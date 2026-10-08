<!--
  RepCoachChat.vue
  Rep Coach conversation: full screen on phones (/coach), embedded in the desktop
  dashboard's inline chat area. Coach replies are rendered as text plus cards;
  nothing from a reply is ever inserted as HTML.
-->

<template>
  <div class="flex flex-col h-full min-h-0 bg-white">
    <!-- Header -->
    <header
      class="shrink-0 flex items-center gap-2.5 border-b border-gray-200"
      :class="embedded ? 'px-4 py-2.5 bg-white' : 'h-14 px-2'"
      :style="embedded ? '' : 'background-color: #f7f7f7'"
    >
      <button
        v-if="!embedded"
        type="button"
        aria-label="Back"
        class="w-11 h-11 flex items-center justify-center shrink-0"
        style="color: #8cc65d"
        @click="goBack"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <img :src="RepCoachAvatar" alt="" class="w-8 h-8 rounded-full shrink-0" />
      <div class="min-w-0">
        <p class="flex items-center gap-1.5 font-semibold text-[15px] leading-tight">
          Rep Coach
          <span class="text-[10px] font-semibold text-gray-600 border border-gray-300 rounded px-1 leading-[14px]">AI</span>
        </p>
        <p class="text-xs text-gray-500 leading-tight">Suggests. You decide.</p>
      </div>
      <button
        v-if="messages.length"
        type="button"
        class="ml-auto text-sm text-gray-500 hover:text-gray-800 px-3 h-10 rounded-lg"
        @click="startOver"
      >
        New chat
      </button>
    </header>

    <!-- Messages -->
    <div ref="listRef" class="flex-1 min-h-0 overflow-y-auto px-3 lg:px-4 py-4 flex flex-col gap-3" aria-live="polite">
      <!-- Welcome -->
      <div class="flex items-end gap-2 max-w-[85%]">
        <img :src="RepCoachAvatar" alt="" class="w-6 h-6 rounded-full shrink-0" />
        <div class="bg-gray-100 rounded-2xl rounded-bl-sm px-3.5 py-2.5 text-[15px] leading-snug">
          Hi! I'm Rep Coach. Tell me what you want to make progress on, and I'll find Purposes, people and Goal Teams on Rep that can help.
        </div>
      </div>
      <div v-if="!messages.length" class="flex flex-wrap gap-2 pl-8">
        <button
          v-for="s in starters"
          :key="s"
          type="button"
          class="px-3.5 py-2 min-h-[2.25rem] rounded-full border border-gray-300 text-sm font-medium leading-tight text-gray-800 text-left hover:bg-gray-50 disabled:opacity-50"
          :disabled="sending"
          @click="send(s)"
        >
          {{ s }}
        </button>
      </div>

      <template v-for="(m, i) in messages" :key="i">
        <!-- Member -->
        <div v-if="m.role === 'user'" class="self-end max-w-[85%] rounded-2xl rounded-br-sm px-3.5 py-2.5 text-[15px] leading-snug whitespace-pre-wrap break-words bg-black" style="color: #8cc65d">{{ m.text }}</div>

        <!-- Coach -->
        <div v-else class="flex items-end gap-2 max-w-[92%] lg:max-w-[85%]">
          <img :src="RepCoachAvatar" alt="" class="w-6 h-6 rounded-full shrink-0" />
          <div
            class="rounded-2xl rounded-bl-sm px-3.5 py-2.5 text-[15px] leading-snug flex flex-col gap-2 min-w-0 break-words"
            :class="m.error ? 'bg-red-50 text-red-800' : 'bg-gray-100 text-gray-900'"
          >
            <template v-for="(seg, j) in parse(m)" :key="j">
              <RouterLink
                v-if="seg.kind === 'card'"
                :to="cardLink(seg.card)"
                class="flex items-center gap-3 p-2.5 rounded-xl bg-white border border-gray-200 hover:border-gray-300 hover:shadow-sm transition"
              >
                <img
                  v-if="seg.card.image_url"
                  :src="seg.card.image_url"
                  alt=""
                  class="w-11 h-11 object-cover shrink-0"
                  :class="seg.card.type === 'person' ? 'rounded-full' : 'rounded-md'"
                />
                <span
                  v-else
                  class="w-11 h-11 shrink-0 flex items-center justify-center text-white text-sm font-semibold"
                  :class="seg.card.type === 'person' ? 'rounded-full bg-gray-400' : 'rounded-md'"
                  :style="seg.card.type === 'person' ? '' : 'background-color: #113213'"
                >
                  {{ initials(seg.card.title) }}
                </span>
                <span class="min-w-0 flex-1 flex flex-col">
                  <span class="text-[11px] font-semibold uppercase tracking-wide text-gray-500">{{ cardLabel(seg.card) }}</span>
                  <span class="text-sm font-semibold text-gray-900 truncate">{{ seg.card.title }}</span>
                  <span v-if="seg.card.subtitle" class="text-xs text-gray-500 truncate">{{ seg.card.subtitle }}</span>
                  <span v-if="seg.card.type === 'goal'" class="mt-1 flex items-center gap-2">
                    <span class="flex-1 h-1.5 rounded-full bg-gray-200 overflow-hidden">
                      <span class="block h-full rounded-full" style="background-color: #8cc65d" :style="{ width: `${Math.round((seg.card.progress || 0) * 100)}%` }"></span>
                    </span>
                    <span class="text-[11px] text-gray-500">{{ Math.round((seg.card.progress || 0) * 100) }}%</span>
                  </span>
                </span>
              </RouterLink>
              <p v-else-if="seg.kind === 'line'">
                <template v-for="(part, k) in seg.parts" :key="k">
                  <strong v-if="part.bold">{{ part.text }}</strong>
                  <template v-else>{{ part.text }}</template>
                </template>
              </p>
            </template>
          </div>
        </div>
      </template>

      <!-- Thinking -->
      <div v-if="sending" class="flex items-center gap-2 text-sm text-gray-500">
        <img :src="RepCoachAvatar" alt="" class="w-6 h-6 rounded-full shrink-0" />
        <span class="flex gap-1" aria-hidden="true">
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0ms"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 150ms"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 300ms"></span>
        </span>
        <span>Rep Coach is looking…</span>
      </div>
    </div>

    <!-- Input -->
    <form class="shrink-0 border-t border-gray-200 bg-white px-3 pt-2 pb-3" @submit.prevent="submit">
      <div class="flex items-end gap-2">
        <label for="rep-coach-input" class="sr-only">Message Rep Coach</label>
        <textarea
          id="rep-coach-input"
          ref="inputRef"
          v-model="draft"
          rows="1"
          maxlength="2000"
          placeholder="Ask Rep Coach…"
          class="flex-1 resize-none rounded-2xl border border-gray-300 px-4 py-2.5 text-[15px] bg-gray-50 focus:outline-none focus:ring-1"
          style="--tw-ring-color: #8cc65d; overflow-y: hidden; max-height: 120px"
          @input="grow"
          @keydown.enter.exact.prevent="submit"
        ></textarea>
        <button
          type="submit"
          aria-label="Send"
          class="h-11 w-11 rounded-full flex items-center justify-center text-white shrink-0 transition-colors"
          :class="canSend ? 'hover:opacity-90' : 'bg-gray-300'"
          :style="canSend ? 'background-color: #8cc65d' : ''"
          :disabled="!canSend"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 rotate-90" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
          </svg>
        </button>
      </div>
      <p class="mt-1.5 text-[11px] text-gray-400 text-center">Rep Coach is AI and can make mistakes. It never sends anything for you.</p>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted } from 'vue';
import { useRouter, RouterLink } from 'vue-router';
import RepCoachAvatar from '@/assets/RepCoachAvatar.svg';
import { useRepCoach, type CoachCard, type CoachMessage } from '@/pages/utils/useRepCoach';

defineProps<{ embedded?: boolean }>();

const router = useRouter();
const { messages, sending, send, startOver } = useRepCoach();

const starters = [
  'Find a Purpose near me',
  'Meet people who share my cause',
  'Help my Goal Team make progress',
  'Help me pick my priorities',
];

const draft = ref('');
const listRef = ref<HTMLElement | null>(null);
const inputRef = ref<HTMLTextAreaElement | null>(null);
const canSend = computed(() => draft.value.trim().length > 0 && !sending.value);

type Part = { text: string; bold: boolean };
type Segment = { kind: 'line'; parts: Part[] } | { kind: 'card'; card: CoachCard };

const MARKER = /\[\[\s*(purpose|person|goal)\s*:\s*(\d+)\s*\]\]/gi;

// Split a reply into lines of text (with **bold**) and cards. Card markers on their own
// line become full cards; markers inside a sentence become cards right after that line.
function parse(m: CoachMessage): Segment[] {
  const cards = m.cards || {};
  const out: Segment[] = [];
  for (const raw of m.text.split('\n')) {
    const line = raw.trim();
    if (!line || /^-{3,}$/.test(line)) continue;
    const found: CoachCard[] = [];
    const textOnly = line.replace(MARKER, (_all, kind: string, id: string) => {
      const card = cards[`${kind.toLowerCase()}:${id}`];
      if (card) found.push(card);
      return '';
    }).trim();
    if (textOnly) {
      const parts: Part[] = textOnly.split(/(\*\*[^*]+\*\*)/g).filter(Boolean).map((p) =>
        /^\*\*[^*]+\*\*$/.test(p) ? { text: p.slice(2, -2), bold: true } : { text: p, bold: false });
      out.push({ kind: 'line', parts });
    }
    for (const card of found) out.push({ kind: 'card', card });
  }
  return out;
}

function cardLink(card: CoachCard): string {
  if (card.type === 'purpose') return `/portal/${card.id}`;
  if (card.type === 'person') return `/profile/${card.id}`;
  return `/goal/${card.id}`;
}

function cardLabel(card: CoachCard): string {
  const place = card.city ? ` · ${card.city}` : '';
  if (card.type === 'purpose') return `Purpose${place}`;
  if (card.type === 'person') return `Person${place}`;
  return 'Goal Team';
}

function initials(title: string): string {
  return title.split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0]?.toUpperCase() || '').join('');
}

function grow() {
  const el = inputRef.value;
  if (!el) return;
  el.style.height = 'auto';
  el.style.height = Math.min(el.scrollHeight, 120) + 'px';
}

async function submit() {
  if (!canSend.value) return;
  const text = draft.value;
  draft.value = '';
  await nextTick();
  grow();
  await send(text);
}

function goBack() {
  if (window.history.length > 1) router.back();
  else router.push('/main');
}

function scrollToBottom() {
  nextTick(() => {
    const el = listRef.value;
    if (el) el.scrollTop = el.scrollHeight;
  });
}

watch(() => [messages.value.length, sending.value], scrollToBottom);
onMounted(scrollToBottom);
</script>
