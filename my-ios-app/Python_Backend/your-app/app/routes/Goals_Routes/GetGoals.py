
from flask import Blueprint, request, jsonify
from app.models.ValueMetric_Models.Goal import Goal

goals_bp = Blueprint('goals', __name__)

# GET /api/goals/list?users_id=1
@goals_bp.route('/api/goals/list', methods=['GET'])
def get_goals_by_user():
    users_id = request.args.get('users_id', type=int)
    if not users_id:
        return jsonify({"error": "users_id required"}), 400

    goals = Goal.query.filter_by(users_id=users_id).all()

    aGoals = [
        {
            "id": goal.id,
            "title": goal.title,
            "subtitle": goal.subtitle or "",
            "progressPercent": round(100 * goal.filled_quota / goal.quota) if goal.quota else 0,
            "typeName": goal.goal_type.title if goal.goal_type else "",
            "chartData": [
                {
                    "value": d["value"],
                    "valueLabel": str(d["value"]),
                    "bottomLabel": d["label"]
                }
                for d in goal.chart_data()
            ]
        }
        for goal in goals
    ]

    return jsonify({"aGoals": aGoals})

# GET /api/goals/portal?portals_id=1
@goals_bp.route('/api/goals/portal', methods=['GET'])
def get_goals_by_portal():
    portals_id = request.args.get('portals_id', type=int)
    if not portals_id:
        return jsonify({"error": "portals_id required"}), 400

    goals = Goal.query.filter_by(portals_id=portals_id).all()

    aGoals = [
        {
            "id": goal.id,
            "title": goal.title,
            "subtitle": goal.subtitle or "",
            "progressPercent": round(100 * goal.filled_quota / goal.quota) if goal.quota else 0,
            "typeName": goal.goal_type.title if goal.goal_type else "",
            "chartData": [
                {
                    "value": d["value"],
                    "valueLabel": str(d["value"]),
                    "bottomLabel": d["label"]
                }
                for d in goal.chart_data()
            ]
        }
        for goal in goals
    ]

    return jsonify({"aGoals": aGoals})
