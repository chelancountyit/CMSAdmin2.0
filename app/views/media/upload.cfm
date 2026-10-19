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

<link rel="stylesheet" href="/stylesheets/filexplorer/explorer.css?v=4.0">

<style>
	.upload-studio-container { max-width: 980px; margin: 0 auto; }
	.upload-path-preview { background: #f8fafc; border: 1px solid var(--admin-border); border-radius: var(--radius-md); padding: 0.75rem 1rem; font-family: monospace; font-size: 0.85rem; color: var(--admin-text-main); display: flex; align-items: center; gap: 0.5rem; margin-top: 0.5rem; }
	.file-selected-badge { margin-top: 1rem; padding: 0.65rem 1rem; background: #ffffff; border: 1px solid var(--admin-success); border-radius: var(--radius-md); display: inline-flex; align-items: center; gap: 0.65rem; color: var(--admin-success); font-weight: 600; font-size: 0.9rem; }
	.ada-tip-box { background: #eff6ff; border-left: 4px solid var(--admin-primary); padding: 0.85rem 1rem; border-radius: 0 var(--radius-md) var(--radius-md) 0; font-size: 0.825rem; color: #1e3a8a; line-height: 1.5; margin-top: 0.5rem; }
	.hash-pill { display: inline-flex; align-items: center; gap: 0.35rem; font-family: monospace; font-size: 0.75rem; background: #f1f5f9; color: #475569; padding: 2px 7px; border-radius: 4px; border: 1px solid #cbd5e1; }
	.table-thumb { width: 44px; height: 44px; border-radius: 4px; object-fit: cover; background: #f1f5f9; border: 1px solid var(--admin-border); }
	.table-thumb-placeholder { width: 44px; height: 44px; border-radius: 4px; display: inline-flex; align-items: center; justify-content: center; background: #f1f5f9; color: var(--admin-text-muted); border: 1px solid var(--admin-border); }
</style>

<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Upload Media &amp; Documents</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>"><cfoutput>#svgIcon(name="dashboard", size=14)#</cfoutput> Home</a></li>
				<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='media', action='index')#</cfoutput>">Media Library</a></li>
				<li class="breadcrumb-item active" aria-current="page">Upload Media</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="<cfoutput>#urlFor(controller='media', action='index')#</cfoutput>" class="btn btn-outline btn-sm">
			<cfoutput>#svgIcon(name="arrow-left", size=14)#</cfoutput>
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

		<!--- Drag-and-Drop File Upload Area (Matching CMSAdmin 2.0 Studio Design) --->
		<div class="admin-card" style="margin-bottom:1.5rem;">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="upload", size=18)#
					<span>Select or Drop File</span>
				</h2>
			</div>
			<div class="card-body">
				<!--- Hero Dropzone Card --->
				<div class="media-upload-dropzone" id="fileDropzone" role="button" tabindex="0"
				     style="border: 2px dashed ##0284c7; border-radius: 12px; padding: 2.25rem 1.5rem; text-align: center; background: ##f8fafc; cursor: pointer; transition: all 0.2s ease; position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 140px; outline: none; margin-bottom: 1rem;"
				     aria-label="Click to browse workspace media library or drag and drop files here" title="Click to browse workspace media library or drag and drop files here">
					<div id="fileDropzonePrompt" class="media-dropzone-prompt" style="display: flex; flex-direction: column; align-items: center; justify-content: center; pointer-events: none;">
						<div style="color: ##0284c7; margin-bottom: 0.5rem; display: flex; align-items: center; justify-content: center;">
							#svgIcon(name="image", size=36)#
						</div>
						<div class="media-dropzone-title" style="font-size: 1.05rem; font-weight: 700; color: ##0f172a; margin-bottom: 0.25rem; letter-spacing: -0.01em;">Choose Cover Image / File</div>
						<div class="media-dropzone-sub" style="font-size: 0.825rem; color: ##64748b;">Click to browse workspace media library or drag and drop here</div>
					</div>

					<div id="fileSelectionBox" class="media-selected-card" hidden style="display: flex; align-items: center; gap: 1rem; padding: 0.75rem 1rem; background: ##ffffff; border: 1.5px solid ##0284c7; border-radius: 8px; max-width: 520px; width: 100%; box-shadow: 0 2px 8px rgba(2, 132, 199, 0.08); position: relative; z-index: 6;">
						<div id="uploadSelectedThumb" class="media-selected-thumb" style="width: 54px; height: 54px; border-radius: 6px; object-fit: cover; background: ##f1f5f9; border: 1px solid ##cbd5e1; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0;"></div>
						<div class="media-selected-info" style="flex: 1; min-width: 0; text-align: left;">
							<div id="selectedFileName" class="media-selected-name" style="font-size: 0.875rem; font-weight: 700; color: ##0f172a; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">filename.png</div>
							<div id="selectedFileSize" class="media-selected-meta" style="font-size: 0.75rem; color: ##64748b; margin-top: 0.15rem;">(0 KB)</div>
						</div>
						<button type="button" id="btnRemoveSelectedFile" class="btn btn-outline btn-xs" title="Change or remove selected file" style="position: relative; z-index: 7;">
							#svgIcon(name="x", size=12)#
							<span>Change</span>
						</button>
					</div>

					<input type="file" id="mediaFileInputField" name="mediaFile" class="media-file-native-input" tabindex="-1" aria-hidden="true" required onchange="handleFileChange(this)" style="position: absolute; inset: 0; width: 100%; height: 100%; opacity: 0; cursor: pointer; z-index: 5;">
				</div>

				<!--- Image URL & Browse Row (Directly below dropzone) --->
				<div class="media-url-browse-row" style="margin-top: 0.25rem;">
					<label for="destinationPathUrlInput" class="media-url-label" style="display: block; font-size: 0.85rem; font-weight: 600; color: ##334155; margin-bottom: 0.35rem;">
						Image URL
					</label>
					<div class="media-url-input-group" style="display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
						<input type="text" id="destinationPathUrlInput" class="form-control media-url-field" placeholder="/files/#encodeForHTMLAttribute(variables.defaultWs)#/#encodeForHTMLAttribute(variables.defaultFolder)#/photo.jpg" readonly title="Prospective URL destination on server" style="flex: 1; min-width: 240px; border: 1.5px solid ##cbd5e1 !important; border-radius: 8px !important; padding: 0.6rem 0.85rem !important; font-size: 0.875rem !important; background: ##ffffff !important; color: ##0f172a !important;">
						<button type="button" id="btnBrowseFileStudio" class="btn media-btn-browse" title="Browse files on your computer" style="display: inline-flex; align-items: center; gap: 0.45rem; padding: 0.6rem 1.15rem; border: 1.5px solid ##cbd5e1 !important; border-radius: 8px !important; background: ##f1f5f9 !important; font-weight: 600; font-size: 0.875rem; color: ##0f172a !important; cursor: pointer; white-space: nowrap;">
							#svgIcon(name="folder", size=15)#
							<span>Browse</span>
						</button>
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
					<label for="uploadAlt" class="form-label" style="font-weight:600; display:flex; justify-content:space-between; align-items:center;">
						<span>Alternative Text (Image Description) <span id="uploadAltRequiredIndicator" style="color:var(--admin-danger); font-weight:700;">* Required for Images (WCAG 1.1.1)</span></span>
						<span style="font-size:0.75rem; color:var(--admin-primary); font-weight:600;">ADA Title II Mandatory</span>
					</label>
					<textarea id="uploadAlt" name="altText" class="form-control" rows="3" style="width:100%; transition:border-color 0.2s, box-shadow 0.2s;" placeholder="Describe the visual subjects, text, and context of this image for blind and low-vision users using screen readers..." oninput="updateAltCharCount(this.value)"></textarea>
					<div id="uploadAltCharCount" style="text-align:right; font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">0 / 150 rec.</div>
					
					<!--- Decorative Image Toggle Option (WCAG H67) --->
					<div class="form-check" style="margin-top:0.65rem; display:flex; align-items:center; gap:0.5rem;">
						<input type="checkbox" id="uploadDecorative" name="isDecorative" value="1" class="form-check-input" onchange="toggleDecorativeUpload(this.checked)" style="margin:0; width:16px; height:16px;">
						<label for="uploadDecorative" class="form-check-label" style="font-size:0.825rem; color:var(--admin-text-main); font-weight:500; cursor:pointer;">
							This image is purely decorative / presentation-only (satisfies WCAG 1.1.1 Technique H67 &mdash; screen readers will ignore it)
						</label>
					</div>

					<div class="ada-tip-box" style="margin-top:0.75rem;">
						<strong>WCAG 1.1.1 AA Mandate:</strong> Under County ADA policy, all images must provide an equivalent text alternative describing subjects, actions, and key graphical elements. If the image is purely decorative background styling, check the box above.
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
	function getCurrentWebUrl(fileName) {
		const wsEl = document.getElementById('selectWs');
		const folderEl = document.getElementById('selectSubfolder');
		const ws = wsEl ? wsEl.value : 'assessors';
		const folder = folderEl ? folderEl.value : 'images';
		const file = fileName || '';
		return file ? `/files/${ws}/${folder}/${file}` : `/files/${ws}/${folder}/photo.jpg`;
	}

	function updatePathPreview() {
		const wsEl = document.getElementById('selectWs');
		const folderEl = document.getElementById('selectSubfolder');
		const ws = wsEl ? wsEl.value : 'assessors';
		const folder = folderEl ? folderEl.value : 'images';
		const destText = document.getElementById('destinationPathText');
		if (destText) {
			destText.textContent = `C:\\inetpub\\chelan-county\\files\\${ws}\\${folder}`;
		}
		const urlInput = document.getElementById('destinationPathUrlInput');
		if (urlInput) {
			const input = document.getElementById('mediaFileInputField');
			const hasFile = input && input.files && input.files[0];
			if (hasFile) {
				urlInput.value = getCurrentWebUrl(input.files[0].name);
			} else {
				urlInput.placeholder = getCurrentWebUrl('');
				urlInput.value = '';
			}
		}
	}

	function handleFileChange(input) {
		const prompt = document.getElementById('fileDropzonePrompt');
		const box = document.getElementById('fileSelectionBox');
		const thumb = document.getElementById('uploadSelectedThumb');
		const nameSpan = document.getElementById('selectedFileName');
		const sizeSpan = document.getElementById('selectedFileSize');
		const titleInput = document.getElementById('uploadTitle');
		const altInput = document.getElementById('uploadAlt');
		const urlInput = document.getElementById('destinationPathUrlInput');

		if (input.files && input.files[0]) {
			const f = input.files[0];
			if (prompt) prompt.hidden = true;
			if (box) box.hidden = false;
			if (nameSpan) nameSpan.textContent = f.name;
			const szKb = (f.size / 1024).toFixed(1);
			if (sizeSpan) sizeSpan.textContent = `${szKb} KB`;

			// Render thumbnail or placeholder icon
			if (thumb) {
				thumb.innerHTML = '';
				const isImg = /\.(jpe?g|png|gif|webp|svg|bmp)$/i.test(f.name);
				if (isImg && typeof FileReader !== 'undefined') {
					const reader = new FileReader();
					reader.onload = (e) => {
						thumb.innerHTML = `<img src="${e.target.result}" alt="Preview" style="width:100%; height:100%; object-fit:cover; border-radius:6px;">`;
					};
					reader.readAsDataURL(f);
				} else {
					thumb.innerHTML = `<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><polyline points="13 2 13 9 20 9"/></svg>`;
				}
			}

			// Update Image URL preview
			if (urlInput) {
				urlInput.value = getCurrentWebUrl(f.name);
			}

			// Auto populate title if blank
			if (titleInput && !titleInput.value) {
				const clean = f.name.replace(/\.[^/.]+$/, '').replace(/[-_]+/g, ' ').trim();
				titleInput.value = clean.charAt(0).toUpperCase() + clean.slice(1);
			}

			// Pre-fill prompt for alt text if image & enforce required state
			const isImg = /\.(jpe?g|png|gif|webp|svg|bmp)$/i.test(f.name);
			const reqIndicator = document.getElementById('uploadAltRequiredIndicator');
			if (altInput) {
				if (isImg) {
					altInput.required = true;
					if (reqIndicator) reqIndicator.style.display = 'inline';
					if (!altInput.value) {
						altInput.placeholder = `Required: Describe "${f.name}" for screen readers to satisfy ADA WCAG AA (WCAG 1.1.1)...`;
					}
				} else {
					altInput.required = false;
					if (reqIndicator) reqIndicator.style.display = 'none';
					altInput.placeholder = 'Optional description (not an image)...';
				}
			}
		} else {
			if (prompt) prompt.hidden = false;
			if (box) box.hidden = true;
			if (thumb) thumb.innerHTML = '';
			if (urlInput) {
				urlInput.value = '';
				urlInput.placeholder = getCurrentWebUrl('');
			}
		}
	}

	function updateAltCharCount(val) {
		const counter = document.getElementById('uploadAltCharCount');
		const altInput = document.getElementById('uploadAlt');
		if (counter) {
			const len = (val || '').length;
			counter.textContent = `${len} / 150 rec.`;
			if (len > 150) {
				counter.style.color = 'var(--admin-warning, ##d97706)';
			} else {
				counter.style.color = 'var(--admin-text-muted)';
			}
		}
		if (altInput && (val || '').trim().length > 0) {
			altInput.style.borderColor = '';
			altInput.style.boxShadow = '';
		}
	}

	function toggleDecorativeUpload(isDec) {
		const altInput = document.getElementById('uploadAlt');
		const reqIndicator = document.getElementById('uploadAltRequiredIndicator');
		if (altInput) {
			if (isDec) {
				altInput.dataset.previousVal = altInput.value;
				altInput.value = '';
				altInput.disabled = true;
				altInput.required = false;
				altInput.style.opacity = '0.6';
				altInput.placeholder = 'Image marked as purely decorative (WCAG H67). Alt text is not required for presentation-only elements.';
				altInput.style.borderColor = '';
				altInput.style.boxShadow = '';
				if (reqIndicator) reqIndicator.style.display = 'none';
			} else {
				altInput.disabled = false;
				altInput.required = true;
				altInput.style.opacity = '1';
				altInput.value = altInput.dataset.previousVal || '';
				altInput.placeholder = 'Describe the visual subjects, text, and context of this image for blind and low-vision users using screen readers...';
				if (reqIndicator) reqIndicator.style.display = 'inline';
				altInput.focus();
			}
			updateAltCharCount(altInput.value);
		}
	}

	document.addEventListener('DOMContentLoaded', () => {
		const dropzone = document.getElementById('fileDropzone');
		const fileInput = document.getElementById('mediaFileInputField');
		const btnBrowse = document.getElementById('btnBrowseFileStudio');
		const btnRemove = document.getElementById('btnRemoveSelectedFile');

		if (btnBrowse && fileInput) {
			btnBrowse.addEventListener('click', (e) => {
				e.preventDefault();
				fileInput.click();
			});
		}

		if (btnRemove && fileInput) {
			btnRemove.addEventListener('click', (e) => {
				e.preventDefault();
				e.stopPropagation();
				fileInput.value = '';
				handleFileChange(fileInput);
			});
		}

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

			dropzone.addEventListener('keydown', (e) => {
				if ((e.key === 'Enter' || e.key === ' ') && fileInput) {
					e.preventDefault();
					fileInput.click();
				}
			});
		}

		const uploadForm = document.getElementById('uploadFullForm');
		if (uploadForm) {
			uploadForm.addEventListener('submit', (e) => {
				const fileInput = document.getElementById('mediaFileInputField');
				const f = fileInput && fileInput.files && fileInput.files[0];
				if (!f) {
					e.preventDefault();
					if (window.showToast) window.showToast('Please choose a file to upload.', 'warning');
					return false;
				}
				const isImg = /\.(jpe?g|png|gif|webp|svg|bmp)$/i.test(f.name);
				const altInput = document.getElementById('uploadAlt');
				const decCheck = document.getElementById('uploadDecorative');
				const isDec = decCheck && decCheck.checked;

				if (isImg && !isDec) {
					const altVal = altInput ? altInput.value.trim() : '';
					if (!altVal) {
						e.preventDefault();
						altInput.style.borderColor = 'var(--admin-danger, ##ef4444)';
						altInput.style.boxShadow = '0 0 0 3px rgba(239, 68, 68, 0.2)';
						altInput.focus();
						if (window.showToast) {
							window.showToast('WCAG 1.1.1 Requirement: Alternative Text (Image Description) is mandatory for all images.', 'error');
						} else if (window.adminAlert) {
							window.adminAlert({
								title: 'WCAG 1.1.1 Requirement Missing',
								message: 'Alternative Text is mandatory for all images under County ADA Title II policy. Please enter a description of the image for screen readers, or check decorative if presentation-only.',
								type: 'warning'
							});
						}
						return false;
					}

					// Generic alt check
					const lowerAlt = altVal.toLowerCase();
					const generic = ['image', 'photo', 'picture', 'graphic', 'img', 'pic', 'file', 'screenshot'];
					if (generic.includes(lowerAlt) || lowerAlt.endsWith('.jpg') || lowerAlt.endsWith('.png') || lowerAlt.endsWith('.webp')) {
						e.preventDefault();
						altInput.style.borderColor = 'var(--admin-danger, ##ef4444)';
						altInput.style.boxShadow = '0 0 0 3px rgba(239, 68, 68, 0.2)';
						altInput.focus();
						if (window.showToast) {
							window.showToast('Generic alt text like "' + altVal + '" or filenames are not permitted. Please describe the image content.', 'error');
						}
						return false;
					}
				}
			});
		}

		updatePathPreview();
	});
</script>
