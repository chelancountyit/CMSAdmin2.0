<cfoutput>
<div class="page-header d-flex justify-content-between align-items-center mb-4" style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; flex-wrap:wrap; margin-bottom:1.5rem;">
	<div>
		<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.35rem; flex-wrap:wrap;">
			<span class="badge badge-primary" style="font-size:0.72rem; text-transform:uppercase; letter-spacing:0.05em;">Settings &bull; SEO</span>
			<span class="badge badge-info" style="font-size:0.72rem;">Search &amp; Social</span>
			<span class="badge badge-success" style="font-size:0.72rem;">WCAG 2.1 AA Compliant</span>
		</div>
		<h1 class="page-title" style="margin:0; font-size:1.5rem; font-weight:700;">Reading &amp; Search Engine Optimization (SEO)</h1>
		<p class="text-muted" style="margin:0.35rem 0 0; color:var(--admin-text-muted); font-size:0.92rem;">
			Configure default search engine snippets, title format patterns, OpenGraph share cards, Google Analytics (GA4/GTM), and crawler rules.
		</p>
	</div>
	<div style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="#urlFor(controller='settings', action='general')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="globe", size=14)#
			<span>General Settings</span>
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

<form action="#urlFor(controller='settings', action='saveSeo')#" method="post" id="settingsSeoForm">
	#authenticityTokenField()#

	<div style="display:grid; grid-template-columns: 8fr 4fr; gap:1.5rem; align-items:start;">
		<!--- Main SEO Settings Column --->
		<div style="display:flex; flex-direction:column; gap:1.5rem;">
			
			<!--- Card 1: Browser Titles & Fallback Search Meta --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="search", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Search Engine Snippets &amp; Browser Titles</h2>
				</div>

				<div class="form-group mb-3" style="margin-bottom:1.25rem;">
					<label for="seo_meta_title_format" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Browser Title Template Pattern <span style="color:var(--admin-danger); font-weight:700;">*</span>
					</label>
					<input type="text" id="seo_meta_title_format" name="seo_meta_title_format" class="form-control" value="#EncodeForHTMLAttribute(settings.seo_meta_title_format)#" required style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Use <code>{page_title}</code> as the dynamic token. Example: <code>{page_title} | Chelan County, WA</code> produces <em>Board of Commissioners | Chelan County, WA</em>.
					</small>
				</div>

				<div class="form-group mb-2">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.35rem;">
						<label for="seo_default_meta_description" style="font-weight:600; font-size:0.875rem; color:var(--admin-text-main); margin:0;">
							Default Search Meta Description <span style="color:var(--admin-danger); font-weight:700;">*</span>
						</label>
						<span id="metaDescCount" style="font-size:0.78rem; color:var(--admin-text-muted);">#len(settings.seo_default_meta_description)# / 160 chars</span>
					</div>
					<textarea id="seo_default_meta_description" name="seo_default_meta_description" class="form-control" rows="3" required style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface); line-height:1.5;" oninput="document.getElementById('metaDescCount').textContent = this.value.length + ' / 160 chars'">#EncodeForHTML(settings.seo_default_meta_description)#</textarea>
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Used as the fallback SERP description across all search results whenever individual pages do not provide a dedicated meta description.
					</small>
				</div>
			</div>

			<!--- Card 2: Open Graph & Social Media Cards --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="share-2", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Social Media &amp; OpenGraph Share Cards</h2>
				</div>

				<div class="form-group mb-3" style="margin-bottom:1.25rem;">
					<label for="seo_default_og_image" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Default OpenGraph &amp; Twitter Card Image URL
					</label>
					<div style="display:flex; gap:0.75rem; align-items:center;">
						<input type="text" id="seo_default_og_image" name="seo_default_og_image" class="form-control" value="#EncodeForHTMLAttribute(settings.seo_default_og_image)#" style="flex:1; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
						<a href="#urlFor(controller='media', action='index')#" target="_blank" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.35rem; white-space:nowrap;">
							#svgIcon(name="image", size=14)# Media Picker
						</a>
					</div>
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Displayed in Facebook, LinkedIn, X/Twitter, and iMessage rich preview cards when links are shared. Recommended 1200 &times; 630 pixels.
					</small>
				</div>

				<div class="form-group mb-2">
					<label for="seo_twitter_handle" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Official County X / Twitter Handle
					</label>
					<div style="position:relative;">
						<input type="text" id="seo_twitter_handle" name="seo_twitter_handle" class="form-control" value="#EncodeForHTMLAttribute(settings.seo_twitter_handle)#" placeholder="@ChelanCountyWA" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
					</div>
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Attributed as <code>twitter:site</code> and <code>twitter:creator</code> meta tags.
					</small>
				</div>
			</div>

			<!--- Card 3: Web Analytics & Tag Management --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="bar-chart-2", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Web Analytics &amp; Tag Management</h2>
				</div>

				<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
					<div class="form-group mb-2">
						<label for="seo_ga_tracking_id" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
							Google Analytics 4 (GA4) ID
						</label>
						<input type="text" id="seo_ga_tracking_id" name="seo_ga_tracking_id" class="form-control" value="#EncodeForHTMLAttribute(settings.seo_ga_tracking_id)#" placeholder="G-XXXXXXXXXX" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
						<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
							Measurement ID for Google Analytics gtag.js integration.
						</small>
					</div>

					<div class="form-group mb-2">
						<label for="seo_gtm_container_id" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
							Google Tag Manager (GTM) Container
						</label>
						<input type="text" id="seo_gtm_container_id" name="seo_gtm_container_id" class="form-control" value="#EncodeForHTMLAttribute(settings.seo_gtm_container_id)#" placeholder="GTM-XXXXXXX" style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
						<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
							Container ID for marketing, event tracking, and accessibility tools.
						</small>
					</div>
				</div>
			</div>

			<!--- Card 4: Search Engine Crawlers (robots.txt) --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<div style="display:flex; align-items:center; gap:0.6rem;">
						<span style="color:var(--admin-primary);">#svgIcon(name="file-text", size=20)#</span>
						<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Search Engine Spider Rules (<code>robots.txt</code>)</h2>
					</div>
					<span class="badge badge-neutral" style="font-size:0.75rem;">Crawler Directives</span>
				</div>

				<div class="form-group mb-2">
					<label for="seo_robots_txt" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Robots Exclusion Protocol Directives
					</label>
					<textarea id="seo_robots_txt" name="seo_robots_txt" class="form-control" rows="7" style="width:100%; padding:0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-family:monospace; font-size:0.85rem; background:##0f172a; color:##e2e8f0; line-height:1.55;">#EncodeForHTML(settings.seo_robots_txt)#</textarea>
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Specifies which directories web crawlers (Googlebot, Bingbot) may index. Always disallow <code>/admin/</code> and internal API routes.
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
					Updates to SEO tags, OpenGraph cards, and robots.txt will take effect on next crawler inspection.
				</p>
				<button type="submit" class="btn btn-primary" style="width:100%; display:inline-flex; align-items:center; justify-content:center; gap:0.5rem; font-weight:600; padding:0.65rem 1rem;">
					#svgIcon(name="check", size=16)#
					<span>Save SEO Settings</span>
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
						<a href="#urlFor(controller='settings', action='general')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="globe", size=15)# General Settings
							</span>
							<span style="color:var(--admin-text-muted); font-size:0.75rem;">Core Identity</span>
						</a>
					</li>
					<li>
						<a href="#urlFor(controller='settings', action='seo')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); color:var(--admin-primary); font-weight:600; font-size:0.85rem; text-decoration:none;">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="search", size=15)# Reading &amp; SEO
							</span>
							<span class="badge badge-primary" style="font-size:0.7rem;">Active</span>
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
						<a href="#urlFor(controller='documentation', action='startup')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="book", size=15)# Docs: Front-End (.css)
							</span>
							<span style="color:var(--admin-text-muted); font-size:0.75rem;">Docs</span>
						</a>
					</li>
				</ul>
			</div>

			<!--- Google Search Snippet Preview Box --->
			<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-bg); box-shadow:none;">
				<h4 style="margin:0 0 0.5rem; font-size:0.85rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.4rem;">
					#svgIcon(name="eye", size=15)#
					<span>SERP Preview Simulation</span>
				</h4>
				<div style="background:##ffffff; border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:0.75rem; margin-top:0.5rem; font-family:Arial, sans-serif;">
					<div style="font-size:0.75rem; color:##202124; margin-bottom:0.15rem;">https://www.co.chelan.wa.us</div>
					<div style="font-size:0.95rem; color:##1a0dab; font-weight:500; text-decoration:underline; line-height:1.3; margin-bottom:0.25rem;">
						Chelan County Washington | Official Government
					</div>
					<div style="font-size:0.78rem; color:##4d5156; line-height:1.4;">
						#Left(settings.seo_default_meta_description, 140)#...
					</div>
				</div>
			</div>
		</div>
	</div>
</form>
</cfoutput>

