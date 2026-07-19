<!--
  StripePaymentReturn.vue
  This page handles the redirect back from Stripe after a payment attempt.
-->
<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center text-center p-4">
    <div v-if="status === 'success'" class="max-w-md w-full">
      <div class="mb-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-green-600 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h1 class="text-2xl font-bold text-gray-800 mb-2">Payment Successful!</h1>
      <p class="text-gray-600 mb-4">Thank you for your support.</p>
      <div v-if="!showButton" class="mb-4">
        <div class="animate-spin h-8 w-8 border-4 border-green-600 border-t-transparent rounded-full mx-auto"></div>
        <p class="text-sm text-gray-500 mt-2">Redirecting...</p>
      </div>
      <button
        v-if="showButton"
        @click="redirectBack"
        class="w-full py-3 bg-green-600 text-white font-bold rounded-lg hover:bg-green-700 transition-colors"
      >
        Return to Rep
      </button>
    </div>
    <div v-else class="max-w-md w-full">
      <div class="mb-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-gray-600 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h1 class="text-2xl font-bold text-gray-800 mb-2">Payment Canceled</h1>
      <p class="text-gray-600 mb-4">Your payment was not completed.</p>
      <div v-if="!showButton" class="mb-4">
        <div class="animate-spin h-8 w-8 border-4 border-gray-600 border-t-transparent rounded-full mx-auto"></div>
        <p class="text-sm text-gray-500 mt-2">Redirecting...</p>
      </div>
      <button
        v-if="showButton"
        @click="redirectBack"
        class="w-full py-3 bg-gray-600 text-white font-bold rounded-lg hover:bg-gray-700 transition-colors"
      >
        Return to Rep
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const route = useRoute();
const router = useRouter();
const status = ref<'success' | 'canceled'>('canceled');
const showButton = ref(false);

function redirectBack() {
  // Prefer the originating page (portal, goal, etc.) saved before Stripe redirect
  const returnUrl = localStorage.getItem('lastPaymentReturnUrl');
  localStorage.removeItem('lastPaymentReturnUrl');
  localStorage.removeItem('lastPaymentGoalId');
  localStorage.removeItem('lastCheckoutSessionId');

  if (returnUrl) {
    router.push(returnUrl);
  } else {
    router.push('/main');
  }
}

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

  // On success: wait 3s before redirecting — gives the Stripe webhook time to update
  // goal progress on the backend before the portal/goal page re-fetches on mount.
  // On cancel: redirect immediately.
  const delay = status.value === 'success' ? 3000 : 1500;
  setTimeout(() => {
    redirectBack();
  }, delay);

  // Show manual button as fallback if auto-redirect doesn't work
  setTimeout(() => {
    showButton.value = true;
  }, delay + 1000);
});
</script>