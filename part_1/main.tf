terraform {
    required_providers {
        platform-orchestrator = {
            source = "humanitec/platform-orchestrator"
            version = "2.6.1"
        }
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "2.38.0"
        }
    }
}

variable "humanitec_org_id" {
    type = string
}

variable "humanitec_project_id" {
    type = string
   default = "workshop"
    description = "Project ids have to be unique, if there is already a project with this ID and it can't be deleted or used, you can use this to use a new project ID"
}

variable "humanitec_runner_id" {
    type = string
    default = "workshop"
    description = "Runner ids have to be unique, if there is already a runner with this ID and it can't be deleted or used, you can use this to use a new runner ID"
}

variable "humanitec_environment_type_prefix" {
    type = string
    default = ""
    description = "ET ids have to be unique, if the existing ETs cannot be deleted, you can use this to create a new set of ET ids."
}

provider "platform-orchestrator" {
    org_id = var.humanitec_org_id
}

provider "kubernetes" {
    config_path = "~/.kube/config"
}

locals {
    match_labels = {
        app = "humanitec-agent"
    }
}

resource "tls_private_key" "runner" {
  algorithm = "ED25519"
}

resource "kubernetes_namespace" "po" {
    metadata {
        name = "platform-orchestrator"
    }
}

resource "kubernetes_service_account" "agent" {
    metadata {
        name = "agent"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
}

resource "kubernetes_role" "agent" {
    metadata {
        name = "agent"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    rule {
        api_groups = ["batch"]
        resources = ["jobs"]
        verbs = ["create", "get", "list", "watch", "delete"]
    }
}

resource "kubernetes_role_binding" "agent" {
    metadata {
        name = "${kubernetes_service_account.agent.metadata[0].name}-${kubernetes_role.agent.metadata[0].name}"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    subject {
        kind = "ServiceAccount"
        name = kubernetes_service_account.agent.metadata[0].name
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = kubernetes_role.agent.metadata[0].name
    }
}

resource "kubernetes_secret" "agent-private-key" {
    metadata {
        name = "agent-private-key"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    data = {
        key = tls_private_key.runner.private_key_pem
    }
}

resource "kubernetes_deployment" "agent" {
    metadata {
        name = "agent"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    spec {
        replicas = 1
        selector {
            match_labels = local.match_labels
        }
        template {
            metadata {
                labels = local.match_labels
            }
            spec {
                service_account_name = kubernetes_service_account.agent.metadata[0].name
                container {
                    name = "agent"
                    image = "ghcr.io/humanitec/canyon-runner:v1.7.1"
                    args = ["remote"]
                    env {
                        name = "ORG_ID"
                        value = var.humanitec_org_id
                    }
                    env {
                        name = "RUNNER_ID"
                        value = var.humanitec_runner_id
                    }
                    env {
                        name = "PRIVATE_KEY"
                        value_from {
                            secret_key_ref {
                                name = kubernetes_secret.agent-private-key.metadata[0].name
                                key = "key"
                            }
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_service_account" "runner" {
    metadata {
        name = "runner"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
}

resource "kubernetes_role" "runner" {
    metadata {
        name = "runner"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    rule {
        api_groups = [""]
        resources = ["secrets"]
        verbs = ["create", "get", "list", "watch", "delete"]
    }
    rule {
        api_groups = ["coordination.k8s.io"]
        resources = ["leases"]
        verbs = ["create", "get", "update"]
    }
}

resource "kubernetes_role_binding" "runner" {
    metadata {
        name = "${kubernetes_service_account.runner.metadata[0].name}-${kubernetes_role.runner.metadata[0].name}"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    subject {
        kind = "ServiceAccount"
        name = kubernetes_service_account.runner.metadata[0].name
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = kubernetes_role.runner.metadata[0].name
    }
}

resource "platform-orchestrator_kubernetes_agent_runner" "workshop" {
    id = var.humanitec_runner_id
    runner_configuration = {
        key = tls_private_key.runner.public_key_pem
        job = {
            namespace = kubernetes_namespace.po.metadata[0].name
            service_account = kubernetes_service_account.runner.metadata[0].name
        }
    }
    state_storage_configuration = {
        type = "kubernetes"
        kubernetes_configuration = {
            namespace = kubernetes_namespace.po.metadata[0].name
        }
    }
}

resource "platform-orchestrator_environment_type" "development" {
    id = "${var.humanitec_environment_type_prefix}development"
}

resource "platform-orchestrator_environment_type" "staging" {
    id = "${var.humanitec_environment_type_prefix}staging"
}

resource "platform-orchestrator_environment_type" "production" {
    id = "${var.humanitec_environment_type_prefix}production"
}

resource "platform-orchestrator_project" "workshop" {
    id = var.humanitec_project_id
}

resource "platform-orchestrator_runner_rule" "default" {
    runner_id = platform-orchestrator_kubernetes_agent_runner.workshop.id
    project_id = platform-orchestrator_project.workshop.id
}
