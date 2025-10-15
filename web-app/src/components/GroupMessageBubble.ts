import { defineComponent, h } from 'vue';

export default defineComponent({
  name: 'GroupMessageBubble',
  props: {
    message: { type: Object, required: true },
    isCurrentUser: { type: Boolean, required: true }
  },
  setup(props) {
    function formatTime(ts: string) {
      const date = new Date(ts);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    return () => {
      const outerClass = `flex ${props.isCurrentUser ? 'justify-end' : 'justify-start'}`;
      const innerClass = `flex flex-col max-w-[260px] ${props.isCurrentUser ? 'items-end' : 'items-start'}`;
      const bubbleClass = `px-4 py-2 rounded-lg break-words ${props.isCurrentUser ? 'bg-black text-green-400' : 'bg-gray-200 text-black'}`;
      const children = [];
      if (!props.isCurrentUser) {
        children.push(h('div', { class: 'text-xs text-gray-500 mb-1' }, props.message.senderName));
      }
      children.push(
        h('div', { class: bubbleClass }, props.message.text),
        h('div', { class: 'text-xs text-gray-500 mt-1' }, formatTime(props.message.timestamp))
      );
      return h('div', { class: outerClass }, [
        h('div', { class: innerClass }, children)
      ]);
    };
  }
});
