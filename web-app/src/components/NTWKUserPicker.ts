import { defineComponent, h, ref, onMounted } from 'vue';
import GroupMemberAvatar from './GroupMemberAvatar';

export default defineComponent({
  name: 'NTWKUserPicker',
  props: {
    chatId: { type: Number, required: true },
    alreadySelected: { type: Array, default: () => [] },
    onSelect: { type: Function, required: true },
    onCancel: { type: Function, required: true }
  },
  setup(props) {
    const users = ref([]);
    const isLoading = ref(false);
    const errorMessage = ref('');
    const selectedUsers = ref(new Set<number>());
    const token = localStorage.getItem('jwtToken');
    const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
    function fetchNTWKUsers() {
      isLoading.value = true;
      errorMessage.value = '';
      fetch(`${apiBaseUrl}/api/user/members_of_my_network?not_in_chats_id=${props.chatId}`, {
        headers: { Authorization: `Bearer ${token}` }
      })
        .then(res => res.json())
        .then(data => {
          if (data.result) users.value = data.result;
        })
        .catch(() => { errorMessage.value = 'Failed to load network users.'; })
        .finally(() => { isLoading.value = false; });
    }
    function toggleUser(userId: number) {
      if (selectedUsers.value.has(userId)) selectedUsers.value.delete(userId);
      else selectedUsers.value.add(userId);
    }
    function handleDone() {
      const selected = users.value.filter(u => selectedUsers.value.has(u.id));
      props.onSelect(selected);
    }
    onMounted(fetchNTWKUsers);
    return () => {
      // ...same h() conversion as previous step...
      return h('div', {}, 'NTWKUserPicker h() implementation here');
    };
  }
});
