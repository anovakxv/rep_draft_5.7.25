package com.networkedcapital.rep.presentation.payment

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.PaymentRepository
import com.networkedcapital.rep.domain.model.ActiveSubscription
import com.networkedcapital.rep.domain.model.TransactionHistoryItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PaymentState(
    val subscriptions: List<ActiveSubscription> = emptyList(),
    val paymentHistory: List<TransactionHistoryItem> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val showWebView: Boolean = false,
    val webViewUrl: String? = null,
    val webViewTitle: String = ""
)

@HiltViewModel
class PaymentViewModel @Inject constructor(
    private val paymentRepository: PaymentRepository
) : ViewModel() {

    private val _paymentState = MutableStateFlow(PaymentState())
    val paymentState: StateFlow<PaymentState> = _paymentState.asStateFlow()

    init {
        loadPaymentData()
    }

    fun loadPaymentData() {
        viewModelScope.launch {
            _paymentState.value = _paymentState.value.copy(isLoading = true, errorMessage = null)

            // Load subscriptions
            paymentRepository.getSubscriptions()
                .catch { e ->
                    _paymentState.value = _paymentState.value.copy(
                        errorMessage = "Failed to load subscriptions: ${e.message}"
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { subscriptions ->
                            _paymentState.value = _paymentState.value.copy(
                                subscriptions = subscriptions
                            )
                        },
                        onFailure = { e ->
                            _paymentState.value = _paymentState.value.copy(
                                errorMessage = "Failed to load subscriptions: ${e.message}"
                            )
                        }
                    )
                }

            // Load payment history
            paymentRepository.getPaymentHistory()
                .catch { e ->
                    _paymentState.value = _paymentState.value.copy(
                        errorMessage = "Failed to load payment history: ${e.message}"
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { history ->
                            _paymentState.value = _paymentState.value.copy(
                                paymentHistory = history,
                                isLoading = false
                            )
                        },
                        onFailure = { e ->
                            _paymentState.value = _paymentState.value.copy(
                                errorMessage = "Failed to load payment history: ${e.message}",
                                isLoading = false
                            )
                        }
                    )
                }
        }
    }

    fun cancelSubscription(subscriptionId: String) {
        viewModelScope.launch {
            _paymentState.value = _paymentState.value.copy(isLoading = true, errorMessage = null)

            paymentRepository.cancelSubscription(subscriptionId)
                .catch { e ->
                    _paymentState.value = _paymentState.value.copy(
                        errorMessage = "Failed to cancel subscription: ${e.message}",
                        isLoading = false
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = {
                            // Remove subscription from list
                            val updatedSubscriptions = _paymentState.value.subscriptions
                                .filter { it.id != subscriptionId }
                            _paymentState.value = _paymentState.value.copy(
                                subscriptions = updatedSubscriptions,
                                isLoading = false
                            )
                        },
                        onFailure = { e ->
                            _paymentState.value = _paymentState.value.copy(
                                errorMessage = "Failed to cancel subscription: ${e.message}",
                                isLoading = false
                            )
                        }
                    )
                }
        }
    }

    fun openStripeCustomerPortal() {
        viewModelScope.launch {
            _paymentState.value = _paymentState.value.copy(isLoading = true, errorMessage = null)

            // Use app deep link for return URL
            val returnUrl = "rep://payment-settings-return"

            paymentRepository.createCustomerPortal(returnUrl)
                .catch { e ->
                    _paymentState.value = _paymentState.value.copy(
                        errorMessage = "Failed to open customer portal: ${e.message}",
                        isLoading = false
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { portalUrl ->
                            _paymentState.value = _paymentState.value.copy(
                                showWebView = true,
                                webViewUrl = portalUrl,
                                webViewTitle = "Stripe's Secure Website:",
                                isLoading = false
                            )
                        },
                        onFailure = { e ->
                            _paymentState.value = _paymentState.value.copy(
                                errorMessage = "Failed to open customer portal: ${e.message}",
                                isLoading = false
                            )
                        }
                    )
                }
        }
    }

    fun openStripeSupport() {
        _paymentState.value = _paymentState.value.copy(
            showWebView = true,
            webViewUrl = "https://support.stripe.com/",
            webViewTitle = "Stripe's Support Website:"
        )
    }

    fun closeWebView() {
        _paymentState.value = _paymentState.value.copy(
            showWebView = false,
            webViewUrl = null
        )
        // Reload payment data after closing web view (user may have updated payment methods)
        loadPaymentData()
    }

    fun clearError() {
        _paymentState.value = _paymentState.value.copy(errorMessage = null)
    }
}
