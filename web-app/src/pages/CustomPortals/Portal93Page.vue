<!--
  Portal93Page.vue
  Rep — Custom page for Portal 93 (High School Reunion event)

  Differences from PortalPage.vue:
  1. Desktop CTA: Donate button shown as a standalone v-if (not v-else-if),
     so it appears alongside Register for Event when both goals exist.
  2. Mobile CTA: Single fixed container stacks Register + Donate vertically
     instead of the three mutually-exclusive fixed divs used in PortalPage.vue.
-->

<template>
  <div class="flex flex-col h-screen bg-white overflow-hidden portal-page-container">
    <div v-if="isLoading && !portalDetail" class="flex items-center justify-center h-full">
      <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full"></div>
    </div>
    <div v-else-if="errorMessage" class="flex items-center justify-center h-full text-red-500 p-4">
      <p>{{ errorMessage }}</p>
    </div>
    <div v-else-if="portalDetail" class="flex flex-col flex-1 min-h-0">
      <!-- Header - Full Width Across Both Columns -->
      <PortalHeader :portal-name="portalDetail.name" :show-more="isCurrentUserLead" @back="goBack" @more="handleAddAction" />

      <!-- Two Column Layout (Desktop Only) -->
      <div class="flex flex-col flex-1 min-h-0 lg:flex-row">
        <!-- DESKTOP: Left Column - Image Gallery (70% width, full screen height) -->
        <div class="hidden lg:flex lg:w-[70%] lg:h-[calc(100vh-3rem)] lg:sticky lg:top-[3rem] lg:flex-col lg:bg-black" style="border: 12px solid black;">
          <ImageTabView
            :sections="(portalDetail.aSections || []).filter(s => s.title === 'Main Section')"
            @image-tap="openFullscreen"
            :desktop-mode="true"
          />
        </div>

        <!-- MOBILE & DESKTOP: Right Column - Content (30% on desktop) -->
        <div class="flex flex-col flex-1 min-h-0 lg:w-[30%]">

        <!-- 2. Main Scrollable Content -->
        <div class="flex-1 overflow-y-auto overflow-x-hidden pb-20 lg:pb-0" style="overscroll-behavior-y: contain;">
          <div class="relative">
            <!-- MOBILE ONLY: Image Gallery -->
            <div class="lg:hidden">
              <ImageTabView
                :sections="(portalDetail.aSections || []).filter(s => s.title === 'Main Section')"
                @image-tap="openFullscreen"
              />
            </div>

            <!-- Sticky Segmented Picker (mobile & desktop) -->
            <div class="sticky top-0 z-10 bg-white">
              <div class="py-2 px-4 border-b border-t border-gray-200">
                <PortalSegmentedPicker
                  :segments="['Goal Teams', 'Story']"
                  v-model="selectedSection"
                />
              </div>
            </div>

            <!-- Conditional Content -->
            <div class="px-4 pt-4 pb-36 lg:pb-4">
              <PortalResultsSection
                v-if="selectedSection === 0"
                :goals="portalGoals"
                :supporters-goal="supportersGoal"
              />
              <PortalStorySection
                v-else-if="selectedSection === 1"
                :portal="portalDetail"
              />
            </div>
          </div>
        </div>

        <!-- Desktop Inline Action Buttons -->
        <!-- PORTAL 93 CHANGE: Donate uses v-if (not v-else-if) so it shows alongside Register -->
        <div class="hidden lg:flex lg:flex-col lg:px-4 lg:py-3 lg:border-t lg:border-gray-100 lg:gap-2">
          <!-- Register for Event -->
          <button
            v-if="attendeesGoal && !isEventRegistered"
            @click="handleRSVP"
            class="w-full h-10 rounded-xl font-semibold text-sm text-white hover:opacity-90 transition-opacity"
            style="background-color: #D4AF37; color: #000000;"
          >
            Register for Event
          </button>
          <!-- Add to Calendar (after registration) -->
          <div v-else-if="isEventRegistered && portalDetail?.event_datetime" class="relative">
            <div v-if="showCalendarPicker" class="absolute bottom-full left-0 right-0 mb-2 bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden z-50">
              <a
                v-if="buildGoogleCalUrlFromPortal()"
                :href="buildGoogleCalUrlFromPortal()"
                target="_blank" rel="noopener noreferrer"
                class="flex items-center gap-3 px-4 py-3 text-sm font-semibold hover:bg-gray-50 border-b border-gray-100"
                style="color: #000000;"
                @click="showCalendarPicker = false"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Google Calendar
              </a>
              <a
                :href="`https://rep-june2025.onrender.com/api/portal/${portalDetail!.id}/calendar.ics`"
                class="flex items-center gap-3 px-4 py-3 text-sm font-semibold hover:bg-gray-50 border-b border-gray-100"
                style="color: #000000;"
                @click="showCalendarPicker = false"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Apple Calendar
              </a>
              <a
                :href="`https://rep-june2025.onrender.com/api/portal/${portalDetail!.id}/calendar.ics`"
                class="flex items-center gap-3 px-4 py-3 text-sm font-semibold hover:bg-gray-50"
                style="color: #000000;"
                @click="showCalendarPicker = false"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                Microsoft / Outlook
              </a>
            </div>
            <button
              @click="showCalendarPicker = !showCalendarPicker"
              class="w-full h-10 flex items-center justify-center gap-2 rounded-xl font-semibold text-sm text-white hover:opacity-90 transition-opacity"
              style="background-color: #000000; color: #D4AF37;"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              Add to Calendar
            </button>
          </div>
          <!-- PORTAL 93: Donate button — v-if (not v-else-if) so it always shows when supportGoal exists -->
          <button
            v-if="supportGoal"
            @click="openPaymentSheet"
            class="w-full h-10 rounded-xl font-semibold text-sm text-white hover:opacity-90 transition-opacity"
            style="background-color: #000000; color: #D4AF37;"
          >
            Donate
          </button>
          <!-- Message + More pills -->
          <div class="flex items-center gap-2">
            <button
              @click="openMessageSheet"
              class="flex-1 flex items-center justify-center gap-1.5 h-9 rounded-full text-sm font-semibold hover:opacity-80 transition-opacity"
              style="border: 2px solid #000000; color: #000000; background: white;"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
              </svg>
              Message
            </button>
            <button
              @click="handleAddAction"
              class="flex-1 flex items-center justify-center gap-1.5 h-9 rounded-full text-sm font-semibold text-white hover:opacity-80 transition-opacity"
              style="background: #D4AF37; color: #000000;"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                <circle cx="5" cy="12" r="2.5"/><circle cx="12" cy="12" r="2.5"/><circle cx="19" cy="12" r="2.5"/>
              </svg>
              More
            </button>
          </div>
        </div>

        <!-- PORTAL 93: Side-by-side Register + Donate bar at bottom (replaces generic bottom bar) -->
        <div
          v-if="(attendeesGoal && !isEventRegistered) || (isEventRegistered && portalDetail?.event_datetime) || supportGoal"
          class="fixed bottom-0 left-0 right-0 z-10 bg-white border-t border-gray-200 px-4 py-3 lg:hidden"
        >
          <div class="flex gap-3 max-w-md mx-auto">
            <!-- Register for Event -->
            <button
              v-if="attendeesGoal && !isEventRegistered"
              @click="handleRSVP"
              class="flex-1 h-14 rounded-xl font-bold text-base transition-transform hover:scale-105 active:scale-95"
              style="background-color: #D4AF37; color: #000000;"
            >
              Register
            </button>

            <!-- Add to Calendar (after registration) -->
            <div v-else-if="isEventRegistered && portalDetail?.event_datetime" class="relative flex-1">
              <div
                v-if="showCalendarPicker"
                class="absolute bottom-full left-0 right-0 mb-2 bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden"
              >
                <a
                  v-if="buildGoogleCalUrlFromPortal()"
                  :href="buildGoogleCalUrlFromPortal()"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="flex items-center gap-3 px-4 py-3 text-sm font-semibold hover:bg-gray-50 border-b border-gray-100"
                  style="color: #000000;"
                  @click="showCalendarPicker = false"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  Google Calendar
                </a>
                <a
                  :href="`https://rep-june2025.onrender.com/api/portal/${portalDetail!.id}/calendar.ics`"
                  class="flex items-center gap-3 px-4 py-3 text-sm font-semibold hover:bg-gray-50 border-b border-gray-100"
                  style="color: #000000;"
                  @click="showCalendarPicker = false"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  Apple Calendar
                </a>
                <a
                  :href="`https://rep-june2025.onrender.com/api/portal/${portalDetail!.id}/calendar.ics`"
                  class="flex items-center gap-3 px-4 py-3 text-sm font-semibold hover:bg-gray-50"
                  style="color: #000000;"
                  @click="showCalendarPicker = false"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                  Microsoft / Outlook
                </a>
              </div>
              <button
                @click="showCalendarPicker = !showCalendarPicker"
                class="w-full flex items-center justify-center gap-2 h-14 rounded-xl font-bold text-sm transition-transform hover:scale-105 active:scale-95"
                style="background-color: #000000; color: #D4AF37;"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Add to Calendar
              </button>
            </div>

            <!-- Donate button — always shown when supportGoal exists -->
            <button
              v-if="supportGoal"
              @click="openPaymentSheet"
              class="flex-1 h-14 rounded-xl font-bold text-base transition-transform hover:scale-105 active:scale-95"
              style="background-color: #000000; color: #D4AF37;"
            >
              Donate
            </button>
          </div>
        </div>
        </div>
      </div>
    </div>

    <!-- Modals & Fullscreen Views -->
    <transition name="fade">
      <ActionSheetModal
        v-if="activeSheet === 'portalActionMenu'"
        :portal="portalDetail"
        :is-current-user-lead="isCurrentUserLead"
        :support-goal="supportGoal"
        @close="activeSheet = null"
        @add-goal="activeSheet = 'addGoal'"
        @edit-purpose="navigateToEdit"
        @flag="showFlagConfirmation = true"
        @support="openPaymentSheet"
        @share="handleShare"
        @join-goal-team="activeSheet = 'goalPicker'"
      />
    </transition>

    <transition name="fade">
      <GoalPickerSheet
        v-if="activeSheet === 'goalPicker'"
        :goals="portalGoals"
        :current-user-id="userId"
        @close="activeSheet = null"
        @join="(goalId) => { joinGoalTeam(goalId); activeSheet = null; }"
        @view-details="(goal) => { router.push(`/goal/${goal.id}`); }"
      />
    </transition>

    <transition name="fade">
      <FullscreenImageViewer
        v-if="isFullscreenOpen"
        :images="(portalDetail?.aSections || []).filter(s => s.title === 'Main Section').flatMap(s => s.aFiles)"
        :start-index="fullscreenStartIndex"
        @close="isFullscreenOpen = false"
      />
    </transition>

    <!-- PayTransaction Sheet -->
    <div v-if="showPaymentSheet && supportGoal" class="fixed inset-0 z-50 bg-white">
      <PayTransaction
        :portal-id="portalId"
        :portal-name="portalDetail?.name || 'Portal'"
        :goal-id="supportGoal.id"
        :goal-name="supportGoal.title"
        :transaction-type="supportGoal.typeName === 'Donations' ? 'donation' : 'payment'"
        @close="showPaymentSheet = false"
      />
    </div>

    <!-- Add Goal Sheet -->
    <EditGoal
      v-if="activeSheet === 'addGoal'"
      :portal-id="portalId"
      :user-id="userId"
      :reporting-increments="reportingIncrementsForEditGoal"
      @close="handleAddGoalClose"
    />

    <!-- Alerts -->
    <transition name="fade">
      <div v-if="showFlagConfirmation" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
        <div class="bg-white rounded-lg shadow-lg p-6 max-w-sm w-full">
          <h3 class="text-lg font-bold mb-3">Flag Portal?</h3>
          <p class="mb-4">Are you sure you want to flag this portal as inappropriate?</p>
          <div class="flex justify-end space-x-3">
            <button
              @click="showFlagConfirmation = false"
              class="px-4 py-2 border border-gray-300 rounded-md"
            >
              Cancel
            </button>
            <button
              @click="handleFlag"
              class="px-4 py-2 bg-red-600 text-white rounded-md"
            >
              Flag
            </button>
          </div>
        </div>
      </div>
    </transition>

    <transition name="fade">
      <div v-if="flagResultMessage" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
        <div class="bg-white rounded-lg shadow-lg p-6 max-w-sm w-full">
          <p class="mb-4">{{ flagResultMessage }}</p>
          <div class="flex justify-end">
            <button
              @click="flagResultMessage = null"
              class="px-4 py-2 bg-green-600 text-white rounded-md"
            >
              OK
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch, defineComponent, defineAsyncComponent, h, onBeforeUnmount } from 'vue';
import { useRoute, useRouter, RouterLink } from 'vue-router';

defineOptions({
  name: 'Portal93Page'
});
import api from '@/pages/utils/api';
import { isAuthenticated } from '@/utils/auth';
const EditGoal = defineAsyncComponent(() => import('../GoalPages/EditGoal.vue'));
import PayTransaction from '../MainPages/PayTransaction.vue';
import { BREAKPOINTS } from '@/constants/breakpoints';
import { shareUrl } from '@/utils/share';

// --- Interfaces (from Swift Models) ---
interface User {
  id: number;
  fname?: string;
  lname?: string;
  profile_picture_url?: string;
}

interface Goal {
  id: number;
  title: string;
  typeName: string;
  metricName?: string;
  chartData?: any[];
  quota?: number;
  subtitle?: string;
  progressPercent?: number;
  progress?: number;
  creatorId?: number;
  is_member?: boolean;
}

interface PortalFile {
  id: number;
  url?: string;
}

interface PortalSection {
  id: number;
  title: string;
  aFiles: PortalFile[];
}

interface PortalText {
  id: number;
  title?: string;
  text?: string;
  section?: string;
  position?: number;
  created_at?: string;
  updated_at?: string;
}

interface PortalDetail {
  id: number;
  name: string;
  subtitle?: string;
  about?: string;
  categories_id?: number;
  cities_id?: number;
  lead_id?: number;
  users_id?: number;
  _c_users_count?: number;
  mainImageUrl?: string;
  aSections?: PortalSection[];
  aLeads?: User[];
  aUsers?: User[];
  aTexts?: PortalText[];
  aGoals?: Goal[];
  portal_type?: string;
  event_datetime?: string;
  event_location?: string;
  event_timezone?: string;
  event_duration_minutes?: number;
}

interface ReportingIncrement {
  id: number;
  name: string;
}

// --- Orientation Detection ---
const isLandscape = ref(window.innerWidth > window.innerHeight);

const updateOrientation = () => {
  isLandscape.value = window.innerWidth > window.innerHeight;
  if (isLandscape.value && !isFullscreenOpen.value && portalDetail.value?.aSections?.length) {
    isFullscreenOpen.value = true;
    fullscreenStartIndex.value = 0;
  }
};

// --- Composables & Initial Setup ---
const route = useRoute();
const router = useRouter();
const portalId = Number(route.params.id);
const userId = Number(localStorage.getItem('userId') || '0');

// --- State ---
const portalDetail = ref<PortalDetail | null>(null);
const portalGoals = ref<Goal[]>([]);
const reportingIncrements = ref<ReportingIncrement[]>([]);
const selectedSection = ref(0);
const isLoading = ref(true);
const errorMessage = ref<string | null>(null);

type ActiveSheet = 'portalActionMenu' | 'addGoal' | 'goalPicker' | null;
const activeSheet = ref<ActiveSheet>(null);
const showPaymentSheet = ref(false);
const navigateToEditAfterDismiss = ref(false);
const showEditPortal = ref(false);

const showFlagConfirmation = ref(false);
const flagResultMessage = ref<string | null>(null);

const isFullscreenOpen = ref(false);
const fullscreenStartIndex = ref(0);

// --- Computed Properties ---
const supportGoal = computed(() => {
  return portalGoals.value.find(g => g.typeName === 'Fund' || g.typeName === 'Sales' || g.typeName === 'Donations');
});

const isCurrentUserLead = computed(() => {
  return portalDetail.value?.aUsers?.some(u => u.id === userId) ?? false;
});

const reportingIncrementsForEditGoal = computed(() => {
  return reportingIncrements.value.map(ri => ({ id: ri.id, title: ri.name }));
});

const leadRepUser = computed(() => {
  const creatorId = portalDetail.value?.users_id;
  if (!creatorId) return null;
  return portalDetail.value?.aUsers?.find(u => u.id === creatorId) ?? null;
});

const attendeesGoal = computed(() => {
  return portalGoals.value.find(g =>
    g.typeName === 'Recruiting' &&
    (g.title?.toLowerCase() === 'attendees' || g.title?.toLowerCase().includes('attendee'))
  );
});

const supportersGoal = computed(() => {
  return portalGoals.value.find(g =>
    g.typeName === 'Recruiting' &&
    (g.title?.toLowerCase() === 'supporters' || g.title?.toLowerCase().includes('supporter'))
  );
});

// --- API Methods ---
const fetchPortalDetail = async () => {
  isLoading.value = true;
  errorMessage.value = null;
  const authenticated = isAuthenticated();

  try {
    let res;
    if (!authenticated) {
      res = await api.get(`/api/public/portal/${portalId}`);
    } else {
      res = await api.get(`/api/portal/details?portals_id=${portalId}&user_id=${userId}`);
    }

    if (res.data && res.data.result) {
      portalDetail.value = res.data.result;
      if (!authenticated && portalDetail.value.aGoals) {
        portalGoals.value = portalDetail.value.aGoals;
      }
    } else {
      errorMessage.value = "Could not find portal details";
    }
  } catch (err: any) {
    errorMessage.value = err.response?.data?.error || 'Failed to load portal details.';
    console.error(err);
  } finally {
    isLoading.value = false;
  }
};

const fetchPortalGoals = async () => {
  const authenticated = isAuthenticated();
  if (!authenticated) return;

  try {
    const res = await api.get(`/api/goals/portal?portals_id=${portalId}`);
    if (res.data && res.data.aGoals) {
      portalGoals.value = res.data.aGoals;
    }
  } catch (err) {
    console.error('Failed to load portal goals:', err);
  }
};

const fetchReportingIncrements = async () => {
  try {
    const res = await api.get('/api/reporting_increments/list');
    if (res.data && res.data.reportingIncrements) {
      reportingIncrements.value = res.data.reportingIncrements;
    }
  } catch (err) {
    console.error('Failed to load reporting increments:', err);
  }
};

const flagPortal = async () => {
  try {
    await api.post('/api/portal/flag_portal', { portal_id: portalId, reason: '' });
    flagResultMessage.value = 'Portal flagged. Thank you for your report.';
  } catch (err) {
    flagResultMessage.value = 'Failed to flag portal.';
    console.error(err);
  }
};

const joinGoalTeam = async (goalId: number) => {
  const res = await api.post('/api/goals/join_leave', {
    aGoalsIDs: [goalId],
    todo: 'join'
  });

  if (res.data && res.data.result && res.data.result[goalId] === 'ok') {
    await fetchPortalGoals();
    return true;
  } else if (res.data && res.data.result && res.data.result[goalId] === 'Already a member') {
    await fetchPortalGoals();
    return true;
  } else {
    console.error('Error joining goal team:', res.data);
    throw new Error('Failed to join goal team');
  }
};

const isEventRegistered = ref(false);
const showCalendarPicker = ref(false);

watch(attendeesGoal, (goal) => {
  if (goal?.is_member && !isEventRegistered.value) {
    isEventRegistered.value = true;
  }
}, { immediate: true });

const buildGoogleCalUrlFromPortal = (): string => {
  const portal = portalDetail.value;
  if (!portal?.event_datetime) return '';
  try {
    const dt = new Date(portal.event_datetime);
    const pad = (n: number) => String(n).padStart(2, '0');
    const fmt = (d: Date) =>
      `${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}T${pad(d.getHours())}${pad(d.getMinutes())}00`;
    const durationMs = (portal.event_duration_minutes ?? 90) * 60 * 1000;
    const end = new Date(dt.getTime() + durationMs);
    const parts = [
      `action=TEMPLATE`,
      `text=${encodeURIComponent(portal.name)}`,
      `dates=${fmt(dt)}/${fmt(end)}`,
    ];
    if (portal.event_location) parts.push(`location=${encodeURIComponent(portal.event_location)}`);
    if (portal.about) parts.push(`details=${encodeURIComponent(portal.about.slice(0, 200))}`);
    return `https://calendar.google.com/calendar/render?${parts.join('&')}`;
  } catch { return ''; }
};

const handleRSVP = async () => {
  if (!attendeesGoal.value) return;

  if (isAuthenticated()) {
    try {
      await joinGoalTeam(attendeesGoal.value.id);
      isEventRegistered.value = true;
      alert('✓ You\'re registered for this event!');
    } catch (err) {
      console.error('RSVP failed:', err);
      alert('Failed to register. Please try again.');
    }
  } else {
    localStorage.setItem('rsvpIntent', JSON.stringify({
      portalId: portalId,
      goalId: attendeesGoal.value.id,
      goalTitle: attendeesGoal.value.title,
      isEventRegistration: true
    }));
    router.push({
      path: '/register',
      query: { returnTo: `/portal/${portalId}` }
    });
  }
};

// --- Event Handlers ---
const goBack = () => {
  const fromTab = route.query.from;
  if (fromTab) {
    router.push({ path: '/main', query: { tab: fromTab } });
  } else {
    router.push('/main');
  }
};

const handleAddAction = () => {
  activeSheet.value = 'portalActionMenu';
};

const openFullscreen = (index: number) => {
  fullscreenStartIndex.value = index;
  isFullscreenOpen.value = true;
};

const openMessageSheet = () => {
  if (!isAuthenticated()) {
    router.push({
      path: '/register',
      query: { returnTo: `/portal/${portalId}` }
    });
    return;
  }
  if (leadRepUser.value) {
    router.push(`/chat/user/${leadRepUser.value.id}`);
  }
};

const openPaymentSheet = () => {
  activeSheet.value = null;
  if (supportGoal.value) {
    showPaymentSheet.value = true;
  }
};

const navigateToEdit = () => {
  navigateToEditAfterDismiss.value = true;
  activeSheet.value = null;
};

const handleFlag = () => {
  showFlagConfirmation.value = false;
  activeSheet.value = null;
  flagPortal();
};

const handleShare = async () => {
  activeSheet.value = null;
  if (portalDetail.value) {
    try {
      await shareUrl({
        url: `https://www.repsomething.com/portal/${portalDetail.value.id}`,
        title: portalDetail.value.name,
        text: `Check out ${portalDetail.value.name} on Rep`
      });
    } catch (error) {
      console.error('Share failed:', error);
    }
  }
};

const handleAddGoalClose = () => {
  activeSheet.value = null;
  fetchPortalGoals();
};

// --- Lifecycle Hooks ---
onMounted(async () => {
  await fetchPortalDetail();
  if (portalDetail.value?.portal_type === 'event') {
    selectedSection.value = 1;
  }
  await fetchPortalGoals();

  if (isAuthenticated()) {
    fetchReportingIncrements();
  }

  const rsvpIntentStr = localStorage.getItem('rsvpIntent');
  if (rsvpIntentStr && isAuthenticated()) {
    try {
      const rsvpIntent = JSON.parse(rsvpIntentStr);
      if (rsvpIntent.portalId === portalId && rsvpIntent.goalId) {
        const success = await joinGoalTeam(rsvpIntent.goalId);
        if (success) {
          localStorage.removeItem('rsvpIntent');
          const goalTitle = (rsvpIntent.goalTitle || '').toLowerCase();
          if (goalTitle.includes('supporter')) {
            alert('✓ You\'ve joined the Supporters team!');
          } else {
            isEventRegistered.value = true;
            alert('✓ You\'re Registered!');
          }
        } else {
          console.error('Failed to auto-join goal team');
        }
      }
    } catch (err) {
      console.error('Failed to process RSVP intent:', err);
      if (err instanceof SyntaxError) {
        localStorage.removeItem('rsvpIntent');
      }
    }
  }

  window.addEventListener('resize', updateOrientation);
  window.addEventListener('orientationchange', updateOrientation);

  document.addEventListener('ShowEditPortalFromToolbar', () => {
    showEditPortal.value = true;
  });
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', updateOrientation);
  window.removeEventListener('orientationchange', updateOrientation);
  document.removeEventListener('ShowEditPortalFromToolbar', () => {});
});

watch(navigateToEditAfterDismiss, (newVal) => {
  if (newVal && !activeSheet.value) {
    showEditPortal.value = true;
    navigateToEditAfterDismiss.value = false;
  }
});

watch(showEditPortal, (newVal) => {
  if (newVal && portalDetail.value) {
    router.push(`/portal/edit/${portalId}`);
  }
});

watch(portalGoals, () => {}, { immediate: true });

// --- Inline Child Components (identical to PortalPage.vue) ---

const PortalHeader = defineComponent({
  props: { portalName: String, showMore: Boolean },
  emits: ['back', 'more'],
  setup(props, { emit }) {
    return () => h('header', {
      class: 'flex items-center h-14 lg:h-12 px-4 border-b border-gray-200 shrink-0',
      style: 'background-color: #f7f7f7'
    }, [
      h('button', {
        onClick: () => emit('back'),
        style: 'color: #8cc65d'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-6 w-6 lg:h-5 lg:w-5',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M15 19l-7-7 7-7'
          })
        ])
      ]),
      h('h1', {
        class: 'flex-1 text-center font-bold text-xl lg:text-sm lg:font-semibold'
      }, props.portalName),
      props.showMore
        ? h('button', {
            class: 'w-12 lg:w-8 flex items-center justify-center',
            onClick: () => emit('more')
          }, [
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-6 w-6 text-gray-600',
              fill: 'currentColor',
              viewBox: '0 0 24 24'
            }, [
              h('circle', { cx: '5', cy: '12', r: '2' }),
              h('circle', { cx: '12', cy: '12', r: '2' }),
              h('circle', { cx: '19', cy: '12', r: '2' })
            ])
          ])
        : h('div', { class: 'w-12 lg:w-8' })
    ]);
  }
});

const ImageTabView = defineComponent({
  props: {
    sections: Array as () => PortalSection[],
    desktopMode: Boolean
  },
  emits: ['image-tap'],
  setup(props, { emit }) {
    const images = computed(() => props.sections?.flatMap(s => s.aFiles) || []);
    const currentImageIndex = ref(0);
    let slideshowTimer: ReturnType<typeof setInterval> | null = null;

    onMounted(() => {
      if (images.value.length > 1) {
        images.value.forEach(img => {
          if (img.url) {
            const el = new window.Image();
            el.src = img.url;
          }
        });

        const preloads = images.value.slice(0, 7).map(img => new Promise<void>(resolve => {
          let done = false;
          const finish = () => { if (!done) { done = true; resolve(); } };
          const el = new window.Image();
          el.onload = finish;
          el.onerror = finish;
          el.src = img.url || '';
          if (el.complete) finish();
        }));

        if (!props.desktopMode) {
          Promise.all(preloads).then(() => {
            let step = 1;
            const total = images.value.length;
            slideshowTimer = setInterval(() => {
              if (step < total) {
                currentImageIndex.value = step;
                step++;
              } else {
                currentImageIndex.value = 0;
                clearInterval(slideshowTimer!);
                slideshowTimer = null;
              }
            }, 400);
          });
        }
      }
    });

    onBeforeUnmount(() => {
      if (slideshowTimer) {
        clearInterval(slideshowTimer);
        slideshowTimer = null;
      }
    });

    const nextImage = () => {
      if (images.value.length > 0) {
        currentImageIndex.value = (currentImageIndex.value + 1) % images.value.length;
      }
    };

    const prevImage = () => {
      if (images.value.length > 0) {
        currentImageIndex.value = (currentImageIndex.value - 1 + images.value.length) % images.value.length;
      }
    };

    const noSelectStyle = {
      userSelect: 'none',
      WebkitUserSelect: 'none',
      MozUserSelect: 'none',
      msUserSelect: 'none'
    };

    const arrowSvg = (d: string) => h('svg', {
      xmlns: 'http://www.w3.org/2000/svg',
      class: 'h-6 w-6 text-white',
      fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor'
    }, [h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d })]);

    return () => {
      if (props.desktopMode) {
        return h('div', { class: 'w-full h-full bg-black flex flex-col overflow-hidden', style: noSelectStyle }, [
          h('div', { class: 'relative flex-1 overflow-hidden flex items-center justify-center' }, [
            images.value.length > 0
              ? h('img', {
                  src: images.value[currentImageIndex.value]?.url || '/placeholder-image.png',
                  class: 'max-w-full max-h-full object-contain cursor-pointer',
                  onClick: () => emit('image-tap', currentImageIndex.value)
                })
              : h('div', { class: 'flex items-center justify-center h-full text-gray-500' }, 'No Images'),

            images.value.length > 1 && h('button', {
              key: 'prev',
              class: 'absolute left-2 top-1/2 -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-1',
              onClick: prevImage,
              onMousedown: (e: MouseEvent) => e.preventDefault()
            }, [arrowSvg('M15 19l-7-7 7-7')]),

            images.value.length > 1 && h('button', {
              key: 'next',
              class: 'absolute right-2 top-1/2 -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-1',
              onClick: nextImage,
              onMousedown: (e: MouseEvent) => e.preventDefault()
            }, [arrowSvg('M9 5l7 7-7 7')]),
          ]),

          images.value.length > 1 && h('div', {
            class: 'flex gap-2 px-4 py-2 justify-center overflow-x-auto shrink-0',
            style: 'background:#000'
          }, images.value.map((img, idx) =>
            h('button', {
              key: idx,
              class: 'shrink-0 focus:outline-none',
              onClick: () => { currentImageIndex.value = idx; },
              onMousedown: (e: MouseEvent) => e.preventDefault()
            }, [
              h('img', {
                src: img.url,
                class: `object-cover rounded transition-all duration-150 ${
                  idx === currentImageIndex.value
                    ? 'ring-2 ring-white opacity-100'
                    : 'opacity-50 hover:opacity-80'
                }`,
                style: 'width:80px; height:45px'
              })
            ])
          ))
        ]);
      }

      return h('div', {
        class: 'relative w-full aspect-[16/9] bg-gray-200 overflow-hidden',
        style: noSelectStyle
      }, [
        images.value.length > 0
          ? h('img', {
              src: images.value[currentImageIndex.value]?.url || '/placeholder-image.png',
              class: 'w-full h-full object-cover cursor-pointer',
              onClick: () => emit('image-tap', currentImageIndex.value)
            })
          : h('div', { class: 'flex items-center justify-center h-full text-gray-500' }, 'No Images'),

        images.value.length > 1 && h('div', {
          class: 'absolute bottom-2 left-0 right-0 flex justify-center space-x-2'
        }, images.value.map((_, idx) =>
          h('div', {
            key: idx,
            class: `w-2 h-2 rounded-full ${idx === currentImageIndex.value ? 'bg-white' : 'bg-gray-400'}`
          })
        )),

        images.value.length > 1 && [
          h('button', {
            key: 'prev',
            class: 'absolute left-2 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-1',
            onClick: prevImage,
            onMousedown: (e: MouseEvent) => e.preventDefault()
          }, [arrowSvg('M15 19l-7-7 7-7')]),
          h('button', {
            key: 'next',
            class: 'absolute right-2 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-1',
            onClick: nextImage,
            onMousedown: (e: MouseEvent) => e.preventDefault()
          }, [arrowSvg('M9 5l7 7-7 7')])
        ]
      ]);
    };
  }
});

const PortalSegmentedPicker = defineComponent({
  props: {
    segments: Array as () => string[],
    modelValue: Number
  },
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    return () => h('div', {
      class: 'flex border border-black rounded-md overflow-hidden'
    },
      props.segments?.map((segment, index) =>
        h('button', {
          key: index,
          class: [
            'flex-1 py-2 text-sm font-medium transition-colors',
            props.modelValue === index ? 'bg-black text-white' : 'bg-white text-black',
            index < (props.segments?.length || 0) - 1 ? 'border-r border-black' : ''
          ],
          onClick: () => emit('update:modelValue', index)
        }, segment)
      ) || []
    );
  }
});

const PortalResultsSection = defineComponent({
  props: {
    goals: Array as () => Goal[],
    supportersGoal: Object as () => Goal | null
  },
  setup(props) {
    const GoalListItem = (goal: Goal) => {
      const tagText = goal.typeName.toLowerCase() === 'other'
        ? (goal.metricName?.trim() || goal.typeName).substring(0, 9)
        : goal.typeName;

      const chartBars = (goal.chartData || []).slice(-4);

      return h('div', {
        class: 'flex items-center gap-4 py-1 px-4 bg-white hover:bg-gray-50 transition',
        style: { height: '89px' }
      }, [
        h('div', {
          class: 'flex items-end gap-[6px]',
          style: { width: '114px', height: '81px' }
        }, chartBars.map((bar, idx) => {
          const quota = goal.quota > 0 ? goal.quota : 1;
          const heightPercent = Math.min(100, Math.max(0, (bar.value / quota) * 100));
          const barHeight = (77 * heightPercent) / 100;

          return h('div', {
            key: idx,
            class: 'flex flex-col justify-end',
            style: { width: '24px', height: '100%' }
          }, [
            h('div', {
              class: 'rounded-sm',
              style: {
                width: '24px',
                height: `${Math.max(barHeight, 0)}px`,
                backgroundColor: '#8cc65d',
                minHeight: '0px'
              }
            })
          ]);
        })),

        h('div', { class: 'flex-1 flex flex-col justify-center gap-1' }, [
          h('h3', { class: 'font-semibold text-[17px] leading-tight' }, goal.title),
          goal.subtitle && goal.subtitle.trim()
            ? h('p', { class: 'text-[15px] text-gray-600 leading-tight' }, goal.subtitle)
            : null,
          h('p', { class: 'text-[15px] text-black' }, `${Math.round(goal.progressPercent || (goal.progress * 100))}% [${tagText}]`)
        ].filter(Boolean))
      ]);
    };

    const sortedGoals = computed(() => {
      if (!props.goals || props.goals.length === 0) return [];
      if (!props.supportersGoal) return props.goals;

      const supportersGoal = props.goals.find(g => g.id === props.supportersGoal!.id);
      const otherGoals = props.goals.filter(g => g.id !== props.supportersGoal!.id);

      return supportersGoal ? [supportersGoal, ...otherGoals] : props.goals;
    });

    return () => h('div', { class: 'space-y-2' }, [
      (props.goals?.length || 0) > 0
        ? [
            ...sortedGoals.value.map((goal, index) => [
              h(RouterLink, {
                key: `link-${index}`,
                to: `/goal/${goal.id}`,
                class: 'block'
              }, () => GoalListItem(goal)),
              h('div', {
                key: `divider-${index}`,
                class: 'border-b border-gray-200'
              })
            ]).flat(),
            h('div', { key: 'bottom-spacer', style: { height: '80px' } })
          ]
        : h('p', { class: 'text-gray-500 py-8 text-center' }, 'No goals for this portal yet.')
    ]);
  }
});

const PortalStorySection = defineComponent({
  props: { portal: Object as () => PortalDetail | null },
  setup(props) {
    const formatEventDatetime = (dtString: string, timezone?: string): string => {
      try {
        const date = new Date(dtString);
        const options: Intl.DateTimeFormatOptions = {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          hour: 'numeric',
          minute: '2-digit',
          hour12: true,
        };
        if (timezone) {
          try {
            Intl.DateTimeFormat('en-US', { timeZone: timezone });
            options.timeZone = timezone;
          } catch {
            // fall back to local
          }
        }
        return new Intl.DateTimeFormat('en-US', options).format(date);
      } catch {
        return dtString;
      }
    };

    const storyTexts = computed(() =>
      (props.portal?.aTexts || [])
        .filter(t => (t.section || '') === 'story')
        .sort((a, b) => (a.position ?? 0) - (b.position ?? 0))
    );

    const gallerySections = computed(() =>
      (props.portal?.aSections || [])
        .filter(s => s.title !== 'Main Section' && s.aFiles && s.aFiles.length > 0)
        .sort((a: any, b: any) => (a.position || 0) - (b.position || 0))
    );

    const fullscreenImages = ref<PortalFile[]>([]);
    const fullscreenIndex = ref(0);
    const showFullscreen = ref(false);

    const openGalleryFullscreen = (section: PortalSection, imgIndex: number) => {
      fullscreenImages.value = section.aFiles;
      fullscreenIndex.value = imgIndex;
      showFullscreen.value = true;
    };

    const closeFullscreen = () => { showFullscreen.value = false; };
    const fullscreenPrev = () => { if (fullscreenIndex.value > 0) fullscreenIndex.value--; };
    const fullscreenNext = () => {
      if (fullscreenIndex.value < fullscreenImages.value.length - 1) fullscreenIndex.value++;
    };

    const linkifyLine = (line: string) => {
      const urlRegex = /(https?:\/\/[^\s]+)|(www\.[^\s]+)/gi;
      const parts: any[] = [];
      let lastIndex = 0;
      let match;
      urlRegex.lastIndex = 0;

      while ((match = urlRegex.exec(line)) !== null) {
        if (match.index > lastIndex) {
          parts.push(line.substring(lastIndex, match.index));
        }
        const urlText = match[0];
        const fullUrl = urlText.startsWith('www.') ? `https://${urlText}` : urlText;
        parts.push(
          h('a', {
            href: fullUrl,
            target: '_blank',
            rel: 'noopener noreferrer',
            class: 'story-link',
            style: { color: '#2563eb', textDecoration: 'underline', cursor: 'pointer' },
            onClick: (e: MouseEvent) => {
              e.preventDefault();
              window.open(fullUrl, '_blank', 'noopener,noreferrer');
            }
          }, urlText)
        );
        lastIndex = match.index + urlText.length;
      }

      if (lastIndex < line.length) {
        parts.push(line.substring(lastIndex));
      }
      return parts.length > 0 ? parts : [line];
    };

    const renderLinkableText = (text: string) => {
      if (!text) return [];
      const lines = text.split('\n');
      const result: any[] = [];
      lines.forEach((line, lineIndex) => {
        result.push(...linkifyLine(line));
        if (lineIndex < lines.length - 1) {
          result.push(h('br'));
        }
      });
      return result;
    };

    return () => h('div', { class: 'space-y-6' }, [
      h('h2', { class: 'font-bold text-xl' }, 'Leads'),
      h('div', { class: 'overflow-x-auto -mx-4 px-4' }, [
        h('div', { class: 'flex space-x-6 pb-2' },
          (props.portal?.aLeads || []).map((lead, index) =>
            h('div', {
              key: index,
              class: 'text-center flex flex-col items-center'
            }, [
              lead.profile_picture_url
                ? h('img', {
                    src: lead.profile_picture_url,
                    class: 'w-12 h-12 rounded-full object-cover'
                  })
                : h('div', {
                    class: 'w-12 h-12 rounded-full bg-gray-300 flex items-center justify-center'
                  }, [
                    h('svg', {
                      class: 'w-6 h-6 text-gray-500',
                      fill: 'currentColor',
                      viewBox: '0 0 20 20'
                    }, [
                      h('path', {
                        'fill-rule': 'evenodd',
                        d: 'M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z',
                        'clip-rule': 'evenodd'
                      })
                    ])
                  ]),
              h('p', { class: 'text-sm mt-2 whitespace-nowrap' },
                `${lead.fname || ''} ${lead.lname ? lead.lname.charAt(0) + '.' : ''}`)
            ])
          )
        )
      ]),
      h('div', { class: 'border-t border-gray-200 my-4' }),
      ...storyTexts.value.map((textBlock, index) =>
        h('div', {
          key: index,
          class: 'space-y-2 mb-6'
        }, [
          textBlock.title && h('h3', { class: 'font-semibold text-xl' }, textBlock.title),
          textBlock.text && h('div', {
            class: 'text-black text-[17px] leading-relaxed'
          }, renderLinkableText(textBlock.text))
        ])
      ),

      ...gallerySections.value.map((section: any, sIdx: number) =>
        h('div', { key: `gallery-${sIdx}`, class: 'space-y-2' }, [
          h('div', { class: 'border-t border-gray-200 pt-4' }),
          h('h3', { class: 'font-semibold text-lg' }, section.title),
          h('div', {
            class: 'overflow-x-auto -mx-4 px-4',
            style: { WebkitOverflowScrolling: 'touch' }
          }, [
            h('div', { class: 'flex gap-3 pb-2' },
              section.aFiles.map((file: any, imgIdx: number) =>
                h('img', {
                  key: file.id || imgIdx,
                  src: file.url,
                  class: 'w-[213px] h-[120px] flex-shrink-0 rounded-lg object-cover cursor-pointer hover:opacity-90 transition-opacity',
                  onClick: () => openGalleryFullscreen(section, imgIdx)
                })
              )
            )
          ])
        ])
      ),

      props.portal?.portal_type === 'event' && (props.portal?.event_datetime || props.portal?.event_location) && h('div', {
        class: 'border-t border-gray-200 pt-4 mt-2 space-y-3'
      }, [
        h('h3', { class: 'font-semibold text-lg mb-2' }, 'Event Details'),
        props.portal?.event_datetime && h('div', { class: 'flex items-start gap-3' }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-5 w-5 text-gray-500 mt-0.5 shrink-0',
            fill: 'none',
            viewBox: '0 0 24 24',
            stroke: 'currentColor',
            'stroke-width': '1.5'
          }, [
            h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' })
          ]),
          h('div', {}, [
            h('p', { class: 'text-[17px] text-black' },
              formatEventDatetime(props.portal.event_datetime, props.portal?.event_timezone)
            ),
            props.portal?.event_timezone && h('p', { class: 'text-sm text-gray-500 mt-0.5' }, props.portal.event_timezone)
          ])
        ]),
        props.portal?.event_location && h('div', { class: 'flex items-start gap-3' }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-5 w-5 text-gray-500 mt-0.5 shrink-0',
            fill: 'none',
            viewBox: '0 0 24 24',
            stroke: 'currentColor',
            'stroke-width': '1.5'
          }, [
            h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z' }),
            h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M15 11a3 3 0 11-6 0 3 3 0 016 0z' })
          ]),
          h('p', { class: 'text-[17px] text-black' }, props.portal.event_location)
        ]),
      ]),

      showFullscreen.value && h('div', {
        class: 'fixed inset-0 z-50 bg-black flex flex-col items-center justify-center',
        onClick: closeFullscreen
      }, [
        h('button', {
          class: 'absolute top-4 right-4 z-10 text-white text-3xl font-light w-10 h-10 flex items-center justify-center',
          onClick: (e: Event) => { e.stopPropagation(); closeFullscreen(); }
        }, '×'),

        fullscreenIndex.value > 0 && h('button', {
          class: 'absolute left-3 top-1/2 -translate-y-1/2 z-10 text-white text-4xl font-light w-12 h-12 flex items-center justify-center rounded-full bg-black bg-opacity-40 hover:bg-opacity-60 transition-colors',
          onClick: (e: Event) => { e.stopPropagation(); fullscreenPrev(); }
        }, '‹'),

        fullscreenIndex.value < fullscreenImages.value.length - 1 && h('button', {
          class: 'absolute right-3 top-1/2 -translate-y-1/2 z-10 text-white text-4xl font-light w-12 h-12 flex items-center justify-center rounded-full bg-black bg-opacity-40 hover:bg-opacity-60 transition-colors',
          onClick: (e: Event) => { e.stopPropagation(); fullscreenNext(); }
        }, '›'),

        h('img', {
          src: fullscreenImages.value[fullscreenIndex.value]?.url || '',
          class: 'max-w-full max-h-[85vh] object-contain select-none',
          style: { pointerEvents: 'none' },
          draggable: false
        }),

        fullscreenImages.value.length > 1 && h('div', {
          class: 'absolute bottom-6 left-0 right-0 flex justify-center gap-2',
          onClick: (e: Event) => e.stopPropagation()
        },
          fullscreenImages.value.map((_: any, dotIdx: number) =>
            h('div', {
              key: dotIdx,
              class: `w-2 h-2 rounded-full transition-colors ${dotIdx === fullscreenIndex.value ? 'bg-white' : 'bg-white/40'}`,
              style: { cursor: 'pointer' },
              onClick: () => { fullscreenIndex.value = dotIdx; }
            })
          )
        ),

        h('div', {
          class: 'absolute bottom-14 text-white text-sm opacity-70'
        }, `${fullscreenIndex.value + 1} / ${fullscreenImages.value.length}`)
      ])
    ]);
  }
});

const ActionSheetModal = defineComponent({
  props: {
    portal: Object as () => PortalDetail | null,
    isCurrentUserLead: Boolean,
    supportGoal: Object as () => Goal | null,
  },
  emits: ['close', 'add-goal', 'edit-purpose', 'flag', 'support', 'share', 'join-goal-team'],
  setup(props, { emit }) {
    const isDesktop = ref(window.innerWidth >= BREAKPOINTS.DESKTOP);

    return () => {
      if (isDesktop.value) {
        return h('div', {
          class: 'fixed inset-0 z-40 flex items-center justify-center',
          onClick: () => emit('close')
        }, [
          h('div', { class: 'absolute inset-0 bg-black/40' }),
          h('div', {
            class: 'relative z-10 bg-white rounded-2xl shadow-2xl w-72 overflow-hidden',
            onClick: (e: Event) => e.stopPropagation()
          }, [
            h('div', { class: 'px-2 py-2' }, [
              props.supportGoal && h('button', {
                class: 'w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left',
                onClick: () => emit('support')
              }, [
                h('span', { class: 'w-9 h-9 rounded-full flex items-center justify-center shrink-0', style: { background: '#006600' } }, [
                  h('span', { class: 'font-bold text-base text-white' }, '$')
                ]),
                h('div', {}, [
                  h('p', { class: 'font-semibold text-gray-900 text-[15px]' }, 'Support'),
                  h('p', { class: 'text-xs text-gray-400' }, 'Make a contribution')
                ])
              ]),
              (props.isCurrentUserLead && userId > 0) && h('button', {
                class: 'w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left',
                onClick: () => emit('add-goal')
              }, [
                h('span', { class: 'w-9 h-9 rounded-full flex items-center justify-center shrink-0', style: { background: '#8cc65d' } }, [
                  h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'h-5 w-5 text-white', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', strokeWidth: 2 }, [
                    h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M12 4v16m8-8H4' })
                  ])
                ]),
                h('div', {}, [
                  h('p', { class: 'font-semibold text-gray-900 text-[15px]' }, 'Add Goal'),
                  h('p', { class: 'text-xs text-gray-400' }, 'Create a new goal')
                ])
              ]),
              h('button', {
                class: 'w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left',
                onClick: () => emit('join-goal-team')
              }, [
                h('span', { class: 'w-9 h-9 rounded-full flex items-center justify-center shrink-0', style: { background: '#8cc65d' } }, [
                  h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'h-5 w-5 text-white', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', strokeWidth: 2 }, [
                    h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z' })
                  ])
                ]),
                h('div', {}, [
                  h('p', { class: 'font-semibold text-gray-900 text-[15px]' }, 'Join Team'),
                  h('p', { class: 'text-xs text-gray-400' }, 'Join a goal team')
                ])
              ]),
              h('button', {
                class: 'w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left',
                onClick: () => emit('share')
              }, [
                h('span', { class: 'w-9 h-9 rounded-full flex items-center justify-center shrink-0', style: { background: '#8cc65d' } }, [
                  h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'h-5 w-5 text-white', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', strokeWidth: 2 }, [
                    h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z' })
                  ])
                ]),
                h('div', {}, [
                  h('p', { class: 'font-semibold text-gray-900 text-[15px]' }, 'Share'),
                  h('p', { class: 'text-xs text-gray-400' }, 'Share this portal')
                ])
              ]),
              (props.portal?.users_id === userId && userId > 0) && h('button', {
                class: 'w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left',
                onClick: () => emit('edit-purpose')
              }, [
                h('span', { class: 'w-9 h-9 rounded-full flex items-center justify-center shrink-0', style: { background: '#8cc65d' } }, [
                  h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'h-5 w-5 text-white', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', strokeWidth: 2 }, [
                    h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z' })
                  ])
                ]),
                h('div', {}, [
                  h('p', { class: 'font-semibold text-gray-900 text-[15px]' }, 'Edit Purpose'),
                  h('p', { class: 'text-xs text-gray-400' }, 'Modify portal settings')
                ])
              ]),
              userId > 0 && h('button', {
                class: 'w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left',
                onClick: () => emit('flag')
              }, [
                h('span', { class: 'w-9 h-9 rounded-full flex items-center justify-center shrink-0', style: { background: '#dc2626' } }, [
                  h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'h-5 w-5 text-white', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', strokeWidth: 2 }, [
                    h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9' })
                  ])
                ]),
                h('div', {}, [
                  h('p', { class: 'font-semibold text-gray-900 text-[15px]' }, 'Flag as Inappropriate'),
                  h('p', { class: 'text-xs text-gray-400' }, 'Report this portal')
                ])
              ])
            ]),
            h('div', { class: 'border-t border-gray-100 px-2 py-2' }, [
              h('button', {
                class: 'w-full px-4 py-2.5 rounded-xl text-sm text-gray-500 hover:bg-gray-50 transition-colors text-center',
                onClick: () => emit('close')
              }, 'Cancel')
            ])
          ])
        ]);
      }

      return h('div', {
        class: 'fixed inset-0 z-40 flex items-end justify-center',
        onClick: () => emit('close')
      }, [
        h('div', {
          class: 'bg-black bg-opacity-50 w-full',
          style: {
            maxWidth: '768px',
            position: 'absolute',
            top: '0',
            bottom: '0',
            left: '50%',
            transform: 'translateX(-50%)'
          }
        }),
        h('div', {
          class: 'bg-white w-full rounded-t-2xl p-6 relative z-10',
          style: { maxHeight: '80vh', overflowY: 'auto', maxWidth: '768px' },
          onClick: (e: Event) => e.stopPropagation()
        }, [
          h('div', { class: 'flex flex-col items-center space-y-6' }, [
            props.supportGoal && h('button', {
              class: 'py-3',
              onClick: () => emit('support')
            }, [
              h('div', { class: 'flex items-center space-x-2' }, [
                h('span', {
                  class: 'font-bold text-[28px]',
                  style: { color: '#006600' }
                }, '$'),
                h('span', {
                  class: 'font-bold text-[28px]',
                  style: { color: '#006600' }
                }, 'Support')
              ])
            ]),
            (props.isCurrentUserLead && userId > 0) && h('button', {
              class: 'text-[#8cc65d] font-bold text-[28px] py-3',
              onClick: () => emit('add-goal')
            }, 'Add Goal'),
            h('button', {
              class: 'font-bold text-[28px] py-3',
              style: { color: '#006600' },
              onClick: () => emit('join-goal-team')
            }, 'Join Team'),
            h('button', {
              class: 'text-[#8cc65d] font-bold text-[28px] py-3',
              onClick: () => emit('share')
            }, 'Share'),
            (props.portal?.users_id === userId && userId > 0) && h('button', {
              class: 'text-[#8cc65d] font-bold text-[28px] py-3',
              onClick: () => emit('edit-purpose')
            }, 'Edit Purpose'),
            userId > 0 && h('button', {
              class: 'text-red-600 text-[16px] py-3',
              onClick: () => emit('flag')
            }, 'Flag as Inappropriate'),
            h('button', {
              class: 'w-full text-center text-gray-500 text-[16px] py-3 mt-4',
              onClick: () => emit('close')
            }, 'Cancel')
          ])
        ])
      ]);
    };
  }
});

const GoalPickerRow = defineComponent({
  props: {
    goal: Object as () => Goal,
    currentUserId: Number,
  },
  emits: ['join', 'view-details'],
  setup(props, { emit }) {
    const isCreator = computed(() => props.goal?.creatorId === props.currentUserId);

    const tagText = computed(() => {
      if (!props.goal) return '';
      if (props.goal.typeName.toLowerCase() === 'other') {
        const raw = (props.goal.metricName || '').trim();
        return raw ? raw.substring(0, 9) : props.goal.typeName;
      }
      return props.goal.typeName;
    });

    return () => {
      if (!props.goal) return null;

      return h('div', {
        class: 'flex items-center gap-4 p-4 hover:bg-gray-50',
      }, [
        h('div', { class: 'flex items-end gap-1.5 shrink-0', style: { width: '126px', height: '81px' } },
          (props.goal.chartData || []).slice(-4).map((bar: any, idx: number) => {
            const quota = (props.goal?.quota || 0) > 0 ? props.goal!.quota! : 1;
            const barHeight = Math.max(0, Math.min(1.0, (bar.value || 0) / quota) * 77);
            return h('div', {
              key: `bar-${idx}`,
              class: 'flex flex-col justify-end',
              style: { width: '24px', height: '81px' }
            }, [
              h('div', {
                class: 'rounded',
                style: { backgroundColor: '#8cc65d', width: '24px', height: `${barHeight}px` }
              })
            ]);
          })
        ),

        h('button', {
          class: 'flex-1 min-w-0 text-left',
          onClick: () => emit('view-details')
        }, [
          h('div', { class: 'flex items-center gap-1 font-semibold text-base', style: { color: '#006600' } }, [
            h('span', {}, props.goal.title),
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-3.5 w-3.5 shrink-0',
              fill: 'none',
              viewBox: '0 0 24 24',
              stroke: 'currentColor',
              strokeWidth: 2.5
            }, [
              h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M9 5l7 7-7 7' })
            ])
          ]),
          props.goal.subtitle && h('div', { class: 'text-sm text-gray-600' }, props.goal.subtitle),
          h('div', { class: 'text-sm text-black' }, `${Math.floor(props.goal.progressPercent || 0)}% [${tagText.value}]`)
        ]),

        h('div', { class: 'flex flex-col gap-1 shrink-0' }, [
          !isCreator.value
            ? h('button', {
                class: 'flex items-center gap-1.5 px-4 py-2.5 rounded-lg text-white font-semibold text-base',
                style: { backgroundColor: '#8cc65d' },
                onClick: () => emit('join')
              }, [
                h('svg', {
                  xmlns: 'http://www.w3.org/2000/svg',
                  class: 'h-4 w-4',
                  fill: 'none',
                  viewBox: '0 0 24 24',
                  stroke: 'currentColor',
                  strokeWidth: 2
                }, [
                  h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z' })
                ]),
                'Join'
              ])
            : h('div', {
                class: 'flex items-center gap-1 px-2.5 py-1 rounded text-xs font-semibold',
                style: { color: '#8cc65d', backgroundColor: 'rgba(140, 198, 93, 0.1)' }
              }, [
                h('svg', {
                  xmlns: 'http://www.w3.org/2000/svg',
                  class: 'h-3 w-3',
                  fill: 'currentColor',
                  viewBox: '0 0 20 20'
                }, [
                  h('path', {
                    fillRule: 'evenodd',
                    d: 'M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z',
                    clipRule: 'evenodd'
                  })
                ]),
                'Creator'
              ])
        ])
      ]);
    };
  }
});

const GoalPickerSheet = defineComponent({
  props: {
    goals: Array as () => Goal[],
    currentUserId: Number,
  },
  emits: ['close', 'join', 'view-details'],
  setup(props, { emit }) {
    const isDesktop = ref(window.innerWidth >= BREAKPOINTS.DESKTOP);
    const recruitingGoals = computed(() =>
      (props.goals || []).filter(g => g.typeName === 'Recruiting')
    );

    return () => h('div', {
      class: 'fixed inset-0 z-50 flex items-center justify-center',
      onClick: () => emit('close')
    }, [
      h('div', { class: 'bg-black bg-opacity-50 absolute inset-0' }),
      h('div', {
        class: isDesktop.value
          ? 'bg-white w-full max-w-2xl max-h-[80vh] flex flex-col relative z-10 rounded-2xl shadow-2xl overflow-hidden'
          : 'bg-white w-full max-w-2xl h-[90vh] flex flex-col relative z-10 rounded-t-2xl',
        onClick: (e: Event) => e.stopPropagation()
      }, [
        h('div', { class: 'flex items-center justify-between p-4 border-b border-gray-200 shrink-0' }, [
          h('button', {
            class: 'flex items-center gap-1',
            style: { color: '#8cc65d' },
            onClick: () => emit('close')
          }, [
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-5 w-5',
              fill: 'none',
              viewBox: '0 0 24 24',
              stroke: 'currentColor',
              strokeWidth: 2
            }, [
              h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M15 19l-7-7 7-7' })
            ]),
            h('span', {}, 'Back')
          ]),

          h('h2', { class: 'font-semibold text-lg absolute left-1/2 transform -translate-x-1/2' }, 'Join Team'),

          h('button', {
            style: { color: '#8cc65d' },
            onClick: () => emit('close')
          }, [
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-6 w-6',
              fill: 'none',
              viewBox: '0 0 24 24',
              stroke: 'currentColor',
              strokeWidth: 2
            }, [
              h('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: 'M6 18L18 6M6 6l12 12' })
            ])
          ])
        ]),

        h('div', { class: 'flex-1 overflow-y-auto' },
          recruitingGoals.value.length === 0
            ? h('div', { class: 'flex flex-col items-center justify-center h-full text-center px-4' }, [
                h('svg', {
                  xmlns: 'http://www.w3.org/2000/svg',
                  class: 'h-12 w-12 text-gray-400 mb-4',
                  fill: 'none',
                  viewBox: '0 0 24 24',
                  stroke: 'currentColor'
                }, [
                  h('path', {
                    strokeLinecap: 'round',
                    strokeLinejoin: 'round',
                    strokeWidth: 1.5,
                    d: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z'
                  })
                ]),
                h('h3', { class: 'font-semibold text-lg mb-2 text-gray-700' }, 'No Goal Teams Available'),
                h('p', { class: 'text-sm text-gray-500' }, 'Check back later for new opportunities')
              ])
            : h('div', { class: 'divide-y divide-gray-200' },
                recruitingGoals.value.map(goal =>
                  h(GoalPickerRow, {
                    key: goal.id,
                    goal: goal,
                    currentUserId: props.currentUserId,
                    onJoin: () => emit('join', goal.id),
                    onViewDetails: () => emit('view-details', goal)
                  })
                )
              )
        )
      ])
    ]);
  }
});

const FullscreenImageViewer = defineComponent({
  props: {
    images: Array as () => PortalFile[],
    startIndex: Number,
  },
  emits: ['close'],
  setup(props, { emit }) {
    const currentIndex = ref(props.startIndex || 0);
    const scale = ref(1);
    const offset = ref({ x: 0, y: 0 });
    const containerRef = ref<HTMLElement | null>(null);
    const isClosing = ref(false);

    const nextImage = () => {
      if (props.images && props.images.length > 0) {
        resetZoom();
        currentIndex.value = (currentIndex.value + 1) % props.images.length;
      }
    };

    const prevImage = () => {
      if (props.images && props.images.length > 0) {
        resetZoom();
        currentIndex.value = (currentIndex.value - 1 + props.images.length) % props.images.length;
      }
    };

    const resetZoom = () => {
      scale.value = 1;
      offset.value = { x: 0, y: 0 };
    };

    const handleDoubleTap = () => {
      if (scale.value > 1.01) {
        resetZoom();
      } else {
        scale.value = 2.5;
      }
    };

    const transformStyle = computed(() => {
      return `scale(${scale.value}) translate(${offset.value.x}px, ${offset.value.y}px)`;
    });

    const enterFullscreen = async () => {
      if (!containerRef.value) return;
      try {
        if (containerRef.value.requestFullscreen) {
          await containerRef.value.requestFullscreen();
        } else if ((containerRef.value as any).webkitRequestFullscreen) {
          await (containerRef.value as any).webkitRequestFullscreen();
        } else if ((containerRef.value as any).mozRequestFullScreen) {
          await (containerRef.value as any).mozRequestFullScreen();
        } else if ((containerRef.value as any).msRequestFullscreen) {
          await (containerRef.value as any).msRequestFullscreen();
        }
      } catch (err) {
        console.error('Failed to enter fullscreen:', err);
      }
    };

    const exitFullscreen = async () => {
      try {
        if (document.exitFullscreen) {
          await document.exitFullscreen();
        } else if ((document as any).webkitExitFullscreen) {
          await (document as any).webkitExitFullscreen();
        } else if ((document as any).mozCancelFullScreen) {
          await (document as any).mozCancelFullScreen();
        } else if ((document as any).msExitFullscreen) {
          await (document as any).msExitFullscreen();
        }
      } catch (err) {
        console.error('Failed to exit fullscreen:', err);
      }
    };

    const handleClose = async () => {
      if (isClosing.value) return;
      isClosing.value = true;
      await exitFullscreen();
      setTimeout(() => { emit('close'); }, 100);
    };

    const handleFullscreenChange = () => {
      if (isClosing.value) return;
      const isCurrentlyFullscreen = !!(
        document.fullscreenElement ||
        (document as any).webkitFullscreenElement ||
        (document as any).mozFullScreenElement ||
        (document as any).msFullscreenElement
      );
      if (!isCurrentlyFullscreen) {
        isClosing.value = true;
        emit('close');
      }
    };

    onMounted(() => {
      enterFullscreen();
      document.addEventListener('fullscreenchange', handleFullscreenChange);
      document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
      document.addEventListener('mozfullscreenchange', handleFullscreenChange);
      document.addEventListener('msfullscreenchange', handleFullscreenChange);
    });

    onBeforeUnmount(() => {
      exitFullscreen();
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
      document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
      document.removeEventListener('mozfullscreenchange', handleFullscreenChange);
      document.removeEventListener('msfullscreenchange', handleFullscreenChange);
    });

    return () => h('div', {
      ref: containerRef,
      class: 'fixed inset-0 bg-black z-50',
      style: {
        height: '100dvh',
        width: '100vw',
        userSelect: 'none',
        WebkitUserSelect: 'none',
        MozUserSelect: 'none',
        msUserSelect: 'none'
      }
    }, [
      h('div', { class: 'absolute inset-0 overflow-hidden' }, [
        h('div', {
          class: 'absolute inset-0 flex items-center justify-center',
          onDblclick: handleDoubleTap
        }, [
          h('img', {
            src: props.images?.[currentIndex.value]?.url,
            class: 'w-full h-full object-contain',
            style: {
              transform: transformStyle.value,
              transition: 'transform 0.15s ease-out',
              objectPosition: 'center'
            }
          })
        ]),

        h('button', {
          class: 'absolute top-4 right-4 bg-black bg-opacity-50 rounded-full p-2 z-10',
          onClick: handleClose,
          onMousedown: (e: MouseEvent) => e.preventDefault()
        }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-6 w-6 text-white',
            fill: 'none',
            viewBox: '0 0 24 24',
            stroke: 'currentColor',
            'stroke-width': '2'
          }, [
            h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M6 18L18 6M6 6l12 12' })
          ])
        ]),

        (props.images?.length || 0) > 1 && [
          h('button', {
            key: 'prev',
            class: 'absolute left-4 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-50 rounded-full p-2 z-10',
            onClick: prevImage,
            onMousedown: (e: MouseEvent) => e.preventDefault()
          }, [
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-8 w-8 text-white',
              fill: 'none',
              viewBox: '0 0 24 24',
              stroke: 'currentColor'
            }, [
              h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M15 19l-7-7 7-7' })
            ])
          ]),
          h('button', {
            key: 'next',
            class: 'absolute right-4 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-50 rounded-full p-2 z-10',
            onClick: nextImage,
            onMousedown: (e: MouseEvent) => e.preventDefault()
          }, [
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-8 w-8 text-white',
              fill: 'none',
              viewBox: '0 0 24 24',
              stroke: 'currentColor'
            }, [
              h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5l7 7-7 7' })
            ])
          ])
        ]
      ])
    ]);
  }
});
</script>

<style scoped>
.portal-page-container {
  width: 100%;
}

@media (min-width: 1024px) {
  .portal-page-container {
    width: 100vw;
    max-width: 100vw;
    margin-left: calc(-50vw + 50%);
  }
}

.story-link {
  color: #2563eb !important;
  text-decoration: underline !important;
  cursor: pointer !important;
}

.story-link:hover {
  color: #1d4ed8 !important;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
