# Azure AI Platform - Deployment Runbook

**Version:** 1.0  
**Last Updated:** 2026-02-24  
**Target Architecture:** Single Region Hub-and-Spoke with AI/ML Landing Zone

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Deployment Phases](#deployment-phases)
   - [Phase 1: Bootstrap](#phase-1-bootstrap)
   - [Phase 2: Platform Deployment](#phase-2-platform-deployment)
   - [Phase 3: Application Deployment](#phase-3-application-deployment)
5. [Validation](#validation)
6. [Customization](#customization)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This runbook provides step-by-step instructions for deploying the Azure AI Platform using:

- **Azure Landing Zone Accelerator** — Code generation from standard templates
- **Terraform** — Infrastructure as Code deployment
- **GitHub Actions** — CI/CD automation with self-hosted runners
- **Hub-and-Spoke Architecture** — Centralized connectivity with isolated workloads

### Deployment Methodology

```
ALZ Accelerator → Generate Terraform Code → Bootstrap Deployment
                                                           ↓
                                Platform Deployment (Default / Connectivity-Only)
                                                           ↓
                                      Application Deployment (AI/ML)
                                                           ↓
                                         CI/CD Automation (GitHub Actions)
```

---

## Prerequisites

### Required Access

- [ ] Azure subscription with **Owner** role
- [ ] GitHub organization account with **Admin** access
- [ ] Service Principal with Contributor / User with Administrator Access

### Required Software

| Tool | Version | Purpose |
|---|---|---|
| PowerShell | 7.0+ | Bootstrap script execution |
| Azure PowerShell Module | Latest | Azure resource management |
| Terraform | 1.9+ | Infrastructure deployment |
| Azure CLI | 2.50+ | Azure operations |
| Git | 2.30+ | Version control |

### Installation Commands

```powershell
# PowerShell 7
winget install Microsoft.PowerShell

# Azure PowerShell Module
Install-Module -Name Az -Repository PSGallery -Force

# Azure CLI
winget install Microsoft.AzureCLI

# Terraform
winget install Hashicorp.Terraform

# Git
winget install Git.Git
```

### Required Information

Before starting, collect:
- Azure subscription ID(s)
- Azure region (e.g., `swedencentral`, `eastus`)
- GitHub organization name
- GitHub Personal Access Token (with `repo`, `workflow`, `admin:org` scopes)
- Naming prefix for resources (e.g., `contoso`, `ai-platform`)

---

## Architecture

### Folder Structure

```
azure_ai_platform/
├── azure-ai-platform-whitepaper-v3.html
├── README.md
└── single_region/
    ├── accelerator/                          # ALZ Accelerator output, part of the github as an example
    │   ├── deploy.ps1                      # Bootstrap deployment script
    │   ├── config/
    │   │   ├── inputs.yaml                  # ALZ Accelerator inputs
    │   │   └── platform-landing-zone.tfvars # input config for the scenario
    │   └── output/
    │       ├── bootstrap/
    │       └── starter/v15.2.0
    │           ├── platform_landing_zone    # Generated Terraform code
    │           ├── empty                    # Terraform code to created empty platform
    │           └── test                     
    │
    ├── platform/
    │   ├── default/                        # Full platform (copied from bootstrap)
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── terraform.tfvars
    │   │
    │   └── only_connectivity/              # Connectivity-only variant
    │       ├── main.tf                     # Customized (mgmt groups removed)
    │       ├── variables.tf
    │       ├── outputs.tf
    │       └── terraform.tfvars
    │
    └── applications/
        └── ai-ml/                          # AI/ML landing zone
            ├── main.tf
            ├── variables.tf
            ├── outputs.tf
            └── terraform.tfvars
```

### Logical Architecture

```
┌────────────────────────────────────────────────────────────────┐
│  PLATFORM (Connectivity Subscription)                          │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Hub VNet  (10.0.0.0/16 or 172.16.0.0/16)                │  │
│  │  ├─ Azure Firewall (10.0.1.4)                            │  │
│  │  ├─ VPN/ExpressRoute Gateway (optional)                  │  │
│  │  ├─ Azure Bastion (optional)                             │  │
│  │  └─ Private DNS Resolver (optional, for on-premises)     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Private DNS Zones (Centralized)                         │  │
│  │  ├─ privatelink.services.ai.azure.com                    │  │
│  │  ├─ privatelink.openai.azure.com                         │  │
│  │  ├─ privatelink.blob.core.windows.net                    │  │
│  │  ├─ privatelink.vaultcore.azure.net                      │  │
│  │  ├─ privatelink.documents.azure.com (Cosmos DB)          │  │
│  │  ├─ privatelink.search.windows.net                       │  │
│  │  └─ ... (~90 zones or customized subset)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                         │
                         │ VNet Peering
                         │
                         ▼
┌────────────────────────────────────────────────────────────────┐
│  APPLICATIONS (Workload Subscription)                          │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  AI/ML Spoke VNet  (192.168.0.0/23)                      │  │
│  │  ├─ Private Endpoint Subnet                              │  │
│  │  └─ AI Agent Services Subnet (Container Apps)            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
│  (GenAI Resources):                                            │
│  ├─ Cosmos DB                                                  │
│  ├─ Storage Account (Blob + File)                              │
│  ├─ Key Vault                                                  │
│  └─ AI Search                                                  │
│                                                                │
│  AI Foundry Hub + Projects:                                    │
│  ├─ AI Foundry Hub                                             │
│  ├─ AI Model Deployments (GPT-4, embeddings, etc.)             │
│  ├─ AI Projects (connected to shared resources)                │
│  ├─ Cosmos DB                                                  │
│  ├─ Storage Account (Blob + File)                              │
│  ├─ Key Vault                                                  │
│  └─ AI Search                                                  │
└────────────────────────────────────────────────────────────────┘
```

---

## Deployment Phases

### Phase 1: Bootstrap

**Purpose:** Generate foundational Terraform code using ALZ Accelerator and deploy GitHub runner infrastructure. Which creates folder structure similar to accelerator 

**Output:**
- Generated Terraform code for platform deployment
- Terraform state storage account
- GitHub self-hosted runner (Azure Container Instance)

---

Reference the [ALZ Accelerator documentation](https://aka.ms/alz/accelerator/docs) for more detail or for alternative approaches.

#### step 1.1 Prereqs

1. Binaries

    You will need at least the specified version of

    - [PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) (7.4)
    - [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (2.55.0)
    - [Git](https://git-scm.com/downloads)

    It is also assumed that you are using [Visual Studio Code](https://aka.ms/vscode) with the [Hashicorp Terraform](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform) extension.

1. ALZ PowerShell modules

   ```powershell
   Install-Module -Name ALZ
   ```

   Use `Update-Module ALZ` to update.

1. Authorisation

    Elevate in Entra ID's tenant properties, then assign yourself as Owner at tenant root group.

    ```shell

    az role assignment create --assignee "$(az ad signed-in-user show --query id -otsv)" --role "Owner" --scope "/providers/Microsoft.Management/managementGroups/$(az account show --query tenantId -otsv)"
    ```

    You may remove the RBAC role assignment once the accelerator has run.

1. Subscriptions

    The setup assumes that you have three subscriptions that will be assigned to the platform landing zone area.

    - management
    - connectivity
    - identity

1. GitHub ID and Organization

    You will need both a GitHub ID and an organization. The ALZ accelerator does not work in a user context.

1. Create personal access tokens for the accelerator and private runners

    Create the two [personal access tokens](https://github.com/settings/tokens). Save the generated token for each.

    1. __Azure Landing Zone Terraform Accelerator__

        - repo
        - workflow
        - admin:org
        - user : read:user
        - user : read:email
        - delete_repo

        Short expiry, e.g. tomorrow.

    1. Azure Landing Zone Private Runners

        - repo
        - admin:org (for Enterprise organization only)

        Permanent.


---

#### Step 1.2: Configure Bootstrap Files

1. create required folders using `single_region/accelerator/deploy.ps1`

```powershell
# --- Configuration ---
$runFolderSetup  = $true     # First deployment: $true, Re-runs: $false
$deploy          = $false     # Set to $false to skip deployment
$iacType         = "terraform"
$versionControl  = "github"  # or "azuredevops", "local"
$scenarioNumber  = 6         # Scenario 6: Single region with GitHub
$targetFolderPath = "./accelerator/single_region_github"
```

**File:** `accelerator/single_region_github/config/inputs.yaml`

2. Edit inputs.yaml

    Example file:

    ```yaml
    ---
    # For detailed instructions on using this file, visit:
    # https://aka.ms/alz/accelerator/docs

    # Basic Inputs
    iac_type: "terraform"
    bootstrap_module_name: "alz_github"
    starter_module_name: "none"

    # Shared Interface Inputs
    bootstrap_location: "change_me"                     # E.g. "uksouth"
    subscription_ids:
      management: "change_me"
      identity: "change_me"
      connectivity: "change_me"
      security: "change_me"

    # Bootstrap Inputs
    github_personal_access_token: "change_me"           # PAT for Terraform accelerator
    github_runners_personal_access_token: "change_me"   # PAT for private runners
    github_organization_name: "change_me"
    use_separate_repository_for_templates: true
    bootstrap_subscription_id: "change_me"              # Management subscription ID
    service_name: "alz"
    environment_name: "mgmt"
    postfix_number: 1
    use_self_hosted_runners: true
    use_private_networking: true
    allow_storage_access_from_my_ip: false
    apply_approvers: ["change_me"]                      # GitHub ID
    create_branch_policies: true

    # Advanced Inputs
    bootstrap_module_version: "latest"
    starter_module_version: "latest"
    output_folder_path: "~/accelerator/output"
    ```

**File:** `accelerator/single_region_github/platform-landing-zone.tfvars`
3. edit platform-landing-zone which controls the resource deployments of platform
```hcl
# Core Settings
location       = "swedencentral"
location_short = "sec"

# Hub Network
vnet_address_space = "10.0.0.0/16"

# Firewall
firewall_sku_tier = "Standard"  # or "Premium" for production

# DNS Zones (optional cost optimization)
enable_private_dns_resolver = false

# Exclude zones you don't need
private_link_excluded_zones = [
  # Add zones to exclude (see TFVARS-CUSTOMIZATION.md for examples)
]
```

**💡 Tip:** See `TFVARS-CUSTOMIZATION.md` for detailed examples.

---
#### Step 1.3: Run Bootstrap Deployment

```powershell
# Navigate to  folder
# Execute deployment script
./deploy.ps1
```

**What Happens:**

1. **Folder Structure Creation** (if `$runFolderSetup = $true`)
   - Generates Terraform code in `./accelerator/single_region_github/output/`
   - Creates GitHub workflow templates
   - Structures files per ALZ best practices

2. **Terraform Deployment** (if `$deploy = $true`)
   - Creates Azure Storage Account for Terraform state
   - creates github repo (if `versionControl = github`)
    - Deploys GitHub self-hosted runner (Azure Container Instance)
    - Configures runner registration with your GitHub repo
   - Initializes Terraform backend configuration

---

#### Step 1.6: Verify Bootstrap Outputs

**Check 1: Generated Code**
```powershell
# List generated Terraform files
Get-ChildItem ./accelerator/single_region_github/output -Recurse -File
```

Expected files:
- `main.tf`
- `variables.tf`
- `outputs.tf`
- `terraform.tfvars`
- `.github/workflows/*.yml`

**Check 2: Terraform State Storage**
```powershell
# Verify state storage account
az storage account show \
  --name <state-storage-account-name> \
  --resource-group <bootstrap-resource-group> \
  --query "[name,location,provisioningState]"
```

Expected output:
```json
{
  "name": "sttfstateaiplatformsec",
  "location": "swedencentral",
  "provisioningState": "Succeeded"
}
```

**Check 3: GitHub Runner**
```powershell
# Check runner status in Azure
az container show \
  --name <runner-container-name> \
  --resource-group <bootstrap-resource-group> \
  --query "[name,provisioningState,instanceView.state]"
```

**Check 4: GitHub Runner Registration**

Navigate to: `https://github.com/<org>/<repo>/settings/actions/runners`

Verify:
- Runner appears in list
- Status: **Online** (green)
- Labels: `self-hosted`, `azure`, `terraform`

---

#### Step 1.7: Save Bootstrap Outputs

**Critical Information to Record:**

| Output | Value | Used In |
|---|---|---|
| State Storage Account Name | `sttfstate*` | Platform & Application backends |
| State Resource Group Name | `rg-terraform-state-*` | Platform & Application backends |
| State Container Name | `tfstate` | Platform & Application backends |
| GitHub Runner Name | `runner-*` | GitHub Actions workflows |
| Subscription ID | `xxxx-xxxx-xxxx` | Platform & Application configs |

**Save to:** Secure location (Key Vault, password manager)

---

## Phase 2: Platform Deployment

**Purpose:** Reorganize ALZ-generated Terraform code and deploy platform infrastructure.

**Prerequisites:**
- Phase 1 (Bootstrap) completed successfully
- ALZ Accelerator created two GitHub repositories:
  - `alz-mgmt-templates` (workflow templates)
  - `alz-mgmt` (Terraform code + workflows)

**Output:**
- Organized platform code in folder structure
- Deployed hub network, firewall, and DNS zones
- Platform outputs available for application deployment

---

### Understanding the ALZ Repository Structure

**Repository 1: `alz-mgmt-templates`**
```
alz-mgmt-templates/
└── .github/
    └── workflows/
        └── cd-template.yaml      # Reusable workflow template (plan/apply logic)
```
**Purpose:** Shared workflow templates used by `alz-mgmt` repo.

---

**Repository 2: `alz-mgmt`** (Your working repository)
```
alz-mgmt/                         # Initial state (ALZ-generated)
├── main.tf                       # Terraform at root level
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules/
│   ├── management/
│   ├── connectivity/
│   └── identity/
└── .github/
    └── workflows/
        └── cd.yml         # Calls cd-template.yaml from alz-mgmt-templates
```

---

### Step 2.1: Clone ALZ Management Repository

```bash
# Clone the ALZ-generated repository
git clone https://github.com/<your-org>/alz-mgmt.git
cd alz-mgmt

# Verify initial structure (Terraform at root level)
ls -la
# Expected: main.tf, variables.tf, outputs.tf, etc.
```

---

### Step 2.2: Create Development Branch

**Important:** The `main` branch is protected. All changes must go through Pull Requests.

```bash
# Create and checkout development branch
git checkout -b dev

# Verify you're on dev branch
git branch
# Expected output:
#   * dev
#     main
```

---

### Step 2.3: Reorganize Code Structure

**Goal:** Move Terraform code into organized folder structure.

**Option A: Default Platform (Full ALZ)**

```bash
# Create platform folder
mkdir -p platform/default

# Move Terraform files to platform/default/
mv *.tf platform/default/
mv *.tfvars platform/default/
mv modules platform/default/

# Keep .github folder at root
# Keep README.md, .gitignore at root if they exist
```

**Final structure:**
```
alz-mgmt/
├── platform/
│   └── default/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── modules/
└── .github/
    └── workflows/
        └── 02-alz-cd.yml
```

---

**Option B: Connectivity-Only Platform (Customized)**

```bash
# Create platform folder
mkdir -p platform/only_connectivity

# Move Terraform files
mv *.tf platform/only_connectivity/
mv *.tfvars platform/only_connectivity/
mv modules platform/only_connectivity/

# Customize main.tf to remove management groups (optional)
# See example in azure_ai_platform/single_region/platform/only_connectivity/
```
---

### Step 2.4: Update GitHub Workflow

**File:** `.github/workflows/cd.yml`

**Current content (ALZ-generated):**
```yaml
name: 02 Azure Landing Zones Continuous Delivery
on:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      terraform_action:
        description: 'Terraform Action to perform'
        required: true
        default: 'apply'
        type: choice
        options:
          - 'apply'
          - 'destroy'
      terraform_cli_version:
        description: 'Terraform CLI Version'
        required: true
        default: 'latest'
        type: string

jobs:
  plan_and_apply:
    uses: <your-org>/alz-mgmt-templates/.github/workflows/cd-template.yaml@main
    name: 'CD'
    permissions:
      id-token: write
      contents: read
    with:
      terraform_action: ${{ inputs.terraform_action }}
      root_module_folder_relative_path: '.'
      terraform_cli_version: ${{ inputs.terraform_cli_version }}
```

**Modified content (Add `root_module_folder_relative_path` and `state_file_path`):**

```yaml
name: 02 Azure Landing Zones Continuous Delivery
on:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      terraform_action:
        description: 'Terraform Action to perform'
        required: true
        default: 'apply'
        type: choice
        options:
          - 'apply'
          - 'destroy'

      terraform_cli_version:
        description: 'Terraform CLI Version'
        required: true
        default: 'latest'
        type: string

      root_module_folder_relative_path:
        description: 'Relative path of Terraform scripts to be executed'
        required: true
        default: './platform/only_connectivity'
        type: string

      state_file_path:
        description: 'Full path of terraform state file'
        default: 'terraform.tfstate'
        type: string

jobs:
  plan_and_apply:
    uses: <your-org>/alz-mgmt-templates/.github/workflows/cd-template.yaml@main
    name: 'CD'
    permissions:
      id-token: write
      contents: read
    with:
      terraform_action: ${{ inputs.terraform_action }}
      root_module_folder_relative_path: ${{ inputs.root_module_folder_relative_path }}
      terraform_cli_version: ${{ inputs.terraform_cli_version }}
```

**Key Changes:**
1. Added `root_module_folder_relative_path` and `state_file_path` as input parameter
2. Default value: `'./platform/only_connectivity'` (adjust if using `default` instead)
3. Passed parameter to workflow template

---

### Step 2.5: Customize Platform Configuration (Optional)

**File:** `platform/only_connectivity/terraform.tfvars`

Update values as needed:

```hcl
# Location
location       = "swedencentral"
location_short = "sec"

# Hub Network
vnet_address_space = "10.0.0.0/16"

# Resource provisioning global connectivity
    ddos_protection_plan_enabled = false

# Resource provisioning primary connectivity
primary_firewall_enabled                                             = true
primary_firewall_management_ip_enabled                               = true
primary_virtual_network_gateway_express_route_enabled                = false
primary_virtual_network_gateway_express_route_hobo_public_ip_enabled = false
primary_virtual_network_gateway_vpn_enabled                          = false
primary_private_dns_zones_enabled                                    = true
primary_private_dns_auto_registration_zone_enabled                   = true
primary_private_dns_resolver_enabled                                 = true
primary_bastion_enabled                                              = true


# DNS Zones - Cost Optimization
private_link_excluded_zones = [
  "azure_maria_db_server",
  "azure_mysql_db_server",
  # Add more zones you don't need
]
hub_virtual_networks.primary.private_dns_zones.private_link_private_dns_zones = {
  azure_ml = { 
    zone_name = "privatelink.api.azureml.ms" 
  }
}

# Private DNS Resolver (only if on-premises)
enable_private_dns_resolver = false
```

**💡 Reference:** See `TFVARS-CUSTOMIZATION.md` for detailed examples.

---

### Step 2.6: Commit and Push to Dev Branch

```bash
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "feat: reorganize platform code into folder structure

- Moved Terraform files to platform/only_connectivity/
- Updated workflow to support root_module_folder_relative_path
- Customized terraform.tfvars for environment"

# Push to dev branch
git push origin dev
```

---

### Step 2.7: Create Pull Request

**In GitHub UI:**

1. Navigate to `https://github.com/<your-org>/alz-mgmt`
2. Click **"Compare & pull request"** (appears after pushing to dev)
3. **Title:** `feat: Platform deployment - Connectivity layer`
4. **Description:**
   ```
   ## Changes
   - Reorganized Terraform code into platform/only_connectivity/ folder
   - Updated workflow to support custom folder paths
   - Configured platform variables for swedencentral region
   
   ## Testing
   - [ ] Terraform validate passed locally
   - [ ] Reviewed terraform.tfvars configuration
   - [ ] Workflow file syntax validated
   
   ## Deployment
   After merge, trigger workflow manually with:
   - terraform_action: apply
   - root_module_folder_relative_path: ./platform/only_connectivity
   ```
5. **Reviewers:** Add platform team members
6. Click **"Create pull request"**

---

### Step 2.8: Review and Merge PR

**Review Checklist:**
- [ ] Terraform files moved to correct folder
- [ ] Workflow updated with `root_module_folder_relative_path`
- [ ] `terraform.tfvars` configured correctly
- [ ] No sensitive data in code
- [ ] Folder structure matches documentation

**Merge PR:**
1. Address any review comments
2. Ensure all checks pass (if CI checks configured)
3. Click **"Squash and merge"** or **"Merge pull request"**
4. Delete `dev` branch after merge (optional)

---

### Step 2.9: Deploy Platform via GitHub Actions

**Option A: Automatic Deployment (on push to main)**

If workflow is configured with `push: branches: - main`, deployment starts automatically after PR merge.

Monitor at: `https://github.com/<your-org>/alz-mgmt/actions`

---

**Option B: Manual Deployment (workflow_dispatch)**

1. Navigate to **Actions** tab in GitHub
2. Click **"02 Azure Landing Zones Continuous Delivery"** workflow
3. Click **"Run workflow"** dropdown
4. Select branch: `main`
5. Configure inputs:
   - **terraform_action:** `apply`
   - **terraform_cli_version:** `latest`
   - **root_module_folder_relative_path:** `./platform/only_connectivity`
6. Click **"Run workflow"**

**Monitor Deployment:**
- Click on the running workflow
- Expand job steps to see Terraform output
- Review plan before apply (if workflow includes approval step)

---

### Step 2.10: Verify Platform Deployment

**Check 1: Workflow Completed Successfully**

In GitHub Actions:
- Status: ✅ **Success** (green checkmark)
- All jobs completed without errors
- Terraform apply succeeded

---

**Check 2: Azure Resources Created**

```bash
# Login to Azure
az login

# List resource groups (should see connectivity RG)
az group list --query "[?contains(name,'connectivity')].{Name:name,Location:location}" -o table

# Check hub VNet
az network vnet show \
  --name <hub-vnet-name> \
  --resource-group <connectivity-rg-name> \
  --query "{Name:name,AddressSpace:addressSpace.addressPrefixes[0],Location:location}"

# Check Azure Firewall
az network firewall show \
  --name <firewall-name> \
  --resource-group <connectivity-rg-name> \
  --query "{Name:name,ProvisioningState:provisioningState,Tier:sku.tier}"

# Check Private DNS Zones count
az network private-dns zone list \
  --resource-group <dns-rg-name> \
  --query "length(@)"
# Expected: 26-90 zones depending on exclusions
```

---

**Check 3: Platform Outputs Available**

Platform outputs are stored in Terraform state and must be accessible to application deployments.

**Verify outputs exist:**

1. **Via GitHub Actions Workflow:**
   - Add a step in workflow to output values:
   ```yaml
   - name: Show Platform Outputs
     run: |
       terraform output hub_virtual_network_resource_id
       terraform output firewall_private_ip_address
       terraform output private_dns_zone_resource_ids
     working-directory: ./platform/only_connectivity
   ```

2. **Via Local Terraform (if state accessible):**
   ```bash
   cd platform/only_connectivity
   terraform init
   terraform output
   ```

**Critical outputs required for applications:**
- `hub_virtual_network_resource_id`
- `firewall_private_ip_address`
- `private_dns_zone_resource_ids` (map)
- `hub_resource_group_resource_id`

**If outputs are missing:** Update `platform/only_connectivity/outputs.tf` and re-run workflow.

---

## Phase 3: Application Deployment

**Purpose:** Deploy AI/ML application landing zone using custom code.

**Prerequisites:**
- Phase 2 (Platform) deployed successfully
- Platform outputs available
- Custom AI/ML code available in `azure_ai_platform` example repository

**Output:**
- AI/ML spoke network peered to hub
- Shared resources (Cosmos DB, Storage, Key Vault, AI Search)
- AI Foundry Hub with model deployments
- AI Projects connected to shared resources

---

### Step 3.1: Prepare Custom Application Code

**Source Repository:** `azure_ai_platform` (https://github.com/DataGrokrAnalytics/<repo_name>.git)

```bash
# Clone or navigate to your example repository
git clone https://github.com/<your-org>/azure_ai_platform.git
cd azure_ai_platform/single_region/applications/ai-ml

# Review the custom code structure
ls -la
# Expected files:
# - main.tf (manual resource creation + AI Foundry BYOR)
# - variables.tf
# - outputs.tf
# - terraform.tfvars
# - README.md
```

**Key Files to Copy:**
- `main.tf` — AI/ML infrastructure with BYOR pattern
- `variables.tf` — Input variable definitions
- `outputs.tf` — Output definitions
- `terraform.tfvars` — Configuration template (will need customization)
- `README.md` — Documentation

---

### Step 3.2: Create Application Folder in ALZ Repository

**Switch to ALZ management repository:**

```bash
# Navigate to ALZ repo
cd /path/to/alz-mgmt

# Ensure you're on dev branch (or create new feature branch)
git checkout dev

# If starting fresh, create from latest main
git checkout -b dev
git pull origin main

# Create application folder structure
mkdir -p applications/ai-ml

# Copy custom AI/ML code
cp -r /path/to/azure_ai_platform/single_region/applications/ai-ml/* \
     applications/ai-ml/
```

**Resulting structure:**
```
alz-mgmt/
├── platform/
│   └── only_connectivity/
│       └── (platform code)
├── applications/
│   └── ai-ml/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── README.md
└── .github/
    └── workflows/
        ├── cd.yml (platform workflow)
        └── 03-application-aiml-cd.yml (to be created)
```

---

### Step 3.3: Customize Application Configuration

**File:** `applications/ai-ml/terraform.tfvars`

**Update with your environment values:**

```hcl
# ── Identity ──────────────────────────────────────────────────────────────
location       = "swedencentral"  # Must match platform region
location_short = "sec"
environment    = "dev"            # or "tst", "stg", "prd"
workload_name  = "aiml"

# ── Resource Group ────────────────────────────────────────────────────────
resource_group_name = "rg-aiml-dev-sec-001"

# ── VNet Configuration ────────────────────────────────────────────────────
# CRITICAL: AI Foundry requires 192.168.0.0/16 range
vnet_address_space = "192.168.0.0/23"

# DNS servers (leave empty to use Azure default)
hub_dns_server_ips = []

# ── Platform Remote State ─────────────────────────────────────────────────
# Point to platform Terraform state
platform_state_resource_group_name  = "rg-terraform-state-<name>"  # From bootstrap
platform_state_storage_account_name = "sttfstate<name>"            # From bootstrap
platform_state_container_name       = "tfstate"
platform_state_key                  = "platform/only_connectivity/terraform.tfstate"

# ── AI Model Deployments ──────────────────────────────────────────────────
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
      capacity = 20
    }
  }
}

# ── Tags ──────────────────────────────────────────────────────────────────
tags = {
  Environment = "dev"
  Workload    = "aiml"
  ManagedBy   = "terraform"
}
```

**Important Updates:**
1. **Platform state location:** Use actual values from bootstrap outputs
2. **VNet address space:** Must be `192.168.0.0/16` range (AI Foundry requirement)
3. **Platform state key:** Must match the path used in Phase 2 (`platform/only_connectivity/terraform.tfstate`)

---

### Step 3.4: Update Application Terraform Backend

**File:** `applications/ai-ml/terraform.tf` (or backend configuration in `main.tf`)

Ensure backend state file points to correct state location:

update `state_file_path` = `application/ai-ml/terraform.tstate`

**💡 Critical:** Application state must be in a DIFFERENT state file path than platform.

---

### Step 3.5: Create Application Workflow

**File:** `.github/workflows/03-application-aiml-cd.yml`

Create new workflow for application deployment:

```yaml
name: 03 Application AI/ML Continuous Delivery
on:
  push:
    branches:
      - main
    paths:
      - 'applications/ai-ml/**'
  workflow_dispatch:
    inputs:
      terraform_action:
        description: 'Terraform Action to perform'
        required: true
        default: 'apply'
        type: choice
        options:
          - 'apply'
          - 'destroy'

      terraform_cli_version:
        description: 'Terraform CLI Version'
        required: true
        default: 'latest'
        type: string

      root_module_folder_relative_path:
        description: 'Relative path of Terraform scripts to be executed'
        required: true
        default: './application/ai-ml'
        type: string

      state_file_path:
        description: 'Full path of terraform state file'
        default: 'application/ai-ml/terraform.tfstate'
        type: string

jobs:
  plan_and_apply:
    uses: <your-org>/alz-mgmt-templates/.github/workflows/cd-template.yaml@main
    name: 'CD'
    permissions:
      id-token: write
      contents: read
    with:
      terraform_action: ${{ inputs.terraform_action }}
      root_module_folder_relative_path: ${{ inputs.root_module_folder_relative_path }}
      terraform_cli_version: ${{ inputs.terraform_cli_version }}
```

**Key Differences from Platform Workflow:**
- Different name: `03 Application AI/ML Continuous Delivery`
- Triggers on `applications/ai-ml/**` path changes
- Default `root_module_folder_relative_path`: `./applications/ai-ml`
- state file `application/ai-ml/terraform.tstate`

---

### Step 3.6: Commit Application Code to Dev Branch

```bash
# Verify you're on dev branch
git branch

# Stage all application files
git add applications/ai-ml/
git add .github/workflows/03-application-aiml-cd.yml

# Commit
git commit -m "feat: add AI/ML application landing zone

- Added custom AI/ML infrastructure code
- Configured shared resources with BYOR pattern
- Set up AI Foundry Hub with model deployments
- Created application deployment workflow
- Configured platform state integration"

# Push to dev branch
git push origin dev
```

---

### Step 3.7: Create Pull Request for Application

**In GitHub UI:**

1. Navigate to `https://github.com/<your-org>/alz-mgmt`
2. Click **"Compare & pull request"**
3. **Title:** `feat: AI/ML Application Landing Zone`
4. **Description:**
   ```
   ## Changes
   - Added AI/ML application code to applications/ai-ml/
   - Created spoke VNet with hub peering
   - Configured shared resources (Cosmos, Storage, Key Vault, AI Search)
   - Set up AI Foundry Hub with BYOR pattern
   - Added application deployment workflow
   
   ## Configuration
   - VNet: 192.168.0.0/23 (AI Foundry requirement)
   - Models: GPT-4o, Text Embeddings
   - Platform state: platform/only_connectivity/terraform.tfstate
   
   ## Testing
   - [ ] Terraform validate passed
   - [ ] Platform outputs accessible
   - [ ] No duplicate resources in code
   - [ ] Workflow file syntax validated
   
   ## Deployment
   After merge, trigger workflow manually with:
   - terraform_action: apply
   - root_module_folder_relative_path: ./applications/ai-ml
   ```
5. **Reviewers:** Add application team members
6. Click **"Create pull request"**

---

### Step 3.8: Review and Merge PR

**Review Checklist:**
- [ ] Application code structure correct
- [ ] `terraform.tfvars` configured with correct values
- [ ] Platform state path matches Phase 2 deployment
- [ ] VNet address space is in `192.168.0.0/16` range
- [ ] No hardcoded credentials or secrets
- [ ] Workflow file created and configured correctly
- [ ] Using BYOR pattern (no duplicate resource creation)

**Merge PR:**
1. Address review comments
2. Wait for approval from reviewers
3. Click **"Squash and merge"**
4. Optionally delete `dev` branch

---

### Step 3.9: Deploy Application via GitHub Actions

**Option A: Automatic Deployment**

If workflow triggers on push to `main`, it starts automatically after merge.

---

**Option B: Manual Deployment** (Recommended for first deployment)

1. Navigate to **Actions** tab
2. Click **"03 Application AI/ML Continuous Delivery"**
3. Click **"Run workflow"**
4. Select branch: `main`
5. Configure inputs:
   - **terraform_action:** `apply`
   - **terraform_cli_version:** `latest`
   - **root_module_folder_relative_path:** `./applications/ai-ml`
6. Click **"Run workflow"**

**Monitor Deployment:**
- Watch workflow progress in GitHub Actions
- Review Terraform plan output
- Verify no errors during apply
- Check that only 1 of each resource is created (Cosmos DB, Storage, etc.)

---

### Step 3.10: Verify Application Deployment

**Check 1: Workflow Completed Successfully**

✅ Workflow status: Success  
✅ No errors in Terraform apply  
✅ All resources created

---

**Check 2: Spoke Network Created**

```bash
# Check spoke VNet
az network vnet show \
  --name vnet-aiml-dev-sec \
  --resource-group rg-aiml-dev-sec-001 \
  --query "{Name:name,AddressSpace:addressSpace.addressPrefixes[0]}"

# Expected output:
# {
#   "Name": "vnet-aiml-dev-sec",
#   "AddressSpace": "192.168.0.0/23"
# }

# Check VNet peering
az network vnet peering list \
  --vnet-name vnet-aiml-dev-sec \
  --resource-group rg-aiml-dev-sec-001 \
  --query "[].{Name:name,PeeringState:peeringState,RemoteVNet:remoteVirtualNetwork.id}" -o table

# Expected: PeeringState = Connected
```

---

**Check 3: Resources**

```bash
# List all resources in AI/ML resource group
az resource list \
  --resource-group rg-aiml-dev-sec-001 \
  --query "[].{Name:name,Type:type}" -o table
```

**✅ Expected Output :**
```
Name                      Type
------------------------  ----------------------------------------
cosmos-aiml-dev-sec       Microsoft.DocumentDB/databaseAccounts
staimldevsec              Microsoft.Storage/storageAccounts
kv-aiml-dev-sec           Microsoft.KeyVault/vaults
srch-aiml-dev-sec         Microsoft.Search/searchServices
aif-aiml-dev-sec          Microsoft.CognitiveServices/accounts
vnet-aiml-dev-sec         Microsoft.Network/virtualNetworks
```

**Check 4: AI Foundry Hub and Models**

```bash
# Check AI Foundry Hub
az cognitiveservices account show \
  --name aif-aiml-dev-sec \
  --resource-group rg-aiml-dev-sec-001 \
  --query "{Name:name,ProvisioningState:provisioningState,Kind:kind}"

# List model deployments
az cognitiveservices account deployment list \
  --name aif-aiml-dev-sec \
  --resource-group rg-aiml-dev-sec-001 \
  --query "[].{Name:name,Model:properties.model.name,Capacity:properties.sku.capacity}" -o table
```

**Expected Output:**
```
Name                  Model                     Capacity
--------------------  ------------------------  ---------
gpt-4o-deployment     gpt-4o                    20
```

---

**Check 5: AI Foundry Connections (Azure Portal)**

1. Navigate to Azure Portal
2. Go to **AI Foundry Hub** resource: `aif-aiml-dev-sec`
3. Click **Settings** → **Connected resources**
4. Verify connections:

   | Resource Type | Resource Name | Status |
   |---|---|---|
   | Cosmos DB | `cosmos-aiml-dev-sec` | ✅ Connected |
   | Storage Account | `staimldevsec` | ✅ Connected |
   | Key Vault | `kv-aiml-dev-sec` | ✅ Connected |
   | AI Search | `srch-aiml-dev-sec` | ✅ Connected |

**All connections should show status: Connected**

---

## Summary

### Deployment Flow Recap

```
Phase 1: Bootstrap
   ↓
   Creates: alz-mgmt-templates + alz-mgmt repos
   ↓
Phase 2: Platform
   ↓
   Clone alz-mgmt → dev branch → reorganize code → PR to main → deploy
   ↓
   Creates: Hub VNet, Firewall, DNS zones
   ↓
Phase 3: Application
   ↓
   Copy custom code → dev branch → configure → PR to main → deploy
   ↓
   Creates: Spoke VNet, Shared Resources, AI Foundry
```

### Key Principles

1. **Protected Main Branch:** All changes via Pull Requests from `dev` or feature branches
2. **Two Repositories:** 
   - `alz-mgmt-templates` — Workflow templates (don't modify)
   - `alz-mgmt` — Your working repo (Terraform + workflows)
3. **Folder Organization:** Platform and applications in separate folders
4. **Workflow Customization:** Added `root_module_folder_relative_path` for flexible deployments
5. **State Separation:** Platform and application use different state file paths

### Next Steps

- Configure additional environments (test, staging, production)
- Add more application landing zones
- Set up monitoring and alerting
- Implement backup and disaster recovery
- Document custom procedures

---
## Customization

### Common Customization Scenarios

Refer to `TFVARS-CUSTOMIZATION.md` for detailed examples of:

1. **Environment-Specific Configurations** (dev vs prod)
2. **Cost Optimization** (DNS zone reduction, resource right-sizing)
3. **Multi-Region Deployment** (separate platform per region)
4. **Resource Scaling** (AI model capacity, storage replication)
5. **Tagging Strategies** (cost allocation, governance)

### Quick Customization Reference

| Scenario | File to Edit | Example |
|---|---|---|
| Change hub VNet CIDR | `platform/only_connectivity/terraform.tfvars` | `vnet_address_space = "172.16.0.0/16"` |
| Reduce DNS zones | `platform/only_connectivity/terraform.tfvars` | Add to `private_link_excluded_zones` |
| Add AI model | `applications/ai-ml/terraform.tfvars` | Add to `ai_model_deployments` map |
| Change environment | `applications/ai-ml/terraform.tfvars` | `environment = "prd"` |
| Enable Bastion | `applications/ai-ml/terraform.tfvars` | `enable_bastion = true` |

---

## Troubleshooting

### Common Issues

#### Issue 1: GitHub Runner Offline

**Symptom:** Workflows fail with "No runner online."

**Diagnosis:**
```bash
az container show \
  --name <runner-container-name> \
  --resource-group <bootstrap-resource-group> \
  --query "instanceView.state"
```

**Solution:**
```bash
# Restart runner container
az container restart \
  --name <runner-container-name> \
  --resource-group <bootstrap-resource-group>

# Wait 2-3 minutes and verify in GitHub
```

---

#### Issue 2: Terraform State Lock

**Symptom:** "Error acquiring the state lock"

**Solution:**
```bash
# Get lock ID from error message
terraform force-unlock <LOCK_ID>

# If that fails, remove blob lease manually
az storage blob lease break \
  --blob-name <state-file-name> \
  --container-name tfstate \
  --account-name <state-storage-account>
```

---

#### Issue 3: DNS Resolution Not Working

**Symptom:** Private endpoints resolve to public IPs instead of private.

**Diagnosis:**
```bash
# From VM in spoke VNet
nslookup staimldevsec.blob.core.windows.net

# Should return 192.168.x.x, not public IP
```

**Solution:**
1. Verify VNet is linked to private DNS zone
2. Check `private_dns_zones.azure_policy_pe_zone_linking_enabled = true`
3. Verify hub resource group ID is correct in application config
4. Check DNS zone exists in hub for the service type

---

#### Issue 4: Platform Outputs Not Available

**Symptom:** Application deployment fails with "output not found."

**Diagnosis:**
```bash
cd single_region/platform/only_connectivity
terraform output
```

**Solution:**
1. Ensure platform outputs are defined in `outputs.tf`
2. Run `terraform refresh` in platform folder
3. Verify state file exists and is accessible
4. Check application's `platform_state_key` points to correct path

---

### Getting Help

| Issue Type | Resource |
|---|---|
| ALZ Accelerator | https://github.com/Azure/Azure-Landing-Zones/issues |
| Terraform | https://github.com/hashicorp/terraform/issues |
| Azure Support | Azure Portal → Support + Troubleshooting |
| GitHub Actions | https://github.com/<org>/<repo>/issues |

---

## Appendix

### Useful Commands

```bash
# Check Azure CLI version
az --version

# List all resource groups
az group list -o table

# Check Terraform version
terraform version

# Validate Terraform configuration
terraform validate

# Format Terraform code
terraform fmt -recursive

# View Terraform state
terraform show

# List resources in state
terraform state list

# View specific resource
terraform state show <resource-address>
```
---
### Reference Documentation

- **ALZ Accelerator:** https://azure.github.io/Azure-Landing-Zones/accelerator/, https://aka.ms/alz/tf
- **Azure Verified Modules:** https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-pattern-modules/
- **Terraform Azure Provider:** https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure Landing zone Documentation:** https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
- **AI Foundry Documentation:** https://learn.microsoft.com/azure/ai-studio/
- **GitHub Actions:** https://docs.github.com/actions
- **Video tutorial to use Azure accelerator** https://www.youtube.com/watch?v=YxOzTwEnDE0&t=5844s, https://www.youtube.com/watch?v=IyQM_wG_X_Q

