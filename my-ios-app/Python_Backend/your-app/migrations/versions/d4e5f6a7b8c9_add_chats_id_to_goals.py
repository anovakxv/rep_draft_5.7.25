"""add chats_id to goals

Revision ID: d4e5f6a7b8c9
Revises: b5c6d7e8f9a0
Create Date: 2026-05-13

"""
from alembic import op
import sqlalchemy as sa

revision = 'd4e5f6a7b8c9'
down_revision = 'b5c6d7e8f9a0'
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()

    # Add column only if it doesn't exist yet (handles partial-run recovery on SQLite)
    inspector = sa.inspect(bind)
    existing_columns = [c['name'] for c in inspector.get_columns('goals')]
    if 'chats_id' not in existing_columns:
        op.add_column('goals', sa.Column('chats_id', sa.Integer(), nullable=True))

    # FK constraint — PostgreSQL only; SQLite doesn't support ALTER TABLE ADD CONSTRAINT
    # and doesn't enforce FK constraints anyway
    if bind.dialect.name != 'sqlite':
        op.create_foreign_key(
            'fk_goals_chats_id', 'goals', 'chats',
            ['chats_id'], ['id'],
            ondelete='SET NULL'
        )


def downgrade():
    bind = op.get_bind()
    if bind.dialect.name != 'sqlite':
        op.drop_constraint('fk_goals_chats_id', 'goals', type_='foreignkey')
    op.drop_column('goals', 'chats_id')
