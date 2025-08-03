#!/bin/bash
# Setup script for Terraform S3 backend
# This script creates the S3 bucket and DynamoDB table for remote state storage

set -e

echo "🚀 Setting up Terraform S3 Backend..."

# Get current AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_DEFAULT_REGION:-us-east-1}

# Define bucket and table names
BUCKET_NAME="cis-benchmark-terraform-state-${ACCOUNT_ID}-${AWS_REGION}"
DYNAMODB_TABLE="cis-benchmark-terraform-locks"

echo "Account ID: $ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"

# Check if bucket already exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ S3 bucket $BUCKET_NAME already exists"
else
    echo "📦 Creating S3 bucket $BUCKET_NAME..."
    
    # Create bucket
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Block public access
    aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    # Enable encryption
    aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    echo "✅ S3 bucket created and configured"
fi

# Check if DynamoDB table exists
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "✅ DynamoDB table $DYNAMODB_TABLE already exists"
else
    echo "🗄️  Creating DynamoDB table $DYNAMODB_TABLE..."
    
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        --tags Key=Project,Value=CIS-Benchmark-Testing \
               Key=Purpose,Value=TerraformStateLocking \
               Key=CreatedBy,Value=SetupScript
    
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
    echo "✅ DynamoDB table created"
fi

# Update backend.tf to enable S3 backend
echo "📝 Updating backend.tf configuration..."
cat > backend.tf << EOF
# Remote state backend configuration
# This ensures state persistence across GitHub Actions runs

terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "cis-benchmark-testing/terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo "✅ Backend configuration updated"

# If there's an existing local state, migrate it
if [ -f "terraform.tfstate" ]; then
    echo "🔄 Migrating existing local state to S3..."
    echo "You will be prompted to confirm the migration."
    terraform init -migrate-state
else
    echo "🔧 Initializing Terraform with S3 backend..."
    terraform init
fi

echo "🎉 S3 backend setup complete!"
echo ""
echo "Backend Details:"
echo "  S3 Bucket: $BUCKET_NAME" 
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo "  State Key: cis-benchmark-testing/terraform.tfstate"
echo ""
echo "Your Terraform state is now stored remotely and protected with state locking."
