terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

data "kubernetes_nodes" "nodes" {
}

locals {
  node_labels = data.kubernetes_nodes.nodes.nodes[0].metadata[0].labels
  cluster_region = lookup(local.node_labels, "topology.kubernetes.io/region", "unknown")
  cluster_name = lookup(local.node_labels, "alpha.eksctl.io/cluster-name", "unknown")
}

output "name" {
    value = local.cluster_name
}

output "region" {
    value = local.cluster_region
}

output "humanitec_metadata" {
  value = {
    "Console-Url": "https://${local.cluster_region}.console.aws.amazon.com/eks/clusters/${local.cluster_name}?region=${local.cluster_region}"
  }
}
