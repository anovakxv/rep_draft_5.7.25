<!--
  Chat_Individual.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white chat-individual-container">
    <!-- Header - Full Width -->
    <div class="flex items-center h-14 xl:h-12 px-4 border-b border-gray-200 shrink-0" style="background-color: #f7f7f7">
      <button @click="emit('close')" style="color: #8cc65d">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 xl:h-5 xl:w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h1 class="font-bold text-lg xl:text-sm xl:font-semibold flex-1 text-center truncate">{{ otherUserName }}</h1>
      <div class="w-10 xl:w-8"></div>
    </div>

    <!-- Two Column Layout (Desktop) / Single Column (Mobile) -->
    <div class="flex flex-col flex-1 min-h-0 xl:flex-row">
      <!-- LEFT COLUMN (Desktop): Compose Panel (50% width) — email-style -->
      <div class="hidden xl:flex xl:flex-col xl:w-[50%] xl:border-r xl:border-gray-200" style="background:#f9fafb">

        <!-- Compose header: "To:" recipient -->
        <div class="px-6 pt-5 pb-4 border-b border-gray-100 shrink-0">
          <p class="text-[10px] text-gray-400 uppercase tracking-widest font-semibold mb-2">New Message</p>
          <div class="flex items-center gap-2">
            <span class="text-xs font-semibold text-gray-400">To:</span>
            <span class="text-sm font-medium text-gray-800">{{ otherUserName }}</span>
          </div>
        </div>

        <!-- Full-height textarea — no border, fills panel -->
        <div class="flex-1 flex flex-col px-6 py-4 min-h-0">
          <textarea
            ref="textareaRef"
            v-model="inputText"
            @input="handleInputChange"
            @keydown="handleKeyDown"
            class="flex-1 w-full resize-none border-0 focus:outline-none text-[15px] leading-relaxed text-gray-800 placeholder-gray-400 bg-transparent"
            placeholder="Write your message here..."
            maxlength="5000"
            aria-label="Type a message"
          ></textarea>
        </div>

        <!-- Send footer -->
        <div class="px-6 pb-5 pt-3 border-t border-gray-100 shrink-0 flex items-center justify-between">
          <span class="text-xs text-gray-400">{{ inputText.length > 0 ? `${inputText.length} / 5000` : 'Shift+Enter for new line' }}</span>
          <button
            @click="sendMessage"
            :disabled="inputText.trim() === '' || isSending"
            class="flex items-center gap-2 text-white font-semibold px-6 py-2.5 rounded-lg transition disabled:opacity-50 hover:opacity-90"
            style="background-color: #8cc65d"
          >
            <span v-if="isSending" class="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full"></span>
            <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
            </svg>
            Send Message
          </button>
        </div>
      </div>

      <!-- RIGHT COLUMN (Desktop) / FULL VIEW (Mobile): Messages Feed (50% width) -->
      <div class="flex flex-col flex-1 min-h-0 xl:w-[50%] bg-white">

        <!-- Desktop: thread header with avatar + name + count -->
        <div class="hidden xl:flex items-center gap-3 px-6 py-3 border-b border-gray-100 shrink-0 bg-white">
          <img v-if="otherUserPhotoURL" :src="otherUserPhotoURL" class="w-9 h-9 rounded-full object-cover shrink-0" />
          <div v-else class="w-9 h-9 rounded-full bg-gray-200 flex items-center justify-center text-gray-500 text-sm font-semibold shrink-0">
            {{ otherUserName?.charAt(0)?.toUpperCase() }}
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-semibold text-gray-900 truncate">{{ otherUserName }}</p>
            <p class="text-xs text-gray-400">{{ messages.length }} message{{ messages.length !== 1 ? 's' : '' }}</p>
          </div>
        </div>

        <!-- Messages List -->
        <div ref="scrollContainer" class="flex-1 overflow-y-auto px-3 xl:px-8 py-3 xl:py-5 pb-32 xl:pb-5" style="-webkit-overflow-scrolling: touch; overscroll-behavior-y: contain;" @scroll.passive="onScroll">
      <!-- Load older: divider style on desktop, plain link on mobile -->
      <div v-if="canLoadOlder" class="flex items-center gap-3 py-2 xl:my-3">
        <div class="hidden xl:block flex-1 h-px bg-gray-200"></div>
        <button @click="loadOlder" :disabled="isLoadingOlder" class="text-xs text-gray-400 hover:text-gray-600 shrink-0">
          <span v-if="isLoadingOlder" class="animate-spin h-4 w-4 border-2 border-gray-400 border-t-transparent rounded-full inline-block mr-1"></span>
          Load older messages
        </button>
        <div class="hidden xl:block flex-1 h-px bg-gray-200"></div>
      </div>
      <div v-for="msg in messages" :key="msg.id" class="mb-3 xl:mb-5">
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
      </div>
    </div>

    <!-- Input Bar (MOBILE ONLY - hidden on desktop) -->
    <div class="xl:hidden fixed bottom-0 left-0 right-0 z-20 flex justify-center">
      <div class="w-full border-t border-gray-200 bg-white px-3 py-2" style="max-width: 768px;">
        <div class="flex items-center gap-2">
          <textarea
            v-model="inputText"
            @input="handleInputChange"
            @keydown.enter.exact.prevent="sendMessage()"
            rows="1"
            class="flex-1 resize-none rounded-lg border border-gray-300 p-2 focus:outline-none focus:ring-2"
            style="--tw-ring-color: #8cc65d; border-color: inherit;"
            placeholder="Type a message..."
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
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, defineEmits } from 'vue';
import { useRouter } from 'vue-router';
import api from '@/pages/utils/api';
import MessageBubble from '@/components/MessageBubble.vue';
import EmojiPicker from '@/components/EmojiPicker.vue';
import DeleteConfirmDialog from '@/components/DeleteConfirmDialog.vue';
import EditHistoryModal from '@/components/EditHistoryModal.vue';
import { BREAKPOINTS } from '@/constants/breakpoints';

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

const router = useRouter();
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
const isDesktop = ref(window.innerWidth >= BREAKPOINTS.DESKTOP);
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
  // Disable auto-resize on desktop - we have a fixed large textarea in the left column
  // Only auto-resize on mobile if needed
  if (!isDesktop.value && textareaRef.value) {
    textareaRef.value.style.height = 'auto';
    textareaRef.value.style.height = `${Math.min(textareaRef.value.scrollHeight, 180)}px`;
  }
}

function updateDesktopDetection() {
  isDesktop.value = window.innerWidth >= BREAKPOINTS.DESKTOP;
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
      // Accept if sender is the other user; recipientId check is optional
      // (server doesn't always include it — requiring it silently drops valid messages)
      if (senderId === props.otherUserId && (recipientId == null || recipientId === props.currentUserId)) {
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

function handleStorageLogout(e: StorageEvent) {
  if (e.key === 'jwtToken' && !e.newValue) router.push('/login');
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

  // Redirect to login if JWT is cleared in another tab
  window.addEventListener('storage', handleStorageLogout);
});

onUnmounted(() => {
  if (observerId && window.RealtimeSocketManager) {
    window.RealtimeSocketManager.removeDirectMessageObserver(observerId);
  }

  // Remove desktop detection listener
  window.removeEventListener('resize', updateDesktopDetection);
  window.removeEventListener('storage', handleStorageLogout);

  // Refresh MainScreen chat list when leaving - backend marks messages as read during fetch
  emit('refresh-chats');
});
</script>

<style scoped>
/* Desktop: Make chat page full width, breaking out of App.vue container */
.chat-individual-container {
  /* Mobile: stay within container */
  width: 100%;
}

/* Desktop breakpoint - keep in sync with BREAKPOINTS.DESKTOP in @/constants/breakpoints.ts */
@media (min-width: 1280px) {
  .chat-individual-container {
    /* Desktop: break out to full viewport width */
    width: 100vw;
    max-width: 100vw;
    margin-left: calc(-50vw + 50%);
  }
}
</style>