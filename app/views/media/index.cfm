<!--- CMSAdmin 2.0 - Media Library File Explorer --->
<cfparam name="variables.activeWsFolder" default="community-development">
<cfparam name="variables.activeWsVirtualDir" default="#variables.activeWsFolder#">
<cfparam name="variables.activeWsName" default="#variables.activeWsFolder#">
<cfparam name="variables.activeWsStoragePath" default="C:\inetpub\chelan-county\files\#variables.activeWsFolder#">
<cfparam name="variables.activeWsDiskPath" default="C:\inetpub\chelan-county\files\#variables.activeWsFolder#">
<cfparam name="variables.activeWsAssetsPath" default="assets.chelancounty.gov\#variables.activeWsFolder#">
<cfoutput>
<link rel="stylesheet" href="/stylesheets/filexplorer/explorer.css?v=4.1">

<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Media Library</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item active" aria-current="page">Media Library</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="#urlFor(controller='media', action='upload', params='ws=' & variables.activeWsFolder)#" class="btn btn-primary btn-sm" id="btnHeaderUpload">
			#svgIcon(name="upload", size=15)#
			<span>Upload Media</span>
		</a>
	</div>
</div>

<div class="filexplorer-scope admin-card"
     id="filexplorer-container"
     data-ws="#encodeForHTMLAttribute(variables.activeWsFolder)#"
     data-ws-virtual-dir="#encodeForHTMLAttribute(variables.activeWsVirtualDir)#"
     data-ws-storage-path="#encodeForHTMLAttribute(variables.activeWsStoragePath)#"
     data-ws-disk-path="#encodeForHTMLAttribute(variables.activeWsDiskPath)#"
     data-ws-assets-path="#encodeForHTMLAttribute(variables.activeWsAssetsPath)#"
     data-ws-name="#encodeForHTMLAttribute(variables.activeWsName)#">

	<div id="offline-banner" class="offline-banner" role="alert" hidden>
		<span>The file server is not responding. Changes are disabled until the connection is restored.</span>
		<button type="button" id="btn-retry" class="btn btn-small">Retry</button>
	</div>

	<div class="layout">
		<!-- Left column: Server Folders tree -->
		<nav class="panel tree-panel" aria-label="Server folders">
			<div class="panel-title">SERVER FOLDERS</div>
			<ul id="tree" class="tree" role="list"></ul>
		</nav>

		<!-- Main column -->
		<main class="main" id="main">
			<div class="panel pathbar">
				<button type="button" id="btn-up" class="btn btn-icon" aria-label="Up one level" disabled>
					<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 19V5M5 12l7-7 7 7"/></svg>
				</button>
				<nav class="crumbs mono" id="crumbs" aria-label="Current path"></nav>
				<div class="pathbar-tools">
					<label class="filter">
						<span class="sr-only">Filter this folder by name</span>
						<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/></svg>
						<input type="search" id="filter" placeholder="Filter" autocomplete="off">
					</label>
					<button type="button" id="btn-upload" class="btn btn-primary" title="Upload files to this folder">
						<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
						<span>Upload</span>
					</button>
					<button type="button" id="btn-new" class="btn btn-secondary" disabled>
						<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM12 10v6M9 13h6"/></svg>
						<span>New folder</span>
					</button>
					<div class="view-toggle" role="group" aria-label="View mode">
						<button type="button" id="btn-grid" class="btn btn-icon" aria-label="Grid view" aria-pressed="true">
							<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="4" y="4" width="7" height="7" rx="1"/><rect x="13" y="4" width="7" height="7" rx="1"/><rect x="4" y="13" width="7" height="7" rx="1"/><rect x="13" y="13" width="7" height="7" rx="1"/></svg>
						</button>
						<button type="button" id="btn-list" class="btn btn-icon" aria-label="List view" aria-pressed="false">
							<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"/></svg>
						</button>
					</div>
					<div id="conn" class="conn conn-connecting" role="status" aria-live="polite">
						<span class="conn-dot" aria-hidden="true"></span>
						<span id="conn-text">Connecting&hellip;</span>
					</div>
				</div>
			</div>

			<!-- Inline new-folder panel -->
			<form id="new-panel" class="panel new-panel" hidden novalidate>
				<div class="new-row">
					<label for="new-name" class="new-label">New folder name</label>
					<input type="text" id="new-name" class="input" maxlength="64" autocomplete="off" spellcheck="false" aria-describedby="new-preview new-error">
					<button type="submit" id="btn-create" class="btn btn-primary">Create</button>
					<button type="button" id="btn-cancel" class="btn">Cancel</button>
				</div>
				<div class="new-preview mono" id="new-preview"></div>
				<div class="new-error" id="new-error" role="alert"></div>
			</form>

			<!-- Inline upload-file panel (CMSAdmin 2.0 Modern Studio Design) -->
			<form id="upload-panel" class="panel upload-panel admin-card" hidden novalidate enctype="multipart/form-data" aria-label="Quick file upload" style="padding:1.5rem; margin-bottom:1.5rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem; flex-wrap:wrap; gap:0.75rem;">
					<h3 style="margin:0; font-size:1.1rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
						#svgIcon(name="upload", size=18)# Quick Upload to Folder
					</h3>
					<div style="display:flex; align-items:center; gap:0.75rem; font-size:0.825rem;">
						<span id="upload-destination-preview" class="mono" style="color:var(--admin-text-muted); background:var(--admin-surface-hover, ##f8fafc); padding:0.25rem 0.65rem; border-radius:var(--radius-sm, 4px); border:1px solid var(--admin-border-subtle, ##e2e8f0);"></span>
						<a href="#urlFor(controller='media', action='upload', params='ws=' & variables.activeWsFolder)#" id="link-full-upload-studio" style="color:var(--admin-primary); font-weight:600; text-decoration:none;">Open Full Upload Studio &rarr;</a>
						<button type="button" id="btn-upload-close-icon" class="btn btn-icon btn-sm" aria-label="Close upload panel" title="Close (Esc)" style="border:none; background:transparent;">
							#svgIcon(name="x", size=16)#
						</button>
					</div>
				</div>

				<!--- Drag & Drop Image/File Container (Matching Reference Spec) --->
				<div id="upload-dropzone" class="media-upload-dropzone" role="button" tabindex="0"
				     style="border: 2px dashed ##0284c7; border-radius: 12px; padding: 2.25rem 1.5rem; text-align: center; background: ##f8fafc; cursor: pointer; transition: all 0.2s ease; position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 140px; outline: none; margin-bottom: 1rem;"
				     aria-label="Click to browse workspace media library or drag and drop files here" title="Click to browse workspace media library or drag and drop files here">
					<div id="upload-dropzone-prompt" class="media-dropzone-prompt" style="display: flex; flex-direction: column; align-items: center; justify-content: center; pointer-events: none;">
						<div style="color: ##0284c7; margin-bottom: 0.5rem; display: flex; align-items: center; justify-content: center;">
							#svgIcon(name="image", size=36)#
						</div>
						<div class="media-dropzone-title" style="font-size: 1.05rem; font-weight: 700; color: ##0f172a; margin-bottom: 0.25rem; letter-spacing: -0.01em;">Choose Cover Image / File</div>
						<div class="media-dropzone-sub" style="font-size: 0.825rem; color: ##64748b;">Click to browse workspace media library or drag and drop here</div>
					</div>

					<div id="upload-selected-card" class="media-selected-card" hidden style="display: flex; align-items: center; gap: 1rem; padding: 0.75rem 1rem; background: ##ffffff; border: 1.5px solid ##0284c7; border-radius: 8px; max-width: 520px; width: 100%; box-shadow: 0 2px 8px rgba(2, 132, 199, 0.08); position: relative; z-index: 6;">
						<div id="upload-selected-thumb" class="media-selected-thumb" style="width: 54px; height: 54px; border-radius: 6px; object-fit: cover; background: ##f1f5f9; border: 1px solid ##cbd5e1; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0;"></div>
						<div class="media-selected-info" style="flex: 1; min-width: 0; text-align: left;">
							<div id="upload-selected-name" class="media-selected-name" style="font-size: 0.875rem; font-weight: 700; color: ##0f172a; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"></div>
							<div id="upload-selected-meta" class="media-selected-meta" style="font-size: 0.75rem; color: ##64748b; margin-top: 0.15rem;"></div>
						</div>
						<button type="button" id="btn-remove-selected-file" class="btn btn-outline btn-xs" title="Change or remove selected file" style="position: relative; z-index: 7;">
							#svgIcon(name="x", size=12)#
							<span>Change</span>
						</button>
					</div>

					<input type="file" id="upload-file-input" name="mediaFile" class="media-file-native-input" tabindex="-1" aria-hidden="true" required style="position: absolute; inset: 0; width: 100%; height: 100%; opacity: 0; cursor: pointer; z-index: 5;">
				</div>

				<!--- Image URL & Browse Row (Directly below dropzone) --->
				<div class="media-url-browse-row" style="margin-top: 0.25rem;">
					<label for="upload-target-url-input" class="media-url-label" style="display: block; font-size: 0.85rem; font-weight: 600; color: ##334155; margin-bottom: 0.35rem;">
						Image URL
					</label>
					<div class="media-url-input-group" style="display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
						<input type="text" id="upload-target-url-input" class="form-control media-url-field" placeholder="/files/#encodeForHTMLAttribute(variables.activeWsFolder)#/images/photo.jpg" readonly title="Prospective URL destination on server" style="flex: 1; min-width: 240px; border: 1.5px solid ##cbd5e1 !important; border-radius: 8px !important; padding: 0.6rem 0.85rem !important; font-size: 0.875rem !important; background: ##ffffff !important; color: ##0f172a !important;">
						<button type="button" id="btn-browse-file" class="btn media-btn-browse" title="Browse files on your computer" style="display: inline-flex; align-items: center; gap: 0.45rem; padding: 0.6rem 1.15rem; border: 1.5px solid ##cbd5e1 !important; border-radius: 8px !important; background: ##f1f5f9 !important; font-weight: 600; font-size: 0.875rem; color: ##0f172a !important; cursor: pointer; white-space: nowrap;">
							#svgIcon(name="folder", size=15)#
							<span>Browse</span>
						</button>
						<button type="submit" id="btn-do-upload" class="btn btn-primary media-btn-upload" style="display: inline-flex; align-items: center; gap: 0.45rem; padding: 0.6rem 1.25rem !important; border-radius: 8px !important; font-weight: 600; font-size: 0.875rem; white-space: nowrap;">
							<svg id="btn-do-upload-icon" viewBox="0 0 24 24" aria-hidden="true" style="width:15px; height:15px; stroke:currentColor; stroke-width:2; fill:none;"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
							<svg id="btn-do-upload-spinner" class="fx-spinner" viewBox="0 0 24 24" aria-hidden="true" hidden style="display:none !important; width:15px; height:15px; stroke:currentColor; fill:none; stroke-width:2.5;"><circle cx="12" cy="12" r="10" stroke-opacity="0.25"/><path d="M12 2a10 10 0 0 1 10 10"/></svg>
							<span id="btn-do-upload-text">Upload Now</span>
						</button>
						<button type="button" id="btn-upload-cancel" class="btn btn-outline" style="padding:0.6rem 1rem; border-radius:8px; font-size:0.875rem;">Cancel</button>
					</div>
				</div>

				<!--- Accessibility & Search Metadata --->
				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem; margin-top:1.25rem;">
					<div>
						<label for="upload-alt-input" class="form-label" style="font-weight:600; font-size:0.85rem; display:flex; justify-content:space-between; align-items:center;">
							<span>Alternative Text (WCAG 1.1.1) <span id="upload-alt-required-badge" style="color:var(--admin-danger, ##ef4444); font-weight:700;">* Required</span></span>
							<span style="font-size:0.72rem; color:var(--admin-primary); font-weight:600;">ADA Title II</span>
						</label>
						<input type="text" id="upload-alt-input" class="form-control" style="font-size:0.875rem; transition:border-color 0.2s, box-shadow 0.2s;" placeholder="Describe image for screen readers (required for photos &amp; graphics)...">
						<small style="color:var(--admin-text-muted); font-size:0.75rem; margin-top:0.25rem; display:block;">Mandatory for County public compliance. Describe subjects, actions, and text visible in graphic.</small>
					</div>
					<div>
						<label for="upload-title-input" class="form-label" style="font-weight:600; font-size:0.85rem;">
							Display Title
						</label>
						<input type="text" id="upload-title-input" class="form-control" style="font-size:0.875rem;" placeholder="Optional title (auto-fills from filename)">
						<small style="color:var(--admin-text-muted); font-size:0.75rem; margin-top:0.25rem; display:block;">Human-readable asset title used for catalog searches.</small>
					</div>
				</div>

				<div id="upload-error" class="new-error" role="alert" style="color:var(--admin-danger); font-size:0.825rem; margin-top:0.75rem;" hidden></div>
			</form>

			<div class="subbar">
				<span id="summary">&nbsp;</span>
				<span id="level-hint" class="muted"></span>
			</div>

			<!-- 6x3 Grid: Folder contents (6-grid) + Document details (3-grid) -->
			<div class="fx-content-grid">
				<section id="content" class="panel content" tabindex="-1" aria-label="Folder contents">
					<div id="items" class="items"></div>
				</section>

				<aside class="panel details" id="details" aria-label="Details" aria-live="polite"></aside>
			</div>
		</main>
	</div>

	<div id="toast" class="toast" role="status" aria-live="polite" hidden></div>

	<!--- Modal: Edit Media Asset Metadata & WCAG Accessibility --->
	<div id="mediaEditMetaModal" class="modal-backdrop" hidden style="position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:9999; padding:1rem;" role="dialog" aria-modal="true" aria-labelledby="mediaEditMetaModalTitle">
		<div class="admin-card" style="max-width:580px; width:100%; border-radius:12px; box-shadow:0 20px 25px -5px rgba(0,0,0,0.2); overflow:hidden; background:var(--admin-surface, ##fff);">
			<div class="card-header" style="padding:1.25rem 1.5rem; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--admin-border-subtle, ##e2e8f0);">
				<h3 id="mediaEditMetaModalTitle" style="margin:0; font-size:1.1rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="shield", size=18)#
					<span>Edit Image WCAG &amp; Metadata</span>
				</h3>
				<button type="button" class="btn btn-icon btn-sm" id="btn-close-edit-meta" aria-label="Close dialog" style="border:none; background:transparent; cursor:pointer;">
					#svgIcon(name="x", size=16)#
				</button>
			</div>
			<form id="mediaEditMetaForm" style="margin:0;">
				<input type="hidden" id="edit-meta-id" name="id" value="">
				<input type="hidden" id="edit-meta-path" name="path" value="">
				<div class="card-body" style="padding:1.5rem; max-height:75vh; overflow-y:auto;">
					<!--- Image Preview Row --->
					<div style="display:flex; align-items:center; gap:1rem; padding:0.75rem; background:var(--admin-bg, ##f8fafc); border-radius:8px; border:1px solid var(--admin-border-subtle, ##cbd5e1); margin-bottom:1.25rem;">
						<div id="edit-meta-thumb" style="width:60px; height:60px; border-radius:6px; background:##f1f5f9; overflow:hidden; display:flex; align-items:center; justify-content:center; flex-shrink:0; border:1px solid ##cbd5e1;"></div>
						<div style="flex:1; min-width:0;">
							<div id="edit-meta-filename" style="font-weight:700; font-size:0.875rem; color:var(--admin-text-main); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;"></div>
							<div id="edit-meta-fileinfo" class="mono" style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;"></div>
							<div id="edit-meta-wcag-badge" style="margin-top:4px;"></div>
						</div>
					</div>

					<!--- Alternative Text (Mandatory for WCAG 1.1.1) --->
					<div class="form-group" style="margin-bottom:1.25rem;">
						<label for="edit-meta-alt" class="form-label" style="font-weight:700; font-size:0.85rem; display:flex; justify-content:space-between; align-items:center;">
							<span>Alternative Text (Image Description) <span style="color:var(--admin-danger, ##ef4444);">* Required (WCAG 1.1.1)</span></span>
							<span style="font-size:0.72rem; color:var(--admin-primary); font-weight:600;">ADA Title II</span>
						</label>
						<textarea id="edit-meta-alt" name="altText" class="form-control" rows="3" style="width:100%; font-size:0.875rem;" placeholder="Describe what is seen in the image for blind and visually-impaired screen reader users..." required></textarea>
						<div id="edit-meta-alt-char" style="text-align:right; font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">0 / 150 rec.</div>
					</div>

					<!--- Display Title --->
					<div class="form-group" style="margin-bottom:1.25rem;">
						<label for="edit-meta-title" class="form-label" style="font-weight:600; font-size:0.85rem;">Display Title</label>
						<input type="text" id="edit-meta-title" name="title" class="form-control" style="font-size:0.875rem;" placeholder="Human-readable title">
					</div>

					<!--- Caption --->
					<div class="form-group" style="margin-bottom:1.25rem;">
						<label for="edit-meta-caption" class="form-label" style="font-weight:600; font-size:0.85rem;">Caption / Editorial Context</label>
						<input type="text" id="edit-meta-caption" name="caption" class="form-control" style="font-size:0.875rem;" placeholder="Optional visible caption or notes">
					</div>

					<!--- Attribution / Credit & Tags in 2-col --->
					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div class="form-group">
							<label for="edit-meta-credit" class="form-label" style="font-weight:600; font-size:0.85rem;">Photographer / Credit</label>
							<input type="text" id="edit-meta-credit" name="credit" class="form-control" style="font-size:0.875rem;" placeholder="e.g. County Assessor">
						</div>
						<div class="form-group">
							<label for="edit-meta-tags" class="form-label" style="font-weight:600; font-size:0.85rem;">Tags &amp; Keywords</label>
							<input type="text" id="edit-meta-tags" name="tags" class="form-control" style="font-size:0.875rem;" placeholder="comma, separated">
						</div>
					</div>

					<div id="edit-meta-error" role="alert" style="color:var(--admin-danger); font-size:0.825rem; margin-top:0.75rem;" hidden></div>
				</div>
				<div class="card-footer" style="padding:1rem 1.5rem; background:var(--admin-surface-hover, ##f8fafc); border-top:1px solid var(--admin-border-subtle, ##e2e8f0); display:flex; justify-content:flex-end; gap:0.5rem; align-items:center;">
					<button type="button" class="btn btn-outline" id="btn-cancel-edit-meta">Cancel</button>
					<button type="submit" class="btn btn-primary" id="btn-save-edit-meta">
						#svgIcon(name="check", size=15)#
						<span>Save WCAG Metadata</span>
					</button>
				</div>
			</form>
		</div>
	</div>
</div>

<script src="/javascripts/filexplorer/explorer.js?v=4.5"></script>
</cfoutput>
