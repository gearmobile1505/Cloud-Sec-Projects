#!/bin/bash
# Emergency Security Group Remediation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚨 EMERGENCY SECURITY GROUP REMEDIATION"
echo "======================================="

# Confirmation prompt
read -p "This will modify security groups! Are you sure? (type 'EMERGENCY' to confirm): " -r
if [[ $REPLY != "EMERGENCY" ]]; then
    echo "Remediation cancelled"
    exit 0
fi

cd "$PROJECT_DIR"

# Step 1: Find and report current state
echo "Step 1: Assessing current state..."
python security_group_remediation.py find --ports "22,3389" --output "/tmp/emergency_open_sgs.json"

OPEN_COUNT=$(cat /tmp/emergency_open_sgs.json | python -c "import sys, json; print(len(json.load(sys.stdin)))")
echo "Found $OPEN_COUNT security groups with critical open ports"

if [ "$OPEN_COUNT" -eq 0 ]; then
    echo "✅ No critical security groups found. Exiting."
    exit 0
fi

# Step 2: Show what will be changed (dry run)
echo "Step 2: Showing planned changes (dry run)..."
python security_group_remediation.py bulk-remediate --ports "22,3389" --cidrs "10.0.0.0/8" --dry-run

# Step 3: Final confirmation
echo ""
read -p "Proceed with emergency remediation? (type 'YES' to confirm): " -r
if [[ $REPLY != "YES" ]]; then
    echo "Emergency remediation cancelled"
    exit 0
fi

# Step 4: Execute remediation
echo "Step 3: Executing emergency remediation..."
python security_group_remediation.py bulk-remediate --ports "22,3389" --cidrs "10.0.0.0/8"

echo "🚨 Emergency remediation completed!"
echo "⚠️  Remember to update these rules with proper CIDRs for your environment"
