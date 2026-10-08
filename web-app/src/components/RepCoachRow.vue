<!--
  RepCoachRow.vue
  Rep Coach, pinned at the top of the Chats list (phone and desktop styles).
-->

<template>
  <button
    type="button"
    class="w-full flex items-center text-left transition-colors"
    :class="[
      variant === 'mobile' ? 'py-4 px-4 hover:bg-gray-50' : 'gap-3 px-3 py-3 border-b border-gray-100 hover:bg-gray-50',
      selected ? 'bg-gray-100' : '',
    ]"
    :style="variant === 'mobile' ? 'min-height: 96px' : ''"
    @click="emit('select')"
  >
    <img
      :src="RepCoachAvatar"
      alt=""
      class="rounded-full shrink-0"
      :class="variant === 'mobile' ? 'w-16 h-16' : 'w-10 h-10'"
    />
    <span class="flex-1 min-w-0 flex flex-col" :class="variant === 'mobile' ? 'ml-3' : ''">
      <span class="flex items-center gap-1.5">
        <span class="font-semibold truncate" :class="variant === 'mobile' ? 'text-[17px]' : 'text-sm'">Rep Coach</span>
        <span class="text-[10px] font-semibold text-gray-600 border border-gray-300 rounded px-1 leading-[14px] shrink-0">AI</span>
        <svg
          class="ml-auto shrink-0 text-gray-400"
          :class="variant === 'mobile' ? 'w-4 h-4' : 'w-3.5 h-3.5'"
          viewBox="0 0 24 24"
          fill="currentColor"
          role="img"
          aria-label="Pinned"
        >
          <path d="M16 3a1 1 0 0 1 .7 1.7L15 6.4v4.2l2.7 2.7A1 1 0 0 1 17 15h-4v5.5a1 1 0 0 1-2 0V15H7a1 1 0 0 1-.7-1.7L9 10.6V6.4L7.3 4.7A1 1 0 0 1 8 3h8z" />
        </svg>
      </span>
      <span class="truncate text-gray-500" :class="variant === 'mobile' ? 'text-[15px] mt-1' : 'text-xs mt-1'">{{ preview }}</span>
    </span>
  </button>
</template>

<script setup lang="ts">
import RepCoachAvatar from '@/assets/RepCoachAvatar.svg';
import { useRepCoach } from '@/pages/utils/useRepCoach';

defineProps<{ variant: 'mobile' | 'desktop'; selected?: boolean }>();
const emit = defineEmits<{ (e: 'select'): void }>();
const { preview } = useRepCoach();
</script>
