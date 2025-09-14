terraform {
    required_providers {
        helm = {
            source = "hashicorp/helm"
            version = "3.0.2"
        }
    }
}

provider "helm" {
    kubernetes = {
        config_path = "~/.kube/config"
    }
}

resource "helm_release" "ingress" {
    name = "ingress-nginx"
    chart = "ingress-nginx"
    repository = "https://kubernetes.github.io/ingress-nginx"
    namespace = "ingress-nginx"
    set = [
        {
            name = "controller.service.type"
            value = "LoadBalancer"
        }, {
            name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
            value = "nlb"
        }, {
            name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
            value = "internet-facing"
        }
    ]
}
