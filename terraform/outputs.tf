output "lxc_info" {
  description = "Infos des LXC créés"
  value = {
    for k, v in proxmox_virtual_environment_container.debian_lxc :
    k => {
      vmid = v.vm_id
      ip   = var.lxc_containers[index(var.lxc_containers.*.hostname, k)].ip
    }
  }
}

output "vm_info" {
  description = "Infos des VMs créées"
  value = {
    for k, v in proxmox_virtual_environment_vm.fedora_vm :
    k => {
      vmid = v.vm_id
      ip   = var.virtual_machines[index(var.virtual_machines.*.hostname, k)].ip
    }
  }
}

# -----------------------------------------------------------------------------
# Génération automatique de l'inventaire Ansible
# -----------------------------------------------------------------------------
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"
  content  = <<-EOF
    [lxc_debian]
    %{for ct in var.lxc_containers~}
    ${ct.hostname} ansible_host=${ct.ip}
    %{endfor~}

    [vm_fedora]
    %{for vm in var.virtual_machines~}
    ${vm.hostname} ansible_host=${vm.ip}
    %{endfor~}

    [debian:children]
    lxc_debian

    [fedora:children]
    vm_fedora

    [debian:vars]
    ansible_user=root
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    ansible_python_interpreter=/usr/bin/python3

    [fedora:vars]
    ansible_user=root
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    ansible_python_interpreter=/usr/bin/python3
  EOF

  depends_on = [
    proxmox_virtual_environment_container.debian_lxc,
    proxmox_virtual_environment_vm.fedora_vm
  ]
}
