// src/pages/utils/desktopShell.ts
// Desktop "Rolodex Shell" helpers (DesktopDashboard, lg+ only):
// - which conversation is open, carried in the URL as /main?c=dm-12 | group-7 | coach
// - the last conversation a member viewed (restored on their next visit)
// - unsent drafts per conversation
// - sending desktop chat links (/chat/dm/:id, /chat/group/:id, /coach) into the shell
// Phones keep their own full-page chat routes; nothing here runs below lg.

import { BREAKPOINTS } from '@/constants/breakpoints';

export type ConversationKey =
  | { kind: 'coach' }
  | { kind: 'direct'; id: number }
  | { kind: 'group'; id: number };

export interface GroupMember {
  id: number;
  name?: string;
  full_name?: string;
  profile_picture_url?: string;
}

// What the open group chat's first load reports up to the shell (for the context pane).
export interface GroupLoaded {
  name: string;
  members: GroupMember[];
  creatorId: number | null;
}

export function parseConversationKey(raw: unknown): ConversationKey | null {
  if (typeof raw !== 'string') return null;
  if (raw === 'coach') return { kind: 'coach' };
  const m = /^(dm|group)-(\d+)$/.exec(raw);
  if (!m) return null;
  const id = Number(m[2]);
  if (!id) return null;
  return m[1] === 'dm' ? { kind: 'direct', id } : { kind: 'group', id };
}

export function formatConversationKey(key: ConversationKey): string {
  if (key.kind === 'coach') return 'coach';
  return `${key.kind === 'direct' ? 'dm' : 'group'}-${key.id}`;
}

export function sameConversation(a: ConversationKey | null, b: ConversationKey | null): boolean {
  if (!a || !b) return a === b;
  return formatConversationKey(a) === formatConversationKey(b);
}

export function isDesktopViewport(): boolean {
  return typeof window !== 'undefined' && window.innerWidth >= BREAKPOINTS.DESKTOP;
}

// The context pane sits inline from this width; below it, it opens as a drawer.
export const WIDE_DESKTOP = 1280;

// --- Last conversation (localStorage: no message content, just the key) ---

const lastKey = (userId: number) => `repLastConversation:${userId}`;

export function readLastConversation(userId: number): ConversationKey | null {
  try {
    return parseConversationKey(localStorage.getItem(lastKey(userId)));
  } catch {
    return null;
  }
}

export function saveLastConversation(userId: number, key: ConversationKey | null) {
  try {
    if (key) localStorage.setItem(lastKey(userId), formatConversationKey(key));
    else localStorage.removeItem(lastKey(userId));
  } catch {
    // Storage can be blocked (private mode); restoring is a convenience only.
  }
}

// --- Drafts (sessionStorage: survives a refresh, cleared when the tab closes) ---

const draftKey = (userId: number, key: ConversationKey) => `repDraft:${userId}:${formatConversationKey(key)}`;

export function readDraft(userId: number, key: ConversationKey): string {
  try {
    return sessionStorage.getItem(draftKey(userId, key)) || '';
  } catch {
    return '';
  }
}

export function saveDraft(userId: number, key: ConversationKey, text: string) {
  try {
    if (text.trim()) sessionStorage.setItem(draftKey(userId, key), text);
    else sessionStorage.removeItem(draftKey(userId, key));
  } catch {
    // Same as above: drafts are best-effort.
  }
}

// --- Pane preferences (per browser) ---

export function readPref(name: string, fallback: string): string {
  try {
    return localStorage.getItem(`repDesktop:${name}`) ?? fallback;
  } catch {
    return fallback;
  }
}

export function savePref(name: string, value: string) {
  try {
    localStorage.setItem(`repDesktop:${name}`, value);
  } catch {
    // Preferences are a convenience only.
  }
}

// --- Routing: desktop chat links open inside the shell ---

// Returns the shell key for a full-page chat path on desktop, or null to leave the route alone.
export function shellKeyForPath(path: string): string | null {
  if (!isDesktopViewport()) return null;
  if (path === '/coach') return 'coach';
  const dm = /^\/chat\/dm\/(\d+)\/?$/.exec(path);
  if (dm) return `dm-${dm[1]}`;
  const group = /^\/chat\/group\/(\d+)\/?$/.exec(path); // "/chat/group/new" stays a page
  if (group) return `group-${group[1]}`;
  return null;
}

// --- Display helpers shared by the shell's panes ---

export function getInitials(name: string): string {
  const parts = (name || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  return (parts[0] || '?').substring(0, 2).toUpperCase();
}

export function timeAgo(dateString?: string): string {
  if (!dateString) return '';
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return '';
  const diffMin = Math.floor((Date.now() - date.getTime()) / 60000);
  if (diffMin < 1) return 'now';
  if (diffMin < 60) return `${diffMin}m`;
  const diffHour = Math.floor(diffMin / 60);
  if (diffHour < 24) return `${diffHour}h`;
  const diffDay = Math.floor(diffHour / 24);
  if (diffDay < 7) return `${diffDay}d`;
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

// Group member photos are sometimes stored as bare S3 keys.
export function photoUrl(url?: string | null): string | undefined {
  if (!url || !url.trim()) return undefined;
  if (url.startsWith('http')) return url;
  return `https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/${url}`;
}
