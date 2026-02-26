# --- Configuration ---
$runFolderSetup  = $false  # Set to $false to skip New-AcceleratorFolderStructure
$deploy  = $true  # Set to $false to skip depoly
$iacType         = "terraform" 
$versionControl  = "github"
# "local"
$scenarioNumber  = 6
$targetFolderPath = "./accelerator/single_region_github"

# --- 1. Folder Structure (Optional) ---
if ($runFolderSetup) {
    Write-Host "Creating folder structure..." -ForegroundColor Cyan
    New-AcceleratorFolderStructure `
        -iacType $iacType `
        -versionControl $versionControl `
        -scenarioNumber $scenarioNumber `
        -targetFolderPath $targetFolderPath
} else {
    Write-Host "Skipping folder structure creation." -ForegroundColor Yellow
}

if ($deploy) {
    # --- 2. Deployment ---
    Write-Host "Starting deployment..." -ForegroundColor Green
    Deploy-Accelerator `
        -inputs "$targetFolderPath/config/inputs.yaml", "$targetFolderPath/config/platform-landing-zone.tfvars" `
        -starterAdditionalFiles "$targetFolderPath/config/lib" `
        -output "$targetFolderPath/output"
} else {
    Write-Host "Skipping accelerator deployment." -ForegroundColor Yellow
}