package com.networkedcapital.rep.presentation.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    onNavigateToEditProfile: () -> Unit,
    onNavigateToPayments: () -> Unit,
    onNavigateToTerms: () -> Unit,
    onNavigateToStripeConnectApproval: () -> Unit = {},
    onLogout: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showLogoutDialog by remember { mutableStateOf(false) }

    // Dark green color matching iOS
    val darkGreen = Color(0xFF006600)
    val repGreen = Color(red = 0.549f, green = 0.78f, blue = 0.365f)

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = darkGreen
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = repGreen
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            // Account Section
            item {
                SettingsSectionHeader("Account")
            }

            item {
                SettingsItem(
                    icon = Icons.Default.Person,
                    title = "Edit Profile",
                    iconTint = darkGreen,
                    onClick = onNavigateToEditProfile
                )
                HorizontalDivider()
            }

            // Payments Section
            item {
                SettingsSectionHeader("Payments")
            }

            item {
                SettingsItem(
                    icon = Icons.Default.CreditCard,
                    title = "Payment & Payouts",
                    iconTint = darkGreen,
                    onClick = onNavigateToPayments
                )
                HorizontalDivider()
            }

            // Notifications Section
            item {
                SettingsSectionHeader("Notifications")
            }

            item {
                SettingsToggleItem(
                    title = "Push Notifications",
                    checked = uiState.notificationSettings.pushNotificationsEnabled,
                    onCheckedChange = { viewModel.togglePushNotifications(it) }
                )
            }

            // Show sub-toggles only if push notifications are enabled
            if (uiState.notificationSettings.pushNotificationsEnabled) {
                item {
                    SettingsToggleItem(
                        title = "Direct Messages",
                        checked = uiState.notificationSettings.notifDirectMessages,
                        onCheckedChange = { viewModel.toggleDirectMessages(it) }
                    )
                }

                item {
                    SettingsToggleItem(
                        title = "Group Messages",
                        checked = uiState.notificationSettings.notifGroupMessages,
                        onCheckedChange = { viewModel.toggleGroupMessages(it) }
                    )
                }

                item {
                    SettingsToggleItem(
                        title = "Goal Team Invites",
                        checked = uiState.notificationSettings.notifGoalInvites,
                        onCheckedChange = { viewModel.toggleGoalInvites(it) }
                    )
                }
            }

            item {
                HorizontalDivider()
            }

            // Legal Section
            item {
                SettingsSectionHeader("Legal")
            }

            item {
                SettingsItem(
                    icon = Icons.Default.Description,
                    title = "Terms of Use",
                    iconTint = Color.Gray,
                    onClick = onNavigateToTerms
                )
                HorizontalDivider()
            }

            // Admin Tools Section (conditional)
            if (uiState.isAdmin) {
                item {
                    SettingsSectionHeader("Admin Tools")
                }

                item {
                    SettingsItem(
                        icon = Icons.Default.VerifiedUser,
                        title = "Approve Stripe Connect Accounts",
                        iconTint = Color(0xFF2196F3), // Blue color
                        onClick = onNavigateToStripeConnectApproval
                    )
                    HorizontalDivider()
                }
            }

            // Logout Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
            }

            item {
                Button(
                    onClick = { showLogoutDialog = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFF3B30) // iOS red color
                    )
                ) {
                    Text(
                        text = "Log Out",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }

        // Loading indicator
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = repGreen)
            }
        }

        // Logout confirmation dialog
        if (showLogoutDialog) {
            AlertDialog(
                onDismissRequest = { showLogoutDialog = false },
                title = { Text("Log Out") },
                text = { Text("Are you sure you want to log out?") },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showLogoutDialog = false
                            viewModel.logout(onSuccess = onLogout)
                        },
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = Color(0xFFFF3B30)
                        )
                    ) {
                        Text("Log Out")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showLogoutDialog = false }) {
                        Text("Cancel")
                    }
                }
            )
        }

        // Error message snackbar
        uiState.errorMessage?.let { error ->
            LaunchedEffect(error) {
                // Show error snackbar or toast
                viewModel.clearError()
            }
        }
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.labelMedium,
        color = Color.Gray,
        modifier = Modifier.padding(
            start = 16.dp,
            end = 16.dp,
            top = 16.dp,
            bottom = 8.dp
        )
    )
}

@Composable
private fun SettingsItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    iconTint: Color = Color.Gray,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            color = iconTint,
            modifier = Modifier.weight(1f)
        )

        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = Color.Gray,
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
private fun SettingsToggleItem(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f)
        )

        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = Color(red = 0.549f, green = 0.78f, blue = 0.365f),
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = Color.Gray
            )
        )
    }
}
