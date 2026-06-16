# AutoProvisionX

> **Automated Linux Server Provisioning & Configuration**
> *Zero-touch server setup powered by Ansible, Docker, Bash, and GitHub Actions*

[![CI Pipeline](https://github.com/YOUR_USERNAME/AutoProvisionX/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/AutoProvisionX/actions/workflows/ci.yml)
[![Ansible](https://img.shields.io/badge/Ansible-2.14+-red?logo=ansible)](https://www.ansible.com/)
[![Docker](https://img.shields.io/badge/Docker-CE-blue?logo=docker)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-orange?logo=ubuntu)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📌 Project Overview

**AutoProvisionX** is a production-style Infrastructure-as-Code (IaC) project that demonstrates automated Linux server provisioning using industry-standard DevOps tooling. Given nothing more than a bare Ubuntu 22.04 server (simulated here as a Docker container), it fully configures the system end-to-end — from package installation through to a live, containerized web application — with **zero manual steps**.

Every configuration decision is version-controlled, every operation is idempotent, and the entire pipeline runs automatically on every code push via GitHub Actions.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Developer Workstation                      │
│                                                                 │
│   ┌──────────────────┐        ┌───────────────────────────┐    │
│   │  run_provision.sh│───────▶│     ansible-playbook      │    │
│   └──────────────────┘        └────────────┬──────────────┘    │
│                                            │                   │
│   ┌──────────────────┐                     │ community.docker   │
│   │build_test_target │───────▶┌────────────▼──────────────┐    │
│   │     .sh          │        │  Docker Container Target  │    │
│   └──────────────────┘        │  (Ubuntu 22.04 + Python)  │    │
│                                │                           │    │
│                                │  ┌─────────────────────┐ │    │
│                                │  │   Ansible Roles      │ │    │
│                                │  │                      │ │    │
│                                │  │  [base]              │ │    │
│                                │  │   └─ apt update      │ │    │
│                                │  │   └─ common packages │ │    │
│                                │  │   └─ kernel hardening│ │    │
│                                │  │                      │ │    │
│                                │  │  [users]             │ │    │
│                                │  │   └─ deploy user     │ │    │
│                                │  │   └─ SSH keys        │ │    │
│                                │  │   └─ passwordless sudo│ │    │
│                                │  │                      │ │    │
│                                │  │  [firewall]          │ │    │
│                                │  │   └─ UFW deny-in     │ │    │
│                                │  │   └─ allow ports     │ │    │
│                                │  │                      │ │    │
│                                │  │  [docker]            │ │    │
│                                │  │   └─ Docker CE repo  │ │    │
│                                │  │   └─ Docker engine   │ │    │
│                                │  │   └─ Compose plugin  │ │    │
│                                │  │                      │ │    │
│                                │  │  [webapp]            │ │    │
│                                │  │   └─ Jinja2 template │ │    │
│                                │  │   └─ nginx container │ │    │
│                                │  │   └─ port 80 exposed │ │    │
│                                │  └─────────────────────┘ │    │
│                                │                           │    │
│                                │  ┌─────────────────────┐ │    │
│                                │  │  nginx:alpine       │ │    │
│                                │  │  Container          │ │    │
│                                │  │  :80 ──────────────▶│─│──▶ Browser │
│                                │  └─────────────────────┘ │    │
│                                └───────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions CI/CD                        │
│                                                                 │
│   git push ──▶ [Lint] ──▶ [Provision] ──▶ [Verify] ──▶ Pass   │
│                  │             │               │                │
│               yamllint    ansible-playbook  nginx HTTP 200      │
│             ansible-lint  against Docker                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technologies

| Tool | Version | Purpose |
|------|---------|---------|
| **Ansible** | 2.14+ | Configuration management & orchestration |
| **community.docker** | 3.4+ | Docker container management via Ansible |
| **ansible.posix** | 1.5+ | POSIX system modules (sysctl, authorized_key) |
| **community.general** | 7.0+ | UFW, timezone, and general modules |
| **Docker CE** | Latest | Container runtime on the target server |
| **Docker Compose Plugin** | Latest | Multi-container orchestration |
| **Nginx** | 1.25-alpine | Web server (containerized) |
| **Ubuntu** | 22.04 LTS | Target server OS |
| **GitHub Actions** | — | CI/CD pipeline automation |
| **UFW** | — | Firewall management |
| **Bash** | 5.x | Helper scripts |
| **yamllint** | 1.32+ | YAML syntax validation |
| **ansible-lint** | 6.22+ | Ansible best practices enforcement |

---

## 📁 Repository Structure

```
AutoProvisionX/
├── ansible.cfg                      # Ansible runtime configuration
├── requirements.yml                 # Ansible Galaxy collection dependencies
├── Dockerfile.test                  # Ubuntu 22.04 target server image
├── .ansible-lint                    # Ansible linting rules
├── .yamllint                        # YAML formatting rules
├── .gitignore
│
├── inventory/
│   └── hosts.ini                    # Target server inventory (Docker container)
│
├── group_vars/
│   └── all.yml                      # Global variables (user, packages, ports, etc.)
│
├── playbooks/
│   └── site.yml                     # Main orchestration playbook
│
├── roles/
│   ├── base/                        # System bootstrap & packages
│   │   └── tasks/main.yml
│   ├── users/                       # Deploy user + SSH hardening
│   │   ├── tasks/main.yml
│   │   └── handlers/main.yml
│   ├── firewall/                    # UFW firewall rules
│   │   └── tasks/main.yml
│   ├── docker/                      # Docker CE + Compose installation
│   │   ├── tasks/main.yml
│   │   └── handlers/main.yml
│   └── webapp/                      # Nginx container deployment
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       ├── templates/
│       │   └── index.html.j2        # Jinja2 HTML template
│       └── files/                   # Static files (optional)
│
├── scripts/
│   ├── build_test_target.sh         # Build & launch target container
│   └── run_provision.sh             # Full provisioning orchestrator
│
└── .github/
    └── workflows/
        └── ci.yml                   # GitHub Actions pipeline
```

---

## 🎭 Role Descriptions

### `base` — System Bootstrap
Initializes the server: updates the package cache, performs a full distribution upgrade, installs common Linux tools (git, curl, vim, htop, fail2ban, unzip), applies kernel hardening via sysctl, and enables fail2ban as a brute-force protection service.

**Key modules:** `ansible.builtin.apt`, `ansible.posix.sysctl`, `community.general.timezone`

---

### `users` — Deploy User & SSH Hardening
Creates a non-root `deployer` user with a locked password (SSH-key-only login), installs the specified public key into `authorized_keys`, grants passwordless sudo via `/etc/sudoers.d/`, and hardens the SSH daemon configuration (no root login, no password auth, reduced MaxAuthTries).

**Key modules:** `ansible.builtin.user`, `ansible.posix.authorized_key`, `ansible.builtin.lineinfile`, `ansible.builtin.copy`

---

### `firewall` — UFW Network Security
Configures UFW (Uncomplicated Firewall) with a **default deny incoming / allow outgoing** policy. Opens only the ports listed in `group_vars/all.yml` (`allowed_tcp_ports: [22, 80, 443]`). Always allows loopback traffic.

**Key modules:** `community.general.ufw`, `ansible.builtin.apt`

---

### `docker` — Container Runtime
Removes legacy Docker packages, adds the official Docker GPG key and apt repository, installs Docker CE, containerd, the Compose plugin, and the buildx plugin. Ensures the Docker daemon is started and enabled at boot. Adds the deploy user to the `docker` group.

**Key modules:** `ansible.builtin.apt`, `ansible.builtin.get_url`, `ansible.builtin.apt_repository`, `ansible.builtin.service`

---

### `webapp` — Nginx Application Deployment
Renders `index.html` from a Jinja2 template (injecting live variables like app name, version, deploy user), creates the content directory on the host, pulls the nginx alpine image, and deploys it as a running container with a bind-mounted volume. The container is restarted via a handler only when the HTML content changes.

**Key modules:** `community.docker.docker_container`, `community.docker.docker_image`, `ansible.builtin.template`, `ansible.builtin.file`

---

## 🚀 Local Setup & Execution

### Prerequisites

- **Docker Desktop** (Windows/macOS) or **Docker Engine** (Linux)
- **Python 3.8+** with pip
- **Bash** (WSL2 on Windows, or native on macOS/Linux)
- **Git**

### Step 1 — Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/AutoProvisionX.git
cd AutoProvisionX
```

### Step 2 — Build the Test Target Container

This builds the Ubuntu 22.04 Docker image that simulates a bare server:

```bash
chmod +x scripts/*.sh
./scripts/build_test_target.sh
```

**Expected output:**
```
[AutoProvisionX] Building test target image: autoprovisionx-test-target:latest
[✓] Image built: autoprovisionx-test-target:latest
[AutoProvisionX] Starting target container: autoprovisionx-target
[✓] Container 'autoprovisionx-target' is running!
Container Details:
ID: a1b2c3d4e5f6  |  Status: running  |  IP: 172.17.0.2
Test target ready. Run ./scripts/run_provision.sh to start provisioning.
```

### Step 3 — Run the Provisioning

```bash
./scripts/run_provision.sh
```

Or manually:

```bash
# 1. Create virtualenv
python3 -m venv .venv && source .venv/bin/activate

# 2. Install Ansible
pip install "ansible>=8.0.0" "docker>=6.0.0"

# 3. Install Galaxy collections
ansible-galaxy collection install -r requirements.yml

# 4. Run playbook
ansible-playbook --inventory inventory/hosts.ini playbooks/site.yml -v
```

### Step 4 — Verify Nginx

```bash
# Inside the target container
docker exec autoprovisionx-target curl -s http://localhost:80 | head -5

# From your host machine (mapped to port 8080)
curl http://localhost:8080
```

### Run Only Specific Roles (Tags)

```bash
# Only run base + users roles
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags "base,users"

# Only deploy the web app
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags "webapp"

# Dry-run (check mode, no changes)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check
```

---

## ⚙️ Configuration Variables

All variables live in [`group_vars/all.yml`](group_vars/all.yml). Override any at runtime:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml \
  --extra-vars "deploy_user=myuser nginx_host_port=8080"
```

| Variable | Default | Description |
|----------|---------|-------------|
| `timezone` | `UTC` | System timezone |
| `deploy_user` | `deployer` | Non-root deploy user name |
| `deploy_ssh_public_key` | placeholder | Ed25519 public key content |
| `common_packages` | `[git, curl, vim, ...]` | Packages to install |
| `allowed_tcp_ports` | `[22, 80, 443]` | UFW inbound allowed ports |
| `nginx_container_name` | `autoprovisionx-nginx` | Docker container name |
| `nginx_image` | `nginx:1.25-alpine` | Docker image to use |
| `nginx_host_port` | `80` | Host port mapping |
| `nginx_content_dir` | `/opt/autoprovisionx/html` | HTML mount path |
| `app_name` | `AutoProvisionX` | Application name |
| `app_version` | `1.0.0` | Application version |
| `app_environment` | `production` | Deployment environment |

---

## 🔄 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and pull request to `main`.

```
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions Pipeline                   │
│                                                             │
│   Trigger: git push / pull_request                          │
│                                                             │
│   Job 1: lint                                               │
│   ├── Checkout code                                         │
│   ├── Setup Python 3.11                                     │
│   ├── Install Ansible + yamllint + ansible-lint             │
│   ├── Install Galaxy collections                            │
│   ├── Run yamllint ─────────────────── ✅ PASS / ❌ FAIL   │
│   └── Run ansible-lint ─────────────── ✅ PASS / ❌ FAIL   │
│                                                             │
│   Job 2: provision (needs: lint)                            │
│   ├── Checkout code                                         │
│   ├── Setup Python 3.11                                     │
│   ├── Install Ansible + Docker SDK                          │
│   ├── Install Galaxy collections                            │
│   ├── docker build Dockerfile.test                          │
│   ├── docker run --privileged (target container)            │
│   ├── ansible-playbook site.yml                             │
│   ├── Verify nginx container Running ── ✅ PASS / ❌ FAIL  │
│   ├── Verify HTTP 200 response ──────── ✅ PASS / ❌ FAIL  │
│   └── Cleanup containers                                    │
│                                                             │
│   Job 3: summary (needs: lint, provision)                   │
│   └── Report overall pipeline status                        │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Expected Success Output

```
PLAY [AutoProvisionX — Automated Linux Server Provisioning] ****

TASK [Verify Ansible meets minimum version requirement] ****
ok: [autoprovisionx-target] => {
    "msg": "Ansible version OK: 2.16.0"
}

TASK [base : Update apt package cache] ****
ok: [autoprovisionx-target]

TASK [base : Install common Linux packages] ****
ok: [autoprovisionx-target]

TASK [users : Create deploy user with locked password] ****
ok: [autoprovisionx-target]

TASK [firewall : Enable UFW firewall] ****
ok: [autoprovisionx-target]

TASK [docker : Install Docker CE and Compose plugin] ****
ok: [autoprovisionx-target]

TASK [webapp : Render index.html from Jinja2 template] ****
ok: [autoprovisionx-target]

TASK [webapp : Deploy nginx container] ****
ok: [autoprovisionx-target]

TASK [webapp : Assert nginx container is in running state] ****
ok: [autoprovisionx-target] => {
    "msg": "Nginx container 'autoprovisionx-nginx' is running ✅"
}

PLAY RECAP *****************************************************
autoprovisionx-target : ok=28  changed=0  unreachable=0  failed=0  skipped=0
```

---

## 📸 Screenshots

> _Add screenshots here after running locally._

| Step | Screenshot |
|------|-----------|
| Terminal — Playbook running | _![Playbook Output](docs/screenshots/playbook_run.png)_ |
| Nginx page in browser | _![Nginx Page](docs/screenshots/nginx_page.png)_ |
| GitHub Actions — CI green | _![CI Pipeline](docs/screenshots/ci_pipeline.png)_ |
| Docker container list | _![Docker PS](docs/screenshots/docker_ps.png)_ |

---

## 🎓 Learning Outcomes

By building and running AutoProvisionX, you will understand:

- ✅ **Ansible role-based architecture** — separating concerns into reusable, testable roles
- ✅ **Idempotency** — running the playbook multiple times produces the same result
- ✅ **Jinja2 templating** — generating dynamic configuration files from variables
- ✅ **Ansible handlers** — triggering service restarts only on actual changes
- ✅ **Ansible tags** — running partial playbooks for targeted deployments
- ✅ **Docker as an Ansible target** — using `community.docker` connection plugin
- ✅ **UFW firewall management** — default-deny policy with explicit port allowances
- ✅ **SSH hardening** — disabling root login and password auth
- ✅ **Passwordless sudo** — sudoers.d configuration with visudo validation
- ✅ **GitHub Actions CI/CD** — automated lint + full provisioning on every push
- ✅ **Infrastructure as Code principles** — version-controlled, repeatable, auditable

---

## 💼 Resume Impact Statement

> *"Designed and implemented AutoProvisionX, a production-grade Infrastructure-as-Code system using Ansible, Docker, Bash, and GitHub Actions. The solution automates full Linux server provisioning — from package management and user hardening through Docker Engine installation to containerized web application deployment — achieving 100% idempotency across 5 modular Ansible roles with CI/CD validation on every commit."*

**Skills demonstrated:** Ansible · Docker · GitHub Actions · UFW · Linux administration · IaC · CI/CD · Jinja2 · YAML · Bash · Security hardening · Infrastructure automation

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with ❤️ as a DevOps portfolio project · AutoProvisionX
</p>
