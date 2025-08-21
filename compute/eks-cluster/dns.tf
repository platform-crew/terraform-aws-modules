#---------------------------------------------
# ExternalDNS
#---------------------------------------------
# This section sets up ExternalDNS for the IDP application on EKS.
# ExternalDNS will automatically manage Route53 DNS records for Ingress resources.
# It uses a dedicated ServiceAccount with an IAM Role via IRSA to allow Route53 access.
#---------------------------------------------

# Create an IAM role that can be assumed by the ExternalDNS service account
resource "aws_iam_role" "externaldns_sa_role" {
  name = "${var.environment}-externaldns-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.environment}-externaldns-sa"
          }
        }
      }
    ]
  })
}

# IAM policy to allow ExternalDNS to manage Route53 records
resource "aws_iam_role_policy" "externaldns_route53" {
  name = "${var.environment}-externaldns-route53"
  role = aws_iam_role.externaldns_sa_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:ListHostedZones"
        ]
        Resource = "*" # Can be scoped further to specific hosted zones if needed
      }
    ]
  })
}

# Create Kubernetes ServiceAccount and annotate with the IAM role
resource "kubernetes_service_account" "externaldns_sa" {
  metadata {
    name      = "${var.environment}-externaldns-sa"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns_sa_role.arn
    }
  }
}

# Deploy ExternalDNS using Helm
resource "helm_release" "externaldns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = var.namespace
  version    = var.external_dns_chart_version

  values = [
    yamlencode({
      provider      = "aws"         # Use AWS Route53
      policy        = "upsert-only" # Only create/update records, never delete
      txtOwnerId    = "${var.environment}-externaldns"
      domainFilters = var.external_dns_domain_filter # Only manage this domain
      sources       = ["ingress", "service"]

      serviceAccount = {
        name   = kubernetes_service_account.externaldns_sa.metadata[0].name
        create = false # Use the pre-created service account
      }
    })
  ]

  depends_on = [kubernetes_service_account.externaldns_sa]
}
