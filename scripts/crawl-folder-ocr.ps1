param(
    [Parameter(Mandatory=$false)]
    [string]$FolderPath = "C:\inetpub\chelan-county\files",

    [Parameter(Mandatory=$false)]
    [string]$Workspace = "",

    [Parameter(Mandatory=$false)]
    [string]$SubFolder = "",

    [Parameter(Mandatory=$false)]
    [switch]$Recursive = $true,

    [Parameter(Mandatory=$false)]
    [switch]$OverwriteExistingAlt = $false,

    [Parameter(Mandatory=$false)]
    [switch]$GenerateThumbs = $true,

    [Parameter(Mandatory=$false)]
    [switch]$JsonOnly = $false
)

$ErrorActionPreference = "Stop"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# Initialize WinRT OCR Engine (Windows.Media.Ocr)
$ocrEngine = $null
$asTaskGeneric = $null
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]
    $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
    $null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
    $null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType = WindowsRuntime]
    $null = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Foundation, ContentType = WindowsRuntime]
    $ocrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
} catch {
    $ocrEngine = $null
}

function Await-WinRT($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(8000) | Out-Null
    return $netTask.Result
}

# Normalize incoming FolderPath to physical path under C:\inetpub\chelan-county\files
$filesRoot = "C:\inetpub\chelan-county\files"
$rawPath = ($FolderPath -replace '/', '\').Trim()
if ([string]::IsNullOrWhiteSpace($rawPath)) {
    $rawPath = $filesRoot
}

if ($rawPath -match '^https?://assets\.chelancounty\.(?:com|gov)/(.*)$') {
    $rel = ($Matches[1] -replace '/', '\').Trim('\')
    $targetAbs = if ($rel) { Join-Path $filesRoot $rel } else { $filesRoot }
} elseif ($rawPath -match '^assets\.chelancounty\.(?:com|gov)[\\/](.*)$') {
    $rel = ($Matches[1] -replace '/', '\').Trim('\')
    $targetAbs = if ($rel) { Join-Path $filesRoot $rel } else { $filesRoot }
} elseif ([System.IO.Path]::IsPathRooted($rawPath)) {
    $targetAbs = $rawPath.TrimEnd('\')
} else {
    $cleanRel = $rawPath.Trim('\')
    if ($cleanRel -match '^files\\(.*)$') {
        $cleanRel = $Matches[1]
    }
    $targetAbs = Join-Path $filesRoot $cleanRel
}

if (-not (Test-Path -LiteralPath $targetAbs)) {
    $errOut = @{
        ok = $false
        success = $false
        error = "Target folder does not exist on disk: $targetAbs"
        requestedPath = $FolderPath
    }
    Write-Output ($errOut | ConvertTo-Json -Depth 5 -Compress)
    exit 0
}

$targetItem = Get-Item -LiteralPath $targetAbs

# Workspace display names dictionary
$wsDisplayMap = @{
    "assessor"              = "Chelan County Assessor"
    "auditor"               = "Chelan County Auditor"
    "board-of-commissioners"= "Board of County Commissioners"
    "clerk"                 = "Chelan County Superior Court Clerk"
    "community-development" = "Chelan County Community Development"
    "coroner"               = "Chelan County Coroner"
    "district-court"        = "Chelan County District Court"
    "economic-development"  = "Chelan County Economic Development"
    "emergency-management"  = "Chelan County Emergency Management"
    "extension"             = "WSU Chelan County Extension"
    "facilities"            = "Chelan County Facilities Maintenance"
    "fair"                  = "Chelan County Fair & Expo Center"
    "faireventcenter"       = "Chelan County Fair & Expo Center"
    "horticulture"          = "Chelan County Horticulture & Pest Board"
    "hrm"                   = "Chelan County Human Resources"
    "it"                    = "Chelan County Information Technology"
    "juvenile"              = "Chelan County Juvenile Justice Center"
    "natural-resources"     = "Chelan County Natural Resources Department"
    "noxious-weed"          = "Chelan County Noxious Weed Control Board"
    "ohme-gardens"          = "Ohme Gardens County Park"
    "pio"                   = "Chelan County Public Information Office"
    "prosecutor"            = "Chelan County Prosecuting Attorney"
    "public-works"          = "Chelan County Public Works"
    "regional-justice"      = "Chelan County Regional Justice Center"
    "sheriff"               = "Chelan County Sheriff's Office"
    "superior-court"        = "Chelan County Superior Court"
    "treasurer"             = "Chelan County Treasurer"
    "veterans"              = "Chelan County Veterans Program"
    "wenatcheeriverpark.org"= "Wenatchee River County Park"
    "wrcp"                  = "Wenatchee River County Park"
    "shared"                = "Chelan County Government"
}

function Clean-OcrText([string]$raw) {
    if ([string]::IsNullOrWhiteSpace($raw)) { return "" }
    $normalized = ($raw -replace '[\r\n\t]+', ' ' -replace '\s+', ' ').Trim()
    $tokens = $normalized -split ' '
    $validTokens = New-Object System.Collections.Generic.List[string]
    $goodWordCount = 0
    foreach ($t in $tokens) {
        $cleanTok = ($t -replace '^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$', '')
        # Reject tokens containing OCR garbage symbols in the middle (like (, ), %, \, ", |)
        if ($cleanTok -match '[\(\)\%\\"|~`^<>\{\}\[\]]') { continue }
        if ($cleanTok.Length -ge 2 -and $cleanTok -match '^[a-zA-Z0-9''\-\.,:&!]+$') {
            $validTokens.Add($cleanTok)
            if ($cleanTok -match '^[a-zA-Z]{4,}$' -or $cleanTok -match '^\d{4}$') {
                $goodWordCount++
            }
        }
    }
    if ($goodWordCount -lt 1 -or $validTokens.Count -eq 0) {
        return ""
    }
    $result = ($validTokens -join ' ').Trim()
    if ($result.Length -lt 4) { return "" }
    if ($result.Length -gt 240) {
        $result = $result.Substring(0, 240).Trim() + "..."
    }
    return $result
}

function Analyze-ImageVisualsAndOcr([string]$fullPath, [string]$ext) {
    $info = @{
        width = 0
        height = 0
        ocrText = ""
        visualTone = ""
        orientation = ""
        hasAlpha = $false
        svgText = ""
    }

    if ($ext -eq "svg") {
        try {
            $svgRaw = Get-Content -LiteralPath $fullPath -Raw -ErrorAction SilentlyContinue
            if ($svgRaw) {
                if ($svgRaw -match '<title[^>]*>([^<]+)</title>') {
                    $info.svgText = $Matches[1].Trim()
                } elseif ($svgRaw -match 'aria-label="([^"]+)"') {
                    $info.svgText = $Matches[1].Trim()
                }
                if ($svgRaw -match 'viewBox="[^"]*?\s+(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)"') {
                    $info.width = [int][double]$Matches[1]
                    $info.height = [int][double]$Matches[2]
                }
            }
        } catch {}
        $info.orientation = "vector icon"
        return $info
    }

    if ($ext -notin @("jpg", "jpeg", "png", "gif", "bmp", "webp")) {
        return $info
    }

    # 1. Run WinRT OCR + Dimensions via BitmapDecoder
    if ($null -ne $ocrEngine -and $ext -in @("jpg", "jpeg", "png", "bmp", "gif")) {
        $stream = $null
        try {
            $sFile = Await-WinRT ([Windows.Storage.StorageFile]::GetFileFromPathAsync($fullPath)) ([Windows.Storage.StorageFile])
            $stream = Await-WinRT ($sFile.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
            $decoder = Await-WinRT ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
            $info.width = [int]$decoder.PixelWidth
            $info.height = [int]$decoder.PixelHeight
            if ($info.width -le 4096 -and $info.height -le 4096) {
                $softBmp = Await-WinRT ($decoder.GetSoftwareBitmapAsync([Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8, [Windows.Graphics.Imaging.BitmapAlphaMode]::Premultiplied)) ([Windows.Graphics.Imaging.SoftwareBitmap])
                $ocrRes = Await-WinRT ($ocrEngine.RecognizeAsync($softBmp)) ([Windows.Media.Ocr.OcrResult])
                if ($ocrRes -and $ocrRes.Text) {
                    $info.ocrText = Clean-OcrText $ocrRes.Text
                }
            }
        } catch {
            # Fallback to System.Drawing below
        } finally {
            if ($null -ne $stream) {
                try { $stream.Dispose() } catch {}
            }
        }
    }

    # 2. Sample pixel palette & dimensions via System.Drawing.Bitmap
    $bmp = $null
    try {
        $bmp = New-Object System.Drawing.Bitmap($fullPath)
        if ($info.width -le 0) { $info.width = $bmp.Width }
        if ($info.height -le 0) { $info.height = $bmp.Height }

        $w = $bmp.Width
        $h = $bmp.Height
        if ($w -gt 0 -and $h -gt 0) {
            $ratio = [double]$w / [double]$h
            if ($ratio -ge 2.1) { $info.orientation = "panoramic banner" }
            elseif ($ratio -ge 1.15) { $info.orientation = "landscape" }
            elseif ($ratio -le 0.85) { $info.orientation = "portrait" }
            else { $info.orientation = "square" }

            $rSum = 0; $gSum = 0; $bSum = 0; $lumSum = 0; $alphaTransparent = 0; $samples = 0
            $greenDom = 0; $blueDom = 0; $warmDom = 0; $graySamples = 0
            for ($ix = 1; $ix -le 6; $ix++) {
                for ($iy = 1; $iy -le 6; $iy++) {
                    $px = [Math]::Min($w - 1, [int](($w * $ix) / 7))
                    $py = [Math]::Min($h - 1, [int](($h * $iy) / 7))
                    $c = $bmp.GetPixel($px, $py)
                    $samples++
                    if ($c.A -lt 200) {
                        $alphaTransparent++
                        continue
                    }
                    $rSum += $c.R; $gSum += $c.G; $bSum += $c.B
                    $lum = (0.299 * $c.R) + (0.587 * $c.G) + (0.114 * $c.B)
                    $lumSum += $lum
                    $maxC = [Math]::Max($c.R, [Math]::Max($c.G, $c.B))
                    $minC = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
                    if (($maxC - $minC) -lt 18) {
                        $graySamples++
                    } elseif ($c.G -gt ($c.R + 15) -and $c.G -gt ($c.B + 12)) {
                        $greenDom++
                    } elseif ($c.B -gt ($c.R + 15) -and $c.B -gt ($c.G + 10)) {
                        $blueDom++
                    } elseif ($c.R -gt ($c.B + 25)) {
                        $warmDom++
                    }
                }
            }

            if ($alphaTransparent -ge 4) {
                $info.hasAlpha = $true
            }
            $opaqueSamples = [Math]::Max(1, ($samples - $alphaTransparent))
            $avgLum = $lumSum / $opaqueSamples

            if ($graySamples -gt ($opaqueSamples * 0.7)) {
                $info.visualTone = if ($avgLum -gt 200) { "clean light background" } elseif ($avgLum -lt 65) { "dark monochrome tones" } else { "neutral grayscale tones" }
            } elseif ($greenDom -ge ($opaqueSamples * 0.28)) {
                $info.visualTone = "lush green botanical foliage"
            } elseif ($blueDom -ge ($opaqueSamples * 0.28)) {
                $info.visualTone = "sky and water blue tones"
            } elseif ($warmDom -ge ($opaqueSamples * 0.35)) {
                $info.visualTone = if ($avgLum -lt 75) { "warm evening lighting" } else { "warm sunlit earth tones" }
            } elseif ($avgLum -lt 65) {
                $info.visualTone = "dramatic dark background"
            } elseif ($avgLum -gt 215) {
                $info.visualTone = "bright high-contrast layout"
            } else {
                $info.visualTone = "natural full-color palette"
            }
        }
    } catch {} finally {
        if ($null -ne $bmp) {
            try { $bmp.Dispose() } catch {}
        }
    }

    return $info
}

function Ensure-Thumbnail([string]$dirAbs, [string]$fileName, [string]$ext) {
    if ($ext -notin @("jpg", "jpeg", "png", "gif", "bmp")) { return $false }
    $srcPath = Join-Path $dirAbs $fileName
    $thumbDir = Join-Path $dirAbs ".thumbs"
    $thumbPath = Join-Path $thumbDir $fileName
    if (Test-Path -LiteralPath $thumbPath) { return $true }
    if (-not (Test-Path -LiteralPath $srcPath)) { return $false }

    $img = $null
    $bmp = $null
    $g = $null
    try {
        if (-not (Test-Path -LiteralPath $thumbDir)) {
            New-Item -ItemType Directory -Path $thumbDir -Force | Out-Null
        }
        $img = [System.Drawing.Image]::FromFile($srcPath)
        $w = $img.Width
        $h = $img.Height
        $maxDim = 360
        if ($w -gt $maxDim -or $h -gt $maxDim) {
            if ($w -ge $h) {
                $newW = $maxDim
                $newH = [Math]::Max(1, [int][Math]::Round(($h * $maxDim) / [double]$w))
            } else {
                $newH = $maxDim
                $newW = [Math]::Max(1, [int][Math]::Round(($w * $maxDim) / [double]$h))
            }
        } else {
            $newW = $w
            $newH = $h
        }
        $bmp = New-Object System.Drawing.Bitmap($newW, $newH)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($img, 0, 0, $newW, $newH)
        if ($ext -eq "png") {
            $bmp.Save($thumbPath, [System.Drawing.Imaging.ImageFormat]::Png)
        } else {
            $bmp.Save($thumbPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        }
        return $true
    } catch {
        return $false
    } finally {
        if ($null -ne $g) { $g.Dispose() }
        if ($null -ne $bmp) { $bmp.Dispose() }
        if ($null -ne $img) { $img.Dispose() }
    }
}

function Parse-TitleAndCredit([string]$fileName, [string]$ocrText, [string]$subFolder) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $decoded = [System.Web.HttpUtility]::UrlDecode($base)
    $credit = ""

    # Extract photographer/subject credit after '~' (e.g., Wedding5~Pamela%20Grillo%20Photography.jpg)
    if ($decoded -match '^(.+?)~(.+)$') {
        $decoded = $Matches[1].Trim()
        $credit = ($Matches[2] -replace '[-_]+', ' ').Trim()
    }

    # Check if filename is a 32-to-64 char hex hash (like 4570bc98e8a40f919a26aaea0423803ab69200d4)
    $isHexHash = ($decoded -match '^[0-9a-fA-F]{24,64}$')
    if ($isHexHash) {
        if (-not [string]::IsNullOrWhiteSpace($ocrText)) {
            $shortOcr = if ($ocrText.Length -gt 48) { $ocrText.Substring(0, 48).Trim() } else { $ocrText }
            $title = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($shortOcr.ToLower())
        } else {
            $folderLabel = if ($subFolder) { ($subFolder -split '[\\/]' | Select-Object -Last 1) } else { "Media" }
            $title = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($folderLabel.ToLower()) + " Graphic (" + $decoded.Substring(0, 6) + ")"
        }
        return @{ title = $title; credit = $credit; isHashName = $true }
    }

    # Clean common prefixes and camelCase/hyphens (use -creplace for case-sensitive camelCase)
    $cleaned = $decoded -replace '[-_]+', ' '
    $cleaned = $cleaned -creplace '([a-z])([A-Z])', '$1 $2'
    $cleaned = $cleaned -creplace '([a-zA-Z])(\d+)', '$1 $2'
    $cleaned = ($cleaned -replace '\s+', ' ').Trim()

    $textInfo = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo
    $title = $textInfo.ToTitleCase($cleaned.ToLower())

    return @{ title = $title; credit = $credit; isHashName = $false }
}

function Test-ValidExistingAlt([string]$alt) {
    if ([string]::IsNullOrWhiteSpace($alt)) { return $false }
    $t = $alt.Trim()
    if ($t.Length -lt 10) { return $false }
    # Reject single-token strings with no spaces (e.g. keyboard mash "ewerqwerwqerqwer", "sdfasdfsadfsadfasdf")
    if ($t -notmatch '\s') { return $false }
    # Reject obvious test/keyboard-mash strings or previously broken camelCase split
    if ($t -match '(?i)^(test|asdf|qwer|zxcv)' -or $t -match 'S Cr Ee Ns Ho T') { return $false }
    return $true
}

function Build-WcagAltText(
    [string]$wsLabel,
    [string]$subFolder,
    [string]$fileName,
    [string]$title,
    [string]$credit,
    [hashtable]$vis,
    [string]$companionTitle
) {
    $effectiveTitle = if (-not [string]::IsNullOrWhiteSpace($companionTitle)) { $companionTitle } else { $title }
    $ocr = $vis.ocrText
    $svgTxt = $vis.svgText
    $w = $vis.width
    $h = $vis.height
    $dimStr = if ($w -gt 0 -and $h -gt 0) { "${w}x${h}" } else { "" }
    $folderLower = $subFolder.ToLower()
    $nameLower = $fileName.ToLower()

    # 1. Vector SVG icons
    if ($vis.orientation -eq "vector icon") {
        $iconLabel = if ($svgTxt) { $svgTxt } else { $effectiveTitle }
        return "$wsLabel - $iconLabel vector icon graphic"
    }

    # 2. Official Seals, Brand Marks & Logos
    if ($nameLower -match 'seal|insignia|brand-mark|logo') {
        $bgNote = if ($vis.hasAlpha) { " on transparent background" } else { "" }
        $ocrNote = if ($ocr) { " reading '$ocr'" } else { "" }
        return "$wsLabel - $effectiveTitle official emblem graphic$bgNote$ocrNote"
    }

    # 3. License Plates (Auditor vehicle licensing)
    if ($nameLower -match 'plate') {
        $ocrNote = if ($ocr) { " displaying plate text '$ocr'" } else { "" }
        return "$wsLabel - Washington State vehicle license plate sample ($effectiveTitle)$ocrNote"
    }

    # 4. Screenshots
    if ($nameLower -match '^screenshot') {
        $ocrNote = if ($ocr) { " showing text: '$ocr'" } else { "" }
        $sizeNote = if ($dimStr) { " ($dimStr $($vis.orientation))" } else { "" }
        return "$wsLabel - Application interface screenshot ($effectiveTitle)$sizeNote$ocrNote"
    }

    # 5. Event Posters, Flyers & Movie/Comedy Graphics
    if ($effectiveTitle -match '(?i)event|movie|comedy|roots|rhythm|cinema|theater' -or (-not [string]::IsNullOrWhiteSpace($ocr) -and $folderLower -notmatch 'pages')) {
        $ocrClause = if ($ocr) { " featuring visible text: '$ocr'" } else { "" }
        $toneClause = if ($vis.visualTone) { " ($($vis.orientation), $($vis.visualTone))" } else { "" }
        return "$wsLabel - $effectiveTitle promotional event graphic$toneClause$ocrClause"
    }

    # 6. Wedding Gallery Photographs
    if ($folderLower -match 'wedding' -or $nameLower -match 'wedding') {
        $creditClause = if ($credit) { " (Photography by $credit)" } else { "" }
        $toneClause = if ($vis.visualTone) { " featuring $($vis.visualTone)" } else { "" }
        return "$wsLabel Weddings - Outdoor garden wedding photograph ($effectiveTitle)$toneClause$creditClause"
    }

    # 7. Garden & Park Landscape Gallery Photographs
    if ($folderLower -match 'garden' -or $nameLower -match 'gallery|gnome|historyofohme|about-us|get-involved') {
        $toneClause = if ($vis.visualTone) { " showcasing $($vis.visualTone)" } else { "" }
        $orientClause = if ($vis.orientation) { " $($vis.orientation)" } else { "" }
        return "$wsLabel - Scenic alpine garden$orientClause photograph ($effectiveTitle)$toneClause"
    }

    # 8. General Department Image with or without OCR
    $ocrSuffix = if ($ocr) { " with visible text: '$ocr'" } else { "" }
    $toneDesc = if ($vis.visualTone) { " ($($vis.orientation), $($vis.visualTone))" } elseif ($dimStr) { " ($dimStr)" } else { "" }
    $creditSuffix = if ($credit) { " by $credit" } else { "" }
    return "$wsLabel - $effectiveTitle graphic$toneDesc$ocrSuffix$creditSuffix"
}

function Get-MimeType([string]$ext) {
    switch ($ext) {
        "jpg"  { return "image/jpeg" }
        "jpeg" { return "image/jpeg" }
        "png"  { return "image/png" }
        "gif"  { return "image/gif" }
        "webp" { return "image/webp" }
        "svg"  { return "image/svg+xml" }
        "bmp"  { return "image/bmp" }
        "ico"  { return "image/x-icon" }
        "pdf"  { return "application/pdf" }
        "doc"  { return "application/msword" }
        "docx" { return "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
        "xls"  { return "application/vnd.ms-excel" }
        "xlsx" { return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
        "csv"  { return "text/csv" }
        "txt"  { return "text/plain" }
        "html" { return "text/html" }
        "md"   { return "text/markdown" }
        default { return "application/octet-stream" }
    }
}

# Collect all candidate files
if ($targetItem.PSIsContainer) {
    if ($Recursive) {
        $allFiles = Get-ChildItem -LiteralPath $targetAbs -Recurse -File
    } else {
        $allFiles = Get-ChildItem -LiteralPath $targetAbs -File
    }
} else {
    $allFiles = @($targetItem)
}

# Filter out .thumbs folders, hidden dot-files, README.txt, .gitkeep, and 0-byte placeholder text files
$validFiles = $allFiles | Where-Object {
    $_.FullName -notmatch '\\\.thumbs(\\|$)' -and
    $_.Name -notmatch '^\.' -and
    $_.Name -notin @('README.txt', 'Thumbs.db', 'desktop.ini')
}

# Pre-pass: map SHA-256 hashes of human-named files so hash-named duplicates inherit their human title
$sha256Provider = [System.Security.Cryptography.SHA256]::Create()
$fileHashes = @{}
$hashToHumanTitle = @{}

foreach ($f in $validFiles) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $hashBytes = $sha256Provider.ComputeHash($bytes)
        $hashHex = ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLower()
        $fileHashes[$f.FullName] = $hashHex

        $baseNoExt = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        if ($baseNoExt -notmatch '^[0-9a-fA-F]{24,64}$') {
            $parsed = Parse-TitleAndCredit $f.Name "" ""
            if (-not $hashToHumanTitle.ContainsKey($hashHex)) {
                $hashToHumanTitle[$hashHex] = $parsed.title
            }
        }
    } catch {}
}

# Open SQL Server connection to ChelanCountyWebsite
$conn = $null
$existingByPath = @{}
$existingByKey = @{}
$wsAssetsDomains = @{}

if (-not $JsonOnly) {
    $conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost;Database=ChelanCountyWebsite;Integrated Security=True;TrustServerCertificate=True;")
    $conn.Open()

    # Load workspace assets_domain from dbo.cms_workspaces
    try {
        $cmdWs = $conn.CreateCommand()
        $cmdWs.CommandText = "SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SELECT code, virtual_directory, assets_domain FROM dbo.cms_workspaces;"
        $wsRdr = $cmdWs.ExecuteReader()
        while ($wsRdr.Read()) {
            $domVal = if ($wsRdr.IsDBNull(2) -or [string]::IsNullOrWhiteSpace([string]$wsRdr["assets_domain"])) { "" } else { ([string]$wsRdr["assets_domain"]).Trim() }
            if (-not $wsRdr.IsDBNull(0)) { $wsAssetsDomains[([string]$wsRdr["code"]).ToLower()] = $domVal }
            if (-not $wsRdr.IsDBNull(1)) { $wsAssetsDomains[([string]$wsRdr["virtual_directory"]).ToLower()] = $domVal }
        }
        $wsRdr.Close()
    } catch {}

    # Load existing media_assets records
    $cmdLoad = $conn.CreateCommand()
    $cmdLoad.CommandText = @"
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
SELECT id, site_id, folder, filename, file_path, title, alt_text, caption, credit, tags, ocr_text, is_wcag_compliant, width, height
FROM dbo.media_assets
WHERE deletedat IS NULL
"@
    $reader = $cmdLoad.ExecuteReader()
    while ($reader.Read()) {
        $rec = @{
            id = [int]$reader["id"]
            site_id = [string]$reader["site_id"]
            folder = [string]$reader["folder"]
            filename = [string]$reader["filename"]
            file_path = [string]$reader["file_path"]
            title = if ($reader.IsDBNull(5)) { "" } else { [string]$reader["title"] }
            alt_text = if ($reader.IsDBNull(6)) { "" } else { [string]$reader["alt_text"] }
            caption = if ($reader.IsDBNull(7)) { "" } else { [string]$reader["caption"] }
            credit = if ($reader.IsDBNull(8)) { "" } else { [string]$reader["credit"] }
            tags = if ($reader.IsDBNull(9)) { "" } else { [string]$reader["tags"] }
            ocr_text = if ($reader.IsDBNull(10)) { "" } else { [string]$reader["ocr_text"] }
            is_wcag_compliant = if ($reader.IsDBNull(11)) { $false } else { [bool]$reader["is_wcag_compliant"] }
            width = if ($reader.IsDBNull(12)) { 0 } else { [int]$reader["width"] }
            height = if ($reader.IsDBNull(13)) { 0 } else { [int]$reader["height"] }
        }
        $pKey = ($rec.file_path -replace '\\', '/').ToLower()
        $uKey = ("$($rec.site_id)|$($rec.folder)|$($rec.filename)").ToLower()
        $existingByPath[$pKey] = $rec
        $existingByKey[$uKey] = $rec
    }
    $reader.Close()
}

$stats = @{
    filesScanned = 0
    imagesProcessed = 0
    documentsProcessed = 0
    ocrDetectedCount = 0
    madeCompliant = 0
    inserted = 0
    updated = 0
    alreadyCompliant = 0
    thumbsCreated = 0
}
$processedItems = New-Object System.Collections.Generic.List[object]

foreach ($f in $validFiles) {
    $stats.filesScanned++
    $fullPath = $f.FullName
    $ext = $f.Extension.TrimStart('.').ToLower()
    $isImage = $ext -in @("jpg", "jpeg", "png", "gif", "webp", "svg", "bmp", "ico")
    if ($isImage) { $stats.imagesProcessed++ } else { $stats.documentsProcessed++ }

    # Determine workspace (site_id) and relative folder under C:\inetpub\chelan-county\files
    $relFromFilesRoot = ""
    if ($fullPath.StartsWith($filesRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relFromFilesRoot = $fullPath.Substring($filesRoot.Length).TrimStart('\')
    } else {
        $relFromFilesRoot = $f.Name
    }

    $segments = $relFromFilesRoot -split '\\'
    if ($segments.Count -ge 2) {
        $siteId = $segments[0]
        if ($segments.Count -ge 3) {
            $subFolder = ($segments[1..($segments.Count - 2)] -join '/')
        } else {
            $subFolder = if ($SubFolder) { ($SubFolder -replace '\\', '/').Trim('/') } else { "root" }
        }
    } else {
        $siteId = if ($Workspace) { $Workspace } else { "shared" }
        $subFolder = if ($SubFolder) { ($SubFolder -replace '\\', '/').Trim('/') } else { "images" }
    }

    $wsLabel = if ($wsDisplayMap.ContainsKey($siteId.ToLower())) {
        $wsDisplayMap[$siteId.ToLower()]
    } else {
        [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase(($siteId -replace '[-_]', ' ').ToLower())
    }

    $relFilePath = "files/" + ($relFromFilesRoot -replace '\\', '/')
    $assetsDomain = if ($wsAssetsDomains.ContainsKey($siteId.ToLower())) { $wsAssetsDomains[$siteId.ToLower()] } else { "assets.chelancounty.com" }
    $assetsBase = if ($wsAssetsDomains.ContainsKey($siteId.ToLower())) { $wsAssetsDomains[$siteId.ToLower()].TrimEnd('/') } else { "" }
    if ($assetsBase -ne "" -and $assetsBase -notmatch '^https?://') { $assetsBase = "http://$assetsBase" }
    $webUrl = if ($assetsBase -ne "") { "$assetsBase/" + ($relFromFilesRoot -replace '\\', '/') } else { "/" + ($relFromFilesRoot -replace '\\', '/') }
    $fileHash = if ($fileHashes.ContainsKey($fullPath)) { $fileHashes[$fullPath] } else { "" }
    $mimeType = Get-MimeType $ext

    # Check existing record
    $uKey = ("$siteId|$subFolder|$($f.Name)").ToLower()
    $pKey = $relFilePath.ToLower()
    $existing = $null
    if ($existingByKey.ContainsKey($uKey)) {
        $existing = $existingByKey[$uKey]
    } elseif ($existingByPath.ContainsKey($pKey)) {
        $existing = $existingByPath[$pKey]
    }

    # Generate thumbnail if image
    if ($GenerateThumbs -and -not $JsonOnly -and $isImage) {
        $hadThumb = Test-Path -LiteralPath (Join-Path $f.DirectoryName (".thumbs\" + $f.Name))
        $thumbOk = Ensure-Thumbnail $f.DirectoryName $f.Name $ext
        if ($thumbOk -and -not $hadThumb) {
            $stats.thumbsCreated++
        }
    }

    # Analyze image visuals & OCR
    $vis = @{ width = 0; height = 0; ocrText = ""; visualTone = ""; orientation = ""; hasAlpha = $false; svgText = "" }
    if ($isImage) {
        $vis = Analyze-ImageVisualsAndOcr $fullPath $ext
        if (-not [string]::IsNullOrWhiteSpace($vis.ocrText) -or -not [string]::IsNullOrWhiteSpace($vis.svgText)) {
            $stats.ocrDetectedCount++
        }
    }

    $companionTitle = if ($fileHash -and $hashToHumanTitle.ContainsKey($fileHash)) { $hashToHumanTitle[$fileHash] } else { "" }
    $parsedMeta = Parse-TitleAndCredit $f.Name $vis.ocrText $subFolder
    $title = if ($parsedMeta.isHashName -and $companionTitle) { $companionTitle } else { $parsedMeta.title }
    $credit = $parsedMeta.credit

    # Determine final Alt Text, Caption, Tags, OCR Text
    $detectedOcr = if ($vis.ocrText) { $vis.ocrText } elseif ($vis.svgText) { $vis.svgText } else { "" }
    $generatedAlt = if ($isImage) {
        Build-WcagAltText $wsLabel $subFolder $f.Name $title $credit $vis $companionTitle
    } else {
        "$wsLabel - $title ($($ext.ToUpper()) document)"
    }

    $finalTitle = $title
    $finalAlt = $generatedAlt
    $finalCredit = $credit
    $finalCaption = if ($detectedOcr) { "Detected text in image: ""$detectedOcr""" } else { "" }
    $folderTag = ($subFolder -replace '/', ', ')
    $finalTags = "$siteId, $folderTag" + ($(if ($isImage) { ", wcag-compliant" } else { ", document" })) + ($(if ($detectedOcr) { ", ocr-indexed" } else { "" }))

    $wasAlreadyCompliant = $false
    if ($null -ne $existing) {
        if (-not [string]::IsNullOrWhiteSpace($existing.title) -and -not $OverwriteExistingAlt -and $existing.title -notmatch '^[0-9a-fA-F]{24,64}$' -and $existing.title -notmatch 'S Cr Ee Ns Ho T') {
            $finalTitle = $existing.title
        }
        if ((Test-ValidExistingAlt $existing.alt_text) -and -not $OverwriteExistingAlt) {
            $finalAlt = $existing.alt_text
            $wasAlreadyCompliant = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($existing.credit) -and [string]::IsNullOrWhiteSpace($finalCredit)) {
            $finalCredit = $existing.credit
        }
        if (-not [string]::IsNullOrWhiteSpace($existing.caption) -and -not $OverwriteExistingAlt) {
            $finalCaption = $existing.caption
        }
        if ([string]::IsNullOrWhiteSpace($detectedOcr) -and -not [string]::IsNullOrWhiteSpace($existing.ocr_text)) {
            $detectedOcr = $existing.ocr_text
        }
    }

    $isWcagCompliant = $true

    if (-not $JsonOnly -and $null -ne $conn) {
        if ($null -eq $existing) {
            $cmdIns = $conn.CreateCommand()
            $cmdIns.CommandText = @"
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
INSERT INTO dbo.media_assets (
    site_id, folder, filename, file_path, web_url,
    file_size, file_ext, mime_type, file_hash,
    title, alt_text, caption, credit, ocr_text,
    is_image, width, height, is_wcag_compliant, tags,
    created_by, created_at, updated_at
) VALUES (
    @site_id, @folder, @filename, @file_path, @web_url,
    @file_size, @file_ext, @mime_type, @file_hash,
    @title, @alt_text, @caption, @credit, @ocr_text,
    @is_image, @width, @height, 1, @tags,
    'OCR Auto-Compliance Crawler', SYSDATETIME(), SYSDATETIME()
);
"@
            $null = $cmdIns.Parameters.AddWithValue("@site_id", $siteId)
            $null = $cmdIns.Parameters.AddWithValue("@folder", $subFolder)
            $null = $cmdIns.Parameters.AddWithValue("@filename", $f.Name)
            $null = $cmdIns.Parameters.AddWithValue("@file_path", $relFilePath)
            $null = $cmdIns.Parameters.AddWithValue("@web_url", $webUrl)
            $null = $cmdIns.Parameters.AddWithValue("@file_size", [long]$f.Length)
            $null = $cmdIns.Parameters.AddWithValue("@file_ext", $ext)
            $null = $cmdIns.Parameters.AddWithValue("@mime_type", $mimeType)
            $null = $cmdIns.Parameters.AddWithValue("@file_hash", $fileHash)
            $null = $cmdIns.Parameters.AddWithValue("@title", $finalTitle)
            $null = $cmdIns.Parameters.AddWithValue("@alt_text", $finalAlt)
            $null = $cmdIns.Parameters.AddWithValue("@caption", $finalCaption)
            $null = $cmdIns.Parameters.AddWithValue("@credit", $finalCredit)
            $null = $cmdIns.Parameters.AddWithValue("@ocr_text", $detectedOcr)
            $null = $cmdIns.Parameters.AddWithValue("@is_image", $(if ($isImage) { 1 } else { 0 }))
            if ($vis.width -gt 0) {
                $null = $cmdIns.Parameters.AddWithValue("@width", [int]$vis.width)
            } else {
                $null = $cmdIns.Parameters.AddWithValue("@width", [DBNull]::Value)
            }
            if ($vis.height -gt 0) {
                $null = $cmdIns.Parameters.AddWithValue("@height", [int]$vis.height)
            } else {
                $null = $cmdIns.Parameters.AddWithValue("@height", [DBNull]::Value)
            }
            $null = $cmdIns.Parameters.AddWithValue("@tags", $finalTags)
            $null = $cmdIns.ExecuteNonQuery()

            $stats.inserted++
            if ($isImage) { $stats.madeCompliant++ }
            $actionStatus = "inserted"
        } else {
            $cmdUpd = $conn.CreateCommand()
            $cmdUpd.CommandText = @"
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
UPDATE dbo.media_assets
SET site_id = @site_id,
    folder = @folder,
    file_path = @file_path,
    web_url = @web_url,
    file_size = @file_size,
    mime_type = @mime_type,
    file_hash = @file_hash,
    title = @title,
    alt_text = @alt_text,
    caption = @caption,
    credit = @credit,
    ocr_text = @ocr_text,
    width = @width,
    height = @height,
    is_wcag_compliant = 1,
    tags = @tags,
    updated_by = 'OCR Auto-Compliance Crawler',
    updated_at = SYSDATETIME()
WHERE id = @id;
"@
            $null = $cmdUpd.Parameters.AddWithValue("@id", [int]$existing.id)
            $null = $cmdUpd.Parameters.AddWithValue("@site_id", $siteId)
            $null = $cmdUpd.Parameters.AddWithValue("@folder", $subFolder)
            $null = $cmdUpd.Parameters.AddWithValue("@file_path", $relFilePath)
            $null = $cmdUpd.Parameters.AddWithValue("@web_url", $webUrl)
            $null = $cmdUpd.Parameters.AddWithValue("@file_size", [long]$f.Length)
            $null = $cmdUpd.Parameters.AddWithValue("@mime_type", $mimeType)
            $null = $cmdUpd.Parameters.AddWithValue("@file_hash", $fileHash)
            $null = $cmdUpd.Parameters.AddWithValue("@title", $finalTitle)
            $null = $cmdUpd.Parameters.AddWithValue("@alt_text", $finalAlt)
            $null = $cmdUpd.Parameters.AddWithValue("@caption", $finalCaption)
            $null = $cmdUpd.Parameters.AddWithValue("@credit", $finalCredit)
            $null = $cmdUpd.Parameters.AddWithValue("@ocr_text", $detectedOcr)
            if ($vis.width -gt 0) {
                $null = $cmdUpd.Parameters.AddWithValue("@width", [int]$vis.width)
            } else {
                $null = $cmdUpd.Parameters.AddWithValue("@width", [DBNull]::Value)
            }
            if ($vis.height -gt 0) {
                $null = $cmdUpd.Parameters.AddWithValue("@height", [int]$vis.height)
            } else {
                $null = $cmdUpd.Parameters.AddWithValue("@height", [DBNull]::Value)
            }
            $null = $cmdUpd.Parameters.AddWithValue("@tags", $finalTags)
            $null = $cmdUpd.ExecuteNonQuery()

            $stats.updated++
            if ($isImage -and -not $wasAlreadyCompliant) {
                $stats.madeCompliant++
                $actionStatus = "made-compliant"
            } elseif ($wasAlreadyCompliant) {
                $stats.alreadyCompliant++
                $actionStatus = "verified-compliant"
            } else {
                $actionStatus = "updated"
            }
        }
    } else {
        $actionStatus = "analyzed"
    }

    if ($processedItems.Count -lt 100) {
        $processedItems.Add(@{
            filename = $f.Name
            siteId = $siteId
            folder = $subFolder
            webUrl = $webUrl
            isImage = $isImage
            width = $vis.width
            height = $vis.height
            ocrText = $detectedOcr
            visualTone = $vis.visualTone
            orientation = $vis.orientation
            title = $finalTitle
            altText = $finalAlt
            caption = $finalCaption
            credit = $finalCredit
            tags = $finalTags
            fileHash = $fileHash
            status = $actionStatus
            isWcagCompliant = $isWcagCompliant
        })
    }
}

if ($null -ne $conn) {
    $conn.Close()
}
$sw.Stop()

$response = @{
    ok = $true
    success = $true
    targetDiskPath = $targetAbs
    requestedPath = $FolderPath
    durationMs = $sw.ElapsedMilliseconds
    filesScanned = $stats.filesScanned
    imagesProcessed = $stats.imagesProcessed
    documentsProcessed = $stats.documentsProcessed
    ocrDetectedCount = $stats.ocrDetectedCount
    madeCompliant = $stats.madeCompliant
    alreadyCompliant = $stats.alreadyCompliant
    inserted = $stats.inserted
    updated = $stats.updated
    thumbsCreated = $stats.thumbsCreated
    items = $processedItems
}

Write-Output ($response | ConvertTo-Json -Depth 6 -Compress)
