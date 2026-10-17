<cfset pageTitle = "Rich Text Editor (JBDEditor) Guide & Demo">

<style>
	.kb-layout { display:grid; grid-template-columns:minmax(0, 1fr) 250px; gap:1.25rem; align-items:start; }
	.kb-article { min-width:0; }
	.kb-section { padding:1.25rem; margin-bottom:1rem; scroll-margin-top:1rem; }
	.kb-section h2 { font-size:1.15rem; margin:0 0 0.65rem; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem; }
	.kb-section h3 { font-size:0.95rem; margin:1rem 0 0.4rem; color:var(--admin-text-main); }
	.kb-section p, .kb-section li { color:var(--admin-text-muted); line-height:1.6; }
	.kb-section p { margin:0.4rem 0; }
	.kb-section ul, .kb-section ol { padding-left:1.25rem; margin:0.4rem 0; }
	.kb-toc { position:sticky; top:1rem; padding:1rem; }
	.kb-toc a { display:block; padding:0.35rem 0; color:var(--admin-text-muted); text-decoration:none; font-size:0.85rem; }
	.kb-toc a:hover, .kb-toc a:focus { color:var(--admin-primary); text-decoration:underline; }
	.kb-note { border-left:4px solid var(--admin-info); background:var(--admin-info-light); padding:0.85rem 1rem; border-radius:var(--radius-sm); color:var(--admin-text-main); line-height:1.55; margin-top:0.85rem; }
	.kb-success { border-left-color:var(--admin-success); background:var(--admin-success-light, #f0fdf4); }
	.kb-steps { display:grid; grid-template-columns:repeat(3, minmax(0, 1fr)); gap:0.75rem; margin-top:1rem; }
	.kb-step { padding:0.9rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); }
	.kb-step strong { display:block; margin-bottom:0.35rem; color:var(--admin-text-main); }
	.kb-step span { display:block; color:var(--admin-text-muted); font-size:0.85rem; line-height:1.5; }
	.kb-table-wrap { overflow-x:auto; }
	.kb-table { width:100%; border-collapse:collapse; font-size:0.88rem; }
	.kb-table th, .kb-table td { text-align:left; vertical-align:top; padding:0.6rem; border-bottom:1px solid var(--admin-border); }
	.kb-table th { color:var(--admin-text-main); }
	.kb-table td { color:var(--admin-text-muted); }
	.jbd-demo-box { margin-top:1rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); overflow:hidden; }
	@media (max-width: 850px) {
		.kb-layout { grid-template-columns:1fr; }
		.kb-toc { position:static; order:-1; }
		.kb-steps { grid-template-columns:1fr; }
	}
</style>

<div class="page-header">
	<div>
		<h1 class="page-title">Rich Text Editor (JBDEditor) Guide &amp; Demo</h1>
		<ol class="breadcrumb" style="margin-top:0.35rem;">
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='main', action='index')#</cfoutput>">Home</a></li>
			<li class="breadcrumb-item"><a href="<cfoutput>#urlFor(controller='documentation', action='index')#</cfoutput>">Documentation</a></li>
			<li class="breadcrumb-item active">Rich Text Editor Guide &amp; Demo</li>
		</ol>
	</div>
	<div class="page-actions" style="display:flex; gap:0.5rem;">
		<a href="/vendor/jbdeditor/index.html" target="_blank" rel="noopener" class="btn btn-primary btn-sm">
			<cfoutput>#svgIcon(name="external-link", size=14)#</cfoutput>
			<span>Open Standalone Editor</span>
		</a>
		<a href="/vendor/jbdeditor/test.html" target="_blank" rel="noopener" class="btn btn-outline btn-sm">
			<cfoutput>#svgIcon(name="check-circle", size=14)#</cfoutput>
			<span>Run WCAG Test Suite</span>
		</a>
	</div>
</div>

<div class="kb-layout">
	<article class="kb-article">
		<section class="admin-card kb-section" id="overview" aria-labelledby="overviewTitle">
			<h2 id="overviewTitle">
				<cfoutput>#svgIcon(name="edit-3", size=18)#</cfoutput>
				<span>Overview: JBDEditor in CMS Admin</span>
			</h2>
			<p><strong>JBDEditor</strong> is a lightweight, zero-dependency, 100% vanilla JavaScript rich text editor integrated directly into Chelan County CMS Admin 2.0. It is fully compliant with <strong>ADA / WCAG 2.1 &amp; 2.2 AA</strong> accessibility standards.</p>
			
			<div class="kb-steps">
				<div class="kb-step">
					<strong>1. Zero Build Tools</strong>
					<span>Runs natively in modern browsers with pure ES6 JavaScript and CSS. Fully self-contained inside <code>/vendor/jbdeditor/</code> and <code>/javascripts/jbdeditor/</code>.</span>
				</div>
				<div class="kb-step">
					<strong>2. WCAG 2.2 Level AA</strong>
					<span>Full roving tabindex keyboard navigation (Alt+F10, arrow keys, Esc), focus traps in modals, semantic heading order, and screen reader announcements.</span>
				</div>
				<div class="kb-step">
					<strong>3. CMS Integrated</strong>
					<span>Directly connected to the Chelan County Media Library picker, Form Builder embeds, accessible data tables, and LocalStorage draft recovery.</span>
				</div>
			</div>
		</section>

		<section class="admin-card kb-section" id="interactive-demo" aria-labelledby="demoTitle">
			<h2 id="demoTitle">
				<cfoutput>#svgIcon(name="play", size=18)#</cfoutput>
				<span>Live Interactive Editor Demo</span>
			</h2>
			<p>Try out the full rich text editing suite right here inside CMS Admin. Features include text formatting, accessible tables, responsive block templates, color highlights, and full-screen maximize mode.</p>
			
			<div class="jbd-demo-box">
				<textarea id="demoEditorTextarea" data-jbd-editor data-jbd-toolbar="full" data-jbd-inline-toolbar="true" data-jbd-height="320px" data-jbd-placeholder="Start typing rich text here..."><h2>Chelan County Department Notice</h2>
<p>Welcome to the <strong>JBDEditor</strong> rich text suite. You can easily insert formatted announcements, tables with proper accessibility tags, and media library assets.</p>
<table class="jbd-table jbd-table-bordered">
  <caption>Office Hours &amp; Public Services</caption>
  <thead>
    <tr><th scope="col">Service</th><th scope="col">Schedule</th><th scope="col">Location</th></tr>
  </thead>
  <tbody>
    <tr><th scope="row">Public Records</th><td>Mon - Fri: 8am - 5pm</td><td>Level 2, Room 204</td></tr>
    <tr><th scope="row">Permit Center</th><td>Mon - Thu: 8am - 4pm</td><td>Administration Building</td></tr>
  </tbody>
</table>
<div class="jbd-template-callout jbd-callout-info">
  <h4>Public Information Notice</h4>
  <p>All county facilities are ADA accessible. For auxiliary aids or language assistance, please contact the coordinator at least 48 hours in advance.</p>
</div>
<aside class="jbd-template jbd-cta-card" aria-label="Action: Online Service">
  <div class="jbd-cta-card-header">
    <span class="jbd-cta-badge" aria-hidden="true">ONLINE SERVICE</span>
    <p class="jbd-cta-title h4">Apply for Department Permits &amp; Licenses</p>
  </div>
  <p class="jbd-cta-desc">Submit your applications, upload engineering documents, and track review status securely through our citizen portal.</p>
  <div class="jbd-cta-card-footer">
    <a href="##portal" class="jbd-btn jbd-btn-primary jbd-cta-btn" aria-label="Apply online for Department Permits and Licenses">
      <span>Begin Online Application</span>
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
    </a>
  </div>
</aside></textarea>
			</div>

			<div style="margin-top:0.75rem; display:flex; justify-content:space-between; align-items:center;">
				<span style="font-size:0.8rem; color:var(--admin-text-muted);">Changes sync automatically to the underlying textarea.</span>
				<button type="button" class="btn btn-outline btn-sm" id="btnInspectDemoHTML">Inspect Clean HTML</button>
			</div>
			<pre id="demoOutputCode" style="display:none; margin-top:0.75rem; padding:0.85rem; background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.8rem; max-height:200px; overflow:auto;"></pre>
		</section>

		<section class="admin-card kb-section" id="cta-templates" aria-labelledby="ctaTitle">
			<h2 id="ctaTitle">
				<cfoutput>#svgIcon(name="external-link", size=18)#</cfoutput>
				<span>Call to Action (CTA / CTR) Card Patterns</span>
			</h2>
			<p>High-conversion Call to Action cards are essential for civic web pages to guide citizens smoothly toward key services, permit applications, payments, and public records requests.</p>

			<div class="kb-steps">
				<div class="kb-step">
					<strong>Single Action Card (<code>.jbd-cta-card</code>)</strong>
					<span>Focuses reader attention on a single primary goal with a category badge, clear headline, explanatory text, and a prominent 44px touch target button.</span>
				</div>
				<div class="kb-step">
					<strong>2-Column Action Grid (<code>.jbd-cta-grid</code>)</strong>
					<span>Presents paired civic pathways (e.g. "Pay Taxes Online" vs. "Public Records Request") that wrap gracefully into single columns on mobile devices.</span>
				</div>
				<div class="kb-step">
					<strong>Full-Width Banner (<code>.jbd-cta-banner</code>)</strong>
					<span>High-contrast Chelan navy gradient bar designed for end-of-page application steps, office assistance notices, or critical milestones.</span>
				</div>
			</div>

			<div class="kb-note kb-success" style="margin-top:1rem;">
				<strong>ADA Title II &amp; WCAG 2.1 AA Compliant:</strong>
				CTA cards use styled <code>&lt;p class="jbd-cta-title h4"&gt;</code> elements so they never skip or disrupt the page's heading hierarchy during automated accessibility audits. Buttons include descriptive <code>aria-label</code> tags, high-contrast focus rings (minimum 3:1 ratio), and full Windows High Contrast Mode support.
			</div>
		</section>

		<section class="admin-card kb-section" id="keyboard-shortcuts" aria-labelledby="shortcutsTitle">
			<h2 id="shortcutsTitle">
				<cfoutput>#svgIcon(name="command", size=18)#</cfoutput>
				<span>Accessibility &amp; Keyboard Shortcuts</span>
			</h2>
			<div class="kb-table-wrap">
				<table class="kb-table">
					<thead>
						<tr>
							<th scope="col">Shortcut</th>
							<th scope="col">Action</th>
							<th scope="col">Description</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td><kbd>Alt + F10</kbd></td>
							<td>Focus Toolbar</td>
							<td>Jumps focus directly to the first button in the editor toolbar or floating bubble.</td>
						</tr>
						<tr>
							<td><kbd>&larr;</kbd> / <kbd>&rarr;</kbd></td>
							<td>Navigate Controls</td>
							<td>Cycles focus across toolbar groups using roving tabindex without submitting forms.</td>
						</tr>
						<tr>
							<td><kbd>Esc</kbd></td>
							<td>Exit / Close</td>
							<td>Closes open modal dialogs, color popovers, or full-screen maximize mode.</td>
						</tr>
						<tr>
							<td><kbd>Ctrl + B</kbd></td>
							<td>Bold</td>
							<td>Toggles bold text weighting.</td>
						</tr>
						<tr>
							<td><kbd>Ctrl + I</kbd></td>
							<td>Italic</td>
							<td>Toggles italic styling.</td>
						</tr>
						<tr>
							<td><kbd>Ctrl + U</kbd></td>
							<td>Underline</td>
							<td>Toggles underline text decoration.</td>
						</tr>
						<tr>
							<td><kbd>Ctrl + F</kbd></td>
							<td>Find &amp; Replace</td>
							<td>Opens the accessible Find and Replace modal with count indicator.</td>
						</tr>
						<tr>
							<td><kbd>Ctrl + Z</kbd> / <kbd>Ctrl + Y</kbd></td>
							<td>Undo / Redo</td>
							<td>Steps backward and forward through editorial history.</td>
						</tr>
					</tbody>
				</table>
			</div>
		</section>

		<section class="admin-card kb-section" id="app-integration" aria-labelledby="integrationTitle">
			<h2 id="integrationTitle">
				<cfoutput>#svgIcon(name="code", size=18)#</cfoutput>
				<span>Integration Methods in CMS Admin</span>
			</h2>
			<p>JBDEditor supports both automatic zero-configuration initialization and programmatic attachment:</p>

			<h3>Method 1: Zero-JS Declarative (Automatic)</h3>
			<p>Simply add the <code>data-jbd-editor</code> attribute to any <code>&lt;textarea&gt;</code> in your view:</p>
			<pre style="padding:0.85rem; background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.8rem; overflow-x:auto;"><code>&lt;textarea 
  data-jbd-editor 
  data-jbd-toolbar="full" 
  data-jbd-height="380px" 
  name="content"&gt;Initial document content...&lt;/textarea&gt;</code></pre>

			<h3>Method 2: Programmatic JavaScript</h3>
			<pre style="padding:0.85rem; background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-md); font-size:0.8rem; overflow-x:auto;"><code>const editor = JBDEditor.attach('##myTextarea', {
  toolbar: 'article', // 'full' | 'basic' | 'minimal' | 'article'
  inlineToolbar: true,
  height: '400px',
  autoSaveKey: 'my_draft_key',
  onChange: (html, text) => {
    console.log('Words:', text.split(/\s+/).length);
  }
});</code></pre>
		</section>
	</article>

	<nav class="admin-card kb-toc" aria-label="Table of contents">
		<strong style="display:block; margin-bottom:0.5rem; font-size:0.85rem; color:var(--admin-text-main);">On This Page</strong>
		<a href="#overview">Overview</a>
		<a href="#interactive-demo">Live Interactive Demo</a>
		<a href="#cta-templates">Call to Action (CTA) Cards</a>
		<a href="#keyboard-shortcuts">Keyboard Shortcuts</a>
		<a href="#app-integration">Integration Methods</a>
		<hr style="margin:0.75rem 0; border:none; border-top:1px solid var(--admin-border);">
		<div style="font-size:0.75rem; color:var(--admin-text-muted);">
			Standalone Files:<br>
			&bull; <code>/vendor/jbdeditor/</code><br>
			&bull; <code>/javascripts/jbdeditor/</code><br>
			&bull; <code>/stylesheets/jbdeditor.css</code>
		</div>
	</nav>
</div>

<script>
	document.addEventListener('DOMContentLoaded', function() {
		var btnInspect = document.getElementById('btnInspectDemoHTML');
		var outPre = document.getElementById('demoOutputCode');
		if (btnInspect && outPre) {
			btnInspect.addEventListener('click', function() {
				var editor = (typeof JBDEditor !== 'undefined') ? JBDEditor.get('#demoEditorTextarea') : null;
				var html = editor ? editor.getHTML() : document.getElementById('demoEditorTextarea').value;
				outPre.textContent = html;
				outPre.style.display = (outPre.style.display === 'none') ? 'block' : 'none';
				btnInspect.textContent = (outPre.style.display === 'none') ? 'Inspect Clean HTML' : 'Hide HTML Source';
			});
		}
	});
</script>

