import uuid
import json
from datetime import datetime
from extensions import db

class Ride(db.Model):
    __tablename__ = 'rides'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    passenger_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    passenger_name = db.Column(db.String(100), nullable=False)
    
    rider_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=True)
    rider_name = db.Column(db.String(100), nullable=True)
    
    from_location = db.Column(db.String(255), nullable=False)
    to_location = db.Column(db.String(255), nullable=False)
    
    from_lat = db.Column(db.Float, nullable=True)
    from_lng = db.Column(db.Float, nullable=True)
    to_lat = db.Column(db.Float, nullable=True)
    to_lng = db.Column(db.Float, nullable=True)
    
    status = db.Column(db.String(20), default='pending') # 'pending', 'accepted', 'in_progress', 'completed', 'cancelled'
    points_awarded = db.Column(db.Integer, default=10)
    
    passenger_rating = db.Column(db.Integer, nullable=True)
    rider_rating = db.Column(db.Integer, nullable=True)
    
    declined_by = db.Column(db.Text, default='[]') # JSON list of user IDs
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    accepted_at = db.Column(db.DateTime, nullable=True)
    started_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)
    scheduled_time = db.Column(db.DateTime, nullable=True, default=None)
    gender_preference = db.Column(db.String(20), nullable=True, default='All')

    def get_declined_by(self):
        return json.loads(self.declined_by)

    def add_declined_by(self, user_id):
        declined_list = self.get_declined_by()
        if user_id not in declined_list:
            declined_list.append(user_id)
            self.declined_by = json.dumps(declined_list)

    def to_dict(self):
        from models.user import User
        passenger = User.query.get(self.passenger_id) if self.passenger_id else None
        rider = User.query.get(self.rider_id) if self.rider_id else None

        p_phone = passenger.phone if passenger and passenger.phone else ''
        p_photo = passenger.avatar_url if passenger and passenger.avatar_url else ''
        r_phone = rider.phone if rider and rider.phone else ''
        r_photo = rider.avatar_url if rider and rider.avatar_url else ''

        return {
            'id': self.id,
            'passengerId': self.passenger_id,
            'passengerName': self.passenger_name,
            'passengerPhone': p_phone,
            'passenger_phone': p_phone,
            'passengerPhoto': p_photo,
            'passenger_photo': p_photo,
            'riderId': self.rider_id,
            'riderName': self.rider_name,
            'riderPhone': r_phone,
            'rider_phone': r_phone,
            'riderPhoto': r_photo,
            'rider_photo': r_photo,
            'fromLocation': self.from_location,
            'toLocation': self.to_location,
            'fromLat': self.from_lat,
            'fromLng': self.from_lng,
            'toLat': self.to_lat,
            'toLng': self.to_lng,
            'status': self.status,
            'pointsAwarded': self.points_awarded,
            'passengerRating': self.passenger_rating,
            'riderRating': self.rider_rating,
            'genderPreference': self.gender_preference or 'All',
            'gender_preference': self.gender_preference or 'All',
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'acceptedAt': self.accepted_at.isoformat() if self.accepted_at else None,
            'startedAt': self.started_at.isoformat() if self.started_at else None,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'completedAt': self.completed_at.isoformat() if self.completed_at else None,
            'scheduledTime': self.scheduled_time.isoformat() if self.scheduled_time else None
        }
