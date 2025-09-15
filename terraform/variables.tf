# Terraform Variables

# Basic Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and can only contain letters, numbers, and hyphens."
  }
}

variable "student_name" {
  description = "Name of the student (for tagging purposes)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Node Configuration
variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
  
  validation {
    condition     = var.node_desired_capacity >= 1 && var.node_desired_capacity <= 20
    error_message = "Node desired capacity must be between 1 and 20."
  }
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
  
  validation {
    condition     = var.node_min_capacity >= 1
    error_message = "Node minimum capacity must be at least 1."
  }
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10
  
  validation {
    condition     = var.node_max_capacity >= 1 && var.node_max_capacity <= 100
    error_message = "Node maximum capacity must be between 1 and 100."
  }
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

# Application Configuration
variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "giligalili/guestlistapi:ver01"
}

variable "app_port" {
  description = "Port number for the application"
  type        = number
  default     = 1111
  
  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
  
  validation {
    condition     = var.app_replicas >= 1 && var.app_replicas <= 20
    error_message = "Application replicas must be between 1 and 20."
  }
}

# Networking
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified for high availability."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# Tags
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
