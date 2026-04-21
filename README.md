# Proxmox Lab — Terraform + Ansible

Provisionne **3 LXC Fedora** + **2 VMs Fedora** sur Proxmox, puis les teste avec Ansible.

**Proxmox configuré :** `https://192.168.1.38:8006/` (root / password)

## 📋 Plan d'adressage

| Type | Hostname       | IP              | VMID |
|------|----------------|-----------------|------|
| LXC  | fedora-lxc-01  | 192.168.1.10    | 201  |
| LXC  | fedora-lxc-02  | 192.168.1.11    | 202  |
| LXC  | fedora-lxc-03  | 192.168.1.12    | 203  |
| VM   | fedora-vm-01   | 192.168.1.20    | 301  |
| VM   | fedora-vm-02   | 192.168.1.21    | 302  |

## 📂 Structure

```
proxmox-lab/
├── terraform/
│   ├── providers.tf        # Provider bpg/proxmox
│   ├── variables.tf        # Toutes les variables
│   ├── lxc.tf              # 3 LXC Fedora
│   ├── vms.tf              # 2 VMs Fedora + cloud-init
│   ├── outputs.tf          # Génère l'inventaire Ansible
│   ├── terraform.tfvars    # ← déjà rempli avec tes infos
│   └── terraform.tfvars.example
└── ansible/
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts.ini       # ← généré par Terraform
    └── playbooks/
        └── test-all.yml
```

## 🚀 Utilisation

### 1. Ajouter ta clé SSH publique

Édite `terraform/terraform.tfvars` et remplace la ligne `ssh_public_key` par ta vraie clé :

```bash
cat ~/.ssh/id_ed25519.pub   # ou id_rsa.pub
# copie le résultat dans terraform.tfvars
```

Si tu n'en as pas :
```bash
ssh-keygen -t ed25519 -C "ton_user@ta_machine"
```

### 2. Lancer Terraform

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

Ça va :
- Télécharger le template LXC Fedora 41 sur le storage `local`
- Télécharger la cloud image Fedora 41 sur le storage `local`
- Créer les 3 LXC (VMIDs 201-203) avec hostname, IP statique, SSH root activé
- Créer les 2 VMs (VMIDs 301-302) avec cloud-init (hostname, IP statique, SSH root activé, qemu-guest-agent)
- Générer l'inventaire Ansible `ansible/inventory/hosts.ini`

### 3. Lancer Ansible

```bash
cd ../ansible/
ansible all -m ping                         # test rapide
ansible-playbook playbooks/test-all.yml     # tests complets
```

## 🔐 Sécurité

Le fichier `terraform.tfvars` contient le mot de passe root Proxmox en clair. **Il est exclu de Git** via `.gitignore`. Pour une utilisation sérieuse :
- Change le mot de passe `password` pour quelque chose de fort
- Utilise un token API Proxmox au lieu du password (je peux adapter si tu veux)
- Mets les secrets dans un vault (sops, Vault, etc.)

## 🧠 Kickstart vs cloud-init

Tu parlais de Kickstart — pour ton use case (provisioning automatisé sur hyperviseur), **cloud-init** est l'équivalent moderne et c'est ce qui est utilisé ici. Install en ~30s depuis une cloud image, vs ~10 min d'install ISO complète avec Kickstart. Si tu veux vraiment du Kickstart pur, dis-le moi, je peux adapter la partie VM.

## 🔄 Destruction

```bash
cd terraform/
terraform destroy
```

## ⚠️ Si ça foire au téléchargement des images

Les URLs dans `lxc.tf` et `vms.tf` pointent vers Fedora 41. Si le fichier n'existe plus (nouvelle release Fedora) :
- Template LXC : aller sur `http://download.proxmox.com/images/system/` et chercher le dernier `fedora-*.tar.xz`
- Cloud image : aller sur `https://download.fedoraproject.org/pub/fedora/linux/releases/` pour la dernière version Cloud Base

Alternativement, télécharge manuellement via l'UI Proxmox :
- **CT Templates** → onglet Templates → chercher "fedora"
- **ISO Images** → télécharger depuis URL la cloud image Fedora
