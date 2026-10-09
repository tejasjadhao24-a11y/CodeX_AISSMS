import sys
import os
import unittest
import json
import uuid

# Ensure backend directory is on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from extensions import db
from models.user import User
from models.ride import Ride

class TestRideFlowComplete(unittest.TestCase):
    def setUp(self):
        self.app = create_app()
        self.client = self.app.test_client()
        self.ctx = self.app.app_context()
        self.ctx.push()

    def tearDown(self):
        self.ctx.pop()

    def _register_and_login(self, email, name, role, gender="Male"):
        # Register
        resp = self.client.post('/api/auth/register', json={
            "name": name,
            "email": email,
            "password": "Password@123",
            "phone": "9876543210",
            "role": role,
            "gender": gender
        })
        if resp.status_code not in [200, 201]:
            resp = self.client.post('/api/auth/login', json={
                "email": email,
                "password": "Password@123"
            })
        data = resp.get_json()
        d = data.get("data", data)
        token = d.get("token") or d.get("access_token")
        user = d.get("user", {})
        user_id = user.get("id")
        return token, user_id

    def test_complete_ride_flow(self):
        suffix = str(uuid.uuid4())[:6]
        
        # 1. Create Driver (verified, approved)
        driver_email = f"driver_{suffix}@test.com"
        driver_token, driver_id = self._register_and_login(driver_email, "Driver Bob", "rider", "Male")
        self.assertIsNotNone(driver_token)
        
        # Set driver approved & online
        driver = User.query.get(driver_id)
        driver.verification_status = 'approved'
        driver.is_online = True
        db.session.commit()

        # 2. Create Passenger
        passenger_email = f"passenger_{suffix}@test.com"
        passenger_token, passenger_id = self._register_and_login(passenger_email, "Passenger Alice", "passenger", "Female")
        self.assertIsNotNone(passenger_token)

        headers_p = {"Authorization": f"Bearer {passenger_token}"}
        headers_d = {"Authorization": f"Bearer {driver_token}"}

        # 3. Passenger requests a ride
        req_resp = self.client.post('/api/rides/request', json={
            "fromLocation": "Campus Gate 1",
            "toLocation": "Library",
            "fromLat": 18.4624,
            "fromLng": 73.8670,
            "toLat": 18.4700,
            "toLng": 73.8750,
            "genderPreference": "All"
        }, headers=headers_p)
        self.assertEqual(req_resp.status_code, 201)
        req_data = req_resp.get_json()
        ride_data = req_data.get("ride")
        self.assertIsNotNone(ride_data)
        ride_id = ride_data["id"]
        self.assertEqual(ride_data["status"], "pending")

        # 4. Driver fetches pending rides -> should see the new ride
        pending_resp = self.client.get('/api/rides/pending', headers=headers_d)
        self.assertEqual(pending_resp.status_code, 200)
        pending_rides = pending_resp.get_json().get("rides", [])
        ride_ids = [r["id"] for r in pending_rides]
        self.assertIn(ride_id, ride_ids, "Driver should see the newly requested ride in pending list")

        # 5. Driver accepts ride
        accept_resp = self.client.post(f'/api/rides/{ride_id}/accept', headers=headers_d)
        self.assertEqual(accept_resp.status_code, 200)
        accept_data = accept_resp.get_json().get("ride")
        self.assertEqual(accept_data["status"], "accepted")
        self.assertEqual(accept_data["riderId"], driver_id)

        # 6. Check /rides/active for passenger -> should return accepted ride
        active_p_resp = self.client.get('/api/rides/active', headers=headers_p)
        self.assertEqual(active_p_resp.status_code, 200)
        active_p = active_p_resp.get_json().get("data")
        self.assertIsNotNone(active_p)
        self.assertEqual(active_p["id"], ride_id)
        self.assertEqual(active_p["status"], "accepted")

        # 7. Check /rides/active for driver -> should return accepted ride
        active_d_resp = self.client.get('/api/rides/active', headers=headers_d)
        self.assertEqual(active_d_resp.status_code, 200)
        active_d = active_d_resp.get_json().get("data")
        self.assertIsNotNone(active_d)
        self.assertEqual(active_d["id"], ride_id)
        self.assertEqual(active_d["status"], "accepted")

        # 8. Driver starts ride
        start_resp = self.client.post(f'/api/rides/{ride_id}/start', headers=headers_d)
        self.assertEqual(start_resp.status_code, 200)
        start_data = start_resp.get_json().get("ride")
        self.assertEqual(start_data["status"], "in_progress")

        # Test idempotency: calling start again should return 200
        start_again_resp = self.client.post(f'/api/rides/{ride_id}/start', headers=headers_d)
        self.assertEqual(start_again_resp.status_code, 200)

        # 9. Driver completes ride
        complete_resp = self.client.post(f'/api/rides/{ride_id}/complete', headers=headers_d)
        self.assertEqual(complete_resp.status_code, 200)
        complete_data = complete_resp.get_json().get("ride")
        self.assertEqual(complete_data["status"], "completed")

        # Test idempotency: calling complete again should return 200
        complete_again_resp = self.client.post(f'/api/rides/{ride_id}/complete', headers=headers_d)
        self.assertEqual(complete_again_resp.status_code, 200)

        # 10. Check /rides/active -> should be None now
        active_p_after = self.client.get('/api/rides/active', headers=headers_p).get_json().get("data")
        self.assertIsNone(active_p_after, "Active ride should be None after completion")

        # 11. Passenger rates the ride
        rate_resp = self.client.post(f'/api/rides/{ride_id}/rate', json={"rating": 5}, headers=headers_p)
        self.assertEqual(rate_resp.status_code, 200)

        # 12. History check
        hist_p_resp = self.client.get('/api/rides/history?role=passenger', headers=headers_p)
        self.assertEqual(hist_p_resp.status_code, 200)
        p_rides = [r["id"] for r in hist_p_resp.get_json().get("rides", [])]
        self.assertIn(ride_id, p_rides)

        hist_d_resp = self.client.get('/api/rides/history?role=rider', headers=headers_d)
        self.assertEqual(hist_d_resp.status_code, 200)
        d_rides = [r["id"] for r in hist_d_resp.get_json().get("rides", [])]
        self.assertIn(ride_id, d_rides)

        print("\n[SUCCESS] End-to-end ride flow verified successfully!")

if __name__ == '__main__':
    unittest.main()
