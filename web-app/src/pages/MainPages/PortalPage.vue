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
      <BottomBarView @add="activeSheet = 'portalActionMenu'" @message="openMessageSheet" />
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
import { ref, onMounted, computed, watch, defineComponent, h, onBeforeUnmount } from 'vue';
import { useRoute, useRouter, RouterLink } from 'vue-router';
import api from '@/pages/utils/api';
import EditGoal from '../GoalPages/EditGoal.vue';
import PayTransaction from './PayTransaction.vue';

// --- Interfaces (from Swift Models) ---
interface User { 
  id: number; 
  fname?: string; 
  lname?: string; 
  profilePictureURL?: string; 
}

interface Goal { 
  id: number; 
  title: string; 
  typeName: string; 
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

interface PortalDetailResponse {
  result: PortalDetail;
}

interface PortalGoalsResponse {
  aGoals: Goal[];
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
const token = localStorage.getItem('jwtToken') || '';
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
const authHeaders = { headers: { Authorization: `Bearer ${token}` } };

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

const leadRepUser = computed(() => {
  return portalDetail.value?.aLeads?.[0] ?? null;
});

// --- API Methods (from ViewModel) ---
const fetchPortalDetail = async () => {
  isLoading.value = true;
  errorMessage.value = null;
  try {
    const res = await api.get(
      `/api/portal/details?portals_id=${portalId}&user_id=${userId}`,
      authHeaders
    );
    if (res.data && res.data.result) {
      portalDetail.value = res.data.result;
      console.log("Portal aLeads:", portalDetail.value.aLeads?.map(l => l.id) || []);
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
  try {
    const res = await api.get(
      `/api/goals/portal?portals_id=${portalId}`,
      authHeaders
    );
    if (res.data && res.data.aGoals) {
      portalGoals.value = res.data.aGoals;
    }
  } catch (err) {
    console.error('Failed to load portal goals:', err);
  }
};

const fetchReportingIncrements = async () => {
  try {
    const res = await api.get(
      `/api/reporting_increments/list`,
      authHeaders
    );
    if (res.data) {
      reportingIncrements.value = res.data;
    }
  } catch (err) {
    console.error('Failed to load reporting increments:', err);
  }
};

const flagPortal = async () => {
  try {
    await api.post(
      `/api/portal/flag_portal`,
      { portal_id: portalId, reason: '' },
      authHeaders
    );
    flagResultMessage.value = 'Portal flagged. Thank you for your report.';
  } catch (err) {
    flagResultMessage.value = 'Failed to flag portal.';
    console.error(err);
  }
};

// --- Event Handlers ---
const goBack = () => router.back();

const openFullscreen = (index: number) => {
  fullscreenStartIndex.value = index;
  isFullscreenOpen.value = true;
};

const openMessageSheet = () => {
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
  if (!token) {
    router.push('/login');
    return;
  }
  
  // Fetch portal data
  fetchPortalDetail();
  fetchPortalGoals();
  fetchReportingIncrements();
  
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
watch(portalGoals, (newGoals) => {
  console.log("Portal goals updated, supportGoal:", supportGoal.value);
}, { immediate: true });

// --- Inline Child Components ---

const PortalHeader = defineComponent({
  props: { portalName: String },
  emits: ['back'],
  setup(props, { emit }) {
    return () => h('header', { 
      class: 'flex items-center h-14 px-4 border-b border-gray-200 shrink-0' 
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
      return h('div', { 
        class: 'py-3 px-2 hover:bg-gray-50 transition'
      }, [
        h('div', { class: 'flex items-center space-x-4' }, [
          h('div', { class: 'flex-1' }, [
            h('h3', { class: 'font-bold text-lg' }, goal.title),
            h('p', { class: 'text-sm text-gray-600' }, `Type: ${goal.typeName}`)
          ])
        ])
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
    
    return () => h('div', { class: 'space-y-6' }, [
      h('h2', { class: 'font-bold text-lg' }, 'Leads'),
      h('div', { class: 'overflow-x-auto -mx-4 px-4' }, [
        h('div', { class: 'flex space-x-6 pb-2' },
          (props.portal?.aLeads || []).map((lead, index) =>
            h('div', { 
              key: index,
              class: 'text-center flex flex-col items-center' 
            }, [
              lead.profilePictureURL 
                ? h('img', {
                    src: lead.profilePictureURL,
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
              h('p', { class: 'text-xs mt-2 whitespace-nowrap' }, 
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
          textBlock.title && h('h3', { class: 'font-semibold text-lg' }, textBlock.title),
          textBlock.text && h('p', { class: 'text-gray-700 whitespace-pre-line' }, textBlock.text)
        ])
      )
    ]);
  }
});

const BottomBarView = defineComponent({
  emits: ['add', 'message'],
  setup(_, { emit }) {
    return () => h('footer', { 
      class: 'flex items-center justify-around p-4 border-t bg-white shrink-0'
    }, [
      h('button', { 
        onClick: () => emit('add'), 
        class: 'font-semibold text-lg text-green-600'
      }, 'Add'),
      h('button', { 
        onClick: () => emit('message'), 
        class: 'font-semibold text-lg text-green-600'
      }, 'Message Lead')
    ]);
  }
});

// ActionSheetModal - EXACTLY matching Swift logic with proper button ordering
const ActionSheetModal = defineComponent({
  props: {
    portal: Object as () => PortalDetail | null,
    isCurrentUserLead: Boolean,
    supportGoal: Object as () => Goal | null,
  },
  emits: ['close', 'add-goal', 'edit-purpose', 'flag', 'support'],
  setup(props, { emit }) {
    return () => h('div', { 
      class: 'fixed inset-0 bg-black bg-opacity-50 z-40 flex items-end', 
      onClick: () => emit('close') 
    },
      h('div', { 
        class: 'bg-white w-full rounded-t-xl p-6 space-y-6 transform transition-transform duration-300 ease-out', 
        style: { maxHeight: '80vh', overflowY: 'auto' },
        onClick: (e: Event) => e.stopPropagation() 
      }, [
        // "$ Support" button - always shown at the top if supportGoal exists, matching Swift EXACTLY
        props.supportGoal && h('button', { 
          class: 'w-full text-left py-3 text-xl font-semibold text-green-600 hover:bg-gray-50 transition-colors flex items-center space-x-2', 
          onClick: () => emit('support') 
        }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-6 w-6 text-green-800',
            fill: 'currentColor',
            viewBox: '0 0 20 20'
          }, [
            h('path', {
              'fill-rule': 'evenodd',
              d: 'M4 4a2 2 0 00-2 2v4a2 2 0 002 2V6h10a2 2 0 00-2-2H4zm2 6a2 2 0 012-2h8a2 2 0 012 2v4a2 2 0 01-2 2H8a2 2 0 01-2-2v-4zm6 4a2 2 0 100-4 2 2 0 000 4z',
              'clip-rule': 'evenodd'
            })
          ]),
          h('span', 'Support')
        ]),
        
        // Add Goal - only if current user is lead (matches Swift isCurrentUserLead check)
        props.isCurrentUserLead && h('button', { 
          class: 'action-button', 
          onClick: () => emit('add-goal') 
        }, 'Add Goal'),
        
        // Select Goal Team - always shown (no action in Swift, just placeholder)
        h('button', { 
          class: 'action-button' 
        }, 'Select Goal Team'),
        
        // Edit Purpose - only if portal belongs to current user (matches Swift: portal.users_id == userId)
        (props.portal?.users_id === userId) && h('button', { 
          class: 'action-button', 
          onClick: () => emit('edit-purpose') 
        }, 'Edit Purpose'),
        
        // Flag - always shown
        h('button', { 
          class: 'action-button text-red-500', 
          onClick: () => emit('flag') 
        }, 'Flag as Inappropriate'),
        
        // Cancel button
        h('div', { class: 'pt-4' }, [
          h('button', { 
            class: 'w-full text-center text-gray-600 py-2', 
            onClick: () => emit('close') 
          }, 'Cancel')
        ])
      ])
    );
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
      class: 'fixed inset-0 bg-black z-50 flex flex-col'
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
        // Image with touch handlers
        h('div', {
          class: 'absolute inset-0 flex items-center justify-center',
          onDblclick: handleDoubleTap
        }, [
          h('img', {
            src: props.images?.[currentIndex.value]?.url,
            class: 'max-w-full max-h-full object-contain',
            style: {
              transform: transformStyle.value,
              transition: 'transform 0.15s ease-out'
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