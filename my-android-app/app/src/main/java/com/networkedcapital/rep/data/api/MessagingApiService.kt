package com.networkedcapital.rep.data.api

import com.networkedcapital.rep.domain.model.*
import retrofit2.Response
import retrofit2.http.*

/**
 * MessagingApiService - Backend API for messaging
 * Matches iOS Swift backend endpoints exactly
 */
interface MessagingApiService {

    // MARK: - Direct Messages (DM)

    /**
     * Get direct messages with another user
     * iOS Reference: Chat_Individual.swift line 174
     * Endpoint: GET /api/message/get_messages
     */
    @GET("api/message/get_messages")
    suspend fun getDirectMessages(
        @Query("users_id") userId: Int,
        @Query("order") order: String = "ASC",
        @Query("limit") limit: Int = 200,
        @Query("mark_as_read") markAsRead: Int = 1,
        @Query("before_id") beforeId: Int? = null
    ): Response<GetMessagesResponse>

    /**
     * Send a direct message to another user
     * iOS Reference: Chat_Individual.swift line 290
     * Endpoint: POST /api/message/send_message
     */
    @POST("api/message/send_message")
    @Headers("Content-Type: application/json")
    suspend fun sendDirectMessage(
        @Body request: SendDirectMessageRequest
    ): Response<SendMessageResponse>

    // MARK: - Group Chat

    /**
     * Get group chat messages
     * iOS Reference: Chat_Group.swift line 355
     * Endpoint: GET /api/message/group_chat
     */
    @GET("api/message/group_chat")
    suspend fun getGroupChat(
        @Query("chats_id") chatId: Int,
        @Query("limit") limit: Int = 50
    ): Response<GroupChatResponse>

    /**
     * Send a group chat message
     * iOS Reference: Chat_Group.swift line 407
     * Endpoint: POST /api/message/send_chat_message
     */
    @POST("api/message/send_chat_message")
    @Headers("Content-Type: application/json")
    suspend fun sendGroupMessage(
        @Body request: SendGroupMessageRequest
    ): Response<SendGroupMessageResponse>

    /**
     * Create or manage group chat (add/remove members)
     * iOS Reference: Chat_Group.swift line 880, 932, 961
     * Endpoint: POST /api/message/manage_chat
     */
    @POST("api/message/manage_chat")
    @Headers("Content-Type: application/json")
    suspend fun manageGroupChat(
        @Body request: ManageGroupChatRequest
    ): Response<ManageGroupChatResponse>

    /**
     * Delete a group chat
     * iOS Reference: Chat_Group.swift line 993
     * Endpoint: POST /api/message/delete_chat
     */
    @POST("api/message/delete_chat")
    @Headers("Content-Type: application/json")
    suspend fun deleteGroupChat(
        @Body request: DeleteGroupChatRequest
    ): Response<Unit>

    /**
     * Get NTWK users to add to group chat
     * iOS Reference: Chat_Group.swift line 1130
     * Endpoint: GET /api/user/members_of_my_network
     */
    @GET("api/user/members_of_my_network")
    suspend fun getNetworkMembers(
        @Query("not_in_chats_id") chatId: Int
    ): Response<NetworkMembersResponse>

    // MARK: - Reactions (Direct Messages)

    /** Toggle emoji reaction on a DM — POST /api/message/toggle-reaction/{id} */
    @POST("api/message/toggle-reaction/{messageId}")
    @Headers("Content-Type: application/json")
    suspend fun toggleDmReaction(
        @Path("messageId") messageId: Int,
        @Body request: ToggleReactionRequest
    ): Response<ReactionResponse>

    /** Edit a DM — PUT /api/message/{id} */
    @PUT("api/message/{messageId}")
    @Headers("Content-Type: application/json")
    suspend fun editDmMessage(
        @Path("messageId") messageId: Int,
        @Body request: EditMessageRequest
    ): Response<EditMessageResponse>

    /** Soft-delete a DM (sender only) — DELETE /api/message/{id} */
    @DELETE("api/message/{messageId}")
    suspend fun deleteDmMessage(
        @Path("messageId") messageId: Int
    ): Response<Unit>

    /** Get edit history for a DM — GET /api/message/{id}/history */
    @GET("api/message/{messageId}/history")
    suspend fun getDmMessageHistory(
        @Path("messageId") messageId: Int
    ): Response<MessageHistoryResponse>

    // MARK: - Reactions (Group Messages)

    /** Toggle emoji reaction on a group message — POST /api/message/group/toggle-reaction/{id} */
    @POST("api/message/group/toggle-reaction/{messageId}")
    @Headers("Content-Type: application/json")
    suspend fun toggleGroupReaction(
        @Path("messageId") messageId: Int,
        @Body request: ToggleReactionRequest
    ): Response<ReactionResponse>

    /** Edit a group message — PUT /api/message/group/{id} */
    @PUT("api/message/group/{messageId}")
    @Headers("Content-Type: application/json")
    suspend fun editGroupMessage(
        @Path("messageId") messageId: Int,
        @Body request: EditMessageRequest
    ): Response<EditMessageResponse>

    /** Soft-delete a group message (sender only) — DELETE /api/message/group/{id} */
    @DELETE("api/message/group/{messageId}")
    suspend fun deleteGroupMessage(
        @Path("messageId") messageId: Int
    ): Response<Unit>
}

data class ToggleReactionRequest(val emoji: String)

data class EditMessageRequest(val text: String)

data class ReactionResponse(
    val reactions: List<com.networkedcapital.rep.domain.model.MessageReaction>? = null
)

data class EditMessageResponse(
    val result: Map<String, String>? = null
)

// MARK: - Request Models

data class SendDirectMessageRequest(
    val users_id: Int,
    val message: String
)

data class SendGroupMessageRequest(
    val chats_id: Int,
    val message: String
)

data class ManageGroupChatRequest(
    val chats_id: Int? = null,  // null when creating new chat
    val title: String? = null,
    val aAddIDs: List<Int>? = null,  // User IDs to add
    val aDelIDs: List<Int>? = null   // User IDs to remove
)

data class DeleteGroupChatRequest(
    val chats_id: Int
)

// MARK: - Response Models

data class GetMessagesResponse(
    val result: MessagesResult
)

data class MessagesResult(
    val messages: List<MessageModel>
)

data class SendMessageResponse(
    val result: String,
    val message: MessageModel
)

data class GroupChatResponse(
    val result: GroupChatResult
)

data class GroupChatResult(
    val chat: ChatInfo,
    val users: List<GroupMemberModel>,
    val messages: List<GroupMessageModel>
)

data class SendGroupMessageResponse(
    val result: String,
    val message: GroupMessageModel
)

data class ManageGroupChatResponse(
    val chats_id: Int
)

data class NetworkMembersResponse(
    val result: List<User>
)

data class MessageHistoryItem(
    val id: Int,
    val text: String,
    val edited_at: String? = null,
    val timestamp: String? = null
)

data class MessageHistoryResponse(
    val history: List<MessageHistoryItem>
)
