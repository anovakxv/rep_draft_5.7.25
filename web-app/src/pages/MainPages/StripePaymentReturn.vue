<!--
  StripePaymentReturn.vue
  This page handles the redirect back from Stripe after a payment attempt.
-->
<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center text-center p-4">
    <div v-if="status === 'success'" class="max-w-md">
      <div class="mb-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-green-600 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h1 class="text-2xl font-bold text-gray-800 mb-2">Payment Successful!</h1>
      <p class="text-gray-600 mb-4">Thank you for your support. Redirecting you back...</p>
      <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full mx-auto"></div>
    </div>
    <div v-else class="max-w-md">
      <div class="mb-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-gray-600 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h1 class="text-2xl font-bold text-gray-800 mb-2">Payment Canceled</h1>
      <p class="text-gray-600 mb-4">Your payment was not completed. Redirecting you back...</p>
      <div class="animate-spin h-8 w-8 border-4 border-gray-600 border-t-transparent rounded-full mx-auto"></div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const route = useRoute();
const router = useRouter();
const status = ref<'success' | 'canceled'>('canceled');

onMounted(() => {
  const channel = new BroadcastChannel('stripe_payment');
  if (route.query.success === 'true') {
    status.value = 'success';
    channel.postMessage('completed');
  } else {
    status.value = 'canceled';
    channel.postMessage('canceled');
  }
  channel.close();

  // Redirect back to the goal page or main screen after a brief delay
  setTimeout(() => {
    const goalId = localStorage.getItem('lastPaymentGoalId');
    if (goalId) {
      // Clean up and return to the goal page
      localStorage.removeItem('lastPaymentGoalId');
      router.push(`/goal/${goalId}`);
    } else {
      // Return to main screen if no goal context
      router.push('/main');
    }
  }, 2000); // 2 second delay to show success/canceled message
});
</script>