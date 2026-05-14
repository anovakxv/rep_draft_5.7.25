package com.networkedcapital.rep.presentation.portal

import android.content.Context
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import com.networkedcapital.rep.domain.model.PortalDetail
import com.networkedcapital.rep.domain.model.User

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditPortalScreen(
    portalDetail: PortalDetail?,
    userId: Int,
    onNavigateBack: () -> Unit,
    onNavigateToPortalDetail: (Int) -> Unit = {},
    onNavigateToPaymentSettings: (Int, String) -> Unit = { _, _ -> },
    viewModel: EditPortalViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showLeadsSheet by remember { mutableStateOf(false) }

    // Initialize with portal data
    LaunchedEffect(portalDetail) {
        portalDetail?.let {
            viewModel.initializeWithPortal(it)
            viewModel.loadNetworkMembers(userId)
        }
    }

    val isEdit = portalDetail != null && portalDetail.id != 0

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isEdit) "Edit Portal" else "Create Portal") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            viewModel.savePortal(
                                userId = userId,
                                portalId = portalDetail?.id ?: 0,
                                context = context,
                                onSuccess = { createdPortalId ->
                                    // Navigate to the created/edited portal detail screen
                                    onNavigateToPortalDetail(createdPortalId)
                                }
                            )
                        },
                        enabled = !uiState.isSaving && uiState.name.isNotBlank()
                    ) {
                        if (uiState.isSaving) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Save", color = Color(0xFF8CC55D))
                        }
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Images Section
            item {
                PortalImagesSection(
                    selectedImages = uiState.selectedImages,
                    mainImageIndex = uiState.mainImageIndex,
                    onImagesSelected = { uris ->
                        viewModel.addImages(uris, context)
                    },
                    onRemoveImage = { index ->
                        viewModel.removeImage(index)
                    },
                    onSetMainImage = { index ->
                        viewModel.setMainImageIndex(index)
                    }
                )
            }

            // Portal Info Section
            item {
                PortalInfoSection(
                    name = uiState.name,
                    subtitle = uiState.subtitle,
                    about = uiState.about,
                    onNameChange = viewModel::updateName,
                    onSubtitleChange = viewModel::updateSubtitle,
                    onAboutChange = viewModel::updateAbout
                )
            }

            // Leads Section
            item {
                PortalLeadsSection(
                    selectedLeads = uiState.selectedLeads,
                    onAddLeadsClick = { showLeadsSheet = true }
                )
            }

            // Payment Settings (only if user owns portal)
            if (isEdit && portalDetail?.usersId == userId) {
                item {
                    PaymentSettingsSection(
                        portalId = portalDetail?.id ?: 0,
                        portalName = uiState.name,
                        onNavigate = onNavigateToPaymentSettings
                    )
                }
            }

            // Story Blocks Editor
            item {
                PortalStoryBlocksEditor(
                    storyBlocks = uiState.storyBlocks,
                    onAddBlock = viewModel::addStoryBlock,
                    onUpdateBlock = viewModel::updateStoryBlock,
                    onDeleteBlock = viewModel::deleteStoryBlock
                )
            }

            // Delete Portal Button (only for existing portals)
            if (isEdit) {
                item {
                    Button(
                        onClick = { showDeleteDialog = true },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 16.dp)
                    ) {
                        Text("Delete Portal", fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Error message
            if (uiState.errorMessage != null) {
                item {
                    Text(
                        text = uiState.errorMessage!!,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }
            }
        }
    }

    // Leads Selection Sheet
    if (showLeadsSheet) {
        ModalBottomSheet(
            onDismissRequest = { showLeadsSheet = false }
        ) {
            LeadsSelectionSheet(
                networkMembers = uiState.networkMembers,
                selectedLeads = uiState.selectedLeads,
                isLoading = uiState.isLoadingMembers,
                onToggleLead = viewModel::toggleLeadSelection,
                onDismiss = { showLeadsSheet = false }
            )
        }
    }

    // Delete Confirmation Dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Portal?") },
            text = { Text("Are you sure you want to delete this portal? This cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        viewModel.deletePortal(
                            userId = userId,
                            portalId = portalDetail?.id ?: 0,
                            onSuccess = onNavigateBack
                        )
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun PortalImagesSection(
    selectedImages: List<android.graphics.Bitmap>,
    mainImageIndex: Int,
    onImagesSelected: (List<Uri>) -> Unit,
    onRemoveImage: (Int) -> Unit,
    onSetMainImage: (Int) -> Unit
) {
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        if (uris.isNotEmpty()) {
            onImagesSelected(uris)
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        TextButton(
            onClick = { imagePickerLauncher.launch("image/*") }
        ) {
            Icon(Icons.Default.Add, contentDescription = null)
            Spacer(Modifier.width(4.dp))
            Text(if (selectedImages.isEmpty()) "Add Images" else "Add More Images")
        }

        if (selectedImages.isNotEmpty()) {
            val pagerState = rememberPagerState(pageCount = { selectedImages.size })

            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
            ) { page ->
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .clickable { onSetMainImage(page) }
                ) {
                    Image(
                        bitmap = selectedImages[page].asImageBitmap(),
                        contentDescription = "Portal Image $page",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.LightGray, RoundedCornerShape(8.dp))
                    )

                    // Main Icon badge
                    if (page == 0) {
                        Text(
                            text = "Main Icon",
                            color = Color.White,
                            style = MaterialTheme.typography.labelSmall,
                            modifier = Modifier
                                .align(Alignment.TopStart)
                                .padding(8.dp)
                                .background(Color.Black.copy(alpha = 0.7f), RoundedCornerShape(4.dp))
                                .padding(horizontal = 6.dp, vertical = 3.dp)
                        )
                    }

                    // Remove button (can't remove main image)
                    if (page != 0) {
                        IconButton(
                            onClick = { onRemoveImage(page) },
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(8.dp)
                        ) {
                            Icon(
                                Icons.Default.Clear,
                                contentDescription = "Remove",
                                tint = Color.Red
                            )
                        }
                    }
                }
            }

            // Page indicator
            Row(
                Modifier
                    .wrapContentHeight()
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                horizontalArrangement = Arrangement.Center
            ) {
                repeat(selectedImages.size) { iteration ->
                    val color = if (pagerState.currentPage == iteration) MaterialTheme.colorScheme.primary else Color.LightGray
                    Box(
                        modifier = Modifier
                            .padding(2.dp)
                            .background(color, RoundedCornerShape(2.dp))
                            .size(8.dp)
                    )
                }
            }

            Text(
                text = "First image is used as Portal Icon",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp)
            )
        } else {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
                    .background(Color.LightGray.copy(alpha = 0.3f), RoundedCornerShape(8.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "No Images Selected",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun PortalInfoSection(
    name: String,
    subtitle: String,
    about: String,
    onNameChange: (String) -> Unit,
    onSubtitleChange: (String) -> Unit,
    onAboutChange: (String) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        OutlinedTextField(
            value = name,
            onValueChange = onNameChange,
            label = { Text("Portal Name") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = subtitle,
            onValueChange = onSubtitleChange,
            label = { Text("Subtitle") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = about,
            onValueChange = onAboutChange,
            label = { Text("About") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 3
        )
    }
}

@Composable
fun PortalLeadsSection(
    selectedLeads: List<User>,
    onAddLeadsClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onAddLeadsClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text("Add Leads", fontWeight = FontWeight.Medium)
                if (selectedLeads.isNotEmpty()) {
                    Text(
                        "${selectedLeads.size} selected",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null)
        }
    }
}

@Composable
fun PaymentSettingsSection(
    portalId: Int,
    portalName: String,
    onNavigate: (Int, String) -> Unit
) {
    HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = { onNavigate(portalId, portalName) }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.CreditCard,
                    contentDescription = null,
                    tint = Color(0xFF8CC55D),
                    modifier = Modifier.padding(end = 12.dp)
                )
                Text("Payment Settings", fontWeight = FontWeight.Medium)
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null)
        }
    }
}

@Composable
fun PortalStoryBlocksEditor(
    storyBlocks: List<PortalStoryBlock>,
    onAddBlock: (String, String) -> Unit,
    onUpdateBlock: (String, String, String) -> Unit,
    onDeleteBlock: (String) -> Unit
) {
    var editingBlock by remember { mutableStateOf<PortalStoryBlock?>(null) }
    var storyTitle by remember { mutableStateOf("") }
    var storyText by remember { mutableStateOf("") }
    var showDeleteDialog by remember { mutableStateOf<String?>(null) }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            "Story",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Medium
        )

        if (storyBlocks.isEmpty()) {
            Text(
                "No content yet.",
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        } else {
            storyBlocks.forEach { block ->
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        if (block.title.isNotBlank()) {
                            Text(
                                block.title,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Medium
                            )
                        }
                        Text(
                            block.content,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            TextButton(
                                onClick = {
                                    editingBlock = block
                                    storyTitle = block.title
                                    storyText = block.content
                                }
                            ) {
                                Text("Edit", color = Color.Blue)
                            }
                            TextButton(
                                onClick = { showDeleteDialog = block.id }
                            ) {
                                Text("Delete", color = MaterialTheme.colorScheme.error)
                            }
                        }
                    }
                }
            }
        }

        HorizontalDivider()

        Text(
            if (editingBlock == null) "Add new block:" else "Edit block:",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        OutlinedTextField(
            value = storyTitle,
            onValueChange = { storyTitle = it },
            label = { Text("Title") },
            modifier = Modifier.fillMaxWidth()
        )

        OutlinedTextField(
            value = storyText,
            onValueChange = { storyText = it },
            label = { Text("Content") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 4
        )

        Button(
            onClick = {
                if (editingBlock != null) {
                    onUpdateBlock(editingBlock!!.id, storyTitle, storyText)
                    editingBlock = null
                } else {
                    onAddBlock(storyTitle, storyText)
                }
                storyTitle = ""
                storyText = ""
            },
            enabled = storyText.isNotBlank(),
            modifier = Modifier.align(Alignment.CenterHorizontally)
        ) {
            Text(if (editingBlock == null) "Save" else "Update")
        }
    }

    // Delete confirmation dialog
    showDeleteDialog?.let { blockId ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("Delete Story Block") },
            text = { Text("Are you sure you want to delete this story block? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDeleteBlock(blockId)
                        showDeleteDialog = null
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun LeadsSelectionSheet(
    networkMembers: List<User>,
    selectedLeads: List<User>,
    isLoading: Boolean,
    onToggleLead: (User) -> Unit,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Select Leads",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            TextButton(onClick = onDismiss) {
                Text("Done")
            }
        }

        Spacer(Modifier.height(16.dp))

        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (networkMembers.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "No network members found",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.height(400.dp)
            ) {
                items(networkMembers) { user ->
                    val isSelected = selectedLeads.any { it.id == user.id }
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { onToggleLead(user) }
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(user.displayName)
                            if (isSelected) {
                                Icon(
                                    Icons.Default.Check,
                                    contentDescription = "Selected",
                                    tint = Color(0xFF8CC55D)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
