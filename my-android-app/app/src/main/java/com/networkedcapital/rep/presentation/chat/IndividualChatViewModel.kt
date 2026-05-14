package com.networkedcapital.rep.presentation.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.MessageRepository
import com.networkedcapital.rep.domain.model.MessageModel
import com.networkedcapital.rep.utils.SocketManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class IndividualChatUiState(
    val messages: List<MessageModel> = emptyList(),
    val inputText: String = "",
    val isLoading: Boolean = false,
    val isLoadingOlder: Boolean = false,
    val canLoadOlder: Boolean = true,
    val isInitialized: Boolean = false,
    val error: String? = null,
    // New properties
    val otherUserName: String = "",
    val otherUserPhotoUrl: String? = null
) {
    // Helper property for empty state
    val isEmpty: Boolean get() = messages.isEmpty() && !isLoading && isInitialized
}

/**
 * IndividualChatViewModel - Direct message chat
 * Based on iOS MessageViewModel from Chat_Individual.swift
 */
@HiltViewModel
class IndividualChatViewModel @Inject constructor(
    private val messageRepository: MessageRepository,
    private val authRepository: com.networkedcapital.rep.data.repository.AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(IndividualChatUiState())
    val uiState: StateFlow<IndividualChatUiState> = _uiState

    // Scroll position management
    private val _shouldScrollToBottom = MutableStateFlow(false)
    val shouldScrollToBottom: StateFlow<Boolean> = _shouldScrollToBottom.asStateFlow()

    // Socket connection status
    private val _isConnected = MutableStateFlow(SocketManager.isConnected)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()

    private var socketObserverId: UUID? = null
    private var connectionStatusObserverId: UUID? = null
    private var isFetchingMessages = false
    private var isSettingUpSocket = false

    var currentUserId: Int = 0
        private set
    var otherUserId: Int = 0
        private set

    init {
        // Get current user ID from auth repository
        viewModelScope.launch {
            authRepository.getCurrentUser()
                .firstOrNull()
                ?.onSuccess { user ->
                    currentUserId = user.id
                    android.util.Log.d("IndividualChatVM", "Current user ID set to: $currentUserId")
                }
        }
    }

    // Helper function for image URL patching
    private fun patchProfilePictureUrl(imageUrl: String?): String? {
        if (imageUrl.isNullOrBlank()) return null
        return if (imageUrl.startsWith("http")) {
            imageUrl
        } else {
            "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/$imageUrl"
        }
    }
    
    // Timestamp formatting
    fun formatTimestamp(timestamp: String): String {
        try {
            val formatter = java.time.format.DateTimeFormatter.ISO_OFFSET_DATE_TIME
            val dateTime = java.time.OffsetDateTime.parse(timestamp, formatter)
            val now = java.time.OffsetDateTime.now()
            val today = now.toLocalDate()
            val messageDate = dateTime.toLocalDate()
            
            return when {
                messageDate == today -> {
                    // Today: show time
                    val timeFormatter = java.time.format.DateTimeFormatter.ofPattern("h:mm a")
                    dateTime.format(timeFormatter)
                }
                messageDate == today.minusDays(1) -> {
                    // Yesterday
                    "Yesterday"
                }
                messageDate.isAfter(today.minusDays(7)) -> {
                    // This week: show day name
                    val dayFormatter = java.time.format.DateTimeFormatter.ofPattern("EEEE")
                    dateTime.format(dayFormatter)
                }
                messageDate.year == today.year -> {
                    // This year: show month and day
                    val monthDayFormatter = java.time.format.DateTimeFormatter.ofPattern("MMM d")
                    dateTime.format(monthDayFormatter)
                }
                else -> {
                    // Different year: show month, day, year
                    val fullFormatter = java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy")
                    dateTime.format(fullFormatter)
                }
            }
        } catch (e: Exception) {
            return ""
        }
    }

    fun initialize(otherUserId: Int, otherUserName: String = "", otherUserPhotoUrl: String? = null) {
        this.otherUserId = otherUserId

        // Update UI state with other user info
        _uiState.update { it.copy(
            otherUserName = otherUserName,
            otherUserPhotoUrl = patchProfilePictureUrl(otherUserPhotoUrl)
        )}

        // Socket connection awareness
        // Immediately sync with current connection state
        _isConnected.value = SocketManager.isConnected
        android.util.Log.d("IndividualChatVM", "🔌 Initial connection state: ${SocketManager.isConnected}, _isConnected=${_isConnected.value}")

        connectionStatusObserverId = SocketManager.onConnectionStatusChange { connected ->
            android.util.Log.d("IndividualChatVM", "🔌 Connection changed: $connected")
            _isConnected.value = connected
            if (connected && _uiState.value.isInitialized) {
                android.util.Log.d("IndividualChatVM", "🔄 Reconnected - re-setup socket listener")
                // Re-setup socket on reconnection
                setupSocketListener()
            }
        }

        android.util.Log.d("IndividualChatVM", "✨ INIT for otherUserId: $otherUserId")

        // Start initial fetch
        fetchMessages()

        // Delay socket setup slightly to avoid deadlock (iOS does 1.2s delay)
        viewModelScope.launch {
            kotlinx.coroutines.delay(1200)
            setupSocketListener()
        }
    }

    private fun setupSocketListener() {
        android.util.Log.d("IndividualChatVM", "📞 Attempting to setup socket listener...")

        if (isSettingUpSocket) {
            android.util.Log.w("IndividualChatVM", "⚠️ Aborted: setupSocketListener() already in progress")
            return
        }

        isSettingUpSocket = true

        // Remove existing listener first
        socketObserverId?.let { id ->
            android.util.Log.d("IndividualChatVM", "   Removing existing socket observer: $id")
            SocketManager.removeDirectMessageObserver(id)
        }

        // Register new listener
        socketObserverId = SocketManager.onDirectMessageNotification { payload ->
            android.util.Log.d("IndividualChatVM", "📡 Received socket payload: $payload")

            val senderId = (payload["sender_id"] as? Number)?.toInt()
                         ?: (payload["senderId"] as? Number)?.toInt()
            val recipientId = (payload["recipient_id"] as? Number)?.toInt()
                           ?: (payload["recipientId"] as? Number)?.toInt()

            // Only process if from the other user to me
            if (senderId == otherUserId && recipientId == currentUserId) {
                android.util.Log.d("IndividualChatVM", "   Payload is relevant. Processing...")

                try {
                    val message = MessageModel(
                        id = (payload["id"] as? Number)?.toInt() ?: (payload["message_id"] as? Number)?.toInt() ?: 0,
                        sender_id = senderId,
                        text = payload["text"] as? String,
                        created_at = payload["timestamp"] as? String,
                        read = payload["read"] as? String
                    )

                    appendIfNeeded(message)
                } catch (e: Exception) {
                    android.util.Log.e("IndividualChatVM", "Failed to parse message: ${e.message}")
                }
            } else {
                android.util.Log.d("IndividualChatVM", "   Payload ignored (not for this conversation)")
            }
        }

        android.util.Log.d("IndividualChatVM", "👍 Socket listener setup complete. Observer ID: $socketObserverId")
        isSettingUpSocket = false
    }

    private fun appendIfNeeded(message: MessageModel) {
        _uiState.update { state ->
            if (!state.messages.any { it.id == message.id }) {
                android.util.Log.d("IndividualChatVM", "   Appending new message ID: ${message.id}")
                val newMessages = (state.messages + message).sortedBy { it.timestamp }
                
                // Trigger scroll to bottom for new messages
                if (message.senderId != currentUserId) {
                    _shouldScrollToBottom.value = true
                    viewModelScope.launch {
                        kotlinx.coroutines.delay(100)
                        _shouldScrollToBottom.value = false
                    }
                }
                
                state.copy(messages = newMessages)
            } else {
                android.util.Log.d("IndividualChatVM", "   Ignoring duplicate message ID: ${message.id}")
                state
            }
        }
    }

    fun fetchMessages() {
        fetchMessages(beforeId = null, append = false)
    }

    private fun fetchMessages(beforeId: Int? = null, append: Boolean) {
        android.util.Log.d("IndividualChatVM", "⬇️ fetchMessages called. Append: $append, BeforeID: ${beforeId ?: -1}")

        if (append) {
            if (_uiState.value.isLoadingOlder || !_uiState.value.canLoadOlder) {
                android.util.Log.w("IndividualChatVM", "⚠️ Aborted paginated fetch")
                return
            }
            _uiState.update { it.copy(isLoadingOlder = true) }
        } else {
            if (isFetchingMessages) {
                android.util.Log.w("IndividualChatVM", "⚠️ Aborted initial fetch: Another fetch is already in progress")
                return
            }
            isFetchingMessages = true
            _uiState.update { it.copy(isLoading = true) }
        }

        viewModelScope.launch {
            messageRepository.getDirectMessages(
                otherUserId = otherUserId,
                beforeId = beforeId,
                markAsRead = !append
            ).firstOrNull()?.let { result ->
                _uiState.update { state ->
                    if (append) {
                        state.copy(isLoadingOlder = false)
                    } else {
                        isFetchingMessages = false
                        state.copy(isLoading = false)
                    }
                }

                result.onSuccess { newMsgs ->
                    android.util.Log.d("IndividualChatVM", "✅ Fetch successful. Received ${newMsgs.size} messages")
                    val sortedMsgs = newMsgs.sortedBy { it.timestamp }

                    _uiState.update { state ->
                        if (append) {
                            if (sortedMsgs.isEmpty()) {
                                android.util.Log.d("IndividualChatVM", "   No older messages found. Disabling pagination")
                                state.copy(canLoadOlder = false)
                            } else {
                                val existingIds = state.messages.map { it.id }.toSet()
                                val filtered = sortedMsgs.filter { !existingIds.contains(it.id) }
                                android.util.Log.d("IndividualChatVM", "   Prepending ${filtered.count()} older messages")
                                state.copy(messages = filtered + state.messages)
                            }
                        } else {
                            // Initial load - trigger scroll to bottom
                            if (sortedMsgs.isNotEmpty()) {
                                _shouldScrollToBottom.value = true
                                viewModelScope.launch {
                                    kotlinx.coroutines.delay(100)
                                    _shouldScrollToBottom.value = false
                                }
                            }
                            
                            state.copy(
                                messages = sortedMsgs,
                                isInitialized = true
                            )
                        }
                    }
                }.onFailure { error ->
                    android.util.Log.e("IndividualChatVM", "❌ Message fetch error: ${error.message}")
                    _uiState.update { state ->
                        if (!append) {
                            state.copy(
                                messages = emptyList(),
                                isInitialized = true,
                                error = error.message
                            )
                        } else {
                            state.copy(error = error.message)
                        }
                    }
                }
            }
        }
    }

    fun loadOlderIfNeeded(firstVisibleId: Int?) {
        val messages = _uiState.value.messages
        if (messages.isEmpty()) return

        firstVisibleId?.let { id ->
            if (messages.firstOrNull()?.id == id) {
                android.util.Log.d("IndividualChatVM", "🔝 Top of list reached, loading older messages")
                fetchMessages(beforeId = id, append = true)
            }
        }
    }

    fun onInputTextChange(text: String) {
        _uiState.update { it.copy(inputText = text) }
    }

    fun sendMessage() {
        val trimmed = _uiState.value.inputText.trim()
        if (trimmed.isEmpty()) return

        android.util.Log.d("IndividualChatVM", "⬆️ Sending message...")

        // Create optimistic message
        val tempId = -System.currentTimeMillis().toInt() // Temporary negative ID
        val optimisticMessage = MessageModel(
            id = tempId,
            sender_id = currentUserId,
            text = trimmed,
            created_at = java.time.Instant.now().toString(),
            read = null
        )
        
        // Add optimistic message immediately
        _uiState.update { state ->
            val newMessages = state.messages + optimisticMessage
            state.copy(
                messages = newMessages.sortedBy { it.timestamp },
                inputText = "" // Clear input immediately for better UX
            )
        }
        
        // Trigger scroll to bottom
        _shouldScrollToBottom.value = true
        viewModelScope.launch {
            kotlinx.coroutines.delay(100)
            _shouldScrollToBottom.value = false
        }

        viewModelScope.launch {
            messageRepository.sendDirectMessage(
                otherUserId = otherUserId,
                message = trimmed
            ).firstOrNull()?.let { result ->
                result.onSuccess { sentMessage ->
                    android.util.Log.d("IndividualChatVM", "✅ Send message successful")
                    
                    // Replace optimistic message with real one
                    _uiState.update { state ->
                        val updatedMessages = state.messages.toMutableList()
                        val optimisticIndex = updatedMessages.indexOfFirst { it.id == tempId }
                        
                        if (optimisticIndex >= 0) {
                            updatedMessages[optimisticIndex] = sentMessage
                        } else if (!updatedMessages.any { it.id == sentMessage.id }) {
                            updatedMessages.add(sentMessage)
                        }
                        
                        state.copy(messages = updatedMessages.sortedBy { it.timestamp })
                    }
                }.onFailure { error ->
                    android.util.Log.e("IndividualChatVM", "❌ Send message error: ${error.message}")
                    
                    // Remove the optimistic message on error
                    _uiState.update { state ->
                        val updatedMessages = state.messages.filter { it.id != tempId }
                        state.copy(
                            messages = updatedMessages,
                            error = error.message
                        )
                    }
                }
            }
        }
    }
    
    // Enhanced error handling
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun acknowledgeError() {
        clearError()
    }

    override fun onCleared() {
        super.onCleared()
        android.util.Log.d("IndividualChatVM", "🗑️ DEINIT for otherUserId: $otherUserId")

        socketObserverId?.let { id ->
            android.util.Log.d("IndividualChatVM", "   Removing socket observer $id")
            SocketManager.removeDirectMessageObserver(id)
        }

        connectionStatusObserverId?.let { id ->
            android.util.Log.d("IndividualChatVM", "   Removing connection status observer $id")
            SocketManager.removeConnectionStatusObserver(id)
        }

        socketObserverId = null
        connectionStatusObserverId = null
        isFetchingMessages = false
        isSettingUpSocket = false
    }
}