#!/usr/bin/env bash
set -euo pipefail

# Build the kd-web container image and push it to AWS ECR Public (public.ecr.aws).
#
# Required:
#   ECR_PUBLIC_ALIAS   your ECR Public registry alias (e.g. "a1b2c3d4" or a custom alias)
#
# Optional (with defaults):
#   IMAGE_NAME         repository name              (default: kd-web)
#   IMAGE_TAG          primary tag                  (default: latest)
#   AWS_REGION         region for the auth token    (default: us-east-1; ECR Public requires us-east-1)
#   CONTAINER_TOOL     podman | docker              (default: auto-detect)
#   CREATE_REPO        create the repo if missing   (default: true)
#
# Usage:
#   ECR_PUBLIC_ALIAS=my-alias scripts/build-and-push.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../kd-web"

IMAGE_NAME="${IMAGE_NAME:-kd-web}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CREATE_REPO="${CREATE_REPO:-true}"
REGISTRY="public.ecr.aws"

# --- preconditions ------------------------------------------------------------
if [[ -z "${ECR_PUBLIC_ALIAS:-}" ]]; then
  echo "error: ECR_PUBLIC_ALIAS is required (your public.ecr.aws registry alias)." >&2
  echo "       e.g.  ECR_PUBLIC_ALIAS=my-alias $0" >&2
  exit 1
fi

# Pick a container tool.
CONTAINER_TOOL="${CONTAINER_TOOL:-}"
if [[ -z "$CONTAINER_TOOL" ]]; then
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_TOOL=podman
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_TOOL=docker
  else
    echo "error: neither podman nor docker found on PATH." >&2
    exit 1
  fi
fi

command -v aws >/dev/null 2>&1 || { echo "error: aws CLI not found on PATH." >&2; exit 1; }

REPO_URI="${REGISTRY}/${ECR_PUBLIC_ALIAS}/${IMAGE_NAME}"
# A second, immutable tag from the current git commit (if available).
GIT_SHA="$(git -C "$APP_DIR" rev-parse --short HEAD 2>/dev/null || echo "")"

echo "==> Tool:     $CONTAINER_TOOL"
echo "==> Registry: $REPO_URI"
echo "==> Tags:     ${IMAGE_TAG}${GIT_SHA:+, ${GIT_SHA}}"

# --- login --------------------------------------------------------------------
echo "==> Logging in to $REGISTRY ..."
aws ecr-public get-login-password --region "$AWS_REGION" \
  | "$CONTAINER_TOOL" login --username AWS --password-stdin "$REGISTRY"

# --- ensure repository exists -------------------------------------------------
if [[ "$CREATE_REPO" == "true" ]]; then
  if ! aws ecr-public describe-repositories --region "$AWS_REGION" \
        --repository-names "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "==> Creating repository '$IMAGE_NAME' ..."
    aws ecr-public create-repository --region "$AWS_REGION" \
      --repository-name "$IMAGE_NAME" >/dev/null
  fi
fi

# --- build --------------------------------------------------------------------
echo "==> Building image ..."
BUILD_ARGS=(-f "$APP_DIR/Containerfile" -t "${REPO_URI}:${IMAGE_TAG}")
[[ -n "$GIT_SHA" ]] && BUILD_ARGS+=(-t "${REPO_URI}:${GIT_SHA}")
"$CONTAINER_TOOL" build "${BUILD_ARGS[@]}" "$APP_DIR"

# --- push ---------------------------------------------------------------------
echo "==> Pushing ${REPO_URI}:${IMAGE_TAG} ..."
"$CONTAINER_TOOL" push "${REPO_URI}:${IMAGE_TAG}"
if [[ -n "$GIT_SHA" ]]; then
  echo "==> Pushing ${REPO_URI}:${GIT_SHA} ..."
  "$CONTAINER_TOOL" push "${REPO_URI}:${GIT_SHA}"
fi

echo "==> Done. Pullable at: ${REPO_URI}:${IMAGE_TAG}"
