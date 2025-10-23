<!--
  Edit_Portal.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->
  
<template>
  <div class="flex flex-col h-screen bg-white">
    <!-- Header -->
    <header class="flex items-center justify-between h-15 px-4 border-b border-gray-200 shrink-0" style="background-color: #f7f7f7">
      <button @click="dismiss" style="color: #8cc65d">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <h1 class="font-bold text-xl">Edit Portal</h1>
      <button @click="save" class="font-bold" style="color: #8cc65d" :disabled="isSaving">
        {{ isSaving ? 'Saving...' : 'Save' }}
      </button>
    </header>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full"></div>
    </div>
    
    <!-- Error State -->
    <div v-else-if="errorMessage" class="flex-1 flex items-center justify-center text-red-500 p-4">
      <p>{{ errorMessage }}</p>
    </div>

    <!-- Main Form -->
    <div v-else class="flex-1 overflow-y-auto">
      <div class="p-4 space-y-6">
        <!-- Images Section -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-green-600 cursor-pointer hover:text-green-700">
            {{ selectedImages.length ? 'Add More Images' : 'Add Images' }}
            <input 
              type="file" 
              multiple 
              accept="image/*" 
              class="hidden" 
              @change="handleImageSelection" 
              :disabled="selectedImages.length >= maxImages"
            />
          </label>

          <div v-if="selectedImages.length > 0" class="relative">
            <div class="w-full aspect-video bg-gray-200 rounded-lg overflow-hidden">
              <!-- Image Carousel -->
              <div class="relative w-full h-full">
                <transition-group name="fade">
                  <div 
                    v-for="(image, idx) in selectedImages" 
                    :key="idx"
                    v-show="idx === mainImageIndex" 
                    class="absolute inset-0"
                  >
                    <img 
                      :src="image.url" 
                      class="w-full h-full object-cover"
                      alt="Portal image"
                    />
                    
                    <!-- Main Icon Badge -->
                    <div 
                      v-if="idx === 0" 
                      class="absolute top-2 left-2 bg-black bg-opacity-70 text-white text-xs px-2 py-1 rounded"
                    >
                      Main Icon
                    </div>
                    
                    <!-- Delete Button (not for main image) -->
                    <button 
                      v-if="idx !== 0"
                      @click.stop="removeImage(idx)" 
                      class="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                      </svg>
                    </button>
                  </div>
                </transition-group>
              </div>
              
              <!-- Pagination Dots -->
              <div class="absolute bottom-2 left-0 right-0 flex justify-center gap-2">
                <button 
                  v-for="(_, idx) in selectedImages" 
                  :key="idx"
                  @click="mainImageIndex = idx"
                  class="w-2 h-2 rounded-full transition-colors"
                  :class="idx === mainImageIndex ? 'bg-white' : 'bg-gray-400'"
                ></button>
              </div>
              
              <!-- Navigation Arrows (if multiple images) -->
              <div v-if="selectedImages.length > 1" class="absolute inset-y-0 left-0 right-0 flex justify-between items-center px-2">
                <button 
                  @click="prevImage" 
                  class="bg-black bg-opacity-30 rounded-full p-1 text-white hover:bg-opacity-50"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                <button 
                  @click="nextImage" 
                  class="bg-black bg-opacity-30 rounded-full p-1 text-white hover:bg-opacity-50"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
          <div v-else class="w-full aspect-video bg-gray-100 rounded-lg flex items-center justify-center text-gray-500">
            No Images Selected
          </div>
          <p class="text-xs text-gray-500">First image is used as Portal Icon. ({{ selectedImages.length }}/{{ maxImages }} images)</p>
        </div>

        <!-- Portal Info Section -->
        <div class="space-y-4">
          <div class="space-y-1">
            <label class="text-sm font-medium">Portal Name</label>
            <input 
              v-model="name" 
              type="text" 
              class="w-full p-2 border rounded-md focus:border-green-500 focus:ring-1 focus:ring-green-500"
              placeholder="Portal Name"
            />
          </div>
          
          <div class="space-y-1">
            <label class="text-sm font-medium">Subtitle</label>
            <input 
              v-model="subtitle" 
              type="text" 
              class="w-full p-2 border rounded-md focus:border-green-500 focus:ring-1 focus:ring-green-500"
              placeholder="Subtitle"
            />
          </div>
          
          <div class="space-y-1">
            <label class="text-sm font-medium">About</label>
            <input 
              v-model="about" 
              type="text" 
              class="w-full p-2 border rounded-md focus:border-green-500 focus:ring-1 focus:ring-green-500"
              placeholder="About"
            />
          </div>
        </div>

        <!-- Portal Leads Section -->
        <button 
          @click="showAddLeadsSheet = true" 
          class="w-full p-3 bg-gray-100 rounded-lg flex justify-between items-center text-left hover:bg-gray-200"
        >
          <span>Add Leads</span>
          <span class="text-gray-500 flex items-center">
            {{ selectedLeads.length }} selected
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </span>
        </button>

        <!-- Story Blocks Editor Section -->
        <div class="space-y-4">
          <h2 class="text-xl font-medium">Story</h2>
          
          <div v-if="storyBlocks.length === 0" class="text-gray-500 text-center py-4">
            No content yet.
          </div>
          
          <!-- Existing Story Blocks -->
          <div 
            v-for="block in storyBlocks" 
            :key="block.id"
            class="p-4 bg-white border rounded-lg space-y-3"
          >
            <h3 v-if="block.title" class="text-lg font-medium">{{ block.title }}</h3>
            <p class="text-base whitespace-pre-line">{{ block.content }}</p>
            <div class="flex justify-end space-x-4">
              <button 
                @click="editBlock(block)" 
                class="text-blue-600 text-base hover:text-blue-800"
              >
                Edit
              </button>
              <button 
                @click="confirmDeleteBlock(block)" 
                class="text-red-600 text-base hover:text-red-800"
              >
                Delete
              </button>
            </div>
          </div>
          
          <!-- Divider -->
          <div class="border-t border-gray-200 my-4"></div>
          
          <!-- Add/Edit Block Form -->
          <div class="space-y-3">
            <p class="text-sm text-gray-500">
              {{ editingStoryBlock ? 'Edit block:' : 'Add new block:' }}
            </p>
            
            <input 
              v-model="storyTitle" 
              type="text" 
              placeholder="Title" 
              class="w-full p-2 border rounded-lg text-lg focus:border-green-500 focus:ring-1 focus:ring-green-500"
            />
            
            <textarea 
              v-model="storyText" 
              placeholder="Content" 
              class="w-full p-2 border rounded-lg h-32 text-base focus:border-green-500 focus:ring-1 focus:ring-green-500"
            ></textarea>
            
            <div class="flex justify-center">
              <button 
                v-if="editingStoryBlock"
                @click="cancelEditingBlock" 
                class="text-gray-600 mr-4 hover:text-gray-800"
              >
                Cancel Edit
              </button>
              <button 
                @click="saveStoryBlock" 
                class="font-bold text-green-600 hover:text-green-700"
              >
                {{ editingStoryBlock ? 'Update' : 'Save' }}
              </button>
            </div>
          </div>
        </div>

        <!-- Payment Settings -->
        <div class="pt-2 pb-2">
          <div class="border-t border-gray-200 my-4"></div>
          <button 
            @click="navigateToPaymentSettings" 
            class="w-full p-3 bg-gray-100 rounded-lg flex justify-between items-center text-left hover:bg-gray-200"
          >
            <span class="flex items-center">
              <span class="mr-2 text-xl">💳</span>
              <span class="font-semibold">Payment Settings</span>
            </span>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>

        <!-- Delete Portal Button -->
        <div class="pt-8 pb-12">
          <button 
            @click="showDeletePortalAlert = true" 
            class="w-full py-3 text-red-500 font-bold text-lg bg-red-50 rounded-lg hover:bg-red-100"
          >
            Delete Portal
          </button>
        </div>
      </div>
    </div>

    <!-- Modals and Alerts -->
    
    <!-- Add Leads Sheet -->
    <div 
      v-if="showAddLeadsSheet" 
      class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center"
      @click="showAddLeadsSheet = false"
    >
      <div 
        class="bg-white rounded-lg w-full max-w-md h-3/4 flex flex-col" 
        @click.stop
      >
        <!-- Header -->
        <div class="p-4 border-b flex justify-between items-center">
          <button 
            @click="showAddLeadsSheet = false" 
            class="text-gray-600 hover:text-gray-800"
          >
            Cancel
          </button>
          <h2 class="font-bold text-lg">Select Leads</h2>
          <button 
            @click="saveSelectedLeads" 
            class="font-bold text-green-600 hover:text-green-700"
          >
            Done
          </button>
        </div>
        
        <!-- Body -->
        <div 
          v-if="loadingNetworkMembers" 
          class="flex-1 flex items-center justify-center"
        >
          <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full"></div>
        </div>
        <div v-else class="flex-1 overflow-y-auto">
          <div 
            v-for="user in networkMembers" 
            :key="user.id"
            @click="toggleUserSelection(user)"
            class="p-4 border-b flex justify-between items-center cursor-pointer hover:bg-gray-50"
          >
            <span>{{ user.full_name || user.fname + ' ' + (user.lname || '') }}</span>
            <svg 
              v-if="isUserSelected(user)" 
              xmlns="http://www.w3.org/2000/svg" 
              class="h-5 w-5 text-green-600" 
              viewBox="0 0 20 20" 
              fill="currentColor"
            >
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Delete Story Block Confirmation -->
    <div 
      v-if="showDeleteStoryBlockAlert" 
      class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-lg p-6 max-w-sm w-full">
        <h3 class="text-lg font-bold mb-3">Delete Story Block</h3>
        <p class="text-gray-600 mb-6">Are you sure you want to delete this story block? This action cannot be undone.</p>
        <div class="flex justify-end space-x-3">
          <button 
            @click="showDeleteStoryBlockAlert = false" 
            class="px-4 py-2 border rounded hover:bg-gray-50"
          >
            Cancel
          </button>
          <button 
            @click="deleteStoryBlock" 
            class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
    
    <!-- Delete Portal Confirmation -->
    <div 
      v-if="showDeletePortalAlert" 
      class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-lg p-6 max-w-sm w-full">
        <h3 class="text-lg font-bold mb-3">Delete Portal?</h3>
        <p class="text-gray-600 mb-6">Are you sure you want to delete this portal? This cannot be undone.</p>
        <div class="flex justify-end space-x-3">
          <button 
            @click="showDeletePortalAlert = false" 
            class="px-4 py-2 border rounded hover:bg-gray-50"
          >
            Cancel
          </button>
          <button 
            @click="deletePortal" 
            class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import api from '@/pages/utils/api';
import { ref, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { v4 as uuidv4 } from 'uuid'; // You'll need to add this package

// --- Interfaces ---
interface User {
  id: number;
  full_name?: string;  // Backend returns snake_case
  fname?: string;
  lname?: string;
  displayName?: string;
}

interface PortalDetail {
  id: number;
  name: string;
  subtitle?: string;
  about?: string;
  aTexts?: PortalText[];
  aUsers?: User[];
  aGoals?: EditableGoal[];
}

interface PortalText { 
  id: number; 
  title?: string; 
  text?: string; 
  section?: string; 
}

interface PortalWriteBlock { 
  id: string; 
  title?: string; 
  content: string; 
  order?: number; 
  created_at?: string;
  updated_at?: string;
}

interface ImageFile { 
  file: File; 
  url: string; 
}

interface EditableGoal {
  id: string;
  title: string;
  subtitle?: string;
  progressPercent?: number;
  typeName?: string;
  chartData?: any[];
}

// --- Composables & Initial Setup ---
const route = useRoute();
const router = useRouter();
const portalId = Number(route.params.id) || 0; // 0 for new portal
const userId = Number(localStorage.getItem('userId'));
const token = localStorage.getItem('jwtToken');
const authHeaders = { headers: { Authorization: `Bearer ${token}` } };

// --- State ---
const isLoading = ref(true);
const isSaving = ref(false);
const errorMessage = ref<string | null>(null);
const maxImages = 10;

// Portal Fields
const name = ref('');
const subtitle = ref('');
const about = ref('');
const offeringText = ref('');
const selectedImages = ref<ImageFile[]>([]);
const mainImageIndex = ref(0);
const portalDetail = ref<PortalDetail | null>(null);
const goals = ref<EditableGoal[]>([]);

// Story Blocks
const storyBlocks = ref<PortalWriteBlock[]>([]);
const storyTitle = ref('');
const storyText = ref('');
const editingStoryBlock = ref<PortalWriteBlock | null>(null);
const blockToDelete = ref<PortalWriteBlock | null>(null);

// Leads
const selectedLeads = ref<User[]>([]);
const tempSelectedLeads = ref<User[]>([]);
const networkMembers = ref<User[]>([]);
const loadingNetworkMembers = ref(false);

// Modal/Alert State
const showAddLeadsSheet = ref(false);
const showDeleteStoryBlockAlert = ref(false);
const showDeletePortalAlert = ref(false);

// --- Methods ---
const dismiss = () => router.back();

const fetchPortalData = async () => {
  if (portalId === 0) { // New portal
    isLoading.value = false;
    return;
  }
  
  try {
    const res = await api.get(`/api/portal/details?portals_id=${portalId}&user_id=${userId}`);
    const portal: PortalDetail = res.data.result;
    
    portalDetail.value = portal;
    name.value = portal.name;
    subtitle.value = portal.subtitle || '';
    about.value = portal.about || '';
    offeringText.value = portal.about || '';
    
    // Convert portal texts to story blocks
    storyBlocks.value = (portal.aTexts || [])
      .filter(t => t.section === 'story')
      .map((t, i) => ({ 
        id: uuidv4(), 
        title: t.title || '', 
        content: t.text || '', 
        order: i 
      }));
    
    // Set selected leads
    selectedLeads.value = portal.aUsers || [];
    
    // Load goals if they exist
    if (portal.aGoals) {
      goals.value = portal.aGoals.map(goal => ({
        id: uuidv4(),
        title: goal.title,
        subtitle: goal.subtitle,
        progressPercent: goal.progressPercent,
        typeName: goal.typeName,
        chartData: goal.chartData
      }));
    }
    
  } catch (err) {
    console.error('Failed to load portal:', err);
    errorMessage.value = 'Failed to load portal data.';
  } finally {
    isLoading.value = false;
  }
};

const handleImageSelection = (event: Event) => {
  const input = event.target as HTMLInputElement;
  if (!input.files) return;
  
  const availableSlots = maxImages - selectedImages.value.length;
  if (availableSlots <= 0) return;
  
  const files = Array.from(input.files).slice(0, availableSlots);
  
  // Process files
  for (const file of files) {
    const url = URL.createObjectURL(file);
    selectedImages.value.push({ file, url });
  }
  
  // Reset input so the same file can be selected again
  input.value = '';
};

const removeImage = (index: number) => {
  if (index < 0 || index >= selectedImages.value.length) return;
  
  const imageToRemove = selectedImages.value[index];
  URL.revokeObjectURL(imageToRemove.url);
  
  selectedImages.value.splice(index, 1);
  
  if (mainImageIndex.value >= selectedImages.value.length) {
    mainImageIndex.value = Math.max(0, selectedImages.value.length - 1);
  }
};

const nextImage = () => {
  if (selectedImages.value.length <= 1) return;
  mainImageIndex.value = (mainImageIndex.value + 1) % selectedImages.value.length;
};

const prevImage = () => {
  if (selectedImages.value.length <= 1) return;
  mainImageIndex.value = (mainImageIndex.value - 1 + selectedImages.value.length) % selectedImages.value.length;
};

// Story block functions
const saveStoryBlock = () => {
  if (!storyText.value.trim()) {
    return; // Don't save empty blocks
  }
  
  if (editingStoryBlock.value) {
    // Update existing block
    const index = storyBlocks.value.findIndex(b => b.id === editingStoryBlock.value!.id);
    if (index !== -1) {
      storyBlocks.value[index] = { 
        ...storyBlocks.value[index], 
        title: storyTitle.value, 
        content: storyText.value 
      };
    }
  } else {
    // Add new block
    const newBlock: PortalWriteBlock = {
      id: uuidv4(),
      title: storyTitle.value,
      content: storyText.value,
      order: storyBlocks.value.length
    };
    storyBlocks.value.push(newBlock);
  }
  
  // Reset form
  editingStoryBlock.value = null;
  storyTitle.value = '';
  storyText.value = '';
};

const editBlock = (block: PortalWriteBlock) => {
  editingStoryBlock.value = block;
  storyTitle.value = block.title || '';
  storyText.value = block.content;
};

const cancelEditingBlock = () => {
  editingStoryBlock.value = null;
  storyTitle.value = '';
  storyText.value = '';
};

const confirmDeleteBlock = (block: PortalWriteBlock) => {
  blockToDelete.value = block;
  showDeleteStoryBlockAlert.value = true;
};

const deleteStoryBlock = () => {
  if (blockToDelete.value) {
    storyBlocks.value = storyBlocks.value.filter(b => b.id !== blockToDelete.value!.id);
  }
  showDeleteStoryBlockAlert.value = false;
  blockToDelete.value = null;
};

// Lead selection functions
const fetchNetworkMembers = async () => {
  if (networkMembers.value.length > 0) return;
  
  loadingNetworkMembers.value = true;
  
  try {
    const res = await api.get(`/api/user/members_of_my_network`);
    networkMembers.value = res.data.result || [];
  } catch (err) {
    console.error('Failed to fetch network members:', err);
  } finally {
    loadingNetworkMembers.value = false;
  }
};

const toggleUserSelection = (user: User) => {
  const index = tempSelectedLeads.value.findIndex(u => u.id === user.id);
  if (index > -1) {
    tempSelectedLeads.value.splice(index, 1);
  } else {
    tempSelectedLeads.value.push(user);
  }
};

const isUserSelected = (user: User) => {
  return tempSelectedLeads.value.some(u => u.id === user.id);
};

const saveSelectedLeads = () => {
  selectedLeads.value = [...tempSelectedLeads.value];
  showAddLeadsSheet.value = false;
};

// Payment settings
const navigateToPaymentSettings = () => {
  router.push(`/portal/${portalId}/payment-setup`);
};

// Save the portal
const save = async () => {
  // Basic validation
  if (!name.value.trim()) {
    alert('Portal name is required');
    return;
  }

  isSaving.value = true;
  const formData = new FormData();
  const isNew = portalId === 0;
  const endpoint = isNew ? '/api/portal/' : '/api/portal/edit';

  // Append text fields
  if (!isNew) formData.append('portal_id', String(portalId));
  formData.append('users_id', String(userId));
  formData.append('name', name.value);
  formData.append('subtitle', subtitle.value);
  // Backend requires 'about' field - provide default if empty
  formData.append('about', about.value.trim() || ' ');

  // Append story blocks (aTexts)
  const texts = storyBlocks.value.map(block => ({
    title: block.title || '',
    text: block.content,
    section: 'story'
  }));
  formData.append('aTexts', JSON.stringify(texts));

  // Append leads (aLeadsIDs)
  const leadIds = selectedLeads.value.map(lead => lead.id);
  formData.append('aLeadsIDs', JSON.stringify(leadIds));

  // Debug logging (matching Swift implementation)
  console.log("Selected Leads:", leadIds);
  console.log("aLeadsIDs JSON:", JSON.stringify(leadIds));

  // Append images
  selectedImages.value.forEach((imgFile, index) => {
    formData.append('images', imgFile.file, `portal_image_${index}.jpg`);
  });

  // Debug: Log FormData contents
  console.log("FormData contents:");
  for (let [key, value] of formData.entries()) {
    console.log(`  ${key}:`, value);
  }

  try {
    // Browser will automatically set Content-Type with proper boundary for FormData
    const response = await api.post(endpoint, formData);

    console.log('Portal saved successfully:', response.data);
    dismiss();
  } catch (err) {
    console.error('Failed to save portal:', err);
    alert('Failed to save portal. Please try again.');
  } finally {
    isSaving.value = false;
  }
};

// Delete the portal
const deletePortal = async () => {
  isSaving.value = true;
  
  try {
    await api.post(`/api/portal/delete`, {
      portal_id: portalId,
      user_id: userId
    }, authHeaders);
    
    console.log('Portal deleted successfully');
    router.push('/main');
  } catch (err) {
    console.error('Failed to delete portal:', err);
    alert('Failed to delete portal. Please try again.');
  } finally {
    isSaving.value = false;
    showDeletePortalAlert.value = false;
  }
};

// --- Lifecycle Hooks ---
onMounted(() => {
  if (!token) {
    router.push('/login');
    return;
  }
  
  fetchPortalData();
});

// When the add leads sheet is opened, fetch network members and set up temp selection
watch(showAddLeadsSheet, (newVal) => {
  if (newVal) {
    fetchNetworkMembers();
    tempSelectedLeads.value = [...selectedLeads.value];
  }
});
</script>

<style scoped>
/* Transitions for image carousel */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Fix for textarea resize */
textarea {
  resize: vertical;
  min-height: 120px;
}

/* Ensure buttons have consistent styling */
button {
  transition: all 0.2s ease;
}
</style>