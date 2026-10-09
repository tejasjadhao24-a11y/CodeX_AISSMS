from flask_socketio import join_room, leave_room, emit
from extensions import socketio

def register_ride_events(socketio_instance):
    @socketio_instance.on('join_ride_room')
    def on_join(data):
        ride_id = data.get('ride_id') or data.get('rideId')
        if ride_id:
            room = f'ride_{ride_id}'
            join_room(room)
            print(f"User joined room: {room}")

    @socketio_instance.on('join_user_room')
    def on_join_user(data):
        user_id = data.get('user_id')
        if user_id:
            room = f'user_{user_id}'
            join_room(room)
            print(f"User joined room: {room}")

    @socketio_instance.on('leave_ride_room')
    def on_leave(data):
        ride_id = data.get('ride_id') or data.get('rideId')
        if ride_id:
            room = f'ride_{ride_id}'
            leave_room(room)
            print(f"User left room: {room}")

    @socketio_instance.on('update_location')
    def on_location_update(data):
        ride_id = data.get('ride_id') or data.get('rideId')
        if ride_id:
            emit('location_update', data, room=f'ride_{ride_id}')

    @socketio_instance.on('rider_online')
    def on_rider_online():
        join_room('riders')
        print("Rider joined 'riders' room")

    @socketio_instance.on('rider_offline')
    def on_rider_offline():
        leave_room('riders')
        print("Rider left 'riders' room")

    @socketio_instance.on('sos_live_location')
    def on_sos_live_location(data):
        emit('sos_location_update', data, room='admin')
        ride_id = data.get('ride_id') or data.get('rideId')
        if ride_id:
            emit('sos_location_update', data, room=f'ride_{ride_id}')

    @socketio_instance.on('join_admin_room')
    def on_join_admin(data=None):
        data = data or {}
        token = data.get('token')
        if not token:
            print("Admin join rejected: No token provided")
            emit('admin_error', {'message': 'Authentication required'})
            return
        try:
            from flask_jwt_extended import decode_token
            decoded = decode_token(token)
            is_admin = decoded.get('is_admin', False)
            user_id = decoded.get('sub')
            
            # Also check user model if claim not yet updated
            if not is_admin:
                from models.user import User
                user = User.query.get(user_id)
                if user and (getattr(user, 'is_admin', False) or user.role == 'admin'):
                    is_admin = True

            if is_admin:
                join_room('admin')
                print(f"Admin socket joined 'admin' room: user {user_id}")
                emit('admin_joined', {'status': 'success', 'room': 'admin'})
            else:
                print(f"Admin join rejected: User {user_id} is not admin")
                emit('admin_error', {'message': 'Admin privilege required'})
        except Exception as e:
            print(f"Admin join token error: {e}")
            emit('admin_error', {'message': f'Invalid token: {str(e)}'})

    @socketio_instance.on('leave_admin_room')
    def on_leave_admin():
        leave_room('admin')
        print("Admin left 'admin' room")
