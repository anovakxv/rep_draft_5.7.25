<!--
  GoalsDetailView.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="goal-detail-container flex flex-col h-screen bg-white">
    <!-- Loading State -->
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <div class="animate-spin h-8 w-8 border-4 border-rep-green border-t-transparent rounded-full"></div>
    </div>

    <!-- Error State -->
    <div v-else-if="errorMessage" class="flex-1 flex flex-col items-center justify-center p-4">
      <div class="text-red-500 text-center mb-4">{{ errorMessage }}</div>
      <button @click="loadGoalDetails" class="px-4 py-2 bg-rep-green text-white rounded-lg">
        Retry
      </button>
    </div>

    <!-- Main Content -->
    <div v-else-if="goal" class="flex flex-col flex-1 min-h-0">
      <!-- Custom Top Bar (Mobile Only) -->
      <header class="md:hidden flex items-center justify-between px-4 border-b border-gray-200 shrink-0" style="background-color: #f7f7f7; min-height: 44px;">
        <button @click="goBack" class="p-2 -ml-2" style="color: #8cc65d">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <div class="flex-1 flex flex-col items-center justify-center py-1">
          <h1 class="font-bold text-lg truncate max-w-full px-2">{{ goal?.title || 'Goal Details' }}</h1>
          <!-- Portal Link (only show if goal has associated portal) -->
          <button
            v-if="goal?.portalId && goal?.portalName"
            @click="navigateToPortal(goal.portalId)"
            class="flex items-center gap-1 mt-0.5"
          >
            <span class="text-xs truncate max-w-[200px]" style="color: #006600;">{{ goal.portalName }}</span>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3" style="color: #006600;">
              <path stroke-linecap="round" stroke-linejoin="round" d="M7 17L17 7M17 7H7M17 7v10" />
            </svg>
          </button>
        </div>
        <div class="w-10"></div> <!-- Spacer -->
      </header>

      <!-- Two Column Layout (Desktop) / Single Column (Mobile) -->
      <div class="flex flex-col flex-1 min-h-0 md:flex-row">
        <!-- LEFT COLUMN (Desktop): Dashboard Panel (40% width) -->
        <div class="hidden md:flex md:flex-col md:w-[40%] md:border-r md:border-gray-200 md:overflow-y-auto">
          <!-- Goal Header -->
          <div class="px-6 py-4 border-b border-gray-200">
            <button @click="goBack" class="mb-3 inline-flex items-center gap-2" style="color: #8cc65d">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
              </svg>
              <span class="text-sm font-medium">Back</span>
            </button>
            <h1 class="font-bold text-2xl mb-2">{{ goal?.title || 'Goal Details' }}</h1>
            <button
              v-if="goal?.portalId && goal?.portalName"
              @click="navigateToPortal(goal.portalId)"
              class="flex items-center gap-1"
            >
              <span class="text-sm" style="color: #006600;">{{ goal.portalName }}</span>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3" style="color: #006600;">
                <path stroke-linecap="round" stroke-linejoin="round" d="M7 17L17 7M17 7H7M17 7v10" />
              </svg>
            </button>
          </div>

          <!-- Progress Bar and Metrics -->
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-sm font-semibold text-gray-700 mb-3">Progress</h2>
            <!-- Progress Bar -->
            <div class="relative bg-gray-200 rounded-none h-[34px] overflow-hidden mb-3">
              <div
                class="bg-rep-green h-full transition-all duration-300 ease-out"
                :style="{ width: `${Math.min(100, Math.max(0, goal.progress * 100))}%` }"
              ></div>
            </div>

            <!-- Metrics Info -->
            <div class="text-sm text-gray-600 space-y-2">
              <div class="flex justify-between">
                <span class="font-medium">Quota:</span>
                <span>{{ Math.round(goal.quota) }}</span>
              </div>
              <div class="flex justify-between">
                <span class="font-medium">Progress:</span>
                <span>{{ Math.round(goal.filledQuota) }}</span>
              </div>
              <div class="flex justify-between">
                <span class="font-medium">Metric:</span>
                <span>{{ goal.metricName }}</span>
              </div>
              <div class="flex justify-between">
                <span class="font-medium">Type:</span>
                <span>{{ goal.typeName }}</span>
              </div>
              <div v-if="goal.subtitle && goal.subtitle.trim()" class="text-secondary text-sm mt-2 pt-2 border-t border-gray-200">
                {{ goal.subtitle }}
              </div>
              <div v-if="goal.description && goal.description.trim()" class="text-secondary text-sm">
                {{ goal.description }}
              </div>
            </div>
          </div>

          <!-- Team Preview -->
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-sm font-semibold text-gray-700 mb-3">Team Members</h2>
            <div v-if="team.length === 0" class="text-sm text-gray-500">
              No team members yet.
            </div>
            <div v-else class="space-y-2">
              <TeamCell
                v-for="user in team.slice(0, 5)"
                :key="user.id"
                :user="user"
                @click="navigateToProfile(user.id)"
              />
              <button
                v-if="team.length > 5"
                @click="selectedSegment = 2"
                class="text-sm font-medium w-full text-left py-2"
                style="color: #8cc65d"
              >
                View all {{ team.length }} members →
              </button>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="px-6 py-4 space-y-3 mt-auto">
            <button
              @click="openGoalTeamChat"
              class="w-full flex items-center justify-center h-12 rounded-lg border-2 transition-transform hover:scale-105 active:scale-95"
              style="border-color: #8cc65d; color: #8cc65d; background-color: white;"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
              </svg>
              Message Team
            </button>

            <button
              @click="handleAddAction"
              class="w-full flex items-center justify-center h-12 rounded-lg transition-transform hover:scale-105 active:scale-95"
              style="background-color: #8cc65d; color: white;"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
              </svg>
              Add Action
            </button>

            <!-- Support Button (for Fund/Sales goals) -->
            <button
              v-if="goal.typeName === 'Fund' || goal.typeName === 'Sales'"
              @click="showPaymentSheet = true"
              class="w-full px-5 py-3 bg-white border-2 rounded-lg shadow-md flex items-center justify-center gap-2 font-bold transition-transform hover:scale-105 active:scale-95"
              style="border-color: #006600; color: #006600;"
            >
              <span class="text-[22px]">$</span>
              <span>Support</span>
            </button>
          </div>
        </div>

        <!-- RIGHT COLUMN (Desktop) / FULL VIEW (Mobile): Content View (60% width) -->
        <div class="flex flex-col flex-1 min-h-0 md:w-[60%]">
          <!-- Mobile: Progress Bar and Metrics Section -->
          <div class="md:hidden p-4 border-b border-gray-200">
            <!-- Progress Bar -->
            <div class="relative bg-gray-200 rounded-none h-[34px] overflow-hidden mb-2">
              <div
                class="bg-rep-green h-full transition-all duration-300 ease-out"
                :style="{ width: `${Math.min(100, Math.max(0, goal.progress * 100))}%` }"
              ></div>
            </div>

            <!-- Metrics Info -->
            <div class="text-sm text-gray-600 space-y-1">
              <div class="flex justify-between">
                <span>Metric: {{ goal.metricName }}</span>
                <span>Goal Type: {{ goal.typeName }}</span>
              </div>
              <div class="flex justify-between">
                <span>Quota: {{ Math.round(goal.quota) }}</span>
                <span>Progress: {{ Math.round(goal.filledQuota) }}</span>
              </div>
              <div v-if="goal.subtitle && goal.subtitle.trim()" class="text-secondary text-base mt-1">
                {{ goal.subtitle }}
              </div>
              <div v-if="goal.description && goal.description.trim()" class="text-secondary text-base">
                {{ goal.description }}
              </div>
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
          <div class="flex-1 overflow-y-auto pb-24 md:pb-4">
            <!-- Feed Tab -->
            <div v-if="selectedSegment === 0" class="px-4">
              <div v-if="feed.length === 0" class="text-center text-gray-500 py-10">
                No feed items yet.
              </div>
              <div v-else class="space-y-2">
                <FeedCell
                  v-for="feedItem in feed"
                  :key="feedItem.id"
                  :feed="feedItem"
                  @profile-tap="navigateToProfile(getUserIdForFeed(feedItem))"
                />
              </div>
            </div>

            <!-- Report Tab -->
            <div v-else-if="selectedSegment === 1" class="px-4">
              <div v-if="goal.chartData && goal.chartData.length > 0">
                <LargeBarChartView :data="goal.chartData" :quota="goal.quota" />
              </div>
              <div v-else class="text-center text-gray-500 py-10">
                No chart data available.
              </div>
            </div>

            <!-- Team Tab -->
            <div v-else-if="selectedSegment === 2" class="px-4">
              <div v-if="team.length === 0" class="text-center text-gray-500 py-10">
                No team members yet.
              </div>
              <div v-else class="space-y-2">
                <TeamCell
                  v-for="user in team"
                  :key="user.id"
                  :user="user"
                  @click="navigateToProfile(user.id)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Fixed Bottom Bar (Mobile Only) -->
      <div class="md:hidden fixed bottom-0 left-0 right-0 z-20 flex justify-center" :class="{ 'scale-100': !isCreatingTeamChat, 'scale-0': isCreatingTeamChat }">
        <div class="w-full bg-white border-t shadow-lg flex items-center justify-center gap-3 py-1.5 px-4" style="max-width: 768px; border-color: #e5e7eb;">
          <!-- Message Button -->
          <button
            @click="openGoalTeamChat"
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
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Floating Support Button (Mobile Only) - White background with dark green border (matching iOS) -->
    <!-- Positioned bottom-right for Fund/Sales goals (matching iOS .bottomTrailing) -->
    <div
      v-if="goal && (goal.typeName === 'Fund' || goal.typeName === 'Sales')"
      class="md:hidden fixed bottom-0 left-0 right-0 z-20 flex justify-center pointer-events-none"
      style="bottom: 70px"
    >
      <div class="w-full relative flex justify-end pr-5" style="max-width: 768px">
        <button
          @click="showPaymentSheet = true"
          class="px-5 py-2.5 bg-white border-2 rounded-lg shadow-lg flex items-center gap-2 font-bold transition-transform pointer-events-auto"
          style="border-color: #006600; color: #006600; box-shadow: 3px 5px 7px rgba(26, 26, 26, 0.4)"
          :class="{ 'scale-100': !isCreatingTeamChat, 'scale-0': isCreatingTeamChat }"
        >
          <span class="text-[22px]">$</span>
          <span>Support</span>
        </button>
      </div>
    </div>

    <!-- Team Chat Loading Overlay - EXACTLY matching Swift -->
    <div v-if="isCreatingTeamChat" class="fixed inset-0 bg-black bg-opacity-15 z-40 flex items-center justify-center">
      <div class="bg-white p-4 rounded-xl shadow-lg flex flex-col items-center gap-3">
        <div class="animate-spin h-6 w-6 border-2 border-rep-green border-t-transparent rounded-full"></div>
        <div class="text-center">Opening Team Chat...</div>
      </div>
    </div>

    <!-- Action Sheet - iOS style design -->
    <transition name="fade">
      <div v-if="activeSheet === 'action'" @click="activeSheet = null" class="fixed inset-0 z-50 flex items-end justify-center">
        <div class="bg-black bg-opacity-50 w-full" style="position: absolute; top: 0; bottom: 0; left: 50%; transform: translateX(-50%);"></div>
        <div @click.stop class="bg-white w-full rounded-t-2xl p-6 relative z-10" style="max-height: 80vh; overflow-y: auto;">
          <div class="flex flex-col items-center space-y-6">
            <!-- Join Team (only if not on team and not creator, for Recruiting goals) -->
            <button
              v-if="goal && goal.typeName === 'Recruiting' && !isUserOnTeam && goal.creatorId !== currentUserId"
              @click="joinRecruitingGoal"
              class="text-[#8cc65d] font-bold text-[28px] py-3"
            >
              Join Team
            </button>

            <!-- Invite to Team (only if on team or is creator) -->
            <button
              v-if="goal && (isUserOnTeam || goal.creatorId === currentUserId)"
              @click="handleInviteTeam"
              class="text-[#8cc65d] font-bold text-[28px] py-3"
            >
              Invite to Team
            </button>

            <!-- Update Progress (only for non-Recruiting goals) -->
            <button
              v-if="goal && goal.typeName !== 'Recruiting'"
              @click="handleUpdateProgress"
              class="text-[#8cc65d] font-bold text-[28px] py-3"
            >
              Update Progress
            </button>

            <!-- Edit Goal (always show) -->
            <button
              @click="handleEditGoal"
              class="text-[#8cc65d] font-bold text-[28px] py-3"
            >
              Edit Goal
            </button>

            <!-- Delete Goal -->
            <button
              @click="confirmDelete"
              class="text-red-600 text-[16px] py-3"
            >
              Delete Goal
            </button>

            <!-- Cancel -->
            <button
              @click="activeSheet = null"
              class="w-full text-center text-gray-500 text-[16px] py-3 mt-4"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </transition>

    <!-- Update Goal Sheet -->
    <UpdateGoalSheet
      v-if="activeSheet === 'updateGoal'"
      :goal-id="goal?.id || 0"
      :quota="goal?.quota || 0"
      :metric-name="goal?.metricName || ''"
      @close="handleSheetClose"
    />

    <!-- Edit Goal Page - Only if user is creator -->
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
      :goal-id="goal?.id || 0"
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

    <!-- Payment Sheet - EXACTLY matching Swift -->
    <div v-if="showPaymentSheet" class="fixed inset-0 z-50 bg-white">
      <PayTransactionView
        :portal-id="goal?.portalId || 0"
        :portal-name="goal?.portalName || 'Portal'"
        :goal-id="goal?.id || 0"
        :goal-name="goal?.title || ''"
        :transaction-type="goal?.typeName === 'Fund' ? 'donation' : 'payment'"
        @close="showPaymentSheet = false"
        @payment-success="handlePaymentSuccess"
      />
    </div>

    <!-- Delete Alert - EXACTLY matching Swift -->
    <transition name="fade">
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
    </transition>

    <!-- Chat Error Alert - EXACTLY matching Swift -->
    <transition name="fade">
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
    </transition>

    <!-- Profile Navigation (Hidden NavigationLink equivalent) -->
    <div v-if="selectedProfileUserId" class="hidden">
      <!-- This would trigger navigation to profile -->
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, defineComponent, defineAsyncComponent, h, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '@/pages/utils/api';
import { isAuthenticated } from '@/utils/auth';

// Lazy load components with Tailwind @apply errors to prevent blocking page load
const UpdateGoalSheet = defineAsyncComponent(() => import('./Update_Goal.vue'));
const EditGoalPage = defineAsyncComponent(() => import('./EditGoal.vue'));
// Regular imports for components without errors
import InviteTeamSheet from './InviteTeamSheet.vue';
import GroupChatView from '../Messaging/Chat_Group.vue';
import PayTransactionView from '../MainPages/PayTransaction.vue';

// --- Types & Interfaces (EXACTLY matching Swift models) ---
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
  full_name?: string;  // For display
  name?: string;  // Backend sometimes returns this for team members
  fname?: string;
  lname?: string;
  username?: string;
  about?: string;
  broadcast?: string;
  profile_picture_url?: string;  // Backend returns snake_case
  imageName?: string;  // Backend returns this for team members
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

interface Attachment {
  id: number;
  url: string;
  isImage: boolean;
  fileName: string;
  note: string;
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
  attachments: Attachment[];
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

interface APIAttachment {
  id: number;
  file_url?: string;
  file_name?: string;
  is_image?: boolean;
  note?: string;
}

interface APIGoalProgressLog {
  id: number;
  users_id?: number;
  added_value?: number;
  note?: string;
  value?: number;
  timestamp?: string;
  aAttachments?: APIAttachment[];
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
const currentUserId = Number(localStorage.getItem('userId'));
const token = localStorage.getItem('jwtToken');
const s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/";

// --- State (EXACTLY matching Swift ViewModel) ---
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
const selectedProfileUserId = ref<number | null>(null);
const isLoading = ref(true);
const errorMessage = ref<string | null>(null);

// Default reporting increments (fallback)
const defaultReportingIncrements = [
  { id: 1, title: "Monthly" },
  { id: 2, title: "Weekly" },
  { id: 3, title: "Daily" }
];

// Computed: Check if current user is on the team
const isUserOnTeam = computed(() => {
  return team.value.some(member => member.id === currentUserId);
});

// --- Helper Methods (EXACTLY matching Swift ViewModel) ---
const patchProfilePictureURL = (imageName?: string): string | undefined => {
  if (!imageName || imageName.trim() === '') return undefined;
  if (imageName.startsWith('http')) {
    return imageName;
  } else {
    return s3BaseURL + imageName;
  }
};

const getUserIdForFeed = (feedItem: Feed): number | undefined => {
  return latestProgressLogs.value.find(log => log.id === feedItem.id)?.users_id;
};

// Parse timestamp string to Date (EXACTLY matching Swift)
const parseTimestamp = (isoString?: string): Date => {
  if (!isoString) return new Date(0); // Date.distantPast equivalent

  try {
    // If already has timezone info (ends with Z or has +/-), parse directly
    if (isoString.includes('Z') || /[+-]\d{2}:\d{2}$/.test(isoString)) {
      const date = new Date(isoString);
      if (!isNaN(date.getTime())) {
        return date;
      }
    }

    // Backend sends "yyyy-MM-dd HH:mm:ss" in UTC without timezone suffix
    // Add 'Z' to indicate UTC, then parse (will auto-convert to local timezone)
    const utcString = isoString.replace(' ', 'T') + (isoString.includes('T') || isoString.includes('Z') ? '' : 'Z');
    const date = new Date(utcString);
    if (!isNaN(date.getTime())) {
      return date;
    }
  } catch (e) {
    console.error('Date parsing error:', e);
  }

  return new Date(0);
};

// Format a timestamp string to time only (EXACTLY matching Swift)
const formatDateString = (isoString?: string): string => {
  if (!isoString) return "";
  
  try {
    const date = parseTimestamp(isoString);
    if (date.getTime() === 0) return isoString;
    
    return new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: 'numeric',
      hour12: true
    }).format(date);
  } catch (e) {
    console.error('Date formatting error:', e);
    return isoString;
  }
};

// --- Navigation Methods ---
const goBack = () => router.back();

const handleAddAction = () => {
  // Allow public users to view the action menu
  // Authentication will be checked when they select specific actions
  activeSheet.value = 'action';
};

const navigateToProfile = (userId?: number) => {
  if (userId) {
    selectedProfileUserId.value = userId;
    router.push(`/profile/${userId}`);
  }
};

const navigateToPortal = (portalId: number) => {
  router.push(`/portal/${portalId}`);
};

// --- API Methods (EXACTLY matching Swift ViewModel) ---
const loadGoalDetails = async () => {
  isLoading.value = true;
  errorMessage.value = null;
  const authenticated = isAuthenticated();

  try {
    let res;

    // Use public endpoint for unauthenticated users
    if (!authenticated) {
      res = await api.get(`/api/public/goal/${initialGoalId}`);
    } else {
      res = await api.get(
        `/api/goals/details?goals_id=${initialGoalId}&num_periods=7`
      );
    }

    const apiGoal: APIGoalDetail = res.data.result;

    // Map API goal to our Goal model (EXACTLY matching Swift)
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
      portalName: apiGoal.portalName || "Portal"
    };
    
    // Store latest progress logs for lookup
    latestProgressLogs.value = apiGoal.aLatestProgress || [];
    
    // Create a dictionary of team members by ID for easy lookup (EXACTLY matching Swift)
    const teamDict = (apiGoal.team || []).reduce((acc, member) => {
      acc[member.id] = member;
      return acc;
    }, {} as Record<number, APIUser>);
    
    // Get all progress logs and sort by timestamp (newest first) - EXACTLY matching Swift
    const allLogs = apiGoal.aLatestProgress || [];
    const sortedLogs = allLogs.sort((log1, log2) => {
      const date1 = parseTimestamp(log1.timestamp);
      const date2 = parseTimestamp(log2.timestamp);
      return date2.getTime() - date1.getTime();
    });
    
    // Limit to 20 items like Swift .prefix(20)
    const limitedLogs = sortedLogs.slice(0, 20);
    
    // Create feed items from logs (EXACTLY matching Swift)
    feed.value = limitedLogs.map(log => {
      const apiUser = teamDict[log.users_id || 0];
      // Show "Public Supporter" for anonymous/guest contributions (user_id is NULL)
      const userName = log.users_id ? (apiUser?.name || "User") : "Public Supporter";

      // Debug logging for timestamp parsing
      if (log.id === limitedLogs[0]?.id) {
        console.log('[GoalsDetailView] First log timestamp:', log.timestamp);
        console.log('[GoalsDetailView] Parsed date:', parseTimestamp(log.timestamp));
        console.log('[GoalsDetailView] Formatted:', formatDateString(log.timestamp));
      }

      const formattedDate = formatDateString(log.timestamp);
      // Use generic placeholder for public supporters
      const profilePicUrl = log.users_id ? patchProfilePictureURL(apiUser?.imageName) : "profile_placeholder";

      // Process attachments (EXACTLY matching Swift)
      const attachments: Attachment[] = (log.aAttachments || []).map(attachment => ({
        id: attachment.id,
        url: attachment.file_url || '',
        isImage: attachment.is_image ?? true,
        fileName: attachment.file_name || 'File',
        note: attachment.note || ''
      })).filter(att => att.url); // Filter out attachments without URLs

      // Show only the individual transaction value, not the cumulative (EXACTLY matching Swift)
      const transactionValue = log.added_value || 0;
      let valueString: string;
      if (goal.value?.typeName === "Fund" || goal.value?.typeName === "Sales") {
        valueString = `Value: $${Math.round(transactionValue)}`;
      } else {
        valueString = `Value: ${Math.round(transactionValue)}`;
      }

      return {
        id: log.id,
        userImageName: "profile_placeholder",
        userName: userName,
        line1: formattedDate,
        line2: valueString,
        line3: log.note || "",
        line4: "",
        userProfilePictureURL: profilePicUrl,
        attachments: attachments
      };
    });
    
    // Map team members (EXACTLY matching Swift)
    team.value = (apiGoal.team || []).map(apiUser => ({
      id: apiUser.id,
      full_name: apiUser.name || "User",  // Backend returns 'name' for team members
      profile_picture_url: patchProfilePictureURL(apiUser.imageName),
      imageName: apiUser.imageName || "profile_placeholder"
    }));

    isLoading.value = false;

  } catch (error: any) {
    console.error("Failed to load goal details:", error);
    errorMessage.value = error.response?.data?.error || 'Failed to load goal details. Please try again.';
    isLoading.value = false;
  }
};

const loadReportingIncrements = async () => {
  if (isLoadingIncrements.value) return;
  isLoadingIncrements.value = true;
  
  try {
    const res = await api.get('/api/goals/reporting_increments');

    const data = res.data as ReportingIncrementsResponse;
    reportingIncrements.value = data.reportingIncrements;
  } catch (error) {
    console.error("Failed to load reporting increments:", error);
  } finally {
    isLoadingIncrements.value = false;
  }
};

// Join Recruiting Goal (EXACTLY matching Swift)
const joinRecruitingGoal = async () => {
  // Check authentication before allowing join
  if (!isAuthenticated()) {
    activeSheet.value = null;
    router.push({
      path: '/register',
      query: { returnTo: `/goal/${initialGoalId}` }
    });
    return;
  }

  activeSheet.value = null;

  try {
    const res = await api.post(
      '/api/goals/join_leave',
      {
        aGoalsIDs: [goal.value?.id],
        todo: "join"
      }
    );

    // Check if response indicates success (matching Swift logic)
    const goalIdStr = goal.value?.id?.toString() || '0';
    if (res.data?.result?.[goalIdStr] === "ok") {
      // Reload goal details to update team members
      loadGoalDetails();
    }
  } catch (error) {
    console.error("Failed to join goal:", error);
  }
};

// Open Goal Team Chat (EXACTLY matching Swift)
const openGoalTeamChat = async () => {
  if (!isAuthenticated()) {
    router.push({
      path: '/register',
      query: { returnTo: `/goal/${initialGoalId}` }
    });
    return;
  }

  if (isCreatingTeamChat.value) return;

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
    // Filter out current user from member IDs (EXACTLY matching Swift)
    const memberIds = team.value
      .map(user => user.id)
      .filter(id => id !== currentUserId);

    const res = await api.post(
      '/api/message/manage_chat',
      {
        title: `Goal Team: ${goal.value?.title}`,
        aAddIDs: memberIds
      }
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

// Handler for Invite to Team action
const handleInviteTeam = () => {
  if (!isAuthenticated()) {
    activeSheet.value = null;
    router.push({
      path: '/register',
      query: { returnTo: `/goal/${initialGoalId}` }
    });
    return;
  }
  activeSheet.value = 'inviteTeam';
};

// Handler for Update Progress action
const handleUpdateProgress = () => {
  if (!isAuthenticated()) {
    activeSheet.value = null;
    router.push({
      path: '/register',
      query: { returnTo: `/goal/${initialGoalId}` }
    });
    return;
  }
  activeSheet.value = 'updateGoal';
};

// Handler for Edit Goal action
const handleEditGoal = () => {
  if (!isAuthenticated()) {
    activeSheet.value = null;
    router.push({
      path: '/register',
      query: { returnTo: `/goal/${initialGoalId}` }
    });
    return;
  }
  activeSheet.value = 'editGoal';
};

const confirmDelete = () => {
  // Check authentication before allowing delete
  if (!isAuthenticated()) {
    activeSheet.value = null;
    router.push({
      path: '/register',
      query: { returnTo: `/goal/${initialGoalId}` }
    });
    return;
  }

  activeSheet.value = null;
  setTimeout(() => {
    showDeleteAlert.value = true;
  }, 200);
};

const deleteGoal = async () => {
  showDeleteAlert.value = false;
  
  try {
    const res = await api.post(
      '/api/goals/delete',
      { goals_id: goal.value?.id }
    );

    // Check for successful response (EXACTLY matching Swift)
    if (res.status === 200) {
      goBack();
    }
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

const handlePaymentSuccess = () => {
  // Close payment sheet
  showPaymentSheet.value = false;

  // Reload goal details to show new payment in feed
  console.log('[GoalsDetailView] Payment successful, reloading goal details');
  loadGoalDetails();
};

const handleChatClose = () => {
  showChatSheet.value = false;

  // Clean up chat resources (EXACTLY matching Swift onDismiss)
  if (goalTeamChatId.value) {
    // Equivalent to RealtimeSocketManager.shared.leave(chatId:)
    // and NotificationCenter.default.post cleanup
    console.log(`Cleaning up chat ${goalTeamChatId.value}`);
  }
};

// --- Lifecycle Hooks (EXACTLY matching Swift .onAppear) ---
onMounted(() => {
  // Allow public users to view goal details
  // Authentication is checked on protected actions (Message, Add)

  // Small delay to match Swift's DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
  setTimeout(() => {
    loadGoalDetails();

    // Only load reporting increments if authenticated (needed for editing goals)
    if (isAuthenticated()) {
      loadReportingIncrements();
    }
  }, 100);
});

// --- Component Definitions (EXACTLY matching Swift UI components) ---

// GoalSegmentedPicker Component (EXACTLY matching Swift)
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
          'flex-1 py-1.5 font-medium transition-colors',
          props.selectedIndex === index ? 'bg-black text-white' : 'bg-white text-black',
          index < props.segments.length - 1 ? 'border-r border-gray-300' : ''
        ],
        onClick: () => emit('update:selectedIndex', index)
      }, segment)
    ));
  }
});

// FeedCell Component (EXACTLY matching Swift)
const FeedCell = defineComponent({
  props: {
    feed: { type: Object as () => Feed, required: true }
  },
  emits: ['profileTap'],
  setup(props, { emit }) {
    const getInitials = (name: string): string => {
      const parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      }
      return name.substring(0, 2).toUpperCase();
    };

    return () => h('div', {
      class: 'flex items-start space-x-4 py-2'
    }, [
      h('button', {
        onClick: () => emit('profileTap'),
        class: 'flex-shrink-0'
      }, [
        props.feed.userProfilePictureURL?.trim() && !props.feed.userProfilePictureURL.includes('profile_placeholder')
          ? h('img', {
              src: props.feed.userProfilePictureURL,
              class: 'w-20 h-20 rounded-full object-cover',
              onError: (e: Event) => {
                // Hide broken image and show initials fallback
                const target = e.target as HTMLImageElement;
                target.style.display = 'none';
              }
            })
          : h('div', {
              class: 'w-20 h-20 rounded-full bg-gray-300 flex items-center justify-center text-white font-semibold text-2xl'
            }, getInitials(props.feed.userName))
      ]),
      h('div', {
        class: 'flex-1 pt-1 space-y-1'
      }, [
        h('div', { class: 'font-bold' }, props.feed.userName),
        h('div', { class: 'text-xs text-gray-600' }, props.feed.line1),
        h('div', { class: 'text-sm' }, props.feed.line2),
        h('div', { class: 'text-sm' }, `Note: ${props.feed.line3 || 'NA'}`),
        // Display attachments if any (matching Swift implementation)
        props.feed.attachments && props.feed.attachments.length > 0
          ? h('div', {
              class: 'overflow-x-auto py-2',
              style: { '-webkit-overflow-scrolling': 'touch' }
            }, [
              h('div', {
                class: 'flex gap-3'
              }, props.feed.attachments.map(attachment =>
                h('div', {
                  key: attachment.id,
                  class: 'flex flex-col gap-1 flex-shrink-0'
                }, [
                  attachment.isImage
                    ? h('img', {
                        src: attachment.url,
                        class: 'w-[100px] h-[100px] object-cover rounded-lg',
                        alt: attachment.fileName
                      })
                    : h('div', {
                        class: 'w-[100px] h-[100px] flex items-center justify-center bg-gray-100 rounded-lg'
                      }, [
                        h('svg', {
                          xmlns: 'http://www.w3.org/2000/svg',
                          class: 'w-12 h-12 text-gray-500',
                          fill: 'currentColor',
                          viewBox: '0 0 20 20'
                        }, [
                          h('path', {
                            'fill-rule': 'evenodd',
                            d: 'M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z',
                            'clip-rule': 'evenodd'
                          })
                        ])
                      ]),
                  attachment.note
                    ? h('div', {
                        class: 'text-xs text-gray-600 w-[100px] line-clamp-2'
                      }, attachment.note)
                    : null
                ].filter(Boolean))
              ))
            ])
          : null
      ].filter(Boolean))
    ]);
  }
});

// TeamCell Component (EXACTLY matching Swift)
const TeamCell = defineComponent({
  props: {
    user: { type: Object as () => User, required: true }
  },
  emits: ['click'],
  setup(props, { emit }) {
    const getInitials = (name: string): string => {
      const parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      }
      return name.substring(0, 2).toUpperCase();
    };

    return () => h('div', {
      class: 'flex items-center space-x-3 py-2 cursor-pointer hover:bg-gray-50 transition-colors',
      onClick: () => emit('click')
    }, [
      props.user.profile_picture_url?.trim() && !props.user.profile_picture_url.includes('profile_placeholder')
        ? h('img', {
            src: props.user.profile_picture_url,
            class: 'w-10 h-10 rounded-full object-cover',
            onError: (e: Event) => {
              // Replace with initials on error
              const target = e.target as HTMLImageElement;
              const parent = target.parentElement;
              if (parent) {
                target.remove();
                const initialsDiv = document.createElement('div');
                initialsDiv.className = 'w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white font-semibold text-sm';
                initialsDiv.textContent = getInitials(props.user.full_name || 'User');
                parent.appendChild(initialsDiv);
              }
            }
          })
        : h('div', {
            class: 'w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white font-semibold text-sm'
          }, getInitials(props.user.full_name || 'User')),
      h('div', { class: 'font-medium' }, props.user.full_name || 'User')
    ]);
  }
});

// LargeBarChartView Component (EXACTLY matching Swift - with responsive scaling for desktop/tablet)
const LargeBarChartView = defineComponent({
  props: {
    data: { type: Array as () => BarChartData[], required: true },
    quota: { type: Number, default: 1 }
  },
  setup(props) {
    return () => h('div', {
      // Responsive container height: mobile 260px -> tablet 340px -> desktop 400px (scaled down)
      class: 'h-[260px] md:h-[340px] lg:h-[400px] p-4 md:p-5 lg:p-6 bg-white'
    }, [
      h('div', {
        // Responsive chart area - Mobile optimized, desktop scaled down for better proportions
        // Mobile: 220px, Tablet: 280px, Desktop: 340px (more reasonable on desktop)
        class: 'h-[220px] md:h-[280px] lg:h-[340px] flex items-end justify-center space-x-2 md:space-x-3 lg:space-x-4'
      }, props.data.map(item => {
        const quotaValue = props.quota > 0 ? props.quota : 1;
        const heightPercent = Math.min(100, Math.max(1, (item.value / quotaValue) * 100));

        return h('div', {
          key: item.id,
          class: 'flex flex-col items-center justify-end',
          style: { height: '100%' }
        }, [
          // Responsive value label: mobile xs -> tablet sm -> desktop base (scaled down)
          h('div', {
            class: 'text-xs md:text-sm lg:text-base text-center font-medium mb-1'
          }, item.valueLabel),
          // Bar element - height as percentage of container, width responsive (narrower on desktop)
          h('div', {
            class: 'w-10 md:w-14 lg:w-20 rounded-sm',
            style: {
              height: `${heightPercent}%`,
              minHeight: '2px',
              backgroundColor: '#8cc65d'
            }
          }),
          // Responsive bottom label: mobile xs -> tablet sm -> desktop base (scaled down)
          h('div', {
            class: 'text-xs md:text-sm lg:text-base mt-1 w-10 md:w-14 lg:w-20 text-center truncate text-gray-600'
          }, item.bottomLabel)
        ]);
      }))
    ]);
  }
});

// BottomGoalBar removed - replaced with floating action buttons

// Note: UpdateGoalSheet, EditGoalPage, InviteTeamSheet, GroupChatView, and PayTransactionView 
// components would be imported from separate files in a real implementation
</script>

<style scoped>
.text-secondary {
  color: rgba(60, 60, 67, 0.6);
}

.text-rep-green {
  color: #8cc65d;
}

.bg-rep-green {
  background-color: #8cc65d;
}

.border-rep-green {
  border-color: #8cc65d;
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Scale transitions for support button */
.transition-transform {
  transition: transform 0.3s ease;
}

.scale-0 {
  transform: scale(0);
}

.scale-100 {
  transform: scale(1);
}

/* Desktop: Make goal detail page full width, breaking out of App.vue container */
.goal-detail-container {
  /* Mobile: stay within container */
  width: 100%;
}

@media (min-width: 768px) {
  .goal-detail-container {
    /* Desktop: break out to full viewport width */
    width: 100vw;
    max-width: 100vw;
    margin-left: calc(-50vw + 50%);
  }
}
</style>