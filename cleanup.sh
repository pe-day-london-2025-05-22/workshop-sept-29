#!/usr/bin/env bash

set -eu

hctl get environment workshop dev-ephemeral && hctl delete environment workshop dev-ephemeral
hctl get environment workshop dev && hctl delete environment workshop dev
hctl get project workshop && hctl delete project workshop

hctl get module bedrock-text-model && hctl delete module bedrock-text-model

(cd part_3; terraform destroy)
(cd part_2; terraform destroy)
(cd part_1; terraform destroy)
