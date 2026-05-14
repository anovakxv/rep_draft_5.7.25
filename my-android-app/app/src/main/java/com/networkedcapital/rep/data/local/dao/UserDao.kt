package com.networkedcapital.rep.data.local.dao

import androidx.room.*
import com.networkedcapital.rep.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for User offline caching.
 * Provides methods to read, write, and delete user profile data from Room database.
 */
@Dao
interface UserDao {

    /**
     * Get all cached users as a Flow (reactive updates)
     */
    @Query("SELECT * FROM users ORDER BY lastUpdated DESC")
    fun getAllUsersFlow(): Flow<List<UserEntity>>

    /**
     * Get all cached users (one-time query)
     */
    @Query("SELECT * FROM users ORDER BY lastUpdated DESC")
    suspend fun getAllUsers(): List<UserEntity>

    /**
     * Get a specific user by ID
     */
    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getUserById(userId: Int): UserEntity?

    /**
     * Get users by city
     */
    @Query("SELECT * FROM users WHERE city = :city OR manual_city = :city")
    suspend fun getUsersByCity(city: String): List<UserEntity>

    /**
     * Search users by name
     */
    @Query("SELECT * FROM users WHERE fname LIKE '%' || :query || '%' OR lname LIKE '%' || :query || '%' OR fullName LIKE '%' || :query || '%'")
    suspend fun searchUsersByName(query: String): List<UserEntity>

    /**
     * Insert or replace a user
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    /**
     * Insert or replace multiple users
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<UserEntity>)

    /**
     * Delete a specific user
     */
    @Delete
    suspend fun deleteUser(user: UserEntity)

    /**
     * Delete all users (for clearing cache)
     */
    @Query("DELETE FROM users")
    suspend fun deleteAllUsers()

    /**
     * Delete users older than a certain timestamp
     */
    @Query("DELETE FROM users WHERE lastUpdated < :timestamp")
    suspend fun deleteOldUsers(timestamp: Long)
}
