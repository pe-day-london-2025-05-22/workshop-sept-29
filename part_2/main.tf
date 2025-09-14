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

resource "platform-orchestrator_module" "k8s-score-workload" {
    id = "k8s-score-workload${var.humanitec_id_suffix}"
    description = "Deploy a Score Workload onto a kubernetes cluster"
    module_source = "git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/score-workload/kubernetes"
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
            type = "k8s-namespace"
        }
        acc = {
            type = "k8s-service-account"
            params = {
                namespace = "$${resources.ns.outputs.name}"
            }
        }
    }
    module_inputs = jsonencode({
        namespace = "$${resources.ns.outputs.name}"
        service_account_name = "$${resources.acc.outputs.name}"
    })
}

resource "platform-orchestrator_module" "k8s-namespace" {
    id = "k8s-namespace${var.humanitec_id_suffix}"
    description = "Provision a Kubernetes namespace onto the kubernetes cluster"
    module_source = "git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/k8s-namespace/new"
}

resource "platform-orchestrator_module" "k8s-service-account" {
    id = "k8s-service-account${var.humanitec_id_suffix}"
    description = "Provision a Kubernetes service account onto the kubernetes cluster in the given namespace"
    module_source = "git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/k8s-service-account/new"
    module_params = {
        namespace = {
            type = "string"
        }
    }
}
