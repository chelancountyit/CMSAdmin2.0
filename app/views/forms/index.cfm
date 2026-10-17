<cfset pageTitle = "Online Forms & Intake Directory">
<cfset currentDeptFilter = structKeyExists(variables, "currentDept") ? variables.currentDept : (structKeyExists(params, "dept") ? LCase(Trim(params.dept)) : "all")>

<style>
	#formsTable .form-department-badge {
		display:inline-flex;
		max-width:100%;
		white-space:nowrap;
		background:#f1f5f9;
		color:#1e293b;
		border-left:3px solid var(--form-dept-color, var(--admin-primary));
	}
	@media (max-width: 900px) {
		#formsTableCard .table-responsive { overflow:visible; }
		#formsTable, #formsTable tbody { display:block; width:100%; }
		#formsTable thead { position:absolute; width:1px; height:1px; padding:0; margin:-1px; overflow:hidden; clip:rect(0, 0, 0, 0); white-space:nowrap; border:0; }
		#formsTable tbody { display:grid; gap:0.85rem; padding:0.85rem; }
		#formsTable tbody tr.form-row {
			display:block;
			background:var(--admin-surface);
			border:1px solid var(--admin-border);
			border-radius:var(--radius-md);
			box-shadow:var(--shadow-sm);
			overflow:hidden;
		}
		#formsTable tbody tr.form-row:hover { background:var(--admin-surface); }
		#formsTable tbody tr.form-row td {
			display:grid;
			grid-template-columns:minmax(6.5rem, 34%) minmax(0, 1fr);
			align-items:start;
			gap:0.75rem;
			padding:0.75rem 0.9rem;
			border-bottom:1px solid var(--admin-border-subtle);
			text-align:left !important;
			overflow-wrap:anywhere;
		}
		#formsTable tbody tr.form-row td::before {
			content:attr(data-label);
			color:var(--admin-text-muted);
			font-size:0.75rem;
			font-weight:700;
		}
		#formsTable tbody tr.form-row td:first-child { display:block; padding:1rem; }
		#formsTable tbody tr.form-row td:first-child::before { content:""; display:none; }
		#formsTable tbody tr.form-row td:last-child { border-bottom:0; }
		#formsTable tbody tr.form-row td:last-child > * { justify-self:end; }
		#formsTable tbody tr.form-row td:nth-child(7) { grid-template-columns:1fr; }
		#formsTable tbody tr.form-row td:nth-child(7)::before { content:"Actions"; }
		#formsTable tbody tr.form-row td:nth-child(7) > * { justify-self:start; }
		#formsTable tbody tr.form-row td:first-child code { white-space:normal; overflow-wrap:anywhere; }
	}
</style>

<!--- CMS Admin 2.0 - All Online Forms Management & Form Builder Directory --->
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.75rem;">
			<h1 class="page-title" style="margin-bottom:0;">Online Forms &amp; Intake Directory</h1>
			<span class="badge badge-primary">Form Builder</span>
		</div>
		<ol class="breadcrumb" style="margin-top:0.35rem;">
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>"><cfoutput>#svgIcon(name="dashboard", size=14)#</cfoutput> Home</a></li>
			<li class="breadcrumb-item">Content Management</li>
			<li class="breadcrumb-item active">Active Forms</li>
		</ol>
	</div>

	<div class="page-actions" style="display:flex; gap:0.5rem; flex-wrap:wrap;">
		<button type="button" class="btn btn-secondary btn-sm" id="btnOpenTemplatesListModal">
			<cfoutput>#svgIcon(name="sparkles", size=14)#</cfoutput>
			<span>Browse Starter Templates</span>
		</button>
		<a href="<cfoutput>#urlFor(controller='forms', action='builder')#</cfoutput>" class="btn btn-primary btn-sm">
			<cfoutput>#svgIcon(name="plus", size=15)#</cfoutput>
			<span>+ Open Form Builder</span>
		</a>
	</div>
</div>

<!--- Metric Cards for Online Forms Directory --->
<div class="stat-grid" style="margin-bottom:1.5rem;">
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Active Online Forms</span>
			<span class="stat-value" id="statFormCount"><cfoutput>#formMetrics.total#</cfoutput></span>
			<span class="stat-change up">
				<cfoutput>#svgIcon(name="trending-up", size=13)#</cfoutput>
				<span><cfoutput>#formMetrics.published#</cfoutput> Published &bull; <cfoutput>#formMetrics.draft#</cfoutput> Drafts &bull; <cfoutput>#formMetrics.workspaces#</cfoutput> Workspaces</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary">
			<cfoutput>#svgIcon(name="form", size=24)#</cfoutput>
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Total Submissions</span>
			<span class="stat-value"><cfoutput>#formMetrics.submissions#</cfoutput></span>
			<span class="stat-change up">
				<cfoutput>#svgIcon(name="check-circle", size=13)#</cfoutput>
				<span><cfoutput>#formMetrics.pending#</cfoutput> Awaiting review</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-success">
			<cfoutput>#svgIcon(name="check-circle", size=24)#</cfoutput>
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">ADA WCAG 2.1 AA</span>
			<span class="stat-value" style="color:var(--admin-success);"><cfoutput>#(formMetrics.total ? Round(formMetrics.wcagCompliant * 100 / formMetrics.total) & "%" : "—")#</cfoutput></span>
			<span class="stat-change up" style="color:var(--admin-success);">
				<cfoutput>#svgIcon(name="check", size=13)#</cfoutput>
				<span>Forms marked WCAG compliant</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-success">
			<cfoutput>#svgIcon(name="check", size=24)#</cfoutput>
		</div>
	</div>

	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Spam Bots Blocked</span>
			<span class="stat-value" style="color:var(--admin-info);"><cfoutput>#formMetrics.spamBlocked#</cfoutput></span>
			<span class="stat-change" style="color:var(--admin-info);">
				<cfoutput>#svgIcon(name="shield", size=13)#</cfoutput>
				<span>Blocked submissions</span>
			</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary" style="background:var(--admin-info-light); color:var(--admin-info);">
			<cfoutput>#svgIcon(name="shield", size=24)#</cfoutput>
		</div>
	</div>
</div>

<!--- Active Local Storage Builder Session Banner --->
<div id="activeSessionBanner" style="display:none; background:linear-gradient(135deg, rgba(0,115,170,0.06), rgba(142,68,173,0.06)); border:1px solid var(--admin-primary-focus); border-left:4px solid var(--admin-primary); border-radius:var(--radius-md); padding:0.95rem 1.25rem; margin-bottom:1.5rem; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1rem;">
	<div style="display:flex; align-items:center; gap:0.85rem;">
		<div style="width:36px; height:36px; border-radius:50%; background:var(--admin-primary-light); color:var(--admin-primary); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
			<cfoutput>#svgIcon(name="sparkles", size=18)#</cfoutput>
		</div>
		<div>
			<div style="display:flex; align-items:center; gap:0.5rem;">
				<span class="badge badge-primary" style="font-size:0.68rem; font-weight:700;">Live In-Builder Draft</span>
				<strong id="sessionFormTitle" style="color:var(--admin-text-main); font-size:0.95rem;">Custom Form In Progress</strong>
			</div>
			<div id="sessionFormMeta" style="font-size:0.775rem; color:var(--admin-text-muted); margin-top:2px;">
				Unsaved modifications detected in local Form Builder studio
			</div>
		</div>
	</div>
	<div style="display:flex; gap:0.5rem;">
		<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='resume=1')#</cfoutput>" class="btn btn-primary btn-sm">
			<cfoutput>#svgIcon(name="edit", size=13)#</cfoutput>
			<span>Resume In Builder</span>
		</a>
		<a href="<cfoutput>#urlFor(controller='forms', action='preview')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm">
			<cfoutput>#svgIcon(name="eye", size=13)#</cfoutput>
			<span>Preview Draft</span>
		</a>
	</div>
</div>

<!--- Filter & Control Bar Card --->
<div class="admin-card" style="margin-bottom:1.25rem;">
	<div class="card-body" style="padding:1rem 1.25rem; display:flex; flex-direction:column; gap:0.85rem;">
		<!--- Top row: Search input + View switcher + Bulk actions --->
		<div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:0.85rem;">
			<!--- Search bar --->
			<div style="position:relative; width:340px; max-width:100%;">
				<span style="position:absolute; left:0.75rem; top:50%; transform:translateY(-50%); color:var(--admin-text-subtle); display:flex; pointer-events:none;">
					<cfoutput>#svgIcon(name="search", size=14)#</cfoutput>
				</span>
				<input type="text" id="formsSearchInput" class="form-control" placeholder="Search forms by title, slug, or department..." style="width:100%; box-sizing:border-box; padding:0.5rem 2rem 0.5rem 2.25rem; font-size:0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg);">
				<button type="button" id="btnClearSearch" style="display:none; position:absolute; right:0.5rem; top:50%; transform:translateY(-50%); background:none; border:none; color:var(--admin-text-subtle); cursor:pointer; font-size:1rem; line-height:1; padding:0 4px;">&times;</button>
			</div>

			<div style="display:flex; align-items:center; gap:0.75rem;">
				<!--- Status filter pills --->
				<div class="status-filter-pills" style="display:flex; gap:0.25rem; background:var(--admin-bg); padding:3px; border-radius:var(--radius-sm); border:1px solid var(--admin-border);">
					<button type="button" class="btn btn-sm status-pill btn-primary" data-status="all" style="font-size:0.75rem; padding:0.2rem 0.55rem;">All (<cfoutput>#formMetrics.total#</cfoutput>)</button>
					<button type="button" class="btn btn-sm status-pill btn-outline" data-status="published" style="font-size:0.75rem; padding:0.2rem 0.55rem;">Published (<cfoutput>#formMetrics.published#</cfoutput>)</button>
					<button type="button" class="btn btn-sm status-pill btn-outline" data-status="draft" style="font-size:0.75rem; padding:0.2rem 0.55rem;">Drafts (<cfoutput>#formMetrics.draft#</cfoutput>)</button>
					<button type="button" class="btn btn-sm status-pill btn-outline" data-status="archived" style="font-size:0.75rem; padding:0.2rem 0.55rem;">Archived (<cfoutput>#formMetrics.archived#</cfoutput>)</button>
				</div>

				<!--- View toggle (Table vs Card view) --->
				<div class="view-toggle" style="display:flex; gap:2px; background:var(--admin-bg); padding:2px; border-radius:var(--radius-sm); border:1px solid var(--admin-border);">
					<button type="button" class="btn btn-sm btn-icon-only btn-primary" id="btnViewTable" title="Table View" style="width:28px; height:28px;">
						<cfoutput>#svgIcon(name="list", size=14)#</cfoutput>
					</button>
					<button type="button" class="btn btn-sm btn-icon-only btn-outline" id="btnViewGrid" title="Card Grid View" style="width:28px; height:28px;">
						<cfoutput>#svgIcon(name="grid", size=14)#</cfoutput>
					</button>
				</div>
			</div>
		</div>

		<div style="display:flex; align-items:center; justify-content:flex-end; border-top:1px solid var(--admin-border-subtle); padding-top:0.75rem;">
			<div id="formsFilterCount" style="font-size:0.775rem; color:var(--admin-text-muted);">
				<cfoutput>Showing #formMetrics.total# of #formMetrics.total# forms</cfoutput>
			</div>
		</div>
	</div>
</div>

<!--- Main Container: Forms List (Table View) --->
<div class="admin-card" id="formsTableCard">
	<div class="table-responsive">
		<table class="admin-table" id="formsTable">
			<thead>
				<tr>
					<th>Form Title &amp; Endpoint</th>
					<th>Department</th>
					<th>Components &amp; Fields</th>
					<th>Submissions</th>
					<th>Status</th>
					<th>Last Updated</th>
					<th style="text-align:right;">Actions</th>
				</tr>
			</thead>
			<tbody id="formsTableBody">
				<cfloop array="#formsList#" index="formItem">
					<cfoutput>
						<tr class="form-row" data-form-id="#formItem.id#" data-dept="#EncodeForHTMLAttribute(formItem.deptKey)#" data-status="#EncodeForHTMLAttribute(formItem.status)#" data-title="#EncodeForHTMLAttribute(formItem.title)#" data-slug="#EncodeForHTMLAttribute(formItem.slug)#" data-dept-name="#EncodeForHTMLAttribute(formItem.deptName)#" data-edit-url="#EncodeForHTMLAttribute(formItem.editUrl)#" data-preview-url="#EncodeForHTMLAttribute(formItem.previewUrl)#" data-public-url="#EncodeForHTMLAttribute(formItem.publicUrl)#" data-delete-url="#EncodeForHTMLAttribute(urlFor(route='formSoftDelete'))#">
							<td data-label="Form">
								<div style="display:flex; align-items:flex-start; gap:0.5rem;">
									<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-primary-light); color:var(--admin-primary); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
										#svgIcon(name=formItem.deptIcon, size=16)#
									</div>
									<div>
										<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
											<a href="#EncodeForHTMLAttribute(formItem.editUrl)#" style="color:inherit; text-decoration:none;">#EncodeForHTML(formItem.title)#</a>
										</div>
										<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
											<code>#EncodeForHTML(formItem.previewUrl)#</code>
										</div>
										<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">#EncodeForHTML(formItem.description)#</div>
									</div>
								</div>
							</td>
							<td data-label="Department"><span class="badge form-department-badge" style="--form-dept-color:#EncodeForHTMLAttribute(formItem.deptColor)#;">#EncodeForHTML(formItem.deptName)#</span></td>
							<td data-label="Components &amp; Fields">
								<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">#formItem.fieldCount# Fields</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted);">#EncodeForHTML(ArrayToList(formItem.fieldTypeLabels, ", "))#</div>
							</td>
							<td data-label="Submissions">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">#formItem.submissionsCount#</strong>
								<div style="font-size:0.75rem; color:var(--admin-text-muted);">#formItem.pendingCount# pending</div>
							</td>
							<td data-label="Status"><span class="badge #(formItem.status eq 'published' ? 'badge-success' : (formItem.status eq 'draft' ? 'badge-neutral' : 'badge-danger'))#">#EncodeForHTML(UCase(Left(formItem.status, 1)) & Mid(formItem.status, 2, Len(formItem.status)))#</span></td>
							<td data-label="Last Updated" style="color:var(--admin-text-muted); font-size:0.775rem;">#(IsDate(formItem.updatedAt) ? EncodeForHTML(DateTimeFormat(formItem.updatedAt, "mmm d, yyyy h:nn tt")) : "—")#</td>
							<td data-label="Actions" style="text-align:right; white-space:nowrap;">
								<a href="#EncodeForHTMLAttribute(formItem.editUrl)#" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder">#svgIcon(name="edit", size=14)#</a>
								<a href="#EncodeForHTMLAttribute(formItem.previewUrl)#" target="_blank" rel="noopener" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form">#svgIcon(name="eye", size=14)#</a>
								<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="#EncodeForHTMLAttribute(formItem.title)#" data-url="#EncodeForHTMLAttribute(formItem.publicUrl)#" data-slug="#EncodeForHTMLAttribute(formItem.slug)#" title="Share &amp; Embed Form">#svgIcon(name="share-2", size=14)#</button>
								<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-delete-form" title="Delete form" aria-label="Delete #EncodeForHTMLAttribute(formItem.title)#" style="color:var(--admin-danger);">#svgIcon(name="trash", size=14)#</button>
							</td>
						</tr>
					</cfoutput>
				</cfloop>
				<cfif false>
				<!--- 1. HRM Candidate Application --->
				<tr class="form-row" data-dept="hrm" data-status="published" data-title="Chelan County Employment Application &amp; Candidate Intake" data-slug="hrm-employment-application">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-purple-light); color:var(--admin-purple); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="briefcase", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=hrm')#</cfoutput>" style="color:inherit; text-decoration:none;">Chelan County Employment Application &amp; Candidate Intake</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/preview?template=hrm</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=hrm" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">HRM official candidate intake with EOE disclaimers and qualifications.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-purple" style="font-weight:600;">
							<cfoutput>#svgIcon(name="briefcase", size=12)#</cfoutput>
							<span>HRM</span>
						</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">14 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Address Block</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Signature</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">File Upload</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Radios</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">61</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">applicants</span>
							</div>
							<div style="display:flex; align-items:center; gap:0.4rem; font-size:0.7rem; color:var(--admin-purple);">
								<span style="display:inline-block; width:6px; height:6px; border-radius:50%; background:var(--admin-purple);"></span>
								<span>14 pending review</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem; display:inline-flex; align-items:center; gap:4px;">
							<span style="display:inline-block; width:6px; height:6px; border-radius:50%; background:#fff;"></span>
							Published
						</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Today, 11:20 AM</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by HRM Admin</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=hrm')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview', params='template=hrm')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Intake Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Chelan County Employment Application &amp; Candidate Intake" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=hrm" data-slug="hrm-employment-application" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="hrm" data-title="Employment Application Candidates" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 2. PIO Media Inquiry --->
				<tr class="form-row" data-dept="pio" data-status="published" data-title="Public Information Office (PIO) - Media &amp; Press Inquiry Form" data-slug="pio-media-inquiry">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-info-light); color:var(--admin-info); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="megaphone", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=pio')#</cfoutput>" style="color:inherit; text-decoration:none;">Public Information Office (PIO) - Media &amp; Press Inquiry Form</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/preview?template=pio</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=pio" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Intake for journalists, interview requests, and deadline press releases.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-info" style="font-weight:600;">
							<cfoutput>#svgIcon(name="megaphone", size=12)#</cfoutput>
							<span>PIO</span>
						</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">10 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Urgent Switch</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Date Picker</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Radios</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">38</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">media inquiries</span>
							</div>
							<div style="display:flex; align-items:center; gap:0.4rem; font-size:0.7rem; color:var(--admin-danger);">
								<span style="display:inline-block; width:6px; height:6px; border-radius:50%; background:var(--admin-danger);"></span>
								<span>2 active breaking deadlines</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Today, 9:45 AM</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Communications PIO</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=pio')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview', params='template=pio')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Intake Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Public Information Office (PIO) - Media &amp; Press Inquiry Form" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=pio" data-slug="pio-media-inquiry" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="pio" data-title="Media Inquiries" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 3. PIO Public Records Request --->
				<tr class="form-row" data-dept="pio" data-status="published" data-title="Public Information Office - Public Records Request (PRR RCW 42.56)" data-slug="pio-public-records-request">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-info-light); color:var(--admin-info); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="article", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=pio')#</cfoutput>" style="color:inherit; text-decoration:none;">Public Records &amp; Information Request (PRR RCW 42.56)</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/pio-public-records-request</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/pio-public-records-request" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Public Records Officer intake for Washington state public disclosure requests.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-info" style="font-weight:600;">
							<cfoutput>#svgIcon(name="megaphone", size=12)#</cfoutput>
							<span>PIO</span>
						</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">8 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Address Block</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">File Upload</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Legal Notice</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">85</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">PRR filings</span>
							</div>
							<div style="font-size:0.7rem; color:var(--admin-success);">
								<span>81 fulfilled on time</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Oct 1, 2026</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Legal / PIO</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=pio')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview', params='template=pio')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Public Records Request (PRR)" data-url="http://cmsadmin.chelancounty.gov/forms/pio-public-records-request" data-slug="pio-public-records-request" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="prr" data-title="Public Records Filings" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 4. HRM Employee Incident / Leave Request --->
				<tr class="form-row" data-dept="hrm" data-status="published" data-title="HRM - Employee Incident &amp; Leave Request" data-slug="hrm-incident-leave-request">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-purple-light); color:var(--admin-purple); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="briefcase", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=hrm')#</cfoutput>" style="color:inherit; text-decoration:none;">HRM - Employee Incident &amp; Leave Request</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/hrm-incident-leave-request</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/hrm-incident-leave-request" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Internal county staff workplace incident reports and FMLA / bereavement leave requests.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-purple" style="font-weight:600;">
							<cfoutput>#svgIcon(name="briefcase", size=12)#</cfoutput>
							<span>HRM</span>
						</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">8 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Signature</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">File Upload</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Date</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">19</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">requests</span>
							</div>
							<div style="font-size:0.7rem; color:var(--admin-text-subtle);">Confidential HRM Queue</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Yesterday, 3:15 PM</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Benefits Officer</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=hrm')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview', params='template=hrm')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="HRM Employee Incident &amp; Leave Request" data-url="http://cmsadmin.chelancounty.gov/forms/hrm-incident-leave-request" data-slug="hrm-incident-leave-request" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="hrm-leave" data-title="Leave Requests" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 5. Resident Satisfaction Survey (PIO) --->
				<tr class="form-row" data-dept="pio" data-status="published" data-title="Chelan County Resident Satisfaction Survey" data-slug="resident-satisfaction-survey">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-warning-light); color:var(--admin-warning); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="star", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=survey')#</cfoutput>" style="color:inherit; text-decoration:none;">Chelan County Resident Satisfaction Survey</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/resident-satisfaction-survey</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/resident-satisfaction-survey" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Annual community survey gathering feedback on roads, sheriff, and county services.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-info" style="font-weight:600;">
							<cfoutput>#svgIcon(name="megaphone", size=12)#</cfoutput>
							<span>PIO</span>
						</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">7 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Star Rating</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Radios</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Select</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">114</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">citizen responses</span>
							</div>
							<div style="font-size:0.7rem; color:var(--admin-warning);">
								<span>4.8 / 5.0 Avg Rating</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Oct 1, 2026</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by PIO Team</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=survey')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Chelan County Resident Satisfaction Survey" data-url="http://cmsadmin.chelancounty.gov/forms/resident-satisfaction-survey" data-slug="resident-satisfaction-survey" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="survey" data-title="Satisfaction Survey Responses" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 6. General Contact & Inquiry Form (Admin) --->
				<tr class="form-row" data-dept="admin" data-status="published" data-title="General Public Contact &amp; Inquiry Form" data-slug="contact-inquiry">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-primary-light); color:var(--admin-primary); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="form", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder')#</cfoutput>" style="color:inherit; text-decoration:none;">General Public Contact &amp; Inquiry Form</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/contact-inquiry</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/contact-inquiry" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Standard county portal contact intake for Commissioners Office and Administration.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-primary" style="font-weight:600;">Administration</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">6 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Select</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Textarea</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Email</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">182</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">inquiries</span>
							</div>
							<div style="font-size:0.7rem; color:var(--admin-success);">
								<span>+24 this week</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Today, 10:15 AM</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by County Admin</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="General Public Contact &amp; Inquiry Form" data-url="http://cmsadmin.chelancounty.gov/forms/contact-inquiry" data-slug="contact-inquiry" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="contact" data-title="Public Inquiries" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 7. Community Workshop & Event RSVP (Admin) --->
				<tr class="form-row" data-dept="admin" data-status="published" data-title="Community Workshop &amp; Public Hearing RSVP" data-slug="event-rsvp">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-primary-light); color:var(--admin-primary); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="calendar", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=event')#</cfoutput>" style="color:inherit; text-decoration:none;">Community Workshop &amp; Public Hearing RSVP</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/event-rsvp</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/event-rsvp" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Event seat reservations and accessibility accommodation requests for town halls.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-primary" style="font-weight:600;">Administration</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">6 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Checkboxes</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Switch</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Number</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">30</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">seats reserved</span>
							</div>
							<div style="font-size:0.7rem; color:var(--admin-success);">
								<span>4 special accommodations</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Sep 24, 2026</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Clerk of the Board</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=event')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Community Workshop &amp; Public Hearing RSVP" data-url="http://cmsadmin.chelancounty.gov/forms/event-rsvp" data-slug="event-rsvp" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="event" data-title="Workshop Registrations" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 8. Community Development Permit Inquiry --->
				<tr class="form-row" data-dept="community" data-status="published" data-title="Online Building Permit &amp; Planning Inquiry" data-slug="permit-inquiry">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-warning-light); color:var(--admin-warning); display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="building", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=permit')#</cfoutput>" style="color:inherit; text-decoration:none;">Online Building Permit &amp; Planning Inquiry</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/permit-inquiry</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/permit-inquiry" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Permit preliminary consultation, zoning questions, and site plan document uploads.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-warning" style="font-weight:600;">Community Dev</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">9 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Address Block</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">File Upload</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Signature</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">58</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">inquiries</span>
							</div>
							<div style="font-size:0.7rem; color:var(--admin-text-subtle);">Assigned to Planning Desk</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Sep 28, 2026</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Planning Specialist</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=permit')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Online Building Permit &amp; Planning Inquiry" data-url="http://cmsadmin.chelancounty.gov/forms/permit-inquiry" data-slug="permit-inquiry" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="permit" data-title="Permit &amp; Planning Inquiries" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 9. Short-Term Rental Complaint (Community Dev) - Draft --->
				<tr class="form-row" data-dept="community" data-status="draft" data-title="Short-Term Vacation Rental (STR) Complaint Intake" data-slug="str-complaint-intake">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:#f1f5f9; color:#64748b; display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="map-pin", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder')#</cfoutput>" style="color:inherit; text-decoration:none;">Short-Term Vacation Rental (STR) Complaint Intake</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/str-complaint-intake</code>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Neighbor noise, parking, and permit compliance reports for STR properties.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-warning" style="font-weight:600;">Community Dev</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">8 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Address Block</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">File Upload</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">0</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">in draft</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-neutral" style="font-size:0.75rem;">Draft</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Oct 2, 2026</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Code Enforcement</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Short-Term Vacation Rental (STR) Complaint Intake" data-url="http://cmsadmin.chelancounty.gov/forms/str-complaint-intake" data-slug="str-complaint-intake" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 10. Report a Problem & Citizen Service Request (Public Works) --->
				<tr class="form-row" data-dept="works" data-status="published" data-title="Report a Problem &amp; Citizen Service Request (Public Works)" data-slug="report-a-problem" data-template="problem">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:rgba(217,119,6,0.15); color:#d97706; display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="alert-triangle", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=problem')#</cfoutput>" style="color:inherit; text-decoration:none;">Report a Problem &amp; Citizen Service Request</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/preview?template=problem</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=problem" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Public Works intake for potholes, road hazards, streetlights, drainage washouts, and park maintenance.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge" style="font-weight:600; background:rgba(217,119,6,0.15); color:#d97706; border:1px solid rgba(217,119,6,0.3);">
							<cfoutput>#svgIcon(name="alert-triangle", size=12)#</cfoutput>
							<span>Public Works</span>
						</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">10 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Address / GPS</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Photo Upload</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Urgency Select</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">42</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">service tickets</span>
							</div>
							<div style="display:flex; align-items:center; gap:0.4rem; font-size:0.7rem; color:#d97706;">
								<span style="display:inline-block; width:6px; height:6px; border-radius:50%; background:#d97706;"></span>
								<span>3 active priority dispatches</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Today, 8:30 AM</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Road Maintenance</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=problem')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview', params='template=problem')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Report a Problem &amp; Citizen Service Request" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=problem" data-slug="report-a-problem" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="problem" data-title="Problem &amp; Service Reports" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>

				<!--- 11. Report Infestations & Pests (Natural Resources) --->
				<tr class="form-row" data-dept="natural" data-status="published" data-title="Report Infestations &amp; Noxious Weeds (Natural Resources)" data-slug="report-infestations" data-template="infestation">
					<td>
						<div style="display:flex; align-items:flex-start; gap:0.5rem;">
							<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:rgba(21,128,61,0.15); color:#15803d; display:flex; align-items:center; justify-content:center; flex-shrink:0; margin-top:2px;">
								<cfoutput>#svgIcon(name="bug", size=16)#</cfoutput>
							</div>
							<div>
								<div style="font-weight:600; color:var(--admin-text-main); font-size:0.9rem;">
									<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=infestation')#</cfoutput>" style="color:inherit; text-decoration:none;">Report Infestations &amp; Noxious Weeds</a>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-subtle); display:flex; align-items:center; gap:0.35rem; margin-top:2px;">
									<code>/forms/preview?template=infestation</code>
									<button type="button" class="btn-copy-url" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=infestation" title="Copy public form URL" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; padding:0; display:inline-flex;">
										<cfoutput>#svgIcon(name="link", size=12)#</cfoutput>
									</button>
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">Landowner and agricultural reporting for noxious weeds, Apple Maggot, tree borers, and invasive pests.</div>
							</div>
						</div>
					</td>
					<td>
						<span class="badge" style="font-weight:600; background:rgba(21,128,61,0.15); color:#15803d; border:1px solid rgba(21,128,61,0.3);">
							<cfoutput>#svgIcon(name="bug", size=12)#</cfoutput>
							<span>Natural Resources</span>
						</span>
					</td>
					<td>
						<div style="font-weight:600; font-size:0.85rem; color:var(--admin-text-main); margin-bottom:2px;">11 Fields</div>
						<div style="display:flex; gap:3px; flex-wrap:wrap;">
							<span class="badge badge-neutral" style="font-size:0.65rem;">Parcel / GPS</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Specimen Photo</span>
							<span class="badge badge-neutral" style="font-size:0.65rem;">Acreage Radios</span>
						</div>
					</td>
					<td>
						<div style="display:flex; flex-direction:column; gap:2px;">
							<div style="display:flex; align-items:center; gap:0.4rem;">
								<strong style="color:var(--admin-text-main); font-size:0.95rem;">27</strong>
								<span style="font-size:0.75rem; color:var(--admin-text-muted);">weed filings</span>
							</div>
							<div style="display:flex; align-items:center; gap:0.4rem; font-size:0.7rem; color:#15803d;">
								<span style="display:inline-block; width:6px; height:6px; border-radius:50%; background:#15803d;"></span>
								<span>6 flagged for field inspection</span>
							</div>
						</div>
					</td>
					<td>
						<span class="badge badge-success" style="font-size:0.75rem;">Published</span>
					</td>
					<td style="color:var(--admin-text-muted); font-size:0.775rem;">
						<div>Yesterday, 4:50 PM</div>
						<div style="font-size:0.7rem; color:var(--admin-text-subtle);">by Noxious Weed Board</div>
					</td>
					<td style="text-align:right; white-space:nowrap;">
						<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=infestation')#</cfoutput>" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Form Builder Studio"><cfoutput>#svgIcon(name="edit", size=14)#</cfoutput></a>
						<a href="<cfoutput>#urlFor(controller='forms', action='preview', params='template=infestation')#</cfoutput>" target="_blank" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form"><cfoutput>#svgIcon(name="eye", size=14)#</cfoutput></a>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="Report Infestations &amp; Noxious Weeds" data-url="http://cmsadmin.chelancounty.gov/forms/preview?template=infestation" data-slug="report-infestations" title="Share &amp; Embed Form"><cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput></button>
						<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-view-subs" data-id="infestation" data-title="Infestation &amp; Pest Reports" title="View Submitted Responses"><cfoutput>#svgIcon(name="form", size=14)#</cfoutput></button>
					</td>
				</tr>
				</cfif>
			</tbody>
		</table>
	</div>

	<!--- Empty State when Search yields 0 results --->
	<div id="formsNoResults" style="display:none; padding:3rem 2rem; text-align:center;">
		<div style="width:48px; height:48px; border-radius:50%; background:var(--admin-bg); color:var(--admin-text-subtle); display:inline-flex; align-items:center; justify-content:center; margin-bottom:1rem;">
			<cfoutput>#svgIcon(name="search", size=24)#</cfoutput>
		</div>
		<h3 style="font-size:1.1rem; color:var(--admin-text-main); margin-bottom:0.35rem;">No matching forms found</h3>
		<p style="font-size:0.875rem; color:var(--admin-text-muted); max-width:400px; margin:0 auto 1.25rem auto;">
			Try adjusting your search terms or department workspace filter to view available forms.
		</p>
		<button type="button" class="btn btn-secondary btn-sm" id="btnResetFilters">Reset All Filters</button>
	</div>
</div>

<!--- Alternative Grid / Cards View (Initially hidden, toggled via switcher) --->
<div id="formsGridContainer" style="display:none; margin-bottom:1.5rem;">
	<div style="display:grid; grid-template-columns:repeat(auto-fill, minmax(320px, 1fr)); gap:1.25rem;" id="formsGridCards">
		<!--- Cards are synchronized from row data via JavaScript --->
	</div>
</div>

<!--- =========================================================================
      Interactive Share & Embed Modal
      ========================================================================= --->
<div class="fb-modal" id="modalShareEmbed" role="dialog" aria-modal="true" aria-labelledby="shareModalTitle" style="display:none; position:fixed; top:0; left:0; right:0; bottom:0; z-index:1000; align-items:center; justify-content:center;">
	<div class="fb-modal-backdrop" style="position:absolute; top:0; left:0; right:0; bottom:0; background:rgba(15,23,42,0.6); backdrop-filter:blur(3px);"></div>
	<div class="fb-modal-dialog" style="position:relative; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:var(--shadow-lg); width:640px; max-width:92%; max-height:90vh; overflow-y:auto; border:1px solid var(--admin-border); z-index:1001;">
		<div style="padding:1.25rem 1.5rem; border-bottom:1px solid var(--admin-border); display:flex; align-items:center; justify-content:space-between;">
			<div style="display:flex; align-items:center; gap:0.6rem;">
				<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-primary-light); color:var(--admin-primary); display:flex; align-items:center; justify-content:center;">
					<cfoutput>#svgIcon(name="share-2", size=16)#</cfoutput>
				</div>
				<h3 id="shareModalTitle" style="margin:0; font-size:1.1rem; color:var(--admin-text-main);">Share &amp; Embed Form</h3>
			</div>
			<button type="button" class="btn btn-outline btn-sm btn-icon-only modal-close-btn" style="border:none;" aria-label="Close modal">&times;</button>
		</div>

		<div style="padding:1.5rem; display:flex; flex-direction:column; gap:1.25rem;">
			<div>
				<label style="display:block; font-weight:600; font-size:0.85rem; margin-bottom:0.35rem; color:var(--admin-text-main);">Target Form</label>
				<div id="shareFormNameDisplay" style="font-size:0.95rem; font-weight:600; color:var(--admin-primary);">Form Title</div>
			</div>

			<!--- Option 1: Direct Link --->
			<div>
				<label for="shareDirectUrlInput" style="display:flex; justify-content:space-between; align-items:center; font-weight:600; font-size:0.85rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
					<span>Direct County Portal Link</span>
					<span style="font-size:0.75rem; color:var(--admin-text-muted);">Share with respondents</span>
				</label>
				<div style="display:flex; gap:0.5rem;">
					<input type="text" id="shareDirectUrlInput" class="form-control" readonly style="flex:1; font-family:monospace; font-size:0.8rem; background:var(--admin-bg);">
					<button type="button" class="btn btn-primary btn-sm btn-modal-copy" data-target="shareDirectUrlInput">
						<cfoutput>#svgIcon(name="link", size=13)#</cfoutput>
						<span>Copy Link</span>
					</button>
				</div>
			</div>

			<!--- Option 2: Embed Code (iframe) --->
			<div>
				<label for="shareIframeCodeInput" style="display:flex; justify-content:space-between; align-items:center; font-weight:600; font-size:0.85rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
					<span>Responsive Embed Code (iFrame)</span>
					<span style="font-size:0.75rem; color:var(--admin-text-muted);">For external portals &amp; websites</span>
				</label>
				<div style="position:relative;">
					<textarea id="shareIframeCodeInput" class="form-control" rows="3" readonly style="width:100%; box-sizing:border-box; font-family:monospace; font-size:0.785rem; background:var(--admin-bg); resize:none;"></textarea>
				</div>
				<div style="margin-top:0.4rem; display:flex; justify-content:flex-end;">
					<button type="button" class="btn btn-secondary btn-sm btn-modal-copy" data-target="shareIframeCodeInput">
						<cfoutput>#svgIcon(name="code", size=13)#</cfoutput>
						<span>Copy iFrame Code</span>
					</button>
				</div>
			</div>

			<!--- Option 3: Chelan CMS Shortcode --->
			<div>
				<label for="shareShortcodeInput" style="display:flex; justify-content:space-between; align-items:center; font-weight:600; font-size:0.85rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
					<span>Chelan County CMS Shortcode</span>
					<span style="font-size:0.75rem; color:var(--admin-text-muted);">Paste directly into Articles or Pages</span>
				</label>
				<div style="display:flex; gap:0.5rem;">
					<input type="text" id="shareShortcodeInput" class="form-control" readonly style="flex:1; font-family:monospace; font-size:0.8rem; background:var(--admin-bg);">
					<button type="button" class="btn btn-secondary btn-sm btn-modal-copy" data-target="shareShortcodeInput">
						<span>Copy Shortcode</span>
					</button>
				</div>
			</div>

			<!--- Anti-Spam & WCAG Guarantee Badge --->
			<div style="background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:0.85rem 1rem; display:flex; align-items:center; gap:0.75rem; font-size:0.775rem; color:var(--admin-text-muted);">
				<div style="color:var(--admin-success); display:flex;">
					<cfoutput>#svgIcon(name="shield", size=18)#</cfoutput>
				</div>
				<div>
					<strong>Accessibility &amp; Security Guaranteed:</strong> Forms served through this endpoint include automated anti-spam honeypot detection, submission speed traps, and meet ADA WCAG 2.1 Level AA compliance out of the box.
				</div>
			</div>
		</div>

		<div style="padding:1rem 1.5rem; border-top:1px solid var(--admin-border); background:var(--admin-bg); display:flex; justify-content:flex-end;">
			<button type="button" class="btn btn-secondary btn-sm modal-close-btn">Close</button>
		</div>
	</div>
</div>

<!--- =========================================================================
      Interactive Recent Submissions Drawer / Modal
      ========================================================================= --->
<div class="fb-modal" id="modalSubmissions" role="dialog" aria-modal="true" aria-labelledby="subsModalTitle" style="display:none; position:fixed; top:0; left:0; right:0; bottom:0; z-index:1000; align-items:center; justify-content:center;">
	<div class="fb-modal-backdrop" style="position:absolute; top:0; left:0; right:0; bottom:0; background:rgba(15,23,42,0.6); backdrop-filter:blur(3px);"></div>
	<div class="fb-modal-dialog" style="position:relative; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:var(--shadow-lg); width:780px; max-width:94%; max-height:90vh; overflow-y:auto; border:1px solid var(--admin-border); z-index:1001;">
		<div style="padding:1.25rem 1.5rem; border-bottom:1px solid var(--admin-border); display:flex; align-items:center; justify-content:space-between;">
			<div style="display:flex; align-items:center; gap:0.6rem;">
				<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-success-light); color:var(--admin-success); display:flex; align-items:center; justify-content:center;">
					<cfoutput>#svgIcon(name="check-circle", size=16)#</cfoutput>
				</div>
				<div>
					<h3 id="subsModalTitle" style="margin:0; font-size:1.1rem; color:var(--admin-text-main);">Recent Form Submissions</h3>
					<div id="subsModalSubtitle" style="font-size:0.75rem; color:var(--admin-text-muted);">Review incoming respondent records &bull; Verified Humans</div>
				</div>
			</div>
			<button type="button" class="btn btn-outline btn-sm btn-icon-only modal-close-btn" style="border:none;" aria-label="Close modal">&times;</button>
		</div>

		<div style="padding:1.5rem;">
			<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1rem; flex-wrap:wrap; gap:0.5rem;">
				<span style="font-size:0.825rem; color:var(--admin-text-muted);" id="subsRecordCount">Showing latest 5 received entries</span>
				<button type="button" class="btn btn-outline btn-sm" id="btnExportCSV">
					<cfoutput>#svgIcon(name="download", size=13)#</cfoutput>
					<span>Export All to CSV</span>
				</button>
			</div>

			<div class="table-responsive">
				<table class="admin-table" style="font-size:0.825rem;">
					<thead>
						<tr>
							<th>Reference ID</th>
							<th>Respondent</th>
							<th>Contact Info</th>
							<th>Time Elapsed</th>
							<th>Security Verification</th>
							<th>Status</th>
						</tr>
					</thead>
					<tbody id="subsSampleTableBody">
						<tr>
							<td><code>SUB-94B82A1C</code></td>
							<td><strong>Sarah Connor</strong></td>
							<td>sarah.c@wenatchee.example.com</td>
							<td>18s review time</td>
							<td><span class="badge badge-success">&#10003; Human Verified</span></td>
							<td><span class="badge badge-purple">Pending Review</span></td>
						</tr>
						<tr>
							<td><code>SUB-E7104D99</code></td>
							<td><strong>Marcus Vance</strong></td>
							<td>m.vance@example.org</td>
							<td>42s review time</td>
							<td><span class="badge badge-success">&#10003; Human Verified</span></td>
							<td><span class="badge badge-success">Processed</span></td>
						</tr>
						<tr>
							<td><code>SUB-5A32B8C1</code></td>
							<td><strong>Elena Rostova</strong></td>
							<td>elena@chelandistrict.com</td>
							<td>29s review time</td>
							<td><span class="badge badge-success">&#10003; Human Verified</span></td>
							<td><span class="badge badge-success">Processed</span></td>
						</tr>
						<tr>
							<td><code>SUB-089FC214</code></td>
							<td><strong>David Kim</strong></td>
							<td>dkim@leavenworth.org</td>
							<td>14s review time</td>
							<td><span class="badge badge-success">&#10003; Human Verified</span></td>
							<td><span class="badge badge-warning">Action Required</span></td>
						</tr>
					</tbody>
				</table>
			</div>
		</div>

		<div style="padding:1rem 1.5rem; border-top:1px solid var(--admin-border); background:var(--admin-bg); display:flex; justify-content:flex-end;">
			<button type="button" class="btn btn-secondary btn-sm modal-close-btn">Close</button>
		</div>
	</div>
</div>

<!--- =========================================================================
      Starter Templates Modal
      ========================================================================= --->
<div class="fb-modal" id="modalTemplatesList" role="dialog" aria-modal="true" aria-labelledby="tplModalTitle" style="display:none; position:fixed; top:0; left:0; right:0; bottom:0; z-index:1000; align-items:center; justify-content:center;">
	<div class="fb-modal-backdrop" style="position:absolute; top:0; left:0; right:0; bottom:0; background:rgba(15,23,42,0.6); backdrop-filter:blur(3px);"></div>
	<div class="fb-modal-dialog" style="position:relative; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:var(--shadow-lg); width:860px; max-width:92%; max-height:90vh; overflow-y:auto; border:1px solid var(--admin-border); z-index:1001;">
		<div style="padding:1.25rem 1.5rem; border-bottom:1px solid var(--admin-border); display:flex; align-items:center; justify-content:space-between;">
			<div style="display:flex; align-items:center; gap:0.6rem;">
				<div style="width:32px; height:32px; border-radius:var(--radius-sm); background:var(--admin-primary-light); color:var(--admin-primary); display:flex; align-items:center; justify-content:center;">
					<cfoutput>#svgIcon(name="sparkles", size=16)#</cfoutput>
				</div>
				<div>
					<h3 id="tplModalTitle" style="margin:0; font-size:1.1rem; color:var(--admin-text-main);">Official Chelan County Form Templates</h3>
					<div style="font-size:0.75rem; color:var(--admin-text-muted);">Choose a pre-built starter template to instantly load into the Form Builder Studio</div>
				</div>
			</div>
			<button type="button" class="btn btn-outline btn-sm btn-icon-only modal-close-btn" style="border:none;" aria-label="Close modal">&times;</button>
		</div>

		<div style="padding:1.5rem; display:grid; grid-template-columns:repeat(auto-fill, minmax(310px, 1fr)); gap:1rem;">
			<!--- 1. Contact Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid var(--admin-primary); border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge badge-primary">Administration</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">6 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">General Contact &amp; Inquiry</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Standard public contact form with name, email, department topic selector, and detailed inquiry message.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=contact')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:var(--admin-primary); color:var(--admin-primary);">
					<span>Use Contact Template &rarr;</span>
				</a>
			</div>

			<!--- 2. Resident Survey Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid var(--admin-success); border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge badge-success">Survey</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">7 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">Citizen Satisfaction &amp; Feedback Survey</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Interactive star ratings, multiple choice service satisfaction questions, and feedback comment textareas.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=survey')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:var(--admin-success); color:var(--admin-success);">
					<span>Use Survey Template &rarr;</span>
				</a>
			</div>

			<!--- 3. Community Development Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid var(--admin-warning); border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge badge-warning">Community Dev</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">9 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">Building Permit &amp; Planning Inquiry</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Property site address block, residential/commercial construction permits, site plan file uploads, and applicant signature.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=permit')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:var(--admin-warning); color:var(--admin-warning);">
					<span>Use Permit Template &rarr;</span>
				</a>
			</div>

			<!--- 4. Workshop & Event RSVP Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid var(--admin-purple); border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge badge-purple">Community</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">6 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">Workshop &amp; Event RSVP</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Registration form for public hearings and sessions with guest counts, date selections, and accommodation options.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=event')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:var(--admin-purple); color:var(--admin-purple);">
					<span>Use Event Template &rarr;</span>
				</a>
			</div>

			<!--- 5. HRM Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid var(--admin-purple); border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge badge-purple">HRM</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">14 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">Employment Application &amp; Candidate Intake</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Complete job application with EOE statement, education picker, veteran status radios, 5-part address block, and digital signature.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=hrm')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:var(--admin-purple); color:var(--admin-purple);">
					<span>Use HRM Template &rarr;</span>
				</a>
			</div>

			<!--- 6. PIO Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid var(--admin-info); border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge badge-info">PIO</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">10 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">Media &amp; Press Inquiry Portal</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Journalist intake with news outlet verification, publication deadline picker, and breaking news emergency duty switch.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=pio')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:var(--admin-info); color:var(--admin-info);">
					<span>Use PIO Template &rarr;</span>
				</a>
			</div>

			<!--- 7. Report a Problem Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid #d97706; border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge" style="background:rgba(217,119,6,0.15); color:#d97706; border:1px solid rgba(217,119,6,0.3); font-weight:600;">Public Works</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">10 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">Report a Problem (Citizen Service Request)</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Potholes, road hazards, streetlights, drainage washouts, and park maintenance with photo upload and urgency level.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=problem')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:#d97706; color:#d97706;">
					<span>Use Problem Template &rarr;</span>
				</a>
			</div>

			<!--- 8. Report Infestations & Pests Template Card --->
			<div style="border:1px solid var(--admin-border); border-top:4px solid #15803d; border-radius:var(--radius-md); padding:1.25rem; display:flex; flex-direction:column; justify-content:space-between; background:var(--admin-surface);">
				<div>
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.5rem;">
						<span class="badge" style="background:rgba(21,128,61,0.15); color:#15803d; border:1px solid rgba(21,128,61,0.3); font-weight:600;">Natural Resources</span>
						<span style="font-size:0.75rem; color:var(--admin-text-subtle);">11 Fields</span>
					</div>
					<h4 style="margin:0 0 0.35rem 0; font-size:0.95rem; color:var(--admin-text-main);">Report Infestations &amp; Noxious Weeds</h4>
					<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0 0 1rem 0; line-height:1.4;">
						Landowner and citizen reporting for noxious weeds, Apple Maggot, tree borers, land coordinates, acreage extent, and specimen photos.
					</p>
				</div>
				<a href="<cfoutput>#urlFor(controller='forms', action='builder', params='template=infestation')#</cfoutput>" class="btn btn-outline btn-sm" style="width:100%; border-color:#15803d; color:#15803d;">
					<span>Use Infestation Template &rarr;</span>
				</a>
			</div>
		</div>

		<div style="padding:1rem 1.5rem; border-top:1px solid var(--admin-border); background:var(--admin-bg); display:flex; justify-content:space-between; align-items:center;">
			<a href="<cfoutput>#urlFor(controller='forms', action='builder')#</cfoutput>" class="btn btn-primary btn-sm">
				<cfoutput>#svgIcon(name="plus", size=13)#</cfoutput>
				<span>+ Start Blank Form</span>
			</a>
			<button type="button" class="btn btn-secondary btn-sm modal-close-btn">Close</button>
		</div>
	</div>
</div>

<script>
	document.addEventListener("DOMContentLoaded", function() {
		// 1. Detect if an active form exists in localStorage from the Form Builder Studio
		try {
			const saved = localStorage.getItem("cmsadmin_active_form");
			if (saved) {
				const formObj = JSON.parse(saved);
				if (formObj && formObj.title) {
					const banner = document.getElementById("activeSessionBanner");
					const titleEl = document.getElementById("sessionFormTitle");
					const metaEl = document.getElementById("sessionFormMeta");
					if (banner && titleEl && metaEl) {
						titleEl.innerText = formObj.title;
						const fieldCount = (formObj.fields || []).length;
						const dept = formObj.department || "General Administration";
						const workspace = formObj.workspaceName || formObj.siteid || "Unassigned";
						metaEl.innerText = `${fieldCount} fields configured &bull; Department: ${dept} &bull; Workspace: ${workspace} &bull; ${formObj.dbId ? "Saved to database" : "Unsaved browser draft"}`;
						banner.style.display = "flex";
					}
				}
			}
		} catch(e) {}

		// 2. Department & Status Filtering Logic
		const deptTabs = document.querySelectorAll(".dept-tab");
		const statusPills = document.querySelectorAll(".status-pill");
		const searchInput = document.getElementById("formsSearchInput");
		const btnClearSearch = document.getElementById("btnClearSearch");
		const tableRows = document.querySelectorAll("#formsTableBody tr.form-row");
		const noResults = document.getElementById("formsNoResults");
		const filterCountEl = document.getElementById("formsFilterCount");

		let currentDept = "all";
		let currentStatus = "all";
		let searchQuery = "";

		function filterRows() {
			let visibleCount = 0;
			const totalCount = tableRows.length;

			tableRows.forEach(row => {
				const rowDept = row.getAttribute("data-dept") || "";
				const rowStatus = row.getAttribute("data-status") || "";
				const rowTitle = (row.getAttribute("data-title") || "").toLowerCase();
				const rowSlug = (row.getAttribute("data-slug") || "").toLowerCase();

				const matchesDept = (currentDept === "all" || rowDept === currentDept);
				const matchesStatus = (currentStatus === "all" || rowStatus === currentStatus);
				const matchesSearch = (searchQuery === "" || rowTitle.includes(searchQuery) || rowSlug.includes(searchQuery) || rowDept.includes(searchQuery));

				if (matchesDept && matchesStatus && matchesSearch) {
					row.style.display = "";
					visibleCount++;
				} else {
					row.style.display = "none";
				}
			});

			if (filterCountEl) {
				filterCountEl.innerText = `Showing ${visibleCount} of ${totalCount} forms`;
			}

			if (noResults) {
				noResults.style.display = visibleCount === 0 ? "block" : "none";
			}

			// Synchronize Grid view if currently active
			renderGridView();
		}

		// Department tabs click
		deptTabs.forEach(tab => {
			tab.addEventListener("click", function() {
				deptTabs.forEach(t => {
					t.classList.remove("btn-primary");
					t.classList.add("btn-outline");
				});
				this.classList.add("btn-primary");
				this.classList.remove("btn-outline");
				currentDept = this.getAttribute("data-dept");
				filterRows();
			});
		});

		// Status pills click
		statusPills.forEach(pill => {
			pill.addEventListener("click", function() {
				statusPills.forEach(p => {
					p.classList.remove("btn-primary");
					p.classList.add("btn-outline");
				});
				this.classList.add("btn-primary");
				this.classList.remove("btn-outline");
				currentStatus = this.getAttribute("data-status");
				filterRows();
			});
		});

		// Search input listener
		if (searchInput) {
			searchInput.addEventListener("input", function() {
				searchQuery = this.value.trim().toLowerCase();
				if (btnClearSearch) {
					btnClearSearch.style.display = searchQuery.length > 0 ? "block" : "none";
				}
				filterRows();
			});
		}

		// Clear search button
		if (btnClearSearch) {
			btnClearSearch.addEventListener("click", function() {
				searchInput.value = "";
				searchQuery = "";
				this.style.display = "none";
				searchInput.focus();
				filterRows();
			});
		}

		// Reset filters button in empty state
		const btnReset = document.getElementById("btnResetFilters");
		if (btnReset) {
			btnReset.addEventListener("click", function() {
				currentDept = "all";
				currentStatus = "all";
				searchQuery = "";
				if (searchInput) searchInput.value = "";
				if (btnClearSearch) btnClearSearch.style.display = "none";

				deptTabs.forEach((tab, idx) => {
					tab.classList.toggle("btn-primary", idx === 0);
					tab.classList.toggle("btn-outline", idx !== 0);
				});

				statusPills.forEach((pill, idx) => {
					pill.classList.toggle("btn-primary", idx === 0);
					pill.classList.toggle("btn-outline", idx !== 0);
				});

				filterRows();
			});
		}

		// Check for URL query param `?dept=...`
		const urlParams = new URLSearchParams(window.location.search);
		const deptParam = urlParams.get("dept");
		if (deptParam) {
			const matchingTab = document.querySelector(`.dept-tab[data-dept="${deptParam.toLowerCase()}"]`);
			if (matchingTab) {
				matchingTab.click();
			}
		}

		// 3. View Switcher: Table View vs Card Grid View
		const btnViewTable = document.getElementById("btnViewTable");
		const btnViewGrid = document.getElementById("btnViewGrid");
		const tableCard = document.getElementById("formsTableCard");
		const gridContainer = document.getElementById("formsGridContainer");

		if (btnViewTable && btnViewGrid && tableCard && gridContainer) {
			btnViewTable.addEventListener("click", () => {
				btnViewTable.classList.add("btn-primary");
				btnViewTable.classList.remove("btn-outline");
				btnViewGrid.classList.remove("btn-primary");
				btnViewGrid.classList.add("btn-outline");
				tableCard.style.display = "block";
				gridContainer.style.display = "none";
			});

			btnViewGrid.addEventListener("click", () => {
				btnViewGrid.classList.add("btn-primary");
				btnViewGrid.classList.remove("btn-outline");
				btnViewTable.classList.remove("btn-primary");
				btnViewTable.classList.add("btn-outline");
				tableCard.style.display = "none";
				gridContainer.style.display = "block";
				renderGridView();
			});
		}

		function renderGridView() {
			const gridCards = document.getElementById("formsGridCards");
			if (!gridCards) return;
			gridCards.innerHTML = "";

			tableRows.forEach(row => {
				if (row.style.display === "none") return;

				const title = row.getAttribute("data-title");
				const slug = row.getAttribute("data-slug");
				const dept = row.getAttribute("data-dept");
				const deptName = row.getAttribute("data-dept-name") || dept;
				const status = row.getAttribute("data-status");
				const editUrl = row.getAttribute("data-edit-url") || "/forms/builder";
				const previewUrl = row.getAttribute("data-preview-url") || "/forms/preview";
				const publicUrl = row.getAttribute("data-public-url") || previewUrl;
				const formId = row.getAttribute("data-form-id") || "";
				const deleteUrl = row.getAttribute("data-delete-url") || "";

				const deptBadge = `<span class="badge badge-primary">${escapeHTML(deptName)}</span>`;

				const statusBadge = status === "published"
					? '<span class="badge badge-success">&#9679; Published</span>'
					: `<span class="badge badge-neutral">${escapeHTML(status)}</span>`;

				const topBorderColor = "#0073aa";

				const card = document.createElement("div");
				card.className = "admin-card";
				card.style.margin = "0";
				card.style.display = "flex";
				card.style.flexDirection = "column";
				card.style.justifyContent = "space-between";
				card.style.borderTop = `4px solid ${topBorderColor}`;

				card.innerHTML = `
					<div class="card-body" style="padding:1.25rem;">
						<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.75rem;">
							${deptBadge}
							${statusBadge}
						</div>
						<h3 style="font-size:1rem; font-weight:700; margin:0 0 0.4rem 0; color:var(--admin-text-main); line-height:1.3;">
							${escapeHTML(title)}
						</h3>
						<div style="font-size:0.75rem; color:var(--admin-text-subtle); margin-bottom:0.75rem; font-family:monospace;">
							${escapeHTML(previewUrl)}
						</div>
						<div style="display:flex; gap:0.4rem; flex-wrap:wrap; margin-bottom:0.75rem;">
							<span class="badge badge-success" style="font-size:0.65rem;">&#10003; WCAG 2.1 AA</span>
							<span class="badge badge-primary" style="font-size:0.65rem;">&#128737; Anti-Spam Shield</span>
						</div>
					</div>
					<div class="card-footer" style="padding:0.75rem 1.25rem; display:flex; align-items:center; justify-content:space-between; background:var(--admin-bg);">
						<div style="font-size:0.75rem; color:var(--admin-text-muted);">
							${row.querySelector("td:nth-child(3)")?.innerText || ""}
						</div>
						<div style="display:flex; gap:0.35rem;">
							<a href="${escapeHTML(editUrl)}" class="btn btn-outline btn-sm btn-icon-only" title="Edit in Builder">
								<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/><path d="m15 5 4 4"/></svg>
							</a>
							<a href="${escapeHTML(previewUrl)}" target="_blank" rel="noopener" class="btn btn-outline btn-sm btn-icon-only" title="Preview Public Form">
								<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
							</a>
							<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-delete-form" title="Delete form" aria-label="Delete ${escapeHTML(title)}" style="color:var(--admin-danger);" data-form-id="${escapeHTML(formId)}" data-delete-url="${escapeHTML(deleteUrl)}" data-title="${escapeHTML(title)}">
								<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="m19 6-1 14H6L5 6"/><path d="M10 11v5M14 11v5"/></svg>
							</button>
							<button type="button" class="btn btn-outline btn-sm btn-icon-only btn-share-modal" data-title="${escapeHTML(title)}" data-url="${escapeHTML(publicUrl)}" data-slug="${escapeHTML(slug)}" title="Share & Embed">
								<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" x2="15.42" y1="13.51" y2="17.49"/><line x1="15.41" x2="8.59" y1="6.51" y2="10.49"/></svg>
							</button>
						</div>
					</div>
				`;
				gridCards.appendChild(card);
			});
		}

		filterRows();

		// 4. Copy URL button interaction
		document.querySelectorAll(".btn-copy-url").forEach(btn => {
			btn.addEventListener("click", async function(e) {
				e.stopPropagation();
				const url = this.getAttribute("data-url");
				const ok = typeof window.copyToClipboard === "function"
					? await window.copyToClipboard(url)
					: await fallbackCopyText(url);
				if (ok) {
					showToast("Public form URL copied to clipboard!", "success");
				}
			});
		});

		document.addEventListener("click", async function(e) {
			const btn = e.target.closest(".btn-delete-form");
			if (!btn) return;

			const row = btn.closest(".form-row");
			const formId = btn.getAttribute("data-form-id") || row?.getAttribute("data-form-id");
			const deleteUrl = btn.getAttribute("data-delete-url") || row?.getAttribute("data-delete-url");
			const title = btn.getAttribute("data-title") || row?.getAttribute("data-title") || "this form";
			if (!formId || !deleteUrl) {
				await window.adminAlert("Unable to delete this form because its record details are missing. Refresh the page and try again.", {
					title: "Unable to delete form"
				});
				return;
			}
			if (!await window.adminConfirm(`Delete "${title}"? It will be removed from the Forms list and stop accepting submissions. Existing submissions and audit history will be preserved.`, {
				title: "Delete form?",
				acceptText: "Delete",
				destructive: true
			})) return;

			btn.disabled = true;
			try {
				const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || "";
				const response = await fetch(deleteUrl, {
					method: "POST",
					credentials: "same-origin",
					headers: {
						"Content-Type": "application/json",
						"X-Requested-With": "XMLHttpRequest",
						...(csrfToken ? { "X-CSRF-Token": csrfToken } : {})
					},
					body: JSON.stringify({ id: Number(formId) })
				});
				const result = await response.json();
				if (!response.ok || !result.success) {
					throw new Error(result.message || `Delete failed with HTTP ${response.status}.`);
				}
				showToast(result.message || "Form deleted.");
				window.setTimeout(() => window.location.reload(), 700);
			} catch (error) {
				btn.disabled = false;
				await window.adminAlert(`Unable to delete form: ${error.message}`, {
					title: "Unable to delete form"
				});
			}
		});

		// 5. Share & Embed Modal Dialog Handler
		const shareModal = document.getElementById("modalShareEmbed");
		document.addEventListener("click", function(e) {
			const btn = e.target.closest(".btn-share-modal");
			if (btn) {
				const title = btn.getAttribute("data-title") || "Online Form";
				const url = btn.getAttribute("data-url") || "http://cmsadmin.chelancounty.gov/forms/preview";
				const slug = btn.getAttribute("data-slug") || "form";

				document.getElementById("shareFormNameDisplay").innerText = title;
				document.getElementById("shareDirectUrlInput").value = url;
				document.getElementById("shareIframeCodeInput").value = `<iframe src="${url}" width="100%" height="800" frameborder="0" style="border:none; max-width:100%;" title="${title}"></iframe>`;
				document.getElementById("shareShortcodeInput").value = `[chelan_form slug="${slug}"]`;

				shareModal.style.display = "flex";
			}
		});

		// Modal Copy Buttons
		document.querySelectorAll(".btn-modal-copy").forEach(btn => {
			btn.addEventListener("click", async function() {
				const targetId = this.getAttribute("data-target");
				const input = document.getElementById(targetId);
				if (input && input.value) {
					const ok = typeof window.copyToClipboard === "function"
						? await window.copyToClipboard(input.value)
						: await fallbackCopyText(input.value);
					if (ok) {
						const origText = this.innerHTML;
						this.innerHTML = "<span>&#10003; Copied!</span>";
						setTimeout(() => { this.innerHTML = origText; }, 1800);
						showToast("Copied to clipboard!", "success");
					}
				}
			});
		});

		// 6. Submissions Drawer Modal
		const subsModal = document.getElementById("modalSubmissions");
		document.addEventListener("click", function(e) {
			const btn = e.target.closest(".btn-view-subs");
			if (btn) {
				const title = btn.getAttribute("data-title") || "Form Submissions";
				document.getElementById("subsModalTitle").innerText = title;
				subsModal.style.display = "flex";
			}
		});

		const btnExportCSV = document.getElementById("btnExportCSV");
		if (btnExportCSV) {
			btnExportCSV.addEventListener("click", function() {
				showToast("Exporting respondent submissions to CSV...", "info");
			});
		}

		// 7. Starter Templates Modal
		const tplModal = document.getElementById("modalTemplatesList");
		const btnOpenTpl = document.getElementById("btnOpenTemplatesListModal");
		if (btnOpenTpl) {
			btnOpenTpl.addEventListener("click", () => {
				tplModal.style.display = "flex";
			});
		}

		// Generic Modal Close Buttons & Backdrop clicks
		document.querySelectorAll(".modal-close-btn, .fb-modal-backdrop").forEach(el => {
			el.addEventListener("click", function() {
				document.querySelectorAll(".fb-modal").forEach(m => m.style.display = "none");
			});
		});

		document.addEventListener("keydown", function(e) {
			if (e.key === "Escape") {
				document.querySelectorAll(".fb-modal").forEach(m => m.style.display = "none");
			}
		});

		// Toast Notification Utility
		function showToast(msg, type = "success") {
			if (typeof window.showToast === "function") {
				window.showToast(msg, type);
				return;
			}
			let toast = document.getElementById("cmsToast");
			if (!toast) {
				toast = document.createElement("div");
				toast.id = "cmsToast";
				toast.style.cssText = "position:fixed; bottom:24px; right:24px; background:#ffffff; color:#14532d; border:1px solid #bbf7d0; border-left:5px solid #15803d; padding:0.75rem 1.25rem; border-radius:6px; font-size:0.85rem; font-weight:600; box-shadow:0 10px 15px -3px rgba(0,0,0,0.1); z-index:99999; display:flex; align-items:center; gap:0.5rem; transition:opacity 0.2s;";
				document.body.appendChild(toast);
			}
			toast.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#15803d" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg> <span>${escapeHTML(msg)}</span>`;
			toast.style.opacity = "1";
			toast.style.display = "flex";
			clearTimeout(toast._timer);
			toast._timer = setTimeout(() => {
				toast.style.opacity = "0";
				setTimeout(() => { toast.style.display = "none"; }, 200);
			}, 3000);
		}

		function fallbackCopyText(text) {
			try {
				const ta = document.createElement("textarea");
				ta.value = text;
				ta.style.position = "fixed";
				ta.style.top = "0";
				ta.style.left = "0";
				ta.style.opacity = "0";
				document.body.appendChild(ta);
				ta.focus();
				ta.select();
				const res = document.execCommand("copy");
				document.body.removeChild(ta);
				if (res) return Promise.resolve(true);
			} catch (e) {}
			window.prompt("Copy to clipboard (Ctrl+C):", text);
			return Promise.resolve(true);
		}

		function escapeHTML(str) {
			if (!str) return "";
			return String(str)
				.replace(/&/g, "&amp;")
				.replace(/</g, "&lt;")
				.replace(/>/g, "&gt;")
				.replace(/"/g, "&quot;")
				.replace(/'/g, "&#039;");
		}
	});
</script>
