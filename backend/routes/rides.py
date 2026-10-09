from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db, socketio
from models.ride import Ride
from models.user import User
from datetime import datetime, timedelta
import math

rides_bp = Blueprint('rides', __name__)

@rides_bp.route('/request', methods=['POST'])
@jwt_required()
def request_ride():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
            
        # Clear stale in-progress rides (> 30 mins)
        stale = Ride.query.filter(
            Ride.passenger_id == user_id,
            Ride.status == 'in_progress',
            Ride.accepted_at < datetime.utcnow() - timedelta(minutes=30)
        ).all()
        for r in stale:
            r.status = 'cancelled'
        db.session.commit()
        
        print(f"=== NEW RIDE REQUEST ===")
        print(f"User: {user_id}")
        
        # Check for existing active/pending/in-progress ride to prevent overlapping dual rides
        existing = Ride.query.filter(
            Ride.passenger_id == user_id,
            Ride.status.in_(['pending', 'accepted', 'in_progress'])
        ).first()
        
        if existing:
            print(f"Active ride already exists: {existing.id}")
            return jsonify({'ride': existing.to_dict(), 'msg': 'Active ride already exists'}), 200

        # Extract gender preference
        gender_pref = data.get('gender_preference') or data.get('genderPreference')
        normalized_pref = 'All'
        if gender_pref:
            gp = str(gender_pref).strip().lower()
            if 'female' in gp:
                normalized_pref = 'Female'
            elif 'male' in gp:
                normalized_pref = 'Male'

        ride = Ride(
            passenger_id=user_id,
            passenger_name=user.name or 'Passenger',
            from_location=str(data.get('fromLocation', 'Unknown')),
            to_location=str(data.get('toLocation', 'Unknown')),
            from_lat=float(data.get('fromLat', 18.4624)),
            from_lng=float(data.get('fromLng', 73.8670)),
            to_lat=float(data.get('toLat', 18.4700)),
            to_lng=float(data.get('toLng', 73.8750)),
            gender_preference=normalized_pref,
            status='pending'
        )

        db.session.add(ride)
        db.session.commit()
        
        print(f"Ride saved: {ride.id}")
        print(f"Status: {ride.status}")

        # Emit to all riders
        ride_dict = ride.to_dict()
        socketio.emit('new_ride_request', ride_dict)
        print(f"Socket emitted to all clients")
        print(f"=== END RIDE REQUEST ===")

        return jsonify({"ride": ride_dict}), 201

    except Exception as e:
        db.session.rollback()
        print(f"ERROR in request_ride: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@rides_bp.route('/debug', methods=['GET'])
def debug_rides():
  all_rides = Ride.query.all()
  return jsonify({
    'total': len(all_rides),
    'rides': [r.to_dict() for r in all_rides]
  }), 200

@rides_bp.route('/community', methods=['GET'])
@jwt_required(optional=True)
def community_rides():
    try:
        active_statuses = ['pending', 'accepted', 'in_progress']
        rides = Ride.query.filter(Ride.status.in_(active_statuses))\
            .order_by(Ride.created_at.desc())\
            .limit(30)\
            .all()
        
        result = []
        for r in rides:
            full_name = (r.passenger_name or 'Passenger').strip()
            first_name = full_name.split()[0] if full_name else 'Student'
            
            f_lat = round(r.from_lat, 3) if r.from_lat is not None else None
            f_lng = round(r.from_lng, 3) if r.from_lng is not None else None
            t_lat = round(r.to_lat, 3) if r.to_lat is not None else None
            t_lng = round(r.to_lng, 3) if r.to_lng is not None else None

            vehicle_info = 'Campus Ride'
            if r.rider_id:
                rider = User.query.get(r.rider_id)
                if rider and (rider.vehicle_name or rider.vehicle_type):
                    vehicle_info = rider.vehicle_name or rider.vehicle_type
                elif r.rider_name:
                    vehicle_info = f"Ride with {r.rider_name.strip().split()[0]}"
            
            result.append({
                'id': r.id,
                'passengerId': '',
                'passengerName': first_name,
                'fromLocation': r.from_location,
                'toLocation': r.to_location,
                'fromLat': f_lat or 18.462,
                'fromLng': f_lng or 73.867,
                'toLat': t_lat or 18.470,
                'toLng': t_lng or 73.875,
                'status': r.status,
                'pointsAwarded': r.points_awarded or 10,
                'vehicleDetails': vehicle_info,
                'createdAt': r.created_at.isoformat() if r.created_at else None,
                'scheduledTime': r.scheduled_time.isoformat() if r.scheduled_time else None,
            })
            
        return jsonify({'rides': result, 'community_rides': result}), 200
    except Exception as e:
        print(f"ERROR in community_rides: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e), 'rides': [], 'community_rides': []}), 500

def haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371.0 # Radius of the earth in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

@rides_bp.route('/nearby-drivers', methods=['GET'])
@jwt_required(optional=True)
def get_nearby_drivers():
    try:
        current_user_id = get_jwt_identity()
        pickup_lat_param = request.args.get('lat') or request.args.get('pickupLat') or request.args.get('pickup_lat')
        pickup_lng_param = request.args.get('lng') or request.args.get('pickupLng') or request.args.get('pickup_lng')
        radius = float(request.args.get('radius', 15.0))
        gender_filter = request.args.get('gender')
        
        try:
            p_lat = float(pickup_lat_param) if pickup_lat_param is not None else 18.4624
            p_lng = float(pickup_lng_param) if pickup_lng_param is not None else 73.8670
        except (ValueError, TypeError):
            p_lat = 18.4624
            p_lng = 73.8670

        # Query online verified drivers (role == 'rider')
        query = User.query.filter(
            User.role == 'rider',
            User.is_online == True,
            db.or_(User.verification_status == 'approved', User.license_verified == True)
        )
        if current_user_id:
            query = query.filter(User.id != current_user_id)

        # Optional gender filter (Task 11 / Round 3 Task 5)
        if gender_filter and gender_filter.strip().lower() not in ['', 'all', 'any']:
            g_clean = gender_filter.strip().lower()
            if 'female' in g_clean:
                target_gender = 'female'
            elif 'male' in g_clean:
                target_gender = 'male'
            else:
                target_gender = g_clean

            query = query.filter(db.func.lower(db.func.trim(User.gender)) == target_gender)

        candidates = query.all()

        # Filter out drivers already on an active ride (accepted or in_progress)
        busy_driver_ids = set(r[0] for r in db.session.query(Ride.rider_id).filter(
            Ride.rider_id.isnot(None),
            Ride.status.in_(['accepted', 'in_progress'])
        ).all())

        results = []
        for d in candidates:
            if d.id in busy_driver_ids:
                continue

            d_lat = d.current_lat if d.current_lat is not None else 18.4624 + 0.005
            d_lng = d.current_lng if d.current_lng is not None else 73.8670 + 0.005

            dist = haversine_distance(p_lat, p_lng, d_lat, d_lng)
            if dist <= radius:
                eta_minutes = max(2, int(dist * 3))
                vehicle_str = d.vehicle_name or d.vehicle_type or 'Campus Ride'
                results.append({
                    'id': d.id,
                    'name': d.name,
                    'photoUrl': d.avatar_url or '',
                    'gender': d.gender or 'Not specified',
                    'vehicleType': vehicle_str,
                    'vehicleNumber': d.vehicle_number or 'MH-12-CL-0001',
                    'rating': 4.9 if d.points >= 50 else 4.7,
                    'points': d.points,
                    'distance': round(dist, 1),
                    'eta': f"{eta_minutes} mins",
                    'serviceArea': d.service_area or 'Campus Zone',
                    'phone': d.phone or ''
                })

        # Proximity ranking: nearest first
        results.sort(key=lambda x: x['distance'])

        return jsonify({
            'status': 'success',
            'count': len(results),
            'drivers': results
        }), 200

    except Exception as e:
        print(f"Error in nearby_drivers: {e}")
        return jsonify({'error': str(e), 'drivers': [], 'count': 0}), 500

@rides_bp.route('/pending', methods=['GET'])
@jwt_required()
def pending_rides():
  try:
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    driver_gender = (user.gender or '').strip().lower() if user else ''
    
    # Auto-expire pending rides older than 2 hours
    two_hours_ago = datetime.utcnow() - timedelta(hours=2)
    stale_pending = Ride.query.filter(
        Ride.status == 'pending',
        Ride.created_at < two_hours_ago
    ).all()
    if stale_pending:
        for r in stale_pending:
            r.status = 'cancelled'
        db.session.commit()
    
    rides = Ride.query.filter_by(status='pending').all()
    print(f"DEBUG: Found {len(rides)} total pending rides in DB")
    
    result = []
    for r in rides:
      declined = r.get_declined_by()
      print(f"DEBUG: Checking ride {r.id}:")
      print(f"  - Passenger: {r.passenger_id}")
      print(f"  - Current User: {user_id}")
      print(f"  - Declined by: {declined}")
      print(f"  - Gender Preference: {r.gender_preference}")
      
      is_own_ride = str(r.passenger_id) == str(user_id)
      is_declined = str(user_id) in [str(uid) for uid in declined]

      # Enforce gender preference filter
      r_pref = (r.gender_preference or 'All').strip().lower()
      is_gender_match = True
      if r_pref not in ['', 'all', 'any']:
          if 'female' in r_pref:
              if driver_gender != 'female':
                  is_gender_match = False
          elif 'male' in r_pref:
              if driver_gender != 'male':
                  is_gender_match = False
      
      if not is_own_ride and not is_declined and is_gender_match:
        result.append(r.to_dict())
        print(f"  -> ACCEPTED for visibility")
      else:
        reason = "Own ride" if is_own_ride else ("Declined" if is_declined else f"Gender mismatch (pref: {r.gender_preference}, driver: {user.gender if user else 'None'})")
        print(f"  -> SKIPPED (Reason: {reason})")
    
    print(f"DEBUG: Returning {len(result)} rides to client")
    return jsonify({'rides': result}), 200
    
  except Exception as e:
    print(f"ERROR in pending_rides: {e}")
    import traceback
    traceback.print_exc()
    return jsonify({'rides': []}), 200

@rides_bp.route('/<ride_id>/accept', methods=['POST'])
@jwt_required()
def accept_ride(ride_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if user.verification_status != 'approved':
            return jsonify({
                'error': 'Your account is not verified. Please complete driver verification first.'
            }), 403
        
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({'error': 'Ride not found'}), 404
        
        if ride.status != 'pending':
            if ride.rider_id == user_id:
                return jsonify({'ride': ride.to_dict()}), 200
            return jsonify({'error': 'Ride no longer available'}), 400
        
        if ride.passenger_id == user_id:
            return jsonify({'error': 'You cannot accept your own ride'}), 400

        # Enforce gender preference check on ride acceptance
        if ride.gender_preference and ride.gender_preference.strip().lower() not in ['', 'all', 'any']:
            r_pref = ride.gender_preference.strip().lower()
            driver_gender = (user.gender or '').strip().lower()
            if 'female' in r_pref:
                if driver_gender != 'female':
                    return jsonify({'error': 'This ride request is restricted to female drivers only'}), 403
            elif 'male' in r_pref:
                if driver_gender != 'male':
                    return jsonify({'error': 'This ride request is restricted to male drivers only'}), 403

        ride.rider_id = user_id
        ride.rider_name = user.name or 'Rider'
        ride.status = 'accepted'
        ride.accepted_at = datetime.utcnow()
        
        db.session.commit()
        
        ride_dict = ride.to_dict()
        # Notify the passenger and the rider using room and general event
        socketio.emit('ride_accepted', ride_dict, room=f'ride_{ride.id}')
        socketio.emit('ride_accepted', ride_dict, room=f'user_{ride.passenger_id}')
        # Also broadcast for dashboard updates if needed
        socketio.emit('ride_accepted', ride_dict)

        return jsonify({"ride": ride_dict}), 200

    except Exception as e:
        db.session.rollback()
        print(f"ERROR in accept_ride: {str(e)}")
        return jsonify({'error': str(e)}), 500

@rides_bp.route('/<ride_id>/decline', methods=['POST'])
@jwt_required()
def decline_ride(ride_id):
    try:
        user_id = get_jwt_identity()
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"error": "Ride not found"}), 404

        ride.add_declined_by(user_id)
        db.session.commit()
        
        return jsonify({"data": "Ride declined"}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/<ride_id>/start', methods=['POST'])
@jwt_required()
def start_ride(ride_id):
    try:
        user_id = get_jwt_identity()
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"error": "Ride not found"}), 404

        if ride.status == 'in_progress':
            return jsonify({"ride": ride.to_dict()}), 200

        if ride.rider_id != user_id:
            return jsonify({"error": "Only the assigned rider can start this ride"}), 403

        if ride.status != 'accepted':
            return jsonify({"error": f"Cannot start ride from status {ride.status}"}), 400

        ride.status = 'in_progress'
        ride.started_at = datetime.utcnow()
        db.session.commit()
        
        ride_dict = ride.to_dict()
        socketio.emit('ride_started', ride_dict, room=f'ride_{ride.id}')
        socketio.emit('ride_started', ride_dict, room=f'user_{ride.passenger_id}')
        socketio.emit('ride_started', ride_dict, room=f'user_{ride.rider_id}')
        socketio.emit('ride_started', ride_dict)
        
        return jsonify({"ride": ride_dict}), 200

    except Exception as e:
        db.session.rollback()
        print(f"ERROR in start_ride: {str(e)}")
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/<ride_id>/complete', methods=['POST'])
@jwt_required()
def complete_ride(ride_id):
    try:
        user_id = get_jwt_identity()
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"error": "Ride not found"}), 404

        if ride.rider_id != user_id:
            return jsonify({"error": "Unauthorized"}), 403

        if ride.status == 'completed':
            return jsonify({"ride": ride.to_dict()}), 200

        if ride.status not in ['accepted', 'in_progress']:
            return jsonify({"error": f"Cannot complete ride from status {ride.status}"}), 400

        ride.status = 'completed'
        ride.completed_at = datetime.utcnow()
        
        # Add points to rider
        rider = User.query.get(ride.rider_id)
        if rider:
            rider.points = (rider.points or 0) + 10
            
        db.session.commit()
        
        ride_dict = ride.to_dict()
        socketio.emit('ride_completed', ride_dict, room=f'ride_{ride.id}')
        socketio.emit('ride_completed', ride_dict, room=f'user_{ride.passenger_id}')
        socketio.emit('ride_completed', ride_dict, room=f'user_{ride.rider_id}')
        socketio.emit('ride_completed', ride_dict)
        
        return jsonify({"ride": ride_dict}), 200

    except Exception as e:
        db.session.rollback()
        print(f"ERROR in complete_ride: {str(e)}")
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/<ride_id>', methods=['GET'])
@jwt_required()
def get_ride(ride_id):
    try:
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"error": "Ride not found"}), 404
        return jsonify({"data": ride.to_dict()}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/<ride_id>/rate', methods=['POST'])
@jwt_required()
def rate_ride(ride_id):
    try:
        user_id = get_jwt_identity()
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"error": "Ride not found"}), 404
            
        if ride.passenger_id != user_id:
            return jsonify({"error": "Only passenger can rate the ride"}), 403
            
        if ride.status != 'completed':
            return jsonify({"error": "Ride is not completed"}), 400
            
        data = request.get_json()
        rating = data.get('rating')
        if rating is None or not (1 <= rating <= 5):
            return jsonify({"error": "Invalid rating"}), 400
            
        ride.passenger_rating = rating
        
        # Award passenger +5 points for rating
        passenger = User.query.get(user_id)
        if passenger:
            passenger.points += 5
            
        db.session.commit()
        return jsonify({"ride": ride.to_dict(), "points_earned": 5}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/<ride_id>/cancel', methods=['POST'])
@jwt_required()
def cancel_ride(ride_id):
    try:
        user_id = get_jwt_identity()
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"error": "Ride not found"}), 404

        # Only passenger or assigned rider can cancel
        if ride.passenger_id != user_id and ride.rider_id != user_id:
            return jsonify({"error": "Unauthorized"}), 403

        ride.status = 'cancelled'
        db.session.commit()

        socketio.emit('ride_cancelled', {"id": ride.id}, room=f'ride_{ride.id}')
        socketio.emit('ride_cancelled', {"id": ride.id}, room=f'user_{ride.passenger_id}')
        if ride.rider_id:
            socketio.emit('ride_cancelled', {"id": ride.id}, room=f'user_{ride.rider_id}')
        socketio.emit('ride_cancelled', {"id": ride.id})
        
        return jsonify({"data": "Ride cancelled"}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/history', methods=['GET'])
@jwt_required()
def get_history():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        role = request.args.get('role') or (user.role if user else None)
        
        if role in ['rider', 'driver']:
            rides = Ride.query.filter(
                Ride.rider_id == user_id,
                Ride.status.in_(['completed', 'cancelled'])
            ).order_by(Ride.created_at.desc()).all()
        elif role == 'passenger':
            rides = Ride.query.filter(
                Ride.passenger_id == user_id,
                Ride.status.in_(['completed', 'cancelled'])
            ).order_by(Ride.created_at.desc()).all()
        else:
            rides = Ride.query.filter(
                ((Ride.passenger_id == user_id) | (Ride.rider_id == user_id)),
                Ride.status.in_(['completed', 'cancelled'])
            ).order_by(Ride.created_at.desc()).all()
            
        ride_list = [r.to_dict() for r in rides]
        return jsonify({"data": ride_list, "rides": ride_list}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/active', methods=['GET'])
@jwt_required()
def get_active_ride():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        role = user.role if user else None
        
        # Cleanup old pending rides for this user (> 1 hour)
        old_pending = Ride.query.filter(
            Ride.passenger_id == user_id,
            Ride.status == 'pending',
            Ride.created_at < datetime.utcnow() - timedelta(hours=1)
        ).all()
        for r in old_pending:
            r.status = 'cancelled'
        if old_pending:
            db.session.commit()

        if role in ['rider', 'driver']:
            ride = Ride.query.filter(
                Ride.rider_id == user_id,
                Ride.status.in_(['accepted', 'in_progress'])
            ).order_by(Ride.created_at.desc()).first()
        else:
            ride = Ride.query.filter(
                Ride.passenger_id == user_id,
                Ride.status.in_(['pending', 'accepted', 'in_progress'])
            ).order_by(Ride.created_at.desc()).first()
            if not ride:
                ride = Ride.query.filter(
                    Ride.rider_id == user_id,
                    Ride.status.in_(['accepted', 'in_progress'])
                ).order_by(Ride.created_at.desc()).first()
        
        return jsonify({"data": ride.to_dict() if ride else None}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/upcoming', methods=['GET'])
@jwt_required()
def get_upcoming_rides():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        role = request.args.get('role') or (user.role if user else None)
        now = datetime.utcnow()
        
        if role in ['rider', 'driver']:
            rides = Ride.query.filter(
                Ride.rider_id == user_id,
                Ride.status.in_(['accepted', 'in_progress']),
                ((Ride.scheduled_time == None) | (Ride.scheduled_time > now))
            ).order_by(Ride.created_at.desc()).all()
        else:
            rides = Ride.query.filter(
                Ride.passenger_id == user_id,
                Ride.status.in_(['pending', 'accepted']),
                ((Ride.scheduled_time == None) | (Ride.scheduled_time > now))
            ).order_by(Ride.created_at.desc()).all()
            
        ride_list = [r.to_dict() for r in rides]
        return jsonify({"data": ride_list, "rides": ride_list}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/clear-stuck', methods=['GET'])
@jwt_required()
def clear_stuck_rides():
    try:
        user_id = get_jwt_identity()
        thirty_minutes_ago = datetime.utcnow() - timedelta(minutes=30)
        
        stuck_rides = Ride.query.filter(
            Ride.status.in_(['pending', 'accepted', 'in_progress']),
            Ride.created_at < thirty_minutes_ago
        ).all()
        
        count = 0
        for ride in stuck_rides:
            ride.status = 'cancelled'
            count += 1
            socketio.emit('ride_cancelled', {"id": ride.id}, room=f'ride_{ride.id}')
            
        db.session.commit()
        return jsonify({"message": f"Cleared {count} stuck rides"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@rides_bp.route('/<ride_id>/receipt', methods=['GET'])
@jwt_required()
def download_receipt(ride_id):
    try:
        user_id = get_jwt_identity()
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({'error': 'Ride not found'}), 404
        if ride.passenger_id != user_id and ride.rider_id != user_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        receipt_data = {
            'receiptId': ride.id[:8].upper(),
            'date': ride.completed_at.strftime('%d %b %Y %I:%M %p') if ride.completed_at else 'N/A',
            'passengerName': ride.passenger_name,
            'riderName': ride.rider_name or 'N/A',
            'fromLocation': ride.from_location,
            'toLocation': ride.to_location,
            'status': ride.status,
            'pointsAwarded': ride.points_awarded,
            'platformFee': 0,
        }
        return jsonify({'receipt': receipt_data}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@rides_bp.route('/cleanup', methods=['POST'])
@jwt_required()
def cleanup_rides():
    try:
        user_id = get_jwt_identity()
        # Cancel any pending or accepted/in_progress rides for this user
        stuck_rides = Ride.query.filter(
            db.or_(
                Ride.passenger_id == user_id,
                Ride.rider_id == user_id
            ),
            Ride.status.in_(['pending', 'accepted', 'in_progress'])
        ).all()
        
        count = 0
        for ride in stuck_rides:
            ride.status = 'cancelled'
            count += 1
            socketio.emit('ride_cancelled', {'id': ride.id}, room=f'ride_{ride.id}')
            
        db.session.commit()
        return jsonify({'message': f'Cleaned up {count} rides'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
