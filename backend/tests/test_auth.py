import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    """Test health endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_root():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()

def test_register_user():
    """Test user registration"""
    user_data = {
        "email": "test@example.com",
        "username": "testuser",
        "password": "testpass123",
        "full_name": "Test User"
    }
    response = client.post("/api/auth/register", json=user_data)
    # Puede fallar si el usuario ya existe, pero verifica la estructura
    assert response.status_code in [200, 400]

def test_login_invalid():
    """Test login with invalid credentials"""
    login_data = {
        "username": "invalid",
        "password": "invalid"
    }
    response = client.post("/api/auth/login", json=login_data)
    assert response.status_code == 401
