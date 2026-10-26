<cfset pageTitle = "Media OCR Content Detection &amp; Folder Auto-Compliance Guide">
<cfoutput>
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Media OCR Content Detection &amp; Folder Auto-Compliance</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='documentation', action='index')#">Documentation</a></li>
				<li class="breadcrumb-item active" aria-current="page">Media OCR &amp; Folder Auto-Compliance</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem;">
		<a href="#urlFor(controller='media', action='index')#" class="btn btn-primary btn-sm">
			#svgIcon(name="folder", size=14)#
			<span>Open Media Library</span>
		</a>
		<a href="#urlFor(controller='documentation', action='index')#" class="btn btn-outline btn-sm">
			#svgIcon(name="arrow-left", size=14)#
			<span>Back to Documentation</span>
		</a>
	</div>
</div>

<!--- Overview Card --->
<div class="admin-card" style="margin-bottom:1.5rem;">
	<div class="card-body" style="padding:1.5rem;">
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.65rem;">
			<span class="badge badge-success">WCAG 2.1 AA (1.1.1 Non-text Content)</span>
			<span class="badge badge-info">Windows Native WinRT OCR</span>
			<span class="badge badge-primary">Visual Palette &amp; Credit Detection</span>
		</div>
		<h2 style="font-size:1.2rem; margin:0 0 0.5rem; color:var(--admin-text-main);">Automated Image Accessibility &amp; Database Synchronization</h2>
		<p style="margin:0; color:var(--admin-text-muted); line-height:1.6;">
			CMSAdmin 2.0 includes an integrated <strong>OCR Content Detection &amp; Visual Analysis Engine</strong> (<code>scripts/crawl-folder-ocr.ps1</code> &amp; <code>api/Files.cfc</code>). It operates both <strong>automatically during single-file uploads</strong> (pre-filling Alternative Text and Display Title as soon as an image is dropped) and <strong>in batch folder crawls</strong> (scanning any workspace directory to make existing images WCAG 1.1.1 compliant and registering them in <code>dbo.media_assets</code>).
		</p>
	</div>
</div>

<!--- 1. On-Upload Pre-Flight OCR Auto-Prefill --->
<div class="admin-card" style="margin-bottom:1.5rem;">
	<div class="card-header">
		<h2 class="card-title">
			#svgIcon(name="upload", size=18)#
			<span>1. Automatic Pre-Flight OCR on File Upload</span>
		</h2>
	</div>
	<div class="card-body" style="padding:1.5rem;">
		<p style="margin:0 0 1rem; color:var(--admin-text-muted); line-height:1.6;">
			Whenever you select or drag-and-drop an image file into any upload dropzone in CMSAdmin 2.0, the browser immediately sends the file to <code>/api/Files.cfc?method=analyzeUploadOcr</code> (~0.6&ndash;0.9 seconds) and pre-fills the form fields before you click Upload:
		</p>
		<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(260px, 1fr)); gap:1rem; margin-bottom:1rem;">
			<div style="padding:1rem; background:var(--admin-bg, ##f8fafc); border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:8px;">
				<div style="font-weight:700; font-size:0.92rem; margin-bottom:0.35rem; color:var(--admin-text-main);">Media Library Quick Upload (<code>/media</code>)</div>
				<p style="margin:0; font-size:0.84rem; color:var(--admin-text-muted); line-height:1.5;">
					Click <strong>Upload</strong> inside File Explorer and select an image. <strong>Alternative Text (WCAG 1.1.1)</strong> and <strong>Display Title</strong> are populated automatically with a green confirmation badge showing any detected OCR text.
				</p>
			</div>
			<div style="padding:1rem; background:var(--admin-bg, ##f8fafc); border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:8px;">
				<div style="font-weight:700; font-size:0.92rem; margin-bottom:0.35rem; color:var(--admin-text-main);">Modal Media Picker (<code>/media/picker</code>)</div>
				<p style="margin:0; font-size:0.84rem; color:var(--admin-text-muted); line-height:1.5;">
					When browsing for a cover photo or inline image from the Page or Article Editor, quick-uploading a new image automatically pre-fills its accessible description.
				</p>
			</div>
			<div style="padding:1rem; background:var(--admin-bg, ##f8fafc); border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:8px;">
				<div style="font-weight:700; font-size:0.92rem; margin-bottom:0.35rem; color:var(--admin-text-main);">Full Upload Studio (<code>/media/upload</code>)</div>
				<p style="margin:0; font-size:0.84rem; color:var(--admin-text-muted); line-height:1.5;">
					Automatically populates <strong>Alternative Text</strong>, <strong>Display Title</strong>, <strong>Caption</strong> (if OCR text is found), <strong>Photographer Credit</strong> (from <code>~</code> filename tags), and <strong>Tags</strong>.
				</p>
			</div>
		</div>
	</div>
</div>

<!--- 2. Batch Folder Crawler in Media Library UI --->
<div class="admin-card" style="margin-bottom:1.5rem;">
	<div class="card-header">
		<h2 class="card-title">
			#svgIcon(name="shield", size=18)#
			<span>2. Crawling a Folder from the Media Library UI</span>
		</h2>
	</div>
	<div class="card-body" style="padding:1.5rem;">
		<ol style="margin:0; padding-left:1.25rem; line-height:1.75; color:var(--admin-text-main); font-size:0.92rem;">
			<li>Navigate to <strong>Media Library</strong> (<code>/media</code>).</li>
			<li>Click <strong>OCR Crawl &amp; Auto-Comply Folder</strong> in the top-right header &mdash; or select any folder in the File Explorer and click <strong>OCR Crawl &amp; Make Compliant</strong> in the right-hand Details panel.</li>
			<li>In the modal dialog, enter or select the <strong>Target Folder Path to Crawl</strong>:
				<ul style="margin:0.35rem 0 0.5rem;">
					<li>Use the <strong>Quick Fill</strong> buttons for <em>Current Open Folder</em>, <em>Current Workspace Root</em>, or <em>All Workspaces</em> (<code>C:\inetpub\chelan-county\files</code>).</li>
					<li>Accepts physical paths (<code>C:\inetpub\chelan-county\files\ohme-gardens</code>), assets URLs (<code>assets.chelancounty.com\ohme-gardens\images</code>), or relative paths (<code>auditor/images</code>).</li>
				</ul>
			</li>
			<li>Choose your options:
				<ul style="margin:0.35rem 0 0.5rem;">
					<li><strong>Include Subfolders (Recursive):</strong> Crawls all nested subdirectories.</li>
					<li><strong>Generate 360px Thumbnails (<code>.thumbs</code>):</strong> Creates lightweight <code>.thumbs/</code> previews for fast grid browsing.</li>
					<li><strong>Overwrite Existing Valid Alt Text:</strong> Leave unchecked to only auto-fill missing/placeholder descriptions, or check to regenerate descriptions for all images in the folder.</li>
				</ul>
			</li>
			<li>Click <strong>Start OCR Crawl &amp; Make Compliant</strong> to execute the crawl and view the per-image OCR &amp; WCAG Alt Text results table.</li>
		</ol>
	</div>
</div>

<!--- 3. PowerShell CLI Usage --->
<div class="admin-card" style="margin-bottom:1.5rem;">
	<div class="card-header">
		<h2 class="card-title">
			#svgIcon(name="terminal", size=18)#
			<span>3. Running the Crawler from PowerShell CLI</span>
		</h2>
	</div>
	<div class="card-body" style="padding:1.5rem;">
		<p style="margin:0 0 0.75rem; color:var(--admin-text-muted); font-size:0.9rem;">
			System administrators can run <code>scripts/crawl-folder-ocr.ps1</code> directly from PowerShell for scheduled tasks or bulk migrations:
		</p>
		<pre style="background:##0f172a; color:##f8fafc; padding:1rem 1.25rem; border-radius:8px; font-size:0.82rem; overflow-x:auto; line-height:1.6;"><code>## Crawl a single workspace or subfolder
cd C:\inetpub\CMSAdmin2.0
.\scripts\crawl-folder-ocr.ps1 -FolderPath "C:\inetpub\chelan-county\files\ohme-gardens"

## Crawl using a relative path or assets.chelancounty.com path
.\scripts\crawl-folder-ocr.ps1 -FolderPath "auditor/images"
.\scripts\crawl-folder-ocr.ps1 -FolderPath "assets.chelancounty.com\assessor\images"

## Crawl all workspaces at once
.\scripts\crawl-folder-ocr.ps1 -FolderPath "C:\inetpub\chelan-county\files"

## Force overwrite existing Alt Text in a folder
.\scripts\crawl-folder-ocr.ps1 -FolderPath "C:\inetpub\chelan-county\files\auditor\images" -OverwriteExistingAlt</code></pre>
	</div>
</div>

<!--- 4. 5-Stage Detection Pipeline --->
<div class="admin-card">
	<div class="card-header">
		<h2 class="card-title">
			#svgIcon(name="layers", size=18)#
			<span>4. How the 5-Stage OCR &amp; Visual Analysis Pipeline Works</span>
		</h2>
	</div>
	<div class="card-body" style="padding:1.5rem;">
		<div class="table-responsive">
			<table class="admin-table">
				<thead>
					<tr>
						<th style="width:90px;">Stage</th>
						<th style="width:260px;">Subsystem</th>
						<th>What It Detects &amp; Generates</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td><strong>Stage 1</strong></td>
						<td><strong>Windows Native WinRT OCR</strong><br><code style="font-size:0.75rem;">Windows.Media.Ocr.OcrEngine</code></td>
						<td>Extracts visible text from <code>.jpg</code>, <code>.jpeg</code>, <code>.png</code>, <code>.bmp</code>, and <code>.gif</code> graphics (event flyers, posters, license plates, signs, screenshots, seals) and filters out OCR punctuation noise.</td>
					</tr>
					<tr>
						<td><strong>Stage 2</strong></td>
						<td><strong>Visual Pixel Composition</strong><br><code style="font-size:0.75rem;">System.Drawing.Bitmap</code></td>
						<td>Reads exact dimensions (<code>width</code> &times; <code>height</code>), determines orientation (<code>panoramic banner</code>, <code>landscape</code>, <code>portrait</code>, <code>square</code>), detects alpha transparency, and samples dominant color tones (e.g., <em>lush green botanical foliage</em>, <em>sky and water blue tones</em>, <em>warm sunlit earth tones</em>).</td>
					</tr>
					<tr>
						<td><strong>Stage 3</strong></td>
						<td><strong>SVG XML &amp; Credit Parsing</strong></td>
						<td>Extracts <code>&lt;title&gt;</code> and <code>aria-label</code> from <code>.svg</code> vector icons and parses photographer/subject credits from <code>~</code> filename suffixes (e.g., <code>Wedding5~Pamela%20Grillo%20Photography.jpg</code> &rarr; Credit: <code>Pamela Grillo Photography</code>).</td>
					</tr>
					<tr>
						<td><strong>Stage 4</strong></td>
						<td><strong>SHA-256 Hash Title Recovery</strong></td>
						<td>Computes cryptographic <code>SHA-256</code> file hashes and maps hex/hash-named files to companion human-readable titles or detected OCR text.</td>
					</tr>
					<tr>
						<td><strong>Stage 5</strong></td>
						<td><strong>Database Upsert &amp; <code>.thumbs/</code></strong><br><code style="font-size:0.75rem;">dbo.media_assets</code></td>
						<td>Generates <code>360x360</code> max-dimension thumbnails inside <code>.thumbs\</code> and upserts the record into <code>dbo.media_assets</code> with <code>alt_text</code>, <code>ocr_text</code>, <code>title</code>, <code>caption</code>, <code>credit</code>, <code>tags</code>, and <code>is_wcag_compliant = 1</code>.</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>
</div>
</cfoutput>

