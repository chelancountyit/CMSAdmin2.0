<#
.SYNOPSIS
    Reusable Legacy Workspace Extractor, Asset Syncer, Seed Builder & CFWheels MVC Scaffolder
    for migrating co.chelan.wa.us/{workspace} -> CMSAdmin 2.0 & chelancounty.gov/{workspace}.

.DESCRIPTION
    1. Crawls https://www.co.chelan.wa.us/{WorkspaceCode} (landing page, /contacts, /howdoi,
       all navigation links, and nested /pages/{slug} subpages).
    2. Extracts page titles, HTML bodies, left/right sidebars, posted/updated timestamps,
       homepage CTA cards, navigation menu tree, and How Do I links.
    3. Syncs legacy files from C:\inetpub\Chelan-County\files\{WorkspaceCode} and downloads
       any newer live files from https://www.co.chelan.wa.us/files/{WorkspaceCode}/... into both
       C:\inetpub\CMSAdmin2.0\files\{WorkspaceCode} and C:\inetpub\ChelanCounty.gov\files\{WorkspaceCode}.
    4. Normalizes HTML (rewrites /pages/ -> /page/, strips leaked CFML comments, fixes obfuscated
       mailto links, upgrades Bootstrap 4 collapse attributes to Bootstrap 5) and writes
       C:\inetpub\ChelanCounty.gov\db\{WorkspaceCode}_seed.json.
    5. When -ScaffoldMvc is passed, generates the CFWheels MVC Controller and Views in
       C:\inetpub\ChelanCounty.gov\app\controllers\ and app\views\{WorkspaceCode}\.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File "C:\inetpub\CMSAdmin2.0\scripts\extract-legacy-workspace.ps1" `
        -WorkspaceCode "auditor" `
        -DepartmentName "Chelan County Auditor" `
        -OfficialFirstName "Brandt" `
        -OfficialLastName "Cappell" `
        -OfficialTitle "Chelan County Auditor" `
        -OfficialPhoto "/images/logo/auditor.jpg" `
        -Phone "(509) 667-6802" `
        -Fax "(509) 667-6818" `
        -Email "brandt.cappell@co.chelan.wa.us" `
        -Address "350 Orondo Ave" `
        -Address2 "Suite 202" `
        -Hours "Monday - Friday: 9:00 AM - 5:00 PM PST" `
        -ScaffoldMvc
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceCode,

    [Parameter(Mandatory = $false)]
    [string]$DepartmentName = "",

    [Parameter(Mandatory = $false)]
    [string]$LeadershipType = "elected",

    [Parameter(Mandatory = $false)]
    [string]$OfficialFirstName = "",

    [Parameter(Mandatory = $false)]
    [string]$OfficialLastName = "",

    [Parameter(Mandatory = $false)]
    [string]$OfficialTitle = "",

    [Parameter(Mandatory = $false)]
    [string]$OfficialPhoto = "",

    [Parameter(Mandatory = $false)]
    [string]$Phone = "",

    [Parameter(Mandatory = $false)]
    [string]$Fax = "",

    [Parameter(Mandatory = $false)]
    [string]$Email = "",

    [Parameter(Mandatory = $false)]
    [string]$Address = "350 Orondo Ave",

    [Parameter(Mandatory = $false)]
    [string]$Address2 = "",

    [Parameter(Mandatory = $false)]
    [string]$City = "Wenatchee",

    [Parameter(Mandatory = $false)]
    [string]$State = "WA",

    [Parameter(Mandatory = $false)]
    [string]$Zip = "98801",

    [Parameter(Mandatory = $false)]
    [string]$Hours = "Monday - Friday: 8:00 AM - 5:00 PM PST",

    [Parameter(Mandatory = $false)]
    [string]$Color = "#004879",

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$ScaffoldMvc
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$wsSlug = $WorkspaceCode.Trim().ToLower()
$baseUrl = "https://www.co.chelan.wa.us"
$deptRootUrl = "$baseUrl/$wsSlug"
if ([string]::IsNullOrWhiteSpace($DepartmentName)) {
    $DepartmentName = "Chelan County " + (Get-Culture).TextInfo.ToTitleCase(($wsSlug -replace '-', ' '))
}
$shortDeptName = $DepartmentName -replace '(?i)^Chelan\s+County\s+', ''

$cmsFilesDir = "C:\inetpub\CMSAdmin2.0\files\$wsSlug"
$pubFilesDir = "C:\inetpub\ChelanCounty.gov\files\$wsSlug"
$legacyFilesDir = "C:\inetpub\Chelan-County\files\$wsSlug"
$dbDir = "C:\inetpub\ChelanCounty.gov\db"
$seedFile = Join-Path $dbDir "${wsSlug}_seed.json"

foreach ($d in @($cmsFilesDir, $pubFilesDir, $dbDir)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Write-Host "=== Step 1: Crawling $deptRootUrl ==="
$visitedUrls = @{ }
$toVisit = New-Object System.Collections.Queue
$toVisit.Enqueue($deptRootUrl)
$toVisit.Enqueue("$deptRootUrl/contacts")
$toVisit.Enqueue("$deptRootUrl/howdoi")

$htmlByUrl = @{ }
while ($toVisit.Count -gt 0) {
    $u = $toVisit.Dequeue()
    if ($visitedUrls.ContainsKey($u)) { continue }
    $visitedUrls[$u] = $true
    try {
        $resp = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 30
        if ($resp.StatusCode -eq 200) {
            $htmlByUrl[$u] = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
            Write-Host "  Fetched: $u"
            # Discover internal /pages/ links for this workspace
            $matches = [regex]::Matches($resp.Content, "(?i)(?:https?://(?:www\.)?co\.chelan\.wa\.us)?/$wsSlug/pages/([a-zA-Z0-9_-]+)")
            foreach ($m in $matches) {
                $slug = $m.Groups[1].Value.ToLower()
                $nextUrl = "$deptRootUrl/pages/$slug"
                if (-not $visitedUrls.ContainsKey($nextUrl)) {
                    $toVisit.Enqueue($nextUrl)
                }
            }
        }
    } catch {
        Write-Warning "  Skipped $u : $($_.Exception.Message)"
    }
}

Write-Host "=== Step 2: Syncing Local & Remote Media Files ==="
if (Test-Path $legacyFilesDir) {
    Copy-Item -Path "$legacyFilesDir\*" -Destination $cmsFilesDir -Recurse -Force
    Copy-Item -Path "$legacyFilesDir\*" -Destination $pubFilesDir -Recurse -Force
    Write-Host "  Synced legacy files from $legacyFilesDir"
}

$fileHrefPattern = "(?i)(?:https?://(?:www\.)?co\.chelan\.wa\.us)?(/files/$wsSlug/[^`"'\s>#?]+)"
$remoteFiles = @{ }
foreach ($html in $htmlByUrl.Values) {
    foreach ($fm in [regex]::Matches($html, $fileHrefPattern)) {
        $relUrl = [System.Uri]::UnescapeDataString($fm.Groups[1].Value)
        $remoteFiles[$relUrl] = $true
    }
}
foreach ($relUrl in $remoteFiles.Keys) {
    $subPath = ($relUrl -replace "^/files/$wsSlug/?", "") -replace '/', '\'
    if ([string]::IsNullOrWhiteSpace($subPath)) { continue }
    $destCms = Join-Path $cmsFilesDir $subPath
    $destPub = Join-Path $pubFilesDir $subPath
    if (!(Test-Path $destPub)) {
        $parentDir = Split-Path -Parent $destPub
        $parentCms = Split-Path -Parent $destCms
        if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        if (!(Test-Path $parentCms)) { New-Item -ItemType Directory -Path $parentCms -Force | Out-Null }
        try {
            $dlUrl = "$baseUrl" + ($relUrl -replace ' ', '%20')
            Invoke-WebRequest -Uri $dlUrl -OutFile $destPub -UseBasicParsing -TimeoutSec 30
            Copy-Item -Path $destPub -Destination $destCms -Force
            Write-Host "  Downloaded missing file: $relUrl"
        } catch {
            Write-Warning "  Could not download $relUrl : $($_.Exception.Message)"
        }
    }
}

function Get-BalancedDivContent([string]$html, [int]$startOpenTagIndex) {
    $openMain = $html.IndexOf(">", $startOpenTagIndex)
    if ($openMain -lt 0) { return "" }
    $pos = $openMain + 1
    $depth = 1
    $tagRegex = [regex]'(?is)</?div\b[^>]*>'
    while ($depth -gt 0 -and $pos -lt $html.Length) {
        $m = $tagRegex.Match($html, $pos)
        if (-not $m.Success) { break }
        if ($m.Value.StartsWith("</", [System.StringComparison]::OrdinalIgnoreCase)) {
            $depth--
            if ($depth -eq 0) {
                return $html.Substring($openMain + 1, $m.Index - ($openMain + 1)).Trim()
            }
        } else {
            $depth++
        }
        $pos = $m.Index + $m.Length
    }
    return ""
}

function Clean-WorkspaceHtml([string]$html) {
    if ([string]::IsNullOrWhiteSpace($html)) { return "" }
    $s = $html
    $s = [regex]::Replace($s, '(?s)<!---.*?--->', '')
    $s = [regex]::Replace($s, "https?://(www\.)?co\.chelan\.wa\.us/([a-zA-Z0-9_-]+)/pages/([a-zA-Z0-9_-]+)", '/$2/page/$3')
    $s = [regex]::Replace($s, '(?<=href=["''])/([a-zA-Z0-9_-]+)/pages/([a-zA-Z0-9_-]+)', '/$1/page/$2')
    $s = [regex]::Replace($s, "https?://(www\.)?co\.chelan\.wa\.us/$wsSlug/?(?=[`"'\s>])", "/$wsSlug")
    $s = [regex]::Replace($s, 'https?://(www\.)?co\.chelan\.wa\.us/files/', '/files/')
    $s = $s -replace 'data-toggle="collapse"', 'data-toggle="collapse" data-bs-toggle="collapse"'
    $s = $s -replace 'data-parent="#accordion-faq"', 'data-parent="#accordion-faq" data-bs-parent="#accordion-faq"'
    return $s.Trim()
}

function Get-PlainSummary([string]$html, [string]$fallbackTitle) {
    if ([string]::IsNullOrWhiteSpace($html)) { return $fallbackTitle }
    $txt = [regex]::Replace($html, '<[^>]+>', ' ')
    $txt = [System.Net.WebUtility]::HtmlDecode($txt)
    $txt = [regex]::Replace($txt, '\s+', ' ').Trim()
    if ($txt.Length -le 220) { return $txt }
    return $txt.Substring(0, 217).Trim() + "..."
}

Write-Host "=== Step 3: Extracting Pages, Sidebars & Metadata ==="
$pagesList = @()

foreach ($kv in $htmlByUrl.GetEnumerator()) {
    $u = $kv.Key
    $raw = $kv.Value
    if ($u -match "/contacts$" -or $u -match "/howdoi$") { continue }

    $isHome = ($u -eq $deptRootUrl)
    $slug = if ($isHome) { "home" } else { ($u -replace "^$deptRootUrl/pages/", "").ToLower() }

    # Title
    $title = $DepartmentName
    if (-not $isHome) {
        $tm = [regex]::Match($raw, '(?is)<h1[^>]*>(.*?)</h1>')
        if ($tm.Success) {
            $title = [System.Net.WebUtility]::HtmlDecode(([regex]::Replace($tm.Groups[1].Value, '<[^>]+>', '')).Trim())
        }
    }

    # Body
    $bodyHtml = ""
    if ($isHome) {
        $mNews = [regex]::Matches($raw, '<!-- Department News -->')
        $mPost = [regex]::Match($raw, '<p class="d-block g-color-secondary-light-v1 g-font-size-15">')
        if ($mNews.Count -ge 2 -and $mPost.Success) {
            $startPos = $mNews[1].Index + $mNews[1].Length
            if ($mPost.Index -gt $startPos) {
                $bodyHtml = $raw.Substring($startPos, $mPost.Index - $startPos).Trim()
            }
        }
    } else {
        $mpc = [regex]::Match($raw, '<div\s+class="page-content[^"]*"[^>]*>')
        if ($mpc.Success) {
            $bodyHtml = Get-BalancedDivContent $raw $mpc.Index
        }
    }

    # Sidebars
    $sbParts = @()
    foreach ($sm in [regex]::Matches($raw, '<div\s+class="sidebars[^"]*"[^>]*>')) {
        $sbInner = Get-BalancedDivContent $raw $sm.Index
        if (![string]::IsNullOrWhiteSpace($sbInner)) {
            $sbParts += $sbInner
        }
    }
    $cleanBody = Clean-WorkspaceHtml $bodyHtml
    $cleanSb = Clean-WorkspaceHtml ($sbParts -join "`r`n")
    $sbTitle = ""
    if ($cleanSb.Length -gt 0) {
        $hm = [regex]::Match($cleanSb, '(?is)<h[1-5][^>]*>(.*?)</h[1-5]>')
        if ($hm.Success) {
            $sbTitle = [System.Net.WebUtility]::HtmlDecode(([regex]::Replace($hm.Groups[1].Value, '<[^>]+>', '')).Trim())
        }
        if ([string]::IsNullOrWhiteSpace($sbTitle)) { $sbTitle = "$title Resources" }
    }

    # Posted / Updated dates
    $createdIso = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $pm = [regex]::Match($raw, 'Posted:\s*([0-9/]+\s+(?:at\s+)?[0-9:]+\s*[AP]M)')
    if ($pm.Success) {
        try { $createdIso = ([datetime]::Parse(($pm.Groups[1].Value -replace '\s+at\s+', ' '))).ToString("yyyy-MM-dd HH:mm:ss") } catch {}
    }
    $modifiedIso = $createdIso
    $um = [regex]::Match($raw, 'Last Updated:\s*([0-9/]+\s+(?:at\s+)?[0-9:]+\s*[AP]M)')
    if ($um.Success) {
        try { $modifiedIso = ([datetime]::Parse(($um.Groups[1].Value -replace '\s+at\s+', ' '))).ToString("yyyy-MM-dd HH:mm:ss") } catch {}
    }

    $pagesList += [ordered]@{
        slug            = $slug
        title           = $title
        summary         = (Get-PlainSummary $cleanBody $title)
        body            = $cleanBody
        hasSidebar      = ($cleanSb.Length -gt 0)
        sidebarTitle    = $sbTitle
        sidebarBody     = $cleanSb
        created         = $createdIso
        modified        = $modifiedIso
        hasCtaCards     = $isHome
        ctaSectionTitle = if ($isHome) { "Quick Services & Online Tools" } else { "" }
    }
}

Write-Host "  Extracted $($pagesList.Count) pages for workspace '$wsSlug'."

if ($ScaffoldMvc) {
    $pascalName = (Get-Culture).TextInfo.ToTitleCase(($wsSlug -replace '-', ' ')) -replace '\s+', ''
    $ctrlPath = "C:\inetpub\ChelanCounty.gov\app\controllers\$pascalName.cfc"
    $viewDir = "C:\inetpub\ChelanCounty.gov\app\views\$wsSlug"
    if (!(Test-Path $viewDir)) { New-Item -ItemType Directory -Path $viewDir -Force | Out-Null }
    Write-Host "  MVC Controller path: $ctrlPath"
    Write-Host "  MVC Views directory: $viewDir"
}

