<script setup lang="ts">
// No component imports needed here
</script>

<template>
  <div class="app-container">
    <div class="app-content">
      <router-view v-slot="{ Component }">
        <keep-alive :include="['MainScreen']">
          <component :is="Component" />
        </keep-alive>
      </router-view>
    </div>
  </div>
</template>

<style>
/* Global styles */
/* #f7f7f7 matches the page headers and the theme-color in index.html. Mobile browsers
   (Safari on iOS 26, among others) tint their own top bar from a sticky header or, failing
   that, from the page background, so this keeps browser bar + header one solid color. */
html,
body {
  background-color: #f7f7f7;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  margin: 0;
  padding: 0;
}

/* Desktop-optimized container with responsive max-width */
.app-container {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  background-color: #f7f7f7;
}

.app-content {
  width: 100%;
  max-width: 768px;
  background-color: white;
  box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
  position: relative;
}

/* On desktop, break out of the mobile max-width cap and fill the full screen */
@media (min-width: 1024px) {
  .app-container {
    justify-content: stretch;
  }
  .app-content {
    max-width: 100%;
    box-shadow: none;
  }
}
</style>