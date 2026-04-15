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
    "echo VIRTUAL_ENV=`${VIRTUAL_ENV:-}"
    "if [ -f pyproject.toml ]; then echo PYPROJECT_TOML=present; fi"
    "if [ -f uv.lock ]; then echo UV_LOCK=present; fi"
    "python --version 2>&1 || true"
    "R --version 2>/dev/null | head -n 1 || true"
    "if command -v uv >/dev/null 2>&1; then uv --version; else echo uv:not-found; fi"
    "which R 2>/dev/null || true"
    "which python 2>/dev/null || true"
    "which uv 2>/dev/null || true"
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
