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
