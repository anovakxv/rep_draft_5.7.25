<template>
  <div class="flex items-center justify-center my-4 md:my-6">
    <div class="flex-grow border-t border-gray-300"></div>
    <span class="px-4 text-xs md:text-sm text-gray-500 font-medium">{{ formattedDate }}</span>
    <div class="flex-grow border-t border-gray-300"></div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  timestamp: string;
}>();

const formattedDate = computed(() => {
  const date = new Date(props.timestamp);
  const now = new Date();
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);

  if (date.toDateString() === now.toDateString()) {
    return 'Today';
  } else if (date.toDateString() === yesterday.toDateString()) {
    return 'Yesterday';
  } else {
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }
});
</script>
