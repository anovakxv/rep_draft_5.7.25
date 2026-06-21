# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: February 2026

from flask import Blueprint, request, jsonify, g
from app import db, limiter
from app.models.People_Models.UserPhoto import UserPhoto
from app.models.People_Models.PhotoReaction import PhotoReaction
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

photo_reactions_bp = Blueprint('photo_reactions', __name__)


def get_grouped_reactions(photo_id, current_user_id):
    """Helper to build grouped reaction response (matches message reactions pattern)."""
    reactions = PhotoReaction.query.filter_by(photo_id=photo_id).all()

    # Batch-load reacting users in one query to avoid N+1
    user_ids = {r.user_id for r in reactions}
    users_map = {u.id: u for u in User.query.filter(User.id.in_(user_ids)).all()} if user_ids else {}

    # Group by emoji
    grouped = {}
    for reaction in reactions:
        emoji = reaction.emoji
        if emoji not in grouped:
            grouped[emoji] = {
                'emoji': emoji,
                'count': 0,
                'userReacted': False,
                'users': []
            }
        grouped[emoji]['count'] += 1
        u = users_map.get(reaction.user_id)
        grouped[emoji]['users'].append({
            'user_id': reaction.user_id,
            'user_name': f"{u.fname or ''} {u.lname or ''}".strip() if u else ""
        })
        if reaction.user_id == current_user_id:
            grouped[emoji]['userReacted'] = True

    return list(grouped.values())


@photo_reactions_bp.route('/photos/<int:photo_id>/reaction', methods=['POST'])
@jwt_required
@limiter.limit("60 per minute")
def toggle_reaction(photo_id):
    """Toggle emoji reaction on a photo. If already reacted with this emoji, remove it."""
    user_id = g.current_user.id
    data = request.get_json()

    if not data or not data.get('emoji'):
        return jsonify({'error': 'emoji required'}), 400

    emoji = data['emoji']

    # Verify photo exists
    photo = UserPhoto.query.get(photo_id)
    if not photo:
        return jsonify({'error': 'Photo not found'}), 404

    try:
        existing = PhotoReaction.query.filter_by(
            photo_id=photo_id, user_id=user_id, emoji=emoji
        ).first()

        if existing:
            db.session.delete(existing)
            db.session.commit()
            result = 'removed'
        else:
            new_reaction = PhotoReaction(photo_id=photo_id, user_id=user_id, emoji=emoji)
            db.session.add(new_reaction)
            db.session.commit()
            result = 'added'

        return jsonify({
            'result': result,
            'reactions': get_grouped_reactions(photo_id, user_id)
        }), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error toggling photo reaction: {e}")
        return jsonify({'error': 'Failed to toggle reaction'}), 500


@photo_reactions_bp.route('/photos/<int:photo_id>/reactions', methods=['GET'])
@jwt_required
def get_photo_reactions(photo_id):
    """Get all grouped reactions for a photo."""
    user_id = g.current_user.id

    # Verify photo exists
    photo = UserPhoto.query.get(photo_id)
    if not photo:
        return jsonify({'error': 'Photo not found'}), 404

    try:
        return jsonify({
            'grouped': get_grouped_reactions(photo_id, user_id)
        }), 200

    except Exception as e:
        print(f"Error fetching photo reactions: {e}")
        return jsonify({'error': 'Failed to fetch reactions'}), 500


@photo_reactions_bp.route('/photos/<int:photo_id>/reaction/<int:reaction_id>', methods=['DELETE'])
@jwt_required
def remove_reaction(photo_id, reaction_id):
    """Remove a specific reaction. Users can only remove their own reactions."""
    user_id = g.current_user.id

    reaction = PhotoReaction.query.get(reaction_id)
    if not reaction:
        return jsonify({'error': 'Reaction not found'}), 404

    if reaction.photo_id != photo_id:
        return jsonify({'error': 'Reaction does not belong to this photo'}), 400

    if reaction.user_id != user_id:
        return jsonify({'error': 'Permission denied'}), 403

    try:
        db.session.delete(reaction)
        db.session.commit()
        return jsonify({'result': 'Reaction removed'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error removing photo reaction: {e}")
        return jsonify({'error': 'Failed to remove reaction'}), 500
