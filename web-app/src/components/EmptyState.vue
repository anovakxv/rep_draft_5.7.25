<template>
  <div class="flex flex-col items-center justify-center h-64 text-center p-8">
    <!-- Custom Icon Slot or Default -->
    <slot name="icon">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
      </svg>
    </slot>

    <!-- Title -->
    <h3 class="text-lg font-semibold text-gray-700 mb-2">{{ title || 'Nothing here yet' }}</h3>

    <!-- Description -->
    <p class="text-gray-500 mb-6 max-w-sm">{{ description || 'Get started by adding something new.' }}</p>

    <!-- Action Button (optional) -->
    <button
      v-if="actionText"
      @click="emit('action')"
      class="px-6 py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition"
    >
      {{ actionText }}
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  title?: string;
  description?: string;
  actionText?: string;
}>();

defineSlots<{
  icon?: () => any;
}>();

const emit = defineEmits(['action']);
</script>

<script lang="ts">
export default {
  name: 'EmptyState'
};
</script>
