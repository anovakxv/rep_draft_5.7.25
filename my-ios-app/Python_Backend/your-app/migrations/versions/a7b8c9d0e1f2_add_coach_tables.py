"""add Rep Coach tables (coach_messages, coach_memories)

Creates the two AI tables for Rep Coach / Rep Onboarding, kept separate from the
member's own content and from regular chat (the only link is user_id -> users.id):
  coach_messages — every Coach/Onboarding turn; members can delete one or all (hard delete)
  coach_memories — one row per member: what Coach knows + Onboarding progress
Additive only (new tables + index; no existing table or row touched). Low risk per
DB_MIGRATION_WORKFLOW. JSON columns are JSONB on Postgres, JSON on SQLite.

Revision ID: a7b8c9d0e1f2
Revises: f6a7b8c9d0e1
Create Date: 2026-10-18

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'a7b8c9d0e1f2'
down_revision = 'f6a7b8c9d0e1'
branch_labels = None
depends_on = None

JSON_TYPE = sa.JSON().with_variant(postgresql.JSONB(), 'postgresql')


def upgrade():
    op.create_table(
        'coach_messages',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('thread', sa.String(length=20), nullable=False, server_default='coach'),
        sa.Column('role', sa.String(length=10), nullable=False),
        sa.Column('kind', sa.String(length=20), nullable=False, server_default='text'),
        sa.Column('text', sa.Text(), nullable=False),
        sa.Column('payload', JSON_TYPE, nullable=True),
        sa.Column('model', sa.String(length=60), nullable=True),
        sa.Column('input_tokens', sa.Integer(), nullable=True),
        sa.Column('output_tokens', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        'ix_coach_messages_user_thread_created',
        'coach_messages',
        ['user_id', 'thread', 'created_at'],
        unique=False,
    )

    op.create_table(
        'coach_memories',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('narrative', sa.Text(), nullable=True),
        sa.Column('facts', JSON_TYPE, nullable=False, server_default='{}'),
        sa.Column('onboarding_status', sa.String(length=20), nullable=False, server_default='not_started'),
        sa.Column('onboarding_step', sa.SmallInteger(), nullable=False, server_default='0'),
        sa.Column('onboarding_answers', JSON_TYPE, nullable=False, server_default='{}'),
        sa.Column('onboarding_completed_at', sa.DateTime(), nullable=True),
        sa.Column('write_saved_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', name='uq_coach_memories_user_id'),
    )


def downgrade():
    op.drop_table('coach_memories')
    op.drop_index('ix_coach_messages_user_thread_created', table_name='coach_messages')
    op.drop_table('coach_messages')
