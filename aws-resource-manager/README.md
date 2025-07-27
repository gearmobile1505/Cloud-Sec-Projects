# AWS Resource Manager

A flexible Python starter script for interacting with any AWS boto3 SDK resource. This tool provides a unified interface to work with various AWS services through both command-line and programmatic interfaces.

## Features

- **Universal AWS Service Support**: Works with any AWS service supported by boto3
- **Flexible Operation Execution**: Execute any available operation on AWS services
- **Auto-detection**: Automatically detects common list operations for popular services
- **Multiple AWS Profiles**: Support for different AWS credential profiles
- **Comprehensive Logging**: Built-in logging for debugging and monitoring
- **CLI and Module Support**: Use as a command-line tool or import as a Python module
- **Error Handling**: Robust error handling for AWS operations

## Prerequisites

- Python 3.6 or higher
- boto3 library
- AWS credentials configured (via AWS CLI, environment variables, or IAM roles)

## Installation

1. Install required dependencies:
```bash
pip install boto3
```

2. Configure AWS credentials using one of these methods:
   - AWS CLI: `aws configure`
   - Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - IAM roles (when running on EC2)
   - AWS credentials file

## Usage

### Command Line Interface

#### Basic Usage
```bash
# List EC2 instances
python aws_resource_manager.py ec2

# List S3 buckets
python aws_resource_manager.py s3

# List Lambda functions
python aws_resource_manager.py lambda
```

#### Advanced Usage
```bash
# Execute specific operation
python aws_resource_manager.py ec2 --operation describe_instances

# Use specific AWS profile and region
python aws_resource_manager.py s3 --profile myprofile --region us-west-2

# List all available operations for a service
python aws_resource_manager.py dynamodb --list-operations

# Execute operation with parameters
python aws_resource_manager.py dynamodb --operation describe_table --params '{"TableName": "my-table"}'
```

### Programmatic Usage

```python
from aws_resource_manager import AWSResourceManager

# Initialize manager for EC2 service
ec2_manager = AWSResourceManager('ec2', region_name='us-east-1')

# List EC2 instances
instances = ec2_manager.list_resources()
print(instances)

# Execute specific operation
response = ec2_manager.execute_operation('describe_vpcs')
```

## Examples

### EC2 Management
```bash
# List all EC2 instances
python aws_resource_manager.py ec2

# Get specific instance details
python aws_resource_manager.py ec2 --operation describe_instances --params '{"InstanceIds": ["i-1234567890abcdef0"]}'
```

### S3 Operations
```bash
# List all buckets
python aws_resource_manager.py s3

# List objects in a bucket
python aws_resource_manager.py s3 --operation list_objects_v2 --params '{"Bucket": "my-bucket"}'
```

### Lambda Functions
```bash
# List all Lambda functions
python aws_resource_manager.py lambda

# Get function configuration
python aws_resource_manager.py lambda --operation get_function --params '{"FunctionName": "my-function"}'
```

For more detailed documentation, see the complete README.md file.
