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
		.top-nav {
			background: #0b2545;
			color: #ffffff;
			padding: 0.85rem 1.5rem;
			font-size: 0.875rem;
		}
		.top-nav a {
			color: #38bdf8;
			text-decoration: none;
			font-weight: 500;
		}
		.top-nav a:hover {
			text-decoration: underline;
		}
		.container {
			max-width: 1140px;
			margin: 2rem auto 4rem auto;
			padding: 0 1.25rem;
		}
		.card {
			background: var(--surface);
			border: 1px solid var(--border);
			border-radius: var(--radius);
			padding: 1.75rem;
			box-shadow: 0 2px 8px rgba(0,0,0,0.04);
			margin-bottom: 1.5rem;
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
		.badge-closed { background: #f1f5f9; color: #475569; }
		.btn {
			display: inline-flex;
			align-items: center;
			justify-content: center;
			gap: 0.5rem;
			padding: 0.75rem 1.25rem;
			font-size: 0.95rem;
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
			width: 100%;
			box-shadow: 0 1px 3px rgba(0,0,0,0.1);
		}
		.btn-primary:hover {
			background-color: var(--primary-dark);
		}
		.btn-outline {
			background-color: #ffffff;
			border-color: var(--border-strong);
			color: var(--text);
		}
		.btn-outline:hover {
			background-color: #f1f5f9;
			border-color: var(--text-muted);
		}
		.timeline-item {
			display: flex;
			gap: 1rem;
			padding: 0.75rem 0;
			border-bottom: 1px solid var(--border);
		}
		.timeline-item:last-child {
			border-bottom: none;
		}
		.timeline-label {
			flex: 1;
			font-size: 0.85rem;
			color: var(--text-muted);
		}
		.timeline-val {
			flex: 1.5;
			font-size: 0.875rem;
			font-weight: 600;
			color: var(--text);
			text-align: right;
		}
		.solicitation-body h1, .solicitation-body h2, .solicitation-body h3 {
			color: var(--text);
			margin-top: 1.5rem;
			margin-bottom: 0.5rem;
		}
		.solicitation-body ul, .solicitation-body ol {
			padding-left: 1.25rem;
			margin-bottom: 1rem;
		}
		.footer {
			background: #0f172a;
			color: #94a3b8;
			padding: 3rem 1.5rem;
			font-size: 0.85rem;
			line-height: 1.7;
		}
	</style>
</head>
<body>

<div class="top-nav">
	<div style="max-width:1140px; margin:0 auto; display:flex; justify-content:space-between; align-items:center;">
		<div>
			<strong>Chelan County, WA</strong> &bull; Public Procurement &amp; Solicitations
		</div>
		<div>
			<a href="<cfoutput>#urlFor(controller='rfps', action='publicList')#</cfoutput>">&larr; Back to All Bids &amp; Solicitations</a>
		</div>
	</div>
</div>

<cfoutput>
<main class="container">
	<div style="display:grid; grid-template-columns: 2fr 1fr; gap: 2rem; align-items: start;">
		
		<!--- Left Column: Project Details, Addenda Attachments --->
		<div>
			<div class="card">
				<div style="display:flex; gap:0.65rem; align-items:center; margin-bottom:0.75rem; flex-wrap:wrap;">
					<span class="badge badge-rfp">#variables.qRfp.solicitation_type#</span>
					<span style="font-weight:700; color:var(--primary); font-size:0.95rem;">#variables.qRfp.solicitation_number#</span>
					<span style="color:var(--text-muted);">&bull;</span>
					<span style="color:var(--text-muted); font-size:0.9rem; font-weight:500;">#encodeForHTML(variables.qRfp.department_name)#</span>
					<span style="margin-left:auto;">
						<cfif variables.qRfp.status eq "Open">
							<span class="badge badge-open">Open for Submittals</span>
						<cfelseif variables.qRfp.status eq "Under Review">
							<span class="badge badge-review">Under Review</span>
						<cfelseif variables.qRfp.status eq "Awarded">
							<span class="badge badge-awarded">Awarded</span>
						<cfelse>
							<span class="badge badge-closed">#variables.qRfp.status#</span>
						</cfif>
					</span>
				</div>

				<h1 style="margin:0 0 1rem 0; font-size:1.85rem; font-weight:800; line-height:1.3; color:var(--text);">
					#encodeForHTML(variables.qRfp.title)#
				</h1>

				<cfif variables.qRfp.status eq "Awarded">
					<div style="background:##f3e8ff; border:1px solid ##d8b4fe; padding:1.25rem; border-radius:8px; margin-bottom:1.5rem;">
						<div style="font-weight:700; color:var(--purple); font-size:1rem; margin-bottom:0.35rem;">
							&bull; Contract Award Notice
						</div>
						<div style="font-size:0.925rem; color:##3b0764;">
							This solicitation has been awarded to <strong>#encodeForHTML(variables.qRfp.awarded_vendor)#</strong>
							<cfif IsNumeric(variables.qRfp.awarded_amount)>
								in the amount of <strong>$#NumberFormat(variables.qRfp.awarded_amount, ",.__")#</strong>
							</cfif>
							<cfif Len(variables.qRfp.bocc_resolution_number)>
								under Board of County Commissioners Resolution <strong>#encodeForHTML(variables.qRfp.bocc_resolution_number)#</strong>
							</cfif>
							<cfif IsDate(variables.qRfp.award_date)>
								on #DateFormat(variables.qRfp.award_date, "mmmm d, yyyy")#
							</cfif>.
						</div>
						<cfif Len(variables.qRfp.tabulation_file_url)>
							<div style="margin-top:0.75rem;">
								<a href="#variables.qRfp.tabulation_file_url#" target="_blank" rel="noopener" class="btn btn-outline" style="font-size:0.85rem; padding:0.4rem 0.85rem;">
									Download Bid Tabulation Sheet (PDF) &rarr;
								</a>
							</div>
						</cfif>
					</div>
				</cfif>

				<cfif Len(variables.qRfp.summary)>
					<div style="font-size:1.05rem; color:var(--text-muted); line-height:1.6; margin-bottom:1.5rem; padding-bottom:1.25rem; border-bottom:1px solid var(--border);">
						#encodeForHTML(variables.qRfp.summary)#
					</div>
				</cfif>

				<div style="font-size:0.95rem; line-height:1.7; color:var(--text);" class="solicitation-body">
					<h2 style="font-size:1.2rem; font-weight:700; margin-top:0;">Scope of Work &amp; Project Description</h2>
					<cfif Len(variables.qRfp.description_html)>
						#variables.qRfp.description_html#
					<cfelse>
						<p style="color:var(--text-muted);">Please download and review the official specifications packet below for complete project requirements.</p>
					</cfif>
				</div>
			</div>

			<!--- Sequenced Addenda & Clarifications Section --->
			<div class="card" id="addenda">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
					<h2 style="margin:0; font-size:1.2rem; font-weight:700; color:var(--text);">
						Addenda &amp; Clarifications (#variables.qAddenda.recordCount#)
					</h2>
				</div>
				<p style="font-size:0.875rem; color:var(--text-muted); margin-bottom:1.25rem;">
					All issued addenda become part of the contract documents. Proposers must acknowledge all addenda in their submittal.
				</p>

				<cfif variables.qAddenda.recordCount eq 0>
					<div style="padding:1.5rem; background:##f8fafc; border:1px solid var(--border); border-radius:6px; color:var(--text-muted); font-size:0.9rem;">
						No formal addenda or revisions have been issued for this solicitation at this time.
					</div>
				<cfelse>
					<div style="display:flex; flex-direction:column; gap:1rem;">
						<cfloop query="variables.qAddenda">
							<div style="border:1px solid var(--border); border-radius:8px; padding:1.25rem; background:##ffffff; box-shadow:0 1px 3px rgba(0,0,0,0.03);">
								<div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:0.5rem;">
									<div style="font-weight:700; font-size:1rem; color:var(--primary);">
										Addendum ###addendum_number#: #encodeForHTML(title)#
									</div>
									<div style="font-size:0.8rem; color:var(--text-muted);">
										Issued: #DateFormat(published_at, "mmm d, yyyy")#
									</div>
								</div>
								<cfif Len(description_html)>
									<div style="font-size:0.9rem; color:var(--text-muted); line-height:1.5; margin-bottom:0.85rem;">
										#description_html#
									</div>
								</cfif>
								<cfif Len(file_url)>
									<div>
										<a href="#file_url#" target="_blank" rel="noopener" class="btn btn-outline" style="font-size:0.85rem; padding:0.4rem 0.85rem;">
											Download Addendum ###addendum_number# (PDF) &rarr;
										</a>
									</div>
								</cfif>
							</div>
						</cfloop>
					</div>
				</cfif>
			</div>
		</div>

		<!--- Right Column: Primary Packet Download, Submittal Instructions, Key Dates, Contact --->
		<div>
			
			<!--- Specifications Packet Download Card --->
			<div class="card" style="padding:1.5rem; border-top: 4px solid var(--primary);">
				<h2 style="margin:0 0 0.5rem 0; font-size:1.15rem; font-weight:700; color:var(--text);">
					Solicitation Documents
				</h2>
				<p style="font-size:0.85rem; color:var(--text-muted); margin-bottom:1.25rem;">
					Download the primary RFP/bid specifications, contract terms, and drawings.
				</p>

				<cfif Len(variables.qRfp.primary_packet_url)>
					<a href="#variables.qRfp.primary_packet_url#" target="_blank" rel="noopener" class="btn btn-primary" style="margin-bottom:0.5rem;">
						<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
						Download Complete Specs (PDF)
					</a>
				<cfelse>
					<div style="padding:0.75rem; background:##f1f5f9; border-radius:6px; font-size:0.85rem; color:var(--text-muted);">
						Official bid documents are available upon request from the department contact listed below.
					</div>
				</cfif>

				<cfif Len(variables.qRfp.estimated_budget_range)>
					<div style="margin-top:1rem; padding-top:0.75rem; border-top:1px solid var(--border); font-size:0.85rem;">
						<span style="color:var(--text-muted);">Estimated Project Budget:</span>
						<div style="font-weight:700; color:var(--text); font-size:0.95rem;">#encodeForHTML(variables.qRfp.estimated_budget_range)#</div>
					</div>
				</cfif>
			</div>

			<!--- How to Submit Card --->
			<div class="card" style="padding:1.5rem;">
				<h2 style="margin:0 0 0.75rem 0; font-size:1.15rem; font-weight:700; color:var(--text);">
					How to Submit
				</h2>

				<div style="margin-bottom:0.75rem;">
					<span style="font-size:0.8rem; font-weight:700; text-transform:uppercase; color:var(--text-muted); letter-spacing:0.04em;">Delivery Method</span>
					<div style="font-weight:700; font-size:0.95rem; color:var(--primary); margin-top:0.15rem;">
						#variables.qRfp.submission_method# Submission
					</div>
				</div>

				<div style="font-size:0.875rem; color:var(--text); line-height:1.6; background:##f8fafc; padding:0.85rem; border-radius:6px; border:1px solid var(--border);">
					<cfif Len(variables.qRfp.submission_instructions)>
						#encodeForHTML(variables.qRfp.submission_instructions)#
					<cfelse>
						Submittals must be received prior to the submission deadline at the issuing department address below. Late submittals cannot be accepted.
					</cfif>
				</div>
			</div>

			<!--- Procurement Timeline Card --->
			<div class="card" style="padding:1.5rem;">
				<h2 style="margin:0 0 1rem 0; font-size:1.15rem; font-weight:700; color:var(--text); border-bottom:1px solid var(--border); padding-bottom:0.75rem;">
					Important Dates
				</h2>

				<div class="timeline-item">
					<div class="timeline-label">Publication Date</div>
					<div class="timeline-val">
						<cfif IsDate(variables.qRfp.publish_at)>#DateFormat(variables.qRfp.publish_at, "mmm d, yyyy")#<cfelse>—</cfif>
					</div>
				</div>

				<cfif IsDate(variables.qRfp.pre_bid_datetime)>
					<div class="timeline-item">
						<div class="timeline-label">
							Pre-Bid Meeting
							<cfif variables.qRfp.is_pre_bid_mandatory eq 1>
								<div style="color:var(--danger); font-size:0.75rem; font-weight:700;">MANDATORY</div>
							</cfif>
						</div>
						<div class="timeline-val">
							#DateFormat(variables.qRfp.pre_bid_datetime, "mmm d, yyyy")#<br>
							<span style="font-size:0.8rem; font-weight:normal; color:var(--text-muted);">#TimeFormat(variables.qRfp.pre_bid_datetime, "h:mm tt")#</span>
							<cfif Len(variables.qRfp.pre_bid_location)>
								<div style="font-size:0.75rem; font-weight:normal; color:var(--text-muted);">#encodeForHTML(variables.qRfp.pre_bid_location)#</div>
							</cfif>
						</div>
					</div>
				</cfif>

				<cfif IsDate(variables.qRfp.questions_due_at)>
					<div class="timeline-item">
						<div class="timeline-label">Questions Cutoff</div>
						<div class="timeline-val">#DateFormat(variables.qRfp.questions_due_at, "mmm d, yyyy")#</div>
					</div>
				</cfif>

				<div class="timeline-item" style="background:##f8fafc; margin:0 -0.5rem; padding:0.85rem 0.5rem; border-radius:6px; border:1px solid var(--primary);">
					<div class="timeline-label" style="font-weight:700; color:var(--primary);">
						Submission Deadline
					</div>
					<div class="timeline-val" style="color:var(--primary); font-weight:800;">
						#DateFormat(variables.qRfp.submission_deadline, "mmm d, yyyy")#<br>
						<span>#TimeFormat(variables.qRfp.submission_deadline, "h:mm tt")#</span>
					</div>
				</div>

				<cfif IsDate(variables.qRfp.bid_opening_datetime)>
					<div class="timeline-item">
						<div class="timeline-label">Public Bid Opening</div>
						<div class="timeline-val">
							#DateFormat(variables.qRfp.bid_opening_datetime, "mmm d, yyyy")#<br>
							<span style="font-size:0.8rem; font-weight:normal; color:var(--text-muted);">#TimeFormat(variables.qRfp.bid_opening_datetime, "h:mm tt")#</span>
							<cfif Len(variables.qRfp.bid_opening_location)>
								<div style="font-size:0.75rem; font-weight:normal; color:var(--text-muted);">#encodeForHTML(variables.qRfp.bid_opening_location)#</div>
							</cfif>
						</div>
					</div>
				</cfif>
			</div>

			<!--- Department Inquiries Contact Card --->
			<div class="card" style="padding:1.5rem;">
				<h2 style="margin:0 0 0.75rem 0; font-size:1.15rem; font-weight:700; color:var(--text);">
					Project Inquiries
				</h2>
				<div style="font-size:0.875rem; line-height:1.6; color:var(--text-muted);">
					<cfif Len(variables.qRfp.contact_name)>
						<div style="font-weight:600; color:var(--text);">#encodeForHTML(variables.qRfp.contact_name)#</div>
					</cfif>
					<div>#encodeForHTML(variables.qRfp.department_name)#</div>
					<cfif Len(variables.qRfp.contact_email)>
						<div><a href="mailto:#encodeForHTML(variables.qRfp.contact_email)#" style="color:var(--primary); text-decoration:none;">#encodeForHTML(variables.qRfp.contact_email)#</a></div>
					</cfif>
					<cfif Len(variables.qRfp.contact_phone)>
						<div>#encodeForHTML(variables.qRfp.contact_phone)#</div>
					</cfif>
				</div>
			</div>

		</div>
	</div>
</main>
</cfoutput>

<footer class="footer">
	<div style="max-width:1140px; margin:0 auto; text-align:center; font-size:0.85rem;">
		Chelan County Board of Commissioners &bull; 400 Douglas Street, Wenatchee, WA 98801<br>
		&copy; <cfoutput>#Year(Now())#</cfoutput> Chelan County, WA. All Rights Reserved.
	</div>
</footer>

</body>
</html>
