package com.networkedcapital.rep.presentation.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.MessageRepository
import com.networkedcapital.rep.domain.model.GroupMemberModel
import com.networkedcapital.rep.domain.model.GroupMessageModel
import com.networkedcapital.rep.domain.model.User
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

data class GroupChatUiState(
    val groupName: String = "",
    val groupMembers: List<GroupMemberModel> = emptyList(),
    val messages: List<GroupMessageModel> = emptyList(),
    val inputText: String = "",
    val chatCreatorId: Int? = null,
    val isCreator: Boolean = false,
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    // Group management UI state
    val showEditSheet: Boolean = false,
    val showAddMemberSheet: Boolean = false,
    val showRemoveMemberSheet: Boolean = false,
    val showDeleteConfirmation: Boolean = false,
    val editGroupNameText: String = "",
    val selectedMembersToRemove: List<Int> = emptyList(),
    val showMemberOptions: Int? = null,
    val scrollToMessageId: Int? = null,
    // NEW: Member management properties
    val memberToRemove: GroupMemberModel? = null,
    val selectedUsersToAdd: List<User> = emptyList()
)

/**
 * GroupChatViewModel - Group chat functionality
 * Based on iOS GroupChatViewModel from Chat_Group.swift
 */
@HiltViewModel
class GroupChatViewModel @Inject constructor(
    private val messageRepository: MessageRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(GroupChatUiState())
    val uiState: StateFlow<GroupChatUiState> = _uiState
    
    // Scroll position management
    private val _shouldScrollToBottom = MutableStateFlow(false)
    val shouldScrollToBottom: StateFlow<Boolean> = _shouldScrollToBottom.asStateFlow()
    
    // Socket connection status
    private val _isConnected = MutableStateFlow(SocketManager.isConnected)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()

    private var groupObsId: UUID? = null
    private var groupNotifObsId: UUID? = null
    private var connectionStatusObserverId: UUID? = null
    private var isActive: Boolean = false

    var currentUserId: Int = 0
        private set
    var chatId: Int = 0
        private set
    
    // Helper function for image URL patching
    private fun patchProfilePictureUrl(imageUrl: String?): String? {
        if (imageUrl.isNullOrBlank()) return null
        return if (imageUrl.startsWith("http")) {
            imageUrl
        } else {
            "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/$imageUrl"
        }
    }
    
    // Helper for getting user initials
    fun getInitials(firstName: String?, lastName: String?): String {
        val firstInitial = firstName?.firstOrNull()?.toString() ?: ""
        val lastInitial = lastName?.firstOrNull()?.toString() ?: ""
        return (firstInitial + lastInitial).uppercase().take(2)
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

    fun initialize(currentUserId: Int, chatId: Int) {
        this.currentUserId = currentUserId
        this.chatId = chatId
        
        // Socket connection awareness
        // Immediately sync with current connection state
        _isConnected.value = SocketManager.isConnected
        android.util.Log.d("GroupChatVM", "🔌 Initial connection state: ${SocketManager.isConnected}, _isConnected=${_isConnected.value}")

        connectionStatusObserverId = SocketManager.onConnectionStatusChange { connected ->
            android.util.Log.d("GroupChatVM", "🔌 Connection changed: $connected")
            _isConnected.value = connected
            if (connected && isActive) {
                android.util.Log.d("GroupChatVM", "🔄 Reconnected - rejoining group chat")
                SocketManager.joinGroupChat(chatId)
            }
        }

        android.util.Log.d("GroupChatVM", "✨ init chat_$chatId")
    }

    /**
     * activate() - Call when screen appears
     * Based on iOS GroupChatViewModel.activate()
     */
    fun activate() {
        if (isActive) {
            android.util.Log.d("GroupChatVM", "⚙️ activate() ignored (already active) chat_$chatId")
            return
        }

        isActive = true
        android.util.Log.d("GroupChatVM", "🚀 activate() chat_$chatId")

        SocketManager.registerActiveChat(chatId)
        fetchGroupChat()
        setupRealtime()
    }

    /**
     * deactivate() - Call when screen disappears
     * Based on iOS GroupChatViewModel.deactivate()
     */
    fun deactivate(reason: String = "onDisappear") {
        if (!isActive) {
            android.util.Log.d("GroupChatVM", "⚙️ deactivate() ignored (already inactive) chat_$chatId")
            return
        }

        isActive = false
        android.util.Log.d("GroupChatVM", "🛑 deactivate() chat_$chatId reason=$reason")

        SocketManager.unregisterActiveChat(chatId)

        // Delay leave slightly to avoid churn (iOS uses 0.4s)
        viewModelScope.launch {
            kotlinx.coroutines.delay(400)
            if (!isActive) {
                android.util.Log.d("GroupChatVM", "📤 leaving chat_$chatId after grace period")
                SocketManager.leaveGroupChat(chatId)
                performImmediateCleanup()
            } else {
                android.util.Log.d("GroupChatVM", "♻️ Skip leave for chat_$chatId – reactivated during grace period")
            }
        }
    }

    private fun performImmediateCleanup() {
        groupObsId?.let { id ->
            SocketManager.removeGroupMessageObserver(id)
            groupObsId = null
        }
        groupNotifObsId?.let { id ->
            SocketManager.removeGroupMessageNotificationObserver(id)
            groupNotifObsId = null
        }
    }

    private fun setupRealtime() {
        // Remove existing observers first
        groupObsId?.let { SocketManager.removeGroupMessageObserver(it); groupObsId = null }
        groupNotifObsId?.let { SocketManager.removeGroupMessageNotificationObserver(it); groupNotifObsId = null }

        // Add group message observer
        groupObsId = SocketManager.onGroupMessage { payload ->
            android.util.Log.d("GroupChatVM", "🧩 Incoming group_message payload: $payload")

            // Robust chat_id parsing
            val chatAny = payload["chat_id"] ?: payload["chatId"]
            val incomingChatId = (chatAny as? Number)?.toInt()
                              ?: (chatAny as? String)?.toIntOrNull()

            if (incomingChatId != chatId) return@onGroupMessage

            try {
                // DEBUG: Log socket payload fields
                android.util.Log.d("GroupChatVM", "📦 Socket payload - sender_name='${payload["sender_name"]}', sender_id=${payload["sender_id"]}, text='${payload["text"]}'")

                val message = GroupMessageModel(
                    id = (payload["id"] as? Number)?.toInt() ?: 0,
                    senderId = (payload["sender_id"] as? Number)?.toInt(),
                    senderName = payload["sender_name"] as? String, // Don't default to "" - use null so UI fallback works
                    // Use image patching
                    senderPhotoUrl = patchProfilePictureUrl(payload["sender_photo_url"] as? String),
                    text = payload["text"] as? String,
                    timestamp = payload["timestamp"] as? String,
                    chatId = incomingChatId
                )

                android.util.Log.d("GroupChatVM", "📬 Created message object - id=${message.id}, senderName='${message.senderName}', text='${message.text?.take(20)}'")

                _uiState.update { state ->
                    if (!state.messages.any { it.id == message.id }) {
                        // Check if there's an optimistic message to replace
                        val optimisticIndex = state.messages.indexOfFirst {
                            it.id < 0 && it.text == message.text && it.senderId == message.senderId
                        }

                        val newMessages = if (optimisticIndex >= 0) {
                            state.messages.toMutableList().apply {
                                set(optimisticIndex, message)
                            }
                        } else {
                            state.messages + message
                        }

                        // Trigger scroll on new messages
                        if (message.senderId != currentUserId || optimisticIndex < 0) {
                            _shouldScrollToBottom.value = true
                            viewModelScope.launch {
                                kotlinx.coroutines.delay(100)
                                _shouldScrollToBottom.value = false
                            }
                        }

                        state.copy(messages = newMessages)
                    } else {
                        state
                    }
                }

                // If someone else sent it while we're viewing, mark read
                if (message.senderId != null && message.senderId != currentUserId) {
                    markCurrentChatReadIfNeeded(message.id)
                }

            } catch (e: Exception) {
                android.util.Log.e("GroupChatVM", "Failed to parse group message: ${e.message}")
            }
        }

        // Add group notification observer (for future use)
        groupNotifObsId = SocketManager.onGroupMessageNotification { payload ->
            // Handle notification if needed
        }

        // Delay join slightly to avoid racing socket handshake (iOS uses 0.3s)
        viewModelScope.launch {
            kotlinx.coroutines.delay(300)
            if (isActive) {
                SocketManager.joinGroupChat(chatId)
                android.util.Log.d("GroupChatVM", "➡️ Requested join for chat_$chatId")
            }
        }
    }

    private fun markCurrentChatReadIfNeeded(latestMessageId: Int) {
        // Trigger a refresh which marks as read
        viewModelScope.launch {
            messageRepository.getGroupChat(chatId, limit = 1).firstOrNull()?.let { result ->
                // Server marks as read automatically
            }
        }
    }

    fun fetchGroupChat() {
        if (_uiState.value.isRefreshing) {
            android.util.Log.w("GroupChatVM", "⚠️ Already refreshing chat $chatId, skipping")
            return
        }

        android.util.Log.d("GroupChatVM", "⏳ Starting fetch for chat_$chatId")
        _uiState.update { it.copy(isRefreshing = true, isLoading = true) }

        viewModelScope.launch {
            messageRepository.getGroupChat(chatId).firstOrNull()?.let { result ->
                _uiState.update { it.copy(isRefreshing = false, isLoading = false) }

                android.util.Log.d("GroupChatVM", "✅ Fetch completion for chat_$chatId")

                result.onSuccess { chatResult ->
                    // Patch member profile picture URLs
                    val patchedMembers = chatResult.users.map { member ->
                        member.copy(
                            profilePictureUrl = patchProfilePictureUrl(member.profilePictureUrl)
                        )
                    }

                    // DEBUG: Log message sender names
                    chatResult.messages.forEach { msg ->
                        android.util.Log.d("GroupChatVM", "Message ${msg.id}: senderName='${msg.senderName}', senderId=${msg.senderId}, text='${msg.text?.take(20)}'")
                    }

                    _uiState.update { state ->
                        state.copy(
                            messages = chatResult.messages.sortedBy { it.timestamp ?: "" },
                            groupMembers = patchedMembers,
                            groupName = chatResult.chat.name ?: "Unnamed Chat",
                            chatCreatorId = chatResult.chat.createdBy,
                            isCreator = (chatResult.chat.createdBy != null && currentUserId == chatResult.chat.createdBy)
                        )
                    }
                    
                    // Trigger scroll to bottom on initial load
                    _shouldScrollToBottom.value = true
                    viewModelScope.launch {
                        kotlinx.coroutines.delay(100)
                        _shouldScrollToBottom.value = false
                    }

                    // Mark as read if there are messages
                    chatResult.messages.lastOrNull()?.let { latest ->
                        markCurrentChatReadIfNeeded(latest.id)
                    }

                }.onFailure { error ->
                    android.util.Log.e("GroupChatVM", "❌ Fetch error: ${error.message}")
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }

    fun onInputTextChange(text: String) {
        _uiState.update { it.copy(inputText = text) }
    }

    fun sendMessage() {
        val trimmed = _uiState.value.inputText.trim()
        if (trimmed.isEmpty()) return

        android.util.Log.d("GroupChatVM", "⬆️ Sending group message...")

        // Create optimistic message
        val tempId = -(_uiState.value.messages.size + 1)
        val optimisticMessage = GroupMessageModel(
            id = tempId,
            senderId = currentUserId,
            senderName = "You",
            senderPhotoUrl = null,
            text = trimmed,
            timestamp = java.time.Instant.now().toString(),
            chatId = chatId
        )

        _uiState.update { state ->
            state.copy(
                messages = state.messages + optimisticMessage,
                inputText = ""
            )
        }
        
        // Trigger scroll to bottom when sending
        _shouldScrollToBottom.value = true
        viewModelScope.launch {
            kotlinx.coroutines.delay(100)
            _shouldScrollToBottom.value = false
        }

        viewModelScope.launch {
            messageRepository.sendGroupMessage(chatId, trimmed).firstOrNull()?.let { result ->
                result.onSuccess { realMessage ->
                    android.util.Log.d("GroupChatVM", "✅ Send group message successful")

                    _uiState.update { state ->
                        val messages = state.messages.toMutableList()
                        val tempIndex = messages.indexOfFirst { it.id == tempId }

                        if (tempIndex >= 0) {
                            messages[tempIndex] = realMessage
                        } else if (!messages.any { it.id == realMessage.id }) {
                            messages.add(realMessage)
                        }

                        state.copy(messages = messages)
                    }

                }.onFailure { error ->
                    android.util.Log.e("GroupChatVM", "❌ Send group message error: ${error.message}")
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }
    
    // Error handling
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun acknowledgeError() {
        clearError()
    }
    
    // Group management functions
    fun editGroupName(newName: String) {
        // TODO: Implement updateGroupChat in MessageRepository
        viewModelScope.launch {
            _uiState.update { it.copy(groupName = newName) }
            android.util.Log.d("GroupChatVM", "TODO: Update group name to: $newName")
        }
    }

    fun addMembers(userIds: List<Int>) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            messageRepository.addMembersToGroupChat(chatId, userIds).firstOrNull()?.let { result ->
                _uiState.update { it.copy(isLoading = false) }
                result.onSuccess {
                    // Refresh group chat details to get updated member list
                    fetchGroupChat()
                }.onFailure { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }

    fun removeMembers(userIds: List<Int>) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            messageRepository.removeMemberFromGroupChat(chatId, userIds.first()).firstOrNull()?.let { result ->
                _uiState.update { it.copy(isLoading = false) }
                result.onSuccess {
                    // Refresh group chat details to get updated member list
                    fetchGroupChat()
                }.onFailure { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }

    fun leaveGroup() {
        // TODO: Implement leaveGroupChat in MessageRepository
        viewModelScope.launch {
            android.util.Log.d("GroupChatVM", "TODO: Leave group chat $chatId")
        }
    }

    fun deleteGroupChat() {
        if (!_uiState.value.isCreator) return
        
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            messageRepository.deleteGroupChat(chatId).firstOrNull()?.let { result ->
                _uiState.update { it.copy(isLoading = false) }
                result.onFailure { error ->
                    _uiState.update { it.copy(error = error.message) }
                }
            }
        }
    }
    
    // UI control methods
    fun showEditGroupSheet() {
        _uiState.update { it.copy(
            showEditSheet = true,
            editGroupNameText = it.groupName
        )}
    }

    fun hideEditGroupSheet() {
        _uiState.update { it.copy(showEditSheet = false) }
    }

    fun onEditGroupNameTextChange(text: String) {
        _uiState.update { it.copy(editGroupNameText = text) }
    }

    fun saveEditGroupName() {
        val newName = _uiState.value.editGroupNameText.trim()
        if (newName.isNotEmpty()) {
            editGroupName(newName)
        }
        hideEditGroupSheet()
    }

    fun showAddMemberSheet() {
        _uiState.update { it.copy(showAddMemberSheet = true) }
    }

    fun hideAddMemberSheet() {
        _uiState.update { it.copy(showAddMemberSheet = false) }
    }
    
    fun showRemoveMemberSheet() {
        _uiState.update { it.copy(
            showRemoveMemberSheet = true,
            selectedMembersToRemove = emptyList()
        )}
    }
    
    fun hideRemoveMemberSheet() {
        _uiState.update { it.copy(showRemoveMemberSheet = false) }
    }
    
    fun toggleMemberForRemoval(userId: Int) {
        _uiState.update { state ->
            val current = state.selectedMembersToRemove
            val new = if (current.contains(userId)) {
                current - userId
            } else {
                current + userId
            }
            state.copy(selectedMembersToRemove = new)
        }
    }
    
    fun confirmRemoveSelectedMembers() {
        val members = _uiState.value.selectedMembersToRemove
        if (members.isNotEmpty()) {
            removeMembers(members)
        }
        hideRemoveMemberSheet()
    }
    
    fun showDeleteConfirmation() {
        _uiState.update { it.copy(showDeleteConfirmation = true) }
    }
    
    fun hideDeleteConfirmation() {
        _uiState.update { it.copy(showDeleteConfirmation = false) }
    }
    
    fun confirmDeleteChat() {
        deleteGroupChat()
        hideDeleteConfirmation()
    }
    
    // NEW: Member management methods
    fun onAddMembersSelected(users: List<User>) {
        if (users.isEmpty()) return
        
        _uiState.update { it.copy(showAddMemberSheet = false) }
        
        val userIds = users.map { it.id }
        addMembers(userIds)
    }

    fun showRemoveMemberConfirmation(member: GroupMemberModel) {
        _uiState.update { it.copy(memberToRemove = member) }
    }

    fun hideRemoveMemberConfirmation() {
        _uiState.update { it.copy(memberToRemove = null) }
    }

    fun confirmRemoveMember() {
        val member = _uiState.value.memberToRemove ?: return
        removeMembers(listOf(member.id))
        hideRemoveMemberConfirmation()
    }

    override fun onCleared() {
        super.onCleared()
        android.util.Log.d("GroupChatVM", "🧹 onCleared chat_$chatId active=$isActive")

        if (isActive) {
            SocketManager.unregisterActiveChat(chatId)
            SocketManager.leaveGroupChat(chatId)
            performImmediateCleanup()
        }

        connectionStatusObserverId?.let { id ->
            android.util.Log.d("GroupChatVM", "   Removing connection status observer $id")
            SocketManager.removeConnectionStatusObserver(id)
        }
        connectionStatusObserverId = null
    }
}