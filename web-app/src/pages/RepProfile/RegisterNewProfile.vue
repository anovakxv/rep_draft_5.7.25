<!--
  RegisterNewProfile.vue
//  Rep
//
//  Created by Adam Novak on 09.09.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen flex flex-col lg:flex-row bg-white text-[#101828]">
    <AuthShowcase :shared-link="sharedLink" mode="register" />

    <main class="flex-1 min-w-0 flex flex-col">
      <!-- Desktop: log-in link -->
      <div class="hidden lg:flex justify-end px-12 pt-[54px]">
        <p class="text-sm leading-5 text-[#475467]">
          Already have an account?
          <button type="button" class="auth-link" @click="goToLogin">Log in</button>
        </p>
      </div>

      <div class="lg:flex-1 flex flex-col lg:items-center lg:justify-center px-6 pt-7 lg:px-12 lg:pt-0">
        <form class="w-full max-w-[400px] mx-auto lg:max-w-[380px] lg:mx-0 flex flex-col gap-6" novalidate @submit.prevent="registerUser">
          <div class="flex flex-col gap-1 lg:gap-2">
            <h2 class="text-[22px] leading-7 lg:text-[28px] lg:leading-[34px] font-semibold tracking-[-0.01em]">Create your account</h2>
            <p class="text-[15px] leading-[22px] text-[#475467]">
              {{ sharedLink ? `Free to join. Then you can join ${sharedLink.name}.` : 'Free to join.' }}
            </p>
          </div>

          <div v-if="error" role="alert" class="flex items-start gap-2.5 rounded-lg border border-[#fecdca] bg-[#fef3f2] px-3.5 py-3 text-[#b42318]">
            <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="shrink-0 mt-px" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <div class="min-w-0 text-sm leading-5">
              <p class="font-semibold">{{ error.title }}</p>
              <p v-if="error.kind === 'exists'">
                <button type="button" class="font-semibold underline" @click="goToLogin">Log in instead</button>, or use a different email.
              </p>
              <p v-else-if="error.detail">{{ error.detail }}</p>
            </div>
          </div>

          <div class="flex flex-col gap-3.5">
            <div class="grid grid-cols-2 gap-3">
              <div class="flex flex-col gap-1.5 min-w-0">
                <label for="register-first-name" class="auth-label">First name</label>
                <input
                  id="register-first-name"
                  v-model.trim="firstName"
                  type="text"
                  autocomplete="given-name"
                  class="auth-input"
                  :aria-invalid="invalidFields.includes('firstName')"
                />
              </div>
              <div class="flex flex-col gap-1.5 min-w-0">
                <label for="register-last-name" class="auth-label">Last name</label>
                <input
                  id="register-last-name"
                  v-model.trim="lastName"
                  type="text"
                  autocomplete="family-name"
                  class="auth-input"
                  :aria-invalid="invalidFields.includes('lastName')"
                />
              </div>
            </div>

            <div class="flex flex-col gap-1.5">
              <label for="register-email" class="auth-label">Email</label>
              <input
                id="register-email"
                v-model.trim="email"
                type="email"
                inputmode="email"
                autocomplete="email"
                placeholder="you@example.com"
                class="auth-input"
                :aria-invalid="invalidFields.includes('email')"
              />
            </div>

            <div class="flex flex-col gap-1.5">
              <label for="register-password" class="auth-label">Password</label>
              <div class="relative">
                <input
                  id="register-password"
                  v-model="password"
                  :type="showPassword ? 'text' : 'password'"
                  autocomplete="new-password"
                  aria-describedby="register-password-hint"
                  class="auth-input has-toggle"
                  :aria-invalid="invalidFields.includes('password')"
                />
                <button
                  type="button"
                  class="auth-toggle"
                  :aria-label="showPassword ? 'Hide password' : 'Show password'"
                  :aria-pressed="showPassword"
                  @click="showPassword = !showPassword"
                >
                  <svg v-if="showPassword" width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" /></svg>
                  <svg v-else width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                </button>
              </div>
              <p
                id="register-password-hint"
                class="text-[13px] leading-[18px]"
                :class="invalidFields.includes('password') ? 'text-[#b42318]' : 'text-[#667085]'"
              >At least 6 characters</p>
            </div>
          </div>

          <div class="flex flex-col gap-3">
            <button type="submit" class="auth-primary" :disabled="isLoading">
              <svg v-if="isLoading" class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-opacity="0.3" stroke-width="3" /><path d="M21 12a9 9 0 00-9-9" stroke="currentColor" stroke-width="3" stroke-linecap="round" /></svg>
              {{ isLoading ? 'Creating your account…' : 'Create account' }}
            </button>
            <p class="text-[13px] leading-[18px] text-[#667085] text-center">Next, you'll set up your profile.</p>
          </div>
        </form>
      </div>

      <!-- Phones: log-in button pinned to the bottom -->
      <div class="lg:hidden mt-auto w-full max-w-[448px] mx-auto px-6 pt-10 pb-7 flex flex-col gap-4">
        <div class="flex items-center gap-3">
          <div class="flex-1 h-px bg-[#eaecf0]"></div>
          <span class="text-[13px] leading-[18px] text-[#667085]">Already have an account?</span>
          <div class="flex-1 h-px bg-[#eaecf0]"></div>
        </div>
        <button type="button" class="auth-secondary" @click="goToLogin">Log in</button>
        <nav class="flex justify-center gap-5 text-[13px] leading-[18px] text-[#667085]">
          <router-link to="/terms" class="hover:text-[#344054]">Terms</router-link>
          <router-link to="/contact-us" class="hover:text-[#344054]">Contact us</router-link>
        </nav>
      </div>

      <!-- Desktop: footer links -->
      <nav class="hidden lg:flex justify-center gap-5 px-12 pb-10 text-[13px] leading-[18px] text-[#667085]">
        <router-link to="/terms" class="hover:text-[#344054]">Terms</router-link>
        <router-link to="/contact-us" class="hover:text-[#344054]">Contact us</router-link>
      </nav>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import api from '../utils/api'
import { useRouter, useRoute } from 'vue-router'
import AuthShowcase from '@/components/AuthShowcase.vue'
import { useSharedLink } from '@/pages/utils/authShowcase'

type Field = 'firstName' | 'lastName' | 'email' | 'password'
interface RegisterError {
  kind: 'exists' | 'other'
  title: string
  detail?: string
}

const firstName = ref('')
const lastName = ref('')
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const isLoading = ref(false)
const error = ref<RegisterError | null>(null)
const invalidFields = ref<Field[]>([])
const router = useRouter()
const route = useRoute()

const returnTo = typeof route.query.returnTo === 'string' ? route.query.returnTo : undefined
const sharedLink = useSharedLink(returnTo)

function goToLogin() {
  // Preserve returnTo parameter when navigating to login
  if (returnTo) {
    router.push({ path: '/login', query: { returnTo } })
  } else {
    router.push('/login')
  }
}

// Turns server and network failures into plain-English messages
function describeRegisterError(err: any): RegisterError {
  const status = err?.response?.status
  const message = String(err?.response?.data?.error || '')
  if (status === 400 && /already exists/i.test(message)) {
    return { kind: 'exists', title: 'An account with this email already exists.' }
  }
  if (status === 400) return { kind: 'other', title: 'Some details need another look.', detail: 'Check each box and try again.' }
  if (status === 429) return { kind: 'other', title: 'Too many new accounts from this network.', detail: 'Try again in an hour.' }
  if (!status) return { kind: 'other', title: "Can't reach Rep right now.", detail: 'Check your connection and try again.' }
  return { kind: 'other', title: 'Something went wrong on our end.', detail: 'Try again in a moment.' }
}

function validate(): RegisterError | null {
  const missing: Field[] = []
  if (!firstName.value) missing.push('firstName')
  if (!lastName.value) missing.push('lastName')
  if (!email.value) missing.push('email')
  if (!password.value) missing.push('password')
  if (missing.length) {
    invalidFields.value = missing
    return { kind: 'other', title: 'Fill in your name, email and a password.' }
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value)) {
    invalidFields.value = ['email']
    return { kind: 'other', title: 'That email address doesn\'t look right.', detail: 'Check it and try again.' }
  }
  if (password.value.length < 6) {
    invalidFields.value = ['password']
    return { kind: 'other', title: 'Your password is too short.', detail: 'Use at least 6 characters.' }
  }
  return null
}

async function registerUser() {
  error.value = null
  invalidFields.value = []
  const problem = validate()
  if (problem) {
    error.value = problem
    return
  }
  isLoading.value = true
  try {
    const form = new FormData()
    form.append('fname', firstName.value)
    form.append('lname', lastName.value)
    form.append('email', email.value)
    form.append('password', password.value)

    const res = await api.post(
      '/api/user/register',
      form,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    )
    // Success: store JWT and userId, set onboarding flags, navigate
    const { user, token } = res.data
    localStorage.setItem('jwtToken', token)
    localStorage.setItem('pendingUserId', user.id) // Use pendingUserId for onboarding flow
    localStorage.setItem('userId', user.id) // Also set userId immediately for EditProfile
    localStorage.setItem('isRegistered', 'true')
    localStorage.setItem('onboardingComplete', 'false')
    // Optionally store first/last name for onboarding
    localStorage.setItem('pendingFirstName', firstName.value)
    localStorage.setItem('pendingLastName', lastName.value)

    // Store returnTo parameter if present (for post-onboarding redirect)
    if (returnTo) {
      localStorage.setItem('returnTo', returnTo)
    }

    // Navigate to onboarding
    // Using replace() instead of push() to remove registration page from browser history
    router.replace('/onboarding')
  } catch (err: any) {
    error.value = describeRegisterError(err)
    if (error.value.kind === 'exists') invalidFields.value = ['email']
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped src="./authForm.css"></style>
