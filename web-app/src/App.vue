<script setup lang="ts">
// No component imports needed here
</script>

<template>
  <div class="app-container">
    <div class="app-content">
      <router-view />
    </div>
  </div>
</template>

<style>
/* Global styles */
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  margin: 0;
  padding: 0;
  background-color: #e5e5e5; /* Gray background for sidebars */
}

/* Desktop-optimized container with responsive max-width */
.app-container {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  background-color: #e5e5e5;
}

.app-content {
  width: 100%;
  max-width: 768px; /* Mobile and tablet default */
  background-color: white;
  box-shadow: 0 0 20px rgba(0, 0, 0, 0.1); /* Subtle shadow for depth */
  position: relative;
}

/* Desktop: Wider layout for messaging and content-heavy pages */
@media (min-width: 1024px) {
  .app-content {
    max-width: 900px; /* Wider on desktop for better readability */
  }
}

/* Large Desktop: Even wider for immersive experience */
@media (min-width: 1440px) {
  .app-content {
    max-width: 1000px;
  }
}
</style>