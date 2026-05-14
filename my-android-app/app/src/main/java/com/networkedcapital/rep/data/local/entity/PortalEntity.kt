package com.networkedcapital.rep.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.networkedcapital.rep.domain.model.Portal

/**
 * Room entity for caching Portal data offline.
 * Maps to Portal domain model for use in the app.
 */
@Entity(tableName = "portals")
data class PortalEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val subtitle: String?,
    val about: String?,
    val categoriesId: Int?,
    val citiesId: Int?,
    val leadId: Int?,
    val usersId: Int?,
    val usersCount: Int?,
    val mainImageUrl: String?,
    val description: String,
    val location: String,
    val isSafe: Boolean,
    val imageUrl: String?,
    val lastUpdated: Long = System.currentTimeMillis()
) {
    /**
     * Converts PortalEntity to Portal domain model
     */
    fun toDomainModel(): Portal {
        return Portal(
            id = id,
            name = name,
            subtitle = subtitle,
            about = about,
            categoriesId = categoriesId,
            citiesId = citiesId,
            leadId = leadId,
            usersId = usersId,
            usersCount = usersCount,
            mainImageUrl = mainImageUrl,
            description = description,
            location = location,
            isSafe = isSafe,
            imageUrl = imageUrl
        )
    }

    companion object {
        /**
         * Converts Portal domain model to PortalEntity
         */
        fun fromDomainModel(portal: Portal): PortalEntity {
            return PortalEntity(
                id = portal.id,
                name = portal.name,
                subtitle = portal.subtitle,
                about = portal.about,
                categoriesId = portal.categoriesId,
                citiesId = portal.citiesId,
                leadId = portal.leadId,
                usersId = portal.usersId,
                usersCount = portal.usersCount,
                mainImageUrl = portal.mainImageUrl,
                description = portal.description,
                location = portal.location,
                isSafe = portal.isSafe,
                imageUrl = portal.imageUrl
            )
        }
    }
}
