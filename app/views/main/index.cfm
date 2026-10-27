<!--- CMS Dashboard View --->
<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem;">
			<h1 class="page-title" style="margin-bottom:0;"><cfif variables.hasWorkspace>#encodeForHTML(variables.workspaceName)# </cfif>Dashboard</h1>
			<cfif variables.hasWorkspace>
				<span class="badge #encodeForHTML(variables.activeWsObj.badgeClass ?: 'badge-primary')#" style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.04em;">
					#encodeForHTML(variables.activeWsObj.badge ?: variables.activeWorkspaceId)#
				</span>
			</cfif>
		</div>
		<ol class="breadcrumb">
			<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name='dashboard', size=14)# Home</a></li>
			<li class="breadcrumb-item">Content Management</li>
			<li class="breadcrumb-item active"><cfif variables.hasWorkspace>#encodeForHTML(variables.workspaceName)#<cfelse>Dashboard</cfif></li>
		</ol>
	</div>
	<div class="page-actions">
		<cfif variables.hasWorkspace>
			<cfscript>
				local.frontEndDomain = (StructKeyExists(variables.activeWsObj, "domain_name") && Len(Trim(variables.activeWsObj.domain_name)))
					? Trim(variables.activeWsObj.domain_name)
					: "www.chelancounty.gov";
				if (!REFindNoCase("^https?://", local.frontEndDomain)) {
					local.frontEndDomain = "https://" & local.frontEndDomain;
				}
				if (Right(local.frontEndDomain, 1) == "/") {
					local.frontEndDomain = Left(local.frontEndDomain, Len(local.frontEndDomain) - 1);
				}
				local.wsSlug = (StructKeyExists(variables.activeWsObj, "virtual_directory") && Len(Trim(variables.activeWsObj.virtual_directory)))
					? Trim(variables.activeWsObj.virtual_directory)
					: variables.activeWorkspaceId;
				local.isStandaloneSite = (StructKeyExists(variables.activeWsObj, "type") && variables.activeWsObj.type == "site")
					|| (local.wsSlug == "shared" || local.wsSlug == "root" || local.wsSlug == "global");
				if (local.isStandaloneSite) {
					local.portalUrl = local.frontEndDomain & "/";
				} else if (StructKeyExists(variables.activeWsObj, "redirect_url") && Len(Trim(variables.activeWsObj.redirect_url))) {
					local.portalUrl = variables.activeWsObj.redirect_url;
					if (!REFindNoCase("^https?://", local.portalUrl) && Left(local.portalUrl, 1) != "/") {
						local.portalUrl = local.frontEndDomain & "/" & local.portalUrl;
					}
				} else {
					local.portalUrl = local.frontEndDomain & "/" & local.wsSlug;
				}
			</cfscript>
			<a href="#encodeForHTMLAttribute(local.portalUrl)#" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm" title="Preview public portal for this workspace (#encodeForHTMLAttribute(local.portalUrl)#)">
				#svgIcon(name="globe", size=14)#
				<span>View Portal</span>
				#svgIcon(name="external-link", size=12)#
			</a>
		</cfif>
		<button type="button" class="btn btn-primary btn-sm" id="btnHeaderAddPage" onclick="openAddPageModal();">
			#svgIcon(name="plus", size=15)#
			<span>Add New Page</span>
		</button>
	</div>
</div>

<!--- 4 Real KPI Metric Stat Cards Scoped to Active Workspace --->
<div class="stat-grid">
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Workspace Pages</span>
			<span class="stat-value">#NumberFormat(variables.stats.totalPages, ",")#</span>
			<span class="stat-change up">
				#svgIcon(name="check-circle", size=13)#
				<span>#NumberFormat(variables.stats.publishedPages, ",")# Active / Published</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary">
			#svgIcon(name="pages", size=24)#
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Online Forms</span>
			<span class="stat-value">#NumberFormat(variables.stats.totalForms, ",")#</span>
			<span class="stat-change" style="color:var(--admin-purple);">
				#svgIcon(name="clipboard-list", size=13)#
				<span>#NumberFormat(variables.stats.activeForms, ",")# Published Citizen Forms</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-purple">
			#svgIcon(name="clipboard-list", size=24)#
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Form Submissions</span>
			<span class="stat-value">#NumberFormat(variables.stats.pendingSubmissions, ",")#</span>
			<span class="stat-change <cfif variables.stats.pendingSubmissions gt 0>style="color:var(--admin-warning);"<cfelse>up</cfif>">
				<cfif variables.stats.pendingSubmissions gt 0>
					#svgIcon(name="clock", size=13)#
					<span>Awaiting staff review</span>
				<cfelse>
					#svgIcon(name="check-circle", size=13)#
					<span>Inbox up to date</span>
				</cfif>
			</span>
		</div>
		<div class="stat-icon-wrapper <cfif variables.stats.pendingSubmissions gt 0>stat-icon-warning<cfelse>stat-icon-success</cfif>">
			#svgIcon(name="mail", size=24)#
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Media &amp; Files</span>
			<span class="stat-value">#NumberFormat(variables.stats.mediaCount, ",")#</span>
			<span class="stat-change" style="color:var(--admin-info);">
				#svgIcon(name="hard-drive", size=13)#
				<span>#variables.stats.mediaFormattedSize# in workspace</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-info">
			#svgIcon(name="media", size=24)#
		</div>
	</div>
</div>

<!--- Main Responsive Dashboard Masonry Grid --->
<div class="dashboard-grid">
	<!--- Recent Workspace Pages Table Card --->
	<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="file-text", size=18)#
					<span>Recent Workspace Pages</span>
				</h2>
				<div class="card-tools">
					<button type="button" class="btn btn-primary btn-sm" id="btnRecentPagesAddPage" onclick="openAddPageModal();">
						#svgIcon(name="plus", size=14)#
						<span>Add Page</span>
					</button>
				</div>
			</div>

			<cfif ArrayLen(variables.recentPages) gt 0>
				<div class="table-responsive">
					<table class="admin-table">
						<thead>
							<tr>
								<th>Page Title</th>
								<th>Status</th>
								<th style="text-align:right;">Actions</th>
							</tr>
						</thead>
						<tbody>
							<cfloop array="#variables.recentPages#" index="local.p">
								<tr>
									<td>
										<div style="font-weight:600; color:var(--admin-text-main);">
											<a href="#urlFor(controller='pages', action='edit', params='id=' & local.p.id)#" style="color:inherit; text-decoration:none;">
												#encodeForHTML(local.p.title)#
											</a>
										</div>
										<div style="font-size:0.75rem; color:var(--admin-text-subtle);">
											/#encodeForHTML(local.p.siteId)#/#encodeForHTML(local.p.permalink)#
										</div>
									</td>
									<td>
										#statusBadge(local.p.status)#
									</td>
									<td style="text-align:right; white-space:nowrap;">
										<div style="display:inline-flex; gap:0.25rem;">
											<a href="#urlFor(controller='pages', action='edit', params='id=' & local.p.id)#" class="btn btn-outline btn-sm btn-icon-only" title="Edit Page" aria-label="Edit #encodeForHTML(local.p.title)#">
												#svgIcon(name="edit", size=14)#
											</a>
											<a href="/#encodeForHTML(local.p.siteId)#/#encodeForHTML(local.p.permalink)#" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Page" aria-label="Preview #encodeForHTML(local.p.title)#">
												#svgIcon(name="eye", size=14)#
											</a>
										</div>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
				<div class="card-footer" style="display:flex; justify-content:space-between; align-items:center; font-size:0.825rem;">
					<span style="color:var(--admin-text-muted);">
						Showing #ArrayLen(variables.recentPages)# of #NumberFormat(variables.stats.totalPages, ",")# pages in this workspace
					</span>
					<a href="#urlFor(controller='pages', action='index', params=variables.hasWorkspace ? ('ws=' & variables.activeWorkspaceId) : '')#" class="btn btn-outline btn-sm">
						<span>Manage in Page Editor</span>
						#svgIcon(name="arrow-right", size=12)#
					</a>
				</div>
			<cfelse>
				<div class="card-body" style="text-align:center; padding:3rem 1.5rem;">
					<div style="width:48px; height:48px; border-radius:50%; background:var(--admin-surface-subtle); color:var(--admin-text-subtle); display:flex; align-items:center; justify-content:center; margin:0 auto 1rem auto;">
						#svgIcon(name="file-text", size=24)#
					</div>
					<h3 style="font-size:1rem; font-weight:600; margin:0 0 0.4rem 0;">No pages published in this workspace yet</h3>
					<p style="font-size:0.85rem; color:var(--admin-text-muted); margin:0 auto 1.25rem auto; max-width:400px;">
						Create the primary department homepage or informational subpages to start publishing content for Chelan County citizens.
					</p>
					<button type="button" class="btn btn-primary btn-sm" onclick="openAddPageModal();">
						#svgIcon(name="plus", size=14)#
						<span>Create First Page</span>
					</button>
				</div>
			</cfif>
		</div>

		<!--- Media Storage Breakdown Card --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="hard-drive", size=18)#
					<span>Workspace Storage</span>
				</h2>
				<span class="badge badge-info">#variables.stats.mediaFormattedSize# / 500 MB</span>
			</div>
			<div class="card-body">
				<div style="margin-bottom:0.75rem; display:flex; justify-content:space-between; font-size:0.825rem;">
					<span style="color:var(--admin-text-muted);">Allocated Storage Used</span>
					<span style="font-weight:700; color:var(--admin-text-main);">#variables.stats.storagePercent#%</span>
				</div>
				<!--- Progress Bar --->
				<div style="width:100%; height:8px; background:var(--admin-border); border-radius:var(--radius-full); overflow:hidden; margin-bottom:1.25rem;">
					<div style="width:#variables.stats.storagePercent#%; height:100%; background:linear-gradient(90deg, var(--admin-primary), var(--admin-info)); border-radius:var(--radius-full);"></div>
				</div>

				<div style="display:flex; flex-direction:column; gap:0.75rem; font-size:0.825rem;">
					<div style="display:flex; justify-content:space-between; align-items:center;">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							<span style="width:10px; height:10px; border-radius:2px; background:var(--admin-primary);"></span>
							<span>Images (PNG, JPG, WebP)</span>
						</span>
						<span style="font-weight:600;">#variables.mediaBreakdown.imagesCount# files (#NumberFormat(variables.mediaBreakdown.imagesBytes / 1024, "0.0")# KB)</span>
					</div>
					<div style="display:flex; justify-content:space-between; align-items:center;">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							<span style="width:10px; height:10px; border-radius:2px; background:var(--admin-info);"></span>
							<span>Documents &amp; PDFs</span>
						</span>
						<span style="font-weight:600;">#variables.mediaBreakdown.docsCount# files (#NumberFormat(variables.mediaBreakdown.docsBytes / 1024, "0.0")# KB)</span>
					</div>
					<div style="display:flex; justify-content:space-between; align-items:center;">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							<span style="width:10px; height:10px; border-radius:2px; background:var(--admin-purple);"></span>
							<span>Other Assets &amp; Data</span>
						</span>
						<span style="font-weight:600;">#variables.mediaBreakdown.otherCount# files</span>
					</div>
				</div>
			</div>
			<div class="card-footer" style="display:flex; justify-content:space-between; align-items:center;">
				<a href="#urlFor(controller='media', action='upload', params=variables.hasWorkspace ? ('ws=' & variables.activeWorkspaceId) : '')#" class="btn btn-primary btn-sm" style="display:inline-flex; align-items:center; gap:0.35rem;">
					#svgIcon(name="upload", size=14)#
					<span>Upload Media</span>
				</a>
				<a href="#urlFor(controller='media', action='index', params=variables.hasWorkspace ? ('ws=' & variables.activeWorkspaceId) : '')#" class="btn btn-outline btn-sm">
					<span>Browse Media Library</span>
					#svgIcon(name="arrow-right", size=12)#
				</a>
			</div>
		</div>

		<!--- Online Forms & Citizen Engagement Card --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="clipboard-list", size=18)#
					<span>Online Forms &amp; Intake</span>
				</h2>
				<div class="card-tools">
					<a href="#urlFor(controller='forms', action='index')#" class="btn btn-secondary btn-sm">All Forms</a>
					<a href="#urlFor(controller='forms', action='builder')#" class="btn btn-primary btn-sm">
						#svgIcon(name="plus", size=14)#
						<span>New Form</span>
					</a>
				</div>
			</div>

			<cfif ArrayLen(variables.workspaceForms) gt 0>
				<div class="card-body" style="padding:0;">
					<div style="display:flex; flex-direction:column;">
						<cfloop array="#variables.workspaceForms#" index="local.frm">
							<div style="display:flex; align-items:center; justify-content:space-between; padding:0.85rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); gap:0.75rem; flex-wrap:wrap;">
								<div style="display:flex; align-items:center; gap:0.75rem; min-width:0; flex:1;">
									<div style="width:34px; height:34px; border-radius:var(--radius-md); background:var(--admin-purple-light); color:var(--admin-purple); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
										#svgIcon(name="form", size=16)#
									</div>
									<div style="min-width:0;">
										<div style="font-weight:600; font-size:0.875rem; color:var(--admin-text-main); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
											<a href="#urlFor(controller='forms', action='builder', params='id=' & local.frm.id)#" style="color:inherit; text-decoration:none;">
												#encodeForHTML(local.frm.title)#
											</a>
										</div>
										<div style="font-size:0.75rem; color:var(--admin-text-muted); display:flex; align-items:center; gap:0.4rem; margin-top:2px;">
											<span>/#encodeForHTML(local.frm.slug)#</span>
											<span>&bull;</span>
											<span>#NumberFormat(local.frm.submissionsCount, ",")# subs</span>
										</div>
									</div>
								</div>
								<div style="display:flex; align-items:center; gap:0.4rem; flex-shrink:0;">
									<cfif local.frm.pendingCount gt 0>
										<span class="badge badge-warning" style="font-size:0.7rem;">#local.frm.pendingCount# New</span>
									<cfelse>
										#statusBadge(local.frm.status)#
									</cfif>
									<a href="#urlFor(controller='forms', action='builder', params='id=' & local.frm.id)#" class="btn btn-outline btn-xs" title="Edit in Form Builder">
										#svgIcon(name="edit", size=12)#
										<span>Build</span>
									</a>
									<a href="#urlFor(route='formPreview', params='id=' & local.frm.id)#" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-xs btn-icon-only" title="Preview Public Form">
										#svgIcon(name="eye", size=12)#
									</a>
								</div>
							</div>
						</cfloop>
					</div>
				</div>
			<cfelse>
				<div class="card-body" style="text-align:center; padding:2.5rem 1.5rem;">
					<div style="width:40px; height:40px; border-radius:50%; background:var(--admin-purple-light); color:var(--admin-purple); display:flex; align-items:center; justify-content:center; margin:0 auto 0.75rem auto;">
						#svgIcon(name="clipboard-list", size=20)#
					</div>
					<h3 style="font-size:0.95rem; font-weight:600; margin:0 0 0.35rem 0;">No active online forms for this workspace</h3>
					<p style="font-size:0.825rem; color:var(--admin-text-muted); margin:0 auto 1rem auto; max-width:380px;">
						Build custom intake workflows, permit requests, citizen inquiries, or service applications using the visual Form Builder.
					</p>
					<a href="#urlFor(controller='forms', action='builder')#" class="btn btn-primary btn-sm">
						#svgIcon(name="plus", size=14)#
						<span>Open Form Builder</span>
					</a>
				</div>
			</cfif>
		</div>

		<!--- Quick Action Hub Card --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="sparkles", size=18)#
					<span>Quick Actions</span>
				</h2>
			</div>
			<div class="card-body" style="padding:1rem;">
				<div style="display:grid; grid-template-columns: 1fr 1fr; gap:0.75rem;">
					<button type="button" class="btn btn-outline btn-sm" id="btnQuickActionAddPage" style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding:0.85rem 0.5rem; height:auto; text-align:center; gap:0.35rem;" onclick="openAddPageModal();">
						<span style="color:var(--admin-primary);">#svgIcon(name="plus", size=20)#</span>
						<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-main);">Add New Page</span>
					</button>

					<a href="#urlFor(controller='media', action='upload', params=variables.hasWorkspace ? ('ws=' & variables.activeWorkspaceId) : '')#" class="btn btn-outline btn-sm" style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding:0.85rem 0.5rem; height:auto; text-align:center; gap:0.35rem; text-decoration:none;">
						<span style="color:var(--admin-info);">#svgIcon(name="upload-cloud", size=20)#</span>
						<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-main);">Upload Media</span>
					</a>

					<a href="#urlFor(controller='forms', action='builder')#" class="btn btn-outline btn-sm" style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding:0.85rem 0.5rem; height:auto; text-align:center; gap:0.35rem; text-decoration:none;">
						<span style="color:var(--admin-purple);">#svgIcon(name="clipboard-list", size=20)#</span>
						<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-main);">Create Form</span>
					</a>

					<a href="#urlFor(controller='pages', action='folderExplorer')#" class="btn btn-outline btn-sm" style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding:0.85rem 0.5rem; height:auto; text-align:center; gap:0.35rem; text-decoration:none;">
						<span style="color:var(--admin-warning);">#svgIcon(name="folder", size=20)#</span>
						<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-main);">Folder Explorer</span>
					</a>

					<a href="#urlFor(controller='pages', action='index', params=variables.hasWorkspace ? ('ws=' & variables.activeWorkspaceId) : '')#" class="btn btn-outline btn-sm" style="display:flex; align-items:center; justify-content:center; padding:0.75rem 0.5rem; height:auto; text-align:center; gap:0.5rem; text-decoration:none; grid-column: span 2;">
						<span style="color:var(--admin-primary);">#svgIcon(name="file-text", size=18)#</span>
						<span style="font-size:0.85rem; font-weight:600; color:var(--admin-text-main);">Page Editor</span>
					</a>
				</div>
			</div>
		</div>

		<!--- Recent Activity Feed --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					#svgIcon(name="activity", size=18)#
					<span>Recent Editorial Activity</span>
				</h2>
			</div>
			<div class="card-body" style="padding-top:1rem; padding-bottom:1rem;">
				<cfif ArrayLen(variables.recentActivities) gt 0>
					<div style="display:flex; flex-direction:column; gap:1.25rem;">
						<cfloop array="#variables.recentActivities#" index="local.act">
							<div style="display:flex; gap:0.75rem;">
								<div style="width:32px; height:32px; border-radius:50%; display:flex; align-items:center; justify-content:center; flex-shrink:0;" class="#local.act.colorClass#">
									#svgIcon(name=local.act.icon, size=15)#
								</div>
								<div>
									<div style="font-size:0.85rem; font-weight:600; color:var(--admin-text-main);">
										<a href="#local.act.link#" style="color:inherit; text-decoration:none;">
											#encodeForHTML(local.act.title)#
										</a>
									</div>
									<div style="font-size:0.775rem; color:var(--admin-text-muted);">
										#encodeForHTML(local.act.subtitle)#
									</div>
									<div style="font-size:0.725rem; color:var(--admin-text-subtle); margin-top:2px;">
										#encodeForHTML(local.act.time)#
									</div>
								</div>
							</div>
						</cfloop>
					</div>
				<cfelse>
					<div style="text-align:center; padding:1.5rem 0; color:var(--admin-text-muted); font-size:0.85rem;">
						No recent editorial activity recorded in this workspace.
					</div>
				</cfif>
			</div>
		</div>

</div>

<!--- Add Page Modal Dialog (WCAG 2.1/2.2 AA Compliant) --->
<div id="addPageModalBackdrop" class="admin-modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="addPageModalTitle" aria-describedby="addPageModalDesc" data-server-active-ws="#encodeForHTMLAttribute(variables.activeWorkspaceId)#" style="display:none;">
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
					<input type="hidden" id="modalWorkspaceSelect" value="#encodeForHTML(variables.activeWorkspaceId)#">

					<!--- 1. Page Title --->
					<div>
						<label for="modalPageTitle" class="form-label" style="font-weight:600;">
							Page Title <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<input type="text" id="modalPageTitle" name="modalPageTitle" class="form-control" placeholder="e.g., Parks &amp; Recreation Guide" required aria-required="true" style="width:100%; font-size:0.95rem; padding:0.6rem 0.75rem;" autocomplete="off">
						<div id="modalTitleError" class="form-help-text" style="color:var(--admin-danger); display:none; margin-top:0.35rem; font-size:0.8rem; font-weight:600;" role="alert">
							Please enter a page title.
						</div>
					</div>

					<!--- 2. Page URL / Slug --->
					<div>
						<label for="modalPageSlug" class="form-label" style="font-weight:600;">
							Page URL <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<div class="pg-slug-wrap" style="display:flex; align-items:center; border:1.5px solid var(--admin-border-input); border-radius:var(--radius-md); overflow:hidden; background:var(--admin-surface);">
							<span id="modalUrlPrefix" style="padding:0.6rem 0.75rem; background:var(--admin-bg); color:var(--admin-text-muted); font-size:0.825rem; border-right:1px solid var(--admin-border); white-space:nowrap; user-select:none;">/#encodeForHTML(variables.hasWorkspace ? variables.activeWorkspaceId : 'shared')#/</span>
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

					<!--- 3. Page Layout (Iconized Choices) --->
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
/* Dashboard Controllers: Add Page Modal & Quick Subpage Modal */
(function () {
	// ==========================================
	// 1. ADD PAGE MODAL CONTROLLER (3 Entries -> Save DB -> Redirect to Edit Mode)
	// ==========================================
	var addPageModal = document.getElementById("addPageModalBackdrop");
	var btnCloseAddPage = document.getElementById("btnCloseAddPageModal");
	var btnCancelAddPage = document.getElementById("btnCancelAddPage");
	var btnContinueAddPage = document.getElementById("btnContinueAddPage");
	var titleInput = document.getElementById("modalPageTitle");
	var slugInput = document.getElementById("modalPageSlug");
	var titleError = document.getElementById("modalTitleError");
	var slugError = document.getElementById("modalSlugError");
	var urlPrefixEl = document.getElementById("modalUrlPrefix");
	var layoutHidden = document.getElementById("modalSelectedLayout");
	var layoutCards = document.querySelectorAll("#addPageModalBackdrop .layout-choice-card");
	var btnCopyUrl = document.getElementById("btnCopyModalUrl");

	var lastActiveElement = null;
	var slugManuallyEdited = false;

	function getActiveWorkspaceId() {
		var activeWs = "";
		try {
			var wsSelect = document.getElementById("modalWorkspaceSelect");
			if (wsSelect && wsSelect.value) {
				var val = wsSelect.value.trim();
				if (val && val !== "global" && val !== "all") return val;
			}

			var activeItem = document.querySelector(".workspace-item.is-active");
			if (activeItem && activeItem.getAttribute("data-ws-id")) {
				activeWs = activeItem.getAttribute("data-ws-id").trim();
			}

			if (!activeWs || activeWs === "global" || activeWs === "all") {
				var wsContainer = document.getElementById("workspaceDropdownContainer");
				if (wsContainer && wsContainer.getAttribute("data-active-ws-id")) {
					activeWs = wsContainer.getAttribute("data-active-ws-id").trim();
				}
			}

			if (!activeWs || activeWs === "global" || activeWs === "all") {
				var serverWs = (addPageModal && addPageModal.getAttribute("data-server-active-ws")) ? addPageModal.getAttribute("data-server-active-ws").trim() : "";
				if (serverWs && serverWs !== "global" && serverWs !== "all") {
					activeWs = serverWs;
				}
			}

			if (!activeWs || activeWs === "global" || activeWs === "all") {
				var match = document.cookie.match(/(?:^|;\s*)cmsadmin_workspace=([^;]+)/);
				if (match && match[1]) {
					activeWs = decodeURIComponent(match[1]).trim();
				}
			}

			if (!activeWs || activeWs === "global" || activeWs === "all") {
				var saved = localStorage.getItem("cmsadmin_active_workspace");
				if (saved) {
					var parsed = JSON.parse(saved);
					if (parsed && parsed.id) activeWs = parsed.id.trim();
				}
			}
		} catch (e) {}
		if (activeWs === "global" || activeWs === "all") activeWs = "";
		return activeWs;
	}

	function slugify(text) {
		return text.toString().toLowerCase()
			.replace(/\s+/g, "-")
			.replace(/[^a-z0-9\-]/g, "")
			.replace(/\-{2,}/g, "-")
			.replace(/^-+/, "")
			.replace(/-+$/, "");
	}

	function updateUrlPrefix() {
		if (!urlPrefixEl) return;
		var ws = "";
		var wsSelect = document.getElementById("modalWorkspaceSelect");
		if (wsSelect && wsSelect.value) {
			ws = wsSelect.value.trim();
		} else {
			ws = getActiveWorkspaceId();
		}
		urlPrefixEl.textContent = "/" + (ws && ws !== "global" && ws !== "all" ? ws : "pages") + "/";
	}

	function selectLayout(layoutName) {
		if (layoutHidden) layoutHidden.value = layoutName;
		layoutCards.forEach(function (card) {
			var isMatch = card.getAttribute("data-layout") === layoutName;
			card.classList.toggle("is-selected", isMatch);
			card.setAttribute("aria-checked", isMatch ? "true" : "false");
			card.tabIndex = isMatch ? 0 : -1;
		});
	}

	// Move modal to document.body to ensure it overlays the full viewport without container clipping
	if (addPageModal && addPageModal.parentNode !== document.body) {
		document.body.appendChild(addPageModal);
	}

	var modalWsEl = document.getElementById("modalWorkspaceSelect");
	if (modalWsEl && modalWsEl.tagName === "SELECT") {
		modalWsEl.addEventListener("change", function () {
			var wsErr = document.getElementById("modalWorkspaceError");
			if (wsErr) wsErr.style.display = "none";
			updateUrlPrefix();
		});
	}

	window.openAddPageModal = function () {
		var curWs = getActiveWorkspaceId();
		if (!curWs || curWs === "global" || curWs === "all") {
			if (typeof window.adminAlert === "function") {
				window.adminAlert({
					title: "Workspace Required",
					message: "Please select a workspace from the header dropdown before creating a page.",
					type: "warning"
				});
			}
			return;
		}

		if (addPageModal && addPageModal.parentNode !== document.body) {
			document.body.appendChild(addPageModal);
		}

		lastActiveElement = document.activeElement;
		addPageModal.style.display = "flex";
		document.body.style.overflow = "hidden";
		void addPageModal.offsetWidth;
		addPageModal.classList.add("open");
		addPageModal.setAttribute("aria-hidden", "false");

		titleError.style.display = "none";
		slugError.style.display = "none";
		var wsErr = document.getElementById("modalWorkspaceError");
		if (wsErr) wsErr.style.display = "none";

		titleInput.value = "";
		slugInput.value = "";
		slugManuallyEdited = false;

		var wsSelect = document.getElementById("modalWorkspaceSelect");
		if (wsSelect && wsSelect.tagName === "SELECT") {
			wsSelect.value = curWs;
		}

		updateUrlPrefix();
		btnContinueAddPage.disabled = false;
		btnContinueAddPage.innerHTML = '<span>Continue to Editor</span><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="margin-left:4px;"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>';
		selectLayout("Right Sidebar");

		setTimeout(function () {
			titleInput.focus();
		}, 50);
	};

	function closeAddPageModal() {
		addPageModal.classList.remove("open");
		addPageModal.setAttribute("aria-hidden", "true");
		document.body.style.overflow = "";
		setTimeout(function () {
			addPageModal.style.display = "none";
			if (lastActiveElement && typeof lastActiveElement.focus === "function") {
				lastActiveElement.focus();
			}
		}, 150);
	}

	if (btnCloseAddPage) btnCloseAddPage.addEventListener("click", closeAddPageModal);
	if (btnCancelAddPage) btnCancelAddPage.addEventListener("click", closeAddPageModal);

	if (addPageModal) {
		addPageModal.addEventListener("click", function (e) {
			if (e.target === addPageModal) closeAddPageModal();
		});
		document.addEventListener("keydown", function (e) {
			if (e.key === "Escape" && addPageModal.classList.contains("open")) {
				closeAddPageModal();
			}
		});
	}

	if (titleInput) {
		titleInput.addEventListener("input", function () {
			titleError.style.display = "none";
			if (!slugManuallyEdited) {
				slugInput.value = slugify(titleInput.value);
			}
		});
	}

	if (slugInput) {
		slugInput.addEventListener("input", function () {
			slugError.style.display = "none";
			slugManuallyEdited = true;
			slugInput.value = slugInput.value.toLowerCase().replace(/[^a-z0-9\-]/g, "");
		});
	}

	if (btnCopyUrl) {
		btnCopyUrl.addEventListener("click", function () {
			var full = window.location.origin + (urlPrefixEl ? urlPrefixEl.textContent : "/") + slugInput.value;
			navigator.clipboard.writeText(full).then(function () {
				if (typeof window.showToast === "function") window.showToast("URL copied to clipboard", "info");
			});
		});
	}

	layoutCards.forEach(function (card) {
		card.addEventListener("click", function () {
			selectLayout(card.getAttribute("data-layout"));
		});
		card.addEventListener("keydown", function (e) {
			if (e.key === " " || e.key === "Enter") {
				e.preventDefault();
				selectLayout(card.getAttribute("data-layout"));
			}
		});
	});

	if (btnContinueAddPage) {
		btnContinueAddPage.addEventListener("click", function () {
			var titleVal = titleInput.value.trim();
			var slugVal = slugInput.value.trim();
			var layoutVal = layoutHidden ? layoutHidden.value : "Right Sidebar";

			var selectedWs = "";
			var wsSelectEl = document.getElementById("modalWorkspaceSelect");
			if (wsSelectEl) {
				selectedWs = wsSelectEl.value.trim();
			}
			if (!selectedWs) {
				selectedWs = getActiveWorkspaceId();
			}

			if (wsSelectEl && wsSelectEl.tagName === "SELECT" && (!selectedWs || selectedWs === "global" || selectedWs === "all")) {
				var wsErr = document.getElementById("modalWorkspaceError");
				if (wsErr) {
					wsErr.textContent = "Please choose a workspace for the new page.";
					wsErr.style.display = "block";
				}
				wsSelectEl.focus();
				return;
			}

			if (!titleVal) {
				titleError.textContent = "Page title is required.";
				titleError.style.display = "block";
				titleInput.focus();
				return;
			}

			if (titleVal && !slugVal) {
				slugVal = slugify(titleVal);
			}

			btnContinueAddPage.disabled = true;
			btnContinueAddPage.innerHTML = '<span class="admin-spinner-sm" style="margin-right:6px;" aria-hidden="true"></span> <span>Saving &amp; Opening Editor...</span>';

			if (typeof window.showPageLoader === "function") {
				window.showPageLoader(
					"Creating &amp; Saving Page...",
					"Saving “" + titleVal + "” into database and opening in Edit mode..."
				);
			}

			var csrfMeta = document.querySelector('meta[name="csrf-token"]');
			var headers = {
				"Content-Type": "application/json; charset=utf-8",
				"Accept": "application/json",
				"X-Requested-With": "XMLHttpRequest"
			};
			if (csrfMeta && csrfMeta.getAttribute("content")) {
				headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
			}

			fetch("/pages/create-modal", {
				method: "POST",
				credentials: "same-origin",
				headers: headers,
				body: JSON.stringify({
					title: titleVal,
					slug: slugVal,
					layout: layoutVal,
					siteId: selectedWs
				})
			})
			.then(function (res) {
				return res.text().then(function (text) {
					var data;
					try { data = JSON.parse(text); } catch (e) {
						throw new Error("Invalid response from server (HTTP " + res.status + ").");
					}
					if (!res.ok) {
						var msg = (data && (data.message || data.MESSAGE)) || ("Server error (HTTP " + res.status + ").");
						throw new Error(msg);
					}
					return data;
				});
			})
			.then(function (data) {
				var isSuccess = (data && (data.success === true || data.SUCCESS === true));
				var newId = parseInt((data && (data.id || data.ID || data.newId)), 10) || 0;
				var redirectUrl = (data && (data.redirectUrl || data.REDIRECTURL));

				if (isSuccess && newId > 0) {
					closeAddPageModal();
					var targetUrl = redirectUrl || ("/pages/edit?id=" + encodeURIComponent(newId) + "&created=1");
					window.location.href = targetUrl;
				} else {
					throw new Error((data && data.message) || "Failed to create page in database.");
				}
			})
			.catch(function (err) {
				if (typeof window.hidePageLoader === "function") {
					window.hidePageLoader();
				}
				btnContinueAddPage.disabled = false;
				btnContinueAddPage.innerHTML = '<span>Continue to Editor</span><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="margin-left:4px;"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>';
				titleError.textContent = err.message || "Error creating page. Please try again.";
				titleError.style.display = "block";
				if (typeof window.adminAlert === "function") {
					window.adminAlert(err.message || "Unable to save page. Please try again.", { title: "Error Creating Page" });
				}
			});
		});
	}

})();
</script>
