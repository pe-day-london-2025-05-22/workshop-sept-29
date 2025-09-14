# Part 0 - Prepare cluster ingress

This step needs to be done before proceeding with the workshop since it takes a bit of time to provision and some of the remaining parts of the workshop rely on it.

This step provisions an AWS Network Load Balancer infront of the EKS cluster, linked to an NGINX ingress controller.

We're using NLB and the NGINX ingress because these are simple, cheap, and easy to configure, but you might want to use something more specific in a production setting.

Since the DNS name of the NLB takes some minutes to become resolvable, you should do this step before proceeding with the remaining parts otherwise you may have issues.
