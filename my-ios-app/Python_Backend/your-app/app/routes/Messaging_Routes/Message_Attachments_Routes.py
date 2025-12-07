# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Routes for message attachments (file uploads)

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.Message_Attachments import MessageAttachment
from app.utils.auth import jwt_required
import boto3
import os
from werkzeug.utils import secure_filename
from datetime import datetime

attachments_bp = Blueprint('message_attachments', __name__)

# --- Helper Functions ---

def upload_to_s3(file, user_id):
    """
    Upload file to S3 and return the URL.
    Uses existing S3 configuration from environment variables.
    """
    try:
        s3_client = boto3.client(
            's3',
            aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
            region_name=os.environ.get('AWS_REGION', 'us-east-1')
        )

        bucket_name = os.environ.get('S3_BUCKET_NAME')
        if not bucket_name:
            raise ValueError("S3_BUCKET_NAME not configured")

        # Generate unique filename
        filename = secure_filename(file.filename)
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        s3_key = f"message_attachments/user_{user_id}/{timestamp}_{filename}"

        # Upload file
        s3_client.upload_fileobj(
            file,
            bucket_name,
            s3_key,
            ExtraArgs={'ContentType': file.content_type} if file.content_type else {}
        )

        # Generate URL
        file_url = f"https://{bucket_name}.s3.amazonaws.com/{s3_key}"

        return file_url, filename, file.content_type, file.content_length

    except Exception as e:
        print(f"S3 upload error: {str(e)}")
        raise


# --- 1. Add attachment to a message ---
@attachments_bp.route('/message/<int:message_id>/attachment', methods=['POST'])
@jwt_required
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
@attachments_bp.route('/message/<int:message_id>/attachments', methods=['GET'])
@jwt_required
def get_message_attachments(message_id):
    """
    Get all attachments for a message.

    Returns:
    - result: List of attachment objects
    """
    message = DirectMessage.query.get(message_id)

    if not message:
        return jsonify({'error': 'Message not found'}), 404

    attachments = MessageAttachment.query.filter_by(message_id=message_id).all()

    return jsonify({'result': [a.as_dict() for a in attachments]})


# --- 3. Delete an attachment ---
@attachments_bp.route('/message/<int:message_id>/attachment/<int:attachment_id>', methods=['DELETE'])
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
    attachment = MessageAttachment.query.get(attachment_id)

    if not attachment:
        return jsonify({'error': 'Attachment not found'}), 404

    return jsonify({'result': attachment.as_dict()})
