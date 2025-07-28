#!/bin/bash
# Automated CIS Benchmark Compliance Checker
# Runs CIS compliance checks and integrates with AWS security services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Configuration
AWS_PROFILE=""
AWS_REGION="us-east-1"
OUTPUT_DIR="./reports"
S3_BUCKET=""
SNS_TOPIC=""
CONTROL_IDS=""
INTEGRATION_MODE="standalone"  # standalone, security-hub, config
DRY_RUN=false

# Usage function
usage() {
    cat << EOF
Automated CIS Benchmark Compliance Checker

Usage: $0 [OPTIONS]

OPTIONS:
    --profile PROFILE       AWS profile to use
    --region REGION         AWS region (default: us-east-1)
    --output-dir DIR        Output directory for reports (default: ./reports)
    --s3-bucket BUCKET      S3 bucket to upload reports
    --sns-topic TOPIC       SNS topic for notifications
    --controls CONTROLS     Comma-separated list of control IDs
    --integration MODE      Integration mode: standalone, security-hub, config
    --dry-run              Show what would be checked without running
    --help                 Show this help message

EXAMPLES:
    # Basic compliance check
    $0

    # Check specific controls
    $0 --controls "1.3,1.12,3.1,5.2"

    # Use different AWS profile and region
    $0 --profile production --region us-west-2

    # Upload reports to S3 and send notifications
    $0 --s3-bucket my-compliance-bucket --sns-topic arn:aws:sns:us-east-1:123456789:compliance-alerts

    # Integration with AWS Security Hub
    $0 --integration security-hub

    # Dry run to see what would be checked
    $0 --dry-run

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --s3-bucket)
            S3_BUCKET="$2"
            shift 2
            ;;
        --sns-topic)
            SNS_TOPIC="$2"
            shift 2
            ;;
        --controls)
            CONTROL_IDS="$2"
            shift 2
            ;;
        --integration)
            INTEGRATION_MODE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is required but not installed"
        exit 1
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed"
        exit 1
    fi
    
    # Check Python dependencies
    if ! python3 -c "import boto3" 2>/dev/null; then
        print_error "boto3 is required. Install with: pip install boto3"
        exit 1
    fi
    
    print_status "All dependencies satisfied"
}

# Validate AWS credentials
validate_aws_credentials() {
    print_info "Validating AWS credentials..."
    
    local aws_cmd="aws"
    if [[ -n "$AWS_PROFILE" ]]; then
        aws_cmd="aws --profile $AWS_PROFILE"
    fi
    
    # Test AWS credentials
    if ! $aws_cmd sts get-caller-identity --region "$AWS_REGION" &>/dev/null; then
        print_error "AWS credentials validation failed"
        print_error "Please configure AWS credentials using 'aws configure' or set environment variables"
        exit 1
    fi
    
    local account_id
    account_id=$($aws_cmd sts get-caller-identity --query Account --output text --region "$AWS_REGION")
    print_status "AWS credentials validated for account: $account_id"
}

# Setup output directory
setup_output_dir() {
    print_info "Setting up output directory: $OUTPUT_DIR"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY RUN] Would create directory: $OUTPUT_DIR"
        return
    fi
    
    mkdir -p "$OUTPUT_DIR"
    print_status "Output directory ready: $OUTPUT_DIR"
}

# Run CIS compliance checks
run_compliance_checks() {
    print_info "Running CIS compliance checks..."
    
    local timestamp
    timestamp=$(date -u +"%Y%m%d_%H%M%S")
    local report_file="$OUTPUT_DIR/cis_compliance_report_${timestamp}.json"
    local summary_file="$OUTPUT_DIR/cis_compliance_summary_${timestamp}.txt"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY RUN] Would run compliance checks with the following parameters:"
        print_info "  - Profile: ${AWS_PROFILE:-default}"
        print_info "  - Region: $AWS_REGION"
        print_info "  - Controls: ${CONTROL_IDS:-all implemented controls}"
        print_info "  - Report file: $report_file"
        print_info "  - Summary file: $summary_file"
        return
    fi
    
    # Build Python command - pass global args before subcommand, subcommand args after
    local python_cmd="python3 $PROJECT_DIR/cis_checker.py"
    
    if [[ -n "$AWS_PROFILE" ]]; then
        python_cmd="$python_cmd --profile $AWS_PROFILE"
    fi
    
    python_cmd="$python_cmd --region $AWS_REGION check"
    
    if [[ -n "$CONTROL_IDS" ]]; then
        python_cmd="$python_cmd --controls $CONTROL_IDS"
    fi
    
    python_cmd="$python_cmd --output $report_file --format json"
    
    print_info "Executing: $python_cmd"
    
    if $python_cmd; then
        print_status "Compliance checks completed successfully"
        
        # Generate summary report
        if command -v jq &> /dev/null; then
            print_info "Generating summary report..."
            {
                echo "==========================================="
                echo "CIS Benchmark Compliance Summary"
                echo "==========================================="
                echo "Timestamp: $(date -u)"
                echo "Account: $(jq -r '.report_metadata.account_id' "$report_file")"
                echo "Region: $(jq -r '.report_metadata.region' "$report_file")"
                echo ""
                echo "COMPLIANCE SUMMARY:"
                echo "  Compliant: $(jq -r '.summary.compliant' "$report_file")"
                echo "  Non-Compliant: $(jq -r '.summary.non_compliant' "$report_file")"
                echo "  Not Applicable: $(jq -r '.summary.not_applicable' "$report_file")"
                echo "  Insufficient Data: $(jq -r '.summary.insufficient_data' "$report_file")"
                echo ""
                echo "NON-COMPLIANT CONTROLS:"
                jq -r '.results[] | select(.status == "NON_COMPLIANT") | "  - \(.control_id): \(.reason)"' "$report_file"
                echo ""
                echo "==========================================="
            } > "$summary_file"
            
            print_status "Summary report generated: $summary_file"
        fi
        
        # Display quick summary
        print_info "Quick Summary:"
        if command -v jq &> /dev/null; then
            local compliant non_compliant
            compliant=$(jq -r '.summary.compliant' "$report_file")
            non_compliant=$(jq -r '.summary.non_compliant' "$report_file")
            
            print_status "Compliant controls: $compliant"
            if [[ "$non_compliant" -gt 0 ]]; then
                print_warning "Non-compliant controls: $non_compliant"
            else
                print_status "Non-compliant controls: $non_compliant"
            fi
        fi
        
    else
        print_error "Compliance checks failed"
        exit 1
    fi
}

# Upload reports to S3
upload_to_s3() {
    if [[ -z "$S3_BUCKET" ]]; then
        return
    fi
    
    print_info "Uploading reports to S3 bucket: $S3_BUCKET"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY RUN] Would upload reports to s3://$S3_BUCKET/"
        return
    fi
    
    local aws_cmd="aws"
    if [[ -n "$AWS_PROFILE" ]]; then
        aws_cmd="aws --profile $AWS_PROFILE"
    fi
    
    # Upload all reports from output directory
    if $aws_cmd s3 sync "$OUTPUT_DIR" "s3://$S3_BUCKET/cis-compliance-reports/" --region "$AWS_REGION"; then
        print_status "Reports uploaded to S3 successfully"
    else
        print_error "Failed to upload reports to S3"
    fi
}

# Send SNS notification
send_notification() {
    if [[ -z "$SNS_TOPIC" ]]; then
        return
    fi
    
    print_info "Sending notification to SNS topic: $SNS_TOPIC"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY RUN] Would send notification to SNS topic: $SNS_TOPIC"
        return
    fi
    
    local aws_cmd="aws"
    if [[ -n "$AWS_PROFILE" ]]; then
        aws_cmd="aws --profile $AWS_PROFILE"
    fi
    
    # Find the latest report
    local latest_report
    latest_report=$(find "$OUTPUT_DIR" -name "cis_compliance_report_*.json" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -z "$latest_report" ]]; then
        print_warning "No report found to include in notification"
        return
    fi
    
    # Extract summary for notification
    local account_id region compliant non_compliant
    if command -v jq &> /dev/null; then
        account_id=$(jq -r '.report_metadata.account_id' "$latest_report")
        region=$(jq -r '.report_metadata.region' "$latest_report")
        compliant=$(jq -r '.summary.compliant' "$latest_report")
        non_compliant=$(jq -r '.summary.non_compliant' "$latest_report")
        
        local message
        message="CIS Benchmark Compliance Report
        
Account: $account_id
Region: $region
Timestamp: $(date -u)

Summary:
- Compliant: $compliant
- Non-Compliant: $non_compliant

$(if [[ "$non_compliant" -gt 0 ]]; then
    echo "Non-compliant controls:"
    jq -r '.results[] | select(.status == "NON_COMPLIANT") | "- \(.control_id): \(.reason)"' "$latest_report"
fi)

Full report available in S3: s3://$S3_BUCKET/cis-compliance-reports/"
        
        local subject="CIS Compliance Report - $account_id"
        if [[ "$non_compliant" -gt 0 ]]; then
            subject="🔴 CIS Compliance Issues Found - $account_id"
        else
            subject="✅ CIS Compliance Check Passed - $account_id"
        fi
        
        if $aws_cmd sns publish \
            --topic-arn "$SNS_TOPIC" \
            --subject "$subject" \
            --message "$message" \
            --region "$AWS_REGION"; then
            print_status "Notification sent successfully"
        else
            print_error "Failed to send notification"
        fi
    fi
}

# Integration with AWS Security Hub
integrate_security_hub() {
    if [[ "$INTEGRATION_MODE" != "security-hub" ]]; then
        return
    fi
    
    print_info "Integrating with AWS Security Hub..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY RUN] Would integrate findings with AWS Security Hub"
        return
    fi
    
    # TODO: Implement Security Hub integration
    # This would involve:
    # 1. Converting CIS compliance results to Security Hub finding format
    # 2. Submitting findings using batch-import-findings API
    # 3. Managing finding lifecycle (create, update, resolve)
    
    print_warning "Security Hub integration not yet implemented"
}

# Integration with AWS Config
integrate_config() {
    if [[ "$INTEGRATION_MODE" != "config" ]]; then
        return
    fi
    
    print_info "Integrating with AWS Config..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY RUN] Would integrate with AWS Config rules"
        return
    fi
    
    # TODO: Implement Config integration
    # This would involve:
    # 1. Creating/updating Config rules for CIS controls
    # 2. Triggering evaluations
    # 3. Retrieving compliance status from Config
    
    print_warning "AWS Config integration not yet implemented"
}

# Main execution
main() {
    print_info "Starting CIS Benchmark Compliance Check"
    print_info "========================================"
    
    # Pre-flight checks
    check_dependencies
    validate_aws_credentials
    setup_output_dir
    
    # Run compliance checks
    run_compliance_checks
    
    # Upload and notify
    upload_to_s3
    send_notification
    
    # Integrations
    integrate_security_hub
    integrate_config
    
    print_status "CIS compliance check completed successfully"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info ""
        print_info "This was a dry run. No actual checks were performed."
        print_info "Remove --dry-run flag to execute the compliance checks."
    fi
}

# Run main function
main "$@"
