# ===========================================
# Providers
# ===========================================

terraform {
    required_providers {
        platform-orchestrator = {
            source = "humanitec/platform-orchestrator"
            version = "~> 2.0"
        }
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

# ===========================================
# Variables (required, and optional)
# ===========================================

variable "humanitec_org_id" {
    type = string
}

variable "humanitec_project_id" {
    type = string
    default = "workshop"
}

variable "humanitec_id_suffix" {
    type = string
    default = ""
}

# ===========================================
# Instantiate providers
# ===========================================

provider "platform-orchestrator" {
  hctl_config_file = "/home/ec2-user/.config/hctl/config.yaml"
  org_id = var.humanitec_org_id
}

provider "aws" {
}

data "platform-orchestrator_provider" "k8s" {
    provider_type = "kubernetes"
    id = "default${var.humanitec_id_suffix}"
}

resource "platform-orchestrator_provider" "aws" {
    provider_type = "aws"
    id = "default${var.humanitec_id_suffix}"
    source = "hashicorp/aws"
    version_constraint = "~> 6.0"
    configuration = jsonencode({
        region = "us-west-2"
    })
}

resource "platform-orchestrator_resource_type" "iam-role" {
  id                      = "aws-iam-role${var.humanitec_id_suffix}"
  is_developer_accessible = false
  description             = "AWS IAM Role"
  output_schema = jsonencode({
    required = ["name"]
    properties = {
      name = {
        type = "string"
      }
    }
  })
}

resource "platform-orchestrator_module" "k8s-service-account-iam" {
  id            = "k8s-service-account-iam${var.humanitec_id_suffix}"
  resource_type = platform-orchestrator_resource_type.iam-role.id
  description   = "Provision an AWS IAM role linked to the k8s service account"
  module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/iam-role/k8s-service-account"
  module_inputs = jsonencode({
    eks_cluster_names = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').dependencies('k8s-namespace${var.humanitec_id_suffix}').dependencies('eks-cluster${var.humanitec_id_suffix}').outputs.name}"
    eks_cluster_regions = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').dependencies('k8s-namespace${var.humanitec_id_suffix}').dependencies('eks-cluster${var.humanitec_id_suffix}').outputs.region}"
    namespaces = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').dependencies('k8s-namespace${var.humanitec_id_suffix}').outputs.name}"
    service_accounts = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').outputs.name}"
  })
  provider_mapping = {
    aws = "${platform-orchestrator_provider.aws.provider_type}.${platform-orchestrator_provider.aws.id}"
    kubernetes = "${data.platform-orchestrator_provider.k8s.provider_type}.${data.platform-orchestrator_provider.k8s.id}"
  }
}

resource "platform-orchestrator_module_rule" "iam-role" {
    module_id = platform-orchestrator_module.k8s-service-account-iam.id
    project_id = var.humanitec_project_id
}

data "aws_iam_roles" "runner_inner_roles" {
    name_regex = "humanitec_runner_inner_role.*"
}

resource "aws_iam_role_policy_attachment" "iam_full_access" {
  role       = tolist(data.aws_iam_roles.runner_inner_roles.names)[0]
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamo_full_access" {
  role       = tolist(data.aws_iam_roles.runner_inner_roles.names)[0]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy" "custom_policy_statements" {
  role       = tolist(data.aws_iam_roles.runner_inner_roles.names)[0]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = [
                "eks:CreatePodIdentityAssociation",
                "eks:DeletePodIdentityAssociation",
                "eks:DescribePodIdentityAssociation",
            ],
            Effect   = "Allow"
            Resource = "*"
        }
    ]
  })
}

# # ===========================================
# # Part 3.1
# # ===========================================

# resource "platform-orchestrator_resource_type" "dynamodb" {
#     id = "dynamodb-table${var.humanitec_id_suffix}"
#     description = "Dynamo DB Table"
#     output_schema = jsonencode({
#         required = ["region", "name"]
#         properties = {
#             region = {
#                 type = "string"
#             }
#             name = {
#                 type = "string"
#             }
#         }
#     })
# }

# resource "platform-orchestrator_module" "new-dynamodb" {
#     id = "new-dynamodb-table${var.humanitec_id_suffix}"
#     resource_type = platform-orchestrator_resource_type.dynamodb.id
#     description = "Provision a new dynamo db table"
#     module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/dynamodb_table/new"
#     module_params = {
#         hash_key = {
#             type = "string"
#         }
#         hash_key_type = {
#             type = "string"
#             is_optional = true
#         }
#         range_key = {
#             type = "string"
#             is_optional = true
#         }
#         range_key_type = {
#             type = "string"
#             is_optional = true
#         }
#     }
#     module_inputs = jsonencode({
#         context = {
#             org_id = "$${context.org_id}"
#             project_id = "$${context.project_id}"
#             env_id = "$${context.env_id}"
#         }
#         allowed_role_names = "$${select.consumers('score-workload${var.humanitec_id_suffix}').dependencies('k8s-service-account${var.humanitec_id_suffix}').consumers('iam-role${var.humanitec_id_suffix}').outputs.name}"
#     })
#     provider_mapping = {
#         aws = "${platform-orchestrator_provider.aws.provider_type}.${platform-orchestrator_provider.aws.id}"
#     }
# }

# resource "platform-orchestrator_module_rule" "new-dynamodb" {
#     module_id = platform-orchestrator_module.new-dynamodb.id
#     project_id = var.humanitec_project_id
# }

# # ===========================================
# # Part 3.2
# # ===========================================

# # 1. Go to AWS IAM
# # 2. Create humanitec-runner role
# # 3. Add dynamodb full access, add IAM full access
# # 4. Go to EKS, switch Access tab
# # 5. Add pod identity association between humanitec-runner role, platform-orchestrator namespace, runner service account
# # 6. kubectl rollout restart -n platform-orchestrator deployment/agent

# resource "platform-orchestrator_resource_type" "iam-role" {
#     id = "iam-role${var.humanitec_id_suffix}"
#     is_developer_accessible = false
#     output_schema = jsonencode({
#         required = ["name"]
#         properties = {
#             name = {
#                 type = "string"
#             }
#         }
#     })
# }

# resource "platform-orchestrator_module" "iam-role" {
#     id = "new-iam-role${var.humanitec_id_suffix}"
#     resource_type = platform-orchestrator_resource_type.iam-role.id
#     module_source = "inline"
#     module_source_code = <<EOT

# terraform {
#     required_providers {
#         aws = {
#             source = "hashicorp/aws"
#             version = "~> 6.0"
#         }
#     }
# }

# variable "eks_cluster_names" {
#     type = list(string)
#     validation {
#       condition = length(var.eks_cluster_names) == 1
#       error_message = "Must select one cluster"
#     }
# }

# variable "eks_cluster_regions" {
#     type = list(string)
#     validation {
#       condition = length(var.eks_cluster_regions) == 1
#       error_message = "Must select one cluster"
#     }
# }

# variable "namespaces" {
#     type = list(string)
#     validation {
#       condition = length(var.namespaces) == 1
#       error_message = "Must select one namespace"
#     }
# }

# variable "service_accounts" {
#     type = list(string)
#     validation {
#       condition = length(var.service_accounts) == 1
#       error_message = "Must select one service_accounts"
#     }
# }

# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }

#     actions = [
#       "sts:AssumeRole",
#       "sts:TagSession"
#     ]
#   }
# }

# resource "aws_iam_role" "r" {
#   name_prefix = "role"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# resource "aws_eks_pod_identity_association" "example" {
#   region = var.eks_cluster_regions[0]
#   cluster_name    = var.eks_cluster_names[0]
#   namespace       = var.namespaces[0]
#   service_account = var.service_accounts[0]
#   role_arn        = aws_iam_role.r.arn
# }

# output "name" {
#     value = aws_iam_role.r.name
# }
# EOT
#     module_inputs = jsonencode({
#         eks_cluster_names = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').dependencies('k8s-namespace${var.humanitec_id_suffix}').dependencies('eks-cluster${var.humanitec_id_suffix}').outputs.name}"
#         eks_cluster_regions = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').dependencies('k8s-namespace${var.humanitec_id_suffix}').dependencies('eks-cluster${var.humanitec_id_suffix}').outputs.region}"
#         namespaces = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').dependencies('k8s-namespace${var.humanitec_id_suffix}').outputs.name}"
#         service_accounts = "$${select.dependencies('k8s-service-account${var.humanitec_id_suffix}').outputs.name}"
#     })
#     provider_mapping = {
#         aws = "${platform-orchestrator_provider.aws.provider_type}.${platform-orchestrator_provider.aws.id}"
#     }
# }

# resource "platform-orchestrator_module_rule" "new-iam-role" {
#     module_id = platform-orchestrator_module.iam-role.id
#     project_id = var.humanitec_project_id
# }

# // TODO: update k8s-service-account module to also have iam role coprovisioned
