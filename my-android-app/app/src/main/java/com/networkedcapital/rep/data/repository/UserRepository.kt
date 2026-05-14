package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.domain.model.User
import com.networkedcapital.rep.presentation.settings.NotificationSettings
import kotlinx.coroutines.flow.Flow

interface UserRepository {
    suspend fun getNetworkUsersNotInChat(chatId: Int): List<User>

    suspend fun updateNotificationSettings(settings: NotificationSettings): Flow<Result<Unit>>

    suspend fun getNetworkMembers(): Flow<Result<List<User>>>

    suspend fun blockUser(userId: Int): Flow<Result<Unit>>

    suspend fun flagUser(userId: Int, reason: String): Flow<Result<Unit>>

    suspend fun updateDeviceToken(token: String): Flow<Result<Unit>>
}
