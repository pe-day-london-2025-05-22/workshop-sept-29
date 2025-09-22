terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

variable "eks_cluster_names" {
    type = list(string)
    validation {
      condition = length(var.eks_cluster_names) == 1
      error_message = "Must select one cluster"
    }
}

variable "eks_cluster_regions" {
    type = list(string)
    validation {
      condition = length(var.eks_cluster_regions) == 1
      error_message = "Must select one cluster"
    }
}

variable "namespaces" {
    type = list(string)
    validation {
      condition = length(var.namespaces) == 1
      error_message = "Must select one namespace"
    }
}

variable "service_accounts" {
    type = list(string)
    validation {
      condition = length(var.service_accounts) == 1
      error_message = "Must select one service_accounts"
    }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "r" {
  name_prefix = "role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_eks_pod_identity_association" "example" {
  region = var.eks_cluster_regions[0]
  cluster_name    = var.eks_cluster_names[0]
  namespace       = var.namespaces[0]
  service_account = var.service_accounts[0]
  role_arn        = aws_iam_role.r.arn
}

output "name" {
    value = aws_iam_role.r.name
}

output "humanitec_metadata" {
    value = {
        "Console-Url": "https://${var.eks_cluster_regions[0]}.console.aws.amazon.com/iam/home?region=${var.eks_cluster_regions[0]}#/roles/details/${aws_iam_role.r.name}"
    }
}
