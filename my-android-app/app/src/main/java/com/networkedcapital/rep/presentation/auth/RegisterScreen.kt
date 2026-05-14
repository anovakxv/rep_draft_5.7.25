package com.networkedcapital.rep.presentation.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.networkedcapital.rep.presentation.theme.RepGreen
import androidx.compose.ui.draw.shadow
import androidx.compose.foundation.border
import androidx.compose.ui.res.painterResource
import com.networkedcapital.rep.R


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegisterScreen(
    onNavigateToLogin: () -> Unit,
    onRegistrationSuccess: () -> Unit,
    viewModel: AuthViewModel = androidx.hilt.navigation.compose.hiltViewModel()
) {
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var confirmPasswordVisible by remember { mutableStateOf(false) }

    val authState by viewModel.authState.collectAsState()

    // Navigate on successful registration
        LaunchedEffect(authState.isRegistered, authState.onboardingComplete) {
            println("[RegisterScreen] LaunchedEffect triggered: isRegistered=${authState.isRegistered}, onboardingComplete=${authState.onboardingComplete}")
            if (authState.isRegistered && !authState.onboardingComplete) {
                println("[RegisterScreen] Triggering onRegistrationSuccess() navigation to onboarding.")
                onRegistrationSuccess()
            }
        }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .padding(bottom = 0.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Top
    ) {
        Spacer(modifier = Modifier.height(24.dp))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 24.dp)
        ) {
            Text(
                "Already have an account? :",
                fontSize = 16.sp,
                color = Color.Gray,
                fontFamily = androidx.compose.ui.text.font.FontFamily.SansSerif
            )
            Button(
                onClick = onNavigateToLogin,
                colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent),
                elevation = null,
                contentPadding = PaddingValues(0.dp),
                modifier = Modifier.height(60.dp)
            ) {
                Text(
                    "Login",
                    color = RepGreen,
                    fontWeight = FontWeight.Bold,
                    fontSize = 24.sp,
                    fontFamily = androidx.compose.ui.text.font.FontFamily.SansSerif,
                    modifier = Modifier.padding(horizontal = 24.dp)
                )
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        // REPLogo image as circle with shadow
        Box(
            modifier = Modifier
                .size(80.dp)
                .background(Color.White, shape = RoundedCornerShape(40.dp))
                .shadow(4.dp, shape = RoundedCornerShape(40.dp)),
            contentAlignment = Alignment.Center
        ) {
            androidx.compose.foundation.Image(
                painter = painterResource(id = com.networkedcapital.rep.R.drawable.replogo),
                contentDescription = "REP Logo",
                modifier = Modifier.size(64.dp)
            )
        }
        Spacer(modifier = Modifier.height(24.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.Start
        ) {
            Text(
                text = "Create Account:",
                fontWeight = FontWeight.Bold,
                color = Color(0xFF1A1C29),
                fontSize = 20.sp,
                fontFamily = androidx.compose.ui.text.font.FontFamily.SansSerif
            )
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StyledRegisterTextField(
                    value = firstName,
                    onValueChange = { firstName = it },
                    placeholder = "First Name",
                    modifier = Modifier.weight(1f)
                )
                StyledRegisterTextField(
                    value = lastName,
                    onValueChange = { lastName = it },
                    placeholder = "Last Name",
                    modifier = Modifier.weight(1f)
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Email:",
                fontWeight = FontWeight.Bold,
                color = Color(0xFF1A1C29),
                fontSize = 20.sp,
                fontFamily = androidx.compose.ui.text.font.FontFamily.SansSerif,
                modifier = Modifier.padding(top = 8.dp)
            )
            StyledRegisterTextField(
                value = email,
                onValueChange = { email = it },
                placeholder = "Email address",
                keyboardType = KeyboardType.Email,
                modifier = Modifier.fillMaxWidth()
            )
            StyledRegisterTextField(
                value = password,
                onValueChange = { password = it },
                placeholder = "Password",
                keyboardType = KeyboardType.Password,
                isPassword = true,
                passwordVisible = passwordVisible,
                onPasswordVisibilityChange = { passwordVisible = !passwordVisible },
                modifier = Modifier.fillMaxWidth()
            )
            StyledRegisterTextField(
                value = confirmPassword,
                onValueChange = { confirmPassword = it },
                placeholder = "Confirm Password",
                keyboardType = KeyboardType.Password,
                isPassword = true,
                passwordVisible = confirmPasswordVisible,
                onPasswordVisibilityChange = { confirmPasswordVisible = !confirmPasswordVisible },
                modifier = Modifier.fillMaxWidth()
            )
            StyledRegisterTextField(
                value = phone,
                onValueChange = { phone = it },
                placeholder = "Phone number (optional)",
                keyboardType = KeyboardType.Phone,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))
            authState.errorMessage?.let { error ->
                Text(
                    text = error,
                    color = Color.Red,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Normal,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }
            val isFormValid = firstName.isNotBlank() &&
                    lastName.isNotBlank() &&
                    email.isNotBlank() &&
                    password.isNotBlank() &&
                    password == confirmPassword &&
                    password.length >= 6
            Button(
                onClick = { viewModel.register(firstName, lastName, email, password, phone) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(64.dp),
                enabled = !authState.isLoading && isFormValid,
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = RepGreen)
            ) {
                if (authState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = Color.White
                    )
                } else {
                    Text(
                        "Next",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        fontFamily = androidx.compose.ui.text.font.FontFamily.SansSerif
                    )
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .width(134.dp)
                        .height(5.dp)
                        .background(Color.Black, RoundedCornerShape(100.dp))
                )
            }
            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}

@Composable
fun StyledRegisterTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    keyboardType: KeyboardType = KeyboardType.Text,
    isPassword: Boolean = false,
    passwordVisible: Boolean = false,
    onPasswordVisibilityChange: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = {
            Text(
                placeholder,
                color = Color(0xFF59595F),
                fontSize = 16.sp,
                fontFamily = androidx.compose.ui.text.font.FontFamily.SansSerif
            )
        },
        singleLine = true,
        modifier = modifier
            .background(Color(0xFFF2F2F2), RoundedCornerShape(14.dp))
            .border(
                width = 1.dp,
                color = RepGreen,
                shape = RoundedCornerShape(14.dp)
            ),
        shape = RoundedCornerShape(14.dp),
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
        visualTransformation = if (isPassword && !passwordVisible) PasswordVisualTransformation() else VisualTransformation.None,
        trailingIcon = if (isPassword && onPasswordVisibilityChange != null) {
            {
                IconButton(onClick = onPasswordVisibilityChange) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Filled.VisibilityOff else Icons.Filled.Visibility,
                        contentDescription = if (passwordVisible) "Hide password" else "Show password"
                    )
                }
            }
        } else null,
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = RepGreen,
            unfocusedBorderColor = RepGreen,
            cursorColor = Color.Black,
            focusedLabelColor = RepGreen
        ),
        textStyle = androidx.compose.ui.text.TextStyle(
            color = Color.Black,
            fontSize = 16.sp,
            fontFamily = androidx.compose.ui.text.font.FontFamily.SansSerif
        )
    )
}
