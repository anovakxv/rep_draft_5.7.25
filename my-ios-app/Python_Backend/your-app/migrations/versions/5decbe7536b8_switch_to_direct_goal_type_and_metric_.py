"""Switch to direct goal_type and metric fields on Goal

Revision ID: 5decbe7536b8
Revises: c196646a34b6
Create Date: 2025-06-30 22:30:38.016366

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '5decbe7536b8'
down_revision = 'c196646a34b6'
branch_labels = None
depends_on = None

def upgrade():
    with op.batch_alter_table('goal_metrics', schema=None) as batch_op:
        pass

    with op.batch_alter_table('goals', schema=None) as batch_op:
        pass

def downgrade():
    with op.batch_alter_table('goals', schema=None) as batch_op:
        batch_op.add_column(sa.Column('goal_types_id', sa.INTEGER(), nullable=False))
        batch_op.add_column(sa.Column('goal_metrics_id', sa.INTEGER(), nullable=False))
        batch_op.create_foreign_key(None, 'goal_types', ['goal_types_id'], ['id'])
        batch_op.create_foreign_key(None, 'goal_metrics', ['goal_metrics_id'], ['id'])
        batch_op.create_index(batch_op.f('ix_goals_goal_types_id'), ['goal_types_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_goals_goal_metrics_id'), ['goal_metrics_id'], unique=False)
        batch_op.drop_column('metric')
        batch_op.drop_column('goal_type')

    with op.batch_alter_table('goal_metrics', schema=None) as batch_op:
        batch_op.add_column(sa.Column('goal_types_id', sa.INTEGER(), nullable=False))
        batch_op.add_column(sa.Column('title', sa.VARCHAR(length=100), nullable=False))
        batch_op.create_foreign_key(None, 'goal_types', ['goal_types_id'], ['id'])
        batch_op.drop_column('metric')
        batch_op.drop_column('goal_type')