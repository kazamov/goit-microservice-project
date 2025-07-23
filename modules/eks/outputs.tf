output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "cluster_name" {
  description = "Name of the EKS cluster (alias)"
  value       = aws_eks_cluster.eks.name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = aws_iam_role.nodes.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.oidc.url
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

output "current_user_arn" {
  description = "ARN of the current AWS user with EKS access"
  value       = data.aws_caller_identity.current.arn
}

output "eks_console_url" {
  description = "URL to access EKS cluster in AWS Console"
  value       = "https://${data.aws_caller_identity.current.account_id}.console.aws.amazon.com/eks/home?region=${data.aws_region.current.name}#/clusters/${aws_eks_cluster.eks.name}"
}
