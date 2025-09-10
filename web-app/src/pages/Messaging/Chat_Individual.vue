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
          :isCurrentUser="msg.senderId === currentUserId"
          :profilePicURL="msg.senderId === otherUserId ? otherUserPhotoURL : null"
        />
      </div>
      <div v-if="isLoadingOlder" class="flex justify-center py-2">
        <span class="animate-spin h-5 w-5 border-2 border-gray-400 border-t-transparent rounded-full"></span>
      </div>
    </div>

    <!-- Input Bar -->
    <div class="border-t bg-white px-3 py-2 flex items-center gap-2">
      <textarea
        v-model="inputText"
        rows="1"
        class="flex-1 resize-none rounded-lg border border-gray-300 p-2 focus:ring-green-500 focus:border-green-500"
        placeholder="Type a message..."
        @keydown.enter.exact.prevent="sendMessage"
        maxlength="1000"
        aria-label="Type a message"
      ></textarea>
      <button
        @click="sendMessage"
        :disabled="inputText.trim() === '' || isSending"
        class="bg-green-600 text-white font-bold px-4 py-2 rounded-lg hover:bg-green-700 transition disabled:opacity-60"
      >
        <span v-if="isSending" class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-2"></span>
        Send
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, defineEmits } from 'vue';
import axios from 'axios';

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
let observerId: string | null = null;

interface SimpleMessage {
  id: number;
  senderId: number;
  senderName: string;
  text: string;
  timestamp: string;
  read?: string;
}

const token = localStorage.getItem('jwtToken');
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

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
    const res = await axios.get(`${apiBaseUrl}/api/message/get_messages?${params.toString()}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
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
    const res = await axios.post(`${apiBaseUrl}/api/message/send_message`, {
      users_id: props.otherUserId,
      message: trimmed
    }, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    const msg: SimpleMessage = res.data.message;
    appendIfNeeded(msg);
    inputText.value = '';
    nextTick(() => scrollToBottom());
  } catch (e) {
    // Optionally show error
  } finally {
    isSending.value = false;
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
            read: payload.read
          });
        }
        emit('refresh-chats'); // Notify parent to refresh chat list
        nextTick(() => scrollToBottom());
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

<script lang="ts">
// MessageBubble component
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'MessageBubble',
  props: {
    message: { type: Object, required: true },
    isCurrentUser: { type: Boolean, required: true },
    profilePicURL: { type: String, default: null }
  },
  setup(props) {
    function formatTime(ts: string) {
      const date = new Date(ts);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    return () => (
      <div class={['flex items-end', props.isCurrentUser ? 'justify-end' : 'justify-start']}>
        {!props.isCurrentUser && (
          props.profilePicURL
            ? <img src={props.profilePicURL} class="w-8 h-8 rounded-full object-cover mr-2" />
            : <div class="w-8 h-8 rounded-full bg-gray-300 mr-2"></div>
        )}
        <div class={['flex flex-col', props.isCurrentUser ? 'items-end' : 'items-start']}>
          <div
            class={[
              'px-4 py-2 rounded-lg max-w-xs break-words',
              props.isCurrentUser ? 'bg-black text-green-400' : 'bg-gray-100 text-black'
            ]}
          >
            {props.message.text}
          </div>
          <div class="text-xs text-gray-500 mt-1">{formatTime(props.message.timestamp)}</div>
        </div>
      </div>
    );
  }
});
</script>