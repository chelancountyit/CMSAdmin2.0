<cfset pageTitle = "Online Form Builder">
<!--- CMS Admin 2.0 - Online Form Builder View --->
<div class="page-header" style="margin-bottom: 1rem;">
	<div>
		<div style="display:flex; align-items:center; gap:0.75rem;">
			<h1 class="page-title" style="margin-bottom:0;">Online Form Builder</h1>
			<span class="badge badge-primary">Interactive Studio</span>
		</div>

		<ol class="breadcrumb" style="margin-top:0.35rem;">
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>"><cfoutput>#svgIcon(name="dashboard", size=14)#</cfoutput> Home</a></li>
			<li class="breadcrumb-item">Content Management</li>
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='forms', action='index')#</cfoutput>">Forms</a></li>
			<li class="breadcrumb-item active">Builder</li>
		</ol>
	</div>

	<div class="page-actions">
		<a href="<cfoutput>#urlFor(controller='forms', action='index')#</cfoutput>" class="btn btn-outline btn-sm">
			<cfoutput>#svgIcon(name="list", size=14)#</cfoutput>
			<span>All Forms</span>
		</a>
		<cfif StructKeyExists(fbConfig, "form") AND IsStruct(fbConfig.form) AND StructKeyExists(fbConfig.form, "dbId") AND Val(fbConfig.form.dbId) GT 0>
			<a href="<cfoutput>#urlFor(controller='forms', action='index', params='viewSubmissions=' & fbConfig.form.dbId)#</cfoutput>" class="btn btn-outline btn-sm" title="View Submitted Responses">
				<cfoutput>#svgIcon(name="inbox", size=14)#</cfoutput>
				<span>View Submissions (<cfoutput>#Val(fbConfig.form.submissionsCount ?: 0)#</cfoutput>)</span>
			</a>
		</cfif>
		<button type="button" class="btn btn-secondary btn-sm" id="btnOpenTemplates">
			<cfoutput>#svgIcon(name="sparkles", size=14)#</cfoutput>
			<span>Templates</span>
		</button>
		<button type="button" class="btn btn-outline btn-sm" id="btnShareEmbed">
			<cfoutput>#svgIcon(name="share-2", size=14)#</cfoutput>
			<span>Share &amp; Embed</span>
		</button>
		<button type="button" class="btn btn-secondary btn-sm" id="btnPreviewForm">
			<cfoutput>#svgIcon(name="play", size=14)#</cfoutput>
			<span>Preview Form</span>
		</button>
		<button type="button" class="btn btn-primary btn-sm" id="btnSaveForm">
			<cfoutput>#svgIcon(name="save", size=15)#</cfoutput>
			<span>Save Form</span>
		</button>
	</div>
</div>

<cfoutput><script>window.CMSAdminFormBuilderConfig = #fbConfigJson#;</script></cfoutput>

<div class="fb-workspace">
	<!--- Topbar Bar: Form Title, Autosave Status & Device Preview Switcher --->
	<div class="fb-topbar">
		<div class="fb-topbar-left">
			<div class="fb-form-info">
				<input type="text" class="fb-form-title-input" id="fbFormTitleInput" value="Untitled Online Form" placeholder="Enter Form Title..." aria-label="Form Title">
				<div class="fb-form-meta">
					<span>Online Public Form</span>
					&bull;
					<span id="fbFormWorkspace" aria-live="polite">Workspace: All Workspaces</span>
					&bull;
					<span class="fb-save-status" id="fbSaveStatus">
						<span class="status-indicator"></span> Ready
					</span>
					&bull;
					<span class="badge badge-success" style="font-size:0.65rem; padding:2px 6px; display:inline-flex; align-items:center; gap:3px;">
						<cfoutput>#svgIcon(name="check", size=10)#</cfoutput> WCAG 2.1 AA
					</span>
					&bull;
					<span class="badge badge-primary" style="font-size:0.65rem; padding:2px 6px; display:inline-flex; align-items:center; gap:3px;">
						<cfoutput>#svgIcon(name="shield", size=10)#</cfoutput> Anti-Spam Active
					</span>
				</div>
			</div>
		</div>

		<!--- Viewport Switcher --->
		<div class="fb-device-switcher" title="Responsive Canvas Viewport">
			<button type="button" class="fb-device-btn active" data-mode="desktop" title="Desktop View (Full Width)">
				<cfoutput>#svgIcon(name="monitor", size=15)#</cfoutput>
			</button>
			<button type="button" class="fb-device-btn" data-mode="tablet" title="Tablet View (680px)">
				<cfoutput>#svgIcon(name="tablet", size=15)#</cfoutput>
			</button>
			<button type="button" class="fb-device-btn" data-mode="mobile" title="Mobile View (400px)">
				<cfoutput>#svgIcon(name="smartphone", size=15)#</cfoutput>
			</button>
		</div>

		<div class="fb-topbar-actions">
			<button type="button" class="btn btn-outline btn-sm" id="btnClearForm" title="Clear all fields and start blank">
				<cfoutput>#svgIcon(name="refresh-cw", size=13)#</cfoutput>
				<span>Reset Canvas</span>
			</button>
		</div>
	</div>

	<!--- Three-Column Form Builder Workspace --->
	<div class="fb-grid">
		<!--- Column 1: Field Palette (Left) --->
		<aside class="fb-panel">
			<div class="fb-panel-header">
				<h2 class="fb-panel-title">
					<cfoutput>#svgIcon(name="layers", size=16)#</cfoutput>
					<span>Form Elements</span>
				</h2>
			</div>

			<div class="fb-panel-body">
				<div class="fb-palette-search">
					<span class="search-icon"><cfoutput>#svgIcon(name="search", size=14)#</cfoutput></span>
					<input type="search" id="fbPaletteSearch" placeholder="Search fields..." aria-label="Search fields">
				</div>

				<!--- Category: Standard Inputs --->
				<div class="fb-palette-section">
					<div class="fb-palette-section-title">Standard Inputs</div>
					<div class="fb-palette-items">
						<div class="fb-palette-item" data-type="text" title="Single-line text input">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="type", size=15)#</cfoutput></span>
							<span>Short Text</span>
						</div>
						<div class="fb-palette-item" data-type="textarea" title="Multi-line comments, descriptions, or detailed responses">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="align-left", size=15)#</cfoutput></span>
							<span>Paragraph (Long Text)</span>
						</div>
						<div class="fb-palette-item" data-type="email" title="Email address with format validation">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="mail", size=15)#</cfoutput></span>
							<span>Email</span>
						</div>
						<div class="fb-palette-item" data-type="phone" title="Phone number input">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="phone", size=15)#</cfoutput></span>
							<span>Phone</span>
						</div>
						<div class="fb-palette-item" data-type="number" title="Numeric value or quantity">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="hash", size=15)#</cfoutput></span>
							<span>Number</span>
						</div>
						<div class="fb-palette-item" data-type="date" title="Calendar date selector">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="calendar", size=15)#</cfoutput></span>
							<span>Date Picker</span>
						</div>
					</div>
				</div>

				<!--- Category: Choices & Options --->
				<div class="fb-palette-section">
					<div class="fb-palette-section-title">Choices &amp; Options</div>
					<div class="fb-palette-items">
						<div class="fb-palette-item" data-type="select" title="Dropdown single select">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="list", size=15)#</cfoutput></span>
							<span>Dropdown</span>
						</div>
						<div class="fb-palette-item" data-type="radio" title="Single choice radio group">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="circle-dot", size=15)#</cfoutput></span>
							<span>Radio Group</span>
						</div>
						<div class="fb-palette-item" data-type="checkbox" title="Multiple choice checkboxes">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="check-square", size=15)#</cfoutput></span>
							<span>Checkboxes</span>
						</div>
						<div class="fb-palette-item" data-type="switch" title="Yes/No or Agreement toggle">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="toggle-right", size=15)#</cfoutput></span>
							<span>Agreement</span>
						</div>
					</div>
				</div>

				<!--- Category: Advanced & Media --->
				<div class="fb-palette-section">
					<div class="fb-palette-section-title">Advanced &amp; Media</div>
					<div class="fb-palette-items">
						<div class="fb-palette-item" data-type="rating" title="1 to 5 star satisfaction rating">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="star", size=15)#</cfoutput></span>
							<span>Star Rating</span>
						</div>
						<div class="fb-palette-item" data-type="file" title="Document or image file attachment">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="upload-cloud", size=15)#</cfoutput></span>
							<span>File Upload</span>
						</div>
						<div class="fb-palette-item" data-type="signature" title="Online digital signature capture">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="pen-tool", size=15)#</cfoutput></span>
							<span>Signature</span>
						</div>
						<div class="fb-palette-item" data-type="address" title="Multi-field street, city, state, zip address">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="map-pin", size=15)#</cfoutput></span>
							<span>Address Block</span>
						</div>
					</div>
				</div>

				<!--- Category: Layout & Structure --->
				<div class="fb-palette-section">
					<div class="fb-palette-section-title">Structure &amp; Instructions</div>
					<div class="fb-palette-items">
						<div class="fb-palette-item" data-type="heading" title="Section title heading">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="type", size=15)#</cfoutput></span>
							<span>Section Title</span>
						</div>
						<div class="fb-palette-item" data-type="paragraph" title="Descriptive instructional text or policy block">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="file-text", size=15)#</cfoutput></span>
							<span>Text / Instructions</span>
						</div>
						<div class="fb-palette-item" data-type="divider" title="Horizontal separator line">
							<span class="fb-palette-icon"><cfoutput>#svgIcon(name="menu", size=15)#</cfoutput></span>
							<span>Divider</span>
						</div>
					</div>
				</div>
			</div>
		</aside>

		<!--- Column 2: Form Canvas Workspace (Center) --->
		<div class="fb-canvas-area">
			<div class="fb-canvas-container" id="fbCanvasContainer">
				<div class="fb-form-card" id="fbFormCard">
					<!--- Canvas Form Header --->
					<div class="fb-form-header">
						<div class="fb-canvas-title" id="fbCanvasTitle" title="Click to edit form title in settings">
							Untitled Online Form
						</div>
						<div class="fb-canvas-desc" id="fbCanvasDesc" title="Click to edit form description in settings">
							Click to add instructions or description for citizens...
						</div>
					</div>

					<!--- Dynamic Fields Canvas Container --->
					<div class="fb-fields-container" id="fbFieldsContainer">
						<!--- Populated dynamically via javascripts/form-builder.js --->
					</div>
				</div>
			</div>
		</div>

		<!--- Column 3: Inspector / Settings Panel (Right) --->
		<aside class="fb-panel">
			<div class="fb-inspector-tabs">
				<button type="button" class="fb-inspector-tab active" data-tab="field">
					Field Settings
				</button>
				<button type="button" class="fb-inspector-tab" data-tab="form">
					Form Settings
				</button>
			</div>

			<div class="fb-panel-body">
				<!--- Field Properties View --->
				<div id="fbFieldPropsPanel">
					<!--- Populated dynamically when a field is selected --->
				</div>

				<!--- Form Settings View --->
				<div id="fbFormPropsPanel" style="display: none;">
					<!--- Form title, theme, submit actions, notification email --->
				</div>
			</div>
		</aside>
	</div>
</div>

<!--- Modal 1: Starter Templates Library --->
<div class="fb-modal-backdrop" id="fbTemplatesModal">
	<div class="fb-modal-dialog modal-lg">
		<div class="fb-modal-header">
			<h3 class="fb-modal-title">
				<cfoutput>#svgIcon(name="sparkles", size=18)#</cfoutput>
				<span>Choose a Starter Form Template</span>
			</h3>
			<button type="button" class="fb-modal-close" data-dismiss="modal" aria-label="Close modal">&times;</button>
		</div>
		<div class="fb-modal-body">
			<p style="color:var(--admin-text-muted); margin-bottom:1.25rem;">
				Select any pre-configured template tailored for county and public agency workflows. You can customize all fields after loading.
			</p>
			<div class="fb-templates-grid">
				<div class="fb-template-card" data-template="contact">
					<div class="fb-template-icon"><cfoutput>#svgIcon(name="mail", size=20)#</cfoutput></div>
					<div class="fb-template-name">General Contact &amp; Inquiry</div>
					<p class="fb-template-desc">Standard public contact form with name, email, department topic selector, and detailed inquiry message.</p>
					<div class="fb-template-fields-count">6 Form Fields &bull; Chelan Blue Theme</div>
				</div>

				<div class="fb-template-card" data-template="survey">
					<div class="fb-template-icon" style="background:var(--admin-success-light); color:var(--admin-success);"><cfoutput>#svgIcon(name="star", size=20)#</cfoutput></div>
					<div class="fb-template-name">Resident Satisfaction Survey</div>
					<p class="fb-template-desc">Community feedback survey featuring star ratings, timeliness rating, comments, and follow-up toggle.</p>
					<div class="fb-template-fields-count">7 Form Fields &bull; Evergreen Theme</div>
				</div>

				<div class="fb-template-card" data-template="permit">
					<div class="fb-template-icon" style="background:var(--admin-warning-light); color:var(--admin-warning);"><cfoutput>#svgIcon(name="file-text", size=20)#</cfoutput></div>
					<div class="fb-template-name">Online Permit &amp; Planning Inquiry</div>
					<p class="fb-template-desc">Department intake form with parcel number, address block, project scope, document upload, and electronic signature.</p>
					<div class="fb-template-fields-count">9 Form Fields &bull; Amber Theme</div>
				</div>

				<div class="fb-template-card" data-template="event">
					<div class="fb-template-icon" style="background:var(--admin-purple-light); color:var(--admin-purple);"><cfoutput>#svgIcon(name="calendar", size=20)#</cfoutput></div>
					<div class="fb-template-name">Workshop &amp; Event RSVP</div>
					<p class="fb-template-desc">Registration form for public hearings and sessions with guest counts, date selections, and accommodation options.</p>
					<div class="fb-template-fields-count">6 Form Fields &bull; Royal Purple Theme</div>
				</div>

				<div class="fb-template-card" data-template="hrm">
					<div class="fb-template-icon" style="background:var(--admin-purple-light); color:var(--admin-purple);"><cfoutput>#svgIcon(name="briefcase", size=20)#</cfoutput></div>
					<div class="fb-template-name">HRM - Employment Application &amp; Intake</div>
					<p class="fb-template-desc">Comprehensive job application with position selection, contact details, work authorization, experience, resume upload, and digital signature.</p>
					<div class="fb-template-fields-count">10 Form Fields &bull; HRM Group &bull; Purple Theme</div>
				</div>

				<div class="fb-template-card" data-template="pio">
					<div class="fb-template-icon" style="background:var(--admin-info-light); color:var(--admin-info);"><cfoutput>#svgIcon(name="megaphone", size=20)#</cfoutput></div>
					<div class="fb-template-name">PIO - Media Inquiry &amp; Press Request</div>
					<p class="fb-template-desc">News media and journalist intake with publication outlet, deadline date/time, inquiry scope, urgency toggle, and communications routing.</p>
					<div class="fb-template-fields-count">7 Form Fields &bull; PIO Group &bull; Chelan Blue Theme</div>
				</div>

				<div class="fb-template-card" data-template="problem">
					<div class="fb-template-icon" style="background:rgba(217,119,6,0.15); color:#d97706;"><cfoutput>#svgIcon(name="alert-triangle", size=20)#</cfoutput></div>
					<div class="fb-template-name">Report a Problem &amp; Service Request</div>
					<p class="fb-template-desc">Citizen issue reporting portal for potholes, road hazards, streetlights, drainage, and park maintenance with photo uploads.</p>
					<div class="fb-template-fields-count">10 Form Fields &bull; Public Works &bull; Amber Theme</div>
				</div>

				<div class="fb-template-card" data-template="infestation">
					<div class="fb-template-icon" style="background:rgba(21,128,61,0.15); color:#15803d;"><cfoutput>#svgIcon(name="bug", size=20)#</cfoutput></div>
					<div class="fb-template-name">Report Infestations &amp; Noxious Weeds</div>
					<p class="fb-template-desc">Landowner and citizen reporting portal for noxious weeds, Apple Maggot, tree borers, land coordinates, and specimen photos.</p>
					<div class="fb-template-fields-count">11 Form Fields &bull; Natural Resources &bull; Green Theme</div>
				</div>
			</div>
		</div>
		<div class="fb-modal-footer">
			<button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
		</div>
	</div>
</div>

<!--- Modal 2: Interactive Live Preview Modal --->
<div class="fb-modal-backdrop" id="fbPreviewModal">
	<div class="fb-modal-dialog modal-lg">
		<div class="fb-modal-header">
			<h3 class="fb-modal-title">
				<cfoutput>#svgIcon(name="play", size=18)#</cfoutput>
				<span>Interactive Form Test &amp; Live Preview</span>
			</h3>
			<button type="button" class="fb-modal-close" data-dismiss="modal" aria-label="Close modal">&times;</button>
		</div>
		<div class="fb-modal-body" id="fbPreviewFormContainer" style="background:var(--admin-bg);">
			<!--- Interactive form loaded dynamically --->
		</div>
		<div class="fb-modal-footer">
			<button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Close Preview</button>
		</div>
	</div>
</div>

<!--- Modal 3: Share, Embed & Export Code Modal --->
<div class="fb-modal-backdrop" id="fbShareModal">
	<div class="fb-modal-dialog">
		<div class="fb-modal-header">
			<h3 class="fb-modal-title">
				<cfoutput>#svgIcon(name="share-2", size=18)#</cfoutput>
				<span>Publish, Embed &amp; Export Form</span>
			</h3>
			<button type="button" class="fb-modal-close" data-dismiss="modal" aria-label="Close modal">&times;</button>
		</div>
		<div class="fb-modal-body">
			<div class="fb-prop-group">
				<label class="fb-prop-label">Direct Public Web Link</label>
				<div style="display:flex; gap:0.5rem;">
					<input type="text" class="fb-prop-input" id="fbDirectLinkInput" readonly>
					<button type="button" class="btn btn-outline btn-sm" id="btnCopyDirectLink">Copy Link</button>
					<a href="#" target="_blank" class="btn btn-secondary btn-sm" id="btnOpenNewTabLink" title="Open preview in new tab">
						<cfoutput>#svgIcon(name="external-link", size=14)#</cfoutput>
					</a>
				</div>
			</div>

			<div class="fb-prop-group" style="margin-top:1.25rem;">
				<div class="fb-code-card">
					<div class="fb-code-card-header">
						<div class="fb-code-card-title">
							<cfoutput>#svgIcon(name="code", size=14)#</cfoutput>
							<span>Responsive iFrame Embed Code</span>
						</div>
						<button type="button" class="fb-copy-code-btn" id="btnCopyEmbedCode" title="Copy iFrame Embed Code">
							<cfoutput>#svgIcon(name="copy", size=13)#</cfoutput>
							<span>Copy Embed Code</span>
						</button>
					</div>
					<div class="fb-code-box">
						<code id="fbEmbedCode"></code>
					</div>
				</div>
			</div>

			<div class="fb-prop-group" style="margin-top:1.5rem; padding-top:1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; gap:0.75rem; flex-wrap:wrap;">
				<button type="button" class="btn btn-outline btn-sm" id="btnDownloadHTML">
					<cfoutput>#svgIcon(name="download", size=14)#</cfoutput>
					<span>Download Standalone HTML</span>
				</button>
				<button type="button" class="btn btn-outline btn-sm" id="btnExportJSON">
					<cfoutput>#svgIcon(name="code", size=14)#</cfoutput>
					<span>Export Form JSON Schema</span>
				</button>
			</div>
		</div>
		<div class="fb-modal-footer">
			<button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Done</button>
		</div>
	</div>
</div>
