# Remote state backend configuration
# This ensures state persistence across GitHub Actions runs

# terraform {
#   backend "s3" {
#     bucket = "your-terraform-state-bucket"  # Replace with your bucket name
#     key    = "cis-benchmark-testing/terraform.tfstate"
#     region = "us-east-1"
    
#     # Optional: Add DynamoDB table for state locking
#     # dynamodb_table = "terraform-state-locks"
    
#     # # Encryption
#     # encrypt = true
#   }
# }
