package com.networkedcapital.rep.presentation.auth

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch

data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val isLoggedIn: Boolean = false,
    val errorMessage: String? = null
)

class LoginViewModel : ViewModel() {
    var uiState by mutableStateOf(LoginUiState())
        private set

    fun onEmailChange(email: String) {
        uiState = uiState.copy(email = email)
    }

    fun onPasswordChange(password: String) {
        uiState = uiState.copy(password = password)
    }

    fun focusPasswordField() {
        // No-op for Compose, handled by focusRequester in the UI
    }

    fun login() {
        if (uiState.email.isBlank() || uiState.password.isBlank()) {
            uiState = uiState.copy(errorMessage = "Please enter your email and password.")
            return
        }
        uiState = uiState.copy(isLoading = true, errorMessage = null)
        viewModelScope.launch {
            try {
                // TODO: Replace with real API call
                // Simulate network delay
                kotlinx.coroutines.delay(1000)
                // Simulate login success
                if (uiState.email == "test@example.com" && uiState.password == "password") {
                    uiState = uiState.copy(isLoading = false, isLoggedIn = true)
                } else {
                    uiState = uiState.copy(isLoading = false, errorMessage = "Invalid credentials.")
                }
            } catch (e: Exception) {
                uiState = uiState.copy(isLoading = false, errorMessage = "Network error. Please try again.")
            }
        }
    }

    fun clearError() {
        uiState = uiState.copy(errorMessage = null)
    }
}
