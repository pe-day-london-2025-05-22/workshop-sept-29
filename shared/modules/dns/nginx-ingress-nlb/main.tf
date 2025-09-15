terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

data "kubernetes_service" "ingress-nginx" {
    metadata {
        name = "ingress-nginx-controller"
        namespace = "ingress-nginx"
    }
}

locals {
    hostname = data.kubernetes_service.ingress-nginx.status[0].load_balancer[0].ingress[0].hostname
    nlb_region = split(".", hostname)[2]
    nlb_name = split("-", hostname)[0]
}

output "hostname" {
    value = data.kubernetes_service.ingress-nginx.status[0].load_balancer[0].ingress[0].hostname
}

output "humanitec_metadata" {
  value = {
    "Console-Url": "https://${local.nlb_region}.console.aws.amazon.com/ec2/home?region=${local.nlb_region}#LoadBalancers:name=${local.nlb_name}"
  }
}
