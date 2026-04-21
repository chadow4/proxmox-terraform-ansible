# -----------------------------------------------------------------------------
# Téléchargement de la cloud image Fedora
# -----------------------------------------------------------------------------
resource "proxmox_download_file" "fedora_cloud_image" {
  content_type = "iso"
  datastore_id = var.iso_storage
  node_name    = var.proxmox_node

  # Fedora 41 Cloud Base (qcow2 renommé en img pour Proxmox)
  url       = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
  file_name = "fedora-43-cloudbase.img"
}

# -----------------------------------------------------------------------------
# Création des VMs
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "fedora_vm" {
  for_each = { for vm in var.virtual_machines : vm.hostname => vm }

  name      = each.value.hostname
  vm_id     = each.value.vmid
  node_name = var.proxmox_node
  tags      = ["terraform", "fedora", "vm"]

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  # Disque OS — importé depuis la cloud image
  disk {
    datastore_id = var.storage
    file_id      = proxmox_download_file.fedora_cloud_image.id
    interface    = "scsi0"
    size         = each.value.disk
    file_format  = "raw"
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  # ---- Cloud-init (équivalent moderne du Kickstart pour ce use case) ----
  initialization {
    datastore_id = var.storage
    interface    = "ide2"

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
      username = "root"
      password = var.root_password
      keys     = [trimspace(var.ssh_public_key)]
    }

    # On injecte un user-data custom pour forcer SSH root + qemu-agent
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_userdata[each.key].id
  }

  serial_device {}

  depends_on = [proxmox_virtual_environment_file.cloud_init_userdata]
}

# -----------------------------------------------------------------------------
# User-data cloud-init — active SSH root + installe qemu-guest-agent
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_file" "cloud_init_userdata" {
  for_each = { for vm in var.virtual_machines : vm.hostname => vm }

  content_type = "snippets"
  datastore_id = var.iso_storage
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOF
      #cloud-config
      hostname: ${each.value.hostname}
      manage_etc_hosts: true

      users:
        - name: root
          lock_passwd: false
          ssh_authorized_keys:
            - ${trimspace(var.ssh_public_key)}

      chpasswd:
        list: |
          root:${var.root_password}
        expire: false

      ssh_pwauth: true

      # Autorise le login root en SSH
      runcmd:
        - sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        - sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
        - systemctl restart sshd
        - dnf install -y qemu-guest-agent
        - systemctl enable --now qemu-guest-agent

      package_update: true
    EOF

    file_name = "${each.value.hostname}-userdata.yaml"
  }
}
