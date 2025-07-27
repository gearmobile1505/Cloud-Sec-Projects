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
