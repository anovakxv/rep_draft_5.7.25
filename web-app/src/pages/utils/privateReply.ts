// src/pages/utils/privateReply.ts
// "Reply privately": answer someone's group-chat message in a 1:1 DM.
// No backend changes — the quoted group message travels inside the DM text as
// leading "> " lines, so the iOS/Android apps show it as readable plain text and
// the web app renders it as a quote card (see splitQuote).

export interface PrivateReplyDraft {
  recipientId: number;
  recipientName: string;
  groupName: string;
  text: string;
}

const QUOTE_MAX = 200; // characters of the original message kept in the quote

// Handed from the group chat to the DM page on navigation (kept out of the URL
// so message text never lands in browser history). Lost on a full page reload.
let pending: PrivateReplyDraft | null = null;

export function startPrivateReply(draft: PrivateReplyDraft) {
  pending = draft;
}

// Returns the draft only if it's for this DM, and clears it either way.
export function takePrivateReply(recipientId: number): PrivateReplyDraft | null {
  const draft = pending;
  pending = null;
  return draft && draft.recipientId === recipientId ? draft : null;
}

export function quoteSnippet(text: string): string {
  const oneLine = (text || '').replace(/\s+/g, ' ').trim();
  if (!oneLine) return '(attachment)';
  return oneLine.length > QUOTE_MAX ? `${oneLine.slice(0, QUOTE_MAX - 1).trimEnd()}…` : oneLine;
}

// Email-style attribution so the quote reads the same to both people in the DM.
export function buildPrivateReplyText(draft: PrivateReplyDraft, reply: string): string {
  const oneLine = (s: string) => s.replace(/\s+/g, ' ').trim();
  return `> In ${oneLine(draft.groupName)}, ${oneLine(draft.recipientName)} wrote:\n> "${quoteSnippet(draft.text)}"\n\n${reply}`;
}

// Splits a message into its leading "> " quote lines and the rest. Only treated
// as a quote when a blank line and a non-empty reply follow, so a message that
// merely starts with ">" still renders normally.
export function splitQuote(text?: string): { quote: string[]; body: string } {
  const lines = (text || '').split('\n');
  let i = 0;
  while (i < lines.length && lines[i].startsWith('> ')) i++;
  const body = lines.slice(i + 1).join('\n');
  if (i === 0 || lines[i] !== '' || !body.trim()) return { quote: [], body: text || '' };
  return { quote: lines.slice(0, i).map(l => l.slice(2)), body };
}

// Chat-list preview: show the reply itself rather than the quote header.
export function messagePreview(text?: string): string {
  return splitQuote(text).body;
}
