# kd-cfn — CloudFormation deployment for kd-web

Deploys the `kd-web` container (from ECR Public) onto **AWS Fargate** behind an
**Application Load Balancer**, split into one template per tier and assembled by a
master stack using **nested stacks**.

```
master.yaml          # nested-stack orchestrator + cross-stack wiring
├── vpc.yaml         # VPC, IGW, two public subnets across AZs
├── alb.yaml         # ALB, security group, target group, listener
└── ecs.yaml         # ECS cluster, task definition, Fargate service, IAM, logs
```

## How the tiers are wired (cross-stack references)

The master stack passes each tier's data to the next using nested-stack output
references — the nested-stack form of a cross-stack reference:

| Produced by | Output | Consumed by (as a parameter) |
|-------------|--------|------------------------------|
| `vpc.yaml`  | `VpcId`, `PublicSubnet1Id`, `PublicSubnet2Id` | `alb.yaml`, `ecs.yaml` |
| `alb.yaml`  | `TargetGroupArn`, `AlbSecurityGroupId` | `ecs.yaml` |
| `alb.yaml`  | `LoadBalancerUrl` | master `AppUrl` output |

In `master.yaml` this looks like:

```yaml
VpcId: !GetAtt VpcStack.Outputs.VpcId
TargetGroupArn: !GetAtt AlbStack.Outputs.TargetGroupArn
```

`EcsStack` `DependsOn: AlbStack` so the ALB listener exists before the ECS
service registers with the target group.

## Deploy

Nested stacks must be uploaded to S3, so package first (this rewrites the local
`TemplateURL: ./*.yaml` references to S3 URLs), then deploy.

```bash
cd kd-cfn

# one-time: a bucket to hold the packaged templates
aws s3 mb s3://<your-cfn-artifacts-bucket>

# 1) package (uploads vpc/alb/ecs.yaml, rewrites the master)
aws cloudformation package \
  --template-file master.yaml \
  --s3-bucket <your-cfn-artifacts-bucket> \
  --s3-prefix kd-cfn \
  --output-template-file packaged.yaml

# 2) deploy the whole thing
aws cloudformation deploy \
  --template-file packaged.yaml \
  --stack-name kd-web \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides ContainerImage=public.ecr.aws/d1o2c4n7/kd-web:latest

# 3) get the URL
aws cloudformation describe-stacks --stack-name kd-web \
  --query "Stacks[0].Outputs[?OutputKey=='AppUrl'].OutputValue" --output text
```

`--capabilities CAPABILITY_IAM` is required because `ecs.yaml` creates IAM roles.

## Parameters (master)

| Name | Default | Notes |
|------|---------|-------|
| `ContainerImage` | `public.ecr.aws/d1o2c4n7/kd-web:latest` | image to run |
| `ContainerPort`  | `3000` | matches the container's `PORT` |
| `DesiredCount`   | `1` | number of Fargate tasks |
| `Cpu` / `Memory` | `256` / `512` | Fargate task size |

## Notes

- Tasks run in **public subnets with public IPs** (no NAT gateway) so they can
  pull the image and reach the internet — keeps the stack cheap. Lock this down
  with private subnets + a NAT gateway for production.
- Only port **80 (HTTP)** is exposed. Add an ACM cert + HTTPS listener for TLS.
- Match state (votes/code) lives in each task's memory, so run a **single task**
  (`DesiredCount: 1`) unless you move that state to a shared store (e.g. Redis).
- The ALB idle timeout is raised to 3600s so the app's SSE streams stay open.

## Tear down

```bash
aws cloudformation delete-stack --stack-name kd-web
```
