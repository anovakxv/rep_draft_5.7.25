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
      <div ref="scrollContainer" class="flex-1 overflow-y-auto px-3 py-3" @scroll.passive="onScroll">
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
            v-model="inputText"
            @input="handleInputChange"
            rows="1"
            class="flex-1 resize-none rounded-lg border border-gray-300 p-2 focus:outline-none focus:ring-2"
            style="--tw-ring-color: #8cc65d; border-color: inherit;"
            placeholder="Type a message..."
            @keydown.enter.exact.prevent="sendMessage"
            maxlength="1000"
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
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, defineEmits } from 'vue';
import api from '@/pages/utils/api';
import MessageBubble from '@/components/MessageBubble.vue';

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
let typingTimeout: ReturnType<typeof setTimeout> | null = null;
let observerId: string | null = null;

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

function scrollToBottom() {
  if (scrollContainer.value) {
    scrollContainer.value.scrollTop = scrollContainer.value.scrollHeight;
  }
}

// --- Scroll Event for Infinite Scroll ---
function onScroll() {
  if (!scrollContainer.value || isLoadingOlder.value || !canLoadOlder.value) return;
  if (scrollContainer.value.scrollTop < 60 && messages.value.length > 0) {
    loadOlder();
  }
}

// --- Lifecycle ---
onMounted(() => {
  // Optionally initialize socket connection if needed
  if (window.RealtimeSocketManager) {
    window.RealtimeSocketManager.connect(apiBaseUrl, token, props.currentUserId);
  }
  fetchMessages();
  setupRealtimeListener();
});

onUnmounted(() => {
  if (observerId && window.RealtimeSocketManager) {
    window.RealtimeSocketManager.removeDirectMessageObserver(observerId);
  }
});
</script>