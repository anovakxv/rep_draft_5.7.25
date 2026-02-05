# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.Purpose_Models.PortalGraphicSection import PortalGraphicSection
from app.models.s3Content_Models.s3Content import S3Content, PortalGraphicSectionS3Content
from app.utils.portal_permissions import check_portal_editor_permission
from app.utils.auth import jwt_required
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

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

portal_bp = Blueprint('portal_graphic_sections', __name__)

# GET: List all graphic sections (with files) for a portal
@portal_bp.route('/graphic_sections', methods=['GET'])
@jwt_required
def api_get_portal_graphic_sections():
    portal_id = request.args.get('portal_id')
    user_id = g.current_user.id or request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id required!'}), 400

    sections = PortalGraphicSection.query.filter_by(portals_id=portal_id).all()
    section_ids = [section.id for section in sections]
    files = S3Content.query.filter(S3Content.tbl_index == 6, S3Content.tbl_id.in_(section_ids)).all()
    files_by_section = {}
    for f in files:
        file_url = f.url
        if file_url and not file_url.startswith("http"):
            file_url = S3_BASE_URL + file_url
        files_by_section.setdefault(f.tbl_id, []).append({
            'id': f.id,
            'gr_hash': f.gr_hash,
            'key': f.key,
            'url': file_url
        })
    result = []
    for section in sections:
        result.append({
            'id': section.id,
            'title': section.title,
            'position': section.position,
            'content': section.content,
            'aFiles': files_by_section.get(section.id, [])
        })
    return jsonify({'result': result})

# POST: Add or update graphic sections and their files
@portal_bp.route('/graphic_sections', methods=['POST'])
@jwt_required
def api_add_update_portal_graphic_sections():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    portal_id = data.get('portal_id')
    sections = data.get('aSections')
    if not user_id or not portal_id or not isinstance(sections, list) or not sections:
        return jsonify({'error': 'Missing or invalid parameters'}), 400
    if not check_portal_editor_permission(user_id, portal_id):
        return jsonify({'error': 'Permission denied'}), 403

    aLog = []
    for idx, section in enumerate(sections):
        section_id = section.get('id')
        title = section.get('title', '')
        position = section.get('position')
        content = section.get('content', '')
        indexes = section.get('indexes', '')

        # Find or create section
        if section_id:
            pgs = PortalGraphicSection.query.filter_by(id=section_id, portals_id=portal_id).first()
            if not pgs:
                aLog.append({'error': 'portal_graphic_section_id not found', 'index': idx})
                continue
            if title:
                pgs.title = title
            if position is not None:
                pgs.position = position
            if content is not None:
                pgs.content = content
        else:
            pgs = PortalGraphicSection(portals_id=portal_id, title=title, position=position, content=content)
            db.session.add(pgs)
            db.session.flush()  # Get id before commit

        # Remove existing S3 content links for this section (if updating)
        PortalGraphicSectionS3Content.query.filter_by(portals_graphic_sections_id=pgs.id).delete(synchronize_session=False)

        file_indexes = [i.strip() for i in indexes.split(',') if i.strip()]
        files_log = []
        for gr_hash in file_indexes:
            s3_file = S3Content.query.filter_by(gr_hash=gr_hash, tbl_index=6).first()
            if s3_file:
                link = PortalGraphicSectionS3Content(
                    portals_graphic_sections_id=pgs.id,
                    s3_gr_hash=gr_hash
                )
                db.session.add(link)
                files_log.append({'gr_hash': gr_hash})
            else:
                files_log.append({'gr_hash': gr_hash, 'error': 'S3 file not found'})
        aLog.append({'portal_graphic_section_id': pgs.id, 'aFiles': files_log})
    db.session.commit()
    return jsonify({'result': aLog})

# DELETE: Delete graphic sections and their files
@portal_bp.route('/graphic_sections', methods=['DELETE'])
@jwt_required
def api_delete_portal_graphic_sections():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    section_ids = data.get('aSectionIDs')
    if not user_id or not isinstance(section_ids, list) or not section_ids:
        return jsonify({'error': 'Missing or invalid parameters'}), 400
    sections = PortalGraphicSection.query.filter(PortalGraphicSection.id.in_(section_ids)).all()
    for section in sections:
        if not check_portal_editor_permission(user_id, section.portals_id):
            return jsonify({'error': 'Permission denied'}), 403
    # Delete links and files
    PortalGraphicSectionS3Content.query.filter(
        PortalGraphicSectionS3Content.portals_graphic_sections_id.in_(section_ids)
    ).delete(synchronize_session=False)
    PortalGraphicSection.query.filter(
        PortalGraphicSection.id.in_(section_ids)
    ).delete(synchronize_session=False)
    db.session.commit()
    return jsonify({'result': section_ids})

# DELETE: Delete specific files by group hash
@portal_bp.route('/graphic_files', methods=['DELETE'])
@jwt_required
def api_delete_portal_graphic_files():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    group_hashes = data.get('aGroupHash')
    if not user_id or not isinstance(group_hashes, list) or not group_hashes:
        return jsonify({'error': 'Missing or invalid parameters'}), 400
    s3_files = S3Content.query.filter(
        S3Content.gr_hash.in_(group_hashes),
        S3Content.tbl_index == 6
    ).all()
    portal_ids = db.session.query(PortalGraphicSection.portals_id).filter(
        PortalGraphicSection.id.in_([f.tbl_id for f in s3_files])
    ).distinct().all()
    for pid_tuple in portal_ids:
        pid = pid_tuple[0]
        if not check_portal_editor_permission(user_id, pid):
            return jsonify({'error': 'Permission denied'}), 403
    PortalGraphicSectionS3Content.query.filter(
        PortalGraphicSectionS3Content.s3_gr_hash.in_(group_hashes)
    ).delete(synchronize_session=False)
    for s3_file in s3_files:
        db.session.delete(s3_file)
    db.session.commit()
    return jsonify({'result': group_hashes})


# POST: Upload images to a graphic section via FormData (web app pattern)
@portal_bp.route('/graphic_sections/upload', methods=['POST'])
@jwt_required
def api_upload_graphic_section_images():
    """
    Upload images to a new or existing graphic section via FormData.
    FormData fields:
      - portal_id: int (required)
      - title: str (required for new section)
      - section_id: int (optional — if provided, adds images to existing section)
      - images: File[] (required, one or more image files)
    Returns: { "result": { id, title, position, content, aFiles: [...] } }
    """
    user_id = g.current_user.id
    portal_id = request.form.get('portal_id')
    section_id = request.form.get('section_id')
    title = request.form.get('title', '').strip()

    if not portal_id:
        return jsonify({'error': 'portal_id required'}), 400

    if not check_portal_editor_permission(user_id, int(portal_id)):
        return jsonify({'error': 'Permission denied'}), 403

    images = request.files.getlist('images')
    if not images or not images[0].filename:
        return jsonify({'error': 'At least one image file is required'}), 400

    try:
        # Find or create section
        if section_id:
            section = PortalGraphicSection.query.filter_by(
                id=int(section_id), portals_id=int(portal_id)
            ).first()
            if not section:
                return jsonify({'error': 'Section not found'}), 404
            # Update title if provided
            if title:
                section.title = title
        else:
            if not title:
                return jsonify({'error': 'title required for new section'}), 400
            # Get next position
            max_pos = db.session.query(db.func.max(PortalGraphicSection.position))\
                .filter_by(portals_id=int(portal_id)).scalar() or 0
            section = PortalGraphicSection(
                portals_id=int(portal_id),
                title=title,
                position=max_pos + 1
            )
            db.session.add(section)
            db.session.flush()

        # Upload each image
        for img in images:
            if not img.filename or not allowed_file(img.filename):
                continue

            unique_filename = f"{portal_id}_{uuid.uuid4().hex}_{secure_filename(img.filename)}"
            img.seek(0)
            s3.upload_fileobj(img, S3_BUCKET, unique_filename)
            s3_url = f"{S3_BASE_URL}{unique_filename}"
            gr_hash = f"{uuid.uuid4().hex}_{unique_filename}"

            s3_content = S3Content(
                gr_hash=gr_hash,
                tbl_id=section.id,
                tbl_index=6,
                key=unique_filename,
                url=s3_url,
                file_type=img.mimetype,
                file_size=None
            )
            db.session.add(s3_content)
            db.session.flush()

            link = PortalGraphicSectionS3Content(
                portals_graphic_sections_id=section.id,
                s3_gr_hash=gr_hash
            )
            db.session.add(link)

        db.session.commit()

        # Build response with all files for this section
        files = S3Content.query.filter(S3Content.tbl_index == 6, S3Content.tbl_id == section.id).all()
        a_files = []
        for f in files:
            file_url = f.url
            if file_url and not file_url.startswith("http"):
                file_url = S3_BASE_URL + file_url
            a_files.append({
                'id': f.id,
                'gr_hash': f.gr_hash,
                'key': f.key,
                'url': file_url
            })

        return jsonify({'result': {
            'id': section.id,
            'title': section.title,
            'position': section.position,
            'content': section.content,
            'aFiles': a_files
        }}), 201

    except Exception as e:
        db.session.rollback()
        print(f"Error uploading graphic section images: {e}")
        return jsonify({'error': 'Failed to upload images'}), 500


# DELETE: Delete a single graphic section by ID (URL param)
@portal_bp.route('/graphic_sections/<int:section_id>', methods=['DELETE'])
@jwt_required
def api_delete_single_graphic_section(section_id):
    """
    Delete a single graphic section by ID. Only portal editors can delete.
    Returns: { "result": "Section deleted successfully" }
    """
    user_id = g.current_user.id

    section = PortalGraphicSection.query.get(section_id)
    if not section:
        return jsonify({'error': 'Section not found'}), 404

    if not check_portal_editor_permission(user_id, section.portals_id):
        return jsonify({'error': 'Permission denied'}), 403

    try:
        # Delete association links
        PortalGraphicSectionS3Content.query.filter_by(
            portals_graphic_sections_id=section_id
        ).delete(synchronize_session=False)
        # Delete section
        db.session.delete(section)
        db.session.commit()
        return jsonify({'result': 'Section deleted successfully'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error deleting graphic section: {e}")
        return jsonify({'error': 'Failed to delete section'}), 500


# DELETE: Delete a single graphic file by gr_hash (URL param)
@portal_bp.route('/graphic_file/<path:gr_hash>', methods=['DELETE'])
@jwt_required
def api_delete_single_graphic_file(gr_hash):
    """
    Delete a single graphic file by gr_hash. Only portal editors can delete.
    Returns: { "result": "File deleted successfully" }
    """
    user_id = g.current_user.id

    s3_file = S3Content.query.filter_by(gr_hash=gr_hash, tbl_index=6).first()
    if not s3_file:
        return jsonify({'error': 'File not found'}), 404

    # Check permission on the section's portal
    section = PortalGraphicSection.query.get(s3_file.tbl_id)
    if not section or not check_portal_editor_permission(user_id, section.portals_id):
        return jsonify({'error': 'Permission denied'}), 403

    try:
        # Remove association link
        PortalGraphicSectionS3Content.query.filter_by(
            s3_gr_hash=gr_hash
        ).delete(synchronize_session=False)
        # Delete S3Content record
        db.session.delete(s3_file)
        db.session.commit()
        return jsonify({'result': 'File deleted successfully'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error deleting graphic file: {e}")
        return jsonify({'error': 'Failed to delete file'}), 500