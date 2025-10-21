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
      const now = new Date();
      const isToday = date.toDateString() === now.toDateString();

      if (isToday) {
        return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
      } else {
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', hour12: true });
      }
    }

    function openImage(url: string) {
      window.open(url, '_blank');
    }

    return () => {
      const outerClass = `flex ${props.isCurrentUser ? 'justify-end' : 'justify-start'}`;
      const innerClass = `flex flex-col max-w-[260px] ${props.isCurrentUser ? 'items-end' : 'items-start'}`;
      const bubbleClass = `px-4 py-2 rounded-lg break-words ${props.isCurrentUser ? 'bg-green-600 text-white' : 'bg-gray-200 text-black'}`;

      const children = [];

      // Sender name (for other users)
      if (!props.isCurrentUser) {
        children.push(h('div', { class: 'text-xs text-gray-500 mb-1 font-semibold' }, props.message.senderName));
      }

      // Message bubble content
      const bubbleChildren = [];

      // Attachments
      if (props.message.attachments && props.message.attachments.length > 0) {
        const attachmentElements = props.message.attachments.map((attachment: any) => {
          if (attachment.type === 'image') {
            return h('img', {
              src: attachment.url,
              alt: attachment.filename || 'Image',
              class: 'rounded-lg max-w-full h-auto cursor-pointer mb-2',
              onClick: () => openImage(attachment.url)
            });
          } else {
            return h('a', {
              href: attachment.url,
              target: '_blank',
              class: `flex items-center gap-2 p-2 rounded-lg hover:opacity-80 mb-2 ${props.isCurrentUser ? 'bg-green-700' : 'bg-gray-300'}`
            }, [
              h('svg', {
                xmlns: 'http://www.w3.org/2000/svg',
                class: 'h-5 w-5',
                viewBox: '0 0 20 20',
                fill: 'currentColor'
              }, [
                h('path', {
                  'fill-rule': 'evenodd',
                  d: 'M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z',
                  'clip-rule': 'evenodd'
                })
              ]),
              h('span', { class: 'text-sm truncate' }, attachment.filename || 'File')
            ]);
          }
        });
        bubbleChildren.push(...attachmentElements);
      }

      // Message text
      if (props.message.text) {
        bubbleChildren.push(h('p', { class: 'text-sm whitespace-pre-wrap' }, props.message.text));
      }

      children.push(h('div', { class: bubbleClass }, bubbleChildren));

      // Timestamp
      children.push(h('div', { class: 'text-xs text-gray-500 mt-1' }, formatTime(props.message.timestamp)));

      return h('div', { class: outerClass }, [
        h('div', { class: innerClass }, children)
      ]);
    };
  }
});
