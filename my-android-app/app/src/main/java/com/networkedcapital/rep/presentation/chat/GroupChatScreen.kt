package com.networkedcapital.rep.presentation.chat

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.networkedcapital.rep.domain.model.GroupMemberModel
import com.networkedcapital.rep.domain.model.GroupMessageModel
import kotlinx.coroutines.delay
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberUpdatedState


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupChatScreen(
    viewModel: GroupChatViewModel = hiltViewModel(),
    chatId: Int,
    currentUserId: Int,
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val shouldScrollToBottom by viewModel.shouldScrollToBottom.collectAsState()
    val isConnected by viewModel.isConnected.collectAsState()
    
    val editSheetState = rememberModalBottomSheetState()
    val context = LocalContext.current
    
    // Initialize and activate chat
    LaunchedEffect(chatId, currentUserId) {
        viewModel.initialize(currentUserId, chatId)
        viewModel.activate()
    }
    
    // Cleanup on dispose
    DisposableEffect(Unit) {
        onDispose {
            viewModel.deactivate()
        }
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize().background(Color.White)) {
            // Custom iOS-style header
            GroupChatHeader(
                title = uiState.groupName,
                isCreator = uiState.isCreator,
                onBackClick = onNavigateBack,
                onEditGroupClick = viewModel::showEditGroupSheet
            )
            
            // Connection status
            ConnectionStatusBar(isConnected = isConnected)
            
            // Group members row
            GroupMemberRow(
                members = uiState.groupMembers,
                onMemberClick = { /* Optional: Show member details */ }
            )
            
            HorizontalDivider()
            
            // Messages list with auto-scrolling
            MessagesList(
                messages = uiState.messages,
                currentUserId = currentUserId,
                viewModel = viewModel,
                shouldScrollToBottom = shouldScrollToBottom,
                modifier = Modifier.weight(1f)
            )
            
            // Growing text input
            GrowingTextInput(
                value = uiState.inputText,
                onValueChange = viewModel::onInputTextChange,
                onSend = viewModel::sendMessage
            )
        }
        
        // Error dialog
        ErrorDialog(
            error = uiState.error,
            onDismiss = viewModel::acknowledgeError
        )
        
        // Loading overlay
        LoadingOverlay(isLoading = uiState.isLoading)
    }
    
    // Group edit sheet
    if (uiState.showEditSheet) {
        EditGroupSheet(
            groupName = uiState.editGroupNameText,
            onNameChanged = viewModel::onEditGroupNameTextChange,
            onSave = viewModel::saveEditGroupName,
            onCancel = viewModel::hideEditGroupSheet,
            onAddMembers = viewModel::showAddMemberSheet,
            onRemoveMembers = viewModel::showRemoveMemberSheet,
            onDelete = viewModel::showDeleteConfirmation,
            isCreator = uiState.isCreator,
            onLeave = viewModel::leaveGroup,
            sheetState = editSheetState
        )
    }
    
    // Delete confirmation
    if (uiState.showDeleteConfirmation) {
        DeleteConfirmationDialog(
            onConfirm = viewModel::confirmDeleteChat,
            onDismiss = viewModel::hideDeleteConfirmation
        )
    }
    // Add Members Sheet
    if (uiState.showAddMemberSheet) {
        ModalBottomSheet(
            onDismissRequest = viewModel::hideAddMemberSheet,
            containerColor = Color.White
        ) {
            val currentMembers = uiState.groupMembers.map { it.id }.toSet()
            AddMembersScreen(
                chatId = chatId,
                alreadySelected = currentMembers,
                onMembersSelected = viewModel::onAddMembersSelected,
                onCancel = viewModel::hideAddMemberSheet
            )
        }
    }

    // Remove Members Sheet
    if (uiState.showRemoveMemberSheet) {
        ModalBottomSheet(
            onDismissRequest = viewModel::hideRemoveMemberSheet,
            containerColor = Color.White
        ) {
            RemoveMembersScreen(
                members = uiState.groupMembers,
                currentUserId = currentUserId,
                isCreator = uiState.isCreator,
                onRemoveMember = viewModel::showRemoveMemberConfirmation,
                onCancel = viewModel::hideRemoveMemberSheet
            )
        }
    }

    // Remove Member Confirmation
    uiState.memberToRemove?.let { member ->
        RemoveMemberConfirmationDialog(
            member = member,
            onConfirm = viewModel::confirmRemoveMember,
            onDismiss = viewModel::hideRemoveMemberConfirmation
        )
    }
}

@Composable
fun GroupChatHeader(
    title: String,
    isCreator: Boolean,
    onBackClick: () -> Unit,
    onEditGroupClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(Color.White)
            .shadow(elevation = 2.dp)
    ) {
        // Back button
        IconButton(
            onClick = onBackClick,
            modifier = Modifier
                .align(Alignment.CenterStart)
                .padding(start = 4.dp)
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = Color(0xFF8CC55D)
            )
        }
        
        // Title in center
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.align(Alignment.Center)
        )
        
        // Edit button (only for creator)
        if (isCreator) {
            IconButton(
                onClick = onEditGroupClick,
                modifier = Modifier
                    .align(Alignment.CenterEnd)
                    .padding(end = 8.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Edit, 
                    contentDescription = "Edit Group",
                    tint = Color(0xFF8CC55D)
                )
            }
        }
    }
}

@Composable
fun ConnectionStatusBar(isConnected: Boolean) {
    AnimatedVisibility(
        visible = !isConnected,
        enter = slideInVertically() + fadeIn(),
        exit = slideOutVertically() + fadeOut()
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.Red.copy(alpha = 0.8f))
                .padding(4.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                "No connection. Reconnecting...",
                color = Color.White,
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
fun GroupMemberRow(
    members: List<GroupMemberModel>,
    onMemberClick: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyRow(
        modifier = modifier
            .fillMaxWidth()
            .background(Color(0xFFF9F9F9))
            .padding(vertical = 8.dp, horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 8.dp)
    ) {
        items(members) { member ->
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .width(52.dp)
                    .clickable { onMemberClick(member.id) }
            ) {
                MemberAvatar(
                    photoUrl = member.profilePictureUrl,
                    fullName = member.fullName ?: "Unknown",
                    size = 40.dp
                )

                Spacer(modifier = Modifier.height(4.dp))

                // Display name, truncated as needed
                val memberName = member.fullName ?: "Unknown"
                val displayName = if (memberName.length > 10) {
                    memberName.take(8) + "..."
                } else {
                    memberName
                }
                
                Text(
                    text = displayName,
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.DarkGray,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.width(52.dp)
                )
            }
        }
    }
}

@Composable
fun MemberAvatar(
    photoUrl: String?,
    fullName: String?,
    size: Dp,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(Color(0xFFE0E0E0)),
        contentAlignment = Alignment.Center
    ) {
        if (!photoUrl.isNullOrEmpty()) {
            AsyncImage(
                model = photoUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        } else {
            // Display initials from full name
            val initials = fullName?.split(" ")?.mapNotNull { it.firstOrNull() }?.take(2)?.joinToString("")?.uppercase() ?: "?"
            
            Text(
                text = initials,
                style = MaterialTheme.typography.bodyMedium,
                color = Color.DarkGray,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
fun MessagesList(
    messages: List<GroupMessageModel>,
    currentUserId: Int,
    viewModel: GroupChatViewModel,
    shouldScrollToBottom: Boolean,
    modifier: Modifier = Modifier
) {
    val listState = rememberLazyListState()
    
    // Auto scroll to bottom on new messages
    LaunchedEffect(shouldScrollToBottom, messages.size) {
        if (shouldScrollToBottom && messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }
    
    // Auto scroll on init if messages present
    LaunchedEffect(Unit) {
        if (messages.isNotEmpty()) {
            listState.scrollToItem(messages.size - 1)
        }
    }
    
    LazyColumn(
        state = listState,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        items(messages) { message ->
            val isFromCurrentUser = message.senderId == currentUserId
            val formattedTime = message.timestamp?.let { viewModel.formatTimestamp(it) } ?: ""
            
            MessageBubble(
                message = message,
                isFromCurrentUser = isFromCurrentUser,
                formattedTime = formattedTime,
                viewModel = viewModel
            )
        }
    }
}

@Composable
fun MessageBubble(
    message: GroupMessageModel,
    isFromCurrentUser: Boolean,
    formattedTime: String,
    viewModel: GroupChatViewModel,
    modifier: Modifier = Modifier
) {
    // iOS Design: NO profile pictures in message bubbles, sender name only for incoming messages
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        horizontalArrangement = if (isFromCurrentUser) Arrangement.End else Arrangement.Start
    ) {
        if (isFromCurrentUser) {
            Spacer(modifier = Modifier.weight(1f))
        }

        Column(
            horizontalAlignment = if (isFromCurrentUser) Alignment.End else Alignment.Start,
            modifier = Modifier.widthIn(max = 260.dp)
        ) {
            // Sender name ONLY for incoming messages (iOS behavior)
            if (!isFromCurrentUser) {
                Text(
                    text = message.senderName ?: "Unknown",
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                    color = Color.Gray,
                    modifier = Modifier.padding(bottom = 2.dp, start = 4.dp)
                )
            }

            // Message bubble
            Surface(
                color = if (isFromCurrentUser) Color.Black else Color(0xFFF0F0F0),
                shape = RoundedCornerShape(8.dp)
            ) {
                Text(
                    text = message.text ?: "",
                    color = if (isFromCurrentUser) Color(0xFF8CC55D) else Color.Black,
                    modifier = Modifier.padding(vertical = 10.dp, horizontal = 10.dp),
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            // Timestamp below bubble
            Text(
                text = formattedTime,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                color = Color.Gray,
                modifier = Modifier.padding(top = 2.dp, start = 4.dp, end = 4.dp)
            )
        }

        if (!isFromCurrentUser) {
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
fun GrowingTextInput(
    value: String,
    onValueChange: (String) -> Unit,
    onSend: () -> Unit,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    val lineHeight = MaterialTheme.typography.bodyLarge.lineHeight.value * density.density
    
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(Color(0xFFF9F9F9))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .background(Color.White, RoundedCornerShape(18.dp))
                .border(1.dp, Color(0xFFE0E0E0), RoundedCornerShape(18.dp))
        ) {
            BasicTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .heightIn(min = 36.dp, max = lineHeight.dp * 4), // Max 4 lines
                textStyle = MaterialTheme.typography.bodyLarge.copy(
                    color = Color.Black
                ),
                keyboardOptions = KeyboardOptions(
                    imeAction = ImeAction.Send
                ),
                keyboardActions = KeyboardActions(
                    onSend = {
                        if (value.trim().isNotEmpty()) {
                            onSend()
                        }
                    }
                ),
                decorationBox = { innerTextField ->
                    Box(
                        contentAlignment = Alignment.CenterStart,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        if (value.isEmpty()) {
                            Text(
                                "Message...",
                                style = MaterialTheme.typography.bodyLarge,
                                color = Color.Gray
                            )
                        }
                        innerTextField()
                    }
                }
            )
        }
        
        Spacer(modifier = Modifier.width(8.dp))
        
        // iOS-style send button
        Box(
            modifier = Modifier
                .size(36.dp)
                .background(
                    if (value.trim().isEmpty()) Color(0xFFE0E0E0) else Color(0xFF8CC55D),
                    CircleShape
                )
                .clickable(enabled = value.trim().isNotEmpty()) {
                    if (value.trim().isNotEmpty()) {
                        onSend()
                    }
                },
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Send,
                contentDescription = "Send",
                tint = if (value.trim().isEmpty()) Color.Gray else Color.White,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditGroupSheet(
    groupName: String,
    onNameChanged: (String) -> Unit,
    onSave: () -> Unit,
    onCancel: () -> Unit,
    onAddMembers: () -> Unit,
    onRemoveMembers: () -> Unit,
    onDelete: () -> Unit,
    isCreator: Boolean,
    onLeave: () -> Unit,
    sheetState: SheetState,
    modifier: Modifier = Modifier
) {
    ModalBottomSheet(
        onDismissRequest = onCancel,
        sheetState = sheetState,
        containerColor = Color.White
    ) {
        Column(
            modifier = modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Edit Group",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            OutlinedTextField(
                value = groupName,
                onValueChange = onNameChanged,
                label = { Text("Group Name") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            
            Button(
                onClick = onSave,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF8CC55D)
                ),
                enabled = groupName.trim().isNotEmpty()
            ) {
                Text("Save Changes")
            }
            
            Button(
                onClick = onAddMembers,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF8CC55D)
                )
            ) {
                Text("Add Members")
            }
            
            if (isCreator) {
                Button(
                    onClick = onRemoveMembers,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color(0xFF8CC55D)
                    ),
                    border = BorderStroke(1.dp, Color(0xFF8CC55D))
                ) {
                    Text("Remove Members")
                }
                
                Button(
                    onClick = onDelete,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color.Red
                    ),
                    border = BorderStroke(1.dp, Color.Red)
                ) {
                    Text("Delete Group")
                }
            } else {
                Button(
                    onClick = onLeave,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color.Red
                    ),
                    border = BorderStroke(1.dp, Color.Red)
                ) {
                    Text("Leave Group")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
fun DeleteConfirmationDialog(
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Delete Group?") },
        text = { Text("This will permanently delete the group for all members and cannot be undone.") },
        confirmButton = {
            Button(
                onClick = onConfirm,
                colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
            ) {
                Text("Delete")
            }
        },
        dismissButton = {
            OutlinedButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun ErrorDialog(
    error: String?,
    onDismiss: () -> Unit
) {
    if (error != null) {
        AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text("Error") },
            text = { Text(error) },
            confirmButton = {
                Button(
                    onClick = onDismiss,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8CC55D))
                ) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
fun LoadingOverlay(isLoading: Boolean) {
    if (isLoading) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.5f)),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(
                color = Color(0xFF8CC55D)
            )
        }
    }
}