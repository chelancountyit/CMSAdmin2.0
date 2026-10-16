<cfparam name="release" default="#{}#">

<cfoutput>
<div class="press-view-toolbar no-print" style="margin-bottom:1.5rem; display:flex; justify-content:space-between; align-items:center; background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:0.75rem 1.25rem;">
	<div style="display:flex; align-items:center; gap:0.75rem;">
		<a href="#urlFor(controller='pressReleases', action='index')#" class="btn btn-outline-secondary btn-sm">
			&larr; Back to Press Releases
		</a>
		<a href="#urlFor(controller='pressReleases', action='edit', params='id=#release.id#')#" class="btn btn-outline-secondary btn-sm">
			#svgIcon(name="edit", size=14)# Edit
		</a>
	</div>
	<div style="display:flex; align-items:center; gap:0.6rem;">
		<cfif Len(release.pdf_url)>
			<a href="#EncodeForHTML(release.pdf_url)#" target="_blank" class="btn btn-outline-secondary btn-sm">
				#svgIcon(name="download", size=14)# Download PDF
			</a>
		</cfif>
		<button type="button" class="btn btn-primary btn-sm" onclick="window.print()">
			#svgIcon(name="printer", size=14)# Print / Export
		</button>
	</div>
</div>

<div class="press-document-sheet" style="background:##ffffff; color:##0f172a; max-width:850px; margin:0 auto; padding:3rem 3.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); box-shadow:0 8px 30px rgba(0,0,0,0.06); font-family:Georgia, Cambria, 'Times New Roman', Times, serif; line-height:1.7;">
	<!--- Official Masthead --->
	<header style="border-bottom:2.5px solid ##0f172a; padding-bottom:1.5rem; margin-bottom:2rem; display:flex; justify-content:space-between; align-items:flex-start; gap:2rem;">
		<div>
			<div style="font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size:0.85rem; font-weight:800; text-transform:uppercase; letter-spacing:0.12em; color:##0284c7; margin-bottom:0.25rem;">
				CHELAN COUNTY, WASHINGTON
			</div>
			<div style="font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size:1.35rem; font-weight:900; letter-spacing:0.04em; color:##0f172a;">
				PUBLIC INFORMATION OFFICE
			</div>
			<div style="font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size:0.8rem; color:##64748b; margin-top:0.2rem;">
				400 Douglas Street, Suite 201 &bull; Wenatchee, WA 98801
			</div>
		</div>

		<!--- Media Contact Block --->
		<div style="text-align:right; font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size:0.8rem; line-height:1.45; background:##f8fafc; border:1px solid ##e2e8f0; border-radius:6px; padding:0.75rem 1rem;">
			<div style="font-weight:700; text-transform:uppercase; letter-spacing:0.05em; color:##475569; font-size:0.72rem; margin-bottom:0.35rem;">MEDIA INQUIRIES:</div>
			<div style="font-weight:700; color:##0f172a;">#EncodeForHTML(release.contact_name ?: "Public Information Office")#</div>
			<cfif Len(release.contact_title)>
				<div style="color:##64748b; font-size:0.75rem;">#EncodeForHTML(release.contact_title)#</div>
			</cfif>
			<cfif Len(release.contact_phone)>
				<div style="color:##0f172a; margin-top:0.2rem;"><strong>Phone:</strong> #EncodeForHTML(release.contact_phone)#</div>
			</cfif>
			<cfif Len(release.contact_email)>
				<div style="color:##0284c7;">#EncodeForHTML(release.contact_email)#</div>
			</cfif>
		</div>
	</header>

	<!--- Release Notice Banner --->
	<div style="margin-bottom:1.5rem; font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
		<div style="font-weight:800; font-size:0.95rem; text-transform:uppercase; letter-spacing:0.08em; color:##15803d; border-bottom:1px solid ##e2e8f0; padding-bottom:0.5rem; display:flex; justify-content:space-between; align-items:center;">
				<span>FOR IMMEDIATE RELEASE</span>
				<span style="font-weight:600; color:##64748b; font-size:0.85rem; text-transform:none; letter-spacing:normal;">
					<cfif IsDate(release.released_at)>
						#DateFormat(release.released_at, "mmmm d, yyyy")#
					</cfif>
				</span>
			</div>
	</div>

	<!--- Release Headline --->
	<h1 style="font-size:2rem; font-weight:800; line-height:1.25; color:##0f172a; margin:0 0 1rem; font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
		#EncodeForHTML(release.title)#
	</h1>

	<!--- Subhead / Summary --->
	<cfif Len(release.summary)>
		<div style="font-size:1.15rem; color:##334155; font-style:italic; line-height:1.5; margin-bottom:1.75rem; border-left:3px solid ##cbd5e1; padding-left:1rem;">
			#EncodeForHTML(release.summary)#
		</div>
	</cfif>

	<!--- Release Dateline & Body --->
	<div class="press-release-body" style="font-size:1.05rem; color:##1e293b; margin-bottom:2.5rem;">
		<span style="font-weight:800; font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size:0.9rem; letter-spacing:0.05em; color:##0f172a;">
			#EncodeForHTML(release.dateline)# &mdash;
		</span>
		#release.content_html#
	</div>

	<!--- End Mark --->
	<div style="text-align:center; font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-weight:800; letter-spacing:0.5em; color:##64748b; margin:2.5rem 0;">
		&##35;&##35;&##35;
	</div>

	<!--- Official Boilerplate --->
	<footer style="border-top:1px solid ##e2e8f0; padding-top:1.5rem; margin-top:2rem; font-family:system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size:0.8rem; color:##64748b; line-height:1.5;">
		<strong style="color:##0f172a;">About Chelan County:</strong> Located in North Central Washington, Chelan County encompasses over 2,900 square miles of pristine mountains, rivers, apple orchards, and vibrant communities from Wenatchee and Leavenworth to Lake Chelan. For more information, visit <a href="https://www.co.chelan.wa.us" target="_blank" style="color:##0284c7; text-decoration:none;">www.co.chelan.wa.us</a>.
	</footer>
</div>
</cfoutput>