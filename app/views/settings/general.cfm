<cfoutput>
<div class="page-header d-flex justify-content-between align-items-center mb-4" style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; flex-wrap:wrap; margin-bottom:1.5rem;">
	<div>
		<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.35rem; flex-wrap:wrap;">
			<span class="badge badge-primary" style="font-size:0.72rem; text-transform:uppercase; letter-spacing:0.05em;">Settings &bull; General</span>
			<span class="badge badge-neutral" style="font-size:0.72rem;">Core Configuration</span>
			<span class="badge badge-success" style="font-size:0.72rem;">WCAG 2.1 AA Compliant</span>
		</div>
		<h1 class="page-title" style="margin:0; font-size:1.5rem; font-weight:700;">General Administrative Settings</h1>
		<p class="text-muted" style="margin:0.35rem 0 0; color:var(--admin-text-muted); font-size:0.92rem;">
			Manage official municipal identity, central switchboard contacts, physical courthouse operating hours, timezone, and public maintenance mode.
		</p>
	</div>
	<div style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="#urlFor(controller='settings', action='seo')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="search", size=14)#
			<span>Reading &amp; SEO</span>
		</a>
		<a href="#urlFor(controller='settings', action='media')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="image", size=14)#
			<span>Media Sizes</span>
		</a>
		<a href="#urlFor(controller='settings', action='system')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="cpu", size=14)#
			<span>System Diagnostics</span>
		</a>
	</div>
</div>

<form action="#urlFor(controller='settings', action='saveGeneral')#" method="post" id="settingsGeneralForm">
	#authenticityTokenField()#

	<div style="display:grid; grid-template-columns: 8fr 4fr; gap:1.5rem; align-items:start;">
		<!--- Main Settings Column --->
		<div style="display:flex; flex-direction:column; gap:1.5rem;">
			
			<!--- Card 1: Municipal Identity & Switchboard --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="globe", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Municipal Identity &amp; Switchboard Contacts</h2>
				</div>

				<div class="form-group mb-3" style="margin-bottom:1rem;">
					<label for="site_title" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Official Website Title <span style="color:var(--admin-danger); font-weight:700;">*</span>
					</label>
					<input type="text" id="site_title" name="site_title" class="form-control" value="#EncodeForHTMLAttribute(settings.site_title)#" required style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Primary title rendered in browser headers, sitemaps, and public footer copyright notices.
					</small>
				</div>

				<div class="form-group mb-3" style="margin-bottom:1rem;">
					<label for="site_tagline" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Site Tagline / Sub-Headline
					</label>
					<input type="text" id="site_tagline" name="site_tagline" class="form-control" value="#EncodeForHTMLAttribute(settings.site_tagline)#" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Secondary municipal motto displayed in hero sections, search snippet descriptions, and open graph cards.
					</small>
				</div>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
					<div class="form-group mb-3" style="margin-bottom:1rem;">
						<label for="admin_email" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
							Administrative &amp; PIO Email <span style="color:var(--admin-danger); font-weight:700;">*</span>
						</label>
						<input type="email" id="admin_email" name="admin_email" class="form-control" value="#EncodeForHTMLAttribute(settings.admin_email)#" required style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
						<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
							Official contact address for public records, system notifications, and feedback.
						</small>
					</div>

					<div class="form-group mb-3" style="margin-bottom:1rem;">
						<label for="county_phone" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
							Central Switchboard Phone <span style="color:var(--admin-danger); font-weight:700;">*</span>
						</label>
						<input type="tel" id="county_phone" name="county_phone" class="form-control" value="#EncodeForHTMLAttribute(settings.county_phone)#" required style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
						<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
							Main county telephone switchboard number displayed across public portal footers.
						</small>
					</div>
				</div>
			</div>

			<!--- Card 2: Physical Courthouse Location & Hours --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="map-pin", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Courthouse Location &amp; Public Hours</h2>
				</div>

				<div class="form-group mb-3" style="margin-bottom:1rem;">
					<label for="county_address" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Official Physical Address
					</label>
					<input type="text" id="county_address" name="county_address" class="form-control" value="#EncodeForHTMLAttribute(settings.county_address)#" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Primary county administration and courthouse street address for schema.org local business markup.
					</small>
				</div>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
					<div class="form-group mb-3" style="margin-bottom:1rem;">
						<label for="office_hours" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
							Standard Operating Hours
						</label>
						<input type="text" id="office_hours" name="office_hours" class="form-control" value="#EncodeForHTMLAttribute(settings.office_hours)#" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
						<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
							Public front-counter operating schedule.
						</small>
					</div>

					<div class="form-group mb-3" style="margin-bottom:1rem;">
						<label for="timezone" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
							Municipal Timezone
						</label>
						<select id="timezone" name="timezone" class="form-select" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
							<cfloop array="#timezones#" index="tz">
								<option value="#tz.code#" <cfif settings.timezone eq tz.code>selected="selected"</cfif>>#EncodeForHTML(tz.label)#</option>
							</cfloop>
						</select>
						<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
							Used for publishing datetimes, event calendars, and revision timestamps.
						</small>
					</div>
				</div>
			</div>

			<!--- Card 3: Maintenance Mode --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<div style="display:flex; align-items:center; gap:0.6rem;">
						<span style="color:<cfif settings.maintenance_mode eq '1'>var(--admin-danger)<cfelse>var(--admin-primary)</cfif>;">#svgIcon(name="alert-triangle", size=20)#</span>
						<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Public Maintenance Mode</h2>
					</div>
					<cfif settings.maintenance_mode eq "1">
						<span class="badge badge-danger" style="font-size:0.75rem; font-weight:700;">MAINTENANCE ACTIVE</span>
					<cfelse>
						<span class="badge badge-success" style="font-size:0.75rem; font-weight:700;">PUBLIC SITE LIVE</span>
					</cfif>
				</div>

				<div style="display:flex; align-items:flex-start; gap:0.75rem; margin-bottom:1rem; padding:1rem; background:var(--admin-bg); border-radius:var(--radius-md); border:1px solid var(--admin-border);">
					<input type="checkbox" id="maintenance_mode" name="maintenance_mode" value="1" <cfif settings.maintenance_mode eq "1">checked="checked"</cfif> style="width:1.2rem; height:1.2rem; margin-top:0.2rem; cursor:pointer;">
					<div>
						<label for="maintenance_mode" style="font-weight:700; font-size:0.92rem; color:var(--admin-text-main); cursor:pointer; margin:0;">
							Enable Front-End Scheduled Maintenance Mode
						</label>
						<p style="margin:0.25rem 0 0; font-size:0.82rem; color:var(--admin-text-muted); line-height:1.45;">
							When activated, public citizens visiting <code>chelancounty.gov</code> are presented with an emergency maintenance screen. Staff members logged into <code>cmsadmin</code> retain unrestricted administrative access.
						</p>
					</div>
				</div>

				<div class="form-group mb-2">
					<label for="maintenance_message" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Citizen Maintenance Banner Notice
					</label>
					<textarea id="maintenance_message" name="maintenance_message" class="form-control" rows="3" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface); line-height:1.5;">#EncodeForHTML(settings.maintenance_message)#</textarea>
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Notice shown to the public explaining service downtime, emergency dispatch alternatives, and expected restoration.
					</small>
				</div>
			</div>

		</div>

		<!--- Sidebar Actions Column --->
		<div style="display:flex; flex-direction:column; gap:1.25rem;">
			<!--- Save Action Card --->
			<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<h3 style="margin:0 0 0.85rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="save", size=16)#
					<span>Save Configuration</span>
				</h3>
				<p style="font-size:0.82rem; color:var(--admin-text-muted); margin-bottom:1rem; line-height:1.45;">
					Modifications apply immediately to the Chelan County database and front-end layout headers.
				</p>
				<button type="submit" class="btn btn-primary" style="width:100%; display:inline-flex; align-items:center; justify-content:center; gap:0.5rem; font-weight:600; padding:0.65rem 1rem;">
					#svgIcon(name="check", size=16)#
					<span>Save General Settings</span>
				</button>
			</div>

			<!--- Settings Navigation Hub --->
			<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<h3 style="margin:0 0 0.85rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="settings", size=16)#
					<span>Settings Modules</span>
				</h3>
				<ul style="list-style:none; padding:0; margin:0; display:flex; flex-direction:column; gap:0.4rem;">
					<li>
						<a href="#urlFor(controller='settings', action='general')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); color:var(--admin-primary); font-weight:600; font-size:0.85rem; text-decoration:none;">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="globe", size=15)# General Settings
							</span>
							<span class="badge badge-primary" style="font-size:0.7rem;">Active</span>
						</a>
					</li>
					<li>
						<a href="#urlFor(controller='settings', action='seo')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="search", size=15)# Reading &amp; SEO
							</span>
							<span style="color:var(--admin-text-muted); font-size:0.75rem;">Meta &bull; GA4</span>
						</a>
					</li>
					<li>
						<a href="#urlFor(controller='settings', action='media')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="image", size=15)# Media Sizes
							</span>
							<span style="color:var(--admin-text-muted); font-size:0.75rem;">Upload Caps</span>
						</a>
					</li>
					<li>
						<a href="#urlFor(controller='settings', action='system')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="cpu", size=15)# System Info
							</span>
							<span style="color:var(--admin-text-muted); font-size:0.75rem;">JVM &bull; SQL</span>
						</a>
					</li>
					<li>
						<a href="#urlFor(controller='settings', action='startup')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="code", size=15)# Front-End (.css)
							</span>
							<span style="color:var(--admin-text-muted); font-size:0.75rem;">Templates</span>
						</a>
					</li>
				</ul>
			</div>

			<!--- Information Callout --->
			<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-bg); box-shadow:none;">
				<h4 style="margin:0 0 0.5rem; font-size:0.85rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.4rem;">
					#svgIcon(name="info", size=15)#
					<span>Municipal Compliance</span>
				</h4>
				<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0; line-height:1.45;">
					Per RCW 42.56, physical administrative office hours and official contact switchboards must remain publicly visible and accessible at all times.
				</p>
			</div>
		</div>
	</div>
</form>
</cfoutput>

