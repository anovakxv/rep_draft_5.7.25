<!--
  EditProfileComponent.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="edit-profile-component bg-white min-h-screen">
    <!-- Header -->
    <div class="header sticky top-0 bg-white z-10 flex items-center justify-between px-4 py-3 border-b border-gray-200">
      <button @click="handleCancel" class="text-green-600 text-lg font-semibold">
        Cancel
      </button>
      <h1 class="text-xl font-bold">Edit Profile</h1>
      <button @click="handleSave" :disabled="isSaving" class="text-yellow-600 text-lg font-bold">
        {{ isSaving ? 'Saving...' : 'Save' }}
      </button>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-20">
      <div class="text-lg font-semibold text-gray-500">Loading profile...</div>
    </div>

    <div v-else class="px-4 pb-40">
      <!-- Profile Picture Section -->
      <div class="profile-info-section flex items-start space-x-4 py-4">
        <div class="relative">
          <div class="w-28 h-28 rounded-full overflow-hidden bg-gray-200 flex items-center justify-center">
            <img v-if="previewImageUrl" :src="previewImageUrl" class="w-full h-full object-cover" alt="Profile" />
            <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <label class="absolute bottom-0 right-0 bg-white bg-opacity-80 px-2 py-1 rounded text-xs text-gray-600 cursor-pointer border border-gray-300">
            <input type="file" accept="image/*" @change="handleImageSelect" class="hidden" />
            +Edit<br />Photo
          </label>
        </div>
        <div class="flex-1 pt-2">
          <div class="font-bold text-lg">{{ selectedType?.description || 'Rep Type' }}</div>
          <div class="text-sm space-y-1">
            <div v-for="skill in selectedSkills" :key="skill.id" class="text-gray-700">
              {{ skill.title }}
            </div>
            <div v-if="selectedSkills.length === 0" class="text-gray-400 italic">No skills selected</div>
          </div>
        </div>
      </div>

      <!-- Form Fields -->
      <div class="space-y-4 mt-6">
        <!-- First Name & Last Name -->
        <div class="flex space-x-3">
          <input
            v-model="formData.firstName"
            type="text"
            placeholder="First Name"
            class="flex-1 px-4 py-3 bg-gray-50 rounded text-base"
          />
          <input
            v-model="formData.lastName"
            type="text"
            placeholder="Last Name"
            class="flex-1 px-4 py-3 bg-gray-50 rounded text-base"
          />
        </div>

        <!-- Broadcast -->
        <input
          v-model="formData.broadcast"
          type="text"
          placeholder="Broadcast (optional)"
          class="w-full px-4 py-3 bg-gray-50 rounded text-base"
        />

        <!-- Rep Type -->
        <div>
          <label class="block font-bold text-base mb-2">Rep Type</label>
          <select
            v-model="formData.repType"
            class="w-full px-4 py-3 bg-gray-50 rounded text-base"
          >
            <option v-for="type in repTypes" :key="type.id" :value="type.id">
              {{ type.description }}
            </option>
          </select>
        </div>

        <!-- City -->
        <div>
          <label class="block font-bold text-base mb-2">City</label>
          <input
            v-model="formData.city"
            type="text"
            placeholder="Enter City (optional)"
            class="w-full px-4 py-3 bg-gray-50 rounded text-base"
          />
        </div>

        <!-- Skills Selection -->
        <div>
          <label class="block font-bold text-base mb-2">Select up to 3 Skills</label>
          <div v-if="loadingSkills" class="text-gray-500 py-4">Loading skills...</div>
          <div v-else class="border border-gray-200 rounded max-h-52 overflow-y-auto">
            <div
              v-for="skill in availableSkills"
              :key="skill.id"
              @click="toggleSkill(skill)"
              class="flex items-center justify-between px-4 py-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0"
            >
              <span class="font-semibold text-green-700">{{ skill.title }}</span>
              <div
                class="w-5 h-5 rounded-full border-2 flex items-center justify-center"
                :class="isSkillSelected(skill) ? 'border-green-700 bg-green-700' : 'border-green-700 bg-white'"
              >
                <svg v-if="isSkillSelected(skill)" xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
              </div>
            </div>
          </div>
          <div class="text-sm text-gray-500 mt-1">{{ selectedSkills.length }} of 3 selected</div>
        </div>

        <!-- Other Skill -->
        <input
          v-model="formData.otherSkill"
          type="text"
          placeholder="Other Skill (optional)"
          class="w-full px-4 py-3 bg-gray-50 rounded text-base"
        />

        <!-- Delete Profile Button -->
        <div class="pt-8 border-t border-gray-200 mt-12">
          <button
            @click="showDeleteConfirm = true"
            class="w-full py-3 text-red-600 font-bold text-lg hover:bg-red-50 rounded transition"
          >
            Delete Profile
          </button>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteConfirm" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h3 class="text-xl font-bold mb-4">Delete Profile?</h3>
        <p class="mb-6 text-gray-700">
          Are you sure you want to delete your profile? This cannot be undone.
        </p>
        <div class="flex space-x-4">
          <button @click="handleDeleteProfile" class="flex-1 bg-red-600 text-white px-4 py-3 rounded font-bold hover:bg-red-700 transition">
            Delete
          </button>
          <button @click="showDeleteConfirm = false" class="flex-1 bg-gray-200 text-gray-700 px-4 py-3 rounded font-semibold hover:bg-gray-300 transition">
            Cancel
          </button>
        </div>
      </div>
    </div>

    <!-- Error Modal -->
    <div v-if="errorMessage" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h3 class="text-xl font-bold mb-4 text-red-600">Error</h3>
        <p class="mb-6 text-gray-700">{{ errorMessage }}</p>
        <button @click="errorMessage = ''" class="w-full bg-green-600 text-white px-4 py-3 rounded font-bold hover:bg-green-700 transition">
          OK
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/pages/utils/api'

interface Skill {
  id: number
  title: string
}

interface RepType {
  id: number
  description: string
}

// Router
const router = useRouter()

// State
const isLoading = ref(true)
const isSaving = ref(false)
const loadingSkills = ref(true)
const showDeleteConfirm = ref(false)
const errorMessage = ref('')

// Form Data
const formData = ref({
  firstName: '',
  lastName: '',
  broadcast: '',
  repType: 1, // default to "Lead"
  city: '',
  otherSkill: '',
})

const selectedSkills = ref<Skill[]>([])
const availableSkills = ref<Skill[]>([])
const selectedImage = ref<File | null>(null)
const previewImageUrl = ref<string>('')

// Rep Types (matching Swift RepTypeModel)
const repTypes: RepType[] = [
  { id: 1, description: 'Lead' },
  { id: 2, description: 'Manager' },
  { id: 3, description: 'Designer' },
  { id: 4, description: 'Engineer' },
  { id: 5, description: 'Writer' },
  { id: 6, description: 'Other' },
]

// Computed
const selectedType = computed(() => repTypes.find(t => t.id === formData.value.repType))

// API Config
const userId = localStorage.getItem('userId')

// Methods
function isSkillSelected(skill: Skill): boolean {
  return selectedSkills.value.some(s => s.id === skill.id)
}

function toggleSkill(skill: Skill) {
  const index = selectedSkills.value.findIndex(s => s.id === skill.id)
  if (index > -1) {
    selectedSkills.value.splice(index, 1)
  } else if (selectedSkills.value.length < 3) {
    selectedSkills.value.push(skill)
  }
}

function handleImageSelect(event: Event) {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    const file = target.files[0]
    selectedImage.value = file

    // Create preview URL
    const reader = new FileReader()
    reader.onload = (e) => {
      previewImageUrl.value = e.target?.result as string
    }
    reader.readAsDataURL(file)
  }
}

function handleCancel() {
  router.back()
}

async function handleSave() {
  // Validation
  if (!formData.value.firstName.trim() || !formData.value.lastName.trim()) {
    errorMessage.value = 'First name and last name are required.'
    return
  }

  isSaving.value = true
  try {
    // Create FormData for multipart upload
    const formDataToSend = new FormData()

    formDataToSend.append('fname', formData.value.firstName.trim())
    formDataToSend.append('lname', formData.value.lastName.trim())
    formDataToSend.append('broadcast', formData.value.broadcast.trim())
    formDataToSend.append('users_types_id', String(formData.value.repType))
    formDataToSend.append('manual_city', formData.value.city.trim())
    formDataToSend.append('other_skill', formData.value.otherSkill.trim())

    // Add skills as comma-separated IDs
    if (selectedSkills.value.length > 0) {
      const skillIds = selectedSkills.value.map(s => s.id).join(',')
      formDataToSend.append('aSkills', skillIds)
    }

    // Add profile picture if selected
    if (selectedImage.value) {
      formDataToSend.append('profile_picture', selectedImage.value)
    }

    const response = await api.post(
      '/api/user/edit',
      formDataToSend,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    )

    if (response.data && response.data.result) {
      // Success - go back
      router.back()
    } else {
      errorMessage.value = 'Failed to update profile. Please try again.'
    }
  } catch (err: any) {
    console.error('Save error:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to save profile. Please try again.'
  } finally {
    isSaving.value = false
  }
}

async function handleDeleteProfile() {
  showDeleteConfirm.value = false
  isSaving.value = true

  try {
    await api.post(
      '/api/user/delete',
      {}
    )

    // Clear localStorage and redirect to login
    localStorage.clear()
    router.push('/login')
  } catch (err: any) {
    console.error('Delete error:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to delete profile. Please try again.'
  } finally {
    isSaving.value = false
  }
}

async function fetchProfile() {
  if (!userId || !token) {
    errorMessage.value = 'Not authenticated'
    return
  }

  try {
    const response = await api.get(
      `/api/user/profile?users_id=${userId}`
    )

    const user = response.data.result

    // Populate form
    formData.value.firstName = user.fname || ''
    formData.value.lastName = user.lname || ''
    formData.value.broadcast = user.broadcast || ''
    formData.value.city = user.city || user.manual_city || ''
    formData.value.otherSkill = user.other_skill || ''

    // Map user type
    const typeMapping: Record<string, number> = {
      'Lead': 1,
      'Manager': 2,
      'Designer': 3,
      'Engineer': 4,
      'Writer': 5,
      'Other': 6,
    }
    formData.value.repType = typeMapping[user.userType] || 1

    // Set profile picture URL
    if (user.profile_picture_url) {
      previewImageUrl.value = user.profile_picture_url
    }

    // Map skills to selectedSkills after skills are loaded
    if (user.skills && Array.isArray(user.skills)) {
      // Wait for skills to load, then match
      const skillTitles = user.skills
      // We'll populate selectedSkills after availableSkills are loaded
      setTimeout(() => {
        selectedSkills.value = availableSkills.value.filter(skill =>
          skillTitles.includes(skill.title)
        )
      }, 100)
    }
  } catch (err: any) {
    console.error('Fetch profile error:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to load profile.'
  } finally {
    isLoading.value = false
  }
}

async function fetchSkills() {
  loadingSkills.value = true
  try {
    const response = await api.get(
      '/api/user/get_skills'
    )

    availableSkills.value = response.data.result || []
  } catch (err: any) {
    console.error('Fetch skills error:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to load skills.'
  } finally {
    loadingSkills.value = false
  }
}

// Lifecycle
onMounted(async () => {
  await Promise.all([fetchProfile(), fetchSkills()])
})
</script>

<style scoped>
.header {
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

input::placeholder,
select {
  color: #8a8a8d;
}

input:focus,
select:focus {
  outline: none;
  ring: 2px;
  ring-color: #8cc65d;
}
</style>
