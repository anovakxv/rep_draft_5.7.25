package com.networkedcapital.rep.data.api

import com.networkedcapital.rep.domain.model.GoalTeamInvitesResponse
import com.networkedcapital.rep.domain.model.RespondToInviteRequest
import retrofit2.Response
import retrofit2.http.*

interface InviteApiService {

    /**
     * Get pending team invitations for the current user
     * Endpoint: GET /api/goals/pending_invites
     */
    @GET(ApiConfig.PENDING_INVITES)
    suspend fun getPendingInvites(): Response<GoalTeamInvitesResponse>

    /**
     * Respond to a team invitation (accept or decline)
     * Endpoint: PATCH /api/goals/{goalId}/team
     */
    @PATCH("api/goals/{goalId}/team")
    suspend fun respondToInvite(
        @Path("goalId") goalId: Int,
        @Body request: RespondToInviteRequest
    ): Response<Unit>

    /**
     * Mark all invites as read
     * Endpoint: POST /api/goals/pending_invites/mark_read
     */
    @POST(ApiConfig.MARK_INVITES_READ)
    suspend fun markInvitesRead(): Response<Unit>
}
