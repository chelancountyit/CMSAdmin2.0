<cfset pageTitle = "Documentation &amp; Help Center">

<style>
	.kb-guide-card {
		margin-bottom: 1rem;
		transition: transform 0.15s ease, box-shadow 0.15s ease;
	}
	.kb-guide-card:hover {
		box-shadow: var(--shadow-md, 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06));
	}
	.kb-featured-card {
		border-left: 4px solid var(--admin-primary, ##1e3a8a);
		background: linear-gradient(to right, rgba(30, 58, 138, 0.02), transparent);
	}
</style>

<div class="page-header">
	<div>
		<h1 class="page-title">Documentation &amp; Help Center</h1>
		<ol class="breadcrumb" style="margin-top:0.35rem;">
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>">Home</a></li>
			<li class="breadcrumb-item active">Documentation</li>
		</ol>
	</div>
</div>

<section class="admin-card" aria-labelledby="kbIntroTitle" style="margin-bottom:1.5rem;">
	<div class="card-body" style="padding:1.5rem;">
		<div style="display:flex; align-items:center; gap:0.75rem; margin-bottom:0.5rem;">
			<cfoutput>#svgIcon(name="book", size=24)#</cfoutput>
			<h2 id="kbIntroTitle" style="margin:0; font-size:1.25rem;">CMS Admin Knowledge Base &amp; Documentation</h2>
		</div>
		<p style="margin:0; color:var(--admin-text-muted); line-height:1.6; max-width:850px;">
			Official documentation, operational user manuals, and technical blueprints for Chelan County CMSAdmin 2.0.
			Find step-by-step guidance for content authors, public information officers, and system administrators.
		</p>
	</div>
</section>

<section aria-labelledby="kbGuidesTitle">
	<h2 id="kbGuidesTitle" style="font-size:1.05rem; margin:0 0 1rem; display:flex; align-items:center; gap:0.5rem;">
		<cfoutput>#svgIcon(name="file-text", size=18)#</cfoutput>
		<span>Official Manuals &amp; Training Guides</span>
	</h2>

	<!--- 1. Official User Guide (PDF) - Featured Lead Card --->
	<article class="admin-card kb-guide-card kb-featured-card">
		<div class="card-body" style="padding:1.35rem; display:flex; align-items:center; justify-content:space-between; gap:1.25rem; flex-wrap:wrap;">
			<div style="max-width:760px;">
				<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.4rem;">
					<span class="badge badge-primary">Official Handbook</span>
					<span class="badge badge-success">ADA WCAG 2.1 AA</span>
					<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted);">PDF &bull; 489 KB</span>
				</div>
				<h3 style="font-size:1.15rem; margin:0.3rem 0; color:var(--admin-text-main);">
					CMSAdmin 2.0 User Guide (PDF)
				</h3>
				<p style="margin:0; color:var(--admin-text-muted); line-height:1.55; font-size:0.9rem;">
					Comprehensive end-user manual for Chelan County staff and editors. Illustrated workflows covering workspace navigation, Media Library &amp; Explorer, Page Studio, Article &amp; News management, Events Calendar, Form Builder, and statutory compliance checks.
				</p>
			</div>
			<div style="display:flex; gap:0.5rem; flex-wrap:wrap; align-items:center;">
				<a href="<cfoutput>#urlFor(controller='documentation', action='userGuide')#</cfoutput>" class="btn btn-primary btn-sm">
					<cfoutput>#svgIcon(name="eye", size=14)#</cfoutput>
					<span>View User Guide</span>
				</a>
				<a href="/miscellaneous/docs/CMSAdmin-2.0-User-Guide.pdf" download="CMSAdmin-2.0-User-Guide.pdf" class="btn btn-outline btn-sm">
					<cfoutput>#svgIcon(name="download", size=14)#</cfoutput>
					<span>Download PDF</span>
				</a>
			</div>
		</div>
	</article>

	<!--- 2. System Architecture & Technical Documentation (PDF) --->
	<article class="admin-card kb-guide-card">
		<div class="card-body" style="padding:1.35rem; display:flex; align-items:center; justify-content:space-between; gap:1.25rem; flex-wrap:wrap;">
			<div style="max-width:760px;">
				<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.4rem;">
					<span class="badge badge-secondary" style="background:var(--admin-surface-hover, ##f1f5f9); color:var(--admin-text-main);">Technical Architecture</span>
					<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted);">PDF &bull; 931 KB</span>
				</div>
				<h3 style="font-size:1.05rem; margin:0.3rem 0; color:var(--admin-text-main);">
					CMSAdmin 2.0 Technical Architecture &amp; System Blueprint (PDF)
				</h3>
				<p style="margin:0; color:var(--admin-text-muted); line-height:1.55; font-size:0.9rem;">
					Engineering documentation including database schema specifications, SQL Server trigger and filtered index standards, ColdFusion Wheels runtime configuration, security boundary policies, and the .doclib specification series.
				</p>
			</div>
			<div style="display:flex; gap:0.5rem; flex-wrap:wrap; align-items:center;">
				<a href="/miscellaneous/docs/CMSAdmin-2.0-Documentation.pdf" target="_blank" rel="noopener" class="btn btn-outline btn-sm">
					<cfoutput>#svgIcon(name="external-link", size=14)#</cfoutput>
					<span>Open in Tab</span>
				</a>
				<a href="/miscellaneous/docs/CMSAdmin-2.0-Documentation.pdf" download="CMSAdmin-2.0-Documentation.pdf" class="btn btn-outline btn-sm">
					<cfoutput>#svgIcon(name="download", size=14)#</cfoutput>
					<span>Download PDF</span>
				</a>
			</div>
		</div>
	</article>

	<!--- 3. Form Builder Guide --->
	<article class="admin-card kb-guide-card">
		<div class="card-body" style="padding:1.35rem; display:flex; align-items:center; justify-content:space-between; gap:1.25rem; flex-wrap:wrap;">
			<div style="max-width:760px;">
				<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.4rem;">
					<span class="badge badge-info">Interactive Forms</span>
					<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted);">Web Walkthrough</span>
				</div>
				<h3 style="font-size:1.05rem; margin:0.3rem 0; color:var(--admin-text-main);">
					Form Builder Guide for Beginners
				</h3>
				<p style="margin:0; color:var(--admin-text-muted); line-height:1.55; font-size:0.9rem;">
					Step-by-step visual tutorial for constructing civic web forms with drag-and-drop field sorting, validation rules, field logic, email notifications, and submission management.
				</p>
			</div>
			<div>
				<a href="<cfoutput>#urlFor(controller='documentation', action='formBuilder')#</cfoutput>" class="btn btn-outline btn-sm">
					<span>Read Guide</span>
					<cfoutput>#svgIcon(name="arrow-right", size=14)#</cfoutput>
				</a>
			</div>
		</div>
	</article>

	<!--- 4. Rich Text Editor (JBDEditor) Guide & Demo --->
	<article class="admin-card kb-guide-card">
		<div class="card-body" style="padding:1.35rem; display:flex; align-items:center; justify-content:space-between; gap:1.25rem; flex-wrap:wrap;">
			<div style="max-width:760px;">
				<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.4rem;">
					<span class="badge badge-success">Content Authoring</span>
					<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted);">Interactive Demo &bull; WCAG Tools</span>
				</div>
				<h3 style="font-size:1.05rem; margin:0.3rem 0; color:var(--admin-text-main);">
					Rich Text Editor (JBDEditor) Guide &amp; Demo
				</h3>
				<p style="margin:0; color:var(--admin-text-muted); line-height:1.55; font-size:0.9rem;">
					Learn how to craft accessible headings, insert and manage tables, embed Media Library images with mandatory alt text, and use keyboard shortcuts across all CMSAdmin editor fields.
				</p>
			</div>
			<div>
				<a href="<cfoutput>#urlFor(controller='documentation', action='editor')#</cfoutput>" class="btn btn-outline btn-sm">
					<span>Read Guide &amp; Demo</span>
					<cfoutput>#svgIcon(name="arrow-right", size=14)#</cfoutput>
				</a>
			</div>
		</div>
	</article>
</section>
