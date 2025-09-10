<!--
  RegisterNewProfile.vue
//  Rep
//
//  Created by Adam Novak on 09.09.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-white flex flex-col justify-center">
    <form @submit.prevent="registerUser" class="max-w-md mx-auto p-6 space-y-4">
      <div class="flex justify-end text-sm">
        <span>Already have an account?</span>
        <button type="button" class="ml-2 text-green-600 font-bold" @click="goToLogin">Login</button>
      </div>
      <div class="flex justify-center mb-4">
        <img src="/REPLogo.png" alt="REP Logo" class="w-20 h-20 rounded-full shadow" />
      </div>
      <h2 class="text-xl font-bold mb-2">Create Account:</h2>
      <div class="flex space-x-2">
        <input v-model="firstName" type="text" placeholder="First Name" class="input" autocomplete="given-name" />
        <input v-model="lastName" type="text" placeholder="Last Name" class="input" autocomplete="family-name" />
      </div>
      <input v-model="email" type="email" placeholder="Email address" class="input" autocomplete="email" />
      <input v-model="password" type="password" placeholder="Password" class="input" autocomplete="new-password" />
      <input v-model="confirmPassword" type="password" placeholder="Confirm Password" class="input" autocomplete="new-password" />
      <input v-model="phone" type="tel" placeholder="Phone number (optional)" class="input" autocomplete="tel" />
      <div v-if="errorMessage" class="text-red-600 text-sm">{{ errorMessage }}</div>
      <button type="submit" :disabled="isLoading" class="w-full h-12 bg-green-600 text-white font-bold rounded-lg mt-2">
        <span v-if="isLoading">Registering...</span>
        <span v-else>Next</span>
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import axios from 'axios'
import { useRouter } from 'vue-router'

const firstName = ref('')
const lastName = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const phone = ref('')
const isLoading = ref(false)
const errorMessage = ref('')
const router = useRouter()

function goToLogin() {
  router.push('/login')
}

async function registerUser() {
  errorMessage.value = ''
  if (!firstName.value || !lastName.value || !email.value || !password.value) {
    errorMessage.value = 'Please fill in all required fields.'
    return
  }
  if (password.value !== confirmPassword.value) {
    errorMessage.value = 'Passwords do not match.'
    return
  }
  if (password.value.length < 6) {
    errorMessage.value = 'Password must be at least 6 characters.'
    return
  }
  isLoading.value = true
  try {
    const form = new FormData()
    form.append('fname', firstName.value)
    form.append('lname', lastName.value)
    form.append('email', email.value)
    form.append('password', password.value)
    if (phone.value) form.append('phone', phone.value)
    // Add other fields as needed

    const res = await axios.post(
      `${import.meta.env.VITE_API_BASE_URL || 'https://rep-june2025.onrender.com'}/api/user/register`,
      form,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    )
    // Success: store JWT and userId, set onboarding flags, navigate
    const { user, token } = res.data
    localStorage.setItem('jwtToken', token)
    localStorage.setItem('pendingUserId', user.id) // Use pendingUserId
    localStorage.setItem('isRegistered', 'true')
    localStorage.setItem('onboardingComplete', 'false')
    // Optionally store first/last name for onboarding
    localStorage.setItem('pendingFirstName', firstName.value)
    localStorage.setItem('pendingLastName', lastName.value)
    // Navigate to onboarding or main
    router.push('/onboarding')
  } catch (err: any) {
    if (err.response?.data?.error) {
      errorMessage.value = err.response.data.error
    } else {
      errorMessage.value = 'Registration failed. Please try again.'
    }
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped>
.input {
  @apply w-full px-4 py-3 rounded-lg border border-green-300 bg-gray-100 text-base mb-2 focus:outline-none focus:ring-2 focus:ring-green-400;
}
</style>