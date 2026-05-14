package com.networkedcapital.rep.data.api

import com.networkedcapital.rep.domain.model.*
import retrofit2.Response
import retrofit2.http.*

interface PortalApiService {
    
    @GET(ApiConfig.PORTALS_LIST)
    suspend fun getPortals(): Response<List<Portal>>
    
    @POST(ApiConfig.PORTALS_FILTER)
    suspend fun filterPortals(@Body request: PortalFilterRequest): Response<List<Portal>>
    
    @GET(ApiConfig.PORTAL_DETAILS)
    suspend fun getPortalDetails(@Query("portal_id") portalId: String): Response<Portal>
    
    @POST(ApiConfig.PORTAL_CREATE)
    suspend fun createPortal(@Body portal: CreatePortalRequest): Response<Portal>
    
    @PUT(ApiConfig.PORTAL_EDIT)
    suspend fun updatePortal(@Body portal: UpdatePortalRequest): Response<Portal>
    
    @DELETE(ApiConfig.PORTAL_DELETE)
    suspend fun deletePortal(@Query("portal_id") portalId: String): Response<Unit>
    
    // Main screen endpoints matching iOS functionality
    @GET("api/portal/filter_network_portals")
    suspend fun getFilteredPortals(
        @Query("user_id") userId: Int,
        @Query("tab") tab: String,
        @Query("limit") limit: Int? = null,
        @Query("safe_only") safeOnly: Boolean = false
    ): Response<PortalsApiResponse>
    
    @GET("api/filter_people")
    suspend fun getFilteredPeople(
        @Query("user_id") userId: Int,
        @Query("tab") tab: String,
        @Query("limit") limit: Int? = null
    ): Response<UsersApiResponse>
    
    @GET("api/active_chat_list")
    suspend fun getActiveChats(
        @Query("user_id") userId: Int
    ): Response<ActiveChatApiResponse>
    
    @GET("api/search_portals")
    suspend fun searchPortals(
        @Query("q") query: String,
        @Query("limit") limit: Int = 50
    ): Response<PortalsApiResponse>
    
    @GET("api/search_people")
    suspend fun searchPeople(
        @Query("q") query: String,
        @Query("limit") limit: Int = 50
    ): Response<UsersApiResponse>
    
    @Multipart
    @POST("api/portal/upload_image")
    suspend fun uploadPortalImage(
        @Part("image") image: okhttp3.MultipartBody.Part,
        @Part("portal_id") portalId: okhttp3.RequestBody
    ): Response<ImageUploadResponse>
    
    @GET("api/portal/search_people")
    suspend fun searchPeople(@Query("search_term") searchTerm: String): Response<List<User>>
    
    @POST("api/portal/join")
    suspend fun joinPortal(@Body request: JoinPortalRequest): Response<Unit>
    
    @POST("api/portal/leave")
    suspend fun leavePortal(@Body request: LeavePortalRequest): Response<Unit>
    
    // Portal detail endpoints
    @GET("api/portal/details")
    suspend fun getPortalDetail(
        @Query("portals_id") portalId: Int,
        @Query("user_id") userId: Int
    ): Response<PortalDetailApiResponse>
    
    @GET("api/goals/portal")
    suspend fun getPortalGoals(
        @Query("portals_id") portalId: Int
    ): Response<PortalGoalsApiResponse>
    
    @GET("api/reporting_increments/list")
    suspend fun getReportingIncrements(): Response<List<ReportingIncrement>>
    
    @POST("api/portal/flag_portal")
    suspend fun flagPortal(@Body request: FlagPortalRequest): Response<Unit>

    // Portal creation/edit with multipart (images + form data)
    @Multipart
    @POST("api/portal/")
    suspend fun createPortalWithImages(
        @Part parts: List<okhttp3.MultipartBody.Part>
    ): Response<Portal>

    @Multipart
    @POST("api/portal/edit")
    suspend fun editPortalWithImages(
        @Part parts: List<okhttp3.MultipartBody.Part>
    ): Response<Portal>

    // Delete portal endpoint
    @POST("api/portal/delete")
    suspend fun deletePortalPost(
        @Body request: DeletePortalRequest
    ): Response<Unit>
}

data class PortalFilterRequest(
    val searchTerm: String? = null,
    val category: String? = null,
    val location: String? = null
)

data class CreatePortalRequest(
    val name: String,
    val description: String,
    val category: String,
    val location: String,
    val isPrivate: Boolean,
    val storyBlocks: List<StoryBlock>? = null
)

data class UpdatePortalRequest(
    val portalId: String,
    val name: String,
    val description: String,
    val category: String,
    val location: String,
    val isPrivate: Boolean,
    val storyBlocks: List<StoryBlock>? = null
)

data class JoinPortalRequest(
    val portalId: String
)

data class LeavePortalRequest(
    val portalId: String
)

data class FlagPortalRequest(
    val portal_id: Int,
    val reason: String = ""
)

data class DeletePortalRequest(
    val portal_id: Int,
    val user_id: Int
)
