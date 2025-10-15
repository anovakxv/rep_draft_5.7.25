import { defineComponent, h } from 'vue';
import GroupMemberAvatar from './GroupMemberAvatar';

export default defineComponent({
  name: 'RemoveMembersSheet',
  props: {
    members: { type: Array, required: true },
    onRemove: { type: Function, required: true },
    onCancel: { type: Function, required: true }
  },
  setup(props) {
    return () => {
      const memberNodes = props.members.map((member) =>
        h('div', { key: member.id, class: 'p-4' }, [
          h('button', {
            onClick: () => props.onRemove(member),
            class: 'flex items-center w-full text-left text-red-600'
          }, [
            h(GroupMemberAvatar, { name: member.name, photoURL: member.profilePicture, size: 40 }),
            h('span', { class: 'ml-3' }, member.name)
          ])
        ])
      );
      return h('div', { class: 'fixed inset-0 bg-black bg-opacity-30 z-50' }, [
        h('div', { class: 'bg-white h-full max-w-md mx-auto flex flex-col' }, [
          h('div', { class: 'flex items-center justify-between p-4 border-b' }, [
            h('button', { onClick: props.onCancel, class: 'text-gray-600' }, 'Cancel'),
            h('h2', { class: 'font-bold' }, 'Remove Member(s)'),
            h('div', { class: 'w-14' })
          ]),
          h('div', { class: 'flex-1 overflow-y-auto divide-y' }, memberNodes)
        ])
      ]);
    };
  }
});
