# OCR Content Detection & Folder Auto-Compliance Crawler — Quick Guide

> See also: [`folder-crawl-ocr.md`](file:///c:/inetpub/CMSAdmin2.0/folder-crawl-ocr.md)

This guide explains how to feed any folder of images/documents to the **OCR Content Detection & Folder Auto-Compliance Crawler** so every image is analyzed, made **WCAG 2.1 AA (`1.1.1 Non-text Content`)** compliant, given a `.thumbs/` preview, and saved to SQL Server (`dbo.media_assets`).

---

## 1. Option A: Run from the CMSAdmin 2.0 Media Library UI (Recommended)

1. Open **Media Library** (`/media`) in CMSAdmin 2.0.
2. Click the **OCR Crawl & Auto-Comply Folder** button in the top-right page header — **or** select any folder in the File Explorer and click **OCR Crawl & Make Compliant** in the right-hand Details panel.
3. In the **OCR Content Detection & Folder Auto-Compliance Crawler** modal:
   - **Target Folder Path to Crawl:** Paste or type any folder path, or click one of the **Quick Fill** buttons:
     - **Current Open Folder** (e.g., `C:\inetpub\chelan-county\files\auditor\images`)
     - **Current Workspace Root** (e.g., `C:\inetpub\chelan-county\files\auditor`)
     - **All Workspaces** (`C:\inetpub\chelan-county\files`)
   - **Supported Path Formats:**
     - Physical disk path: `C:\inetpub\chelan-county\files\ohme-gardens\images`
     - Assets domain path: `assets.chelancounty.com\ohme-gardens\images` or `https://assets.chelancounty.com/ohme-gardens/images`
     - Relative workspace path: `ohme-gardens/images` or `auditor`
4. Configure optional checkboxes:
   - **Include Subfolders (Recursive):** Crawls all nested subdirectories (checked by default).
   - **Generate 360px Thumbnails (`.thumbs`):** Generates fast `.thumbs/<filename>` previews for the Media Explorer grid (checked by default).
   - **Overwrite Existing Valid Alt Text:** Leave unchecked to only auto-fill missing/placeholder descriptions, or check to regenerate descriptions for all images in the folder.
5. Click **Start OCR Crawl & Make Compliant**.
6. Review the live telemetry counters (**Files Scanned**, **Images Analyzed**, **OCR Text Found**, **WCAG Compliant**) and the per-image table showing detected OCR text and generated `alt_text`.

---

## 2. Option B: Run from PowerShell CLI

You can run [`scripts/crawl-folder-ocr.ps1`](file:///c:/inetpub/CMSAdmin2.0/scripts/crawl-folder-ocr.ps1) directly from PowerShell on the server:

### Crawl a Single Workspace or Subfolder
```powershell
cd C:\inetpub\CMSAdmin2.0
.\scripts\crawl-folder-ocr.ps1 -FolderPath "C:\inetpub\chelan-county\files\ohme-gardens"
```

### Crawl Using a Relative Path or Assets URL
```powershell
.\scripts\crawl-folder-ocr.ps1 -FolderPath "auditor/images"
.\scripts\crawl-folder-ocr.ps1 -FolderPath "assets.chelancounty.com\assessor\images"
```

### Crawl All Workspaces at Once
```powershell
.\scripts\crawl-folder-ocr.ps1 -FolderPath "C:\inetpub\chelan-county\files"
```

### Force Overwrite Existing Alt Text in a Folder
```powershell
.\scripts\crawl-folder-ocr.ps1 -FolderPath "C:\inetpub\chelan-county\files\auditor\images" -OverwriteExistingAlt
```

### Inspect Formatted Summary Output in PowerShell
```powershell
$res = .\scripts\crawl-folder-ocr.ps1 -FolderPath "C:\inetpub\chelan-county\files\auditor" | ConvertFrom-Json
$res | Select-Object ok, targetDiskPath, durationMs, filesScanned, imagesProcessed, ocrDetectedCount, madeCompliant, inserted, updated
$res.items | Where-Object { $_.isImage } | Format-Table filename, ocrText, altText -Wrap -AutoSize
```

---

## 3. CLI Parameters Reference (`scripts/crawl-folder-ocr.ps1`)

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `-FolderPath` | `"C:\inetpub\chelan-county\files"` | Disk path, `assets.chelancounty.com\...` path, or relative workspace folder path to crawl. |
| `-Workspace` | `""` (Auto-detected) | Optional workspace `site_id` override when crawling a single file or custom path. |
| `-Recursive` | `$true` | Recursively crawls all nested subfolders (use `-Recursive:$false` for top-level only). |
| `-OverwriteExistingAlt` | `$false` | When set, replaces existing valid `alt_text` with newly synthesized OCR/visual `alt_text`. |
| `-GenerateThumbs` | `$true` | Automatically generates `360x360` max-dimension thumbnails in `.thumbs\` for fast grid loading. |
| `-JsonOnly` | `$false` | Runs OCR & visual analysis and outputs JSON without writing to SQL Server. |

---

## 4. How the 5-Stage OCR & Auto-Compliance Pipeline Works

1. **Windows Native WinRT OCR (`Windows.Media.Ocr.OcrEngine`):** Extracts embedded text from `.jpg`, `.jpeg`, `.png`, `.bmp`, and `.gif` images (flyers, event posters, license plates, banners, signs, screenshots) and filters out OCR punctuation noise.
2. **Visual Pixel Composition (`System.Drawing.Bitmap`):** Reads image dimensions (`width` × `height`), calculates orientation (`panoramic banner`, `landscape`, `portrait`, `square`), detects alpha transparency, and samples dominant color tones (`lush green botanical foliage`, `sky and water blue tones`, `warm sunlit earth tones`, `dramatic dark background`, etc.).
3. **SVG XML & Photographer Credit Extraction:** Reads `<title>` / `aria-label` from `.svg` files and parses photographer/subject credits from `~` filename suffixes (e.g., `Wedding5~Pamela%20Grillo%20Photography.jpg` -> Credit: `Pamela Grillo Photography`).
4. **SHA-256 Hash De-Duplication:** Computes `SHA-256` hashes for every file and maps hex/hash-named files to human-readable titles or OCR text.
5. **Database Upsert (`dbo.media_assets`):** Inserts new records or updates existing records in `ChelanCountyWebsite.dbo.media_assets` with `alt_text`, `ocr_text`, `title`, `caption`, `credit`, `tags`, `width`, `height`, `file_hash`, and `is_wcag_compliant = 1`.

---

## 5. Automatic Pre-Flight OCR on File Upload

When selecting or dragging an image into **any** upload dropzone in CMSAdmin 2.0:
- **Media Library Quick Upload** (`/media`)
- **Media Picker Quick Upload** (`/media/picker`)
- **Full Upload Studio** (`/media/upload`)

The browser automatically invokes `/api/Files.cfc?method=analyzeUploadOcr` in the background (~0.6–0.9s) and **pre-fills**:
- **Alternative Text (WCAG 1.1.1)** (`#upload-alt-input` / `#uploadAlt`)
- **Display Title** (`#upload-title-input` / `#uploadTitle`)
- **Caption**, **Photographer Credit**, **Tags**, and **OCR Text** (`#uploadOcrText`)

You can review or customize the pre-filled description before clicking **Upload Now** / **Save & Upload to Repository**.


