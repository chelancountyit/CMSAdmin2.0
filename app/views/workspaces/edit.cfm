<cfset pageTitle = "Edit Workspace: " & variables.workspace.site_name>
<cfparam name="variables.departmentCategories" default="#[]#">
<cfparam name="variables.workspace" default="#{}#">

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.25rem; flex-wrap:wrap;">
			<h1 class="page-title" style="margin:0;">Edit Workspace: #EncodeForHTML(variables.workspace.site_name)#</h1>
			<cfif variables.workspace.type eq "site">
				<span class="badge" style="background:rgba(16,185,129,0.1); color:##047857; border:1px solid rgba(16,185,129,0.25); font-size:0.72rem; padding:0.18rem 0.55rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
					#svgIcon(name="globe", size=11)# Site / Portal
				</span>
			<cfelseif variables.workspace.type eq "dept">
				<span class="badge" style="background:rgba(126,34,206,0.1); color:##7e22ce; border:1px solid rgba(126,34,206,0.25); font-size:0.72rem; padding:0.18rem 0.55rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
					#svgIcon(name="building", size=11)# Department
				</span>
			<cfelse>
				<span class="badge badge-neutral" style="font-size:0.72rem; padding:0.18rem 0.55rem; border-radius:9999px; display:inline-flex; align-items:center; gap:0.25rem;">
					#svgIcon(name="grid", size=11)# Global
				</span>
			</cfif>
			<span class="badge badge-danger" style="font-size:0.75rem; padding:0.2rem 0.55rem;">Admin Only</span>
			<code style="background:var(--admin-surface-hover); border:1px solid var(--admin-border); padding:0.2rem 0.5rem; border-radius:var(--radius-sm); font-size:0.78rem;">#EncodeForHTML(variables.workspace.id)#</code>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Administration</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='workspaces', action='index')#">Workspaces</a></li>
				<li class="breadcrumb-item active" aria-current="page">Edit Workspace</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions">
		<a href="#urlFor(controller='workspaces', action='index')#" class="btn btn-secondary btn-sm">
			#svgIcon(name="chevron-left", size=14)#
			<span>Back to Workspace Directory</span>
		</a>
	</div>
</div>

<style>
.ws-form-grid {
	display: grid;
	grid-template-columns: repeat(12, 1fr);
	gap: 1.5rem;
	align-items: stretch;
}
.col-6 {
	grid-column: span 6;
	display: flex;
	flex-direction: column;
}
.col-12 {
	grid-column: span 12;
}
@media (max-width: 992px) {
	.col-6 {
		grid-column: span 12 !important;
	}
}
.admin-card {
	background: var(--admin-surface);
	border: 1px solid var(--admin-border);
	border-radius: var(--radius-md);
	box-shadow: var(--shadow-sm);
	overflow: hidden;
	display: flex;
	flex-direction: column;
	height: 100%;
}
.card-header {
	padding: 1rem 1.25rem;
	background: var(--admin-surface-hover);
	border-bottom: 1px solid var(--admin-border);
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 0.75rem;
}
.card-body {
	padding: 1.25rem 1.35rem;
	flex: 1;
	display: flex;
	flex-direction: column;
	gap: 1rem;
}
.ws-form-label {
	display: block;
	font-size: 0.825rem;
	font-weight: 600;
	color: var(--admin-text-main);
	margin-bottom: 0.35rem;
}
.ws-grid-2 {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 1rem;
}
.ws-grid-3 {
	display: grid;
	grid-template-columns: 2fr 1fr 1fr;
	gap: 0.75rem;
}
@media (max-width: 576px) {
	.ws-grid-2, .ws-grid-3 {
		grid-template-columns: 1fr;
	}
}
.ws-type-selector-card:has(input:checked) {
	border-color: var(--admin-primary) !important;
	background: rgba(0, 115, 170, 0.04) !important;
	box-shadow: 0 0 0 1px var(--admin-primary);
}
@media (max-width: 768px) {
	.ws-contact-location-grid,
	.ws-leadership-type-grid,
	.ws-location-hours-grid {
		grid-template-columns: 1fr !important;
	}
}
</style>

<form action="#urlFor(controller='workspaces', action='update')#" method="post" class="workspace-form">
	#authenticityTokenField()#
	<input type="hidden" name="id" value="#EncodeForHTMLAttribute(variables.workspace.id)#">

	<div class="ws-form-grid">
		<!--- PANEL 1 (12-col): SITE & DIRECTORY CONFIGURATION --->
		<div class="admin-card col-12">
			<div class="card-header">
				<div style="display:flex; align-items:center; gap:0.5rem;">
					<div style="width:30px; height:30px; border-radius:var(--radius-sm); background:rgba(0,115,170,0.1); color:var(--admin-primary); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
						#svgIcon(name="settings", size=16)#
					</div>
					<div>
						<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main);">Site &amp; Directory Configuration</h2>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.1rem;">Define site identity, IIS virtual folder mapping, and public routing.</div>
					</div>
				</div>
				<span class="badge badge-info" style="font-size:0.7rem; padding:0.2rem 0.5rem;">Routing</span>
			</div>
			<div class="card-body">
				<div>
					<label class="ws-form-label">Classification / Marker <span style="color:var(--admin-danger);">*</span></label>
					<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.75rem;">
						<label class="ws-type-selector-card" style="border:1.5px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.75rem 0.85rem; display:flex; align-items:flex-start; gap:0.6rem; cursor:pointer; background:var(--admin-surface); transition:all 0.15s ease;">
							<input type="radio" name="type" value="dept" <cfif variables.workspace.type eq "dept" or !len(variables.workspace.type)>checked</cfif> style="margin-top:0.25rem;">
							<div>
								<div style="font-weight:700; font-size:0.85rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.35rem;">
									<span style="color:##7e22ce;">#svgIcon(name="building", size=14)#</span>
									<span>Department</span>
								</div>
								<div style="font-size:0.73rem; color:var(--admin-text-muted); margin-top:0.2rem; line-height:1.35;">
									Municipal department, elected office, or administrative division.
								</div>
							</div>
						</label>
						<label class="ws-type-selector-card" style="border:1.5px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.75rem 0.85rem; display:flex; align-items:flex-start; gap:0.6rem; cursor:pointer; background:var(--admin-surface); transition:all 0.15s ease;">
							<input type="radio" name="type" value="site" <cfif variables.workspace.type eq "site">checked</cfif> style="margin-top:0.25rem;">
							<div>
								<div style="font-weight:700; font-size:0.85rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.35rem;">
									<span style="color:##047857;">#svgIcon(name="globe", size=14)#</span>
									<span>Site / Portal</span>
								</div>
								<div style="font-size:0.73rem; color:var(--admin-text-muted); margin-top:0.2rem; line-height:1.35;">
									Public-facing web portal, community microsite, or external service.
								</div>
							</div>
						</label>
					</div>
				</div>

				<div>
					<label for="site_name" class="ws-form-label">Site Name <span style="color:var(--admin-danger);">*</span></label>
					<input type="text" id="site_name" name="site_name" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.site_name)#" required autocomplete="off">
				</div>

				<div class="ws-grid-2">
					<div>
						<label for="virtual_directory" class="ws-form-label">Virtual Directory <span style="color:var(--admin-danger);">*</span></label>
						<input type="text" id="virtual_directory" name="virtual_directory" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.virtual_directory)#" required autocomplete="off">
						<small style="color:var(--admin-text-muted); font-size:0.73rem; display:block; margin-top:0.25rem;">
							IIS virtual folder mapping
						</small>
					</div>
					<div>
						<label for="domain_name" class="ws-form-label">Domain Name</label>
						<input type="text" id="domain_name" name="domain_name" class="form-control" placeholder="e.g. www.chelancounty.gov" autocomplete="off" value="#EncodeForHTMLAttribute(variables.workspace.domain_name ?: 'www.chelancounty.gov')#">
						<small style="color:var(--admin-text-muted); font-size:0.73rem; display:block; margin-top:0.25rem;">
							Canonical web hostname
						</small>
					</div>
				</div>

				<div class="ws-grid-2">
					<div>
						<label for="storage_path" class="ws-form-label">Storage Path</label>
						<input type="text" id="storage_path" name="storage_path" class="form-control" placeholder="files/[virtual-directory]" autocomplete="off" value="#EncodeForHTMLAttribute(variables.workspace.storage_path ?: ('files/' & variables.workspace.virtual_directory))#">
						<small style="color:var(--admin-text-muted); font-size:0.73rem; display:block; margin-top:0.25rem;">
							File repository path for media &amp; documents
						</small>
					</div>
					<div>
						<label for="project_path" class="ws-form-label">Project Path</label>
						<input type="text" id="project_path" name="project_path" class="form-control" placeholder="C:\inetpub\chelan-county" autocomplete="off" value="#EncodeForHTMLAttribute(variables.workspace.project_path ?: 'C:\inetpub\chelan-county')#">
						<small style="color:var(--admin-text-muted); font-size:0.73rem; display:block; margin-top:0.25rem;">
							Server application codebase directory
						</small>
					</div>
				</div>

				<div class="ws-grid-2">
					<div>
						<label for="department" class="ws-form-label">Department</label>
						<input type="text" id="department" name="department" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.department)#" autocomplete="off">
					</div>
					<div>
						<label for="department_category" class="ws-form-label">Department Category</label>
						<select id="department_category" name="department_category" class="form-control">
							<option value="">Select Category (if applicable)</option>
							<cfloop array="#variables.departmentCategories#" index="local.cat">
								<option value="#EncodeForHTMLAttribute(local.cat)#" <cfif variables.workspace.department_category eq local.cat>selected</cfif>>#EncodeForHTML(local.cat)#</option>
							</cfloop>
						</select>
					</div>
				</div>

				<div>
					<label for="redirect_url" class="ws-form-label">Custom Redirect URL</label>
					<input type="text" id="redirect_url" name="redirect_url" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.redirect_url)#" placeholder="https://www.chelancounty.gov/..." autocomplete="off">
				</div>

				<!--- Workspace Theme & Brand Accent Color Picker --->
				<div style="background:var(--admin-surface-hover); border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:1rem; margin-top:0.25rem;">
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.75rem; flex-wrap:wrap; gap:0.5rem;">
						<div>
							<label for="wsColorPicker" class="ws-form-label" style="margin:0; display:flex; align-items:center; gap:0.4rem;">
								<span>Theme &amp; Brand Accent Color</span>
							</label>
							<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.15rem;">
								Assigned palette for badges, workspace selector pill, icons, and visual cards.
							</div>
						</div>
						<!--- Live Preview Badge --->
						<div id="wsColorLivePreview" style="display:inline-flex; align-items:center; gap:0.35rem; padding:0.25rem 0.65rem; border-radius:9999px; font-size:0.75rem; font-weight:700; border:1px solid; transition:all 0.15s ease;">
							<span id="wsColorPreviewIcon" style="display:inline-flex;">
								<cfif variables.workspace.type eq "site">
									#svgIcon(name="globe", size=12)#
								<cfelseif variables.workspace.type eq "dept">
									#svgIcon(name="building", size=12)#
								<cfelse>
									#svgIcon(name="grid", size=12)#
								</cfif>
							</span>
							<span id="wsColorPreviewText">#EncodeForHTML(Len(variables.workspace.site_name) ? variables.workspace.site_name : 'Preview')#</span>
						</div>
					</div>

					<div style="display:flex; align-items:center; gap:0.75rem; flex-wrap:wrap;">
						<!--- Native Color Picker Clickable Swatch --->
						<div style="position:relative; display:inline-flex; align-items:center;" title="Click to open color picker">
							<input type="color" id="wsColorPicker" value="#EncodeForHTMLAttribute(variables.workspace.color)#" style="position:absolute; opacity:0; width:38px; height:38px; cursor:pointer; left:0; top:0; z-index:2;" title="Choose Custom Color">
							<div id="wsColorSwatch" style="width:38px; height:38px; border-radius:var(--radius-sm); border:2px solid var(--admin-border); background-color:#EncodeForHTMLAttribute(variables.workspace.color)#; cursor:pointer; box-shadow:var(--shadow-sm); display:flex; align-items:center; justify-content:center; transition:transform 0.15s ease;" title="Click to open color picker">
							</div>
						</div>

						<!--- Hex Code Input Field --->
						<div style="display:inline-flex; align-items:center; position:relative; width:135px;">
							<span style="position:absolute; left:0.65rem; color:var(--admin-text-muted); font-size:0.85rem; font-weight:700; pointer-events:none;">##</span>
							<input type="text" id="wsColorHex" name="color" class="form-control" value="#EncodeForHTMLAttribute(Replace(variables.workspace.color, '##', '', 'all'))#" maxlength="7" placeholder="0073AA" style="padding-left:1.6rem; font-family:monospace; font-weight:700; text-transform:uppercase; font-size:0.85rem;" autocomplete="off" required>
						</div>

						<!--- Quick Preset Color Chips --->
						<div style="display:flex; align-items:center; gap:0.4rem; flex-wrap:wrap; flex:1; min-width:200px;">
							<button type="button" class="ws-color-preset" data-color="##004879" title="Chelan Navy (##004879)" style="width:24px; height:24px; border-radius:50%; background:##004879; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##0073aa" title="Ocean Blue (##0073aa)" style="width:24px; height:24px; border-radius:50%; background:##0073aa; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##0284c7" title="Sky Blue (##0284c7)" style="width:24px; height:24px; border-radius:50%; background:##0284c7; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##0f766e" title="Deep Teal (##0f766e)" style="width:24px; height:24px; border-radius:50%; background:##0f766e; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##047857" title="Forest Green (##047857)" style="width:24px; height:24px; border-radius:50%; background:##047857; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##10b981" title="Emerald (##10b981)" style="width:24px; height:24px; border-radius:50%; background:##10b981; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##7e22ce" title="County Purple (##7e22ce)" style="width:24px; height:24px; border-radius:50%; background:##7e22ce; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##6366f1" title="Indigo (##6366f1)" style="width:24px; height:24px; border-radius:50%; background:##6366f1; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##d97706" title="Amber Gold (##d97706)" style="width:24px; height:24px; border-radius:50%; background:##d97706; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##dc2626" title="Crimson (##dc2626)" style="width:24px; height:24px; border-radius:50%; background:##dc2626; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##be185d" title="Rose Berry (##be185d)" style="width:24px; height:24px; border-radius:50%; background:##be185d; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
							<button type="button" class="ws-color-preset" data-color="##475569" title="Slate (##475569)" style="width:24px; height:24px; border-radius:50%; background:##475569; border:2px solid ##fff; outline:1px solid var(--admin-border); cursor:pointer; padding:0; transition:transform 0.15s ease;"></button>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!--- PANEL 2 (12-col): CONTACT INFORMATION, PHYSICAL LOCATION & OPERATING HOURS (MERGED) --->
		<div class="admin-card col-12">
			<div class="card-header">
				<div style="display:flex; align-items:center; gap:0.5rem;">
					<div style="width:30px; height:30px; border-radius:var(--radius-sm); background:rgba(126,34,206,0.1); color:var(--admin-purple, ##7e22ce); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
						#svgIcon(name="user", size=16)#
					</div>
					<div>
						<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main);">Contact Information, Location &amp; Operating Hours</h2>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.1rem;">Department leadership, primary contact, physical facility address, and public operating schedule.</div>
					</div>
				</div>
				<span class="badge badge-purple" style="font-size:0.7rem; padding:0.2rem 0.5rem;">Communications &amp; Facility</span>
			</div>
			<div class="card-body">
				<!--- Leadership Classification: Elected Official vs Department Head --->
				<div>
					<label class="ws-form-label">Leadership Classification <span style="color:var(--admin-danger);">*</span></label>
					<div style="display:grid; grid-template-columns:1fr 1fr; gap:0.75rem;" class="ws-leadership-type-grid">
						<label class="ws-type-selector-card" style="border:1.5px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.75rem 0.85rem; display:flex; align-items:flex-start; gap:0.6rem; cursor:pointer; background:var(--admin-surface); transition:all 0.15s ease;">
							<input type="radio" name="leadership_type" value="dept_head" <cfif (variables.workspace.leadership_type ?: 'dept_head') neq "elected">checked</cfif> style="margin-top:0.25rem;">
							<div>
								<div style="font-weight:700; font-size:0.85rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.35rem;">
									<span style="color:var(--admin-primary);">#svgIcon(name="briefcase", size=14)#</span>
									<span>Department Head</span>
								</div>
								<div style="font-size:0.73rem; color:var(--admin-text-muted); margin-top:0.2rem; line-height:1.35;">
									Appointed Director, Administrator, Division Chief, or Program Manager.
								</div>
							</div>
						</label>
						<label class="ws-type-selector-card" style="border:1.5px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.75rem 0.85rem; display:flex; align-items:flex-start; gap:0.6rem; cursor:pointer; background:var(--admin-surface); transition:all 0.15s ease;">
							<input type="radio" name="leadership_type" value="elected" <cfif (variables.workspace.leadership_type ?: '') eq "elected">checked</cfif> style="margin-top:0.25rem;">
							<div>
								<div style="font-weight:700; font-size:0.85rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.35rem;">
									<span style="color:##d97706;">#svgIcon(name="award", size=14)#</span>
									<span>Elected Official</span>
								</div>
								<div style="font-size:0.73rem; color:var(--admin-text-muted); margin-top:0.2rem; line-height:1.35;">
									Countywide elected official (Assessor, Auditor, Clerk, Commissioner, Coroner, Prosecutor, Sheriff, Treasurer).
								</div>
							</div>
						</label>
					</div>
				</div>

				<!--- Side-by-Side: Contact Details (Left) and Location & Hours (Right) --->
				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1.5rem; margin-top:0.5rem; padding-top:1rem; border-top:1px solid var(--admin-border);" class="ws-contact-location-grid">
					<!--- LEFT COLUMN: Contact Information --->
					<div style="display:flex; flex-direction:column; gap:1rem;">
						<div style="font-size:0.8rem; font-weight:700; color:var(--admin-text-subtle); text-transform:uppercase; letter-spacing:0.04em; display:flex; align-items:center; gap:0.4rem;">
							#svgIcon(name="user", size=13)#
							<span>Department Leadership &amp; Official Contact</span>
						</div>

						<!--- Leadership / Contact Profile Photo Selector (200x200) --->
						<div style="background:var(--admin-surface-hover); border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:1.25rem; display:flex; flex-direction:column; align-items:center; gap:1rem;">
							<div style="width:100%; display:flex; align-items:center; justify-content:space-between;">
								<label for="contact_photo" class="ws-form-label" style="margin:0; font-size:0.85rem; font-weight:700; display:flex; align-items:center; gap:0.4rem;">
									#svgIcon(name="image", size=14)#
									<span>Profile Photo (200 &times; 200)</span>
								</label>
								<span class="badge badge-neutral" style="font-size:0.68rem; padding:0.12rem 0.45rem;">200 &times; 200 px</span>
							</div>

							<!--- 200x200 Circular Avatar Preview with Hover Trigger --->
							<div id="contactPhotoPreviewWrap"
							     role="button"
							     tabindex="0"
							     aria-label="Click to browse workspace media library for leadership profile photo"
							     onclick="openMediaPickerForContactPhoto()"
							     onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();openMediaPickerForContactPhoto();}"
							     style="width:200px; height:200px; border-radius:50%; border:3px #(Len(Trim(variables.workspace.contact_photo ?: '')) ? 'solid' : 'dashed')# var(--admin-border); display:flex; align-items:center; justify-content:center; overflow:hidden; background:var(--admin-surface); cursor:pointer; flex-shrink:0; position:relative; transition:all 0.2s ease; box-shadow:var(--shadow-sm);"
							     onmouseenter="this.style.borderColor='var(--admin-primary)'; this.style.transform='scale(1.02)';"
							     onmouseleave="this.style.borderColor='var(--admin-border)'; this.style.transform='scale(1)';"
							     title="Click to select or change 200x200 profile photo">
								<img id="contactPhotoImg" 
								     src="#EncodeForHTMLAttribute(variables.workspace.contact_photo ?: '')#" 
								     alt="Profile photo preview" 
								     style="width:100%; height:100%; object-fit:cover; display:#(Len(Trim(variables.workspace.contact_photo ?: '')) ? 'block' : 'none')#;" 
								     onerror="this.style.display='none'; document.getElementById('contactPhotoPlaceholder').style.display='flex';" />
								<div id="contactPhotoPlaceholder" style="color:var(--admin-text-muted); display:#(Len(Trim(variables.workspace.contact_photo ?: '')) ? 'none' : 'flex')#; flex-direction:column; align-items:center; justify-content:center; text-align:center; padding:1rem;">
									<div style="width:48px; height:48px; border-radius:50%; background:var(--admin-surface-hover); display:flex; align-items:center; justify-content:center; margin-bottom:0.5rem; color:var(--admin-text-muted);">
										#svgIcon(name="user", size=28)#
									</div>
									<span style="font-size:0.85rem; font-weight:700; color:var(--admin-text-main);">Choose Photo</span>
									<span style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:2px;">Click to browse 200 &times; 200</span>
								</div>
							</div>

							<!--- Controls & Input --->
							<div style="width:100%;">
								<div style="display:flex; gap:0.4rem; align-items:center;">
									<input type="text" id="contact_photo" name="contact_photo" class="form-control" style="font-size:0.82rem; height:36px;" value="#EncodeForHTMLAttribute(variables.workspace.contact_photo ?: '')#" placeholder="/files/[workspace]/images/photo.jpg" oninput="updateContactPhotoPreview(this.value)" autocomplete="off">
									<button type="button" class="btn btn-outline-secondary btn-sm" onclick="openMediaPickerForContactPhoto()" title="Browse Media Library" style="display:inline-flex; align-items:center; gap:0.35rem; white-space:nowrap; height:36px; padding:0 0.85rem; font-weight:600;">
										#svgIcon(name="folder", size=14)#
										<span>Browse</span>
									</button>
									<button type="button" id="btnRemoveContactPhoto" class="btn btn-outline-danger btn-sm" onclick="removeContactPhoto()" title="Remove profile photo" style="display:#(Len(Trim(variables.workspace.contact_photo ?: '')) ? 'inline-flex' : 'none')#; align-items:center; gap:0.25rem; white-space:nowrap; height:36px; padding:0 0.65rem;">
										#svgIcon(name="trash", size=13)#
									</button>
								</div>
								<div style="font-size:0.73rem; color:var(--admin-text-muted); margin-top:0.35rem; display:flex; justify-content:space-between; align-items:center;">
									<span>Recommended size: 200 &times; 200 px headshot portrait.</span>
									<button type="button" onclick="openMediaPickerForContactPhoto()" style="background:none; border:none; color:var(--admin-primary); cursor:pointer; font-size:0.73rem; font-weight:600; padding:0; display:inline-flex; align-items:center; gap:0.25rem;">
										<span>Media Library</span>
										&rarr;
									</button>
								</div>
							</div>
						</div>

						<!--- Job Title --->
						<div>
							<label for="job_title" class="ws-form-label">Job Title</label>
							<input type="text" id="job_title" name="job_title" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.job_title ?: '')#" placeholder="e.g. County Assessor or Director of Community Development" autocomplete="off">
							<small style="color:var(--admin-text-muted); font-size:0.73rem; display:block; margin-top:0.25rem;">
								Official title or municipal role displayed on citizen directories and page headers
							</small>
						</div>

						<div class="ws-grid-2">
							<div>
								<label for="contact_first_name" class="ws-form-label">First Name</label>
								<input type="text" id="contact_first_name" name="contact_first_name" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.contact_first_name)#" placeholder="e.g. Deanna" autocomplete="off">
							</div>
							<div>
								<label for="contact_last_name" class="ws-form-label">Last Name</label>
								<input type="text" id="contact_last_name" name="contact_last_name" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.contact_last_name)#" placeholder="e.g. Walter" autocomplete="off">
							</div>
						</div>

						<div>
							<label for="contact_email" class="ws-form-label">Official Email</label>
							<input type="email" id="contact_email" name="contact_email" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.contact_email)#" placeholder="e.g. contact@chelancounty.gov" autocomplete="off">
						</div>

						<div class="ws-grid-2">
							<div>
								<label for="contact_phone" class="ws-form-label">Phone</label>
								<input type="tel" id="contact_phone" name="contact_phone" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.contact_phone)#" placeholder="e.g. 509-667-6800" autocomplete="off">
							</div>
							<div>
								<label for="contact_fax" class="ws-form-label">Fax</label>
								<input type="tel" id="contact_fax" name="contact_fax" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.contact_fax)#" placeholder="e.g. 509-667-6860" autocomplete="off">
							</div>
						</div>
					</div>

					<!--- RIGHT COLUMN: Physical Location & Operating Hours --->
					<div style="display:flex; flex-direction:column; gap:1rem;">
						<div style="font-size:0.8rem; font-weight:700; color:var(--admin-text-subtle); text-transform:uppercase; letter-spacing:0.04em; display:flex; align-items:center; gap:0.4rem;">
							#svgIcon(name="map-pin", size=13)#
							<span>Facility Physical Address &amp; Operating Hours</span>
						</div>

						<div>
							<label for="address" class="ws-form-label">Street Address</label>
							<input type="text" id="address" name="address" class="form-control" placeholder="Please enter address (e.g. 350 Orondo Ave)" value="#EncodeForHTMLAttribute(variables.workspace.address)#" autocomplete="off">
							<input type="text" id="address2" name="address2" class="form-control" placeholder="Suite, unit, floor, or building (optional)" value="#EncodeForHTMLAttribute(variables.workspace.address2)#" style="margin-top:0.5rem;" autocomplete="off">
						</div>

						<div class="ws-grid-3">
							<div>
								<label for="city" class="ws-form-label">City</label>
								<input type="text" id="city" name="city" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.city)#" autocomplete="off">
							</div>
							<div>
								<label for="state" class="ws-form-label">State</label>
								<input type="text" id="state" name="state" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.state)#" autocomplete="off">
							</div>
							<div>
								<label for="zip" class="ws-form-label">Zip</label>
								<input type="text" id="zip" name="zip" class="form-control" value="#EncodeForHTMLAttribute(variables.workspace.zip)#" autocomplete="off">
							</div>
						</div>

						<div>
							<label for="office_hours" class="ws-form-label">Office Hours &amp; Schedule</label>
							<textarea id="office_hours" name="office_hours" class="form-control" rows="3" placeholder="Please enter Office Hours (e.g. Monday - Friday: 8:00 AM - 5:00 PM)">#EncodeForHTML(variables.workspace.office_hours)#</textarea>
						</div>

						<div style="background:var(--admin-surface-hover); border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.65rem 0.8rem; font-size:0.76rem; color:var(--admin-text-muted); display:flex; align-items:flex-start; gap:0.5rem;">
							<span style="color:var(--admin-primary); margin-top:1px;">#svgIcon(name="info", size=14)#</span>
							<span>These leadership details, operating hours, and facility coordinates will be published on public portal headers, citizen directories, and staff listings.</span>
						</div>
					</div>
				</div>
			</div>
			<div class="card-footer" style="padding:1rem 1.25rem; background:var(--admin-bg); border-top:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; min-height:57px; box-sizing:border-box;">
				<div style="display:flex; gap:0.5rem; align-items:center;">
					<a href="#urlFor(controller='workspaces', action='index')#" class="btn btn-secondary btn-sm">Cancel</a>
					<cfif variables.workspace.id neq "global" and (!structKeyExists(variables.workspace, "is_system") or !variables.workspace.is_system)>
						<a href="#urlFor(controller='workspaces', action='delete', params='id=' & variables.workspace.id)#" class="btn btn-outline-danger btn-sm" data-confirm="Are you sure you want to delete workspace '#EncodeForHTMLAttribute(variables.workspace.site_name)#'?" data-confirm-title="Delete workspace?" data-confirm-accept="Delete">
							#svgIcon(name="trash", size=13)#
							<span>Delete Workspace</span>
						</a>
					</cfif>
				</div>
				<button type="submit" class="btn btn-primary btn-sm">
					#svgIcon(name="save", size=15)#
					<span>Save Workspace Changes</span>
				</button>
			</div>
		</div>
	</div>
</form>
</cfoutput>

<script>
document.addEventListener("DOMContentLoaded", function() {
	var picker = document.getElementById("wsColorPicker");
	var hexInput = document.getElementById("wsColorHex");
	var swatch = document.getElementById("wsColorSwatch");
	var preview = document.getElementById("wsColorLivePreview");
	var presets = document.querySelectorAll(".ws-color-preset");
	var siteNameInput = document.getElementById("site_name");
	var previewText = document.getElementById("wsColorPreviewText");

	function hexToRgba(hex, alpha) {
		hex = hex.replace("#", "");
		if (hex.length === 3) {
			hex = hex.split("").map(function(c) { return c + c; }).join("");
		}
		var r = parseInt(hex.substring(0, 2), 16) || 0;
		var g = parseInt(hex.substring(2, 4), 16) || 0;
		var b = parseInt(hex.substring(4, 6), 16) || 0;
		return "rgba(" + r + ", " + g + ", " + b + ", " + alpha + ")";
	}

	function applyColor(hex) {
		if (!hex) return;
		if (hex.charAt(0) !== "#") hex = "#" + hex;
		if (!/^#[0-9A-Fa-f]{3,6}$/.test(hex)) return;

		var normHex = hex.length === 4
			? "#" + hex.charAt(1) + hex.charAt(1) + hex.charAt(2) + hex.charAt(2) + hex.charAt(3) + hex.charAt(3)
			: hex;

		if (picker) picker.value = normHex;
		if (hexInput) hexInput.value = hex.replace("#", "").toUpperCase();
		if (swatch) swatch.style.backgroundColor = normHex;

		if (preview) {
			preview.style.color = normHex;
			preview.style.backgroundColor = hexToRgba(normHex, 0.12);
			preview.style.borderColor = hexToRgba(normHex, 0.35);
		}

		presets.forEach(function(btn) {
			var btnColor = (btn.getAttribute("data-color") || "").toLowerCase();
			if (btnColor === normHex.toLowerCase()) {
				btn.style.transform = "scale(1.3)";
				btn.style.outline = "2px solid var(--admin-primary)";
			} else {
				btn.style.transform = "scale(1)";
				btn.style.outline = "1px solid var(--admin-border)";
			}
		});
	}

	if (picker) {
		picker.addEventListener("input", function(e) {
			applyColor(e.target.value);
		});
		picker.addEventListener("change", function(e) {
			applyColor(e.target.value);
		});
	}

	if (swatch && picker) {
		swatch.addEventListener("click", function() {
			picker.click();
		});
	}

	if (hexInput) {
		hexInput.addEventListener("input", function(e) {
			var val = e.target.value.trim().replace("#", "");
			if (val.length === 3 || val.length === 6) {
				applyColor("#" + val);
			}
		});
		hexInput.addEventListener("blur", function(e) {
			var val = e.target.value.trim().replace("#", "");
			if (val.length > 0) {
				applyColor("#" + val);
			}
		});
	}

	presets.forEach(function(btn) {
		btn.addEventListener("click", function() {
			applyColor(this.getAttribute("data-color"));
		});
	});

	if (siteNameInput && previewText) {
		siteNameInput.addEventListener("input", function(e) {
			previewText.textContent = e.target.value.trim() || "Preview";
		});
	}

	// Initialize with current color
	var initialVal = (hexInput && hexInput.value.trim()) ? hexInput.value.trim() : "0073AA";
	applyColor("#" + initialVal);
});
</script>

<!--- Media Picker Modal Overlay for Workspaces --->
<cfoutput>
<div class="admin-modal-backdrop" id="mediaPickerModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeMediaPickerModal()"></div>
<div class="admin-modal" id="mediaPickerModal" role="dialog" aria-modal="true" aria-labelledby="mediaPickerModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:94vw; max-width:1300px; height:85vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg, ##f8fafc);">
		<h2 class="modal-title" id="mediaPickerModalTitle" style="margin:0; font-size:1.05rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
			#svgIcon(name="image", size=18)#
			<span id="mediaPickerTitleText">Select Leadership Profile Photo</span>
		</h2>
		<div style="display:flex; align-items:center; gap:0.5rem;">
			<button type="button" class="btn btn-outline-primary btn-sm" onclick="triggerMediaPickerUpload()" style="display:inline-flex; align-items:center; gap:0.35rem;" title="Upload new media asset to repository">
				#svgIcon(name="upload", size=14)#
				<span>Upload New File</span>
			</button>
			<button type="button" class="btn btn-secondary btn-sm" onclick="closeMediaPickerModal()" aria-label="Close Media Picker" id="btnCloseMediaPicker">
				#svgIcon(name="x", size=16)#
			</button>
		</div>
	</div>
	<div style="flex:1; width:100%; height:calc(100% - 60px); position:relative;">
		<iframe id="mediaPickerIframe" src="about:blank" style="width:100%; height:100%; border:none;" title="Media Asset Picker"></iframe>
	</div>
</div>
</cfoutput>

<script>
window.updateContactPhotoPreview = function(url) {
	url = (url || '').trim();
	var img = document.getElementById('contactPhotoImg');
	var placeholder = document.getElementById('contactPhotoPlaceholder');
	var btnRemove = document.getElementById('btnRemoveContactPhoto');
	var wrap = document.getElementById('contactPhotoPreviewWrap');
	if (url.length > 0) {
		if (img) {
			img.src = url;
			img.style.display = 'block';
		}
		if (placeholder) placeholder.style.display = 'none';
		if (btnRemove) btnRemove.style.display = 'inline-flex';
		if (wrap) wrap.style.borderStyle = 'solid';
	} else {
		if (img) {
			img.src = '';
			img.style.display = 'none';
		}
		if (placeholder) placeholder.style.display = 'flex';
		if (btnRemove) btnRemove.style.display = 'none';
		if (wrap) wrap.style.borderStyle = 'dashed';
	}
};

window.removeContactPhoto = function() {
	var input = document.getElementById('contact_photo');
	if (input) input.value = '';
	updateContactPhotoPreview('');
	if (typeof window.showToast === 'function') {
		window.showToast('Profile photo removed.', 'info');
	}
};

window.openMediaPickerForContactPhoto = function() {
	var vDir = (document.getElementById('virtual_directory') ? document.getElementById('virtual_directory').value.trim() : '') || 'global';
	window.openMediaPicker('image', {
		workspace: vDir,
		folder: 'images',
		title: 'Select Leadership Profile Photo',
		onSelect: function(payload) {
			if (!payload) return;
			var url = payload.url || (payload.data && payload.data.webUrl) || '';
			if (!url) return;
			var input = document.getElementById('contact_photo');
			if (input) input.value = url;
			updateContactPhotoPreview(url);
			if (typeof window.showToast === 'function') {
				window.showToast('Profile photo selected successfully.', 'success');
			}
		}
	});
};

window.openMediaPicker = function(mode, options) {
	options = options || {};
	var modal = document.getElementById("mediaPickerModal");
	var backdrop = document.getElementById("mediaPickerModalBackdrop");
	var iframe = document.getElementById("mediaPickerIframe");
	var title = document.getElementById("mediaPickerTitleText");

	if (title) {
		title.textContent = options.title || 'Select Asset from Media Library';
	}
	var activeWs = options.workspace || (document.getElementById('virtual_directory') ? document.getElementById('virtual_directory').value.trim() : '') || 'global';
	var pickerType = (mode === 'document') ? 'document' : 'image';
	var folder = options.folder || 'images';

	if (typeof options.onSelect === 'function') {
		window._mediaPickerCustomCallback = options.onSelect;
	} else {
		window._mediaPickerCustomCallback = null;
	}

	if (iframe) {
		iframe.src = '/media/picker?picker=' + encodeURIComponent(mode) + '&type=' + encodeURIComponent(pickerType) + '&folder=' + encodeURIComponent(folder) + '&ws=' + encodeURIComponent(activeWs) + '&callback=onMediaSelectedFromPicker';
	}
	if (modal) {
		modal.style.display = 'flex';
		modal.classList.add('open');
	}
	if (backdrop) {
		backdrop.style.display = 'block';
		backdrop.style.opacity = '1';
		backdrop.style.visibility = 'visible';
		backdrop.classList.add('open');
	}
};

window.closeMediaPickerModal = function() {
	var modal = document.getElementById("mediaPickerModal");
	var backdrop = document.getElementById("mediaPickerModalBackdrop");
	var iframe = document.getElementById("mediaPickerIframe");
	if (modal) {
		modal.style.display = 'none';
		modal.classList.remove('open');
	}
	if (backdrop) {
		backdrop.style.display = 'none';
		backdrop.style.opacity = '0';
		backdrop.style.visibility = 'hidden';
		backdrop.classList.remove('open');
	}
	if (iframe) {
		iframe.src = 'about:blank';
	}
	window._mediaPickerCustomCallback = null;
};

window.onMediaSelectedFromPicker = function(payload) {
	var cb = window._mediaPickerCustomCallback;
	closeMediaPickerModal();
	if (typeof cb === 'function') {
		cb(payload);
	}
};

window.triggerMediaPickerUpload = function() {
	try {
		var iframe = document.getElementById("mediaPickerIframe");
		if (iframe && iframe.contentDocument) {
			var b = iframe.contentDocument.getElementById("btn-upload");
			if (b) { b.click(); return; }
		}
	} catch (e) {}
};
</script>
