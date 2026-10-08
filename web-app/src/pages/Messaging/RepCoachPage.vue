<!--
  RepCoachPage.vue
  Full-screen Rep Coach (phones, or a direct link to /coach).
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <div class="flex-1 min-h-0 w-full mx-auto flex flex-col" style="max-width: 768px">
      <RepCoachChat v-if="enabled" />
      <div v-else-if="enabled === false" class="flex-1 flex flex-col items-center justify-center gap-4 px-8 text-center">
        <img :src="RepCoachAvatar" alt="" class="w-16 h-16 rounded-full" />
        <p class="text-gray-600">Rep Coach isn't available right now.</p>
        <RouterLink to="/main" class="px-6 py-2.5 rounded-full text-white text-sm font-semibold" style="background-color: #8cc65d">
          Back to Rep
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { RouterLink } from 'vue-router';
import RepCoachChat from '@/components/RepCoachChat.vue';
import RepCoachAvatar from '@/assets/RepCoachAvatar.svg';
import { useRepCoach } from '@/pages/utils/useRepCoach';

const { enabled, checkStatus } = useRepCoach();
onMounted(checkStatus);
</script>
