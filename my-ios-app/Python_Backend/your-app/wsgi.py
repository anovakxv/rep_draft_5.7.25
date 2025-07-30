import eventlet
eventlet.monkey_patch()

from app import create_app, socketio

app = create_app()
# Do NOT include any `if __name__ == "__main__":` block here!