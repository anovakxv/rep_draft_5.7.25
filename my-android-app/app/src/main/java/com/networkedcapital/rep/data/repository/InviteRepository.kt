package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.data.api.InviteApiService
import com.networkedcapital.rep.domain.model.GoalTeamInvite
import com.networkedcapital.rep.domain.model.RespondToInviteRequest
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class InviteRepository @Inject constructor(
    private val inviteApiService: InviteApiService
) {

    /**
     * Fetch pending team invitations for the current user
     */
    suspend fun getPendingInvites(): Flow<Result<List<GoalTeamInvite>>> = flow {
        try {
            val response = inviteApiService.getPendingInvites()
            if (response.isSuccessful) {
                val invitesResponse = response.body()
                if (invitesResponse != null) {
                    // Filter for unconfirmed invites only
                    val pendingInvites = invitesResponse.invites.filter { it.confirmed == 0 }
                    emit(Result.success(pendingInvites))
                } else {
                    emit(Result.success(emptyList()))
                }
            } else {
                emit(Result.failure(Exception("Failed to fetch invites: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Respond to a team invitation (accept or decline)
     * @param goalId The ID of the goal
     * @param action "accept" or "decline"
     * @param userId The current user's ID
     */
    suspend fun respondToInvite(
        goalId: Int,
        action: String,
        userId: Int
    ): Flow<Result<Unit>> = flow {
        try {
            val request = RespondToInviteRequest(
                action = action,
                users = listOf(userId)
            )
            val response = inviteApiService.respondToInvite(goalId, request)
            if (response.isSuccessful) {
                emit(Result.success(Unit))
            } else {
                emit(Result.failure(Exception("Failed to respond to invite: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Mark all pending invites as read
     */
    suspend fun markInvitesRead(): Flow<Result<Unit>> = flow {
        try {
            val response = inviteApiService.markInvitesRead()
            if (response.isSuccessful) {
                emit(Result.success(Unit))
            } else {
                emit(Result.failure(Exception("Failed to mark invites as read: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
}
