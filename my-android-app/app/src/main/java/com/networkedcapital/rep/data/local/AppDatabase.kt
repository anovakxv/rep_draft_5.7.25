package com.networkedcapital.rep.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.networkedcapital.rep.data.local.dao.*
import com.networkedcapital.rep.data.local.entity.*

/**
 * Main Room database for the Rep app.
 * Provides offline caching for portals, users, goals, and active chats.
 *
 * Version 1: Initial database schema with 4 entities
 */
@Database(
    entities = [
        PortalEntity::class,
        UserEntity::class,
        GoalEntity::class,
        ActiveChatEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    /**
     * Portal data access object
     */
    abstract fun portalDao(): PortalDao

    /**
     * User profile data access object
     */
    abstract fun userDao(): UserDao

    /**
     * Goal data access object
     */
    abstract fun goalDao(): GoalDao

    /**
     * Active chat data access object
     */
    abstract fun activeChatDao(): ActiveChatDao

    companion object {
        const val DATABASE_NAME = "rep_database"
    }
}
