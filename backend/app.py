from flask import Flask
from extensions import db, jwt, socketio, cors, bcrypt
from flask_cors import CORS
from config import Config
from routes.auth import auth_bp
from routes.users import users_bp, support_bp
from routes.rides import rides_bp
from routes.sos import sos_bp
from routes.admin import admin_bp
from routes.bikes import bikes_bp
from sockets.ride_events import register_ride_events
from flask import render_template

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # SQLAlchemy connection stability
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
    }

    # Initialize extensions
    db.init_app(app)
    jwt.init_app(app)
    socketio.init_app(app)
    CORS(app)



    bcrypt.init_app(app)
    
    # CORS is already initialized with simple settings
    pass


    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(users_bp, url_prefix='/api/users')
    app.register_blueprint(support_bp, url_prefix='/api/support')
    app.register_blueprint(rides_bp, url_prefix='/api/rides')
    app.register_blueprint(sos_bp, url_prefix='/api/sos')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    app.register_blueprint(bikes_bp, url_prefix='/api/bikes')

    @app.route('/admin')
    def admin():
        return render_template('admin.html')

    # Register socket events
    register_ride_events(socketio)

    with app.app_context():
        # Import all models to ensure they are registered with SQLAlchemy
        from models.user import User
        from models.ride import Ride
        from models.sos_alert import SOSAlert
        from models.support_ticket import SupportTicket
        from models.bike import Bike, BikeRental
        from models.trusted_contact import TrustedContact
        try:
            # 1. Idempotent schema verification
            import os
            from migrate_db import ensure_columns
            db_path = app.config.get('SQLALCHEMY_DATABASE_URI', '').replace('sqlite:///', '')
            if not os.path.isabs(db_path):
                db_path = os.path.join(app.instance_path, os.path.basename(db_path))
            ensure_columns(db_path)

            db.create_all()
            print("Database tables verified successfully.")

            # 2. Seed default trusted contacts if none exist
            if TrustedContact.query.count() == 0:
                defaults = [
                    TrustedContact(name="Campus Security Main Desk", phone="+91 98765 43210", category="security", location="Main Campus Gate 1", description="24/7 emergency campus security control room"),
                    TrustedContact(name="National Emergency Helpline", phone="112", category="emergency", location="National", description="All-in-one police, ambulance, fire response"),
                    TrustedContact(name="Campus Health & Medical Center", phone="+91 98765 43211", category="health", location="Health Wing, Block B", description="Immediate medical assistance and ambulance"),
                    TrustedContact(name="Campus Auto Stand", phone="+91 98765 43212", category="auto", location="Hostel 4 Gate", description="Verified local auto rickshaw stand"),
                    TrustedContact(name="City Taxi Services", phone="+91 98765 43213", category="taxi", location="North Terminal", description="Campus-affiliated round-the-clock taxi stand"),
                ]
                for d in defaults:
                    db.session.add(d)
                db.session.commit()
                print("Default trusted contacts seeded successfully.")

            # 3. Bootstrap default admin user if none exists
            admin_email = os.environ.get('ADMIN_EMAIL', 'admin@campuslift.edu')
            dev_admin_pass = os.environ.get('ADMIN_PASSWORD') or os.environ.get('DEFAULT_DEV_ADMIN_PASSWORD', 'Admin@123')
            admin_user = User.query.filter(
                (User.is_admin == True) | (User.role == 'admin') | (User.email == admin_email)
            ).first()

            if not admin_user:
                admin_user = User(
                    name="admin",
                    email=admin_email,
                    role="admin",
                    is_admin=True,
                    accepted_guidelines=True
                )
                admin_user.set_password(dev_admin_pass)
                db.session.add(admin_user)
                db.session.commit()
                print("Default admin account created successfully (admin@campuslift.edu / Admin@123).")
            elif not admin_user.check_password(dev_admin_pass) and os.environ.get('FLASK_ENV') != 'production':
                admin_user.set_password(dev_admin_pass)
                admin_user.is_admin = True
                admin_user.role = 'admin'
                db.session.commit()
                print("Dev admin credentials synchronized (admin@campuslift.edu / Admin@123).")

        except Exception as e:
            import logging
            logging.critical(f"FATAL: Database initialization error: {e}", exc_info=True)
            raise SystemExit(f"Database initialization failed: {e}. Preserved database without dropping tables.")

    return app

if __name__ == '__main__':
    app = create_app()
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
