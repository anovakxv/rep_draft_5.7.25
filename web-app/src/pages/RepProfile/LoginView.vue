<!--
  LoginView.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen flex flex-col lg:flex-row bg-white text-[#101828]">
    <AuthShowcase :shared-link="sharedLink" mode="login" />

    <main class="flex-1 min-w-0 flex flex-col">
      <!-- Desktop: sign-up link -->
      <div class="hidden lg:flex justify-end px-12 pt-[54px]">
        <p class="text-sm leading-5 text-[#475467]">
          New to Rep?
          <button type="button" class="auth-link" @click="goToRegister">Create an account</button>
        </p>
      </div>

      <div class="lg:flex-1 flex flex-col lg:items-center lg:justify-center px-6 pt-7 lg:px-12 lg:pt-0">
        <form class="w-full max-w-[400px] mx-auto lg:max-w-[360px] lg:mx-0 flex flex-col gap-6 lg:gap-7" novalidate @submit.prevent="login">
          <div class="flex flex-col gap-1 lg:gap-2">
            <h2 class="text-[22px] leading-7 lg:text-[28px] lg:leading-[34px] font-semibold tracking-[-0.01em]">Welcome back</h2>
            <p class="text-[15px] leading-[22px] text-[#475467]">
              {{ sharedLink ? `Log in to see ${sharedLink.name}.` : 'Log in to your Rep account.' }}
            </p>
          </div>

          <div v-if="error" role="alert" class="flex items-start gap-2.5 rounded-lg border border-[#fecdca] bg-[#fef3f2] px-3.5 py-3 text-[#b42318]">
            <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="shrink-0 mt-px" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <div class="min-w-0 text-sm leading-5">
              <p class="font-semibold">{{ error.title }}</p>
              <p v-if="error.kind === 'mismatch'">
                Check for typos, or
                <button type="button" class="font-semibold underline" @click="goToResetPassword">reset your password</button>.
              </p>
              <p v-else-if="error.detail">{{ error.detail }}</p>
            </div>
          </div>

          <div class="flex flex-col gap-4 lg:gap-[18px]">
            <div class="flex flex-col gap-1.5">
              <label for="login-email" class="auth-label">Email</label>
              <input
                id="login-email"
                v-model.trim="email"
                type="email"
                inputmode="email"
                autocomplete="email"
                placeholder="you@example.com"
                class="auth-input"
                :aria-invalid="invalidField === 'email'"
              />
            </div>

            <div class="flex flex-col gap-1.5">
              <div class="flex items-baseline justify-between gap-3">
                <label for="login-password" class="auth-label">Password</label>
                <button type="button" class="text-sm leading-5 font-medium text-[#006600] hover:text-[#004d00]" @click="goToResetPassword">Forgot password?</button>
              </div>
              <div class="relative">
                <input
                  id="login-password"
                  v-model="password"
                  :type="showPassword ? 'text' : 'password'"
                  autocomplete="current-password"
                  class="auth-input has-toggle"
                  :aria-invalid="invalidField === 'password'"
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
            </div>
          </div>

          <button type="submit" class="auth-primary" :disabled="isLoading">
            <svg v-if="isLoading" class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-opacity="0.3" stroke-width="3" /><path d="M21 12a9 9 0 00-9-9" stroke="currentColor" stroke-width="3" stroke-linecap="round" /></svg>
            {{ isLoading ? 'Logging in…' : 'Log in' }}
          </button>
        </form>
      </div>

      <!-- Phones: sign-up button pinned to the bottom -->
      <div class="lg:hidden mt-auto w-full max-w-[448px] mx-auto px-6 pt-10 pb-7 flex flex-col gap-4">
        <div class="flex items-center gap-3">
          <div class="flex-1 h-px bg-[#eaecf0]"></div>
          <span class="text-[13px] leading-[18px] text-[#667085]">New to Rep?</span>
          <div class="flex-1 h-px bg-[#eaecf0]"></div>
        </div>
        <button type="button" class="auth-secondary" @click="goToRegister">Create an account</button>
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
import { useRouter, useRoute } from 'vue-router'
import api from '@/pages/utils/api'
import AuthShowcase from '@/components/AuthShowcase.vue'
import { useSharedLink } from '@/pages/utils/authShowcase'

const router = useRouter()
const route = useRoute()
const email = ref('')

// Only allow internal paths — prevents open redirect via crafted returnTo
const safeReturnPath = (url: string | null | undefined): string => {
  if (!url) return '/main'
  return url.startsWith('/') && !url.startsWith('//') ? url : '/main'
}
const password = ref('')
const showPassword = ref(false)
const isLoading = ref(false)

interface LoginError {
  kind: 'mismatch' | 'other'
  title: string
  detail?: string
}
const error = ref<LoginError | null>(null)
const invalidField = ref<'email' | 'password' | null>(null)

const returnTo = typeof route.query.returnTo === 'string' ? route.query.returnTo : undefined
const sharedLink = useSharedLink(returnTo)

// Turns server and network failures into plain-English messages
function describeLoginError(err: any): LoginError {
  const status = err?.response?.status
  if (status === 401) return { kind: 'mismatch', title: "That email and password don't match." }
  if (status === 429) return { kind: 'other', title: 'Too many tries.', detail: 'Wait a minute, then try again.' }
  if (!status) return { kind: 'other', title: "Can't reach Rep right now.", detail: 'Check your connection and try again.' }
  return { kind: 'other', title: 'Something went wrong on our end.', detail: 'Try again in a moment.' }
}

async function login() {
  error.value = null
  invalidField.value = null
  if (!email.value || !password.value) {
    invalidField.value = !email.value ? 'email' : 'password'
    error.value = { kind: 'other', title: 'Enter your email and password.' }
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
    // Redirect to returnTo URL if provided, otherwise go to /main
    // Using replace() instead of push() to remove login page from browser history
    router.replace(safeReturnPath(returnTo))
  } catch (err: any) {
    error.value = describeLoginError(err)
    if (error.value.kind === 'mismatch') {
      invalidField.value = 'password'
      password.value = ''
    }
  } finally {
    isLoading.value = false
  }
}

function goToRegister() {
  // Preserve returnTo so a new account still lands where the visitor was headed
  router.push(returnTo ? { path: '/register', query: { returnTo } } : '/register')
}

function goToResetPassword() {
  router.push('/reset-password')
}
</script>

<style scoped src="./authForm.css"></style>
