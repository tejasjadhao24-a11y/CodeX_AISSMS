import uuid
from datetime import datetime
from extensions import db

class SOSAlert(db.Model):
    __tablename__ = 'sos_alerts'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    ride_id = db.Column(db.String(36), db.ForeignKey('rides.id'), nullable=True)
    
    lat = db.Column(db.Float, nullable=False)
    lng = db.Column(db.Float, nullable=False)
    
    triggered_at = db.Column(db.DateTime, default=datetime.utcnow)
    resolved = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'ride_id': self.ride_id,
            'lat': self.lat,
            'lng': self.lng,
            'triggered_at': self.triggered_at.isoformat(),
            'resolved': self.resolved
        }
