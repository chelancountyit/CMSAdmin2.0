<cfoutput>
<div class="page-header d-flex justify-content-between align-items-center mb-4" style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; flex-wrap:wrap; margin-bottom:1.5rem;">
	<div>
		<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.35rem; flex-wrap:wrap;">
			<span class="badge badge-primary" style="font-size:0.72rem; text-transform:uppercase; letter-spacing:0.05em;">Settings &bull; Media</span>
			<span class="badge badge-warning" style="font-size:0.72rem;">Dimensions &amp; Limits</span>
			<span class="badge badge-success" style="font-size:0.72rem;">WCAG 2.1 AA Compliant</span>
		</div>
		<h1 class="page-title" style="margin:0; font-size:1.5rem; font-weight:700;">Media Size Presets &amp; Upload Constraints</h1>
		<p class="text-muted" style="margin:0.35rem 0 0; color:var(--admin-text-muted); font-size:0.92rem;">
			Manage automatic image scaling dimensions for thumbnails, banners, and hero graphics, set maximum file size upload caps, and maintain extension whitelists.
		</p>
	</div>
	<div style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="#urlFor(controller='settings', action='general')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="globe", size=14)#
			<span>General Settings</span>
		</a>
		<a href="#urlFor(controller='settings', action='seo')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="search", size=14)#
			<span>Reading &amp; SEO</span>
		</a>
		<a href="#urlFor(controller='settings', action='system')#" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="cpu", size=14)#
			<span>System Diagnostics</span>
		</a>
	</div>
</div>

<form action="#urlFor(controller='settings', action='saveMedia')#" method="post" id="settingsMediaForm">
	#authenticityTokenField()#

	<div style="display:grid; grid-template-columns: 8fr 4fr; gap:1.5rem; align-items:start;">
		<!--- Main Media Settings Column --->
		<div style="display:flex; flex-direction:column; gap:1.5rem;">
			
			<!--- Card 1: Image Scaling Presets --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="image", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Automatic Image Resize Presets</h2>
				</div>

				<p style="font-size:0.85rem; color:var(--admin-text-muted); margin-bottom:1.25rem;">
					The sizes listed below determine the maximum dimensions (in pixels) used when images are uploaded or processed through the Media Inspector.
				</p>

				<!--- Thumbnail Size Row --->
				<div style="padding:1rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); margin-bottom:1rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
						<div style="font-weight:700; font-size:0.92rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.45rem;">
							<span style="display:inline-block; width:12px; height:12px; border-radius:2px; background:var(--admin-primary);"></span>
							<span>Thumbnail Size</span>
						</div>
						<span class="badge badge-neutral" style="font-size:0.75rem;">Grid &bull; Avatar &bull; Icon</span>
					</div>
					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div>
							<label for="media_thumb_width" style="display:block; font-size:0.8rem; font-weight:600; margin-bottom:0.25rem; color:var(--admin-text-main);">Max Width (px)</label>
							<input type="number" id="media_thumb_width" name="media_thumb_width" class="form-control" value="#EncodeForHTMLAttribute(settings.media_thumb_width)#" min="50" max="800" required style="width:100%; padding:0.5rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.88rem; background:var(--admin-surface);">
						</div>
						<div>
							<label for="media_thumb_height" style="display:block; font-size:0.8rem; font-weight:600; margin-bottom:0.25rem; color:var(--admin-text-main);">Max Height (px)</label>
							<input type="number" id="media_thumb_height" name="media_thumb_height" class="form-control" value="#EncodeForHTMLAttribute(settings.media_thumb_height)#" min="50" max="800" required style="width:100%; padding:0.5rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.88rem; background:var(--admin-surface);">
						</div>
					</div>
				</div>

				<!--- Medium Size Row --->
				<div style="padding:1rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); margin-bottom:1rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
						<div style="font-weight:700; font-size:0.92rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.45rem;">
							<span style="display:inline-block; width:12px; height:12px; border-radius:2px; background:var(--admin-info);"></span>
							<span>Medium Size</span>
						</div>
						<span class="badge badge-neutral" style="font-size:0.75rem;">Content Blocks &bull; Cards</span>
					</div>
					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div>
							<label for="media_medium_width" style="display:block; font-size:0.8rem; font-weight:600; margin-bottom:0.25rem; color:var(--admin-text-main);">Max Width (px)</label>
							<input type="number" id="media_medium_width" name="media_medium_width" class="form-control" value="#EncodeForHTMLAttribute(settings.media_medium_width)#" min="200" max="1600" required style="width:100%; padding:0.5rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.88rem; background:var(--admin-surface);">
						</div>
						<div>
							<label for="media_medium_height" style="display:block; font-size:0.8rem; font-weight:600; margin-bottom:0.25rem; color:var(--admin-text-main);">Max Height (px)</label>
							<input type="number" id="media_medium_height" name="media_medium_height" class="form-control" value="#EncodeForHTMLAttribute(settings.media_medium_height)#" min="200" max="1600" required style="width:100%; padding:0.5rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.88rem; background:var(--admin-surface);">
						</div>
					</div>
				</div>

				<!--- Large Size Row --->
				<div style="padding:1rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg);">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
						<div style="font-weight:700; font-size:0.92rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.45rem;">
							<span style="display:inline-block; width:12px; height:12px; border-radius:2px; background:var(--admin-success);"></span>
							<span>Large Size</span>
						</div>
						<span class="badge badge-neutral" style="font-size:0.75rem;">Hero Banners &bull; Lightboxes</span>
					</div>
					<div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
						<div>
							<label for="media_large_width" style="display:block; font-size:0.8rem; font-weight:600; margin-bottom:0.25rem; color:var(--admin-text-main);">Max Width (px)</label>
							<input type="number" id="media_large_width" name="media_large_width" class="form-control" value="#EncodeForHTMLAttribute(settings.media_large_width)#" min="600" max="3840" required style="width:100%; padding:0.5rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.88rem; background:var(--admin-surface);">
						</div>
						<div>
							<label for="media_large_height" style="display:block; font-size:0.8rem; font-weight:600; margin-bottom:0.25rem; color:var(--admin-text-main);">Max Height (px)</label>
							<input type="number" id="media_large_height" name="media_large_height" class="form-control" value="#EncodeForHTMLAttribute(settings.media_large_height)#" min="400" max="2160" required style="width:100%; padding:0.5rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.88rem; background:var(--admin-surface);">
						</div>
					</div>
				</div>
			</div>

			<!--- Card 2: Maximum File Upload Cap & Whitelist --->
			<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
				<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="upload-cloud", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Upload Caps &amp; File Type Restrictions</h2>
				</div>

				<div class="form-group mb-3" style="margin-bottom:1.25rem;">
					<label for="media_max_upload_mb" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Maximum Allowed Single File Upload Size (MB) <span style="color:var(--admin-danger); font-weight:700;">*</span>
					</label>
					<div style="display:flex; align-items:center; gap:0.75rem;">
						<input type="number" id="media_max_upload_mb" name="media_max_upload_mb" class="form-control" value="#EncodeForHTMLAttribute(settings.media_max_upload_mb)#" min="1" max="100" required style="max-width:180px; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface);">
						<span style="font-weight:600; font-size:0.9rem; color:var(--admin-text-main);">Megabytes (MB)</span>
					</div>
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Enforced at the application layer during drag-and-drop and media picker uploads. Must not exceed IIS <code>maxAllowedContentLength</code> (30MB).
					</small>
				</div>

				<div class="form-group mb-2">
					<label for="media_allowed_extensions" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Permitted File Extensions Whitelist <span style="color:var(--admin-danger); font-weight:700;">*</span>
					</label>
					<input type="text" id="media_allowed_extensions" name="media_allowed_extensions" class="form-control" value="#EncodeForHTMLAttribute(settings.media_allowed_extensions)#" required style="width:100%; padding:0.55rem 0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.9rem; background:var(--admin-surface); font-family:monospace;">
					<small class="text-muted" style="display:block; margin-top:0.35rem; font-size:0.78rem; color:var(--admin-text-muted);">
						Comma-separated list of safe file extensions (e.g. <code>jpg,jpeg,png,gif,webp,svg,pdf,doc,docx,xls,xlsx,csv</code>). Scripting binaries are strictly prohibited for municipal cybersecurity compliance.
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
					New dimension limits apply to subsequent asset uploads in the Media Library.
				</p>
				<button type="submit" class="btn btn-primary" style="width:100%; display:inline-flex; align-items:center; justify-content:center; gap:0.5rem; font-weight:600; padding:0.65rem 1rem;">
					#svgIcon(name="check", size=16)#
					<span>Save Media Settings</span>
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
						<a href="#urlFor(controller='settings', action='seo')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="search", size=15)# Reading &amp; SEO
							</span>
							<span style="color:var(--admin-text-muted); font-size:0.75rem;">Meta &bull; GA4</span>
						</a>
					</li>
					<li>
						<a href="#urlFor(controller='settings', action='media')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); color:var(--admin-primary); font-weight:600; font-size:0.85rem; text-decoration:none;">
							<span style="display:flex; align-items:center; gap:0.5rem;">
								#svgIcon(name="image", size=15)# Media Sizes
							</span>
							<span class="badge badge-primary" style="font-size:0.7rem;">Active</span>
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

			<!--- Media Library Direct Link --->
			<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-bg); box-shadow:none;">
				<h4 style="margin:0 0 0.5rem; font-size:0.85rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.4rem;">
					#svgIcon(name="folder", size=15)#
					<span>Media Library Manager</span>
				</h4>
				<p style="font-size:0.8rem; color:var(--admin-text-muted); margin-bottom:0.75rem; line-height:1.45;">
					Inspect, upload, replace, and audit WCAG alt-text metadata across all county media files.
				</p>
				<div style="display:flex; gap:0.5rem; flex-wrap:wrap;">
					<a href="#urlFor(controller='media', action='upload')#" class="btn btn-primary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem; font-size:0.82rem;">
						#svgIcon(name="upload", size=14)#
						<span>Upload Media</span>
					</a>
					<a href="#urlFor(controller='media', action='index')#" class="btn btn-outline-primary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem; font-size:0.82rem;">
						#svgIcon(name="arrow-right", size=14)#
						<span>Open Media Library</span>
					</a>
				</div>
			</div>
		</div>
	</div>
</form>
</cfoutput>

