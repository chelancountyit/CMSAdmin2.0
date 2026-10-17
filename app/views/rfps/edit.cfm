<cfset isNew = (variables.solicitation.id EQ 0)>
<cfoutput>
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">
			<cfif isNew>
				Post Solicitation Announcement
			<cfelse>
				Edit Announcement: #encodeForHTML(variables.solicitation.solicitationNumber)#
			</cfif>
		</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='rfps', action='index')#">Bids &amp; RFPs</a></li>
				<li class="breadcrumb-item active" aria-current="page"><cfif isNew>New Announcement<cfelse>#encodeForHTML(variables.solicitation.solicitationNumber)#</cfif></li>
			</ol>
		</nav>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center;">
		<a href="#urlFor(controller='rfps', action='index')#" class="btn btn-outline btn-sm">
			#svgIcon(name="arrow-left", size=14)#
			<span>Back to List</span>
		</a>
		<cfif NOT isNew>
			<a href="/bids/#encodeForHTMLAttribute(variables.solicitation.slug)#" target="_blank" rel="noopener" class="btn btn-outline btn-sm" title="View Live Public Notice">
				#svgIcon(name="eye", size=14)#
				<span>View Public Notice &rarr;</span>
			</a>
		</cfif>
		<button type="button" class="btn btn-primary btn-sm" id="btnTopSave" onclick="submitSolicitationForm()">
			#svgIcon(name="check-circle", size=15)#
			<span>Save Announcement</span>
		</button>
	</div>
</div>

<form id="solicitationForm" method="post" action="#urlFor(controller='rfps', action='save')#" novalidate>
	<input type="hidden" name="id" id="solicitationId" value="#variables.solicitation.id#">
	<input type="hidden" name="site_id" id="site_id" value="#encodeForHTMLAttribute(variables.solicitation.siteId)#">
	<input type="hidden" name="authenticityToken" value="#authenticityToken()#">

	<div style="display:grid; grid-template-columns: minmax(0, 2fr) minmax(320px, 1fr); gap:1.5rem; align-items:start;">
		
		<!--- Left Column: Project Scope & Document Attachments --->
		<div style="display:flex; flex-direction:column; gap:1.5rem;">
			
			<!--- Card 1: Core Identification --->
			<div class="admin-card" style="padding:1.5rem;">
				<h3 style="margin-top:0; margin-bottom:1.25rem; font-size:1.1rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="file-text", size=18)# Announcement Information
				</h3>

				<div style="display:grid; grid-template-columns:1fr 2fr; gap:1rem; margin-bottom:1rem;">
					<div>
						<label for="solicitation_number" class="form-label" style="font-weight:600;">Project / Solicitation ## <span style="color:var(--admin-danger);">*</span></label>
						<input type="text" id="solicitation_number" name="solicitation_number" class="form-control" value="#encodeForHTML(variables.solicitation.solicitationNumber)#" required placeholder="e.g. PW-2026-08">
					</div>
					<div>
						<label for="title" class="form-label" style="font-weight:600;">Project Title <span style="color:var(--admin-danger);">*</span></label>
						<input type="text" id="title" name="title" class="form-control" value="#encodeForHTML(variables.solicitation.title)#" required placeholder="e.g. Manson Boulevard Roadway & Drainage Improvements" oninput="autoGenerateSlug(this.value)">
					</div>
				</div>

				<!--- Clean Single-Line URL Slug Input --->
				<div style="margin-bottom:1.25rem;">
					<label for="slug" class="form-label" style="font-weight:600; display:flex; justify-content:space-between; align-items:center; margin-bottom:0.4rem;">
						<span>URL Slug <span style="font-weight:normal; color:var(--admin-text-muted); font-size:0.775rem;">(Lowercase letters, numbers, hyphens)</span></span>
						<span style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:500;">Public Web Address</span>
					</label>
					<div style="display:flex; align-items:stretch; border:1px solid var(--admin-border); border-radius:var(--radius-md); overflow:hidden; background:var(--admin-surface); box-shadow:0 1px 2px rgba(0,0,0,0.03);">
						<span style="background:var(--admin-bg, ##f1f5f9); color:var(--admin-text-muted); padding:0.5rem 0.85rem; font-size:0.825rem; font-family:monospace; border-right:1px solid var(--admin-border); display:inline-flex; align-items:center; user-select:none; white-space:nowrap; font-weight:600;">
							https://chelancounty.gov/bids/
						</span>
						<input type="text" id="slug" name="slug" class="form-control" value="#encodeForHTML(variables.solicitation.slug)#" style="border:none; border-radius:0; box-shadow:none; font-family:monospace; font-size:0.85rem; padding:0.5rem 0.85rem; flex:1; min-width:140px; background:transparent;" placeholder="project-title-slug" oninput="updateSlugPreview(this.value)">
					</div>
					<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem; display:flex; align-items:center; gap:0.4rem;">
						<span>Direct Link:</span>
						<code style="color:var(--admin-primary); background:rgba(0,115,170,0.07); padding:0.15rem 0.45rem; border-radius:4px; font-size:0.775rem;">/bids/<span id="slugLivePreview">#encodeForHTML(variables.solicitation.slug)#</span></code>
					</div>
				</div>

				<div style="margin-bottom:1rem;">
					<label for="summary" class="form-label" style="font-weight:600;">Brief Summary</label>
					<textarea id="summary" name="summary" class="form-control" rows="2" placeholder="1-2 sentence overview for cards and search results...">#encodeForHTML(variables.solicitation.summary)#</textarea>
				</div>

				<div style="margin-bottom:0;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.4rem;">
						<label for="description_html" class="form-label" style="font-weight:600; margin-bottom:0;">
							Detailed Specifications &amp; Scope of Work
						</label>
						<span style="font-size:0.75rem; color:var(--admin-text-muted); font-weight:500;">
							Rich HTML &bull; Accessible JBDEditor
						</span>
					</div>
					<textarea id="description_html" name="description_html" class="form-control" data-jbd-editor data-jbd-toolbar="basic" data-jbd-inline-toolbar="true" data-jbd-height="360px" data-jbd-placeholder="Provide a detailed project scope, specifications summary, mandatory vendor qualifications, deliverables, or special instructions...">#encodeForHTML(variables.solicitation.descriptionHtml)#</textarea>
				</div>
			</div>

			<!--- Card 2: Document Attachments & Addenda --->
			<div class="admin-card" style="padding:1.5rem;">
				<h3 style="margin-top:0; margin-bottom:1rem; font-size:1.1rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="paperclip", size=18)# Specifications Packet &amp; Attachments
				</h3>

				<div style="margin-bottom:1.25rem;">
					<label for="primary_packet_url" class="form-label" style="font-weight:600;">Primary Spec Book / RFP Package (PDF)</label>
					<div style="display:flex; gap:0.5rem;">
						<input type="text" id="primary_packet_url" name="primary_packet_url" class="form-control" value="#encodeForHTML(variables.solicitation.primaryPacketUrl)#" placeholder="/files/public-works/specs.pdf" style="flex:1;">
						<button type="button" class="btn btn-secondary btn-sm" onclick="openMediaPickerForInput('primary_packet_url', 'Select Specification Packet')">
							#svgIcon(name="media", size=14)# Browse
						</button>
						<cfif Len(variables.solicitation.primaryPacketUrl)>
							<a href="#variables.solicitation.primaryPacketUrl#" target="_blank" rel="noopener" class="btn btn-outline btn-sm">
								#svgIcon(name="external-link", size=14)# Open
							</a>
						</cfif>
					</div>
					<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">
						The main PDF that contractors will download directly from the public announcement page.
					</div>
				</div>

				<!--- Sequenced Addenda List --->
				<div style="border-top:1px solid var(--admin-border); padding-top:1.25rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
						<div>
							<h4 style="margin:0; font-size:0.95rem; font-weight:700; color:var(--admin-text-main);">Addenda / Amendments (#variables.qAddenda.recordCount#)</h4>
							<div style="font-size:0.775rem; color:var(--admin-text-muted);">Optional revisions, boring logs, or Q&amp;A clarifications issued for this RFP.</div>
						</div>
						<cfif NOT isNew>
							<button type="button" class="btn btn-outline btn-sm" onclick="openAddendumModal()">
								#svgIcon(name="plus", size=13)# + Add Addendum
							</button>
						</cfif>
					</div>

					<cfif isNew>
						<div style="font-size:0.8rem; color:var(--admin-text-muted); padding:0.85rem; background:var(--admin-card-bg); border-radius:6px; border:1px dashed var(--admin-border);">
							Save this announcement first to attach numbered addenda files.
						</div>
					<cfelseif variables.qAddenda.recordCount eq 0>
						<div style="font-size:0.8rem; color:var(--admin-text-muted); padding:0.85rem; background:var(--admin-card-bg); border-radius:6px; border:1px dashed var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
							<span>No addenda issued yet.</span>
							<button type="button" class="btn btn-outline btn-sm" onclick="openAddendumModal()" style="font-size:0.775rem; padding:0.25rem 0.6rem;">
								+ Attach Addendum ##1
							</button>
						</div>
					<cfelse>
						<div style="display:flex; flex-direction:column; gap:0.5rem;">
							<cfloop query="variables.qAddenda">
								<div style="display:flex; justify-content:space-between; align-items:center; padding:0.6rem 0.85rem; border:1px solid var(--admin-border); border-radius:6px; background:var(--admin-surface);">
									<div>
										<strong style="color:var(--admin-primary); font-size:0.85rem;">Addendum ###addendum_number#:</strong>
										<span style="font-size:0.85rem; margin-left:0.35rem;">#encodeForHTML(title)#</span>
										<cfif Len(file_url)>
											<span style="font-size:0.75rem; color:var(--admin-text-muted); margin-left:0.5rem; font-family:monospace;">(#file_url#)</span>
										</cfif>
									</div>
									<div style="display:flex; gap:0.4rem; align-items:center;">
										<cfif Len(file_url)>
											<a href="#file_url#" target="_blank" rel="noopener" class="btn btn-outline btn-sm" style="padding:0.2rem 0.45rem; font-size:0.75rem;">Download</a>
										</cfif>
										<button type="button" class="btn btn-sm btn-icon-only btn-outline" style="color:var(--admin-danger); padding:0.2rem;" onclick="deleteAddendum(#id#)" title="Delete Addendum">
											#svgIcon(name="trash", size=13)#
										</button>
									</div>
								</div>
							</cfloop>
						</div>
					</cfif>
				</div>
			</div>

			<!--- Card 3: How Contractors Submit --->
			<div class="admin-card" style="padding:1.5rem;">
				<h3 style="margin-top:0; margin-bottom:1rem; font-size:1.1rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="mail", size=18)# Submittal Instructions &amp; Requirements
				</h3>

				<div style="display:grid; grid-template-columns:1fr 2fr; gap:1rem; margin-bottom:1rem;">
					<div>
						<label for="submission_method" class="form-label" style="font-weight:600;">Submission Method</label>
						<select id="submission_method" name="submission_method" class="form-control">
							<option value="Physical" #(variables.solicitation.submissionMethod eq "Physical" ? "selected" : "")#>Sealed Hardcopy / Delivery</option>
							<option value="Email" #(variables.solicitation.submissionMethod eq "Email" ? "selected" : "")#>Electronic Submission (Email PDF)</option>
							<option value="Portal" #(variables.solicitation.submissionMethod eq "Portal" ? "selected" : "")#>Online Portal / External Link</option>
						</select>
					</div>
					<div>
						<label for="submission_instructions" class="form-label" style="font-weight:600;">Delivery Instructions</label>
						<textarea id="submission_instructions" name="submission_instructions" class="form-control" rows="2" placeholder="e.g. Deliver 1 original and 2 copies in a sealed envelope marked 'PW-2026-08' to the Public Works front desk.">#encodeForHTML(variables.solicitation.submissionInstructions)#</textarea>
					</div>
				</div>
			</div>
		</div>

		<!--- Right Column: Status, Dates, Contact --->
		<div style="display:flex; flex-direction:column; gap:1.5rem;">
			
			<!--- Publishing Status --->
			<div class="admin-card" style="padding:1.5rem;">
				<h3 style="margin-top:0; margin-bottom:1rem; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">
					Status &amp; Publishing
				</h3>

				<div style="margin-bottom:1rem;">
					<label for="status" class="form-label" style="font-weight:600;">Status</label>
					<select id="status" name="status" class="form-control" onchange="toggleAwardFields(this.value)">
						<option value="Open" #(variables.solicitation.status eq "Open" ? "selected" : "")#>Open / Active Bidding</option>
						<option value="Draft" #(variables.solicitation.status eq "Draft" ? "selected" : "")#>Draft (Not Published)</option>
						<option value="Scheduled" #(variables.solicitation.status eq "Scheduled" ? "selected" : "")#>Scheduled (Auto-opens on date)</option>
						<option value="Under Review" #(variables.solicitation.status eq "Under Review" ? "selected" : "")#>Closed / Under Evaluation</option>
						<option value="Awarded" #(variables.solicitation.status eq "Awarded" ? "selected" : "")#>Awarded</option>
						<option value="Cancelled" #(variables.solicitation.status eq "Cancelled" ? "selected" : "")#>Cancelled</option>
					</select>
				</div>

				<div style="margin-bottom:1rem;">
					<label for="solicitation_type" class="form-label" style="font-weight:600;">Type</label>
					<select id="solicitation_type" name="solicitation_type" class="form-control">
						<option value="RFP" #(variables.solicitation.solicitationType eq "RFP" ? "selected" : "")#>RFP &mdash; Request for Proposals</option>
						<option value="RFQ" #(variables.solicitation.solicitationType eq "RFQ" ? "selected" : "")#>RFQ &mdash; Request for Qualifications</option>
						<option value="ITB" #(variables.solicitation.solicitationType eq "ITB" ? "selected" : "")#>ITB &mdash; Call for Bids</option>
						<option value="SWR" #(variables.solicitation.solicitationType eq "SWR" ? "selected" : "")#>Small Works Roster Project</option>
						<option value="NOTICE" #(variables.solicitation.solicitationType eq "NOTICE" ? "selected" : "")#>Sole Source / Intent Notice</option>
					</select>
				</div>


				<div style="margin-bottom:0;">
					<label for="estimated_budget_range" class="form-label" style="font-weight:600;">Estimated Budget (Optional)</label>
					<input type="text" id="estimated_budget_range" name="estimated_budget_range" class="form-control" value="#encodeForHTML(variables.solicitation.estimatedBudgetRange)#" placeholder="e.g. $150,000 - $200,000">
				</div>

				<!--- Optional Award Fields (revealed if status is Awarded) --->
				<div id="awardNoticeSection" style="margin-top:1.25rem; padding-top:1rem; border-top:1px solid var(--admin-border); #(variables.solicitation.status neq 'Awarded' ? 'display:none;' : '')#">
					<div style="font-weight:700; font-size:0.875rem; color:var(--admin-purple, ##7e22ce); margin-bottom:0.5rem;">
						Award Announcement
					</div>
					<div style="margin-bottom:0.75rem;">
						<label class="form-label" style="font-size:0.775rem;">Winning Contractor / Firm</label>
						<input type="text" id="awarded_vendor" name="awarded_vendor" class="form-control" value="#encodeForHTML(variables.solicitation.awardedVendor)#" placeholder="e.g. Selland Construction">
					</div>
					<div>
						<label class="form-label" style="font-size:0.775rem;">Award Amount ($)</label>
						<input type="number" step="0.01" id="awarded_amount" name="awarded_amount" class="form-control" value="#variables.solicitation.awardedAmount#" placeholder="0.00">
					</div>
				</div>
			</div>

			<!--- Critical Dates --->
			<div class="admin-card" style="padding:1.5rem;">
				<h3 style="margin-top:0; margin-bottom:1rem; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">
					Important Dates
				</h3>

				<div style="margin-bottom:1rem; background:var(--admin-card-bg); border:1.5px solid var(--admin-primary); padding:0.85rem; border-radius:6px;">
					<label for="submission_deadline" class="form-label" style="font-weight:700; color:var(--admin-primary); font-size:0.85rem;">
						Submission Deadline <span style="color:var(--admin-danger);">*</span>
					</label>
					<input type="datetime-local" id="submission_deadline" name="submission_deadline" class="form-control" value="#variables.solicitation.submissionDeadlineStr#" required style="border-color:var(--admin-primary); font-weight:600;">
					<div style="font-size:0.725rem; color:var(--admin-text-muted); margin-top:0.25rem;">
						Exact cutoff for proposals.
					</div>
				</div>

				<div style="margin-bottom:1rem;">
					<label for="publish_at" class="form-label" style="font-weight:600; font-size:0.85rem;">Issue / Publication Date</label>
					<input type="datetime-local" id="publish_at" name="publish_at" class="form-control" value="#variables.solicitation.publishAtStr#">
				</div>

				<div style="margin-bottom:1rem;">
					<label for="questions_due_at" class="form-label" style="font-weight:600; font-size:0.85rem;">Questions Due Cutoff</label>
					<input type="datetime-local" id="questions_due_at" name="questions_due_at" class="form-control" value="#variables.solicitation.questionsDueAtStr#">
				</div>

				<div style="border-top:1px solid var(--admin-border); padding-top:0.85rem; margin-top:0.85rem;">
					<label for="pre_bid_datetime" class="form-label" style="font-weight:600; font-size:0.85rem;">Pre-Bid Meeting (Optional)</label>
					<input type="datetime-local" id="pre_bid_datetime" name="pre_bid_datetime" class="form-control" value="#variables.solicitation.preBidDatetimeStr#" style="margin-bottom:0.5rem;">
					<input type="text" id="pre_bid_location" name="pre_bid_location" class="form-control" value="#encodeForHTML(variables.solicitation.preBidLocation)#" placeholder="Meeting room or Teams URL...">
				</div>
			</div>

			<!--- Department Contact --->
			<div class="admin-card" style="padding:1.5rem;">
				<h3 style="margin-top:0; margin-bottom:1rem; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">
					Inquiries Contact
				</h3>

				<div style="margin-bottom:0.75rem;">
					<label for="contact_name" class="form-label" style="font-size:0.8rem; font-weight:600;">Contact Person</label>
					<input type="text" id="contact_name" name="contact_name" class="form-control" value="#encodeForHTML(variables.solicitation.contactName)#" placeholder="e.g. Eric Pierson, P.E.">
				</div>

				<div style="margin-bottom:0.75rem;">
					<label for="contact_email" class="form-label" style="font-size:0.8rem; font-weight:600;">Contact Email</label>
					<input type="email" id="contact_email" name="contact_email" class="form-control" value="#encodeForHTML(variables.solicitation.contactEmail)#" placeholder="email@co.chelan.wa.us">
				</div>

				<div>
					<label for="contact_phone" class="form-label" style="font-size:0.8rem; font-weight:600;">Contact Phone</label>
					<input type="text" id="contact_phone" name="contact_phone" class="form-control" value="#encodeForHTML(variables.solicitation.contactPhone)#" placeholder="(509) 667-...">
				</div>
			</div>
		</div>
	</div>
</form>

<!--- ================================================================= --->
<!--- MODAL: ADD ADDENDUM --->
<!--- ================================================================= --->
<div class="admin-modal-backdrop" id="addendumModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99990; background:rgba(15,23,42,0.6); backdrop-filter:blur(4px);" onclick="closeAddendumModal()"></div>
<div class="admin-modal" id="addendumModal" role="dialog" aria-modal="true" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99991; width:90vw; max-width:560px; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 20px 50px rgba(0,0,0,0.3); border:1px solid var(--admin-border); flex-direction:column; max-height:90vh; overflow:auto;">
	<div style="padding:1.25rem 1.5rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
		<h3 style="margin:0; font-size:1.05rem; font-weight:700;">Attach Addendum</h3>
		<button type="button" class="btn btn-sm btn-icon-only btn-outline" onclick="closeAddendumModal()">#svgIcon(name="close", size=14)#</button>
	</div>
	<div style="padding:1.5rem; display:flex; flex-direction:column; gap:1rem;">
		<div>
			<label class="form-label" style="font-weight:600;">Addendum Number</label>
			<input type="number" id="addendum_number" class="form-control" placeholder="Leave empty for next sequential number (e.g. 1)">
		</div>
		<div>
			<label class="form-label" style="font-weight:600;">Addendum Title <span style="color:var(--admin-danger);">*</span></label>
			<input type="text" id="addendum_title" class="form-control" placeholder="e.g. Addendum 1: Clarification of Questions">
		</div>
		<div>
			<label class="form-label" style="font-weight:600;">Addendum PDF Document</label>
			<div style="display:flex; gap:0.5rem;">
				<input type="text" id="addendum_file_url" class="form-control" placeholder="/files/.../addendum-1.pdf">
				<button type="button" class="btn btn-secondary btn-sm" onclick="openMediaPickerForInput('addendum_file_url', 'Select Addendum PDF')">Browse</button>
			</div>
		</div>
		<div>
			<label class="form-label" style="font-weight:600;">Summary / Description</label>
			<textarea id="addendum_desc" class="form-control" rows="2" placeholder="Brief summary of what this addendum covers..."></textarea>
		</div>
	</div>
	<div style="padding:1rem 1.5rem; border-top:1px solid var(--admin-border); display:flex; justify-content:flex-end; gap:0.5rem; background:var(--admin-card-bg);">
		<button type="button" class="btn btn-outline btn-sm" onclick="closeAddendumModal()">Cancel</button>
		<button type="button" class="btn btn-primary btn-sm" onclick="submitAddendum()">Save Addendum</button>
	</div>
</div>

<!--- ================================================================= --->
<!--- MEDIA LIBRARY PICKER MODAL --->
<!--- ================================================================= --->
<div class="admin-modal-backdrop" id="mediaPickerModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72); backdrop-filter:blur(6px);" onclick="closeMediaPickerModal()"></div>
<div class="admin-modal" id="mediaPickerModal" role="dialog" aria-modal="true" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:96vw; max-width:1440px; height:88vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	<div class="modal-header" style="display:flex; justify-content:space-between; align-items:center; padding:1rem 1.5rem; border-bottom:1px solid var(--admin-border);">
		<h2 class="modal-title" id="mediaPickerModalTitle" style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">
			<span id="mediaPickerTitleText">Select Asset from Media Library</span>
		</h2>
		<button type="button" class="btn btn-sm btn-icon-only btn-outline" onclick="closeMediaPickerModal()">
			#svgIcon(name="close", size=14)#
		</button>
	</div>
	<div class="modal-body" style="flex:1; padding:0; overflow:hidden; position:relative;">
		<iframe id="mediaPickerIframe" src="about:blank" style="width:100%; height:100%; border:none;" title="Media Asset Picker"></iframe>
	</div>
</div>
</cfoutput>

<script>
// Auto-generate URL slug from title
function autoGenerateSlug(text) {
	const slugInput = document.getElementById('slug');
	if (slugInput && !slugInput.dataset.manual) {
		let s = text.toLowerCase().trim()
			.replace(/[^a-z0-9\s-]/g, '')
			.replace(/\s+/g, '-')
			.replace(/-+/g, '-');
		slugInput.value = s;
		updateSlugPreview(s);
	}
}

function updateSlugPreview(val) {
	const preview = document.getElementById('slugLivePreview');
	if (preview) {
		preview.innerText = val ? val.trim() : '...';
	}
}

document.getElementById('slug').addEventListener('input', function() {
	this.dataset.manual = 'true';
	updateSlugPreview(this.value);
});

function toggleAwardFields(statusVal) {
	const el = document.getElementById('awardNoticeSection');
	if (el) {
		el.style.display = (statusVal === 'Awarded') ? 'block' : 'none';
	}
}

// Save Solicitation Form
function submitSolicitationForm() {
	const form = document.getElementById('solicitationForm');
	const title = document.getElementById('title').value.trim();
	const number = document.getElementById('solicitation_number').value.trim();
	const deadline = document.getElementById('submission_deadline').value.trim();

	// Synchronize JBDEditor content to underlying textarea before gathering FormData
	const descTextarea = document.getElementById('description_html');
	if (descTextarea && typeof JBDEditor !== 'undefined' && JBDEditor.get) {
		const editorInst = JBDEditor.get(descTextarea);
		if (editorInst && typeof editorInst.syncToTarget === 'function') {
			editorInst.syncToTarget();
		}
	}

	if (!title) {
		window.adminAlert("Validation Error", "Please provide a project title.", "warning");
		return;
	}
	if (!number) {
		window.adminAlert("Validation Error", "Please provide a project or solicitation number.", "warning");
		return;
	}
	if (!deadline) {
		window.adminAlert("Validation Error", "Please specify a submission deadline.", "warning");
		return;
	}

	const btn = document.getElementById('btnTopSave');
	btn.disabled = true;
	const originalHtml = btn.innerHTML;
	btn.innerHTML = '<span>Saving...</span>';

	const formData = new FormData(form);

	fetch(form.action, {
		method: "POST",
		body: formData,
		headers: { "X-Requested-With": "XMLHttpRequest" }
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		btn.disabled = false;
		btn.innerHTML = originalHtml;
		if (data.success) {
			window.showToast(data.message || "Solicitation saved successfully.", "success");
			if (data.redirectUrl) {
				setTimeout(function() {
					window.location.href = data.redirectUrl;
				}, 600);
			}
		} else {
			window.adminAlert("Save Failed", data.message || "An error occurred.", "error");
		}
	})
	.catch(function(err) {
		btn.disabled = false;
		btn.innerHTML = originalHtml;
		window.adminAlert("Network Error", "Unable to communicate with the server.", "error");
	});
}

// Keyboard Shortcut: Ctrl + S to save
document.addEventListener('keydown', function(e) {
	if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
		e.preventDefault();
		submitSolicitationForm();
	}
});

// =========================================================================
// Addenda Modal & AJAX
// =========================================================================
function openAddendumModal() {
	document.getElementById('addendum_number').value = '';
	document.getElementById('addendum_title').value = '';
	document.getElementById('addendum_desc').value = '';
	document.getElementById('addendum_file_url').value = '';
	document.getElementById('addendumModalBackdrop').style.display = 'block';
	document.getElementById('addendumModal').style.display = 'flex';
}

function closeAddendumModal() {
	document.getElementById('addendumModalBackdrop').style.display = 'none';
	document.getElementById('addendumModal').style.display = 'none';
}

function submitAddendum() {
	const solId = document.getElementById('solicitationId').value;
	const title = document.getElementById('addendum_title').value.trim();
	const num = document.getElementById('addendum_number').value.trim();
	const desc = document.getElementById('addendum_desc').value.trim();
	const fileUrl = document.getElementById('addendum_file_url').value.trim();

	if (!title) {
		window.adminAlert("Validation Error", "Addendum title is required.", "warning");
		return;
	}

	const params = new URLSearchParams({
		solicitation_id: solId,
		title: title,
		addendum_number: num,
		description_html: desc,
		file_url: fileUrl
	});

	fetch("/rfps/addendum/save", {
		method: "POST",
		headers: { "Content-Type": "application/x-www-form-urlencoded" },
		body: params.toString()
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		if (data.success) {
			closeAddendumModal();
			window.showToast(data.message, "success");
			setTimeout(function() { window.location.reload(); }, 600);
		} else {
			window.adminAlert("Error", data.message || "Failed to save addendum.", "error");
		}
	})
	.catch(function(err) {
		window.adminAlert("Error", "Server error while saving addendum.", "error");
	});
}

function deleteAddendum(id) {
	window.adminConfirm("Delete Addendum?", "Are you sure you want to remove this addendum?", function() {
		fetch("/rfps/addendum/delete", {
			method: "POST",
			headers: { "Content-Type": "application/x-www-form-urlencoded" },
			body: "id=" + encodeURIComponent(id)
		})
		.then(function(res) { return res.json(); })
		.then(function(data) {
			if (data.success) {
				window.showToast("Addendum deleted.", "success");
				setTimeout(function() { window.location.reload(); }, 500);
			} else {
				window.adminAlert("Error", data.message || "Could not delete.", "error");
			}
		});
	});
}

// =========================================================================
// Media Library Picker Integration
// =========================================================================
let currentMediaTargetInputId = null;

function openMediaPickerForInput(inputId, titleText) {
	currentMediaTargetInputId = inputId;
	const siteEl = document.getElementById('site_id');
	let dept = siteEl ? siteEl.value : '';
	if (!dept || dept === 'global') {
		const m = document.cookie.match(/(?:^|;\s*)cmsadmin_workspace=([^;]+)/);
		dept = (m && m[1] && m[1] !== 'global') ? decodeURIComponent(m[1]) : 'public-works';
	}
	const iframe = document.getElementById('mediaPickerIframe');
	const modal = document.getElementById('mediaPickerModal');
	const backdrop = document.getElementById('mediaPickerModalBackdrop');
	const title = document.getElementById('mediaPickerTitleText');

	title.innerText = titleText || 'Select Asset from Media Library';
	iframe.src = '/media/picker?ws=' + encodeURIComponent(dept);

	backdrop.style.display = 'block';
	modal.style.display = 'flex';
}

function closeMediaPickerModal() {
	document.getElementById('mediaPickerModalBackdrop').style.display = 'none';
	document.getElementById('mediaPickerModal').style.display = 'none';
	document.getElementById('mediaPickerIframe').src = 'about:blank';
	currentMediaTargetInputId = null;
}

// Listen for PostMessage from Media Picker
window.addEventListener('message', function(e) {
	if (e.data && (e.data.url || e.data.filePath)) {
		const chosenUrl = e.data.url || e.data.filePath;
		if (currentMediaTargetInputId) {
			const target = document.getElementById(currentMediaTargetInputId);
			if (target) {
				target.value = chosenUrl;
				window.showToast("Document linked: " + chosenUrl, "success");
			}
			closeMediaPickerModal();
		}
	}
});

// Sync active workspace from top-header switcher if creating new announcement
window.addEventListener('cmsadmin:workspaceChanged', function(e) {
	const solId = parseInt(document.getElementById('solicitationId').value, 10);
	if (solId === 0 && e && e.detail && e.detail.id && e.detail.id !== 'global') {
		const siteEl = document.getElementById('site_id');
		if (siteEl) {
			siteEl.value = e.detail.id;
		}
	}
});
</script>
