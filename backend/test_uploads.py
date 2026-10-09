import urllib.request
import urllib.error
import json

BASE_URL = "http://127.0.0.1:5000/api"

def make_req(url, method="GET", data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(data).encode("utf-8") if data is not None else None
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

def run_tests():
    print("Testing Profile Picture and Driver Document Upload Flows...")

    # 1. Register or login a test user
    email = "uploadtest_student@campuslift.edu"
    password = "Password123!"
    status, reg_res = make_req(f"{BASE_URL}/auth/register", "POST", {
        "name": "Upload Tester",
        "email": email,
        "password": password,
        "role": "rider"
    })
    
    if status in [200, 201]:
        d = reg_res.get("data", reg_res)
        token = d["token"]
        user_id = d["user"]["id"]
    else:
        status, log_res = make_req(f"{BASE_URL}/auth/login", "POST", {
            "email": email,
            "password": password
        })
        assert status == 200, f"Login failed: {log_res}"
        d = log_res.get("data", log_res)
        token = d["token"]
        user_id = d["user"]["id"]

    # 2. Upload Avatar (Base64)
    tiny_png_b64 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    status, avatar_data = make_req(
        f"{BASE_URL}/users/profile/avatar",
        "POST",
        {"avatar_base64": tiny_png_b64},
        token=token
    )
    assert status == 200, f"Avatar upload failed ({status}): {avatar_data}"
    assert "avatarUrl" in avatar_data, "No avatarUrl in response"
    avatar_url = avatar_data["avatarUrl"]
    print(f"[PASS] Avatar uploaded successfully: {avatar_url}")

    # 3. Retrieve Avatar publicly
    req = urllib.request.Request(f"http://127.0.0.1:5000{avatar_url}")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200, f"Get avatar failed: {resp.status}"
    print("[PASS] Avatar retrieved successfully.")

    # 3b. Test Avatar Removal (DELETE /api/users/profile/avatar)
    status, del_data = make_req(
        f"{BASE_URL}/users/profile/avatar",
        "DELETE",
        token=token
    )
    assert status == 200, f"Avatar delete failed ({status}): {del_data}"
    assert del_data.get("avatar_url") is None, "avatar_url not reset to None"
    print("[PASS] Avatar DELETE endpoint reset avatar_url to None.")

    # Re-upload avatar for subsequent tests
    status, avatar_data = make_req(
        f"{BASE_URL}/users/profile/avatar",
        "POST",
        {"avatar_base64": tiny_png_b64},
        token=token
    )
    assert status == 200, "Re-uploading avatar failed"

    # 4. Upload Driver Verification Documents (License and RC)
    tiny_jpg_b64 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="
    status, doc_data = make_req(
        f"{BASE_URL}/users/license/documents",
        "POST",
        {
            "license_base64": tiny_jpg_b64,
            "rc_base64": tiny_jpg_b64
        },
        token=token
    )
    assert status == 200, f"Document upload failed ({status}): {doc_data}"
    assert doc_data.get("licensePhoto") is not None, "Missing licensePhoto"
    assert doc_data.get("rcPhoto") is not None, "Missing rcPhoto"
    lic_file = doc_data["licensePhoto"]
    rc_file = doc_data["rcPhoto"]
    print(f"[PASS] License document uploaded: {lic_file}")
    print(f"[PASS] RC document uploaded: {rc_file}")

    # 5. Admin Login to retrieve document
    status, admin_log = make_req(f"{BASE_URL}/admin/login", "POST", {
        "username": "admin@campuslift.edu",
        "password": "Admin@123"
    })
    assert status == 200, f"Admin login failed ({status}): {admin_log}"
    admin_token = admin_log["token"]

    # 6. Admin can retrieve document with query param token
    req = urllib.request.Request(f"{BASE_URL}/admin/documents/{lic_file}?token={admin_token}")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200, f"Admin get document failed: {resp.status}"
    print("[PASS] Admin retrieved verification document with token param.")

    # 7. Unauthenticated user cannot retrieve document
    try:
        req = urllib.request.Request(f"{BASE_URL}/admin/documents/{lic_file}")
        with urllib.request.urlopen(req) as resp:
            raise AssertionError("Unauthenticated request should have failed!")
    except urllib.error.HTTPError as e:
        assert e.code in [401, 403], f"Expected 401/403, got {e.code}"
    print("[PASS] Document endpoint blocks unauthenticated requests.")

    # 8. Submit verification info with documents attached
    status, sub_res = make_req(
        f"{BASE_URL}/users/license",
        "PATCH",
        {
            "licenseNumber": "MH12-2024-0012345",
            "licenseType": "Two Wheeler",
            "licenseExpiry": "2030-01-01",
            "vehicleRcNumber": "MH-12-AB-9999",
            "vehicleType": "Bike/Scooter",
            "vehicleName": "Honda Activa 6G",
            "licensePhoto": lic_file,
            "rcPhoto": rc_file
        },
        token=token
    )
    assert status == 200, f"Submit license failed ({status}): {sub_res}"
    user_dict = sub_res["user"]
    assert user_dict["verificationStatus"] == "pending", "Status not pending"
    assert user_dict["licensePhoto"] == lic_file, "License photo not retained"
    assert user_dict["rcPhoto"] == rc_file, "RC photo not retained"
    print("[PASS] Driver verification submitted with document references.")

    # 9. Admin verifications listing includes documents
    status, verifs = make_req(
        f"{BASE_URL}/admin/verifications",
        "GET",
        token=admin_token
    )
    assert status == 200, f"Failed to get verifications ({status}): {verifs}"
    matching = [u for u in verifs if u["id"] == user_id]
    assert len(matching) > 0, "Submitted user not in pending verifications"
    assert matching[0].get("licensePhoto") == lic_file, "Missing licensePhoto in admin verifications"
    print("[PASS] Admin verifications listing includes uploaded documents.")

    print("\nALL PROFILE & DOCUMENT UPLOAD TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_tests()
