package com.networkedcapital.rep.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.networkedcapital.rep.domain.model.Goal

@Composable
fun GoalListItemComponent(
    goal: Goal,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() },
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Goal Info Column
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = goal.title,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                
                if (goal.subtitle.isNotBlank()) {
                    Text(
                        text = goal.subtitle,
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                // Progress information
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = if (goal.quotaString.isNotBlank()) {
                            goal.quotaString
                        } else {
                            "${goal.filledQuota.toInt()}/${goal.quota.toInt()} ${goal.metricName}"
                        },
                        fontSize = 12.sp,
                        color = Color(0xFF8CC55D),
                        fontWeight = FontWeight.Medium
                    )
                    
                    if (goal.progressPercent > 0) {
                        Text(
                            text = "${(goal.progressPercent * 100).toInt()}%",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Metric and reporting info
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (goal.typeName.isNotBlank()) {
                        Text(
                            text = goal.typeName,
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier
                                .background(
                                    MaterialTheme.colorScheme.surfaceVariant,
                                    RoundedCornerShape(4.dp)
                                )
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                    
                    if (goal.reportingName.isNotBlank()) {
                        Text(
                            text = goal.reportingName,
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier
                                .background(
                                    MaterialTheme.colorScheme.surfaceVariant,
                                    RoundedCornerShape(4.dp)
                                )
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Progress Chart
            BarChartView(
                progress = goal.progressPercent,
                filledQuota = goal.filledQuota,
                totalQuota = goal.quota,
                modifier = Modifier.size(width = 60.dp, height = 40.dp)
            )
        }
    }
}

@Composable
fun BarChartView(
    progress: Double,
    filledQuota: Double,
    totalQuota: Double,
    modifier: Modifier = Modifier
) {
    val progressHeight = if (totalQuota > 0) {
        (filledQuota / totalQuota).coerceIn(0.0, 1.0)
    } else {
        progress.coerceIn(0.0, 1.0)
    }

    Box(
        modifier = modifier,
        contentAlignment = Alignment.BottomCenter
    ) {
        // Background bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight()
                .background(
                    Color(0xFFE0E0E0),
                    RoundedCornerShape(2.dp)
                )
        )

        // Progress bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(progressHeight.toFloat())
                .background(
                    Color(0xFF8CC55D),
                    RoundedCornerShape(2.dp)
                )
        )
    }
}
