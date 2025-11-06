# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

import os
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def send_mail(to, subject, body, from_email='contact@repsomething.com'):
    """
    Send an email using SendGrid.
    """
    message = Mail(
        from_email=from_email,
        to_emails=to,
        subject=subject,
        html_content=body
    )
    try:
        sg = SendGridAPIClient(os.environ['SENDGRID_API_KEY'])
        response = sg.send(message)
        return response.status_code == 202
    except Exception as e:
        print(f"SendGrid error: {e}")
        return False