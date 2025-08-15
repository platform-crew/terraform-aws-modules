resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version

  values = [
    <<EOF
args:
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP
EOF
  ]

  depends_on = [
    aws_eks_node_group.eks_nodes
  ]
}
