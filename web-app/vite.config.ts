import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'
// @ts-ignore
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    VitePWA({
      registerType: 'autoUpdate',
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,jpg,jpeg,svg,gif,webp}'],
        runtimeCaching: [
          {
            // Cache images from your backend
            urlPattern: /^https:\/\/.*\.(png|jpg|jpeg|svg|gif|webp)$/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'images-cache',
              expiration: {
                maxEntries: 500,
                maxAgeSeconds: 60 * 60 * 24 * 30 // 30 days
              },
              cacheableResponse: {
                statuses: [0, 200]
              }
            }
          },
          {
            // Cache API responses
            urlPattern: /^https:\/\/.*\/api\/.*/i,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'api-cache',
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 5 // 5 minutes
              },
              networkTimeoutSeconds: 10
            }
          }
        ]
      },
      manifest: {
        name: 'Rep',
        short_name: 'Rep',
        description: 'Rep - Network and Collaborate',
        theme_color: '#8cc65d',
        background_color: '#ffffff',
        display: 'standalone',
        icons: [
          {
            src: '/icon-192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: '/icon-512.png',
            sizes: '512x512',
            type: 'image/png'
          }
        ]
      }
    })
  ],
  resolve: {
    alias: {
      // @ts-ignore
      '@': path.resolve(__dirname, 'src')
    },
  },
  server: {
    proxy: {
      // Forward all /api calls to the live Render backend during local dev.
      // The browser sees requests going to localhost (no CORS), Vite proxies
      // them server-to-server. Has no effect on production builds.
      '/api': {
        target: 'https://rep-june2025.onrender.com',
        changeOrigin: true,
        secure: true,
      }
    }
  }
})
