#!/bin/bash
# Kubernetes CIS Testing Deployment Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/k8s-manifests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Please install kubectl and configure access to your cluster."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        error "Unable to connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    log "kubectl is configured and cluster is accessible"
}

# Function to deploy insecure workloads
deploy_insecure_workloads() {
    log "Deploying insecure workloads with CIS violations..."
    
    if [ -f "${MANIFESTS_DIR}/insecure-workloads.yaml" ]; then
        kubectl apply -f "${MANIFESTS_DIR}/insecure-workloads.yaml"
        log "Insecure workloads deployed"
    else
        error "insecure-workloads.yaml not found"
        return 1
    fi
}

# Function to deploy insecure RBAC
deploy_insecure_rbac() {
    log "Deploying insecure RBAC configurations..."
    
    if [ -f "${MANIFESTS_DIR}/insecure-rbac.yaml" ]; then
        kubectl apply -f "${MANIFESTS_DIR}/insecure-rbac.yaml"
        log "Insecure RBAC configurations deployed"
    else
        error "insecure-rbac.yaml not found"
        return 1
    fi
}

# Function to deploy namespaces without network policies
deploy_unprotected_namespaces() {
    log "Deploying namespaces without network policies..."
    
    if [ -f "${MANIFESTS_DIR}/no-network-policies.yaml" ]; then
        kubectl apply -f "${MANIFESTS_DIR}/no-network-policies.yaml"
        log "Unprotected namespaces deployed"
    else
        error "no-network-policies.yaml not found"
        return 1
    fi
}

# Function to run CIS checks
run_cis_checks() {
    log "Running Kubernetes CIS compliance checks..."
    
    if [ -f "${SCRIPT_DIR}/../scripts/k8s_cis_checker.py" ]; then
        cd "${SCRIPT_DIR}/../scripts"
        
        info "Running all Kubernetes CIS checks..."
        python3 k8s_cis_checker.py check --format text
        
        info "Generating JSON report..."
        python3 k8s_cis_checker.py check --format json --output ../reports/k8s-cis-report.json
        
        log "CIS checks completed. Report saved to ../reports/k8s-cis-report.json"
    else
        error "k8s_cis_checker.py not found"
        return 1
    fi
}

# Function to run unified checker
run_unified_checks() {
    log "Running unified CIS checks for Kubernetes..."
    
    if [ -f "${SCRIPT_DIR}/../scripts/unified_cis_checker.py" ]; then
        cd "${SCRIPT_DIR}/../scripts"
        
        info "Running unified Kubernetes CIS checks..."
        python3 unified_cis_checker.py k8s check --format text
        
        info "Generating JSON report via unified checker..."
        python3 unified_cis_checker.py k8s check --format json --output ../reports/unified-k8s-cis-report.json
        
        log "Unified CIS checks completed"
    else
        error "unified_cis_checker.py not found"
        return 1
    fi
}

# Function to show cluster status
show_cluster_status() {
    log "Current cluster status:"
    
    info "Cluster info:"
    kubectl cluster-info
    
    info "Nodes:"
    kubectl get nodes
    
    info "Namespaces:"
    kubectl get namespaces
    
    info "Pods in default namespace:"
    kubectl get pods -n default
    
    info "RBAC - ClusterRoles with excessive permissions:"
    kubectl get clusterroles | grep -E "(overly-permissive|wildcard|excessive)" || true
    
    info "Pods with security issues:"
    kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.spec.securityContext}{"\n"}{end}' | grep -v "null" || true
}

# Function to cleanup test resources
cleanup() {
    log "Cleaning up test resources..."
    
    warn "This will delete all test resources created by this script"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Deleting test resources..."
        
        kubectl delete -f "${MANIFESTS_DIR}/insecure-workloads.yaml" --ignore-not-found=true
        kubectl delete -f "${MANIFESTS_DIR}/insecure-rbac.yaml" --ignore-not-found=true
        kubectl delete -f "${MANIFESTS_DIR}/no-network-policies.yaml" --ignore-not-found=true
        
        log "Cleanup completed"
    else
        info "Cleanup cancelled"
    fi
}

# Main function
main() {
    case "${1:-}" in
        "deploy")
            check_kubectl
            deploy_insecure_workloads
            deploy_insecure_rbac
            deploy_unprotected_namespaces
            show_cluster_status
            ;;
        "check")
            check_kubectl
            run_cis_checks
            ;;
        "unified-check")
            check_kubectl
            run_unified_checks
            ;;
        "status")
            check_kubectl
            show_cluster_status
            ;;
        "cleanup")
            check_kubectl
            cleanup
            ;;
        "test")
            check_kubectl
            deploy_insecure_workloads
            deploy_insecure_rbac
            deploy_unprotected_namespaces
            sleep 5
            run_cis_checks
            ;;
        *)
            echo "Kubernetes CIS Testing Deployment Script"
            echo ""
            echo "Usage: $0 {deploy|check|unified-check|status|cleanup|test}"
            echo ""
            echo "Commands:"
            echo "  deploy        - Deploy insecure Kubernetes resources for testing"
            echo "  check         - Run Kubernetes CIS compliance checks"
            echo "  unified-check - Run CIS checks using unified checker"
            echo "  status        - Show current cluster status"
            echo "  cleanup       - Remove all test resources"
            echo "  test          - Deploy resources and run checks"
            echo ""
            echo "Examples:"
            echo "  $0 deploy     # Deploy test resources"
            echo "  $0 check      # Run CIS compliance checks"
            echo "  $0 test       # Full test cycle"
            echo "  $0 cleanup    # Clean up test resources"
            exit 1
            ;;
    esac
}

# Create reports directory if it doesn't exist
mkdir -p "${SCRIPT_DIR}/../reports"

# Run main function with all arguments
main "$@"
