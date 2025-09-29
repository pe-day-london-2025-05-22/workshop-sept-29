# Part 0 - Prepare cluster

This step needs to be done before proceeding with the workshop since it takes a bit of time to provision and some of the remaining parts of the workshop rely on it.

## Customising the EKS Cluster

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

**Success indicator:** You should see the terraform complete successfully and output information about the ingress controller installation.

## Allowing our IDE user to create roles

This needs to be done by hand unfortunately.

1. In the Workshop Studio, follow the link to "Open AWS console".
2. In the search bar, enter "Roles" and navigate to the IAM Roles page.
3. In the Roles search bar, enter "ideStack" and click on the EKS Workshop IDE Role (should be named something like `ideStackXXXXX-ideRole-XXXXX`).
4. Click on the "Permissions" tab, then select the "ide-password" policy in the policy list and click "Edit policy".
5. Click on the "JSON" tab and add the following statement to the `Statement` array (after the existing statements):

```json
{
    "Effect": "Allow",
    "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:GetRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfilesForRole",
        "iam:PassRole"
    ],
    "Resource": "*"
}
```

6. Click the "Next" and "Save changes" buttons to continue. You can ignore any warnings since this is a demo workshop.
