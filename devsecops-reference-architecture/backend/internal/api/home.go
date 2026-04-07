package api

import (
	"encoding/json"
	"net/http"
	"time"
	"database/sql"
	// "fmt"
	// "os/exec"

	//_ "github.com/dgrijalva/jwt-go"  //import for go mod, not used in this file
)

// HomeResponse is returned by the root handler.
type HomeResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
}

// HomeHandler returns a simple running status.
func HomeHandler(w http.ResponseWriter, r *http.Request) {
	resp := HomeResponse{
		Status:    "app is running",
		Timestamp: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(resp)
}

var db *sql.DB

// INTENTIONAL FLAW 1 — SQL Injection
// Semgrep rule: go.lang.security.audit.sqli

// func GetPaymentHandler(w http.ResponseWriter, r *http.Request) {
//     userID := r.URL.Query().Get("id")

//     query := "SELECT * FROM payments WHERE user_id = " + userID
//     rows, err := db.Query(query)
//     if err != nil {
//         http.Error(w, err.Error(), http.StatusInternalServerError)
//         return
//     }
//     defer rows.Close()
//     fmt.Fprintln(w, "payment data:", rows)
// }

// func GetPaymentHandler(w http.ResponseWriter, r *http.Request) {
//     userID := r.URL.Query().Get("id")
//     query := "SELECT * FROM payments WHERE user_id = $1"
//     rows, err := db.QueryRow(query, userID)
//     ...
// }


// INTENTIONAL FLAW 2 — Command Injection
// Semgrep rule: go.lang.security.audit.dangerous-exec-cmd

// func GenerateReportHandler(w http.ResponseWriter, r *http.Request) {
//     reportName := r.URL.Query().Get("name")

//     cmd := exec.Command("sh", "-c", "generate_report "+reportName)
//     out, err := cmd.Output()
//     if err != nil {
//         http.Error(w, err.Error(), http.StatusInternalServerError)
//         return
//     }
//     fmt.Fprintln(w, string(out))
// }

// FIXED VERSION 
// func GenerateReportHandler(w http.ResponseWriter, r *http.Request) {
//     reportName := r.URL.Query().Get("name")
//     cmd := exec.Command("generate_report", reportName) // args separated
//     ...
// }
// test

func getAWSConfig() {
    awsAccessKey := "AKIAVVMIL4TK5GCQFUCI"
    awsSecretKey := "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"
    awsRegion    := "us-east-2"

    _ = awsAccessKey
    _ = awsSecretKey
    _ = awsRegion
}
