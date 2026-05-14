package com.networkedcapital.rep.presentation.auth

import android.app.Application
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.AuthRepository
import com.networkedcapital.rep.data.repository.UserRepository
import com.networkedcapital.rep.domain.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject
import android.util.Base64
import android.util.Log
import org.json.JSONObject

data class AuthState(
    val isRegistered: Boolean = false,
    val onboardingComplete: Boolean = false,
    val jwtToken: String = "",
    val userId: Int = 0,
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val isLoggedIn: Boolean = false,
    val forgotPasswordSuccess: String? = null
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository,
    private val application: Application
) : ViewModel() {

    private val _authState = MutableStateFlow(AuthState())
    val authState: StateFlow<AuthState> = _authState.asStateFlow()
    
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser = _currentUser.asStateFlow()

    init {
        checkAuthStatus()
    }

    fun acceptTermsOfUse() {
        // This could call a backend endpoint if needed, or just update state
        _authState.value = _authState.value.copy(onboardingComplete = false)
    }

    fun continueAboutRep() {
        // This could call a backend endpoint if needed, or just update state
        _authState.value = _authState.value.copy(onboardingComplete = false)
    }

    fun saveProfile(
        firstName: String,
        lastName: String,
        email: String,
        broadcast: String,
        repType: String,
        city: String,
        about: String,
        otherSkill: String,
        skills: Set<String>,
        profileImageUri: String?,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(isLoading = true, errorMessage = null)
            // Upload image if present
            var imageUrl: String? = null
            if (profileImageUri != null) {
                authRepository.uploadProfileImage(profileImageUri)
                    .catch { throwable ->
                        _authState.value = _authState.value.copy(errorMessage = throwable.message ?: "Image upload failed")
                        onError(throwable.message ?: "Image upload failed")
                    }
                    .collect { result ->
                        result.fold(
                            onSuccess = { url -> imageUrl = url },
                            onFailure = { throwable -> 
                                _authState.value = _authState.value.copy(errorMessage = throwable.message ?: "Image upload failed")
                                onError(throwable.message ?: "Image upload failed")
                            }
                        )
                    }
            }
            authRepository.updateProfile(
                firstName, lastName, email, broadcast, repType, city, about, otherSkill, skills.toList(), imageUrl
            )
                .catch { throwable ->
                    _authState.value = _authState.value.copy(
                        isLoading = false,
                        errorMessage = throwable.message ?: "Profile update failed"
                    )
                    onError(throwable.message ?: "Profile update failed")
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { user ->
                            _currentUser.value = user
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                onboardingComplete = true,
                                userId = user.id,
                                errorMessage = null
                            )
                            onSuccess()
                        },
                        onFailure = { throwable ->
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                errorMessage = throwable.message ?: "Profile update failed"
                            )
                            onError(throwable.message ?: "Profile update failed")
                        }
                    )
                }
        }
    }

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(isLoading = true, errorMessage = null)
            authRepository.login(email, password)
                .catch { throwable ->
                    _authState.value = _authState.value.copy(
                        isLoading = false,
                        errorMessage = throwable.message ?: "Login failed"
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { user ->
                            _currentUser.value = user
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                isLoggedIn = true,
                                isRegistered = true,
                                onboardingComplete = true,
                                userId = user.id,
                                jwtToken = authRepository.getToken() ?: "",
                                errorMessage = null
                            )
                            // Send FCM token to backend after successful login
                            sendFCMTokenToBackend()
                        },
                        onFailure = { throwable ->
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                errorMessage = throwable.message ?: "Login failed"
                            )
                        }
                    )
                }
        }
    }

    private fun checkAuthStatus() {
        // For emulator testing: require manual login even if a token exists.
        // We still treat the user as registered/onboarded to avoid showing the Register/Onboarding screens.
        val token = authRepository.getToken() ?: ""
        val userIdFromToken = if (token.isNotEmpty()) parseUserIdFromToken(token) else null
        _authState.value = _authState.value.copy(
            isLoggedIn = false, // force login screen on app start
            isRegistered = true,
            onboardingComplete = true,
            jwtToken = token, // Keep the actual token for socket connections
            userId = userIdFromToken ?: _authState.value.userId
        )
        // Do not auto-fetch profile; wait until user logs in explicitly.
    }
    
    fun register(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        phone: String = "",
        repType: String = "Lead",
        userTypeId: Int = 1 // Lead = 1, Specialist = 2, Partner = 3, Founder = 4
    ) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(isLoading = true, errorMessage = null)
            println("[AuthViewModel] Starting registration: firstName=$firstName, lastName=$lastName, email=$email, phone=$phone, repType=$repType, userTypeId=$userTypeId")
            authRepository.register(email, password, firstName, lastName, userTypeId, phone, null, null)
                .catch { throwable ->
                    println("[AuthViewModel] Registration failed: ${throwable.message}")
                    _authState.value = _authState.value.copy(
                        isLoading = false,
                        errorMessage = throwable.message ?: "Registration failed"
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { user ->
                            println("[AuthViewModel] Registration success. User ID: ${user.id}")
                            _currentUser.value = user
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                isLoggedIn = true,
                                isRegistered = true,
                                onboardingComplete = false, // Still needs onboarding
                                userId = user.id,
                                errorMessage = null
                            )
                            println("[AuthViewModel] authState after registration: isRegistered=${_authState.value.isRegistered}, onboardingComplete=${_authState.value.onboardingComplete}, userId=${_authState.value.userId}")
                            // Send FCM token to backend after successful registration
                            sendFCMTokenToBackend()
                        },
                        onFailure = { throwable ->
                            println("[AuthViewModel] Registration result failure: ${throwable.message}")
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                errorMessage = throwable.message ?: "Registration failed"
                            )
                        }
                    )
                }
        }
    }
    
    fun completeOnboarding() {
        _authState.value = _authState.value.copy(
            onboardingComplete = true
        )
    }
    
    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
                .catch { /* Handle error if needed */ }
                .collect { result ->
                    result.fold(
                        onSuccess = {
                            _currentUser.value = null
                            _authState.value = AuthState()
                        },
                        onFailure = {
                            // Even if logout fails, clear local state
                            _currentUser.value = null
                            _authState.value = AuthState()
                        }
                    )
                }
        }
    }

    fun loadCurrentUser() {
        viewModelScope.launch {
            authRepository.getProfile()
                .catch { /* Handle error silently for auto-fetch */ }
                .collect { result ->
                    result.fold(
                        onSuccess = { user ->
                            _currentUser.value = user
                            // Ensure userId is populated so navigation can proceed
                            _authState.value = _authState.value.copy(userId = user.id)
                        },
                        onFailure = {
                            // If profile fetch fails, user might need to re-login
                            _authState.value = _authState.value.copy(isLoggedIn = false)
                        }
                    )
                }
        }
    }

    private fun parseUserIdFromToken(token: String): Int? {
        return try {
            val parts = token.split('.')
            if (parts.size < 2) return null
            val payload = parts[1]
            val decoded = String(Base64.decode(payload, Base64.URL_SAFE or Base64.NO_WRAP))
            val json = JSONObject(decoded)
            val id = json.optInt("user_id", 0)
            if (id > 0) id else null
        } catch (e: Exception) {
            null
        }
    }
    
    fun clearError() {
        _authState.value = _authState.value.copy(errorMessage = null)
    }

    fun forgotPassword(email: String) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(
                isLoading = true,
                errorMessage = null,
                forgotPasswordSuccess = null
            )
            authRepository.forgotPassword(email)
                .catch { throwable ->
                    _authState.value = _authState.value.copy(
                        isLoading = false,
                        errorMessage = throwable.message ?: "Failed to send reset email"
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { message ->
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                forgotPasswordSuccess = message,
                                errorMessage = null
                            )
                        },
                        onFailure = { throwable ->
                            _authState.value = _authState.value.copy(
                                isLoading = false,
                                errorMessage = throwable.message ?: "Failed to send reset email"
                            )
                        }
                    )
                }
        }
    }

    fun clearForgotPasswordSuccess() {
        _authState.value = _authState.value.copy(forgotPasswordSuccess = null)
    }

    /**
     * Send FCM token to backend after successful login/registration
     */
    private fun sendFCMTokenToBackend() {
        viewModelScope.launch {
            try {
                val prefs = application.getSharedPreferences("auth_prefs", android.content.Context.MODE_PRIVATE)
                val fcmToken = prefs.getString("fcm_token", null)

                if (fcmToken.isNullOrEmpty()) {
                    Log.d("AuthViewModel", "No FCM token found in SharedPreferences")
                    return@launch
                }

                Log.d("AuthViewModel", "Sending FCM token to backend: $fcmToken")

                userRepository.updateDeviceToken(fcmToken)
                    .catch { throwable ->
                        Log.e("AuthViewModel", "Failed to send FCM token: ${throwable.message}", throwable)
                    }
                    .collect { result ->
                        result.fold(
                            onSuccess = {
                                Log.d("AuthViewModel", "Successfully sent FCM token to backend")
                            },
                            onFailure = { throwable ->
                                Log.e("AuthViewModel", "Failed to send FCM token: ${throwable.message}", throwable)
                            }
                        )
                    }
            } catch (e: Exception) {
                Log.e("AuthViewModel", "Error sending FCM token: ${e.message}", e)
            }
        }
    }
}
