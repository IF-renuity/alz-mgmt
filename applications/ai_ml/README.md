# Azure Landing Zone — Infrastructure as Code

## Recommended Folder Structure

```
infra/
│
├── platform/                          # Platform team owns this layer
│   ├── default/                       # ALZ default config (mgmt groups, policies)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tf
│   │
│   └── single_zone/                   # Hub & Spoke connectivity platform
│       ├── main.tf                    # avm-ptn-alz-connectivity-hub-and-spoke-vnet
│       ├── variables.tf
│       ├── outputs.tf                 # ← Exports hub VNet ID, firewall IP, DNS zone IDs
│       ├── terraform.tf               # backend: tfstate/platform/single_zone
│       └── terraform.tfvars
│
└── applications/                      # App teams own this layer
    └── aiml/                          # AI/ML application landing zone
        ├── main.tf                    # avm-ptn-aiml-landing-zone v0.4.0 (BYO VNet)
        ├── variables.tf
        ├── outputs.tf
        ├── terraform.tf               # backend: tfstate/applications/aiml
        └── terraform.tfvars
```

---

## Why This Structure?

### Separation of concerns

```
platform/single_zone  →  owns:  Hub VNet, Firewall, DNS zones, Peering
applications/aiml     →  owns:  Spoke resources, AI Foundry, Private Endpoints
```

The platform layer and application layer have **separate Terraform state files**.
Application teams consume platform outputs via `terraform_remote_state` — they
never modify platform resources directly.

### State isolation

| Layer | State key |
|---|---|
| `platform/single_zone` | `platform/single_zone/terraform.tfstate` |
| `applications/aiml` | `applications/aiml/terraform.tfstate` |

This means the platform team can upgrade hub infrastructure without touching
application state, and application teams can deploy independently.

---

## How the Layers Connect

```
platform/single_zone
    │
    │  outputs:
    │    hub_virtual_network_resource_id
    │    firewall_private_ip_address
    │    private_dns_zone_resource_ids   ← map of ~26 AI/ML zone IDs
    │
    └──► applications/aiml  (reads via terraform_remote_state)
             │
             │  uses:
             │    BYO VNet → points to spoke VNet (pre-peered to hub)
             │    firewall IP → configures route tables in spoke subnets
             │    DNS zone IDs → writes PE A records into hub zones
             │
             └──► AI Foundry Hub, Key Vault, Storage, ACR, Log Analytics
                  (all with Private Endpoints → hub DNS zones)
```

---

## DNS Flow (No On-Premises, No Private DNS Resolver Needed)

```
AI/ML App in Spoke VNet
    │
    ▼ query: myaifoundry.api.azureml.ms
Azure DNS 168.63.129.16
    │
    ▼ public CNAME: myaifoundry.privatelink.api.azureml.ms
Check linked DNS zones on spoke VNet
    │
    ▼ zone linked from HUB: privatelink.api.azureml.ms
Return A record written by Private Endpoint
    │
    ▼ 10.1.2.5 (spoke private IP)
Connect privately ✓
```

---

## Deployment Order

```
Step 1:  platform/default       → Management groups, policies
Step 2:  platform/single_zone   → Hub VNet, Firewall, DNS zones
Step 3:  Create spoke VNet      → Peered to hub (can be in single_zone or separate)
Step 4:  applications/aiml      → AI Foundry + all supporting resources
```

---

## Key Variables to Set Before Deploying applications/aiml

In `terraform.tfvars`:

1. `spoke_vnet_resource_id` — The spoke VNet already peered to hub
2. `spoke_aiml_subnet_resource_id` — Subnet for private endpoints
3. `platform_state_storage_account_name` — Where platform state is stored
4. `location` / `environment` / `workload_name` — Naming identifiers

---

## Adding More Application Landing Zones

To add another application (e.g., `data`, `webapp`):

```
applications/
    ├── aiml/        ← AI/ML landing zone
    ├── data/        ← Data platform landing zone (new)
    └── webapp/      ← Web application landing zone (new)
```

Each reads the same `platform/single_zone` remote state for hub references.
Each gets its own spoke VNet and its own Terraform state file.
