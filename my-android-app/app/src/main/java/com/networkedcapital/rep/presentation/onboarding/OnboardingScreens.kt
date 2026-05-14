package com.networkedcapital.rep.presentation.onboarding
import com.networkedcapital.rep.model.RepType
import com.networkedcapital.rep.model.RepSkill
import com.networkedcapital.rep.api.fetchSkills
import kotlinx.coroutines.launch

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import coil.compose.rememberAsyncImagePainter
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropUp
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.Image
import androidx.compose.foundation.border
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.zIndex
import android.util.Log
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import com.networkedcapital.rep.R

@Composable
fun TermsOfUseScreen(
    onAccept: () -> Unit,
    viewModel: com.networkedcapital.rep.presentation.auth.AuthViewModel = hiltViewModel()
) {
    Surface(
        color = com.networkedcapital.rep.presentation.theme.RepBackground,
        modifier = Modifier.fillMaxSize()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Terms of Use",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                color = com.networkedcapital.rep.presentation.theme.RepGreen
            )
            Spacer(modifier = Modifier.height(24.dp))
            Card(
                shape = MaterialTheme.shapes.medium,
                colors = CardDefaults.cardColors(containerColor = com.networkedcapital.rep.presentation.theme.RepLightGray),
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
            ) {
                Column(modifier = Modifier.verticalScroll(rememberScrollState()).padding(16.dp)) {
                    Text(
                        text = """
Terms of Use:  
Version: 1.1
Effective Date: 7/30/2025
App Name: Rep 1
Developer: Networked Capital Inc.

Welcome to Rep. By continuing, you agree to the following community guidelines and terms:

1. Community Standards
Users must not post objectionable, offensive, or abusive content.
Hate speech, harassment, and explicit material are strictly prohibited.
Violators may have their content removed and accounts suspended or banned.

2. User Responsibilities
You are solely responsible for the content you share, create, or promote.
Impersonation, deception, or targeted harassment is not tolerated.

3. Moderation & Enforcement
Rep reserves the right to monitor, moderate, and remove content at its discretion.
Inappropriate content can be flagged by users and reviewed by our team.
Users can block others to prevent unwanted or abusive interactions.

4. Removal of Objectionable Content    
We will review flagged content and remove content that violates this policy within 24 hours of the content being flagged. Users who repeatedly violate our content policy will be ejected from the platform. 

5. Intellectual Property
Rep and its underlying software, design, content, trademarks, logos, and features are the exclusive property of Networked Capital Inc., unless otherwise noted.
Users are not permitted to modify, reverse-engineer, reproduce, distribute, or exploit any part of the app or its codebase without prior written consent.
All feedback, suggestions, or feature ideas submitted by users may be used by Networked Capital Inc. to improve Rep, with no obligation of compensation unless explicitly agreed upon.
Unauthorized use of Rep’s intellectual property may result in termination of service and legal action.

6. Future Licensing
Certain components of Rep may, in the future, be released under an open-source license. However, until such licensing is explicitly announced and documented by Networked Capital Inc., all elements of the Rep software remain proprietary and fully protected under applicable intellectual property laws. Future licensing decisions will not retroactively affect ownership rights, nor shall they be construed as a waiver of any current protections.

7. Agreement
By using Rep, you acknowledge and agree to uphold these standards.
For questions, contact us via our website at:  https://networkedcapital.co/contact/

Before proceeding, you must confirm acceptance of these terms.
""",
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.Start,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
            Spacer(modifier = Modifier.height(16.dp))

            Surface(
                color = com.networkedcapital.rep.presentation.theme.RepBackground,
                modifier = Modifier.fillMaxWidth()
            ) {
                Button(
                    onClick = {
                        Log.d("TermsOfUseScreen", "Accept Terms button clicked")
                        viewModel.acceptTermsOfUse()
                        Log.d("TermsOfUseScreen", "Calling onAccept callback")
                        onAccept()
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = com.networkedcapital.rep.presentation.theme.RepGreen)
                ) {
                    Text("Accept Terms of Use", color = MaterialTheme.colorScheme.onPrimary)
                }
            }
        }
    }
}

@Composable
fun AboutRepScreen(
    onContinue: () -> Unit,
    viewModel: com.networkedcapital.rep.presentation.auth.AuthViewModel = hiltViewModel()
) {
    Surface(
        color = com.networkedcapital.rep.presentation.theme.RepBackground,
        modifier = Modifier.fillMaxSize()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "About Rep",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                color = com.networkedcapital.rep.presentation.theme.RepGreen
            )
            Spacer(modifier = Modifier.height(24.dp))
            Image(
                painter = painterResource(id = R.drawable.replogo),
                contentDescription = "Rep Logo",
                modifier = Modifier
                    .size(120.dp)
                    .align(Alignment.CenterHorizontally)
            )
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = "Rep is a platform for representatives to connect, set goals, and collaborate.\n\nRep empowers you to build your network, achieve your goals, and work together with other reps in a secure, supportive environment.",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            Spacer(modifier = Modifier.height(48.dp))
            Button(
                onClick = {
                    viewModel.continueAboutRep()
                    onContinue()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.buttonColors(containerColor = com.networkedcapital.rep.presentation.theme.RepGreen)
            ) {
                Text("Continue", color = MaterialTheme.colorScheme.onPrimary)
            }
        }
    }
}

@Composable
fun EditProfileScreen(
    onProfileSaved: () -> Unit,
    onBack: (() -> Unit)? = null,
    viewModel: com.networkedcapital.rep.presentation.auth.AuthViewModel = hiltViewModel()
) {
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var broadcast by remember { mutableStateOf("") }
    var city by remember { mutableStateOf("") }
    var about by remember { mutableStateOf("") }
    var otherSkill by remember { mutableStateOf("") }

    val authState = viewModel.authState.collectAsState().value
    val currentUser = viewModel.currentUser.collectAsState().value
    var repType by remember { mutableStateOf(RepType.LEAD) }
    val repTypes = RepType.values().toList()
    var allSkills by remember { mutableStateOf(listOf<RepSkill>()) }
    var selectedSkills by remember { mutableStateOf(setOf<RepSkill>()) }
    val coroutineScope = rememberCoroutineScope()

    // Fetch current user profile data and skills on first composition
    LaunchedEffect(Unit) {
        // Load current user into viewModel
        viewModel.loadCurrentUser()

        coroutineScope.launch {
            // Fetch skills
            val jwtToken = authState.jwtToken
            val skills = fetchSkills(jwtToken)
            if (skills.isNotEmpty()) {
                allSkills = skills
            } else {
                allSkills = RepSkill.values().toList()
            }
        }
    }

    // Pre-populate form when currentUser is loaded
    LaunchedEffect(currentUser) {
        if (currentUser != null) {
            firstName = currentUser.fname ?: ""
            lastName = currentUser.lname ?: ""
            email = currentUser.email ?: ""
            broadcast = currentUser.broadcast ?: ""
            city = currentUser.manual_city ?: currentUser.city ?: ""
            about = currentUser.about ?: ""
            otherSkill = currentUser.other_skill ?: ""

            // Set rep type (only LEAD and TEAM are supported)
            repType = when (currentUser.userType?.name ?: currentUser.userType_string) {
                "Team" -> RepType.TEAM
                else -> RepType.LEAD
            }

            // Pre-select user's skills
            val userSkillTitles = currentUser.skills ?: emptyList()
            selectedSkills = allSkills.filter { skill ->
                userSkillTitles.contains(skill.displayName)
            }.toSet()
        }
    }
    // Profile image upload
    var profileImageUri by remember { mutableStateOf<Uri?>(null) }
    val imagePickerLauncher = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        profileImageUri = uri
    }
    val isLoading = authState.isLoading
    val errorMessage = authState.errorMessage
    var saveError by remember { mutableStateOf<String?>(null) }
    // Use navigation from parent composable (RepNavigation)
    Surface(
        color = com.networkedcapital.rep.presentation.theme.RepBackground,
        modifier = Modifier.fillMaxSize()
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Back button at top left
            if (onBack != null) {
                IconButton(
                    onClick = onBack,
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(16.dp)
                        .zIndex(1f)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = Color.Black
                    )
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Edit Profile",
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = com.networkedcapital.rep.presentation.theme.RepGreen,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(20.dp))
                Card(
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = com.networkedcapital.rep.presentation.theme.RepLightGray),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp)
                    ) {
                        // Profile Image
                        Text("Profile Image", style = MaterialTheme.typography.titleMedium)
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Button(onClick = { imagePickerLauncher.launch("image/*") }) {
                                Text(if (profileImageUri != null) "Change Image" else "Upload Image")
                            }
                            if (profileImageUri != null) {
                                Spacer(modifier = Modifier.width(16.dp))
                                androidx.compose.foundation.Image(
                                    painter = coil.compose.rememberAsyncImagePainter(profileImageUri),
                                    contentDescription = "Profile Image",
                                    modifier = Modifier.size(64.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(18.dp))
                        // Name fields
                        Row(modifier = Modifier.fillMaxWidth()) {
                            OutlinedTextField(
                                value = firstName,
                                onValueChange = { firstName = it },
                                label = { Text("First Name") },
                                modifier = Modifier.weight(1f)
                            )
                            Spacer(modifier = Modifier.width(16.dp))
                            OutlinedTextField(
                                value = lastName,
                                onValueChange = { lastName = it },
                                label = { Text("Last Name") },
                                modifier = Modifier.weight(1f)
                            )
                        }
                        Spacer(modifier = Modifier.height(18.dp))
                        // Rep Type
                        Text("Type", style = MaterialTheme.typography.titleMedium)
                        var repTypeDropdownExpanded by remember { mutableStateOf(false) }
                        Box {
                            OutlinedTextField(
                                value = repType.displayName,
                                onValueChange = {},
                                label = { Text("Rep Type") },
                                readOnly = true,
                                trailingIcon = {
                                    IconButton(onClick = { repTypeDropdownExpanded = !repTypeDropdownExpanded }) {
                                        Icon(
                                            imageVector = if (repTypeDropdownExpanded) Icons.Filled.ArrowDropUp else Icons.Filled.ArrowDropDown,
                                            contentDescription = null
                                        )
                                    }
                                },
                                modifier = Modifier.fillMaxWidth()
                            )
                            DropdownMenu(
                                expanded = repTypeDropdownExpanded,
                                onDismissRequest = { repTypeDropdownExpanded = false },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                repTypes.forEach { type ->
                                    DropdownMenuItem(
                                        text = { Text(type.displayName) },
                                        onClick = {
                                            repType = type
                                            repTypeDropdownExpanded = false
                                        }
                                    )
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(18.dp))
                        // City
                        OutlinedTextField(
                            value = city,
                            onValueChange = { city = it },
                            label = { Text("City") },
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(18.dp))
                        // Skills
                        Text("Skills", style = MaterialTheme.typography.titleMedium)
                        // Scrollable skills box (displays ~10 skills at a time)
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .heightIn(max = 400.dp)
                                .border(1.dp, Color.Gray.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                                .padding(8.dp)
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .verticalScroll(rememberScrollState())
                            ) {
                                allSkills.forEach { skill ->
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Checkbox(
                                            checked = selectedSkills.contains(skill),
                                            onCheckedChange = { checked ->
                                                selectedSkills = if (checked) selectedSkills + skill else selectedSkills - skill
                                            }
                                        )
                                        Text(skill.displayName)
                                    }
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(18.dp))
                        // About
                        OutlinedTextField(
                            value = about,
                            onValueChange = { about = it },
                            label = { Text("About") },
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(18.dp))
                        // Broadcast
                        OutlinedTextField(
                            value = broadcast,
                            onValueChange = { broadcast = it },
                            label = { Text("Broadcast") },
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(18.dp))
                        // Other Skill
                        OutlinedTextField(
                            value = otherSkill,
                            onValueChange = { otherSkill = it },
                            label = { Text("Other Skill") },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
                Spacer(modifier = Modifier.height(28.dp))
                Button(
                    onClick = {
                        Log.d("EditProfileScreen", "Save button clicked")
                        viewModel.saveProfile(
                            firstName,
                            lastName,
                            email,
                            broadcast,
                            repType.displayName,
                            city,
                            about,
                            otherSkill,
                            selectedSkills.map { it.displayName }.toSet(),
                            profileImageUri?.toString(),
                            onSuccess = {
                                Log.d("EditProfileScreen", "onSuccess callback triggered")
                                saveError = null
                                onProfileSaved()
                            },
                            onError = { msg ->
                                Log.d("EditProfileScreen", "onError callback triggered: $msg")
                                saveError = msg
                            }
                        )
                    },
                    enabled = !isLoading,
                    colors = ButtonDefaults.buttonColors(containerColor = com.networkedcapital.rep.presentation.theme.RepGreen),
                    modifier = Modifier
                        .height(48.dp)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                ) {
                    Text("Save", color = MaterialTheme.colorScheme.onPrimary, style = MaterialTheme.typography.titleMedium)
                }
                if (isLoading) {
                    Spacer(modifier = Modifier.height(16.dp))
                    CircularProgressIndicator()
                }
                if (errorMessage != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(text = errorMessage ?: "", color = MaterialTheme.colorScheme.error)
                }
                if (saveError != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(text = saveError ?: "", color = MaterialTheme.colorScheme.error)
                }
            }
        }
    }
}

@Composable
fun OnboardingFlowEntry(
    navController: androidx.navigation.NavHostController,
    viewModel: com.networkedcapital.rep.presentation.auth.AuthViewModel = hiltViewModel()
) {
    // Remove local step-based navigation, rely on RepNavigation
    // ...existing code...
}

@Composable
fun AppWalkthroughScreen(onFinish: () -> Unit) {
    // UI for 4-5 walkthrough screens, similar to Swift's AppWalkthroughView
    // Use a pager (e.g., Accompanist Pager) for swipeable screens
    // For brevity, show a single screen and a finish button
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Welcome to Rep – our Purpose-Driven movement.", fontWeight = FontWeight.Bold, fontSize = MaterialTheme.typography.headlineMedium.fontSize)
        Spacer(modifier = Modifier.height(16.dp))
        Text("Rep helps you champion your priorities—like a world-class sales rep. Let's accelerate.", textAlign = TextAlign.Center)
        Spacer(modifier = Modifier.height(32.dp))
        Button(onClick = onFinish, modifier = Modifier.fillMaxWidth().height(56.dp)) {
            Text("Finish Walkthrough", color = MaterialTheme.colorScheme.onPrimary)
        }
    }
}
