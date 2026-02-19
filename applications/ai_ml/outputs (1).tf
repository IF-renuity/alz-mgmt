# =============================================================================
# platform/single_zone/outputs.tf
#
# These outputs are consumed by application landing zones via remote state.
# Every application (aiml, data, etc.) reads these values using:
#   data "terraform_remote_state" "platform" { ... }
#
# IMPORTANT: Do not remove or rename these outputs without updating all
# dependent application landing zone configurations.
# =============================================================================

# ── Hub Networking ────────────────────────────────────────────────────────────

output "hub_virtual_network_resource_id" {
  description = "Resource ID of the hub Virtual Network. Used by application landing zones to set up peering and routing references."
  value       = module.hub_and_spoke.hub_virtual_network_resource_ids["primary"]
}

output "hub_virtual_network_name" {
  description = "Name of the hub Virtual Network."
  value       = module.hub_and_spoke.hub_virtual_network_names["primary"]
}

output "hub_resource_group_name" {
  description = "Resource group name where the hub network resources are deployed."
  value       = module.hub_and_spoke.hub_resource_group_names["primary"]
}

# ── Azure Firewall ────────────────────────────────────────────────────────────

output "firewall_private_ip_address" {
  description = <<EOT
Private IP address of the Azure Firewall in the hub.
Application landing zones use this to configure route tables so all
spoke subnet egress traffic is forced through the firewall.
EOT
  value       = module.hub_and_spoke.firewall_private_ip_addresses["primary"]
}

output "firewall_resource_id" {
  description = "Resource ID of the Azure Firewall in the hub."
  value       = module.hub_and_spoke.firewall_resource_ids["primary"]
}

# ── Private DNS Zones ─────────────────────────────────────────────────────────

output "private_dns_zone_resource_ids" {
  description = <<EOT
Map of private DNS zone keys to their resource IDs.
Application landing zones use these IDs to configure private endpoint
DNS zone groups so that A records are written into the centrally
managed hub DNS zones.

Key format matches the avm-ptn-network-private-link-private-dns-zones
module's map keys, e.g.:
  azure_ml                 => privatelink.api.azureml.ms
  azure_storage_blob       => privatelink.blob.core.windows.net
  azure_key_vault          => privatelink.vaultcore.azure.net
  ...etc

Usage in application landing zones:
  local.dns_zones["azure_ml"]  =>  /subscriptions/.../privateDnsZones/privatelink.api.azureml.ms
EOT
  value = module.hub_and_spoke.private_dns_zone_resource_ids
}

output "private_dns_zone_names" {
  description = "Map of private DNS zone keys to their zone names (for reference/debugging)."
  value       = module.hub_and_spoke.private_dns_zone_names
}

# ── Location ──────────────────────────────────────────────────────────────────

output "location" {
  description = "Azure region where the platform hub is deployed. Application landing zones should deploy to the same region unless multi-region."
  value       = var.location
}
