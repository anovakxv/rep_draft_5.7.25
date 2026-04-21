"""add event_duration_minutes to portals

Revision ID: b5c6d7e8f9a0
Revises: f3a8d921c047
Create Date: 2026-04-21

"""
from alembic import op
import sqlalchemy as sa

revision = 'b5c6d7e8f9a0'
down_revision = 'f3a8d921c047'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('portals', schema=None) as batch_op:
        batch_op.add_column(sa.Column('event_duration_minutes', sa.Integer(), nullable=True))


def downgrade():
    with op.batch_alter_table('portals', schema=None) as batch_op:
        batch_op.drop_column('event_duration_minutes')
