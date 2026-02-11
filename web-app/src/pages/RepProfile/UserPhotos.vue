<!--
  UserPhotos.vue
  Rep

  Created by Adam Novak on 01.24.2026
  Copyright (c) 2026 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Loading State -->
    <div v-if="!isLoaded" class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <div class="animate-spin h-8 w-8 border-4 border-t-transparent rounded-full mx-auto mb-4" style="border-color: #8cc65d; border-top-color: transparent;"></div>
        <p class="text-gray-400 text-sm">Loading Photos</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="errorMessage" class="flex-1 flex items-center justify-center p-4">
      <div class="text-center">
        <p class="text-red-500 mb-4">{{ errorMessage }}</p>
        <button @click="fetchUserPhotos" class="px-6 py-2.5 text-white rounded-xl font-medium" style="background-color: #8cc65d">
          Retry
        </button>
      </div>
    </div>

    <!-- Main Content -->
    <div v-else class="flex flex-col h-full">
      <!-- Header -->
      <header class="flex items-center h-14 px-4 border-b border-gray-200 shrink-0 bg-white">
        <button @click="goBack" class="w-10 h-10 flex items-center justify-center -ml-2" style="color: #8cc65d">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <h1 class="flex-1 text-center font-semibold text-lg text-gray-900">{{ pageTitle }}</h1>
        <!-- Upload button (own profile only) -->
        <div v-if="isCurrentUser" class="flex items-center gap-3 -mr-2">
          <button @click="isEditing = !isEditing" class="text-sm font-medium" style="color: #8cc65d">
            {{ isEditing ? 'Done' : 'Edit' }}
          </button>
          <button @click="triggerFileInput" class="w-10 h-10 flex items-center justify-center" style="color: #8cc65d">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
            </svg>
          </button>
        </div>
        <div v-else class="w-10"></div>
      </header>

      <!-- Photo Feed -->
      <div class="flex-1 overflow-y-auto">
        <!-- Empty State -->
        <div v-if="photos.length === 0" class="flex items-center justify-center h-full px-6">
          <div class="text-center">
            <div class="w-20 h-20 mx-auto mb-5 rounded-full bg-gray-100 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <p class="text-gray-400 text-base mb-1">No photos yet</p>
            <p v-if="isCurrentUser" class="text-gray-300 text-sm mb-6">Share your first photo</p>
            <button
              v-if="isCurrentUser"
              @click="triggerFileInput"
              class="px-8 py-3 text-white rounded-xl font-medium text-base shadow-sm transition-transform active:scale-95"
              style="background-color: #8cc65d"
            >
              Add Photo
            </button>
          </div>
        </div>

        <!-- Photo Cards -->
        <div v-else class="max-w-lg mx-auto">
          <div
            v-for="(photo, index) in photos"
            :key="photo.id"
            class="bg-white"
          >
            <!-- Reorder & Delete Controls (owner only) -->
            <div v-if="isEditing" class="flex items-center justify-between px-3 py-2 border-b border-gray-100">
              <!-- Reorder buttons -->
              <div class="flex items-center space-x-1">
                <button
                  v-if="index > 0"
                  @click="movePhotoUp(index)"
                  class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded transition-colors"
                  title="Move up"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 15l7-7 7 7" />
                  </svg>
                </button>
                <span v-else class="w-8"></span>
                <button
                  v-if="index < photos.length - 1"
                  @click="movePhotoDown(index)"
                  class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded transition-colors"
                  title="Move down"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                <span v-else class="w-8"></span>
              </div>
              <!-- Delete button -->
              <button
                @click="confirmDelete(photo)"
                class="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded transition-colors"
                title="Delete photo"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>
            <!-- Photo Image -->
            <div class="relative cursor-pointer group" @click="openFullscreen(index)">
              <img
                :src="photo.url"
                :alt="photo.caption || `Photo ${index + 1}`"
                class="w-full object-contain bg-gray-50"
                style="max-height: 75vh;"
                @error="handleImageError($event)"
              />
            </div>
            <!-- Caption + Timestamp -->
            <div v-if="photo.caption || photo.created_at" class="px-4 py-3">
              <p v-if="photo.caption" class="text-gray-800 text-sm leading-relaxed">{{ photo.caption }}</p>
              <p class="text-gray-300 text-xs mt-1">{{ formatDate(photo.created_at) }}</p>
            </div>
          </div>
          <!-- Bottom spacer -->
          <div style="height: 80px;"></div>
        </div>
      </div>
    </div>

    <!-- Hidden File Input -->
    <input
      ref="fileInputRef"
      type="file"
      accept="image/png,image/jpeg,image/jpg,image/gif,image/webp"
      class="hidden"
      @change="onFileSelected"
    />

    <!-- Upload Preview Modal -->
    <Transition name="fade">
      <div v-if="uploadPreview" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center" @click.self="cancelUpload">
        <div class="absolute inset-0 bg-black/50 backdrop-blur-sm"></div>
        <div class="relative w-full sm:max-w-md mx-auto bg-white rounded-t-2xl sm:rounded-2xl shadow-2xl overflow-hidden animate-slide-up">
          <!-- Preview Header -->
          <div class="flex items-center justify-between px-4 py-3 border-b border-gray-100">
            <button @click="cancelUpload" class="text-gray-400 font-medium text-sm">Cancel</button>
            <span class="font-semibold text-gray-900">New Photo</span>
            <button
              @click="uploadPhoto"
              :disabled="isUploading"
              class="font-semibold text-sm transition-opacity"
              :style="{ color: isUploading ? '#ccc' : '#8cc65d' }"
            >
              {{ isUploading ? 'Posting...' : 'Post' }}
            </button>
          </div>
          <!-- Preview Image -->
          <div class="relative bg-gray-50">
            <img :src="uploadPreview" class="w-full object-contain" style="max-height: 50vh;" />
            <!-- Upload spinner overlay -->
            <div v-if="isUploading" class="absolute inset-0 bg-white/70 flex items-center justify-center">
              <div class="animate-spin h-10 w-10 border-4 border-t-transparent rounded-full" style="border-color: #8cc65d; border-top-color: transparent;"></div>
            </div>
          </div>
          <!-- Caption Input -->
          <div class="px-4 py-3">
            <textarea
              v-model="uploadCaption"
              placeholder="Write a caption..."
              maxlength="500"
              rows="2"
              class="w-full resize-none text-sm text-gray-800 placeholder-gray-300 outline-none"
            ></textarea>
            <p class="text-right text-xs text-gray-300">{{ uploadCaption.length }}/500</p>
          </div>
          <!-- Upload Error -->
          <p v-if="uploadError" class="px-4 pb-3 text-red-500 text-xs">{{ uploadError }}</p>
        </div>
      </div>
    </Transition>

    <!-- Delete Confirmation -->
    <Transition name="fade">
      <div v-if="deleteTarget" class="fixed inset-0 z-50 flex items-center justify-center" @click.self="deleteTarget = null">
        <div class="absolute inset-0 bg-black/50 backdrop-blur-sm"></div>
        <div class="relative bg-white rounded-2xl shadow-2xl overflow-hidden w-72 mx-auto">
          <div class="p-5 text-center">
            <div class="w-12 h-12 mx-auto mb-3 rounded-full bg-red-50 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </div>
            <p class="font-semibold text-gray-900 mb-1">Delete Photo</p>
            <p class="text-gray-400 text-sm">This can't be undone.</p>
          </div>
          <div class="flex border-t border-gray-100">
            <button @click="deleteTarget = null" class="flex-1 py-3.5 text-center font-medium text-gray-500 text-sm border-r border-gray-100">
              Cancel
            </button>
            <button @click="executeDelete" :disabled="isDeleting" class="flex-1 py-3.5 text-center font-medium text-red-500 text-sm">
              {{ isDeleting ? 'Deleting...' : 'Delete' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Fullscreen Viewer -->
    <Transition name="viewer">
      <div
        v-if="isFullscreenOpen"
        class="fixed inset-0 z-50 bg-black flex flex-col"
        @keydown.escape="closeFullscreen"
        @keydown.left="viewerPrev"
        @keydown.right="viewerNext"
        tabindex="0"
        ref="viewerRef"
      >
        <!-- Top bar -->
        <div class="absolute top-0 left-0 right-0 z-10 flex items-center justify-between px-4 py-3" style="background: linear-gradient(to bottom, rgba(0,0,0,0.5), transparent);">
          <button @click="closeFullscreen" class="w-10 h-10 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <span v-if="photos.length > 1" class="text-white/80 text-sm font-medium">{{ viewerIndex + 1 }} / {{ photos.length }}</span>
          <div class="w-10"></div>
        </div>

        <!-- Photo container with swipe -->
        <div
          class="flex-1 flex items-center justify-center overflow-hidden select-none"
          @touchstart.passive="onTouchStart"
          @touchmove.passive="onTouchMove"
          @touchend="onTouchEnd"
          @mousedown="onMouseDown"
        >
          <!-- Previous / Current / Next images for smooth transitions -->
          <div
            class="flex items-center h-full transition-transform duration-300 ease-out"
            :style="{ transform: `translateX(${viewerTranslateX}px)` }"
            :class="{ 'transition-none': isSwiping }"
          >
            <div
              v-for="offset in [-1, 0, 1]"
              :key="offset"
              class="flex-shrink-0 w-screen h-full flex items-center justify-center px-2"
            >
              <img
                v-if="photos[viewerIndex + offset]"
                :src="photos[viewerIndex + offset].url"
                :alt="photos[viewerIndex + offset].caption || ''"
                class="max-w-full max-h-full object-contain rounded-sm"
                draggable="false"
              />
            </div>
          </div>
        </div>

        <!-- Navigation arrows (desktop) -->
        <button
          v-if="viewerIndex > 0"
          @click="viewerPrev"
          class="hidden sm:flex absolute left-4 top-1/2 -translate-y-1/2 w-12 h-12 items-center justify-center rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-sm transition-colors"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <button
          v-if="viewerIndex < photos.length - 1"
          @click="viewerNext"
          class="hidden sm:flex absolute right-4 top-1/2 -translate-y-1/2 w-12 h-12 items-center justify-center rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-sm transition-colors"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
          </svg>
        </button>

        <!-- Bottom caption bar -->
        <div
          v-if="currentViewerPhoto?.caption"
          class="absolute bottom-0 left-0 right-0 z-10 px-6 py-5"
          style="background: linear-gradient(to top, rgba(0,0,0,0.6), transparent);"
        >
          <p class="text-white text-sm leading-relaxed">{{ currentViewerPhoto.caption }}</p>
        </div>

        <!-- Dot indicators for few photos -->
        <div
          v-if="photos.length > 1 && photos.length <= 10"
          class="absolute bottom-4 left-0 right-0 z-10 flex justify-center gap-1.5"
          :class="{ 'mb-12': currentViewerPhoto?.caption }"
        >
          <div
            v-for="(_, i) in photos"
            :key="i"
            class="w-1.5 h-1.5 rounded-full transition-all duration-300"
            :class="i === viewerIndex ? 'bg-white w-4' : 'bg-white/40'"
          ></div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '@/pages/utils/api'

// --- Types ---
interface Photo {
  id: number
  url: string
  caption?: string
  position?: number
  created_at?: string
  updated_at?: string
}

// --- Route / Auth ---
const route = useRoute()
const router = useRouter()
const userId = computed(() => Number(route.params.id))
const loggedInUserId = computed(() => Number(localStorage.getItem('userId')))
const isCurrentUser = computed(() => userId.value === loggedInUserId.value)

// --- State ---
const userName = ref('')
const photos = ref<Photo[]>([])
const isLoaded = ref(false)
const errorMessage = ref<string | null>(null)
const isEditing = ref(false)

const pageTitle = computed(() => {
  if (!userName.value) return 'Photos'
  return `${userName.value}'s Photos`
})

// --- Fetch ---
const fetchUserPhotos = async () => {
  isLoaded.value = false
  errorMessage.value = null

  try {
    const userRes = await api.get(`/api/user/profile?users_id=${userId.value}`)
    const profile = userRes.data.result

    if (!profile || !profile.id) {
      errorMessage.value = 'User not found'
      return
    }

    userName.value = profile.full_name || ((profile.fname || '') + ' ' + (profile.lname || '')).trim()

    const photosRes = await api.get(`/api/user/photos?users_id=${userId.value}`)
    photos.value = photosRes.data.result || []

  } catch (error) {
    console.error('Failed to load user photos:', error)
    if ((error as any).response?.status === 401) {
      localStorage.removeItem('jwtToken')
      localStorage.removeItem('userId')
      router.push('/login')
    } else {
      errorMessage.value = (error as any).response?.data?.error || 'Failed to load photos.'
    }
  } finally {
    isLoaded.value = true
  }
}

const goBack = () => {
  router.back()
}

const formatDate = (dateStr?: string) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)

  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined })
}

const handleImageError = (event: Event) => {
  const target = event.target as HTMLImageElement
  target.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="300"%3E%3Crect fill="%23f3f4f6" width="400" height="300"/%3E%3Ctext x="50%25" y="50%25" text-anchor="middle" fill="%239ca3af" font-family="sans-serif" font-size="14"%3EImage unavailable%3C/text%3E%3C/svg%3E'
}

// --- Upload ---
const fileInputRef = ref<HTMLInputElement | null>(null)
const uploadPreview = ref<string | null>(null)
const uploadCaption = ref('')
const uploadFile = ref<File | null>(null)
const isUploading = ref(false)
const uploadError = ref<string | null>(null)

const triggerFileInput = () => {
  fileInputRef.value?.click()
}

const onFileSelected = (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  // Validate file type
  const validTypes = ['image/png', 'image/jpeg', 'image/jpg', 'image/gif', 'image/webp']
  if (!validTypes.includes(file.type)) {
    alert('Please select a valid image file (PNG, JPG, GIF, or WebP)')
    return
  }

  // Validate file size (10MB max)
  if (file.size > 10 * 1024 * 1024) {
    alert('Image must be under 10MB')
    return
  }

  uploadFile.value = file
  uploadPreview.value = URL.createObjectURL(file)
  uploadCaption.value = ''
  uploadError.value = null

  // Reset file input for re-selection
  input.value = ''
}

const cancelUpload = () => {
  if (uploadPreview.value) {
    URL.revokeObjectURL(uploadPreview.value)
  }
  uploadPreview.value = null
  uploadFile.value = null
  uploadCaption.value = ''
  uploadError.value = null
}

const uploadPhoto = async () => {
  if (!uploadFile.value || isUploading.value) return

  isUploading.value = true
  uploadError.value = null

  try {
    const formData = new FormData()
    formData.append('photo', uploadFile.value)
    if (uploadCaption.value.trim()) {
      formData.append('caption', uploadCaption.value.trim())
    }

    const res = await api.post('/api/user/photos/upload', formData, { timeout: 60000 })
    const newPhoto = res.data.result

    // Prepend new photo to the list
    photos.value.unshift(newPhoto)

    // Clean up
    if (uploadPreview.value) {
      URL.revokeObjectURL(uploadPreview.value)
    }
    uploadPreview.value = null
    uploadFile.value = null
    uploadCaption.value = ''

  } catch (error) {
    console.error('Upload failed:', error)
    uploadError.value = (error as any).response?.data?.error || 'Upload failed. Please try again.'
  } finally {
    isUploading.value = false
  }
}

// --- Reorder ---
const movePhotoUp = async (index: number) => {
  if (index <= 0) return

  // Swap in local array
  const temp = photos.value[index]
  photos.value[index] = photos.value[index - 1]
  photos.value[index - 1] = temp

  // Persist to backend
  await savePhotoOrder()
}

const movePhotoDown = async (index: number) => {
  if (index >= photos.value.length - 1) return

  // Swap in local array
  const temp = photos.value[index]
  photos.value[index] = photos.value[index + 1]
  photos.value[index + 1] = temp

  // Persist to backend
  await savePhotoOrder()
}

const savePhotoOrder = async () => {
  try {
    const photoOrder = photos.value.map((photo, idx) => ({
      id: photo.id,
      position: idx
    }))

    await api.put('/api/user/photos/reorder', {
      users_id: userId.value,
      photo_order: photoOrder
    })
  } catch (error) {
    console.error('Failed to save photo order:', error)
    // Optionally show an error toast, but don't break the UX
  }
}

// --- Delete ---
const deleteTarget = ref<Photo | null>(null)
const isDeleting = ref(false)

const confirmDelete = (photo: Photo) => {
  deleteTarget.value = photo
}

const executeDelete = async () => {
  if (!deleteTarget.value || isDeleting.value) return

  isDeleting.value = true
  const photoId = deleteTarget.value.id

  try {
    await api.delete(`/api/user/photos/${photoId}`)
    photos.value = photos.value.filter(p => p.id !== photoId)
    deleteTarget.value = null
  } catch (error) {
    console.error('Delete failed:', error)
    alert('Failed to delete photo. Please try again.')
  } finally {
    isDeleting.value = false
  }
}

// --- Fullscreen Viewer ---
const isFullscreenOpen = ref(false)
const viewerIndex = ref(0)
const viewerRef = ref<HTMLElement | null>(null)

// Touch/swipe state
const touchStartX = ref(0)
const touchStartY = ref(0)
const touchDeltaX = ref(0)
const isSwiping = ref(false)
const isHorizontalSwipe = ref<boolean | null>(null)

const currentViewerPhoto = computed(() => photos.value[viewerIndex.value] || null)

const viewerTranslateX = computed(() => {
  // Center on current image (offset = 0 is the middle of the 3-image strip)
  const base = 0
  return base + touchDeltaX.value
})

const openFullscreen = (index: number) => {
  viewerIndex.value = index
  isFullscreenOpen.value = true
  nextTick(() => {
    viewerRef.value?.focus()
  })
}

const closeFullscreen = () => {
  isFullscreenOpen.value = false
}

const viewerPrev = () => {
  if (viewerIndex.value > 0) {
    viewerIndex.value--
  }
}

const viewerNext = () => {
  if (viewerIndex.value < photos.value.length - 1) {
    viewerIndex.value++
  }
}

// Touch handlers for swipe
const onTouchStart = (e: TouchEvent) => {
  touchStartX.value = e.touches[0].clientX
  touchStartY.value = e.touches[0].clientY
  touchDeltaX.value = 0
  isSwiping.value = true
  isHorizontalSwipe.value = null
}

const onTouchMove = (e: TouchEvent) => {
  if (!isSwiping.value) return

  const dx = e.touches[0].clientX - touchStartX.value
  const dy = e.touches[0].clientY - touchStartY.value

  // Determine swipe direction on first significant movement
  if (isHorizontalSwipe.value === null && (Math.abs(dx) > 5 || Math.abs(dy) > 5)) {
    isHorizontalSwipe.value = Math.abs(dx) > Math.abs(dy)
  }

  if (isHorizontalSwipe.value) {
    // Apply resistance at edges
    if ((viewerIndex.value === 0 && dx > 0) || (viewerIndex.value === photos.value.length - 1 && dx < 0)) {
      touchDeltaX.value = dx * 0.3
    } else {
      touchDeltaX.value = dx
    }
  }
}

const onTouchEnd = () => {
  if (!isSwiping.value) return
  isSwiping.value = false

  const threshold = window.innerWidth * 0.2
  if (touchDeltaX.value < -threshold && viewerIndex.value < photos.value.length - 1) {
    viewerIndex.value++
  } else if (touchDeltaX.value > threshold && viewerIndex.value > 0) {
    viewerIndex.value--
  }

  touchDeltaX.value = 0
  isHorizontalSwipe.value = null
}

// Mouse drag for desktop
const isMouseDragging = ref(false)
const mouseStartX = ref(0)

const onMouseDown = (e: MouseEvent) => {
  isMouseDragging.value = true
  mouseStartX.value = e.clientX
  isSwiping.value = true

  const onMouseMove = (ev: MouseEvent) => {
    const dx = ev.clientX - mouseStartX.value
    if ((viewerIndex.value === 0 && dx > 0) || (viewerIndex.value === photos.value.length - 1 && dx < 0)) {
      touchDeltaX.value = dx * 0.3
    } else {
      touchDeltaX.value = dx
    }
  }

  const onMouseUp = () => {
    isSwiping.value = false
    const threshold = window.innerWidth * 0.15
    if (touchDeltaX.value < -threshold && viewerIndex.value < photos.value.length - 1) {
      viewerIndex.value++
    } else if (touchDeltaX.value > threshold && viewerIndex.value > 0) {
      viewerIndex.value--
    }
    touchDeltaX.value = 0
    isMouseDragging.value = false
    window.removeEventListener('mousemove', onMouseMove)
    window.removeEventListener('mouseup', onMouseUp)
  }

  window.addEventListener('mousemove', onMouseMove)
  window.addEventListener('mouseup', onMouseUp)
}

// --- Init ---
onMounted(fetchUserPhotos)
</script>

<style scoped>
/* Fade transition */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.25s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

/* Viewer transition */
.viewer-enter-active {
  transition: opacity 0.3s ease;
}
.viewer-leave-active {
  transition: opacity 0.2s ease;
}
.viewer-enter-from, .viewer-leave-to {
  opacity: 0;
}

/* Slide up for upload modal */
@keyframes slide-up {
  from { transform: translateY(100%); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
.animate-slide-up {
  animation: slide-up 0.3s ease-out;
}
</style>
