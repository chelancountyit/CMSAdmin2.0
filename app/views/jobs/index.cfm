<cfset pageTitle = "Job Postings">
<cfoutput>
<!--- CMS Admin 2.0 - Job Postings Directory (Aligned with Pages & Users listings) --->
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Job Postings</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">HR &amp; Careers</li>
				<li class="breadcrumb-item active" aria-current="page">Job Postings</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="#urlFor(controller='jobs', action='applications')#" class="btn btn-secondary btn-sm" title="View Candidate Applications">
			#svgIcon(name="users", size=14)#
			<span>Applications (#variables.metrics.total_applications#)</span>
		</a>
		<a href="#urlFor(controller='jobs', action='publicList')#" target="_blank" rel="noopener" class="btn btn-outline btn-sm" title="View Public Careers Portal">
			#svgIcon(name="eye", size=14)#
			<span>View Live Portal</span>
		</a>
		<a href="#urlFor(controller='jobs', action='new')#" class="btn btn-primary btn-sm" title="Create New Job Posting">
			#svgIcon(name="plus", size=15)#
			<span>Add Job Listing</span>
		</a>
	</div>
</div>

<!--- Summary KPI Cards (Standard stat-grid matching pages/index.cfm) --->
<div class="stat-grid" style="margin-bottom:1.5rem;">
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Active Openings</span>
			<span class="stat-value">#variables.metrics.active#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary" aria-hidden="true">#svgIcon(name="briefcase", size=24)#</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Total Applications</span>
			<span class="stat-value">#variables.metrics.total_applications#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-info" aria-hidden="true">#svgIcon(name="users", size=24)#</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Scheduled (Future)</span>
			<span class="stat-value">#variables.metrics.scheduled#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-info" aria-hidden="true">#svgIcon(name="clock", size=24)#</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Draft Listings</span>
			<span class="stat-value">#variables.metrics.draft#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-warning" aria-hidden="true">#svgIcon(name="edit", size=24)#</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Closed / Filled</span>
			<span class="stat-value">#variables.metrics.closed#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-success" aria-hidden="true">#svgIcon(name="check-circle", size=24)#</div>
	</div>
</div>

<!--- Standard Filter & Search Bar (admin-card matching pages/index.cfm) --->
<div class="admin-card" style="margin-bottom:1.25rem;">
	<div class="card-body" style="padding:1rem 1.25rem;">
		<form method="get" action="#urlFor(controller='jobs', action='index')#" id="jobsFilterForm" style="display:flex; align-items:flex-end; flex-wrap:wrap; gap:0.85rem; margin:0;">
			
			<!--- Search Input --->
			<div style="flex:1 1 260px; max-width:360px;">
				<label for="jobsSearch" class="form-label" style="font-size:0.775rem;">Search job postings</label>
				<input type="search" id="jobsSearch" name="q" class="form-control" placeholder="Title, class code, or keyword..." value="#encodeForHTML(variables.searchQuery)#" style="width:100%; padding:0.5rem 0.75rem; font-size:0.85rem;">
			</div>

			<!--- Status Filter --->
			<div>
				<label for="jobsStatus" class="form-label" style="font-size:0.775rem;">Status</label>
				<select id="jobsStatus" name="status" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;" onchange="this.form.submit()">
					<option value="Active" <cfif variables.selectedStatus eq "Active">selected</cfif>>Active</option>
					<option value="Scheduled" <cfif variables.selectedStatus eq "Scheduled">selected</cfif>>Scheduled</option>
					<option value="Draft" <cfif variables.selectedStatus eq "Draft">selected</cfif>>Draft</option>
					<option value="Reviewing" <cfif variables.selectedStatus eq "Reviewing">selected</cfif>>Reviewing</option>
					<option value="Closed" <cfif variables.selectedStatus eq "Closed">selected</cfif>>Closed</option>
					<option value="All" <cfif variables.selectedStatus eq "All">selected</cfif>>All statuses</option>
				</select>
			</div>

			<button type="submit" class="btn btn-secondary btn-sm" style="padding:0.5rem 0.85rem;">Filter</button>
			
			<cfif len(variables.searchQuery) or variables.selectedStatus neq "Active">
				<a href="#urlFor(controller='jobs', action='index')#" class="btn btn-outline btn-sm" style="padding:0.5rem 0.85rem;">Reset</a>
			</cfif>

			<!--- Live Count on Right --->
			<div id="jobsCount" role="status" aria-live="polite" style="margin-left:auto; font-size:0.8rem; color:var(--admin-text-muted); padding-bottom:0.55rem;">
				Showing #variables.qJobs.recordCount# of #variables.metrics.total# positions
			</div>
		</form>
	</div>
</div>

<!--- Standard Job Listings Table (admin-card with admin-table matching pages/index.cfm) --->
<div class="admin-card">
	<div class="table-responsive">
		<table class="admin-table" id="jobsTable" aria-label="Job listings">
			<thead>
				<tr>
					<th scope="col" style="width:56px;"><span class="sr-only">Actions</span></th>
					<th scope="col" style="width:140px;">Class Code / PCN</th>
					<th scope="col">Position Title</th>
					<th scope="col">Department</th>
					<th scope="col">Compensation</th>
					<th scope="col" style="text-align:center;">Applicants</th>
					<th scope="col" style="text-align:center;">Status</th>
					<th scope="col" style="text-align:center;">Deadline</th>
				</tr>
			</thead>
			<tbody>
				<cfif variables.qJobs.recordCount eq 0>
					<tr>
						<td colspan="8" style="text-align:center; padding:3.5rem 1.5rem; color:var(--admin-text-muted);">
							<div style="font-size:1.1rem; font-weight:600; color:var(--admin-text-main); margin-bottom:0.5rem;">No job listings found</div>
							<p style="margin:0 0 1.25rem 0; font-size:0.875rem;">No positions match your selected filter criteria. Clear filters or create a new listing.</p>
							<a href="#urlFor(controller='jobs', action='new')#" class="btn btn-primary btn-sm">
								#svgIcon(name="plus", size=14)#
								<span>Add Job Listing</span>
							</a>
						</td>
					</tr>
				<cfelse>
					<cfloop query="variables.qJobs">
						<tr class="job-row">
							<!--- Standard Action Icon (first column, matching pages/index.cfm) --->
							<td>
								<a href="#urlFor(controller='jobs', action='edit', params='id=' & JobID)#" class="btn btn-sm btn-icon-only btn-outline" aria-label="Edit #EncodeForHTMLAttribute(Title)#" title="Edit">
									#svgIcon(name="edit", size=14)#
								</a>
							</td>

							<!--- Class Code / PCN --->
							<td>
								<cfif len(trim(ClassCode))>
									<code>#encodeForHTML(ClassCode)#</code>
								<cfelse>
									<span style="color:var(--admin-text-muted); font-size:0.8rem;">&mdash;</span>
								</cfif>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
									<cfif JobClasificationID eq 1>Full-Time
									<cfelseif JobClasificationID eq 2>Part-Time
									<cfelseif JobClasificationID eq 3>Seasonal
									<cfelseif JobClasificationID eq 4>Temporary
									<cfelse>On-Call</cfif>
								</div>
							</td>

							<!--- Position Title & Metadata --->
							<td>
								<div style="font-weight:600; color:var(--admin-text-main);">
									<a href="#urlFor(controller='jobs', action='edit', params='id=' & JobID)#" style="color:inherit; text-decoration:none;">
										#encodeForHTML(Title)#
									</a>
									<cfif isSupervisor>
										<span class="badge badge-warning" style="font-size:0.65rem; margin-left:0.35rem;">Supervisor</span>
									</cfif>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
									FLSA: #(FLSAClassificationID eq 2 ? 'Exempt' : 'Non-Exempt')#
									<cfif len(SalaryGroup)> &bull; #encodeForHTML(SalaryGroup)#</cfif>
								</div>
							</td>

							<!--- Department / Location --->
							<td>
								<div style="font-weight:600; color:var(--admin-text-main);">
									#encodeForHTML(department_name)#
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
									#encodeForHTML(Location)#
								</div>
							</td>

							<!--- Compensation Range --->
							<td>
								<div style="font-weight:600; color:var(--admin-text-main);">
									<cfif val(MinSalary) gt 0 and val(MaxSalary) gt 0>
										$#numberFormat(MinSalary, ",.__")# &ndash; $#numberFormat(MaxSalary, ",.__")#
									<cfelseif val(MinSalary) gt 0>
										$#numberFormat(MinSalary, ",.__")#
									<cfelse>
										DOE
									</cfif>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
									#encodeForHTML(SalarySchedule)#
								</div>
							</td>

							<!--- Applicants Count Pill --->
							<td style="text-align:center;">
								<a href="#urlFor(controller='jobs', action='applications', params='jobId=' & JobID)#" class="btn btn-sm btn-outline" style="padding:0.25rem 0.55rem; font-size:0.8rem; text-decoration:none; display:inline-flex; align-items:center; gap:0.35rem;" title="View Applicants">
									#svgIcon(name="users", size=13)#
									<span>#applications_count#</span>
									<cfif new_applications_count gt 0>
										<span class="badge badge-danger" style="font-size:0.65rem; padding:0.1rem 0.35rem; border-radius:999px;">#new_applications_count# New</span>
									</cfif>
								</a>
							</td>

							<!--- Status Badge --->
							<td style="text-align:center;">
								<cfset badgeClass = "badge-neutral">
								<cfif StatusCode eq "Active"><cfset badgeClass = "badge-success">
								<cfelseif StatusCode eq "Scheduled"><cfset badgeClass = "badge-info">
								<cfelseif StatusCode eq "Reviewing"><cfset badgeClass = "badge-warning">
								<cfelseif StatusCode eq "Closed"><cfset badgeClass = "badge-danger">
								<cfelseif StatusCode eq "Draft"><cfset badgeClass = "badge-neutral">
								</cfif>
								<span class="badge #badgeClass#">#StatusCode#</span>
							</td>

							<!--- Deadline --->
							<td style="text-align:center; font-size:0.825rem; color:var(--admin-text-muted); white-space:nowrap;">
								<cfif isDate(ApplicationDeadline)>
									#dateFormat(ApplicationDeadline, "mmm d, yyyy")#
								<cfelse>
									<span class="badge badge-neutral" style="font-size:0.7rem;">Open Until Filled</span>
								</cfif>
							</td>
						</tr>
					</cfloop>
				</cfif>
			</tbody>
		</table>
	</div>
</div>
</cfoutput>
