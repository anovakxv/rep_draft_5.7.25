<template>
  <div class="flex items-center justify-between px-4 py-2 bg-gray-50 border-t border-gray-200 text-sm text-gray-600">
    <div class="flex items-center gap-6">
      <div class="flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <span><strong>{{ wordCount }}</strong> words</span>
      </div>

      <div class="flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>{{ readingTime }} min read</span>
      </div>

      <div class="flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
        </svg>
        <span>{{ characterCount }} characters</span>
      </div>
    </div>

    <!-- Auto-save indicator (desktop only) -->
    <div v-if="showAutoSave" class="hidden md:flex items-center gap-2">
      <div v-if="saveStatus === 'saving'" class="flex items-center gap-2 text-blue-600">
        <div class="animate-spin h-3 w-3 border-2 border-blue-600 border-t-transparent rounded-full"></div>
        <span class="text-xs">Saving...</span>
      </div>
      <div v-else-if="saveStatus === 'saved'" class="flex items-center gap-2 text-green-600">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <span class="text-xs">Saved</span>
      </div>
      <div v-else-if="saveStatus === 'error'" class="flex items-center gap-2 text-red-600">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span class="text-xs">Error</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  content: string;
  saveStatus?: 'idle' | 'saving' | 'saved' | 'error';
  showAutoSave?: boolean;
}>();

// Calculate word count (excluding HTML tags)
const wordCount = computed(() => {
  const text = stripHtml(props.content);
  const words = text.trim().split(/\s+/).filter(w => w.length > 0);
  return words.length;
});

// Calculate character count (excluding HTML tags)
const characterCount = computed(() => {
  const text = stripHtml(props.content);
  return text.length;
});

// Calculate estimated reading time (average 200 words per minute)
const readingTime = computed(() => {
  const wc = wordCount.value;
  const minutes = Math.ceil(wc / 200);
  return Math.max(1, minutes);
});

// Helper function to strip HTML tags
function stripHtml(html: string): string {
  const tmp = document.createElement('DIV');
  tmp.innerHTML = html;
  return tmp.textContent || tmp.innerText || '';
}
</script>
