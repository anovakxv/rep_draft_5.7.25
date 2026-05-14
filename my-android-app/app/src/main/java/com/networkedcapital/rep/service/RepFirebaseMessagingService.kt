package com.networkedcapital.rep.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.networkedcapital.rep.MainActivity
import com.networkedcapital.rep.R
import com.networkedcapital.rep.data.api.ApiConfig
import com.networkedcapital.rep.data.repository.UserRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class RepFirebaseMessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var userRepository: UserRepository

    companion object {
        private const val TAG = "RepFCM"
        private const val CHANNEL_ID = "rep_messages"
        private const val CHANNEL_NAME = "Messages"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    /**
     * Called when a new FCM token is generated
     * This happens on first install and when the token is rotated
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")

        // Send token to backend
        sendTokenToBackend(token)
    }

    /**
     * Called when a push notification is received while app is in foreground or background
     */
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        Log.d(TAG, "Message received from: ${message.from}")
        Log.d(TAG, "Message data: ${message.data}")

        // Handle notification payload
        val notificationType = message.data["type"] ?: ""
        val title = message.notification?.title ?: message.data["title"] ?: "New Message"
        val body = message.notification?.body ?: message.data["body"] ?: ""

        when (notificationType) {
            "direct_message" -> handleDirectMessage(title, body, message.data)
            "group_message" -> handleGroupMessage(title, body, message.data)
            else -> {
                // Generic notification
                if (title.isNotEmpty() && body.isNotEmpty()) {
                    showNotification(title, body, message.data)
                }
            }
        }
    }

    private fun handleDirectMessage(title: String, body: String, data: Map<String, String>) {
        val senderId = data["sender_id"]?.toIntOrNull()
        val messageId = data["message_id"]?.toIntOrNull()

        Log.d(TAG, "Direct message from user $senderId, message $messageId")

        showNotification(
            title = title,
            body = body,
            data = data,
            notificationId = senderId ?: System.currentTimeMillis().toInt()
        )
    }

    private fun handleGroupMessage(title: String, body: String, data: Map<String, String>) {
        val chatId = data["chat_id"]?.toIntOrNull()
        val senderId = data["sender_id"]?.toIntOrNull()
        val messageId = data["message_id"]?.toIntOrNull()

        Log.d(TAG, "Group message in chat $chatId from user $senderId, message $messageId")

        showNotification(
            title = title,
            body = body,
            data = data,
            notificationId = chatId ?: System.currentTimeMillis().toInt()
        )
    }

    private fun showNotification(
        title: String,
        body: String,
        data: Map<String, String>,
        notificationId: Int = System.currentTimeMillis().toInt()
    ) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            // Add data extras for deep linking
            data.forEach { (key, value) ->
                putExtra(key, value)
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Using Android system icon
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notificationBuilder.build())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for new messages"
                enableVibration(true)
                enableLights(true)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun sendTokenToBackend(token: String) {
        // Get JWT token from SharedPreferences
        val prefs = getSharedPreferences("auth_prefs", Context.MODE_PRIVATE)
        val jwtToken = prefs.getString("jwt_token", null)
        val userId = prefs.getInt("user_id", 0)

        if (jwtToken.isNullOrEmpty() || userId == 0) {
            Log.d(TAG, "No JWT token or user ID found, will send token after login")
            // Save the token for later
            prefs.edit().putString("pending_fcm_token", token).apply()
            return
        }

        // Send token to backend
        CoroutineScope(Dispatchers.IO).launch {
            try {
                userRepository.updateDeviceToken(token)
                Log.d(TAG, "Successfully sent FCM token to backend")
                // Clear pending token
                prefs.edit().remove("pending_fcm_token").apply()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send FCM token to backend: ${e.message}", e)
                // Save for retry
                prefs.edit().putString("pending_fcm_token", token).apply()
            }
        }
    }
}
