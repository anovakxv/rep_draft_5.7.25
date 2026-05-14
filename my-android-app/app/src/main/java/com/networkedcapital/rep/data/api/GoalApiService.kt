package com.networkedcapital.rep.data.api

import com.google.gson.annotations.SerializedName
import com.squareup.moshi.Json
import com.networkedcapital.rep.domain.model.*
import retrofit2.Response
import retrofit2.http.*

interface GoalApiService {

    @GET(ApiConfig.GOALS_LIST)
    suspend fun getGoals(@Query("portal_id") portalId: String? = null): Response<List<Goal>>

    @GET(ApiConfig.GOAL_DETAILS)
    suspend fun getGoalDetails(
        @Query("goals_id") goalId: Int,
        @Query("num_periods") numPeriods: Int = 7
    ): Response<GoalDetailResponse>

    @GET(ApiConfig.GOAL_REPORTING_INCREMENTS)
    suspend fun getReportingIncrements(): Response<ReportingIncrementsResponse>

    @POST(ApiConfig.GOAL_CREATE)
    suspend fun createGoal(@Body request: GoalCreateRequest): Response<GoalResponse>

    @POST(ApiConfig.GOAL_EDIT)
    suspend fun editGoal(@Body request: GoalEditRequest): Response<GoalResponse>

    @DELETE(ApiConfig.GOAL_DELETE)
    suspend fun deleteGoal(@Query("goal_id") goalId: String): Response<Unit>

    @POST(ApiConfig.GOAL_PROGRESS_UPDATE)
    suspend fun updateProgress(@Body request: UpdateProgressRequest): Response<Goal>

    @POST(ApiConfig.GOAL_TEAM_MANAGE)
    suspend fun manageTeam(@Body request: ManageTeamRequest): Response<Goal>

    @GET(ApiConfig.GOALS_LIST)
    suspend fun getUserGoals(@Query("users_id") userId: Int): Response<PortalGoalsApiResponse>

    @POST("api/goals/join_leave")
    suspend fun joinOrLeaveGoal(@Body request: JoinLeaveGoalRequest): Response<JoinLeaveGoalResponse>
}

// Response for reporting increments - matches iOS structure
data class ReportingIncrementsResponse(
    val reportingIncrements: List<ReportingIncrement>
)

// Request for creating a goal - matches iOS/Backend structure
data class GoalCreateRequest(
    val title: String,
    val subtitle: String,
    val description: String,
    val goal_type: String,
    val quota: Int,
    val reporting_increments_id: Int,
    val user_id: Int,
    val portals_id: Int? = null,  // Optional portal ID
    val metric: String? = null     // Required only if goal_type is "Other"
)

// Request for editing a goal - matches iOS/Backend structure
data class GoalEditRequest(
    val goals_id: Int,
    val title: String,
    val subtitle: String,
    val description: String,
    val goal_type: String,
    val quota: Int,
    val reporting_increments_id: Int,
    val user_id: Int,
    val portals_id: Int? = null,  // Optional portal ID
    val metric: String? = null     // Required only if goal_type is "Other"
)

// Generic goal response
data class GoalResponse(
    val result: Any? = null,  // Can be either a String message or a Goal object
    val error: String? = null,
    val goal: Goal? = null
)

data class UpdateProgressRequest(
    val goalId: String,
    val progress: Int, // 0-100 for percentage, checkpoint index for checkpoints
    val note: String? = null
)

data class ManageTeamRequest(
    val goalId: String,
    val action: String, // "add" or "remove"
    val userId: String
)

data class JoinLeaveGoalRequest(
    val aGoalsIDs: List<Int>,
    val todo: String  // "join" or "leave"
)

data class JoinLeaveGoalResponse(
    val result: Map<Int, String>,  // Map of goalId to result status
    val team_sizes: Map<Int, Int>? = null  // Map of goalId to team size
)

data class GoalDetailResponse(
    val result: GoalDetailData
)

data class GoalDetailData(
    val id: Int,
    val title: String,
    val subtitle: String? = null,
    val description: String? = null,
    val progress: Double? = null,
    @Json(name = "progress_percent") val progressPercent: Double? = null,
    val quota: Double? = null,
    @Json(name = "filled_quota") val filledQuota: Double? = null,
    val metricName: String? = null,
    val typeName: String? = null,
    val reportingName: String? = null,
    val quotaString: String? = null,
    val valueString: String? = null,
    val chartData: List<BarChartData>? = null,
    val creatorId: Int? = null,
    val portalId: Int? = null,
    val portalName: String? = null,
    val team: List<User>? = null,
    val aLatestProgress: List<ProgressLog>? = null
)

data class ProgressLog(
    val id: Int,
    @Json(name = "users_id") val usersId: Int? = null,
    @Json(name = "added_value") val addedValue: Double? = null,
    val note: String? = null,
    val value: Double? = null,
    val timestamp: String? = null,
    val aAttachments: List<ProgressAttachment>? = null
)

data class ProgressAttachment(
    val id: Int,
    @Json(name = "file_url") val fileUrl: String? = null,
    @Json(name = "is_image") val isImage: Boolean? = null
)
