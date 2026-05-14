package com.networkedcapital.rep.presentation.portal

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.PortalRepository
import com.networkedcapital.rep.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PortalDetailViewModel @Inject constructor(
    private val portalRepository: PortalRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(PortalDetailUiState())
    val uiState: StateFlow<PortalDetailUiState> = _uiState.asStateFlow()

    // S3 base URL for image patching (same as backend and iOS)
    private val s3BaseUrl = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

    /**
     * Patch image URL - convert filename to full S3 URL if needed
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
     * Patch all image URLs in PortalDetail
     */
    private fun patchPortalDetailImages(portalDetail: PortalDetail): PortalDetail {
        return portalDetail.copy(
            mainImageUrl = patchImageUrl(portalDetail.mainImageUrl),
            aLeads = portalDetail.aLeads?.map { patchUserImages(it) },
            aUsers = portalDetail.aUsers?.map { patchUserImages(it) }
        )
    }

    /**
     * Patch user profile picture URLs
     */
    private fun patchUserImages(user: User): User {
        val patchedUrl = patchImageUrl(user.profile_picture_url ?: user.imageName)
        return user.copy(
            profile_picture_url = patchedUrl,
            imageUrl = patchedUrl,
            avatarUrl = patchedUrl
        )
    }

    fun loadPortalDetail(portalId: Int, userId: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // Load portal detail
            portalRepository.getPortalDetail(portalId, userId).firstOrNull()?.fold(
                onSuccess = { portalDetail ->
                    val patchedPortalDetail = patchPortalDetailImages(portalDetail)
                    android.util.Log.d("PortalDetailViewModel", "Loaded portal detail: $patchedPortalDetail")
                    _uiState.update {
                        it.copy(
                            portalDetail = patchedPortalDetail,
                            isLoading = false
                        )
                    }
                },
                onFailure = { error ->
                    android.util.Log.e("PortalDetailViewModel", "Error loading portal detail: ${error.message}", error)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message
                        )
                    }
                }
            )

            // Load portal goals
            portalRepository.getPortalGoals(portalId).firstOrNull()?.fold(
                onSuccess = { goals ->
                    android.util.Log.d("PortalDetailViewModel", "Loaded portal goals: $goals")
                    _uiState.update { it.copy(portalGoals = goals) }
                },
                onFailure = { error ->
                    android.util.Log.e("PortalDetailViewModel", "Error loading portal goals: ${error.message}", error)
                }
            )

            // Load reporting increments if needed
            if (_uiState.value.reportingIncrements.isEmpty()) {
                portalRepository.getReportingIncrements().firstOrNull()?.fold(
                    onSuccess = { increments ->
                        android.util.Log.d("PortalDetailViewModel", "Loaded reporting increments: $increments")
                        _uiState.update { it.copy(reportingIncrements = increments) }
                    },
                    onFailure = { error ->
                        android.util.Log.e("PortalDetailViewModel", "Error loading reporting increments: ${error.message}", error)
                    }
                )
            }
        }
    }

    fun selectSection(sectionIndex: Int) {
        _uiState.update { it.copy(selectedSection = sectionIndex) }
    }

    fun flagPortal(portalId: Int, reason: String = "") {
        viewModelScope.launch {
            portalRepository.flagPortal(portalId, reason).firstOrNull()?.fold(
                onSuccess = {
                    _uiState.update {
                        it.copy(
                            flagResult = "Portal flagged. Thank you for your report."
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            flagResult = error.message ?: "Failed to flag portal."
                        )
                    }
                }
            )
        }
    }

    fun clearFlagResult() {
        _uiState.update { it.copy(flagResult = null) }
    }
}

data class PortalDetailUiState(
    val isLoading: Boolean = false,
    val portalDetail: PortalDetail? = null,
    val portalGoals: List<Goal> = emptyList(),
    val reportingIncrements: List<ReportingIncrement> = emptyList(),
    val selectedSection: Int = 0, // 0 = Goal Teams, 1 = Story
    val error: String? = null,
    val flagResult: String? = null
)
