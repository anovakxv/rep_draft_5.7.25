// src/pages/utils/goalTeamChat.ts
// Open (or create) a Goal Team's group chat. Members only, mirroring GoalsDetailView:
// the team is checked first, and a chat is created and linked to the goal if it has none.
// Resolves with the chat to open; rejects with a message that's fine to show the member.

import api from '@/pages/utils/api';

export interface GoalTeamChat {
  id: number;
  name: string;
}

export async function openGoalTeamChat(goal: any, portalName: string, userId: number): Promise<GoalTeamChat> {
  let memberIds: number[] = [];
  let isOnTeam = false;
  try {
    const teamRes = await api.get(`/api/goals/details?goals_id=${goal.id}`);
    const result = teamRes.data.result;
    const team: any[] = result?.team || [];
    const creatorId = result?.creatorId ?? goal.creatorId;
    isOnTeam = userId === creatorId || team.some((m: any) => m.id === userId);
    memberIds = team.map((m: any) => m.id).filter((id: any) => id && id !== userId);
  } catch {
    // If the check fails, stay conservative and don't open the chat.
  }
  if (!isOnTeam) throw new Error('Only Goal Team members can message this team.');

  if (goal.chats_id) return { id: goal.chats_id, name: goal.title };

  const title = portalName ? `${portalName}: ${goal.title}` : goal.title;
  try {
    const res = await api.post('/api/message/manage_chat', { title, aAddIDs: memberIds });
    const chatsId = res.data.chats_id;
    if (!chatsId) throw new Error('No chats_id returned');
    api.post('/api/goals/link_chat', { goals_id: goal.id, chats_id: chatsId }).catch(() => {});
    goal.chats_id = chatsId; // later clicks reuse it
    return { id: chatsId, name: title };
  } catch (err: any) {
    const status = err?.response?.status;
    throw new Error(status === 401 || status === 403 ? 'Only Goal Team members can message this team.' : 'Couldn’t open the Goal Team chat.');
  }
}
