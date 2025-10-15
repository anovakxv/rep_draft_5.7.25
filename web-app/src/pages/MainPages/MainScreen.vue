<!--
  MainScreen.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header/Toolbar -->
    <header class="sticky top-0 z-20 bg-gray-100 border-b border-gray-200 flex items-center justify-between h-14 px-4">
      <router-link :to="`/profile/${userId}`">
        <img v-if="currentUser?.profilePictureURL" :src="currentUser.profilePictureURL" 
             class="w-7 h-7 rounded-full object-cover" alt="Profile"/>
        <div v-else class="w-7 h-7 rounded-full bg-gray-300 flex items-center justify-center text-white">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
          </svg>
        </div>
      </router-link>

      <MainSegmentedPicker
        :segments="['OPEN', 'NTWK', 'ALL']"
        :selected-index="section"
        :attention-dot-indices="openNeedsAttention ? [0] : []"
        @select="handleSectionSelect"
        :key="openNeedsAttention ? 'dot-on' : 'dot-off'"
      />

      <button @click="mainActiveSheet = 'actionSheet'" class="text-green-600">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
        </svg>
      </button>
    </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto relative">
      <div v-if="isLoading" class="flex justify-center items-center h-full">
        <div class="text-center">
          <svg class="animate-spin h-8 w-8 mx-auto mb-2 text-gray-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p>Loading {{ page === 'portals' ? 'portals' : page === 'people' && section === 0 ? 'chats' : 'people' }}...</p>
        </div>
      </div>
      <div v-else-if="errorMessage" class="flex justify-center items-center h-full text-red-500 p-4 text-center">
        <p>{{ errorMessage }}</p>
      </div>
      <div v-else>
        <template v-if="page === 'people'">
          <template v-if="section === 0">
            <ActiveChatList 
              :chats="filteredActiveChats" 
              :invites="pendingInvites"
              :current-user-id="userId"
            />
            <div v-if="filteredActiveChats.length === 0 && pendingInvites.length === 0" class="flex justify-center items-center h-64 text-gray-500">
              No chats found.
            </div>
          </template>
          <template v-else>
            <PeopleList :users="filteredUsers" :current-user-id="userId" />
            <div v-if="filteredUsers.length === 0" class="flex justify-center items-center h-64 text-gray-500">
              No people found.
            </div>
          </template>
        </template>
        <template v-else-if="page === 'portals'">
          <PortalList :portals="filteredPortals" :user-id="userId" />
          <div v-if="filteredPortals.length === 0" class="flex justify-center items-center h-64 text-gray-500">
            No portals found.
          </div>
        </template>
      </div>

      <!-- Floating Toggle Button -->
      <div class="absolute bottom-5 right-9">
        <button @click="togglePage" class="w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center">
          <img :src="REPLogo" alt="Toggle Page" class="w-8 h-8" />
        </button>
      </div>
    </main>

    <!-- Search Overlay -->
    <div v-if="showSearch" class="fixed bottom-0 left-0 right-0 bg-white p-3 border-t shadow-md transition-transform duration-300">
      <div class="flex items-center">
        <input 
          v-model="searchText" 
          type="search" 
          placeholder="Search..." 
          class="flex-grow p-3 border rounded-lg bg-gray-100 focus:outline-none focus:ring-2 focus:ring-green-500"
          @input="handleSearchInput"
        />
        <button @click="cancelSearch" class="ml-2 px-4 py-2 text-gray-700">Cancel</button>
      </div>
    </div>

    <!-- Action Sheet Modal -->
    <div v-if="mainActiveSheet" @click="mainActiveSheet = null" class="fixed inset-0 bg-black bg-opacity-50 z-30 flex items-end">
      <div @click.stop class="bg-white w-full rounded-t-lg p-6 space-y-4">
        <!-- Portal Filter Options -->
        <div v-if="page === 'portals'" class="flex items-center justify-center space-x-8 py-3 mb-2">
          <span class="text-gray-500">Show:</span>
          <button @click="toggleSafePortals(false)" class="flex items-center">
            <div class="w-5 h-5 rounded-full border-2 border-gray-400 mr-2 flex items-center justify-center">
              <div v-if="!showOnlySafePortals" class="w-3 h-3 bg-green-600 rounded-full"></div>
            </div>
            <span :class="!showOnlySafePortals ? 'font-bold text-black' : 'text-gray-600'">All</span>
          </button>
          <button @click="toggleSafePortals(true)" class="flex items-center">
            <div class="w-5 h-5 rounded-full border-2 border-gray-400 mr-2 flex items-center justify-center">
              <div v-if="showOnlySafePortals" class="w-3 h-3 bg-green-600 rounded-full"></div>
            </div>
            <span :class="showOnlySafePortals ? 'font-bold text-black' : 'text-gray-600'">Safe</span>
          </button>
        </div>
        
        <button @click="navigateToAddPurpose" class="action-button">Add Purpose</button>
        <button @click="navigateToTeamChat" class="action-button">Team Chat</button>
        <button @click="startSearch" class="action-button">Search</button>
        <button @click="mainActiveSheet = null" class="w-full text-center mt-4 py-2 text-gray-600">Cancel</button>
      </div>
    </div>
    
    <!-- Add Purpose Modal -->
    <div v-if="mainActiveSheet === 'addPurpose'" class="fixed inset-0 z-40">
      <router-view name="portalEditor" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, computed, defineComponent, h, nextTick } from 'vue';
import { useRouter, RouterLink } from 'vue-router';
import api from '@/pages/utils/api';
import { debounce } from 'lodash-es';
import { useSocketManager } from '../utils/useSocketManager';
import REPLogo from '@/assets/REPLogo.png';

// --- Interfaces (from MainScreen.swift) ---
interface User { 
  id: number; 
  fullName?: string; 
  profilePictureURL?: string; 
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

// --- Constants & Config ---
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

// --- Composables (Mirroring ViewModels) ---

const usePortals = (userId: ref<number>, token: ref<string>, safeOnly: ref<boolean>) => {
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
    
    try {
      const res = await axios.get(
        `${apiBaseUrl}/api/portal/filter_network_portals?user_id=${userId.value}&tab=${tab}${limitParam}${safeParam}`, 
        { headers: { Authorization: `Bearer ${token.value}` } }
      );
      
      if (res.data && res.data.result) {
        portals.value = res.data.result;
      } else {
        portals.value = [];
      }
    } catch (err: any) {
      if (err.response?.status === 401 || err.response?.status === 403) {
        errorMessage.value = "Session expired. Please log in again.";
        handleUnauthorized('fetchPortals');
      } else {
        errorMessage.value = err.response?.data?.error || `Server error (${err.response?.status || 'unknown'}).`;
      }
      portals.value = [];
    } finally { 
      isLoading.value = false; 
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
      const res = await axios.get(
        `${apiBaseUrl}/api/search_portals?q=${encodeURIComponent(query)}&limit=${limit}`, 
        { headers: { Authorization: `Bearer ${token.value}` } }
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

const usePeople = (userId: ref<number>, token: ref<string>) => {
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
    
    try {
      if (section === 0) {
        // Active chats
        const res = await axios.get(
          `${apiBaseUrl}/api/active_chat_list?user_id=${userId.value}`, 
          { headers: { Authorization: `Bearer ${token.value}` } }
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
          
          hasUnreadDM.value = newHasUnreadDM;
          hasUnreadGroup.value = newHasUnreadGroup;
        } else {
          activeChats.value = [];
        }
      } else {
        // People list
        const tab = section === 1 ? 'ntwk' : 'all';
        const limitParam = (tab === "all") ? "&limit=200" : "";
        
        const res = await axios.get(
          `${apiBaseUrl}/api/filter_people?user_id=${userId.value}&tab=${tab}${limitParam}`, 
          { headers: { Authorization: `Bearer ${token.value}` } }
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
      const res = await axios.get(
        `${apiBaseUrl}/api/search_people?q=${encodeURIComponent(query)}&limit=${limit}`, 
        { headers: { Authorization: `Bearer ${token.value}` } }
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

const useInvites = (token: ref<string>) => {
  const pendingInvites = ref<Invite[]>([]);
  const isLoading = ref(false);
  
  const fetchPendingInvites = async () => {
    isLoading.value = true;
    try {
      const res = await axios.get(
        `${apiBaseUrl}/api/goals/pending_invites`,
        { headers: { Authorization: `Bearer ${token.value}` } }
      );
      pendingInvites.value = res.data.invites || [];
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
const userId = ref(Number(localStorage.getItem('userId')) || 0);
const token = ref(localStorage.getItem('jwtToken') || '');

// --- Persistent App State ---
const persistedUnreadDM = ref(localStorage.getItem('hasUnreadDMFlag') === 'true');
const persistedUnreadGroup = ref(localStorage.getItem('hasUnreadGroupFlag') === 'true');

// --- Page & Section State ---
const page = ref<'portals' | 'people'>('portals');
const section = ref(2);
const showOnlySafePortals = ref(false);
const openNeedsAttention = ref(false);

// --- View Models ---
const { pendingInvites, fetchPendingInvites } = useInvites(token);
const { 
  portals, 
  searchResults: searchResultsPortals, 
  isLoading: isLoadingPortals, 
  errorMessage: errorPortals, 
  fetchPortals, 
  searchPortals, 
  clearSearch: clearPortalSearch 
} = usePortals(userId, token, showOnlySafePortals);

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
} = usePeople(userId, token);

// --- UI State ---
const isLoading = computed(() => isLoadingPortals.value || isLoadingPeople.value);
const errorMessage = computed(() => errorPortals.value || errorPeople.value);
const currentUser = ref<User | null>(null);
const mainActiveSheet = ref<'actionSheet' | 'addPurpose' | null>(null);
const showSearch = ref(false);
const searchText = ref('');
const searchDebounceTimer = ref<number | null>(null);
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
      (user.fullName || '').toLowerCase().includes(searchText.value.toLowerCase())
    );
  }
  return users.value;
});

const filteredActiveChats = computed(() => {
  if (!searchText.value.trim()) return activeChats.value;
  
  return activeChats.value.filter(chat => {
    const name = chat.type === 'direct' 
      ? chat.user?.fullName 
      : chat.chat?.name;
      
    return name?.toLowerCase().includes(searchText.value.toLowerCase());
  });
});

// --- Methods ---
const handleUnauthorized = (source: string) => {
  console.error(`Unauthorized from: ${source}`);
  localStorage.clear();
  router.push('/login');
};

const fetchCurrentUser = async () => {
  try {
    const res = await axios.get(
      `${apiBaseUrl}/api/user/me`, 
      { headers: { Authorization: `Bearer ${token.value}` } }
    );
    
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
  page.value = page.value === 'portals' ? 'people' : 'portals';
  cancelSearch();
};

const handleSectionSelect = (index: number) => {
  if (index === 0 && openNeedsAttention.value) {
    forceShowPeopleOpen();
  } else {
    section.value = index;
  }
};

const forceShowPeopleOpen = () => {
  page.value = 'people';
  if (section.value !== 0) {
    section.value = 0;
  } else {
    // Refresh if already on section 0
    fetchPeople(0);
  }
};

const startSearch = () => {
  mainActiveSheet.value = null;
  showSearch.value = true;
  nextTick(() => {
    const searchInput = document.querySelector('input[type="search"]');
    if (searchInput) {
      (searchInput as HTMLInputElement).focus();
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
  // Check authentication
  if (!token.value || !userId.value) { 
    router.push('/login'); 
    return; 
  }

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

  // --- Socket Handlers (from Swift) ---
  const toInt = (any: any): number | null => {
    if (typeof any === 'number') return any;
    if (typeof any === 'string') return parseInt(any, 10);
    return null;
  };

  unsubscribeDM = onDirectMessageNotification((payload) => {
    const senderId = toInt(payload.sender_id ?? payload.senderId);
    if (senderId === userId.value) return;
    
    // Instant UI feedback
    hasUnreadDM.value = true;
    recalcOpenNeedsAttention();
    
    // Reconcile after brief delay
    setTimeout(() => fetchPeople(0), 1500);
  });

  unsubscribeGroup = onGroupMessageNotification((payload) => {
    const senderId = toInt(payload.sender_id ?? payload.senderId);
    if (senderId === userId.value) return;
    
    // Instant UI feedback
    hasUnreadGroup.value = true;
    recalcOpenNeedsAttention();
    
    // Reconcile after brief delay
    setTimeout(() => fetchPeople(0), 1500);
  });

  unsubscribeInvite = onGoalTeamInvite(() => {
    // Instant UI feedback for invites
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
      // Reconnect socket if needed
      connect(apiBaseUrl, token.value, userId.value);
      scheduleUnreadPollingIfNeeded();
    }
  });
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
    segments: Array, 
    selectedIndex: Number, 
    attentionDotIndices: Array 
  },
  emits: ['select'],
  setup(props, { emit }) {
    return () => h('div', { 
      class: 'flex w-60 h-8 bg-gray-200 rounded overflow-hidden border border-black'
    },
    props.segments?.map((segment, index) =>
      h('button', {
        class: [
          'relative flex-1 text-sm font-medium transition-colors duration-150', 
          props.selectedIndex === index ? 'bg-black text-white' : 'bg-white text-black'
        ],
        onClick: () => emit('select', index)
      }, [
        segment,
        (props.attentionDotIndices?.includes(index)) && 
        h('div', { 
          class: 'absolute top-1 left-1 w-2.5 h-2.5 bg-green-500 rounded-full' 
        })
      ])
    ));
  }
});

const PortalList = defineComponent({
  props: { 
    portals: Array as () => Portal[],
    userId: Number 
  },
  setup(props) {
    return () => h('div', { class: 'divide-y' },
      props.portals?.map(portal =>
        h(RouterLink, { 
          to: `/portal/${portal.id}`, 
          class: 'block py-4 px-4 hover:bg-gray-50' 
        }, () =>
          h('div', { class: 'flex items-center space-x-4' }, [
            h('img', { 
              src: portal.mainImageUrl || '/default-portal.png', 
              class: 'w-16 h-16 object-cover rounded shadow-sm' 
            }),
            h('div', [
              h('h3', { class: 'font-bold text-lg' }, portal.name),
              h('p', { class: 'text-sm text-gray-600 mt-1' }, portal.subtitle)
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
    currentUserId: Number
  },
  setup(props) {
    return () => h('div', { class: 'divide-y' },
      props.users?.map(user =>
        h(RouterLink, { 
          to: `/profile/${user.id}`, 
          class: 'block py-4 px-4 hover:bg-gray-50' 
        }, () =>
          h('div', { class: 'flex items-center space-x-4' }, [
            h('img', { 
              src: user.profilePictureURL || '/default-profile.png', 
              class: 'w-12 h-12 object-cover rounded-full shadow-sm' 
            }),
            h('div', { class: 'flex-1' }, [
              h('div', { class: 'flex justify-between' }, [
                h('h3', { class: 'font-semibold' }, user.fullName),
                h('p', { class: 'text-xs text-gray-500' }, timeAgoDisplay(user.lastMessageDate))
              ]),
              h('p', { class: 'text-sm text-gray-600 truncate mt-1' }, user.lastMessage)
            ])
          ])
        )
      )
    );
  }
});

const ActiveChatList = defineComponent({
  props: { 
    chats: Array as () => ActiveChat[], 
    invites: Array as () => Invite[],
    currentUserId: Number
  },
  setup(props) {
    const renderInvite = () => {
      if (!props.invites || props.invites.length === 0) return null;
      
      return h(RouterLink, { 
        to: '/invites', 
        class: 'block p-4 bg-green-50 border-b hover:bg-green-100' 
      }, () =>
        h('div', { class: 'flex items-center space-x-3' }, [
          h('div', { 
            class: 'w-10 h-10 bg-green-500 rounded-full flex items-center justify-center text-white font-bold'
          }, '🔔'),
          h('div', [
            h('h3', { class: 'font-semibold' }, 
              `You have ${props.invites.length} pending invitation${props.invites.length > 1 ? 's' : ''}`
            ),
            h('p', { class: 'text-sm text-gray-600 mt-1' }, 'Tap to view and respond')
          ])
        ])
      );
    };
    
    const renderChat = (chat: ActiveChat) => {
      const isUnread = chat.last_message?.read === '0' && 
                       chat.last_message?.sender_id !== props.currentUserId;
                       
      const target = chat.type === 'direct' 
        ? `/chat/dm/${chat.user?.id}` 
        : `/chat/group/${chat.chat?.id}`;
        
      const name = chat.type === 'direct' 
        ? chat.user?.fullName 
        : chat.chat?.name;
        
      const image = chat.type === 'direct' 
        ? chat.user?.profilePictureURL 
        : undefined;
      
      return h(RouterLink, { 
        to: target, 
        class: 'block p-4 hover:bg-gray-50' 
      }, () =>
        h('div', { class: 'flex items-center space-x-4' }, [
          // Chat avatar (profile pic or group initials)
          image 
            ? h('img', { 
                src: image, 
                class: 'w-12 h-12 object-cover rounded-full shadow-sm' 
              }) 
            : h('div', { 
                class: 'w-12 h-12 bg-gray-300 rounded-full flex items-center justify-center font-bold text-white'
              }, name?.substring(0, 2).toUpperCase()),
              
          // Chat details  
          h('div', { class: 'flex-1' }, [
            h('div', { class: 'flex justify-between' }, [
              h('h3', { class: 'font-semibold' }, name),
              h('p', { class: 'text-xs text-gray-500' }, timeAgoDisplay(chat.last_message_time))
            ]),
            h('p', { 
              class: [
                'text-sm truncate mt-1', 
                isUnread ? 'font-bold text-green-600' : 'text-gray-600'
              ]
            }, chat.last_message?.text)
          ])
        ])
      );
    };
    
    return () => h('div', { class: 'divide-y' }, [
      renderInvite(),
      ...(props.chats?.map(renderChat) || [])
    ]);
  }
});
</script>

<style scoped>
.logo {
  width: 120px;
  margin-bottom: 2rem;
}
</style>