# EKS Cluster Terraform Module

This Terraform configuration provisions an AWS EKS cluster along with a managed node group. It supports optional launch templates, spot instances, and autoscaling.

---

## Features

- Creates an EKS cluster
- Creates a managed node group with configurable instance types
- Supports on-demand and spot instances (`capacity_type`)
- Optional launch template support for node groups
- Autoscaling enabled with tags for Cluster Autoscaler
- IAM roles and policies attached for worker nodes
- Configurable scaling parameters for node group size

---

## Variables

| Name                   | Type     | Default   | Description                                                   |
|------------------------|----------|-----------|---------------------------------------------------------------|
| `cluster_name`         | `string` |           | Name of the EKS cluster                                       |                                       |
| `node_role_arn`        | `string` |           | ARN of the IAM role for the node group                        |
| `subnet_ids`           | `list`   |           | List of subnet IDs where nodes will be deployed               |
| `node_instance_types`  | `list`   | `["t3.medium"]` | List of EC2 instance types for nodes                         |
| `node_capacity_type`   | `string` | `"ON_DEMAND"` | Capacity type for node group. Use `"SPOT"` for spot instances |
| `desired_node_size`    | `number` |           | Desired number of nodes in the node group                     |
| `max_node_size`        | `number` |           | Maximum number of nodes in the node group                     |
| `min_node_size`        | `number` |           | Minimum number of nodes in the node group                     |
| `launch_template_id`   | `string` | `""`      | (Optional) Launch template ID for node group                  |
| `launch_template_version` | `string` | `"$Latest"` | Version of the launch template                               |
| `environment`          | `string` |           | Environment tag (e.g., dev, staging, prod)                    |

---

## Usage

```hcl
module "eks" {
  source = "./path_to_your_module"

  cluster_name           = "my-eks-cluster"
  node_role_arn          = aws_iam_role.eks_node_role.arn
  subnet_ids             = ["subnet-xxxxxx", "subnet-yyyyyy"]
  node_instance_types    = ["t3.medium"]
  node_capacity_type     = "ON_DEMAND" # or "SPOT"
  desired_node_size      = 2
  max_node_size          = 3
  min_node_size          = 1
  environment            = "dev"

  # Optional launch template
  launch_template_id       = ""       # e.g. "lt-0abcd1234efgh5678"
  launch_template_version  = "$Latest"
}
