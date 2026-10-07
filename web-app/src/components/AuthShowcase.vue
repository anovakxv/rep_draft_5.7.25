<!--
  AuthShowcase.vue
  Rep

  The brand side of the log-in and sign-up pages: a left panel on desktop, a top band on phones.
  Shows (in order of preference):
  1. the purpose or goal behind a shared link, when the visitor arrived from one
  2. the "living wall" of real purposes from the public list
  3. a plain pitch, when there aren't enough purposes to fill the wall
-->

<template>
  <!-- Desktop: left panel -->
  <aside class="hidden lg:flex relative overflow-hidden shrink-0 w-[42%] max-w-[600px] bg-[#113213] text-white">
    <template v-if="!sharedLink && wallState !== 'fallback'">
      <div
        aria-hidden="true"
        class="absolute -left-10 -top-36 w-[600px] h-[1100px] flex gap-3.5 rotate-[-7deg] transition-opacity duration-700"
        :class="wallState === 'ready' ? 'opacity-100' : 'opacity-0'"
      >
        <div
          v-for="(column, i) in wallColumns"
          :key="i"
          class="w-[180px] shrink-0 flex flex-col"
          :class="i === 1 ? 'wall-down' : i === 2 ? 'wall-up wall-slow' : 'wall-up'"
        >
          <div v-for="(purpose, j) in [...column, ...column]" :key="j" class="pb-3.5">
            <div class="rounded-xl overflow-hidden bg-white text-[#101828] shadow-[0_10px_24px_rgba(0,0,0,0.3)]">
              <img v-if="purpose.imageUrl" :src="purpose.imageUrl" alt="" class="block w-full h-24 object-cover" loading="lazy" decoding="async" />
              <div
                v-else
                class="h-24 flex items-end px-3 py-2 text-[40px] leading-none font-bold text-[rgba(17,50,19,0.28)]"
                :style="{ background: tint(purpose.id) }"
              >{{ purpose.name.charAt(0) }}</div>
              <div class="px-3 pt-2.5 pb-3">
                <p class="text-[13px] leading-[17px] font-semibold line-clamp-2">{{ purpose.name }}</p>
                <p v-if="purpose.subtitle" class="text-xs leading-4 text-[#667085] truncate">{{ purpose.subtitle }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="wall-shade absolute inset-0"></div>
    </template>

    <div class="relative flex-1 flex flex-col px-14 pt-12 pb-10">
      <div class="flex items-center gap-2.5">
        <img :src="REPLogo" alt="" class="w-8 h-8 rounded-full" />
        <span class="text-xl font-semibold tracking-[-0.01em]">Rep</span>
      </div>

      <!-- 1. Shared link -->
      <div v-if="sharedLink" class="flex-1 flex flex-col justify-center gap-5 py-10">
        <p class="text-[13px] leading-[18px] font-semibold tracking-[0.08em] uppercase text-white/60">You were sent a link to</p>
        <div class="rounded-xl overflow-hidden bg-white text-[#101828] shadow-[0_16px_40px_rgba(0,0,0,0.28)]">
          <img v-if="sharedLink.imageUrl" :src="sharedLink.imageUrl" alt="" class="block w-full h-[200px] object-cover" />
          <div v-else class="h-[120px] flex items-end px-6 py-4 text-6xl leading-none font-bold text-[rgba(17,50,19,0.28)] bg-[#c9d9b8]">{{ sharedLink.name.charAt(0) }}</div>
          <div class="px-6 pt-5 pb-[22px] flex flex-col gap-1.5">
            <h1 class="text-xl leading-[26px] font-semibold tracking-[-0.01em]">{{ sharedLink.name }}</h1>
            <p v-if="sharedLink.subtitle" class="text-[15px] leading-[22px] text-[#475467]">{{ sharedLink.subtitle }}</p>
          </div>
        </div>
        <p class="text-[15px] leading-[22px] text-white/75">{{ sharedLinkNote }}</p>
      </div>

      <!-- 3. Plain pitch -->
      <div v-else-if="wallState === 'fallback'" class="flex-1 flex flex-col justify-center gap-10 py-10">
        <div class="flex flex-col gap-4">
          <h1 class="text-4xl leading-[1.15] font-semibold tracking-[-0.015em] text-balance">Rep something you believe in.</h1>
          <p class="text-[17px] leading-[1.55] text-white/75 max-w-[400px]">Rep connects you with causes, communities and people near you, so you can make real progress together.</p>
        </div>
        <ul class="flex flex-col border-b border-white/10">
          <li v-for="point in pitchPoints" :key="point.title" class="flex items-start gap-3.5 py-4 border-t border-white/10">
            <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="#8cc65d" stroke-width="2.5" class="shrink-0 mt-0.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" /></svg>
            <div class="flex flex-col gap-0.5 min-w-0">
              <p class="text-[15px] leading-[22px] font-semibold">{{ point.title }}</p>
              <p class="text-[15px] leading-[22px] text-white/65">{{ point.detail }}</p>
            </div>
          </li>
        </ul>
      </div>

      <!-- 2. Living wall caption -->
      <div v-else class="flex-1 flex flex-col justify-end gap-3 pt-10 pb-9">
        <p class="text-[13px] leading-[18px] font-semibold tracking-[0.08em] uppercase text-[#8cc65d]">Happening on Rep</p>
        <h1 class="text-4xl leading-[1.15] font-semibold tracking-[-0.015em] text-balance">Rep something you believe in.</h1>
        <p class="text-base leading-[1.55] text-white/75 max-w-[380px]">Real causes, started by people near you. Join one, or start your own.</p>
      </div>

      <p class="text-[13px] leading-[18px] text-white/50">© {{ year }} Networked Capital Inc.</p>
    </div>
  </aside>

  <!-- Phones and tablets: top band -->
  <header class="lg:hidden shrink-0 overflow-hidden bg-[#113213] text-white py-[18px] flex flex-col gap-3.5">
    <div class="px-6 flex items-center gap-2">
      <img :src="REPLogo" alt="" class="w-7 h-7 rounded-full" />
      <span class="text-lg font-semibold tracking-[-0.01em]">Rep</span>
    </div>

    <div v-if="sharedLink" class="px-6 flex flex-col gap-2.5">
      <p class="text-xs leading-4 font-semibold tracking-[0.08em] uppercase text-white/60">You were sent a link to</p>
      <div class="flex items-center gap-3 p-3 rounded-[10px] bg-white text-[#101828]">
        <img v-if="sharedLink.imageUrl" :src="sharedLink.imageUrl" alt="" class="w-14 h-14 shrink-0 rounded-lg object-cover" />
        <div v-else class="w-14 h-14 shrink-0 rounded-lg bg-[#c9d9b8] flex items-center justify-center text-2xl font-bold text-[rgba(17,50,19,0.4)]">{{ sharedLink.name.charAt(0) }}</div>
        <div class="flex flex-col gap-0.5 min-w-0">
          <h1 class="text-base leading-[22px] font-semibold truncate">{{ sharedLink.name }}</h1>
          <p v-if="sharedLink.subtitle" class="text-[13px] leading-[18px] text-[#667085] truncate">{{ sharedLink.subtitle }}</p>
        </div>
      </div>
    </div>

    <template v-else>
      <div
        v-if="wallState !== 'fallback'"
        aria-hidden="true"
        class="flex flex-col gap-2 transition-opacity duration-700"
        :class="wallState === 'ready' ? 'opacity-100' : 'opacity-0'"
      >
        <div v-for="(row, i) in marqueeRows" :key="i" class="flex w-max" :class="i === 0 ? 'marquee-left' : 'marquee-right'">
          <div v-for="(purpose, j) in [...row, ...row]" :key="j" class="pr-2">
            <div
              class="flex items-center gap-2 h-[34px] pl-1 pr-3.5 rounded-full whitespace-nowrap"
              :class="i === 0 ? 'bg-white text-[#101828]' : 'bg-white/10 text-white border border-[#8cc65d]/40'"
            >
              <img v-if="purpose.imageUrl" :src="purpose.imageUrl" alt="" class="w-[26px] h-[26px] rounded-full object-cover" loading="lazy" decoding="async" />
              <span
                v-else
                class="w-[26px] h-[26px] rounded-full flex items-center justify-center text-xs font-bold text-[rgba(17,50,19,0.55)]"
                :style="{ background: tint(purpose.id) }"
              >{{ purpose.name.charAt(0) }}</span>
              <span class="text-[13px] font-semibold">{{ purpose.name }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="px-6 flex flex-col gap-1.5">
        <h1 class="text-[22px] leading-[1.2] font-semibold tracking-[-0.01em] text-balance">Rep something you believe in.</h1>
        <p v-if="wallState === 'fallback'" class="text-[15px] leading-[22px] text-white/75">Causes, communities and people near you, all in one place.</p>
      </div>
    </template>
  </header>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import REPLogo from '@/assets/REPLogo.png'
import { loadWallPurposes, MIN_WALL_PURPOSES, type SharedLink, type WallPurpose } from '@/pages/utils/authShowcase'

const props = defineProps<{
  sharedLink: SharedLink | null
  mode: 'login' | 'register'
}>()

const year = new Date().getFullYear()
const purposes = ref<WallPurpose[]>([])
const wallState = ref<'loading' | 'ready' | 'fallback'>('loading')

const pitchPoints = [
  { title: 'Find a purpose', detail: 'Join causes and communities you care about.' },
  { title: 'Meet the right people', detail: 'Connect with others working on the same things.' },
  { title: 'Team up on goals', detail: 'Set a goal with a team and track progress together.' },
]

const sharedLinkNote = computed(() =>
  props.mode === 'login'
    ? 'Log in to see it, or create a free account to join.'
    : 'Create a free account to join, or log in if you already have one.'
)

// Repeats the list until there are `count` slots, so a short list still fills the wall
function fill(count: number, offset = 0): WallPurpose[] {
  const list = purposes.value
  if (!list.length) return []
  return Array.from({ length: count }, (_, i) => list[(i + offset) % list.length])
}

// 3 columns of 7 cards: tall enough to cover the panel on large screens while they drift
const wallColumns = computed(() => {
  const slots = fill(21)
  return [slots.slice(0, 7), slots.slice(7, 14), slots.slice(14, 21)]
})

const marqueeRows = computed(() => [fill(6), fill(6, 6)])

const tints = ['#c9d9b8', '#d6cbb6', '#b8c9d9', '#c4d4cf', '#d9c4b8', '#cfd9b8']
function tint(id: number) {
  return tints[Math.abs(id) % tints.length]
}

onMounted(async () => {
  const list = await loadWallPurposes()
  purposes.value = list
  wallState.value = list.length >= MIN_WALL_PURPOSES ? 'ready' : 'fallback'
})
</script>

<style scoped>
.wall-shade {
  background: linear-gradient(
    180deg,
    rgba(17, 50, 19, 0.96) 0%,
    rgba(17, 50, 19, 0.86) 11%,
    rgba(17, 50, 19, 0) 25%,
    rgba(17, 50, 19, 0) 34%,
    rgba(17, 50, 19, 0.94) 58%,
    #113213 72%
  );
}

@keyframes wall-up {
  from { transform: translateY(0); }
  to { transform: translateY(-50%); }
}
@keyframes wall-down {
  from { transform: translateY(-50%); }
  to { transform: translateY(0); }
}
@keyframes marquee-left {
  from { transform: translateX(0); }
  to { transform: translateX(-50%); }
}
@keyframes marquee-right {
  from { transform: translateX(-50%); }
  to { transform: translateX(0); }
}

.wall-up { animation: wall-up 70s linear infinite; }
.wall-down { animation: wall-down 80s linear infinite; }
.wall-slow { animation-duration: 95s; }
.marquee-left { animation: marquee-left 45s linear infinite; }
.marquee-right { animation: marquee-right 52s linear infinite; }

@media (prefers-reduced-motion: reduce) {
  .wall-up,
  .wall-down,
  .marquee-left,
  .marquee-right {
    animation: none;
  }
}
</style>
