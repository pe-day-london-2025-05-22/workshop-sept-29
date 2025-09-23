terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

variable "hostname" {
  type        = string
  description = "The hostname to route from"
}

variable "port" {
  type        = number
  description = "The service port to route to"
}

variable "namespace" {
  type        = list(string)
  description = "The namespace to create the ingress in. Fill this in using selectors"
  validation {
    condition     = length(var.namespace) == 1
    error_message = "Must select one namespace"
  }
}

variable "endpoint" {
  type        = list(string)
  description = "The service to route to"
  validation {
    condition     = length(var.endpoint) == 1
    error_message = "Must select one service endpoint"
  }
}

variable "ingress_class_name" {
  type = string
}

locals {
  service = split(".", var.endpoint[0])[0]
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = "${local.service}-${var.port}"
    namespace = var.namespace[0]
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2",
      "nginx.ingress.kubernetes.io/x-forwarded-prefix" = "/${var.namespace[0]}/",
    }
  }
  spec {
    ingress_class_name = var.ingress_class_name
    rule {
      host = var.hostname
      http {
        path {
          path      = "/${var.namespace[0]}(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = local.service
              port {
                number = var.port
              }
            }
          }
        }
      }
    }
  }
}

output "humanitec_metadata" {
  value = {
    "Kubernetes-Namespace" : var.namespace[0]
    "Kubernetes-Service" : local.service
    "Web-Url" : "http://${var.hostname}/${var.namespace[0]}"
  }
}
