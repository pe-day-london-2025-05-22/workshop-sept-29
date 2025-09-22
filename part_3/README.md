# Part 3 - Platform Engineering of real infrastructure

In part 2, we saw that the app we deployed could take an AWS Dynamo DB and an AWS Bedrock model name as inputs for more complex behavior. In this part 3, we will be expanding the set of available resources to provision these before cloning our app to another environment.

Our app requires a Dynamo DB table and a Bedrock model. Not only do we need the runner to now have AWS access to create the Dynamo DB and validate the bedrock model, but we also need the running Score application to have access to these APIs. Good thing we're running inside EKS, for we can use the Pod Identity addon that we installed in part 0!

Therefore, we need to do the following for our app:

1. Modify the k8s service account module from part 1 to also bind an IAM Role to the pod
2. Provision a dynamo db table
3. Provision a policy statement that allows the service account of the Score workload to access the dynamo db table
4. Provision a policy statement that allows the Score workload to access AWS Bedrock

## Adding the per-service-account IAM Role

We're first going to add a new IAM role resource type and an implementation which binds it to the k8s service account using pod identity.

```sh
cd part_3

terraform init
terraform apply
```

However we now need to update our k8s-service-account module so that it also coprovisions the IAM role.

```sh
hctl update module k8s-service-account --set=coprovisioned='[{"type": "aws-iam-role", "is_dependent_on_current": true}]'
```

Now we can run our deploy again..

```sh
hctl score deploy workshop dev ./score.yaml
```

And when we look at the resource graph in the console, we'll see an IAM role associated. We can also see this in the graph nodes output:

```sh
hctl get active-resource-nodes workshop dev --out json | jq '.[] | select(.resource_type == "aws-iam-role")'
```



```sh
hctl create resource-type dynamodb-table --set-yaml=- <<"EOF"
description: "A dynamodb table"
output_schema:
  type: object
  required:
  - region
  - name
  properties:
    region: {"type": "string"}
    name: {"type": "string"}
EOF
```

TODO: create dynamodb_table module and matching rule

```sh
hctl create provider aws automatic --set-yaml=- <<"EOF"
source: "hashicorp/aws"
version_constraint: "~> 6.0"
configuration:
    region: us-west-2
EOF
```

```sh
hctl create module new-dynamodb-table --set-yaml=- <<"EOF"
resource_type: dynamodb-table
module_source: git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/dynamodb_table/new
provider_mapping:
    aws: aws.automatic
EOF
```

```sh
hctl create module-rule --set=module_id=new-dynamodb-table --set=project_id=workshop
```

TODO: provision a new score app that uses the dynamo db

TODO: notice the failure! failed to authenticate

RequestID: L6BB74RI7FHVJAAIQ6ATOA0J5RVV4KQNSO5AEMVJF66Q9ASUAAJG, api error AccessDeniedException: User: arn:aws:sts::913524934415:assumed-role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-3RBNJ5l9oZZT/i-08c90401779a867f3 is not authorized to perform: dynamodb:CreateTable on resource: arn:aws:dynamodb:us-west-2:913524934415:table/tablea05b36847a because no identity-based policy allows the dynamodb:CreateTable action

TODO: create provider and AWS identity association for the runner

TODO: add coprovision iam-role to service-account

```sh
hctl update module k8s-service-account3 --set-yaml=- <<"EOF"
coprovisioned:
- type: iam-role3
  is_dependent_on_current: true
> EOF
```


TODO: create the table
