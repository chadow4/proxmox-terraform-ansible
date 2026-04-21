#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# destroy.sh — Détruit toute l'infra Proxmox provisionnée par Terraform
# Usage : ./destroy.sh [--force]
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}==> $1${NC}"; }
ok()   { echo -e "${GREEN}✔ $1${NC}"; }
die()  { echo -e "${RED}✘ $1${NC}" >&2; exit 1; }

cd "$TF_DIR"

# Vérifie qu'il y a bien un state à détruire
if [[ ! -f terraform.tfstate ]] || [[ "$(terraform state list 2>/dev/null | wc -l)" -eq 0 ]]; then
  die "Aucune ressource dans le state Terraform — rien à détruire."
fi

echo -e "${YELLOW}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║   ⚠️  ATTENTION : DESTRUCTION DE L'INFRA     ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo "Les ressources suivantes vont être supprimées :"
echo ""
terraform state list
echo ""

# Confirmation interactive sauf si --force
if [[ "${1:-}" != "--force" ]]; then
  read -r -p "Confirmer la destruction ? [oui/N] " confirm
  [[ "$confirm" == "oui" ]] || { echo "Annulé."; exit 0; }
fi

step "Initialisation Terraform"
terraform init -upgrade

step "Destruction de l'infra"
terraform destroy -auto-approve
ok "Toute l'infra a été détruite"
