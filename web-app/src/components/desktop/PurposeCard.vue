<!--
  PurposeCard.vue
  One Purpose as a rolodex card: the 16:9 pitch-deck image beside the Purpose and its
  Goal Teams' progress (Purpose → Value). Used by the Purpose feed and the Person card.
  layout="wide": image left, details right (Purpose mode, profiles)
  layout="pane": stacked, compact (the right-hand context pane)
  The parent loads `images` and `goals` (undefined = still loading).
-->

<template>
  <RouterLink
    :to="`/portal/${portal.id}`"
    class="group block bg-white overflow-hidden border rounded border-gray-200 hover:border-gray-300 transition"
    :class="wide ? 'flex hover:shadow-md' : 'hover:shadow-sm'"
  >
    <!-- Always 16:9 (self-start stops the flex row stretching it to the text's height);
         object-contain so a slide is never cropped, even if its file isn't exactly 16:9 -->
    <div class="relative bg-gray-100 shrink-0 aspect-video" :class="wide ? 'w-[46%] max-w-[480px] self-start' : 'w-full'">
      <img v-if="currentImage" :src="currentImage" :alt="portal.name" loading="lazy" class="absolute inset-0 w-full h-full object-contain" />
      <template v-if="(images?.length ?? 0) > 1">
        <button
          v-if="index > 0"
          type="button"
          aria-label="Previous image"
          class="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition"
          @click.prevent.stop="index--"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
        </button>
        <button
          v-if="index < (images?.length ?? 0) - 1"
          type="button"
          aria-label="Next image"
          class="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition"
          @click.prevent.stop="index++"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" /></svg>
        </button>
        <div class="absolute bottom-2 inset-x-0 flex justify-center gap-1 pointer-events-none">
          <span v-for="(_, i) in images" :key="i" class="w-1.5 h-1.5 rounded-full" :class="i === index ? 'bg-white' : 'bg-white/40'"></span>
        </div>
      </template>
    </div>

    <!-- Purpose + Value -->
    <div class="min-w-0 flex flex-col" :class="wide ? 'flex-1 p-5' : 'p-3'">
      <p class="font-bold text-gray-900 leading-snug" :class="wide ? 'text-lg line-clamp-2' : 'text-[15px] line-clamp-1'">{{ portal.name }}</p>
      <p v-if="portal.subtitle?.trim()" class="text-gray-500 leading-snug mt-0.5 line-clamp-2" :class="wide ? 'text-sm' : 'text-xs'">{{ portal.subtitle }}</p>

      <div :class="wide ? 'mt-4 flex-1' : 'mt-2.5'">
        <p v-if="wide && goals?.length" class="text-[11px] font-semibold uppercase tracking-wide text-gray-400 mb-2">Goal Teams</p>
        <div :class="wide ? 'space-y-3' : 'space-y-2'">
          <div v-if="!goals" class="space-y-1.5 animate-pulse">
            <div class="h-2.5 bg-gray-100 rounded w-3/4"></div>
            <div class="h-1.5 bg-gray-100 rounded w-full"></div>
          </div>
          <p v-else-if="!goals.length" class="text-xs text-gray-400 italic">No active Goal Teams yet</p>
          <template v-else>
            <div v-for="goal in goals.slice(0, wide ? 3 : 2)" :key="goal.id">
              <div class="flex items-center justify-between gap-2">
                <p class="font-semibold text-gray-800 truncate" :class="wide ? 'text-sm' : 'text-xs'">{{ goal.title }}</p>
                <span class="text-gray-500 shrink-0" :class="wide ? 'text-xs font-medium' : 'text-[11px]'">{{ pct(goal) }}%</span>
              </div>
              <div class="mt-1 flex items-center gap-2">
                <div class="flex-1 bg-gray-100 rounded-full overflow-hidden" :class="wide ? 'h-2' : 'h-1.5'">
                  <div class="h-full rounded-full transition-all duration-300" style="background: #8cc65d" :style="{ width: `${pct(goal)}%` }"></div>
                </div>
                <button
                  type="button"
                  class="shrink-0 rounded-full flex items-center justify-center hover:opacity-80"
                  :class="wide ? 'w-6 h-6' : 'w-5 h-5'"
                  style="background: #8cc65d"
                  :disabled="busyGoalId === goal.id"
                  :title="goal.chats_id ? 'Message this Goal Team' : 'Start a Goal Team chat'"
                  :aria-label="`Message the ${goal.title} Goal Team`"
                  @click.prevent.stop="emit('goal-chat', goal)"
                >
                  <svg v-if="busyGoalId === goal.id" class="h-3 w-3 text-white animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
                  <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
                </button>
              </div>
            </div>
            <p v-if="wide && goals.length > 3" class="text-xs text-gray-400">+ {{ goals.length - 3 }} more Goal Team{{ goals.length - 3 === 1 ? '' : 's' }}</p>
          </template>
        </div>
      </div>

      <p v-if="wide" class="mt-4 text-sm font-semibold group-hover:underline" style="color: #006600">View Purpose →</p>
    </div>
  </RouterLink>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { RouterLink } from 'vue-router';

const props = defineProps<{
  portal: { id: number; name: string; subtitle?: string; mainImageUrl?: string };
  layout: 'wide' | 'pane';
  images?: string[];
  goals?: any[];
  busyGoalId?: number | null;
}>();

const emit = defineEmits<{ (e: 'goal-chat', goal: any): void }>();

const wide = computed(() => props.layout === 'wide');
const index = ref(0);
watch(() => props.images, () => { index.value = 0; });

const currentImage = computed(() => props.images?.[index.value] ?? props.portal.mainImageUrl ?? '');

function pct(goal: any): number {
  return Math.round(Math.min(100, Math.max(0, (goal.progress ?? 0) * 100)));
}
</script>
