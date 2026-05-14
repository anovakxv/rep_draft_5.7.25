package com.networkedcapital.rep.utils

import android.util.Log
import io.socket.client.IO
import io.socket.client.Socket
import io.socket.emitter.Emitter
import org.json.JSONObject
import java.net.URI
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * SocketManager - Real-time messaging infrastructure using Socket.IO
 * Based on iOS RealtimeSocketManager.swift
 *
 * Handles WebSocket connections for:
 * - Direct messages (DM)
 * - Group chat messages
 * - Room management (join/leave)
 * - Real-time notifications
 */
object SocketManager {
    private const val TAG = "SocketManager"

    private var socket: Socket? = null
    val isConnected: Boolean
        get() = socket?.connected() == true

    private var handlersRegistered = false
    private val activelyViewingChats = mutableSetOf<Int>()

    // Track last connection parameters for deduplication
    private var lastBaseURL: String? = null
    private var lastToken: String? = null
    private var lastUserId: Int? = null
    private var pendingUserId: Int? = null

    // Observer storage for multicast notifications
    private data class DMObserver(
        val id: UUID,
        val callback: (Map<String, Any>) -> Unit
    )

    private data class GroupObserver(
        val id: UUID,
        val callback: (Map<String, Any>) -> Unit
    )

    private data class GroupNotifObserver(
        val id: UUID,
        val callback: (Map<String, Any>) -> Unit
    )

    private data class ConnectionStatusObserver(
        val id: UUID,
        val callback: (Boolean) -> Unit
    )

    private val dmObservers = ConcurrentHashMap<UUID, DMObserver>()
    private val groupObservers = ConcurrentHashMap<UUID, GroupObserver>()
    private val groupNotifObservers = ConcurrentHashMap<UUID, GroupNotifObserver>()
    private val connectionStatusObservers = ConcurrentHashMap<UUID, ConnectionStatusObserver>()

    // MARK: - Chat Registration

    fun registerActiveChat(chatId: Int) {
        val inserted = activelyViewingChats.add(chatId)
        if (inserted) {
            Log.d(TAG, "📝 Registered active viewing of chat_$chatId")
        } else {
            Log.d(TAG, "📝 (idempotent) chat_$chatId already registered active")
        }
    }

    fun unregisterActiveChat(chatId: Int) {
        if (activelyViewingChats.contains(chatId)) {
            activelyViewingChats.remove(chatId)
            Log.d(TAG, "📝 Unregistered active viewing of chat_$chatId")
        } else {
            Log.d(TAG, "📝 (idempotent) chat_$chatId not in active set")
        }
    }

    // MARK: - Public Connect

    fun connect(baseURL: String, token: String, userId: Int) {
        if (baseURL.isEmpty() || token.isEmpty() || userId == 0) return

        pendingUserId = userId

        // Normalize: strip trailing "/api" if present
        val normalizedURL = if (baseURL.endsWith("/api")) {
            baseURL.dropLast(4)
        } else {
            baseURL
        }

        // If already connected with same baseURL/token, only ensure room join
        if (socket != null && isConnected &&
            lastBaseURL == normalizedURL && lastToken == token) {
            if (lastUserId != userId) {
                lastUserId = userId
            }
            joinUserRoom(userId)
            return
        }

        // If baseURL or token changed, rebuild socket
        if (socket == null ||
            lastBaseURL != normalizedURL ||
            lastToken != token) {
            buildSocket(normalizedURL, token)
        }

        lastBaseURL = normalizedURL
        lastToken = token
        lastUserId = userId

        // Initiate connect
        socket?.connect()
    }

    fun ensureUserRoomJoined(userId: Int) {
        pendingUserId = userId
        if (isConnected) {
            joinUserRoom(userId)
        }
    }

    // MARK: - Build Socket

    private fun buildSocket(baseURL: String, token: String) {
        try {
            // Disconnect old socket if exists
            socket?.disconnect()
            socket?.off()

            val uri = URI.create(baseURL)
            val tokenPreview = if (token.length > 10) "${token.substring(0, 10)}..." else "***"
            Log.d(TAG, "🔧 Building socket:")
            Log.d(TAG, "   URL: $baseURL")
            Log.d(TAG, "   URI: ${uri.scheme}://${uri.host}:${uri.port}${uri.path}")
            Log.d(TAG, "   Token: $tokenPreview")

            val opts = IO.Options().apply {
                // Authentication
                query = "token=$token"
                extraHeaders = mapOf("Authorization" to listOf("Bearer $token"))

                // Reconnection settings
                reconnection = true
                reconnectionAttempts = Int.MAX_VALUE
                reconnectionDelay = 1000
                reconnectionDelayMax = 20000

                forceNew = true
                transports = arrayOf("websocket", "polling")
            }

            socket = IO.socket(uri, opts)
            handlersRegistered = false
            registerLifecycleHandlers()

            Log.d(TAG, "✨ Socket built successfully. Attempting connection...")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error building socket: ${e.message}", e)
        }
    }

    // MARK: - Lifecycle Handlers

    private fun registerLifecycleHandlers() {
        val socket = this.socket ?: return

        socket.on(Socket.EVENT_CONNECT) {
            Log.d(TAG, "✅ Connected -> $lastBaseURL")
            notifyConnectionStatus(true)
            pendingUserId?.let { userId ->
                joinUserRoom(userId)
            } ?: Log.w(TAG, "⚠️ No pending user id at connect")
            registerEventHandlers()
        }

        socket.on(Socket.EVENT_DISCONNECT) { args ->
            Log.d(TAG, "❌ Disconnected: ${args.joinToString()}")
            notifyConnectionStatus(false)
        }

        socket.on(Socket.EVENT_CONNECT_ERROR) { args ->
            Log.e(TAG, "🔴 Connect Error: ${args.joinToString()}")
            if (args.isNotEmpty()) {
                val error = args[0]
                Log.e(TAG, "🔴 Error details: $error")
                if (error is Exception) {
                    Log.e(TAG, "🔴 Exception: ${error.message}", error)
                }
            }
        }

        socket.on("error") { args ->
            Log.w(TAG, "⚠️ Socket Error: ${args.joinToString()}")
        }

        socket.on("reconnect") { args ->
            Log.d(TAG, "🔄 Reconnected: ${args.joinToString()}")
        }

        socket.on("reconnect_attempt") { args ->
            Log.d(TAG, "🔄 Reconnect attempt: ${args.joinToString()}")
        }

        socket.on("reconnect_failed") { args ->
            Log.e(TAG, "🔴 Reconnect failed: ${args.joinToString()}")
        }

        socket.on("reconnect_error") { args ->
            Log.e(TAG, "🔴 Reconnect error: ${args.joinToString()}")
        }
    }

    // MARK: - Event Handlers

    private fun registerEventHandlers() {
        if (handlersRegistered) return
        val socket = this.socket ?: return

        handlersRegistered = true
        Log.d(TAG, "🧩 Registering event handlers")

        // Direct message events - support multiple possible names
        val dmEventNames = listOf(
            "direct_message_notification",
            "new_direct_message",
            "direct_message",
            "dm_notification"
        )

        val dmHandler = Emitter.Listener { args ->
            if (args.isNotEmpty()) {
                val data = args[0]
                val payload = when (data) {
                    is JSONObject -> data.toMap()
                    else -> null
                }
                payload?.let { notifyDirectMessage(it) }
            }
        }

        dmEventNames.forEach { eventName ->
            socket.on(eventName, dmHandler)
        }

        // Group message event
        socket.on("group_message") { args ->
            if (args.isNotEmpty()) {
                val data = args[0]
                val payload = when (data) {
                    is JSONObject -> data.toMap()
                    else -> null
                }
                payload?.let { dict ->
                    groupObservers.values.forEach { observer ->
                        observer.callback(dict)
                    }
                }
            }
        }

        // Group message notification (to personal room)
        socket.on("group_message_notification") { args ->
            if (args.isNotEmpty()) {
                val data = args[0]
                val payload = when (data) {
                    is JSONObject -> data.toMap()
                    else -> null
                }
                payload?.let { dict ->
                    groupNotifObservers.values.forEach { observer ->
                        observer.callback(dict)
                    }
                }
            }
        }
    }

    // MARK: - Notify Helpers

    private fun notifyDirectMessage(payload: Map<String, Any>) {
        dmObservers.values.forEach { observer ->
            observer.callback(payload)
        }
    }

    private fun notifyConnectionStatus(connected: Boolean) {
        connectionStatusObservers.values.forEach { observer ->
            observer.callback(connected)
        }
    }

    // MARK: - Public Listener Registration

    fun onDirectMessageNotification(callback: (Map<String, Any>) -> Unit): UUID {
        val id = UUID.randomUUID()
        dmObservers[id] = DMObserver(id, callback)
        return id
    }

    fun removeDirectMessageObserver(id: UUID) {
        dmObservers.remove(id)
    }

    fun onGroupMessage(callback: (Map<String, Any>) -> Unit): UUID {
        val id = UUID.randomUUID()
        groupObservers[id] = GroupObserver(id, callback)
        return id
    }

    fun removeGroupMessageObserver(id: UUID) {
        groupObservers.remove(id)
    }

    fun onGroupMessageNotification(callback: (Map<String, Any>) -> Unit): UUID {
        val id = UUID.randomUUID()
        groupNotifObservers[id] = GroupNotifObserver(id, callback)
        return id
    }

    fun removeGroupMessageNotificationObserver(id: UUID) {
        groupNotifObservers.remove(id)
    }

    fun onConnectionStatusChange(callback: (Boolean) -> Unit): UUID {
        val id = UUID.randomUUID()
        connectionStatusObservers[id] = ConnectionStatusObserver(id, callback)
        // Immediately call with current status
        callback(isConnected)
        return id
    }

    fun removeConnectionStatusObserver(id: UUID) {
        connectionStatusObservers.remove(id)
    }

    // MARK: - Room Management

    private fun joinUserRoom(userId: Int) {
        val data = JSONObject().apply {
            put("user_id", userId)
        }
        socket?.emit("join_user_room", data)
        Log.d(TAG, "➡️ join_user_room user_$userId")
    }

    fun joinGroupChat(chatId: Int) {
        if (!activelyViewingChats.contains(chatId)) {
            Log.d(TAG, "🛑 Prevented join for non-active chat_$chatId")
            return
        }

        val data = JSONObject().apply {
            put("chat_id", chatId)
        }
        socket?.emit("join_group_chat", data)
        Log.d(TAG, "➡️ join group chat $chatId")
    }

    fun leaveGroupChat(chatId: Int) {
        val data = JSONObject().apply {
            put("chat_id", chatId)
        }
        socket?.emit("leave_group_chat", data)
        Log.d(TAG, "⬅️ leave group chat $chatId")
    }

    // MARK: - Connection Control

    fun disconnect() {
        socket?.disconnect()
        // isConnected is now a computed property, no need to set it manually
    }

    fun reconnectIfNeeded() {
        val socket = this.socket ?: return
        if (!socket.connected()) {
            Log.d(TAG, "🔄 Reconnecting...")
            socket.connect()
        }
    }

    fun cleanupAllHandlers() {
        dmObservers.clear()
        groupObservers.clear()
        groupNotifObservers.clear()
        connectionStatusObservers.clear()
        Log.d(TAG, "🧹 All handlers cleaned up")
    }
}

// Helper extension to convert JSONObject to Map
private fun JSONObject.toMap(): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    keys().forEach { key ->
        val value = get(key)
        map[key] = value
    }
    return map
}
