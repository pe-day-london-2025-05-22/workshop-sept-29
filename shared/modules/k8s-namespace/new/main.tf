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

resource "kubernetes_namespace" "ns" {
    metadata {
        name = "env-${random_id.r.hex}"
    }
}

data "kubernetes_nodes" "nodes" {
}

locals {
  node_labels = data.kubernetes_nodes.nodes.nodes.metadata[0].labels
  cluster_region = lookup(node_labels, "topology.kubernetes.io/region", "unknown")
  cluster_name = lookup(node_labels, "alpha.eksctl.io/cluster-name", "unknown")
}

output "name" {
    value = kubernetes_namespace.ns.metadata[0].name
}

output "humanitec_metadata" {
  value = {
    "Console-Url": "https://${local.cluster_region}.console.aws.amazon.com/eks/clusters/${local.cluster_name}?region=${local.cluster_region}"
    "Name": kubernetes_namespace.ns.metadata[0].name
  }
}
