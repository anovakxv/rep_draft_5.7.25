# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.ValueMetric_Models.GoalProgressFile import GoalProgressFile

import os
import boto3
import uuid
from werkzeug.utils import secure_filename
from app.utils.auth import jwt_required

goals_bp = Blueprint('update_quota', __name__)

# Configuration for file uploads
USE_S3 = os.environ.get('USE_S3', 'False').lower() == 'true'
LOCAL_UPLOAD_FOLDER = 'uploads/goal_progress_files'
S3_BUCKET = os.environ.get('S3_BUCKET_NAME', 'your-bucket-name')
S3_REGION = os.environ.get('AWS_REGION', 'us-east-1')
BASE_URL = os.environ.get('BASE_URL', 'http://localhost:5000')

# Initialize S3 client if enabled
if USE_S3:
    s3_client = boto3.client(
        's3',
        aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
        region_name=S3_REGION
    )

def get_file_extension(filename):
    """Get file extension from filename."""
    return os.path.splitext(filename)[1].lower()

def is_image_file(filename):
    """Check if file is an image based on extension."""
    image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
    return get_file_extension(filename) in image_extensions

@goals_bp.route('/update_filled_quota', methods=['POST'])
@jwt_required
def api_update_goal_filled_quota():
    user_id = g.current_user.id
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401

    # Handle both JSON and multipart/form-data
    if request.content_type and request.content_type.startswith('multipart/form-data'):
        data = request.form
        files = request.files.getlist('files')
        sources_notes = request.form.getlist('sources_notes')
    else:
        data = request.json or {}
        files = []
        sources_notes = data.get('sources_notes', [])

    goal_id = data.get('goals_id')
    added_value = data.get('added_value')
    note = data.get('note', '')

    if not goal_id:
        return jsonify({'error': 'goals_id required!'}), 400
    if added_value is None:
        return jsonify({'error': 'added_value required!'}), 400

    try:
        added_value = float(added_value)
    except (TypeError, ValueError):
        return jsonify({'error': 'added_value must be a number!'}), 400

    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': 'Goal not found'}), 404

    # Permission: Only owner or confirmed team member can update
    is_owner = goal.users_id == user_id
    is_team_member = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=user_id, confirmed=1).count() > 0
    if not (is_owner or is_team_member):
        return jsonify({'error': 'Permission denied'}), 403

    # Add progress log
    progress_log = GoalProgressLog(
        users_id=user_id,
        goals_id=goal_id,
        added_value=added_value,
        note=note,
        value=(goal.filled_quota or 0) + added_value
    )
    db.session.add(progress_log)
    db.session.flush()  # Get progress_log.id before commit

    # Handle file uploads
    uploaded_files = []
    if files:
        # Ensure local directory exists if not using S3
        if not USE_S3:
            os.makedirs(LOCAL_UPLOAD_FOLDER, exist_ok=True)
            
        for idx, file in enumerate(files):
            if file and file.filename:
                # Generate unique filename
                original_filename = secure_filename(file.filename)
                unique_id = str(uuid.uuid4())
                filename = f"{unique_id}_{original_filename}"
                
                # Get note for this file
                note_for_file = sources_notes[idx] if idx < len(sources_notes) else ""
                
                # Check if file is an image
                is_image = is_image_file(original_filename)
                
                if USE_S3:
                    # Upload to S3
                    try:
                        file_key = f"goal_updates/{goal_id}/{progress_log.id}/{filename}"
                        s3_client.upload_fileobj(file, S3_BUCKET, file_key)
                        file_url = f"https://{S3_BUCKET}.s3.{S3_REGION}.amazonaws.com/{file_key}"
                        
                        # Create database record
                        progress_file = GoalProgressFile(
                            goal_progress_id=progress_log.id,
                            file_url=file_url,
                            file_name=original_filename,
                            is_image=is_image,
                            note=note_for_file
                        )
                        db.session.add(progress_file)
                        
                        uploaded_files.append({
                            "id": None,  # Will be set after commit
                            "url": file_url,
                            "file_name": original_filename,
                            "is_image": is_image,
                            "note": note_for_file
                        })
                        
                    except Exception as e:
                        print(f"S3 upload error: {str(e)}")
                        continue
                        
                else:
                    # Local file storage
                    file_path = os.path.join(LOCAL_UPLOAD_FOLDER, filename)
                    file.save(file_path)
                    
                    # Generate URL for the file
                    file_url = f"{BASE_URL}/uploads/goal_progress_files/{filename}"
                    
                    # Create database record
                    progress_file = GoalProgressFile(
                        goal_progress_id=progress_log.id,
                        file_url=file_url,
                        file_name=original_filename,
                        is_image=is_image,
                        note=note_for_file
                    )
                    db.session.add(progress_file)
                    
                    uploaded_files.append({
                        "id": None,  # Will be set after commit
                        "url": file_url,
                        "file_name": original_filename,
                        "is_image": is_image,
                        "note": note_for_file
                    })

    # Update goal's filled_quota
    goal.filled_quota = (goal.filled_quota or 0) + added_value
    db.session.commit()
    
    # Update the IDs in the response after commit
    for idx, file_record in enumerate(db.session.query(GoalProgressFile).filter_by(goal_progress_id=progress_log.id).all()):
        if idx < len(uploaded_files):
            uploaded_files[idx]["id"] = file_record.id

    # Return updated goal details with progress and progress_percent
    updated_goal = {
        'id': goal.id,
        'description': goal.description,
        'quota': goal.quota,
        'filled_quota': goal.filled_quota,
        'progress': round(goal.filled_quota / goal.quota, 2) if goal.quota else 0,
        'progress_percent': round(100 * goal.filled_quota / goal.quota) if goal.quota else 0,
        'goal_type': goal.goal_type,
        'metric': goal.metric,
        'rep_commission': goal.rep_commission,
        'reporting_increments_id': goal.reporting_increments_id,
        'portals_id': goal.portals_id,
        'users_id': goal.users_id,
        'lead_id': goal.lead_id,
        'uploaded_files': uploaded_files
    }

    return jsonify({'result': updated_goal})