#!/usr/bin/env python3
"""
Unit tests for Security Group Remediation
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add parent directory to path to import the modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from security_group_remediation import SecurityGroupRemediator

class TestSecurityGroupRemediator(unittest.TestCase):
    
    @patch('security_group_remediation.boto3.Session')
    def setUp(self, mock_session):
        """Set up test fixtures"""
        mock_session_instance = Mock()
        mock_session.return_value = mock_session_instance
        mock_session_instance.client.return_value = Mock()
        mock_session_instance.resource.return_value = Mock()
        
        self.remediator = SecurityGroupRemediator('us-east-1')
    
    def test_find_open_security_groups_empty(self):
        """Test finding open security groups with no results"""
        # Mock the describe_security_groups response
        self.remediator.execute_operation = Mock(return_value={
            'SecurityGroups': []
        })
        
        result = self.remediator.find_open_security_groups()
        self.assertEqual(len(result), 0)
    
    def test_find_open_security_groups_with_open_ssh(self):
        """Test finding security groups with open SSH"""
        # Mock security group with open SSH
        mock_sg = {
            'GroupId': 'sg-12345678',
            'GroupName': 'test-sg',
            'Description': 'Test security group',
            'VpcId': 'vpc-12345678',
            'IpPermissions': [{
                'IpProtocol': 'tcp',
                'FromPort': 22,
                'ToPort': 22,
                'IpRanges': [{'CidrIp': '0.0.0.0/0', 'Description': 'SSH access'}]
            }]
        }
        
        self.remediator.execute_operation = Mock(return_value={
            'SecurityGroups': [mock_sg]
        })
        
        result = self.remediator.find_open_security_groups()
        
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]['GroupId'], 'sg-12345678')
        self.assertEqual(len(result[0]['OpenRules']), 1)
        self.assertEqual(result[0]['OpenRules'][0]['FromPort'], 22)
    
    def test_remediate_security_group_dry_run(self):
        """Test dry run remediation"""
        # Mock security group details
        mock_sg = {
            'GroupId': 'sg-12345678',
            'GroupName': 'test-sg',
            'IpPermissions': [{
                'IpProtocol': 'tcp',
                'FromPort': 22,
                'ToPort': 22,
                'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
            }]
        }
        
        self.remediator.execute_operation = Mock(return_value={
            'SecurityGroups': [mock_sg]
        })
        
        result = self.remediator.remediate_security_group('sg-12345678', dry_run=True)
        
        self.assertTrue(result['DryRun'])
        self.assertEqual(len(result['RulesRevoked']), 1)
        self.assertEqual(len(result['RulesAdded']), 3)  # Default private networks
        self.assertEqual(len(result['Errors']), 0)
    
    def test_generate_remediation_report(self):
        """Test report generation"""
        # Mock open security groups
        self.remediator.find_open_security_groups = Mock(return_value=[
            {
                'GroupId': 'sg-high-risk',
                'GroupName': 'high-risk-sg',
                'Description': 'High risk security group',
                'VpcId': 'vpc-12345678',
                'OpenRules': [{'FromPort': 22, 'IpProtocol': 'tcp'}]
            },
            {
                'GroupId': 'sg-medium-risk',
                'GroupName': 'medium-risk-sg',
                'Description': 'Medium risk security group',
                'VpcId': 'vpc-12345678',
                'OpenRules': [{'FromPort': 3306, 'IpProtocol': 'tcp'}]
            }
        ])
        
        report = self.remediator.generate_remediation_report()
        
        self.assertEqual(report['TotalSecurityGroups'], 2)
        self.assertEqual(report['Summary']['HighRisk'], 1)
        self.assertEqual(report['Summary']['MediumRisk'], 1)
        self.assertEqual(report['Summary']['LowRisk'], 0)

if __name__ == '__main__':
    unittest.main()
