<!--
  EditProfileComponent.vue (Reusable)
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <form @submit.prevent="saveProfile" class="space-y-4">
    <div v-if="!fromOnboarding" class="flex items-center justify-between mb-4">
      <button type="button" @click="cancel" class="text-green-600 font-bold" aria-label="Cancel Edit">Cancel</button>
      <h2 class="text-xl font-bold">Edit Profile</h2>
      <button type="submit" :disabled="isLoading" class="text-yellow-600 font-bold" aria-label="Save Profile">Save</button>
    </div>

    <div class="flex items-center space-x-4 mb-4">
        <label class="relative" aria-label="Edit Profile Image">
          <input type="file" accept="image/*" class="hidden" @change="onImageChange" />
          <img :src="profileImageUrl" class="w-24 h-24 rounded-full object-cover border" />
          <span class="absolute bottom-0 right-0 bg-white px-2 py-1 rounded text-xs border">+Edit</span>
        </label>
        <div>
          <div class="font-bold">{{ repTypeTitle }}</div>
          <div v-for="skill in selectedSkills" :key="skill.id" class="text-sm">{{ skill.title }}</div>
        </div>
      </div>
      <div class="flex space-x-2">
        <input v-model="firstName" type="text" placeholder="First Name" class="input" aria-label="First Name" />
        <input v-model="lastName" type="text" placeholder="Last Name" class="input" aria-label="Last Name" />
      </div>
      <input v-model="broadcast" type="text" placeholder="Broadcast (optional)" class="input" aria-label="Broadcast" />
      <div>
        <label class="font-bold">Rep Type</label>
        <select v-model="repType" class="input" aria-label="Rep Type">
          <option v-for="type in repTypes" :key="type.id" :value="type.id">{{ type.title }}</option>
        </select>
      </div>
      <input v-model="cityName" type="text" placeholder="Enter City (optional)" class="input" aria-label="City" />
      <div>
        <label class="font-bold">Select up to 3 Skills</label>
        <div v-if="skills.length === 0" class="text-gray-500">Loading skills...</div>
        <div v-else>
          <div v-for="skill in skills" :key="skill.id" class="flex items-center">
            <input
              type="checkbox"
              :value="skill"
              v-model="selectedSkills"
              :disabled="isSkillDisabled(skill)"
              :aria-label="`Select skill ${skill.title}`"
            />
            <span class="ml-2">{{ skill.title }}</span>
          </div>
          <div class="text-xs text-gray-500">{{ selectedSkills.length }} of 3 selected</div>
        </div>
      </div>
      <input v-model="otherSkill" type="text" placeholder="Other Skill (optional)" class="input" aria-label="Other Skill" />
      <div v-if="errorMessage" class="text-red-600 text-sm">{{ errorMessage }}</div>
      
      <button v-if="fromOnboarding" type="submit" :disabled="isLoading" class="w-full py-3 bg-green-600 text-white font-bold rounded-lg">
        Save & Continue
      </button>

      <button v-if="!fromOnboarding" type="button" @click="showDelete = true" class="w-full mt-4 text-red-600 font-bold" aria-label="Delete Profile">Delete Profile</button>
    
    <!-- Delete Modal and Toast remain the same -->
    <div v-if="showDelete" class="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center">
      <div class="bg-white p-6 rounded shadow">
        <div class="mb-4">Are you sure you want to delete your profile? This cannot be undone.</div>
        <button @click="deleteProfile" class="text-red-600 font-bold mr-4" aria-label="Confirm Delete">Delete</button>
        <button @click="showDelete = false" class="text-gray-600 font-bold" aria-label="Cancel Delete">Cancel</button>
      </div>
    </div>
    <div v-if="showToast" class="fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-red-600 text-white px-4 py-2 rounded shadow">
      {{ errorMessage }}
    </div>
  </form>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, computed } from 'vue'
import api from '../utils/api'
import { useRouter } from 'vue-router'

const props = defineProps({
  fromOnboarding: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['profile-saved'])

const router = useRouter()
const firstName = ref('')
const lastName = ref('')
const broadcast = ref('')
const repTypes = [
  { id: 1, title: 'Lead' },
  { id: 2, title: 'Member' },
  { id: 3, title: 'Other' }
]
const repType = ref(repTypes[0].id)
const cityName = ref('')
const skills = ref<{id:number, title:string}[]>([])
const selectedSkills = ref<{id:number, title:string}[]>([])
const otherSkill = ref('')
const profileImage = ref<File|null>(null)
const profileImageUrl = ref('/default-profile.png')
const isLoading = ref(false)
const errorMessage = ref('')
const showDelete = ref(false)
const showToast = ref(false)

const repTypeTitle = computed(() => {
  const found = repTypes.find(t => t.id === repType.value)
  return found ? found.title : ''
})

function isSkillDisabled(skill: {id: number}) {
  // Check if the skill is already selected
  const isSelected = selectedSkills.value.some(s => s.id === skill.id);
  // Disable if 3 skills are selected AND the current skill is NOT one of them
  return selectedSkills.value.length >= 3 && !isSelected;
}

watch(selectedSkills, (newVal, oldVal) => {
  // Prevent selecting more than 3 skills
  if (newVal.length > 3) {
    // Revert to the old value if a 4th skill is added
    selectedSkills.value = oldVal;
  }
});

function onImageChange(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (file) {
    profileImage.value = file
    profileImageUrl.value = URL.createObjectURL(file)
  }
}

async function fetchSkills() {
  try {
    // Corrected endpoint to match Swift/Python backend
    const res = await api.get('/api/user/get_skills')
    skills.value = res.data.result || []
  } catch (err) {
    console.error("Failed to fetch skills:", err);
  }
}

async function fetchProfile() {
  const onboardingComplete = localStorage.getItem('onboardingComplete') === 'true'
  const pendingUserId = localStorage.getItem('pendingUserId')
  const pendingFirstName = localStorage.getItem('pendingFirstName')
  const pendingLastName = localStorage.getItem('pendingLastName')

  if (pendingUserId && !onboardingComplete) {
    firstName.value = pendingFirstName || ''
    lastName.value = pendingLastName || ''
    return
  }
  try {
    const userId = localStorage.getItem('userId')
    const res = await api.get(`/api/user/profile?users_id=${userId}`)
    const user = res.data.result
    firstName.value = user.fname || ''
    lastName.value = user.lname || ''
    broadcast.value = user.broadcast || ''
    const foundType = repTypes.find(t => t.title === user.userType)
    repType.value = foundType ? foundType.id : repTypes[0].id
    cityName.value = user.city || ''
    // The backend sends an array of skill objects, which populates the v-model
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
    form.append('users_types_id', repType.value.toString())
    form.append('manual_city', cityName.value)
    form.append('other_skill', otherSkill.value)
    // This correctly maps the selected skills to a comma-separated string of IDs
    form.append('aSkills', selectedSkills.value.map(s => s.id).join(','))
    if (profileImage.value) form.append('profile_picture', profileImage.value)
    
    await api.post(
      '/api/user/edit',
      form,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    )
    
    if (props.fromOnboarding) {
      emit('profile-saved')
    } else {
      router.push('/profile')
    }
  } catch (err: any) {
    errorMessage.value = err.response?.data?.error || 'Failed to save profile.'
    showToast.value = true
    setTimeout(() => { showToast.value = false }, 3000)
  } finally {
    isLoading.value = false
  }
}

function cancel() {
  router.back()
}

async function deleteProfile() {
  // ... delete logic remains the same
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