<cfset pageTitle = "Planholders Registry">
<cfoutput>
<!--- CMS Admin 2.0 - Master Planholders Registry --->
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Planholders Registry</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='rfps', action='index')#">Bids &amp; RFPs</a></li>
				<li class="breadcrumb-item active" aria-current="page">Planholders Registry</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="#urlFor(controller='rfps', action='index')#" class="btn btn-outline btn-sm">
			#svgIcon(name="arrow-left", size=14)#
			<span>Back to Solicitations</span>
		</a>
		<a href="#urlFor(controller='rfps', action='exportPlanholdersCsv', params='solicitation_id=' & variables.selectedSolId)#" class="btn btn-secondary btn-sm" title="Export Planholders List as CSV">
			#svgIcon(name="arrow-right", size=14)#
			<span>Export CSV</span>
		</a>
	</div>
</div>

<!--- Filters Card --->
<div class="admin-card" style="margin-bottom:1.5rem; padding:1.25rem 1.5rem;">
	<form method="get" action="#urlFor(controller='rfps', action='planholders')#" id="planholderFilterForm" style="display:flex; align-items:flex-end; flex-wrap:wrap; gap:0.85rem; margin:0;">
		
		<div style="flex:2; min-width:240px;">
			<label for="phSearch" class="form-label" style="font-size:0.775rem;">Search Contractor / Contact</label>
			<input type="search" id="phSearch" name="q" class="form-control" placeholder="Company name, contact person, email, or license ##..." value="#encodeForHTML(variables.searchQuery)#" style="width:100%; padding:0.5rem 0.75rem; font-size:0.85rem;">
		</div>

		<div style="flex:2; min-width:240px;">
			<label for="phSol" class="form-label" style="font-size:0.775rem;">Filter by Solicitation</label>
			<select id="phSol" name="solicitation_id" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;" onchange="this.form.submit()">
				<option value="0">All Solicitations</option>
				<cfloop query="variables.qSolicitationsList">
					<option value="#id#" <cfif variables.selectedSolId eq id>selected</cfif>>#solicitation_number# &mdash; #encodeForHTML(Left(title, 45))#...</option>
				</cfloop>
			</select>
		</div>

		<div style="display:flex; gap:0.35rem;">
			<button type="submit" class="btn btn-secondary btn-sm" style="padding:0.5rem 0.85rem;">Filter</button>
			<a href="#urlFor(controller='rfps', action='planholders')#" class="btn btn-outline btn-sm" style="padding:0.5rem 0.85rem;">Reset</a>
		</div>

		<div id="phCount" role="status" aria-live="polite" style="margin-left:auto; font-size:0.8rem; color:var(--admin-text-muted); padding-bottom:0.55rem;">
			Total Registered: <strong>#variables.qPlanholders.recordCount#</strong> contractors
		</div>
	</form>
</div>

<!--- Planholders Table --->
<div class="admin-card" style="padding:0; overflow:hidden;">
	<div class="table-responsive">
		<table class="admin-table" id="planholdersTable" aria-label="Planholders Master Table">
			<thead>
				<tr>
					<th scope="col">Company &amp; License</th>
					<th scope="col">Contact Person</th>
					<th scope="col">Contact Info</th>
					<th scope="col">Solicitation</th>
					<th scope="col" style="text-align:center;">Role</th>
					<th scope="col" style="text-align:center;">DBE Certified</th>
					<th scope="col">Registered</th>
					<th scope="col" style="text-align:right; width:80px;">Actions</th>
				</tr>
			</thead>
			<tbody>
				<cfif variables.qPlanholders.recordCount eq 0>
					<tr>
						<td colspan="8" style="text-align:center; padding:3rem 1.5rem; color:var(--admin-text-muted);">
							<div style="margin-bottom:0.75rem;">#svgIcon(name="users", size=36)#</div>
							<p style="font-size:1rem; font-weight:600; margin-bottom:0.35rem; color:var(--admin-text-main);">No Planholders Found</p>
							<p style="font-size:0.85rem; margin-bottom:0;">No contractors match your selected search or solicitation filter.</p>
						</td>
					</tr>
				<cfelse>
					<cfloop query="variables.qPlanholders">
						<tr>
							<td style="vertical-align:middle;">
								<div style="font-weight:600; color:var(--admin-text-main);">#encodeForHTML(company_name)#</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); font-family:monospace; margin-top:0.15rem;">
									Lic: #encodeForHTML(contractor_license_number ?: "None Provided")#
								</div>
							</td>
							<td style="vertical-align:middle;">
								#encodeForHTML(contact_name)#
							</td>
							<td style="vertical-align:middle;">
								<div><a href="mailto:#encodeForHTML(email)#" style="color:var(--admin-primary); text-decoration:none; font-size:0.85rem;">#encodeForHTML(email)#</a></div>
								<cfif Len(phone)>
									<div style="font-size:0.775rem; color:var(--admin-text-muted); margin-top:0.15rem;">#encodeForHTML(phone)#</div>
								</cfif>
							</td>
							<td style="vertical-align:middle;">
								<div style="font-size:0.75rem; font-weight:700; color:var(--admin-primary);">
									<a href="#urlFor(controller='rfps', action='edit', params='id=' & solicitation_id)#" style="color:inherit; text-decoration:none;">
										#encodeForHTML(solicitation_number)#
									</a>
								</div>
								<div style="font-size:0.8rem; color:var(--admin-text-muted); max-width:280px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
									#encodeForHTML(solicitation_title)#
								</div>
							</td>
							<td style="text-align:center; vertical-align:middle;">
								<cfif is_prime_contractor eq 1>
									<span class="badge badge-primary" style="font-size:0.7rem;">Prime</span>
								<cfelse>
									<span class="badge badge-neutral" style="font-size:0.7rem;">Sub</span>
								</cfif>
							</td>
							<td style="text-align:center; vertical-align:middle;">
								<cfif is_dbe_certified eq 1>
									<span class="badge badge-success" style="font-size:0.7rem;">Certified</span>
								<cfelse>
									<span style="color:var(--admin-text-muted); font-size:0.8rem;">—</span>
								</cfif>
							</td>
							<td style="vertical-align:middle; font-size:0.8rem; color:var(--admin-text-muted);">
								#DateFormat(registered_at, "mmm d, yyyy")#
							</td>
							<td style="text-align:right; vertical-align:middle;">
								<button type="button" class="btn btn-sm btn-icon-only btn-outline" style="color:var(--admin-danger);" onclick="deletePlanholder(#id#, '#encodeForJavaScript(company_name)#')" title="Remove Planholder">
									#svgIcon(name="trash", size=13)#
								</button>
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
function deletePlanholder(id, company) {
	window.adminConfirm(
		"Remove Planholder?",
		"Are you sure you want to remove <strong>" + company + "</strong> from the planholders list?",
		function() {
			fetch("/rfps/planholder/delete", {
				method: "POST",
				headers: { "Content-Type": "application/x-www-form-urlencoded" },
				body: "id=" + encodeURIComponent(id)
			})
			.then(function(res) { return res.json(); })
			.then(function(data) {
				if (data.success) {
					window.showToast("Planholder removed.", "success");
					setTimeout(function() { window.location.reload(); }, 500);
				} else {
					window.adminAlert("Error", data.message || "Failed to remove planholder.", "error");
				}
			});
		}
	);
}
</script>

