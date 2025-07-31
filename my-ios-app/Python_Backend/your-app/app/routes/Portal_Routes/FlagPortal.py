from flask import Blueprint, request, jsonify, g
from app import db
from app.models.Purpose_Models.FlaggedPortal import FlaggedPortal
from app.models.Purpose_Models.Portal import Portal
from app.utils.auth import jwt_required

portal_bp = Blueprint('flag_portal', __name__)

@portal_bp.route('/flag_portal', methods=['POST'])
@jwt_required
def flag_portal():
    data = request.get_json()
    user_id = g.current_user.id
    portal_id = data.get('portal_id')
    reason = data.get('reason', '')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id is empty!'}), 400
    if not Portal.query.filter_by(id=portal_id).first():
        return jsonify({'error': "That portal_id doesn't exist!"}), 404

    exists = FlaggedPortal.query.filter_by(flagger_id=user_id, portal_id=portal_id).first()
    if exists:
        return jsonify({'error': 'You have already flagged this portal.'}), 400

    flagged = FlaggedPortal(flagger_id=user_id, portal_id=portal_id, reason=reason)
    db.session.add(flagged)
    db.session.commit()
    return jsonify({'result': 'flagged'})