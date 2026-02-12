# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: January 2026

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.UserPhoto import UserPhoto
from app.models.s3Content_Models.s3Content import S3Content
from app.utils.auth import jwt_required
from sqlalchemy import desc
from werkzeug.utils import secure_filename
import uuid
import boto3
import os

# --- S3 Configuration ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"
S3_BUCKET = "rep-app-dbbucket"

s3 = boto3.client(
    's3',
    aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
    region_name=os.environ.get('AWS_DEFAULT_REGION')
)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
MAX_PHOTOS_PER_USER = 50
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

user_photos_bp = Blueprint('user_photos', __name__)

def patch_photo_url(url):
    """Ensure URL is a full S3 URL (matching portal graphics pattern)."""
    if url and not url.startswith("http"):
        return S3_BASE_URL + url
    return url


# GET: Fetch all photos for a user
@user_photos_bp.route('/photos', methods=['GET'])
@jwt_required
def api_get_user_photos():
    """
    Get all photos for a user
    Query params: users_id (required)
    Returns: { "result": [{ id, url, caption, position, created_at, updated_at }] }
    """
    user_id = request.args.get('users_id')

    if not user_id:
        return jsonify({'error': 'users_id required'}), 400

    try:
        # Fetch photos ordered by position, then by created_at (newest first)
        photos = UserPhoto.query.filter_by(users_id=user_id)\
            .order_by(UserPhoto.position.asc(), desc(UserPhoto.created_at))\
            .all()

        result = []
        for photo in photos:
            photo_dict = photo.as_dict()
            photo_dict['url'] = patch_photo_url(photo_dict.get('url'))
            result.append(photo_dict)

        return jsonify({'result': result}), 200

    except Exception as e:
        print(f"Error fetching user photos: {e}")
        return jsonify({'error': 'Failed to fetch photos'}), 500


# POST: Upload new photo(s) for a user
@user_photos_bp.route('/photos', methods=['POST'])
@jwt_required
def api_upload_user_photo():
    """
    Upload new photo(s) for a user
    Body: { "users_id": int, "s3_gr_hash": str, "caption": str (optional) }
    Or: { "users_id": int, "photos": [{ "s3_gr_hash": str, "caption": str }] }
    Returns: { "result": "Photo(s) uploaded successfully" }

    Note: S3 upload should happen client-side first, then pass the s3_gr_hash here
    """
    data = request.get_json()
    current_user_id = g.current_user.id
    target_user_id = data.get('users_id')

    if not target_user_id:
        return jsonify({'error': 'users_id required'}), 400

    # Only allow users to upload photos to their own profile
    if current_user_id != int(target_user_id):
        return jsonify({'error': 'Permission denied'}), 403

    # Check photo count limit
    current_count = UserPhoto.query.filter_by(users_id=target_user_id).count()
    if current_count >= MAX_PHOTOS_PER_USER:
        return jsonify({'error': f'Maximum of {MAX_PHOTOS_PER_USER} photos allowed'}), 400

    try:
        # Handle single photo upload
        if 's3_gr_hash' in data:
            s3_gr_hash = data.get('s3_gr_hash')
            caption = data.get('caption', '')

            # Verify S3 content exists
            s3_content = S3Content.query.filter_by(gr_hash=s3_gr_hash).first()
            if not s3_content:
                return jsonify({'error': 'Invalid s3_gr_hash'}), 400

            # Get next position
            max_position = db.session.query(db.func.max(UserPhoto.position))\
                .filter_by(users_id=target_user_id).scalar() or 0

            new_photo = UserPhoto(
                users_id=target_user_id,
                s3_gr_hash=s3_gr_hash,
                caption=caption,
                position=max_position + 1
            )
            db.session.add(new_photo)

        # Handle multiple photo upload
        elif 'photos' in data and isinstance(data['photos'], list):
            max_position = db.session.query(db.func.max(UserPhoto.position))\
                .filter_by(users_id=target_user_id).scalar() or 0

            for idx, photo_data in enumerate(data['photos']):
                s3_gr_hash = photo_data.get('s3_gr_hash')
                caption = photo_data.get('caption', '')

                # Verify S3 content exists
                s3_content = S3Content.query.filter_by(gr_hash=s3_gr_hash).first()
                if not s3_content:
                    continue  # Skip invalid hashes

                new_photo = UserPhoto(
                    users_id=target_user_id,
                    s3_gr_hash=s3_gr_hash,
                    caption=caption,
                    position=max_position + idx + 1
                )
                db.session.add(new_photo)
        else:
            return jsonify({'error': 's3_gr_hash or photos array required'}), 400

        db.session.commit()
        return jsonify({'result': 'Photo(s) uploaded successfully'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error uploading user photo: {e}")
        return jsonify({'error': 'Failed to upload photo'}), 500


# DELETE: Delete specific photo(s)
@user_photos_bp.route('/photos', methods=['DELETE'])
@jwt_required
def api_delete_user_photos():
    """
    Delete specific photo(s) by ID
    Body: { "users_id": int, "photo_ids": [int, int, ...] }
    Returns: { "result": "Photo(s) deleted successfully" }
    """
    data = request.get_json()
    current_user_id = g.current_user.id
    target_user_id = data.get('users_id')
    photo_ids = data.get('photo_ids', [])

    if not target_user_id:
        return jsonify({'error': 'users_id required'}), 400

    if not isinstance(photo_ids, list) or not photo_ids:
        return jsonify({'error': 'photo_ids must be a non-empty list'}), 400

    # Only allow users to delete their own photos
    if current_user_id != int(target_user_id):
        return jsonify({'error': 'Permission denied'}), 403

    try:
        UserPhoto.query.filter(
            UserPhoto.users_id == target_user_id,
            UserPhoto.id.in_(photo_ids)
        ).delete(synchronize_session=False)

        db.session.commit()
        return jsonify({'result': 'Photo(s) deleted successfully'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error deleting user photos: {e}")
        return jsonify({'error': 'Failed to delete photo(s)'}), 500


# PUT: Reorder photos
@user_photos_bp.route('/photos/reorder', methods=['PUT'])
@jwt_required
def api_reorder_user_photos():
    """
    Reorder user photos
    Body: { "users_id": int, "photo_order": [{ "id": int, "position": int }] }
    Returns: { "result": "Photos reordered successfully" }
    """
    data = request.get_json()
    current_user_id = g.current_user.id
    target_user_id = data.get('users_id')
    photo_order = data.get('photo_order', [])

    if not target_user_id:
        return jsonify({'error': 'users_id required'}), 400

    if not isinstance(photo_order, list):
        return jsonify({'error': 'photo_order must be a list'}), 400

    # Only allow users to reorder their own photos
    if current_user_id != int(target_user_id):
        return jsonify({'error': 'Permission denied'}), 403

    try:
        for item in photo_order:
            photo_id = item.get('id')
            position = item.get('position')

            if photo_id and position is not None:
                photo = UserPhoto.query.filter_by(
                    id=photo_id,
                    users_id=target_user_id
                ).first()

                if photo:
                    photo.position = position

        db.session.commit()
        return jsonify({'result': 'Photos reordered successfully'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error reordering user photos: {e}")
        return jsonify({'error': 'Failed to reorder photos'}), 500


# POST: Upload photo via FormData (web app pattern)
@user_photos_bp.route('/photos/upload', methods=['POST'])
@jwt_required
def api_upload_user_photo_file():
    """
    Upload a photo via FormData (handles S3 upload + S3Content + UserPhoto creation).
    FormData fields:
      - photo: File (required)
      - caption: str (optional, max 500 chars)
    Returns: { "result": { id, url, caption, position, created_at, updated_at } }
    """
    current_user_id = g.current_user.id

    if 'photo' not in request.files:
        return jsonify({'error': 'No photo file provided'}), 400

    file = request.files['photo']
    if not file or not file.filename:
        return jsonify({'error': 'No file selected'}), 400

    if not allowed_file(file.filename):
        return jsonify({'error': 'Invalid file type. Allowed: png, jpg, jpeg, gif, webp'}), 400

    # Check file size
    file.seek(0, 2)  # Seek to end
    file_size = file.tell()
    file.seek(0)  # Reset to beginning
    if file_size > MAX_FILE_SIZE_BYTES:
        return jsonify({'error': 'File too large. Maximum size is 10 MB'}), 400

    # Check photo count limit
    current_count = UserPhoto.query.filter_by(users_id=current_user_id).count()
    if current_count >= MAX_PHOTOS_PER_USER:
        return jsonify({'error': f'Maximum of {MAX_PHOTOS_PER_USER} photos allowed'}), 400

    caption = request.form.get('caption', '').strip()
    if len(caption) > 500:
        return jsonify({'error': 'Caption must be 500 characters or less'}), 400

    try:
        # 1. Upload to S3 (using put_object to avoid threading issues with eventlet)
        unique_filename = f"user_photo_{current_user_id}_{uuid.uuid4().hex}_{secure_filename(file.filename)}"
        file.seek(0)
        file_content = file.read()
        s3.put_object(Bucket=S3_BUCKET, Key=unique_filename, Body=file_content, ContentType=file.mimetype)
        s3_url = f"{S3_BASE_URL}{unique_filename}"

        # 2. Create S3Content record (tbl_index=7 for user photos)
        gr_hash = f"{uuid.uuid4().hex}_{unique_filename}"
        s3_content = S3Content(
            gr_hash=gr_hash,
            tbl_id=current_user_id,
            tbl_index=7,
            key=unique_filename,
            url=s3_url,
            file_type=file.mimetype,
            file_size=None
        )
        db.session.add(s3_content)
        db.session.flush()

        # 3. Create UserPhoto record
        max_position = db.session.query(db.func.max(UserPhoto.position))\
            .filter_by(users_id=current_user_id).scalar() or 0

        new_photo = UserPhoto(
            users_id=current_user_id,
            s3_gr_hash=gr_hash,
            caption=caption if caption else None,
            position=max_position + 1
        )
        db.session.add(new_photo)
        db.session.commit()

        # 4. Return the full photo dict
        photo_dict = new_photo.as_dict()
        photo_dict['url'] = patch_photo_url(photo_dict.get('url'))
        return jsonify({'result': photo_dict}), 201

    except Exception as e:
        db.session.rollback()
        print(f"Error uploading user photo file: {e}")
        return jsonify({'error': 'Failed to upload photo'}), 500


# DELETE: Delete a single photo by ID (URL param)
@user_photos_bp.route('/photos/<int:photo_id>', methods=['DELETE'])
@jwt_required
def api_delete_single_photo(photo_id):
    """
    Delete a single photo by ID. Only the photo owner can delete.
    Returns: { "result": "Photo deleted successfully" }
    """
    current_user_id = g.current_user.id

    photo = UserPhoto.query.get(photo_id)
    if not photo:
        return jsonify({'error': 'Photo not found'}), 404

    if photo.users_id != current_user_id:
        return jsonify({'error': 'Permission denied'}), 403

    try:
        db.session.delete(photo)
        db.session.commit()
        return jsonify({'result': 'Photo deleted successfully'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error deleting user photo: {e}")
        return jsonify({'error': 'Failed to delete photo'}), 500
