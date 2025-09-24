#!/usr/bin/env bash

set -eu

hctl get environment workshop ephemeral-dev && hctl delete environment workshop ephemeral-dev
hctl get environment workshop dev && hctl delete environment workshop dev
hctl get project workshop && hctl delete project workshop

hctl get module bedrock-text-model && hctl delete module bedrock-text-model
hctl get resource-type bedrock-model && hctl delete resource-type bedrock-model
hctl get module new-dynamodb-table && hctl delete module new-dynamodb-table
hctl get resource-type dynamodb-table && hctl delete resource-type dynamodb-table

(cd part_3; terraform destroy)
(cd part_2; terraform destroy)
(cd part_1; terraform destroy)
