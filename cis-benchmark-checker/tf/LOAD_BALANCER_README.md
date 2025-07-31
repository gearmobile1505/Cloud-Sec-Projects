# Load Balancer Configuration

This document explains the load balancer resources added to prevent Kubernetes from automatically creating Classic ELBs that can block VPC deletion.

## Problem Solved

Previously, when Kubernetes services with `type: LoadBalancer` were deployed, EKS would automatically create Classic Load Balancers (ELBs) outside of Terraform's control. These ELBs would:

- Create ENIs (Elastic Network Interfaces) in your subnets
- Block VPC deletion during cleanup
- Require manual deletion through AWS CLI or Console

## Solution

We now create Terraform-managed load balancers that:

- ✅ Are fully managed by Terraform lifecycle
- ✅ Get destroyed automatically during `terraform destroy`
- ✅ Don't block VPC cleanup
- ✅ Provide better control and visibility

## Recommended Configuration

For most use cases, you only need:

### ✅ **Application Load Balancer (ALB)** - Primary Choice
- **Resource**: `aws_lb.main_alb`
- **Use Case**: HTTP/HTTPS web applications (like your CIS testing app)
- **Features**: Path-based routing, SSL termination, WAF integration
- **Default**: `create_alb = true`

### ✅ **Classic Load Balancer (ELB)** - Prevention & Legacy Testing  
- **Resource**: `aws_elb.classic`
- **Use Case**: Prevents Kubernetes auto-creation + tests legacy scenarios
- **Features**: Simple HTTP/HTTPS/TCP load balancing
- **Default**: `create_classic_elb = true`

### ❌ **Network Load Balancer (NLB)** - Optional
- **Resource**: `aws_lb.main_nlb`
- **Use Case**: High-performance TCP/UDP traffic (not needed for web apps)
- **Features**: Ultra-low latency, static IP addresses
- **Default**: `create_nlb = false` (disabled to save costs)

## Configuration Variables

Control which load balancers to create:

```hcl
# Recommended defaults in terraform.tfvars
create_alb         = true   # ✅ For your web application
create_nlb         = false  # ❌ Not needed for HTTP apps
create_classic_elb = true   # ✅ Prevents K8s auto-creation
```

## Cost Optimization

With the recommended configuration:
- **ALB**: ~$16-25/month (handles your web traffic)
- **Classic ELB**: ~$18/month (prevents issues, legacy testing)
- **Total**: ~$34-43/month

Previous configuration with all three would cost ~$50-68/month.

## When to Enable NLB

Only enable NLB (`create_nlb = true`) if you need:
- Non-HTTP protocols (TCP/UDP)
- Ultra-low latency requirements
- Static IP addresses for the load balancer
- Preserve source IP addresses

## Kubernetes Service Changes

The Kubernetes service has been changed from:

```yaml
# OLD - Creates unmanaged ELB
spec:
  type: LoadBalancer
```

To:

```yaml
# NEW - Uses ClusterIP, relies on Terraform LBs
spec:
  type: ClusterIP
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-managed: "false"
```

## Outputs Available

After deployment, you can access these outputs:

```bash
# ALB Information
terraform output alb_dns_name
terraform output alb_arn
terraform output alb_zone_id

# NLB Information  
terraform output nlb_dns_name
terraform output nlb_arn
terraform output nlb_zone_id

# Classic ELB Information
terraform output classic_elb_dns_name
terraform output classic_elb_name
terraform output classic_elb_zone_id
```

## Security Groups

Each load balancer type gets its own security group:

- **ALB**: `aws_security_group.alb` - Allows HTTP (80) and HTTPS (443)
- **ELB**: `aws_security_group.elb` - Allows HTTP (80) and HTTPS (443)  
- **NLB**: No security group needed (operates at Layer 4)

## Target Groups

- **ALB Target Group**: `aws_lb_target_group.alb_tg` - HTTP health checks
- **NLB Target Group**: `aws_lb_target_group.nlb_tg` - TCP health checks

## Cleanup Benefits

With Terraform-managed load balancers:

1. **Automatic Cleanup**: `terraform destroy` removes everything
2. **No Manual Intervention**: No need for emergency cleanup scripts for LBs
3. **Predictable State**: All resources are in Terraform state
4. **Better Dependency Management**: Proper resource ordering during destruction

## Emergency Cleanup

The emergency cleanup script is still useful for other resources, but load balancers are now handled automatically by Terraform. If you need to manually clean up these load balancers, they follow the naming pattern:

- ALB: `{project_name}-alb`
- NLB: `{project_name}-nlb`  
- Classic ELB: `{project_name}-classic-elb`

## Cost Considerations

- **ALB**: ~$16-25/month (based on usage)
- **NLB**: ~$16-25/month (based on usage)
- **Classic ELB**: ~$18/month (fixed cost)

For testing, you can disable unused load balancers by setting their variables to `false`.
