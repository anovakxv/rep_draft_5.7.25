package com.networkedcapital.rep.presentation.auth

import android.util.Patterns
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ForgotPasswordScreen(
    onNavigateBack: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val authState = viewModel.authState.collectAsState().value
    val focusManager = LocalFocusManager.current
    var email by remember { mutableStateOf("") }
    var showSuccessDialog by remember { mutableStateOf(false) }

    // Show success dialog when email is sent
    LaunchedEffect(authState.forgotPasswordSuccess) {
        if (authState.forgotPasswordSuccess != null) {
            showSuccessDialog = true
        }
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
            // Top bar with back button
            Spacer(modifier = Modifier.height(8.dp))
            IconButton(
                onClick = onNavigateBack,
                modifier = Modifier.size(40.dp)
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = Color.Black
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Header
            Text(
                "Forgot Password?",
                fontSize = 32.sp,
                color = Color.Black,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                "Enter your email address and we'll send you a link to reset your password on our website.",
                fontSize = 14.sp,
                color = Color.Gray,
                fontWeight = FontWeight.Normal,
                lineHeight = 20.sp
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Email field
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                placeholder = { Text("Email", color = Color(0xFF59595F), fontSize = 16.sp) },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFFF2F2F2), RoundedCornerShape(14.dp)),
                shape = RoundedCornerShape(14.dp),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Done,
                    autoCorrect = false
                ),
                keyboardActions = KeyboardActions(
                    onDone = {
                        focusManager.clearFocus()
                        if (isValidEmail(email)) {
                            viewModel.forgotPassword(email)
                        }
                    }
                )
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Send button
            Button(
                onClick = {
                    focusManager.clearFocus()
                    viewModel.forgotPassword(email)
                },
                enabled = isValidEmail(email) && !authState.isLoading,
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
                    Text(
                        "Send Reset Link",
                        fontSize = 16.sp,
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Error message
            if (authState.errorMessage != null) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFFFEBEE)),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = authState.errorMessage ?: "",
                        color = Color(0xFFC62828),
                        fontSize = 14.sp,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
        }

        // Success dialog
        if (showSuccessDialog) {
            AlertDialog(
                onDismissRequest = {
                    showSuccessDialog = false
                    viewModel.clearForgotPasswordSuccess()
                    onNavigateBack()
                },
                confirmButton = {
                    TextButton(onClick = {
                        showSuccessDialog = false
                        viewModel.clearForgotPasswordSuccess()
                        onNavigateBack()
                    }) {
                        Text("OK", color = Color(0xFF30C053), fontWeight = FontWeight.Bold)
                    }
                },
                title = {
                    Text(
                        "Check Your Email",
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp
                    )
                },
                text = {
                    Column {
                        Text(
                            authState.forgotPasswordSuccess ?: "",
                            fontSize = 16.sp,
                            lineHeight = 22.sp
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            "You can reset your password at www.repsomething.com",
                            fontSize = 14.sp,
                            color = Color.Gray,
                            lineHeight = 20.sp
                        )
                    }
                },
                shape = RoundedCornerShape(16.dp)
            )
        }
    }
}

private fun isValidEmail(email: String): Boolean {
    return email.isNotBlank() && Patterns.EMAIL_ADDRESS.matcher(email).matches()
}
