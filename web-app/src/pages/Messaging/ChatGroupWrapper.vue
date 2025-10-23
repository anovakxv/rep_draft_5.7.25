<!--
  ChatGroupWrapper.vue
  Wrapper component for Chat_Group that handles route params
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div v-if="!chatId" class="flex items-center justify-center h-screen p-4 text-center">
    <div>
      <p class="text-red-600 mb-4">Invalid chat ID</p>
      <button @click="handleBack" class="px-4 py-2 bg-green-600 text-white rounded-lg">Go Back</button>
    </div>
  </div>

  <Chat_Group
    v-else
    :chat-id="chatId"
    :current-user-id="currentUserId"
    @close="handleBack"
    @refresh-chats="emitRefresh"
  />
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import Chat_Group from './Chat_Group.vue';

const route = useRoute();
const router = useRouter();

const currentUserId = ref(Number(localStorage.getItem('userId')) || 0);
const token = ref(localStorage.getItem('jwtToken') || '');

const chatId = computed(() => Number(route.params.id) || 0);

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
  }
});
</script>
