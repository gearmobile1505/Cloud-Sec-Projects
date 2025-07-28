#!/usr/bin/env python3
"""
Unified CIS Benchmark Checker

Supports both AWS and Kubernetes CIS benchmark checking from a single interface.
"""

import argparse
import sys
import os
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    """Main function for unified CIS checker"""
    parser = argparse.ArgumentParser(description="Unified CIS Benchmark Checker for AWS and Kubernetes")
    parser.add_argument("platform", choices=["aws", "k8s", "kubernetes"], help="Target platform")
    parser.add_argument("command", choices=["check", "list"], help="Command to execute")
    parser.add_argument("--controls", help="Comma-separated list of control IDs to check")
    parser.add_argument("--format", choices=["json", "text"], default="json", help="Output format")
    parser.add_argument("--output", help="Output file path")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    
    # AWS-specific arguments
    parser.add_argument("--profile", help="AWS profile to use")
    parser.add_argument("--region", help="AWS region")
    
    # Kubernetes-specific arguments
    parser.add_argument("--kubeconfig", help="Path to kubeconfig file")
    parser.add_argument("--context", help="Kubernetes context to use")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Import and run appropriate checker
    if args.platform == "aws":
        try:
            from cis_checker import CISChecker
            
            checker = CISChecker(
                profile_name=args.profile,
                region_name=args.region
            )
            
            if args.command == "list":
                controls = checker.get_supported_controls()
                for control in controls:
                    print(f"{control.control_id}: {control.title} ({control.severity})")
                return
            
            elif args.command == "check":
                control_ids = None
                if args.controls:
                    control_ids = [c.strip() for c in args.controls.split(",")]
                
                results = checker.run_compliance_check(control_ids)
                report = checker.generate_report(results, args.format)
                
                if args.output:
                    with open(args.output, "w") as f:
                        f.write(report)
                    print(f"AWS CIS report saved to {args.output}")
                else:
                    print(report)
                    
        except ImportError as e:
            logger.error(f"AWS checker not available: {e}")
            sys.exit(1)
    
    elif args.platform in ["k8s", "kubernetes"]:
        try:
            from k8s_cis_checker import KubernetesCISChecker
            
            checker = KubernetesCISChecker(
                kubeconfig_path=args.kubeconfig,
                context=args.context
            )
            
            if args.command == "list":
                controls = checker.get_supported_controls()
                for control in controls:
                    print(f"{control.control_id}: {control.title} ({control.severity})")
                return
            
            elif args.command == "check":
                control_ids = None
                if args.controls:
                    control_ids = [c.strip() for c in args.controls.split(",")]
                
                results = checker.run_compliance_check(control_ids)
                report = checker.generate_report(results, args.format)
                
                if args.output:
                    with open(args.output, "w") as f:
                        f.write(report)
                    print(f"Kubernetes CIS report saved to {args.output}")
                else:
                    print(report)
                    
        except ImportError as e:
            logger.error(f"Kubernetes checker not available: {e}")
            logger.error("Make sure kubernetes python client is installed: pip install kubernetes")
            sys.exit(1)
        except Exception as e:
            logger.error(f"Error connecting to Kubernetes cluster: {e}")
            sys.exit(1)

if __name__ == "__main__":
    main()
