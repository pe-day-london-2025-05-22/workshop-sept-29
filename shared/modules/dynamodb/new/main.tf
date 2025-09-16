terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
        random = {
            source  = "hashicorp/random"
            version = ">= 3.0"
        }
    }
}

provider "aws" {
}

variable "name" {
    type = string
    default = null
}

variable "hash_key" {
    type = string
}

variable "hash_key_type" {
    type = string
    default = "S"
}

variable "range_key" {
    type = string
    default = null
}

variable "range_key_type" {
    type = string
    default = "S"
}

variable "context" {
    type = object({
      org_id = string
      project_id = string
      env_id = string
    })
}

resource "random_id" "r" {
    byte_length = 5
}

locals {
  table_name = var.name != null ? var.name : "table${random_id.r.hex}"
}

resource "aws_dynamodb_table" "table" {
  name           = local.table_name
  hash_key       = var.hash_key
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  range_key      = var.range_key
  dynamic "attribute" {
    for_each = var.range_key != null ? [1] : []
    content {
        name = var.range_key
        type = var.range_key_type
    }
  }

  read_capacity  = 20
  write_capacity = 20

  tags = {
    HumanitecOrg = var.context.org_id
    HumanitecProject = var.context.project_id
    HumanitecEnv = var.context.env_id
  }
}

output "name" {
    value = aws_dynamodb_table.table.name
}

output "region" {
    value = aws_dynamodb_table.table.region
}
