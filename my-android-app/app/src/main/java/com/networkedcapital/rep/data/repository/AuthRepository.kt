package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.data.api.*
import com.networkedcapital.rep.domain.model.User
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.catch
import okhttp3.MultipartBody
import javax.inject.Inject
import javax.inject.Singleton
import okhttp3.RequestBody.Companion.toRequestBody

@Singleton
class AuthRepository @Inject constructor(
    private val authApiService: AuthApiService,
    private val authInterceptor: AuthInterceptor
) {

    suspend fun updateProfile(
        firstName: String,
        lastName: String,
        email: String,
        broadcast: String,
        repType: String,
        city: String,
        about: String,
        otherSkill: String,
        skills: List<String>,
        imageUrl: String?
    ): Flow<Result<User>> = flow {
        // Construct full name for the 'name' field (used by iOS)
        val fullNameString = if (firstName.isNotBlank() && lastName.isNotBlank()) {
            "$firstName $lastName"
        } else if (firstName.isNotBlank()) {
            firstName
        } else if (lastName.isNotBlank()) {
            lastName
        } else {
            null
        }

        val user = User(
            id = 0,
            name = fullNameString, // Add the 'name' field for iOS compatibility
            fname = firstName,
            lname = lastName,
            email = email,
            broadcast = broadcast,
            userType_string = repType,
            manual_city = city,
            about = about,
            other_skill = otherSkill,
            skills = skills,
            profile_picture_url = imageUrl
        )
        emitAll(updateProfile(user))
    }

    suspend fun uploadProfileImage(profileImageUri: String): Flow<Result<String>> = flow {
        // TODO: Use content resolver to get file from URI and upload as MultipartBody.Part
        // For now, just emit a dummy URL
        emit(Result.success("https://dummyimage.com/200x200"))
    }

    suspend fun login(email: String, password: String): Flow<Result<User>> = flow {
        val response = authApiService.login(LoginRequest(email = email, password = password))
        if (response.isSuccessful) {
            val loginResponse = response.body()
            if (loginResponse != null) {
                // Save token
                authInterceptor.saveToken(loginResponse.token)
                emit(Result.success(loginResponse.result))
            } else {
                throw Exception("Invalid response")
            }
        } else {
            throw Exception("Login failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Login error", e)))
    }

    suspend fun register(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        userTypeId: Int = 1, // Default to Lead (1)
        phone: String? = null,
        about: String? = null,
        city: String? = null
    ): Flow<Result<User>> = flow {
        val emailBody = email.toRequestBody()
        val passwordBody = password.toRequestBody()
        val firstNameBody = firstName.toRequestBody()
        val lastNameBody = lastName.toRequestBody()
        val userTypeIdBody = userTypeId.toString().toRequestBody()
        val phoneBody = phone?.toRequestBody()
        val aboutBody = about?.toRequestBody()
        val cityBody = city?.toRequestBody()

        val response = authApiService.register(
            email = emailBody,
            password = passwordBody,
            firstName = firstNameBody,
            lastName = lastNameBody,
            userTypeId = userTypeIdBody,
            phone = phoneBody,
            about = aboutBody,
            city = cityBody
        )

        // Debug logging: print raw response
        println("[AuthRepository] register raw response: ${response.raw()}\nBody: ${response.body()}")

        if (response.isSuccessful) {
            val registerResponse = response.body()
            if (registerResponse != null) {
                // Try to cast result to User
                val user = registerResponse.result as? User
                if (user != null) {
                    authInterceptor.saveToken(registerResponse.token)
                    emit(Result.success(user))
                } else if (registerResponse.result is String && (registerResponse.result as String).contains("success", ignoreCase = true)) {
                    // Treat as success even if result is a string
                    authInterceptor.saveToken(registerResponse.token)
                    emit(Result.success(User(
                        id = 0,
                        fname = "",
                        lname = "",
                        email = "",
                        broadcast = "",
                        userType_string = "",
                        manual_city = "",
                        about = "",
                        other_skill = "",
                        skills = emptyList(),
                        profile_picture_url = ""
                    )))
                } else {
                    throw Exception("Registration failed: ${registerResponse.result}")
                }
            } else {
                throw Exception("Invalid response")
            }
        } else {
            throw Exception("Registration failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Registration error", e)))
    }

    suspend fun logout(): Flow<Result<Unit>> = flow {
        val response = authApiService.logout()
        authInterceptor.clearToken()
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Logout failed: ${response.message()}")
        }
    }.catch { e ->
        // Clear token even if API call fails
        authInterceptor.clearToken()
        emit(Result.success(Unit))
    }

    suspend fun getProfile(): Flow<Result<User>> = flow {
        val response = authApiService.getProfile()
        if (response.isSuccessful) {
            val userResponse = response.body()
            if (userResponse != null) {
                emit(Result.success(userResponse.result))
            } else {
                throw Exception("User not found")
            }
        } else {
            throw Exception("Failed to get profile: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e))
    }

    suspend fun getCurrentUser(): Flow<Result<User>> = getProfile()

    suspend fun updateProfile(user: User): Flow<Result<User>> = flow {
        val response = authApiService.updateProfile(user)
        if (response.isSuccessful) {
            val editResponse = response.body()
            if (editResponse != null && editResponse.result != null) {
                emit(Result.success(editResponse.result))
            } else {
                throw Exception("Update failed: missing user data")
            }
        } else {
            throw Exception("Profile update failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e))
    }

    suspend fun uploadProfileImage(image: MultipartBody.Part): Flow<Result<String>> = flow {
        val response = authApiService.uploadProfileImage(image)
        if (response.isSuccessful) {
            val uploadResponse = response.body()
            if (uploadResponse != null) {
                emit(Result.success(uploadResponse.imageUrl))
            } else {
                throw Exception("Upload failed")
            }
        } else {
            throw Exception("Image upload failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e))
    }

    fun isLoggedIn(): Boolean {
        return authInterceptor.getToken() != null
    }

    fun getToken(): String? {
        return authInterceptor.getToken()
    }

    suspend fun deleteProfile(): Flow<Result<Unit>> = flow {
        val response = authApiService.deleteProfile()
        if (response.isSuccessful) {
            authInterceptor.clearToken()
            emit(Result.success(Unit))
        } else {
            throw Exception("Delete failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Delete profile error", e)))
    }

    suspend fun forgotPassword(email: String): Flow<Result<String>> = flow {
        val response = authApiService.forgotPassword(ForgotPasswordRequest(email = email))
        if (response.isSuccessful) {
            val forgotPasswordResponse = response.body()
            if (forgotPasswordResponse?.result == "sent") {
                emit(Result.success("Password reset email sent to $email"))
            } else if (forgotPasswordResponse?.error != null) {
                throw Exception(forgotPasswordResponse.error)
            } else {
                throw Exception("Failed to send reset email")
            }
        } else {
            throw Exception("Failed to send reset email: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Forgot password error", e)))
    }
}

