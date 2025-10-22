# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: October 2025
# PUBLIC WEB ROUTES - Public Stripe payments without authentication

from flask import Blueprint, request, jsonify
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.Purpose_Models.Portal import Portal
from app.models.ValueMetric_Models.Transaction import Transaction
from datetime import datetime
import stripe
import os

stripe.api_key = os.environ.get("STRIPE_SECRET_KEY")

public_payments_bp = Blueprint('public_payments', __name__)

def get_or_create_guest_customer(email):
    """
    Creates a Stripe customer for guest (unauthenticated) checkout.
    Uses email as the identifier.
    """
    if not email:
        raise Exception("Email is required for guest checkout")

    # Try to find existing customer by email
    existing_customers = stripe.Customer.list(email=email, limit=1)
    if existing_customers.data:
        return existing_customers.data[0]

    # Create new customer
    customer = stripe.Customer.create(email=email)
    return customer

@public_payments_bp.route('/create_checkout_session', methods=['POST'])
def create_public_checkout_session():
    """
    PUBLIC API: Creates a Stripe Checkout Session for unauthenticated users.
    Used for public web app Support button on Fund/Sales goals.

    Required params:
    - amount: payment amount in cents
    - portal_id: ID of the portal to receive payment
    - email: payer's email address (for guest checkout)

    Optional params:
    - goal_id: ID of the goal (if supporting a specific goal)
    - currency: payment currency (default: 'usd')
    - message: optional message from payer
    - transaction_type: 'donation' or 'payment' (default: 'donation')
    - is_subscription: boolean for recurring payments
    - price_id: Stripe price ID for subscriptions
    """
    data = request.json or {}
    print(f"[Public Checkout] Received data: {data}")

    # Required fields for public checkout
    amount = data.get('amount')
    portal_id = data.get('portal_id')
    email = data.get('email')

    # Optional fields
    goal_id = data.get('goal_id')
    currency = data.get('currency', 'usd')
    message = data.get('message', '')
    transaction_type = data.get('transaction_type', 'donation')
    is_subscription = data.get('is_subscription', False)
    price_id = data.get('price_id')

    print(f"[Public Checkout] amount: {amount}, portal_id: {portal_id}, goal_id: {goal_id}, email: {email}")

    # Validation
    if not amount and not price_id:
        return jsonify({'error': 'amount or price_id is required'}), 400
    if not portal_id:
        return jsonify({'error': 'portal_id is required'}), 400
    if not email:
        return jsonify({'error': 'email is required for guest checkout'}), 400

    # Verify portal exists and can receive payments
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    print(f"[Public Checkout] Portal found: {portal is not None}, stripe_account_id: {getattr(portal, 'stripe_account_id', None)}")

    if not portal or not portal.stripe_account_id:
        return jsonify({'error': 'Portal not set up to receive payments'}), 400

    # Get goal if specified
    goal = None
    if goal_id:
        goal = db.session.query(Goal).filter_by(id=goal_id).first()
        print(f"[Public Checkout] Goal found: {goal is not None}")

    try:
        # Create or get Stripe customer for this email
        customer = get_or_create_guest_customer(email)
        print(f"[Public Checkout] Stripe customer: {customer.id}")

        # Success and cancel URLs (for web app)
        success_url = f"https://rep-june2025.onrender.com/payment-return?status=success&session_id={{CHECKOUT_SESSION_ID}}"
        cancel_url = f"https://rep-june2025.onrender.com/payment-return?status=canceled"

        # Build checkout session params
        session_params = {
            'customer': customer.id,  # Email is already associated with customer
            'success_url': success_url,
            'cancel_url': cancel_url,
            'payment_method_types': ['card'],
            'metadata': {
                'portal_id': str(portal_id),
                'goal_id': str(goal_id) if goal_id else '',
                'email': email,
                'message': message,
                'transaction_type': transaction_type,
                'is_public': 'true'  # Flag to identify public transactions
            }
        }

        # Subscription checkout
        if is_subscription and price_id:
            print("[Public Checkout] Creating subscription checkout session")
            session_params['mode'] = 'subscription'
            session_params['line_items'] = [{
                'price': price_id,
                'quantity': 1
            }]
            session_params['subscription_data'] = {
                'metadata': {
                    'portal_id': str(portal_id),
                    'goal_id': str(goal_id) if goal_id else '',
                    'email': email,
                    'message': message,
                    'transaction_type': transaction_type,
                    'is_public': 'true'
                },
                'transfer_data': {
                    'destination': portal.stripe_account_id,
                }
            }
        # One-time payment checkout
        else:
            print("[Public Checkout] Creating payment checkout session")
            session_params['mode'] = 'payment'
            session_params['line_items'] = [{
                'price_data': {
                    'currency': currency,
                    'product_data': {
                        'name': f"{transaction_type.capitalize()} to {portal.name}",
                        'description': f"Goal: {goal.title}" if goal else "",
                    },
                    'unit_amount': amount,
                },
                'quantity': 1,
            }]
            session_params['payment_intent_data'] = {
                'transfer_data': {
                    'destination': portal.stripe_account_id,
                },
                'metadata': {
                    'portal_id': str(portal_id),
                    'goal_id': str(goal_id) if goal_id else '',
                    'email': email,
                    'message': message,
                    'transaction_type': transaction_type,
                    'is_public': 'true'
                }
            }

        # Create Stripe Checkout Session
        print(f"[Public Checkout] Creating Stripe session...")
        checkout_session = stripe.checkout.Session.create(**session_params)
        print(f"[Public Checkout] Created session: {checkout_session.id}, url: {checkout_session.url}")

        # Pre-record transaction as pending (will be updated by webhook on success)
        # Note: user_id is NULL for public transactions
        transaction = Transaction(
            user_id=None,  # No user_id for public transactions
            portal_id=portal_id,
            goal_id=goal_id if goal_id else None,
            amount=amount,
            currency=currency,
            transaction_type=transaction_type,
            message=message,
            stripe_payment_intent_id=checkout_session.id,  # Store session_id temporarily
            status='pending',
            created_at=datetime.utcnow()
        )
        db.session.add(transaction)
        db.session.commit()
        print(f"[Public Checkout] Pre-recorded transaction: {transaction.id}")

        return jsonify({
            'checkout_url': checkout_session.url,
            'session_id': checkout_session.id
        })

    except Exception as e:
        print(f"[Public Checkout] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400

@public_payments_bp.route('/checkout_session_status', methods=['GET'])
def public_checkout_session_status():
    """
    PUBLIC API: Check status of a Stripe Checkout Session (no auth required).

    Query params:
    - session_id: Stripe checkout session ID
    """
    session_id = request.args.get('session_id')
    if not session_id:
        return jsonify({'error': 'session_id is required'}), 400

    try:
        checkout_session = stripe.checkout.Session.retrieve(session_id)
        return jsonify({
            'status': checkout_session.status,
            'payment_status': checkout_session.payment_status
        })
    except Exception as e:
        print(f"[Public Checkout Status] Error: {str(e)}")
        return jsonify({'error': str(e)}), 400
