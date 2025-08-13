import eventlet
eventlet.monkey_patch()

from app import create_app, socketio

app = create_app()

if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 5000))
    socketio.run(app, host="0.0.0.0", port=port)