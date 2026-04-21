#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# deploy.sh — Provisionne l'infra Proxmox puis valide via Ansible
# Usage : ./deploy.sh [--destroy]
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}==> $1${NC}"; }
ok()   { echo -e "${GREEN}✔ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
die()  { echo -e "${RED}✘ $1${NC}" >&2; exit 1; }

# -----------------------------------------------------------------------------
# --destroy : détruit toute l'infra et quitte
# -----------------------------------------------------------------------------
if [[ "${1:-}" == "--destroy" ]]; then
  step "Destruction de l'infra Terraform"
  cd "$TF_DIR"
  terraform destroy
  ok "Infra détruite"
  exit 0
fi

# -----------------------------------------------------------------------------
# 1. Terraform init
# -----------------------------------------------------------------------------
step "Terraform — init"
cd "$TF_DIR"
terraform init -upgrade
ok "Init OK"

# -----------------------------------------------------------------------------
# 2. Terraform plan
# -----------------------------------------------------------------------------
step "Terraform — plan"
terraform plan -out=tfplan
ok "Plan OK"

# -----------------------------------------------------------------------------
# 3. Terraform apply
# -----------------------------------------------------------------------------
step "Terraform — apply"
terraform apply tfplan
rm -f tfplan
ok "Apply OK"

# -----------------------------------------------------------------------------
# 4. Pause — laisser les machines finir leur boot et cloud-init
# -----------------------------------------------------------------------------
step "Attente démarrage des machines (10s)"
sleep 10

# -----------------------------------------------------------------------------
# 5. Ansible — test de connectivité et validation
# -----------------------------------------------------------------------------
step "Ansible — vérification de toutes les machines"
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory/hosts.ini playbooks/test-all.yml
ok "Toutes les machines sont validées"

echo -e "\n${GREEN}${BOLD}Déploiement terminé avec succès.${NC}"
