#!/usr/bin/env python3
"""
Unit tests for AWS Resource Manager
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add parent directory to path to import the module
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from aws_resource_manager import AWSResourceManager

class TestAWSResourceManager(unittest.TestCase):
    
    @patch('aws_resource_manager.boto3.Session')
    def test_initialization(self, mock_session):
        """Test AWSResourceManager initialization"""
        mock_session_instance = Mock()
        mock_session.return_value = mock_session_instance
        mock_session_instance.client.return_value = Mock()
        mock_session_instance.resource.return_value = Mock()
        
        manager = AWSResourceManager('ec2', 'us-east-1')
        
        self.assertEqual(manager.service_name, 'ec2')
        self.assertEqual(manager.region_name, 'us-east-1')
        self.assertIsNone(manager.profile_name)
    
    @patch('aws_resource_manager.boto3.Session')
    def test_initialization_with_profile(self, mock_session):
        """Test AWSResourceManager initialization with profile"""
        mock_session_instance = Mock()
        mock_session.return_value = mock_session_instance
        mock_session_instance.client.return_value = Mock()
        mock_session_instance.resource.return_value = Mock()
        
        manager = AWSResourceManager('s3', 'us-west-2', 'test-profile')
        
        self.assertEqual(manager.service_name, 's3')
        self.assertEqual(manager.region_name, 'us-west-2')
        self.assertEqual(manager.profile_name, 'test-profile')
    
    @patch('aws_resource_manager.boto3.Session')
    def test_get_available_operations(self, mock_session):
        """Test getting available operations"""
        mock_session_instance = Mock()
        mock_session.return_value = mock_session_instance
        mock_client = Mock()
        mock_session_instance.client.return_value = mock_client
        mock_session_instance.resource.return_value = Mock()
        
        # Mock dir() to return some operations
        with patch('builtins.dir') as mock_dir:
            mock_dir.return_value = ['_private_method', 'describe_instances', 'list_buckets', 'some_other_method']
            
            # Mock callable check
            with patch('builtins.callable') as mock_callable:
                mock_callable.return_value = True
                
                manager = AWSResourceManager('ec2', 'us-east-1')
                operations = manager.get_available_operations()
                
                # Should exclude private methods and include public ones
                expected_operations = ['describe_instances', 'list_buckets', 'some_other_method']
                self.assertEqual(sorted(operations), sorted(expected_operations))

if __name__ == '__main__':
    unittest.main()
