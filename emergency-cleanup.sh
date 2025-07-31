#!/bin/bash
# Emergency manual cleanup script for stuck resources
# Run this locally with your AWS credentials configured

set -e

ENV=${1:-dev}
RUN_NUMBER=${2:-""}
REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo "🧹 Emergency Cleanup for Environment: $ENV"
echo "Region: $REGION"

if [ -n "$RUN_NUMBER" ]; then
    PATTERN="cis-$ENV-$RUN_NUMBER"
    echo "Run Number: $RUN_NUMBER"
else
    PATTERN="cis-$ENV"
    echo "Cleaning ALL resources for environment $ENV"
fi

echo "Pattern: $PATTERN"
echo ""

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local resource_id=$2
    local max_wait=${3:-300}
    
    echo "Waiting for $resource_type $resource_id to delete (max ${max_wait}s)..."
    local count=0
    while [ $count -lt $max_wait ]; do
        if ! aws $resource_type describe-* --$resource_type-id "$resource_id" --region $REGION &>/dev/null; then
            echo "✅ $resource_type $resource_id deleted"
            return 0
        fi
        sleep 10
        count=$((count + 10))
        echo -n "."
    done
    echo "⚠️  Timeout waiting for $resource_type $resource_id to delete"
}

echo "🔍 Step 1: Deleting EKS Clusters and Node Groups"
CLUSTERS=$(aws eks list-clusters --region $REGION --query "clusters[?contains(@, '$PATTERN')]" --output text)

for cluster in $CLUSTERS; do
    echo "🗑️  Deleting EKS cluster: $cluster"
    
    # Delete all nodegroups first
    NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$cluster" --region $REGION --query 'nodegroups[]' --output text 2>/dev/null || echo "")
    for nodegroup in $NODEGROUPS; do
        echo "   Deleting nodegroup: $nodegroup"
        aws eks delete-nodegroup --cluster-name "$cluster" --nodegroup-name "$nodegroup" --region $REGION || true
    done
    
    # Wait for nodegroups
    echo "   Waiting for nodegroups to delete..."
    sleep 60
    
    # Delete cluster
    aws eks delete-cluster --name "$cluster" --region $REGION || true
    echo "   Cluster deletion initiated: $cluster"
done

echo ""
echo "🔍 Step 2: Deleting Load Balancers"
# ALBs/NLBs
aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?contains(LoadBalancerName, '$PATTERN')].LoadBalancerArn" --output text | while read lb_arn; do
    if [ ! -z "$lb_arn" ]; then
        echo "🗑️  Deleting ALB/NLB: $lb_arn"
        aws elbv2 delete-load-balancer --load-balancer-arn "$lb_arn" --region $REGION || true
    fi
done

# Classic ELBs
aws elb describe-load-balancers --region $REGION --query "LoadBalancerDescriptions[?contains(LoadBalancerName, '$PATTERN')].LoadBalancerName" --output text | while read lb_name; do
    if [ ! -z "$lb_name" ]; then
        echo "🗑️  Deleting Classic ELB: $lb_name"
        aws elb delete-load-balancer --load-balancer-name "$lb_name" --region $REGION || true
    fi
done

echo ""
echo "🔍 Step 3: Waiting for EKS clusters to fully delete..."
sleep 120

echo ""
echo "🔍 Step 4: Deleting EC2 Instances"
INSTANCES=$(aws ec2 describe-instances --region $REGION --query "Reservations[].Instances[?Tags[?Key=='Name' && contains(Value, '$PATTERN')] && State.Name!='terminated'].InstanceId" --output text)
for instance in $INSTANCES; do
    if [ ! -z "$instance" ]; then
        echo "🗑️  Terminating EC2 instance: $instance"
        aws ec2 terminate-instances --instance-ids "$instance" --region $REGION || true
    fi
done

echo ""
echo "🔍 Step 5: Deleting Security Groups"
# Wait a bit for instances to terminate
sleep 30

aws ec2 describe-security-groups --region $REGION --query "SecurityGroups[?contains(GroupName, '$PATTERN') && GroupName != 'default'].GroupId" --output text | while read sg_id; do
    if [ ! -z "$sg_id" ]; then
        echo "🗑️  Deleting Security Group: $sg_id"
        # Retry a few times as dependencies might still be clearing
        for i in {1..5}; do
            if aws ec2 delete-security-group --group-id "$sg_id" --region $REGION 2>/dev/null; then
                echo "   ✅ Deleted SG: $sg_id"
                break
            else
                echo "   ⏳ Retry $i/5 for SG: $sg_id"
                sleep 20
            fi
        done
    fi
done

echo ""
echo "🔍 Step 6: Deleting VPCs and associated resources"
VPC_IDS=$(aws ec2 describe-vpcs --region $REGION --query "Vpcs[?Tags[?Key=='Name' && contains(Value, '$PATTERN')]].VpcId" --output text)

for vpc_id in $VPC_IDS; do
    echo "🗑️  Cleaning up VPC: $vpc_id"
    
    # Delete NAT Gateways first
    aws ec2 describe-nat-gateways --region $REGION --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[].NatGatewayId' --output text | while read nat_id; do
        if [ ! -z "$nat_id" ]; then
            echo "   Deleting NAT Gateway: $nat_id"
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id" --region $REGION || true
        fi
    done
    
    # Wait for NAT Gateways to delete
    sleep 60
    
    # Delete subnets
    aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text | while read subnet_id; do
        if [ ! -z "$subnet_id" ]; then
            echo "   Deleting subnet: $subnet_id"
            aws ec2 delete-subnet --subnet-id "$subnet_id" --region $REGION || true
        fi
    done
    
    # Delete internet gateway
    aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text | while read igw_id; do
        if [ ! -z "$igw_id" ]; then
            echo "   Detaching and deleting IGW: $igw_id"
            aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" --region $REGION || true
            aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" --region $REGION || true
        fi
    done
    
    # Delete route tables (except main)
    aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[?Associations[0].Main != `true`].RouteTableId' --output text | while read rt_id; do
        if [ ! -z "$rt_id" ]; then
            echo "   Deleting route table: $rt_id"
            aws ec2 delete-route-table --route-table-id "$rt_id" --region $REGION || true
        fi
    done
    
    # Finally delete VPC
    echo "   Deleting VPC: $vpc_id"
    for i in {1..5}; do
        if aws ec2 delete-vpc --vpc-id "$vpc_id" --region $REGION 2>/dev/null; then
            echo "   ✅ Deleted VPC: $vpc_id"
            break
        else
            echo "   ⏳ Retry $i/5 for VPC: $vpc_id"
            sleep 30
        fi
    done
done

echo ""
echo "✅ Emergency cleanup completed!"
echo ""
echo "⚠️  Note: Some resources may take additional time to fully delete."
echo "Check the AWS Console to verify all resources are removed."
echo ""
echo "If IAM roles need to be deleted, run:"
echo "aws iam list-roles --query \"Roles[?contains(RoleName, '$PATTERN')].RoleName\" --output text"
