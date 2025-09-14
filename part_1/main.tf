# ===========================================
# Providers
# ===========================================

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

# ===========================================
# Variables (required, and optional)
# ===========================================

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

locals {
    match_labels = {
        app = "humanitec-agent"
    }
}

# ===========================================
# Instantiate providers
# ===========================================

provider "platform-orchestrator" {
    org_id = var.humanitec_org_id
}

provider "kubernetes" {
    config_path = "~/.kube/config"
}

# ===========================================
# Kubernetes resources for the agent and runner
# agent = the reverse proxy pod
# runner = the jobs running terraform/tofu
# ===========================================

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

// These are the permissions the reverse proxy job launcher needs to execute. In generate, it just needs to be able
// to launch and monitor kubernetes jobs in it's own namespace. Nothing else.
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

// We use a private key to authenticate the agent reverse proxy with humanitec. The private component 
// is stored in a secret so that the agent can prove it's identity. The public component is passed to
// humanitec when we register the agent further down.
resource "tls_private_key" "agent" {
  algorithm = "ED25519"
}

resource "kubernetes_secret" "agent-private-key" {
    metadata {
        name = "agent-private-key"
        namespace = kubernetes_namespace.po.metadata[0].name
    }
    data = {
        key = tls_private_key.agent.private_key_pem
    }
}

// Our actual agent reverse proxy runs as a 1-replica deployment as a basic example. This can get far
// more complicated as we'll see in the later parts.
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

// The actual runner pods execute as a service account that needs permissions to at least store
// it's kubernetes state file in kubernetes secrets. We will grant it more permissions later
// if we need to.
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

# ===========================================
# Register the agent runner in the humanitec platform orchestrator
# ===========================================

resource "platform-orchestrator_kubernetes_agent_runner" "workshop" {
    id = var.humanitec_runner_id
    runner_configuration = {
        key = tls_private_key.agent.public_key_pem
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

output "runner_url" {
    value = "https://console.humanitec.dev/orgs/${var.humanitec_org_id}/runners/${platform-orchestrator_kubernetes_agent_runner.workshop.id}/configuration"
}

output "kubernetes_runner_service_account" {
    value = "${kubernetes_namespace.po.metadata[0].name}/${kubernetes_service_account.runner.metadata[0].name}"
}
