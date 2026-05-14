package com.networkedcapital.rep.presentation.goals

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.networkedcapital.rep.domain.model.Goal

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GoalsListScreen(
    viewModel: GoalsViewModel,
    onGoalClick: (Goal) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadGoals()
    }

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Goals") })
        }
    ) { padding ->
        when {
            uiState.isLoading -> {
                Box(Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            uiState.error != null -> {
                Box(Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
                    Text(uiState.error ?: "Unknown error")
                }
            }
            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                ) {
                    items(uiState.goals) { goal ->
                        GoalListItem(goal = goal, onClick = { onGoalClick(goal) })
                    }
                }
            }
        }
    }
}
