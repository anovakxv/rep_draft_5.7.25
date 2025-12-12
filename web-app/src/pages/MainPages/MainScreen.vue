<!--
  MainScreen.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header/Toolbar -->
    <header class="sticky top-0 z-20 border-b border-gray-200 flex items-center justify-between h-14 px-4" style="background-color: #f7f7f7">
      <button @click="handleProfileClick" class="focus:outline-none">
        <img v-if="currentUser?.profile_picture_url" :src="currentUser.profile_picture_url"
             class="w-8 h-8 rounded-full object-cover" alt="Profile"/>
        <div v-else class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-white text-xs font-semibold">
          {{ getInitials(currentUser?.full_name || 'User') }}
        </div>
      </button>

      <MainSegmentedPicker
        :segments="['Chats', 'Network', 'Purpose']"
        :selected-index="section"
        :attention-dot-indices="openNeedsAttention ? [0] : []"
        @select="handleSectionSelect"
        :key="openNeedsAttention ? 'dot-on' : 'dot-off'"
      />

      <button @click="handleAddButtonClick" style="color: #8cc65d">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
        </svg>
      </button>
    </header>

    <!-- Search Bar (slides from top) -->
    <Transition name="slide-down">
      <div v-if="showSearch" class="sticky z-10 bg-white p-3 border-b border-gray-200 shadow-sm flex justify-center" style="top: 56px;">
        <div class="w-full flex items-center" style="max-width: 768px;">
          <input
            ref="searchInput"
            v-model="searchText"
            type="search"
            placeholder="Search..."
            class="flex-grow p-3 border rounded-lg bg-gray-100 focus:outline-none focus:ring-1"
            style="--tw-ring-color: #8cc65d"
            @input="handleSearchInput"
          />
          <button @click="cancelSearch" class="ml-2 px-4 py-2 text-gray-700">Cancel</button>
        </div>
      </div>
    </Transition>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto relative pb-20">
      <Transition name="fade" mode="out-in">
        <!-- Loading State with Skeleton -->
        <LoadingSkeleton
          v-if="isLoading"
          key="loading"
          type="list"
          :count="5"
          :size="page === 'portals' ? 64 : 48"
          :variant="page === 'portals' ? 'square' : 'circle'"
        />

        <!-- Error State with Retry -->
        <ErrorState
          v-else-if="errorMessage"
          key="error"
          :message="errorMessage"
          show-retry
          :retrying="isLoading"
          @retry="handleRetry"
        />

        <!-- Content -->
        <div v-else key="content">
        <!-- Tab 0: MESSAGES - Always show Active Chat List regardless of page -->
        <template v-if="section === 0">
          <ActiveChatList
            :chats="filteredActiveChats"
            :invites="pendingInvites"
            :current-user-id="userId"
            :current-tab="currentTab"
          />
          <EmptyState
            v-if="filteredActiveChats.length === 0 && pendingInvites.length === 0"
            title="No conversations yet"
            description="Start a conversation by searching for people or creating a group chat"
            action-text="Find People"
            @action="() => { page = 'people'; section = 2; }"
          >
            <template #icon>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
            </template>
          </EmptyState>
        </template>

        <!-- Tab 1 (NTWK) and Tab 2 (ALL): Show based on page context -->
        <template v-else>
          <!-- When page = 'people': Show people lists -->
          <template v-if="page === 'people'">
            <PeopleList :users="filteredUsers" :current-user-id="userId" :current-tab="currentTab" />
            <!-- Empty State for Network Tab (section 1) -->
            <EmptyState
              v-if="filteredUsers.length === 0 && section === 1 && !searchText"
              title="No Network Members yet"
              description="Browse or search all People in the People Purpose tab to +NTWK to integrate with others you know."
              action-text=""
            >
              <template #icon>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </template>
            </EmptyState>
            <!-- Empty State for All other cases -->
            <EmptyState
              v-else-if="filteredUsers.length === 0"
              title="No people found"
              :description="searchText ? 'Try a different search term' : 'No people to display'"
            >
              <template #icon>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </template>
            </EmptyState>
          </template>

          <!-- When page = 'portals': Show portal lists -->
          <template v-else-if="page === 'portals'">
            <PortalList :portals="filteredPortals" :user-id="userId" :current-tab="currentTab" />
            <!-- Empty State for Network Tab (section 1) -->
            <EmptyState
              v-if="filteredPortals.length === 0 && section === 1 && !searchText"
              title="No Network Purposes yet"
              description="Browse active Purposes in the Purpose tab and join a Goal Team to get started! Or create your own Purpose."
              action-text=""
            >
              <template #icon>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </template>
            </EmptyState>
            <!-- Empty State for All other cases -->
            <EmptyState
              v-else-if="filteredPortals.length === 0"
              title="No portals found"
              :description="searchText ? 'Try a different search term' : 'Create your first portal to get started'"
              :action-text="searchText ? '' : 'Add Purpose'"
              @action="navigateToAddPurpose"
            >
              <template #icon>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
              </template>
            </EmptyState>
          </template>
        </template>
      </div>
      </Transition>

      <!-- Floating Toggle Button - Clear background (matching iOS) -->
      <div class="fixed bottom-5 z-30" style="right: max(36px, calc(50% - 348px));">
        <button @click="togglePage" class="w-11 h-11 flex items-center justify-center transition-opacity hover:opacity-80">
          <img :src="REPLogo" alt="Toggle Page" class="w-11 h-11" />
        </button>
      </div>
    </main>


    <!-- Action Sheet Modal -->
    <Transition name="fade">
      <div v-if="mainActiveSheet" @click="mainActiveSheet = null" class="fixed inset-0 z-30 flex items-end justify-center">
        <div class="bg-black bg-opacity-50 w-full" style="max-width: 768px; position: absolute; top: 0; bottom: 0; left: 50%; transform: translateX(-50%);"></div>
        <Transition name="slide-up">
          <div v-if="mainActiveSheet" @click.stop class="bg-white w-full rounded-t-2xl p-6 relative z-10" style="max-width: 768px">
            <div class="flex flex-col items-center space-y-6">
              <!-- Portal Filter Options (iOS style) -->
              <div v-if="page === 'portals'" class="flex items-center space-x-6 py-3">
                <span class="text-gray-500 font-normal">Show:</span>
                <button @click="toggleSafePortals(false)" class="flex items-center space-x-2">
                  <div class="w-5 h-5 rounded-full border-2 border-gray-400 flex items-center justify-center">
                    <svg v-if="!showOnlySafePortals" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-blue-500" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <span :class="!showOnlySafePortals ? 'font-bold text-gray-900' : 'font-normal text-gray-500'">All</span>
                </button>
                <button @click="toggleSafePortals(true)" class="flex items-center space-x-2">
                  <div class="w-5 h-5 rounded-full border-2 border-gray-400 flex items-center justify-center">
                    <svg v-if="showOnlySafePortals" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-blue-500" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <span :class="showOnlySafePortals ? 'font-bold text-gray-900' : 'font-normal text-gray-500'">Safe</span>
                </button>
              </div>

              <!-- Action Buttons (iOS style) -->
              <button @click="navigateToAddPurpose" class="text-[#8cc65d] font-bold text-[28px] py-3">
                Add Purpose
              </button>
              <button @click="navigateToTeamChat" class="text-[#8cc65d] font-bold text-[28px] py-3">
                Team Chat
              </button>
              <button @click="startSearch" class="text-[#8cc65d] font-bold text-[28px] py-3">
                Search
              </button>

              <!-- Cancel Button -->
              <button @click="mainActiveSheet = null" class="w-full text-center py-3 text-gray-500">
                Cancel
              </button>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
    
    <!-- Add Purpose Modal -->
    <div v-if="mainActiveSheet === 'addPurpose'" class="fixed inset-0 z-40">
      <router-view name="portalEditor" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, onActivated, watch, computed, defineComponent, h, nextTick, type Ref } from 'vue';
import { useRouter, useRoute, RouterLink } from 'vue-router';

// Define component name for keep-alive
defineOptions({
  name: 'MainScreen'
});
import api from '@/pages/utils/api';
import { useSocketManager } from '../utils/useSocketManager';
import { isAuthenticated } from '@/utils/auth';
import REPLogo from '@/assets/REPLogo.png';
import LoadingSkeleton from '@/components/LoadingSkeleton.vue';
import ErrorState from '@/components/ErrorState.vue';
import EmptyState from '@/components/EmptyState.vue';

// Simple debounce utility
function debounce<T extends (...args: any[]) => any>(fn: T, delay: number): (...args: Parameters<T>) => void {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
}

// Get initials from a name
function getInitials(name: string): string {
  const parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
  return name.substring(0, 2).toUpperCase();
}

// --- Interfaces (from MainScreen.swift) ---
interface User {
  id: number;
  full_name?: string;  // Backend returns snake_case
  profile_picture_url?: string;  // Backend returns snake_case
  lastMessage?: string;
  lastMessageDate?: string;
}

interface Portal { 
  id: number; 
  name: string; 
  subtitle?: string; 
  mainImageUrl?: string; 
}

interface ChatModel { 
  id: number; 
  name?: string; 
}

interface MessageModel { 
  id: number; 
  text?: string; 
  read?: string; 
  sender_id?: number; 
  created_at?: string;
}

interface ActiveChat { 
  id: string; 
  type: 'direct' | 'group'; 
  user?: User; 
  chat?: ChatModel; 
  last_message?: MessageModel; 
  last_message_time?: string; 
}

interface Invite { 
  id: number; 
  goals_id: number;
  users_id1: number;
  users_id2: number;
  confirmed: string;
  read1: string;
  read2: string;
  timestamp: string;
  goalTitle?: string;
  inviterName?: string;
  inviterPhotoURL?: string;
}

// --- Composables (Mirroring ViewModels) ---

const usePortals = (userId: Ref<number>, safeOnly: Ref<boolean>, lastFetchTime: Ref<Record<string, number>>) => {
  const portals = ref<Portal[]>([]);
  const searchResults = ref<Portal[]>([]);
  const isLoading = ref(false);
  const errorMessage = ref<string|null>(null);
  const isSearching = ref(false);

  const fetchPortals = async (section: number) => {
    isLoading.value = true;
    errorMessage.value = null;
    const tab = { 0: 'open', 1: 'ntwk', 2: 'all' }[section] || 'all';
    const limitParam = (tab === "all") ? "&limit=200" : "";
    const safeParam = safeOnly.value ? "&safe_only=true" : "";
    const authenticated = isAuthenticated();
    const cacheKey = `portals-${section}-${safeOnly.value}`;

    try {
      let res;

      // Use public endpoint for unauthenticated users on ALL tab
      if (!authenticated && tab === 'all') {
        res = await api.get(
          `/api/public/portals?safe_only=${safeOnly.value}${limitParam}`
        );
      } else {
        // Use authenticated endpoint
        res = await api.get(
          `/api/portal/filter_network_portals?user_id=${userId.value}&tab=${tab}${limitParam}${safeParam}`
        );
      }

      if (res.data && res.data.result) {
        portals.value = res.data.result;
      } else {
        portals.value = [];
      }
    } catch (err: any) {
      if (err.response?.status === 401 || err.response?.status === 403) {
        // For ALL tab, try to fallback to public endpoint if authenticated endpoint fails
        if (tab === 'all') {
          try {
            // Clear invalid auth data and retry with public endpoint
            console.log("Auth failed for ALL tab, falling back to public endpoint");
            localStorage.removeItem('jwtToken');
            localStorage.removeItem('userId');
            userId.value = 0;
            token.value = '';

            const publicRes = await api.get(
              `/api/public/portals?safe_only=${safeOnly.value}${limitParam}`
            );

            if (publicRes.data && publicRes.data.result) {
              portals.value = publicRes.data.result;
            } else {
              portals.value = [];
            }
            isLoading.value = false;
            return;
          } catch (publicErr) {
            errorMessage.value = "Unable to load portals. Please try again.";
          }
        } else {
          errorMessage.value = "Session expired. Please log in again.";
          handleUnauthorized('fetchPortals');
        }
      } else {
        errorMessage.value = err.response?.data?.error || `Server error (${err.response?.status || 'unknown'}).`;
      }
      portals.value = [];
    } finally {
      isLoading.value = false;
      // Record successful fetch timestamp (even if result is empty)
      if (!errorMessage.value) {
        lastFetchTime.value[cacheKey] = Date.now();
      }
    }
  };

  const searchPortals = async (query: string, limit: number = 50) => {
    if (!query.trim()) {
      searchResults.value = [];
      isSearching.value = false;
      return;
    }

    isLoading.value = true;
    isSearching.value = true;
    errorMessage.value = null;

    try {
      const res = await api.get(
        `/api/search_portals?q=${encodeURIComponent(query)}&limit=${limit}`
      );

      if (res.data && res.data.result) {
        searchResults.value = res.data.result;
      } else {
        searchResults.value = [];
      }
    } catch (err: any) {
      if (err.response?.status === 401 || err.response?.status === 403) {
        handleUnauthorized('searchPortals');
      }
      errorMessage.value = err.response?.data?.error || 'Failed to search portals.';
      searchResults.value = [];
    } finally {
      isLoading.value = false;
      isSearching.value = false;
    }
  };

  const clearSearch = () => {
    searchResults.value = [];
    isSearching.value = false;
  };

  return { portals, searchResults, isLoading, errorMessage, isSearching, fetchPortals, searchPortals, clearSearch };
};

const usePeople = (userId: Ref<number>, lastFetchTime: Ref<Record<string, number>>) => {
  const users = ref<User[]>([]);
  const activeChats = ref<ActiveChat[]>([]);
  const searchResults = ref<User[]>([]);
  const isLoading = ref(false);
  const errorMessage = ref<string|null>(null);
  const isSearching = ref(false);
  const hasUnreadDM = ref(localStorage.getItem('hasUnreadDMFlag') === 'true');
  const hasUnreadGroup = ref(localStorage.getItem('hasUnreadGroupFlag') === 'true');

  const fetchPeople = async (section: number) => {
    isLoading.value = true;
    errorMessage.value = null;
    const cacheKey = `people-${section}`;

    try {
      if (section === 0) {
        // Active chats
        const res = await api.get(
          `/api/active_chat_list?user_id=${userId.value}`
        );

        if (res.data && res.data.result) {
          activeChats.value = res.data.result;

          // Check for unread messages (exactly like Swift)
          const newHasUnreadDM = activeChats.value.some(c =>
            c.type === 'direct' &&
            c.last_message?.read === '0' &&
            c.last_message?.sender_id !== userId.value
          );

          const newHasUnreadGroup = activeChats.value.some(c =>
            c.type === 'group' &&
            c.last_message?.read === '0' &&
            c.last_message?.sender_id !== userId.value
          );

          // Always set to true if API shows unreads
          // Only clear to false if user is currently viewing Chats tab
          if (newHasUnreadDM) {
            hasUnreadDM.value = true;
          } else if (section.value === 0) {
            // User is on Chats tab, so clear the flag if no unreads found
            hasUnreadDM.value = false;
          }

          if (newHasUnreadGroup) {
            hasUnreadGroup.value = true;
          } else if (section.value === 0) {
            // User is on Chats tab, so clear the flag if no unreads found
            hasUnreadGroup.value = false;
          }
        } else {
          activeChats.value = [];
        }
      } else {
        // People list
        const tab = section === 1 ? 'ntwk' : 'all';
        const limitParam = (tab === "all") ? "&limit=200" : "";

        const res = await api.get(
          `/api/filter_people?user_id=${userId.value}&tab=${tab}${limitParam}`
        );

        if (res.data && res.data.result) {
          users.value = res.data.result;
        } else {
          users.value = [];
        }
      }
    } catch (err: any) {
      if (err.response?.status === 401 || err.response?.status === 403) {
        errorMessage.value = "Session expired. Please log in again.";
        handleUnauthorized('fetchPeople');
      } else {
        errorMessage.value = err.response?.data?.error || `Server error (${err.response?.status || 'unknown'}).`;
      }

      if (section === 0) {
        activeChats.value = [];
      } else {
        users.value = [];
      }
    } finally {
      isLoading.value = false;
      // Record successful fetch timestamp (even if result is empty)
      if (!errorMessage.value) {
        lastFetchTime.value[cacheKey] = Date.now();
      }
    }
  };

  const searchPeople = async (query: string, limit: number = 50) => {
    if (!query.trim()) {
      searchResults.value = [];
      isSearching.value = false;
      return;
    }

    isLoading.value = true;
    isSearching.value = true;
    errorMessage.value = null;

    try {
      const res = await api.get(
        `/api/search_people?q=${encodeURIComponent(query)}&limit=${limit}`
      );

      if (res.data && res.data.result) {
        searchResults.value = res.data.result;
      } else {
        searchResults.value = [];
      }
    } catch (err: any) {
      if (err.response?.status === 401 || err.response?.status === 403) {
        handleUnauthorized('searchPeople');
      }
      errorMessage.value = err.response?.data?.error || 'Failed to search people.';
      searchResults.value = [];
    } finally {
      isLoading.value = false;
      isSearching.value = false;
    }
  };

  const clearSearch = () => {
    searchResults.value = [];
    isSearching.value = false;
  };

  return { 
    users, 
    activeChats, 
    searchResults, 
    isLoading, 
    errorMessage, 
    isSearching,
    hasUnreadDM, 
    hasUnreadGroup, 
    fetchPeople, 
    searchPeople,
    clearSearch
  };
};

const useInvites = () => {
  const pendingInvites = ref<Invite[]>([]);
  const isLoading = ref(false);

  const fetchPendingInvites = async () => {
    isLoading.value = true;
    try {
      const res = await api.get('/api/goals/pending_invites');
      pendingInvites.value = res.data.invites || [];
      console.log('[MainScreen] Fetched pending invites:', pendingInvites.value.length, pendingInvites.value);
    } catch (err) {
      pendingInvites.value = [];
      console.error('Failed to fetch invites:', err);
    } finally {
      isLoading.value = false;
    }
  };

  return { pendingInvites, isLoading, fetchPendingInvites };
};

// --- Main Component Setup ---
const router = useRouter();
const route = useRoute();
const userId = ref(Number(localStorage.getItem('userId')) || 0);
const token = ref(localStorage.getItem('jwtToken') || '');
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

// --- Persistent App State ---
const persistedUnreadDM = ref(localStorage.getItem('hasUnreadDMFlag') === 'true');
const persistedUnreadGroup = ref(localStorage.getItem('hasUnreadGroupFlag') === 'true');

// --- Page & Section State ---
const page = ref<'portals' | 'people'>('portals');
const section = ref(2);
const showOnlySafePortals = ref(false);
const openNeedsAttention = ref(false);

// Map section to tab name for navigation
const currentTab = computed(() => {
  const tabMap: Record<number, string> = { 0: 'chats', 1: 'network', 2: 'purpose' };
  return tabMap[section.value] || 'purpose';
});

// --- Cache State (for keep-alive optimization) ---
const lastFetchTime = ref<Record<string, number>>({});
const CACHE_DURATION = 30000; // 30 seconds - data is considered fresh for this duration
const isInitialMount = ref(true);

const shouldFetchData = (key: string): boolean => {
  const lastFetch = lastFetchTime.value[key];
  if (!lastFetch) return true; // Never fetched
  const now = Date.now();
  return (now - lastFetch) > CACHE_DURATION; // Fetch if data is stale
};

// --- View Models ---
const { pendingInvites, fetchPendingInvites } = useInvites();
const {
  portals,
  searchResults: searchResultsPortals,
  isLoading: isLoadingPortals,
  errorMessage: errorPortals,
  fetchPortals,
  searchPortals,
  clearSearch: clearPortalSearch
} = usePortals(userId, showOnlySafePortals, lastFetchTime);

const {
  users,
  activeChats,
  searchResults: searchResultsUsers,
  isLoading: isLoadingPeople,
  errorMessage: errorPeople,
  hasUnreadDM,
  hasUnreadGroup,
  fetchPeople,
  searchPeople,
  clearSearch: clearPeopleSearch
} = usePeople(userId, lastFetchTime);

// --- UI State ---
const isLoading = computed(() => isLoadingPortals.value || isLoadingPeople.value);
const errorMessage = computed(() => errorPortals.value || errorPeople.value);
const currentUser = ref<User | null>(null);
const mainActiveSheet = ref<'actionSheet' | 'addPurpose' | null>(null);
const showSearch = ref(false);
const searchText = ref('');
const searchInput = ref<HTMLInputElement | null>(null);
const initialUnreadPollScheduled = ref(false);

// --- Computed Filters ---
const filteredPortals = computed(() => {
  if (showSearch.value && searchText.value.trim()) {
    return searchResultsPortals.value;
  }
  if (searchText.value.trim()) {
    return portals.value.filter(portal => 
      portal.name.toLowerCase().includes(searchText.value.toLowerCase())
    );
  }
  return portals.value;
});

const filteredUsers = computed(() => {
  if (showSearch.value && searchText.value.trim()) {
    return searchResultsUsers.value;
  }
  if (searchText.value.trim()) {
    return users.value.filter(user =>
      (user.full_name || '').toLowerCase().includes(searchText.value.toLowerCase())
    );
  }
  return users.value;
});

const filteredActiveChats = computed(() => {
  if (!searchText.value.trim()) return activeChats.value;

  return activeChats.value.filter(chat => {
    const name = chat.type === 'direct'
      ? chat.user?.full_name
      : chat.chat?.name;

    return name?.toLowerCase().includes(searchText.value.toLowerCase());
  });
});

// --- Methods ---
const handleUnauthorized = (source: string) => {
  console.error(`Unauthorized from: ${source}`);
  localStorage.clear();
  router.push('/register');
};

const fetchCurrentUser = async () => {
  try {
    const res = await api.get('/api/user/me');

    if (res.data && res.data.result) {
      currentUser.value = res.data.result;
    } else {
      currentUser.value = null;
    }
  } catch (err: any) {
    if (err.response?.status === 401 || err.response?.status === 403) {
      handleUnauthorized('fetchCurrentUser');
    }
    currentUser.value = null;
  }
};

const togglePage = () => {
  // Don't toggle page if we're on Chats tab - it doesn't use page context
  if (section.value === 0) {
    return;
  }

  // Switching to People page requires authentication (it's about chats/messages)
  if (page.value === 'portals' && !isAuthenticated()) {
    router.push({
      path: '/register',
      query: { returnTo: '/main' }
    });
    return;
  }
  page.value = page.value === 'portals' ? 'people' : 'portals';
  cancelSearch();
};

const handleSectionSelect = (index: number) => {
  // OPEN (0) and NTWK (1) tabs require authentication
  if ((index === 0 || index === 1) && !isAuthenticated()) {
    router.push({
      path: '/register',
      query: { returnTo: '/main' }
    });
    return;
  }

  // Always load chats data for tab 0 (regardless of notification dot or page state)
  section.value = index;
  if (index === 0) {
    fetchPeople(0); // Always fetch chats when switching to Chats tab
  }
};

const handleAddButtonClick = () => {
  if (!isAuthenticated()) {
    router.push({
      path: '/register',
      query: { returnTo: '/main' }
    });
    return;
  }
  mainActiveSheet.value = 'actionSheet';
};

const handleProfileClick = () => {
  if (!isAuthenticated()) {
    router.push({
      path: '/register',
      query: { returnTo: '/main' }
    });
    return;
  }
  router.push(`/profile/${userId.value}`);
};

const startSearch = () => {
  mainActiveSheet.value = null;
  showSearch.value = true;
  nextTick(() => {
    if (searchInput.value) {
      searchInput.value.focus();
    }
  });
};

const handleSearchInput = debounce(() => {
  performSearch(searchText.value);
}, 400);

const performSearch = (query: string) => {
  if (!showSearch.value || !query.trim()) {
    clearPortalSearch();
    clearPeopleSearch();
    return;
  }
  
  if (page.value === 'people' && section.value === 2) {
    searchPeople(query);
  } else if (page.value === 'portals' && section.value === 2) {
    searchPortals(query);
  }
};

const cancelSearch = () => {
  showSearch.value = false;
  searchText.value = '';
  clearPortalSearch();
  clearPeopleSearch();
};

const navigateToAddPurpose = () => {
  mainActiveSheet.value = 'addPurpose';
  router.push('/portal/edit/new');
};

const navigateToTeamChat = () => {
  mainActiveSheet.value = null;
  router.push('/chat/group/new');
};

const toggleSafePortals = (safeOnly: boolean) => {
  showOnlySafePortals.value = safeOnly;
  // Fetch will be triggered by the watcher
};

const handleRetry = () => {
  if (page.value === 'portals') {
    fetchPortals(section.value);
  } else {
    fetchPeople(section.value);
  }
};

const recalcOpenNeedsAttention = () => {
  // Include DM + Group + persisted + invites (identical to Swift)
  const currentUnread = hasUnreadDM.value || 
                        hasUnreadGroup.value || 
                        persistedUnreadDM.value || 
                        persistedUnreadGroup.value;
                        
  const newValue = currentUnread || pendingInvites.value.length > 0;
  
  // Only animate if value is changing
  if (newValue !== openNeedsAttention.value) {
    openNeedsAttention.value = newValue;
  } else {
    openNeedsAttention.value = newValue;
  }
  
  // Persist DM (exactly like Swift)
  if (!hasUnreadDM.value && persistedUnreadDM.value) {
    persistedUnreadDM.value = false;
    localStorage.setItem('hasUnreadDMFlag', 'false');
  } else if (hasUnreadDM.value && !persistedUnreadDM.value) {
    persistedUnreadDM.value = true;
    localStorage.setItem('hasUnreadDMFlag', 'true');
  }
  
  // Persist Group (exactly like Swift)
  if (!hasUnreadGroup.value && persistedUnreadGroup.value) {
    persistedUnreadGroup.value = false;
    localStorage.setItem('hasUnreadGroupFlag', 'false');
  } else if (hasUnreadGroup.value && !persistedUnreadGroup.value) {
    persistedUnreadGroup.value = true;
    localStorage.setItem('hasUnreadGroupFlag', 'true');
  }
};

// One-shot unread polling (first open only), like in Swift
const scheduleUnreadPollingIfNeeded = () => {
  if (initialUnreadPollScheduled.value) return;
  if (page.value !== 'portals' || 
      hasUnreadDM.value || 
      hasUnreadGroup.value) return;
  
  initialUnreadPollScheduled.value = true;
  console.log("🕑 Scheduling one-shot unread poll (1s)");
  
  setTimeout(() => {
    if (page.value === 'portals' && 
        !hasUnreadDM.value && 
        !hasUnreadGroup.value) {
      console.log("🕑 Executing one-shot unread poll");
      fetchPeople(0);
    }
  }, 1000);
};

// --- Watchers ---
// Combine page, section, and safe filter
watch([page, section, showOnlySafePortals], () => {
  // Don't reload data if we're on Chats tab - it doesn't change with page toggle
  if (section.value === 0) {
    return;
  }

  // Skip if component is not mounted yet (will be handled by immediate: true on mount)
  // Also skip if we just came from cache (onActivated handles it with cache checking)
  // But DO fetch when user actively changes page/section/filter
  const cacheKey = `${page.value}-${section.value}-${showOnlySafePortals.value}`;

  // If we have a cached timestamp for this exact state, and it's fresh, skip fetching
  // This prevents duplicate fetches when reactivated from cache
  // But allows fetching when user toggles to a new page/section that hasn't been loaded
  if (!isInitialMount.value && !shouldFetchData(cacheKey)) {
    console.log('[MainScreen] Watcher: Using cached data for', cacheKey);
    return;
  }

  if (page.value === 'portals') {
    fetchPortals(section.value);
  } else {
    fetchPeople(section.value);
  }
}, { immediate: true });

// Track unread status
watch([hasUnreadDM, hasUnreadGroup, pendingInvites], () => {
  recalcOpenNeedsAttention();
}, { immediate: true });

watch(activeChats, () => {
  recalcOpenNeedsAttention();
});

watch(page, () => {
  scheduleUnreadPollingIfNeeded();
});

// --- Lifecycle & Sockets ---
let inviteTimer: number | undefined;
const { connect, onDirectMessageNotification, onGroupMessageNotification, onGoalTeamInvite } = useSocketManager();
let unsubscribeDM: (() => void) | null = null;
let unsubscribeGroup: (() => void) | null = null;
let unsubscribeInvite: (() => void) | null = null;

onMounted(() => {
  // For public web, we allow viewing MainScreen ALL tab without authentication
  // Only initialize authenticated features if user is logged in
  const authenticated = isAuthenticated();

  // Check for tab query parameter to set initial section
  const tabParam = route.query.tab;
  if (tabParam === 'chats') {
    section.value = 0;
  } else if (tabParam === 'network') {
    section.value = 1;
  } else if (tabParam === 'purpose' || tabParam === 'all') {
    section.value = 2;
  }

  if (authenticated) {
    // Initialize unread status from localStorage
    if (persistedUnreadDM.value) {
      hasUnreadDM.value = true;
      if (userId.value !== 0 && token.value) {
        fetchPeople(0);
      }
    }

    if (persistedUnreadGroup.value) {
      hasUnreadGroup.value = true;
      if (userId.value !== 0 && token.value) {
        fetchPeople(0);
      }
    }

    // Connect the socket
    connect(apiBaseUrl, token.value, userId.value);

    // Get user data & invites
    fetchCurrentUser();
    fetchPendingInvites();

    // Start invite polling: immediate + every 30s
    inviteTimer = window.setInterval(fetchPendingInvites, 30000);

    // Schedule one-shot unread polling
    scheduleUnreadPollingIfNeeded();
  } else {
    // Public user - ensure we're on the ALL tab (section 2) for portals unless tab param overrides
    page.value = 'portals';
    if (!tabParam) {
      section.value = 2;
    }
  }

  // --- Socket Handlers (from Swift) ---
  const toInt = (any: any): number | null => {
    if (typeof any === 'number') return any;
    if (typeof any === 'string') return parseInt(any, 10);
    return null;
  };

  unsubscribeDM = onDirectMessageNotification((payload) => {
    const senderId = toInt(payload.sender_id ?? payload.senderId);
    if (senderId === userId.value) return;

    // Instant UI feedback (rely on socket.io only, like iOS)
    hasUnreadDM.value = true;
    recalcOpenNeedsAttention();
  });

  unsubscribeGroup = onGroupMessageNotification((payload) => {
    const senderId = toInt(payload.sender_id ?? payload.senderId);
    if (senderId === userId.value) return;

    // Instant UI feedback (rely on socket.io only, like iOS)
    hasUnreadGroup.value = true;
    recalcOpenNeedsAttention();
  });

  unsubscribeInvite = onGoalTeamInvite((data) => {
    // Instant UI feedback for invites
    console.log('[MainScreen] Received goal_team_invite socket event:', data);
    openNeedsAttention.value = true;
    fetchPendingInvites();
  });
  
  // Add DOM event for refreshing active chats (like NotificationCenter in Swift)
  document.addEventListener('refreshActiveChats', () => {
    fetchPeople(0);
  });
  
  // Add visibilitychange event (similar to willEnterForeground in Swift)
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      // Only reconnect socket and poll for authenticated users
      if (isAuthenticated()) {
        connect(apiBaseUrl, token.value, userId.value);
        scheduleUnreadPollingIfNeeded();
      }
    }
  });
});

// Called when component is reactivated from keep-alive cache
onActivated(() => {
  console.log('[MainScreen] Component activated from cache');
  isInitialMount.value = false;

  // Reconnect socket if needed
  if (isAuthenticated()) {
    connect(apiBaseUrl, token.value, userId.value);
  }

  // Only fetch data if it's stale (older than CACHE_DURATION)
  const cacheKey = `${page.value}-${section.value}-${showOnlySafePortals.value}`;
  if (shouldFetchData(cacheKey)) {
    console.log('[MainScreen] Cache is stale, refreshing data');
    if (section.value !== 0) {
      if (page.value === 'portals') {
        fetchPortals(section.value);
      } else {
        fetchPeople(section.value);
      }
    }
  } else {
    console.log('[MainScreen] Using cached data (fresh)');
  }

  // Always check for new invites and unread messages (lightweight)
  if (isAuthenticated()) {
    fetchPendingInvites();
    scheduleUnreadPollingIfNeeded();
  }
});

onUnmounted(() => {
  if (inviteTimer) clearInterval(inviteTimer);
  if (unsubscribeDM) unsubscribeDM();
  if (unsubscribeGroup) unsubscribeGroup();
  if (unsubscribeInvite) unsubscribeInvite();

  document.removeEventListener('refreshActiveChats', () => {});
  document.removeEventListener('visibilitychange', () => {});
});

// --- Time Formatting Utility ---
const timeAgoDisplay = (dateString: string | undefined): string => {
  if (!dateString) return '';
  
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);
    
    if (diffSec < 60) return 'just now';
    if (diffMin < 60) return `${diffMin}m`;
    if (diffHour < 24) return `${diffHour}h`;
    if (diffDay < 7) return `${diffDay}d`;
    
    return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  } catch (e) {
    return dateString;
  }
};

// --- Inline Component Definitions ---

const MainSegmentedPicker = defineComponent({
  props: {
    segments: Array as () => string[],
    selectedIndex: Number,
    attentionDotIndices: Array as () => number[]
  },
  emits: ['select'],
  setup(props, { emit }) {
    return () => h('div', {
      class: 'flex w-52 md:w-56 h-8 bg-gray-200 rounded overflow-hidden border border-black'
    },
    props.segments?.flatMap((segment, index) => {
      const button = h('button', {
        class: [
          'relative flex-1 text-xs font-medium transition-colors duration-150',
          props.selectedIndex === index ? 'bg-black text-white' : 'bg-white text-black'
        ],
        onClick: () => emit('select', index)
      }, [
        segment,
        ...(props.attentionDotIndices?.includes(index) ? [
          h('div', {
            class: 'absolute top-1 left-1 w-2.5 h-2.5 bg-green-500 rounded-full'
          })
        ] : [])
      ]);

      // Add divider line after each button except the last one
      if (index < (props.segments?.length || 0) - 1) {
        return [
          button,
          h('div', {
            class: 'w-px bg-black',
            style: { height: '100%' }
          })
        ];
      }
      return [button];
    }));
  }
});

const PortalList = defineComponent({
  props: {
    portals: Array as () => Portal[],
    userId: Number,
    currentTab: String
  },
  setup(props) {
    return () => h('div', { class: 'bg-gray-50' },
      props.portals?.map((portal, index) =>
        h(RouterLink, {
          to: { path: `/portal/${portal.id}`, query: { from: props.currentTab } },
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
                // City (placeholder - would need to map cities_id to city name)
                h('span', { class: 'text-gray-500' }, ''),

                // Member count (green text on right)
                h('span', { class: 'text-green-600 font-medium' }, '')
              ])
            ])
          ])
        )
      )
    );
  }
});

const PeopleList = defineComponent({
  props: {
    users: Array as () => User[],
    currentUserId: Number,
    currentTab: String
  },
  setup(props) {
    return () => h('div', { class: 'bg-white' },
      props.users?.map((user, index) =>
        h('div', { key: user.id }, [
          h(RouterLink, {
            to: { path: `/profile/${user.id}`, query: { from: props.currentTab } },
            class: 'block hover:bg-gray-50'
          }, () =>
            h('div', {
              class: 'flex items-center py-4 px-4',
              style: { minHeight: '96px' }
            }, [
              (user.profile_picture_url && user.profile_picture_url.trim())
                ? h('img', {
                    src: user.profile_picture_url,
                    class: 'w-16 h-16 object-cover rounded-full'
                  })
                : h('div', {
                    class: 'w-16 h-16 bg-gray-300 rounded-full flex items-center justify-center text-white font-semibold text-xl'
                  }, getInitials(user.full_name || 'User')),
              h('div', { class: 'flex-1 ml-3' }, [
                h('div', { class: 'flex justify-between items-center' }, [
                  h('h3', { class: 'font-semibold text-[17px]' }, user.full_name),
                  h('p', { class: 'text-[13px] text-gray-500' }, timeAgoDisplay(user.lastMessageDate))
                ]),
                h('p', { class: 'text-[17px] text-gray-600 truncate mt-1' }, user.lastMessage)
              ])
            ])
          ),
          // Separator line matching iOS light gray
          index < (props.users?.length || 0) - 1
            ? h('div', {
                class: 'h-px',
                style: { backgroundColor: 'rgb(228, 228, 228)' }
              })
            : null
        ])
      )
    );
  }
});

const ActiveChatList = defineComponent({
  props: {
    chats: Array as () => ActiveChat[],
    invites: Array as () => Invite[],
    currentUserId: Number,
    currentTab: String
  },
  setup(props) {
    const renderInvite = () => {
      console.log('[ActiveChatList] renderInvite called, invites:', props.invites?.length || 0);
      if (!props.invites || props.invites.length === 0) return null;

      return h(RouterLink, {
        to: '/invites',
        class: 'block p-4 bg-white border-b border-gray-200 hover:bg-gray-50'
      }, () =>
        h('div', { class: 'flex items-center space-x-3' }, [
          h('div', {
            class: 'w-10 h-10 rounded-full flex items-center justify-center text-white font-bold',
            style: 'background-color: #8cc65d'
          }, '🔔'),
          h('div', [
            h('h3', { class: 'font-semibold' },
              `You have ${props.invites?.length || 0} pending invitation${(props.invites?.length || 0) > 1 ? 's' : ''}`
            ),
            h('p', { class: 'text-sm text-gray-600 mt-1' }, 'Tap to view and respond')
          ])
        ])
      );
    };
    
    const renderChat = (chat: ActiveChat, index: number) => {
      const isUnread = chat.last_message?.read === '0' &&
                       chat.last_message?.sender_id !== props.currentUserId;

      const chatTarget = chat.type === 'direct'
        ? `/chat/dm/${chat.user?.id}`
        : `/chat/group/${chat.chat?.id}`;

      const profileTarget = chat.type === 'direct' && chat.user?.id
        ? `/profile/${chat.user.id}`
        : null;

      const name = chat.type === 'direct'
        ? chat.user?.full_name
        : chat.chat?.name;

      const image = chat.type === 'direct'
        ? chat.user?.profile_picture_url
        : undefined;

      return h('div', { key: chat.id }, [
        h('div', {
          class: 'flex items-center py-4 px-4 hover:bg-gray-50',
          style: { minHeight: '96px' }
        }, [
          // Profile picture - clickable to navigate to profile (for direct chats only)
          chat.type === 'direct' && profileTarget
            ? h(RouterLink, {
                to: { path: profileTarget, query: { from: props.currentTab } },
                class: 'flex-shrink-0'
              }, () =>
                image
                  ? h('img', {
                      src: image,
                      class: 'w-16 h-16 object-cover rounded-full'
                    })
                  : h('div', {
                      class: 'w-16 h-16 bg-gray-300 rounded-full flex items-center justify-center font-semibold text-white text-xl'
                    }, getInitials(name || 'User'))
              )
            : // For group chats, just show the avatar without profile link
              h('div', { class: 'flex-shrink-0' },
                h('div', {
                  class: 'w-16 h-16 bg-gray-300 rounded-full flex items-center justify-center font-semibold text-white text-xl'
                }, getInitials(name || 'Chat'))
              ),

          // Chat details - clickable to navigate to chat
          h(RouterLink, {
            to: { path: chatTarget, query: { from: props.currentTab } },
            class: 'flex-1 ml-3 min-w-0'
          }, () =>
            h('div', { class: 'min-w-0' }, [
              h('div', { class: 'flex justify-between items-center gap-2' }, [
                h('h3', { class: 'font-semibold text-[17px] truncate flex-1 min-w-0' }, name),
                h('p', { class: 'text-[13px] text-gray-500 flex-shrink-0' }, timeAgoDisplay(chat.last_message_time))
              ]),
              h('p', {
                class: [
                  'text-[15px] truncate mt-1',
                  isUnread ? 'font-bold text-green-600' : 'text-gray-600'
                ]
              }, chat.last_message?.text || '')
            ])
          )
        ]),
        // Separator line matching iOS light gray
        index < (props.chats?.length || 0) - 1
          ? h('div', {
              class: 'h-px',
              style: { backgroundColor: 'rgb(228, 228, 228)' }
            })
          : null
      ]);
    };

    return () => h('div', { class: 'bg-white' }, [
      renderInvite(),
      ...(props.chats?.map((chat, index) => renderChat(chat, index)) || [])
    ]);
  }
});
</script>

<style scoped>
.logo {
  width: 120px;
  margin-bottom: 2rem;
}

/* Slide-down transition for search bar from top */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: transform 0.2s ease-out, opacity 0.2s ease-out;
}

.slide-down-enter-from {
  transform: translateY(-100%);
  opacity: 0;
}

.slide-down-leave-to {
  transform: translateY(-100%);
  opacity: 0;
}

.slide-down-enter-to,
.slide-down-leave-from {
  transform: translateY(0);
  opacity: 1;
}
</style>