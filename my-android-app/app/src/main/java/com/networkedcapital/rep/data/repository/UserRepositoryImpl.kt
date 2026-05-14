package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.domain.model.User
import com.networkedcapital.rep.data.api.UserApiService
import com.networkedcapital.rep.data.local.dao.UserDao
import com.networkedcapital.rep.data.local.entity.UserEntity
import com.networkedcapital.rep.presentation.settings.NotificationSettings
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class UserRepositoryImpl @Inject constructor(
    private val userApiService: UserApiService,
    private val userDao: UserDao
) : UserRepository {

    override suspend fun getNetworkUsersNotInChat(chatId: Int): List<User> {
        return try {
            val response = userApiService.getNetworkUsersNotInChat(chatId)
            response.result
        } catch (e: Exception) {
            throw e
        }
    }

    override suspend fun updateNotificationSettings(settings: NotificationSettings): Flow<Result<Unit>> = flow {
        try {
            val response = userApiService.updateNotificationSettings(
                mapOf(
                    "pushNotificationsEnabled" to settings.pushNotificationsEnabled,
                    "notifDirectMessages" to settings.notifDirectMessages,
                    "notifGroupMessages" to settings.notifGroupMessages,
                    "notifGoalInvites" to settings.notifGoalInvites
                )
            )
            if (response.isSuccessful) {
                emit(Result.success(Unit))
            } else {
                emit(Result.failure(Exception("Failed to update notification settings: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    override suspend fun getNetworkMembers(): Flow<Result<List<User>>> = flow {
        try {
            val response = userApiService.getNetworkMembers()
            val users = response.result

            // Cache users in Room
            val entities = users.map { UserEntity.fromDomainModel(it) }
            userDao.insertUsers(entities)

            emit(Result.success(users))
        } catch (e: Exception) {
            // On exception, try to load from cache
            try {
                val cachedEntities = userDao.getAllUsers()
                val cachedUsers = cachedEntities.map { it.toDomainModel() }
                if (cachedUsers.isNotEmpty()) {
                    emit(Result.success(cachedUsers))
                } else {
                    emit(Result.failure(e))
                }
            } catch (cacheException: Exception) {
                emit(Result.failure(e))
            }
        }
    }

    override suspend fun blockUser(userId: Int): Flow<Result<Unit>> = flow {
        try {
            val response = userApiService.blockUser(userId)
            if (response.isSuccessful) {
                emit(Result.success(Unit))
            } else {
                emit(Result.failure(Exception("Failed to block user: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    override suspend fun flagUser(userId: Int, reason: String): Flow<Result<Unit>> = flow {
        try {
            val response = userApiService.flagUser(mapOf("users_id" to userId, "reason" to reason))
            if (response.isSuccessful) {
                emit(Result.success(Unit))
            } else {
                emit(Result.failure(Exception("Failed to flag user: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    override suspend fun updateDeviceToken(token: String): Flow<Result<Unit>> = flow {
        try {
            val response = userApiService.updateDeviceToken(mapOf("device_token" to token))
            if (response.isSuccessful) {
                emit(Result.success(Unit))
            } else {
                emit(Result.failure(Exception("Failed to update device token: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Get cached users as a Flow for reactive UI updates
     */
    fun getCachedUsersFlow(): Flow<List<User>> {
        return userDao.getAllUsersFlow().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    /**
     * Search cached users by name
     */
    suspend fun searchCachedUsers(query: String): List<User> {
        return userDao.searchUsersByName(query).map { it.toDomainModel() }
    }
}