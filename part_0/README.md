# Part 0 - Prepare cluster

This step needs to be done before proceeding with the workshop since it takes a bit of time to provision and some of the remaining parts of the workshop rely on it.

We're going to customise the EKS workshop cluster by installing some addons:

1. Setup the EKS Pod Identity Addon.
2. Setup the EKS Cloud Watch container insights Addon.
3. Install the Nginx Ingress controller and launch an EC2 network load balancer in front of the cluster.

These choices are not required by the platform orchestrator specifically and can be replaced by comparable functionality in other cloud providers or ingress implementations.

REMINDER: you must execute these inside the AWS Workshop environment and not on your local terminal otherwise you may have unintended side effects.

```sh
cd part_0/
terraform init
terraform apply -auto-approve
```
