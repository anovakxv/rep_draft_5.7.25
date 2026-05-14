package com.networkedcapital.rep.presentation.auth

import android.util.Log
import android.util.Patterns
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.ui.text.font.FontWeight

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    onLoginSuccess: () -> Unit,
    onNavigateToSignUp: () -> Unit,
    onNavigateToForgotPassword: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val authState = viewModel.authState.collectAsState().value
    val focusManager = LocalFocusManager.current
    val coroutineScope = rememberCoroutineScope()
    var showAlert by remember { mutableStateOf(false) }

    // Define email and password as local state variables
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    // Navigate on successful login
    LaunchedEffect(authState.isLoggedIn) {
        val loggedIn = authState.isLoggedIn
        Log.d("LoginScreen", "state: isLoggedIn=$loggedIn, userId=${authState.userId}")
        if (loggedIn) {
            Log.d("LoginScreen", "navigating to Main")
            onLoginSuccess()
        }
    }

    // Show error message alert
    LaunchedEffect(authState.errorMessage) {
        if (authState.errorMessage != null) showAlert = true
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            verticalArrangement = Arrangement.Top,
            horizontalAlignment = Alignment.Start
        ) {
            // Header left-aligned
            Spacer(modifier = Modifier.height(24.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    horizontalAlignment = Alignment.Start
                ) {
                    Text(
                        "Welcome Back,",
                        fontSize = 32.sp,
                        color = Color.Black,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "Sign in to continue",
                        fontSize = 14.sp,
                        color = Color.Gray,
                        fontWeight = FontWeight.Normal
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
            }
            Spacer(modifier = Modifier.height(32.dp))
            // Email field
            StyledLoginTextField(
                placeholder = "Email",
                value = email,
                onValueChange = { email = it },
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next,
                onNext = { /* Optionally move focus to password */ }
            )
            Spacer(modifier = Modifier.height(24.dp))
            // Password field
            StyledLoginTextField(
                placeholder = "Password",
                value = password,
                onValueChange = { password = it },
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done,
                isPassword = true,
                onNext = { focusManager.clearFocus(); viewModel.login(email, password) }
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                Text(
                    text = "Forgot Password?",
                    color = Color(0xFF007AFF),
                    fontSize = 14.sp,
                    modifier = Modifier
                        .clickable { onNavigateToForgotPassword() }
                        .padding(8.dp)
                        .background(Color.Transparent)
                )
            }
            Spacer(modifier = Modifier.height(32.dp))
            // Login button prominent
            Button(
                onClick = { viewModel.login(email, password) },
                enabled = email.isNotBlank() && password.isNotBlank() && !authState.isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF30C053))
            ) {
                if (authState.isLoading) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Login", fontSize = 16.sp, color = Color.White, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.height(32.dp))
            // Centered sign up row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                Text("New?", fontSize = 16.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Sign Up",
                    color = Color(0xFF30C053),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .clickable { onNavigateToSignUp() }
                        .padding(4.dp)
                )
            }
        }
        if (showAlert && authState.errorMessage != null) {
            AlertDialog(
                onDismissRequest = { showAlert = false; viewModel.clearError() },
                confirmButton = {
                    TextButton(onClick = { showAlert = false; viewModel.clearError() }) {
                        Text("OK")
                    }
                },
                title = { Text("Error") },
                text = { Text(authState.errorMessage ?: "") }
            )
        }
    }
}

@Composable
fun StyledLoginTextField(
    placeholder: String,
    value: String,
    onValueChange: (String) -> Unit,
    keyboardType: KeyboardType,
    imeAction: ImeAction,
    isPassword: Boolean = false,
    onNext: () -> Unit = {}
) {
    val focusRequester = remember { FocusRequester() }
    var passwordVisible by remember { mutableStateOf(false) }
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(placeholder, color = Color(0xFF59595F), fontSize = 16.sp) },
        singleLine = true,
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFFF2F2F2), RoundedCornerShape(14.dp))
            .focusRequester(focusRequester),
        shape = RoundedCornerShape(14.dp),
        visualTransformation = if (isPassword && !passwordVisible) PasswordVisualTransformation() else VisualTransformation.None,
        keyboardOptions = KeyboardOptions(
            keyboardType = keyboardType,
            imeAction = imeAction,
            autoCorrect = false
        ),
        trailingIcon = if (isPassword) {
            {
                val icon = if (passwordVisible) Icons.Filled.VisibilityOff else Icons.Filled.Visibility
                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(imageVector = icon, contentDescription = null)
                }
            }
        } else null,
        keyboardActions = KeyboardActions(
            onDone = { onNext() },
            onNext = { onNext() }
        )
    )
}

// Example usage in your LoginScreen (for validation):
// if (Patterns.EMAIL_ADDRESS.matcher(email).matches()) { /* valid email */ }

// No extra dependency is needed for handling email as a String in Compose.
// If you want to use a third-party library for email validation, you can add it, but for most Android apps, android.util.Patterns is sufficient.
    


// Example usage in your LoginScreen (for validation):
// if (Patterns.EMAIL_ADDRESS.matcher(email).matches()) { /* valid email */ }

// No extra dependency is needed for handling email as a String in Compose.
// If you want to use a third-party library for email validation, you can add it, but for most Android apps, android.util.Patterns is sufficient.
