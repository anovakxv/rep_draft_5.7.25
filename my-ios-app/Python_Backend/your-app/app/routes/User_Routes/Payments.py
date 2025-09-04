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