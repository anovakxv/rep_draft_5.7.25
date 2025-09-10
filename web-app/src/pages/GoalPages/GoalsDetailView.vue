<!--
  GoalsDetailView.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Custom Top Bar -->
    <header class="flex items-center justify-between h-14 px-4 border-b bg-white shrink-0">
      <button @click="goBack" class="text-green-600 p-2 -ml-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <h1 class="font-bold text-lg truncate px-4">{{ goal?.title || 'Goal Details' }}</h1>
      <div class="w-10"></div> <!-- Spacer -->
    </header>

    <!-- Main Content -->
    <div v-if="goal" class="flex-1 flex flex-col overflow-hidden">
      <!-- Progress Bar and Metrics Section -->
      <div class="p-4 border-b">
        <div class="bg-gray-200 rounded-none h-[34px] overflow-hidden">
          <div class="bg-[#8cc65d] h-full" :style="{ width: `${goal.progressPercent}%` }"></div>
        </div>
        <div class="text-sm text-gray-600 mt-2 space-y-1">
          <div class="flex justify-between">
            <span>Metric: {{ goal.metricName }}</span>
            <span>Goal Type: {{ goal.typeName }}</span>
          </div>
          <div class="flex justify-between">
            <span>Quota: {{ Math.round(goal.quota) }}</span>
            <span>Progress: {{ Math.round(goal.filledQuota) }}</span>
          </div>
          <div v-if="goal.subtitle" class="text-secondary text-base mt-1">{{ goal.subtitle }}</div>
          <div v-if="goal.description" class="text-secondary text-base">{{ goal.description }}</div>
        </div>
      </div>

      <!-- Segmented Picker -->
      <GoalSegmentedPicker
        :segments="['Feed', 'Report', 'Team']"
        :selected-index="selectedSegment"
        @update:selected-index="selectedSegment = $event"
        class="mx-4 my-4"
      />

      <!-- Content List -->
      <div class="flex-1 overflow-y-auto">
        <!-- Feed -->
        <div v-if="selectedSegment === 0" class="px-4">
          <div v-if="feed.length === 0" class="text-center text-gray-500 py-10">No feed items yet.</div>
          <div v-else>
            <FeedCell
              v-for="feedItem in feed"
              :key="feedItem.id"
              :feed="feedItem"
              @profile-tap="navigateToProfile(getUserIdForFeed(feedItem))"
            />
          </div>
        </div>
        
        <!-- Report -->
        <div v-else-if="selectedSegment === 1" class="px-4">
          <div v-if="goal.chartData && goal.chartData.length > 0">
            <LargeBarChartView :data="goal.chartData" :quota="goal.quota" />
          </div>
          <div v-else class="text-center text-gray-500 py-10">
            No chart data available.
          </div>
        </div>
        
        <!-- Team -->
        <div v-else-if="selectedSegment === 2" class="px-4">
          <div v-if="team.length === 0" class="text-center text-gray-500 py-10">No team members yet.</div>
          <div v-else>
            <TeamCell
              v-for="user in team"
              :key="user.id"
              :user="user"
              @click="navigateToProfile(user.id)"
            />
          </div>
        </div>
      </div>

      <!-- Bottom Bar -->
      <BottomGoalBar @add="activeSheet = 'action'" @message="openGoalTeamChat" />
    </div>

    <!-- Loading State -->
    <div v-else class="flex-1 flex items-center justify-center">
      <div class="animate-spin h-8 w-8 border-4 border-[#8cc65d] border-t-transparent rounded-full"></div>
    </div>

    <!-- Floating Support Button -->
    <button
      v-if="goal && (goal.typeName === 'Fund' || goal.typeName === 'Sales')"
      @click="showPaymentSheet = true"
      class="absolute bottom-20 right-5 px-5 py-3.5 bg-white border-2 border-[#8cc65d] rounded-lg shadow-lg flex items-center gap-2 text-[#8cc65d] font-semibold"
      style="box-shadow: -3px 5px 7px rgba(26, 26, 26, 0.4)"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-[22px] w-[22px]" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" /></svg>
      Support
    </button>

    <!-- Team Chat Loading Overlay -->
    <div v-if="isCreatingTeamChat" class="fixed inset-0 bg-black bg-opacity-15 z-40 flex items-center justify-center">
      <div class="bg-white p-4 rounded-xl shadow-lg flex flex-col items-center gap-3">
        <div class="animate-spin h-6 w-6 border-3 border-[#8cc65d] border-t-transparent rounded-full"></div>
        <div>Opening Team Chat...</div>
      </div>
    </div>

    <!-- Action Sheet -->
    <div v-if="activeSheet === 'action'" class="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-end justify-center">
      <div class="bg-white rounded-t-xl w-full max-w-md">
        <div class="p-6 space-y-6">
          <div v-if="goal?.typeName === 'Recruiting'" class="space-y-6">
            <button @click="joinRecruitingGoal" class="w-full text-[#8cc65d] font-bold text-xl">
              Join Team
            </button>
            <button @click="activeSheet = 'inviteTeam'" class="w-full text-[#8cc65d] font-bold text-xl">
              Invite to Team
            </button>
          </div>
          <div v-else class="space-y-6">
            <button @click="activeSheet = 'updateGoal'" class="w-full text-[#8cc65d] font-bold text-xl">
              Update Progress
            </button>
          </div>
          <button @click="activeSheet = 'editGoal'" class="w-full text-[#8cc65d] font-bold text-xl">
            Edit Goal
          </button>
          <button @click="confirmDelete" class="w-full text-red-500 font-medium">
            Delete Goal
          </button>
          <button @click="activeSheet = null" class="w-full text-gray-500">
            Cancel
          </button>
        </div>
      </div>
    </div>

    <!-- Update Goal Sheet -->
    <UpdateGoalSheet 
      v-if="activeSheet === 'updateGoal'" 
      :goal-id="goal?.id" 
      :quota="goal?.quota" 
      :metric-name="goal?.metricName"
      @close="handleSheetClose" 
    />

    <!-- Edit Goal Page -->
    <EditGoalPage 
      v-if="activeSheet === 'editGoal' && goal?.id && goal?.creatorId === currentUserId" 
      :existing-goal="goal" 
      :portal-id="goal?.portalId || 0" 
      :user-id="currentUserId" 
      :reporting-increments="reportingIncrements.length ? reportingIncrements : defaultReportingIncrements"
      @close="handleSheetClose" 
    />

    <!-- Invite Team Sheet -->
    <InviteTeamSheet 
      v-if="activeSheet === 'inviteTeam'" 
      :goal-id="goal?.id" 
      @done="handleTeamInvite"
      @close="activeSheet = null" 
    />

    <!-- Group Chat Sheet -->
    <GroupChatView 
      v-if="showChatSheet && goalTeamChatId" 
      :current-user-id="currentUserId"
      :chat-id="goalTeamChatId"
      :custom-chat-title="`Goal Team: ${goal?.title}`"
      @close="handleChatClose" 
    />

    <!-- Payment Sheet -->
    <PayTransactionView
      v-if="showPaymentSheet"
      :portal-id="goal?.portalId || 0"
      :portal-name="goal?.portalName || 'Portal'"
      :goal-id="goal?.id || 0"
      :goal-name="goal?.title || ''"
      :transaction-type="goal?.typeName === 'Fund' ? 'donation' : 'payment'"
      @close="showPaymentSheet = false"
    />

    <!-- Delete Alert -->
    <div v-if="showDeleteAlert" class="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-lg p-6 max-w-sm w-full">
        <h3 class="text-lg font-semibold mb-2">Delete Goal?</h3>
        <p class="text-gray-600 mb-6">Are you sure you want to delete this goal? This cannot be undone.</p>
        <div class="flex justify-end space-x-4">
          <button @click="showDeleteAlert = false" class="px-4 py-2 text-gray-700">
            Cancel
          </button>
          <button @click="deleteGoal" class="px-4 py-2 bg-red-500 text-white rounded">
            Delete
          </button>
        </div>
      </div>
    </div>

    <!-- Error Alert -->
    <div v-if="chatCreationError" class="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-lg p-6 max-w-sm w-full">
        <h3 class="text-lg font-semibold mb-2">Chat Error</h3>
        <p class="text-gray-600 mb-6">{{ chatCreationError }}</p>
        <div class="flex justify-end">
          <button @click="chatCreationError = null" class="px-4 py-2 bg-blue-500 text-white rounded">
            OK
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, defineComponent, h } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import axios from 'axios';

// --- Types & Interfaces ---
interface Goal {
  id: number;
  title: string;
  subtitle: string;
  description: string;
  progress: number;
  progressPercent: number;
  quota: number;
  filledQuota: number;
  metricName: string;
  typeName: string;
  reportingName: string;
  quotaString: string;
  valueString: string;
  chartData: BarChartData[];
  creatorId: number;
  portalId?: number;
  portalName?: string;
}

interface User {
  id: number;
  fullName?: string;
  fname?: string;
  lname?: string;
  username?: string;
  about?: string;
  broadcast?: string;
  profilePictureURL?: string;
  imageName?: string;
  userType?: string;
  city?: string;
  skills?: string[];
  other_skill?: string;
  lastLogin?: string;
  createdAt?: string;
  updatedAt?: string;
  lastMessage?: string;
  lastMessageDate?: string;
}

interface Feed {
  id: number;
  userImageName: string;
  userName: string;
  line1: string;
  line2: string;
  line3: string;
  line4: string;
  userProfilePictureURL?: string;
}

interface BarChartData {
  id: number;
  value: number;
  valueLabel: string;
  bottomLabel: string;
}

interface ReportingIncrement {
  id: number;
  title: string;
}

interface APIGoalDetail {
  id: number;
  title: string;
  subtitle?: string;
  description?: string;
  progress?: number;
  progress_percent?: number;
  quota?: number;
  filled_quota?: number;
  metricName?: string;
  typeName?: string;
  reportingName?: string;
  quotaString?: string;
  valueString?: string;
  chartData?: BarChartData[];
  aLatestProgress?: APIGoalProgressLog[];
  team?: APIUser[];
  creatorId?: number;
  portalId?: number;
  portalName?: string;
}

interface APIGoalProgressLog {
  id: number;
  users_id?: number;
  added_value?: number;
  note?: string;
  value?: number;
  timestamp?: string;
}

interface APIUser {
  id: number;
  name?: string;
  imageName?: string;
}

interface GoalDetailAPIResponse {
  result: APIGoalDetail;
}

interface ReportingIncrementsResponse {
  reportingIncrements: ReportingIncrement[];
}

// --- Composables & Initial Setup ---
const route = useRoute();
const router = useRouter();
const initialGoalId = Number(route.params.id);
const token = localStorage.getItem('jwtToken');
const currentUserId = Number(localStorage.getItem('userId'));
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'https://api.rep-app.com';
const s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/";

// --- State ---
const goal = ref<Goal | null>(null);
const team = ref<User[]>([]);
const feed = ref<Feed[]>([]);
const latestProgressLogs = ref<APIGoalProgressLog[]>([]);
const reportingIncrements = ref<ReportingIncrement[]>([]);
const selectedSegment = ref(0);
const activeSheet = ref<string | null>(null);
const showDeleteAlert = ref(false);
const chatCreationError = ref<string | null>(null);
const isCreatingTeamChat = ref(false);
const showChatSheet = ref(false);
const goalTeamChatId = ref<number | null>(null);
const showPaymentSheet = ref(false);
const isLoadingIncrements = ref(false);

// Default reporting increments (fallback)
const defaultReportingIncrements = [
  { id: 1, title: "Monthly" },
  { id: 2, title: "Weekly" },
  { id: 3, title: "Daily" }
];

// --- Methods ---
const goBack = () => router.back();

const navigateToProfile = (userId?: number) => {
  if (userId) router.push(`/profile/${userId}`);
};

const getUserIdForFeed = (feedItem: Feed): number | undefined => {
  return latestProgressLogs.value.find(log => log.id === feedItem.id)?.users_id;
};

const patchProfilePictureURL = (imageName?: string): string | undefined => {
  if (!imageName) return undefined;
  if (imageName.startsWith('http')) {
    return imageName;
  } else {
    return s3BaseURL + imageName;
  }
};

// Format a timestamp string to time only
const formatDateString = (isoString?: string): string => {
  if (!isoString) return "";
  
  try {
    // Try ISO format first
    const date = new Date(isoString);
    if (!isNaN(date.getTime())) {
      return new Intl.DateTimeFormat('en-US', {
        hour: 'numeric',
        minute: 'numeric',
        hour12: true
      }).format(date);
    }
    
    // Try fallback format
    const fallbackDate = new Date(isoString.replace(' ', 'T'));
    if (!isNaN(fallbackDate.getTime())) {
      return new Intl.DateTimeFormat('en-US', {
        hour: 'numeric',
        minute: 'numeric',
        hour12: true
      }).format(fallbackDate);
    }
  } catch (e) {
    console.error('Date parsing error:', e);
  }
  
  return isoString;
};

const loadGoalDetails = async () => {
  try {
    const res = await axios.get(
      `${apiBaseUrl}/api/goals/details?goals_id=${initialGoalId}&num_periods=7`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    const apiGoal: APIGoalDetail = res.data.result;
    
    // Map API goal to our Goal model
    goal.value = {
      id: apiGoal.id,
      title: apiGoal.title,
      subtitle: apiGoal.subtitle || "",
      description: apiGoal.description || "",
      progress: apiGoal.progress || 0,
      progressPercent: apiGoal.progress_percent || 0,
      quota: apiGoal.quota || 0,
      filledQuota: apiGoal.filled_quota || 0,
      metricName: apiGoal.metricName || "",
      typeName: apiGoal.typeName || "",
      reportingName: apiGoal.reportingName || "",
      quotaString: apiGoal.quotaString || "",
      valueString: apiGoal.valueString || "",
      chartData: apiGoal.chartData || [],
      creatorId: apiGoal.creatorId || 0,
      portalId: apiGoal.portalId,
      portalName: apiGoal.portalName || "Organization"
    };
    
    // Store latest progress logs for lookup
    latestProgressLogs.value = apiGoal.aLatestProgress || [];
    
    // Create a dictionary of team members by ID for easy lookup
    const teamDict = (apiGoal.team || []).reduce((acc, member) => {
      acc[member.id] = member;
      return acc;
    }, {} as Record<number, APIUser>);
    
    // Sort progress logs by timestamp (newest first)
    const sortedLogs = [...(apiGoal.aLatestProgress || [])].sort((a, b) => {
      const dateA = new Date(a.timestamp || "");
      const dateB = new Date(b.timestamp || "");
      return dateB.getTime() - dateA.getTime();
    });
    
    // Create feed items from logs
    feed.value = sortedLogs.slice(0, 20).map(log => {
      const apiUser = teamDict[log.users_id || 0];
      const userName = apiUser?.name || "User";
      const formattedDate = formatDateString(log.timestamp);
      const profilePicUrl = patchProfilePictureURL(apiUser?.imageName);
      
      return {
        id: log.id,
        userImageName: "profile_placeholder",
        userName: userName,
        line1: formattedDate,
        line2: `Value: ${Math.round(log.value || 0)}`,
        line3: log.note || "",
        line4: "",
        userProfilePictureURL: profilePicUrl
      };
    });
    
    // Map team members
    team.value = (apiGoal.team || []).map(apiUser => ({
      id: apiUser.id,
      fullName: apiUser.name || "User",
      profilePictureURL: patchProfilePictureURL(apiUser.imageName),
      imageName: apiUser.imageName || "profile_placeholder"
    }));
    
  } catch (error) {
    console.error("Failed to load goal details:", error);
  }
};

const loadReportingIncrements = async () => {
  if (isLoadingIncrements.value) return;
  isLoadingIncrements.value = true;
  
  try {
    const res = await axios.get(
      `${apiBaseUrl}/api/goals/reporting_increments`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    const data = res.data as ReportingIncrementsResponse;
    reportingIncrements.value = data.reportingIncrements;
  } catch (error) {
    console.error("Failed to load reporting increments:", error);
  } finally {
    isLoadingIncrements.value = false;
  }
};

const joinRecruitingGoal = async () => {
  activeSheet.value = null;
  
  try {
    await axios.post(
      `${apiBaseUrl}/api/goals/join_leave`,
      {
        aGoalsIDs: [goal.value?.id],
        todo: "join"
      },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    // Reload goal details to update team members
    loadGoalDetails();
  } catch (error) {
    console.error("Failed to join goal:", error);
  }
};

const openGoalTeamChat = async () => {
  if (goalTeamChatId.value) {
    showChatSheet.value = true;
    return;
  }
  
  if (!token) {
    chatCreationError.value = "Not authenticated.";
    return;
  }
  
  isCreatingTeamChat.value = true;
  chatCreationError.value = null;
  
  try {
    // Filter out current user from member IDs
    const memberIds = team.value
      .map(user => user.id)
      .filter(id => id !== currentUserId);
    
    const res = await axios.post(
      `${apiBaseUrl}/api/message/manage_chat`,
      {
        title: `Goal Team: ${goal.value?.title}`,
        aAddIDs: memberIds
      },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    if (res.data.chats_id) {
      goalTeamChatId.value = res.data.chats_id;
      showChatSheet.value = true;
    } else {
      throw new Error("Failed to get chat ID from server.");
    }
  } catch (error: any) {
    chatCreationError.value = error.message || "Failed to create chat.";
  } finally {
    isCreatingTeamChat.value = false;
  }
};

const confirmDelete = () => {
  activeSheet.value = null;
  setTimeout(() => {
    showDeleteAlert.value = true;
  }, 200);
};

const deleteGoal = async () => {
  showDeleteAlert.value = false;
  
  try {
    await axios.post(
      `${apiBaseUrl}/api/goals/delete`,
      { goals_id: goal.value?.id },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    goBack();
  } catch (error) {
    console.error("Failed to delete goal:", error);
  }
};

const handleSheetClose = () => {
  activeSheet.value = null;
  loadGoalDetails();
};

const handleTeamInvite = () => {
  activeSheet.value = null;
  loadGoalDetails();
};

const handleChatClose = () => {
  showChatSheet.value = false;
  // Additional cleanup for chat, if needed
};

// --- Lifecycle Hooks ---
onMounted(() => {
  if (!token) {
    router.push('/login');
    return;
  }
  
  // Small delay to match Swift's DispatchQueue.main.asyncAfter
  setTimeout(() => {
    loadGoalDetails();
    loadReportingIncrements();
  }, 100);
});

// --- Component Definitions ---

// GoalSegmentedPicker Component
const GoalSegmentedPicker = defineComponent({
  props: {
    segments: { type: Array as () => string[], required: true },
    selectedIndex: { type: Number, default: 0 }
  },
  emits: ['update:selectedIndex'],
  setup(props, { emit }) {
    return () => h('div', {
      class: 'flex border border-black rounded overflow-hidden'
    }, props.segments.map((segment, index) => 
      h('button', {
        key: index,
        class: [
          'flex-1 py-1.5 font-medium',
          props.selectedIndex === index ? 'bg-black text-white' : 'bg-white text-black',
          index < props.segments.length - 1 ? 'border-r border-[#e4e4e4]' : ''
        ],
        onClick: () => emit('update:selectedIndex', index)
      }, segment)
    ));
  }
});

// FeedCell Component
const FeedCell = defineComponent({
  props: {
    feed: { type: Object as () => Feed, required: true }
  },
  emits: ['profileTap'],
  setup(props, { emit }) {
    return () => h('div', {
      class: 'flex items-start space-x-4 py-2'
    }, [
      h('button', {
        onClick: () => emit('profileTap'),
        class: 'flex-shrink-0'
      }, [
        props.feed.userProfilePictureURL 
          ? h('img', {
              src: props.feed.userProfilePictureURL,
              class: 'w-20 h-20 rounded-full object-cover'
            })
          : h('div', {
              class: 'w-20 h-20 rounded-full bg-gray-300'
            })
      ]),
      h('div', {
        class: 'flex-1 pt-1 space-y-1'
      }, [
        h('div', { class: 'font-bold' }, props.feed.userName),
        h('div', { class: 'text-xs' }, props.feed.line1),
        h('div', { class: 'text-sm' }, props.feed.line2),
        h('div', { class: 'text-sm' }, `Note: ${props.feed.line3 || 'NA'}`),
        h('div', { class: 'text-sm' }, 'Attachments: NA')
      ])
    ]);
  }
});

// TeamCell Component
const TeamCell = defineComponent({
  props: {
    user: { type: Object as () => User, required: true }
  },
  setup(props, { emit }) {
    return () => h('div', {
      class: 'flex items-center space-x-3 py-2 cursor-pointer',
      onClick: () => emit('click')
    }, [
      props.user.profilePictureURL 
        ? h('img', {
            src: props.user.profilePictureURL,
            class: 'w-10 h-10 rounded-full object-cover'
          })
        : h('div', {
            class: 'w-10 h-10 rounded-full bg-gray-300'
          }),
      h('div', { class: 'font-medium' }, props.user.fullName || '')
    ]);
  }
});

// LargeBarChartView Component
const LargeBarChartView = defineComponent({
  props: {
    data: { type: Array as () => BarChartData[], required: true },
    quota: { type: Number, default: 1 }
  },
  setup(props) {
    return () => h('div', {
      class: 'h-[260px] p-4 bg-white'
    }, [
      h('div', {
        class: 'flex items-end h-full'
      }, props.data.map(item => 
        h('div', {
          key: item.id,
          class: 'flex flex-col items-center'
        }, [
          h('div', { class: 'text-xs mb-0.5' }, item.valueLabel),
          h('div', { class: 'flex-1' }),
          h('div', {
            class: 'w-10 bg-[#8cc65d] rounded',
            style: {
              height: `${Math.min(100, (item.value / Math.max(0.1, props.quota)) * 100)}%`
            }
          }),
          h('div', { class: 'text-xs mt-0.5 w-8 text-center truncate' }, item.bottomLabel)
        ])
      ))
    ]);
  }
});

// BottomGoalBar Component
const BottomGoalBar = defineComponent({
  emits: ['add', 'message'],
  setup(props, { emit }) {
    return () => h('div', {
      class: 'h-[51px] flex items-center justify-between px-4 border-t border-[#e4e4e4] bg-white'
    }, [
      h('button', {
        class: 'w-[291px] h-[41px] bg-[#8cc65d] rounded-md shadow flex items-center justify-center',
        onClick: () => emit('add')
      }, [
        h('svg', {
          class: 'w-5 h-5 text-white',
          xmlns: 'http://www.w3.org/2000/svg',
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
        ])
      ]),
      h('button', {
        class: 'text-black',
        onClick: () => emit('message')
      }, [
        h('svg', {
          class: 'w-5 h-5',
          xmlns: 'http://www.w3.org/2000/svg',
          fill: 'none',
          viewBox: '0 0 24 24',
          stroke: 'currentColor'
        }, [
          h('path', {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z'
          })
        ])
      ])
    ]);
  }
});

// Note: The UpdateGoalSheet, EditGoalPage, GroupChatView, and PayTransactionView components
// would be imported from separate files in a real implementation
</script>

<style scoped>
.text-secondary {
  color: rgba(60, 60, 67, 0.6);
}

.text-[#8cc65d] {
  color: #8cc65d;
}

.bg-[#8cc65d] {
  background-color: #8cc65d;
}

.border-[#8cc65d] {
  border-color: #8cc65d;
}

.border-[#e4e4e4] {
  border-color: #e4e4e4;
}
</style>