

TODO: create dynamodb_table resource type


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
