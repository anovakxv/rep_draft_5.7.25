<!--
  ProfileView.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->
  
<template>
  <div class="min-h-screen bg-white flex flex-col">
    <!-- Navigation Header -->
    <NavigationHeaderView 
      :name="user.displayName" 
      :show-settings="isCurrentUser"
      @back="goBack" 
      @settings="goToSettings" 
    />

    <!-- Main Content -->
    <main v-if="isLoaded && user.id" class="flex-1 overflow-y-auto">
      <!-- Profile Info -->
      <ProfileInfoView
        :photo-url="user.profile_picture_url"
        :city="user.city"
        :skills="user.skills ? user.skills.map(s => s.title) : []"
      />

      <!-- Broadcast Message -->
      <ProfileBroadcastView :broadcast="user.broadcast" />

      <!-- Sticky Tab Header -->
      <div class="sticky top-14 z-10 bg-white px-4 py-2 border-b border-t">
        <ProfileSegmentedPicker 
          :segments="['Rep', 'Goals', 'Write']" 
          v-model="selectedTab" 
        />
      </div>

      <!-- Tab Content -->
      <div class="p-4">
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
    </main>

    <!-- Loading State -->
    <div v-else class="flex-1 flex items-center justify-center">
      <p>Loading Profile...</p>
    </div>

    <!-- Bottom Action Bar -->
    <BottomBarView
      @add-click="showActionMenu = true"
      @message-click="goToMessages"
    />

    <!-- Action Menu Modal -->
    <div v-if="showActionMenu" @click="showActionMenu = false" class="fixed inset-0 bg-black bg-opacity-50 z-30 flex items-end">
      <div @click.stop class="bg-white w-full rounded-t-lg p-4">
        <!-- Current User Actions -->
        <div v-if="isCurrentUser">
          <button @click="goToEditProfile" class="action-button">Edit Profile</button>
          <button @click="showAddPurpose = true" class="action-button">Add Purpose</button>
          <button @click="showAddGoal = true" class="action-button">Add Goal</button>
          <button @click="logout" class="action-button text-red-600">Logout</button>
          <button @click="showPolicy = true" class="action-button text-black font-normal">Policy</button>
        </div>
        <!-- Other User Actions -->
        <div v-else>
          <button @click="addToNetwork" class="action-button">+ to NTWK</button>
          <button @click="blockUser" class="action-button text-red-600">{{ isBlocked ? 'Unblock User' : 'Block User' }}</button>
          <button @click="flagUser" class="action-button text-red-600">Flag as Inappropriate</button>
        </div>
        <button @click="showActionMenu = false" class="w-full text-center mt-4 text-gray-600">Cancel</button>
      </div>
    </div>

    <!-- Network Result Alert -->
    <div v-if="showNetworkResultAlert" class="fixed inset-0 flex items-center justify-center z-50">
      <div class="bg-white p-4 rounded-lg shadow-lg">
        <p>{{ networkResultMessage }}</p>
        <button @click="showNetworkResultAlert = false" class="mt-3 bg-green-600 text-white px-4 py-2 rounded w-full">OK</button>
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
import { useRoute, useRouter } from 'vue-router'

// Components (in a real app, these would be imported from separate files)
const NavigationHeaderView = defineComponent({
  props: {
    name: String,
    showSettings: Boolean
  },
  emits: ['back', 'settings'],
  template: `
    <header class="sticky top-0 z-20 bg-white border-b border-gray-200 flex items-center h-14 px-4">
      <button @click="$emit('back')" class="text-green-600">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h1 class="flex-1 text-center font-bold text-xl">{{ name }}</h1>
      <div class="w-8">
        <button v-if="showSettings" @click="$emit('settings')" class="text-green-600">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
      </div>
    </header>
  `
})

const ProfileInfoView = defineComponent({
  props: {
    photoUrl: String,
    city: String,
    skills: Array
  },
  template: `
    <div class="p-4 flex items-start space-x-4">
      <img :src="photoUrl || '/default-profile.png'" class="w-28 h-28 rounded-full object-cover border" alt="Profile Picture">
      <div class="pt-2">
        <p v-if="city" class="font-bold text-lg">{{ city }}</p>
        <div v-if="skills && skills.length" class="mt-1">
          <p v-for="(skill, index) in skills" :key="index" class="text-base">{{ skill }}</p>
        </div>
      </div>
    </div>
  `
})

const ProfileBroadcastView = defineComponent({
  props: {
    broadcast: String
  },
  template: `
    <div v-if="broadcast" class="px-4 pb-2">
      <p class="text-gray-600">{{ broadcast }}</p>
    </div>
  `
})

const ProfileSegmentedPicker = defineComponent({
  props: {
    segments: Array,
    modelValue: String
  },
  emits: ['update:modelValue'],
  template: `
    <div class="flex border border-black rounded overflow-hidden">
      <button 
        v-for="segment in segments" 
        :key="segment" 
        @click="$emit('update:modelValue', segment.toLowerCase())"
        :class="[
          'flex-1 py-1 text-center font-medium',
          modelValue === segment.toLowerCase() ? 'bg-black text-white' : 'bg-white text-black'
        ]"
      >
        {{ segment }}
      </button>
    </div>
  `
})

const ProfileRepSection = defineComponent({
  props: {
    portals: Array,
    isCurrentUser: Boolean,
    showAddPartner: Boolean
  },
  emits: ['portal-click', 'add-partner'],
  template: `
    <div>
      <div v-if="portals.length">
        <div v-for="portal in portals" :key="portal.id" 
             class="border-b py-2 cursor-pointer" 
             @click="$emit('portal-click', portal.id)">
          <h3 class="font-bold">{{ portal.name }}</h3>
          <p class="text-sm text-gray-500">{{ portal.subtitle }}</p>
        </div>
      </div>
      <p v-else class="text-gray-500">No purposes yet.</p>
      <button v-if="showAddPartner" @click="$emit('add-partner')" 
              class="mt-4 w-full text-center text-green-600">
        Add Partner
      </button>
    </div>
  `
})

const GoalsListSection = defineComponent({
  props: {
    goals: Array,
    isCurrentUser: Boolean
  },
  emits: ['goal-click'],
  template: `
    <div>
      <div v-if="goals.length">
        <div v-for="goal in goals" :key="goal.id" 
             class="border-b py-2 cursor-pointer" 
             @click="$emit('goal-click', goal.id)">
          <h3 class="font-bold">{{ goal.name }}</h3>
          <p class="text-sm text-gray-500">{{ goal.description }}</p>
        </div>
      </div>
      <p v-else class="text-gray-500">No goals yet.</p>
    </div>
  `
})

const WriteContentView = defineComponent({
  props: {
    writeBlocks: Array,
    isCurrentUser: Boolean
  },
  emits: ['delete-write', 'edit-write', 'new-write'],
  setup(props, { emit }) {
    const router = useRouter()

    const navigateToEdit = (writeId: number) => {
      router.push(`/write/edit/${writeId}`)
    }

    const navigateToNew = () => {
      router.push('/write/new')
    }

    return () => h('div', { class: 'space-y-4' }, [
      // Existing write blocks
      props.writeBlocks && props.writeBlocks.length > 0
        ? h('div', { class: 'space-y-4' }, props.writeBlocks.map((write: any) =>
            h('div', {
              key: write.id,
              class: 'p-4 border border-gray-200 rounded-lg hover:shadow-md transition-shadow'
            }, [
              write.title && h('h3', { class: 'font-bold text-lg mb-2' }, write.title),
              h('div', {
                class: 'text-gray-700 prose prose-sm max-w-none mb-3',
                innerHTML: write.content.substring(0, 200) + (write.content.length > 200 ? '...' : '')
              }),
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
          ))
        : h('p', { class: 'text-gray-500 text-center py-8' }, 'No content yet.'),

      // New Content Button for current user
      props.isCurrentUser && h('div', { class: 'mt-6 pt-6 border-t' }, [
        h('button', {
          onClick: navigateToNew,
          class: 'w-full py-3 bg-green-600 text-white font-bold rounded-lg hover:bg-green-700 transition-colors flex items-center justify-center space-x-2'
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

const BottomBarView = defineComponent({
  emits: ['add-click', 'message-click'],
  template: `
    <footer class="sticky bottom-0 bg-white border-t h-16 flex items-center justify-around px-4">
      <button @click="$emit('add-click')" 
              class="bg-green-600 text-white rounded-md shadow-md flex-grow h-10 flex items-center justify-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
      </button>
      <button @click="$emit('message-click')" class="ml-6 text-black">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      </button>
    </footer>
  `
})

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

const goBack = () => router.back()
const goToSettings = () => router.push('/settings')
const goToEditProfile = () => {
  showActionMenu.value = false
  router.push('/profile/edit')
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