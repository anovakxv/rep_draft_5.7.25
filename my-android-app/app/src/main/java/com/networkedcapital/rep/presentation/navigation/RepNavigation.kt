package com.networkedcapital.rep.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import java.net.URLEncoder
import java.net.URLDecoder
import java.nio.charset.StandardCharsets
import com.networkedcapital.rep.presentation.auth.AuthViewModel
import com.networkedcapital.rep.presentation.auth.LoginScreen
import com.networkedcapital.rep.presentation.auth.RegisterScreen
import com.networkedcapital.rep.presentation.auth.ForgotPasswordScreen
import com.networkedcapital.rep.presentation.onboarding.TermsOfUseScreen
import com.networkedcapital.rep.presentation.onboarding.AboutRepScreen
import com.networkedcapital.rep.presentation.onboarding.EditProfileScreen
import com.networkedcapital.rep.presentation.main.MainScreen
import com.networkedcapital.rep.presentation.profile.ProfileScreen
import com.networkedcapital.rep.presentation.payment.PaymentsScreen
import com.networkedcapital.rep.presentation.payment.PayTransactionScreen
import com.networkedcapital.rep.presentation.payment.PortalPaymentSetupScreen
import com.networkedcapital.rep.presentation.invites.InvitesScreen
import com.networkedcapital.rep.presentation.settings.SettingsScreen
import com.networkedcapital.rep.presentation.portal.EditPortalScreen
import com.networkedcapital.rep.presentation.goals.EditGoalScreen
import com.networkedcapital.rep.presentation.goals.UpdateGoalScreen
import com.networkedcapital.rep.domain.model.TransactionType
import com.networkedcapital.rep.presentation.test.ApiTestScreen
import androidx.navigation.navArgument
import androidx.navigation.NavType

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RepNavigation(
    navController: NavHostController,
    authViewModel: AuthViewModel,
    modifier: Modifier = Modifier
) {
    val authState by authViewModel.authState.collectAsState()

    NavHost(
        navController = navController,
        startDestination = when {
            !authState.isRegistered -> Screen.Register.route
            !authState.onboardingComplete -> Screen.Onboarding.route
            authState.isLoggedIn && authState.userId > 0 -> Screen.Main.route
            else -> Screen.Login.route
        },
        modifier = modifier
    ) {
        composable(Screen.Register.route) {
            RegisterScreen(
                onNavigateToLogin = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Register.route) { inclusive = true }
                    }
                },
                onRegistrationSuccess = {
                    navController.navigate(Screen.EditProfile.route) {
                        popUpTo(Screen.Register.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Login.route) {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNavigateToSignUp = {
                    navController.navigate(Screen.Register.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNavigateToForgotPassword = {
                    navController.navigate(Screen.ForgotPassword.route)
                }
            )
        }

        composable(Screen.ForgotPassword.route) {
            ForgotPasswordScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.EditProfile.route) {
            EditProfileScreen(
                onProfileSaved = {
                    navController.navigate(Screen.Onboarding.route) {
                        popUpTo(Screen.EditProfile.route) { inclusive = true }
                    }
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.Onboarding.route) {
            TermsOfUseScreen(
                onAccept = {
                    navController.navigate(Screen.AboutRep.route) {
                        popUpTo(Screen.Onboarding.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.AboutRep.route) {
            AboutRepScreen(
                onContinue = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.AboutRep.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Main.route) {
            MainScreen(
                userId = authState.userId,
                jwtToken = authState.jwtToken,
                onNavigateToProfile = { userId ->
                    navController.navigate(Screen.Profile.createRoute(userId))
                },
                onNavigateToPortalDetail = { portalId ->
                    val userId = authState.userId
                    navController.navigate(Screen.PortalDetail.createRoute(portalId, userId))
                },
                onNavigateToPersonDetail = { personId ->
                    navController.navigate(Screen.Profile.createRoute(personId))
                },
                onNavigateToChat = { chat ->
                    // Differentiate between direct and group chats
                    if (chat is com.networkedcapital.rep.domain.model.ActiveChat) {
                        if (chat.type == "direct") {
                            // Navigate to individual chat with user info
                            navController.navigate(
                                Screen.IndividualChat.createRoute(
                                    chat.usersId ?: 0,
                                    chat.name,
                                    chat.profilePictureUrl
                                )
                            )
                        } else {
                            // Navigate to group chat
                            navController.navigate(
                                Screen.GroupChat.createRoute(chat.chatsId ?: 0)
                            )
                        }
                    }
                },
                onNavigateToAddPurpose = {
                    // Navigate to EditPortal with portalId = 0 for creating new portal
                    navController.navigate(Screen.EditPortal.createRoute(0))
                },
                onNavigateToCreateGroupChat = {
                    navController.navigate(Screen.CreateGroupChat.route)
                },
                onLogout = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        composable(
            route = Screen.Profile.route,
            arguments = listOf(
                navArgument("userId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val userId = backStackEntry.arguments?.getInt("userId")

            // Safety check - if userId is invalid, go back
            if (userId == null || userId <= 0) {
                android.util.Log.w("RepNavigation", "Invalid userId for ProfileScreen")
                LaunchedEffect(Unit) {
                    navController.popBackStack()
                }
                return@composable
            }

            ProfileScreen(
                userId = userId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToSettings = {
                    navController.navigate(Screen.Settings.route)
                },
                onNavigateToPortal = { portalId ->
                    // Navigate to EditPortal for creating/editing, PortalDetail for viewing
                    if (portalId == 0) {
                        navController.navigate(Screen.EditPortal.createRoute(0))
                    } else {
                        navController.navigate(Screen.PortalDetail.createRoute(portalId, authState.userId))
                    }
                },
                onNavigateToGoal = { goalId ->
                    // Navigate to EditGoal for creating/editing, GoalDetail for viewing
                    if (goalId == 0) {
                        navController.navigate(Screen.EditGoal.createRoute(0))
                    } else {
                        navController.navigate(Screen.GoalDetail.createRoute(goalId))
                    }
                },
                onNavigateToEditProfile = {
                    navController.navigate(Screen.EditProfile.route)
                },
                onNavigateToMessage = { userId, userName, userPhotoUrl ->
                    navController.navigate(Screen.IndividualChat.createRoute(userId, userName, userPhotoUrl))
                }
            )
        }

        composable(
            route = Screen.PortalDetail.route,
            arguments = listOf(
                navArgument("portalId") { type = NavType.IntType },
                navArgument("userId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val portalId = backStackEntry.arguments?.getInt("portalId")
            val userId = backStackEntry.arguments?.getInt("userId")

            // Safety check - if portalId is invalid, go back
            if (portalId == null || portalId <= 0) {
                android.util.Log.w("RepNavigation", "Invalid portalId for PortalDetailScreen")
                LaunchedEffect(Unit) {
                    navController.popBackStack()
                }
                return@composable
            }

            // Use provided userId or fall back to current user
            val finalUserId = if (userId != null && userId > 0) userId else authState.userId
            val viewModel: com.networkedcapital.rep.presentation.portal.PortalDetailViewModel = hiltViewModel()
            val uiState by viewModel.uiState.collectAsState()

            // Initialize data loading when screen first loads - THIS WAS MISSING!
            LaunchedEffect(portalId, finalUserId) {
                try {
                    viewModel.loadPortalDetail(portalId, finalUserId)
                } catch (e: Exception) {
                    android.util.Log.e("RepNavigation", "Error loading portal detail data", e)
                }
            }

            com.networkedcapital.rep.presentation.portal.PortalDetailScreen(
                uiState = uiState,
                userId = finalUserId,
                portalId = portalId,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToGoal = { goalId ->
                    navController.navigate(Screen.GoalDetail.createRoute(goalId))
                },
                onNavigateToEditGoal = { goalId, portalId ->
                    navController.navigate(Screen.EditGoal.createRoute(goalId ?: 0))
                },
                onNavigateToEditPortal = { portalId ->
                    navController.navigate(Screen.EditPortal.createRoute(portalId))
                },
                onMessage = { user ->
                    // Navigate to IndividualChatScreen
                    navController.navigate(
                        Screen.IndividualChat.createRoute(
                            user.id,
                            user.displayName,
                            user.profile_picture_url
                        )
                    )
                },
                viewModel = viewModel
            )
        }

        composable(Screen.ApiTest.route) {
            ApiTestScreen(
                authViewModel = authViewModel
            )
        }

        composable(
            route = Screen.GoalDetail.route,
            arguments = listOf(
                navArgument("goalId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val goalId = backStackEntry.arguments?.getInt("goalId")

            // Safety check - if goalId is invalid, go back
            if (goalId == null || goalId <= 0) {
                android.util.Log.w("RepNavigation", "Invalid goalId for GoalDetailScreen")
                LaunchedEffect(Unit) {
                    navController.popBackStack()
                }
                return@composable
            }

            com.networkedcapital.rep.presentation.goals.GoalsDetailScreen(
                goalId = goalId,
                onBack = { navController.popBackStack() },
                onMessage = { user ->
                    // Navigate to IndividualChatScreen
                    navController.navigate(
                        Screen.IndividualChat.createRoute(
                            user.id,
                            user.displayName,
                            user.profile_picture_url
                        )
                    )
                },
                onEditGoal = {
                    navController.navigate(Screen.EditGoal.createRoute(goalId))
                },
                onUpdateGoal = {
                    navController.navigate(Screen.UpdateGoal.createRoute(goalId))
                },
                onNavigateToPortal = { portalId ->
                    navController.navigate(Screen.PortalDetail.createRoute(portalId, authState.userId))
                },
                onNavigateToGroupChat = { chatId ->
                    navController.navigate(Screen.GroupChat.createRoute(chatId))
                }
            )
        }

        // Individual Chat Screen
        composable(
            route = Screen.IndividualChat.route,
            arguments = listOf(
                navArgument("chatId") { type = NavType.IntType },
                navArgument("userName") { type = NavType.StringType },
                navArgument("userPhotoUrl") {
                    type = NavType.StringType
                    nullable = true
                }
            )
        ) { backStackEntry ->
            val chatId = backStackEntry.arguments?.getInt("chatId")
            val userName = backStackEntry.arguments?.getString("userName")?.let {
                URLDecoder.decode(it, StandardCharsets.UTF_8.toString())
            } ?: "User"
            val userPhotoUrl = backStackEntry.arguments?.getString("userPhotoUrl")?.let {
                val decoded = URLDecoder.decode(it, StandardCharsets.UTF_8.toString())
                if (decoded == "null") null else decoded
            }

            // Safety check - if chatId is invalid, go back
            if (chatId == null || chatId <= 0) {
                android.util.Log.w("RepNavigation", "Invalid chatId for IndividualChatScreen")
                LaunchedEffect(Unit) {
                    navController.popBackStack()
                }
                return@composable
            }

            com.networkedcapital.rep.presentation.chat.IndividualChatScreen(
                chatId = chatId,
                userName = userName,
                userPhotoUrl = userPhotoUrl,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Group Chat Screen
        composable(
            route = Screen.GroupChat.route,
            arguments = listOf(
                navArgument("chatId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val chatId = backStackEntry.arguments?.getInt("chatId")

            // Safety check - if chatId is invalid, go back
            if (chatId == null || chatId <= 0) {
                android.util.Log.w("RepNavigation", "Invalid chatId for GroupChatScreen")
                LaunchedEffect(Unit) {
                    navController.popBackStack()
                }
                return@composable
            }

            com.networkedcapital.rep.presentation.chat.GroupChatScreen(
                chatId = chatId,
                currentUserId = authState.userId,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Create Group Chat Screen
        composable(Screen.CreateGroupChat.route) {
            com.networkedcapital.rep.presentation.chat.CreateGroupChatScreen(
                currentUserId = authState.userId,
                onNavigateToChat = { chatId ->
                    // Navigate to the newly created group chat
                    navController.navigate(Screen.GroupChat.createRoute(chatId)) {
                        // Remove CreateGroupChat from back stack
                        popUpTo(Screen.CreateGroupChat.route) { inclusive = true }
                    }
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Payments Screen
        composable(Screen.Payments.route) {
            PaymentsScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Pay Transaction Screen
        composable(
            route = Screen.PayTransaction.route,
            arguments = listOf(
                navArgument("portalId") { type = NavType.IntType },
                navArgument("portalName") { type = NavType.StringType },
                navArgument("goalId") { type = NavType.IntType },
                navArgument("goalName") { type = NavType.StringType },
                navArgument("transactionType") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val portalId = backStackEntry.arguments?.getInt("portalId") ?: 0
            val portalName = backStackEntry.arguments?.getString("portalName") ?: ""
            val goalId = backStackEntry.arguments?.getInt("goalId") ?: 0
            val goalName = backStackEntry.arguments?.getString("goalName") ?: ""
            val transactionTypeStr = backStackEntry.arguments?.getString("transactionType") ?: "DONATION"
            val transactionType = when (transactionTypeStr.uppercase()) {
                "PAYMENT" -> TransactionType.PAYMENT
                "PURCHASE" -> TransactionType.PURCHASE
                else -> TransactionType.DONATION
            }

            PayTransactionScreen(
                portalId = portalId,
                portalName = portalName,
                goalId = goalId,
                goalName = goalName,
                transactionType = transactionType,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onTransactionComplete = {
                    navController.popBackStack()
                }
            )
        }

        // Portal Payment Setup Screen
        composable(
            route = Screen.PortalPaymentSetup.route,
            arguments = listOf(
                navArgument("portalId") { type = NavType.IntType },
                navArgument("portalName") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val portalId = backStackEntry.arguments?.getInt("portalId") ?: 0
            val portalName = backStackEntry.arguments?.getString("portalName") ?: ""

            PortalPaymentSetupScreen(
                portalId = portalId,
                portalName = portalName,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Team Invites Screen
        composable(
            route = Screen.Invites.route,
            arguments = listOf(
                navArgument("userId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val userId = backStackEntry.arguments?.getInt("userId") ?: authState.userId

            InvitesScreen(
                userId = userId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onViewGoal = { goalId ->
                    navController.navigate(Screen.GoalDetail.createRoute(goalId))
                }
            )
        }

        // Settings Screen
        composable(Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToEditProfile = {
                    navController.navigate(Screen.EditProfile.route)
                },
                onNavigateToPayments = {
                    navController.navigate(Screen.Payments.route)
                },
                onNavigateToTerms = {
                    navController.navigate(Screen.Onboarding.route)
                },
                onLogout = {
                    authViewModel.logout()
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        // Edit Portal Screen
        composable(
            route = Screen.EditPortal.route,
            arguments = listOf(
                navArgument("portalId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val portalId = backStackEntry.arguments?.getInt("portalId") ?: 0
            // TODO: Load existing portal by portalId via ViewModel
            EditPortalScreen(
                portalDetail = null, // Will be loaded via ViewModel when portalId != 0
                userId = authState.userId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToPortalDetail = { createdPortalId ->
                    // Navigate to the newly created/edited portal detail screen
                    navController.navigate(Screen.PortalDetail.createRoute(createdPortalId, authState.userId)) {
                        // Remove EditPortal from back stack so back button goes to Main
                        popUpTo(Screen.EditPortal.route) { inclusive = true }
                    }
                },
                onNavigateToPaymentSettings = { portalId, portalName ->
                    navController.navigate(Screen.PortalPaymentSetup.createRoute(portalId, portalName))
                }
            )
        }

        // Edit Goal Screen
        composable(
            route = Screen.EditGoal.route,
            arguments = listOf(
                navArgument("goalId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val goalId = backStackEntry.arguments?.getInt("goalId") ?: 0
            // TODO: Load existing goal by goalId
            EditGoalScreen(
                existingGoal = null, // Will be loaded via ViewModel in future
                onSave = { goal ->
                    // TODO: Save goal via API
                    navController.popBackStack()
                },
                onCancel = {
                    navController.popBackStack()
                }
            )
        }

        // Update Goal Screen
        composable(
            route = Screen.UpdateGoal.route,
            arguments = listOf(
                navArgument("goalId") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val goalId = backStackEntry.arguments?.getInt("goalId") ?: 0
            // TODO: Load goal quota and metric by goalId
            UpdateGoalScreen(
                goalId = goalId,
                quota = 100.0, // TODO: Load from API
                metricName = "Units", // TODO: Load from API
                onSubmit = { addedValue, note ->
                    // TODO: Submit progress update via API
                    navController.popBackStack()
                },
                onCancel = {
                    navController.popBackStack()
                }
            )
        }
    }
}

sealed class Screen(val route: String) {
    object Register : Screen("register")
    object Login : Screen("login")
    object ForgotPassword : Screen("forgot_password")
    object Onboarding : Screen("onboarding")
    object AboutRep : Screen("about_rep")
    object EditProfile : Screen("edit_profile")
    object Main : Screen("main")
    object Profile : Screen("profile/{userId}") {
        fun createRoute(userId: Int) = "profile/$userId"
    }
    object PortalDetail : Screen("portal_detail/{portalId}/{userId}") {
        fun createRoute(portalId: Int, userId: Int) = "portal_detail/$portalId/$userId"
    }
    object GoalDetail : Screen("goal_detail/{goalId}") {
        fun createRoute(goalId: Int) = "goal_detail/$goalId"
    }
    object IndividualChat : Screen("individual_chat/{chatId}/{userName}/{userPhotoUrl}") {
        fun createRoute(chatId: Int, userName: String, userPhotoUrl: String?): String {
            val encodedUserName = URLEncoder.encode(userName, StandardCharsets.UTF_8.toString())
            val encodedPhotoUrl = URLEncoder.encode(userPhotoUrl ?: "null", StandardCharsets.UTF_8.toString())
            return "individual_chat/$chatId/$encodedUserName/$encodedPhotoUrl"
        }
    }
    object GroupChat : Screen("group_chat/{chatId}") {
        fun createRoute(chatId: Int) = "group_chat/$chatId"
    }
    object CreateGroupChat : Screen("create_group_chat")
    object ApiTest : Screen("api_test")

    // Payment & Subscription screens
    object Payments : Screen("payments")
    object PayTransaction : Screen("pay_transaction/{portalId}/{portalName}/{goalId}/{goalName}/{transactionType}") {
        fun createRoute(portalId: Int, portalName: String, goalId: Int, goalName: String, transactionType: String) =
            "pay_transaction/$portalId/$portalName/$goalId/$goalName/$transactionType"
    }
    object PortalPaymentSetup : Screen("portal_payment_setup/{portalId}/{portalName}") {
        fun createRoute(portalId: Int, portalName: String) = "portal_payment_setup/$portalId/$portalName"
    }

    // Team Invites screen
    object Invites : Screen("invites/{userId}") {
        fun createRoute(userId: Int) = "invites/$userId"
    }

    // Settings screen
    object Settings : Screen("settings")

    // Edit screens
    object EditPortal : Screen("edit_portal/{portalId}") {
        fun createRoute(portalId: Int) = "edit_portal/$portalId"
    }
    object EditGoal : Screen("edit_goal/{goalId}") {
        fun createRoute(goalId: Int) = "edit_goal/$goalId"
    }
    object UpdateGoal : Screen("update_goal/{goalId}") {
        fun createRoute(goalId: Int) = "update_goal/$goalId"
    }
}
