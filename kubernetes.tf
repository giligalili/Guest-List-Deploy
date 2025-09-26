# kubernetes.tf
locals {
  full_image = "${var.image_repo}:${var.image_tag}"
  ddb_table_name  = "GuestList-${var.environment}"
}

# Kubernetes resources for Guest List API deployment

# Namespace for the application
# Always deploy into "guestlist"
resource "kubernetes_namespace" "guestlist" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.namespace
  }
}
resource "kubernetes_secret" "guestlist_aws" {
  metadata {
    name      = "guestlist-aws"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
  }

  data = {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    AWS_DEFAULT_REGION    = var.aws_region
    DDB_TABLE             = local.ddb_table_name
  }

  type = "Opaque"
}

# Deployment
resource "kubernetes_deployment" "guestlist_api" {
  depends_on = [
    kubernetes_namespace.guestlist,
    kubernetes_secret.guestlist_aws
  ]

  metadata {
    name      = "guestlist-deployment"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
    labels = {
      app         = "guestlist-api"
      environment = var.environment
      student     = var.environment  # student = environment
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "guestlist-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "guestlist-api"
        }
      }

      spec {
        container {
          name              = "guestlist-container"
          image             = local.full_image
          image_pull_policy = "Always"

          # -------- AWS + DynamoDB envs (from Secret) --------
          env {
            name = "AWS_ACCESS_KEY_ID"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.guestlist_aws.metadata[0].name
                key  = "AWS_ACCESS_KEY_ID"
              }
            }
          }

          env {
            name = "AWS_SECRET_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.guestlist_aws.metadata[0].name
                key  = "AWS_SECRET_ACCESS_KEY"
              }
            }
          }

          env {
            name = "AWS_DEFAULT_REGION"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.guestlist_aws.metadata[0].name
                key  = "AWS_DEFAULT_REGION"
              }
            }
          }

          env {
            name = "DDB_TABLE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.guestlist_aws.metadata[0].name
                key  = "DDB_TABLE"
              }
            }
          }
          # ---------------------------------------------------

          port {
            container_port = 1111
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 1111
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = 1111
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        # (Optional) image pull secrets, SA, etc. go here, still inside template.spec
        # image_pull_secrets { name = "myregistry" }
        # service_account_name = "guestlist-sa"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "0%"
      }
    }
  }
}

# Service
resource "kubernetes_service" "guestlist_service" {
  metadata {
    name      = "guestlist-service"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
    labels = {
      app         = "guestlist-api"
      environment = var.environment
      student     = var.environment
    }
  }

  spec {
    selector = {
      app = "guestlist-api"
    }

    port {
      name        = "http"
      port        = 9999
      target_port = 1111
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.guestlist_api]
}

# ConfigMap for application configuration (optional)
resource "kubernetes_config_map" "guestlist_config" {
  metadata {
    name      = "guestlist-config"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
  }

  data = {
    environment = var.environment
    log_level   = "INFO"
  }
}

# Horizontal Pod Autoscaler (optional for cost management)
resource "kubernetes_horizontal_pod_autoscaler_v2" "guestlist_hpa" {
  metadata {
    name      = "guestlist-hpa"
    namespace = kubernetes_namespace.guestlist.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.guestlist_api.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

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
  }
}
