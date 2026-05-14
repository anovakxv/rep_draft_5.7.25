package com.networkedcapital.rep.data.api

object ApiConfig {
    // For local development - update this to your Flask backend URL
    // Common local development URLs:
    // - "http://10.0.2.2:5000/" (Android emulator accessing host machine)
    // - "http://localhost:5000/" (if running on same machine)
    // - "http://192.168.1.xxx:5000/" (specific IP address)
    const val BASE_URL = "https://rep-june2025.onrender.com/"
    
    // Authentication endpoints - match Flask LoginActions.py
    const val LOGIN = "api/user/login"
    const val REGISTER = "api/user/register"
    const val LOGOUT = "api/user/logout"
    const val FORGOT_PASSWORD = "api/user/forgot_password"
    
    // Profile endpoints - match Flask user routes
    const val PROFILE = "api/user/profile"
    const val EDIT_PROFILE = "api/user/edit"
    const val DELETE_PROFILE = "api/user/delete"
    const val GET_ME = "api/user/me"
    
    // Portal endpoints - match Flask Portal_Routes
    const val PORTALS_LIST = "api/portal/portals"
    const val PORTALS_FILTER = "api/portal/filter_network_portals"
    const val PORTAL_DETAILS = "api/portal/details"
    const val PORTAL_CREATE = "api/portal/"
    const val PORTAL_EDIT = "api/portal/edit"
    const val PORTAL_DELETE = "api/portal/delete"
    
    // Goal endpoints - match Flask Goals_Routes
    const val GOALS_LIST = "api/goals/list"
    const val GOAL_DETAILS = "api/goals/details"
    const val GOAL_CREATE = "api/goals/create"
    const val GOAL_EDIT = "api/goals/edit"
    const val GOAL_DELETE = "api/goals/delete"
    const val GOAL_PROGRESS_UPDATE = "api/goals/progress"
    const val GOAL_TEAM_MANAGE = "api/goals/team"
    const val GOAL_JOIN_LEAVE = "api/goals/join_or_leave"
    const val GOAL_REPORTING_INCREMENTS = "api/goals/reporting_increments"
    
    // Messaging endpoints - match Flask Messaging_Routes
    const val MESSAGES_GET = "api/message/get_messages"
    const val MESSAGES_SEND = "api/message/send_direct_message"
    const val MESSAGES_DELETE = "api/message/delete"
    const val GROUP_CHAT_GET = "api/message/get_group_chat"
    const val GROUP_CHAT_SEND = "api/message/send_group_chat"
    
    // People endpoints - match Flask Get_People.py
    const val FILTER_PEOPLE = "api/filter_people"
    const val SEARCH_PEOPLE = "api/search_people"
    const val ACTIVE_CHAT_LIST = "api/active_chat_list"
    
    // Skills endpoints
    const val SKILLS_LIST = "api/user/skills"
    
    // Network endpoints
    const val NETWORK_ACTION = "api/user/network_action"
    const val BLOCK_USER = "api/user/block"
    const val UNBLOCK_USER = "api/user/unblock"
    const val FLAG_USER = "api/user/flag_user"

    // Payment & Stripe endpoints
    const val SUBSCRIPTIONS = "api/subscriptions"
    const val PAYMENT_HISTORY = "api/payment_history"
    const val CANCEL_SUBSCRIPTION = "api/cancel_subscription"
    const val CREATE_CUSTOMER_PORTAL = "api/create_customer_portal"
    const val PORTAL_PAYMENT_STATUS = "api/portal/payment_status"
    const val CREATE_CONNECT_ACCOUNT = "api/create_connect_account"
    const val STRIPE_DASHBOARD_LINK = "api/stripe_dashboard_link"
    const val CREATE_CHECKOUT_SESSION = "api/create_checkout_session"
    const val CHECKOUT_SESSION_STATUS = "api/checkout_session_status"

    // Team Invite endpoints
    const val PENDING_INVITES = "api/goals/pending_invites"
    const val GOAL_TEAM_RESPOND = "api/goals/{goalId}/team"
    const val MARK_INVITES_READ = "api/goals/pending_invites/mark_read"
}
