
```
hctl create project workshop2
```

```
hctl create runner-rule --set=runner_id=workshop --set=project_id=workshop2
```

```
hctl create environment workshop2 dev --set=env_type_id=development
```

```
hctl deploy workshop2 dev - --no-prompt <<"EOF"
workloads: {}
EOF
```

Create the score resource type

```
hctl create resource-type score-workload --set=description='Score Workload' --set=output_schema='{"type":"object","required":["endpoint"], "properties":{"endpoint":{"type": "string"}}}'
```

```
hctl create module k8s-score-workload --set=resource_type=score-workload --set=module_source=git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/score-workload/kubernetes
```