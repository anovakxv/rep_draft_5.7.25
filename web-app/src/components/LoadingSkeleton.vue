<template>
  <div class="animate-pulse">
    <!-- List Skeleton (for portals/people/chats) -->
    <div v-if="type === 'list'" class="space-y-4 p-4">
      <div v-for="i in count" :key="i" class="flex items-center space-x-4">
        <div :class="variant === 'circle' ? 'rounded-full' : 'rounded'" class="bg-gray-300" :style="{ width: size + 'px', height: size + 'px' }"></div>
        <div class="flex-1 space-y-2">
          <div class="h-4 bg-gray-300 rounded w-3/4"></div>
          <div class="h-3 bg-gray-200 rounded w-1/2"></div>
        </div>
      </div>
    </div>

    <!-- Card Skeleton (for portals in grid) -->
    <div v-else-if="type === 'card'" class="space-y-4 p-4">
      <div v-for="i in count" :key="i" class="p-4 border rounded-lg">
        <div class="bg-gray-300 h-48 rounded mb-4"></div>
        <div class="h-4 bg-gray-300 rounded w-3/4 mb-2"></div>
        <div class="h-3 bg-gray-200 rounded w-1/2"></div>
      </div>
    </div>

    <!-- Text Skeleton (for paragraphs) -->
    <div v-else-if="type === 'text'" class="space-y-2 p-4">
      <div v-for="i in count" :key="i" class="h-4 bg-gray-300 rounded" :style="{ width: (Math.random() * 30 + 60) + '%' }"></div>
    </div>

    <!-- Avatar Skeleton -->
    <div v-else-if="type === 'avatar'" class="bg-gray-300 rounded-full" :style="{ width: size + 'px', height: size + 'px' }"></div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  type?: 'list' | 'card' | 'text' | 'avatar';
  count?: number;
  size?: number;
  variant?: 'circle' | 'square';
}>();
</script>

<script lang="ts">
export default {
  name: 'LoadingSkeleton'
};
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>
