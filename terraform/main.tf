# Main Terraform Configuration
# This file orchestrates all modules to create the complete infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Configure Kubernetes Provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = var.cluster_name
  availability_zones = var.availability_zones
  common_tags        = var.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  app_port           = var.app_port
  common_tags        = var.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name          = var.cluster_name
  kubernetes_version    = var.kubernetes_version
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  node_instance_type    = var.node_instance_type
  node_desired_capacity = var.node_desired_capacity
  node_max_capacity     = var.node_max_capacity
  node_min_capacity     = var.node_min_capacity
  capacity_type         = var.capacity_type
  common_tags           = var.common_tags

  depends_on = [module.vpc, module.security]
}

# Kubernetes Namespace
resource "kubernetes_namespace" "guestlist" {
  metadata {
    name = "guestlist-${var.environment}"

    labels = {
      name        = "guestlist-${var.environment}"
      environment = var.environment
    }
  }

  depends_on = [module.eks]
}

# Kubernetes Deployment
resource "kubernetes_deployment" "guestlist" {
  metadata {
    name      = "guestlist-deployment"
    namespace = kubernetes_namespace.guestlist.metadata[0].name

    labels = {
      app         = "guestlist"
      environment = var.environment
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "guestlist"
      }
    }

    template {
      metadata {
        labels = {
          app = "guestlist"
        }
      }

      spec {
        container {
          image = var.app_image
          name  = "guestlist"
          port {
            container_port = var.app_port
          }

          # Environment variables
          env {
            name  = "PORT"
            value = tostring(var.app_port)
          }

          env {
            name  = "ENVIRONMENT"
            value = var.environment
          }

          # Resource limits
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          # Health checks
          liveness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.guestlist]
}

# Kubernetes Service
resource "kubernetes_service" "guestlist" {
  metadata {
    name      = "guestlist-service"
    namespace = kubernetes_namespace.guestlist.metadata[0].name

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.guestlist.metadata[0].labels.app
    }

    port {
      name        = "http"
      port        = 80
      target_port = var.app_port
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.guestlist]
}

# Kubernetes ConfigMap for application configuration
resource "kubernetes_config_map" "guestlist_config" {
  metadata {
    name      = "guestlist-config"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
  }

  data = {
    "app.properties" = <<-EOF
      # Guest List Application Configuration
      environment=${var.environment}
      port=${var.app_port}
      log_level=INFO
      max_guests=1000
      EOF
  }

  depends_on = [kubernetes_namespace.guestlist]
}

# Kubernetes Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "guestlist_hpa" {
  metadata {
    name      = "guestlist-hpa"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.guestlist.metadata[0].name
    }

    min_replicas = var.app_replicas
    max_replicas = var.app_replicas * 3

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.guestlist]
}
