<!--
  ConversationView.vue
  Desktop conversation for DMs and group chats, shown in the center pane of the
  desktop Rolodex Shell (DesktopDashboard). One implementation for both kinds,
  built on MessageBubble so reactions, edits and deletes match the full-page chats.
  Phones keep using Chat_Individual / Chat_Group.
-->

<template>
  <div class="flex flex-col h-full min-h-0 bg-white">
    <!-- Header -->
    <header class="shrink-0 flex items-center gap-3 h-14 px-4 border-b border-gray-200 bg-white">
      <button
        type="button"
        class="shrink-0 rounded-full focus:outline-none focus-visible:ring-2 focus-visible:ring-[#8cc65d]"
        :class="kind === 'direct' ? 'cursor-pointer hover:opacity-80' : 'cursor-default'"
        :aria-label="kind === 'direct' ? `View ${displayName}'s profile` : undefined"
        :tabindex="kind === 'direct' ? 0 : -1"
        @click="openProfile"
      >
        <img v-if="displayAvatar" :src="displayAvatar" alt="" class="w-9 h-9 rounded-full object-cover" />
        <span
          v-else
          class="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-semibold"
          :class="kind === 'group' ? '' : 'bg-gray-300'"
          :style="kind === 'group' ? 'background-color: #113213' : ''"
        >{{ getInitials(displayName) }}</span>
      </button>
      <div class="min-w-0 flex-1">
        <p class="font-semibold text-[15px] text-gray-900 truncate leading-tight">{{ displayName }}</p>
        <p class="text-xs text-gray-500 truncate leading-tight mt-0.5">
          <template v-if="kind === 'group'">{{ members.length }} member{{ members.length === 1 ? '' : 's' }}</template>
          <button v-else type="button" class="hover:underline" @click="openProfile">View profile</button>
        </p>
      </div>

      <slot name="actions" />

      <!-- Group menu: leave / delete -->
      <div v-if="kind === 'group'" class="relative">
        <button
          type="button"
          class="w-9 h-9 rounded-lg flex items-center justify-center text-gray-500 hover:bg-gray-100 hover:text-gray-800"
          aria-label="Group options"
          :aria-expanded="showGroupMenu"
          @click="showGroupMenu = !showGroupMenu"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
          </svg>
        </button>
        <div v-if="showGroupMenu" class="fixed inset-0 z-30" @click="showGroupMenu = false"></div>
        <div v-if="showGroupMenu" role="menu" class="absolute right-0 top-full mt-1 z-40 w-48 bg-white rounded-xl shadow-xl border border-gray-100 py-1">
          <button
            v-if="currentUserId === creatorId"
            role="menuitem"
            class="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50"
            @click="confirmGroupAction('delete')"
          >Delete group chat</button>
          <button
            v-else
            role="menuitem"
            class="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50"
            @click="confirmGroupAction('leave')"
          >Leave group</button>
        </div>
      </div>
    </header>

    <!-- Messages -->
    <div class="relative flex-1 min-h-0">
      <div
        ref="scrollRef"
        class="h-full overflow-y-auto"
        style="overscroll-behavior-y: contain"
        aria-live="polite"
        @scroll.passive="onScroll"
        @click="replyMenuId = null"
      >
        <div class="mx-auto w-full max-w-[860px] px-6 pt-4 pb-6">
          <!-- Older messages -->
          <div v-if="loadingOlder" class="flex justify-center py-3">
            <span class="animate-spin h-5 w-5 border-2 border-gray-300 border-t-transparent rounded-full"></span>
          </div>
          <p v-else-if="!hasMore && messages.length && !loading" class="text-center text-xs text-gray-400 py-3">
            Beginning of your conversation{{ kind === 'direct' ? ` with ${firstName(displayName)}` : '' }}
          </p>

          <!-- Initial load -->
          <div v-if="loading" class="space-y-4 py-6 animate-pulse" aria-hidden="true">
            <div v-for="i in 5" :key="i" class="flex" :class="i % 2 ? 'justify-start' : 'justify-end'">
              <div class="h-10 rounded-2xl bg-gray-100" :style="`width:${[38, 52, 30, 46, 34][i - 1]}%`"></div>
            </div>
          </div>

          <div v-else-if="loadError" class="py-16 text-center">
            <p class="text-sm text-gray-500">Couldn't load this conversation.</p>
            <button type="button" class="mt-3 text-sm font-semibold hover:underline" style="color: #8cc65d" @click="loadInitial">Try again</button>
          </div>

          <div v-else-if="!messages.length" class="py-16 flex flex-col items-center text-center">
            <img v-if="displayAvatar" :src="displayAvatar" alt="" class="w-16 h-16 rounded-full object-cover mb-3" />
            <p class="font-semibold text-gray-900">{{ kind === 'direct' ? `Start a conversation with ${firstName(displayName)}` : 'No messages yet' }}</p>
            <p class="text-sm text-gray-500 mt-1">Say hello. Messages you send appear here.</p>
          </div>

          <template v-else>
            <template v-for="row in rows" :key="row.key">
              <!-- Date separator -->
              <div v-if="row.type === 'date'" class="flex items-center gap-3 my-5" role="separator">
                <div class="flex-1 h-px bg-gray-100"></div>
                <span class="text-[11px] font-semibold uppercase tracking-wide text-gray-400">{{ row.label }}</span>
                <div class="flex-1 h-px bg-gray-100"></div>
              </div>

              <!-- Message -->
              <div v-else :class="row.first ? 'mt-4' : 'mt-1'">
                <p
                  v-if="row.first && kind === 'group' && !isMine(row.msg)"
                  class="text-xs font-semibold text-gray-500 mb-1"
                  :class="senderPhoto(row.msg) ? 'pl-12' : ''"
                >{{ row.msg.sender_name || 'Member' }}</p>
                <div :class="!row.first && !isMine(row.msg) && senderPhoto(row.msg) ? 'pl-12' : ''">
                  <MessageBubble
                    :message="row.msg"
                    :isCurrentUser="isMine(row.msg)"
                    :profilePicURL="row.first && !isMine(row.msg) ? senderPhoto(row.msg) : undefined"
                    :editMode="editingId === row.msg.id"
                    :currentUserId="currentUserId"
                    :replyPrivatelyTo="kind === 'group' && !isMine(row.msg) && row.msg.id > 0 ? firstName(row.msg.sender_name || 'them') : undefined"
                    :showReplyPrivately="replyMenuId === row.msg.id"
                    @toggleReplyPrivately="toggleReplyMenu"
                    @replyPrivately="replyPrivately"
                    @toggleReaction="toggleReaction"
                    @showEmojiPicker="openEmojiPicker"
                    @startEdit="startEdit"
                    @saveEdit="saveEdit"
                    @cancelEdit="editingId = null"
                    @delete="askDelete"
                    @restore="restoreMessage"
                    @showEditHistory="showHistory"
                  />
                </div>
                <!-- Delivery state for messages you just sent -->
                <div v-if="row.msg._status === 'sending'" class="text-right text-[11px] text-gray-400 mt-0.5 pr-1">Sending…</div>
                <div v-else-if="row.msg._status === 'failed'" class="flex justify-end items-center gap-2 text-[12px] mt-1 pr-1">
                  <span class="text-red-600 font-medium">{{ row.msg._error || 'Not sent' }}</span>
                  <button type="button" class="font-semibold hover:underline" style="color: #8cc65d" @click="retry(row.msg)">Retry</button>
                  <button type="button" class="text-gray-500 hover:underline" @click="discard(row.msg)">Discard</button>
                </div>
              </div>
            </template>
          </template>
        </div>
      </div>

      <!-- Jump to latest -->
      <Transition name="cv-pop">
        <button
          v-if="!atBottom && messages.length"
          type="button"
          class="absolute bottom-4 left-1/2 -translate-x-1/2 flex items-center gap-1.5 pl-3 pr-4 h-9 rounded-full bg-white border border-gray-200 shadow-lg text-sm font-medium text-gray-800 hover:bg-gray-50"
          @click="scrollToBottom(true)"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" style="color: #8cc65d" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
          </svg>
          {{ newCount ? `${newCount} new message${newCount === 1 ? '' : 's'}` : 'Jump to latest' }}
        </button>
      </Transition>
    </div>

    <!-- Composer -->
    <div class="shrink-0 border-t border-gray-200 bg-white">
      <div class="mx-auto w-full max-w-[860px] px-6 pt-3 pb-3">
        <!-- Private reply: the group message being answered -->
        <div v-if="privateReply" class="flex items-start gap-2 mb-2 rounded-xl border border-gray-200 bg-gray-50 px-3 py-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mt-0.5 shrink-0" style="color: #8cc65d" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
          </svg>
          <div class="flex-1 min-w-0">
            <p class="text-xs font-semibold text-gray-500 truncate">Replying privately to {{ privateReply.recipientName }} · {{ privateReply.groupName }}</p>
            <p class="text-sm text-gray-700 line-clamp-2 break-words">{{ quoteSnippet(privateReply.text) }}</p>
          </div>
          <button type="button" class="p-1 text-gray-400 hover:text-gray-600 shrink-0" aria-label="Cancel private reply" @click="privateReply = null">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form
          class="flex items-end gap-2 rounded-2xl border border-gray-300 bg-gray-50 pl-4 pr-1.5 py-1.5 focus-within:border-[#8cc65d] focus-within:bg-white transition-colors"
          @submit.prevent="send"
        >
          <label :for="inputId" class="sr-only">Message {{ displayName }}</label>
          <textarea
            :id="inputId"
            ref="inputRef"
            v-model="draft"
            rows="1"
            maxlength="5000"
            :placeholder="`Message ${kind === 'direct' ? firstName(displayName) : displayName}`"
            class="flex-1 resize-none bg-transparent py-2 text-[15px] leading-snug text-gray-900 placeholder-gray-400 focus:outline-none"
            style="max-height: 200px; overflow-y: hidden"
            @input="onDraftInput"
            @keydown.enter.exact.prevent="send"
            @keydown.esc="privateReply = null"
          ></textarea>
          <button
            type="submit"
            aria-label="Send"
            class="h-9 w-9 mb-0.5 rounded-full flex items-center justify-center text-white shrink-0 transition-colors"
            :class="canSend ? 'hover:opacity-90' : 'bg-gray-300'"
            :style="canSend ? 'background-color: #8cc65d' : ''"
            :disabled="!canSend"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 rotate-90" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
            </svg>
          </button>
        </form>
        <p class="mt-1.5 text-[11px] text-gray-400">
          <span class="font-medium text-gray-500">Enter</span> to send · <span class="font-medium text-gray-500">Shift + Enter</span> for a new line
        </p>
      </div>
    </div>

    <EmojiPicker :show="showEmoji" :messageId="emojiMessageId" @close="showEmoji = false" @selectEmoji="onEmojiSelected" />
    <DeleteConfirmDialog :show="showDeleteConfirm" @close="showDeleteConfirm = false" @confirm="confirmDelete" />
    <EditHistoryModal
      :show="historyOpen"
      :history="history"
      :loading="historyLoading"
      :error="historyError"
      @close="historyOpen = false"
      @retry="historyError = false"
    />

    <!-- Leave / delete group confirmation -->
    <Transition name="fade">
      <div v-if="groupAction" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/40" @click="groupAction = null"></div>
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6" role="dialog" aria-modal="true">
          <h3 class="font-bold text-lg">{{ groupAction === 'delete' ? 'Delete group chat?' : 'Leave group?' }}</h3>
          <p class="mt-2 text-sm text-gray-600">
            {{ groupAction === 'delete'
              ? 'This permanently deletes the group chat for all members. This can’t be undone.'
              : 'You’ll stop receiving messages from this group chat.' }}
          </p>
          <p v-if="groupActionError" class="mt-3 text-sm text-red-600">{{ groupActionError }}</p>
          <div class="mt-6 flex justify-end gap-3">
            <button type="button" class="px-4 py-2 rounded-lg border border-gray-300 text-sm" @click="groupAction = null">Cancel</button>
            <button type="button" class="px-4 py-2 rounded-lg bg-red-600 text-white text-sm font-semibold hover:bg-red-700" @click="runGroupAction">
              {{ groupAction === 'delete' ? 'Delete' : 'Leave' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import api from '@/pages/utils/api';
import MessageBubble from '@/components/MessageBubble.vue';
import EmojiPicker from '@/components/EmojiPicker.vue';
import DeleteConfirmDialog from '@/components/DeleteConfirmDialog.vue';
import EditHistoryModal from '@/components/EditHistoryModal.vue';
import { useSocketManager } from '@/pages/utils/useSocketManager';
import {
  takePrivateReply,
  startPrivateReply,
  buildPrivateReplyText,
  quoteSnippet,
  type PrivateReplyDraft,
} from '@/pages/utils/privateReply';
import {
  readDraft,
  saveDraft,
  getInitials,
  photoUrl,
  type ConversationKey,
  type GroupMember,
  type GroupLoaded,
} from '@/pages/utils/desktopShell';

interface ChatMessage {
  id: number;
  sender_id: number;
  sender_name: string;
  sender_photo_url?: string;
  text: string;
  timestamp: string;
  read?: string;
  attachments?: Array<{ url: string; type: 'image' | 'file'; filename?: string }>;
  reactions?: Array<{ emoji: string; count: number; userReacted: boolean }>;
  is_edited?: boolean;
  is_deleted?: boolean;
  edited_at?: string;
  // Local delivery state for messages sent from this screen
  _status?: 'sending' | 'failed';
  _error?: string;
}

const props = defineProps<{
  kind: 'direct' | 'group';
  id: number;
  currentUserId: number;
  title?: string;
  avatar?: string | null;
}>();

const emit = defineEmits<{
  (e: 'refresh-chats'): void;
  (e: 'group-loaded', info: GroupLoaded): void;
  (e: 'left'): void;
}>();

const router = useRouter();
const route = useRoute();
const { onDirectMessageNotification, onGroupMessage, onGroupMessageNotification, joinChat, leaveChat } = useSocketManager();

const PAGE = 50;
const GROUP_WINDOW_MS = 5 * 60 * 1000; // consecutive messages within 5 min read as one block

// --- State ---
const messages = ref<ChatMessage[]>([]);
const loading = ref(false);
const loadError = ref(false);
const loadingOlder = ref(false);
const hasMore = ref(true);
const scrollRef = ref<HTMLElement | null>(null);
const inputRef = ref<HTMLTextAreaElement | null>(null);
const atBottom = ref(true);
const newCount = ref(0);
const draft = ref('');
const privateReply = ref<PrivateReplyDraft | null>(null);

const members = ref<GroupMember[]>([]);
const groupName = ref('');
const creatorId = ref<number | null>(null);
const dmProfile = ref<{ full_name?: string; profile_picture_url?: string } | null>(null);

const editingId = ref<number | null>(null);
const replyMenuId = ref<number | null>(null);
const showEmoji = ref(false);
const emojiMessageId = ref<number | null>(null);
const showDeleteConfirm = ref(false);
const deleteId = ref<number | null>(null);
const historyOpen = ref(false);
const history = ref<any[] | null>(null);
const historyLoading = ref(false);
const historyError = ref(false);
const showGroupMenu = ref(false);
const groupAction = ref<'leave' | 'delete' | null>(null);
const groupActionError = ref('');

let loadSeq = 0; // ignore responses for a conversation we've already left
let tempSeq = 0;
let pendingSync = false;
let syncTimer: ReturnType<typeof setTimeout> | null = null;

const inputId = computed(() => `cv-input-${props.kind}-${props.id}`);
const convKey = computed<ConversationKey>(() => ({ kind: props.kind, id: props.id }));

const displayName = computed(() => {
  if (props.kind === 'group') return groupName.value || props.title || 'Group chat';
  return props.title || dmProfile.value?.full_name || 'Member';
});
const displayAvatar = computed(() =>
  props.kind === 'direct' ? props.avatar || dmProfile.value?.profile_picture_url || null : null
);

const canSend = computed(() => draft.value.trim().length > 0);

// --- Helpers ---
function firstName(name: string): string {
  return (name || '').trim().split(/\s+/)[0] || name;
}

function isMine(msg: ChatMessage): boolean {
  return msg.sender_id === props.currentUserId;
}

function senderPhoto(msg: ChatMessage): string | undefined {
  if (isMine(msg)) return undefined;
  if (props.kind === 'direct') return displayAvatar.value || undefined;
  const member = members.value.find((m) => m.id === msg.sender_id);
  return photoUrl(member?.profile_picture_url || msg.sender_photo_url);
}

function normalize(raw: any): ChatMessage {
  return {
    ...raw,
    sender_id: Number(raw.sender_id ?? raw.senderId),
    sender_name: raw.sender_name ?? raw.senderName ?? '',
    timestamp: raw.timestamp || raw.created_at || new Date().toISOString(),
  };
}

function msgTime(m: ChatMessage): number {
  const t = new Date(m.timestamp).getTime();
  return Number.isNaN(t) ? 0 : t;
}

function dayKey(t: number): string {
  const d = new Date(t);
  return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}

function dayLabel(t: number): string {
  const d = new Date(t);
  const today = new Date();
  const startOf = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const diffDays = Math.round((startOf(today) - startOf(d)) / 86400000);
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays > 1 && diffDays < 7) return d.toLocaleDateString(undefined, { weekday: 'long' });
  return d.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    ...(d.getFullYear() !== today.getFullYear() ? { year: 'numeric' } : {}),
  });
}

type Row =
  | { type: 'date'; key: string; label: string }
  | { type: 'msg'; key: string; msg: ChatMessage; first: boolean };

const rows = computed<Row[]>(() => {
  const out: Row[] = [];
  let prev: ChatMessage | null = null;
  let prevDay = '';
  for (const m of messages.value) {
    const t = msgTime(m);
    const day = dayKey(t);
    if (day !== prevDay) {
      out.push({ type: 'date', key: `d-${day}`, label: dayLabel(t) });
      prevDay = day;
      prev = null;
    }
    const first = !prev || prev.sender_id !== m.sender_id || t - msgTime(prev) > GROUP_WINDOW_MS || !!prev.is_deleted;
    out.push({ type: 'msg', key: `m-${m.id}`, msg: m, first });
    prev = m;
  }
  return out;
});

function realIds(): Set<number> {
  return new Set(messages.value.filter((m) => m.id > 0).map((m) => m.id));
}

function sortMessages() {
  messages.value.sort((a, b) => msgTime(a) - msgTime(b) || a.id - b.id);
}

// Adds new messages and refreshes ones we already have (edits, reactions, deletes).
function mergeMessages(incoming: any[]): number {
  let added = 0;
  for (const raw of incoming) {
    const m = normalize(raw);
    const idx = messages.value.findIndex((x) => x.id === m.id);
    if (idx === -1) {
      messages.value.push(m);
      added++;
    } else {
      messages.value[idx] = { ...messages.value[idx], ...m };
    }
  }
  if (added) sortMessages();
  return added;
}

// --- Scrolling ---
function distanceFromBottom(): number {
  const el = scrollRef.value;
  return el ? el.scrollHeight - el.scrollTop - el.clientHeight : 0;
}

function scrollToBottom(smooth = false) {
  nextTick(() => {
    const el = scrollRef.value;
    if (!el) return;
    el.scrollTo({ top: el.scrollHeight, behavior: smooth ? 'smooth' : 'auto' });
    atBottom.value = true;
    newCount.value = 0;
  });
}

function onScroll() {
  atBottom.value = distanceFromBottom() < 80;
  if (atBottom.value) newCount.value = 0;
  const el = scrollRef.value;
  if (el && el.scrollTop < 120) loadOlder();
}

// --- Loading ---
async function loadInitial() {
  const seq = ++loadSeq;
  loading.value = true;
  loadError.value = false;
  messages.value = [];
  hasMore.value = true;
  newCount.value = 0;
  atBottom.value = true;
  try {
    if (props.kind === 'direct') {
      const [res] = await Promise.all([
        api.get(`/api/message/get_messages?users_id=${props.id}&order=ASC&limit=${PAGE}&mark_as_read=1`),
        !props.title ? loadDmProfile() : Promise.resolve(),
      ]);
      if (seq !== loadSeq) return;
      const list = res.data.result?.messages || [];
      messages.value = list.map(normalize);
      hasMore.value = list.length >= PAGE;
    } else {
      const res = await api.get(`/api/message/group_chat?chats_id=${props.id}&limit=${PAGE}&offset=0`);
      if (seq !== loadSeq) return;
      const result = res.data.result || {};
      const list = result.messages || [];
      messages.value = list.map(normalize);
      hasMore.value = list.length >= PAGE;
      groupName.value = result.chat?.name || props.title || 'Group chat';
      members.value = result.users || [];
      creatorId.value = result.chat?.created_by ?? null;
      emit('group-loaded', { name: groupName.value, members: members.value, creatorId: creatorId.value });
    }
    emit('refresh-chats'); // opening marks messages read; update the list
  } catch (e) {
    if (seq !== loadSeq) return;
    console.error('ConversationView load error:', e);
    loadError.value = true;
  } finally {
    if (seq === loadSeq) {
      loading.value = false;
      scrollToBottom();
    }
  }
}

async function loadDmProfile() {
  try {
    const res = await api.get(`/api/user/profile?users_id=${props.id}`);
    dmProfile.value = res.data.result || null;
  } catch {
    dmProfile.value = null;
  }
}

async function loadOlder() {
  if (loading.value || loadingOlder.value || !hasMore.value || !messages.value.length) return;
  const el = scrollRef.value;
  const seq = loadSeq;
  const prevHeight = el?.scrollHeight ?? 0;
  const prevTop = el?.scrollTop ?? 0;
  loadingOlder.value = true;
  try {
    let list: any[] = [];
    if (props.kind === 'direct') {
      const oldest = messages.value.find((m) => m.id > 0);
      if (!oldest) return;
      const res = await api.get(
        `/api/message/get_messages?users_id=${props.id}&order=ASC&limit=${PAGE}&before_id=${oldest.id}&mark_as_read=0`
      );
      list = res.data.result?.messages || [];
    } else {
      const offset = messages.value.filter((m) => m.id > 0).length;
      const res = await api.get(`/api/message/group_chat?chats_id=${props.id}&limit=${PAGE}&offset=${offset}`);
      list = res.data.result?.messages || [];
    }
    if (seq !== loadSeq) return;
    hasMore.value = list.length >= PAGE;
    const known = realIds();
    const older = list.filter((m) => !known.has(m.id)).map(normalize);
    if (!older.length) {
      hasMore.value = false;
      return;
    }
    messages.value = [...older, ...messages.value];
    sortMessages();
    await nextTick();
    if (el) el.scrollTop = el.scrollHeight - prevHeight + prevTop; // keep the reader's place
  } catch (e) {
    console.error('ConversationView loadOlder error:', e);
  } finally {
    loadingOlder.value = false;
  }
}

// Pull the newest page and merge it in. Used for live updates: it doesn't depend on the
// socket payload's shape, and for DMs it also marks what the member is looking at as read.
function canMarkRead(): boolean {
  return route.path === '/main' && document.visibilityState === 'visible';
}

function scheduleSync() {
  if (!canMarkRead()) {
    pendingSync = true; // catch up when the member is back on this screen
    return;
  }
  if (syncTimer) clearTimeout(syncTimer);
  syncTimer = setTimeout(syncLatest, 250);
}

async function syncLatest() {
  pendingSync = false;
  const seq = loadSeq;
  const wasAtBottom = distanceFromBottom() < 80;
  try {
    let list: any[] = [];
    if (props.kind === 'direct') {
      const res = await api.get(`/api/message/get_messages?users_id=${props.id}&order=ASC&limit=20&mark_as_read=1`);
      list = res.data.result?.messages || [];
    } else {
      const res = await api.get(`/api/message/group_chat?chats_id=${props.id}&limit=20&offset=0`);
      list = res.data.result?.messages || [];
    }
    if (seq !== loadSeq) return;
    const added = mergeMessages(list);
    if (added) {
      if (wasAtBottom) scrollToBottom(true);
      else newCount.value += added;
      emit('refresh-chats');
    }
  } catch {
    // Live updates are best-effort; the next event or a reopen catches up.
  }
}

// --- Sending (optimistic) ---
async function send() {
  const raw = draft.value.trim();
  if (!raw) return;
  const text = privateReply.value ? buildPrivateReplyText(privateReply.value, raw) : raw;
  const temp: ChatMessage = {
    id: -(++tempSeq),
    sender_id: props.currentUserId,
    sender_name: 'You',
    text,
    timestamp: new Date().toISOString(),
    _status: 'sending',
  };
  messages.value.push(temp);
  draft.value = '';
  privateReply.value = null;
  saveDraft(props.currentUserId, convKey.value, '');
  resizeInput();
  scrollToBottom(true);
  await deliver(temp.id);
}

async function deliver(tempId: number) {
  const seq = loadSeq;
  const idx = messages.value.findIndex((m) => m.id === tempId);
  if (idx === -1) return;
  messages.value[idx] = { ...messages.value[idx], _status: 'sending', _error: undefined };
  const text = messages.value[idx].text;
  try {
    const res =
      props.kind === 'direct'
        ? await api.post('/api/message/send_message', { users_id: props.id, message: text })
        : await api.post('/api/message/send_chat_message', { chats_id: props.id, message: text });
    if (seq !== loadSeq) return;
    const real = res.data?.message ? normalize(res.data.message) : null;
    const at = messages.value.findIndex((m) => m.id === tempId);
    if (at === -1) return;
    if (!real || realIds().has(real.id)) messages.value.splice(at, 1); // already arrived via sync
    else messages.value[at] = real;
    if (!real) syncLatest();
    emit('refresh-chats');
  } catch (e: any) {
    if (seq !== loadSeq) return;
    const at = messages.value.findIndex((m) => m.id === tempId);
    if (at === -1) return;
    const status = e?.response?.status;
    const reason =
      status === 403 ? "Not sent: you can't message this person" : status === 429 ? 'Not sent: slow down a moment' : 'Not sent';
    messages.value[at] = { ...messages.value[at], _status: 'failed', _error: reason };
  }
}

function retry(msg: ChatMessage) {
  deliver(msg.id);
}

function discard(msg: ChatMessage) {
  messages.value = messages.value.filter((m) => m.id !== msg.id);
}

// --- Composer ---
function resizeInput() {
  nextTick(() => {
    const el = inputRef.value;
    if (!el) return;
    el.style.height = 'auto';
    const h = Math.min(el.scrollHeight, 200);
    el.style.height = `${h}px`;
    el.style.overflowY = el.scrollHeight > 200 ? 'auto' : 'hidden';
  });
}

function onDraftInput() {
  saveDraft(props.currentUserId, convKey.value, draft.value);
  resizeInput();
}

function focusInput() {
  nextTick(() => inputRef.value?.focus());
}

// --- Message actions (MessageBubble events) ---
const reactionPath = (id: number) =>
  props.kind === 'direct' ? `/api/message/toggle-reaction/${id}` : `/api/message/group/toggle-reaction/${id}`;
const messagePath = (id: number) => (props.kind === 'direct' ? `/api/message/${id}` : `/api/message/group/${id}`);

async function toggleReaction(messageId: number, emoji: string) {
  if (messageId < 0) return;
  try {
    const res = await api.post(reactionPath(messageId), { emoji });
    const idx = messages.value.findIndex((m) => m.id === messageId);
    if (idx !== -1 && res.data.reactions) messages.value[idx] = { ...messages.value[idx], reactions: res.data.reactions };
  } catch (e) {
    console.error('Failed to toggle reaction:', e);
  }
}

function openEmojiPicker(messageId: number) {
  if (messageId < 0) return;
  emojiMessageId.value = messageId;
  showEmoji.value = true;
}

function onEmojiSelected(messageId: number, emoji: string) {
  showEmoji.value = false;
  toggleReaction(messageId, emoji);
}

function startEdit(message: ChatMessage) {
  if (message.id > 0) editingId.value = message.id;
}

async function saveEdit(messageId: number, newText: string) {
  const text = newText.trim();
  if (!text || messageId < 0) return;
  try {
    const res = await api.put(messagePath(messageId), { text });
    const idx = messages.value.findIndex((m) => m.id === messageId);
    if (idx !== -1) {
      messages.value[idx] = {
        ...messages.value[idx],
        text,
        is_edited: true,
        edited_at: res.data.edited_at || new Date().toISOString(),
      };
    }
    editingId.value = null;
  } catch (e) {
    console.error('Failed to edit message:', e);
  }
}

function askDelete(messageId: number) {
  if (messageId < 0) return;
  deleteId.value = messageId;
  showDeleteConfirm.value = true;
}

async function confirmDelete() {
  const id = deleteId.value;
  if (id === null) return;
  try {
    await api.delete(messagePath(id));
    const idx = messages.value.findIndex((m) => m.id === id);
    if (idx !== -1) messages.value[idx] = { ...messages.value[idx], is_deleted: true };
  } catch (e) {
    console.error('Failed to delete message:', e);
  } finally {
    deleteId.value = null;
  }
}

async function restoreMessage(messageId: number) {
  try {
    await api.post(`${messagePath(messageId)}/restore`);
    const idx = messages.value.findIndex((m) => m.id === messageId);
    if (idx !== -1) messages.value[idx] = { ...messages.value[idx], is_deleted: false };
  } catch (e) {
    console.error('Failed to restore message:', e);
  }
}

async function showHistory(messageId: number) {
  if (props.kind !== 'direct' || messageId < 0) return; // group edit history isn't available yet
  historyOpen.value = true;
  historyLoading.value = true;
  historyError.value = false;
  history.value = null;
  try {
    const res = await api.get(`/api/message/${messageId}/history`);
    history.value = res.data.history || [];
  } catch {
    historyError.value = true;
  } finally {
    historyLoading.value = false;
  }
}

// --- Reply privately (groups) ---
function toggleReplyMenu(messageId: number) {
  replyMenuId.value = replyMenuId.value === messageId ? null : messageId;
}

function replyPrivately(msg: ChatMessage) {
  replyMenuId.value = null;
  startPrivateReply({
    recipientId: msg.sender_id,
    recipientName: msg.sender_name || 'them',
    groupName: displayName.value,
    text: msg.text || '',
  });
  router.push({ path: '/main', query: { c: `dm-${msg.sender_id}` } });
}

// --- Group leave / delete ---
function confirmGroupAction(action: 'leave' | 'delete') {
  showGroupMenu.value = false;
  groupActionError.value = '';
  groupAction.value = action;
}

async function runGroupAction() {
  const action = groupAction.value;
  if (!action) return;
  try {
    if (action === 'delete') await api.post('/api/message/delete_chat', { chats_id: props.id });
    else await api.post('/api/message/manage_chat', { chats_id: props.id, aDelIDs: [props.currentUserId] });
    groupAction.value = null;
    emit('left');
    emit('refresh-chats');
  } catch (e: any) {
    groupActionError.value = e?.response?.data?.error || 'Something went wrong. Please try again.';
  }
}

// --- Profile ---
function openProfile() {
  if (props.kind === 'direct') router.push(`/profile/${props.id}`);
}

// --- Conversation switching ---
watch(
  () => `${props.kind}-${props.id}`,
  (_now, before) => {
    if (before) {
      // Leaving the previous conversation
      const [prevKind, prevId] = before.split('-');
      if (prevKind === 'group') leaveChat(Number(prevId));
    }
    editingId.value = null;
    replyMenuId.value = null;
    dmProfile.value = null;
    members.value = [];
    groupName.value = '';
    creatorId.value = null;
    draft.value = readDraft(props.currentUserId, convKey.value);
    privateReply.value = props.kind === 'direct' ? takePrivateReply(props.id) : null;
    if (props.kind === 'group') joinChat(props.id);
    loadInitial();
    resizeInput();
    focusInput();
  },
  { immediate: true }
);

// Back on this screen after viewing another page: catch up on anything that arrived.
watch(
  () => route.path,
  (path) => {
    if (path === '/main' && pendingSync) scheduleSync();
  }
);

function onVisibility() {
  if (document.visibilityState === 'visible' && pendingSync) scheduleSync();
}

// --- Realtime ---
let unsubs: Array<() => void> = [];

onMounted(() => {
  document.addEventListener('visibilitychange', onVisibility);

  unsubs.push(
    onDirectMessageNotification((payload: Record<string, any>) => {
      if (props.kind !== 'direct') return;
      const senderId = Number(payload.sender_id ?? payload.senderId ?? -1);
      if (senderId !== props.id) return;
      // Show it right away when the payload carries the message, then reconcile.
      if (payload.message?.id && canMarkRead()) {
        const wasAtBottom = distanceFromBottom() < 80;
        const added = mergeMessages([payload.message]);
        if (added) {
          if (wasAtBottom) scrollToBottom(true);
          else newCount.value += added;
        }
      }
      scheduleSync();
    })
  );

  const onGroup = (payload: Record<string, any>) => {
    if (props.kind !== 'group') return;
    const chatId = Number(payload.chat_id ?? payload.chatId ?? -1);
    if (chatId !== props.id) return;
    const senderId = Number(payload.sender_id ?? payload.senderId ?? -1);
    if (senderId === props.currentUserId) return;
    scheduleSync();
  };
  unsubs.push(onGroupMessage(onGroup));
  unsubs.push(onGroupMessageNotification(onGroup));
});

onUnmounted(() => {
  document.removeEventListener('visibilitychange', onVisibility);
  unsubs.forEach((u) => u());
  unsubs = [];
  if (syncTimer) clearTimeout(syncTimer);
  if (props.kind === 'group') leaveChat(props.id);
  loadSeq++; // drop any in-flight responses
});
</script>

<style scoped>
.cv-pop-enter-active,
.cv-pop-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
/* Tailwind 4's translate utilities use the `translate` property, so this stacks on top */
.cv-pop-enter-from,
.cv-pop-leave-to {
  opacity: 0;
  transform: translateY(6px);
}
</style>
