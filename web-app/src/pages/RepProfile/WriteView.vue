<!--
  WriteView_Enhanced.vue
  Rep - Desktop Enhanced Writing Platform
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col" :class="{ 'distraction-free': distractionFreeMode }">
    <!-- Header (Hidden in distraction-free mode) -->
    <header v-if="!distractionFreeMode" class="flex items-center justify-between h-14 md:h-16 px-4 md:px-6 border-b shrink-0" style="background-color: #f7f7f7">
      <button @click="handleCancel" class="font-semibold hover:opacity-75 transition-opacity" style="color: #8cc65d">
        Cancel
      </button>
      <h1 class="font-bold text-lg md:text-xl">{{ isEditing ? 'Edit Content' : 'New Content' }}</h1>
      <button
        @click="handleSave"
        :disabled="isSaving || !canSave"
        class="text-yellow-600 font-bold disabled:opacity-50 hover:opacity-75 transition-opacity px-3 py-1 rounded-lg"
      >
        {{ isSaving ? 'Saving...' : 'Publish' }}
      </button>
    </header>

    <!-- Toolbar (Hidden in distraction-free mode) -->
    <WritingToolbar
      v-if="!distractionFreeMode"
      :activeFormats="activeFormats"
      :isMobile="isMobile"
      @format="execCommand"
      @insertLink="insertLink"
      @insertImage="insertImage"
      @insertCodeBlock="insertCodeBlock"
      @toggleDistraction="toggleDistractionFree"
    />

    <!-- Main Content -->
    <div class="flex-1 overflow-y-auto">
      <div
        class="mx-auto p-4 space-y-6 transition-all duration-300"
        :class="distractionFreeMode ? 'max-w-4xl md:py-16' : 'max-w-5xl md:p-8'"
      >
        <!-- Title Input -->
        <div>
          <input
            v-model="title"
            type="text"
            placeholder="Title"
            class="w-full text-2xl md:text-3xl lg:text-4xl font-bold border-none outline-none bg-transparent placeholder-gray-400 focus:placeholder-gray-500 transition-colors"
            @input="clearError"
            :class="{ 'text-center': distractionFreeMode }"
          />
        </div>

        <!-- Content Editor -->
        <div
          ref="editor"
          contenteditable="true"
          @input="handleContentChange"
          @paste="handlePaste"
          @keydown="handleKeyDown"
          @mouseup="handleEditorInteraction"
          @keyup="handleEditorInteraction"
          class="min-h-[400px] md:min-h-[600px] p-4 md:p-6 lg:p-8 bg-white border border-gray-300 rounded-lg outline-none prose prose-lg md:prose-xl max-w-none focus:ring-2 transition-all"
          :class="{
            'shadow-lg': !distractionFreeMode,
            'border-green-500': focusedEditor
          }"
          style="--tw-ring-color: #8cc65d"
          placeholder="Start writing your story..."
          @focus="focusedEditor = true"
          @blur="focusedEditor = false"
        ></div>

        <!-- Publish Status Toggle -->
        <div v-if="!distractionFreeMode" class="flex items-center justify-between p-4 md:p-6 bg-white border border-gray-300 rounded-lg shadow-sm hover:shadow-md transition-shadow">
          <div>
            <h3 class="font-semibold text-gray-700 text-base md:text-lg">Status</h3>
            <p class="text-sm md:text-base text-gray-500">
              {{ isDraft ? 'Save as draft or publish' : 'Published and visible to others' }}
            </p>
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
        <div v-if="errorMessage" class="p-3 md:p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm md:text-base">
          {{ errorMessage }}
        </div>
      </div>
    </div>

    <!-- Stats Bar -->
    <WriteStats
      :content="content"
      :saveStatus="saveStatus"
      :showAutoSave="true"
    />

    <!-- Keyboard Shortcuts Overlay -->
    <Transition name="fade">
      <div v-if="showShortcuts" @click="showShortcuts = false" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
        <div @click.stop class="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[80vh] overflow-y-auto">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold">Keyboard Shortcuts</h2>
            <button @click="showShortcuts = false" class="text-gray-600 hover:text-gray-800">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-2">
              <h3 class="font-semibold text-lg">Text Formatting</h3>
              <div class="space-y-1 text-sm">
                <div class="flex justify-between"><span>Bold</span><kbd>Ctrl/Cmd + B</kbd></div>
                <div class="flex justify-between"><span>Italic</span><kbd>Ctrl/Cmd + I</kbd></div>
                <div class="flex justify-between"><span>Underline</span><kbd>Ctrl/Cmd + U</kbd></div>
                <div class="flex justify-between"><span>Insert Link</span><kbd>Ctrl/Cmd + K</kbd></div>
              </div>
            </div>

            <div class="space-y-2">
              <h3 class="font-semibold text-lg">Editor Actions</h3>
              <div class="space-y-1 text-sm">
                <div class="flex justify-between"><span>Save</span><kbd>Ctrl/Cmd + S</kbd></div>
                <div class="flex justify-between"><span>Distraction-Free</span><kbd>F11</kbd></div>
                <div class="flex justify-between"><span>Shortcuts Help</span><kbd>Ctrl/Cmd + /</kbd></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Distraction-Free Exit Button -->
    <Transition name="fade">
      <div v-if="distractionFreeMode" class="fixed top-4 right-4 z-30">
        <button
          @click="toggleDistractionFree"
          class="bg-gray-800 bg-opacity-75 hover:bg-opacity-100 text-white px-4 py-2 rounded-lg flex items-center gap-2 transition-all"
          title="Exit Distraction-Free Mode (F11)"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
          <span class="hidden md:inline">Exit Focus Mode</span>
        </button>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import api from '@/pages/utils/api'
import WritingToolbar from '@/components/WritingToolbar.vue'
import WriteStats from '@/components/WriteStats.vue'
import { BREAKPOINTS } from '@/constants/breakpoints'
import TurndownService from 'turndown'
import { marked } from 'marked'

// Enable breaks: single \n renders as <br> (matches user expectation from Enter key)
marked.use({ breaks: true })

const turndown = new TurndownService({ headingStyle: 'atx', bulletListMarker: '-' })

// Treat <div> as paragraph breaks (contenteditable uses <div> not <p> for Enter key)
turndown.addRule('divParagraph', {
  filter: 'div',
  replacement: function (content: string) {
    return '\n\n' + content.trim() + '\n\n'
  }
})

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
const isSaving = ref(false)
const errorMessage = ref('')
const isEditing = computed(() => writeId !== null)
const distractionFreeMode = ref(false)
const showShortcuts = ref(false)
const focusedEditor = ref(false)
const isMobile = ref(window.innerWidth < BREAKPOINTS.DESKTOP)
const activeFormats = ref<string[]>([])
const saveStatus = ref<'idle' | 'saving' | 'saved' | 'error'>('idle')
const autoSaveTimer = ref<NodeJS.Timeout | null>(null)

// Refs
const editor = ref<HTMLDivElement | null>(null)

// Store the last selection to restore it when toolbar buttons are clicked
let savedSelection: Range | null = null

// Computed
const canSave = computed(() => {
  return title.value.trim().length > 0 && content.value.trim().length > 0
})

// Save selection whenever it changes
function saveSelection() {
  const selection = window.getSelection()
  if (selection && selection.rangeCount > 0) {
    const range = selection.getRangeAt(0)
    const editorEl = editor.value
    if (editorEl && editorEl.contains(range.commonAncestorContainer)) {
      savedSelection = range.cloneRange()
    }
  }
}

// Restore the saved selection
function restoreSelection() {
  if (savedSelection) {
    const selection = window.getSelection()
    selection?.removeAllRanges()
    selection?.addRange(savedSelection)
  }
}

// Methods
function execCommand(command: string, value: any = null) {
  try {
    const editorEl = editor.value
    if (!editorEl) return

    // Restore the saved selection before executing command
    restoreSelection()

    // Focus the editor
    editorEl.focus()

    // Execute the command
    if (command === 'formatBlock') {
      document.execCommand(command, false, value)
    } else {
      document.execCommand(command, false, value)
    }

    // Save the new selection after command
    saveSelection()
    checkActiveFormats()
  } catch (e) {
    console.error('Command failed:', command, e)
  }
}

function insertLink() {
  const url = prompt('Enter URL:')
  if (url) {
    execCommand('createLink', url)
  }
}

function insertImage() {
  const url = prompt('Enter image URL:')
  if (url) {
    execCommand('insertImage', url)
  }
}

function insertCodeBlock() {
  const code = prompt('Enter code:')
  if (code) {
    const pre = document.createElement('pre')
    const codeEl = document.createElement('code')
    codeEl.textContent = code
    codeEl.className = 'bg-gray-100 p-2 rounded block'
    pre.appendChild(codeEl)
    const selection = window.getSelection()
    if (selection && selection.rangeCount > 0) {
      const range = selection.getRangeAt(0)
      range.deleteContents()
      range.insertNode(pre)
    }
    editor.value?.focus()
  }
}

function checkActiveFormats() {
  const formats: string[] = []
  if (document.queryCommandState('bold')) formats.push('bold')
  if (document.queryCommandState('italic')) formats.push('italic')
  if (document.queryCommandState('underline')) formats.push('underline')
  if (document.queryCommandState('strikeThrough')) formats.push('strikeThrough')
  if (document.queryCommandState('insertUnorderedList')) formats.push('insertUnorderedList')
  if (document.queryCommandState('insertOrderedList')) formats.push('insertOrderedList')
  activeFormats.value = formats
}

function handleEditorInteraction() {
  saveSelection()
  checkActiveFormats()
}

function handleContentChange() {
  if (editor.value) {
    content.value = editor.value.innerHTML
    checkActiveFormats()
    scheduleAutoSave()
  }
}

function handlePaste(e: ClipboardEvent) {
  e.preventDefault()
  const text = e.clipboardData?.getData('text/plain')
  if (text) {
    document.execCommand('insertText', false, text)
  }
}

function handleKeyDown(e: KeyboardEvent) {
  // Ctrl/Cmd + B = Bold
  if ((e.ctrlKey || e.metaKey) && e.key === 'b') {
    e.preventDefault()
    execCommand('bold')
  }
  // Ctrl/Cmd + I = Italic
  else if ((e.ctrlKey || e.metaKey) && e.key === 'i') {
    e.preventDefault()
    execCommand('italic')
  }
  // Ctrl/Cmd + U = Underline
  else if ((e.ctrlKey || e.metaKey) && e.key === 'u') {
    e.preventDefault()
    execCommand('underline')
  }
  // Ctrl/Cmd + K = Link
  else if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
    e.preventDefault()
    insertLink()
  }
  // Ctrl/Cmd + S = Save
  else if ((e.ctrlKey || e.metaKey) && e.key === 's') {
    e.preventDefault()
    handleSave()
  }
  // Ctrl/Cmd + / = Shortcuts
  else if ((e.ctrlKey || e.metaKey) && e.key === '/') {
    e.preventDefault()
    showShortcuts.value = !showShortcuts.value
  }
  // F11 = Distraction-Free
  else if (e.key === 'F11') {
    e.preventDefault()
    toggleDistractionFree()
  }
}

function toggleDistractionFree() {
  distractionFreeMode.value = !distractionFreeMode.value
}

function scheduleAutoSave() {
  if (autoSaveTimer.value) {
    clearTimeout(autoSaveTimer.value)
  }

  // Auto-save after 30 seconds of inactivity (UI only for now)
  autoSaveTimer.value = setTimeout(() => {
    if (canSave.value) {
      saveStatus.value = 'saving'
      setTimeout(() => {
        saveStatus.value = 'saved'
        setTimeout(() => {
          saveStatus.value = 'idle'
        }, 2000)
      }, 1000)
    }
  }, 30000)
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
  // Always read the editor's current HTML directly before saving
  // (don't rely on @input having synced content.value)
  if (editor.value) {
    content.value = editor.value.innerHTML
  }

  if (!canSave.value) {
    errorMessage.value = 'Please add a title and content'
    return
  }

  isSaving.value = true
  saveStatus.value = 'saving'
  errorMessage.value = ''

  try {
    const editorHtml = editor.value ? editor.value.innerHTML : content.value
    const payload = {
      title: title.value.trim(),
      content: turndown.turndown(editorHtml),
      content_format: 'markdown',
      status: isDraft.value ? 'draft' : 'published'
    }

    let response
    if (isEditing.value) {
      response = await api.put(`/api/user/write/${writeId}`, payload)
    } else {
      response = await api.post('/api/user/write', payload)
    }

    if (response.data) {
      saveStatus.value = 'saved'
      setTimeout(() => {
        router.push(`/profile/${userId}`)
      }, 500)
    }
  } catch (err: any) {
    console.error('Save error:', err)
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to save content'
    saveStatus.value = 'error'
  } finally {
    isSaving.value = false
  }
}

async function loadExistingWrite() {
  if (!isEditing.value) return

  try {
    const response = await api.get(`/api/user/writes?users_id=${userId}`)
    const writes = response.data.result || []
    const existingWrite = writes.find((w: any) => w.id === writeId)

    if (existingWrite) {
      title.value = existingWrite.title || ''
      content.value = existingWrite.content || ''
      isDraft.value = existingWrite.status === 'draft'

      if (editor.value) {
        if (existingWrite.content_format === 'markdown') {
          editor.value.innerHTML = marked.parse(content.value) as string
        } else {
          editor.value.innerHTML = content.value.replace(/\n/g, '<br>')
        }
        // Sync content.value with the actual editor HTML so Turndown
        // always receives HTML (not raw markdown) on save
        content.value = editor.value.innerHTML
      }
    }
  } catch (err) {
    console.error('Failed to load write:', err)
    errorMessage.value = 'Failed to load content'
  }
}

function handleResize() {
  isMobile.value = window.innerWidth < BREAKPOINTS.DESKTOP
}

// Lifecycle
onMounted(async () => {
  if (!userId) {
    router.push('/login')
    return
  }

  await loadExistingWrite()
  window.addEventListener('resize', handleResize)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', handleResize)
  if (autoSaveTimer.value) {
    clearTimeout(autoSaveTimer.value)
  }
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

/* Distraction-free mode */
.distraction-free {
  background-color: #fafafa;
}

.distraction-free [contenteditable="true"] {
  border: none;
  box-shadow: none;
  min-height: 70vh;
}

/* Prose styling for content */
.prose {
  color: #1f2937;
  line-height: 1.75;
}

.prose h1 {
  font-size: 2.25em;
  font-weight: bold;
  margin-top: 0.5em;
  margin-bottom: 0.5em;
  line-height: 1.2;
}

.prose h2 {
  font-size: 1.875em;
  font-weight: bold;
  margin-top: 1em;
  margin-bottom: 0.5em;
  line-height: 1.3;
}

.prose h3 {
  font-size: 1.5em;
  font-weight: bold;
  margin-top: 1em;
  margin-bottom: 0.5em;
  line-height: 1.4;
}

.prose p {
  margin-top: 1em;
  margin-bottom: 1em;
}

.prose ul,
.prose ol {
  padding-left: 1.75em;
  margin-top: 1em;
  margin-bottom: 1em;
}

.prose li {
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.prose a {
  color: #3b82f6;
  text-decoration: underline;
  transition: color 0.15s;
}

.prose a:hover {
  color: #2563eb;
}

.prose strong {
  font-weight: 700;
}

.prose em {
  font-style: italic;
}

.prose blockquote {
  border-left: 4px solid #8cc65d;
  padding-left: 1em;
  font-style: italic;
  color: #4b5563;
  margin: 1.5em 0;
}

.prose code {
  background-color: #f3f4f6;
  padding: 0.2em 0.4em;
  border-radius: 0.25em;
  font-size: 0.875em;
  font-family: 'Courier New', monospace;
}

.prose pre {
  background-color: #1f2937;
  color: #f9fafb;
  padding: 1em;
  border-radius: 0.5em;
  overflow-x: auto;
  margin: 1em 0;
}

.prose pre code {
  background-color: transparent;
  padding: 0;
  color: inherit;
  font-size: 0.875em;
}

.prose hr {
  border: none;
  border-top: 2px solid #e5e7eb;
  margin: 2em 0;
}

/* Keyboard shortcut badge */
kbd {
  background-color: #f3f4f6;
  border: 1px solid #d1d5db;
  border-radius: 0.25rem;
  padding: 0.125rem 0.375rem;
  font-family: monospace;
  font-size: 0.75rem;
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
