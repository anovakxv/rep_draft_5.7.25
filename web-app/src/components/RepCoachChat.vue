<!--
  RepCoachChat.vue
  Rep Coach conversation: full screen on phones (/coach), embedded in the desktop
  dashboard's center pane. Two saved threads:
    - Profile setup (Rep Onboarding): shown until the member's profile is set up, with a
      progress bar and the Write-section review card
    - Rep Coach: the ongoing assistant (replies as text plus cards)
  Members can delete any message, or all of them. Nothing from a reply is ever inserted as HTML.
-->

<template>
  <div class="flex flex-col h-full min-h-0 bg-white">
    <!-- Header -->
    <header
      class="shrink-0 flex items-center gap-2.5 border-b border-gray-200"
      :class="embedded ? 'h-14 px-4 bg-white' : 'h-14 px-2'"
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
        <p class="text-xs text-gray-500 leading-tight truncate">
          {{ isSetup ? (setupDone ? 'Profile setup · done' : `Profile setup · step ${Math.min(onboarding.state.value.step + 1, 5)} of 5`) : 'Suggests. You decide.' }}
        </p>
      </div>
      <div class="ml-auto flex items-center gap-1">
        <!-- Switch between profile setup and Coach -->
        <button
          v-if="isSetup"
          type="button"
          class="text-sm font-medium px-3 h-9 rounded-lg hover:bg-gray-100"
          style="color: #006600"
          @click="onboarding.setView('coach')"
        >{{ setupDone ? 'Chat with Coach' : 'Skip for now' }}</button>
        <button
          v-else-if="!setupDone"
          type="button"
          class="text-sm font-medium px-3 h-9 rounded-lg hover:bg-gray-100"
          style="color: #006600"
          @click="onboarding.setView('onboarding')"
        >{{ onboarding.status.value === 'not_started' ? 'Set up profile' : 'Finish profile setup' }}</button>

        <!-- More -->
        <div class="relative">
          <button
            type="button"
            class="w-9 h-9 rounded-lg flex items-center justify-center text-gray-500 hover:bg-gray-100 hover:text-gray-800"
            aria-label="More options"
            :aria-expanded="showMenu"
            @click="showMenu = !showMenu"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" /></svg>
          </button>
          <div v-if="showMenu" class="fixed inset-0 z-30" @click="showMenu = false"></div>
          <div v-if="showMenu" role="menu" class="absolute right-0 top-full mt-1 z-40 w-60 bg-white rounded shadow-xl border border-gray-100 py-1">
            <button v-if="isSetup && !setupDone" role="menuitem" class="w-full text-left px-4 py-2.5 text-sm text-gray-800 hover:bg-gray-50" @click="showMenu = false; confirmRestart = true">
              Restart profile setup
            </button>
            <button v-if="setupDone && !isSetup" role="menuitem" class="w-full text-left px-4 py-2.5 text-sm text-gray-800 hover:bg-gray-50" @click="showMenu = false; onboarding.setView('onboarding')">
              View profile setup
            </button>
            <button role="menuitem" class="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50" @click="showMenu = false; openDeleteAll()">
              Delete all chat history
            </button>
          </div>
        </div>
        <!-- Desktop shell puts its pane controls here -->
        <slot name="header-actions" />
      </div>
    </header>

    <!-- Profile setup progress -->
    <div v-if="isSetup" class="shrink-0 border-b border-gray-100 px-4 py-2.5" :class="embedded ? 'lg:px-6' : ''">
      <div class="mx-auto w-full" :class="embedded ? 'max-w-[760px]' : ''">
        <div class="flex gap-1" aria-hidden="true">
          <span
            v-for="(label, i) in STEP_LABELS"
            :key="label"
            class="flex-1 h-1.5 rounded-full"
            :class="i < progressStep ? '' : 'bg-gray-200'"
            :style="i < progressStep ? 'background-color: #8cc65d' : ''"
          ></span>
        </div>
        <p class="mt-1.5 text-[11px] text-gray-500">
          <span v-for="(label, i) in STEP_LABELS" :key="label">
            <span :class="i === currentIndex && !setupDone ? 'font-semibold text-gray-900' : ''">{{ label }}</span><span v-if="i < STEP_LABELS.length - 1" class="text-gray-300"> · </span>
          </span>
        </p>
      </div>
    </div>

    <!-- Messages -->
    <div ref="listRef" class="flex-1 min-h-0 overflow-y-auto" aria-live="polite">
    <div class="w-full mx-auto px-3 lg:px-4 py-4 flex flex-col gap-3" :class="embedded ? 'max-w-[760px] lg:px-6' : ''">
      <!-- Until we know whether profile setup is done, show nothing (avoids flashing the wrong thread) -->
      <div v-if="!ready" class="flex justify-center py-6">
        <span class="animate-spin h-5 w-5 border-2 border-gray-300 border-t-transparent rounded-full"></span>
      </div>

      <template v-else>
      <!-- Coach: load older + welcome + starters -->
      <template v-if="!isSetup">
        <button
          v-if="coach.hasMore.value"
          type="button"
          class="self-center text-xs text-gray-500 hover:text-gray-800 py-1"
          :disabled="coach.loadingHistory.value"
          @click="coach.loadOlder()"
        >{{ coach.loadingHistory.value ? 'Loading…' : 'Load earlier messages' }}</button>
        <div v-if="!coach.hasMore.value" class="flex items-end gap-2 max-w-[85%]">
          <img :src="RepCoachAvatar" alt="" class="w-6 h-6 rounded-full shrink-0" />
          <div class="bg-gray-100 rounded-2xl rounded-bl-sm px-3.5 py-2.5 text-[15px] leading-snug">
            Hi! I'm Rep Coach. Tell me what you want to make progress on, and I'll find Purposes, people and Goal Teams on Rep that can help.
          </div>
        </div>
        <div v-if="!thread.length && !coach.loadingHistory.value" class="flex flex-wrap gap-2 pl-8">
          <button
            v-for="s in starters"
            :key="s"
            type="button"
            class="px-3.5 py-2 min-h-[2.25rem] rounded-full border border-gray-300 text-sm font-medium leading-tight text-gray-800 text-left hover:bg-gray-50 disabled:opacity-50"
            :disabled="isSending"
            @click="coach.send(s)"
          >
            {{ s }}
          </button>
        </div>
      </template>

      <!-- Setup: loading the interview -->
      <div v-else-if="!thread.length" class="flex items-center gap-2 text-sm text-gray-500 py-6 justify-center">
        <span class="animate-spin h-4 w-4 border-2 border-gray-300 border-t-transparent rounded-full"></span>
        Getting your profile setup ready…
      </div>

      <template v-for="(m, i) in thread" :key="m.id ?? m.localId ?? `local-${i}`">
        <!-- Write-section review card -->
        <div v-if="m.kind === 'write_draft'" class="group relative flex items-start gap-2 max-w-full">
          <img :src="RepCoachAvatar" alt="" class="w-6 h-6 rounded-full shrink-0 mt-1" />
          <div class="flex-1 min-w-0">
            <WriteDraftCard
              :message-id="m.id ?? 0"
              :payload="m.payload"
              :save-entries="(entries) => onboarding.saveDraft(m, entries)"
              :show-continue="true"
              @discard="onboarding.discardDraft(m)"
              @continue="onboarding.setView('coach')"
            />
          </div>
        </div>

        <!-- Member -->
        <div v-else-if="m.role === 'user'" class="group self-end flex items-center gap-1.5 max-w-[85%]">
          <MessageDelete v-if="m.id" :confirming="confirmId === m.id" @ask="confirmId = m.id ?? null" @cancel="confirmId = null" @confirm="removeMessage(m)" />
          <div
            class="rounded-2xl rounded-br-sm px-3.5 py-2.5 text-[15px] leading-snug whitespace-pre-wrap break-words bg-black"
            :class="m.pending ? 'opacity-60' : ''"
            style="color: #8cc65d"
          >{{ m.text }}</div>
        </div>

        <!-- Assistant -->
        <div v-else class="group flex items-end gap-2 max-w-[92%] lg:max-w-[85%]">
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
          <MessageDelete v-if="m.id" :confirming="confirmId === m.id" @ask="confirmId = m.id ?? null" @cancel="confirmId = null" @confirm="removeMessage(m)" />
        </div>
      </template>

      <!-- Thinking -->
      <div v-if="isSending" class="flex items-center gap-2 text-sm text-gray-500">
        <img :src="RepCoachAvatar" alt="" class="w-6 h-6 rounded-full shrink-0" />
        <span class="flex gap-1" aria-hidden="true">
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0ms"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 150ms"></span>
          <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 300ms"></span>
        </span>
        <span>{{ isSetup ? 'Rep Coach is thinking…' : 'Rep Coach is looking…' }}</span>
      </div>
      </template>
    </div>
    </div>

    <!-- Input -->
    <form class="shrink-0 border-t border-gray-200 bg-white px-3 pt-2 pb-3" @submit.prevent="submit">
      <div :class="embedded ? 'max-w-[760px] mx-auto lg:px-3' : ''">
      <p v-if="isSetup && setupDone" class="text-sm text-gray-600 text-center py-2">
        Your profile is set up.
        <button type="button" class="font-semibold hover:underline" style="color: #006600" @click="onboarding.setView('coach')">Continue with Rep Coach →</button>
      </p>
      <div v-else class="flex items-end gap-2">
        <label for="rep-coach-input" class="sr-only">{{ isSetup ? 'Answer Rep Coach' : 'Message Rep Coach' }}</label>
        <textarea
          id="rep-coach-input"
          ref="inputRef"
          v-model="draft"
          rows="1"
          maxlength="2000"
          :placeholder="isSetup ? 'Type your answer…' : 'Ask Rep Coach…'"
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
      <p class="mt-1.5 text-[11px] text-gray-400 text-center">Rep Coach is AI and can make mistakes. It never sends anything or changes your profile for you.</p>
      </div>
    </form>

    <!-- Delete all -->
    <Transition name="fade">
      <div v-if="showDeleteAll" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/40" @click="showDeleteAll = false"></div>
        <div class="relative bg-white rounded shadow-2xl w-full max-w-sm p-6" role="dialog" aria-modal="true">
          <h3 class="font-bold text-lg">Delete all chat history?</h3>
          <p class="mt-2 text-sm text-gray-600">This permanently deletes your Rep Coach and profile setup messages. Anything you've saved to your profile stays.</p>
          <label class="mt-4 flex items-start gap-2 text-sm text-gray-800">
            <input v-model="alsoClearMemory" type="checkbox" class="mt-0.5 accent-[#8cc65d]" />
            Also clear what Rep Coach knows about me
          </label>
          <p v-if="actionError" class="mt-3 text-sm text-red-600">{{ actionError }}</p>
          <div class="mt-6 flex justify-end gap-3">
            <button type="button" class="px-4 py-2 rounded border border-gray-300 text-sm" @click="showDeleteAll = false">Cancel</button>
            <button type="button" class="px-4 py-2 rounded bg-red-600 text-white text-sm font-semibold hover:bg-red-700 disabled:opacity-50" :disabled="busy" @click="runDeleteAll">Delete</button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Restart profile setup -->
    <Transition name="fade">
      <div v-if="confirmRestart" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/40" @click="confirmRestart = false"></div>
        <div class="relative bg-white rounded shadow-2xl w-full max-w-sm p-6" role="dialog" aria-modal="true">
          <h3 class="font-bold text-lg">Start profile setup over?</h3>
          <p class="mt-2 text-sm text-gray-600">This deletes the setup conversation and your answers so far. Anything you've saved to your profile stays.</p>
          <p v-if="actionError" class="mt-3 text-sm text-red-600">{{ actionError }}</p>
          <div class="mt-6 flex justify-end gap-3">
            <button type="button" class="px-4 py-2 rounded border border-gray-300 text-sm" @click="confirmRestart = false">Cancel</button>
            <button type="button" class="px-4 py-2 rounded text-white text-sm font-semibold hover:opacity-90 disabled:opacity-50" style="background-color: #8cc65d" :disabled="busy" @click="runRestart">Start over</button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, defineComponent, h } from 'vue';
import { useRouter, RouterLink } from 'vue-router';
import RepCoachAvatar from '@/assets/RepCoachAvatar.svg';
import WriteDraftCard from '@/components/WriteDraftCard.vue';
import { useRepCoach, type CoachCard, type CoachMessage } from '@/pages/utils/useRepCoach';
import { useRepOnboarding, STEP_LABELS } from '@/pages/utils/useRepOnboarding';

defineProps<{ embedded?: boolean }>();

// Hover delete with an inline confirm ("Delete?" ✓ ✕)
const MessageDelete = defineComponent({
  props: { confirming: Boolean },
  emits: ['ask', 'confirm', 'cancel'],
  setup(props, { emit }) {
    return () =>
      props.confirming
        ? h('span', { class: 'flex items-center gap-1 shrink-0 text-xs' }, [
            h('button', { type: 'button', class: 'px-2 py-0.5 rounded bg-red-600 text-white font-semibold', onClick: () => emit('confirm') }, 'Delete'),
            h('button', { type: 'button', class: 'px-1.5 py-0.5 rounded text-gray-500 hover:bg-gray-100', 'aria-label': 'Cancel', onClick: () => emit('cancel') }, '✕'),
          ])
        : h('button', {
            type: 'button',
            class: 'shrink-0 w-7 h-7 rounded-full flex items-center justify-center text-gray-400 hover:text-red-600 hover:bg-red-50 opacity-0 group-hover:opacity-100 focus:opacity-100 transition',
            'aria-label': 'Delete message',
            title: 'Delete message',
            onClick: () => emit('ask'),
          }, [
            h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'h-4 w-4', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '2' }, [
              h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16' }),
            ]),
          ]);
  },
});

const router = useRouter();
const coach = useRepCoach();
const onboarding = useRepOnboarding();

const starters = [
  'Find a Purpose near me',
  'Meet people who share my cause',
  'Help my Goal Team make progress',
  'Help me pick my priorities',
];

const draft = ref('');
const listRef = ref<HTMLElement | null>(null);
const inputRef = ref<HTMLTextAreaElement | null>(null);
const showMenu = ref(false);
const showDeleteAll = ref(false);
const alsoClearMemory = ref(false);
const confirmRestart = ref(false);
const confirmId = ref<number | null>(null);
const busy = ref(false);
const actionError = ref('');
const ready = ref(false);

const isSetup = computed(() => onboarding.view.value === 'onboarding');
const setupDone = computed(() => onboarding.status.value === 'complete');
const thread = computed<CoachMessage[]>(() => (isSetup.value ? onboarding.messages.value : coach.messages.value));
const isSending = computed(() => (isSetup.value ? onboarding.sending.value : coach.sending.value));
const canSend = computed(() => draft.value.trim().length > 0 && !isSending.value);

// Progress bar: steps done (all five once the profile is set up)
const progressStep = computed(() => (setupDone.value ? 5 : Math.min(onboarding.state.value.step, 5)));
const currentIndex = computed(() => Math.min(onboarding.state.value.step, 4));

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
  await (isSetup.value ? onboarding.send(text) : coach.send(text));
}

async function removeMessage(m: CoachMessage) {
  confirmId.value = null;
  try {
    if (isSetup.value) {
      if (m.id) await onboarding.deleteMessage(m.id);
      else onboarding.messages.value = onboarding.messages.value.filter((x) => x !== m);
    } else {
      await coach.deleteMessage(m);
    }
  } catch {
    // Leave it on screen; the member can try again.
  }
}

function openDeleteAll() {
  actionError.value = '';
  alsoClearMemory.value = false;
  showDeleteAll.value = true;
}

async function runDeleteAll() {
  busy.value = true;
  actionError.value = '';
  try {
    await coach.deleteAll(alsoClearMemory.value);
    showDeleteAll.value = false;
    if (isSetup.value && !setupDone.value) await onboarding.load(true);
  } catch {
    actionError.value = "Couldn't delete your history. Try again.";
  } finally {
    busy.value = false;
  }
}

async function runRestart() {
  busy.value = true;
  actionError.value = '';
  try {
    await onboarding.restart();
    confirmRestart.value = false;
  } catch {
    actionError.value = "Couldn't restart profile setup. Try again.";
  } finally {
    busy.value = false;
  }
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

// Profile setup: load the saved interview, and open it with its first question if it's new
async function ensureSetup() {
  await onboarding.load();
  if (isSetup.value && !setupDone.value && !onboarding.messages.value.length) await onboarding.start();
  scrollToBottom();
}

watch(isSetup, (setup) => {
  if (setup) ensureSetup();
  else coach.loadHistory().then(scrollToBottom);
});
watch(() => [thread.value.length, isSending.value], scrollToBottom);

onMounted(async () => {
  await coach.checkStatus();
  ready.value = true;
  if (isSetup.value) await ensureSetup();
  else await coach.loadHistory();
  scrollToBottom();
});
</script>
