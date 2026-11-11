# Partial backend configuration: terraform init -backend-config=backend.hcl -backend-config=backend.local.hcl
# Same state bucket as sketch-infra; CI roles there can't write this key.
region       = "eu-central-1"
encrypt      = true
use_lockfile = true
