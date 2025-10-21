# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: October 2025
# PUBLIC WEB ROUTES - Package initialization

from flask import Blueprint

# Import all public route blueprints
from .Public_Portals import public_portals_bp
from .Public_Portal_Details import public_portal_details_bp
from .Public_Goal_Details import public_goal_details_bp
from .Public_Payments import public_payments_bp

def register_public_routes(app):
    """
    Register all public web routes with the Flask app.
    These routes do NOT require authentication.
    """
    # Register with /api/public prefix
    app.register_blueprint(public_portals_bp, url_prefix='/api/public')
    app.register_blueprint(public_portal_details_bp, url_prefix='/api/public')
    app.register_blueprint(public_goal_details_bp, url_prefix='/api/public')
    app.register_blueprint(public_payments_bp, url_prefix='/api/public')

    print("[OK] Public web routes registered:")
    print("  GET /api/public/portals")
    print("  GET /api/public/portal/<portal_id>")
    print("  GET /api/public/goal/<goal_id>")
    print("  POST /api/public/create_checkout_session")
    print("  GET /api/public/checkout_session_status")
