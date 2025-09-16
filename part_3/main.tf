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
    org_id = var.humanitec_org_id
}

provider "aws" {
}

# ===========================================
# Part 3.1
# ===========================================

resource "platform-orchestrator_resource_type" "dynamodb" {
    id = "dynamodb-table${var.humanitec_id_suffix}"
    description = "Dynamo DB Table"
    output_schema = jsonencode({
        required = ["region", "name"]
        properties = {
            region = {
                type = "string"
            }
            name = {
                type = "string"
            }
        }
    })
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

resource "platform-orchestrator_module" "new-dynamodb" {
    id = "new-dynamodb-table${var.humanitec_id_suffix}"
    resource_type = platform-orchestrator_resource_type.dynamodb.id
    description = "Provision a new dynamo db table"
    module_source = "git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/dynamodb_table/new"
    module_params = {
        hash_key = {
            type = "string"
        }
        hash_key_type = {
            type = "string"
            is_optional = true
        }
        range_key = {
            type = "string"
            is_optional = true
        }
        range_key_type = {
            type = "string"
            is_optional = true
        }
    }
    module_inputs = jsonencode({
        context = {
            org_id = "$${context.org_id}"
            project_id = "$${context.project_id}"
            env_id = "$${context.env_id}"
        }
    })
    provider_mapping = {
        aws = "${platform-orchestrator_provider.aws.provider_type}.${platform-orchestrator_provider.aws.id}"
    }
}

resource "platform-orchestrator_module_rule" "new-dynamodb" {
    module_id = platform-orchestrator_module.new-dynamodb.id
    project_id = var.humanitec_project_id
}

# ===========================================
# Part 3.2
# ===========================================

/*
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

resource "aws_iam_role" "runner" {
  name               = "runner-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "manage-dynamo" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.runner.name
}

resource "aws_eks_pod_identity_association" "example" {
  cluster_name    = "eks-workload"
  namespace       = "platform-orchestrator"
  service_account = "runner"
  role_arn        = aws_iam_role.runner.arn
}
*/
