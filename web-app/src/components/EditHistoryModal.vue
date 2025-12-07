<template>
  <Transition name="fade">
    <div v-if="show" @click="close" class="fixed inset-0 bg-black bg-opacity-40 z-50 flex items-center justify-center p-4">
      <div @click.stop class="bg-white rounded-lg shadow-2xl max-w-2xl w-full max-h-[80vh] flex flex-col overflow-hidden">
        <!-- Header -->
        <div class="px-5 py-4 border-b border-gray-200 flex items-center justify-between bg-gray-50">
          <div class="flex items-center gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div>
              <h3 class="font-semibold text-gray-900 text-lg">Edit History</h3>
              <p class="text-xs text-gray-500 mt-0.5">Changes made to this message</p>
            </div>
          </div>
          <button @click="close" class="text-gray-400 hover:text-gray-600 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Content -->
        <div class="flex-1 overflow-y-auto px-5 py-4">
          <div v-if="loading" class="flex items-center justify-center py-12">
            <div class="flex flex-col items-center gap-3">
              <div class="animate-spin h-8 w-8 border-3 border-gray-300 border-t-blue-600 rounded-full"></div>
              <p class="text-sm text-gray-500">Loading edit history...</p>
            </div>
          </div>

          <div v-else-if="error" class="flex items-center justify-center py-12">
            <div class="text-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-red-400 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p class="text-sm text-gray-600">Failed to load edit history</p>
              <button @click="$emit('retry')" class="mt-2 text-sm text-blue-600 hover:underline">
                Try again
              </button>
            </div>
          </div>

          <div v-else-if="!history || history.length === 0" class="flex items-center justify-center py-12">
            <div class="text-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-gray-300 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p class="text-sm text-gray-500">No edit history available</p>
            </div>
          </div>

          <!-- Timeline of Edits -->
          <div v-else class="space-y-4">
            <div
              v-for="(edit, index) in history"
              :key="edit.id"
              class="relative pl-8 pb-4 border-l-2"
              :class="index === 0 ? 'border-blue-400' : 'border-gray-300'"
            >
              <!-- Timeline Dot -->
              <div
                class="absolute -left-[9px] top-0 w-4 h-4 rounded-full border-2"
                :class="index === 0 ? 'bg-blue-500 border-blue-500' : 'bg-white border-gray-300'"
              ></div>

              <!-- Edit Content -->
              <div>
                <div class="flex items-center gap-2 mb-2">
                  <span
                    v-if="index === 0"
                    class="px-2 py-0.5 text-xs font-medium bg-blue-100 text-blue-700 rounded-full"
                  >
                    Current
                  </span>
                  <span
                    v-else-if="index === history.length - 1"
                    class="px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-600 rounded-full"
                  >
                    Original
                  </span>
                  <span class="text-xs text-gray-500">{{ formatTimestamp(edit.edited_at || edit.timestamp) }}</span>
                </div>

                <div
                  class="bg-gray-50 rounded-lg p-3 border"
                  :class="index === 0 ? 'border-blue-200 bg-blue-50' : 'border-gray-200'"
                >
                  <p class="text-sm text-gray-800 whitespace-pre-wrap break-words">{{ edit.text }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="px-5 py-3 bg-gray-50 border-t border-gray-200 flex justify-end">
          <button
            @click="close"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface EditHistoryEntry {
  id: number
  text: string
  edited_at?: string
  timestamp?: string
}

const props = defineProps<{
  show: boolean
  history: EditHistoryEntry[] | null
  loading?: boolean
  error?: boolean
}>()

const emit = defineEmits<{
  close: []
  retry: []
}>()

function close() {
  emit('close')
}

function formatTimestamp(timestamp: string) {
  const date = new Date(timestamp)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)

  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`

  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  })
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Custom scrollbar for better UX */
.overflow-y-auto {
  scrollbar-width: thin;
  scrollbar-color: #cbd5e0 #f7fafc;
}

.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: #f7fafc;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background-color: #cbd5e0;
  border-radius: 3px;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background-color: #a0aec0;
}
</style>
