package com.networkedcapital.rep.presentation.chat

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.networkedcapital.rep.domain.model.MessageModel

@Composable
fun IndividualChatScreen(
    viewModel: IndividualChatViewModel = hiltViewModel(),
    chatId: Int,
    userName: String,
    userPhotoUrl: String?,
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val shouldScrollToBottom by viewModel.shouldScrollToBottom.collectAsState()
    val isConnected by viewModel.isConnected.collectAsState()
    
    LaunchedEffect(chatId) {
        viewModel.initialize(
            otherUserId = chatId,
            otherUserName = userName,
            otherUserPhotoUrl = userPhotoUrl
        )
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        IndividualChatContent(
            userName = userName,
            userPhotoUrl = userPhotoUrl,
            messages = uiState.messages,
            currentUserId = viewModel.currentUserId,
            inputText = uiState.inputText,
            isLoading = uiState.isLoading,
            isInitialized = uiState.isInitialized,
            isLoadingOlder = uiState.isLoadingOlder,
            isEmpty = uiState.isEmpty,
            shouldScrollToBottom = shouldScrollToBottom,
            onInputTextChange = viewModel::onInputTextChange,
            onSend = viewModel::sendMessage,
            onBack = onNavigateBack,
            onLoadOlder = viewModel::loadOlderIfNeeded,
            formatTimestamp = viewModel::formatTimestamp
        )
        
        // Connection status indicator
        AnimatedVisibility(
            visible = !isConnected,
            enter = slideInVertically() + fadeIn(),
            exit = slideOutVertically() + fadeOut(),
            modifier = Modifier.align(Alignment.TopCenter)
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
        
        // Error dialog
        uiState.error?.let { error ->
            AlertDialog(
                onDismissRequest = viewModel::acknowledgeError,
                title = { Text("Error") },
                text = { Text(error) },
                confirmButton = {
                    Button(
                        onClick = viewModel::acknowledgeError,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF8CC55D)
                        )
                    ) {
                        Text("OK")
                    }
                }
            )
        }
    }
}

@Composable
fun IndividualChatContent(
    userName: String,
    userPhotoUrl: String?,
    messages: List<MessageModel>,
    currentUserId: Int,
    inputText: String,
    isLoading: Boolean,
    isInitialized: Boolean,
    isLoadingOlder: Boolean,
    isEmpty: Boolean,
    shouldScrollToBottom: Boolean,
    onInputTextChange: (String) -> Unit,
    onSend: () -> Unit,
    onBack: () -> Unit,
    onLoadOlder: (Int?) -> Unit,
    formatTimestamp: (String) -> String
) {
    Column(modifier = Modifier.fillMaxSize().background(Color.White)) {
        // iOS-style header
        NavigationHeaderView(name = userName, onBack = onBack)
        
        if (!isInitialized) {
            // Show loading state
            LoadingConversation()
        } else {
            // Messages or empty state
            Box(modifier = Modifier.weight(1f)) {
                if (isEmpty) {
                    EmptyConversationView(otherUserName = userName)
                } else {
                    val listState = rememberLazyListState()

                    // Auto scroll to bottom on new messages (when shouldScrollToBottom flag is set)
                    LaunchedEffect(shouldScrollToBottom) {
                        if (shouldScrollToBottom && messages.isNotEmpty()) {
                            listState.animateScrollToItem(messages.size - 1)
                        }
                    }

                    // Initial scroll to bottom when messages first load (matching iOS behavior)
                    LaunchedEffect(isInitialized) {
                        if (isInitialized && messages.isNotEmpty()) {
                            // Add slight delay like iOS (0.15s) to ensure layout is ready
                            kotlinx.coroutines.delay(150)
                            listState.scrollToItem(messages.size - 1)
                        }
                    }

                    // Scroll to bottom when message count changes (matching iOS onChange behavior)
                    LaunchedEffect(messages.size) {
                        if (messages.isNotEmpty() && !isLoadingOlder) {
                            // Only auto-scroll on count changes if we're not loading older messages
                            listState.animateScrollToItem(messages.size - 1)
                        }
                    }
                    
                    LazyColumn(
                        state = listState,
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(horizontal = 12.dp),
                        contentPadding = PaddingValues(vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Pagination trigger
                        if (messages.isNotEmpty()) {
                            item {
                                if (isLoadingOlder) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 8.dp),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        CircularProgressIndicator(
                                            modifier = Modifier.size(24.dp),
                                            color = Color(0xFF8CC55D),
                                            strokeWidth = 2.dp
                                        )
                                    }
                                } else {
                                    Spacer(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(1.dp)
                                    )

                                    // Load older messages when reaching top
                                    LaunchedEffect(messages.firstOrNull()?.id) {
                                        messages.firstOrNull()?.let {
                                            onLoadOlder(it.id)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Messages
                        items(messages, key = { it.id }) { message ->
                            val isCurrentUser = message.senderId == currentUserId
                            MessageBubble(
                                message = message,
                                isCurrentUser = isCurrentUser,
                                profilePicURL = if (!isCurrentUser) userPhotoUrl else null,
                                formattedTime = formatTimestamp(message.timestamp)
                            )
                        }
                    }
                }
            }
            
            // Message input area with divider
            Column {
                HorizontalDivider(color = Color(0xFFE5E5E5))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White)
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.Bottom
                ) {
                    GrowingTextEditor(
                        text = inputText,
                        onValueChange = onInputTextChange,
                        modifier = Modifier.weight(1f)
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Button(
                        onClick = onSend,
                        enabled = inputText.trim().isNotEmpty(),
                        modifier = Modifier.padding(vertical = 4.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF8CC55D),
                            disabledContainerColor = Color(0xFFDDDDDD)
                        ),
                        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 10.dp)
                    ) {
                        Text(
                            "Send",
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun NavigationHeaderView(
    name: String,
    onBack: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(Color.White)
            .shadow(elevation = 2.dp)
    ) {
        IconButton(
            onClick = onBack,
            modifier = Modifier.align(Alignment.CenterStart)
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = Color(0xFF8CC55D) // RepGreen color
            )
        }
        
        Text(
            text = name,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.align(Alignment.Center)
        )
    }
}

@Composable
fun MessageBubble(
    message: MessageModel,
    isCurrentUser: Boolean,
    profilePicURL: String?,
    formattedTime: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = if (isCurrentUser) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.Bottom
    ) {
        if (!isCurrentUser) {
            // Profile picture for other user
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(Color.Gray.copy(alpha = 0.3f)),
                contentAlignment = Alignment.Center
            ) {
                if (profilePicURL != null) {
                    AsyncImage(
                        model = profilePicURL,
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
            Spacer(modifier = Modifier.width(8.dp))
        }
        
        Column(
            horizontalAlignment = if (isCurrentUser) Alignment.End else Alignment.Start
        ) {
            Surface(
                color = if (isCurrentUser) Color.Black else Color(0xFFF2F2F2),
                shape = RoundedCornerShape(18.dp)
            ) {
                Text(
                    text = message.text ?: "",
                    color = if (isCurrentUser) Color(0xFF8CC55D) else Color.Black,
                    modifier = Modifier.padding(vertical = 8.dp, horizontal = 12.dp)
                )
            }
            
            // Time below message
            Text(
                text = formattedTime,
                style = MaterialTheme.typography.bodySmall.copy(
                    fontSize = MaterialTheme.typography.labelSmall.fontSize
                ),
                color = Color.Gray,
                modifier = Modifier.padding(top = 2.dp)
            )
        }
        
        if (isCurrentUser) {
            Spacer(modifier = Modifier.width(8.dp))
        }
    }
}

@Composable
fun GrowingTextEditor(
    text: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    val lineHeight = MaterialTheme.typography.bodyLarge.lineHeight.value * density.density
    
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(Color(0xFFF5F5F5), RoundedCornerShape(18.dp))
            .border(1.dp, Color(0xFFE0E0E0), RoundedCornerShape(18.dp))
    ) {
        BasicTextField(
            value = text,
            onValueChange = onValueChange,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp)
                .heightIn(min = 36.dp, max = lineHeight.dp * 4), // Max 4 lines
            textStyle = MaterialTheme.typography.bodyLarge.copy(
                color = Color.Black
            ),
            decorationBox = { innerTextField ->
                Box(
                    contentAlignment = Alignment.CenterStart,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    if (text.isEmpty()) {
                        Text(
                            "Type a message...",
                            style = MaterialTheme.typography.bodyLarge,
                            color = Color.Gray
                        )
                    }
                    innerTextField()
                }
            }
        )
    }
}

@Composable
fun EmptyConversationView(otherUserName: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "No messages yet",
            style = MaterialTheme.typography.titleMedium,
            color = Color.Gray
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        Text(
            text = "Start a conversation with $otherUserName",
            style = MaterialTheme.typography.bodyMedium,
            color = Color.Gray,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
fun LoadingConversation() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            CircularProgressIndicator(color = Color(0xFF8CC55D))
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Loading conversation...",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.Gray
            )
        }
    }
}