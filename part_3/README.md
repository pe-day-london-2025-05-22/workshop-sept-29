

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
module_source: git::https://github.com/pe-day-london-2025-05-22/workshop-sept-29//shared/modules/dynamodb_table/new
provider_mapping:
    aws: aws.automatic
EOF
```

```sh
hctl create module-rule --set=module_id=new-dynamodb-table --set=project_id=workshop
```

TODO: provision a new score app that uses the dynamo db

TODO: notice the failure! failed to authenticate

TODO: create provider and AWS identity association for the runner




TODO: create the table
