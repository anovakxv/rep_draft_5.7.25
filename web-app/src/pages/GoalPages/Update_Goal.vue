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
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm"
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
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm"
            :disabled="isSubmitting"
            placeholder="Add a note"
            maxlength="120"
            aria-label="Note"
          />
        </div>

        <!-- Attachments Section -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Attachments</label>
          <button
            type="button"
            @click="triggerFileInput"
            :disabled="isSubmitting || selectedImages.length >= 5"
            class="flex items-center gap-2 px-4 py-2 border border-green-500 rounded-lg hover:bg-green-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            style="color: #8cc65d;"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span>Add Photo (optional)</span>
          </button>
          <input
            ref="fileInput"
            type="file"
            accept="image/*"
            multiple
            class="hidden"
            @change="handleFileSelect"
            :disabled="isSubmitting"
          />
          <div v-if="selectedImages.length >= 5" class="text-xs text-gray-500 mt-1">
            Maximum 5 images
          </div>

          <!-- Image Previews -->
          <div v-if="selectedImages.length > 0" class="mt-4 space-y-3">
            <div
              v-for="(image, index) in selectedImages"
              :key="index"
              class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg"
            >
              <img
                :src="image.preview"
                alt="Preview"
                class="w-16 h-16 object-cover rounded"
              />
              <div class="flex-1">
                <input
                  v-model="attachmentNotes[index]"
                  type="text"
                  placeholder="Note for image"
                  class="w-full px-2 py-1 text-sm border rounded focus:ring-green-500 focus:border-green-500"
                  :disabled="isSubmitting"
                />
              </div>
              <button
                type="button"
                @click="removeImage(index)"
                :disabled="isSubmitting"
                class="text-red-500 hover:text-red-700 disabled:opacity-50"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>
          </div>
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
import api from '@/pages/utils/api';

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

// Image upload state
interface SelectedImage {
  file: File;
  preview: string;
}
const selectedImages = ref<SelectedImage[]>([]);
const attachmentNotes = ref<string[]>([]);
const fileInput = ref<HTMLInputElement | null>(null);

const valueNum = computed(() => Number(addedValue.value));
const isValid = computed(() => !isSubmitting.value && valueNum.value > 0 && addedValue.value !== '');

const showAmountWarning = computed(() => addedValue.value !== '' && valueNum.value <= 0);

function clearError() {
  errorMessage.value = '';
}

function triggerFileInput() {
  fileInput.value?.click();
}

function handleFileSelect(event: Event) {
  const target = event.target as HTMLInputElement;
  const files = target.files;
  if (!files) return;

  // Limit to 5 images total
  const remainingSlots = 5 - selectedImages.value.length;
  const filesToAdd = Array.from(files).slice(0, remainingSlots);

  filesToAdd.forEach(file => {
    // Create preview URL
    const preview = URL.createObjectURL(file);
    selectedImages.value.push({ file, preview });
    attachmentNotes.value.push('');
  });

  // Reset input
  if (fileInput.value) {
    fileInput.value.value = '';
  }
}

function removeImage(index: number) {
  // Revoke the preview URL to free memory
  URL.revokeObjectURL(selectedImages.value[index].preview);
  selectedImages.value.splice(index, 1);
  attachmentNotes.value.splice(index, 1);
}

async function submitUpdate() {
  if (!isValid.value) {
    errorMessage.value = "Please enter a valid number greater than zero.";
    return;
  }
  isSubmitting.value = true;
  errorMessage.value = '';

  try {
    // Use FormData for multipart/form-data if there are images
    if (selectedImages.value.length > 0) {
      const formData = new FormData();
      formData.append('goals_id', props.goalId.toString());
      formData.append('added_value', valueNum.value.toString());
      formData.append('note', note.value);

      // Add images
      selectedImages.value.forEach((image, index) => {
        formData.append('files', image.file);
        formData.append(`sources_notes[${index}]`, attachmentNotes.value[index] || '');
      });

      await api.post('/api/goals/update_filled_quota', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
    } else {
      // JSON if no images
      const params = {
        goals_id: props.goalId,
        added_value: valueNum.value,
        note: note.value
      };
      await api.post('/api/goals/update_filled_quota', params);
    }

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