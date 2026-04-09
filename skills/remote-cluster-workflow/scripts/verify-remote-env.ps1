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
    "echo CONDA_DEFAULT_ENV=`${CONDA_DEFAULT_ENV:-}"
    "python --version 2>&1 || true"
    "R --version 2>/dev/null | head -n 1 || true"
    "which R 2>/dev/null || true"
    "which python 2>/dev/null || true"
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
