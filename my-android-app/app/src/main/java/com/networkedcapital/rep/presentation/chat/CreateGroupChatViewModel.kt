package com.networkedcapital.rep.presentation.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.api.ManageGroupChatRequest
import com.networkedcapital.rep.data.api.MessagingApiService
import com.networkedcapital.rep.data.repository.PortalRepository
import com.networkedcapital.rep.domain.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CreateGroupChatUiState(
    val groupName: String = "",
    val selectedMembers: Set<User> = emptySet(),
    val availableUsers: List<User> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val createdChatId: Int? = null
)

@HiltViewModel
class CreateGroupChatViewModel @Inject constructor(
    private val messagingApiService: MessagingApiService,
    private val portalRepository: PortalRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CreateGroupChatUiState())
    val uiState: StateFlow<CreateGroupChatUiState> = _uiState.asStateFlow()

    // S3 base URL for image patching (same as backend and iOS)
    private val s3BaseUrl = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

    /**
     * Patch image URL - convert filename to full S3 URL if needed
     */
    private fun patchImageUrl(imageNameOrUrl: String?): String? {
        if (imageNameOrUrl.isNullOrBlank()) return null
        return if (imageNameOrUrl.startsWith("http")) {
            imageNameOrUrl
        } else {
            s3BaseUrl + imageNameOrUrl
        }
    }

    /**
     * Patch User image URLs
     */
    private fun patchUserImage(user: User): User {
        val patchedUrl = patchImageUrl(user.profile_picture_url ?: user.imageName)
        return user.copy(
            profile_picture_url = patchedUrl,
            imageUrl = patchedUrl,
            avatarUrl = patchedUrl
        )
    }

    fun initialize(currentUserId: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                // Fetch network members (your NTWK)
                val response = portalRepository.getFilteredPeople(currentUserId, "ntwk")
                val patchedUsers = response.map { patchUserImage(it) }
                _uiState.update {
                    it.copy(
                        availableUsers = patchedUsers,
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Failed to load network: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun updateGroupName(name: String) {
        _uiState.update { it.copy(groupName = name) }
    }

    fun toggleMemberSelection(user: User) {
        _uiState.update { state ->
            val newSelection = if (state.selectedMembers.contains(user)) {
                state.selectedMembers - user
            } else {
                state.selectedMembers + user
            }
            state.copy(selectedMembers = newSelection)
        }
    }

    fun createGroupChat(currentUserId: Int) {
        val state = _uiState.value

        // Validation
        if (state.groupName.isBlank()) {
            _uiState.update { it.copy(error = "Please enter a group name") }
            return
        }

        if (state.selectedMembers.isEmpty()) {
            _uiState.update { it.copy(error = "Please select at least one member") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                // Include current user ID in the members list
                val memberIds = listOf(currentUserId) + state.selectedMembers.map { it.id }

                val request = ManageGroupChatRequest(
                    chats_id = null,  // null for creating new chat
                    title = state.groupName,
                    aAddIDs = memberIds,
                    aDelIDs = null
                )

                val response = messagingApiService.manageGroupChat(request)

                if (response.isSuccessful) {
                    val chatId = response.body()?.chats_id
                    if (chatId != null) {
                        _uiState.update {
                            it.copy(
                                createdChatId = chatId,
                                isLoading = false
                            )
                        }
                    } else {
                        _uiState.update {
                            it.copy(
                                error = "Failed to create group chat",
                                isLoading = false
                            )
                        }
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            error = "Failed to create group chat: ${response.message()}",
                            isLoading = false
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = "Error creating group chat: ${e.message}",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
