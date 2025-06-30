# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.Purpose_Models.PortalTexts import PortalText
from app.utils.portal_permissions import check_portal_editor_permission
from app.utils.auth import jwt_required

portal_bp = Blueprint('portal_texts', __name__)

# GET: Get all text sections for a portal
@portal_bp.route('/texts', methods=['GET'])
@jwt_required
def api_get_portal_texts():
    portal_id = request.args.get('portal_id')
    user_id = g.current_user.id or request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id required!'}), 400

    texts = PortalText.query.filter_by(portal_id=portal_id).all()
    result = [t.as_dict() for t in texts]
    return jsonify({'result': result})

# POST: Add or update text sections for a portal (replaces all)
@portal_bp.route('/texts', methods=['POST'])
@jwt_required
def api_add_update_portal_texts():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    portal_id = data.get('portal_id')
    texts = data.get('aTexts')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id required!'}), 400
    if not isinstance(texts, list):
        return jsonify({'error': 'aTexts must be a list'}), 400

    if not check_portal_editor_permission(user_id, portal_id):
        return jsonify({'error': 'Permission denied'}), 403

    # Remove all existing texts for this portal
    PortalText.query.filter_by(portal_id=portal_id).delete(synchronize_session=False)

    # Add new texts
    for text_obj in texts:
        title = text_obj.get('title', '').strip()
        text = text_obj.get('text', '').strip()
        section = text_obj.get('section', '').strip()
        if title or text:
            new_text = PortalText(portal_id=portal_id, title=title, text=text, section=section)
            db.session.add(new_text)

    db.session.commit()
    return jsonify({'result': 'Portal texts updated'})

# DELETE: Delete specific text sections by IDs
@portal_bp.route('/texts', methods=['DELETE'])
@jwt_required
def api_delete_portal_texts():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    portal_id = data.get('portal_id')
    text_ids = data.get('aTextIDs')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id required!'}), 400
    if not isinstance(text_ids, list) or not text_ids:
        return jsonify({'error': 'aTextIDs must be a non-empty list'}), 400

    if not check_portal_editor_permission(user_id, portal_id):
        return jsonify({'error': 'Permission denied'}), 403

    PortalText.query.filter(PortalText.portal_id == portal_id, PortalText.id.in_(text_ids)).delete(synchronize_session=False)
    db.session.commit()
    return jsonify({'result': 'Selected portal texts deleted'})
