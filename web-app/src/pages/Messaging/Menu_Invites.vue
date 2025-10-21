<!--
  Menu_Invites.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header -->
    <div class="flex items-center h-14 px-4 border-b bg-white shrink-0">
      <button @click="emit('close')" class="text-green-600 font-semibold p-2 -ml-2" aria-label="Back">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h1 class="font-bold text-lg flex-1 text-center truncate">Invitations</h1>
      <div class="w-10"></div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <span class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full"></span>
    </div>

    <!-- No Invites State -->
    <div v-else-if="pendingInvites.length === 0" class="flex-1 flex flex-col items-center justify-center gap-4">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none"/>
        <path stroke="currentColor" stroke-width="2" d="M8 12l2 2 4-4"/>
      </svg>
      <div class="text-xl text-gray-600">No pending invitations</div>
    </div>

    <!-- Invites List -->
    <div v-else class="flex-1 overflow-y-auto px-4 py-4">
      <div class="space-y-4">
        <InviteCard
          v-for="invite in pendingInvites"
          :key="invite.id"
          :invite="invite"
          @accept="acceptInvite(invite)"
          @decline="declineInvite(invite)"
        />
      </div>
    </div>

    <!-- Alert -->
    <div v-if="responseMessage" class="fixed bottom-6 left-1/2 transform -translate-x-1/2 bg-white border border-gray-300 rounded-lg shadow-lg px-6 py-3 text-center z-50">
      {{ responseMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, defineEmits } from 'vue';
import api from '@/pages/utils/api';

// --- Emits ---
const emit = defineEmits(['close', 'refresh-chats']);

// --- State ---
const pendingInvites = ref<GoalTeamInvite[]>([]);
const isLoading = ref(false);
const responseMessage = ref('');
let responseTimeout: number | null = null;

const userId = Number(localStorage.getItem('userId'));
const s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/";

// --- Models ---
interface GoalTeamInvite {
  id: number;
  goals_id: number;
  users_id1: number;
  users_id2: number;
  confirmed: number;
  read1: boolean;
  read2: boolean;
  timestamp?: string;
  goalTitle?: string;
  inviterName?: string;
  inviterPhotoURL?: string;
}

// --- Helpers ---
function inviterDisplayName(invite: GoalTeamInvite) {
  return invite.inviterName || "Someone";
}
function inviterProfilePictureURL(invite: GoalTeamInvite): string | null {
  if (!invite.inviterPhotoURL || invite.inviterPhotoURL === "") return null;
  if (invite.inviterPhotoURL.startsWith("http")) return invite.inviterPhotoURL;
  return s3BaseURL + invite.inviterPhotoURL;
}

// --- API Calls ---
async function fetchPendingInvites() {
  if (!userId) return;
  isLoading.value = true;
  try {
    const res = await api.get('/api/goals/pending_invites');
    const invites: GoalTeamInvite[] = res.data.invites || [];
    pendingInvites.value = invites.filter(inv => inv.confirmed === 0);
  } catch (e) {
    responseMessage.value = "Failed to load invites";
    if (responseTimeout) clearTimeout(responseTimeout);
    responseTimeout = window.setTimeout(() => responseMessage.value = '', 2000);
  } finally {
    isLoading.value = false;
  }
}

async function respondToInvite(goalId: number, action: "accept" | "decline") {
  if (!userId) return;
  isLoading.value = true;
  try {
    await api.patch(`/api/goals/${goalId}/team`, {
      action,
      users: [userId]
    });
    responseMessage.value = action === "accept" ? "You've joined the goal team!" : "Invite declined";
    // Refresh invites after action
    await fetchPendingInvites();
    emit('refresh-chats');
  } catch (e) {
    responseMessage.value = action === "accept" ? "Failed to accept invite" : "Failed to decline invite";
  } finally {
    isLoading.value = false;
    if (responseTimeout) clearTimeout(responseTimeout);
    responseTimeout = window.setTimeout(() => responseMessage.value = '', 2000);
  }
}

async function markAllInvitesRead() {
  if (!userId) return;
  try {
    await api.post('/api/goals/pending_invites/mark_read', {});
    // Refresh invites after marking as read
    await fetchPendingInvites();
  } catch (e) {
    // Optionally show error
  }
}

// --- Actions ---
function acceptInvite(invite: GoalTeamInvite) {
  respondToInvite(invite.goals_id, "accept");
}
function declineInvite(invite: GoalTeamInvite) {
  respondToInvite(invite.goals_id, "decline");
}

// --- Lifecycle ---
onMounted(() => {
  markAllInvitesRead();
});
onUnmounted(() => {
  if (responseTimeout) clearTimeout(responseTimeout);
});
</script>

<script lang="ts">
// InviteCard component
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'InviteCard',
  props: {
    invite: { type: Object, required: true }
  },
  emits: ['accept', 'decline'],
  setup(props, { emit }) {
    function inviterDisplayName(invite: any) {
      return invite.inviterName || "Someone";
    }
    function inviterProfilePictureURL(invite: any): string | null {
      if (!invite.inviterPhotoURL || invite.inviterPhotoURL === "") return null;
      if (invite.inviterPhotoURL.startsWith("http")) return invite.inviterPhotoURL;
      return "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/" + invite.inviterPhotoURL;
    }
    return () => (
      <div class="p-4 bg-white rounded-lg shadow flex flex-col gap-3" aria-label="Goal Team Invite">
        <div class="flex items-center gap-3">
          {inviterProfilePictureURL(props.invite)
            ? <img src={inviterProfilePictureURL(props.invite)} class="w-10 h-10 rounded-full object-cover" alt="Inviter profile" />
            : <div class="w-10 h-10 rounded-full bg-gray-300" aria-label="No profile image"></div>
          }
          <div class="flex-1">
            <div class="font-semibold">Goal Team Invite</div>
            <div class="text-sm text-gray-600 truncate">
              {inviterDisplayName(props.invite)} invited you to join '{props.invite.goalTitle || "a goal"}'
            </div>
          </div>
        </div>
        <div class="flex gap-3">
          <button
            class="flex-1 py-2 bg-green-600 text-white font-semibold rounded hover:bg-green-700 transition"
            onClick={() => emit('accept')}
            aria-label="Accept invite"
          >
            Accept
          </button>
          <button
            class="flex-1 py-2 bg-gray-100 text-black font-semibold rounded hover:bg-gray-200 transition"
            onClick={() => emit('decline')}
            aria-label="Decline invite"
          >
            Decline
          </button>
        </div>
      </div>
    );
  }
});
</script>