<cfparam name="user" default="#{}#">
<cfparam name="roles" default="#[]#">
<cfparam name="workspaces" default="#[]#">
<cfscript>
	if (!structKeyExists(user, "id")) user.id = 0;
	if (!structKeyExists(user, "first_name")) user.first_name = "Staff";
	if (!structKeyExists(user, "last_name")) user.last_name = "Member";
	if (!structKeyExists(user, "email")) user.email = "staff@chelancounty.gov";
	if (!structKeyExists(user, "username")) user.username = "staff";
	if (!structKeyExists(user, "job_title")) user.job_title = "County Staff";
	if (!structKeyExists(user, "phone")) user.phone = "";
	if (!structKeyExists(user, "role_code")) user.role_code = "author";
	if (!structKeyExists(user, "role_name")) user.role_name = "Author";
	if (!structKeyExists(user, "role_badge")) user.role_badge = "badge-primary";
	if (!structKeyExists(user, "department_name")) user.department_name = "County Administration";
	if (!structKeyExists(user, "department_code")) user.department_code = "global";
	if (!structKeyExists(user, "workspaces") or !isArray(user.workspaces)) {
		user.workspaces = [user.department_code];
	}
	if (!structKeyExists(user, "status")) user.status = "active";
	if (!structKeyExists(user, "two_factor_enabled")) user.two_factor_enabled = false;
	if (!structKeyExists(user, "totp_connected")) user.totp_connected = false;
	if (!structKeyExists(user, "last_login")) user.last_login = "Recently";
	if (!structKeyExists(user, "created_at")) user.created_at = DateFormat(Now(), "mmm d, yyyy");

	userInitials = UCase(Left(user.first_name, 1) & Left(user.last_name, 1));
</cfscript>

<cfoutput>
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0.25rem;">My Profile &amp; Security Settings</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Administration</li>
				<li class="breadcrumb-item active" aria-current="page">My Profile</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center;">
		<a href="#urlFor(controller='main', action='index')#" class="btn btn-secondary btn-sm">
			#svgIcon(name="dashboard", size=14)#
			<span>Dashboard</span>
		</a>
		<a href="#urlFor(controller='users', action='roles')#" class="btn btn-outline-secondary btn-sm">
			#svgIcon(name="security", size=14)#
			<span>Permissions Matrix</span>
		</a>
	</div>
</div>

<!--- Profile Hero Card --->
<div class="admin-card" style="margin-bottom:1.5rem; background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.5rem; box-shadow:var(--shadow-sm);">
	<div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1.25rem;">
		<div style="display:flex; align-items:center; gap:1.25rem;">
			<div class="profile-hero-avatar" style="width:68px; height:68px; border-radius:50%; background:var(--admin-primary); color:##ffffff; display:flex; align-items:center; justify-content:center; font-size:1.6rem; font-weight:700; box-shadow:var(--shadow-sm); flex-shrink:0;">
				#userInitials#
			</div>
			<div>
				<div style="display:flex; align-items:center; gap:0.6rem; flex-wrap:wrap; margin-bottom:0.25rem;">
					<h2 style="font-size:1.35rem; font-weight:700; margin:0; color:var(--admin-text-main);">#user.first_name# #user.last_name#</h2>
					<span class="badge #user.role_badge#" style="font-size:0.75rem; padding:0.15rem 0.6rem;">#user.role_name#</span>
					<span class="badge #(user.status eq 'active' ? 'badge-success' : 'badge-neutral')#" style="font-size:0.75rem;">#UCase(user.status)#</span>
				</div>
				<div style="font-size:0.85rem; color:var(--admin-text-muted); display:flex; align-items:center; gap:0.85rem; flex-wrap:wrap;">
					<span style="display:flex; align-items:center; gap:0.35rem;">
						#svgIcon(name="mail", size=14)#
						<span>#user.email#</span>
					</span>
					<span>&bull;</span>
					<span style="display:flex; align-items:center; gap:0.35rem;">
						#svgIcon(name="briefcase", size=14)#
						<span>#user.job_title#</span>
					</span>
					<span>&bull;</span>
					<span style="display:flex; align-items:center; gap:0.35rem;">
						#svgIcon(name="building", size=14)#
						<span>#user.department_name#</span>
					</span>
				</div>
			</div>
		</div>

		<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
			<a href="#urlFor(controller='sessions', action='destroy')#" class="btn btn-outline-danger btn-sm">
				#svgIcon(name="log-out", size=14)#
				<span>Sign Out</span>
			</a>
		</div>
	</div>
</div>

<style>
.profile-grid {
	display: grid;
	grid-template-columns: 7fr 5fr;
	gap: 1.5rem;
	align-items: start;
}
@media (max-width: 992px) {
	.profile-grid {
		grid-template-columns: 1fr;
	}
}
.form-group-custom {
	margin-bottom: 1rem;
}
.form-group-custom label {
	display: block;
	font-weight: 600;
	font-size: 0.825rem;
	margin-bottom: 0.35rem;
	color: var(--admin-text-main);
}
.form-control-disabled {
	background-color: var(--admin-bg) !important;
	color: var(--admin-text-muted) !important;
	cursor: not-allowed;
	border-color: var(--admin-border) !important;
}
</style>

<div class="profile-grid">
	<!--- Left Column: Editable Profile & Password Cards --->
	<div style="display:flex; flex-direction:column; gap:1.5rem;">
		
		<!--- Card 1: Personal & Contact Information Form --->
		<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:var(--shadow-sm);">
			<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
				<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="user", size=16)#
					<span>Personal &amp; Contact Details</span>
				</h2>
				<span style="font-size:0.75rem; color:var(--admin-text-muted);">Staff ID: ###user.id#</span>
			</div>
			<div class="card-body" style="padding:1.25rem;">
				<form action="#urlFor(controller='users', action='updateProfile')#" method="post">
					#authenticityTokenField()#
					<input type="hidden" name="id" value="#user.id#">

					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div class="form-group-custom">
							<label for="prof_first_name">First Name <span style="color:var(--admin-danger);">*</span></label>
							<input type="text" id="prof_first_name" name="first_name" value="#user.first_name#" required class="form-control" autocomplete="given-name">
						</div>
						<div class="form-group-custom">
							<label for="prof_last_name">Last Name <span style="color:var(--admin-danger);">*</span></label>
							<input type="text" id="prof_last_name" name="last_name" value="#user.last_name#" required class="form-control" autocomplete="family-name">
						</div>
					</div>

					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div class="form-group-custom">
							<label for="prof_job_title">Job Title</label>
							<input type="text" id="prof_job_title" name="job_title" value="#user.job_title#" class="form-control" placeholder="e.g. Senior Planner">
						</div>
						<div class="form-group-custom">
							<label for="prof_phone">Direct Phone / Extension</label>
							<input type="tel" id="prof_phone" name="phone" value="#user.phone#" class="form-control" placeholder="509-667-6000" autocomplete="tel">
						</div>
					</div>

					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div class="form-group-custom">
							<label for="prof_email">Chelan County Email</label>
							<input type="email" id="prof_email" value="#user.email#" class="form-control form-control-disabled" disabled readonly>
							<small style="display:block; font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">
								Official email managed by County IT
							</small>
						</div>
						<div class="form-group-custom">
							<label for="prof_username">Username</label>
							<input type="text" id="prof_username" value="#user.username#" class="form-control form-control-disabled" disabled readonly>
							<small style="display:block; font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">
								System login identifier
							</small>
						</div>
					</div>

					<div style="margin-top:0.5rem; display:flex; justify-content:flex-end;">
						<button type="submit" class="btn btn-primary btn-sm" style="display:flex; align-items:center; gap:0.4rem; padding:0.45rem 1.1rem;">
							#svgIcon(name="check", size=14)#
							<span>Save Profile Changes</span>
						</button>
					</div>
				</form>
			</div>
		</div>

		<!--- Card 2: Passwordless Authentication Overview --->
		<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:var(--shadow-sm);">
			<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
				<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="lock", size=16)#
					<span>Sign-In Security (Passwordless)</span>
				</h2>
				<span class="badge badge-success">Zero Password Risk</span>
			</div>
			<div class="card-body" style="padding:1.25rem;">
				<div style="display:flex; gap:0.85rem; align-items:flex-start; margin-bottom:1rem;">
					<div style="width:38px; height:38px; border-radius:10px; background:rgba(0,115,170,0.1); color:var(--admin-primary); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
						#svgIcon(name="shield", size=20)#
					</div>
					<div>
						<h3 style="font-size:0.9rem; font-weight:700; color:var(--admin-text-main); margin:0 0 0.25rem 0;">Why is there no password to change?</h3>
						<p style="font-size:0.825rem; color:var(--admin-text-muted); line-height:1.5; margin:0;">
							Chelan County CMSAdmin operates exclusively on a <strong>Passwordless 2FA Security Architecture</strong>. Staff accounts authenticate using dynamic one-time passcodes (OTP) delivered to official county email or via paired Microsoft/Google Authenticator apps.
						</p>
					</div>
				</div>

				<div style="background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.85rem 1rem;">
					<div style="font-weight:700; font-size:0.8rem; color:var(--admin-text-main); margin-bottom:0.4rem;">Government Security Benefits:</div>
					<ul style="margin:0; padding-left:1.2rem; font-size:0.78rem; color:var(--admin-text-muted); line-height:1.5;">
						<li><strong>Eliminates Password Compromise:</strong> Static passwords cannot be leaked, phished, or brute-forced.</li>
						<li><strong>County Email Verification:</strong> Access requires live control of your registered <code>@chelancounty.gov</code> inbox.</li>
						<li><strong>Hardware TOTP Protection:</strong> Microsoft and Google Authenticator generate time-sensitive tokens refreshed every 30 seconds.</li>
					</ul>
				</div>
			</div>
		</div>

	</div>

	<!--- Right Column: Security, 2FA & Workspaces --->
	<div style="display:flex; flex-direction:column; gap:1.5rem;">

		<!--- Card 3: Two-Factor Authentication (2FA / TOTP) --->
		<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:var(--shadow-sm);">
			<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
				<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="shield", size=16)#
					<span>Two-Factor Authentication (2FA)</span>
				</h2>
				<cfif user.two_factor_enabled>
					<span class="badge badge-success">Enabled</span>
				<cfelse>
					<span class="badge badge-warning">Disabled</span>
				</cfif>
			</div>
			<div class="card-body" style="padding:1.25rem;">
				<p style="font-size:0.825rem; color:var(--admin-text-muted); line-height:1.45; margin-bottom:1rem;">
					Protect your administrative account with time-based one-time passcodes (TOTP) compatible with Microsoft Authenticator and Google Authenticator.
				</p>

				<div style="padding:0.85rem; border-radius:var(--radius-sm); border:1px solid var(--admin-border); background:var(--admin-bg); display:flex; align-items:center; justify-content:space-between; margin-bottom:1rem;">
					<div style="display:flex; align-items:center; gap:0.65rem;">
						<span style="color:#(user.two_factor_enabled ? 'var(--admin-success)' : 'var(--admin-warning)')#;">
							#svgIcon(name=(user.two_factor_enabled ? "check-circle" : "alert-circle"), size=18)#
						</span>
						<div>
							<div style="font-weight:700; font-size:0.825rem; color:var(--admin-text-main);">
								#(user.two_factor_enabled ? "2FA Verification Active" : "2FA Not Required")#
							</div>
							<div style="font-size:0.75rem; color:var(--admin-text-muted);">
								#(user.totp_connected ? "Paired with Authenticator App" : "Email passcode fallback active")#
							</div>
						</div>
					</div>

					<form action="#urlFor(controller='users', action='toggle2Fa')#" method="post" style="margin:0;">
						#authenticityTokenField()#
						<input type="hidden" name="id" value="#user.id#">
						<button type="submit" class="btn btn-sm #(user.two_factor_enabled ? 'btn-outline-danger' : 'btn-outline-success')#" style="font-size:0.75rem; padding:0.25rem 0.65rem;">
							#(user.two_factor_enabled ? "Disable 2FA" : "Enable 2FA")#
						</button>
					</form>
				</div>

				<a href="#urlFor(controller='sessions', action='connectAuthenticator')#" class="btn btn-outline-primary btn-sm" style="display:flex; align-items:center; justify-content:center; gap:0.4rem; width:100%; text-decoration:none;">
					#svgIcon(name="smartphone", size=14)#
					<span>Pair / Reconfigure Authenticator App</span>
				</a>
			</div>
		</div>

		<!--- Card 4: Assigned Role & Workspace Entitlements --->
		<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:var(--shadow-sm);">
			<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
				<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="grid", size=16)#
					<span>Workspace Entitlements</span>
				</h2>
				<span class="badge #user.role_badge#">#user.role_name#</span>
			</div>
			<div class="card-body" style="padding:1.25rem;">
				<div style="margin-bottom:1rem;">
					<div style="font-weight:700; font-size:0.825rem; color:var(--admin-text-main); margin-bottom:0.25rem;">Primary Department</div>
					<div style="font-size:0.85rem; color:var(--admin-text-muted); display:flex; align-items:center; gap:0.4rem;">
						#svgIcon(name="building", size=14)#
						<span>#user.department_name# (<code>#user.department_code#</code>)</span>
					</div>
				</div>

				<div style="margin-bottom:1rem;">
					<div style="font-weight:700; font-size:0.825rem; color:var(--admin-text-main); margin-bottom:0.45rem;">Assigned Workspaces &amp; Sites</div>
					<div style="display:flex; flex-wrap:wrap; gap:0.4rem;">
						<cfloop array="#user.workspaces#" index="local.wsCode">
							<span class="badge badge-info" style="font-size:0.75rem; padding:0.2rem 0.55rem;">
								#local.wsCode#
							</span>
						</cfloop>
					</div>
				</div>

				<a href="#urlFor(controller='users', action='roles')#" class="btn btn-outline-secondary btn-sm" style="display:flex; align-items:center; justify-content:center; gap:0.4rem; width:100%; text-decoration:none;">
					#svgIcon(name="security", size=14)#
					<span>View Full Permissions Matrix</span>
				</a>
			</div>
		</div>

		<!--- Card 5: Account Telemetry --->
		<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:var(--shadow-sm);">
			<div class="card-header" style="padding:0.85rem 1.25rem; border-bottom:1px solid var(--admin-border);">
				<h2 style="font-size:0.85rem; font-weight:700; margin:0; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.04em;">
					Account Telemetry
				</h2>
			</div>
			<div class="card-body" style="padding:1.25rem; font-size:0.8rem; display:flex; flex-direction:column; gap:0.6rem;">
				<div style="display:flex; justify-content:space-between; align-items:center;">
					<span style="color:var(--admin-text-muted);">Account Created:</span>
					<strong style="color:var(--admin-text-main);">#user.created_at#</strong>
				</div>
				<div style="display:flex; justify-content:space-between; align-items:center;">
					<span style="color:var(--admin-text-muted);">Last Sign-in:</span>
					<strong style="color:var(--admin-text-main);">#user.last_login#</strong>
				</div>
				<div style="display:flex; justify-content:space-between; align-items:center;">
					<span style="color:var(--admin-text-muted);">Account Status:</span>
					<strong style="color:var(--admin-success);">#UCase(user.status)#</strong>
				</div>
			</div>
		</div>

	</div>
</div>
</cfoutput>

