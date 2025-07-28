#!/bin/bash
# Daily Security Group Check Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATE=$(date +%Y%m%d)
REPORT_DIR="$PROJECT_DIR/reports"

# Create reports directory if it doesn't exist
mkdir -p "$REPORT_DIR"

echo "🔍 Daily Security Group Audit - $(date)"
echo "========================================"

# Check for open security groups
echo "Checking for open security groups..."
cd "$PROJECT_DIR"

# Generate report
python ../automation/security_group_remediation.py report --output "$REPORT_DIR/security_report_$DATE.json"

# Find critical open security groups
python ../automation/security_group_remediation.py find --ports "22,3389,1433,3306" --output "$REPORT_DIR/critical_open_sgs_$DATE.json"

# Check if critical issues were found
if [ -s "$REPORT_DIR/critical_open_sgs_$DATE.json" ]; then
    CRITICAL_COUNT=$(cat "$REPORT_DIR/critical_open_sgs_$DATE.json" | python -c "import sys, json; print(len(json.load(sys.stdin)))")
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo "⚠️  WARNING: $CRITICAL_COUNT security groups have critical open ports!"
        echo "   Report saved to: $REPORT_DIR/critical_open_sgs_$DATE.json"
        echo "   Full report: $REPORT_DIR/security_report_$DATE.json"
        
        # Uncomment to send alerts (requires setup)
        # send_alert "Critical security groups found: $CRITICAL_COUNT"
        
        exit 1
    fi
fi

echo "✅ No critical security group issues found"
echo "   Full report: $REPORT_DIR/security_report_$DATE.json"
