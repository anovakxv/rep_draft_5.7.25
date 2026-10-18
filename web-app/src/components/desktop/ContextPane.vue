<!--
  ContextPane.vue
  Right-hand pane of the desktop Rolodex Shell: People · Conversation · Purpose-Value.
  "About" shows who or what the open conversation is with (a person's Write section,
  Purposes and Goal Teams; a group's members; what Rep Coach can help with).
  "Purposes" is the network Purpose feed, always one click away.
-->

<template>
  <div class="flex flex-col h-full min-h-0 bg-white">
    <!-- Tabs -->
    <div class="shrink-0 flex items-center gap-1 h-14 px-3 border-b border-gray-200">
      <div class="flex flex-1 p-0.5 rounded-lg bg-gray-100" role="tablist" aria-label="Context">
        <button
          v-if="conversation"
          type="button"
          role="tab"
          :aria-selected="activeTab === 'about'"
          class="flex-1 h-8 rounded-md text-sm font-medium transition-colors"
          :class="activeTab === 'about' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
          @click="setTab('about')"
        >About</button>
        <button
          type="button"
          role="tab"
          :aria-selected="activeTab === 'purposes'"
          class="flex-1 h-8 rounded-md text-sm font-medium transition-colors"
          :class="activeTab === 'purposes' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
          @click="setTab('purposes')"
        >Purposes</button>
      </div>
      <button
        v-if="closable"
        type="button"
        class="w-9 h-9 rounded-lg flex items-center justify-center text-gray-500 hover:bg-gray-100"
        aria-label="Close panel"
        @click="emit('close')"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <!-- About -->
    <div v-if="activeTab === 'about' && conversation" class="flex-1 min-h-0 overflow-y-auto">
      <!-- Person -->
      <template v-if="conversation.kind === 'direct'">
        <div v-if="person.loading" class="p-5 space-y-4 animate-pulse" aria-hidden="true">
          <div class="flex items-center gap-3">
            <div class="w-16 h-16 rounded-full bg-gray-100"></div>
            <div class="flex-1 space-y-2"><div class="h-3.5 bg-gray-100 rounded w-2/3"></div><div class="h-3 bg-gray-100 rounded w-1/2"></div></div>
          </div>
          <div class="h-24 bg-gray-50 rounded-xl"></div>
          <div class="h-16 bg-gray-50 rounded-xl"></div>
        </div>

        <div v-else class="p-5 space-y-6">
          <!-- Rolodex card -->
          <section class="flex items-start gap-3">
            <img v-if="person.profile?.profile_picture_url" :src="person.profile.profile_picture_url" alt="" class="w-16 h-16 rounded-full object-cover shrink-0" />
            <span v-else class="w-16 h-16 rounded-full bg-gray-300 flex items-center justify-center text-white text-lg font-semibold shrink-0">{{ getInitials(personName) }}</span>
            <div class="min-w-0 flex-1 pt-1">
              <p class="font-bold text-[17px] text-gray-900 leading-tight">{{ personName }}</p>
              <p v-if="personMeta" class="text-sm text-gray-500 mt-0.5">{{ personMeta }}</p>
              <div class="mt-3 flex flex-wrap gap-2">
                <RouterLink
                  :to="`/profile/${conversation.id}`"
                  class="px-3 h-8 inline-flex items-center rounded-full border border-gray-300 text-sm font-medium text-gray-800 hover:bg-gray-50"
                >View profile</RouterLink>
                <button
                  v-if="coachEnabled"
                  type="button"
                  class="px-3 h-8 inline-flex items-center gap-1.5 rounded-full text-sm font-medium text-white hover:opacity-90"
                  style="background-color: #8cc65d"
                  @click="askCoachAboutPerson"
                >
                  <img :src="RepCoachAvatar" alt="" class="w-4 h-4 rounded-full bg-white" />
                  Ask Coach
                </button>
              </div>
            </div>
          </section>

          <!-- Shared Purposes -->
          <section v-if="sharedPortals.length" class="rounded-xl px-3.5 py-3" style="background-color: #f3f9ee">
            <p class="text-xs font-semibold uppercase tracking-wide" style="color: #006600">You both work on</p>
            <div class="mt-2 flex flex-wrap gap-1.5">
              <RouterLink
                v-for="p in sharedPortals"
                :key="p.id"
                :to="`/portal/${p.id}`"
                class="px-2.5 py-1 rounded-full bg-white border border-[#cfe6bb] text-xs font-medium text-gray-800 hover:border-[#8cc65d]"
              >{{ p.name }}</RouterLink>
            </div>
          </section>

          <!-- Write section -->
          <section>
            <h3 class="text-xs font-semibold uppercase tracking-wide text-gray-400">Write</h3>
            <p v-if="!person.writes.length" class="mt-2 text-sm text-gray-500">
              {{ firstName(personName) }} hasn't written their story yet.
            </p>
            <div v-for="block in person.writes" :key="block.id" class="mt-3">
              <p v-if="block.title" class="font-semibold text-sm text-gray-900">{{ block.title }}</p>
              <p
                class="text-sm text-gray-700 leading-relaxed whitespace-pre-line break-words mt-0.5"
                :class="expanded[block.id] ? '' : 'line-clamp-6'"
              >{{ block.content }}</p>
              <button
                v-if="(block.content || '').length > 320"
                type="button"
                class="mt-1 text-xs font-semibold hover:underline"
                style="color: #8cc65d"
                @click="expanded = { ...expanded, [block.id]: !expanded[block.id] }"
              >{{ expanded[block.id] ? 'Show less' : 'Read more' }}</button>
            </div>
          </section>

          <!-- Purposes -->
          <section v-if="person.portals.length">
            <h3 class="text-xs font-semibold uppercase tracking-wide text-gray-400">Purposes</h3>
            <div class="mt-2 space-y-1">
              <RouterLink
                v-for="p in person.portals.slice(0, 6)"
                :key="p.id"
                :to="`/portal/${p.id}`"
                class="flex items-center gap-3 -mx-2 px-2 py-2 rounded-lg hover:bg-gray-50"
              >
                <img v-if="p.mainImageUrl" :src="p.mainImageUrl" alt="" class="w-10 h-10 rounded-md object-cover shrink-0" />
                <span v-else class="w-10 h-10 rounded-md flex items-center justify-center text-white text-xs font-semibold shrink-0" style="background-color: #113213">{{ getInitials(p.name) }}</span>
                <span class="min-w-0">
                  <span class="block text-sm font-semibold text-gray-900 truncate">{{ p.name }}</span>
                  <span v-if="p.subtitle" class="block text-xs text-gray-500 truncate">{{ p.subtitle }}</span>
                </span>
              </RouterLink>
            </div>
          </section>

          <!-- Goal Teams -->
          <section v-if="person.goals.length">
            <h3 class="text-xs font-semibold uppercase tracking-wide text-gray-400">Goal Teams</h3>
            <div class="mt-2 space-y-3">
              <RouterLink v-for="g in person.goals.slice(0, 5)" :key="g.id" :to="`/goal/${g.id}`" class="block group">
                <div class="flex items-center justify-between gap-2">
                  <span class="text-sm font-medium text-gray-900 truncate group-hover:underline">{{ g.title || g.name }}</span>
                  <span class="text-xs text-gray-500 shrink-0">{{ goalPct(g) }}%</span>
                </div>
                <div class="mt-1 h-1.5 rounded-full bg-gray-100 overflow-hidden">
                  <div class="h-full rounded-full" style="background: #8cc65d" :style="{ width: `${goalPct(g)}%` }"></div>
                </div>
              </RouterLink>
            </div>
          </section>
        </div>
      </template>

      <!-- Group -->
      <div v-else-if="conversation.kind === 'group'" class="p-5 space-y-6">
        <section>
          <p class="font-bold text-[17px] text-gray-900 leading-tight">{{ group?.name || 'Group chat' }}</p>
          <p class="text-sm text-gray-500 mt-0.5">{{ group?.members.length ?? 0 }} member{{ (group?.members.length ?? 0) === 1 ? '' : 's' }}</p>
          <button
            v-if="coachEnabled"
            type="button"
            class="mt-3 px-3 h-8 inline-flex items-center gap-1.5 rounded-full text-sm font-medium text-white hover:opacity-90"
            style="background-color: #8cc65d"
            @click="emit('ask-coach', `How can our Goal Team “${group?.name || 'our team'}” make faster progress? Suggest concrete next steps.`)"
          >
            <img :src="RepCoachAvatar" alt="" class="w-4 h-4 rounded-full bg-white" />
            Ask Coach about this team
          </button>
        </section>

        <section>
          <h3 class="text-xs font-semibold uppercase tracking-wide text-gray-400">Members</h3>
          <div v-if="!group" class="mt-3 space-y-3 animate-pulse">
            <div v-for="i in 4" :key="i" class="flex items-center gap-3"><div class="w-9 h-9 rounded-full bg-gray-100"></div><div class="h-3 bg-gray-100 rounded w-1/2"></div></div>
          </div>
          <div v-else class="mt-2 space-y-0.5">
            <div v-for="m in group.members" :key="m.id" class="flex items-center gap-3 -mx-2 px-2 py-1.5 rounded-lg hover:bg-gray-50">
              <RouterLink :to="`/profile/${m.id}`" class="shrink-0">
                <img v-if="photoUrl(m.profile_picture_url)" :src="photoUrl(m.profile_picture_url)" alt="" class="w-9 h-9 rounded-full object-cover" />
                <span v-else class="w-9 h-9 rounded-full bg-gray-300 flex items-center justify-center text-white text-xs font-semibold">{{ getInitials(memberName(m)) }}</span>
              </RouterLink>
              <RouterLink :to="`/profile/${m.id}`" class="min-w-0 flex-1">
                <span class="block text-sm font-medium text-gray-900 truncate">{{ memberName(m) }}<span v-if="m.id === currentUserId" class="text-gray-400 font-normal"> (you)</span></span>
                <span v-if="m.id === group.creatorId" class="block text-xs text-gray-500">Creator</span>
              </RouterLink>
              <button
                v-if="m.id !== currentUserId"
                type="button"
                class="shrink-0 px-2.5 h-7 rounded-full border border-gray-300 text-xs font-medium text-gray-700 hover:bg-white hover:border-[#8cc65d]"
                @click="emit('open-conversation', { kind: 'direct', id: m.id })"
              >Message</button>
            </div>
          </div>
        </section>
      </div>

      <!-- Rep Coach -->
      <div v-else class="p-5 space-y-5">
        <section class="flex items-start gap-3">
          <img :src="RepCoachAvatar" alt="" class="w-12 h-12 rounded-full shrink-0" />
          <div>
            <p class="font-bold text-[17px] text-gray-900 leading-tight">Rep Coach</p>
            <p class="text-sm text-gray-500 mt-0.5">Your AI guide on Rep. It suggests; you decide.</p>
          </div>
        </section>

        <!-- Write section status: the first thing Coach helps with -->
        <section class="rounded-xl border border-gray-200 p-4">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-400">Your Write section</p>
          <template v-if="myWriteCount === null">
            <div class="mt-2 h-3 bg-gray-100 rounded w-2/3 animate-pulse"></div>
          </template>
          <template v-else-if="myWriteCount === 0">
            <p class="mt-2 text-sm text-gray-800 leading-relaxed">
              Your Write section is how people on Rep understand what you’re working toward. It answers three questions:
            </p>
            <ul class="mt-2 space-y-1 text-sm text-gray-700">
              <li class="flex gap-2"><span style="color: #8cc65d">●</span> What you’re trying to accomplish</li>
              <li class="flex gap-2"><span style="color: #8cc65d">●</span> What you’re looking for</li>
              <li class="flex gap-2"><span style="color: #8cc65d">●</span> What’s holding you back</li>
            </ul>
            <div class="mt-3 flex flex-wrap gap-2">
              <button
                type="button"
                class="px-3 h-8 rounded-full text-sm font-semibold text-white hover:opacity-90"
                style="background-color: #8cc65d"
                @click="emit('ask-coach', writeStarter)"
              >Write it with Coach</button>
              <RouterLink to="/write/new" class="px-3 h-8 inline-flex items-center rounded-full border border-gray-300 text-sm font-medium text-gray-800 hover:bg-gray-50">Write it myself</RouterLink>
            </div>
          </template>
          <template v-else>
            <p class="mt-2 text-sm text-gray-800">
              You have {{ myWriteCount }} {{ myWriteCount === 1 ? 'entry' : 'entries' }} in your Write section.
            </p>
            <div class="mt-3 flex flex-wrap gap-2">
              <RouterLink :to="`/profile/${currentUserId}`" class="px-3 h-8 inline-flex items-center rounded-full border border-gray-300 text-sm font-medium text-gray-800 hover:bg-gray-50">View my profile</RouterLink>
              <button type="button" class="px-3 h-8 rounded-full text-sm font-medium hover:underline" style="color: #8cc65d" @click="emit('ask-coach', refineStarter)">Refine it with Coach</button>
            </div>
          </template>
        </section>

        <section class="rounded-xl bg-gray-50 p-4">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-400">What Coach knows about you</p>
          <p class="mt-2 text-sm text-gray-600 leading-relaxed">
            Coming soon: Rep Coach will remember your goals between conversations, and you’ll be able to see and edit what it knows right here.
          </p>
        </section>

        <p class="text-xs text-gray-400 leading-relaxed">Rep Coach is AI and can make mistakes. It never sends messages or changes your profile for you.</p>
      </div>
    </div>

    <!-- Purposes (kept mounted so switching tabs keeps your place) -->
    <div v-show="activeTab === 'purposes'" class="flex-1 min-h-0">
      <PurposeFeed
        :user-id="currentUserId"
        :is-auth="isAuth"
        layout="pane"
        @open-group="(chat) => emit('open-group', chat)"
        @toast="(msg) => emit('toast', msg)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { RouterLink } from 'vue-router';
import api from '@/pages/utils/api';
import RepCoachAvatar from '@/assets/RepCoachAvatar.svg';
import PurposeFeed from './PurposeFeed.vue';
import {
  getInitials,
  photoUrl,
  readPref,
  savePref,
  type ConversationKey,
  type GroupLoaded,
  type GroupMember,
} from '@/pages/utils/desktopShell';

interface Portal { id: number; name: string; subtitle?: string; mainImageUrl?: string }
interface WriteBlock { id: number; title?: string; content: string }

const props = defineProps<{
  conversation: ConversationKey | null;
  currentUserId: number;
  isAuth: boolean;
  group: GroupLoaded | null;
  coachEnabled: boolean;
  myWriteCount: number | null;
  closable?: boolean;
}>();

const emit = defineEmits<{
  (e: 'open-conversation', key: ConversationKey): void;
  (e: 'open-group', chat: { id: number; name: string }): void;
  (e: 'ask-coach', text: string): void;
  (e: 'toast', message: string): void;
  (e: 'close'): void;
}>();

const writeStarter =
  'Help me write my Rep profile. Ask me, one question at a time, what I’m trying to accomplish, what I’m looking for, and what’s holding me back, then draft my Write section for me to review.';
const refineStarter =
  'Help me sharpen my Rep Write section so it clearly says what I’m trying to accomplish, what I’m looking for, and what’s holding me back.';

// --- Tabs: About by default; choosing Purposes is remembered ---
const tabPref = ref<'about' | 'purposes'>(readPref('contextTab', 'about') === 'purposes' ? 'purposes' : 'about');
const activeTab = computed(() => (props.conversation ? tabPref.value : 'purposes'));

function setTab(tab: 'about' | 'purposes') {
  tabPref.value = tab;
  savePref('contextTab', tab);
}

// --- Person About ---
interface PersonState {
  loading: boolean;
  profile: { full_name?: string; profile_picture_url?: string; city?: string; user_type?: string } | null;
  writes: WriteBlock[];
  portals: Portal[];
  goals: any[];
}

const emptyPerson = (): PersonState => ({ loading: false, profile: null, writes: [], portals: [], goals: [] });
const person = ref<PersonState>(emptyPerson());
const personCache = new Map<number, PersonState>();
const expanded = ref<Record<number, boolean>>({});
const myPortals = ref<Portal[]>([]);
let personSeq = 0;

const personName = computed(() => person.value.profile?.full_name || 'Member');
const personMeta = computed(() => [person.value.profile?.user_type, person.value.profile?.city].filter(Boolean).join(' · '));
const sharedPortals = computed(() => {
  const mine = new Set(myPortals.value.map((p) => p.id));
  return person.value.portals.filter((p) => mine.has(p.id));
});

async function loadPerson(userId: number) {
  expanded.value = {};
  const cached = personCache.get(userId);
  if (cached) {
    person.value = cached;
    return;
  }
  const seq = ++personSeq;
  person.value = { ...emptyPerson(), loading: true };
  const [profileRes, writesRes, portalsRes, goalsRes] = await Promise.allSettled([
    api.get(`/api/user/profile?users_id=${userId}`),
    api.get(`/api/user/writes?users_id=${userId}`),
    api.get(`/api/portal/filter_network_portals?user_id=${userId}&tab=open&limit=50`),
    api.get(`/api/goals/list?users_id=${userId}`),
  ]);
  if (seq !== personSeq) return;
  // Each section shows what it could load; one failed request doesn't blank the pane.
  const data = (r: PromiseSettledResult<any>) => (r.status === 'fulfilled' ? r.value.data || {} : {});
  const state: PersonState = {
    loading: false,
    profile: data(profileRes).result || null,
    writes: data(writesRes).result || [],
    portals: data(portalsRes).result || [],
    goals: data(goalsRes).aGoals || [],
  };
  personCache.set(userId, state);
  person.value = state;
}

async function loadMyPortals() {
  if (!props.isAuth || !props.currentUserId) return;
  try {
    const res = await api.get(`/api/portal/filter_network_portals?user_id=${props.currentUserId}&tab=open&limit=200`);
    myPortals.value = res.data.result || [];
  } catch {
    myPortals.value = [];
  }
}

function askCoachAboutPerson() {
  const name = personName.value;
  emit(
    'ask-coach',
    `I'm talking with ${name} on Rep. What are they working on, and how could we help each other? Suggest a good way to start the conversation.`
  );
}

function firstName(name: string): string {
  return (name || '').trim().split(/\s+/)[0] || name;
}

function memberName(m: GroupMember): string {
  return m.full_name || m.name || 'Member';
}

function goalPct(g: any): number {
  const raw = g.progressPercent ?? (g.progress ?? 0) * 100;
  return Math.round(Math.min(100, Math.max(0, Number(raw) || 0)));
}

watch(
  () => (props.conversation?.kind === 'direct' ? props.conversation.id : null),
  (id) => {
    if (id) loadPerson(id);
  },
  { immediate: true }
);

onMounted(loadMyPortals);
</script>
