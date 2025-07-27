#!/usr/bin/env python3
"""
EC2 Example - Demonstrates how to use AWSResourceManager with EC2
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from aws_resource_manager import AWSResourceManager

def main():
    # Initialize EC2 manager
    ec2_manager = AWSResourceManager('ec2', region_name='us-east-1')
    
    try:
        # List all instances
        print("=== Listing all EC2 instances ===")
        instances = ec2_manager.list_resources()
        ec2_manager.print_response(instances)
        
        # Get available operations
        print("\n=== Available EC2 operations ===")
        operations = ec2_manager.get_available_operations()
        for op in operations[:10]:  # Show first 10
            print(f"- {op}")
        print(f"... and {len(operations) - 10} more operations")
        
        # Describe VPCs
        print("\n=== Describing VPCs ===")
        vpcs = ec2_manager.execute_operation('describe_vpcs')
        ec2_manager.print_response(vpcs)
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
