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

def login(email, password, role="rider"):
    status, data = make_req(f"{BASE_URL}/auth/register", "POST", {
        "name": email.split("@")[0].capitalize(),
        "email": email,
        "password": password,
        "phone": "9876543210",
        "role": role
    })
    if status not in [200, 201]:
        status, data = make_req(f"{BASE_URL}/auth/login", "POST", {
            "email": email,
            "password": password
        })
    d = data.get("data", data)
    token = d.get("token") or d.get("access_token")
    user = d.get("user", {})
    return token, user.get("id")

print("--- Testing Bike Rental Flow & State Machine ---")
unique_suffix = str(uuid.uuid4())[:6]
token_a, id_a = login(f"owner_{unique_suffix}@test.com", "Owner@123", "driver")
token_b, id_b = login(f"renter1_{unique_suffix}@test.com", "Renter@123", "rider")
token_c, id_c = login(f"renter2_{unique_suffix}@test.com", "Renter@123", "rider")

# 1. Post bike
status, post_resp = make_req(f"{BASE_URL}/bikes/post", "POST", {
    "bikeName": "Activa 6G Super",
    "bikeType": "scooter",
    "bikeNumber": "KA01AB1234",
    "pricePerHour": 35.0,
    "location": "North Campus Gate 2",
    "upiId": "owner@upi",
    "paymentMethod": "UPI"
}, token=token_a)
assert status == 201, f"Post bike failed: {status} {post_resp}"
bike = post_resp["bike"]
bike_id = bike["id"]
assert bike["payment_method"] == "UPI"
print(f"[OK] Bike posted: {bike_id} with payment_method: {bike['payment_method']}")

# 2. Check available bikes (from renter B perspective)
status, avail_resp = make_req(f"{BASE_URL}/bikes/available", token=token_b)
assert status == 200, f"Available bikes failed: {status} {avail_resp}"
avail_ids = [b["id"] for b in avail_resp]
assert bike_id in avail_ids, "Posted bike should be in available list"
print(f"[OK] Bike visible in /bikes/available")

# 3. User B requests bike
status, req_b_resp = make_req(f"{BASE_URL}/bikes/{bike_id}/request-rental", "POST", {
    "hours": 2,
    "paymentMethod": "UPI"
}, token=token_b)
assert status == 201, f"Request B failed: {status} {req_b_resp}"
rental_b_id = req_b_resp["rental"]["id"]
print(f"[OK] User B requested rental: {rental_b_id}")

# 4. User C also requests same bike before approval
status, req_c_resp = make_req(f"{BASE_URL}/bikes/{bike_id}/request-rental", "POST", {
    "hours": 3,
    "paymentMethod": "Cash"
}, token=token_c)
assert status == 201, f"Request C failed: {status} {req_c_resp}"
rental_c_id = req_c_resp["rental"]["id"]
print(f"[OK] User C requested rental concurrently: {rental_c_id}")

# 5. Owner A approves User B
status, appr_resp = make_req(f"{BASE_URL}/bikes/rentals/{rental_b_id}/approve", "POST", token=token_a)
assert status == 200, f"Approve B failed: {status} {appr_resp}"
assert appr_resp["status"] == "approved"
print(f"[OK] Owner A approved rental B")

# 6. Verify User C request got auto-cancelled due to double-booking prevention!
status, detail_c = make_req(f"{BASE_URL}/bikes/rentals/{rental_c_id}", token=token_c)
assert detail_c["status"] == "cancelled", f"User C status expected cancelled, got {detail_c['status']}"
print(f"[OK] User C pending rental was correctly auto-cancelled upon B's approval!")

# 7. Check bike is now hidden from /bikes/available
status, avail_resp2 = make_req(f"{BASE_URL}/bikes/available", token=token_b)
avail_ids2 = [b["id"] for b in avail_resp2]
assert bike_id not in avail_ids2, "Approved bike must NOT appear in available list"
print(f"[OK] Approved bike removed from /bikes/available")

# 8. User B confirms payment
status, pay_resp = make_req(f"{BASE_URL}/bikes/rentals/{rental_b_id}/confirm-payment", "POST", {
    "paymentMethod": "UPI",
    "paymentScreenshot": "mock_txn_123"
}, token=token_b)
assert status == 200, f"Payment confirm failed: {status} {pay_resp}"
assert pay_resp["status"] == "payment_done"
print(f"[OK] Payment confirmed -> status: payment_done")

# 9. Owner A confirms vehicle handover -> active
status, handover_resp = make_req(f"{BASE_URL}/bikes/rentals/{rental_b_id}/confirm-received", "POST", token=token_a)
assert status == 200, f"Handover failed: {status} {handover_resp}"
assert handover_resp["status"] == "active"
print(f"[OK] Handover confirmed -> status: active")

# 10. Return bike -> completed
status, return_resp = make_req(f"{BASE_URL}/bikes/rentals/{rental_b_id}/return", "POST", token=token_b)
assert status == 200, f"Return failed: {status} {return_resp}"
assert return_resp["status"] == "completed"
print(f"[OK] Bike returned -> status: completed")

# 11. Check bike is available again
status, avail_resp3 = make_req(f"{BASE_URL}/bikes/available", token=token_b)
avail_ids3 = [b["id"] for b in avail_resp3]
assert bike_id in avail_ids3, "Completed bike must be restored to /bikes/available"
print(f"[OK] Returned bike is back in /bikes/available")

print("\n=== TASK 6 BIKE RENTAL VERIFICATION PASSED 100% ===")
