<!--
  EditProfile.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->
  
<template>
  <div class="min-h-screen bg-white flex flex-col">
    <form @submit.prevent="saveProfile" class="max-w-lg mx-auto p-6 space-y-4">
      <div class="flex items-center justify-between mb-4">
        <button type="button" @click="cancel" class="text-green-600 font-bold">Cancel</button>
        <h2 class="text-xl font-bold">Edit Profile</h2>
        <button type="submit" :disabled="isLoading" class="text-yellow-600 font-bold">Save</button>
      </div>
      <div class="flex items-center space-x-4 mb-4">
        <label class="relative">
          <input type="file" accept="image/*" class="hidden" @change="onImageChange" />
          <img :src="profileImageUrl" class="w-24 h-24 rounded-full object-cover border" />
          <span class="absolute bottom-0 right-0 bg-white px-2 py-1 rounded text-xs border">+Edit</span>
        </label>
        <div>
          <div class="font-bold">{{ repType }}</div>
          <div v-for="skill in selectedSkills" :key="skill.id" class="text-sm">{{ skill.title }}</div>
        </div>
      </div>
      <div class="flex space-x-2">
        <input v-model="firstName" type="text" placeholder="First Name" class="input" />
        <input v-model="lastName" type="text" placeholder="Last Name" class="input" />
      </div>
      <input v-model="broadcast" type="text" placeholder="Broadcast (optional)" class="input" />
      <div>
        <label class="font-bold">Rep Type</label>
        <select v-model="repType" class="input">
          <option v-for="type in repTypes" :key="type" :value="type">{{ type }}</option>
        </select>
      </div>
      <input v-model="cityName" type="text" placeholder="Enter City (optional)" class="input" />
      <div>
        <label class="font-bold">Select up to 3 Skills</label>
        <div v-if="skills.length === 0" class="text-gray-500">Loading skills...</div>
        <div v-else>
          <div v-for="skill in skills" :key="skill.id" class="flex items-center">
            <input type="checkbox" :value="skill" v-model="selectedSkills" :disabled="isSkillDisabled(skill)" />
            <span class="ml-2">{{ skill.title }}</span>
          </div>
          <div class="text-xs text-gray-500">{{ selectedSkills.length }} of 3 selected</div>
        </div>
      </div>
      <input v-model="otherSkill" type="text" placeholder="Other Skill (optional)" class="input" />
      <div v-if="errorMessage" class="text-red-600 text-sm">{{ errorMessage }}</div>
      <button type="button" @click="showDelete = true" class="w-full mt-4 text-red-600 font-bold">Delete Profile</button>
    </form>
    <div v-if="showDelete" class="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center">
      <div class="bg-white p-6 rounded shadow">
        <div class="mb-4">Are you sure you want to delete your profile? This cannot be undone.</div>
        <button @click="deleteProfile" class="text-red-600 font-bold mr-4">Delete</button>
        <button @click="showDelete = false" class="text-gray-600 font-bold">Cancel</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { useRouter } from 'vue-router'

const firstName = ref('')
const lastName = ref('')
const broadcast = ref('')
const repType = ref('Lead')
const repTypes = ['Lead', 'Member', 'Other'] // Replace with your actual types
const cityName = ref('')
const skills = ref<{id:number, title:string}[]>([])
const selectedSkills = ref<{id:number, title:string}[]>([])
const otherSkill = ref('')
const profileImage = ref<File|null>(null)
const profileImageUrl = ref('/default-profile.png')
const isLoading = ref(false)
const errorMessage = ref('')
const showDelete = ref(false)
const router = useRouter()

function isSkillDisabled(skill) {
  return selectedSkills.value.length >= 3 && !selectedSkills.value.includes(skill)
}

function onImageChange(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (file) {
    profileImage.value = file
    profileImageUrl.value = URL.createObjectURL(file)
  }
}

async function fetchSkills() {
  try {
    const res = await axios.get(`${import.meta.env.VITE_API_BASE_URL}/api/user/skills`, {
      headers: { Authorization: `Bearer ${localStorage.getItem('jwtToken')}` }
    })
    skills.value = res.data.result || []
  } catch {}
}

async function fetchProfile() {
  try {
    const res = await axios.get(`${import.meta.env.VITE_API_BASE_URL}/api/user/profile?users_id=${localStorage.getItem('userId')}`, {
      headers: { Authorization: `Bearer ${localStorage.getItem('jwtToken')}` }
    })
    const user = res.data.result
    firstName.value = user.fname || ''
    lastName.value = user.lname || ''
    broadcast.value = user.broadcast || ''
    repType.value = user.userType || 'Lead'
    cityName.value = user.city || ''
    selectedSkills.value = user.skills || []
    otherSkill.value = user.other_skill || ''
    profileImageUrl.value = user.profile_picture_url || '/default-profile.png'
  } catch {}
}

async function saveProfile() {
  errorMessage.value = ''
  isLoading.value = true
  try {
    const form = new FormData()
    form.append('fname', firstName.value)
    form.append('lname', lastName.value)
    form.append('broadcast', broadcast.value)
    form.append('users_types_id', repType.value)
    form.append('manual_city', cityName.value)
    form.append('other_skill', otherSkill.value)
    form.append('aSkills', selectedSkills.value.map(s => s.id).join(','))
    if (profileImage.value) form.append('profile_picture', profileImage.value)
    const res = await axios.post(
      `${import.meta.env.VITE_API_BASE_URL}/api/user/edit`,
      form,
      { headers: { 'Content-Type': 'multipart/form-data', Authorization: `Bearer ${localStorage.getItem('jwtToken')}` } }
    )
    // Optionally handle response
    router.push('/profile')
  } catch (err: any) {
    errorMessage.value = err.response?.data?.error || 'Failed to save profile.'
  } finally {
    isLoading.value = false
  }
}

function cancel() {
  router.back()
}

async function deleteProfile() {
  isLoading.value = true
  try {
    await axios.post(
      `${import.meta.env.VITE_API_BASE_URL}/api/user/delete`,
      {},
      { headers: { Authorization: `Bearer ${localStorage.getItem('jwtToken')}` } }
    )
    localStorage.clear()
    router.push('/register')
  } catch {
    errorMessage.value = 'Failed to delete profile.'
  } finally {
    isLoading.value = false
    showDelete.value = false
  }
}

onMounted(() => {
  fetchSkills()
  fetchProfile()
})
</script>

<style scoped>
.input {
  @apply w-full px-4 py-3 rounded-lg border border-green-300 bg-gray-100 text-base mb-2 focus:outline-none focus:ring-2 focus:ring-green-400;
}
</style>
