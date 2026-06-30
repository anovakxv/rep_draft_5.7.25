//  ContactUs.vue
//  Rep
//
//  Public support / contact page. Linked as the App Store "Support URL"
//  (https://www.repsomething.com/contact-us).
//  Intake form posts to POST /api/contact (added separately); a direct-email
//  fallback is always shown so the page is never a dead end.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

<template>
  <div class="min-h-screen bg-white flex flex-col items-center px-4 py-10">
    <div class="max-w-xl w-full">
      <!-- Header -->
      <div class="text-center mb-6">
        <h1 class="text-3xl font-bold mb-1" style="color: #8cc65d;">Rep</h1>
        <h2 class="text-2xl font-bold text-gray-900">Contact Us</h2>
        <p class="text-gray-700 mt-2">
          Have a question, ran into an issue, or need help with your account?
          Send us a message and we'll get back to you as soon as we can.
        </p>
      </div>

      <!-- Success state -->
      <div
        v-if="submitted"
        class="border rounded-lg p-6 text-center bg-gray-50 mb-6"
      >
        <p class="text-lg font-semibold mb-1" style="color: #006600;">Thanks — your message was sent.</p>
        <p class="text-gray-700 text-sm">
          We've received your message and will reply to <span class="font-semibold">{{ sentToEmail }}</span> soon.
        </p>
        <button
          class="mt-4 text-sm font-semibold underline"
          style="color: #8cc65d;"
          @click="resetForm"
        >
          Send another message
        </button>
      </div>

      <!-- Contact form -->
      <form v-else class="space-y-4" @submit.prevent="submitForm" novalidate>
        <div>
          <label class="block text-sm font-semibold text-gray-700 mb-1" for="cu-name">Name</label>
          <input
            id="cu-name"
            v-model.trim="name"
            type="text"
            autocomplete="name"
            class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2"
            :style="{ borderColor: '#e4e4e4' }"
            placeholder="Your name"
          />
        </div>

        <div>
          <label class="block text-sm font-semibold text-gray-700 mb-1" for="cu-email">Email</label>
          <input
            id="cu-email"
            v-model.trim="email"
            type="email"
            autocomplete="email"
            class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2"
            :style="{ borderColor: '#e4e4e4' }"
            placeholder="you@example.com"
          />
        </div>

        <div>
          <label class="block text-sm font-semibold text-gray-700 mb-1" for="cu-subject">Subject <span class="font-normal text-gray-400">(optional)</span></label>
          <input
            id="cu-subject"
            v-model.trim="subject"
            type="text"
            class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2"
            :style="{ borderColor: '#e4e4e4' }"
            placeholder="What's this about?"
          />
        </div>

        <div>
          <label class="block text-sm font-semibold text-gray-700 mb-1" for="cu-message">Message</label>
          <textarea
            id="cu-message"
            v-model.trim="message"
            rows="5"
            class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 resize-y"
            :style="{ borderColor: '#e4e4e4' }"
            placeholder="Tell us what's going on. Including the email on your Rep account and any error message helps us respond faster."
          ></textarea>
        </div>

        <p v-if="errorMsg" class="text-sm text-red-600">{{ errorMsg }}</p>

        <button
          type="submit"
          class="block w-full py-3 text-white font-bold rounded-lg disabled:opacity-60"
          style="background-color: #8cc65d;"
          :disabled="isSubmitting"
        >
          {{ isSubmitting ? 'Sending…' : 'Send Message' }}
        </button>
      </form>

      <!-- Direct email fallback (always available) -->
      <p class="text-center text-sm text-gray-600 mt-6">
        Prefer email? Reach us directly at
        <a :href="`mailto:${supportEmail}`" class="font-semibold" style="color: #006600;">{{ supportEmail }}</a>
      </p>

      <!-- Terms link -->
      <p class="text-center text-xs text-gray-500 mt-8">
        By contacting us you agree to our
        <router-link to="/terms" class="font-semibold underline" style="color: #8cc65d;">Terms of Use</router-link>.
      </p>

      <p class="text-center text-xs text-gray-400 mt-2">
        © {{ year }} Networked Capital Inc. · Rep
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import api from '@/pages/utils/api'

const supportEmail = 'contact@repsomething.com'
const year = new Date().getFullYear()

const name = ref('')
const email = ref('')
const subject = ref('')
const message = ref('')

const isSubmitting = ref(false)
const submitted = ref(false)
const errorMsg = ref('')
const sentToEmail = ref('')

function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
}

async function submitForm() {
  errorMsg.value = ''

  if (!name.value || !email.value || !message.value) {
    errorMsg.value = 'Please fill in your name, email, and message.'
    return
  }
  if (!isValidEmail(email.value)) {
    errorMsg.value = 'Please enter a valid email address so we can reply.'
    return
  }

  isSubmitting.value = true
  try {
    await api.post('/api/public/contact', {
      name: name.value,
      email: email.value,
      subject: subject.value,
      message: message.value,
    })
    sentToEmail.value = email.value
    submitted.value = true
  } catch (e: any) {
    errorMsg.value =
      e?.response?.data?.error ||
      `Sorry, something went wrong sending your message. Please email us directly at ${supportEmail}.`
  } finally {
    isSubmitting.value = false
  }
}

function resetForm() {
  name.value = ''
  email.value = ''
  subject.value = ''
  message.value = ''
  errorMsg.value = ''
  submitted.value = false
}
</script>

<style scoped>
input:focus,
textarea:focus {
  --tw-ring-color: #8cc65d;
  border-color: #8cc65d;
}
</style>
