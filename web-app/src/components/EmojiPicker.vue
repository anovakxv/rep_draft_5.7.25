<template>
  <Transition name="fade">
    <div v-if="show" @click="close" class="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-center justify-center p-4">
      <div @click.stop class="bg-white rounded-lg shadow-xl p-4 max-w-sm w-full">
        <div class="flex justify-between items-center mb-3">
          <h3 class="font-semibold text-gray-800">Add Reaction</h3>
          <button @click="close" class="text-gray-500 hover:text-gray-700 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Popular Emojis -->
        <div class="grid grid-cols-8 gap-2 mb-3">
          <button
            v-for="emoji in popularEmojis"
            :key="emoji"
            @click="selectEmoji(emoji)"
            class="p-2 text-2xl hover:bg-gray-100 rounded-lg transition-all hover:scale-125 active:scale-95"
          >
            {{ emoji }}
          </button>
        </div>

        <!-- All Emojis -->
        <div class="border-t pt-3">
          <p class="text-xs text-gray-500 mb-2">All Reactions</p>
          <div class="grid grid-cols-8 gap-2 max-h-48 overflow-y-auto">
            <button
              v-for="emoji in allEmojis"
              :key="emoji"
              @click="selectEmoji(emoji)"
              class="p-2 text-xl hover:bg-gray-100 rounded-lg transition-all hover:scale-110 active:scale-95"
            >
              {{ emoji }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
const props = defineProps<{
  show: boolean
  messageId: number | null
}>()

const emit = defineEmits<{
  close: []
  selectEmoji: [messageId: number, emoji: string]
}>()

// Popular emojis (most commonly used)
const popularEmojis = [
  '👍', '❤️', '😂', '😮', '😢', '🙏', '🎉', '🔥'
]

// All available emojis
const allEmojis = [
  // Smileys
  '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
  '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
  '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
  '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
  '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
  '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
  '🤢', '🤮', '🤧', '🥵', '🥶', '😶‍🌫️', '😵', '🤯',
  '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁',
  '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨',
  '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞',
  '😓', '😩', '😫', '🥱', '😤', '😡', '😠', '🤬',

  // Hands & Hearts
  '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙',
  '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐',
  '🖖', '👋', '🤝', '🙏', '💪', '🦾', '🦿', '🦵',
  '🦶', '👂', '👃', '🧠', '🦷', '🦴', '👀', '👁',
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
  '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
  '💘', '💝', '💟', '❤️‍🔥', '❤️‍🩹',

  // Animals & Nature
  '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
  '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🙈',
  '🙉', '🙊', '🐔', '🐧', '🐦', '🐤', '🦆', '🦅',
  '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛',
  '🦋', '🐌', '🐞', '🐜', '🕷', '🦂', '🐢', '🐍',

  // Food & Drink
  '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈',
  '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🥑',
  '🍆', '🥔', '🥕', '🌽', '🌶', '🥒', '🥬', '🥦',
  '🍞', '🥐', '🥖', '🥨', '🥯', '🧇', '🥞', '🧈',
  '🍕', '🍔', '🍟', '🌭', '🥪', '🌮', '🌯', '🥙',
  '🍿', '🧂', '🥫', '🍱', '🍘', '🍙', '🍚', '🍛',

  // Activities & Objects
  '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉',
  '🥏', '🎱', '🏓', '🏸', '🥅', '🏒', '🏑', '🥍',
  '🏏', '⛳', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽',
  '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🥈', '🥉',
  '⭐', '🌟', '✨', '💫', '💥', '💢', '💬', '💭',
  '💤', '💮', '🏵', '🎗', '🎫', '🎖', '🔥', '💧',
]

function selectEmoji(emoji: string) {
  if (props.messageId !== null) {
    emit('selectEmoji', props.messageId, emoji)
  }
  close()
}

function close() {
  emit('close')
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
