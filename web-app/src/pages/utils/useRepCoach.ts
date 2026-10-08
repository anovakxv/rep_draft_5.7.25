// src/pages/utils/useRepCoach.ts
// Rep Coach state shared by the pinned chat row and the chat panel.
// The conversation is kept in sessionStorage for this tab only (no database yet),
// so it survives a page refresh but starts fresh in a new visit.

import { ref, computed } from 'vue';
import api from '@/pages/utils/api';

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
  role: 'user' | 'assistant';
  text: string;
  cards?: Record<string, CoachCard>;
  error?: boolean;
}

const HISTORY_SENT = 12; // recent turns sent with each message; the server caps it too

const enabled = ref<boolean | null>(null);
const sending = ref(false);
const messages = ref<CoachMessage[]>([]);
let loadedFor = '';
let statusRequest: Promise<void> | null = null;

function storageKey(): string {
  return `repCoachConversation:${localStorage.getItem('userId') || ''}`;
}

function loadConversation() {
  const key = storageKey();
  if (key === loadedFor) return;
  loadedFor = key;
  try {
    const raw = sessionStorage.getItem(key);
    messages.value = raw ? JSON.parse(raw) : [];
  } catch {
    messages.value = [];
  }
}

function saveConversation() {
  try {
    sessionStorage.setItem(storageKey(), JSON.stringify(messages.value.slice(-30)));
  } catch {
    // Storage can be blocked (private mode); the chat still works for this page view.
  }
}

export function stripCardMarkers(text: string): string {
  return text.replace(/\[\[\s*(purpose|person|goal)\s*:\s*\d+\s*\]\]/gi, '').replace(/\*\*/g, '').replace(/\s+/g, ' ').trim();
}

export function useRepCoach() {
  loadConversation();

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
        })
        .catch(() => {
          enabled.value = false;
          statusRequest = null; // let a later screen try again
        });
    }
    return statusRequest;
  }

  async function send(text: string) {
    const t = text.trim();
    if (!t || sending.value) return;
    messages.value.push({ role: 'user', text: t });
    saveConversation();
    sending.value = true;
    try {
      const history = messages.value
        .filter((m) => !m.error)
        .slice(-HISTORY_SENT)
        .map((m) => ({ role: m.role, text: m.text }));
      const res = await api.post('/api/coach/message', { messages: history }, { timeout: 60000 });
      messages.value.push({ role: 'assistant', text: res.data.reply, cards: res.data.cards || {} });
    } catch (e: any) {
      const status = e?.response?.status;
      let msg = 'Rep Coach is having trouble right now. Try again in a minute.';
      if (status === 429) msg = "You've reached the Rep Coach limit for now. Try again later.";
      else if (status === 503) msg = 'Rep Coach is turned off right now.';
      else if (status === 400 && e?.response?.data?.error) msg = e.response.data.error;
      messages.value.push({ role: 'assistant', text: msg, error: true });
    } finally {
      sending.value = false;
      saveConversation();
    }
  }

  function startOver() {
    messages.value = [];
    saveConversation();
  }

  const preview = computed(() => {
    const last = [...messages.value].reverse().find((m) => m.role === 'assistant' && !m.error);
    return last ? stripCardMarkers(last.text) : 'Find Purposes, people and Goal Teams for what you care about';
  });

  return { enabled, messages, sending, checkStatus, send, startOver, preview };
}
