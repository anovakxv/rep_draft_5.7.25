# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: February 2026

from flask import Blueprint, request, jsonify, g
from app import db, limiter
from app.models.People_Models.UserPhoto import UserPhoto
from app.models.People_Models.PhotoComment import PhotoComment
from app.utils.auth import jwt_required

photo_comments_bp = Blueprint('photo_comments', __name__)


@photo_comments_bp.route('/photos/<int:photo_id>/comments', methods=['POST'])
@jwt_required
@limiter.limit("30 per minute")
def add_comment(photo_id):
    """Add a comment to a photo."""
    user_id = g.current_user.id
    data = request.get_json()

    if not data or not data.get('text') or not data['text'].strip():
        return jsonify({'error': 'text required'}), 400

    text = data['text'].strip()
    if len(text) > 1000:
        return jsonify({'error': 'Comment must be 1000 characters or less'}), 400

    # Verify photo exists
    photo = UserPhoto.query.get(photo_id)
    if not photo:
        return jsonify({'error': 'Photo not found'}), 404

    try:
        comment = PhotoComment(photo_id=photo_id, user_id=user_id, text=text)
        db.session.add(comment)
        db.session.commit()

        return jsonify({'result': comment.as_dict()}), 201

    except Exception as e:
        db.session.rollback()
        print(f"Error adding photo comment: {e}")
        return jsonify({'error': 'Failed to add comment'}), 500


@photo_comments_bp.route('/photos/<int:photo_id>/comments', methods=['GET'])
@jwt_required
def get_comments(photo_id):
    """Get all comments for a photo (paginated, chronological order)."""
    # Verify photo exists
    photo = UserPhoto.query.get(photo_id)
    if not photo:
        return jsonify({'error': 'Photo not found'}), 404

    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    per_page = min(per_page, 100)  # Cap at 100

    try:
        pagination = PhotoComment.query.filter_by(photo_id=photo_id)\
            .order_by(PhotoComment.created_at.asc())\
            .paginate(page=page, per_page=per_page, error_out=False)

        return jsonify({
            'comments': [c.as_dict() for c in pagination.items],
            'total': pagination.total,
            'page': page,
            'per_page': per_page
        }), 200

    except Exception as e:
        print(f"Error fetching photo comments: {e}")
        return jsonify({'error': 'Failed to fetch comments'}), 500


@photo_comments_bp.route('/photos/comments/<int:comment_id>', methods=['PUT'])
@jwt_required
def edit_comment(comment_id):
    """Edit own comment."""
    user_id = g.current_user.id
    data = request.get_json()

    if not data or not data.get('text') or not data['text'].strip():
        return jsonify({'error': 'text required'}), 400

    text = data['text'].strip()
    if len(text) > 1000:
        return jsonify({'error': 'Comment must be 1000 characters or less'}), 400

    comment = PhotoComment.query.get(comment_id)
    if not comment:
        return jsonify({'error': 'Comment not found'}), 404

    if comment.user_id != user_id:
        return jsonify({'error': 'Permission denied'}), 403

    try:
        comment.text = text
        db.session.commit()

        return jsonify({'result': comment.as_dict()}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error editing photo comment: {e}")
        return jsonify({'error': 'Failed to edit comment'}), 500


@photo_comments_bp.route('/photos/comments/<int:comment_id>', methods=['DELETE'])
@jwt_required
def delete_comment(comment_id):
    """Delete a comment. Users can delete their own comments. Photo owner can delete any comment."""
    user_id = g.current_user.id

    comment = PhotoComment.query.get(comment_id)
    if not comment:
        return jsonify({'error': 'Comment not found'}), 404

    # Allow deletion if: user owns the comment OR user owns the photo
    is_comment_owner = comment.user_id == user_id
    is_photo_owner = comment.photo.users_id == user_id

    if not is_comment_owner and not is_photo_owner:
        return jsonify({'error': 'Permission denied'}), 403

    try:
        db.session.delete(comment)
        db.session.commit()
        return jsonify({'result': 'Comment deleted'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error deleting photo comment: {e}")
        return jsonify({'error': 'Failed to delete comment'}), 500
