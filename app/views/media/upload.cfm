<cfparam name="variables.workspaces" default="#[]#">
<cfparam name="variables.defaultWs" default="assessors">
<cfparam name="variables.defaultFolder" default="media">

<style>
	.upload-studio-container { max-width: 860px; margin: 0 auto; }
	.upload-path-preview { background: #f1f5f9; border: 1px solid var(--admin-border); border-radius: var(--radius-md); padding: 0.75rem 1rem; font-family: monospace; font-size: 0.85rem; color: var(--admin-text-main); display: flex; align-items: center; gap: 0.5rem; margin-top: 0.5rem; }
	.upload-card-dropzone { border: 2px dashed var(--admin-border-input); border-radius: var(--radius-lg); padding: 3rem 2rem; text-align: center; background: #f8fafc; cursor: pointer; transition: all 0.2s ease; position: relative; }
	.upload-card-dropzone:hover, .upload-card-dropzone.is-dragover { border-color: var(--admin-primary); background: var(--admin-primary-light); }
	.upload-card-dropzone:focus-within { outline: 2px solid var(--admin-primary); outline-offset: 2px; }
	.upload-icon-circle { width: 64px; height: 64px; border-radius: 50%; background: var(--admin-primary-light); color: var(--admin-primary); display: inline-flex; align-items: center; justify-content: center; margin-bottom: 1rem; }
	.file-selected-badge { margin-top: 1rem; padding: 0.65rem 1rem; background: #ffffff; border: 1px solid var(--admin-success); border-radius: var(--radius-md); display: inline-flex; align-items: center; gap: 0.65rem; color: var(--admin-success); font-weight: 600; font-size: 0.9rem; }
	.ada-tip-box { background: #eff6ff; border-left: 4px solid var(--admin-primary); padding: 0.85rem 1rem; border-radius: 0 var(--radius-md) var(--radius-md) 0; font-size: 0.825rem; color: #1e3a8a; line-height: 1.5; margin-top: 0.5rem; }
</style>

<div class="content-header">
	<div class="content-header-title">
		<nav class="breadcrumb" aria-label="Breadcrumb">
			<a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>">Dashboard</a>
			<span class="breadcrumb-separator">/</span>
			<a href="<cfoutput>#urlFor(controller='media', action='index')#</cfoutput>">Media Library</a>
			<span class="breadcrumb-separator">/</span>
			<span class="breadcrumb-current">Upload Files</span>
		</nav>
		<h1 class="page-title">
			<cfoutput>#svgIcon(name="upload", size=24)#</cfoutput>
			<span>Upload Media &amp; Documents</span>
		</h1>
	</div>

	<div>
		<a href="<cfoutput>#urlFor(controller='media', action='index')#</cfoutput>" class="btn btn-secondary">
			<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
			<span>Back to Library</span>
		</a>
	</div>
</div>

<cfoutput>
<div class="upload-studio-container">
	<form action="#urlFor(controller='media', action='processUpload')#" method="post" enctype="multipart/form-data" id="uploadFullForm">
		
		<!--- Institutional Workspace & Target Folder Configuration --->
		<div class="admin-card" style="margin-bottom:1.5rem;">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="folder", size=18)#
					<span>Destination Workspace &amp; Folder</span>
				</h2>
			</div>
			<div class="card-body">
				<p style="font-size:0.875rem; color:var(--admin-text-muted); margin-bottom:1rem;">
					Files uploaded are stored directly in the county server filesystem under <code>files/[workspace]/[folder]</code>.
					The <strong>Assessors</strong> workspace hosts the shared media library repository for county-wide assessor assets and public archives.
				</p>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.25rem;">
					<div class="form-group">
						<label for="selectWs" class="form-label" style="font-weight:600;">Workspace / Department Site <span style="color:var(--admin-danger);">*</span></label>
						<select id="selectWs" name="workspace" class="form-control" style="width:100%;" onchange="updatePathPreview()">
							<cfloop array="#variables.workspaces#" index="local.w">
								<option value="#local.w.id#" <cfif variables.defaultWs eq local.w.id>selected</cfif>>
									#EncodeForHTML(local.w.name)#
								</option>
							</cfloop>
						</select>
					</div>

					<div class="form-group">
						<label for="selectSubfolder" class="form-label" style="font-weight:600;">Repository Subfolder <span style="color:var(--admin-danger);">*</span></label>
						<select id="selectSubfolder" name="subfolder" class="form-control" style="width:100%;" onchange="updatePathPreview()">
							<option value="media" <cfif variables.defaultFolder eq 'media'>selected</cfif>>media/ (Photos, Logos, Graphic Assets)</option>
							<option value="documents" <cfif variables.defaultFolder eq 'documents'>selected</cfif>>documents/ (PDF Reports, Forms, Spreadsheets)</option>
						</select>
					</div>
				</div>

				<div class="upload-path-preview">
					#svgIcon(name="hard-drive", size=16)#
					<span>Target Destination:</span>
					<strong id="destinationPathText">C:\inetpub\chelan-county\files\#variables.defaultWs#\#variables.defaultFolder#</strong>
				</div>
			</div>
		</div>

		<!--- Drag-and-Drop File Upload Area --->
		<div class="admin-card" style="margin-bottom:1.5rem;">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="upload", size=18)#
					<span>Select or Drop File</span>
				</h2>
			</div>
			<div class="card-body">
				<div class="upload-card-dropzone" id="fileDropzone">
					<div class="upload-icon-circle">
						#svgIcon(name="upload", size=32)#
					</div>
					<h3 style="font-size:1.15rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.35rem;">
						Choose a file or drag &amp; drop it here
					</h3>
					<p style="color:var(--admin-text-muted); font-size:0.875rem; max-width:480px; margin:0 auto 1rem auto;">
						Supports standard images (JPG, PNG, WEBP, SVG), PDFs, Office Documents (DOCX, XLSX), and compressed ZIP packages up to 25 MB.
					</p>

					<input type="file" id="mediaFileInputField" name="mediaFile" required style="position:absolute; inset:0; opacity:0; cursor:pointer;" onchange="handleFileChange(this)">

					<div id="fileSelectionBox" style="display:none;">
						<div class="file-selected-badge">
							#svgIcon(name="check-circle", size=18)#
							<span id="selectedFileName">filename.png</span>
							<span id="selectedFileSize" style="font-weight:normal; opacity:0.8;">(0 KB)</span>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!--- ADA WCAG AA Compliance & Metadata Card --->
		<div class="admin-card" style="margin-bottom:1.5rem;">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="shield", size=18)#
					<span>ADA WCAG 2.1/2.2 AA Accessibility &amp; Metadata</span>
				</h2>
			</div>
			<div class="card-body">
				<div class="form-group" style="margin-bottom:1.25rem;">
					<label for="uploadAlt" class="form-label" style="font-weight:600;">
						Alternative Text (Image Description) <span style="font-weight:normal; color:var(--admin-text-muted);">(Required for images)</span>
					</label>
					<textarea id="uploadAlt" name="altText" class="form-control" rows="3" style="width:100%;" placeholder="Describe the contents and function of this image for blind and low-vision users using screen readers..."></textarea>
					<div class="ada-tip-box">
						<strong>WCAG AA Requirement:</strong> All non-text content that is presented to the user must have a text alternative that serves the equivalent purpose (WCAG 1.1.1). Describe key subjects, actions, and text rendered within the graphic.
					</div>
				</div>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.25rem;">
					<div class="form-group">
						<label for="uploadTitle" class="form-label" style="font-weight:600;">Display Title</label>
						<input type="text" id="uploadTitle" name="title" class="form-control" style="width:100%;" placeholder="e.g. 2026 Assessment Roll Certified Summary">
						<div class="pg-help" style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">Shown in search results and media browser</div>
					</div>

					<div class="form-group">
						<label for="uploadCaption" class="form-label" style="font-weight:600;">Caption / Editorial Context</label>
						<input type="text" id="uploadCaption" name="caption" class="form-control" style="width:100%;" placeholder="Optional editorial caption or attribution notes">
					</div>
				</div>
			</div>
			<div class="card-footer" style="padding:1rem 1.5rem; background:var(--admin-surface-hover); border-top:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
				<a href="#urlFor(controller='media', action='index')#" class="btn btn-secondary">Cancel</a>
				<button type="submit" class="btn btn-primary btn-lg" id="btnSubmitFullUpload">
					#svgIcon(name="upload", size=18)#
					<span>Save &amp; Upload to Repository</span>
				</button>
			</div>
		</div>
	</form>
</div>
</cfoutput>

<script>
	function updatePathPreview() {
		const ws = document.getElementById('selectWs').value;
		const folder = document.getElementById('selectSubfolder').value;
		document.getElementById('destinationPathText').textContent = `C:\\inetpub\\chelan-county\\files\\${ws}\\${folder}`;
	}

	function handleFileChange(input) {
		const box = document.getElementById('fileSelectionBox');
		const nameSpan = document.getElementById('selectedFileName');
		const sizeSpan = document.getElementById('selectedFileSize');
		const titleInput = document.getElementById('uploadTitle');

		if (input.files && input.files[0]) {
			const f = input.files[0];
			nameSpan.textContent = f.name;
			sizeSpan.textContent = `(${(f.size / 1024).toFixed(1)} KB)`;
			box.style.display = 'block';

			if (!titleInput.value) {
				titleInput.value = f.name.replace(/\.[^/.]+$/, '').replace(/[-_]/g, ' ');
			}
		}
	}

	document.addEventListener('DOMContentLoaded', () => {
		const dropzone = document.getElementById('fileDropzone');
		if (dropzone) {
			['dragenter', 'dragover'].forEach(name => {
				dropzone.addEventListener(name, (e) => {
					e.preventDefault();
					e.stopPropagation();
					dropzone.classList.add('is-dragover');
				});
			});
			['dragleave', 'drop'].forEach(name => {
				dropzone.addEventListener(name, (e) => {
					e.preventDefault();
					e.stopPropagation();
					dropzone.classList.remove('is-dragover');
				});
			});
		}
	});
</script>
