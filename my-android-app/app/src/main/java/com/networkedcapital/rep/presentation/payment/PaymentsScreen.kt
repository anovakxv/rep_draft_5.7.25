package com.networkedcapital.rep.presentation.payment

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.OpenInNew
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.networkedcapital.rep.domain.model.ActiveSubscription
import com.networkedcapital.rep.domain.model.TransactionHistoryItem
import com.networkedcapital.rep.presentation.common.WebViewScreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentsScreen(
    onNavigateBack: () -> Unit,
    viewModel: PaymentViewModel = hiltViewModel()
) {
    val paymentState by viewModel.paymentState.collectAsState()

    var showCancelDialog by remember { mutableStateOf(false) }
    var subscriptionToCancel by remember { mutableStateOf<ActiveSubscription?>(null) }

    // Show WebView for Stripe pages
    val webViewUrl = paymentState.webViewUrl
    if (paymentState.showWebView && webViewUrl != null) {
        WebViewScreen(
            url = webViewUrl,
            title = paymentState.webViewTitle,
            onDismiss = { viewModel.closeWebView() }
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Payments & Subscriptions") },
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
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(32.dp)
            ) {
                // Payment Methods Section
                item {
                    PaymentMethodsSection(
                        onEditPaymentMethods = { viewModel.openStripeCustomerPortal() }
                    )
                }

                // Payment Support Section
                item {
                    PaymentSupportSection(
                        onRequestHelp = { viewModel.openStripeSupport() }
                    )
                }

                // Active Subscriptions Section
                item {
                    Text(
                        text = "Active Subscriptions",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (paymentState.subscriptions.isEmpty() && !paymentState.isLoading) {
                    item {
                        EmptyStateCard("You have no active monthly subscriptions.")
                    }
                } else {
                    items(paymentState.subscriptions) { subscription ->
                        SubscriptionCard(
                            subscription = subscription,
                            onCancel = {
                                subscriptionToCancel = subscription
                                showCancelDialog = true
                            }
                        )
                    }

                    item {
                        Text(
                            text = "You can cancel your subscriptions directly in the app. Changes take effect at the end of the current billing period.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Payment History Section
                item {
                    Text(
                        text = "Payment History",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (paymentState.paymentHistory.isEmpty() && !paymentState.isLoading) {
                    item {
                        EmptyStateCard("Your payment history will appear here.")
                    }
                } else {
                    items(paymentState.paymentHistory) { transaction ->
                        TransactionCard(transaction = transaction)
                    }
                }
            }

            // Loading indicator
            if (paymentState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        }
    }

    // Cancel subscription confirmation dialog
    if (showCancelDialog && subscriptionToCancel != null) {
        AlertDialog(
            onDismissRequest = { showCancelDialog = false },
            title = { Text("Cancel Subscription?") },
            text = {
                Text("Are you sure you want to cancel your ${subscriptionToCancel?.formattedAmount}/month subscription to ${subscriptionToCancel?.name}? This cannot be undone.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        subscriptionToCancel?.let { viewModel.cancelSubscription(it.id) }
                        showCancelDialog = false
                        subscriptionToCancel = null
                    }
                ) {
                    Text("Cancel Subscription", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showCancelDialog = false }) {
                    Text("Keep Subscription")
                }
            }
        )
    }

    // Error message dialog
    paymentState.errorMessage?.let { error ->
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
private fun PaymentMethodsSection(
    onEditPaymentMethods: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(
            text = "Your Payment Methods",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        OutlinedButton(
            onClick = onEditPaymentMethods,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                imageVector = Icons.Default.CreditCard,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text("Edit Payment Methods")
            Spacer(modifier = Modifier.weight(1f))
            Icon(
                imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                contentDescription = null,
                modifier = Modifier.size(16.dp)
            )
        }

        Text(
            text = "Your saved payment cards are used for your donations, payments, and subscriptions.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "About Your Payment Information",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "Your payment information is securely stored with Stripe. You can add, remove, or update your payment cards at any time.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun PaymentSupportSection(
    onRequestHelp: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(
            text = "Payment Support",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        OutlinedButton(
            onClick = onRequestHelp,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Help,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text("Request Refund or Payment Help")
            Spacer(modifier = Modifier.weight(1f))
            Icon(
                imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                contentDescription = null,
                modifier = Modifier.size(16.dp)
            )
        }

        Text(
            text = "For payment disputes, refund requests, or other payment issues, contact Stripe support directly.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun SubscriptionCard(
    subscription: ActiveSubscription,
    onCancel: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = subscription.name,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "${subscription.formattedAmount}/mo",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            TextButton(
                onClick = onCancel,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Cancel Subscription", style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun TransactionCard(
    transaction: TransactionHistoryItem
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = transaction.description,
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = transaction.formattedDate,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Stripe Transaction ID: ${transaction.id}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
        }
        Text(
            text = transaction.formattedAmount,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold
        )
    }
    HorizontalDivider()
}

@Composable
private fun EmptyStateCard(message: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
