<cfparam name="notifications" default="#[]#">
<cfparam name="counts" default="#{}#">
<cfparam name="activeFilterType" default="all">
<cfscript>
	if (!structKeyExists(counts, "total")) counts.total = arrayLen(notifications);
	if (!structKeyExists(counts, "forms")) counts.forms = 0;
	if (!structKeyExists(counts, "pages")) counts.pages = 0;
	if (!structKeyExists(counts, "jobs")) counts.jobs = 0;
	if (!structKeyExists(counts, "unread")) counts.unread = 0;
</cfscript>

<cfoutput>
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0.25rem;">Notifications &amp; Activity Center</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item active" aria-current="page">Notifications &amp; Activity</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center;">
		<a href="#urlFor(controller='main', action='index')#" class="btn btn-secondary btn-sm">
			#svgIcon(name="dashboard", size=14)#
			<span>Back to Dashboard</span>
		</a>
		<a href="#urlFor(controller='users', action='profile')#" class="btn btn-outline-secondary btn-sm">
			#svgIcon(name="user", size=14)#
			<span>My Profile</span>
		</a>
	</div>
</div>

<!--- Metric KPI Overview Cards --->
<div class="admin-kpi-grid" style="display:grid; grid-template-columns:repeat(auto-fit, minmax(210px, 1fr)); gap:1rem; margin-bottom:1.5rem;">
	<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
		<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(0,115,170,0.1); color:var(--admin-primary); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			#svgIcon(name="bell", size=22)#
		</div>
		<div>
			<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#counts.total#</div>
			<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">Total Activities</div>
		</div>
	</div>

	<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
		<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(126,34,206,0.1); color:var(--admin-purple); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			#svgIcon(name="form", size=22)#
		</div>
		<div>
			<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#counts.forms#</div>
			<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">Form Submissions</div>
		</div>
	</div>

	<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
		<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(21,128,61,0.1); color:var(--admin-success); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			#svgIcon(name="pages", size=22)#
		</div>
		<div>
			<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#counts.pages#</div>
			<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">Content &amp; Page Updates</div>
		</div>
	</div>

	<cfif isAdmin or isHR>
		<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
			<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(2,132,199,0.1); color:var(--admin-info); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
				#svgIcon(name="briefcase", size=22)#
			</div>
			<div>
				<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#counts.jobs#</div>
				<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">HRM Applications</div>
			</div>
		</div>
	</cfif>
</div>

<!--- Main Notifications Card --->
<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:var(--shadow-sm);">
	<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.75rem;">
		<div style="display:flex; align-items:center; gap:0.75rem;">
			<h2 style="font-size:1rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
				#svgIcon(name="bell", size=18)#
				<span>Recent Notifications &amp; Activity Stream</span>
			</h2>
			<span class="badge badge-primary">#arrayLen(notifications)# Items</span>
		</div>

		<!--- Filter Tabs --->
		<div class="btn-group" role="group" aria-label="Filter Notifications by Type" style="display:flex; gap:2px;">
			<a href="#urlFor(controller='main', action='notifications', params='type=all')#" class="btn btn-sm #(activeFilterType eq 'all' ? 'btn-primary' : 'btn-outline-secondary')#">
				All (#counts.total#)
			</a>
			<a href="#urlFor(controller='main', action='notifications', params='type=form')#" class="btn btn-sm #(activeFilterType eq 'form' ? 'btn-primary' : 'btn-outline-secondary')#">
				Forms (#counts.forms#)
			</a>
			<a href="#urlFor(controller='main', action='notifications', params='type=page')#" class="btn btn-sm #(activeFilterType eq 'page' ? 'btn-primary' : 'btn-outline-secondary')#">
				Pages (#counts.pages#)
			</a>
			<cfif isAdmin or isHR>
				<a href="#urlFor(controller='main', action='notifications', params='type=job')#" class="btn btn-sm #(activeFilterType eq 'job' ? 'btn-primary' : 'btn-outline-secondary')#">
					Jobs (#counts.jobs#)
				</a>
			</cfif>
		</div>
	</div>

	<div class="card-body" style="padding:0;">
		<cfif arrayLen(notifications) gt 0>
			<div class="notification-list" style="display:flex; flex-direction:column;">
				<cfloop array="#notifications#" index="local.n">
					<div class="notification-item" style="display:flex; align-items:flex-start; justify-content:space-between; padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); transition:background 0.15s ease; gap:1rem; #(local.n.isUnread ? 'background:rgba(0,115,170,0.02);' : '')#">
						<div style="display:flex; align-items:flex-start; gap:0.85rem; min-width:0; flex-grow:1;">
							<div class="notif-avatar" style="width:38px; height:38px; border-radius:var(--radius-sm); background:rgba(0,0,0,0.04); display:flex; align-items:center; justify-content:center; color:#local.n.iconColor#; flex-shrink:0;">
								#svgIcon(name=local.n.icon, size=18)#
							</div>
							<div style="min-width:0; flex-grow:1;">
								<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap; margin-bottom:0.2rem;">
									<span style="font-weight:700; font-size:0.875rem; color:var(--admin-text-main);">#local.n.title#</span>
									<span class="badge #local.n.badgeClass#" style="font-size:0.68rem; padding:0.1rem 0.45rem;">#local.n.badgeText#</span>
									<span style="font-size:0.75rem; color:var(--admin-text-muted);">#local.n.category#</span>
								</div>
								<div style="font-size:0.825rem; color:var(--admin-text-muted); line-height:1.4;">
									#local.n.message#
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem; display:flex; align-items:center; gap:0.35rem;">
									#svgIcon(name="clock", size=12)#
									<span>#formatTimeAgo(local.n.createdat)# (#DateFormat(local.n.createdat, "mmm d, yyyy")# at #TimeFormat(local.n.createdat, "h:mm TT")#)</span>
								</div>
							</div>
						</div>

						<div style="flex-shrink:0; display:flex; align-items:center; gap:0.5rem;">
							<a href="#local.n.link#" class="btn btn-outline-primary btn-sm" style="white-space:nowrap; padding:0.3rem 0.75rem; font-size:0.75rem;">
								<span>View Record</span>
								#svgIcon(name="chevron-right", size=12)#
							</a>
						</div>
					</div>
				</cfloop>
			</div>
		<cfelse>
			<div style="padding:3.5rem 1.5rem; text-align:center; color:var(--admin-text-muted);">
				<div style="width:54px; height:54px; border-radius:50%; background:rgba(0,0,0,0.04); display:flex; align-items:center; justify-content:center; margin:0 auto 1rem; color:var(--admin-text-muted);">
					#svgIcon(name="bell", size=24)#
				</div>
				<h3 style="font-size:1.1rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.25rem;">No notifications found</h3>
				<p style="font-size:0.85rem; max-width:420px; margin:0 auto 1.25rem;">There are no notifications matching the selected filter category at this time.</p>
				<a href="#urlFor(controller='main', action='notifications', params='type=all')#" class="btn btn-secondary btn-sm">
					View All Notifications
				</a>
			</div>
		</cfif>
	</div>
</div>
</cfoutput>

