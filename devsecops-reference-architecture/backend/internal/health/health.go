package health

import (
	"encoding/json"
	"net/http"
	"time"
)

// HealthResponse represents the health check response
type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Service   string    `json:"service"`
}

// Handler handles health check requests
// GET /health - Basic health check
func Handler(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Status:    "ok",
		Timestamp: time.Now(),
		Service:   "devsecops-demo-backend",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// ReadyHandler handles readiness checks for Kubernetes
// GET /health/ready - Readiness probe
func ReadyHandler(w http.ResponseWriter, r *http.Request) {
	// In a real app, check dependencies (DB, cache, etc.)
	response := HealthResponse{
		Status:    "ready",
		Timestamp: time.Now(),
		Service:   "devsecops-demo-backend",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// LiveHandler handles liveness checks for Kubernetes
// GET /health/live - Liveness probe
func LiveHandler(w http.ResponseWriter, r *http.Request) {
	// In a real app, check if the app is deadlocked
	response := HealthResponse{
		Status:    "alive",
		Timestamp: time.Now(),
		Service:   "devsecops-demo-backend",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}
