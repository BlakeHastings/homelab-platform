# A single A-record OR CNAME in an existing Technitium primary zone.
#
# Exactly one of var.ip / var.cname must be set — enforced by the
# validation block below. The two resource declarations are gated on which
# variable is populated; only one ever materialises per module instance.
#
# The technitium provider must be configured in the calling root module.
# This child module deliberately does not declare a provider block — see
# docs/decisions/dns-management.md for the rationale.

resource "terraform_data" "validate_mode" {
  # Fails plan if both or neither of ip/cname are set.
  lifecycle {
    precondition {
      condition     = (var.ip == null) != (var.cname == null)
      error_message = "Set exactly one of `ip` (creates an A record) or `cname` (creates a CNAME). Both null or both set is an error."
    }
  }
}

resource "technitium_dns_zone_record" "a" {
  count = var.ip != null ? 1 : 0

  zone       = var.zone
  domain     = "${var.hostname}.${var.zone}"
  type       = "A"
  ip_address = var.ip
  ttl        = var.ttl

  depends_on = [terraform_data.validate_mode]
}

resource "technitium_dns_zone_record" "cname" {
  count = var.cname != null ? 1 : 0

  zone   = var.zone
  domain = "${var.hostname}.${var.zone}"
  type   = "CNAME"
  cname  = var.cname
  ttl    = var.ttl

  depends_on = [terraform_data.validate_mode]
}
