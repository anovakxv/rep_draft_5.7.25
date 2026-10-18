<!--
  PurposeFeed.vue
  The Purpose feed (Me / Network / All) for the desktop Rolodex Shell.
  layout="pane": compact cards in the right-hand context pane (with an expand button).
  layout="wide": Purpose mode — the feed is the center of the dashboard, so the
                 Purpose-Value side of the rolodex is the main feature.
  Cards are PurposeCard; their images and top Goals load lazily as they scroll into view.
-->

<template>
  <div class="flex flex-col h-full min-h-0">
    <!-- Header -->
    <div v-if="wide" class="shrink-0 border-b border-gray-100">
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
          <div v-for="i in 3" :key="i" class="rounded border border-gray-100 bg-white overflow-hidden animate-pulse" :class="wide ? 'flex' : ''">
            <div class="bg-gray-100 aspect-video" :class="wide ? 'w-[46%] max-w-[480px] self-start shrink-0' : 'w-full'"></div>
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

        <PurposeCard
          v-for="portal in filtered"
          :key="portal.id"
          :data-portal-id="portal.id"
          :portal="portal"
          :layout="layout"
          :images="images[portal.id]"
          :goals="goals[portal.id]"
          :busy-goal-id="busyGoalId"
          @goal-chat="(goal) => onGoalChat(goal, portal.name)"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import api from '@/pages/utils/api';
import { HIDDEN_ALL_TAB_PORTAL_IDS } from '@/constants/hiddenPortals';
import { openGoalTeamChat } from '@/pages/utils/goalTeamChat';
import PurposeCard from './PurposeCard.vue';

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

// Per-card data, loaded lazily. A missing goals entry means "still loading".
const images = ref<Record<number, string[]>>({});
const goals = ref<Record<number, any[]>>({});
const busyGoalId = ref<number | null>(null);

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
const requested = new Set<number>();

async function fetchPortals() {
  const seq = ++fetchSeq;
  loading.value = true;
  portals.value = [];
  images.value = {};
  goals.value = {};
  requested.clear();
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

// --- Lazy card data (images + goals), about one screen ahead ---
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
    { root, rootMargin: `0px 0px ${Math.max(root.clientHeight, 600)}px 0px`, threshold: 0 }
  );
  root.querySelectorAll<HTMLElement>('[data-portal-id]').forEach((el) => observer!.observe(el));
}

async function loadCardData(portalId: number) {
  if (requested.has(portalId)) return;
  requested.add(portalId);
  try {
    const res = await api.get(`/api/public/portal/${portalId}`);
    const data = res.data.result;
    const main = (data?.aSections || []).find((s: any) => s.title === 'Main Section');
    images.value = { ...images.value, [portalId]: (main?.aFiles || []).map((f: any) => f.url).filter(Boolean) };
    goals.value = { ...goals.value, [portalId]: data?.aGoals || [] };
  } catch {
    goals.value = { ...goals.value, [portalId]: [] };
  }
}

async function onGoalChat(goal: any, portalName: string) {
  if (!props.isAuth) {
    router.push({ path: '/register', query: { returnTo: '/main' } });
    return;
  }
  if (busyGoalId.value) return;
  busyGoalId.value = goal.id;
  try {
    emit('open-group', await openGoalTeamChat(goal, portalName, props.userId));
  } catch (e: any) {
    emit('toast', e?.message || 'Couldn’t open the Goal Team chat.');
  } finally {
    busyGoalId.value = null;
  }
}

onMounted(fetchPortals);
onUnmounted(() => observer?.disconnect());
</script>
