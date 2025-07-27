#!/usr/bin/env python3
"""
AWS Resource Manager
A flexible starter script for interacting with any AWS boto3 SDK resource.
"""

import boto3
import json
import logging
from typing import Dict, Any, Optional, List
from botocore.exceptions import ClientError, NoCredentialsError
import argparse
import sys


class AWSResourceManager:
    """
    A flexible class to interact with any AWS service using boto3.
    """
    
    def __init__(self, service_name: str, region_name: str = 'us-east-1', profile_name: str = None):
        """
        Initialize the AWS Resource Manager.
        
        Args:
            service_name (str): AWS service name (e.g., 'ec2', 's3', 'lambda', 'dynamodb')
            region_name (str): AWS region name
            profile_name (str): AWS profile name (optional)
        """
        self.service_name = service_name
        self.region_name = region_name
        self.profile_name = profile_name
        
        # Configure logging
        self.logger = self._setup_logging()
        
        # Initialize boto3 session and clients
        self.session = self._create_session()
        self.client = self._create_client()
        self.resource = self._create_resource()
    
    def _setup_logging(self) -> logging.Logger:
        """Setup logging configuration."""
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
        
        return logger
    
    def _create_session(self) -> boto3.Session:
        """Create boto3 session with optional profile."""
        try:
            if self.profile_name:
                session = boto3.Session(profile_name=self.profile_name)
                self.logger.info(f"Created session with profile: {self.profile_name}")
            else:
                session = boto3.Session()
                self.logger.info("Created default session")
            return session
        except Exception as e:
            self.logger.error(f"Failed to create session: {e}")
            raise
    
    def _create_client(self) -> boto3.client:
        """Create boto3 client for the specified service."""
        try:
            client = self.session.client(self.service_name, region_name=self.region_name)
            self.logger.info(f"Created {self.service_name} client in region {self.region_name}")
            return client
        except NoCredentialsError:
            self.logger.error("AWS credentials not found")
            raise
        except Exception as e:
            self.logger.error(f"Failed to create client: {e}")
            raise
    
    def _create_resource(self) -> Optional[boto3.resource]:
        """Create boto3 resource if available for the service."""
        try:
            resource = self.session.resource(self.service_name, region_name=self.region_name)
            self.logger.info(f"Created {self.service_name} resource")
            return resource
        except Exception as e:
            self.logger.warning(f"Resource not available for {self.service_name}: {e}")
            return None
    
    def list_resources(self, operation_name: str = None, **kwargs) -> Dict[str, Any]:
        """
        List resources using a specified operation or auto-detect common list operations.
        
        Args:
            operation_name (str): Specific operation name to call
            **kwargs: Additional parameters for the operation
            
        Returns:
            Dict containing the response from AWS
        """
        if not operation_name:
            # Common list operations for different services
            common_operations = {
                'ec2': 'describe_instances',
                's3': 'list_buckets',
                'lambda': 'list_functions',
                'dynamodb': 'list_tables',
                'iam': 'list_users',
                'rds': 'describe_db_instances',
                'cloudformation': 'list_stacks',
                'sns': 'list_topics',
                'sqs': 'list_queues'
            }
            operation_name = common_operations.get(self.service_name)
            
            if not operation_name:
                raise ValueError(f"No default list operation for {self.service_name}. Please specify operation_name.")
        
        try:
            operation = getattr(self.client, operation_name)
            response = operation(**kwargs)
            self.logger.info(f"Successfully called {operation_name}")
            return response
        except ClientError as e:
            self.logger.error(f"AWS Client Error: {e}")
            raise
        except AttributeError:
            self.logger.error(f"Operation {operation_name} not available for {self.service_name}")
            raise
        except Exception as e:
            self.logger.error(f"Unexpected error: {e}")
            raise
    
    def execute_operation(self, operation_name: str, **kwargs) -> Dict[str, Any]:
        """
        Execute any operation available on the client.
        
        Args:
            operation_name (str): Name of the operation to execute
            **kwargs: Parameters for the operation
            
        Returns:
            Dict containing the response from AWS
        """
        try:
            if not hasattr(self.client, operation_name):
                raise AttributeError(f"Operation '{operation_name}' not available for {self.service_name}")
            
            operation = getattr(self.client, operation_name)
            response = operation(**kwargs)
            self.logger.info(f"Successfully executed {operation_name}")
            return response
        except ClientError as e:
            self.logger.error(f"AWS Client Error: {e}")
            raise
        except Exception as e:
            self.logger.error(f"Error executing {operation_name}: {e}")
            raise
    
    def get_available_operations(self) -> List[str]:
        """Get list of available operations for the current service."""
        try:
            operations = [method for method in dir(self.client) if not method.startswith('_')]
            operations = [op for op in operations if callable(getattr(self.client, op))]
            return sorted(operations)
        except Exception as e:
            self.logger.error(f"Error getting available operations: {e}")
            return []
    
    def print_response(self, response: Dict[str, Any], indent: int = 2) -> None:
        """Pretty print AWS response."""
        try:
            print(json.dumps(response, indent=indent, default=str))
        except Exception as e:
            self.logger.error(f"Error printing response: {e}")
            print(str(response))


def main():
    """Main function with command line interface."""
    parser = argparse.ArgumentParser(description='AWS Resource Manager - Interact with any AWS service')
    parser.add_argument('service', help='AWS service name (e.g., ec2, s3, lambda)')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    parser.add_argument('--profile', help='AWS profile name')
    parser.add_argument('--operation', help='Operation to execute')
    parser.add_argument('--list-operations', action='store_true', help='List available operations')
    parser.add_argument('--params', help='JSON string of parameters for the operation')
    
    args = parser.parse_args()
    
    try:
        # Initialize the manager
        manager = AWSResourceManager(
            service_name=args.service,
            region_name=args.region,
            profile_name=args.profile
        )
        
        if args.list_operations:
            print(f"Available operations for {args.service}:")
            operations = manager.get_available_operations()
            for op in operations:
                print(f"  - {op}")
            return
        
        # Parse parameters if provided
        params = {}
        if args.params:
            try:
                params = json.loads(args.params)
            except json.JSONDecodeError as e:
                print(f"Error parsing parameters: {e}")
                sys.exit(1)
        
        # Execute operation
        if args.operation:
            response = manager.execute_operation(args.operation, **params)
        else:
            response = manager.list_resources(**params)
        
        # Print response
        manager.print_response(response)
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()


# Example usage as a module:
if __name__ == "__main__" and len(sys.argv) == 1:
    # Example usage when run without arguments
    print("Example usage:")
    print("python aws_resource_manager.py ec2 --operation describe_instances")
    print("python aws_resource_manager.py s3 --list-operations")
    print("python aws_resource_manager.py lambda --operation list_functions")
    print('python aws_resource_manager.py dynamodb --operation create_table --params \'{"TableName": "test"}\'')
