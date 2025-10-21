<!--
  LoginView.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen flex flex-col bg-white">
    <div class="max-w-md mx-auto w-full p-6">
      <!-- Header -->
      <div class="mb-8">
        <h2 class="text-3xl font-bold mb-2">Welcome Back,</h2>
        <p class="text-gray-500">Sign in to continue</p>
      </div>

      <!-- Login Form -->
      <form @submit.prevent="login" class="space-y-6">
        <input
          v-model="email"
          type="email"
          placeholder="Email"
          autocomplete="email"
          class="w-full border focus:outline-none focus:ring-2 focus:ring-green-400 mb-2 text-base bg-gray-100 rounded-lg"
        />
        <input
          v-model="password"
          type="password"
          placeholder="Password"
          autocomplete="current-password"
          class="w-full border focus:outline-none focus:ring-2 focus:ring-green-400 mb-2 text-base bg-gray-100 rounded-lg"
        />

        <div v-if="error" class="text-red-600 text-sm">{{ error }}</div>

        <button
          type="submit"
          :disabled="isLoading || !email || !password"
          class="w-full py-3 font-bold rounded-lg"
          :class="(isLoading || !email || !password) ? 'bg-gray-300 text-gray-500' : 'bg-green-600 text-white'"
        >
          <span v-if="isLoading">Logging in...</span>
          <span v-else>Login</span>
        </button>

        <div class="flex justify-end mt-2">
          <button
            type="button"
            @click="goToResetPassword"
            class="text-blue-600 underline text-sm"
          >
            Forgot Password?
          </button>
        </div>
      </form>

      <!-- Sign Up Link -->
      <div class="mt-8 text-center">
        <span>New?</span>
        <button
          type="button"
          @click="goToRegister"
          class="font-bold text-green-600 ml-2"
        >
          Sign Up
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import api from '@/pages/utils/api'

const router = useRouter()
const route = useRoute()
const email = ref('')
const password = ref('')
const isLoading = ref(false)
const error = ref('')

async function login() {
  error.value = ''
  if (!email.value || !password.value) {
    error.value = 'Please enter your email and password.'
    return
  }
  isLoading.value = true
  try {
    const res = await api.post(
      '/api/user/login',
      { email: email.value, password: password.value }
    )
    const { result, token } = res.data
    // Store user info and onboarding flags
    localStorage.setItem('userId', result.id)
    localStorage.setItem('jwtToken', token)
    localStorage.setItem('isRegistered', 'true')
    localStorage.setItem('onboardingComplete', 'true')
    // Store admin flag (matches Swift iOS app behavior)
    localStorage.setItem('isAdmin', result.user_type === 'Admin' ? 'true' : 'false')

    // Redirect to returnTo URL if provided, otherwise go to /main
    const returnTo = route.query.returnTo as string
    router.push(returnTo || '/main')
  } catch (err: any) {
    error.value =
      err.response?.data?.error ||
      err.message ||
      'Network error. Please try again.'
  } finally {
    isLoading.value = false
  }
}

function goToRegister() {
  router.push('/register')
}

function goToResetPassword() {
  router.push('/reset-password')
}
</script>

<style scoped>
/* Remove .input CSS class from <style> block */
</style>