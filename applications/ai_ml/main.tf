# =============================================================================
# applications/aiml/main.tf
#
# AI/ML Application Landing Zone
# Uses BYO VNet pattern — references hub VNet and DNS zones from platform
# Module: Azure/avm-ptn-aiml-landing-zone/azurerm v0.4.0
# =============================================================================

# -----------------------------------------------------------------------------
# Read platform outputs from remote state
# The platform/single_zone state is the source of truth for:
#   - Hub VNet resource ID
#   - Azure Firewall private IP
#   - Private DNS zone resource IDs
# -----------------------------------------------------------------------------
data "terraform_remote_state" "platform" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.platform_state_resource_group_name
    storage_account_name = var.platform_state_storage_account_name
    container_name       = var.platform_state_container_name
    key                  = var.platform_state_key
  }
}

# -----------------------------------------------------------------------------
# Local values — resolve platform outputs into named references
# -----------------------------------------------------------------------------
locals {
  # Hub networking from platform
  hub_vnet_resource_id    = data.terraform_remote_state.platform.outputs.hub_virtualhub_and_spoke_vnet_virtual_network_resource_ids_network_resource_id
  firewall_private_ip     = data.terraform_remote_state.platform.outputs.hub_and_spoke_vnet_firewall_private_ip_address
  dns_server_ip_address   = data.terraform_remote_state.platform.outputs.dns_server_ip_address
  # Private DNS zone resource IDs from platform (hub-managed zones)
  # These are the zones relevant to AI Foundry + supporting services
  dns_zones = data.terraform_remote_state.platform.outputs.private_dns_zone_resource_ids

  # Convenience map — pull out the specific zones the aiml module needs
  # Keys match the zone map keys from avm-ptn-network-private-link-private-dns-zones
  dns = {
    ai_foundry_api    = local.dns_zones["azure_ml"]
    ai_foundry_nb     = local.dns_zones["azure_ml_notebooks"]
    openai            = local.dns_zones["azure_ai_oai"]
    cognitive_svc     = local.dns_zones["azure_ai_cog_svcs"]
    ai_services       = local.dns_zones["azure_ai_services"]
    acr               = local.dns_zones["azure_acr_registry"]
    blob              = local.dns_zones["azure_storage_blob"]
    file              = local.dns_zones["azure_storage_file"]
    dfs               = local.dns_zones["azure_data_lake_gen2"]
    key_vault         = local.dns_zones["azure_key_vault"]
    monitor           = local.dns_zones["azure_monitor"]
    oms               = local.dns_zones["azure_log_analytics"]
    ods               = local.dns_zones["azure_log_analytics_data"]
    agent_svc         = local.dns_zones["azure_monitor_agent"]
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# Add a vnet in a separate resource group
resource "azurerm_resource_group" "vnet_rg" {
  location = var.location
  name     = coalesce(var.resource_group_name , module.naming.resource_group.name_unique)
}

#create a BYO vnet and peer to the hub
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.16.0"

  location      = azurerm_resource_group.vnet_rg.location
  parent_id     = azurerm_resource_group.vnet_rg.id
  address_space = ["192.168.0.0/20"] # has to be out of 192.168.0.0/16 currently. Other RFC1918 not supported for foundry capabilityHost injection.
  dns_servers = {
    dns_servers = [for key, value in local.dns_server_ip_address : value]
  }
  name = module.naming.virtual_network.name_unique
  peerings = {
    peertovnet1 = {
      name                                 = "${module.naming.virtual_network_peering.name_unique}-vnet2-to-vnet1"
      remote_virtual_network_resource_id   = module.example_hub.virtual_network_resource_id
      allow_forwarded_traffic              = true
      allow_gateway_transit                = true
      allow_virtual_network_access         = true
      create_reverse_peering               = true
      reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-vnet1-to-vnet2"
      reverse_allow_virtual_network_access = true
    }
  }
}

# -----------------------------------------------------------------------------
# AI/ML Landing Zone
# BYO VNet mode — no new VNet created, module adds subnets to spoke VNet
# Peering to hub is assumed to be managed by the platform (ALZ accelerator)
# or handled separately via the platform outputs
# -----------------------------------------------------------------------------
module "aiml_landing_zone" {
  source  = "Azure/avm-ptn-aiml-landing-zone/azurerm"
  version = "0.4.0"

  # ── Required ────────────────────────────────────────────────────────────────
  location            = var.location
  resource_group_name = var.resource_group_name

  # ── Global tags ─────────────────────────────────────────────────────────────
  tags = var.tags

  # ── Telemetry ───────────────────────────────────────────────────────────────
  enable_telemetry = var.enable_telemetry

  # ── Networking — BYO VNet ───────────────────────────────────────────────────
  vnet_definition = {
    existing_byo_vnet = {
      spoke = {
        vnet_resource_id    = var.spoke_vnet_resource_id
        firewall_ip_address = local.firewall_private_ip
      }
    }
  }

  # ── AI Foundry Hub ───────────────────────────────────────────────────────────
  # The module creates the AI Foundry Hub with all necessary configurations
  ai_foundry_definition = {
    name = "aif-${var.workload_name}-${var.environment}-${var.location_short}"
    
    # Private endpoint configuration using hub DNS zones
    private_endpoints = {
      hub_api = {
        subnet_resource_id            = var.spoke_aiml_subnet_resource_id
        private_dns_zone_resource_ids = [local.dns.ai_foundry_api]
        private_endpoints_manage_dns_zone_group = true
      }
    }
    # ── Key Vault ────────────────────────────────────────────────────────────────
    # Using hub-managed DNS zone for Key Vault private endpoint
    key_vault_definition = {
      name = "kv-${var.workload_name}-${var.environment}"
      
      private_endpoints = {
        vault = {
          subnet_resource_id            = var.spoke_aiml_subnet_resource_id
          private_dns_zone_resource_ids = [local.dns.key_vault]
          private_endpoints_manage_dns_zone_group = true
        }
      }
    }

    # ── Storage Account ──────────────────────────────────────────────────────────
    # Using hub-managed DNS zones for blob and file endpoints
    storage_account = {
      name = "st${var.workload_name}${var.environment}${var.location_short}"
      
      private_endpoints = {
        blob = {
          subnet_resource_id            = var.spoke_aiml_subnet_resource_id
          private_dns_zone_resource_ids = [local.dns.blob]
          subresource_names             = ["blob"]
          private_endpoints_manage_dns_zone_group = true
        }
        file = {
          subnet_resource_id            = var.spoke_aiml_subnet_resource_id
          private_dns_zone_resource_ids = [local.dns.file]
          subresource_names             = ["file"]
          private_endpoints_manage_dns_zone_group = true
        }
      }
    }
  }
  
  # ── Azure Container Registry ─────────────────────────────────────────────────
  # Using hub-managed DNS zone for ACR
  genai_container_registry_definition = {
    name = "acr${var.workload_name}${var.environment}${var.location_short}"
    
    private_endpoints = {
      registry = {
        subnet_resource_id            = var.spoke_aiml_subnet_resource_id
        private_dns_zone_resource_ids = [local.dns.acr]
        subresource_names             = ["registry"]
        private_endpoints_manage_dns_zone_group = true
      }
    }
  }

  # ── Log Analytics Workspace ──────────────────────────────────────────────────
  # For centralized monitoring - can be hub-shared or spoke-specific
  
  
#   log_analytics_workspace = {
#     name = "log-${var.workload_name}-${var.environment}-${var.location_short}"
    
#     # If you want to use a hub-shared Log Analytics instead, set:
#     # existing_log_analytics_workspace_resource_id = var.hub_log_analytics_workspace_id
#   }
# }
}
