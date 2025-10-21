<!--
  NewPassword.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen flex flex-col bg-white">
    <div class="max-w-md mx-auto w-full p-6">
      <h2 class="text-2xl font-bold text-center mt-8 mb-8">Reset Password</h2>

      <div v-if="isSent" class="space-y-6 text-center">
        <p class="text-gray-700">
          If an account exists for <span class="font-semibold">{{ email }}</span>, a reset link has been sent to your email.
        </p>
        <button
          @click="goToLogin"
          class="w-full py-3 bg-green-600 text-white font-bold rounded-lg mt-4"
        >
          Back to Login
        </button>
      </div>

      <form v-else @submit.prevent="sendReset" class="space-y-6">
        <input
          v-model="email"
          type="email"
          placeholder="Enter your email"
          autocomplete="email"
          class="w-full px-4 py-3 rounded-lg border border-gray-300 bg-gray-100 text-base mb-2 focus:outline-none focus:ring-2 focus:ring-green-400"
          :disabled="isLoading"
        />

        <div v-if="error" class="text-red-600 text-sm">{{ error }}</div>

        <button
          type="submit"
          :disabled="!email || isLoading"
          class="w-full py-3 font-bold rounded-lg"
          :class="(!email || isLoading) ? 'bg-gray-300 text-gray-500' : 'bg-green-600 text-white'"
        >
          <span v-if="isLoading">Sending...</span>
          <span v-else>Send Reset Link</span>
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../utils/api'

const router = useRouter()
const email = ref('')
const isSent = ref(false)
const isLoading = ref(false)
const error = ref('')

async function sendReset() {
  if (!email.value) return
  error.value = ''
  isLoading.value = true
  try {
    await api.post(
      '/api/user/forgot_password',
      { email: email.value },
      { headers: { 'Content-Type': 'application/json' } }
    )
    isSent.value = true
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
