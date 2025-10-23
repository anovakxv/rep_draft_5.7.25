<!--
  PortalPaymentSetup.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
    <!-- Header -->
    <header class="flex items-center justify-between h-14 px-4 border-b shrink-0" style="background-color: #f7f7f7">
      <button @click="goBack" class="p-2 -ml-2" style="color: #8cc65d">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <h1 class="font-bold text-lg">Payment Setup</h1>
      <div class="w-10"></div> <!-- Spacer -->
    </header>

    <!-- Main Content -->
    <div class="flex-1 overflow-y-auto p-4 md:p-6">
      <div class="max-w-2xl mx-auto space-y-6">
        <!-- Header -->
        <div class="text-left">
          <h2 class="text-2xl font-bold">Payment Settings</h2>
          <p class="text-base text-gray-500 mt-1">Set up your portal to receive payments</p>
        </div>

        <!-- Status Card -->
        <div class="p-5 rounded-xl bg-white border">
          <div class="flex items-center mb-3">
            <span v-if="isConnected" class="text-green-500 mr-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.707a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
            </span>
            <span v-else class="text-orange-500 mr-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10A8 8 0 11 2 10a8 8 0 0116 0zm-8 4a1 1 0 100-2 1 1 0 000 2zm-.707-7.707a1 1 0 011.414 0l.293.293.293-.293a1 1 0 111.414 1.414l-.293.293.293.293a1 1 0 01-1.414 1.414l-.293-.293-.293.293a1 1 0 01-1.414-1.414l.293-.293-.293-.293a1 1 0 010-1.414z" clip-rule="evenodd"/></svg>
            </span>
            <span class="font-semibold text-lg">
              {{ isConnected ? "Connected to Stripe" : "Not Connected to Stripe" }}
            </span>
          </div>
          <p class="text-gray-600 text-sm mb-4">
            {{ isConnected
              ? "Your portal is connected to Stripe and can receive payments. You can manage your account through the Stripe Dashboard."
              : "Connect your portal to Stripe to receive donations, payments, and purchases from users." }}
          </p>
          <div>
            <button
              v-if="isConnected"
              @click="getStripeDashboardLink"
              class="w-full py-3 bg-gray-100 rounded-lg flex items-center justify-center font-semibold text-gray-800 hover:bg-gray-200 transition-colors"
              :disabled="isLoading"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" /></svg>
              Go to Stripe Dashboard
            </button>
            <button
              v-else
              @click="createConnectAccount"
              class="w-full py-3 rounded-lg flex items-center justify-center font-semibold text-white transition-colors"
              style="background-color: #8cc65d;"
              :disabled="isLoading"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" /></svg>
              Connect to Stripe
            </button>
          </div>
        </div>

        <!-- Payment Info Section -->
        <div class="p-5 rounded-xl bg-white border space-y-4">
          <h3 class="font-semibold text-lg">About Payments</h3>
          <InfoRow icon="creditcard" title="Secure Payments" description="All payments are securely processed by Stripe, a PCI-compliant payment processor." />
          <InfoRow icon="dollarsign" title="Transaction Fee" description="Rep does not charge any additional platform fee. Stripe’s standard rates apply. For example: 2.9% + 30¢ per successful transaction for domestic cards, 0.8% for ACH Direct Debit. For full details, see stripe.com/pricing." />
          <InfoRow icon="calendar" title="Payouts" description="Funds will be directly deposited to your bank account based on your Stripe payout schedule." />
          <InfoRow icon="document" title="Tax Information" description="You'll need to provide tax information in your Stripe account to receive payments." />
        </div>

        <!-- Error Message -->
        <div v-if="errorMessage" class="text-red-500 p-3 bg-red-50 rounded-lg">{{ errorMessage }}</div>
      </div>
    </div>

    <!-- Loading Overlay -->
    <div v-if="isLoading" class="fixed inset-0 bg-white bg-opacity-75 z-50 flex items-center justify-center">
      <div class="animate-spin h-10 w-10 border-4 border-green-600 border-t-transparent rounded-full"></div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, defineComponent, h } from 'vue';
import { useRoute, useRouter } from 'vue-router';

// --- InfoRow Component with SVGs ---
const InfoRow = defineComponent({
  props: {
    icon: { type: String, required: true },
    title: { type: String, required: true },
    description: { type: String, required: true },
  },
  setup(props) {
    const icons: Record<string, string> = {
      creditcard: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />`,
      dollarsign: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v.01" />`,
      calendar: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />`,
      document: `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />`,
    };
    return () => h('div', { class: 'flex items-start' }, [
      h('div', { class: 'w-6 h-6 mr-4 text-gray-500 flex-shrink-0' }, [
        h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'h-6 w-6', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', innerHTML: icons[props.icon] || '' })
      ]),
      h('div', [
        h('div', { class: 'font-medium text-gray-800' }, props.title),
        h('div', { class: 'text-sm text-gray-500 whitespace-pre-line' }, props.description),
      ])
    ]);
  }
});

// --- Props & Setup ---
const route = useRoute();
const router = useRouter();
const portalId = Number(route.params.id);

const token = localStorage.getItem('jwtToken');
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

// --- State ---
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);
const isConnected = ref(false);
const accountId = ref<string | null>(null);

// --- Methods ---
const goBack = () => router.back();

const checkConnectionStatus = async () => {
  isLoading.value = true;
  errorMessage.value = null;
  try {
    const res = await fetch(`${apiBaseUrl}/api/portal/payment_status?portal_id=${portalId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) throw new Error(`Server responded with ${res.status}`);
    const json = await res.json();
    if (json.stripe_account_id && json.stripe_account_id.length > 0) {
      isConnected.value = true;
      accountId.value = json.stripe_account_id;
    } else {
      isConnected.value = false;
      accountId.value = null;
    }
  } catch (err: any) {
    errorMessage.value = "Error checking payment status: " + (err.message || "Unknown error");
  } finally {
    isLoading.value = false;
  }
};

const createConnectAccount = async () => {
  isLoading.value = true;
  errorMessage.value = null;
  try {
    const redirectURL = `${window.location.origin}/stripe-connect-return?portal_id=${portalId}`;
    const res = await fetch(`${apiBaseUrl}/api/create_connect_account`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ portal_id: portalId, redirect_url: redirectURL }),
    });
    if (!res.ok) throw new Error(`Server responded with ${res.status}`);
    const json = await res.json();
    if (json.url) {
      // Open in a new tab for better user experience than an iframe
      window.open(json.url, '_blank');
      if (json.account_id) accountId.value = json.account_id;
    } else {
      throw new Error("Invalid response from server");
    }
  } catch (err: any) {
    errorMessage.value = "Error creating account: " + (err.message || "Unknown error");
  } finally {
    isLoading.value = false;
  }
};

const getStripeDashboardLink = async () => {
  if (!accountId.value) {
    errorMessage.value = "No Stripe account found";
    return;
  }
  isLoading.value = true;
  errorMessage.value = null;
  try {
    const res = await fetch(`${apiBaseUrl}/api/stripe_dashboard_link`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ account_id: accountId.value }),
    });
    if (!res.ok) throw new Error(`Server responded with ${res.status}`);
    const json = await res.json();
    if (json.url) {
      // Open in a new tab
      window.open(json.url, '_blank');
    } else {
      throw new Error("Invalid response from server");
    }
  } catch (err: any) {
    errorMessage.value = "Error getting dashboard link: " + (err.message || "Unknown error");
  } finally {
    isLoading.value = false;
  }
};

// --- Lifecycle & Event Handling (Web equivalent of NotificationCenter) ---
let channel: BroadcastChannel | null = null;

onMounted(() => {
  if (!token) {
    router.push('/login');
    return;
  }
  checkConnectionStatus();

  // Listen for completion message from the redirect page
  channel = new BroadcastChannel('stripe_connect');
  channel.onmessage = (event) => {
    if (event.data === 'completed') {
      console.log('Stripe connect completed, refreshing status...');
      checkConnectionStatus();
    }
  };
});

onUnmounted(() => {
  // Clean up the channel
  if (channel) {
    channel.close();
  }
});
</script>