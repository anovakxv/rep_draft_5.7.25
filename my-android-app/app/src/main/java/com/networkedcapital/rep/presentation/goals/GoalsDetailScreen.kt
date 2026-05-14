package com.networkedcapital.rep.presentation.goals

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.outlined.AttachMoney
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.networkedcapital.rep.domain.model.BarChartData
import com.networkedcapital.rep.domain.model.FeedItem
import com.networkedcapital.rep.domain.model.Goal
import com.networkedcapital.rep.domain.model.User
import kotlin.math.max
import kotlin.math.min

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GoalsDetailScreen(
    goalId: Int,
    onBack: () -> Unit,
    onMessage: (User) -> Unit,
    onEditGoal: () -> Unit,
    onUpdateGoal: () -> Unit,
    onNavigateToPortal: (Int) -> Unit = {}, // Added portal navigation
    onNavigateToGroupChat: (Int) -> Unit = {}, // Added group chat navigation
    viewModel: GoalsDetailViewModel = hiltViewModel()
) {
    val goal by viewModel.goal.collectAsState()
    val feed by viewModel.feed.collectAsState()
    val team by viewModel.team.collectAsState()
    val loading by viewModel.loading.collectAsState()
    val error by viewModel.error.collectAsState()
    val currentUserId by viewModel.currentUserId.collectAsState()
    val currentUser by viewModel.currentUser.collectAsState()
    var selectedTab by remember { mutableStateOf(0) }
    var selectedProfileUser by remember { mutableStateOf<User?>(null) }

    LaunchedEffect(goalId) {
        viewModel.loadGoal(goalId)
    }

    // State for modal sheets
    val showActionSheet = remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState()
    var showSheet by remember { mutableStateOf(false) }
    var showSupportSheet by remember { mutableStateOf(false) }
    
    // Payment sheet state
    var paymentAmount by remember { mutableStateOf("") }
    var paymentMessage by remember { mutableStateOf("") }
    
    // Team Chat state
    var isCreatingTeamChat by remember { mutableStateOf(false) }
    var teamChatId by remember { mutableStateOf<Int?>(null) }
    var chatCreationError by remember { mutableStateOf<String?>(null) }
    
    // Function to open or create team chat
    fun openGoalTeamChat() {
        if (isCreatingTeamChat) return

        if (teamChatId != null) {
            // Navigate to existing chat
            onNavigateToGroupChat(teamChatId!!)
            return
        }

        // Create new chat logic
        isCreatingTeamChat = true
        viewModel.createTeamChat(
            goalId = goal?.id ?: 0,
            title = "Goal Team: ${goal?.title}"
        ) { chatId, error ->
            isCreatingTeamChat = false
            if (error != null) {
                chatCreationError = error
            } else if (chatId != null) {
                teamChatId = chatId
                onNavigateToGroupChat(chatId)
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize().background(Color.White)) {
            // Enhanced Top Bar with Portal Navigation
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .background(Color.White)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 15.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color(0xFF8CC55D)
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(2.dp)
                        ) {
                            Text(
                                text = goal?.title ?: "Goal Detail",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1,
                                color = Color.Black
                            )
                            
                            // Portal navigation link
                            goal?.portalId?.let { portalId ->
                                goal?.portalName?.let { portalName ->
                                    Row(
                                        modifier = Modifier.clickable { onNavigateToPortal(portalId) },
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = portalName,
                                            fontSize = 12.sp,
                                            color = Color(0xFF006400)
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Icon(
                                            imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                                            contentDescription = "Go to Portal",
                                            tint = Color(0xFF006400),
                                            modifier = Modifier.size(10.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(modifier = Modifier.size(24.dp)) // Placeholder for right icon
                }
                HorizontalDivider(
                    color = Color(0xFFE4E4E4),
                    modifier = Modifier.align(Alignment.BottomCenter)
                )
            }
            
            // Content area
            Box(modifier = Modifier.weight(1f)) {
                Column(modifier = Modifier.fillMaxSize()) {
                    // Enhanced Progress Bar (iOS Style)
                    if (goal != null) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            // Title
                            Text(goal!!.title, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            // iOS-style progress bar
                            Box(modifier = Modifier.fillMaxWidth()) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(34.dp)
                                        .background(Color(0xFFE0E0E0), RoundedCornerShape(4.dp))
                                )
                                val configuration = LocalConfiguration.current
                                Box(
                                    modifier = Modifier
                                        .width(
                                            (max(0f, min(1f, goal!!.progress.toFloat())) * 
                                            configuration.screenWidthDp * 0.92f).dp
                                        )
                                        .height(34.dp)
                                        .background(Color(0xFF8CC55D), RoundedCornerShape(4.dp))
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            Row {
                                Text("Metric: ${goal!!.metricName}", style = MaterialTheme.typography.bodySmall)
                                Spacer(modifier = Modifier.weight(1f))
                                Text("Goal Type: ${goal!!.typeName}", style = MaterialTheme.typography.bodySmall)
                            }
                            Row {
                                Text("Quota: ${goal!!.quotaString}", style = MaterialTheme.typography.bodySmall)
                                Spacer(modifier = Modifier.weight(1f))
                                Text("Progress: ${goal!!.valueString}", style = MaterialTheme.typography.bodySmall)
                            }
                            if (!goal!!.reportingName.isNullOrBlank()) {
                                Text("Reporting: ${goal!!.reportingName}", style = MaterialTheme.typography.bodySmall, color = Color.DarkGray)
                            }
                            if (goal!!.subtitle.isNotBlank()) {
                                Text(goal!!.subtitle, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                            }
                            if (goal!!.description.isNotBlank()) {
                                Text(goal!!.description, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                            }
                        }
                    }
                    
                    // iOS-Style Black Segmented Control
                    val segmentLabels = listOf("Feed", "Report", "Team")
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(40.dp)
                                .border(1.dp, Color.Black, RoundedCornerShape(4.dp))
                                .padding(2.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            segmentLabels.forEachIndexed { idx, label ->
                                val isSelected = selectedTab == idx
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .fillMaxHeight()
                                        .clip(RoundedCornerShape(2.dp))
                                        .background(if (isSelected) Color.Black else Color.Transparent)
                                        .clickable { selectedTab = idx },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = label,
                                        color = if (isSelected) Color.White else Color.Black,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                    )
                                }
                                if (idx < segmentLabels.lastIndex) {
                                    Spacer(modifier = Modifier.width(2.dp))
                                }
                            }
                        }
                    }
                    
                    // Content
                    if (loading) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    } else if (error != null) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text("Error: $error")
                        }
                    } else {
                        when (selectedTab) {
                            0 -> {
                                if (feed.isEmpty()) {
                                    Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Icon(Icons.Filled.Message, contentDescription = null, tint = Color.LightGray, modifier = Modifier.size(48.dp))
                                            Spacer(modifier = Modifier.height(12.dp))
                                            Text("No feed activity yet.", color = Color.Gray, fontSize = 16.sp)
                                            Text("Updates and progress will appear here.", color = Color.LightGray, fontSize = 13.sp)
                                        }
                                    }
                                } else {
                                    LazyColumn(modifier = Modifier.weight(1f)) {
                                        items(feed) { item ->
                                            EnhancedFeedItemView(
                                                item = item,
                                                currentUserId = currentUserId,
                                                currentUser = currentUser,
                                                onProfileClick = { user -> selectedProfileUser = user }
                                            )
                                        }
                                    }
                                }
                            }
                            1 -> {
                                if (error != null) {
                                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Icon(Icons.Filled.Message, contentDescription = null, tint = Color.Red, modifier = Modifier.size(48.dp))
                                            Spacer(modifier = Modifier.height(12.dp))
                                            Text("Oops! Couldn't load reporting data.", color = Color.Red, fontSize = 16.sp)
                                            Text(error ?: "Unknown error.", color = Color.LightGray, fontSize = 13.sp)
                                        }
                                    }
                                } else if (goal?.chartData?.isEmpty() != false) {
                                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Icon(Icons.Filled.Message, contentDescription = null, tint = Color.LightGray, modifier = Modifier.size(48.dp))
                                            Spacer(modifier = Modifier.height(12.dp))
                                            Text("No reporting data available.", color = Color.Gray, fontSize = 16.sp)
                                            Text("Charts and stats will appear here.", color = Color.LightGray, fontSize = 13.sp)
                                        }
                                    }
                                } else {
                                    EnhancedBarChartView(goal!!.chartData, goal!!.quota)
                                }
                            }
                            2 -> {
                                if (team.isNullOrEmpty()) {
                                    Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Icon(Icons.Filled.Message, contentDescription = null, tint = Color.LightGray, modifier = Modifier.size(48.dp))
                                            Spacer(modifier = Modifier.height(12.dp))
                                            Text("No team members yet.", color = Color.Gray, fontSize = 16.sp)
                                            Text("Invite teammates to join this goal.", color = Color.LightGray, fontSize = 13.sp)
                                        }
                                    }
                                } else {
                                    LazyColumn(modifier = Modifier.weight(1f)) {
                                        items(team) { user ->
                                            EnhancedTeamMemberItem(user, onMessage, onProfileClick = { selectedProfileUser = user })
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // iOS-Style Bottom Bar
            Column {
                HorizontalDivider(color = Color(0xFFE4E4E4))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(64.dp)
                        .background(Color.White)
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Button(
                        onClick = { showSheet = true },
                        modifier = Modifier
                            .weight(1f)
                            .height(41.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(red = 0.482f, green = 0.749f, blue = 0.294f)
                        ),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Actions",
                            tint = Color.White
                        )
                    }

                    Spacer(modifier = Modifier.width(16.dp))

                    IconButton(
                        onClick = { openGoalTeamChat() },
                        enabled = !isCreatingTeamChat
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Message,
                            contentDescription = "Team Chat",
                            tint = Color.Black
                        )
                    }
                }
            }
        }

        // Enhanced Support Button for Fund/Sales Goals
        if (goal?.typeName == "Fund" || goal?.typeName == "Sales") {
            Box(
                modifier = Modifier
                    .padding(bottom = 70.dp)
                    .padding(end = 20.dp)
                    .align(Alignment.BottomEnd)
            ) {
                Button(
                    onClick = { showSupportSheet = true },
                    modifier = Modifier
                        .shadow(
                            elevation = 4.dp,
                            shape = RoundedCornerShape(8.dp),
                            spotColor = Color(0x4D000000)
                        ),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color(0xFF006400)
                    ),
                    border = BorderStroke(2.dp, Color(0xFF006400))
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Outlined.AttachMoney,
                            contentDescription = null,
                            tint = Color(0xFF006400),
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Support",
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 16.sp
                        )
                    }
                }
            }
        }

        // Enhanced Role-Based Action Sheet
        if (showSheet) {
            ModalBottomSheet(
                onDismissRequest = { showSheet = false },
                sheetState = sheetState,
                containerColor = Color.White
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(24.dp)
                ) {
                    // Check if user is already on the team
                    val isOnTeam = team.any { it.id == viewModel.getCurrentUserId() }
                    val isCreator = goal?.creatorId == viewModel.getCurrentUserId()

                    // Show "Join Team" only if user is not already on the team
                    if (!isOnTeam && !isCreator && goal?.typeName == "Recruiting") {
                        Text(
                            text = "Join Team",
                            fontSize = 22.sp, // .title2 equivalent
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF8CC75D), // RGB(0.549, 0.78, 0.365)
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    viewModel.joinRecruitingGoal(goal?.id ?: 0) { success ->
                                        showSheet = false
                                        if (success) {
                                            viewModel.loadGoal(goal?.id ?: 0)
                                        }
                                    }
                                }
                                .padding(vertical = 5.dp),
                            textAlign = TextAlign.Center
                        )
                    }

                    // Show "Invite to Team" only if user is on the team or is creator
                    if (isOnTeam || isCreator) {
                        Text(
                            text = "Invite to Team",
                            fontSize = 22.sp, // .title2 equivalent
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF8CC75D),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    showSheet = false
                                    // TODO: Show invite team sheet
                                }
                                .padding(vertical = 5.dp),
                            textAlign = TextAlign.Center
                        )
                    }

                    // Update Progress for non-Recruiting goals
                    if (goal?.typeName != "Recruiting") {
                        Text(
                            text = "Update Progress",
                            fontSize = 22.sp, // .title2 equivalent
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF8CC75D),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    showSheet = false
                                    onUpdateGoal()
                                }
                                .padding(vertical = 5.dp),
                            textAlign = TextAlign.Center
                        )
                    }

                    Text(
                        text = "Edit Goal",
                        fontSize = 22.sp, // .title2 equivalent - same as other primary actions
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF8CC75D),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                showSheet = false
                                onEditGoal()
                            }
                            .padding(vertical = 5.dp),
                        textAlign = TextAlign.Center
                    )

                    Text(
                        text = "Delete Goal",
                        fontSize = 16.sp, // .body equivalent
                        fontWeight = FontWeight.Normal,
                        color = Color.Red, // Destructive role
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                showSheet = false
                                // TODO: Show delete confirmation alert
                            }
                            .padding(vertical = 5.dp),
                        textAlign = TextAlign.Center
                    )

                    Text(
                        text = "Cancel",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Normal,
                        color = Color.Gray, // .secondary equivalent
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { showSheet = false }
                            .padding(vertical = 5.dp),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }

        // Chat creation error alert
        if (chatCreationError != null) {
            AlertDialog(
                onDismissRequest = { chatCreationError = null },
                title = { Text("Chat Error") },
                text = { Text(chatCreationError!!) },
                confirmButton = {
                    TextButton(onClick = { chatCreationError = null }) {
                        Text("OK")
                    }
                }
            )
        }

        // Enhanced Payment/Support Sheet
        if (showSupportSheet) {
            ModalBottomSheet(
                onDismissRequest = { showSupportSheet = false },
                sheetState = rememberModalBottomSheetState()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Support ${goal?.title ?: "Goal"}",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Text("Your support helps this goal succeed")
                    
                    // Payment Amount
                    OutlinedTextField(
                        value = paymentAmount,
                        onValueChange = { paymentAmount = it },
                        label = { Text("Amount") },
                        leadingIcon = {
                            Text(
                                "$",
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(start = 12.dp)
                            )
                        },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.fillMaxWidth()
                    )
                    
                    // Message field
                    OutlinedTextField(
                        value = paymentMessage,
                        onValueChange = { paymentMessage = it },
                        label = { Text("Message (Optional)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    
                    // Submit payment button
                    Button(
                        onClick = {
                            // Process payment
                            viewModel.processPayment(
                                goalId = goal?.id ?: 0,
                                portalId = goal?.portalId ?: 0,
                                amount = paymentAmount.toDoubleOrNull() ?: 0.0,
                                message = paymentMessage
                            )
                            showSupportSheet = false
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF006400)
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "Submit Payment",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    }
                    
                    TextButton(
                        onClick = { showSupportSheet = false },
                        modifier = Modifier.align(Alignment.CenterHorizontally)
                    ) {
                        Text("Cancel")
                    }
                }
            }
        }

        // Enhanced Profile Dialog
        if (selectedProfileUser != null) {
            AlertDialog(
                onDismissRequest = { selectedProfileUser = null },
                title = { 
                    Text(
                        "${selectedProfileUser!!.fullName ?: selectedProfileUser!!.username ?: "User"} Profile",
                        fontWeight = FontWeight.Bold
                    ) 
                },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        // Profile image
                        Box(modifier = Modifier.align(Alignment.CenterHorizontally)) {
                            if (!selectedProfileUser!!.profile_picture_url.isNullOrBlank()) {
                                AsyncImage(
                                    model = selectedProfileUser!!.profile_picture_url,
                                    contentDescription = "Profile picture",
                                    contentScale = ContentScale.Crop,
                                    modifier = Modifier
                                        .size(80.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFFE0E0E0))
                                )
                            } else {
                                Box(
                                    modifier = Modifier
                                        .size(80.dp)
                                        .background(Color(0xFFE0E0E0), CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        (selectedProfileUser!!.fullName ?: selectedProfileUser!!.username ?: "").take(1), 
                                        fontWeight = FontWeight.Bold, 
                                        fontSize = 32.sp,
                                        color = Color.Black
                                    )
                                }
                            }
                        }
                        
                        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                        
                        Text("ID: ${selectedProfileUser!!.id}")
                        Text("Username: ${selectedProfileUser!!.username ?: "(none)"}")
                        Text("Full Name: ${selectedProfileUser!!.fullName ?: selectedProfileUser!!.fname ?: "(none)"}")
                    }
                },
                confirmButton = {
                    Button(
                        onClick = { 
                            onMessage(selectedProfileUser!!)
                            selectedProfileUser = null 
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF8CC55D)
                        )
                    ) {
                        Text("Message")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { selectedProfileUser = null }) {
                        Text("Close")
                    }
                }
            )
        }
    }
}    

@Composable
private fun ActionButton(text: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.White,
            contentColor = Color(0xFF8CC55D)
        ),
        border = BorderStroke(1.dp, Color(0xFF8CC55D)),
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
fun EnhancedFeedItemView(
    item: FeedItem,
    currentUserId: Int,
    currentUser: User?,
    onProfileClick: (User) -> Unit
) {
    // If this feed item is from the current user, use their actual user data
    val user = if (item.userId == currentUserId && currentUser != null) {
        currentUser
    } else {
        User(
            id = item.userId ?: 0,
            username = item.userName,
            fullName = item.userName,
            fname = null,
            profile_picture_url = item.profilePictureUrl
        )
    }
    val context = LocalContext.current
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Row(verticalAlignment = Alignment.Top) {
            // Profile image with Coil, fallback to initials or icon on error
            Box(modifier = Modifier.size(60.dp)) {
                if (!user.profile_picture_url.isNullOrBlank()) {
                    AsyncImage(
                        model = user.profile_picture_url,
                        contentDescription = "Profile picture",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .size(60.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFE0E0E0))
                            .clickable { onProfileClick(user) }
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .background(Color(0xFFE0E0E0), CircleShape)
                            .clickable { onProfileClick(user) },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            item.userName.take(1), 
                            fontWeight = FontWeight.Bold, 
                            color = Color.Black,
                            fontSize = 24.sp
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    item.userName, 
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
                
                Text(
                    item.date, 
                    fontSize = 12.sp, 
                    color = Color.Gray
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    item.value, 
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium
                )
                
                if (item.note.isNotBlank()) {
                    Text(
                        item.note, 
                        fontSize = 14.sp, 
                        color = Color.DarkGray,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
        
        // Attachments section - iOS style
        if (!item.attachments.isNullOrEmpty()) {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 12.dp)
            ) {
                items(item.attachments) { attachment ->
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        if (attachment.isImage == true && !attachment.url.isNullOrBlank()) {
                            // Image attachment
                            AsyncImage(
                                model = attachment.url,
                                contentDescription = attachment.fileName ?: "Attachment image",
                                contentScale = ContentScale.Crop,
                                modifier = Modifier
                                    .size(100.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFE0E0E0))
                                    .clickable {
                                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(attachment.url))
                                        context.startActivity(intent)
                                    }
                            )
                        } else if (!attachment.url.isNullOrBlank()) {
                            // Document or non-image attachment
                            Box(
                                modifier = Modifier
                                    .size(100.dp, 80.dp)
                                    .background(Color(0xFFF5F5F5), RoundedCornerShape(8.dp))
                                    .clickable {
                                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(attachment.url))
                                        context.startActivity(intent)
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Icon(
                                        imageVector = Icons.Default.Description,
                                        contentDescription = "Document",
                                        tint = Color(0xFF4A90E2),
                                        modifier = Modifier.size(30.dp)
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = attachment.fileName?.take(10) ?: "Document", 
                                        fontSize = 10.sp,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        textAlign = TextAlign.Center
                                    )
                                }
                            }
                        }
                        
                        if (!attachment.note.isNullOrBlank()) {
                            Text(
                                attachment.note,
                                fontSize = 12.sp,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.width(100.dp),
                                color = Color.Gray
                            )
                        }
                    }
                }
            }
        }
        
        HorizontalDivider(modifier = Modifier.padding(top = 12.dp))
    }
}

@Composable
fun EnhancedTeamMemberItem(user: User, onMessage: (User) -> Unit, onProfileClick: (User) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Profile image with Coil, fallback to initials or icon on error
        Box(modifier = Modifier.size(50.dp)) {
            if (!user.profile_picture_url.isNullOrBlank()) {
                AsyncImage(
                    model = user.profile_picture_url,
                    contentDescription = "Profile picture",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .size(50.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFE0E0E0))
                        .clickable { onProfileClick(user) }
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(50.dp)
                        .background(Color(0xFFE0E0E0), CircleShape)
                        .clickable { onProfileClick(user) },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        (user.fullName ?: user.username ?: "").take(1), 
                        fontWeight = FontWeight.Bold, 
                        color = Color.Black,
                        fontSize = 18.sp
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(
            modifier = Modifier
                .weight(1f)
                .clickable { onProfileClick(user) }
        ) {
            Text(
                text = user.displayName,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp
            )
            
            if (user.username != null) {
                Text(
                    text = "@${user.username}",
                    fontSize = 12.sp,
                    color = Color.Gray
                )
            }
            
            // Optional role or join date
            user.role?.let {
                Text(
                    text = it,
                    fontSize = 12.sp,
                    color = Color(0xFF8CC55D)
                )
            }
        }
        
        IconButton(
            onClick = { onMessage(user) },
            modifier = Modifier
                .size(44.dp)
                .border(1.dp, Color(0xFFE4E4E4), CircleShape)
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Chat,
                contentDescription = "Message",
                tint = Color.Black,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
fun EnhancedBarChartView(data: List<BarChartData>, quota: Double) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Text(
            text = "Progress", 
            fontWeight = FontWeight.Medium, 
            fontSize = 16.sp,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(260.dp)
                .padding(vertical = 16.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            data.forEach { item ->
                val quotaValue = if (quota > 0) quota else 1.0
                val percent = (item.value / quotaValue).coerceIn(0.0, 1.0)
                val barHeight = percent * 200f
                
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(horizontal = 4.dp)
                ) {
                    // Value label above bar
                    Text(
                        item.valueLabel, 
                        fontSize = 12.sp, 
                        fontWeight = FontWeight.Bold, 
                        color = Color.Black
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Box(
                        modifier = Modifier
                            .width(36.dp)
                            .height(barHeight.dp)
                            .background(
                                color = Color(0xFF8CC55D),
                                shape = RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp)
                            )
                    )
                    
                    // Bottom label
                    Text(
                        item.bottomLabel, 
                        fontSize = 12.sp, 
                        color = Color.DarkGray,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
    }
}

// Extension properties to make code cleaner
val User.role: String?
    get() = this::class.members.firstOrNull { it.name == "role" }?.call(this) as? String