package com.networkedcapital.rep.domain.model

import com.squareup.moshi.FromJson
import com.squareup.moshi.JsonReader
import com.squareup.moshi.ToJson

/**
 * Moshi adapter for skills field in User model.
 * Handles both:
 * - List of strings (from some endpoints)
 * - List of Skill objects with "title" field (from /api/user/profile endpoint)
 */
class SkillsJsonAdapter {

    @FromJson
    fun fromJson(reader: JsonReader): List<String>? {
        val skills = mutableListOf<String>()

        if (reader.peek() == JsonReader.Token.NULL) {
            reader.nextNull<Unit>()
            return null
        }

        if (reader.peek() != JsonReader.Token.BEGIN_ARRAY) {
            reader.skipValue()
            return null
        }

        reader.beginArray()
        while (reader.hasNext()) {
            when (reader.peek()) {
                JsonReader.Token.STRING -> {
                    // It's a string, add it directly
                    skills.add(reader.nextString())
                }
                JsonReader.Token.BEGIN_OBJECT -> {
                    // It's an object, look for "title" field
                    reader.beginObject()
                    var title: String? = null
                    while (reader.hasNext()) {
                        when (reader.nextName()) {
                            "title" -> title = reader.nextString()
                            else -> reader.skipValue()
                        }
                    }
                    reader.endObject()
                    title?.let { skills.add(it) }
                }
                else -> {
                    // Unknown type, skip it
                    reader.skipValue()
                }
            }
        }
        reader.endArray()

        return skills.ifEmpty { null }
    }

    @ToJson
    fun toJson(skills: List<String>?): List<String>? {
        return skills
    }
}
