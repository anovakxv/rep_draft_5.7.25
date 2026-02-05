# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: February 2026

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.UserPhoto import UserPhoto
from app.models.People_Models.PhotoLike import PhotoLike
from app.utils.auth import jwt_required

photo_likes_bp = Blueprint('photo_likes', __name__)


@photo_likes_bp.route('/photos/<int:photo_id>/like', methods=['POST'])
@jwt_required
def toggle_like(photo_id):
    """Toggle like on a photo. If already liked, unlike it. If not liked, like it."""
    user_id = g.current_user.id

    # Verify photo exists
    photo = UserPhoto.query.get(photo_id)
    if not photo:
        return jsonify({'error': 'Photo not found'}), 404

    try:
        existing_like = PhotoLike.query.filter_by(photo_id=photo_id, user_id=user_id).first()

        if existing_like:
            db.session.delete(existing_like)
            db.session.commit()
            like_count = PhotoLike.query.filter_by(photo_id=photo_id).count()
            return jsonify({
                'result': 'unliked',
                'like_count': like_count,
                'user_liked': False
            }), 200
        else:
            new_like = PhotoLike(photo_id=photo_id, user_id=user_id)
            db.session.add(new_like)
            db.session.commit()
            like_count = PhotoLike.query.filter_by(photo_id=photo_id).count()
            return jsonify({
                'result': 'liked',
                'like_count': like_count,
                'user_liked': True
            }), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error toggling photo like: {e}")
        return jsonify({'error': 'Failed to toggle like'}), 500


@photo_likes_bp.route('/photos/<int:photo_id>/likes', methods=['GET'])
@jwt_required
def get_photo_likes(photo_id):
    """Get all likes for a photo including count and whether current user liked it."""
    user_id = g.current_user.id

    # Verify photo exists
    photo = UserPhoto.query.get(photo_id)
    if not photo:
        return jsonify({'error': 'Photo not found'}), 404

    try:
        likes = PhotoLike.query.filter_by(photo_id=photo_id).all()
        like_count = len(likes)
        user_liked = any(like.user_id == user_id for like in likes)

        users = [{
            'user_id': like.user_id,
            'user_name': f"{like.user.fname or ''} {like.user.lname or ''}".strip() if like.user else ""
        } for like in likes]

        return jsonify({
            'like_count': like_count,
            'user_liked': user_liked,
            'users': users
        }), 200

    except Exception as e:
        print(f"Error fetching photo likes: {e}")
        return jsonify({'error': 'Failed to fetch likes'}), 500
