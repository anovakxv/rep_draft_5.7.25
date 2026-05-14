package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.data.api.*
import com.networkedcapital.rep.domain.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.catch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * MessageRepository - Repository for messaging operations
 * Wraps MessagingApiService and provides Flow-based results
 */
@Singleton
class MessageRepository @Inject constructor(
    private val messagingApi: MessagingApiService
) {

    // MARK: - Direct Messages

    fun getDirectMessages(
        otherUserId: Int,
        beforeId: Int? = null,
        markAsRead: Boolean = true
    ): Flow<Result<List<MessageModel>>> = flow {
        val response = messagingApi.getDirectMessages(
            userId = otherUserId,
            beforeId = beforeId,
            markAsRead = if (markAsRead) 1 else 0
        )

        if (response.isSuccessful && response.body() != null) {
            val messages = response.body()!!.result.messages
            emit(Result.success(messages))
        } else {
            throw Exception("Failed to load messages: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to get messages", e)))
    }

    fun sendDirectMessage(
        otherUserId: Int,
        message: String
    ): Flow<Result<MessageModel>> = flow {
        val request = SendDirectMessageRequest(
            users_id = otherUserId,
            message = message
        )

        val response = messagingApi.sendDirectMessage(request)

        if (response.isSuccessful && response.body() != null) {
            val sentMessage = response.body()!!.message
            emit(Result.success(sentMessage))
        } else {
            throw Exception("Failed to send message: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to send message", e)))
    }

    // MARK: - Group Chat

    fun getGroupChat(
        chatId: Int,
        limit: Int = 50
    ): Flow<Result<GroupChatResult>> = flow {
        val response = messagingApi.getGroupChat(
            chatId = chatId,
            limit = limit
        )

        if (response.isSuccessful && response.body() != null) {
            val result = response.body()!!.result
            emit(Result.success(result))
        } else {
            throw Exception("Failed to load group chat: ${response.message()}")
        }
    }.catch { e ->
        android.util.Log.e("MessageRepository", "❌ Group chat parsing error", e)
        emit(Result.failure(Exception("Failed to load group chat: ${e.message}", e)))
    }

    fun sendGroupMessage(
        chatId: Int,
        message: String
    ): Flow<Result<GroupMessageModel>> = flow {
        val request = SendGroupMessageRequest(
            chats_id = chatId,
            message = message
        )

        val response = messagingApi.sendGroupMessage(request)

        if (response.isSuccessful && response.body() != null) {
            val sentMessage = response.body()!!.message
            emit(Result.success(sentMessage))
        } else {
            throw Exception("Failed to send group message: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to send group message", e)))
    }

    fun createGroupChat(
        title: String,
        memberIds: List<Int>
    ): Flow<Result<Int>> = flow {
        val request = ManageGroupChatRequest(
            title = title,
            aAddIDs = memberIds
        )

        val response = messagingApi.manageGroupChat(request)

        if (response.isSuccessful && response.body() != null) {
            val chatId = response.body()!!.chats_id
            emit(Result.success(chatId))
        } else {
            throw Exception("Failed to create group chat: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to create group chat", e)))
    }

    fun addMembersToGroupChat(
        chatId: Int,
        memberIds: List<Int>
    ): Flow<Result<Unit>> = flow {
        val request = ManageGroupChatRequest(
            chats_id = chatId,
            aAddIDs = memberIds
        )

        val response = messagingApi.manageGroupChat(request)

        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to add members: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to add members", e)))
    }

    fun removeMemberFromGroupChat(
        chatId: Int,
        memberId: Int
    ): Flow<Result<Unit>> = flow {
        val request = ManageGroupChatRequest(
            chats_id = chatId,
            aDelIDs = listOf(memberId)
        )

        val response = messagingApi.manageGroupChat(request)

        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to remove member: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to remove member", e)))
    }

    fun deleteGroupChat(
        chatId: Int
    ): Flow<Result<Unit>> = flow {
        val request = DeleteGroupChatRequest(chats_id = chatId)
        val response = messagingApi.deleteGroupChat(request)

        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to delete chat: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to delete chat", e)))
    }

    fun getNetworkMembers(
        chatId: Int
    ): Flow<Result<List<User>>> = flow {
        val response = messagingApi.getNetworkMembers(chatId)

        if (response.isSuccessful && response.body() != null) {
            val members = response.body()!!.result
            emit(Result.success(members))
        } else {
            throw Exception("Failed to load network members: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(Exception("Failed to load network members", e)))
    }
}
