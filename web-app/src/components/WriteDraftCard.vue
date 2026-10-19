<!--
  WriteDraftCard.vue
  The Write-section draft from Rep Onboarding, shown in the chat for the member to review.
  Each entry is editable; nothing is saved to the profile until the member taps Save.
-->

<template>
  <div class="w-full rounded border border-gray-200 bg-white overflow-hidden">
    <div class="flex items-center gap-2 px-4 py-2.5 border-b border-gray-100 bg-[#f7f7f7]">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0" style="color: #006600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
      </svg>
      <p class="flex-1 text-sm font-semibold text-gray-900">Your Write section</p>
      <span v-if="status === 'saved'" class="text-xs font-semibold" style="color: #006600">✓ Saved to your profile</span>
      <span v-else-if="status === 'discarded'" class="text-xs font-medium text-gray-400">Discarded</span>
      <span v-else class="text-xs text-gray-500">Review and edit before saving</span>
    </div>

    <div class="divide-y divide-gray-100">
      <div v-for="(entry, i) in local" :key="entry.pillar" class="px-4 py-3">
        <label :for="`draft-${messageId}-${i}`" class="block text-[13px] font-semibold text-gray-900">{{ entry.title }}</label>
        <textarea
          v-if="editable"
          :id="`draft-${messageId}-${i}`"
          v-model="entry.content"
          rows="4"
          maxlength="2500"
          class="mt-1.5 w-full resize-y rounded-sm border border-gray-200 bg-white px-3 py-2 text-[14px] leading-relaxed text-gray-800 focus:outline-none focus:border-[#8cc65d] focus:ring-1 focus:ring-[#8cc65d]"
        ></textarea>
        <p v-else :id="`draft-${messageId}-${i}`" class="mt-1 text-[14px] leading-relaxed text-gray-700 whitespace-pre-line">{{ entry.content }}</p>
      </div>
    </div>

    <div v-if="editable" class="px-4 py-3 border-t border-gray-100 flex flex-wrap items-center gap-2">
      <button
        type="button"
        class="h-9 px-4 rounded-sm text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50"
        style="background-color: #8cc65d"
        :disabled="busy || !canSave"
        @click="save"
      >{{ busy ? 'Saving…' : 'Save to my profile' }}</button>
      <button
        type="button"
        class="h-9 px-3 rounded-sm text-sm font-medium text-gray-600 hover:bg-gray-100 disabled:opacity-50"
        :disabled="busy"
        @click="emit('discard')"
      >Discard</button>
      <p class="w-full text-xs text-gray-400 mt-1">Want changes? Tell me what to adjust below, or edit it here.</p>
      <p v-if="error" class="w-full text-sm text-red-600">{{ error }}</p>
    </div>

    <div v-else-if="status === 'saved'" class="px-4 py-3 border-t border-gray-100 flex flex-wrap items-center gap-3">
      <RouterLink :to="`/profile/${userId}`" class="text-sm font-semibold hover:underline" style="color: #006600">View my profile</RouterLink>
      <button v-if="showContinue" type="button" class="text-sm font-semibold hover:underline" style="color: #006600" @click="emit('continue')">Continue with Rep Coach →</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { RouterLink } from 'vue-router';
import type { DraftEntry } from '@/pages/utils/useRepOnboarding';

const props = defineProps<{
  messageId: number;
  payload: any;
  saveEntries: (entries: DraftEntry[]) => Promise<void>;
  showContinue?: boolean;
}>();

const emit = defineEmits<{ (e: 'discard'): void; (e: 'continue'): void }>();

const userId = localStorage.getItem('userId') || '';
const local = ref<DraftEntry[]>([]);
const busy = ref(false);
const error = ref('');

const status = computed<string>(() => props.payload?.status || 'pending');
const editable = computed(() => status.value === 'pending');
const canSave = computed(() => local.value.length > 0 && local.value.every((e) => e.content.trim()));

watch(
  () => props.payload,
  (p) => {
    local.value = (p?.write_draft?.entries || []).map((e: DraftEntry) => ({ ...e }));
  },
  { immediate: true }
);

async function save() {
  if (busy.value || !canSave.value) return;
  busy.value = true;
  error.value = '';
  try {
    await props.saveEntries(local.value);
  } catch {
    error.value = "Couldn't save everything. Check your profile's Write section, then try again.";
  } finally {
    busy.value = false;
  }
}
</script>
