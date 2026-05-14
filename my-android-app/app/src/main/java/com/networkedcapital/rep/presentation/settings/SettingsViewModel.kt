package com.networkedcapital.rep.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.AuthRepository
import com.networkedcapital.rep.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NotificationSettings(
    val pushNotificationsEnabled: Boolean = true,
    val notifDirectMessages: Boolean = true,
    val notifGroupMessages: Boolean = true,
    val notifGoalInvites: Boolean = true
)

data class SettingsUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val notificationSettings: NotificationSettings = NotificationSettings(),
    val userId: Int = 0,
    val isAdmin: Boolean = false
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        loadSettings()
    }

    private fun loadSettings() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            // Load user profile to get userId
            authRepository.getCurrentUser()
                .catch { /* Handle silently */ }
                .collect { result ->
                    result.fold(
                        onSuccess = { user ->
                            _uiState.value = _uiState.value.copy(
                                userId = user.id,
                                isAdmin = user.is_admin ?: false,
                                isLoading = false
                            )
                        },
                        onFailure = {
                            _uiState.value = _uiState.value.copy(isLoading = false)
                        }
                    )
                }

            // Load notification settings from local storage or API
            loadNotificationSettings()
        }
    }

    private fun loadNotificationSettings() {
        // In a real implementation, you'd load these from SharedPreferences or API
        // For now, use defaults
        _uiState.value = _uiState.value.copy(
            notificationSettings = NotificationSettings()
        )
    }

    fun updateNotificationSettings(settings: NotificationSettings) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(notificationSettings = settings)

            // Send to backend
            userRepository.updateNotificationSettings(settings)
                .catch { throwable ->
                    _uiState.value = _uiState.value.copy(
                        errorMessage = throwable.message ?: "Failed to update notification settings"
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = {
                            // Settings updated successfully
                        },
                        onFailure = { throwable ->
                            _uiState.value = _uiState.value.copy(
                                errorMessage = throwable.message ?: "Failed to update notification settings"
                            )
                        }
                    )
                }
        }
    }

    fun togglePushNotifications(enabled: Boolean) {
        val newSettings = _uiState.value.notificationSettings.copy(
            pushNotificationsEnabled = enabled
        )
        updateNotificationSettings(newSettings)
    }

    fun toggleDirectMessages(enabled: Boolean) {
        val newSettings = _uiState.value.notificationSettings.copy(
            notifDirectMessages = enabled
        )
        updateNotificationSettings(newSettings)
    }

    fun toggleGroupMessages(enabled: Boolean) {
        val newSettings = _uiState.value.notificationSettings.copy(
            notifGroupMessages = enabled
        )
        updateNotificationSettings(newSettings)
    }

    fun toggleGoalInvites(enabled: Boolean) {
        val newSettings = _uiState.value.notificationSettings.copy(
            notifGoalInvites = enabled
        )
        updateNotificationSettings(newSettings)
    }

    fun logout(onSuccess: () -> Unit) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            authRepository.logout()
                .catch { /* Handle error if needed */ }
                .collect { result ->
                    result.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(isLoading = false)
                            onSuccess()
                        },
                        onFailure = {
                            // Even if logout fails, clear local state and navigate
                            _uiState.value = _uiState.value.copy(isLoading = false)
                            onSuccess()
                        }
                    )
                }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }
}
