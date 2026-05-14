package com.networkedcapital.rep.presentation.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.networkedcapital.rep.domain.model.User

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateGroupChatScreen(
    currentUserId: Int,
    onNavigateToChat: (Int) -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: CreateGroupChatViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Initialize when screen loads
    LaunchedEffect(currentUserId) {
        viewModel.initialize(currentUserId)
    }

    // Navigate to chat when created
    LaunchedEffect(uiState.createdChatId) {
        uiState.createdChatId?.let { chatId ->
            onNavigateToChat(chatId)
        }
    }

    // Show error dialog
    if (uiState.error != null) {
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text("Error") },
            text = { Text(uiState.error ?: "") },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Group Chat") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    TextButton(
                        onClick = { viewModel.createGroupChat(currentUserId) },
                        enabled = !uiState.isLoading && uiState.groupName.isNotBlank() && uiState.selectedMembers.isNotEmpty()
                    ) {
                        Text(
                            "Create",
                            color = if (!uiState.isLoading && uiState.groupName.isNotBlank() && uiState.selectedMembers.isNotEmpty()) {
                                Color(0xFF8CC55D)
                            } else {
                                Color.Gray
                            }
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(Color.White)
        ) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(vertical = 16.dp)
            ) {
                // Group Name Section
                item {
                    Text(
                        text = "GROUP NAME",
                        fontSize = 13.sp,
                        color = Color.Gray,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                    OutlinedTextField(
                        value = uiState.groupName,
                        onValueChange = { viewModel.updateGroupName(it) },
                        placeholder = { Text("Enter group name") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Color(0xFF8CC55D),
                            unfocusedBorderColor = Color.LightGray
                        )
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                }

                // Members Section Header
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "MEMBERS",
                            fontSize = 13.sp,
                            color = Color.Gray
                        )
                        Text(
                            text = "${uiState.selectedMembers.size} selected",
                            fontSize = 13.sp,
                            color = Color(0xFF8CC55D),
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                // Members List
                if (uiState.isLoading && uiState.availableUsers.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(color = Color(0xFF8CC55D))
                        }
                    }
                } else if (uiState.availableUsers.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No network members found.\nBuild your network first!",
                                color = Color.Gray,
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center
                            )
                        }
                    }
                } else {
                    items(uiState.availableUsers) { user ->
                        MemberSelectionItem(
                            user = user,
                            isSelected = uiState.selectedMembers.contains(user),
                            onClick = { viewModel.toggleMemberSelection(user) }
                        )
                    }
                }
            }

            // Loading overlay
            if (uiState.isLoading && uiState.availableUsers.isNotEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.3f)),
                    contentAlignment = Alignment.Center
                ) {
                    Card(
                        modifier = Modifier.padding(32.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White)
                    ) {
                        Column(
                            modifier = Modifier.padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            CircularProgressIndicator(color = Color(0xFF8CC55D))
                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Creating group chat...")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MemberSelectionItem(
    user: User,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Profile Picture
        if (!user.profile_picture_url.isNullOrEmpty()) {
            AsyncImage(
                model = user.profile_picture_url,
                contentDescription = "Profile picture",
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFE0E0E0))
            )
        } else {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFE0E0E0)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = user.displayName.take(1).uppercase(),
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Name
        Text(
            text = user.displayName,
            fontSize = 16.sp,
            fontWeight = FontWeight.Normal,
            modifier = Modifier.weight(1f),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Selection indicator
        Icon(
            imageVector = if (isSelected) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
            contentDescription = if (isSelected) "Selected" else "Not selected",
            tint = if (isSelected) Color(0xFF8CC55D) else Color.LightGray,
            modifier = Modifier.size(24.dp)
        )
    }
}
