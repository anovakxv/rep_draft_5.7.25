package com.networkedcapital.rep.model

enum class RepType(val displayName: String, val dbID: Int) {
    LEAD("Lead", 1),
    TEAM("Team", 2);

    companion object {
        val title = "Rep Type"
        fun fromDisplayName(name: String): RepType? = values().find { it.displayName == name }
    }
}
