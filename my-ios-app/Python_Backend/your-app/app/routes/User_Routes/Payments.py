# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: September 2025

@app.route('/api/create_setup_intent', methods=['POST'])
@authenticate
def create_setup_intent():
    # Get the user from your authentication
    user_id = g.user_id
    
    # Get or create a Stripe customer for this user
    customer = get_or_create_stripe_customer(user_id)
    
    # Create a SetupIntent
    setup_intent = stripe.SetupIntent.create(
        customer=customer.id,
        payment_method_types=['card'],
    )
    
    # Return only the client secret to the app
    return jsonify({'clientSecret': setup_intent.client_secret})

# Add to your Python backend (Payments.py)
@app.route('/api/create_connect_account', methods=['POST'])
@authenticate
def create_connect_account():
    data = request.json
    user_id = g.user_id
    portal_id = data.get('portal_id')
    redirect_url = data.get('redirect_url')
    
    # Verify user owns this portal
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or portal.users_id != user_id:
        return jsonify({'error': 'Not authorized'}), 403
    
    try:
        # Create a Stripe Connected account (Express account)
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
        
        # Store the account ID
        portal.stripe_account_id = account.id
        db.session.commit()
        
        # Create an account link for onboarding
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

@app.route('/api/stripe_dashboard_link', methods=['POST'])
@authenticate
def stripe_dashboard_link():
    data = request.json
    user_id = g.user_id
    account_id = data.get('account_id')
    
    # Verify user owns this account
    portal = db.session.query(Portal).filter_by(stripe_account_id=account_id).first()
    if not portal or portal.users_id != user_id:
        return jsonify({'error': 'Not authorized'}), 403
    
    try:
        # Create a login link to the Stripe Express dashboard
        login_link = stripe.Account.create_login_link(account_id)
        
        return jsonify({
            'url': login_link.url
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400
    
@app.route('/api/create_payment_intent', methods=['POST'])
@authenticate
def create_payment_intent():
    data = request.json
    user_id = g.user_id
    
    amount = data.get('amount')
    portal_id = data.get('portal_id')
    goal_id = data.get('goal_id')  # New: Associate with a specific goal
    currency = data.get('currency', 'usd')
    message = data.get('message', '')
    transaction_type = data.get('transaction_type', 'donation')  # New: Transaction type
    
    # Get portal's connected account ID
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or not portal.stripe_account_id:
        return jsonify({'error': 'Portal not set up to receive payments'}), 400
    
    # Check if goal exists and belongs to portal
    goal = None
    if goal_id:
        goal = db.session.query(Goal).filter_by(id=goal_id).first()
        if not goal or goal.portals_id != portal_id:
            return jsonify({'error': 'Invalid goal for this portal'}), 400
    
    try:
        # Create payment intent that sends payment to the connected account
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            application_fee_amount=int(amount * 0.05),  # 5% platform fee
            transfer_data={
                'destination': portal.stripe_account_id,
            },
            metadata={
                'portal_id': portal_id,
                'goal_id': goal_id,
                'user_id': user_id,
                'message': message,
                'transaction_type': transaction_type
            }
        )
        
        # Store transaction record in your database
        transaction = Transaction(
            user_id=user_id,
            portal_id=portal_id,
            goal_id=goal_id,
            amount=amount/100,  # Store in dollars
            message=message,
            transaction_type=transaction_type,
            payment_intent_id=payment_intent.id,
            status='pending'
        )
        db.session.add(transaction)
        
        # If this is for a goal, update goal's progress
        if goal and transaction_type in ['donation', 'payment']:
            # Create a progress log for the goal
            progress_log = GoalProgressLog(
                users_id=user_id,
                goals_id=goal_id,
                added_value=amount/100,  # Amount in dollars
                note=f"{transaction_type.capitalize()} via Stripe",
                value=(goal.filled_quota or 0) + (amount/100)
            )
            db.session.add(progress_log)
            
            # Update the goal's filled quota
            goal.filled_quota = (goal.filled_quota or 0) + (amount/100)
        
        db.session.commit()
        
        return jsonify({
            'clientSecret': payment_intent.client_secret
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400
@app.route('/api/portal/payment_status', methods=['GET'])
@authenticate
def get_portal_payment_status():
    user_id = g.user_id
    portal_id = request.args.get('portal_id')
    
    # Verify user has access to this portal
    portal = db.session.query(Portal).filter_by(id=portal_id).first()
    if not portal or portal.users_id != user_id:
        return jsonify({'error': 'Not authorized'}), 403
        
    return jsonify({
        'stripe_account_id': portal.stripe_account_id or '',
        'is_connected': bool(portal.stripe_account_id),
    })    