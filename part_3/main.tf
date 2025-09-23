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
        "default_tags[0]" = {
            tags = {
                HumanitecOrg = "$${context.org_id}"
                HumanitecProject = "$${context.project_id}"
                HumanitecEnv = "$${context.env_id}"
            }
        }
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
                "eks:TagResource",
            ],
            Effect   = "Allow"
            Resource = "*"
        }
    ]
  })
}
