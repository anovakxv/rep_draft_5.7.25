# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: January 2025

"""
Scheduler setup for background tasks using Flask-APScheduler.

This module configures scheduled jobs (cron tasks) for the application.
The scheduler only runs when WORKER_MODE environment variable is set to 'true'.

This allows us to run a separate worker process for background jobs,
keeping them isolated from the main web API process.
"""

import os
from flask_apscheduler import APScheduler

# Initialize scheduler (but don't start yet)
scheduler = APScheduler()


def init_scheduler(app):
    """
    Initialize and start the scheduler with the Flask app.

    This function should be called from app/__init__.py during app creation.

    The scheduler will ONLY start if the WORKER_MODE environment variable
    is set to 'true'. This prevents the scheduler from running in the main
    web process and allows us to run a dedicated worker process.

    Args:
        app: Flask application instance

    Environment Variables:
        WORKER_MODE: Set to 'true' to enable scheduler (default: false)
                     This should ONLY be true in the dedicated worker process

    Jobs Configured:
        - daily_email_summary: Runs at 8:00 AM UTC daily
          Sends email digests to users with messages from last 24 hours

    Example:
        # In app/__init__.py
        from app.scheduler import init_scheduler
        init_scheduler(app)

    Deployment:
        On Render, create two services from same repo:
        1. Web Service: WORKER_MODE=false (serves API)
        2. Background Worker: WORKER_MODE=true (runs scheduler)
    """

    # Check if we should start the scheduler
    worker_mode = os.getenv('WORKER_MODE', 'false').lower()

    if worker_mode != 'true':
        print("[Scheduler] WORKER_MODE not enabled, skipping scheduler setup")
        print("[Scheduler] Set WORKER_MODE=true to enable background jobs")
        return

    print("[Scheduler] WORKER_MODE enabled, initializing scheduler...")

    # Initialize scheduler with Flask app
    scheduler.init_app(app)

    # Configure scheduled jobs
    _add_jobs()

    # Start the scheduler
    scheduler.start()

    print("[Scheduler] ✓ Scheduler started successfully")
    print("[Scheduler] Active jobs:")
    for job in scheduler.get_jobs():
        print(f"  - {job.id}: {job.trigger}")


def _add_jobs():
    """
    Add all scheduled jobs to the scheduler.

    This is an internal function called by init_scheduler().

    Jobs:
        1. daily_email_summary
           - Runs: Daily at 8:00 AM UTC
           - Function: send_daily_summary()
           - Purpose: Send email digest to users with new messages
    """

    # Lazy import to avoid circular dependency
    # (app/__init__.py imports scheduler, which needs db to be initialized first)
    from app.tasks.daily_email_summary import send_daily_summary

    # Job 1: Daily Email Summary
    # Runs at 8:00 AM UTC every day
    # Users receive morning summary of messages from previous 24 hours
    scheduler.add_job(
        id='daily_email_summary',
        func=send_daily_summary,
        trigger='cron',
        hour=8,
        minute=0,
        timezone='UTC',
        max_instances=1,  # Prevent overlapping runs
        coalesce=True,    # If multiple runs are pending, only run once
        misfire_grace_time=3600  # Allow up to 1 hour delay if server was down
    )

    print("[Scheduler] Added job: daily_email_summary (08:00 UTC daily)")

    # Future jobs can be added here:
    # scheduler.add_job(
    #     id='weekly_digest',
    #     func=send_weekly_digest,
    #     trigger='cron',
    #     day_of_week='mon',
    #     hour=8,
    #     minute=0,
    #     timezone='UTC'
    # )


def shutdown_scheduler():
    """
    Gracefully shutdown the scheduler.

    This function should be called when the application is shutting down
    to ensure all running jobs complete properly.

    This is typically handled automatically by Flask-APScheduler,
    but can be called manually if needed.
    """
    if scheduler.running:
        scheduler.shutdown()
        print("[Scheduler] ✓ Scheduler shutdown complete")
