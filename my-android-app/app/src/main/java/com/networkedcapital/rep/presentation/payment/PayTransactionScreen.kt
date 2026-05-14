package com.networkedcapital.rep.presentation.payment

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.networkedcapital.rep.domain.model.TransactionType
import com.networkedcapital.rep.presentation.common.WebViewScreen
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PayTransactionScreen(
    portalId: Int,
    portalName: String,
    goalId: Int,
    goalName: String,
    transactionType: TransactionType,
    onNavigateBack: () -> Unit,
    onTransactionComplete: () -> Unit,
    viewModel: PayTransactionViewModel = hiltViewModel()
) {
    val transactionState by viewModel.transactionState.collectAsState()

    // Initialize viewModel
    LaunchedEffect(portalId, goalId, transactionType) {
        viewModel.initialize(portalId, goalId, transactionType)
    }

    // Show WebView for Stripe Checkout
    val webViewUrl = transactionState.webViewUrl
    if (transactionState.showWebView && webViewUrl != null) {
        WebViewScreen(
            url = webViewUrl,
            title = "Stripe's Secure Website:",
            onDismiss = {
                viewModel.closeWebView()
                // Note: In a real implementation, you'd need to handle deep links
                // to detect payment completion/cancellation
            }
        )
        return
    }

    // Show success banner and auto-dismiss
    LaunchedEffect(transactionState.showSuccessBanner) {
        if (transactionState.showSuccessBanner) {
            delay(2500)
            viewModel.dismissSuccessBanner()
            onTransactionComplete()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(transactionType.displayName) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Cancel"
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
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = "${transactionType.displayName} to $portalName",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )

                    if (goalName.isNotEmpty()) {
                        Text(
                            text = "For: $goalName",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }

                    Text(
                        text = transactionType.subtitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Amount Entry
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = transactionType.amountLabel,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )

                    OutlinedTextField(
                        value = transactionState.amount,
                        onValueChange = { viewModel.updateAmount(it) },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("0.00") },
                        leadingIcon = { Text("$", style = MaterialTheme.typography.titleLarge) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        textStyle = MaterialTheme.typography.titleLarge,
                        enabled = !transactionState.isMonthlySubscription,
                        singleLine = true
                    )

                    // Quick amount buttons
                    if (!transactionState.isMonthlySubscription) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            listOf(10, 20, 50, 100).forEach { amount ->
                                OutlinedButton(
                                    onClick = { viewModel.updateAmount(amount.toString()) },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text("$$amount")
                                }
                            }
                        }
                    }
                }

                // Monthly subscription toggle
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .toggleable(
                            value = transactionState.isMonthlySubscription,
                            onValueChange = { viewModel.toggleMonthlySubscription(it) }
                        )
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Make this a monthly recurring payment",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Switch(
                        checked = transactionState.isMonthlySubscription,
                        onCheckedChange = null
                    )
                }

                // Monthly amount selection
                if (transactionState.isMonthlySubscription) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(
                            text = "Choose your monthly amount:",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            viewModel.monthlyPriceOptions.forEach { (amount, priceId) ->
                                val isSelected = transactionState.selectedPriceId == priceId
                                Button(
                                    onClick = { viewModel.selectMonthlyAmount(amount, priceId) },
                                    modifier = Modifier.weight(1f),
                                    colors = if (isSelected) {
                                        ButtonDefaults.buttonColors()
                                    } else {
                                        ButtonDefaults.outlinedButtonColors()
                                    }
                                ) {
                                    Text("$$amount")
                                }
                            }
                        }
                    }
                }

                // Message/Notes
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = transactionType.messageLabel,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )

                    OutlinedTextField(
                        value = transactionState.message,
                        onValueChange = { viewModel.updateMessage(it) },
                        modifier = Modifier.fillMaxWidth(),
                        minLines = 2,
                        maxLines = 4
                    )
                }

                // Payment button
                Button(
                    onClick = { viewModel.createCheckoutSession() },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !transactionState.isLoading &&
                              transactionState.amount.isNotEmpty() &&
                              (!transactionState.isMonthlySubscription || transactionState.selectedPriceId.isNotEmpty())
                ) {
                    if (transactionState.isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        val amountText = transactionState.amount.toDoubleOrNull()?.let {
                            String.format("%.2f", it)
                        } ?: "0.00"

                        Text(
                            if (transactionState.isMonthlySubscription) {
                                "Subscribe $$amountText/mo"
                            } else {
                                "${transactionType.ctaText} $$amountText"
                            }
                        )
                    }
                }

                // Info text
                Text(
                    text = "Payment info is handled directly through Stripe, a secure online payments platform. You'll be redirected to a secure payment page to complete your ${if (transactionState.isMonthlySubscription) "subscription" else transactionType.displayName.lowercase()}.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                if (transactionType == TransactionType.DONATION) {
                    Text(
                        text = "If your payment is a donation, it may be tax deductible. A receipt will be emailed to you.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Success banner overlay
            if (transactionState.showSuccessBanner) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.BottomCenter
                ) {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surface
                        ),
                        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(18.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(28.dp)
                            )
                            Text(
                                text = transactionType.receiptTitle,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }
    }

    // Payment setup alert
    if (transactionState.showPaymentSetupAlert) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissPaymentSetupAlert() },
            title = { Text("Payments Not Ready") },
            text = { Text("This organization hasn't completed their payment setup yet and cannot receive payments at this time.") },
            confirmButton = {
                TextButton(onClick = { viewModel.dismissPaymentSetupAlert() }) {
                    Text("OK")
                }
            }
        )
    }

    // Error message dialog
    transactionState.errorMessage?.let { error ->
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text("Payment Error") },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }
}
