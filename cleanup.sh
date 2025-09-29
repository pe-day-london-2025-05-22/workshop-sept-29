#!/usr/bin/env bash

set -eu

# Clean up environments (ignore failures if they don't exist)
hctl get environment workshop ephemeral-dev > /dev/null 2>&1 && hctl delete environment workshop ephemeral-dev || echo "ephemeral-dev environment not found, skipping"
hctl get environment workshop prod > /dev/null 2>&1 && hctl delete environment workshop prod || echo "prod environment not found, skipping"

# Clean up project (ignore failure if it doesn't exist)
hctl get project workshop > /dev/null 2>&1 && hctl delete project workshop || echo "workshop project not found, skipping"

# Clean up modules and resource types (ignore failures if they don't exist)
hctl get module bedrock-text-model > /dev/null 2>&1 && hctl delete module bedrock-text-model || echo "bedrock-text-model module not found, skipping"
hctl get resource-type bedrock-model > /dev/null 2>&1 && hctl delete resource-type bedrock-model || echo "bedrock-model resource type not found, skipping"
hctl get module new-dynamodb-table > /dev/null 2>&1 && hctl delete module new-dynamodb-table || echo "new-dynamodb-table module not found, skipping"
hctl get resource-type dynamodb-table > /dev/null 2>&1 && hctl delete resource-type dynamodb-table || echo "dynamodb-table resource type not found, skipping"

# Clean up terraform infrastructure (in reverse order)
echo "Cleaning up terraform infrastructure..."
(cd part_3 && terraform destroy -auto-approve) || echo "part_3 terraform destroy failed or already clean"
(cd part_2 && terraform destroy -auto-approve) || echo "part_2 terraform destroy failed or already clean"
(cd part_1 && terraform destroy -auto-approve) || echo "part_1 terraform destroy failed or already clean"

echo "Cleanup completed!"
