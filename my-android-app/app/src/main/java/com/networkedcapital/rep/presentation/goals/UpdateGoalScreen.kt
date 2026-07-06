package com.networkedcapital.rep.presentation.goals

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UpdateGoalScreen(
    goalId: Int,
    quota: Double,
    metricName: String,
    onSuccess: () -> Unit,
    onCancel: () -> Unit,
    viewModel: UpdateGoalViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    var addedValue by remember { mutableStateOf("") }
    var note by remember { mutableStateOf("") }
    var selectedImages by remember { mutableStateOf<List<Uri>>(emptyList()) }

    val imagePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        val remaining = 5 - selectedImages.size
        selectedImages = selectedImages + uris.take(remaining)
    }

    LaunchedEffect(uiState.success) {
        if (uiState.success) onSuccess()
    }

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
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text("Metric: $metricName", style = MaterialTheme.typography.bodyMedium)

            OutlinedTextField(
                value = addedValue,
                onValueChange = { addedValue = it },
                label = { Text("Amount to add") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            OutlinedTextField(
                value = note,
                onValueChange = { note = it },
                label = { Text("Note (optional)") },
                modifier = Modifier.fillMaxWidth(),
                maxLines = 3
            )

            // Attachments section
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Attachments", fontWeight = FontWeight.Medium, fontSize = 14.sp, color = Color.Gray)

                if (selectedImages.isNotEmpty()) {
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        itemsIndexed(selectedImages) { index, uri ->
                            Box(modifier = Modifier.size(80.dp)) {
                                AsyncImage(
                                    model = uri,
                                    contentDescription = null,
                                    contentScale = ContentScale.Crop,
                                    modifier = Modifier
                                        .size(80.dp)
                                        .clip(RoundedCornerShape(8.dp))
                                        .border(1.dp, Color(0xFFE0E0E0), RoundedCornerShape(8.dp))
                                )
                                Box(
                                    modifier = Modifier
                                        .align(Alignment.TopEnd)
                                        .size(20.dp)
                                        .background(Color.Black.copy(alpha = 0.6f), CircleShape)
                                        .clickable { selectedImages = selectedImages.toMutableList().also { it.removeAt(index) } },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(Icons.Default.Close, contentDescription = "Remove", modifier = Modifier.size(12.dp), tint = Color.White)
                                }
                            }
                        }
                    }
                }

                if (selectedImages.size < 5) {
                    OutlinedButton(
                        onClick = { imagePicker.launch("image/*") },
                        enabled = !uiState.isSubmitting,
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF8CC65D)),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF8CC65D))
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Add Photo (optional)", fontSize = 14.sp)
                    }
                }
            }

            if (uiState.error != null) {
                Text(uiState.error!!, color = MaterialTheme.colorScheme.error, fontSize = 14.sp)
            }

            val valueNum = addedValue.toDoubleOrNull()
            Button(
                onClick = {
                    if (valueNum != null && valueNum > 0) {
                        viewModel.submitUpdate(goalId, valueNum, note, selectedImages, context)
                    }
                },
                enabled = !uiState.isSubmitting && valueNum != null && valueNum > 0,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8CC65D))
            ) {
                if (uiState.isSubmitting) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp, color = Color.White)
                    Spacer(Modifier.width(8.dp))
                }
                Text("Submit Update", fontWeight = FontWeight.Bold)
            }
        }
    }
}
