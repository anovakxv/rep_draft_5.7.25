<!--
  PortalPage.vue
  Rep

  Created by Adam Novak on 09.10.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
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
      <PortalHeader :portal-name="portalDetail.name" @back="goBack" />

      <!-- Two Column Layout (Desktop Only) -->
      <div class="flex flex-col flex-1 min-h-0 xl:flex-row">
        <!-- DESKTOP: Left Column - Image Gallery (70% width, full screen height) -->
        <div class="hidden xl:flex xl:w-[70%] xl:h-[calc(100vh-3.5rem)] xl:sticky xl:top-[3.5rem] xl:flex-col xl:bg-black" style="border: 12px solid black;">
          <ImageTabView
            :sections="portalDetail.aSections || []"
            @image-tap="openFullscreen"
            :desktop-mode="true"
          />
        </div>

        <!-- MOBILE & DESKTOP: Right Column - Content (30% on desktop) -->
        <div class="flex flex-col flex-1 min-h-0 xl:w-[30%]">

        <!-- 2. Main Scrollable Content -->
        <div class="flex-1 overflow-y-auto overflow-x-hidden pb-20 xl:pb-0" style="overscroll-behavior-y: contain;">
          <div class="relative">
            <!-- MOBILE ONLY: Image Gallery -->
            <div class="xl:hidden">
              <ImageTabView
                :sections="portalDetail.aSections || []"
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
            <div class="px-4 pt-4 pb-24 xl:pb-4">
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

        <!-- Floating RSVP Button (only show if Attendees goal exists) -->
        <div
          v-if="attendeesGoal"
          class="fixed bottom-16 left-0 right-0 z-10 flex justify-center px-4 xl:sticky xl:bottom-20"
        >
          <button
            @click="handleRSVP"
            class="w-full max-w-md h-12 xl:h-14 rounded-xl font-bold text-lg xl:text-xl shadow-lg transition-transform hover:scale-105 active:scale-95"
            style="background-color: #8cc65d; color: white;"
          >
            Register for Event
          </button>
        </div>

        <!-- Floating Join Supporters Button (only show if Supporters goal exists AND no Attendees goal) -->
        <div
          v-if="supportersGoal && !attendeesGoal"
          class="fixed bottom-16 left-0 right-0 z-10 flex justify-center px-4 xl:sticky xl:bottom-20"
        >
          <button
            @click="handleJoinSupporters"
            class="w-full max-w-md h-12 xl:h-14 rounded-xl font-bold text-lg xl:text-xl shadow-lg transition-transform hover:scale-105 active:scale-95"
            style="background-color: #8cc65d; color: white;"
          >
            Join Supporters
          </button>
        </div>

        <!-- Fixed Bottom Bar (mobile) / Sticky Bottom Bar (desktop) -->
        <div class="fixed bottom-0 left-0 right-0 z-20 flex justify-center xl:sticky xl:bottom-0 xl:left-auto xl:right-auto xl:mt-auto">
          <div class="w-full bg-white border-t shadow-lg flex items-center justify-center gap-3 py-1.5 px-4 xl:py-3" style="max-width: 768px; border-color: #e5e7eb;">
            <!-- Message Button -->
            <button
              @click="openMessageSheet"
              class="flex-1 flex items-center justify-center h-10 rounded-lg border-2 transition-transform hover:scale-105 active:scale-95"
              style="border-color: #8cc65d; color: #8cc65d; background-color: white;"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
              </svg>
            </button>

            <!-- Add Button -->
            <button
              @click="handleAddAction"
              class="flex-1 flex items-center justify-center h-10 rounded-lg transition-transform hover:scale-105 active:scale-95"
              style="background-color: #8cc65d; color: white;"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24">
                <circle cx="5" cy="12" r="2.5"/>
                <circle cx="12" cy="12" r="2.5"/>
                <circle cx="19" cy="12" r="2.5"/>
              </svg>
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
        :images="(portalDetail?.aSections || []).flatMap(s => s.aFiles)"
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

// Define component name for keep-alive
defineOptions({
  name: 'PortalPage'
});
import api from '@/pages/utils/api';
import { isAuthenticated } from '@/utils/auth';
// Lazy load EditGoal to prevent Tailwind @apply errors from blocking page load
const EditGoal = defineAsyncComponent(() => import('../GoalPages/EditGoal.vue'));
import PayTransaction from './PayTransaction.vue';
import { BREAKPOINTS } from '@/constants/breakpoints';
import { shareUrl } from '@/utils/share';

// --- Interfaces (from Swift Models) ---
interface User { 
  id: number;
  fname?: string;
  lname?: string;
  profile_picture_url?: string;  // Backend returns snake_case
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
  // Other goal fields would be defined here
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
}

interface ReportingIncrement { 
  id: number;
  name: string;
}

// --- Orientation Detection (similar to OrientationObserver in Swift) ---
const isLandscape = ref(window.innerWidth > window.innerHeight);

const updateOrientation = () => {
  isLandscape.value = window.innerWidth > window.innerHeight;
  
  // Auto-open fullscreen in landscape mode, if not already open
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

// --- State (from ViewModel & View) ---
const portalDetail = ref<PortalDetail | null>(null);
const portalGoals = ref<Goal[]>([]);
const reportingIncrements = ref<ReportingIncrement[]>([]);
const selectedSection = ref(0); // 0: Goal Teams, 1: Story
const isLoading = ref(true);
const errorMessage = ref<string | null>(null);

// Modal/Sheet State
type ActiveSheet = 'portalActionMenu' | 'addGoal' | 'goalPicker' | null;
const activeSheet = ref<ActiveSheet>(null);
const showPaymentSheet = ref(false);
const navigateToEditAfterDismiss = ref(false);
const showEditPortal = ref(false);

// Flagging State
const showFlagConfirmation = ref(false);
const flagResultMessage = ref<string | null>(null);

// Fullscreen Image Viewer State
const isFullscreenOpen = ref(false);
const fullscreenStartIndex = ref(0);

// --- Computed Properties (matching Swift logic exactly) ---
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
  // Find the portal creator from aUsers using users_id
  const creatorId = portalDetail.value?.users_id;
  if (!creatorId) return null;
  return portalDetail.value?.aUsers?.find(u => u.id === creatorId) ?? null;
});

// Find "Attendees" goal for RSVP button
const attendeesGoal = computed(() => {
  return portalGoals.value.find(g =>
    g.typeName === 'Recruiting' &&
    (g.title?.toLowerCase() === 'attendees' || g.title?.toLowerCase().includes('attendee'))
  );
});

// Find "Supporters" goal for Join Supporters button
const supportersGoal = computed(() => {
  return portalGoals.value.find(g =>
    g.typeName === 'Recruiting' &&
    (g.title?.toLowerCase() === 'supporters' || g.title?.toLowerCase().includes('supporter'))
  );
});

// --- API Methods (from ViewModel) ---
const fetchPortalDetail = async () => {
  isLoading.value = true;
  errorMessage.value = null;
  const authenticated = isAuthenticated();

  try {
    let res;

    // Use public endpoint for unauthenticated users
    if (!authenticated) {
      res = await api.get(`/api/public/portal/${portalId}`);
    } else {
      res = await api.get(`/api/portal/details?portals_id=${portalId}&user_id=${userId}`);
    }

    if (res.data && res.data.result) {
      portalDetail.value = res.data.result;
      console.log("Portal aLeads:", portalDetail.value?.aLeads?.map(l => l.id) || []);

      // For public users, use goals from portal detail response (now includes proper chartData from backend fix)
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

  // Skip for unauthenticated users - they already have goals from portal detail response
  if (!authenticated) {
    return;
  }

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
    // Backend route: /api/reporting_increments/list (matches Swift iOS app)
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

// Join goal team function (matching iOS implementation)
const joinGoalTeam = async (goalId: number) => {
  const res = await api.post('/api/goals/join_leave', {
    aGoalsIDs: [goalId],
    todo: 'join'
  });

  if (res.data && res.data.result && res.data.result[goalId] === 'ok') {
    // Success - refresh portal goals
    await fetchPortalGoals();
    return true;
  } else if (res.data && res.data.result && res.data.result[goalId] === 'Already a member') {
    // User already registered - treat as success
    await fetchPortalGoals();
    return true;
  } else {
    console.error('Error joining goal team:', res.data);
    throw new Error('Failed to join goal team');
  }
};

// RSVP button handler
const handleRSVP = async () => {
  if (!attendeesGoal.value) return;

  if (isAuthenticated()) {
    // User is logged in - join immediately
    try {
      await joinGoalTeam(attendeesGoal.value.id);
      alert('✓ You\'re registered for this event!');
    } catch (err) {
      console.error('RSVP failed:', err);
      alert('Failed to register. Please try again.');
    }
  } else {
    // User not logged in - store RSVP intent and redirect to registration
    localStorage.setItem('rsvpIntent', JSON.stringify({
      portalId: portalId,
      goalId: attendeesGoal.value.id,
      goalTitle: attendeesGoal.value.title,
      isEventRegistration: true  // Flag to streamline onboarding
    }));
    router.push({
      path: '/register',
      query: { returnTo: `/portal/${portalId}` }
    });
  }
};

// Join Supporters button handler
const handleJoinSupporters = async () => {
  if (!supportersGoal.value) return;

  if (isAuthenticated()) {
    // User is logged in - join immediately
    try {
      await joinGoalTeam(supportersGoal.value.id);
      alert('✓ You\'ve joined the Supporters team!');
    } catch (err) {
      console.error('Join Supporters failed:', err);
      alert('Failed to join. Please try again.');
    }
  } else {
    // User not logged in - store join intent and redirect to registration
    localStorage.setItem('rsvpIntent', JSON.stringify({
      portalId: portalId,
      goalId: supportersGoal.value.id,
      goalTitle: supportersGoal.value.title,
      isEventRegistration: true  // Use streamlined onboarding
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
    // Always route to main screen for users without a specific fromTab
    // This handles external arrivals (like event registration links) properly
    router.push('/main');
  }
};

const handleAddAction = () => {
  // Allow public users to access the action menu (to use "Support" button)
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
    // Navigate to chat with the lead user
    router.push(`/chat/user/${leadRepUser.value.id}`);
  } else {
    console.log("No lead user found for portal!");
  }
};

// Updated to match Swift logic exactly - dismiss action sheet first, then show payment
const openPaymentSheet = () => {
  activeSheet.value = null; // Dismiss the action menu first
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
  // Refresh portal goals after creating a new one
  fetchPortalGoals();
};

// --- Lifecycle Hooks ---
onMounted(async () => {
  // Allow public users to view portal page
  // Authentication is checked on protected actions (Message, Add)

  // Fetch portal data
  await fetchPortalDetail();
  await fetchPortalGoals();

  // Only fetch reporting increments if authenticated (needed for creating goals)
  if (isAuthenticated()) {
    fetchReportingIncrements();
  }

  // Check for RSVP intent after registration
  const rsvpIntentStr = localStorage.getItem('rsvpIntent');
  if (rsvpIntentStr && isAuthenticated()) {
    try {
      const rsvpIntent = JSON.parse(rsvpIntentStr);
      if (rsvpIntent.portalId === portalId && rsvpIntent.goalId) {
        // Auto-join the goal
        const success = await joinGoalTeam(rsvpIntent.goalId);
        if (success) {
          // Clear the intent only on success
          localStorage.removeItem('rsvpIntent');
          console.log('Auto-joined goal after registration:', rsvpIntent.goalTitle);
          // Show appropriate success message based on goal type
          const goalTitle = (rsvpIntent.goalTitle || '').toLowerCase();
          if (goalTitle.includes('supporter')) {
            alert('✓ You\'ve joined the Supporters team!');
          } else {
            alert('✓ You\'re Registered!');
          }
        } else {
          console.error('Failed to auto-join goal team');
          // Don't clear rsvpIntent - user can try again
        }
      }
    } catch (err) {
      console.error('Failed to process RSVP intent:', err);
      // Only clear if JSON parse failed (corrupted data)
      if (err instanceof SyntaxError) {
        localStorage.removeItem('rsvpIntent');
      }
      // Don't clear for API errors - user can try again
    }
  }

  // Set up orientation detection
  window.addEventListener('resize', updateOrientation);
  window.addEventListener('orientationchange', updateOrientation);

  // Set up event bus for toolbar actions (similar to NotificationCenter)
  document.addEventListener('ShowEditPortalFromToolbar', () => {
    showEditPortal.value = true;
  });
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', updateOrientation);
  window.removeEventListener('orientationchange', updateOrientation);
  document.removeEventListener('ShowEditPortalFromToolbar', () => {});
});

// Watch for navigateToEditAfterDismiss changes
watch(navigateToEditAfterDismiss, (newVal) => {
  if (newVal && !activeSheet.value) {
    showEditPortal.value = true;
    navigateToEditAfterDismiss.value = false;
  }
});

// Watch for showEditPortal changes to trigger navigation
watch(showEditPortal, (newVal) => {
  if (newVal && portalDetail.value) {
    router.push(`/portal/edit/${portalId}`);
  }
});

// Watch for portalGoals changes - this matches the Swift onChange(of: viewModel.portalGoals) logic
watch(portalGoals, () => {
  console.log("Portal goals updated, supportGoal:", supportGoal.value);
}, { immediate: true });

// --- Inline Child Components ---

const PortalHeader = defineComponent({
  props: { portalName: String },
  emits: ['back'],
  setup(props, { emit }) {
    return () => h('header', {
      class: 'flex items-center h-14 px-4 border-b border-gray-200 shrink-0',
      style: 'background-color: #f7f7f7'
    }, [
      h('button', {
        onClick: () => emit('back'),
        style: 'color: #8cc65d'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-6 w-6',
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
        class: 'flex-1 text-center font-bold text-xl' 
      }, props.portalName),
      h('div', { 
        class: 'w-12' 
      }) // Spacer for symmetry
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

    // Desktop: full height with black background, Mobile: 16:9 aspect ratio with gray background
    const containerClass = props.desktopMode
      ? 'relative w-full h-full bg-black overflow-hidden flex items-center justify-center'
      : 'relative w-full aspect-[16/9] bg-gray-200 overflow-hidden';

    return () => h('div', {
      class: containerClass,
      style: {
        userSelect: 'none', // Prevent text/content selection
        WebkitUserSelect: 'none', // Safari
        MozUserSelect: 'none', // Firefox
        msUserSelect: 'none' // IE/Edge
      }
    }, [
      // Main image display
      images.value.length > 0
        ? h('img', {
            src: images.value[currentImageIndex.value]?.url || '/placeholder-image.png',
            class: props.desktopMode
              ? 'w-full h-full object-contain cursor-pointer'
              : 'w-full h-full object-cover cursor-pointer',
            onClick: () => emit('image-tap', currentImageIndex.value)
          })
        : h('div', { 
            class: 'flex items-center justify-center h-full text-gray-500' 
          }, 'No Images'),
      
      // Pagination dots
      images.value.length > 1 && h('div', {
        class: 'absolute bottom-2 left-0 right-0 flex justify-center space-x-2'
      }, images.value.map((_, idx) => 
        h('div', { 
          key: idx,
          class: `w-2 h-2 rounded-full ${idx === currentImageIndex.value ? 'bg-white' : 'bg-gray-400'}` 
        })
      )),
      
      // Navigation arrows (if multiple images)
      images.value.length > 1 && [
        h('button', {
          key: 'prev',
          class: 'absolute left-2 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-1',
          onClick: prevImage,
          onMousedown: (e: MouseEvent) => e.preventDefault() // Prevent selection on click
        }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-6 w-6 text-white',
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
        h('button', {
          key: 'next',
          class: 'absolute right-2 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-1',
          onClick: nextImage,
          onMousedown: (e: MouseEvent) => e.preventDefault() // Prevent selection on click
        }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-6 w-6 text-white',
            fill: 'none',
            viewBox: '0 0 24 24',
            stroke: 'currentColor'
          }, [
            h('path', {
              'stroke-linecap': 'round',
              'stroke-linejoin': 'round',
              'stroke-width': '2',
              d: 'M9 5l7 7-7 7'
            })
          ])
        ])
      ]
    ]);
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
      // Compute tag text (matching iOS logic)
      const tagText = goal.typeName.toLowerCase() === 'other'
        ? (goal.metricName?.trim() || goal.typeName).substring(0, 9)
        : goal.typeName;

      // Get last 4 chart data points
      const chartBars = (goal.chartData || []).slice(-4);

      return h('div', {
        class: 'flex items-center gap-4 py-1 px-4 bg-white hover:bg-gray-50 transition',
        style: { height: '89px' } // 81px + 8px padding
      }, [
        // Mini bar chart (left side)
        h('div', {
          class: 'flex items-end gap-[6px]',
          style: { width: '114px', height: '81px' } // 4*24 + 3*6 = 114px width
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

        // Text content (right side)
        h('div', { class: 'flex-1 flex flex-col justify-center gap-1' }, [
          // Title
          h('h3', { class: 'font-semibold text-[17px] leading-tight' }, goal.title),

          // Subtitle (if exists)
          goal.subtitle && goal.subtitle.trim()
            ? h('p', { class: 'text-[15px] text-gray-600 leading-tight' }, goal.subtitle)
            : null,

          // Progress percentage with tag
          h('p', { class: 'text-[15px] text-black' }, `${Math.round(goal.progressPercent || (goal.progress * 100))}% [${tagText}]`)
        ].filter(Boolean))
      ]);
    };
    
    // Sort goals to put Supporters goal first
    const sortedGoals = computed(() => {
      if (!props.goals || props.goals.length === 0) return [];
      if (!props.supportersGoal) return props.goals;

      // Separate Supporters goal and other goals
      const supportersGoal = props.goals.find(g => g.id === props.supportersGoal!.id);
      const otherGoals = props.goals.filter(g => g.id !== props.supportersGoal!.id);

      // Put Supporters goal first
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
            // Extra bottom padding to allow scrolling past floating buttons
            h('div', { key: 'bottom-spacer', style: { height: '80px' } })
          ]
        : h('p', { class: 'text-gray-500 py-8 text-center' }, 'No goals for this portal yet.')
    ]);
  }
});

const PortalStorySection = defineComponent({
  props: { portal: Object as () => PortalDetail | null },
  setup(props) {
    const storyTexts = computed(() =>
      (props.portal?.aTexts || [])
        .filter(t => (t.section || '') === 'story')
        .sort((a, b) => (a.position ?? 0) - (b.position ?? 0))
    );

    // Gallery sections (non-Main Section) for display
    const gallerySections = computed(() =>
      (props.portal?.aSections || [])
        .filter(s => s.title !== 'Main Section' && s.aFiles && s.aFiles.length > 0)
        .sort((a: any, b: any) => (a.position || 0) - (b.position || 0))
    );

    // Fullscreen viewer state
    const fullscreenImages = ref<PortalFile[]>([]);
    const fullscreenIndex = ref(0);
    const showFullscreen = ref(false);

    const openGalleryFullscreen = (section: PortalSection, imgIndex: number) => {
      fullscreenImages.value = section.aFiles;
      fullscreenIndex.value = imgIndex;
      showFullscreen.value = true;
    };

    const closeFullscreen = () => {
      showFullscreen.value = false;
    };

    const fullscreenPrev = () => {
      if (fullscreenIndex.value > 0) fullscreenIndex.value--;
    };

    const fullscreenNext = () => {
      if (fullscreenIndex.value < fullscreenImages.value.length - 1) fullscreenIndex.value++;
    };

    // Helper function to linkify a single line of text (matching iOS NSDataDetector behavior)
    const linkifyLine = (line: string) => {
      // Regex to detect URLs: http://, https://, or www.
      const urlRegex = /(https?:\/\/[^\s]+)|(www\.[^\s]+)/gi;
      const parts: any[] = [];
      let lastIndex = 0;
      let match;

      // Reset regex state
      urlRegex.lastIndex = 0;

      while ((match = urlRegex.exec(line)) !== null) {
        // Add text before the URL as a text node
        if (match.index > lastIndex) {
          parts.push(line.substring(lastIndex, match.index));
        }

        // Add the URL as a link VNode
        const urlText = match[0];
        const fullUrl = urlText.startsWith('www.') ? `https://${urlText}` : urlText;
        parts.push(
          h('a', {
            href: fullUrl,
            target: '_blank',
            rel: 'noopener noreferrer',
            class: 'story-link',
            style: {
              color: '#2563eb',
              textDecoration: 'underline',
              cursor: 'pointer'
            },
            onClick: (e: MouseEvent) => {
              e.preventDefault();
              window.open(fullUrl, '_blank', 'noopener,noreferrer');
            }
          }, urlText)
        );

        lastIndex = match.index + urlText.length;
      }

      // Add remaining text after last URL
      if (lastIndex < line.length) {
        parts.push(line.substring(lastIndex));
      }

      // If no URLs found, return the original line as text
      return parts.length > 0 ? parts : [line];
    };

    // Helper to render text with clickable links and preserved newlines
    const renderLinkableText = (text: string) => {
      if (!text) return [];

      // Split by newlines to preserve line breaks
      const lines = text.split('\n');
      const result: any[] = [];

      lines.forEach((line, lineIndex) => {
        // Process each line for URLs
        const lineParts = linkifyLine(line);
        result.push(...lineParts);

        // Add line break after each line except the last one
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

      // Gallery Sections — horizontal scrollable image strips
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

      // Fullscreen image viewer overlay
      showFullscreen.value && h('div', {
        class: 'fixed inset-0 z-50 bg-black flex flex-col items-center justify-center',
        onClick: closeFullscreen
      }, [
        // Close button
        h('button', {
          class: 'absolute top-4 right-4 z-10 text-white text-3xl font-light w-10 h-10 flex items-center justify-center',
          onClick: (e: Event) => { e.stopPropagation(); closeFullscreen(); }
        }, '\u00D7'),

        // Previous arrow
        fullscreenIndex.value > 0 && h('button', {
          class: 'absolute left-3 top-1/2 -translate-y-1/2 z-10 text-white text-4xl font-light w-12 h-12 flex items-center justify-center rounded-full bg-black bg-opacity-40 hover:bg-opacity-60 transition-colors',
          onClick: (e: Event) => { e.stopPropagation(); fullscreenPrev(); }
        }, '\u2039'),

        // Next arrow
        fullscreenIndex.value < fullscreenImages.value.length - 1 && h('button', {
          class: 'absolute right-3 top-1/2 -translate-y-1/2 z-10 text-white text-4xl font-light w-12 h-12 flex items-center justify-center rounded-full bg-black bg-opacity-40 hover:bg-opacity-60 transition-colors',
          onClick: (e: Event) => { e.stopPropagation(); fullscreenNext(); }
        }, '\u203A'),

        // Image
        h('img', {
          src: fullscreenImages.value[fullscreenIndex.value]?.url || '',
          class: 'max-w-full max-h-[85vh] object-contain select-none',
          style: { pointerEvents: 'none' },
          draggable: false
        }),

        // Dot indicators
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

        // Counter text
        h('div', {
          class: 'absolute bottom-14 text-white text-sm opacity-70'
        }, `${fullscreenIndex.value + 1} / ${fullscreenImages.value.length}`)
      ])
    ]);
  }
});

// BottomBarView removed - replaced with floating action buttons

// ActionSheetModal - EXACTLY matching Swift design with iOS styling
const ActionSheetModal = defineComponent({
  props: {
    portal: Object as () => PortalDetail | null,
    isCurrentUserLead: Boolean,
    supportGoal: Object as () => Goal | null,
  },
  emits: ['close', 'add-goal', 'edit-purpose', 'flag', 'support', 'share', 'join-goal-team'],
  setup(props, { emit }) {
    const isDesktop = ref(window.innerWidth >= BREAKPOINTS.DESKTOP);

    return () => h('div', {
      class: 'fixed inset-0 z-40 flex items-end justify-center',
      onClick: () => emit('close')
    }, [
      h('div', {
        class: 'bg-black bg-opacity-50 w-full',
        style: {
          maxWidth: isDesktop.value ? '100vw' : '768px',
          position: 'absolute',
          top: '0',
          bottom: '0',
          left: '50%',
          transform: 'translateX(-50%)'
        }
      }),
      h('div', {
        class: 'bg-white w-full rounded-t-2xl p-6 relative z-10',
        style: {
          maxHeight: '80vh',
          overflowY: 'auto',
          maxWidth: isDesktop.value ? '100vw' : '768px'
        },
        onClick: (e: Event) => e.stopPropagation()
      }, [
        h('div', { class: 'flex flex-col items-center space-y-6' }, [
          // "$ Support" button - dark green with dollar sign (iOS style)
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

          // Add Goal - light green, large text (only if current user is lead AND authenticated)
          (props.isCurrentUserLead && userId > 0) && h('button', {
            class: 'text-[#8cc65d] font-bold text-[28px] py-3',
            onClick: () => emit('add-goal')
          }, 'Add Goal'),

          // Join Team - dark green, large text (available for everyone)
          h('button', {
            class: 'font-bold text-[28px] py-3',
            style: { color: '#006600' },
            onClick: () => emit('join-goal-team')
          }, 'Join Team'),

          // Share - light green, large text (available for everyone)
          h('button', {
            class: 'text-[#8cc65d] font-bold text-[28px] py-3',
            onClick: () => emit('share')
          }, 'Share'),

          // Edit Purpose - light green, large text (only if portal owner AND authenticated)
          (props.portal?.users_id === userId && userId > 0) && h('button', {
            class: 'text-[#8cc65d] font-bold text-[28px] py-3',
            onClick: () => emit('edit-purpose')
          }, 'Edit Purpose'),

          // Flag as Inappropriate - red, smaller text (only if authenticated)
          userId > 0 && h('button', {
            class: 'text-red-600 text-[16px] py-3',
            onClick: () => emit('flag')
          }, 'Flag as Inappropriate'),

          // Cancel button - gray, smaller text
          h('button', {
            class: 'w-full text-center text-gray-500 text-[16px] py-3 mt-4',
            onClick: () => emit('close')
          }, 'Cancel')
        ])
      ])
    ]);
  }
});

// GoalPickerRow - Individual goal row in the picker (matching Swift design)
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
        // Bar Chart (matching iOS design)
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
                style: {
                  backgroundColor: '#8cc65d',
                  width: '24px',
                  height: `${barHeight}px`
                }
              })
            ]);
          })
        ),

        // Title, subtitle, progress - clickable to view details
        h('button', {
          class: 'flex-1 min-w-0 text-left',
          onClick: () => emit('view-details')
        }, [
          // Title with chevron (dark green)
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
              h('path', {
                strokeLinecap: 'round',
                strokeLinejoin: 'round',
                d: 'M9 5l7 7-7 7'
              })
            ])
          ]),
          props.goal.subtitle && h('div', { class: 'text-sm text-gray-600' }, props.goal.subtitle),
          h('div', { class: 'text-sm text-black' }, `${Math.floor(props.goal.progressPercent || 0)}% [${tagText.value}]`)
        ]),

        // Action buttons
        h('div', { class: 'flex flex-col gap-1 shrink-0' }, [
          // Join or Creator badge
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
                  h('path', {
                    strokeLinecap: 'round',
                    strokeLinejoin: 'round',
                    d: 'M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z'
                  })
                ]),
                'Join'
              ])
            : h('div', {
                class: 'flex items-center gap-1 px-2.5 py-1 rounded text-xs font-semibold',
                style: {
                  color: '#8cc65d',
                  backgroundColor: 'rgba(140, 198, 93, 0.1)'
                }
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

// GoalPickerSheet - Modal for selecting and joining goals (matching Swift design)
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
      h('div', {
        class: 'bg-black bg-opacity-50 absolute inset-0'
      }),
      h('div', {
        class: 'bg-white w-full max-w-2xl h-[90vh] flex flex-col relative z-10 rounded-t-2xl',
        onClick: (e: Event) => e.stopPropagation()
      }, [
        // Header
        h('div', { class: 'flex items-center justify-between p-4 border-b border-gray-200 shrink-0' }, [
          // Back button
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
              h('path', {
                strokeLinecap: 'round',
                strokeLinejoin: 'round',
                d: 'M15 19l-7-7 7-7'
              })
            ]),
            h('span', {}, 'Back')
          ]),

          // Title
          h('h2', { class: 'font-semibold text-lg absolute left-1/2 transform -translate-x-1/2' }, 'Join Team'),

          // Close button
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
              h('path', {
                strokeLinecap: 'round',
                strokeLinejoin: 'round',
                d: 'M6 18L18 6M6 6l12 12'
              })
            ])
          ])
        ]),

        // Goal List
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

// Fullscreen viewer with proper zoom functionality and true fullscreen support
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

    // Enter browser fullscreen mode
    const enterFullscreen = async () => {
      if (!containerRef.value) return;

      try {
        if (containerRef.value.requestFullscreen) {
          await containerRef.value.requestFullscreen();
        } else if ((containerRef.value as any).webkitRequestFullscreen) {
          // Safari support
          await (containerRef.value as any).webkitRequestFullscreen();
        } else if ((containerRef.value as any).mozRequestFullScreen) {
          // Firefox support
          await (containerRef.value as any).mozRequestFullScreen();
        } else if ((containerRef.value as any).msRequestFullscreen) {
          // IE/Edge support
          await (containerRef.value as any).msRequestFullscreen();
        }
      } catch (err) {
        console.error('Failed to enter fullscreen:', err);
      }
    };

    // Exit browser fullscreen mode
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
      if (isClosing.value) return; // Prevent double-close
      isClosing.value = true;

      // Exit fullscreen first, then close after a small delay to ensure browser processes it
      await exitFullscreen();

      // Small delay to ensure fullscreen has fully exited
      setTimeout(() => {
        emit('close');
      }, 100);
    };

    // Listen for fullscreen changes (ESC key or fullscreen exit)
    const handleFullscreenChange = () => {
      if (isClosing.value) return; // Ignore if we're already closing via X button

      const isCurrentlyFullscreen = !!(
        document.fullscreenElement ||
        (document as any).webkitFullscreenElement ||
        (document as any).mozFullScreenElement ||
        (document as any).msFullscreenElement
      );

      // If we exited fullscreen (user pressed ESC), close the viewer
      if (!isCurrentlyFullscreen) {
        isClosing.value = true;
        emit('close');
      }
    };

    // Enter fullscreen when component mounts
    onMounted(() => {
      enterFullscreen();

      // Listen for fullscreen changes
      document.addEventListener('fullscreenchange', handleFullscreenChange);
      document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
      document.addEventListener('mozfullscreenchange', handleFullscreenChange);
      document.addEventListener('msfullscreenchange', handleFullscreenChange);
    });

    // Clean up fullscreen on unmount
    onBeforeUnmount(() => {
      exitFullscreen();

      // Remove fullscreen change listeners
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
      document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
      document.removeEventListener('mozfullscreenchange', handleFullscreenChange);
      document.removeEventListener('msfullscreenchange', handleFullscreenChange);
    });
    
    return () => h('div', {
      ref: containerRef,
      class: 'fixed inset-0 bg-black z-50',
      style: {
        // Use dynamic viewport height for mobile browsers (handles landscape properly)
        height: '100dvh',
        width: '100vw',
        userSelect: 'none', // Prevent text/content selection
        WebkitUserSelect: 'none', // Safari
        MozUserSelect: 'none', // Firefox
        msUserSelect: 'none' // IE/Edge
      }
    }, [
      // Main image container (fullscreen - no header)
      h('div', {
        class: 'absolute inset-0 overflow-hidden'
      }, [
        // Image with touch handlers - fills entire viewport in landscape
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

        // Close button overlay (top-right)
        h('button', {
          class: 'absolute top-4 right-4 bg-black bg-opacity-50 rounded-full p-2 z-10',
          onClick: handleClose,
          onMousedown: (e: MouseEvent) => e.preventDefault() // Prevent selection on click
        }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-6 w-6 text-white',
            fill: 'none',
            viewBox: '0 0 24 24',
            stroke: 'currentColor',
            'stroke-width': '2'
          }, [
            h('path', {
              'stroke-linecap': 'round',
              'stroke-linejoin': 'round',
              d: 'M6 18L18 6M6 6l12 12'
            })
          ])
        ]),

        // Navigation arrows (if multiple images)
        (props.images?.length || 0) > 1 && [
          h('button', {
            key: 'prev',
            class: 'absolute left-4 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-50 rounded-full p-2 z-10',
            onClick: prevImage,
            onMousedown: (e: MouseEvent) => e.preventDefault() // Prevent selection on click
          }, [
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-8 w-8 text-white',
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
          h('button', {
            key: 'next',
            class: 'absolute right-4 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-50 rounded-full p-2 z-10',
            onClick: nextImage,
            onMousedown: (e: MouseEvent) => e.preventDefault() // Prevent selection on click
          }, [
            h('svg', {
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-8 w-8 text-white',
              fill: 'none',
              viewBox: '0 0 24 24',
              stroke: 'currentColor'
            }, [
              h('path', {
                'stroke-linecap': 'round',
                'stroke-linejoin': 'round',
                'stroke-width': '2',
                d: 'M9 5l7 7-7 7'
              })
            ])
          ])
        ]
      ])
    ]);
  }
});
</script>

<style scoped>
/* Desktop: Make portal page full width, breaking out of App.vue container */
.portal-page-container {
  /* Mobile: stay within container */
  width: 100%;
}

/* Desktop breakpoint - keep in sync with BREAKPOINTS.DESKTOP in @/constants/breakpoints.ts */
@media (min-width: 1280px) {
  .portal-page-container {
    /* Desktop: break out to full viewport width */
    width: 100vw;
    max-width: 100vw;
    margin-left: calc(-50vw + 50%);
  }
}

/* Story section link styling - matching iOS LinkableText */
.story-link {
  color: #2563eb !important;
  text-decoration: underline !important;
  cursor: pointer !important;
}

.story-link:hover {
  color: #1d4ed8 !important;
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>