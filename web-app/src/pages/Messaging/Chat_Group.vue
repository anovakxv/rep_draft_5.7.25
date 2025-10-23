<!--
  Chat_Group.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header -->
    <div class="flex items-center h-14 px-4 border-b border-gray-200 bg-gray-50 shrink-0">
      <button @click="emit('close')" class="text-green-600">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h1 class="font-bold text-lg flex-1 text-center truncate">{{ groupName }}</h1>
      <button @click="showGroupInfo = true" class="p-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </button>
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
        <GroupMessageBubble :message="msg" :isCurrentUser="msg.sender_id === currentUserId" />
      </div>
      <div v-if="isLoadingOlder" class="flex justify-center py-2">
        <span class="animate-spin h-5 w-5 border-2 border-gray-400 border-t-transparent rounded-full"></span>
      </div>
      <!-- Typing Indicators -->
      <div v-if="typingUsers.length > 0" class="mb-3 flex items-center gap-2 text-gray-500 text-sm">
        <div class="flex gap-1">
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0ms;"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 150ms;"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 300ms;"></span>
        </div>
        <span>{{ typingUsersText }} typing...</span>
      </div>
    </div>

    <!-- Input Bar -->
    <div class="border-t border-gray-200 bg-white px-3 py-2">
      <div class="flex items-center gap-2">
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
          :disabled="inputText.trim() === '' || isSending"
          class="bg-green-600 text-white font-bold px-4 py-2 rounded-lg hover:bg-green-700 transition disabled:opacity-60"
        >
          <span v-if="isSending" class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-2"></span>
          Send
        </button>
      </div>
    </div>

    <!-- Group Info Modal -->
    <div v-if="showGroupInfo && groupMembers.length > 0" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-y-auto p-6">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-bold">Group Info</h2>
          <button @click="showGroupInfo = false" class="text-gray-600 hover:text-gray-800">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="mb-4">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">Members ({{ groupMembers.length }})</h3>
          <div class="space-y-2">
            <div v-for="member in groupMembers" :key="member.id" class="flex items-center gap-3">
              <GroupMemberAvatar :name="member.name || 'Unknown'" :photoURL="member.profilePicture" :size="40" />
              <div>
                <p class="font-semibold">{{ member.name || 'Unknown' }}</p>
                <p v-if="member.id === creatorId" class="text-xs text-gray-500">Group Creator</p>
              </div>
            </div>
          </div>
        </div>

        <div class="space-y-2 border-t pt-4">
          <button v-if="currentUserId === creatorId" @click="handleDeleteClick" class="w-full py-2 bg-red-600 text-white font-bold rounded-lg hover:bg-red-700">
            Delete Group Chat
          </button>
          <button v-else @click="handleLeaveClick" class="w-full py-2 bg-red-600 text-white font-bold rounded-lg hover:bg-red-700">
            Leave Group
          </button>
        </div>
      </div>
    </div>

    <!-- Leave Alert -->
    <div v-if="showLeaveAlert" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
      <div class="bg-white rounded-lg p-6 max-w-sm mx-auto">
        <h3 class="font-bold text-lg mb-4">Leave Group?</h3>
        <p class="mb-6">Are you sure you want to leave this group chat?</p>
        <div class="flex gap-4 justify-end">
          <button @click="showLeaveAlert = false" class="px-4 py-2 border rounded-lg">Cancel</button>
          <button @click="leaveGroup" class="px-4 py-2 bg-red-600 text-white rounded-lg">Leave</button>
        </div>
      </div>
    </div>

    <!-- Delete Alert (for creators) -->
    <div v-if="showDeleteAlert" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
      <div class="bg-white rounded-lg p-6 max-w-sm mx-auto">
        <h3 class="font-bold text-lg mb-4">Delete Group Chat?</h3>
        <p class="mb-6">This will permanently delete the group chat for all members. This action cannot be undone.</p>
        <div class="flex gap-4 justify-end">
          <button @click="showDeleteAlert = false" class="px-4 py-2 border rounded-lg">Cancel</button>
          <button @click="deleteGroup" class="px-4 py-2 bg-red-600 text-white rounded-lg">Delete</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, computed } from 'vue';
import api from '@/pages/utils/api';
import GroupMessageBubble from '@/components/GroupMessageBubble';
import GroupMemberAvatar from '@/components/GroupMemberAvatar';

// --- Constants ---
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '';
const token = localStorage.getItem('jwtToken') || '';

// --- Props ---
const props = defineProps<{
  chatId: number;
  currentUserId: number;
}>();

const emit = defineEmits(['close', 'refresh-chats']);

// --- State ---
const messages = ref<GroupMessage[]>([]);
const inputText = ref('');
const isSending = ref(false);
const isLoadingOlder = ref(false);
const canLoadOlder = ref(true);
const scrollContainer = ref<HTMLElement | null>(null);
const isTyping = ref(false);
const typingUsers = ref<Array<{ userId: number; userName: string }>>([]);
const groupName = ref('');
const groupMembers = ref<GroupMember[]>([]);
const creatorId = ref<number | null>(null);
const showGroupInfo = ref(false);
const showLeaveAlert = ref(false);
const showDeleteAlert = ref(false);
let typingTimeout: ReturnType<typeof setTimeout> | null = null;
let observerId: string | null = null;

interface GroupMessage {
  id: number;
  sender_id: number;  // Backend returns snake_case
  sender_name: string;  // Backend returns snake_case
  sender_photo_url?: string;  // Backend returns this
  text: string;
  timestamp: string;
  attachments?: Array<{
    url: string;
    type: 'image' | 'file';
    filename?: string;
  }>;
}

interface GroupMember {
  id: number;
  name: string;
  profilePicture?: string;
}

const typingUsersText = computed(() => {
  if (typingUsers.value.length === 0) return '';
  if (typingUsers.value.length === 1) return typingUsers.value[0].userName;
  if (typingUsers.value.length === 2) return `${typingUsers.value[0].userName} and ${typingUsers.value[1].userName}`;
  return `${typingUsers.value[0].userName} and ${typingUsers.value.length - 1} others`;
});

// --- Fetch Group Info ---
async function fetchGroupInfo() {
  try {
    // Backend route: GET /api/message/group_chat?chats_id=${id}
    const res = await api.get(`/api/message/group_chat?chats_id=${props.chatId}`);
    const result = res.data.result;
    groupName.value = result.chat?.name || 'Group Chat';
    groupMembers.value = result.users || [];
    creatorId.value = result.chat?.created_by;
  } catch (e) {
    console.error('Failed to fetch group info:', e);
  }
}

// --- Fetch Messages ---
async function fetchMessages(beforeId?: number, append = false) {
  if (append) {
    if (isLoadingOlder.value || !canLoadOlder.value) return;
    isLoadingOlder.value = true;
  }
  try {
    // Backend route: GET /api/message/group_chat?chats_id=${id}&limit=${limit}&offset=${offset}
    // Note: Backend uses offset, not before_id for pagination
    const params = new URLSearchParams({
      chats_id: String(props.chatId),
      limit: '200',
      offset: '0'
    });
    const res = await api.get(`/api/message/group_chat?${params.toString()}`);
    const result = res.data.result;
    const newMsgs: GroupMessage[] = result.messages || [];

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
      // Update group info from the same response
      groupName.value = result.chat?.name || 'Group Chat';
      groupMembers.value = result.users || [];
      creatorId.value = result.chat?.created_by;
      emit('refresh-chats');
      nextTick(() => scrollToBottom());
    }
  } catch (e) {
    console.error('Failed to fetch messages:', e);
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
    // Backend route: POST /api/message/send_chat_message
    const res = await api.post('/api/message/send_chat_message', {
      chats_id: props.chatId,
      message: trimmed
    });
    const msg: GroupMessage = res.data.message;
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
    window.RealtimeSocketManager.emitGroupTyping({
      chatId: props.chatId,
      isTyping: typing
    });
  }
}

// --- Real-time Socket Listener ---
function setupRealtimeListener() {
  if (window.RealtimeSocketManager) {
    observerId = window.RealtimeSocketManager.onGroupMessageNotification((payload: any) => {
      if (payload.chatId === props.chatId || payload.chat_id === props.chatId) {
        if (payload.message) {
          appendIfNeeded(payload.message);
        } else if (payload.text) {
          // Socket payload already has snake_case fields
          appendIfNeeded({
            id: payload.id,
            sender_id: payload.sender_id,
            sender_name: payload.sender_name,
            sender_photo_url: payload.sender_photo_url,
            text: payload.text,
            timestamp: payload.timestamp,
            attachments: payload.attachments
          });
        }
        emit('refresh-chats');
        nextTick(() => scrollToBottom());
      }
    });

    // Listen for typing events in group
    window.RealtimeSocketManager.onGroupTypingNotification?.((payload: any) => {
      if (payload.chatId === props.chatId && payload.senderId !== props.currentUserId) {
        if (payload.isTyping) {
          if (!typingUsers.value.some(u => u.userId === payload.senderId)) {
            typingUsers.value.push({
              userId: payload.senderId,
              userName: payload.senderName || 'Someone'
            });
          }
        } else {
          typingUsers.value = typingUsers.value.filter(u => u.userId !== payload.senderId);
        }
      }
    });
  }
}

// --- Helpers ---
function appendIfNeeded(msg: GroupMessage) {
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

function onScroll() {
  if (!scrollContainer.value || isLoadingOlder.value || !canLoadOlder.value) return;
  if (scrollContainer.value.scrollTop < 60 && messages.value.length > 0) {
    loadOlder();
  }
}

async function leaveGroup() {
  try {
    // Backend route: POST /api/message/manage_chat
    // To leave: send current user ID in aDelIDs array
    await api.post('/api/message/manage_chat', {
      chats_id: props.chatId,
      aDelIDs: [props.currentUserId]
    });
    showLeaveAlert.value = false;
    emit('close');
    emit('refresh-chats');
  } catch (e) {
    console.error('Failed to leave group:', e);
  }
}

function handleLeaveClick() {
  showGroupInfo.value = false;
  showLeaveAlert.value = true;
}

function handleDeleteClick() {
  showGroupInfo.value = false;
  showDeleteAlert.value = true;
}

async function deleteGroup() {
  try {
    // Backend route: POST /api/message/delete_chat
    // Deletes the entire group chat (creators only)
    await api.post('/api/message/delete_chat', {
      chats_id: props.chatId
    });
    showDeleteAlert.value = false;
    emit('close');
    emit('refresh-chats');
  } catch (e) {
    console.error('Failed to delete group:', e);
  }
}

// --- Lifecycle ---
onMounted(() => {
  if (window.RealtimeSocketManager) {
    window.RealtimeSocketManager.connect(apiBaseUrl, token, props.currentUserId);
  }
  fetchGroupInfo();
  fetchMessages();
  setupRealtimeListener();
});

onUnmounted(() => {
  if (observerId && window.RealtimeSocketManager) {
    window.RealtimeSocketManager.removeGroupMessageObserver?.(observerId);
  }
  stopTyping();
});
</script>