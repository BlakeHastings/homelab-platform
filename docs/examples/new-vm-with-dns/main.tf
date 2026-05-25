# my-vm — example VM that also registers itself in DNS as my-vm.lan
#
# REPLACE: vm_name, vm_id, mac_address, dns_hostname for your VM.
#
# Lifecycle is unified: `terraform destroy` removes both the VM and its
# DNS record. The "lan" zone itself is NOT created here — it's owned by
# homelab-services/services/dns/terraform-config/.

module "vm" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/proxmox-vm?ref=main"

  vm_name        = "my-vm"            # REPLACE
  vm_id          = 202                # REPLACE: unique Proxmox VMID
  target_node    = var.proxmox_node
  template_id    = var.template_id
  cpu_cores      = var.cpu_cores
  memory_mb      = var.memory_mb
  disk_gb        = var.disk_gb
  mac_address    = "BC:24:11:00:02:02"  # REPLACE: unique MAC for DHCP reservation
  dns_servers    = [var.gateway]        # use router for DNS during provisioning
  ssh_public_key = var.ssh_public_key
}

module "dns" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/dns-record?ref=main"

  # CNAME mode (preferred): creates my-friendly-name.lan → my-vm.lan.
  # The underlying A record on my-vm.lan is auto-registered by the router
  # via DHCP updates, so when the VM's IP changes the CNAME just follows.
  # No re-apply needed when DHCP renews.
  hostname = "my-friendly-name"                  # → my-friendly-name.lan
  cname    = "${module.vm.vm_name}.lan"          # → my-vm.lan (router-registered)
  zone     = "lan"

  # Alternative: A-record mode. Use only if you've pinned the IP via
  # router DHCP reservation or the target has a truly static IP.
  # ip       = module.vm.vm_ip
}

output "vm_ip" {
  description = "VM IP — also reachable as ${module.dns.fqdn} once DNS records propagate."
  value       = module.vm.vm_ip
}

output "vm_id" {
  value = module.vm.vm_id
}

output "vm_name" {
  value = module.vm.vm_name
}

output "fqdn" {
  description = "DNS name the VM is reachable at on the LAN."
  value       = module.dns.fqdn
}
