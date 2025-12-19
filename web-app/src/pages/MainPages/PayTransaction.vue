<!--
  PayTransaction.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="h-screen bg-gray-50 flex justify-center overflow-hidden">
    <div class="w-full max-w-3xl flex flex-col">
      <!-- Header -->
      <header class="flex items-center justify-between h-14 px-4 border-b border-gray-200 shrink-0" style="background-color: #f7f7f7">
        <button @click="handleClose" class="p-2 -ml-2" style="color: #8cc65d">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
        </button>
        <h1 class="font-bold text-lg">{{ transactionType.title }}</h1>
        <button @click="handleClose" class="font-semibold" style="color: #8cc65d">Cancel</button>
      </header>

      <!-- Main Content -->
      <div class="flex-1 overflow-y-auto overflow-x-hidden">
        <div class="p-4 md:p-6 pb-20 space-y-6">
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

    <!-- Donation Disclosure Modal -->
    <div v-if="showDonationDisclosure" class="fixed inset-0 bg-black bg-opacity-60 z-50 overflow-y-auto">
      <div class="min-h-screen flex items-center justify-center p-4">
        <div class="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
          <!-- Header -->
          <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
            <button @click="showDonationDisclosure = false" class="text-rep-green font-semibold">
              Cancel
            </button>
            <h2 class="text-lg font-bold">Donation Disclosure</h2>
            <div class="w-16"></div> <!-- Spacer -->
          </div>

          <!-- Content -->
          <div class="px-6 py-6 space-y-6">
            <!-- Header -->
            <div class="space-y-2">
              <h3 class="text-2xl font-bold" style="color: #006600;">Donation Information</h3>
              <p class="text-gray-600">Please read this important information before proceeding with your donation.</p>
            </div>

            <div class="border-t border-gray-200"></div>

            <!-- Recipient Information -->
            <div class="space-y-3">
              <p class="text-base">You are about to make a donation to:</p>
              <div class="bg-gray-100 p-4 rounded-lg">
                <p class="text-xl font-bold" style="color: #006600;">{{ props.portalName }}</p>
                <p class="text-gray-600 mt-1">For: {{ props.goalName }}</p>
              </div>
            </div>

            <!-- Tax Deductibility Warning -->
            <div class="border-2 border-orange-500 bg-orange-50 p-4 rounded-lg space-y-3">
              <div class="flex items-start gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-orange-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <div class="space-y-2">
                  <h4 class="font-bold text-gray-900">Tax Deductibility Status</h4>
                  <p class="text-sm">Rep does not verify the tax-exempt status of organizations on this platform. This donation may not be tax-deductible.</p>
                  <p class="text-sm font-semibold">Please consult your tax advisor to determine if this donation qualifies for a tax deduction.</p>
                </div>
              </div>
            </div>

            <!-- Payment Processing Information -->
            <div class="bg-gray-100 p-4 rounded-lg space-y-2">
              <h4 class="font-bold">Payment Processing</h4>
              <p class="text-sm text-gray-600">Your donation will be processed securely through Stripe. You will be redirected to complete your donation.</p>
            </div>

            <!-- Action Buttons -->
            <div class="space-y-3 pt-4">
              <button
                @click="() => { donationDisclosureAccepted = true; showDonationDisclosure = false; startPayment(); }"
                class="w-full py-3 text-white font-bold rounded-lg"
                style="background-color: #006600;"
              >
                I Understand - Continue to Donation
              </button>
              <button
                @click="() => { showDonationDisclosure = false; donationDisclosureAccepted = false; }"
                class="w-full py-3 bg-gray-200 text-gray-800 font-semibold rounded-lg"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
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

const emit = defineEmits(['close', 'payment-success']);

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
const showDonationDisclosure = ref(false);
const donationDisclosureAccepted = ref(false);

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

  // CRITICAL: For donations, show disclosure FIRST
  if (transactionType.key === 'donation' && !donationDisclosureAccepted.value) {
    showDonationDisclosure.value = true;
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
      if (json.session_id) {
        localStorage.setItem('lastCheckoutSessionId', json.session_id);
        // Store goal ID for refreshing after payment
        if (props.goalId) localStorage.setItem('lastPaymentGoalId', props.goalId.toString());
      }
      // Redirect to Stripe checkout in same window (works on mobile unlike window.open)
      window.location.href = json.checkout_url;
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

  // Clean up localStorage
  localStorage.removeItem('lastCheckoutSessionId');
  localStorage.removeItem('lastPaymentGoalId');

  // Emit payment-success event so GoalsDetailView can refresh
  emit('payment-success');
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