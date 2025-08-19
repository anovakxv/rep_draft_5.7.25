# Rep
# Copyright (c) 2025 Networked Capital Inc.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from sqlalchemy import or_, and_
from app import db
from app.utils.auth import jwt_required
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.messages_read import MessagesRead

user_bp = Blueprint('get_messages', __name__)

@user_bp.route('/get_messages', methods=['GET'])
@jwt_required
def api_get_messages():
    """
    Fetch direct messages between current user and users_id.

    Query Params:
      users_id      (required)
      order         ASC|DESC (default ASC)
      limit         (optional, default 1000, max 1000)
      before_id     (optional) paginate older (id < before_id)
      mark_as_read  '1' to mark returned inbound messages as read

    Internally selects newest first then reverses if ASC.
    """
    other_id = request.args.get('users_id', type=int)
    if not other_id:
        return jsonify({'error': 'users_id required'}), 400

    current_id = g.current_user.id

    limit = request.args.get('limit', type=int) or 1000
    if limit < 1:
        limit = 50
    limit = min(limit, 1000)

    order = (request.args.get('order') or 'ASC').upper()
    if order not in ('ASC', 'DESC'):
        order = 'ASC'

    before_id = request.args.get('before_id', type=int)
    mark_flag = request.args.get('mark_as_read') == '1'

    q = DirectMessage.query.filter(
        or_(
            and_(DirectMessage.sender_id == current_id, DirectMessage.recipient_id == other_id),
            and_(DirectMessage.sender_id == other_id, DirectMessage.recipient_id == current_id)
        )
    )
    if before_id:
        q = q.filter(DirectMessage.id < before_id)

    q = q.order_by(DirectMessage.created_at.desc(), DirectMessage.id.desc()).limit(limit)
    recent_desc = q.all()

    read_new_ids = []
    existing_marked = set()

    if recent_desc:
        inbound_ids = [m.id for m in recent_desc if m.recipient_id == current_id]
        if inbound_ids:
            existing_marked = {
                mid for (mid,) in db.session.query(MessagesRead.messages_id)
                .filter(MessagesRead.users_id == current_id,
                        MessagesRead.messages_id.in_(inbound_ids))
                .all()
            }
            if mark_flag:
                for mid in inbound_ids:
                    if mid not in existing_marked:
                        db.session.add(MessagesRead(users_id=current_id, messages_id=mid))
                        read_new_ids.append(mid)
                if read_new_ids:
                    try:
                        db.session.commit()
                    except Exception as e:
                        db.session.rollback()
                        print(f"[GetMessages] read commit error: {e}")

    def read_state(m: DirectMessage) -> str:
        if m.sender_id == current_id:
            return "1"
        if m.id in read_new_ids or m.id in existing_marked:
            return "1"
        return "0"

    ordered = list(reversed(recent_desc)) if order == 'ASC' else recent_desc
    payload = [m.as_dict(read=read_state(m)) for m in ordered]

    return jsonify({'result': {'messages': payload}}), 200