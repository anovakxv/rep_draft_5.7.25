
import { useSocketManager } from "./useSocketManager";

// Create the socket manager instance
const socketManager = useSocketManager();

// Create a UUID generator to match Swift's UUID format
const generateUUID = (): string => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
};

// Create the global window interface
declare global {
  interface Window {
    RealtimeSocketManager: {
      // Connection methods
      connect: (baseURL: string, token: string, userId: number) => void;

      // Room methods
      join: (chatId: number) => void;
      leave: (chatId: number) => void;

      // Observer methods
      onGroupMessage: (callback: (payload: any) => void) => string;
      removeGroupMessageObserver: (id: string) => void;
      onDirectMessageNotification: (callback: (payload: any) => void) => string;
      removeDirectMessageObserver: (id: string) => void;
      onGroupMessageNotification: (callback: (payload: any) => void) => string;
      removeGroupMessageNotificationObserver: (id: string) => void;

      // Private property to store unsubscribe functions
      _unsubMap?: Map<string, () => void>;
    };
  }
}

// Create the global bridge object
window.RealtimeSocketManager = {
  connect: (baseURL: string, token: string, userId: number) => {
    socketManager.connect(baseURL, token, userId);
  },
  
  join: (chatId: number) => {
    socketManager.joinChat(chatId);
  },
  
  leave: (chatId: number) => {
    socketManager.leaveChat(chatId);
  },
  
  onGroupMessage: (callback: (payload: any) => void) => {
    const wrappedCallback = (payload: any) => {
      // Add robust type handling similar to Swift
      let chatId: number | null = null;
      const chatIdRaw = payload.chat_id ?? payload.chatId;
      
      if (typeof chatIdRaw === 'number') {
        chatId = chatIdRaw;
      } else if (typeof chatIdRaw === 'string') {
        chatId = parseInt(chatIdRaw, 10);
      }
      
      // Create a new payload with consistent properties
      const normalizedPayload = {
        ...payload,
        chat_id: chatId,
        chatId: chatId
      };
      
      callback(normalizedPayload);
    };
    
    const uuid = generateUUID();
    const unsubscribe = socketManager.onGroupMessage(wrappedCallback);
    
    // Store the unsubscribe function with the UUID
    const unsubMap = window.RealtimeSocketManager._unsubMap || new Map();
    unsubMap.set(uuid, unsubscribe);
    window.RealtimeSocketManager._unsubMap = unsubMap;
    
    return uuid;
  },
  
  removeGroupMessageObserver: (id: string) => {
    const unsubMap = window.RealtimeSocketManager._unsubMap || new Map();
    const unsubscribe = unsubMap.get(id);
    if (unsubscribe) {
      unsubscribe();
      unsubMap.delete(id);
    }
  },
  
  onDirectMessageNotification: (callback: (payload: any) => void) => {
    const uuid = generateUUID();
    const unsubscribe = socketManager.onDirectMessageNotification(callback);
    
    const unsubMap = window.RealtimeSocketManager._unsubMap || new Map();
    unsubMap.set(uuid, unsubscribe);
    window.RealtimeSocketManager._unsubMap = unsubMap;
    
    return uuid;
  },
  
  removeDirectMessageObserver: (id: string) => {
    const unsubMap = window.RealtimeSocketManager._unsubMap || new Map();
    const unsubscribe = unsubMap.get(id);
    if (unsubscribe) {
      unsubscribe();
      unsubMap.delete(id);
    }
  },
  
  onGroupMessageNotification: (callback: (payload: any) => void) => {
    const uuid = generateUUID();
    const unsubscribe = socketManager.onGroupMessageNotification(callback);
    
    const unsubMap = window.RealtimeSocketManager._unsubMap || new Map();
    unsubMap.set(uuid, unsubscribe);
    window.RealtimeSocketManager._unsubMap = unsubMap;
    
    return uuid;
  },
  
  removeGroupMessageNotificationObserver: (id: string) => {
    const unsubMap = window.RealtimeSocketManager._unsubMap || new Map();
    const unsubscribe = unsubMap.get(id);
    if (unsubscribe) {
      unsubscribe();
      unsubMap.delete(id);
    }
  },
  
  // Private property to store unsubscribe functions
  _unsubMap: new Map<string, () => void>()
};
