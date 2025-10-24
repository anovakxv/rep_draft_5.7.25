<!--
  InviteTeamSheet.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-end justify-center">
    <div class="bg-white rounded-t-xl w-full max-w-md h-[80vh] flex flex-col">
      <!-- Header -->
      <div class="flex items-center justify-between p-4 border-b shrink-0">
        <button @click="emit('close')" class="text-green-600 font-semibold">
          Cancel
        </button>
        <h2 class="font-bold text-lg">Invite to Team</h2>
        <button
          @click="inviteUsers"
          :disabled="selectedUsers.size === 0 || isLoading"
          class="text-green-600 font-semibold disabled:opacity-50"
        >
          Invite
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="flex-1 flex items-center justify-center">
        <div class="flex flex-col items-center gap-3">
          <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full"></div>
          <div class="text-gray-600">{{ loadingMessage }}</div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else-if="users.length === 0" class="flex-1 flex items-center justify-center">
        <div class="text-gray-500 text-center px-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto mb-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
          <p>No network members found</p>
        </div>
      </div>

      <!-- User List -->
      <div v-else class="flex-1 overflow-y-auto">
        <div
          v-for="user in users"
          :key="user.id"
          @click="toggleUser(user.id)"
          class="flex items-center gap-3 p-4 hover:bg-gray-50 cursor-pointer transition-colors border-b border-gray-100 last:border-b-0"
        >
          <!-- Profile Picture -->
          <img
            v-if="user.profile_picture_url"
            :src="user.profile_picture_url"
            class="w-10 h-10 rounded-full object-cover"
            :alt="user.full_name"
          />
          <div
            v-else
            class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
            </svg>
          </div>

          <!-- User Name -->
          <div class="flex-1 font-medium">
            {{ user.full_name || 'User' }}
          </div>

          <!-- Checkmark -->
          <svg
            v-if="selectedUsers.has(user.id)"
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6 text-green-600"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
          </svg>
        </div>
      </div>

      <!-- Success Message -->
      <div
        v-if="inviteSuccess"
        class="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center z-10"
      >
        <div class="bg-white rounded-lg p-6 max-w-sm mx-4">
          <h3 class="text-lg font-bold mb-2">Invitation Sent</h3>
          <p class="text-gray-600 mb-4">Team invitation has been sent successfully.</p>
          <button
            @click="handleSuccess"
            class="w-full py-2 bg-green-600 text-white rounded font-semibold hover:bg-green-700 transition"
          >
            OK
          </button>
        </div>
      </div>

      <!-- Error Message -->
      <div
        v-if="errorMessage"
        class="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center z-10"
      >
        <div class="bg-white rounded-lg p-6 max-w-sm mx-4">
          <h3 class="text-lg font-bold mb-2 text-red-600">Error</h3>
          <p class="text-gray-600 mb-4">{{ errorMessage }}</p>
          <button
            @click="errorMessage = ''"
            class="w-full py-2 bg-gray-200 text-gray-700 rounded font-semibold hover:bg-gray-300 transition"
          >
            OK
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/pages/utils/api'

interface User {
  id: number
  full_name?: string  // Backend returns this
  fname?: string
  lname?: string
  profile_picture_url?: string  // Backend returns this
}

const props = defineProps<{
  goalId: number
}>()

const emit = defineEmits(['done', 'close'])

// State
const users = ref<User[]>([])
const selectedUsers = ref<Set<number>>(new Set())
const isLoading = ref(false)
const loadingMessage = ref('Loading...')
const errorMessage = ref('')
const inviteSuccess = ref(false)

const s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

// Methods
function toggleUser(userId: number) {
  if (selectedUsers.value.has(userId)) {
    selectedUsers.value.delete(userId)
  } else {
    selectedUsers.value.add(userId)
  }
  // Trigger reactivity
  selectedUsers.value = new Set(selectedUsers.value)
}

function patchProfilePictureURL(user: User): string | undefined {
  const url = user.profile_picture_url
  if (!url || url.trim() === '') return undefined
  if (url.startsWith('http')) return url
  return s3BaseURL + url
}

async function loadNetworkMembers() {
  isLoading.value = true
  loadingMessage.value = 'Loading...'
  errorMessage.value = ''

  try {
    const res = await api.get(
      `/api/user/members_of_my_network?invited_goal_id=${props.goalId}`
    )

    const rawUsers = res.data.result || []

    // Map users and patch profile picture URLs
    users.value = rawUsers.map((user: any) => ({
      ...user,
      full_name: user.full_name || (user.fname && user.lname ? `${user.fname} ${user.lname}` : user.fname || user.lname || 'User'),
      profile_picture_url: patchProfilePictureURL(user)
    }))
  } catch (err: any) {
    console.error('Failed to load network members:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to load network members'
  } finally {
    isLoading.value = false
  }
}

async function inviteUsers() {
  if (selectedUsers.value.size === 0) return

  isLoading.value = true
  loadingMessage.value = 'Sending invitations...'
  errorMessage.value = ''

  try {
    await api.post(
      `/api/goals/${props.goalId}/team`,
      {
        users: Array.from(selectedUsers.value)
      }
    )

    inviteSuccess.value = true
    console.log('[InviteTeamSheet] Invites sent successfully to users:', Array.from(selectedUsers.value))
  } catch (err: any) {
    console.error('Failed to invite users:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to send invitations'
  } finally {
    isLoading.value = false
  }
}

function handleSuccess() {
  inviteSuccess.value = false
  emit('done')
  emit('close')
}

// Lifecycle
onMounted(() => {
  loadNetworkMembers()
})
</script>

<style scoped>
/* Smooth transitions */
.transition-colors {
  transition: background-color 0.2s ease;
}
</style>
