package com.networkedcapital.rep.domain.model

import kotlinx.serialization.Serializable

@Serializable
data class FeedItem(
    val id: Int = 0,
    val userId: Int? = null,
    val userName: String = "",
    val profilePictureUrl: String? = null,
    val date: String = "",
    val value: String = "",
    val note: String = "",
    val attachments: List<Attachment>? = null
)

@Serializable
data class Attachment(
    val id: Int = 0,
    val url: String? = null,
    val isImage: Boolean? = null,
    val fileName: String? = null,
    val note: String? = null
)
