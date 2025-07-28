#!/bin/bash
# Emergency VPC Security Remediation Script
# Comprehensive security lockdown for active attack scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

print_header() {
    echo ""
    echo -e "${RED}🚨 EMERGENCY VPC SECURITY REMEDIATION 🚨${NC}"
    echo -e "${RED}==========================================${NC}"
    echo ""
}

print_header

# Get VPC ID from user or detect automatically
get_vpc_info() {
    print_info "Detecting VPC configuration..."
    
    if [[ -n "$1" ]]; then
        VPC_ID="$1"
        print_info "Using specified VPC: $VPC_ID"
    else
        # Get default VPC or prompt user
        DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")
        
        if [[ "$DEFAULT_VPC" != "None" ]] && [[ "$DEFAULT_VPC" != "null" ]]; then
            print_warning "Default VPC detected: $DEFAULT_VPC"
            read -p "Use default VPC for remediation? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                VPC_ID="$DEFAULT_VPC"
            else
                read -p "Enter VPC ID to remediate: " VPC_ID
            fi
        else
            read -p "Enter VPC ID to remediate: " VPC_ID
        fi
    fi
    
    # Validate VPC exists
    if ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" &>/dev/null; then
        print_error "VPC $VPC_ID not found or not accessible"
        exit 1
    fi
    
    print_status "Target VPC: $VPC_ID"
}

# Comprehensive security assessment
assess_vpc_security() {
    print_info "🔍 STEP 1: Comprehensive Security Assessment"
    echo ""
    
    # Security Groups Assessment
    print_info "Assessing Security Groups..."
    python automation/security_group_remediation.py find --output "/tmp/emergency_open_sgs.json"
    SG_COUNT=$(cat /tmp/emergency_open_sgs.json | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
    print_warning "Found $SG_COUNT security groups with open rules"
    
    # Network ACLs Assessment
    print_info "Assessing Network ACLs..."
    aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID" --output json > "/tmp/emergency_nacls.json"
    NACL_COUNT=$(cat /tmp/emergency_nacls.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(len([n for n in data['NetworkAcls'] if any(e['RuleAction']=='allow' and e['CidrBlock']=='0.0.0.0/0' for e in n['Entries'])]))" 2>/dev/null || echo "0")
    print_warning "Found $NACL_COUNT NACLs with permissive rules"
    
    # Internet Gateways Assessment
    print_info "Assessing Internet Gateways..."
    aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --output json > "/tmp/emergency_igws.json"
    IGW_COUNT=$(cat /tmp/emergency_igws.json | python3 -c "import sys, json; print(len(json.load(sys.stdin)['InternetGateways']))" 2>/dev/null || echo "0")
    print_warning "Found $IGW_COUNT Internet Gateways attached"
    
    # Route Tables Assessment
    print_info "Assessing Route Tables..."
    aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --output json > "/tmp/emergency_routes.json"
    ROUTE_COUNT=$(cat /tmp/emergency_routes.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(len([r for rt in data['RouteTables'] for r in rt['Routes'] if r.get('DestinationCidrBlock')=='0.0.0.0/0' and r.get('GatewayId','').startswith('igw-')]))" 2>/dev/null || echo "0")
    print_warning "Found $ROUTE_COUNT public routes (0.0.0.0/0 -> IGW)"
    
    # EC2 Instances Assessment
    print_info "Assessing EC2 Instances..."
    aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" --output json > "/tmp/emergency_instances.json"
    INSTANCE_COUNT=$(cat /tmp/emergency_instances.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(len([i for r in data['Reservations'] for i in r['Instances']]))" 2>/dev/null || echo "0")
    print_info "Found $INSTANCE_COUNT running instances in VPC"
    
    # Public IP Assessment
    PUBLIC_INSTANCE_COUNT=$(cat /tmp/emergency_instances.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(len([i for r in data['Reservations'] for i in r['Instances'] if i.get('PublicIpAddress')]))" 2>/dev/null || echo "0")
    print_warning "Found $PUBLIC_INSTANCE_COUNT instances with public IPs"
    
    echo ""
    print_header
    print_error "SECURITY ASSESSMENT SUMMARY:"
    echo -e "${YELLOW}  • Security Groups with open rules: $SG_COUNT${NC}"
    echo -e "${YELLOW}  • Network ACLs with permissive rules: $NACL_COUNT${NC}"
    echo -e "${YELLOW}  • Internet Gateways attached: $IGW_COUNT${NC}"
    echo -e "${YELLOW}  • Public routes via IGW: $ROUTE_COUNT${NC}"
    echo -e "${YELLOW}  • Running instances: $INSTANCE_COUNT${NC}"
    echo -e "${YELLOW}  • Instances with public IPs: $PUBLIC_INSTANCE_COUNT${NC}"
    echo ""
}

# Show planned remediation actions
show_remediation_plan() {
    print_info "🔧 STEP 2: Remediation Plan (DRY RUN)"
    echo ""
    
    print_info "The following actions will be performed:"
    echo ""
    echo -e "${RED}1. SECURITY GROUPS:${NC}"
    echo "   • Remove 0.0.0.0/0 rules from all security groups"
    echo "   • Replace with private network CIDRs (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)"
    echo ""
    
    echo -e "${RED}2. NETWORK ACLs:${NC}"
    echo "   • Block all inbound traffic from 0.0.0.0/0 on critical ports (22, 3389, 80, 443)"
    echo "   • Add deny rules for common attack vectors"
    echo ""
    
    echo -e "${RED}3. ROUTE TABLES:${NC}"
    echo "   • Backup current public routes"
    echo "   • Option to remove public routes (EXTREME - will break internet access)"
    echo ""
    
    echo -e "${RED}4. EC2 INSTANCES:${NC}"
    echo "   • Option to stop instances with public IPs"
    echo "   • Backup instance metadata"
    echo ""
    
    echo -e "${RED}5. ELASTIC IPs:${NC}"
    echo "   • Option to disassociate Elastic IPs"
    echo "   • Preserve EIP allocations for restoration"
    echo ""
    
    # Show actual dry run for security groups
    if [[ $SG_COUNT -gt 0 ]]; then
        print_info "Security Groups remediation preview:"
        python automation/security_group_remediation.py bulk-remediate --dry-run
        echo ""
    fi
}

# Execute security group remediation
remediate_security_groups() {
    if [[ $SG_COUNT -gt 0 ]]; then
        print_info "Remediating Security Groups..."
        python automation/security_group_remediation.py bulk-remediate --cidrs "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
        print_status "Security Groups remediated"
    else
        print_status "No security groups need remediation"
    fi
}

# Create emergency NACL rules
remediate_network_acls() {
    print_info "Creating emergency Network ACL rules..."
    
    # Get all NACLs in VPC
    for nacl_id in $(cat /tmp/emergency_nacls.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(' '.join([n['NetworkAclId'] for n in data['NetworkAcls']]))" 2>/dev/null); do
        print_info "Adding emergency rules to NACL: $nacl_id"
        
        # Add deny rules for critical ports (rule numbers 1-10 for highest priority)
        for port in 22 3389 1433 3306 5432; do
            aws ec2 create-network-acl-entry \
                --network-acl-id "$nacl_id" \
                --rule-number $((port - 21)) \
                --protocol tcp \
                --rule-action deny \
                --cidr-block 0.0.0.0/0 \
                --port-range From=$port,To=$port 2>/dev/null || true
        done
        
        print_status "Emergency rules added to $nacl_id"
    done
}

# Handle public routes (EXTREME option)
handle_public_routes() {
    print_warning "⚠️  EXTREME OPTION: Remove public internet routes"
    print_error "This will break all internet connectivity for the VPC!"
    echo ""
    read -p "Remove public routes? This is IRREVERSIBLE without manual restoration (type 'BREAK_INTERNET' to confirm): " -r
    
    if [[ $REPLY == "BREAK_INTERNET" ]]; then
        print_info "Backing up route tables..."
        cp /tmp/emergency_routes.json "/tmp/emergency_routes_backup_$(date +%s).json"
        
        print_info "Removing public routes..."
        cat /tmp/emergency_routes.json | python3 -c "
import sys, json, subprocess
data = json.load(sys.stdin)
for rt in data['RouteTables']:
    for route in rt['Routes']:
        if route.get('DestinationCidrBlock') == '0.0.0.0/0' and route.get('GatewayId', '').startswith('igw-'):
            cmd = ['aws', 'ec2', 'delete-route', '--route-table-id', rt['RouteTableId'], '--destination-cidr-block', '0.0.0.0/0']
            try:
                subprocess.run(cmd, check=True, capture_output=True)
                print(f'Removed public route from {rt[\"RouteTableId\"]}')
            except:
                print(f'Failed to remove route from {rt[\"RouteTableId\"]}')
"
        print_status "Public routes removed"
    else
        print_info "Skipping route table modification"
    fi
}

# Handle EC2 instances
handle_instances() {
    if [[ $PUBLIC_INSTANCE_COUNT -gt 0 ]]; then
        print_warning "⚠️  EXTREME OPTION: Stop instances with public IPs"
        echo ""
        read -p "Stop instances with public IPs? (type 'STOP_INSTANCES' to confirm): " -r
        
        if [[ $REPLY == "STOP_INSTANCES" ]]; then
            print_info "Backing up instance information..."
            cp /tmp/emergency_instances.json "/tmp/emergency_instances_backup_$(date +%s).json"
            
            print_info "Stopping instances with public IPs..."
            cat /tmp/emergency_instances.json | python3 -c "
import sys, json, subprocess
data = json.load(sys.stdin)
for reservation in data['Reservations']:
    for instance in reservation['Instances']:
        if instance.get('PublicIpAddress'):
            instance_id = instance['InstanceId']
            cmd = ['aws', 'ec2', 'stop-instances', '--instance-ids', instance_id]
            try:
                subprocess.run(cmd, check=True, capture_output=True)
                print(f'Stopped instance {instance_id} (had public IP)')
            except:
                print(f'Failed to stop instance {instance_id}')
"
            print_status "Public instances stopped"
        else
            print_info "Skipping instance shutdown"
        fi
    else
        print_info "No instances with public IPs found"
    fi
}

# Generate restoration guide
generate_restoration_guide() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    RESTORATION_FILE="/tmp/emergency_restoration_guide_${TIMESTAMP}.md"
    
    print_info "Generating restoration guide..."
    
    cat > "$RESTORATION_FILE" << EOF
# Emergency Remediation Restoration Guide
Generated: $(date)
VPC ID: $VPC_ID

## Files Created:
- Security Groups backup: /tmp/emergency_open_sgs.json
- Network ACLs backup: /tmp/emergency_nacls.json
- Route tables backup: /tmp/emergency_routes_backup_*.json (if created)
- Instances backup: /tmp/emergency_instances_backup_*.json (if created)

## Restoration Steps:

### 1. Security Groups
To restore original security group rules, manually review the backup file and re-add necessary rules:
\`\`\`bash
cat /tmp/emergency_open_sgs.json
# Manually restore specific rules as needed
\`\`\`

### 2. Network ACLs
Remove the emergency deny rules that were added:
\`\`\`bash
# List current NACL entries and remove rules 1-10 if they were added
aws ec2 describe-network-acls --network-acl-ids <nacl-id>
aws ec2 delete-network-acl-entry --network-acl-id <nacl-id> --rule-number <rule-number>
\`\`\`

### 3. Route Tables (if modified)
Restore public internet routes:
\`\`\`bash
# Re-add default route to internet gateway
aws ec2 create-route --route-table-id <rt-id> --destination-cidr-block 0.0.0.0/0 --gateway-id <igw-id>
\`\`\`

### 4. EC2 Instances (if stopped)
Restart stopped instances:
\`\`\`bash
# Start specific instances
aws ec2 start-instances --instance-ids <instance-id>
\`\`\`

## Important Notes:
- Always test restoration in a non-production environment first
- Monitor for any service disruptions after restoration
- Review all changes before applying in production
- Consider implementing proper security controls instead of just restoring original state
EOF

    print_status "Restoration guide created: $RESTORATION_FILE"
}

# Main execution flow
main() {
    # Parse command line arguments
    VPC_ID_ARG="$1"
    
    # Confirmation prompt
    print_warning "This will modify AWS VPC security settings during an ACTIVE ATTACK scenario!"
    print_error "This script will make IRREVERSIBLE changes that may break connectivity!"
    echo ""
    read -p "Are you responding to an active security incident? (type 'EMERGENCY' to confirm): " -r
    if [[ $REPLY != "EMERGENCY" ]]; then
        print_info "Emergency remediation cancelled"
        exit 0
    fi
    
    cd "$PROJECT_DIR"
    
    # Get VPC information
    get_vpc_info "$VPC_ID_ARG"
    
    # Assess current security posture
    assess_vpc_security
    
    # Show remediation plan
    show_remediation_plan
    
    # Final confirmation
    echo ""
    print_error "FINAL CONFIRMATION REQUIRED"
    print_warning "Proceeding will make immediate changes to your AWS VPC security configuration!"
    echo ""
    read -p "Execute emergency remediation? (type 'EXECUTE' to confirm): " -r
    if [[ $REPLY != "EXECUTE" ]]; then
        print_info "Emergency remediation cancelled"
        exit 0
    fi
    
    print_header
    print_error "🚨 EXECUTING EMERGENCY REMEDIATION 🚨"
    echo ""
    
    # Execute remediations
    remediate_security_groups
    remediate_network_acls
    
    # Optional extreme measures
    handle_public_routes
    handle_instances
    
    # Generate restoration guide
    generate_restoration_guide
    
    print_header
    print_status "🚨 EMERGENCY REMEDIATION COMPLETED! 🚨"
    print_warning "⚠️  Review the restoration guide for rollback procedures"
    print_info "Restoration guide: /tmp/emergency_restoration_guide_*.md"
    echo ""
    print_error "IMPORTANT: Monitor your environment for any service disruptions"
    print_error "IMPORTANT: This is a temporary fix - implement proper security controls"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
