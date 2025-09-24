# ===========================================
# Providers
# ===========================================

terraform {
  required_providers {
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
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

variable "humanitec_project_id" {
  type = string
  default = "workshop"
}

variable "humanitec_id_suffix" {
  type    = string
  default = ""
}

# ===========================================
# Instantiate providers
# ===========================================

provider "platform-orchestrator" {
  hctl_config_file = "/home/ec2-user/.config/hctl/config.yaml"
  org_id = var.humanitec_org_id
}

# ===========================================
# Resource types
# ===========================================

resource "platform-orchestrator_resource_type" "score-workload" {
  id          = "score-workload${var.humanitec_id_suffix}"
  description = "Score Workload"
  output_schema = jsonencode({
    properties = {
      endpoint = {
        type = "string"
      }
    }
  })
}

resource "platform-orchestrator_resource_type" "eks-cluster" {
  id                      = "eks-cluster${var.humanitec_id_suffix}"
  description             = "EKS cluster"
  is_developer_accessible = false
  output_schema = jsonencode({
    required = ["name", "region"]
    properties = {
      name = {
        type = "string"
      }
      region = {
        type = "string"
      }
    }
  })
}

resource "platform-orchestrator_resource_type" "k8s-namespace" {
  id          = "k8s-namespace${var.humanitec_id_suffix}"
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
  id                      = "k8s-service-account${var.humanitec_id_suffix}"
  is_developer_accessible = false
  description             = "K8s Service Account"
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
  provider_type      = "kubernetes"
  id                 = "default${var.humanitec_id_suffix}"
  source             = "hashicorp/kubernetes"
  version_constraint = "~> 2.0"
  configuration      = jsonencode({})
}

resource "platform-orchestrator_module" "k8s-score-workload" {
  id            = "k8s-score-workload${var.humanitec_id_suffix}"
  resource_type = platform-orchestrator_resource_type.score-workload.id
  description   = "Deploy a Score Workload onto a kubernetes cluster"
  module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/score-workload/kubernetes"
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
      type        = "map"
      is_optional = true
    }
  }
  dependencies = {
    ns = {
      type = platform-orchestrator_resource_type.k8s-namespace.id
      id   = "shared-k8s-namespace"
    }
    acc = {
      type = platform-orchestrator_resource_type.k8s-service-account.id
      params = jsonencode({
        namespace = "$${resources.ns.outputs.name}"
      })
    }
  }
  module_inputs = jsonencode({
    namespace            = "$${resources.ns.outputs.name}"
    service_account_name = "$${resources.acc.outputs.name}"
  })

  depends_on = [platform-orchestrator_resource_type.k8s-namespace, platform-orchestrator_resource_type.k8s-service-account]
}

resource "platform-orchestrator_module_rule" "k8s-score-workload" {
  module_id = platform-orchestrator_module.k8s-score-workload.id
  project_id = var.humanitec_project_id
}

resource "platform-orchestrator_module" "eks-cluster" {
  id            = "eks-cluster${var.humanitec_id_suffix}"
  resource_type = platform-orchestrator_resource_type.eks-cluster.id
  module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/eks-cluster/runner-context"
  provider_mapping = {
    kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
  }
}

resource "platform-orchestrator_module_rule" "eks-cluster" {
  module_id = platform-orchestrator_module.eks-cluster.id
  project_id = var.humanitec_project_id
}

resource "platform-orchestrator_module" "k8s-namespace" {
  id            = "k8s-namespace${var.humanitec_id_suffix}"
  resource_type = platform-orchestrator_resource_type.k8s-namespace.id
  description   = "Provision a Kubernetes namespace onto the EKS kubernetes cluster"
  module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/k8s-namespace/new"
  module_inputs = jsonencode({
    cluster_name   = "$${resources.cluster.outputs.name}"
    cluster_region = "$${resources.cluster.outputs.region}"
  })
  dependencies = {
    cluster = {
      type = "eks-cluster${var.humanitec_id_suffix}"
    }
  }
  provider_mapping = {
    kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
  }
}

resource "platform-orchestrator_module_rule" "k8s-namespace" {
  module_id = platform-orchestrator_module.k8s-namespace.id
  project_id = var.humanitec_project_id
}

resource "platform-orchestrator_module" "k8s-service-account" {
  id            = "k8s-service-account${var.humanitec_id_suffix}"
  resource_type = platform-orchestrator_resource_type.k8s-service-account.id
  description   = "Provision a Kubernetes service account onto the kubernetes cluster in the given namespace"
  module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/k8s-service-account/new"
  provider_mapping = {
    kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
  }
  module_params = {
    namespace = {
      type = "string"
    }
  }
}

resource "platform-orchestrator_module_rule" "k8s-service-account" {
  module_id = platform-orchestrator_module.k8s-service-account.id
  project_id = var.humanitec_project_id
}

# ===========================================
# OPTIONAL
# ===========================================


variable "is_part_2_modules_enabled" {
  type    = bool
  default = false
}

resource "platform-orchestrator_resource_type" "dns" {
  count = var.is_part_2_modules_enabled ? 1 : 0

  id = "dns${var.humanitec_id_suffix}"
  output_schema = jsonencode({
    required = ["hostname"]
    properties = {
      hostname = {
        type = "string"
      }
    }
  })
}

resource "platform-orchestrator_module" "dns" {
  count = var.is_part_2_modules_enabled ? 1 : 0

  id            = "dns${var.humanitec_id_suffix}"
  resource_type = platform-orchestrator_resource_type.dns[0].id
  module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/dns/nginx-ingress-nlb"
  provider_mapping = {
    kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
  }
  depends_on = [platform-orchestrator_resource_type.dns]
}

resource "platform-orchestrator_module_rule" "dns" {
  count = var.is_part_2_modules_enabled ? 1 : 0
  module_id = platform-orchestrator_module.dns[0].id
  project_id = var.humanitec_project_id
}

resource "platform-orchestrator_resource_type" "route" {
  count = var.is_part_2_modules_enabled ? 1 : 0

  id = "route${var.humanitec_id_suffix}"
  output_schema = jsonencode({
    type                 = "object"
    additionalProperties = true
  })
}

resource "platform-orchestrator_module" "route" {
  count = var.is_part_2_modules_enabled ? 1 : 0

  id            = "route${var.humanitec_id_suffix}"
  resource_type = platform-orchestrator_resource_type.route[0].id
  module_source = "git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/route/host-ingress"
  provider_mapping = {
    kubernetes = "${platform-orchestrator_provider.k8s.provider_type}.${platform-orchestrator_provider.k8s.id}"
  }

  module_params = {
    hostname = {
      type = "string"
    }
    port = {
      type = "number"
    }
  }
  module_inputs = jsonencode({
    namespace          = "$${select.consumers('workload').dependencies('score-workload').dependencies('k8s-namespace').outputs.name}"
    endpoint           = "$${select.consumers('workload').dependencies('score-workload').outputs.endpoint}"
    ingress_class_name = "nginx"
  })


  depends_on = [platform-orchestrator_resource_type.dns]
}

resource "platform-orchestrator_module_rule" "route" {
  count = var.is_part_2_modules_enabled ? 1 : 0
  module_id = platform-orchestrator_module.route[0].id
  project_id = var.humanitec_project_id
}
