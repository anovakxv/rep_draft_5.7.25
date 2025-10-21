<!--
  Payments.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-white flex flex-col">
    <!-- Header -->
    <div class="header sticky top-0 bg-white z-10 flex items-center justify-between px-4 py-3 border-b border-gray-200">
      <button @click="goBack" class="text-green-600 text-lg font-semibold">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h1 class="text-xl font-bold">Payments & Subscriptions</h1>
      <div class="w-6"></div>
    </div>

    <div class="max-w-2xl mx-auto w-full p-6">
      <div v-if="isLoading" class="flex items-center justify-center py-12">
        <span class="text-lg font-semibold">Loading...</span>
      </div>
      <div v-else>
        <!-- Active Subscriptions Section -->
        <section class="mb-10">
          <h3 class="text-xl font-semibold mb-4">Active Subscriptions</h3>
          <div v-if="subscriptions.length === 0" class="bg-gray-100 p-4 rounded text-gray-500 text-center">
            You have no active monthly subscriptions.
          </div>
          <div v-else>
            <div v-for="sub in subscriptions" :key="sub.id" class="mb-4">
              <SubscriptionRow
                :subscription="sub"
                @cancel="confirmCancel(sub)"
              />
            </div>
          </div>
        </section>

        <!-- Payment History Section -->
        <section>
          <h3 class="text-xl font-semibold mb-4">Payment History</h3>
          <div v-if="history.length === 0" class="bg-gray-100 p-4 rounded text-gray-500 text-center">
            Your payment history will appear here.
          </div>
          <div v-else>
            <div v-for="item in history" :key="item.id">
              <TransactionHistoryRow :item="item" />
            </div>
          </div>
        </section>
      </div>
    </div>

    <!-- Cancel Subscription Modal -->
    <div v-if="showCancelModal" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h3 class="text-xl font-bold mb-4">Cancel Subscription?</h3>
        <p class="mb-4">
          Are you sure you want to cancel your
          <span class="font-semibold">{{ subscriptionToCancel?.formattedAmount }}/month</span>
          subscription to <span class="font-semibold">{{ subscriptionToCancel?.name }}</span>? This cannot be undone.
        </p>
        <div class="flex space-x-4">
          <button @click="cancelSubscription" class="bg-red-600 text-white px-4 py-2 rounded font-bold flex-1">Cancel Subscription</button>
          <button @click="showCancelModal = false" class="bg-gray-200 text-gray-700 px-4 py-2 rounded flex-1">Keep Subscription</button>
        </div>
      </div>
    </div>

    <!-- Error Alert Modal -->
    <div v-if="errorMessage" class="fixed inset-0 flex items-center justify-center z-50">
      <div class="bg-white p-4 rounded-lg shadow-lg max-w-md w-full">
        <h3 class="font-bold text-lg mb-2">Error</h3>
        <p class="mb-4">{{ errorMessage }}</p>
        <button @click="errorMessage = ''" class="w-full py-2 bg-green-600 text-white rounded">OK</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const router = useRouter()

// --- Data Models ---
interface ActiveSubscriptionItem {
  id: string // Stripe Subscription ID
  name: string // Portal Name or Goal Name
  amount: number // Amount in cents
  nextBillingDate: number // Unix timestamp
  formattedAmount?: string
  formattedNextBillingDate?: string
}

interface TransactionHistoryItem {
  id: string // Stripe Payment Intent ID
  description: string
  amount: number // Amount in cents
  date: number // Unix timestamp
  formattedAmount?: string
  formattedDate?: string
}

// --- State ---
const subscriptions = ref<ActiveSubscriptionItem[]>([])
const history = ref<TransactionHistoryItem[]>([])
const isLoading = ref(true)
const errorMessage = ref('')
const showCancelModal = ref(false)
const subscriptionToCancel = ref<ActiveSubscriptionItem | null>(null)

const token = localStorage.getItem('jwtToken')
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL

// --- Formatters ---
function formatAmount(amount: number): string {
  return `$${(amount / 100).toFixed(2)}`
}
function formatDate(ts: number): string {
  const d = new Date(ts * 1000)
  return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

// --- Fetch Data ---
async function loadPaymentData() {
  isLoading.value = true
  try {
    const [subsRes, histRes] = await Promise.all([
      axios.get(`${apiBaseUrl}/api/subscriptions`, { headers: { Authorization: `Bearer ${token}` } }),
      axios.get(`${apiBaseUrl}/api/payment_history`, { headers: { Authorization: `Bearer ${token}` } })
    ])
    subscriptions.value = (subsRes.data as ActiveSubscriptionItem[]).map(sub => ({
      ...sub,
      formattedAmount: formatAmount(sub.amount),
      formattedNextBillingDate: formatDate(sub.nextBillingDate)
    }))
    history.value = (histRes.data as TransactionHistoryItem[]).map(item => ({
      ...item,
      formattedAmount: formatAmount(item.amount),
      formattedDate: formatDate(item.date)
    }))
  } catch (err: any) {
    errorMessage.value = err.response?.data?.error || err.message || 'Network error. Please try again.'
  } finally {
    isLoading.value = false
  }
}

// --- Cancel Subscription ---
function confirmCancel(sub: ActiveSubscriptionItem) {
  subscriptionToCancel.value = sub
  showCancelModal.value = true
}

async function cancelSubscription() {
  if (!subscriptionToCancel.value) return
  isLoading.value = true
  showCancelModal.value = false
  try {
    await axios.post(
      `${apiBaseUrl}/api/cancel_subscription`,
      { subscriptionId: subscriptionToCancel.value.id },
      { headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` } }
    )
    subscriptions.value = subscriptions.value.filter(sub => sub.id !== subscriptionToCancel.value?.id)
    subscriptionToCancel.value = null
  } catch (err: any) {
    errorMessage.value = err.response?.data?.error || err.message || 'Failed to cancel subscription. Please try again.'
  } finally {
    isLoading.value = false
  }
}

function goBack() {
  router.back()
}

onMounted(loadPaymentData)
</script>

<!-- --- Subscription Row Component --- -->
<script lang="ts">
import { defineComponent, PropType } from 'vue'
export default defineComponent({
  name: 'SubscriptionRow',
  props: {
    subscription: {
      type: Object as PropType<{
        id: string
        name: string
        formattedAmount: string
        formattedNextBillingDate: string
      }>,
      required: true
    }
  },
  emits: ['cancel'],
  setup(props, { emit }) {
    return () => (
      <div class="p-4 bg-gray-100 rounded">
        <div class="flex justify-between items-center mb-1">
          <span class="font-semibold">{props.subscription.name}</span>
          <span class="font-bold text-green-700">{props.subscription.formattedAmount}/mo</span>
        </div>
        <div class="text-sm text-gray-500 mb-2">
          Next payment on {props.subscription.formattedNextBillingDate}
        </div>
        <button
          class="text-red-600 text-sm underline"
          onClick={() => emit('cancel')}
        >
          Cancel Subscription
        </button>
      </div>
    )
  }
})
</script>

<!-- --- Transaction History Row Component --- -->
<script lang="ts">
import { defineComponent, PropType } from 'vue'
export default defineComponent({
  name: 'TransactionHistoryRow',
  props: {
    item: {
      type: Object as PropType<{
        description: string
        formattedDate: string
        formattedAmount: string
      }>,
      required: true
    }
  },
  setup(props) {
    return () => (
      <div class="flex justify-between items-center py-2">
        <div>
          <div class="font-medium">{props.item.description}</div>
          <div class="text-xs text-gray-500">{props.item.formattedDate}</div>
        </div>
        <div class="font-semibold">{props.item.formattedAmount}</div>
      </div>
    )
  }
})
</script>

<style scoped>
/* Add any custom styles here if needed */
</style>