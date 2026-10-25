<!--
  OnboardingView.vue
  Rep

  Created by Adam Novak on 09.09.2025
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<!--
  New-member sign-up: Register → Terms of Use (this page) → the app.
  The profile is edited later from the profile menu, and Rep Coach guides new members in the app.
-->

<template>
  <div class="min-h-screen bg-white flex flex-col">
    <div class="flex-1">
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
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

const safeReturnPath = (url: string | null | undefined): string => {
  if (!url) return '/main'
  return url.startsWith('/') && !url.startsWith('//') ? url : '/main'
}

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

function onTermsAccepted() {
  localStorage.setItem('acceptedTermsOfUse', 'true')
  completeOnboarding()
}

// Complete onboarding and go to the app, or back to the page the member came from
// (event RSVP, Portal 93 donation, public page) via returnTo
function completeOnboarding() {
  // Mirror Swift app's onboarding completion logic
  const pendingUserId = localStorage.getItem('pendingUserId')
  if (pendingUserId) {
    localStorage.setItem('userId', pendingUserId)
    localStorage.removeItem('pendingUserId')
  }

  localStorage.setItem('isRegistered', 'true')
  localStorage.setItem('onboardingComplete', 'true')

  // Using replace() instead of push() to remove onboarding from browser history
  const returnTo = localStorage.getItem('returnTo')
  localStorage.removeItem('returnTo')
  router.replace(safeReturnPath(returnTo))
}
</script>
