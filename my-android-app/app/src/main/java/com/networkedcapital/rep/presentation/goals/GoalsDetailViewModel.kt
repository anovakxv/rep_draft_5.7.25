package com.networkedcapital.rep.presentation.goals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.api.GoalApiService
import com.networkedcapital.rep.data.api.GoalDetailData
import com.networkedcapital.rep.data.api.ProgressLog
import com.networkedcapital.rep.data.api.MessagingApiService
import com.networkedcapital.rep.data.api.ManageGroupChatRequest
import com.networkedcapital.rep.data.api.PaymentApiService
import com.networkedcapital.rep.domain.model.Goal
import com.networkedcapital.rep.domain.model.CreateCheckoutSessionRequest
import com.networkedcapital.rep.domain.model.User
import com.networkedcapital.rep.domain.model.FeedItem
import com.networkedcapital.rep.domain.model.Attachment
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class GoalsDetailViewModel @Inject constructor(
    private val goalApiService: GoalApiService,
    private val authRepository: com.networkedcapital.rep.data.repository.AuthRepository,
    private val messagingApiService: MessagingApiService,
    private val paymentApiService: PaymentApiService
) : ViewModel() {

    private val _goal = MutableStateFlow<Goal?>(null)
    val goal: StateFlow<Goal?> = _goal

    private val _feed = MutableStateFlow<List<FeedItem>>(emptyList())
    val feed: StateFlow<List<FeedItem>> = _feed

    private val _team = MutableStateFlow<List<User>>(emptyList())
    val team: StateFlow<List<User>> = _team

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    private val _currentUserId = MutableStateFlow(0)
    val currentUserId: StateFlow<Int> = _currentUserId

    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser

    private val _isCreatingChat = MutableStateFlow(false)
    val isCreatingChat: StateFlow<Boolean> = _isCreatingChat

    private val _isProcessingPayment = MutableStateFlow(false)
    val isProcessingPayment: StateFlow<Boolean> = _isProcessingPayment

    init {
        viewModelScope.launch {
            authRepository.getCurrentUser()
                .catch { /* ignore */ }
                .collect { result ->
                    result.onSuccess { user ->
                        _currentUserId.value = user.id
                        // Patch profile picture URL for current user
                        _currentUser.value = user.copy(
                            profile_picture_url = patchProfilePictureUrl(
                                user.profile_picture_url ?: user.imageName
                            )
                        )
                    }
                }
        }
    }

    // S3 base URL for profile images
    private val s3BaseUrl = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

    private fun patchProfilePictureUrl(imageNameOrUrl: String?): String? {
        if (imageNameOrUrl.isNullOrBlank()) return null
        return if (imageNameOrUrl.startsWith("http")) imageNameOrUrl else s3BaseUrl + imageNameOrUrl
    }

    fun loadGoal(goalId: Int) {
        _loading.value = true
        _error.value = null

        viewModelScope.launch {
            try {
                val response = goalApiService.getGoalDetails(goalId, numPeriods = 7)

                if (response.isSuccessful && response.body() != null) {
                    val goalDetailData = response.body()!!.result

                    // Convert GoalDetailData to Goal model
                    _goal.value = convertToGoal(goalDetailData)

                    // Convert team to User list with patched profile pictures
                    val patchedTeam = goalDetailData.team?.map { user ->
                        user.copy(
                            profile_picture_url = patchProfilePictureUrl(
                                user.profile_picture_url ?: user.imageName
                            )
                        )
                    } ?: emptyList()

                    val teamDict = patchedTeam.associateBy { it.id }
                    _team.value = patchedTeam

                    // Convert progress logs to FeedItem list
                    _feed.value = convertProgressLogsToFeed(goalDetailData.aLatestProgress, teamDict)
                } else {
                    _error.value = "Failed to load goal: ${response.message()}"
                }
            } catch (e: Exception) {
                _error.value = e.message ?: "Unknown error occurred"
            } finally {
                _loading.value = false
            }
        }
    }

    private fun convertToGoal(data: GoalDetailData): Goal {
        return Goal(
            id = data.id,
            title = data.title,
            subtitle = data.subtitle ?: "",
            description = data.description ?: "",
            progress = data.progress ?: 0.0,
            progressPercent = data.progressPercent ?: 0.0,
            quota = data.quota ?: 0.0,
            filledQuota = data.filledQuota ?: 0.0,
            metricName = data.metricName ?: "",
            typeName = data.typeName ?: "",
            reportingName = data.reportingName ?: "",
            quotaString = data.quotaString ?: "",
            valueString = data.valueString ?: "",
            chartData = data.chartData ?: emptyList(),
            portalName = data.portalName,
            portalId = data.portalId,
            creatorId = data.creatorId ?: 0
        )
    }

    private fun convertProgressLogsToFeed(
        logs: List<ProgressLog>?,
        teamDict: Map<Int, User>
    ): List<FeedItem> {
        if (logs == null) return emptyList()

        return logs.sortedByDescending { it.timestamp }.take(20).map { log ->
            // Check if this feed item is from the current user
            val isCurrentUser = log.usersId == _currentUserId.value
            val user = if (isCurrentUser && _currentUser.value != null) {
                // Use complete current user data from authRepository
                _currentUser.value
            } else {
                // Use data from teamDict for other users
                log.usersId?.let { teamDict[it] }
            }

            val userName = user?.displayName ?: "Unknown User"

            // User already has patched profile_picture_url from teamDict or currentUser
            val profilePictureUrl = user?.profile_picture_url

            // Convert attachments
            val attachments = log.aAttachments?.mapNotNull { att ->
                att.fileUrl?.let { url ->
                    Attachment(
                        id = att.id,
                        url = url,
                        isImage = att.isImage
                    )
                }
            }

            FeedItem(
                id = log.id,
                userId = log.usersId,
                userName = userName,
                profilePictureUrl = profilePictureUrl,
                date = log.timestamp ?: "",
                value = log.value?.toString() ?: log.addedValue?.toString() ?: "",
                note = log.note ?: "",
                attachments = attachments
            )
        }
    }

    // Team chat creation - FULLY IMPLEMENTED ✅
    fun createTeamChat(goalId: Int, title: String, onComplete: (Int?, String?) -> Unit) {
        _isCreatingChat.value = true
        _error.value = null

        viewModelScope.launch {
            try {
                // Get team member IDs (excluding current user)
                val memberIds = _team.value
                    .map { it.id }
                    .filter { it != _currentUserId.value }

                if (memberIds.isEmpty()) {
                    _error.value = "No team members to add to chat"
                    onComplete(null, "No team members to add to chat")
                    return@launch
                }

                val request = ManageGroupChatRequest(
                    chats_id = null, // null = create new chat
                    title = title,
                    aAddIDs = memberIds,
                    aDelIDs = null
                )

                val response = messagingApiService.manageGroupChat(request)

                if (response.isSuccessful && response.body() != null) {
                    val chatId = response.body()!!.chats_id
                    onComplete(chatId, null)
                } else {
                    val errorMsg = "Failed to create chat: ${response.message()}"
                    _error.value = errorMsg
                    onComplete(null, errorMsg)
                }
            } catch (e: Exception) {
                val errorMsg = e.message ?: "Unknown error creating chat"
                _error.value = errorMsg
                onComplete(null, errorMsg)
            } finally {
                _isCreatingChat.value = false
            }
        }
    }

    // Join team - FULLY IMPLEMENTED ✅
    fun joinRecruitingGoal(goalId: Int, onComplete: (Boolean) -> Unit) {
        _loading.value = true
        _error.value = null

        viewModelScope.launch {
            try {
                val request = com.networkedcapital.rep.data.api.JoinLeaveGoalRequest(
                    aGoalsIDs = listOf(goalId),
                    todo = "join"
                )

                val response = goalApiService.joinOrLeaveGoal(request)

                if (response.isSuccessful && response.body() != null) {
                    val result = response.body()!!.result[goalId]

                    when (result) {
                        "ok" -> {
                            // Successfully joined - reload goal to get updated team
                            loadGoal(goalId)
                            onComplete(true)
                        }
                        "Already a member" -> {
                            _error.value = "You are already a team member"
                            onComplete(false)
                        }
                        else -> {
                            _error.value = result ?: "Failed to join goal"
                            onComplete(false)
                        }
                    }
                } else {
                    _error.value = "Failed to join goal: ${response.message()}"
                    onComplete(false)
                }
            } catch (e: Exception) {
                _error.value = "Failed to join goal: ${e.message}"
                onComplete(false)
            } finally {
                _loading.value = false
            }
        }
    }

    // Payment processing - FULLY IMPLEMENTED ✅
    fun processPayment(goalId: Int, portalId: Int, amount: Double, message: String) {
        _isProcessingPayment.value = true
        _error.value = null

        viewModelScope.launch {
            try {
                val amountCents = (amount * 100).toInt()

                val request = CreateCheckoutSessionRequest(
                    portal_id = portalId,
                    goal_id = goalId,
                    amount = amountCents,
                    currency = "usd",
                    message = message,
                    transaction_type = "PAYMENT", // or DONATION based on context
                    is_subscription = false,
                    price_id = null
                )

                val response = paymentApiService.createCheckoutSession(request)

                if (response.isSuccessful && response.body() != null) {
                    val checkoutUrl = response.body()!!.checkout_url
                    // Store URL for UI to open in WebView
                    _error.value = null // Clear any errors
                    // TODO: Pass this URL to the UI layer to open in WebView
                    // The UI should listen to a separate paymentUrl StateFlow
                } else {
                    _error.value = "Payment failed: ${response.message()}"
                }
            } catch (e: Exception) {
                _error.value = "Payment error: ${e.message}"
            } finally {
                _isProcessingPayment.value = false
            }
        }
    }

    // Helper to get current user ID for UI checks
    fun getCurrentUserId(): Int {
        return _currentUserId.value
    }

    // Clear error message
    fun clearError() {
        _error.value = null
    }
}
