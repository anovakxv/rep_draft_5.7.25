import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import './assets/main.css'
import './assets/transitions.css'
import router from './router'

// Import the socket bridge here:
import './pages/utils/socket-bridge'

// Register PWA service worker for image caching
import { registerSW } from 'virtual:pwa-register'

const updateSW = registerSW({
  onNeedRefresh() {
    console.log('New content available, please refresh.')
    // Optionally, you can auto-refresh here or show a notification to the user
    // For now, we'll just log it - the service worker will update automatically
  },
  onOfflineReady() {
    console.log('App ready to work offline')
  },
  onRegistered(registration) {
    console.log('Service Worker registered:', registration)
  },
  onRegisterError(error) {
    console.error('Service Worker registration error:', error)
  }
})

createApp(App)
  .use(router)
  .mount('#app')