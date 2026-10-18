<cfparam name="variables.workspaces" default="#[]#">
<cfparam name="variables.defaultWs" default="assessors">
<cfparam name="variables.defaultFolder" default="images">
<cfparam name="variables.recentUploads" default="#queryNew('id,site_id,folder,filename,file_path,web_url,file_size,file_ext,file_hash,title,alt_text,caption,credit,is_image,is_wcag_compliant,width,height,created_at')#">
<cfparam name="variables.mediaStats" default="#queryNew('total_assets,total_images,total_documents,wcag_compliant_images,needs_alt_images')#">

<cfset local.totalAssets = variables.mediaStats.recordCount ? (variables.mediaStats.total_assets[1] ?: 0) : 0>
<cfset local.totalImages = variables.mediaStats.recordCount ? (variables.mediaStats.total_images[1] ?: 0) : 0>
<cfset local.totalDocs = variables.mediaStats.recordCount ? (variables.mediaStats.total_documents[1] ?: 0) : 0>
<cfset local.wcagCompliant = variables.mediaStats.recordCount ? (variables.mediaStats.wcag_compliant_images[1] ?: 0) : 0>
<cfset local.needsAlt = variables.mediaStats.recordCount ? (variables.mediaStats.needs_alt_images[1] ?: 0) : 0>
<cfset local.wcagPct = local.totalImages gt 0 ? Round((local.wcagCompliant / local.totalImages) * 100) : 100>

<style>
	.upload-studio-container { max-width: 980px; margin: 0 auto; }
	.upload-path-preview { background: #f8fafc; border: 1px solid var(--admin-border); border-radius: var(--radius-md); padding: 0.75rem 1rem; font-family: monospace; font-size: 0.85rem; color: var(--admin-text-main); display: flex; align-items: center; gap: 0.5rem; margin-top: 0.5rem; }
	.upload-card-dropzone { border: 2px dashed var(--admin-border-input); border-radius: var(--radius-lg); padding: 3rem 2rem; text-align: center; background: #f8fafc; cursor: pointer; transition: all 0.2s ease; position: relative; }
	.upload-card-dropzone:hover, .upload-card-dropzone.is-dragover { border-color: var(--admin-primary); background: var(--admin-primary-light); }
	.upload-card-dropzone:focus-within { outline: 2px solid var(--admin-primary); outline-offset: 2px; }
	.upload-icon-circle { width: 64px; height: 64px; border-radius: 50%; background: var(--admin-primary-light); color: var(--admin-primary); display: inline-flex; align-items: center; justify-content: center; margin-bottom: 1rem; }
	.file-selected-badge { margin-top: 1rem; padding: 0.65rem 1rem; background: #ffffff; border: 1px solid var(--admin-success); border-radius: var(--radius-md); display: inline-flex; align-items: center; gap: 0.65rem; color: var(--admin-success); font-weight: 600; font-size: 0.9rem; }
	.ada-tip-box { background: #eff6ff; border-left: 4px solid var(--admin-primary); padding: 0.85rem 1rem; border-radius: 0 var(--radius-md) var(--radius-md) 0; font-size: 0.825rem; color: #1e3a8a; line-height: 1.5; margin-top: 0.5rem; }
	.hash-pill { display: inline-flex; align-items: center; gap: 0.35rem; font-family: monospace; font-size: 0.75rem; background: #f1f5f9; color: #475569; padding: 2px 7px; border-radius: 4px; border: 1px solid #cbd5e1; }
	.table-thumb { width: 44px; height: 44px; border-radius: 4px; object-fit: cover; background: #f1f5f9; border: 1px solid var(--admin-border); }
	.table-thumb-placeholder { width: 44px; height: 44px; border-radius: 4px; display: inline-flex; align-items: center; justify-content: center; background: #f1f5f9; color: var(--admin-text-muted); border: 1px solid var(--admin-border); }
</style>

<div class="content-header">
	<div class="content-header-title">
		<nav class="breadcrumb" aria-label="Breadcrumb">
			<a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>">Dashboard</a>
			<span class="breadcrumb-separator">/</span>
			<a href="<cfoutput>#urlFor(controller='media', action='index')#</cfoutput>">Media Library</a>
			<span class="breadcrumb-separator">/</span>
			<span class="breadcrumb-current">Upload Media &amp; Metadata</span>
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
<!--- KPI Statistics Row --->
<div class="stat-grid" style="margin-bottom:1.5rem;">
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Total Assets</span>
			<span class="stat-value">#NumberFormat(local.totalAssets, ",")#</span>
			<span class="stat-change up">
				#svgIcon(name="hard-drive", size=13)#
				<span>Database tracked</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary">
			#svgIcon(name="media", size=24)#
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Image Assets</span>
			<span class="stat-value">#NumberFormat(local.totalImages, ",")#</span>
			<span class="stat-change" style="color:var(--admin-purple);">
				#svgIcon(name="eye", size=13)#
				<span>Web photos &amp; graphics</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-purple">
			#svgIcon(name="eye", size=24)#
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Documents &amp; Reports</span>
			<span class="stat-value">#NumberFormat(local.totalDocs, ",")#</span>
			<span class="stat-change" style="color:##0284c7;">
				#svgIcon(name="document", size=13)#
				<span>PDFs &amp; public records</span>
			</span>
		</div>
		<div class="stat-icon-wrapper" style="background:##e0f2fe; color:##0284c7;">
			#svgIcon(name="document", size=24)#
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">ADA WCAG AA Status</span>
			<span class="stat-value">#local.wcagPct#%</span>
			<span class="stat-change <cfif local.needsAlt gt 0>style="color:var(--admin-warning);"<cfelse>up</cfif>">
				<cfif local.needsAlt gt 0>
					#svgIcon(name="alert-triangle", size=13)#
					<span>#NumberFormat(local.needsAlt, ",")# need alt text</span>
				<cfelse>
					#svgIcon(name="check-circle", size=13)#
					<span>100% compliant</span>
				</cfif>
			</span>
		</div>
		<div class="stat-icon-wrapper <cfif local.needsAlt gt 0>stat-icon-warning<cfelse>stat-icon-success</cfif>">
			<cfif local.needsAlt gt 0>
				#svgIcon(name="alert-triangle", size=24)#
			<cfelse>
				#svgIcon(name="check-circle", size=24)#
			</cfif>
		</div>
	</div>
</div>

<div class="upload-studio-container">
	<form action="#urlFor(controller='media', action='processUpload')#" method="post" enctype="multipart/form-data" id="uploadFullForm">
		
		<!--- Institutional Workspace & Target Folder Configuration --->
		<div class="admin-card" style="margin-bottom:1.5rem;">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="folder", size=18)#
					<span>Destination Workspace &amp; Subfolder</span>
				</h2>
			</div>
			<div class="card-body">
				<p style="font-size:0.875rem; color:var(--admin-text-muted); margin-bottom:1rem;">
					Assets are written directly to disk at <code>files/[workspace]/[folder]</code> and cataloged in the SQL Server <code>dbo.media_assets</code> registry with cryptographic SHA-256 deduplication and WCAG metadata.
				</p>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.25rem;">
					<div class="form-group">
						<label for="selectWs" class="form-label" style="font-weight:600;">Destination Workspace <span style="color:var(--admin-danger);">*</span></label>
						<select id="selectWs" name="workspace" class="form-control" style="width:100%;" onchange="updatePathPreview()">
							<cfloop array="#variables.workspaces#" index="local.ws">
								<option value="#encodeForHTMLAttribute(local.ws.id)#" <cfif local.ws.id eq variables.defaultWs>selected</cfif>>
									#encodeForHTML(local.ws.name)# (#encodeForHTML(local.ws.id)#)
								</option>
							</cfloop>
						</select>
					</div>

					<div class="form-group">
						<label for="selectSubfolder" class="form-label" style="font-weight:600;">Repository Subfolder <span style="color:var(--admin-danger);">*</span></label>
						<select id="selectSubfolder" name="subfolder" class="form-control" style="width:100%;" onchange="updatePathPreview()">
							<option value="images" <cfif variables.defaultFolder eq 'images'>selected</cfif>>images/ (Recommended &mdash; Photos, Logos, Web Graphics)</option>
							<option value="documents" <cfif variables.defaultFolder eq 'documents'>selected</cfif>>documents/ (PDF Reports, Official Forms, Spreadsheets)</option>
							<option value="media" <cfif variables.defaultFolder eq 'media'>selected</cfif>>media/ (Legacy Folder &mdash; Media Assets)</option>
						</select>
					</div>
				</div>

				<div class="upload-path-preview">
					#svgIcon(name="hard-drive", size=16)#
					<span>Target Destination:</span>
					<strong id="destinationPathText">C:\inetpub\chelan-county\files\#encodeForHTML(variables.defaultWs)#\#encodeForHTML(variables.defaultFolder)#</strong>
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
					<p style="color:var(--admin-text-muted); font-size:0.875rem; max-width:520px; margin:0 auto 1rem auto;">
						Supports standard images (JPG, PNG, WEBP, SVG), PDFs, Office Documents (DOCX, XLSX), and compressed ZIP packages up to 25 MB.
						Executable files (.cfm, .cfc, .exe, .bat, .cmd) are strictly blocked.
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

		<!--- ADA WCAG AA Compliance & Editorial Metadata Card --->
		<div class="admin-card" style="margin-bottom:1.5rem;">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="shield", size=18)#
					<span>ADA WCAG 2.1/2.2 AA Accessibility &amp; Editorial Metadata</span>
				</h2>
			</div>
			<div class="card-body">
				<div class="form-group" style="margin-bottom:1.25rem;">
					<label for="uploadAlt" class="form-label" style="font-weight:600;">
						Alternative Text (Image Description) <span style="font-weight:normal; color:var(--admin-text-muted);">(Required for images to satisfy WCAG 1.1.1)</span>
					</label>
					<textarea id="uploadAlt" name="altText" class="form-control" rows="3" style="width:100%;" placeholder="Describe the contents and function of this image for blind and low-vision users using screen readers..."></textarea>
					<div class="ada-tip-box">
						<strong>WCAG 1.1.1 AA Requirement:</strong> All non-text content presented to citizens must provide an equivalent text alternative describing subjects, actions, and key graphical elements. Purely decorative images can be noted with a concise description or empty quotes.
					</div>
				</div>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.25rem; margin-bottom:1.25rem;">
					<div class="form-group">
						<label for="uploadTitle" class="form-label" style="font-weight:600;">Display Title</label>
						<input type="text" id="uploadTitle" name="title" class="form-control" style="width:100%;" placeholder="e.g. 2026 Assessment Roll Certified Summary">
						<div class="pg-help" style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">Shown in media browser, search results, and page attachments</div>
					</div>

					<div class="form-group">
						<label for="uploadCaption" class="form-label" style="font-weight:600;">Caption / Editorial Context</label>
						<input type="text" id="uploadCaption" name="caption" class="form-control" style="width:100%;" placeholder="Optional editorial caption or figure note">
					</div>
				</div>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.25rem;">
					<div class="form-group">
						<label for="uploadCredit" class="form-label" style="font-weight:600;">Photographer / Source Attribution</label>
						<input type="text" id="uploadCredit" name="credit" class="form-control" style="width:100%;" placeholder="e.g. Chelan County Assessor's Office / Jane Doe">
					</div>

					<div class="form-group">
						<label for="uploadTags" class="form-label" style="font-weight:600;">Tags &amp; Keywords</label>
						<input type="text" id="uploadTags" name="tags" class="form-control" style="width:100%;" placeholder="assessment, tax roll, parcel map, 2026">
						<div class="pg-help" style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">Comma-separated keywords for rapid discovery</div>
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

	<!--- Recent Uploads & Database Telemetry Table --->
	<div class="admin-card" style="margin-top:2rem;">
		<div class="card-header" style="display:flex; justify-content:space-between; align-items:center;">
			<h2 class="card-title">
				#svgIcon(name="database", size=18)#
				<span>Recent Database Tracked Uploads (<code>dbo.media_assets</code>)</span>
			</h2>
			<a href="#urlFor(controller='media', action='index')#" class="btn btn-outline btn-sm">
				#svgIcon(name="folder", size=14)#
				<span>Open File Explorer</span>
			</a>
		</div>
		<cfif variables.recentUploads.recordCount gt 0>
			<div class="table-responsive">
				<table class="admin-table">
					<thead>
						<tr>
							<th style="width:56px;">Preview</th>
							<th>Asset Title &amp; Filename</th>
							<th>Location &amp; Dimensions</th>
							<th>Size &amp; SHA-256</th>
							<th>ADA Status</th>
							<th style="text-align:right;">Uploaded</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="variables.recentUploads">
							<tr>
								<td>
									<cfif variables.recentUploads.is_image eq 1>
										<img src="#encodeForHTMLAttribute(variables.recentUploads.web_url)#" alt="#encodeForHTMLAttribute(variables.recentUploads.alt_text)#" class="table-thumb" onerror="this.src='/images/county-seal.svg';">
									<cfelse>
										<div class="table-thumb-placeholder">
											#svgIcon(name="document", size=18)#
										</div>
									</cfif>
								</td>
								<td>
									<div style="font-weight:600; color:var(--admin-text-main);">
										#encodeForHTML(Len(variables.recentUploads.title) ? variables.recentUploads.title : variables.recentUploads.filename)#
									</div>
									<div style="font-size:0.75rem; color:var(--admin-text-subtle); font-family:monospace;">
										#encodeForHTML(variables.recentUploads.filename)#
									</div>
									<cfif Len(variables.recentUploads.alt_text)>
										<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
											<em title="Alt text for screen readers">&ldquo;#encodeForHTML(Left(variables.recentUploads.alt_text, 60))#<cfif Len(variables.recentUploads.alt_text) gt 60>&hellip;</cfif>&rdquo;</em>
										</div>
									</cfif>
								</td>
								<td>
									<div style="font-size:0.8rem; font-family:monospace;">
										files/#encodeForHTML(variables.recentUploads.site_id)#/#encodeForHTML(variables.recentUploads.folder)#
									</div>
									<cfif Val(variables.recentUploads.width) gt 0 and Val(variables.recentUploads.height) gt 0>
										<div style="font-size:0.75rem; color:var(--admin-text-muted);">
											#variables.recentUploads.width# &times; #variables.recentUploads.height# px
										</div>
									</cfif>
								</td>
								<td>
									<div style="font-size:0.8rem;">
										<cfset local.sz = Val(variables.recentUploads.file_size)>
										<cfif local.sz lt 1024>
											#local.sz# B
										<cfelseif local.sz lt 1048576>
											#NumberFormat(local.sz / 1024, "0.0")# KB
										<cfelse>
											#NumberFormat(local.sz / 1048576, "0.0")# MB
										</cfif>
									</div>
									<cfif Len(variables.recentUploads.file_hash)>
										<span class="hash-pill" title="SHA-256: #encodeForHTMLAttribute(variables.recentUploads.file_hash)#">
											#svgIcon(name="hash", size=10)#
											#encodeForHTML(Left(variables.recentUploads.file_hash, 8))#&hellip;
										</span>
									</cfif>
								</td>
								<td>
									<cfif variables.recentUploads.is_image eq 1>
										<cfif variables.recentUploads.is_wcag_compliant eq 1>
											<span class="badge badge-success" style="display:inline-flex; align-items:center; gap:4px;">
												#svgIcon(name="check-circle", size=12)#
												<span>Compliant</span>
											</span>
										<cfelse>
											<span class="badge badge-warning" style="display:inline-flex; align-items:center; gap:4px;">
												#svgIcon(name="alert-triangle", size=12)#
												<span>Needs Alt Text</span>
											</span>
										</cfif>
									<cfelse>
										<span class="badge badge-secondary" style="display:inline-flex; align-items:center; gap:4px;">
											#svgIcon(name="check-circle", size=12)#
											<span>Document</span>
										</span>
									</cfif>
								</td>
								<td style="text-align:right; font-size:0.8rem; color:var(--admin-text-muted); white-space:nowrap;">
									#DateFormat(variables.recentUploads.created_at, "mmm dd, yyyy")#<br>
									<span style="font-size:0.725rem;">#TimeFormat(variables.recentUploads.created_at, "h:mm tt")#</span>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		<cfelse>
			<div class="card-body" style="text-align:center; padding:3rem 1rem; color:var(--admin-text-muted);">
				#svgIcon(name="database", size=32)#
				<h3 style="font-size:1rem; font-weight:600; margin-top:0.75rem; color:var(--admin-text-main);">No Database-Tracked Assets Found</h3>
				<p style="font-size:0.85rem; max-width:440px; margin:0.25rem auto 0 auto;">
					Upload your first media file or document using the studio above to register it in the <code>dbo.media_assets</code> catalog.
				</p>
			</div>
		</cfif>
	</div>
</div>
</cfoutput>

<script>
	function updatePathPreview() {
		const wsEl = document.getElementById('selectWs');
		const folderEl = document.getElementById('selectSubfolder');
		const ws = wsEl ? wsEl.value : 'assessors';
		const folder = folderEl ? folderEl.value : 'images';
		const destText = document.getElementById('destinationPathText');
		if (destText) {
			destText.textContent = `C:\\inetpub\\chelan-county\\files\\${ws}\\${folder}`;
		}
	}

	function handleFileChange(input) {
		const box = document.getElementById('fileSelectionBox');
		const nameSpan = document.getElementById('selectedFileName');
		const sizeSpan = document.getElementById('selectedFileSize');
		const titleInput = document.getElementById('uploadTitle');
		const altInput = document.getElementById('uploadAlt');

		if (input.files && input.files[0]) {
			const f = input.files[0];
			nameSpan.textContent = f.name;
			const szKb = (f.size / 1024).toFixed(1);
			sizeSpan.textContent = `(${szKb} KB)`;
			box.style.display = 'block';

			// Auto populate title if blank
			if (!titleInput.value) {
				const clean = f.name.replace(/\.[^/.]+$/, '').replace(/[-_]+/g, ' ').trim();
				titleInput.value = clean.charAt(0).toUpperCase() + clean.slice(1);
			}

			// Pre-fill prompt for alt text if image
			const isImg = /\.(jpe?g|png|gif|webp|svg|bmp)$/i.test(f.name);
			if (isImg && !altInput.value) {
				altInput.placeholder = `Describe "${f.name}" for screen readers to satisfy ADA WCAG AA...`;
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
		updatePathPreview();
	});
</script>
