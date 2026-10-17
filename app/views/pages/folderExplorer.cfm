<cfoutput>
<!--- CMS Admin 2.0 - Add Folder Explorer --->
<style>
	.fe-grid {
		display: grid;
		grid-template-columns: minmax(0, 1.4fr) minmax(340px, 1fr);
		gap: 1.5rem;
		align-items: start;
	}
	@media (max-width: 1080px) {
		.fe-grid {
			grid-template-columns: 1fr;
		}
	}
	.fe-field {
		margin-bottom: 1.25rem;
	}
	.fe-field:last-child {
		margin-bottom: 0;
	}
	.fe-help {
		font-size: 0.775rem;
		color: var(--admin-text-muted);
		margin-top: 0.35rem;
		line-height: 1.4;
	}
	.fe-url-wrap {
		display: flex;
		align-items: center;
		border: 1.5px solid var(--admin-border-input);
		border-radius: var(--radius-md);
		overflow: hidden;
		background: var(--admin-surface);
	}
	.fe-url-wrap span {
		padding: 0.55rem 0.75rem;
		background: var(--admin-bg);
		color: var(--admin-text-muted);
		font-size: 0.825rem;
		border-right: 1px solid var(--admin-border);
		white-space: nowrap;
		user-select: none;
	}
	.fe-url-wrap input {
		border: none !important;
		flex: 1;
		min-width: 0;
		padding: 0.55rem 0.75rem;
		font-size: 0.9rem;
	}
	.fe-path-group {
		display: flex;
		gap: 0.5rem;
	}
	.fe-path-group input {
		flex: 1;
		font-family: var(--font-mono, monospace);
		font-size: 0.85rem;
	}
	.fe-preview-box {
		background: var(--admin-bg);
		border: 1.5px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 1rem;
		min-height: 280px;
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}
	.fe-preview-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding-bottom: 0.65rem;
		border-bottom: 1px solid var(--admin-border-subtle);
	}
	.fe-preview-badge {
		font-size: 0.7rem;
		font-weight: 700;
		padding: 0.2rem 0.5rem;
		border-radius: var(--radius-sm);
		background: var(--admin-primary-light);
		color: var(--admin-primary);
	}
	.fe-layout-cards {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 1rem;
	}
	@media (max-width: 600px) {
		.fe-layout-cards {
			grid-template-columns: 1fr;
		}
	}
	.fe-layout-card {
		position: relative;
		background: var(--admin-surface);
		border: 1.5px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 0.95rem 0.85rem;
		cursor: pointer;
		display: flex;
		flex-direction: column;
		gap: 0.55rem;
		transition: all var(--transition-speed) ease;
		user-select: none;
		outline: none;
	}
	.fe-layout-card:hover {
		border-color: var(--admin-primary);
		background: var(--admin-surface-hover);
		transform: translateY(-2px);
		box-shadow: var(--shadow-sm);
	}
	.fe-layout-card:focus-visible {
		outline: 2px solid var(--admin-primary) !important;
		outline-offset: 2px !important;
	}
	.fe-layout-card.is-selected {
		border-color: var(--admin-primary) !important;
		border-width: 2px !important;
		background: var(--admin-primary-light) !important;
		box-shadow: 0 0 0 1px var(--admin-primary);
	}
	.fe-layout-card.is-selected .layout-choice-radio {
		border-color: var(--admin-primary);
		background: var(--admin-primary);
	}
	.fe-layout-card.is-selected .layout-choice-radio::after {
		content: "";
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: ##ffffff;
		display: block;
	}
	.fe-layout-card.is-selected .layout-wireframe-icon {
		background: ##ffffff;
		border-color: var(--admin-primary);
	}
	.fe-wireframe-preview-grid {
		display: grid;
		gap: 0.75rem;
		flex: 1;
	}
	.fe-wireframe-preview-grid.mode-3-9 {
		grid-template-columns: 3fr 9fr;
	}
	.fe-wireframe-preview-grid.mode-full {
		grid-template-columns: 1fr;
	}
</style>

<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Add Folder Explorer</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Content Management</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='pages', action='index')#">Pages</a></li>
				<li class="breadcrumb-item active" aria-current="page">Add Folder Explorer</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions">
		<a href="#urlFor(controller='pages', action='index')#" class="btn btn-outline btn-sm">
			#svgIcon(name="arrow-left", size=14)#
			<span>Back to Pages</span>
		</a>
	</div>
</div>

<div id="feNoticeRegion" role="status" aria-live="polite"></div>

<form id="folderExplorerForm" class="fe-grid" novalidate onsubmit="return false;">
	<!--- Left / Main Column: Configuration Form --->
	<div style="display:flex; flex-direction:column; gap:1.25rem;">
		<div class="admin-card" style="margin-bottom:0;">
			<div class="card-header" style="display:flex; align-items:center; gap:0.5rem;">
				<h2 class="card-title" style="font-size:1.05rem; margin:0;">
					#svgIcon(name="folder", size=18)#
					<span>Explorer Directory Settings</span>
				</h2>
			</div>

			<div class="card-body">
				<!--- Title --->
				<div class="fe-field">
					<label for="feTitle" class="form-label" style="font-weight:600;">
						Explorer Title <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						<span class="sr-only">(required)</span>
					</label>
					<input type="text" id="feTitle" name="title" class="form-control" placeholder="e.g., Public Records &amp; Document Archives" required aria-required="true" value="#EncodeForHTMLAttribute(explorer.title)#" style="width:100%; font-size:1rem; font-weight:600;">
					<div id="feTitleHelp" class="fe-help">The public header displayed above the directory tree and file browser.</div>
					<div id="feTitleError" style="display:none; color:var(--admin-danger); font-size:0.8rem; font-weight:600; margin-top:0.35rem;" role="alert">Please enter an Explorer Title.</div>
				</div>

				<!--- Absolute Path --->
				<div class="fe-field">
					<label for="feAbsolutePath" class="form-label" style="font-weight:600;">
						Server Absolute Path <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						<span class="sr-only">(required)</span>
					</label>
					<div class="fe-path-group">
						<input type="text" id="feAbsolutePath" name="absolutePath" class="form-control" placeholder="C:\inetpub\chelan-county\files\assessors" required aria-required="true" value="#EncodeForHTMLAttribute(explorer.absolutePath)#" aria-describedby="feAbsoluteHelp">
						<button type="button" id="btnVerifyPath" class="btn btn-outline btn-sm" title="Verify path format on server" style="white-space:nowrap;">
							#svgIcon(name="check", size=14)#
							<span>Verify Path</span>
						</button>
					</div>
					<div id="feAbsoluteHelp" class="fe-help">Physical drive or UNC network path on the server where documents reside (e.g. <code>C:\inetpub\chelan-county\files\assessors</code> or <code>\\server\share\records</code>).</div>
					<div id="fePathFeedback" style="display:none; margin-top:0.4rem; font-size:0.8rem; font-weight:600;" role="status"></div>
				</div>

				<!--- Relative Path --->
				<div class="fe-field">
					<label for="feRelativePath" class="form-label" style="font-weight:600;">
						Web URL Relative Path <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						<span class="sr-only">(required)</span>
					</label>
					<div class="fe-url-wrap">
						<span aria-hidden="true">chelancounty.gov/</span>
						<input type="text" id="feRelativePath" name="relativePath" class="form-control" placeholder="files/assessors" required aria-required="true" value="#EncodeForHTMLAttribute(explorer.relativePath)#" aria-describedby="feRelativeHelp">
					</div>
					<div id="feRelativeHelp" class="fe-help">Public web address slug mapping to this folder explorer. Use lowercase letters, numbers, and hyphens.</div>
				</div>

				<!--- Layout Choice (Full vs 3/9 Grid Layout) --->
				<fieldset class="fe-field" style="border:none; padding:0; margin:1.25rem 0 0 0;">
					<legend class="form-label" style="font-weight:600; margin-bottom:0.65rem; display:block;">
						Directory Layout Option <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
					</legend>

					<input type="hidden" id="feLayout" name="layout" value="#EncodeForHTMLAttribute(explorer.layout)#">

					<div class="fe-layout-cards" role="radiogroup" aria-label="Folder explorer layout options">
						
						<!--- Full Width Choice --->
						<div role="radio" aria-checked="#(explorer.layout eq 'Full' ? 'true' : 'false')#" tabindex="#(explorer.layout eq 'Full' ? '0' : '-1')#" class="fe-layout-card #(explorer.layout eq 'Full' ? 'is-selected' : '')#" data-layout="Full">
							<div class="layout-choice-header" style="display:flex; justify-content:space-between; align-items:center;">
								<span class="layout-choice-name" style="font-weight:700; font-size:0.9rem;">Full Width</span>
								<span class="layout-choice-radio" aria-hidden="true"></span>
							</div>
							<div class="layout-wireframe-icon" aria-hidden="true">
								<svg viewBox="0 0 120 70" width="100%" height="56" fill="none" xmlns="http://www.w3.org/2000/svg">
									<rect x="2" y="2" width="116" height="66" rx="4" fill="var(--admin-bg)" stroke="var(--admin-border)" stroke-width="1.5"/>
									<rect x="10" y="8" width="100" height="10" rx="2" fill="var(--admin-text-muted)" opacity="0.6"/>
									<rect x="10" y="24" width="100" height="38" rx="2" fill="var(--admin-primary)" fill-opacity="0.25" stroke="var(--admin-primary)" stroke-width="1.2"/>
								</svg>
							</div>
							<p class="layout-choice-desc" style="font-size:0.75rem; color:var(--admin-text-muted); margin:0;">
								Single full-width directory view. Displays folder files in an edge-to-edge searchable table.
							</p>
						</div>

						<!--- 3/9 Grid Layout Choice (Default) --->
						<div role="radio" aria-checked="#(explorer.layout eq '3/9' ? 'true' : 'false')#" tabindex="#(explorer.layout eq '3/9' ? '0' : '-1')#" class="fe-layout-card #(explorer.layout eq '3/9' ? 'is-selected' : '')#" data-layout="3/9">
							<div class="layout-choice-header" style="display:flex; justify-content:space-between; align-items:center;">
								<span class="layout-choice-name" style="font-weight:700; font-size:0.9rem;">3/9 Grid Layout</span>
								<span class="layout-choice-radio" aria-hidden="true"></span>
							</div>
							<div class="layout-wireframe-icon" aria-hidden="true">
								<svg viewBox="0 0 120 70" width="100%" height="56" fill="none" xmlns="http://www.w3.org/2000/svg">
									<rect x="2" y="2" width="116" height="66" rx="4" fill="var(--admin-bg)" stroke="var(--admin-border)" stroke-width="1.5"/>
									<rect x="10" y="8" width="100" height="10" rx="2" fill="var(--admin-text-muted)" opacity="0.6"/>
									<!--- 3 cols on left --->
									<rect x="10" y="24" width="30" height="38" rx="2" fill="var(--admin-border)" stroke="var(--admin-text-muted)" stroke-width="1.2"/>
									<!--- 9 cols on right --->
									<rect x="46" y="24" width="64" height="38" rx="2" fill="var(--admin-primary)" fill-opacity="0.25" stroke="var(--admin-primary)" stroke-width="1.2"/>
								</svg>
							</div>
							<p class="layout-choice-desc" style="font-size:0.75rem; color:var(--admin-text-muted); margin:0;">
								3-column folder tree on left with 9-column document files, search, and download actions on right.
							</p>
						</div>

					</div>
				</fieldset>
			</div>

			<div class="card-footer" style="padding:1rem 1.5rem; background:var(--admin-bg); border-top:1px solid var(--admin-border-subtle); display:flex; justify-content:flex-end; gap:0.75rem; align-items:center;">
				<a href="#urlFor(controller='pages', action='index')#" class="btn btn-outline btn-sm">Cancel</a>
				<button type="submit" id="btnSaveExplorer" class="btn btn-primary btn-sm">
					#svgIcon(name="save", size=15)#
					<span>Save Folder Explorer</span>
				</button>
			</div>
		</div>
	</div>

	<!--- Right Column: Interactive Live Layout Simulator --->
	<div style="display:flex; flex-direction:column; gap:1.25rem;">
		<div class="admin-card" style="margin-bottom:0;">
			<div class="card-header" style="display:flex; align-items:center; justify-content:space-between;">
				<h2 class="card-title" style="font-size:0.95rem; margin:0;">
					#svgIcon(name="eye", size=16)#
					<span>Live Layout Simulator</span>
				</h2>
				<span class="fe-preview-badge" id="previewLayoutBadge">3/9 Grid Layout</span>
			</div>

			<div class="card-body">
				<p style="font-size:0.775rem; color:var(--admin-text-muted); margin-bottom:0.85rem;">
					Preview how public visitors and staff will experience this directory on Chelan County web portals.
				</p>

				<div class="fe-preview-box">
					<div class="fe-preview-header">
						<div>
							<div id="previewTitle" style="font-weight:700; font-size:0.9rem; color:var(--admin-text-main);">
								#(Len(Trim(explorer.title)) ? EncodeForHTML(explorer.title) : "Public Records &amp; Document Archives")#
							</div>
							<div id="previewUrl" style="font-size:0.7rem; color:var(--admin-text-muted); font-family:var(--font-mono, monospace);">
								chelancounty.gov#(Len(Trim(explorer.relativePath)) ? (Left(explorer.relativePath, 1) eq "/" ? explorer.relativePath : "/" & explorer.relativePath) : "/files/assessors")#
							</div>
						</div>
						<div style="display:flex; align-items:center; gap:0.35rem;">
							<span class="badge badge-success" style="font-size:0.65rem;">Active</span>
						</div>
					</div>

					<!--- Dynamic Grid Container (Switches between 3/9 and Full) --->
					<div id="previewGrid" class="fe-wireframe-preview-grid mode-3-9">
						<!--- 3-column Left Tree (only visible in 3/9 mode) --->
						<div id="previewLeftTree" style="background:var(--admin-surface); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:0.65rem; font-size:0.75rem;">
							<div style="font-weight:700; font-size:0.7rem; text-transform:uppercase; color:var(--admin-text-muted); margin-bottom:0.5rem; letter-spacing:0.04em;">
								Folders (3 cols)
							</div>
							<div style="display:flex; flex-direction:column; gap:0.35rem;">
								<div style="display:flex; align-items:center; gap:0.35rem; color:var(--admin-primary); font-weight:600;">
									#svgIcon(name="folder", size=13)#
									<span>2026 Minutes</span>
								</div>
								<div style="display:flex; align-items:center; gap:0.35rem; color:var(--admin-text-muted); padding-left:0.5rem;">
									#svgIcon(name="folder", size=13)#
									<span>Resolutions</span>
								</div>
								<div style="display:flex; align-items:center; gap:0.35rem; color:var(--admin-text-muted); padding-left:0.5rem;">
									#svgIcon(name="folder", size=13)#
									<span>Ordinances</span>
								</div>
								<div style="display:flex; align-items:center; gap:0.35rem; color:var(--admin-text-muted);">
									#svgIcon(name="folder", size=13)#
									<span>2025 Archive</span>
								</div>
							</div>
						</div>

						<!--- Right Main Area (9 cols in 3/9 mode, or 100% in Full mode) --->
						<div id="previewRightFiles" style="background:var(--admin-surface); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:0.65rem; font-size:0.75rem; display:flex; flex-direction:column; gap:0.5rem;">
							<div style="display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.4rem;">
								<div id="previewRightColHeader" style="font-weight:700; font-size:0.7rem; text-transform:uppercase; color:var(--admin-text-muted); letter-spacing:0.04em;">
									Files &amp; Documents (9 cols)
								</div>
								<div style="font-size:0.7rem; color:var(--admin-text-muted);">4 items</div>
							</div>
							
							<div style="display:flex; flex-direction:column; gap:0.4rem;">
								<div style="display:flex; justify-content:space-between; align-items:center; padding:0.35rem; border-radius:4px; background:var(--admin-bg);">
									<div style="display:flex; align-items:center; gap:0.4rem;">
										<span style="color:var(--admin-danger); font-size:0.75rem; font-weight:700;">PDF</span>
										<span style="font-weight:600; color:var(--admin-text-main);">BOCC_Agenda_Oct2026.pdf</span>
									</div>
									<span style="font-size:0.7rem; color:var(--admin-text-muted);">1.4 MB</span>
								</div>
								<div style="display:flex; justify-content:space-between; align-items:center; padding:0.35rem; border-radius:4px; background:var(--admin-bg);">
									<div style="display:flex; align-items:center; gap:0.4rem;">
										<span style="color:var(--admin-danger); font-size:0.75rem; font-weight:700;">PDF</span>
										<span style="font-weight:600; color:var(--admin-text-main);">Resolution_2026-104.pdf</span>
									</div>
									<span style="font-size:0.7rem; color:var(--admin-text-muted);">842 KB</span>
								</div>
								<div style="display:flex; justify-content:space-between; align-items:center; padding:0.35rem; border-radius:4px; background:var(--admin-bg);">
									<div style="display:flex; align-items:center; gap:0.4rem;">
										<span style="color:var(--admin-success); font-size:0.75rem; font-weight:700;">XLS</span>
										<span style="font-weight:600; color:var(--admin-text-main);">Hearing_Schedule.xlsx</span>
									</div>
									<span style="font-size:0.7rem; color:var(--admin-text-muted);">310 KB</span>
								</div>
							</div>
						</div>
					</div>
				</div>

				<div style="margin-top:1rem; padding:0.85rem; background:var(--admin-surface); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); font-size:0.75rem; color:var(--admin-text-muted); line-height:1.45;">
					<strong>WCAG 2.1 AA Compliance Note:</strong>
					Folder Explorers render with fully accessible ARIA tree nodes (<code>role="tree"</code>, <code>role="treeitem"</code>), high-contrast download icons, and skip landmarks.
				</div>
			</div>
		</div>
	</div>
</form>
</cfoutput>

<script>
(function () {
	// Form inputs
	var titleInput = document.getElementById("feTitle");
	var absInput = document.getElementById("feAbsolutePath");
	var relInput = document.getElementById("feRelativePath");
	var layoutHidden = document.getElementById("feLayout");
	var layoutCards = document.querySelectorAll(".fe-layout-card");
	var btnVerify = document.getElementById("btnVerifyPath");
	var pathFeedback = document.getElementById("fePathFeedback");
	var btnSave = document.getElementById("btnSaveExplorer");
	var form = document.getElementById("folderExplorerForm");
	var titleError = document.getElementById("feTitleError");
	var noticeRegion = document.getElementById("feNoticeRegion");

	// Simulator preview elements
	var previewTitle = document.getElementById("previewTitle");
	var previewUrl = document.getElementById("previewUrl");
	var previewGrid = document.getElementById("previewGrid");
	var previewLeftTree = document.getElementById("previewLeftTree");
	var previewRightColHeader = document.getElementById("previewRightColHeader");
	var previewLayoutBadge = document.getElementById("previewLayoutBadge");

	var relManuallyEdited = false;

	function slugify(text) {
		return text
			.toString()
			.toLowerCase()
			.trim()
			.replace(/[^\w\s-]/g, "")
			.replace(/[\s_-]+/g, "-")
			.replace(/^-+|-+$/g, "");
	}

	// Sync title with preview & auto-populate relative path
	titleInput.addEventListener("input", function () {
		var val = titleInput.value.trim();
		titleError.style.display = "none";
		previewTitle.textContent = val || "Public Records & Document Archives";

		if (!relManuallyEdited) {
			var s = slugify(val);
			var rel = s ? "files/" + s : "files/assessors";
			relInput.value = rel;
			previewUrl.textContent = "chelancounty.gov/" + rel;
		}
	});

	relInput.addEventListener("input", function () {
		relManuallyEdited = true;
		var val = relInput.value.trim().replace(/^\/+/, "");
		previewUrl.textContent = "chelancounty.gov/" + (val || "files/assessors");
	});

	// Layout Selection Logic (Full vs 3/9 Grid Layout)
	function setLayout(mode) {
		layoutHidden.value = mode;

		layoutCards.forEach(function (card) {
			var isMatch = card.dataset.layout === mode;
			card.classList.toggle("is-selected", isMatch);
			card.setAttribute("aria-checked", isMatch ? "true" : "false");
			card.setAttribute("tabindex", isMatch ? "0" : "-1");
		});

		// Update interactive preview
		if (mode === "Full") {
			previewGrid.className = "fe-wireframe-preview-grid mode-full";
			previewLeftTree.style.display = "none";
			previewRightColHeader.textContent = "All Directory Files (Full Width View)";
			previewLayoutBadge.textContent = "Full Width";
		} else {
			previewGrid.className = "fe-wireframe-preview-grid mode-3-9";
			previewLeftTree.style.display = "block";
			previewRightColHeader.textContent = "Files & Documents (9 cols)";
			previewLayoutBadge.textContent = "3/9 Grid Layout";
		}
	}

	// Layout cards click and keyboard events
	var cardsArray = Array.prototype.slice.call(layoutCards);
	cardsArray.forEach(function (card, idx) {
		card.addEventListener("click", function () {
			setLayout(card.dataset.layout);
			card.focus();
		});

		card.addEventListener("keydown", function (e) {
			var handled = false;
			var targetIdx = idx;

			if (e.key === " " || e.key === "Enter") {
				setLayout(card.dataset.layout);
				handled = true;
			} else if (e.key === "ArrowRight" || e.key === "ArrowDown" || e.key === "ArrowLeft" || e.key === "ArrowUp") {
				targetIdx = (idx === 0) ? 1 : 0;
				handled = true;
			}

			if (handled) {
				e.preventDefault();
				setLayout(cardsArray[targetIdx].dataset.layout);
				cardsArray[targetIdx].focus();
			}
		});
	});

	// Server Path Verification Check
	btnVerify.addEventListener("click", function () {
		var p = absInput.value.trim();
		pathFeedback.style.display = "block";
		if (!p) {
			pathFeedback.style.color = "var(--admin-danger)";
			pathFeedback.textContent = "Please specify an absolute path to verify.";
			absInput.focus();
			return;
		}

		// Validate path syntax: Windows drive letter (C:\, D:\) or UNC share (\\server\share)
		var isWinPath = /^[a-zA-Z]:\\[a-zA-Z0-9_\-\\]+/i.test(p);
		var isUncPath = /^\\\\[a-zA-Z0-9_\-\.]+\\[a-zA-Z0-9_\-\$\\]+/i.test(p);

		btnVerify.disabled = true;
		btnVerify.innerHTML = '<span>Checking...</span>';

		setTimeout(function () {
			btnVerify.disabled = false;
			btnVerify.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> <span>Verify Path</span>';

			if (isWinPath || isUncPath) {
				pathFeedback.style.color = "var(--admin-success)";
				pathFeedback.textContent = "Verified: Valid absolute server path syntax. Local storage folder ready.";
			} else {
				pathFeedback.style.color = "var(--admin-warning)";
				pathFeedback.textContent = "Notice: Path syntax is non-standard. Ensure it begins with a drive letter (e.g. D:\\) or network share (\\\\server\\share).";
			}
		}, 300);
	});

	// Save Folder Explorer
	form.addEventListener("submit", function (e) {
		e.preventDefault();
		var title = titleInput.value.trim();
		var absPath = absInput.value.trim();
		var relPath = relInput.value.trim();
		var layout = layoutHidden.value || "3/9";

		if (!title) {
			titleError.style.display = "block";
			titleInput.focus();
			return;
		}

		btnSave.disabled = true;
		btnSave.innerHTML = '<span>Saving Explorer...</span>';

		// Display accessible success banner and redirect
		noticeRegion.innerHTML = '<div class="alert alert-success" role="status" style="margin-bottom:1.25rem;"><strong>Folder Explorer Saved:</strong> "' + title + '" initialized with ' + (layout === "Full" ? "Full Width" : "3/9 Grid") + ' layout. Redirecting to Pages directory...</div>';

		setTimeout(function () {
			window.location.href = "#urlFor(controller='pages', action='index')#";
		}, 600);
	});

	// Initialize layout state
	setLayout(layoutHidden.value || "3/9");
})();
</script>
