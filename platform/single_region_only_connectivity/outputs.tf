output "dns_server_ip_address" {
  value = local.connectivity_enabled && local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].dns_server_ip_addresses: null
}

output "hub_and_spoke_vnet_virtual_network_resource_ids" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].virtual_network_resource_ids : null
}

output "hub_and_spoke_vnet_virtual_network_resource_names" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].virtual_network_resource_names : null
}

output "hub_and_spoke_vnet_bastion_host_public_ip_address" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].bastion_host_public_ip_address : null
}

output "hub_and_spoke_vnet_bastion_host_resource_ids" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].bastion_host_resource_ids : null
}

output "hub_and_spoke_vnet_bastion_host_dns_names" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].bastion_host_dns_names : null
}

output "hub_and_spoke_vnet_firewall_resource_ids" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].firewall_resource_ids : null
}

output "hub_and_spoke_vnet_firewall_resource_names" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].firewall_resource_names : null
}

output "hub_and_spoke_vnet_firewall_private_ip_address" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].firewall_private_ip_addresses : null
}

output "hub_and_spoke_vnet_firewall_public_ip_addresses" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].firewall_public_ip_addresses : null
}

output "hub_and_spoke_vnet_firewall_policies" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].firewall_policies : null
}

output "hub_and_spoke_vnet_route_tables_firewall" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].route_tables_firewall : null
}

output "hub_and_spoke_vnet_route_tables_user_subnets" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0].route_tables_user_subnets : null
}

output "hub_and_spoke_vnet_full_output" {
  value = local.connectivity_hub_and_spoke_vnet_enabled ? module.hub_and_spoke_vnet[0] : null
}

output "templated_inputs" {
  value = module.config.outputs
}
