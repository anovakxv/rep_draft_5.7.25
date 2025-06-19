
<template>
  <ion-page>
    <ion-header>
      <ion-toolbar>
        <ion-buttons slot="start">
          <ion-avatar @click="goToProfile">
            <img :src="profilePic" alt="Profile" />
          </ion-avatar>
        </ion-buttons>
        <ion-title>
          <ion-segment v-model="section" value="0">
            <ion-segment-button value="0">OPEN</ion-segment-button>
            <ion-segment-button value="1">NTWK</ion-segment-button>
            <ion-segment-button value="2">ALL</ion-segment-button>
          </ion-segment>
        </ion-title>
        <ion-buttons slot="end">
          <ion-button>
            <ion-icon :icon="arrowDown" />
          </ion-button>
        </ion-buttons>
      </ion-toolbar>
    </ion-header>

    <ion-content>
      <div v-if="page === 'people'">
        <ion-list>
          <ion-item v-for="chat in sortedChats" :key="chat.id" button @click="goToChat(chat)">
            <ion-avatar slot="start">
              <img :src="chat.imageUrl" />
            </ion-avatar>
            <ion-label>
              <div class="chat-header">
                <span class="chat-name">{{ chat.name }}</span>
                <span class="chat-date">{{ chat.lastMessageDateFormatted }}</span>
              </div>
              <div class="chat-message">{{ chat.lastMessage }}</div>
            </ion-label>
          </ion-item>
        </ion-list>
      </div>
      <div v-else>
        <ion-list>
          <ion-item v-for="portal in portals" :key="portal.id" button @click="goToPortal(portal)">
            <ion-thumbnail slot="start">
              <img :src="portal.imageUrl" style="object-fit:cover;width:80px;height:45px;" />
            </ion-thumbnail>
            <ion-label>
              <div class="portal-header">
                <span class="portal-name">{{ portal.name }}</span>
                <span class="portal-category">{{ portal.category }}</span>
              </div>
              <div v-if="portal.subtitle" class="portal-subtitle">{{ portal.subtitle }}</div>
              <div class="portal-footer">
                <span class="portal-city">{{ portal.city }}</span>
                <span class="portal-leads">{{ portal.leads.length }} leads</span>
              </div>
            </ion-label>
          </ion-item>
        </ion-list>
      </div>
      <!-- Floating REP logo button -->
     <ion-fab vertical="bottom" horizontal="end" slot="fixed">
        <ion-fab-button @click="togglePage" style="--background: transparent;">
          <img src="/assets/REPLogo.png" style="width: 36px; height: 36px;" />
        </ion-fab-button>
      </ion-fab>
    </ion-content>
  </ion-page>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { IonPage, IonHeader, IonToolbar, IonTitle, IonButtons, IonButton, IonIcon, IonContent, IonList, IonItem, IonLabel, IonAvatar, IonSegment, IonSegmentButton, IonFab, IonFabButton, IonThumbnail } from '@ionic/vue'
import { chevronDown as arrowDown } from 'ionicons/icons'

// Dummy data for demonstration
const profilePic = '/assets/profile.jpg'
const page = ref<'people' | 'portals'>('people')
const section = ref('0')

const chatItems = ref([
  {
    id: 1,
    imageUrl: '/assets/leadPic.png',
    name: 'Martin G.',
    lastMessage: 'Hello Matt! Are you still there?',
    lastMessageDate: new Date(Date.now() - 15000)
  },
  // ...more chat items
])

const portals = ref([
  {
    id: 1,
    name: 'Networked Capital',
    subtitle: 'A global network...',
    about: 'About text',
    category: 'Business',
    city: 'New York',
    imageUrl: '/assets/sampleImage.png',
    leads: [{ id: 1 }, { id: 2 }]
  },
  // ...more portals
])

const sortedChats = computed(() =>
  [...chatItems.value].sort((a, b) => b.lastMessageDate.getTime() - a.lastMessageDate.getTime())
)

function goToProfile() {
  // Navigate to profile page
}

function goToChat(chat: any) {
  // Navigate to chat page
}

function goToPortal(portal: any) {
  // Navigate to portal page
}

function togglePage() {
  page.value = page.value === 'people' ? 'portals' : 'people'
}
</script>

<style>
.chat-header, .portal-header, .portal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;

  ion-fab-button {
  --box-shadow: none !important;
  box-shadow: none !important;
}

ion-fab-button::part(native) {
  box-shadow: none !important;
}

}
.chat-name, .portal-name {
  font-weight: 500;
}
.chat-date, .portal-category, .portal-leads {
  font-size: 0.8em;
  color: #888;
}
.portal-subtitle {
  font-size: 0.9em;
  color: #666;
  margin: 2px 0;
}
.portal-city {
  font-size: 0.8em;
  color: #888;
}
</style>
