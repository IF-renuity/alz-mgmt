# =============================================================================
# applications/aiml/terraform.tfvars
#
# Example values — update to match your environment before running.
# DO NOT commit real subscription IDs or secrets to source control.
# =============================================================================

# ── Identity ──────────────────────────────────────────────────────────────────
location       = "eastus"
location_short = "eus"
environment    = "dev"
workload_name  = "aiml"

# ── Resource Group ────────────────────────────────────────────────────────────
resource_group_name = "rg-aiml-dev-eus-001"

# ── Spoke VNet ────────────────────────────────────────────────────────────────
# This VNet must already be peered to the platform hub.
# Obtain this from the platform team or from the spoke VNet deployment.
spoke_vnet_resource_id = "/subscriptions/<spoke-sub-id>/resourceGroups/rg-spoke-aiml-dev-eus/providers/Microsoft.Network/virtualNetworks/vnet-spoke-aiml-dev-eus-001"

# Subnet within the spoke VNet where private endpoints will be deployed.
spoke_aiml_subnet_resource_id = "/subscriptions/<spoke-sub-id>/resourceGroups/rg-spoke-aiml-dev-eus/providers/Microsoft.Network/virtualNetworks/vnet-spoke-aiml-dev-eus-001/subnets/snet-privateendpoints"

# ── Platform Remote State ─────────────────────────────────────────────────────
platform_state_resource_group_name  = "rg-alz-mgmt-state-eastus-001"
platform_state_storage_account_name = "stoalzmgmeas001aqqd"
platform_state_container_name       = "mgmt-tfstate"
platform_state_key                  = "terraform.tfstate"

# ── Tags ──────────────────────────────────────────────────────────────────────
tags = {
  Environment  = "dev"
  Workload     = "aiml"
  CostCenter   = "ai-platform"
  ManagedBy    = "terraform"
  Owner        = "platform-team"
}
