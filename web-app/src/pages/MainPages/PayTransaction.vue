<!--
  PayTransaction.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
    <!-- Header -->
    <header class="flex items-center justify-between h-14 px-4 border-b bg-white shrink-0">
      <button @click="handleClose" class="text-green-600 p-2 -ml-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <h1 class="font-bold text-lg">{{ transactionType.title }}</h1>
      <button @click="handleClose" class="text-green-600 font-semibold">Cancel</button>
    </header>

    <div class="flex-1 overflow-y-auto">
      <div class="max-w-2xl mx-auto p-4 md:p-6 space-y-6">
        <!-- Header Section -->
        <div class="text-center space-y-2">
          <h2 class="text-2xl font-bold">{{ transactionType.title }} to {{ props.portalName }}</h2>
          <p v-if="props.goalName" class="text-lg font-medium text-gray-800">For: {{ props.goalName }}</p>
          <p class="text-base text-gray-500">{{ transactionType.subtitle }}</p>
        </div>

        <!-- Amount Entry -->
        <div class="space-y-2">
          <label class="font-semibold text-gray-800">{{ transactionType.amountLabel }}</label>
          <div class="flex items-center p-3 bg-gray-100 rounded-lg border border-gray-200 focus-within:border-green-500 focus-within:ring-1 focus-within:ring-green-500">
            <span class="text-xl font-semibold text-gray-500 mr-2">$</span>
            <input
              v-model="amount"
              @input="clearError"
              :disabled="isMonthlySubscription"
              type="number"
              min="1"
              step="0.01"
              class="flex-1 bg-transparent text-2xl font-medium w-full outline-none"
              placeholder="0.00"
            />
          </div>
          <!-- Quick Amounts -->
          <div v-if="!isMonthlySubscription" class="flex flex-wrap gap-2 pt-2">
            <button
              v-for="value in transactionType.quickAmounts"
              :key="value"
              @click="amount = value.toString()"
              class="px-4 py-1.5 bg-gray-200 text-gray-800 rounded-full font-semibold hover:bg-gray-300 transition-colors"
            >${{ value }}</button>
          </div>
        </div>

        <!-- Monthly Subscription -->
        <div class="space-y-3">
          <label class="flex items-center gap-3 cursor-pointer p-3 bg-gray-100 rounded-lg">
            <input type="checkbox" v-model="isMonthlySubscription" @change="handleSubscriptionToggle" class="h-5 w-5 rounded text-green-600 focus:ring-green-500" />
            <span class="font-semibold">Make this a monthly recurring payment</span>
          </label>
          <div v-if="isMonthlySubscription" class="space-y-2 pl-2">
            <label class="font-semibold text-gray-800">Choose your monthly amount:</label>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="option in monthlyPriceOptions"
                :key="option.priceId"
                @click="selectMonthly(option)"
                :class="selectedPriceId === option.priceId ? 'text-white' : 'bg-gray-200 text-gray-800 hover:bg-gray-300'"
                :style="selectedPriceId === option.priceId ? { backgroundColor: '#8cc65d' } : {}"
                class="px-4 py-1.5 rounded-full font-semibold transition-colors"
              >${{ option.amount }}/mo</button>
            </div>
          </div>
        </div>

        <!-- Email (for guest users only) -->
        <div v-if="!isAuthenticated" class="space-y-2">
          <label class="font-semibold text-gray-800">Email Address *</label>
          <input
            v-model="email"
            @input="clearError"
            type="email"
            required
            class="w-full p-3 bg-gray-100 border border-gray-200 rounded-lg outline-none focus:border-green-500 focus:ring-1 focus:ring-green-500"
            placeholder="your@email.com"
          />
          <p class="text-xs text-gray-500">Required to send your receipt</p>
        </div>

        <!-- Optional Message -->
        <div class="space-y-2">
          <label class="font-semibold text-gray-800">{{ transactionType.messageLabel }}</label>
          <textarea
            v-model="message"
            class="w-full p-3 bg-gray-100 border border-gray-200 rounded-lg h-28 outline-none focus:border-green-500 focus:ring-1 focus:ring-green-500"
            placeholder="Type your message here..."
          ></textarea>
        </div>

        <!-- Error Message -->
        <div v-if="paymentStatus.status === 'failed'" class="text-red-500 p-3 bg-red-50 rounded-lg text-center">{{ paymentStatus.message }}</div>

        <!-- Payment Button -->
        <div class="pt-2">
          <button
            @click="startPayment"
            :disabled="!canSubmit || paymentStatus.status === 'loading'"
            class="w-full py-3 text-white font-bold rounded-lg text-lg flex items-center justify-center transition-colors disabled:opacity-50"
            :style="{ backgroundColor: '#8cc65d' }"
          >
            <div v-if="paymentStatus.status === 'loading'" class="animate-spin h-5 w-5 mr-3 border-2 border-white border-t-transparent rounded-full"></div>
            <span>
              {{ isMonthlySubscription
                ? `Subscribe $${formattedAmount}/mo`
                : `${transactionType.ctaText} $${formattedAmount}` }}
            </span>
          </button>
        </div>

        <!-- Info Text -->
        <div class="text-center text-gray-500 text-xs space-y-1 px-4">
          <p>You'll be redirected to a secure payment page to complete your {{ isMonthlySubscription ? "subscription" : transactionType.title.toLowerCase() }}.</p>
          <p v-if="transactionType.key === 'donation'">Your donation may be tax deductible. A receipt will be emailed to you.</p>
        </div>
      </div>
    </div>

    <!-- Success Modal -->
    <div v-if="paymentStatus.status === 'success'" class="fixed inset-0 bg-black bg-opacity-60 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-lg p-6 max-w-sm w-full text-center">
        <h2 class="text-xl font-bold mb-2">{{ transactionType.receiptTitle }}</h2>
        <p class="text-gray-600 mb-6">{{ transactionType.receiptMessage }}</p>
        <button @click="closeSuccessModal" class="w-full py-2 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700">
          Done
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { isAuthenticated as checkAuth } from '@/utils/auth';

// --- Types and Constants ---
interface TransactionTypeConfig {
  key: string;
  title: string;
  subtitle: string;
  amountLabel: string;
  messageLabel: string;
  ctaText: string;
  receiptTitle: string;
  receiptMessage: string;
  quickAmounts: number[];
}

const transactionTypes: Record<string, TransactionTypeConfig> = {
  donation: {
    key: 'donation',
    title: 'Make a Donation',
    subtitle: 'Support this purpose with a one-time or monthly donation',
    amountLabel: 'Donation Amount',
    messageLabel: 'Message (Optional)',
    ctaText: 'Donate',
    receiptTitle: 'Thank You!',
    receiptMessage: 'Your donation has been received. A receipt has been sent to your email.',
    quickAmounts: [10, 20, 50, 100]  // Match iOS app
  },
  payment: {
    key: 'payment',
    title: 'Make a Payment',
    subtitle: 'Pay for services or products',
    amountLabel: 'Payment Amount',
    messageLabel: 'Note (Optional)',
    ctaText: 'Pay',
    receiptTitle: 'Payment Complete',
    receiptMessage: 'Your payment has been processed successfully.',
    quickAmounts: [10, 20, 50, 100]  // Match iOS app
  },
  purchase: {
    key: 'purchase',
    title: 'Complete Purchase',
    subtitle: 'Purchase items or services',
    amountLabel: 'Purchase Amount',
    messageLabel: 'Order Notes (Optional)',
    ctaText: 'Purchase',
    receiptTitle: 'Order Confirmed',
    receiptMessage: 'Your order has been confirmed. You will receive a confirmation email shortly.',
    quickAmounts: [10, 20, 50, 100]  // Match iOS app
  }
};

// Monthly subscription options - MUST match iOS app exactly (these are actual Stripe products)
const monthlyPriceOptions = [
  { amount: 5, priceId: 'price_1S8BJNLEcZxL3ukIiYVOMyHD' },   // $5/month
  { amount: 10, priceId: 'price_1S8BJeLEcZxL3ukI3fpsE25j' },  // $10/month
  { amount: 20, priceId: 'price_1S8BJuLEcZxL3ukIwJshQJp6' },  // $20/month
  { amount: 40, priceId: 'price_1S8BK9LEcZxL3ukISu3iPeLK' }   // $40/month
];

type PaymentStatus = { status: 'initial' | 'loading' | 'success' | 'failed'; message?: string };

// --- Props & Setup ---
const props = defineProps<{
  portalId: number;
  portalName: string;
  goalId?: number;
  goalName?: string;
  transactionType?: string;
}>();

const emit = defineEmits(['close']);

const typeKey = props.transactionType || 'donation';
const transactionType = transactionTypes[typeKey] || transactionTypes.donation;

const token = localStorage.getItem('jwtToken');
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

// --- State ---
const amount = ref('');
const email = ref('');
const message = ref('');
const paymentStatus = ref<PaymentStatus>({ status: 'initial' });
const isMonthlySubscription = ref(false);
const selectedPriceId = ref('');

// --- Computed ---
const isAuthenticated = computed(() => checkAuth());

const formattedAmount = computed(() => {
  const num = parseFloat(amount.value);
  return isNaN(num) ? '0.00' : num.toFixed(2);
});

const canSubmit = computed(() => {
  const num = parseFloat(amount.value);

  // Guest users must provide email
  if (!isAuthenticated.value && !email.value.includes('@')) {
    return false;
  }

  if (isMonthlySubscription.value) {
    return selectedPriceId.value !== '' && num >= 1;
  }
  return num >= 1;
});

// --- Methods ---
const handleClose = () => emit('close');
const clearError = () => { if (paymentStatus.value.status === 'failed') paymentStatus.value = { status: 'initial' }; };

const handleSubscriptionToggle = () => {
  clearError();
  if (!isMonthlySubscription.value) {
    selectedPriceId.value = '';
    amount.value = '';
  }
};

const selectMonthly = (option: { amount: number; priceId: string }) => {
  clearError();
  selectedPriceId.value = option.priceId;
  amount.value = option.amount.toString();
};

const startPayment = async () => {
  if (!canSubmit.value) {
    paymentStatus.value = { status: 'failed', message: isMonthlySubscription.value ? 'Please select a monthly amount.' : 'Please enter a valid amount (minimum $1.00)' };
    return;
  }
  paymentStatus.value = { status: 'loading' };

  try {
    const successUrl = `${window.location.origin}/stripe-payment-return?success=true`;
    const cancelUrl = `${window.location.origin}/stripe-payment-return?success=false`;

    const body: any = {
      portal_id: props.portalId,
      amount: parseFloat(amount.value) * 100, // Convert to cents
      currency: 'usd',
      transaction_type: transactionType.key,
      success_url: successUrl,
      cancel_url: cancelUrl,
      message: message.value
    };

    // Add email for guest users
    if (!isAuthenticated.value) {
      body.email = email.value;
    }

    if (props.goalId) {
      body.goal_id = props.goalId;
    }

    if (isMonthlySubscription.value && selectedPriceId.value) {
      body.is_subscription = true;
      body.price_id = selectedPriceId.value;
    }

    // Use public route for guest users, authenticated route for logged-in users
    const endpoint = isAuthenticated.value
      ? `${apiBaseUrl}/api/create_checkout_session`
      : `${apiBaseUrl}/api/public/create_checkout_session`;

    const headers: any = {
      'Content-Type': 'application/json'
    };

    // Only add Authorization header if authenticated
    if (isAuthenticated.value && token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    console.log('[PayTransaction] Sending payment request:', { endpoint, body });

    const res = await fetch(endpoint, {
      method: 'POST',
      headers,
      body: JSON.stringify(body)
    });

    const json = await res.json();
    console.log('[PayTransaction] Backend response:', { status: res.status, json });

    if (!res.ok) {
      const errorMessage = json.error || `Server responded with ${res.status}`;
      console.error('[PayTransaction] Payment failed:', errorMessage);
      throw new Error(errorMessage);
    }

    if (json.checkout_url) {
      if (json.session_id) localStorage.setItem('lastCheckoutSessionId', json.session_id);
      window.open(json.checkout_url, '_blank');
      paymentStatus.value = { status: 'initial' }; // Reset status after opening checkout
    } else {
      throw new Error("Failed to get checkout URL from server.");
    }
  } catch (err: any) {
    paymentStatus.value = { status: 'failed', message: err.message || "An unknown error occurred." };
  }
};

const checkPaymentStatus = async (sessionId: string) => {
  try {
    // Use public endpoint for guest users, authenticated endpoint for logged-in users
    const endpoint = isAuthenticated.value
      ? `${apiBaseUrl}/api/checkout_session_status?session_id=${sessionId}`
      : `${apiBaseUrl}/api/public/checkout_session_status?session_id=${sessionId}`;

    const headers: any = {};
    if (isAuthenticated.value && token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(endpoint, { headers });
    if (!res.ok) throw new Error('Could not verify payment status.');
    const json = await res.json();
    if (json.payment_status === "paid") {
      paymentStatus.value = { status: 'success' };
    } else {
      paymentStatus.value = { status: 'failed', message: "Payment was not completed." };
    }
  } catch (err: any) {
    paymentStatus.value = { status: 'failed', message: err.message };
  } finally {
    localStorage.removeItem('lastCheckoutSessionId');
  }
};

const closeSuccessModal = () => {
  paymentStatus.value = { status: 'initial' };
  emit('close');
};

// --- Lifecycle & Event Handling ---
let channel: BroadcastChannel | null = null;

onMounted(() => {
  channel = new BroadcastChannel('stripe_payment');
  channel.onmessage = (event) => {
    const sessionId = localStorage.getItem('lastCheckoutSessionId');
    if (event.data === 'completed' && sessionId) {
      checkPaymentStatus(sessionId);
    } else if (event.data === 'canceled') {
      paymentStatus.value = { status: 'initial' };
    }
  };
});

onUnmounted(() => {
  if (channel) channel.close();
});
</script>