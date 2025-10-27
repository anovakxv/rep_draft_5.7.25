//  TermsOfUse.vue
//  Rep
//
//  Created by Adam Novak on 09.09.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

<template>
  <div class="min-h-screen bg-white flex flex-col items-center justify-center">
    <div class="max-w-xl w-full p-6">
      <h2 class="text-2xl font-bold mb-4 text-center">Terms of Use</h2>
      <div class="overflow-y-auto max-h-[60vh] mb-6 border rounded bg-gray-50 p-4 text-sm whitespace-pre-line">
        {{ termsText }}
      </div>
      <button
        class="w-full py-3 text-white font-bold rounded-lg"
        style="background-color: #8cc65d;"
        @click="acceptTerms"
      >
        Accept Terms of Use
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
const router = useRouter()

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
Users are not permitted to modify, reverse-engineer, reproduce, distribute, or exploit any part of the app or its codebase without prior written consent.
All feedback, suggestions, or feature ideas submitted by users may be used by Networked Capital Inc. to improve Rep, with no obligation of compensation unless explicitly agreed upon.
Unauthorized use of Rep’s intellectual property may result in termination of service and legal action.

6. Future Licensing
Certain components of Rep may, in the future, be released under an open-source license. However, until such licensing is explicitly announced and documented by Networked Capital Inc., all elements of the Rep software remain proprietary and fully protected under applicable intellectual property laws. Future licensing decisions will not retroactively affect ownership rights, nor shall they be construed as a waiver of any current protections.

7. Agreement
By using Rep, you acknowledge and agree to uphold these standards.
For questions, contact us via our website at:  https://networkedcapital.co/contact/

Before proceeding, you must confirm acceptance of these terms.
`

function acceptTerms() {
  localStorage.setItem('acceptedTermsOfUse', 'true')
  router.push('/onboarding') // or main app route
}
</script>

<style scoped>
/* Add any custom styles if needed */
</style>