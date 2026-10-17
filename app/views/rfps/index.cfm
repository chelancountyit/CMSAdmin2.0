<cfset pageTitle = "Bids & Solicitations Announcements">
<cfoutput>
<!--- CMS Admin 2.0 - Bids & Solicitations Announcements --->
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Bids &amp; Solicitations</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Announcements</li>
				<li class="breadcrumb-item active" aria-current="page">Bids &amp; RFPs</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="#urlFor(controller='rfps', action='publicList')#" target="_blank" rel="noopener" class="btn btn-outline btn-sm" title="View Public Bid Board">
			#svgIcon(name="eye", size=14)#
			<span>Public Bid Board</span>
		</a>
		<a href="#urlFor(controller='rfps', action='new')#" class="btn btn-primary btn-sm" title="Post New Solicitation">
			#svgIcon(name="plus", size=15)#
			<span>+ Post RFP / Bid</span>
		</a>
	</div>
</div>

<!--- Summary KPI Cards --->
<div class="stat-grid" style="margin-bottom:1.5rem;">
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Total Solicitations</span>
			<span class="stat-value">#variables.metrics.total_count#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-info" aria-hidden="true">#svgIcon(name="file-text", size=24)#</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Active / Open</span>
			<span class="stat-value" style="color:var(--admin-success, ##15803d);">#variables.metrics.open_count#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary" aria-hidden="true">#svgIcon(name="gavel", size=24)#</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Closing in &lt; 7 Days</span>
			<span class="stat-value" style="color:var(--admin-warning, ##d97706);">#variables.metrics.closing_soon_count#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-warning" aria-hidden="true">#svgIcon(name="clock", size=24)#</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Closed / Awarded</span>
			<span class="stat-value">#(variables.metrics.under_review_count + variables.metrics.awarded_count)#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-purple" aria-hidden="true">#svgIcon(name="award", size=24)#</div>
	</div>
</div>

<!--- Standard Filter & Search Bar --->
<div class="admin-card" style="margin-bottom:1.5rem; padding:1.25rem 1.5rem;">
	<form method="get" action="#urlFor(controller='rfps', action='index')#" id="rfpsFilterForm" style="display:flex; align-items:flex-end; flex-wrap:wrap; gap:0.85rem; margin:0;">
		
		<div style="flex:2; min-width:220px;">
			<label for="rfpsSearch" class="form-label" style="font-size:0.775rem;">Search Announcements</label>
			<input type="search" id="rfpsSearch" name="q" class="form-control" placeholder="Title, project ##, or keyword..." value="#encodeForHTML(variables.searchQuery)#" style="width:100%; padding:0.5rem 0.75rem; font-size:0.85rem;">
		</div>

		<div style="flex:1; min-width:140px;">
			<label for="rfpsType" class="form-label" style="font-size:0.775rem;">Type</label>
			<select id="rfpsType" name="type" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;" onchange="this.form.submit()">
				<option value="All" #(variables.selectedType eq "All" ? "selected" : "")#>All Types</option>
				<option value="RFP" #(variables.selectedType eq "RFP" ? "selected" : "")#>RFP (Proposals)</option>
				<option value="RFQ" #(variables.selectedType eq "RFQ" ? "selected" : "")#>RFQ (Qualifications)</option>
				<option value="ITB" #(variables.selectedType eq "ITB" ? "selected" : "")#>ITB (Call for Bids)</option>
				<option value="SWR" #(variables.selectedType eq "SWR" ? "selected" : "")#>Small Works Roster</option>
				<option value="NOTICE" #(variables.selectedType eq "NOTICE" ? "selected" : "")#>Sole Source / Notice</option>
			</select>
		</div>

		<div style="flex:1; min-width:140px;">
			<label for="rfpsStatus" class="form-label" style="font-size:0.775rem;">Status</label>
			<select id="rfpsStatus" name="status" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;" onchange="this.form.submit()">
				<option value="All" #(variables.selectedStatus eq "All" ? "selected" : "")#>All Statuses</option>
				<option value="Open" #(variables.selectedStatus eq "Open" ? "selected" : "")#>Open / Active</option>
				<option value="Under Review" #(variables.selectedStatus eq "Under Review" ? "selected" : "")#>Closed / Under Review</option>
				<option value="Awarded" #(variables.selectedStatus eq "Awarded" ? "selected" : "")#>Awarded</option>
				<option value="Draft" #(variables.selectedStatus eq "Draft" ? "selected" : "")#>Draft</option>
				<option value="Cancelled" #(variables.selectedStatus eq "Cancelled" ? "selected" : "")#>Cancelled</option>
			</select>
		</div>

		<div style="display:flex; gap:0.35rem;">
			<button type="submit" class="btn btn-secondary btn-sm" style="padding:0.5rem 0.85rem;">Filter</button>
			<a href="#urlFor(controller='rfps', action='index')#" class="btn btn-outline btn-sm" style="padding:0.5rem 0.85rem;">Reset</a>
		</div>

		<div id="rfpsCount" role="status" aria-live="polite" style="margin-left:auto; font-size:0.8rem; color:var(--admin-text-muted); padding-bottom:0.55rem;">
			Showing <strong>#variables.qSolicitations.recordCount#</strong> announcements
		</div>
	</form>
</div>

<!--- Solicitations Table --->
<div class="admin-card" style="padding:0; overflow:hidden;">
	<div class="table-responsive">
		<table class="admin-table" id="rfpsTable" aria-label="Solicitations list">
			<thead>
				<tr>
					<th scope="col" style="width:60px; text-align:center;">Type</th>
					<th scope="col">Announcement Title &amp; Number</th>
					<th scope="col">Department</th>
					<th scope="col">Submission Deadline</th>
					<th scope="col" style="text-align:center;">Documents</th>
					<th scope="col" style="text-align:center;">Status</th>
					<th scope="col" style="text-align:right; width:130px;">Actions</th>
				</tr>
			</thead>
			<tbody>
				<cfif variables.qSolicitations.recordCount eq 0>
					<tr>
						<td colspan="7" style="text-align:center; padding:3rem 1.5rem; color:var(--admin-text-muted);">
							<div style="margin-bottom:0.75rem;">#svgIcon(name="gavel", size=36)#</div>
							<p style="font-size:1rem; font-weight:600; margin-bottom:0.35rem; color:var(--admin-text-main);">No Solicitations Found</p>
							<p style="font-size:0.85rem; margin-bottom:1rem;">Post an announcement for upcoming vendor proposals, contracts, or public bids.</p>
							<a href="#urlFor(controller='rfps', action='new')#" class="btn btn-primary btn-sm">
								#svgIcon(name="plus", size=14)# Post New RFP / Bid
							</a>
						</td>
					</tr>
				<cfelse>
					<cfloop query="variables.qSolicitations">
						<cfset typeBadgeClass = "badge-neutral">
						<cfif solicitation_type eq "ITB"><cfset typeBadgeClass = "badge-primary">
						<cfelseif solicitation_type eq "RFQ"><cfset typeBadgeClass = "badge-purple">
						<cfelseif solicitation_type eq "RFP"><cfset typeBadgeClass = "badge-info">
						<cfelseif solicitation_type eq "SWR"><cfset typeBadgeClass = "badge-warning">
						</cfif>

						<cfset deadlineDiffDays = DateDiff("d", Now(), submission_deadline)>
						<cfset isPastDeadline = DateDiff("n", Now(), submission_deadline) LTE 0>

						<tr>
							<!--- Type Badge --->
							<td style="text-align:center; vertical-align:middle;">
								<span class="badge #typeBadgeClass#" style="font-size:0.75rem; font-weight:700;">#solicitation_type#</span>
							</td>

							<!--- Title & Number --->
							<td style="vertical-align:middle;">
								<div style="font-size:0.75rem; font-weight:700; color:var(--admin-primary); text-transform:uppercase; letter-spacing:0.04em;">
									#encodeForHTML(solicitation_number)#
								</div>
								<div style="font-weight:600; font-size:0.95rem; margin-top:0.15rem; color:var(--admin-text-main);">
									<a href="#urlFor(controller='rfps', action='edit', params='id=' & id)#" style="color:inherit; text-decoration:none;">
										#encodeForHTML(title)#
									</a>
								</div>
								<cfif Len(summary)>
									<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.25rem; max-width:550px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
										#encodeForHTML(summary)#
									</div>
								</cfif>
							</td>

							<!--- Department Workspace --->
							<td style="vertical-align:middle; font-size:0.85rem;">
								<span class="badge badge-neutral" style="font-weight:500;">
									#encodeForHTML(department_name)#
								</span>
							</td>

							<!--- Submission Deadline --->
							<td style="vertical-align:middle; font-size:0.85rem;">
								<div style="font-weight:600; color:var(--admin-text-main);">
									#DateFormat(submission_deadline, "mmm d, yyyy")#
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted);">
									#TimeFormat(submission_deadline, "h:mm tt")#
								</div>
								<cfif status eq "Open">
									<cfif isPastDeadline>
										<span class="badge badge-danger" style="margin-top:0.25rem; font-size:0.7rem;">Closed</span>
									<cfelseif deadlineDiffDays LTE 0>
										<span class="badge badge-danger" style="margin-top:0.25rem; font-size:0.7rem;">CLOSES TODAY</span>
									<cfelseif deadlineDiffDays LTE 3>
										<span class="badge badge-warning" style="margin-top:0.25rem; font-size:0.7rem;">#deadlineDiffDays# day<cfif deadlineDiffDays neq 1>s</cfif> left</span>
									<cfelse>
										<span class="badge badge-neutral" style="margin-top:0.25rem; font-size:0.7rem;">#deadlineDiffDays# days left</span>
									</cfif>
								<cfelseif status eq "Awarded">
									<span class="badge badge-purple" style="margin-top:0.25rem; font-size:0.7rem;">Awarded</span>
								</cfif>
							</td>

							<!--- Documents / Attachments --->
							<td style="text-align:center; vertical-align:middle;">
								<cfset totalDocs = (Len(primary_packet_url) ? 1 : 0) + addenda_count>
								<cfif totalDocs GT 0>
									<span class="badge badge-neutral" style="font-weight:600;" title="#totalDocs# file(s) attached">
										#svgIcon(name="paperclip", size=11)# #totalDocs#
									</span>
								<cfelse>
									<span style="color:var(--admin-text-muted); font-size:0.8rem;">—</span>
								</cfif>
							</td>

							<!--- Status Badge --->
							<td style="text-align:center; vertical-align:middle;">
								#statusBadge(status)#
							</td>

							<!--- Actions --->
							<td style="text-align:right; vertical-align:middle;">
								<div style="display:inline-flex; gap:0.35rem; align-items:center;">
									<a href="#urlFor(controller='rfps', action='edit', params='id=' & id)#" class="btn btn-sm btn-icon-only btn-outline" aria-label="Edit #EncodeForHTMLAttribute(title)#" title="Edit Announcement">
										#svgIcon(name="edit", size=14)#
									</a>
									<a href="/bids/#encodeForHTMLAttribute(slug)#" target="_blank" rel="noopener" class="btn btn-sm btn-icon-only btn-outline" aria-label="Public View" title="View Public Notice">
										#svgIcon(name="eye", size=14)#
									</a>
									<button type="button" class="btn btn-sm btn-icon-only btn-outline" style="color:var(--admin-danger);" onclick="deleteSolicitation(#id#, '#encodeForJavaScript(solicitation_number)#')" aria-label="Delete #EncodeForHTMLAttribute(solicitation_number)#" title="Archive Announcement">
										#svgIcon(name="trash", size=14)#
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
function deleteSolicitation(id, number) {
	window.adminConfirm(
		"Archive Announcement?",
		"Are you sure you want to remove solicitation <strong>" + number + "</strong> from public view?",
		function() {
			fetch("/rfps/delete", {
				method: "POST",
				headers: { "Content-Type": "application/x-www-form-urlencoded" },
				body: "id=" + encodeURIComponent(id)
			})
			.then(function(res) { return res.json(); })
			.then(function(data) {
				if (data.success) {
					window.showToast("Solicitation archived successfully.", "success");
					setTimeout(function() { window.location.reload(); }, 600);
				} else {
					window.adminAlert("Error", data.message || "Failed to archive solicitation.", "error");
				}
			})
			.catch(function(err) {
				window.adminAlert("Error", "Server error while archiving solicitation.", "error");
			});
		}
	);
}
</script>
