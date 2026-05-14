package com.networkedcapital.rep.presentation.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.AuthRepository
import com.networkedcapital.rep.data.repository.PortalRepository
import com.networkedcapital.rep.data.repository.InviteRepository
import com.networkedcapital.rep.domain.model.*
import com.networkedcapital.rep.utils.SocketManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MainUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val currentPage: MainViewModel.MainPage = MainViewModel.MainPage.PORTALS, // Start with Portals on Purpose tab
    val selectedSection: Int = 2, // Start on Purpose tab (0=Chats, 1=Network, 2=Purpose)
    val showSearch: Boolean = false,
    val searchQuery: String = "",
    val isSearching: Boolean = false,
    val showOnlySafePortals: Boolean = false,
    val currentUser: User? = null,
    val portals: List<Portal> = emptyList(),
    val users: List<User> = emptyList(),
    val activeChats: List<ActiveChat> = emptyList(),
    val searchPortals: List<Portal> = emptyList(),
    val searchUsers: List<User> = emptyList()
)

data class UnreadMessageStats(
    val hasUnreadDirectMessages: Boolean = false,
    val hasUnreadGroupMessages: Boolean = false
)

@HiltViewModel
class MainViewModel @Inject constructor(
    private val portalRepository: PortalRepository,
    private val authRepository: AuthRepository,
    private val inviteRepository: InviteRepository
) : ViewModel() {

    enum class MainPage { PORTALS, PEOPLE }

    // S3 base URL for image patching (same as backend and iOS)
    private val s3BaseUrl = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()
    
    // NEW: Unread message tracking and notification state
    private val _hasUnreadDirectMessages = MutableStateFlow(false)
    val hasUnreadDirectMessages: StateFlow<Boolean> = _hasUnreadDirectMessages.asStateFlow()

    private val _hasUnreadGroupMessages = MutableStateFlow(false)
    val hasUnreadGroupMessages: StateFlow<Boolean> = _hasUnreadGroupMessages.asStateFlow()

    private val _openNeedsAttention = MutableStateFlow(false)
    val openNeedsAttention: StateFlow<Boolean> = _openNeedsAttention.asStateFlow()
    
    // NEW: Background data caching
    private val backgroundPortalsTab0 = MutableStateFlow<List<Portal>>(emptyList())
    private val backgroundPortalsTab1 = MutableStateFlow<List<Portal>>(emptyList())
    private val backgroundPortalsTab2 = MutableStateFlow<List<Portal>>(emptyList())

    private val backgroundUsersTab0 = MutableStateFlow<List<ActiveChat>>(emptyList())
    private val backgroundUsersTab1 = MutableStateFlow<List<User>>(emptyList())
    private val backgroundUsersTab2 = MutableStateFlow<List<User>>(emptyList())

    private var searchJob: Job? = null

    /**
     * Patches image URLs to use full S3 URLs if they're just file names.
     * Matches iOS patchProfilePictureURL() and backend patch functions.
     */
    private fun patchImageUrl(imageNameOrUrl: String?): String? {
        if (imageNameOrUrl.isNullOrBlank()) return null
        return if (imageNameOrUrl.startsWith("http")) {
            imageNameOrUrl
        } else {
            s3BaseUrl + imageNameOrUrl
        }
    }

    /**
     * Patches a portal's mainImageUrl and copies it to imageUrl.
     * Backend returns mainImageUrl, but UI uses imageUrl, so we must copy it over.
     */
    private fun patchPortalImage(portal: Portal): Portal {
        val patchedMainImage = patchImageUrl(portal.mainImageUrl)
        return portal.copy(
            mainImageUrl = patchedMainImage,
            imageUrl = patchedMainImage  // Copy mainImageUrl to imageUrl for UI compatibility
        )
    }

    /**
     * Patches a user's profile picture URL.
     */
    private fun patchUserImage(user: User): User {
        val patchedUrl = patchImageUrl(user.profile_picture_url ?: user.imageName)
        return user.copy(
            profile_picture_url = patchedUrl,
            imageUrl = patchedUrl,
            avatarUrl = patchedUrl
        )
    }

    /**
     * Patches an ActiveChat's profilePictureUrl with S3 base URL.
     */
    private fun patchActiveChatImage(chat: ActiveChat): ActiveChat {
        // For direct chats, patch the user's profile picture
        val patchedUser = chat.user?.let { user ->
            patchUserImage(user)
        }
        return chat.copy(
            user = patchedUser
        )
    }

    init {
        // Debounced search
        searchQuery
            .debounce(400)
            .onEach { query ->
                if (_uiState.value.showSearch && query.isNotEmpty()) {
                    performSearch(query)
                }
            }
            .launchIn(viewModelScope)
    }

    fun onSectionSelected(section: String) {
        val sectionIndex = when (section) {
            "OPEN" -> 0
            "NTWK" -> 1
            "ALL" -> 2
            else -> 2
        }
        val userId = _uiState.value.currentUser?.id ?: 0
        onSectionChanged(sectionIndex, userId)
    }

    // NEW: Recalculate attention state (for badges)
    fun recalculateAttentionState() {
        val hasUnread = _hasUnreadDirectMessages.value || _hasUnreadGroupMessages.value
        viewModelScope.launch {
            val hasPendingInvites = try {
                inviteRepository.getPendingInvites()
                    .firstOrNull()
                    ?.getOrNull()
                    ?.isNotEmpty() ?: false
            } catch (e: Exception) {
                false
            }
            _openNeedsAttention.value = hasUnread || hasPendingInvites
        }
    }

    // NEW: Check for unread messages
    fun checkForUnreadMessages() {
        viewModelScope.launch {
            try {
                // TODO: Implement getUnreadMessageStats in PortalRepository
                // For now, rely on socket notifications to update unread state
                recalculateAttentionState()
            } catch (e: Exception) {
                // Silently handle errors
            }
        }
    }

    // NEW: Set up socket connections for real-time updates
    fun setupSocketNotifications(baseURL: String, token: String, userId: Int) {
        android.util.Log.d("MainViewModel", "🔧 setupSocketNotifications called - baseURL=$baseURL, userId=$userId, tokenEmpty=${token.isEmpty()}")
        viewModelScope.launch {
            try {
                if (token.isNotEmpty() && userId > 0) {
                    android.util.Log.d("MainViewModel", "📡 Calling SocketManager.connect()")
                    SocketManager.connect(baseURL, token, userId)

                    SocketManager.onDirectMessageNotification { payload ->
                        val senderId = (payload["sender_id"] as? Number)?.toInt() ?: 0
                        if (senderId != userId) {
                            _hasUnreadDirectMessages.value = true
                            recalculateAttentionState()

                            // Fetch updated chat list after a delay
                            viewModelScope.launch {
                                delay(1500)
                                if (_uiState.value.currentPage == MainPage.PEOPLE &&
                                    _uiState.value.selectedSection == 0) {
                                    fetchPeople(userId, 0, true)
                                }
                            }
                        }
                    }

                    SocketManager.onGroupMessageNotification { payload ->
                        val senderId = (payload["sender_id"] as? Number)?.toInt() ?: 0
                        if (senderId != userId) {
                            _hasUnreadGroupMessages.value = true
                            recalculateAttentionState()

                            // Fetch updated chat list after a delay
                            viewModelScope.launch {
                                delay(1500)
                                if (_uiState.value.currentPage == MainPage.PEOPLE &&
                                    _uiState.value.selectedSection == 0) {
                                    fetchPeople(userId, 0, true)
                                }
                            }
                        }
                    }
                } else {
                    android.util.Log.w("MainViewModel", "❌ Skipping socket connection - token empty or invalid userId")
                }
            } catch (e: Exception) {
                android.util.Log.e("MainViewModel", "❌ Socket connection error: ${e.message}", e)
            }
        }
    }

    // NEW: Background data loading
    fun loadBackgroundData(from: Int, to: Int, userId: Int) {
        viewModelScope.launch {
            // Don't override current tab data
            if (from == to) return@launch
            
            when (_uiState.value.currentPage) {
                MainPage.PORTALS -> {
                    // Load background portal data
                    try {
                        val tab = when (to) {
                            0 -> "open"
                            1 -> "ntwk"
                            2 -> "all"
                            else -> "open"
                        }
                        val safeOnly = _uiState.value.showOnlySafePortals
                        val portals = portalRepository.getFilteredPortals(userId, tab, safeOnly)
                        val patchedPortals = portals.map { patchPortalImage(it) }
                        when (to) {
                            0 -> backgroundPortalsTab0.value = patchedPortals
                            1 -> backgroundPortalsTab1.value = patchedPortals
                            2 -> backgroundPortalsTab2.value = patchedPortals
                        }
                    } catch (e: Exception) {
                        // Silently fail for background loads
                    }
                }
                MainPage.PEOPLE -> {
                    // Load background people data
                    try {
                        if (to == 0) {
                            val chats = portalRepository.getActiveChats(userId)
                            val patchedChats = chats.map { patchActiveChatImage(it) }
                            backgroundUsersTab0.value = patchedChats
                        } else {
                            val tab = if (to == 1) "ntwk" else "all"
                            val users = portalRepository.getFilteredPeople(userId, tab)
                            val patchedUsers = users.map { patchUserImage(it) }
                            if (to == 1) backgroundUsersTab1.value = patchedUsers
                            else backgroundUsersTab2.value = patchedUsers
                        }
                    } catch (e: Exception) {
                        // Silently fail for background loads
                    }
                }
            }
        }
    }

    fun loadData(userId: Int) {
        viewModelScope.launch {
            _uiState.update { state -> state.copy(isLoading = true, errorMessage = null) }
            try {
                // Fetch current user
                fetchCurrentUser()
                
                // Fetch content based on current page and section
                when (_uiState.value.currentPage) {
                    MainPage.PORTALS -> fetchPortals(userId, _uiState.value.selectedSection, _uiState.value.showOnlySafePortals)
                    MainPage.PEOPLE -> fetchPeople(userId, _uiState.value.selectedSection)
                }
                
                // Check for unread messages
                checkForUnreadMessages()
                
                // Start loading background data for other tabs
                val currentSection = _uiState.value.selectedSection
                viewModelScope.launch {
                    delay(500)
                    loadBackgroundData(currentSection, (currentSection + 1) % 3, userId)
                    loadBackgroundData(currentSection, (currentSection + 2) % 3, userId)
                }
            } catch (e: Exception) {
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        errorMessage = e.message ?: "Unknown error occurred"
                    )
                }
            }
        }
    }

    // ENHANCED: Use background cached data and load background data
    // Tab changes should NOT switch between People/Portals pages - only Rep Logo does that
    fun onSectionChanged(section: Int, userId: Int) {
        val oldSection = _uiState.value.selectedSection
        _uiState.update { state -> state.copy(selectedSection = section) }

        // Section 0 (Chats) ALWAYS shows active chats, regardless of currentPage
        if (section == 0) {
            // Use background data first if available
            val backgroundChats = backgroundUsersTab0.value
            if (backgroundChats.isNotEmpty()) {
                _uiState.update { it.copy(activeChats = backgroundChats) }
            }

            // Then fetch fresh data
            viewModelScope.launch {
                fetchPeople(userId, 0)
            }
        } else {
            // For sections 1 & 2, use currentPage to determine what to load
            // Use background data first if available
            when (_uiState.value.currentPage) {
                MainPage.PORTALS -> {
                    val backgroundData = when (section) {
                        1 -> backgroundPortalsTab1.value
                        2 -> backgroundPortalsTab2.value
                        else -> emptyList()
                    }
                    if (backgroundData.isNotEmpty()) {
                        _uiState.update { it.copy(portals = backgroundData) }
                    }
                }
                MainPage.PEOPLE -> {
                    val backgroundUsers = if (section == 1) backgroundUsersTab1.value else backgroundUsersTab2.value
                    if (backgroundUsers.isNotEmpty()) {
                        _uiState.update { it.copy(users = backgroundUsers) }
                    }
                }
            }

            // Then fetch fresh data
            viewModelScope.launch {
                when (_uiState.value.currentPage) {
                    MainPage.PORTALS -> fetchPortals(userId, section, _uiState.value.showOnlySafePortals)
                    MainPage.PEOPLE -> fetchPeople(userId, section)
                }
            }
        }

        // Load other sections in background after a delay
        viewModelScope.launch {
            delay(500)
            loadBackgroundData(section, (section + 1) % 3, userId)
            loadBackgroundData(section, (section + 2) % 3, userId)
        }
    }

    // ENHANCED: Use background data when toggling pages
    // NOTE: Matches iOS behavior - only works for sections 1 & 2, not section 0 (Chats)
    fun togglePage(userId: Int) {
        val section = _uiState.value.selectedSection

        // Section 0 (Chats) always shows people/chats, so don't toggle
        if (section == 0) {
            return
        }

        val newPage = when (_uiState.value.currentPage) {
            MainPage.PORTALS -> MainPage.PEOPLE
            MainPage.PEOPLE -> MainPage.PORTALS
        }
        _uiState.update { state ->
            state.copy(
                currentPage = newPage,
                searchQuery = "",
                searchPortals = emptyList(),
                searchUsers = emptyList()
            )
        }
        _searchQuery.value = ""

        // Use background data first if available
        if (newPage == MainPage.PORTALS) {
            val backgroundData = when (section) {
                1 -> backgroundPortalsTab1.value
                2 -> backgroundPortalsTab2.value
                else -> emptyList()
            }
            if (backgroundData.isNotEmpty()) {
                _uiState.update { it.copy(portals = backgroundData) }
            }
        } else {
            val backgroundUsers = if (section == 1) backgroundUsersTab1.value else backgroundUsersTab2.value
            if (backgroundUsers.isNotEmpty()) {
                _uiState.update { it.copy(users = backgroundUsers) }
            }
        }

        // Then fetch fresh data
        viewModelScope.launch {
            when (newPage) {
                MainPage.PORTALS -> fetchPortals(userId, section, _uiState.value.showOnlySafePortals)
                MainPage.PEOPLE -> fetchPeople(userId, section)
            }
        }

        // Load background data for other tabs
        viewModelScope.launch {
            delay(500)
            loadBackgroundData(section, (section + 1) % 3, userId)
            loadBackgroundData(section, (section + 2) % 3, userId)
        }
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
        _uiState.update { state -> state.copy(searchQuery = query) }

        // Clear search results if query is empty
        if (query.isBlank()) {
            _uiState.update { state ->
                state.copy(
                    searchPortals = emptyList(),
                    searchUsers = emptyList(),
                    isSearching = false
                )
            }
            return
        }

        // Perform search based on current page
        viewModelScope.launch {
            _uiState.update { it.copy(isSearching = true) }
            try {
                when (_uiState.value.currentPage) {
                    MainPage.PORTALS -> {
                        val results = portalRepository.searchPortals(query, limit = 50)
                        val patchedResults = results.map { patchPortalImage(it) }
                        _uiState.update { state ->
                            state.copy(
                                searchPortals = patchedResults,
                                isSearching = false
                            )
                        }
                    }
                    MainPage.PEOPLE -> {
                        val results = portalRepository.searchPeople(query, limit = 50)
                        val patchedResults = results.map { patchUserImage(it) }
                        _uiState.update { state ->
                            state.copy(
                                searchUsers = patchedResults,
                                isSearching = false
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                _uiState.update { state ->
                    state.copy(
                        errorMessage = "Search failed: ${e.message}",
                        isSearching = false
                    )
                }
            }
        }
    }

    fun toggleSearch() {
        val showSearch = !_uiState.value.showSearch
        _uiState.update { state ->
            state.copy(
                showSearch = showSearch,
                searchQuery = if (!showSearch) "" else state.searchQuery,
                searchPortals = if (!showSearch) emptyList() else state.searchPortals,
                searchUsers = if (!showSearch) emptyList() else state.searchUsers
            )
        }
        if (!showSearch) {
            _searchQuery.value = ""
        }
    }

    fun toggleSafePortals(userId: Int) {
        val newValue = !_uiState.value.showOnlySafePortals
        _uiState.update { state -> state.copy(showOnlySafePortals = newValue) }
        if (_uiState.value.currentPage == MainPage.PORTALS) {
            viewModelScope.launch {
                fetchPortals(userId, _uiState.value.selectedSection, newValue)
            }
        }
    }

    private suspend fun fetchPortals(userId: Int, section: Int, safeOnly: Boolean = false) {
        _uiState.update { state -> state.copy(isLoading = true, errorMessage = null) }
        try {
            val tab = when (section) {
                0 -> "open"
                1 -> "ntwk"
                2 -> "all"
                else -> "open"
            }
            val portals = portalRepository.getFilteredPortals(userId, tab, safeOnly)
            val patchedPortals = portals.map { patchPortalImage(it) }
            _uiState.update { state ->
                state.copy(
                    isLoading = false,
                    portals = patchedPortals,
                    errorMessage = null
                )
            }
            
            // Update background cache
            when (section) {
                0 -> backgroundPortalsTab0.value = patchedPortals
                1 -> backgroundPortalsTab1.value = patchedPortals
                2 -> backgroundPortalsTab2.value = patchedPortals
            }
        } catch (e: Exception) {
            _uiState.update { state ->
                state.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to load portals"
                )
            }
        }
    }

    // Public function to refresh active chats (called when returning from chat screen)
    fun refreshActiveChats(userId: Int) {
        viewModelScope.launch {
            fetchPeople(userId, 0, force = true)
        }
    }

    // ENHANCED: Add force parameter and update unread message tracking
    private suspend fun fetchPeople(userId: Int, section: Int, force: Boolean = false) {
        if (_uiState.value.isLoading && !force) return
        
        _uiState.update { state -> state.copy(isLoading = true, errorMessage = null) }
        try {
            if (section == 0) {
                // Fetch active chats
                val chats = portalRepository.getActiveChats(userId)
                val patchedChats = chats.map { patchActiveChatImage(it) }
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        activeChats = patchedChats,
                        users = emptyList(),
                        errorMessage = null
                    )
                }

                // Update cache
                backgroundUsersTab0.value = patchedChats

                // Check for unread messages - only count messages from OTHER users
                // Matches iOS logic: only show green if last_message.read == "0" AND sender != currentUser
                val hasUnreadDM = patchedChats.any {
                    it.type == "direct" &&
                    it.last_message?.read == "0" &&
                    it.last_message?.sender_id != userId
                }
                val hasUnreadGroup = patchedChats.any {
                    it.type == "group" &&
                    it.last_message?.read == "0" &&
                    it.last_message?.sender_id != userId
                }
                _hasUnreadDirectMessages.value = hasUnreadDM
                _hasUnreadGroupMessages.value = hasUnreadGroup
                recalculateAttentionState()
            } else {
                // Fetch users
                val tab = if (section == 1) "ntwk" else "all"
                val users = portalRepository.getFilteredPeople(userId, tab)
                val patchedUsers = users.map { patchUserImage(it) }
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        users = patchedUsers,
                        activeChats = emptyList(),
                        errorMessage = null
                    )
                }
                
                // Update cache
                if (section == 1) {
                    backgroundUsersTab1.value = patchedUsers
                } else {
                    backgroundUsersTab2.value = patchedUsers
                }
            }
        } catch (e: Exception) {
            _uiState.update { state ->
                state.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to load people"
                )
            }
        }
    }

    private suspend fun fetchCurrentUser() {
        try {
            authRepository.getCurrentUser()
                .firstOrNull()
                ?.getOrNull()
                ?.let { user ->
                    // Patch current user's profile picture with S3 URL
                    val patchedUser = patchUserImage(user)
                    _uiState.update { state -> state.copy(currentUser = patchedUser) }
                }
        } catch (e: Exception) {
            // Ignore error, user will remain null
        }
    }

    private fun performSearch(query: String) {
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            _uiState.update { state -> state.copy(isSearching = true) }
            try {
                when (_uiState.value.currentPage) {
                    MainPage.PORTALS -> {
                        val portals = if (_uiState.value.selectedSection == 2) {
                            portalRepository.searchPortals(query)
                        } else {
                            _uiState.value.portals.filter {
                                it.name.contains(query, ignoreCase = true)
                            }
                        }
                        _uiState.update { state ->
                            state.copy(
                                isSearching = false,
                                searchPortals = portals,
                                searchUsers = emptyList()
                            )
                        }
                    }
                    MainPage.PEOPLE -> {
                        val users: List<User> = if (_uiState.value.selectedSection == 2) {
                            // Ensure the result is cast to List<User>
                            @Suppress("UNCHECKED_CAST")
                            portalRepository.searchPeople(query) as? List<User> ?: emptyList()
                        } else {
                            _uiState.value.users.filter {
                                it.displayName.contains(query, ignoreCase = true)
                            }
                        }
                        _uiState.update { state ->
                            state.copy(
                                isSearching = false,
                                searchUsers = users,
                                searchPortals = emptyList()
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                _uiState.update { state ->
                    state.copy(
                        isSearching = false,
                        errorMessage = e.message ?: "Search failed"
                    )
                }
            }
        }
    }
}