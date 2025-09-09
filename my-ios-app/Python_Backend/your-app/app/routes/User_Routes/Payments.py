# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: September 2025

from flask import Blueprint, request, jsonify, g
from app import db, stripe
from app.models.ValueMetric_Models import Goal, GoalProgressLog
from app.models.Purpose_Models import Portal
from app.middleware.auth import authenticate
from app.services.stripe_service import get_or_create_stripe_customer

# Define the Blueprint
payments_bp = Blueprint('payments', __name__)

@payments_bp.route('/api/create_setup_intent', methods=['POST'])
@authenticate
def create_setup_intent():
    user_id = g.user_id
    customer = get_or_create_stripe_customer(user_id)
    setup_intent = stripe.SetupIntent.create(
        customer=customer.id,
        payment_method_types=['card'],
    )
    return jsonify({'clientSecret': setup_intent.client_secret})

@payments_bp.route('/api/create_connect_account', methods=['POST'])
@authenticate
def create_connect_account():
    data = request.json
    user_id = g.user_id
    portal_id = data.get('portal_id')
    redirect_url = data.get('redirect_url')
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or portal.users_id != user_id:
        return jsonify({'error': 'Not authorized'}), 403
    try:
        account = stripe.Account.create(
            type="express",
            country="US",
            email=g.user_email,
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
@authenticate
def stripe_dashboard_link():
    data = request.json
    user_id = g.user_id
    account_id = data.get('account_id')
    portal = db.session.query(Portal).filter_by(stripe_account_id=account_id).first()
    if not portal or portal.users_id != user_id:
        return jsonify({'error': 'Not authorized'}), 403
    try:
        login_link = stripe.Account.create_login_link(account_id)
        return jsonify({'url': login_link.url})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/create_payment_intent', methods=['POST'])
@authenticate
def create_payment_intent():
    data = request.json
    user_id = g.user_id
    amount = data.get('amount')
    portal_id = data.get('portal_id')
    goal_id = data.get('goal_id')
    currency = data.get('currency', 'usd')
    message = data.get('message', '')
    transaction_type = data.get('transaction_type', 'donation')
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or not portal.stripe_account_id:
        return jsonify({'error': 'Portal not set up to receive payments'}), 400
    goal = None
    if goal_id:
        goal = db.session.query(Goal).filter_by(id=goal_id).first()
        if not goal or goal.portals_id != portal_id:
            return jsonify({'error': 'Invalid goal for this portal'}), 400
    try:
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            transfer_data={'destination': portal.stripe_account_id},
            metadata={
                'portal_id': portal_id,
                'goal_id': goal_id,
                'user_id': user_id,
                'message': message,
                'transaction_type': transaction_type
            }
        )
        # Store transaction record in your database (pseudo-code, adjust as needed)
        # transaction = Transaction(
        #     user_id=user_id,
        #     portal_id=portal_id,
        #     goal_id=goal_id,
        #     amount=amount/100,
        #     message=message,
        #     transaction_type=transaction_type,
        #     payment_intent_id=payment_intent.id,
        #     status='pending'
        # )
        # db.session.add(transaction)
        # if goal and transaction_type in ['donation', 'payment']:
        #     progress_log = GoalProgressLog(
        #         users_id=user_id,
        #         goals_id=goal_id,
        #         added_value=amount/100,
        #         note=f"{transaction_type.capitalize()} via Stripe",
        #         value=(goal.filled_quota or 0) + (amount/100)
        #     )
        #     db.session.add(progress_log)
        #     goal.filled_quota = (goal.filled_quota or 0) + (amount/100)
        # db.session.commit()
        return jsonify({'clientSecret': payment_intent.client_secret})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/portal/payment_status', methods=['GET'])
@authenticate
def get_portal_payment_status():
    user_id = g.user_id
    portal_id = request.args.get('portal_id')
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or portal.users_id != user_id:
        return jsonify({'error': 'Not authorized'}), 403
    return jsonify({
        'stripe_account_id': portal.stripe_account_id or '',
        'is_connected': bool(portal.stripe_account_id),
    })

@payments_bp.route('/stripe/webhook', methods=['POST'])
def stripe_webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')
    try:
        # You must define stripe_webhook_secret in your config
        event = stripe.Webhook.construct_event(
            payload, sig_header, stripe_webhook_secret
        )
        if event['type'] == 'account.updated':
            account = event['data']['object']
            portal = db.session.query(Portal).filter_by(stripe_account_id=account['id']).first()
            if portal:
                portal.stripe_account_status = account['details_submitted']
                db.session.commit()
        # Handle payment_intent.succeeded, etc.
        return jsonify({'status': 'success'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/create_subscription', methods=['POST'])
@authenticate
def create_subscription():
    data = request.json
    user_id = g.user_id
    portal_id = data.get('portal_id')
    goal_id = data.get('goal_id')
    price_id = data.get('price_id')
    customer = get_or_create_stripe_customer(user_id)
    try:
        subscription = stripe.Subscription.create(
            customer=customer.id,
            items=[{"price": price_id}],
            payment_behavior="default_incomplete",
            expand=["latest_invoice.payment_intent"],
            metadata={
                "portal_id": portal_id,
                "goal_id": goal_id,
                "user_id": user_id,
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
@authenticate
def get_subscriptions():
    user_id = g.user_id
    customer = get_or_create_stripe_customer(user_id)
    try:
        subscriptions = stripe.Subscription.list(customer=customer.id, status='active', expand=['data.plan.product'])
        results = []
        for sub in subscriptions.data:
            portal_id = sub.metadata.get('portal_id')
            goal_id = sub.metadata.get('goal_id')
            display_name = "Rep Subscription"
            if goal_id:
                goal = db.session.query(Goal).filter_by(id=goal_id).first()
                if goal: display_name = goal.title
            elif portal_id:
                portal = db.session.query(Portal).filter_by(id=portal_id).first()
                if portal: display_name = portal.name
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
@authenticate
def get_payment_history():
    user_id = g.user_id
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
                if goal: display_name = f"{transaction_type.capitalize()} to {goal.title}"
            elif portal_id:
                portal = db.session.query(Portal).filter_by(id=portal_id).first()
                if portal: display_name = f"{transaction_type.capitalize()} to {portal.name}"
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
@authenticate
def cancel_subscription():
    data = request.json
    user_id = g.user_id
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