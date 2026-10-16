<cfset pageTitle = "Create Workspace">
<cfparam name="variables.departmentCategories" default="#[]#">
<cfparam name="variables.workspace" default="#{}#">

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">Create Workspace</h1>
			<span class="badge badge-danger" style="font-size:0.75rem; padding:0.2rem 0.55rem;">Admin Only</span>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Administration</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='workspaces', action='index')#">Workspaces</a></li>
				<li class="breadcrumb-item active" aria-current="page">Create Workspace</li>
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
</style>

<form action="#urlFor(controller='workspaces', action='create')#" method="post" class="workspace-form">
	#authenticityTokenField()#

	<div class="ws-form-grid">
		<!--- PANEL 1 (6-col): SITE & DIRECTORY CONFIGURATION --->
		<div class="admin-card col-6">
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
							<input type="radio" name="type" value="dept" checked style="margin-top:0.25rem;">
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
							<input type="radio" name="type" value="site" style="margin-top:0.25rem;">
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
					<input type="text" id="site_name" name="site_name" class="form-control" placeholder="Please enter site name" required autocomplete="off" oninput="autoSuggestVirtualDir(this.value)">
				</div>

				<div>
					<label for="virtual_directory" class="ws-form-label">Virtual Directory <span style="color:var(--admin-danger);">*</span></label>
					<input type="text" id="virtual_directory" name="virtual_directory" class="form-control" placeholder="This should match the IIS virtual directory" required autocomplete="off">
					<small style="color:var(--admin-text-muted); font-size:0.75rem; display:block; margin-top:0.35rem;">
						Storage path: <code>files/[virtual-directory]</code>. Media &amp; documents folders will be automatically initialized on disk.
					</small>
				</div>

				<div class="ws-grid-2">
					<div>
						<label for="department" class="ws-form-label">Department</label>
						<input type="text" id="department" name="department" class="form-control" placeholder="Please enter department" autocomplete="off">
					</div>
					<div>
						<label for="department_category" class="ws-form-label">Department Category</label>
						<select id="department_category" name="department_category" class="form-control">
							<option value="">Select Category (if applicable)</option>
							<cfloop array="#variables.departmentCategories#" index="local.cat">
								<option value="#EncodeForHTMLAttribute(local.cat)#">#EncodeForHTML(local.cat)#</option>
							</cfloop>
						</select>
					</div>
				</div>

				<div>
					<label for="redirect_url" class="ws-form-label">Custom Redirect URL</label>
					<input type="text" id="redirect_url" name="redirect_url" class="form-control" placeholder="https://www.chelancounty.gov/..." autocomplete="off">
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
								#svgIcon(name="building", size=12)#
							</span>
							<span id="wsColorPreviewText">Workspace Preview</span>
						</div>
					</div>

					<div style="display:flex; align-items:center; gap:0.75rem; flex-wrap:wrap;">
						<!--- Native Color Picker Clickable Swatch --->
						<div style="position:relative; display:inline-flex; align-items:center;" title="Click to open color picker">
							<input type="color" id="wsColorPicker" value="##7e22ce" style="position:absolute; opacity:0; width:38px; height:38px; cursor:pointer; left:0; top:0; z-index:2;" title="Choose Custom Color">
							<div id="wsColorSwatch" style="width:38px; height:38px; border-radius:var(--radius-sm); border:2px solid var(--admin-border); background-color:##7e22ce; cursor:pointer; box-shadow:var(--shadow-sm); display:flex; align-items:center; justify-content:center; transition:transform 0.15s ease;" title="Click to open color picker">
							</div>
						</div>

						<!--- Hex Code Input Field --->
						<div style="display:inline-flex; align-items:center; position:relative; width:135px;">
							<span style="position:absolute; left:0.65rem; color:var(--admin-text-muted); font-size:0.85rem; font-weight:700; pointer-events:none;">##</span>
							<input type="text" id="wsColorHex" name="color" class="form-control" value="7E22CE" maxlength="7" placeholder="7E22CE" style="padding-left:1.6rem; font-family:monospace; font-weight:700; text-transform:uppercase; font-size:0.85rem;" autocomplete="off" required>
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

		<!--- PANEL 2 (6-col): OFFICIAL CONTACT INFORMATION --->
		<div class="admin-card col-6">
			<div class="card-header">
				<div style="display:flex; align-items:center; gap:0.5rem;">
					<div style="width:30px; height:30px; border-radius:var(--radius-sm); background:rgba(126,34,206,0.1); color:var(--admin-purple, ##7e22ce); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
						#svgIcon(name="user", size=16)#
					</div>
					<div>
						<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main);">Official Contact Information</h2>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.1rem;">Primary department contact, administrative lead, and direct communications.</div>
					</div>
				</div>
				<span class="badge badge-purple" style="font-size:0.7rem; padding:0.2rem 0.5rem;">Communications</span>
			</div>
			<div class="card-body">
				<div class="ws-grid-2">
					<div>
						<label for="contact_first_name" class="ws-form-label">First Name</label>
						<input type="text" id="contact_first_name" name="contact_first_name" class="form-control" placeholder="Please enter First Name" autocomplete="off">
					</div>
					<div>
						<label for="contact_last_name" class="ws-form-label">Last Name</label>
						<input type="text" id="contact_last_name" name="contact_last_name" class="form-control" placeholder="Please enter Last Name" autocomplete="off">
					</div>
				</div>

				<div>
					<label for="contact_email" class="ws-form-label">Email</label>
					<input type="email" id="contact_email" name="contact_email" class="form-control" placeholder="Please enter Email (e.g. contact@chelancounty.gov)" autocomplete="off">
				</div>

				<div class="ws-grid-2">
					<div>
						<label for="contact_phone" class="ws-form-label">Phone</label>
						<input type="tel" id="contact_phone" name="contact_phone" class="form-control" placeholder="Please enter Phone Number" autocomplete="off">
					</div>
					<div>
						<label for="contact_fax" class="ws-form-label">Fax</label>
						<input type="tel" id="contact_fax" name="contact_fax" class="form-control" placeholder="Please enter Fax Number" autocomplete="off">
					</div>
				</div>
			</div>
		</div>

		<!--- PANEL 3 (6-col): PHYSICAL LOCATION & ADDRESS --->
		<div class="admin-card col-6">
			<div class="card-header">
				<div style="display:flex; align-items:center; gap:0.5rem;">
					<div style="width:30px; height:30px; border-radius:var(--radius-sm); background:rgba(16,185,129,0.1); color:var(--admin-success, ##10b981); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
						#svgIcon(name="map-pin", size=16)#
					</div>
					<div>
						<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main);">Physical Location &amp; Address</h2>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.1rem;">Municipal facility address, room details, and mailing coordinates.</div>
					</div>
				</div>
				<span class="badge badge-success" style="font-size:0.7rem; padding:0.2rem 0.5rem;">Location</span>
			</div>
			<div class="card-body">
				<div>
					<label for="address" class="ws-form-label">Address</label>
					<input type="text" id="address" name="address" class="form-control" placeholder="Please enter address (e.g. 350 Orondo Ave)" autocomplete="off">
					<input type="text" id="address2" name="address2" class="form-control" placeholder="Suite, unit, floor, or building (optional)" style="margin-top:0.5rem;" autocomplete="off">
				</div>

				<div class="ws-grid-3">
					<div>
						<label for="city" class="ws-form-label">City</label>
						<input type="text" id="city" name="city" class="form-control" value="Wenatchee" autocomplete="off">
					</div>
					<div>
						<label for="state" class="ws-form-label">State</label>
						<input type="text" id="state" name="state" class="form-control" value="WA" autocomplete="off">
					</div>
					<div>
						<label for="zip" class="ws-form-label">Zip</label>
						<input type="text" id="zip" name="zip" class="form-control" value="98801" autocomplete="off">
					</div>
				</div>
			</div>
			<div class="card-footer" style="padding:1rem 1.25rem; background:var(--admin-bg); border-top:1px solid var(--admin-border); font-size:0.75rem; color:var(--admin-text-muted); display:flex; align-items:center; min-height:57px; box-sizing:border-box;">
				<span>Municipal facility address &amp; mailing coordinates</span>
			</div>
		</div>

		<!--- PANEL 4 (6-col): OPERATING HOURS & SCHEDULE --->
		<div class="admin-card col-6">
			<div class="card-header">
				<div style="display:flex; align-items:center; gap:0.5rem;">
					<div style="width:30px; height:30px; border-radius:var(--radius-sm); background:rgba(245,158,11,0.1); color:var(--admin-warning, ##d97706); display:flex; align-items:center; justify-content:center; flex-shrink:0;">
						#svgIcon(name="clock", size=16)#
					</div>
					<div>
						<h2 style="font-size:0.95rem; font-weight:700; margin:0; color:var(--admin-text-main);">Operating Hours &amp; Schedule</h2>
						<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.1rem;">Public office hours, walk-in availability, and scheduling details.</div>
					</div>
				</div>
				<span class="badge badge-warning" style="font-size:0.7rem; padding:0.2rem 0.5rem;">Schedule</span>
			</div>
			<div class="card-body">
				<div>
					<label for="office_hours" class="ws-form-label">Office Hours</label>
					<textarea id="office_hours" name="office_hours" class="form-control" rows="4" placeholder="Please enter Office Hours (e.g. Monday - Friday: 8:00 AM - 5:00 PM)"></textarea>
				</div>

				<div style="background:var(--admin-surface-hover); border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.75rem 0.85rem; font-size:0.76rem; color:var(--admin-text-muted); display:flex; align-items:flex-start; gap:0.5rem;">
					<span style="color:var(--admin-primary); margin-top:1px;">#svgIcon(name="info", size=14)#</span>
					<span>These operating hours will be displayed on the public department portal, staff directories, and municipal visitor guides.</span>
				</div>
			</div>
			<div class="card-footer" style="padding:1rem 1.25rem; background:var(--admin-bg); border-top:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; min-height:57px; box-sizing:border-box;">
				<a href="#urlFor(controller='workspaces', action='index')#" class="btn btn-secondary btn-sm">Cancel</a>
				<button type="submit" class="btn btn-primary btn-sm">
					#svgIcon(name="save", size=15)#
					<span>Create Workspace</span>
				</button>
			</div>
		</div>
	</div>
</form>

<script>
function autoSuggestVirtualDir(siteName) {
	var dirInput = document.getElementById("virtual_directory");
	if (dirInput && !dirInput.dataset.manuallyEdited) {
		var slug = siteName.toLowerCase().trim()
			.replace(/[^a-z0-9\s-]/g, "")
			.replace(/[\s-]+/g, "-")
			.replace(/^-+|-+$/g, "");
		dirInput.value = slug;
	}
}

document.addEventListener("DOMContentLoaded", function() {
	var dirInput = document.getElementById("virtual_directory");
	if (dirInput) {
		dirInput.addEventListener("input", function() {
			if (this.value.trim().length > 0) {
				this.dataset.manuallyEdited = "true";
			} else {
				delete this.dataset.manuallyEdited;
			}
		});
	}
});
</script>
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
			previewText.textContent = e.target.value.trim() || "Workspace Preview";
		});
	}

	// Initialize with current color
	var initialVal = (hexInput && hexInput.value.trim()) ? hexInput.value.trim() : "7E22CE";
	applyColor("#" + initialVal);
});
</script>
