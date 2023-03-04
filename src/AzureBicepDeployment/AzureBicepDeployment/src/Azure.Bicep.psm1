using namespace System.Management.Automation
Import-Module "$PSScriptRoot\DevOps.Utilities.psm1"

enum Mode {
    WhatIf
    Deploy
    DeployIfChanged
}

class ValidModes : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $arr = [System.Array]([Mode].GetEnumNames())
        return $arr
    }
}

function New-AzureBicepDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]$DeploymentParameters,

        [Parameter(Mandatory)]
        [ValidateSet([ValidModes])]
        [string]$Mode
    )
    switch ([Mode]$Mode) {
        ([Mode]::WhatIf) {
            Write-Host "##[section] Running WhatIf Deployment" 
            $result = _newWhatIfDeployment $DeploymentParameters
            Write-Output $result
            break;
        }
        ([Mode]::Deploy) {
            Write-Host "##[section] Running Deployment" 
            $result = New-AzDeployment @DeploymentParameters
            Write-Host "##[section]Success"
            break;
        }
        ([Mode]::DeployIfChanged) {
            Write-Host "##[section] Running WhatIf Deployment"
            $result = _getWhatifChanges $DeploymentParameters
            if($results.Count -gt 0) {
                Write-Host "##[section] Changes detected, running deployment"
                New-AzDeployment @DeploymentParameters
                Write-Host "##[section]Success"
            }
            else {
                Write-Host "##[section] No changes detected, skipping deployment"
            }
        }
        Default {
            Write-Waring "No Valid Mode Specified"
        }
    }
}

# Runs what-if deployment and removes Ignore and NoChange results
function _newWhatIfDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]$DeploymentParameters
    )
    # If you are in a pipeline this prints out better
    New-AzDeployment @DeploymentParameters -WhatIf
}

function _getWhatifChanges {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]$DeploymentParameters
    )
    $result = Get-AzDeploymentWhatIfResult @DeploymentParameters
    $changes = $result.Changes `
    | Where-Object { 
        $_.ChangeType -ne [Microsoft.Azure.Management.ResourceManager.Models.ChangeType]::Ignore 
    } `
    | Where-Object { 
        $_.ChangeType -ne [Microsoft.Azure.Management.ResourceManager.Models.ChangeType]::NoChange 
    }
    return $changes
}