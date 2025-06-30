# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Write_Models.Writings_Model import Write
from app.utils.auth import jwt_required

user_bp = Blueprint('user_writes', __name__)

# --- 1. List all writes for a user ---
@user_bp.route('/writes', methods=['GET'])
@jwt_required
def get_user_writes():
    users_id = request.args.get('users_id', type=int)
    if not users_id:
        return jsonify({'error': 'users_id required'}), 400
    writes = Write.query.filter_by(users_id=users_id).order_by(Write.order.asc(), Write.created_at.desc()).all()
    result = [w.as_dict() for w in writes]
    return jsonify({'result': result})

# --- 2. Add a new write block ---
@user_bp.route('/write', methods=['POST'])
@jwt_required
def add_user_write():
    users_id = g.current_user.id
    data = request.get_json()
    title = data.get('title', '').strip()
    content = data.get('content', '').strip()
    order = data.get('order', 0)
    status = data.get('status', 'published')
    if not users_id or not content:
        return jsonify({'error': 'Missing user or content'}), 400
    write = Write(users_id=users_id, title=title, content=content, order=order, status=status)
    db.session.add(write)
    db.session.commit()
    return jsonify({'result': write.as_dict()})

# --- 3. Edit a write block ---
@user_bp.route('/write/<int:write_id>', methods=['PUT'])
@jwt_required
def edit_user_write(write_id):
    users_id = g.current_user.id
    write = Write.query.get(write_id)
    if not write or write.users_id != users_id:
        return jsonify({'error': 'Write not found or unauthorized'}), 404
    data = request.get_json()
    write.title = data.get('title', write.title)
    write.content = data.get('content', write.content)
    write.order = data.get('order', write.order)
    write.status = data.get('status', write.status)
    db.session.commit()
    return jsonify({'result': write.as_dict()})

# --- 4. Delete a write block ---
@user_bp.route('/write/<int:write_id>', methods=['DELETE'])
@jwt_required
def delete_user_write(write_id):
    users_id = g.current_user.id
    write = Write.query.get(write_id)
    if not write or write.users_id != users_id:
        return jsonify({'error': 'Write not found or unauthorized'}), 404
    db.session.delete(write)
    db.session.commit()
    return jsonify({'result': 'Write deleted'})
