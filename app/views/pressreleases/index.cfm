<cfparam name="releases" default="#[]#">
<cfparam name="stats" default="#{}#">
<cfparam name="filterStatus" default="all">
<cfparam name="searchQuery" default="">
<cfparam name="activeWorkspaceId" default="global">

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">Press Releases &amp; Media Alerts</h1>
			<span class="badge badge-primary" style="font-size:0.75rem; padding:0.2rem 0.6rem;">
				#Val(stats.total ?: ArrayLen(releases))# Total
			</span>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">PIO</li>
				<li class="breadcrumb-item active" aria-current="page">Press Releases</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="#urlFor(controller='pressReleases', action='api', params='limit=10')#" target="_blank" class="btn btn-outline-secondary btn-sm" title="View Public JSON API Feed">
			#svgIcon(name="code", size=14)#
			<span>Public JSON API</span>
		</a>
		<a href="#urlFor(controller='pressReleases', action='new')#" class="btn btn-primary btn-sm">
			#svgIcon(name="plus", size=14)#
			<span>+ New Press Release</span>
		</a>
	</div>
</div>

<!--- Metric Cards --->
<div class="grid grid-4" style="display:grid; grid-template-columns:repeat(4, minmax(0, 1fr)); gap:1rem; margin-bottom:1.5rem;">
	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid var(--admin-primary);">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(2, 132, 199, 0.1); display:flex; align-items:center; justify-content:center; color:var(--admin-primary);">
			#svgIcon(name="megaphone", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">Total Releases</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#Val(stats.total ?: 0)#</div>
		</div>
	</div>

	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid ##16a34a;">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(22, 163, 74, 0.1); display:flex; align-items:center; justify-content:center; color:##16a34a;">
			#svgIcon(name="check-circle", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">Active</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#Val(stats.active ?: 0)#</div>
		</div>
	</div>

	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid ##d97706;">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(217, 119, 6, 0.1); display:flex; align-items:center; justify-content:center; color:##d97706;">
			#svgIcon(name="pause-circle", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">InActive</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#Val(stats.inactive ?: 0)#</div>
		</div>
	</div>

	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid ##64748b;">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(100, 116, 139, 0.1); display:flex; align-items:center; justify-content:center; color:##64748b;">
			#svgIcon(name="archive", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">Archive</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#Val(stats.archive ?: 0)#</div>
		</div>
	</div>
</div>

<!--- Search and Filter Toolbar --->
<div class="admin-card" style="padding:1rem; margin-bottom:1.5rem;">
	<form method="get" action="#urlFor(controller='pressReleases', action='index')#" style="display:flex; gap:0.75rem; align-items:center; flex-wrap:wrap;">
		<div style="position:relative; flex:1; min-width:260px;">
			<input type="text" name="q" value="#EncodeForHTML(searchQuery)#" placeholder="Search releases by headline, dateline, media contact, or summary..." class="form-control" style="padding-left:2.2rem; width:100%;">
			<span style="position:absolute; left:0.75rem; top:50%; transform:translateY(-50%); color:var(--admin-text-muted); pointer-events:none;">
				#svgIcon(name="search", size=15)#
			</span>
		</div>

		<div style="min-width:180px;">
			<select name="status" class="form-control" onchange="this.form.submit()">
				<option value="all" <cfif filterStatus eq 'all'>selected</cfif>>All Statuses</option>
				<option value="active" <cfif filterStatus eq 'active'>selected</cfif>>Active</option>
				<option value="inactive" <cfif filterStatus eq 'inactive'>selected</cfif>>InActive</option>
				<option value="archive" <cfif filterStatus eq 'archive'>selected</cfif>>Archive</option>
			</select>
		</div>

		<button type="submit" class="btn btn-secondary btn-sm" style="padding:0.45rem 0.9rem;">
			Filter
		</button>
		<cfif Len(searchQuery) or filterStatus neq 'all'>
			<a href="#urlFor(controller='pressReleases', action='index')#" class="btn btn-outline-secondary btn-sm" style="padding:0.45rem 0.8rem;" title="Reset filters">
				#svgIcon(name="x", size=14)# Clear
			</a>
		</cfif>
	</form>
</div>

<!--- Press Releases Table --->
<div class="admin-card" style="padding:0; overflow:hidden;">
	<div class="table-responsive">
		<table class="table" style="margin:0; width:100%; border-collapse:collapse;">
			<thead>
				<tr style="background:var(--admin-bg); border-bottom:1.5px solid var(--admin-border);">
					<th style="padding:0.85rem 1rem;">Headline &amp; Dateline</th>
					<th style="padding:0.85rem 1rem; width:180px;">Media Contact</th>
					<th style="padding:0.85rem 1rem; width:120px; text-align:center;">Status</th>
					<th style="padding:0.85rem 1rem; width:140px;">Release Date</th>
					<th style="padding:0.85rem 1rem; width:160px; text-align:right;">Actions</th>
				</tr>
			</thead>
			<tbody>
				<cfif ArrayLen(releases) eq 0>
					<tr>
						<td colspan="5" style="padding:3rem 1.5rem; text-align:center; color:var(--admin-text-muted);">
							<div style="margin-bottom:0.75rem; color:var(--admin-text-muted);">
								#svgIcon(name="megaphone", size=40)#
							</div>
							<h3 style="margin:0 0 0.5rem; font-size:1.1rem; color:var(--admin-text-main);">No press releases found</h3>
							<p style="margin:0 0 1rem; font-size:0.875rem;">Create and dispatch official county media alerts and press statements.</p>
							<a href="#urlFor(controller='pressReleases', action='new')#" class="btn btn-primary btn-sm">
								#svgIcon(name="plus", size=14)# New Press Release
							</a>
						</td>
					</tr>
				<cfelse>
					<cfloop array="#releases#" index="rel">
						<tr style="border-bottom:1px solid var(--admin-border-subtle); transition:background 0.15s ease;" id="release-row-#rel.id#">
							<td style="padding:0.75rem 1rem; vertical-align:middle;">
								<div style="font-weight:600; font-size:0.95rem; color:var(--admin-text-main); margin-bottom:0.2rem;">
									<a href="#urlFor(controller='pressReleases', action='edit', params='id=#rel.id#')#" style="color:var(--admin-text-main); text-decoration:none;">
										#EncodeForHTML(rel.title)#
									</a>
								</div>
								<div style="font-size:0.8rem; color:var(--admin-text-muted); line-height:1.35; margin-bottom:0.3rem;">
									<strong style="color:var(--admin-text-main); font-size:0.75rem; letter-spacing:0.04em;">#EncodeForHTML(rel.dateline)# &mdash;</strong>
									#EncodeForHTML(rel.summary)#
								</div>
								<div style="display:flex; gap:0.5rem; align-items:center;">
									<span style="font-size:0.72rem; color:var(--admin-text-muted); font-family:monospace;">/#rel.slug#</span>
									<cfif Len(rel.pdf_url)>
										<a href="#EncodeForHTML(rel.pdf_url)#" target="_blank" class="badge badge-neutral" style="font-size:0.68rem; text-decoration:none;" title="Download Attached PDF">
											#svgIcon(name="external-link", size=11)# PDF Attached
										</a>
									</cfif>
								</div>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; font-size:0.85rem;">
								<div style="font-weight:500; color:var(--admin-text-main);">#EncodeForHTML(rel.contact_name ?: "PIO Office")#</div>
								<cfif Len(rel.contact_phone)>
									<div style="font-size:0.75rem; color:var(--admin-text-muted);">#EncodeForHTML(rel.contact_phone)#</div>
								</cfif>
								<cfif Len(rel.contact_email)>
									<div style="font-size:0.72rem; color:var(--admin-primary);">#EncodeForHTML(rel.contact_email)#</div>
								</cfif>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:center;">
								<cfif listFindNoCase("active,released", rel.status)>
									<button type="button" class="badge badge-success" style="cursor:pointer; border:none; padding:0.25rem 0.6rem; font-size:0.72rem;" onclick="toggleReleaseStatus(#rel.id#, 'inactive')" title="Click to set InActive">
										Active
									</button>
								<cfelseif listFindNoCase("inactive,draft,embargoed", rel.status)>
									<button type="button" class="badge badge-warning" style="cursor:pointer; border:none; padding:0.25rem 0.6rem; font-size:0.72rem;" onclick="toggleReleaseStatus(#rel.id#, 'active')" title="Click to set Active">
										InActive
									</button>
								<cfelseif listFindNoCase("archive,archived", rel.status)>
									<button type="button" class="badge badge-neutral" style="cursor:pointer; border:none; padding:0.25rem 0.6rem; font-size:0.72rem;" onclick="toggleReleaseStatus(#rel.id#, 'active')" title="Click to restore to Active">
										Archive
									</button>
								<cfelse>
									<span class="badge badge-neutral" style="font-size:0.72rem; padding:0.25rem 0.6rem;">#EncodeForHTML(rel.status)#</span>
								</cfif>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; font-size:0.8rem; color:var(--admin-text-muted);">
								<cfif IsDate(rel.released_at)>
									#DateFormat(rel.released_at, "mmm d, yyyy")#<br>
									<span style="font-size:0.72rem;">#TimeFormat(rel.released_at, "h:mm tt")#</span>
								<cfelse>
									<span style="font-style:italic;">Pending</span>
								</cfif>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:right;">
								<div style="display:inline-flex; gap:0.35rem; align-items:center;">
									<a href="#urlFor(controller='pressReleases', action='view', params='id=#rel.id#')#" target="_blank" class="btn btn-outline-secondary btn-sm" title="View Official Printer-Friendly Release" style="padding:0.3rem 0.5rem;">
										#svgIcon(name="eye", size=13)#
									</a>
									<a href="#urlFor(controller='pressReleases', action='edit', params='id=#rel.id#')#" class="btn btn-outline-secondary btn-sm" title="Edit Press Release" style="padding:0.3rem 0.5rem;">
										#svgIcon(name="edit", size=13)#
									</a>
									<button type="button" class="btn btn-outline-danger btn-sm" onclick="confirmDeleteRelease(#rel.id#, '#JSStringFormat(rel.title)#')" title="Delete Release" style="padding:0.3rem 0.5rem;">
										#svgIcon(name="trash", size=13)#
									</button>
								</div>
							</td>
						</tr>
					</cfloop>
				</cfif>
			</tbody>
		</table>
	</div>
</div>
</cfoutput>

<script>
async function toggleReleaseStatus(id, newStatus) {
	const ok = await window.adminConfirm({
		title: 'Update Press Release Status?',
		message: 'Change press release status to "' + newStatus + '"?',
		type: 'info',
		acceptText: 'Update Status'
	});
	if (!ok) return;
	fetch('/press-releases/toggle-status', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json; charset=utf-8' },
		body: JSON.stringify({ id: id, status: newStatus })
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			window.location.reload();
		} else {
			window.adminAlert({ title: 'Error', message: res.message || 'Error updating status', type: 'danger' });
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error updating press release status.', type: 'danger' });
	});
}

async function confirmDeleteRelease(id, title) {
	const ok = await window.adminConfirm({
		title: 'Delete Press Release?',
		message: 'Are you sure you want to delete press release "' + title + '"?',
		type: 'danger',
		acceptText: 'Delete Press Release'
	});
	if (!ok) return;
	fetch('/press-releases/delete', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json; charset=utf-8' },
		body: JSON.stringify({ id: id })
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			const row = document.getElementById('release-row-' + id);
			if (row) row.remove();
			if (window.showToast) window.showToast('Press release deleted successfully.', 'success');
		} else {
			window.adminAlert({ title: 'Error', message: res.message || 'Error deleting press release', type: 'danger' });
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error deleting press release.', type: 'danger' });
	});
}
</script>
