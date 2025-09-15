# ===========================================
# Providers
# ===========================================

terraform {
    required_providers {
        platform-orchestrator = {
            source = "humanitec/platform-orchestrator"
            version = "~> 2.0"
        }
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "~> 2.0"
        }
    }
}

# ===========================================
# Variables (required, and optional)
# ===========================================

variable "humanitec_org_id" {
    type = string
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

# ===========================================
# Resource types
# ===========================================

resource "platform-orchestrator_resource_type" "score-workload" {
    id = "score-workload${var.humanitec_id_suffix}"
    description = "Score Workload"
    output_schema = jsonencode({
        required = ["endpoint"]
        properties = {
            endpoint = {
                type = "string"
            }
        }
    })
}

resource "platform-orchestrator_resource_type" "k8s-namespace" {
    id = "k8s-namespace${var.humanitec_id_suffix}"
    description = "K8s Namespace"
    output_schema = jsonencode({
        required = ["name"]
        properties = {
            name = {
                type = "string"
            }
        }
    })
}

resource "platform-orchestrator_resource_type" "k8s-service-account" {
    id = "k8s-service-account${var.humanitec_id_suffix}"
    description = "K8s Service Account"
    output_schema = jsonencode({
        required = ["name"]
        properties = {
            name = {
                type = "string"
            }
        }
    })
}

# ===========================================
# Modules
# ===========================================

resource "platform-orchestrator_provider" "k8s" {
    provider_type = "kubernetes"
    id = "default${var.humanitec_id_suffix}"
    source = "hashicorp/kubernetes"
    version_constraint = "~> 2.0"
    configuration = jsonencode({})
}

resource "platform-orchestrator_module" "k8s-score-workload" {
    id = "k8s-score-workload${var.humanitec_id_suffix}"
    resource_type = platform-orchestrator_resource_type.score-workload.id
    description = "Deploy a Score Workload onto a kubernetes cluster"
    module_source = "git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/score-workload/kubernetes"
    provider_mapping = {
        kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
    }
    module_params = {
        metadata = {
            type = "map"
        }
        containers = {
            type = "map"
        }
        service = {
            type = "map"
            is_optional = true
        }
    }
    dependencies = {
        ns = {
            type = platform-orchestrator_resource_type.k8s-namespace.id
            id = "shared-k8s-namespace"
        }
        acc = {
            type = platform-orchestrator_resource_type.k8s-service-account.id
            params = jsonencode({
                namespace = "$${resources.ns.outputs.name}"
            })
        }
    }
    module_inputs = jsonencode({
        namespace = "$${resources.ns.outputs.name}"
        service_account_name = "$${resources.acc.outputs.name}"
    })

    depends_on = [ platform-orchestrator_resource_type.k8s-namespace, platform-orchestrator_resource_type.k8s-service-account ]
}

resource "platform-orchestrator_module" "k8s-namespace" {
    id = "k8s-namespace${var.humanitec_id_suffix}"
    resource_type = platform-orchestrator_resource_type.k8s-namespace.id
    description = "Provision a Kubernetes namespace onto the kubernetes cluster"
    module_source = "git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/k8s-namespace/new"
    provider_mapping = {
        kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
    }
}

resource "platform-orchestrator_module" "k8s-service-account" {
    id = "k8s-service-account${var.humanitec_id_suffix}"
    resource_type = platform-orchestrator_resource_type.k8s-service-account.id
    description = "Provision a Kubernetes service account onto the kubernetes cluster in the given namespace"
    module_source = "git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/k8s-service-account/new"
    provider_mapping = {
        kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
    }
    module_params = {
        namespace = {
            type = "string"
        }
    }
}
