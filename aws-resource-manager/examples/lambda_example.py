#!/usr/bin/env python3
"""
Lambda Example - Demonstrates how to use AWSResourceManager with Lambda
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from aws_resource_manager import AWSResourceManager

def main():
    # Initialize Lambda manager
    lambda_manager = AWSResourceManager('lambda', region_name='us-east-1')
    
    try:
        # List all functions
        print("=== Listing all Lambda functions ===")
        functions = lambda_manager.list_resources()
        lambda_manager.print_response(functions)
        
        # Get account settings
        print("\n=== Getting account settings ===")
        settings = lambda_manager.execute_operation('get_account_settings')
        lambda_manager.print_response(settings)
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
