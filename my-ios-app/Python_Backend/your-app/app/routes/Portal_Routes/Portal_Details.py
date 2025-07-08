# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.Purpose_Models.Portal import Portal
from app.models.ValueMetric_Models.Goal import Goal
from app.models.Purpose_Models.PortalUser import PortalUser
from app.models.Purpose_Models.PortalTexts import PortalText
from app.models.People_Models.user import User
from app.models.Purpose_Models.PortalGraphicSection import PortalGraphicSection
from app.models.s3Content_Models.s3Content import S3Content, PortalGraphicSectionS3Content
from app.utils.portal_permissions import check_portal_editor_permission
from sqlalchemy.orm import joinedload, subqueryload
from sqlalchemy import func
from datetime import datetime
from app.utils.auth import jwt_required
from werkzeug.utils import secure_filename
import uuid

portal_bp = Blueprint('portal', __name__)

# GET: Portal details
@portal_bp.route('/details', methods=['GET'])
@jwt_required
def api_portal_details():
    # Accept both 'portal_id' and 'portals_id'
    portal_id = request.args.get('portal_id', type=int) or request.args.get('portals_id', type=int)
    user_id = g.current_user.id or request.args.get('user_id', type=int)

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id required!'}), 400

    portal = Portal.query.options(
        joinedload(Portal.creator),
        joinedload(Portal.lead),
        joinedload(Portal.category),
        joinedload(Portal.city),
        subqueryload(Portal.portal_users),
        subqueryload(Portal.portal_texts),
        subqueryload(Portal.graphic_sections)
    ).filter_by(id=portal_id).first()
    if not portal:
        return jsonify({'error': "The portal doesn't exist"}), 404

    # Batch fetch S3 files for all sections
    sections = portal.graphic_sections
    section_ids = [section.id for section in sections]
    files_by_section = {}
    if section_ids:
        files = S3Content.query.filter(S3Content.tbl_index == 6, S3Content.tbl_id.in_(section_ids)).all()
        for f in files:
            files_by_section.setdefault(f.tbl_id, []).append({
                'id': f.id,
                'gr_hash': f.gr_hash,
                'key': f.key,
                'url': f.url
            })

    # Compose sections with files
    aSections = []
    for section in sections:
        aSections.append({
            'id': section.id,
            'title': section.title,
            'aFiles': files_by_section.get(section.id, [])
        })

    # Compose users (owners and portal users)
    portal_users = portal.portal_users
    user_ids = set([portal.users_id] + [pu.user_id for pu in portal_users])
    users = User.query.filter(User.id.in_(user_ids)).all()

    # Compose goals
    goals = Goal.query.filter_by(portals_id=portal.id).order_by(Goal.id.desc()).all()

    # Compose portal texts
    texts = portal.portal_texts

    # Identify the main image (first file of the first section)
    main_image_url = portal.main_image_url

    portal_data = {
        'id': portal.id,
        'name': portal.name,
        'subtitle': portal.subtitle,
        'about': portal.about,
        'categories_id': portal.categories_id,
        'cities_id': portal.cities_id,
        'lead_id': portal.lead_id,
        'users_id': portal.users_id,
        '_c_users_count': getattr(portal, '_c_users_count', None),
        'mainImageUrl': main_image_url,
        'aGoals': [g.as_dict() for g in goals],
        'aPortalUsers': [pu.as_dict() for pu in portal_users],
        'aTexts': [t.as_dict() for t in texts],
        'aSections': aSections,
        'aUsers': [u.as_dict() for u in users]
    }

    return jsonify({'result': portal_data})

# POST: Create portal (with optional images)
@portal_bp.route('/', methods=['POST'])
@jwt_required
def api_create_portal():
    if request.content_type and request.content_type.startswith('multipart/form-data'):
        data = request.form
    else:
        data = request.get_json()
    required_fields = ['name', 'about']
    if not data or not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400

    user_id = g.current_user.id or data.get('users_id')
    if not user_id:
        return jsonify({'error': 'users_id required'}), 400

    # Check for duplicate portal name for this user
    if Portal.query.filter_by(name=data['name'], users_id=user_id).first():
        return jsonify({'error': 'Portal name already exists for this user'}), 400

    try:
        portal = Portal(
            name=data['name'],
            about=data.get('about'),
            subtitle=data.get('subtitle'),
            users_id=user_id,
            lead_id=data.get('lead_id'),
            categories_id=data.get('categories_id'),
            cities_id=data.get('cities_id'),
            visible=data.get('visible', True),
            status='active',
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        db.session.add(portal)
        db.session.flush()  # Get portal.id before commit

        # Handle images (uploaded files)
        images = request.files.getlist('images')
        if images:
            main_section = PortalGraphicSection(portals_id=portal.id, title="Main Section", position=1)
            db.session.add(main_section)
            db.session.flush()
            for img in images:
                filename = secure_filename(img.filename)
                # Here you would upload to S3 and get the URL and gr_hash
                # For demo, use filename as gr_hash and url
                s3_url = f"https://your-s3-bucket/{filename}"
                gr_hash = f"{uuid.uuid4().hex}_{filename}"
                img.seek(0)
                s3_content = S3Content(
                    gr_hash=gr_hash,
                    tbl_id=main_section.id,
                    tbl_index=6,
                    key=filename,
                    url=s3_url,
                    file_type=img.mimetype,
                    file_size=len(img.read())
                )
                img.seek(0)
                db.session.add(s3_content)
                db.session.flush()
                link = PortalGraphicSectionS3Content(
                    portals_graphic_sections_id=main_section.id,
                    s3_gr_hash=gr_hash
                )
                db.session.add(link)

        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

    # Return the full portal card dict for immediate frontend use
    return jsonify({'result': portal.as_card_dict()}), 201

# POST: Edit portal (with optional images)
@portal_bp.route('/edit', methods=['POST'])
@jwt_required
def api_edit_portal():
    if request.content_type and request.content_type.startswith('multipart/form-data'):
        data = request.form
    else:
        data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    portal_id = data.get('portal_id')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id required!'}), 400

    if not check_portal_editor_permission(user_id, portal_id):
        return jsonify({'error': 'Permission denied'}), 403

    portal = Portal.query.filter_by(id=portal_id).first()
    if not portal:
        return jsonify({'error': 'Portal not found'}), 404

    # Update main portal fields
    update_fields = ['name', 'subtitle', 'categories_id', 'cities_id', 'about', 'lead_id', 'visible']
    for field in update_fields:
        if data.get(field) is not None:
            setattr(portal, field, data[field])
    portal.updated_at = datetime.utcnow()

    # Handle deleting graphic group hashes
    if isinstance(data.get('aDeleteGraphicGroupHashes'), list) and data['aDeleteGraphicGroupHashes']:
        S3Content.query.filter(S3Content.gr_hash.in_(data['aDeleteGraphicGroupHashes'])).delete(synchronize_session=False)

    # Handle deleting graphic section IDs
    if isinstance(data.get('aDeletePGSIDs'), list) and data['aDeletePGSIDs']:
        PortalGraphicSection.query.filter(PortalGraphicSection.id.in_(data['aDeletePGSIDs'])).delete(synchronize_session=False)

    # Handle texts
    if 'aTexts' in data:
        try:
            texts = data.get('aTexts')
            if isinstance(texts, str):
                import json
                texts = json.loads(texts)
            PortalText.query.filter_by(portal_id=portal_id).delete(synchronize_session=False)
            for text_obj in texts:
                title = text_obj.get('title', '').strip()
                text = text_obj.get('text', '').strip()
                section = text_obj.get('section', '').strip()
                if title or text:
                    new_text = PortalText(portal_id=portal_id, title=title, text=text, section=section)
                    db.session.add(new_text)
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Invalid aTexts: {str(e)}'}), 400

    # Handle leads/users (if you use roles, update accordingly)
    if isinstance(data.get('aLeadsIDs'), list) and data['aLeadsIDs']:
        leads_ids = list(set([int(i) for i in data['aLeadsIDs'] if str(i).strip().isdigit()]))
        if leads_ids:
            # Remove old leads for this portal
            PortalUser.query.filter(
                PortalUser.portal_id == portal_id,
                PortalUser.user_id.in_(leads_ids),
                PortalUser.role == 'lead'
            ).delete(synchronize_session=False)
            # Add new leads
            for lead_id in leads_ids:
                db.session.add(PortalUser(user_id=lead_id, portal_id=portal_id, role='lead'))

    # Handle images (uploaded files)
    images = request.files.getlist('images')
    if images:
        # Find or create the main graphic section
        main_section = PortalGraphicSection.query.filter_by(portals_id=portal_id, title="Main Section").first()
        if not main_section:
            main_section = PortalGraphicSection(portals_id=portal_id, title="Main Section", position=1)
            db.session.add(main_section)
            db.session.flush()
        # Remove existing links
        PortalGraphicSectionS3Content.query.filter_by(portals_graphic_sections_id=main_section.id).delete(synchronize_session=False)
        for img in images:
            filename = secure_filename(img.filename)
            # Here you would upload to S3 and get the URL and gr_hash
            # For demo, use filename as gr_hash and url
            s3_url = f"https://your-s3-bucket/{filename}"
            gr_hash = f"{uuid.uuid4().hex}_{filename}"
            img.seek(0)
            s3_content = S3Content(
                gr_hash=gr_hash,
                tbl_id=main_section.id,
                tbl_index=6,
                key=filename,
                url=s3_url,
                file_type=img.mimetype,
                file_size=len(img.read())
            )
            img.seek(0)
            db.session.add(s3_content)
            db.session.flush()
            link = PortalGraphicSectionS3Content(
                portals_graphic_sections_id=main_section.id,
                s3_gr_hash=gr_hash
            )
            db.session.add(link)

    db.session.commit()

    # Return the updated portal card dict for immediate frontend use
    return jsonify({'result': portal.as_card_dict()})

# POST: Delete portal
@portal_bp.route('/delete', methods=['POST'])
@jwt_required
def api_delete_portal():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    portal_id = data.get('portal_id')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portal_id required!'}), 400

    portal = Portal.query.filter_by(id=portal_id).first()
    if not portal:
        return jsonify({'error': "The portal doesn't exist!"}), 404

    # Check permission
    if not check_portal_editor_permission(user_id, portal_id):
        return jsonify({'error': 'Permission denied'}), 403

    db.session.delete(portal)
    db.session.commit()

    return jsonify({'result': 'ok'})

# POST: Remove a user from a portal
@portal_bp.route('/user/delete', methods=['POST'])
@jwt_required
def api_delete_portal_user():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    portals_users_id = data.get('portals_users_id')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portals_users_id:
        return jsonify({'error': 'portals_users_id required!'}), 400

    pu = PortalUser.query.filter_by(id=portals_users_id).first()
    if not pu:
        return jsonify({'error': "the portal user doesn't exist!"}), 404

    # Check permission
    if not check_portal_editor_permission(user_id, pu.portal_id):
        return jsonify({'error': 'Permission denied'}), 403

    portal_id = pu.portal_id
    db.session.delete(pu)
    db.session.commit()

    # Update users count (optional, if you store this denormalized)
    users_count = PortalUser.query.filter_by(portal_id=portal_id).count()
    portal = Portal.query.filter_by(id=portal_id).first()
    if portal:
        portal._c_users_count = users_count
        db.session.commit()

    return jsonify({'result': 'ok', 'portal_id': portal_id, 'users_count': users_count})

# GET: Find the nearest portal representative (leader)
@portal_bp.route('/nearest_rep', methods=['GET'])
@jwt_required
def api_get_portal_nearest_rep():
    portal_id = request.args.get('portals_id')
    user_id = g.current_user.id or request.args.get('user_id')
    keyword = request.args.get('keyword', '')
    lat = request.args.get('lat')
    lng = request.args.get('lng')
    restrict_by_distance = request.args.get('restrict_by_distance', '0')
    distance = float(request.args.get('distance', 10))
    offset = int(request.args.get('offset', 0))
    limit = int(request.args.get('limit', 1))

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portals_id is empty!'}), 400

    portal = Portal.query.filter_by(id=portal_id).first()
    if not portal:
        return jsonify({'error': 'portals_id: 404'}), 404

    # Find leaders (excluding current user)
    leaders = PortalUser.query.filter(
        PortalUser.portal_id == portal_id,
        PortalUser.role == 'lead',
        PortalUser.user_id != user_id
    ).all()

    leader_users = []
    if not leaders:
        # If no other leaders, check if current user is the only leader
        if str(portal.users_id) == str(user_id):
            return jsonify({'error': 'You are the one and only leader of the portal'}), 400
        # Return owner as leader
        owner = User.query.filter_by(id=portal.users_id).first()
        if owner:
            leader_users.append(owner)
    else:
        leader_ids = [l.user_id for l in leaders]
        query = User.query.filter(User.id.in_(leader_ids), User.id != user_id)
        if keyword:
            query = query.filter(
                func.lower(func.concat(User.fname, ' ', User.lname)).like(f"%{keyword.lower()}%")
            )
        if lat and lng and lat != '0' and lng != '0':
            try:
                lat = float(lat)
                lng = float(lng)
                if restrict_by_distance == '1' and distance >= 1:
                    # Haversine formula for distance in miles
                    query = query.filter(
                        func.acos(
                            func.sin(func.radians(User.lat)) * func.sin(func.radians(lat)) +
                            func.cos(func.radians(User.lat)) * func.cos(func.radians(lat)) *
                            func.cos(func.radians(User.lng) - func.radians(lng))
                        ) * 3959 <= distance
                    )
                query = query.filter(User.lat != 0, User.lng != 0)
            except Exception:
                pass
        leader_users = query.offset(offset).limit(limit).all()

    # If still no leaders, try by city
    if not leader_users:
        current_user = User.query.filter_by(id=user_id).first()
        if current_user and current_user.cities_id:
            leader_ids = [l.user_id for l in leaders]
            leader_users = User.query.filter(
                User.cities_id == current_user.cities_id,
                User.id.in_(leader_ids),
                User.id != user_id
            ).order_by(func.random()).offset(offset).limit(limit).all()

    # If still none, just pick random leader
    if not leader_users and leaders:
        leader_ids = [l.user_id for l in leaders]
        leader_users = User.query.filter(
            User.id.in_(leader_ids),
            User.id != user_id
        ).order_by(func.random()).offset(offset).limit(limit).all()

    # Serialize users
    result = []
    for user in leader_users:
        result.append({
            'id': user.id,
            'fname': user.fname,
            'lname': user.lname,
            'email': user.email,
            'lat': user.lat,
            'lng': user.lng,
            'cities_id': user.cities_id,
            # Add more fields as needed
        })

    return jsonify({'result': result})