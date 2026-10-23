<cfset a = variables.app>
<cfset pageTitle = "Candidate Dossier: " & a.FirstName & " " & a.LastName>

<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.75rem;">
			<h1 class="page-title" style="margin-bottom:0;">
				<cfoutput>#encodeForHTML(a.FirstName)# <cfif len(a.MiddleName)>#encodeForHTML(a.MiddleName)# </cfif>#encodeForHTML(a.LastName)#</cfoutput>
			</h1>
			<cfset sBadge = "badge-neutral">
			<cfif a.Status eq "New"><cfset sBadge = "badge-primary">
			<cfelseif a.Status eq "Under Review"><cfset sBadge = "badge-info">
			<cfelseif a.Status eq "Interview"><cfset sBadge = "badge-purple">
			<cfelseif a.Status eq "Offer"><cfset sBadge = "badge-warning">
			<cfelseif a.Status eq "Hired"><cfset sBadge = "badge-success">
			<cfelseif a.Status eq "Not Selected"><cfset sBadge = "badge-danger">
			</cfif>
			<span class="badge <cfoutput>#sBadge#</cfoutput>" id="candidateStatusBadge" style="font-size:0.8rem;"><cfoutput>#a.Status#</cfoutput></span>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>"><cfoutput>#svgIcon(name="dashboard", size=14)#</cfoutput> Home</a></li>
				<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='jobs', action='index')#</cfoutput>">Job Postings</a></li>
				<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='jobs', action='applications')#</cfoutput>">Applications</a></li>
				<li class="breadcrumb-item active" aria-current="page">Candidate Dossier</li>
			</ol>
		</nav>
	</div>

	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="<cfoutput>#urlFor(controller='jobs', action='applications', params='jobId=' & a.JobID)#</cfoutput>" class="btn btn-outline btn-sm">
			<cfoutput>#svgIcon(name="arrow-left", size=14)#</cfoutput>
			<span>Back to Applications</span>
		</a>
		<a href="javascript:window.print()" class="btn btn-secondary btn-sm">
			<cfoutput>#svgIcon(name="printer", size=14)#</cfoutput>
			<span>Print Dossier</span>
		</a>
	</div>
</div>

<style>
.admin-card .card-header {
	justify-content: flex-start !important;
	gap: 0.75rem !important;
}
</style>

<div style="display:grid; grid-template-columns:minmax(0, 2fr) minmax(320px, 1fr); gap:1.5rem; align-items:start;">

	<!--- Left Column: Grouped Candidate Dossier Panels (Matching Edit Page Layout) --->
	<div style="display:flex; flex-direction:column; gap:1.25rem;">

		<!--- 1. Applicant Profile & Contact Details Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="user", size=16)#</cfoutput>
					<span>1. Applicant Profile &amp; Contact Details</span>
				</h2>
				<span style="font-size:0.8rem; color:var(--admin-text-muted); font-weight:normal;">
					Application ##<cfoutput>#a.ApplicationID#</cfoutput>
				</span>
			</div>
			<div class="card-body">
				<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:1.25rem;">
					<div>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:700;">EMAIL ADDRESS</div>
						<div style="font-size:0.95rem; font-weight:600; margin-top:0.2rem;">
							<a href="mailto:<cfoutput>#encodeForHTML(a.Email)#</cfoutput>" style="color:var(--admin-primary); text-decoration:none;">
								<cfoutput>#encodeForHTML(a.Email)#</cfoutput>
							</a>
						</div>
					</div>
					<div>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:700;">PRIMARY PHONE</div>
						<div style="font-size:0.95rem; font-weight:600; margin-top:0.2rem;">
							<a href="tel:<cfoutput>#encodeForHTML(a.Phone)#</cfoutput>" style="color:inherit; text-decoration:none;">
								<cfoutput>#encodeForHTML(a.Phone)#</cfoutput>
							</a>
						</div>
					</div>
					<div>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:700;">PHYSICAL ADDRESS</div>
						<div style="font-size:0.9rem; margin-top:0.2rem; color:var(--admin-text-main);">
							<cfoutput>#encodeForHTML(a.Address1)#<cfif len(a.Address2)>, #encodeForHTML(a.Address2)#</cfif><br>#encodeForHTML(a.City)#, #encodeForHTML(a.State)# #encodeForHTML(a.Zip)#</cfoutput>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!--- 2. Driver's License & Commercial CDL Credentials Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="truck", size=16)#</cfoutput>
					<span>2. Driver's License &amp; Commercial CDL Credentials</span>
				</h2>
			</div>
			<div class="card-body">
				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.25rem;">
					
					<!--- Standard Driver's License --->
					<div style="background:var(--admin-surface-alt, ##f8fafc); padding:1.15rem; border-radius:var(--radius-md); border:1px solid var(--admin-border);">
						<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
							<strong style="font-size:0.9rem;">Standard Driver's License</strong>
							<cfif a.hasLicense>
								<span class="badge badge-success">Valid License</span>
							<cfelse>
								<span class="badge badge-neutral">No License Reported</span>
							</cfif>
						</div>
						<cfif a.hasLicense>
							<div style="font-size:0.85rem; display:flex; flex-direction:column; gap:0.35rem;">
								<div>License Number: <strong style="font-family:monospace;"><cfoutput>#encodeForHTML(a.LicenseNo)#</cfoutput></strong></div>
								<div>Issuing State: <strong><cfoutput>#encodeForHTML(a.LicenseState)#</cfoutput></strong></div>
								<div>Expiration Date: <strong><cfoutput>#(isDate(a.LicenseExpireDate) ? dateFormat(a.LicenseExpireDate, "mmm d, yyyy") : 'N/A')#</cfoutput></strong></div>
							</div>
						<cfelse>
							<div style="font-size:0.8rem; color:var(--admin-text-muted);">Candidate indicates they do not hold a standard driver's license.</div>
						</cfif>
					</div>

					<!--- Commercial Driver's License (CDL) --->
					<div style="background:var(--admin-surface-alt, ##f8fafc); padding:1.15rem; border-radius:var(--radius-md); border:1px solid var(--admin-border);">
						<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
							<strong style="font-size:0.9rem;">Commercial Driver's License (CDL)</strong>
							<cfif a.hasCDL>
								<span class="badge badge-warning">CDL Certified</span>
							<cfelse>
								<span class="badge badge-neutral">No CDL</span>
							</cfif>
						</div>
						<cfif a.hasCDL>
							<div style="font-size:0.85rem; display:flex; flex-direction:column; gap:0.35rem;">
								<div>CDL Number: <strong style="font-family:monospace;"><cfoutput>#encodeForHTML(a.CDLNo)#</cfoutput></strong> (State: <strong><cfoutput>#encodeForHTML(a.CDLState)#</cfoutput></strong>)</div>
								<div>CDL Class/Type: <strong style="color:var(--admin-primary);"><cfoutput>#encodeForHTML(a.CDLType)#</cfoutput></strong></div>
								<div>Expiration: <strong><cfoutput>#(isDate(a.CDLExpireDate) ? dateFormat(a.CDLExpireDate, "mmm d, yyyy") : 'N/A')#</cfoutput></strong></div>
								<cfif len(a.CDLRestriction)>
									<div>Endorsements / Restrictions: <span style="color:var(--admin-text-muted);"><cfoutput>#encodeForHTML(a.CDLRestriction)#</cfoutput></span></div>
								</cfif>
							</div>
						<cfelse>
							<div style="font-size:0.8rem; color:var(--admin-text-muted);">Candidate does not hold a Commercial Driver's License.</div>
						</cfif>
					</div>

				</div>
			</div>
		</div>

		<!--- 3. County Employment History & Relatives Disclosures Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="building", size=16)#</cfoutput>
					<span>3. County Disclosures &amp; Nepotism Screening</span>
				</h2>
			</div>
			<div class="card-body">
				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.25rem;">
					
					<!--- Prior County Employment --->
					<div style="background:var(--admin-surface-alt, ##f8fafc); padding:1.15rem; border-radius:var(--radius-md); border:1px solid var(--admin-border);">
						<div style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:700; text-transform:uppercase;">Prior Chelan County Employment</div>
						<cfif a.wasEmployed>
							<div style="margin-top:0.5rem; padding:0.75rem; background:rgba(2, 132, 199, 0.08); border-left:3px solid var(--admin-info); border-radius:var(--radius-sm);">
								<div style="font-weight:700; font-size:0.85rem; color:var(--admin-info);">Previous County Staff Member</div>
								<div style="font-size:0.8rem; margin-top:0.25rem;">
									Department: <strong><cfoutput>#encodeForHTML(a.EmploymentDepartment)#</cfoutput></strong><br>
									Dates Employed: <cfoutput>#(isDate(a.EmploymentStart) ? dateFormat(a.EmploymentStart, "mmm yyyy") : 'N/A')# &ndash; #(isDate(a.EmploymentEnd) ? dateFormat(a.EmploymentEnd, "mmm yyyy") : 'N/A')#</cfoutput>
								</div>
							</div>
						<cfelse>
							<div style="font-size:0.85rem; color:var(--admin-text-muted); margin-top:0.4rem;">Candidate was not previously employed by Chelan County.</div>
						</cfif>
					</div>

					<!--- Relatives Disclosures --->
					<div style="background:var(--admin-surface-alt, ##f8fafc); padding:1.15rem; border-radius:var(--radius-md); border:1px solid var(--admin-border);">
						<div style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:700; text-transform:uppercase;">Relatives Employed with County</div>
						<cfif a.hasRelative>
							<div style="margin-top:0.5rem; padding:0.75rem; background:rgba(217, 119, 6, 0.08); border-left:3px solid var(--admin-warning); border-radius:var(--radius-sm);">
								<div style="font-weight:700; font-size:0.85rem; color:var(--admin-warning);">Disclosed Relative(s)</div>
								<div style="font-size:0.8rem; margin-top:0.25rem;">
									<cfoutput>#encodeForHTML(a.RelativeNames)#</cfoutput>
								</div>
							</div>
						<cfelse>
							<div style="font-size:0.85rem; color:var(--admin-text-muted); margin-top:0.4rem;">No relatives currently employed by Chelan County.</div>
						</cfif>
					</div>

				</div>
			</div>
		</div>

		<!--- 4. Foreign Language Skills & Proficiency Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="sparkles", size=16)#</cfoutput>
					<span>4. Foreign Language Skills &amp; Multilingual Capabilities</span>
				</h2>
			</div>
			<div class="card-body">
				<cfset hasLangs = false>
				<div style="display:flex; gap:0.75rem; flex-wrap:wrap;">
					<cfloop from="1" to="3" index="lIdx">
						<cfset lName = a["ForeignLanguage" & lIdx]>
						<cfset lProf = a["Proficiency" & lIdx]>
						<cfif len(lName)>
							<cfset hasLangs = true>
							<div class="badge badge-purple" style="font-size:0.85rem; padding:0.45rem 0.85rem; border-radius:8px;">
								<cfoutput>#encodeForHTML(lName)# &bull; #encodeForHTML(lProf)#</cfoutput>
							</div>
						</cfif>
					</cfloop>
					<cfif not hasLangs>
						<span style="font-size:0.85rem; color:var(--admin-text-muted);">Candidate reported English as their primary language with no additional foreign languages.</span>
					</cfif>
				</div>
			</div>
		</div>

		<!--- 5. Educational Background & Degrees Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="book", size=16)#</cfoutput>
					<span>5. Educational Background &amp; Degrees</span>
				</h2>
			</div>
			<div class="card-body">
				<div style="display:flex; gap:1.75rem; align-items:center; margin-bottom:1.25rem; padding-bottom:0.85rem; border-bottom:1px solid var(--admin-border-subtle); flex-wrap:wrap;">
					<div>
						<span style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:700;">HIGH SCHOOL / GED:</span>
						<strong style="margin-left:0.35rem; color:var(--admin-text-main);"><cfoutput>#(a.hasGED ? 'GED Certified' : 'High School Diploma')#</cfoutput></strong>
					</div>
					<div>
						<span style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:700;">HIGHEST GRADE COMPLETED:</span>
						<strong style="margin-left:0.35rem; color:var(--admin-text-main);"><cfoutput>#encodeForHTML(a.HighestGrade)#</cfoutput></strong>
					</div>
				</div>

				<div style="display:flex; flex-direction:column; gap:0.75rem;">
					<cfset hasEdu = false>
					<cfloop from="1" to="4" index="eduIdx">
						<cfset eduName = a["Education" & eduIdx]>
						<cfset eduDeg = a["Degree" & eduIdx]>
						<cfset eduDate = a["DateEarned" & eduIdx]>
						<cfif len(eduName)>
							<cfset hasEdu = true>
							<div style="display:flex; justify-content:space-between; align-items:center; background:var(--admin-surface-alt, ##f8fafc); padding:0.75rem 1rem; border-radius:var(--radius-sm); border:1px solid var(--admin-border-subtle);">
								<div>
									<strong style="font-size:0.9rem; color:var(--admin-text-main);"><cfoutput>#encodeForHTML(eduName)#</cfoutput></strong>
									<cfif len(eduDeg)>
										<div style="font-size:0.85rem; color:var(--admin-primary); margin-top:0.15rem; font-weight:600;"><cfoutput>#encodeForHTML(eduDeg)#</cfoutput></div>
									</cfif>
								</div>
								<cfif len(eduDate)>
									<span style="font-size:0.8rem; color:var(--admin-text-muted); font-weight:600;"><cfoutput>#encodeForHTML(eduDate)#</cfoutput></span>
								</cfif>
							</div>
						</cfif>
					</cfloop>
					<cfif not hasEdu>
						<div style="color:var(--admin-text-muted); font-size:0.85rem;">No higher education degrees reported.</div>
					</cfif>
				</div>
			</div>
		</div>

		<!--- 6. Work Experience & Employment History Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="briefcase", size=16)#</cfoutput>
					<span>6. Employment History &amp; Work Experience</span>
				</h2>
			</div>
			<div class="card-body" style="display:flex; flex-direction:column; gap:1.25rem;">
				
				<cfset hasWork = false>
				<cfloop from="1" to="3" index="wIdx">
					<cfset wEmp = a["WorkExperienceEmployer" & wIdx]>
					<cfset wPhone = a["WorkExperienceEmployerPhone" & wIdx]>
					<cfset wStart = a["WorkExperienceStart" & wIdx]>
					<cfset wEnd = a["WorkExperienceEnd" & wIdx]>
					<cfset wReason = a["WorkExperienceReason" & wIdx]>
					<cfif len(wEmp)>
						<cfset hasWork = true>
						<div style="border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:1rem; background:var(--admin-surface-alt, ##f8fafc);">
							<div style="display:flex; justify-content:space-between; align-items:baseline; flex-wrap:wrap; gap:0.5rem;">
								<div style="font-weight:700; font-size:0.95rem; color:var(--admin-text-main);">
									<cfoutput>#wIdx#. #encodeForHTML(wEmp)#</cfoutput>
								</div>
								<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted);">
									<cfoutput>#encodeForHTML(wStart)# &ndash; #encodeForHTML(wEnd)#</cfoutput>
								</span>
							</div>
							<cfif len(wPhone)>
								<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.25rem;">
									Phone: <cfoutput>#encodeForHTML(wPhone)#</cfoutput>
								</div>
							</cfif>
							<cfif len(wReason)>
								<div style="font-size:0.85rem; margin-top:0.5rem; color:var(--admin-text-main); background:##ffffff; padding:0.5rem 0.75rem; border-radius:var(--radius-sm); border:1px solid var(--admin-border-subtle);">
									<strong>Reason for Leaving:</strong> <cfoutput>#encodeForHTML(wReason)#</cfoutput>
								</div>
							</cfif>
						</div>
					</cfif>
				</cfloop>

				<cfif not hasWork>
					<div style="color:var(--admin-text-muted); font-size:0.85rem;">No prior employment history provided.</div>
				</cfif>
			</div>
		</div>

		<!--- 7. Professional References Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="users", size=16)#</cfoutput>
					<span>7. Professional References</span>
				</h2>
			</div>
			<div class="card-body">
				<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(220px, 1fr)); gap:1rem;">
					<cfloop from="1" to="3" index="rIdx">
						<cfset rName = a["ReferenceName" & rIdx]>
						<cfset rEmail = a["ReferenceEmail" & rIdx]>
						<cfset rPhone = a["ReferencePhone" & rIdx]>
						<div style="background:var(--admin-surface-alt, ##f8fafc); padding:1rem; border-radius:var(--radius-sm); border:1px solid var(--admin-border-subtle);">
							<div style="font-weight:700; font-size:0.9rem; color:var(--admin-text-main);">
								<cfoutput>Reference ## #rIdx#: #(len(rName) ? encodeForHTML(rName) : 'N/A')#</cfoutput>
							</div>
							<cfif len(rEmail)>
								<div style="font-size:0.8rem; margin-top:0.35rem;">
									<a href="mailto:<cfoutput>#encodeForHTML(rEmail)#</cfoutput>" style="color:var(--admin-primary); text-decoration:none;"><cfoutput>#encodeForHTML(rEmail)#</cfoutput></a>
								</div>
							</cfif>
							<cfif len(rPhone)>
								<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.2rem;"><cfoutput>#encodeForHTML(rPhone)#</cfoutput></div>
							</cfif>
						</div>
					</cfloop>
				</div>
			</div>
		</div>

		<!--- 8. Attestation & Legal Signature Panel --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="check-circle", size=16)#</cfoutput>
					<span>8. Legal Attestation &amp; Signature</span>
				</h2>
			</div>
			<div class="card-body" style="font-size:0.85rem; color:var(--admin-text-muted); line-height:1.5;">
				<p style="margin-bottom:0.75rem;">
					&ldquo;I certify that answers given herein are true and complete to the best of my knowledge. I authorize investigation of all statements contained in this application for employment as may be necessary in arriving at an employment decision.&rdquo;
				</p>
				<div style="display:flex; justify-content:space-between; align-items:center; background:var(--admin-surface-alt, ##f8fafc); padding:0.85rem 1.15rem; border-radius:var(--radius-sm); border:1px solid var(--admin-border);">
					<div>
						<div style="font-size:0.75rem; font-weight:700; color:var(--admin-text-muted);">ELECTRONIC SIGNATURE</div>
						<div style="font-family:'Courier New', monospace; font-size:1.15rem; font-weight:700; color:var(--admin-primary); margin-top:0.2rem;">
							/<cfoutput>#encodeForHTML(a.Signature)#</cfoutput>/
						</div>
					</div>
					<div style="text-align:right;">
						<div style="font-size:0.75rem; font-weight:700; color:var(--admin-text-muted);">DATE EXECUTED</div>
						<div style="font-weight:600; color:var(--admin-text-main); margin-top:0.2rem;">
							<cfoutput>#dateFormat(a.EntryDate, "mmmm d, yyyy")# #timeFormat(a.EntryDate, "h:mm tt")#</cfoutput>
						</div>
					</div>
				</div>
			</div>
		</div>

	</div>

	<!--- Right Column: Grouped HRM Review & Target Position Sidebars (Matching Edit Page Sidebar) --->
	<div style="display:flex; flex-direction:column; gap:1.25rem;">
		
		<!--- Target Position & Requisition Overview Card --->
		<div class="admin-card">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="briefcase", size=16)#</cfoutput>
					<span>Target Requisition Details</span>
				</h2>
			</div>
			<div class="card-body" style="display:flex; flex-direction:column; gap:0.75rem; font-size:0.88rem;">
				<div>
					<div style="font-size:0.75rem; color:var(--admin-text-muted); text-transform:uppercase; font-weight:700;">Position Applied For</div>
					<div style="font-size:1.05rem; font-weight:700; color:var(--admin-primary); margin-top:0.15rem;">
						<cfoutput>#encodeForHTML(a.Position)#</cfoutput>
					</div>
				</div>
				<cfif len(a.job_code)>
					<div style="display:flex; justify-content:space-between; padding-top:0.5rem; border-top:1px solid var(--admin-border-subtle);">
						<span style="color:var(--admin-text-muted);">Requisition ID:</span>
						<strong style="font-family:monospace;"><cfoutput>#encodeForHTML(a.job_code)#</cfoutput></strong>
					</div>
				</cfif>
				<cfif len(a.department_name)>
					<div style="display:flex; justify-content:space-between;">
						<span style="color:var(--admin-text-muted);">Department:</span>
						<strong><cfoutput>#encodeForHTML(a.department_name)#</cfoutput></strong>
					</div>
				</cfif>
				<div style="display:flex; justify-content:space-between; padding-top:0.5rem; border-top:1px solid var(--admin-border-subtle);">
					<span style="color:var(--admin-text-muted);">Date Applied:</span>
					<strong><cfoutput>#dateFormat(a.EntryDate, "mmm d, yyyy")#</cfoutput></strong>
				</div>
				<div style="display:flex; justify-content:space-between; align-items:center;">
					<span style="color:var(--admin-text-muted);">Work Authorization:</span>
					<cfif a.hasImmigration>
						<span class="badge badge-success" style="font-size:0.75rem;">Authorized</span>
					<cfelse>
						<span class="badge badge-danger" style="font-size:0.75rem;">Visa Required</span>
					</cfif>
				</div>
				<div style="display:flex; justify-content:space-between; align-items:center;">
					<span style="color:var(--admin-text-muted);">Age Eligibility:</span>
					<cfif a.under18>
						<span class="badge badge-warning" style="font-size:0.75rem;">Under 18</span>
					<cfelse>
						<span class="badge badge-neutral" style="font-size:0.75rem;">18+</span>
					</cfif>
				</div>
			</div>
		</div>

		<!--- HRM Review & Evaluation Card --->
		<div class="admin-card" style="border-top:3px solid var(--admin-primary);">
			<div class="card-header">
				<h2 class="card-title">
					<cfoutput>#svgIcon(name="activity", size=16)#</cfoutput>
					<span>HRM Candidate Review</span>
				</h2>
				<span class="badge badge-purple">Recruitment</span>
			</div>
			<div class="card-body" style="display:flex; flex-direction:column; gap:1.25rem;">
				
				<!--- Status Select --->
				<div>
					<label for="evalStatus" class="form-label" style="font-weight:700; font-size:0.85rem;">Candidate Pipeline Stage</label>
					<select id="evalStatus" class="form-control">
						<option value="New" <cfif a.Status eq "New">selected</cfif>>New (Awaiting Review)</option>
						<option value="Under Review" <cfif a.Status eq "Under Review">selected</cfif>>Under Review (HR Screening)</option>
						<option value="Interview" <cfif a.Status eq "Interview">selected</cfif>>Interview Scheduled</option>
						<option value="Offer" <cfif a.Status eq "Offer">selected</cfif>>Conditional Offer Extended</option>
						<option value="Hired" <cfif a.Status eq "Hired">selected</cfif>>Hired / Onboarding</option>
						<option value="Not Selected" <cfif a.Status eq "Not Selected">selected</cfif>>Not Selected / Archived</option>
					</select>
				</div>

				<!--- Star Rating --->
				<div>
					<label class="form-label" style="font-weight:700; font-size:0.85rem;">Candidate Rating</label>
					<div id="starRatingContainer" style="display:flex; gap:0.5rem; font-size:1.5rem; color:var(--admin-warning, ##eab308); cursor:pointer;">
						<cfloop from="1" to="5" index="sVal">
							<span class="star-btn" data-value="<cfoutput>#sVal#</cfoutput>" style="<cfif sVal lte a.Rating>opacity:1;<cfelse>opacity:0.35;</cfif>">&starf;</span>
						</cfloop>
					</div>
					<input type="hidden" id="evalRating" value="<cfoutput>#a.Rating#</cfoutput>">
				</div>

				<!--- Internal Notes --->
				<div>
					<label for="evalNotes" class="form-label" style="font-weight:700; font-size:0.85rem;">Internal HRM Review Notes</label>
					<textarea id="evalNotes" class="form-control" rows="6" placeholder="Add confidential review notes, interview feedback, civil service scores, or reference check summaries..."><cfoutput>#encodeForHTML(a.AdminNotes)#</cfoutput></textarea>
				</div>

				<!--- Audit Stamp --->
				<cfif len(a.ReviewedBy)>
					<div style="font-size:0.75rem; color:var(--admin-text-muted); background:var(--admin-surface-alt, #f8fafc); padding:0.6rem; border-radius:var(--radius-sm); border:1px solid var(--admin-border-subtle);">
						Last reviewed by: <strong><cfoutput>#encodeForHTML(a.ReviewedBy)#</cfoutput></strong><br>
						Timestamp: <cfoutput>#dateFormat(a.ReviewedAt, "mmm d, yyyy")# #timeFormat(a.ReviewedAt, "h:mm tt")#</cfoutput>
					</div>
				</cfif>

				<!--- Save Button --->
				<button type="button" id="btnSaveAppEvaluation" class="btn btn-primary" style="width:100%;">
					<cfoutput>#svgIcon(name="check", size=15)#</cfoutput>
					<span>Save Evaluation</span>
				</button>

				<div id="saveEvalFeedback" style="display:none; font-size:0.8rem; text-align:center;"></div>

			</div>
		</div>

	</div>

</div>

<script>
document.addEventListener("DOMContentLoaded", function() {
	var curRating = parseInt(document.getElementById("evalRating").value || "0");
	var starSpans = document.querySelectorAll("#starRatingContainer .star-btn");

	function updateStars(val) {
		starSpans.forEach(function(star) {
			var sVal = parseInt(star.getAttribute("data-value"));
			star.style.opacity = (sVal <= val) ? "1" : "0.35";
		});
	}

	starSpans.forEach(function(star) {
		star.addEventListener("click", function() {
			curRating = parseInt(this.getAttribute("data-value"));
			document.getElementById("evalRating").value = curRating;
			updateStars(curRating);
		});
	});

	// Save evaluation handler
	var btnSave = document.getElementById("btnSaveAppEvaluation");
	var feedback = document.getElementById("saveEvalFeedback");

	btnSave.addEventListener("click", function() {
		btnSave.disabled = true;
		btnSave.innerText = "Saving...";
		feedback.style.display = "none";

		var payload = {
			applicationId: <cfoutput>#a.ApplicationID#</cfoutput>,
			status: document.getElementById("evalStatus").value,
			rating: document.getElementById("evalRating").value,
			adminNotes: document.getElementById("evalNotes").value
		};

		fetch("/jobs/application/status", {
			method: "POST",
			headers: {
				"Content-Type": "application/json; charset=utf-8",
				"X-Requested-With": "XMLHttpRequest"
			},
			body: JSON.stringify(payload)
		})
		.then(function(res) { return res.json(); })
		.then(function(data) {
			btnSave.disabled = false;
			btnSave.innerText = "Save Evaluation";
			if (data.success) {
				feedback.style.display = "block";
				feedback.style.color = "var(--admin-success, #15803d)";
				feedback.innerText = "Evaluation saved successfully!";
				document.getElementById("candidateStatusBadge").innerText = payload.status;
				setTimeout(function() { feedback.style.display = "none"; }, 3500);
			} else {
				feedback.style.display = "block";
				feedback.style.color = "var(--admin-danger, #b91c1c)";
				feedback.innerText = data.message || "Failed to update.";
			}
		})
		.catch(function(err) {
			console.error(err);
			btnSave.disabled = false;
			btnSave.innerText = "Save Evaluation";
			feedback.style.display = "block";
			feedback.style.color = "var(--admin-danger, #b91c1c)";
			feedback.innerText = "An error occurred while saving.";
		});
	});
});
</script>
