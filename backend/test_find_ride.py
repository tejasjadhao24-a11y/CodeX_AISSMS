import urllib.request
import urllib.error
import json
import uuid

BASE_URL = "http://127.0.0.1:5000/api"

def make_req(url, method="GET", data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read().decode("utf-8")
            return resp.status, json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        content = e.read().decode("utf-8")
        try:
            return e.code, json.loads(content)
        except Exception:
            return e.code, {"raw": content}

def login(email, password, role="rider", name="Test Driver", gender="Male"):
    status, data = make_req(f"{BASE_URL}/auth/register", "POST", {
        "name": name,
        "email": email,
        "password": password,
        "phone": "9876543210",
        "role": role,
        "gender": gender
    })
    if status not in [200, 201]:
        status, data = make_req(f"{BASE_URL}/auth/login", "POST", {
            "email": email,
            "password": password
        })
    d = data.get("data", data)
    token = d.get("token") or d.get("access_token")
    user = d.get("user", {})
    if role and token:
        make_req(f"{BASE_URL}/users/role", "PATCH", {"role": role}, token=token)
    return token, user.get("id")

print("--- Testing Task 7: Find Ride Matching Logic ---")
suffix = str(uuid.uuid4())[:6]

# 0. Get admin token
s, admin_login = make_req(f"{BASE_URL}/admin/login", "POST", {"username": "admin", "password": "Admin@123"})
admin_token = admin_login.get("token")
assert admin_token is not None, "Admin login must succeed"

# Driver 1: Male, online, approved, 0.5km away
t_d1, id_d1 = login(f"driver1_{suffix}@test.com", "Driver@123", "rider", name="Rohan Sharma", gender="Male")
make_req(f"{BASE_URL}/users/license", "PATCH", {
    "licenseNumber": "MH122020001",
    "licenseType": "MCWG",
    "vehicleType": "Hero Splendor",
    "vehicleName": "Splendor Plus",
    "vehicleRcNumber": "MH-12-RS-1001"
}, token=t_d1)
make_req(f"{BASE_URL}/users/profile", "PATCH", {"gender": "Male"}, token=t_d1)
make_req(f"{BASE_URL}/admin/verifications/{id_d1}/approve", "PATCH", token=admin_token)
make_req(f"{BASE_URL}/users/online", "PATCH", {
    "is_online": True,
    "lat": 18.4630,
    "lng": 73.8675
}, token=t_d1)

# Driver 2: Female, online, approved, 1.5km away
t_d2, id_d2 = login(f"driver2_{suffix}@test.com", "Driver@123", "rider", name="Ananya Sen", gender="Female")
make_req(f"{BASE_URL}/users/license", "PATCH", {
    "licenseNumber": "MH122020002",
    "licenseType": "MCWG",
    "vehicleType": "Honda Activa",
    "vehicleName": "Activa 6G",
    "vehicleRcNumber": "MH-12-AS-2002"
}, token=t_d2)
make_req(f"{BASE_URL}/users/profile", "PATCH", {"gender": "Female"}, token=t_d2)
make_req(f"{BASE_URL}/admin/verifications/{id_d2}/approve", "PATCH", token=admin_token)
make_req(f"{BASE_URL}/users/online", "PATCH", {
    "is_online": True,
    "lat": 18.4710,
    "lng": 73.8720
}, token=t_d2)

# Driver 3: Male, online, approved, BUT busy on an active in-progress ride!
t_d3, id_d3 = login(f"driver3_{suffix}@test.com", "Driver@123", "rider", name="Busy Driver", gender="Male")
make_req(f"{BASE_URL}/users/license", "PATCH", {
    "licenseNumber": "MH122020003",
    "licenseType": "MCWG",
    "vehicleType": "Pulsar 150",
    "vehicleName": "Bajaj Pulsar",
    "vehicleRcNumber": "MH-12-BD-3003"
}, token=t_d3)
make_req(f"{BASE_URL}/admin/verifications/{id_d3}/approve", "PATCH", token=admin_token)
make_req(f"{BASE_URL}/users/online", "PATCH", {
    "is_online": True,
    "lat": 18.4625,
    "lng": 73.8671
}, token=t_d3)

# Passenger requests ride and Driver 3 accepts and starts it -> in_progress
t_p, id_p = login(f"passenger_{suffix}@test.com", "Pass@123", "passenger", name="Test Passenger")
s, r_resp = make_req(f"{BASE_URL}/rides/request", "POST", {
    "fromLocation": "Main Gate",
    "toLocation": "Tech Park",
    "fromLat": 18.4624,
    "fromLng": 73.8670,
    "toLat": 18.4700,
    "toLng": 73.8750
}, token=t_p)
ride_id = r_resp["ride"]["id"]
make_req(f"{BASE_URL}/rides/{ride_id}/accept", "POST", token=t_d3)
make_req(f"{BASE_URL}/rides/{ride_id}/start", "POST", token=t_d3)
print(f"[OK] Driver 3 put on active in_progress ride: {ride_id}")

# 1. Query nearby drivers around 18.4624, 73.8670
s, res = make_req(f"{BASE_URL}/rides/nearby-drivers?lat=18.4624&lng=73.8670&radius=10")
assert s == 200, f"Query failed: {s} {res}"
drivers = res.get("drivers", [])
driver_ids = [d["id"] for d in drivers]

# Driver 3 (busy) must NOT be in results
assert id_d3 not in driver_ids, f"Driver 3 is on an active ride and must be excluded! Found in {driver_ids}"
print("[OK] Busy driver on active ride correctly excluded")

# Driver 1 and 2 must be found
assert id_d1 in driver_ids, "Driver 1 should be found"
assert id_d2 in driver_ids, "Driver 2 should be found"
print(f"[OK] Found {len(drivers)} available nearby drivers")

# Check proximity ranking (sorted by distance ascending)
distances = [d["distance"] for d in drivers]
assert distances == sorted(distances), f"Drivers must be sorted by distance: {distances}"
print(f"[OK] Drivers ranked by proximity correctly: {distances}")

# 2. Test Gender Filter (Female only)
s, res_fem = make_req(f"{BASE_URL}/rides/nearby-drivers?lat=18.4624&lng=73.8670&gender=female")
assert s == 200
fem_ids = [d["id"] for d in res_fem.get("drivers", [])]
assert id_d2 in fem_ids, "Female driver should be in results"
assert id_d1 not in fem_ids, "Male driver should NOT be in female-filtered results"
print(f"[OK] Gender filter (female) works: only female driver returned")

# 3. Test Zero-results case (far coordinates)
s, res_empty = make_req(f"{BASE_URL}/rides/nearby-drivers?lat=0.0&lng=0.0&radius=1")
assert s == 200
assert res_empty.get("count") == 0
assert len(res_empty.get("drivers", [])) == 0
print(f"[OK] Zero-results handled cleanly with 200 OK and empty list")

print("\n=== TASK 7 & TASK 11 BACKEND MATCHING LOGIC VERIFIED 100% ===")
