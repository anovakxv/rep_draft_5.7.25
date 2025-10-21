<!--
  NewPassword.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen flex flex-col bg-white">
    <div class="max-w-md mx-auto w-full p-6">
      <h2 class="text-2xl font-bold text-center mt-8 mb-8">Set New Password</h2>

      <div v-if="isSuccess" class="space-y-6 text-center">
        <p class="text-gray-700">Your password has been reset successfully.</p>
        <button
          @click="goToLogin"
          class="w-full py-3 bg-green-600 text-white font-bold rounded-lg"
        >
          Back to Login
        </button>
      </div>

      <form v-else @submit.prevent="setNewPassword" class="space-y-6">
        <input
          v-model="newPassword"
          type="password"
          placeholder="New Password"
          autocomplete="new-password"
          class="input"
          :disabled="isLoading"
        />
        <input
          v-model="confirmPassword"
          type="password"
          placeholder="Confirm Password"
          autocomplete="new-password"
          class="input"
          :disabled="isLoading"
        />

        <div v-if="error" class="text-red-600 text-sm">{{ error }}</div>

        <button
          type="submit"
          :disabled="isLoading || !newPassword || !confirmPassword"
          class="w-full py-3 font-bold rounded-lg"
          :class="(isLoading || !newPassword || !confirmPassword) ? 'bg-gray-300 text-gray-500' : 'bg-green-600 text-white'"
        >
          <span v-if="isLoading">Setting...</span>
          <span v-else>Set Password</span>
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '@/pages/utils/api'

const route = useRoute()
const router = useRouter()

const resetToken = route.query.hash || route.params.hash || ''
const newPassword = ref('')
const confirmPassword = ref('')
const isLoading = ref(false)
const error = ref('')
const isSuccess = ref(false)

async function setNewPassword() {
  error.value = ''
  if (!newPassword.value || !confirmPassword.value) return
  if (newPassword.value !== confirmPassword.value) {
    error.value = 'Passwords do not match.'
    return
  }
  isLoading.value = true
  try {
    await api.post(
      '/api/user/forgot_password',
      {
        hash: resetToken,
        new_password: newPassword.value
      }
    )
    isSuccess.value = true
  } catch (err: any) {
    error.value =
      err.response?.data?.error ||
      err.message ||
      'Network error. Please try again.'
  } finally {
    isLoading.value = false
  }
}

function goToLogin() {
  router.push('/login')
}
</script>

<style scoped>
.input {
  @apply w-full px-4 py-3 rounded-lg border border-gray-300 bg-gray-100 text-base mb-2 focus:outline-none focus:ring-2 focus:ring-green-400;
}
</style>