package com.networkedcapital.rep.domain.model

import android.os.Parcelable
import com.google.gson.annotations.SerializedName
import com.google.gson.annotations.JsonAdapter
import com.squareup.moshi.Json
import kotlinx.parcelize.Parcelize
import kotlinx.parcelize.RawValue

@Parcelize
data class User(
    val id: Int,
    val email: String? = null,
    val about: String? = null,
    val broadcast: String? = null,
    val phone: String? = null,
    val cities_id: Int? = null,
    val users_types_id: Int? = null,
    val name: String? = null, // Full name from backend (used in iOS)
    val fname: String? = null,
    val lname: String? = null,
    val username: String? = null,
    val confirmed: Boolean = true,
    val device_token: String? = null,
    val twitter_id: String? = null,
    val manual_city: String? = null,
    val other_skill: String? = null,
    val lat: Double? = null,
    val lng: Double? = null,
    val last_login: String? = null,
    val created_at: String? = null,
    val updated_at: String? = null,
    val profile_picture_url: String? = null,
    @JsonAdapter(SkillsDeserializer::class)
    val skills: List<String>? = null,
    val userType: UserType? = null,
    // Additional fields from iOS app
    val fullName: String? = null,
    val firstName: String? = null,
    val lastName: String? = null,
    val imageName: String? = null,
    val userType_string: String? = null,
    val city: String? = null,
    val lastMessage: String? = null,
    val lastMessageDate: String? = null,
    // Add for compatibility with MainScreen
    val imageUrl: String? = null,
    val avatarUrl: String? = null,
    // Admin flag
    val is_admin: Boolean? = false
) : Parcelable {
    val displayName: String
        get() = name ?: fullName ?: fname?.let { fn ->
            lname?.let { ln -> "$fn $ln" } ?: fn
        } ?: firstName?.let { fn ->
            lastName?.let { ln -> "$fn $ln" } ?: fn
        } ?: username ?: email ?: "Unknown User"

    val repTypeAndCity: String
        get() {
            val type = userType?.name ?: userType_string ?: ""
            val cityStr = city ?: manual_city ?: ""
            return when {
                type.isNotEmpty() && cityStr.isNotEmpty() -> "Rep Type: $type   City: $cityStr"
                type.isNotEmpty() -> "Rep Type: $type"
                cityStr.isNotEmpty() -> "City: $cityStr"
                else -> ""
            }
        }

    // Compatibility properties for chat screens
    val photoUrl: String? get() = profile_picture_url ?: imageUrl ?: avatarUrl
    val profilePictureUrl: String? get() = profile_picture_url ?: imageUrl ?: avatarUrl
}

@Parcelize
data class UserType(
    val id: Int,
    val name: String
) : Parcelable

@Parcelize
data class Skill(
    val id: Int,
    val title: String
) : Parcelable

@Parcelize
data class Portal(
    val id: Int,
    val name: String,
    val subtitle: String? = null,
    val about: String? = null,
    val categoriesId: Int? = null,
    val citiesId: Int? = null,
    val leadId: Int? = null,
    val usersId: Int? = null,
    val usersCount: Int? = null,
    val mainImageUrl: String? = null,
    val description: String = "",
    val location: String = "",
    val isSafe: Boolean = false,
    val imageUrl: String? = null,
    val leads: List<User>? = emptyList() // Ensure this is present and matches MainScreen usage
) : Parcelable

@Parcelize
data class PortalDetail(
    val id: Int,
    val name: String,
    val subtitle: String? = null,
    val about: String? = null,
    @Json(name = "categories_id") val categoriesId: Int? = null,
    @Json(name = "cities_id") val citiesId: Int? = null,
    @Json(name = "lead_id") val leadId: Int? = null,
    @Json(name = "users_id") val usersId: Int? = null,
    @Json(name = "_c_users_count") val usersCount: Int? = null,
    val mainImageUrl: String? = null,
    val aGoals: List<Goal>? = null,
    val aPortalUsers: List<PortalUser>? = null,
    val aTexts: List<PortalText>? = null,
    val aSections: List<PortalSection>? = null,
    val aUsers: List<User>? = null,
    val aLeads: List<User>? = null
) : Parcelable

@Parcelize
data class PortalUser(
    val id: Int
) : Parcelable

@Parcelize
data class PortalText(
    val id: Int,
    @Json(name = "portal_id") val portalId: Int? = null,
    val title: String? = null,
    val text: String? = null,
    val section: String? = null,
    @Json(name = "created_at") val createdAt: String? = null,
    @Json(name = "updated_at") val updatedAt: String? = null
) : Parcelable

@Parcelize
data class PortalSection(
    val id: Int,
    val title: String,
    val aFiles: List<PortalFile>
) : Parcelable

@Parcelize
data class PortalFile(
    val id: Int,
    val url: String? = null
) : Parcelable

@Parcelize
data class ReportingIncrement(
    val id: Int,
    val title: String,
    val name: String? = null,  // Backward compatibility
    val value: String? = null  // Backward compatibility
) : Parcelable {
    // For backward compatibility, return title if name is null
    val displayName: String get() = name ?: title
}

@Parcelize
data class Goal(
    val id: Int,
    val title: String,
    val subtitle: String = "",
    val description: String = "",
    val progress: Double = 0.0,
    val progressPercent: Double = 0.0,
    val quota: Double = 0.0,
    val filledQuota: Double = 0.0,
    val metricName: String = "",
    val typeName: String = "",
    val reportingName: String = "",
    val quotaString: String = "",
    val valueString: String = "",
    val chartData: List<BarChartData> = emptyList(),
    val portalName: String? = null,
    val portalId: Int? = null,
    val creatorId: Int = 0
) : Parcelable

@Parcelize
data class BarChartData(
    val id: Int,
    val value: Double,
    val valueLabel: String,
    val bottomLabel: String
) : Parcelable

@Parcelize
data class Message(
    val id: Int,
    val senderId: Int,
    val senderName: String,
    val text: String,
    val timestamp: String,
    val read: String? = null
) : Parcelable

enum class RepType(val displayName: String, val dbId: Int) {
    LEAD("Lead", 1),
    SPECIALIST("Specialist", 2),
    PARTNER("Partner", 3),
    FOUNDER("Founder", 4);
    
    companion object {
        fun fromDisplayName(name: String): RepType? = values().find { it.displayName == name }
        fun fromDbId(id: Int): RepType? = values().find { it.dbId == id }
    }
}

@Parcelize
data class StoryBlock(
    val id: Int? = null,
    val type: String, // "text", "image", "video"
    val content: String, // text content or URL for media
    val title: String? = null,
    val description: String? = null,
    val order: Int = 0
) : Parcelable

@Parcelize
data class ProgressUpdate(
    val id: Int,
    val goalId: Int,
    val userId: Int,
    val progress: Int,
    val note: String? = null,
    val timestamp: String
) : Parcelable

@Parcelize
data class Team(
    val id: Int,
    val name: String,
    val members: List<User> = emptyList(),
    val goals: List<Goal> = emptyList()
) : Parcelable

// Chat models for main screen
@Parcelize
data class ActiveChat(
    val id: String,  // "direct-<userId>" or "group-<chatId>"
    val type: String, // "direct" or "group"
    val user: User? = null,  // For direct chats
    val chat: ChatModel? = null,  // For group chats
    val last_message: MessageModel? = null,
    @SerializedName("last_message_time") val last_message_time: String? = null
) : Parcelable {
    // Computed properties for convenience
    val usersId: Int?
        get() = user?.id

    val chatsId: Int?
        get() = chat?.id

    val name: String
        get() = when (type) {
            "direct" -> user?.displayName ?: "Unknown User"
            "group" -> chat?.name ?: "Group Chat"
            else -> "Chat"
        }

    val profilePictureUrl: String?
        get() = user?.profile_picture_url

    val lastMessage: String?
        get() = last_message?.text

    val timestamp: String?
        get() = last_message_time

    val unreadCount: Int
        get() = if (last_message?.read == "0") 1 else 0
}

@Parcelize
data class ChatModel(
    val id: Int,
    val name: String? = null
) : Parcelable

@Parcelize
data class MessageModel(
    val id: Int,
    @SerializedName("sender_id") val sender_id: Int? = null,
    val text: String? = null,
    @SerializedName("created_at") val created_at: String? = null,
    val read: String? = null
) : Parcelable {
    // Legacy compatibility properties
    val senderId: Int
        get() = sender_id ?: 0

    val timestamp: String
        get() = created_at ?: ""
}

// Auth models
data class LoginRequest(
    val email: String,
    val password: String
)

data class RegisterRequest(
    val firstName: String,
    val lastName: String,
    val email: String,
    val password: String,
    val phone: String? = null
)

data class AuthResponse(
    val token: String,
    val user: User
)

// API Response wrappers
data class ApiResponse<T>(
    val result: T,
    val message: String? = null
)

data class UsersApiResponse(
    val result: List<User>
)

// Network users response (for NTWK tab and chat member management)
data class NTWKUsersResponse(
    val result: List<User>
)

data class PortalsApiResponse(
    val result: List<Portal>
)

data class ActiveChatApiResponse(
    val result: List<ActiveChat>
)

data class UserProfileApiResponse(
    val result: User
)

data class PortalDetailApiResponse(
    val result: PortalDetail
)

data class PortalGoalsApiResponse(
    val aGoals: List<Goal>
)

// ====================
// Payment & Stripe Models
// ====================

@Parcelize
data class ActiveSubscription(
    val id: String,
    val name: String,
    val amount: Int, // Amount in cents
    val nextBillingDate: Long // Unix timestamp
) : Parcelable {
    val formattedAmount: String
        get() = String.format("$%.2f", amount / 100.0)

    val formattedNextBillingDate: String
        get() {
            val date = java.util.Date(nextBillingDate * 1000)
            val formatter = java.text.SimpleDateFormat("MMM dd, yyyy", java.util.Locale.getDefault())
            return formatter.format(date)
        }
}

@Parcelize
data class TransactionHistoryItem(
    val id: String, // Stripe Payment Intent ID
    val description: String,
    val amount: Int, // Amount in cents
    val date: Long // Unix timestamp
) : Parcelable {
    val formattedAmount: String
        get() = String.format("$%.2f", amount / 100.0)

    val formattedDate: String
        get() {
            val date = java.util.Date(date * 1000)
            val formatter = java.text.SimpleDateFormat("MMM dd, yyyy", java.util.Locale.getDefault())
            return formatter.format(date)
        }
}

data class SubscriptionsResponse(
    val result: List<ActiveSubscription>
)

data class PaymentHistoryResponse(
    val result: List<TransactionHistoryItem>
)

data class CancelSubscriptionRequest(
    val subscriptionId: String
)

data class CustomerPortalRequest(
    val return_url: String
)

data class CustomerPortalResponse(
    val url: String
)

data class PortalPaymentStatusResponse(
    val stripe_account_id: String?,
    val account_status: Boolean?,
    val stripe_connect_requested: Boolean?
)

data class CreateConnectAccountRequest(
    val portal_id: Int,
    val redirect_url: String
)

data class CreateConnectAccountResponse(
    val status: String?,
    val message: String?,
    val url: String?,
    val account_id: String?,
    val error: String?
)

data class StripeDashboardLinkRequest(
    val account_id: String
)

data class StripeDashboardLinkResponse(
    val url: String?,
    val error: String?
)

enum class TransactionType(val displayName: String, val apiValue: String) {
    DONATION("Donate", "donation"),
    PAYMENT("Pay", "payment"),
    PURCHASE("Purchase", "purchase");

    val subtitle: String
        get() = when (this) {
            DONATION -> "Your contribution helps this organization achieve its goals"
            PAYMENT -> "Your payment helps fund this business initiative"
            PURCHASE -> "Complete your purchase to support this business"
        }

    val amountLabel: String
        get() = when (this) {
            DONATION -> "Donation Amount"
            PAYMENT -> "Payment Amount"
            PURCHASE -> "Total Amount"
        }

    val messageLabel: String
        get() = when (this) {
            DONATION -> "Message (Optional)"
            PAYMENT -> "Notes for Recipient (Optional)"
            PURCHASE -> "Order Notes (Optional)"
        }

    val ctaText: String
        get() = when (this) {
            DONATION -> "Donate"
            PAYMENT -> "Pay"
            PURCHASE -> "Complete Purchase"
        }

    val receiptTitle: String
        get() = when (this) {
            DONATION -> "Thank You for Your Donation!"
            PAYMENT -> "Payment Complete"
            PURCHASE -> "Purchase Successful"
        }

    val receiptMessage: String
        get() = when (this) {
            DONATION -> "Your donation has been processed successfully."
            PAYMENT -> "Your payment has been processed successfully."
            PURCHASE -> "Your purchase has been completed successfully."
        }
}

data class CreateCheckoutSessionRequest(
    val portal_id: Int,
    val goal_id: Int,
    val amount: Int?, // Amount in cents (null if subscription)
    val currency: String = "usd",
    val message: String?,
    val transaction_type: String,
    val is_subscription: Boolean = false,
    val price_id: String? = null // For subscriptions
)

data class CreateCheckoutSessionResponse(
    val checkout_url: String?,
    val session_id: String?,
    val error: String?
)

data class CheckoutSessionStatusResponse(
    val payment_status: String, // "paid", "unpaid", "no_payment_required"
    val error: String?
)

// ====================
// Team Invite Models
// ====================

@Parcelize
data class GoalTeamInvite(
    val id: Int,
    val goals_id: Int,
    val users_id1: Int,
    val users_id2: Int,
    val confirmed: Int,
    val read1: Boolean,
    val read2: Boolean,
    val timestamp: String?,
    val goalTitle: String?,
    val inviterName: String?,
    val inviterPhotoURL: String?
) : Parcelable {
    val inviterDisplayName: String
        get() = inviterName ?: "Someone"

    val patchedInviterProfilePictureURL: String?
        get() {
            val urlString = inviterPhotoURL ?: return null
            if (urlString.isEmpty()) return null

            return if (urlString.startsWith("http")) {
                urlString
            } else {
                val s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"
                s3BaseURL + urlString
            }
        }
}

data class GoalTeamInvitesResponse(
    val invites: List<GoalTeamInvite>
)

data class RespondToInviteRequest(
    val action: String, // "accept" or "decline"
    val users: List<Int>
)

// MARK: - Messaging Models (Group chat specific)

@Parcelize
data class GroupMessageModel(
    val id: Int,
    @Json(name = "sender_id") val senderId: Int? = null,
    @Json(name = "sender_name") val senderName: String? = null,
    @Json(name = "sender_photo_url") val senderPhotoUrl: String? = null,
    val text: String? = null,
    val timestamp: String? = null,
    @Json(name = "chat_id") val chatId: Int? = null
) : Parcelable

@Parcelize
data class GroupMemberModel(
    val id: Int,
    @Json(name = "full_name") val fullName: String? = null,
    @Json(name = "profile_picture_url") val profilePictureUrl: String? = null
) : Parcelable

@Parcelize
data class ChatInfo(
    val id: Int,
    val name: String? = null,
    val description: String? = null,
    @SerializedName("created_by") val createdBy: Int? = null
) : Parcelable
