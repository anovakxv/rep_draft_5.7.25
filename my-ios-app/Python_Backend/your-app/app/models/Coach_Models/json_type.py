# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
#
# JSON column type for the Coach (AI) tables: JSONB on Postgres (production),
# plain JSON on SQLite (local dev, sqlite:///test.db).

from sqlalchemy.dialects.postgresql import JSONB

from app import db

JSONType = db.JSON().with_variant(JSONB(), 'postgresql')
