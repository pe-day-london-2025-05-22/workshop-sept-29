# Part 2 - Launching a Kubernetes based HTTP application

```sh
cd part_2
terraform init
terraform apply
```

```sh
hctl create project workshop
hctl create runner-rule --set=runner_id=workshop --set=project_id=workshop
hctl create environment workshop dev --set=env_type_id=development
```

```sh
hctl get available-resource-types workshop-4 dev

hctl create module-rule --set=module_id=k8s-namespace3 --set=project_id=workshop-4
hctl create module-rule --set=module_id=k8s-service-account3 --set=project_id=workshop-4
hctl create module-rule --set=module_id=k8s-score-workload3 --set=project_id=workshop-4
```

```sh
hctl score deploy workshop-4 dev ./score.yaml
```

now add a dns to grab as an ingress

```
...
resources:
  dns:
    type: dns
```

```
Creating deploy deployment...
Error: request is invalid: graph contains 1 errors:
        type=dns,class=default,id=workloads.simple.dns: no module definition matches this resource
```

```sh
hctl create resource-type dns --set-yaml=- <<"EOF"
description: "A dns name"
output_schema:
  type: object
  properties:
    hostname: {"type": "string"}
EOF
```

```sh
hctl create module dns-ingress --set-yaml=- <<"EOF"
resource_type: dns
module_source: git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/dns/nginx-ingress-nlb
provider_mapping:
  kubernetes: kubernetes.default
EOF
```

```sh
hctl create module-rule --set=module_id=dns-ingress  --set=project_id=workshop
```


```
...
resources:
  route:
    type: route
    class: 
    params:
      hostname: ${resources.dns.hostname}
      port: 80
```

```sh
hctl create resource-type route --set-yaml=- <<"EOF"
description: "A route between a dns name and a service port"
output_schema:
  type: object
  additional_properties: true
EOF
```

```sh
hctl create module route-host-ingress --set-yaml=- <<"EOF"
resource_type: route
module_source: git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/route/host-ingress
module_params:
    hostname:
        type: string
    port:
        type: number

module_inputs: 
    namespace: "${select.consumers('score-workload').dependencies('k8s-namespace').outputs.name}"
    endpoint: "${select.consumers('score-workload').outputs.endpoint}"
provider_mapping:
  kubernetes: kubernetes.default
EOF
```

```
hctl create module-rule --set=module_id=route-host-ingress --set=resource_class=host-only --set=project_id=workshop-4
```