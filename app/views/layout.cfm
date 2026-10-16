<cfif application.contentOnly or (structKeyExists(params, "controller") and ((params.controller eq "forms" and structKeyExists(params, "action") and params.action eq "preview") or params.controller eq "sessions"))>
	<cfoutput>
		#flashMessages(encode=false)#
		#includeContent()#
	</cfoutput>
<cfelse>
	<!DOCTYPE html>
	<html lang="en">
		<head>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<title><cfoutput>#(structKeyExists(variables, "pageTitle") ? variables.pageTitle & " - " : "")#CMS Admin</cfoutput></title>
			<cfoutput>#csrfMetaTags()#</cfoutput>
			
			<!--- Google Font Plus Jakarta Sans & Mada for crisp typography --->
			<link rel="preconnect" href="https://fonts.googleapis.com">
			<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
			<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">

			<!--- Chelan County Logo & favicon --->
			<link rel="icon" type="image/png" href="/images/logo.png">
			<link rel="apple-touch-icon" href="/images/logo.png">

			<!--- Google Material Symbols for JBDEditor & Modern UI --->
			<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200">

			<!--- Our custom CMS Admin stylesheet inspired by Mashable Light --->
			<link href="/stylesheets/admin-theme.css?v=3.0" media="all" rel="stylesheet" type="text/css">
			<link href="/stylesheets/jbdeditor.css?v=1.6" media="all" rel="stylesheet" type="text/css">
			<link href="/stylesheets/jbd-templates.css?v=1.2" media="all" rel="stylesheet" type="text/css">
			<cfif structKeyExists(params, "controller") and params.controller eq "forms">
				<link href="/stylesheets/form-builder.css?v=2.3" media="all" rel="stylesheet" type="text/css">
			</cfif>
			<style>
				.admin-prompt-backdrop {
					position:fixed;
					inset:0;
					z-index:100000;
					display:none;
					align-items:center;
					justify-content:center;
					padding:1rem;
					background:rgba(15, 23, 42, 0.72);
					backdrop-filter:blur(6px);
					-webkit-backdrop-filter:blur(6px);
				}
				.admin-prompt-backdrop.is-open { display:flex; }
				.admin-prompt-dialog {
					width:min(100%, 460px);
					padding:1.4rem 1.5rem;
					border:1px solid var(--admin-border);
					border-top:4px solid var(--admin-primary);
					border-radius:var(--radius-lg);
					background:var(--admin-surface);
					box-shadow:var(--shadow-dropdown);
					color:var(--admin-text-main);
					animation:adminPromptEnter 0.16s ease-out;
					transition:border-color 0.2s ease;
				}
				.admin-prompt-header {
					display:flex;
					align-items:center;
					gap:0.75rem;
					margin-bottom:0.65rem;
				}
				.admin-prompt-icon {
					width:36px;
					height:36px;
					border-radius:50%;
					display:flex;
					align-items:center;
					justify-content:center;
					flex-shrink:0;
					background:var(--admin-info-light);
					color:var(--admin-info);
				}
				.admin-prompt-title { margin:0; font-size:1.1rem; font-weight:700; line-height:1.3; }
				.admin-prompt-message { margin:0 0 1.35rem; color:var(--admin-text-muted); line-height:1.55; white-space:pre-wrap; overflow-wrap:anywhere; font-size:0.92rem; }
				.admin-prompt-actions { display:flex; justify-content:flex-end; gap:0.65rem; }

				/* Color Coded Tone Variants */
				.admin-prompt--success {
					border-top-color: var(--admin-success);
				}
				.admin-prompt--success .admin-prompt-icon {
					background: var(--admin-success-light);
					color: var(--admin-success);
				}
				.admin-prompt--success .admin-prompt-title {
					color: #14532d;
				}

				.admin-prompt--danger {
					border-top-color: var(--admin-danger);
				}
				.admin-prompt--danger .admin-prompt-icon {
					background: var(--admin-danger-light);
					color: var(--admin-danger);
				}
				.admin-prompt--danger .admin-prompt-title {
					color: #991b1b;
				}

				.admin-prompt--warning {
					border-top-color: var(--admin-warning);
				}
				.admin-prompt--warning .admin-prompt-icon {
					background: var(--admin-warning-light);
					color: var(--admin-warning);
				}
				.admin-prompt--warning .admin-prompt-title {
					color: #854d0e;
				}

				.admin-prompt--info {
					border-top-color: var(--admin-info);
				}
				.admin-prompt--info .admin-prompt-icon {
					background: var(--admin-info-light);
					color: var(--admin-info);
				}
				.admin-prompt--info .admin-prompt-title {
					color: #075985;
				}
				@keyframes adminPromptEnter {
					from { opacity:0; transform:translateY(8px) scale(0.98); }
					to { opacity:1; transform:translateY(0) scale(1); }
				}
				@media (prefers-reduced-motion: reduce) {
					.admin-prompt-dialog { animation:none; }
				}
			</style>
		</head>

		<body>
			<cfscript>
				realUserRole = getAuthenticatedUserRole();
				userIsRealAdmin = isRealAdmin();

				if (userIsRealAdmin) {
					activeRole = "admin";
					if (structKeyExists(cookie, "cmsadmin_simulated_role") and len(cookie.cmsadmin_simulated_role)) {
						activeRole = lCase(cookie.cmsadmin_simulated_role);
					} else if (structKeyExists(session, "simulatedRole") and len(session.simulatedRole)) {
						activeRole = lCase(session.simulatedRole);
					}
				} else {
					// Non-admin groups are strictly locked to their genuine assigned role
					activeRole = realUserRole;
				}
				if (!listFind("admin,pio,hr,author", activeRole)) activeRole = "admin";

				isAuthor = (activeRole eq "author");
				isHR = (activeRole eq "hr");
				isPIO = (activeRole eq "pio");
				isAdmin = (activeRole eq "admin");
				isSimulatingRole = (userIsRealAdmin and (activeRole neq "admin"));

				// Default simulated persona values
				curUserName = "Sarah Jenkins";
				curUserRole = "Administrator";
				curUserBadge = "badge-danger";
				curUserInitials = "SJ";
				curUserEmail = "sarah.jenkins@chelancounty.gov";

				// When authenticated via live user database session, prioritize real retrieved user data!
				if (structKeyExists(session, "user") and isStruct(session.user)) {
					curUserName = len(session.user.full_name ?: "") ? session.user.full_name : (session.user.first_name & " " & session.user.last_name);
					curUserRole = len(session.user.role_name ?: "") ? session.user.role_name : (isAdmin ? "Administrator" : (isHR ? "Human Resources" : (isPIO ? "Public Information" : "Author")));
					curUserBadge = len(session.user.role_badge ?: "") ? session.user.role_badge : (isAdmin ? "badge-danger" : (isHR ? "badge-purple" : (isPIO ? "badge-info" : "badge-primary")));
					curUserEmail = len(session.user.email ?: "") ? session.user.email : "user@chelancounty.gov";
					curUserInitials = len(session.user.initials ?: "") ? session.user.initials : (Left(curUserName, 1) & Right(curUserName, 1));
				} else {
					if (isAuthor) {
						curUserName = "Thomas Hayes";
						curUserRole = "Author";
						curUserBadge = "badge-primary";
						curUserInitials = "TH";
						curUserEmail = "thomas.hayes@chelancounty.gov";
					} else if (isHR) {
						curUserName = "Elena Rostova";
						curUserRole = "HR";
						curUserBadge = "badge-purple";
						curUserInitials = "ER";
						curUserEmail = "elena.rostova@chelancounty.gov";
					} else if (isPIO) {
						curUserName = "Jill Morrison";
						curUserRole = "PIO";
						curUserBadge = "badge-info";
						curUserInitials = "JM";
						curUserEmail = "jill.morrison@chelancounty.gov";
					}
				}

				// Workspace Permissions: Only Admin can see All Workspaces; Non-Admins strictly see their assigned workspaces
				accessibleWorkspaces = getUserAccessibleWorkspaces(activeRole);
				assignedWorkspaceCodes = getUserAssignedWorkspaceCodes(activeRole);

				requestedWsParam = "";
				if (structKeyExists(params, "ws") && len(trim(params.ws))) {
					requestedWsParam = trim(params.ws);
				} else if (structKeyExists(cookie, "cmsadmin_workspace") && len(trim(cookie.cmsadmin_workspace))) {
					requestedWsParam = trim(cookie.cmsadmin_workspace);
				}

				activeWsObj = resolveUserActiveWorkspace(requestedWsParam, activeRole);
				activeWsVirtualDir = (structKeyExists(activeWsObj, "virtual_directory") && len(trim(activeWsObj.virtual_directory)))
					? trim(activeWsObj.virtual_directory)
					: (activeWsObj.id eq 'global' ? 'shared' : activeWsObj.id);

				// Dynamic System Notifications for header bell
				headerNotifications = getSystemNotifications(activeRole, 5);
				headerUnreadCount = 0;
				for (local.hn in headerNotifications) {
					if (local.hn.isUnread) headerUnreadCount++;
				}

				// Active Emergency Alerts indicator
				activeEmergencyAlertsCount = 0;
				try {
					local.qEmerg = queryExecute("SELECT COUNT(*) AS cnt FROM emergency_alerts WHERE is_active = 1 AND deletedat IS NULL", {}, { datasource: "ChelanCountyWebsite" });
					activeEmergencyAlertsCount = Val(local.qEmerg.cnt);
				} catch (any e) {}
			</cfscript>

			<!--- WCAG 2.4.1 Accessible Skip to Main Content Link --->
			<a href="#mainContent" class="skip-link">Skip to main content</a>

			<!--- Global Top Progress Bar --->
			<div id="adminPageProgressBar" class="admin-page-progress-bar" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" aria-label="Page loading progress"></div>

			<cfif isSimulatingRole>
				<!--- Persona Simulation Notice Banner (Exclusively shown when an Administrator is simulating another role) --->
				<div class="persona-simulator-banner" role="status" aria-live="polite" style="position:fixed; top:var(--header-height); left:var(--sidebar-width); right:0; z-index:90; background:var(--admin-surface); border-bottom:1px solid var(--admin-border); padding:0.45rem 1.5rem; display:flex; align-items:center; justify-content:space-between; font-size:0.8rem; box-shadow:var(--shadow-sm); transition:left var(--transition-speed) var(--transition-ease);">
					<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
						<span style="color:var(--admin-primary);"><cfoutput>#svgIcon(name="security", size=15)#</cfoutput></span>
						<span style="color:var(--admin-text-main); font-weight:700;">Simulated Role View:</span>
						<span class="badge <cfoutput>#curUserBadge#</cfoutput>" style="font-weight:700;"><cfoutput>#curUserRole#</cfoutput></span>
						<span style="color:var(--admin-text-muted);">
							<cfif isAuthor>
								General web update &bull; Scoped strictly to <strong>Content Management Group</strong>.
							<cfelseif isHR>
								Scoped to <strong>Content Management and HRM Group</strong>.
							<cfelseif isPIO>
								Scoped to <strong>Content Management and PIO Group</strong>.
							</cfif>
						</span>
					</div>
					<a href="<cfoutput>#urlFor(controller='users', action='simulate', params='role=admin')#</cfoutput>" class="btn btn-outline-secondary btn-sm" style="padding:0.2rem 0.6rem; font-size:0.75rem;">
						Reset to Administrator
					</a>
				</div>
			</cfif>

			<div class="admin-app">
				<!--- Top Navigation Bar --->
				<header class="admin-header">
					<div class="header-left">
						<div class="brand-wrapper">
							<a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>" style="display:flex; align-items:center; gap:0.75rem; text-decoration:none;">
								<div class="brand-logo" style="background:transparent; box-shadow:none;">
									<img src="/images/logo.png" alt="Chelan County Logo" width="34" height="34" style="width:34px; height:34px; object-fit:contain; display:block;">
								</div>
								<span class="brand-text">CMS Admin</span>
								<span class="brand-badge">2.0</span>
							</a>
						</div>

						<button type="button" class="btn-toggle-sidebar" id="btnToggleSidebar" title="Toggle Sidebar (Collapse/Expand)" aria-label="Toggle Sidebar">
							<cfoutput>#svgIcon(name="menu", size=18)#</cfoutput>
						</button>

						<!--- Workspace Dropdown (Department or Site Selector) --->
						<div class="dropdown header-workspace-dropdown" id="workspaceDropdownContainer" data-user-role="<cfoutput>#activeRole#</cfoutput>" data-is-admin="<cfoutput>#(isAdmin ? 'true' : 'false')#</cfoutput>" data-active-ws-id="<cfoutput>#activeWsObj.id#</cfoutput>" data-active-ws-virtual-dir="<cfoutput>#activeWsVirtualDir#</cfoutput>" data-dashboard-url="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>">
							<button type="button" class="workspace-btn" id="workspaceDropdownBtn" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Switch Workspace">
								<span class="workspace-btn-icon" id="activeWsIcon">
									<cfoutput>#svgIcon(name=activeWsObj.icon, size=16)#</cfoutput>
								</span>
								<div class="workspace-btn-content">
									<span class="workspace-btn-meta"><cfoutput>#(isAdmin ? 'Workspace' : 'Assigned Workspace')#</cfoutput></span>
									<span class="workspace-btn-title" id="activeWsTitle"><cfoutput>#activeWsObj.name#</cfoutput></span>
								</div>
								<span class="workspace-btn-pill <cfoutput>#activeWsObj.badgeClass#</cfoutput>" id="activeWsTypePill"><cfoutput>#activeWsObj.badge#</cfoutput></span>
								<span class="workspace-btn-chevron">
									<cfoutput>#svgIcon(name="chevron-down", size=13)#</cfoutput>
								</span>
							</button>

							<div class="dropdown-menu workspace-menu" aria-labelledby="workspaceDropdownBtn">
								<div class="workspace-menu-search">
									<span class="workspace-search-icon"><cfoutput>#svgIcon(name="search", size=14)#</cfoutput></span>
									<input type="text" class="workspace-filter-input" id="workspaceFilterInput" placeholder="<cfoutput>#(isAdmin ? 'Find department or site...' : 'Find assigned workspace...')#</cfoutput>" autocomplete="off">
								</div>

								<div class="workspace-menu-scrollable" id="workspaceList">
									<cfif !isAdmin>
										<!--- Non-Admin Scoping Banner --->
										<div style="padding:0.45rem 0.75rem; margin-bottom:0.35rem; background:rgba(0, 115, 170, 0.06); border-radius:var(--radius-sm); border:1px solid rgba(0, 115, 170, 0.15); display:flex; align-items:center; justify-content:space-between; font-size:0.75rem;">
											<span style="color:var(--admin-text-main); font-weight:600; display:flex; align-items:center; gap:0.35rem;">
												<cfoutput>#svgIcon(name="lock", size=12)#</cfoutput>
												<span>Assigned Workspaces</span>
											</span>
											<span class="badge badge-primary" style="font-size:0.68rem; padding:0.1rem 0.4rem;"><cfoutput>#ArrayLen(accessibleWorkspaces)# Assigned</cfoutput></span>
										</div>
									</cfif>

									<!--- Departments Section --->
									<cfset deptWorkspaces = []>
									<cfloop array="#accessibleWorkspaces#" index="local.w">
										<cfif local.w.type eq "dept">
											<cfset ArrayAppend(deptWorkspaces, local.w)>
										</cfif>
									</cfloop>

									<cfif ArrayLen(deptWorkspaces) gt 0>
										<cfset ArraySort(deptWorkspaces, function(a, b){ return CompareNoCase(a.name, b.name); })>
										<div class="workspace-menu-section-title"><cfoutput>#(isAdmin ? 'Departments' : 'Assigned Departments')#</cfoutput></div>
										<cfloop array="#deptWorkspaces#" index="local.w">
											<cfset local.wVirtDir = (StructKeyExists(local.w, "virtual_directory") && Len(Trim(local.w.virtual_directory))) ? Trim(local.w.virtual_directory) : local.w.id>
											<button type="button" class="workspace-item <cfif activeWsObj.id eq local.w.id>is-active</cfif>" data-ws-id="<cfoutput>#local.w.id#</cfoutput>" data-ws-name="<cfoutput>#local.w.name#</cfoutput>" data-ws-type="dept" data-ws-badge="<cfoutput>#local.w.badge#</cfoutput>" data-ws-badge-cls="<cfoutput>#local.w.badgeClass#</cfoutput>" data-ws-icon="<cfoutput>#local.w.icon#</cfoutput>" data-ws-virtual-dir="<cfoutput>#local.wVirtDir#</cfoutput>">
												<span class="workspace-item-icon icon-<cfoutput>#local.w.id#</cfoutput>">
													<cfoutput>#svgIcon(name=local.w.icon, size=16)#</cfoutput>
												</span>
												<div class="workspace-item-details">
													<div class="workspace-item-name"><cfoutput>#local.w.name#</cfoutput></div>
													<div class="workspace-item-sub"><cfoutput>#local.w.desc#</cfoutput></div>
												</div>
												<span class="badge <cfoutput>#local.w.badgeClass#</cfoutput>"><cfoutput>#local.w.badge#</cfoutput></span>
												<span class="workspace-item-check"><cfoutput>#svgIcon(name="check", size=14)#</cfoutput></span>
											</button>
										</cfloop>
									</cfif>

									<!--- Sites & Public Portals Section --->
									<cfset siteWorkspaces = []>
									<cfloop array="#accessibleWorkspaces#" index="local.w">
										<cfif local.w.type eq "site">
											<cfset ArrayAppend(siteWorkspaces, local.w)>
										</cfif>
									</cfloop>

									<cfif ArrayLen(siteWorkspaces) gt 0>
										<cfset ArraySort(siteWorkspaces, function(a, b){ return CompareNoCase(a.name, b.name); })>
										<div class="workspace-menu-section-title"><cfoutput>#(isAdmin ? 'Sites & Portals' : 'Assigned Sites & Portals')#</cfoutput></div>
										<cfloop array="#siteWorkspaces#" index="local.w">
											<cfset local.wVirtDir = (StructKeyExists(local.w, "virtual_directory") && Len(Trim(local.w.virtual_directory))) ? Trim(local.w.virtual_directory) : local.w.id>
											<button type="button" class="workspace-item <cfif activeWsObj.id eq local.w.id>is-active</cfif>" data-ws-id="<cfoutput>#local.w.id#</cfoutput>" data-ws-name="<cfoutput>#local.w.name#</cfoutput>" data-ws-type="site" data-ws-badge="<cfoutput>#local.w.badge#</cfoutput>" data-ws-badge-cls="<cfoutput>#local.w.badgeClass#</cfoutput>" data-ws-icon="<cfoutput>#local.w.icon#</cfoutput>" data-ws-virtual-dir="<cfoutput>#local.wVirtDir#</cfoutput>">
												<span class="workspace-item-icon icon-site">
													<cfoutput>#svgIcon(name=local.w.icon, size=16)#</cfoutput>
												</span>
												<div class="workspace-item-details">
													<div class="workspace-item-name"><cfoutput>#local.w.name#</cfoutput></div>
													<div class="workspace-item-sub"><cfoutput>#local.w.desc#</cfoutput></div>
												</div>
												<span class="badge <cfoutput>#local.w.badgeClass#</cfoutput>"><cfoutput>#local.w.badge#</cfoutput></span>
												<span class="workspace-item-check"><cfoutput>#svgIcon(name="check", size=14)#</cfoutput></span>
											</button>
										</cfloop>
									</cfif>

									<div class="workspace-no-results" id="workspaceNoResults" style="display:none;">
										No matching departments or sites found
									</div>
								</div>

								<div class="workspace-menu-footer">
									<cfif isAdmin>
										<a href="<cfoutput>#urlFor(controller='workspaces', action='index')#</cfoutput>" class="workspace-footer-link">
											<cfoutput>#svgIcon(name="settings", size=13)#</cfoutput>
											<span>Manage Workspaces</span>
										</a>
									<cfelse>
										<span class="workspace-footer-link" style="color:var(--admin-text-muted); cursor:default;">
											<cfoutput>#svgIcon(name="shield", size=13)#</cfoutput>
											<span>Scoped to Assigned Profile</span>
										</span>
									</cfif>
									<span class="workspace-shortcut-hint">Switch (Alt+W)</span>
								</div>
							</div>
						</div>
					</div>

					<div class="header-right">
						<!--- Emergency Alert Active Broadcast Indicator --->
						<cfif activeEmergencyAlertsCount gt 0>
							<a href="<cfoutput>#urlFor(controller='alerts', action='index')#</cfoutput>" class="badge badge-danger" style="display:inline-flex; align-items:center; gap:0.4rem; padding:0.35rem 0.75rem; text-decoration:none; font-size:0.75rem; font-weight:700; border-radius:20px; box-shadow:0 2px 8px rgba(185,28,28,0.3); animation:pulse 2s infinite;" title="Active Emergency Broadcast Live on County Websites">
								<cfoutput>#svgIcon(name="alert-triangle", size=14)#</cfoutput>
								<span>EMERGENCY ALERT LIVE (<cfoutput>#activeEmergencyAlertsCount#</cfoutput>)</span>
							</a>
						</cfif>

						<!--- Fullscreen Toggle --->
						<button type="button" class="nav-action-btn" id="btnFullscreen" title="Toggle Fullscreen">
							<cfoutput>#svgIcon(name="maximize", size=18)#</cfoutput>
						</button>

						<!--- View Live Site Link --->
						<a href="/" target="_blank" class="nav-action-btn" title="View Public Website">
							<cfoutput>#svgIcon(name="external-link", size=18)#</cfoutput>
						</a>

						<!--- Notifications Dropdown --->
						<div class="dropdown">
							<button type="button" class="nav-action-btn" data-toggle="dropdown" title="Notifications" aria-label="Notifications" style="position:relative;">
								<cfoutput>#svgIcon(name="bell", size=18)#</cfoutput>
								<cfif headerUnreadCount gt 0>
									<span class="nav-badge-dot" style="background:var(--admin-primary); position:absolute; top:7px; right:7px; width:8px; height:8px; border-radius:50%; border:2px solid var(--admin-surface);"></span>
								</cfif>
							</button>
							<div class="dropdown-menu" style="min-width: 320px; max-width: 360px; padding:0;">
								<div class="dropdown-header" style="display:flex; justify-content:space-between; align-items:center; padding:0.75rem 1rem; border-bottom:1px solid var(--admin-border); background:var(--admin-surface);">
									<span style="font-weight:700; color:var(--admin-text-main);">Notifications</span>
									<cfif headerUnreadCount gt 0>
										<span class="badge badge-primary"><cfoutput>#headerUnreadCount# New</cfoutput></span>
									<cfelse>
										<span class="badge badge-neutral">All Caught Up</span>
									</cfif>
								</div>

								<div style="max-height: 320px; overflow-y: auto;">
									<cfif arrayLen(headerNotifications) gt 0>
										<cfloop array="#headerNotifications#" index="local.n">
											<a href="<cfoutput>#local.n.link#</cfoutput>" class="dropdown-item" style="padding:0.75rem 1rem; border-bottom:1px solid rgba(0,0,0,0.04); display:flex; gap:0.75rem; align-items:flex-start; <cfif local.n.isUnread>background:rgba(0,115,170,0.02);</cfif>">
												<span style="color:<cfoutput>#local.n.iconColor#</cfoutput>; margin-top:2px; flex-shrink:0;">
													<cfoutput>#svgIcon(name=local.n.icon, size=16)#</cfoutput>
												</span>
												<div style="flex-grow:1; min-width:0;">
													<div style="display:flex; justify-content:space-between; align-items:baseline; gap:0.4rem; margin-bottom:0.15rem;">
														<span style="font-weight:700; font-size:0.8rem; color:var(--admin-text-main); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;"><cfoutput>#local.n.title#</cfoutput></span>
														<span style="font-size:0.68rem; color:var(--admin-text-muted); flex-shrink:0;"><cfoutput>#formatTimeAgo(local.n.createdat)#</cfoutput></span>
													</div>
													<div style="font-size:0.75rem; color:var(--admin-text-muted); line-height:1.3; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;"><cfoutput>#local.n.message#</cfoutput></div>
												</div>
											</a>
										</cfloop>
									<cfelse>
										<div style="padding:1.5rem 1rem; text-align:center; color:var(--admin-text-muted); font-size:0.8rem;">
											No recent notifications at this time.
										</div>
									</cfif>
								</div>

								<div class="dropdown-divider" style="margin:0;"></div>
								<a href="<cfoutput>#urlFor(controller='main', action='notifications')#</cfoutput>" class="dropdown-item" style="justify-content:center; font-weight:600; font-size:0.8rem; color:var(--admin-primary); padding:0.65rem 1rem; background:rgba(0,115,170,0.02);">
									View All Notifications
								</a>
							</div>
						</div>

						<!--- User Profile Dropdown --->
						<div class="dropdown">
							<button type="button" class="header-user-btn" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
								<div class="user-avatar" style="font-weight:700;"><cfoutput>#curUserInitials#</cfoutput></div>
								<div class="user-meta">
									<span class="user-name"><cfoutput>#curUserName#</cfoutput></span>
									<span class="user-role"><span class="badge <cfoutput>#curUserBadge#</cfoutput>" style="font-size:0.68rem; padding:0.1rem 0.45rem;"><cfoutput>#curUserRole#</cfoutput></span></span>
								</div>
								<cfoutput>#svgIcon(name="chevron-down", size=14, class="nav-caret")#</cfoutput>
							</button>
							<div class="dropdown-menu" style="min-width: 270px;">
								<div class="dropdown-header">Signed in as <strong><cfoutput>#curUserEmail#</cfoutput></strong></div>
								<a href="<cfoutput>#urlFor(controller='users', action='profile')#</cfoutput>" class="dropdown-item">
									<cfoutput>#svgIcon(name="user", size=15)#</cfoutput>
									<span>My Profile &amp; Security</span>
								</a>
								<cfif isAdmin>
									<a href="<cfoutput>#urlFor(controller='users', action='index')#</cfoutput>" class="dropdown-item">
										<cfoutput>#svgIcon(name="users", size=15)#</cfoutput>
										<span>Manage Users &amp; Roles</span>
									</a>
								</cfif>
								<a href="<cfoutput>#urlFor(controller='users', action='roles')#</cfoutput>" class="dropdown-item">
									<cfoutput>#svgIcon(name="security", size=15)#</cfoutput>
									<span>Roles &amp; Permissions Matrix</span>
								</a>

								<!--- Role Persona Simulator Switcher: EXCLUSIVELY FOR ADMINISTRATORS --->
								<cfif userIsRealAdmin>
									<div class="dropdown-divider"></div>
									<div class="dropdown-header" style="font-size:0.7rem; text-transform:uppercase; letter-spacing:0.04em;">Simulate User Group:</div>
									<a href="<cfoutput>#urlFor(controller='users', action='simulate', params='role=admin')#</cfoutput>" class="dropdown-item" style="display:flex; justify-content:space-between; align-items:center; #(isAdmin ? 'font-weight:700; color:var(--admin-primary);' : '')#">
										<span>Administrator (Everything)</span>
										<cfif isAdmin><cfoutput>#svgIcon(name="check", size=14)#</cfoutput></cfif>
									</a>
									<a href="<cfoutput>#urlFor(controller='users', action='simulate', params='role=pio')#</cfoutput>" class="dropdown-item" style="display:flex; justify-content:space-between; align-items:center; #(isPIO ? 'font-weight:700; color:var(--admin-primary);' : '')#">
										<span>PIO (Content + PIO)</span>
										<cfif isPIO><cfoutput>#svgIcon(name="check", size=14)#</cfoutput></cfif>
									</a>
									<a href="<cfoutput>#urlFor(controller='users', action='simulate', params='role=hr')#</cfoutput>" class="dropdown-item" style="display:flex; justify-content:space-between; align-items:center; #(isHR ? 'font-weight:700; color:var(--admin-primary);' : '')#">
										<span>HR (Content + HRM)</span>
										<cfif isHR><cfoutput>#svgIcon(name="check", size=14)#</cfoutput></cfif>
									</a>
									<a href="<cfoutput>#urlFor(controller='users', action='simulate', params='role=author')#</cfoutput>" class="dropdown-item" style="display:flex; justify-content:space-between; align-items:center; #(isAuthor ? 'font-weight:700; color:var(--admin-primary);' : '')#">
										<span>Author (Content Only)</span>
										<cfif isAuthor><cfoutput>#svgIcon(name="check", size=14)#</cfoutput></cfif>
									</a>
								</cfif>

								<div class="dropdown-divider"></div>
								<a href="<cfoutput>#urlFor(controller='sessions', action='new')#</cfoutput>" class="dropdown-item">
									<cfoutput>#svgIcon(name="user", size=15)#</cfoutput>
									<span>Switch Account / Sign In</span>
								</a>
								<a href="<cfoutput>#urlFor(controller='sessions', action='destroy')#</cfoutput>" class="dropdown-item" style="color:var(--admin-danger);">
									<cfoutput>#svgIcon(name="log-out", size=15)#</cfoutput>
									<span>Log Out</span>
								</a>
							</div>
						</div>
					</div>
				</header>

				<!--- Mobile Drawer Backdrop --->
				<div class="sidebar-backdrop" id="sidebarBackdrop"></div>

				<!--- Left Sidebar Navigation --->
				<aside class="admin-sidebar" id="adminSidebar">
					<div class="sidebar-content">
						<!--- Profile Quick Badge --->
						<div class="sidebar-profile">
							<div class="sidebar-profile-avatar" style="font-weight:700;"><cfoutput>#curUserInitials#</cfoutput></div>
							<div class="sidebar-profile-info">
								<div class="sidebar-profile-name"><cfoutput>#curUserName#</cfoutput></div>
								<div class="sidebar-profile-status">
									<span class="status-indicator"></span> Online &bull; <cfoutput>#curUserRole#</cfoutput>
								</div>
							</div>
						</div>

						<!--- Navigation Group: MAIN --->
						<div class="nav-group">
							<div class="nav-group-title">Main</div>
							<ul class="sidebar-nav">
								<li class="nav-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'main' ? 'active' : '')#</cfoutput>">
									<a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>" class="nav-link">
										<span class="nav-link-main">
											<span class="nav-icon"><cfoutput>#svgIcon(name="dashboard", size=18)#</cfoutput></span>
											<span class="nav-text">Dashboard</span>
										</span>
									</a>
								</li>
							</ul>
						</div>

						<!--- Navigation Group: CONTENT MANAGEMENT --->
						<div class="nav-group">
							<div class="nav-group-title">Content Management</div>
							<ul class="sidebar-nav">
								<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'pages' ? 'open active' : '')#</cfoutput>">
									<a href="javascript:void(0)" class="nav-link">
										<span class="nav-link-main">
											<span class="nav-icon"><cfoutput>#svgIcon(name="pages", size=18)#</cfoutput></span>
											<span class="nav-text">Pages</span>
										</span>
										<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
									</a>
									<ul class="nav-submenu">
										<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'pages' and structKeyExists(params, 'action') and (params.action eq 'index' or params.action eq 'edit') ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='pages', action='index')#</cfoutput>" class="submenu-link">All Pages</a></li>
										<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'pages' and structKeyExists(params, 'action') and lCase(params.action) eq 'howdoi' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='pages', action='howDoI')#</cfoutput>" class="submenu-link">How Do I</a></li>
									</ul>
								</li>

								<li class="nav-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'events' ? 'active' : '')#</cfoutput>">
									<a href="<cfoutput>#urlFor(controller='events', action='index')#</cfoutput>" class="nav-link">
										<span class="nav-link-main">
											<span class="nav-icon"><cfoutput>#svgIcon(name="calendar", size=18)#</cfoutput></span>
											<span class="nav-text">Events / Calendar</span>
										</span>
									</a>
								</li>

								<li class="nav-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'media' ? 'active' : '')#</cfoutput>">
									<a href="<cfoutput>#urlFor(controller='media', action='index')#</cfoutput>" class="nav-link">
										<span class="nav-link-main">
											<span class="nav-icon"><cfoutput>#svgIcon(name="media", size=18)#</cfoutput></span>
											<span class="nav-text">Media Library</span>
										</span>
									</a>
								</li>

								<!--- Form Builder Menu Item with Submenu --->
								<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'forms' ? 'open active' : '')#</cfoutput>">
									<a href="javascript:void(0)" class="nav-link">
										<span class="nav-link-main">
											<span class="nav-icon"><cfoutput>#svgIcon(name="form", size=18)#</cfoutput></span>
											<span class="nav-text">Form Builder</span>
										</span>
										<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
									</a>
									<ul class="nav-submenu">
										<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'forms' and structKeyExists(params, 'action') and params.action eq 'index' ? 'active' : '')#</cfoutput>">
											<a href="<cfoutput>#urlFor(controller='forms', action='index')#</cfoutput>" class="submenu-link">Active Forms</a>
										</li>
										<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'forms' and structKeyExists(params, 'action') and params.action eq 'builder' ? 'active' : '')#</cfoutput>">
											<a href="<cfoutput>#urlFor(controller='forms', action='builder')#</cfoutput>" class="submenu-link">+ Create / Builder Studio</a>
										</li>
									</ul>
								</li>

								<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'documentation' ? 'open active' : '')#</cfoutput>">
									<a href="javascript:void(0)" class="nav-link">
										<span class="nav-link-main">
											<span class="nav-icon"><cfoutput>#svgIcon(name="book", size=18)#</cfoutput></span>
											<span class="nav-text">Documentation</span>
										</span>
										<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
									</a>
									<ul class="nav-submenu">
										<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'documentation' and structKeyExists(params, 'action') and params.action eq 'index' ? 'active' : '')#</cfoutput>">
											<a href="<cfoutput>#urlFor(controller='documentation', action='index')#</cfoutput>" class="submenu-link">Knowledge Base</a>
										</li>
										<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'documentation' and structKeyExists(params, 'action') and params.action eq 'formBuilder' ? 'active' : '')#</cfoutput>">
											<a href="<cfoutput>#urlFor(controller='documentation', action='formBuilder')#</cfoutput>" class="submenu-link">Form Builder Guide for Beginners</a>
										</li>
										<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'documentation' and structKeyExists(params, 'action') and params.action eq 'editor' ? 'active' : '')#</cfoutput>">
											<a href="<cfoutput>#urlFor(controller='documentation', action='editor')#</cfoutput>" class="submenu-link">Rich Text Editor Guide &amp; Demo</a>
										</li>
									</ul>
								</li>
							</ul>
						</div>

						<!--- Navigation Group: HRM (Human Resource Management) --->
						<cfif isAdmin or isHR>
							<div class="nav-group">
								<div class="nav-group-title">HRM</div>
								<ul class="sidebar-nav">
									<li class="nav-item has-submenu <cfoutput>#((structKeyExists(params, 'dept') and params.dept eq 'hrm') or (structKeyExists(params, 'controller') and params.controller eq 'jobs') ? 'open active' : '')#</cfoutput>">
										<a href="javascript:void(0)" class="nav-link">
											<span class="nav-link-main">
												<span class="nav-icon"><cfoutput>#svgIcon(name="briefcase", size=18)#</cfoutput></span>
												<span class="nav-text">Human Resources</span>
											</span>
											<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
										</a>
										<ul class="nav-submenu">
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'forms' and structKeyExists(params, 'dept') and params.dept eq 'hrm' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='forms', action='index', params='dept=hrm')#</cfoutput>" class="submenu-link">HRM Forms &amp; Applications</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'jobs' and (params.action eq 'index' or params.action eq 'new' or params.action eq 'edit') ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='jobs', action='index')#</cfoutput>" class="submenu-link">Job Postings &amp; Vacancies</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'jobs' and (params.action eq 'applications' or params.action eq 'application') ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='jobs', action='applications')#</cfoutput>" class="submenu-link">Candidate Applications</a></li>
										</ul>
									</li>
								</ul>
							</div>
						</cfif>

						<!--- Navigation Group: PIO (Public Information Office) --->
						<cfif isAdmin or isPIO>
							<div class="nav-group">
								<div class="nav-group-title">PIO</div>
								<ul class="sidebar-nav">
									<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'dept') and params.dept eq 'pio' ? 'open active' : '')#</cfoutput>">
										<a href="javascript:void(0)" class="nav-link">
											<span class="nav-link-main">
												<span class="nav-icon"><cfoutput>#svgIcon(name="megaphone", size=18)#</cfoutput></span>
												<span class="nav-text">Public Information</span>
											</span>
											<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
										</a>
										<ul class="nav-submenu">
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'dept') and params.dept eq 'pio' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='forms', action='index', params='dept=pio')#</cfoutput>" class="submenu-link">PIO Forms &amp; Inquiries</a></li>
											<li class="submenu-item"><a href="#pio-press" class="submenu-link">Press Releases &amp; Media</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'alerts' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='alerts', action='index')#</cfoutput>" class="submenu-link">Emergency Alerts &amp; News</a></li>
										</ul>
									</li>
									<!--- Articles & Posts (PIO-owned content) --->
									<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'articles' ? 'open active' : '')#</cfoutput>">
										<a href="javascript:void(0)" class="nav-link">
											<span class="nav-link-main">
												<span class="nav-icon"><cfoutput>#svgIcon(name="article", size=18)#</cfoutput></span>
												<span class="nav-text">Articles &amp; Posts</span>
											</span>
											<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
										</a>
										<ul class="nav-submenu">
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'articles' ? 'active' : '')#</cfoutput>"><a href="#articles-all" class="submenu-link">All Articles</a></li>
											<li class="submenu-item"><a href="#articles-new" class="submenu-link">Add New Article</a></li>
											<li class="submenu-item"><a href="#articles-categories" class="submenu-link">Categories</a></li>
											<li class="submenu-item"><a href="#articles-tags" class="submenu-link">Tags</a></li>
										</ul>
									</li>
								</ul>
							</div>
						</cfif>

						<!--- Navigation Group: ADMINISTRATION --->
						<cfif isAdmin or (structKeyExists(params, 'controller') and listFindNoCase('users,workspaces,settings', params.controller))>
							<div class="nav-group">
								<div class="nav-group-title">Administration</div>
								<ul class="sidebar-nav">
									<!--- Workspaces Manager (Admin Only) --->
									<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'workspaces' ? 'open active' : '')#</cfoutput>">
										<a href="javascript:void(0)" class="nav-link">
											<span class="nav-link-main">
												<span class="nav-icon"><cfoutput>#svgIcon(name="grid", size=18)#</cfoutput></span>
												<span class="nav-text">Workspaces</span>
											</span>
											<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
										</a>
										<ul class="nav-submenu">
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'workspaces' and structKeyExists(params, 'action') and params.action eq 'index' and (!structKeyExists(params, 'type') or params.type eq 'all') ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='workspaces', action='index')#</cfoutput>" class="submenu-link">All Workspaces</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'workspaces' and structKeyExists(params, 'action') and params.action eq 'new' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='workspaces', action='new')#</cfoutput>" class="submenu-link">Add New Workspace</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'workspaces' and structKeyExists(params, 'type') and params.type eq 'dept' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='workspaces', action='index', params='type=dept')#</cfoutput>" class="submenu-link">Departments</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'workspaces' and structKeyExists(params, 'type') and params.type eq 'site' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='workspaces', action='index', params='type=site')#</cfoutput>" class="submenu-link">Sites &amp; Portals</a></li>
										</ul>
									</li>

									<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'users' ? 'open active' : '')#</cfoutput>">
										<a href="javascript:void(0)" class="nav-link">
											<span class="nav-link-main">
												<span class="nav-icon"><cfoutput>#svgIcon(name="users", size=18)#</cfoutput></span>
												<span class="nav-text">Users &amp; Roles</span>
											</span>
											<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
										</a>
										<ul class="nav-submenu">
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'users' and structKeyExists(params, 'action') and params.action eq 'index' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='users', action='index')#</cfoutput>" class="submenu-link">All Users</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'users' and structKeyExists(params, 'action') and params.action eq 'new' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='users', action='new')#</cfoutput>" class="submenu-link">Add New User</a></li>
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'users' and structKeyExists(params, 'action') and params.action eq 'roles' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='users', action='roles')#</cfoutput>" class="submenu-link">Roles &amp; Permissions</a></li>
										</ul>
									</li>

									<li class="nav-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'navigation' ? 'active' : '')#</cfoutput>">
										<a href="<cfoutput>#urlFor(controller='navigation', action='index')#</cfoutput>" class="nav-link">
											<span class="nav-link-main">
												<span class="nav-icon"><cfoutput>#svgIcon(name="folder", size=18)#</cfoutput></span>
												<span class="nav-text">Navigation Menus</span>
											</span>
										</a>
									</li>

									<li class="nav-item has-submenu <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'settings' ? 'open active' : '')#</cfoutput>">
										<a href="javascript:void(0)" class="nav-link">
											<span class="nav-link-main">
												<span class="nav-icon"><cfoutput>#svgIcon(name="settings", size=18)#</cfoutput></span>
												<span class="nav-text">Settings</span>
											</span>
											<cfoutput>#svgIcon(name="chevron-right", size=14, class="nav-caret")#</cfoutput>
										</a>
										<ul class="nav-submenu">
											<li class="submenu-item <cfoutput>#(structKeyExists(params, 'controller') and params.controller eq 'settings' and structKeyExists(params, 'action') and params.action eq 'startup' ? 'active' : '')#</cfoutput>"><a href="<cfoutput>#urlFor(controller='settings', action='startup')#</cfoutput>" class="submenu-link">Startup &amp; Front-End (.css)</a></li>
											<li class="submenu-item"><a href="#settings-general" class="submenu-link">General Settings</a></li>
											<li class="submenu-item"><a href="#settings-reading" class="submenu-link">Reading &amp; SEO</a></li>
											<li class="submenu-item"><a href="#settings-media" class="submenu-link">Media Sizes</a></li>
											<li class="submenu-item"><a href="#settings-system" class="submenu-link">System Info</a></li>
										</ul>
									</li>
								</ul>
							</div>
						</cfif>
					</div>
				</aside>

				<!--- Main Content Area with WCAG AA Landmark and Skip Target --->
				<main class="admin-main" id="mainContent" tabindex="-1">
					<div class="page-wrapper">
						<!--- Flash messages output --->
						<cfoutput>#flashMessages(encode=false)#</cfoutput>

						<!--- Dynamic action content view --->
						<cfoutput>#includeContent()#</cfoutput>
					</div>

					<!--- Admin Template Footer --->
					<footer class="admin-footer mt-5">
						<div>
							&copy; <cfoutput>#Year(Now())#</cfoutput> <strong>CMS Admin</strong> &bull; Chelan County CMS Platform by Chelan County IT 
						</div>
						<div class="footer-status">
							<span class="status-indicator"></span>
							<span>Wheels 4.1 &bull; Lucee CFML &bull; System Healthy</span>
						</div>
					</footer>
				</main>
			</div>

			<!--- Global Accessible Page Transition Loader Overlay --->
			<div class="admin-page-loader-overlay" id="adminPageLoadingOverlay" role="status" aria-live="polite" aria-busy="true">
				<div class="admin-page-loader-card">
					<div class="admin-page-loader-visual">
						<div class="admin-spinner-ring" aria-hidden="true"></div>
						<img src="/images/logo.png" alt="" class="admin-loader-logo" width="30" height="30" aria-hidden="true">
					</div>
					<div class="admin-page-loader-text">
						<h2 class="admin-page-loader-title" id="adminLoaderTitle">Loading Page...</h2>
						<p class="admin-page-loader-subtitle" id="adminLoaderSubtitle">Retrieving records, attributes, and navigation trees.</p>
					</div>
					<div class="admin-loader-progress-track" aria-hidden="true">
						<div class="admin-loader-progress-fill"></div>
					</div>
				</div>
			</div>

			<div class="admin-prompt-backdrop" id="adminPromptBackdrop" role="presentation">
				<section class="admin-prompt-dialog" id="adminPromptDialog" role="dialog" aria-modal="true" aria-labelledby="adminPromptTitle" aria-describedby="adminPromptMessage" tabindex="-1">
					<div class="admin-prompt-header">
						<div class="admin-prompt-icon" id="adminPromptIcon" aria-hidden="true"></div>
						<h2 class="admin-prompt-title" id="adminPromptTitle"></h2>
					</div>
					<p class="admin-prompt-message" id="adminPromptMessage"></p>
					<div class="admin-prompt-actions">
						<button type="button" class="btn btn-outline btn-sm" id="adminPromptCancel">Cancel</button>
						<button type="button" class="btn btn-primary btn-sm" id="adminPromptAccept">OK</button>
					</div>
				</section>
			</div>

			<!--- Core Vanilla JS Interactions --->
			<script src="/javascripts/admin.js?v=1.4" type="text/javascript"></script>
			<script src="/javascripts/jbdeditor.js?v=1.6" type="text/javascript"></script>
			<cfif structKeyExists(params, "controller") and params.controller eq "forms" and structKeyExists(params, "action") and params.action eq "builder">
				<script src="/javascripts/form-builder.js?v=2.5" type="text/javascript"></script>
			</cfif>
		</body>
	</html>
</cfif>
