// src/pages/utils/useRepOnboarding.ts
// Rep Onboarding: the guided interview that helps a member write their profile's
// Write section. Shared state (module-level) for the Coach chat, the Coach row and the
// desktop dashboard. The conversation is saved on the server (thread "onboarding").
//
// The member saves the drafted Write section themselves: saveDraft() posts each entry
// through the regular Write endpoint, then tells the server the draft was saved.

import { ref, computed } from 'vue';
import api from '@/pages/utils/api';
import type { CoachMessage } from '@/pages/utils/useRepCoach';

export type OnboardingStatus = 'not_started' | 'in_progress' | 'review' | 'complete';

export interface OnboardingState {
  status: OnboardingStatus;
  step: number;
  steps: string[];
  answers: Record<string, any>;
  completed_at?: string | null;
}

export interface DraftEntry {
  pillar: 'accomplish' | 'looking_for' | 'holding_back';
  title: string;
  content: string;
}

export const STEP_LABELS = ['Accomplish', 'Looking for', 'Holding back', 'Quick details', 'Review'];

const emptyState = (): OnboardingState => ({
  status: 'not_started',
  step: 0,
  steps: ['accomplish', 'looking_for', 'holding_back', 'details', 'review'],
  answers: {},
});

// Shared with useRepCoach (status comes back from /api/coach/status too)
export const onboardingStatus = ref<OnboardingStatus>('not_started');

const state = ref<OnboardingState>(emptyState());
const messages = ref<CoachMessage[]>([]);
const sending = ref(false);
const loading = ref(false);
// Which thread the Coach chat shows: null = automatic (onboarding until it's complete)
const requestedView = ref<'onboarding' | 'coach' | null>(readView());
let loadedFor = '';

function readView(): 'onboarding' | 'coach' | null {
  try {
    const v = sessionStorage.getItem('repCoachView');
    return v === 'onboarding' || v === 'coach' ? v : null;
  } catch {
    return null;
  }
}

function saveView(v: 'onboarding' | 'coach' | null) {
  try {
    if (v) sessionStorage.setItem('repCoachView', v);
    else sessionStorage.removeItem('repCoachView');
  } catch {
    // Storage can be blocked; the choice just won't survive a refresh.
  }
}

function applyState(next?: Partial<OnboardingState>) {
  if (!next) return;
  state.value = { ...state.value, ...next } as OnboardingState;
  onboardingStatus.value = state.value.status;
}

export function fromServer(m: any): CoachMessage {
  return {
    id: m.id,
    role: m.role,
    kind: m.kind || 'text',
    text: m.text,
    payload: m.payload || null,
    created_at: m.created_at,
    cards: m.payload?.cards || {},
  };
}

/** Forget the local copy (after "delete all", or a different member signs in). */
export function resetOnboardingLocal() {
  messages.value = [];
  loadedFor = '';
}

export function useRepOnboarding() {
  const userKey = () => localStorage.getItem('userId') || '';

  async function load(force = false) {
    const key = userKey();
    if (!key || (!force && loadedFor === key)) return;
    loadedFor = key;
    loading.value = true;
    try {
      const res = await api.get('/api/coach/onboarding');
      applyState(res.data);
      if (res.data?.status && res.data.status !== 'not_started') {
        const hist = await api.get('/api/coach/messages?thread=onboarding&limit=100');
        messages.value = (hist.data?.messages || []).map(fromServer);
      } else {
        messages.value = [];
      }
    } catch {
      loadedFor = ''; // try again next time
    } finally {
      loading.value = false;
    }
  }

  /** Open the interview with its first question (no-op if it's already open). */
  async function start() {
    if (sending.value) return;
    sending.value = true;
    try {
      const res = await api.post('/api/coach/onboarding/start');
      messages.value = (res.data?.messages || []).map(fromServer);
      applyState(res.data?.onboarding);
    } catch {
      messages.value.push({ role: 'assistant', text: 'Profile setup is having trouble right now. Try again in a minute.', error: true });
    } finally {
      sending.value = false;
    }
  }

  async function send(text: string) {
    const t = text.trim();
    if (!t || sending.value) return;
    const localId = Date.now();
    messages.value.push({ role: 'user', text: t, pending: true, localId });
    sending.value = true;
    try {
      const res = await api.post('/api/coach/onboarding/message', { text: t }, { timeout: 90000 });
      const fresh = (res.data?.messages || []).map(fromServer);
      messages.value = [...messages.value.filter((m) => m.localId !== localId), ...fresh];
      applyState(res.data?.onboarding);
    } catch (e: any) {
      const status = e?.response?.status;
      // The server saved nothing: keep the member's words on screen (unsaved) with the error
      const idx = messages.value.findIndex((m) => m.localId === localId);
      if (idx !== -1) messages.value[idx] = { ...messages.value[idx], pending: false };
      if (status === 409) {
        applyState(e.response.data?.onboarding);
        messages.value.push({ role: 'assistant', text: 'Your profile is already set up. Switch to Rep Coach to keep going.', error: true });
      } else {
        let msg = 'Profile setup is having trouble right now. Try again in a minute.';
        if (status === 429) msg = "You've reached today's limit for profile setup. Try again tomorrow.";
        else if (status === 503) msg = 'Rep Coach is turned off right now.';
        else if (status === 400 && e?.response?.data?.error) msg = e.response.data.error;
        messages.value.push({ role: 'assistant', text: msg, error: true });
      }
    } finally {
      sending.value = false;
    }
  }

  /**
   * Save the (possibly edited) draft to the member's profile. Each entry is posted through
   * the regular Write endpoint at the top of the Write section; existing entries stay.
   */
  async function saveDraft(message: CoachMessage, entries: DraftEntry[]) {
    for (const [i, entry] of entries.entries()) {
      await api.post('/api/user/write', {
        title: entry.title,
        content: entry.content.trim(),
        content_format: 'plain',
        order: i - entries.length, // -3, -2, -1: ahead of existing entries, in pillar order
        status: 'published',
      });
    }
    const res = await api.post(`/api/coach/onboarding/write-draft/${message.id}`, {
      status: 'saved',
      entries: Object.fromEntries(entries.map((e) => [e.pillar, e.content.trim()])),
    });
    replaceMessage(fromServer(res.data.message));
    // Stay on the setup thread so the member sees "Saved ✓" (the switch to Coach is theirs)
    if (!requestedView.value) requestedView.value = 'onboarding';
    applyState(res.data?.onboarding);
    window.dispatchEvent(new CustomEvent('rep:write-updated'));
  }

  async function discardDraft(message: CoachMessage) {
    const res = await api.post(`/api/coach/onboarding/write-draft/${message.id}`, { status: 'discarded' });
    replaceMessage(fromServer(res.data.message));
    applyState(res.data?.onboarding);
  }

  function replaceMessage(updated: CoachMessage) {
    const idx = messages.value.findIndex((m) => m.id === updated.id);
    if (idx !== -1) messages.value[idx] = updated;
  }

  /** Start the interview over (keeps what Coach knows and anything already saved). */
  async function restart() {
    const res = await api.post('/api/coach/onboarding/restart');
    applyState(res.data?.onboarding);
    messages.value = [];
    await start();
  }

  async function deleteMessage(id: number) {
    await api.delete(`/api/coach/messages/${id}`);
    messages.value = messages.value.filter((m) => m.id !== id);
  }

  function setView(v: 'onboarding' | 'coach' | null) {
    requestedView.value = v;
    saveView(v);
  }

  // The Coach chat shows the interview until the member's profile is set up, unless they
  // chose to chat with Coach instead ("Skip for now", remembered for the session).
  const view = computed<'onboarding' | 'coach'>(() => {
    if (requestedView.value) return requestedView.value;
    return onboardingStatus.value === 'complete' ? 'coach' : 'onboarding';
  });

  return {
    state,
    status: onboardingStatus,
    messages,
    sending,
    loading,
    view,
    // true once the member chose "Skip for now" this session
    skipped: computed(() => requestedView.value === 'coach'),
    load,
    start,
    send,
    saveDraft,
    discardDraft,
    restart,
    deleteMessage,
    setView,
  };
}
