"""Add file_name and is_image to GoalProgressFile

Revision ID: 4e2a292a92be
Revises: 32000d86a46a
Create Date: 2025-09-14 19:42:28.236734

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '4e2a292a92be'
down_revision = '32000d86a46a'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('goal_progress_files', schema=None) as batch_op:
        batch_op.add_column(sa.Column('file_name', sa.String(), nullable=True))
        batch_op.add_column(sa.Column('is_image', sa.Boolean(), nullable=True))
        batch_op.add_column(sa.Column('note', sa.String(), nullable=True))
        batch_op.add_column(sa.Column('created_at', sa.DateTime(), nullable=True))
        batch_op.create_foreign_key(
            'fk_goal_progress_files_goal_progress_id',
            'goals_progress_log',
            ['goal_progress_id'],
            ['id'],
            ondelete='CASCADE'
        )

def downgrade():
    with op.batch_alter_table('goal_progress_files', schema=None) as batch_op:
        batch_op.drop_constraint('fk_goal_progress_files_goal_progress_id', type_='foreignkey')
        batch_op.drop_column('created_at')
        batch_op.drop_column('note')
        batch_op.drop_column('is_image')
        batch_op.drop_column('file_name')

    # ### end Alembic commands ###
