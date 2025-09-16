data "kubernetes_nodes" "nodes" {
}

locals {
    node_labels = data.kubernetes_nodes.nodes.nodes[0].metadata[0].labels
    cluster_region = lookup(local.node_labels, "topology.kubernetes.io/region", "unknown")
    cluster_name = lookup(local.node_labels, "alpha.eksctl.io/cluster-name", "unknown")

    cloud_watch_query = replace(urlencode(<<EOT
SELECT `@timestamp`, `@message`
FROM `/aws/containerinsights/${local.cluster_name}/application`
WHERE `@entity.Attributes.K8s.Namespace` = '${var.namespace}'
  AND `@entity.Attributes.K8s.Workload` = '${var.metadata.name}'
ORDER BY `@timestamp` DESC
LIMIT 1000;
EOT
), "%", "*")

    cloud_watch_url = local.cluster_name == "unknown" ? "" : "https://${local.cluster_region}.console.aws.amazon.com/cloudwatch/home?region=${local.cluster_region}#logs-insights$3FqueryDetail$3D~(end~0~start~-3600~timeType~'RELATIVE~tz~'UTC~unit~'seconds~editorString~'${local.cloud_watch_query}'"
}
