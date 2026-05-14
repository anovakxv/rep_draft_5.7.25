package com.networkedcapital.rep.data.api

import com.networkedcapital.rep.domain.model.NTWKUsersResponse
import retrofit2.Response
import retrofit2.http.*

interface UserApiService {
    @GET("api/user/members_of_my_network")
    suspend fun getNetworkUsersNotInChat(
        @Query("not_in_chats_id") chatId: Int
    ): NTWKUsersResponse

    @PATCH("api/user/notification_settings")
    suspend fun updateNotificationSettings(
        @Body settings: Map<String, Boolean>
    ): Response<Unit>

    @GET("api/user/members_of_my_network")
    suspend fun getNetworkMembers(): NTWKUsersResponse

    @POST("api/user/block")
    suspend fun blockUser(
        @Query("users_id") userId: Int
    ): Response<Unit>

    @POST("api/user/flag")
    suspend fun flagUser(
        @Body params: Map<String, Any>
    ): Response<Unit>

    @POST("api/user/device_token")
    suspend fun updateDeviceToken(
        @Body params: Map<String, String>
    ): Response<Unit>
}
