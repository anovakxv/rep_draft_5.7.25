package com.networkedcapital.rep.presentation.goals

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.networkedcapital.rep.domain.model.Goal
import com.networkedcapital.rep.domain.model.BarChartData

@Composable
fun GoalListItem(
    goal: Goal,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 0.dp)
            .shadow(2.dp, RoundedCornerShape(12.dp))
            .background(Color.White, RoundedCornerShape(12.dp))
            .clickable { onClick() }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(81.dp)
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Bar Chart (matches iOS: 4 bars, 24dp width, 6dp spacing)
            MiniBarChart(
                data = goal.chartData.takeLast(4),
                quota = goal.quota,
                modifier = Modifier
                    .width((4 * 24 + 3 * 6).dp)
                    .height(81.dp)
                    .padding(vertical = 4.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp),
                horizontalAlignment = Alignment.Start
            ) {
                Text(
                    text = goal.title,
                    fontSize = 17.sp,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                    color = Color.Black
                )
                if (goal.subtitle.isNotBlank()) {
                    Text(
                        text = goal.subtitle,
                        fontSize = 15.sp,
                        color = Color.Gray,
                        fontWeight = androidx.compose.ui.text.font.FontWeight.Normal
                    )
                }
                // Tag text logic (matches iOS)
                val tagText = if (goal.typeName.lowercase() == "other") {
                    val raw = goal.metricName.trim()
                    if (raw.isNotEmpty()) raw.take(9) else goal.typeName
                } else {
                    goal.typeName
                }
                Text(
                    text = "${goal.progressPercent.toInt()}% [${tagText}]",
                    fontSize = 13.sp,
                    color = Color.Black,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
                )
            }
            Spacer(modifier = Modifier.width(8.dp))
        }
    }
}

@Composable
fun MiniBarChart(
    data: List<BarChartData>,
    quota: Double,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.Bottom
    ) {
        data.forEachIndexed { idx, bar ->
            val quotaValue = if (quota > 0) quota else 1.0
            val percent = (bar.value / quotaValue).coerceIn(0.0, 1.0)
            val barHeight = (percent * 77f).dp
            Box(
                modifier = Modifier
                    .width(24.dp)
                    .height(barHeight)
                    .background(Color(0xFF8CC55D), RoundedCornerShape(3.dp))
            )
            if (idx < data.lastIndex) Spacer(modifier = Modifier.width(6.dp))
        }
    }
}

// No changes needed. Use as GoalListItem in goals screens.
