BeforeDiscovery {
    Import-Module "$PSScriptRoot\..\src\Azure.Bicep.psm1"
}

BeforeAll {
    Mock Get-AzDeploymentWhatIfResult { return Import-Clixml "$PSScriptRoot\mocks\whatif-result.xml" } -ModuleName Azure.Bicep
    Mock New-AzDeployment { return @() } -ModuleName Azure.Bicep
    Mock Write-Host { return "" } -ModuleName Azure.Bicep
    $params = @{
        Name         = "test-deployment-$((New-Guid).Guid)"
        Location     = "eastus"
        TemplateFile = "$PSScriptRoot\mocks\deploy.bicep"
        TemplateParameterFile = "$PSScriptRoot\mocks\dev.parameters.json"
    }
}

Describe "Azure.Bicep Unit Tests" {
    Context "New-AzureBicepDeployment" {
        It "Mode <Mode> should return <Count> changes" -ForEach @(
            @{ Mode = "WhatIf"; Count = 0; BuildReason = "PullRequest" }
            @{ Mode = "Deploy"; Count = 0; BuildReason = "PullRequest" }
            @{ Mode = "DeployIfChanged"; Count = 0; BuildReason = "PullRequest" }
        ) {
            Mock Get-EnvironmentVariable { return $BuildReason } -ModuleName Azure.Bicep
            $result = New-AzureBicepDeployment -DeploymentParameters $params -Mode $Mode
            $result.Changes.Count | Should -Be $Count
            
        }
    }

    Context "_getWhatifChanges" {
        It "Should return 2 changes" {
            $result = _getWhatifChanges -DeploymentParameters $params
            $result.Count | Should -Be 2
        }
    }
}

AfterAll {
    Remove-Module Azure.Bicep
}