from app import create_app, db
from app.models.People_Models.user import User

app = create_app()
with app.app_context():
    user = User(
        username='testuser',
        fname='Test',
        lname='User',
        email='test@example.com',
        password='securepassword123',
    )
    db.session.add(user)
    db.session.commit()
    print(f"Created user with ID: {user.id}")
    