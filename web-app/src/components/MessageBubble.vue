<template>
  <div class="flex" :class="isCurrentUser ? 'justify-end' : 'justify-start'">
    <!-- Profile Picture (for other user) -->
    <img
      v-if="!isCurrentUser && profilePicURL && profilePicURL.trim()"
      :src="profilePicURL"
      class="w-8 h-8 rounded-full mr-2 mt-1 flex-shrink-0 object-cover"
      alt="Profile"
    />

    <div class="max-w-[70%]">
      <!-- Message Bubble -->
      <div
        class="rounded-lg px-4 py-2"
        :class="isCurrentUser ? 'bg-black text-rep-green' : 'bg-gray-200 text-gray-800'"
      >
        <!-- Attachments -->
        <div v-if="message.attachments && message.attachments.length > 0" class="mb-2 space-y-2">
          <div v-for="(attachment, index) in message.attachments" :key="index">
            <!-- Image Attachment -->
            <img
              v-if="attachment.type === 'image'"
              :src="attachment.url"
              :alt="attachment.filename || 'Image'"
              class="rounded-lg max-w-full h-auto cursor-pointer"
              @click="openImage(attachment.url)"
            />
            <!-- File Attachment -->
            <a
              v-else
              :href="attachment.url"
              target="_blank"
              class="flex items-center gap-2 p-2 rounded-lg hover:opacity-80"
              :class="isCurrentUser ? 'bg-gray-900' : 'bg-gray-300'"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clip-rule="evenodd" />
              </svg>
              <span class="text-sm truncate">{{ attachment.filename || 'File' }}</span>
            </a>
          </div>
        </div>

        <!-- Message Text -->
        <p v-if="message.text" class="text-sm break-words whitespace-pre-wrap">{{ message.text }}</p>
      </div>

      <!-- Timestamp -->
      <div class="flex items-center gap-1 mt-1 px-1" :class="isCurrentUser ? 'justify-end' : 'justify-start'">
        <span class="text-xs text-gray-500">{{ formattedTimestamp }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

interface MessageAttachment {
  url: string;
  type: 'image' | 'file';
  filename?: string;
}

interface Message {
  id: number;
  senderId: number;
  senderName: string;
  text: string;
  timestamp: string;
  read?: string;
  attachments?: MessageAttachment[];
}

const props = defineProps<{
  message: Message;
  isCurrentUser: boolean;
  profilePicURL?: string;
}>();

const formattedTimestamp = computed(() => {
  const date = new Date(props.message.timestamp);
  const now = new Date();
  const isToday = date.toDateString() === now.toDateString();

  if (isToday) {
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
  } else {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', hour12: true });
  }
});

function openImage(url: string) {
  window.open(url, '_blank');
}
</script>

<style scoped>
.text-rep-green {
  color: #8cc65d;
}
</style>
