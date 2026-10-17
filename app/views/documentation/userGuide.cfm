<cfset pageTitle = "CMSAdmin 2.0 User Guide (PDF)">

<style>
	.ug-meta-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
		gap: 1rem;
		margin-bottom: 1.25rem;
	}
	.ug-meta-card {
		padding: 1rem 1.25rem;
		background: var(--admin-card-bg, ##ffffff);
		border: 1px solid var(--admin-border, ##e2e8f0);
		border-radius: var(--radius-md, 8px);
	}
	.ug-meta-label {
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		font-weight: 700;
		color: var(--admin-text-muted, ##64748b);
		margin-bottom: 0.35rem;
	}
	.ug-meta-value {
		font-size: 0.95rem;
		font-weight: 600;
		color: var(--admin-text-main, ##0f172a);
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}
	.ug-viewer-container {
		background: var(--admin-card-bg, ##ffffff);
		border: 1px solid var(--admin-border, ##e2e8f0);
		border-radius: var(--radius-md, 8px);
		overflow: hidden;
		box-shadow: var(--shadow-sm, 0 1px 2px 0 rgba(0, 0, 0, 0.05));
	}
	.ug-viewer-toolbar {
		padding: 0.85rem 1.25rem;
		background: var(--admin-bg-subtle, ##f8fafc);
		border-bottom: 1px solid var(--admin-border, ##e2e8f0);
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-wrap: wrap;
		gap: 0.75rem;
	}
	.ug-frame {
		width: 100%;
		height: 850px;
		border: none;
		display: block;
		background: ##525659;
	}
	@media (max-width: 768px) {
		.ug-frame {
			height: 520px;
		}
	}
</style>

<div class="page-header">
	<div>
		<h1 class="page-title">CMSAdmin 2.0 User Guide (PDF)</h1>
		<ol class="breadcrumb" style="margin-top:0.35rem;">
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>">Home</a></li>
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='documentation', action='index')#</cfoutput>">Documentation</a></li>
			<li class="breadcrumb-item active">User Guide PDF</li>
		</ol>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem; flex-wrap:wrap;">
		<a href="<cfoutput>#variables.pdfUrl#</cfoutput>" download="CMSAdmin-2.0-User-Guide.pdf" class="btn btn-primary btn-sm">
			<cfoutput>#svgIcon(name="download", size=14)#</cfoutput>
			<span>Download User Guide (PDF)</span>
		</a>
		<a href="<cfoutput>#variables.pdfUrl#</cfoutput>" target="_blank" rel="noopener" class="btn btn-outline btn-sm">
			<cfoutput>#svgIcon(name="external-link", size=14)#</cfoutput>
			<span>Open in New Tab</span>
		</a>
		<a href="<cfoutput>#variables.systemDocUrl#</cfoutput>" target="_blank" rel="noopener" class="btn btn-outline btn-sm" title="Open Complete System Architecture & Engineering Documentation">
			<cfoutput>#svgIcon(name="book", size=14)#</cfoutput>
			<span>System Blueprint (PDF)</span>
		</a>
	</div>
</div>

<div class="ug-meta-grid">
	<div class="ug-meta-card">
		<div class="ug-meta-label">Document Title</div>
		<div class="ug-meta-value">
			<cfoutput>#svgIcon(name="file-text", size=16)#</cfoutput>
			<span>CMSAdmin 2.0 User Guide</span>
		</div>
	</div>
	<div class="ug-meta-card">
		<div class="ug-meta-label">Format &amp; Size</div>
		<div class="ug-meta-value">
			<span class="badge badge-primary">Adobe PDF</span>
			<span style="font-size:0.85rem; color:var(--admin-text-muted);">489 KB (Complete Edition)</span>
		</div>
	</div>
	<div class="ug-meta-card">
		<div class="ug-meta-label">Target Audience</div>
		<div class="ug-meta-value">
			<cfoutput>#svgIcon(name="users", size=16)#</cfoutput>
			<span>County Staff, PIOs &amp; Editors</span>
		</div>
	</div>
	<div class="ug-meta-card">
		<div class="ug-meta-label">Compliance Standard</div>
		<div class="ug-meta-value">
			<span class="badge badge-success">ADA WCAG 2.1 AA</span>
		</div>
	</div>
</div>

<div class="ug-viewer-container">
	<div class="ug-viewer-toolbar">
		<div style="display:flex; align-items:center; gap:0.6rem;">
			<cfoutput>#svgIcon(name="book", size=18)#</cfoutput>
			<span style="font-weight:600; font-size:0.9rem;">Document Preview</span>
			<span class="badge badge-info" style="font-size:0.7rem;">Official Release</span>
		</div>
		<div style="font-size:0.8rem; color:var(--admin-text-muted);">
			If the PDF does not display directly in your browser, 
			<a href="<cfoutput>#variables.pdfUrl#</cfoutput>" download="CMSAdmin-2.0-User-Guide.pdf" style="color:var(--admin-primary); font-weight:600; text-decoration:underline;">click here to download the file directly</a>.
		</div>
	</div>

	<iframe class="ug-frame" src="<cfoutput>#variables.pdfUrl#</cfoutput>#view=FitH" title="CMSAdmin 2.0 User Guide PDF Document Viewer">
		<p style="padding:2rem; text-align:center; color:var(--admin-text-muted);">
			Your browser does not support embedded PDF viewing. 
			<a href="<cfoutput>#variables.pdfUrl#</cfoutput>" download="CMSAdmin-2.0-User-Guide.pdf" class="btn btn-primary" style="margin-top:1rem;">Download CMSAdmin 2.0 User Guide (PDF)</a>
		</p>
	</iframe>
</div>

