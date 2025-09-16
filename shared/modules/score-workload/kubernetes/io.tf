variable "metadata" {
  type        = any
  description = "The metadata section of the Score file."
}

variable "containers" {
  type = map(object({
    image = string
    command = optional(list(string))
    args = optional(list(string))
    variables = optional(map(string))
    files = optional(map(object({
      source = optional(string)
      content = optional(string)
      binaryContent = optional(string)
      mode = optional(string)
      noExpand = optional(bool)
    })))
    volumes = optional(map(object({
      source = string
      path = optional(string)
      readOnly = optional(bool)
    })))
    resources = optional(object({
      limits = optional(object({
        memory = optional(string)
        cpu = optional(string)
      }))
      requests = optional(object({
        memory = optional(string)
        cpu = optional(string)
      }))
    }))
    livenessProbe = optional(object({
      httpGet = optional(object({
        host = optional(string)
        scheme = optional(string)
        path = string
        port = number
        httpHeaders = optional(list(object({
          name = string
          value = string
        })))
      }))
      exec = optional(object({
        command = list(string)
      }))
    }))
    readinessProbe = optional(object({
      httpGet = optional(object({
        host = optional(string)
        scheme = optional(string)
        path = string
        port = number
        httpHeaders = optional(list(object({
          name = string
          value = string
        })))
      }))
      exec = optional(object({
        command = list(string)
      }))
    }))
  }))
  description = "The containers section of the Score file."
}

variable "service" {
  type = object({
    ports = optional(map(object({
      port = number
      protocol = optional(string)
      targetPort = optional(number)
    })))
  })
  description = "The service section of the Score file."
  default     = null
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to deploy the resources into."
}

variable "service_account_name" {
  type        = string
  description = "The name of the service account to use for the pods."
  default     = null
}

variable "additional_annotations" {
  type        = map(string)
  description = "Additional annotations to add to all resources."
  default     = {}
}

variable "wait_for_rollout" {
  type        = bool
  description = "Whether to wait for the workload to be rolled out."
  default     = true
}

output "humanitec_metadata" {
  description = "Metadata for Humanitec."
  value = merge(
    {
      "Kubernetes-Namespace" = var.namespace
    },
    local.create_service ? { "Kubernetes-Service" = kubernetes_service_v1.default[0].metadata[0].name } : {},
    local.workload_type == "Deployment" ? { "Kubernetes-Deployment" = kubernetes_deployment_v1.default[0].metadata[0].name } : {},
    local.workload_type == "StatefulSet" ? { "Kubernetes-StatefulSet" = kubernetes_stateful_set_v1.default[0].metadata[0].name } : {},
    local.cloud_watch_url ? {"Cloud-Watch-Url" = local.cloud_watch_url} : {}
  )
}

output "endpoint" {
  value = "${var.metadata.name}.${var.namespace}.svc.cluster.local"
}
