# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

import os
import resend

def send_mail(to, subject, body, from_email='contact@repsomething.com'):
    """
    Send an email using Resend.
    """
    resend.api_key = os.environ.get('RESEND_API_KEY')
    try:
        resend.Emails.send({
            "from": from_email,
            "to": [to] if isinstance(to, str) else to,
            "subject": subject,
            "html": body
        })
        return True
    except Exception as e:
        print(f"Resend error: {e}")
        return False