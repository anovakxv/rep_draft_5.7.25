<template>
  <div class="flex flex-col items-center justify-center h-full text-center p-8">
    <!-- Error Icon -->
    <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-red-500 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>

    <!-- Error Title -->
    <h3 class="text-xl font-bold text-gray-800 mb-2">{{ title || 'Something went wrong' }}</h3>

    <!-- Error Message -->
    <p class="text-gray-600 mb-6 max-w-md">{{ message || 'We encountered an error. Please try again.' }}</p>

    <!-- Retry Button -->
    <button
      v-if="showRetry"
      @click="emit('retry')"
      :disabled="retrying"
      class="px-6 py-3 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition disabled:opacity-60 flex items-center gap-2"
    >
      <span v-if="retrying" class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full"></span>
      {{ retrying ? 'Retrying...' : 'Try Again' }}
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  title?: string;
  message?: string;
  showRetry?: boolean;
  retrying?: boolean;
}>();

const emit = defineEmits(['retry']);
</script>

<script lang="ts">
export default {
  name: 'ErrorState'
};
</script>
