package com.networkedcapital.rep.presentation.payment

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.PaymentRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PortalPaymentSetupState(
    val isConnected: Boolean = false,
    val accountId: String? = null,
    val accountFullySetup: Boolean = false,
    val isRequestPending: Boolean = false,
    val pendingApprovalMessage: String? = null,
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val showWebView: Boolean = false,
    val webViewUrl: String? = null,
    val webViewTitle: String = ""
)

@HiltViewModel
class PortalPaymentSetupViewModel @Inject constructor(
    private val paymentRepository: PaymentRepository
) : ViewModel() {

    private val _setupState = MutableStateFlow(PortalPaymentSetupState())
    val setupState: StateFlow<PortalPaymentSetupState> = _setupState.asStateFlow()

    private var portalId: Int = 0
    private var portalName: String = ""

    fun initialize(portalId: Int, portalName: String) {
        this.portalId = portalId
        this.portalName = portalName
        checkConnectionStatus()
    }

    fun checkConnectionStatus() {
        viewModelScope.launch {
            _setupState.value = _setupState.value.copy(isLoading = true, errorMessage = null)

            paymentRepository.getPortalPaymentStatus(portalId)
                .catch { e ->
                    _setupState.value = _setupState.value.copy(
                        errorMessage = "Error checking payment status: ${e.message}",
                        isLoading = false
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { status ->
                            // Check for pending approval status
                            if (status.stripe_connect_requested == true) {
                                _setupState.value = _setupState.value.copy(
                                    isRequestPending = true,
                                    isConnected = false,
                                    accountFullySetup = false,
                                    pendingApprovalMessage = "Your Stripe Connect request is pending admin approval. You'll be notified when it's approved.",
                                    isLoading = false
                                )
                            } else if (!status.stripe_account_id.isNullOrEmpty()) {
                                _setupState.value = _setupState.value.copy(
                                    isConnected = true,
                                    accountId = status.stripe_account_id,
                                    accountFullySetup = status.account_status ?: false,
                                    isRequestPending = false,
                                    isLoading = false
                                )
                            } else {
                                _setupState.value = _setupState.value.copy(
                                    isConnected = false,
                                    accountFullySetup = false,
                                    isRequestPending = false,
                                    isLoading = false
                                )
                            }
                        },
                        onFailure = { e ->
                            _setupState.value = _setupState.value.copy(
                                errorMessage = "Error checking payment status: ${e.message}",
                                isLoading = false
                            )
                        }
                    )
                }
        }
    }

    fun createConnectAccount() {
        viewModelScope.launch {
            _setupState.value = _setupState.value.copy(isLoading = true, errorMessage = null)

            val redirectUrl = "rep://stripe-connect-return?portal_id=$portalId"

            paymentRepository.createConnectAccount(portalId, redirectUrl)
                .catch { e ->
                    _setupState.value = _setupState.value.copy(
                        errorMessage = "Error creating account: ${e.message}",
                        isLoading = false
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { response ->
                            // Check for pending approval status
                            if (response.status == "pending_approval") {
                                _setupState.value = _setupState.value.copy(
                                    isConnected = false,
                                    isRequestPending = true,
                                    accountFullySetup = false,
                                    pendingApprovalMessage = response.message,
                                    errorMessage = null,
                                    isLoading = false
                                )
                            } else if (response.url != null) {
                                // Success - show Stripe onboarding
                                _setupState.value = _setupState.value.copy(
                                    accountId = response.account_id,
                                    showWebView = true,
                                    webViewUrl = response.url,
                                    webViewTitle = "Stripe's Secure Website:",
                                    isLoading = false
                                )
                            } else if (response.error != null) {
                                _setupState.value = _setupState.value.copy(
                                    errorMessage = response.error,
                                    isLoading = false
                                )
                            } else {
                                _setupState.value = _setupState.value.copy(
                                    errorMessage = "Invalid response from server",
                                    isLoading = false
                                )
                            }
                        },
                        onFailure = { e ->
                            _setupState.value = _setupState.value.copy(
                                errorMessage = "Error creating account: ${e.message}",
                                isLoading = false
                            )
                        }
                    )
                }
        }
    }

    fun getStripeDashboardLink() {
        val accountId = _setupState.value.accountId
        if (accountId == null) {
            _setupState.value = _setupState.value.copy(errorMessage = "No Stripe account found")
            return
        }

        viewModelScope.launch {
            _setupState.value = _setupState.value.copy(isLoading = true, errorMessage = null)

            paymentRepository.getStripeDashboardLink(accountId)
                .catch { e ->
                    _setupState.value = _setupState.value.copy(
                        errorMessage = "Error getting dashboard link: ${e.message}",
                        isLoading = false
                    )
                }
                .collect { result ->
                    result.fold(
                        onSuccess = { dashboardUrl ->
                            _setupState.value = _setupState.value.copy(
                                showWebView = true,
                                webViewUrl = dashboardUrl,
                                webViewTitle = "Stripe's Secure Website:",
                                isLoading = false
                            )
                        },
                        onFailure = { e ->
                            // If dashboard link fails, try to complete onboarding
                            _setupState.value = _setupState.value.copy(
                                errorMessage = "Stripe error: ${e.message}\nPlease complete your Stripe setup.",
                                isLoading = false
                            )
                            createConnectAccount()
                        }
                    )
                }
        }
    }

    fun closeWebView() {
        _setupState.value = _setupState.value.copy(
            showWebView = false,
            webViewUrl = null
        )
        // Refresh connection status after closing web view
        checkConnectionStatus()
    }

    fun clearError() {
        _setupState.value = _setupState.value.copy(errorMessage = null)
    }

    /**
     * Handle deep link return from Stripe Connect onboarding
     * Called when app receives rep://stripe-connect-return
     */
    fun handleStripeConnectReturn() {
        // Close webview and refresh connection status
        _setupState.value = _setupState.value.copy(
            showWebView = false,
            webViewUrl = null
        )
        // Refresh to get updated connection status
        checkConnectionStatus()
    }
}
