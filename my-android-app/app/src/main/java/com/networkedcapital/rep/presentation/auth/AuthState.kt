package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.data.api.*
import com.networkedcapital.rep.domain.model.User
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.catch
import okhttp3.MultipartBody
import javax.inject.Inject
import javax.inject.Singleton
import okhttp3.RequestBody.Companion.toRequestBody

@Singleton
class AuthStateect constructor(
    private val authApiService: AuthApiService,
    private val authInterceptor: AuthInterceptor
) {

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
        emit(Result.failure(e))
    }

    suspend fun register(
        email: String?,
        password: String,
        firstName: String,
        lastName: String,
        userTypeId: Int = 1,
        phone: String? = null,
        about: String? = null,
        city: String? = null
    ): Flow<Result<User>> = flow {
        // Option 1: Using Elvis operator for a default empty string if email is null
        val emailBody = (email ?: "").toRequestBody()
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

        if (response.isSuccessful) {
            val registerResponse = response.body()
            if (registerResponse != null) {
                val user = registerResponse.result as? User
                if (user != null) {
                    authInterceptor.saveToken(registerResponse.token)
                    emit(Result.success(user))
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
        emit(Result.failure(e))
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

    suspend fun deleteProfile(): Flow<Result<Unit>> = flow {
        val response = authApiService.deleteProfile()
        if (response.isSuccessful) {
            authInterceptor.clearToken()
            emit(Result.success(Unit))
        } else {
            throw Exception("Delete failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e))
    }
}
data class AuthState(
    val isLoading: Boolean = false,
    val jwtToken: String = "",
    val userId: Int = 0,
    val email: String? = null,
    val password: String = "",
    val errorMessage: String? = null
)