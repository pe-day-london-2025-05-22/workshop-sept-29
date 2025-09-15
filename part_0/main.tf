terraform {
    required_providers {
        helm = {
            source = "hashicorp/helm"
            version = "~> 3.0"
        }
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "helm" {
    kubernetes = {
        config_path = "~/.kube/config"
    }
}

provider "aws" {
}

resource "helm_release" "ingress" {
    name = "ingress-nginx"
    chart = "ingress-nginx"
    version = "4.13.2"
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


data "aws_eks_cluster" "workshop" {
    name = "eks-workshop"
}

data "aws_eks_node_groups" "workshop" {
    cluster_name = data.aws_eks_cluster.workshop.name
}

data "aws_eks_node_group" "workshop-default" {
    cluster_name = data.aws_eks_cluster.workshop.name
    node_group_name = tolist(data.aws_eks_node_groups.workshop.names)[0]
}

resource "aws_iam_role_policy_attachment" "worker_node_cloudwatch" {
    role       = split("/", data.aws_eks_node_group.workshop-default.node_role_arn)[1]
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "cloudwatch" {
    cluster_name = data.aws_eks_cluster.workshop.name
    addon_name = "amazon-cloudwatch-observability"
}
