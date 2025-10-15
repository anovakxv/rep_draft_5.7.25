

<template>
  <div class="chat-group-page">
    <div v-for="msg in messages" :key="msg.id" class="mb-3">
      <GroupMessageBubble :message="msg" :isCurrentUser="msg.senderId === currentUserId" />
    </div>
    <EditGroupSheet
      v-if="showEditSheet"
      :chatId="chatId"
      :groupName="groupName"
      :groupMembers="groupMembers"
      :isCreator="isCreator"
      :currentUserId="currentUserId"
      @close="showEditSheet = false"
      @refresh="fetchGroupChat"
      @delete="handleDelete"
    />
    <div class="mt-2 flex gap-2 flex-wrap">
      <GroupMemberAvatar
        v-for="member in groupMembers"
        :key="member.id"
        :name="member.name"
        :photoURL="member.profilePicture"
        :size="36"
      />
      <template v-for="(name, id) in selectedMembersToAdd">
        <div v-if="!groupMembers.some(m => m.id === parseInt(id))" :key="id" class="flex items-center gap-2 bg-green-100 rounded px-2 py-1">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-500" viewBox="0 0 20 20" fill="currentColor">
            <path d="M8 9a3 3 0 100-6 3 3 0 000 6zm0 2a6 6 0 016 6H2a6 6 0 016-6zm8-4a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z" />
          </svg>
          <span class="text-xs text-green-700">{{ name }}</span>
        </div>
      </template>
    </div>
    <div class="flex justify-between mt-2">
      <button type="button" @click="showAddMembersSheet = true" class="text-green-600 text-sm flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
          <path d="M8 9a3 3 0 100-6 3 3 0 000 6zm0 2a6 6 0 016 6H2a6 6 0 016-6zm8-4a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z" />
        </svg>
        Add to Chat
      </button>
      <button v-if="groupMembers.length > 1" type="button" @click="showRemoveMembersSheet = true" class="text-red-600 text-sm flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" viewBox="0 0 20 20" fill="currentColor">
          <path d="M11 6a3 3 0 11-6 0 3 3 0 016 0zm3 11a6 6 0 00-12 0h12zm-1-9a1 1 0 00-2 0v2H9a1 1 0 000 2h2v2a1 1 0 002 0v-2h2a1 1 0 000-2h-2V8z" />
        </svg>
        Remove Member(s)
      </button>
    </div>
    <div class="space-y-3 mt-6">
      <button type="button" :disabled="isSaving" class="w-full py-3 bg-green-600 text-white font-bold rounded-lg text-lg flex items-center justify-center transition-colors disabled:opacity-60" @click="save">
        <span v-if="isSaving" class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-2"></span>
        Save Changes
      </button>
      <button v-if="isCreator" type="button" :disabled="isSaving" class="w-full py-3 bg-red-600 text-white font-bold rounded-lg text-lg flex items-center justify-center transition-colors disabled:opacity-60" @click="showDeleteAlert = true">
        Delete Group
      </button>
      <div v-if="errorMessage" class="text-red-600 bg-red-100 rounded-lg p-3 text-center text-sm">{{ errorMessage }}</div>
    </div>
    <NTWKUserPicker
      v-if="showAddMembersSheet"
      :chatId="chatId"
      :alreadySelected="[...groupMembers.map(m => m.id), ...Object.keys(selectedMembersToAdd).map(Number)]"
      @select="handleAddMembers"
      @cancel="showAddMembersSheet = false"
    />
    <RemoveMembersSheet
      v-if="showRemoveMembersSheet"
      :members="groupMembers"
      @remove="handleRemoveMember"
      @cancel="showRemoveMembersSheet = false"
    />
    <div v-if="showDeleteAlert" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
      <div class="bg-white rounded-lg p-6 max-w-sm mx-auto">
        <h3 class="font-bold text-lg mb-4">Delete Group Chat?</h3>
        <p class="mb-6">This action cannot be undone.</p>
        <div class="flex gap-4 justify-end">
          <button @click="showDeleteAlert = false" class="px-4 py-2 border rounded-lg">Cancel</button>
          <button @click="deleteChat" class="px-4 py-2 bg-red-600 text-white rounded-lg">Delete</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import GroupMemberAvatar from '../../components/GroupMemberAvatar';
import GroupMessageBubble from '../../components/GroupMessageBubble';
import GrowingTextarea from '../../components/GrowingTextarea';
import EditGroupSheet from '../../components/EditGroupSheet';
import NTWKUserPicker from '../../components/NTWKUserPicker';
import RemoveMembersSheet from '../../components/RemoveMembersSheet';

// Example state, replace with actual logic or props
const messages = ref([]);
const currentUserId = ref(1);
const showEditSheet = ref(false);
const chatId = ref(1);
const groupName = ref('Group Name');
const groupMembers = ref([]);
const isCreator = ref(false);
const selectedMembersToAdd = ref({});
const showAddMembersSheet = ref(false);
const showRemoveMembersSheet = ref(false);
const isSaving = ref(false);
const errorMessage = ref('');
const showDeleteAlert = ref(false);

function fetchGroupChat() {
  // Fetch logic here
}
function handleDelete() {
  // Delete logic here
}
function save() {
  // Save logic here
}
function handleAddMembers(users: any[]) {
  users.forEach(user => {
    selectedMembersToAdd.value[user.id] = user.fullName || 'User';
  });
  showAddMembersSheet.value = false;
}
function handleRemoveMember(member: any) {
  // Remove member logic here
  showRemoveMembersSheet.value = false;
}
function deleteChat() {
  // Delete chat logic here
  showDeleteAlert.value = false;
}
</script>