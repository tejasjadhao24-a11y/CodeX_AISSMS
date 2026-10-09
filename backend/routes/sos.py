from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from extensions import db, socketio
from models.sos_alert import SOSAlert
from models.user import User
from models.ride import Ride

sos_bp = Blueprint('sos', __name__)

@sos_bp.route('/trigger', methods=['POST'])
@jwt_required()
def trigger_sos():
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}
        ride_id = data.get('ride_id') or data.get('rideId')
        
        user = User.query.get(user_id)
        user_identity = {
            'id': user.id if user else user_id,
            'name': user.name if user else 'Unknown Student',
            'phone': user.phone if user else 'N/A',
            'college_id': user.prn or 'PRN-Pending' if user else 'N/A',
            'photo': user.avatar_url or '' if user else '',
            'role': user.role or 'student' if user else 'student',
            'gender': user.gender or 'Not specified' if user else 'Not specified',
            'college_name': user.college_name or 'Campus' if user else 'Campus'
        }

        alert = SOSAlert(
            user_id=user_id,
            ride_id=ride_id,
            lat=float(data.get('lat', 18.4624)),
            lng=float(data.get('lng', 73.8670))
        )
        
        db.session.add(alert)
        db.session.commit()
        
        alert_dict = alert.to_dict()
        alert_dict['user_name'] = user.name if user else 'Unknown'
        alert_dict['user_identity'] = user_identity

        # 1. Emit to admin room
        socketio.emit('sos_triggered', alert_dict, room='admin')
        
        # 2. Emit to ride room and participants if ride active
        if ride_id:
            ride = Ride.query.get(ride_id)
            socketio.emit('sos_triggered', alert_dict, room=f'ride_{ride_id}')
            if ride:
                # Notify opposite party directly
                if user_id == ride.passenger_id and ride.rider_id:
                    socketio.emit('sos_triggered', alert_dict, room=f'user_{ride.rider_id}')
                elif user_id == ride.rider_id and ride.passenger_id:
                    socketio.emit('sos_triggered', alert_dict, room=f'user_{ride.passenger_id}')

        return jsonify({"data": alert_dict}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@sos_bp.route('/<alert_id>/location', methods=['POST'])
@jwt_required()
def update_sos_location(alert_id):
    try:
        user_id = get_jwt_identity()
        alert = SOSAlert.query.get_or_404(alert_id)
        if alert.user_id != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
            
        if alert.resolved:
            return jsonify({'error': 'SOS alert has already been resolved'}), 400
            
        data = request.get_json() or {}
        lat = data.get('lat')
        lng = data.get('lng')
        
        if lat is not None and lng is not None:
            alert.lat = float(lat)
            alert.lng = float(lng)
            db.session.commit()
            
            loc_payload = {
                'alert_id': alert.id,
                'ride_id': alert.ride_id,
                'user_id': user_id,
                'lat': alert.lat,
                'lng': alert.lng,
                'timestamp': datetime.utcnow().isoformat()
            }
            socketio.emit('sos_location_update', loc_payload, room='admin')
            if alert.ride_id:
                socketio.emit('sos_location_update', loc_payload, room=f'ride_{alert.ride_id}')
            return jsonify({'data': loc_payload}), 200
            
        return jsonify({'error': 'Missing lat or lng'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@sos_bp.route('/<alert_id>/cancel', methods=['POST'])
@jwt_required()
def cancel_sos(alert_id):
    try:
        user_id = get_jwt_identity()
        alert = SOSAlert.query.get_or_404(alert_id)
        if alert.user_id != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
            
        alert.resolved = True
        db.session.commit()
        
        cancel_payload = {
            'alert_id': alert.id,
            'ride_id': alert.ride_id,
            'status': 'resolved',
            'resolved_at': datetime.utcnow().isoformat()
        }
        socketio.emit('sos_resolved', cancel_payload, room='admin')
        if alert.ride_id:
            socketio.emit('sos_resolved', cancel_payload, room=f'ride_{alert.ride_id}')
            
        return jsonify({'data': alert.to_dict(), 'message': 'SOS cancelled successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
