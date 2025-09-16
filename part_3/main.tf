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
    provider_mapping = {
        aws = "${platform-orchestrator_provider.aws.provider_type}.${platform-orchestrator_provider.aws.id}"
    }
}

resource "platform-orchestrator_module_rule" "new-dynamodb" {
    module_id = platform-orchestrator_module.new-dynamodb.id
    project_id = var.humanitec_project_id
}
