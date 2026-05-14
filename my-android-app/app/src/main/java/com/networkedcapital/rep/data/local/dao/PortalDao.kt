package com.networkedcapital.rep.data.local.dao

import androidx.room.*
import com.networkedcapital.rep.data.local.entity.PortalEntity
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for Portal offline caching.
 * Provides methods to read, write, and delete portal data from Room database.
 */
@Dao
interface PortalDao {

    /**
     * Get all cached portals as a Flow (reactive updates)
     */
    @Query("SELECT * FROM portals ORDER BY lastUpdated DESC")
    fun getAllPortalsFlow(): Flow<List<PortalEntity>>

    /**
     * Get all cached portals (one-time query)
     */
    @Query("SELECT * FROM portals ORDER BY lastUpdated DESC")
    suspend fun getAllPortals(): List<PortalEntity>

    /**
     * Get a specific portal by ID
     */
    @Query("SELECT * FROM portals WHERE id = :portalId")
    suspend fun getPortalById(portalId: Int): PortalEntity?

    /**
     * Get portals by safe status
     */
    @Query("SELECT * FROM portals WHERE isSafe = :isSafe ORDER BY lastUpdated DESC")
    suspend fun getPortalsBySafeStatus(isSafe: Boolean): List<PortalEntity>

    /**
     * Insert or replace a portal
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPortal(portal: PortalEntity)

    /**
     * Insert or replace multiple portals
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPortals(portals: List<PortalEntity>)

    /**
     * Delete a specific portal
     */
    @Delete
    suspend fun deletePortal(portal: PortalEntity)

    /**
     * Delete all portals (for clearing cache)
     */
    @Query("DELETE FROM portals")
    suspend fun deleteAllPortals()

    /**
     * Delete portals older than a certain timestamp
     */
    @Query("DELETE FROM portals WHERE lastUpdated < :timestamp")
    suspend fun deleteOldPortals(timestamp: Long)
}
