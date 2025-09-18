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

resource "random_id" "r" {
  byte_length = 5
}

resource "kubernetes_namespace_v1" "ns" {
  metadata {
    name = "env-${random_id.r.hex}"
  }
}

variable "cluster_region" {
  type    = string
  default = "unknown"
}

variable "cluster_name" {
  type    = string
  default = "unknown"
}

data "kubernetes_nodes" "nodes" {
}

output "name" {
  value = kubernetes_namespace_v1.ns.metadata[0].name
}

output "humanitec_metadata" {
  value = {
    "Console-Url" : "https://${var.cluster_region}.console.aws.amazon.com/eks/clusters/${var.cluster_name}?region=${var.cluster_region}"
    "Kubernetes-Namespace" : kubernetes_namespace_v1.ns.metadata[0].name
  }
}
