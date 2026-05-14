package com.networkedcapital.rep.data.local.dao

import androidx.room.*
import com.networkedcapital.rep.data.local.entity.ActiveChatEntity
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for ActiveChat offline caching.
 * Provides methods to read, write, and delete active chat data from Room database.
 */
@Dao
interface ActiveChatDao {

    /**
     * Get all cached active chats as a Flow (reactive updates)
     */
    @Query("SELECT * FROM active_chats ORDER BY timestamp DESC")
    fun getAllChatsFlow(): Flow<List<ActiveChatEntity>>

    /**
     * Get all cached active chats (one-time query)
     */
    @Query("SELECT * FROM active_chats ORDER BY timestamp DESC")
    suspend fun getAllChats(): List<ActiveChatEntity>

    /**
     * Get a specific chat by ID
     */
    @Query("SELECT * FROM active_chats WHERE id = :chatId")
    suspend fun getChatById(chatId: Int): ActiveChatEntity?

    /**
     * Get chats by type (DM or GROUP)
     */
    @Query("SELECT * FROM active_chats WHERE type = :type ORDER BY timestamp DESC")
    suspend fun getChatsByType(type: String): List<ActiveChatEntity>

    /**
     * Get chats with unread messages
     */
    @Query("SELECT * FROM active_chats WHERE unreadCount > 0 ORDER BY timestamp DESC")
    suspend fun getChatsWithUnread(): List<ActiveChatEntity>

    /**
     * Insert or replace a chat
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChat(chat: ActiveChatEntity)

    /**
     * Insert or replace multiple chats
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChats(chats: List<ActiveChatEntity>)

    /**
     * Update unread count for a specific chat
     */
    @Query("UPDATE active_chats SET unreadCount = :count WHERE id = :chatId")
    suspend fun updateUnreadCount(chatId: Int, count: Int)

    /**
     * Delete a specific chat
     */
    @Delete
    suspend fun deleteChat(chat: ActiveChatEntity)

    /**
     * Delete all chats (for clearing cache)
     */
    @Query("DELETE FROM active_chats")
    suspend fun deleteAllChats()

    /**
     * Delete chats older than a certain timestamp
     */
    @Query("DELETE FROM active_chats WHERE lastUpdated < :timestamp")
    suspend fun deleteOldChats(timestamp: Long)
}
