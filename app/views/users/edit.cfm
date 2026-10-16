<cfparam name="roles" default="#[]#">
<cfparam name="departments" default="#[]#">
<cfparam name="workspaces" default="#[]#">
<cfparam name="user" default="#{}#">
<cfscript>
	if (!structKeyExists(user, "id")) user.id = 0;
	if (!structKeyExists(user, "first_name")) user.first_name = "Staff";
	if (!structKeyExists(user, "last_name")) user.last_name = "Member";
	if (!structKeyExists(user, "email")) user.email = "";
	if (!structKeyExists(user, "username")) user.username = "";
	if (!structKeyExists(user, "job_title")) user.job_title = "";
	if (!structKeyExists(user, "phone")) user.phone = "";
	if (!structKeyExists(user, "role_code")) user.role_code = "author";
	if (!structKeyExists(user, "department_code")) user.department_code = "global";
	if (!structKeyExists(user, "workspaces") or !isArray(user.workspaces)) {
		user.workspaces = structKeyExists(user, "department_code") ? [user.department_code] : ["global"];
	}
	if (!structKeyExists(user, "status")) user.status = "active";
	if (!structKeyExists(user, "two_factor_enabled")) user.two_factor_enabled = false;
	if (!structKeyExists(user, "last_login")) user.last_login = "Never";
	if (!structKeyExists(user, "created_at")) user.created_at = DateFormat(Now(), "mmm d, yyyy");
	if (arrayLen(workspaces) eq 0 and arrayLen(departments) gt 0) workspaces = departments;
</cfscript>
<cfset pageTitle = "Edit User - " & user.first_name & " " & user.last_name>
<cfoutput>
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0.25rem;">Edit User: #user.first_name# #user.last_name#</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Administration</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='users', action='index')#">Users &amp; Roles</a></li>
				<li class="breadcrumb-item active" aria-current="page">Edit #user.first_name# #user.last_name#</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center;">
		<a href="#urlFor(controller='users', action='index')#" class="btn btn-secondary btn-sm">
			#svgIcon(name="users", size=14)#
			<span>Back to Directory</span>
		</a>
		<a href="#urlFor(controller='users', action='roles')#" class="btn btn-outline-secondary btn-sm">
			#svgIcon(name="security", size=14)#
			<span>Permissions Matrix</span>
		</a>
	</div>
</div>

<style>
.user-form-grid {
	display: grid;
	grid-template-columns: repeat(12, 1fr);
	gap: 1.5rem;
	align-items: stretch;
}
.col-6 {
	grid-column: span 6;
}
.col-12 {
	grid-column: span 12;
}
@media (max-width: 992px) {
	.col-6 {
		grid-column: span 12 !important;
	}
}
</style>

<form action="#urlFor(controller='users', action='update')#" method="post" class="user-form">
	#authenticityTokenField()#
	<input type="hidden" name="id" value="#user.id#">

	<div class="user-form-grid">
			
			<!--- Card 1: Staff Profile Details (6-col) --->
			<div class="admin-card col-6" style="display:flex; flex-direction:column;">
				<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
					<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
						#svgIcon(name="user", size=16)#
						<span>Profile Information (User ID: &##35;#user.id#)</span>
					</h2>
					<span class="badge #(user.status eq 'active' ? 'badge-success' : 'badge-neutral')#">#UCase(user.status)#</span>
				</div>
				<div class="card-body" style="padding:1.25rem; display:flex; flex-direction:column; gap:1rem;">
					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div>
							<label for="edit_first_name" class="form-label" style="font-weight:600; font-size:0.825rem;">First Name <span style="color:var(--admin-danger);">*</span></label>
							<input type="text" id="edit_first_name" name="first_name" required value="#user.first_name#" class="form-control" autocomplete="given-name">
						</div>
						<div>
							<label for="edit_last_name" class="form-label" style="font-weight:600; font-size:0.825rem;">Last Name <span style="color:var(--admin-danger);">*</span></label>
							<input type="text" id="edit_last_name" name="last_name" required value="#user.last_name#" class="form-control" autocomplete="family-name">
						</div>
					</div>

					<div style="display:grid; grid-template-columns:1.2fr 0.8fr; gap:1rem;">
						<div>
							<label for="edit_email" class="form-label" style="font-weight:600; font-size:0.825rem;">Chelan County Email <span style="color:var(--admin-danger);">*</span></label>
							<input type="email" id="edit_email" name="email" required value="#user.email#" class="form-control" autocomplete="email">
						</div>
						<div>
							<label for="edit_username" class="form-label" style="font-weight:600; font-size:0.825rem;">Username <span style="color:var(--admin-danger);">*</span></label>
							<input type="text" id="edit_username" name="username" required value="#user.username#" class="form-control" autocomplete="username">
							<div class="pg-help" style="margin-top:0.25rem;">Admin editable account login identifier.</div>
						</div>
					</div>

					<div style="display:grid; grid-template-columns:1.2fr 0.8fr; gap:1rem;">
						<div>
							<label for="edit_job_title" class="form-label" style="font-weight:600; font-size:0.825rem;">Job Title</label>
							<input type="text" id="edit_job_title" name="job_title" value="#user.job_title#" class="form-control">
						</div>
						<div>
							<label for="edit_phone" class="form-label" style="font-weight:600; font-size:0.825rem;">Office Phone</label>
							<input type="tel" id="edit_phone" name="phone" value="#user.phone#" class="form-control" autocomplete="tel">
						</div>
					</div>
				</div>
			</div>

			<!--- Card 2: 4 User Groups / Role Selection (6-col) --->
			<div class="admin-card col-6" style="display:flex; flex-direction:column;">
				<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border);">
					<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
						#svgIcon(name="security", size=16)#
						<span>User Group &amp; Role Permissions</span>
					</h2>
				</div>
				<div class="card-body" style="padding:1.25rem; display:flex; flex-direction:column; gap:1rem; flex:1;">
					<div class="pg-help">Select the staff member’s operational access group:</div>

					<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.85rem;" id="editRoleGrid">
						<!--- Admin Option --->
						<label class="role-select-box" style="border:2px solid #(user.role_code eq 'admin' ? 'var(--admin-primary)' : 'var(--admin-border)')#; background:#(user.role_code eq 'admin' ? 'var(--admin-primary-light)' : 'var(--admin-surface)')#; border-radius:var(--radius-md); padding:1rem; cursor:pointer; display:flex; gap:0.75rem; transition:all 0.15s ease;">
							<input type="radio" name="role_code" value="admin" #(user.role_code eq 'admin' ? 'checked' : '')# style="margin-top:3px;" onchange="setEditRoleSummary('admin')">
							<div>
								<div style="display:flex; align-items:center; gap:0.4rem;">
									<span class="badge badge-danger">Admin</span>
									<span style="font-weight:700; font-size:0.875rem; color:var(--admin-text-main);">Administrator</span>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem; line-height:1.4;">
									Administrator will have <strong>everything</strong>: Content, HRM, PIO, Navigation, and Administration.
								</div>
							</div>
						</label>

						<!--- PIO Option --->
						<label class="role-select-box" style="border:2px solid #(user.role_code eq 'pio' ? 'var(--admin-primary)' : 'var(--admin-border)')#; background:#(user.role_code eq 'pio' ? 'var(--admin-primary-light)' : 'var(--admin-surface)')#; border-radius:var(--radius-md); padding:1rem; cursor:pointer; display:flex; gap:0.75rem; transition:all 0.15s ease;">
							<input type="radio" name="role_code" value="pio" #(user.role_code eq 'pio' ? 'checked' : '')# style="margin-top:3px;" onchange="setEditRoleSummary('pio')">
							<div>
								<div style="display:flex; align-items:center; gap:0.4rem;">
									<span class="badge badge-info">PIO</span>
									<span style="font-weight:700; font-size:0.875rem; color:var(--admin-text-main);">PIO</span>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem; line-height:1.4;">
									Will have <strong>Content Management and PIO Group</strong> (Articles, Alerts, Press).
								</div>
							</div>
						</label>

						<!--- HR Option --->
						<label class="role-select-box" style="border:2px solid #(user.role_code eq 'hr' ? 'var(--admin-primary)' : 'var(--admin-border)')#; background:#(user.role_code eq 'hr' ? 'var(--admin-primary-light)' : 'var(--admin-surface)')#; border-radius:var(--radius-md); padding:1rem; cursor:pointer; display:flex; gap:0.75rem; transition:all 0.15s ease;">
							<input type="radio" name="role_code" value="hr" #(user.role_code eq 'hr' ? 'checked' : '')# style="margin-top:3px;" onchange="setEditRoleSummary('hr')">
							<div>
								<div style="display:flex; align-items:center; gap:0.4rem;">
									<span class="badge badge-purple">HR</span>
									<span style="font-weight:700; font-size:0.875rem; color:var(--admin-text-main);">HR</span>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem; line-height:1.4;">
									Update to <strong>Content Management and HRM</strong> (Jobs, Onboarding, Policies).
								</div>
							</div>
						</label>

						<!--- Author Option --->
						<label class="role-select-box" style="border:2px solid #(user.role_code eq 'author' ? 'var(--admin-primary)' : 'var(--admin-border)')#; background:#(user.role_code eq 'author' ? 'var(--admin-primary-light)' : 'var(--admin-surface)')#; border-radius:var(--radius-md); padding:1rem; cursor:pointer; display:flex; gap:0.75rem; transition:all 0.15s ease;">
							<input type="radio" name="role_code" value="author" #(user.role_code eq 'author' ? 'checked' : '')# style="margin-top:3px;" onchange="setEditRoleSummary('author')">
							<div>
								<div style="display:flex; align-items:center; gap:0.4rem;">
									<span class="badge badge-primary">Author</span>
									<span style="font-weight:700; font-size:0.875rem; color:var(--admin-text-main);">Author</span>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem; line-height:1.4;">
									General web update &bull; Access to <strong>Content Management Group</strong> only.
								</div>
							</div>
						</label>
					</div>

					<div id="editRoleFeedback" style="background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1rem; font-size:0.825rem; margin-top:auto;">
						<div style="font-weight:700; color:var(--admin-text-main); margin-bottom:0.35rem; display:flex; align-items:center; gap:0.5rem;">
							#svgIcon(name="info", size=16)#
							<span id="editFeedbackTitle">
								<cfif user.role_code eq "admin">Administrator Access:
								<cfelseif user.role_code eq "pio">PIO Access:
								<cfelseif user.role_code eq "hr">HR Access:
								<cfelse>Author (General Web Update) Access:
								</cfif>
							</span>
						</div>
						<div id="editFeedbackDetail" style="color:var(--admin-text-muted); line-height:1.5;">
							<cfif user.role_code eq "admin">
								Administrator will have <strong>everything</strong>: full access across Content Management, HRM, PIO, Navigation Menus, and System Administration.
							<cfelseif user.role_code eq "pio">
								Access to <strong>Content Management Group</strong> + <strong>PIO Group</strong> (Articles, Alerts, Press Releases). Restricted from HRM and Administration.
							<cfelseif user.role_code eq "hr">
								Access to <strong>Content Management Group</strong> + <strong>HRM Group</strong> (Job Postings, Onboarding, Personnel Policies). Restricted from PIO and Administration.
							<cfelse>
								Author is general web update &bull; Access to <strong>Content Management Group</strong> only (Pages, Media Library, Form Builder/Forms, Feedback &amp; Inquiries).
							</cfif>
						</div>
					</div>
				</div>
			</div>

			<!--- Card 3: Assigned Workspaces & Sites (12-col full width) --->
			<div class="admin-card col-12">
				<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
					<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
						#svgIcon(name="building", size=16)#
						<span>Assigned Workspaces &amp; Sites</span>
					</h2>
					<span class="badge badge-primary" id="editWsSelectedCount">#(arrayFindNoCase(user.workspaces, 'global') ? 'All Workspaces (Global)' : ArrayLen(user.workspaces) & ' Selected')#</span>
				</div>
				<div class="card-body" style="padding:1.25rem; display:flex; flex-direction:column; gap:1.25rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.5rem;">
						<div class="pg-help" style="margin:0;">A user can be assigned to multiple workspaces and portals. Select all that apply:</div>
						<div style="display:flex; gap:0.35rem;">
							<button type="button" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem; padding:0.2rem 0.5rem;" onclick="selectAllEditWorkspaces('dept')">All Departments</button>
							<button type="button" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem; padding:0.2rem 0.5rem;" onclick="selectAllEditWorkspaces('site')">All Sites</button>
							<button type="button" class="btn btn-outline-secondary btn-sm" style="font-size:0.75rem; padding:0.2rem 0.5rem;" onclick="clearAllEditWorkspaces()">Clear</button>
						</div>
					</div>

					<!--- Master Global Scope Option --->
					<label class="workspace-select-box" style="border:1.5px solid #(arrayFindNoCase(user.workspaces, 'global') ? 'var(--admin-primary)' : 'var(--admin-border)')#; background:#(arrayFindNoCase(user.workspaces, 'global') ? 'var(--admin-primary-light)' : 'var(--admin-bg)')#; border-radius:var(--radius-md); padding:0.85rem 1rem; cursor:pointer; display:flex; gap:0.75rem; align-items:center; transition:all 0.15s ease;">
						<input type="checkbox" name="workspaces" value="global" id="edit_ws_global" #(arrayFindNoCase(user.workspaces, 'global') ? 'checked' : '')# onchange="toggleEditGlobalWorkspace(this)" style="width:17px; height:17px; margin:0;">
						<div style="flex:1;">
							<div style="display:flex; align-items:center; gap:0.5rem;">
								<span style="color:var(--admin-primary);">#svgIcon(name="grid", size=16)#</span>
								<strong style="font-size:0.875rem; color:var(--admin-text-main);">All Workspaces (Global Overview)</strong>
								<span class="badge badge-neutral">Full Scope</span>
							</div>
							<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
								Grants user county-wide content editing, media uploads, and form permissions across all departments and public websites.
							</div>
						</div>
					</label>

					<!--- Section 1: County Departments & Divisions --->
					<div>
						<div style="font-weight:700; font-size:0.8rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-subtle); margin-bottom:0.65rem; display:flex; align-items:center; gap:0.4rem;">
							#svgIcon(name="building", size=14)#
							<span>County Departments &amp; Divisions</span>
						</div>
						<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.65rem;" id="editDeptWorkspacesGrid">
							<cfloop array="#workspaces#" index="ws">
								<cfif ws.type eq "dept">
									<cfset isAssigned = arrayFindNoCase(user.workspaces, ws.code) 
										or arrayFindNoCase(user.workspaces, "global") 
										or (structKeyExists(ws, "alias") and len(trim(ws.alias)) and arrayFindNoCase(user.workspaces, trim(ws.alias)))
										or (ws.code eq "human-resources" and arrayFindNoCase(user.workspaces, "hrm"))
										or (ws.code eq "communications" and arrayFindNoCase(user.workspaces, "pio"))
										or (ws.code eq "assessor" and arrayFindNoCase(user.workspaces, "assessors"))
										or (ws.code eq "commdev" and arrayFindNoCase(user.workspaces, "community-development"))>
									<label class="workspace-item-checkbox" style="border:1px solid #(isAssigned ? 'var(--admin-primary)' : 'var(--admin-border)')#; background:#(isAssigned ? 'var(--admin-primary-light)' : 'var(--admin-surface)')#; border-radius:var(--radius-sm); padding:0.6rem 0.75rem; cursor:pointer; display:flex; gap:0.55rem; align-items:center; transition:all 0.15s ease;">
										<input type="checkbox" name="workspaces" value="#ws.code#" class="edit-ws-dept-check" #(isAssigned ? 'checked' : '')# onchange="updateEditWorkspaceCardState(this)" style="width:16px; height:16px; margin:0;">
										<span style="color:var(--admin-text-muted);">#svgIcon(name=ws.icon, size=15)#</span>
										<div style="flex:1; min-width:0;">
											<div style="font-weight:600; font-size:0.8rem; color:var(--admin-text-main); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">#ws.name#</div>
										</div>
										<span class="badge #ws.badgeClass#" style="font-size:0.68rem; padding:0.1rem 0.4rem;">#ws.badge#</span>
									</label>
								</cfif>
							</cfloop>
						</div>
					</div>

					<!--- Section 2: Public Portals & Sites --->
					<div>
						<div style="font-weight:700; font-size:0.8rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-subtle); margin-bottom:0.65rem; display:flex; align-items:center; gap:0.4rem;">
							#svgIcon(name="globe", size=14)#
							<span>Public Portals &amp; Web Sites</span>
						</div>
						<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.65rem;" id="editSiteWorkspacesGrid">
							<cfloop array="#workspaces#" index="ws">
								<cfif ws.type eq "site">
									<cfset isAssigned = arrayFindNoCase(user.workspaces, ws.code) 
										or arrayFindNoCase(user.workspaces, "global") 
										or (structKeyExists(ws, "alias") and len(trim(ws.alias)) and arrayFindNoCase(user.workspaces, trim(ws.alias)))>
									<label class="workspace-item-checkbox" style="border:1px solid #(isAssigned ? 'var(--admin-primary)' : 'var(--admin-border)')#; background:#(isAssigned ? 'var(--admin-primary-light)' : 'var(--admin-surface)')#; border-radius:var(--radius-sm); padding:0.6rem 0.75rem; cursor:pointer; display:flex; gap:0.55rem; align-items:center; transition:all 0.15s ease;">
										<input type="checkbox" name="workspaces" value="#ws.code#" class="edit-ws-site-check" #(isAssigned ? 'checked' : '')# onchange="updateEditWorkspaceCardState(this)" style="width:16px; height:16px; margin:0;">
										<span style="color:var(--admin-text-muted);">#svgIcon(name="globe", size=15)#</span>
										<div style="flex:1; min-width:0;">
											<div style="font-weight:600; font-size:0.8rem; color:var(--admin-text-main); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">#ws.name#</div>
										</div>
										<span class="badge #ws.badgeClass#" style="font-size:0.68rem; padding:0.1rem 0.4rem;">#ws.badge#</span>
									</label>
								</cfif>
							</cfloop>
						</div>
					</div>

				</div>
			</div>

			<!--- Card 4: Primary Home Department (6-col) --->
			<div class="admin-card col-6" style="display:flex; flex-direction:column;">
				<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border);">
					<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
						#svgIcon(name="building", size=16)#
						<span>Primary Home Department</span>
					</h2>
				</div>
				<div class="card-body" style="padding:1.25rem; display:flex; flex-direction:column; gap:1rem; flex:1;">
					<div>
						<label for="edit_department_code" class="form-label" style="font-weight:600; font-size:0.825rem;">Default Home Workspace</label>
						<select id="edit_department_code" name="department_code" class="form-control">
							<cfloop array="#workspaces#" index="d">
								<option value="#d.code#" #(user.department_code eq d.code ? 'selected' : '')#>#d.name#</option>
							</cfloop>
						</select>
						<div class="pg-help" style="margin-top:0.35rem;">Used as staff profile home department label and initial landing scope.</div>
					</div>

					<div>
						<label for="edit_status" class="form-label" style="font-weight:600; font-size:0.825rem;">Account Status</label>
						<select id="edit_status" name="status" class="form-control">
							<option value="active" #(user.status eq 'active' ? 'selected' : '')#>Active</option>
							<option value="inactive" #(user.status eq 'inactive' ? 'selected' : '')#>Inactive</option>
						</select>
					</div>
				</div>
				<div class="card-footer" style="padding:1rem 1.25rem; background:var(--admin-bg); border-top:1px solid var(--admin-border); font-size:0.75rem; color:var(--admin-text-muted); display:flex; align-items:center; min-height:57px; box-sizing:border-box;">
					<span>Staff ID: CC-USER-#user.id# &bull; Chelan County</span>
				</div>
			</div>

			<!--- Card 5: Credentials & Security (6-col) --->
			<div class="admin-card col-6" style="display:flex; flex-direction:column;">
				<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border);">
					<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
						#svgIcon(name="lock", size=16)#
						<span>Credentials &amp; Security</span>
					</h2>
				</div>
				<div class="card-body" style="padding:1.25rem; display:flex; flex-direction:column; gap:1rem; flex:1;">
					<div style="font-size:0.8rem; color:var(--admin-text-muted); line-height:1.45;">
						<div><strong>Last Login:</strong> #user.last_login#</div>
						<div style="margin-top:0.25rem;"><strong>Created:</strong> #user.created_at#</div>
					</div>

					<div style="padding-top:0.5rem; border-top:1px solid var(--admin-border-subtle);">
						<label style="display:flex; align-items:flex-start; gap:0.5rem; cursor:pointer; font-size:0.825rem;">
							<input type="checkbox" name="two_factor_enabled" value="1" #(user.two_factor_enabled ? 'checked' : '')# style="margin-top:2px;">
							<span>Require Two-Factor Authentication (2FA)</span>
						</label>
					</div>
				</div>

				<div class="card-footer" style="padding:1rem 1.25rem; background:var(--admin-bg); border-top:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; min-height:57px; box-sizing:border-box;">
					<a href="#urlFor(controller='users', action='index')#" class="btn btn-secondary btn-sm">Cancel</a>
					<button type="submit" class="btn btn-primary btn-sm">
						#svgIcon(name="save", size=15)#
						<span>Save Changes</span>
					</button>
				</div>
			</div>

	</div>
</form>
</cfoutput>

<script>
function setEditRoleSummary(role) {
	const boxes = document.querySelectorAll("#editRoleGrid .role-select-box");
	boxes.forEach(b => {
		const rad = b.querySelector("input[type='radio']");
		if (rad && rad.value === role) {
			b.style.borderColor = "var(--admin-primary)";
			b.style.background = "var(--admin-primary-light)";
		} else {
			b.style.borderColor = "var(--admin-border)";
			b.style.background = "var(--admin-surface)";
		}
	});

	const titleEl = document.getElementById("editFeedbackTitle");
	const detailEl = document.getElementById("editFeedbackDetail");

	if (role === "admin") {
		titleEl.textContent = "Administrator Access:";
		detailEl.innerHTML = "Administrator will have <strong>everything</strong>: unrestricted access to Content Management, HRM Group, PIO Group, Administration, Navigation Menus, and System Settings.";
	} else if (role === "pio") {
		titleEl.textContent = "PIO Access:";
		detailEl.innerHTML = "Access to <strong>Content Management Group</strong> (Pages, Media, Forms) + <strong>PIO Group</strong> (Articles &amp; Posts, Press Releases, Media Alerts, PRR). Locked out of HRM and Administration.";
	} else if (role === "hr") {
		titleEl.textContent = "HR Access:";
		detailEl.innerHTML = "Access to <strong>Content Management Group</strong> (Pages, Media, Forms) + <strong>HRM Group</strong> (Job Postings, Onboarding, Personnel Policies, HRM Inquiries). Locked out of PIO and Administration.";
	} else {
		titleEl.textContent = "Author (General Web Update) Access:";
		detailEl.innerHTML = "Author is general web update &bull; Access to <strong>Content Management Group</strong> only (Pages, Media Library, Form Builder/Forms, Feedback &amp; Inquiries). Locked out of HRM, PIO, and Administration.";
	}
}

function toggleEditGlobalWorkspace(chk) {
	const allDept = document.querySelectorAll(".edit-ws-dept-check");
	const allSite = document.querySelectorAll(".edit-ws-site-check");
	if (chk.checked) {
		allDept.forEach(c => { c.checked = true; updateEditWorkspaceCardVisual(c); });
		allSite.forEach(c => { c.checked = true; updateEditWorkspaceCardVisual(c); });
	}
	updateEditWorkspaceCardVisual(chk);
	updateEditWorkspaceCount();
}

function selectAllEditWorkspaces(type) {
	if (type === 'dept') {
		document.querySelectorAll(".edit-ws-dept-check").forEach(c => { c.checked = true; updateEditWorkspaceCardVisual(c); });
	} else if (type === 'site') {
		document.querySelectorAll(".edit-ws-site-check").forEach(c => { c.checked = true; updateEditWorkspaceCardVisual(c); });
	}
	updateEditWorkspaceCount();
}

function clearAllEditWorkspaces() {
	const glob = document.getElementById("edit_ws_global");
	if (glob) { glob.checked = false; updateEditWorkspaceCardVisual(glob); }
	document.querySelectorAll(".edit-ws-dept-check, .edit-ws-site-check").forEach(c => {
		c.checked = false;
		updateEditWorkspaceCardVisual(c);
	});
	updateEditWorkspaceCount();
}

function updateEditWorkspaceCardState(chk) {
	updateEditWorkspaceCardVisual(chk);
	const glob = document.getElementById("edit_ws_global");
	if (!chk.checked && glob) {
		glob.checked = false;
		updateEditWorkspaceCardVisual(glob);
	}
	updateEditWorkspaceCount();
}

function updateEditWorkspaceCardVisual(chk) {
	const label = chk.closest("label");
	if (!label) return;
	if (chk.checked) {
		label.style.borderColor = "var(--admin-primary)";
		label.style.background = "var(--admin-primary-light)";
	} else {
		label.style.borderColor = "var(--admin-border)";
		label.style.background = "var(--admin-surface)";
	}
}

function updateEditWorkspaceCount() {
	const checked = document.querySelectorAll("input[name='workspaces']:checked");
	const glob = document.getElementById("edit_ws_global");
	const badge = document.getElementById("editWsSelectedCount");
	if (badge) {
		if (glob && glob.checked) {
			badge.textContent = "All Workspaces (Global)";
		} else {
			badge.textContent = checked.length + " Selected";
		}
	}
}
</script>
