<cfoutput>
<div class="page-header d-flex justify-content-between align-items-center mb-4" style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; flex-wrap:wrap; margin-bottom:1.5rem;">
	<div>
		<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.35rem; flex-wrap:wrap;">
			<span class="badge badge-primary" style="font-size:0.72rem; text-transform:uppercase; letter-spacing:0.05em;">Settings &bull; Startup</span>
			<span class="badge badge-success" style="font-size:0.72rem;">Bootstrap 5 Compatible</span>
			<span class="badge badge-neutral" style="font-size:0.72rem;">WCAG 2.1 AA Compliant</span>
			<span class="badge badge-info" style="font-size:0.72rem;">v2.3 Updated</span>
		</div>
		<h1 class="page-title" style="margin:0; font-size:1.5rem; font-weight:700;">Front-End Startup &amp; Template Styles (<code>jbd-templates.css</code>)</h1>
		<p class="text-muted" style="margin:0.35rem 0 0; color:var(--admin-text-muted); font-size:0.92rem;">
			The public front-end is full Bootstrap-themed. Import the standalone <code>jbd-templates.css</code> stylesheet in your front-end layout so all JBDEditor content blocks, subpage templates, callouts, and non-heading typography (<code>.h4</code>) render identically outside the admin editor.
		</p>
	</div>
	<div style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="/stylesheets/jbd-templates.css" download="jbd-templates.css" class="btn btn-primary" style="display:inline-flex; align-items:center; gap:0.45rem;">
			#svgIcon(name="download", size=16)#
			<span>Download <code>jbd-templates.css</code></span>
		</a>
	</div>
</div>

<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(340px, 1fr)); gap:1.25rem; margin-bottom:1.5rem;">
	<!--- Step 1: CFWheels / ColdFusion Layout Import --->
	<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface);">
		<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
			<h2 style="margin:0; font-size:1rem; font-weight:700; display:flex; align-items:center; gap:0.5rem;">
				<span style="width:24px; height:24px; border-radius:50%; background:var(--admin-primary); color:##fff; display:inline-flex; align-items:center; justify-content:center; font-size:0.78rem; font-weight:700;">1</span>
				<span>Front-End Layout Startup Import (CFWheels)</span>
			</h2>
			<button type="button" class="btn btn-outline btn-sm" onclick="copyCodeBlock('cfwheelsImportSnippet', this)">Copy</button>
		</div>
		<p style="font-size:0.85rem; color:var(--admin-text-muted); margin-bottom:0.75rem;">
			Place <code>jbd-templates.css</code> in your front-end <code>/stylesheets/</code> folder and include it after Bootstrap 5 in <code>app/views/layout.cfm</code>:
		</p>
		<pre id="cfwheelsImportSnippet" style="margin:0; padding:0.85rem 1rem; background:##0f172a; color:##e2e8f0; border-radius:8px; font-size:0.82rem; overflow-x:auto; line-height:1.55;"><code>&lt;!-- Bootstrap 5.3+ (Front-End Base Theme) --&gt;
&lt;link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap.min.css"&gt;

&lt;!-- CFWheels Stylesheets --&gt;
##styleSheetLinkTag(source="styles.css", head="true")##
##styleSheetLinkTag(source="custom.css", head="true")##
##styleSheetLinkTag(source="jbd-templates.css", head="true")##</code></pre>
	</div>

	<!--- Step 2: Standard HTML <link> or CSS @import --->
	<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface);">
		<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem;">
			<h2 style="margin:0; font-size:1rem; font-weight:700; display:flex; align-items:center; gap:0.5rem;">
				<span style="width:24px; height:24px; border-radius:50%; background:var(--admin-primary); color:##fff; display:inline-flex; align-items:center; justify-content:center; font-size:0.78rem; font-weight:700;">2</span>
				<span>Standard HTML <code>&lt;link&gt;</code> or CSS <code>@import</code></span>
			</h2>
			<button type="button" class="btn btn-outline btn-sm" onclick="copyCodeBlock('htmlImportSnippet', this)">Copy</button>
		</div>
		<p style="font-size:0.85rem; color:var(--admin-text-muted); margin-bottom:0.75rem;">
			Or import the whole <code>jbd-templates.css</code> directly inside your front-end <code>&lt;head&gt;</code> or main stylesheet:
		</p>
		<pre id="htmlImportSnippet" style="margin:0; padding:0.85rem 1rem; background:##0f172a; color:##e2e8f0; border-radius:8px; font-size:0.82rem; overflow-x:auto; line-height:1.55;"><code>&lt;!-- Direct HTML Head Link --&gt;
&lt;link rel="stylesheet" href="/stylesheets/jbd-templates.css" media="all"&gt;

/* Or inside your front-end custom.css / styles.css */
@import url("/stylesheets/jbd-templates.css");</code></pre>
	</div>
</div>

<!--- Full Isolated CSS File Viewer --->
<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface);">
	<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.75rem; margin-bottom:0.85rem;">
		<div>
			<h2 style="margin:0; font-size:1.05rem; font-weight:700;">Isolated Stylesheet Source: <code>/stylesheets/jbd-templates.css</code></h2>
			<p style="margin:0.2rem 0 0; font-size:0.83rem; color:var(--admin-text-muted);">
				Unscoped from <code>.jbd-editor-content</code> so all <code>.jbd-template</code> blocks (Callouts, Panels, TOC, Subpage Menu, Related Pages, Related Links, References, Contact Cards, Grids, Hero, Quotes, FAQ, Steps/Timeline, Tables &amp; Figures) work seamlessly on any Bootstrap front-end page while hiding editor-only action buttons.
			</p>
		</div>
		<div style="display:flex; gap:0.5rem;">
			<button type="button" class="btn btn-outline btn-sm" onclick="copyCodeBlock('fullJbdTemplateCss', this)">
				Copy Full <code>jbd-templates.css</code>
			</button>
			<a href="/stylesheets/jbd-templates.css" target="_blank" class="btn btn-outline btn-sm">Open Raw .css</a>
		</div>
	</div>

	<pre id="fullJbdTemplateCss" style="margin:0; padding:1rem; background:##0f172a; color:##f8fafc; border-radius:8px; font-size:0.8rem; max-height:520px; overflow:auto; line-height:1.5;"><code>#encodeForHtml(jbdTemplateCssContent)#</code></pre>
</div>

<script>
function copyCodeBlock(elementId, btn) {
	var el = document.getElementById(elementId);
	if (!el) return;
	var text = el.innerText || el.textContent;
	navigator.clipboard.writeText(text).then(function() {
		var original = btn.innerHTML;
		btn.textContent = "Copied!";
		setTimeout(function() {
			btn.innerHTML = original;
		}, 1800);
	});
}
</script>
</cfoutput>

