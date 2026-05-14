
package com.networkedcapital.rep.presentation.chat

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.networkedcapital.rep.domain.model.GroupMemberModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RemoveMembersScreen(
    members: List<GroupMemberModel>,
    currentUserId: Int,
    isCreator: Boolean,
    onRemoveMember: (GroupMemberModel) -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(max = 600.dp)  // Constrain height for bottom sheet
    ) {
        // Custom header instead of TopAppBar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onCancel) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Cancel",
                    tint = Color(0xFF8CC55D)
                )
            }
            Text(
                "Remove Member(s)",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.width(48.dp)) // Balance the close icon
        }

        HorizontalDivider()

        if (members.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No members to remove",
                    style = MaterialTheme.typography.bodyLarge,
                    color = Color.Gray
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(members.filter { 
                    // Filter out current user if not creator
                    if (!isCreator) it.id != currentUserId else true 
                }) { member ->
                    val canRemove = isCreator || member.id != currentUserId
                    
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(enabled = canRemove) {
                                if (canRemove) {
                                    // Show confirmation dialog
                                    onRemoveMember(member)
                                }
                            }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        MemberAvatar(
                            photoUrl = member.profilePictureUrl,
                            fullName = member.fullName,
                            size = 40.dp
                        )

                        Spacer(modifier = Modifier.width(12.dp))

                        Column(
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                text = member.fullName ?: "Unknown",
                                style = MaterialTheme.typography.bodyLarge,
                                color = Color.Red,
                                fontWeight = FontWeight.SemiBold
                            )
                            
                            Text(
                                text = "Tap to remove from group",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.Gray
                            )
                        }
                    }
                    
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 68.dp),
                        color = Color.LightGray.copy(alpha = 0.5f)
                    )
                }
            }
        }
    }
}

@Composable
fun RemoveMemberConfirmationDialog(
    member: GroupMemberModel,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Remove Member?") },
        text = {
            Text(
                "Are you sure you want to remove ${member.fullName} from this group?"
            )
        },
        confirmButton = {
            Button(
                onClick = onConfirm,
                colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
            ) {
                Text("Remove")
            }
        },
        dismissButton = {
            OutlinedButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
