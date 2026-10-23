<cfparam name="alerts" default="#[]#">
<cfparam name="stats" default="#{}#">
<cfparam name="presets" default="#[]#">
<cfparam name="accessibleWorkspaces" default="#[]#">
<cfscript>
	if (!structKeyExists(stats, "total")) stats.total = arrayLen(alerts);
	if (!structKeyExists(stats, "active")) stats.active = 0;
	if (!structKeyExists(stats, "critical")) stats.critical = 0;
	if (!structKeyExists(stats, "warning")) stats.warning = 0;
	if (!structKeyExists(stats, "info")) stats.info = 0;
</cfscript>

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">Emergency Alerts &amp; Incident Dispatch</h1>
			<cfif stats.active gt 0>
				<span class="badge badge-danger" style="animation:pulseBadge 1.8s infinite; font-size:0.75rem; padding:0.2rem 0.6rem;">
					&bull; #stats.active# BROADCAST LIVE
				</span>
			<cfelse>
				<span class="badge badge-neutral" style="font-size:0.75rem;">Standby (0 Active)</span>
			</cfif>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">PIO</li>
				<li class="breadcrumb-item active" aria-current="page">Emergency Alerts</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="/api/v1/alerts/active" target="_blank" class="btn btn-outline-secondary btn-sm" title="View Public JSON API Output">
			#svgIcon(name="code", size=14)#
			<span>Public JSON API</span>
		</a>
		<button type="button" class="btn btn-primary btn-sm" onclick="openAlertModal()">
			#svgIcon(name="plus", size=14)#
			<span>+ New Emergency Broadcast</span>
		</button>
	</div>
</div>

<style>
@keyframes pulseBadge {
	0% { opacity: 1; transform: scale(1); }
	50% { opacity: 0.75; transform: scale(1.04); }
	100% { opacity: 1; transform: scale(1); }
}
.alert-preset-card {
	background: var(--admin-surface);
	border: 1px solid var(--admin-border);
	border-radius: var(--radius-md);
	padding: 1rem;
	cursor: pointer;
	transition: all 0.15s ease;
	display: flex;
	flex-direction: column;
	justify-content: space-between;
	text-align: left;
	height: 100%;
}
.alert-preset-card:hover {
	border-color: var(--admin-primary);
	transform: translateY(-2px);
	box-shadow: var(--shadow-md);
}
.live-banner-preview {
	border-radius: var(--radius-md);
	padding: 1rem 1.25rem;
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 1rem;
	box-shadow: 0 4px 14px rgba(0, 0, 0, 0.15);
	margin-bottom: 1.5rem;
	transition: all 0.2s ease;
}
.live-banner--danger {
	background: ##b91c1c;
	color: ##ffffff;
	border-left: 6px solid ##7f1d1d;
}
.live-banner--warning {
	background: ##c2410c;
	color: ##ffffff;
	border-left: 6px solid ##7c2d12;
}
.live-banner--info {
	background: ##0284c7;
	color: ##ffffff;
	border-left: 6px solid ##0369a1;
}
.live-banner--success {
	background: ##15803d;
	color: ##ffffff;
	border-left: 6px solid ##14532d;
}
.modal-backdrop-alert {
	position: fixed;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	background: rgba(15, 23, 42, 0.65);
	backdrop-filter: blur(3px);
	z-index: 9990;
	display: none;
	align-items: center;
	justify-content: center;
	padding: 1rem;
}
.modal-box-alert {
	background: var(--admin-surface);
	border-radius: var(--radius-lg);
	max-width: 680px;
	width: 100%;
	max-height: 90vh;
	display: flex;
	flex-direction: column;
	box-shadow: var(--shadow-lg);
	overflow: hidden;
	animation: modalEnter 0.2s ease-out;
}
@keyframes modalEnter {
	from { opacity: 0; transform: scale(0.96) translateY(8px); }
	to { opacity: 1; transform: scale(1) translateY(0); }
}
.severity-radio-card {
	border: 1.5px solid var(--admin-border);
	border-radius: var(--radius-sm);
	padding: 0.6rem 0.85rem;
	cursor: pointer;
	display: flex;
	align-items: center;
	gap: 0.5rem;
	font-size: 0.85rem;
	font-weight: 600;
	transition: all 0.15s ease;
}
.severity-radio-card:hover {
	border-color: var(--admin-primary);
	background: var(--admin-bg);
}
.severity-radio-card input:checked + span {
	font-weight: 700;
}
</style>

<!--- KPI Overview Cards --->
<div class="admin-kpi-grid" style="display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:1rem; margin-bottom:1.5rem;">
	<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
		<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(185,28,28,0.12); color:var(--admin-danger); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			#svgIcon(name="alert-triangle", size=22)#
		</div>
		<div>
			<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-danger); line-height:1.2;">#stats.active#</div>
			<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">Active Broadcasts</div>
		</div>
	</div>

	<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
		<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(220,38,38,0.1); color:##b91c1c; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			#svgIcon(name="flame", size=22)#
		</div>
		<div>
			<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#stats.critical#</div>
			<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">Critical / Danger</div>
		</div>
	</div>

	<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
		<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(194,65,12,0.1); color:##c2410c; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			#svgIcon(name="clock", size=22)#
		</div>
		<div>
			<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#stats.warning#</div>
			<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">Warnings / Closures</div>
		</div>
	</div>

	<div class="kpi-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; display:flex; align-items:center; gap:1rem; box-shadow:var(--shadow-sm);">
		<div class="kpi-icon" style="width:44px; height:44px; border-radius:var(--radius-md); background:rgba(2,132,199,0.1); color:var(--admin-info); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			#svgIcon(name="info", size=22)#
		</div>
		<div>
			<div class="kpi-value" style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#stats.info#</div>
			<div class="kpi-label" style="font-size:0.8rem; color:var(--admin-text-muted);">Advisory Notices</div>
		</div>
	</div>
</div>

<!--- Live Public Banner Simulator --->
<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.25rem; margin-bottom:1.5rem; box-shadow:var(--shadow-sm);">
	<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem; flex-wrap:wrap; gap:0.5rem;">
		<div>
			<span style="font-size:0.75rem; text-transform:uppercase; font-weight:700; letter-spacing:0.04em; color:var(--admin-text-muted);">Public Webpage Banner Simulator (chelancounty.gov Header Preview)</span>
		</div>
		<div style="font-size:0.75rem; color:var(--admin-text-muted);">
			Simulates exact visual presentation on the public county site
		</div>
	</div>

	<cfset activeAlertsList = []>
	<cfloop array="#alerts#" index="local.a">
		<cfif local.a.is_active>
			<cfset arrayAppend(activeAlertsList, local.a)>
		</cfif>
	</cfloop>

	<cfif arrayLen(activeAlertsList) gt 0>
		<cfset heroAlert = activeAlertsList[1]>
		<div id="simulatedBanner" class="live-banner-preview live-banner--#heroAlert.severity#">
			<div style="display:flex; align-items:flex-start; gap:0.85rem;">
				<span style="font-size:1.4rem; line-height:1; flex-shrink:0;">
					#svgIcon(name="alert-triangle", size=22)#
				</span>
				<div>
					<div id="simTitle" style="font-weight:800; font-size:0.95rem; letter-spacing:-0.01em; margin-bottom:0.15rem;">
						#heroAlert.title#
					</div>
					<div id="simMessage" style="font-size:0.85rem; opacity:0.95; line-height:1.4;">
						#heroAlert.message#
					</div>
				</div>
			</div>
			<div style="display:flex; align-items:center; gap:0.6rem; flex-shrink:0;">
				<cfif len(heroAlert.link_url)>
					<a id="simLink" href="#heroAlert.link_url#" target="_blank" class="btn btn-sm" style="background:##ffffff; color:##0f172a; font-weight:700; padding:0.35rem 0.85rem; font-size:0.75rem; border:none; text-decoration:none; border-radius:6px;">
						#heroAlert.link_text# &rarr;
					</a>
				</cfif>
				<button type="button" style="background:transparent; border:none; color:##ffffff; opacity:0.85; cursor:pointer; padding:0.25rem;" title="Close banner (Citizen view)" aria-label="Dismiss banner">
					#svgIcon(name="x", size=18)#
				</button>
			</div>
		</div>
	<cfelse>
		<div class="live-banner-preview" style="background:var(--admin-bg); border:1.5px dashed var(--admin-border); color:var(--admin-text-muted); justify-content:center; text-align:center; padding:1.75rem;">
			<div style="display:flex; flex-direction:column; align-items:center; gap:0.35rem;">
				#svgIcon(name="shield", size=24)#
				<span style="font-weight:700; font-size:0.9rem; color:var(--admin-text-main);">No Emergency Alerts Currently Live</span>
				<span style="font-size:0.8rem;">The public website banner is currently idle. Use the presets below or click "+ New Emergency Broadcast" to deploy an advisory.</span>
			</div>
		</div>
	</cfif>
</div>

<!--- 1-Click Incident Dispatch Presets Grid --->
<div style="margin-bottom:1.5rem;">
	<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
		<h2 style="font-size:1rem; font-weight:700; color:var(--admin-text-main); margin:0; display:flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="zap", size=16)#
			<span>Quick-Dispatch Presets (1-Click Deployment)</span>
		</h2>
		<span style="font-size:0.75rem; color:var(--admin-text-muted);">Standardized Chelan County public safety templates</span>
	</div>

	<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(280px, 1fr)); gap:1rem;">
		<cfloop array="#presets#" index="local.p">
			<div class="alert-preset-card" onclick='applyPreset(#SerializeJSON(local.p)#)'>
				<div>
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.4rem;">
						<span style="font-weight:700; font-size:0.85rem; color:var(--admin-text-main);">#local.p.name#</span>
						<span class="badge #local.p.badgeClass#" style="font-size:0.68rem;">#UCase(local.p.severity)#</span>
					</div>
					<div style="font-size:0.78rem; color:var(--admin-text-muted); line-height:1.4; margin-bottom:0.75rem;">
						#Left(local.p.message, 110)#...
					</div>
				</div>
				<div style="display:flex; justify-content:space-between; align-items:center; border-top:1px solid var(--admin-border); padding-top:0.6rem; font-size:0.75rem;">
					<span style="color:var(--admin-primary); font-weight:600; display:flex; align-items:center; gap:0.25rem;">
						#svgIcon(name="plus", size=12)#
						<span>Use This Preset</span>
					</span>
					<span style="color:var(--admin-text-muted);">#local.p.incident_type#</span>
				</div>
			</div>
		</cfloop>
	</div>
</div>

<!--- Alerts Directory Table --->
<div class="admin-card" style="background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:var(--shadow-sm);">
	<div class="card-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.75rem;">
		<div style="display:flex; align-items:center; gap:0.6rem;">
			<h2 style="font-size:1rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.45rem;">
				#svgIcon(name="radio", size=16)#
				<span>Emergency Broadcast History &amp; Archives</span>
			</h2>
			<span class="badge badge-primary">#arrayLen(alerts)# Total</span>
		</div>

		<!--- Search / Filter input --->
		<div style="display:flex; gap:0.5rem; align-items:center;">
			<input type="text" id="alertSearchInput" class="form-control" placeholder="Search broadcasts..." onkeyup="filterAlertRows()" style="padding:0.35rem 0.75rem; font-size:0.8rem; width:220px;">
		</div>
	</div>

	<div class="card-body" style="padding:0;">
		<cfif arrayLen(alerts) gt 0>
			<div class="table-responsive">
				<table class="table" id="alertsTable" style="margin:0; width:100%; border-collapse:collapse;">
					<thead>
						<tr style="background:var(--admin-bg); border-bottom:1px solid var(--admin-border); font-size:0.75rem; text-transform:uppercase; letter-spacing:0.04em; color:var(--admin-text-muted);">
							<th style="padding:0.75rem 1rem; width:90px; text-align:center;">Live Status</th>
							<th style="padding:0.75rem 1rem;">Headline &amp; Message</th>
							<th style="padding:0.75rem 1rem; width:120px;">Severity</th>
							<th style="padding:0.75rem 1rem; width:110px;">Incident Type</th>
							<th style="padding:0.75rem 1rem; width:110px;">Target Site</th>
							<th style="padding:0.75rem 1rem; width:140px;">Updated</th>
							<th style="padding:0.75rem 1rem; width:110px; text-align:right;">Actions</th>
						</tr>
					</thead>
					<tbody>
						<cfloop array="#alerts#" index="local.a">
							<cfset local.sevBadge = "badge-danger">
							<cfif local.a.severity eq "warning"><cfset local.sevBadge = "badge-warning">
							<cfelseif local.a.severity eq "info"><cfset local.sevBadge = "badge-info">
							<cfelseif local.a.severity eq "success"><cfset local.sevBadge = "badge-success"></cfif>

							<tr class="alert-row" data-search="#LCase(local.a.title & ' ' & local.a.message & ' ' & local.a.severity & ' ' & local.a.incident_type)#" style="border-bottom:1px solid var(--admin-border); font-size:0.825rem; transition:background 0.15s ease; <cfif local.a.is_active>background:rgba(185,28,28,0.02);</cfif>">
								<td style="padding:0.85rem 1rem; text-align:center;">
									<button type="button" class="btn btn-sm #(local.a.is_active ? 'btn-success' : 'btn-outline-secondary')#" onclick="toggleAlert(#local.a.id#)" style="padding:0.2rem 0.55rem; font-size:0.72rem; font-weight:700; border-radius:20px;">
										#(local.a.is_active ? "LIVE" : "OFF")#
									</button>
								</td>
								<td style="padding:0.85rem 1rem;">
									<div style="font-weight:700; color:var(--admin-text-main); margin-bottom:0.2rem;">
										#local.a.title#
									</div>
									<div style="color:var(--admin-text-muted); font-size:0.78rem; line-height:1.35; max-width:550px;">
										#Left(local.a.message, 140)#<cfif len(local.a.message) gt 140>...</cfif>
									</div>
									<cfif len(local.a.link_url)>
										<div style="margin-top:0.35rem; font-size:0.72rem;">
											<a href="#local.a.link_url#" target="_blank" style="color:var(--admin-primary); text-decoration:none;">
												#svgIcon(name="external-link", size=10)# #local.a.link_text# (#local.a.link_url#)
											</a>
										</div>
									</cfif>
								</td>
								<td style="padding:0.85rem 1rem;">
									<span class="badge #local.sevBadge#">#UCase(local.a.severity)#</span>
								</td>
								<td style="padding:0.85rem 1rem; color:var(--admin-text-muted); font-size:0.78rem;">
									#local.a.incident_type#
								</td>
								<td style="padding:0.85rem 1rem;">
									<span class="badge badge-neutral" style="font-size:0.7rem;">#local.a.siteid#</span>
								</td>
								<td style="padding:0.85rem 1rem; font-size:0.75rem; color:var(--admin-text-muted);">
									<div>#DateFormat(local.a.updatedat, "mmm d, yyyy")#</div>
									<div style="font-size:0.7rem;">#TimeFormat(local.a.updatedat, "h:mm TT")#</div>
								</td>
								<td style="padding:0.85rem 1rem; text-align:right; white-space:nowrap;">
									<button type="button" class="btn btn-outline-secondary btn-sm" onclick='editAlert(#SerializeJSON(local.a)#)' title="Edit Broadcast" style="padding:0.25rem 0.5rem;">
										#svgIcon(name="edit", size=13)#
									</button>
									<button type="button" class="btn btn-outline-danger btn-sm" onclick="deleteAlert(#local.a.id#, '#JSStringFormat(local.a.title)#')" title="Delete Broadcast" style="padding:0.25rem 0.5rem;">
										#svgIcon(name="trash", size=13)#
									</button>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		<cfelse>
			<div style="padding:3.5rem 1.5rem; text-align:center; color:var(--admin-text-muted);">
				<div style="width:54px; height:54px; border-radius:50%; background:rgba(0,0,0,0.04); display:flex; align-items:center; justify-content:center; margin:0 auto 1rem; color:var(--admin-text-muted);">
					#svgIcon(name="shield", size=24)#
				</div>
				<h3 style="font-size:1.1rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.25rem;">No emergency broadcasts found</h3>
				<p style="font-size:0.85rem; max-width:420px; margin:0 auto 1.25rem;">Deploy a pre-formatted incident preset or author a custom emergency notification.</p>
				<button type="button" class="btn btn-primary btn-sm" onclick="openAlertModal()">
					+ New Emergency Broadcast
				</button>
			</div>
		</cfif>
	</div>
</div>

<!--- Accessible Add/Edit Alert Modal --->
<div class="modal-backdrop-alert" id="alertModalBackdrop" onclick="closeAlertModal(event)">
	<div class="modal-box-alert" id="alertModalBox" onclick="event.stopPropagation()">
		<div style="padding:1.1rem 1.35rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
			<h2 id="modalAlertTitle" style="font-size:1rem; font-weight:700; margin:0; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
				#svgIcon(name="alert-triangle", size=18)#
				<span>Emergency Incident Dispatch</span>
			</h2>
			<button type="button" onclick="closeAlertModalDirect()" style="background:transparent; border:none; cursor:pointer; color:var(--admin-text-muted); padding:0.25rem;" aria-label="Close dialog">
				#svgIcon(name="x", size=18)#
			</button>
		</div>

		<form id="alertDispatchForm" onsubmit="handleAlertFormSubmit(event)" style="display:flex; flex-direction:column; overflow-y:auto; padding:1.35rem; gap:1.15rem;">
			<input type="hidden" id="alertId" name="id" value="0">

			<!--- Preset Selector Helper --->
			<div style="background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.75rem 1rem;">
				<label for="modalPresetSelect" style="display:block; font-size:0.78rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.35rem;">
					Load Standard Incident Preset:
				</label>
				<select id="modalPresetSelect" class="form-control" onchange="onPresetSelectChange(this)" style="font-size:0.825rem;">
					<option value="">-- Choose a pre-configured template (optional) --</option>
					<cfloop array="#presets#" index="local.p">
						<option value="#local.p.id#">#local.p.name#</option>
					</cfloop>
				</select>
			</div>

			<!--- Headline --->
			<div>
				<label for="fldAlertTitle" class="form-label" style="font-weight:700; font-size:0.825rem; display:block; margin-bottom:0.35rem;">
					Incident Headline / Alert Title <span style="color:var(--admin-danger);">*</span>
				</label>
				<input type="text" id="fldAlertTitle" name="title" required class="form-control" placeholder="e.g. LEVEL 3 EVACUATION (GO NOW): Apple Fire" style="font-weight:600;">
			</div>

			<!--- Severity Radio Cards --->
			<div>
				<label class="form-label" style="font-weight:700; font-size:0.825rem; display:block; margin-bottom:0.35rem;">
					Severity Level &amp; Banner Color <span style="color:var(--admin-danger);">*</span>
				</label>
				<div style="display:grid; grid-template-columns:repeat(3, 1fr); gap:0.6rem;">
					<label class="severity-radio-card" style="border-left:4px solid ##b91c1c;">
						<input type="radio" name="severity" value="danger" checked>
						<span>Danger / Red (Critical)</span>
					</label>
					<label class="severity-radio-card" style="border-left:4px solid ##c2410c;">
						<input type="radio" name="severity" value="warning">
						<span>Warning / Orange</span>
					</label>
					<label class="severity-radio-card" style="border-left:4px solid ##0284c7;">
						<input type="radio" name="severity" value="info">
						<span>Notice / Blue</span>
					</label>
				</div>
			</div>

			<!--- Message Body --->
			<div>
				<label for="fldAlertMessage" class="form-label" style="font-weight:700; font-size:0.825rem; display:block; margin-bottom:0.35rem;">
					Advisory Message Body <span style="color:var(--admin-danger);">*</span>
				</label>
				<textarea id="fldAlertMessage" name="message" rows="3" required class="form-control" placeholder="Detail the active hazard, boundary zones, designated evacuation routes, or road closures..."></textarea>
			</div>

			<!--- Target Link --->
			<div style="display:grid; grid-template-columns:1.5fr 1fr; gap:0.85rem;">
				<div>
					<label for="fldLinkUrl" class="form-label" style="font-weight:600; font-size:0.825rem; display:block; margin-bottom:0.35rem;">
						Action Link URL (Optional)
					</label>
					<input type="url" id="fldLinkUrl" name="link_url" class="form-control" placeholder="https://www.chelancounty.gov/emergency-management">
				</div>
				<div>
					<label for="fldLinkText" class="form-label" style="font-weight:600; font-size:0.825rem; display:block; margin-bottom:0.35rem;">
						Button Label
					</label>
					<input type="text" id="fldLinkText" name="link_text" class="form-control" value="View Incident Details">
				</div>
			</div>

			<!--- Incident Category --->
			<div>
				<input type="hidden" id="fldSiteId" name="siteid" value="#EncodeForHTMLAttribute(activeWorkspaceId())#">
				<div>
					<label for="fldIncidentType" class="form-label" style="font-weight:600; font-size:0.825rem; display:block; margin-bottom:0.35rem;">
						Incident Category
					</label>
					<select id="fldIncidentType" name="incident_type" class="form-control">
						<option value="wildfire">Wildfire &amp; Evacuation</option>
						<option value="road_closure">Road &amp; Pass Closure</option>
						<option value="weather">Severe Weather / Flood</option>
						<option value="facility">Courthouse &amp; Facility Notice</option>
						<option value="general">General Public Advisory</option>
					</select>
				</div>
			</div>

			<!--- Live Status & Dismissible Checkboxes --->
			<div style="display:flex; gap:1.5rem; align-items:center; padding:0.75rem 1rem; background:rgba(0,115,170,0.04); border-radius:var(--radius-sm); border:1px solid rgba(0,115,170,0.12);">
				<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer; font-size:0.85rem; font-weight:700; color:var(--admin-text-main); margin:0;">
					<input type="checkbox" id="fldIsActive" name="is_active" value="1" checked style="width:16px; height:16px;">
					<span>Deploy Immediately (Live on Public Sites)</span>
				</label>
				<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer; font-size:0.825rem; color:var(--admin-text-muted); margin:0;">
					<input type="checkbox" id="fldIsDismissible" name="is_dismissible" value="1" checked style="width:15px; height:15px;">
					<span>Allow citizens to dismiss banner</span>
				</label>
			</div>

			<div style="display:flex; justify-content:flex-end; gap:0.6rem; padding-top:0.5rem; border-top:1px solid var(--admin-border);">
				<button type="button" class="btn btn-secondary btn-sm" onclick="closeAlertModalDirect()">
					Cancel
				</button>
				<button type="submit" id="btnSubmitAlert" class="btn btn-primary btn-sm" style="padding:0.45rem 1.25rem;">
					#svgIcon(name="radio", size=14)#
					<span>Dispatch Alert</span>
				</button>
			</div>
		</form>
	</div>
</div>

<script>
var presetCatalog = #SerializeJSON(presets)#;

function filterAlertRows() {
	var q = document.getElementById('alertSearchInput').value.toLowerCase().trim();
	var rows = document.querySelectorAll('.alert-row');
	rows.forEach(function(row) {
		var text = row.getAttribute('data-search') || '';
		row.style.display = (!q || text.indexOf(q) !== -1) ? '' : 'none';
	});
}

function openAlertModal() {
	document.getElementById('alertId').value = "0";
	document.getElementById('modalAlertTitle').innerHTML = 'New Emergency Broadcast';
	document.getElementById('fldAlertTitle').value = '';
	document.getElementById('fldAlertMessage').value = '';
	document.getElementById('fldLinkUrl').value = '';
	document.getElementById('fldLinkText').value = 'View Incident Details';
	document.getElementById('fldIsActive').checked = true;
	document.getElementById('fldIsDismissible').checked = true;
	document.getElementById('modalPresetSelect').value = '';
	document.querySelector('input[name="severity"][value="danger"]').checked = true;
	document.getElementById('btnSubmitAlert').querySelector('span').textContent = 'Dispatch Alert';

	document.getElementById('alertModalBackdrop').style.display = 'flex';
	document.getElementById('fldAlertTitle').focus();
}

function closeAlertModal(e) {
	if (e.target.id === 'alertModalBackdrop') {
		closeAlertModalDirect();
	}
}

function closeAlertModalDirect() {
	document.getElementById('alertModalBackdrop').style.display = 'none';
}

function applyPreset(preset) {
	openAlertModal();
	fillModalFromPreset(preset);
}

function onPresetSelectChange(select) {
	var pid = (select.value || '').toLowerCase();
	if (!pid) return;
	for (var i = 0; i < presetCatalog.length; i++) {
		var candId = (presetCatalog[i].id || presetCatalog[i].ID || '').toLowerCase();
		if (candId === pid) {
			fillModalFromPreset(presetCatalog[i]);
			break;
		}
	}
}

function fillModalFromPreset(p) {
	if (!p) return;
	var title = p.title || p.TITLE || '';
	var message = p.message || p.MESSAGE || '';
	var linkUrl = p.link_url || p.LINK_URL || '';
	var linkText = p.link_text || p.LINK_TEXT || 'View Incident Details';
	var incType = (p.incident_type || p.INCIDENT_TYPE || 'wildfire').toLowerCase();
	var sev = (p.severity || p.SEVERITY || 'danger').toLowerCase();
	var presetId = (p.id || p.ID || '').toLowerCase();

	document.getElementById('fldAlertTitle').value = title;
	document.getElementById('fldAlertMessage').value = message;
	document.getElementById('fldLinkUrl').value = linkUrl;
	document.getElementById('fldLinkText').value = linkText;

	if (presetId) {
		var presetSelect = document.getElementById('modalPresetSelect');
		if (presetSelect) {
			presetSelect.value = presetId;
		}
	}

	var radio = document.querySelector('input[name="severity"][value="' + sev + '"]');
	if (radio) {
		radio.checked = true;
	}

	var incSelect = document.getElementById('fldIncidentType');
	if (incSelect && incType) {
		incSelect.value = incType;
	}
}

function editAlert(alert) {
	if (!alert) return;
	var id = alert.id || alert.ID || 0;
	var title = alert.title || alert.TITLE || '';
	var message = alert.message || alert.MESSAGE || '';
	var linkUrl = alert.link_url || alert.LINK_URL || '';
	var linkText = alert.link_text || alert.LINK_TEXT || 'View Incident Details';
	var siteid = alert.siteid || alert.SITEID || 'global';
	var incType = (alert.incident_type || alert.INCIDENT_TYPE || 'general').toLowerCase();
	var isActive = (alert.is_active === true || alert.is_active === 1 || alert.is_active === '1' || alert.IS_ACTIVE === true || alert.IS_ACTIVE === 1 || alert.IS_ACTIVE === '1');
	var isDismiss = (alert.is_dismissible === true || alert.is_dismissible === 1 || alert.is_dismissible === '1' || alert.IS_DISMISSIBLE === true || alert.IS_DISMISSIBLE === 1 || alert.IS_DISMISSIBLE === '1');
	var sev = (alert.severity || alert.SEVERITY || 'danger').toLowerCase();

	document.getElementById('alertId').value = id;
	document.getElementById('modalAlertTitle').innerHTML = 'Edit Emergency Alert ##' + id;
	document.getElementById('fldAlertTitle').value = title;
	document.getElementById('fldAlertMessage').value = message;
	document.getElementById('fldLinkUrl').value = linkUrl;
	document.getElementById('fldLinkText').value = linkText;
	document.getElementById('fldSiteId').value = siteid;
	document.getElementById('fldIncidentType').value = incType;
	document.getElementById('fldIsActive').checked = isActive;
	document.getElementById('fldIsDismissible').checked = isDismiss;

	var radio = document.querySelector('input[name="severity"][value="' + sev + '"]');
	if (radio) radio.checked = true;

	document.getElementById('modalPresetSelect').value = '';
	document.getElementById('btnSubmitAlert').querySelector('span').textContent = 'Save Changes';
	document.getElementById('alertModalBackdrop').style.display = 'flex';
	document.getElementById('fldAlertTitle').focus();
}

function handleAlertFormSubmit(e) {
	e.preventDefault();
	var csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';

	var payload = {
		id: parseInt(document.getElementById('alertId').value) || 0,
		title: document.getElementById('fldAlertTitle').value.trim(),
		message: document.getElementById('fldAlertMessage').value.trim(),
		severity: document.querySelector('input[name="severity"]:checked')?.value || 'danger',
		incident_type: document.getElementById('fldIncidentType').value,
		link_url: document.getElementById('fldLinkUrl').value.trim(),
		link_text: document.getElementById('fldLinkText').value.trim(),
		siteid: document.getElementById('fldSiteId').value,
		is_active: document.getElementById('fldIsActive').checked ? 1 : 0,
		is_dismissible: document.getElementById('fldIsDismissible').checked ? 1 : 0
	};

	if (!payload.title || !payload.message) {
		window.adminAlert({ title: 'Validation Error', message: 'Headline and advisory message are required.', type: 'danger' });
		return;
	}

	var submitBtn = document.getElementById('btnSubmitAlert');
	submitBtn.disabled = true;

	fetch('/alerts/save', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json; charset=utf-8',
			'X-Requested-With': 'XMLHttpRequest',
			'X-CSRF-Token': csrfToken
		},
		body: JSON.stringify(payload)
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		submitBtn.disabled = false;
		if (data.success || data.SUCCESS) {
			closeAlertModalDirect();
			if (window.showToast) window.showToast(data.message || 'Alert saved successfully.', 'success');
			setTimeout(function() { window.location.reload(); }, 600);
		} else {
			window.adminAlert({ title: 'Error', message: data.message || 'Unable to save alert.', type: 'danger' });
		}
	})
	.catch(function(err) {
		submitBtn.disabled = false;
		window.adminAlert({ title: 'System Error', message: err.message, type: 'danger' });
	});
}

function toggleAlert(id) {
	var csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
	fetch('/alerts/toggle', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json; charset=utf-8',
			'X-Requested-With': 'XMLHttpRequest',
			'X-CSRF-Token': csrfToken
		},
		body: JSON.stringify({ id: id })
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		if (data.success || data.SUCCESS) {
			if (window.showToast) window.showToast(data.message, 'success');
			setTimeout(function() { window.location.reload(); }, 500);
		} else {
			window.adminAlert({ title: 'Error', message: data.message, type: 'danger' });
		}
	});
}

async function deleteAlert(id, title) {
	const ok = await window.adminConfirm({
		title: 'Delete Emergency Broadcast?',
		message: 'Are you sure you want to remove "' + title + '" from broadcast history?',
		type: 'danger',
		confirmText: 'Delete Alert',
		cancelText: 'Keep Broadcast'
	});
	if (ok) {
		executeDeleteAlert(id);
	}
}

function executeDeleteAlert(id) {
	var csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
	fetch('/alerts/delete', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json; charset=utf-8',
			'X-Requested-With': 'XMLHttpRequest',
			'X-CSRF-Token': csrfToken
		},
		body: JSON.stringify({ id: id })
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		if (data.success || data.SUCCESS) {
			if (window.showToast) window.showToast('Broadcast deleted.', 'info');
			setTimeout(function() { window.location.reload(); }, 500);
		} else {
			if (window.adminAlert) {
				window.adminAlert({ title: 'Error', message: data.message, type: 'danger' });
			}
		}
	});
}
</script>
</cfoutput>

