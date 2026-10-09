import time
import os
import secrets
from collections import defaultdict
from flask import Blueprint, request, jsonify, send_from_directory
from extensions import db, bcrypt
from flask_jwt_extended import (
    create_access_token,
    verify_jwt_in_request,
    get_jwt,
    jwt_required,
    decode_token
)
from models.user import User
from models.ride import Ride
from models.sos_alert import SOSAlert
from models.bike import Bike, BikeRental
from models.support_ticket import SupportTicket
from models.trusted_contact import TrustedContact
from datetime import datetime, date
from routes.users import get_certificate_level

admin_bp = Blueprint('admin', __name__)

DOCS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'uploads', 'documents')
os.makedirs(DOCS_DIR, exist_ok=True)

# NOTE ON RATE LIMITING:
# This in-memory sliding window rate limiter resets on server restart and is process-local.
# It is designed for single-process development/hackathon setups.
# For multi-worker production setups, use a shared store like Redis (e.g., via Flask-Limiter).
FAILED_LOGIN_ATTEMPTS = defaultdict(list)
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_WINDOW_SECONDS = 900  # 15 minutes

def is_ip_rate_limited(ip_address: str) -> bool:
    now = time.time()
    # Filter attempts within the lockout window
    recent_attempts = [t for t in FAILED_LOGIN_ATTEMPTS[ip_address] if now - t < LOCKOUT_WINDOW_SECONDS]
    FAILED_LOGIN_ATTEMPTS[ip_address] = recent_attempts
    return len(recent_attempts) >= MAX_LOGIN_ATTEMPTS

def record_failed_login(ip_address: str):
    FAILED_LOGIN_ATTEMPTS[ip_address].append(time.time())

def clear_failed_logins(ip_address: str):
    FAILED_LOGIN_ATTEMPTS.pop(ip_address, None)

@admin_bp.before_request
def before_request():
    if request.method == 'OPTIONS':
        return '', 200
    
    # Allow admin login endpoint without existing JWT
    if request.endpoint == 'admin.admin_login':
        return None

    # Allow document access if valid admin token is in query param
    if request.endpoint == 'admin.get_admin_document':
        token = request.args.get('token')
        if token:
            try:
                claims = decode_token(token)
                if claims.get('is_admin'):
                    return None
            except Exception:
                pass

    # Verify JWT and assert admin privilege
    try:
        verify_jwt_in_request()
        claims = get_jwt()
        if not claims.get('is_admin', False):
            return jsonify({'error': 'Forbidden: Admin privilege required'}), 403
    except Exception as e:
        return jsonify({'error': 'Unauthorized: Valid admin JWT required', 'details': str(e)}), 401

@admin_bp.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS')
    return response

@admin_bp.route('/login', methods=['POST'])
def admin_login():
    ip = request.remote_addr or 'unknown'
    if is_ip_rate_limited(ip):
        return jsonify({'error': 'Too many failed login attempts. Please try again in 15 minutes.'}), 429

    data = request.get_json() or {}
    email_or_user = (data.get('username') or data.get('email') or '').strip()
    password = data.get('password')

    if not email_or_user or not password:
        return jsonify({'error': 'Username/email and password are required'}), 400

    # Search for matching user with case-insensitivity
    user = User.query.filter(
        (User.email.ilike(email_or_user)) | (User.name.ilike(email_or_user))
    ).first()

    if not user:
        record_failed_login(ip)
        return jsonify({'error': f"No account found for '{email_or_user}'"}), 401

    if not (user.is_admin or user.role == 'admin'):
        record_failed_login(ip)
        return jsonify({'error': f"Account '{email_or_user}' is not an authorized administrator"}), 403

    if not user.check_password(password):
        record_failed_login(ip)
        return jsonify({'error': 'Incorrect password. Please check your credentials and try again.'}), 401

    clear_failed_logins(ip)
    access_token = create_access_token(
        identity=user.id,
        additional_claims={'is_admin': True, 'role': 'admin', 'name': user.name}
    )

    return jsonify({
        'token': access_token,
        'user': {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'is_admin': True
        }
    }), 200

@admin_bp.route('/stats', methods=['GET'])
def get_stats():
    today = date.today()
    return jsonify({
        'totalUsers': User.query.count(),
        'ridesTotal': Ride.query.count(),
        'ridestoday': Ride.query.filter(db.func.date(Ride.created_at) == today).count(),
        'pendingRides': Ride.query.filter_by(status='pending').count(),
        'completedRides': Ride.query.filter_by(status='completed').count(),
        'totalPointsDistributed': db.session.query(db.func.sum(User.points)).scalar() or 0,
        'activeSosAlerts': SOSAlert.query.filter_by(resolved=False).count(),
        'onlineUsers': User.query.filter_by(is_online=True).count(),
        'pendingVerifications': User.query.filter_by(verification_status='pending').count(),
        'openSupportTickets': SupportTicket.query.filter_by(status='open').count(),
        'verifiedDrivers': User.query.filter_by(verification_status='approved').count(),
    })

@admin_bp.route('/users', methods=['GET'])
def get_users():
    users = User.query.all()
    user_list = []
    for user in users:
        u_dict = user.to_dict()
        u_dict['isOnline'] = user.is_online
        u_dict['totalRides'] = Ride.query.filter(
            db.or_(Ride.passenger_id == user.id, Ride.rider_id == user.id),
            Ride.status == 'completed'
        ).count()
        cert = get_certificate_level(user.points or 0)
        u_dict['certificateLevel'] = cert['level']
        u_dict['certificateTitle'] = cert['title']
        u_dict['certificateEmoji'] = cert['emoji']
        user_list.append(u_dict)
    return jsonify(user_list)

@admin_bp.route('/users/<user_id>/points', methods=['PATCH'])
def update_points(user_id):
    try:
        user = User.query.get_or_404(user_id)
        data = request.json or {}
        points = data.get('points', 0)
        user.points = (user.points or 0) + points
        db.session.commit()
        return jsonify({
            'message': 'Points updated',
            'points': user.points,
            'user': user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    try:
        user = User.query.get_or_404(user_id)
        db.session.delete(user)
        db.session.commit()
        return jsonify({'message': 'User deleted'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/rides', methods=['GET'])
def get_rides():
    rides = Ride.query.order_by(Ride.created_at.desc()).all()
    rides_data = []
    for ride in rides:
        rides_data.append({
            'id': ride.id,
            'passengerName': ride.passenger_name,
            'riderName': ride.rider_name or 'Not assigned',
            'fromLocation': ride.from_location,
            'toLocation': ride.to_location,
            'status': ride.status,
            'pointsAwarded': ride.points_awarded,
            'createdAt': ride.created_at.strftime('%d %b %Y %I:%M %p') if ride.created_at else '-',
            'completedAt': ride.completed_at.strftime('%d %b %Y %I:%M %p') if ride.completed_at else '-'
        })
    return jsonify({'rides': rides_data})

@admin_bp.route('/rides/<ride_id>/receipt')
def download_receipt(ride_id):
    try:
        key = request.headers.get('X-Admin-Key')
        if key != 'campuslift@admin123':
            return jsonify({'error': 'Unauthorized'}), 401
        
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({'error': 'Ride not found'}), 404
        
        receipt = f"""
CAMPUSLIFT RIDE RECEIPT
═══════════════════════════════
Receipt ID  : {ride.id[:8].upper()}
Date        : {ride.completed_at.strftime('%d %b %Y %I:%M %p') if ride.completed_at else 'N/A'}
═══════════════════════════════
RIDE DETAILS
Passenger   : {ride.passenger_name}
Rider       : {ride.rider_name or 'N/A'}
From        : {ride.from_location}
To          : {ride.to_location}
Status      : {ride.status.upper()}
═══════════════════════════════
FARE SUMMARY
Points Used : {ride.points_awarded} pts
Platform Fee: 0 (Waived)
Total       : {ride.points_awarded} pts
═══════════════════════════════
Thank you for using CampusLift!
Safe travels 🚗
"""
        
        from flask import Response
        return Response(
            receipt,
            mimetype='text/plain',
            headers={
                'Content-Disposition': f'attachment; filename=receipt_{ride.id[:8]}.txt'
            }
        )
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/sos', methods=['GET'])
def get_sos():
    alerts = SOSAlert.query.order_by(SOSAlert.triggered_at.desc()).all()
    result = []
    for alert in alerts:
        alert_dict = alert.to_dict()
        user = User.query.get(alert.user_id)
        alert_dict['user_name'] = user.name if user else 'Unknown'
        alert_dict['user_identity'] = {
            'name': user.name if user else 'Unknown',
            'phone': user.phone if user else 'N/A',
            'college_id': user.prn or 'PRN-Pending' if user else 'N/A',
            'photo': user.avatar_url or '' if user else '',
            'role': user.role if user else 'student',
            'college_name': user.college_name if user else 'Campus'
        } if user else None
        result.append(alert_dict)
    return jsonify(result)

@admin_bp.route('/sos/<alert_id>/resolve', methods=['PATCH'])
def resolve_sos(alert_id):
    try:
        alert = SOSAlert.query.get_or_404(alert_id)
        alert.resolved = True
        db.session.commit()
        return jsonify(alert.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/bikes', methods=['GET'])
def get_admin_bikes():
    bikes = Bike.query.order_by(Bike.created_at.desc()).all()
    return jsonify([bike.to_dict() for bike in bikes])

@admin_bp.route('/rentals', methods=['GET'])
def get_admin_rentals():
    rentals = BikeRental.query.order_by(BikeRental.created_at.desc()).all()
    return jsonify([rental.to_dict() for rental in rentals])

@admin_bp.route('/verifications', methods=['GET'])
def get_pending_verifications():
    pending_users = User.query.filter_by(verification_status='pending').all()
    return jsonify([u.to_dict() for u in pending_users])

@admin_bp.route('/verifications/<user_id>/approve', methods=['PATCH'])
def approve_verification(user_id):
    try:
        user = User.query.get_or_404(user_id)
        user.verification_status = 'approved'
        user.license_verified = True
        user.verified_at = datetime.utcnow()
        db.session.commit()
        return jsonify(user.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/verifications/<user_id>/reject', methods=['PATCH'])
def reject_verification(user_id):
    try:
        user = User.query.get_or_404(user_id)
        data = request.json or {}
        note = data.get('note') or data.get('verificationNote') or 'No reason provided.'
        user.verification_status = 'rejected'
        user.license_verified = False
        user.verification_note = note
        db.session.commit()
        return jsonify(user.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/support', methods=['GET'])
def get_support_tickets():
    tickets = SupportTicket.query.order_by(SupportTicket.created_at.desc()).all()
    return jsonify([t.to_dict() for t in tickets])

@admin_bp.route('/support/<ticket_id>', methods=['PATCH'])
def update_support_ticket(ticket_id):
    try:
        ticket = SupportTicket.query.get_or_404(ticket_id)
        data = request.json or {}
        
        status = data.get('status')
        if status:
            ticket.status = status
            if status == 'resolved':
                ticket.resolved_at = datetime.utcnow()
                
        admin_note = data.get('adminNote') or data.get('admin_note')
        if admin_note is not None:
            ticket.admin_note = admin_note
            
        db.session.commit()
        return jsonify(ticket.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/trusted-contacts', methods=['GET'])
def get_admin_trusted_contacts():
    contacts = TrustedContact.query.order_by(TrustedContact.created_at.desc()).all()
    return jsonify([c.to_dict() for c in contacts]), 200

@admin_bp.route('/trusted-contacts', methods=['POST'])
def add_admin_trusted_contact():
    try:
        data = request.json or {}
        name = data.get('name')
        phone = data.get('phone')
        category = data.get('category', 'security').lower()
        location = data.get('location', 'Campus Area')
        description = data.get('description', '')

        if not name or not phone:
            return jsonify({'error': 'Name and phone are required'}), 400

        contact = TrustedContact(
            name=name,
            phone=phone,
            category=category,
            location=location,
            description=description,
            is_active=True
        )
        db.session.add(contact)
        db.session.commit()
        return jsonify(contact.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/trusted-contacts/<contact_id>', methods=['PATCH'])
def update_admin_trusted_contact(contact_id):
    try:
        contact = TrustedContact.query.get_or_404(contact_id)
        data = request.json or {}
        if 'name' in data:
            contact.name = data['name']
        if 'phone' in data:
            contact.phone = data['phone']
        if 'category' in data:
            contact.category = data['category'].lower()
        if 'location' in data:
            contact.location = data['location']
        if 'description' in data:
            contact.description = data['description']
        if 'isActive' in data or 'is_active' in data:
            contact.is_active = bool(data.get('isActive') if 'isActive' in data else data.get('is_active'))

        db.session.commit()
        return jsonify(contact.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/trusted-contacts/<contact_id>', methods=['DELETE'])
def delete_admin_trusted_contact(contact_id):
    try:
        contact = TrustedContact.query.get_or_404(contact_id)
        db.session.delete(contact)
        db.session.commit()
        return jsonify({'message': 'Contact deleted successfully', 'id': contact_id}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/documents/<filename>', methods=['GET'])
def get_admin_document(filename):
    try:
        safe_name = os.path.basename(filename)
        return send_from_directory(DOCS_DIR, safe_name)
    except Exception as e:
        return jsonify({'error': f'Document not found: {str(e)}'}), 404

