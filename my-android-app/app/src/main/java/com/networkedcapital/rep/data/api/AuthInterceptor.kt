package com.networkedcapital.rep.data.api

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthInterceptor @Inject constructor(
    @ApplicationContext private val context: Context
) : Interceptor {

    companion object {
        private const val AUTHORIZATION_HEADER = "Authorization"
        private const val BEARER_PREFIX = "Bearer "
        private const val PREFS_NAME = "rep_prefs"
        private const val TOKEN_KEY = "auth_token"
    }

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        
        // Get token from SharedPreferences
        val sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val token = sharedPrefs.getString(TOKEN_KEY, null)
        
        val newRequest = if (token != null && !isAuthEndpoint(originalRequest.url.encodedPath)) {
            originalRequest.newBuilder()
                .addHeader(AUTHORIZATION_HEADER, "$BEARER_PREFIX$token")
                .build()
        } else {
            originalRequest
        }
        
        return chain.proceed(newRequest)
    }
    
    private fun isAuthEndpoint(path: String): Boolean {
        return path.contains("/login") || path.contains("/register")
    }
    
    fun saveToken(token: String) {
        val sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sharedPrefs.edit()
            .putString(TOKEN_KEY, token)
            .apply()
    }
    
    fun getToken(): String? {
        val sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return sharedPrefs.getString(TOKEN_KEY, null)
    }
    
    fun clearToken() {
        val sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sharedPrefs.edit()
            .remove(TOKEN_KEY)
            .apply()
    }
}
