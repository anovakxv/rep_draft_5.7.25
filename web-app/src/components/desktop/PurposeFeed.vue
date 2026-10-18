<!--
  PurposeFeed.vue
  The Purpose feed (Me / Network / All) for the desktop Rolodex Shell.
  layout="pane": compact cards in the right-hand context pane (with an expand button).
  layout="wide": Purpose mode — the feed is the center of the dashboard. Each card puts
                 the pitch-deck image beside the Purpose and its Goal Teams' progress,
                 so the Purpose-Value side of the rolodex is the main feature.
  Card images and top Goals load lazily as cards scroll into view.
-->

<template>
  <div class="flex flex-col h-full min-h-0">
    <!-- Header -->
    <div v-if="layout === 'wide'" class="shrink-0 border-b border-gray-100">
      <div class="max-w-[1100px] mx-auto w-full px-6 pt-6 pb-4 flex flex-wrap items-end gap-4">
        <div class="flex-1 min-w-[240px]">
          <h1 class="text-2xl font-bold text-gray-900">Purposes</h1>
          <p class="text-sm text-gray-500 mt-0.5">{{ tagline }}</p>
        </div>
        <div class="flex items-center gap-2">
          <div class="flex p-0.5 rounded-lg bg-gray-100" role="tablist" aria-label="Purposes to show">
            <button
              v-for="(label, i) in tabLabels"
              :key="label"
              type="button"
              role="tab"
              :aria-selected="tab === i"
              class="px-4 h-8 rounded-md text-sm font-medium transition-colors"
              :class="tab === i ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
              @click="selectTab(i)"
            >{{ label }}</button>
          </div>
          <div class="relative">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              v-model="searchText"
              type="search"
              placeholder="Search Purposes"
              aria-label="Search Purposes"
              class="w-52 h-9 pl-8 pr-3 rounded-lg bg-gray-100 text-sm focus:outline-none focus:ring-1 focus:ring-[#8cc65d] focus:bg-white"
            />
          </div>
          <button
            v-if="isAuth"
            type="button"
            class="h-9 px-4 rounded-lg text-sm font-semibold text-white inline-flex items-center gap-1.5 hover:opacity-90"
            style="background-color: #8cc65d"
            @click="router.push('/portal/edit/new')"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" /></svg>
            Add Purpose
          </button>
        </div>
      </div>
    </div>

    <div v-else class="shrink-0 px-4 pt-3 pb-2 space-y-2">
      <div class="flex items-center gap-1.5">
        <div class="flex flex-1 p-0.5 rounded-lg bg-gray-100" role="tablist" aria-label="Purposes to show">
          <button
            v-for="(label, i) in tabLabels"
            :key="label"
            type="button"
            role="tab"
            :aria-selected="tab === i"
            class="flex-1 h-7 rounded-md text-[13px] font-medium transition-colors"
            :class="tab === i ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
            @click="selectTab(i)"
          >{{ label }}</button>
        </div>
        <button
          type="button"
          class="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-gray-100"
          :class="showSearch ? 'bg-gray-100' : ''"
          style="color: #8cc65d"
          aria-label="Search Purposes"
          @click="toggleSearch"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </button>
        <button
          type="button"
          class="w-8 h-8 rounded-lg flex items-center justify-center text-gray-500 hover:bg-gray-100 hover:text-gray-800"
          title="Open Purpose view"
          aria-label="Open Purpose view"
          @click="emit('expand')"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 9V5a1 1 0 011-1h4M20 9V5a1 1 0 00-1-1h-4M4 15v4a1 1 0 001 1h4M20 15v4a1 1 0 01-1 1h-4" />
          </svg>
        </button>
      </div>
      <input
        v-if="showSearch"
        ref="searchRef"
        v-model="searchText"
        type="search"
        placeholder="Search Purposes…"
        class="w-full h-8 px-3 rounded-lg bg-gray-100 text-sm focus:outline-none focus:ring-1 focus:ring-[#8cc65d]"
      />
    </div>

    <!-- Feed -->
    <div ref="listRef" class="flex-1 min-h-0 overflow-y-auto" :class="wide ? 'bg-[#f7f7f7]' : 'px-4 pb-4'">
      <div :class="wide ? 'max-w-[1100px] mx-auto px-6 py-5 space-y-4' : 'space-y-3'">
        <template v-if="loading && !portals.length">
          <div v-for="i in 3" :key="i" class="rounded-xl border border-gray-100 bg-white overflow-hidden animate-pulse" :class="wide ? 'flex' : ''">
            <div class="bg-gray-100" :class="wide ? 'w-[42%] aspect-[16/10]' : 'aspect-[16/9]'"></div>
            <div class="p-4 flex-1 space-y-2">
              <div class="h-4 bg-gray-100 rounded w-2/3"></div>
              <div class="h-3 bg-gray-100 rounded w-full"></div>
              <div class="h-2 bg-gray-100 rounded w-5/6 mt-6"></div>
            </div>
          </div>
        </template>

        <p v-else-if="!filtered.length" class="py-12 text-center text-sm text-gray-400 leading-relaxed">
          <template v-if="searchText.trim()">No Purposes match your search.</template>
          <template v-else-if="tab === 0">No Purposes here for you yet.<br><span class="text-xs">Join a Goal Team on a Purpose, or add your own.</span></template>
          <template v-else-if="tab === 1">No Purposes in your network yet.<br><span class="text-xs">Connect with people to see their Purposes here.</span></template>
          <template v-else>No Purposes found.</template>
        </p>

        <RouterLink
          v-for="portal in filtered"
          :key="portal.id"
          :data-portal-id="portal.id"
          :to="`/portal/${portal.id}`"
          class="group block bg-white overflow-hidden border transition"
          :class="wide
            ? 'flex rounded-2xl border-gray-200 hover:border-gray-300 hover:shadow-lg'
            : 'rounded-xl border-gray-200 hover:border-gray-300 hover:shadow-md'"
        >
          <!-- Pitch-deck image (← → cycles) -->
          <div
            class="relative bg-gray-100 shrink-0"
            :class="wide ? 'w-[42%] max-w-[440px] aspect-[16/10]' : 'aspect-[16/9]'"
          >
            <img v-if="cardImage(portal)" :src="cardImage(portal)" :alt="portal.name" loading="lazy" class="absolute inset-0 w-full h-full object-cover" />
            <template v-if="(images[portal.id]?.length ?? 0) > 1">
              <button
                v-if="(imageIndex[portal.id] ?? 0) > 0"
                type="button"
                aria-label="Previous image"
                class="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition"
                @click.prevent.stop="stepImage(portal.id, -1)"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
              </button>
              <button
                v-if="(imageIndex[portal.id] ?? 0) < images[portal.id].length - 1"
                type="button"
                aria-label="Next image"
                class="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition"
                @click.prevent.stop="stepImage(portal.id, 1)"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" /></svg>
              </button>
              <div class="absolute bottom-2 inset-x-0 flex justify-center gap-1 pointer-events-none">
                <span
                  v-for="(_, i) in images[portal.id]"
                  :key="i"
                  class="w-1.5 h-1.5 rounded-full"
                  :class="i === (imageIndex[portal.id] ?? 0) ? 'bg-white' : 'bg-white/40'"
                ></span>
              </div>
            </template>
          </div>

          <!-- Purpose + Value -->
          <div class="min-w-0 flex flex-col" :class="wide ? 'flex-1 p-5' : 'p-3'">
            <p class="font-bold text-gray-900 leading-snug" :class="wide ? 'text-lg line-clamp-2' : 'text-[15px] line-clamp-1'">{{ portal.name }}</p>
            <p
              v-if="portal.subtitle?.trim()"
              class="text-gray-500 leading-snug mt-0.5"
              :class="wide ? 'text-sm line-clamp-2' : 'text-xs line-clamp-2'"
            >{{ portal.subtitle }}</p>

            <div :class="wide ? 'mt-4 flex-1' : 'mt-2.5'">
              <p v-if="wide && goals[portal.id]?.length" class="text-[11px] font-semibold uppercase tracking-wide text-gray-400 mb-2">Goal Teams</p>
              <div :class="wide ? 'space-y-3' : 'space-y-2'">
                <div v-if="!goals[portal.id]" class="space-y-1.5 animate-pulse">
                  <div class="h-2.5 bg-gray-100 rounded w-3/4"></div>
                  <div class="h-1.5 bg-gray-100 rounded w-full"></div>
                </div>
                <p v-else-if="!goals[portal.id].length" class="text-xs text-gray-400 italic">No active Goal Teams yet</p>
                <template v-else>
                  <div v-for="goal in goals[portal.id].slice(0, wide ? 3 : 2)" :key="goal.id">
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
                        :disabled="creating[goal.id]"
                        :title="goal.chats_id ? 'Message this Goal Team' : 'Start a Goal Team chat'"
                        :aria-label="`Message the ${goal.title} Goal Team`"
                        @click.prevent.stop="openGoalTeamChat(goal, portal.name)"
                      >
                        <svg v-if="creating[goal.id]" class="h-3 w-3 text-white animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
                        <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
                      </button>
                    </div>
                  </div>
                  <p v-if="wide && goals[portal.id].length > 3" class="text-xs text-gray-400">+ {{ goals[portal.id].length - 3 }} more Goal Team{{ goals[portal.id].length - 3 === 1 ? '' : 's' }}</p>
                </template>
              </div>
            </div>

            <p v-if="wide" class="mt-4 text-sm font-semibold group-hover:underline" style="color: #006600">View Purpose →</p>
          </div>
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { useRouter, RouterLink } from 'vue-router';
import api from '@/pages/utils/api';
import { HIDDEN_ALL_TAB_PORTAL_IDS } from '@/constants/hiddenPortals';

interface Portal {
  id: number;
  name: string;
  subtitle?: string;
  mainImageUrl?: string;
}

const props = defineProps<{
  userId: number;
  isAuth: boolean;
  layout: 'pane' | 'wide';
}>();

const emit = defineEmits<{
  (e: 'open-group', chat: { id: number; name: string }): void;
  (e: 'toast', message: string): void;
  (e: 'expand'): void;
}>();

const router = useRouter();

const wide = computed(() => props.layout === 'wide');
const tabLabels = ['Me', 'Network', 'All'];
// 0 = My Purposes (open), 1 = Network (ntwk), 2 = All (all). Logged-out visitors see All.
const tab = ref<0 | 1 | 2>(2);
const portals = ref<Portal[]>([]);
const loading = ref(false);
const showSearch = ref(false);
const searchText = ref('');
const searchRef = ref<HTMLInputElement | null>(null);
const listRef = ref<HTMLElement | null>(null);

const images = ref<Record<number, string[]>>({});
const imageIndex = ref<Record<number, number>>({});
const goals = ref<Record<number, any[]>>({});
const creating = ref<Record<number, boolean>>({});

const tagline = computed(() => {
  if (tab.value === 0) return 'The Purposes you lead or belong to, and how their Goal Teams are doing.';
  if (tab.value === 1) return 'What the people in your network are working toward.';
  return 'Purposes across Rep and the Goal Teams moving them forward.';
});

const filtered = computed(() => {
  let list = portals.value;
  const q = searchText.value.trim().toLowerCase();
  if (q) list = list.filter((p) => p.name.toLowerCase().includes(q) || (p.subtitle || '').toLowerCase().includes(q));
  // Designated portals stay off the public All tab (still reachable by link and on other tabs)
  if (tab.value === 2) list = list.filter((p) => !HIDDEN_ALL_TAB_PORTAL_IDS.includes(p.id));
  return list;
});

function selectTab(i: number) {
  if (i !== 2 && !props.isAuth) {
    router.push({ path: '/register', query: { returnTo: '/main' } });
    return;
  }
  tab.value = i as 0 | 1 | 2;
}

function toggleSearch() {
  showSearch.value = !showSearch.value;
  if (!showSearch.value) searchText.value = '';
  else nextTick(() => searchRef.value?.focus());
}

let fetchSeq = 0;
async function fetchPortals() {
  const seq = ++fetchSeq;
  loading.value = true;
  portals.value = [];
  images.value = {};
  imageIndex.value = {};
  goals.value = {};
  try {
    const tabParam = ({ 0: 'open', 1: 'ntwk', 2: 'all' } as const)[tab.value];
    const res = props.isAuth
      ? await api.get(`/api/portal/filter_network_portals?user_id=${props.userId}&tab=${tabParam}&limit=200`)
      : await api.get('/api/public/portals?safe_only=false&limit=200');
    if (seq !== fetchSeq) return;
    portals.value = res.data.result || [];
  } catch {
    // Silent: the empty state explains there's nothing to show.
  } finally {
    if (seq === fetchSeq) loading.value = false;
    await nextTick();
    observeCards();
  }
}

watch(tab, fetchPortals);
watch(() => props.isAuth, () => {
  if (!props.isAuth) tab.value = 2;
  fetchPortals();
});
watch(filtered, async () => {
  await nextTick();
  observeCards();
});

// --- Lazy card data (images + top goals) ---
let observer: IntersectionObserver | null = null;

function observeCards() {
  observer?.disconnect();
  const root = listRef.value;
  if (!root) return;
  observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        const id = Number((entry.target as HTMLElement).dataset.portalId);
        if (id) loadCardData(id);
        observer?.unobserve(entry.target);
      }
    },
    // Preload about one screen ahead
    { root, rootMargin: `0px 0px ${Math.max(root.clientHeight, 600)}px 0px`, threshold: 0 }
  );
  root.querySelectorAll<HTMLElement>('[data-portal-id]').forEach((el) => observer!.observe(el));
}

async function loadCardData(portalId: number) {
  if (images.value[portalId]) return;
  images.value = { ...images.value, [portalId]: [] }; // mark as loading
  try {
    const res = await api.get(`/api/public/portal/${portalId}`);
    const data = res.data.result;
    const main = (data?.aSections || []).find((s: any) => s.title === 'Main Section');
    const urls = (main?.aFiles || []).map((f: any) => f.url).filter(Boolean);
    images.value = { ...images.value, [portalId]: urls };
    goals.value = { ...goals.value, [portalId]: data?.aGoals || [] };
  } catch {
    goals.value = { ...goals.value, [portalId]: [] };
  }
}

function cardImage(portal: Portal): string {
  return images.value[portal.id]?.[imageIndex.value[portal.id] ?? 0] ?? portal.mainImageUrl ?? '';
}

function stepImage(portalId: number, delta: number) {
  const count = images.value[portalId]?.length ?? 0;
  const next = Math.min(Math.max((imageIndex.value[portalId] ?? 0) + delta, 0), count - 1);
  imageIndex.value = { ...imageIndex.value, [portalId]: next };
}

function pct(goal: any): number {
  return Math.round(Math.min(100, Math.max(0, (goal.progress ?? 0) * 100)));
}

// --- Goal Team chat: members only (mirrors GoalsDetailView) ---
async function openGoalTeamChat(goal: any, portalName: string) {
  if (!props.isAuth) {
    router.push({ path: '/register', query: { returnTo: '/main' } });
    return;
  }
  if (creating.value[goal.id]) return;
  creating.value = { ...creating.value, [goal.id]: true };
  try {
    let memberIds: number[] = [];
    let isOnTeam = false;
    try {
      const teamRes = await api.get(`/api/goals/details?goals_id=${goal.id}`);
      const result = teamRes.data.result;
      const team: any[] = result?.team || [];
      const creatorId = result?.creatorId ?? goal.creatorId;
      isOnTeam = props.userId === creatorId || team.some((m: any) => m.id === props.userId);
      memberIds = team.map((m: any) => m.id).filter((id: any) => id && id !== props.userId);
    } catch {
      // If the check fails, stay conservative and don't open the chat.
    }
    if (!isOnTeam) {
      emit('toast', 'Only Goal Team members can message this team.');
      return;
    }
    if (goal.chats_id) {
      emit('open-group', { id: goal.chats_id, name: goal.title });
      return;
    }
    const title = portalName ? `${portalName}: ${goal.title}` : goal.title;
    const res = await api.post('/api/message/manage_chat', { title, aAddIDs: memberIds });
    const chatsId = res.data.chats_id;
    if (!chatsId) throw new Error('No chats_id returned');
    api.post('/api/goals/link_chat', { goals_id: goal.id, chats_id: chatsId }).catch(() => {});
    goal.chats_id = chatsId;
    emit('open-group', { id: chatsId, name: title });
  } catch (err: any) {
    const status = err?.response?.status;
    emit('toast', status === 401 || status === 403 ? 'Only Goal Team members can message this team.' : 'Couldn’t open the Goal Team chat.');
  } finally {
    creating.value = { ...creating.value, [goal.id]: false };
  }
}

onMounted(fetchPortals);
onUnmounted(() => observer?.disconnect());
</script>
