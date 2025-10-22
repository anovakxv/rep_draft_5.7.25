<!--
  Chat_Group.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header -->
    <div class="flex items-center h-14 px-4 border-b bg-white shrink-0">
      <button @click="emit('close')" class="text-green-600 font-semibold p-2 -ml-2">Back</button>
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

    <!-- Group Info Modal -->
    <div v-if="showGroupInfo" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
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
              <GroupMemberAvatar :name="member.name" :photoURL="member.profilePicture" :size="40" />
              <div>
                <p class="font-semibold">{{ member.name }}</p>
                <p v-if="member.id === creatorId" class="text-xs text-gray-500">Group Creator</p>
              </div>
            </div>
          </div>
        </div>

        <div v-if="currentUserId === creatorId" class="space-y-2 border-t pt-4">
          <button @click="showLeaveAlert = true" class="w-full py-2 bg-red-600 text-white font-bold rounded-lg hover:bg-red-700">
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
const selectedAttachments = ref<File[]>([]);
const fileInputRef = ref<HTMLInputElement | null>(null);
const isTyping = ref(false);
const typingUsers = ref<Array<{ userId: number; userName: string }>>([]);
const groupName = ref('');
const groupMembers = ref<GroupMember[]>([]);
const creatorId = ref<number | null>(null);
const showGroupInfo = ref(false);
const showLeaveAlert = ref(false);
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
  if ((!trimmed && selectedAttachments.value.length === 0) || isSending.value) return;
  isSending.value = true;

  try {
    if (selectedAttachments.value.length > 0) {
      const formData = new FormData();
      formData.append('chats_id', String(props.chatId));
      if (trimmed) {
        formData.append('message', trimmed);
      }
      selectedAttachments.value.forEach((file, index) => {
        formData.append('attachments', file, file.name);
      });

      // Backend route: POST /api/message/send_chat_message
      const res = await api.post('/api/message/send_chat_message', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      const msg: GroupMessage = res.data.message;
      appendIfNeeded(msg);
    } else {
      // Backend route: POST /api/message/send_chat_message
      const res = await api.post('/api/message/send_chat_message', {
        chats_id: props.chatId,
        message: trimmed
      });
      const msg: GroupMessage = res.data.message;
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
    target.value = '';
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