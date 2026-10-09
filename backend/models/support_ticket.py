import uuid
from datetime import datetime
from extensions import db

class SupportTicket(db.Model):
    __tablename__ = 'support_tickets'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    user_name = db.Column(db.String(100), nullable=False)
    user_email = db.Column(db.String(120), nullable=False)
    issue_type = db.Column(db.String(50), nullable=False)
    description = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(20), default='open')  # 'open'|'in_progress'|'resolved'
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    resolved_at = db.Column(db.DateTime, nullable=True)
    admin_note = db.Column(db.String(200), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'userId': self.user_id,
            'user_name': self.user_name,
            'userName': self.user_name,
            'user_email': self.user_email,
            'userEmail': self.user_email,
            'issue_type': self.issue_type,
            'issueType': self.issue_type,
            'description': self.description,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'resolved_at': self.resolved_at.isoformat() if self.resolved_at else None,
            'resolvedAt': self.resolved_at.isoformat() if self.resolved_at else None,
            'admin_note': self.admin_note,
            'adminNote': self.admin_note,
        }
