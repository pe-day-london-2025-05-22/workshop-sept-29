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

Let's look at what resources are available:

```sh
hctl get available-resource-types workshop dev --out yaml
```

And finally deploy our score file.

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

Now when we deploy the Score file again, it should successfully provision a DNS and Route implementation in the graph.

If we inspect the metadata fields on the route or dns object, we can find the web url and browse to it.

The result should be a running web app with a message of the day which shows that we can pass environmental context through the graph. However, two warning messages show that we can make this even more complex in part 3!
