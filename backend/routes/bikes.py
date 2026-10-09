from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db, socketio
from models.bike import Bike, BikeRental
from models.user import User
from datetime import datetime

bikes_bp = Blueprint('bikes', __name__)

@bikes_bp.route('/post', methods=['POST'])
@jwt_required()
def post_bike():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.json or {}
    try:
        payment_method = data.get('paymentMethod', 'Both')
        owner_upi_id = data.get('ownerUpiId', '').strip()
        if payment_method in ['UPI', 'Both'] and not owner_upi_id:
            # If UPI is accepted, UPI ID is required
            owner_upi_id = user.email # fallback placeholder
            
        new_bike = Bike(
            owner_id=user_id,
            owner_name=user.name,
            owner_upi_id=owner_upi_id,
            bike_type=data.get('bikeType', 'bicycle'),
            bike_name=data.get('bikeName', 'Bike'),
            bike_number=data.get('bikeNumber', 'N/A'),
            price_per_hour=float(data.get('pricePerHour', 20.0)),
            location=data.get('location', 'Campus'),
            description=data.get('description', ''),
            payment_method=payment_method,
            is_available=True
        )
        db.session.add(new_bike)
        db.session.commit()
        
        bike_dict = new_bike.to_dict()
        socketio.emit('new_bike_posted', bike_dict)
        print(f"Bike posted: {new_bike.bike_name} ({new_bike.id})")
        
        return jsonify({'bike': bike_dict}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 400

@bikes_bp.route('/available', methods=['GET'])
@jwt_required()
def get_available_bikes():
    user_id = get_jwt_identity()
    
    # Exclude bikes that currently have approved, payment_pending, payment_done, or active rentals
    in_flight_subquery = db.session.query(BikeRental.bike_id).filter(
        BikeRental.status.in_(['approved', 'payment_pending', 'payment_done', 'active'])
    ).subquery()

    bikes = Bike.query.filter(
        Bike.is_available == True,
        Bike.owner_id != user_id,
        ~Bike.id.in_(in_flight_subquery)
    ).order_by(Bike.created_at.desc()).limit(50).all()
    
    response = jsonify([bike.to_dict() for bike in bikes])
    response.headers['Cache-Control'] = 'no-cache'
    return response, 200

@bikes_bp.route('/my-bikes', methods=['GET'])
@jwt_required()
def get_my_bikes():
    user_id = get_jwt_identity()
    bikes = Bike.query.filter_by(owner_id=user_id).order_by(Bike.created_at.desc()).limit(50).all()
    return jsonify([bike.to_dict() for bike in bikes]), 200

@bikes_bp.route('/<bike_id>/toggle-availability', methods=['PATCH'])
@jwt_required()
def toggle_availability(bike_id):
    user_id = get_jwt_identity()
    bike = Bike.query.get_or_404(bike_id)
    
    if bike.owner_id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    bike.is_available = not bike.is_available
    db.session.commit()
    return jsonify(bike.to_dict()), 200

@bikes_bp.route('/<bike_id>', methods=['GET'])
@jwt_required()
def get_bike_detail(bike_id):
    bike = Bike.query.get(bike_id)
    if not bike:
        return jsonify({'error': 'Bike not found'}), 404
    return jsonify(bike.to_dict()), 200

@bikes_bp.route('/<bike_id>', methods=['DELETE'])
@jwt_required()
def delete_bike(bike_id):
    user_id = get_jwt_identity()
    bike = Bike.query.get_or_404(bike_id)
    
    if bike.owner_id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    active_rental = BikeRental.query.filter_by(bike_id=bike_id).filter(
        BikeRental.status.in_(['requested', 'approved', 'payment_pending', 'payment_done', 'active'])
    ).first()
    
    if active_rental:
        return jsonify({'error': 'Cannot delete bike with active or pending rentals'}), 400
        
    db.session.delete(bike)
    db.session.commit()
    return jsonify({'message': 'Deleted'}), 200

@bikes_bp.route('/<bike_id>/request-rental', methods=['POST'])
@jwt_required()
def request_rental(bike_id):
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    bike = Bike.query.get(bike_id)
    
    if not bike:
        return jsonify({'error': 'Bike not found'}), 404

    # Rule 1: Cannot rent own bike
    if bike.owner_id == user_id:
        return jsonify({'error': 'Cannot rent your own bike'}), 400

    # Rule 2: Cannot request if bike is unavailable or already has an approved/active rental in flight
    in_flight = BikeRental.query.filter(
        BikeRental.bike_id == bike_id,
        BikeRental.status.in_(['approved', 'payment_pending', 'payment_done', 'active'])
    ).first()
    if not bike.is_available or in_flight:
        return jsonify({'error': 'Bike is currently unavailable or booked by another student'}), 400

    # Rule 3: Check if requester already has a pending request for this bike
    existing_req = BikeRental.query.filter(
        BikeRental.bike_id == bike_id,
        BikeRental.renter_id == user_id,
        BikeRental.status == 'requested'
    ).first()
    if existing_req:
        return jsonify({'error': 'You already have a pending request for this bike', 'rental': existing_req.to_dict()}), 400

    data = request.json or {}
    try:
        start_time_str = data.get('startTime')
        end_time_str = data.get('endTime')
        
        if start_time_str and end_time_str:
            start_time = datetime.fromisoformat(start_time_str.replace('Z', '+00:00'))
            end_time = datetime.fromisoformat(end_time_str.replace('Z', '+00:00'))
            duration = max(1.0, (end_time - start_time).total_seconds() / 3600)
        else:
            duration = float(data.get('hours', 2.0))
            start_time = datetime.utcnow()
            from datetime import timedelta
            end_time = start_time + timedelta(hours=duration)
            
        total_amount = round(duration * bike.price_per_hour, 2)
        payment_method = data.get('paymentMethod', 'UPI')
        
        rental = BikeRental(
            bike_id=bike_id,
            renter_id=user_id,
            renter_name=user.name if user else 'Student',
            owner_id=bike.owner_id,
            start_time=start_time,
            end_time=end_time,
            total_hours=duration,
            total_amount=total_amount,
            payment_method=payment_method,
            status='requested'
        )
        
        db.session.add(rental)
        db.session.commit()
        
        rental_dict = rental.to_dict()
        socketio.emit('rental_requested', rental_dict)
        print(f"Rental requested: {rental.id} for bike {bike_id}")
        
        return jsonify({'rental': rental_dict}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 400

@bikes_bp.route('/rentals/<rental_id>/approve', methods=['POST'])
@jwt_required()
def approve_rental(rental_id):
    user_id = get_jwt_identity()
    rental = BikeRental.query.get(rental_id)
    if not rental:
        return jsonify({'error': 'Rental not found'}), 404
    
    # Only bike owner can approve
    if rental.owner_id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    if rental.status != 'requested':
        return jsonify({'error': f'Cannot approve rental in status {rental.status}'}), 400

    # Rule: Check if another rental was already approved or active for this bike
    in_flight = BikeRental.query.filter(
        BikeRental.bike_id == rental.bike_id,
        BikeRental.id != rental.id,
        BikeRental.status.in_(['approved', 'payment_pending', 'payment_done', 'active'])
    ).first()
    if in_flight:
        return jsonify({'error': 'This bike already has an approved or active rental'}), 400

    # Transition to approved
    rental.status = 'approved'
    bike = Bike.query.get(rental.bike_id)
    if bike:
        bike.is_available = False # Hide from search

    # DOUBLE-BOOKING GAP FIX: Auto-cancel all other pending requests for this bike
    other_requests = BikeRental.query.filter(
        BikeRental.bike_id == rental.bike_id,
        BikeRental.id != rental.id,
        BikeRental.status == 'requested'
    ).all()
    for o in other_requests:
        o.status = 'cancelled'
        socketio.emit('rental_cancelled', o.to_dict())

    db.session.commit()
    
    rental_dict = rental.to_dict()
    socketio.emit('rental_approved', rental_dict)
    
    return jsonify(rental_dict), 200

@bikes_bp.route('/rentals/<rental_id>/confirm-payment', methods=['POST'])
@jwt_required()
def confirm_payment(rental_id):
    user_id = get_jwt_identity()
    rental = BikeRental.query.get(rental_id)
    if not rental:
        return jsonify({'error': 'Rental not found'}), 404
    
    # Only the renter confirms payment
    if rental.renter_id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    if rental.status not in ['approved', 'payment_pending']:
        return jsonify({'error': f'Cannot confirm payment for rental in status {rental.status}'}), 400

    data = request.json or {}
    if data.get('paymentScreenshot'):
        rental.payment_screenshot = data.get('paymentScreenshot')
    if data.get('paymentMethod'):
        rental.payment_method = data.get('paymentMethod')

    rental.status = 'payment_done'
    db.session.commit()
    
    rental_dict = rental.to_dict()
    socketio.emit('payment_done', rental_dict)
    
    return jsonify(rental_dict), 200

@bikes_bp.route('/rentals/<rental_id>/confirm-received', methods=['POST'])
@jwt_required()
def confirm_received(rental_id):
    user_id = get_jwt_identity()
    rental = BikeRental.query.get(rental_id)
    if not rental:
        return jsonify({'error': 'Rental not found'}), 404
    
    # Owner confirms handover
    if rental.owner_id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    if rental.status not in ['approved', 'payment_pending', 'payment_done']:
        return jsonify({'error': f'Cannot activate rental from status {rental.status}'}), 400

    rental.status = 'active'
    bike = Bike.query.get(rental.bike_id)
    if bike:
        bike.is_available = False
        
    db.session.commit()
    
    rental_dict = rental.to_dict()
    socketio.emit('rental_active', rental_dict)
    
    return jsonify(rental_dict), 200

@bikes_bp.route('/rentals/<rental_id>/return', methods=['POST'])
@jwt_required()
def return_bike(rental_id):
    user_id = get_jwt_identity()
    rental = BikeRental.query.get(rental_id)
    if not rental:
        return jsonify({'error': 'Rental not found'}), 404
    
    # Owner or renter confirms return
    if user_id not in [rental.owner_id, rental.renter_id]:
        return jsonify({'error': 'Unauthorized'}), 403
        
    if rental.status != 'active':
        return jsonify({'error': f'Cannot return bike from status {rental.status}'}), 400

    rental.status = 'completed'
    bike = Bike.query.get(rental.bike_id)
    if bike:
        bike.is_available = True
        
    db.session.commit()
    
    rental_dict = rental.to_dict()
    socketio.emit('rental_completed', rental_dict)
    
    return jsonify(rental_dict), 200

@bikes_bp.route('/rentals/<rental_id>/cancel', methods=['POST'])
@jwt_required()
def cancel_rental(rental_id):
    user_id = get_jwt_identity()
    rental = BikeRental.query.get(rental_id)
    if not rental:
        return jsonify({'error': 'Rental not found'}), 404
    
    if user_id not in [rental.owner_id, rental.renter_id]:
        return jsonify({'error': 'Unauthorized'}), 403
        
    if rental.status not in ['requested', 'approved', 'payment_pending']:
        return jsonify({'error': 'Cannot cancel at this stage'}), 400
        
    rental.status = 'cancelled'
    
    # If no other approved/active rental exists for this bike, restore bike availability
    active_exists = BikeRental.query.filter(
        BikeRental.bike_id == rental.bike_id,
        BikeRental.id != rental.id,
        BikeRental.status.in_(['approved', 'payment_pending', 'payment_done', 'active'])
    ).first()
    if not active_exists:
        bike = Bike.query.get(rental.bike_id)
        if bike:
            bike.is_available = True

    db.session.commit()
    
    rental_dict = rental.to_dict()
    socketio.emit('rental_cancelled', rental_dict)
    
    return jsonify(rental_dict), 200

@bikes_bp.route('/rentals/<rental_id>', methods=['GET'])
@jwt_required()
def get_rental_detail(rental_id):
    rental = BikeRental.query.get(rental_id)
    if not rental:
        return jsonify({'error': 'Rental not found'}), 404
    return jsonify(rental.to_dict()), 200

@bikes_bp.route('/my-rentals', methods=['GET'])
@jwt_required()
def get_my_rentals():
    user_id = get_jwt_identity()
    rentals = BikeRental.query.filter_by(renter_id=user_id).order_by(BikeRental.created_at.desc()).limit(50).all()
    return jsonify([rental.to_dict() for rental in rentals]), 200

@bikes_bp.route('/incoming-rentals', methods=['GET'])
@jwt_required()
def get_incoming_rentals():
    user_id = get_jwt_identity()
    rentals = BikeRental.query.filter_by(owner_id=user_id).order_by(BikeRental.created_at.desc()).limit(50).all()
    return jsonify([rental.to_dict() for rental in rentals]), 200
