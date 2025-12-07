<template>
  <div class="sticky top-0 z-20 bg-white border-b border-gray-200 shadow-sm">
    <div class="flex flex-wrap items-center gap-1 md:gap-2 p-2 md:p-3">
      <!-- Text Formatting Group -->
      <div class="flex items-center gap-1 border-r border-gray-300 pr-2">
        <ToolbarButton
          @click="emit('format', 'bold')"
          title="Bold (Ctrl/Cmd+B)"
          :active="activeFormats.includes('bold')"
        >
          <BoldIcon />
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'italic')"
          title="Italic (Ctrl/Cmd+I)"
          :active="activeFormats.includes('italic')"
        >
          <ItalicIcon />
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'underline')"
          title="Underline (Ctrl/Cmd+U)"
          :active="activeFormats.includes('underline')"
        >
          <UnderlineIcon />
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'strikeThrough')"
          title="Strikethrough"
          :active="activeFormats.includes('strikeThrough')"
        >
          <StrikethroughIcon />
        </ToolbarButton>
      </div>

      <!-- Headings Group -->
      <div class="hidden md:flex items-center gap-1 border-r border-gray-300 pr-2">
        <ToolbarButton
          @click="emit('format', 'formatBlock', 'h1')"
          title="Heading 1"
        >
          <span class="font-bold text-sm">H1</span>
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'formatBlock', 'h2')"
          title="Heading 2"
        >
          <span class="font-bold text-sm">H2</span>
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'formatBlock', 'h3')"
          title="Heading 3"
        >
          <span class="font-bold text-sm">H3</span>
        </ToolbarButton>
      </div>

      <!-- Lists Group -->
      <div class="flex items-center gap-1 border-r border-gray-300 pr-2">
        <ToolbarButton
          @click="emit('format', 'insertUnorderedList')"
          title="Bullet List"
          :active="activeFormats.includes('insertUnorderedList')"
        >
          <BulletListIcon />
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'insertOrderedList')"
          title="Numbered List"
          :active="activeFormats.includes('insertOrderedList')"
        >
          <NumberedListIcon />
        </ToolbarButton>
      </div>

      <!-- Alignment Group (Desktop) -->
      <div class="hidden md:flex items-center gap-1 border-r border-gray-300 pr-2">
        <ToolbarButton
          @click="emit('format', 'justifyLeft')"
          title="Align Left"
        >
          <AlignLeftIcon />
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'justifyCenter')"
          title="Align Center"
        >
          <AlignCenterIcon />
        </ToolbarButton>
        <ToolbarButton
          @click="emit('format', 'justifyRight')"
          title="Align Right"
        >
          <AlignRightIcon />
        </ToolbarButton>
      </div>

      <!-- Insert Group -->
      <div class="flex items-center gap-1 border-r border-gray-300 pr-2">
        <ToolbarButton
          @click="emit('insertLink')"
          title="Insert Link (Ctrl/Cmd+K)"
        >
          <LinkIcon />
        </ToolbarButton>
        <ToolbarButton
          v-if="!isMobile"
          @click="emit('insertImage')"
          title="Insert Image"
        >
          <ImageIcon />
        </ToolbarButton>
        <ToolbarButton
          v-if="!isMobile"
          @click="emit('format', 'insertHorizontalRule')"
          title="Horizontal Rule"
        >
          <HorizontalRuleIcon />
        </ToolbarButton>
      </div>

      <!-- Advanced Group (Desktop) -->
      <div class="hidden md:flex items-center gap-1 border-r border-gray-300 pr-2">
        <ToolbarButton
          @click="emit('format', 'formatBlock', 'blockquote')"
          title="Block Quote"
        >
          <QuoteIcon />
        </ToolbarButton>
        <ToolbarButton
          @click="emit('insertCodeBlock')"
          title="Code Block"
        >
          <CodeIcon />
        </ToolbarButton>
      </div>

      <!-- Utility Group -->
      <div class="flex items-center gap-1">
        <ToolbarButton
          @click="emit('format', 'removeFormat')"
          title="Clear Formatting"
        >
          <ClearFormatIcon />
        </ToolbarButton>
        <ToolbarButton
          v-if="!isMobile"
          @click="emit('toggleDistraction')"
          title="Distraction-Free Mode (F11)"
        >
          <FullscreenIcon />
        </ToolbarButton>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, h, defineComponent } from 'vue';

const props = defineProps<{
  activeFormats?: string[];
  isMobile?: boolean;
}>();

const emit = defineEmits(['format', 'insertLink', 'insertImage', 'insertCodeBlock', 'toggleDistraction']);

// Toolbar Button Component
const ToolbarButton = defineComponent({
  props: {
    active: Boolean,
    disabled: Boolean
  },
  setup(props, { slots }) {
    return () => h('button', {
      type: 'button',
      class: [
        'p-2 rounded transition-colors',
        props.active ? 'bg-green-100 text-green-700' : 'hover:bg-gray-100',
        props.disabled ? 'opacity-50 cursor-not-allowed' : ''
      ],
      onMousedown: (e: MouseEvent) => e.preventDefault() // Prevent focus loss from editor
    }, slots.default?.());
  }
});

// Icon Components
const BoldIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M6 12h8a4 4 0 004-4 4 4 0 00-4-4H6v8zm0 0h9a4 4 0 014 4 4 4 0 01-4 4H6v-8z' })
]);

const ItalicIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M19 4h-9m4 0l-4 16m-5 0h9' })
]);

const UnderlineIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M6 4v8a6 6 0 0012 0V4M4 20h16' })
]);

const StrikethroughIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M3 12h18M9 5a4 4 0 004 4M9 19a4 4 0 004-4' })
]);

const BulletListIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 6h16M4 12h16M4 18h16' })
]);

const NumberedListIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5h12M9 12h12M9 19h12M5 5v2m0 5v2m0 5v2' })
]);

const LinkIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1' })
]);

const ImageIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z' })
]);

const HorizontalRuleIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 12h16' })
]);

const QuoteIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z' })
]);

const CodeIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4' })
]);

const AlignLeftIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 6h16M4 12h10M4 18h14' })
]);

const AlignCenterIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 6h16M7 12h10M5 18h14' })
]);

const AlignRightIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 6h16M10 12h10M6 18h14' })
]);

const ClearFormatIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M6 18L18 6M6 6l12 12' })
]);

const FullscreenIcon = () => h('svg', { xmlns: 'http://www.w3.org/2000/svg', class: 'w-5 h-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4' })
]);
</script>

<style scoped>
button:focus {
  outline: 2px solid #8cc65d;
  outline-offset: 2px;
}
</style>
