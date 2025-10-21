<!--
  WriteView.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
    <!-- Header -->
    <header class="flex items-center justify-between h-14 px-4 border-b bg-white shrink-0">
      <button @click="handleCancel" class="text-green-600 font-semibold">
        Cancel
      </button>
      <h1 class="font-bold text-lg">{{ isEditing ? 'Edit Content' : 'New Content' }}</h1>
      <button
        @click="handleSave"
        :disabled="isSaving || !canSave"
        class="text-yellow-600 font-bold disabled:opacity-50"
      >
        {{ isSaving ? 'Saving...' : 'Publish' }}
      </button>
    </header>

    <div class="flex-1 overflow-y-auto">
      <div class="max-w-4xl mx-auto p-4 md:p-6 space-y-6">
        <!-- Title Input -->
        <div>
          <input
            v-model="title"
            type="text"
            placeholder="Title"
            class="w-full text-3xl font-bold border-none outline-none bg-transparent placeholder-gray-400"
            @input="clearError"
          />
        </div>

        <!-- Rich Text Editor Toolbar -->
        <div class="flex flex-wrap items-center gap-2 p-3 bg-white border border-gray-300 rounded-t-lg">
          <button
            v-for="tool in textTools"
            :key="tool.command"
            @click="execCommand(tool.command, tool.value)"
            :title="tool.label"
            class="p-2 hover:bg-gray-100 rounded transition-colors"
            type="button"
          >
            <component :is="tool.icon" class="w-5 h-5" />
          </button>

          <div class="border-l border-gray-300 h-6 mx-1"></div>

          <!-- Image Upload Button -->
          <button
            @click="triggerImageUpload"
            title="Insert Image"
            class="p-2 hover:bg-gray-100 rounded transition-colors"
            type="button"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </button>
          <input
            ref="imageInput"
            type="file"
            accept="image/*"
            class="hidden"
            @change="handleImageSelect"
            multiple
          />
        </div>

        <!-- Content Editor -->
        <div
          ref="editor"
          contenteditable="true"
          @input="handleContentChange"
          @paste="handlePaste"
          class="min-h-[400px] p-4 bg-white border border-t-0 border-gray-300 rounded-b-lg outline-none prose prose-lg max-w-none"
          placeholder="Start writing..."
        ></div>

        <!-- Image Preview Section -->
        <div v-if="uploadedImages.length > 0" class="space-y-2">
          <h3 class="font-semibold text-gray-700">Attached Images:</h3>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div
              v-for="(img, index) in uploadedImages"
              :key="index"
              class="relative group"
            >
              <img :src="img.preview" class="w-full h-32 object-cover rounded-lg" />
              <button
                @click="removeImage(index)"
                class="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Link to Portal/Goal Section -->
        <div class="space-y-4 p-4 bg-white border border-gray-300 rounded-lg">
          <h3 class="font-semibold text-gray-700">Link to (Optional):</h3>

          <!-- Portal Selection -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Portal</label>
            <select
              v-model="linkedPortalId"
              class="w-full p-2 border border-gray-300 rounded-lg bg-white"
              @change="clearError"
            >
              <option :value="null">None</option>
              <option v-for="portal in userPortals" :key="portal.id" :value="portal.id">
                {{ portal.name }}
              </option>
            </select>
          </div>

          <!-- Goal Selection -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Goal</label>
            <select
              v-model="linkedGoalId"
              class="w-full p-2 border border-gray-300 rounded-lg bg-white"
              @change="clearError"
            >
              <option :value="null">None</option>
              <option v-for="goal in userGoals" :key="goal.id" :value="goal.id">
                {{ goal.title }}
              </option>
            </select>
          </div>
        </div>

        <!-- Publish Status Toggle -->
        <div class="flex items-center justify-between p-4 bg-white border border-gray-300 rounded-lg">
          <div>
            <h3 class="font-semibold text-gray-700">Status</h3>
            <p class="text-sm text-gray-500">{{ isDraft ? 'Save as draft or publish' : 'Published and visible to others' }}</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              v-model="isDraft"
              class="sr-only peer"
              @change="clearError"
            />
            <div class="w-14 h-7 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-300 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-green-600"></div>
            <span class="ms-3 text-sm font-medium text-gray-700">{{ isDraft ? 'Draft' : 'Published' }}</span>
          </label>
        </div>

        <!-- Error Message -->
        <div v-if="errorMessage" class="p-3 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {{ errorMessage }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, h } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import api from '@/pages/utils/api'

// Icons as Vue components
const BoldIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M6 12h12M6 6h12M6 18h12' })
])

const ItalicIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4' })
])

const UnderlineIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M6 4v8a6 6 0 0012 0V4M4 20h16' })
])

const ListIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 6h16M4 12h16M4 18h16' })
])

const NumberedListIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5h12M9 12h12M9 19h12M5 5v2m0 5v2m0 5v2' })
])

const LinkIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1' })
])

// Props & Router
const router = useRouter()
const route = useRoute()
const writeId = route.params.id ? Number(route.params.id) : null

// API Config
const userId = Number(localStorage.getItem('userId'))

// State
const title = ref('')
const content = ref('')
const isDraft = ref(false)
const linkedPortalId = ref<number | null>(null)
const linkedGoalId = ref<number | null>(null)
const uploadedImages = ref<Array<{ file: File; preview: string }>>([])
const isSaving = ref(false)
const errorMessage = ref('')
const isEditing = computed(() => writeId !== null)

// Data for linking
const userPortals = ref<Array<{ id: number; name: string }>>([])
const userGoals = ref<Array<{ id: number; title: string }>>([])

// Refs
const editor = ref<HTMLDivElement | null>(null)
const imageInput = ref<HTMLInputElement | null>(null)

// Text formatting tools
const textTools = [
  { command: 'bold', label: 'Bold', icon: BoldIcon },
  { command: 'italic', label: 'Italic', icon: ItalicIcon },
  { command: 'underline', label: 'Underline', icon: UnderlineIcon },
  { command: 'insertUnorderedList', label: 'Bullet List', icon: ListIcon },
  { command: 'insertOrderedList', label: 'Numbered List', icon: NumberedListIcon },
  { command: 'createLink', label: 'Insert Link', icon: LinkIcon, value: null },
]

// Computed
const canSave = computed(() => {
  return title.value.trim().length > 0 && content.value.trim().length > 0
})

// Methods
function execCommand(command: string, value: any = null) {
  if (command === 'createLink') {
    const url = prompt('Enter URL:')
    if (url) {
      document.execCommand(command, false, url)
    }
  } else {
    document.execCommand(command, false, value)
  }
  editor.value?.focus()
}

function handleContentChange() {
  if (editor.value) {
    content.value = editor.value.innerHTML
  }
}

function handlePaste(e: ClipboardEvent) {
  e.preventDefault()
  const text = e.clipboardData?.getData('text/plain')
  if (text) {
    document.execCommand('insertText', false, text)
  }
}

function triggerImageUpload() {
  imageInput.value?.click()
}

function handleImageSelect(event: Event) {
  const target = event.target as HTMLInputElement
  if (target.files) {
    Array.from(target.files).forEach(file => {
      const reader = new FileReader()
      reader.onload = (e) => {
        uploadedImages.value.push({
          file,
          preview: e.target?.result as string
        })
      }
      reader.readAsDataURL(file)
    })
  }
  // Reset input
  if (target) target.value = ''
}

function removeImage(index: number) {
  uploadedImages.value.splice(index, 1)
}

function clearError() {
  errorMessage.value = ''
}

function handleCancel() {
  if (confirm('Discard changes?')) {
    router.back()
  }
}

async function handleSave() {
  if (!canSave.value) {
    errorMessage.value = 'Please add a title and content'
    return
  }

  isSaving.value = true
  errorMessage.value = ''

  try {
    const formData = new FormData()
    formData.append('title', title.value.trim())
    formData.append('content', content.value.trim())
    formData.append('status', isDraft.value ? 'draft' : 'published')

    if (linkedPortalId.value) {
      formData.append('portal_id', String(linkedPortalId.value))
    }

    if (linkedGoalId.value) {
      formData.append('goal_id', String(linkedGoalId.value))
    }

    // Upload images if any
    uploadedImages.value.forEach((img, index) => {
      formData.append('images', img.file, `write_image_${index}.jpg`)
    })

    let response
    if (isEditing.value) {
      // Update existing write
      response = await api.put(
        `/api/user/write/${writeId}`,
        formData,
        {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        }
      )
    } else {
      // Create new write
      response = await api.post(
        '/api/user/write',
        formData,
        {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        }
      )
    }

    if (response.data) {
      // Navigate back to profile
      router.push(`/profile/${userId}`)
    }
  } catch (err: any) {
    console.error('Save error:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to save content'
  } finally {
    isSaving.value = false
  }
}

async function loadExistingWrite() {
  if (!isEditing.value) return

  try {
    const response = await api.get(
      `/api/user/writes?users_id=${userId}`
    )

    const writes = response.data.result || []
    const existingWrite = writes.find((w: any) => w.id === writeId)

    if (existingWrite) {
      title.value = existingWrite.title || ''
      content.value = existingWrite.content || ''
      isDraft.value = existingWrite.status === 'draft'
      linkedPortalId.value = existingWrite.portal_id || null
      linkedGoalId.value = existingWrite.goal_id || null

      // Set editor content
      if (editor.value) {
        editor.value.innerHTML = content.value
      }
    }
  } catch (err) {
    console.error('Failed to load write:', err)
    errorMessage.value = 'Failed to load content'
  }
}

async function loadUserPortals() {
  try {
    const response = await api.get(
      `/api/portal/portals?users_id=${userId}`
    )
    userPortals.value = response.data.result || []
  } catch (err) {
    console.error('Failed to load portals:', err)
  }
}

async function loadUserGoals() {
  try {
    const response = await api.get(
      `/api/goals/list?users_id=${userId}`
    )
    userGoals.value = response.data.result || []
  } catch (err) {
    console.error('Failed to load goals:', err)
  }
}

// Lifecycle
onMounted(async () => {
  if (!token || !userId) {
    router.push('/login')
    return
  }

  await Promise.all([
    loadUserPortals(),
    loadUserGoals(),
    loadExistingWrite()
  ])
})
</script>

<style scoped>
/* Rich text editor styling */
[contenteditable="true"] {
  outline: 0px solid transparent;
}

[contenteditable="true"]:empty:before {
  content: attr(placeholder);
  color: #9CA3AF;
  pointer-events: none;
  display: block;
}

/* Prose styling for content */
.prose {
  color: #1f2937;
}

.prose h1 {
  font-size: 2em;
  font-weight: bold;
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.prose h2 {
  font-size: 1.5em;
  font-weight: bold;
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.prose h3 {
  font-size: 1.25em;
  font-weight: bold;
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.prose p {
  margin-top: 0.75em;
  margin-bottom: 0.75em;
}

.prose ul,
.prose ol {
  padding-left: 1.5em;
  margin-top: 0.75em;
  margin-bottom: 0.75em;
}

.prose li {
  margin-top: 0.25em;
  margin-bottom: 0.25em;
}

.prose a {
  color: #3b82f6;
  text-decoration: underline;
}

.prose strong {
  font-weight: bold;
}

.prose em {
  font-style: italic;
}
</style>
