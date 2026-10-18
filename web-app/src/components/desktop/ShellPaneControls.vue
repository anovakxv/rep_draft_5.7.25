<!--
  ShellPaneControls.vue
  Header buttons for the desktop Rolodex Shell's center pane:
  show/hide the context pane, and focus mode (hide both side panes).
-->

<template>
  <div class="flex items-center gap-0.5">
    <button
      v-if="!focusMode"
      type="button"
      class="w-9 h-9 rounded-lg flex items-center justify-center transition-colors"
      :class="contextOpen ? 'text-[#006600] bg-[#f3f9ee] hover:bg-[#e8f3df]' : 'text-gray-500 hover:bg-gray-100 hover:text-gray-800'"
      :aria-pressed="contextOpen"
      :title="contextOpen ? 'Hide details' : 'Show details'"
      :aria-label="contextOpen ? 'Hide details panel' : 'Show details panel'"
      @click="emit('toggle-context')"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
        <rect x="3" y="4" width="18" height="16" rx="2.5" />
        <path stroke-linecap="round" d="M15 4v16" />
      </svg>
    </button>
    <button
      type="button"
      class="w-9 h-9 rounded-lg flex items-center justify-center transition-colors"
      :class="focusMode ? 'text-[#006600] bg-[#f3f9ee] hover:bg-[#e8f3df]' : 'text-gray-500 hover:bg-gray-100 hover:text-gray-800'"
      :aria-pressed="focusMode"
      :title="focusMode ? 'Exit focus mode (Esc)' : 'Focus mode'"
      :aria-label="focusMode ? 'Exit focus mode' : 'Focus mode'"
      @click="emit('toggle-focus')"
    >
      <svg v-if="!focusMode" xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
        <path stroke-linecap="round" stroke-linejoin="round" d="M4 9V5a1 1 0 011-1h4M20 9V5a1 1 0 00-1-1h-4M4 15v4a1 1 0 001 1h4M20 15v4a1 1 0 01-1 1h-4" />
      </svg>
      <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
        <path stroke-linecap="round" stroke-linejoin="round" d="M9 4v4a1 1 0 01-1 1H4M15 4v4a1 1 0 001 1h4M9 20v-4a1 1 0 00-1-1H4M15 20v-4a1 1 0 011-1h4" />
      </svg>
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{ contextOpen: boolean; focusMode: boolean }>();
const emit = defineEmits<{ (e: 'toggle-context'): void; (e: 'toggle-focus'): void }>();
</script>
