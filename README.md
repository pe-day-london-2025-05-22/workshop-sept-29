# Welcome to the September 29 AWS Platform Engineering Workshop

1. Set up your AWS Workshop Studio environment
2. Go to <https://console.humanitec.dev> and register for an account and free org
3. Enter the hosted VSCode IDE
4. Clone the workshop GitHub repo inside the IDE `git clone https://github.com/pe-workshops/workshop-sept-29.git` and follow the README's from within that directory.

Prerequisites:

1. A Google account to sign up to Humanitec
2. A web browser
3. Some familiarity with Terraform or OpenTofu is recommended but not necessary

## Structure

All of these parts should be completed from inside the Workshop Studio IDE other than web browser activities.

### Part 0

[Part 0](./part_0/README.md) contains general setup and prep steps for the workshop AWS infrastructure. This only needs to be done once. 

It may take a few minutes so try to start this early.

### Part 1

[Part 1](./part_1/README.md) introduces the Humanitec Platform Orchestrator and guides you through connecting it to your workshop Kubernetes cluster.

You need that Humanitec organization that you signed up for here.

### Part 2

[Part 2](./part_2/README.md) introduces the Score workload specification and how the Platform Orchestrator can support developers by abstracting away application deployment and resources.

### Part 3

[Part 3](./part_3/README.md) introduces the concepts of platform engineering modules and how to write them for maximum leverage.

### Part 4

[Part 4](./part_4/README.md) introduces cloning and promoting between environments as well as deleting environments when no longer needed.
