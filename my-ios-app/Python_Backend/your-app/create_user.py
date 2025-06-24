from app import create_app, db
from app.models.user import User

app = create_app()
with app.app_context():
    user = User(username='testuser', fname='Test', lname='User', email='test@example.com')
    db.session.add(user)
    db.session.commit()
    print(f"Created user with ID: {user.id}")