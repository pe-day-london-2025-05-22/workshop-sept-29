data "kubernetes_nodes" "nodes" {
}

locals {
    node_labels = data.kubernetes_nodes.nodes.nodes[0].metadata[0].labels
    cluster_region = lookup(local.node_labels, "topology.kubernetes.io/region", "unknown")
    cluster_name = lookup(local.node_labels, "alpha.eksctl.io/cluster-name", "unknown")
    cloud_watch_url = local.cluster_name == "unknown" ? "" : "https://${local.cluster_region}.console.aws.amazon.com/cloudwatch/home?region=${local.cluster_region}#logsV2:logs-insights$3FqueryDetail$3D~(end~0~start~-10800~timeType~'RELATIVE~tz~'UTC~unit~'seconds~editorString~'fields*20*40timestamp*2c*20*40message*0a*7c*20filter*20*40entity.Attributes.K8s.Namespace*20*3d*20*22${var.namespace}*22*0a*7c*20filter*20*40entity.Attributes.K8s.Workload*20*3d*20*22${var.metadata.name}*22*0a*7c*20sort*20*40timestamp*20desc*0a*7c*20limit*2010000~source~(~'*2faws*2fcontainerinsights*2f${local.cluster_name}*2fapplication)~lang~'CWLI)"
}
