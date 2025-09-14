terraform {
    required_providers {
        platform-orchestrator = {
            source = "humanitec/platform-orchestrator"
        }
        kubernetes = {
            source = "hashicorp/kubernetes"
        }
    }
}

variable "humanitec_org_id" {
    type = string
}

variable "humanitec_project_id" {
    type = string
   default = "workshop"
}

variable "humanitec_runner_id" {
    type = string
    default = "workshop"
}

provider "platform-orchestrator" {
    org_id = var.humanitec_org_id
}

provider "kubernetes" {
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
        namespace = kubernetes_namespace.po.metadata.name
    }
}

resource "kubernetes_role" "agent" {
    metadata {
        name = "agent"
        namespace = kubernetes_namespace.po.metadata.name
    }
    rule {
        api_groups = ["batch"]
        resources = ["jobs"]
        verbs = ["create", "get", "list", "watch", "delete"]
    }
}

resource "kubernetes_role_binding" "agent" {
    metadata {
        name = "${kubernetes_service_account.agent.metadata.name}-${kubernetes_role.agent.metadata.name}"
        namespace = kubernetes_namespace.po.metadata.name
    }
    subject {
        kind = "ServiceAccount"
        name = kubernetes_service_account.agent.metadata.name
        namespace = kubernetes_namespace.po.metadata.name
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = kubernetes_role.agent.metadata.name
    }
}

resource "kubernetes_secret" "agent-private-key" {
    metadata {
        name = "agent-private-key"
        namespace = kubernetes_namespace.po.metadata.name
    }
    data = {
        key = tls_private_key.runner.private_key_pem
    }
}

resource "kubernetes_deployment" "agent" {
    metadata {
        name = "agent"
        namespace = kubernetes_namespace.po.metadata.name
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
                service_account_name = kubernetes_service_account.agent.metadata.name
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
                                name = kubernetes_secret.agent-private-key.metadata.name
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
        namespace = kubernetes_namespace.po.metadata.name
    }
}

resource "kubernetes_role" "runner" {
    metadata {
        name = "runner"
        namespace = kubernetes_namespace.po.metadata.name
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
        name = "${kubernetes_service_account.runner.metadata.name}-${kubernetes_role.runner.metadata.name}"
        namespace = kubernetes_namespace.po.metadata.name
    }
    subject {
        kind = "ServiceAccount"
        name = kubernetes_service_account.runner.metadata.name
        namespace = kubernetes_namespace.po.metadata.name
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = kubernetes_role.runner.metadata.name
    }
}

resource "platform-orchestrator_kubernetes_agent_runner" "workshop" {
    id = var.humanitec_runner_id
    runner_configuration = {
        key = tls_private_key.runner.public_key_pem
        job = {
            namespace = kubernetes_namespace.po.metadata.name
            service_account = kubernetes_service_account.runner.metadata.name
        }
    }
    state_storage_configuration = {
        type = "kubernetes"
        kubernetes_configuration = {
            namespace = kubernetes_namespace.po.metadata.name
        }
    }
}

resource "platform-orchestrator_environment_type" "development" {
    id = "development"
}

resource "platform-orchestrator_environment_type" "staging" {
    id = "staging"
}

resource "platform-orchestrator_environment_type" "production" {
    id = "production"
}

resource "platform-orchestrator_project" "workshop" {
    id = var.humanitec_project_id
}

resource "platform-orchestrator_runner_rule" "default" {
    runner_id = platform-orchestrator_kubernetes_runner.default.id
    project_id = platform-orchestrator_project.workshop.id
}
