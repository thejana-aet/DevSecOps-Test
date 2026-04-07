# DevSecOps Platform

Minimal reference stack: a Go backend with health endpoints, a Helm chart for deploying it to Kubernetes, Terraform to provision an EKS cluster, and helper scripts for AWS setup/cleanup.

## File reference

### Root
- README.md: repository overview and file map.
- backend/: Go API service source and build assets.
- k8s/: Helm chart for deploying the backend service.
- terraform/: Infrastructure-as-code for AWS/EKS.
- scripts/: helper shell scripts for AWS/Terraform/Kubernetes maintenance.

### Backend (Go API)
- backend/go.mod: module path and direct dependencies.
- backend/go.sum: dependency checksums locked for reproducible builds.
- backend/Makefile: shortcuts to build, run, test, and clean the binary.
- backend/Dockerfile: multi-stage build producing a distroless container for the server.
- backend/cmd/server/main.go: application entrypoint, router wiring, and graceful HTTP server shutdown.
- backend/internal/api/router.go: Gorilla Mux router with health and root routes.
- backend/internal/api/home.go: `/` handler returning a simple status payload.
- backend/internal/health/health.go: health, readiness, and liveness HTTP handlers.
- backend/internal/health/health_test.go: unit tests for the health endpoints.

### Kubernetes (Helm chart)
- k8s/Chart.yaml: chart metadata for the backend service.
- k8s/values.yaml: configurable values (image repo/tag, replicas, probes, ingress, service type, optional namespace creation).
- k8s/templates/deployment.yaml: backend deployment template with probes/resources.
- k8s/templates/service.yaml: ClusterIP service template exposing HTTP traffic.
- k8s/templates/ingress.yaml: ALB ingress template routing `/` and `/health` to the service.
- k8s/templates/namespace.yaml: optional namespace creation when `namespace.create` is true.
- k8s/templates/_helpers.tpl: naming and label helpers shared across templates.

Deploy example:
- `helm install backend ./k8s -n app --create-namespace` (override values with `-f my-values.yaml` or `--set key=val` as needed).

### Terraform
- terraform/scripts/bootstrap.sh: bootstraps the S3 bucket/DynamoDB table for Terraform state and writes backend config.
- terraform/environments/shared/versions.tf: pins Terraform and provider versions plus remote state backend stub.
- terraform/environments/shared/variables.tf: shared variables for region, VPC, EKS, and node settings.
- terraform/environments/shared/main.tf: provisions the VPC, EKS cluster, and node group.
- terraform/environments/shared/outputs.tf: exports VPC, EKS, and helper connection details.
- terraform/environments/shared/terraform.tfvars: sample production defaults for the shared environment.

### Utility scripts
- scripts/setup-aws-tools.sh: verifies Terraform and AWS CLI prerequisites.
- scripts/cleanup-terraform-backend.sh: deletes the Terraform backend bucket/table and local state cache.
- scripts/cleanup-k8s-resources.sh: removes load balancers/ingress resources to avoid AWS leftovers before destroy.
