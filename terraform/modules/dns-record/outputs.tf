output "fqdn" {
  description = "Fully qualified domain name of the created record (e.g. \"zoe-vm.lan\")."
  value       = "${var.hostname}.${var.zone}"
}

output "ip" {
  description = "IPv4 address the A record points at, or null if this is a CNAME record."
  value       = var.ip
}

output "cname" {
  description = "Target FQDN the CNAME points at, or null if this is an A record."
  value       = var.cname
}

output "type" {
  description = "Record type — \"A\" or \"CNAME\" — derived from which input was set."
  value       = var.ip != null ? "A" : "CNAME"
}
