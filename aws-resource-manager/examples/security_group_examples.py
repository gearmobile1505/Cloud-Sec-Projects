#!/usr/bin/env python3
"""
Security Group Examples - Demonstrates security group operations
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from aws_resource_manager import AWSResourceManager
from security_group_remediation import SecurityGroupRemediator

def basic_security_operations():
    """Basic security group operations using AWSResourceManager"""
    print("=== Basic Security Group Operations ===")
    
    ec2_manager = AWSResourceManager('ec2', region_name='us-east-1')
    
    try:
        # Find security groups with open SSH access
        print("\n1. Finding security groups with SSH open to 0.0.0.0/0:")
        open_ssh_sgs = ec2_manager.execute_operation('describe_security_groups', 
            Filters=[
                {'Name': 'ip-permission.from-port', 'Values': ['22']},
                {'Name': 'ip-permission.cidr', 'Values': ['0.0.0.0/0']}
            ]
        )
        
        for sg in open_ssh_sgs.get('SecurityGroups', []):
            print(f"  - {sg['GroupId']}: {sg['GroupName']}")
        
        # List all security groups
        print("\n2. Listing all security groups:")
        all_sgs = ec2_manager.list_resources()
        print(f"  Total security groups: {len(all_sgs.get('SecurityGroups', []))}")
        
    except Exception as e:
        print(f"Error in basic operations: {e}")

def security_remediation_examples():
    """Security remediation examples using SecurityGroupRemediator"""
    print("\n=== Security Group Remediation Examples ===")
    
    remediator = SecurityGroupRemediator(region_name='us-east-1')
    
    try:
        # Find open security groups
        print("\n1. Finding open security groups:")
        open_sgs = remediator.find_open_security_groups()
        print(f"  Found {len(open_sgs)} security groups with open rules")
        
        for sg in open_sgs[:3]:  # Show first 3
            print(f"  - {sg['GroupId']}: {sg['GroupName']} ({len(sg['OpenRules'])} open rules)")
        
        # Generate security report
        print("\n2. Generating security report:")
        report = remediator.generate_remediation_report()
        print(f"  High Risk: {report['Summary']['HighRisk']}")
        print(f"  Medium Risk: {report['Summary']['MediumRisk']}")
        print(f"  Low Risk: {report['Summary']['LowRisk']}")
        
        # Dry run remediation for first security group (if any)
        if open_sgs:
            print(f"\n3. Dry run remediation for {open_sgs[0]['GroupId']}:")
            remediation = remediator.remediate_security_group(
                open_sgs[0]['GroupId'], 
                replacement_cidrs=['10.0.0.0/8'],
                dry_run=True
            )
            print(f"  Would revoke {len(remediation['RulesRevoked'])} rules")
            print(f"  Would add {len(remediation['RulesAdded'])} rules")
        
    except Exception as e:
        print(f"Error in remediation examples: {e}")

def demonstrate_manual_remediation():
    """Show manual remediation using the base manager"""
    print("\n=== Manual Remediation Example ===")
    
    ec2_manager = AWSResourceManager('ec2', region_name='us-east-1')
    
    # This is just an example - don't run on real security groups without verification
    example_sg_id = "sg-example123"  # Replace with actual SG ID
    
    print(f"Example commands for manual remediation of {example_sg_id}:")
    print("\n1. Revoke dangerous SSH rule:")
    print(f"""
    python aws_resource_manager.py ec2 --operation revoke_security_group_ingress --params '{{
        "GroupId": "{example_sg_id}",
        "IpPermissions": [{{
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "IpRanges": [{{"CidrIp": "0.0.0.0/0"}}]
        }}]
    }}'
    """)
    
    print("\n2. Add restricted SSH rule:")
    print(f"""
    python aws_resource_manager.py ec2 --operation authorize_security_group_ingress --params '{{
        "GroupId": "{example_sg_id}",
        "IpPermissions": [{{
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "IpRanges": [{{"CidrIp": "10.0.0.0/8", "Description": "Internal network SSH"}}]
        }}]
    }}'
    """)

def main():
    print("Security Group Examples Demo")
    print("=" * 50)
    
    basic_security_operations()
    security_remediation_examples()
    demonstrate_manual_remediation()
    
    print("\n" + "=" * 50)
    print("Examples completed. Check the output above for results.")
    print("\nNOTE: The manual remediation examples show command syntax only.")
    print("Always use --dry-run first when remediating real security groups!")

if __name__ == "__main__":
    main()
