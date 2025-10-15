import { defineComponent, h, ref, onMounted } from 'vue';

export default defineComponent({
  name: 'GrowingTextarea',
  props: {
    modelValue: { type: String, required: true }
  },
  emits: ['update:modelValue', 'keydown'],
  setup(props, { emit }) {
    const textarea = ref<HTMLTextAreaElement | null>(null);
    function resize() {
      if (textarea.value) {
        textarea.value.style.height = 'auto';
        textarea.value.style.height = Math.min(textarea.value.scrollHeight, 144) + 'px';
      }
    }
    onMounted(resize);
    return () => h('textarea', {
      ref: textarea,
      value: props.modelValue,
      rows: 1,
      class: 'flex-1 resize-none rounded-lg border border-gray-300 p-2 focus:ring-green-500 focus:border-green-500',
      placeholder: 'Type a message...',
      maxlength: '1000',
      'aria-label': 'Type a message',
      onInput: e => {
        emit('update:modelValue', (e.target as HTMLTextAreaElement).value);
        resize();
      },
      onKeydown: e => emit('keydown', e)
    });
  }
});
