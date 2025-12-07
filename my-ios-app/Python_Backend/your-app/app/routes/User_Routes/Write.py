# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Write_Models.Writings_Model import Write
from app.utils.auth import jwt_required
import html
import re

# Import bleach for HTML sanitization
try:
    import bleach
    HAS_BLEACH = True
except ImportError:
    HAS_BLEACH = False
    print("WARNING: bleach not installed. Using basic HTML sanitization. Install with: pip install bleach")

user_bp = Blueprint('user_writes', __name__)

# --- Helper Functions ---

def sanitize_html(content):
    """
    Sanitize HTML content to prevent XSS attacks.
    Uses bleach library if available, otherwise falls back to basic regex.

    Allows only safe HTML tags for formatting.
    """
    if HAS_BLEACH:
        # Use bleach for robust HTML sanitization (recommended)
        allowed_tags = [
            'p', 'br', 'strong', 'b', 'em', 'i', 'u', 's', 'strike',
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
            'ul', 'ol', 'li',
            'a', 'blockquote', 'pre', 'code',
            'hr', 'div', 'span'
        ]

        allowed_attrs = {
            'a': ['href', 'title', 'target'],
            'code': ['class'],  # For syntax highlighting classes
        }

        allowed_protocols = ['http', 'https', 'mailto']

        # Clean HTML with bleach
        cleaned = bleach.clean(
            content,
            tags=allowed_tags,
            attributes=allowed_attrs,
            protocols=allowed_protocols,
            strip=True  # Strip disallowed tags instead of escaping
        )

        return cleaned
    else:
        # Fallback to basic regex sanitization (less secure)
        # Remove script tags and dangerous attributes
        content = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.IGNORECASE | re.DOTALL)
        content = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.IGNORECASE | re.DOTALL)
        content = re.sub(r'on\w+="[^"]*"', '', content, flags=re.IGNORECASE)  # Remove event handlers
        content = re.sub(r'on\w+=\'[^\']*\'', '', content, flags=re.IGNORECASE)  # Single quotes too
        content = re.sub(r'javascript:', '', content, flags=re.IGNORECASE)

        return content

def detect_format(content):
    """
    Auto-detect if content is HTML or plain text.
    Returns 'html' or 'plain'
    """
    if not content:
        return 'plain'

    # Check for HTML tags
    html_pattern = r'<(p|br|div|strong|b|em|i|u|h[1-6]|ul|ol|li|a|blockquote|pre|code)[^>]*>'
    if re.search(html_pattern, content, re.IGNORECASE):
        return 'html'

    return 'plain'

# --- 1. List all writes for a user ---
@user_bp.route('/writes', methods=['GET'])
@jwt_required
def get_user_writes():
    """
    Get all writes for a user.

    Query params:
    - users_id (int): User ID to get writes for
    - format (str, optional): 'plain' or 'html' - filter by format

    Returns:
    - result: List of write objects with content_format field
    """
    users_id = request.args.get('users_id', type=int)
    format_filter = request.args.get('format', type=str)

    if not users_id:
        return jsonify({'error': 'users_id required'}), 400

    query = Write.query.filter_by(users_id=users_id)

    # Optional: filter by format
    if format_filter in ['plain', 'html']:
        query = query.filter_by(content_format=format_filter)

    writes = query.order_by(Write.order.asc(), Write.created_at.desc()).all()
    result = [w.as_dict() for w in writes]

    return jsonify({'result': result})

# --- 2. Add a new write block ---
@user_bp.route('/write', methods=['POST'])
@jwt_required
def add_user_write():
    """
    Create a new write block.

    Body params:
    - title (str, optional): Title of the write
    - content (str, required): Content text
    - content_format (str, optional): 'plain' or 'html' (default: auto-detected)
    - order (int, optional): Order number (default: 0)
    - status (str, optional): 'draft' or 'published' (default: 'published')

    Returns:
    - result: Created write object
    """
    users_id = g.current_user.id
    data = request.get_json()

    title = data.get('title', '').strip()
    content = data.get('content', '').strip()
    order = data.get('order', 0)
    status = data.get('status', 'published')

    # Get content format (user-specified or auto-detected)
    content_format = data.get('content_format', '').lower()
    if content_format not in ['plain', 'html']:
        content_format = detect_format(content)

    if not users_id or not content:
        return jsonify({'error': 'Missing user or content'}), 400

    # Sanitize HTML content to prevent XSS
    if content_format == 'html':
        content = sanitize_html(content)

    write = Write(
        users_id=users_id,
        title=title,
        content=content,
        content_format=content_format,
        order=order,
        status=status
    )

    db.session.add(write)
    db.session.commit()

    return jsonify({'result': write.as_dict()})

# --- 3. Edit a write block ---
@user_bp.route('/write/<int:write_id>', methods=['PUT'])
@jwt_required
def edit_user_write(write_id):
    """
    Update an existing write block.

    Body params:
    - title (str, optional): New title
    - content (str, optional): New content
    - content_format (str, optional): 'plain' or 'html'
    - order (int, optional): New order
    - status (str, optional): New status

    Returns:
    - result: Updated write object
    """
    users_id = g.current_user.id
    write = Write.query.get(write_id)

    if not write or write.users_id != users_id:
        return jsonify({'error': 'Write not found or unauthorized'}), 404

    data = request.get_json()

    # Update title
    if 'title' in data:
        write.title = data.get('title', write.title)

    # Update content
    if 'content' in data:
        content = data.get('content', write.content)

        # Get or detect format
        if 'content_format' in data:
            content_format = data.get('content_format', '').lower()
            if content_format not in ['plain', 'html']:
                content_format = detect_format(content)
        else:
            # If format not specified, keep existing or auto-detect
            content_format = getattr(write, 'content_format', None) or detect_format(content)

        # Sanitize HTML content
        if content_format == 'html':
            content = sanitize_html(content)

        write.content = content
        write.content_format = content_format

    # Update order
    if 'order' in data:
        write.order = data.get('order', write.order)

    # Update status
    if 'status' in data:
        write.status = data.get('status', write.status)

    db.session.commit()

    return jsonify({'result': write.as_dict()})

# --- 4. Delete a write block ---
@user_bp.route('/write/<int:write_id>', methods=['DELETE'])
@jwt_required
def delete_user_write(write_id):
    users_id = g.current_user.id
    write = Write.query.get(write_id)
    if not write or write.users_id != users_id:
        return jsonify({'error': 'Write not found or unauthorized'}), 404
    db.session.delete(write)
    db.session.commit()
    return jsonify({'result': 'Write deleted'})
