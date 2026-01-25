<!--
  UserPhotos.vue
  Rep

  Created by Adam Novak on 01.24.2026
  Copyright (c) 2026 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-gray-100">
    <!-- Loading State -->
    <div v-if="!isLoaded" class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <div class="animate-spin h-8 w-8 border-4 border-t-transparent rounded-full mx-auto mb-4" style="border-color: #8cc65d; border-top-color: transparent;"></div>
        <p class="text-gray-500">Loading Photos...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="errorMessage" class="flex-1 flex items-center justify-center p-4">
      <div class="text-center">
        <p class="text-red-500 mb-4">{{ errorMessage }}</p>
        <button @click="fetchUserPhotos" class="px-4 py-2 text-white rounded-lg" style="background-color: #8cc65d">
          Retry
        </button>
      </div>
    </div>

    <!-- Main Content -->
    <div v-else class="flex flex-col h-full">
      <!-- Header -->
      <PhotosHeader :user-name="userName" @back="goBack" />

      <!-- Scrollable Photo List -->
      <div class="flex-1 overflow-y-auto">
        <div v-if="photos.length === 0" class="flex items-center justify-center h-full">
          <p class="text-gray-500">No photos yet.</p>
        </div>
        <div v-else class="space-y-1">
          <div
            v-for="(photo, index) in photos"
            :key="photo.id"
            class="relative bg-white cursor-pointer"
            @click="openFullscreen(index)"
          >
            <img
              :src="photo.url"
              :alt="`Photo ${index + 1}`"
              class="w-full object-contain"
              style="max-height: 80vh;"
              @error="handleImageError($event, photo)"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Fullscreen Image Viewer -->
    <transition name="fade">
      <FullscreenImageViewer
        v-if="isFullscreenOpen"
        :images="photos"
        :start-index="fullscreenStartIndex"
        @close="isFullscreenOpen = false"
      />
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, h, defineComponent } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '@/pages/utils/api'

// Header Component
const PhotosHeader = defineComponent({
  props: { userName: String },
  emits: ['back'],
  setup(props, { emit }) {
    return () => h('header', {
      class: 'flex items-center h-14 px-4 border-b border-gray-200 shrink-0',
      style: 'background-color: #f7f7f7'
    }, [
      h('button', {
        onClick: () => emit('back'),
        style: 'color: #8cc65d'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-6 w-6',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M15 19l-7-7 7-7'
          })
        ])
      ]),
      h('h1', {
        class: 'flex-1 text-center font-bold text-xl'
      }, `${props.userName}'s Photos`),
      h('div', { class: 'w-6' }) // Spacer for centering
    ])
  }
})

// Fullscreen Image Viewer Component
const FullscreenImageViewer = defineComponent({
  props: {
    images: Array,
    startIndex: Number
  },
  emits: ['close'],
  setup(props, { emit }) {
    const currentIndex = ref(props.startIndex || 0)

    const goToPrevious = () => {
      if (currentIndex.value > 0) {
        currentIndex.value--
      }
    }

    const goToNext = () => {
      if (props.images && currentIndex.value < props.images.length - 1) {
        currentIndex.value++
      }
    }

    const handleTouchStart = ref(0)
    const handleTouchEnd = (e: TouchEvent) => {
      const touchEnd = e.changedTouches[0].clientX
      const diff = handleTouchStart.value - touchEnd

      if (Math.abs(diff) > 50) {
        if (diff > 0) {
          goToNext()
        } else {
          goToPrevious()
        }
      }
    }

    return () => h('div', {
      class: 'fixed inset-0 z-50 bg-black flex items-center justify-center',
      onTouchstart: (e: TouchEvent) => { handleTouchStart.value = e.touches[0].clientX },
      onTouchend: handleTouchEnd
    }, [
      // Close Button
      h('button', {
        onClick: () => emit('close'),
        class: 'absolute top-4 right-4 z-10 text-white p-2'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-8 w-8',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor',
          'stroke-width': '2'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            d: 'M6 18L18 6M6 6l12 12'
          })
        ])
      ]),

      // Image Counter
      props.images && props.images.length > 1 && h('div', {
        class: 'absolute top-4 left-1/2 transform -translate-x-1/2 text-white text-sm bg-black bg-opacity-50 px-3 py-1 rounded-full'
      }, `${currentIndex.value + 1} / ${props.images.length}`),

      // Previous Button
      currentIndex.value > 0 && h('button', {
        onClick: goToPrevious,
        class: 'absolute left-4 text-white p-2 z-10'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-10 w-10',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor',
          'stroke-width': '2'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            d: 'M15 19l-7-7 7-7'
          })
        ])
      ]),

      // Current Image
      props.images && props.images[currentIndex.value] && h('img', {
        src: (props.images[currentIndex.value] as any).url,
        class: 'max-w-full max-h-full object-contain',
        alt: `Photo ${currentIndex.value + 1}`
      }),

      // Next Button
      props.images && currentIndex.value < props.images.length - 1 && h('button', {
        onClick: goToNext,
        class: 'absolute right-4 text-white p-2 z-10'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-10 w-10',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor',
          'stroke-width': '2'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            d: 'M9 5l7 7-7 7'
          })
        ])
      ])
    ])
  }
})

interface Photo {
  id: number
  url: string
  created_at?: string
}

const route = useRoute()
const router = useRouter()

const userId = computed(() => Number(route.params.id))
const userName = ref('')
const photos = ref<Photo[]>([])
const isLoaded = ref(false)
const errorMessage = ref<string | null>(null)
const isFullscreenOpen = ref(false)
const fullscreenStartIndex = ref(0)

const fetchUserPhotos = async () => {
  isLoaded.value = false
  errorMessage.value = null

  try {
    // Fetch user profile for name
    const userRes = await api.get(`/api/user/profile?users_id=${userId.value}`)
    const profile = userRes.data.result

    if (!profile || !profile.id) {
      errorMessage.value = 'User not found'
      return
    }

    userName.value = profile.full_name || ((profile.fname || '') + ' ' + (profile.lname || '')).trim()

    // Fetch user photos
    const photosRes = await api.get(`/api/user/photos?users_id=${userId.value}`)
    photos.value = photosRes.data.result || []

  } catch (error) {
    console.error('Failed to load user photos:', error)
    if ((error as any).response?.status === 401) {
      localStorage.removeItem('jwtToken')
      localStorage.removeItem('userId')
      router.push('/login')
    } else {
      errorMessage.value = (error as any).response?.data?.error || 'Failed to load photos. Please try again.'
    }
  } finally {
    isLoaded.value = true
  }
}

const goBack = () => {
  router.back()
}

const openFullscreen = (index: number) => {
  fullscreenStartIndex.value = index
  isFullscreenOpen.value = true
}

const handleImageError = (event: Event, photo: Photo) => {
  const target = event.target as HTMLImageElement
  target.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="300"%3E%3Crect fill="%23e5e7eb" width="400" height="300"/%3E%3Ctext x="50%25" y="50%25" text-anchor="middle" fill="%239ca3af" font-family="sans-serif" font-size="16"%3EImage not available%3C/text%3E%3C/svg%3E'
}

onMounted(fetchUserPhotos)
</script>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
