"""add position to s3_content for image ordering

Adds a non-null integer `position` column (server_default '0') to s3_content so
portal graphic-section images can be re-ordered. Existing rows get 0, so all reads
(ORDER BY position, id) preserve the current upload order until a user reorders.
Low-risk per DB_MIGRATION_WORKFLOW: additive column with server_default.

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-09-07

"""
from alembic import op
import sqlalchemy as sa

revision = 'f6a7b8c9d0e1'
down_revision = 'e5f6a7b8c9d0'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        's3_content',
        sa.Column('position', sa.Integer(), nullable=False, server_default='0'),
    )


def downgrade():
    op.drop_column('s3_content', 'position')
