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

## Provisioning the Dynamo DB

Now that our running pod is getting a secure AWS identity, we can provision a dynamo DB and link it to our pod.

Create the resource type:

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

And the module:

```sh
hctl create module new-dynamodb-table --set-yaml=- <<"EOF"
resource_type: dynamodb-table
module_source: git::https://github.com/pe-workshops/workshop-sept-29//shared/modules/dynamodb_table/new
module_params:
  hash_key:
    type: string
  hash_key_type:
    is_optional: true
    type: string
  range_key:
    is_optional: true
    type: string
  range_key_type:
    is_optional: true
    type: string
module_inputs:
  context:
    org_id: "${context.org_id}"
    project_id: "${context.project_id}"
    env_id: "${context.env_id}"
  allowed_role_names: "${select.consumers('score-workload').dependencies('k8s-service-account').consumers('aws-iam-role').outputs.name}"
provider_mapping:
    aws: aws.default
EOF
```

```sh
hctl create module-rule --set=module_id=new-dynamodb-table --set=project_id=workshop
```

And we can deploy the Score file which contains the added Dynamo DB table:

```sh
hctl score deploy workshop dev ./score2.yaml
```

## Passing through the Bedrock model name

For our AWS_BEDROCK_MODEL_NAME name we're going to create a model from scratch. On the surface this is simply a string configuration value, but it has a complication: Our deployed app needs runtime permissions to invoke the model so the module needs to identify the existing IAM role and add a policy for it.

Unfortunately, for now, AWS model access needs to be granted manually in the AWS Console. So do the following steps.

1. Follow the Workshop link to sign in to the AWS Console
2. Enter "AWS Bedrock" in the top search bar and navigate to it
3. In the left hand menu, go to "Model Access" near the bottom
4. Now "Modify Model Access"
5. Select both Amazon Titan Text G1 Lite and Express
6. "Next"
7. "Submit"

We'll need a new resource type:

```sh
hctl create resource-type bedrock-model --set-yaml=- <<"EOF"
description: "A name of the AWS Bedrock model the the app can consume"
output_schema:
  type: object
  required:
  - name
  properties:
    name: {"type": "string"}
EOF
```

For the module itself, we're going to use an _inline_ module definition rather than a Git source. This is useful for testing and iteration and for entirely bespoke modules, but is limited to about 2000 characters.

```sh
hctl create module bedrock-text-model --set-yaml=- <<"EOF"
resource_type: bedrock-model
module_source: inline
module_source_code: |
  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
  }
  variable "env_type_id" {
    type = string
  }
  variable "allowed_role_names" {
    type        = list(string)
  }
  locals {
    model_name = var.env_type_id == "development" ? "amazon.titan-text-lite-v1" : "amazon.titan-text-express-v1"
  }
  resource "aws_iam_role_policy_attachment" "dynamodb_access" {
    count      = length(var.allowed_role_names)
    role       = sort(var.allowed_role_names)[count.index]
    policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockLimitedAccess"
  }
  output "name" {
    value = local.model_name
  }

  data "aws_region" "current" {}

  output "humanitec_metadata" {
    value = {
      "Bedrock-Model" = local.model_name,
      "Console-Url" = "https://${data.aws_region.current.region}.console.aws.amazon.com/bedrock/home?region=${data.aws_region.current.region}#/model-catalog/serverless/${local.model_name}",
    }
  }
module_inputs:
  env_type_id: "${context.env_type_id}"
  allowed_role_names: "${select.consumers('score-workload').dependencies('k8s-service-account').consumers('aws-iam-role').outputs.name}"
provider_mapping:
    aws: aws.default
EOF
```

And a rule to go with it for our project:

```sh
hctl create module-rule --set=module_id=bedrock-text-model --set=project_id=workshop
```

And now we can deploy the third varient of our Score file which includes the model name.

We can now use the "Generate" button in the UI!
