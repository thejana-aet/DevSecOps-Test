package api

import (
	"github.com/gorilla/mux"
	"github.com/devsecops-demo/devsecops-demo/internal/health"
)

// NewRouter creates and configures the HTTP router
func NewRouter() *mux.Router {
	router := mux.NewRouter()

	// Health check endpoints
	router.HandleFunc("/api/health", health.Handler).Methods("GET")
	router.HandleFunc("/health", health.Handler).Methods("GET")
	router.HandleFunc("/health/ready", health.ReadyHandler).Methods("GET")
	router.HandleFunc("/health/live", health.LiveHandler).Methods("GET")

	// Home endpoint
	router.HandleFunc("/", HomeHandler).Methods("GET")

	return router
}
