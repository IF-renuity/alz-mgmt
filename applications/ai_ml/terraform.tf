# =============================================================================
# applications/aiml/terraform.tf
# =============================================================================

terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  # ── Remote state backend ───────────────────────────────────────────────────
  # Store aiml state separately from the platform state.
  # bootstrap storage account.
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azapi" {
  # alias                      = "aiml"
  skip_provider_registration = true
  subscription_id            = var.aiml_subscription_id
}
