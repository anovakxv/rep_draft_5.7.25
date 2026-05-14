// New file: c:\Users\Stephanie\Desktop\my-android-app\android-app\android-app-V.1\app\src\main\java\com\networkedcapital\rep\presentation\chat\AddMembersScreen.kt

package com.networkedcapital.rep.presentation.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.networkedcapital.rep.domain.model.User

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddMembersScreen(
    chatId: Int,
    alreadySelected: Set<Int> = emptySet(),
    onMembersSelected: (List<User>) -> Unit,
    onCancel: () -> Unit,
    viewModel: AddMembersViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    LaunchedEffect(chatId) {
        viewModel.initialize(chatId, alreadySelected)
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(max = 600.dp)  // Constrain height for bottom sheet
    ) {
        // Custom header instead of TopAppBar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextButton(onClick = onCancel) {
                Text("Cancel", color = Color(0xFF8CC55D))
            }
            Text(
                "Your NTWK",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            TextButton(
                onClick = {
                    val selectedUsers = uiState.users.filter {
                        uiState.selectedUserIds.contains(it.id)
                    }
                    onMembersSelected(selectedUsers)
                },
                enabled = uiState.selectedUserIds.isNotEmpty()
            ) {
                Text(
                    "Done",
                    color = if (uiState.selectedUserIds.isNotEmpty())
                        Color(0xFF8CC55D) else Color.Gray
                )
            }
        }

        HorizontalDivider()

        Box(modifier = Modifier.weight(1f)) {
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = Color(0xFF8CC55D))
                }
            } else if (uiState.users.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "No users available to add",
                        style = MaterialTheme.typography.bodyLarge,
                        color = Color.Gray
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxWidth(),
                    contentPadding = PaddingValues(vertical = 8.dp)
                ) {
                    items(uiState.users) { user ->
                        val isSelected = uiState.selectedUserIds.contains(user.id)
                        val isAlreadyInGroup = alreadySelected.contains(user.id)
                        
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable(enabled = !isAlreadyInGroup) {
                                    viewModel.toggleUserSelection(user.id)
                                }
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            MemberAvatar(
                                photoUrl = user.profilePictureUrl,
                                fullName = user.displayName,
                                size = 40.dp
                            )
                            
                            Spacer(modifier = Modifier.width(12.dp))
                            
                            Text(
                                text = user.displayName,
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = if (isSelected || isAlreadyInGroup)
                                    FontWeight.SemiBold else FontWeight.Normal,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f)
                            )
                            
                            if (isSelected || isAlreadyInGroup) {
                                Icon(
                                    imageVector = Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = Color(0xFF8CC55D),
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                        
                        HorizontalDivider(
                            modifier = Modifier.padding(start = 68.dp),
                            color = Color.LightGray.copy(alpha = 0.5f)
                        )
                    }
                }
            }
            
            // Error dialog
            if (uiState.error != null) {
                ErrorDialog(
                    error = uiState.error,
                    onDismiss = { viewModel.clearError() }
                )
            }
        }
    }
}