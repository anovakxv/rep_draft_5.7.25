package com.networkedcapital.rep.data.api

import com.networkedcapital.rep.domain.model.*
import retrofit2.Response
import retrofit2.http.*

interface PaymentApiService {

    /**
     * Get user's active subscriptions
     * Endpoint: GET /api/subscriptions
     */
    @GET(ApiConfig.SUBSCRIPTIONS)
    suspend fun getSubscriptions(): Response<List<ActiveSubscription>>

    /**
     * Get user's payment history
     * Endpoint: GET /api/payment_history
     */
    @GET(ApiConfig.PAYMENT_HISTORY)
    suspend fun getPaymentHistory(): Response<List<TransactionHistoryItem>>

    /**
     * Cancel a subscription
     * Endpoint: POST /api/cancel_subscription
     */
    @POST(ApiConfig.CANCEL_SUBSCRIPTION)
    suspend fun cancelSubscription(
        @Body request: CancelSubscriptionRequest
    ): Response<Unit>

    /**
     * Create Stripe Customer Portal session
     * Endpoint: POST /api/create_customer_portal
     */
    @POST(ApiConfig.CREATE_CUSTOMER_PORTAL)
    suspend fun createCustomerPortal(
        @Body request: CustomerPortalRequest
    ): Response<CustomerPortalResponse>

    /**
     * Check portal's Stripe payment status
     * Endpoint: GET /api/portal/payment_status?portal_id={portalId}
     */
    @GET(ApiConfig.PORTAL_PAYMENT_STATUS)
    suspend fun getPortalPaymentStatus(
        @Query("portal_id") portalId: Int
    ): Response<PortalPaymentStatusResponse>

    /**
     * Create Stripe Connect account for portal
     * Endpoint: POST /api/create_connect_account
     */
    @POST(ApiConfig.CREATE_CONNECT_ACCOUNT)
    suspend fun createConnectAccount(
        @Body request: CreateConnectAccountRequest
    ): Response<CreateConnectAccountResponse>

    /**
     * Get Stripe Dashboard login link
     * Endpoint: POST /api/stripe_dashboard_link
     */
    @POST(ApiConfig.STRIPE_DASHBOARD_LINK)
    suspend fun getStripeDashboardLink(
        @Body request: StripeDashboardLinkRequest
    ): Response<StripeDashboardLinkResponse>

    /**
     * Create Stripe Checkout session
     * Endpoint: POST /api/create_checkout_session
     */
    @POST(ApiConfig.CREATE_CHECKOUT_SESSION)
    suspend fun createCheckoutSession(
        @Body request: CreateCheckoutSessionRequest
    ): Response<CreateCheckoutSessionResponse>

    /**
     * Check checkout session status
     * Endpoint: GET /api/checkout_session_status?session_id={sessionId}
     */
    @GET(ApiConfig.CHECKOUT_SESSION_STATUS)
    suspend fun getCheckoutSessionStatus(
        @Query("session_id") sessionId: String
    ): Response<CheckoutSessionStatusResponse>
}
