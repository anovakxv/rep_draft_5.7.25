package com.networkedcapital.rep.data.repository

import com.networkedcapital.rep.data.api.PaymentApiService
import com.networkedcapital.rep.domain.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PaymentRepository @Inject constructor(
    private val paymentApiService: PaymentApiService
) {

    /**
     * Fetch active subscriptions for the current user
     */
    suspend fun getSubscriptions(): Flow<Result<List<ActiveSubscription>>> = flow {
        try {
            val response = paymentApiService.getSubscriptions()
            if (response.isSuccessful) {
                val subscriptions = response.body()
                if (subscriptions != null) {
                    emit(Result.success(subscriptions))
                } else {
                    emit(Result.success(emptyList()))
                }
            } else {
                emit(Result.failure(Exception("Failed to fetch subscriptions: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Fetch payment history for the current user
     */
    suspend fun getPaymentHistory(): Flow<Result<List<TransactionHistoryItem>>> = flow {
        try {
            val response = paymentApiService.getPaymentHistory()
            if (response.isSuccessful) {
                val history = response.body()
                if (history != null) {
                    emit(Result.success(history))
                } else {
                    emit(Result.success(emptyList()))
                }
            } else {
                emit(Result.failure(Exception("Failed to fetch payment history: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Cancel a subscription
     */
    suspend fun cancelSubscription(subscriptionId: String): Flow<Result<Unit>> = flow {
        try {
            val response = paymentApiService.cancelSubscription(
                CancelSubscriptionRequest(subscriptionId)
            )
            if (response.isSuccessful) {
                emit(Result.success(Unit))
            } else {
                emit(Result.failure(Exception("Failed to cancel subscription: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Create Stripe Customer Portal session
     */
    suspend fun createCustomerPortal(returnUrl: String): Flow<Result<String>> = flow {
        try {
            val response = paymentApiService.createCustomerPortal(
                CustomerPortalRequest(returnUrl)
            )
            if (response.isSuccessful) {
                val portalResponse = response.body()
                if (portalResponse != null) {
                    emit(Result.success(portalResponse.url))
                } else {
                    emit(Result.failure(Exception("Invalid response from server")))
                }
            } else {
                emit(Result.failure(Exception("Failed to create customer portal: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Check portal's Stripe payment status
     */
    suspend fun getPortalPaymentStatus(portalId: Int): Flow<Result<PortalPaymentStatusResponse>> = flow {
        try {
            val response = paymentApiService.getPortalPaymentStatus(portalId)
            if (response.isSuccessful) {
                val status = response.body()
                if (status != null) {
                    emit(Result.success(status))
                } else {
                    emit(Result.failure(Exception("Invalid response from server")))
                }
            } else {
                emit(Result.failure(Exception("Failed to check payment status: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Create Stripe Connect account for portal
     */
    suspend fun createConnectAccount(
        portalId: Int,
        redirectUrl: String
    ): Flow<Result<CreateConnectAccountResponse>> = flow {
        try {
            val response = paymentApiService.createConnectAccount(
                CreateConnectAccountRequest(portalId, redirectUrl)
            )
            if (response.isSuccessful) {
                val connectResponse = response.body()
                if (connectResponse != null) {
                    emit(Result.success(connectResponse))
                } else {
                    emit(Result.failure(Exception("Invalid response from server")))
                }
            } else {
                emit(Result.failure(Exception("Failed to create connect account: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Get Stripe Dashboard login link
     */
    suspend fun getStripeDashboardLink(accountId: String): Flow<Result<String>> = flow {
        try {
            val response = paymentApiService.getStripeDashboardLink(
                StripeDashboardLinkRequest(accountId)
            )
            if (response.isSuccessful) {
                val dashboardResponse = response.body()
                if (dashboardResponse?.url != null) {
                    emit(Result.success(dashboardResponse.url))
                } else if (dashboardResponse?.error != null) {
                    emit(Result.failure(Exception(dashboardResponse.error)))
                } else {
                    emit(Result.failure(Exception("Invalid response from server")))
                }
            } else {
                emit(Result.failure(Exception("Failed to get dashboard link: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Create Stripe Checkout session for payment
     */
    suspend fun createCheckoutSession(
        portalId: Int,
        goalId: Int,
        amount: Int?,
        message: String?,
        transactionType: TransactionType,
        isSubscription: Boolean = false,
        priceId: String? = null
    ): Flow<Result<CreateCheckoutSessionResponse>> = flow {
        try {
            val request = CreateCheckoutSessionRequest(
                portal_id = portalId,
                goal_id = goalId,
                amount = amount,
                currency = "usd",
                message = message,
                transaction_type = transactionType.apiValue,
                is_subscription = isSubscription,
                price_id = priceId
            )
            val response = paymentApiService.createCheckoutSession(request)
            if (response.isSuccessful) {
                val checkoutResponse = response.body()
                if (checkoutResponse != null) {
                    emit(Result.success(checkoutResponse))
                } else {
                    emit(Result.failure(Exception("Invalid response from server")))
                }
            } else {
                emit(Result.failure(Exception("Failed to create checkout session: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Check checkout session payment status
     */
    suspend fun getCheckoutSessionStatus(sessionId: String): Flow<Result<CheckoutSessionStatusResponse>> = flow {
        try {
            val response = paymentApiService.getCheckoutSessionStatus(sessionId)
            if (response.isSuccessful) {
                val statusResponse = response.body()
                if (statusResponse != null) {
                    emit(Result.success(statusResponse))
                } else {
                    emit(Result.failure(Exception("Invalid response from server")))
                }
            } else {
                emit(Result.failure(Exception("Failed to check session status: ${response.message()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
}
