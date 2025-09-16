terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

variable "hostname" {
    type = string
    description = "The hostname to route from"
}

variable "port" {
    type = number
    description = "The service port to route to"
}

variable "namespace" {
    type = string
    description = "The namespace to create the ingress in. Fill this in using selectors"
}

variable "endpoint" {
    type = string
    description = "The service to route to"
}

locals {
    service = split(".", var.endpoint)[0]
}

resource "kubernetes_ingress_v1" "ingress" {
    metadata {
        name = "${local.service}-${var.port}"
        namespace = var.namespace
    }
    spec {
        rule {
            host = var.hostname
            http {
                path {
                  path = "/"
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
    "Kubernetes-Namespace": var.namespace
    "Kubernetes-Service": local.service
  }
}
