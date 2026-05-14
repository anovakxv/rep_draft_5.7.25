package com.networkedcapital.rep.presentation.goals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.GoalRepository
import com.networkedcapital.rep.domain.model.ReportingIncrement
import com.networkedcapital.rep.domain.model.Goal
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EditGoalUiState(
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null,
    val reportingIncrements: List<ReportingIncrement> = emptyList(),
    val selectedReportingIncrementId: Int? = null
)

@HiltViewModel
class EditGoalViewModel @Inject constructor(
    private val goalRepository: GoalRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditGoalUiState())
    val uiState: StateFlow<EditGoalUiState> = _uiState.asStateFlow()

    init {
        loadReportingIncrements()
    }

    private fun loadReportingIncrements() {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
        viewModelScope.launch {
            goalRepository.getReportingIncrements().collect { result ->
                result.fold(
                    onSuccess = { increments ->
                        // Find "Daily" or use first as default
                        val defaultId = increments.firstOrNull {
                            it.title.trim().equals("Daily", ignoreCase = true)
                        }?.id ?: increments.firstOrNull()?.id

                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            reportingIncrements = increments,
                            selectedReportingIncrementId = defaultId
                        )
                    },
                    onFailure = { throwable ->
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            errorMessage = throwable.message ?: "Failed to load reporting increments"
                        )
                    }
                )
            }
        }
    }

    fun setSelectedReportingIncrement(incrementId: Int) {
        _uiState.value = _uiState.value.copy(selectedReportingIncrementId = incrementId)
    }

    fun createGoal(
        title: String,
        subtitle: String,
        description: String,
        goalType: String,
        quota: Int,
        userId: Int,
        portalId: Int? = null,
        metric: String? = null,
        onSuccess: () -> Unit = {}
    ) {
        val reportingIncrementId = _uiState.value.selectedReportingIncrementId
        if (reportingIncrementId == null) {
            _uiState.value = _uiState.value.copy(errorMessage = "Please select a reporting increment")
            return
        }

        _uiState.value = _uiState.value.copy(isSaving = true, errorMessage = null, successMessage = null)
        viewModelScope.launch {
            goalRepository.createGoal(
                title = title,
                subtitle = subtitle,
                description = description,
                goalType = goalType,
                quota = quota,
                reportingIncrementsId = reportingIncrementId,
                userId = userId,
                portalId = portalId,
                metric = metric
            ).collect { result ->
                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isSaving = false,
                            successMessage = message
                        )
                        onSuccess()
                    },
                    onFailure = { throwable ->
                        _uiState.value = _uiState.value.copy(
                            isSaving = false,
                            errorMessage = throwable.message ?: "Failed to create goal"
                        )
                    }
                )
            }
        }
    }

    fun editGoal(
        goalId: Int,
        title: String,
        subtitle: String,
        description: String,
        goalType: String,
        quota: Int,
        userId: Int,
        portalId: Int? = null,
        metric: String? = null,
        onSuccess: () -> Unit = {}
    ) {
        val reportingIncrementId = _uiState.value.selectedReportingIncrementId
        if (reportingIncrementId == null) {
            _uiState.value = _uiState.value.copy(errorMessage = "Please select a reporting increment")
            return
        }

        _uiState.value = _uiState.value.copy(isSaving = true, errorMessage = null, successMessage = null)
        viewModelScope.launch {
            goalRepository.editGoal(
                goalId = goalId,
                title = title,
                subtitle = subtitle,
                description = description,
                goalType = goalType,
                quota = quota,
                reportingIncrementsId = reportingIncrementId,
                userId = userId,
                portalId = portalId,
                metric = metric
            ).collect { result ->
                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isSaving = false,
                            successMessage = message
                        )
                        onSuccess()
                    },
                    onFailure = { throwable ->
                        _uiState.value = _uiState.value.copy(
                            isSaving = false,
                            errorMessage = throwable.message ?: "Failed to update goal"
                        )
                    }
                )
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun clearSuccess() {
        _uiState.value = _uiState.value.copy(successMessage = null)
    }
}
