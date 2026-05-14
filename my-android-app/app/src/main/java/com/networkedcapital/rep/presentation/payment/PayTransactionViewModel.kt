package com.networkedcapital.rep.presentation.payment

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.PaymentRepository
import com.networkedcapital.rep.domain.model.TransactionType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class PaymentStatus {
    object Initial : PaymentStatus()
    object Loading : PaymentStatus()
    object Success : PaymentStatus()
    data class Failed(val message: String) : PaymentStatus()
}

data class PayTransactionState(
    val amount: String = "",
    val message: String = "",
    val isMonthlySubscription: Boolean = false,
    val selectedPriceId: String = "",
    val paymentStatus: PaymentStatus = PaymentStatus.Initial,
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val showWebView: Boolean = false,
    val webViewUrl: String? = null,
    val showSuccessBanner: Boolean = false,
    val showPaymentSetupAlert: Boolean = false
)

@HiltViewModel
class PayTransactionViewModel @Inject constructor(
    private val paymentRepository: PaymentRepository
) : ViewModel() {

    private val _transactionState = MutableStateFlow(PayTransactionState())
    val transactionState: StateFlow<PayTransactionState> = _transactionState.asStateFlow()

    // Monthly subscription price options (from iOS)
    val monthlyPriceOptions = listOf(
        Pair(5, "price_1S8BJNLEcZxL3ukIiYVOMyHD"),
        Pair(10, "price_1S8BJeLEcZxL3ukI3fpsE25j"),
        Pair(20, "price_1S8BJuLEcZxL3ukIwJshQJp6"),
        Pair(40, "price_1S8BK9LEcZxL3ukISu3iPeLK")
    )

    private var portalId: Int = 0
    private var goalId: Int = 0
    private var transactionType: TransactionType = TransactionType.DONATION

    fun initialize(portalId: Int, goalId: Int, transactionType: TransactionType) {
        this.portalId = portalId
        this.goalId = goalId
        this.transactionType = transactionType
    }

    fun updateAmount(amount: String) {
        _transactionState.value = _transactionState.value.copy(amount = amount)
    }

    fun updateMessage(message: String) {
        _transactionState.value = _transactionState.value.copy(message = message)
    }

    fun toggleMonthlySubscription(enabled: Boolean) {
        _transactionState.value = _transactionState.value.copy(
            isMonthlySubscription = enabled,
            selectedPriceId = if (!enabled) "" else _transactionState.value.selectedPriceId
        )
    }

    fun selectMonthlyAmount(amount: Int, priceId: String) {
        _transactionState.value = _transactionState.value.copy(
            amount = amount.toString(),
            selectedPriceId = priceId
        )
    }

    fun createCheckoutSession() {
        val state = _transactionState.value

        // Validate amount
        if (state.isMonthlySubscription) {
            if (state.selectedPriceId.isEmpty()) {
                _transactionState.value = state.copy(
                    paymentStatus = PaymentStatus.Failed("Please select a monthly amount")
                )
                return
            }
        } else {
            val amountValue = state.amount.toDoubleOrNull()
            if (amountValue == null || amountValue < 1.0) {
                _transactionState.value = state.copy(
                    paymentStatus = PaymentStatus.Failed("Please enter a valid amount (minimum $1.00)")
                )
                return
            }
        }

        viewModelScope.launch {
            _transactionState.value = state.copy(
                isLoading = true,
                paymentStatus = PaymentStatus.Loading,
                errorMessage = null
            )

            val amountCents = if (state.isMonthlySubscription) {
                null
            } else {
                (state.amount.toDoubleOrNull() ?: 0.0).times(100).toInt()
            }

            paymentRepository.createCheckoutSession(
                portalId = portalId,
                goalId = goalId,
                amount = amountCents,
                message = state.message.ifEmpty { null },
                transactionType = transactionType,
                isSubscription = state.isMonthlySubscription,
                priceId = if (state.isMonthlySubscription) state.selectedPriceId else null
            )
                .catch { e ->
                    _transactionState.value = _transactionState.value.copy(
                        isLoading = false,
                        paymentStatus = PaymentStatus.Failed("Network error: ${e.message}"),
                        errorMessage = "Network error: ${e.message}"
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { response ->
                            if (response.error != null) {
                                // Check if it's a payment setup error
                                val isPaymentSetupError = response.error.contains("Portal not set up", ignoreCase = true) ||
                                        response.error.contains("not fully onboarded", ignoreCase = true) ||
                                        response.error.contains("not activated", ignoreCase = true) ||
                                        response.error.contains("charges_enabled", ignoreCase = true) ||
                                        response.error.contains("transfers_enabled", ignoreCase = true) ||
                                        response.error.contains("missing the required capabilities", ignoreCase = true)

                                if (isPaymentSetupError) {
                                    _transactionState.value = _transactionState.value.copy(
                                        isLoading = false,
                                        showPaymentSetupAlert = true
                                    )
                                } else {
                                    _transactionState.value = _transactionState.value.copy(
                                        isLoading = false,
                                        paymentStatus = PaymentStatus.Failed(response.error),
                                        errorMessage = response.error
                                    )
                                }
                            } else if (response.checkout_url != null) {
                                _transactionState.value = _transactionState.value.copy(
                                    isLoading = false,
                                    showWebView = true,
                                    webViewUrl = response.checkout_url
                                )
                            } else {
                                _transactionState.value = _transactionState.value.copy(
                                    isLoading = false,
                                    paymentStatus = PaymentStatus.Failed("Failed to create checkout session"),
                                    errorMessage = "Failed to create checkout session"
                                )
                            }
                        },
                        onFailure = { e ->
                            _transactionState.value = _transactionState.value.copy(
                                isLoading = false,
                                paymentStatus = PaymentStatus.Failed(e.message ?: "Unknown error"),
                                errorMessage = e.message
                            )
                        }
                    )
                }
        }
    }

    fun handlePaymentCompleted(sessionId: String?) {
        if (sessionId != null) {
            checkPaymentStatus(sessionId)
        } else {
            // Payment completed without session ID
            _transactionState.value = _transactionState.value.copy(
                paymentStatus = PaymentStatus.Success,
                showSuccessBanner = true,
                showWebView = false
            )
        }
    }

    fun handlePaymentCanceled() {
        _transactionState.value = _transactionState.value.copy(
            paymentStatus = PaymentStatus.Failed("Payment was canceled or not completed"),
            errorMessage = "Payment was canceled or not completed",
            showWebView = false
        )
    }

    private fun checkPaymentStatus(sessionId: String) {
        viewModelScope.launch {
            paymentRepository.getCheckoutSessionStatus(sessionId)
                .catch { e ->
                    // On error, assume success if we got this far
                    _transactionState.value = _transactionState.value.copy(
                        paymentStatus = PaymentStatus.Success,
                        showSuccessBanner = true,
                        showWebView = false
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { statusResponse ->
                            if (statusResponse.payment_status == "paid") {
                                _transactionState.value = _transactionState.value.copy(
                                    paymentStatus = PaymentStatus.Success,
                                    showSuccessBanner = true,
                                    showWebView = false
                                )
                            } else {
                                _transactionState.value = _transactionState.value.copy(
                                    paymentStatus = PaymentStatus.Failed("Payment was not completed"),
                                    errorMessage = "Payment was not completed",
                                    showWebView = false
                                )
                            }
                        },
                        onFailure = { e ->
                            // Fallback: assume success
                            _transactionState.value = _transactionState.value.copy(
                                paymentStatus = PaymentStatus.Success,
                                showSuccessBanner = true,
                                showWebView = false
                            )
                        }
                    )
                }
        }
    }

    fun closeWebView() {
        _transactionState.value = _transactionState.value.copy(showWebView = false)
    }

    fun dismissSuccessBanner() {
        _transactionState.value = _transactionState.value.copy(showSuccessBanner = false)
    }

    fun dismissPaymentSetupAlert() {
        _transactionState.value = _transactionState.value.copy(showPaymentSetupAlert = false)
    }

    fun clearError() {
        _transactionState.value = _transactionState.value.copy(
            errorMessage = null,
            paymentStatus = PaymentStatus.Initial
        )
    }

    /**
     * Handle deep link return from Stripe payment
     * Called when app receives rep://payment-return?status=success or rep://payment-return?status=canceled
     */
    fun handlePaymentReturn(status: String?, sessionId: String? = null) {
        when (status) {
            "success" -> {
                handlePaymentCompleted(sessionId)
            }
            "canceled" -> {
                handlePaymentCanceled()
            }
            else -> {
                // Unknown status, close webview
                _transactionState.value = _transactionState.value.copy(
                    showWebView = false,
                    isLoading = false
                )
            }
        }
    }
}
