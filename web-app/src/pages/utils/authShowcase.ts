// src/pages/utils/authShowcase.ts
// Data for the left side of the log-in and sign-up pages (AuthShowcase.vue):
// - the "living wall" of real purposes from the public portal list
// - the purpose or goal behind a shared link (?returnTo=/portal/123 or /goal/45)

import { ref, type Ref } from 'vue'
import api from './api'

export interface WallPurpose {
  id: number
  name: string
  subtitle: string | null
  imageUrl: string | null
}

export interface SharedLink {
  name: string
  subtitle: string | null
  imageUrl: string | null
}

// Fewer purposes than this and the wall looks repetitive, so the page shows the plain pitch instead
export const MIN_WALL_PURPOSES = 6

let wallRequest: Promise<WallPurpose[]> | null = null

// Loads once per visit and is shared by the log-in and sign-up pages
export function loadWallPurposes(): Promise<WallPurpose[]> {
  if (!wallRequest) {
    wallRequest = api
      .get('/api/public/portals?limit=40')
      .then((res) => {
        const now = Date.now()
        const purposes: WallPurpose[] = ((res.data?.result ?? []) as any[])
          .filter((p) => p?.name && !(p.event_datetime && new Date(p.event_datetime).getTime() < now))
          .map((p) => ({
            id: Number(p.id),
            name: String(p.name),
            subtitle: p.subtitle ? String(p.subtitle) : null,
            imageUrl: p.mainImageUrl || null,
          }))
        const withImages = purposes.filter((p) => p.imageUrl)
        return withImages.length >= MIN_WALL_PURPOSES ? withImages : purposes
      })
      .catch(() => {
        wallRequest = null
        return []
      })
  }
  return wallRequest
}

// Looks up the purpose or goal a visitor was sent to, so the page can show it instead of the general pitch
export function useSharedLink(returnTo: string | undefined): Ref<SharedLink | null> {
  const sharedLink = ref<SharedLink | null>(null)
  const match = returnTo?.match(/^\/(portal|goal)\/(\d+)(?:[/?#]|$)/)
  if (!match) return sharedLink

  const [, type, id] = match
  api
    .get(`/api/public/${type}/${id}`)
    .then((res) => {
      const item = res.data?.result
      if (!item) return
      if (type === 'portal' && item.name) {
        sharedLink.value = {
          name: String(item.name),
          subtitle: item.subtitle ? String(item.subtitle) : null,
          imageUrl: item.mainImageUrl || null,
        }
      } else if (type === 'goal' && item.title) {
        sharedLink.value = {
          name: String(item.title),
          subtitle: item.portalName ? `A goal in ${item.portalName}` : null,
          imageUrl: null,
        }
      }
    })
    .catch(() => {
      // Not found or offline: keep the general pitch
    })
  return sharedLink
}
