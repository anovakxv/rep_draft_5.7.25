import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import './assets/main.css'
import router from './router'

// Import the socket bridge here:
import './socket-bridge';

createApp(App)
  .use(router)
  .mount('#app')