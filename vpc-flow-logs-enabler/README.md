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
