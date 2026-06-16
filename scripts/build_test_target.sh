#!/usr/bin/env bash
# ============================================================
# AutoProvisionX — Build Test Target Container
# ============================================================
# Builds the Docker image that simulates the provisioning
# target server and starts it as a background container.
#
# Usage:
#   ./scripts/build_test_target.sh
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTAINER_NAME="autoprovisionx-target"
IMAGE_NAME="autoprovisionx-test-target"
IMAGE_TAG="latest"

# ── Colour helpers ───────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Colour

log()  { echo -e "${CYAN}[AutoProvisionX]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ── Preflight checks ─────────────────────────────────────────
command -v docker &>/dev/null || err "Docker not found. Install Docker Desktop first."

log "Project root: ${PROJECT_ROOT}"

# ── Stop & remove existing container ─────────────────────────
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  warn "Removing existing container: ${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}"
fi

# ── Build Docker image ────────────────────────────────────────
log "Building test target image: ${IMAGE_NAME}:${IMAGE_TAG}"
docker build \
  --file "${PROJECT_ROOT}/Dockerfile.test" \
  --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
  --label "autoprovisionx=true" \
  "${PROJECT_ROOT}"

ok "Image built: ${IMAGE_NAME}:${IMAGE_TAG}"

# ── Launch container ──────────────────────────────────────────
log "Starting target container: ${CONTAINER_NAME}"
docker run \
  --detach \
  --name "${CONTAINER_NAME}" \
  --hostname "${CONTAINER_NAME}" \
  --privileged \
  --volume /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cgroupns=host \
  --publish 8080:80 \
  "${IMAGE_NAME}:${IMAGE_TAG}"

# ── Wait for container to be healthy ─────────────────────────
log "Waiting for container to initialize..."
sleep 3

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  ok "Container '${CONTAINER_NAME}' is running!"
  echo ""
  echo -e "${BOLD}Container Details:${NC}"
  docker inspect "${CONTAINER_NAME}" \
    --format 'ID: {{.Id | printf "%.12s"}}  |  Status: {{.State.Status}}  |  IP: {{.NetworkSettings.IPAddress}}'
  echo ""
  echo -e "${GREEN}Test target ready. Run ./scripts/run_provision.sh to start provisioning.${NC}"
else
  err "Container failed to start. Check: docker logs ${CONTAINER_NAME}"
fi
