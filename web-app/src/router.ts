
// router.ts
import { createRouter, createWebHistory } from 'vue-router'
import RegisterNewProfile from './pages/RepProfile/RegisterNewProfile.vue'
import LoginView from './pages/RepProfile/LoginView.vue'
import OnboardingView from './pages/RepProfile/OnboardingView.vue'
import MainScreen from './pages/MainPages/MainScreen.vue'
import PortalPage from './pages/MainPages/PortalPage.vue'
import EditPortal from './pages/MainPages/Edit_Portal.vue'
import ProfileView from './pages/RepProfile/ProfileView.vue'
import EditProfile from './pages/RepProfile/EditProfile.vue'
import Terms from './pages/RepProfile/Terms.vue'
import Chat_Individual from './pages/Messaging/Chat_Individual.vue'
import Chat_Group from './pages/Messaging/Chat_Group.vue'

const routes = [
  // Authentication routes
  { path: '/', redirect: checkAuth },
  { path: '/register', component: RegisterNewProfile },
  { path: '/login', component: LoginView },
  { path: '/onboarding', component: OnboardingView },
  { path: '/terms', component: Terms },
  
  // Main app routes
  { path: '/main', component: MainScreen, meta: { requiresAuth: true } },
  { path: '/portal/:id', component: PortalPage, meta: { requiresAuth: true } },
  { path: '/portal/edit/:id', component: EditPortal, meta: { requiresAuth: true } },
  { path: '/profile/:id', component: ProfileView, meta: { requiresAuth: true } },
  { path: '/profile/edit', component: EditProfile, meta: { requiresAuth: true } },
  { path: '/chat/direct/:id', component: Chat_Individual, props: true, meta: { requiresAuth: true } },
  { path: '/chat/group/:id', component: Chat_Group, props: true, meta: { requiresAuth: true } },
]

// Auth check function (similar to Swift's RootAppView logic)
function checkAuth() {
  const isRegistered = localStorage.getItem('isRegistered') === 'true'
  const onboardingComplete = localStorage.getItem('onboardingComplete') === 'true'
  const jwtToken = localStorage.getItem('jwtToken')
  const userId = localStorage.getItem('userId')

  if (!isRegistered) {
    return '/register'
  } else if (!onboardingComplete) {
    return '/onboarding'
  } else if (jwtToken && userId) {
    return '/main'
  } else {
    return '/login'
  }
}

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guard (similar to Swift's auth checks)
router.beforeEach((to, from, next) => {
  if (to.meta.requiresAuth) {
    const jwtToken = localStorage.getItem('jwtToken')
    const userId = localStorage.getItem('userId')
    const isAuthenticated = jwtToken && userId
    
    if (!isAuthenticated) {
      next('/login')
    } else {
      next()
    }
  } else {
    next()
  }
})

export default router
