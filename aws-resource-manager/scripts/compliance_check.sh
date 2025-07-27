#!/bin/bash
# Security Group Compliance Check Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATE=$(date +%Y%m%d_%H%M%S)
COMPLIANCE_DIR="$PROJECT_DIR/compliance"

# Create compliance directory
mkdir -p "$COMPLIANCE_DIR"

echo "📋 Security Group Compliance Check - $(date)"
echo "============================================="

cd "$PROJECT_DIR"

# Generate comprehensive compliance report
echo "Generating compliance report..."
python security_group_remediation.py report --output "$COMPLIANCE_DIR/compliance_report_$DATE.json"

# Check specific compliance requirements
echo "Checking specific compliance rules..."

# Rule 1: No SSH/RDP from internet
python security_group_remediation.py find --ports "22,3389" --output "$COMPLIANCE_DIR/ssh_rdp_violations_$DATE.json"

# Rule 2: No database ports from internet
python security_group_remediation.py find --ports "3306,5432,1433,27017,6379" --output "$COMPLIANCE_DIR/database_violations_$DATE.json"

# Rule 3: No management ports from internet
python security_group_remediation.py find --ports "8080,9000,8443,5601" --output "$COMPLIANCE_DIR/mgmt_violations_$DATE.json"

# Generate summary
echo "Compliance Summary:"
echo "==================="

SSH_RDP_COUNT=$(cat "$COMPLIANCE_DIR/ssh_rdp_violations_$DATE.json" | python -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
DB_COUNT=$(cat "$COMPLIANCE_DIR/database_violations_$DATE.json" | python -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
MGMT_COUNT=$(cat "$COMPLIANCE_DIR/mgmt_violations_$DATE.json" | python -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

echo "SSH/RDP violations: $SSH_RDP_COUNT"
echo "Database violations: $DB_COUNT"
echo "Management violations: $MGMT_COUNT"

TOTAL_VIOLATIONS=$((SSH_RDP_COUNT + DB_COUNT + MGMT_COUNT))

if [ "$TOTAL_VIOLATIONS" -eq 0 ]; then
    echo "✅ COMPLIANT: No security group violations found"
    exit 0
else
    echo "❌ NON-COMPLIANT: $TOTAL_VIOLATIONS total violations found"
    echo "Reports saved in: $COMPLIANCE_DIR/"
    exit 1
fi
