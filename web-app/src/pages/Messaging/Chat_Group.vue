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
      <h1 class="font-bold text-lg flex-1 text-center truncate">{{ customChatTitle || groupName }}</h1>
      <button @click="showEditSheet = true" class="text-green-600 p-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
      </button>
    </div>

    <!-- Members Horizontal Scroll -->
    <div class="overflow-x-auto bg-white border-b py-2 px-2 shadow-sm">
      <div class="flex gap-4">
        <div v-for="member in groupMembers" :key="member.id" class="flex flex-col items-center w-14">
          <GroupMemberAvatar :name="member.name" :photoURL="member.profilePicture" :size="36" />
          <div class="text-xs text-gray-500 mt-1 truncate w-12 text-center">{{ initials(member.name) }}</div>
        </div>
      </div>
    </div>

    <!-- Messages List -->
    <div ref="scrollContainer" class="flex-1 overflow-y-auto px-3 py-3">
      <div v-for="msg in messages" :key="msg.id" class="mb-3">
        <GroupMessageBubble :message="msg" :isCurrentUser="msg.senderId === currentUserId" />
      </div>
    </div>

    <!-- Input Bar -->
    <div class="border-t bg-white px-3 py-2 flex items-start gap-2">
      <GrowingTextarea v-model="inputText" @keydown.enter.exact.prevent="sendMessage" />
      <button
        @click="sendMessage"
        :disabled="inputText.trim() === '' || isSending"
        class="bg-green-600 text-white font-bold px-4 h-[38px] rounded-lg hover:bg-green-700 transition disabled:opacity-60 shrink-0"
      >
        <span v-if="isSending" class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full"></span>
        <span v-else>Send</span>
      </button>
    </div>

    <!-- Edit Group Sheet -->
    <EditGroupSheet
      v-if="showEditSheet"
      :chatId="chatId"
      :groupName="groupName"
      :groupMembers="groupMembers"
      :isCreator="isCreator"
      :currentUserId="currentUserId"
      @close="showEditSheet = false"
      @refresh="fetchGroupChat"
      @delete="handleDelete"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, defineEmits } from 'vue';
import axios from 'axios';

// --- Props & Emits ---
const props = defineProps<{
  currentUserId: number;
  chatId: number;
  customChatTitle?: string;
}>();
const emit = defineEmits(['close', 'refresh-chats']);

// --- State ---
const groupName = ref('');
const groupMembers = ref<GroupMember[]>([]);
const messages = ref<GroupMessage[]>([]);
const inputText = ref('');
const isSending = ref(false);
const isCreator = ref(false);
const showEditSheet = ref(false);
const scrollContainer = ref<HTMLElement | null>(null);
let socketObserverId: string | null = null;

const token = localStorage.getItem('jwtToken');
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
const s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/";

// --- Models ---
interface GroupMessage {
  id: number;
  senderId: number;
  senderName: string;
  senderPhoto?: string;
  text: string;
  timestamp: string;
}

interface GroupMember {
  id: number;
  name: string;
  profilePicture?: string;
}

interface User {
  id: number;
  fullName?: string;
  profilePictureURL?: string;
}

interface ErrorMessage {
  message: string;
}

// --- Helpers ---
function initials(name: string): string {
  const comps = name.split(' ');
  const first = comps[0]?.[0] || '';
  const last = comps[1]?.[0] || '';
  return (first + last).toUpperCase();
}

function scrollToBottom() {
  if (scrollContainer.value) {
    scrollContainer.value.scrollTop = scrollContainer.value.scrollHeight;
  }
}

function appendIfNeeded(msg: GroupMessage) {
  if (!messages.value.some(m => m.id === msg.id)) {
    messages.value.push(msg);
    messages.value.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
  }
}

function patchProfilePictureURL(imageName?: string): string | null {
  if (!imageName) return null;
  if (imageName.startsWith('http')) {
    return imageName;
  } else {
    return s3BaseURL + imageName;
  }
}

// --- API & Realtime ---
async function fetchGroupChat() {
  try {
    const res = await axios.get(`${apiBaseUrl}/api/message/group_chat?chats_id=${props.chatId}&limit=50`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const result = res.data.result;
    groupName.value = result.chat.name;
    groupMembers.value = result.users;
    messages.value = result.messages.sort((a: GroupMessage, b: GroupMessage) =>
      new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
    );
    isCreator.value = result.chat.created_by === props.currentUserId;
    emit('refresh-chats');
    nextTick(() => scrollToBottom());
  } catch (e) {
    console.error("Failed to fetch group chat:", e);
  }
}

async function sendMessage() {
  const trimmed = inputText.value.trim();
  if (!trimmed || isSending.value) return;
  isSending.value = true;

  // Create optimistic message with negative ID (like in Swift)
  const tempId = -(messages.value.length + 1);
  const optimisticMsg: GroupMessage = {
    id: tempId,
    senderId: props.currentUserId,
    senderName: "You",
    text: trimmed,
    timestamp: new Date().toISOString()
  };
  messages.value.push(optimisticMsg);
  inputText.value = '';
  nextTick(() => scrollToBottom());

  try {
    const res = await axios.post(`${apiBaseUrl}/api/message/send_chat_message`, {
      chats_id: props.chatId,
      message: trimmed
    }, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    const realMsg: GroupMessage = res.data.message;
    // Replace optimistic message with real one
    const idx = messages.value.findIndex(m => m.id === tempId);
    if (idx !== -1) {
      messages.value[idx] = realMsg;
    } else {
      appendIfNeeded(realMsg);
    }
    nextTick(() => scrollToBottom());
  } catch (e) {
    // Remove optimistic message on failure
    messages.value = messages.value.filter(m => m.id !== tempId);
    console.error("Failed to send message:", e);
  } finally {
    isSending.value = false;
  }
}

async function markChatAsRead() {
  try {
    // Call API with limit=1 to mark as read (same as Swift)
    await axios.get(`${apiBaseUrl}/api/message/group_chat?chats_id=${props.chatId}&limit=1`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    // Notify parent to refresh chats (equivalent to NotificationCenter in Swift)
    emit('refresh-chats');
  } catch (e) {
    console.error("Failed to mark chat as read:", e);
  }
}

// --- Real-time Socket Management ---
function setupRealtime() {
  if (!window.RealtimeSocketManager) return;

  // Initialize the socket connection (only once per app session)
  const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
  window.RealtimeSocketManager.connect(apiBaseUrl, token, props.currentUserId);

  // Join the chat room
  window.RealtimeSocketManager.join(props.chatId);

  // Listen for messages
  socketObserverId = window.RealtimeSocketManager.onGroupMessage((payload: any) => {
    const incomingChatId = payload.chat_id ?? payload.chatId;
    if (incomingChatId != props.chatId) return;

    // Extract message from payload (handle both formats)
    const msg = payload.message || {
      id: payload.id,
      senderId: payload.sender_id,
      senderName: payload.sender_name,
      senderPhoto: payload.sender_photo_url,
      text: payload.text,
      timestamp: payload.timestamp
    };

    if (msg && !messages.value.some(m => m.id === msg.id)) {
      messages.value.push(msg);
      // Mark as read if from someone else
      if (msg.senderId !== props.currentUserId) {
        markChatAsRead();
      }
      nextTick(() => scrollToBottom());
    }
  });
}

function teardownRealtime() {
  if (!window.RealtimeSocketManager) return;
  
  // Remove observer and leave chat room
  if (socketObserverId) {
    window.RealtimeSocketManager.removeGroupMessageObserver(socketObserverId);
    socketObserverId = null;
  }
  window.RealtimeSocketManager.leave(props.chatId);
}

function handleDelete() {
  emit('refresh-chats');
  emit('close');
}

// --- Lifecycle ---
onMounted(() => {
  fetchGroupChat();
  setupRealtime();
});

onUnmounted(() => {
  teardownRealtime();
});
</script>

<script lang="ts">
// GroupMemberAvatar component
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'GroupMemberAvatar',
  props: {
    name: { type: String, required: true },
    photoURL: { type: String, default: null },
    size: { type: Number, default: 36 }
  },
  setup(props) {
    function initials(name: string): string {
      const comps = name.split(' ');
      const first = comps[0]?.[0] || '';
      const last = comps[1]?.[0] || '';
      return (first + last).toUpperCase();
    }
    
    return () => (
      <div style={{ width: `${props.size}px`, height: `${props.size}px` }} class="relative">
        {props.photoURL
          ? <img src={props.photoURL.startsWith('http') ? props.photoURL : `https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/${props.photoURL}`} class="rounded-full object-cover w-full h-full" />
          : <div class="rounded-full bg-gray-300 w-full h-full flex items-center justify-center text-xs font-semibold text-white">{initials(props.name)}</div>
        }
      </div>
    );
  }
});

// GroupMessageBubble component
export const GroupMessageBubble = defineComponent({
  name: 'GroupMessageBubble',
  props: {
    message: { type: Object, required: true },
    isCurrentUser: { type: Boolean, required: true }
  },
  setup(props) {
    function formatTime(ts: string) {
      const date = new Date(ts);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    
    return () => (
      <div class={['flex', props.isCurrentUser ? 'justify-end' : 'justify-start']}>
        <div class={['flex flex-col max-w-[260px]', props.isCurrentUser ? 'items-end' : 'items-start']}>
          {!props.isCurrentUser && (
            <div class="text-xs text-gray-500 mb-1">{props.message.senderName}</div>
          )}
          <div
            class={[
              'px-4 py-2 rounded-lg break-words',
              props.isCurrentUser ? 'bg-black text-green-400' : 'bg-gray-200 text-black'
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

// GrowingTextarea component (auto-expanding textarea)
export const GrowingTextarea = defineComponent({
  name: 'GrowingTextarea',
  props: {
    modelValue: { type: String, required: true }
  },
  emits: ['update:modelValue', 'keydown'],
  setup(props, { emit }) {
    const textarea = ref<HTMLTextAreaElement | null>(null);
    
    function resize() {
      if (textarea.value) {
        textarea.value.style.height = 'auto';
        textarea.value.style.height = Math.min(textarea.value.scrollHeight, 144) + 'px'; // Max 4 lines (36px * 4)
      }
    }
    
    onMounted(resize);
    
    return () => (
      <textarea
        ref={textarea}
        value={props.modelValue}
        rows={1}
        class="flex-1 resize-none rounded-lg border border-gray-300 p-2 focus:ring-green-500 focus:border-green-500"
        placeholder="Type a message..."
        maxlength="1000"
        aria-label="Type a message"
        onInput={e => {
          emit('update:modelValue', (e.target as HTMLTextAreaElement).value);
          resize();
        }}
        onKeydown={e => emit('keydown', e)}
      />
    );
  }
});

// EditGroupSheet component with add/remove members functionality
export const EditGroupSheet = defineComponent({
  name: 'EditGroupSheet',
  props: {
    chatId: { type: Number, required: true },
    groupName: { type: String, required: true },
    groupMembers: { type: Array, required: true },
    isCreator: { type: Boolean, required: true },
    currentUserId: { type: Number, required: true }
  },
  emits: ['close', 'refresh', 'delete'],
  setup(props, { emit }) {
    const editedName = ref(props.groupName);
    const isSaving = ref(false);
    const errorMessage = ref('');
    const showAddMembersSheet = ref(false);
    const showRemoveMembersSheet = ref(false);
    const showDeleteAlert = ref(false);
    const selectedMembersToAdd = ref<Record<number, string>>({});
    const token = localStorage.getItem('jwtToken');
    const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

    function close() { 
      emit('close'); 
    }

    async function save() {
      isSaving.value = true;
      errorMessage.value = '';
      
      try {
        // Get array of member IDs to add (not already in group)
        const currentIds = new Set(props.groupMembers.map((m: any) => m.id));
        const addIds = Object.keys(selectedMembersToAdd.value)
          .map(Number)
          .filter(id => !currentIds.has(id));

        await axios.post(`${apiBaseUrl}/api/message/manage_chat`, {
          chats_id: props.chatId,
          title: editedName.value,
          aAddIDs: addIds
        }, {
          headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
        });
        
        emit('refresh');
        close();
      } catch (e: any) {
        errorMessage.value = e.response?.data?.error || "Server error.";
      } finally {
        isSaving.value = false;
      }
    }

    async function deleteChat() {
      isSaving.value = true;
      errorMessage.value = '';
      
      try {
        await axios.post(`${apiBaseUrl}/api/message/delete_chat`, {
          chats_id: props.chatId
        }, {
          headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
        });
        
        emit('delete');
        close();
      } catch (e: any) {
        errorMessage.value = e.response?.data?.error || "Server error.";
      } finally {
        isSaving.value = false;
      }
    }

    async function removeMember(memberId: number) {
      isSaving.value = true;
      errorMessage.value = '';
      
      try {
        await axios.post(`${apiBaseUrl}/api/message/manage_chat`, {
          chats_id: props.chatId,
          aDelIDs: [memberId]
        }, {
          headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
        });
        
        emit('refresh');
        close();
      } catch (e: any) {
        errorMessage.value = e.response?.data?.error || "Server error.";
      } finally {
        isSaving.value = false;
      }
    }

    // Render UserPicker and RemoveMembersSheet components when needed
    return () => (
      <>
        <div class="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-center justify-center">
          <div class="bg-white rounded-xl shadow-2xl p-6 w-full max-w-md space-y-6 max-h-[90vh] overflow-y-auto">
            <div class="flex items-center justify-between mb-2">
              <h2 class="font-bold text-lg">Edit Group</h2>
              <button type="button" onClick={close} class="text-green-600 font-semibold hover:underline focus:outline-none">
                Cancel
              </button>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Group Name</label>
              <input v-model={editedName.value} type="text" class="form-input" />
            </div>
            
            <div class="space-y-2">
              <div class="flex justify-between items-center">
                <h3 class="font-medium">Members</h3>
              </div>
              
              <div class="mt-2 flex gap-2 flex-wrap">
                {props.groupMembers.map((member: any) => (
                  <div class="flex items-center gap-2 bg-gray-100 rounded px-2 py-1" key={member.id}>
                    <GroupMemberAvatar name={member.name} photoURL={member.profilePicture} size={24} />
                    <span class="text-xs">{member.name}</span>
                  </div>
                ))}
                
                {/* Pending members to add */}
                {Object.entries(selectedMembersToAdd.value).map(([id, name]) => {
                  if (!props.groupMembers.some((m: any) => m.id === parseInt(id))) {
                    return (
                      <div class="flex items-center gap-2 bg-green-100 rounded px-2 py-1" key={id}>
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-500" viewBox="0 0 20 20" fill="currentColor">
                          <path d="M8 9a3 3 0 100-6 3 3 0 000 6zm0 2a6 6 0 016 6H2a6 6 0 016-6zm8-4a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z" />
                        </svg>
                        <span class="text-xs text-green-700">{name}</span>
                      </div>
                    );
                  }
                  return null;
                })}
              </div>
              
              <div class="flex justify-between mt-2">
                <button
                  type="button"
                  onClick={() => showAddMembersSheet.value = true}
                  class="text-green-600 text-sm flex items-center"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M8 9a3 3 0 100-6 3 3 0 000 6zm0 2a6 6 0 016 6H2a6 6 0 016-6zm8-4a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z" />
                  </svg>
                  Add to Chat
                </button>
                
                {props.groupMembers.length > 1 && (
                  <button
                    type="button"
                    onClick={() => showRemoveMembersSheet.value = true}
                    class="text-red-600 text-sm flex items-center"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M11 6a3 3 0 11-6 0 3 3 0 016 0zm3 11a6 6 0 00-12 0h12zm-1-9a1 1 0 00-2 0v2H9a1 1 0 000 2h2v2a1 1 0 002 0v-2h2a1 1 0 000-2h-2V8z" />
                    </svg>
                    Remove Member(s)
                  </button>
                )}
              </div>
            </div>
            
            <div class="space-y-3 mt-6">
              <button
                type="button"
                disabled={isSaving.value}
                class="w-full py-3 bg-green-600 text-white font-bold rounded-lg text-lg flex items-center justify-center transition-colors disabled:opacity-60"
                onClick={save}
              >
                {isSaving.value ? <span class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-2"></span> : null}
                Save Changes
              </button>
              
              {props.isCreator && (
                <button
                  type="button"
                  disabled={isSaving.value}
                  class="w-full py-3 bg-red-600 text-white font-bold rounded-lg text-lg flex items-center justify-center transition-colors disabled:opacity-60"
                  onClick={() => showDeleteAlert.value = true}
                >
                  Delete Group
                </button>
              )}
              
              {errorMessage.value && (
                <div class="text-red-600 bg-red-100 rounded-lg p-3 text-center text-sm">{errorMessage.value}</div>
              )}
            </div>
          </div>
        </div>

        {/* Add Members Sheet */}
        {showAddMembersSheet.value && (
          <NTWKUserPicker
            chatId={props.chatId}
            alreadySelected={[...props.groupMembers.map((m: any) => m.id), ...Object.keys(selectedMembersToAdd.value).map(Number)]}
            onSelect={(users) => {
              users.forEach(user => {
                selectedMembersToAdd.value[user.id] = user.fullName || 'User';
              });
              showAddMembersSheet.value = false;
            }}
            onCancel={() => showAddMembersSheet.value = false}
          />
        )}

        {/* Remove Members Sheet */}
        {showRemoveMembersSheet.value && (
          <RemoveMembersSheet
            members={props.groupMembers}
            onRemove={(member) => {
              removeMember(member.id);
              showRemoveMembersSheet.value = false;
            }}
            onCancel={() => showRemoveMembersSheet.value = false}
          />
        )}

        {/* Delete Confirmation */}
        {showDeleteAlert.value && (
          <div class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
            <div class="bg-white rounded-lg p-6 max-w-sm mx-auto">
              <h3 class="font-bold text-lg mb-4">Delete Group Chat?</h3>
              <p class="mb-6">This action cannot be undone.</p>
              <div class="flex gap-4 justify-end">
                <button
                  onClick={() => showDeleteAlert.value = false}
                  class="px-4 py-2 border rounded-lg"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    deleteChat();
                    showDeleteAlert.value = false;
                  }}
                  class="px-4 py-2 bg-red-600 text-white rounded-lg"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        )}
      </>
    );
  }
});

// NTWKUserPicker component
export const NTWKUserPicker = defineComponent({
  name: 'NTWKUserPicker',
  props: {
    chatId: { type: Number, required: true },
    alreadySelected: { type: Array, default: () => [] },
    onSelect: { type: Function, required: true },
    onCancel: { type: Function, required: true }
  },
  setup(props) {
    const users = ref<User[]>([]);
    const isLoading = ref(false);
    const errorMessage = ref('');
    const selectedUsers = ref<Set<number>>(new Set());
    const token = localStorage.getItem('jwtToken');
    const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

    // Fetch network users who aren't already in chat
    function fetchNTWKUsers() {
      isLoading.value = true;
      errorMessage.value = '';
      
      axios.get(`${apiBaseUrl}/api/user/members_of_my_network?not_in_chats_id=${props.chatId}`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      .then(res => {
        if (res.data.result) {
          users.value = res.data.result;
        }
      })
      .catch(e => {
        errorMessage.value = e.response?.data?.error || "Failed to load network users.";
      })
      .finally(() => {
        isLoading.value = false;
      });
    }

    function toggleUser(userId: number) {
      if (selectedUsers.value.has(userId)) {
        selectedUsers.value.delete(userId);
      } else {
        selectedUsers.value.add(userId);
      }
    }

    function handleDone() {
      const selected = users.value.filter(u => selectedUsers.value.has(u.id));
      props.onSelect(selected);
    }

    onMounted(fetchNTWKUsers);

    return () => (
      <div class="fixed inset-0 bg-black bg-opacity-30 z-50">
        <div class="bg-white h-full max-w-md mx-auto flex flex-col">
          <div class="flex items-center justify-between p-4 border-b">
            <button onClick={props.onCancel} class="text-gray-600">Cancel</button>
            <h2 class="font-bold">Your NTWK</h2>
            <button onClick={handleDone} class="text-green-600" disabled={selectedUsers.value.size === 0}>
              Done
            </button>
          </div>
          
          <div class="flex-1 overflow-y-auto">
            {isLoading.value ? (
              <div class="flex justify-center items-center h-full">
                <div class="animate-spin h-6 w-6 border-2 border-gray-500 border-t-transparent rounded-full"></div>
              </div>
            ) : (
              <div class="divide-y">
                {users.value.map(user => (
                  <div
                    key={user.id}
                    class="flex items-center p-4 hover:bg-gray-50 cursor-pointer"
                    onClick={() => toggleUser(user.id)}
                  >
                    <GroupMemberAvatar name={user.fullName || ''} photoURL={user.profilePictureURL} size={40} />
                    <span class="ml-3 flex-1">{user.fullName}</span>
                    <div class={`w-6 h-6 rounded-full border flex items-center justify-center ${selectedUsers.value.has(user.id) ? 'bg-green-500 border-green-500' : 'border-gray-300'}`}>
                      {selectedUsers.value.has(user.id) && (
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-white" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                      )}
                    </div>
                  </div>
                ))}
                {users.value.length === 0 && !isLoading.value && (
                  <div class="p-4 text-center text-gray-500">No users available to add</div>
                )}
              </div>
            )}
            {errorMessage.value && (
              <div class="p-4 text-red-600 text-center">{errorMessage.value}</div>
            )}
          </div>
        </div>
      </div>
    );
  }
});

// RemoveMembersSheet component
export const RemoveMembersSheet = defineComponent({
  name: 'RemoveMembersSheet',
  props: {
    members: { type: Array, required: true },
    onRemove: { type: Function, required: true },
    onCancel: { type: Function, required: true }
  },
  setup(props) {
    return () => (
      <div class="fixed inset-0 bg-black bg-opacity-30 z-50">
        <div class="bg-white h-full max-w-md mx-auto flex flex-col">
          <div class="flex items-center justify-between p-4 border-b">
            <button onClick={props.onCancel} class="text-gray-600">Cancel</button>
            <h2 class="font-bold">Remove Member(s)</h2>
            <div class="w-14"></div>
          </div>
          
          <div class="flex-1 overflow-y-auto divide-y">
            {props.members.map((member: GroupMember) => (
              <div key={member.id} class="p-4">
                <button
                  onClick={() => props.onRemove(member)}
                  class="flex items-center w-full text-left text-red-600"
                >
                  <GroupMemberAvatar name={member.name} photoURL={member.profilePicture} size={40} />
                  <span class="ml-3">{member.name}</span>
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }
});
</script>

<style scoped>
.form-input {
  @apply mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm;
}
</style>