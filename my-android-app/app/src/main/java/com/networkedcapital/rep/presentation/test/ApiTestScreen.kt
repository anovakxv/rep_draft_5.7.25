package com.networkedcapital.rep.presentation.test

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.networkedcapital.rep.presentation.auth.AuthViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ApiTestScreen(
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val authState by authViewModel.authState.collectAsState()
    val currentUser by authViewModel.currentUser.collectAsState()
    val context = LocalContext.current
    
    var testEmail by remember { mutableStateOf("test@example.com") }
    var testPassword by remember { mutableStateOf("password123") }
    var testFirstName by remember { mutableStateOf("John") }
    var testLastName by remember { mutableStateOf("Doe") }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "API Connection Test",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Connection Status",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Backend URL:")
                    Text("http://10.0.2.2:5000/")
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Status:")
                    Text(
                        text = if (authState.isLoading) "Testing..." else "Ready",
                        color = if (authState.isLoading) MaterialTheme.colorScheme.primary 
                               else MaterialTheme.colorScheme.onSurface
                    )
                }
                
                if (authState.errorMessage != null) {
                    Text(
                        text = "Error: ${authState.errorMessage}",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Test Authentication",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                OutlinedTextField(
                    value = testEmail,
                    onValueChange = { testEmail = it },
                    label = { Text("Email") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                OutlinedTextField(
                    value = testPassword,
                    onValueChange = { testPassword = it },
                    label = { Text("Password") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = {
                            authViewModel.login(testEmail, testPassword)
                        },
                        modifier = Modifier.weight(1f),
                        enabled = !authState.isLoading
                    ) {
                        Text("Test Login")
                    }
                    
                    OutlinedButton(
                        onClick = {
                            authViewModel.clearError()
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Clear")
                    }
                }
            }
        }
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Test Registration",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = testFirstName,
                        onValueChange = { testFirstName = it },
                        label = { Text("First Name") },
                        modifier = Modifier.weight(1f)
                    )
                    
                    OutlinedTextField(
                        value = testLastName,
                        onValueChange = { testLastName = it },
                        label = { Text("Last Name") },
                        modifier = Modifier.weight(1f)
                    )
                }
                
                Button(
                    onClick = {
                        authViewModel.register(
                            firstName = testFirstName,
                            lastName = testLastName,
                            email = testEmail,
                            password = testPassword,
                            userTypeId = 1 // Lead
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !authState.isLoading
                ) {
                    Text("Test Register")
                }
            }
        }
        
        if (currentUser != null) {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Current User",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    currentUser?.let { user ->
                        Text("ID: ${user.id}")
                        Text("Name: ${user.displayName}")
                        Text("Email: ${user.email}")
                        Text("User Type ID: ${user.users_types_id}")
                        if (user.manual_city != null) {
                            Text("City: ${user.manual_city}")
                        }
                    }
                    
                    Button(
                        onClick = {
                            authViewModel.logout()
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Logout")
                    }
                }
            }
        }
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Instructions",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Text(
                    text = """
                    1. Make sure your Flask backend is running on port 5000
                    2. Test login with existing user credentials
                    3. Try registering a new user
                    4. Check Flask console for incoming requests
                    5. Check Android logcat for detailed network logs
                    """.trimIndent(),
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}
