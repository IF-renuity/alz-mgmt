# TFVARS CUSTOMIZATION GUIDE

This guide provides practical examples for customizing `.tfvars` files based on your actual configuration structure.

---

## PLATFORM TFVARS

**File:** `platform/only_connectivity/platform-alz_auto.tfvars`

This file uses ALZ Accelerator's template variable system with `$${variable}` placeholders.

---

### Example 1: Change Azure Region

**Default:**
```hcl
starter_locations = ["eastus"]
```

**Customized:**
```hcl
starter_locations = ["swedencentral"]
```

**Impact:** All resources deploy to Sweden Central instead of East US. The `$${starter_location_01}` placeholder throughout the file automatically resolves to `swedencentral`.

---

### Example 2: Change Hub Network Address Space

**Default:**
```hcl
custom_replacements = {
  names = {
    # IP Ranges Primary
    # Regional Address Space: 10.0.0.0/16
    primary_hub_address_space                          = "10.1.0.0/16"
    primary_hub_virtual_network_address_space          = "10.1.0.0/22"
    primary_firewall_subnet_address_prefix             = "10.1.0.0/26"
    primary_firewall_management_subnet_address_prefix  = "10.1.0.192/26"
    primary_bastion_subnet_address_prefix              = "10.1.0.64/26"
    primary_gateway_subnet_address_prefix              = "10.1.0.128/27"
  }
}
```

**Customized (Avoid conflicts with on-premises 10.0.0.0/8):**
```hcl
custom_replacements = {
  names = {
    # IP Ranges Primary
    # Regional Address Space: 172.16.0.0/16
    primary_hub_address_space                          = "172.16.0.0/16"
    primary_hub_virtual_network_address_space          = "172.16.0.0/22"
    primary_firewall_subnet_address_prefix             = "172.16.0.0/26"
    primary_firewall_management_subnet_address_prefix  = "172.16.0.192/26"
    primary_bastion_subnet_address_prefix              = "172.16.0.64/26"
    primary_gateway_subnet_address_prefix              = "172.16.0.128/27"
  }
}
```

**Why:** Using 172.16.0.0/16 range avoids overlap with on-premises networks that commonly use 10.0.0.0/8.

---

### Example 3: Enable/Disable Optional Resources

**Current Configuration:**
```hcl
custom_replacements = {
  names = {
    # Resource provisioning primary connectivity
    primary_firewall_enabled                          = false
    primary_virtual_network_gateway_vpn_enabled       = false
    primary_private_dns_resolver_enabled              = false
    primary_bastion_enabled                           = true
  }
}
```

**Scenario A: Enable Firewall for Production**
```hcl
primary_firewall_enabled                          = true
primary_firewall_management_ip_enabled            = true
```
**Cost Impact:** ~$1,200/month
**Use When:** Production environment requiring traffic inspection

---

**Scenario B: Enable VPN Gateway for On-Premises**
```hcl
primary_virtual_network_gateway_vpn_enabled       = true
```
Uncomment the entire `virtual_network_gateways` block (lines 289-319) in the file.

**Cost Impact:** ~$100-300/month depending on SKU
**Use When:** Connecting to on-premises datacenter

---

**Scenario C: Disable Bastion (Cost Savings for Dev)**
```hcl
primary_bastion_enabled                           = false
```
**Savings:** ~$130/month
**Use When:** Development environment without VM access needs

---

### Example 4: Customize DNS Zones (Cost Optimization)

**Current Configuration (Custom Zones Only):**
```hcl
private_dns_zones = {
  private_link_private_dns_zones = {
    # ── AI Foundry ──────────────────────────────────────
    azure_ml                    = { zone_name = "privatelink.api.azureml.ms" }
    azure_ml_notebooks          = { zone_name = "privatelink.notebooks.azure.net" }
    azure_ai_oai                = { zone_name = "privatelink.openai.azure.com" }
    azure_ai_cog_svcs           = { zone_name = "privatelink.cognitiveservices.azure.com" }
    azure_ai_services           = { zone_name = "privatelink.services.ai.azure.com" }
    azure_acr_registry          = { zone_name = "privatelink.azurecr.io" }
    azure_cosmos_db             = { zone_name = "privatelink.documents.azure.com" }
    azure_ai_search             = { zone_name = "privatelink.search.windows.net" }

    # ── Storage ─────────────────────────────────────────
    azure_storage_blob          = { zone_name = "privatelink.blob.core.windows.net" }
    azure_storage_file          = { zone_name = "privatelink.file.core.windows.net" }
    # ... more zones
  }
}
```

**Why This Approach:** You've already selected only the zones needed for AI/ML and Fabric workloads (~26 zones).

**Cost:** ~$13/month (26 zones × $0.50)

**To Add More Zones:** Simply add to the list:
```hcl
# Add Databricks support
azure_databricks        = { zone_name = "privatelink.azuredatabricks.net" }
```

**To Remove Zones:** Comment out or delete lines:
```hcl
# Don't need Fabric? Remove these:
# azure_fabric          = { zone_name = "privatelink.fabric.microsoft.com" }
# azure_synapse         = { zone_name = "privatelink.azuresynapse.net" }
# azure_power_bi        = { zone_name = "privatelink.analysis.windows.net" }
```

**Savings:** $1.50/month (3 zones removed)

---

### Example 5: Update Tags

**Default:**
```hcl
tags = {
  deployed_by = "terraform"
  source      = "Azure Landing Zones Accelerator"
}
```

**Enhanced:**
```hcl
tags = {
  deployed_by = "terraform"
  source      = "Azure Landing Zones Accelerator"
  Environment = "production"
  CostCenter  = "platform-ops"
  Owner       = "platform-team@company.com"
  Criticality = "tier1"
}
```

**Result:** Better cost allocation and governance tracking.

---

## APPLICATION TFVARS

**File:** `applications/ai-ml/terraform.tfvars`

Straightforward variable definitions (no template placeholders).

---

### Example 1: Environment-Specific Configuration

**Development:**
```hcl
location       = "eastus"
location_short = "eus"
environment    = "dev"
workload_name  = "aiml"

resource_group_name = "rg-aiml-dev-001"
vnet_address_space  = "192.168.0.0/20"  # 4096 IPs

ai_model_deployments = {
  "gpt-4o" = {
    name = "gpt-4o-deployment"
    model = {
      format  = "OpenAI"
      name    = "gpt-4o"
      version = "2024-05-13"
    }
    scale = {
      type     = "Standard"
      capacity = 10  # Small for dev
    }
  }
}

enable_app_gateway = false
enable_bastion     = true
```

---

**Production:**
```hcl
location       = "eastus"
location_short = "eus"
environment    = "prd"
workload_name  = "aiml"

resource_group_name = "rg-aiml-prd-001"
vnet_address_space  = "192.168.16.0/20"  # Different CIDR, no overlap

ai_model_deployments = {
  "gpt-4o-chat" = {
    name = "gpt-4o-chat"
    model = {
      format  = "OpenAI"
      name    = "gpt-4o"
      version = "2024-05-13"
    }
    scale = {
      type     = "Standard"
      capacity = 100  # High capacity for production
    }
  }
  "gpt-4o-analysis" = {
    name = "gpt-4o-analysis"
    model = {
      format  = "OpenAI"
      name    = "gpt-4o"
      version = "2024-05-13"
    }
    scale = {
      type     = "Standard"
      capacity = 50
    }
  }
  "text-embedding-ada-002" = {
    name = "embeddings"
    model = {
      format  = "OpenAI"
      name    = "text-embedding-ada-002"
      version = "2"
    }
    scale = {
      type     = "Standard"
      capacity = 50
    }
  }
}

enable_app_gateway = true   # Enable for production
enable_bastion     = true
```

**Key Differences:**
- Environment name: `dev` vs `prd`
- VNet CIDR: Different ranges (no overlap)
- AI model capacity: 10 vs 100+
- Multiple models: 1 vs 3 deployments
- App Gateway: Disabled vs enabled

---

### Example 2: Platform State Location

**Current:**
```hcl
platform_state_resource_group_name  = "rg-alz-mgmt-state-eastus-001"
platform_state_storage_account_name = "stoalzmgmeas001aqqd"
platform_state_container_name       = "mgmt-tfstate"
platform_state_key                  = "terraform.tfstate"
```

**Important:** These values come from your ALZ bootstrap deployment. 

**If Platform is in Different Folder:**
```hcl
platform_state_key = "platform/only_connectivity/terraform.tfstate"
```

**Multi-Environment Setup:**
```hcl
# Dev environment points to dev platform
platform_state_key = "platform/dev/terraform.tfstate"

# Prod environment points to prod platform
platform_state_key = "platform/prd/terraform.tfstate"
```

---

### Example 3: Firewall IP Address

**What it is:**
```hcl
firewall_ip_address = "10.1.0.4"  # IP from platform firewall
```

**How to get it:**
1. From platform deployment output:
   ```bash
   terraform output firewall_private_ip_address
   ```
2. Or query Azure:
   ```bash
   az network firewall show \
     --name fw-hub-eastus \
     --resource-group rg-hub-eastus \
     --query "ipConfigurations[0].privateIPAddress" -o tsv
   ```

**When to update:** If you change firewall configuration or platform deployment.

---

### Example 4: Add DNS Servers (Hub DNS Resolver)

**Default (Use Azure DNS):**
```hcl
hub_dns_server_ips = []
```

**With Hub DNS Resolver Enabled:**
```hcl
hub_dns_server_ips = ["10.1.0.164", "10.1.0.165"]
```

**How to get IPs:**
```bash
az dns-resolver inbound-endpoint show \
  --name pdr-hub-dns-eastus \
  --dns-resolver-name pdr-hub-dns-eastus \
  --resource-group rg-hub-dns-eastus \
  --query "ipConfigurations[].privateIpAddress" -o tsv
```

**When to use:** If platform has Private DNS Resolver enabled for on-premises integration.

---

### Example 5: Comprehensive Tagging

**Basic:**
```hcl
tags = {
  Environment = "dev"
  Workload    = "aiml"
  ManagedBy   = "terraform"
}
```

**Enhanced (Production):**
```hcl
tags = {
  Environment      = "prd"
  Workload         = "aiml"
  CostCenter       = "CC-8472"
  Owner            = "data-science@company.com"
  BusinessUnit     = "AI Research"
  Project          = "customer-insights-ai"
  Criticality      = "tier1"
  DataClass        = "confidential"
  Compliance       = "gdpr,sox"
  BackupPolicy     = "daily"
  DisasterRecovery = "enabled"
  MaintenanceWindow = "sunday-02:00-06:00"
  SupportContact    = "platform-team@company.com"
  ManagedBy         = "terraform"
  Repository        = "github.com/company/azure-ai-platform"
  DeployedBy        = "github-actions"
  LastUpdated       = "2026-02-25"
}
```

**Result:** 
- Detailed cost allocation per project
- Compliance tracking
- Operational contact information
- Change management tracking

---

## QUICK REFERENCE

### When to Update Platform Tfvars

| Change | Section | Impact |
|---|---|---|
| Azure region | `starter_locations` | All resources move to new region |
| Hub VNet CIDR | `custom_replacements.names.primary_hub_address_space` | Network addressing changes |
| Enable firewall | `primary_firewall_enabled = true` | +$1,200/month |
| Disable bastion | `primary_bastion_enabled = false` | -$130/month |
| Add DNS zone | `private_link_private_dns_zones` | +$0.50/zone/month |

### When to Update Application Tfvars

| Change | Variable | Example |
|---|---|---|
| Deploy to new region | `location`, `location_short` | `"swedencentral"`, `"sec"` |
| Change environment | `environment` | `"dev"` → `"prd"` |
| Add AI model | `ai_model_deployments` | Add new map entry |
| Scale model capacity | `ai_model_deployments.*.scale.capacity` | `10` → `100` |
| Point to different platform | `platform_state_key` | Update state path |

---

## VALIDATION CHECKLIST

Before applying changes:

### Platform
- [ ] VNet address space doesn't overlap with existing networks
- [ ] Region supports all required services
- [ ] DNS zones match your workload requirements
- [ ] Optional resources (firewall, bastion) match budget

### Application
- [ ] VNet address space in `192.168.0.0/16` range (AI Foundry requirement)
- [ ] VNet address space doesn't overlap with hub or other spokes
- [ ] Platform state location is correct and accessible
- [ ] Firewall IP address is correct
- [ ] AI model versions available in your region
- [ ] Model capacity within subscription quota

---

## TROUBLESHOOTING

### Issue: Platform state not found

**Symptom:**
```
Error: Invalid backend configuration: state blob not found
```

**Solution:** Verify `platform_state_key` matches your platform deployment:
```bash
# List state files
az storage blob list \
  --account-name stoalzmgmeas001aqqd \
  --container-name mgmt-tfstate \
  --query "[].name" -o table
```

---

### Issue: VNet address overlap

**Symptom:**
```
Error: Address space overlaps with existing peered network
```

**Solution:** Change `vnet_address_space` to non-overlapping CIDR:
```hcl
# Instead of: "192.168.0.0/20" (overlaps with another spoke)
vnet_address_space = "192.168.16.0/20"  # Different range
```

---

### Issue: AI model version not available

**Symptom:**
```
Error: Model version not found in region
```

**Solution:** Check available versions:
```bash
az cognitiveservices account list-models \
  --location eastus \
  --query "[?name=='gpt-4o'].version" -o table
```

Update tfvars with available version:
```hcl
version = "2024-08-06"  # Use currently available version
```

---

**💡 Tip:** Always run `terraform plan` before `terraform apply` to preview changes.
