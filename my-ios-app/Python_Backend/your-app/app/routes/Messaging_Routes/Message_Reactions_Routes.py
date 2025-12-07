# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Routes for message reactions (emojis)

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.Message_Reactions import MessageReaction
from app.utils.auth import jwt_required

reactions_bp = Blueprint('message_reactions', __name__)

# --- 1. Add a reaction to a message ---
@reactions_bp.route('/message/<int:message_id>/reaction', methods=['POST'])
@jwt_required
def add_reaction(message_id):
    """
    Add an emoji reaction to a message.

    Body params:
    - emoji (str, required): Emoji character (e.g., '👍', '❤️', '😂')

    Returns:
    - result: Created reaction object
    """
    user_id = g.current_user.id
    data = request.get_json()

    emoji = data.get('emoji', '').strip()

    if not emoji:
        return jsonify({'error': 'Emoji required'}), 400

    # Check if message exists
    message = DirectMessage.query.get(message_id)
    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user already reacted with this emoji
    existing_reaction = MessageReaction.query.filter_by(
        message_id=message_id,
        user_id=user_id,
        emoji=emoji
    ).first()

    if existing_reaction:
        return jsonify({'error': 'Already reacted with this emoji'}), 409

    # Create new reaction
    reaction = MessageReaction(
        message_id=message_id,
        user_id=user_id,
        emoji=emoji
    )

    db.session.add(reaction)
    db.session.commit()

    return jsonify({'result': reaction.as_dict()}), 201


# --- 2. Remove a reaction from a message ---
@reactions_bp.route('/message/<int:message_id>/reaction/<int:reaction_id>', methods=['DELETE'])
@jwt_required
def remove_reaction(message_id, reaction_id):
    """
    Remove a reaction from a message.
    Users can only remove their own reactions.

    Returns:
    - result: Success message
    """
    user_id = g.current_user.id

    reaction = MessageReaction.query.get(reaction_id)

    if not reaction:
        return jsonify({'error': 'Reaction not found'}), 404

    if reaction.message_id != message_id:
        return jsonify({'error': 'Reaction does not belong to this message'}), 400

    if reaction.user_id != user_id:
        return jsonify({'error': 'Cannot remove other users\' reactions'}), 403

    db.session.delete(reaction)
    db.session.commit()

    return jsonify({'result': 'Reaction removed'})


# --- 3. Get all reactions for a message ---
@reactions_bp.route('/message/<int:message_id>/reactions', methods=['GET'])
@jwt_required
def get_message_reactions(message_id):
    """
    Get all reactions for a message.

    Returns:
    - result: List of reactions
    - grouped: Reactions grouped by emoji with counts
    """
    message = DirectMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    reactions = MessageReaction.query.filter_by(message_id=message_id).all()

    # Group reactions by emoji
    reactions_grouped = {}
    for reaction in reactions:
        emoji = reaction.emoji
        if emoji not in reactions_grouped:
            reactions_grouped[emoji] = {
                "emoji": emoji,
                "count": 0,
                "users": []
            }
        reactions_grouped[emoji]["count"] += 1
        reactions_grouped[emoji]["users"].append({
            "user_id": reaction.user_id,
            "user_name": f"{reaction.user.fname or ''} {reaction.user.lname or ''}".strip() if reaction.user else ""
        })

    return jsonify({
        'result': [r.as_dict() for r in reactions],
        'grouped': list(reactions_grouped.values())
    })


# --- 4. Toggle a reaction (add if not exists, remove if exists) ---
@reactions_bp.route('/toggle-reaction/<int:message_id>', methods=['POST'])
@jwt_required
def toggle_reaction(message_id):
    """
    Toggle a reaction: add if it doesn't exist, remove if it does.
    Convenient for UI interactions.

    Body params:
    - emoji (str, required): Emoji character

    Returns:
    - result: 'added' or 'removed'
    - reaction: Reaction object (if added)
    """
    user_id = g.current_user.id
    data = request.get_json()

    emoji = data.get('emoji', '').strip()

    if not emoji:
        return jsonify({'error': 'Emoji required'}), 400

    # Check if message exists
    message = DirectMessage.query.get(message_id)
    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user already reacted with this emoji
    existing_reaction = MessageReaction.query.filter_by(
        message_id=message_id,
        user_id=user_id,
        emoji=emoji
    ).first()

    if existing_reaction:
        # Remove reaction
        db.session.delete(existing_reaction)
        db.session.commit()
        action = 'removed'
    else:
        # Add reaction
        reaction = MessageReaction(
            message_id=message_id,
            user_id=user_id,
            emoji=emoji
        )
        db.session.add(reaction)
        db.session.commit()
        action = 'added'

    # Get updated grouped reactions for this message
    reactions = MessageReaction.query.filter_by(message_id=message_id).all()
    reactions_grouped = {}
    for reaction in reactions:
        emoji_char = reaction.emoji
        if emoji_char not in reactions_grouped:
            reactions_grouped[emoji_char] = {
                "emoji": emoji_char,
                "count": 0,
                "userReacted": False,
                "users": []
            }
        reactions_grouped[emoji_char]["count"] += 1
        if reaction.user_id == user_id:
            reactions_grouped[emoji_char]["userReacted"] = True
        reactions_grouped[emoji_char]["users"].append({
            "user_id": reaction.user_id,
            "user_name": f"{reaction.user.fname or ''} {reaction.user.lname or ''}".strip() if reaction.user else ""
        })

    return jsonify({
        'result': action,
        'reactions': list(reactions_grouped.values())
    })
