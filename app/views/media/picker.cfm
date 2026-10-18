<!--- CMSAdmin 2.0 - Media Library File Explorer Picker --->
<cfparam name="variables.activeWsFolder" default="community-development">
<cfparam name="variables.activeWsVirtualDir" default="#variables.activeWsFolder#">
<cfparam name="variables.activeWsName" default="#variables.activeWsFolder#">
<cfparam name="variables.pickerMode" default="document">
<cfparam name="variables.initialSubfolder" default="documents">
<cfparam name="variables.callback" default="onMediaSelected">
<cfparam name="variables.targetInput" default="">
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Select Media Asset - Chelan County CMS</title>
	<link rel="stylesheet" href="/stylesheets/admin-theme.css?v=3.0">
	<link rel="stylesheet" href="/stylesheets/filexplorer/explorer.css?v=2.8">
	<style>
		body {
			background: #f8fafc;
			margin: 0;
			padding: 0;
			font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
		}
		.filexplorer-scope {
			border: none;
			border-radius: 0;
			box-shadow: none;
		}
		.filexplorer-scope .layout {
			min-height: 100vh;
			grid-template-columns: 260px minmax(0, 1fr);
		}
		.filexplorer-scope .fx-content-grid {
			display: grid;
			grid-template-columns: minmax(0, 6fr) minmax(260px, 3fr);
			gap: 16px;
			align-items: start;
		}
		@media (max-width: 960px) {
			.filexplorer-scope .fx-content-grid {
				grid-template-columns: minmax(0, 1fr);
			}
		}
		@media (max-width: 720px) {
			.filexplorer-scope .layout {
				grid-template-columns: minmax(0, 1fr);
			}
		}
	</style>
</head>
<body>
<cfoutput>
<div class="filexplorer-scope admin-card"
     id="filexplorer-container"
     data-ws="#encodeForHTMLAttribute(variables.activeWsFolder)#"
     data-ws-virtual-dir="#encodeForHTMLAttribute(variables.activeWsVirtualDir)#"
     data-ws-name="#encodeForHTMLAttribute(variables.activeWsName)#"
     data-initial-folder="#encodeForHTMLAttribute(variables.initialSubfolder)#"
     data-picker-mode="#encodeForHTMLAttribute(variables.pickerMode)#"
     data-picker-callback="#encodeForHTMLAttribute(variables.callback)#"
     data-target-input="#encodeForHTMLAttribute(variables.targetInput)#">

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

			<!-- Inline upload-file panel -->
			<form id="upload-panel" class="panel upload-panel" hidden novalidate enctype="multipart/form-data">
				<div class="upload-row" style="display:flex; flex-direction:column; gap:0.75rem; padding:0.5rem 0;">
					<div style="display:flex; align-items:center; gap:0.75rem; flex-wrap:wrap;">
						<label for="upload-file-input" class="new-label" style="font-weight:700; font-size:0.85rem; color:var(--admin-text-main); white-space:nowrap;">Select File:</label>
						<input type="file" id="upload-file-input" class="input" style="flex:1; min-width:220px;" required>
						<button type="submit" id="btn-do-upload" class="btn btn-primary" style="display:inline-flex; align-items:center; gap:0.35rem;">
							<svg viewBox="0 0 24 24" aria-hidden="true" style="width:16px; height:16px; stroke:currentColor; stroke-width:2; fill:none;"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
							<span>Upload Now</span>
						</button>
						<button type="button" id="btn-upload-cancel" class="btn btn-secondary">Cancel</button>
					</div>

					<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.75rem;">
						<div>
							<label for="upload-alt-input" style="display:block; font-size:0.78rem; font-weight:600; color:var(--admin-text-muted); margin-bottom:0.25rem;">
								Alternative Text (WCAG 1.1.1):
							</label>
							<input type="text" id="upload-alt-input" class="input" style="width:100%;" placeholder="Describe image for screen readers...">
						</div>
						<div>
							<label for="upload-title-input" style="display:block; font-size:0.78rem; font-weight:600; color:var(--admin-text-muted); margin-bottom:0.25rem;">
								Display Title:
							</label>
							<input type="text" id="upload-title-input" class="input" style="width:100%;" placeholder="Optional title (auto-fills from filename)">
						</div>
					</div>

					<div style="display:flex; justify-content:space-between; align-items:center; font-size:0.78rem; color:var(--admin-text-muted);">
						<span id="upload-destination-preview" class="mono"></span>
						<a href="/media/upload" target="_blank" rel="noopener" id="link-full-upload-studio" style="color:var(--admin-primary); font-weight:600; text-decoration:none;">Open Full Upload Studio &rarr;</a>
					</div>
					<div id="upload-error" class="new-error" role="alert" style="color:var(--admin-danger); font-size:0.8rem;"></div>
				</div>
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
</div>

<script src="/javascripts/filexplorer/explorer.js?v=2.9"></script>
</cfoutput>
</body>
</html>
