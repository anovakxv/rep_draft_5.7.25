# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Routes for message attachments (file uploads)

from flask import Blueprint, request, jsonify, g
from app import db, limiter
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.Message_Attachments import MessageAttachment
from app.utils.auth import jwt_required
import os
from werkzeug.utils import secure_filename
from datetime import datetime

attachments_bp = Blueprint('message_attachments', __name__)

# --- Helper Functions ---

MAX_ATTACHMENT_SIZE = 50 * 1024 * 1024  # 50 MB
ALLOWED_MIME_TYPES = {
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf', 'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
}

def upload_to_s3(file, user_id):
    """
    Upload file to S3 and return the URL.
    Uses existing S3 configuration from environment variables.
    """
    try:
        from app.utils.s3 import s3
        bucket_name = os.environ.get('S3_BUCKET_NAME', 'rep-app-dbbucket')

        # Validate MIME type
        if file.content_type not in ALLOWED_MIME_TYPES:
            raise ValueError(f"File type {file.content_type} not allowed. Allowed types: images, PDF, plain text, Word documents.")

        # Check file size before uploading
        file.seek(0, 2)
        file_size = file.tell()
        file.seek(0)
        if file_size > MAX_ATTACHMENT_SIZE:
            raise ValueError(f"File too large. Maximum size is 50MB.")

        # Generate unique filename
        filename = secure_filename(file.filename)
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        s3_key = f"message_attachments/user_{user_id}/{timestamp}_{filename}"

        extra = {'ContentType': file.content_type} if file.content_type else {}
        s3.put_object(Body=file.read(), Bucket=bucket_name, Key=s3_key, **extra)

        file_url = f"https://{bucket_name}.s3.amazonaws.com/{s3_key}"

        return file_url, filename, file.content_type, file_size

    except Exception as e:
        print(f"S3 upload error: {str(e)}")
        raise


# --- 1. Add attachment to a message ---
@attachments_bp.route('/<int:message_id>/attachment', methods=['POST'])
@jwt_required
@limiter.limit("20 per hour")
def add_attachment(message_id):
    """
    Add a file attachment to a message.
    Uploads file to S3 and creates attachment record.

    Form data:
    - file (file, required): File to upload

    Returns:
    - result: Created attachment object
    """
    user_id = g.current_user.id

    # Check if message exists and user is sender
    message = DirectMessage.query.get(message_id)
    if not message:
        return jsonify({'error': 'Message not found'}), 404

    if message.sender_id != user_id:
        return jsonify({'error': 'Can only add attachments to your own messages'}), 403

    # Check if file is present
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    # Upload to S3
    try:
        file_url, file_name, file_type, file_size = upload_to_s3(file, user_id)
    except Exception as e:
        return jsonify({'error': f'Upload failed: {str(e)}'}), 500

    # Create attachment record
    attachment = MessageAttachment(
        message_id=message_id,
        file_url=file_url,
        file_name=file_name,
        file_type=file_type,
        file_size=file_size
    )

    db.session.add(attachment)
    db.session.commit()

    return jsonify({'result': attachment.as_dict()}), 201


# --- 2. Get all attachments for a message ---
@attachments_bp.route('/<int:message_id>/attachments', methods=['GET'])
@jwt_required
def get_message_attachments(message_id):
    """
    Get all attachments for a message.

    Returns:
    - result: List of attachment objects
    """
    user_id = g.current_user.id
    message = DirectMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    if message.sender_id != user_id and message.recipient_id != user_id:
        return jsonify({'error': 'Access denied'}), 403

    attachments = MessageAttachment.query.filter_by(message_id=message_id).all()

    return jsonify({'result': [a.as_dict() for a in attachments]})


# --- 3. Delete an attachment ---
@attachments_bp.route('/<int:message_id>/attachment/<int:attachment_id>', methods=['DELETE'])
@jwt_required
def delete_attachment(message_id, attachment_id):
    """
    Delete a file attachment.
    Only message sender can delete attachments.
    Note: This removes the database record but does NOT delete from S3 (for safety).

    Returns:
    - result: Success message
    """
    user_id = g.current_user.id

    attachment = MessageAttachment.query.get(attachment_id)

    if not attachment:
        return jsonify({'error': 'Attachment not found'}), 404

    if attachment.message_id != message_id:
        return jsonify({'error': 'Attachment does not belong to this message'}), 400

    # Check if user owns the message
    message = DirectMessage.query.get(message_id)
    if not message or message.sender_id != user_id:
        return jsonify({'error': 'Can only delete attachments from your own messages'}), 403

    # Delete attachment record (but keep S3 file for safety)
    db.session.delete(attachment)
    db.session.commit()

    return jsonify({'result': 'Attachment deleted'})


# --- 4. Get attachment info (without downloading) ---
@attachments_bp.route('/attachment/<int:attachment_id>', methods=['GET'])
@jwt_required
def get_attachment_info(attachment_id):
    """
    Get information about a specific attachment.

    Returns:
    - result: Attachment object with URL, filename, size, etc.
    """
    user_id = g.current_user.id
    attachment = MessageAttachment.query.get(attachment_id)

    if not attachment:
        return jsonify({'error': 'Attachment not found'}), 404

    message = DirectMessage.query.get(attachment.message_id)
    if not message or (message.sender_id != user_id and message.recipient_id != user_id):
        return jsonify({'error': 'Access denied'}), 403

    return jsonify({'result': attachment.as_dict()})
