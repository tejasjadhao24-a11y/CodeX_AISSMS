import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'campuslift-secret-2024')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///campus_lift.db')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'jwt-campuslift-2024')
    JWT_ACCESS_TOKEN_EXPIRES = False
    SQLALCHEMY_TRACK_MODIFICATIONS = False
