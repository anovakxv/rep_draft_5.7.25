package com.networkedcapital.rep.presentation.goals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.domain.model.Goal
import com.networkedcapital.rep.domain.model.BarChartData
import com.networkedcapital.rep.domain.model.User
import com.networkedcapital.rep.domain.model.FeedItem
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class GoalsUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val goals: List<Goal> = emptyList(),
    val selectedGoal: Goal? = null,
    val feed: List<FeedItem> = emptyList(),
    val team: List<User> = emptyList()
)

class GoalsViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(GoalsUiState())
    val uiState: StateFlow<GoalsUiState> = _uiState

    fun loadGoals() {
        _uiState.value = _uiState.value.copy(isLoading = true)
        viewModelScope.launch {
            try {
                // TODO: Replace with real repository call
                val goals = fetchGoalsFromApi()
                _uiState.value = _uiState.value.copy(goals = goals, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(error = e.message, isLoading = false)
            }
        }
    }

    fun selectGoal(goal: Goal) {
        _uiState.value = _uiState.value.copy(selectedGoal = goal)
        loadGoalDetail(goal.id)
    }

    fun loadGoalDetail(goalId: Int) {
        _uiState.value = _uiState.value.copy(isLoading = true)
        viewModelScope.launch {
            try {
                // TODO: Replace with real repository call
                val detail = fetchGoalDetailFromApi(goalId)
                _uiState.value = _uiState.value.copy(
                    selectedGoal = detail.goal,
                    feed = detail.feed,
                    team = detail.team,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(error = e.message, isLoading = false)
            }
        }
    }

    // --- Replace with real API/data source ---
    private suspend fun fetchGoalsFromApi(): List<Goal> {
        // TODO: Implement
        return emptyList()
    }
    private suspend fun fetchGoalDetailFromApi(goalId: Int): GoalDetailResult {
        // TODO: Implement
        return GoalDetailResult(Goal(0, "", "", "", 0.0, 0.0, 0.0, 0.0, "", "", "", "", "", emptyList(), null, null), emptyList(), emptyList())
    }
}

data class GoalDetailResult(
    val goal: Goal,
    val feed: List<FeedItem>,
    val team: List<User>
)

// Remove duplicate FeedItem declaration (already defined elsewhere)
