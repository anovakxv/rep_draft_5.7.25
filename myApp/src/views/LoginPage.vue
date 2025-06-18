import { useRouter } from 'vue-router';

<template>
  <ion-page>
    <ion-header>
      <ion-toolbar>
        <ion-title>Login</ion-title>
      </ion-toolbar>
    </ion-header>

    <ion-content class="ion-padding">
      <ion-input
        v-model="email"
        type="email"
        label="Email"
        placeholder="you@example.com"
        fill="outline"
        label-placement="floating"
      ></ion-input>

      <ion-input
        v-model="password"
        type="password"
        label="Password"
        placeholder="Enter your password"
        fill="outline"
        label-placement="floating"
        class="ion-margin-top"
      ></ion-input>

      <ion-button expand="block" class="ion-margin-top" @click="login">
        Log In
      </ion-button>
    </ion-content>
  </ion-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const email = ref('');
const password = ref('');

const router = useRouter();

function login() {
  // (You can add authentication logic here later)
  router.push('/main');
}

</script>
