<cfoutput>
<!--- Call to Action Studio — CMSAdmin 2.0 (WCAG 2.1 AA Compliant) --->
<cfscript>
	currentWs = variables.activeWorkspaceId ?: "global";
	currentWsObj = variables.activeWsObj ?: {};
	wsName = currentWsObj.name ?: "All Workspaces";
	allCtaItems = variables.ctaItems ?: [];
	allCategories = variables.categories ?: [];
	totalCount = ArrayLen(allCtaItems);
	publishedCount = 0;
	for (local.c in allCtaItems) {
		if (local.c.isPublished) publishedCount++;
	}

	// JSON payload for dynamic client-side interactions
	ctaJsonData = Replace(SerializeJSON({
		"items": allCtaItems,
		"categories": allCategories,
		"activeWorkspace": currentWs,
		"routes": {
			"save": "/pages/call-to-action/save",
			"delete": "/pages/call-to-action/delete",
			"reorder": "/pages/call-to-action/reorder",
			"list": "/pages/call-to-action/list"
		}
	}), "</", "<\\/", "all");
</cfscript>

<style>
	/* Call to Action Manager Custom Styles */
	.cta-manager-header {
		margin-bottom: 1.5rem;
	}
	.cta-stats-bar {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
		margin-bottom: 1.5rem;
	}
	.cta-stat-card {
		background: var(--admin-surface);
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 1rem 1.25rem;
		display: flex;
		align-items: center;
		gap: 1rem;
		box-shadow: var(--shadow-sm);
	}
	.cta-stat-icon {
		width: 44px;
		height: 44px;
		border-radius: var(--radius-md);
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}
	.cta-filter-toolbar {
		background: var(--admin-surface);
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 0.85rem 1.25rem;
		margin-bottom: 1.5rem;
		display: flex;
		flex-wrap: wrap;
		gap: 1rem;
		justify-content: space-between;
		align-items: center;
		box-shadow: var(--shadow-sm);
	}
	.cta-search-wrap {
		position: relative;
		min-width: 280px;
		flex: 1;
		max-width: 440px;
	}
	.cta-search-wrap input {
		padding-left: 2.2rem;
		width: 100%;
	}
	.cta-search-icon {
		position: absolute;
		left: 0.75rem;
		top: 50%;
		transform: translateY(-50%);
		color: var(--admin-text-muted);
		pointer-events: none;
	}
	.cta-pills {
		display: flex;
		gap: 0.4rem;
		flex-wrap: wrap;
		align-items: center;
	}
	.cta-pill-btn {
		background: var(--admin-bg);
		border: 1px solid var(--admin-border);
		color: var(--admin-text-main);
		border-radius: 20px;
		padding: 0.35rem 0.85rem;
		font-size: 0.8rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.15s ease;
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
	}
	.cta-pill-btn:hover {
		background: var(--admin-border-subtle);
		color: var(--admin-primary);
	}
	.cta-pill-btn.active {
		background: var(--admin-primary);
		border-color: var(--admin-primary);
		color: ##ffffff;
	}
	.cta-card-manage-wrap {
		position: relative;
		display: flex;
		flex-direction: column;
		background: var(--admin-surface);
		border: 1px solid var(--admin-border);
		border-radius: 8px;
		overflow: hidden;
		box-shadow: 0 1px 3px rgba(0,0,0,0.06);
		transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
	}
	.cta-card-manage-wrap:hover {
		transform: translateY(-2px);
		box-shadow: 0 6px 18px rgba(0,0,0,0.1);
		border-color: var(--admin-primary-light);
	}
	.cta-card-admin-bar {
		padding: 0.5rem 0.85rem;
		background: var(--admin-bg);
		border-top: 1px solid var(--admin-border);
		display: flex;
		align-items: center;
		justify-content: space-between;
		font-size: 0.75rem;
		color: var(--admin-text-muted);
		gap: 0.5rem;
	}
	.cta-shortcode-chip {
		background: var(--admin-surface);
		border: 1px dashed var(--admin-border);
		border-radius: 4px;
		padding: 0.2rem 0.5rem;
		font-family: monospace;
		font-size: 0.75rem;
		color: var(--admin-text-main);
		cursor: pointer;
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		max-width: 190px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		transition: all 0.15s ease;
	}
	.cta-shortcode-chip:hover {
		border-color: var(--admin-primary);
		color: var(--admin-primary);
		background: ##eff6ff;
	}
	.cta-shortcode-chip.btn-copied {
		border-color: ##10b981;
		color: ##065f46;
		background: ##d1fae5;
	}
	.cta-empty-state {
		text-align: center;
		padding: 3.5rem 1.5rem;
		background: var(--admin-surface);
		border: 2px dashed var(--admin-border);
		border-radius: var(--radius-lg);
		color: var(--admin-text-muted);
	}
	.cta-empty-state svg {
		margin-bottom: 0.75rem;
		color: var(--admin-text-muted);
	}
</style>

<div class="page-header cta-manager-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Call to Action Studio</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='pages', action='index')#">Pages</a></li>
				<li class="breadcrumb-item active" aria-current="page">Call to Action Studio</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="#urlFor(controller='pages', action='index')#" class="btn btn-outline btn-sm">
			#svgIcon(name="pages", size=15)#
			<span>Content Manager</span>
		</a>
		<button type="button" class="btn btn-outline btn-sm" id="btnOpenGridBuilder" title="Build multi-card grid shortcodes">
			#svgIcon(name="grid", size=15)#
			<span>Grid Shortcode Builder</span>
		</button>
		<button type="button" class="btn btn-primary btn-sm" id="btnAddCtaModal" aria-haspopup="dialog">
			#svgIcon(name="plus", size=15)#
			<span>Add Call to Action</span>
		</button>
	</div>
</div>

<!--- Metric Telemetry Strip --->
<div class="cta-stats-bar">
	<div class="cta-stat-card">
		<div class="cta-stat-icon" style="background:##eff6ff; color:##2563eb;">
			#svgIcon(name="cta", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Total CTAs</div>
			<div style="font-size:1.5rem; font-weight:800; color:var(--admin-text-main);" id="statTotalCount">#totalCount#</div>
		</div>
	</div>

	<div class="cta-stat-card">
		<div class="cta-stat-icon" style="background:##f0fdf4; color:##16a34a;">
			#svgIcon(name="check-circle", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Active / Published</div>
			<div style="font-size:1.5rem; font-weight:800; color:var(--admin-text-main);" id="statPublishedCount">#publishedCount#</div>
		</div>
	</div>

	<div class="cta-stat-card">
		<div class="cta-stat-icon" style="background:##faf5ff; color:##9333ea;">
			#svgIcon(name="tag", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Categories</div>
			<div style="font-size:1.5rem; font-weight:800; color:var(--admin-text-main);">#ArrayLen(allCategories)#</div>
		</div>
	</div>

	<div class="cta-stat-card">
		<div class="cta-stat-icon" style="background:##fff7ed; color:##ea580c;">
			#svgIcon(name="building", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Workspace Scope</div>
			<div style="font-size:1rem; font-weight:700; color:var(--admin-text-main); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">#EncodeForHTML(wsName)#</div>
		</div>
	</div>
</div>

<!--- Filter & Search Toolbar --->
<div class="cta-filter-toolbar">
	<div class="cta-search-wrap">
		<span class="cta-search-icon">#svgIcon(name="search", size=14)#</span>
		<input type="search" id="ctaSearchInput" class="form-control form-control-sm" placeholder="Search by title, description, or slug..." aria-label="Search Call to Action cards">
	</div>

	<div class="cta-pills" id="ctaCategoryPills" role="tablist" aria-label="Filter by category">
		<button type="button" class="cta-pill-btn active" data-cat="all" role="tab" aria-selected="true">
			<span>All Categories</span>
			<span class="badge badge-neutral" style="font-size:0.65rem; padding:0.1rem 0.35rem;" id="badgeCatAll">#totalCount#</span>
		</button>
		<cfloop array="#allCategories#" index="local.cat">
			<button type="button" class="cta-pill-btn" data-cat="#EncodeForHTMLAttribute(local.cat)#" role="tab" aria-selected="false">
				<span>#EncodeForHTML(local.cat)#</span>
			</button>
		</cfloop>
	</div>

	<div style="font-size:0.8rem; color:var(--admin-text-muted);">
		Showing <strong id="ctaVisibleCount">#totalCount#</strong> item<cfif totalCount neq 1>s</cfif>
	</div>
</div>

<!--- Main Call to Action Card Grid (4-Column Layout) --->
<div id="ctaCardsContainer" class="jbd-cta-grid cta-grid-4">
	<cfloop array="#allCtaItems#" index="local.it">
		<div class="cta-card-manage-wrap" data-id="#local.it.id#" data-category="#EncodeForHTMLAttribute(local.it.category)#" data-slug="#EncodeForHTMLAttribute(local.it.slug)#" data-title="#EncodeForHTMLAttribute(local.it.title)#" data-published="#local.it.isPublished ? '1' : '0'#">
			
			<!--- Reference Card Presentation --->
			<div class="jbd-cta-card<cfif Len(local.it.imageUrl)> has-image</cfif>" style="margin:0; border:none; box-shadow:none; border-radius:0; flex-grow:1;">
				<cfif Len(local.it.imageUrl)>
					<div class="jbd-cta-card-img-wrap">
						<img src="#local.it.imageUrl#" alt="#EncodeForHTMLAttribute(local.it.imageAlt)#" loading="lazy">
					</div>
					<div class="jbd-cta-card-content">
				</cfif>

				<cfif Len(local.it.badgeText)>
					<div class="jbd-cta-card-header">
						<span class="jbd-cta-badge<cfif local.it.badgeColor eq 'teal'> jbd-cta-badge-teal<cfelseif local.it.badgeColor eq 'amber'> jbd-cta-badge-amber</cfif>">#EncodeForHTML(local.it.badgeText)#</span>
					</div>
				</cfif>

				<p class="jbd-cta-title h4">#EncodeForHTML(local.it.title)#</p>
				<p class="jbd-cta-desc">#EncodeForHTML(local.it.description)#</p>

				<div class="jbd-cta-card-footer">
					<cfif local.it.linkStyle eq "button">
						<a href="#local.it.linkUrl#" class="jbd-btn jbd-btn-primary jbd-cta-btn"<cfif local.it.targetBlank> target="_blank" rel="noopener noreferrer"</cfif>>
							<span>#EncodeForHTML(local.it.linkText)#</span>
							<cfif local.it.linkIcon eq "external">
								<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>
							<cfelseif local.it.linkIcon eq "pdf">
								<span class="jbd-cta-pdf-badge" aria-hidden="true">PDF</span>
							<cfelse>
								<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
							</cfif>
						</a>
					<cfelse>
						<a href="#local.it.linkUrl#" class="jbd-cta-link<cfif local.it.targetBlank or local.it.linkIcon eq 'external'> has-external-icon</cfif>"<cfif local.it.targetBlank> target="_blank" rel="noopener noreferrer"</cfif>>
							<span>#EncodeForHTML(local.it.linkText)#</span>
							<cfif local.it.linkIcon eq "external">
								<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>
							<cfelseif local.it.linkIcon eq "pdf">
								<span class="jbd-cta-pdf-badge" aria-hidden="true">PDF</span>
							<cfelse>
								<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
							</cfif>
						</a>
					</cfif>
				</div>

				<cfif Len(local.it.imageUrl)>
					</div><!--- end content --->
				</cfif>
			</div>

			<!--- Admin Toolbar Strip for each card --->
			<div class="cta-card-admin-bar">
				<button type="button" class="cta-shortcode-chip btn-copy-shortcode" data-code="#local.it.shortcode#" title="Click to copy shortcode to clipboard">
					#svgIcon(name="copy", size=12)#
					<span>#local.it.shortcode#</span>
				</button>
				<div style="display:flex; align-items:center; gap:0.25rem;">
					<button type="button" class="btn btn-ghost btn-xs btn-edit-cta" data-id="#local.it.id#" title="Edit Call to Action">
						#svgIcon(name="edit", size=13)#
						<span>Edit</span>
					</button>
					<button type="button" class="btn btn-ghost btn-xs text-danger btn-delete-cta" data-id="#local.it.id#" data-title="#EncodeForHTMLAttribute(local.it.title)#" title="Delete Call to Action">
						#svgIcon(name="trash", size=13)#
					</button>
				</div>
			</div>
		</div>
	</cfloop>
</div>

<div id="ctaEmptyState" class="cta-empty-state" style="<cfif totalCount gt 0>display:none;</cfif>">
	#svgIcon(name="cta", size=48)#
	<h3 style="margin:0 0 0.5rem; font-size:1.15rem; color:var(--admin-text-main);">No Call to Action Cards Found</h3>
	<p style="margin:0 0 1.25rem; font-size:0.9rem; max-width:480px; margin-left:auto; margin-right:auto;">
		Create your first Call to Action card to embed into pages or provide quick citizen service links.
	</p>
	<button type="button" class="btn btn-primary btn-sm" onclick="openCtaModal(0)">
		#svgIcon(name="plus", size=14)#
		<span>Add Call to Action</span>
	</button>
</div>

<!--- MODAL 1: ADD / EDIT CALL TO ACTION --->
<div class="admin-modal-backdrop" id="ctaModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72); backdrop-filter:blur(6px); opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeCtaModal()"></div>
<div class="admin-modal" id="ctaModal" role="dialog" aria-modal="true" aria-labelledby="ctaModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:94%; max-width:860px; max-height:90vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
		<div>
			<h2 class="modal-title" id="ctaModalTitle" style="margin:0; font-size:1.1rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
				#svgIcon(name="cta", size=18)#
				<span id="ctaModalHeadingText">Add Call to Action</span>
			</h2>
			<div style="font-size:0.78rem; color:var(--admin-text-muted); margin-top:0.2rem;">
				Configure card heading, responsive image, citizen description, and destination action link.
			</div>
		</div>
		<button type="button" class="btn btn-ghost btn-sm" onclick="closeCtaModal()" aria-label="Close modal" style="padding:0.25rem 0.5rem; font-size:1.25rem; line-height:1;">
			#svgIcon(name="x", size=16)#
		</button>
	</div>

	<div style="flex:1; overflow-y:auto; padding:1.25rem; max-height:calc(90vh - 140px);">
		<form id="ctaForm" novalidate onsubmit="return false;">
			<input type="hidden" id="ctaFormId" name="id" value="0">

			<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem; margin-bottom:1rem;">
				<div class="form-group">
					<label for="ctaFormTitle" class="form-label" style="font-weight:700;">Title / Headline <span class="text-danger">*</span></label>
					<input type="text" id="ctaFormTitle" name="title" class="form-control" placeholder="e.g. Parcel & Sale Search" required>
					<div class="form-text" style="font-size:0.75rem; color:var(--admin-text-muted);">Primary bold card heading displayed to users.</div>
				</div>

				<div class="form-group">
					<label for="ctaFormSlug" class="form-label" style="font-weight:700;">Shortcode Slug <span class="text-danger">*</span></label>
					<div style="position:relative;">
						<input type="text" id="ctaFormSlug" name="slug" class="form-control" placeholder="e.g. parcel-sale-search" required style="font-family:monospace;">
					</div>
					<div class="form-text" style="font-size:0.75rem; color:var(--admin-text-muted);">Used in shortcode: <code>[call_to_action slug="..."]</code>.</div>
				</div>
			</div>

			<div class="form-group" style="margin-bottom:1rem;">
				<label for="ctaFormCategory" class="form-label" style="font-weight:700;">Category</label>
				<input type="text" id="ctaFormCategory" name="category" class="form-control" list="ctaCategoryDatalist" placeholder="e.g. Assessor Services">
				<datalist id="ctaCategoryDatalist">
					<cfloop array="#allCategories#" index="local.cName">
						<option value="#EncodeForHTMLAttribute(local.cName)#"></option>
					</cfloop>
				</datalist>
				<div class="form-text" style="font-size:0.75rem; color:var(--admin-text-muted);">Organizes cards into filter tabs and groups.</div>
				<input type="hidden" id="ctaFormWorkspace" name="siteId" value="#EncodeForHTMLAttribute(currentWs)#">
			</div>

			<!--- Image and Media Asset Row --->
			<div style="background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1rem; margin-bottom:1rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
					<label for="ctaFormImageUrl" class="form-label" style="font-weight:700; margin:0;">Top Card Image (Optional)</label>
					<button type="button" class="btn btn-outline btn-xs" id="btnBrowseCtaImage">
						#svgIcon(name="image", size=13)#
						<span>Browse Media Library</span>
					</button>
				</div>
				<div style="display:grid; grid-template-columns:2fr 1fr; gap:0.75rem; margin-bottom:0.5rem;">
					<input type="text" id="ctaFormImageUrl" name="imageUrl" class="form-control form-control-sm" placeholder="/images/cta/parcel-search.jpg or media URL">
					<input type="text" id="ctaFormImageAlt" name="imageAlt" class="form-control form-control-sm" placeholder="ADA Alt Text (e.g. Red house in meadow)">
				</div>
				<div style="font-size:0.74rem; color:var(--admin-text-muted);">
					Reference dimensions: 16:10 or 3:2 ratio (~600x380px). Always provide descriptive alt text for WCAG 2.1 AA compliance.
				</div>
			</div>

			<div class="form-group" style="margin-bottom:1rem;">
				<label for="ctaFormDesc" class="form-label" style="font-weight:700;">Description / Body Text</label>
				<textarea id="ctaFormDesc" name="description" class="form-control" rows="2" placeholder="e.g. Look up property details, assessed valuations, tax history, and verified market sales."></textarea>
				<div class="form-text" style="font-size:0.75rem; color:var(--admin-text-muted);">Brief, informative guidance explaining what the user will achieve.</div>
			</div>

			<!--- Action Link Configuration --->
			<div style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1rem; margin-bottom:1rem;">
				<h4 style="margin:0 0 0.75rem; font-size:0.9rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.4rem;">
					#svgIcon(name="link", size=14)#
					<span>Destination Action Link</span>
				</h4>
				<div style="display:grid; grid-template-columns:1fr 1.5fr; gap:0.75rem; margin-bottom:0.75rem;">
					<div>
						<label for="ctaFormLinkText" class="form-label" style="font-weight:600; font-size:0.8rem;">Action Label <span class="text-danger">*</span></label>
						<input type="text" id="ctaFormLinkText" name="linkText" class="form-control form-control-sm" placeholder="e.g. Search Parcels, Open Map" required>
					</div>
					<div>
						<label for="ctaFormLinkUrl" class="form-label" style="font-weight:600; font-size:0.8rem;">Destination URL <span class="text-danger">*</span></label>
						<input type="text" id="ctaFormLinkUrl" name="linkUrl" class="form-control form-control-sm" placeholder="https://... or /assessor/parcels" required>
					</div>
				</div>

				<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:0.75rem; align-items:center;">
					<div>
						<label for="ctaFormLinkIcon" class="form-label" style="font-weight:600; font-size:0.8rem;">Link Icon</label>
						<select id="ctaFormLinkIcon" name="linkIcon" class="form-select form-select-sm">
							<option value="arrow">Arrow Right (&rarr;)</option>
							<option value="external">External Link (&nearr;)</option>
							<option value="pdf">PDF Document Badge</option>
							<option value="none">No Icon</option>
						</select>
					</div>
					<div>
						<label for="ctaFormLinkStyle" class="form-label" style="font-weight:600; font-size:0.8rem;">Link Presentation</label>
						<select id="ctaFormLinkStyle" name="linkStyle" class="form-select form-select-sm">
							<option value="link">Inline Text Link (Reference Style)</option>
							<option value="button">High-Contrast Action Button</option>
						</select>
					</div>
					<div style="padding-top:1.2rem;">
						<label style="display:flex; align-items:center; gap:0.4rem; font-size:0.8rem; cursor:pointer; font-weight:600;">
							<input type="checkbox" id="ctaFormTargetBlank" name="targetBlank" value="1" style="accent-color:var(--admin-primary); width:16px; height:16px;">
							<span>Open in New Window</span>
						</label>
					</div>
				</div>
			</div>

			<!--- Card Badge & Status --->
			<div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:0.75rem; margin-bottom:1rem; align-items:center;">
				<div>
					<label for="ctaFormBadgeText" class="form-label" style="font-weight:600; font-size:0.8rem;">Badge Tag (Optional)</label>
					<input type="text" id="ctaFormBadgeText" name="badgeText" class="form-control form-control-sm" placeholder="e.g. ONLINE SERVICE, MAPPING">
				</div>
				<div>
					<label for="ctaFormBadgeColor" class="form-label" style="font-weight:600; font-size:0.8rem;">Badge Color</label>
					<select id="ctaFormBadgeColor" name="badgeColor" class="form-select form-select-sm">
						<option value="blue">Blue Accent</option>
						<option value="teal">Teal / Mint</option>
						<option value="amber">Amber / Warm</option>
					</select>
				</div>
				<div style="padding-top:1.2rem;">
					<label style="display:flex; align-items:center; gap:0.4rem; font-size:0.85rem; cursor:pointer; font-weight:700;">
						<input type="checkbox" id="ctaFormPublished" name="isPublished" value="1" checked style="accent-color:var(--admin-primary); width:18px; height:18px;">
						<span>Published &amp; Active</span>
					</label>
				</div>
			</div>

			<!--- Live Interactive Preview Box --->
			<div style="margin-top:1rem; border-top:1px solid var(--admin-border); padding-top:1rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
					<strong style="font-size:0.82rem; color:var(--admin-text-main);">Live Card Preview (Matches Public / Editor Rendering)</strong>
					<span style="font-size:0.72rem; color:var(--admin-text-muted);">Real-time reactive visual</span>
				</div>
				<div style="max-width:360px; margin:0 auto;" id="ctaModalPreviewCanvas">
					<!--- Rendered via JavaScript --->
				</div>
			</div>
		</form>
	</div>

	<div class="modal-footer" style="padding:0.75rem 1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
		<button type="button" class="btn btn-outline btn-sm" onclick="closeCtaModal()">Cancel</button>
		<button type="button" class="btn btn-primary btn-sm" id="btnSaveCtaItem">
			#svgIcon(name="save", size=14)#
			<span>Save Call to Action</span>
		</button>
	</div>
</div>

<!--- MODAL 2: GRID SHORTCODE BUILDER --->
<div class="admin-modal-backdrop" id="gridBuilderBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72); backdrop-filter:blur(6px); opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeGridBuilderModal()"></div>
<div class="admin-modal" id="gridBuilderModal" role="dialog" aria-modal="true" aria-labelledby="gridBuilderTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:94%; max-width:820px; max-height:88vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
		<div>
			<h2 class="modal-title" id="gridBuilderTitle" style="margin:0; font-size:1.1rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
				#svgIcon(name="grid", size=18)#
				<span>Grid Shortcode &amp; Embed Builder</span>
			</h2>
			<div style="font-size:0.78rem; color:var(--admin-text-muted); margin-top:0.2rem;">
				Select multiple Call to Action cards to assemble a 4-column, 3-column, or 50/50 split grid inside JBDEditor.
			</div>
		</div>
		<button type="button" class="btn btn-ghost btn-sm" onclick="closeGridBuilderModal()" aria-label="Close modal" style="padding:0.25rem 0.5rem; font-size:1.25rem; line-height:1;">
			#svgIcon(name="x", size=16)#
		</button>
	</div>

	<div style="flex:1; overflow-y:auto; padding:1.25rem; max-height:calc(88vh - 140px);">
		<div style="margin-bottom:1rem; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.5rem;">
			<div style="font-size:0.85rem; font-weight:700; color:var(--admin-text-main);">
				1. Select Cards to Include in Grid:
			</div>
			<div style="display:flex; gap:0.4rem;">
				<button type="button" class="btn btn-outline btn-xs" id="btnSelectAllCards">Select All</button>
				<button type="button" class="btn btn-outline btn-xs" id="btnClearAllCards">Clear All</button>
			</div>
		</div>

		<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(220px, 1fr)); gap:0.75rem; margin-bottom:1.5rem;" id="gridBuilderChecklist">
			<cfloop array="#allCtaItems#" index="local.it">
				<label style="display:flex; align-items:flex-start; gap:0.6rem; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); cursor:pointer; font-size:0.82rem; transition:border-color 0.15s ease;">
					<input type="checkbox" class="grid-card-checkbox" value="#local.it.slug#" checked style="accent-color:var(--admin-primary); margin-top:0.2rem; width:16px; height:16px;">
					<div style="min-width:0; flex:1;">
						<strong style="color:var(--admin-text-main); display:block; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">#EncodeForHTML(local.it.title)#</strong>
						<span style="font-size:0.72rem; color:var(--admin-text-muted); font-family:monospace;">#local.it.slug#</span>
					</div>
				</label>
			</cfloop>
		</div>

		<div style="font-size:0.85rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.5rem;">
			2. Choose Grid Column Layout:
		</div>
		<div style="display:flex; gap:0.75rem; margin-bottom:1.25rem; flex-wrap:wrap;" id="gridColLayoutGroup">
			<label style="display:flex; align-items:center; gap:0.45rem; padding:0.5rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); cursor:pointer; font-size:0.82rem; font-weight:600; color:var(--admin-text-main);">
				<input type="radio" name="gridColLayout" value="3x1" checked style="accent-color:var(--admin-primary); width:15px; height:15px;">
				<span>3 Columns (3 Col / 3x1 Grid)</span>
			</label>
			<label style="display:flex; align-items:center; gap:0.45rem; padding:0.5rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); cursor:pointer; font-size:0.82rem; font-weight:600; color:var(--admin-text-main);">
				<input type="radio" name="gridColLayout" value="4col" style="accent-color:var(--admin-primary); width:15px; height:15px;">
				<span>4 Columns (4 Col Grid)</span>
			</label>
			<label style="display:flex; align-items:center; gap:0.45rem; padding:0.5rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); cursor:pointer; font-size:0.82rem; font-weight:600; color:var(--admin-text-main);">
				<input type="radio" name="gridColLayout" value="50/50" style="accent-color:var(--admin-primary); width:15px; height:15px;">
				<span>2 Columns (2x2 / 50-50 Split)</span>
			</label>
		</div>

		<div style="font-size:0.85rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.5rem;">
			3. Generated Shortcode for JBDEditor:
		</div>
		<div style="display:flex; gap:0.5rem; margin-bottom:1rem;">
			<input type="text" id="generatedGridShortcode" class="form-control" readonly style="font-family:monospace; font-weight:600; font-size:0.85rem; background:var(--admin-bg);">
			<button type="button" class="btn btn-primary btn-sm" id="btnCopyGridShortcode">
				#svgIcon(name="copy", size=14)#
				<span>Copy Shortcode</span>
			</button>
		</div>

		<div style="font-size:0.85rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.5rem;">
			4. Or Copy Pre-Rendered Semantic HTML:
		</div>
		<div style="position:relative;">
			<textarea id="generatedGridHtml" class="form-control" rows="4" readonly style="font-family:monospace; font-size:0.75rem; background:var(--admin-bg); resize:none;"></textarea>
			<button type="button" class="btn btn-outline btn-xs" id="btnCopyGridHtml" style="position:absolute; right:0.5rem; top:0.5rem;">
				#svgIcon(name="copy", size=12)#
				<span>Copy HTML</span>
			</button>
		</div>
	</div>

	<div class="modal-footer" style="padding:0.75rem 1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; justify-content:flex-end; background:var(--admin-bg);">
		<button type="button" class="btn btn-outline btn-sm" onclick="closeGridBuilderModal()">Close</button>
	</div>
</div>

<!--- MODAL 3: MEDIA LIBRARY PICKER MODAL --->
<div class="admin-modal-backdrop" id="mediaPickerModalBackdrop" style="display:none; position:fixed; inset:0; z-index:100004; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeMediaPickerModal()"></div>
<div class="admin-modal" id="mediaPickerModal" role="dialog" aria-modal="true" aria-labelledby="mediaPickerModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:100005; width:96vw; max-width:1440px; height:88vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	<div class="modal-header" style="padding:0.75rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
		<h2 class="modal-title" id="mediaPickerModalTitle" style="margin:0; font-size:1.05rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
			#svgIcon(name="image", size=18)#
			<span id="mediaPickerTitleText">Select Image from Media Library</span>
		</h2>
		<div style="display:flex; align-items:center; gap:0.5rem;">
			<button type="button" class="btn btn-outline-primary btn-sm" onclick="triggerMediaPickerUpload()" style="display:inline-flex; align-items:center; gap:0.35rem;" title="Upload new media asset to repository">
				#svgIcon(name="upload", size=14)#
				<span>Upload New File</span>
			</button>
			<button type="button" class="btn btn-secondary btn-sm" onclick="closeMediaPickerModal()" aria-label="Close Media Picker">
				#svgIcon(name="x", size=16)#
				<span>Close</span>
			</button>
		</div>
	</div>
	<div style="flex:1; position:relative; overflow:hidden;">
		<iframe id="mediaPickerIframe" src="about:blank" style="width:100%; height:100%; border:none;" title="Media Asset Picker"></iframe>
	</div>
</div>

<script id="ctaConfigData" type="application/json">#ctaJsonData#</script>

<script>
(function() {
	var configEl = document.getElementById("ctaConfigData");
	var config = configEl ? JSON.parse(configEl.textContent || "{}") : {};
	var items = Array.isArray(config.items) ? config.items : [];
	var routes = config.routes || {};

	// Search & Category Filtering
	var searchInput = document.getElementById("ctaSearchInput");
	var pillBtns = document.querySelectorAll(".cta-pill-btn");
	var visibleCountEl = document.getElementById("ctaVisibleCount");
	var activeCategory = "all";

	function filterCards() {
		var term = (searchInput ? searchInput.value : "").trim().toLowerCase();
		var cards = document.querySelectorAll(".cta-card-manage-wrap");
		var visCount = 0;

		cards.forEach(function(card) {
			var cat = (card.getAttribute("data-category") || "").toLowerCase();
			var title = (card.getAttribute("data-title") || "").toLowerCase();
			var slug = (card.getAttribute("data-slug") || "").toLowerCase();

			var matchesCat = (activeCategory === "all") || (cat === activeCategory.toLowerCase());
			var matchesSearch = !term || title.includes(term) || slug.includes(term) || cat.includes(term);

			if (matchesCat && matchesSearch) {
				card.style.display = "";
				visCount++;
			} else {
				card.style.display = "none";
			}
		});

		if (visibleCountEl) visibleCountEl.textContent = visCount;
		var emptyEl = document.getElementById("ctaEmptyState");
		if (emptyEl) emptyEl.style.display = (visCount === 0) ? "block" : "none";
	}

	if (searchInput) {
		searchInput.addEventListener("input", filterCards);
	}

	pillBtns.forEach(function(btn) {
		btn.addEventListener("click", function() {
			pillBtns.forEach(function(b) { b.classList.remove("active"); b.setAttribute("aria-selected", "false"); });
			btn.classList.add("active");
			btn.setAttribute("aria-selected", "true");
			activeCategory = btn.getAttribute("data-cat") || "all";
			filterCards();
		});
	});

	// Copy Shortcode from Card Toolbar
	document.addEventListener("click", function(e) {
		var copyBtn = e.target.closest(".btn-copy-shortcode");
		if (copyBtn) {
			var code = copyBtn.getAttribute("data-code") || "";
			if (code) {
				copyTextToClipboard(code, "Copied shortcode: " + code, copyBtn);
			}
			return;
		}

		var editBtn = e.target.closest(".btn-edit-cta");
		if (editBtn) {
			var id = parseInt(editBtn.getAttribute("data-id"), 10);
			openCtaModal(id);
			return;
		}

		var delBtn = e.target.closest(".btn-delete-cta");
		if (delBtn) {
			var id = parseInt(delBtn.getAttribute("data-id"), 10);
			var title = delBtn.getAttribute("data-title") || "this Call to Action";
			confirmDeleteCta(id, title);
			return;
		}
	});

	// Modal Controls
	window.openCtaModal = function(id) {
		var modal = document.getElementById("ctaModal");
		var backdrop = document.getElementById("ctaModalBackdrop");
		var headingText = document.getElementById("ctaModalHeadingText");
		var form = document.getElementById("ctaForm");

		if (backdrop && backdrop.parentElement !== document.body) document.body.appendChild(backdrop);
		if (modal && modal.parentElement !== document.body) document.body.appendChild(modal);

		form.reset();
		document.getElementById("ctaFormId").value = id || 0;

		if (id > 0) {
			var found = items.find(function(it) { return it.id === id; });
			if (found) {
				headingText.textContent = 'Edit "' + found.title + '"';
				document.getElementById("ctaFormTitle").value = found.title || "";
				document.getElementById("ctaFormSlug").value = found.slug || "";
				document.getElementById("ctaFormCategory").value = found.category || "";
				document.getElementById("ctaFormWorkspace").value = found.siteId || "global";
				document.getElementById("ctaFormImageUrl").value = found.imageUrl || "";
				document.getElementById("ctaFormImageAlt").value = found.imageAlt || "";
				document.getElementById("ctaFormDesc").value = found.description || "";
				document.getElementById("ctaFormLinkText").value = found.linkText || "";
				document.getElementById("ctaFormLinkUrl").value = found.linkUrl || "";
				document.getElementById("ctaFormLinkIcon").value = found.linkIcon || "arrow";
				document.getElementById("ctaFormLinkStyle").value = found.linkStyle || "link";
				document.getElementById("ctaFormTargetBlank").checked = !!found.targetBlank;
				document.getElementById("ctaFormBadgeText").value = found.badgeText || "";
				document.getElementById("ctaFormBadgeColor").value = found.badgeColor || "blue";
				document.getElementById("ctaFormPublished").checked = (found.isPublished !== false);
			}
		} else {
			headingText.textContent = "Add Call to Action";
			document.getElementById("ctaFormWorkspace").value = config.activeWorkspace || "global";
			document.getElementById("ctaFormLinkText").value = "Search Parcels";
			document.getElementById("ctaFormPublished").checked = true;
		}

		updateModalLivePreview();

		modal.style.display = "flex";
		backdrop.style.display = "block";
		setTimeout(function() {
			backdrop.style.opacity = "1";
			backdrop.style.visibility = "visible";
			document.getElementById("ctaFormTitle").focus();
		}, 30);
		document.body.style.overflow = "hidden";
	};

	window.closeCtaModal = function() {
		var modal = document.getElementById("ctaModal");
		var backdrop = document.getElementById("ctaModalBackdrop");
		if (modal) modal.style.display = "none";
		if (backdrop) {
			backdrop.style.opacity = "0";
			backdrop.style.visibility = "hidden";
			backdrop.style.display = "none";
		}
		document.body.style.overflow = "";
	};

	// Modal Live Preview Updater
	function updateModalLivePreview() {
		var previewContainer = document.getElementById("ctaModalPreviewCanvas");
		if (!previewContainer) return;

		var title = document.getElementById("ctaFormTitle").value.trim() || "Headline Here";
		var desc = document.getElementById("ctaFormDesc").value.trim() || "Add descriptive copy explaining the service or citizen benefit.";
		var imgUrl = document.getElementById("ctaFormImageUrl").value.trim();
		var imgAlt = document.getElementById("ctaFormImageAlt").value.trim() || title;
		var linkText = document.getElementById("ctaFormLinkText").value.trim() || "Learn More";
		var linkUrl = document.getElementById("ctaFormLinkUrl").value.trim() || "##";
		var linkIcon = document.getElementById("ctaFormLinkIcon").value;
		var linkStyle = document.getElementById("ctaFormLinkStyle").value;
		var badgeText = document.getElementById("ctaFormBadgeText").value.trim();
		var badgeColor = document.getElementById("ctaFormBadgeColor").value;
		var isBlank = document.getElementById("ctaFormTargetBlank").checked;

		var badgeCls = "jbd-cta-badge";
		if (badgeColor === "teal") badgeCls += " jbd-cta-badge-teal";
		else if (badgeColor === "amber") badgeCls += " jbd-cta-badge-amber";

		var iconSvg = '<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>';
		if (linkIcon === "external") {
			iconSvg = '<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>';
		} else if (linkIcon === "pdf") {
			iconSvg = '<span class="jbd-cta-pdf-badge" aria-hidden="true">PDF</span>';
		} else if (linkIcon === "none") {
			iconSvg = '';
		}

		var html = '<div class="jbd-cta-card' + (imgUrl ? ' has-image' : '') + '">';
		if (imgUrl) {
			html += '<div class="jbd-cta-card-img-wrap"><img src="' + escapeHtmlAttr(imgUrl) + '" alt="' + escapeHtmlAttr(imgAlt) + '"></div>';
			html += '<div class="jbd-cta-card-content">';
		}

		if (badgeText) {
			html += '<div class="jbd-cta-card-header"><span class="' + badgeCls + '">' + escapeHtml(badgeText) + '</span></div>';
		}

		html += '<p class="jbd-cta-title h4">' + escapeHtml(title) + '</p>';
		html += '<p class="jbd-cta-desc">' + escapeHtml(desc) + '</p>';

		html += '<div class="jbd-cta-card-footer">';
		if (linkStyle === "button") {
			html += '<a href="' + escapeHtmlAttr(linkUrl) + '" class="jbd-btn jbd-btn-primary jbd-cta-btn"><span>' + escapeHtml(linkText) + '</span> ' + iconSvg + '</a>';
		} else {
			html += '<a href="' + escapeHtmlAttr(linkUrl) + '" class="jbd-cta-link' + (isBlank || linkIcon === 'external' ? ' has-external-icon' : '') + '"><span>' + escapeHtml(linkText) + '</span> ' + iconSvg + '</a>';
		}
		html += '</div>';

		if (imgUrl) html += '</div>';
		html += '</div>';

		previewContainer.innerHTML = html;
	}

	// Auto-slugify title
	var titleInput = document.getElementById("ctaFormTitle");
	var slugInput = document.getElementById("ctaFormSlug");
	if (titleInput && slugInput) {
		titleInput.addEventListener("input", function() {
			var id = parseInt(document.getElementById("ctaFormId").value, 10);
			if (!id || !slugInput.value) {
				slugInput.value = titleInput.value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
			}
			updateModalLivePreview();
		});
	}

	["ctaFormDesc", "ctaFormImageUrl", "ctaFormImageAlt", "ctaFormLinkText", "ctaFormLinkUrl", "ctaFormLinkIcon", "ctaFormLinkStyle", "ctaFormBadgeText", "ctaFormBadgeColor", "ctaFormTargetBlank"].forEach(function(fId) {
		var el = document.getElementById(fId);
		if (el) el.addEventListener("input", updateModalLivePreview);
		if (el) el.addEventListener("change", updateModalLivePreview);
	});

	// Save CTA
	var btnSave = document.getElementById("btnSaveCtaItem");
	if (btnSave) {
		btnSave.addEventListener("click", function() {
			var title = document.getElementById("ctaFormTitle").value.trim();
			var linkUrl = document.getElementById("ctaFormLinkUrl").value.trim();
			if (!title) {
				if (typeof window.adminAlert === "function") window.adminAlert({ title: "Required Field", message: "Please provide a headline title for this Call to Action.", type: "warning" });
				return;
			}
			if (!linkUrl) {
				if (typeof window.adminAlert === "function") window.adminAlert({ title: "Required Field", message: "Please provide a destination link URL.", type: "warning" });
				return;
			}

			var wsInput = document.getElementById("ctaFormWorkspace");
			var resolvedSiteId = (wsInput && wsInput.value && wsInput.value !== "global") ? wsInput.value : (config.activeWorkspace || "global");

			var payload = {
				id: parseInt(document.getElementById("ctaFormId").value, 10) || 0,
				title: title,
				slug: document.getElementById("ctaFormSlug").value.trim(),
				category: document.getElementById("ctaFormCategory").value.trim() || "General",
				siteId: resolvedSiteId,
				imageUrl: document.getElementById("ctaFormImageUrl").value.trim(),
				imageAlt: document.getElementById("ctaFormImageAlt").value.trim(),
				description: document.getElementById("ctaFormDesc").value.trim(),
				linkText: document.getElementById("ctaFormLinkText").value.trim() || "Learn More",
				linkUrl: linkUrl,
				linkIcon: document.getElementById("ctaFormLinkIcon").value,
				linkStyle: document.getElementById("ctaFormLinkStyle").value,
				targetBlank: document.getElementById("ctaFormTargetBlank").checked ? 1 : 0,
				badgeText: document.getElementById("ctaFormBadgeText").value.trim(),
				badgeColor: document.getElementById("ctaFormBadgeColor").value,
				isPublished: document.getElementById("ctaFormPublished").checked ? 1 : 0
			};

			btnSave.disabled = true;
			btnSave.textContent = "Saving...";

			fetch(routes.save || "/pages/call-to-action/save", {
				method: "POST",
				headers: { "Content-Type": "application/json; charset=utf-8", "Accept": "application/json" },
				body: JSON.stringify(payload)
			})
			.then(function(r) {
				return r.text().then(function(txt) {
					try {
						return JSON.parse(txt);
					} catch(e) {
						if (txt.indexOf("<html") !== -1 || txt.indexOf("<!DOCTYPE") !== -1) {
							if (txt.indexOf("login") !== -1 || txt.indexOf("Sign In") !== -1) {
								return { success: false, message: "Your session has expired. Please refresh the page and sign in again." };
							}
							return { success: false, message: "Server returned a page error. Please reload the page." };
						}
						return { success: false, message: "Unexpected server response: " + txt.substring(0, 100) };
					}
				});
			})
			.then(function(res) {
				btnSave.disabled = false;
				btnSave.innerHTML = '#svgIcon(name="save", size=14)# <span>Save Call to Action</span>';
				if (res.success) {
					closeCtaModal();
					if (typeof window.showToast === "function") window.showToast(res.message || "Saved successfully", "success");
					setTimeout(function() { window.location.reload(); }, 600);
				} else {
					if (typeof window.adminAlert === "function") {
						window.adminAlert({ title: "Save Error", message: res.message || "Unable to save Call to Action.", type: "danger" });
					}
				}
			})
			.catch(function(err) {
				btnSave.disabled = false;
				btnSave.innerHTML = '#svgIcon(name="save", size=14)# <span>Save Call to Action</span>';
				if (typeof window.adminAlert === "function") {
					window.adminAlert({ title: "Network Error", message: "Error communicating with server: " + err, type: "danger" });
				}
			});
		});
	}

	// Delete CTA
	function confirmDeleteCta(id, title) {
		if (typeof window.adminConfirm === "function") {
			window.adminConfirm({
				title: "Delete Call to Action",
				message: 'Are you sure you want to remove "' + title + '"? This will disable any shortcodes referencing this item.',
				confirmLabel: "Delete CTA",
				confirmVariant: "danger"
			}, function(confirmed) {
				if (!confirmed) return;
				executeDeleteCta(id);
			});
		} else {
			executeDeleteCta(id);
		}
	}

	function executeDeleteCta(id) {
		fetch(routes.delete || "/pages/call-to-action/delete", {
			method: "POST",
			headers: { "Content-Type": "application/json; charset=utf-8", "Accept": "application/json" },
			body: JSON.stringify({ id: id })
		})
		.then(function(r) {
			return r.text().then(function(txt) {
				try { return JSON.parse(txt); }
				catch(e) { return { success: false, message: "Server error occurred." }; }
			});
		})
		.then(function(res) {
			if (res.success) {
				if (typeof window.showToast === "function") window.showToast("Call to Action removed.", "success");
				var card = document.querySelector('.cta-card-manage-wrap[data-id="' + id + '"]');
				if (card) card.remove();
				items = items.filter(function(it) { return it.id !== id; });
				filterCards();
			} else {
				if (typeof window.adminAlert === "function") window.adminAlert({ title: "Delete Error", message: res.message || "Failed to delete.", type: "danger" });
			}
		});
	}

	// Open Add CTA Modal button
	var btnAddMain = document.getElementById("btnAddCtaModal");
	if (btnAddMain) {
		btnAddMain.addEventListener("click", function() {
			openCtaModal(0);
		});
	}

	// Media Library Picker Integration
	window.openMediaPicker = function(mode, options) {
		options = options || {};
		var modal = document.getElementById("mediaPickerModal");
		var backdrop = document.getElementById("mediaPickerModalBackdrop");
		var iframe = document.getElementById("mediaPickerIframe");
		var title = document.getElementById("mediaPickerTitleText");

		if (title) {
			title.textContent = (mode === 'document') ? 'Select Document from Media Library' : 'Select Image from Media Library';
		}
		var activeWs = config.activeWorkspace || 'global';
		var pickerType = (mode === 'document') ? 'document' : 'image';
		var folder = options.folder || (mode === 'document' ? 'documents' : 'all');

		if (typeof options.onSelect === 'function') {
			window._mediaPickerCustomCallback = options.onSelect;
		} else {
			window._mediaPickerCustomCallback = null;
		}

		if (iframe) {
			iframe.src = '/media/picker?picker=' + encodeURIComponent(mode) + '&type=' + encodeURIComponent(pickerType) + '&folder=' + encodeURIComponent(folder) + '&ws=' + encodeURIComponent(activeWs) + '&callback=onMediaSelectedFromPicker';
		}
		if (modal) {
			modal.style.display = 'flex';
			modal.classList.add('open');
		}
		if (backdrop) {
			backdrop.style.display = 'block';
			backdrop.style.opacity = '1';
			backdrop.style.visibility = 'visible';
			backdrop.classList.add('open');
		}
	};

	window.closeMediaPickerModal = function() {
		var modal = document.getElementById("mediaPickerModal");
		var backdrop = document.getElementById("mediaPickerModalBackdrop");
		var iframe = document.getElementById("mediaPickerIframe");
		if (modal) {
			modal.style.display = 'none';
			modal.classList.remove('open');
		}
		if (backdrop) {
			backdrop.style.display = 'none';
			backdrop.style.opacity = '0';
			backdrop.style.visibility = 'hidden';
			backdrop.classList.remove('open');
		}
		if (iframe) {
			iframe.src = 'about:blank';
		}
		window._mediaPickerCustomCallback = null;
	};

	window.triggerMediaPickerUpload = function() {
		try {
			var iframe = document.getElementById("mediaPickerIframe");
			if (iframe && iframe.contentDocument) {
				var b = iframe.contentDocument.getElementById("btn-upload");
				if (b) { b.click(); return; }
			}
		} catch (e) {}
		window.open("/media/upload", "_blank");
	};

	window.onMediaSelectedFromPicker = function(payload) {
		var customCb = window._mediaPickerCustomCallback;
		closeMediaPickerModal();
		if (typeof customCb === 'function') {
			customCb(payload);
		}
	};

	window.addEventListener('message', function(e) {
		if (e.data && (e.data.type === 'CMS_MEDIA_SELECTED' || e.data.type === 'cmsMediaSelected')) {
			var customCb = window._mediaPickerCustomCallback;
			if (typeof customCb === 'function') {
				closeMediaPickerModal();
				customCb(e.data);
			}
		}
	});

	var btnBrowseImg = document.getElementById("btnBrowseCtaImage");
	if (btnBrowseImg) {
		btnBrowseImg.addEventListener("click", function() {
			window.openMediaPicker("image", {
				folder: "all",
				onSelect: function(asset) {
					if (asset) {
						var url = asset.url || asset.webPath || asset.path || "";
						if (url) {
							document.getElementById("ctaFormImageUrl").value = url;
							var currentAlt = document.getElementById("ctaFormImageAlt").value.trim();
							var titleVal = document.getElementById("ctaFormTitle").value.trim();
							if (!currentAlt) {
								document.getElementById("ctaFormImageAlt").value = asset.alt || asset.title || titleVal || "";
							}
							updateModalLivePreview();
						}
					}
				}
			});
		});
	}

	// Grid Shortcode Builder Modal
	var btnOpenGrid = document.getElementById("btnOpenGridBuilder");
	var gridModal = document.getElementById("gridBuilderModal");
	var gridBackdrop = document.getElementById("gridBuilderBackdrop");

	function updateGridBuilderOutput() {
		var checkedBoxes = document.querySelectorAll(".grid-card-checkbox:checked");
		var slugs = [];
		checkedBoxes.forEach(function(cb) { slugs.push(cb.value); });

		var scInput = document.getElementById("generatedGridShortcode");
		var htmlInput = document.getElementById("generatedGridHtml");

		var selectedLayout = document.querySelector('input[name="gridColLayout"]:checked');
		var layoutVal = selectedLayout ? selectedLayout.value : "3x1";
		var colsAttr = '';
		var gridClass = 'cta-grid-3';

		if (layoutVal === "4col") {
			colsAttr = ' cols="4"';
			gridClass = 'cta-grid-4';
		} else if (layoutVal === "50/50" || layoutVal === "2x2" || layoutVal === "2") {
			colsAttr = ' cols="2"';
			gridClass = 'cta-grid-2 cta-grid-50-50';
		} else {
			colsAttr = ' cols="3"';
			gridClass = 'cta-grid-3';
		}

		if (slugs.length === 0) {
			if (scInput) scInput.value = "[cta_grid" + colsAttr + "]";
			if (htmlInput) htmlInput.value = "";
			return;
		}

		var shortcode = '[cta_grid slugs="' + slugs.join(",") + '"' + colsAttr + ']';
		if (scInput) scInput.value = shortcode;

		// Generate HTML preview
		var html = '<section class="jbd-template jbd-cta-grid ' + gridClass + '" aria-label="Featured Actions">\n';
		slugs.forEach(function(sl) {
			var item = items.find(function(it) { return it.slug === sl; });
			if (item) {
				html += '  <aside class="jbd-template jbd-cta-card' + (item.imageUrl ? ' has-image' : '') + '">\n';
				if (item.imageUrl) {
					html += '    <div class="jbd-cta-card-img-wrap"><img src="' + escapeHtmlAttr(item.imageUrl) + '" alt="' + escapeHtmlAttr(item.imageAlt || item.title) + '" loading="lazy"></div>\n';
					html += '    <div class="jbd-cta-card-content">\n';
				}
				html += '      <p class="jbd-cta-title h4">' + escapeHtml(item.title) + '</p>\n';
				html += '      <p class="jbd-cta-desc">' + escapeHtml(item.description) + '</p>\n';
				html += '      <div class="jbd-cta-card-footer">\n';
				html += '        <a href="' + escapeHtmlAttr(item.linkUrl) + '" class="jbd-cta-link' + (item.targetBlank || item.linkIcon === 'external' ? ' has-external-icon' : '') + '"' + (item.targetBlank ? ' target="_blank" rel="noopener noreferrer"' : '') + '><span>' + escapeHtml(item.linkText) + '</span> &rarr;</a>\n';
				html += '      </div>\n';
				if (item.imageUrl) html += '    </div>\n';
				html += '  </aside>\n';
			}
		});
		html += '</section>';

		if (htmlInput) htmlInput.value = html;
	}

	if (btnOpenGrid) {
		btnOpenGrid.addEventListener("click", function() {
			if (gridBackdrop && gridBackdrop.parentElement !== document.body) document.body.appendChild(gridBackdrop);
			if (gridModal && gridModal.parentElement !== document.body) document.body.appendChild(gridModal);
			gridModal.style.display = "flex";
			gridBackdrop.style.display = "block";
			setTimeout(function() {
				gridBackdrop.style.opacity = "1";
				gridBackdrop.style.visibility = "visible";
			}, 30);
			updateGridBuilderOutput();
		});
	}

	window.closeGridBuilderModal = function() {
		if (gridModal) gridModal.style.display = "none";
		if (gridBackdrop) {
			gridBackdrop.style.opacity = "0";
			gridBackdrop.style.visibility = "hidden";
			gridBackdrop.style.display = "none";
		}
	};

	var btnSelAll = document.getElementById("btnSelectAllCards");
	if (btnSelAll) {
		btnSelAll.addEventListener("click", function() {
			document.querySelectorAll(".grid-card-checkbox").forEach(function(cb) { cb.checked = true; });
			updateGridBuilderOutput();
		});
	}

	var btnClrAll = document.getElementById("btnClearAllCards");
	if (btnClrAll) {
		btnClrAll.addEventListener("click", function() {
			document.querySelectorAll(".grid-card-checkbox").forEach(function(cb) { cb.checked = false; });
			updateGridBuilderOutput();
		});
	}

	document.querySelectorAll(".grid-card-checkbox").forEach(function(cb) {
		cb.addEventListener("change", updateGridBuilderOutput);
	});

	document.querySelectorAll('input[name="gridColLayout"]').forEach(function(radio) {
		radio.addEventListener("change", updateGridBuilderOutput);
	});

	var btnCopySc = document.getElementById("btnCopyGridShortcode");
	if (btnCopySc) {
		btnCopySc.addEventListener("click", function() {
			var sc = document.getElementById("generatedGridShortcode").value;
			if (sc) copyTextToClipboard(sc, "Copied grid shortcode to clipboard!", btnCopySc);
		});
	}

	var btnCopyHtml = document.getElementById("btnCopyGridHtml");
	if (btnCopyHtml) {
		btnCopyHtml.addEventListener("click", function() {
			var ht = document.getElementById("generatedGridHtml").value;
			if (ht) copyTextToClipboard(ht, "Copied responsive HTML to clipboard!", btnCopyHtml);
		});
	}

	// Escape key dismissal for modals
	document.addEventListener("keydown", function(e) {
		if (e.key === "Escape") {
			closeCtaModal();
			closeGridBuilderModal();
		}
	});

	// Listen for global header workspace switcher changes (Alt+W)
	window.addEventListener("cmsadmin:workspaceChanged", function(e) {
		var newWs = e.detail && (e.detail.id || e.detail.workspaceId) ? String(e.detail.id || e.detail.workspaceId).toLowerCase() : "";
		var curWs = String(config.activeWorkspace || "").toLowerCase();
		if (newWs && newWs !== curWs) {
			window.location.href = "/pages/call-to-action?ws=" + encodeURIComponent(newWs);
		}
	});

	function copyTextToClipboard(text, successToastMsg, triggerBtn) {
		if (!text) return;

		function notifySuccess() {
			if (successToastMsg && typeof window.showToast === "function") {
				window.showToast(successToastMsg, "success");
			}
			if (triggerBtn) {
				triggerBtn.classList.add("btn-copied");
				setTimeout(function() {
					triggerBtn.classList.remove("btn-copied");
				}, 1500);
			}
		}

		// 1. Try global window.copyToClipboard (handles secure context + execCommand fallback)
		if (typeof window.copyToClipboard === "function") {
			window.copyToClipboard(text).then(function(ok) {
				if (ok) {
					notifySuccess();
				} else {
					legacyExecCopy(text, notifySuccess);
				}
			}).catch(function() {
				legacyExecCopy(text, notifySuccess);
			});
			return;
		}

		// 2. Direct fallback for plain HTTP origins (document.execCommand)
		legacyExecCopy(text, notifySuccess);
	}

	function legacyExecCopy(text, callback) {
		try {
			var ta = document.createElement("textarea");
			ta.value = text;
			ta.setAttribute("readonly", "");
			ta.style.position = "fixed";
			ta.style.top = "0";
			ta.style.left = "-9999px";
			ta.style.width = "2em";
			ta.style.height = "2em";
			ta.style.opacity = "0";
			ta.style.pointerEvents = "none";
			document.body.appendChild(ta);
			ta.focus();
			ta.select();
			ta.setSelectionRange(0, text.length);
			var ok = document.execCommand("copy");
			document.body.removeChild(ta);
			if (ok && typeof callback === "function") {
				callback();
			}
		} catch (e) {
			console.error("Clipboard copy failed:", e);
		}
	}

	function escapeHtml(str) {
		return String(str || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
	}
	function escapeHtmlAttr(str) {
		return String(str || "").replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
	}
})();
</script>
</cfoutput>

