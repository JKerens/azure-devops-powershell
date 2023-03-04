using namespace System.Management.Automation

enum Scope {
    Subscription
    Process
}

enum Scheme {
    ServicePrincipal
}

enum AuthenticationType {
    SPNKey
}

class ValidEnvironmentVariables : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $arr = (Get-ChildItem "env:*").Name
        return $arr
    }
}

# Borrowed heavily from https://github.com/microsoft/azure-pipelines-tasks/blob/0be588980db6671af970076f5acf91263b127343/Tasks/AzurePowerShellV5/InitializeAz.ps1#L72
function Set-PipelineAzContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint
    )
    # required to resolve Azure PowerShell Modules
    _setPipelineAzModulePath

    $endpointObject = $Endpoint | ConvertFrom-Json
    $environmentName = $endpointObject.environment
    $scopeLevel = [Scope]::Subscription.ToString()
    if ($endpointObject.scopeLevel) {
        $scopeLevel = $endpointObject.scopeLevel
    }
    $processScope = @{ Scope = [Scope]::Process.ToString() }

    if ($endpointObject.scheme -eq [Scheme]::ServicePrincipal.ToString()) {
        try {
            if ($endpointObject.authenticationType -ieq [AuthenticationType]::SPNKey.ToString()) {
                $psCredential = New-Object System.Management.Automation.PSCredential(
                    $endpointObject.servicePrincipalClientID,
                    (ConvertTo-SecureString $endpointObject.servicePrincipalKey -AsPlainText -Force))
                Write-Host "##[command]Connect-AzAccount -ServicePrincipal -Tenant $($endpointObject.tenantId) -Credential $psCredential -Environment $environmentName @processScope"
                $null = Connect-AzAccount `
                    -ServicePrincipal -Tenant $endpointObject.tenantId `
                    -Credential $psCredential `
                    -Environment $environmentName @processScope -WarningAction SilentlyContinue
            }
            else {
                # Provide an additional, custom, credentials-related error message. Will handle localization later
                throw ("Only SPN credential auth scheme is supported for non windows agent.") 
            }
        }
        catch {
            # Provide an additional, custom, credentials-related error message. Will handle localization later
            Write-Host "Exception is : $($_.Exception.Message)"
            throw (New-Object System.Exception("There was an error with the service principal used for the deployment.", $_.Exception))
        }

        if ($scopeLevel -eq [Scope]::Subscription.ToString()) {
            $SubscriptionId = $endpointObject.subscriptionId
            $TenantId = $endpointObject.tenantId
            $additional = @{ TenantId = $TenantId }

            Write-Host "##[command] Set-AzContext -SubscriptionId $SubscriptionId $(_formatSplat $additional)"
            $null = Set-AzContext -SubscriptionId $SubscriptionId @additional
        }
    }
    else {
        #  Provide an additional, custom, credentials-related error message. Will handle localization later
        throw ("Only SPN credential auth scheme is supported for non windows agent.")
    }
}

# Borrowed heavily from https://github.com/microsoft/azure-pipelines-tasks/blob/0be588980db6671af970076f5acf91263b127343/Tasks/AzurePowerShellV5/InitializeAz.ps1#L57
function _formatSplat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Hashtable
    )

    # Collect the parameters (names and values) in an array.
    $parameters = foreach ($key in $Hashtable.Keys) {
        $value = $Hashtable[$key]
        # If the value is a bool, format the parameter as a switch (ending with ':').
        if ($value -is [bool]) { "-$($key):" } else { "-$key" }
        $value
    }
    
    "$parameters" # String join the array.
}

# Finds the az module build agents stash in the C drive or user/share directory
function _setPipelineAzModulePath {
    if ($IsWindows) {
        $hostedAgentAzModulePath = $env:SystemDrive + "\Modules"
        $env:PSModulePath = $hostedAgentAzModulePath + ";" + $env:PSModulePath
        $env:PSModulePath = $env:PSModulePath.TrimStart(';') 
        Write-Verbose "The updated value of the PSModulePath is: $($env:PSModulePath)"
    }
    else { 
        $modules = Get-ChildItem "/usr/share/az_*" -Directory
        foreach ($module in $modules) {
            $hostedAgentAzModulePath = $module.FullName
            $env:PSModulePath = $hostedAgentAzModulePath + ":" + $env:PSModulePath
            $env:PSModulePath = $env:PSModulePath.TrimStart(':') 
        }
    }
    
}

# This is because I was having issues moving between pipelines and local testing
# of getting environment variables the old fashioned way
function Get-EnvironmentVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ArgumentCompleter( {
                param(
                    $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters
                )
                (Get-ChildItem "env:*" `
                | Where-Object { $_.Name -like "$wordToComplete*" }).Name | ForEach-Object {
                    if ($_.Contains(' ')) {
                        "'$_'"
                    }
                    else {
                        $_
                    }
                }
            })]
        [string]$Name
    )
    $var = Get-ChildItem "env:*" | Where-Object { $_.Name -eq $Name } 
    return $var.Value ?? "NA"
}

Export-ModuleMember -Function "*-*"
