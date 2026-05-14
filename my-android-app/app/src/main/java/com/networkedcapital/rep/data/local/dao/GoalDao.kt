package com.networkedcapital.rep.data.local.dao

import androidx.room.*
import com.networkedcapital.rep.data.local.entity.GoalEntity
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for Goal offline caching.
 * Provides methods to read, write, and delete goal data from Room database.
 */
@Dao
interface GoalDao {

    /**
     * Get all cached goals as a Flow (reactive updates)
     */
    @Query("SELECT * FROM goals ORDER BY lastUpdated DESC")
    fun getAllGoalsFlow(): Flow<List<GoalEntity>>

    /**
     * Get all cached goals (one-time query)
     */
    @Query("SELECT * FROM goals ORDER BY lastUpdated DESC")
    suspend fun getAllGoals(): List<GoalEntity>

    /**
     * Get a specific goal by ID
     */
    @Query("SELECT * FROM goals WHERE id = :goalId")
    suspend fun getGoalById(goalId: Int): GoalEntity?

    /**
     * Get goals by portal ID
     */
    @Query("SELECT * FROM goals WHERE portalId = :portalId ORDER BY lastUpdated DESC")
    suspend fun getGoalsByPortalId(portalId: Int): List<GoalEntity>

    /**
     * Get goals by type
     */
    @Query("SELECT * FROM goals WHERE typeName = :typeName ORDER BY lastUpdated DESC")
    suspend fun getGoalsByType(typeName: String): List<GoalEntity>

    /**
     * Insert or replace a goal
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGoal(goal: GoalEntity)

    /**
     * Insert or replace multiple goals
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGoals(goals: List<GoalEntity>)

    /**
     * Delete a specific goal
     */
    @Delete
    suspend fun deleteGoal(goal: GoalEntity)

    /**
     * Delete all goals (for clearing cache)
     */
    @Query("DELETE FROM goals")
    suspend fun deleteAllGoals()

    /**
     * Delete goals older than a certain timestamp
     */
    @Query("DELETE FROM goals WHERE lastUpdated < :timestamp")
    suspend fun deleteOldGoals(timestamp: Long)
}
