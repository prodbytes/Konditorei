#!/usr/bin/env bash
set -euo pipefail

# Package + deploy the kd-cfn nested stacks, then print and verify the app URL.
#
# Optional env:
#   STACK_NAME        CloudFormation stack name   (default: kd-web)
#   AWS_REGION        region to deploy into        (default: us-east-1)
#   CONTAINER_IMAGE   image to run                 (default: ECR Public kd-web:latest)
#   ARTIFACTS_BUCKET  S3 bucket for packaged templates (default: derived, auto-created)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFN_DIR="$SCRIPT_DIR/../kd-cfn"

STACK_NAME="${STACK_NAME:-kd-web}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CONTAINER_IMAGE="${CONTAINER_IMAGE:-public.ecr.aws/d1o2c4n7/kd-web:latest}"

command -v aws >/dev/null 2>&1 || { echo "error: aws CLI not found" >&2; exit 1; }

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ARTIFACTS_BUCKET="${ARTIFACTS_BUCKET:-kd-cfn-artifacts-${ACCOUNT_ID}-${AWS_REGION}}"

echo "==> Account: $ACCOUNT_ID"
echo "==> Region:  $AWS_REGION"
echo "==> Stack:   $STACK_NAME"
echo "==> Image:   $CONTAINER_IMAGE"
echo "==> Bucket:  $ARTIFACTS_BUCKET"

# --- ensure the artifacts bucket exists --------------------------------------
if ! aws s3api head-bucket --bucket "$ARTIFACTS_BUCKET" >/dev/null 2>&1; then
  echo "==> Creating artifacts bucket ..."
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$ARTIFACTS_BUCKET" --region "$AWS_REGION" >/dev/null
  else
    aws s3api create-bucket --bucket "$ARTIFACTS_BUCKET" --region "$AWS_REGION" \
      --create-bucket-configuration "LocationConstraint=$AWS_REGION" >/dev/null
  fi
fi

# --- package (uploads nested templates, rewrites TemplateURLs) ----------------
PACKAGED="$CFN_DIR/packaged.yaml"
echo "==> Packaging nested templates ..."
aws cloudformation package \
  --template-file "$CFN_DIR/master.yaml" \
  --s3-bucket "$ARTIFACTS_BUCKET" \
  --s3-prefix kd-cfn \
  --region "$AWS_REGION" \
  --output-template-file "$PACKAGED" >/dev/null

# --- deploy ------------------------------------------------------------------
echo "==> Deploying stack (this can take several minutes) ..."
aws cloudformation deploy \
  --template-file "$PACKAGED" \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides "ContainerImage=$CONTAINER_IMAGE"

# --- read the output URL -----------------------------------------------------
APP_URL="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='AppUrl'].OutputValue" --output text)"

# --- verify ------------------------------------------------------------------
echo "==> Waiting for the app to respond at $APP_URL ..."
STATUS="down"
for i in $(seq 1 30); do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$APP_URL" || echo 000)"
  if [[ "$code" == "200" || "$code" == 3* ]]; then
    STATUS="up"
    echo "    HTTP $code — app is responding"
    break
  fi
  echo "    not ready (HTTP $code), retry $i/30 ..."
  sleep 10
done

echo
echo "============================================================"
echo " App URL: $APP_URL"
echo " Status:  $STATUS"
echo "============================================================"
[[ "$STATUS" == "up" ]] || { echo "warning: app did not respond in time (check ECS/ALB)"; exit 1; }
