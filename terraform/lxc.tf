locals {
  debian_template_id = "${var.iso_storage}:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
}

# -----------------------------------------------------------------------------
# Création des LXC Debian
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_container" "debian_lxc" {
  for_each = { for ct in var.lxc_containers : ct.hostname => ct }

  vm_id     = each.value.vmid
  node_name = var.proxmox_node
  tags      = ["terraform", "debian", "lxc"]

  unprivileged  = true
  start_on_boot = true
  started       = true

  features {
    nesting = true
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.storage
    size         = each.value.disk
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  initialization {
    hostname = each.value.hostname

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.dns_server]
    }

    user_account {
      keys     = [trimspace(var.ssh_public_key)]
      password = var.root_password
    }
  }

  operating_system {
    template_file_id = local.debian_template_id
    type             = "debian"
  }
}

# -----------------------------------------------------------------------------
# Bootstrap SSH sur les LXC (sshd n'est pas actif par défaut dans Debian LXC)
# Se connecte au nœud Proxmox via SSH et lance pct exec pour chaque container
# -----------------------------------------------------------------------------
resource "null_resource" "bootstrap_lxc_ssh" {
  for_each = { for ct in var.lxc_containers : ct.hostname => ct }

  depends_on = [proxmox_virtual_environment_container.debian_lxc]

  connection {
    type     = "ssh"
    host     = var.proxmox_ssh_host
    user     = "root"
    password = var.proxmox_password
  }

  provisioner "remote-exec" {
    inline = [
      "pct exec ${each.value.vmid} -- bash -c 'apt-get update -qq && apt-get install -y openssh-server && systemctl enable --now ssh && sed -i \"s/^#*PermitRootLogin.*/PermitRootLogin yes/\" /etc/ssh/sshd_config && systemctl restart ssh'"
    ]
  }
}
