from app import create_app, db
from app.models.People_Models.Skill import Skill

app = create_app()

skills = [
    "HR: Scale",
    "HR: Education",
    "HR: Productivity",
    "HR: Physical Health",
    "HR: Mental Health",
    "Engineering: Software Design",
    "Engineering: Software Dev",
    "Engineering: Hardware",
    "Engineering: CS and AI",
    "Engineering: Civil",
    "Engineering: Mechanical",
    "Engineering: Air & Space",
    "Engineering: Materials",
    "Engineering: R&D",
    "Sales & Marketing: Networking",
    "Sales & Marketing: Sales",
    "Sales & Marketing: Advertising",
    "Sales & Marketing: Branding",
    "Sales & Marketing: Comms",
    "Sales & Marketing: Marketing",
    "Grassroots: Virtual Meetings",
    "Grassroots: Coordination",
    "Grassroots: Event Comms",
    "Events: Planning",
    "Events: Logistics",
    "Events: Promotion",
    "Events: Iterative Evolution",
    "Content: Graphics",
    "Content: Images",
    "Content: Writing",
    "Content: Video Production",
    "Content: Video Editing",
    "Finance: Internal",
    "Finance: Accounting",
    "Finance: M&A",
    "Finance: Deal Structures",
    "Finance: Investing",
    "Finance: Optimization",
    "Finance: Incentive Structures",
    "Spiritual: Principles",
    "Spiritual: Collaboration",
    "Spiritual: Leadership",
    "Spiritual: Community",
    "Spiritual: Worship",
    "Management: Optimization",
    "Management: Project Management"
]

with app.app_context():
    for title in skills:
        if not Skill.query.filter_by(title=title).first():
            db.session.add(Skill(title=title, visible=True))
    db.session.commit()
    print("Skills added!")