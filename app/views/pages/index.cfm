<cfset pageTitle = "Content Manager">
<cfscript>
	cntTotal = ArrayLen(pages);
	cntPublished = 0; cntDraft = 0; cntMenu = 0; cntInactive = 0;
	for (p in pages) {
		if (p.visibility eq "Published") cntPublished++;
		if (p.visibility eq "Draft" or p.visibility eq "Scheduled") cntDraft++;
		if (p.menuItem) cntMenu++;
		if (p.status eq "Inactive") cntInactive++;
	}
	visBadge = { "Published": "badge-success", "Draft": "badge-neutral", "Scheduled": "badge-info", "Hidden": "badge-warning" };
</cfscript>
<cfoutput>
<!--- Add Page Modal Standalone Overlay Styles --->
<style>
.admin-modal-backdrop {
	position: fixed !important;
	top: 0 !important;
	left: 0 !important;
	right: 0 !important;
	bottom: 0 !important;
	width: 100vw !important;
	height: 100vh !important;
	background: rgba(15, 23, 42, 0.72) !important;
	backdrop-filter: blur(4px);
	-webkit-backdrop-filter: blur(4px);
	z-index: 99999 !important;
	display: none;
	align-items: center;
	justify-content: center;
	padding: 1.25rem;
	box-sizing: border-box;
}
.admin-modal-backdrop.open {
	display: flex !important;
}
.admin-modal-dialog {
	position: relative !important;
	background: var(--admin-surface, ##ffffff) !important;
	border: 1px solid var(--admin-border, ##cbd5e1);
	border-radius: var(--radius-lg, 0.75rem);
	box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.45);
	width: 100%;
	max-width: 780px;
	max-height: 90vh;
	display: flex;
	flex-direction: column;
	overflow: hidden;
	box-sizing: border-box;
	animation: modalSlideIn 0.2s cubic-bezier(0.16, 1, 0.3, 1);
	margin: auto;
}
.admin-modal-dialog form,
form.admin-modal-dialog {
	display: flex;
	flex-direction: column;
	flex: 1;
	min-height: 0;
	overflow: hidden;
}
@keyframes modalSlideIn {
	from { transform: translateY(12px) scale(0.98); opacity: 0; }
	to { transform: translateY(0) scale(1); opacity: 1; }
}
.admin-modal-header {
	flex-shrink: 0;
	padding: 1.15rem 1.5rem;
	border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
	display: flex;
	align-items: center;
	justify-content: space-between;
	background: linear-gradient(to bottom, ##ffffff, var(--admin-bg, ##f8fafc));
}
.admin-modal-title {
	font-family: var(--admin-font);
	font-size: 1.05rem !important;
	font-weight: 700;
	text-transform: uppercase !important;
	letter-spacing: 0.04em !important;
	color: var(--admin-text-main, ##0f172a);
	margin: 0;
	display: flex;
	align-items: center;
	gap: 0.5rem;
}
.admin-modal-close {
	background: transparent;
	border: none;
	font-size: 1.5rem;
	color: var(--admin-text-subtle, ##64748b);
	cursor: pointer;
	line-height: 1;
	padding: 0.25rem 0.5rem;
	border-radius: var(--radius-sm, 0.375rem);
	display: flex;
	align-items: center;
	justify-content: center;
}
.admin-modal-close:hover {
	color: var(--admin-text-main, ##0f172a);
	background: var(--admin-surface-hover, ##f1f5f9);
}
.admin-modal-body {
	padding: 1.5rem;
	overflow-y: auto;
	flex: 1;
	min-height: 0;
	-webkit-overflow-scrolling: touch;
}
.admin-modal-footer {
	flex-shrink: 0;
	padding: 1rem 1.5rem;
	border-top: 1px solid var(--admin-border-subtle, ##e2e8f0);
	background: var(--admin-bg, ##f8fafc);
	display: flex;
	align-items: center;
	justify-content: flex-end;
	gap: 0.75rem;
	position: sticky;
	bottom: 0;
	z-index: 10;
}
.layout-picker-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 1rem;
}
@media (max-width: 600px) {
	.layout-picker-grid {
		grid-template-columns: 1fr;
	}
}
.layout-choice-card {
	position: relative;
	background: var(--admin-surface, ##ffffff);
	border: 1.5px solid var(--admin-border, ##cbd5e1);
	border-radius: var(--radius-md, 0.5rem);
	padding: 0.85rem;
	cursor: pointer;
	display: flex;
	flex-direction: column;
	gap: 0.5rem;
	transition: all 0.15s ease;
	user-select: none;
	outline: none;
}
.layout-choice-card:hover {
	border-color: var(--admin-primary, ##0284c7);
	background: var(--admin-surface-hover, ##f8fafc);
	transform: translateY(-2px);
	box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}
.layout-choice-card:focus-visible {
	outline: 2px solid var(--admin-primary, ##0284c7) !important;
	outline-offset: 2px !important;
}
.layout-choice-card.is-selected {
	border-color: var(--admin-primary, ##0284c7) !important;
	border-width: 2px !important;
	background: var(--admin-primary-light, ##f0f9ff) !important;
	box-shadow: 0 0 0 1px var(--admin-primary, ##0284c7);
}
.layout-choice-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 0.5rem;
}
.layout-choice-radio {
	width: 18px;
	height: 18px;
	border-radius: 50%;
	border: 2px solid var(--admin-border-input, ##64748b);
	display: flex;
	align-items: center;
	justify-content: center;
	flex-shrink: 0;
}
.layout-choice-card.is-selected .layout-choice-radio {
	border-color: var(--admin-primary, ##0284c7);
	background: var(--admin-primary, ##0284c7);
}
.layout-choice-card.is-selected .layout-choice-radio::after {
	content: "";
	width: 6px;
	height: 6px;
	border-radius: 50%;
	background: ##ffffff;
	display: block;
}
.layout-wireframe-icon {
	width: 100%;
	height: 62px;
	background: var(--admin-bg, ##f8fafc);
	border: 1px solid var(--admin-border-subtle, ##e2e8f0);
	border-radius: var(--radius-sm, 0.375rem);
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 4px;
	box-sizing: border-box;
}
.layout-choice-card.is-selected .layout-wireframe-icon {
	background: ##ffffff;
	border-color: var(--admin-primary, ##0284c7);
}
.layout-choice-name {
	font-weight: 700;
	font-size: 0.85rem;
	color: var(--admin-text-main, ##0f172a);
}
.layout-choice-desc {
	font-size: 0.725rem;
	color: var(--admin-text-muted, ##475569);
	line-height: 1.35;
	margin: 0;
}
</style>

<!--- CMS Admin 2.0 - Content Manager --->
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Content Manager</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Content Management</li>
				<li class="breadcrumb-item active" aria-current="page">Content Manager</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="#urlFor(controller='pages', action='callToAction')#" class="btn btn-outline btn-sm">
			#svgIcon(name="cta", size=15)#
			<span>Call to Action Studio</span>
		</a>
		<a href="#urlFor(controller='pages', action='howDoI')#" class="btn btn-outline btn-sm">
			#svgIcon(name="help-circle", size=15)#
			<span>How Do I</span>
		</a>
		<button type="button" id="btnOpenAddPageModal" class="btn btn-primary btn-sm" aria-haspopup="dialog" aria-controls="addPageModalBackdrop">
			#svgIcon(name="plus", size=15)#
			<span>Add Page</span>
		</button>
	</div>
</div>

<cfscript>
	currentWsId = "";
	if (StructKeyExists(variables, "activeWorkspace") && IsStruct(variables.activeWorkspace) && Len(variables.activeWorkspace.id ?: "")) {
		currentWsId = variables.activeWorkspace.id;
	} else if (StructKeyExists(variables, "activeWsObj") && IsStruct(variables.activeWsObj) && Len(variables.activeWsObj.id ?: "")) {
		currentWsId = variables.activeWsObj.id;
	}
</cfscript>

<!--- Summary cards --->
<div class="stat-grid" style="margin-bottom:1.5rem;">
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Total Pages</span>
			<span class="stat-value">#cntTotal#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary" aria-hidden="true">#svgIcon(name="pages", size=24)#</div>
	</div>
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Published</span>
			<span class="stat-value">#cntPublished#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-success" aria-hidden="true">#svgIcon(name="check-circle", size=24)#</div>
	</div>
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Drafts &amp; Scheduled</span>
			<span class="stat-value">#cntDraft#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-warning" aria-hidden="true">#svgIcon(name="clock", size=24)#</div>
	</div>
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">In Main Menu</span>
			<span class="stat-value">#cntMenu#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-info" aria-hidden="true">#svgIcon(name="menu", size=24)#</div>
	</div>
</div>

<!--- Filter bar --->
<div class="admin-card" style="margin-bottom:1.25rem;">
	<div class="card-body" style="padding:1rem 1.25rem; display:flex; align-items:flex-end; flex-wrap:wrap; gap:0.85rem;">
		<div style="flex:1 1 260px; max-width:360px;">
			<label for="pagesSearch" class="form-label" style="font-size:0.775rem;">Search pages</label>
			<input type="search" id="pagesSearch" class="form-control" placeholder="Title or URL slug..." style="width:100%; padding:0.5rem 0.75rem; font-size:0.85rem;">
		</div>
		<div>
			<label for="pagesStatus" class="form-label" style="font-size:0.775rem;">Status</label>
			<select id="pagesStatus" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;">
				<option value="">All statuses</option>
				<option value="Active">Active</option>
				<option value="Inactive">Inactive</option>
			</select>
		</div>
		<div>
			<label for="pagesVisibility" class="form-label" style="font-size:0.775rem;">Visibility</label>
			<select id="pagesVisibility" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;">
				<option value="">All</option>
				<option value="Published">Published</option>
				<option value="Draft">Draft</option>
				<option value="Scheduled">Scheduled</option>
				<option value="Hidden">Hidden</option>
			</select>
		</div>
		<div>
			<label for="pagesMenu" class="form-label" style="font-size:0.775rem;">Menu item</label>
			<select id="pagesMenu" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;">
				<option value="">Any</option>
				<option value="yes">In menu</option>
				<option value="no">Not in menu</option>
			</select>
		</div>
		<div id="pagesCount" role="status" aria-live="polite" style="margin-left:auto; font-size:0.8rem; color:var(--admin-text-muted); padding-bottom:0.55rem;">
			Showing #cntTotal# of #cntTotal# pages
		</div>
	</div>
</div>

<!--- Pages table --->
<div class="admin-card">
	<div class="table-responsive">
		<table class="admin-table" id="pagesTable" aria-label="All pages">
			<thead>
				<tr>
					<th scope="col" style="width:76px; text-align:center;"><span class="sr-only">Actions</span></th>
					<th scope="col">Page Title</th>
					<th scope="col" style="text-align:center;">Menu Item</th>
					<th scope="col" style="text-align:center;">Status</th>
					<th scope="col" style="text-align:center;">Visibility</th>
					<th scope="col" style="text-align:center;">Updated</th>
				</tr>
			</thead>
			<tbody>
				<cfloop array="#pages#" index="p">
				<tr class="page-row"
					data-title="#EncodeForHTMLAttribute(LCase(p.title & ' ' & p.slug))#"
					data-status="#p.status#"
					data-visibility="#p.visibility#"
					data-menu="#p.menuItem ? 'yes' : 'no'#">
					<td>
						<div style="display:flex; gap:0.25rem; align-items:center;">
							<a href="#urlFor(controller='pages', action='edit', params='id=#p.id#')#" class="btn btn-sm btn-icon-only btn-outline" aria-label="Edit #EncodeForHTMLAttribute(p.title)#" title="Edit">
								#svgIcon(name="edit", size=14)#
							</a>
							<cfif (p.status eq 'Inactive' or p.status eq 'inactive') and not p.locked>
								<button type="button" class="btn btn-sm btn-icon-only btn-outline-danger" onclick="confirmDeletePage(#p.id#, '#JSStringFormat(p.title)#')" aria-label="Delete #EncodeForHTMLAttribute(p.title)#" title="Soft Delete Inactive Page">
									#svgIcon(name="trash", size=14)#
								</button>
							</cfif>
						</div>
					</td>
					<td>
						<div style="font-weight:600; color:var(--admin-text-main);">
							<a href="#urlFor(controller='pages', action='edit', params='id=#p.id#')#" style="color:inherit;">#EncodeForHTML(p.title)#</a>
							<cfif p.locked><span class="badge badge-neutral" style="font-size:0.65rem; margin-left:0.35rem;">System</span></cfif>
						</div>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
							<code>/#EncodeForHTML(p.slug)#</code>
							<cfif Len(p.parent)> &bull; Parent: #EncodeForHTML(p.parent)#</cfif>
						</div>
					</td>
					<td style="text-align:center;">
						<cfif p.menuItem>
							<span style="color:var(--admin-success); display:inline-flex;" aria-hidden="true">#svgIcon(name="check", size=18)#</span>
							<span class="sr-only">Yes</span>
						<cfelse>
							<span class="sr-only">No</span>
						</cfif>
					</td>
					<td style="text-align:center;">
						<span class="badge #(p.status eq 'Active' ? 'badge-success' : 'badge-danger')#">#p.status#</span>
					</td>
					<td style="text-align:center;">
						<span class="badge #visBadge[p.visibility]#">#p.visibility#</span>
					</td>
					<td style="text-align:center; font-size:0.825rem; color:var(--admin-text-muted); white-space:nowrap;">
						#p.updated#
						<div style="font-size:0.7rem;">by #EncodeForHTML(p.author)#</div>
					</td>
				</tr>
				</cfloop>
				<cfif ArrayLen(pages) eq 0>
				<tr id="pagesEmptyState">
					<td colspan="6" style="text-align:center; padding:3.5rem 1.5rem; color:var(--admin-text-muted);">
						<cfif not Len(currentWsId)>
							<div style="font-size:1.1rem; font-weight:600; color:var(--admin-text-main); margin-bottom:0.5rem;">Please select a workspace</div>
							<p style="margin:0 0 1.25rem 0; font-size:0.875rem;">Pages are scoped by workspace. Select a workspace from the header dropdown to view its pages.</p>
						<cfelse>
							<cfset curWsName = (StructKeyExists(variables, "activeWorkspace") && Len(variables.activeWorkspace.name ?: "")) ? variables.activeWorkspace.name : (StructKeyExists(variables, "activeWsObj") && Len(variables.activeWsObj.name ?: "") ? variables.activeWsObj.name : "this workspace")>
							<div style="font-size:1.1rem; font-weight:600; color:var(--admin-text-main); margin-bottom:0.5rem;">No pages found in #EncodeForHTML(curWsName)#</div>
							<p style="margin:0 0 1.25rem 0; font-size:0.875rem;">This workspace does not have any pages yet. Click below to create your first page.</p>
							<button type="button" class="btn btn-primary btn-sm" onclick="document.getElementById('btnOpenAddPageModal').click();">
								#svgIcon(name="plus", size=14)#
								<span>Add Page</span>
							</button>
						</cfif>
					</td>
				</tr>
				</cfif>
				<tr id="pagesNoResults" style="display:none;">
					<td colspan="6" style="text-align:center; padding:2rem; color:var(--admin-text-muted);">No pages match your filters.</td>
				</tr>
			</tbody>
		</table>
	</div>
</div>

<!--- Add Page Modal Dialog (WCAG 2.1/2.2 AA Compliant) --->
<div id="addPageModalBackdrop" class="admin-modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="addPageModalTitle" aria-describedby="addPageModalDesc" style="display:none;">
	<div class="admin-modal-dialog modal-lg">
		<div class="admin-modal-header">
			<h2 id="addPageModalTitle" class="admin-modal-title">
				#svgIcon(name="plus", size=20)#
				<span>Create New Page</span>
			</h2>
			<button type="button" id="btnCloseAddPageModal" class="admin-modal-close" aria-label="Close dialog">
				<span aria-hidden="true">&times;</span>
			</button>
		</div>

		<form id="addPageModalForm" onsubmit="return false;" novalidate>
			<div class="admin-modal-body">
				<p id="addPageModalDesc" style="font-size:0.85rem; color:var(--admin-text-muted); margin-bottom:1.25rem;">
					Enter a title and page URL for your new page, then choose an initial layout. You can customize widgets, sidebars, and SEO settings in the editor.
				</p>

				<div style="display:flex; flex-direction:column; gap:1.15rem;">
					<!--- Title --->
					<div>
						<label for="modalPageTitle" class="form-label" style="font-weight:600;">
							Page Title <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<input type="text" id="modalPageTitle" name="modalPageTitle" class="form-control" placeholder="e.g., Parks &amp; Recreation Guide" required aria-required="true" style="width:100%; font-size:0.95rem; padding:0.6rem 0.75rem;" autocomplete="off">
						<div id="modalTitleError" class="form-help-text" style="color:var(--admin-danger); display:none; margin-top:0.35rem; font-size:0.8rem; font-weight:600;" role="alert">
							Please enter a page title.
						</div>
					</div>

					<!--- Page URL --->
					<div>
						<label for="modalPageSlug" class="form-label" style="font-weight:600;">
							Page URL <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<div class="pg-slug-wrap" style="display:flex; align-items:center; border:1.5px solid var(--admin-border-input); border-radius:var(--radius-md); overflow:hidden; background:var(--admin-surface);">
							<span id="modalUrlPrefix" style="padding:0.6rem 0.75rem; background:var(--admin-bg); color:var(--admin-text-muted); font-size:0.825rem; border-right:1px solid var(--admin-border); white-space:nowrap; user-select:none;">/shared/pages/</span>
							<input type="text" id="modalPageSlug" name="modalPageSlug" class="form-control" placeholder="parks-recreation-guide" required aria-required="true" style="border:none !important; flex:1; min-width:0; padding:0.6rem 0.75rem; font-size:0.9rem;" autocomplete="off">
							<button type="button" id="btnCopyModalUrl" class="btn btn-sm btn-icon-only btn-ghost" title="Copy full URL to clipboard" aria-label="Copy full URL to clipboard" style="border:none; border-left:1px solid var(--admin-border); border-radius:0; height:100%; padding:0.6rem 0.75rem; color:var(--admin-text-muted); display:inline-flex; align-items:center; justify-content:center; background:transparent; cursor:pointer;" onmouseover="this.style.background='var(--admin-bg)'; this.style.color='var(--admin-primary)';" onmouseout="this.style.background='transparent'; this.style.color='var(--admin-text-muted)';">
								#svgIcon(name="copy", size=15)#
							</button>
						</div>
						<div id="modalSlugHelp" class="form-help-text" style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.3rem;">
							The page URL automatically generates from the page title, or you can customize it. Lowercase letters, numbers, and hyphens only.
						</div>
						<div id="modalSlugError" class="form-help-text" style="color:var(--admin-danger); display:none; margin-top:0.35rem; font-size:0.8rem; font-weight:600;" role="alert">
							Please provide a valid URL slug (e.g. &quot;my-page-title&quot;).
						</div>
					</div>

					<!--- Layout Picker (Iconized Choices) --->
					<fieldset style="border:none; padding:0; margin:0.35rem 0 0 0;">
						<legend class="form-label" style="font-weight:600; margin-bottom:0.65rem; display:block;">
							Page Layout <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</legend>
						
						<input type="hidden" id="modalSelectedLayout" name="modalSelectedLayout" value="Right Sidebar">

						<div class="layout-picker-grid" role="radiogroup" aria-label="Page layout choices">
							
							<!--- Full Width --->
							<div role="radio" aria-checked="false" tabindex="-1" class="layout-choice-card" data-layout="Full">
								<div class="layout-choice-header">
									<span class="layout-choice-name">Full Width</span>
									<span class="layout-choice-radio" aria-hidden="true"></span>
								</div>
								<div class="layout-wireframe-icon" aria-hidden="true">
									<svg viewBox="0 0 120 70" width="100%" height="56" fill="none" xmlns="http://www.w3.org/2000/svg">
										<rect x="2" y="2" width="116" height="66" rx="4" fill="var(--admin-bg)" stroke="var(--admin-border)" stroke-width="1.5"/>
										<rect x="10" y="8" width="100" height="10" rx="2" fill="var(--admin-text-muted)" opacity="0.6"/>
										<rect x="10" y="24" width="100" height="38" rx="2" fill="var(--admin-primary)" fill-opacity="0.25" stroke="var(--admin-primary)" stroke-width="1.2"/>
									</svg>
								</div>
								<p class="layout-choice-desc">Single edge-to-edge column. Ideal for announcements, long-form articles, and maps.</p>
							</div>

							<!--- Right Sidebar (Default) --->
							<div role="radio" aria-checked="true" tabindex="0" class="layout-choice-card is-selected" data-layout="Right Sidebar">
								<div class="layout-choice-header">
									<span class="layout-choice-name">Right Sidebar</span>
									<span class="layout-choice-radio" aria-hidden="true"></span>
								</div>
								<div class="layout-wireframe-icon" aria-hidden="true">
									<svg viewBox="0 0 120 70" width="100%" height="56" fill="none" xmlns="http://www.w3.org/2000/svg">
										<rect x="2" y="2" width="116" height="66" rx="4" fill="var(--admin-bg)" stroke="var(--admin-border)" stroke-width="1.5"/>
										<rect x="10" y="8" width="100" height="10" rx="2" fill="var(--admin-text-muted)" opacity="0.6"/>
										<rect x="10" y="24" width="66" height="38" rx="2" fill="var(--admin-primary)" fill-opacity="0.25" stroke="var(--admin-primary)" stroke-width="1.2"/>
										<rect x="82" y="24" width="28" height="38" rx="2" fill="var(--admin-border)" stroke="var(--admin-text-muted)" stroke-width="1.2"/>
									</svg>
								</div>
								<p class="layout-choice-desc">Primary content on the left with navigation, hours, and quick links on the right.</p>
							</div>
						</div>
					</fieldset>
				</div>
			</div>

			<div class="admin-modal-footer">
				<div id="modalSaveLiveMsg" role="status" aria-live="polite" class="sr-only"></div>
				<button type="button" class="btn btn-outline btn-sm" id="btnCancelAddPage">Cancel</button>
				<button type="button" class="btn btn-primary btn-sm" id="btnContinueAddPage">
					<span>Continue to Editor</span>
					#svgIcon(name="arrow-right", size=15)#
				</button>
			</div>
		</form>
	</div>
</div>
</cfoutput>

<script>
(function () {
	// Table filter controller
	var search = document.getElementById("pagesSearch");
	var status = document.getElementById("pagesStatus");
	var vis = document.getElementById("pagesVisibility");
	var menu = document.getElementById("pagesMenu");
	var rows = document.querySelectorAll("#pagesTable .page-row");
	var countEl = document.getElementById("pagesCount");
	var noRes = document.getElementById("pagesNoResults");

	function apply() {
		var q = search.value.trim().toLowerCase(), shown = 0;
		rows.forEach(function (r) {
			var ok = (!q || r.dataset.title.indexOf(q) > -1)
				&& (!status.value || r.dataset.status === status.value)
				&& (!vis.value || r.dataset.visibility === vis.value)
				&& (!menu.value || r.dataset.menu === menu.value);
			r.style.display = ok ? "" : "none";
			if (ok) shown++;
		});
		noRes.style.display = shown ? "none" : "";
		countEl.textContent = "Showing " + shown + " of " + rows.length + " pages";
	}
	[search, status, vis, menu].forEach(function (el) {
		el.addEventListener(el.tagName === "SELECT" ? "change" : "input", apply);
	});
})();

(function () {
	// Add Page Modal Controller (WCAG 2.1/2.2 AA compliant)
	var modalBackdrop = document.getElementById("addPageModalBackdrop");
	var btnOpen = document.getElementById("btnOpenAddPageModal");
	var btnClose = document.getElementById("btnCloseAddPageModal");
	var btnCancel = document.getElementById("btnCancelAddPage");
	var btnContinue = document.getElementById("btnContinueAddPage");
	var titleInput = document.getElementById("modalPageTitle");
	var slugInput = document.getElementById("modalPageSlug");
	var titleError = document.getElementById("modalTitleError");
	var slugError = document.getElementById("modalSlugError");
	var urlPrefixEl = document.getElementById("modalUrlPrefix");
	var layoutHidden = document.getElementById("modalSelectedLayout");
	var layoutCards = document.querySelectorAll("#addPageModalBackdrop .layout-choice-card");
	var liveMsg = document.getElementById("modalSaveLiveMsg");

	var lastActiveElement = null;
	var slugManuallyEdited = false;

	function getActiveVirtualDirectory() {
		// 1. Check active workspace DOM item
		var activeItem = document.querySelector(".workspace-item.is-active");
		if (activeItem) {
			var vDir = activeItem.getAttribute("data-ws-virtual-dir");
			if (vDir) return vDir;
			var wsId = activeItem.getAttribute("data-ws-id");
			if (wsId) return (wsId === "global" ? "shared" : wsId);
		}

		// 2. Check header container attributes
		var wsContainer = document.getElementById("workspaceDropdownContainer");
		if (wsContainer) {
			var vDir = wsContainer.getAttribute("data-active-ws-virtual-dir");
			if (vDir) return vDir;
			var wsId = wsContainer.getAttribute("data-active-ws-id");
			if (wsId) return (wsId === "global" ? "shared" : wsId);
		}

		// 3. Check localStorage
		try {
			var saved = localStorage.getItem("cmsadmin_active_workspace");
			if (saved) {
				var parsed = JSON.parse(saved);
				if (parsed && parsed.virtualDir) return parsed.virtualDir;
				if (parsed && parsed.id) return (parsed.id === "global" ? "shared" : parsed.id);
			}
		} catch (e) {}

		return "shared";
	}

	function updateUrlPrefix() {
		if (!urlPrefixEl) return;
		var vDir = getActiveVirtualDirectory();
		urlPrefixEl.textContent = "/" + vDir + "/pages/";
	}

	function slugify(text) {
		return text
			.toString()
			.toLowerCase()
			.trim()
			.replace(/[^\w\s-]/g, "")
			.replace(/[\s_-]+/g, "-")
			.replace(/^-+|-+$/g, "");
	}

	// Move modal directly to document.body so it overlays the entire viewport and cannot be clipped by layout containers
	if (modalBackdrop && modalBackdrop.parentNode !== document.body) {
		document.body.appendChild(modalBackdrop);
	}

	function openModal() {
		var activeWs = "";
		try {
			var activeItem = document.querySelector(".workspace-item.is-active");
			if (activeItem && activeItem.getAttribute("data-ws-id")) {
				activeWs = activeItem.getAttribute("data-ws-id").trim();
			} else {
				var saved = localStorage.getItem("cmsadmin_active_workspace");
				if (saved) {
					var parsed = JSON.parse(saved);
					if (parsed && parsed.id) activeWs = parsed.id.trim();
				}
			}
		} catch (e) {}

		if (!activeWs || activeWs === "global" || activeWs === "all") {
			if (typeof window.adminAlert === "function") {
				window.adminAlert({
					title: "Workspace Required",
					message: "Please select a workspace from the header dropdown before creating a page.",
					type: "warning"
				});
			} else if (typeof window.showToast === "function") {
				window.showToast("Please select a workspace from the header dropdown before creating a page.", "warning");
			}
			return;
		}

		lastActiveElement = document.activeElement;
		if (modalBackdrop && modalBackdrop.parentNode !== document.body) {
			document.body.appendChild(modalBackdrop);
		}
		modalBackdrop.style.display = "flex";
		document.body.style.overflow = "hidden";
		void modalBackdrop.offsetWidth; // Force layout reflow
		modalBackdrop.classList.add("open");
		titleError.style.display = "none";
		slugError.style.display = "none";
		titleInput.value = "";
		slugInput.value = "";
		slugManuallyEdited = false;
		updateUrlPrefix();
		btnContinue.disabled = false;
		btnContinue.innerHTML = '<span>Continue to Editor</span><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="margin-left:4px;"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>';
		selectLayout("Right Sidebar");
		setTimeout(function () {
			titleInput.focus();
		}, 50);
		document.addEventListener("keydown", trapFocus);
	}
	window.openAddPageModal = openModal;

	function closeModal() {
		modalBackdrop.classList.remove("open");
		document.body.style.overflow = "";
		document.removeEventListener("keydown", trapFocus);
		setTimeout(function () {
			modalBackdrop.style.display = "none";
			if (lastActiveElement && typeof lastActiveElement.focus === "function") {
				lastActiveElement.focus();
			}
		}, 150);
	}

	function selectLayout(layoutName) {
		layoutHidden.value = layoutName;
		layoutCards.forEach(function (card) {
			var isMatch = (card.dataset.layout === layoutName);
			card.classList.toggle("is-selected", isMatch);
			card.setAttribute("aria-checked", isMatch ? "true" : "false");
			card.setAttribute("tabindex", isMatch ? "0" : "-1");
		});
	}

	function trapFocus(e) {
		if (e.key === "Escape") {
			e.preventDefault();
			closeModal();
			return;
		}

		if (e.key === "Tab") {
			var focusables = modalBackdrop.querySelectorAll(
				'button:not([disabled]), input:not([disabled]), [tabindex="0"]:not([disabled])'
			);
			if (!focusables.length) return;
			var first = focusables[0];
			var last = focusables[focusables.length - 1];

			if (e.shiftKey) {
				if (document.activeElement === first) {
					e.preventDefault();
					last.focus();
				}
			} else {
				if (document.activeElement === last) {
					e.preventDefault();
					first.focus();
				}
			}
		}
	}

	if (btnOpen) btnOpen.addEventListener("click", openModal);
	if (btnClose) btnClose.addEventListener("click", closeModal);
	if (btnCancel) btnCancel.addEventListener("click", closeModal);

	window.addEventListener("cmsadmin:workspaceChanged", function () {
		updateUrlPrefix();
	});

	var btnCopyModalUrl = document.getElementById("btnCopyModalUrl");
	if (btnCopyModalUrl) {
		btnCopyModalUrl.addEventListener("click", async function (e) {
			e.preventDefault();
			e.stopPropagation();
			var prefix = (urlPrefixEl ? urlPrefixEl.textContent.trim() : "/shared/pages/");
			var slugVal = slugInput.value.trim() || slugify(titleInput.value.trim()) || "";
			var fullUrl = prefix + slugVal;

			var ok = false;
			if (typeof window.copyToClipboard === "function") {
				ok = await window.copyToClipboard(fullUrl);
			} else {
				try {
					await navigator.clipboard.writeText(fullUrl);
					ok = true;
				} catch (err) {}
			}

			var origHtml = btnCopyModalUrl.innerHTML;
			if (ok) {
				btnCopyModalUrl.innerHTML = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="var(--admin-success)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
				btnCopyModalUrl.setAttribute("title", "Copied to clipboard!");
				if (typeof window.showToast === "function") {
					window.showToast("Page URL copied to clipboard: " + fullUrl, "success");
				}
			} else {
				if (typeof window.showToast === "function") {
					window.showToast("Copied: " + fullUrl, "info");
				}
			}
			setTimeout(function () {
				btnCopyModalUrl.innerHTML = origHtml;
				btnCopyModalUrl.setAttribute("title", "Copy full URL to clipboard");
			}, 1800);
		});
	}

	modalBackdrop.addEventListener("click", function (e) {
		if (e.target === modalBackdrop) closeModal();
	});

	// Slug generation
	titleInput.addEventListener("input", function () {
		titleError.style.display = "none";
		if (!slugManuallyEdited) {
			slugInput.value = slugify(titleInput.value);
		}
	});

	slugInput.addEventListener("input", function () {
		slugManuallyEdited = true;
		slugError.style.display = "none";
	});

	// Radiogroup interaction
	var cardsArray = Array.prototype.slice.call(layoutCards);
	cardsArray.forEach(function (card, idx) {
		card.addEventListener("click", function () {
			selectLayout(card.dataset.layout);
			card.focus();
		});

		card.addEventListener("keydown", function (e) {
			var handled = false;
			var targetIdx = idx;

			if (e.key === " " || e.key === "Enter") {
				selectLayout(card.dataset.layout);
				handled = true;
			} else if (e.key === "ArrowRight" || e.key === "ArrowDown") {
				targetIdx = (idx + 1) % cardsArray.length;
				handled = true;
			} else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
				targetIdx = (idx - 1 + cardsArray.length) % cardsArray.length;
				handled = true;
			}

			if (handled) {
				e.preventDefault();
				selectLayout(cardsArray[targetIdx].dataset.layout);
				cardsArray[targetIdx].focus();
			}
		});
	});

	// Exit modal and proceed to Edit Page (persisting to database first)
	function proceedToEditor(forceNew) {
		var titleVal = titleInput.value.trim();
		var slugVal = slugInput.value.trim();
		var layoutVal = layoutHidden.value || "Right Sidebar";

		if (!titleVal) {
			titleError.textContent = "Page title is required.";
			titleError.style.display = "block";
			titleInput.focus();
			return;
		}

		if (titleVal && !slugVal) {
			slugVal = slugify(titleVal);
		}

		// 1. Show immediate button loading state
		btnContinue.disabled = true;
		btnContinue.innerHTML = '<span class="admin-spinner-sm" style="margin-right:6px;" aria-hidden="true"></span> <span>Checking &amp; Creating...</span>';

		// 2. Trigger high-contrast Page Transition Loader
		if (typeof window.showPageLoader === "function") {
			window.showPageLoader(
				"Creating & Saving Page...",
				"Saving “" + titleVal + "” into database and opening in Edit mode..."
			);
		}

		// Resolve current active workspace
		var activeWs = "";
		try {
			var wsEl = document.querySelector(".workspace-item.is-active");
			if (wsEl && wsEl.getAttribute("data-ws-id")) {
				activeWs = wsEl.getAttribute("data-ws-id").trim();
			} else {
				var saved = localStorage.getItem("cmsadmin_active_workspace");
				if (saved) {
					var parsed = JSON.parse(saved);
					if (parsed && parsed.id) activeWs = parsed.id.trim();
				}
			}
		} catch (e) {}

		if (!activeWs || activeWs === "global" || activeWs === "all") {
			if (typeof window.hidePageLoader === "function") window.hidePageLoader();
			btnContinue.disabled = false;
			btnContinue.innerHTML = '<span>Continue to Editor</span><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="margin-left:4px;"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>';
			if (typeof window.adminAlert === "function") {
				window.adminAlert({
					title: "Workspace Required",
					message: "Please select a workspace before creating a page.",
					type: "warning"
				});
			} else if (typeof window.showToast === "function") {
				window.showToast("Please select a workspace before creating a page.", "warning");
			}
			return;
		}

		// 3. Persist title, permalink, workspace, and layout to database
		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var headers = {
			"Content-Type": "application/json; charset=utf-8",
			"Accept": "application/json",
			"X-Requested-With": "XMLHttpRequest"
		};
		if (csrfMeta && csrfMeta.getAttribute("content")) {
			headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
		}

		function getField(obj, name) {
			if (!obj || typeof obj !== "object") return undefined;
			var key = Object.keys(obj).find(function (k) { return k.toLowerCase() === name.toLowerCase(); });
			return key === undefined ? undefined : obj[key];
		}

		fetch("/pages/create-modal", {
			method: "POST",
			credentials: "same-origin",
			headers: headers,
			body: JSON.stringify({
				title: titleVal,
				slug: slugVal,
				layout: layoutVal,
				siteId: activeWs,
				forceNew: forceNew === true
			})
		})
		.then(function (res) {
			return res.text().then(function (text) {
				var data;
				try {
					data = JSON.parse(text);
				} catch (e) {
					throw new Error("Invalid response from server (HTTP " + res.status + ").");
				}
				if (!res.ok && !data.archivedFound && !data.ARCHIVEDFOUND) {
					throw new Error(getField(data, "message") || ("Server error (HTTP " + res.status + ")."));
				}
				return data;
			});
		})
		.then(function (data) {
			// Check if an archived/soft-deleted page was found
			if (data.archivedFound || data.ARCHIVEDFOUND) {
				if (typeof window.hidePageLoader === "function") window.hidePageLoader();
				btnContinue.disabled = false;
				btnContinue.innerHTML = '<span>Continue to Editor</span><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="margin-left:4px;"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>';

				var archived = data.archivedPage || {};
				handleArchivedPageFound(archived, titleVal, slugVal);
				return;
			}

			var isSuccess = getField(data, "success") === true;
			var newId = parseInt(getField(data, "id"), 10) || 0;
			var redirectUrl = getField(data, "redirectUrl");

			if (isSuccess && newId > 0) {
				closeModal();
				var targetUrl = redirectUrl || ("/pages/edit?id=" + encodeURIComponent(newId) + "&created=1");
				window.location.href = targetUrl;
			} else {
				throw new Error(getField(data, "message") || "Failed to create page in database.");
			}
		})
		.catch(function (err) {
			if (typeof window.hidePageLoader === "function") {
				window.hidePageLoader();
			}
			btnContinue.disabled = false;
			btnContinue.innerHTML = '<span>Continue to Editor</span><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="margin-left:4px;"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>';
			var msg = (err && err.message) ? err.message : "Error creating page. Please try again.";
			titleError.textContent = msg;
			titleError.style.display = "block";
			if (typeof window.adminAlert === "function") {
				window.adminAlert(msg, { title: "Error Creating Page", type: "danger" });
			}
		});
	}

	async function handleArchivedPageFound(archived, titleVal, slugVal) {
		var pageTitle = archived.title || titleVal;
		var pageSlug = archived.slug || slugVal;
		var delDate = archived.deletedAt || "a previous date";
		var delUser = archived.deletedBy || "staff";

		var restoreChoice = false;
		if (typeof window.adminConfirm === "function") {
			restoreChoice = await window.adminConfirm({
				title: "Archived Page Found",
				message: 'An archived page titled "' + pageTitle + '" (/' + pageSlug + ') was archived on ' + delDate + ' by ' + delUser + '.\n\nWould you like to restore and activate this archived page with its previous content, attachments, and revision history?',
				acceptText: "Restore Archived Page",
				cancelText: "Create Brand New Page",
				type: "info"
			});
		}

		if (restoreChoice) {
			executeRestoreArchivedPage(archived.id, pageTitle);
		} else {
			var createChoice = false;
			if (typeof window.adminConfirm === "function") {
				createChoice = await window.adminConfirm({
					title: "Create Brand New Page?",
					message: 'A brand new blank page will be created. The URL slug will be automatically incremented if needed to avoid conflicting with the archived record. Do you wish to continue?',
					acceptText: "Create New Page",
					cancelText: "Cancel & Edit Title",
					type: "primary"
				});
			}
			if (createChoice) {
				proceedToEditor(true); // forceNew = true
			}
		}
	}

	function executeRestoreArchivedPage(pageId, pageTitle) {
		if (typeof window.showPageLoader === "function") window.showPageLoader("Reactivating archived page...");
		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var headers = {
			"Content-Type": "application/json; charset=utf-8",
			"Accept": "application/json",
			"X-Requested-With": "XMLHttpRequest"
		};
		if (csrfMeta && csrfMeta.getAttribute("content")) {
			headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
		}

		fetch("/pages/restore-archived", {
			method: "POST",
			credentials: "same-origin",
			headers: headers,
			body: JSON.stringify({ id: pageId })
		})
		.then(function(res) { return res.json(); })
		.then(function(resData) {
			if (resData.success || resData.SUCCESS) {
				closeModal();
				if (typeof window.showToast === "function") {
					window.showToast(resData.message || "Page reactivated successfully!", "success");
				}
				var targetUrl = resData.redirectUrl || ("/pages/edit?id=" + encodeURIComponent(pageId) + "&reactivated=1");
				setTimeout(function() {
					window.location.href = targetUrl;
				}, 400);
			} else {
				if (typeof window.hidePageLoader === "function") window.hidePageLoader();
				if (typeof window.adminAlert === "function") {
					window.adminAlert({ title: "Reactivation Failed", message: resData.message || "Unable to restore archived page.", type: "danger" });
				}
			}
		})
		.catch(function(err) {
			if (typeof window.hidePageLoader === "function") window.hidePageLoader();
			if (typeof window.adminAlert === "function") {
				window.adminAlert({ title: "System Error", message: err.message || "Failed to communicate with server.", type: "danger" });
			}
		});
	}

	btnContinue.addEventListener("click", function() { proceedToEditor(false); });

	[titleInput, slugInput].forEach(function (inp) {
		inp.addEventListener("keydown", function (e) {
			if (e.key === "Enter") {
				e.preventDefault();
				proceedToEditor(false);
			}
		});
	});

	// Ensure any loading transition screen dismisses when Content Manager view is ready
	if (typeof window.hidePageLoader === "function") window.hidePageLoader();
	if (typeof window.finishTopProgress === "function") window.finishTopProgress();
})();

async function confirmDeletePage(id, title) {
	if (!id) return;
	var promptTitle = title || ('Page ##' + id);
	var ok = false;
	if (typeof window.adminConfirm === "function") {
		ok = await window.adminConfirm({
			title: 'Soft Delete Inactive Page?',
			message: 'Are you sure you want to soft delete "' + promptTitle + '"? This inactive page will be archived and removed from the active directory.',
			type: 'danger',
			acceptText: 'Delete Page',
			confirmText: 'Delete Page',
			cancelText: 'Cancel'
		});
	}
	if (!ok) return;

	var csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
	var headers = {
		'Content-Type': 'application/json; charset=utf-8',
		'X-Requested-With': 'XMLHttpRequest'
	};
	if (csrfToken) {
		headers['X-CSRF-Token'] = csrfToken;
	}

	fetch('/pages/delete', {
		method: 'POST',
		credentials: 'same-origin',
		headers: headers,
		body: JSON.stringify({ id: id })
	})
	.then(function(r) { return r.json(); })
	.then(function(res) {
		if (res.success || res.SUCCESS) {
			if (typeof window.showToast === 'function') {
				window.showToast(res.message || 'Page soft-deleted successfully.', 'success');
			}
			setTimeout(function() {
				window.location.reload();
			}, 500);
		} else {
			if (typeof window.adminAlert === 'function') {
				window.adminAlert({ title: 'Delete Failed', message: res.message || 'Failed to delete page.', type: 'danger' });
			}
		}
	})
	.catch(function(err) {
		if (typeof window.adminAlert === 'function') {
			window.adminAlert({ title: 'System Error', message: (err && err.message) ? err.message : 'An error occurred while deleting the page.', type: 'danger' });
		}
	});
}
</script>
