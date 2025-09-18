# Part 2 - Launching a Kubernetes based HTTP application

Part 2 introduces the Score workload specification and how the Platform Orchestrator can support developers by abstracting away application deployment and resources.

The [Score spec](https://docs.score.dev/docs/score-specification/score-spec-reference/) defines a simplified manifest for generic container based applications that can be deployed on a variety of different container runtimes and hosts.

As an example of this, we're going to deploy the score file: [score.yaml](./score.yaml) which contains a simple Nginx HTTP server and a customized index html page.

First, we need to configure our environment types, resource types, and modules that we're going to rely on here. We're using some more prebuilt terraform.

```sh
cd part_2
terraform init
terraform apply
```

Next, we need to use our hctl CLI to setup a new Project and link our Runner to it. We'll then create a development environment to work in.

```sh
hctl create project workshop
hctl create runner-rule --set=runner_id=workshop --set=project_id=workshop
hctl create environment workshop dev --set=env_type_id=development
```

If we tried to deploy our Score file now, we'd get an error because there are no implementations of the Score Workload resource type available!

```sh
hctl score deploy workshop dev ./score.yaml
```

We can confirm this by looking at the available resource types:

```sh
hctl get available-resource-types workshop dev
```

To fix this, we must setup the rules in the orchestrator to use the new modules for our project.

```sh
hctl create module-rule --set=module_id=eks-cluster3 --set=project_id=workshop
hctl create module-rule --set=module_id=k8s-namespace3 --set=project_id=workshop
hctl create module-rule --set=module_id=k8s-service-account3 --set=project_id=workshop
hctl create module-rule --set=module_id=k8s-score-workload3 --set=project_id=workshop
hctl get available-resource-types workshop dev
```

Now we can deploy our application.

```sh
hctl score deploy workshop dev ./score.yaml
```

Hopefully, the deployment completed without errors. We can now go an look at our environment resource graph in <https://console.humanitec.dev>. Look at Projects > workshop > dev and click on the various resource nodes. Notice how even though the Score workload did not request any resources explicitly, some were linked into the resource graph as automatical dependencies.

Let's look now at how we as developers request resources and we fulfill those with modules. In this case, let's request a DNS name to expose the application to our public network (the internet).

Add the following to the bottom of the Score file:

```yaml
resources:
  dns:
    type: dns
  route:
    type: route
    params:
      hostname: ${resources.dns.hostname}
      port: 80
```

If we deploy this now, we should get an error!

```
Creating deploy deployment...
Error: request is invalid: graph contains 1 errors:
        type=dns,class=default,id=workloads.simple.dns: no module definition matches this resource
```

This is because our platform engineer (us) hasn't configured a `dns` resource type or modules that can fulfull it. Same with the `route` type.

Enable the new modules and rerun the Terraform

```sh
export TF_VAR_is_part_2_modules_enabled=true

terraform apply
```

And link the modules to our project

```sh
hctl create module-rule --set=module_id=dns-ingress --set=project_id=workshop
hctl create module-rule --set=module_id=route-host-ingress --set=project_id=workshop
```

Now when we deploy the Score file again, it should successfully provision a DNS and Route implementation in the graph.

If we inspect the metadata fields on the route or dns object, we can find the web url and browse to it.
