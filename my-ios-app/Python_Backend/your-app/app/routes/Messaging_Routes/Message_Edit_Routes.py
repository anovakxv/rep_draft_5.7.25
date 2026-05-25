# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Routes for editing and deleting messages

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.Message_Edit_History import MessageEditHistory
from app.utils.auth import jwt_required
from datetime import datetime

message_edit_bp = Blueprint('message_edit', __name__)

# --- 1. Edit a message ---
@message_edit_bp.route('/<int:message_id>', methods=['PUT'])
@jwt_required
def edit_message(message_id):
    """
    Edit a message's text content.
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
    if len(new_text) > 10000:
        return jsonify({'error': 'Message too long (max 10,000 characters)'}), 400

    # Get message
    message = DirectMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user is the sender
    if message.sender_id != user_id:
        return jsonify({'error': 'Can only edit your own messages'}), 403

    # Check if message is deleted
    if getattr(message, 'is_deleted', False):
        return jsonify({'error': 'Cannot edit deleted message'}), 400

    # Save current text to edit history
    edit_history = MessageEditHistory(
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


# --- 2. Delete a message (soft delete) ---
@message_edit_bp.route('/<int:message_id>', methods=['DELETE'])
@jwt_required
def delete_message_soft(message_id):
    """
    Soft delete a message (sets is_deleted flag).
    Only the sender can delete their own messages.
    Message text is replaced with '[Message deleted]'.

    Returns:
    - result: Success message
    """
    user_id = g.current_user.id

    # Get message
    message = DirectMessage.query.get(message_id)

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


# --- 3. Get edit history for a message ---
@message_edit_bp.route('/<int:message_id>/history', methods=['GET'])
@jwt_required
def get_edit_history(message_id):
    """
    Get edit history for a message.
    Only sender and recipient can view edit history.

    Returns:
    - result: List of edit history entries (oldest to newest)
    """
    user_id = g.current_user.id

    # Get message
    message = DirectMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user is sender or recipient
    if message.sender_id != user_id and message.recipient_id != user_id:
        return jsonify({'error': 'Can only view edit history of your own messages'}), 403

    # Get edit history
    edit_history = MessageEditHistory.query.filter_by(
        message_id=message_id
    ).order_by(MessageEditHistory.edited_at.asc()).all()

    return jsonify({
        'result': [e.as_dict() for e in edit_history],
        'edit_count': len(edit_history)
    })


# --- 4. Restore a deleted message (undo delete) ---
@message_edit_bp.route('/<int:message_id>/restore', methods=['POST'])
@jwt_required
def restore_message(message_id):
    """
    Restore a soft-deleted message.
    Only works if message has edit history to restore from.
    Only the sender can restore their own messages.

    Returns:
    - result: Restored message object
    """
    user_id = g.current_user.id

    # Get message
    message = DirectMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user is the sender
    if message.sender_id != user_id:
        return jsonify({'error': 'Can only restore your own messages'}), 403

    # Check if message is deleted
    if not getattr(message, 'is_deleted', False):
        return jsonify({'error': 'Message is not deleted'}), 400

    # Try to restore from edit history
    last_edit = MessageEditHistory.query.filter_by(
        message_id=message_id
    ).order_by(MessageEditHistory.edited_at.desc()).first()

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
