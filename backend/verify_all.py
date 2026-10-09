import urllib.request
import json

print("=== RUNNING FULL VERIFICATION SUITE ===")

# 1. Verify /api/admin/login
login_req = urllib.request.Request(
    'http://127.0.0.1:5000/api/admin/login',
    data=json.dumps({'username': 'admin', 'password': 'Admin@123'}).encode('utf-8'),
    headers={'Content-Type': 'application/json'}
)
with urllib.request.urlopen(login_req) as resp:
    assert resp.getcode() == 200
    login_data = json.loads(resp.read().decode('utf-8'))
    token = login_data.get('token')
    assert token is not None, "Missing admin token in response"
    print("[PASS] 1. Admin Login & JWT issuance verified.")

# 2. Verify /api/admin/stats with Bearer JWT
stats_req = urllib.request.Request(
    'http://127.0.0.1:5000/api/admin/stats',
    headers={'Authorization': f'Bearer {token}'}
)
with urllib.request.urlopen(stats_req) as resp:
    assert resp.getcode() == 200
    stats_data = json.loads(resp.read().decode('utf-8'))
    print(f"[PASS] 2. Admin Stats with Bearer token verified (Total Users: {stats_data.get('total_users')}).")

# 3. Verify /api/rides/community (Task 2)
comm_req = urllib.request.Request('http://127.0.0.1:5000/api/rides/community')
with urllib.request.urlopen(comm_req) as resp:
    assert resp.getcode() == 200
    comm_data = json.loads(resp.read().decode('utf-8'))
    assert 'community_rides' in comm_data
    assert 'rides' in comm_data
    rides = comm_data['community_rides']
    print(f"[PASS] 3. /api/rides/community verified ({len(rides)} active rides returned).")
    if rides:
        r = rides[0]
        assert 'passengerName' in r
        assert 'fromLocation' in r
        assert 'toLocation' in r
        assert ' ' not in r['passengerName'].strip(), "Name should be anonymized to first name only"
        print(f"       Anonymized ride check passed: {r['passengerName']} ({r['fromLocation']} -> {r['toLocation']})")

# 4. Verify /api/rides/history (Task 3: Driver & Passenger history)
# Generate a token for test user
user_login_req = urllib.request.Request(
    'http://127.0.0.1:5000/api/auth/login',
    data=json.dumps({'email': 'rider@campuslift.edu', 'password': 'Password@123'}).encode('utf-8'),
    headers={'Content-Type': 'application/json'}
)
try:
    with urllib.request.urlopen(user_login_req) as resp:
        u_data = json.loads(resp.read().decode('utf-8'))
        u_token = u_data.get('token')
except Exception:
    # Fallback to admin token or any other registered user
    u_token = token

hist_driver_req = urllib.request.Request(
    'http://127.0.0.1:5000/api/rides/history?role=rider',
    headers={'Authorization': f'Bearer {u_token}'}
)
with urllib.request.urlopen(hist_driver_req) as resp:
    assert resp.getcode() == 200
    h_data = json.loads(resp.read().decode('utf-8'))
    assert 'data' in h_data
    assert 'rides' in h_data
    print(f"[PASS] 4. /api/rides/history?role=rider verified ({len(h_data['data'])} driver rides returned).")

hist_pass_req = urllib.request.Request(
    'http://127.0.0.1:5000/api/rides/history?role=passenger',
    headers={'Authorization': f'Bearer {u_token}'}
)
with urllib.request.urlopen(hist_pass_req) as resp:
    assert resp.getcode() == 200
    h_data = json.loads(resp.read().decode('utf-8'))
    assert 'data' in h_data
    assert 'rides' in h_data
    print(f"[PASS] 4. /api/rides/history?role=passenger verified ({len(h_data['data'])} passenger rides returned).")

print("\nALL VERIFICATIONS PASSED SUCCESSFULLY!")
