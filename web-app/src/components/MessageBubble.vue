<template>
  <div class="message-bubble">
    <slot />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'MessageBubble',
});
</script>

<style scoped>
.message-bubble {
  padding: 0.5rem 1rem;
  border-radius: 1rem;
  background: #f3f4f6;
  margin-bottom: 0.5rem;
}
</style>
