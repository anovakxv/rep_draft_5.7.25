<!--
  Chat_Individual.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header -->
    <div class="flex items-center h-14 px-4 border-b bg-white shrink-0">
      <button @click="emit('close')" class="text-green-600 font-semibold p-2 -ml-2">Back</button>
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
    <div class="border-t bg-white px-3 py-2">
      <!-- Attachment Previews -->
      <div v-if="selectedAttachments.length > 0" class="mb-2 flex gap-2 flex-wrap">
        <div v-for="(file, index) in selectedAttachments" :key="index" class="relative bg-gray-100 rounded-lg p-2 flex items-center gap-2 max-w-xs">
          <svg v-if="file.type.startsWith('image/')" xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-green-600" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z" clip-rule="evenodd" />
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-600" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clip-rule="evenodd" />
          </svg>
          <span class="text-sm truncate max-w-[150px]">{{ file.name }}</span>
          <button @click="removeAttachment(index)" class="text-red-600 hover:text-red-800 ml-auto">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <!-- Attachment Button -->
        <button
          @click="openFilePicker"
          :disabled="isSending || selectedAttachments.length >= 5"
          class="text-gray-600 hover:text-green-600 transition p-2 disabled:opacity-40"
          aria-label="Attach file"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
          </svg>
        </button>
        <input
          ref="fileInputRef"
          type="file"
          multiple
          accept="image/*,.pdf,.doc,.docx,.txt"
          @change="handleFileSelection"
          class="hidden"
        />

        <textarea
          v-model="inputText"
          @input="handleInputChange"
          rows="1"
          class="flex-1 resize-none rounded-lg border border-gray-300 p-2 focus:ring-green-500 focus:border-green-500"
          placeholder="Type a message..."
          @keydown.enter.exact.prevent="sendMessage"
          maxlength="1000"
          aria-label="Type a message"
        ></textarea>
        <button
          @click="sendMessage"
          :disabled="(inputText.trim() === '' && selectedAttachments.length === 0) || isSending"
          class="bg-green-600 text-white font-bold px-4 py-2 rounded-lg hover:bg-green-700 transition disabled:opacity-60"
        >
          <span v-if="isSending" class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-2"></span>
          Send
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, defineEmits } from 'vue';
import api from '@/pages/utils/api';
import MessageBubble from '@/components/MessageBubble.vue';

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
const selectedAttachments = ref<File[]>([]);
const fileInputRef = ref<HTMLInputElement | null>(null);
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
  if ((!trimmed && selectedAttachments.value.length === 0) || isSending.value) return;
  isSending.value = true;

  try {
    // If there are attachments, use FormData
    if (selectedAttachments.value.length > 0) {
      const formData = new FormData();
      formData.append('users_id', String(props.otherUserId));
      if (trimmed) {
        formData.append('message', trimmed);
      }
      selectedAttachments.value.forEach((file, index) => {
        formData.append('attachments', file, file.name);
      });

      const res = await api.post('/api/message/send_message', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      const msg: SimpleMessage = res.data.message;
      appendIfNeeded(msg);
    } else {
      // Text-only message
      const res = await api.post('/api/message/send_message', {
        users_id: props.otherUserId,
        message: trimmed
      });
      const msg: SimpleMessage = res.data.message;
      appendIfNeeded(msg);
    }

    inputText.value = '';
    selectedAttachments.value = [];
    stopTyping();
    nextTick(() => scrollToBottom());
  } catch (e) {
    console.error('Failed to send message:', e);
  } finally {
    isSending.value = false;
  }
}

// --- File Attachment Handlers ---
function openFilePicker() {
  fileInputRef.value?.click();
}

function handleFileSelection(event: Event) {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files.length > 0) {
    const newFiles = Array.from(target.files).slice(0, 5 - selectedAttachments.value.length);
    selectedAttachments.value.push(...newFiles);
    target.value = ''; // Reset input
  }
}

function removeAttachment(index: number) {
  selectedAttachments.value.splice(index, 1);
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
            senderId: senderId,
            senderName: payload.sender_name,
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