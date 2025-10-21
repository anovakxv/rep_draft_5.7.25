
// router.ts
import { createRouter, createWebHistory } from 'vue-router'
import RegisterNewProfile from './pages/RepProfile/RegisterNewProfile.vue'
import LoginView from './pages/RepProfile/LoginView.vue'
import OnboardingView from './pages/RepProfile/OnboardingView.vue'
import MainScreen from './pages/MainPages/MainScreen.vue'
import PortalPage from './pages/MainPages/PortalPage.vue'
import EditPortal from './pages/MainPages/Edit_Portal.vue'
import PortalPaymentSetup from './pages/MainPages/PortalPaymentSetup.vue'
import ProfileView from './pages/RepProfile/ProfileView.vue'
import EditProfile from './pages/RepProfile/EditProfile.vue'
import WriteView from './pages/RepProfile/WriteView.vue'
import Terms from './pages/RepProfile/Terms.vue'
import Settings from './pages/RepProfile/Settings.vue'
import Payments from './pages/RepProfile/Payments.vue'
import ChatWrapper from './pages/Messaging/ChatWrapper.vue'
import ChatGroupWrapper from './pages/Messaging/ChatGroupWrapper.vue'
import GoalsDetailView from './pages/GoalPages/GoalsDetailView.vue'
import StripePaymentReturn from './pages/MainPages/StripePaymentReturn.vue'
import StripeConnectReturn from './pages/MainPages/StripeConnectReturn.vue'
import ResetPassword from './pages/RepProfile/ResetPassword.vue'
import NewPassword from './pages/RepProfile/NewPassword.vue'

const routes = [
  // Authentication routes
  { path: '/', redirect: checkAuth },
  { path: '/register', component: RegisterNewProfile },
  { path: '/login', component: LoginView },
  { path: '/onboarding', component: OnboardingView },
  { path: '/terms', component: Terms },
  { path: '/reset-password', component: ResetPassword },
  { path: '/new-password', component: NewPassword },

  // Main app routes
  { path: '/main', component: MainScreen, meta: { requiresAuth: true } },
  { path: '/portal/:id', component: PortalPage, meta: { requiresAuth: true } },
  { path: '/portal/edit/:id', component: EditPortal, meta: { requiresAuth: true } },
  { path: '/portal/:id/payment-setup', component: PortalPaymentSetup, meta: { requiresAuth: true } },
  { path: '/profile/:id', component: ProfileView, meta: { requiresAuth: true } },
  { path: '/profile/edit', component: EditProfile, meta: { requiresAuth: true } },
  {
    path: '/profile',
    redirect: () => {
      const userId = localStorage.getItem('userId')
      return userId ? `/profile/${userId}` : '/login'
    },
    meta: { requiresAuth: true }
  },
  { path: '/write/new', component: WriteView, meta: { requiresAuth: true } },
  { path: '/write/edit/:id', component: WriteView, meta: { requiresAuth: true } },
  { path: '/settings', name: 'Settings', component: Settings, meta: { requiresAuth: true } },
  { path: '/payments', name: 'Payments', component: Payments, meta: { requiresAuth: true } },
  { path: '/goal/:id', component: GoalsDetailView, meta: { requiresAuth: true } },

  // Messaging routes
  { path: '/chat/dm/:id', component: ChatWrapper, meta: { requiresAuth: true } },
  { path: '/chat/user/:id', redirect: to => `/chat/dm/${to.params.id}`, meta: { requiresAuth: true } },
  { path: '/chat/direct/:id', redirect: to => `/chat/dm/${to.params.id}`, meta: { requiresAuth: true } },
  { path: '/chat/group/:id', component: ChatGroupWrapper, meta: { requiresAuth: true } },

  // Invites (placeholder for now, we'll create this page)
  {
    path: '/invites',
    component: () => import('./pages/GoalPages/InvitesView.vue'),
    meta: { requiresAuth: true }
  },

  // Stripe return pages (no auth required - these are redirects from Stripe)
  { path: '/stripe-payment-return', component: StripePaymentReturn },
  { path: '/stripe-connect-return', component: StripeConnectReturn },
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
