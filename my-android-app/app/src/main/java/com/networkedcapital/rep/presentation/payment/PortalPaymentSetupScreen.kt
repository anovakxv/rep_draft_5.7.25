package com.networkedcapital.rep.presentation.payment

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.networkedcapital.rep.presentation.common.WebViewScreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PortalPaymentSetupScreen(
    portalId: Int,
    portalName: String,
    onNavigateBack: () -> Unit,
    viewModel: PortalPaymentSetupViewModel = hiltViewModel()
) {
    val setupState by viewModel.setupState.collectAsState()

    // Initialize viewModel with portal info
    LaunchedEffect(portalId, portalName) {
        viewModel.initialize(portalId, portalName)
    }

    // Show WebView for Stripe pages
    val webViewUrl = setupState.webViewUrl
    if (setupState.showWebView && webViewUrl != null) {
        WebViewScreen(
            url = webViewUrl,
            title = setupState.webViewTitle,
            onDismiss = { viewModel.closeWebView() }
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Payment Setup") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.fillMaxSize().padding(paddingValues)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                // Header
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        text = "Payment Settings",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Set up your portal to receive payments",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Status Card
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            when {
                                setupState.isConnected -> {
                                    Icon(
                                        imageVector = Icons.Default.CheckCircle,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(32.dp)
                                    )
                                    Text(
                                        text = "Stripe Connected",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                                setupState.isRequestPending -> {
                                    Icon(
                                        imageVector = Icons.Default.Schedule,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.tertiary,
                                        modifier = Modifier.size(32.dp)
                                    )
                                    Text(
                                        text = "Approval Pending",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                                else -> {
                                    Icon(
                                        imageVector = Icons.Default.Warning,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.tertiary,
                                        modifier = Modifier.size(32.dp)
                                    )
                                    Text(
                                        text = "Not Connected to Stripe",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }
                        }

                        when {
                            setupState.isConnected -> {
                                Text(
                                    text = "Your portal is connected to Stripe. Click below to manage your account or complete verification steps if needed.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )

                                Button(
                                    onClick = {
                                        if (setupState.accountFullySetup) {
                                            viewModel.getStripeDashboardLink()
                                        } else {
                                            viewModel.createConnectAccount()
                                        }
                                    },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Icon(
                                        imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                                        contentDescription = null,
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(if (setupState.accountFullySetup) "Manage Stripe Account" else "Complete Stripe Setup")
                                }
                            }
                            setupState.isRequestPending -> {
                                Text(
                                    text = setupState.pendingApprovalMessage ?: "Your Stripe Connect request is pending admin approval. You'll be notified when it's approved.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            else -> {
                                Text(
                                    text = "Connect your portal to Stripe to receive donations, payments, and purchases from users.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )

                                Button(
                                    onClick = { viewModel.createConnectAccount() },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Link,
                                        contentDescription = null,
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("Request Stripe Connect")
                                }
                            }
                        }
                    }
                }

                // Payment Info Card
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = "About Payments",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )

                        InfoRow(
                            icon = Icons.Default.CreditCard,
                            title = "Secure Payments",
                            description = "All payments are securely processed by Stripe, a PCI-compliant payment processor."
                        )

                        InfoRow(
                            icon = Icons.Default.AttachMoney,
                            title = "Transaction Fee",
                            description = "Rep does not charge any additional platform fee. Stripe's standard rates apply. For example: 2.9% + 30¢ per successful transaction for domestic cards, 0.8% for ACH Direct Debit. For full details, see stripe.com/pricing."
                        )

                        InfoRow(
                            icon = Icons.Default.CalendarMonth,
                            title = "Payouts",
                            description = "Funds will be directly deposited to your bank account based on your Stripe payout schedule."
                        )

                        InfoRow(
                            icon = Icons.Default.Description,
                            title = "Tax Information",
                            description = "You'll need to provide tax information in your Stripe account to receive payments."
                        )
                    }
                }

                // Error message
                setupState.errorMessage?.let { error ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer
                        )
                    ) {
                        Text(
                            text = error,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }

            // Loading overlay
            if (setupState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Surface(
                        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.8f),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun InfoRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    description: String
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(24.dp)
        )
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
