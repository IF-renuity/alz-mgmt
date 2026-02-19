# =============================================================================
# applications/aiml/outputs.tf
# =============================================================================

output "aiml_resource_group_name" {
  description = "Name of the AI/ML landing zone resource group."
  value       = var.resource_group_name
}

output "ai_foundry_hub_resource_id" {
  description = "Resource ID of the deployed AI Foundry Hub."
  value       = module.aiml_landing_zone.ai_foundry_hub_resource_id
}

output "ai_foundry_hub_name" {
  description = "Name of the deployed AI Foundry Hub."
  value       = module.aiml_landing_zone.ai_foundry_hub_name
}

output "key_vault_resource_id" {
  description = "Resource ID of the Key Vault deployed for the AI/ML landing zone."
  value       = module.aiml_landing_zone.key_vault_resource_id
}

output "storage_account_resource_id" {
  description = "Resource ID of the Storage Account deployed for the AI/ML landing zone."
  value       = module.aiml_landing_zone.storage_account_resource_id
}

output "container_registry_resource_id" {
  description = "Resource ID of the Container Registry deployed for the AI/ML landing zone."
  value       = module.aiml_landing_zone.container_registry_resource_id
}

output "log_analytics_workspace_resource_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = module.aiml_landing_zone.log_analytics_workspace_resource_id
}

output "hub_vnet_resource_id_used" {
  description = "Hub VNet resource ID consumed from platform remote state (for reference)."
  value       = local.hub_vnet_resource_id
}

output "spoke_vnet_resource_id" {
  description = "Spoke VNet resource ID used for BYO VNet deployment."
  value       = var.spoke_vnet_resource_id
}
