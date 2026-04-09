[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Profile,

    [string]$Node,

    [int]$Cores,

    [string[]]$Vars
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$invokeScript = Join-Path $PSScriptRoot "invoke-remote-task.ps1"
$probeCommand = @(
    "pwd"
    "hostname"
    "whoami"
    "python --version || true"
    "R --version 2>/dev/null | head -n 1 || true"
) -join "`n"

$arguments = @{
    Profile = $Profile
    Command = $probeCommand
}

if ($PSBoundParameters.ContainsKey("Node")) {
    $arguments["Node"] = $Node
}

if ($PSBoundParameters.ContainsKey("Cores")) {
    $arguments["Cores"] = $Cores
}

if ($Vars) {
    $arguments["Vars"] = $Vars
}

& $invokeScript @arguments
exit $LASTEXITCODE
