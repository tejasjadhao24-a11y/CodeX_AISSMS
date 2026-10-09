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

def register_and_login(email, password, role="rider", name="Test User", gender="Male"):
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

def run_tests():
    print("=== RUNNING TASK 5 GENDER FILTER CORRECTNESS TEST SUITE ===")
    suffix = str(uuid.uuid4())[:6]

    # Admin Login
    s, admin_data = make_req(f"{BASE_URL}/admin/login", "POST", {"username": "admin", "password": "Admin@123"})
    admin_token = admin_data.get("token")
    assert admin_token is not None, "Admin login must succeed"

    # Seed Driver M: Male driver
    t_male, id_male = register_and_login(f"driver_m_{suffix}@campuslift.edu", "Driver@123", "rider", name="Aarav Sharma", gender="Male")
    make_req(f"{BASE_URL}/users/license", "PATCH", {
        "licenseNumber": f"MH12M{suffix[:4]}",
        "licenseType": "MCWG",
        "vehicleType": "Bike",
        "vehicleName": "Honda CB Shine",
        "vehicleRcNumber": f"MH-12-M-{suffix[:4]}"
    }, token=t_male)
    make_req(f"{BASE_URL}/users/profile", "PATCH", {"gender": "Male"}, token=t_male)
    make_req(f"{BASE_URL}/admin/verifications/{id_male}/approve", "PATCH", token=admin_token)
    make_req(f"{BASE_URL}/users/online", "PATCH", {"is_online": True, "lat": 18.4630, "lng": 73.8675}, token=t_male)

    # Seed Driver F: Female driver
    t_fem, id_fem = register_and_login(f"driver_f_{suffix}@campuslift.edu", "Driver@123", "rider", name="Priya Patel", gender="Female")
    make_req(f"{BASE_URL}/users/license", "PATCH", {
        "licenseNumber": f"MH12F{suffix[:4]}",
        "licenseType": "MCWG",
        "vehicleType": "Scooter",
        "vehicleName": "Honda Activa",
        "vehicleRcNumber": f"MH-12-F-{suffix[:4]}"
    }, token=t_fem)
    make_req(f"{BASE_URL}/users/profile", "PATCH", {"gender": "Female"}, token=t_fem)
    make_req(f"{BASE_URL}/admin/verifications/{id_fem}/approve", "PATCH", token=admin_token)
    make_req(f"{BASE_URL}/users/online", "PATCH", {"is_online": True, "lat": 18.4635, "lng": 73.8680}, token=t_fem)

    print("[PASS] Seeded verified Male and Female drivers successfully.")

    # 1. Test Female Filter
    s, res_fem = make_req(f"{BASE_URL}/rides/nearby-drivers?lat=18.4624&lng=73.8670&gender=female")
    assert s == 200
    fem_drivers = res_fem.get("drivers", [])
    fem_ids = [d["id"] for d in fem_drivers]
    assert id_fem in fem_ids, "Female driver MUST be in female-filtered results"
    assert id_male not in fem_ids, "Male driver MUST NOT be in female-filtered results"
    for d in fem_drivers:
        assert d.get("gender", "").lower() == "female", f"All results must be female, got {d.get('gender')}"
    print("[PASS] Test 1: Female Only filter returns ONLY female drivers (no male leakage).")

    # 2. Test Male Filter
    s, res_male = make_req(f"{BASE_URL}/rides/nearby-drivers?lat=18.4624&lng=73.8670&gender=male")
    assert s == 200
    male_drivers = res_male.get("drivers", [])
    male_ids = [d["id"] for d in male_drivers]
    assert id_male in male_ids, "Male driver MUST be in male-filtered results"
    assert id_fem not in male_ids, "Female driver MUST NOT be in male-filtered results"
    for d in male_drivers:
        assert d.get("gender", "").lower() == "male", f"All results must be male, got {d.get('gender')}"
    print("[PASS] Test 2: Male Only filter returns ONLY male drivers (no female leakage).")

    # 3. Test Unfiltered (All Drivers)
    s, res_all = make_req(f"{BASE_URL}/rides/nearby-drivers?lat=18.4624&lng=73.8670&gender=all")
    assert s == 200
    all_ids = [d["id"] for d in res_all.get("drivers", [])]
    assert id_male in all_ids, "Male driver must be in unfiltered results"
    assert id_fem in all_ids, "Female driver must be in unfiltered results"
    print("[PASS] Test 3: Unfiltered query returns both male and female drivers.")

    # 4. Custom Ride Request with Female Preference
    t_pass, id_pass = register_and_login(f"pass_{suffix}@campuslift.edu", "Pass@123", "passenger", name="Sneha Passenger", gender="Female")
    s, r1 = make_req(f"{BASE_URL}/rides/request", "POST", {
        "fromLocation": "Main Gate",
        "toLocation": "Library",
        "fromLat": 18.4624,
        "fromLng": 73.8670,
        "toLat": 18.4700,
        "toLng": 73.8750,
        "genderPreference": "Female"
    }, token=t_pass)
    assert s in [200, 201], f"Ride request failed: {s} {r1}"
    ride1_id = r1["ride"]["id"]
    assert r1["ride"]["genderPreference"] == "Female"

    # Female driver checks pending rides
    s, p_fem = make_req(f"{BASE_URL}/rides/pending", "GET", token=t_fem)
    pending_fem_ids = [r["id"] for r in p_fem.get("rides", [])]
    assert ride1_id in pending_fem_ids, f"Female driver MUST see Female-restricted ride request: {pending_fem_ids} vs {ride1_id}"

    # Male driver checks pending rides
    s, p_male = make_req(f"{BASE_URL}/rides/pending", "GET", token=t_male)
    pending_male_ids = [r["id"] for r in p_male.get("rides", [])]
    assert ride1_id not in pending_male_ids, "Male driver MUST NOT see Female-restricted ride request"

    # Male driver attempts to accept female-restricted ride
    s_acc_m, res_acc_m = make_req(f"{BASE_URL}/rides/{ride1_id}/accept", "POST", token=t_male)
    assert s_acc_m == 403, f"Male driver must receive 403 when accepting Female-restricted ride, got {s_acc_m}"

    # Female driver accepts ride
    s_acc_f, res_acc_f = make_req(f"{BASE_URL}/rides/{ride1_id}/accept", "POST", token=t_fem)
    assert s_acc_f == 200, f"Female driver accept failed: {s_acc_f} {res_acc_f}"
    # Complete ride1 so passenger can make another request
    make_req(f"{BASE_URL}/rides/{ride1_id}/start", "POST", token=t_fem)
    make_req(f"{BASE_URL}/rides/{ride1_id}/complete", "POST", token=t_fem)
    print("[PASS] Test 4: Custom ride request with Female preference correctly enforced.")

    # 5. Custom Ride Request with Male Preference
    s, r2 = make_req(f"{BASE_URL}/rides/request", "POST", {
        "fromLocation": "Hostel B",
        "toLocation": "Cafeteria",
        "fromLat": 18.4624,
        "fromLng": 73.8670,
        "toLat": 18.4700,
        "toLng": 73.8750,
        "genderPreference": "Male"
    }, token=t_pass)
    assert s in [200, 201], f"Ride request failed: {s} {r2}"
    ride2_id = r2["ride"]["id"]
    assert r2["ride"]["genderPreference"] == "Male"

    # Male driver checks pending rides
    s, p_male2 = make_req(f"{BASE_URL}/rides/pending", "GET", token=t_male)
    pending_male2_ids = [r["id"] for r in p_male2.get("rides", [])]
    assert ride2_id in pending_male2_ids, "Male driver MUST see Male-restricted ride request"

    # Female driver checks pending rides
    s, p_fem2 = make_req(f"{BASE_URL}/rides/pending", "GET", token=t_fem)
    pending_fem2_ids = [r["id"] for r in p_fem2.get("rides", [])]
    assert ride2_id not in pending_fem2_ids, "Female driver MUST NOT see Male-restricted ride request"

    # Female driver attempts to accept male-restricted ride
    s_acc_f2, res_acc_f2 = make_req(f"{BASE_URL}/rides/{ride2_id}/accept", "POST", token=t_fem)
    assert s_acc_f2 == 403, f"Female driver must receive 403 when accepting Male-restricted ride, got {s_acc_f2}"

    # Male driver accepts ride
    s_acc_m2, res_acc_m2 = make_req(f"{BASE_URL}/rides/{ride2_id}/accept", "POST", token=t_male)
    assert s_acc_m2 == 200, f"Male driver accept failed: {s_acc_m2} {res_acc_m2}"
    make_req(f"{BASE_URL}/rides/{ride2_id}/start", "POST", token=t_male)
    make_req(f"{BASE_URL}/rides/{ride2_id}/complete", "POST", token=t_male)
    print("[PASS] Test 5: Custom ride request with Male preference correctly enforced.")

    print("\n==================================================")
    print("ALL GENDER FILTER TESTS (MALE, FEMALE, UNFILTERED, REQUEST RESTRICTIONS) PASSED 100%!")
    print("==================================================")

if __name__ == "__main__":
    run_tests()
