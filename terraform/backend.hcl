# Partial backend configuration: terraform init -backend-config=backend.hcl
# Same state bucket as sketch-infra; CI roles there can't write this key.
bucket       = "sketch-tfstate-183691668268"
region       = "eu-central-1"
encrypt      = true
use_lockfile = true
