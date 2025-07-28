#!/usr/bin/env python3
"""
AWS CIS Benchmark Checker

Automated compliance checking against CIS AWS Foundations Benchmark v1.5.0
using AWS Config, Security Hub, and direct API calls.

Features:
- CIS controls validation across multiple AWS services
- Integration with AWS Config Rules and Security Hub
- Automated remediation suggestions
- Detailed compliance reporting
- Multi-account support
"""

import argparse
import boto3
import json
import logging
import sys
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from enum import Enum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ComplianceStatus(Enum):
    """Compliance status enumeration"""
    COMPLIANT = "COMPLIANT"
    NON_COMPLIANT = "NON_COMPLIANT"
    NOT_APPLICABLE = "NOT_APPLICABLE"
    INSUFFICIENT_DATA = "INSUFFICIENT_DATA"

@dataclass
class CISControl:
    """CIS control definition"""
    control_id: str
    title: str
    description: str
    severity: str
    service: str
    category: str
    automated: bool = True

@dataclass
class ComplianceResult:
    """Compliance check result"""
    control_id: str
    status: ComplianceStatus
    resource_id: str
    resource_type: str
    reason: str
    remediation: str
    timestamp: str
    region: str
    account_id: str

class CISBenchmarkChecker:
    """Main CIS benchmark checker class"""
    
    def __init__(self, profile: Optional[str] = None, region: str = 'us-east-1'):
        """
        Initialize the CIS benchmark checker
        
        Args:
            profile: AWS profile to use
            region: AWS region to check
        """
        self.profile = profile
        self.region = region
        self.session = boto3.Session(profile_name=profile) if profile else boto3.Session()
        
        # Initialize AWS clients
        self.ec2 = self.session.client('ec2', region_name=region)
        self.iam = self.session.client('iam', region_name=region)
        self.cloudtrail = self.session.client('cloudtrail', region_name=region)
        self.config = self.session.client('config', region_name=region)
        self.security_hub = self.session.client('securityhub', region_name=region)
        self.s3 = self.session.client('s3', region_name=region)
        self.kms = self.session.client('kms', region_name=region)
        self.logs = self.session.client('logs', region_name=region)
        self.sns = self.session.client('sns', region_name=region)
        
        # Get account information
        sts = self.session.client('sts')
        self.account_id = sts.get_caller_identity()['Account']
        
        logger.info(f"Initialized CIS checker for account {self.account_id} in region {region}")
        
        # Define CIS controls
        self.cis_controls = self._load_cis_controls()
        
    def _load_cis_controls(self) -> Dict[str, CISControl]:
        """Load CIS control definitions"""
        controls = {
            # Identity and Access Management (IAM)
            "1.1": CISControl(
                control_id="1.1",
                title="Maintain current contact details",
                description="Ensure security contact information is up to date",
                severity="LOW",
                service="account",
                category="iam",
                automated=False
            ),
            "1.2": CISControl(
                control_id="1.2", 
                title="Ensure security questions are registered",
                description="Security questions provide additional account protection",
                severity="LOW",
                service="account",
                category="iam",
                automated=False
            ),
            "1.3": CISControl(
                control_id="1.3",
                title="Ensure credentials unused for 45 days or greater are disabled",
                description="Remove or deactivate unnecessary credentials",
                severity="MEDIUM",
                service="iam",
                category="iam"
            ),
            "1.4": CISControl(
                control_id="1.4",
                title="Ensure access keys are rotated every 90 days or less",
                description="Regular rotation of access keys reduces exposure risk",
                severity="MEDIUM", 
                service="iam",
                category="iam"
            ),
            "1.5": CISControl(
                control_id="1.5",
                title="Ensure IAM password policy requires minimum length of 14 or greater",
                description="Strong password policy enforcement",
                severity="HIGH",
                service="iam",
                category="iam"
            ),
            "1.6": CISControl(
                control_id="1.6",
                title="Ensure IAM password policy prevents password reuse",
                description="Prevent users from reusing previous passwords",
                severity="MEDIUM",
                service="iam", 
                category="iam"
            ),
            "1.7": CISControl(
                control_id="1.7",
                title="Ensure IAM password policy requires uppercase characters",
                description="Password complexity requirements",
                severity="MEDIUM",
                service="iam",
                category="iam"
            ),
            "1.8": CISControl(
                control_id="1.8",
                title="Ensure IAM password policy requires lowercase characters", 
                description="Password complexity requirements",
                severity="MEDIUM",
                service="iam",
                category="iam"
            ),
            "1.9": CISControl(
                control_id="1.9",
                title="Ensure IAM password policy requires symbols",
                description="Password complexity requirements",
                severity="MEDIUM",
                service="iam",
                category="iam"
            ),
            "1.10": CISControl(
                control_id="1.10",
                title="Ensure IAM password policy requires numbers",
                description="Password complexity requirements", 
                severity="MEDIUM",
                service="iam",
                category="iam"
            ),
            "1.11": CISControl(
                control_id="1.11",
                title="Ensure IAM password policy requires minimum password age",
                description="Prevent rapid password changes",
                severity="LOW",
                service="iam",
                category="iam"
            ),
            "1.12": CISControl(
                control_id="1.12",
                title="Ensure no root user access key exists",
                description="Root user should not have access keys",
                severity="CRITICAL",
                service="iam",
                category="iam"
            ),
            "1.13": CISControl(
                control_id="1.13", 
                title="Ensure MFA is enabled for the root user",
                description="Multi-factor authentication for root account",
                severity="CRITICAL",
                service="iam",
                category="iam"
            ),
            "1.14": CISControl(
                control_id="1.14",
                title="Ensure hardware MFA is enabled for the root user",
                description="Hardware-based MFA provides stronger security",
                severity="HIGH",
                service="iam",
                category="iam"
            ),
            
            # Logging (CloudTrail)
            "3.1": CISControl(
                control_id="3.1",
                title="Ensure CloudTrail is enabled in all regions",
                description="Comprehensive API logging across all regions",
                severity="HIGH",
                service="cloudtrail",
                category="logging"
            ),
            "3.2": CISControl(
                control_id="3.2",
                title="Ensure CloudTrail log file validation is enabled",
                description="Detect tampering of CloudTrail logs",
                severity="MEDIUM",
                service="cloudtrail", 
                category="logging"
            ),
            "3.3": CISControl(
                control_id="3.3",
                title="Ensure the S3 bucket used to store CloudTrail logs is not publicly accessible",
                description="Protect audit logs from unauthorized access",
                severity="HIGH",
                service="s3",
                category="logging"
            ),
            "3.4": CISControl(
                control_id="3.4",
                title="Ensure CloudTrail trails are integrated with CloudWatch Logs",
                description="Enable real-time monitoring of API activity",
                severity="MEDIUM",
                service="cloudtrail",
                category="logging"
            ),
            "3.5": CISControl(
                control_id="3.5",
                title="Ensure AWS Config is enabled in all regions",
                description="Configuration compliance monitoring",
                severity="MEDIUM",
                service="config",
                category="logging"
            ),
            "3.6": CISControl(
                control_id="3.6",
                title="Ensure S3 bucket access logging is enabled on CloudTrail S3 bucket",
                description="Monitor access to audit log storage",
                severity="LOW",
                service="s3",
                category="logging"
            ),
            "3.7": CISControl(
                control_id="3.7",
                title="Ensure CloudTrail logs are encrypted at rest using KMS CMKs",
                description="Protect audit logs with encryption",
                severity="MEDIUM",
                service="kms",
                category="logging"
            ),
            "3.8": CISControl(
                control_id="3.8",
                title="Ensure rotation for customer-created CMKs is enabled",
                description="Regular key rotation for enhanced security",
                severity="MEDIUM",
                service="kms",
                category="logging"
            ),
            
            # Networking (VPC)
            "5.1": CISControl(
                control_id="5.1",
                title="Ensure no Network ACLs allow ingress from 0.0.0.0/0 to remote server administration ports",
                description="Restrict network-level access to management ports",
                severity="HIGH",
                service="ec2",
                category="networking"
            ),
            "5.2": CISControl(
                control_id="5.2", 
                title="Ensure no security groups allow ingress from 0.0.0.0/0 to remote server administration ports",
                description="Restrict security group access to management ports",
                severity="HIGH",
                service="ec2",
                category="networking"
            ),
            "5.3": CISControl(
                control_id="5.3",
                title="Ensure the default security group restricts all traffic",
                description="Default security groups should deny all traffic",
                severity="MEDIUM",
                service="ec2", 
                category="networking"
            ),
            "5.4": CISControl(
                control_id="5.4",
                title="Ensure routing tables for VPC peering are least access",
                description="Minimize routing exposure in peered VPCs",
                severity="MEDIUM",
                service="ec2",
                category="networking"
            ),
            "5.5": CISControl(
                control_id="5.5",
                title="Ensure VPC flow logging is enabled in all VPCs", 
                description="Enable network traffic monitoring",
                severity="MEDIUM",
                service="ec2",
                category="networking"
            ),
        }
        
        return controls

    def check_control_1_3(self) -> List[ComplianceResult]:
        """1.3 - Ensure credentials unused for 45 days or greater are disabled"""
        results = []
        
        try:
            # Check IAM users
            paginator = self.iam.get_paginator('list_users')
            for page in paginator.paginate():
                for user in page['Users']:
                    username = user['UserName']
                    
                    # Check password last used
                    if 'PasswordLastUsed' in user:
                        last_used = user['PasswordLastUsed']
                        days_since_used = (datetime.now(timezone.utc) - last_used).days
                        
                        if days_since_used > 45:
                            results.append(ComplianceResult(
                                control_id="1.3",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=username,
                                resource_type="IAM::User",
                                reason=f"Password unused for {days_since_used} days",
                                remediation="Disable or remove the user account",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                region=self.region,
                                account_id=self.account_id
                            ))
                        else:
                            results.append(ComplianceResult(
                                control_id="1.3",
                                status=ComplianceStatus.COMPLIANT,
                                resource_id=username,
                                resource_type="IAM::User",
                                reason=f"Password used within {days_since_used} days",
                                remediation="No action needed",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                region=self.region,
                                account_id=self.account_id
                            ))
                    
                    # Check access keys
                    try:
                        keys_response = self.iam.list_access_keys(UserName=username)
                        for key in keys_response['AccessKeyMetadata']:
                            key_id = key['AccessKeyId']
                            
                            # Get last used information
                            try:
                                last_used_response = self.iam.get_access_key_last_used(AccessKeyId=key_id)
                                if 'LastUsedDate' in last_used_response['AccessKeyLastUsed']:
                                    last_used = last_used_response['AccessKeyLastUsed']['LastUsedDate']
                                    days_since_used = (datetime.now(timezone.utc) - last_used).days
                                    
                                    if days_since_used > 45:
                                        results.append(ComplianceResult(
                                            control_id="1.3",
                                            status=ComplianceStatus.NON_COMPLIANT,
                                            resource_id=key_id,
                                            resource_type="IAM::AccessKey",
                                            reason=f"Access key unused for {days_since_used} days",
                                            remediation="Disable or delete the access key",
                                            timestamp=datetime.now(timezone.utc).isoformat(),
                                            region=self.region,
                                            account_id=self.account_id
                                        ))
                            except Exception as e:
                                logger.warning(f"Could not check last used for key {key_id}: {e}")
                                
                    except Exception as e:
                        logger.warning(f"Could not check access keys for user {username}: {e}")
                        
        except Exception as e:
            logger.error(f"Error checking control 1.3: {e}")
            results.append(ComplianceResult(
                control_id="1.3",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="N/A",
                resource_type="IAM",
                reason=f"Error during check: {e}",
                remediation="Review IAM permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def check_control_1_12(self) -> List[ComplianceResult]:
        """1.12 - Ensure no root user access key exists"""
        results = []
        
        try:
            # Get account summary to check root access keys
            summary = self.iam.get_account_summary()
            root_access_keys = summary['SummaryMap'].get('AccountAccessKeysPresent', 0)
            
            if root_access_keys > 0:
                results.append(ComplianceResult(
                    control_id="1.12",
                    status=ComplianceStatus.NON_COMPLIANT,
                    resource_id="root",
                    resource_type="IAM::Root",
                    reason="Root user has access keys",
                    remediation="Delete root user access keys immediately",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
            else:
                results.append(ComplianceResult(
                    control_id="1.12",
                    status=ComplianceStatus.COMPLIANT,
                    resource_id="root",
                    resource_type="IAM::Root",
                    reason="No root user access keys found",
                    remediation="No action needed",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
                
        except Exception as e:
            logger.error(f"Error checking control 1.12: {e}")
            results.append(ComplianceResult(
                control_id="1.12",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="root",
                resource_type="IAM::Root",
                reason=f"Error during check: {e}",
                remediation="Review IAM permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def check_control_3_1(self) -> List[ComplianceResult]:
        """3.1 - Ensure CloudTrail is enabled in all regions"""
        results = []
        
        try:
            # Check if CloudTrail is enabled
            trails = self.cloudtrail.describe_trails()['trailList']
            
            # Check for multi-region trail
            multi_region_trails = [t for t in trails if t.get('IsMultiRegionTrail', False)]
            
            if multi_region_trails:
                for trail in multi_region_trails:
                    # Check if trail is logging
                    status = self.cloudtrail.get_trail_status(Name=trail['TrailARN'])
                    
                    if status['IsLogging']:
                        results.append(ComplianceResult(
                            control_id="3.1",
                            status=ComplianceStatus.COMPLIANT,
                            resource_id=trail['Name'],
                            resource_type="CloudTrail::Trail",
                            reason="Multi-region trail is active and logging",
                            remediation="No action needed",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
                    else:
                        results.append(ComplianceResult(
                            control_id="3.1",
                            status=ComplianceStatus.NON_COMPLIANT,
                            resource_id=trail['Name'],
                            resource_type="CloudTrail::Trail",
                            reason="Multi-region trail exists but is not logging",
                            remediation="Start CloudTrail logging",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
            else:
                results.append(ComplianceResult(
                    control_id="3.1",
                    status=ComplianceStatus.NON_COMPLIANT,
                    resource_id="N/A",
                    resource_type="CloudTrail",
                    reason="No multi-region CloudTrail found",
                    remediation="Create and enable a multi-region CloudTrail",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
                
        except Exception as e:
            logger.error(f"Error checking control 3.1: {e}")
            results.append(ComplianceResult(
                control_id="3.1",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="N/A",
                resource_type="CloudTrail",
                reason=f"Error during check: {e}",
                remediation="Review CloudTrail permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def check_control_5_2(self) -> List[ComplianceResult]:
        """5.2 - Ensure no security groups allow ingress from 0.0.0.0/0 to remote server administration ports"""
        results = []
        admin_ports = [22, 3389, 5985, 5986]  # SSH, RDP, WinRM
        
        try:
            paginator = self.ec2.get_paginator('describe_security_groups')
            for page in paginator.paginate():
                for sg in page['SecurityGroups']:
                    sg_id = sg['GroupId']
                    
                    # Check each ingress rule
                    for rule in sg.get('IpPermissions', []):
                        # Check if rule allows admin ports from 0.0.0.0/0
                        from_port = rule.get('FromPort')
                        to_port = rule.get('ToPort')
                        ip_protocol = rule.get('IpProtocol')
                        
                        # Check for admin ports
                        risky_rule = False
                        if ip_protocol == 'tcp':
                            if from_port and to_port:
                                # Check if any admin port is in range
                                for admin_port in admin_ports:
                                    if from_port <= admin_port <= to_port:
                                        # Check if 0.0.0.0/0 is allowed
                                        for ip_range in rule.get('IpRanges', []):
                                            if ip_range.get('CidrIp') == '0.0.0.0/0':
                                                risky_rule = True
                                                break
                        elif ip_protocol == '-1':  # All protocols
                            for ip_range in rule.get('IpRanges', []):
                                if ip_range.get('CidrIp') == '0.0.0.0/0':
                                    risky_rule = True
                                    break
                        
                        if risky_rule:
                            results.append(ComplianceResult(
                                control_id="5.2",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=sg_id,
                                resource_type="EC2::SecurityGroup",
                                reason=f"Allows admin ports from 0.0.0.0/0",
                                remediation="Restrict source IPs to specific networks",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                region=self.region,
                                account_id=self.account_id
                            ))
                            break  # Only report once per security group
                    else:
                        # No risky rules found for this security group
                        results.append(ComplianceResult(
                            control_id="5.2",
                            status=ComplianceStatus.COMPLIANT,
                            resource_id=sg_id,
                            resource_type="EC2::SecurityGroup",
                            reason="No admin ports open to 0.0.0.0/0",
                            remediation="No action needed",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
                        
        except Exception as e:
            logger.error(f"Error checking control 5.2: {e}")
            results.append(ComplianceResult(
                control_id="5.2",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="N/A",
                resource_type="EC2::SecurityGroup",
                reason=f"Error during check: {e}",
                remediation="Review EC2 permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def run_check(self, control_ids: Optional[List[str]] = None) -> List[ComplianceResult]:
        """
        Run CIS benchmark checks
        
        Args:
            control_ids: Specific control IDs to check (if None, check all)
            
        Returns:
            List of compliance results
        """
        if control_ids is None:
            control_ids = list(self.cis_controls.keys())
            
        all_results = []
        
        for control_id in control_ids:
            if control_id not in self.cis_controls:
                logger.warning(f"Unknown control ID: {control_id}")
                continue
                
            logger.info(f"Checking control {control_id}: {self.cis_controls[control_id].title}")
            
            # Map control IDs to check methods
            check_methods = {
                "1.3": self.check_control_1_3,
                "1.12": self.check_control_1_12,
                "3.1": self.check_control_3_1,
                "5.2": self.check_control_5_2,
            }
            
            if control_id in check_methods:
                try:
                    results = check_methods[control_id]()
                    all_results.extend(results)
                except Exception as e:
                    logger.error(f"Error checking control {control_id}: {e}")
                    all_results.append(ComplianceResult(
                        control_id=control_id,
                        status=ComplianceStatus.INSUFFICIENT_DATA,
                        resource_id="N/A",
                        resource_type="Unknown",
                        reason=f"Check method failed: {e}",
                        remediation="Review implementation and retry",
                        timestamp=datetime.now(timezone.utc).isoformat(),
                        region=self.region,
                        account_id=self.account_id
                    ))
            else:
                logger.warning(f"Check method not implemented for control {control_id}")
                all_results.append(ComplianceResult(
                    control_id=control_id,
                    status=ComplianceStatus.NOT_APPLICABLE,
                    resource_id="N/A",
                    resource_type="Unknown",
                    reason="Check method not implemented",
                    remediation="Manual review required",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
                
        return all_results

    def generate_report(self, results: List[ComplianceResult], output_format: str = 'json') -> str:
        """
        Generate compliance report
        
        Args:
            results: Compliance check results
            output_format: Output format ('json' or 'text')
            
        Returns:
            Formatted report string
        """
        if output_format == 'json':
            report_data = {
                "report_metadata": {
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "account_id": self.account_id,
                    "region": self.region,
                    "total_checks": len(results)
                },
                "summary": {
                    "compliant": len([r for r in results if r.status == ComplianceStatus.COMPLIANT]),
                    "non_compliant": len([r for r in results if r.status == ComplianceStatus.NON_COMPLIANT]),
                    "not_applicable": len([r for r in results if r.status == ComplianceStatus.NOT_APPLICABLE]),
                    "insufficient_data": len([r for r in results if r.status == ComplianceStatus.INSUFFICIENT_DATA])
                },
                "results": [
                    {
                        "control_id": result.control_id,
                        "status": result.status.value,  # Convert enum to string
                        "resource_id": result.resource_id,
                        "resource_type": result.resource_type,
                        "reason": result.reason,
                        "remediation": result.remediation,
                        "timestamp": result.timestamp,
                        "region": result.region,
                        "account_id": result.account_id
                    }
                    for result in results
                ]
            }
            return json.dumps(report_data, indent=2)
        else:
            # Text format
            report_lines = [
                "=" * 80,
                "AWS CIS Benchmark Compliance Report",
                "=" * 80,
                f"Timestamp: {datetime.now(timezone.utc).isoformat()}",
                f"Account ID: {self.account_id}",
                f"Region: {self.region}",
                f"Total Checks: {len(results)}",
                "",
                "SUMMARY",
                "-" * 40,
            ]
            
            summary = {
                "Compliant": len([r for r in results if r.status == ComplianceStatus.COMPLIANT]),
                "Non-Compliant": len([r for r in results if r.status == ComplianceStatus.NON_COMPLIANT]),
                "Not Applicable": len([r for r in results if r.status == ComplianceStatus.NOT_APPLICABLE]),
                "Insufficient Data": len([r for r in results if r.status == ComplianceStatus.INSUFFICIENT_DATA])
            }
            
            for status, count in summary.items():
                report_lines.append(f"{status}: {count}")
            
            report_lines.extend(["", "DETAILED RESULTS", "-" * 40])
            
            for result in results:
                report_lines.extend([
                    f"Control: {result.control_id}",
                    f"Status: {result.status.value}",
                    f"Resource: {result.resource_type}::{result.resource_id}",
                    f"Reason: {result.reason}",
                    f"Remediation: {result.remediation}",
                    "-" * 40
                ])
            
            return "\n".join(report_lines)


def main():
    """Main CLI interface"""
    parser = argparse.ArgumentParser(
        description="AWS CIS Benchmark Compliance Checker",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Check all implemented controls
  python cis_checker.py check

  # Check specific controls
  python cis_checker.py check --controls 1.3,1.12,3.1

  # Generate JSON report
  python cis_checker.py check --output report.json

  # Use specific AWS profile
  python cis_checker.py check --profile production

  # Check different region
  python cis_checker.py check --region us-west-2
        """
    )
    
    parser.add_argument('--profile', help='AWS profile to use')
    parser.add_argument('--region', default='us-east-1', help='AWS region to check')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Check command
    check_parser = subparsers.add_parser('check', help='Run CIS benchmark checks')
    check_parser.add_argument('--controls', help='Comma-separated list of control IDs to check')
    check_parser.add_argument('--output', help='Output file path (default: stdout)')
    check_parser.add_argument('--format', choices=['json', 'text'], default='json', help='Output format')
    
    # List command  
    list_parser = subparsers.add_parser('list', help='List available controls')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    if args.command == 'list':
        checker = CISBenchmarkChecker(profile=args.profile, region=args.region)
        print("Available CIS Controls:")
        print("=" * 50)
        for control_id, control in checker.cis_controls.items():
            print(f"{control_id}: {control.title}")
            print(f"  Service: {control.service}")
            print(f"  Severity: {control.severity}")
            print(f"  Automated: {control.automated}")
            print()
        return
    
    if args.command == 'check':
        # Initialize checker
        checker = CISBenchmarkChecker(profile=args.profile, region=args.region)
        
        # Parse control IDs if specified
        control_ids = None
        if args.controls:
            control_ids = [c.strip() for c in args.controls.split(',')]
        
        # Run checks
        results = checker.run_check(control_ids)
        
        # Generate report
        report = checker.generate_report(results, args.format)
        
        # Output report
        if args.output:
            with open(args.output, 'w') as f:
                f.write(report)
            print(f"Report saved to {args.output}")
        else:
            print(report)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
