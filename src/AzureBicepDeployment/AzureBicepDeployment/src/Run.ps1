param (
    [Parameter(Mandatory)]
    [string]$Endpoint,

    [Parameter(Mandatory)]
    [string]$BicepFile,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [string]$ParametersFile,

    [Parameter(Mandatory)]
    [string]$Mode
)
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\DevOps.Utilities.psm1"

try {
    Set-PipelineAzContext -Endpoint $Endpoint
    Import-Module "$PSScriptRoot\Azure.Bicep.psm1"

    $params = @{
        Name         = "test-deployment-$((New-Guid).Guid)"
        Location     = $Location
        TemplateFile = $BicepFile
    }
    if ($null -ne $ParametersFile) {
        $params.Add("TemplateParameterFile", $ParametersFile)
    }
    
    $result = New-AzureBicepDeployment -DeploymentParameters $params -Mode $Mode
}
catch {
    Write-Host "##[error]$_"
    # This forces the pipeline to fail instead of throwing like normal
    Write-Host "##vso[task.complete result=Failed;]DONE"
}