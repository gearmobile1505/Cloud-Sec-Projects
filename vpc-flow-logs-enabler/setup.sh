#!/bin/bash

# setup-project.sh
# Creates the complete directory structure and files for VPC Flow Logs Enabler

set -e

PROJECT_NAME="vpc-flow-logs-enabler"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up VPC Flow Logs Enabler project structure...${NC}"

# Create main directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create directory structure
mkdir -p modules/vpc-flow-logs-lambda
mkdir -p environments/{dev,staging,prod}
mkdir -p scripts
mkdir -p cross-account-setup

echo -e "${YELLOW}Creating Terraform configuration files...${NC}"

# Create terraform.tfvars.example
cat > terraform.tfvars.example << 'EOF'
# AWS Configuration
aws_region = "us-east-1"

# S3 Bucket for centralized flow logs (must be globally unique)
flow_logs_bucket_name = "your-org-vpc-flow-logs-bucket-unique-name"

# Lambda Configuration
function_name              = "vpc-flow-logs-enabler"
lambda_schedule_expression = "rate(1 day)"

# Target account to process (can be changed via EventBridge input)
target_account_id = "123456789012"

# Default tags applied to all resources
default_tags = {
  Environment = "production"
  Project     = "vpc-flow-logs"
  Owner       = "security-team"
  CostCenter  = "security"
}
EOF

# Create the Lambda function Python code
cat > modules/vpc-flow-logs-lambda/lambda_function.py << 'EOF'
import boto3
import os
from botocore.exceptions import ClientError

# Environment variable
FLOW_LOG_S3_BUCKET = os.environ['FLOW_LOG_S3_BUCKET']

def enable_custom_flow_logs(vpc_id, ec2_client, s3_bucket):
    """Enable VPC flow logs with custom format for enhanced monitoring."""
    custom_log_format = (
        '${account-id} ${action} ${bytes} ${dstaddr} ${dstport} ${end} ${start} ${flow-direction} '
        '${interface-id} ${packets} ${protocol} ${pkt-dst-aws-service} ${pkt-dstaddr} '
        '${pkt-src-aws-service} ${pkt-srcaddr} ${region} ${subnet-id} ${tcp-flags} '
        '${traffic-path} ${type} ${vpc-id}'
    )
    
    try:
        print(f"Trying to enable custom format flow logs for {vpc_id}")
        response = ec2_client.create_flow_logs(
            ResourceIds=[vpc_id],
            ResourceType="VPC",
            TrafficType="ALL",
            LogDestinationType="s3",
            LogDestination=f"arn:aws:s3:::{s3_bucket}",
            LogFormat=custom_log_format
        )
        print(f"Custom format flow logs successfully enabled for VPC {vpc_id}. Response: {response}")
        
    except ClientError as e:
        print(f"Failed to enable custom format flow logs for VPC {vpc_id}. Error: {e.response['Error']['Message']}")
        if e.response['Error']['Code'] == "FlowLogAlreadyExists":
            print(f"Custom format flow logs already enabled for {vpc_id}")
        else:
            raise

def assume_role(account_id):
    """Assume an IAM role in the target account."""
    sts_client = boto3.client('sts')
    role_arn = f"arn:aws:iam::{account_id}:role/VPC_FlowLogs_CrossAccountRole"
    
    try:
        assumed_role_object = sts_client.assume_role(
            RoleArn=role_arn,
            RoleSessionName="AssumeRoleSession",
            ExternalId="vpc-flow-logs-cross-account"
        )
    except ClientError as e:
        print(f"Unable to assume role in account {account_id}: {e}")
        raise
    
    return assumed_role_object['Credentials']

def get_ec2_client(credentials, region):
    """Create an EC2 client with assumed role credentials."""
    return boto3.client(
        'ec2',
        region_name=region,
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )

def get_all_aws_regions():
    """Fetch all AWS regions enabled for EC2."""
    ec2 = boto3.client('ec2')
    response = ec2.describe_regions(AllRegions=False)
    return [region['RegionName'] for region in response['Regions']]

def lambda_handler(event, context):
    """
    Expects event['account_number'] to be the AWS account to process.
    Example:
    {
        "account_number": "123456789012"
    }
    """
    
    account_id = event.get('account_number')
    if not account_id:
        print("No account_number provided in payload.")
        return {
            'statusCode': 400,
            'body': 'No account_number provided in payload.'
        }
    
    try:
        credentials = assume_role(account_id)
    except ClientError:
        print(f"Could not assume role in account {account_id}, aborting.")
        return {
            'statusCode': 500,
            'body': f'Could not assume role in account {account_id}'
        }
    
    regions = get_all_aws_regions()
    total_processed = 0
    
    for region in regions:
        print(f"Checking region: {region}")
        ec2_client = get_ec2_client(credentials, region)
        
        try:
            vpcs = ec2_client.describe_vpcs()['Vpcs']
        except ClientError as e:
            print(f"Could not describe VPCs in region {region}: {e}")
            continue
        
        for vpc in vpcs:
            vpc_id = vpc['VpcId']
            print(f"Processing VPC {vpc_id} in region {region} for account {account_id}")
            
            try:
                enable_custom_flow_logs(vpc_id, ec2_client, FLOW_LOG_S3_BUCKET)
                total_processed += 1
            except ClientError:
                print(f"Failed to enable flow logs for VPC {vpc_id} in region {region}")
                continue
    
    print(f"Total VPCs processed: {total_processed}")
    return {
        'statusCode': 200,
        'body': f'Successfully processed {total_processed} VPCs in account {account_id}'
    }
EOF

# Create deployment scripts
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting VPC Flow Logs Enabler deployment...${NC}"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed.${NC}" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}Python 3 is required but not installed.${NC}" >&2; exit 1; }

# Validate terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}terraform.tfvars file not found. Please create it based on terraform.tfvars.example${NC}"
    exit 1
fi

echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

echo -e "${YELLOW}Planning deployment...${NC}"
terraform plan -out=tfplan

echo -e "${YELLOW}Applying changes...${NC}"
terraform apply tfplan

echo -e "${GREEN}Deployment completed successfully!${NC}"

# Display important outputs
echo -e "${GREEN}Important information:${NC}"
terraform output
EOF

cat > scripts/create-requests-layer.sh << 'EOF'
#!/bin/bash

set -e

LAYER_DIR="modules/vpc-flow-logs-lambda"
LAYER_ZIP="python-requests.zip"

echo "Creating Python requests layer..."

cd $LAYER_DIR

# Create layer structure
mkdir -p python/lib/python3.11/site-packages

# Install requests
pip install requests -t python/lib/python3.11/site-packages/

# Create zip file
zip -r $LAYER_ZIP python/

# Clean up
rm -rf python/

echo "Layer created: $LAYER_ZIP"
EOF

# Create cross-account setup
cat > cross-account-setup/main.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "central_account_id" {
  description = "AWS Account ID where the Lambda function is deployed"
  type        = string
}

variable "lambda_role_name" {
  description = "Name of the Lambda execution role in the central account"
  type        = string
  default     = "lambda-vpc-flow-logs-enabler-role"
}

# Cross-account role that the Lambda function will assume
resource "aws_iam_role" "vpc_flow_logs_cross_account_role" {
  name = "VPC_FlowLogs_CrossAccountRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.central_account_id}:role/${var.lambda_role_name}"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "vpc-flow-logs-cross-account"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "VPC_FlowLogs_CrossAccountRole"
    Purpose     = "Allow central Lambda to enable VPC Flow Logs"
    Environment = "production"
  }
}

# IAM policy for VPC Flow Logs operations
data "aws_iam_policy_document" "vpc_flow_logs_permissions" {
  statement {
    sid    = "VPCFlowLogsPermissions"
    effect = "Allow"
    
    actions = [
      "ec2:CreateFlowLogs",
      "ec2:DescribeFlowLogs",
      "ec2:DescribeVpcs",
      "ec2:DescribeRegions"
    ]
    
    resources = ["*"]
  }
  
  statement {
    sid    = "LogsDeliveryPermissions"
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/vpc/flowlogs*"
    ]
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy" "vpc_flow_logs_cross_account_policy" {
  name   = "vpc-flow-logs-permissions"
  role   = aws_iam_role.vpc_flow_logs_cross_account_role.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_permissions.json
}

# Output the role ARN for reference
output "cross_account_role_arn" {
  description = "ARN of the cross-account role"
  value       = aws_iam_role.vpc_flow_logs_cross_account_role.arn
}
EOF

cat > cross-account-setup/deploy-cross-account.sh << 'EOF'
#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <central-account-id>${NC}"
    echo -e "${YELLOW}Example: $0 123456789012${NC}"
    exit 1
fi

CENTRAL_ACCOUNT_ID=$1

echo -e "${GREEN}Deploying cross-account role for central account: ${CENTRAL_ACCOUNT_ID}${NC}"

terraform init
terraform plan -var="central_account_id=${CENTRAL_ACCOUNT_ID}"
terraform apply -var="central_account_id=${CENTRAL_ACCOUNT_ID}"

echo -e "${GREEN}Cross-account role deployed successfully!${NC}"
EOF

# Make scripts executable
chmod +x scripts/*.sh
chmod +x cross-account-setup/*.sh

# Create a simple README
cat > README.md << 'EOF'
# VPC Flow Logs Enabler

Automated solution to enable VPC Flow Logs across multiple AWS accounts in an enterprise organization.

## Quick Start

1. **Setup the project structure:**
   ```bash
   ./setup-project.sh
   ```

2. **Configure your environment:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Deploy central infrastructure:**
   ```bash
   ./scripts/deploy.sh
   ```

4. **Deploy cross-account roles in target accounts:**
   ```bash
   cd cross-account-setup
   ./deploy-cross-account.sh YOUR-CENTRAL-ACCOUNT-ID
   ```

## Architecture

- **Lambda Function**: Processes accounts and enables VPC Flow Logs
- **EventBridge**: Schedules Lambda execution
- **S3 Bucket**: Centralized storage for flow logs
- **Cross-Account Roles**: Allow Lambda to assume roles in target accounts

## Files Created

- `main.tf` - Root Terraform configuration
- `modules/vpc-flow-logs-lambda/` - Lambda module
- `cross-account-setup/` - Cross-account role setup
- `scripts/` - Deployment and utility scripts

## Next Steps

1. Customize `terraform.tfvars` for your environment
2. Run `./scripts/deploy.sh` to deploy
3. Set up cross-account roles in target accounts
4. Test the Lambda function

For detailed documentation, see the deployment guide created in the project.
EOF

echo -e "${GREEN}Project setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. cd $PROJECT_NAME"
echo "2. cp terraform.tfvars.example terraform.tfvars"
echo "3. Edit terraform.tfvars with your values"
echo "4. ./scripts/deploy.sh"
echo ""
echo -e "${GREEN}Project structure created in: $(pwd)/$PROJECT_NAME${NC}"