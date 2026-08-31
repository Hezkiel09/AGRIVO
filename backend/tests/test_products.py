import pytest
import io

@pytest.fixture(scope="function")
def auth_headers(client):
    """Fixture to get an auth token by registering and logging in a user."""
    # Register
    client.post(
        "/register",
        json={
            "username": "petanitest",
            "password": "testpassword",
            "role": "petani",
            "full_name": "Petani Test Product"
        }
    )
    # Login
    response = client.post(
        "/login",
        json={
            "username": "petanitest",
            "password": "testpassword"
        }
    )
    token = response.json()["token"]
    return {"Authorization": f"Bearer {token}"}

def test_create_product(client, auth_headers):
    # Dummy file to simulate image upload
    file_content = b"dummy image data"
    file = io.BytesIO(file_content)
    file.name = "test_image.jpg"

    response = client.post(
        "/api/products",
        headers=auth_headers,
        data={
            "name": "Tomat Test",
            "slug": "tomat-test",
            "price": "10000",
            "grade": "Grade A",
            "unit": "kg",
            "stock": "50",
            "category": "Sayuran",
            "description": "Tomat merah manis",
            "sales_mode": "market"
        },
        files={"image": ("test_image.jpg", file, "image/jpeg")}
    )
    
    if response.status_code != 200:
        print(response.json())
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["data"]["name"] == "Tomat Test"
    
def test_get_products(client):
    # Public endpoint to get all products
    response = client.get("/api/products")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert isinstance(data["data"], list)

def test_unauthorized_create_product(client):
    # Missing auth headers
    file_content = b"dummy image data"
    file = io.BytesIO(file_content)
    file.name = "test_image.jpg"

    response = client.post(
        "/api/products",
        data={
            "name": "Tomat Unauthorized",
            "price": "10000",
            "category": "Sayuran"
        },
        files={"image": ("test_image.jpg", file, "image/jpeg")}
    )
    
    assert response.status_code == 401
    assert response.json()["detail"] == "Not authenticated"
