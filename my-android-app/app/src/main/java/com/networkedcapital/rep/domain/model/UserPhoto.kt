package com.networkedcapital.rep.domain.model

data class UserPhoto(
    val id: Int,
    val url: String,
    val caption: String? = null,
    val position: Int? = null,
    val created_at: String? = null,
    val updated_at: String? = null
)

data class UserPhotosResponse(
    val result: List<UserPhoto>
)

data class UserPhotoResponse(
    val result: UserPhoto
)
