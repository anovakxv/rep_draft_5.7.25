package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.data.api.*
import com.networkedcapital.rep.data.local.dao.*
import com.networkedcapital.rep.data.local.entity.*
import com.networkedcapital.rep.domain.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.catch
import okhttp3.MultipartBody
import okhttp3.RequestBody
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PortalRepository @Inject constructor(
    private val portalApiService: PortalApiService,
    private val portalDao: PortalDao,
    private val userDao: UserDao,
    private val activeChatDao: ActiveChatDao,
    private val goalDao: GoalDao
) {

    suspend fun getPortals(): Flow<Result<List<Portal>>> = flow {
        val response = portalApiService.getPortals()
        if (response.isSuccessful) {
            val portals = response.body() ?: emptyList()
            emit(Result.success(portals))
        } else {
            throw Exception("Failed to get portals: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun getFilteredPortals(userId: Int, tab: String, safeOnly: Boolean = false): List<Portal> {
        return try {
            // Try network first
            val limitParam = if (tab == "all") 50 else null
            val response = portalApiService.getFilteredPortals(userId, tab, limitParam, safeOnly)

            if (response.isSuccessful) {
                val portals = response.body()?.result ?: emptyList()
                // Cache portals in Room
                val entities = portals.map { PortalEntity.fromDomainModel(it) }
                portalDao.insertPortals(entities)
                portals
            } else {
                // On network error, try to load from cache
                val cachedEntities = if (safeOnly) {
                    portalDao.getPortalsBySafeStatus(true)
                } else {
                    portalDao.getAllPortals()
                }
                cachedEntities.map { it.toDomainModel() }
            }
        } catch (e: Exception) {
            // On exception, fallback to cache
            val cachedEntities = if (safeOnly) {
                portalDao.getPortalsBySafeStatus(true)
            } else {
                portalDao.getAllPortals()
            }
            cachedEntities.map { it.toDomainModel() }
        }
    }

    suspend fun getFilteredPeople(userId: Int, tab: String): List<User> {
        return try {
            // Try network first
            val limitParam = if (tab == "all") 50 else null
            val response = portalApiService.getFilteredPeople(userId, tab, limitParam)

            if (response.isSuccessful) {
                val users = response.body()?.result ?: emptyList()
                // Cache users in Room
                val entities = users.map { UserEntity.fromDomainModel(it) }
                userDao.insertUsers(entities)
                users
            } else {
                // On network error, try to load from cache
                val cachedEntities = userDao.getAllUsers()
                cachedEntities.map { it.toDomainModel() }
            }
        } catch (e: Exception) {
            // On exception, fallback to cache
            val cachedEntities = userDao.getAllUsers()
            cachedEntities.map { it.toDomainModel() }
        }
    }

    suspend fun getActiveChats(userId: Int): List<ActiveChat> {
        return try {
            // Try network first
            val response = portalApiService.getActiveChats(userId)

            if (response.isSuccessful) {
                val chats = response.body()?.result ?: emptyList()
                // TODO: Re-enable caching after updating ActiveChatEntity to use String id
                // val entities = chats.map { ActiveChatEntity.fromDomainModel(it) }
                // activeChatDao.insertChats(entities)
                chats
            } else {
                // On network error, return empty list for now (caching disabled)
                emptyList()
            }
        } catch (e: Exception) {
            // On exception, return empty list for now (caching disabled)
            emptyList()
        }
    }

    suspend fun searchPortals(query: String, limit: Int = 50): List<Portal> {
        val response = portalApiService.searchPortals(query, limit)
        
        if (response.isSuccessful) {
            return response.body()?.result ?: emptyList()
        } else {
            throw Exception("Failed to search portals: ${response.message()}")
        }
    }

    suspend fun searchPeople(query: String, limit: Int = 50): List<User> {
        val response = portalApiService.searchPeople(query, limit)
        
        if (response.isSuccessful) {
            return response.body()?.result ?: emptyList()
        } else {
            throw Exception("Failed to search people: ${response.message()}")
        }
    }

    suspend fun filterPortals(
        searchTerm: String? = null,
        category: String? = null,
        location: String? = null
    ): Flow<Result<List<Portal>>> = flow {
        val request = PortalFilterRequest(searchTerm, category, location)
        val response = portalApiService.filterPortals(request)
        if (response.isSuccessful) {
            val portals = response.body() ?: emptyList()
            emit(Result.success(portals))
        } else {
            throw Exception("Failed to filter portals: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun getPortalDetails(portalId: String): Flow<Result<Portal>> = flow {
        val response = portalApiService.getPortalDetails(portalId)
        if (response.isSuccessful) {
            val portal = response.body()
            if (portal != null) {
                emit(Result.success(portal))
            } else {
                throw Exception("Portal not found")
            }
        } else {
            throw Exception("Failed to get portal details: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun createPortal(
        name: String,
        description: String,
        category: String,
        location: String,
        isPrivate: Boolean,
        storyBlocks: List<StoryBlock>? = null
    ): Flow<Result<Portal>> = flow {
        val request = CreatePortalRequest(name, description, category, location, isPrivate, storyBlocks)
        val response = portalApiService.createPortal(request)
        if (response.isSuccessful) {
            val portal = response.body()
            if (portal != null) {
                emit(Result.success(portal))
            } else {
                throw Exception("Failed to create portal")
            }
        } else {
            throw Exception("Portal creation failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun updatePortal(
        portalId: String,
        name: String,
        description: String,
        category: String,
        location: String,
        isPrivate: Boolean,
        storyBlocks: List<StoryBlock>? = null
    ): Flow<Result<Portal>> = flow {
        val request = UpdatePortalRequest(portalId, name, description, category, location, isPrivate, storyBlocks)
        val response = portalApiService.updatePortal(request)
        if (response.isSuccessful) {
            val portal = response.body()
            if (portal != null) {
                emit(Result.success(portal))
            } else {
                throw Exception("Failed to update portal")
            }
        } else {
            throw Exception("Portal update failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun deletePortal(portalId: String): Flow<Result<Unit>> = flow {
        val response = portalApiService.deletePortal(portalId)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Portal deletion failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun uploadPortalImage(image: MultipartBody.Part, portalId: RequestBody): Flow<Result<String>> = flow {
        val response = portalApiService.uploadPortalImage(image, portalId)
        if (response.isSuccessful) {
            val uploadResponse = response.body()
            if (uploadResponse != null) {
                emit(Result.success(uploadResponse.imageUrl))
            } else {
                throw Exception("Upload failed")
            }
        } else {
            throw Exception("Image upload failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun searchPeople(searchTerm: String): Flow<Result<List<User>>> = flow {
        val response = portalApiService.searchPeople(searchTerm)
        if (response.isSuccessful) {
            val users = response.body() ?: emptyList()
            emit(Result.success(users))
        } else {
            throw Exception("People search failed: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun joinPortal(portalId: String): Flow<Result<Unit>> = flow {
        val request = JoinPortalRequest(portalId)
        val response = portalApiService.joinPortal(request)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to join portal: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun leavePortal(portalId: String): Flow<Result<Unit>> = flow {
        val request = LeavePortalRequest(portalId)
        val response = portalApiService.leavePortal(request)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to leave portal: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun getPortalDetail(portalId: Int, userId: Int): Flow<Result<PortalDetail>> = flow {
        val response = portalApiService.getPortalDetail(portalId, userId)
        if (response.isSuccessful) {
            val portalDetailResponse = response.body()
            if (portalDetailResponse != null) {
                emit(Result.success(portalDetailResponse.result))
            } else {
                throw Exception("Portal detail not found")
            }
        } else {
            throw Exception("Failed to get portal detail: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun getPortalGoals(portalId: Int): Flow<Result<List<Goal>>> = flow {
        val response = portalApiService.getPortalGoals(portalId)
        if (response.isSuccessful) {
            val goalsResponse = response.body()
            if (goalsResponse != null) {
                val goals = goalsResponse.aGoals
                // Cache goals in Room
                val entities = goals.map { GoalEntity.fromDomainModel(it) }
                goalDao.insertGoals(entities)
                emit(Result.success(goals))
            } else {
                emit(Result.success(emptyList()))
            }
        } else {
            // On network error, try to load from cache
            val cachedEntities = goalDao.getGoalsByPortalId(portalId)
            emit(Result.success(cachedEntities.map { it.toDomainModel() }))
        }
    }.catch { e ->
        // On exception, fallback to cache
        try {
            val cachedEntities = goalDao.getGoalsByPortalId(portalId)
            emit(Result.success(cachedEntities.map { it.toDomainModel() }))
        } catch (cacheException: Exception) {
            emit(Result.failure(e as? Exception ?: Exception(e.message)))
        }
    }

    suspend fun getReportingIncrements(): Flow<Result<List<ReportingIncrement>>> = flow {
        val response = portalApiService.getReportingIncrements()
        if (response.isSuccessful) {
            val increments = response.body() ?: emptyList()
            emit(Result.success(increments))
        } else {
            throw Exception("Failed to get reporting increments: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    suspend fun flagPortal(portalId: Int, reason: String = ""): Flow<Result<Unit>> = flow {
        val request = FlagPortalRequest(portalId, reason)
        val response = portalApiService.flagPortal(request)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to flag portal: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    /**
     * Get cached portals as a Flow for reactive UI updates
     */
    fun getCachedPortalsFlow(): Flow<List<Portal>> {
        return portalDao.getAllPortalsFlow().map { entities ->
            entities.map { it.toDomainModel() }
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
     * Get cached active chats as a Flow for reactive UI updates
     */
    fun getCachedActiveChatsFlow(): Flow<List<ActiveChat>> {
        return activeChatDao.getAllChatsFlow().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    /**
     * Save portal with images (multipart upload)
     * Used for creating new portals or editing existing ones with image uploads
     */
    suspend fun savePortalWithImages(portalId: Int, parts: List<okhttp3.MultipartBody.Part>): Flow<Result<Portal>> = flow {
        val response = if (portalId == 0) {
            portalApiService.createPortalWithImages(parts)
        } else {
            portalApiService.editPortalWithImages(parts)
        }

        if (response.isSuccessful) {
            val portal = response.body()
            if (portal != null) {
                emit(Result.success(portal))
            } else {
                throw Exception("Portal save succeeded but no data returned")
            }
        } else {
            throw Exception("Failed to save portal: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    /**
     * Delete portal (POST method with JSON body)
     */
    suspend fun deletePortal(portalId: Int, userId: Int): Flow<Result<Unit>> = flow {
        val request = DeletePortalRequest(portal_id = portalId, user_id = userId)
        val response = portalApiService.deletePortalPost(request)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to delete portal: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }
}
