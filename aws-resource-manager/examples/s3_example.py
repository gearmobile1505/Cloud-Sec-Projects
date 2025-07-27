#!/usr/bin/env python3
"""
S3 Example - Demonstrates how to use AWSResourceManager with S3
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from aws_resource_manager import AWSResourceManager

def main():
    # Initialize S3 manager
    s3_manager = AWSResourceManager('s3', region_name='us-east-1')
    
    try:
        # List all buckets
        print("=== Listing all S3 buckets ===")
        buckets = s3_manager.list_resources()
        s3_manager.print_response(buckets)
        
        # Get bucket locations (if buckets exist)
        if buckets.get('Buckets'):
            bucket_name = buckets['Buckets'][0]['Name']
            print(f"\n=== Getting location for bucket: {bucket_name} ===")
            location = s3_manager.execute_operation('get_bucket_location', Bucket=bucket_name)
            s3_manager.print_response(location)
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
