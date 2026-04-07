#!/bin/bash
# Pre-destroy cleanup: Remove Kubernetes resources that create AWS dependencies
# This prevents orphaned AWS resources (ENIs, security groups) that block Terraform destroy

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}==> Cleaning up Kubernetes resources that create AWS dependencies${NC}"
echo ""

# Check if kubectl is configured and cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${BLUE}[INFO] Cluster not accessible (already destroyed or credentials expired)${NC}"
    echo "   Skipping Kubernetes cleanup"
    exit 0
fi

echo -e "${GREEN}[OK] Cluster accessible, proceeding with cleanup${NC}"
echo ""

# 1. Delete all LoadBalancer services (creates ENIs and security groups)
echo -e "${CYAN}==> Deleting LoadBalancer services${NC}"
LOAD_BALANCERS=$(kubectl get svc --all-namespaces -o json | \
    jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace)/\(.metadata.name)"')

if [ -n "$LOAD_BALANCERS" ]; then
    while IFS= read -r svc; do
        NAMESPACE=$(echo "$svc" | cut -d'/' -f1)
        NAME=$(echo "$svc" | cut -d'/' -f2)
        echo "  Deleting $NAMESPACE/$NAME..."
        kubectl delete svc "$NAME" -n "$NAMESPACE" --wait=true --timeout=60s || true
    done <<< "$LOAD_BALANCERS"
    echo -e "  ${GREEN}[OK] LoadBalancer services deleted${NC}"
else
    echo -e "  ${BLUE}[INFO] No LoadBalancer services found${NC}"
fi
echo ""

# 2. Delete Ingress resources (AWS Load Balancer Controller creates ALBs/NLBs)
echo -e "${CYAN}==> Deleting Ingress resources${NC}"
INGRESSES=$(kubectl get ingress --all-namespaces -o json | \
    jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"')

if [ -n "$INGRESSES" ]; then
    while IFS= read -r ing; do
        NAMESPACE=$(echo "$ing" | cut -d'/' -f1)
        NAME=$(echo "$ing" | cut -d'/' -f2)
        echo "  Deleting $NAMESPACE/$NAME..."
        kubectl delete ingress "$NAME" -n "$NAMESPACE" --wait=true --timeout=60s || true
    done <<< "$INGRESSES"
    echo -e "  ${GREEN}[OK] Ingress resources deleted${NC}"
else
    echo -e "  ${BLUE}[INFO] No Ingress resources found${NC}"
fi
echo ""

# 3. Wait for AWS resources to be cleaned up
echo -e "${BLUE}[INFO] Waiting for AWS resources to be cleaned up (30s)${NC}"
sleep 30
echo -e "  ${GREEN}[OK] Cleanup complete${NC}"
echo ""

echo -e "${GREEN}[SUCCESS] Kubernetes cleanup complete${NC}"
