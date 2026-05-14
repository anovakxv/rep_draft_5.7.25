package com.networkedcapital.rep.data.remote

import com.networkedcapital.rep.domain.model.Goal
import com.networkedcapital.rep.domain.model.FeedItem
import com.networkedcapital.rep.domain.model.User
import retrofit2.http.GET
import retrofit2.http.Query

// Response model matching backend
// You may need to adjust field names/types to match your backend

data class GoalDetailApiResponse(
    val goal: Goal,
    val feed: List<FeedItem>,
    val team: List<User>
)

interface GoalsApiService {
    @GET("/api/goals/details")
    suspend fun getGoalDetail(
        @Query("goals_id") goalId: Int,
        @Query("num_periods") numPeriods: Int = 7
    ): GoalDetailApiResponse

    @GET("/api/goals/users")
    suspend fun getGoalUsers(
        @Query("goals_id") goalId: Int,
        @Query("confirmed") confirmed: Int? = null,
        @Query("offset") offset: Int = 0,
        @Query("limit") limit: Int = 50
    ): GoalUsersApiResponse
}

data class GoalUsersApiResponse(
    val result: List<User>
)
