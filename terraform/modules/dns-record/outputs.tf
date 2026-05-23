output "fqdn" {
  description = "Fully qualified domain name of the created record (e.g. \"zoe-vm.lan\")."
  value       = "${var.hostname}.${var.zone}"
}

output "ip" {
  description = "IPv4 address the record points at — echoes var.ip for convenience in module compositions."
  value       = var.ip
}
