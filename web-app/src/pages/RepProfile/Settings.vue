<!--
  Settings.vue (Reusable)
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-white flex flex-col">
    <div class="max-w-lg mx-auto w-full p-6">
      <h2 class="text-2xl font-bold mb-6 text-center">Settings</h2>
      <div class="space-y-8">

        <!-- Account Section -->
        <section>
          <h3 class="text-lg font-semibold mb-2 text-gray-700">Account</h3>
          <button @click="goToEditProfile" class="settings-row">
            <span class="icon"><svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><circle cx="12" cy="8" r="4"/><path d="M6 20c0-2 4-3 6-3s6 1 6 3"/></svg></span>
            Edit Profile
          </button>
        </section>

        <!-- Payments Section -->
        <section>
          <h3 class="text-lg font-semibold mb-2 text-gray-700">Payments</h3>
          <button @click="showPayments = true" class="settings-row">
            <span class="icon"><svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><rect x="2" y="7" width="20" height="10" rx="2"/><path d="M2 11h20"/></svg></span>
            Payment & Payouts
          </button>
        </section>

        <!-- Notifications Section -->
        <section>
          <h3 class="text-lg font-semibold mb-2 text-gray-700">Notifications</h3>
          <div class="settings-row">
            <span class="icon"><svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg></span>
            <label class="ml-2">
              <input type="checkbox" v-model="pushNotifications" class="mr-2" />
              Push Notifications
            </label>
          </div>
        </section>

        <!-- Legal Section -->
        <section>
          <h3 class="text-lg font-semibold mb-2 text-gray-700">Legal</h3>
          <button @click="goToTerms" class="settings-row">
            Terms of Use
          </button>
        </section>

        <!-- Logout Section -->
        <section>
          <button @click="logout" class="settings-row text-red-600 font-bold justify-center">
            Log Out
          </button>
        </section>
      </div>
    </div>

    <!-- Payments Modal -->
    <div v-if="showPayments" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h3 class="text-xl font-bold mb-4">Payments & Payouts</h3>
        <p class="mb-4">Connect your payment method and set up payouts. You’ll be able to submit and receive payments through Rep.</p>
        <button @click="statusMessage = 'Stripe setup coming soon.'" class="w-full py-2 mb-2 bg-gray-100 rounded">
          <span class="icon"><svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path d="M10 13v-2a2 2 0 114 0v2m-6 4h8a2 2 0 002-2V7a2 2 0 00-2-2H6a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg></span>
          Set Up Payments
        </button>
        <button @click="statusMessage = 'Open Stripe Dashboard (coming soon).'" class="w-full py-2 mb-2 bg-gray-100 rounded">
          <span class="icon"><svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path d="M14 3v4a1 1 0 001 1h4"/></svg></span>
          Manage Payouts
        </button>
        <div v-if="statusMessage" class="text-gray-500 mt-2">{{ statusMessage }}</div>
        <button @click="showPayments = false" class="w-full mt-4 py-2 bg-green-600 text-white rounded">Close</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const showPayments = ref(false)
const statusMessage = ref('')
const pushNotifications = ref(true) // stub, not persisted

function goToEditProfile() {
  router.push('/profile/edit')
}

function goToTerms() {
  router.push('/terms')
}

function logout() {
  localStorage.clear()
  router.push('/login')
}
</script>

<style scoped>
.settings-row {
  @apply flex items-center py-3 px-2 w-full text-lg rounded hover:bg-gray-100 transition cursor-pointer;
}
.icon {
  @apply mr-3 text-gray-500;
}
</style>