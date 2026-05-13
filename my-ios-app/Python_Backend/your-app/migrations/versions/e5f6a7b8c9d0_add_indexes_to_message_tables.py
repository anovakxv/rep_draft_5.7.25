"""add indexes to message tables

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-05-13

"""
from alembic import op

revision = 'e5f6a7b8c9d0'
down_revision = 'd4e5f6a7b8c9'
branch_labels = None
depends_on = None


def upgrade():
    # DirectMessage: individual indexes + composite for the dominant query pattern
    op.create_index('ix_direct_messages_sender_id', 'direct_messages', ['sender_id'])
    op.create_index('ix_direct_messages_recipient_id', 'direct_messages', ['recipient_id'])
    op.create_index('ix_direct_messages_sender_recipient', 'direct_messages', ['sender_id', 'recipient_id'])

    # GroupMessage: chat_id is the hottest column (every group chat query filters on it)
    op.create_index('ix_group_messages_chat_id', 'group_messages', ['chat_id'])
    op.create_index('ix_group_messages_sender_id', 'group_messages', ['sender_id'])


def downgrade():
    op.drop_index('ix_group_messages_sender_id', table_name='group_messages')
    op.drop_index('ix_group_messages_chat_id', table_name='group_messages')
    op.drop_index('ix_direct_messages_sender_recipient', table_name='direct_messages')
    op.drop_index('ix_direct_messages_recipient_id', table_name='direct_messages')
    op.drop_index('ix_direct_messages_sender_id', table_name='direct_messages')
