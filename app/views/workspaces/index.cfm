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
								<cfif Len(local.contactFullName)>
									<div style="font-weight:600; color:var(--admin-text-main); font-size:0.82rem; display:flex; align-items:center; gap:0.35rem;">
										#svgIcon(name="user", size=12)#
										<span>#EncodeForHTML(local.contactFullName)#</span>
									</div>
								<cfelse>
									<div style="color:var(--admin-text-muted); font-size:0.78rem; font-style:italic;">No contact designated</div>
								</cfif>

								<cfif Len(local.contactEmail)>
									<div style="margin-top:0.25rem; font-size:0.76rem;">
										<a href="mailto:#EncodeForHTMLAttribute(local.contactEmail)#" style="color:var(--admin-primary); text-decoration:none; display:inline-flex; align-items:center; gap:0.3rem;">
											#svgIcon(name="mail", size=11)#
											<span>#EncodeForHTML(local.contactEmail)#</span>
										</a>
									</div>
								</cfif>

								<cfif Len(local.contactPhone)>
									<div style="margin-top:0.15rem; font-size:0.75rem; color:var(--admin-text-muted); display:inline-flex; align-items:center; gap:0.3rem;">
										#svgIcon(name="phone", size=11)#
										<a href="tel:#EncodeForHTMLAttribute(local.contactPhone)#" style="color:var(--admin-text-muted); text-decoration:none;">#EncodeForHTML(local.contactPhone)#</a>
										<cfif Len(local.contactFax)>
											<span style="font-size:0.7rem;">(Fax: #EncodeForHTML(local.contactFax)#)</span>
										</cfif>
									</div>
								</cfif>
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
												<span class="ws-detail-label">Storage Root:</span>
												<span class="ws-detail-val"><code>files/#EncodeForHTML(local.virtualDir)#</code></span>
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
</cfoutput>
