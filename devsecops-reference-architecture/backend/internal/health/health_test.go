package health

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestHealthHandler tests the basic health endpoint
func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest("GET", "/health", nil)
	w := httptest.NewRecorder()

	Handler(w, req)

	// Check status code
	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	// Check content type
	contentType := w.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", contentType)
	}

	// Parse response
	var response HealthResponse
	err := json.NewDecoder(w.Body).Decode(&response)
	if err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	// Check response fields
	if response.Status != "ok" {
		t.Errorf("expected status 'ok', got '%s'", response.Status)
	}

	if response.Service != "devsecops-demo-backend" {
		t.Errorf("expected service 'devsecops-demo-backend', got '%s'", response.Service)
	}
}

// TestReadyHandler tests the readiness endpoint
func TestReadyHandler(t *testing.T) {
	req := httptest.NewRequest("GET", "/health/ready", nil)
	w := httptest.NewRecorder()

	ReadyHandler(w, req)

	// Check status code
	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	// Parse response
	var response HealthResponse
	err := json.NewDecoder(w.Body).Decode(&response)
	if err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	// Check status field
	if response.Status != "ready" {
		t.Errorf("expected status 'ready', got '%s'", response.Status)
	}
}

// TestLiveHandler tests the liveness endpoint
func TestLiveHandler(t *testing.T) {
	req := httptest.NewRequest("GET", "/health/live", nil)
	w := httptest.NewRecorder()

	LiveHandler(w, req)

	// Check status code
	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	// Parse response
	var response HealthResponse
	err := json.NewDecoder(w.Body).Decode(&response)
	if err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	// Check status field
	if response.Status != "alive" {
		t.Errorf("expected status 'alive', got '%s'", response.Status)
	}
}
