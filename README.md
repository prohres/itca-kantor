# kantor-infra

Infrastructure for the [kantor](https://github.com/prohres/kantor) static site: a container on ECS Fargate
behind an Application Load Balancer, images in a shared ECR registry. Built and deployed by GitHub Actions
with OIDC (no long-lived AWS keys), using reusable workflows from
[ci-templates](https://github.com/prohres/ci-templates).

## Before → after

This repo started as a course final project, renamed from `itca-kantor` (tag `legacy-codepipeline`, the old diagram is `itca-kantor.png` in that tag).

| | Before (`legacy-codepipeline`) | After |
|---|---|---|
| Terraform | 0.11 syntax, `profile = "default"` | ≥ 1.10, credentials from the environment, `allowed_account_ids`, S3 backend with lock file |
| CI/CD | CodePipeline v1 → CodeBuild → ECS, GitHub via OAuth token | GitHub Actions, OIDC role per pipeline stage |
| Image | pushed as `:latest` + short SHA (mutable tags) | built once, `IMMUTABLE` tags, deployed and promoted by digest |
| Accounts | one account | registry in the CI hub (sketch-admin), runtime in a workload account (sketch-dev) |
| Network | own VPC + NAT | default VPC, public subnets, no NAT (demo); tasks reachable only from the ALB |

## Architecture

![Architecture](architecture.png)

Source: [`architecture.drawio`](architecture.drawio) (draw.io); re-export the PNG after every change.

## Pipeline

```
kantor PR      → lint · secret scan · build · image scan            (no AWS access)
kantor develop → build once → push ECR kantor:<sha>
               → deploy dev (ECS, new task definition revision) → smoke test
```

Rollback: re-run the deploy with an earlier digest; a deploy that never gets healthy is rolled back by the
ECS deployment circuit breaker.

## Layout (`terraform/`)

| File | What |
|---|---|
| `versions.tf` | providers: sketch-dev (default) and sketch-admin (`admin`), both via `OrganizationAccountAccessRole` |
| `ecr.tf` | registry, lifecycle policy, pull access for workload accounts |
| `network.tf` | default VPC lookup, security groups (ALB :80 → tasks :8080) |
| `alb.tf` | load balancer, target group, HTTP listener |
| `ecs.tf` | cluster, logs, execution role, task definition, service |
| `deploy_role.tf` | `app-deploy`: the only role CI uses in sketch-dev |
| `variables.tf` | account ids (validated, no defaults); `desired_count`: 1 = on, 0 = app stopped between sessions |
| `*.example` | templates for the two local files kept out of git: `accounts.auto.tfvars`, `backend.local.hcl` |

## Design decisions

| Decision | Why |
|---|---|
| Registry in the CI hub, not in a workload account | the registry outlives any one environment; a new account only needs pull access |
| Lifecycle: drop untagged after 1 day, keep the last 20 builds | old builds stay available for rollback; the registry never grows without bound |
| CI owns the task definition (`ignore_changes`), Terraform creates the service with a placeholder image | otherwise every `terraform apply` would roll the service back to the image in code |
| `app-deploy` can update this one service and pass only the execution role to `ecs-tasks` | CI rolls out new revisions but can't change the infrastructure or hand the service another role; it may read load balancers to find the smoke URL (Describe only) |
| Public IP on tasks instead of NAT | NAT costs more than the whole demo; the task security group accepts traffic only from the ALB |
| Account ids out of git (local tfvars here, repo variables in CI) | the repos are public; ids aren't secrets, but they are free reconnaissance |
| Every checkov skip has a reason inline | HTTP without TLS, no WAF / access logs: accepted for the demo, listed in the roadmap |

## Apply (manual)

```bash
cd terraform
cp accounts.auto.tfvars.example accounts.auto.tfvars   # fill in the account ids
cp backend.local.hcl.example backend.local.hcl          # fill in the state bucket
AWS_PROFILE=sketch-root terraform init -backend-config=backend.hcl -backend-config=backend.local.hcl
AWS_PROFILE=sketch-root terraform plan -out=app.tfplan
AWS_PROFILE=sketch-root terraform apply app.tfplan
terraform output url
```

Stop the app between sessions: `terraform apply -var desired_count=0` (back on: `-var desired_count=1`).
Only the task stops; the ALB keeps running and billing — removing it between sessions is on the roadmap.

## Roadmap

- [ ] scale to zero / destroy from CI between sessions
- [ ] HTTPS: domain + ACM certificate
- [ ] own VPC with private subnets
- [ ] Terraform CI for this repo (plan on PR, apply after approval)
- [x] architecture diagram (`architecture.drawio`) for the new setup
