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
            <label class="flex-1 flex items-center cursor-pointer">
              <input type="checkbox" v-model="notificationSettings.pushNotificationsEnabled" @change="saveNotificationSettings" class="mr-2 w-5 h-5" />
              <span>Push Notifications</span>
            </label>
          </div>
          <div v-if="notificationSettings.pushNotificationsEnabled" class="ml-8 space-y-2 mt-2">
            <label class="flex items-center cursor-pointer py-2">
              <input type="checkbox" v-model="notificationSettings.notifDirectMessages" @change="saveNotificationSettings" class="mr-2 w-4 h-4" />
              <span class="text-gray-700">Direct Messages</span>
            </label>
            <label class="flex items-center cursor-pointer py-2">
              <input type="checkbox" v-model="notificationSettings.notifGroupMessages" @change="saveNotificationSettings" class="mr-2 w-4 h-4" />
              <span class="text-gray-700">Group Messages</span>
            </label>
            <label class="flex items-center cursor-pointer py-2">
              <input type="checkbox" v-model="notificationSettings.notifGoalInvites" @change="saveNotificationSettings" class="mr-2 w-4 h-4" />
              <span class="text-gray-700">Goal Team Invites</span>
            </label>
          </div>
        </section>

        <!-- Account Actions Section -->
        <section>
          <h3 class="text-lg font-semibold mb-2 text-gray-700">Account</h3>
          <button @click="showPasswordModal = true" class="settings-row">
            <span class="icon"><svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"/></svg></span>
            Change Password
          </button>
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
    <div v-if="showPayments" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h3 class="text-xl font-bold mb-4">Payments & Payouts</h3>
        <p class="mb-4">Manage your payment methods, view transaction history, and set up payouts.</p>
        <button @click="goToPayments" class="w-full py-3 mb-2 bg-green-600 text-white rounded font-semibold hover:bg-green-700 transition">
          <span class="icon"><svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 inline mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path d="M10 13v-2a2 2 0 114 0v2m-6 4h8a2 2 0 002-2V7a2 2 0 00-2-2H6a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg></span>
          View Payments Page
        </button>
        <button @click="showPayments = false" class="w-full mt-2 py-2 bg-gray-200 text-gray-700 rounded font-semibold hover:bg-gray-300 transition">Close</button>
      </div>
    </div>

    <!-- Change Password Modal -->
    <div v-if="showPasswordModal" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h3 class="text-xl font-bold mb-4">Change Password</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-semibold mb-1">Current Password</label>
            <input
              v-model="passwordForm.currentPassword"
              type="password"
              class="w-full px-4 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="Enter current password"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold mb-1">New Password</label>
            <input
              v-model="passwordForm.newPassword"
              type="password"
              class="w-full px-4 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="Enter new password"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold mb-1">Confirm New Password</label>
            <input
              v-model="passwordForm.confirmPassword"
              type="password"
              class="w-full px-4 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="Confirm new password"
            />
          </div>
          <div v-if="passwordError" class="text-red-600 text-sm">{{ passwordError }}</div>
          <div class="flex space-x-3">
            <button @click="handleChangePassword" :disabled="isChangingPassword" class="flex-1 py-3 bg-green-600 text-white rounded font-semibold hover:bg-green-700 transition">
              {{ isChangingPassword ? 'Changing...' : 'Change Password' }}
            </button>
            <button @click="closePasswordModal" class="flex-1 py-3 bg-gray-200 text-gray-700 rounded font-semibold hover:bg-gray-300 transition">
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Success Message Modal -->
    <div v-if="successMessage" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h3 class="text-xl font-bold mb-4 text-green-600">Success</h3>
        <p class="mb-6">{{ successMessage }}</p>
        <button @click="successMessage = ''" class="w-full py-3 bg-green-600 text-white rounded font-semibold hover:bg-green-700 transition">OK</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/pages/utils/api'

const router = useRouter()
const showPayments = ref(false)
const showPasswordModal = ref(false)
const isChangingPassword = ref(false)
const passwordError = ref('')
const successMessage = ref('')

// Notification settings
const notificationSettings = ref({
  pushNotificationsEnabled: true,
  notifDirectMessages: true,
  notifGroupMessages: true,
  notifGoalInvites: true,
})

// Password form
const passwordForm = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: '',
})

function goToEditProfile() {
  router.push('/profile/edit')
}

function goToTerms() {
  router.push('/terms')
}

function goToPayments() {
  showPayments.value = false
  router.push({ name: 'Payments' })
}

function logout() {
  localStorage.clear()
  router.push('/login')
}

function loadNotificationSettings() {
  // Load from localStorage
  const saved = localStorage.getItem('notificationSettings')
  if (saved) {
    try {
      notificationSettings.value = JSON.parse(saved)
    } catch (e) {
      console.error('Failed to parse notification settings:', e)
    }
  }
}

async function saveNotificationSettings() {
  // Save to localStorage
  localStorage.setItem('notificationSettings', JSON.stringify(notificationSettings.value))

  // Save to backend
  try {
    await api.patch(
      '/api/user/notification_settings',
      notificationSettings.value
    )
  } catch (err: any) {
    console.error('Failed to save notification settings:', err)
  }
}

function closePasswordModal() {
  showPasswordModal.value = false
  passwordForm.value = {
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  }
  passwordError.value = ''
}

async function handleChangePassword() {
  passwordError.value = ''

  // Validation
  if (!passwordForm.value.currentPassword || !passwordForm.value.newPassword || !passwordForm.value.confirmPassword) {
    passwordError.value = 'All fields are required.'
    return
  }

  if (passwordForm.value.newPassword !== passwordForm.value.confirmPassword) {
    passwordError.value = 'New passwords do not match.'
    return
  }

  if (passwordForm.value.newPassword.length < 6) {
    passwordError.value = 'New password must be at least 6 characters.'
    return
  }

  isChangingPassword.value = true

  try {
    await api.post(
      '/api/user/edit',
      {
        password: passwordForm.value.newPassword
      }
    )

    successMessage.value = 'Password changed successfully!'
    closePasswordModal()
  } catch (err: any) {
    console.error('Change password error:', err)
    passwordError.value = err.response?.data?.error || err.message || 'Failed to change password. Please try again.'
  } finally {
    isChangingPassword.value = false
  }
}

onMounted(() => {
  loadNotificationSettings()
})
</script>

<style scoped>
.settings-row {
  @apply flex items-center py-3 px-2 w-full text-lg rounded hover:bg-gray-100 transition cursor-pointer;
}
.icon {
  @apply mr-3 text-gray-500;
}
</style>