variable "region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
}


variable "cluster_name" {
  description = "AWS EKS Cluster name"
  type        = string
}

variable "endpoint_private_access" {
  description = "Is EKS endpoint private"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Is EKS endpoint public"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "VPC subnet ids"
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Kubernetes Version"
  type        = string
}

variable "alb_controller_chart_version" {
  description = "Helm chart AWS Load Balancer Controller version"
  type        = string
}

variable "cluster_autoscaler_chart_version" {
  description = "Helm chart version autoscalaer version"
  type        = string
}

variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "kube-system"
}

variable "vpc_cni_addon_version" {
  description = "AWS VPC CNI version"
  type        = string
}

variable "desired_node_size" {
  description = "Desired node size for this cluster"
  type        = number
}

variable "min_node_size" {
  description = "Minimum node size for this cluster"
  type        = number
}

variable "max_node_size" {
  description = "Maximum node size for this cluster"
  type        = number
}

variable "node_instance_types" {
  description = "List of EC2 instance types for EKS worker nodes. Defaults to t3.medium for general-purpose workloads."
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_capacity_type" {
  description = "By default SPOT instacnes are enabled"
  type        = string
  default     = "SPOT"
}

variable "launch_template_id" {
  description = "Optional launch template ID for the node group"
  type        = string
  default     = "" # empty string means no launch template used
}

variable "launch_template_version" {
  description = "Optional launch template version"
  type        = string
  default     = "$Latest"
}

variable "metrics_server_chart_version" {
  description = "Metrics Server Helm chart version"
  type        = string
}

variable "cluster_rbac_config" {
  description = "List of EKS cluster roles and their permissions"
  type = list(object({
    name     = string
    iam_role = string
    rules = list(object({
      api_groups = list(string)
      resources  = list(string)
      verbs      = list(string)
    }))
  }))
}

variable "public_access_cidrs" {
  description = "List of public cidrs to access EKS control plane"
  type        = list(string)
  default     = []
}

variable "cluster_kms_key_deletion_window_in_days" {
  description = "EKS KMS key deletion window"
  type        = number
  default     = 7 # 7 days
}

variable "cluster_kms_key_rotation" {
  description = "EKS KMS key key rotation"
  type        = bool
  default     = true
}

variable "enabled_cluster_log_types" {
  description = "EKS enable cluster log types"
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}
