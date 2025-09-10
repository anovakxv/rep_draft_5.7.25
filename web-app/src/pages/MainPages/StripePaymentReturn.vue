<!--
  StripePaymentReturn.vue
  This page handles the redirect back from Stripe after a payment attempt.
-->
<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center text-center p-4">
    <div v-if="status === 'success'">
      <h1 class="text-2xl font-bold text-gray-800 mb-2">Payment Successful!</h1>
      <p class="text-gray-600 mb-4">You can now close this window and return to the Rep app.</p>
      <button @click="closeWindow" class="px-6 py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700">
        Close Window
      </button>
    </div>
    <div v-else>
      <h1 class="text-2xl font-bold text-gray-800 mb-2">Payment Canceled</h1>
      <p class="text-gray-600 mb-4">Your payment was not completed. You can close this window and try again.</p>
      <button @click="closeWindow" class="px-6 py-2 bg-gray-600 text-white font-semibold rounded-lg hover:bg-gray-700">
        Close Window
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';

const route = useRoute();
const status = ref<'success' | 'canceled'>('canceled');

onMounted(() => {
  const channel = new BroadcastChannel('stripe_payment');
  if (route.query.success) {
    status.value = 'success';
    channel.postMessage('completed');
  } else {
    status.value = 'canceled';
    channel.postMessage('canceled');
  }
  channel.close();
});

const closeWindow = () => {
  window.close();
};
</script>