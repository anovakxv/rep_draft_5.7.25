package com.networkedcapital.rep.domain.model

import com.google.gson.*
import com.google.gson.reflect.TypeToken
import java.lang.reflect.Type

/**
 * Custom deserializer for skills field in User model.
 * Handles both:
 * - List of strings (from /api/user/me endpoint)
 * - List of Skill objects (from /api/user/profile endpoint)
 */
class SkillsDeserializer : JsonDeserializer<List<String>?> {
    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?
    ): List<String>? {
        if (json == null || json.isJsonNull) {
            return null
        }

        if (!json.isJsonArray) {
            return null
        }

        val jsonArray = json.asJsonArray
        val skills = mutableListOf<String>()

        for (element in jsonArray) {
            when {
                // If it's a string, add it directly
                element.isJsonPrimitive && element.asJsonPrimitive.isString -> {
                    skills.add(element.asString)
                }
                // If it's an object with a "title" field, extract the title
                element.isJsonObject -> {
                    val titleElement = element.asJsonObject.get("title")
                    if (titleElement != null && !titleElement.isJsonNull) {
                        skills.add(titleElement.asString)
                    }
                }
                // Ignore other types
                else -> {}
            }
        }

        return skills.ifEmpty { null }
    }
}
