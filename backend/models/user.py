import uuid
from datetime import datetime
from extensions import db, bcrypt

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    role = db.Column(db.String(20), nullable=True) # 'rider' or 'passenger'
    points = db.Column(db.Integer, default=0)
    license_verified = db.Column(db.Boolean, default=False)
    is_online = db.Column(db.Boolean, default=False)
    accepted_guidelines = db.Column(db.Boolean, default=False)
    is_admin = db.Column(db.Boolean, default=False)
    
    # Profile Details
    prn = db.Column(db.String(50), nullable=True)
    college_name = db.Column(db.String(150), nullable=True)
    course = db.Column(db.String(100), nullable=True)
    year_of_study = db.Column(db.String(50), nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    dob = db.Column(db.String(20), nullable=True)
    gender = db.Column(db.String(10), nullable=True)
    branch = db.Column(db.String(100), nullable=True)
    division = db.Column(db.String(10), nullable=True)
    
    # Rider Specific
    vehicle_type = db.Column(db.String(50), nullable=True)
    vehicle_name = db.Column(db.String(100), nullable=True)
    vehicle_number = db.Column(db.String(50), nullable=True)
    service_area = db.Column(db.String(100), nullable=True)
    
    # License verification
    license_number = db.Column(db.String(50), nullable=True)
    license_type = db.Column(db.String(20), nullable=True)
    license_expiry = db.Column(db.String(20), nullable=True)
    vehicle_rc_number = db.Column(db.String(50), nullable=True)
    verification_status = db.Column(db.String(20), default='unverified') # 'unverified'|'pending'|'approved'|'rejected'
    verification_note = db.Column(db.String(200), nullable=True)
    current_lat = db.Column(db.Float, nullable=True)
    current_lng = db.Column(db.Float, nullable=True)
    avatar_url = db.Column(db.String(255), nullable=True)
    license_photo = db.Column(db.String(255), nullable=True)
    rc_photo = db.Column(db.String(255), nullable=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'role': self.role,
            'points': self.points,
            'license_verified': self.license_verified,
            'licenseVerified': self.license_verified,
            'is_online': self.is_online,
            'accepted_guidelines': self.accepted_guidelines,
            'isAdmin': self.is_admin,
            'is_admin': self.is_admin,
            'prn': self.prn,
            'college_name': self.college_name,
            'collegeName': self.college_name,
            'course': self.course,
            'year_of_study': self.year_of_study,
            'yearOfStudy': self.year_of_study,
            'phone': self.phone,
            'dob': self.dob,
            'gender': self.gender,
            'branch': self.branch,
            'division': self.division,
            'vehicle_type': self.vehicle_type,
            'vehicleType': self.vehicle_type,
            'vehicle_name': self.vehicle_name,
            'vehicleName': self.vehicle_name,
            'vehicle_number': self.vehicle_number,
            'vehicleNumber': self.vehicle_number,
            'service_area': self.service_area,
            'serviceArea': self.service_area,
            
            # License verification fields
            'licenseNumber': self.license_number,
            'license_number': self.license_number,
            'licenseType': self.license_type,
            'license_type': self.license_type,
            'licenseExpiry': self.license_expiry,
            'license_expiry': self.license_expiry,
            'vehicleRcNumber': self.vehicle_rc_number,
            'vehicle_rc_number': self.vehicle_rc_number,
            'verificationStatus': self.verification_status,
            'verification_status': self.verification_status,
            'verificationNote': self.verification_note,
            'verification_note': self.verification_note,
            'verifiedAt': self.verified_at.isoformat() if getattr(self, 'verified_at', None) else None,
            'verified_at': self.verified_at.isoformat() if getattr(self, 'verified_at', None) else None,
            'currentLat': self.current_lat,
            'current_lat': self.current_lat,
            'currentLng': self.current_lng,
            'current_lng': self.current_lng,
            'avatarUrl': self.avatar_url,
            'avatar_url': self.avatar_url,
            'licensePhoto': self.license_photo,
            'license_photo': self.license_photo,
            'rcPhoto': self.rc_photo,
            'rc_photo': self.rc_photo,
            
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
