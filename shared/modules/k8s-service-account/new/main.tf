terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

variable "namespace" {
  type = string
}

resource "random_id" "r" {
  byte_length = 5
}

resource "kubernetes_service_account_v1" "sa" {
  metadata {
    name      = "sa-${random_id.r.hex}"
    namespace = var.namespace
  }
}

output "name" {
  value = kubernetes_service_account_v1.sa.metadata[0].name
}

output "humanitec_metadata" {
  value = {
    "Kubernetes-Service-Account" : kubernetes_service_account_v1.sa.metadata[0].name
    "Kubernetes-Namespace" : var.namespace
  }
}
