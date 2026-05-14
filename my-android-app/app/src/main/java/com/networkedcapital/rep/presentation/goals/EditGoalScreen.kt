package com.networkedcapital.rep.presentation.goals

import android.content.Context
import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.networkedcapital.rep.domain.model.Goal
import kotlinx.coroutines.launch
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditGoalScreen(
    existingGoal: Goal? = null,
    portalId: Int? = null,
    portalName: String? = null,
    userId: Int = 0,
    onSave: (Goal) -> Unit,
    onCancel: () -> Unit,
    viewModel: EditGoalViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()

    var title by remember { mutableStateOf(existingGoal?.title ?: "") }
    var subtitle by remember { mutableStateOf(existingGoal?.subtitle ?: "") }
    var description by remember { mutableStateOf(existingGoal?.description ?: "") }
    var quota by remember { mutableStateOf(existingGoal?.quota?.toInt()?.toString() ?: "") }
    var goalType by remember { mutableStateOf(existingGoal?.typeName ?: "Recruiting") }
    var metric by remember { mutableStateOf(existingGoal?.metricName ?: "") }

    val goalTypes = listOf("Recruiting", "Sales", "Fund", "Marketing", "Hours", "Other")
    val scope = rememberCoroutineScope()

    // Set the selected reporting increment to match existing goal
    LaunchedEffect(existingGoal, uiState.reportingIncrements) {
        if (existingGoal != null && uiState.reportingIncrements.isNotEmpty()) {
            val matchingIncrement = uiState.reportingIncrements.firstOrNull {
                it.title.trim().equals(existingGoal.reportingName.trim(), ignoreCase = true)
            }
            matchingIncrement?.let {
                viewModel.setSelectedReportingIncrement(it.id)
            }
        }
    }

    // Get user ID from SharedPreferences if not provided
    val actualUserId = remember {
        if (userId > 0) userId else {
            context.getSharedPreferences("auth_prefs", Context.MODE_PRIVATE)
                .getInt("user_id", 0)
        }
    }

    Log.d("EditGoalScreen", "userId=$actualUserId, portalId=$portalId, existingGoal=${existingGoal?.id}")

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (existingGoal != null) "Edit Goal" else "Add Goal") },
                navigationIcon = {
                    IconButton(onClick = onCancel) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Cancel")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Title") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = subtitle,
                onValueChange = { subtitle = it },
                label = { Text("Subtitle") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description") },
                modifier = Modifier.fillMaxWidth()
            )
            ExposedDropdownMenuBox(
                expanded = false,
                onExpandedChange = {}
            ) {
                OutlinedTextField(
                    value = goalType,
                    onValueChange = { goalType = it },
                    label = { Text("Goal Type") },
                    modifier = Modifier.fillMaxWidth(),
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = false) }
                )
                DropdownMenu(
                    expanded = false,
                    onDismissRequest = {}
                ) {
                    goalTypes.forEach { type ->
                        DropdownMenuItem(
                            text = { Text(type) },
                            onClick = { goalType = type }
                        )
                    }
                }
            }
            if (goalType == "Other") {
                OutlinedTextField(
                    value = metric,
                    onValueChange = { metric = it },
                    label = { Text("Metric") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            OutlinedTextField(
                value = quota,
                onValueChange = { quota = it },
                label = { Text("Quota") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )

            // Reporting Increment Picker
            var incrementPickerExpanded by remember { mutableStateOf(false) }
            val selectedIncrement = uiState.reportingIncrements.firstOrNull {
                it.id == uiState.selectedReportingIncrementId
            }

            ExposedDropdownMenuBox(
                expanded = incrementPickerExpanded,
                onExpandedChange = { incrementPickerExpanded = !incrementPickerExpanded }
            ) {
                OutlinedTextField(
                    value = selectedIncrement?.title ?: "Loading...",
                    onValueChange = {},
                    label = { Text("Reporting Increment") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = incrementPickerExpanded) }
                )
                ExposedDropdownMenu(
                    expanded = incrementPickerExpanded,
                    onDismissRequest = { incrementPickerExpanded = false }
                ) {
                    uiState.reportingIncrements.forEach { increment ->
                        DropdownMenuItem(
                            text = { Text(increment.title) },
                            onClick = {
                                viewModel.setSelectedReportingIncrement(increment.id)
                                incrementPickerExpanded = false
                            }
                        )
                    }
                }
            }

            // Associated Portal section
            Text(
                text = "Associated Portal",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 8.dp)
            )
            Text(
                text = portalName ?: existingGoal?.portalName ?: "N/A",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            if (uiState.errorMessage != null) {
                Text(uiState.errorMessage!!, color = MaterialTheme.colorScheme.error)
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                Button(
                    onClick = {
                        val quotaInt = quota.toIntOrNull() ?: 0
                        if (existingGoal != null) {
                            // Edit existing goal
                            viewModel.editGoal(
                                goalId = existingGoal.id,
                                title = title,
                                subtitle = subtitle,
                                description = description,
                                goalType = goalType,
                                quota = quotaInt,
                                userId = actualUserId,
                                portalId = portalId,
                                metric = if (goalType == "Other") metric else null,
                                onSuccess = {
                                    onSave(
                                        Goal(
                                            id = existingGoal.id,
                                            title = title,
                                            subtitle = subtitle,
                                            description = description,
                                            quota = quotaInt.toDouble(),
                                            progress = existingGoal.progress,
                                            progressPercent = existingGoal.progressPercent,
                                            typeName = goalType,
                                            metricName = metric,
                                            reportingName = selectedIncrement?.title ?: "",
                                            chartData = existingGoal.chartData,
                                            portalName = existingGoal.portalName,
                                            portalId = existingGoal.portalId,
                                            creatorId = existingGoal.creatorId
                                        )
                                    )
                                }
                            )
                        } else {
                            // Create new goal
                            viewModel.createGoal(
                                title = title,
                                subtitle = subtitle,
                                description = description,
                                goalType = goalType,
                                quota = quotaInt,
                                userId = actualUserId,
                                portalId = portalId,
                                metric = if (goalType == "Other") metric else null,
                                onSuccess = {
                                    onSave(
                                        Goal(
                                            id = 0,
                                            title = title,
                                            subtitle = subtitle,
                                            description = description,
                                            quota = quotaInt.toDouble(),
                                            progress = 0.0,
                                            progressPercent = 0.0,
                                            typeName = goalType,
                                            metricName = metric,
                                            reportingName = selectedIncrement?.title ?: "",
                                            chartData = emptyList(),
                                            portalId = portalId
                                        )
                                    )
                                }
                            )
                        }
                    },
                    enabled = !uiState.isSaving && title.isNotBlank() && quota.isNotBlank() && uiState.selectedReportingIncrementId != null
                ) {
                    if (uiState.isSaving) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(if (existingGoal != null) "Save Changes" else "Add Goal")
                    }
                }
            }
        }
    }
}
     
