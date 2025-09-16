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

variable "namespace" {
    type = string
    description = "The namespace to create the ingress in. Fill this in using selectors"
}

variable "service_port" {
    type = number
    description = "The service port to route to"
}

variable "service_name" {
    type = string
    description = "The service to route to"
}

resource "kubernetes_ingress_v1" "ingress" {
    metadata {
        name = "${var.service_name}-${var.service_port}"
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
                      name = var.service_name
                      port {
                        number = var.service_port
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
    "Kubernetes-Service": var.service_name
  }
}
