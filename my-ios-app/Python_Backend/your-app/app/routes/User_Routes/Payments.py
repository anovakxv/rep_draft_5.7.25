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
from app.models.People_Models.user import User 
from datetime import datetime
from app.models.ValueMetric_Models.Transaction import Transaction 
import os

stripe.api_key = os.environ.get("STRIPE_SECRET_KEY")

# Define the Blueprint
payments_bp = Blueprint('payments', __name__)

def get_or_create_stripe_customer(user_id):
    user = db.session.query(User).filter_by(id=user_id).first()
    if not user:
        raise Exception("User not found")
    if hasattr(user, "stripe_customer_id") and user.stripe_customer_id:
        return stripe.Customer.retrieve(user.stripe_customer_id)
    customer = stripe.Customer.create(email=user.email)
    user.stripe_customer_id = customer.id
    db.session.commit()
    return customer

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

    print(f"[Connect] Received data: {data}, user_id: {user_id}")

    if not portal_id:
        print("[Connect] Missing portal_id")
        return jsonify({'error': 'portal_id is required'}), 400

    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    print(f"[Connect] Portal found: {portal is not None}, portal.users_id: {getattr(portal, 'users_id', None)}")

    if not portal:
        print("[Connect] Portal not found for portal_id:", portal_id)
        return jsonify({'error': 'Portal not found'}), 400

    if str(portal.users_id) != str(user_id):
        print(f"[Connect] Not authorized: portal.users_id={portal.users_id}, user_id={user_id}")
        return jsonify({'error': 'Not authorized'}), 403

    try:
        # Check if portal already has an approved Stripe account
        if portal.stripe_account_id:
            print(f"[Connect] Portal {portal_id} already has approved account: {portal.stripe_account_id}")
            # Generate AccountLink for onboarding/dashboard access
            account_link = stripe.AccountLink.create(
                account=portal.stripe_account_id,
                refresh_url=redirect_url,
                return_url=redirect_url,
                type='account_onboarding'
            )
            print(f"[Connect] Generated AccountLink URL for portal {portal_id}")
            return jsonify({
                'url': account_link.url,
                'account_id': portal.stripe_account_id
            })

        # CHANGE: Instead of creating Stripe account, just mark as requested
        portal.stripe_connect_requested = True
        db.session.commit()

        print(f"[Connect] Marked portal {portal_id} as requesting Stripe Connect")

        # Return success message
        return jsonify({
            'status': 'pending_approval',
            'message': 'Your Stripe Connect request has been submitted for admin approval. You will be notified when it has been approved.'
        })

    except Exception as e:
        print(f"[Connect] Error: {str(e)}")
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
    print(f"[PaymentIntent] Received data: {data}, user_id: {user_id}")

    amount = data.get('amount')
    portal_id = data.get('portal_id')
    goal_id = data.get('goal_id')
    currency = data.get('currency', 'usd')
    message = data.get('message', '')
    transaction_type = data.get('transaction_type', 'donation')

    print(f"[PaymentIntent] amount: {amount}, portal_id: {portal_id}, goal_id: {goal_id}, currency: {currency}, transaction_type: {transaction_type}")

    if not amount:
        print("[PaymentIntent] Missing amount")
        return jsonify({'error': 'amount is required'}), 400
    if not portal_id:
        print("[PaymentIntent] Missing portal_id")
        return jsonify({'error': 'portal_id is required'}), 400

    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    print(f"[PaymentIntent] Portal found: {portal is not None}, stripe_account_id: {getattr(portal, 'stripe_account_id', None)}")

    if not portal or not portal.stripe_account_id:
        print("[PaymentIntent] Portal not set up to receive payments")
        return jsonify({'error': 'Portal not set up to receive payments'}), 400

    customer = get_or_create_stripe_customer(user_id)
    print(f"[PaymentIntent] Stripe customer: {customer.id}")

    goal = None
    if goal_id:
        goal = db.session.query(Goal).filter_by(id=goal_id).first()
        print(f"[PaymentIntent] Goal found: {goal is not None}")

    try:
        print("[PaymentIntent] Creating Stripe PaymentIntent...")
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            customer=customer.id,
            transfer_data={'destination': portal.stripe_account_id},
            metadata={
                'portal_id': str(portal_id),
                'goal_id': str(goal_id) if goal_id else '',
                'user_id': str(user_id),
                'message': message,
                'transaction_type': transaction_type
            }
        )
        print(f"[PaymentIntent] Created intent: {payment_intent.id}")
        
        # Record transaction in DB (with pending status)
        transaction = Transaction(
            user_id=user_id,
            portal_id=portal_id,
            goal_id=goal_id if goal_id else None,
            amount=amount,
            currency=currency,
            transaction_type=transaction_type,
            message=message,
            stripe_payment_intent_id=payment_intent.id,
            status='pending',
            created_at=datetime.utcnow()
        )
        db.session.add(transaction)
        db.session.commit()
        
        return jsonify({'clientSecret': payment_intent.client_secret})
    except Exception as e:
        print(f"[PaymentIntent] Stripe error: {str(e)}")
        return jsonify({'error': str(e)}), 400

        # Optionally record transaction + goal progress in DB (left commented for now)
        # transaction = Transaction(...)
        # db.session.add(transaction)
        # if goal and transaction_type in ['donation', 'payment']:
        #     progress_log = GoalProgressLog(...)
        #     db.session.add(progress_log)
        #     goal.filled_quota = (goal.filled_quota or 0) + (amount/100)
        # db.session.commit()

@payments_bp.route('/api/create_customer_portal', methods=['POST'])
@jwt_required
def create_customer_portal():
    user_id = g.current_user.id
    data = request.json or {}
    return_url = data.get('return_url', 'https://rep-june2025.onrender.com/payment-return?status=success')

    # Get or create Stripe customer for the user
    customer = get_or_create_stripe_customer(user_id)

    try:
        session = stripe.billing_portal.Session.create(
            customer=customer.id,
            return_url=return_url
        )
        return jsonify({'url': session.url})
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

    # Default to database value
    account_status = portal.stripe_account_status if hasattr(portal, 'stripe_account_status') else False
    
    # If portal has a Stripe account, check its real-time status
    if portal.stripe_account_id:
        try:
            # Get the latest account info directly from Stripe
            stripe_account = stripe.Account.retrieve(portal.stripe_account_id)
            
            # An account is FULLY setup if BOTH details_submitted AND charges_enabled are true
            account_status = stripe_account.get('details_submitted', False) and stripe_account.get('charges_enabled', False)
            
            # Log for debugging
            print(f"[Payment Status] Portal {portal_id}: details_submitted={stripe_account.get('details_submitted', False)}, charges_enabled={stripe_account.get('charges_enabled', False)}")
            
        except Exception as e:
            # On error, fall back to database value
            print(f"[Payment Status] Error checking Stripe account {portal.stripe_account_id}: {str(e)}")
            # No change to account_status - keep using database value

    return jsonify({
        'stripe_account_id': portal.stripe_account_id or '',
        'is_connected': bool(portal.stripe_account_id),
        'account_status': account_status,
        'stripe_connect_requested': portal.stripe_connect_requested if hasattr(portal, 'stripe_connect_requested') else False
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
        print(f"[Webhook] Processing event: {event['type']}")

        if event['type'] == 'account.updated':
            account = event['data']['object']
            portal = db.session.query(Portal).filter_by(stripe_account_id=account['id']).first()
            if portal:
                portal.stripe_account_status = account.get('details_submitted', False) and account.get('charges_enabled', False)
                print(f"[Webhook] Updated portal {portal.id} account status: details_submitted={account.get('details_submitted', False)}, charges_enabled={account.get('charges_enabled', False)}")
                db.session.commit()

        elif event['type'] == 'payment_intent.succeeded':
            payment_intent = event['data']['object']
            print(f"[Webhook] Payment succeeded: {payment_intent['id']}")

            # Skip processing for invoice payments - let the invoice handler handle subscriptions
            if payment_intent.get('invoice'):
                print(f"[Webhook] Payment intent is for an invoice ({payment_intent.get('invoice')}). Skipping to avoid duplicate processing.")
                return jsonify({'status': 'success - handled by invoice webhook'})

            existing_transaction = db.session.query(Transaction).filter_by(
                stripe_payment_intent_id=payment_intent['id']
            ).first()
            if existing_transaction:
                if existing_transaction.status == 'completed':
                    print(f"[Webhook] Transaction {existing_transaction.id} already processed")
                    return jsonify({'status': 'success'})
                existing_transaction.status = 'completed'
                db.session.commit()
                transaction = existing_transaction
            else:
                try:
                    goal_id = payment_intent['metadata'].get('goal_id')
                    user_id = payment_intent['metadata'].get('user_id')
                    portal_id = payment_intent['metadata'].get('portal_id')
                    message = payment_intent['metadata'].get('message', '')
                    transaction_type = payment_intent['metadata'].get('transaction_type', 'donation')
                    is_public = payment_intent['metadata'].get('is_public') == 'true'  # Guest payment flag
                    if (not goal_id or not user_id or not portal_id) and 'invoice' in payment_intent and payment_intent['invoice']:
                        print(f"[Webhook] This appears to be a subscription payment, retrieving invoice: {payment_intent['invoice']}")
                        try:
                            invoice = stripe.Invoice.retrieve(payment_intent['invoice'])
                            subscription_id = invoice.get('subscription')
                            if subscription_id:
                                print(f"[Webhook] Found subscription: {subscription_id}")
                                subscription = stripe.Subscription.retrieve(subscription_id)
                                goal_id = subscription.metadata.get('goal_id')
                                user_id = subscription.metadata.get('user_id')
                                portal_id = subscription.metadata.get('portal_id')
                                message = subscription.metadata.get('message', 'Monthly subscription payment')
                                transaction_type = 'subscription'
                                print(f"[Webhook] Retrieved metadata from subscription: goal_id={goal_id}, user_id={user_id}, portal_id={portal_id}")
                        except Exception as e:
                            print(f"[Webhook] Error retrieving subscription data: {str(e)}")
                            import traceback
                            traceback.print_exc()
                    # Validate metadata: portal_id required, user_id required unless is_public
                    if not portal_id:
                        print(f"[Webhook] Missing portal_id: {portal_id}")
                        return jsonify({'error': 'Missing portal_id'}), 400
                    if not user_id and not is_public:
                        print(f"[Webhook] Missing user_id for authenticated payment: {user_id}")
                        return jsonify({'error': 'Missing user_id'}), 400
                    transaction = Transaction(
                        user_id=user_id,
                        portal_id=portal_id,
                        goal_id=goal_id if goal_id else None,
                        amount=payment_intent['amount'],
                        currency=payment_intent['currency'],
                        transaction_type=transaction_type,
                        message=message,
                        stripe_payment_intent_id=payment_intent['id'],
                        status='completed',
                        created_at=datetime.fromtimestamp(payment_intent['created'])
                    )
                    db.session.add(transaction)
                    db.session.commit()
                    print(f"[Webhook] Created transaction {transaction.id}")
                except Exception as e:
                    print(f"[Webhook] Error creating transaction: {str(e)}")
                    db.session.rollback()
                    return jsonify({'error': str(e)}), 500
            if transaction.goal_id and transaction.transaction_type in ['donation', 'payment', 'subscription']:
                try:
                    goal = db.session.query(Goal).filter_by(id=transaction.goal_id).first()
                    if goal and goal.goal_type in ['Fund', 'Sales']:
                        amount_in_units = transaction.amount / 100
                        progress_log = GoalProgressLog(
                            users_id=transaction.user_id,
                            goals_id=transaction.goal_id,
                            added_value=amount_in_units,
                            note=f"({transaction.transaction_type.capitalize()}) {transaction.message}",
                            value=(goal.filled_quota or 0) + amount_in_units
                        )
                        db.session.add(progress_log)
                        goal.filled_quota = (goal.filled_quota or 0) + amount_in_units
                        db.session.commit()
                        print(f"[Webhook] Updated goal {goal.id} progress: +{amount_in_units} units")
                except Exception as e:
                    print(f"[Webhook] Error updating goal progress: {str(e)}")
                    db.session.rollback()
                    return jsonify({'error': str(e)}), 500

        elif event['type'] == 'invoice.payment_succeeded':
            invoice = event['data']['object']
            print(f"[Webhook] Invoice payment succeeded: {invoice.id}")
            try:
                # DIRECT APPROACH: Get customer_id and find their active subscriptions
                customer_id = invoice.get('customer')
                if customer_id:
                    print(f"[Webhook] Looking up subscriptions for customer: {customer_id}")
                    subscriptions = stripe.Subscription.list(
                        customer=customer_id,
                        limit=5,
                        status='active',
                        expand=['data.latest_invoice']
                    )

                    # Find the subscription that matches this invoice
                    subscription_id = None
                    subscription = None
                    for sub in subscriptions.data:
                        if hasattr(sub, 'latest_invoice') and sub.latest_invoice and sub.latest_invoice.id == invoice.id:
                            subscription_id = sub.id
                            subscription = sub
                            print(f"[Webhook] Found matching subscription: {subscription_id}")
                            break

                    if subscription:
                        goal_id = subscription.metadata.get('goal_id')
                        user_id = subscription.metadata.get('user_id')
                        portal_id = subscription.metadata.get('portal_id')
                        payment_intent_id = invoice.get('payment_intent')

                        # CRITICAL FIX: Make payment_intent_id unique for each recurring payment
                        # by adding timestamp to avoid unique constraint violation
                        unique_payment_id = f"{payment_intent_id}_{int(datetime.now().timestamp())}"

                        if user_id and portal_id:
                            # Only check for existing transaction by payment_intent_id
                            existing_transaction = db.session.query(Transaction).filter_by(
                                stripe_payment_intent_id=invoice.id,
                                transaction_type='subscription'
                            ).first()

                            if not existing_transaction:
                                # Create new Transaction and GoalProgressLog for this payment
                                transaction = Transaction(
                                    user_id=user_id,
                                    portal_id=portal_id,
                                    goal_id=goal_id if goal_id else None,
                                    amount=invoice.get('amount_paid'),
                                    currency=invoice.get('currency'),
                                    transaction_type='subscription',
                                    message="Monthly subscription payment",
                                    stripe_payment_intent_id=invoice.id, 
                                    status='completed',
                                    created_at=datetime.fromtimestamp(invoice.get('created'))
                                )
                                db.session.add(transaction)

                                if goal_id:
                                    goal = db.session.query(Goal).filter_by(id=goal_id).first()
                                    if goal and goal.goal_type in ['Fund', 'Sales']:
                                        amount_in_units = invoice.get('amount_paid') / 100
                                        progress_log = GoalProgressLog(
                                            users_id=user_id,
                                            goals_id=goal_id,
                                            added_value=amount_in_units,
                                            note="Monthly subscription payment",
                                            value=(goal.filled_quota or 0) + amount_in_units
                                        )
                                        db.session.add(progress_log)
                                        goal.filled_quota = (goal.filled_quota or 0) + amount_in_units
                                db.session.commit()
                                print(f"[Webhook] Processed subscription payment successfully")
                            else:
                                print(f"[Webhook] Subscription payment already processed: {existing_transaction.id}")
                                # Do not create a new GoalProgressLog for the same payment_intent_id
                                return jsonify({'status': 'success'})
                        else:
                            print(f"[Webhook] Could not process subscription - missing required metadata in subscription object")
                    else:
                        print(f"[Webhook] Could not find matching subscription for invoice: {invoice.id}")
                else:
                    print(f"[Webhook] Invoice has no customer ID")
            except Exception as e:
                print(f"[Webhook] Error processing subscription: {str(e)}")
                import traceback
                traceback.print_exc()

        return jsonify({'status': 'success'})
    except Exception as e:
        print(f"[Webhook] Error: {str(e)}")
        import traceback
        traceback.print_exc()
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

            # Defensive: handle missing current_period_end
            next_billing = 0
            try:
                next_billing = int(getattr(sub, 'current_period_end', 0)) if getattr(sub, 'current_period_end', None) else 0
            except Exception as e:
                print(f"[Subscriptions] Error with current_period_end for sub {sub.id}: {str(e)}")
                next_billing = 0

            results.append({
                'id': sub.id,
                'name': display_name,
                'amount': sub.plan.amount,
                'nextBillingDate': next_billing
            })
        return jsonify(results)
    except Exception as e:
        print(f"[Subscriptions] Error: {str(e)}")
        # Always return a list, even if empty, to avoid frontend decoding errors
        return jsonify([]), 200

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

@payments_bp.route('/api/create_checkout_session', methods=['POST'])
@jwt_required
def create_checkout_session():
    data = request.json or {}
    user_id = g.current_user.id
    print(f"[Checkout] Received data: {data}, user_id: {user_id}")

    amount = data.get('amount')
    portal_id = data.get('portal_id')
    goal_id = data.get('goal_id')
    currency = data.get('currency', 'usd')
    message = data.get('message', '')
    transaction_type = data.get('transaction_type', 'donation')
    is_subscription = data.get('is_subscription', False)
    price_id = data.get('price_id')

    print(f"[Checkout] amount: {amount}, portal_id: {portal_id}, goal_id: {goal_id}, currency: {currency}, transaction_type: {transaction_type}, is_subscription: {is_subscription}, price_id: {price_id}")

    if not amount and not price_id:
        print("[Checkout] Missing amount or price_id")
        return jsonify({'error': 'amount or price_id is required'}), 400
    if not portal_id:
        print("[Checkout] Missing portal_id")
        return jsonify({'error': 'portal_id is required'}), 400

    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    print(f"[Checkout] Portal found: {portal is not None}, stripe_account_id: {getattr(portal, 'stripe_account_id', None)}")

    if not portal or not portal.stripe_account_id:
        print("[Checkout] Portal not set up to receive payments")
        return jsonify({'error': 'Portal not set up to receive payments'}), 400

    customer = get_or_create_stripe_customer(user_id)
    print(f"[Checkout] Stripe customer: {customer.id}")

    success_url = f"https://rep-june2025.onrender.com/payment-return?status=success&session_id={{CHECKOUT_SESSION_ID}}"
    cancel_url = f"https://rep-june2025.onrender.com/payment-return?status=canceled"

    goal = None
    if goal_id:
        goal = db.session.query(Goal).filter_by(id=goal_id).first()
        print(f"[Checkout] Goal found: {goal is not None}")

    try:
        session_params = {
            'customer': customer.id,
            'success_url': success_url,
            'cancel_url': cancel_url,
            'payment_method_types': ['card'],
            'client_reference_id': str(user_id),
            'metadata': {
                'portal_id': str(portal_id),
                'goal_id': str(goal_id) if goal_id else '',
                'user_id': str(user_id),
                'transaction_type': transaction_type
            }
        }

        if is_subscription and price_id:
            print("[Checkout] Creating subscription checkout session")
            session_params['mode'] = 'subscription'
            session_params['line_items'] = [{
                'price': price_id,
                'quantity': 1
            }]
             # FIX: Add subscription_data with metadata to ensure it's attached to the created subscription
            session_params['subscription_data'] = {
                'metadata': {
                    'portal_id': str(portal_id),
                    'goal_id': str(goal_id) if goal_id else '',
                    'user_id': str(user_id),
                    'message': message,
                    'transaction_type': transaction_type
                },
                'transfer_data': {
                    'destination': portal.stripe_account_id,
                }
            }
        else:
            print("[Checkout] Creating payment checkout session")
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
                    'user_id': str(user_id),
                    'message': message,
                    'transaction_type': transaction_type
                }
            }

        print(f"[Checkout] Stripe session params: {session_params}")
        checkout_session = stripe.checkout.Session.create(**session_params)
        print(f"[Checkout] Created session: {checkout_session.id}, url: {checkout_session.url}")

        return jsonify({
            'checkout_url': checkout_session.url,
            'session_id': checkout_session.id
        })
    except Exception as e:
        print(f"[Checkout] Stripe error: {str(e)}")
        return jsonify({'error': str(e)}), 400

@payments_bp.route('/api/checkout_session_status', methods=['GET'])
@jwt_required
def checkout_session_status():
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
        return jsonify({'error': str(e)}), 400        

@payments_bp.route('/stripe-connect-return', methods=['GET'])
def stripe_connect_return():
    portal_id = request.args.get('portal_id')
    status = request.args.get('status')
    
    # Create a redirect to your app using a custom scheme
    redirect_url = f"rep://stripe-connect-return?portal_id={portal_id}&status={status}"
    
    # Return a simple HTML page that will redirect to your app
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Redirecting to Rep</title>
        <meta http-equiv="refresh" content="0;url={redirect_url}" />
    </head>
    <body>
        <p>Redirecting to Rep app...</p>
        <p>If you are not redirected, <a href="{redirect_url}">click here</a>.</p>
        <script>
            window.location.href = "{redirect_url}";
        </script>
    </body>
    </html>
    """

@payments_bp.route('/payment-return', methods=['GET'])
def payment_return():
    status = request.args.get('status')
    session_id = request.args.get('session_id', '')
    
    # Create a redirect to your app using a custom scheme
    if status == "success":
        redirect_url = f"rep://payment-success?session_id={session_id}"
    else:
        redirect_url = f"rep://payment-canceled"
    
    # Return a simple HTML page that will redirect to your app
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Redirecting to Rep</title>
        <meta http-equiv="refresh" content="0;url={redirect_url}" />
    </head>
    <body>
        <p>Redirecting to Rep app...</p>
        <p>If you are not redirected, <a href="{redirect_url}">click here</a>.</p>
        <script>
            window.location.href = "{redirect_url}";
        </script>
    </body>
    </html>
    """

# --- Admin Endpoints for Stripe Connect Account Approval ---

@payments_bp.route('/api/admin/stripe_accounts/pending', methods=['GET'])
@jwt_required
def list_pending_stripe_accounts():
    # Only allow admin users
    if not hasattr(g.current_user, 'user_type') or getattr(g.current_user.user_type, 'title', '') != "Admin":
        return jsonify({'error': 'Not authorized'}), 403

    # CHANGE: Get portals that requested Stripe but don't have accounts yet
    pending_portals = db.session.query(Portal).filter(
        Portal.stripe_connect_requested == True,
        Portal.stripe_account_id.is_(None)
    ).all()

    results = []
    for portal in pending_portals:
        results.append({
            'id': portal.id,
            'name': portal.name,
            'requested_at': portal.updated_at.isoformat() if hasattr(portal, 'updated_at') and portal.updated_at else None
        })
    return jsonify(results)

@payments_bp.route('/api/admin/stripe_accounts/approve', methods=['POST'])
@jwt_required
def approve_stripe_account():
    # Only allow admin users
    if not hasattr(g.current_user, 'user_type') or getattr(g.current_user.user_type, 'title', '') != "Admin":
        return jsonify({'error': 'Not authorized'}), 403

    data = request.json or {}
    portal_id = data.get('portal_id')
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    
    if not portal or not portal.stripe_connect_requested:
        return jsonify({'error': 'Portal not found or no pending request'}), 404

    try:
        # CHANGE: Create Stripe account here, after admin approval
        account = stripe.Account.create(
            type="express",
            country="US",
            email=portal.email if hasattr(portal, 'email') else None,
            capabilities={
                "transfers": {"requested": True},
                "card_payments": {"requested": True}
            },
            business_type="individual"
        )
        
        # Save Stripe account ID and mark as approved
        portal.stripe_account_id = account.id
        portal.stripe_account_approved = True
        portal.stripe_connect_requested = False  # Clear the request flag since it's been approved
        db.session.commit()

        print(f"[Connect] Approved portal {portal_id}: account_id={account.id}, cleared request flag")

        return jsonify({
            'status': 'approved',
            'account_id': account.id
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400