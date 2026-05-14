package com.networkedcapital.rep.presentation.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.UserRepository
import com.networkedcapital.rep.domain.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AddMembersUiState(
    val users: List<User> = emptyList(),
    val selectedUserIds: Set<Int> = emptySet(),
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class AddMembersViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AddMembersUiState(isLoading = true))
    val uiState: StateFlow<AddMembersUiState> = _uiState.asStateFlow()

    fun initialize(chatId: Int, alreadySelected: Set<Int>) {
        fetchNetworkUsers(chatId)
    }

    fun toggleUserSelection(userId: Int) {
        _uiState.update { state ->
            val newSelected = if (state.selectedUserIds.contains(userId)) {
                state.selectedUserIds - userId
            } else {
                state.selectedUserIds + userId
            }
            state.copy(selectedUserIds = newSelected)
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    private fun fetchNetworkUsers(chatId: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val users = userRepository.getNetworkUsersNotInChat(chatId)
                _uiState.update { 
                    it.copy(
                        users = users,
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load network users"
                    )
                }
            }
        }
    }
}