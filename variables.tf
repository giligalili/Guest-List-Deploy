# variables.tf
# Environment variables for flexible deployment

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "guestlist-cluster"
}

variable "environment" {
  description = "Environment name (gili, sivan, sahar, dvir, dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small" # Cost-optimized
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2 # Minimal for cost
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 3
}

variable "student_name" {
  description = "Student name for resource tagging"
  type        = string
  default     = "devsecops-student"
}
variable "image_repo" {
  type        = string
  description = "Docker image repository"
  default     = "docker.io/giligalili/guestlistapi"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag to deploy"
  default     = "latest"
}

variable "namespace" {
  type        = string
  default     = "default"
}
# DynamoDB table your app uses (e.g., "GuestList")
variable "ddb_table_name" {
  type        = string
  description = "DynamoDB table name for the app"
}

# Reuse the same IAM user that manages your TF backend
variable "aws_access_key_id" {
  type        = string
  sensitive   = true
  description = "App AWS access key (same user as TF backend)"
}

variable "aws_secret_access_key" {
  type        = string
  sensitive   = true
  description = "App AWS secret key (same user as TF backend)"
}
