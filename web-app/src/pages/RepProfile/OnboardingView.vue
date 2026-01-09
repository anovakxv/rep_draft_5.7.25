<!--
  OnboardingView.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="min-h-screen bg-white flex flex-col">
    <!-- Step indicators -->
    <div class="flex justify-center py-4">
      <div class="flex space-x-2">
        <div class="w-3 h-3 rounded-full" :class="step === 0 ? '' : 'bg-gray-300'" :style="step === 0 ? 'background-color: #8cc65d;' : ''"></div>
        <div class="w-3 h-3 rounded-full" :class="step === 1 ? '' : 'bg-gray-300'" :style="step === 1 ? 'background-color: #8cc65d;' : ''"></div>
        <div v-if="!isEventRegistration" class="w-3 h-3 rounded-full" :class="step === 2 ? '' : 'bg-gray-300'" :style="step === 2 ? 'background-color: #8cc65d;' : ''"></div>
      </div>
    </div>

    <!-- Profile completion step -->
    <div v-if="step === 0" class="flex-1">
      <div class="max-w-lg mx-auto p-6">
        <h2 class="text-xl font-bold mb-4 text-center">Complete Your Profile</h2>
        <EditProfileComponent 
          :from-onboarding="true" 
          @profile-saved="onProfileSaved" 
        />
      </div>
    </div>

    <!-- Terms acceptance step -->
    <div v-else-if="step === 1" class="flex-1">
      <div class="max-w-lg mx-auto p-6">
        <h2 class="text-xl font-bold mb-4 text-center">Terms of Use</h2>
        <div class="overflow-y-auto max-h-[60vh] mb-6 border rounded bg-gray-50 p-4 text-sm whitespace-pre-line">
          {{ termsText }}
        </div>
        <button
          class="w-full py-3 text-white font-bold rounded-lg"
          style="background-color: #8cc65d;"
          @click="onTermsAccepted"
        >
          Accept Terms of Use
        </button>
      </div>
    </div>

    <!-- Walkthrough step -->
    <div v-else-if="step === 2" class="flex-1 flex flex-col">
      <div class="flex justify-between p-4">
        <button @click="skipWalkthrough" class="text-gray-500">Skip</button>
        <h2 class="font-bold">About Rep</h2>
        <div class="w-10"></div> <!-- Spacer for alignment -->
      </div>

      <div class="flex-1 flex flex-col items-center justify-center p-6 text-center">
        <img :src="REPLogo" alt="REP Logo" class="w-32 h-32 mb-8" />

        <h3 class="text-2xl font-bold mb-4">Welcome to Rep</h3>

        <p class="text-lg mb-12 max-w-2xl">
          Rep connects people with mentors and community opportunities based on shared values. Our software is designed to help communities better focus on the priorities that matter most. Start by viewing the list of Purposes and joining a Goal Team. Or create your own Purpose!
        </p>
      </div>

      <div class="p-6">
        <button
          class="w-full py-4 text-white font-bold rounded-lg"
          style="background-color: #8cc65d;"
          @click="completeOnboarding"
        >
          Rep Something.
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import EditProfileComponent from '@/components/EditProfileComponent.vue'
import REPLogo from '@/assets/REPLogo.png'

const router = useRouter()
const step = ref(0)
const isEventRegistration = ref(false)

// Terms of use content (could be moved to a separate file or fetched from API)
const termsText = `
Terms of Use:  
Version: 1.1
Effective Date: 7/30/2025
App Name: Rep 1
Developer: Networked Capital Inc.

Welcome to Rep. By continuing, you agree to the following community guidelines and terms:

1. Community Standards
Users must not post objectionable, offensive, or abusive content.
Hate speech, harassment, and explicit material are strictly prohibited.
Violators may have their content removed and accounts suspended or banned.

2. User Responsibilities
You are solely responsible for the content you share, create, or promote.
Impersonation, deception, or targeted harassment is not tolerated.

3. Moderation & Enforcement
Rep reserves the right to monitor, moderate, and remove content at its discretion.
Inappropriate content can be flagged by users and reviewed by our team.
Users can block others to prevent unwanted or abusive interactions.

4. Removal of Objectionable Content    
We will review flagged content and remove content that violates this policy within 24 hours of the content being flagged. Users who repeatedly violate our content policy will be ejected from the platform. 

5. Intellectual Property
Rep and its underlying software, design, content, trademarks, logos, and features are the exclusive property of Networked Capital Inc., unless otherwise noted.

6. Future Licensing
Certain components of Rep may, in the future, be released under an open-source license. However, until such licensing is explicitly announced and documented by Networked Capital Inc., all elements of the Rep software remain proprietary and fully protected under applicable intellectual property laws.

7. Agreement
By using Rep, you acknowledge and agree to uphold these standards.
For questions, contact us via our website at:  https://networkedcapital.co/contact/

Before proceeding, you must confirm acceptance of these terms.
`

// Check if we need to start at a specific step based on already completed steps
onMounted(() => {
  // Check if this is an event registration
  const rsvpIntentStr = localStorage.getItem('rsvpIntent')
  if (rsvpIntentStr) {
    try {
      const rsvpIntent = JSON.parse(rsvpIntentStr)
      if (rsvpIntent.isEventRegistration) {
        isEventRegistration.value = true
      }
    } catch (err) {
      console.error('Failed to parse rsvpIntent:', err)
    }
  }

  const hasCompletedProfile = localStorage.getItem('profileComplete') === 'true'
  const hasAcceptedTerms = localStorage.getItem('acceptedTermsOfUse') === 'true'

  if (hasCompletedProfile && hasAcceptedTerms) {
    step.value = 2 // Go directly to walkthrough
  } else if (hasCompletedProfile) {
    step.value = 1 // Go to terms
  }
  // Otherwise start at profile (step 0)
})

// Handler for profile completion
function onProfileSaved() {
  localStorage.setItem('profileComplete', 'true')
  step.value = 1
}

// Handler for terms acceptance
function onTermsAccepted() {
  localStorage.setItem('acceptedTermsOfUse', 'true')

  // Check if this is an event registration - if so, skip walkthrough
  const rsvpIntentStr = localStorage.getItem('rsvpIntent')
  if (rsvpIntentStr) {
    try {
      const rsvpIntent = JSON.parse(rsvpIntentStr)
      if (rsvpIntent.isEventRegistration) {
        // Skip walkthrough and complete onboarding immediately
        completeOnboarding()
        return
      }
    } catch (err) {
      console.error('Failed to parse rsvpIntent:', err)
    }
  }

  // Normal flow - go to walkthrough
  step.value = 2
}

// Skip the walkthrough and complete onboarding
function skipWalkthrough() {
  completeOnboarding()
}

// Complete onboarding and navigate to main app
function completeOnboarding() {
  // Mirror Swift app's onboarding completion logic
  const pendingUserId = localStorage.getItem('pendingUserId')
  if (pendingUserId) {
    localStorage.setItem('userId', pendingUserId)
    localStorage.removeItem('pendingUserId')
  }

  localStorage.setItem('isRegistered', 'true')
  localStorage.setItem('onboardingComplete', 'true')

  // Check for returnTo parameter (from public page redirect)
  // Using replace() instead of push() to remove onboarding from browser history
  const returnTo = localStorage.getItem('returnTo')
  if (returnTo) {
    localStorage.removeItem('returnTo')
    router.replace(returnTo)
  } else {
    // Navigate to main app
    router.replace('/main')
  }
}
</script>

<style scoped>
/* Add any custom styles here */
</style>