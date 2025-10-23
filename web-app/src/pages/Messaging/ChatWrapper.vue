<!--
  ChatWrapper.vue
  Wrapper component for Chat_Individual that handles route params and data fetching
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div v-if="isLoading" class="flex items-center justify-center h-screen">
    <div class="text-center">
      <svg class="animate-spin h-8 w-8 mx-auto mb-2 text-gray-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <p class="text-gray-600">Loading chat...</p>
    </div>
  </div>

  <div v-else-if="errorMessage" class="flex items-center justify-center h-screen p-4 text-center">
    <div>
      <p class="text-red-600 mb-4">{{ errorMessage }}</p>
      <button @click="handleBack" class="px-4 py-2 bg-green-600 text-white rounded-lg">Go Back</button>
    </div>
  </div>

  <Chat_Individual
    v-else-if="otherUser"
    :current-user-id="currentUserId"
    :other-user-id="otherUser.id"
    :other-user-name="otherUser.full_name || 'User'"
    :other-user-photo-u-r-l="otherUser.profile_picture_url"
    @close="handleBack"
    @refresh-chats="emitRefresh"
  />
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '@/pages/utils/api';
import Chat_Individual from './Chat_Individual.vue';

interface User {
  id: number;
  full_name?: string;  // Backend returns snake_case
  profile_picture_url?: string;  // Backend returns snake_case
}

const route = useRoute();
const router = useRouter();

const currentUserId = ref(Number(localStorage.getItem('userId')) || 0);
const token = ref(localStorage.getItem('jwtToken') || '');

const otherUser = ref<User | null>(null);
const isLoading = ref(true);
const errorMessage = ref<string | null>(null);

const otherUserId = computed(() => Number(route.params.id) || 0);

async function fetchOtherUser() {
  if (!otherUserId.value || !token.value) {
    errorMessage.value = 'Invalid user ID or session expired';
    isLoading.value = false;
    return;
  }

  try {
    const res = await api.get(`/api/user/profile?users_id=${otherUserId.value}`);

    if (res.data && res.data.result) {
      otherUser.value = res.data.result;
    } else {
      errorMessage.value = 'User not found';
    }
  } catch (err: any) {
    if (err.response?.status === 401 || err.response?.status === 403) {
      errorMessage.value = 'Session expired. Please log in again.';
      router.push('/login');
    } else {
      errorMessage.value = err.response?.data?.error || 'Failed to load user information';
    }
  } finally {
    isLoading.value = false;
  }
}

function handleBack() {
  const fromTab = route.query.from;
  if (fromTab) {
    router.push({ path: '/main', query: { tab: fromTab } });
  } else {
    router.push({ path: '/main', query: { tab: 'chats' } });
  }
}

function emitRefresh() {
  // Dispatch custom event for MainScreen to refresh chats
  document.dispatchEvent(new CustomEvent('refreshActiveChats'));
}

onMounted(() => {
  if (!currentUserId.value || !token.value) {
    router.push('/login');
    return;
  }

  fetchOtherUser();
});
</script>
