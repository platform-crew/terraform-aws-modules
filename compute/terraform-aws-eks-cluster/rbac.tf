# ============================== EKS RBAC CONFIGURATION ==============================
# This module configures IAM roles and Kubernetes RBAC for EKS cluster access control.
# It creates a complete access control system that maps IAM roles to Kubernetes permissions.

# ----------------------------- IAM ROLE CONFIGURATION ------------------------------
# Creates IAM roles that will be assumed by Kubernetes users through OIDC federation
# These roles serve as identities only - permissions are controlled via Kubernetes RBAC

resource "aws_iam_role" "eks_access_roles" {
  for_each = { for group in var.cluster_rbac_config : group.name => group }

  name        = each.value.iam_role
  description = "IAM role for Kubernetes RBAC access group (${each.value.name})"

  # Trust policy allowing federation through EKS OIDC provider
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${aws_iam_openid_connect_provider.eks_oidc_provider.url}:sub" = "system:serviceaccount:kube-system:aws-auth"
          }
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = "EKS-RBAC"
  }
}

# ------------------------- KUBERNETES RBAC CONFIGURATION --------------------------
# Defines the actual permissions within the Kubernetes cluster

resource "kubernetes_cluster_role" "cluster_rbac_roles" {
  for_each = { for group in var.cluster_rbac_config : group.name => group }

  metadata {
    name = each.value.name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Dynamic block for flexible permission rules configuration
  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

# Binds Kubernetes groups to ClusterRoles
resource "kubernetes_cluster_role_binding" "eks_role_bindings" {
  for_each = { for group in var.cluster_rbac_config : group.name => group }

  metadata {
    name = "${each.value.name}-binding"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_rbac_roles[each.key].metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = each.value.name
    api_group = "rbac.authorization.k8s.io"
  }
}

# ------------------------- AWS-AUTH CONFIGMAP CONFIGURATION -------------------------
# Configures the aws-auth ConfigMap to map IAM roles to Kubernetes RBAC groups

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      concat(
        # Default node role mapping required for worker node communication
        [
          {
            rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-node-role"
            username = "system:node:{{EC2PrivateDNSName}}"
            groups   = ["system:bootstrappers", "system:nodes"]
          }
        ],
        # Dynamic generation of RBAC role mappings from variables
        [
          for group in var.cluster_rbac_config : {
            rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${group.iam_role}"
            username = "${group.name}-${group.iam_role}"
            groups   = [group.name]
          }
        ]
      )
    )
  }
  depends_on = [aws_eks_cluster.eks_cluster]
}
