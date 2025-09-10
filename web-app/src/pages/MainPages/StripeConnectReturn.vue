<!--
  StripeConnectReturn.vue
  This page handles the redirect back from Stripe after onboarding.
-->
  
<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center text-center p-4">
    <div>
      <h1 class="text-2xl font-bold text-gray-800 mb-2">Stripe Connection Complete!</h1>
      <p class="text-gray-600 mb-4">You can now close this window and return to the Rep app.</p>
      <button @click="closeWindow" class="px-6 py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700">
        Close Window
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';

onMounted(() => {
  // Notify the main app window that the process is complete
  const channel = new BroadcastChannel('stripe_connect');
  channel.postMessage('completed');
  channel.close();
});

const closeWindow = () => {
  window.close();
};
</script>