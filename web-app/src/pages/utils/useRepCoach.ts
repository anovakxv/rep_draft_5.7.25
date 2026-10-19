// src/pages/utils/useRepCoach.ts
// Rep Coach state shared by the pinned chat row, the chat panel and the dashboard.
// The conversation is saved on the server (thread "coach"): the app loads the history,
// sends only the member's new message, and can delete one message or all of them.

import { ref, computed } from 'vue';
import api from '@/pages/utils/api';
import { onboardingStatus, resetOnboardingLocal, fromServer, type OnboardingStatus } from '@/pages/utils/useRepOnboarding';

export interface CoachCard {
  type: 'purpose' | 'person' | 'goal';
  id: number;
  title: string;
  subtitle: string;
  image_url: string | null;
  city: string;
  progress?: number;
}

export interface CoachMessage {
  id?: number;              // saved on the server (absent for local-only error notes)
  role: 'user' | 'assistant';
  text: string;
  kind?: 'text' | 'write_draft';
  payload?: any;
  cards?: Record<string, CoachCard>;
  created_at?: string;
  error?: boolean;          // local-only notice (not saved)
  pending?: boolean;        // sent, waiting for the server
  localId?: number;         // matches a pending message to its saved version
}

const PAGE = 50;

const enabled = ref<boolean | null>(null);
const sending = ref(false);
const messages = ref<CoachMessage[]>([]);
const hasMore = ref(false);
const loadingHistory = ref(false);
let loadedFor = '';
let statusRequest: Promise<void> | null = null;

export function stripCardMarkers(text: string): string {
  return text.replace(/\[\[\s*(purpose|person|goal)\s*:\s*\d+\s*\]\]/gi, '').replace(/\*\*/g, '').replace(/\s+/g, ' ').trim();
}

export function useRepCoach() {
  const userKey = () => localStorage.getItem('userId') || '';

  function checkStatus(): Promise<void> {
    if (!localStorage.getItem('jwtToken')) {
      enabled.value = false;
      return Promise.resolve();
    }
    if (!statusRequest) {
      statusRequest = api
        .get('/api/coach/status')
        .then((res) => {
          enabled.value = !!res.data?.enabled;
          if (res.data?.onboarding_status) onboardingStatus.value = res.data.onboarding_status as OnboardingStatus;
        })
        .catch(() => {
          enabled.value = false;
          statusRequest = null; // let a later screen try again
        });
    }
    return statusRequest;
  }

  /** Load the saved conversation (once per signed-in member, unless forced). */
  async function loadHistory(force = false) {
    const key = userKey();
    if (!key || (!force && loadedFor === key)) return;
    if (loadedFor !== key) messages.value = [];
    loadedFor = key;
    loadingHistory.value = true;
    try {
      const res = await api.get(`/api/coach/messages?thread=coach&limit=${PAGE}`);
      messages.value = (res.data?.messages || []).map(fromServer);
      hasMore.value = !!res.data?.has_more;
    } catch {
      loadedFor = ''; // try again next time
    } finally {
      loadingHistory.value = false;
    }
  }

  async function loadOlder() {
    const oldest = messages.value.find((m) => m.id);
    if (!oldest || !hasMore.value || loadingHistory.value) return;
    loadingHistory.value = true;
    try {
      const res = await api.get(`/api/coach/messages?thread=coach&limit=${PAGE}&before_id=${oldest.id}`);
      messages.value = [...(res.data?.messages || []).map(fromServer), ...messages.value];
      hasMore.value = !!res.data?.has_more;
    } finally {
      loadingHistory.value = false;
    }
  }

  async function send(text: string) {
    const t = text.trim();
    if (!t || sending.value) return;
    const localId = Date.now();
    messages.value.push({ role: 'user', text: t, pending: true, localId });
    sending.value = true;
    try {
      const res = await api.post('/api/coach/message', { text: t }, { timeout: 60000 });
      const saved = [res.data.user_message, res.data.message].filter(Boolean).map(fromServer);
      messages.value = [...messages.value.filter((m) => m.localId !== localId), ...saved];
      // Coach may have updated what it knows (the "What Coach knows" panel listens)
      window.dispatchEvent(new CustomEvent('rep:coach-replied'));
    } catch (e: any) {
      // Nothing was saved: keep the member's words on screen with the reason
      const idx = messages.value.findIndex((m) => m.localId === localId);
      if (idx !== -1) messages.value[idx] = { ...messages.value[idx], pending: false };
      const status = e?.response?.status;
      let msg = 'Rep Coach is having trouble right now. Try again in a minute.';
      if (status === 429) msg = "You've reached the Rep Coach limit for now. Try again later.";
      else if (status === 503) msg = 'Rep Coach is turned off right now.';
      else if (status === 400 && e?.response?.data?.error) msg = e.response.data.error;
      messages.value.push({ role: 'assistant', text: msg, error: true });
    } finally {
      sending.value = false;
    }
  }

  /** Permanently delete one saved message (local notices are just dismissed). */
  async function deleteMessage(m: CoachMessage) {
    if (m.id) await api.delete(`/api/coach/messages/${m.id}`);
    messages.value = messages.value.filter((x) => x !== m && (!m.id || x.id !== m.id));
  }

  /** Permanently delete all Coach and profile-setup messages; optionally forget what Coach knows. */
  async function deleteAll(clearMemory = false) {
    await api.delete(`/api/coach/messages?thread=all${clearMemory ? '&clear_memory=true' : ''}`);
    messages.value = [];
    hasMore.value = false;
    resetOnboardingLocal();
  }

  const preview = computed(() => {
    const last = [...messages.value].reverse().find((m) => m.role === 'assistant' && !m.error);
    return last ? stripCardMarkers(last.text) : 'Find Purposes, people and Goal Teams for what you care about';
  });

  return {
    enabled,
    messages,
    sending,
    hasMore,
    loadingHistory,
    preview,
    checkStatus,
    loadHistory,
    loadOlder,
    send,
    deleteMessage,
    deleteAll,
  };
}
