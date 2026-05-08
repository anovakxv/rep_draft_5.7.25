# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db, limiter
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

def parse_event_datetime(value):
    """Parse event_datetime from ISO string (e.g. '2026-05-15T14:30' or '2026-05-15T14:30:00')."""
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value))
    except (ValueError, TypeError):
        return None
from werkzeug.utils import secure_filename
import uuid
import boto3
import os

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"
S3_BUCKET = "rep-app-dbbucket"

s3 = boto3.client(
    's3',
    aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
    region_name=os.environ.get('AWS_DEFAULT_REGION')
)

portal_bp = Blueprint('portal', __name__)

def user_as_portal_dict(user):
    url = getattr(user, "profile_picture_url", None)
    if url and not url.startswith("http"):
        url = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        url = None
    return {
        "id": user.id,
        "fname": user.fname,
        "lname": user.lname,
        "username": getattr(user, "username", None),
        "profile_picture_url": url,
        # Add more fields as needed
    }

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
            # Ensure returned url is full S3 URL
            file_url = f.url
            if file_url and not file_url.startswith("http"):
                file_url = S3_BASE_URL + file_url
            files_by_section.setdefault(f.tbl_id, []).append({
                'id': f.id,
                'gr_hash': f.gr_hash,
                'key': f.key,
                'url': file_url
            })

    # Compose sections with files
    aSections = []
    for section in sections:
        aSections.append({
            'id': section.id,
            'title': section.title,
            'aFiles': files_by_section.get(section.id, [])
        })

    # --- FIX: Compose users and leads separately ---
    portal_users = portal.portal_users
    # All users (all roles)
    all_user_ids = set([portal.users_id] + [pu.user_id for pu in portal_users])
    all_users = User.query.filter(User.id.in_(all_user_ids)).all()
    all_users_by_id = {u.id: u for u in all_users}

    # Derive lead_users from all_users (lead_user_ids is a subset — no second query needed)
    portal_leads = [pu for pu in portal_users if pu.role == 'lead']
    lead_user_ids = set([portal.users_id] + [pu.user_id for pu in portal_leads])
    lead_users = [all_users_by_id[uid] for uid in lead_user_ids if uid in all_users_by_id]

    # Compose goals
    goals = Goal.query.filter_by(portals_id=portal.id).order_by(Goal.id.desc()).all()

    # Batch-check current user's goal membership (event portals only — skipped for all others)
    member_goal_ids = set()
    if portal.portal_type == 'event' and goals:
        from app.models.ValueMetric_Models.GoalTeam import GoalTeam as GT
        goal_ids = [goal.id for goal in goals]
        memberships = GT.query.filter(
            GT.goals_id.in_(goal_ids),
            GT.users_id2 == user_id,
            GT.confirmed == 1
        ).with_entities(GT.goals_id).all()
        member_goal_ids = {m.goals_id for m in memberships}

    # Compose portal texts
    texts = portal.portal_texts

    # Identify the main image (first file of the first section)
    main_image_url = portal.main_image_url
    if main_image_url and not main_image_url.startswith("http"):
        main_image_url = S3_BASE_URL + main_image_url

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
        'portal_type': portal.portal_type,
        'event_datetime': portal.event_datetime.isoformat() if portal.event_datetime else None,
        'event_location': portal.event_location,
        'event_timezone': portal.event_timezone,
        'event_duration_minutes': portal.event_duration_minutes,
        'mainImageUrl': main_image_url,
        'aGoals': [dict(goal.as_dict(), is_member=goal.id in member_goal_ids) for goal in goals],
        'aPortalUsers': [pu.as_dict() for pu in portal_users],
        'aTexts': [t.as_dict() for t in texts],
        'aSections': aSections,
        'aUsers': [user_as_portal_dict(u) for u in all_users],
        'aLeads': [user_as_portal_dict(u) for u in lead_users],
        'lead_user_count': len(lead_user_ids),
        'user_count': len(all_user_ids),
    }

    return jsonify({'result': portal_data})

# POST: Create portal (with optional images)
@portal_bp.route('/', methods=['POST'])
@jwt_required
@limiter.limit("10 per day")
def api_create_portal():
    import traceback

    print("POST /api/portal/ data (form):", request.form)
    print("POST /api/portal/ data (files):", request.files)
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
            portal_type=data.get('portal_type') or None,
            event_datetime=parse_event_datetime(data.get('event_datetime')),
            event_location=data.get('event_location') or None,
            event_timezone=data.get('event_timezone') or None,
            event_duration_minutes=int(data['event_duration_minutes']) if data.get('event_duration_minutes') else None,
            # --- PORTAL APPROVAL WORKFLOW ---
            # To enable approval: change 'active' to 'pending' below.
            # New portals will be hidden from public until approved by admin.
            # status='pending',
            status='active',
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        db.session.add(portal)
        db.session.flush()  # Get portal.id before commit

        # Handle images (uploaded files)
        images = request.files.getlist('images')
        if images:
            # Find or create the main graphic section for this portal
            main_section = PortalGraphicSection.query.filter_by(portals_id=portal.id, title="Main Section").first()
            if not main_section:
                main_section = PortalGraphicSection(portals_id=portal.id, title="Main Section", position=1)
                db.session.add(main_section)
                db.session.flush()
            # Remove existing links (should be none for new portal, but safe)
            PortalGraphicSectionS3Content.query.filter_by(portals_graphic_sections_id=main_section.id).delete(synchronize_session=False)
            # Delete old S3Content files for this section (should be none for new portal)
            old_files = S3Content.query.filter_by(tbl_id=main_section.id, tbl_index=6).all()
            for f in old_files:
                db.session.delete(f)
            for img in images:
                unique_filename = f"{portal.id}_{uuid.uuid4().hex}_{secure_filename(img.filename)}"
                img.seek(0)
                s3.upload_fileobj(img, S3_BUCKET, unique_filename)
                s3_url = f"{S3_BASE_URL}{unique_filename}"
                gr_hash = f"{uuid.uuid4().hex}_{unique_filename}"
                # --- FIX: Remove all img.read() and extra seek() ---
                s3_content = S3Content(
                    gr_hash=gr_hash,
                    tbl_id=main_section.id,
                    tbl_index=6,
                    key=unique_filename,
                    url=s3_url,
                    file_type=img.mimetype,
                    file_size=None  # Or remove if not required
                )
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
        print("PORTAL CREATE ERROR:", e)
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

    # Return the full portal card dict for immediate frontend use
    return jsonify({'result': portal.as_card_dict()}), 201

# POST: Edit portal (with optional images)
@portal_bp.route('/edit', methods=['POST'])
@jwt_required
def api_edit_portal():
    import json

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
    update_fields = ['name', 'subtitle', 'categories_id', 'cities_id', 'about', 'lead_id', 'visible',
                     'portal_type', 'event_location', 'event_timezone', 'event_duration_minutes']
    for field in update_fields:
        if data.get(field) is not None:
            setattr(portal, field, data[field] or None)
    if 'event_datetime' in data:
        portal.event_datetime = parse_event_datetime(data.get('event_datetime'))
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

    # --- FIX: Handle leads/users (add new leads, keep existing) robustly ---
    aLeadsIDs = data.get('aLeadsIDs')
    leads_ids = set()
    if aLeadsIDs:
        try:
            # Accept both JSON string and list
            if isinstance(aLeadsIDs, str):
                leads_ids = set(int(i) for i in json.loads(aLeadsIDs) if str(i).strip().isdigit())
            elif isinstance(aLeadsIDs, list):
                leads_ids = set(int(i) for i in aLeadsIDs if str(i).strip().isdigit())
        except Exception:
            leads_ids = set()
    if leads_ids:
        # Find existing lead user_ids for this portal
        existing_leads = set(
            pu.user_id for pu in PortalUser.query.filter_by(portal_id=portal_id, role='lead').all()
        )
        # Only add new leads that aren't already present
        new_leads = leads_ids - existing_leads
        for lead_id in new_leads:
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
        # Delete old S3Content files for this section
        old_files = S3Content.query.filter_by(tbl_id=main_section.id, tbl_index=6).all()
        for f in old_files:
            db.session.delete(f)
        for img in images:
            unique_filename = f"{portal_id}_{uuid.uuid4().hex}_{secure_filename(img.filename)}"
            img.seek(0)
            s3.upload_fileobj(img, S3_BUCKET, unique_filename)
            s3_url = f"{S3_BASE_URL}{unique_filename}"
            gr_hash = f"{uuid.uuid4().hex}_{unique_filename}"
            s3_content = S3Content(
                gr_hash=gr_hash,
                tbl_id=main_section.id,
                tbl_index=6,
                key=unique_filename,
                url=s3_url,
                file_type=img.mimetype,
                file_size=None  # Or remove if not required
            )
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

    # --- Delete related data ---
    # Delete portal texts
    PortalText.query.filter_by(portal_id=portal_id).delete(synchronize_session=False)
    # Delete portal users
    PortalUser.query.filter_by(portal_id=portal_id).delete(synchronize_session=False)
    # Delete portal graphic sections and their links
    graphic_sections = PortalGraphicSection.query.filter_by(portals_id=portal_id).all()
    for section in graphic_sections:
        # Delete S3 links for this section
        PortalGraphicSectionS3Content.query.filter_by(portals_graphic_sections_id=section.id).delete(synchronize_session=False)
        # Delete S3Content files for this section
        S3Content.query.filter_by(tbl_id=section.id, tbl_index=6).delete(synchronize_session=False)
        db.session.delete(section)
    # Delete goals associated with this portal
    Goal.query.filter_by(portals_id=portal_id).delete(synchronize_session=False)

    # Finally, delete the portal itself
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


@portal_bp.route('/<int:portal_id>/calendar.ics', methods=['GET'])
def api_portal_calendar_ics(portal_id):
    """Return an .ics calendar file for an event portal. No auth required."""
    from flask import make_response
    from datetime import timedelta

    portal = Portal.query.get(portal_id)
    if not portal or portal.portal_type != 'event':
        return jsonify({'error': 'Not an event portal'}), 404

    dt = portal.event_datetime
    if not dt:
        return jsonify({'error': 'No event date set'}), 404

    # Build .ics content
    uid = f"portal-{portal_id}@repsomething.com"
    start = dt.strftime('%Y%m%dT%H%M%S')
    duration_minutes = portal.event_duration_minutes or 90
    end = (dt + timedelta(minutes=duration_minutes)).strftime('%Y%m%dT%H%M%S')
    now_utc = datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    summary = portal.name.replace('\n', ' ').replace('\r', '')
    description = (portal.about or '').replace('\n', '\\n').replace('\r', '')[:500]
    location = (portal.event_location or '').replace('\n', ' ').replace('\r', '')
    url = f"https://www.repsomething.com/portal/{portal_id}"

    # Use TZID if timezone is set, otherwise floating time
    tz = portal.event_timezone or ''
    if tz:
        dtstart_line = f"DTSTART;TZID={tz}:{start}"
        dtend_line = f"DTEND;TZID={tz}:{end}"
    else:
        dtstart_line = f"DTSTART:{start}"
        dtend_line = f"DTEND:{end}"

    lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//Rep//Rep App//EN",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "BEGIN:VEVENT",
        f"UID:{uid}",
        f"DTSTAMP:{now_utc}",
        dtstart_line,
        dtend_line,
        f"SUMMARY:{summary}",
    ]
    if description:
        lines.append(f"DESCRIPTION:{description}")
    if location:
        lines.append(f"LOCATION:{location}")
    lines += [
        f"URL:{url}",
        "END:VEVENT",
        "END:VCALENDAR",
    ]

    ics_content = "\r\n".join(lines) + "\r\n"
    safe_name = "".join(c if c.isalnum() or c in ('-', '_') else '_' for c in portal.name)[:40]

    response = make_response(ics_content)
    response.headers['Content-Type'] = 'text/calendar; charset=utf-8'
    response.headers['Content-Disposition'] = f'attachment; filename="{safe_name}.ics"'
    return response


# =============================================================================
# PORTAL APPROVAL WORKFLOW — Not yet active. Uncomment to enable.
# Requires: status='pending' on portal creation (see api_create_portal above)
#           + status filters in Get_Portals.py, SearchPortals.py, Public_Portals.py
# =============================================================================

# ADMIN_USER_IDS = [45]  # Add more admin user IDs as needed, or load from env:
# ADMIN_USER_IDS = [int(x) for x in os.environ.get('ADMIN_USER_IDS', '45').split(',')]

# @portal_bp.route('/admin/pending', methods=['GET'])
# @jwt_required
# def api_admin_pending_portals():
#     """Admin-only: list all portals awaiting approval."""
#     if g.current_user.id not in ADMIN_USER_IDS:
#         return jsonify({'error': 'Unauthorized'}), 403
#     portals = Portal.query.filter_by(status='pending').order_by(Portal.created_at.asc()).all()
#     return jsonify({'result': [p.as_card_dict() for p in portals]})

# @portal_bp.route('/admin/approve', methods=['POST'])
# @jwt_required
# def api_admin_approve_portal():
#     """Admin-only: approve or reject a pending portal."""
#     if g.current_user.id not in ADMIN_USER_IDS:
#         return jsonify({'error': 'Unauthorized'}), 403
#     data = request.get_json()
#     portal_id = data.get('portal_id')
#     action = data.get('action')  # 'approve' or 'reject'
#     if not portal_id or action not in ('approve', 'reject'):
#         return jsonify({'error': "portal_id and action ('approve' or 'reject') required"}), 400
#     portal = Portal.query.filter_by(id=portal_id).first()
#     if not portal:
#         return jsonify({'error': 'Portal not found'}), 404
#     portal.status = 'active' if action == 'approve' else 'rejected'
#     db.session.commit()
#
#     # Notify creator via DM (best-effort)
#     try:
#         from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
#         from app import socketio
#         admin_id = g.current_user.id
#         if action == 'approve':
#             dm_text = (
#                 f"Your Portal \"{portal.name}\" has been approved! "
#                 f"It's now live and visible to the Rep community."
#             )
#         else:
#             dm_text = (
#                 f"Your Portal \"{portal.name}\" was not approved at this time. "
#                 f"Please message us if you have any questions."
#             )
#         msg = DirectMessage(
#             sender_id=admin_id,
#             recipient_id=portal.users_id,
#             text=dm_text,
#             created_at=datetime.utcnow()
#         )
#         db.session.add(msg)
#         db.session.commit()
#         payload = {
#             "type": "direct_message",
#             "id": msg.id,
#             "message_id": msg.id,
#             "sender_id": admin_id,
#             "recipient_id": portal.users_id,
#             "text": msg.text,
#             "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
#             "read": "0"
#         }
#         socketio.emit("direct_message_notification", payload, room=f"user_{portal.users_id}")
#     except Exception as e:
#         print(f"[PortalApproval] DM notify failed: {e}")
#
#     return jsonify({'result': 'ok', 'portal_id': portal_id, 'status': portal.status})