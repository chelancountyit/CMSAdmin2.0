<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title><cfoutput>#encodeForHTML(variables.pageTitle)#</cfoutput></title>

	<style>
		:root {
			--primary: #0073aa;
			--primary-dark: #005a87;
			--bg: #f8fafc;
			--surface: #ffffff;
			--border: #e2e8f0;
			--border-strong: #cbd5e1;
			--text: #0f172a;
			--text-muted: #475569;
			--success: #15803d;
			--warning: #b45309;
			--danger: #b91c1c;
			--purple: #7e22ce;
			--radius: 10px;
		}
		*, *::before, *::after { box-sizing: border-box; }
		body {
			margin: 0;
			padding: 0;
			font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
			background-color: var(--bg);
			color: var(--text);
			font-size: 15px;
			line-height: 1.6;
		}
		.bids-hero {
			background: linear-gradient(135deg, #0b2545 0%, #134074 100%);
			color: #ffffff;
			padding: 3.5rem 1.5rem 3.5rem 1.5rem;
			text-align: center;
		}
		.hero-container {
			max-width: 860px;
			margin: 0 auto;
		}
		.hero-title {
			font-size: 2.25rem;
			font-weight: 800;
			margin: 0 0 0.75rem 0;
			letter-spacing: -0.025em;
		}
		.hero-subtitle {
			font-size: 1.1rem;
			opacity: 0.9;
			margin: 0 0 0 0;
		}
		.main-container {
			max-width: 1080px;
			margin: -2rem auto 4rem auto;
			padding: 0 1.25rem;
		}
		.filter-card {
			background: var(--surface);
			border: 1px solid var(--border);
			border-radius: var(--radius);
			padding: 1.25rem 1.5rem;
			box-shadow: 0 4px 15px rgba(0,0,0,0.06);
			margin-bottom: 2rem;
		}
		.bids-grid {
			display: flex;
			flex-direction: column;
			gap: 1.25rem;
		}
		.bid-card {
			background: var(--surface);
			border: 1px solid var(--border);
			border-radius: var(--radius);
			padding: 1.5rem;
			box-shadow: 0 2px 6px rgba(0,0,0,0.04);
			transition: transform 0.15s ease, box-shadow 0.15s ease;
			display: flex;
			flex-direction: column;
			gap: 0.85rem;
		}
		.bid-card:hover {
			transform: translateY(-2px);
			box-shadow: 0 8px 24px rgba(0,0,0,0.08);
			border-color: var(--border-strong);
		}
		.badge {
			display: inline-block;
			padding: 0.25rem 0.55rem;
			font-size: 0.75rem;
			font-weight: 700;
			border-radius: 4px;
			text-transform: uppercase;
			letter-spacing: 0.03em;
		}
		.badge-itb { background: #e0f2fe; color: #0369a1; }
		.badge-rfp { background: #e0e7ff; color: #3730a3; }
		.badge-rfq { background: #f3e8ff; color: #6b21a8; }
		.badge-swr { background: #fef3c7; color: #92400e; }
		.badge-open { background: #dcfce7; color: #166534; }
		.badge-review { background: #fef3c7; color: #92400e; }
		.badge-awarded { background: #f3e8ff; color: #6b21a8; }
		.btn {
			display: inline-flex;
			align-items: center;
			justify-content: center;
			gap: 0.4rem;
			padding: 0.55rem 1.15rem;
			font-size: 0.875rem;
			font-weight: 600;
			border-radius: 6px;
			text-decoration: none;
			cursor: pointer;
			border: 1px solid transparent;
			transition: all 0.15s ease;
		}
		.btn-primary {
			background-color: var(--primary);
			color: #ffffff;
		}
		.btn-primary:hover {
			background-color: var(--primary-dark);
		}
		.btn-outline {
			background-color: transparent;
			border-color: var(--border-strong);
			color: var(--text);
		}
		.btn-outline:hover {
			background-color: #f1f5f9;
		}
		.footer {
			background: #0f172a;
			color: #94a3b8;
			padding: 3rem 1.5rem;
			font-size: 0.85rem;
			line-height: 1.7;
		}
		.footer a {
			color: #38bdf8;
			text-decoration: none;
		}
	</style>
</head>
<body>

<header class="bids-hero">
	<div class="hero-container">
		<div style="font-size:0.85rem; text-transform:uppercase; letter-spacing:0.12em; opacity:0.8; margin-bottom:0.5rem; font-weight:700;">
			Chelan County, Washington
		</div>
		<h1 class="hero-title">Public Solicitations &amp; Bid Board</h1>
		<p class="hero-subtitle">
			Official repository for Requests for Proposals (RFP), Requests for Qualifications (RFQ), and Calls for Bids (ITB) under RCW 39.04 and RCW 39.80.
		</p>
	</div>
</header>

<main class="main-container">
	<cfoutput>
	<!--- Filter Bar --->
	<div class="filter-card">
		<form method="get" action="#urlFor(controller='rfps', action='publicList')#" style="display:flex; flex-wrap:wrap; gap:1rem; align-items:flex-end;">
			
			<div style="flex:2; min-width:220px;">
				<label for="bidSearch" style="display:block; font-size:0.775rem; font-weight:600; margin-bottom:0.35rem; color:var(--text-muted);">Search Solicitations</label>
				<input type="search" id="bidSearch" name="q" value="#encodeForHTML(variables.searchQuery)#" placeholder="Keyword, project ##, or title..." style="width:100%; padding:0.6rem 0.85rem; border:1px solid var(--border-strong); border-radius:6px; font-size:0.9rem;">
			</div>

			<div style="flex:1; min-width:150px;">
				<label for="bidStatus" style="display:block; font-size:0.775rem; font-weight:600; margin-bottom:0.35rem; color:var(--text-muted);">Status</label>
				<select id="bidStatus" name="status" style="width:100%; padding:0.6rem 0.85rem; border:1px solid var(--border-strong); border-radius:6px; font-size:0.9rem;" onchange="this.form.submit()">
					<option value="Open" #(variables.selectedStatus eq "Open" ? "selected" : "")#>Open / Active Bids</option>
					<option value="Under Review" #(variables.selectedStatus eq "Under Review" ? "selected" : "")#>Under Evaluation</option>
					<option value="Awarded" #(variables.selectedStatus eq "Awarded" ? "selected" : "")#>Awarded Contracts</option>
					<option value="All" #(variables.selectedStatus eq "All" ? "selected" : "")#>All Solicitations</option>
				</select>
			</div>

			<div style="flex:1; min-width:150px;">
				<label for="bidType" style="display:block; font-size:0.775rem; font-weight:600; margin-bottom:0.35rem; color:var(--text-muted);">Procurement Type</label>
				<select id="bidType" name="type" style="width:100%; padding:0.6rem 0.85rem; border:1px solid var(--border-strong); border-radius:6px; font-size:0.9rem;" onchange="this.form.submit()">
					<option value="All" #(variables.selectedType eq "All" ? "selected" : "")#>All Types</option>
					<option value="RFP" #(variables.selectedType eq "RFP" ? "selected" : "")#>RFP (Proposals)</option>
					<option value="RFQ" #(variables.selectedType eq "RFQ" ? "selected" : "")#>RFQ (Qualifications)</option>
					<option value="ITB" #(variables.selectedType eq "ITB" ? "selected" : "")#>ITB (Call for Bids)</option>
					<option value="SWR" #(variables.selectedType eq "SWR" ? "selected" : "")#>Small Works Roster</option>
				</select>
			</div>

			<div style="flex:1; min-width:180px;">
				<label for="bidDept" style="display:block; font-size:0.775rem; font-weight:600; margin-bottom:0.35rem; color:var(--text-muted);">Issuing Department</label>
				<select id="bidDept" name="dept" style="width:100%; padding:0.6rem 0.85rem; border:1px solid var(--border-strong); border-radius:6px; font-size:0.9rem;" onchange="this.form.submit()">
					<option value="all" #(variables.selectedDept eq "all" ? "selected" : "")#>All Departments</option>
					<cfloop array="#variables.departments#" index="dept">
						<option value="#dept.code#" #(variables.selectedDept eq dept.code ? "selected" : "")#>#dept.name#</option>
					</cfloop>
				</select>
			</div>

			<div>
				<button type="submit" class="btn btn-primary" style="padding:0.6rem 1.25rem;">Search</button>
				<a href="#urlFor(controller='rfps', action='publicList')#" class="btn btn-outline" style="padding:0.6rem 1rem;">Reset</a>
			</div>
		</form>
	</div>

	<!--- Solicitations List --->
	<div class="bids-grid">
		<cfif variables.qBids.recordCount eq 0>
			<div style="background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:3rem 2rem; text-align:center;">
				<h3 style="margin:0 0 0.5rem 0; font-size:1.2rem; color:var(--text);">No Solicitations Found</h3>
				<p style="margin:0; color:var(--text-muted);">There are currently no active public solicitations matching your search criteria.</p>
			</div>
		<cfelse>
			<cfloop query="variables.qBids">
				<cfset typeClass = "badge-rfp">
				<cfif solicitation_type eq "ITB"><cfset typeClass = "badge-itb">
				<cfelseif solicitation_type eq "RFQ"><cfset typeClass = "badge-rfq">
				<cfelseif solicitation_type eq "SWR"><cfset typeClass = "badge-swr">
				</cfif>

				<cfset deadlineDiffDays = DateDiff("d", Now(), submission_deadline)>
				<cfset isPast = DateDiff("n", Now(), submission_deadline) LTE 0>

				<article class="bid-card">
					<div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:0.5rem;">
						<div style="display:flex; align-items:center; gap:0.65rem;">
							<span class="badge #typeClass#">#solicitation_type#</span>
							<span style="font-weight:700; font-size:0.9rem; color:var(--primary); letter-spacing:0.02em;">#solicitation_number#</span>
							<span style="color:var(--text-muted); font-size:0.85rem;">&bull;</span>
							<span style="color:var(--text-muted); font-size:0.85rem; font-weight:500;">#encodeForHTML(department_name)#</span>
						</div>
						
						<div>
							<cfif status eq "Open">
								<cfif isPast>
									<span class="badge badge-review">Closed &bull; Awaiting Review</span>
								<cfelseif deadlineDiffDays LTE 0>
									<span class="badge badge-review" style="color:var(--danger); background:##fee2e2;">Closes Today!</span>
								<cfelse>
									<span class="badge badge-open">Open &bull; #deadlineDiffDays# Day<cfif deadlineDiffDays neq 1>s</cfif> Left</span>
								</cfif>
							<cfelseif status eq "Under Review">
								<span class="badge badge-review">Bids Closed &bull; Under Evaluation</span>
							<cfelseif status eq "Awarded">
								<span class="badge badge-awarded">Awarded Contract</span>
							</cfif>
						</div>
					</div>

					<div>
						<h2 style="margin:0 0 0.4rem 0; font-size:1.25rem; font-weight:700; line-height:1.35;">
							<a href="/bids/#encodeForHTMLAttribute(slug)#" style="color:inherit; text-decoration:none;">
								#encodeForHTML(title)#
							</a>
						</h2>
						<cfif Len(summary)>
							<p style="margin:0; color:var(--text-muted); font-size:0.925rem;">
								#encodeForHTML(summary)#
							</p>
						</cfif>
					</div>

					<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:1rem; padding-top:0.75rem; border-top:1px solid var(--border); font-size:0.85rem;">
						<div style="display:flex; gap:1.5rem; flex-wrap:wrap;">
							<div>
								<span style="color:var(--text-muted);">Submission Deadline:</span>
								<strong style="color:var(--text); margin-left:0.25rem;">#DateFormat(submission_deadline, "mmm d, yyyy")# at #TimeFormat(submission_deadline, "h:mm tt")#</strong>
							</div>
							<cfif Len(estimated_budget_range)>
								<div>
									<span style="color:var(--text-muted);">Est. Budget:</span>
									<strong style="color:var(--text); margin-left:0.25rem;">#encodeForHTML(estimated_budget_range)#</strong>
								</div>
							</cfif>
							<cfif addenda_count GT 0>
								<div>
									<span style="background:##fef3c7; color:##92400e; padding:0.15rem 0.45rem; border-radius:4px; font-weight:600; font-size:0.775rem;">
										#addenda_count# Addend#(addenda_count eq 1 ? "um" : "a")# Issued
									</span>
								</div>
							</cfif>
						</div>

						<div style="display:flex; gap:0.5rem;">
							<a href="/bids/#encodeForHTMLAttribute(slug)#" class="btn btn-primary btn-sm">
								View Details &amp; Specs &rarr;
							</a>
						</div>
					</div>
				</article>
			</cfloop>
		</cfif>
	</div>
	</cfoutput>
</main>

<footer class="footer">
	<div style="max-width:1080px; margin:0 auto; display:grid; grid-template-columns:2fr 1fr; gap:2rem;">
		<div>
			<h4 style="color:#ffffff; margin:0 0 0.5rem 0; font-size:1rem;">Chelan County Purchasing &amp; Procurement</h4>
			<p style="margin:0 0 0.75rem 0;">
				Chelan County Board of Commissioners &bull; 400 Douglas Street, Suite 201, Wenatchee, WA 98801<br>
				Phone: (509) 667-6215 &bull; Web: <a href="https://www.chelancounty.gov">chelancounty.gov</a>
			</p>
			<p style="margin:0; font-size:0.775rem; color:#64748b;">
				Chelan County in accordance with Title VI of the Civil Rights Act of 1964 and Washington State Law assures that no person shall, on the grounds of race, color, national origin, or sex, be excluded from participation in, be denied the benefits of, or be otherwise subjected to discrimination under any County program or activity.
			</p>
		</div>
		<div style="text-align:right;">
			<div style="font-weight:600; color:#ffffff; margin-bottom:0.5rem;">Procurement Governance</div>
			<div>RCW 39.04 &mdash; Public Works</div>
			<div>RCW 39.80 &mdash; Architecture &amp; Engineering</div>
			<div>RCW 36.32 &mdash; County Commissioners Purchasing</div>
			<div style="margin-top:0.75rem; font-size:0.75rem; color:#64748b;">
				&copy; <cfoutput>#Year(Now())#</cfoutput> Chelan County, WA. All Rights Reserved.
			</div>
		</div>
	</div>
</footer>

</body>
</html>

