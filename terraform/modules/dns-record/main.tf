# A single A record in an existing Technitium primary zone.
#
# The technitium provider must be configured in the calling root module.
# This child module deliberately does not declare a provider block — see
# docs/decisions/dns-management.md for the rationale.

resource "technitium_dns_zone_record" "this" {
  zone       = var.zone
  domain     = "${var.hostname}.${var.zone}"
  type       = "A"
  ip_address = var.ip
  ttl        = var.ttl
}
