<!--
  PersonView.vue
  Desktop Person card, shown in the center of the Rolodex Shell (/main?person=:id).
  A compact header card for who they are (the Person), then the mobile profile's
  Purpose · Goals · Write toggle as a full-width, sticky control over rolodex cards:
    Purpose — PurposeCard (16:9 pitch image beside the Purpose and its Goal Teams' progress)
    Goals   — Value cards with mobile's 4-bar chart at full size
    Write   — a reading column of entry cards, with an outline when there are several
  Phones keep ProfileView.vue.
-->

<template>
  <div class="flex flex-col h-full min-h-0 bg-white">
    <!-- Header -->
    <header class="shrink-0 flex items-center gap-2 h-14 px-4 border-b border-gray-200">
      <button
        type="button"
        class="flex items-center gap-1 h-9 pl-1.5 pr-3 rounded-lg text-sm font-medium text-gray-600 hover:bg-gray-100 hover:text-gray-900"
        @click="emit('back')"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" style="color: #8cc65d" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
        Back
      </button>
      <span class="text-gray-300">/</span>
      <span class="text-sm font-semibold text-gray-900 truncate">{{ profile?.full_name || 'Profile' }}</span>
      <RouterLink
        v-if="isMe"
        to="/settings"
        class="ml-auto h-9 px-3 inline-flex items-center gap-1.5 rounded-lg text-sm font-medium text-gray-600 hover:bg-gray-100 hover:text-gray-900"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16" /></svg>
        Settings
      </RouterLink>
    </header>

    <div ref="scrollRef" class="flex-1 min-h-0 overflow-y-auto bg-[#f7f7f7]">
      <div class="max-w-[1100px] mx-auto px-6 pt-6 pb-10">

        <!-- Loading -->
        <div v-if="loading" class="space-y-5 animate-pulse" aria-hidden="true">
          <div class="bg-white border border-gray-200 rounded px-5 py-4 flex gap-5">
            <div class="w-24 h-24 rounded-full bg-gray-100 shrink-0"></div>
            <div class="flex-1 space-y-3 pt-2"><div class="h-6 bg-gray-100 rounded w-1/3"></div><div class="h-4 bg-gray-100 rounded w-1/4"></div><div class="h-4 bg-gray-100 rounded w-1/2"></div></div>
          </div>
          <div class="h-10 bg-white border border-gray-200 rounded-sm"></div>
          <div class="bg-white border border-gray-200 rounded h-64"></div>
        </div>

        <!-- Error -->
        <div v-else-if="loadError" class="bg-white border border-gray-200 rounded p-10 text-center">
          <p class="text-gray-600">{{ loadError }}</p>
          <button type="button" class="mt-3 text-sm font-semibold hover:underline" style="color: #8cc65d" @click="load">Try again</button>
        </div>

        <template v-else-if="profile">
          <!-- ===================== PERSON: rolodex header card ===================== -->
          <section class="bg-white border border-gray-200 rounded">
            <div class="px-5 py-4 flex gap-5">
              <RouterLink :to="`/profile/${userId}/photos`" class="shrink-0 self-start rounded-full hover:opacity-90" :title="`${firstName}'s photos`">
                <img v-if="profile.profile_picture_url && !photoFailed" :src="profile.profile_picture_url" alt="" class="w-24 h-24 rounded-full object-cover" @error="photoFailed = true" />
                <span v-else class="w-24 h-24 rounded-full bg-gray-300 flex items-center justify-center text-white text-2xl font-bold">{{ getInitials(name) }}</span>
              </RouterLink>

              <div class="flex-1 min-w-0">
                <div class="flex flex-wrap items-start gap-x-4 gap-y-2">
                  <div class="flex-1 min-w-[200px]">
                    <h1 class="text-2xl font-bold text-gray-900 leading-tight">{{ name }}</h1>
                    <p v-if="meta" class="text-sm text-gray-500 mt-0.5">{{ meta }}</p>
                  </div>

                  <!-- Actions -->
                  <div class="flex items-center gap-2 shrink-0">
                    <template v-if="isMe">
                      <RouterLink to="/profile/edit" class="h-9 px-4 inline-flex items-center rounded border border-gray-300 text-sm font-semibold text-gray-800 hover:bg-gray-50">Edit profile</RouterLink>
                    </template>
                    <template v-else>
                      <button
                        v-if="coachEnabled"
                        type="button"
                        class="h-9 px-3 inline-flex items-center gap-1.5 rounded text-sm font-semibold hover:bg-[#f3f9ee]"
                        style="color: #006600"
                        :title="`Ask Rep Coach about ${firstName}`"
                        @click="askCoachAboutPerson"
                      >
                        <img :src="RepCoachAvatar" alt="" class="w-5 h-5 rounded-full" />
                        Ask Coach
                      </button>
                      <button
                        type="button"
                        class="h-9 px-4 inline-flex items-center gap-1.5 rounded text-sm font-semibold text-white hover:opacity-90"
                        style="background-color: #8cc65d"
                        @click="emit('message', userId)"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
                        Message
                      </button>
                      <button
                        type="button"
                        class="h-9 px-4 inline-flex items-center gap-1 rounded border text-sm font-semibold hover:bg-[#f3f9ee] disabled:opacity-60"
                        style="border-color: #006600; color: #006600"
                        :disabled="networkBusy"
                        @click="addToNetwork"
                      >+ Network</button>
                      <div class="relative">
                        <button
                          type="button"
                          class="w-9 h-9 rounded flex items-center justify-center text-gray-500 hover:bg-gray-100 hover:text-gray-800"
                          aria-label="More options"
                          :aria-expanded="showMenu"
                          @click="showMenu = !showMenu"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" /></svg>
                        </button>
                        <div v-if="showMenu" class="fixed inset-0 z-30" @click="showMenu = false"></div>
                        <div v-if="showMenu" role="menu" class="absolute right-0 top-full mt-1 z-40 w-52 bg-white rounded shadow-xl border border-gray-100 py-1">
                          <button role="menuitem" class="w-full text-left px-4 py-2.5 text-sm text-gray-800 hover:bg-gray-50" @click="toggleBlock">
                            {{ isBlocked ? 'Unblock' : 'Block' }} {{ firstName }}
                          </button>
                          <button role="menuitem" class="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50" @click="showMenu = false; showFlagConfirm = true">
                            Flag as inappropriate
                          </button>
                        </div>
                      </div>
                    </template>
                  </div>
                </div>

                <!-- Skills -->
                <div v-if="skills.length" class="mt-2 flex flex-wrap gap-1.5">
                  <span v-for="skill in skills" :key="skill" class="px-2 py-0.5 rounded bg-gray-100 text-xs font-medium text-gray-700">{{ skill }}</span>
                </div>

                <!-- Broadcast -->
                <p v-if="profile.broadcast?.trim()" class="mt-2 pl-3 border-l-2 text-sm text-gray-700 leading-relaxed line-clamp-2" style="border-color: #8cc65d" :title="profile.broadcast">
                  {{ profile.broadcast }}
                </p>

                <p v-if="isBlocked" class="mt-2 text-sm text-red-600">You’ve blocked {{ firstName }}.</p>
              </div>
            </div>
          </section>

          <!-- ===================== Main content: Purpose · Goals · Write ===================== -->
          <div ref="contentRef" class="mt-5">
            <!-- The mobile profile's toggle: full width, and it stays put while you scroll -->
            <div class="sticky top-0 z-10 -mx-6 px-6 pt-2 pb-3 bg-[#f7f7f7]">
              <div class="flex bg-white border border-black rounded-sm overflow-hidden" role="tablist" aria-label="Profile content">
                <button
                  v-for="t in tabs"
                  :key="t.id"
                  type="button"
                  role="tab"
                  :aria-selected="tab === t.id"
                  class="flex-1 h-10 text-[15px] font-semibold border-l border-black first:border-l-0 transition-colors"
                  :class="tab === t.id ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
                  @click="selectTab(t.id)"
                >
                  {{ t.label }}
                  <span class="ml-1 text-sm font-normal" :class="tab === t.id ? 'text-white/70' : 'text-gray-400'">{{ t.count }}</span>
                </button>
              </div>
            </div>

            <!-- Panel header: what this tab shows, and the add action on your own profile -->
            <div class="flex items-center justify-between gap-3 mb-3 px-0.5">
              <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-400">{{ panelLabel }}</p>
              <RouterLink
                v-if="isMe && addLink"
                :to="addLink.to"
                class="h-8 px-3 inline-flex items-center rounded text-sm font-semibold text-white hover:opacity-90"
                style="background-color: #8cc65d"
              >{{ addLink.label }}</RouterLink>
            </div>

            <!-- ---------- Purpose ---------- -->
            <div v-if="tab === 'purpose'" class="space-y-4">
              <div v-if="!portals.length" class="bg-white border border-gray-200 rounded p-8 text-center text-sm text-gray-500">
                {{ isMe ? 'You aren’t part of a Purpose yet.' : `${firstName} isn’t part of a Purpose yet.` }}
              </div>
              <PurposeCard
                v-for="p in portals"
                :key="p.id"
                :portal="p"
                layout="wide"
                :images="portalImages[p.id]"
                :goals="portalGoals[p.id]"
                :busy-goal-id="busyGoalId"
                @goal-chat="(goal) => onGoalChat(goal, p.name)"
              />
            </div>

            <!-- ---------- Goals (the Value side) ---------- -->
            <div v-else-if="tab === 'goals'">
              <div v-if="!goals.length" class="bg-white border border-gray-200 rounded p-8 text-center text-sm text-gray-500">
                {{ isMe ? 'You aren’t on a Goal Team yet.' : `${firstName} isn’t on a Goal Team yet.` }}
              </div>
              <div v-else class="grid grid-cols-1 xl:grid-cols-2 gap-4">
                <RouterLink
                  v-for="g in goals"
                  :key="g.id"
                  :to="`/goal/${g.id}`"
                  class="group flex items-center gap-5 bg-white border border-gray-200 rounded p-4 hover:border-gray-300 hover:shadow-sm transition"
                >
                  <!-- Last 4 reporting periods against quota, at mobile's full size -->
                  <span class="flex items-end gap-1.5 shrink-0 h-20 w-[114px] border-b border-gray-200" aria-hidden="true">
                    <span
                      v-for="(bar, i) in chartBars(g)"
                      :key="i"
                      class="w-6 rounded-t-sm"
                      style="background-color: #8cc65d"
                      :style="{ height: `${bar}%`, minHeight: bar > 0 ? '3px' : '0' }"
                    ></span>
                  </span>
                  <span class="flex-1 min-w-0">
                    <span class="block font-semibold text-base text-gray-900 leading-snug line-clamp-2 group-hover:underline">{{ g.title || g.name }}</span>
                    <span v-if="g.subtitle?.trim()" class="block text-sm text-gray-500 leading-snug truncate mt-0.5">{{ g.subtitle }}</span>
                    <span class="mt-2.5 flex items-center gap-2.5">
                      <span class="flex-1 h-2 rounded-full bg-gray-100 overflow-hidden">
                        <span class="block h-full rounded-full" style="background-color: #8cc65d" :style="{ width: `${goalPct(g)}%` }"></span>
                      </span>
                      <span class="text-sm font-semibold text-gray-900 shrink-0">{{ goalPct(g) }}%</span>
                    </span>
                    <span class="mt-2 inline-block px-2 py-0.5 rounded-sm bg-gray-100 text-[11px] font-semibold uppercase tracking-wide text-gray-600">{{ goalTag(g) }}</span>
                  </span>
                </RouterLink>
              </div>
            </div>

            <!-- ---------- Write ---------- -->
            <div v-else>
              <!-- Empty: your own profile → the three pillars, with Coach -->
              <div v-if="!writes.length && isMe" class="bg-white border border-dashed border-gray-300 rounded p-6">
                <p class="font-semibold text-gray-900">Tell people what you’re working toward</p>
                <p class="mt-1 text-sm text-gray-600">Your Write section is how people on Rep understand you. It answers three questions:</p>
                <ol class="mt-3 space-y-1.5 text-sm text-gray-800">
                  <li class="flex gap-2"><span class="font-semibold" style="color: #8cc65d">1</span> What are you trying to accomplish?</li>
                  <li class="flex gap-2"><span class="font-semibold" style="color: #8cc65d">2</span> What are you looking for?</li>
                  <li class="flex gap-2"><span class="font-semibold" style="color: #8cc65d">3</span> What’s holding you back?</li>
                </ol>
                <div class="mt-4 flex flex-wrap gap-2">
                  <button
                    v-if="coachEnabled"
                    type="button"
                    class="h-9 px-4 inline-flex items-center gap-1.5 rounded text-sm font-semibold text-white hover:opacity-90"
                    style="background-color: #8cc65d"
                    @click="emit('ask-coach', writeStarter)"
                  >
                    <img :src="RepCoachAvatar" alt="" class="w-4 h-4 rounded-full bg-white" />
                    Write it with Coach
                  </button>
                  <RouterLink to="/write/new" class="h-9 px-4 inline-flex items-center rounded border border-gray-300 text-sm font-semibold text-gray-800 hover:bg-gray-50">Write it myself</RouterLink>
                </div>
              </div>

              <div v-else-if="!writes.length" class="bg-white border border-gray-200 rounded p-8 text-center text-sm text-gray-500">
                {{ firstName }} hasn’t written their story yet.
              </div>

              <div v-else :class="showOutline ? 'grid grid-cols-[200px_minmax(0,1fr)] gap-6 items-start' : ''">
                <!-- Outline: jump to an entry -->
                <nav v-if="showOutline" class="sticky top-20" aria-label="Write entries">
                  <ol class="space-y-0.5 border-l border-gray-200">
                    <li v-for="(block, i) in writes" :key="block.id">
                      <button
                        type="button"
                        class="w-full text-left pl-3 pr-2 py-1.5 -ml-px border-l-2 border-transparent text-sm text-gray-600 hover:text-gray-900 hover:border-[#8cc65d] line-clamp-2"
                        @click="scrollToWrite(block.id)"
                      >{{ block.title || `Entry ${i + 1}` }}</button>
                    </li>
                  </ol>
                </nav>

                <!-- Entries -->
                <div class="space-y-4 min-w-0">
                  <article
                    v-for="(block, index) in writes"
                    :id="`write-${block.id}`"
                    :key="block.id"
                    class="bg-white border border-gray-200 rounded px-7 py-6 scroll-mt-20"
                  >
                    <div class="flex items-start gap-3">
                      <h3 v-if="block.title" class="flex-1 font-bold text-xl text-gray-900 leading-snug">{{ block.title }}</h3>
                      <span v-if="isMe && block.status === 'draft'" class="shrink-0 px-2 py-0.5 rounded-sm bg-gray-100 text-[11px] font-semibold text-gray-500">Draft</span>
                    </div>
                    <div class="relative max-w-[72ch]" :class="block.title ? 'mt-3' : ''">
                      <div
                        class="prose max-w-none text-[15px] text-gray-800 leading-relaxed break-words"
                        :class="isLong(block) && !expanded[block.id] ? 'max-h-72 overflow-hidden' : ''"
                        :style="block.content_format === 'markdown' ? '' : 'white-space: pre-wrap'"
                        v-html="renderWrite(block)"
                      ></div>
                      <div v-if="isLong(block) && !expanded[block.id]" class="absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-white to-transparent pointer-events-none"></div>
                    </div>
                    <div v-if="isLong(block) || isMe" class="mt-3 flex items-center gap-3">
                      <button
                        v-if="isLong(block)"
                        type="button"
                        class="text-sm font-semibold hover:underline"
                        style="color: #006600"
                        @click="expanded = { ...expanded, [block.id]: !expanded[block.id] }"
                      >{{ expanded[block.id] ? 'Read less' : 'Read more' }}</button>
                      <div v-if="isMe" class="ml-auto flex items-center gap-1 text-sm">
                        <button v-if="index > 0" type="button" class="p-1 rounded text-gray-400 hover:text-gray-700 hover:bg-gray-100" title="Move up" aria-label="Move up" @click="moveWrite(index, -1)">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 15l7-7 7 7" /></svg>
                        </button>
                        <button v-if="index < writes.length - 1" type="button" class="p-1 rounded text-gray-400 hover:text-gray-700 hover:bg-gray-100" title="Move down" aria-label="Move down" @click="moveWrite(index, 1)">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" /></svg>
                        </button>
                        <RouterLink :to="`/write/edit/${block.id}`" class="px-2 py-1 rounded font-medium text-gray-600 hover:bg-gray-100 hover:text-gray-900">Edit</RouterLink>
                        <button type="button" class="px-2 py-1 rounded font-medium text-red-600 hover:bg-red-50" @click="deleteTarget = block">Delete</button>
                      </div>
                    </div>
                  </article>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- Delete Write confirmation -->
    <Transition name="fade">
      <div v-if="deleteTarget" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/40" @click="deleteTarget = null"></div>
        <div class="relative bg-white rounded shadow-2xl w-full max-w-sm p-6" role="dialog" aria-modal="true">
          <h3 class="font-bold text-lg">Delete this entry?</h3>
          <p class="mt-2 text-sm text-gray-600">“{{ deleteTarget.title || 'Untitled' }}” will be removed from your Write section.</p>
          <div class="mt-6 flex justify-end gap-3">
            <button type="button" class="px-4 py-2 rounded border border-gray-300 text-sm" @click="deleteTarget = null">Cancel</button>
            <button type="button" class="px-4 py-2 rounded bg-red-600 text-white text-sm font-semibold hover:bg-red-700" @click="confirmDeleteWrite">Delete</button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Flag confirmation -->
    <Transition name="fade">
      <div v-if="showFlagConfirm" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/40" @click="showFlagConfirm = false"></div>
        <div class="relative bg-white rounded shadow-2xl w-full max-w-sm p-6" role="dialog" aria-modal="true">
          <h3 class="font-bold text-lg">Flag {{ firstName }}?</h3>
          <p class="mt-2 text-sm text-gray-600">This reports the profile to Rep as inappropriate.</p>
          <div class="mt-6 flex justify-end gap-3">
            <button type="button" class="px-4 py-2 rounded border border-gray-300 text-sm" @click="showFlagConfirm = false">Cancel</button>
            <button type="button" class="px-4 py-2 rounded bg-red-600 text-white text-sm font-semibold hover:bg-red-700" @click="confirmFlag">Flag</button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRoute, RouterLink } from 'vue-router';
import { marked } from 'marked';
import DOMPurify from 'dompurify';
import api from '@/pages/utils/api';
import RepCoachAvatar from '@/assets/RepCoachAvatar.svg';
import PurposeCard from './PurposeCard.vue';
import { getInitials } from '@/pages/utils/desktopShell';
import { openGoalTeamChat } from '@/pages/utils/goalTeamChat';

interface Profile {
  id: number;
  full_name?: string;
  profile_picture_url?: string;
  city?: string;
  user_type?: string;
  broadcast?: string;
  skills?: Array<{ id: number; title: string }>;
  other_skill?: string;
}
interface Portal { id: number; name: string; subtitle?: string; mainImageUrl?: string }
interface WriteBlock { id: number; title?: string; content: string; content_format?: string; status?: string }

const props = defineProps<{
  userId: number;
  currentUserId: number;
  coachEnabled: boolean;
}>();

const emit = defineEmits<{
  (e: 'back'): void;
  (e: 'message', userId: number): void;
  (e: 'open-group', chat: { id: number; name: string }): void;
  (e: 'ask-coach', text: string): void;
  (e: 'toast', message: string): void;
}>();

const route = useRoute();

const writeStarter =
  'Help me write my Rep profile. Ask me, one question at a time, what I’m trying to accomplish, what I’m looking for, and what’s holding me back, then draft my Write section for me to review.';

// --- State ---
const loading = ref(true);
const loadError = ref('');
const profile = ref<Profile | null>(null);
const portals = ref<Portal[]>([]);
const goals = ref<any[]>([]);
const writes = ref<WriteBlock[]>([]);
const isBlocked = ref(false);
const photoFailed = ref(false);
const expanded = ref<Record<number, boolean>>({});
const showMenu = ref(false);
const showFlagConfirm = ref(false);
const deleteTarget = ref<WriteBlock | null>(null);
const networkBusy = ref(false);
const scrollRef = ref<HTMLElement | null>(null);
const contentRef = ref<HTMLElement | null>(null);

// Purpose cards' images and Goal Teams (a missing goals entry means "still loading")
const portalImages = ref<Record<number, string[]>>({});
const portalGoals = ref<Record<number, any[]>>({});
const busyGoalId = ref<number | null>(null);

const isMe = computed(() => props.userId === props.currentUserId);
const name = computed(() => profile.value?.full_name || 'Member');
const firstName = computed(() => name.value.trim().split(/\s+/)[0] || name.value);
const meta = computed(() => [profile.value?.user_type, profile.value?.city].filter(Boolean).join(' · '));
const skills = computed(() => {
  const list = (profile.value?.skills || []).map((s) => s.title).filter(Boolean);
  if (profile.value?.other_skill?.trim()) list.push(profile.value.other_skill.trim());
  return list;
});

// --- Main content toggle, in the mobile profile's order (Rep / Goals / Write) ---
type Tab = 'purpose' | 'goals' | 'write';
const tab = ref<Tab>('purpose');
const tabs = computed<Array<{ id: Tab; label: string; count: number }>>(() => [
  { id: 'purpose', label: 'Purpose', count: portals.value.length },
  { id: 'goals', label: 'Goals', count: goals.value.length },
  { id: 'write', label: 'Write', count: writes.value.length },
]);

const panelLabel = computed(() => {
  const who = isMe.value ? 'Your' : `${firstName.value}’s`;
  if (tab.value === 'purpose') return `${who} Purposes and their Goal Teams`;
  if (tab.value === 'goals') return `${who} Goal Teams · Value`;
  return `${who} Write`;
});

// Your own profile: the add action for whichever tab is showing (an empty Write has its own prompt)
const addLink = computed(() => {
  if (tab.value === 'purpose') return { to: '/portal/edit/new', label: '+ Add Purpose' };
  if (tab.value === 'goals') return { to: '/goal/edit/new', label: '+ Add Goal' };
  return writes.value.length ? { to: '/write/new', label: '+ Add to Write' } : null;
});

// Long Write sections get an outline to jump between entries
const showOutline = computed(() => writes.value.length >= 3);

function selectTab(next: Tab) {
  tab.value = next;
  // If the toggle is stuck to the top, start the new tab from its first card
  const el = scrollRef.value;
  const content = contentRef.value;
  if (!el || !content) return;
  const contentTop = content.getBoundingClientRect().top - el.getBoundingClientRect().top + el.scrollTop;
  if (el.scrollTop > contentTop) el.scrollTo({ top: contentTop });
}

function scrollToWrite(id: number) {
  document.getElementById(`write-${id}`)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// --- Loading ---
let seq = 0;
async function load() {
  const mySeq = ++seq;
  loading.value = !profile.value; // background refreshes keep the page in place
  loadError.value = '';
  try {
    const [profileRes, portalsRes, goalsRes, writesRes, blockRes] = await Promise.all([
      api.get(`/api/user/profile?users_id=${props.userId}`),
      api.get(`/api/portal/filter_network_portals?user_id=${props.userId}&tab=open`).catch(() => null),
      api.get(`/api/goals/list?users_id=${props.userId}`).catch(() => null),
      api.get(`/api/user/writes?users_id=${props.userId}`).catch(() => null),
      isMe.value ? Promise.resolve(null) : api.get(`/api/user/is_blocked?users_id=${props.userId}`).catch(() => null),
    ]);
    if (mySeq !== seq) return;
    const p = profileRes.data?.result;
    if (!p?.id) {
      loadError.value = 'This profile could not be found.';
      return;
    }
    profile.value = p;
    photoFailed.value = false;
    portals.value = portalsRes?.data?.result || [];
    goals.value = goalsRes?.data?.aGoals || [];
    writes.value = writesRes?.data?.result || [];
    isBlocked.value = !!blockRes?.data?.is_blocked;
    loadPortalDetails(mySeq);
  } catch (e: any) {
    if (mySeq !== seq) return;
    loadError.value = e?.response?.data?.error || 'Couldn’t load this profile.';
  } finally {
    if (mySeq === seq) loading.value = false;
  }
}

// Each Purpose card shows its pitch-deck images and Goal Teams (the Purpose → Value link)
function loadPortalDetails(mySeq: number) {
  portals.value.slice(0, 30).forEach(async (p) => {
    try {
      const res = await api.get(`/api/public/portal/${p.id}`);
      if (mySeq !== seq) return;
      const data = res.data.result;
      const main = (data?.aSections || []).find((s: any) => s.title === 'Main Section');
      portalImages.value = { ...portalImages.value, [p.id]: (main?.aFiles || []).map((f: any) => f.url).filter(Boolean) };
      portalGoals.value = { ...portalGoals.value, [p.id]: data?.aGoals || [] };
    } catch {
      if (mySeq === seq) portalGoals.value = { ...portalGoals.value, [p.id]: [] };
    }
  });
}

// Coming back from editing your profile or a Write entry: refresh in place
let away = false;
watch(
  () => route.path,
  (path) => {
    if (path !== '/main') away = true;
    else if (away) {
      away = false;
      load();
    }
  }
);

// --- Purpose cards: message a Goal Team (members only) ---
async function onGoalChat(goal: any, portalName: string) {
  if (busyGoalId.value) return;
  busyGoalId.value = goal.id;
  try {
    emit('open-group', await openGoalTeamChat(goal, portalName, props.currentUserId));
  } catch (e: any) {
    emit('toast', e?.message || 'Couldn’t open the Goal Team chat.');
  } finally {
    busyGoalId.value = null;
  }
}

// --- Write ---
function renderWrite(block: WriteBlock): string {
  const raw = block.content || '';
  const html = block.content_format === 'markdown' ? (marked.parse(raw) as string) : raw;
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['p', 'strong', 'em', 'b', 'i', 'u', 'a', 'br', 'h1', 'h2', 'h3', 'h4', 'ul', 'ol', 'li', 'blockquote', 'code', 'pre', 'img', 'hr'],
    ALLOWED_ATTR: ['href', 'target', 'rel', 'src', 'alt'],
  });
}

const isLong = (block: WriteBlock) => (block.content || '').length > 900;

async function moveWrite(index: number, delta: -1 | 1) {
  const to = index + delta;
  if (to < 0 || to >= writes.value.length) return;
  const list = [...writes.value];
  [list[index], list[to]] = [list[to], list[index]];
  writes.value = list;
  try {
    await Promise.all(list.map((w, i) => api.put(`/api/user/write/${w.id}`, { order: i })));
  } catch {
    emit('toast', 'Couldn’t save the new order.');
    load();
  }
}

async function confirmDeleteWrite() {
  const block = deleteTarget.value;
  if (!block) return;
  deleteTarget.value = null;
  try {
    await api.delete(`/api/user/write/${block.id}`);
    writes.value = writes.value.filter((w) => w.id !== block.id);
  } catch {
    emit('toast', 'Couldn’t delete that entry.');
  }
}

// --- Visitor actions ---
async function addToNetwork() {
  networkBusy.value = true;
  try {
    await api.post('/api/user/network_action', {
      action: 'add',
      user_id: props.currentUserId,
      target_user_id: props.userId,
    });
    emit('toast', `${firstName.value} is in your network.`);
    document.dispatchEvent(new Event('refreshNetworkList'));
  } catch (error: any) {
    emit('toast', error?.response?.data?.error || 'Couldn’t add to your network.');
  } finally {
    networkBusy.value = false;
  }
}

async function toggleBlock() {
  showMenu.value = false;
  const action = isBlocked.value ? 'unblock' : 'block';
  try {
    await api.post(`/api/user/${action}`, { users_id: props.userId });
    isBlocked.value = !isBlocked.value;
    emit('toast', isBlocked.value ? `${firstName.value} is blocked.` : `${firstName.value} is unblocked.`);
  } catch {
    emit('toast', `Couldn’t ${action} ${firstName.value}.`);
  }
}

async function confirmFlag() {
  showFlagConfirm.value = false;
  try {
    await api.post('/api/user/flag_user', { users_id: props.userId, reason: 'Inappropriate content' });
    emit('toast', 'Thanks. The profile has been flagged for review.');
  } catch {
    emit('toast', 'Couldn’t flag this profile.');
  }
}

function askCoachAboutPerson() {
  emit(
    'ask-coach',
    `I'm looking at ${name.value}'s profile on Rep. What are they working on, and how could we help each other? Suggest a good way to start the conversation.`
  );
}

// --- Goals ---
function goalPct(g: any): number {
  const raw = g.progressPercent ?? (g.progress ?? 0) * 100;
  return Math.round(Math.min(100, Math.max(0, Number(raw) || 0)));
}

// Matches the mobile tag: the goal type, or for "Other" the metric name (9 chars)
function goalTag(g: any): string {
  if (g.typeName?.toLowerCase() === 'other') return (g.metricName?.trim() || g.typeName || 'Goal').substring(0, 9);
  return g.typeName || 'Goal';
}

// Last 4 reporting periods as % of quota
function chartBars(g: any): number[] {
  const quota = g.quota > 0 ? g.quota : 1;
  return (g.chartData || []).slice(-4).map((bar: any) => Math.min(100, Math.max(0, ((bar.value || 0) / quota) * 100)));
}

onMounted(load);
</script>
