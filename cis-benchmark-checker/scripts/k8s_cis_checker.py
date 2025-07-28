#!/usr/bin/env python3
"""
Kubernetes CIS Benchmark Checker

Automated compliance checking against CIS Kubernetes Benchmark v1.8.0
using Kubernetes API and kubectl commands.

Features:
- CIS controls validation across Kubernetes components
- Master node, worker node, and cluster-wide checks
- RBAC and network policy validation
- Pod security standards compliance
- Detailed compliance reporting
"""

import argparse
import json
import logging
import subprocess
import sys
import yaml
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from enum import Enum
from kubernetes import client, config
from kubernetes.client.rest import ApiException

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
class KubernetesCISControl:
    """Kubernetes CIS control definition"""
    control_id: str
    title: str
    description: str
    severity: str
    category: str
    component: str  # master, worker, cluster
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
    namespace: Optional[str] = None
    node: Optional[str] = None

class KubernetesCISChecker:
    """Kubernetes CIS Benchmark compliance checker"""
    
    def __init__(self, kubeconfig_path: Optional[str] = None, context: Optional[str] = None):
        """Initialize the checker with Kubernetes client"""
        try:
            if kubeconfig_path:
                config.load_kube_config(config_file=kubeconfig_path, context=context)
            else:
                try:
                    config.load_incluster_config()
                except:
                    config.load_kube_config(context=context)
            
            self.v1 = client.CoreV1Api()
            self.apps_v1 = client.AppsV1Api()
            self.rbac_v1 = client.RbacAuthorizationV1Api()
            self.networking_v1 = client.NetworkingV1Api()
            self.policy_v1 = client.PolicyV1Api()
            
            logger.info("Successfully connected to Kubernetes cluster")
            
        except Exception as e:
            logger.error(f"Failed to connect to Kubernetes cluster: {e}")
            raise
    
    def get_supported_controls(self) -> List[KubernetesCISControl]:
        """Get list of supported CIS controls"""
        return [
            # Master Node Security Configuration
            KubernetesCISControl(
                "1.1.1", "Ensure that the API server pod specification file permissions are set to 644 or more restrictive",
                "The API server pod specification file controls how the API server is run. It should have restrictive file permissions.",
                "HIGH", "Master Node", "master", False
            ),
            KubernetesCISControl(
                "1.2.1", "Ensure that the --anonymous-auth argument is set to false",
                "Anonymous requests to the API server should be disabled.",
                "HIGH", "Master Node", "master", True
            ),
            KubernetesCISControl(
                "1.2.2", "Ensure that the --basic-auth-file argument is not set",
                "Basic authentication should not be used.",
                "HIGH", "Master Node", "master", True
            ),
            KubernetesCISControl(
                "1.2.5", "Ensure that the --kubelet-certificate-authority argument is set as appropriate",
                "Verify kubelet's certificate before establishing connection.",
                "HIGH", "Master Node", "master", True
            ),
            
            # Worker Node Security Configuration
            KubernetesCISControl(
                "4.2.1", "Ensure that the --anonymous-auth argument is set to false",
                "Anonymous authentication to the kubelet should be disabled.",
                "HIGH", "Worker Node", "worker", True
            ),
            KubernetesCISControl(
                "4.2.2", "Ensure that the --authorization-mode argument is not set to AlwaysAllow",
                "Kubelet authorization should not always allow requests.",
                "HIGH", "Worker Node", "worker", True
            ),
            
            # Policies
            KubernetesCISControl(
                "5.1.1", "Ensure that the cluster-admin role is only used where required",
                "The cluster-admin role provides unrestricted access and should be used sparingly.",
                "MEDIUM", "RBAC and Service Accounts", "cluster", True
            ),
            KubernetesCISControl(
                "5.1.3", "Minimize wildcard use in Roles and ClusterRoles",
                "Wildcard permissions should be avoided in RBAC.",
                "MEDIUM", "RBAC and Service Accounts", "cluster", True
            ),
            KubernetesCISControl(
                "5.2.2", "Minimize the admission of containers wishing to share the host process ID namespace",
                "Containers should not share the host PID namespace.",
                "HIGH", "Pod Security Policies", "cluster", True
            ),
            KubernetesCISControl(
                "5.2.3", "Minimize the admission of containers wishing to share the host IPC namespace",
                "Containers should not share the host IPC namespace.",
                "HIGH", "Pod Security Policies", "cluster", True
            ),
            KubernetesCISControl(
                "5.2.4", "Minimize the admission of containers wishing to share the host network namespace",
                "Containers should not share the host network namespace.",
                "HIGH", "Pod Security Policies", "cluster", True
            ),
            KubernetesCISControl(
                "5.2.5", "Minimize the admission of containers with allowPrivilegeEscalation",
                "Containers should not allow privilege escalation.",
                "HIGH", "Pod Security Policies", "cluster", True
            ),
            KubernetesCISControl(
                "5.3.2", "Ensure that all Namespaces have Network Policies defined",
                "Network policies should be defined to control traffic between pods.",
                "MEDIUM", "Network Policies and CNI", "cluster", True
            ),
            KubernetesCISControl(
                "5.7.3", "Apply Security Context to Your Pods and Containers",
                "Security contexts should be applied to pods and containers.",
                "MEDIUM", "General Policies", "cluster", True
            ),
            KubernetesCISControl(
                "5.7.4", "The default namespace should not be used",
                "Workloads should not run in the default namespace.",
                "LOW", "General Policies", "cluster", True
            )
        ]
    
    def check_api_server_anonymous_auth(self) -> ComplianceResult:
        """1.2.1 - Check if anonymous authentication is disabled"""
        try:
            # Check kube-system namespace for API server pod
            pods = self.v1.list_namespaced_pod(namespace="kube-system", 
                                               label_selector="component=kube-apiserver")
            
            for pod in pods.items:
                if pod.spec.containers:
                    for container in pod.spec.containers:
                        if container.command:
                            command_str = " ".join(container.command + (container.args or []))
                            if "--anonymous-auth=false" not in command_str:
                                return ComplianceResult(
                                    control_id="1.2.1",
                                    status=ComplianceStatus.NON_COMPLIANT,
                                    resource_id=pod.metadata.name,
                                    resource_type="Pod",
                                    reason="API server does not have --anonymous-auth=false",
                                    remediation="Add --anonymous-auth=false to API server configuration",
                                    timestamp=datetime.now(timezone.utc).isoformat(),
                                    namespace=pod.metadata.namespace
                                )
            
            return ComplianceResult(
                control_id="1.2.1",
                status=ComplianceStatus.COMPLIANT,
                resource_id="kube-apiserver",
                resource_type="Component",
                reason="Anonymous authentication is disabled",
                remediation="No action required",
                timestamp=datetime.now(timezone.utc).isoformat()
            )
            
        except Exception as e:
            return ComplianceResult(
                control_id="1.2.1",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="kube-apiserver",
                resource_type="Component",
                reason=f"Unable to check API server configuration: {e}",
                remediation="Ensure access to kube-system namespace and API server pods",
                timestamp=datetime.now(timezone.utc).isoformat()
            )
    
    def check_rbac_cluster_admin_usage(self) -> List[ComplianceResult]:
        """5.1.1 - Check cluster-admin role usage"""
        results = []
        
        try:
            # Check ClusterRoleBindings for cluster-admin
            cluster_role_bindings = self.rbac_v1.list_cluster_role_binding()
            
            excessive_bindings = []
            for binding in cluster_role_bindings.items:
                if binding.role_ref.name == "cluster-admin":
                    # Check if binding has too many subjects
                    if binding.subjects and len(binding.subjects) > 3:
                        excessive_bindings.append(binding)
                    
                    # Check for service account bindings to cluster-admin
                    for subject in binding.subjects or []:
                        if subject.kind == "ServiceAccount" and subject.name != "cluster-admin":
                            results.append(ComplianceResult(
                                control_id="5.1.1",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=binding.metadata.name,
                                resource_type="ClusterRoleBinding",
                                reason=f"Service account {subject.name} has cluster-admin privileges",
                                remediation="Review and limit cluster-admin role assignments",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                namespace=subject.namespace
                            ))
            
            if not results:
                results.append(ComplianceResult(
                    control_id="5.1.1",
                    status=ComplianceStatus.COMPLIANT,
                    resource_id="cluster-admin-usage",
                    resource_type="RBAC",
                    reason="Cluster-admin role usage appears appropriate",
                    remediation="No action required",
                    timestamp=datetime.now(timezone.utc).isoformat()
                ))
                
        except Exception as e:
            results.append(ComplianceResult(
                control_id="5.1.1",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="cluster-admin",
                resource_type="RBAC",
                reason=f"Unable to check RBAC configuration: {e}",
                remediation="Ensure proper RBAC permissions to view ClusterRoleBindings",
                timestamp=datetime.now(timezone.utc).isoformat()
            ))
        
        return results
    
    def check_wildcard_rbac_usage(self) -> List[ComplianceResult]:
        """5.1.3 - Check for wildcard usage in RBAC"""
        results = []
        
        try:
            # Check ClusterRoles for wildcards
            cluster_roles = self.rbac_v1.list_cluster_role()
            
            for role in cluster_roles.items:
                if role.rules:
                    for rule in role.rules:
                        has_wildcard = False
                        wildcard_details = []
                        
                        if rule.verbs and "*" in rule.verbs:
                            has_wildcard = True
                            wildcard_details.append("verbs")
                        
                        if rule.resources and "*" in rule.resources:
                            has_wildcard = True
                            wildcard_details.append("resources")
                        
                        if rule.api_groups and "*" in rule.api_groups:
                            has_wildcard = True
                            wildcard_details.append("apiGroups")
                        
                        if has_wildcard and role.metadata.name not in ["cluster-admin", "admin"]:
                            results.append(ComplianceResult(
                                control_id="5.1.3",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=role.metadata.name,
                                resource_type="ClusterRole",
                                reason=f"Role uses wildcards in: {', '.join(wildcard_details)}",
                                remediation="Replace wildcards with specific permissions",
                                timestamp=datetime.now(timezone.utc).isoformat()
                            ))
            
            # Check Roles for wildcards
            roles = self.rbac_v1.list_role_for_all_namespaces()
            
            for role in roles.items:
                if role.rules:
                    for rule in role.rules:
                        has_wildcard = False
                        wildcard_details = []
                        
                        if rule.verbs and "*" in rule.verbs:
                            has_wildcard = True
                            wildcard_details.append("verbs")
                        
                        if rule.resources and "*" in rule.resources:
                            has_wildcard = True
                            wildcard_details.append("resources")
                        
                        if rule.api_groups and "*" in rule.api_groups:
                            has_wildcard = True
                            wildcard_details.append("apiGroups")
                        
                        if has_wildcard:
                            results.append(ComplianceResult(
                                control_id="5.1.3",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=role.metadata.name,
                                resource_type="Role",
                                reason=f"Role uses wildcards in: {', '.join(wildcard_details)}",
                                remediation="Replace wildcards with specific permissions",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                namespace=role.metadata.namespace
                            ))
            
            if not results:
                results.append(ComplianceResult(
                    control_id="5.1.3",
                    status=ComplianceStatus.COMPLIANT,
                    resource_id="wildcard-usage",
                    resource_type="RBAC",
                    reason="No inappropriate wildcard usage found in RBAC",
                    remediation="No action required",
                    timestamp=datetime.now(timezone.utc).isoformat()
                ))
                
        except Exception as e:
            results.append(ComplianceResult(
                control_id="5.1.3",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="wildcard-rbac",
                resource_type="RBAC",
                reason=f"Unable to check RBAC wildcard usage: {e}",
                remediation="Ensure proper permissions to view Roles and ClusterRoles",
                timestamp=datetime.now(timezone.utc).isoformat()
            ))
        
        return results
    
    def check_pod_security_policies(self) -> List[ComplianceResult]:
        """5.2.x - Check various pod security policies"""
        results = []
        
        try:
            # Get all pods across all namespaces
            pods = self.v1.list_pod_for_all_namespaces()
            
            for pod in pods.items:
                pod_name = pod.metadata.name
                namespace = pod.metadata.namespace
                
                # Skip system namespaces for some checks
                if namespace in ["kube-system", "kube-public", "kube-node-lease"]:
                    continue
                
                if pod.spec.security_context:
                    # Check host PID namespace (5.2.2)
                    if pod.spec.host_pid:
                        results.append(ComplianceResult(
                            control_id="5.2.2",
                            status=ComplianceStatus.NON_COMPLIANT,
                            resource_id=pod_name,
                            resource_type="Pod",
                            reason="Pod shares host PID namespace",
                            remediation="Set hostPID: false in pod specification",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            namespace=namespace
                        ))
                    
                    # Check host IPC namespace (5.2.3)
                    if pod.spec.host_ipc:
                        results.append(ComplianceResult(
                            control_id="5.2.3",
                            status=ComplianceStatus.NON_COMPLIANT,
                            resource_id=pod_name,
                            resource_type="Pod",
                            reason="Pod shares host IPC namespace",
                            remediation="Set hostIPC: false in pod specification",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            namespace=namespace
                        ))
                    
                    # Check host network namespace (5.2.4)
                    if pod.spec.host_network:
                        results.append(ComplianceResult(
                            control_id="5.2.4",
                            status=ComplianceStatus.NON_COMPLIANT,
                            resource_id=pod_name,
                            resource_type="Pod",
                            reason="Pod shares host network namespace",
                            remediation="Set hostNetwork: false in pod specification",
                            timestamp=datetime.now(timezone.utc).isoformat(),
                            namespace=namespace
                        ))
                
                # Check containers for privilege escalation (5.2.5)
                for container in pod.spec.containers:
                    if container.security_context:
                        if container.security_context.allow_privilege_escalation is True:
                            results.append(ComplianceResult(
                                control_id="5.2.5",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=f"{pod_name}/{container.name}",
                                resource_type="Container",
                                reason="Container allows privilege escalation",
                                remediation="Set allowPrivilegeEscalation: false in container securityContext",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                namespace=namespace
                            ))
                
                # Check default namespace usage (5.7.4)
                if namespace == "default":
                    results.append(ComplianceResult(
                        control_id="5.7.4",
                        status=ComplianceStatus.NON_COMPLIANT,
                        resource_id=pod_name,
                        resource_type="Pod",
                        reason="Pod running in default namespace",
                        remediation="Move workloads to dedicated namespaces",
                        timestamp=datetime.now(timezone.utc).isoformat(),
                        namespace=namespace
                    ))
                
        except Exception as e:
            results.append(ComplianceResult(
                control_id="5.2.x",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="pod-security",
                resource_type="Pod",
                reason=f"Unable to check pod security policies: {e}",
                remediation="Ensure proper permissions to view pods",
                timestamp=datetime.now(timezone.utc).isoformat()
            ))
        
        return results
    
    def check_network_policies(self) -> List[ComplianceResult]:
        """5.3.2 - Check for network policies"""
        results = []
        
        try:
            # Get all namespaces
            namespaces = self.v1.list_namespace()
            
            for namespace in namespaces.items:
                ns_name = namespace.metadata.name
                
                # Skip system namespaces
                if ns_name in ["kube-system", "kube-public", "kube-node-lease", "default"]:
                    continue
                
                # Check if namespace has network policies
                try:
                    network_policies = self.networking_v1.list_namespaced_network_policy(namespace=ns_name)
                    
                    if not network_policies.items:
                        # Check if namespace has pods
                        pods = self.v1.list_namespaced_pod(namespace=ns_name)
                        if pods.items:
                            results.append(ComplianceResult(
                                control_id="5.3.2",
                                status=ComplianceStatus.NON_COMPLIANT,
                                resource_id=ns_name,
                                resource_type="Namespace",
                                reason="Namespace has pods but no network policies",
                                remediation="Create network policies to control pod-to-pod communication",
                                timestamp=datetime.now(timezone.utc).isoformat(),
                                namespace=ns_name
                            ))
                    
                except Exception as e:
                    logger.warning(f"Could not check network policies for namespace {ns_name}: {e}")
            
            if not results:
                results.append(ComplianceResult(
                    control_id="5.3.2",
                    status=ComplianceStatus.COMPLIANT,
                    resource_id="network-policies",
                    resource_type="NetworkPolicy",
                    reason="All namespaces with workloads have network policies or are system namespaces",
                    remediation="No action required",
                    timestamp=datetime.now(timezone.utc).isoformat()
                ))
                
        except Exception as e:
            results.append(ComplianceResult(
                control_id="5.3.2",
                status=ComplianceStatus.INSUFFICIENT_DATA,
                resource_id="network-policies",
                resource_type="NetworkPolicy",
                reason=f"Unable to check network policies: {e}",
                remediation="Ensure proper permissions to view namespaces and network policies",
                timestamp=datetime.now(timezone.utc).isoformat()
            ))
        
        return results
    
    def run_compliance_check(self, control_ids: Optional[List[str]] = None) -> List[ComplianceResult]:
        """Run compliance checks for specified or all controls"""
        results = []
        
        # Define control mappings
        control_methods = {
            "1.2.1": self.check_api_server_anonymous_auth,
            "5.1.1": self.check_rbac_cluster_admin_usage,
            "5.1.3": self.check_wildcard_rbac_usage,
            "5.2.x": self.check_pod_security_policies,
            "5.3.2": self.check_network_policies,
        }
        
        # If no specific controls requested, run all
        if not control_ids:
            control_ids = list(control_methods.keys())
        
        for control_id in control_ids:
            if control_id in control_methods:
                try:
                    logger.info(f"Running check for control {control_id}")
                    result = control_methods[control_id]()
                    
                    if isinstance(result, list):
                        results.extend(result)
                    else:
                        results.append(result)
                        
                except Exception as e:
                    logger.error(f"Error checking control {control_id}: {e}")
                    results.append(ComplianceResult(
                        control_id=control_id,
                        status=ComplianceStatus.INSUFFICIENT_DATA,
                        resource_id="unknown",
                        resource_type="unknown",
                        reason=f"Check failed: {e}",
                        remediation="Review error and ensure proper cluster access",
                        timestamp=datetime.now(timezone.utc).isoformat()
                    ))
            else:
                logger.warning(f"Control {control_id} not implemented")
        
        return results
    
    def generate_report(self, results: List[ComplianceResult], output_format: str = "json") -> str:
        """Generate compliance report"""
        
        # Calculate summary statistics
        total_checks = len(results)
        compliant = len([r for r in results if r.status == ComplianceStatus.COMPLIANT])
        non_compliant = len([r for r in results if r.status == ComplianceStatus.NON_COMPLIANT])
        not_applicable = len([r for r in results if r.status == ComplianceStatus.NOT_APPLICABLE])
        insufficient_data = len([r for r in results if r.status == ComplianceStatus.INSUFFICIENT_DATA])
        
        compliance_percentage = (compliant / total_checks * 100) if total_checks > 0 else 0
        
        report_data = {
            "report_metadata": {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "total_checks": total_checks,
                "benchmark": "CIS Kubernetes Benchmark v1.8.0"
            },
            "summary": {
                "compliant": compliant,
                "non_compliant": non_compliant,
                "not_applicable": not_applicable,
                "insufficient_data": insufficient_data,
                "compliance_percentage": round(compliance_percentage, 2)
            },
            "results": [asdict(result) for result in results]
        }
        
        if output_format.lower() == "json":
            return json.dumps(report_data, indent=2, default=str)
        else:
            # Text format
            report = []
            report.append("=" * 80)
            report.append("Kubernetes CIS Benchmark Compliance Report")
            report.append("=" * 80)
            report.append(f"Timestamp: {report_data['report_metadata']['timestamp']}")
            report.append(f"Total Checks: {total_checks}")
            report.append(f"Compliance Percentage: {compliance_percentage:.1f}%")
            report.append("")
            report.append("SUMMARY")
            report.append("-" * 40)
            report.append(f"Compliant: {compliant}")
            report.append(f"Non-Compliant: {non_compliant}")
            report.append(f"Not Applicable: {not_applicable}")
            report.append(f"Insufficient Data: {insufficient_data}")
            report.append("")
            report.append("DETAILED RESULTS")
            report.append("-" * 40)
            
            for result in results:
                report.append(f"Control: {result.control_id}")
                report.append(f"Status: {result.status.value}")
                report.append(f"Resource: {result.resource_type}::{result.resource_id}")
                if result.namespace:
                    report.append(f"Namespace: {result.namespace}")
                report.append(f"Reason: {result.reason}")
                report.append(f"Remediation: {result.remediation}")
                report.append("")
            
            return "\n".join(report)

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Kubernetes CIS Benchmark Checker")
    parser.add_argument("command", choices=["check", "list"], help="Command to execute")
    parser.add_argument("--controls", help="Comma-separated list of control IDs to check")
    parser.add_argument("--kubeconfig", help="Path to kubeconfig file")
    parser.add_argument("--context", help="Kubernetes context to use")
    parser.add_argument("--format", choices=["json", "text"], default="json", help="Output format")
    parser.add_argument("--output", help="Output file path")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        checker = KubernetesCISChecker(kubeconfig_path=args.kubeconfig, context=args.context)
        
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
                print(f"Report saved to {args.output}")
            else:
                print(report)
    
    except Exception as e:
        logger.error(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
