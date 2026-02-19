starter_locations = ["eastus"]

/*
--- Custom Replacements ---
You can define custom replacements to use throughout the configuration.
*/
custom_replacements = {
  /*
  --- Custom Name Replacements ---
  You can define custom names and other strings to use throughout the configuration.
  You can only use the built in replacements in this section.
  NOTE: You cannot refer to another custom name in this variable.
  */
  names = {
    # Defender email security contact
    defender_email_security_contact = "replace_me@replace_me.com"

    # Resource group names
    management_resource_group_name               = "rg-management-$${starter_location_01}"
    connectivity_hub_primary_resource_group_name = "rg-hub-$${starter_location_01}"
    dns_resource_group_name                      = "rg-hub-dns-$${starter_location_01}"
    # ddos_resource_group_name                     = "rg-hub-ddos-$${starter_location_01}"
    asc_export_resource_group_name               = "rg-asc-export-$${starter_location_01}"

    # Resource names management
    log_analytics_workspace_name            = "law-management-$${starter_location_01}"
    # ddos_protection_plan_name               = "ddos-$${starter_location_01}"
    ama_user_assigned_managed_identity_name = "uami-management-ama-$${starter_location_01}"
    dcr_change_tracking_name                = "dcr-change-tracking"
    dcr_defender_sql_name                   = "dcr-defender-sql"
    dcr_vm_insights_name                    = "dcr-vm-insights"

    # Resource provisioning global connectivity
    ddos_protection_plan_enabled = false

    # Resource provisioning primary connectivity
    primary_firewall_enabled                                             = false
    primary_firewall_management_ip_enabled                               = true
    primary_virtual_network_gateway_express_route_enabled                = false
    primary_virtual_network_gateway_express_route_hobo_public_ip_enabled = false
    primary_virtual_network_gateway_vpn_enabled                          = false
    primary_private_dns_zones_enabled                                    = true
    primary_private_dns_auto_registration_zone_enabled                   = true
    primary_private_dns_resolver_enabled                                 = false
    primary_bastion_enabled                                              = true

    # Resource names primary connectivity
    primary_virtual_network_name                                 = "vnet-hub-$${starter_location_01}"
    primary_firewall_name                                        = "fw-hub-$${starter_location_01}"
    primary_firewall_policy_name                                 = "fwp-hub-$${starter_location_01}"
    primary_firewall_public_ip_name                              = "pip-fw-hub-$${starter_location_01}"
    primary_firewall_management_public_ip_name                   = "pip-fw-hub-mgmt-$${starter_location_01}"
    primary_route_table_firewall_name                            = "rt-hub-fw-$${starter_location_01}"
    primary_route_table_user_subnets_name                        = "rt-hub-std-$${starter_location_01}"
    primary_virtual_network_gateway_express_route_name           = "vgw-hub-er-$${starter_location_01}"
    primary_virtual_network_gateway_express_route_public_ip_name = "pip-vgw-hub-er-$${starter_location_01}"
    primary_virtual_network_gateway_vpn_name                     = "vgw-hub-vpn-$${starter_location_01}"
    primary_virtual_network_gateway_vpn_public_ip_name_1         = "pip-vgw-hub-vpn-$${starter_location_01}-001"
    primary_virtual_network_gateway_vpn_public_ip_name_2         = "pip-vgw-hub-vpn-$${starter_location_01}-002"
    primary_private_dns_resolver_name                            = "pdr-hub-dns-$${starter_location_01}"
    primary_bastion_host_name                                    = "bas-hub-$${starter_location_01}"
    primary_bastion_host_public_ip_name                          = "pip-bastion-hub-$${starter_location_01}"

    # Private DNS Zones primary
    primary_auto_registration_zone_name = "$${starter_location_01}.azure.local"

    # IP Ranges Primary
    # Regional Address Space: 10.0.0.0/16
    primary_hub_address_space                          = "10.1.0.0/16"
    primary_hub_virtual_network_address_space          = "10.1.0.0/22"
    primary_firewall_subnet_address_prefix             = "10.1.0.0/26"
    primary_firewall_management_subnet_address_prefix  = "10.1.0.192/26"
    primary_bastion_subnet_address_prefix              = "10.1.0.64/26"
    primary_gateway_subnet_address_prefix              = "10.1.0.128/27"
    primary_private_dns_resolver_subnet_address_prefix = "10.1.0.160/28"
  }

  /*
  --- Custom Resource Group Identifier Replacements ---
  You can define custom resource group identifiers to use throughout the configuration.
  You can only use the templated variables and custom names in this section.
  NOTE: You cannot refer to another custom resource group identifier in this variable.
  */
  resource_group_identifiers = {
    # management_resource_group_id           = "/subscriptions/$${subscription_id_management}/resourcegroups/$${management_resource_group_name}"
    # ddos_protection_plan_resource_group_id = "/subscriptions/$${subscription_id_connectivity}/resourcegroups/$${ddos_resource_group_name}"
    primary_connectivity_resource_group_id = "/subscriptions/$${subscription_id_connectivity}/resourceGroups/$${connectivity_hub_primary_resource_group_name}"
    dns_resource_group_id                  = "/subscriptions/$${subscription_id_connectivity}/resourceGroups/$${dns_resource_group_name}"
  }

  /*
  --- Custom Resource Identifier Replacements ---
  You can define custom resource identifiers to use throughout the configuration.
  You can only use the templated variables, custom names and customer resource group identifiers in this variable.
  NOTE: You cannot refer to another custom resource identifier in this variable.
  */
  resource_identifiers = {
    # ama_change_tracking_data_collection_rule_id = "$${management_resource_group_id}/providers/Microsoft.Insights/dataCollectionRules/$${dcr_change_tracking_name}"
    # #ama_mdfc_sql_data_collection_rule_id        = "$${management_resource_group_id}/providers/Microsoft.Insights/dataCollectionRules/$${dcr_defender_sql_name}"
    # ama_vm_insights_data_collection_rule_id     = "$${management_resource_group_id}/providers/Microsoft.Insights/dataCollectionRules/$${dcr_vm_insights_name}"
    # ama_user_assigned_managed_identity_id       = "$${management_resource_group_id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$${ama_user_assigned_managed_identity_name}"
    # log_analytics_workspace_id                  = "$${management_resource_group_id}/providers/Microsoft.OperationalInsights/workspaces/$${log_analytics_workspace_name}"
    # ddos_protection_plan_id                     = "$${ddos_protection_plan_resource_group_id}/providers/Microsoft.Network/ddosProtectionPlans/$${ddos_protection_plan_name}"
  }
}

/*
--- Tags ---
This variable can be used to apply tags to all resources that support it. Some resources allow overriding these tags.
*/
tags = {
  deployed_by = "terraform"
  source      = "Azure Landing Zones Accelerator"
}


management_group_settings = {
  enable_telemetry = true
  # This is the name of the architecture that will be used to deploy the management resources.
  # It refers to the alz_custom.alz_architecture_definition.yaml file in the lib folder.
  # Do not change this value unless you have created another architecture definition
  # with the name value specified below.
  architecture_name  = "alz_custom"
  location           = "$${starter_location_01}"
  parent_resource_id = "$${root_parent_management_group_id}"
  policy_default_values = {
    # ama_change_tracking_data_collection_rule_id = "$${ama_change_tracking_data_collection_rule_id}"
    #ama_mdfc_sql_data_collection_rule_id        = "$${#ama_mdfc_sql_data_collection_rule_id}"
    # ama_vm_insights_data_collection_rule_id     = "$${# ama_vm_insights_data_collection_rule_id}"
    # ama_user_assigned_managed_identity_id       = "$${# ama_user_assigned_managed_identity_id}"
    ama_user_assigned_managed_identity_name     = "$${ama_user_assigned_managed_identity_name}"
    # log_analytics_workspace_id                  = "$${# log_analytics_workspace_id}"
    # ddos_protection_plan_id                     = "$${ddos_protection_plan_id}"
    private_dns_zone_subscription_id            = "$${subscription_id_connectivity}"
    private_dns_zone_region                     = "$${starter_location_01}"
    private_dns_zone_resource_group_name        = "$${dns_resource_group_name}"
    /*
    # Example of allowed locations for Sovereign Landing Zones policies
    allowed_locations = [
      "$${starter_location_01}"
    ]
    */
  }
  subscription_placement = {
    # identity = {
    #   subscription_id       = "$${subscription_id_identity}"
    #   management_group_name = "identity"
    # }
    connectivity = {
      subscription_id       = "$${subscription_id_connectivity}"
      management_group_name = "connectivity"
    }
    # management = {
    #   subscription_id       = "$${subscription_id_management}"
    #   management_group_name = "connectivity"
    # }
    # security = {
    #   subscription_id       = "$${subscription_id_security}"
    #   management_group_name = "security"
    # }
  }
  policy_assignments_to_modify = {
    alz = {
      policy_assignments = {
        Deploy-MDFC-Config-H224 = {
          parameters = {
            ascExportResourceGroupName                  = "$${asc_export_resource_group_name}"
            ascExportResourceGroupLocation              = "$${starter_location_01}"
            emailSecurityContact                        = "$${defender_email_security_contact}"
            enableAscForServers                         = "DeployIfNotExists"
            enableAscForServersVulnerabilityAssessments = "DeployIfNotExists"
            enableAscForSql                             = "DeployIfNotExists"
            enableAscForAppServices                     = "DeployIfNotExists"
            enableAscForStorage                         = "DeployIfNotExists"
            enableAscForContainers                      = "DeployIfNotExists"
            enableAscForKeyVault                        = "DeployIfNotExists"
            enableAscForSqlOnVm                         = "DeployIfNotExists"
            enableAscForArm                             = "DeployIfNotExists"
            enableAscForOssDb                           = "DeployIfNotExists"
            enableAscForCosmosDbs                       = "DeployIfNotExists"
            enableAscForCspm                            = "DeployIfNotExists"
          }
        }
      }
    }
  }
}

management_resource_settings = {
  enabled                      = false
  location                     = "$${starter_location_01}"
  log_analytics_workspace_name = "$${log_analytics_workspace_name}"
  resource_group_name          = "$${management_resource_group_name}"
  user_assigned_managed_identities = {
    ama = {
      name = "$${ama_user_assigned_managed_identity_name}"
    }
  }
  data_collection_rules = {
    change_tracking = {
      name = "$${dcr_change_tracking_name}"
    }
    defender_sql = {
      name = "$${dcr_defender_sql_name}"
    }
    vm_insights = {
      name = "$${dcr_vm_insights_name}"
    }
  }
  log_analytics_workspace_retention_in_days=90
}

connectivity_type = "hub_and_spoke_vnet"

connectivity_resource_groups = {
  # ddos = {
  #   name     = "$${ddos_resource_group_name}"
  #   location = "$${starter_location_01}"
  #   settings = {
  #     enabled = "$${ddos_protection_plan_enabled}"
  #   }
  # }
  vnet_primary = {
    name     = "$${connectivity_hub_primary_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = true
    }
  }
  dns = {
    name     = "$${dns_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = "$${primary_private_dns_zones_enabled}"
    }
  }
}

hub_and_spoke_networks_settings = {
  enabled_resources = {
    ddos_protection_plan = "$${ddos_protection_plan_enabled}"
  }
#   ddos_protection_plan = {
#     name                = "$${ddos_protection_plan_name}"
#     resource_group_name = "$${ddos_resource_group_name}"
#     location            = "$${starter_location_01}"
#   }
}

hub_virtual_networks = {
  primary = {
    location          = "$${starter_location_01}"
    default_parent_id = "$${primary_connectivity_resource_group_id}"
    enabled_resources = {
      firewall                              = "$${primary_firewall_enabled}"
      bastion                               = "$${primary_bastion_enabled}"
      virtual_network_gateway_express_route = "$${primary_virtual_network_gateway_express_route_enabled}"
      virtual_network_gateway_vpn           = "$${primary_virtual_network_gateway_vpn_enabled}"
      private_dns_zones                     = "$${primary_private_dns_zones_enabled}"
      private_dns_resolver                  = "$${primary_private_dns_resolver_enabled}"
    }
    hub_virtual_network = {
      name                          = "$${primary_virtual_network_name}"
      address_space                 = ["$${primary_hub_virtual_network_address_space}"]
      routing_address_space         = ["$${primary_hub_address_space}"]
      route_table_name_firewall     = "$${primary_route_table_firewall_name}"
      route_table_name_user_subnets = "$${primary_route_table_user_subnets_name}"
      subnets                       = {}
    }
    firewall = {
      subnet_address_prefix            = "$${primary_firewall_subnet_address_prefix}"
      management_subnet_address_prefix = "$${primary_firewall_management_subnet_address_prefix}"
      name                             = "$${primary_firewall_name}"
      default_ip_configuration = {
        public_ip_config = {
          name = "$${primary_firewall_public_ip_name}"
        }
      }
      management_ip_enabled = "$${primary_firewall_management_ip_enabled}"
      management_ip_configuration = {
        public_ip_config = {
          name = "$${primary_firewall_management_public_ip_name}"
        }
      }
    }
    firewall_policy = {
      name = "$${primary_firewall_policy_name}"
    }
    # virtual_network_gateways = {
    #   subnet_address_prefix = "$${primary_gateway_subnet_address_prefix}"
    #   express_route = {
    #     name                                  = "$${primary_virtual_network_gateway_express_route_name}"
    #     hosted_on_behalf_of_public_ip_enabled = "$${primary_virtual_network_gateway_express_route_hobo_public_ip_enabled}"
    #     ip_configurations = {
    #       default = {
    #         # name = "vnetGatewayConfigdefault"  # For backwards compatibility with previous naming, uncomment this line
    #         public_ip = {
    #           name = "$${primary_virtual_network_gateway_express_route_public_ip_name}"
    #         }
    #       }
    #     }
    #   }
    #   vpn = {
    #     name = "$${primary_virtual_network_gateway_vpn_name}"
    #     ip_configurations = {
    #       active_active_1 = {
    #         # name = "vnetGatewayConfigactive_active_1"  # For backwards compatibility with previous naming, uncomment this line
    #         public_ip = {
    #           name = "$${primary_virtual_network_gateway_vpn_public_ip_name_1}"
    #         }
    #       }
    #       active_active_2 = {
    #         # name = "vnetGatewayConfigactive_active_2"  # For backwards compatibility with previous naming, uncomment this line
    #         public_ip = {
    #           name = "$${primary_virtual_network_gateway_vpn_public_ip_name_2}"
    #         }
    #       }
    #     }
    #   }
    # }
    private_dns_zones = {
      parent_id = "$${dns_resource_group_id}"
      
      private_link_private_dns_zones = {

        # ── AI Foundry ──────────────────────────────────────
        azure_ml                    = { zone_name = "privatelink.api.azureml.ms" }
        azure_ml_notebooks          = { zone_name = "privatelink.notebooks.azure.net" }
        azure_ai_oai                = { zone_name = "privatelink.openai.azure.com" }
        azure_ai_cog_svcs           = { zone_name = "privatelink.cognitiveservices.azure.com" }
        azure_ai_services           = { zone_name = "privatelink.services.ai.azure.com" }
        azure_acr_registry          = { zone_name = "privatelink.azurecr.io" }

        # ── Storage (shared by both) ─────────────────────────
        azure_storage_blob          = { zone_name = "privatelink.blob.core.windows.net" }
        azure_storage_file          = { zone_name = "privatelink.file.core.windows.net" }
        azure_storage_queue         = { zone_name = "privatelink.queue.core.windows.net" }
        azure_storage_table         = { zone_name = "privatelink.table.core.windows.net" }
        azure_data_lake_gen2        = { zone_name = "privatelink.dfs.core.windows.net" }

        # ── Security (shared by both) ────────────────────────
        azure_key_vault             = { zone_name = "privatelink.vaultcore.azure.net" }

        # ── Monitoring (shared by both) ──────────────────────
        azure_monitor               = { zone_name = "privatelink.monitor.azure.com" }
        azure_log_analytics         = { zone_name = "privatelink.oms.opinsights.azure.com" }
        azure_log_analytics_data    = { zone_name = "privatelink.ods.opinsights.azure.com" }
        azure_monitor_agent         = { zone_name = "privatelink.agentsvc.azure-automation.net" }

        # ── Microsoft Fabric ─────────────────────────────────
        azure_fabric                = { zone_name = "privatelink.fabric.microsoft.com" }
        azure_synapse               = { zone_name = "privatelink.azuresynapse.net" }
        azure_synapse_dev           = { zone_name = "privatelink.dev.azuresynapse.net" }
        azure_synapse_sql           = { zone_name = "privatelink.sql.azuresynapse.net" }
        azure_service_hub           = { zone_name = "privatelink.servicebus.windows.net" }
        azure_power_bi              = { zone_name = "privatelink.analysis.windows.net" }

        # ── SQL (if using as data source) ────────────────────
        azure_sql_server            = { zone_name = "privatelink.database.windows.net" }
      }

      private_link_private_dns_zones_regex_filter = {
        enabled = false
      }

      auto_registration_zone_enabled = "$${primary_private_dns_auto_registration_zone_enabled}"
      auto_registration_zone_name    = "$${primary_auto_registration_zone_name}"
    }

    # private_dns_resolver = {
    #   subnet_address_prefix = "$${primary_private_dns_resolver_subnet_address_prefix}"
    #   name                  = "$${primary_private_dns_resolver_name}"
    # }
    bastion = {
      subnet_address_prefix = "$${primary_bastion_subnet_address_prefix}"
      name                  = "$${primary_bastion_host_name}"
      bastion_public_ip = {
        name = "$${primary_bastion_host_public_ip_name}"
      }
    }
  }
}

private_link_private_dns_zone_virtual_network_link_moved_blocks_enabled = true

enable_telemetry = true
telemetry_additional_content = {
  deployed_by    = "alz-terraform-accelerator"
  correlation_id = "00000000-0000-0000-0000-000000000000"
}
