import { defineComponent, h } from 'vue';

export default defineComponent({
  name: 'GroupMemberAvatar',
  props: {
    name: { type: String, required: true },
    photoURL: { type: String, default: null },
    size: { type: Number, default: 36 }
  },
  setup(props) {
    function initials(name: string): string {
      const comps = name.split(' ');
      const first = comps[0]?.[0] || '';
      const last = comps[1]?.[0] || '';
      return (first + last).toUpperCase();
    }
    const avatarStyle = { width: `${props.size}px`, height: `${props.size}px` };
    return () => {
      if (props.photoURL) {
        const src = props.photoURL.startsWith('http') ? props.photoURL : `https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/${props.photoURL}`;
        return h('div', { style: avatarStyle, class: 'relative' }, [
          h('img', { src, class: 'rounded-full object-cover w-full h-full' })
        ]);
      } else {
        return h('div', { style: avatarStyle, class: 'relative' }, [
          h('div', { class: 'rounded-full bg-gray-300 w-full h-full flex items-center justify-center text-xs font-semibold text-white' }, initials(props.name))
        ]);
      }
    };
  }
});
