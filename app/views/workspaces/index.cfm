<cfparam name="variables.workspaces" default="#[]#">
<cfparam name="variables.metrics" default="#{}#">
<cfparam name="variables.activeFilterType" default="all">
<cfparam name="variables.activeSearchQuery" default="">
<cfparam name="variables.currentActiveWs" default="global">

<style>
	.ws-card-kpi {
		padding: 1.15rem;
		background: var(--admin-surface);
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		box-shadow: var(--shadow-sm);
	}
	.ws-kpi-icon {
		width: 42px;
		height: 42px;
		border-radius: var(--radius-md);
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.ws-filter-tab {
		padding: 0.35rem 0.85rem;
		font-size: 0.8rem;
		font-weight: 600;
		text-decoration: none;
		border-radius: var(--radius-sm);
		color: var(--admin-text-muted);
		background: transparent;
		transition: all 0.15s ease;
	}
	.ws-filter-tab:hover {
		color: var(--admin-text-main);
	}
	.ws-filter-tab.active {
		color: #ffffff;
		background: var(--admin-primary);
	}
	.ws-table-main tr.ws-row-item:hover {
		background: var(--admin-surface-hover) !important;
	}
	.ws-details-drawer {
		background: #f8fafc;
		padding: 1.25rem 1.5rem;
		border-top: 1px dashed var(--admin-border);
		border-bottom: 2px solid var(--admin-border);
	}
	.ws-details-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
		gap: 1.25rem;
	}
	.ws-detail-card {
		background: #ffffff;
		border: 1px solid var(--admin-border);
		border-radius: var(--radius-md);
		padding: 1rem 1.25rem;
		box-shadow: 0 1px 3px rgba(0,0,0,0.04);
	}
	.ws-detail-card-title {
		font-size: 0.75rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		color: var(--admin-primary);
		margin-bottom: 0.75rem;
		display: flex;
		align-items: center;
		gap: 0.45rem;
		border-bottom: 2px solid #f97316;
		padding-bottom: 0.35rem;
	}
	.ws-detail-row {
		display: flex;
		justify-content: space-between;
		font-size: 0.8rem;
		margin-bottom: 0.45rem;
		gap: 0.5rem;
	}
	.ws-detail-label {
		color: var(--admin-text-muted);
		font-weight: 600;
		flex-shrink: 0;
	}
	.ws-detail-val {
		color: var(--admin-text-main);
		text-align: right;
		word-break: break-word;
	}

	/* Live Mega-Menu & Directory Preview Modal */
	.ws-modal-backdrop {
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
	.ws-modal-backdrop.is-open {
		display: flex;
	}
	.ws-modal-dialog {
		background: var(--admin-surface, #ffffff);
		border: 1px solid var(--admin-border, #cbd5e1);
		border-radius: var(--radius-lg, 0.75rem);
		box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.45);
		width: 100%;
		max-width: 1080px;
		max-height: 90vh;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	.ws-modal-header {
		padding: 1.1rem 1.4rem;
		border-bottom: 1px solid var(--admin-border-subtle, #e2e8f0);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		flex-wrap: wrap;
		background: var(--admin-bg, #f8fafc);
	}
	.ws-modal-title {
		margin: 0;
		font-size: 1.02rem;
		font-weight: 800;
		letter-spacing: 0.02em;
		text-transform: uppercase;
		color: var(--admin-text-main, #0f172a);
		display: flex;
		align-items: center;
		gap: 0.55rem;
	}
	.ws-modal-body {
		padding: 1.35rem 1.4rem;
		overflow-y: auto;
		flex: 1;
	}
	.ws-modal-footer {
		padding: 0.9rem 1.4rem;
		border-top: 1px solid var(--admin-border-subtle, #e2e8f0);
		background: var(--admin-bg, #f8fafc);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.65rem;
		flex-wrap: wrap;
	}
	.ws-preview-mega-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
		gap: 1.25rem;
		padding: 1.25rem;
		background: #f8fafc;
		border: 1px solid #cbd5e1;
		border-radius: 0.5rem;
	}
	.ws-preview-mega-col h4 {
		font-size: 0.92rem;
		font-weight: 700;
		color: #0f172a;
		margin: 0 0 0.55rem 0;
		padding-bottom: 0.35rem;
		border-bottom: 2px solid #0073aa;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.4rem;
	}
	.ws-preview-mega-col ul {
		list-style: disc;
		margin: 0;
		padding-left: 1.15rem;
	}
	.ws-preview-mega-col li {
		margin-bottom: 0.38rem;
		font-size: 0.84rem;
		line-height: 1.4;
	}
	.ws-preview-mega-col a {
		color: #0073aa;
		text-decoration: none;
		font-weight: 600;
	}
	.ws-preview-mega-col a:hover {
		text-decoration: underline;
	}
</style>

<cfoutput>
<div class="container-fluid" style="padding: 1.5rem 0;">
	<!--- Page Header --->
	<div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:1.5rem; flex-wrap:wrap; gap:1rem;">
		<div>
			<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.25rem;">
				<h1 style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); margin:0;">Workspaces &amp; Portals</h1>
				<span class="badge badge-danger" style="font-size:0.75rem; padding:0.2rem 0.55rem;">Admin Only</span>
			</div>
			<p style="color:var(--admin-text-muted); font-size:0.875rem; margin:0;">
				Manage the #StructKeyExists(variables.metrics, "total") ? variables.metrics.total : 16# municipal department workspaces, public web portals, filesystem directories, and staff scoping.
			</p>
		</div>
		<div style="display:flex; gap:0.5rem; align-items:center; flex-wrap:wrap;">
			<button type="button" class="btn btn-outline-secondary btn-sm" id="btnOpenWorkspaceMegaMenuPreview" style="display:inline-flex; align-items:center; gap:0.4rem;">
				#svgIcon(name="eye", size=15)#
				<span>Mega Menu Preview</span>
			</button>
			<a href="#urlFor(controller='workspaces', action='new')#" class="btn btn-primary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
				#svgIcon(name="plus", size=15)#
				<span>Add New Workspace</span>
			</a>
			<a href="#urlFor(controller='users', action='index')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
				#svgIcon(name="users", size=15)#
				<span>Manage Users</span>
			</a>
			<a href="#urlFor(controller='users', action='roles')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
				#svgIcon(name="shield", size=15)#
				<span>Permissions Matrix</span>
			</a>
		</div>
	</div>

	<!--- KPI Metric Cards --->
	<div class="row" style="display:grid; grid-template-columns:repeat(auto-fit, minmax(220px, 1fr)); gap:1rem; margin-bottom:1.5rem;">
		<div class="ws-card-kpi">
			<div style="display:flex; justify-content:space-between; align-items:center;">
				<div>
					<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Total Workspaces</div>
					<div style="font-size:1.75rem; font-weight:800; color:var(--admin-text-main); line-height:1.2; margin-top:0.25rem;">#StructKeyExists(variables.metrics, "total") ? variables.metrics.total : 1#</div>
				</div>
				<div class="ws-kpi-icon" style="background:rgba(0,115,170,0.1); color:var(--admin-primary);">
					#svgIcon(name="grid", size=22)#
				</div>
			</div>
			<div style="margin-top:0.5rem; font-size:0.75rem; color:var(--admin-text-muted);">
				#StructKeyExists(variables.metrics, "global") ? variables.metrics.global : 1# Global &bull; #StructKeyExists(variables.metrics, "dept") ? variables.metrics.dept : 0# Depts &bull; #StructKeyExists(variables.metrics, "site") ? variables.metrics.site : 0# Portals
			</div>
		</div>

		<div class="ws-card-kpi">
			<div style="display:flex; justify-content:space-between; align-items:center;">
				<div>
					<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Municipal Departments</div>
					<div style="font-size:1.75rem; font-weight:800; color:var(--admin-text-main); line-height:1.2; margin-top:0.25rem;">#StructKeyExists(variables.metrics, "dept") ? variables.metrics.dept : 0#</div>
				</div>
				<div class="ws-kpi-icon" style="background:rgba(126,34,206,0.1); color:var(--admin-purple, ##7e22ce);">
					#svgIcon(name="building", size=22)#
				</div>
			</div>
			<div style="margin-top:0.5rem; font-size:0.75rem; color:var(--admin-text-muted);">
				County divisions &amp; elected offices
			</div>
		</div>

		<div class="ws-card-kpi">
			<div style="display:flex; justify-content:space-between; align-items:center;">
				<div>
					<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Public Web Portals</div>
					<div style="font-size:1.75rem; font-weight:800; color:var(--admin-text-main); line-height:1.2; margin-top:0.25rem;">#StructKeyExists(variables.metrics, "site") ? variables.metrics.site : 0#</div>
				</div>
				<div class="ws-kpi-icon" style="background:rgba(16,185,129,0.1); color:var(--admin-success, ##10b981);">
					#svgIcon(name="globe", size=22)#
				</div>
			</div>
			<div style="margin-top:0.5rem; font-size:0.75rem; color:var(--admin-text-muted);">
				e.g., parks, gis, expo, portals
			</div>
		</div>

		<div class="ws-card-kpi">
			<div style="display:flex; justify-content:space-between; align-items:center;">
				<div>
					<div style="font-size:0.75rem; text-transform:uppercase; font-weight:700; color:var(--admin-text-muted); letter-spacing:0.04em;">Active RBAC Scoping</div>
					<div style="font-size:1.15rem; font-weight:800; color:var(--admin-danger); line-height:1.2; margin-top:0.45rem;">Admin Exclusive</div>
				</div>
				<div class="ws-kpi-icon" style="background:rgba(239,68,68,0.1); color:var(--admin-danger);">
					#svgIcon(name="shield", size=22)#
				</div>
			</div>
			<div style="margin-top:0.5rem; font-size:0.75rem; color:var(--admin-text-muted);">
				Non-admins see assigned only
			</div>
		</div>
	</div>

	<!--- Filter Toolbar --->
	<div class="card" style="margin-bottom:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
		<div style="padding:1rem 1.25rem; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:1rem;">
			<!--- Filter Tabs --->
			<div style="display:inline-flex; background:var(--admin-surface-hover); padding:0.25rem; border-radius:var(--radius-md); border:1px solid var(--admin-border);">
				<a href="#urlFor(controller='workspaces', action='index', params='type=all#(len(variables.activeSearchQuery) ? '&q=' & variables.activeSearchQuery : '')#')#"
				   class="ws-filter-tab #(variables.activeFilterType eq 'all' ? 'active' : '')#">
					All Workspaces (#StructKeyExists(variables.metrics, "total") ? variables.metrics.total : 16#)
				</a>
				<a href="#urlFor(controller='workspaces', action='index', params='type=dept#(len(variables.activeSearchQuery) ? '&q=' & variables.activeSearchQuery : '')#')#"
				   class="ws-filter-tab #(variables.activeFilterType eq 'dept' ? 'active' : '')#" style="display:inline-flex; align-items:center; gap:0.35rem;">
					#svgIcon(name="building", size=13)#
					<span>Departments (#StructKeyExists(variables.metrics, "dept") ? variables.metrics.dept : 11#)</span>
				</a>
				<a href="#urlFor(controller='workspaces', action='index', params='type=site#(len(variables.activeSearchQuery) ? '&q=' & variables.activeSearchQuery : '')#')#"
				   class="ws-filter-tab #(variables.activeFilterType eq 'site' ? 'active' : '')#" style="display:inline-flex; align-items:center; gap:0.35rem;">
					#svgIcon(name="globe", size=13)#
					<span>Sites &amp; Portals (#StructKeyExists(variables.metrics, "site") ? variables.metrics.site : 4#)</span>
				</a>
			</div>

			<!--- Search & Toggle Controls --->
			<div style="display:flex; gap:0.5rem; align-items:center; flex-wrap:wrap;">
				<button type="button" class="btn btn-outline-secondary btn-sm" id="btnToggleAllDetails" style="font-size:0.8rem; display:inline-flex; align-items:center; gap:0.35rem;">
					#svgIcon(name="grid", size=13)#
					<span id="btnToggleAllText">Expand All Details</span>
				</button>

				<form action="#urlFor(controller='workspaces', action='index')#" method="get" style="display:flex; gap:0.5rem; align-items:center; margin:0;">
					<input type="hidden" name="type" value="#EncodeForHTMLAttribute(variables.activeFilterType)#">
					<div style="position:relative; width:280px;">
						<span style="position:absolute; left:0.75rem; top:50%; transform:translateY(-50%); color:var(--admin-text-muted); pointer-events:none;">
							#svgIcon(name="search", size=14)#
						</span>
						<input type="text" name="q" value="#EncodeForHTMLAttribute(variables.activeSearchQuery)#" class="form-control" placeholder="Search name, code, contact..." style="padding-left:2.2rem; font-size:0.825rem;">
					</div>
					<button type="submit" class="btn btn-secondary btn-sm" style="font-size:0.825rem;">Search</button>
					<cfif len(variables.activeSearchQuery)>
						<a href="#urlFor(controller='workspaces', action='index', params='type=' & variables.activeFilterType)#" class="btn btn-outline-secondary btn-sm" title="Clear Search">#svgIcon(name="x", size=14)#</a>
					</cfif>
				</form>
			</div>
		</div>
	</div>

	<!--- Clean Slate Onboarding Alert (When only system root workspace exists) --->
	<cfif variables.metrics.total lte 1 and variables.activeFilterType eq "all" and !len(variables.activeSearchQuery)>
		<div class="alert alert-info" style="display:flex; align-items:flex-start; gap:0.85rem; margin-bottom:1.5rem; background:rgba(0,115,170,0.06); border:1px solid rgba(0,115,170,0.22); border-radius:8px; padding:1.1rem 1.25rem;">
			<div style="color:var(--admin-primary); margin-top:2px;">#svgIcon(name="info", size=22)#</div>
			<div style="flex:1;">
				<div style="font-weight:700; font-size:0.95rem; color:var(--admin-text-main); margin-bottom:0.25rem;">Clean Slate: Database Connected</div>
				<div style="font-size:0.84rem; color:var(--admin-text-muted); line-height:1.45;">
					Test mock data has been removed and your workspaces table (<code>cms_workspaces</code>) is active on SQL Server. Currently, only the root system scope (<strong>Global Overview</strong>) is registered. Ready to add municipal departments and public web portals? Click <strong>Create Workspace</strong> to provision your first live department.
				</div>
			</div>
			<div>
				<a href="#urlFor(controller='workspaces', action='new')#" class="btn btn-primary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem; font-weight:600; padding:0.4rem 0.85rem; white-space:nowrap;">
					#svgIcon(name="plus", size=14)#
					<span>Create Workspace</span>
				</a>
			</div>
		</div>
	</cfif>

	<!--- Workspaces Table --->
	<div class="card" style="border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-surface); box-shadow:var(--shadow-sm); overflow:hidden;">
		<div style="overflow-x:auto;">
			<table class="table ws-table-main" style="width:100%; border-collapse:collapse; font-size:0.85rem; margin:0;">
				<thead>
					<tr style="background:var(--admin-surface-hover); border-bottom:1px solid var(--admin-border); text-align:left;">
						<th style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-muted); font-size:0.75rem; text-transform:uppercase; min-width:230px;">Site / Workspace Name</th>
						<th style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-muted); font-size:0.75rem; text-transform:uppercase; min-width:160px;">Virtual Directory</th>
						<th style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-muted); font-size:0.75rem; text-transform:uppercase; min-width:180px;">Department &amp; Category</th>
						<th style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-muted); font-size:0.75rem; text-transform:uppercase; min-width:190px;">Contact Information</th>
						<th style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-muted); font-size:0.75rem; text-transform:uppercase; min-width:180px;">Office &amp; Hours</th>
						<th style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-muted); font-size:0.75rem; text-transform:uppercase; min-width:90px;">Staff</th>
						<th style="padding:0.75rem 1rem; font-weight:700; color:var(--admin-text-muted); font-size:0.75rem; text-transform:uppercase; text-align:right; min-width:180px;">Actions</th>
					</tr>
				</thead>
				<tbody>
					<cfif ArrayLen(variables.workspaces) eq 0>
						<tr>
							<td colspan="7" style="padding:3.5rem 1.5rem; text-align:center; color:var(--admin-text-muted);">
								<div style="margin-bottom:0.75rem; color:var(--admin-text-muted); opacity:0.6;">
									#svgIcon(name="grid", size=44)#
								</div>
								<div style="font-size:1.05rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.35rem;">No Workspaces Found</div>
								<div style="font-size:0.85rem; max-width:420px; margin:0 auto 1.25rem auto; line-height:1.4;">
									<cfif len(variables.activeSearchQuery) or variables.activeFilterType neq "all">
										No workspaces matched your current filter criteria. Try clearing your search query or filter.
									<cfelse>
										No custom workspaces have been added yet. Start by provisioning a municipal department or portal.
									</cfif>
								</div>
								<cfif len(variables.activeSearchQuery) or variables.activeFilterType neq "all">
									<a href="#urlFor(controller='workspaces', action='index')#" class="btn btn-outline-secondary btn-sm" style="font-size:0.8rem; padding:0.35rem 0.85rem;">Clear Filters</a>
								<cfelse>
									<a href="#urlFor(controller='workspaces', action='new')#" class="btn btn-primary btn-sm" style="font-size:0.8rem; padding:0.35rem 0.85rem;">
										#svgIcon(name="plus", size=13)#
										<span>Create First Workspace</span>
									</a>
								</cfif>
							</td>
						</tr>
					</cfif>
					<cfloop array="#variables.workspaces#" index="local.w">
						<cfset isCurrentActive = (variables.currentActiveWs eq local.w.id or (variables.currentActiveWs eq 'all' and local.w.id eq 'global'))>
						
						<!--- Extract contact details --->
						<cfset local.contactFirst = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "first_name")) ? local.w.contact.first_name : "">
						<cfset local.contactLast = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "last_name")) ? local.w.contact.last_name : "">
						<cfset local.contactFullName = Trim(local.contactFirst & " " & local.contactLast)>
						<cfset local.contactEmail = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "email")) ? local.w.contact.email : "">
						<cfset local.contactPhone = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "phone")) ? local.w.contact.phone : "">
						<cfset local.contactFax = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "fax")) ? local.w.contact.fax : "">
						<cfset local.contactAddr = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "address")) ? local.w.contact.address : "">
						<cfset local.contactAddr2 = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "address2")) ? local.w.contact.address2 : "">
						<cfset local.contactCity = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "city") and Len(local.w.contact.city)) ? local.w.contact.city : "Wenatchee">
						<cfset local.contactState = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "state") and Len(local.w.contact.state)) ? local.w.contact.state : "WA">
						<cfset local.contactZip = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "zip") and Len(local.w.contact.zip)) ? local.w.contact.zip : "98801">
						<cfset local.contactHours = (StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "office_hours")) ? local.w.contact.office_hours : "">
						<cfset local.leadershipType = (StructKeyExists(local.w, "leadership_type") and Len(local.w.leadership_type)) ? local.w.leadership_type : "dept_head">
						<cfset local.jobTitle = (StructKeyExists(local.w, "job_title") and Len(local.w.job_title)) ? local.w.job_title : ((StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "job_title") and Len(local.w.contact.job_title)) ? local.w.contact.job_title : "")>
						<cfset local.contactPhoto = (StructKeyExists(local.w, "contact_photo") and Len(local.w.contact_photo)) ? local.w.contact_photo : ((StructKeyExists(local.w, "contact") and IsStruct(local.w.contact) and StructKeyExists(local.w.contact, "photo") and Len(local.w.contact.photo)) ? local.w.contact.photo : "")>
						
						<cfset local.deptName = StructKeyExists(local.w, "department") and Len(local.w.department) ? local.w.department : local.w.name>
						<cfset local.deptCat = StructKeyExists(local.w, "department_category") and Len(local.w.department_category) ? local.w.department_category : "">
						<cfset local.virtualDir = StructKeyExists(local.w, "virtual_directory") and Len(local.w.virtual_directory) ? local.w.virtual_directory : local.w.id>
						<cfset local.redirectUrl = StructKeyExists(local.w, "redirect_url") ? local.w.redirect_url : "">
						<cfset local.wsType = StructKeyExists(local.w, "type") ? local.w.type : "dept">
						<cfset local.wsColor = (StructKeyExists(local.w, "color") and Len(local.w.color)) ? local.w.color : (local.wsType eq "dept" ? "##7e22ce" : (local.wsType eq "site" ? "##10b981" : "##0073aa"))>

						<!--- Main Table Row --->
						<tr class="ws-row-item" id="ws-row-#local.w.id#" style="border-bottom:1px solid var(--admin-border); #(isCurrentActive ? 'background:rgba(0,115,170,0.03);' : '')#">
							<!--- 1. Site / Workspace Name --->
							<td style="padding:0.85rem 1rem;">
								<div style="display:flex; align-items:flex-start; gap:0.75rem;">
									<div style="width:34px; height:34px; border-radius:var(--radius-sm); background-color:#local.wsColor#1a; color:#local.wsColor#; border:1px solid #local.wsColor#33; display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;" title="Workspace Theme: #local.wsColor#">
										#svgIcon(name=local.w.icon, size=18)#
									</div>
									<div>
										<div style="font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.4rem; flex-wrap:wrap;">
											<span>#EncodeForHTML(local.w.name)#</span>
											<cfif local.wsType eq "dept">
												<span class="badge" style="background:rgba(126,34,206,0.1); color:##7e22ce; border:1px solid rgba(126,34,206,0.25); font-size:0.68rem; font-weight:700; display:inline-flex; align-items:center; gap:0.25rem; padding:0.12rem 0.45rem; border-radius:9999px;">
													#svgIcon(name="building", size=10)# Department
												</span>
											<cfelseif local.wsType eq "site">
												<span class="badge" style="background:rgba(16,185,129,0.1); color:##047857; border:1px solid rgba(16,185,129,0.25); font-size:0.68rem; font-weight:700; display:inline-flex; align-items:center; gap:0.25rem; padding:0.12rem 0.45rem; border-radius:9999px;">
													#svgIcon(name="globe", size=10)# Site / Portal
												</span>
											<cfelse>
												<span class="badge badge-neutral" style="font-size:0.68rem; font-weight:700; display:inline-flex; align-items:center; gap:0.25rem; padding:0.12rem 0.45rem; border-radius:9999px;">
													#svgIcon(name="grid", size=10)# Global
												</span>
											</cfif>
											<cfif isCurrentActive>
												<span class="badge badge-success" style="font-size:0.65rem; padding:0.1rem 0.35rem;">Active</span>
											</cfif>
										</div>
										<cfif Len(local.redirectUrl)>
											<div style="margin-top:0.2rem;">
												<a href="#EncodeForHTMLAttribute(local.redirectUrl)#" target="_blank" rel="noopener noreferrer" style="font-size:0.72rem; color:var(--admin-primary); display:inline-flex; align-items:center; gap:0.25rem; text-decoration:none;" title="External redirect URL">
													#svgIcon(name="external-link", size=11)#
													<span>#Left(local.redirectUrl, 26)#<cfif Len(local.redirectUrl) gt 26>...</cfif></span>
												</a>
											</div>
										</cfif>
										<div style="font-size:0.73rem; color:var(--admin-text-muted); margin-top:0.15rem;">
											#EncodeForHTML(local.w.desc)#
										</div>
									</div>
								</div>
							</td>

							<!--- 2. Virtual Directory & IIS Path --->
							<td style="padding:0.85rem 1rem; vertical-align:top;">
								<div>
									<code style="background:var(--admin-surface-hover); padding:0.15rem 0.4rem; border-radius:var(--radius-sm); font-size:0.78rem; color:var(--admin-text-main); border:1px solid var(--admin-border); font-weight:600;">#EncodeForHTML(local.virtualDir)#</code>
								</div>
								<div style="display:flex; align-items:center; gap:0.35rem; font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem;">
									<cfif StructKeyExists(local.w, "diskExists") and local.w.diskExists>
										<span style="color:var(--admin-success); display:inline-flex;" title="Directory Verified on Disk">#svgIcon(name="check-circle", size=13)#</span>
									<cfelse>
										<span style="color:var(--admin-warning); display:inline-flex;" title="Virtual Directory">#svgIcon(name="folder", size=13)#</span>
									</cfif>
									<span>files/#EncodeForHTML(local.virtualDir)#</span>
								</div>
								<div style="font-size:0.71rem; color:var(--admin-primary); margin-top:0.2rem; font-family:monospace;">
									#EncodeForHTML(Len(Trim(local.w.assets_domain ?: '')) ? ((local.w.assets_protocol ?: 'http') & '://' & Trim(local.w.assets_domain)) : '')#/#EncodeForHTML(local.virtualDir)#
								</div>
							</td>

							<!--- 3. Department & Category --->
							<td style="padding:0.85rem 1rem; vertical-align:top;">
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.82rem; display:flex; align-items:center; gap:0.35rem;">
									<cfif local.wsType eq "site">
										<span style="color:##047857; display:inline-flex;" title="Public Web Portal">#svgIcon(name="globe", size=13)#</span>
									<cfelseif local.wsType eq "dept">
										<span style="color:##7e22ce; display:inline-flex;" title="Municipal Department">#svgIcon(name="building", size=13)#</span>
									<cfelse>
										<span style="color:##475569; display:inline-flex;" title="Global Overview">#svgIcon(name="grid", size=13)#</span>
									</cfif>
									<span>#EncodeForHTML(local.deptName)#</span>
								</div>
								<div style="margin-top:0.25rem; display:flex; align-items:center; gap:0.35rem; flex-wrap:wrap;">
									<cfif local.wsType eq "site">
										<span class="badge" style="background:rgba(16,185,129,0.1); color:##047857; border:1px solid rgba(16,185,129,0.25); font-size:0.68rem; padding:0.12rem 0.45rem; border-radius:4px;">Site / Portal</span>
									<cfelseif local.wsType eq "dept">
										<span class="badge" style="background:rgba(126,34,206,0.1); color:##7e22ce; border:1px solid rgba(126,34,206,0.25); font-size:0.68rem; padding:0.12rem 0.45rem; border-radius:4px;">Department</span>
									</cfif>
									<cfif Len(local.deptCat)>
										<span class="badge #local.w.badgeClass#" style="font-size:0.68rem; padding:0.12rem 0.45rem;">#EncodeForHTML(local.deptCat)#</span>
									<cfelseif local.wsType neq "dept" and local.wsType neq "site">
										<span class="badge #local.w.badgeClass#" style="font-size:0.68rem; padding:0.12rem 0.45rem;">#local.w.badge#</span>
									</cfif>
								</div>
							</td>

							<!--- 4. Contact Information --->
							<td style="padding:0.85rem 1rem; vertical-align:top;">
								<div style="display:flex; align-items:flex-start; gap:0.55rem;">
									<cfif Len(local.contactPhoto)>
										<img src="#EncodeForHTMLAttribute(local.contactPhoto)#" alt="#EncodeForHTMLAttribute(local.contactFullName)#" style="width:34px; height:34px; border-radius:50%; object-fit:cover; border:1.5px solid var(--admin-border); flex-shrink:0; margin-top:2px;" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';" />
										<div style="width:34px; height:34px; border-radius:50%; background:var(--admin-surface-hover); border:1.5px solid var(--admin-border); display:none; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px; color:var(--admin-text-muted);">
											#svgIcon(name="user", size=15)#
										</div>
									<cfelse>
										<div style="width:34px; height:34px; border-radius:50%; background:var(--admin-surface-hover); border:1.5px solid var(--admin-border); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px; color:var(--admin-text-muted);">
											#svgIcon(name="user", size=15)#
										</div>
									</cfif>
									<div style="flex:1; min-width:0;">
										<div style="display:flex; align-items:center; gap:0.35rem; margin-bottom:0.25rem;">
											<cfif local.leadershipType eq "elected">
												<span class="badge" style="background:rgba(217,119,6,0.12); color:##b45309; border:1px solid rgba(217,119,6,0.25); font-size:0.65rem; font-weight:700; padding:0.1rem 0.4rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;" title="Elected Official Leadership">
													#svgIcon(name="award", size=10)# Elected
												</span>
											<cfelse>
												<span class="badge" style="background:rgba(37,99,235,0.08); color:##1d4ed8; border:1px solid rgba(37,99,235,0.2); font-size:0.65rem; font-weight:600; padding:0.1rem 0.4rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;" title="Department Head Leadership">
													#svgIcon(name="briefcase", size=10)# Dept Head
												</span>
											</cfif>
										</div>
										<cfif Len(local.contactFullName)>
											<div style="font-weight:700; color:var(--admin-text-main); font-size:0.82rem; line-height:1.25;">
												#EncodeForHTML(local.contactFullName)#
											</div>
											<cfif Len(local.jobTitle)>
												<div style="font-size:0.73rem; color:var(--admin-text-muted); margin-top:0.15rem; font-weight:500;">
													#EncodeForHTML(local.jobTitle)#
												</div>
											</cfif>
										<cfelse>
											<div style="color:var(--admin-text-muted); font-size:0.78rem; font-style:italic;">No contact designated</div>
										</cfif>

										<cfif Len(local.contactEmail)>
											<div style="margin-top:0.25rem; font-size:0.75rem;">
												<a href="mailto:#EncodeForHTMLAttribute(local.contactEmail)#" style="color:var(--admin-primary); text-decoration:none; display:inline-flex; align-items:center; gap:0.25rem;">
													#svgIcon(name="mail", size=11)#
													<span>#EncodeForHTML(local.contactEmail)#</span>
												</a>
											</div>
										</cfif>

										<cfif Len(local.contactPhone)>
											<div style="margin-top:0.15rem; font-size:0.74rem; color:var(--admin-text-muted); display:inline-flex; align-items:center; gap:0.25rem;">
												#svgIcon(name="phone", size=11)#
												<a href="tel:#EncodeForHTMLAttribute(local.contactPhone)#" style="color:var(--admin-text-muted); text-decoration:none;">#EncodeForHTML(local.contactPhone)#</a>
												<cfif Len(local.contactFax)>
													<span style="font-size:0.7rem;">(Fax: #EncodeForHTML(local.contactFax)#)</span>
												</cfif>
											</div>
										</cfif>
									</div>
								</div>
							</td>

							<!--- 5. Office Location & Hours --->
							<td style="padding:0.85rem 1rem; vertical-align:top;">
								<cfif Len(local.contactAddr)>
									<div style="font-size:0.78rem; color:var(--admin-text-main); line-height:1.3;">
										#EncodeForHTML(local.contactAddr)#<cfif Len(local.contactAddr2)>, #EncodeForHTML(local.contactAddr2)#</cfif>
									</div>
									<div style="font-size:0.73rem; color:var(--admin-text-muted);">
										#EncodeForHTML(local.contactCity)#, #EncodeForHTML(local.contactState)# #EncodeForHTML(local.contactZip)#
									</div>
								<cfelse>
									<div style="font-size:0.78rem; color:var(--admin-text-muted);">
										#EncodeForHTML(local.contactCity)#, #EncodeForHTML(local.contactState)# #EncodeForHTML(local.contactZip)#
									</div>
								</cfif>

								<cfif Len(local.contactHours)>
									<div style="margin-top:0.3rem; font-size:0.72rem; color:var(--admin-text-muted); display:flex; align-items:flex-start; gap:0.3rem;">
										#svgIcon(name="clock", size=11)#
										<span>#EncodeForHTML(local.contactHours)#</span>
									</div>
								</cfif>
							</td>

							<!--- 6. Staff Assigned --->
							<td style="padding:0.85rem 1rem; vertical-align:top;">
								<a href="#urlFor(controller='users', action='index', params='dept=' & local.w.id)#" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem; padding:0.15rem 0.5rem; display:inline-flex; align-items:center; gap:0.35rem;" title="View Assigned Staff">
									#svgIcon(name="users", size=12)#
									<span>#local.w.userCount# Staff</span>
								</a>
							</td>

							<!--- 7. Actions --->
							<td style="padding:0.85rem 1rem; vertical-align:top; text-align:right;">
								<div style="display:inline-flex; gap:0.35rem; justify-content:flex-end; flex-wrap:wrap;">
									<button type="button" class="btn btn-outline-secondary btn-sm btn-toggle-ws-details"
									        data-target="ws-details-#local.w.id#"
									        style="font-size:0.75rem; padding:0.25rem 0.5rem; display:inline-flex; align-items:center; gap:0.25rem;"
									        title="Toggle complete field details card">
										#svgIcon(name="chevron-down", size=12, class="ws-chevron-icon")#
										<span class="ws-btn-text">Details</span>
									</button>

									<cfif local.w.id neq "global">
										<a href="#urlFor(controller='workspaces', action='edit', params='id=' & local.w.id)#" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem; padding:0.25rem 0.5rem;" title="Edit Workspace Settings">
											#svgIcon(name="edit", size=12)#
											<span>Edit</span>
										</a>
										<a href="#urlFor(controller='media', action='index', params='ws=' & local.w.id)#" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem; padding:0.25rem 0.5rem;" title="Browse Media for this Workspace">
											#svgIcon(name="media", size=13)#
											<span>Media</span>
										</a>
										<cfif !structKeyExists(local.w, "is_system") or !local.w.is_system>
											<a href="#urlFor(controller='workspaces', action='delete', params='id=' & local.w.id)#" class="btn btn-outline-danger btn-sm" style="font-size:0.75rem; padding:0.25rem 0.5rem;" data-confirm="Are you sure you want to delete workspace '#EncodeForHTMLAttribute(local.w.name)#'?" data-confirm-title="Delete workspace?" data-confirm-accept="Delete" title="Delete Workspace">
												#svgIcon(name="trash", size=12)#
												<span>Delete</span>
											</a>
										</cfif>
									</cfif>

									<button type="button" class="btn btn-primary btn-sm btn-switch-ws"
									        data-ws-id="#local.w.id#"
									        data-ws-name="#EncodeForHTMLAttribute(local.w.name)#"
									        data-ws-type="#local.w.type#"
									        data-ws-badge="#local.w.badge#"
									        data-ws-badge-cls="#local.w.badgeClass#"
									        data-ws-icon="#local.w.icon#"
									        style="font-size:0.75rem; padding:0.25rem 0.55rem;">
										<span>Switch</span>
									</button>
								</div>
							</td>
						</tr>

						<!--- Expandable Full Details Drawer Row --->
						<tr id="ws-details-#local.w.id#" class="ws-details-row" style="display:none; background:var(--admin-surface-hover);">
							<td colspan="7" style="padding:0; border-bottom:2px solid var(--admin-border);">
								<div class="ws-details-drawer">
									<div class="ws-details-grid">
										<!--- Card 1: Site & Directory Configuration --->
										<div class="ws-detail-card">
											<div class="ws-detail-card-title">
												#svgIcon(name="settings", size=14)#
												<span>Site &amp; Directory Configuration</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Site Name:</span>
												<span class="ws-detail-val"><strong>#EncodeForHTML(local.w.name)#</strong></span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Classification:</span>
												<span class="ws-detail-val">
													<cfif local.wsType eq "dept">
														<span class="badge" style="background:rgba(126,34,206,0.1); color:##7e22ce; border:1px solid rgba(126,34,206,0.25); font-size:0.72rem; padding:0.15rem 0.5rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
															#svgIcon(name="building", size=11)# Municipal Department
														</span>
													<cfelseif local.wsType eq "site">
														<span class="badge" style="background:rgba(16,185,129,0.1); color:##047857; border:1px solid rgba(16,185,129,0.25); font-size:0.72rem; padding:0.15rem 0.5rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
															#svgIcon(name="globe", size=11)# Public Site / Portal
														</span>
													<cfelse>
														<span class="badge badge-neutral" style="font-size:0.72rem; padding:0.15rem 0.5rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
															#svgIcon(name="grid", size=11)# Global Overview
														</span>
													</cfif>
												</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Virtual Directory (IIS):</span>
												<span class="ws-detail-val"><code>#EncodeForHTML(local.virtualDir)#</code></span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Department:</span>
												<span class="ws-detail-val">#EncodeForHTML(local.deptName)#</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Department Category:</span>
												<span class="ws-detail-val"><span class="badge #local.w.badgeClass#">#Len(local.deptCat) ? EncodeForHTML(local.deptCat) : 'General'#</span></span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Theme Color:</span>
												<span class="ws-detail-val" style="display:inline-flex; align-items:center; gap:0.4rem;">
													<span style="display:inline-block; width:13px; height:13px; border-radius:50%; background-color:#local.wsColor#; border:1px solid rgba(0,0,0,0.15);"></span>
													<code style="font-size:0.75rem;">#local.wsColor#</code>
												</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Domain Name:</span>
												<span class="ws-detail-val"><code>#EncodeForHTML(local.w.domain_name ?: 'www.chelancounty.gov')#</code></span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Assets Domain:</span>
												<span class="ws-detail-val"><code style="color:var(--admin-primary); font-weight:600;">#EncodeForHTML(Len(Trim(local.w.assets_domain ?: '')) ? ((local.w.assets_protocol ?: 'http') & '://' & Trim(local.w.assets_domain)) : '/ (relative /[url])')#</code></span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Custom Redirect URL:</span>
												<span class="ws-detail-val">
													<cfif Len(local.redirectUrl)>
														<a href="#EncodeForHTMLAttribute(local.redirectUrl)#" target="_blank" rel="noopener noreferrer" style="color:var(--admin-primary); display:inline-flex; align-items:center; gap:0.25rem;">
															#svgIcon(name="external-link", size=11)#
															<span>#EncodeForHTML(local.redirectUrl)#</span>
														</a>
													<cfelse>
														<span style="color:var(--admin-text-muted); font-style:italic;">None configured</span>
													</cfif>
												</span>
											</div>
											<div class="ws-detail-row" style="margin-top:0.75rem; padding-top:0.5rem; border-top:1px solid var(--admin-border);">
												<span class="ws-detail-label">Storage Path:</span>
												<span class="ws-detail-val"><code>#EncodeForHTML(local.w.storage_path ?: ('files/' & local.virtualDir))#</code></span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Project Path:</span>
												<span class="ws-detail-val"><code>#EncodeForHTML(local.w.project_path ?: 'C:\inetpub\chelan-county')#</code></span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Media &amp; Docs:</span>
												<span class="ws-detail-val"><small style="color:var(--admin-text-muted);">media/ &bull; documents/</small></span>
											</div>
										</div>

										<!--- Card 2: Contact Information --->
										<div class="ws-detail-card">
											<div class="ws-detail-card-title">
												#svgIcon(name="user", size=14)#
												<span>Contact Information</span>
											</div>
											<cfif Len(local.contactPhoto)>
												<div style="display:flex; align-items:center; gap:0.75rem; margin-bottom:0.75rem; padding-bottom:0.75rem; border-bottom:1px solid var(--admin-border);">
													<img src="#EncodeForHTMLAttribute(local.contactPhoto)#" alt="Profile" style="width:48px; height:48px; border-radius:50%; object-fit:cover; border:2px solid var(--admin-border); box-shadow:var(--shadow-sm);" onerror="this.style.display='none';" />
													<div style="flex:1; min-width:0;">
														<div style="font-weight:700; font-size:0.88rem; color:var(--admin-text-main);">
															#Len(local.contactFullName) ? EncodeForHTML(local.contactFullName) : 'Official Contact'#
														</div>
														<cfif Len(local.jobTitle)>
															<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.1rem;">
																#EncodeForHTML(local.jobTitle)#
															</div>
														</cfif>
													</div>
												</div>
											</cfif>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Leadership:</span>
												<span class="ws-detail-val">
													<cfif local.leadershipType eq "elected">
														<span class="badge" style="background:rgba(217,119,6,0.12); color:##b45309; border:1px solid rgba(217,119,6,0.25); font-size:0.7rem; font-weight:700; padding:0.12rem 0.5rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
															#svgIcon(name="award", size=11)# Elected Official
														</span>
													<cfelse>
														<span class="badge" style="background:rgba(37,99,235,0.08); color:##1d4ed8; border:1px solid rgba(37,99,235,0.2); font-size:0.7rem; font-weight:600; padding:0.12rem 0.5rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
															#svgIcon(name="briefcase", size=11)# Department Head
														</span>
													</cfif>
												</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Job Title:</span>
												<span class="ws-detail-val">#Len(local.jobTitle) ? EncodeForHTML(local.jobTitle) : '<em style="color:var(--admin-text-muted);">None</em>'#</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">First Name:</span>
												<span class="ws-detail-val">#Len(local.contactFirst) ? EncodeForHTML(local.contactFirst) : '<em style="color:var(--admin-text-muted);">None</em>'#</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Last Name:</span>
												<span class="ws-detail-val">#Len(local.contactLast) ? EncodeForHTML(local.contactLast) : '<em style="color:var(--admin-text-muted);">None</em>'#</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Email:</span>
												<span class="ws-detail-val">
													<cfif Len(local.contactEmail)>
														<a href="mailto:#EncodeForHTMLAttribute(local.contactEmail)#" style="color:var(--admin-primary); font-weight:600;">#EncodeForHTML(local.contactEmail)#</a>
													<cfelse>
														<span style="color:var(--admin-text-muted); font-style:italic;">None</span>
													</cfif>
												</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Phone:</span>
												<span class="ws-detail-val">
													<cfif Len(local.contactPhone)>
														<a href="tel:#EncodeForHTMLAttribute(local.contactPhone)#" style="color:var(--admin-text-main); font-weight:600;">#EncodeForHTML(local.contactPhone)#</a>
													<cfelse>
														<span style="color:var(--admin-text-muted); font-style:italic;">None</span>
													</cfif>
												</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Fax:</span>
												<span class="ws-detail-val">#Len(local.contactFax) ? EncodeForHTML(local.contactFax) : '<em style="color:var(--admin-text-muted);">None</em>'#</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Photo:</span>
												<span class="ws-detail-val">
													<cfif Len(local.contactPhoto)>
														<a href="#EncodeForHTMLAttribute(local.contactPhoto)#" target="_blank" rel="noopener noreferrer" style="color:var(--admin-primary); display:inline-flex; align-items:center; gap:0.25rem; font-size:0.75rem;">
															#svgIcon(name="image", size=11)#
															<span>#EncodeForHTML(GetFileFromPath(local.contactPhoto))#</span>
														</a>
													<cfelse>
														<span style="color:var(--admin-text-muted); font-style:italic;">None configured</span>
													</cfif>
												</span>
											</div>
											<div class="ws-detail-row" style="margin-top:0.75rem; padding-top:0.5rem; border-top:1px solid var(--admin-border);">
												<span class="ws-detail-label">Assigned Staff:</span>
												<span class="ws-detail-val"><strong>#local.w.userCount# user(s)</strong></span>
											</div>
										</div>

										<!--- Card 3: Location, Hours & Actions --->
										<div class="ws-detail-card">
											<div class="ws-detail-card-title">
												#svgIcon(name="map-pin", size=14)#
												<span>Location &amp; Operating Hours</span>
											</div>
											<div class="ws-detail-row">
												<span class="ws-detail-label">Address:</span>
												<span class="ws-detail-val">#Len(local.contactAddr) ? EncodeForHTML(local.contactAddr) : '350 Orondo Ave'#</span>
											</div>
											<cfif Len(local.contactAddr2)>
												<div class="ws-detail-row">
													<span class="ws-detail-label">Suite / Unit:</span>
													<span class="ws-detail-val">#EncodeForHTML(local.contactAddr2)#</span>
												</div>
											</cfif>
											<div class="ws-detail-row">
												<span class="ws-detail-label">City, State, Zip:</span>
												<span class="ws-detail-val">#EncodeForHTML(local.contactCity)#, #EncodeForHTML(local.contactState)# #EncodeForHTML(local.contactZip)#</span>
											</div>
											<div class="ws-detail-row" style="margin-top:0.5rem;">
												<span class="ws-detail-label">Office Hours:</span>
												<span class="ws-detail-val" style="font-size:0.76rem; color:var(--admin-text-muted);">
													#Len(local.contactHours) ? EncodeForHTML(local.contactHours) : 'Monday - Friday: 8:00 AM - 5:00 PM'#
												</span>
											</div>

											<div style="margin-top:1rem; padding-top:0.75rem; border-top:1px solid var(--admin-border); display:flex; gap:0.4rem; justify-content:flex-end; flex-wrap:wrap;">
												<a href="#urlFor(controller='users', action='index', params='dept=' & local.w.id)#" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem;">
													#svgIcon(name="users", size=12)#
													<span>Staff</span>
												</a>
												<cfif local.w.id neq "global">
													<a href="#urlFor(controller='workspaces', action='edit', params='id=' & local.w.id)#" class="btn btn-outline-primary btn-sm" style="font-size:0.75rem;">
														#svgIcon(name="edit", size=12)#
														<span>Edit Workspace</span>
													</a>
													<a href="#urlFor(controller='media', action='index', params='ws=' & local.w.id)#" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem;">
														#svgIcon(name="media", size=12)#
														<span>Media</span>
													</a>
													<cfif !structKeyExists(local.w, "is_system") or !local.w.is_system>
														<a href="#urlFor(controller='workspaces', action='delete', params='id=' & local.w.id)#" class="btn btn-outline-danger btn-sm" style="font-size:0.75rem;" data-confirm="Are you sure you want to delete workspace '#EncodeForHTMLAttribute(local.w.name)#'?" data-confirm-title="Delete workspace?" data-confirm-accept="Delete" title="Delete Workspace">
															#svgIcon(name="trash", size=12)#
															<span>Delete</span>
														</a>
													</cfif>
												</cfif>
												<button type="button" class="btn btn-primary btn-sm btn-switch-ws"
												        data-ws-id="#local.w.id#"
												        data-ws-name="#EncodeForHTMLAttribute(local.w.name)#"
												        data-ws-type="#local.w.type#"
												        data-ws-badge="#local.w.badge#"
												        data-ws-badge-cls="#local.w.badgeClass#"
												        data-ws-icon="#local.w.icon#"
												        style="font-size:0.75rem;">
													#svgIcon(name="check", size=12)#
													<span>Make Active</span>
												</button>
											</div>
										</div>
									</div>
								</div>
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function() {
	// Individual Details Drawer Toggle
	document.querySelectorAll(".btn-toggle-ws-details").forEach(function(btn) {
		btn.addEventListener("click", function(e) {
			e.preventDefault();
			var targetId = btn.getAttribute("data-target");
			var drawerRow = document.getElementById(targetId);
			if (drawerRow) {
				var isHidden = (drawerRow.style.display === "none" || drawerRow.style.display === "");
				drawerRow.style.display = isHidden ? "table-row" : "none";
				
				var textSpan = btn.querySelector(".ws-btn-text");
				if (textSpan) {
					textSpan.textContent = isHidden ? "Hide" : "Details";
				}
				var iconSvg = btn.querySelector(".ws-chevron-icon");
				if (iconSvg) {
					iconSvg.style.transform = isHidden ? "rotate(180deg)" : "rotate(0deg)";
					iconSvg.style.transition = "transform 0.15s ease";
				}
			}
		});
	});

	// Global Expand / Collapse All Toggle
	var allExpanded = false;
	var btnToggleAll = document.getElementById("btnToggleAllDetails");
	var btnToggleAllText = document.getElementById("btnToggleAllText");

	if (btnToggleAll) {
		btnToggleAll.addEventListener("click", function(e) {
			e.preventDefault();
			allExpanded = !allExpanded;
			document.querySelectorAll(".ws-details-row").forEach(function(row) {
				row.style.display = allExpanded ? "table-row" : "none";
			});
			document.querySelectorAll(".btn-toggle-ws-details").forEach(function(btn) {
				var textSpan = btn.querySelector(".ws-btn-text");
				if (textSpan) {
					textSpan.textContent = allExpanded ? "Hide" : "Details";
				}
				var iconSvg = btn.querySelector(".ws-chevron-icon");
				if (iconSvg) {
					iconSvg.style.transform = allExpanded ? "rotate(180deg)" : "rotate(0deg)";
				}
			});
			if (btnToggleAllText) {
				btnToggleAllText.textContent = allExpanded ? "Collapse All Details" : "Expand All Details";
			}
		});
	}

	// Switch Active Workspace Button Handlers
	document.querySelectorAll(".btn-switch-ws").forEach(function(btn) {
		btn.addEventListener("click", function(e) {
			e.preventDefault();
			var wsId = btn.getAttribute("data-ws-id");
			var wsName = btn.getAttribute("data-ws-name");
			var wsType = btn.getAttribute("data-ws-type");
			var wsBadge = btn.getAttribute("data-ws-badge");
			var wsBadgeCls = btn.getAttribute("data-ws-badge-cls");
			var wsIcon = btn.getAttribute("data-ws-icon");

			var wsData = {
				id: wsId,
				name: wsName,
				type: wsType,
				badge: wsBadge,
				badgeCls: wsBadgeCls,
				icon: wsIcon
			};

			try {
				localStorage.setItem("cmsadmin_active_workspace", JSON.stringify(wsData));
				document.cookie = "cmsadmin_workspace=" + encodeURIComponent(wsId) + "; path=/; max-age=31536000; SameSite=Lax";
			} catch(err) {}

			// Trigger reload or update
			window.location.reload();
		});
	});
});
</script>

<!--- Prepare JSON catalog of all active workspaces for Mega Menu Preview --->
<cfscript>
	local.sourceWsList = (StructKeyExists(variables, "allWorkspaces") && IsArray(variables.allWorkspaces)) ? variables.allWorkspaces : variables.workspaces;
	local.previewItems = [];
	local.previewCategoriesMap = {};
	local.previewCategories = [];

	// Standard category ordering matching Workspaces.cfc
	local.standardCategoryOrder = [
		"County Administration",
		"Finance and Records",
		"Community Services",
		"Law Enforcement",
		"Law and Judicial Services",
		"Internal Services",
		"Chelan-Douglas",
		"Community Outreach"
	];

	for (local.pw in local.sourceWsList) {
		if (local.pw.id eq "global" || (StructKeyExists(local.pw, "type") && local.pw.type eq "global")) {
			continue;
		}
		local.pwCat = (StructKeyExists(local.pw, "department_category") && Len(Trim(local.pw.department_category)))
			? Trim(local.pw.department_category)
			: ((StructKeyExists(local.pw, "type") && local.pw.type eq "site") ? "Community Outreach" : "County Administration");
		local.pwVirt = (StructKeyExists(local.pw, "virtual_directory") && Len(Trim(local.pw.virtual_directory))) ? Trim(local.pw.virtual_directory) : local.pw.id;
		local.pwUrl = (StructKeyExists(local.pw, "redirect_url") && Len(Trim(local.pw.redirect_url)))
			? Trim(local.pw.redirect_url)
			: ("https://www.chelancounty.gov/" & local.pwVirt);
		local.pwContactFirst = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "first_name")) ? local.pw.contact.first_name : "";
		local.pwContactLast = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "last_name")) ? local.pw.contact.last_name : "";
		local.pwContactName = Trim(local.pwContactFirst & " " & local.pwContactLast);
		local.pwJobTitle = (StructKeyExists(local.pw, "job_title") && Len(local.pw.job_title))
			? local.pw.job_title
			: ((StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "job_title")) ? local.pw.contact.job_title : "");
		local.pwPhone = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "phone")) ? local.pw.contact.phone : "";
		local.pwEmail = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "email")) ? local.pw.contact.email : "";
		local.pwAddress = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "address")) ? local.pw.contact.address : "";
		local.pwCity = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "city") && Len(local.pw.contact.city)) ? local.pw.contact.city : "Wenatchee";
		local.pwState = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "state") && Len(local.pw.contact.state)) ? local.pw.contact.state : "WA";
		local.pwZip = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "zip") && Len(local.pw.contact.zip)) ? local.pw.contact.zip : "98801";
		local.pwHours = (StructKeyExists(local.pw, "contact") && IsStruct(local.pw.contact) && StructKeyExists(local.pw.contact, "office_hours")) ? local.pw.contact.office_hours : "";

		if (!StructKeyExists(local.previewCategoriesMap, local.pwCat)) {
			local.previewCategoriesMap[local.pwCat] = true;
		}

		ArrayAppend(local.previewItems, {
			"id": local.pw.id,
			"name": local.pw.name,
			"department": (StructKeyExists(local.pw, "department") && Len(local.pw.department)) ? local.pw.department : local.pw.name,
			"category": local.pwCat,
			"type": StructKeyExists(local.pw, "type") ? local.pw.type : "dept",
			"virtualDirectory": local.pwVirt,
			"destinationUrl": local.pwUrl,
			"editUrl": urlFor(controller="workspaces", action="edit", params="id=" & local.pw.id),
			"leadershipType": (StructKeyExists(local.pw, "leadership_type") && Len(local.pw.leadership_type)) ? local.pw.leadership_type : "dept_head",
			"contactName": local.pwContactName,
			"jobTitle": local.pwJobTitle,
			"phone": local.pwPhone,
			"email": local.pwEmail,
			"address": Trim(local.pwAddress & (Len(local.pwAddress) ? ", " : "") & local.pwCity & ", " & local.pwState & " " & local.pwZip),
			"officeHours": local.pwHours,
			"color": (StructKeyExists(local.pw, "color") && Len(local.pw.color)) ? local.pw.color : "##0073aa"
		});
	}

	for (local.stdCat in local.standardCategoryOrder) {
		if (StructKeyExists(local.previewCategoriesMap, local.stdCat)) {
			ArrayAppend(local.previewCategories, local.stdCat);
			StructDelete(local.previewCategoriesMap, local.stdCat);
		}
	}
	for (local.extraCat in StructKeyArray(local.previewCategoriesMap)) {
		ArrayAppend(local.previewCategories, local.extraCat);
	}

	local.wsPreviewJson = Replace(SerializeJSON({
		"categories": local.previewCategories,
		"items": local.previewItems,
		"autoOpen": (StructKeyExists(variables, "openMegaMenuPreview") && variables.openMegaMenuPreview)
	}), "</", "<\/", "all");
</cfscript>

<!--- =====================================================================
      MODAL: LIVE CHELANCOUNTY.GOV WORKSPACES & MEGA-MENU PREVIEW
      ===================================================================== --->
<div class="ws-modal-backdrop" id="wsMegaMenuPreviewModal" role="dialog" aria-modal="true" aria-labelledby="wsMegaMenuPreviewTitle">
	<div class="ws-modal-dialog">
		<div class="ws-modal-header">
			<h2 class="ws-modal-title" id="wsMegaMenuPreviewTitle">
				#svgIcon(name="eye", size=18)#
				<span>LIVE CHELANCOUNTY.GOV "YOUR GOVERNMENT" PREVIEW</span>
			</h2>
			<div style="display:flex; align-items:center; gap:0.5rem;">
				<div style="display:inline-flex; border:1px solid var(--admin-border); border-radius:var(--radius-sm); overflow:hidden;">
					<button type="button" class="btn btn-xs btn-ghost" id="btnWsPreviewTabDir">
						/departments Directory Page
					</button>
					<button type="button" class="btn btn-xs btn-primary" id="btnWsPreviewTabMega">
						Top Navbar Mega-Menu
					</button>
				</div>
				<button type="button" class="btn btn-ghost btn-xs" id="btnCloseWsPreviewModal" aria-label="Close preview">#svgIcon(name="x", size=18)#</button>
			</div>
		</div>

		<div class="ws-modal-body">
			<!--- Tab 1: Top Navbar Mega-Menu View (Default active when clicking Mega Menu Preview) --->
			<div id="wsPreviewMegaPane">
				<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1rem; padding-bottom:0.65rem; border-bottom:2px solid ##0f172a;">
					<h3 style="margin:0; font-size:1.4rem; font-weight:700; color:##0f172a;">Your Government &amp; Workspaces</h3>
					<a href="https://www.chelancounty.gov" target="_blank" rel="noopener noreferrer" class="btn btn-primary btn-xs" style="border-radius:999px; padding:0.35rem 1rem; text-decoration:none;">See All...</a>
				</div>
				<div class="ws-preview-mega-grid" id="wsPreviewMegaGrid"></div>

				<!--- Two-Tier Navbar Rollup (Departments vs Community Outreach Portals) --->
				<div id="wsPreviewNavbarRollup" style="margin-top:1.25rem; padding:1.15rem 1.25rem; background:##ffffff; border:1px solid ##cbd5e1; border-radius:0.5rem;"></div>
			</div>

			<!--- Tab 2: /departments Directory Page View --->
			<div id="wsPreviewDirectoryPane" style="display:none;">
				<div style="margin-bottom:1rem; padding-bottom:0.75rem; border-bottom:2px solid ##0f172a; display:flex; align-items:baseline; justify-content:space-between; flex-wrap:wrap;">
					<h3 style="margin:0; font-size:1.55rem; font-weight:700; color:##0f172a;">Departments &amp; Portals Directory</h3>
					<span style="font-size:0.78rem; color:var(--admin-text-muted);">Public URL: <strong>https://www.chelancounty.gov/departments</strong></span>
				</div>
				<div style="display:grid; grid-template-columns:240px minmax(0, 1fr); gap:1.5rem; align-items:start;">
					<ul id="wsPreviewSidebarList" style="list-style:none; margin:0; padding:0; border:1px solid ##cbd5e1; border-radius:0.375rem; overflow:hidden;"></ul>
					<div id="wsPreviewCategoryContent" style="padding:0.25rem 0.5rem;"></div>
				</div>
			</div>
		</div>

		<div class="ws-modal-footer">
			<div style="font-size:0.78rem; color:var(--admin-text-muted);">
				Showing <strong>#ArrayLen(local.previewItems)#</strong> active workspaces across <strong>#ArrayLen(local.previewCategories)#</strong> department categories
			</div>
			<button type="button" class="btn btn-outline btn-sm" id="btnDismissWsPreviewModal">Close Preview</button>
		</div>
	</div>
</div>

<script id="wsMegaMenuPreviewData" type="application/json"># local.wsPreviewJson #</script>
</cfoutput>
<script>
(function() {
	var dataEl = document.getElementById("wsMegaMenuPreviewData");
	var cfg = { categories: [], items: [], autoOpen: false };
	if (dataEl && dataEl.textContent) {
		try { cfg = JSON.parse(dataEl.textContent); } catch (e) {}
	}

	var previewModal = document.getElementById("wsMegaMenuPreviewModal");
	var megaGridEl = document.getElementById("wsPreviewMegaGrid");
	var navbarRollupEl = document.getElementById("wsPreviewNavbarRollup");
	var sidebarEl = document.getElementById("wsPreviewSidebarList");
	var contentEl = document.getElementById("wsPreviewCategoryContent");
	var selectedDirCategory = "ALL";

	function escapeHtml(s) {
		return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
	}

	function renderWorkspaceMegaPreview() {
		var items = cfg.items || [];
		var cats = cfg.categories || [];

		// 1. Render Category Columns in Top Navbar Mega-Menu Grid
		if (megaGridEl) {
			megaGridEl.innerHTML = "";
			if (items.length === 0) {
				megaGridEl.innerHTML = "<div style='grid-column:1/-1; color:#64748b; font-size:0.9rem;'>No active workspaces configured yet.</div>";
			} else {
				cats.forEach(function(catName) {
					var catItems = items.filter(function(w) { return w.category === catName; });
					if (catItems.length === 0) return;

					var col = document.createElement("div");
					col.className = "ws-preview-mega-col";
					var html = "<h4><span>" + escapeHtml(catName) + "</span><span style='font-size:0.72rem; font-weight:600; color:#64748b; background:#e2e8f0; padding:0.08rem 0.45rem; border-radius:999px;'>" + catItems.length + "</span></h4><ul>";
					catItems.forEach(function(w) {
						var typeBadge = (w.type === "site")
							? "<span style='font-size:0.65rem; font-weight:700; color:#047857; background:rgba(16,185,129,0.12); border:1px solid rgba(16,185,129,0.28); padding:0.05rem 0.35rem; border-radius:4px; margin-left:0.35rem;'>Portal</span>"
							: "";
						html += "<li>" +
							"<a href='" + escapeHtml(w.destinationUrl) + "' target='_blank' rel='noopener noreferrer' title='Open " + escapeHtml(w.destinationUrl) + "'>" + escapeHtml(w.name) + "</a>" +
							typeBadge +
							"<div style='font-size:0.72rem; color:#64748b; margin-top:0.08rem;'>/" + escapeHtml(w.virtualDirectory) + (w.contactName ? " &bull; " + escapeHtml(w.contactName) : "") + "</div>" +
						"</li>";
					});
					html += "</ul>";
					col.innerHTML = html;
					megaGridEl.appendChild(col);
				});
			}
		}

		// 2. Render Two-Tier ChelanCounty.gov Navbar Rollup (Your Government + Community Outreach)
		if (navbarRollupEl) {
			var deptItems = items.filter(function(w) { return w.type !== "site"; });
			var siteItems = items.filter(function(w) { return w.type === "site"; });

			var rollupHtml = "<div style='font-size:0.85rem; font-weight:800; color:#500000; text-transform:uppercase; letter-spacing:0.04em; border-bottom:2px solid #b45309; padding-bottom:0.4rem; margin-bottom:0.75rem;'>Your Government (Departments)</div>";
			if (deptItems.length === 0) {
				rollupHtml += "<p style='color:#64748b; font-size:0.82rem; margin:0 0 1rem 0;'>No department workspaces configured.</p>";
			} else {
				rollupHtml += "<div style='display:grid; grid-template-columns:repeat(auto-fill, minmax(200px, 1fr)); gap:0.45rem 1.25rem; margin-bottom:1rem;'>";
				deptItems.forEach(function(w) {
					rollupHtml += "<a href='" + escapeHtml(w.destinationUrl) + "' target='_blank' rel='noopener noreferrer' style='color:#0f172a; text-decoration:none; font-size:0.86rem; font-weight:500; padding:0.2rem 0; display:flex; align-items:center; justify-content:space-between; border-bottom:1px dashed #e2e8f0;'>" +
						"<span>" + escapeHtml(w.department || w.name) + "</span>" +
						"<code style='font-size:0.7rem; color:#64748b;'>/" + escapeHtml(w.virtualDirectory) + "</code>" +
					"</a>";
				});
				rollupHtml += "</div>";
			}

			rollupHtml += "<hr style='border:0; border-top:1px solid #cbd5e1; margin:1rem 0 0.85rem 0;'>";
			rollupHtml += "<div style='font-size:0.85rem; font-weight:800; color:#047857; text-transform:uppercase; letter-spacing:0.04em; margin-bottom:0.65rem;'>Community Outreach (Sites &amp; Portals)</div>";
			if (siteItems.length === 0) {
				rollupHtml += "<p style='color:#64748b; font-size:0.82rem; margin:0;'>No external site or portal workspaces configured.</p>";
			} else {
				rollupHtml += "<div style='display:grid; grid-template-columns:repeat(auto-fill, minmax(200px, 1fr)); gap:0.45rem 1.25rem;'>";
				siteItems.forEach(function(w) {
					rollupHtml += "<a href='" + escapeHtml(w.destinationUrl) + "' target='_blank' rel='noopener noreferrer' style='color:#0f172a; text-decoration:none; font-size:0.86rem; font-weight:500; padding:0.2rem 0; display:flex; align-items:center; justify-content:space-between; border-bottom:1px dashed #e2e8f0;'>" +
						"<span>" + escapeHtml(w.name) + "</span>" +
						"<code style='font-size:0.7rem; color:#047857;'>/" + escapeHtml(w.virtualDirectory) + "</code>" +
					"</a>";
				});
				rollupHtml += "</div>";
			}
			navbarRollupEl.innerHTML = rollupHtml;
		}

		// 3. Render /departments Directory Page View
		if (sidebarEl && contentEl) {
			sidebarEl.innerHTML = "";
			var sidebarOptions = [{ key: "ALL", label: "All Workspaces", count: items.length }];
			cats.forEach(function(c) {
				var cnt = items.filter(function(w) { return w.category === c; }).length;
				sidebarOptions.push({ key: c, label: c, count: cnt });
			});

			sidebarOptions.forEach(function(opt) {
				var li = document.createElement("li");
				li.style.borderBottom = "1px solid #e2e8f0";
				var btn = document.createElement("button");
				btn.type = "button";
				var isSel = (selectedDirCategory === opt.key);
				btn.style.cssText = "width:100%; text-align:left; padding:0.65rem 0.9rem; border:none; cursor:pointer; font-size:0.86rem; font-weight:" + (isSel ? "700" : "500") + "; background:" + (isSel ? "#0073aa" : "#ffffff") + "; color:" + (isSel ? "#ffffff" : "#0f172a") + "; display:flex; justify-content:space-between; align-items:center;";
				btn.innerHTML = "<span>" + escapeHtml(opt.label) + "</span><span style='font-size:0.74rem; opacity:0.85;'>" + opt.count + "</span>";
				btn.addEventListener("click", function() {
					selectedDirCategory = opt.key;
					renderWorkspaceMegaPreview();
				});
				li.appendChild(btn);
				sidebarEl.appendChild(li);
			});

			var filteredDir = (selectedDirCategory === "ALL")
				? items
				: items.filter(function(w) { return w.category === selectedDirCategory; });
			var headingLabel = (selectedDirCategory === "ALL") ? "All County Departments & Portals" : selectedDirCategory;
			var dirHtml = "<h2 style='margin:0 0 1rem 0; font-size:1.35rem; font-weight:700; color:#0f172a; border-bottom:2px solid #e2e8f0; padding-bottom:0.5rem;'>" + escapeHtml(headingLabel) + "</h2>";

			if (filteredDir.length === 0) {
				dirHtml += "<p style='color:#64748b;'>No workspaces in this category.</p>";
			} else {
				dirHtml += "<div style='display:grid; grid-template-columns:repeat(auto-fill, minmax(280px, 1fr)); gap:0.9rem;'>";
				filteredDir.forEach(function(w) {
					var leaderLabel = (w.leadershipType === "elected") ? "Elected Official" : "Department Head";
					dirHtml += "<div style='background:#f8fafc; border:1px solid #cbd5e1; border-left:4px solid " + escapeHtml(w.color || "#0073aa") + "; border-radius:0.5rem; padding:0.9rem 1rem;'>" +
						"<div style='display:flex; align-items:flex-start; justify-content:space-between; gap:0.5rem; margin-bottom:0.35rem;'>" +
							"<a href='" + escapeHtml(w.destinationUrl) + "' target='_blank' rel='noopener noreferrer' style='font-size:0.95rem; font-weight:700; color:#0073aa; text-decoration:none;'>" + escapeHtml(w.name) + "</a>" +
							"<a href='" + escapeHtml(w.editUrl) + "' class='btn btn-outline-secondary btn-xs' style='font-size:0.68rem; padding:0.1rem 0.45rem; text-decoration:none;'>Edit</a>" +
						"</div>" +
						"<div style='font-size:0.75rem; color:#475569; margin-bottom:0.4rem;'><strong>" + escapeHtml(w.category) + "</strong> &bull; <code>/" + escapeHtml(w.virtualDirectory) + "</code></div>" +
						(w.contactName ? "<div style='font-size:0.8rem; color:#0f172a;'><strong>" + escapeHtml(w.contactName) + "</strong>" + (w.jobTitle ? " &mdash; " + escapeHtml(w.jobTitle) : " (" + leaderLabel + ")") + "</div>" : "") +
						(w.phone ? "<div style='font-size:0.76rem; color:#475569; margin-top:0.2rem;'>Phone: " + escapeHtml(w.phone) + (w.email ? " &bull; " + escapeHtml(w.email) : "") + "</div>" : "") +
						(w.address ? "<div style='font-size:0.74rem; color:#64748b; margin-top:0.15rem;'>" + escapeHtml(w.address) + "</div>" : "") +
					"</div>";
				});
				dirHtml += "</div>";
			}
			contentEl.innerHTML = dirHtml;
		}
	}

	function dismissPageLoaderIfVisible() {
		if (typeof window.hidePageLoader === "function") {
			window.hidePageLoader();
		}
		var loaderOverlay = document.getElementById("adminPageLoadingOverlay");
		if (loaderOverlay) {
			loaderOverlay.classList.remove("is-visible");
		}
	}

	function closeWorkspaceMegaMenuModal() {
		if (!previewModal) return;
		previewModal.classList.remove("is-open");
		dismissPageLoaderIfVisible();
		try {
			var url = new URL(window.location.href);
			if (url.searchParams.has("preview")) {
				url.searchParams.delete("preview");
				window.history.replaceState({}, document.title, url.pathname + (url.search ? url.search : ""));
			}
		} catch (err) {}
	}

	function openWorkspaceMegaMenuModal(defaultTab) {
		if (!previewModal) return;
		dismissPageLoaderIfVisible();
		renderWorkspaceMegaPreview();
		var tabDir = document.getElementById("btnWsPreviewTabDir");
		var tabMega = document.getElementById("btnWsPreviewTabMega");
		var paneDir = document.getElementById("wsPreviewDirectoryPane");
		var paneMega = document.getElementById("wsPreviewMegaPane");
		if (defaultTab === "dir") {
			tabDir.className = "btn btn-xs btn-primary";
			tabMega.className = "btn btn-xs btn-ghost";
			paneDir.style.display = "";
			paneMega.style.display = "none";
		} else {
			tabMega.className = "btn btn-xs btn-primary";
			tabDir.className = "btn btn-xs btn-ghost";
			paneMega.style.display = "";
			paneDir.style.display = "none";
		}
		previewModal.classList.add("is-open");
		setTimeout(dismissPageLoaderIfVisible, 150);
	}

	if (previewModal) {
		var btnOpen = document.getElementById("btnOpenWorkspaceMegaMenuPreview");
		if (btnOpen) {
			btnOpen.addEventListener("click", function(e) {
				e.preventDefault();
				openWorkspaceMegaMenuModal("mega");
			});
		}

		var navSidebarLink = document.getElementById("navLinkWorkspaceMegaMenuPreview");
		if (navSidebarLink) {
			navSidebarLink.setAttribute("data-no-loader", "true");
			navSidebarLink.addEventListener("click", function(e) {
				e.preventDefault();
				e.stopPropagation();
				openWorkspaceMegaMenuModal("mega");
			});
		}

		document.getElementById("btnCloseWsPreviewModal").addEventListener("click", closeWorkspaceMegaMenuModal);
		document.getElementById("btnDismissWsPreviewModal").addEventListener("click", closeWorkspaceMegaMenuModal);
		previewModal.addEventListener("click", function(e) {
			if (e.target === previewModal) closeWorkspaceMegaMenuModal();
		});
		document.addEventListener("keydown", function(e) {
			if (e.key === "Escape" && previewModal.classList.contains("is-open")) {
				closeWorkspaceMegaMenuModal();
			}
		});

		var tabDir = document.getElementById("btnWsPreviewTabDir");
		var tabMega = document.getElementById("btnWsPreviewTabMega");
		var paneDir = document.getElementById("wsPreviewDirectoryPane");
		var paneMega = document.getElementById("wsPreviewMegaPane");

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

		if (cfg.autoOpen) {
			openWorkspaceMegaMenuModal("mega");
		}
	}
})();
</script>
