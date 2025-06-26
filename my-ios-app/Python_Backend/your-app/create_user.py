from app import create_app, db
from app.models.People_Models.user import User

app = create_app()
with app.app_context():
    user = User(
        username='testuser2',
        fname='Test2',
        lname='User2',
        email='test2@example.com',
        password='securepassword1232',
    )
    db.session.add(user)
    db.session.commit()
    print(f"Created user with ID: {user.id}")
    