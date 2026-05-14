package com.networkedcapital.rep.api

import com.networkedcapital.rep.model.RepSkill
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

suspend fun fetchSkills(jwtToken: String): List<RepSkill> = withContext(Dispatchers.IO) {
    val url = URL("https://rep-june2025.onrender.com/api/user/get_skills")
    val connection = url.openConnection() as HttpURLConnection
    connection.requestMethod = "GET"
    if (jwtToken.isNotEmpty()) {
        connection.setRequestProperty("Authorization", "Bearer $jwtToken")
    }
    val responseCode = connection.responseCode
    if (responseCode == 200) {
        val response = connection.inputStream.bufferedReader().readText()
        val json = JSONObject(response)
        val resultArray = json.optJSONArray("result") ?: JSONArray()
        val skills = mutableListOf<RepSkill>()
        for (i in 0 until resultArray.length()) {
            val skillName = resultArray.optJSONObject(i)?.optString("title") ?: ""
            RepSkill.fromDisplayName(skillName)?.let { skills.add(it) }
        }
        skills
    } else {
        emptyList()
    }
}
