# Part 4 - Multiple environments

So far we've deployed a single environment and shown that it can autonomously provision a variety of AWS infrastructure and deploy our application.

But to show the true scalability of this platform we've setup, we need to show cloning, promoting, and other environment lifecycles.

To start with, let's create a new copy of the dev environment:

```sh
hctl create environment workshop ephemeral-dev --set=env_type_id=development
hctl deploy workshop ephemeral-dev environment://dev
```

The `environment://dev` syntax is deploying the latest deployment state from the `dev` environment to our new `ephemeral-dev` environment.

This is doing everything again that we did for dev: a new K8s namespace, new IAM service account, new DynamoDB table, and new IAM policies.

In the UI, we can see a new environment with it's own copy of the resource graph and different metadata.

And we can tear it all down again:

```sh
hctl delete environment workshop ephemeral-dev
```

This destroys everything in the graph! Deleting IAM resources, DynamoDB tables, Kubernetes deployments, and the Kubernetes namespace itself. No more costs associated with that deployment!
