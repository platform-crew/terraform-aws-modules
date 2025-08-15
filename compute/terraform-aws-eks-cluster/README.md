
# AWS EKS Cluster Terraform Module

## Overview
This Terraform module provisions a production-ready AWS EKS (Elastic Kubernetes Service) cluster with all essential components including worker nodes, ALB controller, cluster autoscaler, and RBAC integration.

## Features
- **Managed EKS Cluster**: Fully configured Kubernetes control plane
- **Worker Node Groups**: Auto-scaling groups with spot instance support
- **AWS ALB Controller**: For ingress management with IAM Roles for Service Accounts (IRSA)
- **Cluster Autoscaler**: Automatic node scaling based on workload
- **VPC CNI Networking**: AWS VPC Container Network Interface
- **Metrics Server**: Cluster metrics collection
- **RBAC Integration**: IAM role to Kubernetes role mapping
- **OIDC Provider**: Secure service account authentication

## Requirements
- Terraform >= 1.12.1
- AWS Provider >= 5.0
- Kubernetes Provider >= 2.37
- Helm Provider >= 2.17
- AWS CLI configured with proper credentials
- kubectl
- helm

## Usage
```hcl
module "eks_cluster" {
  source = "./path/to/module"

  region          = "us-west-2"
  environment     = "production"
  cluster_name    = "my-eks-cluster"
  vpc_id          = "vpc-12345678"
  subnet_ids      = ["subnet-123456", "subnet-234567"]

  kubernetes_version              = "1.27"
  alb_controller_chart_version    = "1.5.3"
  cluster_autoscaler_chart_version = "9.28.0"
  vpc_cni_addon_version           = "v1.14.0-eksbuild.1"

  desired_node_size = 3
  min_node_size     = 1
  max_node_size     = 5
}
```

## Input Variables

### Required Variables
| Name | Description | Type |
|------|-------------|------|
| region | AWS region | string |
| cluster_name | EKS cluster name | string |
| vpc_id | VPC ID for EKS | string |
| subnet_ids | List of subnet IDs | list(string) |
| kubernetes_version | Kubernetes version | string |

### Optional Variables
| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Environment tag | string | "dev" |
| endpoint_private_access | Private API endpoint | bool | false |
| endpoint_public_access | Public API endpoint | bool | true |
| public_access_cidrs | Allowed CIDRs for public endpoint | list(string) | ["0.0.0.0/0"] |
| node_instance_types | Worker node instance types | list(string) | ["t3.medium"] |
| node_capacity_type | SPOT or ON_DEMAND | string | "SPOT" |
| namespace | Kubernetes namespace for components | string | "kube-system" |

## Outputs
| Name | Description |
|------|-------------|
| eks_cluster_name | EKS cluster name |
| eks_cluster_endpoint | Kubernetes API endpoint |
| eks_cluster_arn | EKS cluster ARN |
| cluster_security_group_id | Control plane security group ID |

## Module Components

### 1. IAM Roles
- EKS cluster role
- Node group role
- ALB controller role (IRSA)
- Cluster autoscaler role (IRSA)
- VPC CNI role (IRSA)

### 2. EKS Cluster
- Control plane with configurable API endpoint access
- OIDC provider for IRSA
- Kubernetes network configuration

### 3. Node Groups
- Auto-scaling worker nodes
- Configurable instance types
- Spot instance support
- Launch template support

### 4. Add-ons
- AWS Load Balancer Controller (Helm)
- Cluster Autoscaler (Helm)
- VPC CNI (Managed Add-on)
- Metrics Server (Helm)

### 5. RBAC Configuration
- IAM role to Kubernetes RBAC mapping
- Configurable permission sets
- Automatic aws-auth configmap management

## Security
- IAM Roles for Service Accounts (IRSA) for all components
- Configurable API endpoint access (public/private)
- Network isolation through VPC configuration
- Least-privilege IAM policies

## Maintenance
To update the cluster configuration:
1. Modify the Terraform files
2. Review changes:
   ```bash
   terraform plan
   ```
3. Apply changes:
   ```bash
   terraform apply
   ```

## Cleanup
To destroy all resources:
```bash
terraform destroy
```
