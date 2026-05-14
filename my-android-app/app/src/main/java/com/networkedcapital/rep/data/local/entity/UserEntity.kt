package com.networkedcapital.rep.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.networkedcapital.rep.domain.model.User

/**
 * Room entity for caching User profile data offline.
 * Maps to User domain model for use in the app.
 */
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: Int,
    val email: String?,
    val about: String?,
    val broadcast: String?,
    val phone: String?,
    val cities_id: Int?,
    val users_types_id: Int?,
    val fname: String?,
    val lname: String?,
    val username: String?,
    val confirmed: Boolean = true,
    val manual_city: String?,
    val other_skill: String?,
    val lat: Double?,
    val lng: Double?,
    val last_login: String?,
    val created_at: String?,
    val updated_at: String?,
    val profile_picture_url: String?,
    val fullName: String?,
    val firstName: String?,
    val lastName: String?,
    val imageName: String?,
    val userType_string: String?,
    val city: String?,
    val imageUrl: String?,
    val avatarUrl: String?,
    val is_admin: Boolean? = false,
    val lastUpdated: Long = System.currentTimeMillis()
) {
    /**
     * Converts UserEntity to User domain model
     */
    fun toDomainModel(): User {
        return User(
            id = id,
            email = email,
            about = about,
            broadcast = broadcast,
            phone = phone,
            cities_id = cities_id,
            users_types_id = users_types_id,
            fname = fname,
            lname = lname,
            username = username,
            confirmed = confirmed,
            manual_city = manual_city,
            other_skill = other_skill,
            lat = lat,
            lng = lng,
            last_login = last_login,
            created_at = created_at,
            updated_at = updated_at,
            profile_picture_url = profile_picture_url,
            fullName = fullName,
            firstName = firstName,
            lastName = lastName,
            imageName = imageName,
            userType_string = userType_string,
            city = city,
            imageUrl = imageUrl,
            avatarUrl = avatarUrl,
            is_admin = is_admin
        )
    }

    companion object {
        /**
         * Converts User domain model to UserEntity
         */
        fun fromDomainModel(user: User): UserEntity {
            return UserEntity(
                id = user.id,
                email = user.email,
                about = user.about,
                broadcast = user.broadcast,
                phone = user.phone,
                cities_id = user.cities_id,
                users_types_id = user.users_types_id,
                fname = user.fname,
                lname = user.lname,
                username = user.username,
                confirmed = user.confirmed,
                manual_city = user.manual_city,
                other_skill = user.other_skill,
                lat = user.lat,
                lng = user.lng,
                last_login = user.last_login,
                created_at = user.created_at,
                updated_at = user.updated_at,
                profile_picture_url = user.profile_picture_url,
                fullName = user.fullName,
                firstName = user.firstName,
                lastName = user.lastName,
                imageName = user.imageName,
                userType_string = user.userType_string,
                city = user.city,
                imageUrl = user.imageUrl,
                avatarUrl = user.avatarUrl,
                is_admin = user.is_admin
            )
        }
    }
}
