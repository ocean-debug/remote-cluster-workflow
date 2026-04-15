[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Profile,

    [Parameter(Mandatory = $true)]
    [string]$Command,

    [string]$Node,

    [int]$Cores,

    [string[]]$Vars,

    [switch]$SkipEnvironment,

    [switch]$SkipWorkdir,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-BashSingleQuoted {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) {
        return "''"
    }

    return "'" + ($Text -replace "'", "'""'""'") + "'"
}

function ConvertTo-StringArray {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [string]) {
        return @([string]$Value)
    }

    return @($Value | ForEach-Object { [string]$_ })
}

function Parse-KeyValuePairs {
    param([string[]]$Pairs)

    $result = [ordered]@{}
    foreach ($pair in $Pairs) {
        if ([string]::IsNullOrWhiteSpace($pair)) {
            continue
        }

        $index = $pair.IndexOf("=")
        if ($index -lt 1) {
            throw "Invalid -Vars entry '$pair'. Use key=value."
        }

        $key = $pair.Substring(0, $index)
        $value = $pair.Substring($index + 1)
        $result[$key] = $value
    }

    return $result
}

function Expand-Template {
    param(
        [string]$Template,
        [hashtable]$Values
    )

    $expanded = $Template
    foreach ($key in $Values.Keys) {
        $pattern = "\{" + [regex]::Escape([string]$key) + "\}"
        $replacement = [string]$Values[$key]
        $expanded = [regex]::Replace($expanded, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{
            param($match)
            return $replacement
        })
    }

    $remaining = [regex]::Matches($expanded, "\{[A-Za-z0-9_-]+\}")
    if ($remaining.Count -gt 0) {
        $names = $remaining | ForEach-Object { $_.Value } | Select-Object -Unique
        throw "Unresolved placeholders in resource.template: $($names -join ', ')"
    }

    return $expanded
}

if (-not (Test-Path -LiteralPath $Profile)) {
    throw "Profile not found: $Profile"
}

$profileData = Get-Content -LiteralPath $Profile -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace([string]$profileData.sshTarget)) {
    throw "Profile is missing sshTarget."
}

if ([string]::IsNullOrWhiteSpace([string]$profileData.remoteWorkdir)) {
    throw "Profile is missing remoteWorkdir."
}

$profileName = if ([string]::IsNullOrWhiteSpace([string]$profileData.profileName)) { [System.IO.Path]::GetFileNameWithoutExtension($Profile) } else { [string]$profileData.profileName }
$remoteShell = if ([string]::IsNullOrWhiteSpace([string]$profileData.remoteShell)) { "bash" } else { [string]$profileData.remoteShell }
$sshOptions = ConvertTo-StringArray $profileData.sshOptions
$preCommands = ConvertTo-StringArray $profileData.preCommands
$activateCommand = ""
if ($null -ne $profileData.environment -and -not [string]::IsNullOrWhiteSpace([string]$profileData.environment.activate)) {
    $activateCommand = [string]$profileData.environment.activate
}

$scriptParts = New-Object System.Collections.Generic.List[string]
$scriptParts.Add("set -e")

foreach ($line in $preCommands) {
    if (-not [string]::IsNullOrWhiteSpace($line)) {
        $scriptParts.Add($line)
    }
}

if (-not $SkipWorkdir) {
    $scriptParts.Add("cd $(ConvertTo-BashSingleQuoted ([string]$profileData.remoteWorkdir))")
}

if (-not $SkipEnvironment -and -not [string]::IsNullOrWhiteSpace($activateCommand)) {
    $scriptParts.Add($activateCommand)
}

$scriptParts.Add($Command)
$joinedScript = [string]::Join("`n", $scriptParts)
$joinedScriptWithHeader = "#!/bin/bash`n" + $joinedScript + "`n"

$template = "$remoteShell -lc {command_quoted}"
$resourceDefaults = [ordered]@{}
if ($null -ne $profileData.resource) {
    if (-not [string]::IsNullOrWhiteSpace([string]$profileData.resource.template)) {
        $template = [string]$profileData.resource.template
    }

    if ($null -ne $profileData.resource.defaults) {
        $profileData.resource.defaults.PSObject.Properties | ForEach-Object {
            $resourceDefaults[$_.Name] = [string]$_.Value
        }
    }
}

$templateValues = [ordered]@{}
foreach ($key in $resourceDefaults.Keys) {
    $templateValues[$key] = [string]$resourceDefaults[$key]
}

if ($PSBoundParameters.ContainsKey("Node")) {
    $templateValues["node"] = $Node
}

if ($PSBoundParameters.ContainsKey("Cores")) {
    $templateValues["cores"] = [string]$Cores
}

$extraValues = Parse-KeyValuePairs $Vars
foreach ($key in $extraValues.Keys) {
    $templateValues[$key] = [string]$extraValues[$key]
}

$templateValues["command"] = $joinedScript
$templateValues["command_quoted"] = ConvertTo-BashSingleQuoted $joinedScript
$templateValues["script"] = $joinedScriptWithHeader
$templateValues["script_quoted"] = ConvertTo-BashSingleQuoted $joinedScriptWithHeader
$templateValues["workdir"] = [string]$profileData.remoteWorkdir
$templateValues["workdir_quoted"] = ConvertTo-BashSingleQuoted ([string]$profileData.remoteWorkdir)
$templateValues["profile"] = $profileName
$templateValues["profile_quoted"] = ConvertTo-BashSingleQuoted $profileName

$remoteCommand = Expand-Template -Template $template -Values $templateValues

$sshArgs = @()
$sshArgs += $sshOptions
$sshArgs += [string]$profileData.sshTarget
$sshArgs += $remoteCommand

if ($DryRun) {
    Write-Output ("Profile: " + $profileName)
    Write-Output ("SSH target: " + [string]$profileData.sshTarget)
    Write-Output ("Remote command: " + $remoteCommand)
    exit 0
}

Write-Output ("[remote-cluster-workflow] profile=" + $profileName)
Write-Output ("[remote-cluster-workflow] target=" + [string]$profileData.sshTarget)

& ssh @sshArgs
exit $LASTEXITCODE
