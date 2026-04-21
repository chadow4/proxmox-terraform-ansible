variable "proxmox_endpoint" {
  description = "URL de l'API Proxmox (ex: https://192.168.1.2:8006/)"
  type        = string
}

variable "proxmox_username" {
  description = "Utilisateur API (ex: root@pam)"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Mot de passe de l'API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nom du noeud Proxmox"
  type        = string
  default     = "pve"
}

variable "storage" {
  description = "Nom du storage Proxmox (ex: local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "iso_storage" {
  description = "Storage où sont les ISO et templates CT"
  type        = string
  default     = "local"
}

variable "bridge" {
  description = "Bridge réseau (ex: vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Passerelle réseau"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_server" {
  description = "Serveur DNS"
  type        = string
  default     = "192.168.1.1"
}

variable "ssh_public_key" {
  description = "Clé SSH publique à injecter dans root"
  type        = string
}

variable "root_password" {
  description = "Mot de passe root pour LXC et VM"
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_host" {
  description = "IP ou hostname du nœud Proxmox pour SSH (ex: 192.168.1.2)"
  type        = string
}

# ------- Définitions des machines -------

variable "lxc_containers" {
  description = "Liste des LXC Fedora à créer"
  type = list(object({
    vmid     = number
    hostname = string
    ip       = string
    cores    = number
    memory   = number
    disk     = number
  }))
  default = [
    { vmid = 201, hostname = "debian-lxc-01", ip = "192.168.1.10", cores = 2, memory = 1024, disk = 8 },
    { vmid = 202, hostname = "debian-lxc-02", ip = "192.168.1.11", cores = 2, memory = 1024, disk = 8 },
    { vmid = 203, hostname = "debian-lxc-03", ip = "192.168.1.12", cores = 2, memory = 1024, disk = 8 },
  ]
}

variable "virtual_machines" {
  description = "Liste des VMs cloud-init à créer"
  type = list(object({
    vmid     = number
    hostname = string
    ip       = string
    cores    = number
    memory   = number
    disk     = number
  }))
  default = [
    { vmid = 301, hostname = "fedora-vm-01", ip = "192.168.1.20", cores = 2, memory = 2048, disk = 20 },
    { vmid = 302, hostname = "fedora-vm-02", ip = "192.168.1.21", cores = 2, memory = 2048, disk = 20 },
  ]
}
