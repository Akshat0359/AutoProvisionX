#!/usr/bin/env bash
# ============================================================
# AutoProvisionX — Run Full Provisioning
# ============================================================
# Installs Ansible dependencies and executes the main playbook
# against the running test target container.
#
# Prerequisites:
#   - Python 3.8+ and pip installed
#   - Target container running (./scripts/build_test_target.sh)
#
# Usage:
#   ./scripts/run_provision.sh           # Full run
#   ./scripts/run_provision.sh --tags base,users   # Partial run
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTAINER_NAME="autoprovisionx-target"
VENV_DIR="${PROJECT_ROOT}/.venv"

# Pass extra args through to ansible-playbook
EXTRA_ARGS="${*}"

# ── Colour helpers ───────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[AutoProvisionX]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
banner() {
  echo ""
  echo -e "${BOLD}${CYAN}=============================================="
  echo -e "  AutoProvisionX — Server Provisioning"
  echo -e "==============================================${NC}"
  echo ""
}

banner

# ── Preflight checks ─────────────────────────────────────────
command -v python3 &>/dev/null || err "Python 3 is required."
command -v docker  &>/dev/null || err "Docker is required."

# Ensure target container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  err "Target container '${CONTAINER_NAME}' is not running.\nRun: ./scripts/build_test_target.sh"
fi

ok "Target container '${CONTAINER_NAME}' is running."

# ── Virtual environment setup ─────────────────────────────────
if [[ ! -d "$VENV_DIR" ]]; then
  log "Creating Python virtual environment at ${VENV_DIR}"
  python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
log "Virtual environment activated."

# ── Install Python dependencies ───────────────────────────────
log "Installing Ansible and linting tools..."
pip install --quiet --upgrade pip
pip install --quiet \
  "ansible>=8.0.0" \
  "ansible-lint>=6.22.0" \
  "yamllint>=1.32.0"

ok "Python packages installed."

# ── Install Ansible Galaxy collections ────────────────────────
log "Installing Ansible Galaxy collections..."
ansible-galaxy collection install \
  --requirements-file "${PROJECT_ROOT}/requirements.yml" \
  --force-with-deps 2>/dev/null || true

ok "Galaxy collections installed."

# ── Run yamllint ──────────────────────────────────────────────
log "Running yamllint..."
yamllint --config-file "${PROJECT_ROOT}/.yamllint" "${PROJECT_ROOT}" \
  --no-warnings 2>&1 | head -50 || warn "yamllint found issues (non-blocking)"

# ── Run ansible-lint ─────────────────────────────────────────
log "Running ansible-lint..."
ansible-lint --config-file "${PROJECT_ROOT}/.ansible-lint" \
  "${PROJECT_ROOT}/playbooks/site.yml" 2>&1 | head -50 || warn "ansible-lint found issues (non-blocking)"

# ── Execute Ansible Playbook ──────────────────────────────────
log "Executing Ansible playbook..."
echo ""

cd "${PROJECT_ROOT}"

# shellcheck disable=SC2086
ansible-playbook \
  --inventory inventory/hosts.ini \
  playbooks/site.yml \
  ${EXTRA_ARGS}

PLAYBOOK_EXIT=$?

# ── Results ───────────────────────────────────────────────────
echo ""
if [[ $PLAYBOOK_EXIT -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║   ✅  PROVISIONING COMPLETE — SUCCESS        ║"
  echo "╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
  log "Nginx should be reachable at: http://localhost:8080"
  log "Container logs: docker logs ${CONTAINER_NAME}"
else
  echo -e "${RED}${BOLD}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║   ✗  PROVISIONING FAILED                    ║"
  echo "╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
  err "Playbook exited with code ${PLAYBOOK_EXIT}. Check output above."
fi
