import uuid
from datetime import datetime
from extensions import db

class Bike(db.Model):
    __tablename__ = 'bikes'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    owner_name = db.Column(db.String(100), nullable=False)
    owner_upi_id = db.Column(db.String(100), nullable=False)
    bike_type = db.Column(db.String(20), nullable=False) # 'bicycle', 'scooter', 'motorcycle'
    bike_name = db.Column(db.String(100), nullable=False)
    bike_number = db.Column(db.String(50), nullable=False)
    price_per_hour = db.Column(db.Float, nullable=False)
    location = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    payment_method = db.Column(db.String(20), default='Both') # 'UPI', 'Cash', 'Both'
    is_available = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'owner_id': self.owner_id,
            'owner_name': self.owner_name,
            'owner_upi_id': self.owner_upi_id,
            'bike_type': self.bike_type,
            'bike_name': self.bike_name,
            'bike_number': self.bike_number,
            'price_per_hour': self.price_per_hour,
            'location': self.location,
            'description': self.description,
            'payment_method': self.payment_method or 'Both',
            'is_available': self.is_available,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class BikeRental(db.Model):
    __tablename__ = 'bike_rentals'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    bike_id = db.Column(db.String(36), db.ForeignKey('bikes.id'), nullable=False)
    renter_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    renter_name = db.Column(db.String(100), nullable=False)
    owner_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=False)
    total_hours = db.Column(db.Float, nullable=False)
    total_amount = db.Column(db.Float, nullable=False)
    payment_method = db.Column(db.String(20), default='UPI') # 'UPI' or 'Cash'
    status = db.Column(db.String(20), default='requested') 
    # 'requested', 'approved', 'payment_pending', 'payment_done', 'active', 'completed', 'cancelled'
    payment_screenshot = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        bike = Bike.query.get(self.bike_id)
        return {
            'id': self.id,
            'bike_id': self.bike_id,
            'bike_name': bike.bike_name if bike else 'Unknown',
            'bike_type': bike.bike_type if bike else 'unknown',
            'renter_id': self.renter_id,
            'renter_name': self.renter_name,
            'owner_id': self.owner_id,
            'owner_upi_id': bike.owner_upi_id if bike else '',
            'start_time': self.start_time.isoformat() if self.start_time else None,
            'end_time': self.end_time.isoformat() if self.end_time else None,
            'total_hours': self.total_hours,
            'total_amount': self.total_amount,
            'payment_method': self.payment_method or 'UPI',
            'status': self.status,
            'payment_screenshot': self.payment_screenshot,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
