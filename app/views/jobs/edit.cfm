<cfset isNew = (variables.job.jobId eq 0)>
<cfset pageTitle = isNew ? "Create Job Listing" : "Edit Job Listing: " & variables.job.title>

<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;"><cfoutput>#encodeForHTML(pageTitle)#</cfoutput></h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>"><cfoutput>#svgIcon(name="dashboard", size=14)#</cfoutput> Home</a></li>
				<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='jobs', action='index')#</cfoutput>">Job Postings</a></li>
				<li class="breadcrumb-item active" aria-current="page"><cfoutput>#(isNew ? 'Create' : 'Edit')#</cfoutput></li>
			</ol>
		</nav>
	</div>

	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="<cfoutput>#urlFor(controller='jobs', action='index')#</cfoutput>" class="btn btn-outline btn-sm">
			Cancel
		</a>
		<cfif not isNew>
			<a href="<cfoutput>#urlFor(controller='jobs', action='applications', params='jobId=' & variables.job.jobId)#</cfoutput>" class="btn btn-secondary btn-sm">
				<cfoutput>#svgIcon(name="users", size=14)#</cfoutput>
				<span>View Applicants</span>
			</a>
			<a href="<cfoutput>#urlFor(controller='jobs', action='publicView', params='id=' & variables.job.jobId)#</cfoutput>" target="_blank" class="btn btn-outline btn-sm">
				<cfoutput>#svgIcon(name="eye", size=14)#</cfoutput>
				<span>View Public Listing</span>
			</a>
		</cfif>
		<button type="submit" id="btnSaveJob" form="jobListingForm" class="btn btn-primary btn-sm">
			<cfoutput>#svgIcon(name="check", size=15)#</cfoutput>
			<span><cfoutput>#(isNew ? 'Publish / Save Listing' : 'Update Job Listing')#</cfoutput></span>
		</button>
	</div>
</div>

<div id="jobSaveStatus" role="status" aria-live="polite" class="sr-only"></div>

<cfif flashKeyExists("success")>
	<div class="alert alert-success" role="status" style="margin-bottom:1.25rem; display:flex; align-items:center; gap:0.75rem;">
		<cfoutput>#svgIcon(name="check-circle", size=20)#</cfoutput>
		<div>
			<strong>Job listing saved to database:</strong> <cfoutput>#encodeForHTML(flash("success"))#</cfoutput>
		</div>
	</div>
<cfelseif flashKeyExists("error")>
	<div class="alert alert-danger" role="alert" style="margin-bottom:1.25rem; display:flex; align-items:center; gap:0.75rem;">
		<cfoutput>#svgIcon(name="alert-circle", size=20)#</cfoutput>
		<div>
			<strong>Error saving job listing:</strong> <cfoutput>#encodeForHTML(flash("error"))#</cfoutput>
		</div>
	</div>
<cfelseif isNew and Len(Trim(variables.job.title))>
	<div class="alert alert-info" role="status" style="margin-bottom:1.25rem; display:flex; align-items:center; gap:0.75rem;">
		<cfoutput>#svgIcon(name="info", size=20)#</cfoutput>
		<div>
			<strong>Job listing initialized:</strong> &ldquo;<strong><cfoutput>#encodeForHTML(variables.job.title)#</cfoutput></strong>&rdquo;. Configure your position details, salary, and requirements below, then click Save.
		</div>
	</div>
</cfif>

<style>
.admin-card .card-header {
	justify-content: flex-start !important;
	gap: 0.75rem !important;
}
</style>

<form id="jobListingForm" method="post" action="<cfoutput>#urlFor(controller='jobs', action='save')#</cfoutput>" enctype="multipart/form-data" novalidate>
	<input type="hidden" name="JobID" value="<cfoutput>#variables.job.jobId#</cfoutput>">
	<cfif not isNew>
		<input type="hidden" name="existing_attachment" value="<cfoutput>#encodeForHTML(variables.job.attachment)#</cfoutput>">
	</cfif>

	<div style="display:grid; grid-template-columns:minmax(0, 2fr) minmax(320px, 1fr); gap:1.5rem; align-items:start;">
		
		<!--- Left Column: Main Job Fields --->
		<div style="display:flex; flex-direction:column; gap:1.25rem;">
			
			<!--- Position Title & Core Identifiers --->
			<div class="admin-card">
				<div class="card-header">
					<h2 class="card-title">
						<cfoutput>#svgIcon(name="briefcase", size=16)#</cfoutput>
						<span>Position Identification</span>
					</h2>
				</div>
				<div class="card-body" style="display:flex; flex-direction:column; gap:1rem;">
					
					<div style="display:grid; grid-template-columns:1fr 220px; gap:1rem;">
						<div>
							<label for="Title" class="form-label" style="font-weight:600;">Title <span aria-hidden="true" style="color:var(--admin-danger);">*</span><span class="sr-only"> (required)</span></label>
							<input type="text" id="Title" name="Title" class="form-control" placeholder="e.g. Road Maintenance Specialist II" value="<cfoutput>#encodeForHTML(variables.job.title)#</cfoutput>" required aria-required="true">
						</div>
						<div>
							<label for="ClassCode" class="form-label" style="font-weight:600;">Class Code / PCN</label>
							<input type="text" id="ClassCode" name="ClassCode" class="form-control" style="font-family:monospace;" placeholder="PCN-2027-001" value="<cfoutput>#encodeForHTML(variables.job.classCode)#</cfoutput>">
						</div>
					</div>

					<div>
						<input type="hidden" id="SiteID" name="SiteID" value="<cfoutput>#EncodeForHTMLAttribute(Len(Trim(variables.job.siteId ?: '')) ? variables.job.siteId : activeWorkspaceId())#</cfoutput>">
						<label for="Permalink" class="form-label" style="font-weight:600;">Permalink (URL Slug)</label>
						<input type="text" id="Permalink" name="Permalink" class="form-control" placeholder="road-maintenance-specialist-ii" value="<cfoutput>#encodeForHTML(variables.job.permalink)#</cfoutput>">
					</div>

					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div>
							<label for="DirectSupervisor" class="form-label" style="font-weight:600;">Direct Supervisor</label>
							<input type="text" id="DirectSupervisor" name="DirectSupervisor" class="form-control" placeholder="e.g. Road District Supervisor" value="<cfoutput>#encodeForHTML(variables.job.directSupervisor)#</cfoutput>">
						</div>
						<div style="display:flex; align-items:center; padding-top:1.75rem;">
							<div class="form-check form-switch">
								<input class="form-check-input" type="checkbox" id="isSupervisor" name="isSupervisor" value="1" <cfif variables.job.isSupervisor>checked</cfif>>
								<label class="form-check-label" for="isSupervisor" style="font-weight:600;">Supervisory Position (isSupervisor)</label>
							</div>
						</div>
					</div>

				</div>
			</div>

			<!--- Description (with JBDEditor) --->
			<div class="admin-card">
				<div class="card-header">
					<h2 class="card-title">
						<cfoutput>#svgIcon(name="file-text", size=16)#</cfoutput>
						<span>Job Description</span>
					</h2>
				</div>
				<div class="card-body">
					<textarea id="Description" name="Description" class="form-control" data-jbd-editor data-jbd-toolbar="subpage" data-jbd-inline-toolbar="true" data-jbd-height="460px" data-jbd-placeholder="Enter job description, duties, qualifications, and benefits..."><cfoutput>#encodeForHTML(variables.job.description)#</cfoutput></textarea>
					<div class="pg-help" style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.4rem;">
						Rich Text Editor (WCAG 2.2 AA). Supports headings, bulleted lists, tables, callout blocks, and document links.
					</div>
				</div>
			</div>

		</div>

		<!--- Right Column: Classification, Compensation, Location, Publishing --->
		<div style="display:flex; flex-direction:column; gap:1.25rem;">
			
			<!--- Publishing & Deadlines Card --->
			<div class="admin-card">
				<div class="card-header">
					<h2 class="card-title">
						<cfoutput>#svgIcon(name="clock", size=16)#</cfoutput>
						<span>Status &amp; Timeline</span>
					</h2>
				</div>
				<div class="card-body" style="display:flex; flex-direction:column; gap:1rem;">
					<div>
						<label for="StatusCode" class="form-label" style="font-weight:600;">Status Code</label>
						<select id="StatusCode" name="StatusCode" class="form-control">
							<option value="Active" <cfif variables.job.statusCode eq "Active">selected</cfif>>Active (Accepting Applications)</option>
							<option value="Scheduled" <cfif variables.job.statusCode eq "Scheduled">selected</cfif>>Scheduled (Automated Release)</option>
							<option value="Draft" <cfif variables.job.statusCode eq "Draft">selected</cfif>>Draft (Internal Preview Only)</option>
							<option value="Reviewing" <cfif variables.job.statusCode eq "Reviewing">selected</cfif>>Reviewing (Application Review Stage)</option>
							<option value="Closed" <cfif variables.job.statusCode eq "Closed">selected</cfif>>Closed (Recruitment Concluded)</option>
						</select>
					</div>

					<div style="border-top:1px dashed var(--admin-border); padding-top:0.75rem;">
						<label for="publish_at" class="form-label" style="font-weight:600;">
							Publish At (Release Date)
						</label>
						<input type="datetime-local" id="publish_at" name="publish_at" class="form-control" value="<cfoutput>#variables.job.publishAt#</cfoutput>">
						<div class="pg-help" style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.25rem;">
							Future dates will set status to Scheduled until the worker releases it.
						</div>
					</div>

					<div style="border-top:1px dashed var(--admin-border); padding-top:0.75rem;">
						<label for="unpublish_at" class="form-label" style="font-weight:600;">
							Unpublish / Close At (Auto-Archive)
						</label>
						<input type="datetime-local" id="unpublish_at" name="unpublish_at" class="form-control" value="<cfoutput>#variables.job.unpublishAt#</cfoutput>">
						<div class="pg-help" style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.25rem;">
							When reached, status automatically transitions to Closed.
						</div>
					</div>

					<div>
						<label for="PostDate" class="form-label" style="font-weight:600;">Post Date (Public Display)</label>
						<input type="date" id="PostDate" name="PostDate" class="form-control" value="<cfoutput>#variables.job.postDate#</cfoutput>">
					</div>

					<div class="form-check form-switch">
						<input class="form-check-input" type="checkbox" id="openUntilFilled" name="is_open_until_filled" value="1" <cfif variables.job.isOpenUntilFilled>checked</cfif> onchange="toggleDeadlineField(this)">
						<label class="form-check-label" for="openUntilFilled" style="font-weight:600;">Open Until Filled</label>
					</div>

					<div id="deadlineGroup" style="<cfif variables.job.isOpenUntilFilled>display:none;</cfif>">
						<label for="ApplicationDeadline" class="form-label" style="font-weight:600;">Application Deadline</label>
						<input type="date" id="ApplicationDeadline" name="ApplicationDeadline" class="form-control" value="<cfoutput>#variables.job.applicationDeadline#</cfoutput>">
					</div>

					<button type="submit" id="btnSaveJobSecondary" class="btn btn-primary btn-sm" style="width:100%; margin-top:0.5rem; display:flex; align-items:center; justify-content:center; gap:0.5rem;">
						<cfoutput>#svgIcon(name="save", size=14)#</cfoutput>
						<span><cfoutput>#(isNew ? 'Publish / Save Listing' : 'Save Changes')#</cfoutput></span>
					</button>
				</div>
			</div>

			<!--- Compensation & Classification Card --->
			<div class="admin-card">
				<div class="card-header">
					<h2 class="card-title">
						<cfoutput>#svgIcon(name="activity", size=16)#</cfoutput>
						<span>Compensation &amp; Classification</span>
					</h2>
				</div>
				<div class="card-body" style="display:flex; flex-direction:column; gap:1rem;">
					
					<div>
						<label for="JobClasificationID" class="form-label" style="font-weight:600;">Job Classification</label>
						<select id="JobClasificationID" name="JobClasificationID" class="form-control">
							<option value="1" <cfif variables.job.jobClassificationId eq 1>selected</cfif>>Full-Time</option>
							<option value="2" <cfif variables.job.jobClassificationId eq 2>selected</cfif>>Part-Time</option>
							<option value="3" <cfif variables.job.jobClassificationId eq 3>selected</cfif>>Seasonal</option>
							<option value="4" <cfif variables.job.jobClassificationId eq 4>selected</cfif>>Temporary</option>
							<option value="5" <cfif variables.job.jobClassificationId eq 5>selected</cfif>>On-Call / Relief</option>
						</select>
					</div>

					<div>
						<label for="FLSAClassificationID" class="form-label" style="font-weight:600;">FLSA Classification</label>
						<select id="FLSAClassificationID" name="FLSAClassificationID" class="form-control">
							<option value="1" <cfif variables.job.flsaClassificationId eq 1>selected</cfif>>Non-Exempt (Overtime Eligible)</option>
							<option value="2" <cfif variables.job.flsaClassificationId eq 2>selected</cfif>>Exempt (Salaried Professional)</option>
						</select>
					</div>

					<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.75rem;">
						<div>
							<label for="MinSalary" class="form-label" style="font-weight:600;">Min Salary ($)</label>
							<input type="number" step="0.01" id="MinSalary" name="MinSalary" class="form-control" placeholder="28.45" value="<cfoutput>#variables.job.minSalary#</cfoutput>">
						</div>
						<div>
							<label for="MaxSalary" class="form-label" style="font-weight:600;">Max Salary ($)</label>
							<input type="number" step="0.01" id="MaxSalary" name="MaxSalary" class="form-control" placeholder="34.12" value="<cfoutput>#variables.job.maxSalary#</cfoutput>">
						</div>
					</div>

					<div>
						<label for="SalarySchedule" class="form-label" style="font-weight:600;">Salary Schedule (Frequency)</label>
						<select id="SalarySchedule" name="SalarySchedule" class="form-control">
							<option value="Hourly" <cfif variables.job.salarySchedule eq "Hourly">selected</cfif>>Hourly</option>
							<option value="Monthly" <cfif variables.job.salarySchedule eq "Monthly">selected</cfif>>Monthly</option>
							<option value="Annual" <cfif variables.job.salarySchedule eq "Annual">selected</cfif>>Annual</option>
						</select>
					</div>

					<div>
						<label for="SalaryGroup" class="form-label" style="font-weight:600;">Salary Group / Union</label>
						<input type="text" id="SalaryGroup" name="SalaryGroup" class="form-control" placeholder="e.g. Teamsters Local 760" value="<cfoutput>#encodeForHTML(variables.job.salaryGroup)#</cfoutput>">
					</div>

				</div>
			</div>

			<!--- Location & Facility Address --->
			<div class="admin-card">
				<div class="card-header">
					<h2 class="card-title">
						<cfoutput>#svgIcon(name="map-pin", size=16)#</cfoutput>
						<span>Workplace Location &amp; Address</span>
					</h2>
				</div>
				<div class="card-body" style="display:flex; flex-direction:column; gap:1rem;">
					<div>
						<label for="Location" class="form-label" style="font-weight:600;">Facility / Location Name</label>
						<input type="text" id="Location" name="Location" class="form-control" placeholder="e.g. Wenatchee Road District ##1" value="<cfoutput>#encodeForHTML(variables.job.location)#</cfoutput>">
					</div>
					<div>
						<label for="Address" class="form-label" style="font-weight:600;">Street Address</label>
						<input type="text" id="Address" name="Address" class="form-control" placeholder="1422 Cascade Ave" value="<cfoutput>#encodeForHTML(variables.job.address)#</cfoutput>">
					</div>
					<div style="display:grid; grid-template-columns:2fr 1fr 1fr; gap:0.5rem;">
						<div>
							<label for="City" class="form-label" style="font-weight:600;">City</label>
							<input type="text" id="City" name="City" class="form-control" value="<cfoutput>#encodeForHTML(variables.job.city)#</cfoutput>">
						</div>
						<div>
							<label for="State" class="form-label" style="font-weight:600;">State</label>
							<input type="text" id="State" name="State" class="form-control" value="<cfoutput>#encodeForHTML(variables.job.state)#</cfoutput>">
						</div>
						<div>
							<label for="Zip" class="form-label" style="font-weight:600;">Zip</label>
							<input type="text" id="Zip" name="Zip" class="form-control" value="<cfoutput>#encodeForHTML(variables.job.zip)#</cfoutput>">
						</div>
					</div>
				</div>
			</div>

			<!--- Attachment (Job Flyer) Card --->
			<div class="admin-card">
				<div class="card-header">
					<h2 class="card-title">
						<cfoutput>#svgIcon(name="paperclip", size=16)#</cfoutput>
						<span>Attachment (Job Description PDF)</span>
					</h2>
				</div>
				<div class="card-body">
					<cfif len(variables.job.attachment)>
						<div style="background:var(--admin-surface-alt, ##f8fafc); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:0.75rem; margin-bottom:0.75rem; display:flex; align-items:center; justify-content:space-between;">
							<div style="display:flex; align-items:center; gap:0.5rem; overflow:hidden;">
								<span style="color:var(--admin-danger);"><cfoutput>#svgIcon(name="file-text", size=18)#</cfoutput></span>
								<a href="<cfoutput>#variables.job.attachment#</cfoutput>" target="_blank" style="font-size:0.8rem; font-weight:600; text-decoration:none; color:var(--admin-primary); overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
									<cfoutput>#encodeForHTML(ListLast(variables.job.attachment, "/"))#</cfoutput>
								</a>
							</div>
							<span class="badge badge-success" style="font-size:0.7rem;">Attached</span>
						</div>
					</cfif>

					<label for="jobAttachment" class="form-label" style="font-size:0.8rem; font-weight:600;">
						<cfoutput>#(len(variables.job.attachment) ? 'Replace Attachment File:' : 'Upload Official Job Flyer (PDF):')#</cfoutput>
					</label>
					<input type="file" id="jobAttachment" name="job_attachment" class="form-control form-control-sm" accept=".pdf,.doc,.docx">
				</div>
			</div>

		</div>

	</div>
</form>

<script>
function toggleDeadlineField(checkbox) {
	var group = document.getElementById("deadlineGroup");
	if (checkbox.checked) {
		group.style.display = "none";
	} else {
		group.style.display = "block";
	}
}

(function () {
	var form = document.getElementById("jobListingForm");
	if (!form) return;

	var title = document.getElementById("Title");
	var classCode = document.getElementById("ClassCode");
	var siteId = document.getElementById("SiteID");
	var permalink = document.getElementById("Permalink");
	var status = document.getElementById("jobSaveStatus");
	var btnSaveJob = document.getElementById("btnSaveJob");
	var btnSaveJobSecondary = document.getElementById("btnSaveJobSecondary");

	// Auto-slug permalink from title if not manually changed
	var permalinkTouched = (permalink && permalink.value.trim().length > 0);
	if (title && permalink) {
		title.addEventListener("input", function() {
			if (!permalinkTouched) {
				permalink.value = title.value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
			}
		});
		permalink.addEventListener("input", function() {
			permalinkTouched = true;
		});
	}

	function setButtonLoading(loading) {
		var buttons = [btnSaveJob, btnSaveJobSecondary].filter(Boolean);
		buttons.forEach(function(btn) {
			if (loading) {
				btn.dataset.origHtml = btn.innerHTML;
				btn.disabled = true;
				btn.classList.add("is-loading");
				btn.innerHTML = '<span class="admin-spinner-sm" style="margin-right:6px;" aria-hidden="true"></span> <span>Saving Job Listing...</span>';
			} else {
				btn.disabled = false;
				btn.classList.remove("is-loading");
				if (btn.dataset.origHtml) {
					btn.innerHTML = btn.dataset.origHtml;
				}
			}
		});
	}

	form.addEventListener("submit", function (e) {
		e.preventDefault();

		// Validate Title
		if (!title || !title.value.trim()) {
			if (title) title.setAttribute("aria-invalid", "true");
			if (status) {
				status.className = "";
				status.style.cssText = "background:var(--admin-danger-light); color:var(--admin-danger); border:1px solid var(--admin-danger); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
				status.textContent = "Position title is required.";
			}
			if (title) title.focus();
			if (typeof window.adminAlert === "function") {
				window.adminAlert("Please enter a Title for this job listing.", { title: "Title Required", type: "danger" });
			}
			return;
		}
		if (title) title.removeAttribute("aria-invalid");


		// Validate SiteID / Department Workspace
		if (!siteId || !siteId.value.trim()) {
			if (siteId) siteId.setAttribute("aria-invalid", "true");
			if (status) {
				status.className = "";
				status.style.cssText = "background:var(--admin-danger-light); color:var(--admin-danger); border:1px solid var(--admin-danger); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
				status.textContent = "Department workspace is required.";
			}
			if (siteId) siteId.focus();
			if (typeof window.adminAlert === "function") {
				window.adminAlert("Please select a Department Workspace for this job listing.", { title: "Department Required", type: "danger" });
			}
			return;
		}
		if (siteId) siteId.removeAttribute("aria-invalid");

		// Sync JBDEditor if instantiated
		var jbdInstance = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#Description") : null;
		if (jbdInstance) {
			jbdInstance.syncToTarget();
		}
		var descVal = jbdInstance ? jbdInstance.getHTML() : (document.getElementById("Description") ? document.getElementById("Description").value : "");

		// WCAG 2.1 Level AA Accessibility Validation Check (matching pages/edit.cfm)
		if (typeof A11yValidator !== "undefined" && !window.__cmsBypassA11yOnce) {
			var a11yResult = (jbdInstance && typeof jbdInstance.validateA11y === "function")
				? jbdInstance.validateA11y()
				: A11yValidator.validate(descVal);

			if (!a11yResult.passed || (a11yResult.warnings && a11yResult.warnings.length > 0)) {
				A11yValidator.showModal({
					results: a11yResult,
					onProceed: function() {
						window.__cmsBypassA11yOnce = true;
						form.dispatchEvent(new Event("submit", { cancelable: true }));
					},
					onCancel: function() {
						if (status) {
							status.style.cssText = "background:var(--admin-warning-light, #fffbeb); color:var(--admin-warning, #92400e); border:1px solid var(--admin-warning, #fde68a); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
							status.textContent = "Save paused: please resolve accessibility issues before publishing.";
						}
					}
				});
				return;
			}
		}
		window.__cmsBypassA11yOnce = false;

		// Button loading feedback and top progress
		setButtonLoading(true);
		if (typeof window.startTopProgress === "function") {
			window.startTopProgress();
		}

		if (status) {
			status.className = "";
			status.style.cssText = "background:var(--admin-info-light); color:var(--admin-info); border:1px solid var(--admin-info); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
			status.textContent = "Saving job listing attributes to database...";
		}

		var formData = new FormData(form);
		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var headers = {
			"Accept": "application/json",
			"X-Requested-With": "XMLHttpRequest"
		};
		if (csrfMeta && csrfMeta.getAttribute("content")) {
			headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
		}

		fetch(form.action, {
			method: "POST",
			credentials: "same-origin",
			headers: headers,
			body: formData
		})
		.then(function(r) {
			return r.json().then(function(data) {
				if (!r.ok) throw data;
				return data;
			});
		})
		.then(function(data) {
			setButtonLoading(false);
			if (typeof window.finishTopProgress === "function") {
				window.finishTopProgress();
			}

			function getField(obj, key) {
				if (!obj || typeof obj !== "object") return undefined;
				if (obj[key] !== undefined) return obj[key];
				var upper = key.toUpperCase();
				if (obj[upper] !== undefined) return obj[upper];
				var lower = key.toLowerCase();
				if (obj[lower] !== undefined) return obj[lower];
				return undefined;
			}

			var isSuccess = (getField(data, "success") === true || String(getField(data, "success")).toLowerCase() === "true");
			if (isSuccess) {
				if (jbdInstance && typeof jbdInstance.clearDraft === "function") {
					jbdInstance.clearDraft();
				}
				if (status) {
					status.className = "";
					status.style.cssText = "background:var(--admin-success-light); color:var(--admin-success); border:1px solid var(--admin-success); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
					status.textContent = getField(data, "message") || "Job listing attributes successfully saved to database.";
				}
				if (typeof window.showToast === "function") {
					window.showToast("Job listing saved to database.", "success");
				}

				var redirectUrl = getField(data, "redirectUrl");
				var newJobId = getField(data, "jobId");
				var isNewRecord = <cfoutput>#(isNew ? 'true' : 'false')#</cfoutput>;
				if (isNewRecord && (newJobId || redirectUrl)) {
					setTimeout(function() {
						window.location.href = redirectUrl || ("/jobs/edit?id=" + newJobId);
					}, 750);
				}
			} else {
				var msg = getField(data, "message") || "Error saving job listing attributes.";
				if (status) {
					status.style.cssText = "background:var(--admin-danger-light); color:var(--admin-danger); border:1px solid var(--admin-danger); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
					status.textContent = msg;
				}
				if (typeof window.adminAlert === "function") {
					window.adminAlert(msg, { title: "Save Failed", type: "danger" });
				}
			}
		})
		.catch(function(err) {
			setButtonLoading(false);
			if (typeof window.finishTopProgress === "function") {
				window.finishTopProgress();
			}

			function getField(obj, key) {
				if (!obj || typeof obj !== "object") return undefined;
				if (obj[key] !== undefined) return obj[key];
				var upper = key.toUpperCase();
				if (obj[upper] !== undefined) return obj[upper];
				var lower = key.toLowerCase();
				if (obj[lower] !== undefined) return obj[lower];
				return undefined;
			}
			var msg = (err && (getField(err, "message") || err.message)) ? (getField(err, "message") || err.message) : "Error saving job listing attributes.";
			if (status) {
				status.style.cssText = "background:var(--admin-danger-light); color:var(--admin-danger); border:1px solid var(--admin-danger); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
				status.textContent = msg;
			}
			if (typeof window.adminAlert === "function") {
				window.adminAlert(msg, { title: "Save Failed", type: "danger" });
			}
		});
	});
})();
</script>
