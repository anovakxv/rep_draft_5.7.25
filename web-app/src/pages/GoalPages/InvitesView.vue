<!--
  InvitesView.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header -->
    <header class="sticky top-0 z-10 bg-white border-b border-gray-200 flex items-center h-14 px-4">
      <button @click="goBack" class="text-green-600 font-semibold">Back</button>
      <h1 class="font-bold text-lg flex-1 text-center">Goal Invitations</h1>
      <div class="w-12"></div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto">
      <LoadingSkeleton v-if="isLoading" type="list" :count="3" :size="48" variant="circle" />

      <ErrorState
        v-else-if="errorMessage"
        :message="errorMessage"
        show-retry
        :retrying="isLoading"
        @retry="fetchInvites"
      />

      <div v-else-if="invites.length === 0">
        <EmptyState
          title="No pending invitations"
          description="When someone invites you to join their goal team, it will appear here"
        >
          <template #icon>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </template>
        </EmptyState>
      </div>

      <div v-else class="divide-y">
        <div v-for="invite in invites" :key="invite.id" class="p-4 hover:bg-gray-50">
          <div class="flex items-start space-x-4">
            <!-- Inviter Avatar -->
            <img
              v-if="invite.inviterPhotoURL"
              :src="invite.inviterPhotoURL"
              class="w-12 h-12 rounded-full object-cover"
              alt="Inviter"
            />
            <div v-else class="w-12 h-12 rounded-full bg-gray-300 flex items-center justify-center text-white font-bold">
              {{ invite.inviterName?.substring(0, 2).toUpperCase() || '?' }}
            </div>

            <!-- Invite Details -->
            <div class="flex-1">
              <p class="font-semibold text-gray-800">
                {{ invite.inviterName || 'Someone' }} invited you to join a goal team
              </p>
              <p class="text-sm text-gray-600 mt-1">
                <span class="font-medium">{{ invite.goalTitle || 'Untitled Goal' }}</span>
              </p>
              <p class="text-xs text-gray-500 mt-1">
                {{ formatTimestamp(invite.timestamp) }}
              </p>

              <!-- Action Buttons -->
              <div class="flex gap-3 mt-3">
                <button
                  @click="respondToInvite(invite.id, true)"
                  :disabled="respondingTo === invite.id"
                  class="px-4 py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition disabled:opacity-60 flex items-center gap-2"
                >
                  <span v-if="respondingTo === invite.id" class="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full"></span>
                  Accept
                </button>
                <button
                  @click="respondToInvite(invite.id, false)"
                  :disabled="respondingTo === invite.id"
                  class="px-4 py-2 bg-gray-200 text-gray-800 font-semibold rounded-lg hover:bg-gray-300 transition disabled:opacity-60"
                >
                  Decline
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import api from '@/pages/utils/api';
import LoadingSkeleton from '@/components/LoadingSkeleton.vue';
import ErrorState from '@/components/ErrorState.vue';
import EmptyState from '@/components/EmptyState.vue';

interface Invite {
  id: number;
  goals_id: number;
  users_id1: number;
  users_id2: number;
  confirmed: string;
  read1: string;
  read2: string;
  timestamp: string;
  goalTitle?: string;
  inviterName?: string;
  inviterPhotoURL?: string;
}

const router = useRouter();
const userId = ref(Number(localStorage.getItem('userId')) || 0);

const invites = ref<Invite[]>([]);
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);
const respondingTo = ref<number | null>(null);

function goBack() {
  router.back();
}

async function fetchInvites() {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const res = await api.get('/api/goals/pending_invites');

    invites.value = res.data.invites || [];
  } catch (err: any) {
    if (err.response?.status === 401 || err.response?.status === 403) {
      errorMessage.value = "Session expired. Please log in again.";
      router.push('/login');
    } else {
      errorMessage.value = err.response?.data?.error || 'Failed to load invitations.';
    }
  } finally {
    isLoading.value = false;
  }
}

async function respondToInvite(inviteId: number, accept: boolean) {
  respondingTo.value = inviteId;

  // Find the invite to get goal_id
  const invite = invites.value.find(inv => inv.id === inviteId);
  if (!invite) return;

  try {
    // Backend route: PATCH /api/goals/{goal_id}/team
    // Expects: { action: 'accept'|'decline', users: [userId] }
    await api.patch(
      `/api/goals/${invite.goals_id}/team`,
      {
        action: accept ? 'accept' : 'decline',
        users: [userId.value]
      }
    );

    // Remove the invite from the list
    invites.value = invites.value.filter(inv => inv.id !== inviteId);

    // If accepted, optionally navigate to the goal
    if (accept) {
      setTimeout(() => {
        router.push(`/goal/${invite.goals_id}`);
      }, 500);
    }
  } catch (err: any) {
    if (err.response?.status === 401 || err.response?.status === 403) {
      router.push('/login');
    } else {
      alert(err.response?.data?.error || 'Failed to respond to invitation.');
    }
  } finally {
    respondingTo.value = null;
  }
}

function formatTimestamp(timestamp: string): string {
  if (!timestamp) return '';

  try {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);

    if (diffSec < 60) return 'just now';
    if (diffMin < 60) return `${diffMin} minute${diffMin > 1 ? 's' : ''} ago`;
    if (diffHour < 24) return `${diffHour} hour${diffHour > 1 ? 's' : ''} ago`;
    if (diffDay < 7) return `${diffDay} day${diffDay > 1 ? 's' : ''} ago`;

    return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
  } catch (e) {
    return timestamp;
  }
}

onMounted(() => {
  if (!userId.value) {
    router.push('/login');
    return;
  }

  fetchInvites();
});
</script>

<style scoped>
/* Additional styles if needed */
</style>
