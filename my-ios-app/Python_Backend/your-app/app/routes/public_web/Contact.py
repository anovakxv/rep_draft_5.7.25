# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# PUBLIC WEB ROUTES - Contact Us form intake (no authentication)
#
# Additive, self-contained endpoint for the public Contact Us page
# (www.repsomething.com/contact-us). Emails the submission to the support inbox
# using the existing Resend wiring (mail_utils.send_mail), with Reply-To set to the
# sender so support can reply directly. No DB writes, no schema changes.

import re
from flask import Blueprint, request, jsonify
from markupsafe import escape

from app import limiter
from app.utils.mail_utils import send_mail

public_contact_bp = Blueprint('public_contact', __name__)

# Where Contact Us submissions are delivered (also the verified Resend sender domain).
SUPPORT_INBOX = 'contact@repsomething.com'

# Length caps — bound payload size and abuse. Mirrors the client-side form expectations.
_MAX_NAME = 200
_MAX_EMAIL = 254
_MAX_SUBJECT = 200
_MAX_MESSAGE = 5000

_EMAIL_RE = re.compile(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')


@public_contact_bp.route('/contact', methods=['POST'])
@limiter.limit("5 per hour")
def public_contact():
    """Accept a Contact Us submission and email it to the support inbox.

    Public (no auth) + rate-limited (5/hr per IP) since it's an open, spammable form.
    All user input is HTML-escaped before being placed in the HTML email body to
    prevent injection (same defense used by send_event_registration_email).
    """
    data = request.get_json(silent=True) or {}
    name = (data.get('name') or '').strip()
    email = (data.get('email') or '').strip()
    subject = (data.get('subject') or '').strip()
    message = (data.get('message') or '').strip()

    # Required fields
    if not name or not email or not message:
        return jsonify({'error': 'Name, email, and message are required.'}), 400
    if not _EMAIL_RE.match(email):
        return jsonify({'error': 'Please enter a valid email address.'}), 400

    # Length caps (defense against oversized / abusive payloads)
    if (len(name) > _MAX_NAME or len(email) > _MAX_EMAIL
            or len(subject) > _MAX_SUBJECT or len(message) > _MAX_MESSAGE):
        return jsonify({'error': 'One or more fields are too long.'}), 400

    # HTML-escape ALL user-controlled values before embedding in the email body.
    # Newlines in the message are preserved by `white-space:pre-wrap` on its <p> below
    # (do NOT .replace() on the escaped Markup — that would escape the replacement too).
    name_h = escape(name)
    email_h = escape(email)
    subject_h = escape(subject) if subject else '(no subject)'
    message_h = escape(message)

    html = f"""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#111;">
      <h2 style="color:#006600;margin:0 0 12px;">New Contact Us message</h2>
      <p style="margin:4px 0;"><strong>Name:</strong> {name_h}</p>
      <p style="margin:4px 0;"><strong>Email:</strong> {email_h}</p>
      <p style="margin:4px 0;"><strong>Subject:</strong> {subject_h}</p>
      <hr style="border:none;border-top:1px solid #e5e7eb;margin:16px 0;">
      <p style="white-space:pre-wrap;line-height:1.5;">{message_h}</p>
      <hr style="border:none;border-top:1px solid #e5e7eb;margin:16px 0;">
      <p style="font-size:12px;color:#999;">
        Sent from the Rep Contact Us form (www.repsomething.com/contact-us).
        Reply directly to this email to respond to {email_h}.
      </p>
    </div>
    """

    subject_line = f"[Rep Contact] {subject}" if subject else f"[Rep Contact] Message from {name}"

    sent = send_mail(
        SUPPORT_INBOX,
        subject_line,
        html,
        reply_to=email,  # replies go straight to the person who contacted us
    )
    if not sent:
        return jsonify({
            'error': 'Could not send your message right now. '
                     'Please email us directly at contact@repsomething.com.'
        }), 502

    return jsonify({'result': 'sent'}), 200
