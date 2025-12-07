# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Routes for editing and deleting group messages

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.People_Models.Messaging_Models.Group_Message_Edit_History import GroupMessageEditHistory
from app.utils.auth import jwt_required
from datetime import datetime

group_message_edit_bp = Blueprint('group_message_edit', __name__)

# --- 1. Edit a group message ---
@group_message_edit_bp.route('/group/<int:message_id>/edit', methods=['PUT'])
@jwt_required
def edit_group_message(message_id):
    """
    Edit a group message's text content.
    Only the sender can edit their own messages.
    Stores previous text in edit history.

    Body params:
    - text (str, required): New message text

    Returns:
    - result: Updated message object with edit info
    """
    user_id = g.current_user.id
    data = request.get_json()

    new_text = data.get('text', '').strip()

    if not new_text:
        return jsonify({'error': 'Text required'}), 400

    # Get message
    message = GroupMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user is the sender
    if message.sender_id != user_id:
        return jsonify({'error': 'Can only edit your own messages'}), 403

    # Check if message is deleted
    if getattr(message, 'is_deleted', False):
        return jsonify({'error': 'Cannot edit deleted message'}), 400

    # Save current text to edit history
    edit_history = GroupMessageEditHistory(
        message_id=message_id,
        previous_text=message.text,
        edited_at=datetime.utcnow()
    )

    # Update message
    message.text = new_text

    # Set edited_at timestamp (if field exists)
    if hasattr(message, 'edited_at'):
        message.edited_at = datetime.utcnow()

    db.session.add(edit_history)
    db.session.commit()

    # Return updated message with edit info
    result = message.as_dict() if hasattr(message, 'as_dict') else {
        'id': message.id,
        'text': message.text,
        'edited_at': message.edited_at.strftime("%Y-%m-%dT%H:%M:%SZ") if hasattr(message, 'edited_at') and message.edited_at else None
    }

    return jsonify({'result': result})


# --- 2. Delete a group message (soft delete) ---
@group_message_edit_bp.route('/group/<int:message_id>', methods=['DELETE'])
@jwt_required
def delete_group_message_soft(message_id):
    """
    Soft delete a group message (sets is_deleted flag).
    Only the sender can delete their own messages.
    Message text is replaced with '[Message deleted]'.

    Returns:
    - result: Success message
    """
    user_id = g.current_user.id

    # Get message
    message = GroupMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user is the sender
    if message.sender_id != user_id:
        return jsonify({'error': 'Can only delete your own messages'}), 403

    # Check if already deleted
    if getattr(message, 'is_deleted', False):
        return jsonify({'error': 'Message already deleted'}), 400

    # Soft delete: set flag and replace text
    if hasattr(message, 'is_deleted'):
        message.is_deleted = True
        message.text = '[Message deleted]'
    else:
        # Fallback if is_deleted field doesn't exist yet
        message.text = '[Message deleted]'

    db.session.commit()

    return jsonify({'result': 'Message deleted'})


# --- 3. Get edit history for a group message ---
@group_message_edit_bp.route('/group/<int:message_id>/edit_history', methods=['GET'])
@jwt_required
def get_group_edit_history(message_id):
    """
    Get edit history for a group message.
    All chat members can view edit history.

    Returns:
    - result: List of edit history entries (oldest to newest)
    """
    user_id = g.current_user.id

    # Get message
    message = GroupMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # For group messages, we could check if user is a member of the chat
    # but for simplicity, we'll allow any authenticated user to view
    # (You could add chat membership check here if needed)

    # Get edit history
    edit_history = GroupMessageEditHistory.query.filter_by(
        message_id=message_id
    ).order_by(GroupMessageEditHistory.edited_at.asc()).all()

    return jsonify({
        'result': [e.as_dict() for e in edit_history],
        'edit_count': len(edit_history)
    })


# --- 4. Restore a deleted group message (undo delete) ---
@group_message_edit_bp.route('/group/<int:message_id>/restore', methods=['POST'])
@jwt_required
def restore_group_message(message_id):
    """
    Restore a soft-deleted group message.
    Only works if message has edit history to restore from.
    Only the sender can restore their own messages.

    Returns:
    - result: Restored message object
    """
    user_id = g.current_user.id

    # Get message
    message = GroupMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user is the sender
    if message.sender_id != user_id:
        return jsonify({'error': 'Can only restore your own messages'}), 403

    # Check if message is deleted
    if not getattr(message, 'is_deleted', False):
        return jsonify({'error': 'Message is not deleted'}), 400

    # Try to restore from edit history
    last_edit = GroupMessageEditHistory.query.filter_by(
        message_id=message_id
    ).order_by(GroupMessageEditHistory.edited_at.desc()).first()

    if last_edit:
        # Restore from last edit
        message.text = last_edit.previous_text
    else:
        return jsonify({'error': 'Cannot restore: no edit history found'}), 400

    # Clear deleted flag
    if hasattr(message, 'is_deleted'):
        message.is_deleted = False

    db.session.commit()

    result = message.as_dict() if hasattr(message, 'as_dict') else {
        'id': message.id,
        'text': message.text
    }

    return jsonify({'result': result})
