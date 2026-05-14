package com.networkedcapital.rep.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.networkedcapital.rep.domain.model.ActiveChat

/**
 * Room entity for caching ActiveChat data offline.
 * Maps to ActiveChat domain model for use in the app.
 */
@Entity(tableName = "active_chats")
data class ActiveChatEntity(
    @PrimaryKey val id: Int,
    val usersId: Int?,
    val chatsId: Int?,
    val name: String,
    val type: String, // "DM" or "GROUP"
    val unreadCount: Int,
    val lastMessage: String?,
    val timestamp: String?,
    val profilePictureUrl: String?,
    val lastUpdated: Long = System.currentTimeMillis()
) {
    /**
     * Converts ActiveChatEntity to ActiveChat domain model
     * TODO: Update to match new ActiveChat structure with String id
     */
    fun toDomainModel(): ActiveChat {
        // Temporarily disabled - ActiveChat model changed to match backend
        throw UnsupportedOperationException("ActiveChat caching disabled - model structure changed")
    }

    companion object {
        /**
         * Converts ActiveChat domain model to ActiveChatEntity
         * TODO: Update to match new ActiveChat structure with String id
         */
        fun fromDomainModel(chat: ActiveChat): ActiveChatEntity {
            // Temporarily disabled - ActiveChat model changed to match backend
            throw UnsupportedOperationException("ActiveChat caching disabled - model structure changed")
        }
    }
}
