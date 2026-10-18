<!--
  GoalCard.vue
  One Goal Team as a Value card: mobile's 4-bar chart at full size, the title, progress
  and % with the goal-type tag. Optionally the team's avatars and a Message-team button.
  Used by the desktop Person card (Goals tab) and the desktop Purpose page (Goal Teams).
-->

<template>
  <RouterLink
    :to="`/goal/${goal.id}`"
    class="group flex items-center gap-5 bg-white border border-gray-200 rounded p-4 hover:border-gray-300 hover:shadow-sm transition"
  >
    <!-- Last 4 reporting periods against quota -->
    <span class="flex items-end gap-1.5 shrink-0 h-20 w-[114px] border-b border-gray-200" aria-hidden="true">
      <span
        v-for="(bar, i) in bars"
        :key="i"
        class="w-6 rounded-t-sm"
        style="background-color: #8cc65d"
        :style="{ height: `${bar}%`, minHeight: bar > 0 ? '3px' : '0' }"
      ></span>
    </span>

    <span class="flex-1 min-w-0">
      <span class="flex items-start gap-2">
        <span class="flex-1 min-w-0 font-semibold text-base text-gray-900 leading-snug line-clamp-2 group-hover:underline">{{ goal.title || goal.name }}</span>
        <span v-if="highlight" class="shrink-0 px-1.5 py-0.5 rounded-sm text-[10px] font-bold uppercase tracking-wide text-white" style="background-color: #006600">{{ highlight }}</span>
      </span>
      <span v-if="goal.subtitle?.trim()" class="block text-sm text-gray-500 leading-snug truncate mt-0.5">{{ goal.subtitle }}</span>
      <span class="mt-2.5 flex items-center gap-2.5">
        <span class="flex-1 h-2 rounded-full bg-gray-100 overflow-hidden">
          <span class="block h-full rounded-full" style="background-color: #8cc65d" :style="{ width: `${pct}%` }"></span>
        </span>
        <span class="text-sm font-semibold text-gray-900 shrink-0">{{ pct }}%</span>
      </span>

      <span class="mt-2 flex items-center gap-2">
        <span class="px-2 py-0.5 rounded-sm bg-gray-100 text-[11px] font-semibold uppercase tracking-wide text-gray-600">{{ tag }}</span>

        <!-- Team -->
        <span v-if="team?.length" class="flex -space-x-1.5 ml-1" :title="teamNames">
          <span v-for="m in team.slice(0, 5)" :key="m.id" class="w-6 h-6 rounded-full ring-2 ring-white overflow-hidden bg-gray-300 flex items-center justify-center text-[9px] font-semibold text-white">
            <img v-if="memberPhoto(m)" :src="memberPhoto(m)" alt="" class="w-full h-full object-cover" />
            <template v-else>{{ getInitials(memberName(m)) }}</template>
          </span>
        </span>
        <span v-if="(team?.length ?? 0) > 5" class="text-xs text-gray-500">+{{ (team?.length ?? 0) - 5 }}</span>

        <button
          v-if="showMessage"
          type="button"
          class="ml-auto shrink-0 h-7 px-2.5 inline-flex items-center gap-1 rounded-sm border text-xs font-semibold hover:bg-[#f3f9ee] disabled:opacity-50"
          style="border-color: #006600; color: #006600"
          :disabled="busy"
          :aria-label="`Message the ${goal.title} Goal Team`"
          @click.prevent.stop="emit('message', goal)"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
          {{ busy ? 'Opening…' : 'Message team' }}
        </button>
      </span>
    </span>
  </RouterLink>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { RouterLink } from 'vue-router';
import { getInitials, photoUrl } from '@/pages/utils/desktopShell';

const props = defineProps<{
  goal: any;
  team?: any[];
  showMessage?: boolean;
  busy?: boolean;
  highlight?: string; // small badge, e.g. "Supporters"
}>();

const emit = defineEmits<{ (e: 'message', goal: any): void }>();

const pct = computed(() => {
  const raw = props.goal.progressPercent ?? (props.goal.progress ?? 0) * 100;
  return Math.round(Math.min(100, Math.max(0, Number(raw) || 0)));
});

// Matches the mobile tag: the goal type, or for "Other" the metric name (9 chars)
const tag = computed(() => {
  const g = props.goal;
  if (g.typeName?.toLowerCase() === 'other') return (g.metricName?.trim() || g.typeName || 'Goal').substring(0, 9);
  return g.typeName || 'Goal';
});

// Last 4 reporting periods as % of quota
const bars = computed<number[]>(() => {
  const quota = props.goal.quota > 0 ? props.goal.quota : 1;
  return (props.goal.chartData || []).slice(-4).map((bar: any) => Math.min(100, Math.max(0, ((bar.value || 0) / quota) * 100)));
});

function memberName(m: any): string {
  return m.full_name || m.name || [m.fname, m.lname].filter(Boolean).join(' ') || 'Member';
}

function memberPhoto(m: any): string | undefined {
  return photoUrl(m.profile_picture_url || m.photo_url || m.imageUrl);
}

const teamNames = computed(() => (props.team || []).map(memberName).join(', '));
</script>
