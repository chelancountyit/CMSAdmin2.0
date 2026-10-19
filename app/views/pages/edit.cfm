<cfoutput>
<cfscript>
	folderAttachedHere = false;
	for (folderCheck in availableFolders) {
		if (Val(folderCheck.contentId ?: 0) == Val(page.id)) { folderAttachedHere = true; break; }
	}
</cfscript>
<!--- CMS Admin 2.0 - Add / Edit Page (mockup) --->
<style>
	.pg-edit-grid { display:grid; grid-template-columns:minmax(0,1fr) 320px; gap:1.25rem; align-items:start; }
	.pg-side-col { align-self:stretch; display:flex; flex-direction:column; gap:1.25rem; }
	.pg-publish-sticky { position:sticky; top:calc(var(--header-height, 64px) + 1.25rem); z-index:10; }
	@media (max-width: 1100px) {
		.pg-edit-grid { grid-template-columns:1fr; }
		.pg-publish-sticky { position:static; }
	}
	.pg-field { margin-bottom:1.1rem; }
	.pg-field:last-child { margin-bottom:0; }
	.pg-help { font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.3rem; }
	.pg-toolbar { display:flex; flex-wrap:wrap; gap:2px; padding:0.4rem; border:1.5px solid var(--admin-border-input); border-bottom:none; border-radius:var(--radius-md) var(--radius-md) 0 0; background:var(--admin-bg); }
	.pg-toolbar button { background:transparent; border:1px solid transparent; border-radius:var(--radius-sm); padding:0.3rem 0.55rem; font-size:0.8rem; font-weight:600; color:var(--admin-text-main); cursor:pointer; }
	.pg-toolbar button:hover { background:var(--admin-surface); border-color:var(--admin-border); }
	.pg-toolbar .sep { width:1px; background:var(--admin-border); margin:0.2rem 0.3rem; }
	.pg-editor { width:100%; min-height:360px; border-radius:0 0 var(--radius-md) var(--radius-md) !important; font-family:inherit; line-height:1.6; resize:vertical; padding:0.85rem 1rem; }
	.pg-slug-wrap { display:flex; align-items:center; border:1.5px solid var(--admin-border-input); border-radius:var(--radius-md); overflow:hidden; }
	.pg-slug-wrap span { padding:0.5rem 0.65rem; background:var(--admin-bg); color:var(--admin-text-muted); font-size:0.8rem; border-right:1px solid var(--admin-border); white-space:nowrap; }
	.pg-slug-wrap input { border:none !important; flex:1; min-width:0; }
	.pg-meta-row { display:flex; justify-content:space-between; font-size:0.8rem; padding:0.4rem 0; border-bottom:1px solid var(--admin-border-subtle); }
	.pg-meta-row:last-child { border-bottom:none; }
	.pg-meta-row dt { color:var(--admin-text-muted); }
	.pg-meta-row dd { margin:0; font-weight:600; color:var(--admin-text-main); }
	##pgFolderListingItems [data-folder-title] { font-size:0.875rem; }
	.pg-subpage-modal { position:fixed; inset:0; z-index:99999; display:none; align-items:center; justify-content:center; padding:1rem; }
	.pg-subpage-modal.is-open { display:flex; }
	.pg-subpage-backdrop { position:absolute; inset:0; background:rgba(15,23,42,0.72); backdrop-filter:blur(6px); -webkit-backdrop-filter:blur(6px); }
	.pg-subpage-window { position:relative; width:min(100%, 720px); max-height:min(92vh, 850px); overflow:auto; background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); }
	.pg-subpage-row { display:flex; align-items:center; gap:0.75rem; padding:0.65rem 0; border-bottom:1px solid var(--admin-border-subtle); }
	.pg-subpage-row > label { display:flex; align-items:flex-start; gap:0.65rem; flex:1; min-width:0; cursor:pointer; }
	.fe-layout-card { border:2px solid var(--admin-border, ##cbd5e1); border-radius:var(--radius-md, 0.5rem); padding:0.85rem; cursor:pointer; background:var(--admin-surface, ##ffffff); transition:all 0.15s ease; outline:none; }
	.fe-layout-card:hover { border-color:var(--admin-border-hover, ##94a3b8); }
	.fe-layout-card:focus-visible { outline:2px solid var(--admin-primary) !important; outline-offset:2px !important; }
	.fe-layout-card.is-selected { border-color:var(--admin-primary) !important; background:rgba(30, 58, 138, 0.04) !important; box-shadow:0 0 0 1px var(--admin-primary); }
	.pg-meta-grid { display:grid; grid-template-columns:minmax(0, 6fr) minmax(0, 6fr); gap:1.25rem; align-items:start; }
	@media (max-width: 768px) { .pg-meta-grid { grid-template-columns:1fr; } }
	.pg-attr-tabs { display:inline-flex; background:var(--admin-bg, ##f1f5f9); border:1px solid var(--admin-border, ##cbd5e1); border-radius:var(--radius-md, 0.5rem); padding:0.18rem; gap:0.18rem; }
	.pg-attr-tab { display:inline-flex; align-items:center; gap:0.35rem; padding:0.32rem 0.7rem; font-size:0.78rem; font-weight:600; border:none; border-radius:var(--radius-sm, 0.375rem); background:transparent; color:var(--admin-text-muted, ##475569); cursor:pointer; transition:all 0.15s ease; }
	.pg-attr-tab:hover { color:var(--admin-text-main, ##0f172a); }
	.pg-attr-tab.is-active { background:var(--admin-surface, ##ffffff); color:var(--admin-primary, ##0284c7); box-shadow:0 1px 2px rgba(15, 23, 42, 0.08); }

	/* ----------------------------------------------------
	   Feature 2.2: Page Revision History & Rollback Studio
	   ---------------------------------------------------- */
	##pgRevisionsModalBackdrop { position:fixed; inset:0; z-index:9988; background:rgba(15,23,42,0.72); backdrop-filter:blur(6px); -webkit-backdrop-filter:blur(6px); }
	##pgRevisionsModal { position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:9990; width:min(96vw, 1340px); height:min(90vh, 900px); background:var(--admin-surface, ##ffffff); border-radius:var(--radius-lg, 0.75rem); box-shadow:0 25px 70px rgba(15,23,42,0.4); border:1px solid var(--admin-border, ##cbd5e1); display:flex; flex-direction:column; overflow:hidden; }
	.rev-layout { display:grid; grid-template-columns:340px minmax(0, 1fr); flex:1; min-height:0; overflow:hidden; }
	@media (max-width: 900px) { .rev-layout { grid-template-columns:1fr; } }
	.rev-sidebar { border-right:1px solid var(--admin-border-subtle, ##e2e8f0); background:var(--admin-bg, ##f8fafc); display:flex; flex-direction:column; min-height:0; }
	.rev-sidebar-header { padding:0.85rem 1.1rem; border-bottom:1px solid var(--admin-border-subtle, ##e2e8f0); display:flex; justify-content:space-between; align-items:center; }
	.rev-list { flex:1; overflow-y:auto; padding:0.75rem; display:flex; flex-direction:column; gap:0.5rem; }
	.rev-item-card { border:1.5px solid var(--admin-border, ##cbd5e1); border-radius:var(--radius-md, 0.5rem); padding:0.75rem 0.9rem; background:var(--admin-surface, ##ffffff); cursor:pointer; transition:all 0.15s ease; text-align:left; width:100%; display:block; position:relative; }
	.rev-item-card:hover { border-color:var(--admin-primary, ##0284c7); box-shadow:0 2px 6px rgba(15,23,42,0.06); }
	.rev-item-card:focus-visible { outline:2px solid var(--admin-primary) !important; outline-offset:2px; }
	.rev-item-card.is-active { border-color:var(--admin-primary, ##0284c7); background:rgba(2, 132, 199, 0.05); box-shadow:0 0 0 1px var(--admin-primary, ##0284c7); }
	.rev-item-version { font-weight:700; font-size:0.88rem; color:var(--admin-text-main, ##0f172a); display:flex; align-items:center; justify-content:space-between; }
	.rev-item-meta { font-size:0.75rem; color:var(--admin-text-muted, ##64748b); margin-top:0.25rem; display:flex; align-items:center; gap:0.35rem; }
	.rev-item-note { font-size:0.8rem; color:var(--admin-text-main, ##334155); margin-top:0.4rem; line-height:1.35; word-break:break-word; }
	.rev-stage { display:flex; flex-direction:column; flex:1; min-height:0; overflow:hidden; background:var(--admin-surface, ##ffffff); }
	.rev-stage-toolbar { padding:0.75rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle, ##e2e8f0); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.75rem; background:var(--admin-bg, ##f8fafc); }
	.rev-stage-body { flex:1; min-height:0; overflow:auto; padding:1.25rem; }
	.diff-pane { background:var(--admin-surface, ##ffffff); border:1px solid var(--admin-border, ##cbd5e1); border-radius:var(--radius-md, 0.5rem); padding:1.25rem; min-height:100%; line-height:1.65; font-size:0.95rem; }
	.diff-split-grid { display:grid; grid-template-columns:1fr 1fr; gap:1rem; height:100%; min-height:0; }
	@media (max-width: 800px) { .diff-split-grid { grid-template-columns:1fr; } }
	.diff-split-col { display:flex; flex-direction:column; min-height:0; height:100%; }
	.diff-split-col-header { font-size:0.78rem; font-weight:700; text-transform:uppercase; letter-spacing:0.04em; color:var(--admin-text-muted, ##64748b); padding:0.4rem 0.6rem; border-bottom:2px solid var(--admin-border, ##cbd5e1); margin-bottom:0.5rem; display:flex; justify-content:space-between; align-items:center; }
	.diff-split-col-body { flex:1; overflow:auto; border:1px solid var(--admin-border, ##cbd5e1); border-radius:var(--radius-md, 0.5rem); padding:1rem; background:var(--admin-surface, ##ffffff); }
	.diff-add { background:rgba(34, 197, 94, 0.18) !important; color:##15803d !important; text-decoration:none !important; border-bottom:2px solid ##22c55e !important; padding:1px 3px; border-radius:2px; font-weight:600; }
	.diff-del { background:rgba(239, 68, 68, 0.18) !important; color:##b91c1c !important; text-decoration:line-through !important; border-bottom:2px solid ##ef4444 !important; padding:1px 3px; border-radius:2px; opacity:0.85; }
	.diff-stat-pill { display:inline-flex; align-items:center; gap:0.25rem; font-size:0.75rem; font-weight:700; padding:0.2rem 0.55rem; border-radius:9999px; }
	.diff-stat-pill.add { background:rgba(34, 197, 94, 0.12); color:##15803d; }
	.diff-stat-pill.del { background:rgba(239, 68, 68, 0.12); color:##b91c1c; }
	.diff-code-view { font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; font-size:0.84rem; white-space:pre-wrap; word-break:break-all; }

	/* ----------------------------------------------------
	   Feature 2.3: In-Editor Automated ADA WCAG Pre-Flight Linter
	   ---------------------------------------------------- */
	.pg-a11y-linter-bar {
		background: var(--admin-surface, ##ffffff);
		border: 1.5px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem) var(--radius-md, 0.5rem) 0 0;
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
		margin-bottom: 0;
		overflow: hidden;
		transition: all 0.2s ease;
	}
	.pg-a11y-linter-bar.is-passed {
		border-color: var(--admin-border, ##cbd5e1);
		background: var(--admin-surface, ##ffffff);
	}
	.pg-a11y-linter-bar.has-warnings {
		border-color: ##f59e0b;
		background: ##fffdfa;
	}
	.pg-a11y-linter-bar.has-errors {
		border-color: ##ef4444;
		background: ##fef8f8;
	}
	.pg-a11y-bar-main {
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-wrap: wrap;
		gap: 0.65rem;
		padding: 0.55rem 0.85rem;
	}
	.pg-a11y-bar-title-wrap {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		flex-shrink: 0;
	}
	.pg-a11y-bar-icon {
		color: var(--admin-primary, ##0284c7);
		display: inline-flex;
	}
	.pg-a11y-bar-title {
		font-size: 0.84rem;
		font-weight: 700;
		color: var(--admin-text-main, ##0f172a);
		letter-spacing: -0.01em;
	}
	.pg-a11y-standard-badge {
		font-size: 0.68rem;
		font-weight: 700;
		padding: 0.1rem 0.35rem;
		border-radius: 3px;
		background: var(--admin-bg, ##f1f5f9);
		color: var(--admin-text-muted, ##475569);
		border: 1px solid var(--admin-border-subtle, ##e2e8f0);
	}
	.pg-a11y-category-chips {
		display: flex;
		align-items: center;
		gap: 0.35rem;
		flex-wrap: wrap;
	}
	.pg-a11y-chip {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		padding: 0.2rem 0.55rem;
		font-size: 0.74rem;
		font-weight: 600;
		border-radius: 9999px;
		background: var(--admin-bg, ##f8fafc);
		border: 1px solid var(--admin-border-subtle, ##e2e8f0);
		color: var(--admin-text-muted, ##64748b);
		cursor: pointer;
		transition: all 0.15s ease;
	}
	.pg-a11y-chip:hover {
		background: var(--admin-surface, ##ffffff);
		border-color: var(--admin-border-hover, ##94a3b8);
		color: var(--admin-text-main, ##0f172a);
	}
	.pg-a11y-chip.is-active-filter {
		background: rgba(2, 132, 199, 0.1);
		border-color: var(--admin-primary, ##0284c7);
		color: var(--admin-primary, ##0284c7);
	}
	.pg-a11y-chip .chip-count {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-size: 0.68rem;
		padding: 0 0.35rem;
		height: 16px;
		min-width: 16px;
		border-radius: 9999px;
		background: ##e2e8f0;
		color: ##475569;
		font-weight: 700;
	}
	.pg-a11y-chip.has-error {
		border-color: ##fca5a5;
		background: ##fef2f2;
		color: ##b91c1c;
	}
	.pg-a11y-chip.has-error .chip-count {
		background: ##ef4444;
		color: ##ffffff;
	}
	.pg-a11y-chip.has-warn {
		border-color: ##fde68a;
		background: ##fffbeb;
		color: ##b45309;
	}
	.pg-a11y-chip.has-warn .chip-count {
		background: ##f59e0b;
		color: ##ffffff;
	}
	.pg-a11y-bar-actions {
		display: flex;
		align-items: center;
		gap: 0.35rem;
		flex-shrink: 0;
	}
	.pg-a11y-drawer {
		border-top: 1px solid var(--admin-border-subtle, ##e2e8f0);
		background: var(--admin-surface, ##ffffff);
		padding: 0.85rem 1rem;
		max-height: 480px;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}
	.pg-a11y-drawer[hidden] {
		display: none !important;
	}
	.pg-a11y-drawer-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding-bottom: 0.65rem;
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
	}
	.pg-a11y-issues-list {
		display: flex;
		flex-direction: column;
		gap: 0.65rem;
	}
	.pg-a11y-issue-card {
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		padding: 0.75rem 0.85rem;
		background: var(--admin-surface, ##ffffff);
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
		transition: all 0.15s ease;
	}
	.pg-a11y-issue-card.is-error {
		border-left: 4px solid ##ef4444;
		background: ##fffbfb;
	}
	.pg-a11y-issue-card.is-warn {
		border-left: 4px solid ##f59e0b;
		background: ##fffdf9;
	}
	.pg-a11y-issue-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 0.5rem;
	}
	.pg-a11y-rule-tag {
		font-size: 0.72rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		padding: 0.12rem 0.45rem;
		border-radius: 3px;
	}
	.pg-a11y-rule-tag.error { background: ##fee2e2; color: ##b91c1c; }
	.pg-a11y-rule-tag.warn { background: ##fef3c7; color: ##b45309; }
	.pg-a11y-issue-msg {
		font-size: 0.84rem;
		font-weight: 600;
		color: var(--admin-text-main, ##0f172a);
		line-height: 1.35;
	}
	.pg-a11y-issue-code {
		font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
		font-size: 0.78rem;
		background: var(--admin-bg, ##f1f5f9);
		border: 1px solid var(--admin-border-subtle, ##e2e8f0);
		border-radius: 4px;
		padding: 0.35rem 0.6rem;
		color: ##334155;
		word-break: break-all;
		white-space: pre-wrap;
	}
	.pg-a11y-issue-suggestion {
		font-size: 0.78rem;
		color: var(--admin-text-muted, ##475569);
		line-height: 1.4;
	}
	.pg-a11y-issue-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-top: 0.25rem;
		flex-wrap: wrap;
	}
	.pg-a11y-publish-widget {
		background: var(--admin-surface, ##ffffff);
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-sm, 0.375rem);
		padding: 0.75rem;
		margin-bottom: 0.85rem;
	}
	.pg-a11y-pub-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 0.35rem;
	}
	@keyframes a11yHighlightPulse {
		0% { outline: 3px solid ##ef4444; box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.4); }
		50% { outline: 3px solid ##f59e0b; box-shadow: 0 0 0 8px rgba(245, 158, 11, 0.3); }
		100% { outline: 3px solid ##ef4444; box-shadow: 0 0 0 4px rgba(239, 68, 68, 0); }
	}
	.jbd-a11y-pulse {
		animation: a11yHighlightPulse 1.2s ease-in-out 3;
		border-radius: 4px;
	}

	/* ----------------------------------------------------
	   Feature 2.6: Document to WCAG AA Converter Studio
	   ---------------------------------------------------- */
	.pg-doc-drop-zone-wrap {
		position: relative;
	}
	.pg-doc-drop-overlay {
		position: absolute;
		inset: 0;
		z-index: 50;
		background: rgba(255, 255, 255, 0.96);
		backdrop-filter: blur(4px);
		border: 2.5px dashed var(--admin-primary, ##0284c7);
		border-radius: var(--radius-md, 0.5rem);
		display: none;
		align-items: center;
		justify-content: center;
		padding: 1.5rem;
		text-align: center;
		transition: all 0.2s ease;
		pointer-events: none;
	}
	.pg-doc-drop-overlay.is-active {
		display: flex;
	}
	.pg-doc-drop-inner {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.45rem;
		max-width: 440px;
	}
	.pg-doc-drop-icon {
		width: 52px;
		height: 52px;
		border-radius: 50%;
		background: rgba(2, 132, 199, 0.12);
		color: var(--admin-primary, ##0284c7);
		display: flex;
		align-items: center;
		justify-content: center;
		animation: docDropBounce 1s infinite alternate ease-in-out;
		margin-bottom: 0.25rem;
	}
	@keyframes docDropBounce {
		from { transform: translateY(0); }
		to { transform: translateY(-6px); }
	}
	.pg-doc-drop-title {
		font-size: 1.05rem;
		font-weight: 700;
		color: var(--admin-text-main, ##0f172a);
	}
	.pg-doc-drop-sub {
		font-size: 0.8rem;
		color: var(--admin-text-muted, ##64748b);
		line-height: 1.35;
	}
	##pgDocConvertModalBackdrop {
		position: fixed;
		inset: 0;
		z-index: 99990;
		background: rgba(15, 23, 42, 0.72);
		backdrop-filter: blur(6px);
		-webkit-backdrop-filter: blur(6px);
	}
	##pgDocConvertModal {
		position: fixed;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		z-index: 99992;
		width: min(94vw, 860px);
		max-height: min(90vh, 880px);
		background: var(--admin-surface, ##ffffff);
		border-radius: var(--radius-lg, 0.75rem);
		box-shadow: 0 25px 70px rgba(15, 23, 42, 0.4);
		border: 1px solid var(--admin-border, ##cbd5e1);
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	.doc-dropzone-box {
		border: 2px dashed var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		padding: 1.75rem 1.25rem;
		text-align: center;
		cursor: pointer;
		background: var(--admin-bg, ##f8fafc);
		transition: all 0.2s ease;
	}
	.doc-dropzone-box:hover, .doc-dropzone-box.is-dragover {
		border-color: var(--admin-primary, ##0284c7);
		background: rgba(2, 132, 199, 0.04);
	}
	.doc-kpi-card {
		padding: 0.75rem 0.9rem;
		border-radius: var(--radius-md, 0.5rem);
		background: var(--admin-surface, ##ffffff);
		border: 1px solid var(--admin-border, ##cbd5e1);
		text-align: center;
	}
	.doc-kpi-value {
		font-size: 1.35rem;
		font-weight: 700;
		color: var(--admin-text-main, ##0f172a);
	}
	.doc-kpi-label {
		font-size: 0.72rem;
		color: var(--admin-text-muted, ##64748b);
		text-transform: uppercase;
		letter-spacing: 0.04em;
		font-weight: 600;
	}
	##docPreviewVisual table {
		width: 100%;
		border-collapse: collapse;
		margin: 1rem 0;
	}
	##docPreviewVisual th, ##docPreviewVisual td {
		border: 1px solid var(--admin-border, ##cbd5e1);
		padding: 0.5rem 0.75rem;
		text-align: left;
	}
	##docPreviewVisual th {
		background: var(--admin-bg, ##f8fafc);
		font-weight: 700;
	}
	##docPreviewVisual img {
		max-width: 100%;
		height: auto;
		display: block;
		margin: 0.75rem 0;
	}
	##docPreviewVisual hr {
		border: none;
		border-top: 1px solid var(--admin-border, ##cbd5e1);
		margin: 1.25rem 0;
	}
	##docPreviewVisual blockquote {
		margin: 1rem 0;
		padding: 0.5rem 1rem;
		border-left: 3px solid var(--admin-primary, ##0284c7);
		background: rgba(2, 132, 199, 0.04);
	}
</style>

<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">#isNew ? "Add Page" : "Edit Page"#</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='pages', action='index')#">Pages</a></li>
				<li class="breadcrumb-item active" aria-current="page" id="pgBreadcrumbTitle">#isNew ? "Add Page" : EncodeForHTML(page.title)#</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions">
		<a href="#urlFor(controller='pages', action='index')#" class="btn btn-outline btn-sm">
			#svgIcon(name="list", size=14)#
			<span>All Pages</span>
		</a>
		<cfif not isNew>
			<button type="button" class="btn btn-outline btn-sm" id="btnOpenRevisions" aria-haspopup="dialog" title="View historical snapshots & compare differences (RCW 42.56 compliance)">
				#svgIcon(name="clock", size=14)#
				<span>Revisions</span>
				<span class="badge badge-neutral" id="pgHeaderRevCount" style="margin-left:4px; font-size:0.75rem; font-weight:700;">#Val(revisionCount)#</span>
			</button>
			<a href="/#EncodeForHTMLAttribute(page.slug)#" id="btnViewLivePage" target="_blank" rel="noopener" class="btn btn-secondary btn-sm">
				#svgIcon(name="eye", size=14)#
				<span>View Live<span class="sr-only"> (opens in new tab)</span></span>
			</a>
		</cfif>
	</div>
</div>

<div id="pgSaveStatus" role="status" aria-live="polite" class="sr-only"></div>

<cfif structKeyExists(params, "created") and params.created eq 1>
	<div class="alert alert-success" role="status" style="margin-bottom:1.25rem; display:flex; align-items:center; gap:0.75rem;">
		#svgIcon(name="check-circle", size=20)#
		<div>
			<strong>Page created &amp; saved to database:</strong> &ldquo;<strong>#EncodeForHTML(page.title)#</strong>&rdquo; (ID: #Val(page.id)#) with <strong>#EncodeForHTML(page.layout)#</strong> layout. You are now editing this page in <strong>Edit mode</strong>.
		</div>
	</div>
<cfelseif isNew and Len(Trim(page.title))>
	<div class="alert alert-info" role="status" style="margin-bottom:1.25rem; display:flex; align-items:center; gap:0.75rem;">
		#svgIcon(name="info", size=20)#
		<div>
			<strong>Page initialized:</strong> &ldquo;<strong>#EncodeForHTML(page.title)#</strong>&rdquo; with <strong>#EncodeForHTML(page.layout)#</strong> layout. Configure your content, widgets, and sidebars below, then click Save.
		</div>
	</div>
</cfif>

<form id="pageEditForm" class="pg-edit-grid" novalidate onsubmit="return false;">
	<input type="hidden" id="pgContentId" name="contentId" value="#Val(page.id)#">
	<!--- Main column --->
	<div style="display:flex; flex-direction:column; gap:1.25rem;">
		<div class="admin-card" style="margin-bottom:0;">
			<div class="card-body">
				<div class="pg-field">
					<label for="pgTitle" class="form-label">Page Title <span aria-hidden="true" style="color:var(--admin-danger);">*</span><span class="sr-only"> (required)</span></label>
					<input type="text" id="pgTitle" name="title" class="form-control" required aria-required="true" value="#EncodeForHTMLAttribute(page.title)#" placeholder="e.g. Title VI Plan" style="width:100%; font-size:1.05rem; font-weight:600;">
				</div>
				<div class="pg-field">
					<label for="pgSlug" class="form-label">Page URL</label>
					<cfscript>
						editWsObj = resolveUserActiveWorkspace(requestedWs=(Len(editSiteId) ? editSiteId : (page.siteId ?: "")), role=getCurrentActiveRole());
						editVDir = editWsObj.virtual_directory ?: ((page.siteId eq "global" || !Len(page.siteId)) ? "shared" : page.siteId);
					</cfscript>
					<div class="pg-slug-wrap">
						<span id="pgUrlPrefixSpan" aria-hidden="true">/#EncodeForHTML(editVDir)#/pages/</span>
						<input type="text" id="pgSlug" name="slug" class="form-control" value="#EncodeForHTMLAttribute(page.slug)#" aria-describedby="pgSlugHelp" <cfif page.locked>readonly</cfif>>
						<button type="button" id="btnCopyPageUrl" class="btn btn-sm btn-icon-only btn-ghost" title="Copy full URL to clipboard" aria-label="Copy full URL to clipboard" style="border:none; border-left:1px solid var(--admin-border); border-radius:0; height:100%; padding:0.5rem 0.65rem; color:var(--admin-text-muted); display:inline-flex; align-items:center; justify-content:center; background:transparent; cursor:pointer;" onmouseover="this.style.background='var(--admin-bg)'; this.style.color='var(--admin-primary)';" onmouseout="this.style.background='transparent'; this.style.color='var(--admin-text-muted)';">
							#svgIcon(name="copy", size=14)#
						</button>
					</div>
					<div id="pgSlugHelp" class="pg-help"><cfif page.locked>The home page URL cannot be changed.<cfelse>Lowercase letters, numbers and hyphens. Generated from the title if left blank.</cfif></div>
				</div>
				<div class="pg-field">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.4rem; flex-wrap:wrap; gap:0.5rem;">
						<label for="pgContent" class="form-label" style="margin-bottom:0;">Page Content</label>
						<div style="display:flex; align-items:center; gap:0.35rem;">
							<button type="button" class="btn btn-outline-primary btn-xs" id="btnEditorImportDoc" title="Import Word (.docx) or PDF and convert to WCAG AA HTML">
								#svgIcon(name="file-text", size=13)#
								<span>Import Word / PDF</span>
							</button>
							<button type="button" class="btn btn-outline btn-xs" id="btnEditorInsertCTA" title="Embed Call to Action card or grid into content">
								#svgIcon(name="cta", size=13)#
								<span>Embed Call to Action</span>
							</button>
							<button type="button" class="btn btn-outline btn-xs" id="btnEditorInsertForm" title="Embed online form into content">
								#svgIcon(name="form", size=13)#
								<span>Embed Form</span>
							</button>
						</div>
					</div>

					<!--- Feature 2.3: In-Editor Automated ADA WCAG Pre-Flight Linter Bar --->
					<div id="pgA11yLinterBar" class="pg-a11y-linter-bar is-passed" role="region" aria-label="ADA WCAG 2.1 AA Pre-Flight Linter">
						<div class="pg-a11y-bar-main">
							<div class="pg-a11y-bar-title-wrap">
								<span class="pg-a11y-bar-icon" aria-hidden="true">#svgIcon(name="shield", size=15)#</span>
								<strong class="pg-a11y-bar-title">ADA Pre-Flight Linter</strong>
								<span class="pg-a11y-standard-badge">WCAG 2.1 AA</span>
								<span id="pgA11yOverallBadge" class="badge badge-success" role="status" aria-live="polite">
									#svgIcon(name="check-circle", size=12)# <span>Compliant</span>
								</span>
							</div>

							<div class="pg-a11y-category-chips" id="pgA11yCategoryChips" role="group" aria-label="Accessibility Check Categories">
								<button type="button" class="pg-a11y-chip" id="chipA11yCover" data-cat="cover" title="Cover Image: Alternative text & decorative check">
									<span class="chip-label">Cover</span>
									<span class="chip-count" id="countA11yCover">0</span>
								</button>
								<button type="button" class="pg-a11y-chip" id="chipA11yImages" data-cat="images" title="Images: Alternative text & decorative check">
									<span class="chip-label">Images</span>
									<span class="chip-count" id="countA11yImages">0</span>
								</button>
								<button type="button" class="pg-a11y-chip" id="chipA11yHeadings" data-cat="headings" title="Headings: Logical outline hierarchy">
									<span class="chip-label">Headings</span>
									<span class="chip-count" id="countA11yHeadings">0</span>
								</button>
								<button type="button" class="pg-a11y-chip" id="chipA11yLinks" data-cat="links" title="Links: Descriptive text & target notifications">
									<span class="chip-label">Links</span>
									<span class="chip-count" id="countA11yLinks">0</span>
								</button>
								<button type="button" class="pg-a11y-chip" id="chipA11yTables" data-cat="tables" title="Tables: Header cells & captions">
									<span class="chip-label">Tables</span>
									<span class="chip-count" id="countA11yTables">0</span>
								</button>
								<button type="button" class="pg-a11y-chip" id="chipA11yFormat" data-cat="format" title="Readability, styling & contrast">
									<span class="chip-label">Readability</span>
									<span class="chip-count" id="countA11yFormat">0</span>
								</button>
							</div>

							<div class="pg-a11y-bar-actions">
								<button type="button" class="btn btn-outline btn-xs" id="btnToggleA11yDrawer" aria-expanded="false" aria-controls="pgA11yIssuesDrawer" onclick="if(window.PageA11yLinter){window.PageA11yLinter.toggleDrawer();}">
									#svgIcon(name="eye", size=13)#
									<span id="btnToggleA11yDrawerText">Audit Report</span>
									<span class="badge badge-neutral" id="pgA11yIssueBadge" style="margin-left:2px; font-weight:700;">0</span>
								</button>
								<button type="button" class="btn btn-ghost btn-xs btn-icon-only" id="btnRescanA11y" title="Re-scan content for accessibility barriers" aria-label="Re-scan accessibility" onclick="if(window.PageA11yLinter){window.PageA11yLinter.scan();}">
									#svgIcon(name="refresh", size=13)#
								</button>
							</div>
						</div>

						<!--- Expandable Diagnostic & Quick-Fix Drawer --->
						<div id="pgA11yIssuesDrawer" class="pg-a11y-drawer" style="display:none;" hidden>
							<div class="pg-a11y-drawer-header">
								<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
									<h4 class="pg-a11y-drawer-title" style="margin:0; font-size:0.875rem; font-weight:700;">Pre-Flight Audit Diagnostics</h4>
									<div class="pg-attr-tabs" role="tablist" aria-label="Issue Filter Tabs" style="padding:0.12rem;">
										<button type="button" class="pg-attr-tab is-active" id="tabA11yAll" data-filter="all" style="padding:0.2rem 0.55rem; font-size:0.75rem;">All (<span id="tabCountA11yAll">0</span>)</button>
										<button type="button" class="pg-attr-tab" id="tabA11yErrors" data-filter="errors" style="padding:0.2rem 0.55rem; font-size:0.75rem; color:##b91c1c;">Errors (<span id="tabCountA11yErrors">0</span>)</button>
										<button type="button" class="pg-attr-tab" id="tabA11yWarnings" data-filter="warnings" style="padding:0.2rem 0.55rem; font-size:0.75rem; color:##b45309;">Warnings (<span id="tabCountA11yWarnings">0</span>)</button>
									</div>
								</div>
								<button type="button" class="btn btn-ghost btn-xs btn-icon-only" id="btnCloseA11yDrawer" aria-label="Collapse audit report" onclick="if(window.PageA11yLinter){window.PageA11yLinter.closeDrawer();}">
									#svgIcon(name="x", size=14)#
								</button>
							</div>

							<div id="pgA11yIssuesList" class="pg-a11y-issues-list" role="region" aria-live="polite">
								<!--- Dynamic Issue Cards injected by JS --->
							</div>
						</div>
					</div>

					<div id="pgEditorDropContainer" class="pg-doc-drop-zone-wrap">
						<div id="pgDocDropOverlay" class="pg-doc-drop-overlay" style="display:none;" aria-hidden="true">
							<div class="pg-doc-drop-inner">
								<div class="pg-doc-drop-icon">
									#svgIcon(name="file-text", size=28)#
								</div>
								<strong class="pg-doc-drop-title">Drop Word (.docx) or PDF document here</strong>
								<span class="pg-doc-drop-sub">CMSAdmin will extract headings, tables, lists, and images into WCAG 2.1 AA HTML</span>
							</div>
						</div>
						<textarea id="pgContent" name="content" class="form-control pg-editor" data-jbd-editor data-jbd-toolbar="basic" data-jbd-inline-toolbar="true" data-jbd-height="400px" data-jbd-placeholder="Type page content, add headings, media, tables, and block templates..." aria-describedby="pgContentHelp"><cfif isNew><cfelseif Len(Trim(page.content ?: ''))>#EncodeForHTML(page.content)#<cfelseif Len(Trim(page.body ?: ''))>#EncodeForHTML(page.body)#<cfelse><h2>#EncodeForHTML(page.title)#</h2>
<p>#EncodeForHTML(page.summary)#</p></cfif></textarea>
					</div>
					<div id="pgContentHelp" class="pg-help">Accessible Rich Text Editor (WCAG 2.2 AA). Shortcuts: <kbd>Alt+F10</kbd> focus toolbar &middot; <kbd>&larr;/&rarr;</kbd> navigate &middot; <kbd>Esc</kbd> exit dialogs.</div>
				</div>
			</div>
		</div>

		<div class="pg-meta-grid">
			<div class="admin-card" style="margin-bottom:0;">
				<div class="card-header" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.5rem;">
					<h2 class="card-title">#svgIcon(name="search", size=16)# <span>Search &amp; Sharing</span></h2>
					<button type="button" class="btn btn-outline btn-xs" id="btnAutoGenerateMeta" title="Auto-generate title and summary from page title and content">
						#svgIcon(name="sparkles", size=13)#
						<span>Auto-Generate from Content</span>
					</button>
				</div>
				<div class="card-body">
					<div class="pg-field">
						<div style="display:flex; justify-content:space-between; align-items:center;">
							<label for="pgMetaTitle" class="form-label" style="margin-bottom:0;">Browser / Search Title</label>
							<span id="pgMetaTitleCount" style="font-size:0.75rem; color:var(--admin-text-muted);">0 / 65</span>
						</div>
						<input type="text" id="pgMetaTitle" name="metaTitle" class="form-control" maxlength="65" value="#EncodeForHTMLAttribute(Len(Trim(page.metaTitle ?: '')) ? page.metaTitle : (page.title & (isNew ? '' : ' | Chelan County')))#" style="width:100%; margin-top:0.35rem;" aria-describedby="pgMetaTitleHelp">
						<div id="pgMetaTitleHelp" class="pg-help">Up to 65 characters. Appears in browser tab and search engine results.</div>
					</div>
					<div class="pg-field">
						<div style="display:flex; justify-content:space-between; align-items:center;">
							<label for="pgMetaDesc" class="form-label" style="margin-bottom:0;">Summary / Meta Description</label>
							<span id="pgMetaDescCount" style="font-size:0.75rem; color:var(--admin-text-muted);">0 / 160</span>
						</div>
						<textarea id="pgMetaDesc" name="metaDescription" class="form-control" maxlength="160" rows="3" style="width:100%; margin-top:0.35rem;" aria-describedby="pgMetaDescHelp">#EncodeForHTML(Len(Trim(page.metaDesc ?: '')) ? page.metaDesc : page.summary)#</textarea>
						<div id="pgMetaDescHelp" class="pg-help">Up to 160 characters. Shown in search results and social media link previews.</div>
					</div>
				</div>
			</div>

			<div class="admin-card" style="margin-bottom:0;">
				<div class="card-header" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.5rem;">
					<h2 class="card-title">#svgIcon(name="layers", size=16)# <span>Page Attributes</span></h2>
					<div class="pg-attr-tabs" role="tablist" aria-label="Page Attributes Sections">
						<button type="button" role="tab" id="tabBtnAttrLayout" aria-selected="true" aria-controls="tabPanelAttrLayout" class="pg-attr-tab is-active" data-attr-tab="layout">
							<span>Page Layout</span>
						</button>
						<button type="button" role="tab" id="tabBtnAttrNav" aria-selected="false" aria-controls="tabPanelAttrNav" class="pg-attr-tab" data-attr-tab="nav">
							<span>Navigation Assignment</span>
						</button>
						<button type="button" role="tab" id="tabBtnAttrFolder" aria-selected="false" aria-controls="tabPanelAttrFolder" class="pg-attr-tab" data-attr-tab="folder">
							<span>Folder Explorer</span>
						</button>
					</div>
				</div>
				<div class="card-body">
					<!--- Tab 1: Page Layout --->
					<div id="tabPanelAttrLayout" role="tabpanel" aria-labelledby="tabBtnAttrLayout">
						<div class="pg-field">
							<label for="pgLayout" class="form-label">Layout</label>
							<select id="pgLayout" name="layout" class="form-control" style="width:100%;" aria-describedby="pgLayoutHelp">
								<cfloop list="Full,Right Sidebar" index="layoutOption">
									<option value="#layoutOption#" <cfif page.layout eq layoutOption>selected</cfif>>#layoutOption#</option>
								</cfloop>
							</select>
							<div id="pgLayoutHelp" class="pg-help">Choose whether this page uses a full-width layout or right sidebar layout.</div>
						</div>
						<div id="pgSidebarLayoutOptions" <cfif page.layout neq "Right Sidebar">hidden</cfif>>
							<div id="pgSidebarChoices">
								<h3 class="form-label" style="margin-bottom:0.35rem;">Available Sidebars</h3>
								<div id="pgSidebarChooser" role="group" aria-describedby="pgSidebarHelp" style="display:flex; flex-direction:column; gap:0;">
									<cfloop array="#availableSidebars#" index="sidebarOption">
										<label style="display:flex; align-items:center; gap:0.5rem; padding:0.35rem 0; border-bottom:1px solid var(--admin-border-subtle); cursor:pointer;">
											<input type="checkbox" name="sidebarIds" value="#EncodeForHTMLAttribute(sidebarOption.id)#" <cfif ArrayFind(page.sidebarIds, sidebarOption.id)>checked</cfif> style="width:18px; height:18px; margin-top:0.1rem; flex-shrink:0; accent-color:var(--admin-primary);">
											<span>
												<strong style="display:block; color:var(--admin-text-main); font-size:0.85rem;">#EncodeForHTML(sidebarOption.name)#</strong>
											</span>
										</label>
									</cfloop>
									<cfloop array="#availableSubpages#" index="subpageOption">
										<div class="pg-subpage-row" style="padding:0.35rem 0; gap:0.5rem;">
											<label style="display:flex; align-items:center; gap:0.5rem; flex:1; min-width:0; cursor:pointer;">
												<input type="checkbox" name="sidebarIds" value="subpage-#subpageOption.id#" data-id="#subpageOption.id#" data-subpage-title="#EncodeForHTMLAttribute(subpageOption.title)#" data-content="#EncodeForHTMLAttribute(subpageOption.body)#" data-position="#Val(subpageOption.position)#" <cfif ArrayFindNoCase(page.sidebarIds, "subpage-#subpageOption.id#")>checked</cfif> style="width:18px; height:18px; margin-top:0.1rem; flex-shrink:0; accent-color:var(--admin-primary);">
												<span><strong data-subpage-title style="display:block; color:var(--admin-text-main); font-size:0.85rem;">#EncodeForHTML(subpageOption.title)#</strong></span>
											</label>
											<button type="button" class="btn btn-outline btn-sm btn-icon-only" data-edit-subpage title="Edit" aria-label="Edit #EncodeForHTMLAttribute(subpageOption.title)#">#svgIcon(name="edit", size=14)#</button>
										</div>
									</cfloop>
									<cfif ArrayLen(availableSubpages) eq 0 and ArrayLen(availableSidebars) eq 0>
										<div id="pgNoSidebarsMsg" class="pg-help" style="padding:0.5rem 0; color:var(--admin-text-muted);">No subpages or sidebars have been created for this workspace yet.</div>
									</cfif>
								</div>
								<div id="pgSidebarHelp" class="pg-help" aria-live="polite">Select one or more sidebars for this page.</div>
							</div>
							<cfif not isNew>
								<div id="pgSubpageActions" style="border-top:1px solid var(--admin-border-subtle); margin-top:1rem; padding-top:1rem;">
									<button type="button" class="btn btn-outline btn-sm" id="pgOpenSubpageModal" data-content-id="#page.id#" data-site-id="#EncodeForHTMLAttribute(variables.editSiteId)#" data-save-url="#urlFor(route="saveSubpage")#" data-delete-url="#urlFor(route="deleteSubpage")#">#svgIcon(name="plus", size=14)# <span>Create Subpage</span></button>
									<div class="pg-help">Create a subpage for “#EncodeForHTML(page.title)#” and add it to this workspace’s sidebar list.</div>
								</div>
							<cfelse>
								<div id="pgSubpageActions" style="border-top:1px solid var(--admin-border-subtle); margin-top:1rem; padding-top:1rem;">
									<div class="pg-help">Save this page first to create new custom subpages. Existing workspace subpages can be selected above.</div>
								</div>
							</cfif>
						</div>
					</div>

					<!--- Tab 2: Navigation Assignment --->
					<div id="tabPanelAttrNav" role="tabpanel" aria-labelledby="tabBtnAttrNav" hidden>
						<div class="pg-field">
							<label for="pgParent" class="form-label">Page Assignment</label>
							<cfset isAssignedToMenu = (structKeyExists(page, "pageType") and Val(page.pageType) eq 1) or page.parent eq "Assign to Main Menu Item" or page.parent eq "Assign to Menu Item" or (len(trim(page.parent)) gt 0 and page.parent neq "Top Level - Called from URL")>
							<select id="pgParent" name="parent" class="form-control" style="width:100%;" aria-describedby="pgAssignmentHelp">
								<option value="Top Level - Called from URL" <cfif not isAssignedToMenu>selected</cfif>>Top Level - Called from URL</option>
								<option value="Assign to Main Menu Item" <cfif isAssignedToMenu>selected</cfif>>Assign to Main Menu Item</option>
							</select>
							<div id="pgAssignmentHelp" class="pg-help">Specify whether this page is a top-level URL route or assigned to a menu item.</div>
						</div>

						<!--- Secondary Menu Item selection: ONLY open when Assign to Main Menu Item is selected --->
						<div id="pgMenuAssignmentWrap" class="pg-field" style="margin-top:0.75rem;<cfif not isAssignedToMenu> display:none;</cfif>" <cfif not isAssignedToMenu>hidden</cfif>>
							<label for="pgMenuItemSelect" class="form-label" style="font-size:0.8rem; font-weight:600;">Menu Item Selection</label>
							<select id="pgMenuItemSelect" name="menuItemTarget" class="form-control" style="width:100%;" data-initial-selected="#EncodeForHTMLAttribute(page.parent)#" data-page-workspace="#EncodeForHTMLAttribute(page.siteId)#">
								<cfif ArrayLen(menuItemOptions) eq 0>
									<option value="">(No menu items defined for this workspace)</option>
								<cfelse>
									<option value="" <cfif not len(trim(page.parent))>selected</cfif>>-- Select Menu Item --</option>
									<cfset currentGroup = "">
									<cfloop array="#menuItemOptions#" index="menuOpt">
										<cfif structKeyExists(menuOpt, "group") and len(menuOpt.group) and menuOpt.group neq currentGroup>
											<cfif len(currentGroup)></optgroup></cfif>
											<cfset currentGroup = menuOpt.group>
											<optgroup label="#EncodeForHTMLAttribute(currentGroup)#">
										<cfelseif (!structKeyExists(menuOpt, "group") or !len(menuOpt.group)) and len(currentGroup)>
											</optgroup>
											<cfset currentGroup = "">
										</cfif>
										<option value="#EncodeForHTMLAttribute(menuOpt.label)#" <cfif page.parent eq menuOpt.label>selected</cfif>>#RepeatString("&nbsp;&nbsp;&nbsp;&nbsp;", Int(Val(menuOpt.depth)))##EncodeForHTML(menuOpt.label)#</option>
									</cfloop>
									<cfif len(currentGroup)></optgroup></cfif>
								</cfif>
							</select>
							<div id="pgMenuAssignmentHelp" class="pg-help"><cfif ArrayLen(menuItemOptions) eq 0>No menu structure defined yet for this workspace.<cfelse>Select the navigation item or parent page this belongs under.</cfif></div>
						</div>

						<div class="pg-field" style="margin-top:0.75rem;">
							<label style="display:flex; align-items:center; gap:0.55rem; font-size:0.85rem; cursor:pointer;">
								<input type="checkbox" id="pgMenuItem" name="menuItem" <cfif page.menuItem>checked</cfif> style="width:18px; height:18px; accent-color:var(--admin-primary);" aria-describedby="pgMenuHelp">
								<strong>Show in main menu</strong>
							</label>
							<div id="pgMenuHelp" class="pg-help">Adds this page to the site's top navigation.</div>
						</div>
					</div>

					<!--- Tab 2: Folder Explorer --->
					<div id="tabPanelAttrFolder" role="tabpanel" aria-labelledby="tabBtnAttrFolder" hidden>
						<cfset isFolderExplorerEnabled = folderAttachedHere or (structKeyExists(page, "hasArchive") and page.hasArchive)>
						<div class="pg-field">
							<label style="display:flex; align-items:center; gap:0.55rem; font-size:0.85rem; cursor:pointer;">
								<input type="checkbox" id="pgFolderListingEnabled" name="folderListingEnabled" <cfif isFolderExplorerEnabled>checked</cfif> style="width:18px; height:18px; accent-color:var(--admin-primary);" aria-controls="pgFolderListingControls">
								<strong>Add Folder Explorer</strong>
							</label>
							<div class="pg-help">Show a folder explorer on this page.</div>
						</div>
						<div id="pgFolderListingControls" data-content-id="#page.id#" data-save-url="#urlFor(route="saveFolderExplorer")#" data-delete-url="#urlFor(route="deleteFolderExplorer")#" <cfif not isFolderExplorerEnabled>hidden</cfif>>
							<div id="pgFolderListingItems" style="display:flex; flex-direction:column; gap:0;" aria-live="polite">
								<cfloop array="#availableFolders#" index="folderOption">
									<cfset folderAbs = folderOption.absolutePath>
									<cfset folderRel = folderOption.relativePath>
									<cfset folderLay = folderOption.layout>
									<cfset isFolderSelected = (structKeyExists(folderOption, "selected") and folderOption.selected) or (Val(folderOption.contentId ?: 0) eq Val(page.id) and Val(page.id) gt 0)>
									<div class="pg-subpage-row" data-id="#folderOption.id#" data-title="#EncodeForHTMLAttribute(folderOption.name)#" data-path="#EncodeForHTMLAttribute(folderOption.path)#" data-absolute-path="#EncodeForHTMLAttribute(folderAbs)#" data-relative-path="#EncodeForHTMLAttribute(folderRel)#" data-layout="#EncodeForHTMLAttribute(folderLay)#" style="padding:0.45rem 0; gap:0.5rem; border-bottom:1px dashed var(--admin-border-subtle); display:flex; align-items:center;">
										<label style="display:flex; align-items:flex-start; gap:0.5rem; flex:1; min-width:0; cursor:pointer;">
											<input type="checkbox" name="folderListingItems" value="#EncodeForHTMLAttribute(folderOption.path)#" data-folder-id="#Val(folderOption.id)#" <cfif isFolderSelected>checked</cfif> style="width:18px; height:18px; margin-top:0.15rem; flex-shrink:0; accent-color:var(--admin-primary);">
											<span style="min-width:0; flex:1;">
												<strong data-folder-title style="display:block; color:var(--admin-text-main); font-size:0.875rem;">#EncodeForHTML(folderOption.name)#</strong>
												<span class="pg-help" style="margin:0; font-size:0.75rem; display:flex; align-items:center; gap:0.35rem; flex-wrap:wrap;">
													<code data-folder-relative style="font-size:0.72rem; color:var(--admin-primary); background:rgba(30,58,138,0.06); padding:0.1rem 0.3rem; border-radius:3px;">/#EncodeForHTML(folderRel)#</code>
													<span>&bull;</span>
													<span class="badge badge-neutral" data-folder-layout-badge style="font-size:0.68rem; padding:0.1rem 0.4rem;">#folderLay eq '3/9' ? '3/9 Grid' : 'Full Width'#</span>
												</span>
											</span>
										</label>
										<button type="button" class="btn btn-outline btn-sm btn-icon-only" data-edit-folder-item title="Edit" aria-label="Edit #EncodeForHTMLAttribute(folderOption.name)#">#svgIcon(name="edit", size=14)#</button>
									</div>
								</cfloop>
							</div>
							<template id="pgIconEdit">#svgIcon(name="edit", size=14)#</template><template id="pgIconTrash">#svgIcon(name="trash", size=14)#</template>
							<div id="pgFolderListingStatus" role="status" aria-live="polite" class="pg-help"></div>
							<button type="button" class="btn btn-outline btn-sm" id="pgAddFolderListingItem" style="margin-top:0.4rem;">#svgIcon(name="plus", size=14)# <span>Add Folder Explorer Item</span></button>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!--- Sidebar column --->
	<div class="pg-side-col">
		<!--- Featured Cover Image Card --->
		<div class="admin-card" id="pgCoverImagePanel" style="padding:1.25rem; margin-bottom:0;">
			<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem; border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem; flex-wrap:wrap; gap:0.4rem;">
				<h3 style="margin:0; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.4rem;">
					#svgIcon(name="image", size=16)#
					<span>Featured Cover Image</span>
				</h3>
				<div style="display:flex; align-items:center; gap:0.35rem;">
					<span class="badge badge-neutral" id="featuredImgAdaBadge" style="font-size:0.7rem; font-weight:600;" title="Live ADA Title II & WCAG 2.1 AA Compliance Status">
						<span id="featuredImgAdaText">No Image</span>
					</span>
					<span class="badge badge-neutral" id="featuredImgWsBadge" style="font-size:0.7rem; font-weight:600;" title="Media browser will open files assigned to this workspace">
						#svgIcon(name="folder", size=11)#
						<span id="featuredImgWsName">#EncodeForHTML(StructKeyExists(variables, "activeWsObj") && StructKeyExists(activeWsObj, "name") ? activeWsObj.name : (editWsObj.name ?: "Workspace"))#</span>
					</span>
				</div>
			</div>

			<!--- Thumbnail Preview --->
			<div style="margin-bottom:0.75rem;">
				<div id="featuredImgPreviewWrap"
				     role="button"
				     tabindex="0"
				     aria-label="Click to browse workspace media library for cover image"
				     onclick="openMediaPickerForPageCover()"
				     onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();openMediaPickerForPageCover();}"
				     style="border:1.5px dashed var(--admin-border); border-radius:var(--radius-md); padding:0.5rem; text-align:center; min-height:130px; display:flex; flex-direction:column; align-items:center; justify-content:center; background:var(--admin-bg); cursor:pointer; transition:all 0.15s ease;"
				     onmouseenter="this.style.borderColor='var(--admin-primary)'; this.style.backgroundColor='var(--admin-surface-hover, ##f8fafc)';"
				     onmouseleave="this.style.borderColor='var(--admin-border)'; this.style.backgroundColor='var(--admin-bg)';"
				     title="Click to browse workspace media library">
					<img id="featuredImgPreview" src="#EncodeForHTML(page.imageAttachment ?: '')#" alt="#EncodeForHTMLAttribute(page.imageAlt ?: '')#" style="max-width:100%; max-height:140px; object-fit:cover; border-radius:var(--radius-sm); #(Len(Trim(page.imageAttachment ?: '')) ? '' : 'display:none;')#" />
					<div id="featuredImgPlaceholder" style="color:var(--admin-text-muted); font-size:0.8rem; #(Len(Trim(page.imageAttachment ?: '')) ? 'display:none;' : 'display:flex; flex-direction:column; align-items:center; justify-content:center;')#">
						<div style="color:var(--admin-primary); margin-bottom:0.25rem;">
							#svgIcon(name="image", size=28)#
						</div>
						<div style="font-weight:600; color:var(--admin-text-main); font-size:0.85rem;">Choose Cover Image</div>
						<div style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.15rem;">Click to browse workspace media library</div>
					</div>
				</div>
			</div>

			<!--- Image URL & Picker Buttons --->
			<div style="margin-bottom:0.75rem;">
				<label for="featuredImage" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
					Image URL
				</label>
				<div style="display:flex; gap:0.4rem;">
					<input type="text" id="featuredImage" name="imageAttachment" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(page.imageAttachment ?: "")#" placeholder="/files/pio/images/photo.jpg" oninput="updateImagePreview(this.value)">
					<button type="button" id="btnBrowseFeaturedImg" class="btn btn-outline-secondary btn-sm" onclick="openMediaPickerForPageCover()" title="Select from Workspace Media Library" style="display:inline-flex; align-items:center; gap:0.3rem; white-space:nowrap;">
						#svgIcon(name="folder", size=13)#
						<span>Browse</span>
					</button>
					<button type="button" id="btnRemoveFeaturedImg" class="btn btn-outline-danger btn-sm" onclick="removeFeaturedImage()" title="Remove cover image" style="display:#(Len(Trim(page.imageAttachment ?: '')) ? 'inline-flex' : 'none')#; align-items:center; gap:0.3rem; white-space:nowrap;">
						#svgIcon(name="trash", size=13)#
						<span>Remove</span>
					</button>
				</div>
			</div>

			<!--- Decorative Toggle (WCAG 2.1 H67) --->
			<div style="background:var(--admin-bg-subtle, ##f8fafc); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:0.6rem 0.75rem; margin-bottom:0.75rem;">
				<label style="display:flex; align-items:flex-start; gap:0.5rem; font-size:0.8rem; font-weight:600; color:var(--admin-text-main); margin:0; cursor:pointer;">
					<input type="checkbox" id="featuredImageDecorative" name="imageDecorative" value="1" #(Val(page.imageDecorative ?: 0) ? 'checked="checked"' : '')# onchange="onDecorativeToggled(this.checked)" style="margin-top:0.15rem;">
					<div>
						<span>Mark as decorative image (WCAG 1.1.1 / H67)</span>
						<div style="font-weight:400; font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.15rem; line-height:1.35;">
							Check if this image is purely decorative or mood-setting and conveys no critical news content. Screen readers will safely ignore it.
						</div>
					</div>
				</label>
			</div>

			<!--- Alt Text Container --->
			<div id="altTextContainer" style="#(Val(page.imageDecorative ?: 0) ? 'opacity:0.5; pointer-events:none;' : '')# margin-bottom:0.75rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.25rem;">
					<label for="featuredImageAlt" style="display:block; font-weight:600; font-size:0.8rem; margin:0; color:var(--admin-text-muted);">
						Alternative Text (ADA / WCAG 2.1 AA) <span style="color:var(--admin-danger, ##ef4444); font-weight:700;">*</span>
					</label>
					<span style="font-size:0.7rem; color:var(--admin-text-muted);" id="altCharCounter">#Len(Trim(page.imageAlt ?: ''))#/150 rec.</span>
				</div>
				<input type="text" id="featuredImageAlt" name="imageAlt" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(page.imageAlt ?: "")#" placeholder="Brief description of the scene or subjects for screen readers" maxlength="500" oninput="onAltInput(this.value)">

				<div style="display:flex; justify-content:space-between; align-items:center; margin-top:0.3rem;">
					<div style="font-size:0.72rem; color:var(--admin-text-muted);">
						Be concise and specific. Do not include phrases like "photo of" or "image of".
					</div>
					<button type="button" class="btn btn-link btn-sm" style="padding:0; font-size:0.72rem; text-decoration:none; color:var(--admin-primary); display:inline-flex; align-items:center; gap:0.2rem; cursor:pointer;" onclick="suggestAltFromHeadline()" title="Draft initial alt text based on the page title">
						#svgIcon(name="sparkles", size=12)#
						<span>Suggest from Headline</span>
					</button>
				</div>

				<div id="altAuditNotice" style="display:none; margin-top:0.35rem; padding:0.4rem 0.6rem; border-radius:var(--radius-sm); font-size:0.73rem; line-height:1.35;"></div>
			</div>

			<!--- Story Caption (Visible) --->
			<div style="margin-bottom:0.75rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.25rem;">
					<label for="featuredImageCaption" style="display:block; font-weight:600; font-size:0.8rem; margin:0; color:var(--admin-text-muted);">
						Story Caption (Visible)
					</label>
					<span style="font-size:0.7rem; color:var(--admin-text-muted);" id="captionCharCounter">#Len(Trim(page.imageTitle ?: ''))#/1000</span>
				</div>
				<input type="text" id="featuredImageCaption" name="imageTitle" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(page.imageTitle ?: "")#" placeholder="Optional visible caption printed below the image on the page" maxlength="1000" oninput="updateCaptionCharCount(this.value)">
			</div>

			<!--- Extended Description (Complex Visuals / Maps / Infographics) --->
			<div style="margin-bottom:0.75rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.25rem;">
					<label for="featuredImageDescription" style="display:block; font-weight:600; font-size:0.8rem; margin:0; color:var(--admin-text-muted);">
						Extended Description (Complex Visuals / Maps / Infographics)
					</label>
					<span style="font-size:0.7rem; color:var(--admin-text-muted);" id="descCharCounter">#Len(Trim(page.imageDescription ?: ''))#/2000</span>
				</div>
				<textarea id="featuredImageDescription" name="imageDescription" class="form-control" rows="2" style="font-size:0.82rem;" placeholder="Detailed text transcription for screen readers when the image contains complex maps, data charts, or documents..." maxlength="2000" oninput="updateDescCharCount(this.value)">#EncodeForHTML(page.imageDescription ?: "")#</textarea>
				<div style="font-size:0.71rem; color:var(--admin-text-muted); margin-top:0.2rem;">
					WCAG 1.1.1 AA: If the cover image conveys detailed data, provide a full text equivalent here.
				</div>
			</div>

			<!--- Photo Credit / Attribution --->
			<div>
				<label for="featuredImageCredit" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
					Photo Credit / Attribution
				</label>
				<input type="text" id="featuredImageCredit" name="imageAttribution" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(page.imageAttribution ?: "")#" placeholder="e.g. Chelan County Sheriff's Office / Jane Doe" maxlength="255">
			</div>
		</div>

		<div class="admin-card pg-publish-sticky" id="pgPublishPanel" style="margin-bottom:0;">
			<div class="card-header">
				<h2 class="card-title">#svgIcon(name="published", size=16)# <span>Publish</span></h2>
			</div>
			<div class="card-body">
				<!--- Feature 2.3: Companion WCAG Pre-Flight Scorecard --->
				<div class="pg-a11y-publish-widget" id="pgA11yPublishWidget">
					<div class="pg-a11y-pub-header">
						<span style="display:flex; align-items:center; gap:0.35rem; font-size:0.78rem; font-weight:700; color:var(--admin-text-main);">
							#svgIcon(name="shield", size=14)#
							<span>ADA Pre-Flight</span>
						</span>
						<span id="pgA11yPublishBadge" class="badge badge-success" style="font-size:0.7rem; font-weight:700;">PASS</span>
					</div>
					<div class="pg-a11y-pub-body">
						<div id="pgA11yPublishSummary" style="font-size:0.75rem; color:var(--admin-text-muted); line-height:1.4;">
							Content ready for public release.
						</div>
						<button type="button" id="lnkInspectA11yDrawer" aria-expanded="false" onclick="if(window.PageA11yLinter){window.PageA11yLinter.toggleDrawer('publish');}return false;" style="display:inline-flex; align-items:center; gap:0.25rem; font-size:0.75rem; font-weight:600; color:var(--admin-primary); margin-top:0.35rem; background:none; border:none; padding:0; cursor:pointer; text-decoration:none;">
							<span id="lnkInspectA11yText">Inspect Diagnostics</span>
							<span id="lnkInspectA11yChevron" style="display:inline-flex; align-items:center; transition:transform 0.2s ease;">#svgIcon(name="chevron-down", size=12)#</span>
						</button>
						<div id="pgA11yPublishInlineList" style="display:none; margin-top:0.55rem; padding-top:0.55rem; border-top:1px solid var(--admin-border-subtle, ##e2e8f0); flex-direction:column; gap:0.45rem; max-height:280px; overflow-y:auto;"></div>
					</div>
				</div>

				<div class="pg-field">
					<label for="pgStatus" class="form-label">Status</label>
					<select id="pgStatus" name="status" class="form-control" style="width:100%;">
						<option value="Active" <cfif page.status eq "Active">selected</cfif>>Active</option>
						<option value="Inactive" <cfif page.status eq "Inactive">selected</cfif>>Inactive</option>
					</select>
				</div>
				<div class="pg-field">
					<label for="pgVisibility" class="form-label">Visibility</label>
					<select id="pgVisibility" name="visibility" class="form-control" style="width:100%;">
						<cfloop list="Published,Draft,Scheduled,Hidden" index="v">
							<option value="#v#" <cfif page.visibility eq v>selected</cfif>>#v#</option>
						</cfloop>
					</select>
				</div>
				<div class="pg-field" id="pgScheduleWrap" <cfif page.visibility neq "Scheduled" and not len(trim(page.publishAt ?: ''))>hidden</cfif>>
					<label for="pgPublishAt" class="form-label">Publish On</label>
					<input type="datetime-local" id="pgPublishAt" name="publishAt" class="form-control" value="#page.publishAt ?: ''#" style="width:100%;">
				</div>
				<div class="pg-field" id="pgUnpublishWrap" style="margin-top:0.6rem;">
					<label for="pgUnpublishAt" class="form-label" style="display:flex; justify-content:space-between; align-items:center;">
						<span>Unpublish / Expire On</span>
						<span class="pg-help" style="display:inline; margin:0; font-weight:normal; font-size:0.75rem;">(optional)</span>
					</label>
					<input type="datetime-local" id="pgUnpublishAt" name="unpublishAt" class="form-control" value="#page.unpublishAt ?: ''#" style="width:100%;">
					<div style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.2rem;">
						Auto-archives on date (e.g. election notices, RFP closures, seasonal alerts).
					</div>
				</div>
				<cfif not isNew>
					<div class="pg-field" style="margin-top:0.6rem; margin-bottom:0.75rem;">
						<label for="pgChangeSummary" class="form-label" style="font-size:0.8rem; font-weight:600;">Revision Note <span class="pg-help" style="display:inline; margin:0; font-weight:normal;">(optional)</span></label>
						<input type="text" id="pgChangeSummary" name="changeSummary" class="form-control form-control-sm" placeholder="e.g. Updated fee schedule" maxlength="255" style="width:100%; font-size:0.85rem;">
					</div>
				</cfif>
				<dl id="pgMetaAuditDl" style="margin:0 0 1rem 0;<cfif isNew and not len(trim(page.updated ?: ''))> display:none;</cfif>">
					<div class="pg-meta-row"><dt>Last updated</dt><dd id="pgLastUpdatedDd">#page.updated ?: ''#</dd></div>
					<div class="pg-meta-row"><dt>Updated by</dt><dd id="pgAuthorDd">#EncodeForHTML(page.author ?: '')#</dd></div>
					<cfif not isNew>
						<div class="pg-meta-row"><dt>History</dt><dd><a href="javascript:void(0)" id="lnkSidebarRevisions" style="font-weight:600; text-decoration:underline; color:var(--admin-primary);">v<span id="pgCurrentVerDd">#Val(currentVersion)#</span> (<span id="pgSidebarRevCount">#Val(revisionCount)#</span> snapshots)</a></dd></div>
					</cfif>
				</dl>
				<div style="display:flex; gap:0.5rem; flex-wrap:wrap;">
					<button type="submit" class="btn btn-primary btn-sm" id="btnSavePage" style="flex:1;">
						#svgIcon(name="save", size=14)#
						<span>#isNew ? "Create Page" : "Save Changes"#</span>
					</button>
					<a href="#urlFor(controller='pages', action='index')#" class="btn btn-outline btn-sm">Cancel</a>
				</div>
			</div>
		</div>
	</div>
</form>

<div class="pg-subpage-modal" id="pgSubpageModal" role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="pgSubpageModalTitle">
	<div class="pg-subpage-backdrop" data-close-subpage-modal></div>
	<section class="pg-subpage-window" style="width:min(100%, 820px);">
		<div class="card-header">
			<div>
				<h2 class="card-title" id="pgSubpageModalTitle">Create Subpage</h2>
				<p class="pg-help" style="margin-bottom:0;">The subpage will be added to the available sidebar list.</p>
			</div>
			<button type="button" class="btn btn-outline btn-sm" id="pgCloseSubpageModal" aria-label="Close subpage editor">Close</button>
		</div>
		<div class="card-body">
			<div id="pgSubpageCreateStatus" role="status" aria-live="polite" class="pg-help"></div>
			<div class="pg-field">
				<label for="pgSubpageTitle" class="form-label" style="font-weight:600;">Title / Header <span style="color:var(--admin-danger);" aria-hidden="true">*</span></label>
				<input type="text" id="pgSubpageTitle" class="form-control" maxlength="255" style="width:100%; font-size:0.95rem; font-weight:600;" placeholder="Enter a title / header" required>
			</div>
			<div class="pg-field">
				<label for="pgSubpagePosition" class="form-label" style="font-weight:600;">Position</label>
				<input type="number" id="pgSubpagePosition" class="form-control" min="0" step="1" value="0" style="width:8rem;" aria-describedby="pgSubpagePositionHelp">
				<div id="pgSubpagePositionHelp" class="pg-help">Order of this subpage in the sidebar list. Lower numbers appear first.</div>
			</div>
			<div class="pg-field">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.4rem; flex-wrap:wrap; gap:0.5rem;">
					<label for="pgSubpageContent" class="form-label" style="margin-bottom:0; font-weight:600;">Body</label>
					<div style="display:flex; align-items:center; gap:0.35rem; flex-wrap:wrap;">
						<div class="pg-template-picker-group" style="display:inline-flex; align-items:center; gap:0.25rem;">
							<select id="pgSubpageTemplateSelect" class="form-control" style="font-size:0.8rem; padding:0.25rem 0.5rem; height:auto; width:auto; max-width:210px;" aria-label="Select template to insert">
								<option value="">-- Choose Template --</option>
								<option value="table-of-contents">On This Page (Table of Contents)</option>
								<option value="subpage-menu">Subpage Menu / Navigation Tree</option>
								<option value="related-pages">Related Pages</option>
								<option value="related-links">Related Links &amp; Resources</option>
								<option value="contact-hours">Office Contact &amp; Hours</option>
								<option value="panel-info">Info Panel</option>
								<option value="panel-warning">Warning Panel</option>
								<option value="references-authority">References &amp; Authority</option>
								<option value="callout-info">Info Callout</option>
								<option value="cta-card">Call to Action (CTA) Card</option>
								<option value="cta-grid">Call to Action Grid (2-Col)</option>
								<option value="cta-banner">Call to Action Banner</option>
								<option value="faq-item">FAQ Question &amp; Answer</option>
								<option value="steps-process">Step-by-Step Instructions</option>
							</select>
							<button type="button" class="btn btn-outline btn-xs" id="btnSubpageApplyTemplate" title="Insert selected template into subpage">
								#svgIcon(name="plus", size=13)#
								<span>Insert</span>
							</button>
						</div>
						<button type="button" class="btn btn-outline btn-xs" id="btnSubpageBrowseTemplates" title="Browse all templates with preview">
							#svgIcon(name="template", size=13)#
							<span>Browse Templates</span>
						</button>
					</div>
				</div>
				<textarea id="pgSubpageContent" name="subpageContent" class="form-control pg-editor" data-jbd-editor data-jbd-toolbar="subpage" data-jbd-height="260px" data-jbd-placeholder="Write subpage content, add paragraphs, lists, links, or insert templates..." aria-describedby="pgSubpageHelp"></textarea>
				<div id="pgSubpageHelp" class="pg-help">Accessible Rich Text Editor. Choose a template above or use the toolbar to format paragraph structures and insert blocks.</div>
			</div>
			<div style="display:flex; justify-content:flex-end; gap:0.5rem; margin-top:1.25rem;">
				<button type="button" class="btn btn-outline btn-sm" id="pgDeleteSubpage" hidden style="margin-right:auto; color:var(--admin-danger);">Delete</button>
				<button type="button" class="btn btn-outline btn-sm" id="pgCancelSubpage">Cancel</button>
				<button type="button" class="btn btn-primary btn-sm" id="pgSaveSubpage">Save Subpage</button>
			</div>
		</div>
	</section>
</div>

<div class="pg-subpage-modal" id="pgFolderItemModal" role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="pgFolderItemModalTitle">
	<div class="pg-subpage-backdrop" data-close-folder-modal></div>
	<section class="pg-subpage-window" style="max-width:680px;">
		<div class="card-header" style="display:flex; justify-content:space-between; align-items:flex-start; padding:1.25rem 1.5rem; border-bottom:1px solid var(--admin-border-subtle);">
			<div>
				<h2 class="card-title" id="pgFolderItemModalTitle" style="font-size:1.15rem; margin:0; display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="folder", size=20)#
					<span>Add Folder Explorer Item</span>
				</h2>
				<p class="pg-help" style="margin:0.25rem 0 0 0; font-size:0.8rem;">Configure document repository title, physical storage path, public web route, and layout.</p>
			</div>
			<button type="button" class="btn btn-outline btn-sm" id="pgCloseFolderModal" aria-label="Close folder explorer editor">Close</button>
		</div>
		<div class="card-body" style="padding:1.5rem;">
			<div id="pgFolderItemStatus" role="status" aria-live="polite" class="pg-help" style="min-height:1.2rem; color:var(--admin-danger); font-weight:600; margin-bottom:0.75rem;"></div>
			
			<!--- 1. Title --->
			<div class="pg-field" style="margin-bottom:1.1rem;">
				<label for="pgFolderItemTitle" class="form-label" style="font-weight:600;">Title <span style="color:var(--admin-danger);" aria-hidden="true">*</span></label>
				<input type="text" id="pgFolderItemTitle" class="form-control" maxlength="120" style="width:100%; font-size:0.95rem; font-weight:600;" placeholder="e.g. Public Records &amp; Documents" required aria-required="true" aria-describedby="pgFolderItemTitleHelp">
				<div id="pgFolderItemTitleHelp" class="pg-help">Display heading for this document folder explorer instance.</div>
			</div>

			<!--- 2. Server Absolute Path --->
			<div class="pg-field" style="margin-bottom:1.1rem;">
				<label for="pgFolderItemAbsolutePath" class="form-label" style="font-weight:600;">Server Absolute Path <span style="color:var(--admin-danger);" aria-hidden="true">*</span></label>
				<input type="text" id="pgFolderItemAbsolutePath" class="form-control" style="width:100%; font-family:monospace; font-size:0.85rem;" placeholder="C:\inetpub\chelan-county\files\assessors" required aria-required="true" aria-describedby="pgFolderItemAbsHelp">
				<div id="pgFolderItemAbsHelp" class="pg-help">Physical server directory or network UNC path on the filesystem.</div>
			</div>

			<!--- 3. Web URL Relative Path --->
			<div class="pg-field" style="margin-bottom:1.25rem;">
				<label for="pgFolderItemRelativePath" class="form-label" style="font-weight:600;">Web URL Relative Path <span style="color:var(--admin-danger);" aria-hidden="true">*</span></label>
				<div style="display:flex; align-items:stretch; border:1.5px solid var(--admin-border-input, ##64748b); border-radius:var(--radius-md); overflow:hidden;">
					<span style="display:inline-flex; align-items:center; padding:0 0.75rem; background:var(--admin-bg, ##f8fafc); border-right:1px solid var(--admin-border, ##cbd5e1); color:var(--admin-text-muted, ##475569); font-size:0.85rem; font-family:monospace; user-select:none;">chelancounty.gov/</span>
					<input type="text" id="pgFolderItemRelativePath" class="form-control" style="flex:1; border:none; border-radius:0; font-family:monospace; font-size:0.85rem;" placeholder="files/assessors" required aria-required="true" aria-describedby="pgFolderItemRelHelp">
				</div>
				<div id="pgFolderItemRelHelp" class="pg-help">Public web URL slug (auto-slugged from title or customized).</div>
			</div>

			<!--- 4. Option Layout (Full or 3/9 Grid Layout) --->
			<div class="pg-field" style="margin-bottom:1.5rem;">
				<label class="form-label" id="pgFolderItemLayoutLabel" style="font-weight:600; display:block; margin-bottom:0.5rem;">Option Layout <span style="color:var(--admin-danger);" aria-hidden="true">*</span></label>
				<input type="hidden" id="pgFolderItemLayout" name="folderItemLayout" value="3/9">
				<div role="radiogroup" aria-labelledby="pgFolderItemLayoutLabel" style="display:grid; grid-template-columns:1fr 1fr; gap:0.85rem;">
					<!--- Full Width Card --->
					<div class="fe-layout-card" data-fe-layout="Full" role="radio" aria-checked="false" tabindex="-1" style="display:flex; flex-direction:column; gap:0.5rem;">
						<div style="display:flex; justify-content:space-between; align-items:center;">
							<strong style="font-size:0.9rem; color:var(--admin-text-main);">Full Width</strong>
							<span class="fe-radio-dot" style="width:16px; height:16px; border-radius:50%; border:2px solid var(--admin-border, ##cbd5e1); display:inline-flex; align-items:center; justify-content:center;"></span>
						</div>
						<!--- Full Width Wireframe --->
						<div style="height:60px; background:var(--admin-bg, ##f1f5f9); border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:4px; padding:5px; display:flex; flex-direction:column; gap:4px;" aria-hidden="true">
							<div style="height:8px; background:var(--admin-border, ##cbd5e1); border-radius:2px; width:45%;"></div>
							<div style="flex:1; background:##ffffff; border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:2px; display:flex; flex-direction:column; justify-content:space-around; padding:4px 6px;">
								<div style="height:4px; background:##94a3b8; border-radius:1px; width:90%;"></div>
								<div style="height:4px; background:##cbd5e1; border-radius:1px; width:75%;"></div>
								<div style="height:4px; background:##cbd5e1; border-radius:1px; width:85%;"></div>
							</div>
						</div>
						<div class="pg-help" style="margin:0; font-size:0.75rem;">Full-width document repository without side tree.</div>
					</div>

					<!--- 3/9 Grid Layout Card --->
					<div class="fe-layout-card is-selected" data-fe-layout="3/9" role="radio" aria-checked="true" tabindex="0" style="display:flex; flex-direction:column; gap:0.5rem;">
						<div style="display:flex; justify-content:space-between; align-items:center;">
							<strong style="font-size:0.9rem; color:var(--admin-text-main);">3/9 Grid Layout</strong>
							<span class="fe-radio-dot" style="width:16px; height:16px; border-radius:50%; border:2px solid var(--admin-primary); background:var(--admin-primary); display:inline-flex; align-items:center; justify-content:center;">
								<span style="width:6px; height:6px; border-radius:50%; background:##fff;"></span>
							</span>
						</div>
						<!--- 3/9 Grid Wireframe --->
						<div style="height:60px; background:var(--admin-bg, ##f1f5f9); border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:4px; padding:5px; display:grid; grid-template-columns:3fr 9fr; gap:4px;" aria-hidden="true">
							<div style="background:##ffffff; border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:2px; padding:4px; display:flex; flex-direction:column; gap:3px;">
								<div style="height:4px; background:##3b82f6; border-radius:1px; width:70%;"></div>
								<div style="height:3px; background:##cbd5e1; border-radius:1px; width:85%;"></div>
								<div style="height:3px; background:##cbd5e1; border-radius:1px; width:65%;"></div>
							</div>
							<div style="background:##ffffff; border:1px solid var(--admin-border-subtle, ##e2e8f0); border-radius:2px; padding:4px; display:flex; flex-direction:column; justify-content:space-around;">
								<div style="height:4px; background:##94a3b8; border-radius:1px; width:80%;"></div>
								<div style="height:4px; background:##cbd5e1; border-radius:1px; width:95%;"></div>
								<div style="height:4px; background:##cbd5e1; border-radius:1px; width:70%;"></div>
							</div>
						</div>
						<div class="pg-help" style="margin:0; font-size:0.75rem;">3-col folder tree navigation + 9-col files table grid.</div>
					</div>
				</div>
			</div>

			<div style="display:flex; justify-content:flex-end; gap:0.5rem; padding-top:1rem; border-top:1px solid var(--admin-border-subtle);">
				<button type="button" class="btn btn-outline btn-sm" id="pgDeleteFolderItem" hidden style="margin-right:auto; color:var(--admin-danger);">Delete</button>
			<button type="button" class="btn btn-outline btn-sm" id="pgCancelFolderItem">Cancel</button>
				<button type="button" class="btn btn-primary btn-sm" id="pgSaveFolderItem">Add Item</button>
			</div>
		</div>
	</section>
</div>
</cfoutput>

<script>
(function () {
	var menuSelect = document.getElementById("pgMenuItemSelect");
	if (!menuSelect) return;
	var helpEl = document.getElementById("pgMenuAssignmentHelp");

	function populateMenuOptions(options, selectedValue) {
		var targetValue = (typeof selectedValue === "string" ? selectedValue : "").trim();
		if (!targetValue) {
			targetValue = (menuSelect.getAttribute("data-initial-selected") || menuSelect.value || "").trim();
		}
		if (targetValue === "Top Level - Called from URL" || targetValue === "Assign to Main Menu Item") {
			targetValue = "";
		}
		// Strip any prior "(Current Assignment)" suffix
		targetValue = targetValue.replace(/\s*\(Current Assignment\)$/i, "").trim();

		menuSelect.innerHTML = "";
		var rawList = Array.isArray(options) ? options : [];

		if (rawList.length === 0) {
			var emptyOpt = document.createElement("option");
			emptyOpt.value = "";
			emptyOpt.textContent = "(No menu items defined for this workspace)";
			emptyOpt.selected = true;
			menuSelect.appendChild(emptyOpt);
			if (helpEl) {
				helpEl.textContent = "No menu structure defined yet for this workspace.";
			}
			menuSelect.removeAttribute("data-initial-selected");
			return;
		}

		if (helpEl) {
			helpEl.textContent = "Select the navigation item or parent page this belongs under.";
		}

		var matched = false;
		var groupEls = {};

		// Default placeholder option
		var defaultOpt = document.createElement("option");
		defaultOpt.value = "";
		defaultOpt.textContent = "-- Select Menu Item --";
		if (!targetValue) {
			defaultOpt.selected = true;
		}
		menuSelect.appendChild(defaultOpt);

		rawList.forEach(function (o) {
			if (!o) return;
			var label = (o.label !== undefined ? o.label : (o.LABEL !== undefined ? o.LABEL : "")).toString().trim();
			var group = (o.group !== undefined ? o.group : (o.GROUP !== undefined ? o.GROUP : "")).toString().trim();
			var depth = parseInt(o.depth !== undefined ? o.depth : (o.DEPTH !== undefined ? o.DEPTH : 0), 10) || 0;

			if (!label) return;

			var opt = document.createElement("option");
			opt.value = label;
			opt.textContent = "\u00A0\u00A0\u00A0\u00A0".repeat(depth) + label;

			if (targetValue && !matched && label.toLowerCase() === targetValue.toLowerCase()) {
				opt.selected = true;
				matched = true;
			}

			var container = menuSelect;
			if (group) {
				if (!groupEls[group]) {
					var grp = document.createElement("optgroup");
					grp.label = group;
					menuSelect.appendChild(grp);
					groupEls[group] = grp;
				}
				container = groupEls[group];
			}
			container.appendChild(opt);
		});

		// If a target assignment was set but wasn't found in this workspace's options, and this workspace actually has options, preserve it
		if (targetValue && !matched) {
			var opt = document.createElement("option");
			opt.value = targetValue;
			opt.textContent = targetValue + " (Current Assignment)";
			opt.selected = true;
			if (menuSelect.children.length > 1) {
				menuSelect.insertBefore(opt, menuSelect.children[1]);
			} else {
				menuSelect.appendChild(opt);
			}
		}

		if (menuSelect.value) {
			menuSelect.setAttribute("data-initial-selected", menuSelect.value);
		}
	}

	function loadMenuItems(wsId, targetValue) {
		var toKeep = (typeof targetValue === "string" ? targetValue : "").trim();
		if (!toKeep) {
			toKeep = (menuSelect.getAttribute("data-initial-selected") || menuSelect.value || "").trim();
		}
		toKeep = toKeep.replace(/\s*\(Current Assignment\)$/i, "").trim();

		// Show subtle loading state inside the dropdown
		var prevVal = menuSelect.value;
		var loadingOpt = document.createElement("option");
		loadingOpt.value = "";
		loadingOpt.disabled = true;
		loadingOpt.selected = true;
		loadingOpt.textContent = "Loading navigation menu hierarchy...";
		menuSelect.appendChild(loadingOpt);

		var url = "/pages/menu-items?ws=" + encodeURIComponent(wsId || "");
		if (toKeep && toKeep !== "Top Level - Called from URL" && toKeep !== "Assign to Main Menu Item") {
			url += "&selected=" + encodeURIComponent(toKeep);
		}

		return fetch(url, {
			credentials: "same-origin",
			headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
		})
		.then(function (r) { return r.ok ? r.json() : Promise.reject(); })
		.then(function (data) {
			var opts = [];
			if (data) {
				if (Array.isArray(data.options)) opts = data.options;
				else if (Array.isArray(data.OPTIONS)) opts = data.OPTIONS;
			}
			populateMenuOptions(opts, toKeep);
		})
		.catch(function (err) {
			console.error("Failed to load menu items", err);
			if (loadingOpt.parentNode === menuSelect) menuSelect.removeChild(loadingOpt);
		});
	}

	window.cmsadminLoadMenuItems = loadMenuItems;

	menuSelect.addEventListener("change", function () {
		if (this.value) {
			this.setAttribute("data-initial-selected", this.value);
		}
	});

	window.addEventListener("cmsadmin:workspaceChanged", function (e) {
		var wsId = e.detail && e.detail.id ? e.detail.id : "";
		var currentVal = menuSelect.getAttribute("data-initial-selected") || menuSelect.value || "";
		loadMenuItems(wsId, currentVal);
	});

	// If options only have the default placeholder or are empty, fetch immediately
	if (menuSelect.options.length <= 1) {
		var activeWs = menuSelect.getAttribute("data-page-workspace") || "";
		if (!activeWs) {
			try {
				var activeEl = document.querySelector(".workspace-item.is-active");
				if (activeEl) activeWs = activeEl.getAttribute("data-ws-id");
			} catch (err) {}
		}
		loadMenuItems(activeWs, menuSelect.getAttribute("data-initial-selected"));
	}
})();
(function () {
	var title = document.getElementById("pgTitle");
	var slug = document.getElementById("pgSlug");
	var vis = document.getElementById("pgVisibility");
	var sched = document.getElementById("pgScheduleWrap");
	var status = document.getElementById("pgSaveStatus");
	var layout = document.getElementById("pgLayout");
	var folderListingEnabled = document.getElementById("pgFolderListingEnabled");
	var folderListingControls = document.getElementById("pgFolderListingControls");
	var folderListingItems = document.getElementById("pgFolderListingItems");
	var folderListingStatus = document.getElementById("pgFolderListingStatus");
	var folderItemModal = document.getElementById("pgFolderItemModal");
	var folderItemTitle = document.getElementById("pgFolderItemTitle");
	var folderItemAbsolutePath = document.getElementById("pgFolderItemAbsolutePath");
	var folderItemRelativePath = document.getElementById("pgFolderItemRelativePath");
	var folderItemLayout = document.getElementById("pgFolderItemLayout");
	var folderItemStatus = document.getElementById("pgFolderItemStatus");
	var editingFolderItem = null;
	var folderItemFocusTarget = null;
	var folderItemRelTouched = false;

	// Layout Selection Logic (Full vs 3/9 Grid Layout)
	function setFolderItemLayout(layoutVal) {
		if (layoutVal !== "Full" && layoutVal !== "3/9") layoutVal = "3/9";
		if (folderItemLayout) folderItemLayout.value = layoutVal;
		var cards = folderItemModal.querySelectorAll(".fe-layout-card");
		cards.forEach(function (card) {
			var isMatch = card.dataset.feLayout === layoutVal;
			card.classList.toggle("is-selected", isMatch);
			card.setAttribute("aria-checked", isMatch ? "true" : "false");
			card.setAttribute("tabindex", isMatch ? "0" : "-1");
			var dot = card.querySelector(".fe-radio-dot");
			if (dot) {
				if (isMatch) {
					dot.style.borderColor = "var(--admin-primary)";
					dot.style.background = "var(--admin-primary)";
					dot.innerHTML = '<span style="width:6px; height:6px; border-radius:50%; background:#fff;"></span>';
				} else {
					dot.style.borderColor = "var(--admin-border)";
					dot.style.background = "transparent";
					dot.innerHTML = "";
				}
			}
		});
	}

	// Attach click & keyboard listeners to layout cards
	var feCards = folderItemModal.querySelectorAll(".fe-layout-card");
	feCards.forEach(function (card) {
		card.addEventListener("click", function () {
			setFolderItemLayout(card.dataset.feLayout);
		});
		card.addEventListener("keydown", function (e) {
			if (e.key === "Enter" || e.key === " ") {
				e.preventDefault();
				setFolderItemLayout(card.dataset.feLayout);
			} else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
				e.preventDefault();
				setFolderItemLayout("Full");
				var targetCard = folderItemModal.querySelector('[data-fe-layout="Full"]');
				if (targetCard) targetCard.focus();
			} else if (e.key === "ArrowRight" || e.key === "ArrowDown") {
				e.preventDefault();
				setFolderItemLayout("3/9");
				var targetCard = folderItemModal.querySelector('[data-fe-layout="3/9"]');
				if (targetCard) targetCard.focus();
			}
		});
	});

	// Auto-slug relative path from title input
	folderItemTitle.addEventListener("input", function () {
		if (!folderItemRelTouched || !folderItemRelativePath.value) {
			var raw = folderItemTitle.value.trim().toLowerCase();
			var slug = raw.replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
			if (slug) {
				folderItemRelativePath.value = "files/" + slug;
			}
		}
	});
	folderItemRelativePath.addEventListener("input", function () {
		folderItemRelTouched = true;
	});

	var sidebarInputs = document.querySelectorAll('input[name="sidebarIds"]');
	var sidebarHelp = document.getElementById("pgSidebarHelp");
	var sidebarPanel = document.getElementById("pgSidebarLayoutOptions");
	var subpageModal = document.getElementById("pgSubpageModal");
	var subpageTitle = document.getElementById("pgSubpageTitle");
	var subpageContent = document.getElementById("pgSubpageContent");
	var subpagePosition = document.getElementById("pgSubpagePosition");
	var subpageStatus = document.getElementById("pgSubpageCreateStatus");
	var subpageFocusTarget = null;
	var editingSubpage = null;
	var slugTouched = false;

	function updateSidebarAvailability() {
		var hasSidebarLayout = layout && layout.value === "Right Sidebar";
		sidebarPanel.hidden = !hasSidebarLayout;
		Array.prototype.forEach.call(sidebarInputs, function (input) {
			input.disabled = !hasSidebarLayout;
			if (!hasSidebarLayout) input.checked = false;
		});
		if (hasSidebarLayout) sidebarHelp.textContent = "Select one or more sidebars for this page.";
	}
	layout.addEventListener("change", function () {
		updateSidebarAvailability();
	});
	folderListingEnabled.addEventListener("change", function () {
		folderListingControls.hidden = !folderListingEnabled.checked;
	});
	document.querySelectorAll("[data-attr-tab]").forEach(function (tabBtn) {
		tabBtn.addEventListener("click", function () {
			var mode = tabBtn.getAttribute("data-attr-tab");
			document.querySelectorAll("[data-attr-tab]").forEach(function (btn) {
				var isActive = (btn === tabBtn);
				btn.classList.toggle("is-active", isActive);
				btn.setAttribute("aria-selected", isActive ? "true" : "false");
			});
			var panels = {
				layout: document.getElementById("tabPanelAttrLayout"),
				nav: document.getElementById("tabPanelAttrNav"),
				folder: document.getElementById("tabPanelAttrFolder")
			};
			Object.keys(panels).forEach(function (key) {
				if (panels[key]) {
					panels[key].hidden = (key !== mode);
				}
			});
		});
	});
	var folderContentId = parseInt(folderListingControls.dataset.contentId, 10) || 0;

	function folderField(obj, name) {
		if (!obj || typeof obj !== "object") return undefined;
		var key = Object.keys(obj).find(function (k) { return k.toLowerCase() === name.toLowerCase(); });
		return key === undefined ? undefined : obj[key];
	}
	function folderPostJson(url, data) {
		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var headers = { "Content-Type": "application/json", "X-Requested-With": "XMLHttpRequest" };
		if (csrfMeta) headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
		return fetch(url, { method: "POST", credentials: "same-origin", headers: headers, body: JSON.stringify(data) })
			.then(function (response) {
				return response.text().then(function (body) {
					var result;
					try { result = JSON.parse(body); } catch (e) { throw new Error("The server returned an unexpected response (HTTP " + response.status + ")."); }
					if (!response.ok || folderField(result, "success") !== true) {
						throw new Error(folderField(result, "message") || "Request failed (HTTP " + response.status + ").");
					}
					var item = folderField(result, "item");
					return { item: {
						id: folderField(item, "id"),
						title: folderField(item, "title"),
						absolutePath: folderField(item, "absolutePath"),
						relativePath: folderField(item, "relativePath"),
						layout: folderField(item, "layout"),
						body: folderField(item, "body"),
						position: folderField(item, "position")
					} };
				});
			});
	}

	var pgParent = document.getElementById("pgParent");
	var pgMenuAssignmentWrap = document.getElementById("pgMenuAssignmentWrap");

	function updateMenuAssignmentVisibility() {
		if (!pgParent || !pgMenuAssignmentWrap) return;
		var val = pgParent.value;
		var isMenu = (val === "Assign to Main Menu Item" || val === "Assign to Menu Item");
		pgMenuAssignmentWrap.style.display = isMenu ? "block" : "none";
		pgMenuAssignmentWrap.hidden = !isMenu;
		if (isMenu && typeof window.cmsadminLoadMenuItems === "function") {
			var menuSel = document.getElementById("pgMenuItemSelect");
			if (menuSel && menuSel.options.length <= 1) {
				var activeWs = menuSel.getAttribute("data-page-workspace") || "";
				if (!activeWs) {
					try {
						var activeEl = document.querySelector(".workspace-item.is-active");
						if (activeEl) activeWs = activeEl.getAttribute("data-ws-id");
					} catch (err) {}
				}
				window.cmsadminLoadMenuItems(activeWs, menuSel.getAttribute("data-initial-selected") || menuSel.value || "");
			}
		}
	}

	if (pgParent) {
		pgParent.addEventListener("change", updateMenuAssignmentVisibility);
		updateMenuAssignmentVisibility(); // Run on load to guarantee initial state
	}

	function openFolderItemModal(row) {
		if (folderItemModal.parentNode !== document.body) {
			document.body.appendChild(folderItemModal);
		}
		document.body.style.overflow = "hidden";
		editingFolderItem = row;
		folderItemFocusTarget = row ? row.querySelector("[data-edit-folder-item]") : document.getElementById("pgAddFolderListingItem");
		folderItemStatus.textContent = "";
		var headingSpan = document.getElementById("pgFolderItemModalTitle").querySelector("span");
		if (headingSpan) headingSpan.textContent = row ? "Edit Folder Explorer Item" : "Add Folder Explorer Item";
		document.getElementById("pgSaveFolderItem").textContent = row ? "Save Changes" : "Add Item";
		document.getElementById("pgDeleteFolderItem").hidden = !row;
		if (row) {
			folderItemTitle.value = row.dataset.title || "";
			folderItemAbsolutePath.value = row.dataset.absolutePath || "";
			folderItemRelativePath.value = row.dataset.relativePath || (row.dataset.path ? row.dataset.path.replace(/^\//, "") : "");
			setFolderItemLayout(row.dataset.layout || "3/9");
			folderItemRelTouched = true;
		} else {
			folderItemTitle.value = "";
			folderItemAbsolutePath.value = "";
			folderItemRelativePath.value = "";
			setFolderItemLayout("3/9");
			folderItemRelTouched = false;
		}
		folderItemModal.classList.add("is-open");
		folderItemModal.setAttribute("aria-hidden", "false");
		folderItemTitle.focus();
	}

	function closeFolderItemModal() {
		folderItemModal.classList.remove("is-open");
		folderItemModal.setAttribute("aria-hidden", "true");
		document.body.style.overflow = "";
		if (folderItemFocusTarget) folderItemFocusTarget.focus();
	}

	document.getElementById("pgAddFolderListingItem").addEventListener("click", function () {
		openFolderItemModal(null);
	});
	document.getElementById("pgCloseFolderModal").addEventListener("click", closeFolderItemModal);
	document.getElementById("pgCancelFolderItem").addEventListener("click", closeFolderItemModal);
	folderItemModal.querySelector("[data-close-folder-modal]").addEventListener("click", closeFolderItemModal);
	folderListingItems.addEventListener("click", async function (event) {
		var editButton = event.target.closest("[data-edit-folder-item]");
		if (editButton) openFolderItemModal(editButton.closest(".pg-subpage-row"));
	});

	document.getElementById("pgDeleteFolderItem").addEventListener("click", async function () {
		var rmRow = editingFolderItem;
		if (!rmRow) return;
		var rmId = parseInt(rmRow.dataset.id, 10) || 0;
		if (!rmId) { rmRow.remove(); closeFolderItemModal(); return; }
		if (!await window.adminConfirm("Remove \"" + (rmRow.dataset.title || "this item") + "\" from this workspace?", {
			title: "Remove folder explorer item?",
			acceptText: "Remove",
			destructive: true
		})) return;
		folderPostJson(folderListingControls.dataset.deleteUrl, { id: rmId, contentId: folderContentId })
			.then(function () {
				rmRow.remove();
				editingFolderItem = null;
				folderItemFocusTarget = document.getElementById("pgAddFolderListingItem");
				closeFolderItemModal();
				folderListingStatus.textContent = "";
				window.adminAlert("Folder explorer item removed.", { title: "Item removed" });
			})
			.catch(function (err) {
				window.adminAlert(err.message, { title: "Unable to remove item" });
			});
	});

	document.getElementById("pgSaveFolderItem").addEventListener("click", async function () {
		var name = folderItemTitle.value.trim();
		var absPath = folderItemAbsolutePath.value.trim();
		var relPath = folderItemRelativePath.value.trim().replace(/^\/+/, "");
		var layVal = folderItemLayout ? folderItemLayout.value : "3/9";

		if (!name) {
			await window.adminAlert("Please enter a Title for this folder explorer item.", { title: "Title required" });
			folderItemTitle.focus();
			return;
		}
		if (!absPath) {
			await window.adminAlert("Please enter the Server Absolute Path.", { title: "Absolute path required" });
			folderItemAbsolutePath.focus();
			return;
		}
		if (!relPath) {
			await window.adminAlert("Please enter the Web URL Relative Path.", { title: "Relative path required" });
			folderItemRelativePath.focus();
			return;
		}

		if (!folderContentId) {
			await window.adminAlert("Save the page first, then add folder explorer items.", { title: "Page not saved" });
			return;
		}
		var saveBtn = this;
		saveBtn.disabled = true;
		folderPostJson(folderListingControls.dataset.saveUrl, {
			id: editingFolderItem ? (parseInt(editingFolderItem.dataset.id, 10) || 0) : 0,
			contentId: folderContentId,
			title: name,
			absolutePath: absPath,
			relativePath: relPath,
			layout: layVal
		}).then(function (result) {
		var wasEditing = !!editingFolderItem;
		var row = editingFolderItem || document.createElement("div");
		row.dataset.id = result.item.id;
		if (!editingFolderItem) {
			row.className = "pg-subpage-row";
			row.style.cssText = "padding:0.45rem 0; gap:0.5rem; border-bottom:1px dashed var(--admin-border-subtle); display:flex; align-items:center;";
			var itemLabel = document.createElement("label");
			itemLabel.style.cssText = "display:flex; align-items:flex-start; gap:0.5rem; flex:1; min-width:0; cursor:pointer;";
			var checkbox = document.createElement("input");
			checkbox.type = "checkbox";
			checkbox.name = "folderListingItems";
			checkbox.value = "/" + relPath;
			checkbox.style.cssText = "width:18px; height:18px; margin-top:0.15rem; flex-shrink:0; accent-color:var(--admin-primary);";
			var details = document.createElement("span");
			details.style.cssText = "min-width:0; flex:1;";
			var itemTitle = document.createElement("strong");
			itemTitle.dataset.folderTitle = "";
			itemTitle.style.cssText = "display:block; color:var(--admin-text-main); font-size:0.875rem;";
			var subInfo = document.createElement("span");
			subInfo.className = "pg-help";
			subInfo.style.cssText = "margin:0; font-size:0.75rem; display:flex; align-items:center; gap:0.35rem; flex-wrap:wrap;";
			var codeTag = document.createElement("code");
			codeTag.dataset.folderRelative = "";
			codeTag.style.cssText = "font-size:0.72rem; color:var(--admin-primary); background:rgba(30,58,138,0.06); padding:0.1rem 0.3rem; border-radius:3px;";
			var bullet = document.createElement("span");
			bullet.textContent = "•";
			var layoutBadge = document.createElement("span");
			layoutBadge.className = "badge badge-neutral";
			layoutBadge.dataset.folderLayoutBadge = "";
			layoutBadge.style.cssText = "font-size:0.68rem; padding:0.1rem 0.4rem;";

			subInfo.appendChild(codeTag);
			subInfo.appendChild(bullet);
			subInfo.appendChild(layoutBadge);
			details.appendChild(itemTitle);
			details.appendChild(subInfo);

			itemLabel.appendChild(checkbox);
			itemLabel.appendChild(details);

			var editButton = document.createElement("button");
			editButton.type = "button";
			editButton.className = "btn btn-outline btn-sm btn-icon-only";
			editButton.dataset.editFolderItem = "";
			editButton.title = "Edit";
			editButton.setAttribute("aria-label", "Edit");
			editButton.innerHTML = document.getElementById("pgIconEdit").innerHTML;

			row.appendChild(itemLabel);
			row.appendChild(editButton);
		}

		row.dataset.title = name;
		row.dataset.path = "/" + relPath;
		row.dataset.absolutePath = absPath;
		row.dataset.relativePath = relPath;
		row.dataset.layout = layVal;

		var cb = row.querySelector('input[name="folderListingItems"]');
		if (cb) {
			cb.value = "/" + relPath;
			cb.dataset.folderId = result.item.id;
			cb.checked = true;
		}
		var titleEl = row.querySelector("[data-folder-title]");
		if (titleEl) titleEl.textContent = name;
		var codeEl = row.querySelector("[data-folder-relative]");
		if (codeEl) codeEl.textContent = "/" + relPath;
		var badgeEl = row.querySelector("[data-folder-layout-badge]");
		if (badgeEl) badgeEl.textContent = (layVal === "3/9" ? "3/9 Grid" : "Full Width");
		var editBtn = row.querySelector("[data-edit-folder-item]");
		if (editBtn) editBtn.setAttribute("aria-label", "Edit " + name);

		if (!wasEditing) {
			folderListingItems.appendChild(row);
		}

		folderListingStatus.textContent = "";
		closeFolderItemModal();
		window.adminAlert(
			wasEditing
				? 'Folder explorer item "' + name + '" updated.'
				: 'Folder explorer item "' + name + '" added.',
			{ title: wasEditing ? "Item updated" : "Item added" }
		);
		}).catch(function (err) {
			window.adminAlert(err.message, { title: "Unable to save item" });
		}).then(function () {
			saveBtn.disabled = false;
		});
	});
	document.addEventListener("keydown", function (event) {
		if (event.key === "Escape" && folderItemModal.classList.contains("is-open")) closeFolderItemModal();
	});
	function getSubpageEditor() {
		var ed = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#pgSubpageContent") : null;
		if (!ed && typeof JBDEditor !== "undefined") {
			var el = document.getElementById("pgSubpageContent");
			if (el) {
				ed = JBDEditor.attach(el, {
					toolbar: 'subpage',
					height: '260px',
					placeholder: 'Write subpage content, add paragraphs, lists, links, or insert templates...'
				});
			}
		}
		return ed;
	}

	var SUBPAGE_TEMPLATE_MAP = {
		'table-of-contents': '<nav class="jbd-template jbd-toc" aria-label="Table of Contents">\n  <div class="jbd-toc-header">\n    <span class="jbd-toc-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><circle cx="4" cy="6" r="1.5" fill="currentColor"/><circle cx="4" cy="12" r="1.5" fill="currentColor"/><circle cx="4" cy="18" r="1.5" fill="currentColor"/></svg></span>\n    <strong class="jbd-toc-title">On This Page</strong>\n  </div>\n  <ol class="jbd-toc-list">\n    <li><a href="#overview">Overview &amp; Purpose</a></li>\n    <li><a href="#requirements">Key Requirements</a></li>\n    <li><a href="#process">Step-by-Step Process</a></li>\n    <li><a href="#contact">Contact &amp; Assistance</a></li>\n  </ol>\n</nav>',
		'subpage-menu': '<nav class="jbd-template jbd-subpage-menu" aria-label="Subpage Navigation">\n  <div class="jbd-subpage-menu-header">\n    <span class="jbd-subpage-menu-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg></span>\n    <strong class="jbd-subpage-menu-title">In This Section</strong>\n  </div>\n  <ul class="jbd-subpage-menu-list">\n    <li><a href="#subpage-1" aria-current="page">Current Subpage Overview</a></li>\n    <li><a href="#subpage-2">Department Services &amp; Applications</a></li>\n    <li><a href="#subpage-3">Permits &amp; Regulations</a></li>\n    <li><a href="#subpage-4">Frequently Asked Questions</a></li>\n  </ul>\n</nav>',
		'related-pages': '<nav class="jbd-template jbd-related-pages" aria-label="Related Pages">\n  <div class="jbd-related-pages-header">\n    <span class="jbd-related-pages-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg></span>\n    <strong class="jbd-related-pages-title">Related Pages &amp; Guides</strong>\n  </div>\n  <ul class="jbd-related-pages-list">\n    <li>\n      <a href="/assessor">Assessor &amp; Property Information</a>\n      <span class="jbd-related-pages-desc">Search parcel maps, real property data, and tax assessment schedules.</span>\n    </li>\n    <li>\n      <a href="/treasurer">Treasurer &amp; Tax Payments</a>\n      <span class="jbd-related-pages-desc">Online payment portals, payment options, and fee schedules.</span>\n    </li>\n    <li>\n      <a href="/community-development">Community Development &amp; Planning</a>\n      <span class="jbd-related-pages-desc">Zoning code, building permits, and comprehensive plan amendments.</span>\n    </li>\n  </ul>\n</nav>',
		'panel-info': '<aside class="jbd-template jbd-panel jbd-panel-info" aria-label="Information Panel">\n  <div class="jbd-panel-header">\n    <span class="jbd-panel-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg></span>\n    <p class="jbd-panel-title h4">Department Service Notice</p>\n    <span class="jbd-panel-badge" aria-hidden="true">INFO</span>\n  </div>\n  <div class="jbd-panel-body">\n    <p>Important details or announcements regarding this service or page content.</p>\n  </div>\n</aside>',
		'panel-warning': '<aside class="jbd-template jbd-panel jbd-panel-warning" aria-label="Warning Panel">\n  <div class="jbd-panel-header">\n    <span class="jbd-panel-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg></span>\n    <p class="jbd-panel-title h4">Attention Required</p>\n    <span class="jbd-panel-badge" aria-hidden="true">WARNING</span>\n  </div>\n  <div class="jbd-panel-body">\n    <p>Please double-check filing deadlines and required supporting documentation before submitting.</p>\n  </div>\n</aside>',
		'related-links': '<nav class="jbd-template jbd-related-links" aria-label="Related Links and Resources">\n  <div class="jbd-related-header">\n    <span class="jbd-related-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg></span>\n    <strong class="jbd-related-title">Related Resources &amp; Links</strong>\n  </div>\n  <ul class="jbd-related-list">\n    <li>\n      <a href="#county-code">Chelan County Code &amp; Regulations</a>\n      <span class="jbd-related-desc">Official municipal code and legislative records</span>\n    </li>\n    <li>\n      <a href="#permit-portal">Online Applications &amp; Forms</a>\n      <span class="jbd-related-desc">Downloadable forms and electronic filing portal</span>\n    </li>\n    <li>\n      <a href="#public-notices">Public Notices &amp; Meeting Agendas</a>\n      <span class="jbd-related-desc">Upcoming hearing schedules and community notices</span>\n    </li>\n  </ul>\n</nav>',
		'references-authority': '<section class="jbd-template jbd-references" aria-label="References and Statutory Authority">\n  <div class="jbd-references-header">\n    <span class="jbd-references-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z"/><line x1="8" y1="7" x2="16" y2="7"/><line x1="8" y1="11" x2="14" y2="11"/></svg></span>\n    <strong class="jbd-references-title">References &amp; Statutory Authority</strong>\n  </div>\n  <ul class="jbd-references-list">\n    <li>\n      <span class="jbd-ref-badge">RCW 36.32</span>\n      <span class="jbd-ref-text">Revised Code of Washington &mdash; County Commissioners General Powers</span>\n    </li>\n    <li>\n      <span class="jbd-ref-badge">CCC Title 14</span>\n      <span class="jbd-ref-text">Chelan County Code &mdash; Development Standards &amp; Administration</span>\n    </li>\n    <li>\n      <span class="jbd-ref-badge">Policy &num;2024-03</span>\n      <span class="jbd-ref-text">Department Operating Procedure &amp; Review Timeline</span>\n    </li>\n  </ul>\n</section>',
		'contact-hours': '<aside class="jbd-template jbd-contact-card" aria-label="Department Contact and Hours">\n  <div class="jbd-contact-header">\n    <span class="jbd-contact-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg></span>\n    <strong class="jbd-contact-title">Office Hours &amp; Location</strong>\n  </div>\n  <div class="jbd-contact-body">\n    <p><strong>Location:</strong> 350 Orondo Ave, Suite 201, Wenatchee, WA 98801</p>\n    <p><strong>Hours:</strong> Monday &ndash; Friday: 8:00 AM &ndash; 5:00 PM</p>\n    <p><strong>Phone:</strong> <a href="tel:5096676100">(509) 667-6100</a></p>\n    <p><strong>Email:</strong> <a href="mailto:info@chelancounty.gov">info@chelancounty.gov</a></p>\n  </div>\n</aside>',
		'callout-info': '<aside class="jbd-template jbd-callout jbd-callout-info" aria-label="Note: Information">\n  <div class="jbd-callout-header">\n    <span class="jbd-callout-badge" aria-hidden="true">INFO</span>\n    <strong class="jbd-callout-title">Important Note</strong>\n  </div>\n  <p>Enter your key takeaway or instructions for the reader here.</p>\n</aside>',
		'cta-card': '<aside class="jbd-template jbd-cta-card" aria-label="Action: Online Service">\n  <div class="jbd-cta-card-header">\n    <span class="jbd-cta-badge" aria-hidden="true">ONLINE SERVICE</span>\n    <p class="jbd-cta-title h4">Apply for Department Permits &amp; Licenses</p>\n  </div>\n  <p class="jbd-cta-desc">Submit your applications, upload engineering documents, and track review status securely through our citizen portal.</p>\n  <div class="jbd-cta-card-footer">\n    <a href="#portal" class="jbd-btn jbd-btn-primary jbd-cta-btn" aria-label="Apply online for Department Permits and Licenses">\n      <span>Begin Online Application</span>\n      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>\n    </a>\n  </div>\n</aside>',
		'cta-grid': '<section class="jbd-template jbd-cta-grid" aria-label="Popular online actions">\n  <article class="jbd-cta-card">\n    <div class="jbd-cta-card-header">\n      <span class="jbd-cta-badge jbd-cta-badge-teal" aria-hidden="true">PAYMENT</span>\n      <p class="jbd-cta-title h4">Pay Taxes &amp; Fees Online</p>\n    </div>\n    <p class="jbd-cta-desc">Pay real property taxes, assessment fees, and administrative charges with e-check or card.</p>\n    <div class="jbd-cta-card-footer">\n      <a href="#pay" class="jbd-btn jbd-btn-primary jbd-cta-btn" aria-label="Make an online payment for taxes and fees">\n        <span>Pay Online Now</span>\n        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>\n      </a>\n    </div>\n  </article>\n  <article class="jbd-cta-card">\n    <div class="jbd-cta-card-header">\n      <span class="jbd-cta-badge jbd-cta-badge-blue" aria-hidden="true">PUBLIC RECORDS</span>\n      <p class="jbd-cta-title h4">Submit Public Records Request</p>\n    </div>\n    <p class="jbd-cta-desc">Request county government records under RCW 42.56 with our automated disclosure portal.</p>\n    <div class="jbd-cta-card-footer">\n      <a href="#records" class="jbd-btn jbd-btn-primary jbd-cta-btn" aria-label="Submit a public records disclosure request">\n        <span>Submit Request</span>\n        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>\n      </a>\n    </div>\n  </article>\n</section>',
		'cta-banner': '<aside class="jbd-template jbd-cta-banner" aria-label="Action required">\n  <div class="jbd-cta-banner-content">\n    <span class="jbd-cta-banner-badge" aria-hidden="true">NEXT STEP</span>\n    <p class="jbd-cta-banner-title h4">Need assistance completing your submission?</p>\n    <p class="jbd-cta-banner-lead">Our department specialists are available Monday through Friday from 8:00 AM to 5:00 PM to help you navigate requirements.</p>\n  </div>\n  <div class="jbd-cta-banner-action">\n    <a href="#contact" class="jbd-btn jbd-cta-banner-btn" aria-label="Contact our department specialists for assistance">\n      <span>Contact Office Specialist</span>\n      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>\n    </a>\n  </div>\n</aside>',
		'faq-item': '<div class="jbd-template jbd-faq-block" aria-label="Frequently Asked Questions">\n  <div class="jbd-faq-item">\n    <div class="jbd-faq-header">\n      <span class="jbd-faq-badge" aria-hidden="true">Q&amp;A</span>\n      <p class="jbd-faq-question h4">What are the requirements for this procedure?</p>\n    </div>\n    <div class="jbd-faq-answer">\n      <p>Provide clear, concise details about eligibility, deadlines, and next steps.</p>\n    </div>\n  </div>\n</div>',
		'steps-process': '<ol class="jbd-template jbd-steps" aria-label="Step by step instructions">\n  <li class="jbd-step">\n    <div class="jbd-step-badge" aria-hidden="true">1</div>\n    <div class="jbd-step-body">\n      <strong class="jbd-step-title">Step 1: Preparation</strong>\n      <p>Gather the necessary documentation and review prerequisites.</p>\n    </div>\n  </li>\n  <li class="jbd-step">\n    <div class="jbd-step-badge" aria-hidden="true">2</div>\n    <div class="jbd-step-body">\n      <strong class="jbd-step-title">Step 2: Submission</strong>\n      <p>Submit your application in person, by mail, or through the online portal.</p>\n    </div>\n  </li>\n</ol>'
	};

	function closeSubpageModal() {
		subpageModal.classList.remove("is-open");
		subpageModal.setAttribute("aria-hidden", "true");
		if (subpageFocusTarget) subpageFocusTarget.focus();
	}
	function openSubpageModal() {
		editingSubpage = null;
		document.getElementById("pgSubpageModalTitle").textContent = "Create Subpage";
		document.getElementById("pgSaveSubpage").textContent = "Save Subpage";
		subpageTitle.value = "";
		var ed = getSubpageEditor();
		if (ed) {
			ed.setHTML("");
			if (ed.history) ed.history.clear();
		} else if (subpageContent) {
			subpageContent.value = "";
		}
		var tmplSel = document.getElementById("pgSubpageTemplateSelect");
		if (tmplSel) tmplSel.value = "";
		subpagePosition.value = document.querySelectorAll("#pgSidebarChooser [data-subpage-title]").length + 1;
		subpageStatus.textContent = "";
		document.getElementById("pgDeleteSubpage").hidden = true;
		subpageFocusTarget = document.activeElement;
		subpageModal.classList.add("is-open");
		subpageModal.setAttribute("aria-hidden", "false");
		subpageTitle.focus();
	}
	function openEditSubpageModal(input) {
		editingSubpage = input;
		document.getElementById("pgSubpageModalTitle").textContent = "Edit Subpage";
		document.getElementById("pgSaveSubpage").textContent = "Save Changes";
		subpageTitle.value = input.dataset.subpageTitle || "";
		var existingBody = input.dataset.content || "";
		var ed = getSubpageEditor();
		if (ed) {
			ed.setHTML(existingBody);
			if (ed.history) ed.history.clear();
		} else if (subpageContent) {
			subpageContent.value = existingBody;
		}
		var tmplSel = document.getElementById("pgSubpageTemplateSelect");
		if (tmplSel) tmplSel.value = "";
		subpagePosition.value = input.dataset.position || 0;
		subpageStatus.textContent = "";
		document.getElementById("pgDeleteSubpage").hidden = false;
		subpageFocusTarget = input.closest(".pg-subpage-row").querySelector("[data-edit-subpage]");
		subpageModal.classList.add("is-open");
		subpageModal.setAttribute("aria-hidden", "false");
		subpageTitle.focus();
	}
	var openSubpageButton = document.getElementById("pgOpenSubpageModal");
	if (openSubpageButton) openSubpageButton.addEventListener("click", openSubpageModal);
	document.getElementById("pgCloseSubpageModal").addEventListener("click", closeSubpageModal);
	document.getElementById("pgCancelSubpage").addEventListener("click", closeSubpageModal);
	subpageModal.querySelector("[data-close-subpage-modal]").addEventListener("click", closeSubpageModal);
	document.addEventListener("keydown", function (event) {
		if (event.key === "Escape" && subpageModal.classList.contains("is-open")) closeSubpageModal();
	});

	try {
		var spUrlParams = new URLSearchParams(window.location.search);
		if ((spUrlParams.get("createSubpage") === "1" || spUrlParams.get("addSubpage") === "1") && openSubpageButton) {
			setTimeout(function () {
				openSubpageModal();
			}, 250);
		}
	} catch (eParam) {}
	document.getElementById("pgSidebarChooser").addEventListener("click", function (event) {
		var editButton = event.target.closest("[data-edit-subpage]");
		if (!editButton) return;
		event.preventDefault();
		openEditSubpageModal(editButton.closest(".pg-subpage-row").querySelector('input[name="sidebarIds"]'));
	});

	var btnSubpageApply = document.getElementById("btnSubpageApplyTemplate");
	if (btnSubpageApply) {
		btnSubpageApply.addEventListener("click", function () {
			var sel = document.getElementById("pgSubpageTemplateSelect");
			var val = sel ? sel.value : "";
			if (!val) {
				if (window.adminAlert) {
					window.adminAlert("Please select a template from the dropdown list to insert.", { title: "Select a Template" });
				}
				return;
			}
			var html = SUBPAGE_TEMPLATE_MAP[val];
			if (!html && typeof JBDEditor !== "undefined" && JBDEditor.DEFAULT_BLOCK_TEMPLATES) {
				var found = JBDEditor.DEFAULT_BLOCK_TEMPLATES.find(function (t) { return t.id === val; });
				if (found) html = found.html;
			}
			if (html) {
				var ed = getSubpageEditor();
				if (ed) {
					if (typeof ed.insertTemplate === "function") {
						ed.insertTemplate(html);
					} else if (typeof ed.insertHTML === "function") {
						ed.insertHTML(html);
					}
					ed.focus();
				}
			}
		});
	}

	var btnSubpageBrowse = document.getElementById("btnSubpageBrowseTemplates");
	if (btnSubpageBrowse) {
		btnSubpageBrowse.addEventListener("click", function () {
			var ed = getSubpageEditor();
			if (ed && typeof ed.openTemplateModal === "function") {
				ed.openTemplateModal();
			}
		});
	}

	function subpageUrls() {
		var btn = document.getElementById("pgOpenSubpageModal");
		return {
			save: btn ? (btn.dataset.saveUrl || "") : "",
			del: btn ? (btn.dataset.deleteUrl || "") : "",
			contentId: btn ? (parseInt(btn.dataset.contentId, 10) || 0) : 0,
			siteId: btn ? (btn.dataset.siteId || "") : ""
		};
	}
	function buildSubpageRow(item) {
		var row = document.createElement("div");
		row.className = "pg-subpage-row";
		row.style.cssText = "padding:0.35rem 0; gap:0.5rem;";
		var optionLabel = document.createElement("label");
		optionLabel.style.cssText = "display:flex; align-items:center; gap:0.5rem; flex:1; min-width:0; cursor:pointer;";
		var checkbox = document.createElement("input");
		checkbox.type = "checkbox";
		checkbox.name = "sidebarIds";
		checkbox.value = "subpage-" + item.id;
		checkbox.dataset.id = item.id;
		checkbox.checked = true;
		checkbox.style.cssText = "width:18px; height:18px; margin-top:0.1rem; flex-shrink:0; accent-color:var(--admin-primary);";
		var details = document.createElement("span");
		var heading = document.createElement("strong");
		heading.dataset.subpageTitle = "";
		heading.style.cssText = "display:block; color:var(--admin-text-main); font-size:0.85rem;";
		details.appendChild(heading);
		optionLabel.appendChild(checkbox);
		optionLabel.appendChild(details);
		var editButton = document.createElement("button");
		editButton.type = "button";
		editButton.className = "btn btn-outline btn-sm btn-icon-only";
		editButton.dataset.editSubpage = "";
		editButton.title = "Edit";
		editButton.setAttribute("aria-label", "Edit");
		editButton.innerHTML = document.getElementById("pgIconEdit").innerHTML;
		row.appendChild(optionLabel);
		row.appendChild(editButton);
		return row;
	}
	function applySubpageToRow(row, item) {
		var checkbox = row.querySelector('input[name="sidebarIds"]');
		checkbox.dataset.subpageTitle = item.title;
		checkbox.dataset.content = item.body || "";
		checkbox.dataset.position = item.position;
		row.querySelector("strong[data-subpage-title]").textContent = item.title;
		row.querySelector("[data-edit-subpage]").setAttribute("aria-label", "Edit " + item.title);
	}
	document.getElementById("pgSaveSubpage").addEventListener("click", async function () {
		var saveButton = this;
		var name = subpageTitle.value.trim();
		if (!name) {
			await window.adminAlert("Enter a title / header for the subpage.", { title: "Title required" });
			subpageTitle.focus();
			return;
		}
		var urls = subpageUrls();
		var position = Math.max(0, parseInt(subpagePosition.value, 10) || 0);
		var ed = getSubpageEditor();
		var bodyContent = ed ? ed.getHTML() : (subpageContent ? subpageContent.value : "");
		saveButton.disabled = true;
		subpageStatus.textContent = "Saving...";
		try {
			var result = await folderPostJson(urls.save, {
				id: editingSubpage ? parseInt(editingSubpage.dataset.id, 10) || 0 : 0,
				contentId: urls.contentId,
				siteId: urls.siteId,
				title: name,
				body: bodyContent,
				position: position
			});
			var item = { id: result.item.id, title: result.item.title, body: result.item.body, position: result.item.position };
			var row;
			if (editingSubpage) {
				row = editingSubpage.closest(".pg-subpage-row");
			} else {
				var noMsg = document.getElementById("pgNoSidebarsMsg");
				if (noMsg) noMsg.remove();
				row = buildSubpageRow(item);
				document.getElementById("pgSidebarChooser").appendChild(row);
				sidebarInputs = document.querySelectorAll('input[name="sidebarIds"]');
			}
			applySubpageToRow(row, item);
			subpageStatus.textContent = "";
			closeSubpageModal();
			await window.adminAlert("The subpage was saved.", { title: "Subpage saved" });
		} catch (err) {
			subpageStatus.textContent = "";
			await window.adminAlert(err.message || "Request failed.", { title: "Unable to save subpage" });
		} finally {
			saveButton.disabled = false;
		}
	});
	document.getElementById("pgDeleteSubpage").addEventListener("click", async function () {
		if (!editingSubpage) return;
		var urls = subpageUrls();
		var row = editingSubpage.closest(".pg-subpage-row");
		var ok = await window.adminConfirm("Delete the subpage \"" + (editingSubpage.dataset.subpageTitle || "") + "\"? This cannot be undone.", {
			title: "Delete subpage", acceptText: "Delete", destructive: true
		});
		if (!ok) return;
		try {
			await folderPostJson(urls.del, { id: parseInt(editingSubpage.dataset.id, 10) || 0, contentId: urls.contentId, siteId: urls.siteId });
			row.remove();
			sidebarInputs = document.querySelectorAll('input[name="sidebarIds"]');
			closeSubpageModal();
		} catch (err) {
			await window.adminAlert(err.message || "Request failed.", { title: "Unable to delete subpage" });
		}
	});	updateSidebarAvailability();

	slug.addEventListener("input", function () {
		slugTouched = (slug.value.trim().length > 0);
	});
	function updateSlugFromTitle() {
		if (!slugTouched && !slug.readOnly) {
			slug.value = title.value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
		}
	}
	title.addEventListener("input", updateSlugFromTitle);
	title.addEventListener("change", updateSlugFromTitle);
	vis.addEventListener("change", function () { sched.hidden = vis.value !== "Scheduled"; });

	var btnSavePage = document.getElementById("btnSavePage");
	document.getElementById("pageEditForm").addEventListener("submit", function (e) {
		e.preventDefault();
		if (!title.value.trim()) {
			title.setAttribute("aria-invalid", "true");
			status.className = "";
			status.style.cssText = "background:var(--admin-danger-light); color:var(--admin-danger); border:1px solid var(--admin-danger); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
			status.textContent = "Page title is required.";
			title.focus();
			return;
		}

		title.removeAttribute("aria-invalid");

		// Show instant tactile loading feedback on button & top progress
		var origBtnHtml = btnSavePage.innerHTML;
		btnSavePage.disabled = true;
		btnSavePage.classList.add("is-loading");
		btnSavePage.innerHTML = '<span class="admin-spinner-sm" style="margin-right:6px;" aria-hidden="true"></span> <span>Saving Page...</span>';

		if (typeof window.startTopProgress === "function") {
			window.startTopProgress();
		}

		status.className = "";
		status.style.cssText = "background:var(--admin-info-light); color:var(--admin-info); border:1px solid var(--admin-info); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
		status.textContent = "Saving page attributes to database...";

		var sidebarChecked = Array.from(document.querySelectorAll('input[name="sidebarIds"]:checked')).map(function(el) { return el.value; });
		var folderCheckedIds = Array.from(document.querySelectorAll('input[name="folderListingItems"]:checked')).map(function(el) {
			var r = el.closest(".pg-subpage-row");
			return parseInt(el.dataset.folderId || (r && r.dataset.id) || 0, 10) || 0;
		}).filter(function(id) { return id > 0; });
		var publishAtEl = document.getElementById("pgPublishAt");
		var unpublishAtEl = document.getElementById("pgUnpublishAt");
		var parentAssignmentEl = document.getElementById("pgParent");
		var parentVal = parentAssignmentEl ? parentAssignmentEl.value : "Top Level - Called from URL";
		var menuItemTargetVal = "";
		if (parentVal === "Assign to Main Menu Item") {
			var menuItemSelectEl = document.getElementById("pgMenuItemSelect");
			menuItemTargetVal = menuItemSelectEl ? menuItemSelectEl.value.trim() : "";
		} else {
			menuItemTargetVal = "Top Level - Called from URL";
		}

		var pageIdInput = document.getElementById("pgContentId");
		var pageIdVal = parseInt(pageIdInput ? pageIdInput.value : 0, 10) || 0;

		var jbdInstance = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#pgContent") : null;
		if (jbdInstance) {
			jbdInstance.syncToTarget();
		}
		var contentVal = jbdInstance ? jbdInstance.getHTML() : (document.getElementById("pgContent") ? document.getElementById("pgContent").value : "");

		// Feature 2.3: In-Editor Automated ADA WCAG Pre-Flight Linter Gating
		if (typeof window.PageA11yLinter !== "undefined" && !window.__cmsBypassA11yOnce) {
			var linterResults = window.PageA11yLinter.getResults();
			var visVal = document.getElementById("pgVisibility") ? document.getElementById("pgVisibility").value : "";
			var statusVal = document.getElementById("pgStatus") ? document.getElementById("pgStatus").value : "";
			var isPublishing = (visVal === "Published" && statusVal === "Active");

			if (linterResults && linterResults.criticalCount > 0 && isPublishing) {
				btnSavePage.disabled = false;
				btnSavePage.classList.remove("is-loading");
				btnSavePage.innerHTML = origBtnHtml;
				if (typeof window.finishTopProgress === "function") window.finishTopProgress();

				var confirmMsg = "This page contains " + linterResults.criticalCount + " critical ADA / WCAG 2.1 AA accessibility violation" +
					(linterResults.criticalCount === 1 ? "" : "s") + " (such as missing image alt text, broken heading hierarchy, or missing table headers). " +
					"Public release without remediation may violate ADA Title II & Washington State accessibility policies.\n\n" +
					"Would you like to review and fix the issues now?";

				if (typeof window.adminConfirm === "function") {
					window.adminConfirm(confirmMsg, {
						title: "ADA Pre-Flight Quality Gate",
						confirmText: "Review & Fix Issues",
						cancelText: "Publish Anyway",
						confirmClass: "btn-primary",
						cancelClass: "btn-outline",
						onConfirm: function() {
							window.PageA11yLinter.openDrawer();
							status.style.cssText = "background:var(--admin-warning-light, #fffbeb); color:var(--admin-warning, #92400e); border:1px solid var(--admin-warning, #fde68a); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
							status.textContent = "Publishing paused: please address the highlighted accessibility issues in the Pre-Flight drawer.";
						},
						onCancel: function() {
							window.__cmsBypassA11yOnce = true;
							document.getElementById("pageEditForm").dispatchEvent(new Event("submit", { cancelable: true }));
						}
					});
				} else {
					window.PageA11yLinter.openDrawer();
					status.style.cssText = "background:var(--admin-warning-light, #fffbeb); color:var(--admin-warning, #92400e); border:1px solid var(--admin-warning, #fde68a); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
					status.textContent = "Publishing paused: please address the highlighted accessibility issues in the Pre-Flight drawer.";
				}
				return;
			}
		} else if (typeof A11yValidator !== "undefined" && !window.__cmsBypassA11yOnce) {
			var a11yResult = (jbdInstance && typeof jbdInstance.validateA11y === "function")
				? jbdInstance.validateA11y()
				: A11yValidator.validate(contentVal);

			if (!a11yResult.passed || (a11yResult.warnings && a11yResult.warnings.length > 0)) {
				btnSavePage.disabled = false;
				btnSavePage.classList.remove("is-loading");
				btnSavePage.innerHTML = origBtnHtml;
				if (typeof window.finishTopProgress === "function") window.finishTopProgress();

				A11yValidator.showModal({
					results: a11yResult,
					onProceed: function() {
						window.__cmsBypassA11yOnce = true;
						document.getElementById("pageEditForm").dispatchEvent(new Event("submit", { cancelable: true }));
					},
					onCancel: function() {
						status.style.cssText = "background:var(--admin-warning-light, #fffbeb); color:var(--admin-warning, #92400e); border:1px solid var(--admin-warning, #fde68a); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
						status.textContent = "Save paused: please resolve accessibility issues before publishing.";
					}
				});
				return;
			}
		}
		window.__cmsBypassA11yOnce = false;

		var payload = {
			id: pageIdVal,
			title: title.value.trim(),
			slug: slug.value.trim(),
			content: contentVal,
			metaTitle: document.getElementById("pgMetaTitle") ? document.getElementById("pgMetaTitle").value.trim() : "",
			metaDescription: document.getElementById("pgMetaDesc") ? document.getElementById("pgMetaDesc").value.trim() : "",
			status: document.getElementById("pgStatus").value,
			visibility: document.getElementById("pgVisibility").value,
			publishAt: (publishAtEl && publishAtEl.value) ? publishAtEl.value : "",
			unpublishAt: (unpublishAtEl && unpublishAtEl.value) ? unpublishAtEl.value : "",
			layout: layout.value,
			parent: parentVal,
			menuItemTarget: menuItemTargetVal,
			menuItem: document.getElementById("pgMenuItem") ? document.getElementById("pgMenuItem").checked : false,
			folderListingEnabled: folderListingEnabled ? folderListingEnabled.checked : false,
			folderListingIds: folderCheckedIds,
			sidebarIds: sidebarChecked,
			changeSummary: document.getElementById("pgChangeSummary") ? document.getElementById("pgChangeSummary").value.trim() : "",
			imageAttachment: document.getElementById("featuredImage") ? document.getElementById("featuredImage").value.trim() : "",
			imageAlt: document.getElementById("featuredImageAlt") ? document.getElementById("featuredImageAlt").value.trim() : "",
			imageTitle: document.getElementById("featuredImageCaption") ? document.getElementById("featuredImageCaption").value.trim() : "",
			imageDescription: document.getElementById("featuredImageDescription") ? document.getElementById("featuredImageDescription").value.trim() : "",
			imageAttribution: document.getElementById("featuredImageCredit") ? document.getElementById("featuredImageCredit").value.trim() : "",
			imageDecorative: (document.getElementById("featuredImageDecorative") && document.getElementById("featuredImageDecorative").checked) ? 1 : 0
		};

		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var headers = {
			"Content-Type": "application/json",
			"Accept": "application/json",
			"X-Requested-With": "XMLHttpRequest"
		};
		if (csrfMeta && csrfMeta.getAttribute("content")) {
			headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
		}

		fetch("/pages/save", {
			method: "POST",
			credentials: "same-origin",
			headers: headers,
			body: JSON.stringify(payload)
		})
		.then(function(r) {
			return r.json().then(function(data) {
				if (!r.ok) {
					throw data;
				}
				return data;
			});
		})
		.then(function(data) {
			btnSavePage.disabled = false;
			btnSavePage.classList.remove("is-loading");
			btnSavePage.innerHTML = origBtnHtml;
			if (typeof window.finishTopProgress === "function") window.finishTopProgress();

			function getField(obj, key) {
				if (!obj || typeof obj !== "object") return undefined;
				if (obj[key] !== undefined) return obj[key];
				var upper = key.toUpperCase();
				if (obj[upper] !== undefined) return obj[upper];
				var lower = key.toLowerCase();
				if (obj[lower] !== undefined) return obj[lower];
				return undefined;
			}

			var isSuccess = (getField(data, "success") === true || String(getField(data, "success")).toLowerCase() === "true");
			if (isSuccess) {
				if (jbdInstance && typeof jbdInstance.clearDraft === "function") {
					jbdInstance.clearDraft();
				}
				status.className = "";
				status.style.cssText = "background:var(--admin-success-light); color:var(--admin-success); border:1px solid var(--admin-success); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
				status.textContent = getField(data, "message") || "Page attributes successfully saved to database.";
				if (typeof window.showToast === "function") window.showToast("Page saved to database.", "success");

				// Update Last updated and Updated by in sidebar
				var updatedVal = getField(data, "updated");
				var authorVal = getField(data, "author");
				var metaAuditDl = document.getElementById("pgMetaAuditDl");
				if (metaAuditDl) metaAuditDl.style.display = "";
				if (updatedVal) {
					var lastUpdatedDd = document.getElementById("pgLastUpdatedDd");
					if (lastUpdatedDd) lastUpdatedDd.textContent = updatedVal;
				}
				if (authorVal) {
					var authorDd = document.getElementById("pgAuthorDd");
					if (authorDd) authorDd.textContent = authorVal;
				}

				// Update Revision Counters
				var revCountVal = getField(data, "revisionCount");
				if (revCountVal !== undefined) {
					var hBadge = document.getElementById("pgHeaderRevCount");
					if (hBadge) hBadge.textContent = revCountVal;
					var sBadge = document.getElementById("pgSidebarRevCount");
					if (sBadge) sBadge.textContent = revCountVal;
				}
				var verNumVal = getField(data, "versionNumber");
				if (verNumVal !== undefined) {
					var vDd = document.getElementById("pgCurrentVerDd");
					if (vDd) vDd.textContent = verNumVal;
				}
				var csInput = document.getElementById("pgChangeSummary");
				if (csInput) csInput.value = "";

				// Update breadcrumb and page title display if title changed
				var newTitle = getField(data, "title") || title.value.trim();
				var breadcrumbTitle = document.getElementById("pgBreadcrumbTitle");
				if (breadcrumbTitle) breadcrumbTitle.textContent = newTitle;

				// Update view live link if slug changed
				var newSlug = getField(data, "slug") || slug.value.trim();
				if (slug && newSlug) slug.value = newSlug;
				var viewLiveBtn = document.getElementById("btnViewLivePage");
				if (viewLiveBtn && newSlug) {
					viewLiveBtn.href = "/" + newSlug;
				}
			} else {
				var msg = getField(data, "message") || "Error saving page attributes.";
				status.style.cssText = "background:var(--admin-danger-light); color:var(--admin-danger); border:1px solid var(--admin-danger); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
				status.textContent = msg;
				if (typeof window.adminAlert === "function") {
					window.adminAlert(msg, { title: "Save Failed", type: "danger" });
				}
			}
		})
		.catch(function(err) {
			btnSavePage.disabled = false;
			btnSavePage.classList.remove("is-loading");
			btnSavePage.innerHTML = origBtnHtml;
			if (typeof window.finishTopProgress === "function") window.finishTopProgress();

			function getField(obj, key) {
				if (!obj || typeof obj !== "object") return undefined;
				if (obj[key] !== undefined) return obj[key];
				var upper = key.toUpperCase();
				if (obj[upper] !== undefined) return obj[upper];
				var lower = key.toLowerCase();
				if (obj[lower] !== undefined) return obj[lower];
				return undefined;
			}
			var msg = (err && (getField(err, "message") || err.message)) ? (getField(err, "message") || err.message) : "Error saving page attributes.";
			status.style.cssText = "background:var(--admin-danger-light); color:var(--admin-danger); border:1px solid var(--admin-danger); padding:0.75rem 1rem; border-radius:8px; margin-bottom:1rem;";
			status.textContent = msg;
			if (typeof window.adminAlert === "function") {
				window.adminAlert(msg, { title: "Save Failed", type: "danger" });
			}
		});
	});

	// Rich formatting toolbar interactions for pgContent
	document.querySelectorAll('.pg-toolbar button[data-toolbar-tag]').forEach(function(btn) {
		btn.addEventListener('click', function(e) {
			e.preventDefault();
			var tag = btn.getAttribute('data-toolbar-tag');
			var ta = document.getElementById("pgContent");
			if (!ta) return;
			var start = ta.selectionStart;
			var end = ta.selectionEnd;
			var val = ta.value;
			var selected = val.substring(start, end) || (tag.toUpperCase() + ' Heading');
			var replacement = '<' + tag + '>' + selected + '</' + tag + '>';
			ta.value = val.substring(0, start) + replacement + val.substring(end);
			ta.selectionStart = start;
			ta.selectionEnd = start + replacement.length;
			ta.focus();
		});
	});

	document.querySelectorAll('.pg-toolbar button[data-toolbar-snippet]').forEach(function(btn) {
		btn.addEventListener('click', function(e) {
			e.preventDefault();
			var snippetType = btn.getAttribute('data-toolbar-snippet');
			var ta = document.getElementById("pgContent");
			if (!ta) return;
			var snippet = '';
			if (snippetType === 'ul') {
				snippet = '<ul>\n  <li>List item 1</li>\n  <li>List item 2</li>\n</ul>';
			} else if (snippetType === 'ol') {
				snippet = '<ol>\n  <li>First item</li>\n  <li>Second item</li>\n</ol>';
			} else if (snippetType === 'link') {
				var start = ta.selectionStart;
				var end = ta.selectionEnd;
				var selected = ta.value.substring(start, end) || 'Link Text';
				snippet = '<a href="https://">' + selected + '</a>';
			} else if (snippetType === 'form') {
				snippet = '<div class="cms-form-embed">\n  <!-- Insert Form Embed or Shortcode Here -->\n</div>';
			}
			if (snippet) {
				insertSnippetAtCursor("pgContent", snippet);
			}
		});
	});

	// Copy Page URL to Clipboard
	var btnCopyPageUrl = document.getElementById("btnCopyPageUrl");
	if (btnCopyPageUrl) {
		btnCopyPageUrl.addEventListener("click", async function (e) {
			e.preventDefault();
			var prefixEl = document.getElementById("pgUrlPrefixSpan");
			var prefix = prefixEl ? prefixEl.textContent.trim() : "/shared/pages/";
			var slugEl = document.getElementById("pgSlug");
			var slugVal = slugEl ? slugEl.value.trim() : "";
			var fullUrl = prefix + slugVal;

			var ok = false;
			if (typeof window.copyToClipboard === "function") {
				ok = await window.copyToClipboard(fullUrl);
			} else {
				try {
					await navigator.clipboard.writeText(fullUrl);
					ok = true;
				} catch (err) {}
			}

			var origHtml = btnCopyPageUrl.innerHTML;
			if (ok) {
				btnCopyPageUrl.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--admin-success)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
				btnCopyPageUrl.setAttribute("title", "Copied to clipboard!");
				if (typeof window.showToast === "function") {
					window.showToast("Page URL copied to clipboard: " + fullUrl, "success");
				}
			} else {
				if (typeof window.showToast === "function") {
					window.showToast("Copied: " + fullUrl, "info");
				}
			}
			setTimeout(function () {
				btnCopyPageUrl.innerHTML = origHtml;
				btnCopyPageUrl.setAttribute("title", "Copy full URL to clipboard");
			}, 1800);
		});
	}

	// Form Embed Integration
	var btnForm = document.getElementById("btnEditorInsertForm");
	if (btnForm) {
		btnForm.addEventListener("click", function() {
			openEmbedFormModal();
		});
	}

	// Call to Action Embed Integration
	var btnCTA = document.getElementById("btnEditorInsertCTA");
	if (btnCTA) {
		btnCTA.addEventListener("click", function() {
			openEmbedCtaModal();
		});
	}

	// Search & Sharing Auto-Generation from Page Content
	var metaTitleInput = document.getElementById("pgMetaTitle");
	var metaDescInput = document.getElementById("pgMetaDesc");
	var metaTitleCount = document.getElementById("pgMetaTitleCount");
	var metaDescCount = document.getElementById("pgMetaDescCount");
	var btnAutoGenerateMeta = document.getElementById("btnAutoGenerateMeta");

	function updateMetaCounters() {
		if (metaTitleInput && metaTitleCount) {
			var tLen = metaTitleInput.value.length;
			metaTitleCount.textContent = tLen + " / 65";
			metaTitleCount.style.color = (tLen > 65) ? "var(--admin-danger)" : "var(--admin-text-muted)";
		}
		if (metaDescInput && metaDescCount) {
			var dLen = metaDescInput.value.length;
			metaDescCount.textContent = dLen + " / 160";
			metaDescCount.style.color = (dLen > 160) ? "var(--admin-danger)" : "var(--admin-text-muted)";
		}
	}

	function generateSearchAndSharing(notifyUser) {
		var titleEl = document.getElementById("pgTitle");
		var pageTitle = titleEl ? titleEl.value.trim() : "";

		// Extract plain text from JBDEditor or raw textarea
		var plainContent = "";
		var ed = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#pgContent") : null;
		if (ed && typeof ed.getText === "function") {
			plainContent = ed.getText();
		} else {
			var rawVal = document.getElementById("pgContent") ? document.getElementById("pgContent").value : "";
			var tmp = document.createElement("div");
			tmp.innerHTML = rawVal;
			plainContent = tmp.textContent || tmp.innerText || "";
		}

		// Clean up content string (strip repetitive title heading, excess whitespace)
		plainContent = plainContent.replace(/\r\n|\r|\n/g, " ").replace(/\s+/g, " ").trim();
		if (pageTitle && plainContent.toLowerCase().indexOf(pageTitle.toLowerCase()) === 0) {
			plainContent = plainContent.substring(pageTitle.length).replace(/^[\s:\-–—]+/, "").trim();
		}

		// 1. Generate Browser / Search Title (max 65 chars)
		if (metaTitleInput && pageTitle) {
			var suffix = " | Chelan County";
			if (pageTitle.toLowerCase().indexOf("chelan county") !== -1) {
				metaTitleInput.value = pageTitle.substring(0, 65);
			} else if ((pageTitle + suffix).length <= 65) {
				metaTitleInput.value = pageTitle + suffix;
			} else {
				metaTitleInput.value = pageTitle.substring(0, 62).trim() + "...";
			}
		}

		// 2. Generate Meta Description (clean word boundary <= 160 chars)
		if (metaDescInput && plainContent) {
			var maxChars = 155;
			if (plainContent.length <= maxChars) {
				metaDescInput.value = plainContent;
			} else {
				var snippet = plainContent.substring(0, maxChars);
				var lastBoundary = snippet.lastIndexOf(" ");
				if (lastBoundary > 60) {
					snippet = snippet.substring(0, lastBoundary);
				}
				metaDescInput.value = snippet.replace(/[\s,;:\-–—.]+$/, "") + "...";
			}
		}

		updateMetaCounters();

		if (notifyUser && typeof window.showToast === "function") {
			window.showToast("Search & Sharing metadata generated from content.", "success");
		}
	}

	if (metaTitleInput) metaTitleInput.addEventListener("input", updateMetaCounters);
	if (metaDescInput) metaDescInput.addEventListener("input", updateMetaCounters);
	if (btnAutoGenerateMeta) {
		btnAutoGenerateMeta.addEventListener("click", function (e) {
			e.preventDefault();
			generateSearchAndSharing(true);
		});
	}

	// Initialize live counters on page load
	updateMetaCounters();
})();

function getActiveWorkspaceId() {
	var wsCont = document.getElementById("workspaceDropdownContainer");
	if (wsCont && wsCont.getAttribute("data-active-ws-id")) {
		return wsCont.getAttribute("data-active-ws-id").trim();
	}
	var m = document.cookie.match(/(?:^|;\s*)cmsadmin_workspace=([^;]+)/);
	return m ? decodeURIComponent(m[1]).trim() : "";
}

function escapeHtml(str) {
	if (str === null || str === undefined) return "";
	return String(str)
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;")
		.replace(/'/g, "&#039;");
}

function refreshEmbedForms(targetWs, targetWsName) {
	var currentActive = getActiveWorkspaceId();
	var ws = (targetWs !== undefined && targetWs !== null && targetWs !== "") 
		? targetWs 
		: (currentActive || "<cfoutput>#EncodeForJavaScript(editSiteId ?: (page.siteId ?: ''))#</cfoutput>");
	if (!ws || ws === "global" || ws === "all") ws = "";
	var container = document.getElementById("embedFormListContainer");
	var countEl = document.getElementById("embedFormAvailableCount");
	var nameEl = document.getElementById("embedFormWorkspaceName");

	if (nameEl && targetWsName) {
		nameEl.textContent = targetWsName;
	}

	fetch('/pages/workspaceForms?ws=' + encodeURIComponent(ws))
		.then(function(r) { return r.json(); })
		.then(function(data) {
			if (!data) return;
			var forms = Array.isArray(data.forms) ? data.forms : (Array.isArray(data.FORMS) ? data.FORMS : []);
			if (container) container.setAttribute("data-rendered-ws", ws);
			if (countEl) {
				countEl.textContent = forms.length + " form" + (forms.length !== 1 ? "s" : "") + " available";
			}
			if (nameEl && !targetWsName) {
				var dispName = (ws && ws.length) ? (ws.charAt(0).toUpperCase() + ws.slice(1)) : "General Administration";
				nameEl.textContent = dispName;
			}

			var html = "";
			forms.forEach(function(frm) {
				var id = (frm.id !== undefined && frm.id !== null) ? frm.id : ((frm.ID !== undefined && frm.ID !== null) ? frm.ID : "");
				var title = (frm.title || frm.TITLE || "Untitled Form").toString();
				var slug = (frm.slug || frm.SLUG || "").toString();
				var desc = (frm.description || frm.DESCRIPTION || "").toString();
				var statusStr = (frm.status || frm.STATUS || "published").toString().toUpperCase();
				var badgeCls = (frm.deptBadge || frm.DEPTBADGE || frm.dept_badge || frm.DEPT_BADGE || "badge-primary").toString();
				var deptName = (frm.deptName || frm.DEPTNAME || frm.dept_name || frm.DEPT_NAME || "General").toString();

				html += '<div class="embed-form-card" data-form-title="' + escapeHtml(title) + '" data-form-slug="' + escapeHtml(slug) + '" data-form-dept="' + escapeHtml(deptName) + '" style="border:1.5px solid var(--admin-border); border-radius:var(--radius-md); padding:0.85rem 1rem; background:var(--admin-surface); transition:all 0.15s ease; display:flex; justify-content:space-between; align-items:center; gap:1rem;">' +
					'<div style="flex:1; min-width:0;">' +
						'<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.25rem; flex-wrap:wrap;">' +
							'<strong style="font-size:0.92rem; color:var(--admin-text-main);">' + escapeHtml(title) + '</strong>' +
							'<span class="badge ' + escapeHtml(badgeCls) + '" style="font-size:0.68rem; padding:0.15rem 0.45rem;">' + escapeHtml(deptName) + '</span>' +
							'<span class="badge badge-neutral" style="font-size:0.68rem; padding:0.15rem 0.45rem;">' + escapeHtml(statusStr) + '</span>' +
						'</div>' +
						(desc ? '<div style="font-size:0.8rem; color:var(--admin-text-muted); line-height:1.4; margin-bottom:0.35rem; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden;">' + escapeHtml(desc) + '</div>' : '') +
						'<div style="font-size:0.75rem; color:var(--admin-text-muted); font-family:monospace;">Shortcode: [chelan_form slug="' + escapeHtml(slug) + '"]</div>' +
					'</div>' +
					'<div style="display:flex; flex-direction:column; gap:0.35rem; flex-shrink:0;">' +
						'<button type="button" class="btn btn-primary btn-xs btn-insert-embed-iframe" data-id="' + escapeHtml(id) + '" data-slug="' + escapeHtml(slug) + '" data-title="' + escapeHtml(title) + '" title="Embed responsive form directly on page">' +
							'<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>' +
							' <span>Embed Form</span>' +
						'</button>' +
						'<button type="button" class="btn btn-outline btn-xs btn-insert-embed-shortcode" data-slug="' + escapeHtml(slug) + '" title="Insert [chelan_form] shortcode">' +
							'<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>' +
							' <span>Insert Shortcode</span>' +
						'</button>' +
					'</div>' +
				'</div>';
			});

			html += '<div id="embedFormEmptyState" style="' + (forms.length > 0 ? 'display:none;' : '') + ' text-align:center; padding:2.5rem 1rem; color:var(--admin-text-muted);">' +
				'<div style="margin-bottom:0.5rem; color:var(--admin-text-muted);"><svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 3v18"/><path d="m14 9 3 3-3 3"/></svg></div>' +
				'<h4 style="margin:0 0 0.25rem 0; font-size:1rem; color:var(--admin-text-main);">No Online Forms in Workspace</h4>' +
				'<p style="margin:0 0 1rem 0; font-size:0.85rem;">There are no online forms attached to this workspace yet. You can create a new form in Form Builder.</p>' +
				'<div style="display:flex; justify-content:center; gap:0.5rem;"><a href="/forms/builder" target="_blank" rel="noopener" class="btn btn-primary btn-sm"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg> <span>Create New Form</span></a></div>' +
			'</div>';

			if (container) container.innerHTML = html;
		})
		.catch(function(err) {
			console.warn("Failed to fetch workspace forms:", err);
		});
}

window.openEmbedFormModal = function() {
	var modal = document.getElementById("embedFormModal");
	var backdrop = document.getElementById("embedFormModalBackdrop");
	if (backdrop && backdrop.parentElement !== document.body) document.body.appendChild(backdrop);
	if (modal && modal.parentElement !== document.body) document.body.appendChild(modal);

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
	document.body.style.overflow = 'hidden';

	// Check if active workspace has changed or if cards are empty
	var container = document.getElementById("embedFormListContainer");
	var activeWs = getActiveWorkspaceId();
	var renderedWs = container ? container.getAttribute("data-rendered-ws") : "";
	var existingCards = document.querySelectorAll(".embed-form-card");
	if (existingCards.length === 0 || (activeWs && activeWs !== renderedWs)) {
		refreshEmbedForms(activeWs);
	}

	var searchInput = document.getElementById("embedFormSearchInput");
	if (searchInput) {
		searchInput.value = "";
		var cards = document.querySelectorAll(".embed-form-card");
		cards.forEach(function(card) { card.style.display = "flex"; });
		var empty = document.getElementById("embedFormEmptyState");
		if (empty) empty.style.display = (cards.length === 0) ? "block" : "none";
		setTimeout(function() { searchInput.focus(); }, 50);
	}
};

window.closeEmbedFormModal = function() {
	var modal = document.getElementById("embedFormModal");
	var backdrop = document.getElementById("embedFormModalBackdrop");
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
	document.body.style.overflow = '';
};

// Search inside Embed Form Modal
(function initEmbedFormInteractions() {
	function runFilter() {
		var term = (document.getElementById("embedFormSearchInput") ? document.getElementById("embedFormSearchInput").value : "").toLowerCase().trim();
		var cards = document.querySelectorAll(".embed-form-card");
		var visibleCount = 0;
		cards.forEach(function(card) {
			var title = (card.getAttribute("data-form-title") || "").toLowerCase();
			var slug = (card.getAttribute("data-form-slug") || "").toLowerCase();
			var dept = (card.getAttribute("data-form-dept") || "").toLowerCase();
			var matchSearch = !term || title.includes(term) || slug.includes(term) || dept.includes(term);

			if (matchSearch) {
				card.style.display = "flex";
				visibleCount++;
			} else {
				card.style.display = "none";
			}
		});

		var empty = document.getElementById("embedFormEmptyState");
		if (empty) {
			empty.style.display = (visibleCount === 0) ? "block" : "none";
		}
	}

	document.addEventListener("input", function(e) {
		if (e.target && e.target.id === "embedFormSearchInput") {
			runFilter();
		} else if (e.target && e.target.id === "embedCtaSearchInput") {
			filterEmbedCtaCards();
		}
	});

	document.addEventListener("click", function(e) {
		var btnIframe = e.target.closest(".btn-insert-embed-iframe");
		if (btnIframe) {
			var formId = btnIframe.getAttribute("data-id");
			var formSlug = btnIframe.getAttribute("data-slug");
			var formTitle = btnIframe.getAttribute("data-title") || "Online Form";
			var formSrc = formSlug ? ('http://cmsadmin.chelancounty.gov/forms/preview?slug=' + encodeURIComponent(formSlug)) : ('http://cmsadmin.chelancounty.gov/forms/preview?id=' + formId);
			var snippet = '<div class="cms-form-embed" data-form-slug="' + formSlug + '" data-form-id="' + formId + '">\n' +
				'  <iframe src="' + formSrc + '" width="100%" height="750" frameborder="0" scrolling="no" style="border:none; width:100%; min-height:500px; overflow:hidden; border-radius:8px;" title="' + formTitle.replace(/"/g, '&quot;') + '"></iframe>\n' +
				'</div>\n';
			closeEmbedFormModal();
			insertSnippetAtCursor("pgContent", snippet);
			if (typeof window.showToast === "function") window.showToast('Embedded form "' + formTitle + '" into document.', 'success');
			return;
		}

		var btnShortcode = e.target.closest(".btn-insert-embed-shortcode");
		if (btnShortcode) {
			var formSlug = btnShortcode.getAttribute("data-slug");
			var snippet = '[chelan_form slug="' + formSlug + '"]';
			closeEmbedFormModal();
			insertSnippetAtCursor("pgContent", snippet);
			if (typeof window.showToast === "function") window.showToast('Inserted shortcode [' + formSlug + '].', 'success');
			return;
		}
	});

	document.addEventListener("keydown", function(e) {
		if (e.key === "Escape") {
			var modal = document.getElementById("embedFormModal");
			if (modal && modal.style.display !== "none") {
				closeEmbedFormModal();
			}
		}
	});

	// Call to Action Embed Integration for JBDEditor
	function syncCtaCardSelectionState() {
		document.querySelectorAll(".embed-cta-card-item").forEach(function(card) {
			var cb = card.querySelector(".embed-cta-checkbox");
			if (cb && cb.checked) {
				card.style.borderColor = "var(--admin-primary)";
				card.style.boxShadow = "0 0 0 2px rgba(37, 99, 235, 0.15)";
			} else {
				card.style.borderColor = "var(--admin-border)";
				card.style.boxShadow = "none";
			}
		});
	}

	window.openEmbedCtaModal = function() {
		var modal = document.getElementById("embedCtaModal");
		var backdrop = document.getElementById("embedCtaModalBackdrop");
		if (backdrop && backdrop.parentElement !== document.body) document.body.appendChild(backdrop);
		if (modal && modal.parentElement !== document.body) document.body.appendChild(modal);

		if (modal) {
			modal.style.display = "flex";
			modal.classList.add("open");
		}
		if (backdrop) {
			backdrop.style.display = "block";
			backdrop.style.opacity = "1";
			backdrop.style.visibility = "visible";
			backdrop.classList.add("open");
		}
		document.body.style.overflow = "hidden";

		var searchInput = document.getElementById("embedCtaSearchInput");
		if (searchInput) {
			searchInput.value = "";
			filterEmbedCtaCards();
			setTimeout(function() { searchInput.focus(); }, 50);
		}
		syncCtaCardSelectionState();
	};

	window.closeEmbedCtaModal = function() {
		var modal = document.getElementById("embedCtaModal");
		var backdrop = document.getElementById("embedCtaModalBackdrop");
		if (modal) {
			modal.style.display = "none";
			modal.classList.remove("open");
		}
		if (backdrop) {
			backdrop.style.opacity = "0";
			backdrop.style.visibility = "hidden";
			backdrop.style.display = "none";
			backdrop.classList.remove("open");
		}
		document.body.style.overflow = "";
	};

	function filterEmbedCtaCards() {
		var term = (document.getElementById("embedCtaSearchInput") ? document.getElementById("embedCtaSearchInput").value : "").toLowerCase().trim();
		var cards = document.querySelectorAll(".embed-cta-card-item");
		var visibleCount = 0;
		cards.forEach(function(card) {
			var title = (card.getAttribute("data-title") || "").toLowerCase();
			var slug = (card.getAttribute("data-slug") || "").toLowerCase();
			var cat = (card.getAttribute("data-category") || "").toLowerCase();
			var matches = !term || title.includes(term) || slug.includes(term) || cat.includes(term);

			if (matches) {
				card.style.display = "flex";
				visibleCount++;
			} else {
				card.style.display = "none";
			}
		});

		var countEl = document.getElementById("embedCtaAvailableCount");
		if (countEl) countEl.textContent = visibleCount + " card" + (visibleCount !== 1 ? "s" : "") + " available";
	}

	function getCtaLinkIconSvg(linkIcon) {
		var icon = (linkIcon || "arrow").toLowerCase();
		if (icon === "external") {
			return ' <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6"></path><path d="M10 14 21 3"></path><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path></svg>';
		} else if (icon === "pdf") {
			return ' <span class="jbd-cta-pdf-badge" aria-hidden="true">PDF</span>';
		} else if (icon === "none") {
			return '';
		}
		return ' <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>';
	}

	function generateCtaCardHtml(cardEl) {
		var title = cardEl.getAttribute("data-title") || "";
		var slug = cardEl.getAttribute("data-slug") || "";
		var linkUrl = cardEl.getAttribute("data-link-url") || ("#" + slug);
		var linkIcon = (cardEl.getAttribute("data-link-icon") || "arrow").toLowerCase();
		var targetBlank = cardEl.getAttribute("data-target-blank") === "1";
		var imgEl = cardEl.querySelector("img");
		var imgUrl = imgEl ? imgEl.getAttribute("src") : "";
		var imgAlt = imgEl ? (imgEl.getAttribute("alt") || title) : title;
		var badgeEl = cardEl.querySelector(".jbd-cta-badge");
		var badgeText = badgeEl ? badgeEl.textContent.trim() : "";
		var descEl = cardEl.querySelector("p");
		var desc = descEl ? descEl.textContent.trim() : "";
		var linkEl = cardEl.querySelector(".embed-cta-link-preview span") || cardEl.querySelector("div[style*='font-weight:700'] span");
		var linkText = linkEl ? linkEl.textContent.trim() : "Learn More";
		var targetAttr = targetBlank ? ' target="_blank" rel="noopener noreferrer"' : '';
		var extClass = (targetBlank || linkIcon === "external") ? ' has-external-icon' : '';
		var iconSuffix = getCtaLinkIconSvg(linkIcon);

		var html = '  <aside class="jbd-template jbd-cta-card' + (imgUrl ? ' has-image' : '') + '" aria-label="Action: ' + escapeHtml(title) + '">\n';
		if (imgUrl) {
			html += '    <div class="jbd-cta-card-img-wrap"><img src="' + escapeHtml(imgUrl) + '" alt="' + escapeHtml(imgAlt) + '" loading="lazy"></div>\n';
			html += '    <div class="jbd-cta-card-content">\n';
		}
		if (badgeText) {
			html += '      <div class="jbd-cta-card-header"><span class="jbd-cta-badge">' + escapeHtml(badgeText) + '</span></div>\n';
		}
		html += '      <p class="jbd-cta-title h4">' + escapeHtml(title) + '</p>\n';
		if (desc) {
			html += '      <p class="jbd-cta-desc">' + escapeHtml(desc) + '</p>\n';
		}
		html += '      <div class="jbd-cta-card-footer">\n';
		html += '        <a href="' + escapeHtml(linkUrl) + '" class="jbd-cta-link' + extClass + '"' + targetAttr + '><span>' + escapeHtml(linkText) + '</span>' + iconSuffix + '</a>\n';
		html += '      </div>\n';
		if (imgUrl) {
			html += '    </div>\n';
		}
		html += '  </aside>\n';
		return html;
	}

	document.addEventListener("change", function(e) {
		if (e.target && e.target.classList && e.target.classList.contains("embed-cta-checkbox")) {
			syncCtaCardSelectionState();
		}
	});

	// Delegated click handler for all CTA Modal interactions
	document.addEventListener("click", function(e) {
		var btnSelAll = e.target.closest("#btnSelectAllCtaModal");
		if (btnSelAll) {
			e.preventDefault();
			document.querySelectorAll(".embed-cta-card-item").forEach(function(card) {
				if (card.style.display !== "none") {
					var cb = card.querySelector(".embed-cta-checkbox");
					if (cb) cb.checked = true;
				}
			});
			syncCtaCardSelectionState();
			return;
		}

		var btnClrAll = e.target.closest("#btnClearAllCtaModal");
		if (btnClrAll) {
			e.preventDefault();
			document.querySelectorAll(".embed-cta-checkbox").forEach(function(cb) { cb.checked = false; });
			syncCtaCardSelectionState();
			return;
		}

		var btnEmbedGrid = e.target.closest("#btnEmbedSelectedCtaGrid");
		if (btnEmbedGrid) {
			e.preventDefault();
			var checked = document.querySelectorAll(".embed-cta-checkbox:checked");
			if (checked.length === 0) {
				if (typeof window.adminAlert === "function") {
					window.adminAlert({ title: "No Cards Selected", message: "Please check at least one card to assemble a grid.", type: "warning" });
				}
				return;
			}

			var layoutSel = document.getElementById("embedCtaLayoutSelect");
			var layoutVal = layoutSel ? layoutSel.value : "3";
			var gridClass = "cta-grid-3";
			if (layoutVal === "4") {
				gridClass = "cta-grid-4";
			} else if (layoutVal === "2") {
				gridClass = "cta-grid-2 cta-grid-50-50";
			}

			var gridHtml = '<section class="jbd-template jbd-cta-grid ' + gridClass + '" aria-label="Featured Actions">\n';
			checked.forEach(function(cb) {
				var cardEl = cb.closest(".embed-cta-card-item");
				if (cardEl) {
					gridHtml += generateCtaCardHtml(cardEl);
				}
			});
			gridHtml += '</section>\n';

			closeEmbedCtaModal();
			insertSnippetAtCursor("pgContent", gridHtml);
			if (typeof window.showToast === "function") window.showToast('Embedded ' + checked.length + '-card grid (' + layoutVal + '-column) into document.', 'success');
			return;
		}

		var btnInsertGridSc = e.target.closest("#btnInsertSelectedCtaShortcodes");
		if (btnInsertGridSc) {
			e.preventDefault();
			var checked = document.querySelectorAll(".embed-cta-checkbox:checked");
			if (checked.length === 0) {
				if (typeof window.adminAlert === "function") {
					window.adminAlert({ title: "No Cards Selected", message: "Please check at least one card to generate a grid shortcode.", type: "warning" });
				}
				return;
			}
			var layoutSel = document.getElementById("embedCtaLayoutSelect");
			var layoutVal = layoutSel ? layoutSel.value : "3";
			var slugs = [];
			checked.forEach(function(cb) { slugs.push(cb.value); });
			var snippet = '[cta_grid slugs="' + slugs.join(',') + '" cols="' + layoutVal + '"]';
			closeEmbedCtaModal();
			insertSnippetAtCursor("pgContent", snippet);
			if (typeof window.showToast === "function") window.showToast('Inserted grid shortcode (' + slugs.length + ' cards, ' + layoutVal + ' cols).', 'success');
			return;
		}

		// Clicking anywhere on a CTA card in the modal toggles its selection checkbox
		var clickedCard = e.target.closest(".embed-cta-card-item");
		if (clickedCard && !e.target.closest("input[type='checkbox']") && !e.target.closest("button") && !e.target.closest("a")) {
			var cb = clickedCard.querySelector(".embed-cta-checkbox");
			if (cb) {
				cb.checked = !cb.checked;
				syncCtaCardSelectionState();
			}
			return;
		}
	});

	document.addEventListener("keydown", function(e) {
		if (e.key === "Escape") {
			var modal = document.getElementById("embedCtaModal");
			if (modal && modal.style.display !== "none") {
				closeEmbedCtaModal();
			}
		}
	});

	window.addEventListener("cmsadmin:workspaceChanged", function(e) {
		if (e && e.detail) {
			var wsId = e.detail.id || "";
			var wsName = e.detail.name || "";
			refreshEmbedForms(wsId, wsName);
		}
	});
})();

window.openMediaPicker = function(mode, options) {
	options = options || {};
	var modal = document.getElementById("mediaPickerModal");
	var backdrop = document.getElementById("mediaPickerModalBackdrop");
	var iframe = document.getElementById("mediaPickerIframe");
	var title = document.getElementById("mediaPickerTitleText");

	if (backdrop && backdrop.parentElement !== document.body) document.body.appendChild(backdrop);
	if (modal && modal.parentElement !== document.body) document.body.appendChild(modal);

	if (title) {
		title.textContent = (mode === 'document') ? 'Select Document from Media Library' : 'Select Image from Media Library';
	}
	var activeWs = getActiveWorkspaceId() || "<cfoutput>#EncodeForJavaScript(editSiteId ?: (page.siteId ?: ''))#</cfoutput>";
	var pickerType = (mode === 'document') ? 'document' : 'image';
	var folder = options.folder || (mode === 'document' ? 'documents' : 'all');

	if (typeof options.onSelect === 'function') {
		window._mediaPickerCustomCallback = options.onSelect;
	} else {
		window._mediaPickerCustomCallback = null;
	}

	// Elevate z-index if opened over an active editor modal dialog
	var hasDialogOverlay = !!document.querySelector('.jbd-dialog-overlay');
	if (modal) {
		modal.style.zIndex = hasDialogOverlay ? '100005' : '99999';
	}
	if (backdrop) {
		backdrop.style.zIndex = hasDialogOverlay ? '100004' : '99998';
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
	document.body.style.overflow = 'hidden';
};

window.closeMediaPickerModal = function() {
	var modal = document.getElementById("mediaPickerModal");
	var backdrop = document.getElementById("mediaPickerModalBackdrop");
	if (modal) {
		modal.style.display = 'none';
		modal.classList.remove('open');
		modal.style.zIndex = '99999';
	}
	if (backdrop) {
		backdrop.style.display = 'none';
		backdrop.style.opacity = '0';
		backdrop.style.visibility = 'hidden';
		backdrop.classList.remove('open');
		backdrop.style.zIndex = '99998';
	}
	window._mediaPickerCustomCallback = null;
	document.body.style.overflow = '';
};

window.triggerMediaPickerUpload = function() {
	try {
		var iframe = document.getElementById('mediaPickerIframe');
		if (iframe && iframe.contentDocument) {
			var b = iframe.contentDocument.getElementById('btn-upload');
			if (b) { b.click(); return; }
		}
	} catch (e) {}
	window.open('/media/upload', '_blank');
};

window.onMediaSelectedFromPicker = function(payload) {
	var customCb = window._mediaPickerCustomCallback;
	closeMediaPickerModal();
	if (typeof customCb === 'function') {
		customCb(payload);
		return;
	}
	if (payload && payload.html) {
		insertSnippetAtCursor("pgContent", payload.html);
	}
};

window.addEventListener('message', function(e) {
	if (e.data && e.data.type === 'CMS_MEDIA_SELECTED') {
		var customCb = window._mediaPickerCustomCallback;
		closeMediaPickerModal();
		if (typeof customCb === 'function') {
			customCb(e.data);
			return;
		}
		if (e.data.html) {
			insertSnippetAtCursor("pgContent", e.data.html);
		}
	}
});

function insertSnippetAtCursor(textareaId, text) {
	var editor = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#" + textareaId) : null;
	if (editor) {
		if (editor.isSourceMode && editor.sourceArea) {
			var sa = editor.sourceArea;
			var sStart = sa.selectionStart || sa.value.length;
			var sEnd = sa.selectionEnd || sa.value.length;
			var sVal = sa.value || "";
			sa.value = sVal.substring(0, sStart) + "\n" + text + "\n" + sVal.substring(sEnd);
			if (editor.contentArea) editor.contentArea.innerHTML = sa.value;
			if (typeof editor._handleInput === "function") editor._handleInput();
			else if (typeof editor.syncToTarget === "function") editor.syncToTarget();
			sa.focus();
			return;
		}
		var trimmed = (text || "").trim();
		var isBlockHtml = /^<(section|aside|div|article|table|figure|blockquote)\b/i.test(trimmed);
		if (isBlockHtml && typeof editor.insertTemplate === "function") {
			editor.insertTemplate(trimmed);
			return;
		}
		if (typeof editor.insertHTML === "function") {
			if (!editor.savedSelectionRange && editor.contentArea) {
				var p = document.createElement("p");
				p.innerHTML = trimmed;
				editor.contentArea.appendChild(p);
				if (typeof editor._handleInput === "function") editor._handleInput();
				else if (typeof editor.syncToTarget === "function") editor.syncToTarget();
				editor.contentArea.focus();
				return;
			}
			editor.insertHTML(text);
			return;
		}
	}
	var ta = document.getElementById(textareaId);
	if (!ta) return;
	var start = ta.selectionStart || 0;
	var end = ta.selectionEnd || 0;
	var val = ta.value || "";
	ta.value = val.substring(0, start) + "\n" + text + "\n" + val.substring(end);
	ta.selectionStart = ta.selectionEnd = start + text.length + 2;
	ta.focus();
}

/* ==========================================================================
   Featured Cover Image & Media Library Picker Integration
   ========================================================================== */
function updateImagePreview(url) {
	var img = document.getElementById('featuredImgPreview');
	var ph = document.getElementById('featuredImgPlaceholder');
	var btnRemove = document.getElementById('btnRemoveFeaturedImg');
	var trimmed = (url || '').trim();
	if (trimmed.length > 0) {
		if (img) {
			img.src = trimmed;
			img.style.display = 'block';
		}
		if (ph) ph.style.display = 'none';
		if (btnRemove) btnRemove.style.display = 'inline-flex';
	} else {
		if (img) {
			img.src = '';
			img.style.display = 'none';
		}
		if (ph) ph.style.display = 'flex';
		if (btnRemove) btnRemove.style.display = 'none';
	}
	updateAdaComplianceStatus();
	if (window.PageA11yLinter && typeof window.PageA11yLinter.scheduleScan === 'function') {
		window.PageA11yLinter.scheduleScan();
	}
}

function removeFeaturedImage() {
	var imgInput = document.getElementById('featuredImage');
	if (imgInput) imgInput.value = '';
	var altInput = document.getElementById('featuredImageAlt');
	if (altInput) altInput.value = '';
	var captionEl = document.getElementById('featuredImageCaption');
	if (captionEl) captionEl.value = '';
	var descEl = document.getElementById('featuredImageDescription');
	if (descEl) descEl.value = '';
	var creditEl = document.getElementById('featuredImageCredit');
	if (creditEl) creditEl.value = '';
	var decEl = document.getElementById('featuredImageDecorative');
	if (decEl) decEl.checked = false;

	updateImagePreview('');
	updateAltCharCount('');
	updateCaptionCharCount('');
	updateDescCharCount('');
	onDecorativeToggled(false);
	updateAdaComplianceStatus();

	if (window.PageA11yLinter && typeof window.PageA11yLinter.scheduleScan === 'function') {
		window.PageA11yLinter.scheduleScan();
	}

	if (typeof window.showToast === 'function') {
		window.showToast('Featured cover image removed.', 'info');
	}
	var browseBtn = document.getElementById('btnBrowseFeaturedImg');
	if (browseBtn) browseBtn.focus();
}

function getActiveWorkspaceName(wsId) {
	wsId = (wsId || getActiveWorkspaceId() || "").toLowerCase();
	var wsCont = document.getElementById("workspaceDropdownContainer");
	if (wsCont) {
		var titleEl = wsCont.querySelector(".header-ws-title") || wsCont.querySelector(".workspace-name") || wsCont.querySelector(".active-ws-name");
		if (titleEl && titleEl.textContent.trim()) {
			return titleEl.textContent.trim();
		}
	}
	var badgeEl = document.getElementById("featuredImgWsName");
	if (badgeEl && badgeEl.textContent.trim() && badgeEl.textContent.trim() !== "Workspace") {
		return badgeEl.textContent.trim();
	}
	return wsId || "Workspace";
}

window.openMediaPickerForPageCover = function() {
	var triggerBtn = document.getElementById('btnBrowseFeaturedImg') || document.getElementById('featuredImgPreviewWrap');
	window._mediaPickerTrigger = triggerBtn;

	window.openMediaPicker('image', {
		folder: 'images',
		onSelect: function(payload) {
			if (!payload) return;
			var url = payload.url || (payload.data && payload.data.webUrl) || '';
			if (!url) return;

			var imgInput = document.getElementById('featuredImage');
			if (imgInput) {
				imgInput.value = url;
			}

			var altInput = document.getElementById('featuredImageAlt');
			var suggestedAlt = payload.alt || payload.title || (payload.data && (payload.data.altText || payload.data.title)) || '';
			if (altInput && (!altInput.value.trim().length) && suggestedAlt) {
				altInput.value = suggestedAlt;
				updateAltCharCount(suggestedAlt);
			}

			var captionInput = document.getElementById('featuredImageCaption');
			var suggestedCaption = payload.caption || (payload.data && payload.data.caption) || '';
			if (captionInput && (!captionInput.value.trim().length) && suggestedCaption) {
				captionInput.value = suggestedCaption;
				updateCaptionCharCount(suggestedCaption);
			}

			var creditInput = document.getElementById('featuredImageCredit');
			var suggestedCredit = payload.credit || (payload.data && payload.data.credit) || '';
			if (creditInput && (!creditInput.value.trim().length) && suggestedCredit) {
				creditInput.value = suggestedCredit;
			}

			updateImagePreview(url);
			updateAdaComplianceStatus();
			if (window.PageA11yLinter && typeof window.PageA11yLinter.scheduleScan === 'function') {
				window.PageA11yLinter.scheduleScan();
			}
			var wsName = getActiveWorkspaceName();
			if (typeof window.showToast === 'function') {
				window.showToast('Cover image selected' + (wsName ? ' from ' + wsName + ' workspace.' : '.'), 'success');
			}
		}
	});
};

function onDecorativeToggled(isDecorative) {
	var altContainer = document.getElementById('altTextContainer');
	var imgPreview = document.getElementById('featuredImgPreview');
	if (altContainer) {
		if (isDecorative) {
			altContainer.style.opacity = '0.45';
			altContainer.style.pointerEvents = 'none';
		} else {
			altContainer.style.opacity = '1';
			altContainer.style.pointerEvents = 'auto';
		}
	}
	if (imgPreview) {
		if (isDecorative) {
			imgPreview.setAttribute('aria-hidden', 'true');
			imgPreview.setAttribute('alt', '');
		} else {
			imgPreview.removeAttribute('aria-hidden');
			var altInput = document.getElementById('featuredImageAlt');
			imgPreview.setAttribute('alt', altInput ? altInput.value : '');
		}
	}
	updateAdaComplianceStatus();
	if (window.PageA11yLinter && typeof window.PageA11yLinter.scheduleScan === 'function') {
		window.PageA11yLinter.scheduleScan();
	}
}

function suggestAltFromHeadline() {
	var titleEl = document.getElementById('pgTitle');
	var headline = (titleEl ? titleEl.value : '').trim();
	if (!headline) {
		if (typeof window.adminAlert === 'function') {
			window.adminAlert({ title: 'Page Title Required', message: 'Please enter a page title above first so we can suggest matching image alt text.', type: 'info' });
		} else if (typeof window.showToast === 'function') {
			window.showToast('Please enter a page title first.', 'warning');
		}
		if (titleEl) titleEl.focus();
		return;
	}

	var altInput = document.getElementById('featuredImageAlt');
	if (altInput) {
		var suggestion = headline;
		if (suggestion.length > 120) {
			suggestion = suggestion.substring(0, 117).trim() + '...';
		}
		altInput.value = suggestion;
		updateAltCharCount(suggestion);
		updateAdaComplianceStatus();
		altInput.focus();
		if (window.PageA11yLinter && typeof window.PageA11yLinter.scheduleScan === 'function') {
			window.PageA11yLinter.scheduleScan();
		}
		if (typeof window.showToast === 'function') {
			window.showToast('Alt text populated from page title. Edit as needed for visual accuracy.', 'success');
		}
	}
}

function updateAltCharCount(val) {
	var counter = document.getElementById('altCharCounter');
	if (counter) {
		var len = (val || '').length;
		counter.textContent = len + '/150 rec.';
		if (len > 150) {
			counter.style.color = 'var(--admin-warning, #d97706)';
		} else {
			counter.style.color = 'var(--admin-text-muted)';
		}
	}
}

function onAltInput(val) {
	updateAltCharCount(val);
	updateAdaComplianceStatus();
	if (window.PageA11yLinter && typeof window.PageA11yLinter.scheduleScan === 'function') {
		window.PageA11yLinter.scheduleScan();
	}
}

function updateDescCharCount(val) {
	var counter = document.getElementById('descCharCounter');
	if (counter) {
		counter.textContent = (val || '').length + '/2000';
	}
}

function updateCaptionCharCount(val) {
	var counter = document.getElementById('captionCharCounter');
	if (counter) {
		counter.textContent = (val || '').length + '/1000';
	}
}

function updateAdaComplianceStatus() {
	var imgInput = document.getElementById('featuredImage');
	var decInput = document.getElementById('featuredImageDecorative');
	var altInput = document.getElementById('featuredImageAlt');
	var badge = document.getElementById('featuredImgAdaBadge');
	var badgeText = document.getElementById('featuredImgAdaText');
	var notice = document.getElementById('altAuditNotice');

	if (!badge || !badgeText) return;

	var imgUrl = (imgInput ? imgInput.value : '').trim();
	var isDec = decInput ? decInput.checked : false;
	var altText = (altInput ? altInput.value : '').trim();

	// Reset badge classes
	badge.className = 'badge';

	if (!imgUrl) {
		badge.classList.add('badge-neutral');
		badgeText.textContent = 'No Image';
		badge.title = 'No cover image selected';
		if (notice) notice.style.display = 'none';
		return;
	}

	if (isDec) {
		badge.classList.add('badge-info');
		badgeText.textContent = 'Decorative (H67 Pass)';
		badge.title = 'Marked decorative (WCAG Technique H67). Screen readers will ignore this image.';
		if (notice) {
			notice.style.display = 'block';
			notice.style.background = 'var(--admin-bg-subtle, #f1f5f9)';
			notice.style.color = 'var(--admin-text-muted)';
			notice.style.border = '1px solid var(--admin-border-subtle)';
			notice.innerHTML = '<strong>Decorative Image:</strong> Assistive technologies will skip this image (<code>alt=""</code>, <code>aria-hidden="true"</code>).';
		}
		return;
	}

	if (!altText) {
		badge.classList.add('badge-danger');
		badgeText.textContent = 'Alt Text Required';
		badge.title = 'ADA Title II / WCAG 1.1.1 Issue: Non-decorative images must have descriptive alternative text.';
		if (notice) {
			notice.style.display = 'block';
			notice.style.background = '#fef2f2';
			notice.style.color = '#991b1b';
			notice.style.border = '1px solid #fecaca';
			notice.innerHTML = '<strong>⚠️ ADA Title II / WCAG 1.1.1 Requirement:</strong> Alternative text is required for non-decorative images so screen reader users receive equal access.';
		}
		return;
	}

	// Audit quality of alt text
	var fileExtRegex = /\.(jpe?g|png|gif|webp|svg|bmp|tiff)$/i;
	var genericWordRegex = /^(image|photo|picture|photograph|graphic|pic|img)$/i;
	var startsWithGeneric = /^(photo|image|picture) of /i;

	if (fileExtRegex.test(altText) || genericWordRegex.test(altText) || startsWithGeneric.test(altText)) {
		badge.classList.add('badge-warning');
		badgeText.textContent = 'Generic Alt Warning';
		badge.title = 'Alt text contains file names or generic phrases like "image of".';
		if (notice) {
			notice.style.display = 'block';
			notice.style.background = '#fffbeb';
			notice.style.color = '#92400e';
			notice.style.border = '1px solid #fde68a';
			notice.innerHTML = '<strong>⚠️ Quality Suggestion:</strong> Avoid raw file names (<code>.jpg</code>) or starting with <em>"photo of"</em> or <em>"image of"</em>. Describe what is actually happening in the photo.';
		}
		return;
	}

	// Alt text provided and valid
	badge.classList.add('badge-success');
	badgeText.textContent = 'ADA Pass (WCAG AA)';
	badge.title = 'Meets WCAG 2.1 Level AA and ADA Title II non-text content criteria.';
	if (notice) notice.style.display = 'none';
}

window.addEventListener('cmsadmin:workspaceChanged', function(e) {
	if (e && e.detail && e.detail.id) {
		var newName = (e.detail.name || e.detail.title || getActiveWorkspaceName(e.detail.id));
		var badgeNameEl = document.getElementById('featuredImgWsName');
		if (badgeNameEl && newName) {
			badgeNameEl.textContent = newName;
		}
	}
});

document.addEventListener('DOMContentLoaded', function() {
	var altInput = document.getElementById('featuredImageAlt');
	if (altInput) updateAltCharCount(altInput.value);
	var capInput = document.getElementById('featuredImageCaption');
	if (capInput) updateCaptionCharCount(capInput.value);
	var descInput = document.getElementById('featuredImageDescription');
	if (descInput) updateDescCharCount(descInput.value);
	updateAdaComplianceStatus();
});

/* ==========================================================================
   Feature 2.2: Page Revision History & Rollback Studio (RCW 42.56 Compliance)
   ========================================================================== */
window.__pageRevisions = [];
window.__selectedRevisionDetail = null;
window.__currentDiffMode = 'visual';

function getEditorHtmlContent() {
	var editor = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#pgContent") : null;
	if (editor && typeof editor.getHTML === "function") {
		return editor.getHTML();
	}
	var ta = document.getElementById("pgContent");
	return ta ? ta.value : "";
}

function openRevisionsModal() {
	var modal = document.getElementById("pgRevisionsModal");
	var backdrop = document.getElementById("pgRevisionsModalBackdrop");
	if (!modal || !backdrop) return;

	backdrop.style.display = "block";
	modal.style.display = "flex";
	document.body.style.overflow = "hidden";

	loadRevisionsTimeline();
}

function closeRevisionsModal() {
	var modal = document.getElementById("pgRevisionsModal");
	var backdrop = document.getElementById("pgRevisionsModalBackdrop");
	if (modal) modal.style.display = "none";
	if (backdrop) backdrop.style.display = "none";
	document.body.style.overflow = "";

	var openBtn = document.getElementById("btnOpenRevisions");
	if (openBtn) openBtn.focus();
}

document.addEventListener("keydown", function(e) {
	if (e.key === "Escape") {
		var modal = document.getElementById("pgRevisionsModal");
		if (modal && modal.style.display === "flex") {
			closeRevisionsModal();
		}
	}
});

var btnOpenRevisions = document.getElementById("btnOpenRevisions");
if (btnOpenRevisions) {
	btnOpenRevisions.addEventListener("click", openRevisionsModal);
}
var lnkSidebarRevisions = document.getElementById("lnkSidebarRevisions");
if (lnkSidebarRevisions) {
	lnkSidebarRevisions.addEventListener("click", function(e) {
		e.preventDefault();
		openRevisionsModal();
	});
}

function loadRevisionsTimeline(forceSelectId) {
	var pageIdEl = document.getElementById("pgContentId");
	var pageId = parseInt(pageIdEl ? pageIdEl.value : 0, 10) || 0;
	var listContainer = document.getElementById("revisionsTimelineList");
	var countEl = document.getElementById("revTimelineCount");
	var headerCountEl = document.getElementById("pgHeaderRevCount");
	var sidebarCountEl = document.getElementById("pgSidebarRevCount");

	if (pageId <= 0) {
		if (listContainer) {
			listContainer.innerHTML = '<div style="text-align:center; padding:2rem 1rem; color:var(--admin-text-muted); font-size:0.85rem;">This is a new unsaved page. Save the page to database first to begin tracking historical revisions.</div>';
		}
		return;
	}

	if (listContainer) {
		listContainer.innerHTML = '<div style="text-align:center; padding:2rem 1rem; color:var(--admin-text-muted); font-size:0.85rem;"><span class="admin-spinner-sm" style="margin-right:6px;" aria-hidden="true"></span> Loading revisions...</div>';
	}

	fetch("/pages/revisions?pageId=" + encodeURIComponent(pageId), {
		headers: { "Accept": "application/json" }
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		if (!data || !data.success) {
			if (listContainer) {
				listContainer.innerHTML = '<div style="text-align:center; padding:2rem 1rem; color:var(--admin-danger); font-size:0.85rem;">Failed to load revisions: ' + (data.message || 'Unknown error') + '</div>';
			}
			return;
		}

		var revs = data.revisions || data.REVISIONS || [];
		window.__pageRevisions = revs;
		var total = revs.length;

		if (countEl) countEl.textContent = total;
		if (headerCountEl) headerCountEl.textContent = total;
		if (sidebarCountEl) sidebarCountEl.textContent = total;

		if (total === 0) {
			if (listContainer) {
				listContainer.innerHTML = '<div style="text-align:center; padding:2rem 1rem; color:var(--admin-text-muted); font-size:0.85rem;">No historical revisions found yet. Click <strong>Snapshot Now</strong> above to create your baseline checkpoint.</div>';
			}
			return;
		}

		// Render timeline items
		var html = "";
		for (var i = 0; i < revs.length; i++) {
			var r = revs[i];
			var isLatest = (i === 0);
			var isPreRollback = (r.changeSummary && r.changeSummary.indexOf("Pre-rollback") !== -1);
			var isRestored = (r.changeSummary && r.changeSummary.indexOf("Restored from") !== -1);
			var badgeTag = "";
			if (isLatest) {
				badgeTag = '<span class="badge badge-primary" style="font-size:0.68rem; padding:0.12rem 0.4rem;">Latest</span>';
			} else if (isPreRollback) {
				badgeTag = '<span class="badge badge-warning" style="font-size:0.68rem; padding:0.12rem 0.4rem;">Safety Backup</span>';
			} else if (isRestored) {
				badgeTag = '<span class="badge badge-success" style="font-size:0.68rem; padding:0.12rem 0.4rem;">Restored</span>';
			}

			var sizeKb = (r.contentBytes > 0) ? (Math.round(r.contentBytes / 1024 * 10) / 10) + " KB" : (r.contentLength + " chars");

			html += '<button type="button" class="rev-item-card" data-rev-id="' + r.id + '" onclick="selectRevision(' + r.id + ')" aria-selected="false">';
			html += '  <div class="rev-item-version">';
			html += '    <span>Version ' + r.versionNumber + '</span>';
			html += '    ' + badgeTag;
			html += '  </div>';
			html += '  <div class="rev-item-meta">';
			html += '    <span>' + escapeHtml(r.createdAtFormatted || r.createdAt || "") + '</span>';
			html += '    <span>&bull;</span>';
			html += '    <span>' + escapeHtml(r.createdBy || "Admin") + '</span>';
			html += '  </div>';
			if (r.changeSummary) {
				html += '  <div class="rev-item-note">&ldquo;' + escapeHtml(r.changeSummary) + '&rdquo;</div>';
			}
			html += '  <div style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.35rem; display:flex; justify-content:space-between;">';
			html += '    <span>Layout: ' + escapeHtml(r.layoutType || 'Full') + '</span>';
			html += '    <span>' + sizeKb + '</span>';
			html += '  </div>';
			html += '</button>';
		}

		if (listContainer) {
			listContainer.innerHTML = html;
		}

		// Auto select requested or first revision
		var targetId = forceSelectId;
		if (!targetId && revs.length > 0) {
			targetId = revs[0].id;
		}
		if (targetId) {
			selectRevision(targetId);
		}
	})
	.catch(function(err) {
		console.error("loadRevisionsTimeline error:", err);
		if (listContainer) {
			listContainer.innerHTML = '<div style="text-align:center; padding:2rem 1rem; color:var(--admin-danger); font-size:0.85rem;">Error contacting revisions service.</div>';
		}
	});
}

function selectRevision(revId) {
	// Mark active item in sidebar
	var cards = document.querySelectorAll(".rev-item-card");
	cards.forEach(function(c) {
		if (parseInt(c.getAttribute("data-rev-id"), 10) === parseInt(revId, 10)) {
			c.classList.add("is-active");
			c.setAttribute("aria-selected", "true");
		} else {
			c.classList.remove("is-active");
			c.setAttribute("aria-selected", "false");
		}
	});

	var stageContainer = document.getElementById("revDiffViewer");
	var selectedTitleEl = document.getElementById("revSelectedTitle");
	var restoreBtn = document.getElementById("btnRestoreRevision");

	if (stageContainer) {
		stageContainer.innerHTML = '<div style="text-align:center; padding:3rem 1rem; color:var(--admin-text-muted);"><span class="admin-spinner-sm" style="margin-right:6px;" aria-hidden="true"></span> Fetching snapshot content...</div>';
	}

	var pageIdEl = document.getElementById("pgContentId");
	var pageId = parseInt(pageIdEl ? pageIdEl.value : 0, 10) || 0;

	fetch("/pages/revision?revId=" + encodeURIComponent(revId) + "&pageId=" + encodeURIComponent(pageId), {
		headers: { "Accept": "application/json" }
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		if (!data || !data.success || !data.revision) {
			if (stageContainer) {
				stageContainer.innerHTML = '<div style="text-align:center; padding:2rem 1rem; color:var(--admin-danger);">Failed to load revision details.</div>';
			}
			return;
		}

		var rev = data.revision;
		window.__selectedRevisionDetail = rev;

		if (selectedTitleEl) {
			selectedTitleEl.textContent = "Version " + rev.versionNumber + " (" + (rev.createdAtFormatted || "Snapshot") + ") vs Working Draft";
		}

		if (restoreBtn) {
			restoreBtn.disabled = false;
			restoreBtn.setAttribute("data-version", rev.versionNumber);
			restoreBtn.setAttribute("data-rev-id", rev.id);
		}

		renderRevisionDiff();
	})
	.catch(function(err) {
		console.error("selectRevision error:", err);
		if (stageContainer) {
			stageContainer.innerHTML = '<div style="text-align:center; padding:2rem 1rem; color:var(--admin-danger);">Error fetching revision content.</div>';
		}
	});
}

function setDiffViewMode(mode) {
	window.__currentDiffMode = mode;
	var modeButtons = [
		{ id: "revModeVisual", mode: "visual" },
		{ id: "revModeSplit", mode: "split" },
		{ id: "revModePreview", mode: "preview" },
		{ id: "revModeRaw", mode: "raw" }
	];
	modeButtons.forEach(function(item) {
		var btn = document.getElementById(item.id);
		if (btn) {
			if (item.mode === mode) {
				btn.classList.add("is-active");
				btn.setAttribute("aria-selected", "true");
			} else {
				btn.classList.remove("is-active");
				btn.setAttribute("aria-selected", "false");
			}
		}
	});

	if (window.__selectedRevisionDetail) {
		renderRevisionDiff();
	}
}

// Tokenizes text or HTML into word/punctuation tokens
function tokenizeText(str) {
	if (!str) return [];
	return str.match(/<[^>]+>|[\w'-]+|[^\w\s<]+|\s+/g) || [];
}

// Longest Common Subsequence Diff Generator
function computeTokenDiff(oldTokens, newTokens) {
	var n = oldTokens.length;
	var m = newTokens.length;

	if (n * m > 400000) {
		return computeLineDiff(oldTokens.join(""), newTokens.join(""));
	}

	var dp = Array(n + 1);
	for (var i = 0; i <= n; i++) {
		dp[i] = new Uint16Array(m + 1);
	}

	for (var i = 1; i <= n; i++) {
		for (var j = 1; j <= m; j++) {
			if (oldTokens[i - 1] === newTokens[j - 1]) {
				dp[i][j] = dp[i - 1][j - 1] + 1;
			} else {
				dp[i][j] = Math.max(dp[i - 1][j], dp[i][j - 1]);
			}
		}
	}

	var diff = [];
	var i = n, j = m;
	while (i > 0 || j > 0) {
		if (i > 0 && j > 0 && oldTokens[i - 1] === newTokens[j - 1]) {
			diff.unshift({ type: "eq", val: oldTokens[i - 1] });
			i--;
			j--;
		} else if (j > 0 && (i === 0 || dp[i][j - 1] >= dp[i - 1][j])) {
			diff.unshift({ type: "add", val: newTokens[j - 1] });
			j--;
		} else if (i > 0 && (j === 0 || dp[i][j - 1] < dp[i - 1][j])) {
			diff.unshift({ type: "del", val: oldTokens[i - 1] });
			i--;
		}
	}

	return diff;
}

function computeLineDiff(oldStr, newStr) {
	var oldLines = oldStr.split("\n");
	var newLines = newStr.split("\n");
	var diff = [];
	var maxLen = Math.max(oldLines.length, newLines.length);
	for (var i = 0; i < maxLen; i++) {
		var o = oldLines[i];
		var n = newLines[i];
		if (o === n) {
			if (o !== undefined) diff.push({ type: "eq", val: o + "\n" });
		} else {
			if (o !== undefined) diff.push({ type: "del", val: o + "\n" });
			if (n !== undefined) diff.push({ type: "add", val: n + "\n" });
		}
	}
	return diff;
}

function renderRevisionDiff() {
	var rev = window.__selectedRevisionDetail;
	var container = document.getElementById("revDiffViewer");
	var statsEl = document.getElementById("revDiffStats");
	if (!rev || !container) return;

	var histHtml = rev.contentHtml || "";
	var currHtml = getEditorHtmlContent();

	var oldTokens = tokenizeText(histHtml);
	var newTokens = tokenizeText(currHtml);
	var diffResult = computeTokenDiff(oldTokens, newTokens);

	var adds = 0;
	var dels = 0;
	for (var k = 0; k < diffResult.length; k++) {
		if (diffResult[k].type === "add") adds++;
		if (diffResult[k].type === "del") dels++;
	}

	if (statsEl) {
		if (adds === 0 && dels === 0) {
			statsEl.innerHTML = '<span class="badge badge-neutral" style="font-size:0.75rem;">Exact Match (No Changes)</span>';
		} else {
			statsEl.innerHTML = '<span class="diff-stat-pill add">+' + adds + ' additions</span>' +
			                    '<span class="diff-stat-pill del">-' + dels + ' deletions</span>';
		}
	}

	var mode = window.__currentDiffMode;

	if (mode === "visual") {
		var output = "";
		for (var d = 0; d < diffResult.length; d++) {
			var token = diffResult[d];
			if (token.type === "eq") {
				output += token.val;
			} else if (token.type === "add") {
				output += '<ins class="diff-add">' + escapeHtml(token.val) + '</ins>';
			} else if (token.type === "del") {
				output += '<del class="diff-del">' + escapeHtml(token.val) + '</del>';
			}
		}
		container.innerHTML = '<div style="margin-bottom:0.75rem; padding:0.5rem 0.75rem; background:var(--admin-bg); border-radius:var(--radius-sm); font-size:0.8rem; color:var(--admin-text-muted); display:flex; gap:1rem; align-items:center;">' +
		                      '  <span><ins class="diff-add" style="margin-right:4px;">Green Text</ins> = Added in Current Working Draft</span>' +
		                      '  <span><del class="diff-del" style="margin-right:4px;">Strikethrough Red</del> = Removed from Version ' + rev.versionNumber + '</span>' +
		                      '</div>' +
		                      '<div class="diff-visual-flow" style="line-height:1.7;">' + output + '</div>';
	} else if (mode === "split") {
		var splitHtml = '<div class="diff-split-grid">';
		splitHtml += '  <div class="diff-split-col">';
		splitHtml += '    <div class="diff-split-col-header">';
		splitHtml += '      <span>Version ' + rev.versionNumber + ' (Snapshot ' + (rev.createdAtFormatted || "") + ')</span>';
		splitHtml += '      <span class="badge badge-neutral" style="font-size:0.68rem;">Historical</span>';
		splitHtml += '    </div>';
		splitHtml += '    <div class="diff-split-col-body">' + (histHtml || '<em style="color:var(--admin-text-muted);">(Empty Content)</em>') + '</div>';
		splitHtml += '  </div>';

		splitHtml += '  <div class="diff-split-col">';
		splitHtml += '    <div class="diff-split-col-header">';
		splitHtml += '      <span>Current Working Draft (Editor State)</span>';
		splitHtml += '      <span class="badge badge-primary" style="font-size:0.68rem;">Active</span>';
		splitHtml += '    </div>';
		splitHtml += '    <div class="diff-split-col-body">' + (currHtml || '<em style="color:var(--admin-text-muted);">(Empty Content)</em>') + '</div>';
		splitHtml += '  </div>';
		splitHtml += '</div>';

		container.innerHTML = splitHtml;
	} else if (mode === "preview") {
		var previewHtml = '<div style="margin-bottom:0.75rem; display:flex; justify-content:space-between; align-items:center;">' +
		                  '  <span style="font-size:0.82rem; color:var(--admin-text-muted);">Isolated layout rendering of Version ' + rev.versionNumber + '</span>' +
		                  '  <span class="badge badge-secondary" style="font-size:0.75rem;">Layout: ' + escapeHtml(rev.layoutType || 'Full') + '</span>' +
		                  '</div>' +
		                  '<div style="border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:1.5rem; background:#ffffff; min-height:360px;">' +
		                  '  <h1 style="font-size:1.6rem; margin-top:0; margin-bottom:0.75rem; color:#0f172a;">' + escapeHtml(rev.title || "") + '</h1>' +
		                  (rev.summary ? '<p style="font-size:1rem; color:#64748b; font-style:italic; margin-bottom:1.25rem;">' + escapeHtml(rev.summary) + '</p>' : '') +
		                  '  <hr style="border:none; border-top:1px solid #e2e8f0; margin-bottom:1.5rem;">' +
		                  '  <div class="preview-content-rendered">' + (histHtml || '<p><em>(Empty content body)</em></p>') + '</div>' +
		                  '</div>';
		container.innerHTML = previewHtml;
	} else if (mode === "raw") {
		var rawDiff = "";
		for (var r = 0; r < diffResult.length; r++) {
			var tok = diffResult[r];
			if (tok.type === "eq") {
				rawDiff += escapeHtml(tok.val);
			} else if (tok.type === "add") {
				rawDiff += '<span class="diff-add">' + escapeHtml(tok.val) + '</span>';
			} else if (tok.type === "del") {
				rawDiff += '<span class="diff-del">' + escapeHtml(tok.val) + '</span>';
			}
		}
		container.innerHTML = '<div class="diff-code-view" style="padding:1rem; background:var(--admin-bg); border-radius:var(--radius-md); max-height:560px; overflow:auto;">' + rawDiff + '</div>';
	}
}

function escapeHtml(str) {
	if (!str) return "";
	return String(str)
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;")
		.replace(/'/g, "&#039;");
}

function confirmRollbackRevision() {
	var rev = window.__selectedRevisionDetail;
	if (!rev) return;

	var pageIdEl = document.getElementById("pgContentId");
	var pageId = parseInt(pageIdEl ? pageIdEl.value : 0, 10) || 0;
	if (pageId <= 0) return;

	var confirmMsg = "Are you sure you want to restore Version " + rev.versionNumber + " (" + (rev.createdAtFormatted || "Snapshot") + ")?\n\n" +
	                 "In compliance with RCW 42.56 Public Records Act, an automatic safety backup of your CURRENT page state will be recorded before this rollback is applied.";

	if (typeof window.adminConfirm === "function") {
		window.adminConfirm({
			title: "Roll Back to Version " + rev.versionNumber + "?",
			message: confirmMsg,
			confirmText: "Roll Back & Restore",
			confirmClass: "btn-warning",
			cancelText: "Cancel",
			onConfirm: function() {
				executeRollback(pageId, rev.id, rev.versionNumber);
			}
		});
	} else {
		executeRollback(pageId, rev.id, rev.versionNumber);
	}
}

function executeRollback(pageId, revisionId, versionNumber) {
	var restoreBtn = document.getElementById("btnRestoreRevision");
	if (restoreBtn) {
		restoreBtn.disabled = true;
		restoreBtn.innerHTML = '<span class="admin-spinner-sm" style="margin-right:6px;" aria-hidden="true"></span> Restoring...';
	}

	fetch("/pages/restore-revision", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			"Accept": "application/json"
		},
		body: JSON.stringify({
			pageId: pageId,
			revisionId: revisionId
		})
	})
	.then(function(res) { return res.json(); })
	.then(function(data) {
		if (restoreBtn) {
			restoreBtn.disabled = false;
			restoreBtn.innerHTML = '<span style="display:inline-flex; align-items:center; gap:0.35rem;"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/></svg> <span>Restore this Version</span></span>';
		}

		if (!data || !data.success) {
			window.adminAlert({ title: "Rollback Failed", message: (data.message || "Unknown error"), type: "danger" });
			return;
		}

		// Update working editor fields with restored state
		var pageObj = data.page || data.PAGE || {};
		if (pageObj.title) {
			var t = document.getElementById("pgTitle");
			if (t) t.value = pageObj.title;
			var bc = document.getElementById("pgBreadcrumbTitle");
			if (bc) bc.textContent = pageObj.title;
		}
		if (pageObj.slug) {
			var s = document.getElementById("pgSlug");
			if (s) s.value = pageObj.slug;
		}
		if (pageObj.summary !== undefined) {
			var sm = document.getElementById("pgSummary");
			if (sm) sm.value = pageObj.summary;
		}
		if (pageObj.body !== undefined) {
			var editor = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#pgContent") : null;
			if (editor && typeof editor.setHTML === "function") {
				editor.setHTML(pageObj.body);
				if (typeof editor.syncToTarget === "function") editor.syncToTarget();
			} else {
				var ta = document.getElementById("pgContent");
				if (ta) ta.value = pageObj.body;
			}
		}
		if (pageObj.layout !== undefined) {
			var lay = document.getElementById("pgLayout");
			if (lay) {
				lay.value = pageObj.layout;
				updateSidebarAvailability();
			}
		}
		if (pageObj.imageAttachment !== undefined) {
			var fi = document.getElementById("featuredImage");
			if (fi) fi.value = pageObj.imageAttachment || "";
			updateImagePreview(pageObj.imageAttachment || "");
		}
		if (pageObj.imageAlt !== undefined) {
			var fa = document.getElementById("featuredImageAlt");
			if (fa) { fa.value = pageObj.imageAlt || ""; updateAltCharCount(fa.value); }
		}
		if (pageObj.imageTitle !== undefined) {
			var fc = document.getElementById("featuredImageCaption");
			if (fc) { fc.value = pageObj.imageTitle || ""; updateCaptionCharCount(fc.value); }
		}
		if (pageObj.imageDescription !== undefined) {
			var fd = document.getElementById("featuredImageDescription");
			if (fd) { fd.value = pageObj.imageDescription || ""; updateDescCharCount(fd.value); }
		}
		if (pageObj.imageAttribution !== undefined) {
			var fcr = document.getElementById("featuredImageCredit");
			if (fcr) fcr.value = pageObj.imageAttribution || "";
		}
		if (pageObj.imageDecorative !== undefined) {
			var fdec = document.getElementById("featuredImageDecorative");
			if (fdec) {
				fdec.checked = (pageObj.imageDecorative == 1 || pageObj.imageDecorative === true || pageObj.imageDecorative === "1");
				onDecorativeToggled(fdec.checked);
			}
		}
		updateAdaComplianceStatus();

		if (typeof window.adminToast === "function") {
			window.adminToast("Successfully restored Version " + versionNumber + ". Safety backup recorded.", "success");
		}

		// Reload revisions timeline to show new rollback version at top
		loadRevisionsTimeline();
		closeRevisionsModal();
	})
	.catch(function(err) {
		console.error("executeRollback error:", err);
		if (restoreBtn) {
			restoreBtn.disabled = false;
			restoreBtn.innerHTML = '<span style="display:inline-flex; align-items:center; gap:0.35rem;"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/></svg> <span>Restore this Version</span></span>';
		}
		if (typeof window.adminToast === "function") {
			window.adminToast("Communication error while rolling back version.", "danger");
		}
	});
}

function createManualSnapshot() {
	var pageIdEl = document.getElementById("pgContentId");
	var pageId = parseInt(pageIdEl ? pageIdEl.value : 0, 10) || 0;
	if (pageId <= 0) {
		window.adminAlert({ title: "Save Required", message: "Please save the page before creating revision snapshots.", type: "warning" });
		return;
	}

	function doSaveSnapshot(noteText) {
		var btn = document.getElementById("btnManualSnapshot");
		if (btn) btn.disabled = true;

		fetch("/pages/snapshot-revision", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				"Accept": "application/json"
			},
			body: JSON.stringify({
				pageId: pageId,
				changeSummary: (noteText || "").trim() || "Manual checkpoint snapshot"
			})
		})
		.then(function(res) { return res.json(); })
		.then(function(data) {
			if (btn) btn.disabled = false;
			if (data && data.success) {
				if (typeof window.adminToast === "function") {
					window.adminToast(data.message || "Snapshot recorded.", "success");
				}
				loadRevisionsTimeline(data.revisionId);
			} else {
				if (typeof window.adminToast === "function") {
					window.adminToast("Failed to create snapshot: " + (data.message || "Unknown error"), "danger");
				}
			}
		})
		.catch(function(err) {
			console.error("createManualSnapshot error:", err);
			if (btn) btn.disabled = false;
			if (typeof window.adminToast === "function") {
				window.adminToast("Network error creating snapshot.", "danger");
			}
		});
	}

	var existing = document.getElementById("pgSnapshotPromptBackdrop");
	if (existing) existing.remove();

	var backdrop = document.createElement("div");
	backdrop.id = "pgSnapshotPromptBackdrop";
	backdrop.style.cssText = "position:fixed; inset:0; z-index:100005; background:rgba(15,23,42,0.6); backdrop-filter:blur(3px); display:flex; align-items:center; justify-content:center; padding:1rem;";

	var modal = document.createElement("div");
	modal.setAttribute("role", "dialog");
	modal.setAttribute("aria-modal", "true");
	modal.style.cssText = "background:var(--admin-surface, #fff); border:1px solid var(--admin-border, #cbd5e1); border-radius:0.75rem; width:100%; max-width:440px; box-shadow:0 20px 50px rgba(15,23,42,0.25); overflow:hidden;";

	modal.innerHTML =
		'<div style="padding:0.85rem 1.1rem; border-bottom:1px solid var(--admin-border-subtle, #e2e8f0); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg, #f8fafc);">' +
			'<strong style="font-size:0.92rem; color:var(--admin-text-main);">Create Checkpoint Snapshot</strong>' +
			'<button type="button" id="pgSnapshotModalCloseBtn" class="btn btn-ghost btn-xs" style="padding:0.15rem 0.4rem;">&times;</button>' +
		'</div>' +
		'<div style="padding:1rem 1.1rem;">' +
			'<label for="pgSnapshotModalInput" style="display:block; font-size:0.8rem; font-weight:600; color:var(--admin-text-main); margin-bottom:0.4rem;">Snapshot description or note:</label>' +
			'<input type="text" id="pgSnapshotModalInput" class="form-control" style="width:100%;" value="Manual checkpoint snapshot">' +
		'</div>' +
		'<div style="padding:0.75rem 1.1rem; border-top:1px solid var(--admin-border-subtle, #e2e8f0); display:flex; justify-content:flex-end; gap:0.5rem; background:var(--admin-bg, #f8fafc);">' +
			'<button type="button" id="pgSnapshotModalCancelBtn" class="btn btn-outline btn-sm">Cancel</button>' +
			'<button type="button" id="pgSnapshotModalApplyBtn" class="btn btn-primary btn-sm">Create Snapshot</button>' +
		'</div>';

	backdrop.appendChild(modal);
	document.body.appendChild(backdrop);

	var input = document.getElementById("pgSnapshotModalInput");
	var closeBtn = document.getElementById("pgSnapshotModalCloseBtn");
	var cancelBtn = document.getElementById("pgSnapshotModalCancelBtn");
	var applyBtn = document.getElementById("pgSnapshotModalApplyBtn");

	function close() {
		if (backdrop && backdrop.parentNode) backdrop.parentNode.removeChild(backdrop);
	}
	function submit() {
		var val = input ? input.value : "";
		close();
		doSaveSnapshot(val);
	}

	if (closeBtn) closeBtn.onclick = close;
	if (cancelBtn) cancelBtn.onclick = close;
	if (applyBtn) applyBtn.onclick = submit;
	backdrop.onclick = function(e) { if (e.target === backdrop) close(); };
	if (input) {
		input.focus();
		input.select();
		input.onkeydown = function(e) {
			if (e.key === "Enter") { e.preventDefault(); submit(); }
			if (e.key === "Escape") { e.preventDefault(); close(); }
		};
	}
}

/* ==========================================================================
   Feature 2.3: In-Editor Automated ADA WCAG Pre-Flight Linter Engine & Controller
   ========================================================================== */
window.PageA11yLinter = (function() {
	var _activeFilter = 'all';
	var _lastResults = {
		passed: true,
		criticalCount: 0,
		warningCount: 0,
		categories: { cover: 0, images: 0, headings: 0, links: 0, tables: 0, format: 0 },
		issues: []
	};
	var _scanDebounceTimer = null;

	function escapeHtml(str) {
		if (str === null || str === undefined) return '';
		return String(str)
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;')
			.replace(/'/g, '&#39;');
	}

	var _editorBound = false;
	function bindEditorEvents() {
		var ed = getEditor();
		if (!ed) return false;
		if (_editorBound) return true;

		if (ed.contentArea) {
			ed.contentArea.addEventListener("input", scheduleScan);
			ed.contentArea.addEventListener("keyup", scheduleScan);
			ed.contentArea.addEventListener("paste", function() { setTimeout(scan, 80); });
		}
		if (typeof ed.on === "function") {
			ed.on("change", scheduleScan);
			ed.on("input", scheduleScan);
			ed.on("paste", function() { setTimeout(scan, 80); });
		}
		_editorBound = true;
		return true;
	}

	function getEditor() {
		return (typeof JBDEditor !== "undefined") ? JBDEditor.get("#pgContent") : null;
	}

	function getHtmlContent() {
		if (!_editorBound) bindEditorEvents();
		var ed = getEditor();
		if (ed && typeof ed.getHTML === "function") {
			return ed.getHTML();
		}
		var ta = document.getElementById("pgContent");
		return ta ? ta.value : "";
	}

	function scan() {
		var html = getHtmlContent();
		var temp = document.createElement("div");
		temp.innerHTML = html;

		var issues = [];
		var catCounts = { cover: 0, images: 0, headings: 0, links: 0, tables: 0, format: 0 };
		var criticalCount = 0;
		var warningCount = 0;

		// --- Rule Group 1: Featured Cover Image (WCAG 1.1.1 Non-text Content) ---
		var featImgInput = document.getElementById("featuredImage");
		var featImgUrl = featImgInput ? featImgInput.value.trim() : "";
		var featImgDec = document.getElementById("featuredImageDecorative");
		var isDecorativeCover = featImgDec ? featImgDec.checked : false;
		var featAltInput = document.getElementById("featuredImageAlt");
		var featAlt = featAltInput ? featAltInput.value.trim() : "";

		if (featImgUrl) {
			if (!isDecorativeCover && !featAlt) {
				criticalCount++;
				catCounts.cover++;
				issues.push({
					id: "cover-missing-alt",
					category: "cover",
					severity: "error",
					rule: "WCAG 1.1.1 (Non-text Content)",
					title: "Cover Image Missing Alt Text",
					message: "The featured cover image has no alternative text. Screen reader users cannot discern what is portrayed.",
					snippet: '<img src="' + escapeHtml(featImgUrl.length > 50 ? featImgUrl.substring(0, 47) + '...' : featImgUrl) + '">',
					suggestion: "Provide descriptive alt text or mark the cover photo as decorative if purely illustrative.",
					selector: "#featuredImageAlt",
					index: 0,
					quickFixType: "focus-input",
					meta: { inputId: "featuredImageAlt" }
				});
			} else if (!isDecorativeCover && featAlt) {
				var genericNamesCover = ["image", "photo", "picture", "graphic", "screenshot", "img", "icon", "placeholder", "file", "download"];
				var lowerCover = featAlt.toLowerCase().replace(/[^a-z0-9]/g, "");
				var fileExtRegexCover = /\.(jpe?g|png|gif|webp|svg|bmp|tiff)$/i;

				if (genericNamesCover.indexOf(lowerCover) !== -1 || fileExtRegexCover.test(featAlt) || /^(photo|image|picture) of /i.test(featAlt)) {
					warningCount++;
					catCounts.cover++;
					issues.push({
						id: "cover-generic-alt",
						category: "cover",
						severity: "warning",
						rule: "WCAG 1.1.1 (Descriptive Alt Text)",
						title: "Generic Cover Image Alt Text",
						message: 'Alternative text "' + escapeHtml(featAlt) + '" appears to be a generic placeholder or filename.',
						snippet: '<img alt="' + escapeHtml(featAlt) + '">',
						suggestion: "Describe what is specifically portrayed in the photograph or use 'Suggest from Title'.",
						selector: "#featuredImageAlt",
						index: 0,
						quickFixType: "focus-input",
						meta: { inputId: "featuredImageAlt" }
					});
				} else if (featAlt.length > 150) {
					warningCount++;
					catCounts.cover++;
					issues.push({
						id: "cover-long-alt",
						category: "cover",
						severity: "warning",
						rule: "WCAG 1.1.1 (Concise Alt Text)",
						title: "Excessively Long Alt Text (" + featAlt.length + " chars)",
						message: "Alt text exceeds recommended 150 characters. Screen readers read alt text without pausing.",
						snippet: '<img alt="' + escapeHtml(featAlt.substring(0, 60)) + '...">',
						suggestion: "Shorten alt text to under 150 characters and place extended narrative in the visible Caption or Description field.",
						selector: "#featuredImageAlt",
						index: 0,
						quickFixType: "focus-input",
						meta: { inputId: "featuredImageAlt" }
					});
				}
			}
		}

		// --- Rule Group 2: Content Body Images (WCAG 1.1.1 Non-text Content) ---
		var imgs = temp.querySelectorAll("img");
		var genericNames = ["image", "photo", "picture", "graphic", "screenshot", "img", "icon", "placeholder", "file", "download"];
		imgs.forEach(function(img, idx) {
			var hasAlt = img.hasAttribute("alt");
			var alt = (img.getAttribute("alt") || "").trim();
			var isDecorative = (img.getAttribute("role") === "presentation" || img.getAttribute("aria-hidden") === "true");
			var src = img.getAttribute("src") || "";
			var srcPreview = src.length > 50 ? src.substring(0, 47) + "..." : (src || "Image #" + (idx + 1));

			if (!hasAlt) {
				criticalCount++;
				catCounts.images++;
				issues.push({
					id: "img-missing-alt-" + idx,
					category: "images",
					severity: "error",
					rule: "WCAG 1.1.1 (Non-text Content)",
					title: "Missing Alternative Text Attribute",
					message: "Image lacks an alt attribute entirely. Screen readers cannot describe this image.",
					snippet: '<img src="' + escapeHtml(srcPreview) + '">',
					suggestion: 'Provide descriptive alternative text or mark it as decorative (alt="" and role="presentation").',
					selector: "img",
					index: idx,
					quickFixType: "set-alt",
					meta: { src: src }
				});
			} else if (alt === "" && !isDecorative) {
				// Linked or informative images with empty alt without role="presentation"
				var parentLink = img.closest("a");
				if (parentLink) {
					criticalCount++;
					catCounts.images++;
					issues.push({
						id: "img-linked-empty-alt-" + idx,
						category: "images",
						severity: "error",
						rule: "WCAG 1.1.1 / 2.4.4 (Linked Image Missing Description)",
						title: "Linked Image with Empty Alt",
						message: "This image is inside a hyperlink with an empty alt attribute, resulting in an unlabelled link for assistive tech.",
						snippet: '<a href="' + escapeHtml(parentLink.getAttribute("href") || "") + '"><img src="' + escapeHtml(srcPreview) + '" alt=""></a>',
						suggestion: 'Provide descriptive alt text clarifying the link destination or add an aria-label to the parent link.',
						selector: "img",
						index: idx,
						quickFixType: "set-alt",
						meta: { src: src }
					});
				}
			} else if (alt.length > 0) {
				var lower = alt.toLowerCase().replace(/[^a-z0-9]/g, "");
				if (genericNames.indexOf(lower) !== -1 || /^(dsc|img|p[0-9]|screenshot)[\-_0-9]*/i.test(alt) || /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(alt)) {
					warningCount++;
					catCounts.images++;
					issues.push({
						id: "img-generic-alt-" + idx,
						category: "images",
						severity: "warning",
						rule: "WCAG 1.1.1 (Non-text Content)",
						title: "Generic or Filename Alt Text",
						message: 'Alternative text "' + escapeHtml(alt) + '" appears to be a generic placeholder or filename.',
						snippet: '<img alt="' + escapeHtml(alt) + '" src="' + escapeHtml(srcPreview) + '">',
						suggestion: 'Replace with descriptive text explaining what the visual portrays.',
						selector: "img",
						index: idx,
						quickFixType: "set-alt",
						meta: { currentAlt: alt, src: src }
					});
				} else if (alt.length > 150) {
					warningCount++;
					catCounts.images++;
					issues.push({
						id: "img-long-alt-" + idx,
						category: "images",
						severity: "warning",
						rule: "WCAG 1.1.1 (Concise Alt Text)",
						title: "Excessively Long Alt Text (" + alt.length + " chars)",
						message: 'Alt text exceeds recommended 150 characters. Screen readers read alt text without pausing.',
						snippet: '<img alt="' + escapeHtml(alt.substring(0, 70)) + '...">',
						suggestion: 'Summarize the core visual concept in under 150 characters and use a body caption for extended details.',
						selector: "img",
						index: idx,
						quickFixType: "set-alt",
						meta: { currentAlt: alt, src: src }
					});
				}
			}
		});

		// --- Rule Group 2: Headings (WCAG 1.3.1 Info and Relationships) ---
		var headings = temp.querySelectorAll("h1, h2, h3, h4, h5, h6");
		var lastLevel = 1; // Outer page title serves as singular H1
		var isFirstHeading = true;

		headings.forEach(function(h, idx) {
			var tag = h.tagName.toLowerCase();
			var level = parseInt(tag.substring(1), 10);
			var text = (h.textContent || "").trim();

			if (!text && !h.querySelector("img[alt]")) {
				criticalCount++;
				catCounts.headings++;
				issues.push({
					id: "h-empty-" + idx,
					category: "headings",
					severity: "error",
					rule: "WCAG 1.3.1 (Info and Relationships)",
					title: "Empty Heading Tag <" + tag + ">",
					message: "An empty heading produces a confusing dead-end milestone for screen reader users.",
					snippet: "<" + tag + "></" + tag + ">",
					suggestion: "Add meaningful text describing the section or remove the empty heading element.",
					selector: "h1, h2, h3, h4, h5, h6",
					index: idx,
					quickFixType: "remove-element"
				});
			} else if (level === 1) {
				warningCount++;
				catCounts.headings++;
				issues.push({
					id: "h1-multiple-" + idx,
					category: "headings",
					severity: "warning",
					rule: "WCAG 1.3.1 (Outline Structure)",
					title: "Multiple <h1> Tags Detected",
					message: "The page title is already the primary <h1>. In-page content sections should start at <h2>.",
					snippet: "<h1>" + escapeHtml(text.substring(0, 40)) + "</h1>",
					suggestion: "Demote this heading from <h1> to <h2> to maintain a coherent single-title hierarchy.",
					selector: "h1, h2, h3, h4, h5, h6",
					index: idx,
					quickFixType: "change-heading",
					meta: { targetTag: "h2" }
				});
			} else if (isFirstHeading && level > 2) {
				warningCount++;
				catCounts.headings++;
				issues.push({
					id: "h-skipped-initial-" + idx,
					category: "headings",
					severity: "warning",
					rule: "WCAG 1.3.1 (Heading Outline Order)",
					title: "Top-Level Section Skips <h2> (Found <" + tag + ">)",
					message: "Content begins at <" + tag + "> after the page title <h1> without an introductory <h2>.",
					snippet: "<" + tag + ">" + escapeHtml(text.substring(0, 40)) + "</" + tag + ">",
					suggestion: "Change this initial heading to <h2> so document navigation begins logically.",
					selector: "h1, h2, h3, h4, h5, h6",
					index: idx,
					quickFixType: "change-heading",
					meta: { targetTag: "h2" }
				});
			} else if (!isFirstHeading && level > lastLevel + 1) {
				warningCount++;
				catCounts.headings++;
				var expectedTag = "h" + (lastLevel + 1);
				issues.push({
					id: "h-skipped-" + idx,
					category: "headings",
					severity: "warning",
					rule: "WCAG 1.3.1 (Heading Outline Order)",
					title: "Skipped Heading Level (<" + tag + "> follows <h" + lastLevel + ">)",
					message: "Skipping heading levels (e.g., jumping from <h" + lastLevel + "> to <" + tag + ">) disrupts outline comprehension for assistive software.",
					snippet: "<" + tag + ">" + escapeHtml(text.substring(0, 40)) + "</" + tag + ">",
					suggestion: "Adjust to <" + expectedTag + "> to preserve step-by-step document hierarchy.",
					selector: "h1, h2, h3, h4, h5, h6",
					index: idx,
					quickFixType: "change-heading",
					meta: { targetTag: expectedTag }
				});
			}

			isFirstHeading = false;
			lastLevel = level;
		});

		// --- Rule Group 3: Links (WCAG 2.4.4 Link Purpose in Context) ---
		var links = temp.querySelectorAll("a");
		var ambiguousTerms = [
			"click here", "here", "click", "more", "read more", "learn more",
			"link", "this link", "download", "view", "details", "info", "page"
		];

		links.forEach(function(a, idx) {
			var isAnchorJump = (a.hasAttribute("name") || a.classList.contains("jbd-anchor-marker")) && !a.hasAttribute("href");
			if (isAnchorJump) return;

			var href = (a.getAttribute("href") || "").trim();
			var text = (a.textContent || "").trim();
			var ariaLabel = (a.getAttribute("aria-label") || "").trim();
			var titleAttr = (a.getAttribute("title") || "").trim();
			var hasImgChild = a.querySelector("img");
			var accessibleName = text || ariaLabel || titleAttr || (hasImgChild ? (hasImgChild.getAttribute("alt") || "") : "");

			if (!href || href === "#" || href === "javascript:void(0);" || href === "javascript:;" || href === "javascript:void(0)") {
				warningCount++;
				catCounts.links++;
				issues.push({
					id: "link-placeholder-href-" + idx,
					category: "links",
					severity: "warning",
					rule: "WCAG 2.4.4 / 4.1.2 (Valid Destination)",
					title: "Link Has Empty or Placeholder Href",
					message: 'Link href is empty or "#". If this initiates a JavaScript UI action, a <button> is required.',
					snippet: '<a href="' + escapeHtml(href || "''") + '">' + escapeHtml(text || "Link #" + (idx + 1)) + '</a>',
					suggestion: 'Provide a valid web/document URL or switch to a semantic <button type="button">.',
					selector: "a",
					index: idx,
					quickFixType: "edit-link-href",
					meta: { currentHref: href }
				});
			}

			if (!accessibleName) {
				criticalCount++;
				catCounts.links++;
				issues.push({
					id: "link-empty-name-" + idx,
					category: "links",
					severity: "error",
					rule: "WCAG 2.4.4 (Link Purpose)",
					title: "Completely Empty Link",
					message: "Link contains no readable text, aria-label, or image alt description.",
					snippet: '<a href="' + escapeHtml(href) + '"></a>',
					suggestion: "Insert descriptive anchor text or add an aria-label explaining where the link goes.",
					selector: "a",
					index: idx,
					quickFixType: "add-aria-label",
					meta: { href: href }
				});
			} else {
				var normalized = accessibleName.toLowerCase().replace(/[^a-z0-9 ]/g, "").trim();
				if (ambiguousTerms.indexOf(normalized) !== -1) {
					warningCount++;
					catCounts.links++;
					issues.push({
						id: "link-ambiguous-" + idx,
						category: "links",
						severity: "warning",
						rule: "WCAG 2.4.4 (Link Purpose in Context)",
						title: 'Ambiguous Link Text "' + escapeHtml(accessibleName) + '"',
						message: 'Generic phrases like "' + escapeHtml(accessibleName) + '" provide zero context when screen reader users list all links on a page.',
						snippet: '<a href="' + escapeHtml(href) + '">' + escapeHtml(accessibleName) + '</a>',
						suggestion: 'Provide specific link text (e.g. "Download the 2026 Budget Report" instead of "' + escapeHtml(accessibleName) + '") or add an informative aria-label.',
						selector: "a",
						index: idx,
						quickFixType: "add-aria-label",
						meta: { currentText: accessibleName, href: href }
					});
				} else if (/^https?:\/\//i.test(accessibleName) && accessibleName.length > 25) {
					warningCount++;
					catCounts.links++;
					issues.push({
						id: "link-raw-url-" + idx,
						category: "links",
						severity: "warning",
						rule: "WCAG 2.4.4 (Descriptive Link)",
						title: "Raw URL Used as Link Text",
						message: "Assistive technologies spell out raw URLs character by character.",
						snippet: '<a href="' + escapeHtml(href) + '">' + escapeHtml(accessibleName.substring(0, 35)) + '...</a>',
						suggestion: "Replace the raw URL text with a human-readable title describing the target site or service.",
						selector: "a",
						index: idx,
						quickFixType: "add-aria-label",
						meta: { currentText: accessibleName, href: href }
					});
				}
			}

			// Target="_blank" without screen reader notice or rel="noopener noreferrer"
			if (a.getAttribute("target") === "_blank") {
				var rel = (a.getAttribute("rel") || "").toLowerCase();
				var aria = (a.getAttribute("aria-label") || "").toLowerCase();
				var txt = (a.textContent || "").toLowerCase();
				var hasTabNotice = aria.indexOf("new tab") !== -1 || aria.indexOf("new window") !== -1 ||
				                   txt.indexOf("new tab") !== -1 || txt.indexOf("new window") !== -1;

				if (!hasTabNotice) {
					warningCount++;
					catCounts.links++;
					issues.push({
						id: "link-new-tab-notice-" + idx,
						category: "links",
						severity: "warning",
						rule: "WCAG 3.2.5 (Predictable Navigation)",
						title: "Opens in New Tab Without Screen Reader Notice",
						message: 'Link opens in a new tab without an audible indication like "(opens in a new tab)".',
						snippet: '<a href="' + escapeHtml(href) + '" target="_blank">' + escapeHtml(text || "Link") + '</a>',
						suggestion: 'Add an aria-label with "(opens in a new tab)" to notify assistive tech users.',
						selector: "a",
						index: idx,
						quickFixType: "add-new-tab-notice",
						meta: { text: text, href: href, ariaLabel: ariaLabel }
					});
				}

				if (rel.indexOf("noopener") === -1) {
					warningCount++;
					catCounts.links++;
					issues.push({
						id: "link-noopener-missing-" + idx,
						category: "links",
						severity: "warning",
						rule: "Web Security & Browser Best Practice",
						title: 'target="_blank" Missing rel="noopener noreferrer"',
						message: 'Opening external targets without rel="noopener noreferrer" exposes tab browsing context to reverse tabnabbing.',
						snippet: '<a href="' + escapeHtml(href) + '" target="_blank">',
						suggestion: 'Add rel="noopener noreferrer" to external new-tab hyperlinks.',
						selector: "a",
						index: idx,
						quickFixType: "add-noopener",
						meta: { href: href }
					});
				}
			}
		});

		// --- Rule Group 4: Tables (WCAG 1.3.1 Info and Relationships) ---
		var tables = temp.querySelectorAll("table");
		tables.forEach(function(table, idx) {
			var ths = table.querySelectorAll("th");
			var caption = table.querySelector("caption");
			var ariaLabel = (table.getAttribute("aria-label") || "").trim();

			if (ths.length === 0) {
				criticalCount++;
				catCounts.tables++;
				issues.push({
					id: "table-missing-th-" + idx,
					category: "tables",
					severity: "error",
					rule: "WCAG 1.3.1 (Data Tables)",
					title: "Table Has No Header Cells (<th>)",
					message: "Assistive screen readers cannot associate data cells with headers without <th> cells.",
					snippet: "<table> (Table #" + (idx + 1) + ")",
					suggestion: 'Convert the top row of cells from <td> to <th scope="col">.',
					selector: "table",
					index: idx,
					quickFixType: "convert-table-headers"
				});
			} else {
				var missingScope = false;
				ths.forEach(function(th) {
					if (!th.hasAttribute("scope")) missingScope = true;
				});
				if (missingScope) {
					warningCount++;
					catCounts.tables++;
					issues.push({
						id: "table-missing-scope-" + idx,
						category: "tables",
						severity: "warning",
						rule: "WCAG 1.3.1 (Table Header Scopes)",
						title: "Header Cells Missing scope Attribute",
						message: 'One or more <th> cells lack scope="col" or scope="row", causing ambiguous header association.',
						snippet: "<th>...</th> in Table #" + (idx + 1),
						suggestion: 'Assign scope="col" to column headers and scope="row" to row headers.',
						selector: "table",
						index: idx,
						quickFixType: "add-th-scopes"
					});
				}
			}

			if (!caption && !ariaLabel) {
				warningCount++;
				catCounts.tables++;
				issues.push({
					id: "table-missing-caption-" + idx,
					category: "tables",
					severity: "warning",
					rule: "WCAG 1.3.1 (Table Caption/Name)",
					title: "Table Missing <caption> or aria-label",
					message: "Tables should include a caption or accessible label summarizing the dataset.",
					snippet: "<table> (Table #" + (idx + 1) + ")",
					suggestion: "Add a <caption> element or aria-label describing table contents.",
					selector: "table",
					index: idx,
					quickFixType: "add-table-caption"
				});
			}
		});

		// --- Rule Group 5: Readability, Styling & Contrast (WCAG 1.4.3 / 1.4.12) ---
		// Check for hardcoded low contrast colors on light backgrounds
		var styledElements = temp.querySelectorAll("[style*='color']");
		var lowContrastRegex = /color\s*:\s*(#fff|#ffffff|#ccc|#cccccc|#eee|#eeeeee|#ddd|#dddddd|white|lightgray|yellow|lime|cyan)\b/i;
		styledElements.forEach(function(el, idx) {
			var styleStr = el.getAttribute("style") || "";
			if (lowContrastRegex.test(styleStr)) {
				warningCount++;
				catCounts.format++;
				issues.push({
					id: "contrast-low-" + idx,
					category: "format",
					severity: "warning",
					rule: "WCAG 1.4.3 (Contrast Minimum)",
					title: "Potential Low-Contrast Inline Color",
					message: 'Element specifies a pale or low-contrast text color inline (' + escapeHtml(styleStr) + '). On standard light backgrounds, this fails the 4.5:1 ratio.',
					snippet: '<' + el.tagName.toLowerCase() + ' style="' + escapeHtml(styleStr) + '">' + escapeHtml((el.textContent || "").substring(0, 30)) + '</' + el.tagName.toLowerCase() + '>',
					suggestion: "Remove inline color styles or ensure a minimum contrast ratio of 4.5:1 against the background.",
					selector: "[style*='color']",
					index: idx,
					quickFixType: "remove-style-color"
				});
			}
		});

		// Check for excessive uppercase blocks (> 60 chars)
		var textNodes = temp.querySelectorAll("p, div, span, li");
		textNodes.forEach(function(el, idx) {
			var txt = (el.textContent || "").trim();
			if (txt.length > 60) {
				var upperCount = (txt.match(/[A-Z]/g) || []).length;
				var letterCount = (txt.match(/[a-zA-Z]/g) || []).length;
				if (letterCount > 50 && (upperCount / letterCount) > 0.85) {
					warningCount++;
					catCounts.format++;
					issues.push({
						id: "format-uppercase-" + idx,
						category: "format",
						severity: "warning",
						rule: "WCAG Readability Best Practice",
						title: "Extended Block of Uppercase Text",
						message: "Large passages of ALL-CAPS text are difficult for users with dyslexia and visual impairments to read.",
						snippet: '<p>' + escapeHtml(txt.substring(0, 50)) + '...</p>',
						suggestion: "Use sentence case with bold emphasis rather than all-uppercase text.",
						selector: "p, div, span, li",
						index: idx,
						quickFixType: "to-sentence-case"
					});
				}
			}
		});

		// Check for excessive empty paragraphs used as spacers
		var emptyParas = temp.querySelectorAll("p");
		var spacerCount = 0;
		emptyParas.forEach(function(p) {
			var inner = p.innerHTML.trim();
			if (inner === "" || inner === "&nbsp;" || inner === "<br>" || inner === "<br/>") {
				spacerCount++;
			}
		});
		if (spacerCount >= 3) {
			warningCount++;
			catCounts.format++;
			issues.push({
				id: "format-empty-spacers",
				category: "format",
				severity: "warning",
				rule: "WCAG 1.3.1 (Semantic Whitespace)",
				title: spacerCount + " Empty Paragraph Spacer Tags Found",
				message: "Using empty <p>&nbsp;</p> tags for visual spacing creates repetitive blank pauses for screen reader navigation.",
				snippet: "<p>&nbsp;</p> (x" + spacerCount + ")",
				suggestion: "Remove empty spacer paragraphs and use CSS margin/padding or the editor's divider component.",
				selector: "p",
				index: 0,
				quickFixType: "remove-empty-spacers"
			});
		}

		// --- Rule Group 6: Page Metadata & Title ---
		var titleInput = document.getElementById("pgTitle");
		var pageTitleVal = titleInput ? titleInput.value.trim() : "";
		if (!pageTitleVal || pageTitleVal.length < 3) {
			criticalCount++;
			catCounts.headings++;
			issues.push({
				id: "meta-page-title",
				category: "headings",
				severity: "error",
				rule: "WCAG 2.4.2 (Page Titled)",
				title: "Missing or Inadequate Page Title",
				message: "Every web page must have a descriptive title explaining its topic or purpose.",
				snippet: '<input id="pgTitle" value="' + escapeHtml(pageTitleVal) + '">',
				suggestion: "Provide a descriptive title for this page (e.g. 'Community Development Building Permits').",
				selector: "#pgTitle",
				index: 0,
				quickFixType: "focus-input",
				meta: { inputId: "pgTitle" }
			});
		}

		var metaDescInput = document.getElementById("pgMetaDesc");
		var metaDescVal = metaDescInput ? metaDescInput.value.trim() : "";
		if (metaDescVal.length > 160) {
			warningCount++;
			catCounts.format++;
			issues.push({
				id: "meta-desc-length",
				category: "format",
				severity: "warning",
				rule: "SEO & Accessibility Best Practice",
				title: "Meta Description Exceeds 160 Characters (" + metaDescVal.length + " chars)",
				message: "Search engines and screen reader summaries truncate descriptions beyond 160 characters.",
				snippet: escapeHtml(metaDescVal.substring(0, 60)) + "...",
				suggestion: "Shorten the meta description so key points remain legible in snippet previews.",
				selector: "#pgMetaDesc",
				index: 0,
				quickFixType: "focus-input",
				meta: { inputId: "pgMetaDesc" }
			});
		}

		_lastResults = {
			passed: (criticalCount === 0),
			criticalCount: criticalCount,
			warningCount: warningCount,
			categories: catCounts,
			issues: issues
		};

		renderUI();
		return _lastResults;
	}

	function renderUI() {
		var res = _lastResults;
		var totalIssues = res.criticalCount + res.warningCount;

		// 1. Update Linter Bar Header & Overall Badge
		var bar = document.getElementById("pgA11yLinterBar");
		var overallBadge = document.getElementById("pgA11yOverallBadge");
		var issueCountBadge = document.getElementById("pgA11yIssueBadge");

		if (bar) {
			bar.classList.remove("is-passed", "is-warn", "is-error");
			if (res.criticalCount > 0) {
				bar.classList.add("is-error");
			} else if (res.warningCount > 0) {
				bar.classList.add("is-warn");
			} else {
				bar.classList.add("is-passed");
			}
		}

		if (overallBadge) {
			overallBadge.className = "badge";
			if (res.criticalCount > 0) {
				overallBadge.classList.add("badge-danger");
				overallBadge.innerHTML = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg> <span>' + res.criticalCount + ' Error' + (res.criticalCount === 1 ? '' : 's') + '</span>';
			} else if (res.warningCount > 0) {
				overallBadge.classList.add("badge-warning");
				overallBadge.innerHTML = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg> <span>' + res.warningCount + ' Warning' + (res.warningCount === 1 ? '' : 's') + '</span>';
			} else {
				overallBadge.classList.add("badge-success");
				overallBadge.innerHTML = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> <span>Compliant</span>';
			}
		}

		if (issueCountBadge) {
			issueCountBadge.textContent = totalIssues;
			issueCountBadge.className = "badge " + (res.criticalCount > 0 ? "badge-danger" : (res.warningCount > 0 ? "badge-warning" : "badge-neutral"));
		}

		// 2. Update Category Chips
		var chipMap = {
			cover: { chip: "chipA11yCover", count: "countA11yCover" },
			images: { chip: "chipA11yImages", count: "countA11yImages" },
			headings: { chip: "chipA11yHeadings", count: "countA11yHeadings" },
			links: { chip: "chipA11yLinks", count: "countA11yLinks" },
			tables: { chip: "chipA11yTables", count: "countA11yTables" },
			format: { chip: "chipA11yFormat", count: "countA11yFormat" }
		};

		Object.keys(chipMap).forEach(function(catKey) {
			var cfg = chipMap[catKey];
			var chipEl = document.getElementById(cfg.chip);
			var countEl = document.getElementById(cfg.count);
			var count = res.categories[catKey] || 0;

			if (countEl) countEl.textContent = count;
			if (chipEl) {
				chipEl.classList.remove("has-error", "has-warn");
				// Check if category contains critical errors
				var hasCrit = res.issues.some(function(i) { return i.category === catKey && i.severity === "error"; });
				if (hasCrit) {
					chipEl.classList.add("has-error");
				} else if (count > 0) {
					chipEl.classList.add("has-warn");
				}
			}
		});

		// 3. Update Publish Card Scorecard
		var pubBadge = document.getElementById("pgA11yPublishBadge");
		var pubSummary = document.getElementById("pgA11yPublishSummary");
		if (pubBadge) {
			pubBadge.className = "badge";
			if (res.criticalCount > 0) {
				pubBadge.classList.add("badge-danger");
				pubBadge.textContent = (res.criticalCount === 1) ? "1 CRITICAL" : (res.criticalCount + " CRITICAL");
			} else if (res.warningCount > 0) {
				pubBadge.classList.add("badge-warning");
				pubBadge.textContent = (res.warningCount === 1) ? "1 WARNING" : (res.warningCount + " WARNINGS");
			} else {
				pubBadge.classList.add("badge-success");
				pubBadge.textContent = "PASS";
			}
		}
		if (pubSummary) {
			if (res.criticalCount > 0) {
				pubSummary.innerHTML = '<span style="color:#b91c1c; font-weight:600;">' + res.criticalCount + ' critical barrier' + (res.criticalCount === 1 ? '' : 's') + ' detected.</span> Resolution recommended before publishing.';
			} else if (res.warningCount > 0) {
				pubSummary.innerHTML = '<span style="color:#b45309; font-weight:600;">Compliant with ' + res.warningCount + ' best-practice recommendation' + (res.warningCount === 1 ? '' : 's') + '.</span>';
			} else {
				pubSummary.textContent = "Content ready for public release. Meets ADA WCAG 2.1 AA.";
			}
		}

		// 4. Update Filter Tab Counts
		var tabAll = document.getElementById("tabCountA11yAll");
		var tabErr = document.getElementById("tabCountA11yErrors");
		var tabWarn = document.getElementById("tabCountA11yWarnings");
		if (tabAll) tabAll.textContent = totalIssues;
		if (tabErr) tabErr.textContent = res.criticalCount;
		if (tabWarn) tabWarn.textContent = res.warningCount;

		// 5. Render Issues Drawer List and Publish Scorecard Inline List
		renderDrawerList();
		renderPublishInlineList();
	}

	function renderDrawerList() {
		var listEl = document.getElementById("pgA11yIssuesList");
		if (!listEl) return;

		var filtered = _lastResults.issues.filter(function(issue) {
			if (_activeFilter === "errors") return issue.severity === "error";
			if (_activeFilter === "warnings") return issue.severity === "warning";
			if (_activeFilter === "cover" || _activeFilter === "images" || _activeFilter === "headings" || _activeFilter === "links" || _activeFilter === "tables" || _activeFilter === "format") {
				return issue.category === _activeFilter;
			}
			return true;
		});

		if (filtered.length === 0) {
			if (_lastResults.issues.length === 0) {
				listEl.innerHTML = '<div style="text-align:center; padding:1.75rem 1rem; color:var(--admin-text-muted); font-size:0.875rem;">' +
					'<svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" style="margin:0 auto 0.5rem auto; display:block;"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>' +
					'<strong style="color:var(--admin-text-main); display:block; margin-bottom:0.25rem;">100% WCAG 2.1 AA Compliant!</strong>' +
					'<span>No accessibility barriers detected across images, headings, links, tables, or text contrast.</span>' +
				'</div>';
			} else {
				listEl.innerHTML = '<div style="text-align:center; padding:1.5rem 1rem; color:var(--admin-text-muted); font-size:0.85rem;">' +
					'No issues found matching this filter.' +
				'</div>';
			}
			renderPublishInlineList();
			return;
		}

		var html = "";
		filtered.forEach(function(issue) {
			var isErr = (issue.severity === "error");
			var cardClass = isErr ? "is-error" : "is-warn";
			var tagClass = isErr ? "error" : "warn";
			var tagLabel = isErr ? "Violation" : "Recommendation";

			html += '<div class="pg-a11y-issue-card ' + cardClass + '" id="card-' + issue.id + '" data-issue-id="' + issue.id + '">';
			html += '  <div class="pg-a11y-issue-header">';
			html += '    <div style="display:flex; align-items:center; gap:0.45rem;">';
			html += '      <span class="pg-a11y-rule-tag ' + tagClass + '">' + tagLabel + '</span>';
			html += '      <strong style="font-size:0.85rem; color:var(--admin-text-main);">' + escapeHtml(issue.title) + '</strong>';
			html += '    </div>';
			html += '    <span style="font-size:0.72rem; color:var(--admin-text-muted); font-family:monospace;">' + escapeHtml(issue.rule) + '</span>';
			html += '  </div>';

			html += '  <div class="pg-a11y-issue-msg">' + escapeHtml(issue.message) + '</div>';

			if (issue.snippet) {
				html += '  <div class="pg-a11y-issue-code">' + escapeHtml(issue.snippet) + '</div>';
			}

			html += '  <div class="pg-a11y-issue-suggestion"><strong>How to resolve:</strong> ' + escapeHtml(issue.suggestion) + '</div>';

			html += '  <div class="pg-a11y-issue-actions">';
			html += '    <button type="button" class="btn btn-outline btn-xs" onclick="window.PageA11yLinter.locateIssue(\'' + issue.id + '\')" title="Scroll to and outline this item in the editor">';
			html += '      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:3px;"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>';
			html += '      <span>Locate in Editor</span>';
			html += '    </button>';

			if (issue.quickFixType) {
				html += '    <button type="button" class="btn btn-primary btn-xs" onclick="window.PageA11yLinter.applyQuickFix(\'' + issue.id + '\')" style="background:var(--admin-primary);">';
				html += '      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:3px;"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>';
				html += '      <span>Quick Fix</span>';
				html += '    </button>';
			}
			html += '  </div>';

			html += '</div>';
		});

		listEl.innerHTML = html;
		renderPublishInlineList();
	}

	function renderPublishInlineList() {
		var inlineEl = document.getElementById("pgA11yPublishInlineList");
		var pubBadge = document.getElementById("pgA11yPublishBadge");
		var pubSummary = document.getElementById("pgA11yPublishSummary");

		var issues = (_lastResults && _lastResults.issues) ? _lastResults.issues : [];
		var critCount = issues.filter(function(i) { return i.severity === "error"; }).length;
		var warnCount = issues.filter(function(i) { return i.severity === "warning"; }).length;

		// Ensure Publish Scorecard badge and summary are always 100% in lockstep with issues
		if (pubBadge) {
			pubBadge.className = "badge";
			if (critCount > 0) {
				pubBadge.classList.add("badge-danger");
				pubBadge.textContent = (critCount === 1) ? "1 CRITICAL" : (critCount + " CRITICAL");
			} else if (warnCount > 0) {
				pubBadge.classList.add("badge-warning");
				pubBadge.textContent = (warnCount === 1) ? "1 WARNING" : (warnCount + " WARNINGS");
			} else {
				pubBadge.classList.add("badge-success");
				pubBadge.textContent = "PASS";
			}
		}
		if (pubSummary) {
			if (critCount > 0) {
				pubSummary.innerHTML = '<span style="color:#b91c1c; font-weight:600;">' + critCount + ' critical barrier' + (critCount === 1 ? '' : 's') + ' detected.</span> Resolution recommended before publishing.';
			} else if (warnCount > 0) {
				pubSummary.innerHTML = '<span style="color:#b45309; font-weight:600;">Compliant with ' + warnCount + ' best-practice recommendation' + (warnCount === 1 ? '' : 's') + '.</span>';
			} else {
				pubSummary.textContent = "Content ready for public release. Meets ADA WCAG 2.1 AA.";
			}
		}

		// Update Inspect Diagnostics link text to match exact live issue count
		var lnkText = document.getElementById("lnkInspectA11yText");
		var drawer = document.getElementById("pgA11yIssuesDrawer");
		var isDrawerOpen = drawer && (!drawer.hidden && drawer.style.display !== "none");
		if (lnkText) {
			if (issues.length === 0) {
				lnkText.textContent = isDrawerOpen ? "Hide Audit Summary" : "View Audit Summary";
			} else {
				lnkText.textContent = isDrawerOpen ? ("Hide Diagnostics (" + issues.length + ")") : ("Inspect Diagnostics (" + issues.length + ")");
			}
		}

		if (!inlineEl) return;

		if (issues.length === 0) {
			inlineEl.innerHTML = '<div style="padding:0.5rem 0.6rem; border-radius:6px; background:#f0fdf4; border:1px solid #bbf7d0; color:#166534; font-size:0.74rem; line-height:1.35;">' +
				'<strong>100% WCAG 2.1 AA Compliant</strong><br>No accessibility barriers detected.' +
			'</div>';
			return;
		}

		var inlineHtml = "";
		issues.forEach(function(issue) {
			var isErr = (issue.severity === "error");
			var borderColor = isErr ? "#ef4444" : "#f59e0b";
			var bgColor = isErr ? "#fffbfb" : "#fffdf9";
			var tagBg = isErr ? "#fee2e2" : "#fef3c7";
			var tagColor = isErr ? "#b91c1c" : "#b45309";
			var tagLabel = isErr ? "CRITICAL" : "WARN";

			inlineHtml += '<div style="border:1px solid var(--admin-border, #cbd5e1); border-left:3px solid ' + borderColor + '; border-radius:6px; padding:0.5rem 0.6rem; background:' + bgColor + '; display:flex; flex-direction:column; gap:0.3rem;">';
			inlineHtml += '  <div style="display:flex; align-items:center; gap:0.35rem; flex-wrap:wrap;">';
			inlineHtml += '    <span style="font-size:0.62rem; font-weight:700; padding:0.08rem 0.35rem; border-radius:3px; background:' + tagBg + '; color:' + tagColor + ';">' + tagLabel + '</span>';
			inlineHtml += '    <strong style="font-size:0.75rem; color:var(--admin-text-main); line-height:1.25;">' + escapeHtml(issue.title) + '</strong>';
			inlineHtml += '  </div>';
			inlineHtml += '  <div style="font-size:0.71rem; color:var(--admin-text-muted); line-height:1.3;">' + escapeHtml(issue.message) + '</div>';
			inlineHtml += '  <div style="display:flex; align-items:center; gap:0.35rem; margin-top:0.15rem;">';
			inlineHtml += '    <button type="button" class="btn btn-outline btn-xs" style="padding:0.15rem 0.45rem; font-size:0.68rem;" onclick="window.PageA11yLinter.locateIssue(\'' + issue.id + '\')">Locate</button>';
			if (issue.quickFixType) {
				inlineHtml += '    <button type="button" class="btn btn-primary btn-xs" style="padding:0.15rem 0.45rem; font-size:0.68rem; background:var(--admin-primary);" onclick="window.PageA11yLinter.applyQuickFix(\'' + issue.id + '\')">Quick Fix</button>';
			}
			inlineHtml += '  </div>';
			inlineHtml += '</div>';
		});
		inlineEl.innerHTML = inlineHtml;
	}

	function askA11yInputModal(titleText, labelText, defaultValue, onSubmit) {
		var existing = document.getElementById("pgA11yQuickFixModalBackdrop");
		if (existing) existing.remove();

		var backdrop = document.createElement("div");
		backdrop.id = "pgA11yQuickFixModalBackdrop";
		backdrop.style.cssText = "position:fixed; inset:0; z-index:100005; background:rgba(15,23,42,0.6); backdrop-filter:blur(3px); display:flex; align-items:center; justify-content:center; padding:1rem;";

		var modal = document.createElement("div");
		modal.setAttribute("role", "dialog");
		modal.setAttribute("aria-modal", "true");
		modal.style.cssText = "background:var(--admin-surface, #fff); border:1px solid var(--admin-border, #cbd5e1); border-radius:0.75rem; width:100%; max-width:440px; box-shadow:0 20px 50px rgba(15,23,42,0.25); overflow:hidden;";

		modal.innerHTML =
			'<div style="padding:0.85rem 1.1rem; border-bottom:1px solid var(--admin-border-subtle, #e2e8f0); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg, #f8fafc);">' +
				'<strong style="font-size:0.92rem; color:var(--admin-text-main);">' + escapeHtml(titleText) + '</strong>' +
				'<button type="button" id="pgA11yModalCloseBtn" class="btn btn-ghost btn-xs" style="padding:0.15rem 0.4rem;">&times;</button>' +
			'</div>' +
			'<div style="padding:1rem 1.1rem;">' +
				'<label for="pgA11yModalInput" style="display:block; font-size:0.8rem; font-weight:600; color:var(--admin-text-main); margin-bottom:0.4rem;">' + escapeHtml(labelText) + '</label>' +
				'<input type="text" id="pgA11yModalInput" class="form-control" style="width:100%;" value="' + escapeHtml(defaultValue || "") + '">' +
			'</div>' +
			'<div style="padding:0.75rem 1.1rem; border-top:1px solid var(--admin-border-subtle, #e2e8f0); display:flex; justify-content:flex-end; gap:0.5rem; background:var(--admin-bg, #f8fafc);">' +
				'<button type="button" id="pgA11yModalCancelBtn" class="btn btn-outline btn-sm">Cancel</button>' +
				'<button type="button" id="pgA11yModalApplyBtn" class="btn btn-primary btn-sm">Apply Fix</button>' +
			'</div>';

		backdrop.appendChild(modal);
		document.body.appendChild(backdrop);

		var input = document.getElementById("pgA11yModalInput");
		var closeBtn = document.getElementById("pgA11yModalCloseBtn");
		var cancelBtn = document.getElementById("pgA11yModalCancelBtn");
		var applyBtn = document.getElementById("pgA11yModalApplyBtn");

		function close() {
			if (backdrop && backdrop.parentNode) backdrop.parentNode.removeChild(backdrop);
		}
		function submit() {
			var val = input ? input.value : "";
			close();
			if (typeof onSubmit === "function") onSubmit(val);
		}

		if (closeBtn) closeBtn.onclick = close;
		if (cancelBtn) cancelBtn.onclick = close;
		if (applyBtn) applyBtn.onclick = submit;
		backdrop.onclick = function(e) { if (e.target === backdrop) close(); };
		if (input) {
			input.focus();
			input.select();
			input.onkeydown = function(e) {
				if (e.key === "Enter") { e.preventDefault(); submit(); }
				if (e.key === "Escape") { e.preventDefault(); close(); }
			};
		}
	}

	function locateIssue(issueId) {
		var issue = _lastResults.issues.find(function(i) { return i.id === issueId; });
		if (!issue) return;

		if (issue.quickFixType === "focus-input" && issue.meta && issue.meta.inputId) {
			var inputEl = document.getElementById(issue.meta.inputId);
			if (inputEl) {
				inputEl.scrollIntoView({ behavior: "smooth", block: "center" });
				inputEl.focus();
				inputEl.classList.add("jbd-a11y-pulse");
				setTimeout(function() { inputEl.classList.remove("jbd-a11y-pulse"); }, 3600);
			}
			return;
		}

		var ed = getEditor();
		if (!ed || !ed.contentArea) {
			var ta = document.getElementById("pgContent");
			if (ta) ta.scrollIntoView({ behavior: "smooth", block: "center" });
			return;
		}

		var targets = ed.contentArea.querySelectorAll(issue.selector);
		var targetNode = targets[issue.index];

		if (!targetNode && targets.length > 0) {
			targetNode = targets[0];
		}

		if (targetNode) {
			targetNode.scrollIntoView({ behavior: "smooth", block: "center" });
			targetNode.classList.add("jbd-a11y-pulse");
			setTimeout(function() {
				targetNode.classList.remove("jbd-a11y-pulse");
			}, 3600);
		} else {
			ed.contentArea.scrollIntoView({ behavior: "smooth", block: "center" });
		}
	}

	function applyQuickFix(issueId) {
		var issue = _lastResults.issues.find(function(i) { return i.id === issueId; });
		if (!issue) return;

		var ed = getEditor();
		var contentArea = ed ? ed.contentArea : null;

		function syncChanges() {
			if (ed && typeof ed.syncToTarget === "function") {
				ed.syncToTarget();
			}
			scan();
			if (typeof window.showToast === "function") {
				window.showToast("Applied Quick Fix: " + issue.title, "success");
			}
		}

		if (issue.quickFixType === "focus-input") {
			locateIssue(issueId);
			return;
		}

		if (!contentArea) {
			window.adminAlert({ title: "Editor Not Loaded", message: "Quick fix requires the rich text editor to be loaded.", type: "warning" });
			return;
		}

		var targets = contentArea.querySelectorAll(issue.selector);
		var targetNode = targets[issue.index] || targets[0];

		if (!targetNode && issue.quickFixType !== "remove-empty-spacers") {
			window.adminAlert({ title: "Element Not Found", message: "Unable to locate element in editor for quick fix.", type: "warning" });
			return;
		}

		switch (issue.quickFixType) {
			case "set-alt":
				askA11yInputModal(
					"Image Alternative Text (WCAG 1.1.1)",
					"Enter descriptive alt text (or leave blank to mark decorative):",
					issue.meta ? (issue.meta.currentAlt || "") : "",
					function(promptVal) {
						var trimmed = (promptVal || "").trim();
						if (trimmed.length > 0) {
							targetNode.setAttribute("alt", trimmed);
							targetNode.removeAttribute("role");
							targetNode.removeAttribute("aria-hidden");
						} else {
							targetNode.setAttribute("alt", "");
							targetNode.setAttribute("role", "presentation");
						}
						syncChanges();
					}
				);
				break;

			case "change-heading":
				var newTag = (issue.meta && issue.meta.targetTag) ? issue.meta.targetTag : "h2";
				var replacementHeading = document.createElement(newTag);
				replacementHeading.innerHTML = targetNode.innerHTML;
				Array.from(targetNode.attributes).forEach(function(attr) {
					replacementHeading.setAttribute(attr.name, attr.value);
				});
				targetNode.parentNode.replaceChild(replacementHeading, targetNode);
				syncChanges();
				break;

			case "remove-element":
				targetNode.remove();
				syncChanges();
				break;

			case "add-aria-label":
				var existingLabel = targetNode.getAttribute("aria-label") || (targetNode.textContent || "").trim();
				askA11yInputModal(
					"Accessible Link Label (WCAG 2.4.4)",
					"Enter an accessible description / aria-label for this link:",
					existingLabel,
					function(newLabel) {
						if (newLabel && newLabel.trim().length > 0) {
							targetNode.setAttribute("aria-label", newLabel.trim());
							syncChanges();
						}
					}
				);
				break;

			case "add-new-tab-notice":
				var currentAria = targetNode.getAttribute("aria-label") || (targetNode.textContent || "").trim();
				var noticeText = currentAria ? (currentAria + " (opens in a new tab)") : "Link (opens in a new tab)";
				targetNode.setAttribute("aria-label", noticeText);
				if (!targetNode.getAttribute("rel") || targetNode.getAttribute("rel").indexOf("noopener") === -1) {
					targetNode.setAttribute("rel", "noopener noreferrer");
				}
				syncChanges();
				break;

			case "add-noopener":
				var curRel = (targetNode.getAttribute("rel") || "").trim();
				var parts = curRel ? curRel.split(/\s+/) : [];
				if (parts.indexOf("noopener") === -1) parts.push("noopener");
				if (parts.indexOf("noreferrer") === -1) parts.push("noreferrer");
				targetNode.setAttribute("rel", parts.join(" "));
				syncChanges();
				break;

			case "convert-table-headers":
				var firstRow = targetNode.querySelector("tr");
				if (firstRow) {
					var cells = firstRow.children;
					for (var c = 0; c < cells.length; c++) {
						var td = cells[c];
						if (td.tagName.toLowerCase() === "td") {
							var th = document.createElement("th");
							th.setAttribute("scope", "col");
							th.innerHTML = td.innerHTML || "Header " + (c + 1);
							firstRow.replaceChild(th, td);
						}
					}
					syncChanges();
				}
				break;

			case "add-th-scopes":
				var thList = targetNode.querySelectorAll("th");
				thList.forEach(function(th) {
					if (!th.hasAttribute("scope")) {
						th.setAttribute("scope", "col");
					}
				});
				syncChanges();
				break;

			case "add-table-caption":
				var existingCaption = targetNode.querySelector("caption");
				askA11yInputModal(
					"Table Caption (WCAG 1.3.1)",
					"Enter a brief title or caption summarizing this table:",
					existingCaption ? existingCaption.textContent : "Data Summary Table",
					function(captionPrompt) {
						if (captionPrompt && captionPrompt.trim().length > 0) {
							if (!existingCaption) {
								existingCaption = document.createElement("caption");
								targetNode.insertBefore(existingCaption, targetNode.firstChild);
							}
							existingCaption.textContent = captionPrompt.trim();
							syncChanges();
						}
					}
				);
				break;

			case "remove-style-color":
				targetNode.style.color = "";
				if (!targetNode.getAttribute("style") || !targetNode.getAttribute("style").trim()) {
					targetNode.removeAttribute("style");
				}
				syncChanges();
				break;

			case "to-sentence-case":
				var rawText = targetNode.textContent || "";
				var converted = rawText.charAt(0).toUpperCase() + rawText.slice(1).toLowerCase();
				targetNode.textContent = converted;
				syncChanges();
				break;

			case "remove-empty-spacers":
				var paras = contentArea.querySelectorAll("p");
				paras.forEach(function(p) {
					var ih = p.innerHTML.trim();
					if (ih === "" || ih === "&nbsp;" || ih === "<br>" || ih === "<br/>") {
						p.remove();
					}
				});
				syncChanges();
				break;

			case "edit-link-href":
				askA11yInputModal(
					"Edit Link Destination (WCAG 2.4.4)",
					"Enter destination URL or path for this link:",
					(issue.meta && issue.meta.currentHref) ? issue.meta.currentHref : "https://",
					function(promptHref) {
						if (promptHref && promptHref.trim().length > 0) {
							targetNode.setAttribute("href", promptHref.trim());
							syncChanges();
						}
					}
				);
				break;

			default:
				console.warn("Unhandled quick fix type:", issue.quickFixType);
		}
	}

	function syncDrawerState(isOpen) {
		var drawer = document.getElementById("pgA11yIssuesDrawer");
		var toggleBtn = document.getElementById("btnToggleA11yDrawer");
		var inlineList = document.getElementById("pgA11yPublishInlineList");
		var lnkInspect = document.getElementById("lnkInspectA11yDrawer");
		var lnkText = document.getElementById("lnkInspectA11yText");
		var lnkChevron = document.getElementById("lnkInspectA11yChevron");

		var issues = (_lastResults && _lastResults.issues) ? _lastResults.issues : [];
		var issueCount = issues.length;

		if (drawer) {
			drawer.hidden = !isOpen;
			drawer.style.display = isOpen ? "flex" : "none";
		}
		if (toggleBtn) {
			toggleBtn.setAttribute("aria-expanded", String(isOpen));
		}
		if (inlineList) {
			inlineList.style.display = isOpen ? "flex" : "none";
		}
		if (lnkInspect) {
			lnkInspect.setAttribute("aria-expanded", String(isOpen));
		}
		if (lnkText) {
			if (issueCount === 0) {
				lnkText.textContent = isOpen ? "Hide Audit Summary" : "View Audit Summary";
			} else {
				lnkText.textContent = isOpen ? ("Hide Diagnostics (" + issueCount + ")") : ("Inspect Diagnostics (" + issueCount + ")");
			}
		}
		if (lnkChevron) {
			lnkChevron.style.transform = isOpen ? "rotate(180deg)" : "rotate(0deg)";
		}
	}

	function toggleDrawer(source) {
		var drawer = document.getElementById("pgA11yIssuesDrawer");
		if (!drawer) return;

		var isHidden = drawer.hidden || drawer.style.display === "none";
		if (isHidden) {
			openDrawer(source);
		} else {
			closeDrawer();
		}
	}

	function openDrawer(source) {
		scan(); // Force fresh scan so results and scorecard are 100% synchronized
		syncDrawerState(true);
		var drawer = document.getElementById("pgA11yIssuesDrawer");
		if (drawer) {
			if (source !== "publish") {
				drawer.scrollIntoView({ behavior: "smooth", block: "nearest" });
			}
			drawer.classList.add("jbd-a11y-pulse");
			setTimeout(function() { drawer.classList.remove("jbd-a11y-pulse"); }, 2400);
		}
	}

	function closeDrawer() {
		syncDrawerState(false);
	}

	function setFilter(filterName) {
		_activeFilter = filterName;

		// Update tab active states
		var tabs = ["tabA11yAll", "tabA11yErrors", "tabA11yWarnings"];
		tabs.forEach(function(tid) {
			var el = document.getElementById(tid);
			if (el) {
				var f = el.getAttribute("data-filter");
				if (f === filterName) {
					el.classList.add("is-active");
				} else {
					el.classList.remove("is-active");
				}
			}
		});

		// Ensure drawer is open when filtering
		openDrawer();
	}

	function scheduleScan() {
		if (_scanDebounceTimer) clearTimeout(_scanDebounceTimer);
		_scanDebounceTimer = setTimeout(function() {
			scan();
		}, 250);
	}

	function init() {
		// Wire UI Controls using .onclick to avoid duplicate listeners with inline onclick attributes
		var btnToggle = document.getElementById("btnToggleA11yDrawer");
		if (btnToggle) btnToggle.onclick = function() { toggleDrawer(); };

		var btnClose = document.getElementById("btnCloseA11yDrawer");
		if (btnClose) btnClose.onclick = function() { closeDrawer(); };

		var btnRescan = document.getElementById("btnRescanA11y");
		if (btnRescan) btnRescan.onclick = function() { scan(); };

		var lnkInspect = document.getElementById("lnkInspectA11yDrawer");
		if (lnkInspect) lnkInspect.onclick = function(e) {
			if (e) e.preventDefault();
			toggleDrawer("publish");
			return false;
		};

		// Wire Filter Tabs
		var tabAll = document.getElementById("tabA11yAll");
		if (tabAll) tabAll.onclick = function() { setFilter("all"); };
		var tabErrors = document.getElementById("tabA11yErrors");
		if (tabErrors) tabErrors.onclick = function() { setFilter("errors"); };
		var tabWarnings = document.getElementById("tabA11yWarnings");
		if (tabWarnings) tabWarnings.onclick = function() { setFilter("warnings"); };

		// Wire Category Chips
		var chips = document.querySelectorAll(".pg-a11y-chip");
		chips.forEach(function(chip) {
			chip.onclick = function() {
				var cat = chip.getAttribute("data-cat");
				setFilter(cat);
			};
		});

		// Bind editor readiness and reactive input listeners
		bindEditorEvents();

		var ta = document.getElementById("pgContent");
		if (ta) {
			ta.addEventListener("input", scheduleScan);
			ta.addEventListener("change", scheduleScan);
		}

		var titleInput = document.getElementById("pgTitle");
		if (titleInput) {
			titleInput.addEventListener("input", scheduleScan);
		}

		var metaDescInput = document.getElementById("pgMetaDesc");
		if (metaDescInput) {
			metaDescInput.addEventListener("input", scheduleScan);
		}

		var featImg = document.getElementById("featuredImage");
		if (featImg) featImg.addEventListener("input", scheduleScan);

		var featAlt = document.getElementById("featuredImageAlt");
		if (featAlt) featAlt.addEventListener("input", scheduleScan);

		var featDec = document.getElementById("featuredImageDecorative");
		if (featDec) featDec.addEventListener("change", scheduleScan);

		// Poll for JBDEditor async readiness
		var pollCount = 0;
		var pollTimer = setInterval(function() {
			pollCount++;
			if (bindEditorEvents() || pollCount > 15) {
				clearInterval(pollTimer);
				scan();
			}
		}, 120);

		// Initial scan
		setTimeout(scan, 150);
	}

	// Auto-init on DOMContentLoaded or immediate
	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", init);
	} else {
		setTimeout(init, 100);
	}

	return {
		scan: scan,
		getResults: function() { return _lastResults; },
		toggleDrawer: toggleDrawer,
		openDrawer: openDrawer,
		closeDrawer: closeDrawer,
		setFilter: setFilter,
		locateIssue: locateIssue,
		applyQuickFix: applyQuickFix
	};
})();

// Ensure any loading transition screen dismisses when editor DOM is ready
if (typeof window.hidePageLoader === "function") window.hidePageLoader();
if (typeof window.finishTopProgress === "function") window.finishTopProgress();
</script>

<!--- Media Picker Modal Overlay for Page Editor --->
<div class="admin-modal-backdrop" id="mediaPickerModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeMediaPickerModal()"></div>
<div class="admin-modal" id="mediaPickerModal" role="dialog" aria-modal="true" aria-labelledby="mediaPickerModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:96vw; max-width:1440px; height:88vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; background:#f8fafc;">
		<h2 class="modal-title" id="mediaPickerModalTitle" style="margin:0; font-size:1.05rem; font-weight:700; display:flex; align-items:center; gap:0.5rem;">
			<cfoutput>#svgIcon(name="media", size=18)#</cfoutput>
			<span id="mediaPickerTitleText">Select Asset from Media Library</span>
		</h2>
		<div style="display:flex; align-items:center; gap:0.5rem;">
			<button type="button" class="btn btn-outline-primary btn-sm" onclick="triggerMediaPickerUpload()" style="display:inline-flex; align-items:center; gap:0.35rem;" title="Upload new media asset to repository">
				<cfoutput>#svgIcon(name="upload", size=14)#</cfoutput>
				<span>Upload New File</span>
			</button>
			<button type="button" class="btn btn-secondary btn-sm" onclick="closeMediaPickerModal()" aria-label="Close Media Picker">
				<cfoutput>#svgIcon(name="x", size=16)#</cfoutput>
			</button>
		</div>
	</div>
	<div style="flex:1; width:100%; height:calc(100% - 60px); position:relative;">
		<iframe id="mediaPickerIframe" src="about:blank" style="width:100%; height:100%; border:none;" title="Media Asset Picker"></iframe>
	</div>
</div>

<!--- Embed Form Modal Overlay for Page Editor --->
<div class="admin-modal-backdrop" id="embedFormModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeEmbedFormModal()"></div>
<div class="admin-modal" id="embedFormModal" role="dialog" aria-modal="true" aria-labelledby="embedFormModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:94%; max-width:780px; max-height:86vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:flex-start; background:var(--admin-bg);">
		<div>
			<h2 class="modal-title" id="embedFormModalTitle" style="margin:0; font-size:1.1rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
				<cfoutput>#svgIcon(name="form", size=18)#</cfoutput>
				<span>Embed Online Form</span>
			</h2>
			<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.25rem;">
				Select an active online form from <cfoutput><strong id="embedFormWorkspaceName">#EncodeForHTML(editWsObj.name ?: (Len(page.siteId) ? page.siteId : 'General Administration'))#</strong></cfoutput> to embed into your page content.
			</div>
		</div>
		<button type="button" class="btn btn-ghost btn-sm" onclick="closeEmbedFormModal()" aria-label="Close Form Embed Modal" style="font-size:1.25rem; line-height:1; padding:0.25rem 0.5rem;">
			<cfoutput>#svgIcon(name="x", size=16)#</cfoutput>
		</button>
	</div>

	<div style="padding:0.85rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); background:var(--admin-surface); display:flex; gap:0.65rem; align-items:center;">
		<div style="position:relative; flex:1;">
			<input type="text" id="embedFormSearchInput" class="form-control form-control-sm" placeholder="Search forms by title, keyword, or slug..." style="width:100%; padding-left:1.85rem; font-size:0.85rem;">
			<span style="position:absolute; left:0.6rem; top:50%; transform:translateY(-50%); color:var(--admin-text-muted); pointer-events:none;">
				<cfoutput>#svgIcon(name="search", size=13)#</cfoutput>
			</span>
		</div>
		<cfoutput>
			<span id="embedFormAvailableCount" style="font-size:0.78rem; color:var(--admin-text-muted); white-space:nowrap;">
				#ArrayLen(availableForms)# form<cfif ArrayLen(availableForms) neq 1>s</cfif> available
			</span>
		</cfoutput>
	</div>

	<div id="embedFormListContainer" data-rendered-ws="<cfoutput>#EncodeForHTMLAttribute(editSiteId ?: (page.siteId ?: ''))#</cfoutput>" style="flex:1; overflow-y:auto; padding:1rem 1.25rem; max-height:calc(86vh - 180px); display:flex; flex-direction:column; gap:0.65rem;">
		<cfoutput>
		<cfloop array="#availableForms#" index="local.frm">
			<cfset local.fId = (local.frm.id ?: (local.frm.ID ?: 0))>
			<cfset local.fTitle = Len(Trim(local.frm.title ?: (local.frm.TITLE ?: ""))) ? (local.frm.title ?: local.frm.TITLE) : "Untitled Form">
			<cfset local.fSlug = (local.frm.slug ?: (local.frm.SLUG ?: ""))>
			<cfset local.fDesc = (local.frm.description ?: (local.frm.DESCRIPTION ?: ""))>
			<cfset local.fDeptName = Len(Trim(local.frm.deptName ?: (local.frm.DEPTNAME ?: (local.frm.dept_name ?: "")))) ? (local.frm.deptName ?: (local.frm.DEPTNAME ?: local.frm.dept_name)) : "General">
			<cfset local.fDeptBadge = Len(Trim(local.frm.deptBadge ?: (local.frm.DEPTBADGE ?: (local.frm.dept_badge ?: "")))) ? (local.frm.deptBadge ?: (local.frm.DEPTBADGE ?: local.frm.dept_badge)) : "badge-primary">
			<cfset local.fStatus = UCase(local.frm.status ?: (local.frm.STATUS ?: "published"))>
			<div class="embed-form-card" data-form-title="#EncodeForHTMLAttribute(local.fTitle)#" data-form-slug="#EncodeForHTMLAttribute(local.fSlug)#" data-form-dept="#EncodeForHTMLAttribute(local.fDeptName)#" style="border:1.5px solid var(--admin-border); border-radius:var(--radius-md); padding:0.85rem 1rem; background:var(--admin-surface); transition:all 0.15s ease; display:flex; justify-content:space-between; align-items:center; gap:1rem;">
				<div style="flex:1; min-width:0;">
					<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.25rem; flex-wrap:wrap;">
						<strong style="font-size:0.92rem; color:var(--admin-text-main);">#EncodeForHTML(local.fTitle)#</strong>
						<span class="badge #local.fDeptBadge#" style="font-size:0.68rem; padding:0.15rem 0.45rem;">#EncodeForHTML(local.fDeptName)#</span>
						<span class="badge badge-neutral" style="font-size:0.68rem; padding:0.15rem 0.45rem;">#local.fStatus#</span>
					</div>
					<cfif Len(Trim(local.fDesc))>
						<div style="font-size:0.8rem; color:var(--admin-text-muted); line-height:1.4; margin-bottom:0.35rem; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden;">#EncodeForHTML(local.fDesc)#</div>
					</cfif>
					<div style="font-size:0.75rem; color:var(--admin-text-muted); font-family:monospace;">
						Shortcode: [chelan_form slug="#local.fSlug#"]
					</div>
				</div>
				<div style="display:flex; flex-direction:column; gap:0.35rem; flex-shrink:0;">
					<button type="button" class="btn btn-primary btn-xs btn-insert-embed-iframe" data-id="#local.fId#" data-slug="#EncodeForHTMLAttribute(local.fSlug)#" data-title="#EncodeForHTMLAttribute(local.fTitle)#" title="Embed responsive form directly on page">
						#svgIcon(name="code", size=12)#
						<span>Embed Form</span>
					</button>
					<button type="button" class="btn btn-outline btn-xs btn-insert-embed-shortcode" data-slug="#EncodeForHTMLAttribute(local.fSlug)#" title="Insert [chelan_form] shortcode">
						#svgIcon(name="link", size=12)#
						<span>Insert Shortcode</span>
					</button>
				</div>
			</div>
		</cfloop>
		</cfoutput>

		<div id="embedFormEmptyState" style="<cfif ArrayLen(availableForms) gt 0>display:none;</cfif> text-align:center; padding:2.5rem 1rem; color:var(--admin-text-muted);">
			<div style="margin-bottom:0.5rem; color:var(--admin-text-muted);">
				<cfoutput>#svgIcon(name="form", size=36)#</cfoutput>
			</div>
			<h4 style="margin:0 0 0.25rem 0; font-size:1rem; color:var(--admin-text-main);">No Online Forms in Workspace</h4>
			<p style="margin:0 0 1rem 0; font-size:0.85rem;">There are no online forms attached to this workspace yet. You can create a new form in Form Builder.</p>
			<div style="display:flex; justify-content:center; gap:0.5rem;">
				<a href="/forms/builder" target="_blank" rel="noopener" class="btn btn-primary btn-sm">
					<cfoutput>#svgIcon(name="plus", size=13)#</cfoutput>
					<span>Create New Form</span>
				</a>
			</div>
		</div>
	</div>

	<div class="modal-footer" style="padding:0.75rem 1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
		<a href="/forms/builder" target="_blank" rel="noopener" class="btn btn-ghost btn-xs" style="color:var(--admin-primary); text-decoration:none;">
			<cfoutput>#svgIcon(name="plus-circle", size=14)#</cfoutput>
			<span>Open Form Builder in new tab</span>
		</a>
		<button type="button" class="btn btn-outline btn-sm" onclick="closeEmbedFormModal()">Close</button>
	</div>
</div>

<!--- Embed Call to Action Modal Overlay for Page Editor --->
<div class="admin-modal-backdrop" id="embedCtaModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeEmbedCtaModal()"></div>
<div class="admin-modal" id="embedCtaModal" role="dialog" aria-modal="true" aria-labelledby="embedCtaModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:94%; max-width:880px; max-height:88vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:flex-start; background:var(--admin-bg);">
		<div>
			<h2 class="modal-title" id="embedCtaModalTitle" style="margin:0; font-size:1.1rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
				<cfoutput>#svgIcon(name="cta", size=18)#</cfoutput>
				<span>Embed Call to Action Component</span>
			</h2>
			<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.25rem;">
				Embed responsive Call to Action cards or multi-card service grids into your page content.
			</div>
		</div>
		<button type="button" class="btn btn-ghost btn-sm" onclick="closeEmbedCtaModal()" aria-label="Close CTA Modal" style="font-size:1.25rem; line-height:1; padding:0.25rem 0.5rem;">
			<cfoutput>#svgIcon(name="x", size=16)#</cfoutput>
		</button>
	</div>

	<div style="padding:0.85rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); background:var(--admin-surface); display:flex; gap:0.65rem; align-items:center; flex-wrap:wrap;">
		<div style="position:relative; flex:1; min-width:240px;">
			<input type="text" id="embedCtaSearchInput" class="form-control form-control-sm" placeholder="Search CTAs by title, description, or slug..." style="width:100%; padding-left:1.85rem; font-size:0.85rem;">
			<span style="position:absolute; left:0.6rem; top:50%; transform:translateY(-50%); color:var(--admin-text-muted); pointer-events:none;">
				<cfoutput>#svgIcon(name="search", size=13)#</cfoutput>
			</span>
		</div>
		<div style="display:flex; align-items:center; gap:0.4rem;">
			<button type="button" class="btn btn-outline btn-xs" id="btnSelectAllCtaModal">Select All</button>
			<button type="button" class="btn btn-outline btn-xs" id="btnClearAllCtaModal">Clear All</button>
			<span id="embedCtaAvailableCount" style="font-size:0.78rem; color:var(--admin-text-muted); white-space:nowrap; margin-left:0.5rem;">
				<cfoutput>#ArrayLen(availableCtas)# card<cfif ArrayLen(availableCtas) neq 1>s</cfif> available</cfoutput>
			</span>
		</div>
	</div>

	<div id="embedCtaListContainer" style="flex:1; overflow-y:auto; padding:1.25rem; max-height:calc(88vh - 200px); display:grid; grid-template-columns:repeat(auto-fit, minmax(260px, 1fr)); gap:1rem;">
		<cfoutput>
		<cfloop array="#availableCtas#" index="local.cta">
			<div class="embed-cta-card-item" data-id="#local.cta.id#" data-slug="#EncodeForHTMLAttribute(local.cta.slug)#" data-title="#EncodeForHTMLAttribute(local.cta.title)#" data-category="#EncodeForHTMLAttribute(local.cta.category)#" data-link-url="#EncodeForHTMLAttribute(local.cta.linkUrl ?: '')#" data-link-icon="#EncodeForHTMLAttribute(local.cta.linkIcon ?: 'arrow')#" data-target-blank="#(StructKeyExists(local.cta, 'targetBlank') && local.cta.targetBlank ? '1' : '0')#" style="border:1.5px solid var(--admin-border); border-radius:8px; background:var(--admin-surface); display:flex; flex-direction:column; overflow:hidden; position:relative; cursor:pointer; transition:border-color 0.15s ease, box-shadow 0.15s ease;">
				<div style="position:absolute; top:0.5rem; left:0.5rem; z-index:3; background:rgba(255,255,255,0.92); border-radius:4px; padding:0.2rem 0.35rem; display:flex; align-items:center; box-shadow:0 1px 3px rgba(0,0,0,0.15);">
					<input type="checkbox" class="embed-cta-checkbox" value="#local.cta.slug#" style="accent-color:var(--admin-primary); width:15px; height:15px; cursor:pointer;" title="Select for Multi-Card Grid">
				</div>
				<cfif Len(local.cta.imageUrl)>
					<div style="width:100%; height:130px; overflow:hidden; background:##f1f5f9; position:relative;">
						<img src="#local.cta.imageUrl#" alt="#EncodeForHTMLAttribute(local.cta.imageAlt)#" style="width:100%; height:100%; object-fit:cover; display:block;" loading="lazy">
					</div>
				</cfif>
				<div style="padding:0.85rem; display:flex; flex-direction:column; flex:1;">
					<cfif Len(local.cta.badgeText)>
						<span class="jbd-cta-badge" style="font-size:0.65rem; padding:0.1rem 0.4rem; align-self:flex-start; margin-bottom:0.35rem;">#EncodeForHTML(local.cta.badgeText)#</span>
					</cfif>
					<strong style="font-size:0.95rem; color:var(--admin-text-main); margin-bottom:0.25rem; line-height:1.3;">#EncodeForHTML(local.cta.title)#</strong>
					<p style="font-size:0.78rem; color:var(--admin-text-muted); line-height:1.45; margin:0 0 0.75rem; flex:1; display:-webkit-box; -webkit-line-clamp:3; -webkit-box-orient:vertical; overflow:hidden;">#EncodeForHTML(local.cta.description)#</p>
					<div class="embed-cta-link-preview" style="font-size:0.75rem; color:var(--admin-primary); font-weight:700; display:flex; align-items:center; gap:0.35rem;">
						<span>#EncodeForHTML(local.cta.linkText)#</span>
						<cfif local.cta.linkIcon eq "external"><svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg><cfelseif local.cta.linkIcon eq "pdf"><span class="jbd-cta-pdf-badge">PDF</span><cfelseif local.cta.linkIcon neq "none"><svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg></cfif>
					</div>
				</div>
			</div>
		</cfloop>
		</cfoutput>
	</div>

	<div class="modal-footer" style="padding:0.75rem 1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg); flex-wrap:wrap; gap:0.5rem;">
		<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
			<div style="display:flex; align-items:center; gap:0.35rem; margin-right:0.35rem;">
				<label for="embedCtaLayoutSelect" style="font-size:0.78rem; font-weight:600; color:var(--admin-text-muted); margin:0;">Layout:</label>
				<select id="embedCtaLayoutSelect" class="form-select form-select-sm" style="font-size:0.8rem; padding:0.25rem 0.5rem; height:auto; width:auto; min-width:180px;">
					<option value="3" selected>3 Columns (3 Col / 3x1 Grid)</option>
					<option value="4">4 Columns (4 Col Grid)</option>
					<option value="2">2 Columns (2x2 / 50-50 Split)</option>
				</select>
			</div>
			<button type="button" class="btn btn-primary btn-sm" id="btnEmbedSelectedCtaGrid">
				<cfoutput>#svgIcon(name="grid", size=14)#</cfoutput>
				<span>Embed Selected Cards as Grid</span>
			</button>
			<button type="button" class="btn btn-outline btn-sm" id="btnInsertSelectedCtaShortcodes">
				<cfoutput>#svgIcon(name="link", size=14)#</cfoutput>
				<span>Insert Grid Shortcode</span>
			</button>
		</div>
		<div style="display:flex; align-items:center; gap:0.5rem;">
			<a href="/pages/call-to-action" target="_blank" rel="noopener" class="btn btn-ghost btn-xs" style="color:var(--admin-primary); text-decoration:none;">
				<cfoutput>#svgIcon(name="external-link", size=13)#</cfoutput>
				<span>Open CTA Studio</span>
			</a>
			<button type="button" class="btn btn-outline btn-sm" onclick="closeEmbedCtaModal()">Close</button>
		</div>
	</div>
</div>

<!--- =========================================================================
      Feature 2.2: Page Revision History & Rollback Studio Modal (RCW 42.56)
      ========================================================================= --->
<div id="pgRevisionsModalBackdrop" style="display:none;" onclick="closeRevisionsModal()" aria-hidden="true"></div>
<div id="pgRevisionsModal" role="dialog" aria-modal="true" aria-labelledby="revisionsModalTitle" style="display:none;">
	<div class="modal-header" style="padding:0.9rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
		<div style="display:flex; align-items:center; gap:0.65rem;">
			<div style="width:34px; height:34px; border-radius:var(--radius-md); background:var(--admin-primary); color:#ffffff; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
				<cfoutput>#svgIcon(name="clock", size=18)#</cfoutput>
			</div>
			<div>
				<h2 id="revisionsModalTitle" style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
					<span>Revision History &amp; Rollback Studio</span>
					<span class="badge badge-primary" style="font-size:0.68rem; font-weight:700; padding:0.15rem 0.45rem;">RCW 42.56</span>
				</h2>
				<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:2px;">
					Public records audit trail of snapshot drafts &amp; published versions. Compare visual differences or restore any prior state.
				</div>
			</div>
		</div>
		<div style="display:flex; align-items:center; gap:0.5rem;">
			<button type="button" class="btn btn-outline btn-sm" id="btnManualSnapshot" title="Record an immediate snapshot of current editor state" onclick="createManualSnapshot()">
				<cfoutput>#svgIcon(name="plus", size=14)#</cfoutput>
				<span>Snapshot Now</span>
			</button>
			<button type="button" class="btn btn-ghost btn-sm" onclick="closeRevisionsModal()" aria-label="Close Revisions Studio" style="font-size:1.25rem; line-height:1; padding:0.25rem 0.5rem;">
				<cfoutput>#svgIcon(name="x", size=16)#</cfoutput>
			</button>
		</div>
	</div>

	<div class="rev-layout">
		<!--- Left Column: Timeline List --->
		<div class="rev-sidebar">
			<div class="rev-sidebar-header">
				<span style="font-size:0.8rem; font-weight:700; text-transform:uppercase; letter-spacing:0.04em; color:var(--admin-text-muted);">
					Snapshots (<span id="revTimelineCount">0</span>)
				</span>
				<span style="font-size:0.72rem; color:var(--admin-text-muted);" title="Most recent version first">Newest &darr;</span>
			</div>
			<div id="revisionsTimelineList" class="rev-list" role="tablist" aria-orientation="vertical">
				<div style="text-align:center; padding:2.5rem 1rem; color:var(--admin-text-muted); font-size:0.85rem;">
					Loading revision snapshots...
				</div>
			</div>
		</div>

		<!--- Right Column: Comparison & Diff Stage --->
		<div class="rev-stage">
			<div class="rev-stage-toolbar">
				<div style="display:flex; align-items:center; gap:0.65rem; flex-wrap:wrap;">
					<strong id="revSelectedTitle" style="font-size:0.92rem; color:var(--admin-text-main);">Select a snapshot to compare</strong>
					<div id="revDiffStats" style="display:flex; align-items:center; gap:0.35rem;"></div>
				</div>

				<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
					<!--- View Mode Selector --->
					<div class="pg-attr-tabs" role="tablist" aria-label="Revision Diff View Mode">
						<button type="button" class="pg-attr-tab is-active" id="revModeVisual" data-mode="visual" onclick="setDiffViewMode('visual')">Visual Diff</button>
						<button type="button" class="pg-attr-tab" id="revModeSplit" data-mode="split" onclick="setDiffViewMode('split')">Side-by-Side</button>
						<button type="button" class="pg-attr-tab" id="revModePreview" data-mode="preview" onclick="setDiffViewMode('preview')">Snapshot Preview</button>
						<button type="button" class="pg-attr-tab" id="revModeRaw" data-mode="raw" onclick="setDiffViewMode('raw')">HTML Code</button>
					</div>

					<!--- Restore / Rollback Action Button --->
					<button type="button" class="btn btn-warning btn-sm" id="btnRestoreRevision" onclick="confirmRollbackRevision()" style="font-weight:700; display:flex; align-items:center; gap:0.35rem;" disabled>
						<cfoutput>#svgIcon(name="refresh-cw", size=14)#</cfoutput>
						<span>Restore this Version</span>
					</button>
				</div>
			</div>

			<div class="rev-stage-body" id="revStageContainer">
				<div class="diff-pane" id="revDiffViewer">
					<div style="text-align:center; padding:3rem 1rem; color:var(--admin-text-muted);">
						Select a snapshot from the timeline on the left to review changes against your current working draft.
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

<!--- =========================================================================
   Feature 2.6: Document to WCAG AA Converter Studio Modal & Drop Integration
   ========================================================================= --->
<div class="admin-modal-backdrop" id="pgDocConvertModalBackdrop" style="display:none;" onclick="closeDocConvertModal()"></div>
<div class="admin-modal" id="pgDocConvertModal" role="dialog" aria-modal="true" aria-labelledby="docConvertModalTitle" style="display:none;">
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:flex-start; background:var(--admin-bg);">
		<div>
			<h2 class="modal-title" id="docConvertModalTitle" style="margin:0; font-size:1.15rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
				<cfoutput>#svgIcon(name="file-text", size=18)#</cfoutput>
				<span>Document to WCAG AA Converter Studio</span>
			</h2>
			<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.25rem;">
				Automatically extract headings, tables, lists, and images from Word (.docx) or PDF (.pdf) into accessible HTML.
			</div>
		</div>
		<button type="button" class="btn btn-ghost btn-xs btn-icon-only" onclick="closeDocConvertModal()" aria-label="Close dialog">
			<cfoutput>#svgIcon(name="x", size=16)#</cfoutput>
		</button>
	</div>

	<div class="modal-body" style="padding:1.25rem; overflow-y:auto; flex:1; max-height:calc(88vh - 140px); display:flex; flex-direction:column; gap:1.25rem;">
		<!--- Upload / Dropzone Card --->
		<div id="docConvertUploadArea">
			<div class="doc-dropzone-box" id="docModalDropzone" onclick="document.getElementById('pgDocFileInput').click();">
				<div style="width:48px; height:48px; border-radius:50%; background:rgba(2, 132, 199, 0.1); color:var(--admin-primary); margin:0 auto 0.75rem auto; display:flex; align-items:center; justify-content:center;">
					<cfoutput>#svgIcon(name="upload", size=24)#</cfoutput>
				</div>
				<strong style="display:block; font-size:1rem; color:var(--admin-text-main); margin-bottom:0.25rem;">Choose a Document or Drag &amp; Drop Here</strong>
				<span style="display:block; font-size:0.82rem; color:var(--admin-text-muted); margin-bottom:0.85rem;">
					Supports <strong>Microsoft Word (.docx)</strong> and <strong>Adobe PDF (.pdf)</strong> up to 35 MB
				</span>
				<div style="display:flex; justify-content:center; gap:0.5rem;">
					<span class="badge badge-primary" style="font-size:0.72rem; letter-spacing:0.04em;">.DOCX (Word 2007+)</span>
					<span class="badge badge-info" style="font-size:0.72rem; letter-spacing:0.04em;">.PDF (Adobe PDF)</span>
				</div>
				<input type="file" id="pgDocFileInput" accept=".docx,.pdf,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document" style="display:none;" onchange="handleDocFileSelected(this.files)">
			</div>

			<!--- Selected File Info Pill (Initially Hidden) --->
			<div id="docSelectedFileInfo" style="display:none; margin-top:0.75rem; padding:0.75rem 1rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); align-items:center; justify-content:space-between; gap:1rem;">
				<div style="display:flex; align-items:center; gap:0.65rem; min-width:0; flex:1;">
					<span style="color:var(--admin-primary); display:flex; align-items:center;"><cfoutput>#svgIcon(name="file-text", size=20)#</cfoutput></span>
					<div style="min-width:0; flex:1;">
						<strong id="docSelectedFileName" style="display:block; font-size:0.88rem; color:var(--admin-text-main); overflow:hidden; text-overflow:ellipsis; white-space:nowrap;"></strong>
						<span id="docSelectedFileSize" style="font-size:0.75rem; color:var(--admin-text-muted);"></span>
					</div>
				</div>
				<button type="button" class="btn btn-outline btn-xs" onclick="resetDocSelection()">Change File</button>
			</div>
		</div>

		<!--- Import Options Card --->
		<div class="card" id="docImportOptionsCard" style="padding:1rem 1.1rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-surface);">
			<strong style="font-size:0.85rem; color:var(--admin-text-main); display:block; margin-bottom:0.75rem; text-transform:uppercase; letter-spacing:0.04em;">
				Import &amp; Accessibility Options
			</strong>
			<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(240px, 1fr)); gap:1rem;">
				<div>
					<label class="form-label" style="font-size:0.8rem; font-weight:600; margin-bottom:0.35rem;">Destination Mode</label>
					<div style="display:flex; flex-direction:column; gap:0.35rem; font-size:0.82rem;">
						<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer;">
							<input type="radio" name="docDestMode" value="replace" checked style="accent-color:var(--admin-primary);">
							<span><strong>Replace Page Content</strong> (Recommended)</span>
						</label>
						<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer;">
							<input type="radio" name="docDestMode" value="append" style="accent-color:var(--admin-primary);">
							<span>Append to bottom of existing content</span>
						</label>
						<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer;">
							<input type="radio" name="docDestMode" value="insert" style="accent-color:var(--admin-primary);">
							<span>Insert at current cursor position</span>
						</label>
					</div>
				</div>
				<div>
					<label class="form-label" style="font-size:0.8rem; font-weight:600; margin-bottom:0.35rem;">Metadata &amp; Media</label>
					<div style="display:flex; flex-direction:column; gap:0.35rem; font-size:0.82rem;">
						<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer;">
							<input type="checkbox" id="docOptAutoTitle" checked style="accent-color:var(--admin-primary);">
							<span>Update Page Title if Heading 1 / Title found</span>
						</label>
						<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer;">
							<input type="checkbox" id="docOptAutoSummary" checked style="accent-color:var(--admin-primary);">
							<span>Update Summary from introductory text</span>
						</label>
						<label style="display:flex; align-items:center; gap:0.45rem; cursor:pointer;">
							<input type="checkbox" id="docOptExtractImages" checked style="accent-color:var(--admin-primary);">
							<span>Extract &amp; save photos/charts to Media Library</span>
						</label>
					</div>
				</div>
			</div>
		</div>

		<!--- Conversion Progress Stepper (Initially Hidden) --->
		<div id="docConvertProgress" style="display:none; padding:1.75rem 1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg); text-align:center;">
			<div style="width:40px; height:40px; border-radius:50%; border:3px solid var(--admin-border); border-top-color:var(--admin-primary); margin:0 auto 0.75rem auto; animation:spin 0.8s linear infinite;"></div>
			<strong id="docProgressStepMsg" style="display:block; font-size:0.95rem; color:var(--admin-text-main); margin-bottom:0.25rem;">Extracting and converting document...</strong>
			<span style="font-size:0.8rem; color:var(--admin-text-muted);">Adobe ColdFusion 2025 is parsing structure, images, and generating WCAG AA HTML.</span>
		</div>

		<!--- Results & Preview Container (Initially Hidden) --->
		<div id="docConvertResults" style="display:none; flex-direction:column; gap:1rem;">
			<!--- KPI Row --->
			<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(110px, 1fr)); gap:0.6rem;">
				<div class="doc-kpi-card">
					<div class="doc-kpi-value" id="kpiDocWords">0</div>
					<div class="doc-kpi-label">Words</div>
				</div>
				<div class="doc-kpi-card">
					<div class="doc-kpi-value" id="kpiDocHeadings">0</div>
					<div class="doc-kpi-label">Headings</div>
				</div>
				<div class="doc-kpi-card">
					<div class="doc-kpi-value" id="kpiDocParagraphs">0</div>
					<div class="doc-kpi-label">Paragraphs</div>
				</div>
				<div class="doc-kpi-card">
					<div class="doc-kpi-value" id="kpiDocLists">0</div>
					<div class="doc-kpi-label">Lists</div>
				</div>
				<div class="doc-kpi-card">
					<div class="doc-kpi-value" id="kpiDocTables">0</div>
					<div class="doc-kpi-label">Tables</div>
				</div>
				<div class="doc-kpi-card">
					<div class="doc-kpi-value" id="kpiDocImages">0</div>
					<div class="doc-kpi-label">Images</div>
				</div>
			</div>

			<!--- WCAG Compliance Highlights Callout --->
			<div style="padding:0.75rem 1rem; border-radius:var(--radius-md); background:rgba(34, 197, 94, 0.08); border:1.5px solid rgba(34, 197, 94, 0.3); color:##166534; font-size:0.82rem; line-height:1.45;">
				<div style="display:flex; align-items:center; gap:0.4rem; font-weight:700; margin-bottom:0.25rem;">
					<cfoutput>#svgIcon(name="check-circle", size=15)#</cfoutput>
					<span>WCAG 2.1 AA Compliance Guarantees Applied</span>
				</div>
				<ul id="docWcagHighlightsList" style="margin:0.25rem 0 0; padding-left:1.25rem; font-size:0.8rem;"></ul>
			</div>

			<!--- Preview Area --->
			<div style="border:1px solid var(--admin-border); border-radius:var(--radius-md); overflow:hidden; background:var(--admin-surface);">
				<div style="padding:0.5rem 0.85rem; border-bottom:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
					<span style="font-size:0.8rem; font-weight:700; color:var(--admin-text-main);">Converted HTML Output</span>
					<div class="pg-attr-tabs" role="tablist">
						<button type="button" class="pg-attr-tab is-active" id="docTabVisual" onclick="setDocPreviewTab('visual')">Visual Preview</button>
						<button type="button" class="pg-attr-tab" id="docTabCode" onclick="setDocPreviewTab('code')">HTML Source</button>
					</div>
				</div>
				<div id="docPreviewVisual" style="padding:1.25rem; max-height:280px; overflow-y:auto; line-height:1.6; font-size:0.92rem; background:##ffffff;"></div>
				<pre id="docPreviewCode" style="display:none; margin:0; padding:1.25rem; max-height:280px; overflow-y:auto; font-family:ui-monospace, monospace; font-size:0.8rem; background:var(--admin-bg); color:var(--admin-text-main); white-space:pre-wrap; word-break:break-all;"></pre>
			</div>
		</div>
	</div>

	<div class="modal-footer" style="padding:0.85rem 1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg);">
		<div style="display:flex; gap:0.5rem;">
			<button type="button" class="btn btn-outline btn-sm" onclick="closeDocConvertModal()">Cancel</button>
			<button type="button" class="btn btn-ghost btn-sm" id="btnDocConvertReset" style="display:none;" onclick="resetDocSelection()">Convert Another Document</button>
		</div>
		<div style="display:flex; gap:0.5rem;">
			<button type="button" class="btn btn-primary btn-sm" id="btnDocConvertStart" onclick="startDocumentConversion()" disabled>
				<cfoutput>#svgIcon(name="refresh-cw", size=14)#</cfoutput>
				<span>Convert Document</span>
			</button>
			<button type="button" class="btn btn-success btn-sm" id="btnDocConvertPaste" style="display:none; font-weight:700;" onclick="pasteDocToEditor()">
				<cfoutput>#svgIcon(name="check", size=14)#</cfoutput>
				<span>Paste to Page Content</span>
			</button>
		</div>
	</div>
</div>

<script>
(function() {
	var _selectedDocFile = null;
	var _lastConvertedData = null;
	var _dragCounter = 0;

	// Elements
	var modal = document.getElementById("pgDocConvertModal");
	var backdrop = document.getElementById("pgDocConvertModalBackdrop");
	var overlay = document.getElementById("pgDocDropOverlay");
	var editorContainer = document.getElementById("pgEditorDropContainer");
	var btnTrigger = document.getElementById("btnEditorImportDoc");

	if (btnTrigger) {
		btnTrigger.addEventListener("click", function(e) {
			if (e) e.preventDefault();
			openDocConvertModal();
		});
	}

	// ----------------------------------------------------
	// Drag and Drop Listeners for Page Content Area & Window
	// ----------------------------------------------------
	if (editorContainer && overlay) {
		window.addEventListener("dragenter", function(e) {
			_dragCounter++;
			if (hasDocFiles(e.dataTransfer)) {
				overlay.style.display = "flex";
				overlay.classList.add("is-active");
			}
		});

		window.addEventListener("dragleave", function(e) {
			_dragCounter--;
			if (_dragCounter <= 0) {
				_dragCounter = 0;
				overlay.style.display = "none";
				overlay.classList.remove("is-active");
			}
		});

		window.addEventListener("dragover", function(e) {
			if (hasDocFiles(e.dataTransfer)) {
				e.preventDefault();
				overlay.style.display = "flex";
				overlay.classList.add("is-active");
			}
		});

		window.addEventListener("drop", function(e) {
			_dragCounter = 0;
			overlay.style.display = "none";
			overlay.classList.remove("is-active");

			if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) {
				var file = e.dataTransfer.files[0];
				var name = file.name || "";
				var ext = name.split(".").pop().toLowerCase();
				if (ext === "docx" || ext === "pdf") {
					e.preventDefault();
					openDocConvertModal(file);
				}
			}
		});
	}

	function hasDocFiles(dt) {
		if (!dt || !dt.types) return false;
		for (var i = 0; i < dt.types.length; i++) {
			if (dt.types[i] === "Files") return true;
		}
		return false;
	}

	// ----------------------------------------------------
	// Modal Controls
	// ----------------------------------------------------
	window.openDocConvertModal = function(file) {
		if (modal && backdrop) {
			backdrop.style.display = "block";
			modal.style.display = "flex";
			document.body.style.overflow = "hidden";
			if (file) {
				handleDocFileSelected([file]);
				// Auto-start conversion on drag-drop
				setTimeout(startDocumentConversion, 120);
			}
		}
	};

	window.closeDocConvertModal = function() {
		if (modal && backdrop) {
			modal.style.display = "none";
			backdrop.style.display = "none";
			document.body.style.overflow = "";
		}
	};

	window.handleDocFileSelected = function(files) {
		if (!files || files.length === 0) return;
		var file = files[0];
		var ext = (file.name || "").split(".").pop().toLowerCase();
		if (ext !== "docx" && ext !== "pdf") {
			if (window.adminAlert) {
				window.adminAlert("Please select a Microsoft Word (.docx) or Adobe PDF (.pdf) file.", "Unsupported Format");
			} else {
				alert("Please select a .docx or .pdf file.");
			}
			return;
		}

		_selectedDocFile = file;
		var infoEl = document.getElementById("docSelectedFileInfo");
		var nameEl = document.getElementById("docSelectedFileName");
		var sizeEl = document.getElementById("docSelectedFileSize");
		var startBtn = document.getElementById("btnDocConvertStart");

		if (nameEl) nameEl.textContent = file.name;
		if (sizeEl) {
			var sizeKB = Math.round(file.size / 1024);
			var sizeStr = sizeKB > 1024 ? (Math.round(sizeKB / 102.4) / 10 + " MB") : (sizeKB + " KB");
			sizeEl.textContent = sizeStr + " • " + ext.toUpperCase() + " Document";
		}
		if (infoEl) infoEl.style.display = "flex";
		if (startBtn) startBtn.disabled = false;
	};

	window.resetDocSelection = function() {
		_selectedDocFile = null;
		_lastConvertedData = null;
		var input = document.getElementById("pgDocFileInput");
		if (input) input.value = "";
		var infoEl = document.getElementById("docSelectedFileInfo");
		if (infoEl) infoEl.style.display = "none";

		var startBtn = document.getElementById("btnDocConvertStart");
		if (startBtn) {
			startBtn.style.display = "inline-flex";
			startBtn.disabled = true;
		}
		var pasteBtn = document.getElementById("btnDocConvertPaste");
		if (pasteBtn) pasteBtn.style.display = "none";
		var resetBtn = document.getElementById("btnDocConvertReset");
		if (resetBtn) resetBtn.style.display = "none";

		var uploadArea = document.getElementById("docConvertUploadArea");
		if (uploadArea) uploadArea.style.display = "block";
		var optionsCard = document.getElementById("docImportOptionsCard");
		if (optionsCard) optionsCard.style.display = "block";
		var progressCard = document.getElementById("docConvertProgress");
		if (progressCard) progressCard.style.display = "none";
		var resultsCard = document.getElementById("docConvertResults");
		if (resultsCard) resultsCard.style.display = "none";
	};

	window.startDocumentConversion = function() {
		if (!_selectedDocFile) return;

		var uploadArea = document.getElementById("docConvertUploadArea");
		var optionsCard = document.getElementById("docImportOptionsCard");
		var progressCard = document.getElementById("docConvertProgress");
		var resultsCard = document.getElementById("docConvertResults");
		var startBtn = document.getElementById("btnDocConvertStart");
		var pasteBtn = document.getElementById("btnDocConvertPaste");
		var resetBtn = document.getElementById("btnDocConvertReset");

		if (uploadArea) uploadArea.style.display = "none";
		if (optionsCard) optionsCard.style.display = "none";
		if (progressCard) progressCard.style.display = "block";
		if (resultsCard) resultsCard.style.display = "none";
		if (startBtn) startBtn.style.display = "none";

		var formData = new FormData();
		formData.append("documentFile", _selectedDocFile);
		
		// Active workspace
		var ws = "";
		var wsPill = document.querySelector("[data-workspace-slug]");
		if (wsPill) ws = wsPill.getAttribute("data-workspace-slug");
		if (!ws) ws = "shared";
		formData.append("workspace", ws);

		fetch("/pages/convert-document", {
			method: "POST",
			headers: {
				"X-Requested-With": "XMLHttpRequest"
			},
			body: formData
		})
		.then(function(res) {
			if (!res.ok) throw new Error("Server responded with HTTP " + res.status);
			return res.json();
		})
		.then(function(json) {
			if (progressCard) progressCard.style.display = "none";

			if (json.success && json.data) {
				_lastConvertedData = json.data;
				renderDocResults(json.data);
				if (resultsCard) resultsCard.style.display = "flex";
				if (pasteBtn) pasteBtn.style.display = "inline-flex";
				if (resetBtn) resetBtn.style.display = "inline-flex";
				if (window.showToast) {
					window.showToast("Document converted successfully to WCAG AA HTML!", "success");
				}
			} else {
				if (uploadArea) uploadArea.style.display = "block";
				if (optionsCard) optionsCard.style.display = "block";
				if (startBtn) {
					startBtn.style.display = "inline-flex";
					startBtn.disabled = false;
				}
				var msg = json.message || "An error occurred during document conversion.";
				if (window.adminAlert) {
					window.adminAlert(msg, "Conversion Notice");
				} else {
					alert(msg);
				}
			}
		})
		.catch(function(err) {
			if (progressCard) progressCard.style.display = "none";
			if (uploadArea) uploadArea.style.display = "block";
			if (optionsCard) optionsCard.style.display = "block";
			if (startBtn) {
				startBtn.style.display = "inline-flex";
				startBtn.disabled = false;
			}
			var errMsg = "Failed to communicate with document converter service: " + (err.message || err);
			if (window.adminAlert) {
				window.adminAlert(errMsg, "Conversion Failure");
			} else {
				alert(errMsg);
			}
		});
	};

	function renderDocResults(data) {
		var stats = data.stats || {};
		var kpiWords = document.getElementById("kpiDocWords");
		var kpiHeadings = document.getElementById("kpiDocHeadings");
		var kpiParas = document.getElementById("kpiDocParagraphs");
		var kpiLists = document.getElementById("kpiDocLists");
		var kpiTables = document.getElementById("kpiDocTables");
		var kpiImages = document.getElementById("kpiDocImages");

		if (kpiWords) kpiWords.textContent = stats.wordCount || 0;
		if (kpiHeadings) kpiHeadings.textContent = stats.headingsCount || 0;
		if (kpiParas) kpiParas.textContent = stats.paragraphsCount || 0;
		if (kpiLists) kpiLists.textContent = stats.listsCount || 0;
		if (kpiTables) kpiTables.textContent = stats.tablesCount || 0;
		if (kpiImages) kpiImages.textContent = stats.imagesCount || (data.images ? data.images.length : 0);

		// WCAG Highlights
		var hlList = document.getElementById("docWcagHighlightsList");
		if (hlList) {
			hlList.innerHTML = "";
			var hls = data.wcagHighlights || [];
			if (hls.length === 0) {
				hls.push("WCAG 1.3.1: Clean semantic markup generated.");
			}
			hls.forEach(function(item) {
				var li = document.createElement("li");
				li.textContent = item;
				hlList.appendChild(li);
			});
		}

		// Previews
		var visPreview = document.getElementById("docPreviewVisual");
		var codePreview = document.getElementById("docPreviewCode");
		if (visPreview) visPreview.innerHTML = data.html || "<p class='text-muted'>No text content extracted.</p>";
		if (codePreview) codePreview.textContent = data.html || "";
		setDocPreviewTab("visual");
	}

	window.setDocPreviewTab = function(mode) {
		var tabVis = document.getElementById("docTabVisual");
		var tabCode = document.getElementById("docTabCode");
		var paneVis = document.getElementById("docPreviewVisual");
		var paneCode = document.getElementById("docPreviewCode");

		if (mode === "visual") {
			if (tabVis) tabVis.classList.add("is-active");
			if (tabCode) tabCode.classList.remove("is-active");
			if (paneVis) paneVis.style.display = "block";
			if (paneCode) paneCode.style.display = "none";
		} else {
			if (tabCode) tabCode.classList.add("is-active");
			if (tabVis) tabVis.classList.remove("is-active");
			if (paneCode) paneCode.style.display = "block";
			if (paneVis) paneVis.style.display = "none";
		}
	};

	// ----------------------------------------------------
	// Paste to Page Content & Synchronize
	// ----------------------------------------------------
	window.pasteDocToEditor = function() {
		if (!_lastConvertedData || !_lastConvertedData.html) return;

		var modeRadio = document.querySelector("input[name='docDestMode']:checked");
		var mode = modeRadio ? modeRadio.value : "replace";

		var htmlToInsert = _lastConvertedData.html;
		var ed = (typeof JBDEditor !== "undefined") ? JBDEditor.get("#pgContent") : null;
		var ta = document.getElementById("pgContent");

		if (mode === "replace") {
			if (ed && typeof ed.setHTML === "function") {
				ed.setHTML(htmlToInsert);
				if (typeof ed.syncToTarget === "function") ed.syncToTarget();
			} else if (ta) {
				ta.value = htmlToInsert;
			}
		} else if (mode === "append") {
			var currentHtml = "";
			if (ed && typeof ed.getHTML === "function") {
				currentHtml = ed.getHTML();
			} else if (ta) {
				currentHtml = ta.value;
			}
			var combined = currentHtml.trim() ? (currentHtml + "\n\n" + htmlToInsert) : htmlToInsert;
			if (ed && typeof ed.setHTML === "function") {
				ed.setHTML(combined);
				if (typeof ed.syncToTarget === "function") ed.syncToTarget();
			} else if (ta) {
				ta.value = combined;
			}
		} else if (mode === "insert") {
			if (typeof insertSnippetAtCursor === "function") {
				insertSnippetAtCursor("pgContent", htmlToInsert);
			} else if (ed && typeof ed.insertHTML === "function") {
				ed.insertHTML(htmlToInsert);
			} else if (ta) {
				ta.value += "\n" + htmlToInsert;
			}
		}

		// Auto-populate Title if requested
		var optTitle = document.getElementById("docOptAutoTitle");
		if (optTitle && optTitle.checked && _lastConvertedData.title) {
			var titleInput = document.getElementById("pgTitle");
			if (titleInput && (!titleInput.value.trim() || mode === "replace")) {
				titleInput.value = _lastConvertedData.title;
				titleInput.dispatchEvent(new Event("input"));
			}
		}

		// Auto-populate Summary if requested
		var optSummary = document.getElementById("docOptAutoSummary");
		if (optSummary && optSummary.checked && _lastConvertedData.summary) {
			var summaryInput = document.getElementById("pgSummary");
			var metaDescInput = document.getElementById("pgMetaDesc");
			if (summaryInput && (!summaryInput.value.trim() || mode === "replace")) {
				summaryInput.value = _lastConvertedData.summary;
				summaryInput.dispatchEvent(new Event("input"));
			}
			if (metaDescInput && (!metaDescInput.value.trim() || mode === "replace")) {
				metaDescInput.value = _lastConvertedData.summary.substring(0, 160);
				metaDescInput.dispatchEvent(new Event("input"));
			}
		}

		// Re-trigger In-Editor ADA Pre-Flight Linter immediately
		setTimeout(function() {
			if (window.PageA11yLinter && typeof window.PageA11yLinter.scan === "function") {
				window.PageA11yLinter.scan();
			}
		}, 150);

		if (window.showToast) {
			window.showToast("Document converted and pasted into Page Content with WCAG AA compliance!", "success");
		}

		closeDocConvertModal();
	};

})();
</script>

