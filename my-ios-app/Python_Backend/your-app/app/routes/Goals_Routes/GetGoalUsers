
from flask import Blueprint, request, jsonify
from app.models.Goals_Models.GoalTeam import GoalTeam
from app.models.Goals_Models.User import User

goals_bp = Blueprint('goals', __name__)

@goals_bp.route('/api/goals/users', methods=['GET'])
def api_get_goal_users():
    goal_id = request.args.get('goals_id', type=int)
    confirmed = request.args.get('confirmed')
    offset = request.args.get('offset', default=0, type=int)
    limit = request.args.get('limit', default=50, type=int)

    if not goal_id:
        return jsonify({'error': 'goals_id is empty!'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400

    query = GoalTeam.query.filter_by(goals_id=goal_id)
    if confirmed is not None:
        query = query.filter_by(confirmed=int(confirmed))
    team_members = query.offset(offset).limit(limit).all()

    user_ids = [member.users_id2 for member in team_members]
    users = User.query.filter(User.id.in_(user_ids)).all()
    users_dict = {u.id: u for u in users}

    result = []
    for member in team_members:
        user = users_dict.get(member.users_id2)
        if user:
            result.append({
                'id': user.id,
                'username': user.username,
                'fname': user.fname,
                'lname': user.lname,
                'email': user.email,
                'about': user.about,
                'phone': user.phone,
                'cities_id': user.cities_id,
                'users_types_id': user.users_types_id,
                'confirmed': member.confirmed,
                'team_id': member.id,
                'team_read1': member.read1,
                'team_read2': member.read2,
                'team_timestamp': member.timestamp.isoformat() if member.timestamp else None
            })

    return jsonify({'result': result})
    