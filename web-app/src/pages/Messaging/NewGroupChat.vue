<!--
  NewGroupChat.vue
  Create a new group chat
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="fixed inset-0 bg-gray-100 z-40 flex flex-col">
    <!-- Header -->
    <header class="h-14 shrink-0">
      <div class="max-w-2xl mx-auto flex items-center justify-between h-full px-4 bg-gray-50 border-b border-gray-200">
        <button @click="router.back()" class="text-green-600 font-semibold p-2 -ml-2">
          Cancel
        </button>
        <h1 class="font-bold text-lg">New Group Chat</h1>
        <button
          @click="createGroupChat"
          :disabled="!groupName.trim() || selectedMembers.length === 0 || isSaving"
          class="font-bold text-green-600 hover:text-green-700 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {{ isSaving ? 'Creating...' : 'Create' }}
        </button>
      </div>
    </header>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full"></div>
    </div>

    <!-- Error State -->
    <div v-else-if="errorMessage" class="flex-1 flex items-center justify-center p-4">
      <div class="text-center">
        <p class="text-red-600 mb-4">{{ errorMessage }}</p>
        <button @click="fetchNetworkMembers" class="px-4 py-2 bg-green-600 text-white rounded-lg">
          Retry
        </button>
      </div>
    </div>

    <!-- Form -->
    <div v-else class="flex-1 overflow-y-auto">
      <div class="max-w-2xl mx-auto p-4 space-y-6">
        <!-- Group Name Section -->
        <div class="bg-white rounded-lg p-4 border">
          <h2 class="font-semibold text-lg mb-3">Group Name</h2>
          <input
            v-model="groupName"
            type="text"
            placeholder="Enter group name..."
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
            maxlength="100"
          />
        </div>

        <!-- Members Section -->
        <div class="bg-white rounded-lg p-4 border">
          <h2 class="font-semibold text-lg mb-3">Members</h2>

          <!-- Selected Members -->
          <div v-if="selectedMembers.length > 0" class="mb-4 space-y-2">
            <div
              v-for="member in selectedMembers"
              :key="member.id"
              class="flex items-center justify-between p-3 bg-green-50 rounded-lg"
            >
              <div class="flex items-center gap-3">
                <div
                  v-if="member.profile_picture_url"
                  class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center overflow-hidden"
                >
                  <img :src="member.profile_picture_url" class="w-full h-full object-cover" alt="Profile" />
                </div>
                <div v-else class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white font-semibold">
                  {{ getInitials(member.full_name || 'U') }}
                </div>
                <span class="font-medium">{{ member.full_name || 'User' }}</span>
              </div>
              <button
                @click="removeMember(member.id)"
                class="text-red-600 hover:text-red-800"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          </div>

          <!-- Add Members Button -->
          <button
            @click="showMemberPicker = true"
            class="w-full py-3 border-2 border-dashed border-gray-300 rounded-lg text-green-600 font-semibold hover:border-green-600 hover:bg-green-50 transition"
          >
            + Add Members
          </button>

          <p class="text-sm text-gray-500 mt-2">
            Select at least one member to create the group chat
          </p>
        </div>
      </div>
    </div>

    <!-- Member Picker Modal -->
    <div
      v-if="showMemberPicker"
      @click="showMemberPicker = false"
      class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
    >
      <div
        @click.stop
        class="bg-white rounded-lg w-full max-w-md max-h-[80vh] flex flex-col"
      >
        <!-- Modal Header -->
        <div class="p-4 border-b flex justify-between items-center">
          <h3 class="font-bold text-lg">Add Members</h3>
          <button @click="showMemberPicker = false" class="text-gray-600 hover:text-gray-800">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Search -->
        <div class="p-4 border-b">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search network..."
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
          />
        </div>

        <!-- Member List -->
        <div class="flex-1 overflow-y-auto">
          <div
            v-for="user in filteredNetworkMembers"
            :key="user.id"
            @click="toggleMember(user)"
            class="p-4 border-b flex items-center justify-between cursor-pointer hover:bg-gray-50"
          >
            <div class="flex items-center gap-3">
              <div
                v-if="user.profile_picture_url"
                class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center overflow-hidden"
              >
                <img :src="user.profile_picture_url" class="w-full h-full object-cover" alt="Profile" />
              </div>
              <div v-else class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white font-semibold">
                {{ getInitials(user.full_name || 'U') }}
              </div>
              <span>{{ user.full_name || 'User' }}</span>
            </div>
            <div
              v-if="isSelected(user.id)"
              class="w-6 h-6 bg-green-600 rounded-full flex items-center justify-center"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-white" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
              </svg>
            </div>
          </div>
          <div v-if="filteredNetworkMembers.length === 0" class="p-8 text-center text-gray-500">
            No network members found
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="p-4 border-t">
          <button
            @click="showMemberPicker = false"
            class="w-full py-3 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import api from '@/pages/utils/api';

const router = useRouter();

interface User {
  id: number;
  full_name?: string;
  profile_picture_url?: string;
  fname?: string;
  lname?: string;
}

// State
const groupName = ref('');
const selectedMembers = ref<User[]>([]);
const networkMembers = ref<User[]>([]);
const isLoading = ref(true);
const isSaving = ref(false);
const errorMessage = ref<string | null>(null);
const showMemberPicker = ref(false);
const searchQuery = ref('');

// Computed
const filteredNetworkMembers = computed(() => {
  if (!searchQuery.value.trim()) return networkMembers.value;

  const query = searchQuery.value.toLowerCase();
  return networkMembers.value.filter(user =>
    (user.full_name || '').toLowerCase().includes(query)
  );
});

// Methods
function getInitials(name: string): string {
  const parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
  return name.substring(0, 2).toUpperCase();
}

function isSelected(userId: number): boolean {
  return selectedMembers.value.some(m => m.id === userId);
}

function toggleMember(user: User) {
  const index = selectedMembers.value.findIndex(m => m.id === user.id);
  if (index >= 0) {
    selectedMembers.value.splice(index, 1);
  } else {
    selectedMembers.value.push(user);
  }
}

function removeMember(userId: number) {
  const index = selectedMembers.value.findIndex(m => m.id === userId);
  if (index >= 0) {
    selectedMembers.value.splice(index, 1);
  }
}

async function fetchNetworkMembers() {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const res = await api.get('/api/user/members_of_my_network');
    networkMembers.value = res.data.result || [];
  } catch (err: any) {
    console.error('Failed to fetch network members:', err);
    errorMessage.value = 'Failed to load your network. Please try again.';
  } finally {
    isLoading.value = false;
  }
}

async function createGroupChat() {
  if (!groupName.value.trim() || selectedMembers.value.length === 0) return;

  isSaving.value = true;
  errorMessage.value = null;

  try {
    const currentUserId = Number(localStorage.getItem('userId')) || 0;
    const memberIds = selectedMembers.value.map(m => m.id);
    const allIds = [currentUserId, ...memberIds];

    const res = await api.post('/api/message/manage_chat', {
      title: groupName.value.trim(),
      aAddIDs: allIds
    });

    const newChatId = res.data.chats_id;

    // Dispatch event to refresh chat list
    document.dispatchEvent(new CustomEvent('refreshActiveChats'));

    // Navigate to the new group chat
    router.push(`/chat/group/${newChatId}`);
  } catch (err: any) {
    console.error('Failed to create group chat:', err);
    errorMessage.value = err.response?.data?.error || 'Failed to create group chat. Please try again.';
    isSaving.value = false;
  }
}

// Lifecycle
onMounted(() => {
  fetchNetworkMembers();
});
</script>
