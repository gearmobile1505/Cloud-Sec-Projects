#!/usr/bin/env python3
"""
Security Group Remediation Tool
Direct AWS security group remediation tool using boto3.
"""

import boto3
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional, List, Tuple
from botocore.exceptions import ClientError, NoCredentialsError
import argparse
import sys


class SecurityGroupRemediator:
    """
    AWS Security Group Remediation Tool using direct boto3 calls.
    """
    
    def __init__(self, region_name: str = 'us-east-1', profile_name: str = None):
        """Initialize the Security Group Remediator."""
        self.region_name = region_name
        self.profile_name = profile_name
        self.risky_ports = [22, 3389, 1433, 3306, 5432, 6379, 27017, 9200, 5601]
        
        # Configure logging
        self.logger = self._setup_logging()
        
        # Initialize boto3 session and client
        self.session = self._create_session()
        self.ec2_client = self._create_ec2_client()
    
    def _setup_logging(self) -> logging.Logger:
        """Setup logging configuration."""
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
        
        return logger
    
    def _create_session(self) -> boto3.Session:
        """Create boto3 session with optional profile."""
        try:
            if self.profile_name:
                session = boto3.Session(profile_name=self.profile_name)
                self.logger.info(f"Created session with profile: {self.profile_name}")
            else:
                session = boto3.Session()
                self.logger.info("Created default session")
            return session
        except Exception as e:
            self.logger.error(f"Failed to create session: {e}")
            raise
    
    def _create_ec2_client(self) -> boto3.client:
        """Create boto3 EC2 client."""
        try:
            client = self.session.client('ec2', region_name=self.region_name)
            self.logger.info(f"Created EC2 client in region {self.region_name}")
            return client
        except NoCredentialsError:
            self.logger.error("AWS credentials not found")
            raise
        except Exception as e:
            self.logger.error(f"Failed to create EC2 client: {e}")
            raise
    
    def find_open_security_groups(self, ports: List[int] = None) -> List[Dict[str, Any]]:
        """
        Find security groups with ingress rules open to 0.0.0.0/0.
        
        Args:
            ports (List[int]): Specific ports to check. If None, checks common risky ports.
            
        Returns:
            List of security groups with open ingress rules
        """
        if ports is None:
            ports = self.risky_ports
        
        try:
            # Get all security groups
            response = self.ec2_client.describe_security_groups()
            security_groups = response.get('SecurityGroups', [])
            
            open_sgs = []
            
            for sg in security_groups:
                sg_info = {
                    'GroupId': sg['GroupId'],
                    'GroupName': sg['GroupName'],
                    'Description': sg['Description'],
                    'VpcId': sg.get('VpcId'),
                    'OpenRules': []
                }
                
                # Check each ingress rule
                for rule in sg.get('IpPermissions', []):
                    from_port = rule.get('FromPort')
                    to_port = rule.get('ToPort')
                    protocol = rule.get('IpProtocol')
                    
                    # Check if rule allows 0.0.0.0/0
                    for ip_range in rule.get('IpRanges', []):
                        if ip_range.get('CidrIp') == '0.0.0.0/0':
                            # Check if it's a risky port or if we're checking all ports
                            if (ports == 'all' or 
                                protocol == '-1' or  # All protocols
                                (from_port is not None and any(port >= from_port and port <= to_port for port in ports))):
                                
                                sg_info['OpenRules'].append({
                                    'IpProtocol': protocol,
                                    'FromPort': from_port,
                                    'ToPort': to_port,
                                    'CidrIp': '0.0.0.0/0',
                                    'Description': ip_range.get('Description', 'No description')
                                })
                
                if sg_info['OpenRules']:
                    open_sgs.append(sg_info)
            
            return open_sgs
            
        except Exception as e:
            self.logger.error(f"Error finding open security groups: {e}")
            raise
    
    def remediate_security_group(self, group_id: str, replacement_cidrs: List[str] = None, 
                               dry_run: bool = True) -> Dict[str, Any]:
        """
        Remediate a security group by replacing 0.0.0.0/0 rules with restricted ones.
        
        Args:
            group_id (str): Security group ID to remediate
            replacement_cidrs (List[str]): List of CIDR blocks to replace 0.0.0.0/0 with
            dry_run (bool): If True, only show what would be changed without making changes
            
        Returns:
            Dict containing remediation results
        """
        if replacement_cidrs is None:
            replacement_cidrs = ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']  # Private networks
        
        try:
            # Get security group details
            response = self.ec2_client.describe_security_groups(GroupIds=[group_id])
            sg = response['SecurityGroups'][0]
            
            remediation_plan = {
                'GroupId': group_id,
                'GroupName': sg['GroupName'],
                'DryRun': dry_run,
                'RulesRevoked': [],
                'RulesAdded': [],
                'Errors': []
            }
            
            # Find rules with 0.0.0.0/0
            rules_to_revoke = []
            rules_to_add = []
            
            for rule in sg.get('IpPermissions', []):
                open_ranges = [ip_range for ip_range in rule.get('IpRanges', []) 
                             if ip_range.get('CidrIp') == '0.0.0.0/0']
                
                if open_ranges:
                    # Create revoke rule
                    revoke_rule = {
                        'IpProtocol': rule['IpProtocol'],
                        'IpRanges': open_ranges
                    }
                    
                    if 'FromPort' in rule:
                        revoke_rule['FromPort'] = rule['FromPort']
                    if 'ToPort' in rule:
                        revoke_rule['ToPort'] = rule['ToPort']
                    
                    rules_to_revoke.append(revoke_rule)
                    
                    # Create replacement rules
                    for cidr in replacement_cidrs:
                        add_rule = revoke_rule.copy()
                        add_rule['IpRanges'] = [{
                            'CidrIp': cidr,
                            'Description': f'Remediated from 0.0.0.0/0 - {open_ranges[0].get("Description", "")}'
                        }]
                        rules_to_add.append(add_rule)
            
            # Execute remediation
            if not dry_run:
                # Revoke open rules
                for rule in rules_to_revoke:
                    try:
                        self.ec2_client.revoke_security_group_ingress(
                            GroupId=group_id,
                            IpPermissions=[rule]
                        )
                        remediation_plan['RulesRevoked'].append(rule)
                        self.logger.info(f"Revoked rule: {rule}")
                    except Exception as e:
                        error_msg = f"Failed to revoke rule {rule}: {e}"
                        remediation_plan['Errors'].append(error_msg)
                        self.logger.error(error_msg)
                
                # Add replacement rules
                for rule in rules_to_add:
                    try:
                        self.ec2_client.authorize_security_group_ingress(
                            GroupId=group_id,
                            IpPermissions=[rule]
                        )
                        remediation_plan['RulesAdded'].append(rule)
                        self.logger.info(f"Added rule: {rule}")
                    except Exception as e:
                        error_msg = f"Failed to add rule {rule}: {e}"
                        remediation_plan['Errors'].append(error_msg)
                        self.logger.error(error_msg)
            else:
                remediation_plan['RulesRevoked'] = rules_to_revoke
                remediation_plan['RulesAdded'] = rules_to_add
                self.logger.info(f"DRY RUN: Would revoke {len(rules_to_revoke)} rules and add {len(rules_to_add)} rules")
            
            return remediation_plan
            
        except Exception as e:
            self.logger.error(f"Error remediating security group {group_id}: {e}")
            raise
    
    def bulk_remediate(self, replacement_cidrs: List[str] = None, 
                      ports: List[int] = None, dry_run: bool = True) -> List[Dict[str, Any]]:
        """
        Remediate all security groups with open ingress rules.
        
        Args:
            replacement_cidrs (List[str]): CIDRs to replace 0.0.0.0/0 with
            ports (List[int]): Specific ports to remediate
            dry_run (bool): If True, only show what would be changed
            
        Returns:
            List of remediation results for each security group
        """
        try:
            open_sgs = self.find_open_security_groups(ports)
            results = []
            
            self.logger.info(f"Found {len(open_sgs)} security groups with open rules")
            
            for sg in open_sgs:
                self.logger.info(f"Remediating security group: {sg['GroupId']} ({sg['GroupName']})")
                result = self.remediate_security_group(sg['GroupId'], replacement_cidrs, dry_run)
                results.append(result)
            
            return results
            
        except Exception as e:
            self.logger.error(f"Error in bulk remediation: {e}")
            raise
    
    def generate_remediation_report(self, output_file: str = None) -> Dict[str, Any]:
        """
        Generate a detailed report of security groups that need remediation.
        
        Args:
            output_file (str): Optional file path to save the report
            
        Returns:
            Dict containing the report data
        """
        try:
            open_sgs = self.find_open_security_groups('all')
            
            report = {
                'Timestamp': datetime.now().isoformat(),
                'Region': self.region_name,
                'TotalSecurityGroups': len(open_sgs),
                'SecurityGroups': [],
                'Summary': {
                    'HighRisk': 0,    # SSH, RDP
                    'MediumRisk': 0,  # Database ports
                    'LowRisk': 0      # Other ports
                }
            }
            
            high_risk_ports = [22, 3389]
            medium_risk_ports = [1433, 3306, 5432, 6379, 27017]
            
            for sg in open_sgs:
                sg_report = {
                    'GroupId': sg['GroupId'],
                    'GroupName': sg['GroupName'],
                    'Description': sg['Description'],
                    'VpcId': sg.get('VpcId', 'EC2-Classic'),
                    'RiskLevel': 'Low',
                    'OpenRules': sg['OpenRules']
                }
                
                # Determine risk level
                for rule in sg['OpenRules']:
                    if rule['IpProtocol'] == '-1':  # All protocols
                        sg_report['RiskLevel'] = 'High'
                        break
                    elif rule['FromPort'] in high_risk_ports:
                        sg_report['RiskLevel'] = 'High'
                    elif rule['FromPort'] in medium_risk_ports and sg_report['RiskLevel'] != 'High':
                        sg_report['RiskLevel'] = 'Medium'
                
                report['SecurityGroups'].append(sg_report)
                report['Summary'][f"{sg_report['RiskLevel']}Risk"] += 1
            
            if output_file:
                with open(output_file, 'w') as f:
                    json.dump(report, f, indent=2, default=str)
                self.logger.info(f"Report saved to {output_file}")
            
            return report
            
        except Exception as e:
            self.logger.error(f"Error generating report: {e}")
            raise
    
    def print_response(self, response: Dict[str, Any], indent: int = 2) -> None:
        """Pretty print response data."""
        try:
            print(json.dumps(response, indent=indent, default=str))
        except Exception as e:
            self.logger.error(f"Error printing response: {e}")
            print(str(response))


def main():
    """Main function with enhanced command line interface."""
    parser = argparse.ArgumentParser(description='Security Group Remediation Tool')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    parser.add_argument('--profile', help='AWS profile name')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Find command
    find_parser = subparsers.add_parser('find', help='Find security groups with open rules')
    find_parser.add_argument('--ports', help='Comma-separated list of ports to check (default: common risky ports)')
    find_parser.add_argument('--output', help='Output file for results (JSON format)')
    
    # Remediate command
    remediate_parser = subparsers.add_parser('remediate', help='Remediate specific security group')
    remediate_parser.add_argument('group_id', help='Security group ID to remediate')
    remediate_parser.add_argument('--cidrs', help='Comma-separated list of replacement CIDRs')
    remediate_parser.add_argument('--dry-run', action='store_true', help='Show changes without applying them')
    
    # Bulk remediate command
    bulk_parser = subparsers.add_parser('bulk-remediate', help='Remediate all open security groups')
    bulk_parser.add_argument('--cidrs', help='Comma-separated list of replacement CIDRs')
    bulk_parser.add_argument('--ports', help='Comma-separated list of ports to remediate')
    bulk_parser.add_argument('--dry-run', action='store_true', help='Show changes without applying them')
    
    # Report command
    report_parser = subparsers.add_parser('report', help='Generate remediation report')
    report_parser.add_argument('--output', help='Output file for report (JSON format)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    try:
        # Initialize the remediator
        remediator = SecurityGroupRemediator(
            region_name=args.region,
            profile_name=args.profile
        )
        
        if args.command == 'find':
            ports = None
            if args.ports:
                if args.ports.lower() == 'all':
                    ports = 'all'
                else:
                    ports = [int(p.strip()) for p in args.ports.split(',')]
            
            open_sgs = remediator.find_open_security_groups(ports)
            
            if args.output:
                with open(args.output, 'w') as f:
                    json.dump(open_sgs, f, indent=2, default=str)
                print(f"Results saved to {args.output}")
            else:
                remediator.print_response({'OpenSecurityGroups': open_sgs})
        
        elif args.command == 'remediate':
            cidrs = None
            if args.cidrs:
                cidrs = [c.strip() for c in args.cidrs.split(',')]
            
            result = remediator.remediate_security_group(
                args.group_id, 
                replacement_cidrs=cidrs,
                dry_run=args.dry_run
            )
            remediator.print_response(result)
        
        elif args.command == 'bulk-remediate':
            cidrs = None
            if args.cidrs:
                cidrs = [c.strip() for c in args.cidrs.split(',')]
            
            ports = None
            if args.ports:
                if args.ports.lower() == 'all':
                    ports = 'all'
                else:
                    ports = [int(p.strip()) for p in args.ports.split(',')]
            
            results = remediator.bulk_remediate(
                replacement_cidrs=cidrs,
                ports=ports,
                dry_run=args.dry_run
            )
            remediator.print_response({'BulkRemediationResults': results})
        
        elif args.command == 'report':
            report = remediator.generate_remediation_report(args.output)
            if not args.output:
                remediator.print_response(report)
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
