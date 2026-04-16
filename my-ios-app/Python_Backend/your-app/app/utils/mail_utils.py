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


def send_event_registration_email(user, portal):
    """
    Send a 'You're Registered!' confirmation email for an event portal join.
    Includes Google Calendar link and .ics download link.
    """
    from urllib.parse import quote
    from datetime import timedelta

    to_email = getattr(user, 'email', None)
    if not to_email:
        return False

    fname = getattr(user, 'fname', None) or 'there'
    portal_name = portal.name
    event_datetime = portal.event_datetime
    event_location = portal.event_location or ''
    event_timezone = portal.event_timezone or ''
    portal_url = f"https://www.repsomething.com/portal/{portal.id}"
    ics_url = f"https://rep-june2025.onrender.com/api/portal/{portal.id}/calendar.ics"

    # --- Format date for display ---
    formatted_date = ''
    google_cal_url = ''
    if event_datetime:
        day = event_datetime.day
        month = event_datetime.strftime('%B')
        year = event_datetime.year
        weekday = event_datetime.strftime('%A')
        hour = event_datetime.hour
        minute = event_datetime.strftime('%M')
        ampm = 'AM' if hour < 12 else 'PM'
        hour12 = hour % 12 or 12
        formatted_date = f"{weekday}, {month} {day}, {year} at {hour12}:{minute} {ampm}"
        if event_timezone:
            formatted_date += f" ({event_timezone})"

        # Google Calendar URL (floating time — displays in recipient's local timezone)
        start_str = event_datetime.strftime('%Y%m%dT%H%M%S')
        end_str = (event_datetime + timedelta(hours=1)).strftime('%Y%m%dT%H%M%S')
        gc_parts = [
            f"action=TEMPLATE",
            f"text={quote(portal_name)}",
            f"dates={start_str}/{end_str}",
        ]
        if event_location:
            gc_parts.append(f"location={quote(event_location)}")
        if portal.about:
            gc_parts.append(f"details={quote(portal.about[:200])}")
        google_cal_url = f"https://calendar.google.com/calendar/render?{'&'.join(gc_parts)}"

    # --- Build HTML ---
    green = '#8cc65d'
    dark_green = '#006600'

    date_row = f"""
        <tr>
          <td style="padding:6px 0;color:#555;font-size:15px;">
            &#128197; <strong>Date &amp; Time:</strong> {formatted_date}
          </td>
        </tr>""" if formatted_date else ''

    location_row = f"""
        <tr>
          <td style="padding:6px 0;color:#555;font-size:15px;">
            &#128205; <strong>Location:</strong> {event_location}
          </td>
        </tr>""" if event_location else ''

    calendar_buttons = ''
    if google_cal_url:
        calendar_buttons = f"""
        <tr><td style="padding:24px 0 8px;">
          <a href="{google_cal_url}"
             style="display:inline-block;background-color:{green};color:#fff;
                    font-weight:bold;font-size:15px;padding:12px 24px;
                    border-radius:8px;text-decoration:none;margin-right:12px;">
            Add to Google Calendar
          </a>
          <a href="{ics_url}"
             style="display:inline-block;background-color:#fff;color:{dark_green};
                    font-weight:bold;font-size:15px;padding:12px 24px;
                    border-radius:8px;text-decoration:none;
                    border:2px solid {dark_green};">
            Download .ics
          </a>
        </td></tr>"""

    html = f"""
    <div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;background:#fff;">
      <div style="background-color:{green};padding:28px 32px;border-radius:8px 8px 0 0;">
        <h1 style="color:#fff;margin:0;font-size:26px;">You're Registered! &#10003;</h1>
      </div>
      <div style="padding:28px 32px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px;">
        <p style="font-size:17px;color:#111;margin-top:0;">
          Hi {fname},<br><br>
          You're confirmed for <strong>{portal_name}</strong>.
        </p>
        <table style="width:100%;border-collapse:collapse;margin:16px 0;">
          {date_row}
          {location_row}
        </table>
        {calendar_buttons}
        <p style="margin-top:28px;font-size:14px;color:#888;">
          View the event page:
          <a href="{portal_url}" style="color:{dark_green};">{portal_url}</a>
        </p>
        <p style="font-size:13px;color:#aaa;margin-top:24px;">
          Rep &mdash; Purpose-driven community
        </p>
      </div>
    </div>
    """

    return send_mail(to_email, f"You're Registered for {portal_name}!", html)