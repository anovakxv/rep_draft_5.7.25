<!--
  PortalPage.vue
  Rep

  Created by Adam Novak on 09.10.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <div v-if="isLoading && !portalDetail" class="flex items-center justify-center h-full">
      <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full"></div>
    </div>
    <div v-else-if="errorMessage" class="flex items-center justify-center h-full text-red-500 p-4">
      <p>{{ errorMessage }}</p>
    </div>
    <div v-else-if="portalDetail" class="flex flex-col flex-1 min-h-0">
      <!-- 1. Custom Header -->
      <PortalHeader :portal-name="portalDetail.name" @back="goBack" />

      <!-- 2. Main Scrollable Content -->
      <div class="flex-1 overflow-y-auto">
        <div class="relative">
          <!-- Image Gallery -->
          <ImageTabView 
            :sections="portalDetail.aSections || []" 
            @image-tap="openFullscreen" 
          />

          <!-- Sticky Segmented Picker -->
          <div class="sticky top-0 z-10 bg-white">
            <div class="py-2 px-4 border-b border-t border-gray-200">
              <PortalSegmentedPicker 
                :segments="['Goal Teams', 'Story']" 
                v-model="selectedSection" 
              />
            </div>
          </div>

          <!-- Conditional Content -->
          <div class="p-4">
            <PortalResultsSection 
              v-if="selectedSection === 0" 
              :goals="portalGoals" 
            />
            <PortalStorySection 
              v-else-if="selectedSection === 1" 
              :portal="portalDetail" 
            />
          </div>
        </div>
      </div>

      <!-- 3. Bottom Action Bar -->
      <BottomBarView @add="handleAddAction" @message="openMessageSheet" />
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
    <PayTransaction
      v-if="showPaymentSheet && supportGoal"
      :portal-id="portalId"
      :portal-name="portalDetail?.name || 'Portal'"
      :goal-id="supportGoal.id"
      :goal-name="supportGoal.title"
      :transaction-type="supportGoal.typeName === 'Fund' ? 'donation' : 'payment'"
      @close="showPaymentSheet = false"
    />

    <!-- Message Sheet -->
    <transition name="fade">
      <div v-if="showMessageSheet" class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="bg-white w-full h-full max-w-md rounded-lg shadow-lg flex flex-col">
          <div class="flex justify-between items-center p-4 border-b">
            <h2 class="text-xl font-bold">Message {{ selectedLead?.fname }}</h2>
            <button @click="showMessageSheet = false" class="text-gray-400 hover:text-gray-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <div class="flex-1 p-4">
            <p>Messaging interface would be here</p>
          </div>
          <div class="border-t p-4">
            <button @click="showMessageSheet = false" class="w-full py-2 bg-green-600 text-white rounded-lg">
              Close
            </button>
          </div>
        </div>
      </div>
    </transition>

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
import api from '@/pages/utils/api';
import { isAuthenticated } from '@/utils/auth';
// Lazy load EditGoal to prevent Tailwind @apply errors from blocking page load
const EditGoal = defineAsyncComponent(() => import('../GoalPages/EditGoal.vue'));
import PayTransaction from './PayTransaction.vue';

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
type ActiveSheet = 'portalActionMenu' | 'addGoal' | null;
const activeSheet = ref<ActiveSheet>(null);
const showPaymentSheet = ref(false);
const showMessageSheet = ref(false);
const selectedLead = ref<User | null>(null);
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
  return portalGoals.value.find(g => g.typeName === 'Fund' || g.typeName === 'Sales');
});

const isCurrentUserLead = computed(() => {
  return portalDetail.value?.aUsers?.some(u => u.id === userId) ?? false;
});

const reportingIncrementsForEditGoal = computed(() => {
  return reportingIncrements.value.map(ri => ({ id: ri.id, title: ri.name }));
});

const leadRepUser = computed(() => {
  return portalDetail.value?.aLeads?.[0] ?? null;
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

// --- Event Handlers ---
const goBack = () => {
  const fromTab = route.query.from;
  if (fromTab) {
    router.push({ path: '/main', query: { tab: fromTab } });
  } else {
    router.back();
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
      path: '/login',
      query: { returnTo: `/portal/${portalId}` }
    });
    return;
  }
  if (leadRepUser.value) {
    selectedLead.value = leadRepUser.value;
    showMessageSheet.value = true;
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

const handleAddGoalClose = () => {
  activeSheet.value = null;
  // Refresh portal goals after creating a new one
  fetchPortalGoals();
};

// --- Lifecycle Hooks ---
onMounted(() => {
  // Allow public users to view portal page
  // Authentication is checked on protected actions (Message, Add)

  // Fetch portal data
  fetchPortalDetail();
  fetchPortalGoals();

  // Only fetch reporting increments if authenticated (needed for creating goals)
  if (isAuthenticated()) {
    fetchReportingIncrements();
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
      class: 'flex items-center h-14 px-4 bg-gray-50 border-b border-gray-200 shrink-0'
    }, [
      h('button', { 
        onClick: () => emit('back'), 
        class: 'text-green-600'
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
  props: { sections: Array as () => PortalSection[] },
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
    
    return () => h('div', { 
      class: 'relative w-full aspect-[16/9] bg-gray-200 overflow-hidden'
    }, [
      // Main image display
      images.value.length > 0
        ? h('img', {
            src: images.value[currentImageIndex.value]?.url || '/placeholder-image.png',
            class: 'w-full h-full object-cover cursor-pointer',
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
          onClick: prevImage
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
          onClick: nextImage
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
  props: { goals: Array as () => Goal[] },
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
    
    return () => h('div', { class: 'space-y-2' }, [
      (props.goals?.length || 0) > 0
        ? props.goals!.map((goal, index) => [
            h(RouterLink, { 
              key: `link-${index}`,
              to: `/goal/${goal.id}`, 
              class: 'block' 
            }, () => GoalListItem(goal)),
            h('div', { 
              key: `divider-${index}`,
              class: 'border-b border-gray-200' 
            })
          ]).flat()
        : h('p', { class: 'text-gray-500 py-8 text-center' }, 'No goals for this portal yet.')
    ]);
  }
});

const PortalStorySection = defineComponent({
  props: { portal: Object as () => PortalDetail | null },
  setup(props) {
    const storyTexts = computed(() =>
      (props.portal?.aTexts || []).filter(t => (t.section || '') === 'story')
    );

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
      )
    ]);
  }
});

const BottomBarView = defineComponent({
  emits: ['add', 'message'],
  setup(_, { emit }) {
    return () => h('footer', {
      class: 'flex items-center gap-2 py-2 px-4 border-t border-gray-200 bg-white shrink-0'
    }, [
      h('button', {
        onClick: () => emit('add'),
        class: 'flex-1 py-2 px-3 bg-[#8cc65d] border-2 border-[#8cc65d] rounded-lg text-white font-semibold text-[20px] active:bg-[#7ab54d] transition-colors flex items-center justify-center'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-5 w-5',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor',
          'stroke-width': '2.5'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            d: 'M12 4v16m8-8H4'
          })
        ])
      ]),
      h('button', {
        onClick: () => emit('message'),
        class: 'flex-1 py-2 px-3 bg-white border-2 border-[#8cc65d] rounded-lg text-[#8cc65d] font-semibold text-[17px] active:bg-gray-50 transition-colors flex items-center justify-center'
      }, [
        h('svg', {
          xmlns: 'http://www.w3.org/2000/svg',
          class: 'h-5 w-5',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor',
          'stroke-width': '2.5'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            d: 'M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z'
          })
        ])
      ])
    ]);
  }
});

// ActionSheetModal - EXACTLY matching Swift design with iOS styling
const ActionSheetModal = defineComponent({
  props: {
    portal: Object as () => PortalDetail | null,
    isCurrentUserLead: Boolean,
    supportGoal: Object as () => Goal | null,
  },
  emits: ['close', 'add-goal', 'edit-purpose', 'flag', 'support'],
  setup(props, { emit }) {
    return () => h('div', {
      class: 'fixed inset-0 z-40 flex items-end justify-center',
      onClick: () => emit('close')
    }, [
      h('div', {
        class: 'bg-black bg-opacity-50 w-full',
        style: { maxWidth: '768px', position: 'absolute', top: '0', bottom: '0', left: '50%', transform: 'translateX(-50%)' }
      }),
      h('div', {
        class: 'bg-white w-full rounded-t-2xl p-6 relative z-10',
        style: { maxHeight: '80vh', overflowY: 'auto', maxWidth: '768px' },
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

          // Select Goal Team - light green, large text (available for everyone - navigates to Goal Teams tab)
          h('button', {
            class: 'text-[#8cc65d] font-bold text-[28px] py-3',
            onClick: () => {
              emit('close');
              // Switch to "Goal Teams" tab (index 0)
              selectedSection.value = 0;
            }
          }, 'Select Goal Team'),

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

// Fullscreen viewer with proper zoom functionality
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
    
    return () => h('div', {
      class: 'fixed inset-0 bg-black z-50 flex flex-col',
      style: {
        // Use dynamic viewport height for mobile browsers (handles landscape properly)
        height: '100dvh',
        width: '100vw'
      }
    }, [
      // Header with close button and pagination info
      h('div', { class: 'flex justify-between items-center p-4 text-white' }, [
        h('span', { class: 'text-sm' }, `${currentIndex.value + 1} / ${props.images?.length || 0}`),
        h('button', {
          class: 'text-white p-2',
          onClick: () => emit('close')
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
              d: 'M6 18L18 6M6 6l12 12'
            })
          ])
        ])
      ]),

      // Main image container
      h('div', {
        class: 'flex-1 relative overflow-hidden'
      }, [
        // Image with touch handlers - fills entire viewport in landscape
        h('div', {
          class: 'absolute inset-0 flex items-center justify-center',
          onDblclick: handleDoubleTap
        }, [
          h('img', {
            src: props.images?.[currentIndex.value]?.url,
            class: 'w-full h-full object-cover',
            style: {
              transform: transformStyle.value,
              transition: 'transform 0.15s ease-out',
              objectPosition: 'center'
            }
          })
        ]),
        
        // Navigation arrows (if multiple images)
        (props.images?.length || 0) > 1 && [
          h('button', {
            key: 'prev',
            class: 'absolute left-4 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-2',
            onClick: prevImage
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
            class: 'absolute right-4 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-30 rounded-full p-2',
            onClick: nextImage
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