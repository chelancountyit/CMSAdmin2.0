<cfset pageTitle = "How Do I">
<cfscript>
	wsId = LCase(Trim(activeWorkspace.id ?: "global"));
	wsName = activeWorkspace.name ?: "Global (County-Wide)";
	wsBadge = activeWorkspace.badge ?: "Global";
	wsBadgeClass = activeWorkspace.badgeClass ?: "badge-purple";
	wsVirtDir = (StructKeyExists(activeWorkspace, "virtual_directory") && Len(Trim(activeWorkspace.virtual_directory)))
		? Trim(activeWorkspace.virtual_directory)
		: (wsId eq "global" ? "shared" : wsId);

	totalLinks = ArrayLen(howDoIItems);
	cntPublished = 0;
	cntDraft = 0;
	cntMega = 0;
	catCounts = {};

	for (cat in categories) {
		catCounts["c_" & cat.id] = 0;
	}

	for (item in howDoIItems) {
		if (item.isPublished) cntPublished++; else cntDraft++;
		if (item.isFeaturedMegaMenu) cntMega++;
		cKey = "c_" & item.categoryId;
		if (!StructKeyExists(catCounts, cKey)) catCounts[cKey] = 0;
		catCounts[cKey]++;
	}

	cntActiveCats = 0;
	for (cat in categories) {
		if (cat.isActive) cntActiveCats++;
	}

	typeLabels = {
		"page": { label: "Site Page", cls: "badge-primary", icon: "file-text" },
		"form": { label: "Online Form", cls: "badge-purple", icon: "form" },
		"custom": { label: "Custom Path", cls: "badge-info", icon: "link" },
		"external": { label: "External URL", cls: "badge-warning", icon: "external-link" }
	};

	howDoIJsonData = Replace(SerializeJSON({
		"items": howDoIItems,
		"countyItems": countyRollupItems,
		"categories": categories,
		"pages": workspacePages,
		"forms": workspaceForms,
		"activeWorkspace": {
			"id": wsId,
			"name": wsName,
			"virtualDir": wsVirtDir
		},
		"urls": {
			"saveItem": urlFor(controller="pages", action="saveHowDoIItem"),
			"deleteItem": urlFor(controller="pages", action="deleteHowDoIItem"),
			"reorderItems": urlFor(controller="pages", action="reorderHowDoIItems"),
			"saveCategory": urlFor(controller="pages", action="saveHowDoICategory"),
			"deleteCategory": urlFor(controller="pages", action="deleteHowDoICategory"),
			"prefillCategories": urlFor(controller="pages", action="prefillHowDoICategories")
		}
	}), "</", "<\/", "all");
</cfscript>

<cfoutput>
<style>
	.hdi-layout {
		display: grid;
		grid-template-columns: 270px minmax(0, 1fr);
		gap: 1.25rem;
		align-items: start;
	}
	@media (max-width: 1024px) {
		.hdi-layout {
			grid-template-columns: 1fr;
		}
	}
	.hdi-cat-sidebar {
		position: sticky;
		top: calc(var(--header-height, 64px) + 1rem);
		background: var(--admin-surface, ##ffffff);
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-lg, 0.75rem);
		box-shadow: var(--shadow-sm);
		overflow: hidden;
	}
	.hdi-cat-list {
		list-style: none;
		margin: 0;
		padding: 0.5rem;
		max-height: calc(100vh - 220px);
		overflow-y: auto;
	}
	.hdi-cat-btn {
		width: 100%;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.6rem;
		padding: 0.55rem 0.75rem;
		border: 1px solid transparent;
		border-radius: var(--radius-md, 0.5rem);
		background: transparent;
		color: var(--admin-text-main, ##0f172a);
		font-size: 0.85rem;
		font-weight: 600;
		text-align: left;
		cursor: pointer;
		transition: all 0.15s ease;
	}
	.hdi-cat-btn:hover {
		background: var(--admin-surface-hover, ##f8fafc);
		color: var(--admin-primary, ##0073aa);
	}
	.hdi-cat-btn.is-active {
		background: var(--admin-primary-light, ##f0f9ff);
		border-color: rgba(2, 132, 199, 0.28);
		color: var(--admin-primary, ##0073aa);
		font-weight: 700;
	}
	.hdi-cat-count {
		font-size: 0.72rem;
		font-weight: 700;
		padding: 0.1rem 0.45rem;
		border-radius: 999px;
		background: var(--admin-bg, ##f1f5f9);
		color: var(--admin-text-muted, ##475569);
	}
	.hdi-cat-btn.is-active .hdi-cat-count {
		background: var(--admin-primary, ##0073aa);
		color: ##ffffff;
	}
	.hdi-category-card {
		background: var(--admin-surface, ##ffffff);
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-lg, 0.75rem);
		box-shadow: var(--shadow-sm);
		margin-bottom: 1rem;
		overflow: hidden;
	}
	.hdi-category-header {
		padding: 0.9rem 1.25rem;
		background: linear-gradient(to right, var(--admin-bg, ##f8fafc), ##ffffff);
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		flex-wrap: wrap;
	}
	.hdi-item-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.85rem;
		padding: 0.8rem 1.25rem;
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
		transition: background 0.12s ease;
	}
	.hdi-item-row:last-child {
		border-bottom: none;
	}
	.hdi-item-row:hover {
		background: var(--admin-surface-hover, ##f8fafc);
	}
	.hdi-item-main {
		display: flex;
		align-items: flex-start;
		gap: 0.75rem;
		min-width: 0;
		flex: 1;
	}
	.hdi-order-btns {
		display: flex;
		flex-direction: column;
		gap: 2px;
	}
	.hdi-order-btn {
		border: 1px solid var(--admin-border, ##cbd5e1);
		background: var(--admin-surface, ##ffffff);
		color: var(--admin-text-muted, ##64748b);
		border-radius: 4px;
		width: 22px;
		height: 20px;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0;
		cursor: pointer;
	}
	.hdi-order-btn:hover:not(:disabled) {
		border-color: var(--admin-primary, ##0073aa);
		color: var(--admin-primary, ##0073aa);
		background: var(--admin-primary-light, ##f0f9ff);
	}
	.hdi-order-btn:disabled {
		opacity: 0.35;
		cursor: default;
	}
	.hdi-item-title {
		font-weight: 600;
		font-size: 0.92rem;
		color: var(--admin-text-main, ##0f172a);
		display: flex;
		align-items: center;
		gap: 0.5rem;
		flex-wrap: wrap;
	}
	.hdi-item-url {
		font-size: 0.78rem;
		color: var(--admin-text-muted, ##64748b);
		margin-top: 0.2rem;
		word-break: break-all;
		display: flex;
		align-items: center;
		gap: 0.4rem;
		flex-wrap: wrap;
	}
	.hdi-item-url a {
		color: var(--admin-primary, ##0073aa);
		text-decoration: none;
	}
	.hdi-item-url a:hover {
		text-decoration: underline;
	}
	.hdi-item-actions {
		display: flex;
		align-items: center;
		gap: 0.45rem;
		flex-shrink: 0;
	}

	/* Modal Overlay */
	.hdi-modal-backdrop {
		position: fixed;
		inset: 0;
		z-index: 9990;
		background: rgba(15, 23, 42, 0.72);
		backdrop-filter: blur(4px);
		-webkit-backdrop-filter: blur(4px);
		display: none;
		align-items: center;
		justify-content: center;
		padding: 1.25rem;
	}
	.hdi-modal-backdrop.is-open {
		display: flex;
	}
	.hdi-modal-dialog {
		background: var(--admin-surface, ##ffffff);
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-lg, 0.75rem);
		box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.45);
		width: 100%;
		max-width: 680px;
		max-height: 90vh;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	.hdi-modal-dialog.hdi-modal-xl {
		max-width: 1080px;
	}
	.hdi-modal-header {
		padding: 1.1rem 1.4rem;
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
		display: flex;
		align-items: center;
		justify-content: space-between;
		background: var(--admin-bg, ##f8fafc);
	}
	.hdi-modal-title {
		margin: 0;
		font-size: 1.05rem;
		font-weight: 700;
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}
	.hdi-modal-body {
		padding: 1.35rem 1.4rem;
		overflow-y: auto;
		flex: 1;
	}
	.hdi-modal-footer {
		padding: 0.9rem 1.4rem;
		border-top: 1px solid var(--admin-border-subtle, ##e2e8f0);
		background: var(--admin-bg, ##f8fafc);
		display: flex;
		align-items: center;
		justify-content: flex-end;
		gap: 0.65rem;
	}

	/* Destination Type Radio Pills */
	.hdi-dtype-grid {
		display: grid;
		grid-template-columns: repeat(4, minmax(0, 1fr));
		gap: 0.5rem;
	}
	@media (max-width: 640px) {
		.hdi-dtype-grid {
			grid-template-columns: repeat(2, minmax(0, 1fr));
		}
	}
	.hdi-dtype-btn {
		padding: 0.6rem 0.5rem;
		border: 1.5px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		background: var(--admin-surface, ##ffffff);
		color: var(--admin-text-main, ##0f172a);
		font-size: 0.78rem;
		font-weight: 600;
		cursor: pointer;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.3rem;
		text-align: center;
		transition: all 0.15s ease;
	}
	.hdi-dtype-btn:hover {
		border-color: var(--admin-primary, ##0073aa);
	}
	.hdi-dtype-btn.is-selected {
		border-color: var(--admin-primary, ##0073aa);
		background: var(--admin-primary-light, ##f0f9ff);
		color: var(--admin-primary, ##0073aa);
		box-shadow: 0 0 0 1px var(--admin-primary, ##0073aa);
	}

	/* Live Public /howdoi & Mega-Menu Preview Styles */
	.hdi-preview-mega-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
		gap: 1.25rem;
		padding: 1.25rem;
		background: ##f8fafc;
		border: 1px solid ##cbd5e1;
		border-radius: 0.5rem;
	}
	.hdi-preview-mega-col h4 {
		font-size: 0.92rem;
		font-weight: 700;
		color: ##0f172a;
		margin: 0 0 0.5rem 0;
		padding-bottom: 0.35rem;
		border-bottom: 2px solid ##0073aa;
	}
	.hdi-preview-mega-col ul {
		list-style: disc;
		margin: 0;
		padding-left: 1.15rem;
	}
	.hdi-preview-mega-col li {
		margin-bottom: 0.3rem;
		font-size: 0.82rem;
	}
	.hdi-preview-mega-col a {
		color: ##0073aa;
		text-decoration: none;
	}
	.hdi-preview-mega-col a:hover {
		text-decoration: underline;
	}
</style>

<!--- Page Header --->
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.65rem; flex-wrap:wrap;">
			<h1 class="page-title" style="margin-bottom:0;">How Do I</h1>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='pages', action='index')#">Pages</a></li>
				<li class="breadcrumb-item active" aria-current="page">How Do I</li>
			</ol>
		</nav>
	</div>

	<div class="page-actions" style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
		<button type="button" class="btn btn-outline btn-sm" id="btnOpenHowDoIPreview">
			#svgIcon(name="eye", size=14)#
			<span>Preview /howdoi &amp; Mega-Menu</span>
		</button>

		<cfif isAdmin>
			<button type="button" class="btn btn-outline btn-sm" id="btnManageCategories">
				#svgIcon(name="folder", size=14)#
				<span>Categories (#ArrayLen(categories)#)</span>
			</button>
		</cfif>

		<button type="button" class="btn btn-primary btn-sm" id="btnAddHowDoI">
			#svgIcon(name="plus", size=14)#
			<span>Add "How Do I" Link</span>
		</button>
	</div>
</div>

<!--- KPI Summary Row --->
<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:1rem; margin-bottom:1.25rem;">
	<div class="admin-card" style="margin-bottom:0;">
		<div class="card-body" style="padding:1rem 1.25rem; display:flex; align-items:center; justify-content:space-between;">
			<div>
				<div style="font-size:0.75rem; font-weight:600; text-transform:uppercase; color:var(--admin-text-muted);">Action Links</div>
				<div style="font-size:1.55rem; font-weight:700; color:var(--admin-text-main); margin-top:0.15rem;">#totalLinks#</div>
				<div style="font-size:0.73rem; color:var(--admin-text-muted);">#(viewScope eq 'all' ? 'Across all departments' : 'In ' & EncodeForHTML(wsName))#</div>
			</div>
			<div style="width:42px; height:42px; border-radius:10px; background:var(--admin-primary-light); color:var(--admin-primary); display:flex; align-items:center; justify-content:center;">
				#svgIcon(name="help-circle", size=20)#
			</div>
		</div>
	</div>

	<div class="admin-card" style="margin-bottom:0;">
		<div class="card-body" style="padding:1rem 1.25rem; display:flex; align-items:center; justify-content:space-between;">
			<div>
				<div style="font-size:0.75rem; font-weight:600; text-transform:uppercase; color:var(--admin-text-muted);">Published</div>
				<div style="font-size:1.55rem; font-weight:700; color:var(--admin-success); margin-top:0.15rem;">#cntPublished#</div>
				<div style="font-size:0.73rem; color:var(--admin-text-muted);">#cntDraft# draft / hidden</div>
			</div>
			<div style="width:42px; height:42px; border-radius:10px; background:var(--admin-success-light); color:var(--admin-success); display:flex; align-items:center; justify-content:center;">
				#svgIcon(name="check-circle", size=20)#
			</div>
		</div>
	</div>

	<div class="admin-card" style="margin-bottom:0;">
		<div class="card-body" style="padding:1rem 1.25rem; display:flex; align-items:center; justify-content:space-between;">
			<div>
				<div style="font-size:0.75rem; font-weight:600; text-transform:uppercase; color:var(--admin-text-muted);">Mega-Menu Featured</div>
				<div style="font-size:1.55rem; font-weight:700; color:var(--admin-info); margin-top:0.15rem;">#cntMega#</div>
				<div style="font-size:0.73rem; color:var(--admin-text-muted);">Shown in top navbar dropdown</div>
			</div>
			<div style="width:42px; height:42px; border-radius:10px; background:var(--admin-info-light); color:var(--admin-info); display:flex; align-items:center; justify-content:center;">
				#svgIcon(name="layers", size=20)#
			</div>
		</div>
	</div>

	<div class="admin-card" style="margin-bottom:0;">
		<div class="card-body" style="padding:1rem 1.25rem; display:flex; align-items:center; justify-content:space-between;">
			<div>
				<div style="font-size:0.75rem; font-weight:600; text-transform:uppercase; color:var(--admin-text-muted);">Categories</div>
				<div style="font-size:1.55rem; font-weight:700; color:var(--admin-text-main); margin-top:0.15rem;">#cntActiveCats#</div>
				<div style="font-size:0.73rem; color:var(--admin-text-muted);">Apply For, Pay For, Report, etc.</div>
			</div>
			<div style="width:42px; height:42px; border-radius:10px; background:rgba(126, 34, 206, 0.1); color:##7e22ce; display:flex; align-items:center; justify-content:center;">
				#svgIcon(name="folder", size=20)#
			</div>
		</div>
	</div>
</div>

<!--- Main Two-Column Layout --->
<div class="hdi-layout">
	<!--- Left Sidebar: Standard Chelan County Categories --->
	<aside class="hdi-cat-sidebar" aria-label="How Do I Categories">
		<div style="padding:0.9rem 1rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; align-items:center; justify-content:space-between;">
			<span style="font-size:0.8rem; font-weight:700; text-transform:uppercase; letter-spacing:0.04em; color:var(--admin-text-muted);">How Do I Categories</span>
			<cfif isAdmin>
				<button type="button" class="btn btn-xs btn-ghost" id="btnSidebarAddCat" title="Add or Edit Categories" style="padding:0.15rem 0.4rem;">
					#svgIcon(name="settings", size=13)#
				</button>
			</cfif>
		</div>
		<ul class="hdi-cat-list" id="hdiCategoryNav">
			<li>
				<button type="button" class="hdi-cat-btn is-active" data-category-filter="all">
					<span style="display:flex; align-items:center; gap:0.5rem;">
						#svgIcon(name="grid", size=15)#
						<span>All Categories</span>
					</span>
					<span class="hdi-cat-count">#totalLinks#</span>
				</button>
			</li>
			<cfloop array="#categories#" index="cat">
				<cfset cCnt = StructKeyExists(catCounts, "c_" & cat.id) ? catCounts["c_" & cat.id] : 0>
				<li>
					<button type="button" class="hdi-cat-btn" data-category-filter="#cat.id#" data-category-name="#EncodeForHTMLAttribute(cat.name)#">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							#svgIcon(name=cat.icon, size=15)#
							<span>#EncodeForHTML(cat.name)#</span>
						</span>
						<span class="hdi-cat-count">#cCnt#</span>
					</button>
				</li>
			</cfloop>
		</ul>
	</aside>

	<!--- Right Content Column --->
	<div>
		<!--- Search & Filter Bar --->
		<div class="admin-card" style="margin-bottom:1rem;">
			<div class="card-body" style="padding:0.85rem 1.15rem; display:flex; align-items:center; justify-content:space-between; gap:0.75rem; flex-wrap:wrap;">
				<div style="position:relative; flex:1; min-width:220px;">
					<span style="position:absolute; left:0.75rem; top:50%; transform:translateY(-50%); color:var(--admin-text-muted); pointer-events:none;">
						#svgIcon(name="search", size=15)#
					</span>
					<input type="search" id="hdiSearchInput" class="form-control" placeholder="Search 'How Do I' questions, URLs, or departments..." aria-label="Search How Do I links" style="padding-left:2.25rem; width:100%;">
				</div>

				<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
					<select id="hdiTypeFilter" class="form-control" aria-label="Filter by destination type" style="width:auto; min-width:150px;">
						<option value="all">All Link Types</option>
						<option value="page">Site Pages</option>
						<option value="form">Online Forms</option>
						<option value="custom">Custom Paths</option>
						<option value="external">External URLs</option>
					</select>

					<select id="hdiStatusFilter" class="form-control" aria-label="Filter by status" style="width:auto; min-width:140px;">
						<option value="all">All Statuses</option>
						<option value="published">Published Only</option>
						<option value="draft">Draft / Hidden</option>
						<option value="mega">Mega-Menu Featured</option>
					</select>
				</div>
			</div>
		</div>

		<!--- Category Sections --->
		<div id="hdiCategoriesContainer">
			<cfif ArrayLen(categories) eq 0>
				<div class="admin-card" style="text-align:center; padding:3rem 2rem;">
					<div style="width:52px; height:52px; border-radius:14px; background:var(--admin-primary-light); color:var(--admin-primary); display:inline-flex; align-items:center; justify-content:center; margin-bottom:1rem;">
						#svgIcon(name="help-circle", size=28)#
					</div>
					<h3 style="margin:0 0 0.5rem 0; font-size:1.15rem; font-weight:700;">No "How Do I" Categories Found</h3>
					<p style="margin:0 auto 1.25rem; font-size:0.88rem; color:var(--admin-text-muted); max-width:540px; line-height:1.5;">
						Chelan County organizes resident actions across 12 standard action categories: <strong>Apply For</strong>, <strong>Contact</strong>, <strong>Find</strong>, <strong>File A</strong>, <strong>Join</strong>, <strong>Pay For</strong>, <strong>Learn About</strong>, <strong>Register To</strong>, <strong>Report</strong>, <strong>Request</strong>, <strong>Search For</strong>, and <strong>View</strong>.
					</p>
					<button type="button" class="btn btn-primary btn-sm" id="btnPrefillEmptyCats" style="display:inline-flex; align-items:center; gap:0.4rem;">
						#svgIcon(name="plus-circle", size=16)#
						<span>Prefill 12 Standard Categories</span>
					</button>
				</div>
			</cfif>
			<cfloop array="#categories#" index="cat">
				<cfset catItems = []>
				<cfloop array="#howDoIItems#" index="it">
					<cfif it.categoryId eq cat.id>
						<cfset ArrayAppend(catItems, it)>
					</cfif>
				</cfloop>

				<section class="hdi-category-card" data-category-section="#cat.id#" data-has-items="#(ArrayLen(catItems) gt 0 ? '1' : '0')#">
					<div class="hdi-category-header">
						<div style="display:flex; align-items:center; gap:0.65rem;">
							<span style="width:32px; height:32px; border-radius:8px; background:var(--admin-primary-light); color:var(--admin-primary); display:inline-flex; align-items:center; justify-content:center;">
								#svgIcon(name=cat.icon, size=16)#
							</span>
							<div>
								<div style="display:flex; align-items:center; gap:0.5rem;">
									<h2 style="margin:0; font-size:1rem; font-weight:700; color:var(--admin-text-main);">#EncodeForHTML(cat.name)# &hellip;</h2>
									<span class="badge badge-neutral" style="font-size:0.7rem;">#ArrayLen(catItems)# link#(ArrayLen(catItems) eq 1 ? '' : 's')#</span>
									<cfif not cat.isActive>
										<span class="badge badge-warning" style="font-size:0.68rem;">Inactive Category</span>
									</cfif>
								</div>
								<cfif Len(Trim(cat.description))>
									<div style="font-size:0.76rem; color:var(--admin-text-muted); margin-top:0.1rem;">#EncodeForHTML(cat.description)#</div>
								</cfif>
							</div>
						</div>

						<div style="display:flex; align-items:center; gap:0.4rem;">
							<button type="button" class="btn btn-outline btn-xs js-add-in-category" data-category-id="#cat.id#" data-category-name="#EncodeForHTMLAttribute(cat.name)#">
								#svgIcon(name="plus", size=12)#
								<span>Add to "#EncodeForHTML(cat.name)#"</span>
							</button>
						</div>
					</div>

					<div class="hdi-category-items">
						<cfif ArrayLen(catItems) eq 0>
							<div class="hdi-empty-cat" style="padding:1.25rem; text-align:center; color:var(--admin-text-muted); font-size:0.83rem;">
								No "#EncodeForHTML(cat.name)#" links in this view yet.
								<button type="button" class="btn btn-link btn-xs js-add-in-category" data-category-id="#cat.id#" style="padding:0 0.25rem; color:var(--admin-primary); font-weight:600; background:none; border:none; cursor:pointer; text-decoration:underline;">Add one now</button>
							</div>
						<cfelse>
							<cfloop from="1" to="#ArrayLen(catItems)#" index="idx">
								<cfset item = catItems[idx]>
								<cfset tMeta = StructKeyExists(typeLabels, item.destinationType) ? typeLabels[item.destinationType] : typeLabels["custom"]>
								<div class="hdi-item-row"
								     data-item-id="#item.id#"
								     data-category-id="#item.categoryId#"
								     data-site-id="#EncodeForHTMLAttribute(item.siteId)#"
								     data-question="#EncodeForHTMLAttribute(item.question)#"
								     data-dtype="#EncodeForHTMLAttribute(item.destinationType)#"
								     data-page-id="#item.pageId#"
								     data-form-id="#item.formId#"
								     data-url="#EncodeForHTMLAttribute(item.destinationUrl)#"
								     data-new-tab="#(item.openInNewTab ? '1' : '0')#"
								     data-published="#(item.isPublished ? '1' : '0')#"
								     data-mega="#(item.isFeaturedMegaMenu ? '1' : '0')#"
								     data-sort-order="#item.sortOrder#"
								     data-search="#EncodeForHTMLAttribute(LCase(item.question & ' ' & item.destinationUrl & ' ' & item.workspaceName & ' ' & cat.name))#">
									<div class="hdi-item-main">
										<div class="hdi-order-btns" role="group" aria-label="Reorder #EncodeForHTMLAttribute(item.question)#">
											<button type="button" class="hdi-order-btn js-move-item" data-dir="up" data-id="#item.id#" title="Move up" aria-label="Move #EncodeForHTMLAttribute(item.question)# up" <cfif idx eq 1>disabled</cfif>>
												#svgIcon(name="chevron-up", size=12)#
											</button>
											<button type="button" class="hdi-order-btn js-move-item" data-dir="down" data-id="#item.id#" title="Move down" aria-label="Move #EncodeForHTMLAttribute(item.question)# down" <cfif idx eq ArrayLen(catItems)>disabled</cfif>>
												#svgIcon(name="chevron-down", size=12)#
											</button>
										</div>

										<div style="min-width:0; flex:1;">
											<div class="hdi-item-title">
												<span>#EncodeForHTML(item.question)#</span>
												<span class="badge #tMeta.cls#" style="font-size:0.68rem;">#tMeta.label#</span>
												<span class="badge #item.workspaceBadgeClass#" style="font-size:0.68rem;" title="Workspace: #EncodeForHTMLAttribute(item.workspaceName)#">#EncodeForHTML(item.workspaceName)#</span>
												<cfif item.isFeaturedMegaMenu>
													<span class="badge badge-info" style="font-size:0.66rem;" title="Featured in top navigation How Do I Mega-Menu">Mega-Menu</span>
												</cfif>
												<cfif not item.isPublished>
													<span class="badge badge-neutral" style="font-size:0.68rem;">Draft</span>
												</cfif>
											</div>
											<div class="hdi-item-url">
												#svgIcon(name=tMeta.icon, size=12)#
												<a href="#EncodeForHTMLAttribute(item.destinationUrl)#" target="_blank" rel="noopener">
													#EncodeForHTML(item.destinationUrl)#
												</a>
												<cfif item.openInNewTab>
													<span style="font-size:0.7rem; color:var(--admin-text-subtle);">(opens in new tab)</span>
												</cfif>
											</div>
										</div>
									</div>

									<div class="hdi-item-actions">
										<button type="button" class="btn btn-outline btn-xs js-edit-item"
										        data-id="#item.id#"
										        data-category-id="#item.categoryId#"
										        data-site-id="#EncodeForHTMLAttribute(item.siteId)#"
										        data-question="#EncodeForHTMLAttribute(item.question)#"
										        data-dtype="#EncodeForHTMLAttribute(item.destinationType)#"
										        data-page-id="#item.pageId#"
										        data-form-id="#item.formId#"
										        data-url="#EncodeForHTMLAttribute(item.destinationUrl)#"
										        data-new-tab="#(item.openInNewTab ? '1' : '0')#"
										        data-published="#(item.isPublished ? '1' : '0')#"
										        data-mega="#(item.isFeaturedMegaMenu ? '1' : '0')#"
										        data-sort-order="#item.sortOrder#"
										        title="Edit link">
											#svgIcon(name="edit", size=13)#
											<span>Edit</span>
										</button>
										<button type="button" class="btn btn-outline btn-xs js-delete-item" data-id="#item.id#" data-question="#EncodeForHTMLAttribute(item.question)#" style="color:var(--admin-danger);" title="Delete link" aria-label="Delete #EncodeForHTMLAttribute(item.question)#">
											#svgIcon(name="trash", size=13)#
										</button>
									</div>
								</div>
							</cfloop>
						</cfif>
					</div>
				</section>
			</cfloop>
		</div>

		<div id="hdiNoSearchResults" class="admin-card" style="display:none; text-align:center; padding:2.5rem 1.5rem;">
			<div style="color:var(--admin-text-muted); margin-bottom:0.5rem;">#svgIcon(name="search", size=28)#</div>
			<h3 style="margin:0 0 0.35rem 0; font-size:1rem;">No matching "How Do I" links found</h3>
			<p style="margin:0; font-size:0.85rem; color:var(--admin-text-muted);">Try clearing your search filter or switching to "All Categories".</p>
		</div>
	</div>
</div>

<!--- =====================================================================
      MODAL 1: ADD / EDIT "HOW DO I" ITEM
      ===================================================================== --->
<div class="hdi-modal-backdrop" id="hdiItemModal" role="dialog" aria-modal="true" aria-labelledby="hdiItemModalTitle">
	<div class="hdi-modal-dialog">
		<div class="hdi-modal-header">
			<h2 class="hdi-modal-title" id="hdiItemModalTitle">
				#svgIcon(name="help-circle", size=18)#
				<span id="hdiItemModalTitleText">Add "How Do I" Link</span>
			</h2>
			<button type="button" class="btn btn-ghost btn-xs" id="btnCloseItemModal" aria-label="Close dialog">#svgIcon(name="x", size=18)#</button>
		</div>

		<form id="hdiItemForm" onsubmit="return false;">
			<input type="hidden" id="hdiItemId" value="0">
			<div class="hdi-modal-body" style="display:flex; flex-direction:column; gap:1rem;">
				<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(220px, 1fr)); gap:1rem;">
					<div>
						<label for="hdiItemCategory" class="form-label">How Do I Category <span style="color:var(--admin-danger);">*</span></label>
						<select id="hdiItemCategory" class="form-control" required style="width:100%;">
							<cfloop array="#categories#" index="cat">
								<option value="#cat.id#">#EncodeForHTML(cat.name)# ...</option>
							</cfloop>
						</select>
						<div class="pg-help">Choose the action prefix (e.g., Apply For, Pay For, Report).</div>
					</div>

					<input type="hidden" id="hdiItemSiteId" value="#EncodeForHTMLAttribute(wsId)#">
				</div>

				<div>
					<label for="hdiItemQuestion" class="form-label">Action / Link Label <span style="color:var(--admin-danger);">*</span></label>
					<input type="text" id="hdiItemQuestion" class="form-control" maxlength="255" placeholder="e.g. Driveway Permit, Property Taxes, A Job, Concealed Pistol License (CPL)" required style="width:100%; font-weight:600;">
					<div class="pg-help">Completes the phrase &ldquo;<strong id="hdiPhrasePreview">Apply For &hellip;</strong>&rdquo; on <kbd>/howdoi</kbd> and in the top Mega-Menu.</div>
				</div>

				<div>
					<label class="form-label">Destination Type</label>
					<div class="hdi-dtype-grid" role="radiogroup" aria-label="Destination Type">
						<button type="button" class="hdi-dtype-btn is-selected" data-dtype-choice="page">
							#svgIcon(name="file-text", size=16)#
							<span>Site Page</span>
						</button>
						<button type="button" class="hdi-dtype-btn" data-dtype-choice="form">
							#svgIcon(name="form", size=16)#
							<span>Online Form</span>
						</button>
						<button type="button" class="hdi-dtype-btn" data-dtype-choice="custom">
							#svgIcon(name="link", size=16)#
							<span>Custom Path</span>
						</button>
						<button type="button" class="hdi-dtype-btn" data-dtype-choice="external">
							#svgIcon(name="external-link", size=16)#
							<span>External URL</span>
						</button>
					</div>
					<input type="hidden" id="hdiItemDestType" value="page">
				</div>

				<!--- Site Page Picker --->
				<div id="hdiPagePickerWrap">
					<label for="hdiItemPageSelect" class="form-label">Select Workspace Page</label>
					<select id="hdiItemPageSelect" class="form-control" style="width:100%;">
						<option value="">-- Choose a page in #EncodeForHTML(wsName)# --</option>
						<cfloop array="#workspacePages#" index="pg">
							<option value="#pg.id#" data-url="/#EncodeForHTMLAttribute(wsVirtDir)#/pages/#EncodeForHTMLAttribute(pg.slug)#" data-title="#EncodeForHTMLAttribute(pg.title)#">#EncodeForHTML(pg.title)# (/#EncodeForHTML(wsVirtDir)#/pages/#EncodeForHTML(pg.slug)#)</option>
						</cfloop>
					</select>
					<div class="pg-help">Picking a page automatically populates the destination URL below.</div>
				</div>

				<!--- Online Form Picker --->
				<div id="hdiFormPickerWrap" style="display:none;">
					<label for="hdiItemFormSelect" class="form-label">Select Online Form</label>
					<select id="hdiItemFormSelect" class="form-control" style="width:100%;">
						<option value="">-- Choose an online form --</option>
						<cfloop array="#workspaceForms#" index="fm">
							<option value="#fm.id#" data-url="/#EncodeForHTMLAttribute(wsVirtDir)#/forms/#EncodeForHTMLAttribute(fm.slug)#" data-title="#EncodeForHTMLAttribute(fm.title)#">#EncodeForHTML(fm.title)# (/#EncodeForHTML(wsVirtDir)#/forms/#EncodeForHTML(fm.slug)#)</option>
						</cfloop>
					</select>
					<div class="pg-help">Picking a form automatically populates the destination URL below.</div>
				</div>

				<!--- Destination URL --->
				<div>
					<label for="hdiItemUrl" class="form-label">Destination URL / Path <span style="color:var(--admin-danger);">*</span></label>
					<input type="text" id="hdiItemUrl" class="form-control" maxlength="1000" placeholder="/public-works/pages/development or https://..." required style="width:100%;">
					<div class="pg-help">Use a root-relative path (starting with <kbd>/</kbd>) for county pages/forms, or full <kbd>https://</kbd> for external portals.</div>
				</div>

				<!--- Options & Sort Order --->
				<div style="display:grid; grid-template-columns:1fr 130px; gap:1rem; align-items:start; padding:0.85rem 1rem; background:var(--admin-bg); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-md);">
					<div style="display:flex; flex-direction:column; gap:0.55rem;">
						<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.83rem; cursor:pointer;">
							<input type="checkbox" id="hdiItemMega" checked style="width:16px; height:16px; accent-color:var(--admin-primary);">
							<span><strong>Feature in Top "How Do I" Mega-Menu</strong> (as well as <kbd>/howdoi</kbd> directory)</span>
						</label>
						<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.83rem; cursor:pointer;">
							<input type="checkbox" id="hdiItemNewTab" style="width:16px; height:16px; accent-color:var(--admin-primary);">
							<span>Open link in a new browser tab</span>
						</label>
						<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.83rem; cursor:pointer;">
							<input type="checkbox" id="hdiItemPublished" checked style="width:16px; height:16px; accent-color:var(--admin-primary);">
							<span><strong>Published</strong> (visible on public website)</span>
						</label>
					</div>
					<div>
						<label for="hdiItemSort" class="form-label" style="font-size:0.78rem;">Sort Order</label>
						<input type="number" id="hdiItemSort" class="form-control" value="10" step="10" min="0" style="width:100%;">
					</div>
				</div>
			</div>

			<div class="hdi-modal-footer">
				<button type="button" class="btn btn-outline btn-sm" id="btnCancelItemModal">Cancel</button>
				<button type="submit" class="btn btn-primary btn-sm" id="btnSaveHowDoIItem">
					#svgIcon(name="save", size=14)#
					<span>Save "How Do I" Link</span>
				</button>
			</div>
		</form>
	</div>
</div>

<!--- =====================================================================
      MODAL 2: LIVE /HOWDOI DIRECTORY & MEGA-MENU PREVIEW
      ===================================================================== --->
<div class="hdi-modal-backdrop" id="hdiPreviewModal" role="dialog" aria-modal="true" aria-labelledby="hdiPreviewModalTitle">
	<div class="hdi-modal-dialog hdi-modal-xl">
		<div class="hdi-modal-header">
			<h2 class="hdi-modal-title" id="hdiPreviewModalTitle">
				#svgIcon(name="eye", size=18)#
				<span>Live ChelanCounty.gov "How Do I" Preview</span>
			</h2>
			<div style="display:flex; align-items:center; gap:0.5rem;">
				<div style="display:inline-flex; border:1px solid var(--admin-border); border-radius:var(--radius-sm); overflow:hidden;">
					<button type="button" class="btn btn-xs btn-primary" id="btnPreviewTabDir">
						/howdoi Directory Page
					</button>
					<button type="button" class="btn btn-xs btn-ghost" id="btnPreviewTabMega">
						Top Navbar Mega-Menu
					</button>
				</div>
				<button type="button" class="btn btn-ghost btn-xs" id="btnClosePreviewModal" aria-label="Close preview">#svgIcon(name="x", size=18)#</button>
			</div>
		</div>

		<div class="hdi-modal-body">
			<!--- Tab 1: /howdoi Directory View (Matches https://www.chelancounty.gov/howdoi) --->
			<div id="hdiPreviewDirectoryPane">
				<div style="margin-bottom:1rem; padding-bottom:0.75rem; border-bottom:2px solid ##0f172a; display:flex; align-items:baseline; justify-content:space-between; flex-wrap:wrap;">
					<h3 style="margin:0; font-size:1.65rem; font-weight:700; color:##0f172a;">How Do I</h3>
					<span style="font-size:0.78rem; color:var(--admin-text-muted);">Public URL: <strong>https://www.chelancounty.gov/howdoi</strong></span>
				</div>
				<div style="display:grid; grid-template-columns:240px minmax(0, 1fr); gap:1.5rem; align-items:start;">
					<ul id="hdiPreviewSidebarList" style="list-style:none; margin:0; padding:0; border:1px solid ##cbd5e1; border-radius:0.375rem; overflow:hidden;"></ul>
					<div id="hdiPreviewCategoryContent" style="padding:0.25rem 0.5rem;"></div>
				</div>
			</div>

			<!--- Tab 2: Top Navbar Mega-Menu View --->
			<div id="hdiPreviewMegaPane" style="display:none;">
				<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1rem; padding-bottom:0.65rem; border-bottom:2px solid ##0f172a;">
					<h3 style="margin:0; font-size:1.4rem; font-weight:700; color:##0f172a;">How Do I</h3>
					<span class="btn btn-primary btn-xs" style="border-radius:999px; padding:0.35rem 1rem; pointer-events:none;">See All...</span>
				</div>
				<div class="hdi-preview-mega-grid" id="hdiPreviewMegaGrid"></div>
			</div>
		</div>

		<div class="hdi-modal-footer">
			<button type="button" class="btn btn-outline btn-sm" id="btnDismissPreviewModal">Close Preview</button>
		</div>
	</div>
</div>

<!--- =====================================================================
      MODAL 3: MANAGE CATEGORIES (ADMIN ONLY)
      ===================================================================== --->
<cfif isAdmin>
<div class="hdi-modal-backdrop" id="hdiCategoriesModal" role="dialog" aria-modal="true" aria-labelledby="hdiCategoriesModalTitle">
	<div class="hdi-modal-dialog">
		<div class="hdi-modal-header">
			<h2 class="hdi-modal-title" id="hdiCategoriesModalTitle">
				#svgIcon(name="folder", size=18)#
				<span>Manage "How Do I" Categories</span>
			</h2>
			<button type="button" class="btn btn-ghost btn-xs" id="btnCloseCategoriesModal" aria-label="Close categories dialog">#svgIcon(name="x", size=18)#</button>
		</div>

		<div class="hdi-modal-body">
			<form id="hdiCategoryForm" onsubmit="return false;" style="padding:0.9rem; background:var(--admin-bg); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-md); margin-bottom:1rem;">
				<input type="hidden" id="hdiCatId" value="0">
				<div style="font-size:0.8rem; font-weight:700; margin-bottom:0.65rem; color:var(--admin-text-main);" id="hdiCatFormHeading">Add New Category</div>
				<div style="display:grid; grid-template-columns:1fr 120px 90px; gap:0.65rem; margin-bottom:0.65rem;">
					<div>
						<label for="hdiCatName" class="form-label" style="font-size:0.75rem;">Category Name *</label>
						<input type="text" id="hdiCatName" class="form-control" placeholder="e.g. Apply For" required style="width:100%;">
					</div>
					<div>
						<label for="hdiCatIcon" class="form-label" style="font-size:0.75rem;">Icon</label>
						<select id="hdiCatIcon" class="form-control" style="width:100%;">
							<cfloop list="clipboard-list,phone,search,file-text,users,hard-drive,book,check-square,megaphone,mail,globe,eye,help-circle,calendar,map-pin,shield,briefcase,link" index="ic">
								<option value="#ic#">#ic#</option>
							</cfloop>
						</select>
					</div>
					<div>
						<label for="hdiCatSort" class="form-label" style="font-size:0.75rem;">Order</label>
						<input type="number" id="hdiCatSort" class="form-control" value="130" step="10" style="width:100%;">
					</div>
				</div>
				<div style="display:flex; align-items:center; justify-content:space-between; gap:0.65rem;">
					<input type="text" id="hdiCatDesc" class="form-control" placeholder="Short description (optional)" style="flex:1;">
					<button type="button" class="btn btn-outline btn-xs" id="btnResetCatForm" style="display:none;">Cancel Edit</button>
					<button type="submit" class="btn btn-primary btn-xs" id="btnSaveCategory">
						#svgIcon(name="save", size=13)#
						<span id="btnSaveCategoryText">Add Category</span>
					</button>
				</div>
			</form>

			<div style="border:1px solid var(--admin-border-subtle); border-radius:var(--radius-md); overflow:hidden;">
				<cfloop array="#categories#" index="cat">
					<div style="display:flex; align-items:center; justify-content:space-between; padding:0.6rem 0.85rem; border-bottom:1px solid var(--admin-border-subtle); font-size:0.84rem;">
						<div style="display:flex; align-items:center; gap:0.55rem;">
							<span style="color:var(--admin-primary);">#svgIcon(name=cat.icon, size=15)#</span>
							<strong>#EncodeForHTML(cat.name)#</strong>
							<span class="badge badge-neutral" style="font-size:0.68rem;">Order: #cat.sortOrder#</span>
							<span class="badge badge-primary" style="font-size:0.68rem;">#cat.totalItems# links</span>
						</div>
						<div style="display:flex; align-items:center; gap:0.35rem;">
							<button type="button" class="btn btn-outline btn-xs js-edit-cat"
							        data-id="#cat.id#"
							        data-name="#EncodeForHTMLAttribute(cat.name)#"
							        data-icon="#EncodeForHTMLAttribute(cat.icon)#"
							        data-desc="#EncodeForHTMLAttribute(cat.description)#"
							        data-sort="#cat.sortOrder#">
								Edit
							</button>
							<cfif cat.totalItems eq 0 and not cat.isSystem>
								<button type="button" class="btn btn-outline btn-xs js-delete-cat" data-id="#cat.id#" data-name="#EncodeForHTMLAttribute(cat.name)#" style="color:var(--admin-danger);">
									Delete
								</button>
							</cfif>
						</div>
					</div>
				</cfloop>
			</div>
		</div>

		<div class="hdi-modal-footer" style="display:flex; justify-content:space-between; align-items:center;">
			<button type="button" class="btn btn-outline-primary btn-sm" id="btnPrefillStandardCats" style="display:inline-flex; align-items:center; gap:0.35rem;">
				#svgIcon(name="refresh-cw", size=13)#
				<span>Prefill / Reset Standard Categories</span>
			</button>
			<button type="button" class="btn btn-outline btn-sm" id="btnDismissCategoriesModal">Done</button>
		</div>
	</div>
</div>
</cfif>

<script id="hdiConfigData" type="application/json">#howDoIJsonData#</script>
</cfoutput>

<script>
(function() {
	function getField(obj, key, fallback) {
		if (!obj || typeof obj !== "object") return fallback;
		if (obj[key] !== undefined) return obj[key];
		var up = key.toUpperCase();
		if (obj[up] !== undefined) return obj[up];
		var lo = key.toLowerCase();
		if (obj[lo] !== undefined) return obj[lo];
		var found = Object.keys(obj).find(function(k) { return k.toLowerCase() === lo; });
		return found !== undefined ? obj[found] : fallback;
	}

	function ValOrZero(v) {
		var n = parseInt(v, 10);
		return isNaN(n) ? 0 : n;
	}

	function toBool(v, fallback) {
		if (v === undefined || v === null || v === "") return !!fallback;
		if (typeof v === "boolean") return v;
		if (typeof v === "number") return v !== 0;
		var s = String(v).trim().toLowerCase();
		if (s === "1" || s === "true" || s === "yes") return true;
		if (s === "0" || s === "false" || s === "no") return false;
		return !!fallback;
	}

	function normalizeItem(raw) {
		if (!raw || typeof raw !== "object") return null;
		return {
			id: ValOrZero(getField(raw, "id", 0)),
			categoryId: ValOrZero(getField(raw, "categoryId", 0)),
			categoryName: String(getField(raw, "categoryName", "")),
			categorySlug: String(getField(raw, "categorySlug", "")),
			categoryIcon: String(getField(raw, "categoryIcon", "help-circle")),
			siteId: String(getField(raw, "siteId", "global")),
			workspaceName: String(getField(raw, "workspaceName", "Global")),
			question: String(getField(raw, "question", "")),
			destinationType: String(getField(raw, "destinationType", "custom")).toLowerCase(),
			pageId: ValOrZero(getField(raw, "pageId", 0)),
			formId: ValOrZero(getField(raw, "formId", 0)),
			destinationUrl: String(getField(raw, "destinationUrl", "")),
			openInNewTab: toBool(getField(raw, "openInNewTab", false), false),
			isFeaturedMegaMenu: toBool(getField(raw, "isFeaturedMegaMenu", true), true),
			sortOrder: ValOrZero(getField(raw, "sortOrder", 10)),
			isPublished: toBool(getField(raw, "isPublished", true), true)
		};
	}

	function normalizeCategory(raw) {
		if (!raw || typeof raw !== "object") return null;
		return {
			id: ValOrZero(getField(raw, "id", 0)),
			name: String(getField(raw, "name", "")),
			slug: String(getField(raw, "slug", "")),
			icon: String(getField(raw, "icon", "help-circle")),
			description: String(getField(raw, "description", "")),
			sortOrder: ValOrZero(getField(raw, "sortOrder", 10)),
			isActive: toBool(getField(raw, "isActive", true), true),
			isSystem: toBool(getField(raw, "isSystem", false), false),
			totalItems: ValOrZero(getField(raw, "totalItems", 0))
		};
	}

	var cfgEl = document.getElementById("hdiConfigData");
	var rawCfg = {};
	try {
		rawCfg = cfgEl ? JSON.parse(cfgEl.textContent) : {};
	} catch (errCfg) {
		rawCfg = {};
	}

	var rawUrls = getField(rawCfg, "urls", {}) || {};
	var rawWs = getField(rawCfg, "activeWorkspace", {}) || {};

	var cfg = {
		items: (getField(rawCfg, "items", []) || []).map(normalizeItem).filter(Boolean),
		countyItems: (getField(rawCfg, "countyItems", []) || []).map(normalizeItem).filter(Boolean),
		categories: (getField(rawCfg, "categories", []) || []).map(normalizeCategory).filter(Boolean),
		activeWorkspace: {
			id: String(getField(rawWs, "id", "global")),
			name: String(getField(rawWs, "name", "Global")),
			virtualDir: String(getField(rawWs, "virtualDir", "shared"))
		},
		urls: {
			saveItem: String(getField(rawUrls, "saveItem", "/pages/how-do-i/save")),
			deleteItem: String(getField(rawUrls, "deleteItem", "/pages/how-do-i/delete")),
			reorderItems: String(getField(rawUrls, "reorderItems", "/pages/how-do-i/reorder")),
			saveCategory: String(getField(rawUrls, "saveCategory", "/pages/how-do-i/category/save")),
			deleteCategory: String(getField(rawUrls, "deleteCategory", "/pages/how-do-i/category/delete"))
		}
	};

	var itemsById = {};
	cfg.items.forEach(function(it) { itemsById[it.id] = it; });

	function showDialogAlert(message, options) {
		var opts = options || {};
		if (typeof window.adminAlert === "function") {
			return window.adminAlert(message, opts);
		}
		if (typeof window.showToast === "function") {
			window.showToast(message, opts.type || "danger");
		}
		return Promise.resolve(true);
	}

	function showDialogConfirm(message, options) {
		var opts = options || {};
		if (typeof window.adminConfirm === "function") {
			return window.adminConfirm(message, opts);
		}
		return Promise.resolve(false);
	}

	function hdiPostJson(url, payload) {
		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var headers = {
			"Content-Type": "application/json; charset=utf-8",
			"Accept": "application/json",
			"X-Requested-With": "XMLHttpRequest"
		};
		if (csrfMeta && csrfMeta.getAttribute("content")) {
			headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
		}

		return fetch(url, {
			method: "POST",
			credentials: "same-origin",
			headers: headers,
			body: JSON.stringify(payload || {})
		}).then(function(response) {
			return response.text().then(function(text) {
				var data = {};
				try {
					data = text ? JSON.parse(text) : {};
				} catch (errJson) {
					throw new Error("The server returned an unexpected response (HTTP " + response.status + ").");
				}
				var okFlag = toBool(getField(data, "success", false), false);
				var msg = getField(data, "message", "");
				if (!response.ok || !okFlag) {
					throw new Error(msg || ("Unable to complete request (HTTP " + response.status + ")."));
				}
				return {
					success: true,
					message: msg,
					id: ValOrZero(getField(data, "id", 0)),
					raw: data
				};
			});
		});
	}

	var activeCatFilter = "all";
	var searchInput = document.getElementById("hdiSearchInput");
	var typeFilter = document.getElementById("hdiTypeFilter");
	var statusFilter = document.getElementById("hdiStatusFilter");
	var noResultsEl = document.getElementById("hdiNoSearchResults");

	function applyFilters() {
		var q = (searchInput ? searchInput.value : "").trim().toLowerCase();
		var dtype = typeFilter ? typeFilter.value : "all";
		var st = statusFilter ? statusFilter.value : "all";
		var anyVisible = false;

		document.querySelectorAll("[data-category-section]").forEach(function(sec) {
			var catId = sec.getAttribute("data-category-section");
			if (activeCatFilter !== "all" && String(catId) !== String(activeCatFilter)) {
				sec.style.display = "none";
				return;
			}

			var rows = sec.querySelectorAll(".hdi-item-row");
			var visibleInCat = 0;
			rows.forEach(function(row) {
				var matchQ = !q || (row.getAttribute("data-search") || "").indexOf(q) !== -1;
				var matchType = (dtype === "all") || (row.getAttribute("data-dtype") === dtype);
				var matchStatus = true;
				if (st === "published") matchStatus = (row.getAttribute("data-published") === "1");
				else if (st === "draft") matchStatus = (row.getAttribute("data-published") === "0");
				else if (st === "mega") matchStatus = (row.getAttribute("data-mega") === "1");

				var show = matchQ && matchType && matchStatus;
				row.style.display = show ? "" : "none";
				if (show) visibleInCat++;
			});

			var isFiltering = (q !== "" || dtype !== "all" || st !== "all");
			if (activeCatFilter !== "all") {
				sec.style.display = "";
				anyVisible = true;
			} else if (isFiltering) {
				sec.style.display = visibleInCat > 0 ? "" : "none";
				if (visibleInCat > 0) anyVisible = true;
			} else {
				sec.style.display = "";
				anyVisible = true;
			}
		});

		if (noResultsEl) {
			noResultsEl.style.display = anyVisible ? "none" : "";
		}
	}

	// Category Sidebar Filter Clicks
	document.querySelectorAll("[data-category-filter]").forEach(function(btn) {
		btn.addEventListener("click", function() {
			document.querySelectorAll("[data-category-filter]").forEach(function(b) { b.classList.remove("is-active"); });
			btn.classList.add("is-active");
			activeCatFilter = btn.getAttribute("data-category-filter") || "all";
			applyFilters();
		});
	});

	if (searchInput) searchInput.addEventListener("input", applyFilters);
	if (typeFilter) typeFilter.addEventListener("change", applyFilters);
	if (statusFilter) statusFilter.addEventListener("change", applyFilters);

	// =========================================================================
	// Add / Edit Item Modal
	// =========================================================================
	var itemModal = document.getElementById("hdiItemModal");
	var itemForm = document.getElementById("hdiItemForm");
	var fldId = document.getElementById("hdiItemId");
	var fldCat = document.getElementById("hdiItemCategory");
	var fldSite = document.getElementById("hdiItemSiteId");
	var fldQuestion = document.getElementById("hdiItemQuestion");
	var fldDestType = document.getElementById("hdiItemDestType");
	var fldPageSelect = document.getElementById("hdiItemPageSelect");
	var fldFormSelect = document.getElementById("hdiItemFormSelect");
	var fldUrl = document.getElementById("hdiItemUrl");
	var fldMega = document.getElementById("hdiItemMega");
	var fldNewTab = document.getElementById("hdiItemNewTab");
	var fldPublished = document.getElementById("hdiItemPublished");
	var fldSort = document.getElementById("hdiItemSort");
	var phrasePreview = document.getElementById("hdiPhrasePreview");

	function updatePhrasePreview() {
		if (!phrasePreview || !fldCat) return;
		var opt = fldCat.options[fldCat.selectedIndex];
		var catName = opt ? opt.text.replace(/\s*\.\.\.$/, "") : "Apply For";
		var qVal = (fldQuestion && fldQuestion.value.trim()) ? fldQuestion.value.trim() : "...";
		phrasePreview.textContent = catName + " " + qVal;
	}

	function setDestinationTypeUI(dtype) {
		var normType = (dtype || "page").toLowerCase();
		if (["page", "form", "custom", "external"].indexOf(normType) === -1) {
			normType = "custom";
		}
		fldDestType.value = normType;
		document.querySelectorAll("[data-dtype-choice]").forEach(function(b) {
			b.classList.toggle("is-selected", b.getAttribute("data-dtype-choice") === normType);
		});
		var pageWrap = document.getElementById("hdiPagePickerWrap");
		var formWrap = document.getElementById("hdiFormPickerWrap");
		if (pageWrap) pageWrap.style.display = (normType === "page") ? "" : "none";
		if (formWrap) formWrap.style.display = (normType === "form") ? "" : "none";
		if (normType === "external" && fldNewTab && ValOrZero(fldId.value) === 0) {
			fldNewTab.checked = true;
		}
	}

	document.querySelectorAll("[data-dtype-choice]").forEach(function(btn) {
		btn.addEventListener("click", function() {
			setDestinationTypeUI(btn.getAttribute("data-dtype-choice"));
		});
	});

	if (fldCat) fldCat.addEventListener("change", updatePhrasePreview);
	if (fldQuestion) fldQuestion.addEventListener("input", updatePhrasePreview);

	if (fldPageSelect) {
		fldPageSelect.addEventListener("change", function() {
			var opt = fldPageSelect.options[fldPageSelect.selectedIndex];
			if (opt && opt.getAttribute("data-url")) {
				fldUrl.value = opt.getAttribute("data-url");
				if (!fldQuestion.value.trim() && opt.getAttribute("data-title")) {
					fldQuestion.value = opt.getAttribute("data-title");
					updatePhrasePreview();
				}
			}
		});
	}

	if (fldFormSelect) {
		fldFormSelect.addEventListener("change", function() {
			var opt = fldFormSelect.options[fldFormSelect.selectedIndex];
			if (opt && opt.getAttribute("data-url")) {
				fldUrl.value = opt.getAttribute("data-url");
				if (!fldQuestion.value.trim() && opt.getAttribute("data-title")) {
					fldQuestion.value = opt.getAttribute("data-title");
					updatePhrasePreview();
				}
			}
		});
	}

	function extractItemFromElement(el) {
		if (!el) return null;
		var row = el.closest(".hdi-item-row");
		var id = ValOrZero(el.getAttribute("data-id") || (row ? row.getAttribute("data-item-id") : 0));
		if (id > 0 && itemsById[id]) {
			return itemsById[id];
		}
		var src = el.hasAttribute("data-question") ? el : row;
		if (!src || id <= 0) return null;
		return {
			id: id,
			categoryId: ValOrZero(src.getAttribute("data-category-id")),
			siteId: src.getAttribute("data-site-id") || cfg.activeWorkspace.id || "global",
			question: src.getAttribute("data-question") || "",
			destinationType: (src.getAttribute("data-dtype") || "custom").toLowerCase(),
			pageId: ValOrZero(src.getAttribute("data-page-id")),
			formId: ValOrZero(src.getAttribute("data-form-id")),
			destinationUrl: src.getAttribute("data-url") || "",
			openInNewTab: src.getAttribute("data-new-tab") === "1",
			isFeaturedMegaMenu: src.getAttribute("data-mega") !== "0",
			isPublished: src.getAttribute("data-published") !== "0",
			sortOrder: ValOrZero(src.getAttribute("data-sort-order")) || 10
		};
	}

	function openItemModal(item, defaultCategoryId) {
		if (!itemModal) return;
		var isEdit = !!(item && item.id > 0);
		document.getElementById("hdiItemModalTitleText").textContent = isEdit ? 'Edit "How Do I" Link' : 'Add "How Do I" Link';
		fldId.value = isEdit ? item.id : 0;
		if (isEdit) {
			fldCat.value = String(item.categoryId);
			if (fldSite) {
				var targetSite = (item.siteId || cfg.activeWorkspace.id || "global").toLowerCase();
				var hasOption = Array.from(fldSite.options).some(function(o) { return o.value.toLowerCase() === targetSite; });
				if (!hasOption && item.siteId) {
					var extraOpt = document.createElement("option");
					extraOpt.value = item.siteId;
					extraOpt.textContent = item.workspaceName || item.siteId;
					fldSite.appendChild(extraOpt);
				}
				Array.from(fldSite.options).forEach(function(o) {
					if (o.value.toLowerCase() === targetSite) fldSite.value = o.value;
				});
			}
			fldQuestion.value = item.question || "";
			setDestinationTypeUI(item.destinationType || "custom");
			if (fldPageSelect) fldPageSelect.value = item.pageId > 0 ? String(item.pageId) : "";
			if (fldFormSelect) fldFormSelect.value = item.formId > 0 ? String(item.formId) : "";
			fldUrl.value = item.destinationUrl || "";
			fldMega.checked = !!item.isFeaturedMegaMenu;
			fldNewTab.checked = !!item.openInNewTab;
			fldPublished.checked = !!item.isPublished;
			fldSort.value = item.sortOrder || 10;
		} else {
			if (defaultCategoryId) fldCat.value = String(defaultCategoryId);
			else if (activeCatFilter !== "all") fldCat.value = String(activeCatFilter);
			if (fldSite && cfg.activeWorkspace.id && cfg.activeWorkspace.id !== "all") {
				fldSite.value = cfg.activeWorkspace.id;
			}
			fldQuestion.value = "";
			setDestinationTypeUI("page");
			if (fldPageSelect) fldPageSelect.value = "";
			if (fldFormSelect) fldFormSelect.value = "";
			fldUrl.value = "";
			fldMega.checked = true;
			fldNewTab.checked = false;
			fldPublished.checked = true;
			fldSort.value = 10;
		}
		updatePhrasePreview();
		itemModal.classList.add("is-open");
		setTimeout(function() { fldQuestion.focus(); }, 50);
	}

	function closeItemModal() {
		if (itemModal) itemModal.classList.remove("is-open");
	}

	var btnAddMain = document.getElementById("btnAddHowDoI");
	if (btnAddMain) btnAddMain.addEventListener("click", function() { openItemModal(null, null); });
	document.getElementById("btnCloseItemModal").addEventListener("click", closeItemModal);
	document.getElementById("btnCancelItemModal").addEventListener("click", closeItemModal);
	if (itemModal) {
		itemModal.addEventListener("click", function(e) {
			if (e.target === itemModal) closeItemModal();
		});
	}

	document.querySelectorAll(".js-add-in-category").forEach(function(btn) {
		btn.addEventListener("click", function() {
			openItemModal(null, btn.getAttribute("data-category-id"));
		});
	});

	document.querySelectorAll(".js-edit-item").forEach(function(btn) {
		btn.addEventListener("click", function(e) {
			e.preventDefault();
			var itemData = extractItemFromElement(btn);
			if (itemData) {
				openItemModal(itemData, null);
			} else {
				showDialogAlert("Unable to load item details for editing.", { title: "Edit Item", type: "warning" });
			}
		});
	});

	if (itemForm) {
		itemForm.addEventListener("submit", async function(e) {
			e.preventDefault();
			var qText = fldQuestion.value.trim();
			var urlText = fldUrl.value.trim();

			if (!qText) {
				await showDialogAlert("Please enter an Action / Link Label (e.g. Driveway Permit, Property Taxes).", {
					title: "Action Label Required",
					type: "warning"
				});
				fldQuestion.focus();
				return;
			}

			if (!urlText) {
				await showDialogAlert("Please select a page/form or enter a Destination URL.", {
					title: "Destination URL Required",
					type: "warning"
				});
				fldUrl.focus();
				return;
			}

			var payload = {
				id: ValOrZero(fldId.value),
				categoryId: ValOrZero(fldCat.value),
				siteId: fldSite ? fldSite.value : cfg.activeWorkspace.id,
				question: qText,
				destinationType: fldDestType.value,
				pageId: fldPageSelect ? ValOrZero(fldPageSelect.value) : 0,
				formId: fldFormSelect ? ValOrZero(fldFormSelect.value) : 0,
				destinationUrl: urlText,
				isFeaturedMegaMenu: fldMega.checked,
				openInNewTab: fldNewTab.checked,
				isPublished: fldPublished.checked,
				sortOrder: ValOrZero(fldSort.value)
			};

			var saveBtn = document.getElementById("btnSaveHowDoIItem");
			var origBtnHtml = saveBtn ? saveBtn.innerHTML : "";
			if (saveBtn) {
				saveBtn.disabled = true;
				saveBtn.innerHTML = '<span>Saving...</span>';
			}

			try {
				await hdiPostJson(cfg.urls.saveItem, payload);
				closeItemModal();
				if (typeof window.showToast === "function") {
					window.showToast('Saved "' + qText + '" to How Do I.', "success");
				}
				window.location.reload();
			} catch (err) {
				if (saveBtn) {
					saveBtn.disabled = false;
					saveBtn.innerHTML = origBtnHtml;
				}
				await showDialogAlert(err.message || "Unable to save How Do I item.", {
					title: "Unable to Save Link",
					type: "danger"
				});
			}
		});
	}

	// Delete Item (using built-in window.adminConfirm / window.adminAlert)
	document.querySelectorAll(".js-delete-item").forEach(function(btn) {
		btn.addEventListener("click", async function(e) {
			e.preventDefault();
			var id = ValOrZero(btn.getAttribute("data-id"));
			var q = btn.getAttribute("data-question") || "this link";
			var confirmed = await showDialogConfirm('Are you sure you want to remove "' + q + '" from How Do I?', {
				title: 'Remove "How Do I" Link?',
				acceptText: "Remove Link",
				cancelText: "Cancel",
				destructive: true
			});
			if (!confirmed) return;

			try {
				await hdiPostJson(cfg.urls.deleteItem, { id: id });
				if (typeof window.showToast === "function") {
					window.showToast('Removed "' + q + '".', "success");
				}
				window.location.reload();
			} catch (err) {
				await showDialogAlert(err.message || "Unable to delete item.", {
					title: "Unable to Remove Link",
					type: "danger"
				});
			}
		});
	});

	// Reorder Up / Down within Category
	document.querySelectorAll(".js-move-item").forEach(function(btn) {
		btn.addEventListener("click", function() {
			var row = btn.closest(".hdi-item-row");
			if (!row) return;
			var container = row.parentElement;
			var dir = btn.getAttribute("data-dir");
			var sibling = (dir === "up") ? row.previousElementSibling : row.nextElementSibling;
			if (!sibling || !sibling.classList.contains("hdi-item-row")) return;

			if (dir === "up") container.insertBefore(row, sibling);
			else container.insertBefore(sibling, row);

			var updates = [];
			var allRows = container.querySelectorAll(".hdi-item-row");
			allRows.forEach(function(r, i) {
				var upBtn = r.querySelector('.js-move-item[data-dir="up"]');
				var dnBtn = r.querySelector('.js-move-item[data-dir="down"]');
				if (upBtn) upBtn.disabled = (i === 0);
				if (dnBtn) dnBtn.disabled = (i === allRows.length - 1);
				updates.push({
					id: ValOrZero(r.getAttribute("data-item-id")),
					sortOrder: (i + 1) * 10
				});
			});

			hdiPostJson(cfg.urls.reorderItems, { items: updates })
				.then(function() {
					if (typeof window.showToast === "function") {
						window.showToast("Link order updated.", "info", 2000);
					}
				})
				.catch(function(err) {
					showDialogAlert(err.message || "Unable to update link order.", {
						title: "Reorder Failed",
						type: "danger"
					});
				});
		});
	});

	// =========================================================================
	// Live /howdoi Directory & Mega-Menu Preview Modal
	// =========================================================================
	var previewModal = document.getElementById("hdiPreviewModal");
	var selectedPreviewCatId = (cfg.categories && cfg.categories.length) ? cfg.categories[0].id : 0;

	function renderPreviewModal() {
		var sourceItems = (cfg.countyItems && cfg.countyItems.length) ? cfg.countyItems : cfg.items;
		var pubItems = (sourceItems || []).filter(function(it) { return it.isPublished; });
		var sidebarEl = document.getElementById("hdiPreviewSidebarList");
		var contentEl = document.getElementById("hdiPreviewCategoryContent");
		var megaGridEl = document.getElementById("hdiPreviewMegaGrid");

		if (sidebarEl && contentEl) {
			sidebarEl.innerHTML = "";
			(cfg.categories || []).forEach(function(cat) {
				if (!cat.isActive) return;
				var li = document.createElement("li");
				li.style.borderBottom = "1px solid #e2e8f0";
				var a = document.createElement("button");
				a.type = "button";
				var isSel = (cat.id === selectedPreviewCatId);
				a.style.cssText = "width:100%; text-align:left; padding:0.65rem 0.9rem; border:none; cursor:pointer; font-size:0.88rem; font-weight:" + (isSel ? "700" : "500") + "; background:" + (isSel ? "#0073aa" : "#ffffff") + "; color:" + (isSel ? "#ffffff" : "#0f172a") + "; display:flex; justify-content:space-between; align-items:center;";
				var catMatches = pubItems.filter(function(i) { return i.categoryId === cat.id; });
				a.innerHTML = "<span>" + escapeHtml(cat.name) + "</span><span style='font-size:0.74rem; opacity:0.85;'>" + catMatches.length + "</span>";
				a.addEventListener("click", function() {
					selectedPreviewCatId = cat.id;
					renderPreviewModal();
				});
				li.appendChild(a);
				sidebarEl.appendChild(li);
			});

			var activeCat = (cfg.categories || []).find(function(c) { return c.id === selectedPreviewCatId; }) || (cfg.categories || [])[0];
			if (activeCat) {
				var catLinks = pubItems.filter(function(i) { return i.categoryId === activeCat.id; });
				var html = "<h2 style='margin:0 0 1rem 0; font-size:1.5rem; font-weight:700; color:#0f172a; border-bottom:2px solid #e2e8f0; padding-bottom:0.5rem;'>" + escapeHtml(activeCat.name) + "</h2>";
				if (catLinks.length === 0) {
					html += "<p style='color:#64748b;'>No published links in this category yet.</p>";
				} else {
					html += "<ul style='line-height:1.9; font-size:0.95rem; padding-left:1.25rem;'>";
					catLinks.forEach(function(lk) {
						html += "<li><a href='" + escapeHtml(lk.destinationUrl) + "' target='_blank' rel='noopener' style='color:#0073aa; text-decoration:none; font-weight:500;'>" + escapeHtml(lk.question) + "</a> <span style='font-size:0.74rem; color:#64748b; margin-left:0.35rem;'>(" + escapeHtml(lk.workspaceName) + ")</span></li>";
					});
					html += "</ul>";
				}
				contentEl.innerHTML = html;
			}
		}

		if (megaGridEl) {
			megaGridEl.innerHTML = "";
			(cfg.categories || []).forEach(function(cat) {
				if (!cat.isActive) return;
				var megaLinks = pubItems.filter(function(i) { return i.categoryId === cat.id && i.isFeaturedMegaMenu; }).slice(0, 5);
				if (megaLinks.length === 0) return;
				var col = document.createElement("div");
				col.className = "hdi-preview-mega-col";
				var ulHtml = "<h4>" + escapeHtml(cat.name) + "</h4><ul>";
				megaLinks.forEach(function(lk) {
					ulHtml += "<li><a href='" + escapeHtml(lk.destinationUrl) + "' target='_blank' rel='noopener'>" + escapeHtml(lk.question) + "</a></li>";
				});
				ulHtml += "</ul>";
				col.innerHTML = ulHtml;
				megaGridEl.appendChild(col);
			});
		}
	}

	function escapeHtml(s) {
		return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
	}

	var btnOpenPreview = document.getElementById("btnOpenHowDoIPreview");
	if (btnOpenPreview && previewModal) {
		btnOpenPreview.addEventListener("click", function() {
			renderPreviewModal();
			previewModal.classList.add("is-open");
		});
		document.getElementById("btnClosePreviewModal").addEventListener("click", function() { previewModal.classList.remove("is-open"); });
		document.getElementById("btnDismissPreviewModal").addEventListener("click", function() { previewModal.classList.remove("is-open"); });
		previewModal.addEventListener("click", function(e) {
			if (e.target === previewModal) previewModal.classList.remove("is-open");
		});

		var tabDir = document.getElementById("btnPreviewTabDir");
		var tabMega = document.getElementById("btnPreviewTabMega");
		var paneDir = document.getElementById("hdiPreviewDirectoryPane");
		var paneMega = document.getElementById("hdiPreviewMegaPane");

		tabDir.addEventListener("click", function() {
			tabDir.className = "btn btn-xs btn-primary";
			tabMega.className = "btn btn-xs btn-ghost";
			paneDir.style.display = "";
			paneMega.style.display = "none";
		});
		tabMega.addEventListener("click", function() {
			tabMega.className = "btn btn-xs btn-primary";
			tabDir.className = "btn btn-xs btn-ghost";
			paneMega.style.display = "";
			paneDir.style.display = "none";
		});
	}

	// =========================================================================
	// Admin Categories Modal
	// =========================================================================
	var catModal = document.getElementById("hdiCategoriesModal");
	var btnManageCats = document.getElementById("btnManageCategories");
	var btnSidebarAddCat = document.getElementById("btnSidebarAddCat");
	if (catModal) {
		if (btnManageCats) btnManageCats.addEventListener("click", function() { catModal.classList.add("is-open"); });
		if (btnSidebarAddCat) btnSidebarAddCat.addEventListener("click", function() { catModal.classList.add("is-open"); });
		document.getElementById("btnCloseCategoriesModal").addEventListener("click", function() { catModal.classList.remove("is-open"); });
		document.getElementById("btnDismissCategoriesModal").addEventListener("click", function() { catModal.classList.remove("is-open"); });
		catModal.addEventListener("click", function(e) {
			if (e.target === catModal) catModal.classList.remove("is-open");
		});

		var catForm = document.getElementById("hdiCategoryForm");
		var catIdFld = document.getElementById("hdiCatId");
		var catNameFld = document.getElementById("hdiCatName");
		var catIconFld = document.getElementById("hdiCatIcon");
		var catSortFld = document.getElementById("hdiCatSort");
		var catDescFld = document.getElementById("hdiCatDesc");
		var btnResetCat = document.getElementById("btnResetCatForm");

		document.querySelectorAll(".js-edit-cat").forEach(function(btn) {
			btn.addEventListener("click", function() {
				catIdFld.value = btn.getAttribute("data-id");
				catNameFld.value = btn.getAttribute("data-name") || "";
				catIconFld.value = btn.getAttribute("data-icon") || "help-circle";
				catDescFld.value = btn.getAttribute("data-desc") || "";
				catSortFld.value = btn.getAttribute("data-sort") || "100";
				document.getElementById("hdiCatFormHeading").textContent = "Edit Category: " + catNameFld.value;
				document.getElementById("btnSaveCategoryText").textContent = "Update Category";
				btnResetCat.style.display = "";
				catNameFld.focus();
			});
		});

		if (btnResetCat) {
			btnResetCat.addEventListener("click", function() {
				catIdFld.value = "0";
				catNameFld.value = "";
				catDescFld.value = "";
				catSortFld.value = "130";
				document.getElementById("hdiCatFormHeading").textContent = "Add New Category";
				document.getElementById("btnSaveCategoryText").textContent = "Add Category";
				btnResetCat.style.display = "none";
			});
		}

		if (catForm) {
			catForm.addEventListener("submit", async function(e) {
				e.preventDefault();
				var catNameVal = catNameFld.value.trim();
				if (!catNameVal) {
					await showDialogAlert("Please enter a Category Name.", {
						title: "Category Name Required",
						type: "warning"
					});
					catNameFld.focus();
					return;
				}
				try {
					await hdiPostJson(cfg.urls.saveCategory, {
						id: ValOrZero(catIdFld.value),
						name: catNameVal,
						icon: catIconFld.value,
						description: catDescFld.value.trim(),
						sortOrder: ValOrZero(catSortFld.value),
						isActive: true
					});
					window.location.reload();
				} catch (err) {
					await showDialogAlert(err.message || "Unable to save category.", {
						title: "Unable to Save Category",
						type: "danger"
					});
				}
			});
		}

		document.querySelectorAll(".js-delete-cat").forEach(function(btn) {
			btn.addEventListener("click", async function() {
				var id = ValOrZero(btn.getAttribute("data-id"));
				var nm = btn.getAttribute("data-name") || "this category";
				var confirmed = await showDialogConfirm('Delete the category "' + nm + '"?', {
					title: "Delete Category?",
					acceptText: "Delete Category",
					cancelText: "Cancel",
					destructive: true
				});
				if (!confirmed) return;

				try {
					await hdiPostJson(cfg.urls.deleteCategory, { id: id });
					window.location.reload();
				} catch (err) {
					await showDialogAlert(err.message || "Unable to delete category.", {
						title: "Unable to Delete Category",
						type: "danger"
					});
				}
			});
		});

		var btnPrefill = document.getElementById("btnPrefillStandardCats");
		var btnPrefillEmpty = document.getElementById("btnPrefillEmptyCats");
		async function handlePrefillCategories() {
			var confirmed = await showDialogConfirm(
				"Prefill the 12 standard Chelan County 'How Do I' action categories (Apply For, Contact, Find, File A, Join, Pay For, Learn About, Register To, Report, Request, Search For, View)? Any missing standard categories will be added or restored.",
				{
					title: "Prefill Standard Categories",
					acceptText: "Prefill Categories",
					cancelText: "Cancel",
					destructive: false
				}
			);
			if (!confirmed) return;
			try {
				await hdiPostJson(cfg.urls.prefillCategories, {});
				window.location.reload();
			} catch (err) {
				await showDialogAlert(err.message || "Unable to prefill categories.", {
					title: "Prefill Failed",
					type: "danger"
				});
			}
		}
		if (btnPrefill) btnPrefill.addEventListener("click", handlePrefillCategories);
		if (btnPrefillEmpty) btnPrefillEmpty.addEventListener("click", handlePrefillCategories);
	}
})();
</script>

