#!/usr/bin/env python3
"""
Test script to verify CIS Benchmark Checker installation and basic functionality
"""

import sys
import subprocess
import importlib.util
import os

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 7):
        print("❌ Python 3.7+ required. Current version:", sys.version)
        return False
    print(f"✅ Python version: {sys.version.split()[0]}")
    return True

def check_dependencies():
    """Check if required dependencies are installed"""
    required_packages = [
        'boto3',
        'kubernetes', 
        'yaml'
    ]
    
    missing_packages = []
    for package in required_packages:
        if importlib.util.find_spec(package) is None:
            missing_packages.append(package)
        else:
            print(f"✅ {package} is installed")
    
    if missing_packages:
        print(f"❌ Missing packages: {', '.join(missing_packages)}")
        print("Install with: pip install -r requirements.txt")
        return False
    
    return True

def check_aws_credentials():
    """Check if AWS credentials are configured"""
    try:
        result = subprocess.run(['aws', 'sts', 'get-caller-identity'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ AWS credentials are configured")
            return True
        else:
            print("❌ AWS credentials not configured")
            print("Configure with: aws configure")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("❌ AWS CLI not found or not responsive")
        return False

def check_kubernetes_access():
    """Check if Kubernetes cluster is accessible"""
    try:
        result = subprocess.run(['kubectl', 'cluster-info'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ Kubernetes cluster is accessible")
            return True
        else:
            print("⚠️  Kubernetes cluster not accessible (optional for AWS-only testing)")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("⚠️  kubectl not found (optional for AWS-only testing)")
        return False

def test_aws_checker():
    """Test AWS CIS checker functionality"""
    try:
        # Import and test AWS checker
        sys.path.append('.')
        from cis_checker import CISBenchmarkChecker
        
        checker = CISBenchmarkChecker()
        controls = checker.cis_controls
        
        if controls:
            print(f"✅ AWS CIS checker working - {len(controls)} controls available")
            return True
        else:
            print("❌ AWS CIS checker not returning controls")
            return False
            
    except Exception as e:
        print(f"❌ AWS CIS checker failed: {e}")
        return False

def test_kubernetes_checker():
    """Test Kubernetes CIS checker functionality"""
    try:
        # Import and test Kubernetes checker
        sys.path.append('.')
        from k8s_cis_checker import KubernetesCISChecker
        
        # This might fail if no k8s cluster, but we can still test imports
        checker = KubernetesCISChecker()
        controls = checker.get_supported_controls()
        
        if controls:
            print(f"✅ Kubernetes CIS checker working - {len(controls)} controls available")
            return True
        else:
            print("❌ Kubernetes CIS checker not returning controls")
            return False
            
    except Exception as e:
        print(f"⚠️  Kubernetes CIS checker failed (may be expected if no cluster): {e}")
        return False

def test_unified_checker():
    """Test unified checker imports"""
    try:
        sys.path.append('.')
        import unified_cis_checker
        print("✅ Unified CIS checker imports successfully")
        return True
    except Exception as e:
        print(f"❌ Unified CIS checker failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🔍 CIS Benchmark Checker - Installation Test")
    print("=" * 50)
    
    tests = [
        ("Python Version", check_python_version),
        ("Dependencies", check_dependencies),
        ("AWS Credentials", check_aws_credentials),
        ("Kubernetes Access", check_kubernetes_access),
        ("AWS CIS Checker", test_aws_checker),
        ("Kubernetes CIS Checker", test_kubernetes_checker),
        ("Unified Checker", test_unified_checker),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n🧪 Testing {test_name}...")
        if test_func():
            passed += 1
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} passed")
    
    if passed >= 5:  # Essential tests
        print("✅ Installation appears to be working correctly!")
        print("\n🚀 Next steps:")
        print("   1. For AWS: python3 cis_checker.py list")
        print("   2. For Kubernetes: python3 k8s_cis_checker.py list")
        print("   3. Deploy test infrastructure: cd ../tf && ./deploy.sh apply")
    else:
        print("❌ Some critical components are not working")
        print("   Please check the requirements and setup")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
