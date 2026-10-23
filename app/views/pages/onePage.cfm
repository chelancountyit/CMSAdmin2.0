<cfoutput>
<!--- One Page Studio — Chelan County CMSAdmin 2.0 (WCAG 2.1 AA Compliant) --->
<cfscript>
	currentWs = variables.activeWorkspaceId ?: "global";
	currentWsObj = variables.activeWsObj ?: {};
	wsName = currentWsObj.name ?: "All Workspaces";
	allSites = variables.onePageSites ?: [];
	totalSitesCount = ArrayLen(allSites);
	selSite = variables.selectedSite ?: {};
	selSections = variables.selectedSections ?: [];
	candidatePages = variables.candidatePages ?: [];

	// JSON payload for dynamic client-side interactions
	opsJsonData = Replace(SerializeJSON({
		"sites": allSites,
		"selectedSite": selSite,
		"sections": selSections,
		"candidatePages": candidatePages,
		"activeWorkspace": currentWs,
		"routes": {
			"saveSite": "/pages/one-page/save",
			"deleteSite": "/pages/one-page/delete",
			"saveSection": "/pages/one-page/section/save",
			"deleteSection": "/pages/one-page/section/delete",
			"reorderSections": "/pages/one-page/sections/reorder",
			"syncMenu": "/pages/one-page/sync-menu",
			"compile": "/pages/one-page/compile",
			"publish": "/pages/one-page/publish-production",
			"preview": "/pages/one-page/preview",
			"export": "/pages/one-page/export",
			"navigation": "/navigation"
		}
	}), "</", "<\\/", "all");
</cfscript>

<style>
	/* One Page Studio Styles */
	.ops-header {
		margin-bottom: 1.5rem;
	}
	.ops-stats-bar {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
		gap: 1rem;
		margin-bottom: 1.5rem;
	}
	.ops-stat-card {
		background: var(--admin-surface);
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 1rem 1.25rem;
		display: flex;
		align-items: center;
		gap: 1rem;
		box-shadow: var(--shadow-sm);
	}
	.ops-stat-icon {
		width: 44px;
		height: 44px;
		border-radius: var(--radius-md);
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}
	.ops-tab-nav {
		display: flex;
		gap: 0.5rem;
		border-bottom: 1px solid var(--admin-border);
		margin-bottom: 1.5rem;
	}
	.ops-tab-btn {
		background: transparent;
		border: none;
		border-bottom: 3px solid transparent;
		color: var(--admin-text-muted);
		font-weight: 600;
		font-size: 0.9rem;
		padding: 0.75rem 1.25rem;
		cursor: pointer;
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		transition: all 0.15s ease;
	}
	.ops-tab-btn:hover {
		color: var(--admin-text-main);
	}
	.ops-tab-btn.active {
		color: var(--admin-primary);
		border-bottom-color: var(--admin-primary);
	}
	.ops-studio-layout {
		display: grid;
		grid-template-columns: minmax(0, 1.65fr) minmax(360px, 1fr);
		gap: 1.5rem;
		align-items: start;
	}
	@media (max-width: 1200px) {
		.ops-studio-layout {
			grid-template-columns: 1fr;
		}
	}
	.ops-card {
		background: var(--admin-surface);
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		box-shadow: var(--shadow-sm);
		margin-bottom: 1.5rem;
		overflow: hidden;
	}
	.ops-card-header {
		padding: 1rem 1.25rem;
		border-bottom: 1px solid var(--admin-border-subtle);
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-wrap: wrap;
		gap: 0.75rem;
		background: var(--admin-surface-hover);
	}
	.ops-card-title {
		font-size: 0.95rem;
		font-weight: 700;
		color: var(--admin-text-main);
		margin: 0;
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}
	.ops-card-body {
		padding: 1.25rem;
	}
	.ops-section-row {
		background: var(--admin-surface);
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 1rem;
		margin-bottom: 0.75rem;
		display: flex;
		align-items: center;
		gap: 1rem;
		transition: all 0.15s ease;
	}
	.ops-section-row:hover {
		border-color: var(--admin-primary);
		box-shadow: var(--shadow-sm);
	}
	.ops-grip {
		color: var(--admin-text-muted);
		cursor: grab;
		font-size: 1.25rem;
		user-select: none;
	}
	.ops-anchor-pill {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		background: rgba(16, 185, 129, 0.1);
		color: ##065f46;
		border: 1px solid rgba(16, 185, 129, 0.3);
		padding: 0.2rem 0.6rem;
		border-radius: 9999px;
		font-family: monospace;
		font-size: 0.8rem;
		font-weight: 700;
	}
	.ops-menu-sync-badge {
		font-size: 0.75rem;
		padding: 0.2rem 0.55rem;
		border-radius: 4px;
		font-weight: 600;
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
	}
	.ops-menu-sync-active {
		background: rgba(16, 185, 129, 0.15);
		color: ##065f46;
		border: 1px solid rgba(16, 185, 129, 0.3);
	}
	.ops-menu-sync-missing {
		background: rgba(245, 158, 11, 0.12);
		color: ##92400e;
		border: 1px solid rgba(245, 158, 11, 0.25);
	}
	.ops-preview-stage {
		background: var(--admin-bg);
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 1rem;
		display: flex;
		flex-direction: column;
		align-items: center;
		min-height: 480px;
	}
	.ops-device-toolbar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		width: 100%;
		margin-bottom: 1rem;
		padding-bottom: 0.75rem;
		border-bottom: 1px solid var(--admin-border);
	}
	.ops-device-frame {
		width: 100%;
		height: 600px;
		background: ##ffffff;
		border: 2px solid var(--admin-border);
		border-radius: 8px;
		box-shadow: var(--shadow-md);
		overflow: hidden;
		transition: width 0.2s ease;
	}
	.ops-device-frame.tablet {
		width: 768px;
	}
	.ops-device-frame.mobile {
		width: 375px;
	}
	.ops-device-frame iframe {
		width: 100%;
		height: 100%;
		border: none;
	}
	.ops-sticky-aside {
		position: sticky;
		top: calc(var(--header-height) + 1rem);
	}

	/* Section Background Styles & Live Swatches */
	.ops-bg-default { background: ##ffffff; }
	.ops-bg-muted { background: ##f8fafc; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }
	.ops-bg-surface-elevated { background: ##f1f5f9; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }
	.ops-bg-cream-gradient { background: linear-gradient(180deg, ##fdfbf7 0%, ##faf6ee 45%, ##ffffff 100%); border-top: 1px solid rgba(217, 195, 155, 0.35); border-bottom: 1px solid rgba(217, 195, 155, 0.35); }
	.ops-bg-curly-lines { background-color: ##fafbf9; background-image: radial-gradient(ellipse at 15% 20%, rgba(22, 101, 52, 0.05) 0%, transparent 50%), radial-gradient(ellipse at 85% 80%, rgba(212, 175, 55, 0.06) 0%, transparent 50%), url("data:image/svg+xml,%3Csvg width='800' height='400' viewBox='0 0 800 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' stroke-linecap='round'%3E%3Cpath d='M-100,200 C100,50 300,350 500,200 C700,50 900,350 1100,200' stroke='rgba(22,101,52,0.12)' stroke-width='3'/%3E%3Cpath d='M-100,240 C100,90 300,390 500,240 C700,90 900,390 1100,240' stroke='rgba(14,165,233,0.10)' stroke-width='2'/%3E%3Cpath d='M-100,160 C100,310 300,10 500,160 C700,310 900,10 1100,160' stroke='rgba(212,175,55,0.13)' stroke-width='2.2' stroke-dasharray='8 6'/%3E%3Cpath d='M-100,120 C100,270 300,-30 500,120 C700,270 900,-30 1100,120' stroke='rgba(22,101,52,0.07)' stroke-width='1.5'/%3E%3C/g%3E%3C/svg%3E"); background-repeat: repeat; background-size: 800px 400px; border-top: 1px solid rgba(22, 101, 52, 0.1); border-bottom: 1px solid rgba(22, 101, 52, 0.1); }
	.ops-bg-topo-contours { background-color: ##f8fafc; background-image: radial-gradient(circle at 100% 0%, rgba(22, 101, 52, 0.04) 0%, transparent 40%), url("data:image/svg+xml,%3Csvg width='120' height='120' viewBox='0 0 120 120' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' stroke-linecap='round'%3E%3Cpath d='M0 24 Q 30 6, 60 24 T 120 24 M0 48 Q 30 30, 60 48 T 120 48 M0 72 Q 30 54, 60 72 T 120 72 M0 96 Q 30 78, 60 96 T 120 96' stroke='rgba(71,85,105,0.08)' stroke-width='1.2'/%3E%3Cpath d='M0 36 Q 36 18, 72 36 T 120 36 M0 84 Q 36 66, 72 84 T 120 84' stroke='rgba(22,101,52,0.09)' stroke-width='1.6'/%3E%3C/g%3E%3C/svg%3E"); background-size: 240px 240px; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }
	.ops-bg-nature-sage { background: linear-gradient(135deg, ##f2f7f4 0%, ##e8f3ec 55%, ##f6faf7 100%); border-top: 1px solid rgba(22, 101, 52, 0.12); border-bottom: 1px solid rgba(22, 101, 52, 0.12); }
	.ops-bg-soft-sunset { background: linear-gradient(135deg, ##fdf8f0 0%, ##faede0 50%, ##fffdfa 100%); border-top: 1px solid rgba(180, 83, 9, 0.12); border-bottom: 1px solid rgba(180, 83, 9, 0.12); }
	.ops-bg-geometric-mesh { background-color: ##f8fafc; background-image: radial-gradient(rgba(14, 165, 233, 0.15) 1.2px, transparent 1.2px), radial-gradient(rgba(15, 23, 42, 0.08) 1.2px, transparent 1.2px); background-size: 24px 24px; background-position: 0 0, 12px 12px; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }
	.ops-bg-dark { background: ##0f172a; color: ##f8fafc; }
	.ops-bg-dark-lines { background-color: ##0b1120; color: ##f8fafc; background-image: radial-gradient(circle at 20% 30%, rgba(22, 101, 52, 0.22) 0%, transparent 60%), radial-gradient(circle at 80% 70%, rgba(14, 165, 233, 0.2) 0%, transparent 60%), url("data:image/svg+xml,%3Csvg width='800' height='400' viewBox='0 0 800 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none'%3E%3Cpath d='M-100,200 C100,50 300,350 500,200 C700,50 900,350 1100,200' stroke='rgba(52,211,153,0.22)' stroke-width='2.2'/%3E%3Cpath d='M-100,230 C100,80 300,380 500,230 C700,80 900,380 1100,230' stroke='rgba(56,189,248,0.20)' stroke-width='2'/%3E%3Cpath d='M-100,170 C100,320 300,20 500,170 C700,320 900,20 1100,170' stroke='rgba(251,191,36,0.18)' stroke-width='1.8' stroke-dasharray='6 6'/%3E%3C/g%3E%3C/svg%3E"); background-size: 800px 400px; border-top: 1px solid rgba(255,255,255,0.08); border-bottom: 1px solid rgba(255,255,255,0.08); }
</style>

<div class="page-header ops-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">One Page Studio</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Content Management</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='pages', action='index')#">Pages</a></li>
				<li class="breadcrumb-item active" aria-current="page">One Page Studio</li>
			</ol>
		</nav>
	</div>
	<div style="display:flex; align-items:center; gap:0.6rem; flex-wrap:wrap;">
		<cfif StructKeyExists(variables, "availableWorkspaces") AND ArrayLen(variables.availableWorkspaces) GT 0>
			<select id="opsWorkspaceSelect" class="form-control" style="width:auto; font-size:0.85rem;" aria-label="Filter by workspace">
				<option value="global" <cfif currentWs eq "global">selected</cfif>>All Workspaces / Portals</option>
				<cfloop array="#variables.availableWorkspaces#" index="wsItem">
					<cfif wsItem.id neq "global">
						<option value="#EncodeForHTMLAttribute(wsItem.id)#" <cfif currentWs eq wsItem.id>selected</cfif>>
							#EncodeForHTML(wsItem.name)# <cfif StructKeyExists(wsItem, "type") AND wsItem.type eq "site">(Portal / Site)</cfif>
						</option>
					</cfif>
				</cfloop>
			</select>
		</cfif>
		<button type="button" class="btn btn-primary" id="btnOpsCreateNewSite">
			#svgIcon(name="plus", size=16)# <span>New One-Page Website</span>
		</button>
	</div>
</div>

<!--- Stats KPI Bar --->
<div class="ops-stats-bar">
	<div class="ops-stat-card">
		<div class="ops-stat-icon" style="background:rgba(22, 101, 52, 0.12); color:##166534;">
			#svgIcon(name="monitor", size=22)#
		</div>
		<div>
			<div style="font-size:1.4rem; font-weight:800; color:var(--admin-text-main); line-height:1.1;">#totalSitesCount#</div>
			<div style="font-size:0.78rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.04em;">One-Page Sites</div>
		</div>
	</div>
	<div class="ops-stat-card">
		<div class="ops-stat-icon" style="background:rgba(14, 165, 233, 0.12); color:##0284c7;">
			#svgIcon(name="layers", size=22)#
		</div>
		<div>
			<div style="font-size:1.4rem; font-weight:800; color:var(--admin-text-main); line-height:1.1;">#ArrayLen(selSections)#</div>
			<div style="font-size:0.78rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.04em;">Active Page Sections</div>
		</div>
	</div>
	<div class="ops-stat-card">
		<div class="ops-stat-icon" style="background:rgba(16, 185, 129, 0.12); color:##059669;">
			#svgIcon(name="link", size=22)#
		</div>
		<div>
			<div style="font-size:1.4rem; font-weight:800; color:var(--admin-text-main); line-height:1.1;">#ArrayLen(selSections)#</div>
			<div style="font-size:0.78rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.04em;">Hash ## Anchors</div>
		</div>
	</div>
	<div class="ops-stat-card">
		<div class="ops-stat-icon" style="background:rgba(245, 158, 11, 0.12); color:##d97706;">
			#svgIcon(name="file-text", size=22)#
		</div>
		<div>
			<div style="font-size:1.4rem; font-weight:800; color:var(--admin-text-main); line-height:1.1;">#ArrayLen(candidatePages)#</div>
			<div style="font-size:0.78rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.04em;">Workspace Pages Available</div>
		</div>
	</div>
</div>

<!--- Tabs --->
<div class="ops-tab-nav" role="tablist">
	<button type="button" class="ops-tab-btn active" id="tabBtnBuilder" role="tab" aria-selected="true" aria-controls="opsPanelBuilder">
		#svgIcon(name="layers", size=16)# <span>One Page Assembler</span>
	</button>
	<button type="button" class="ops-tab-btn" id="tabBtnPreview" role="tab" aria-selected="false" aria-controls="opsPanelPreview">
		#svgIcon(name="monitor", size=16)# <span>Interactive Device Preview</span>
	</button>
	<button type="button" class="ops-tab-btn" id="tabBtnDirectory" role="tab" aria-selected="false" aria-controls="opsPanelDirectory">
		#svgIcon(name="grid", size=16)# <span>All One-Page Sites Directory</span>
	</button>
</div>

<!--- TAB 1: ONE PAGE ASSEMBLER STUDIO --->
<div id="opsPanelBuilder" class="ops-tab-panel" role="tabpanel" aria-labelledby="tabBtnBuilder">
	<cfif totalSitesCount eq 0>
		<div class="admin-card" style="text-align:center; padding:3rem 1.5rem;">
			<div style="margin-bottom:1rem; color:var(--admin-text-muted);">
				#svgIcon(name="monitor", size=48)#
			</div>
			<h2 style="font-size:1.25rem; font-weight:700; margin-bottom:0.5rem;">No One-Page Websites Configured Yet</h2>
			<p class="pg-help" style="max-width:540px; margin:0 auto 1.5rem;">
				One Page Studio allows creating modern single-page portal websites stitched together from multiple existing pages, complete with sticky navigation, hero headers, and smooth-scrolling <code>##tag</code> anchors!
			</p>
			<button type="button" class="btn btn-primary" id="btnOpsInitFirstSite">
				#svgIcon(name="plus", size=16)# <span>Create Your First One-Page Website</span>
			</button>
		</div>
	<cfelse>
		<!--- Studio Two-Column Grid --->
		<div class="ops-studio-layout">
			<!--- LEFT COLUMN: Configurations & Sections --->
			<div>
				<!--- 1. Active One-Page Site Selector & Banner --->
				<div class="ops-card">
					<div class="ops-card-header">
						<div style="display:flex; align-items:center; gap:0.6rem;">
							<label for="opsSitePicker" class="form-label" style="margin:0; font-weight:700;">Active One-Page Site:</label>
							<select id="opsSitePicker" class="form-control" style="font-weight:700; width:auto; min-width:240px;">
								<cfloop array="#allSites#" index="siteItem">
									<option value="#siteItem.id#" <cfif StructKeyExists(selSite, "id") AND selSite.id eq siteItem.id>selected</cfif>>
										#EncodeForHTML(siteItem.title)# (#siteItem.slug#)
									</option>
								</cfloop>
							</select>
						</div>
						<div style="display:flex; gap:0.4rem;">
							<button type="button" class="btn btn-outline btn-xs" id="btnOpsEditSiteMeta" title="Edit Site Identity & Theme">
								#svgIcon(name="settings", size=14)# <span>Site Settings</span>
							</button>
							<button type="button" class="btn btn-outline-danger btn-xs" id="btnOpsDeleteSite" title="Delete this One-Page Site">
								#svgIcon(name="trash", size=14)#
							</button>
						</div>
					</div>
					<div class="ops-card-body" style="padding:1rem 1.25rem;">
						<div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:1rem;">
							<div>
								<div style="font-size:1.15rem; font-weight:800; color:var(--admin-text-main); margin-bottom:0.25rem;" id="opsDisplayTitle">
									<cfif StructKeyExists(selSite, "title")>#EncodeForHTML(selSite.title)#<cfelse>Untitled Site</cfif>
								</div>
								<div style="font-size:0.84rem; color:var(--admin-text-muted);" id="opsDisplaySubtitle">
									<cfif StructKeyExists(selSite, "subtitle") AND Len(selSite.subtitle)>#EncodeForHTML(selSite.subtitle)#<cfelse>No subtitle specified.</cfif>
								</div>
							</div>
							<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
								<span class="badge badge-success" id="opsDisplayTheme">
									Theme: <cfif StructKeyExists(selSite, "theme")>#selSite.theme#<cfelse>river-park</cfif>
								</span>
								<span class="badge badge-info" id="opsDisplayWorkspace">
									Workspace: <cfif StructKeyExists(selSite, "siteid")>#selSite.siteid#<cfelse>global</cfif>
								</span>
							</div>
						</div>
					</div>
				</div>

				<!--- 2. Multi-Page Section Assembly Card --->
				<div class="ops-card">
					<div class="ops-card-header">
						<div>
							<h2 class="ops-card-title">
								#svgIcon(name="layers", size=16)#
								<span>Page Sections (<span id="opsSectionCount">#ArrayLen(selSections)#</span>)</span>
							</h2>
							<div class="pg-help" style="margin:0;">These pages are assembled into smooth-scrolling sections on your one-page site.</div>
						</div>
						<div style="display:flex; gap:0.5rem;">
							<button type="button" class="btn btn-primary btn-sm" id="btnOpsOpenPagePicker">
								#svgIcon(name="plus", size=14)# <span>+ Select Pages from Workspace</span>
							</button>
						</div>
					</div>
					<div class="ops-card-body">
						<div id="opsSectionsList" aria-label="Assembled sections list">
							<cfif ArrayLen(selSections) eq 0>
								<div style="text-align:center; padding:2rem 1rem; color:var(--admin-text-muted);">
									<p style="margin-bottom:0.75rem;">No sections have been added to this One-Page Website yet.</p>
									<button type="button" class="btn btn-outline-primary btn-sm" id="btnOpsEmptyAddPages">
										#svgIcon(name="plus", size=14)# <span>Select Pages to Add as Sections</span>
									</button>
								</div>
							<cfelse>
								<cfloop array="#selSections#" index="sec">
									<div class="ops-section-row" data-id="#sec.id#" data-sort="#sec.sortOrder#" data-anchor="#sec.anchorId#">
										<div class="ops-grip" title="Drag to reorder section">&##8942;&##8942;</div>
										<div style="flex:1; min-width:0;">
											<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap; margin-bottom:0.25rem;">
												<strong style="color:var(--admin-text-main); font-size:0.95rem;">#EncodeForHTML(sec.sectionTitle)#</strong>
												<span class="ops-anchor-pill" title="Anchor tag for navigation menu">###sec.anchorId#</span>
												<span class="badge badge-neutral" style="font-size:0.72rem;">#sec.sectionLayout#</span>
												<span class="badge badge-neutral" style="font-size:0.72rem;">bg: #sec.sectionBg#</span>
											</div>
											<div style="font-size:0.78rem; color:var(--admin-text-muted); display:flex; gap:0.75rem; flex-wrap:wrap;">
												<span>Linked Page: <strong>#EncodeForHTML(sec.pageTitle)#</strong> (ID: #sec.pageId#)</span>
												<cfif Len(sec.sectionSubtitle)><span>&bull; #EncodeForHTML(sec.sectionSubtitle)#</span></cfif>
											</div>
										</div>
										<div style="display:flex; align-items:center; gap:0.35rem; flex-shrink:0;">
											<button type="button" class="btn btn-outline btn-xs btnOpsCopyAnchor" data-anchor="###sec.anchorId#" title="Copy anchor tag ##tag" aria-label="Copy anchor tag ###sec.anchorId#">
												#svgIcon(name="link", size=13)# <span>Copy ##</span>
											</button>
											<button type="button" class="btn btn-outline btn-xs btnOpsEditSection" data-id="#sec.id#" title="Configure Section" aria-label="Configure Section #EncodeForHTMLAttribute(sec.sectionTitle)#">
												#svgIcon(name="edit", size=13)#
											</button>
											<button type="button" class="btn btn-outline btn-xs btnOpsMoveUp" data-id="#sec.id#" title="Move Up" aria-label="Move section up">
												#svgIcon(name="chevron-up", size=13)#
											</button>
											<button type="button" class="btn btn-outline btn-xs btnOpsMoveDown" data-id="#sec.id#" title="Move Down" aria-label="Move section down">
												#svgIcon(name="chevron-down", size=13)#
											</button>
											<button type="button" class="btn btn-outline-danger btn-xs btnOpsDeleteSection" data-id="#sec.id#" title="Remove Section" aria-label="Remove section #EncodeForHTMLAttribute(sec.sectionTitle)#">
												#svgIcon(name="trash", size=13)#
											</button>
										</div>
									</div>
								</cfloop>
							</cfif>
						</div>
					</div>
				</div>

				<!--- 3. Menu & Anchor Integration Card --->
				<div class="ops-card">
					<div class="ops-card-header">
						<div>
							<h2 class="ops-card-title">
								#svgIcon(name="link", size=16)#
								<span>Navigation Menu &amp; Anchor Hash Sync</span>
							</h2>
							<div class="pg-help" style="margin:0;">Menus link directly to one-page sections using <code>##anchor</code> hash tags.</div>
						</div>
						<div style="display:flex; gap:0.5rem;">
							<button type="button" class="btn btn-success btn-sm" id="btnOpsSyncMenu">
								#svgIcon(name="check", size=14)# <span>Sync Sections to Navigation Menu</span>
							</button>
							<a href="#urlFor(controller='navigation', action='index')#" class="btn btn-outline btn-sm" target="_blank">
								#svgIcon(name="settings", size=14)# <span>Open Navigation Manager</span>
							</a>
						</div>
					</div>
					<div class="ops-card-body">
						<div style="background:var(--admin-bg); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:1rem; margin-bottom:1rem;">
							<div style="font-size:0.85rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.35rem;">
								How Menu &amp; Anchor Linking Works:
							</div>
							<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 0.5rem;">
								Each section in this one-page site has a unique anchor hash (e.g. <code>##overview</code>, <code>##amenities</code>, <code>##rates</code>). When a visitor clicks a menu item, the browser smoothly scrolls directly to that section.
							</p>
							<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0;">
								Clicking <strong>&ldquo;Sync Sections to Navigation Menu&rdquo;</strong> will automatically create or update the side/top menu in Navigation Manager with all active section anchors for this workspace!
							</p>
						</div>

						<div id="opsMenuAnchorsStatusTable">
							<table class="table" style="width:100%; font-size:0.82rem; margin:0;">
								<thead>
									<tr style="border-bottom:1px solid var(--admin-border);">
										<th style="padding:0.5rem; text-align:left;">Section Name</th>
										<th style="padding:0.5rem; text-align:left;">Hash Anchor</th>
										<th style="padding:0.5rem; text-align:left;">Menu Destination</th>
										<th style="padding:0.5rem; text-align:right;">Actions</th>
									</tr>
								</thead>
								<tbody>
									<cfloop array="#selSections#" index="sec">
										<tr style="border-bottom:1px solid var(--admin-border-subtle);">
											<td style="padding:0.5rem; font-weight:600; color:var(--admin-text-main);">#EncodeForHTML(sec.sectionTitle)#</td>
											<td style="padding:0.5rem;"><span class="ops-anchor-pill">###sec.anchorId#</span></td>
											<td style="padding:0.5rem; color:var(--admin-text-muted);"><code>###sec.anchorId#</code></td>
											<td style="padding:0.5rem; text-align:right;">
												<button type="button" class="btn btn-outline btn-xs btnOpsCopyAnchor" data-anchor="###sec.anchorId#">Copy Tag</button>
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</div>
				</div>
			</div>

			<!--- RIGHT COLUMN: Publish Actions, Mini-Preview & Checklist --->
			<div class="ops-sticky-aside">
				<!--- Action Card --->
				<div class="ops-card">
					<div class="ops-card-header">
						<h2 class="ops-card-title">
							#svgIcon(name="upload", size=16)# <span>Publish &amp; Actions</span>
						</h2>
					</div>
					<div class="ops-card-body" style="display:flex; flex-direction:column; gap:0.75rem;">
						<div style="background:var(--admin-bg, ##f8fafc); border:1px solid var(--admin-border, ##e2e8f0); border-radius:8px; padding:0.65rem 0.75rem;">
							<label style="display:flex; align-items:center; gap:0.5rem; cursor:pointer; font-size:0.85rem; font-weight:600; margin:0; color:var(--admin-text-main, ##0f172a);">
								<input type="checkbox" id="chkOpsSeparateAssets" checked style="accent-color:var(--admin-primary, ##166534); width:16px; height:16px;">
								<span>Separate Assets (.css &amp; .js)</span>
							</label>
							<div style="font-size:0.72rem; color:var(--admin-text-muted, ##64748b); margin-top:0.3rem; line-height:1.35;">
								Compiles cleanly into <code>/stylesheets/onepage/</code> &amp; <code>/javascripts/onepage/</code> instead of inline blocks.
							</div>
						</div>

						<button type="button" class="btn btn-primary" id="btnOpsCompileSave" style="width:100%; justify-content:center; padding:0.75rem;">
							#svgIcon(name="check", size=16)# <span>Compile &amp; Save to Content Manager</span>
						</button>
						<button type="button" class="btn btn-outline" id="btnOpsOpenPreviewTab" style="width:100%; justify-content:center;">
							#svgIcon(name="monitor", size=15)# <span>Open Live Standalone Preview &rarr;</span>
						</button>
						<button type="button" class="btn btn-success" id="btnOpsPublishProduction" style="width:100%; justify-content:center; padding:0.75rem; font-weight:700;">
							#svgIcon(name="upload", size=16)# <span>Publish to Production</span>
						</button>
						<button type="button" class="btn btn-outline" id="btnOpsExportHtml" style="width:100%; justify-content:center;">
							#svgIcon(name="download", size=15)# <span>Export Standalone HTML File</span>
						</button>
					</div>
				</div>

				<!--- Quick Anchor Navigation Outline --->
				<div class="ops-card">
					<div class="ops-card-header">
						<h2 class="ops-card-title">
							#svgIcon(name="link", size=16)# <span>Section Outline &amp; Anchors</span>
						</h2>
					</div>
					<div class="ops-card-body">
						<div id="opsAsideAnchorsList" style="display:flex; flex-direction:column; gap:0.4rem;">
							<cfloop array="#selSections#" index="sec">
								<a href="javascript:void(0)" class="btn btn-outline btn-xs btnOpsJumpToSection" data-anchor="###sec.anchorId#" style="text-align:left; justify-content:space-between;">
									<span>#EncodeForHTML(sec.sectionTitle)#</span>
									<code style="font-size:0.72rem; color:var(--admin-primary);">###sec.anchorId#</code>
								</a>
							</cfloop>
						</div>
					</div>
				</div>

				<!--- WCAG 2.1 AA Compliance Badge Card --->
				<div class="ops-card">
					<div class="ops-card-header">
						<h2 class="ops-card-title" style="color:##166534;">
							#svgIcon(name="shield", size=16)# <span>WCAG 2.1 AA Quality Gate</span>
						</h2>
					</div>
					<div class="ops-card-body" style="font-size:0.8rem; color:var(--admin-text-muted);">
						<ul style="padding-left:1.25rem; margin:0; line-height:1.5;">
							<li>Semantic landmarks (<code>&lt;header&gt;</code>, <code>&lt;nav&gt;</code>, <code>&lt;main&gt;</code>, <code>&lt;section&gt;</code>, <code>&lt;footer&gt;</code>)</li>
							<li>Heading hierarchy maintained (H1 hero, H2 sections)</li>
							<li>High-contrast text tokens &amp; accessible color palettes</li>
							<li>Keyboard-accessible smooth scrolling anchors</li>
							<li>Mobile drawer menu with Escape key support</li>
						</ul>
					</div>
				</div>
			</div>
		</div>
	</cfif>
</div>

<!--- TAB 2: INTERACTIVE DEVICE PREVIEW --->
<div id="opsPanelPreview" class="ops-tab-panel" role="tabpanel" aria-labelledby="tabBtnPreview" hidden>
	<div class="ops-preview-stage">
		<div class="ops-device-toolbar">
			<div style="font-size:0.9rem; font-weight:700; color:var(--admin-text-main);">
				Interactive Device Simulation
			</div>
			<div style="display:flex; gap:0.4rem;">
				<button type="button" class="btn btn-outline btn-xs active opsDeviceBtn" data-device="desktop">
					#svgIcon(name="monitor", size=14)# <span>Desktop (100%)</span>
				</button>
				<button type="button" class="btn btn-outline btn-xs opsDeviceBtn" data-device="tablet">
					<span>Tablet (768px)</span>
				</button>
				<button type="button" class="btn btn-outline btn-xs opsDeviceBtn" data-device="mobile">
					<span>Mobile (375px)</span>
				</button>
			</div>
		</div>
		<div class="ops-device-frame" id="opsDeviceFrame">
			<iframe id="opsPreviewIframe" src="about:blank" title="Live One Page Preview"></iframe>
		</div>
	</div>
</div>

<!--- TAB 3: ALL ONE-PAGE SITES DIRECTORY --->
<div id="opsPanelDirectory" class="ops-tab-panel" role="tabpanel" aria-labelledby="tabBtnDirectory" hidden>
	<div class="admin-card">
		<div class="card-body" style="padding:0;">
			<table class="table" style="width:100%; font-size:0.85rem; margin:0;">
				<thead style="background:var(--admin-surface-hover); border-bottom:1px solid var(--admin-border);">
					<tr>
						<th style="padding:0.75rem 1rem; text-align:left;">Site Title</th>
						<th style="padding:0.75rem 1rem; text-align:left;">Workspace / Code</th>
						<th style="padding:0.75rem 1rem; text-align:left;">Slug / URL</th>
						<th style="padding:0.75rem 1rem; text-align:left;">Theme</th>
						<th style="padding:0.75rem 1rem; text-align:center;">Sections</th>
						<th style="padding:0.75rem 1rem; text-align:left;">Last Updated</th>
						<th style="padding:0.75rem 1rem; text-align:right;">Actions</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#allSites#" index="siteRow">
						<tr style="border-bottom:1px solid var(--admin-border-subtle);">
							<td style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-main);">
								#EncodeForHTML(siteRow.title)#
							</td>
							<td style="padding:0.75rem 1rem;"><span class="badge badge-neutral">#siteRow.siteid#</span></td>
							<td style="padding:0.75rem 1rem; color:var(--admin-text-muted);"><code>/#siteRow.slug#</code></td>
							<td style="padding:0.75rem 1rem;"><span class="badge badge-info">#siteRow.theme#</span></td>
							<td style="padding:0.75rem 1rem; text-align:center; font-weight:700;">#siteRow.sectionCount#</td>
							<td style="padding:0.75rem 1rem; color:var(--admin-text-muted);">#siteRow.updated#</td>
							<td style="padding:0.75rem 1rem; text-align:right;">
								<a href="#urlFor(controller='pages', action='onePage', params='id=' & siteRow.id)#" class="btn btn-outline btn-xs">
									Edit in Studio
								</a>
								<a href="/pages/one-page/preview?id=#siteRow.id#" target="_blank" class="btn btn-outline btn-xs">
									Preview
								</a>
								<button type="button" class="btn btn-outline-danger btn-xs btnOpsDirectoryDeleteSite" data-id="#siteRow.id#" data-title="#EncodeForHTMLAttribute(siteRow.title)#" title="Delete One-Page Site" aria-label="Delete One-Page Site #EncodeForHTMLAttribute(siteRow.title)#">
									#svgIcon(name="trash", size=13)#
								</button>
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</div>
</div>

<!--- MODAL 1: SELECT PAGES FROM WORKSPACE DRAWER --->
<div class="admin-modal-backdrop" id="modalOpsPagePicker">
	<div class="admin-modal-dialog" style="max-width:720px;">
		<div class="admin-modal-header">
			<h2 class="admin-modal-title">
				#svgIcon(name="layers", size=18)# <span>Select Pages to Add as Sections</span>
			</h2>
			<button type="button" class="admin-modal-close" id="btnCloseOpsPagePicker" aria-label="Close">&times;</button>
		</div>
		<div style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; gap:0.75rem; align-items:center;">
			<input type="text" id="opsPageSearchInput" class="form-control" placeholder="Search pages by title or slug...">
		</div>
		<div style="padding:1rem 1.25rem; max-height:420px; overflow-y:auto;" id="opsPagesPickerList">
			<cfloop array="#candidatePages#" index="cPage">
				<label class="ops-page-item-row" style="display:flex; align-items:flex-start; gap:0.75rem; padding:0.65rem 0.5rem; border-bottom:1px solid var(--admin-border-subtle); cursor:pointer;">
					<input type="checkbox" class="opsCandidatePageCb" value="#cPage.id#" data-title="#EncodeForHTMLAttribute(cPage.title)#" data-slug="#EncodeForHTMLAttribute(cPage.slug)#" data-summary="#EncodeForHTMLAttribute(cPage.summary)#" style="margin-top:0.25rem; accent-color:var(--admin-primary);">
					<div style="flex:1;">
						<div style="font-weight:700; color:var(--admin-text-main); font-size:0.9rem;">#EncodeForHTML(cPage.title)#</div>
						<div style="font-size:0.78rem; color:var(--admin-text-muted);">
							Slug: <code>#cPage.slug#</code> &bull; ID: #cPage.id#
							<cfif Len(cPage.summary)>&bull; #EncodeForHTML(cPage.summary)#</cfif>
						</div>
					</div>
				</label>
			</cfloop>
		</div>
		<div style="padding:1rem 1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-surface-hover);">
			<div style="font-size:0.8rem; color:var(--admin-text-muted);" id="opsPagesSelectedCount">0 pages selected</div>
			<div style="display:flex; gap:0.5rem;">
				<button type="button" class="btn btn-outline btn-sm" id="btnCancelOpsPagePicker">Cancel</button>
				<button type="button" class="btn btn-primary btn-sm" id="btnSubmitOpsAddPages">Add Selected Pages as Sections</button>
			</div>
		</div>
	</div>
</div>

<!--- MODAL 2: EDIT SECTION SETTINGS MODAL --->
<div class="admin-modal-backdrop" id="modalOpsEditSection">
	<div class="admin-modal-dialog" style="max-width:620px;">
		<div class="admin-modal-header">
			<h2 class="admin-modal-title">
				#svgIcon(name="edit", size=18)# <span id="opsEditSectionModalTitle">Configure Section</span>
			</h2>
			<button type="button" class="admin-modal-close" id="btnCloseOpsEditSection" aria-label="Close">&times;</button>
		</div>
		<form id="opsEditSectionForm" style="padding:1.25rem; overflow-y:auto; max-height:75vh;">
			<input type="hidden" id="opsSecId" value="0">
			<input type="hidden" id="opsSecSiteId" value="0">
			<input type="hidden" id="opsSecPageId" value="0">

			<div class="pg-field" style="margin-bottom:1rem;">
				<label for="opsSecTitle" class="form-label" style="font-weight:700;">Section Heading / Title</label>
				<input type="text" id="opsSecTitle" class="form-control" required maxlength="255" placeholder="e.g. Park Amenities & Facilities">
			</div>

			<div class="pg-field" style="margin-bottom:1rem;">
				<label for="opsSecAnchorId" class="form-label" style="font-weight:700;">
					Anchor Hash ID (without ##)
				</label>
				<div style="display:flex; align-items:center; gap:0.5rem;">
					<span style="font-family:monospace; font-weight:700; color:var(--admin-text-muted); font-size:1.1rem;">##</span>
					<input type="text" id="opsSecAnchorId" class="form-control" required maxlength="100" placeholder="e.g. amenities">
				</div>
				<div class="nav-editor-description">This defines the URL anchor hash (e.g. <code>##amenities</code>) for one-page menu links.</div>
			</div>

			<div class="pg-field" style="margin-bottom:1rem;">
				<label for="opsSecSubtitle" class="form-label">Subtitle / Eyebrow Text</label>
				<input type="text" id="opsSecSubtitle" class="form-control" maxlength="500" placeholder="Optional category or badge above heading">
			</div>

			<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem; margin-bottom:1rem;">
				<div class="pg-field">
					<label for="opsSecLayout" class="form-label" style="font-weight:700;">Section Layout</label>
					<select id="opsSecLayout" class="form-control">
						<option value="full">Full Width Content</option>
						<option value="split-image-right">Split 50/50 (Image Right)</option>
						<option value="split-image-left">Split 50/50 (Image Left)</option>
						<option value="card-grid">Feature Cards Grid</option>
						<option value="featured-hero">Featured Hero Card</option>
					</select>
				</div>
				<div class="pg-field">
					<label for="opsSecBg" class="form-label" style="font-weight:700;">Background Style</label>
					<select id="opsSecBg" class="form-control">
						<option value="default">Default White Surface</option>
						<option value="muted">Soft Muted Gray</option>
						<option value="surface-elevated">Elevated Subtle Slate</option>
						<option value="cream-gradient">Gradient Cream to White</option>
						<option value="curly-lines">Curly Abstract Two-Tone Lines</option>
						<option value="topo-contours">Topographic Contour Waves</option>
						<option value="nature-sage">Forest Mist &amp; Soft Sage</option>
						<option value="soft-sunset">Warm Ochre / Desert Sand</option>
						<option value="geometric-mesh">Subtle Technical Grid Mesh</option>
						<option value="dark">Dark High-Contrast Midnight</option>
						<option value="dark-lines">Dark Glowing Wave Lines</option>
					</select>
					<div id="opsSecBgPreview" style="margin-top:0.45rem; height:36px; border-radius:6px; border:1px solid var(--admin-border, ##cbd5e1); transition:all 0.2s ease;" title="Live Background Preview"></div>
				</div>
			</div>

			<div class="pg-field" style="margin-bottom:1rem;">
				<label for="opsSecCustomClass" class="form-label">Custom CSS Classes</label>
				<input type="text" id="opsSecCustomClass" class="form-control" maxlength="100" placeholder="Optional space-separated CSS classes">
			</div>

			<div style="display:flex; flex-direction:column; gap:0.5rem; margin-top:1rem; padding-top:1rem; border-top:1px solid var(--admin-border-subtle);">
				<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.85rem; cursor:pointer;">
					<input type="checkbox" id="opsSecShowHeader" checked style="accent-color:var(--admin-primary);">
					<span>Show Section Header &amp; Heading</span>
				</label>
				<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.85rem; cursor:pointer;">
					<input type="checkbox" id="opsSecShowDivider" checked style="accent-color:var(--admin-primary);">
					<span>Show Divider Line at Bottom of Section</span>
				</label>
				<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.85rem; cursor:pointer;">
					<input type="checkbox" id="opsSecIsActive" checked style="accent-color:var(--admin-primary);">
					<span>Section is Active / Visible on Live Site</span>
				</label>
			</div>

			<div style="margin-top:1.5rem; display:flex; justify-content:flex-end; gap:0.5rem;">
				<button type="button" class="btn btn-outline btn-sm" id="btnCancelOpsEditSection">Cancel</button>
				<button type="submit" class="btn btn-primary btn-sm">Save Section</button>
			</div>
		</form>
	</div>
</div>

<!--- MODAL 3: SITE IDENTITY & THEME SETTINGS MODAL --->
<div class="admin-modal-backdrop" id="modalOpsSiteMeta">
	<div class="admin-modal-dialog" style="max-width:680px;">
		<div class="admin-modal-header">
			<h2 class="admin-modal-title">
				#svgIcon(name="settings", size=18)# <span>One-Page Website Settings</span>
			</h2>
			<button type="button" class="admin-modal-close" id="btnCloseOpsSiteMeta" aria-label="Close">&times;</button>
		</div>
		<form id="opsSiteMetaForm" style="padding:1.25rem; overflow-y:auto; max-height:75vh;">
			<input type="hidden" id="opsSiteMetaId" value="0">

			<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem; margin-bottom:1rem;">
				<div class="pg-field">
					<label for="opsSiteMetaTitle" class="form-label" style="font-weight:700;">Site Title</label>
					<input type="text" id="opsSiteMetaTitle" class="form-control" required maxlength="255" placeholder="e.g. Wenatchee River Park">
				</div>
				<div class="pg-field">
					<label for="opsSiteMetaSlug" class="form-label" style="font-weight:700;">Slug / Permalink</label>
					<input type="text" id="opsSiteMetaSlug" class="form-control" required maxlength="150" placeholder="e.g. wenatchee-river-park">
				</div>
			</div>

			<div class="pg-field" style="margin-bottom:1rem;">
				<label for="opsSiteMetaSubtitle" class="form-label">Subtitle / Description</label>
				<input type="text" id="opsSiteMetaSubtitle" class="form-control" maxlength="500" placeholder="e.g. Premier Riverfront RV Resort & Retreat along the scenic Wenatchee River">
			</div>

			<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem; margin-bottom:1rem;">
				<div class="pg-field">
					<label for="opsSiteMetaTheme" class="form-label" style="font-weight:700;">Visual Theme Preset</label>
					<select id="opsSiteMetaTheme" class="form-control">
						<option value="river-park">River Park (Evergreen &amp; River Gold)</option>
						<option value="modern-municipal">County Navy &amp; Gold</option>
						<option value="clean-editorial">Clean Editorial Slate</option>
						<option value="dark-luxury">Dark Luxury Retreat</option>
					</select>
				</div>
				<div class="pg-field">
					<label for="opsSiteMetaWorkspace" class="form-label" style="font-weight:700;">Workspace Assignment</label>
					<select id="opsSiteMetaWorkspace" class="form-control">
						<option value="global">All Workspaces (global)</option>
						<cfloop array="#variables.availableWorkspaces#" index="wsOption">
							<cfif wsOption.id neq "global">
								<option value="#EncodeForHTMLAttribute(wsOption.id)#">#EncodeForHTML(wsOption.name)#</option>
							</cfif>
						</cfloop>
					</select>
				</div>
			</div>

			<div style="background:var(--admin-bg); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-md); padding:1rem; margin-bottom:1rem;">
				<h3 style="font-size:0.85rem; font-weight:700; margin:0 0 0.75rem; color:var(--admin-text-main);">Hero Header Configuration</h3>
				<div class="pg-field" style="margin-bottom:0.75rem;">
					<label for="opsSiteMetaHeroHeadline" class="form-label">Hero Headline</label>
					<input type="text" id="opsSiteMetaHeroHeadline" class="form-control" maxlength="255" placeholder="e.g. Where the River Meets the Cascade Foothills">
				</div>
				<div class="pg-field" style="margin-bottom:0.75rem;">
					<label for="opsSiteMetaHeroTagline" class="form-label">Hero Tagline</label>
					<textarea id="opsSiteMetaHeroTagline" class="form-control" rows="2" maxlength="500" placeholder="Lead text below hero headline"></textarea>
				</div>
				<div class="pg-field" style="margin-bottom:0.75rem;">
					<label for="opsSiteMetaHeroImage" class="form-label">Hero Cover Image URL</label>
					<div style="display:flex; gap:0.5rem;">
						<input type="text" id="opsSiteMetaHeroImage" class="form-control" maxlength="500" placeholder="/files/.../hero.jpg">
						<button type="button" class="btn btn-outline btn-sm" id="btnOpsBrowseHeroMedia">Browse</button>
					</div>
				</div>
				<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.75rem;">
					<div class="pg-field">
						<label for="opsSiteMetaHeroCtaPrimaryText" class="form-label">Primary CTA Button</label>
						<input type="text" id="opsSiteMetaHeroCtaPrimaryText" class="form-control" maxlength="100" placeholder="e.g. Explore Amenities">
					</div>
					<div class="pg-field">
						<label for="opsSiteMetaHeroCtaPrimaryAnchor" class="form-label">Primary Target Anchor</label>
						<input type="text" id="opsSiteMetaHeroCtaPrimaryAnchor" class="form-control" maxlength="100" placeholder="e.g. ##amenities">
					</div>
				</div>
				<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.75rem; margin-top:0.5rem;">
					<div class="pg-field">
						<label for="opsSiteMetaHeroCtaSecondaryText" class="form-label">Secondary CTA Button</label>
						<input type="text" id="opsSiteMetaHeroCtaSecondaryText" class="form-control" maxlength="100" placeholder="e.g. View Rates & Hours">
					</div>
					<div class="pg-field">
						<label for="opsSiteMetaHeroCtaSecondaryAnchor" class="form-label">Secondary Target Anchor</label>
						<input type="text" id="opsSiteMetaHeroCtaSecondaryAnchor" class="form-control" maxlength="100" placeholder="e.g. ##rates">
					</div>
				</div>
			</div>

			<div style="background:var(--admin-bg); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-md); padding:1rem; margin-bottom:1rem;">
				<h3 style="font-size:0.85rem; font-weight:700; margin:0 0 0.75rem; color:var(--admin-text-main);">Sticky Navigation &amp; Header CTA</h3>
				<div style="display:flex; flex-direction:column; gap:0.5rem; margin-bottom:0.75rem;">
					<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.85rem; cursor:pointer;">
						<input type="checkbox" id="opsSiteMetaStickyNav" checked style="accent-color:var(--admin-primary);">
						<span>Enable Sticky Navigation Bar with Smooth-Scrolling Anchors</span>
					</label>
					<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.85rem; cursor:pointer;">
						<input type="checkbox" id="opsSiteMetaScrollspy" checked style="accent-color:var(--admin-primary);">
						<span>Enable Scrollspy Active Link Highlighting</span>
					</label>
					<label style="display:flex; align-items:center; gap:0.5rem; font-size:0.85rem; cursor:pointer;">
						<input type="checkbox" id="opsSiteMetaBackToTop" checked style="accent-color:var(--admin-primary);">
						<span>Show &ldquo;Back to Top&rdquo; Button in Footer</span>
					</label>
				</div>
				<div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:0.75rem;">
					<div class="pg-field">
						<label for="opsSiteMetaNavBrand" class="form-label">Nav Brand Title</label>
						<input type="text" id="opsSiteMetaNavBrand" class="form-control" maxlength="150" placeholder="Brand / Logo title">
					</div>
					<div class="pg-field">
						<label for="opsSiteMetaNavCtaText" class="form-label">Nav CTA Label</label>
						<input type="text" id="opsSiteMetaNavCtaText" class="form-control" maxlength="100" placeholder="e.g. Reserve Online">
					</div>
					<div class="pg-field">
						<label for="opsSiteMetaNavCtaAnchor" class="form-label">Nav CTA Anchor</label>
						<input type="text" id="opsSiteMetaNavCtaAnchor" class="form-control" maxlength="100" placeholder="e.g. ##rates">
					</div>
				</div>
			</div>

			<div style="margin-top:1.5rem; display:flex; justify-content:flex-end; gap:0.5rem;">
				<button type="button" class="btn btn-outline btn-sm" id="btnCancelOpsSiteMeta">Cancel</button>
				<button type="submit" class="btn btn-primary btn-sm">Save Site Settings</button>
			</div>
		</form>
	</div>
</div>

</cfoutput>

<script>
window.opsConfig = <cfoutput>#opsJsonData#</cfoutput>;
</script>

<script>
(function () {
	"use strict";

	var config = window.opsConfig || {};

	// Defensive case-insensitive property accessor for Adobe ColdFusion serialized JSON
	function getProp(obj, prop, def) {
		if (!obj || typeof obj !== "object") return def;
		if (obj[prop] !== undefined && obj[prop] !== null) return obj[prop];
		var lower = String(prop).toLowerCase();
		for (var k in obj) {
			if (Object.prototype.hasOwnProperty.call(obj, k) && String(k).toLowerCase() === lower) {
				if (obj[k] !== undefined && obj[k] !== null) return obj[k];
			}
		}
		return def;
	}

	var rawSites = getProp(config, "sites", []);
	var rawSelectedSite = getProp(config, "selectedSite", null) || (rawSites.length > 0 ? rawSites[0] : null);
	var rawSections = getProp(config, "sections", []);
	var candidatePages = getProp(config, "candidatePages", []);
	var rawRoutes = getProp(config, "routes", {});

	var routes = {
		saveSite: getProp(rawRoutes, "saveSite", "/pages/one-page/save"),
		deleteSite: getProp(rawRoutes, "deleteSite", "/pages/one-page/delete"),
		saveSection: getProp(rawRoutes, "saveSection", "/pages/one-page/section/save"),
		deleteSection: getProp(rawRoutes, "deleteSection", "/pages/one-page/section/delete"),
		reorderSections: getProp(rawRoutes, "reorderSections", "/pages/one-page/sections/reorder"),
		syncMenu: getProp(rawRoutes, "syncMenu", "/pages/one-page/sync-menu"),
		compile: getProp(rawRoutes, "compile", "/pages/one-page/compile"),
		publish: getProp(rawRoutes, "publish", "/pages/one-page/publish-production"),
		preview: getProp(rawRoutes, "preview", "/pages/one-page/preview"),
		export: getProp(rawRoutes, "export", "/pages/one-page/export"),
		navigation: getProp(rawRoutes, "navigation", "/navigation")
	};

	function normalizeSite(s) {
		if (!s || typeof s !== "object") return null;
		return {
			id: parseInt(getProp(s, "id", 0), 10) || 0,
			title: String(getProp(s, "title", "") || ""),
			slug: String(getProp(s, "slug", "") || ""),
			subtitle: String(getProp(s, "subtitle", "") || ""),
			theme: String(getProp(s, "theme", "river-park") || "river-park"),
			siteid: String(getProp(s, "siteid", "") || getProp(s, "siteId", "") || "global"),
			heroHeadline: String(getProp(s, "heroHeadline", "") || getProp(s, "hero_headline", "") || ""),
			heroTagline: String(getProp(s, "heroTagline", "") || getProp(s, "hero_tagline", "") || ""),
			heroImageUrl: String(getProp(s, "heroImageUrl", "") || getProp(s, "hero_image_url", "") || ""),
			heroCtaPrimaryText: String(getProp(s, "heroCtaPrimaryText", "") || getProp(s, "hero_cta_primary_text", "") || "Explore Amenities"),
			heroCtaPrimaryAnchor: String(getProp(s, "heroCtaPrimaryAnchor", "") || getProp(s, "hero_cta_primary_anchor", "") || "#amenities"),
			heroCtaSecondaryText: String(getProp(s, "heroCtaSecondaryText", "") || getProp(s, "hero_cta_secondary_text", "") || "View Rates & Hours"),
			heroCtaSecondaryAnchor: String(getProp(s, "heroCtaSecondaryAnchor", "") || getProp(s, "hero_cta_secondary_anchor", "") || "#rates"),
			enableStickyNav: getProp(s, "enableStickyNav", true) !== false && getProp(s, "enable_sticky_nav", true) !== false,
			enableScrollspy: getProp(s, "enableScrollspy", true) !== false && getProp(s, "enable_scrollspy", true) !== false,
			enableBackToTop: getProp(s, "enableBackToTop", true) !== false && getProp(s, "enable_back_to_top", true) !== false,
			navBrandTitle: String(getProp(s, "navBrandTitle", "") || getProp(s, "nav_brand_title", "") || ""),
			navCtaText: String(getProp(s, "navCtaText", "") || getProp(s, "nav_cta_text", "") || "Reserve Online"),
			navCtaAnchor: String(getProp(s, "navCtaAnchor", "") || getProp(s, "nav_cta_anchor", "") || "#rates")
		};
	}

	function normalizeSection(s) {
		if (!s || typeof s !== "object") return null;
		return {
			id: parseInt(getProp(s, "id", 0), 10) || 0,
			onePageSiteId: parseInt(getProp(s, "onePageSiteId", 0) || getProp(s, "one_page_site_id", 0) || 0, 10),
			pageId: parseInt(getProp(s, "pageId", 0) || getProp(s, "page_id", 0) || 0, 10),
			anchorId: String(getProp(s, "anchorId", "") || getProp(s, "anchor_id", "") || "").replace(/^#+/, ""),
			sectionTitle: String(getProp(s, "sectionTitle", "") || getProp(s, "section_title", "") || ""),
			sectionSubtitle: String(getProp(s, "sectionSubtitle", "") || getProp(s, "section_subtitle", "") || ""),
			sectionLayout: String(getProp(s, "sectionLayout", "full") || getProp(s, "section_layout", "full")),
			sectionBg: String(getProp(s, "sectionBg", "default") || getProp(s, "section_bg", "default")),
			contentOverride: String(getProp(s, "contentOverride", "") || getProp(s, "content_override", "") || ""),
			showHeader: getProp(s, "showHeader", true) !== false && getProp(s, "show_header", true) !== false,
			showDivider: getProp(s, "showDivider", true) !== false && getProp(s, "show_divider", true) !== false,
			customCssClass: String(getProp(s, "customCssClass", "") || getProp(s, "custom_css_class", "") || ""),
			sortOrder: parseInt(getProp(s, "sortOrder", 0) || getProp(s, "sort_order", 0) || 0, 10),
			isActive: getProp(s, "isActive", true) !== false && getProp(s, "is_active", true) !== false,
			pageTitle: String(getProp(s, "pageTitle", "") || getProp(s, "page_title", "") || "")
		};
	}

	var sites = rawSites.map(normalizeSite).filter(Boolean);
	var selectedSite = normalizeSite(rawSelectedSite);
	var sections = rawSections.map(normalizeSection).filter(Boolean);

	// Elements
	var sitePicker = document.getElementById("opsSitePicker");
	var wsSelect = document.getElementById("opsWorkspaceSelect");
	var tabBtnBuilder = document.getElementById("tabBtnBuilder");
	var tabBtnPreview = document.getElementById("tabBtnPreview");
	var tabBtnDirectory = document.getElementById("tabBtnDirectory");
	var panelBuilder = document.getElementById("opsPanelBuilder");
	var panelPreview = document.getElementById("opsPanelPreview");
	var panelDirectory = document.getElementById("opsPanelDirectory");
	var previewIframe = document.getElementById("opsPreviewIframe");
	var deviceFrame = document.getElementById("opsDeviceFrame");

	// Modals
	var modalPagePicker = document.getElementById("modalOpsPagePicker");
	var modalEditSection = document.getElementById("modalOpsEditSection");
	var modalSiteMeta = document.getElementById("modalOpsSiteMeta");

	// Close open modals on backdrop click or Escape
	[modalPagePicker, modalEditSection, modalSiteMeta].forEach(function (m) {
		if (m) {
			m.addEventListener("click", function (e) {
				if (e.target === m) m.classList.remove("open");
			});
		}
	});

	document.addEventListener("keydown", function (e) {
		if (e.key === "Escape") {
			[modalPagePicker, modalEditSection, modalSiteMeta].forEach(function (m) {
				if (m) m.classList.remove("open");
			});
		}
	});

	// Tab switching
	function setTab(tabName) {
		[tabBtnBuilder, tabBtnPreview, tabBtnDirectory].forEach(function (btn) {
			if (btn) {
				btn.classList.remove("active");
				btn.setAttribute("aria-selected", "false");
			}
		});
		[panelBuilder, panelPreview, panelDirectory].forEach(function (p) {
			if (p) p.hidden = true;
		});

		if (tabName === "preview") {
			if (tabBtnPreview) {
				tabBtnPreview.classList.add("active");
				tabBtnPreview.setAttribute("aria-selected", "true");
			}
			if (panelPreview) panelPreview.hidden = false;
			if (previewIframe && selectedSite && selectedSite.id) {
				previewIframe.src = routes.preview + "?id=" + selectedSite.id + "&t=" + Date.now();
			}
		} else if (tabName === "directory") {
			if (tabBtnDirectory) {
				tabBtnDirectory.classList.add("active");
				tabBtnDirectory.setAttribute("aria-selected", "true");
			}
			if (panelDirectory) panelDirectory.hidden = false;
		} else {
			if (tabBtnBuilder) {
				tabBtnBuilder.classList.add("active");
				tabBtnBuilder.setAttribute("aria-selected", "true");
			}
			if (panelBuilder) panelBuilder.hidden = false;
		}
	}

	if (tabBtnBuilder) tabBtnBuilder.addEventListener("click", function () { setTab("builder"); });
	if (tabBtnPreview) tabBtnPreview.addEventListener("click", function () { setTab("preview"); });
	if (tabBtnDirectory) tabBtnDirectory.addEventListener("click", function () { setTab("directory"); });

	// Device toggles
	document.querySelectorAll(".opsDeviceBtn").forEach(function (btn) {
		btn.addEventListener("click", function () {
			document.querySelectorAll(".opsDeviceBtn").forEach(function (b) { b.classList.remove("active"); });
			btn.classList.add("active");
			var dev = btn.dataset.device || "desktop";
			if (deviceFrame) {
				deviceFrame.className = "ops-device-frame" + (dev === "desktop" ? "" : " " + dev);
			}
		});
	});

	// Workspace selector
	if (wsSelect) {
		wsSelect.addEventListener("change", function () {
			var val = wsSelect.value;
			window.location.href = "/pages/one-page?ws=" + encodeURIComponent(val);
		});
	}

	// Site Picker
	if (sitePicker) {
		sitePicker.addEventListener("change", function () {
			var siteId = sitePicker.value;
			window.location.href = "/pages/one-page?id=" + encodeURIComponent(siteId);
		});
	}

	// Safe Clipboard Copy Helper (works on HTTP, HTTPS, and iframes)
	function copyText(text) {
		if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
			return navigator.clipboard.writeText(text).catch(function () {
				return fallbackCopy(text);
			});
		}
		return fallbackCopy(text);
	}

	function fallbackCopy(text) {
		return new Promise(function (resolve, reject) {
			var ta = document.createElement("textarea");
			ta.value = text;
			ta.setAttribute("readonly", "");
			ta.style.position = "fixed";
			ta.style.top = "-9999px";
			ta.style.left = "-9999px";
			document.body.appendChild(ta);
			ta.select();
			try {
				var ok = document.execCommand("copy");
				document.body.removeChild(ta);
				if (ok) resolve();
				else reject(new Error("Copy command returned false"));
			} catch (err) {
				if (ta.parentNode) document.body.removeChild(ta);
				reject(err);
			}
		});
	}

	// Safe Confirmation Modal Helper (supports window.adminConfirm Promise API)
	function confirmAction(message, opts) {
		opts = opts || {};
		if (typeof window.adminConfirm === "function") {
			return window.adminConfirm(message, opts);
		}
		return Promise.resolve(window.confirm(message));
	}

	// Copy anchor tag helper
	document.addEventListener("click", function (e) {
		var btn = e.target.closest(".btnOpsCopyAnchor");
		if (btn) {
			e.preventDefault();
			var anc = btn.dataset.anchor || btn.getAttribute("data-anchor") || "";
			if (!anc) {
				var row = btn.closest(".ops-section-row");
				if (row && row.dataset.anchor) anc = "#" + row.dataset.anchor.replace(/^#+/, "");
			}
			if (anc) {
				copyText(anc).then(function () {
					if (window.showToast) window.showToast("Copied " + anc + " to clipboard!", "success");
					else if (window.adminAlert) window.adminAlert("Copied " + anc + " to clipboard!");
				}).catch(function () {
					if (window.adminAlert) window.adminAlert("Anchor tag: " + anc);
				});
			}
		}
	});

	// Page Picker Drawer open/close
	var btnOpenPicker = document.getElementById("btnOpsOpenPagePicker");
	var btnEmptyPicker = document.getElementById("btnOpsEmptyAddPages");
	var btnClosePicker = document.getElementById("btnCloseOpsPagePicker");
	var btnCancelPicker = document.getElementById("btnCancelOpsPagePicker");
	var pageSearch = document.getElementById("opsPageSearchInput");
	var pageSelectedCount = document.getElementById("opsPagesSelectedCount");

	function openPagePicker() {
		var curSiteId = selectedSite ? selectedSite.id : 0;
		if (!curSiteId) {
			if (window.adminAlert) window.adminAlert("Please create or select a One-Page Website first.");
			return;
		}
		if (modalPagePicker) {
			modalPagePicker.classList.add("open");
			updatePageSelectionCount();
		}
	}
	function closePagePicker() {
		if (modalPagePicker) modalPagePicker.classList.remove("open");
	}

	if (btnOpenPicker) btnOpenPicker.addEventListener("click", openPagePicker);
	if (btnEmptyPicker) btnEmptyPicker.addEventListener("click", openPagePicker);
	if (btnClosePicker) btnClosePicker.addEventListener("click", closePagePicker);
	if (btnCancelPicker) btnCancelPicker.addEventListener("click", closePagePicker);

	function updatePageSelectionCount() {
		var checked = document.querySelectorAll(".opsCandidatePageCb:checked");
		if (pageSelectedCount) {
			pageSelectedCount.textContent = checked.length + " page" + (checked.length === 1 ? "" : "s") + " selected";
		}
	}

	document.querySelectorAll(".opsCandidatePageCb").forEach(function (cb) {
		cb.addEventListener("change", updatePageSelectionCount);
	});

	if (pageSearch) {
		pageSearch.addEventListener("input", function () {
			var q = pageSearch.value.toLowerCase().trim();
			document.querySelectorAll(".ops-page-item-row").forEach(function (row) {
				var text = row.textContent.toLowerCase();
				row.style.display = text.indexOf(q) >= 0 ? "flex" : "none";
			});
		});
	}

	// Submit Adding Selected Pages as Sections
	var btnSubmitPages = document.getElementById("btnSubmitOpsAddPages");
	if (btnSubmitPages) {
		btnSubmitPages.addEventListener("click", function () {
			var curSiteId = selectedSite ? selectedSite.id : 0;
			if (!curSiteId) {
				if (window.adminAlert) window.adminAlert("Please select or create a One-Page Website first.");
				return;
			}
			var checked = Array.from(document.querySelectorAll(".opsCandidatePageCb:checked"));
			if (checked.length === 0) {
				if (window.adminAlert) window.adminAlert("Please select at least one page to add as a section.");
				return;
			}

			btnSubmitPages.disabled = true;
			btnSubmitPages.textContent = "Adding Sections...";

			var promises = checked.map(function (cb) {
				var pageId = parseInt(cb.value, 10);
				var title = cb.dataset.title || "";
				var slug = cb.dataset.slug || "";
				var summary = cb.dataset.summary || "";
				var anchor = slug.replace(/^#+/, "") || title.toLowerCase().replace(/[^a-z0-9]+/g, "-");

				return fetch(routes.saveSection, {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({
						one_page_site_id: curSiteId,
						page_id: pageId,
						section_title: title,
						section_subtitle: summary,
						anchor_id: anchor,
						section_layout: "full",
						section_bg: "default",
						show_header: true,
						show_divider: true,
						is_active: true
					})
				}).then(function (r) { return r.json(); });
			});

			Promise.all(promises).then(function () {
				if (window.showToast) window.showToast("Successfully added sections to One-Page Site!", "success");
				setTimeout(function () {
					window.location.reload();
				}, 600);
			}).catch(function (err) {
				btnSubmitPages.disabled = false;
				btnSubmitPages.textContent = "Add Selected Pages as Sections";
				if (window.adminAlert) window.adminAlert("Failed to add sections: " + err.message);
			});
		});
	}

	// Edit Section Modal
	var btnCloseEditSec = document.getElementById("btnCloseOpsEditSection");
	var btnCancelEditSec = document.getElementById("btnCancelOpsEditSection");
	var formEditSec = document.getElementById("opsEditSectionForm");

	function openEditSection(sec) {
		sec = sec || {};
		var sId = parseInt(getProp(sec, "id", 0), 10) || 0;
		var siteId = parseInt(getProp(sec, "onePageSiteId", 0) || getProp(sec, "one_page_site_id", 0) || (selectedSite ? selectedSite.id : 0), 10);
		var pId = parseInt(getProp(sec, "pageId", 0) || getProp(sec, "page_id", 0) || 0, 10);
		var title = getProp(sec, "sectionTitle", "") || getProp(sec, "section_title", "") || "";
		var anchor = String(getProp(sec, "anchorId", "") || getProp(sec, "anchor_id", "") || "").replace(/^#+/, "");
		var subtitle = getProp(sec, "sectionSubtitle", "") || getProp(sec, "section_subtitle", "") || "";
		var layout = getProp(sec, "sectionLayout", "full") || getProp(sec, "section_layout", "full");
		var bg = getProp(sec, "sectionBg", "default") || getProp(sec, "section_bg", "default");
		var customClass = getProp(sec, "customCssClass", "") || getProp(sec, "custom_css_class", "") || "";
		var showHeader = getProp(sec, "showHeader", true) !== false && getProp(sec, "show_header", true) !== false;
		var showDivider = getProp(sec, "showDivider", true) !== false && getProp(sec, "show_divider", true) !== false;
		var isActive = getProp(sec, "isActive", true) !== false && getProp(sec, "is_active", true) !== false;

		document.getElementById("opsSecId").value = sId;
		document.getElementById("opsSecSiteId").value = siteId;
		document.getElementById("opsSecPageId").value = pId;
		document.getElementById("opsSecTitle").value = title;
		document.getElementById("opsSecAnchorId").value = anchor;
		document.getElementById("opsSecSubtitle").value = subtitle;
		document.getElementById("opsSecLayout").value = layout;
		document.getElementById("opsSecBg").value = bg;
		updateSecBgPreview(bg);
		document.getElementById("opsSecCustomClass").value = customClass;
		document.getElementById("opsSecShowHeader").checked = showHeader;
		document.getElementById("opsSecShowDivider").checked = showDivider;
		document.getElementById("opsSecIsActive").checked = isActive;

		var titleEl = document.getElementById("opsEditSectionModalTitle");
		if (titleEl) {
			titleEl.textContent = title ? ("Configure Section: " + title) : "Configure Section";
		}

		if (modalEditSection) modalEditSection.classList.add("open");
	}

	function closeEditSection() {
		if (modalEditSection) modalEditSection.classList.remove("open");
	}

	function updateSecBgPreview(bgVal) {
		var preview = document.getElementById("opsSecBgPreview");
		if (!preview) return;
		preview.className = "ops-bg-" + (bgVal || "default");
	}

	var selSecBg = document.getElementById("opsSecBg");
	if (selSecBg) {
		selSecBg.addEventListener("change", function () {
			updateSecBgPreview(this.value);
		});
	}

	if (btnCloseEditSec) btnCloseEditSec.addEventListener("click", closeEditSection);
	if (btnCancelEditSec) btnCancelEditSec.addEventListener("click", closeEditSection);

	document.addEventListener("click", function (e) {
		var btn = e.target.closest(".btnOpsEditSection");
		if (btn) {
			e.preventDefault();
			var id = parseInt(btn.dataset.id || btn.getAttribute("data-id"), 10);
			var sec = sections.find(function (s) { return s && s.id === id; });
			if (!sec) {
				// Fallback to reading data from the DOM row
				var row = btn.closest(".ops-section-row");
				if (row) {
					var titleEl = row.querySelector("strong");
					var titleText = titleEl ? titleEl.textContent.trim() : "";
					var anc = (row.dataset.anchor || "").replace(/^#+/, "");
					sec = {
						id: id,
						onePageSiteId: selectedSite ? selectedSite.id : 0,
						sectionTitle: titleText,
						anchorId: anc,
						sectionLayout: "full",
						sectionBg: "default",
						showHeader: true,
						showDivider: true,
						isActive: true
					};
				}
			}
			if (sec) {
				openEditSection(sec);
			} else {
				if (window.adminAlert) window.adminAlert("Section could not be loaded for ID: " + id);
			}
		}
	});

	if (formEditSec) {
		formEditSec.addEventListener("submit", function (e) {
			e.preventDefault();
			var payload = {
				id: parseInt(document.getElementById("opsSecId").value, 10),
				one_page_site_id: parseInt(document.getElementById("opsSecSiteId").value, 10) || (selectedSite ? selectedSite.id : 0),
				page_id: parseInt(document.getElementById("opsSecPageId").value, 10),
				section_title: document.getElementById("opsSecTitle").value.trim(),
				anchor_id: document.getElementById("opsSecAnchorId").value.trim().replace(/^#+/, ""),
				section_subtitle: document.getElementById("opsSecSubtitle").value.trim(),
				section_layout: document.getElementById("opsSecLayout").value,
				section_bg: document.getElementById("opsSecBg").value,
				custom_css_class: document.getElementById("opsSecCustomClass").value.trim(),
				show_header: document.getElementById("opsSecShowHeader").checked,
				show_divider: document.getElementById("opsSecShowDivider").checked,
				is_active: document.getElementById("opsSecIsActive").checked
			};

			var submitBtn = formEditSec.querySelector("button[type='submit']");
			if (submitBtn) {
				submitBtn.disabled = true;
				submitBtn.textContent = "Saving...";
			}

			fetch(routes.saveSection, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify(payload)
			}).then(function (r) {
				return r.json();
			}).then(function (res) {
				if (submitBtn) {
					submitBtn.disabled = false;
					submitBtn.textContent = "Save Section";
				}
				var isSuccess = (res && (res.success === true || res.SUCCESS === true));
				var msg = (res && (res.message || res.MESSAGE)) || "";
				if (isSuccess) {
					if (window.showToast) window.showToast("Section updated!", "success");
					closeEditSection();
					setTimeout(function () { window.location.reload(); }, 500);
				} else {
					if (window.adminAlert) window.adminAlert(msg || "Failed to save section.");
				}
			}).catch(function (err) {
				if (submitBtn) {
					submitBtn.disabled = false;
					submitBtn.textContent = "Save Section";
				}
				if (window.adminAlert) window.adminAlert("Error: " + err.message);
			});
		});
	}

	// Delete Section
	document.addEventListener("click", function (e) {
		var btn = e.target.closest(".btnOpsDeleteSection");
		if (btn) {
			e.preventDefault();
			var id = parseInt(btn.dataset.id || btn.getAttribute("data-id"), 10);
			if (!id) return;

			confirmAction("Are you sure you want to remove this section from the One-Page Site?", {
				title: "Remove Section?",
				acceptText: "Remove Section",
				destructive: true
			}).then(function (confirmed) {
				if (!confirmed) return;

				fetch(routes.deleteSection, {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({ id: id })
				}).then(function (r) {
					return r.json();
				}).then(function (res) {
					var isSuccess = (res && (res.success === true || res.SUCCESS === true));
					var msg = (res && (res.message || res.MESSAGE)) || "";
					if (isSuccess) {
						if (window.showToast) window.showToast("Section removed.", "success");
						var row = btn.closest(".ops-section-row");
						if (row) row.remove();
						var countEl = document.getElementById("opsSectionCount");
						if (countEl) {
							var currentCount = document.querySelectorAll(".ops-section-row").length;
							countEl.textContent = currentCount;
						}
						setTimeout(function () { window.location.reload(); }, 400);
					} else {
						if (window.adminAlert) window.adminAlert(msg || "Failed to remove section.");
					}
				}).catch(function (err) {
					if (window.adminAlert) window.adminAlert("Delete error: " + err.message);
				});
			});
		}
	});

	// Reorder Sections Helper
	function reorderSections(newOrderIds) {
		fetch(routes.reorderSections, {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ ids: newOrderIds })
		}).then(function (r) {
			return r.json();
		}).then(function (res) {
			var isSuccess = (res && (res.success === true || res.SUCCESS === true));
			if (isSuccess) {
				if (window.showToast) window.showToast("Section order updated.", "success");
				// Optionally reload after short delay to sync preview
				setTimeout(function () { window.location.reload(); }, 500);
			}
		}).catch(function (err) {
			if (window.adminAlert) window.adminAlert("Reorder error: " + err.message);
		});
	}

	// Move Up / Down Button Event Delegation
	document.addEventListener("click", function (e) {
		var btnUp = e.target.closest(".btnOpsMoveUp");
		var btnDown = e.target.closest(".btnOpsMoveDown");
		if (btnUp || btnDown) {
			e.preventDefault();
			var btn = btnUp || btnDown;
			var row = btn.closest(".ops-section-row");
			if (!row) return;

			var parent = row.parentNode;
			if (btnUp) {
				var prev = row.previousElementSibling;
				if (prev && prev.classList.contains("ops-section-row")) {
					parent.insertBefore(row, prev);
				} else {
					return; // Already at top
				}
			} else if (btnDown) {
				var next = row.nextElementSibling;
				if (next && next.classList.contains("ops-section-row")) {
					parent.insertBefore(next, row);
				} else {
					return; // Already at bottom
				}
			}

			// Gather new ordering of section IDs from the reordered DOM rows
			var reorderedRows = Array.from(parent.querySelectorAll(".ops-section-row"));
			var newIds = reorderedRows.map(function (r) {
				return parseInt(r.dataset.id || r.getAttribute("data-id"), 10);
			}).filter(function (val) {
				return !isNaN(val) && val > 0;
			});

			if (newIds.length > 0) {
				reorderSections(newIds);
			}
		}
	});

	// Site Meta / New Site Modal
	var btnNewSite = document.getElementById("btnOpsCreateNewSite");
	var btnInitFirst = document.getElementById("btnOpsInitFirstSite");
	var btnEditMeta = document.getElementById("btnOpsEditSiteMeta");
	var btnCloseMeta = document.getElementById("btnCloseOpsSiteMeta");
	var btnCancelMeta = document.getElementById("btnCancelOpsSiteMeta");
	var formSiteMeta = document.getElementById("opsSiteMetaForm");

	function openSiteMeta(site) {
		site = site || {};
		document.getElementById("opsSiteMetaId").value = getProp(site, "id", 0) || 0;
		document.getElementById("opsSiteMetaTitle").value = getProp(site, "title", "") || "";
		document.getElementById("opsSiteMetaSlug").value = getProp(site, "slug", "") || "";
		document.getElementById("opsSiteMetaSubtitle").value = getProp(site, "subtitle", "") || "";
		document.getElementById("opsSiteMetaTheme").value = getProp(site, "theme", "river-park") || "river-park";
		document.getElementById("opsSiteMetaWorkspace").value = getProp(site, "siteid", "") || getProp(site, "siteId", "") || getProp(config, "activeWorkspace", "global") || "global";
		document.getElementById("opsSiteMetaHeroHeadline").value = getProp(site, "heroHeadline", "") || getProp(site, "hero_headline", "") || "";
		document.getElementById("opsSiteMetaHeroTagline").value = getProp(site, "heroTagline", "") || getProp(site, "hero_tagline", "") || "";
		document.getElementById("opsSiteMetaHeroImage").value = getProp(site, "heroImageUrl", "") || getProp(site, "hero_image_url", "") || "";
		document.getElementById("opsSiteMetaHeroCtaPrimaryText").value = getProp(site, "heroCtaPrimaryText", "") || getProp(site, "hero_cta_primary_text", "") || "Explore Amenities";
		document.getElementById("opsSiteMetaHeroCtaPrimaryAnchor").value = getProp(site, "heroCtaPrimaryAnchor", "") || getProp(site, "hero_cta_primary_anchor", "") || "#amenities";
		document.getElementById("opsSiteMetaHeroCtaSecondaryText").value = getProp(site, "heroCtaSecondaryText", "") || getProp(site, "hero_cta_secondary_text", "") || "View Rates & Hours";
		document.getElementById("opsSiteMetaHeroCtaSecondaryAnchor").value = getProp(site, "heroCtaSecondaryAnchor", "") || getProp(site, "hero_cta_secondary_anchor", "") || "#rates";
		document.getElementById("opsSiteMetaStickyNav").checked = getProp(site, "enableStickyNav", true) !== false && getProp(site, "enable_sticky_nav", true) !== false;
		document.getElementById("opsSiteMetaScrollspy").checked = getProp(site, "enableScrollspy", true) !== false && getProp(site, "enable_scrollspy", true) !== false;
		document.getElementById("opsSiteMetaBackToTop").checked = getProp(site, "enableBackToTop", true) !== false && getProp(site, "enable_back_to_top", true) !== false;
		document.getElementById("opsSiteMetaNavBrand").value = getProp(site, "navBrandTitle", "") || getProp(site, "nav_brand_title", "") || "";
		document.getElementById("opsSiteMetaNavCtaText").value = getProp(site, "navCtaText", "") || getProp(site, "nav_cta_text", "") || "Reserve Online";
		document.getElementById("opsSiteMetaNavCtaAnchor").value = getProp(site, "navCtaAnchor", "") || getProp(site, "nav_cta_anchor", "") || "#rates";

		if (modalSiteMeta) modalSiteMeta.classList.add("open");
	}
	function closeSiteMeta() {
		if (modalSiteMeta) modalSiteMeta.classList.remove("open");
	}

	if (btnNewSite) btnNewSite.addEventListener("click", function () { openSiteMeta({}); });
	if (btnInitFirst) btnInitFirst.addEventListener("click", function () { openSiteMeta({}); });
	if (btnEditMeta) btnEditMeta.addEventListener("click", function () { openSiteMeta(selectedSite); });
	if (btnCloseMeta) btnCloseMeta.addEventListener("click", closeSiteMeta);
	if (btnCancelMeta) btnCancelMeta.addEventListener("click", closeSiteMeta);

	if (formSiteMeta) {
		formSiteMeta.addEventListener("submit", function (e) {
			e.preventDefault();
			var payload = {
				id: parseInt(document.getElementById("opsSiteMetaId").value, 10),
				title: document.getElementById("opsSiteMetaTitle").value.trim(),
				slug: document.getElementById("opsSiteMetaSlug").value.trim(),
				subtitle: document.getElementById("opsSiteMetaSubtitle").value.trim(),
				theme: document.getElementById("opsSiteMetaTheme").value,
				siteid: document.getElementById("opsSiteMetaWorkspace").value,
				heroHeadline: document.getElementById("opsSiteMetaHeroHeadline").value.trim(),
				heroTagline: document.getElementById("opsSiteMetaHeroTagline").value.trim(),
				heroImageUrl: document.getElementById("opsSiteMetaHeroImage").value.trim(),
				heroCtaPrimaryText: document.getElementById("opsSiteMetaHeroCtaPrimaryText").value.trim(),
				heroCtaPrimaryAnchor: document.getElementById("opsSiteMetaHeroCtaPrimaryAnchor").value.trim(),
				heroCtaSecondaryText: document.getElementById("opsSiteMetaHeroCtaSecondaryText").value.trim(),
				heroCtaSecondaryAnchor: document.getElementById("opsSiteMetaHeroCtaSecondaryAnchor").value.trim(),
				enableStickyNav: document.getElementById("opsSiteMetaStickyNav").checked,
				enableScrollspy: document.getElementById("opsSiteMetaScrollspy").checked,
				enableBackToTop: document.getElementById("opsSiteMetaBackToTop").checked,
				navBrandTitle: document.getElementById("opsSiteMetaNavBrand").value.trim(),
				navCtaText: document.getElementById("opsSiteMetaNavCtaText").value.trim(),
				navCtaAnchor: document.getElementById("opsSiteMetaNavCtaAnchor").value.trim(),
				isPublished: true
			};

			var submitBtn = formSiteMeta.querySelector("button[type='submit']");
			if (submitBtn) {
				submitBtn.disabled = true;
				submitBtn.textContent = "Saving Site...";
			}

			fetch(routes.saveSite, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify(payload)
			}).then(function (r) {
				return r.json();
			}).then(function (res) {
				if (submitBtn) {
					submitBtn.disabled = false;
					submitBtn.textContent = "Save Site Settings";
				}
				var isSuccess = (res && (res.success === true || res.SUCCESS === true));
				var msg = (res && (res.message || res.MESSAGE)) || "";
				var newId = (res && (res.id || res.ID)) || "";
				if (isSuccess) {
					if (window.showToast) window.showToast("Site configuration saved!", "success");
					closeSiteMeta();
					setTimeout(function () {
						window.location.href = "/pages/one-page?id=" + newId;
					}, 600);
				} else {
					if (window.adminAlert) window.adminAlert(msg || "Failed to save site.");
				}
			}).catch(function (err) {
				if (submitBtn) {
					submitBtn.disabled = false;
					submitBtn.textContent = "Save Site Settings";
				}
				if (window.adminAlert) window.adminAlert("Save error: " + err.message);
			});
		});
	}

	// Delete Site
	var btnDeleteSite = document.getElementById("btnOpsDeleteSite");
	if (btnDeleteSite) {
		btnDeleteSite.addEventListener("click", function () {
			var curSiteId = selectedSite ? selectedSite.id : 0;
			if (!curSiteId) return;

			confirmAction("Are you sure you want to delete this entire One-Page Website and all its sections?", {
				title: "Delete One-Page Site?",
				acceptText: "Delete Site",
				destructive: true
			}).then(function (confirmed) {
				if (!confirmed) return;

				fetch(routes.deleteSite, {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({ id: curSiteId })
				}).then(function (r) {
					return r.json();
				}).then(function (res) {
					var isSuccess = (res && (res.success === true || res.SUCCESS === true));
					var msg = (res && (res.message || res.MESSAGE)) || "";
					if (isSuccess) {
						if (window.showToast) window.showToast("Site deleted.", "success");
						setTimeout(function () { window.location.href = "/pages/one-page"; }, 500);
					} else {
						if (window.adminAlert) window.adminAlert(msg || "Failed to delete site.");
					}
				}).catch(function (err) {
					if (window.adminAlert) window.adminAlert("Delete error: " + err.message);
				});
			});
		});
	}

	// Delete Site from Directory Table
	document.addEventListener("click", function (e) {
		var btn = e.target.closest(".btnOpsDirectoryDeleteSite");
		if (btn) {
			e.preventDefault();
			var siteId = parseInt(btn.dataset.id || btn.getAttribute("data-id"), 10);
			var siteTitle = btn.dataset.title || "this One-Page site";
			if (!siteId) return;

			confirmAction("Are you sure you want to delete '" + siteTitle + "' and all its sections?", {
				title: "Delete One-Page Site?",
				acceptText: "Delete Site",
				destructive: true
			}).then(function (confirmed) {
				if (!confirmed) return;

				fetch(routes.deleteSite, {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({ id: siteId })
				}).then(function (r) {
					return r.json();
				}).then(function (res) {
					var isSuccess = (res && (res.success === true || res.SUCCESS === true));
					var msg = (res && (res.message || res.MESSAGE)) || "";
					if (isSuccess) {
						if (window.showToast) window.showToast("Site deleted.", "success");
						var tr = btn.closest("tr");
						if (tr) tr.remove();
						setTimeout(function () { window.location.reload(); }, 500);
					} else {
						if (window.adminAlert) window.adminAlert(msg || "Failed to delete site.");
					}
				}).catch(function (err) {
					if (window.adminAlert) window.adminAlert("Delete error: " + err.message);
				});
			});
		}
	});

	// Sync to Navigation Menu
	var btnSyncMenu = document.getElementById("btnOpsSyncMenu");
	if (btnSyncMenu) {
		btnSyncMenu.addEventListener("click", function () {
			var curSiteId = selectedSite ? selectedSite.id : 0;
			if (!curSiteId) return;
			btnSyncMenu.disabled = true;
			btnSyncMenu.textContent = "Syncing Menu...";

			fetch(routes.syncMenu, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ id: curSiteId })
			}).then(function (r) {
				return r.json();
			}).then(function (res) {
				btnSyncMenu.disabled = false;
				btnSyncMenu.innerHTML = '<span>Sync Sections to Navigation Menu</span>';
				var isSuccess = (res && (res.success === true || res.SUCCESS === true));
				var msg = (res && (res.message || res.MESSAGE)) || "";
				if (isSuccess) {
					if (window.showToast) window.showToast(msg || "Menu synchronized successfully!", "success");
					else if (window.adminAlert) window.adminAlert(msg || "Menu synchronized successfully!");
				} else {
					if (window.adminAlert) window.adminAlert(msg || "Menu sync failed.");
				}
			}).catch(function (err) {
				btnSyncMenu.disabled = false;
				btnSyncMenu.innerHTML = '<span>Sync Sections to Navigation Menu</span>';
				if (window.adminAlert) window.adminAlert("Sync error: " + err.message);
			});
		});
	}

	// Compile & Save to Content Manager
	var btnCompile = document.getElementById("btnOpsCompileSave");
	var chkSeparate = document.getElementById("chkOpsSeparateAssets");
	if (btnCompile) {
		btnCompile.addEventListener("click", function () {
			var curSiteId = selectedSite ? selectedSite.id : 0;
			if (!curSiteId) return;
			var separateAssets = chkSeparate ? chkSeparate.checked : true;
			btnCompile.disabled = true;
			btnCompile.textContent = "Compiling One-Page Site...";

			fetch(routes.compile, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ id: curSiteId, separateAssets: separateAssets })
			}).then(function (r) {
				return r.json();
			}).then(function (res) {
				btnCompile.disabled = false;
				btnCompile.innerHTML = '<span>Compile &amp; Save to Content Manager</span>';
				var isSuccess = (res && (res.success === true || res.SUCCESS === true));
				var msg = (res && (res.message || res.MESSAGE)) || "";
				if (isSuccess) {
					if (window.showToast) window.showToast(msg || "Site compiled successfully!", "success");
					else if (window.adminAlert) window.adminAlert(msg || "Site compiled successfully!");
				} else {
					if (window.adminAlert) window.adminAlert(msg || "Compilation failed.");
				}
			}).catch(function (err) {
				btnCompile.disabled = false;
				btnCompile.innerHTML = '<span>Compile &amp; Save to Content Manager</span>';
				if (window.adminAlert) window.adminAlert("Compile error: " + err.message);
			});
		});
	}

	// Standalone Preview in New Tab
	var btnPreviewTab = document.getElementById("btnOpsOpenPreviewTab");
	if (btnPreviewTab) {
		btnPreviewTab.addEventListener("click", function () {
			var curSiteId = selectedSite ? selectedSite.id : 0;
			if (!curSiteId) return;
			window.open(routes.preview + "?id=" + curSiteId, "_blank");
		});
	}

	// Publish to Production (Updates files with separated assets in workspace.project_path)
	var btnPublish = document.getElementById("btnOpsPublishProduction");
	if (btnPublish) {
		btnPublish.addEventListener("click", function () {
			var curSiteId = selectedSite ? selectedSite.id : 0;
			if (!curSiteId) return;

			var siteTitle = selectedSite.title || "One-Page Site";
			var confirmMsg = "Publish \"" + siteTitle + "\" directly to Production?\n\nThis will compile and write updated index.html, assets/css/site.css, and assets/js/site.js directly to the workspace project path on the web server.";

			window.adminConfirm(confirmMsg, {
				title: "Confirm Production Deployment",
				confirmButtonText: "Publish Now",
				cancelButtonText: "Cancel",
				isDanger: false
			}).then(function (confirmed) {
				if (!confirmed) return;

				btnPublish.disabled = true;
				btnPublish.innerHTML = '<span>Publishing to Production...</span>';

				fetch(routes.publish, {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({ id: curSiteId })
				}).then(function (r) {
					return r.json();
				}).then(function (res) {
					btnPublish.disabled = false;
					btnPublish.innerHTML = '<span>Publish to Production</span>';
					var isSuccess = (res && (res.success === true || res.SUCCESS === true));
					var msg = (res && (res.message || res.MESSAGE)) || "";
					var pPath = (res && (res.projectPath || res.PROJECTPATH)) || "";
					if (isSuccess) {
						var successMsg = msg || ("Site successfully published to " + pPath + "!");
						if (window.showToast) window.showToast(successMsg, "success");
						else if (window.adminAlert) window.adminAlert(successMsg);
					} else {
						if (window.adminAlert) window.adminAlert(msg || "Publishing to production failed.");
					}
				}).catch(function (err) {
					btnPublish.disabled = false;
					btnPublish.innerHTML = '<span>Publish to Production</span>';
					if (window.adminAlert) window.adminAlert("Publishing error: " + err.message);
				});
			});
		});
	}

	// Export Standalone HTML
	var btnExport = document.getElementById("btnOpsExportHtml");
	if (btnExport) {
		btnExport.addEventListener("click", function () {
			var curSiteId = selectedSite ? selectedSite.id : 0;
			if (!curSiteId) return;
			var separateAssets = chkSeparate ? chkSeparate.checked : true;
			window.location.href = routes.export + "?id=" + curSiteId + (separateAssets ? "&format=html&separateAssets=1" : "&format=html&separateAssets=0");
		});
	}

	// Browse Hero Media Library
	var btnBrowseHero = document.getElementById("btnOpsBrowseHeroMedia");
	if (btnBrowseHero) {
		btnBrowseHero.addEventListener("click", function () {
			if (typeof window.openMediaPicker === "function") {
				window.openMediaPicker("image", {
					onSelect: function (url) {
						var heroInput = document.getElementById("opsSiteMetaHeroImage");
						if (heroInput) heroInput.value = url;
					}
				});
			} else {
				if (window.showToast) window.showToast("Enter image path into Hero Cover Image URL field.", "info");
			}
		});
	}

})();
</script>

