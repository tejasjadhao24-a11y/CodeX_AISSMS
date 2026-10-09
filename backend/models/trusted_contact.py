import uuid
from datetime import datetime
from extensions import db

class TrustedContact(db.Model):
    __tablename__ = 'trusted_contacts'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(30), nullable=False)
    category = db.Column(db.String(50), nullable=False) # 'security', 'health', 'emergency', 'auto', 'taxi'
    location = db.Column(db.String(150), nullable=True, default='Campus Area')
    description = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'phone': self.phone,
            'category': self.category,
            'location': self.location or 'Campus Area',
            'description': self.description or '',
            'isActive': self.is_active,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
