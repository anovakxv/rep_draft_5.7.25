package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.data.api.GoalApiService
import com.networkedcapital.rep.data.api.PortalApiService
import com.networkedcapital.rep.data.api.ProfileApiService
import com.networkedcapital.rep.domain.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.catch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.toRequestBody
import javax.inject.Inject

interface ProfileRepository {
    suspend fun getUserProfile(userId: Int): Flow<Result<User>>
    suspend fun getSkills(): Flow<Result<List<Skill>>>
    suspend fun getWrites(userId: Int): Flow<Result<List<WriteBlock>>>
    suspend fun addWrite(title: String, content: String): Flow<Result<WriteBlock>>
    suspend fun editWrite(writeId: Int, title: String, content: String, order: Int?): Flow<Result<WriteBlock>>
    suspend fun deleteWrite(writeId: Int): Flow<Result<Unit>>
    suspend fun getUserPortals(userId: Int): Flow<Result<List<Portal>>>
    suspend fun getUserGoals(userId: Int): Flow<Result<List<Goal>>>
    suspend fun isBlocked(userId: Int): Flow<Result<Boolean>>
    suspend fun blockUser(userId: Int): Flow<Result<Unit>>
    suspend fun unblockUser(userId: Int): Flow<Result<Unit>>
    suspend fun flagUser(userId: Int, reason: String): Flow<Result<Unit>>
    suspend fun addToNetwork(userId: Int, targetUserId: Int): Flow<Result<Unit>>
    suspend fun getUserPhotos(userId: Int): Flow<Result<List<UserPhoto>>>
    suspend fun uploadPhoto(photoPart: MultipartBody.Part, caption: String?): Flow<Result<UserPhoto>>
    suspend fun deletePhoto(photoId: Int): Flow<Result<Unit>>
    suspend fun reorderPhotos(userId: Int, photos: List<UserPhoto>): Flow<Result<Unit>>
}

class ProfileRepositoryImpl @Inject constructor(
    private val profileApiService: ProfileApiService,
    private val portalApiService: PortalApiService,
    private val goalApiService: GoalApiService
) : ProfileRepository {

    override suspend fun getUserProfile(userId: Int): Flow<Result<User>> = flow {
        val response = profileApiService.getUserProfile(userId)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to load profile: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun getSkills(): Flow<Result<List<Skill>>> = flow {
        val response = profileApiService.getSkills()
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to load skills: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun getWrites(userId: Int): Flow<Result<List<WriteBlock>>> = flow {
        val response = profileApiService.getWrites(userId)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to load writes: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun addWrite(title: String, content: String): Flow<Result<WriteBlock>> = flow {
        val params = mapOf(
            "title" to title,
            "content" to content
        )
        val response = profileApiService.addWrite(params)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to add write: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun editWrite(writeId: Int, title: String, content: String, order: Int?): Flow<Result<WriteBlock>> = flow {
        val params = mutableMapOf<String, Any>(
            "title" to title,
            "content" to content
        )
        if (order != null) {
            params["order"] = order
        }
        val response = profileApiService.editWrite(writeId, params)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to edit write: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun deleteWrite(writeId: Int): Flow<Result<Unit>> = flow {
        val response = profileApiService.deleteWrite(writeId)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to delete write: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun getUserPortals(userId: Int): Flow<Result<List<Portal>>> = flow {
        val response = portalApiService.getFilteredPortals(userId, "open", null, false)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to load portals: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun getUserGoals(userId: Int): Flow<Result<List<Goal>>> = flow {
        val response = goalApiService.getUserGoals(userId)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.aGoals))
        } else {
            throw Exception("Failed to load goals: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun isBlocked(userId: Int): Flow<Result<Boolean>> = flow {
        val response = profileApiService.isBlocked(userId)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.is_blocked))
        } else {
            throw Exception("Failed to check block status: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun blockUser(userId: Int): Flow<Result<Unit>> = flow {
        val params = mapOf("users_id" to userId)
        val response = profileApiService.blockUser(params)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to block user: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun unblockUser(userId: Int): Flow<Result<Unit>> = flow {
        val params = mapOf("users_id" to userId)
        val response = profileApiService.unblockUser(params)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to unblock user: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun flagUser(userId: Int, reason: String): Flow<Result<Unit>> = flow {
        val params = mapOf(
            "users_id" to userId,
            "reason" to reason
        )
        val response = profileApiService.flagUser(params)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to flag user: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun addToNetwork(userId: Int, targetUserId: Int): Flow<Result<Unit>> = flow {
        val params = mapOf(
            "action" to "add",
            "user_id" to userId,
            "target_user_id" to targetUserId
        )
        val response = profileApiService.networkAction(params)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to add to network: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun getUserPhotos(userId: Int): Flow<Result<List<UserPhoto>>> = flow {
        val response = profileApiService.getUserPhotos(userId)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to load photos: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun uploadPhoto(photoPart: MultipartBody.Part, caption: String?): Flow<Result<UserPhoto>> = flow {
        val captionBody = caption?.let {
            it.toRequestBody("text/plain".toMediaTypeOrNull())
        }
        val response = profileApiService.uploadPhoto(photoPart, captionBody)
        if (response.isSuccessful && response.body() != null) {
            emit(Result.success(response.body()!!.result))
        } else {
            throw Exception("Failed to upload photo: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun deletePhoto(photoId: Int): Flow<Result<Unit>> = flow {
        val response = profileApiService.deletePhoto(photoId)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to delete photo: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }

    override suspend fun reorderPhotos(userId: Int, photos: List<UserPhoto>): Flow<Result<Unit>> = flow {
        val photoOrder = photos.mapIndexed { idx, photo -> mapOf("id" to photo.id, "position" to idx) }
        val params = mapOf("users_id" to userId, "photo_order" to photoOrder)
        val response = profileApiService.reorderPhotos(params)
        if (response.isSuccessful) {
            emit(Result.success(Unit))
        } else {
            throw Exception("Failed to reorder photos: ${response.message()}")
        }
    }.catch { e ->
        emit(Result.failure(e as? Exception ?: Exception(e.message)))
    }
}
