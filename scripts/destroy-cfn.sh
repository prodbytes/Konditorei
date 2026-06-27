#!/usr/bin/env bash
set -euo pipefail

# Delete the kd-web CloudFormation stack (and its nested stacks), then optionally
# empty + remove the S3 artifacts bucket created by deploy-cfn.sh.
#
# Optional env:
#   STACK_NAME        stack to delete              (default: kd-web)
#   AWS_REGION        region                        (default: us-east-1)
#   ARTIFACTS_BUCKET  artifacts bucket to remove    (default: derived)
#   KEEP_BUCKET       set to "true" to keep the bucket (default: false)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFN_DIR="$SCRIPT_DIR/../kd-cfn"

STACK_NAME="${STACK_NAME:-kd-web}"
AWS_REGION="${AWS_REGION:-us-east-1}"
KEEP_BUCKET="${KEEP_BUCKET:-false}"

command -v aws >/dev/null 2>&1 || { echo "error: aws CLI not found" >&2; exit 1; }

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ARTIFACTS_BUCKET="${ARTIFACTS_BUCKET:-kd-cfn-artifacts-${ACCOUNT_ID}-${AWS_REGION}}"

echo "==> Account: $ACCOUNT_ID"
echo "==> Region:  $AWS_REGION"
echo "==> Stack:   $STACK_NAME"

# --- delete the stack --------------------------------------------------------
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "==> Deleting stack (nested stacks are removed automatically) ..."
  aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$AWS_REGION"
  echo "==> Waiting for deletion to complete ..."
  aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$AWS_REGION"
  echo "==> Stack deleted."
else
  echo "==> Stack '$STACK_NAME' not found — nothing to delete."
fi

# --- optionally remove the artifacts bucket ----------------------------------
if [[ "$KEEP_BUCKET" != "true" ]] && aws s3api head-bucket --bucket "$ARTIFACTS_BUCKET" >/dev/null 2>&1; then
  echo "==> Emptying and removing artifacts bucket $ARTIFACTS_BUCKET ..."
  aws s3 rb "s3://$ARTIFACTS_BUCKET" --force >/dev/null
  echo "==> Bucket removed."
fi

# Clean up the local packaged template if present.
rm -f "$CFN_DIR/packaged.yaml"

echo "==> Done."
