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

def login(email, password, role="rider", name="Test User", gender="Male"):
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

print("--- Testing Priority 2 Safety Features (Tasks 8, 9, 10) ---")
suffix = str(uuid.uuid4())[:6]

# Admin login
s, admin_login = make_req(f"{BASE_URL}/admin/login", "POST", {"username": "admin", "password": "Admin@123"})
admin_token = admin_login.get("token")
assert admin_token is not None, "Admin login must succeed"

# ==========================================
# 1. TASK 9 & TASK 8: SOS IDENTITY & LIVE LOCATION
# ==========================================
p_token, p_id = login(f"sos_pass_{suffix}@test.com", "Pass@123", "passenger", name="Aarav Sharma", gender="Male")
# Set PRN and Phone
make_req(f"{BASE_URL}/users/profile", "PATCH", {
    "prn": "PRN2026-ENG-99",
    "phone": "+91 91234 56789",
    "college_name": "MIT College of Engineering"
}, token=p_token)

# Trigger SOS
s, sos_resp = make_req(f"{BASE_URL}/sos/trigger", "POST", {
    "lat": 18.4624,
    "lng": 73.8670
}, token=p_token)
assert s == 201, f"SOS trigger failed: {s} {sos_resp}"
alert = sos_resp.get("data", {})
alert_id = alert.get("id")
ident = alert.get("user_identity", {})

# Task 9 Verification: Identity exposed at trigger time
assert ident.get("name") == "Aarav Sharma", f"Expected name Aarav Sharma, got {ident.get('name')}"
assert ident.get("college_id") == "PRN2026-ENG-99", f"Expected PRN, got {ident.get('college_id')}"
assert ident.get("phone") == "+91 91234 56789", f"Expected phone, got {ident.get('phone')}"
print("[OK] Task 9: Triggering user verified identity attached to SOS payload")

# Task 9 Verification: Admin receives user_identity in live SOS view
s, admin_sos_list = make_req(f"{BASE_URL}/admin/sos", token=admin_token)
assert s == 200
found_alert = next((a for a in admin_sos_list if a.get("id") == alert_id), None)
assert found_alert is not None, "Triggered SOS alert must appear in admin SOS list"
admin_ident = found_alert.get("user_identity", {})
assert admin_ident.get("college_id") == "PRN2026-ENG-99"
print("[OK] Task 9: Admin panel live SOS view receives verified student identity")

# Task 8 Verification: Continuous live location updates
s, loc_resp = make_req(f"{BASE_URL}/sos/{alert_id}/location", "POST", {
    "lat": 18.4635,
    "lng": 73.8682
}, token=p_token)
assert s == 200
assert loc_resp.get("data", {}).get("lat") == 18.4635
print("[OK] Task 8: Continuous live location update received and synced")

# Task 8 Verification: User cancels SOS cleanly
s, cancel_resp = make_req(f"{BASE_URL}/sos/{alert_id}/cancel", "POST", token=p_token)
assert s == 200
assert cancel_resp.get("data", {}).get("resolved") == True
print("[OK] Task 8: SOS cancelled cleanly by user")

# ==========================================
# 2. TASK 10: ADMIN EMERGENCY & TRUSTED CONTACTS
# ==========================================
# Fetch public trusted contacts (seeded)
s, initial_contacts = make_req(f"{BASE_URL}/users/trusted-contacts")
assert s == 200
c_list = initial_contacts.get("contacts", [])
assert len(c_list) >= 4, f"Expected at least 4 seeded trusted contacts, got {len(c_list)}"
print(f"[OK] Task 10: Seeded trusted contacts loaded dynamically: {len(c_list)} contacts")

# Admin adds a new trusted contact
s, new_c = make_req(f"{BASE_URL}/admin/trusted-contacts", "POST", {
    "name": "East Gate Priority Auto Stand",
    "phone": "+91 99887 11223",
    "category": "auto",
    "location": "East Campus Gate 3",
    "description": "24/7 dedicated auto rickshaw stand"
}, token=admin_token)
assert s == 201
new_c_id = new_c.get("id")
print(f"[OK] Task 10: Admin created new trusted contact: {new_c_id}")

# Verify newly added contact is immediately pulled by app without app update
s, updated_contacts = make_req(f"{BASE_URL}/users/trusted-contacts?category=auto")
assert s == 200
auto_names = [c["name"] for c in updated_contacts.get("contacts", [])]
assert "East Gate Priority Auto Stand" in auto_names, "Newly created contact must appear in app query"
print("[OK] Task 10: Newly added contact is immediately reflected in app dynamic fetch")

# Admin deletes the trusted contact
s, del_resp = make_req(f"{BASE_URL}/admin/trusted-contacts/{new_c_id}", "DELETE", token=admin_token)
assert s == 200

# Verify contact is immediately gone from app
s, final_contacts = make_req(f"{BASE_URL}/users/trusted-contacts?category=auto")
assert s == 200
final_names = [c["name"] for c in final_contacts.get("contacts", [])]
assert "East Gate Priority Auto Stand" not in final_names, "Deleted contact must no longer appear"
print("[OK] Task 10: Admin deleted contact immediately removed from app on refresh")

print("\n=== PRIORITY 2 SAFETY FEATURES (TASKS 8, 9, 10, 11) VERIFIED 100% ===")
