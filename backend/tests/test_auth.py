def test_register_user_success(client):
    response = client.post(
        "/register",
        json={
            "username": "testuser",
            "password": "testpassword",
            "role": "petani",
            "full_name": "Test User",
            "farm_name": "Test Farm",
            "location": "Jakarta"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["message"] == "Register berhasil!"

def test_register_user_duplicate(client):
    # First registration
    client.post(
        "/register",
        json={
            "username": "testuser_dup",
            "password": "testpassword",
            "role": "petani",
            "full_name": "Test User Dup"
        }
    )
    
    # Second registration with same username
    response = client.post(
        "/register",
        json={
            "username": "testuser_dup",
            "password": "testpassword",
            "role": "petani",
            "full_name": "Test User Dup"
        }
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Username sudah dipakai"

def test_login_user_success(client):
    # Setup: Register first
    client.post(
        "/register",
        json={
            "username": "logintest",
            "password": "loginpassword",
            "role": "umkm",
            "full_name": "UMKM Test"
        }
    )
    
    # Test Login
    response = client.post(
        "/login",
        json={
            "username": "logintest",
            "password": "loginpassword"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "token" in data
    assert data["role"] == "umkm"

def test_login_user_wrong_password(client):
    # Setup: Register first
    client.post(
        "/register",
        json={
            "username": "wrongpw",
            "password": "correctpassword",
            "role": "petani",
            "full_name": "Petani Test"
        }
    )
    
    # Test Login with wrong pw
    response = client.post(
        "/login",
        json={
            "username": "wrongpw",
            "password": "wrongpassword"
        }
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Login gagal, periksa kredensial"
