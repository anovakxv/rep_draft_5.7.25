package com.networkedcapital.rep.domain.model

data class WriteBlock(
    val id: Int,
    val title: String? = null,
    val content: String,
    val order: Int? = null,
    val created_at: String? = null,
    val updated_at: String? = null
)

data class WriteBlocksResponse(
    val result: List<WriteBlock>
)

data class WriteBlockResponse(
    val result: WriteBlock
)
