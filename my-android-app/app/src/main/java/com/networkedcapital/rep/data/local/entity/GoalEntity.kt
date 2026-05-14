package com.networkedcapital.rep.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.networkedcapital.rep.domain.model.Goal

/**
 * Room entity for caching Goal data offline.
 * Maps to Goal domain model for use in the app.
 * Note: chartData is excluded from caching for simplicity.
 */
@Entity(tableName = "goals")
data class GoalEntity(
    @PrimaryKey val id: Int,
    val title: String,
    val subtitle: String,
    val description: String,
    val progress: Double,
    val progressPercent: Double,
    val quota: Double,
    val filledQuota: Double,
    val metricName: String,
    val typeName: String,
    val reportingName: String,
    val quotaString: String,
    val valueString: String,
    val portalName: String?,
    val portalId: Int?,
    val creatorId: Int,
    val lastUpdated: Long = System.currentTimeMillis()
) {
    /**
     * Converts GoalEntity to Goal domain model
     */
    fun toDomainModel(): Goal {
        return Goal(
            id = id,
            title = title,
            subtitle = subtitle,
            description = description,
            progress = progress,
            progressPercent = progressPercent,
            quota = quota,
            filledQuota = filledQuota,
            metricName = metricName,
            typeName = typeName,
            reportingName = reportingName,
            quotaString = quotaString,
            valueString = valueString,
            chartData = emptyList(), // Chart data not cached
            portalName = portalName,
            portalId = portalId,
            creatorId = creatorId
        )
    }

    companion object {
        /**
         * Converts Goal domain model to GoalEntity
         */
        fun fromDomainModel(goal: Goal): GoalEntity {
            return GoalEntity(
                id = goal.id,
                title = goal.title,
                subtitle = goal.subtitle,
                description = goal.description,
                progress = goal.progress,
                progressPercent = goal.progressPercent,
                quota = goal.quota,
                filledQuota = goal.filledQuota,
                metricName = goal.metricName,
                typeName = goal.typeName,
                reportingName = goal.reportingName,
                quotaString = goal.quotaString,
                valueString = goal.valueString,
                portalName = goal.portalName,
                portalId = goal.portalId,
                creatorId = goal.creatorId
            )
        }
    }
}
