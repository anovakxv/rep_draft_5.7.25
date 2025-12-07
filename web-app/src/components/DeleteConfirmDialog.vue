<template>
  <Transition name="fade">
    <div v-if="show" @click="close" class="fixed inset-0 bg-black bg-opacity-40 z-50 flex items-center justify-center p-4">
      <div @click.stop class="bg-white rounded-lg shadow-2xl max-w-sm w-full overflow-hidden">
        <!-- Header -->
        <div class="bg-red-50 px-5 py-4 border-b border-red-100">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 text-lg">Delete Message</h3>
              <p class="text-sm text-gray-600 mt-0.5">This action cannot be undone</p>
            </div>
          </div>
        </div>

        <!-- Body -->
        <div class="px-5 py-4">
          <p class="text-gray-700 text-sm leading-relaxed">
            Are you sure you want to delete this message? The message will be removed from the conversation for everyone.
          </p>
        </div>

        <!-- Actions -->
        <div class="px-5 py-4 bg-gray-50 flex gap-3 justify-end">
          <button
            @click="close"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            @click="confirm"
            class="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors"
          >
            Delete Message
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
defineProps<{
  show: boolean
}>()

const emit = defineEmits<{
  close: []
  confirm: []
}>()

function close() {
  emit('close')
}

function confirm() {
  emit('confirm')
  emit('close')
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
</style>
