# Usage Guide

## Basic Command Line Usage

### List Resources
```bash
# EC2 instances
python aws_resource_manager.py ec2

# S3 buckets
python aws_resource_manager.py s3

# Lambda functions
python aws_resource_manager.py lambda
```

### Execute Specific Operations
```bash
# Describe specific EC2 instance
python aws_resource_manager.py ec2 --operation describe_instances --params '{"InstanceIds": ["i-1234567890abcdef0"]}'

# Create S3 bucket
python aws_resource_manager.py s3 --operation create_bucket --params '{"Bucket": "my-new-bucket"}'

# List objects in S3 bucket
python aws_resource_manager.py s3 --operation list_objects_v2 --params '{"Bucket": "my-bucket"}'
```

### Using Different Profiles and Regions
```bash
# Use specific profile
python aws_resource_manager.py ec2 --profile production

# Use specific region
python aws_resource_manager.py ec2 --region us-west-2

# Combine profile and region
python aws_resource_manager.py ec2 --profile production --region eu-west-1
```

## Programmatic Usage

### Basic Example
```python
from aws_resource_manager import AWSResourceManager

# Create manager instance
manager = AWSResourceManager('ec2', region_name='us-east-1')

# List resources
instances = manager.list_resources()
print(instances)
```

### Advanced Example
```python
from aws_resource_manager import AWSResourceManager

# Initialize with profile
manager = AWSResourceManager('s3', region_name='us-west-2', profile_name='production')

# Execute custom operation
response = manager.execute_operation('list_objects_v2', Bucket='my-bucket', MaxKeys=10)

# Print formatted response
manager.print_response(response)
```
