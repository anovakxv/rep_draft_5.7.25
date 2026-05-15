# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Routes for group message reactions (emojis)

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.People_Models.Messaging_Models.Group_Message_Reactions import GroupMessageReaction
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

group_reactions_bp = Blueprint('group_message_reactions', __name__)

# --- 1. Add a reaction to a group message ---
@group_reactions_bp.route('/group/<int:message_id>/reaction', methods=['POST'])
@jwt_required
def add_group_reaction(message_id):
    """
    Add an emoji reaction to a group message.

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
    message = GroupMessage.query.get(message_id)
    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user already reacted with this emoji
    existing_reaction = GroupMessageReaction.query.filter_by(
        message_id=message_id,
        user_id=user_id,
        emoji=emoji
    ).first()

    if existing_reaction:
        return jsonify({'error': 'Already reacted with this emoji'}), 409

    # Create new reaction
    reaction = GroupMessageReaction(
        message_id=message_id,
        user_id=user_id,
        emoji=emoji
    )

    db.session.add(reaction)
    db.session.commit()

    return jsonify({'result': reaction.as_dict()}), 201


# --- 2. Remove a reaction from a group message ---
@group_reactions_bp.route('/group/<int:message_id>/reaction/<int:reaction_id>', methods=['DELETE'])
@jwt_required
def remove_group_reaction(message_id, reaction_id):
    """
    Remove a reaction from a group message.
    Users can only remove their own reactions.

    Returns:
    - result: Success message
    """
    user_id = g.current_user.id

    reaction = GroupMessageReaction.query.get(reaction_id)

    if not reaction:
        return jsonify({'error': 'Reaction not found'}), 404

    if reaction.message_id != message_id:
        return jsonify({'error': 'Reaction does not belong to this message'}), 400

    if reaction.user_id != user_id:
        return jsonify({'error': 'Cannot remove other users\' reactions'}), 403

    db.session.delete(reaction)
    db.session.commit()

    return jsonify({'result': 'Reaction removed'})


# --- 3. Get all reactions for a group message ---
@group_reactions_bp.route('/group/<int:message_id>/reactions', methods=['GET'])
@jwt_required
def get_group_message_reactions(message_id):
    """
    Get all reactions for a group message.

    Returns:
    - result: List of reactions
    - grouped: Reactions grouped by emoji with counts
    """
    message = GroupMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    reactions = GroupMessageReaction.query.filter_by(message_id=message_id).all()

    # Batch-load users to avoid N+1
    user_ids = {r.user_id for r in reactions}
    users_map = {u.id: u for u in User.query.filter(User.id.in_(user_ids)).all()} if user_ids else {}

    # Group reactions by emoji
    reactions_grouped = {}
    for reaction in reactions:
        emoji = reaction.emoji
        if emoji not in reactions_grouped:
            reactions_grouped[emoji] = {"emoji": emoji, "count": 0, "users": []}
        reactions_grouped[emoji]["count"] += 1
        u = users_map.get(reaction.user_id)
        reactions_grouped[emoji]["users"].append({
            "user_id": reaction.user_id,
            "user_name": f"{u.fname or ''} {u.lname or ''}".strip() if u else ""
        })

    return jsonify({
        'result': [r.as_dict() for r in reactions],
        'grouped': list(reactions_grouped.values())
    })


# --- 4. Toggle a reaction (add if not exists, remove if exists) ---
@group_reactions_bp.route('/group/toggle-reaction/<int:message_id>', methods=['POST'])
@jwt_required
def toggle_group_reaction(message_id):
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
    message = GroupMessage.query.get(message_id)
    if not message:
        return jsonify({'error': 'Message not found'}), 404

    # Check if user already reacted with this emoji
    existing_reaction = GroupMessageReaction.query.filter_by(
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
        reaction = GroupMessageReaction(
            message_id=message_id,
            user_id=user_id,
            emoji=emoji
        )
        db.session.add(reaction)
        db.session.commit()
        action = 'added'

    # Get updated grouped reactions — batch-load users to avoid N+1
    reactions = GroupMessageReaction.query.filter_by(message_id=message_id).all()
    user_ids = {r.user_id for r in reactions}
    users_map = {u.id: u for u in User.query.filter(User.id.in_(user_ids)).all()} if user_ids else {}
    reactions_grouped = {}
    for reaction in reactions:
        emoji_char = reaction.emoji
        if emoji_char not in reactions_grouped:
            reactions_grouped[emoji_char] = {
                "emoji": emoji_char, "count": 0, "userReacted": False, "users": []
            }
        reactions_grouped[emoji_char]["count"] += 1
        if reaction.user_id == user_id:
            reactions_grouped[emoji_char]["userReacted"] = True
        u = users_map.get(reaction.user_id)
        reactions_grouped[emoji_char]["users"].append({
            "user_id": reaction.user_id,
            "user_name": f"{u.fname or ''} {u.lname or ''}".strip() if u else ""
        })

    return jsonify({
        'result': action,
        'reactions': list(reactions_grouped.values())
    })
