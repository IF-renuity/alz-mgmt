# =============================================================================
# applications/aiml/variables.tf
# =============================================================================

# ── Required ──────────────────────────────────────────────────────────────────

variable "aiml_subscription_id" {
  description = "The identifier of the Ai-Ml Subscription"
  type        = string
  default     = null
  validation {
    condition     = var.aiml_subscription_id == null || can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", var.subscription_id_connectivity))
    error_message = "The subscription ID must be a valid GUID"
  }
}

variable "location" {
  type        = string
  description = "Azure region where all AI/ML resources will be deployed. Must match the hub region."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the AI/ML landing zone resources."
}

variable "workload_name" {
  type        = string
  description = "Short name identifying this workload. Used in resource naming. e.g. 'aiml', 'genai'."
  default = "aiml"
}

variable "environment" {
  type        = string
  description = "Environment shortname. e.g. 'dev', 'tst', 'prd'."
  validation {
    condition     = contains(["dev", "tst", "stg", "prd"], var.environment)
    error_message = "environment must be one of: dev, tst, stg, prd."
  }
}

variable "location_short" {
  type        = string
  description = "Short location code used in resource names. e.g. 'eus' for East US, 'weu' for West Europe."
}

# ── Spoke VNet (pre-provisioned and peered to hub by platform) ────────────────

variable "spoke_vnet_resource_id" {
  type        = string
  description = <<EOT
Resource ID of the spoke Virtual Network already peered to the hub.
This VNet must already exist and be peered to the platform hub.
The aiml module will create its subnets inside this VNet.
Example: /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet-name>
EOT
}

variable "spoke_aiml_subnet_resource_id" {
  type        = string
  description = <<EOT
Resource ID of the subnet within the spoke VNet to use for AI/ML private endpoints.
This subnet must already exist within the spoke VNet.
Example: /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet-name>
EOT
}

# ── Platform Remote State ─────────────────────────────────────────────────────

variable "platform_state_resource_group_name" {
  type        = string
  description = "Resource group name of the Azure Storage Account holding the platform Terraform state."
}

variable "platform_state_storage_account_name" {
  type        = string
  description = "Storage account name holding the platform Terraform remote state."
}

variable "platform_state_container_name" {
  type        = string
  default     = "tfstate"
  description = "Blob container name for the platform Terraform state file."
}

variable "platform_state_key" {
  type        = string
  default     = "platform/single_zone/terraform.tfstate"
  description = "State file key (blob name) for the platform single_zone deployment."
}

# ── Optional / Defaults ───────────────────────────────────────────────────────

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable telemetry for AVM modules."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to apply to all resources in this landing zone."
}
