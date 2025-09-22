# ===========================================
# Providers
# ===========================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
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

variable "humanitec_runner_id" {
  type        = string
  default     = "workshop"
  description = "Runner ids have to be unique, if there is already a runner with this ID and it can't be deleted or used, you can use this to use a new runner ID"
}

variable "eks_cluster_name" {
  type = string
  default = "eks-workshop"
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
  hctl_config_file = "/home/ec2-user/.config/hctl/config.yaml"
  org_id = var.humanitec_org_id
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "aws" {
}

# ===========================================
# AWS Related OIDC Role assumption
# ===========================================

data "aws_eks_cluster" "workshop" {
  name = var.eks_cluster_name
}

locals {
  account_id = provider::aws::arn_parse(data.aws_eks_cluster.workshop.arn).account_id
}

resource "aws_iam_openid_connect_provider" "default" {
  url = "https://oidc.humanitec.dev"
  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_role" "humanitec_runner_role" {
  name_prefix = "humanitec_runner_role"
  description = "Role for Humanitec Orchestrator to access the workshop EKS cluster for launching runners"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.default.arn,
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.humanitec.dev:aud": "sts.amazonaws.com",
            "oidc.humanitec.dev:sub": "${var.humanitec_org_id}+${var.humanitec_runner_id}",
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "humanitec_runner_policy" {
  name_prefix = "humanitec_runner_policy"
  role = aws_iam_role.humanitec_runner_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ],
        Resource = data.aws_eks_cluster.workshop.arn
      }
    ]
  })
}

resource "aws_eks_access_entry" "humanitec_runner" {
  cluster_name      = data.aws_eks_cluster.workshop.name
  principal_arn     = aws_iam_role.humanitec_runner_role.arn
  type              = "STANDARD"
}

locals {
  session_name = substr("${var.humanitec_org_id}_${var.humanitec_runner_id}", 0, 64)
  k8s_user_identity = "arn:aws:sts::${local.account_id}:assumed-role/${aws_iam_role.humanitec_runner_role.name}/${local.session_name}"
}

# ===========================================
# Kubernetes resources for the runner
# ===========================================

resource "kubernetes_namespace_v1" "po" {
  metadata {
    name = "platform-orchestrator"
  }
}

resource "kubernetes_role_v1" "humanitec" {
  metadata {
    generate_name = "humanitec"
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["create", "get", "list", "watch", "delete"]
  }
}

resource "kubernetes_role_binding_v1" "humanitec" {
  metadata {
    generate_name = "humanitec-custom-role"
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
  subject {
    kind      = "User"
    name      = local.k8s_user_identity
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.humanitec.metadata[0].name
  }
}

// The actual runner pods execute as a service account that needs permissions to at least store
// it's kubernetes state file in kubernetes secrets. We will grant it more permissions later
// if we need to.
resource "kubernetes_service_account_v1" "runner" {
  metadata {
    generate_name = "runner"
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
}

resource "kubernetes_role_v1" "runner" {
  metadata {
    generate_name = "runner"
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "update", "get", "list", "watch", "delete"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create", "get", "update"]
  }
}

resource "kubernetes_role_binding_v1" "runner" {
  metadata {
    generate_name = "runner-custom-role"
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.runner.metadata[0].name
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.runner.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding_v1" "runner-admin" {
  metadata {
    generate_name = "runner-admin-cluster-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.runner.metadata[0].name
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
}

resource "kubernetes_cluster_role_v1" "runner" {
  metadata {
    generate_name = "runner"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["create", "update", "get", "list", "watch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "runner" {
  metadata {
    generate_name = "runner-custom-cluster-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.runner.metadata[0].name
    namespace = kubernetes_namespace_v1.po.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.runner.metadata[0].name
  }
}

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

resource "aws_iam_role" "humanitec-runner-inner" {
  name_prefix = "humanitec_runner_inner_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_eks_pod_identity_association" "example" {
  region = data.aws_eks_cluster.workshop.region
  cluster_name    = data.aws_eks_cluster.workshop.region.name
  namespace       = kubernetes_namespace_v1.po.metadata[0].name
  service_account = kubernetes_service_account_v1.runner.metadata[0].name
  role_arn        = aws_iam_role.humanitec-runner-inner.arn
}

# ===========================================
# Register the agent runner in the humanitec platform orchestrator
# ===========================================

resource "platform-orchestrator_kubernetes_eks_runner" "workshop" {
  id = var.humanitec_runner_id
  runner_configuration = {
    cluster = {
      name = data.aws_eks_cluster.workshop.name
      region = data.aws_eks_cluster.workshop.region
      auth = {
        role_arn = aws_iam_role.humanitec_runner_role.arn
        session_name = local.session_name
      }
    }
    job = {
      namespace       = kubernetes_namespace_v1.po.metadata[0].name
      service_account = kubernetes_service_account_v1.runner.metadata[0].name
    }
  }
  state_storage_configuration = {
    type = "kubernetes"
    kubernetes_configuration = {
      namespace = kubernetes_namespace_v1.po.metadata[0].name
    }
  }
}

output "runner_url" {
  value = "https://console.humanitec.dev/orgs/${var.humanitec_org_id}/runners/${platform-orchestrator_kubernetes_eks_runner.workshop.id}/configuration"
}

output "kubernetes_runner_namespace" {
  value = kubernetes_namespace_v1.po.metadata[0].name
}

output "kubernetes_runner_service_account" {
  value = kubernetes_service_account_v1.runner.metadata[0].name
}
