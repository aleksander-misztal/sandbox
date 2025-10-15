"""
Simple smoke tests for FastAPI endpoints.
Run with: pytest test_main.py -v
"""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_endpoint():
    """Test /health returns 200 and correct status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


def test_root_endpoint():
    """Test / returns API documentation."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "endpoints" in data
    assert "pod_name" in data


def test_stress_endpoint_default():
    """Test /stress with default parameters."""
    response = client.get("/stress")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "completed"
    assert "duration_seconds" in data
    assert "pod_name" in data
    assert data["duration_seconds"] >= 10  # Default duration


def test_stress_endpoint_custom_duration():
    """Test /stress with custom duration."""
    response = client.get("/stress?duration=2")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "completed"
    assert data["duration_seconds"] >= 2
    assert data["duration_seconds"] < 3


def test_stress_endpoint_max_duration():
    """Test /stress respects max duration limit (60s)."""
    response = client.get("/stress?duration=100")  # Request 100s
    assert response.status_code == 422  # Validation error
    data = response.json()
    assert "detail" in data


def test_stress_endpoint_validation():
    """Test /stress validates duration parameter."""
    # Test minimum
    response = client.get("/stress?duration=0")
    assert response.status_code == 422

    # Test negative
    response = client.get("/stress?duration=-5")
    assert response.status_code == 422
