import os
import uuid
import base64
from flask import Blueprint, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models.user import User
from models.ride import Ride
from models.support_ticket import SupportTicket
from models.trusted_contact import TrustedContact

users_bp = Blueprint('users', __name__)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPLOAD_ROOT = os.path.join(BASE_DIR, 'uploads')
AVATARS_DIR = os.path.join(UPLOAD_ROOT, 'avatars')
DOCS_DIR = os.path.join(UPLOAD_ROOT, 'documents')

os.makedirs(AVATARS_DIR, exist_ok=True)
os.makedirs(DOCS_DIR, exist_ok=True)

ALLOWED_AVATAR_EXTS = {'png', 'jpg', 'jpeg', 'webp'}
ALLOWED_DOC_EXTS = {'png', 'jpg', 'jpeg', 'webp', 'pdf'}
MAX_UPLOAD_SIZE = 5 * 1024 * 1024  # 5 MB

def get_certificate_level(points):
    if points >= 2000:
        return {
            'level': 4,
            'title': 'CampusLift Legend',
            'badge': 'crown',
            'emoji': '👑',
            'color': '#FFD700',
            'description': 'Elite campus mobility legend',
            'minPoints': 2000,
            'nextLevel': None,
        }
    elif points >= 1000:
        return {
            'level': 3,
            'title': 'Eco Warrior',
            'badge': 'bolt',
            'emoji': '⚡',
            'color': '#9B59B6',
            'description': 'Elite sustainable commuter',
            'minPoints': 1000,
            'nextLevel': 2000,
            'pointsToNext': 2000 - points,
        }
    elif points >= 500:
        return {
            'level': 2,
            'title': 'Campus Champion',
            'badge': 'trophy',
            'emoji': '🏆',
            'color': '#E67E22',
            'description': 'Outstanding campus contributor',
            'minPoints': 500,
            'nextLevel': 1000,
            'pointsToNext': 1000 - points,
        }
    elif points >= 100:
        return {
            'level': 1,
            'title': 'Green Rider',
            'badge': 'leaf',
            'emoji': '🌱',
            'color': '#27AE60',
            'description': 'Eco-friendly campus commuter',
            'minPoints': 100,
            'nextLevel': 500,
            'pointsToNext': 500 - points,
        }
    else:
        return {
            'level': 0,
            'title': 'New Rider',
            'badge': 'star',
            'emoji': '⭐',
            'color': '#95A5A6',
            'description': 'Starting your journey',
            'minPoints': 0,
            'nextLevel': 100,
            'pointsToNext': 100 - points,
        }

@users_bp.route('/role', methods=['PATCH'])
@jwt_required()
def update_role():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        role = data.get('role')

        if role not in ['rider', 'passenger', '', None]:
            return jsonify({"error": "Invalid role"}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        user.role = role
        db.session.commit()
        
        return jsonify({"data": user.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@users_bp.route('/guidelines', methods=['PATCH'])
@jwt_required()
def accept_guidelines():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        user.accepted_guidelines = True
        db.session.commit()
        
        return jsonify({"data": user.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@users_bp.route('/online', methods=['PATCH'])
@jwt_required()
def update_online_status():
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}
        is_online = data.get('is_online')

        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        if is_online is not None:
            user.is_online = bool(is_online)
            
        if 'lat' in data or 'currentLat' in data:
            user.current_lat = float(data.get('lat') or data.get('currentLat'))
        if 'lng' in data or 'currentLng' in data:
            user.current_lng = float(data.get('lng') or data.get('currentLng'))

        db.session.commit()
        return jsonify({"data": user.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@users_bp.route('/location', methods=['PATCH'])
@jwt_required()
def update_location():
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        if 'lat' in data or 'currentLat' in data:
            user.current_lat = float(data.get('lat') or data.get('currentLat'))
        if 'lng' in data or 'currentLng' in data:
            user.current_lng = float(data.get('lng') or data.get('currentLng'))

        db.session.commit()
        return jsonify({"data": user.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@users_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404
        return jsonify({"data": user.to_dict()}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@users_bp.route('/profile', methods=['PATCH'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Convert camelCase keys from request to snake_case attributes
        key_mapping = {
            'collegeName': 'college_name',
            'yearOfStudy': 'year_of_study',
            'vehicleType': 'vehicle_type',
            'vehicleName': 'vehicle_name',
            'vehicleNumber': 'vehicle_number',
            'serviceArea': 'service_area',
        }
        for camel, snake in key_mapping.items():
            if camel in data:
                setattr(user, snake, data[camel])

        # Standard attributes
        fields = [
            'name', 'email', 'phone', 'dob', 'gender', 'prn', 'college_name', 
            'course', 'year_of_study', 'branch', 'division', 
            'vehicle_type', 'vehicle_name', 'vehicle_number', 'service_area'
        ]
        
        for field in fields:
            if field in data:
                setattr(user, field, data[field])

        db.session.commit()
        return jsonify({"data": user.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

def _save_uploaded_content(file_obj, base64_str, dest_dir, prefix, allowed_exts):
    if file_obj and getattr(file_obj, 'filename', None):
        orig_name = secure_filename(file_obj.filename)
        ext = orig_name.rsplit('.', 1)[-1].lower() if '.' in orig_name else 'jpg'
        if ext not in allowed_exts:
            raise ValueError(f"Unsupported file format '{ext}'. Allowed: {', '.join(allowed_exts)}")
        data = file_obj.read()
        if len(data) > MAX_UPLOAD_SIZE:
            raise ValueError("File size exceeds 5MB limit")
        filename = f"{prefix}_{uuid.uuid4().hex[:12]}.{ext}"
        filepath = os.path.join(dest_dir, filename)
        with open(filepath, 'wb') as f:
            f.write(data)
        return filename
    elif base64_str:
        content = base64_str
        ext = 'jpg'
        if ',' in base64_str:
            header, content = base64_str.split(',', 1)
            if 'image/png' in header:
                ext = 'png'
            elif 'image/webp' in header:
                ext = 'webp'
            elif 'application/pdf' in header:
                ext = 'pdf'
            elif 'image/jpeg' in header or 'image/jpg' in header:
                ext = 'jpg'
        if ext not in allowed_exts:
            raise ValueError(f"Unsupported file format '{ext}'. Allowed: {', '.join(allowed_exts)}")
        data = base64.b64decode(content)
        if len(data) > MAX_UPLOAD_SIZE:
            raise ValueError("File size exceeds 5MB limit")
        filename = f"{prefix}_{uuid.uuid4().hex[:12]}.{ext}"
        filepath = os.path.join(dest_dir, filename)
        with open(filepath, 'wb') as f:
            f.write(data)
        return filename
    return None

@users_bp.route('/profile/avatar', methods=['POST'])
@jwt_required()
def upload_avatar():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        file_obj = request.files.get('avatar')
        json_data = request.get_json(silent=True) or {}
        b64_str = json_data.get('avatar_base64') or json_data.get('avatarBase64') or request.form.get('avatar_base64')

        if not file_obj and not b64_str:
            return jsonify({"error": "No avatar file or base64 data provided"}), 400

        filename = _save_uploaded_content(file_obj, b64_str, AVATARS_DIR, f"avatar_{user_id[:8]}", ALLOWED_AVATAR_EXTS)
        if not filename:
            return jsonify({"error": "Failed to process avatar file"}), 400

        avatar_url = f"/api/users/avatar/{filename}"
        user.avatar_url = avatar_url
        db.session.commit()

        return jsonify({
            "message": "Avatar uploaded successfully",
            "avatarUrl": avatar_url,
            "avatar_url": avatar_url,
            "user": user.to_dict()
        }), 200
    except ValueError as ve:
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@users_bp.route('/profile/avatar', methods=['DELETE'])
@jwt_required()
def delete_avatar():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        if user.avatar_url:
            filename = os.path.basename(user.avatar_url)
            safe_name = secure_filename(filename)
            file_path = os.path.join(AVATARS_DIR, safe_name)
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                except Exception as del_err:
                    print(f"Warning: could not delete avatar file {file_path}: {del_err}")
            user.avatar_url = None
            db.session.commit()

        return jsonify({
            "message": "Profile photo removed successfully",
            "avatarUrl": None,
            "avatar_url": None,
            "user": user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@users_bp.route('/avatar/<filename>', methods=['GET'])
def get_avatar(filename):
    try:
        safe_name = secure_filename(os.path.basename(filename))
        return send_from_directory(AVATARS_DIR, safe_name)
    except Exception as e:
        return jsonify({"error": f"Avatar not found: {str(e)}"}), 404

@users_bp.route('/license/documents', methods=['POST'])
@jwt_required()
def upload_license_documents():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        lic_file = request.files.get('license_doc') or request.files.get('licenseDoc')
        rc_file = request.files.get('rc_doc') or request.files.get('rcDoc')
        json_data = request.get_json(silent=True) or {}
        lic_b64 = json_data.get('license_base64') or json_data.get('licenseBase64') or request.form.get('license_base64')
        rc_b64 = json_data.get('rc_base64') or json_data.get('rcBase64') or request.form.get('rc_base64')

        updated = False
        if lic_file or lic_b64:
            lic_name = _save_uploaded_content(lic_file, lic_b64, DOCS_DIR, f"license_{user_id[:8]}", ALLOWED_DOC_EXTS)
            user.license_photo = lic_name
            updated = True

        if rc_file or rc_b64:
            rc_name = _save_uploaded_content(rc_file, rc_b64, DOCS_DIR, f"rc_{user_id[:8]}", ALLOWED_DOC_EXTS)
            user.rc_photo = rc_name
            updated = True

        if not updated:
            return jsonify({"error": "No license or RC document provided"}), 400

        db.session.commit()
        return jsonify({
            "message": "Documents uploaded successfully",
            "licensePhoto": user.license_photo,
            "license_photo": user.license_photo,
            "rcPhoto": user.rc_photo,
            "rc_photo": user.rc_photo,
            "user": user.to_dict()
        }), 200
    except ValueError as ve:
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@users_bp.route('/license', methods=['PATCH'])
@jwt_required()
def submit_license():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        data = request.get_json() or {}
        
        user.license_number = data.get('licenseNumber')
        user.license_type = data.get('licenseType')
        user.license_expiry = data.get('licenseExpiry')
        user.vehicle_rc_number = data.get('vehicleRcNumber')
        user.vehicle_type = data.get('vehicleType')
        user.vehicle_name = data.get('vehicleName')
        if data.get('licensePhoto') or data.get('license_photo'):
            user.license_photo = data.get('licensePhoto') or data.get('license_photo')
        if data.get('rcPhoto') or data.get('rc_photo'):
            user.rc_photo = data.get('rcPhoto') or data.get('rc_photo')
        user.verification_status = 'pending'
        
        db.session.commit()
        
        return jsonify({
            'message': 'License submitted',
            'user': user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

support_bp = Blueprint('support', __name__)

@support_bp.route('/report', methods=['POST'])
@jwt_required()
def report_issue():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        data = request.get_json() or {}
        issue_type = data.get('issueType') or data.get('issue_type') or 'Other'
        description = data.get('description') or ''
        
        ticket = SupportTicket(
            user_id=user_id,
            user_name=user.name,
            user_email=user.email,
            issue_type=issue_type,
            description=description,
            status='open'
        )
        db.session.add(ticket)
        db.session.commit()
        
        return jsonify({
            'message': "Issue reported! We'll respond within 24 hours.",
            'ticket': ticket.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@users_bp.route('/points', methods=['GET'])
@jwt_required()
def get_points():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        return jsonify({"data": {"points": user.points}}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@users_bp.route('/profile-stats', methods=['GET'])
@jwt_required()
def profile_stats():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        total_rides = Ride.query.filter(
            db.or_(
                Ride.passenger_id == user_id,
                Ride.rider_id == user_id
            ),
            Ride.status == 'completed'
        ).count()
        
        rated_rides = Ride.query.filter(
            Ride.rider_id == user_id,
            Ride.passenger_rating != None
        ).all()
        
        avg_rating = 0.0
        if rated_rides:
            avg_rating = sum(r.passenger_rating for r in rated_rides) / len(rated_rides)
        
        eco_score = total_rides * 35
        points = user.points or 0
        
        # Calculate certificate level
        certificate = get_certificate_level(points)
        
        return jsonify({
            'totalRides': total_rides,
            'avgRating': round(avg_rating, 1),
            'ecoScore': eco_score,
            'points': points,
            'certificate': certificate,
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@users_bp.route('/trusted-contacts', methods=['GET'])
def get_public_trusted_contacts():
    try:
        category = request.args.get('category')
        query = TrustedContact.query.filter_by(is_active=True)
        if category:
            query = query.filter_by(category=category.lower())
        contacts = query.order_by(TrustedContact.name.asc()).all()
        return jsonify({'contacts': [c.to_dict() for c in contacts]}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'contacts': []}), 500
