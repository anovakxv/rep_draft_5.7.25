package com.networkedcapital.rep.presentation.goals

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UpdateGoalScreen(
    goalId: Int,
    quota: Double,
    metricName: String,
    onSubmit: (addedValue: Double, note: String) -> Unit,
    onCancel: () -> Unit
) {
    var addedValue by remember { mutableStateOf("") }
    var note by remember { mutableStateOf("") }
    var isSubmitting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Update Goal") },
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
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text("Metric: $metricName", style = MaterialTheme.typography.bodyMedium)
            OutlinedTextField(
                value = addedValue,
                onValueChange = { addedValue = it },
                label = { Text("Amount to add") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = note,
                onValueChange = { note = it },
                label = { Text("Note (optional)") },
                modifier = Modifier.fillMaxWidth()
            )
            if (errorMessage != null) {
                Text(errorMessage!!, color = MaterialTheme.colorScheme.error)
            }
            Button(
                onClick = {
                    val value = addedValue.toDoubleOrNull()
                    if (value == null || value <= 0) {
                        errorMessage = "Please enter a valid number."
                        return@Button
                    }
                    isSubmitting = true
                    errorMessage = null
                    scope.launch {
                        // Call the submit callback (should handle API and UI state)
                        onSubmit(value, note)
                        isSubmitting = false
                    }
                },
                enabled = !isSubmitting && addedValue.isNotBlank(),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Submit Update")
            }
        }
    }
}
