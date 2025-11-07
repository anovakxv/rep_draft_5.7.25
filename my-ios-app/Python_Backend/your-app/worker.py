# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: January 2025

"""
Background worker entry point for scheduled tasks.

This file serves as the entry point for the background worker process
that runs scheduled jobs (like daily email summaries).

Usage:
    python worker.py

Environment Variables:
    WORKER_MODE: Must be set to 'true' for this worker to function
    All other environment variables from main app (DATABASE_URL, etc.)

Deployment on Render:
    Create a "Background Worker" service with:
    - Build Command: pip install -r requirements.txt
    - Start Command: python worker.py
    - Environment: WORKER_MODE=true (plus all other env vars)

The worker uses the same Flask app and database as the main web service,
but runs in a separate process to avoid impacting API performance.
"""

import os
import sys
import time
import signal

# Ensure WORKER_MODE is set
if os.getenv('WORKER_MODE') != 'true':
    print("[Worker] ERROR: WORKER_MODE must be set to 'true'")
    print("[Worker] This process should only run in worker mode")
    sys.exit(1)

print("[Worker] Starting Rep background worker...")
print("[Worker] Mode: WORKER_MODE=true")

# Import Flask app
from app import create_app

# Create Flask app instance
app = create_app()

# The scheduler will automatically start when the app is created
# (see app/scheduler.py and app/__init__.py)

print("[Worker] ✓ Background worker initialized")
print("[Worker] Scheduler is now running...")
print("[Worker] Press Ctrl+C to stop")


# Graceful shutdown handler
def handle_shutdown(signum, frame):
    """Handle shutdown signals gracefully"""
    print("\n[Worker] Received shutdown signal, cleaning up...")
    from app.scheduler import shutdown_scheduler
    shutdown_scheduler()
    print("[Worker] ✓ Worker stopped")
    sys.exit(0)


# Register signal handlers for graceful shutdown
signal.signal(signal.SIGINT, handle_shutdown)   # Ctrl+C
signal.signal(signal.SIGTERM, handle_shutdown)  # Termination signal


# Keep the worker running
# The scheduler runs in background threads, so we just need to keep the process alive
try:
    with app.app_context():
        print("[Worker] Worker is running. Waiting for scheduled jobs...")
        while True:
            time.sleep(60)  # Sleep for 60 seconds, then repeat
except KeyboardInterrupt:
    handle_shutdown(None, None)
