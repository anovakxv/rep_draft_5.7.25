# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.Purpose_Models.PortalGraphicSection import PortalGraphicSection
from app.models.s3Content_Models.s3Content import S3Content, PortalGraphicSectionS3Content
from app.utils.portal_permissions import check_portal_editor_permission
from app.utils.auth import jwt_required

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

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