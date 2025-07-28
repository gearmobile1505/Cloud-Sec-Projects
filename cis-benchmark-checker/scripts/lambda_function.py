#!/usr/bin/env python3
"""
AWS Lambda function for automated CIS benchmark compliance checking.

This function can be deployed to AWS Lambda and triggered by CloudWatch Events
for scheduled compliance checking with integration to Security Hub, Config, and SNS.
"""

import json
import boto3
import os
import logging
from datetime import datetime, timezone
from typing import Dict, List, Any

# Import our CIS checker modules
# Note: These would need to be packaged with the Lambda deployment
from cis_checker import CISBenchmarkChecker, ComplianceStatus
from extended_cis import ExtendedCISChecker

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Lambda handler for CIS compliance checking
    
    Args:
        event: Lambda event (CloudWatch Events, API Gateway, etc.)
        context: Lambda context
        
    Returns:
        Response with compliance summary
    """
    try:
        logger.info("Starting CIS compliance check Lambda execution")
        
        # Parse configuration from environment variables
        config = {
            'region': os.environ.get('AWS_REGION', 'us-east-1'),
            'control_ids': os.environ.get('CONTROL_IDS', '').split(',') if os.environ.get('CONTROL_IDS') else None,
            's3_bucket': os.environ.get('S3_BUCKET'),
            'sns_topic': os.environ.get('SNS_TOPIC'),
            'security_hub_enabled': os.environ.get('SECURITY_HUB_ENABLED', 'false').lower() == 'true',
            'compliance_threshold': float(os.environ.get('COMPLIANCE_THRESHOLD', '95')),
        }
        
        # Filter out empty control IDs
        if config['control_ids']:
            config['control_ids'] = [cid.strip() for cid in config['control_ids'] if cid.strip()]
        
        logger.info(f"Configuration: {json.dumps(config, default=str)}")
        
        # Initialize CIS checker
        checker = ExtendedCISChecker(region=config['region'])
        
        # Run compliance checks
        logger.info("Running CIS compliance checks...")
        results = checker.run_check(config['control_ids'])
        
        # Generate summary
        summary = generate_summary(results)
        logger.info(f"Compliance summary: {summary}")
        
        # Store results in S3 if configured
        if config['s3_bucket']:
            s3_key = store_results_s3(results, summary, config['s3_bucket'])
            logger.info(f"Results stored in S3: s3://{config['s3_bucket']}/{s3_key}")
        
        # Send to Security Hub if enabled
        if config['security_hub_enabled']:
            send_to_security_hub(results, config['region'])
            logger.info("Results sent to Security Hub")
        
        # Send notifications if configured
        if config['sns_topic']:
            send_notification(summary, results, config)
            logger.info(f"Notification sent to {config['sns_topic']}")
        
        # Prepare response
        response = {
            'statusCode': 200,
            'body': {
                'message': 'CIS compliance check completed successfully',
                'summary': summary,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'total_checks': len(results),
                'compliance_percentage': calculate_compliance_percentage(summary)
            }
        }
        
        # Check if compliance threshold is met
        compliance_percentage = calculate_compliance_percentage(summary)
        if compliance_percentage < config['compliance_threshold']:
            response['statusCode'] = 206  # Partial Content - compliance issues found
            response['body']['warning'] = f"Compliance below threshold: {compliance_percentage:.1f}% < {config['compliance_threshold']}%"
        
        logger.info("CIS compliance check completed successfully")
        return response
        
    except Exception as e:
        logger.error(f"Error in CIS compliance check: {e}")
        return {
            'statusCode': 500,
            'body': {
                'error': str(e),
                'message': 'CIS compliance check failed',
                'timestamp': datetime.now(timezone.utc).isoformat()
            }
        }

def generate_summary(results: List) -> Dict[str, int]:
    """Generate compliance summary from results"""
    summary = {
        'compliant': 0,
        'non_compliant': 0,
        'not_applicable': 0,
        'insufficient_data': 0
    }
    
    for result in results:
        if result.status == ComplianceStatus.COMPLIANT:
            summary['compliant'] += 1
        elif result.status == ComplianceStatus.NON_COMPLIANT:
            summary['non_compliant'] += 1
        elif result.status == ComplianceStatus.NOT_APPLICABLE:
            summary['not_applicable'] += 1
        elif result.status == ComplianceStatus.INSUFFICIENT_DATA:
            summary['insufficient_data'] += 1
    
    return summary

def calculate_compliance_percentage(summary: Dict[str, int]) -> float:
    """Calculate compliance percentage"""
    total_applicable = summary['compliant'] + summary['non_compliant']
    if total_applicable == 0:
        return 100.0
    return (summary['compliant'] / total_applicable) * 100

def store_results_s3(results: List, summary: Dict[str, int], bucket: str) -> str:
    """Store compliance results in S3"""
    s3 = boto3.client('s3')
    
    timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
    key = f"cis-compliance-reports/{timestamp}/compliance_report.json"
    
    # Prepare report data
    report_data = {
        'report_metadata': {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'source': 'lambda',
            'total_checks': len(results)
        },
        'summary': summary,
        'compliance_percentage': calculate_compliance_percentage(summary),
        'results': [
            {
                'control_id': result.control_id,
                'status': result.status.value,
                'resource_id': result.resource_id,
                'resource_type': result.resource_type,
                'reason': result.reason,
                'remediation': result.remediation,
                'timestamp': result.timestamp,
                'region': result.region,
                'account_id': result.account_id
            } for result in results
        ]
    }
    
    # Upload to S3
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(report_data, indent=2),
        ContentType='application/json',
        ServerSideEncryption='AES256'
    )
    
    return key

def send_to_security_hub(results: List, region: str):
    """Send compliance results to AWS Security Hub"""
    security_hub = boto3.client('securityhub', region_name=region)
    
    # Convert CIS results to Security Hub findings format
    findings = []
    
    for result in results:
        if result.status == ComplianceStatus.NON_COMPLIANT:
            finding = {
                'SchemaVersion': '2018-10-08',
                'Id': f"cis-{result.control_id}-{result.resource_id}",
                'ProductArn': f"arn:aws:securityhub:{region}::product/custom/cis-benchmark-checker",
                'GeneratorId': f"cis-control-{result.control_id}",
                'AwsAccountId': result.account_id,
                'CreatedAt': result.timestamp,
                'UpdatedAt': result.timestamp,
                'Severity': {
                    'Label': get_severity_for_control(result.control_id)
                },
                'Title': f"CIS Control {result.control_id} - Non-Compliant",
                'Description': result.reason,
                'Resources': [
                    {
                        'Type': result.resource_type,
                        'Id': result.resource_id,
                        'Region': result.region
                    }
                ],
                'Compliance': {
                    'Status': 'FAILED'
                },
                'Remediation': {
                    'Recommendation': {
                        'Text': result.remediation
                    }
                },
                'RecordState': 'ACTIVE',
                'WorkflowState': 'NEW'
            }
            findings.append(finding)
    
    # Submit findings in batches (Security Hub limit is 100 per batch)
    batch_size = 100
    for i in range(0, len(findings), batch_size):
        batch = findings[i:i + batch_size]
        try:
            security_hub.batch_import_findings(Findings=batch)
            logger.info(f"Submitted {len(batch)} findings to Security Hub")
        except Exception as e:
            logger.error(f"Error submitting findings to Security Hub: {e}")

def get_severity_for_control(control_id: str) -> str:
    """Get severity level for a CIS control"""
    critical_controls = ['1.12', '1.13']
    high_controls = ['3.1', '5.2', '1.5']
    medium_controls = ['1.3', '1.4', '1.6', '3.2', '3.8', '5.5']
    
    if control_id in critical_controls:
        return 'CRITICAL'
    elif control_id in high_controls:
        return 'HIGH'
    elif control_id in medium_controls:
        return 'MEDIUM'
    else:
        return 'LOW'

def send_notification(summary: Dict[str, int], results: List, config: Dict[str, Any]):
    """Send SNS notification with compliance summary"""
    sns = boto3.client('sns')
    
    compliance_percentage = calculate_compliance_percentage(summary)
    
    # Create message
    subject = f"CIS Compliance Report - {compliance_percentage:.1f}% Compliant"
    if summary['non_compliant'] > 0:
        subject = f"🔴 CIS Compliance Issues - {compliance_percentage:.1f}% Compliant"
    else:
        subject = f"✅ CIS Compliance Check Passed - {compliance_percentage:.1f}% Compliant"
    
    # Get non-compliant controls for detailed message
    non_compliant_controls = [
        result for result in results 
        if result.status == ComplianceStatus.NON_COMPLIANT
    ]
    
    message = f"""CIS Benchmark Compliance Report

Timestamp: {datetime.now(timezone.utc).isoformat()}
Compliance Score: {compliance_percentage:.1f}%

Summary:
- Compliant: {summary['compliant']}
- Non-Compliant: {summary['non_compliant']}
- Not Applicable: {summary['not_applicable']}
- Insufficient Data: {summary['insufficient_data']}

"""
    
    if non_compliant_controls:
        message += "Non-Compliant Controls:\n"
        for result in non_compliant_controls[:10]:  # Limit to first 10
            message += f"- {result.control_id}: {result.reason}\n"
        
        if len(non_compliant_controls) > 10:
            message += f"... and {len(non_compliant_controls) - 10} more\n"
    
    if config['s3_bucket']:
        message += f"\nFull report available in S3: s3://{config['s3_bucket']}/cis-compliance-reports/"
    
    # Send notification
    try:
        sns.publish(
            TopicArn=config['sns_topic'],
            Subject=subject,
            Message=message
        )
    except Exception as e:
        logger.error(f"Error sending SNS notification: {e}")

# Example CloudFormation template for Lambda deployment
CLOUDFORMATION_TEMPLATE = """
AWSTemplateFormatVersion: '2010-09-09'
Description: 'CIS Benchmark Compliance Checker Lambda Function'

Parameters:
  S3Bucket:
    Type: String
    Default: ''
    Description: 'S3 bucket for storing compliance reports (optional)'
  
  SNSTopic:
    Type: String
    Default: ''
    Description: 'SNS topic for notifications (optional)'
  
  ScheduleExpression:
    Type: String
    Default: 'rate(1 day)'
    Description: 'CloudWatch Events schedule expression'
  
  ControlIDs:
    Type: String
    Default: ''
    Description: 'Comma-separated list of CIS control IDs to check'

Resources:
  CISComplianceLambdaRole:
    Type: 'AWS::IAM::Role'
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'
      Policies:
        - PolicyName: CISCompliancePolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'ec2:Describe*'
                  - 'iam:Get*'
                  - 'iam:List*'
                  - 'cloudtrail:Describe*'
                  - 'cloudtrail:Get*'
                  - 'config:Describe*'
                  - 'config:Get*'
                  - 's3:Get*'
                  - 's3:List*'
                  - 'kms:Describe*'
                  - 'kms:Get*'
                  - 'kms:List*'
                  - 'logs:Describe*'
                Resource: '*'
              - Effect: Allow
                Action:
                  - 's3:PutObject'
                  - 's3:PutObjectAcl'
                Resource: !Sub '${S3Bucket}/*'
                Condition:
                  StringEquals:
                    's3:x-amz-server-side-encryption': 'AES256'
              - Effect: Allow
                Action:
                  - 'sns:Publish'
                Resource: !Ref SNSTopic
              - Effect: Allow
                Action:
                  - 'securityhub:BatchImportFindings'
                Resource: '*'

  CISComplianceLambda:
    Type: 'AWS::Lambda::Function'
    Properties:
      FunctionName: 'cis-benchmark-compliance-checker'
      Runtime: 'python3.9'
      Handler: 'lambda_function.lambda_handler'
      Role: !GetAtt CISComplianceLambdaRole.Arn
      Code:
        ZipFile: |
          # Lambda deployment package would be uploaded here
          def lambda_handler(event, context):
              return {'statusCode': 200, 'body': 'Placeholder'}
      Environment:
        Variables:
          S3_BUCKET: !Ref S3Bucket
          SNS_TOPIC: !Ref SNSTopic
          CONTROL_IDS: !Ref ControlIDs
          SECURITY_HUB_ENABLED: 'true'
          LOG_LEVEL: 'INFO'
      Timeout: 300
      MemorySize: 512

  CISComplianceSchedule:
    Type: 'AWS::Events::Rule'
    Properties:
      Description: 'Schedule for CIS compliance checks'
      ScheduleExpression: !Ref ScheduleExpression
      State: ENABLED
      Targets:
        - Arn: !GetAtt CISComplianceLambda.Arn
          Id: 'CISComplianceLambdaTarget'

  CISComplianceLambdaPermission:
    Type: 'AWS::Lambda::Permission'
    Properties:
      FunctionName: !Ref CISComplianceLambda
      Action: 'lambda:InvokeFunction'
      Principal: 'events.amazonaws.com'
      SourceArn: !GetAtt CISComplianceSchedule.Arn

Outputs:
  LambdaFunctionArn:
    Description: 'ARN of the CIS compliance Lambda function'
    Value: !GetAtt CISComplianceLambda.Arn
  
  ScheduleRuleArn:
    Description: 'ARN of the CloudWatch Events rule'
    Value: !GetAtt CISComplianceSchedule.Arn
"""
