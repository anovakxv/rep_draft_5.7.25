// auth.ts
// Authentication helper utilities for public web app

import { useRouter } from 'vue-router'
import api from '@/pages/utils/api'
import { useSocketManager } from '@/pages/utils/useSocketManager'

/**
 * Check if user is authenticated
 * @returns true if user has valid JWT token and userId
 */
export function isAuthenticated(): boolean {
  const jwtToken = localStorage.getItem('jwtToken')
  const userId = localStorage.getItem('userId')
  return !!(jwtToken && userId)
}

/**
 * Redirect to login page with returnTo parameter
 * @param returnTo - Optional path to return to after login. If not provided, uses current route
 */
export function requireAuth(returnTo?: string): void {
  const router = useRouter()
  const redirectPath = returnTo || window.location.pathname
  router.push({
    path: '/login',
    query: { returnTo: redirectPath }
  })
}

/**
 * Get current user ID from localStorage
 * @returns userId string or null
 */
export function getCurrentUserId(): string | null {
  return localStorage.getItem('userId')
}

/**
 * Get JWT token from localStorage
 * @returns JWT token string or null
 */
export function getJwtToken(): string | null {
  return localStorage.getItem('jwtToken')
}

/**
 * Sign the user out on this device: tell the server, drop the realtime
 * connection, and clear the local session. The caller navigates to /login.
 * The server call is fire-and-forget (api reads the token before any await),
 * so a slow or sleeping backend never blocks signing out.
 */
export function logout(): void {
  api.post('/api/user/logout', {}).catch(() => {})
  useSocketManager().disconnect()
  localStorage.clear()
}
