package com.networkedcapital.rep.data.api

import com.networkedcapital.rep.domain.model.*
import retrofit2.Response
import retrofit2.http.*
import okhttp3.MultipartBody
import okhttp3.RequestBody
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

interface AuthApiService {
    
    @POST(ApiConfig.LOGIN)
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>
    
    @Multipart
    @POST(ApiConfig.REGISTER)
    suspend fun register(
        @Part("email") email: RequestBody,
        @Part("password") password: RequestBody,
        @Part("fname") firstName: RequestBody,
        @Part("lname") lastName: RequestBody,
        @Part("users_types_id") userTypeId: RequestBody,
        @Part("phone") phone: RequestBody? = null,
        @Part("about") about: RequestBody? = null,
        @Part("manual_city") city: RequestBody? = null,
        @Part image: MultipartBody.Part? = null
    ): Response<RegisterResponse>
    
    @POST(ApiConfig.LOGOUT)
    suspend fun logout(): Response<LogoutResponse>
    
    @GET(ApiConfig.PROFILE)
    suspend fun getProfile(): Response<UserProfileApiResponse>
    
    @POST(ApiConfig.EDIT_PROFILE)
    suspend fun updateProfile(@Body user: User): Response<UserEditResponse>
    
    @DELETE(ApiConfig.DELETE_PROFILE)
    suspend fun deleteProfile(): Response<Unit>
    
    @POST(ApiConfig.FORGOT_PASSWORD)
    suspend fun forgotPassword(@Body request: ForgotPasswordRequest): Response<ForgotPasswordResponse>
    
    @Multipart
    @POST("api/user/upload_profile_image")
    suspend fun uploadProfileImage(
        @Part("image") image: MultipartBody.Part
    ): Response<ImageUploadResponse>
}

data class LoginRequest(
    val email: String? = null,
    val username: String? = null,
    val password: String
)

data class LoginResponse(
    val result: User,
    val token: String
)



@JsonClass(generateAdapter = true)
data class RegisterResponse(
    @Json(name = "result")
    val result: Any?,
    @Json(name = "token")
    val token: String
)

data class LogoutResponse(
    val result: String
)

data class ForgotPasswordRequest(
    val email: String? = null,
    val hash: String? = null,
    val new_password: String? = null
)

data class ForgotPasswordResponse(
    val result: String? = null,
    val error: String? = null
)

data class ImageUploadResponse(
    val imageUrl: String
)
