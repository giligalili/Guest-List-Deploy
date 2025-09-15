# Security Module Outputs

output "cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.cluster.id
}

output "nodes_security_group_id" {
  description = "ID of the EKS worker nodes security group"
  value       = aws_security_group.nodes.id
}

output "alb_security_group_id" {
  description = "ID of the Application Load Balancer security group"
  value       = aws_security_group.alb.id
}

output "cluster_security_group_arn" {
  description = "ARN of the EKS cluster security group"
  value       = aws_security_group.cluster.arn
}

output "nodes_security_group_arn" {
  description = "ARN of the EKS worker nodes security group"
  value       = aws_security_group.nodes.arn
}

output "alb_security_group_arn" {
  description = "ARN of the Application Load Balancer security group"
  value       = aws_security_group.alb.arn
}

output "network_acl_id" {
  description = "ID of the network ACL"
  value       = aws_network_acl.main.id
}
