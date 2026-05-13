

import { ref, readonly } from 'vue';
import { io, Socket, Manager } from 'socket.io-client';

// --- Type Definitions ---
type SocketCallback = (payload: any) => void;
interface Observer {
  id: number;
  callback: SocketCallback;
}

// --- Module-level state (acts as a singleton) ---
let manager: Manager | null = null;
let socket: Socket | null = null;

const isConnected = ref(false);
let handlersRegistered = false;

// Track last connection parameters for reuse/deduplication
let lastBaseURL: string | null = null;
let lastToken: string | null = null;
let lastUserId: number | null = null;
let pendingUserId: number | null = null;

// Observer storage
let observerIdCounter = 0;
const dmObservers = ref<Observer[]>([]);
const groupObservers = ref<Observer[]>([]);
const groupNotifObservers = ref<Observer[]>([]);
const goalTeamInviteObservers = ref<Observer[]>([]);
const goalTeamInviteUpdateObservers = ref<Observer[]>([]);

// --- Private Functions ---

const notify = (observers: Observer[], payload: any) => {
  // Handle fragmented payloads by merging if necessary
  let finalPayload = {};
  if (Array.isArray(payload) && payload.every(p => typeof p === 'object')) {
    payload.forEach(p => Object.assign(finalPayload, p));
  } else if (typeof payload === 'object' && payload !== null) {
    finalPayload = payload;
  } else {
    console.warn('(Socket) Received non-object payload:', payload);
    return;
  }
  if (Object.keys(finalPayload).length > 0) {
    observers.forEach(obs => obs.callback(finalPayload));
  }
};

const joinUserRoom = (userId: number) => {
  if (!socket) return;
  // Prefer explicit event; fallback legacy 'join'
  socket.emit("join_user_room", { user_id: userId });
  socket.emit("join", { room: `user_${userId}` }); // Backward compatibility
  if (import.meta.env.DEV) console.log(`➡️ (Realtime) Emitted join_user_room for user_${userId}`);
};

const registerEventHandlersIfNeeded = () => {
  if (handlersRegistered || !socket) return;
  handlersRegistered = true;
  if (import.meta.env.DEV) console.log("🧩 (Realtime) Registering event handlers");

  // Direct message events (multiple possible names)
  const dmEventNames = ["direct_message_notification", "new_direct_message", "direct_message", "dm_notification"];
  dmEventNames.forEach(event => {
    socket?.on(event, (data) => notify(dmObservers.value, data));
  });

  // Group message event (for specific chat rooms)
  socket.on("group_message", (data) => notify(groupObservers.value, data));

  // Group notification event (for the main 'OPEN' dot)
  socket.on("group_message_notification", (data) => notify(groupNotifObservers.value, data));

  // Invite events
  socket.on("goal_team_invite", (data) => notify(goalTeamInviteObservers.value, data));
  socket.on("goal_team_invite_update", (data) => notify(goalTeamInviteUpdateObservers.value, data));
};

const registerLifecycle = () => {
  if (!socket) return;

  socket.on('connect', () => {
    isConnected.value = true;
    if (import.meta.env.DEV) console.log(`✅ (Realtime) Connected -> ${lastBaseURL || ""}`);
    if (pendingUserId) {
      joinUserRoom(pendingUserId);
    } else {
      if (import.meta.env.DEV) console.warn("⚠️ (Realtime) No pending user id at connect");
    }
    registerEventHandlersIfNeeded();
  });

  socket.on('disconnect', (reason) => {
    isConnected.value = false;
    if (import.meta.env.DEV) console.log(`❌ (Realtime) Disconnected: ${reason}`);
  });

  socket.on('connect_error', (err) => {
    console.error(`⚠️ (Realtime) Connection Error: ${err.message}`);
  });
};

const buildManager = (baseURL: string, token: string) => {
  // Tear down old manager if it exists
  manager?.disconnect();

  manager = new Manager(baseURL, {
    reconnection: true,
    reconnectionAttempts: Infinity,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 20000,
    autoConnect: true,
    forceNew: true,
    transports: ['websocket', 'polling'],
    auth: { token }, // Use auth option for modern socket.io
    extraHeaders: { Authorization: `Bearer ${token}` }, // Keep for polling fallback
  });

  socket = manager.socket('/');
  handlersRegistered = false;
  registerLifecycle();
};

// --- Public Composable Function ---

export function useSocketManager() {

  const connect = (baseURL: string, token: string, userId: number) => {
    if (!baseURL || !token || userId === 0) {
      if (import.meta.env.DEV) console.warn(`⚠️ (Realtime) Skipping connect - missing params:`, {
        hasBaseURL: !!baseURL,
        hasToken: !!token,
        userId
      });
      return;
    }
    pendingUserId = userId;

    // Normalize URL: strip trailing "/api"
    const normalizedURL = baseURL.endsWith("/api") ? baseURL.slice(0, -4) : baseURL;

    // If already connected with same config, just ensure room join
    if (socket && isConnected.value && lastBaseURL === normalizedURL && lastToken === token) {
      if (lastUserId !== userId) {
        lastUserId = userId;
        joinUserRoom(userId);
      }
      return;
    }

    // If config changed, rebuild the manager
    if (!manager || lastBaseURL !== normalizedURL || lastToken !== token) {
      buildManager(normalizedURL, token);
    }

    lastBaseURL = normalizedURL;
    lastToken = token;
    lastUserId = userId;

    socket?.connect();
  };

  const disconnect = () => {
    manager?.disconnect();
    isConnected.value = false;
  };

  const addObserver = (observerList: Observer[], callback: SocketCallback): (() => void) => {
    const id = ++observerIdCounter;
    observerList.push({ id, callback });
    // Return an unsubscribe function
    return () => {
      const index = observerList.findIndex(obs => obs.id === id);
      if (index !== -1) {
        observerList.splice(index, 1);
      }
    };
  };

  // --- Public Methods ---
  return {
    isConnected: readonly(isConnected),
    connect,
    disconnect,

    // Room management
    joinChat: (chatId: number) => {
      socket?.emit("join_group_chat", { chat_id: chatId });
      socket?.emit("join", { chat_id: chatId }); // Legacy
      if (import.meta.env.DEV) console.log(`➡️ (Realtime) join group chat ${chatId}`);
    },
    leaveChat: (chatId: number) => {
      socket?.emit("leave_group_chat", { chat_id: chatId });
      socket?.emit("leave", { chat_id: chatId }); // Legacy
      if (import.meta.env.DEV) console.log(`⬅️ (Realtime) leave group chat ${chatId}`);
    },

    // Listener registration
    onDirectMessageNotification: (callback: SocketCallback) => addObserver(dmObservers.value, callback),
    onGroupMessage: (callback: SocketCallback) => addObserver(groupObservers.value, callback),
    onGroupMessageNotification: (callback: SocketCallback) => addObserver(groupNotifObservers.value, callback),
    onGoalTeamInvite: (callback: SocketCallback) => addObserver(goalTeamInviteObservers.value, callback),
    onGoalTeamInviteUpdate: (callback: SocketCallback) => addObserver(goalTeamInviteUpdateObservers.value, callback),
  };
}