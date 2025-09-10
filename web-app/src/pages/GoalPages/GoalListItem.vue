<!--
  GoalListItem.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div
    class="flex items-center px-4 py-2 bg-white rounded-lg shadow-sm"
    style="height: 81px;"
    :aria-label="`Goal card for ${goal.title}`"
  >
    <!-- Bar Chart -->
    <div
      class="flex items-end"
      :style="`width: 114px; height: 81px; gap: 6px;`"
    >
      <div
        v-for="bar in lastFourBars"
        :key="bar.id"
        class="flex flex-col justify-end"
        style="width: 24px; height: 77px;"
      >
        <div
          :style="{
            height: `${barHeight(bar)}px`,
            backgroundColor: '#8cc65d',
            borderRadius: '3px',
            width: '24px'
          }"
        ></div>
      </div>
    </div>

    <!-- Goal Info -->
    <div class="flex flex-col justify-center flex-1 ml-4">
      <div class="font-bold text-base leading-tight truncate">{{ goal.title }}</div>
      <div v-if="goal.subtitle && goal.subtitle.trim() !== ''" class="text-sm text-gray-600 leading-tight truncate">
        {{ goal.subtitle }}
      </div>
      <div class="text-xs text-black font-medium">
        {{ Math.round(goal.progressPercent) }}% [{{ tagText }}]
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

interface BarChartData {
  id: number;
  value: number;
  valueLabel: string;
  bottomLabel: string;
}

interface Goal {
  id: number;
  title: string;
  subtitle: string;
  description: string;
  progress: number;
  progressPercent: number;
  quota: number;
  filledQuota: number;
  metricName: string;
  typeName: string;
  reportingName: string;
  quotaString: string;
  valueString: string;
  chartData: BarChartData[];
  creatorId: number;
  portalId?: number;
}

const props = defineProps<{ goal: Goal }>();

const lastFourBars = computed(() => {
  // SwiftUI uses .suffix(4)
  return props.goal.chartData.slice(-4);
});

function barHeight(bar: BarChartData) {
  const quota = props.goal.quota > 0 ? props.goal.quota : 1;
  // Swift: max(0, min(1.0, CGFloat(bar.value / quota)) * 77)
  const ratio = Math.max(0, Math.min(1.0, bar.value / quota));
  return ratio * 77;
}

const tagText = computed(() => {
  if (props.goal.typeName.toLowerCase() === 'other') {
    const raw = props.goal.metricName.trim();
    if (!raw) return props.goal.typeName;
    return raw.slice(0, 9);
  } else {
    return props.goal.typeName;
  }
});
</script>

<style scoped>
/* Card shadow and rounded corners for visual parity with SwiftUI */
div[aria-label] {
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(60,60,67,0.07);
}
</style>