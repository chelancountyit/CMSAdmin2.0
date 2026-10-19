<#
.SYNOPSIS
    Chelan County CMSAdmin 2.0 — Automated Version & Build Incrementor
.DESCRIPTION
    Increments or sets the build number and semantic version in config/version.json
    and synchronizes config/settings.cfm.
.PARAMETER Build
    Explicit build number to set (e.g. -Build 2). If omitted and neither -Major nor -Minor is specified, increments current build by 1.
.PARAMETER Minor
    Explicit minor version to set (e.g. -Minor 2 -> 2.2.1). Resets build to 1.
.PARAMETER Major
    Explicit major version to set (e.g. -Major 3 -> 3.0.1). Resets build to 1.
.PARAMETER ReleaseName
    Optional release name or milestone title.
.EXAMPLE
    .\scripts\bump-version.ps1
    # Bumps build number by 1 (e.g. v2.1.1 -> v2.1.2)
.EXAMPLE
    .\scripts\bump-version.ps1 -Minor 2
    # Bumps to v2.2.1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Build = 0,

    [Parameter(Mandatory = $false)]
    [int]$Minor = -1,

    [Parameter(Mandatory = $false)]
    [int]$Major = -1,

    [string]$ReleaseName = ""
)

$rootDir = Split-Path -Path $PSScriptRoot -Parent
$versionJsonPath = Join-Path $rootDir 'config\version.json'
$settingsCfmPath = Join-Path $rootDir 'config\settings.cfm'

if (-not (Test-Path $versionJsonPath)) {
    Write-Error ('Cannot locate config/version.json at: ' + $versionJsonPath)
    exit 1
}

# 1. Read current version data
$rawJson = Get-Content -Path $versionJsonPath -Raw -Encoding UTF8
$vData = $rawJson | ConvertFrom-Json

$curMajor = [int]($vData.major)
$curMinor = [int]($vData.minor)
$curBuild = [int]($vData.build)

# 2. Determine new version values
if ($Major -ge 0) {
    $newMajor = $Major
    $newMinor = if ($Minor -ge 0) { $Minor } else { 0 }
    $newBuild = if ($Build -gt 0) { $Build } else { 1 }
} elseif ($Minor -ge 0) {
    $newMajor = $curMajor
    $newMinor = $Minor
    $newBuild = if ($Build -gt 0) { $Build } else { 1 }
} elseif ($Build -gt 0) {
    $newMajor = $curMajor
    $newMinor = $curMinor
    $newBuild = $Build
} else {
    # Default: Increment build number by 1
    $newMajor = $curMajor
    $newMinor = $curMinor
    $newBuild = $curBuild + 1
}

$newVersion = "$newMajor.$newMinor.$newBuild"
$newVersionTag = "v$newVersion"
$newBuildDisplay = "$newVersionTag (Build $newBuild)"
$newReleaseDate = (Get-Date).ToString('yyyy-MM-dd')
$newBuiltAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
$newReleaseName = if ($ReleaseName) { $ReleaseName } elseif ($vData.releaseName) { $vData.releaseName } else { "CMSAdmin $newVersionTag" }

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host '  Chelan County CMSAdmin — Version Bumper' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ('Previous: ' + $vData.versionTag + ' (Build ' + $vData.build + ')') -ForegroundColor Gray
Write-Host ('New:      ' + $newVersionTag + ' (Build ' + $newBuild + ')') -ForegroundColor Green
Write-Host ('Release:  ' + $newReleaseName) -ForegroundColor Yellow
Write-Host ('Date:     ' + $newReleaseDate) -ForegroundColor Gray
Write-Host '==================================================' -ForegroundColor Cyan

# 3. Update config/version.json
$newObj = [PSCustomObject]@{
    major       = $newMajor
    minor       = $newMinor
    build       = $newBuild
    version     = $newVersion
    versionTag  = $newVersionTag
    releaseName = $newReleaseName
    releaseDate = $newReleaseDate
    builtAt     = $newBuiltAt
    environment = $vData.environment
}

$updatedJson = $newObj | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText($versionJsonPath, $updatedJson + "`n", [System.Text.Encoding]::UTF8)
Write-Host ('[OK] Updated: ' + $versionJsonPath) -ForegroundColor Green

# 4. Synchronize config/settings.cfm
if (Test-Path $settingsCfmPath) {
    $lines = Get-Content -Path $settingsCfmPath -Encoding UTF8
    $newLines = @()
    foreach ($line in $lines) {
        if ($line -match 'set\(appMajorVersion=') {
            $newLines += "`t" + 'set(appMajorVersion=' + $newMajor + ');'
        } elseif ($line -match 'set\(appMinorVersion=') {
            $newLines += "`t" + 'set(appMinorVersion=' + $newMinor + ');'
        } elseif ($line -match 'set\(appBuildNumber=') {
            $newLines += "`t" + 'set(appBuildNumber=' + $newBuild + ');'
        } elseif ($line -match 'set\(appVersion=') {
            $newLines += "`t" + 'set(appVersion="' + $newVersion + '");'
        } elseif ($line -match 'set\(appVersionTag=') {
            $newLines += "`t" + 'set(appVersionTag="' + $newVersionTag + '");'
        } elseif ($line -match 'set\(appBuildDisplay=') {
            $newLines += "`t" + 'set(appBuildDisplay="' + $newBuildDisplay + '");'
        } else {
            $newLines += $line
        }
    }
    [System.IO.File]::WriteAllLines($settingsCfmPath, $newLines, [System.Text.Encoding]::UTF8)
    Write-Host ('[OK] Synchronized: ' + $settingsCfmPath) -ForegroundColor Green
}

Write-Host ('Version tracking successfully updated to ' + $newVersionTag + ' (Build ' + $newBuild + ').') -ForegroundColor Green
Write-Host 'Remember to reload the framework (e.g. /login?reload=true&password=chelancms) to clear in-memory cache.' -ForegroundColor Yellow

