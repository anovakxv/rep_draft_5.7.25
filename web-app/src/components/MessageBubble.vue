<template>
  <div class="flex group relative" :class="isCurrentUser ? 'justify-end' : 'justify-start'">
    <!-- Profile Picture (for other user) -->
    <img
      v-if="!isCurrentUser && profilePicURL && profilePicURL.trim()"
      :src="profilePicURL"
      class="w-8 h-8 md:w-10 md:h-10 rounded-full mr-2 mt-1 flex-shrink-0 object-cover"
      alt="Profile"
    />

    <div class="max-w-[70%] md:max-w-[60%] relative">
      <!-- Deleted Message Placeholder -->
      <div v-if="message.is_deleted" class="rounded-lg px-4 py-2 bg-gray-100 border border-gray-200 italic text-gray-500 text-sm">
        <span>This message was deleted</span>
        <button
          v-if="isCurrentUser"
          @click="$emit('restore', message.id)"
          class="ml-2 text-blue-600 hover:underline font-normal"
        >
          Undo
        </button>
      </div>

      <!-- Normal Message (not deleted) -->
      <div v-else>
        <!-- Edit Mode -->
        <div v-if="editMode" class="rounded-lg bg-white border-2 border-blue-400 p-3 shadow-lg">
          <textarea
            ref="editTextarea"
            v-model="localEditText"
            class="w-full p-2 border border-gray-300 rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-blue-400 text-sm"
            rows="3"
            maxlength="5000"
            @keydown.esc="$emit('cancelEdit')"
            @keydown.enter.meta.exact="saveEdit"
            @keydown.enter.ctrl.exact="saveEdit"
          ></textarea>
          <div class="flex justify-end gap-2 mt-2">
            <button
              @click="$emit('cancelEdit')"
              class="px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              @click="saveEdit"
              :disabled="!localEditText.trim() || localEditText === message.text"
              class="px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Save
            </button>
          </div>
        </div>

        <!-- Message Bubble (Normal View) -->
        <div
          v-else
          class="rounded-lg px-4 py-2 md:px-5 md:py-3 transition-all duration-200 relative select-none"
          :class="[
            isCurrentUser ? 'bg-black text-rep-green' : 'bg-gray-200 text-gray-800',
            longPressActive ? 'scale-95' : ''
          ]"
          @touchstart="handleTouchStart"
          @touchend="handleTouchEnd"
          @touchmove="handleTouchMove"
        >
          <!-- Attachments -->
          <div v-if="message.attachments && message.attachments.length > 0" class="mb-2 space-y-2">
            <div v-for="(attachment, index) in message.attachments" :key="index">
              <!-- Image Attachment -->
              <img
                v-if="attachment.type === 'image'"
                :src="attachment.url"
                :alt="attachment.filename || 'Image'"
                class="rounded-lg max-w-full h-auto cursor-pointer hover:opacity-90 transition-opacity"
                @click="openImageLightbox(attachment.url)"
              />
              <!-- File Attachment -->
              <a
                v-else
                :href="attachment.url"
                target="_blank"
                class="flex items-center gap-2 p-2 rounded-lg hover:opacity-80 transition-opacity"
                :class="isCurrentUser ? 'bg-gray-900' : 'bg-gray-300'"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clip-rule="evenodd" />
                </svg>
                <span class="text-sm truncate">{{ attachment.filename || 'File' }}</span>
              </a>
            </div>
          </div>

          <!-- Message Text with Link Detection -->
          <p v-if="message.text" class="text-sm md:text-[15px] break-words whitespace-pre-wrap leading-relaxed" v-html="formattedText"></p>

          <!-- Edited Badge -->
          <div v-if="message.is_edited" class="mt-1 text-xs opacity-60" :class="isCurrentUser ? 'text-rep-green' : 'text-gray-600'">
            (edited)
          </div>
        </div>

        <!-- Reactions Display -->
        <div v-if="hasReactions" class="flex flex-wrap gap-1 mt-1 px-1">
          <button
            v-for="reaction in groupedReactions"
            :key="reaction.emoji"
            @click="$emit('toggleReaction', message.id, reaction.emoji)"
            class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs transition-all hover:scale-110"
            :class="reaction.userReacted ? 'bg-blue-100 border border-blue-300' : 'bg-gray-100 border border-gray-200 hover:bg-gray-200'"
          >
            <span>{{ reaction.emoji }}</span>
            <span class="font-medium" :class="reaction.userReacted ? 'text-blue-700' : 'text-gray-700'">
              {{ reaction.count }}
            </span>
          </button>

          <!-- Add Reaction Button -->
          <button
            @click="$emit('showEmojiPicker', message.id)"
            class="inline-flex items-center px-2 py-0.5 rounded-full text-xs bg-gray-100 border border-gray-200 hover:bg-gray-200 transition-all"
            title="Add reaction"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </button>
        </div>

        <!-- Add Reaction Button (if no reactions yet) - Desktop only -->
        <button
          v-else
          @click="$emit('showEmojiPicker', message.id)"
          class="hidden md:block mt-1 px-1 opacity-0 group-hover:opacity-100 transition-opacity text-xs text-gray-500 hover:text-gray-700"
        >
          + Add reaction
        </button>

        <!-- Timestamp - Always visible on mobile, hover on desktop -->
        <div
          class="flex items-center gap-2 mt-1 px-1"
          :class="[
            isCurrentUser ? 'justify-end' : 'justify-start',
            'md:opacity-0 md:group-hover:opacity-100 md:transition-opacity'
          ]"
        >
          <span class="text-xs text-gray-500">{{ formattedTimestamp }}</span>
          <span v-if="message.is_edited" class="text-xs text-gray-500">(edited)</span>
        </div>
      </div>
    </div>

    <!-- Context Menu (appears on long press) -->
    <Teleport to="body">
      <div
        v-if="showContextMenu"
        class="fixed inset-0 z-50 flex items-end"
        @click="closeContextMenu"
      >
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black bg-opacity-30 backdrop-blur-sm"></div>

        <!-- Menu -->
        <div
          class="relative w-full bg-white rounded-t-3xl shadow-2xl animate-slide-up"
          @click.stop
        >
          <!-- Handle Bar -->
          <div class="flex justify-center pt-3 pb-2">
            <div class="w-12 h-1 bg-gray-300 rounded-full"></div>
          </div>

          <div class="px-4 pb-6 space-y-1">
            <!-- React Option -->
            <button
              @click="handleMenuAction('react')"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 active:bg-gray-100 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-yellow-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span class="text-base font-medium text-gray-900">Add Reaction</span>
            </button>

            <!-- Edit Option (only for current user) -->
            <button
              v-if="isCurrentUser"
              @click="handleMenuAction('edit')"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 active:bg-gray-100 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              <span class="text-base font-medium text-gray-900">Edit Message</span>
            </button>

            <!-- Delete Option (only for current user) -->
            <button
              v-if="isCurrentUser"
              @click="handleMenuAction('delete')"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-red-50 active:bg-red-100 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              <span class="text-base font-medium text-red-600">Delete Message</span>
            </button>

            <!-- Cancel -->
            <button
              @click="closeContextMenu"
              class="w-full flex items-center justify-center gap-3 px-4 py-3 mt-2 rounded-xl bg-gray-100 hover:bg-gray-200 active:bg-gray-300 transition-colors"
            >
              <span class="text-base font-semibold text-gray-700">Cancel</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch, nextTick } from 'vue'

interface MessageAttachment {
  url: string
  type: 'image' | 'file'
  filename?: string
}

interface MessageReaction {
  emoji: string
  count: number
  userReacted: boolean
  users?: Array<{ user_id: number; user_name: string }>
}

interface Message {
  id: number
  sender_id: number
  sender_name: string
  text: string
  timestamp: string
  read?: string
  attachments?: MessageAttachment[]
  reactions?: MessageReaction[]
  is_edited?: boolean
  is_deleted?: boolean
  edited_at?: string
}

const props = defineProps<{
  message: Message
  isCurrentUser: boolean
  profilePicURL?: string
  editMode?: boolean
  currentUserId?: number
}>()

const emit = defineEmits<{
  toggleReaction: [messageId: number, emoji: string]
  showEmojiPicker: [messageId: number]
  startEdit: [message: Message]
  saveEdit: [messageId: number, newText: string]
  cancelEdit: []
  delete: [messageId: number]
  restore: [messageId: number]
  showEditHistory: [messageId: number]
}>()

// Edit mode state
const localEditText = ref(props.message.text)
const editTextarea = ref<HTMLTextAreaElement | null>(null)

// Long press detection
const longPressTimer = ref<NodeJS.Timeout | null>(null)
const longPressActive = ref(false)
const showContextMenu = ref(false)
let touchStartX = 0
let touchStartY = 0

// Watch for editMode changes to focus textarea and reset text
watch(() => props.editMode, (newVal) => {
  if (newVal) {
    localEditText.value = props.message.text
    nextTick(() => {
      editTextarea.value?.focus()
      // Select all text for easy replacement
      editTextarea.value?.select()
    })
  }
})

function saveEdit() {
  if (localEditText.value.trim() && localEditText.value !== props.message.text) {
    emit('saveEdit', props.message.id, localEditText.value.trim())
  }
}

const formattedTimestamp = computed(() => {
  const date = new Date(props.message.timestamp)
  const now = new Date()
  const isToday = date.toDateString() === now.toDateString()

  if (isToday) {
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true })
  } else {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', hour12: true })
  }
})

// Link detection and formatting
const formattedText = computed(() => {
  if (!props.message.text) return ''

  const text = props.message.text
  const urlRegex = /(https?:\/\/[^\s]+)|(www\.[^\s]+)/gi

  // Escape HTML to prevent XSS
  const escapeHtml = (str: string) => {
    const div = document.createElement('div')
    div.textContent = str
    return div.innerHTML
  }

  const escapedText = escapeHtml(text)

  // Replace URLs with clickable links
  return escapedText.replace(urlRegex, (match) => {
    const href = match.startsWith('www.') ? `https://${match}` : match
    const linkClass = props.isCurrentUser ? 'text-white underline hover:text-gray-200' : 'text-blue-600 underline hover:text-blue-800'
    return `<a href="${href}" target="_blank" rel="noopener noreferrer" class="${linkClass}">${match}</a>`
  })
})

const hasReactions = computed(() => {
  return props.message.reactions && props.message.reactions.length > 0
})

const groupedReactions = computed(() => {
  return props.message.reactions || []
})

function openImageLightbox(url: string) {
  // For now, just open in new tab - can enhance with a proper lightbox later
  window.open(url, '_blank')
}

// Long press handlers for mobile context menu
function handleTouchStart(event: TouchEvent) {
  if (props.editMode) return // Don't trigger in edit mode

  const touch = event.touches[0]
  touchStartX = touch.clientX
  touchStartY = touch.clientY

  longPressActive.value = true

  // Trigger long press after 500ms
  longPressTimer.value = setTimeout(() => {
    showContextMenu.value = true
    // Add haptic feedback if available
    if (navigator.vibrate) {
      navigator.vibrate(50)
    }
  }, 500)
}

function handleTouchEnd() {
  if (longPressTimer.value) {
    clearTimeout(longPressTimer.value)
    longPressTimer.value = null
  }
  longPressActive.value = false
}

function handleTouchMove(event: TouchEvent) {
  // Cancel long press if user moves finger too much
  const touch = event.touches[0]
  const moveX = Math.abs(touch.clientX - touchStartX)
  const moveY = Math.abs(touch.clientY - touchStartY)

  if (moveX > 10 || moveY > 10) {
    if (longPressTimer.value) {
      clearTimeout(longPressTimer.value)
      longPressTimer.value = null
    }
    longPressActive.value = false
  }
}

function closeContextMenu() {
  showContextMenu.value = false
}

function handleMenuAction(action: 'react' | 'edit' | 'delete') {
  closeContextMenu()

  switch (action) {
    case 'react':
      emit('showEmojiPicker', props.message.id)
      break
    case 'edit':
      emit('startEdit', props.message)
      break
    case 'delete':
      emit('delete', props.message.id)
      break
  }
}
</script>

<style scoped>
.text-rep-green {
  color: #8cc65d;
}

/* Ensure links inside messages have proper styling */
:deep(a) {
  transition: color 0.15s ease;
  font-weight: 500;
}

/* Slide up animation for context menu */
@keyframes slide-up {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}

.animate-slide-up {
  animation: slide-up 0.3s ease-out;
}
</style>
