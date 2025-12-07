<!--
  Chat_Individual.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <div class="flex flex-col flex-1 min-h-0">
      <!-- Header -->
      <div class="flex items-center h-14 px-4 border-b border-gray-200 shrink-0" style="background-color: #f7f7f7">
        <button @click="emit('close')" style="color: #8cc65d">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <h1 class="font-bold text-lg flex-1 text-center truncate">{{ otherUserName }}</h1>
        <div class="w-10"></div>
      </div>

      <!-- Messages List -->
      <div ref="scrollContainer" class="flex-1 overflow-y-auto px-3 py-3 pb-20" style="-webkit-overflow-scrolling: touch; overscroll-behavior-y: contain;" @scroll.passive="onScroll">
      <div v-if="canLoadOlder" class="flex justify-center py-2">
        <button @click="loadOlder" :disabled="isLoadingOlder" class="text-xs text-gray-500 hover:underline">
          <span v-if="isLoadingOlder" class="animate-spin h-4 w-4 border-2 border-gray-400 border-t-transparent rounded-full inline-block mr-1"></span>
          Load older messages
        </button>
      </div>
      <div v-for="msg in messages" :key="msg.id" class="mb-3">
        <MessageBubble
          :message="msg"
          :isCurrentUser="msg.sender_id === currentUserId"
          :profilePicURL="msg.sender_id === otherUserId ? otherUserPhotoURL : null"
          :editMode="editingMessageId === msg.id"
          @toggleReaction="handleToggleReaction"
          @showEmojiPicker="handleShowEmojiPicker"
          @startEdit="handleStartEdit"
          @saveEdit="handleSaveEdit"
          @cancelEdit="handleCancelEdit"
          @delete="handleDeleteMessage"
          @restore="handleRestoreMessage"
          @showEditHistory="handleShowEditHistory"
        />
      </div>
      <div v-if="isLoadingOlder" class="flex justify-center py-2">
        <span class="animate-spin h-5 w-5 border-2 border-gray-400 border-t-transparent rounded-full"></span>
      </div>
      <!-- Typing Indicator -->
      <div v-if="otherUserTyping" class="mb-3 flex items-center gap-2 text-gray-500 text-sm">
        <div class="flex gap-1">
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0ms;"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 150ms;"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 300ms;"></span>
        </div>
        <span>{{ otherUserName }} is typing...</span>
      </div>
    </div>

    <!-- Input Bar -->
    <div class="fixed bottom-0 left-0 right-0 z-20 flex justify-center">
      <div class="w-full border-t border-gray-200 bg-white px-3 py-2" style="max-width: 768px;">
        <div class="flex items-center gap-2">
          <textarea
            ref="textareaRef"
            v-model="inputText"
            @input="handleInputChange"
            @keydown="handleKeyDown"
            @keydown.enter.exact.prevent="!isDesktop && sendMessage()"
            :rows="isDesktop ? 2 : 1"
            class="flex-1 resize-none rounded-lg border border-gray-300 p-2 focus:outline-none focus:ring-2"
            :class="{ 'min-h-[44px]': isDesktop }"
            style="--tw-ring-color: #8cc65d; border-color: inherit;"
            :placeholder="isDesktop ? 'Type a message... (Shift+Enter for new line)' : 'Type a message...'"
            maxlength="5000"
            aria-label="Type a message"
          ></textarea>
          <button
            @click="sendMessage"
            :disabled="inputText.trim() === '' || isSending"
            class="text-white font-bold px-4 py-2 rounded-lg transition disabled:opacity-60"
            style="background-color: #8cc65d"
          >
            <span v-if="isSending" class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-2"></span>
            Send
          </button>
        </div>
      </div>
    </div>

    <!-- Emoji Picker Modal -->
    <EmojiPicker
      :show="showEmojiPicker"
      :messageId="selectedMessageIdForEmoji"
      @close="showEmojiPicker = false"
      @selectEmoji="handleSelectEmoji"
    />

    <!-- Delete Confirmation Dialog -->
    <DeleteConfirmDialog
      :show="showDeleteConfirm"
      @close="showDeleteConfirm = false"
      @confirm="confirmDelete"
    />

    <!-- Edit History Modal -->
    <EditHistoryModal
      :show="showEditHistory"
      :history="editHistory"
      :loading="editHistoryLoading"
      :error="editHistoryError"
      @close="showEditHistory = false"
      @retry="retryLoadHistory"
    />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, defineEmits } from 'vue';
import api from '@/pages/utils/api';
import MessageBubble from '@/components/MessageBubble.vue';
import EmojiPicker from '@/components/EmojiPicker.vue';
import DeleteConfirmDialog from '@/components/DeleteConfirmDialog.vue';
import EditHistoryModal from '@/components/EditHistoryModal.vue';

// --- Constants ---
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '';
const token = localStorage.getItem('jwtToken') || '';

// --- Props ---
const props = defineProps<{
  currentUserId: number;
  otherUserId: number;
  otherUserName: string;
  otherUserPhotoURL?: string;
}>();

const emit = defineEmits(['close', 'refresh-chats']);

// --- State ---
const messages = ref<SimpleMessage[]>([]);
const inputText = ref('');
const isSending = ref(false);
const isLoadingOlder = ref(false);
const canLoadOlder = ref(true);
const scrollContainer = ref<HTMLElement | null>(null);
const isTyping = ref(false);
const otherUserTyping = ref(false);
const isDesktop = ref(window.innerWidth >= 768);
const textareaRef = ref<HTMLTextAreaElement | null>(null);
let typingTimeout: ReturnType<typeof setTimeout> | null = null;
let observerId: string | null = null;

// Emoji picker state
const showEmojiPicker = ref(false);
const selectedMessageIdForEmoji = ref<number | null>(null);

// Edit state
const editingMessageId = ref<number | null>(null);
const editText = ref('');

// Delete confirmation state
const showDeleteConfirm = ref(false);
const messageToDelete = ref<number | null>(null);

// Edit history modal state
const showEditHistory = ref(false);
const editHistory = ref<any[] | null>(null);
const editHistoryLoading = ref(false);
const editHistoryError = ref(false);

interface MessageReaction {
  emoji: string;
  count: number;
  userReacted: boolean;
  users?: Array<{ user_id: number; user_name: string }>;
}

interface SimpleMessage {
  id: number;
  sender_id: number;  // Backend returns snake_case
  sender_name: string;  // Backend returns snake_case
  text: string;
  timestamp: string;
  read?: string;
  attachments?: Array<{
    url: string;
    type: 'image' | 'file';
    filename?: string;
  }>;
  reactions?: MessageReaction[];
  is_edited?: boolean;
  is_deleted?: boolean;
  edited_at?: string;
}

// --- Fetch Messages ---
async function fetchMessages(beforeId?: number, append = false) {
  if (append) {
    if (isLoadingOlder.value || !canLoadOlder.value) return;
    isLoadingOlder.value = true;
  }
  try {
    const params = new URLSearchParams({
      users_id: String(props.otherUserId),
      order: 'ASC',
      limit: '200',
      mark_as_read: append ? '0' : '1'
    });
    if (beforeId) params.append('before_id', String(beforeId));
    const res = await api.get(`/api/message/get_messages?${params.toString()}`);
    const newMsgs: SimpleMessage[] = res.data.result.messages;
    if (append) {
      if (newMsgs.length === 0) {
        canLoadOlder.value = false;
      } else {
        const existingIds = new Set(messages.value.map(m => m.id));
        const filtered = newMsgs.filter(m => !existingIds.has(m.id));
        messages.value = [...filtered, ...messages.value];
      }
      isLoadingOlder.value = false;
    } else {
      messages.value = newMsgs;
      canLoadOlder.value = true;
      emit('refresh-chats'); // Notify parent to refresh chat list
      nextTick(() => scrollToBottom());
    }
  } catch (e) {
    isLoadingOlder.value = false;
  }
}

// --- Load Older ---
function loadOlder() {
  if (messages.value.length > 0) {
    fetchMessages(messages.value[0].id, true);
  }
}

// --- Send Message ---
async function sendMessage() {
  const trimmed = inputText.value.trim();
  if (!trimmed || isSending.value) return;
  isSending.value = true;

  try {
    const res = await api.post('/api/message/send_message', {
      users_id: props.otherUserId,
      message: trimmed
    });
    const msg: SimpleMessage = res.data.message;
    appendIfNeeded(msg);

    inputText.value = '';
    stopTyping();

    // Reset textarea height on desktop after sending
    if (isDesktop.value && textareaRef.value) {
      textareaRef.value.style.height = 'auto';
    }

    nextTick(() => scrollToBottom());
  } catch (e) {
    console.error('Failed to send message:', e);
  } finally {
    isSending.value = false;
  }
}

// --- Typing Indicators ---
function handleInputChange() {
  if (!isTyping.value) {
    isTyping.value = true;
    emitTypingStatus(true);
  }

  if (typingTimeout) {
    clearTimeout(typingTimeout);
  }

  typingTimeout = setTimeout(() => {
    stopTyping();
  }, 3000);

  // Auto-resize textarea on desktop
  autoResizeTextarea();
}

function stopTyping() {
  if (isTyping.value) {
    isTyping.value = false;
    emitTypingStatus(false);
  }
  if (typingTimeout) {
    clearTimeout(typingTimeout);
    typingTimeout = null;
  }
}

function emitTypingStatus(typing: boolean) {
  if (window.RealtimeSocketManager) {
    window.RealtimeSocketManager.emitTyping({
      recipientId: props.otherUserId,
      isTyping: typing
    });
  }
}

// --- Desktop-specific Functions ---
function handleKeyDown(event: KeyboardEvent) {
  // Desktop: Enter sends, Shift+Enter adds newline
  // Mobile: Enter is handled by @keydown.enter.prevent on template
  if (isDesktop.value && event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    sendMessage();
  }
}

function autoResizeTextarea() {
  // Only auto-resize on desktop
  if (isDesktop.value && textareaRef.value) {
    textareaRef.value.style.height = 'auto';
    textareaRef.value.style.height = `${Math.min(textareaRef.value.scrollHeight, 180)}px`;
  }
}

function updateDesktopDetection() {
  isDesktop.value = window.innerWidth >= 768;
  // Reset textarea height when switching between mobile/desktop
  if (textareaRef.value) {
    if (isDesktop.value) {
      autoResizeTextarea();
    } else {
      textareaRef.value.style.height = 'auto';
    }
  }
}

// --- Real-time Socket Listener ---
function setupRealtimeListener() {
  if (window.RealtimeSocketManager) {
    observerId = window.RealtimeSocketManager.onDirectMessageNotification((payload: any) => {
      const senderId = payload.sender_id ?? payload.senderId;
      const recipientId = payload.recipient_id ?? payload.recipientId;
      if (senderId === props.otherUserId && recipientId === props.currentUserId) {
        if (payload.message) {
          appendIfNeeded(payload.message);
        } else if (payload.text) {
          appendIfNeeded({
            id: payload.id,
            sender_id: senderId,
            sender_name: payload.sender_name || payload.senderName || props.otherUserName,
            text: payload.text,
            timestamp: payload.timestamp,
            read: payload.read,
            attachments: payload.attachments
          });
        }
        emit('refresh-chats'); // Notify parent to refresh chat list
        nextTick(() => scrollToBottom());
      }
    });

    // Listen for typing events
    window.RealtimeSocketManager.onTypingNotification?.((payload: any) => {
      if (payload.senderId === props.otherUserId) {
        otherUserTyping.value = payload.isTyping;
      }
    });
  }
}

// --- Helpers ---
function appendIfNeeded(msg: SimpleMessage) {
  if (!messages.value.some(m => m.id === msg.id)) {
    messages.value.push(msg);
    messages.value.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
  }
}

function scrollToBottom(smooth = false) {
  if (scrollContainer.value) {
    // Use a small delay to ensure DOM has fully rendered
    setTimeout(() => {
      if (scrollContainer.value) {
        scrollContainer.value.scrollTo({
          top: scrollContainer.value.scrollHeight,
          behavior: smooth ? 'smooth' : 'auto'
        });
      }
    }, 50);
  }
}

// --- Scroll Event for Infinite Scroll ---
function onScroll() {
  if (!scrollContainer.value || isLoadingOlder.value || !canLoadOlder.value) return;
  if (scrollContainer.value.scrollTop < 60 && messages.value.length > 0) {
    loadOlder();
  }
}

// --- Reaction Handlers ---
async function handleToggleReaction(messageId: number, emoji: string) {
  try {
    const res = await api.post(`/api/message/toggle-reaction/${messageId}`, { emoji });

    // Update the message with new reactions data
    const messageIndex = messages.value.findIndex(m => m.id === messageId);
    if (messageIndex !== -1 && res.data.reactions) {
      messages.value[messageIndex].reactions = res.data.reactions;
    }
  } catch (e) {
    console.error('Failed to toggle reaction:', e);
  }
}

function handleShowEmojiPicker(messageId: number) {
  selectedMessageIdForEmoji.value = messageId;
  showEmojiPicker.value = true;
}

async function handleSelectEmoji(messageId: number, emoji: string) {
  showEmojiPicker.value = false;
  await handleToggleReaction(messageId, emoji);
}

// --- Edit Handlers ---
function handleStartEdit(message: SimpleMessage) {
  editingMessageId.value = message.id;
}

function handleCancelEdit() {
  editingMessageId.value = null;
}

async function handleSaveEdit(messageId: number, newText: string) {
  if (!newText.trim()) return;

  try {
    const res = await api.put(`/api/message/${messageId}`, {
      text: newText.trim()
    });

    // Update the message in the list
    const messageIndex = messages.value.findIndex(m => m.id === messageId);
    if (messageIndex !== -1) {
      messages.value[messageIndex].text = newText.trim();
      messages.value[messageIndex].is_edited = true;
      messages.value[messageIndex].edited_at = res.data.edited_at || new Date().toISOString();
    }

    editingMessageId.value = null;
  } catch (e) {
    console.error('Failed to edit message:', e);
  }
}

// --- Delete/Restore Handlers ---
function handleDeleteMessage(messageId: number) {
  messageToDelete.value = messageId;
  showDeleteConfirm.value = true;
}

async function confirmDelete() {
  if (messageToDelete.value === null) return;

  try {
    await api.delete(`/api/message/${messageToDelete.value}`);

    // Mark message as deleted in the list
    const messageIndex = messages.value.findIndex(m => m.id === messageToDelete.value);
    if (messageIndex !== -1) {
      messages.value[messageIndex].is_deleted = true;
    }

    messageToDelete.value = null;
  } catch (e) {
    console.error('Failed to delete message:', e);
  }
}

async function handleRestoreMessage(messageId: number) {
  try {
    await api.post(`/api/message/${messageId}/restore`);

    // Mark message as restored in the list
    const messageIndex = messages.value.findIndex(m => m.id === messageId);
    if (messageIndex !== -1) {
      messages.value[messageIndex].is_deleted = false;
    }
  } catch (e) {
    console.error('Failed to restore message:', e);
  }
}

// --- Edit History Handler ---
async function handleShowEditHistory(messageId: number) {
  showEditHistory.value = true;
  editHistoryLoading.value = true;
  editHistoryError.value = false;
  editHistory.value = null;

  try {
    const res = await api.get(`/api/message/${messageId}/history`);
    editHistory.value = res.data.history || [];
    editHistoryLoading.value = false;
  } catch (e) {
    console.error('Failed to load edit history:', e);
    editHistoryError.value = true;
    editHistoryLoading.value = false;
  }
}

function retryLoadHistory() {
  // Find the message ID from the current edit history context
  // For now, just close and user can try again
  editHistoryError.value = false;
}

// --- Lifecycle ---
onMounted(() => {
  // Optionally initialize socket connection if needed
  if (window.RealtimeSocketManager) {
    window.RealtimeSocketManager.connect(apiBaseUrl, token, props.currentUserId);
  }
  fetchMessages();
  setupRealtimeListener();

  // Add desktop detection listener
  window.addEventListener('resize', updateDesktopDetection);
});

onUnmounted(() => {
  if (observerId && window.RealtimeSocketManager) {
    window.RealtimeSocketManager.removeDirectMessageObserver(observerId);
  }

  // Remove desktop detection listener
  window.removeEventListener('resize', updateDesktopDetection);
});
</script>