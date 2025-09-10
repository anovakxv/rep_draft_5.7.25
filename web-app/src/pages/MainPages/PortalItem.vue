<!--
  PortalItem.vue
  Rep
  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
-->

<template>
  <div class="portal-item flex items-start space-x-4 px-4 py-3 bg-white rounded-xl relative" :style="{ height: cardHeight + 'px' }">
    <!-- Image or Placeholder -->
    <div class="flex-shrink-0">
      <img
        v-if="portal.mainImageUrl"
        :src="portal.mainImageUrl"
        :alt="portal.name"
        class="rounded"
        :style="{ width: imageWidth + 'px', height: imageHeight + 'px', objectFit: 'cover' }"
      />
      <div
        v-else
        class="bg-gray-200 rounded"
        :style="{ width: imageWidth + 'px', height: imageHeight + 'px' }"
      ></div>
    </div>

    <!-- Portal Info -->
    <div class="flex flex-col flex-1 space-y-1">
      <div class="font-semibold text-lg text-gray-900 leading-tight line-clamp-2">
        {{ portal.name }}
      </div>
      <div v-if="portal.categories_id" class="text-xs text-gray-500">
        Category {{ portal.categories_id }}
      </div>
      <div v-if="portal.subtitle" class="text-base text-gray-500 leading-tight line-clamp-2">
        {{ portal.subtitle }}
      </div>
      <div class="flex items-center text-xs mt-1">
        <span v-if="portal.cities_id" class="text-gray-500">City {{ portal.cities_id }}</span>
        <span class="flex-1"></span>
        <span v-if="portal._c_users_count" class="text-green-600">{{ portal._c_users_count }} leads</span>
      </div>
    </div>

    <!-- Bottom Divider -->
    <div class="absolute left-0 right-0 bottom-0 h-px bg-gray-200"></div>
  </div>
</template>

<script setup lang="ts">
// Props
interface Portal {
  id: number;
  name: string;
  mainImageUrl?: string;
  categories_id?: number;
  subtitle?: string;
  cities_id?: number;
  _c_users_count?: number;
}

defineProps<{ portal: Portal }>();

// Card dimensions (matches SwiftUI)
const imageWidth = 144;
const imageHeight = Math.round(144 * 9 / 16); // 81
const cardHeight = imageHeight + 24;
</script>

<style scoped>
.portal-item {
  /* Matches SwiftUI card style */
  box-shadow: 0 1px 2px rgba(0,0,0,0.03);
}
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>