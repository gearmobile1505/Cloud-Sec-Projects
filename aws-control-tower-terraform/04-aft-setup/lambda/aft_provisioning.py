import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    AFT Account Provisioning Lambda Handler
    Triggered by EventBridge when Control Tower creates a new account
    """
    
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract account information from the event
        detail = event.get('detail', {})
        
        if detail.get('eventName') == 'CreateManagedAccount':
            response_elements = detail.get('responseElements', {})
            create_account_status = response_elements.get('createManagedAccountStatus', {})
            
            account_id = create_account_status.get('accountId')
            account_name = create_account_status.get('accountName')
            
            if account_id and account_name:
                logger.info(f"Processing new account: {account_name} ({account_id})")
                
                # Apply AFT customizations
                apply_aft_customizations(account_id, account_name)
                
                # Send notification
                send_notification(account_id, account_name, 'SUCCESS')
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': f'Successfully processed account {account_name}',
                        'accountId': account_id
                    })
                }
            else:
                logger.error("Missing account information in event")
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Missing account information'})
                }
        else:
            logger.info("Event not relevant to AFT processing")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Event ignored'})
            }
            
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        send_notification('unknown', 'unknown', 'FAILED', str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def apply_aft_customizations(account_id, account_name):
    """
    Apply AFT customizations to the new account
    """
    logger.info(f"Applying AFT customizations to account {account_id}")
    
    try:
        # Assume role in the target account
        sts_client = boto3.client('sts')
        role_arn = f"arn:aws:iam::{account_id}:role/OrganizationAccountAccessRole"
        
        assumed_role = sts_client.assume_role(
            RoleArn=role_arn,
            RoleSessionName=f"AFTCustomization-{account_id}"
        )
        
        credentials = assumed_role['Credentials']
        
        # Create session with assumed role credentials
        session = boto3.Session(
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )
        
        # Apply baseline configurations
        apply_baseline_configurations(session, account_id, account_name)
        
        logger.info(f"Successfully applied customizations to account {account_id}")
        
    except Exception as e:
        logger.error(f"Error applying customizations to account {account_id}: {str(e)}")
        raise

def apply_baseline_configurations(session, account_id, account_name):
    """
    Apply baseline configurations to the account
    """
    logger.info(f"Applying baseline configurations to {account_id}")
    
    # Enable CloudTrail
    enable_cloudtrail(session, account_id)
    
    # Configure Config
    configure_config_service(session, account_id)
    
    # Set up GuardDuty
    setup_guardduty(session, account_id)
    
    # Configure SecurityHub
    configure_securityhub(session, account_id)

def enable_cloudtrail(session, account_id):
    """Enable CloudTrail in the account"""
    try:
        cloudtrail = session.client('cloudtrail')
        
        trail_name = f"aft-baseline-trail-{account_id}"
        
        # Create CloudTrail
        cloudtrail.create_trail(
            Name=trail_name,
            S3BucketName=f"aft-cloudtrail-{account_id}",
            IncludeGlobalServiceEvents=True,
            IsMultiRegionTrail=True,
            EnableLogFileValidation=True
        )
        
        # Start logging
        cloudtrail.start_logging(Name=trail_name)
        
        logger.info(f"CloudTrail enabled for account {account_id}")
        
    except Exception as e:
        logger.error(f"Error enabling CloudTrail: {str(e)}")

def configure_config_service(session, account_id):
    """Configure AWS Config service"""
    try:
        config = session.client('config')
        
        # Create configuration recorder
        config.put_configuration_recorder(
            ConfigurationRecorder={
                'name': f'aft-config-recorder-{account_id}',
                'roleARN': f'arn:aws:iam::{account_id}:role/aws-config-role',
                'recordingGroup': {
                    'allSupported': True,
                    'includeGlobalResourceTypes': True
                }
            }
        )
        
        logger.info(f"Config service configured for account {account_id}")
        
    except Exception as e:
        logger.error(f"Error configuring Config service: {str(e)}")

def setup_guardduty(session, account_id):
    """Set up GuardDuty"""
    try:
        guardduty = session.client('guardduty')
        
        # Create detector
        response = guardduty.create_detector(
            Enable=True,
            FindingPublishingFrequency='SIX_HOURS'
        )
        
        logger.info(f"GuardDuty enabled for account {account_id}")
        
    except Exception as e:
        logger.error(f"Error setting up GuardDuty: {str(e)}")

def configure_securityhub(session, account_id):
    """Configure Security Hub"""
    try:
        securityhub = session.client('securityhub')
        
        # Enable Security Hub
        securityhub.enable_security_hub(
            Tags={
                'ManagedBy': 'AFT',
                'AccountId': account_id
            }
        )
        
        logger.info(f"Security Hub enabled for account {account_id}")
        
    except Exception as e:
        logger.error(f"Error configuring Security Hub: {str(e)}")

def send_notification(account_id, account_name, status, error_message=None):
    """Send SNS notification about AFT processing"""
    try:
        sns = boto3.client('sns')
        
        message = {
            'accountId': account_id,
            'accountName': account_name,
            'status': status,
            'timestamp': context.aws_request_id if 'context' in globals() else 'unknown'
        }
        
        if error_message:
            message['errorMessage'] = error_message
        
        sns.publish(
            TopicArn='${sns_topic_arn}',
            Subject=f'AFT Account Processing - {status}',
            Message=json.dumps(message, indent=2)
        )
        
        logger.info(f"Notification sent for account {account_id}")
        
    except Exception as e:
        logger.error(f"Error sending notification: {str(e)}")
