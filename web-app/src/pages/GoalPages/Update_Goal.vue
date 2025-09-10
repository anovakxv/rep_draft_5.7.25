<!--
  UpdateGoalSheet.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-center justify-center">
    <form
      class="bg-white rounded-xl shadow-2xl p-6 w-full max-w-md space-y-6"
      @submit.prevent="submitUpdate"
      aria-label="Update Goal Progress"
    >
      <div class="flex items-center justify-between mb-2">
        <h2 class="font-bold text-lg">Update Goal</h2>
        <button type="button" @click="emit('close')" class="text-green-600 font-semibold hover:underline focus:outline-none">
          Cancel
        </button>
      </div>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Metric</label>
          <div class="text-base font-semibold text-gray-900">{{ metricName }}</div>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Amount to add</label>
          <input
            v-model="addedValue"
            type="number"
            min="0.01"
            step="0.01"
            class="form-input"
            required
            :disabled="isSubmitting"
            placeholder="Enter amount"
            @input="clearError"
            aria-label="Amount to add"
            autofocus
          />
          <div v-if="showAmountWarning" class="text-xs text-yellow-600 mt-1">
            Amount should be greater than zero.
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Note (optional)</label>
          <input
            v-model="note"
            type="text"
            class="form-input"
            :disabled="isSubmitting"
            placeholder="Add a note"
            maxlength="120"
            aria-label="Note"
          />
        </div>
        <button
          type="submit"
          :disabled="isSubmitting || !isValid"
          class="w-full py-3 bg-green-600 text-white font-bold rounded-lg text-lg flex items-center justify-center transition-colors disabled:opacity-60"
        >
          <span v-if="isSubmitting" class="animate-spin h-5 w-5 mr-2 border-2 border-white border-t-transparent rounded-full"></span>
          Submit Update
        </button>
        <div v-if="errorMessage" class="text-red-600 bg-red-100 rounded-lg p-3 text-center text-sm">{{ errorMessage }}</div>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import axios from 'axios';

const props = defineProps<{
  goalId: number;
  quota: number;
  metricName: string;
}>();

const emit = defineEmits(['close']);

const addedValue = ref('');
const note = ref('');
const isSubmitting = ref(false);
const errorMessage = ref('');

const valueNum = computed(() => Number(addedValue.value));
const isValid = computed(() => !isSubmitting.value && valueNum.value > 0 && addedValue.value !== '');

const showAmountWarning = computed(() => addedValue.value !== '' && valueNum.value <= 0);

function clearError() {
  errorMessage.value = '';
}

async function submitUpdate() {
  if (!isValid.value) {
    errorMessage.value = "Please enter a valid number greater than zero.";
    return;
  }
  isSubmitting.value = true;
  errorMessage.value = '';

  try {
    const token = localStorage.getItem('jwtToken');
    const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
    const params = {
      goals_id: props.goalId,
      added_value: valueNum.value,
      note: note.value
    };
    await axios.post(`${apiBaseUrl}/api/goals/update_filled_quota`, params, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    emit('close');
  } catch (e: any) {
    if (e.response && e.response.data && e.response.data.error) {
      errorMessage.value = e.response.data.error;
    } else {
      errorMessage.value = "Server error.";
    }
  } finally {
    isSubmitting.value = false;
  }
}
</script>

<style scoped>
.form-input {
  @apply mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm;
}
</style>