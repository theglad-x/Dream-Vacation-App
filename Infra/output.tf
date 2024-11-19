
output "endpoint" {
  value = aws_eks_cluster.k8s-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.k8s-cluster.certificate_authority[0].data
}

output "cluster_name" {
  value = aws_eks_cluster.k8s-cluster
}

output "database_endpoint" {
  value = aws_db_instance.postgresdb-instance.endpoint
}