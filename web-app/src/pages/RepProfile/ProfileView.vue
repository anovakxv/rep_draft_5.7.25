<!--
  ProfileView.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->
  
<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Loading State -->
    <div v-if="!isLoaded" class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <div class="animate-spin h-8 w-8 border-4 border-t-transparent rounded-full mx-auto mb-4" style="border-color: #8cc65d; border-top-color: transparent;"></div>
        <p class="text-gray-500">Loading Profile...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="errorMessage" class="flex-1 flex items-center justify-center p-4">
      <div class="text-center">
        <p class="text-red-500 mb-4">{{ errorMessage }}</p>
        <button @click="fetchProfile" class="px-4 py-2 text-white rounded-lg" style="background-color: #8cc65d">
          Retry
        </button>
      </div>
    </div>

    <!-- Main Content Container -->
    <div v-else class="flex flex-col flex-1 min-h-0">
      <!-- Navigation Header -->
      <NavigationHeaderView
        :name="user.displayName"
        :show-settings="isCurrentUser"
        @back="goBack"
        @settings="goToSettings"
      />

      <!-- Scrollable Content -->
      <main class="flex-1 overflow-y-auto pb-20">
      <div class="relative">
        <!-- Profile Info -->
        <ProfileInfoView
          :photo-url="user.profile_picture_url"
          :city="user.city"
          :skills="user.skills ? user.skills.map(s => s.title) : []"
          :display-name="user.displayName"
        />

        <!-- Broadcast Message -->
        <ProfileBroadcastView :broadcast="user.broadcast" />

        <!-- Sticky Tab Header -->
        <div class="sticky top-0 z-10 bg-white px-4 pt-2 pb-1">
          <ProfileSegmentedPicker
            :segments="['Rep', 'Goals', 'Write']"
            v-model="selectedTab"
          />
        </div>

        <!-- Tab Content -->
        <div class="px-4 pt-2">
        <!-- Rep Tab -->
        <div v-if="selectedTab === 'rep'" class="pt-2">
          <ProfileRepSection
            :portals="portals"
            :is-current-user="isCurrentUser"
            :show-add-partner="false"
            @portal-click="goToPortal"
          />
        </div>

        <!-- Goals Tab -->
        <div v-if="selectedTab === 'goals'" class="pt-2">
          <GoalsListSection
            :goals="goals"
            :is-current-user="isCurrentUser"
            @goal-click="goToGoal"
          />
        </div>

        <!-- Write Tab -->
        <div v-if="selectedTab === 'write'" class="pt-2">
          <WriteContentView
            :write-blocks="writeBlocks"
            :is-current-user="isCurrentUser"
            :write-form="writeForm"
            :editing-write="editingWrite"
            @start-edit="startEditWrite"
            @cancel-edit="cancelEditWrite"
            @save-write="saveWrite"
            @delete-write="confirmDeleteWrite"
          />
        </div>
      </div>
      </div>
    </main>
    </div>

    <!-- Fixed Bottom Bar -->
    <div class="fixed bottom-0 left-0 right-0 z-20 flex justify-center">
      <div class="w-full bg-white border-t shadow-lg flex items-center justify-center gap-3 py-1.5 px-4" style="max-width: 768px; border-color: #e5e7eb;">
        <!-- Message Button -->
        <button
          @click="goToMessages"
          class="flex-1 flex items-center justify-center h-10 rounded-lg border-2 transition-transform hover:scale-105 active:scale-95"
          style="border-color: #8cc65d; color: #8cc65d; background-color: white;"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
          </svg>
        </button>

        <!-- Add Button -->
        <button
          @click="showActionMenu = true"
          class="flex-1 flex items-center justify-center h-10 rounded-lg transition-transform hover:scale-105 active:scale-95"
          style="background-color: #8cc65d; color: white;"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Action Menu Modal -->
    <div v-if="showActionMenu" @click="showActionMenu = false" class="fixed inset-0 z-30 flex items-end justify-center">
      <div class="bg-black bg-opacity-50 w-full" style="max-width: 768px; position: absolute; top: 0; bottom: 0; left: 50%; transform: translateX(-50%);"></div>
      <div @click.stop class="bg-white w-full rounded-t-2xl p-6 relative z-10" style="max-width: 768px">
        <div class="flex flex-col items-center space-y-6">
          <!-- Current User Actions -->
          <template v-if="isCurrentUser">
            <button @click="goToEditProfile" class="text-[#8cc65d] font-bold text-[28px] py-3">Edit Profile</button>
            <button @click="goToAddPurpose" class="text-[#8cc65d] font-bold text-[28px] py-3">Add Purpose</button>
            <button @click="goToAddGoal" class="text-[#8cc65d] font-bold text-[28px] py-3">Add Goal</button>
            <button @click="logout" class="text-red-600 font-bold text-[28px] py-3">Logout</button>
            <button @click="showPolicy = true" class="text-gray-500 text-[16px] py-3">Policy</button>
          </template>
          <!-- Other User Actions -->
          <template v-else>
            <button @click="addToNetwork" class="text-[#8cc65d] font-bold text-[28px] py-3">+ to NTWK</button>
            <button @click="blockUser" class="text-[#8cc65d] font-bold text-[28px] py-3">{{ isBlocked ? 'Unblock User' : 'Block User' }}</button>
            <button @click="flagUser" class="text-red-600 font-bold text-[28px] py-3">Flag as Inappropriate</button>
          </template>
          <!-- Cancel Button -->
          <button @click="showActionMenu = false" class="w-full text-center text-gray-500 text-[16px] py-3 mt-4">Cancel</button>
        </div>
      </div>
    </div>

    <!-- Network Result Alert -->
    <div v-if="showNetworkResultAlert" class="fixed inset-0 flex items-center justify-center z-50">
      <div class="bg-white p-4 rounded-lg shadow-lg">
        <p>{{ networkResultMessage }}</p>
        <button @click="showNetworkResultAlert = false" class="mt-3 text-white px-4 py-2 rounded w-full" style="background-color: #8cc65d">OK</button>
      </div>
    </div>

    <!-- Flag Confirmation Dialog -->
    <div v-if="showFlagConfirmation" class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
      <div class="bg-white p-4 rounded-lg shadow-lg max-w-md">
        <h3 class="font-bold text-lg mb-2">Flag User?</h3>
        <p>Are you sure you want to flag this person as inappropriate?</p>
        <div class="flex justify-end space-x-2 mt-4">
          <button @click="showFlagConfirmation = false" class="px-4 py-2 text-gray-600">Cancel</button>
          <button @click="confirmFlagUser" class="px-4 py-2 bg-red-600 text-white rounded">Flag</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import api from '@/pages/utils/api'
import { ref, onMounted, computed, watch, defineComponent, h } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'

// Components using h() render functions
const NavigationHeaderView = defineComponent({
  props: {
    name: String,
    showSettings: Boolean
  },
  emits: ['back', 'settings'],
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
      h('h1', { class: 'flex-1 text-center font-bold text-xl' }, props.name),
      h('div', { class: 'w-8 flex items-center justify-center' }, [
        props.showSettings && h('button', {
          onClick: () => emit('settings'),
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
              d: 'M4 6h16M4 12h16M4 18h16'
            })
          ])
        ])
      ])
    ])
  }
})

const ProfileInfoView = defineComponent({
  props: {
    photoUrl: String,
    city: String,
    skills: Array,
    displayName: String
  },
  setup(props) {
    const getInitials = (name: string): string => {
      const parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      }
      return name.substring(0, 2).toUpperCase();
    };

    return () => h('div', { class: 'p-4 flex items-start space-x-4' }, [
      props.photoUrl
        ? h('img', {
            src: props.photoUrl,
            class: 'w-28 h-28 rounded-full object-cover',
            alt: 'Profile Picture',
            onError: (e: Event) => {
              const target = e.target as HTMLImageElement;
              const parent = target.parentElement;
              if (parent) {
                target.remove();
                const initialsDiv = document.createElement('div');
                initialsDiv.className = 'w-28 h-28 rounded-full bg-gray-400 flex items-center justify-center text-white font-bold text-3xl';
                initialsDiv.textContent = getInitials(props.displayName || 'User');
                parent.prepend(initialsDiv);
              }
            }
          })
        : h('div', {
            class: 'w-28 h-28 rounded-full bg-gray-400 flex items-center justify-center text-white font-bold text-3xl'
          }, getInitials(props.displayName || 'User')),
      h('div', { class: 'pt-2' }, [
        props.city && h('p', { class: 'font-bold text-lg' }, props.city),
        props.skills && props.skills.length > 0 && h('div', { class: 'mt-1' },
          props.skills.map((skill: any, index: number) =>
            h('p', { key: index, class: 'text-base' }, skill)
          )
        )
      ])
    ])
  }
})

const ProfileBroadcastView = defineComponent({
  props: {
    broadcast: String
  },
  setup(props) {
    return () => props.broadcast
      ? h('div', { class: 'px-4 pb-2' }, [
          h('p', { class: 'text-gray-600' }, props.broadcast)
        ])
      : null
  }
})

const ProfileSegmentedPicker = defineComponent({
  props: {
    segments: Array,
    modelValue: String
  },
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    return () => h('div', { class: 'flex border border-black rounded overflow-hidden' },
      (props.segments as string[]).map((segment: string) =>
        h('button', {
          key: segment,
          onClick: () => emit('update:modelValue', segment.toLowerCase()),
          class: [
            'flex-1 py-1 text-center font-medium',
            props.modelValue === segment.toLowerCase() ? 'bg-black text-white' : 'bg-white text-black'
          ]
        }, segment)
      )
    )
  }
})

const ProfileRepSection = defineComponent({
  props: {
    portals: Array,
    isCurrentUser: Boolean,
    showAddPartner: Boolean
  },
  emits: ['portal-click', 'add-partner'],
  setup(props, { emit }) {
    return () => h('div', { class: 'bg-gray-50' }, [
      (props.portals && props.portals.length > 0)
        ? (props.portals as any[]).map((portal: any) =>
            h(RouterLink, {
              to: `/portal/${portal.id}`,
              key: portal.id,
              class: 'block'
            }, () =>
              h('div', {
                class: 'flex items-start gap-4 px-4 py-3 bg-white border-b border-gray-200 hover:bg-gray-50 transition-colors',
                style: { minHeight: '105px' }
              }, [
                // Image (144px x 81px, 16:9 ratio)
                portal.mainImageUrl
                  ? h('img', {
                      src: portal.mainImageUrl,
                      alt: portal.name,
                      class: 'object-cover rounded flex-shrink-0',
                      style: { width: '144px', height: '81px' }
                    })
                  : h('div', {
                      class: 'bg-gray-200 rounded flex-shrink-0',
                      style: { width: '144px', height: '81px' }
                    }),

                // Text content
                h('div', { class: 'flex-1 min-w-0 flex flex-col justify-between', style: { minHeight: '81px' } }, [
                  h('div', { class: 'space-y-1' }, [
                    // Portal name (semibold, 2 lines max)
                    h('h3', {
                      class: 'font-semibold text-[17px] leading-tight line-clamp-2 text-gray-900'
                    }, portal.name),

                    // Subtitle (2 lines max, secondary color)
                    portal.subtitle && portal.subtitle.trim()
                      ? h('p', {
                          class: 'text-[17px] text-gray-600 leading-tight line-clamp-2'
                        }, portal.subtitle)
                      : null
                  ]),

                  // Bottom row: city and member count
                  h('div', { class: 'flex items-center justify-between text-xs mt-auto pt-1' }, [
                    h('span', { class: 'text-gray-500' }, ''),
                    h('span', { class: 'text-green-600 font-medium' }, '')
                  ])
                ])
              ])
            )
          )
        : h('p', { class: 'text-gray-500 text-center py-8' }, 'No purposes yet.'),
      props.showAddPartner && h('button', {
        onClick: () => emit('add-partner'),
        class: 'mt-4 w-full text-center',
        style: 'color: #8cc65d'
      }, 'Add Partner')
    ])
  }
})

const GoalsListSection = defineComponent({
  props: {
    goals: Array,
    isCurrentUser: Boolean
  },
  emits: ['goal-click'],
  setup(props, { emit }) {
    const renderGoalCard = (goal: any) => {
      // Compute tag text (matching iOS logic)
      const tagText = goal.typeName?.toLowerCase() === 'other'
        ? (goal.metricName?.trim() || goal.typeName || 'Goal').substring(0, 9)
        : (goal.typeName || 'Goal');

      // Get last 4 chart data points
      const chartBars = (goal.chartData || []).slice(-4);

      return h('div', {
        class: 'flex items-center gap-4 py-1 px-4 bg-white hover:bg-gray-50 transition',
        style: { height: '89px' }
      }, [
        // Mini bar chart (left side)
        h('div', {
          class: 'flex items-end gap-[6px]',
          style: { width: '114px', height: '81px' }
        }, chartBars.map((bar: any, idx: number) => {
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
          h('h3', { class: 'font-semibold text-[17px] leading-tight' }, goal.title || goal.name),

          // Subtitle (if exists)
          goal.subtitle && goal.subtitle.trim()
            ? h('p', { class: 'text-[15px] text-gray-600 leading-tight' }, goal.subtitle)
            : null,

          // Progress percentage with tag
          h('p', { class: 'text-[15px] text-black' }, `${Math.round(goal.progressPercent || (goal.progress * 100) || 0)}% [${tagText}]`)
        ].filter(Boolean))
      ]);
    };

    return () => h('div', { class: 'space-y-2' }, [
      (props.goals && props.goals.length > 0)
        ? (props.goals as any[]).map((goal: any, index: number) =>
            h(RouterLink, {
              to: `/goal/${goal.id}`,
              key: goal.id,
              class: 'block'
            }, () => renderGoalCard(goal))
          )
        : h('p', { class: 'text-gray-500 text-center py-8' }, 'No goals yet.')
    ])
  }
})

const WriteContentView = defineComponent({
  props: {
    writeBlocks: Array,
    isCurrentUser: Boolean
  },
  emits: ['delete-write', 'edit-write', 'new-write'],
  setup(props, { emit }) {
    const router = useRouter()
    const expandedWriteIds = ref<Set<number>>(new Set())

    const toggleExpand = (writeId: number) => {
      const newSet = new Set(expandedWriteIds.value)
      if (newSet.has(writeId)) {
        newSet.delete(writeId)
      } else {
        newSet.add(writeId)
      }
      expandedWriteIds.value = newSet
    }

    const isExpanded = (writeId: number) => {
      return expandedWriteIds.value.has(writeId)
    }

    const navigateToEdit = (writeId: number) => {
      router.push(`/write/edit/${writeId}`)
    }

    const navigateToNew = () => {
      router.push('/write/new')
    }

    return () => h('div', { class: 'space-y-4' }, [
      // Existing write blocks
      props.writeBlocks && props.writeBlocks.length > 0
        ? h('div', { class: 'space-y-4' }, props.writeBlocks.map((write: any) => {
            const expanded = isExpanded(write.id)
            const shouldTruncate = write.content.length > 200
            const displayContent = expanded ? write.content : write.content.substring(0, 200)

            return h('div', {
              key: write.id,
              class: 'p-4 border border-gray-200 rounded-lg hover:shadow-md transition-shadow'
            }, [
              write.title && h('h3', { class: 'font-bold text-lg mb-2' }, write.title),
              h('div', {
                class: 'text-black prose prose-sm max-w-none mb-3',
                innerHTML: displayContent + (!expanded && shouldTruncate ? '...' : '')
              }),
              shouldTruncate && h('button', {
                onClick: () => toggleExpand(write.id),
                class: 'font-medium text-sm mb-3',
                style: 'color: #8cc65d'
              }, expanded ? 'Read less' : 'Read more'),
              h('div', { class: 'flex items-center justify-between text-sm text-gray-500' }, [
                h('span', write.status === 'draft' ? 'Draft' : 'Published'),
                props.isCurrentUser && h('div', { class: 'flex space-x-3' }, [
                  h('button', {
                    onClick: () => navigateToEdit(write.id),
                    class: 'text-blue-600 hover:text-blue-800 font-medium'
                  }, 'Edit'),
                  h('button', {
                    onClick: () => emit('delete-write', write),
                    class: 'text-red-600 hover:text-red-800 font-medium'
                  }, 'Delete')
                ])
              ])
            ])
          }))
        : h('p', { class: 'text-gray-500 text-center py-8' }, 'No content yet.'),

      // New Content Button for current user
      props.isCurrentUser && h('div', { class: 'mt-6 pt-6 border-t' }, [
        h('button', {
          onClick: navigateToNew,
          class: 'w-full py-3 text-white font-bold rounded-lg transition-colors flex items-center justify-center space-x-2',
          style: 'background-color: #8cc65d'
        }, [
          h('svg', {
            xmlns: 'http://www.w3.org/2000/svg',
            class: 'h-5 w-5',
            fill: 'none',
            viewBox: '0 0 24 24',
            stroke: 'currentColor'
          }, [
            h('path', {
              'stroke-linecap': 'round',
              'stroke-linejoin': 'round',
              'stroke-width': '2',
              d: 'M12 4v16m8-8H4'
            })
          ]),
          h('span', 'Create New Content')
        ])
      ])
    ])
  }
})

// BottomBarView removed - replaced with floating action buttons

// Define interfaces based on Swift models - expanded to match Swift
interface Skill { 
  id: number; 
  title: string; 
}

interface User {
  id: number;
  full_name?: string;  // Backend returns snake_case
  fname?: string;
  lname?: string;
  username?: string;
  about?: string;
  broadcast?: string;
  profile_picture_url?: string;  // Backend returns snake_case
  imageName?: string;
  userType?: string;
  city?: string;
  skills?: Skill[];
  other_skill?: string;
  lastLogin?: string;
  createdAt?: string;
  updatedAt?: string;
  lastMessage?: string;
  lastMessageDate?: string;
  
  // Computed in Swift, we'll compute in Vue
  displayName: string;
  repTypeAndCity?: string;
}

interface Portal { 
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
}

interface Goal { 
  id: number; 
  name: string; 
  description?: string; 
}

interface WriteBlock { 
  id: number; 
  title?: string; 
  content: string;
  order?: number;
  created_at?: string;
  updated_at?: string;
}

const route = useRoute()
const router = useRouter()

// State
const user = ref<User>({ id: 0, displayName: '' })
const portals = ref<Portal[]>([])
const goals = ref<Goal[]>([])
const writeBlocks = ref<WriteBlock[]>([])
const isLoaded = ref(false)
const isBlocked = ref(false)
const errorMessage = ref<string | null>(null)
const selectedTab = ref('rep') // 'rep', 'goals', 'write'
const showActionMenu = ref(false)
const showAddPurpose = ref(false)
const showAddGoal = ref(false)
const showPolicy = ref(false)
const showFlagConfirmation = ref(false)
const showNetworkResultAlert = ref(false)
const networkResultMessage = ref('')

const editingWrite = ref<WriteBlock | null>(null)
const writeForm = ref({ title: '', content: '' })

// Computed properties
const viewedUserId = computed(() => Number(route.params.id))
const loggedInUserId = computed(() => Number(localStorage.getItem('userId')))
const isCurrentUser = computed(() => viewedUserId.value === loggedInUserId.value)

// Methods
const fetchProfile = async () => {
  isLoaded.value = false
  errorMessage.value = null
  try {
    // Parallel API calls
    const [userRes, portalsRes, goalsRes, writesRes, blockStatusRes] = await Promise.all([
      api.get(`/api/user/profile?users_id=${viewedUserId.value}`),
      api.get(`/api/portal/filter_network_portals?user_id=${viewedUserId.value}&tab=open`),
      api.get(`/api/goals/list?users_id=${viewedUserId.value}`),
      api.get(`/api/user/writes?users_id=${viewedUserId.value}`),
      isCurrentUser.value ? Promise.resolve({ data: { is_blocked: false } }) : api.get(`/api/user/is_blocked?users_id=${viewedUserId.value}`)
    ]);

    const profile = userRes.data.result
    if (!profile || !profile.id) {
      errorMessage.value = 'User not found'
      return
    }

    user.value = {
      id: profile.id,
      full_name: profile.full_name,
      fname: profile.fname,
      lname: profile.lname,
      username: profile.username,
      about: profile.about,
      broadcast: profile.broadcast,
      profile_picture_url: profile.profile_picture_url,
      imageName: profile.imageName,
      userType: profile.user_type,
      city: profile.city,
      skills: profile.skills,
      other_skill: profile.other_skill,
      lastLogin: profile.last_login,
      createdAt: profile.created_at,
      updatedAt: profile.updated_at,
      lastMessage: profile.last_message,
      lastMessageDate: profile.last_message_date,

      // Compute displayName like in Swift
      displayName: profile.full_name ||
        ((profile.fname || '') + ' ' + (profile.lname || '')).trim(),

      // Compute repTypeAndCity like in Swift
      repTypeAndCity: computeRepTypeAndCity(profile.user_type, profile.city)
    }

    portals.value = portalsRes.data.result || []
    goals.value = goalsRes.data.aGoals || []

    // Handle writes response - structure matches Swift
    writeBlocks.value = writesRes.data.result || []

    isBlocked.value = blockStatusRes.data.is_blocked || false

  } catch (error) {
    console.error("Failed to load profile data:", error)
    // Handle auth errors, e.g., redirect to login
    if ((error as any).response?.status === 401) {
      handleUnauthorized()
    } else {
      errorMessage.value = (error as any).response?.data?.error || 'Failed to load profile. Please try again.'
    }
  } finally {
    isLoaded.value = true
  }
}

// Helper function similar to Swift's computed property
function computeRepTypeAndCity(type?: string, city?: string): string {
  const typeStr = type || ""
  const cityStr = city || ""
  
  if (typeStr && cityStr) {
    return `Rep Type: ${typeStr}   City: ${cityStr}`
  } else if (typeStr) {
    return `Rep Type: ${typeStr}`
  } else if (cityStr) {
    return `City: ${cityStr}`
  }
  return ""
}

function handleUnauthorized() {
  localStorage.removeItem('jwtToken')
  localStorage.removeItem('userId')
  localStorage.setItem('isRegistered', 'false')
  router.push('/login')
}

const goBack = () => {
  const fromTab = route.query.from;
  if (fromTab) {
    router.push({ path: '/main', query: { tab: fromTab } });
  } else {
    router.back();
  }
}
const goToSettings = () => router.push('/settings')
const goToEditProfile = () => {
  showActionMenu.value = false
  router.push('/profile/edit')
}
const goToAddPurpose = () => {
  showActionMenu.value = false
  router.push('/portal/edit/new')
}
const goToAddGoal = () => {
  showActionMenu.value = false
  router.push('/goal/edit/new')
}
const goToPortal = (id: number) => router.push(`/portal/${id}`)
const goToGoal = (id: number) => router.push(`/goal/${id}`)
const goToMessages = () => {
  // Navigate to chat with this user
  router.push(`/chat/user/${viewedUserId.value}`)
}

const logout = () => {
  // API call to logout like in Swift
  api.post('/api/user/logout', {})
    .finally(() => {
      localStorage.clear()
      router.push('/login')
      showActionMenu.value = false
    })
}

const addToNetwork = async () => {
  try {
    await api.post('/api/user/network_action', {
      action: "add",
      user_id: loggedInUserId.value,
      target_user_id: viewedUserId.value
    })

    networkResultMessage.value = 'Added to your network!'
    showNetworkResultAlert.value = true
  } catch {
    networkResultMessage.value = 'Failed to add to network.'
    showNetworkResultAlert.value = true
  }
  showActionMenu.value = false
}

const blockUser = async () => {
  const action = isBlocked.value ? 'unblock' : 'block'
  try {
  await api.post(`/api/user/${action}`, { users_id: viewedUserId.value })
    isBlocked.value = !isBlocked.value
    networkResultMessage.value = `User ${action}ed.`
    showNetworkResultAlert.value = true
  } catch {
    networkResultMessage.value = `Failed to ${action} user.`
    showNetworkResultAlert.value = true
  }
  showActionMenu.value = false
}

const flagUser = async () => {
  showFlagConfirmation.value = true
  showActionMenu.value = false
}

const confirmFlagUser = async () => {
  try {
    await api.post('/api/user/flag_user', { users_id: viewedUserId.value, reason: 'Inappropriate content' })
    networkResultMessage.value = 'User has been flagged.'
    showNetworkResultAlert.value = true
  } catch {
    networkResultMessage.value = 'Failed to flag user.'
    showNetworkResultAlert.value = true
  }
  showFlagConfirmation.value = false
}

const startEditWrite = (write: WriteBlock) => {
  editingWrite.value = write
  writeForm.value = { title: write.title || '', content: write.content }
}

const cancelEditWrite = () => {
  editingWrite.value = null
  writeForm.value = { title: '', content: '' }
}

const saveWrite = async () => {
  try {
    if (editingWrite.value) {
      // Update existing write - include order if present like in Swift
      const updateData = { 
        title: writeForm.value.title, 
        content: writeForm.value.content
      }
      if (editingWrite.value.order !== undefined) {
        Object.assign(updateData, { order: editingWrite.value.order })
      }
      
      await api.put(`/api/user/write/${editingWrite.value.id}`, updateData)
    } else {
      // Add new write
      await api.post('/api/user/write', writeForm.value)
    }
    cancelEditWrite()
    await fetchProfile() // Refresh data
  } catch {
    alert('Failed to save content.')
  }
}

const confirmDeleteWrite = async (write: WriteBlock) => {
  if (confirm('Are you sure you want to delete this writing block?')) {
    try {
  await api.delete(`/api/user/write/${write.id}`)
      await fetchProfile() // Refresh data
    } catch {
      alert('Failed to delete content.')
    }
  }
}

// Watch for changes in showAddPurpose/showAddGoal to refresh goals after modal closes
watch([showAddPurpose, showAddGoal], ([newPurposeVal, newGoalVal], [oldPurposeVal, oldGoalVal]) => {
  if ((oldPurposeVal && !newPurposeVal) || (oldGoalVal && !newGoalVal)) {
    fetchProfile() // Refresh data when modals close
  }
})

onMounted(fetchProfile)
</script>

<style scoped>
</style>