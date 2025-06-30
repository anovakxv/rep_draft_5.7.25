import os
import jwt
from functools import wraps
from flask import request, jsonify, g
from app.models.People_Models.user import User

def jwt_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = None
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
        if not token:
            return jsonify({'error': 'Authorization token required'}), 401
        try:
            jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
            payload = jwt.decode(token, jwt_secret, algorithms=['HS256'])
            user_id = payload.get('user_id')
            user = User.query.get(user_id)
            if not user:
                return jsonify({'error': 'User not found'}), 404
            g.current_user = user
        except Exception:
            return jsonify({'error': 'Invalid or expired token'}), 401
        return f(*args, **kwargs)
    return decorated_function
