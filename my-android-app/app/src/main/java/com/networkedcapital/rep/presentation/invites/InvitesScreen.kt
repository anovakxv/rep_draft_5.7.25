package com.networkedcapital.rep.presentation.invites

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.networkedcapital.rep.domain.model.GoalTeamInvite

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvitesScreen(
    userId: Int,
    onNavigateBack: () -> Unit,
    onViewGoal: (Int) -> Unit,
    viewModel: InviteViewModel = hiltViewModel()
) {
    val inviteState by viewModel.inviteState.collectAsState()

    // Initialize viewModel with userId
    LaunchedEffect(userId) {
        viewModel.initialize(userId)
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        text = "Invitations",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.fillMaxSize().padding(paddingValues)) {
            when {
                inviteState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                inviteState.invites.isEmpty() -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            modifier = Modifier.size(60.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No pending invitations",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(inviteState.invites) { invite ->
                            InviteCard(
                                invite = invite,
                                isProcessing = inviteState.processingInviteId == invite.id,
                                onAccept = { viewModel.acceptInvite(invite) },
                                onDecline = { viewModel.declineInvite(invite) },
                                onViewGoal = { onViewGoal(invite.goals_id) }
                            )
                        }
                    }
                }
            }
        }
    }

    // Alert dialog
    val alertMessage = inviteState.alertMessage
    if (inviteState.showAlert && alertMessage != null) {
        AlertDialog(
            onDismissRequest = {
                viewModel.dismissAlert()
                // If no invites left, navigate back
                if (inviteState.invites.isEmpty()) {
                    onNavigateBack()
                }
            },
            title = { Text("Team Invite") },
            text = { Text(alertMessage) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.dismissAlert()
                        if (inviteState.invites.isEmpty()) {
                            onNavigateBack()
                        }
                    }
                ) {
                    Text("OK")
                }
            }
        )
    }

    // Error message dialog
    inviteState.errorMessage?.let { error ->
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text("Error") },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
private fun InviteCard(
    invite: GoalTeamInvite,
    isProcessing: Boolean,
    onAccept: () -> Unit,
    onDecline: () -> Unit,
    onViewGoal: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Profile image - already patched by InviteViewModel
                if (invite.inviterPhotoURL != null) {
                    AsyncImage(
                        model = invite.inviterPhotoURL,
                        contentDescription = "Profile picture",
                        modifier = Modifier.size(40.dp)
                    )
                } else {
                    // Placeholder
                    Surface(
                        modifier = Modifier.size(40.dp),
                        color = MaterialTheme.colorScheme.primaryContainer,
                        shape = MaterialTheme.shapes.small
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = invite.inviterDisplayName.take(1).uppercase(),
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }
                }

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Goal Team Invite",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "${invite.inviterDisplayName} invited you to join '${invite.goalTitle ?: "a goal"}'",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2
                    )
                }
            }

            // Action buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Button(
                    onClick = onAccept,
                    modifier = Modifier.weight(1f),
                    enabled = !isProcessing
                ) {
                    if (isProcessing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        Text("Accept", fontWeight = FontWeight.Medium)
                    }
                }

                OutlinedButton(
                    onClick = onDecline,
                    modifier = Modifier.weight(1f),
                    enabled = !isProcessing
                ) {
                    Text("Decline", fontWeight = FontWeight.Medium)
                }
            }

            // View goal button
            TextButton(
                onClick = onViewGoal,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isProcessing
            ) {
                Text(
                    text = "View Goal",
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}
