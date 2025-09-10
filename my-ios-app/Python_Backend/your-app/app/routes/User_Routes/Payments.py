# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: September 2025

from flask import Blueprint, request, jsonify, g
from app import db
import stripe
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.Purpose_Models.Portal import Portal
from app.utils.auth import jwt_required
from app.services.stripe_service import get_or_create_stripe_customer
import os

stripe.api_key = os.environ.get("STRIPE_SECRET_KEY")

# Define the Blueprint
payments_bp = Blueprint('payments', __name__)

@payments_bp.route('/api/create_setup_intent', methods=['POST'])
@jwt_required
def create_setup_intent():
    user_id = g.current_user.id
    customer = get_or_create_stripe_customer(user_id)
    setup_intent = stripe.SetupIntent.create(
        customer=customer.id,
        payment_method_types=['card'],
    )
    return jsonify({'clientSecret': setup_intent.client_secret})

@payments_bp.route('/api/create_connect_account', methods=['POST'])
@jwt_required
def create_connect_account():
    data = request.json or {}
    user_id = g.current_user.id
    portal_id = data.get('portal_id')
    redirect_url = data.get('redirect_url')

    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or str(portal.users_id) != str(user_id):
        return jsonify({'error': 'Not authorized'}), 403

    try:
        account = stripe.Account.create(
            type="express",
            country="US",
            email=g.current_user.email,
            capabilities={
                "card_payments": {"requested": True},
                "transfers": {"requested": True},
            },
            metadata={
                "portal_id": portal_id,
                "user_id": user_id
            }
        )
        portal.stripe_account_id = account.id
        db.session.commit()

        account_link = stripe.AccountLink.create(
            account=account.id,
            refresh_url=f"{request.host_url}api/stripe_connect_refresh?portal_id={portal_id}",
            return_url=redirect_url,
            type="account_onboarding",
        )
        return jsonify({
            'url': account_link.url,
            'account_id': account.id
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/stripe_dashboard_link', methods=['POST'])
@jwt_required
def stripe_dashboard_link():
    data = request.json or {}
    user_id = g.current_user.id
    account_id = data.get('account_id')

    portal = db.session.query(Portal).filter_by(stripe_account_id=account_id).first()
    if not portal or str(portal.users_id) != str(user_id):
        return jsonify({'error': 'Not authorized'}), 403

    try:
        login_link = stripe.Account.create_login_link(account_id)
        return jsonify({'url': login_link.url})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/create_payment_intent', methods=['POST'])
@jwt_required
def create_payment_intent():
    data = request.json or {}
    user_id = g.current_user.id

    amount = data.get('amount')
    portal_id = data.get('portal_id')
    goal_id = data.get('goal_id')
    currency = data.get('currency', 'usd')
    message = data.get('message', '')
    transaction_type = data.get('transaction_type', 'donation')

    if not amount or not portal_id:
        return jsonify({'error': 'amount and portal_id are required'}), 400

    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or not portal.stripe_account_id:
        return jsonify({'error': 'Portal not set up to receive payments'}), 400

    goal = None
    if goal_id:
        goal = db.session.query(Goal).filter_by(id=goal_id).first()
        if not goal or str(goal.portals_id) != str(portal_id):
            return jsonify({'error': 'Invalid goal for this portal'}), 400

    try:
        # Ensure we attach the PaymentIntent to the customer so history works
        customer = get_or_create_stripe_customer(user_id)

        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            customer=customer.id,  # important so /api/payment_history can find it
            transfer_data={'destination': portal.stripe_account_id},
            metadata={
                'portal_id': str(portal_id),
                'goal_id': str(goal_id) if goal_id else '',
                'user_id': str(user_id),
                'message': message,
                'transaction_type': transaction_type
            }
        )

        # Optionally record transaction + goal progress in DB (left commented for now)
        # transaction = Transaction(...)
        # db.session.add(transaction)
        # if goal and transaction_type in ['donation', 'payment']:
        #     progress_log = GoalProgressLog(...)
        #     db.session.add(progress_log)
        #     goal.filled_quota = (goal.filled_quota or 0) + (amount/100)
        # db.session.commit()

        return jsonify({'clientSecret': payment_intent.client_secret})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/portal/payment_status', methods=['GET'])
@jwt_required
def get_portal_payment_status():
    user_id = g.current_user.id
    portal_id = request.args.get('portal_id')

    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or str(portal.users_id) != str(user_id):
        return jsonify({'error': 'Not authorized'}), 403

    return jsonify({
        'stripe_account_id': portal.stripe_account_id or '',
        'is_connected': bool(portal.stripe_account_id),
    })

@payments_bp.route('/stripe/webhook', methods=['POST'])
def stripe_webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')
    stripe_webhook_secret = os.environ.get("STRIPE_WEBHOOK_SECRET")
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, stripe_webhook_secret
        )

        if event['type'] == 'account.updated':
            account = event['data']['object']
            portal = db.session.query(Portal).filter_by(stripe_account_id=account['id']).first()
            if portal:
                portal.stripe_account_status = account.get('details_submitted', False)
                db.session.commit()

        # Add handlers for:
        # - payment_intent.succeeded
        # - invoice.payment_succeeded
        return jsonify({'status': 'success'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/create_subscription', methods=['POST'])
@jwt_required
def create_subscription():
    data = request.json or {}
    user_id = g.current_user.id
    portal_id = data.get('portal_id')
    goal_id = data.get('goal_id')
    price_id = data.get('price_id')

    if not price_id:
        return jsonify({'error': 'price_id is required'}), 400

    customer = get_or_create_stripe_customer(user_id)
    try:
        subscription = stripe.Subscription.create(
            customer=customer.id,
            items=[{"price": price_id}],
            payment_behavior="default_incomplete",
            expand=["latest_invoice.payment_intent"],
            metadata={
                "portal_id": str(portal_id) if portal_id else '',
                "goal_id": str(goal_id) if goal_id else '',
                "user_id": str(user_id),
                "subscription_type": "monthly"
            }
        )
        payment_intent = subscription.latest_invoice.payment_intent
        return jsonify({
            "clientSecret": payment_intent.client_secret,
            "subscriptionId": subscription.id
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/subscriptions', methods=['GET'])
@jwt_required
def get_subscriptions():
    user_id = g.current_user.id
    customer = get_or_create_stripe_customer(user_id)
    try:
        subscriptions = stripe.Subscription.list(
            customer=customer.id,
            status='active',
            expand=['data.plan.product']
        )
        results = []
        for sub in subscriptions.data:
            portal_id = sub.metadata.get('portal_id')
            goal_id = sub.metadata.get('goal_id')
            display_name = "Rep Subscription"
            if goal_id:
                goal = db.session.query(Goal).filter_by(id=goal_id).first()
                if goal:
                    display_name = goal.title
            elif portal_id:
                portal = db.session.query(Portal).filter_by(id=portal_id).first()
                if portal:
                    display_name = portal.name

            results.append({
                'id': sub.id,
                'name': display_name,
                'amount': sub.plan.amount,
                'nextBillingDate': sub.current_period_end
            })
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/payment_history', methods=['GET'])
@jwt_required
def get_payment_history():
    user_id = g.current_user.id
    customer = get_or_create_stripe_customer(user_id)
    try:
        payment_intents = stripe.PaymentIntent.list(customer=customer.id, limit=100)
        results = []
        for pi in payment_intents.data:
            if pi.status != 'succeeded':
                continue
            portal_id = pi.metadata.get('portal_id')
            goal_id = pi.metadata.get('goal_id')
            transaction_type = pi.metadata.get('transaction_type', 'Payment')
            display_name = f"{transaction_type.capitalize()}"
            if goal_id:
                goal = db.session.query(Goal).filter_by(id=goal_id).first()
                if goal:
                    display_name = f"{transaction_type.capitalize()} to {goal.title}"
            elif portal_id:
                portal = db.session.query(Portal).filter_by(id=portal_id).first()
                if portal:
                    display_name = f"{transaction_type.capitalize()} to {portal.name}"
            results.append({
                'id': pi.id,
                'description': display_name,
                'amount': pi.amount,
                'date': pi.created
            })
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/cancel_subscription', methods=['POST'])
@jwt_required
def cancel_subscription():
    data = request.json or {}
    user_id = g.current_user.id
    subscription_id = data.get('subscriptionId')
    if not subscription_id:
        return jsonify({'error': 'Subscription ID is required'}), 400

    customer = get_or_create_stripe_customer(user_id)
    try:
        subscription = stripe.Subscription.retrieve(subscription_id)
        if subscription.customer != customer.id:
            return jsonify({'error': 'Not authorized to cancel this subscription'}), 403
        stripe.Subscription.delete(subscription_id)
        return jsonify({'status': 'success', 'message': 'Subscription canceled successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400