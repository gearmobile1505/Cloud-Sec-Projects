#!/usr/bin/env python3
"""
Extended CIS Control Implementations

Additional CIS benchmark checks for AWS services including IAM password policies,
KMS key management, S3 security, and advanced networking controls.
"""

import boto3
import json
import logging
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

from cis_checker import CISBenchmarkChecker, ComplianceResult, ComplianceStatus

logger = logging.getLogger(__name__)

class ExtendedCISChecker(CISBenchmarkChecker):
    """Extended CIS checker with additional control implementations"""
    
    def check_control_1_5(self) -> List[ComplianceResult]:
        """1.5 - Ensure IAM password policy requires minimum length of 14 or greater"""
        results = []
        
        try:
            password_policy = self.iam.get_account_password_policy()['PasswordPolicy']
            min_length = password_policy.get('MinimumPasswordLength', 0)
            
            if min_length >= 14:
                results.append(ComplianceResult(
                    control_id="1.5",
                    status=ComplianceStatus.COMPLIANT,
                    resource_id="account",
                    resource_type="IAM::PasswordPolicy",
                    reason=f"Password minimum length is {min_length}",
                    remediation="No action needed",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
            else:
                results.append(ComplianceResult(
                    control_id="1.5",
                    status=ComplianceStatus.NON_COMPLIANT,
                    resource_id="account",
                    resource_type="IAM::PasswordPolicy",
                    reason=f"Password minimum length is {min_length}, should be 14+",
                    remediation="Update password policy to require minimum 14 characters",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
                
        except self.iam.exceptions.NoSuchEntityException:
            results.append(ComplianceResult(
                control_id="1.5",
                status=ComplianceStatus.NON_COMPLIANT,
                resource_id="account",
                resource_type="IAM::PasswordPolicy",
                reason="No password policy configured",
                remediation="Create IAM password policy with minimum 14 character length",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
        except Exception as e:
            logger.error(f"Error checking control 1.5: {e}")
            results.append(ComplianceResult(
                control_id="1.5",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="account",
                resource_type="IAM::PasswordPolicy",
                reason=f"Error during check: {e}",
                remediation="Review IAM permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def check_control_1_6(self) -> List[ComplianceResult]:
        """1.6 - Ensure IAM password policy prevents password reuse"""
        results = []
        
        try:
            password_policy = self.iam.get_account_password_policy()['PasswordPolicy']
            password_reuse_prevention = password_policy.get('PasswordReusePrevention', 0)
            
            if password_reuse_prevention >= 24:
                results.append(ComplianceResult(
                    control_id="1.6",
                    status=ComplianceStatus.COMPLIANT,
                    resource_id="account",
                    resource_type="IAM::PasswordPolicy",
                    reason=f"Password reuse prevention set to {password_reuse_prevention}",
                    remediation="No action needed",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
            else:
                results.append(ComplianceResult(
                    control_id="1.6",
                    status=ComplianceStatus.NON_COMPLIANT,
                    resource_id="account",
                    resource_type="IAM::PasswordPolicy",
                    reason=f"Password reuse prevention is {password_reuse_prevention}, should be 24+",
                    remediation="Update password policy to prevent reuse of last 24 passwords",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
                
        except self.iam.exceptions.NoSuchEntityException:
            results.append(ComplianceResult(
                control_id="1.6",
                status=ComplianceStatus.NON_COMPLIANT,
                resource_id="account",
                resource_type="IAM::PasswordPolicy",
                reason="No password policy configured",
                remediation="Create IAM password policy with password reuse prevention",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
        except Exception as e:
            logger.error(f"Error checking control 1.6: {e}")
            results.append(ComplianceResult(
                control_id="1.6",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="account",
                resource_type="IAM::PasswordPolicy",
                reason=f"Error during check: {e}",
                remediation="Review IAM permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def check_control_3_2(self) -> List[ComplianceResult]:
        """3.2 - Ensure CloudTrail log file validation is enabled"""
        results = []
        
        try:
            trails = self.cloudtrail.describe_trails()['trailList']
            
            if not trails:
                results.append(ComplianceResult(
                    control_id="3.2",
                    status=ComplianceStatus.NON_COMPLIANT,
                    resource_id="N/A",
                    resource_type="CloudTrail",
                    reason="No CloudTrail trails found",
                    remediation="Create CloudTrail with log file validation enabled",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
                return results
            
            for trail in trails:
                trail_name = trail['Name']
                log_file_validation = trail.get('LogFileValidationEnabled', False)
                
                if log_file_validation:
                    results.append(ComplianceResult(
                        control_id="3.2",
                        status=ComplianceStatus.COMPLIANT,
                        resource_id=trail_name,
                        resource_type="CloudTrail::Trail",
                        reason="Log file validation is enabled",
                        remediation="No action needed",
                        timestamp=datetime.now(timezone.utc).isoformat(),
                        region=self.region,
                        account_id=self.account_id
                    ))
                else:
                    results.append(ComplianceResult(
                        control_id="3.2",
                        status=ComplianceStatus.NON_COMPLIANT,
                        resource_id=trail_name,
                        resource_type="CloudTrail::Trail",
                        reason="Log file validation is disabled",
                        remediation="Enable log file validation for CloudTrail",
                        timestamp=datetime.now(timezone.utc).isoformat(),
                        region=self.region,
                        account_id=self.account_id
                    ))
                    
        except Exception as e:
            logger.error(f"Error checking control 3.2: {e}")
            results.append(ComplianceResult(
                control_id="3.2",
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

    def check_control_3_3(self) -> List[ComplianceResult]:
        """3.3 - Ensure the S3 bucket used to store CloudTrail logs is not publicly accessible"""
        results = []
        
        try:
            trails = self.cloudtrail.describe_trails()['trailList']
            
            if not trails:
                results.append(ComplianceResult(
                    control_id="3.3",
                    status=ComplianceStatus.NOT_APPLICABLE,
                    resource_id="N/A",
                    resource_type="CloudTrail",
                    reason="No CloudTrail trails found",
                    remediation="Create CloudTrail with secure S3 bucket",
                    timestamp=datetime.now(timezone.utc).isoformat(),
                    region=self.region,
                    account_id=self.account_id
                ))
                return results
            
            for trail in trails:
                trail_name = trail['Name']
                s3_bucket = trail.get('S3BucketName')
                
                if not s3_bucket:
                    continue
                
                try:
                    # Check bucket ACL
                    acl = self.s3.get_bucket_acl(Bucket=s3_bucket)
                    public_read = False
                    public_write = False
                    
                    for grant in acl['Grants']:
                        grantee = grant.get('Grantee', {})
                        if grantee.get('Type') == 'Group':
                            uri = grantee.get('URI', '')
                            if 'AllUsers' in uri or 'AuthenticatedUsers' in uri:
                                permission = grant['Permission']
                                if permission in ['READ', 'FULL_CONTROL']:
                                    public_read = True
                                if permission in ['WRITE', 'FULL_CONTROL']:
                                    public_write = True
                    
                    # Check bucket policy for public access
                    try:
                        bucket_policy = self.s3.get_bucket_policy(Bucket=s3_bucket)
                        policy = json.loads(bucket_policy['Policy'])
                        
                        for statement in policy.get('Statement', []):
                            principal = statement.get('Principal')
                            if principal == '*' or (isinstance(principal, dict) and principal.get('AWS') == '*'):
                                effect = statement.get('Effect')
                                if effect == 'Allow':
                                    public_read = True
                                    
                    except self.s3.exceptions.NoSuchBucketPolicy:
                        pass  # No bucket policy is fine
                    
                    # Check public access block
                    try:
                        public_access_block = self.s3.get_public_access_block(Bucket=s3_bucket)
                        pab = public_access_block['PublicAccessBlockConfiguration']
                        
                        if not (pab.get('BlockPublicAcls', False) and 
                               pab.get('IgnorePublicAcls', False) and
                               pab.get('BlockPublicPolicy', False) and
                               pab.get('RestrictPublicBuckets', False)):
                            public_read = True
                            
                    except self.s3.exceptions.NoSuchPublicAccessBlockConfiguration:
                        public_read = True  # No public access block means potentially public
                    
                    if public_read or public_write:
                        results.append(ComplianceResult(
                            control_id="3.3",
                            status=ComplianceStatus.NON_COMPLIANT,
                            resource_id=s3_bucket,
                            resource_type="S3::Bucket",
                            reason="CloudTrail S3 bucket has public access",
                            remediation="Enable S3 public access block and review bucket policy/ACL",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
                    else:
                        results.append(ComplianceResult(
                            control_id="3.3",
                            status=ComplianceStatus.COMPLIANT,
                            resource_id=s3_bucket,
                            resource_type="S3::Bucket",
                            reason="CloudTrail S3 bucket is not publicly accessible",
                            remediation="No action needed",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
                        
                except Exception as e:
                    logger.warning(f"Could not check bucket {s3_bucket}: {e}")
                    results.append(ComplianceResult(
                        control_id="3.3",
                        status=ComplianceStatus.INSUFFICIENT_DATA,
                        resource_id=s3_bucket,
                        resource_type="S3::Bucket",
                        reason=f"Error checking bucket: {e}",
                        remediation="Review S3 permissions and retry",
                        timestamp=datetime.now(timezone.utc).isoformat(),
                        region=self.region,
                        account_id=self.account_id
                    ))
                    
        except Exception as e:
            logger.error(f"Error checking control 3.3: {e}")
            results.append(ComplianceResult(
                control_id="3.3",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="N/A",
                resource_type="S3",
                reason=f"Error during check: {e}",
                remediation="Review permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def check_control_3_8(self) -> List[ComplianceResult]:
        """3.8 - Ensure rotation for customer-created CMKs is enabled"""
        results = []
        
        try:
            paginator = self.kms.get_paginator('list_keys')
            
            for page in paginator.paginate():
                for key in page['Keys']:
                    key_id = key['KeyId']
                    
                    try:
                        # Get key details
                        key_details = self.kms.describe_key(KeyId=key_id)['KeyMetadata']
                        
                        # Skip AWS managed keys
                        if key_details.get('KeyManager') == 'AWS':
                            continue
                        
                        # Check if key rotation is enabled
                        rotation_status = self.kms.get_key_rotation_status(KeyId=key_id)
                        key_rotation_enabled = rotation_status['KeyRotationEnabled']
                        
                        if key_rotation_enabled:
                            results.append(ComplianceResult(
                                control_id="3.8",
                                status=ComplianceStatus.COMPLIANT,
                                resource_id=key_id,
                                resource_type="KMS::Key",
                                reason="Key rotation is enabled",
                                remediation="No action needed",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                region=self.region,
                                account_id=self.account_id
                            ))
                        else:
                            results.append(ComplianceResult(
                                control_id="3.8",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=key_id,
                                resource_type="KMS::Key",
                                reason="Key rotation is disabled",
                                remediation="Enable automatic key rotation",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                region=self.region,
                                account_id=self.account_id
                            ))
                            
                    except Exception as e:
                        logger.warning(f"Could not check key {key_id}: {e}")
                        results.append(ComplianceResult(
                            control_id="3.8",
                            status=ComplianceStatus.INSUFFICIENT_DATA,
                            resource_id=key_id,
                            resource_type="KMS::Key",
                            reason=f"Error checking key: {e}",
                            remediation="Review KMS permissions and retry",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
                        
        except Exception as e:
            logger.error(f"Error checking control 3.8: {e}")
            results.append(ComplianceResult(
                control_id="3.8",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="N/A",
                resource_type="KMS",
                reason=f"Error during check: {e}",
                remediation="Review KMS permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def check_control_5_5(self) -> List[ComplianceResult]:
        """5.5 - Ensure VPC flow logging is enabled in all VPCs"""
        results = []
        
        try:
            # Get all VPCs
            vpcs = self.ec2.describe_vpcs()['Vpcs']
            
            # Get all flow logs
            flow_logs = self.ec2.describe_flow_logs()['FlowLogs']
            
            # Create mapping of VPC to flow logs
            vpc_flow_logs = {}
            for flow_log in flow_logs:
                if flow_log['ResourceType'] == 'VPC':
                    vpc_id = flow_log['ResourceId']
                    if vpc_id not in vpc_flow_logs:
                        vpc_flow_logs[vpc_id] = []
                    vpc_flow_logs[vpc_id].append(flow_log)
            
            for vpc in vpcs:
                vpc_id = vpc['VpcId']
                
                if vpc_id in vpc_flow_logs:
                    # Check if any flow log is active
                    active_flow_logs = [fl for fl in vpc_flow_logs[vpc_id] 
                                      if fl['FlowLogStatus'] == 'ACTIVE']
                    
                    if active_flow_logs:
                        results.append(ComplianceResult(
                            control_id="5.5",
                            status=ComplianceStatus.COMPLIANT,
                            resource_id=vpc_id,
                            resource_type="EC2::VPC",
                            reason="VPC Flow Logs are enabled",
                            remediation="No action needed",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
                    else:
                        results.append(ComplianceResult(
                            control_id="5.5",
                            status=ComplianceStatus.NON_COMPLIANT,
                            resource_id=vpc_id,
                            resource_type="EC2::VPC",
                            reason="VPC Flow Logs exist but are not active",
                            remediation="Activate VPC Flow Logs",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            region=self.region,
                            account_id=self.account_id
                        ))
                else:
                    results.append(ComplianceResult(
                        control_id="5.5",
                        status=ComplianceStatus.NON_COMPLIANT,
                        resource_id=vpc_id,
                        resource_type="EC2::VPC",
                        reason="No VPC Flow Logs configured",
                        remediation="Enable VPC Flow Logs",
                        timestamp=datetime.now(timezone.utc).isoformat(),
                        region=self.region,
                        account_id=self.account_id
                    ))
                    
        except Exception as e:
            logger.error(f"Error checking control 5.5: {e}")
            results.append(ComplianceResult(
                control_id="5.5",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="N/A",
                resource_type="EC2::VPC",
                reason=f"Error during check: {e}",
                remediation="Review EC2 permissions and retry",
                timestamp=datetime.now(timezone.utc).isoformat(),
                region=self.region,
                account_id=self.account_id
            ))
            
        return results

    def run_check(self, control_ids: Optional[List[str]] = None) -> List[ComplianceResult]:
        """
        Run extended CIS benchmark checks
        
        Args:
            control_ids: Specific control IDs to check (if None, check all)
            
        Returns:
            List of compliance results
        """
        # Add extended check methods
        extended_check_methods = {
            "1.5": self.check_control_1_5,
            "1.6": self.check_control_1_6,
            "3.2": self.check_control_3_2,
            "3.3": self.check_control_3_3,
            "3.8": self.check_control_3_8,
            "5.5": self.check_control_5_5,
        }
        
        # Get results from parent class
        results = super().run_check(control_ids)
        
        # If specific controls were requested, filter extended methods
        if control_ids is None:
            check_control_ids = list(extended_check_methods.keys())
        else:
            check_control_ids = [cid for cid in control_ids if cid in extended_check_methods]
        
        # Run extended checks
        for control_id in check_control_ids:
            if control_id in extended_check_methods:
                logger.info(f"Running extended check for control {control_id}")
                try:
                    extended_results = extended_check_methods[control_id]()
                    results.extend(extended_results)
                except Exception as e:
                    logger.error(f"Error in extended check for control {control_id}: {e}")
                    results.append(ComplianceResult(
                        control_id=control_id,
                        status=ComplianceStatus.INSUFFICIENT_DATA,
                        resource_id="N/A",
                        resource_type="Unknown",
                        reason=f"Extended check failed: {e}",
                        remediation="Review implementation and retry",
                        timestamp=datetime.now(timezone.utc).isoformat(),
                        region=self.region,
                        account_id=self.account_id
                    ))
        
        return results

def main():
    """Main CLI interface for extended CIS checker"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Extended AWS CIS Benchmark Compliance Checker",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--profile', help='AWS profile to use')
    parser.add_argument('--region', default='us-east-1', help='AWS region to check')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Check command
    check_parser = subparsers.add_parser('check', help='Run extended CIS benchmark checks')
    check_parser.add_argument('--controls', help='Comma-separated list of control IDs to check')
    check_parser.add_argument('--output', help='Output file path (default: stdout)')
    check_parser.add_argument('--format', choices=['json', 'text'], default='json', help='Output format')
    
    # List command  
    list_parser = subparsers.add_parser('list', help='List available controls')
    
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    if args.command == 'list':
        checker = ExtendedCISChecker(profile=args.profile, region=args.region)
        print("Available Extended CIS Controls:")
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
        checker = ExtendedCISChecker(profile=args.profile, region=args.region)
        
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
