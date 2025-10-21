<!--
  EditGoalPage.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="fixed inset-0 bg-gray-100 z-40 flex flex-col">
    <!-- Header -->
    <header class="flex items-center justify-between h-14 px-4 border-b bg-white shrink-0">
      <button @click="emit('close')" class="text-green-600 font-semibold p-2 -ml-2">
        Cancel
      </button>
      <h1 class="font-bold text-lg">{{ isEdit ? 'Edit Goal' : 'Add Goal' }}</h1>
      <div class="w-16"></div> <!-- Spacer -->
    </header>

    <form class="flex-1 overflow-y-auto" @submit.prevent="saveGoal">
      <div class="max-w-2xl mx-auto p-4 space-y-6">
        <!-- Main Goal Details Section -->
        <div class="bg-white rounded-lg p-4 space-y-4 border">
          <h2 class="font-semibold text-lg -mt-1">{{ isEdit ? 'Edit Goal' : 'Add Goal' }}</h2>
          <div>
            <label class="block text-sm font-medium text-gray-700">Title</label>
            <input v-model="title" type="text" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm" required />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Subtitle</label>
            <input v-model="subtitle" type="text" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Description</label>
            <textarea v-model="description" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm" rows="3"></textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Goal Type</label>
            <select v-model="goalType" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm">
              <option v-for="type in goalTypes" :key="type" :value="type">{{ type }}</option>
            </select>
          </div>
          <div v-if="goalType === 'Other'">
            <label class="block text-sm font-medium text-gray-700">Metric</label>
            <input v-model="metric" type="text" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm" placeholder="e.g., 'Tasks Completed'"/>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Quota</label>
            <input v-model="quota" type="number" min="1" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm" required />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Reporting Increment</label>
            <select v-model="reportingIncrementId" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm" :disabled="isLoadingIncrements">
              <option v-if="isLoadingIncrements" disabled value="">Loading...</option>
              <option v-for="inc in incrementsToUse" :key="inc.id" :value="inc.id">{{ inc.title }}</option>
            </select>
          </div>
        </div>

        <!-- Associated Portal Section -->
        <div class="bg-white rounded-lg p-4 border">
          <h2 class="font-semibold text-lg -mt-1">Associated Portal</h2>
          <p class="text-gray-500">{{ associatedPortalName || 'N/A (Personal Goal)' }}</p>
        </div>

        <!-- Action Section -->
        <div class="space-y-3">
          <button
            type="submit"
            :disabled="isSaving || !title || !quota || !reportingIncrementId"
            class="w-full py-3 text-white font-bold rounded-lg text-lg flex items-center justify-center transition-colors disabled:opacity-60"
            :style="{ backgroundColor: '#8cc65d' }"
          >
            <div v-if="isSaving" class="animate-spin h-5 w-5 mr-3 border-2 border-white border-t-transparent rounded-full"></div>
            <span>{{ isEdit ? 'Save Changes' : 'Add Goal' }}</span>
          </button>
          <div v-if="errorMessage" class="text-red-600 bg-red-100 rounded-lg p-3 text-center text-sm">{{ errorMessage }}</div>
        </div>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import api from '@/pages/utils/api';

// --- Props and Emits ---
const props = defineProps<{
  existingGoal?: { id: number; title: string; subtitle: string; description: string; quota: number; typeName: string; metricName: string; reportingName: string; };
  portalId?: number;
  userId: number;
  reportingIncrements: { id: number; title: string }[];
  associatedPortalName?: string;
}>();

const emit = defineEmits(['close']);

// --- State ---
const title = ref('');
const subtitle = ref('');
const description = ref('');
const quota = ref('');
const goalType = ref('Recruiting');
const metric = ref('');
const reportingIncrementId = ref<number | null>(null);
const isSaving = ref(false);
const errorMessage = ref('');
const isLoadingIncrements = ref(false);
const loadedIncrements = ref<{ id: number; title: string }[]>([]);

const goalTypes = ["Recruiting", "Sales", "Fund", "Marketing", "Hours", "Other"];
const isEdit = computed(() => !!props.existingGoal);
const incrementsToUse = computed(() => loadedIncrements.value.length ? loadedIncrements.value : props.reportingIncrements);

// --- API Calls ---
async function loadReportingIncrements() {
  if (isLoadingIncrements.value) return;
  isLoadingIncrements.value = true;
  try {
    const res = await api.get('/api/goals/reporting_increments');
    loadedIncrements.value = res.data.reportingIncrements;

    // Set default selection if not already set. Mimics Swift logic.
    if (reportingIncrementId.value === null) {
      // 1. Try to match existing goal's reporting name
      if (props.existingGoal) {
        const match = loadedIncrements.value.find(inc => inc.title === props.existingGoal?.reportingName);
        if (match) {
          reportingIncrementId.value = match.id;
          return; // Found a match, stop here
        }
      }
      // 2. If no match or new goal, default to "Daily"
      const daily = loadedIncrements.value.find(inc => inc.title.trim().toLowerCase() === 'daily');
      if (daily) {
        reportingIncrementId.value = daily.id;
        return; // Found daily, stop here
      }
      // 3. If no "Daily", default to the first increment in the list
      if (loadedIncrements.value.length > 0) {
        reportingIncrementId.value = loadedIncrements.value[0].id;
      }
    }
  } catch (e) {
    errorMessage.value = "Failed to load reporting increments.";
  } finally {
    isLoadingIncrements.value = false;
  }
}

async function saveGoal() {
  isSaving.value = true;
  errorMessage.value = '';
  try {
    const url = isEdit.value ? '/api/goals/edit' : '/api/goals/create';

    const params: any = {
      title: title.value,
      subtitle: subtitle.value,
      description: description.value,
      goal_type: goalType.value,
      quota: Number(quota.value) || 1,
      reporting_increments_id: reportingIncrementId.value,
      user_id: props.userId
    };
    if (props.portalId && props.portalId !== 0) params.portals_id = props.portalId;
    if (goalType.value === "Other") params.metric = metric.value;
    if (isEdit.value) params.goals_id = props.existingGoal?.id;

    await api.post(url, params);
    emit('close'); // Success
  } catch (e: any) {
    errorMessage.value = e.response?.data?.error || "An unknown server error occurred.";
  } finally {
    isSaving.value = false;
  }
}

// --- Lifecycle ---
onMounted(() => {
  if (props.existingGoal) {
    title.value = props.existingGoal.title;
    subtitle.value = props.existingGoal.subtitle;
    description.value = props.existingGoal.description;
    quota.value = String(Math.round(props.existingGoal.quota));
    goalType.value = props.existingGoal.typeName;
    metric.value = props.existingGoal.metricName;
    // Attempt to set from pre-passed increments first
    const match = props.reportingIncrements.find(inc => inc.title === props.existingGoal?.reportingName);
    if (match) reportingIncrementId.value = match.id;
  }
  loadReportingIncrements();
});
</script>