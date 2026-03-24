# Upload cloud-init user-data snippet to Proxmox snippets storage.
# The bpg provider uses SSH to perform this upload — PROXMOX_VE_SSH_USERNAME
# and PROXMOX_VE_SSH_PASSWORD must be set in the environment.
# Snippets must be stored on "local" (not local-lvm, which lacks filesystem access).
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tpl", {
      hostname       = var.vm_name
      ssh_public_key = var.ssh_public_key
    })
    file_name = "${var.vm_name}-cloud-init.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  vm_id     = var.vm_id
  node_name = var.target_node

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  # Resize the cloned disk to var.disk_gb.
  # The template's disk must be smaller than or equal to this size.
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_gb
  }

  # Fixed MAC address — set a DHCP reservation for this MAC in your router
  # to give the VM a stable IP without hardcoding it in Terraform.
  network_device {
    bridge      = var.network_bridge
    mac_address = var.mac_address
  }

  # Cloud-init: DHCP + injected SSH key + user-data snippet.
  # IP is assigned by your router's DHCP reservation for the MAC above.
  initialization {
    datastore_id = "local"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  # Required for Terraform to detect the VM's IP address after boot.
  # qemu-guest-agent must be installed in the template.
  agent {
    enabled = true
  }

  started = true

  depends_on = [proxmox_virtual_environment_file.cloud_init]
}
