<cfparam name="article" default="#{}#">
<cfparam name="isNew" default="true">
<cfparam name="categories" default="#[]#">
<cfparam name="availableTags" default="#[]#">
<cfparam name="accessibleWorkspaces" default="#[]#">
<cfparam name="activeWorkspaceId" default="global">
<cfparam name="activeWsObj" default="#{}#">

<style>
	/* ADA WCAG 2.1 AA Pre-Flight Linter Bar & Diagnostics */
	.pg-a11y-linter-bar {
		background: var(--admin-surface, #ffffff);
		border: 1.5px solid var(--admin-border, #cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		overflow: hidden;
		transition: all 0.2s ease;
	}
	.pg-a11y-linter-bar.is-passed {
		border-color: var(--admin-border, #cbd5e1);
		background: var(--admin-surface, #ffffff);
	}
	.pg-a11y-linter-bar.has-warnings {
		border-color: #f59e0b;
		background: #fffdfa;
	}
	.pg-a11y-linter-bar.has-errors {
		border-color: #ef4444;
		background: #fef8f8;
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
		color: var(--admin-primary, #0284c7);
		display: inline-flex;
	}
	.pg-a11y-bar-title {
		font-size: 0.84rem;
		font-weight: 700;
		color: var(--admin-text-main, #0f172a);
		letter-spacing: -0.01em;
	}
	.pg-a11y-standard-badge {
		font-size: 0.68rem;
		font-weight: 700;
		padding: 0.1rem 0.35rem;
		border-radius: 3px;
		background: var(--admin-bg, #f1f5f9);
		color: var(--admin-text-muted, #475569);
		border: 1px solid var(--admin-border-subtle, #e2e8f0);
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
		background: var(--admin-bg, #f8fafc);
		border: 1px solid var(--admin-border-subtle, #e2e8f0);
		color: var(--admin-text-muted, #64748b);
		cursor: pointer;
		transition: all 0.15s ease;
	}
	.pg-a11y-chip:hover {
		background: var(--admin-surface, #ffffff);
		border-color: var(--admin-border-hover, #94a3b8);
		color: var(--admin-text-main, #0f172a);
	}
	.pg-a11y-chip.is-active-filter {
		background: rgba(2, 132, 199, 0.1);
		border-color: var(--admin-primary, #0284c7);
		color: var(--admin-primary, #0284c7);
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
		background: #e2e8f0;
		color: #475569;
		font-weight: 700;
	}
	.pg-a11y-chip.has-error {
		border-color: #fca5a5;
		background: #fef2f2;
		color: #b91c1c;
	}
	.pg-a11y-chip.has-error .chip-count {
		background: #ef4444;
		color: #ffffff;
	}
	.pg-a11y-chip.has-warn {
		border-color: #fde68a;
		background: #fffbeb;
		color: #b45309;
	}
	.pg-a11y-chip.has-warn .chip-count {
		background: #f59e0b;
		color: #ffffff;
	}
	.pg-a11y-bar-actions {
		display: flex;
		align-items: center;
		gap: 0.35rem;
		flex-shrink: 0;
	}
	.pg-a11y-drawer {
		border-top: 1px solid var(--admin-border-subtle, #e2e8f0);
		background: var(--admin-surface, #ffffff);
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
		border-bottom: 1px solid var(--admin-border-subtle, #e2e8f0);
	}
	.pg-a11y-issues-list {
		display: flex;
		flex-direction: column;
		gap: 0.65rem;
	}
	.pg-a11y-issue-card {
		border: 1px solid var(--admin-border, #cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		padding: 0.75rem 0.85rem;
		background: var(--admin-surface, #ffffff);
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
		transition: all 0.15s ease;
	}
	.pg-a11y-issue-card.is-error {
		border-left: 4px solid #ef4444;
		background: #fffbfb;
	}
	.pg-a11y-issue-card.is-warn {
		border-left: 4px solid #f59e0b;
		background: #fffdf9;
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
	.pg-a11y-rule-tag.error { background: #fee2e2; color: #b91c1c; }
	.pg-a11y-rule-tag.warn { background: #fef3c7; color: #b45309; }
	.pg-a11y-issue-msg {
		font-size: 0.84rem;
		font-weight: 600;
		color: var(--admin-text-main, #0f172a);
		line-height: 1.35;
	}
	.pg-a11y-issue-code {
		font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
		font-size: 0.78rem;
		background: var(--admin-bg, #f1f5f9);
		border: 1px solid var(--admin-border-subtle, #e2e8f0);
		border-radius: 4px;
		padding: 0.35rem 0.6rem;
		color: #334155;
		word-break: break-all;
		white-space: pre-wrap;
	}
	.pg-a11y-issue-suggestion {
		font-size: 0.78rem;
		color: var(--admin-text-muted, #475569);
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
		background: var(--admin-surface, #ffffff);
		border: 1px solid var(--admin-border, #cbd5e1);
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
		0% { outline: 3px solid #ef4444; box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.4); }
		50% { outline: 3px solid #f59e0b; box-shadow: 0 0 0 8px rgba(245, 158, 11, 0.3); }
		100% { outline: 3px solid #ef4444; box-shadow: 0 0 0 4px rgba(239, 68, 68, 0); }
	}
	.jbd-a11y-pulse {
		animation: a11yHighlightPulse 1.2s ease-in-out 3;
		border-radius: 4px;
	}
</style>

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">#(isNew ? "Add New Article" : "Edit Article: " & EncodeForHTML(article.title ?: ""))#</h1>
			<cfif !isNew>
				<cfif (article.status ?: "") eq "published">
					<span class="badge badge-success" style="font-size:0.75rem;">Live</span>
				<cfelseif (article.status ?: "") eq "draft">
					<span class="badge badge-warning" style="font-size:0.75rem;">Draft</span>
				<cfelse>
					<span class="badge badge-neutral" style="font-size:0.75rem;">#article.status ?: ""#</span>
				</cfif>
			</cfif>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">PIO</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='articles', action='index')#">Articles &amp; Posts</a></li>
				<li class="breadcrumb-item active" aria-current="page">#(isNew ? "New" : "Edit")#</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center;">
		<a href="#urlFor(controller='articles', action='index')#" class="btn btn-outline-secondary btn-sm">
			Cancel
		</a>
		<button type="button" class="btn btn-primary btn-sm" onclick="saveArticleForm()" id="btnSaveTop">
			#svgIcon(name="check-circle", size=14)#
			<span>Save Article</span>
		</button>
	</div>
</div>

<form id="articleForm" onsubmit="event.preventDefault(); saveArticleForm();">
	<input type="hidden" name="id" id="articleId" value="#Val(article.id ?: 0)#">

	<div style="display:grid; grid-template-columns:minmax(0, 1fr) 340px; gap:1.5rem; align-items:start;">
		<!--- Left (Main Content) Column --->
		<div style="display:flex; flex-direction:column; gap:1.25rem;">
			<!--- Title & Slug Card --->
			<div class="admin-card" style="padding:1.25rem;">
				<div style="margin-bottom:1.1rem;">
					<label for="articleTitle" style="display:block; font-weight:600; font-size:0.9rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Article Headline / Title <span style="color:var(--admin-danger, ##ef4444);">*</span>
					</label>
					<input type="text" id="articleTitle" name="title" class="form-control" style="font-size:1.15rem; font-weight:600; padding:0.65rem 0.85rem;" placeholder="e.g. Chelan County Adopts 2026 Comprehensive Wildfire Protection Plan" value="#EncodeForHTML(article.title ?: "")#" required oninput="if (#isNew ? 'true' : 'false'#) autoSlug(this.value);">
				</div>

				<div>
					<label for="articleSlug" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						URL Slug / Permalinks
					</label>
					<div style="display:flex; align-items:center; border:1px solid var(--admin-border); border-radius:var(--radius-md); overflow:hidden; background:var(--admin-bg);">
						<span style="padding:0.45rem 0.65rem; color:var(--admin-text-muted); font-size:0.8rem; border-right:1px solid var(--admin-border); font-family:monospace;">
							/news/article/
						</span>
						<input type="text" id="articleSlug" name="slug" class="form-control" style="border:none; border-radius:0; background:transparent; font-size:0.85rem; font-family:monospace; padding:0.45rem 0.65rem;" value="#EncodeForHTML(article.slug ?: "")#" placeholder="chelan-county-wildfire-plan">
					</div>
				</div>
			</div>

			<!--- Excerpt / Summary --->
			<div class="admin-card" style="padding:1.25rem;">
				<label for="articleSummary" style="display:block; font-weight:600; font-size:0.9rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
					Story Excerpt / Teaser Summary
				</label>
				<p style="font-size:0.78rem; color:var(--admin-text-muted); margin-top:0; margin-bottom:0.5rem;">
					A concise 1-2 sentence lead paragraph shown on the county homepage, social feeds, and search listings (max 1000 characters).
				</p>
				<textarea id="articleSummary" name="summary" class="form-control" rows="3" maxlength="1000" style="font-size:0.9rem; resize:vertical;" placeholder="Brief summary of this article...">#EncodeForHTML(article.summary ?: "")#</textarea>
			</div>

			<!--- Content Body with JBDEditor --->
			<div class="admin-card" style="padding:1.25rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
					<label for="articleContent" style="display:block; font-weight:600; font-size:0.9rem; margin:0; color:var(--admin-text-main);">
						Full Story Content <span style="color:var(--admin-danger, ##ef4444);">*</span>
					</label>
					<span style="font-size:0.75rem; color:var(--admin-text-muted);">
						Accessible JBDEditor &bull; WCAG 2.1 AA Compliant
					</span>
				</div>

				<!--- Automated ADA WCAG Pre-Flight Linter Bar --->
				<div id="articleA11yLinterBar" class="pg-a11y-linter-bar is-passed" role="region" aria-label="ADA WCAG 2.1 AA Pre-Flight Linter" style="margin-bottom:0.75rem;">
					<div class="pg-a11y-bar-main">
						<div class="pg-a11y-bar-title-wrap">
							<span class="pg-a11y-bar-icon" aria-hidden="true">#svgIcon(name="shield", size=15)#</span>
							<strong class="pg-a11y-bar-title">ADA Pre-Flight Linter</strong>
							<span class="pg-a11y-standard-badge">WCAG 2.1 AA</span>
							<span id="articleA11yOverallBadge" class="badge badge-success" role="status" aria-live="polite">
								#svgIcon(name="check-circle", size=12)# <span>Compliant</span>
							</span>
						</div>

						<div class="pg-a11y-category-chips" id="articleA11yCategoryChips" role="group" aria-label="Accessibility Check Categories">
							<button type="button" class="pg-a11y-chip" id="chipA11yCover" data-cat="cover" onclick="window.ArticleA11yLinter.setFilter('cover')" title="Cover Image: Alt text & decorative status">
								<span class="chip-label">Cover</span>
								<span class="chip-count" id="countA11yCover">0</span>
							</button>
							<button type="button" class="pg-a11y-chip" id="chipA11yImages" data-cat="images" onclick="window.ArticleA11yLinter.setFilter('images')" title="Story Images: Alternative text & descriptions">
								<span class="chip-label">Images</span>
								<span class="chip-count" id="countA11yImages">0</span>
							</button>
							<button type="button" class="pg-a11y-chip" id="chipA11yHeadings" data-cat="headings" onclick="window.ArticleA11yLinter.setFilter('headings')" title="Headings: Logical outline hierarchy">
								<span class="chip-label">Headings</span>
								<span class="chip-count" id="countA11yHeadings">0</span>
							</button>
							<button type="button" class="pg-a11y-chip" id="chipA11yLinks" data-cat="links" onclick="window.ArticleA11yLinter.setFilter('links')" title="Links: Descriptive text & target notifications">
								<span class="chip-label">Links</span>
								<span class="chip-count" id="countA11yLinks">0</span>
							</button>
							<button type="button" class="pg-a11y-chip" id="chipA11yTables" data-cat="tables" onclick="window.ArticleA11yLinter.setFilter('tables')" title="Tables: Header cells & captions">
								<span class="chip-label">Tables</span>
								<span class="chip-count" id="countA11yTables">0</span>
							</button>
							<button type="button" class="pg-a11y-chip" id="chipA11yFormat" data-cat="format" onclick="window.ArticleA11yLinter.setFilter('format')" title="Readability, styling & contrast">
								<span class="chip-label">Readability</span>
								<span class="chip-count" id="countA11yFormat">0</span>
							</button>
						</div>

						<div class="pg-a11y-bar-actions">
							<button type="button" class="btn btn-outline btn-xs" id="btnToggleA11yDrawer" aria-expanded="false" aria-controls="articleA11yIssuesDrawer" onclick="window.ArticleA11yLinter.toggleDrawer()">
								#svgIcon(name="eye", size=13)#
								<span id="btnToggleA11yDrawerText">Audit Report</span>
								<span class="badge badge-neutral" id="articleA11yIssueBadge" style="margin-left:2px; font-weight:700;">0</span>
							</button>
							<button type="button" class="btn btn-ghost btn-xs btn-icon-only" id="btnRescanA11y" onclick="window.ArticleA11yLinter.scan()" title="Re-scan content for accessibility barriers" aria-label="Re-scan accessibility">
								#svgIcon(name="refresh", size=13)#
							</button>
						</div>
					</div>

					<!--- Expandable Diagnostic & Quick-Fix Drawer --->
					<div id="articleA11yIssuesDrawer" class="pg-a11y-drawer" style="display:none;" hidden>
						<div class="pg-a11y-drawer-header">
							<div style="display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
								<h4 class="pg-a11y-drawer-title" style="margin:0; font-size:0.875rem; font-weight:700;">Pre-Flight Audit Diagnostics</h4>
								<div class="pg-attr-tabs" role="tablist" aria-label="Issue Filter Tabs" style="display:flex; gap:0.3rem; padding:0.12rem;">
									<button type="button" class="pg-a11y-chip is-active-filter" id="tabA11yAll" onclick="window.ArticleA11yLinter.setFilter('all')">All (<span id="tabCountA11yAll">0</span>)</button>
									<button type="button" class="pg-a11y-chip" id="tabA11yErrors" onclick="window.ArticleA11yLinter.setFilter('errors')" style="color:##b91c1c;">Errors (<span id="tabCountA11yErrors">0</span>)</button>
									<button type="button" class="pg-a11y-chip" id="tabA11yWarnings" onclick="window.ArticleA11yLinter.setFilter('warnings')" style="color:##b45309;">Warnings (<span id="tabCountA11yWarnings">0</span>)</button>
								</div>
							</div>
							<button type="button" class="btn btn-ghost btn-xs btn-icon-only" onclick="window.ArticleA11yLinter.closeDrawer()" aria-label="Collapse audit report">
								#svgIcon(name="x", size=14)#
							</button>
						</div>

						<div id="articleA11yIssuesList" class="pg-a11y-issues-list" role="region" aria-live="polite">
							<!--- Dynamic Issue Cards injected by JS --->
						</div>
					</div>
				</div>

				<textarea id="articleContent" name="content_html" data-jbd-editor data-jbd-toolbar="basic" data-jbd-inline-toolbar="true" data-jbd-height="420px" data-jbd-placeholder="Type or paste formatted article text here...">#EncodeForHTML(article.content_html ?: "")#</textarea>
			</div>

			<!--- SEO & Search Engine Metadata --->
			<div class="admin-card" style="padding:1.25rem;">
				<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:1rem; border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="globe", size=16)#</span>
					<h3 style="margin:0; font-size:0.95rem; font-weight:700; color:var(--admin-text-main);">Search Engine Optimization (SEO &amp; Open Graph)</h3>
				</div>
				<div style="display:flex; flex-direction:column; gap:0.9rem;">
					<div>
						<label for="metaTitle" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
							Custom Meta Title (Defaults to headline if blank)
						</label>
						<input type="text" id="metaTitle" name="meta_title" class="form-control" maxlength="255" value="#EncodeForHTML(article.meta_title ?: "")#" placeholder="Headline | Chelan County, WA">
					</div>
					<div>
						<label for="metaDescription" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
							Meta Description (Defaults to summary if blank)
						</label>
						<textarea id="metaDescription" name="meta_description" class="form-control" rows="2" maxlength="500" placeholder="Meta description for search engine snippets...">#EncodeForHTML(article.meta_description ?: "")#</textarea>
					</div>
				</div>
			</div>
		</div>

		<!--- Right (Sidebar) Column --->
		<div style="display:flex; flex-direction:column; gap:1.25rem;">
			<!--- Publishing Controls Card --->
			<div class="admin-card" style="padding:1.25rem;">
				<h3 style="margin:0 0 1rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					Publish Settings
				</h3>

				<!--- ADA Pre-Flight Scorecard Widget --->
				<div class="pg-a11y-publish-widget" id="articleA11yPublishWidget">
					<div class="pg-a11y-pub-header">
						<span style="display:flex; align-items:center; gap:0.35rem; font-size:0.78rem; font-weight:700; color:var(--admin-text-main);">
							#svgIcon(name="shield", size=14)#
							<span>ADA Pre-Flight</span>
						</span>
						<span id="articleA11yPublishBadge" class="badge badge-success" style="font-size:0.7rem; font-weight:700;">PASS</span>
					</div>
					<div class="pg-a11y-pub-body">
						<div id="articleA11yPublishSummary" style="font-size:0.75rem; color:var(--admin-text-muted); line-height:1.4;">
							Article ready for public release. Meets ADA WCAG 2.1 AA.
						</div>
						<button type="button" id="lnkInspectArticleA11y" aria-expanded="false" onclick="if(window.ArticleA11yLinter){window.ArticleA11yLinter.toggleDrawer('publish');}return false;" style="display:inline-flex; align-items:center; gap:0.25rem; font-size:0.75rem; font-weight:600; color:var(--admin-primary); margin-top:0.35rem; background:none; border:none; padding:0; cursor:pointer; text-decoration:none;">
							<span id="lnkInspectArticleA11yText">Inspect Diagnostics</span>
							<span id="lnkInspectArticleA11yChevron" style="display:inline-flex; align-items:center; transition:transform 0.2s ease;">#svgIcon(name="chevron-down", size=12)#</span>
						</button>
						<div id="articleA11yPublishInlineList" style="display:none; margin-top:0.55rem; padding-top:0.55rem; border-top:1px solid var(--admin-border-subtle, ##e2e8f0); flex-direction:column; gap:0.45rem; max-height:280px; overflow-y:auto;"></div>
					</div>
				</div>

				<div style="margin-bottom:1rem;">
					<label for="articleStatus" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Publication Status
					</label>
					<select id="articleStatus" name="status" class="form-control">
						<option value="published" <cfif (article.status ?: "") eq "published">selected</cfif>>Published Live</option>
						<option value="scheduled" <cfif (article.status ?: "") eq "scheduled">selected</cfif>>Scheduled for Release</option>
						<option value="draft" <cfif (article.status ?: "") eq "draft">selected</cfif>>Draft</option>
						<option value="archived" <cfif (article.status ?: "") eq "archived">selected</cfif>>Archived</option>
					</select>
				</div>

				<div style="margin-bottom:1rem;">
					<label for="publishedAt" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Publish Date &amp; Time
					</label>
					<input type="datetime-local" id="publishedAt" name="published_at" class="form-control" value="#DateFormat(article.published_at ?: Now(), 'yyyy-mm-dd')#T#TimeFormat(article.published_at ?: Now(), 'HH:mm')#">
				</div>

				<div style="margin-bottom:1rem;">
					<label for="unpublishAt" style="display:flex; justify-content:space-between; align-items:center; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						<span>Expiration / Archive On</span>
						<span style="font-weight:normal; font-size:0.75rem;">(optional)</span>
					</label>
					<input type="datetime-local" id="unpublishAt" name="unpublish_at" class="form-control" value="<cfif IsDate(article.unpublish_at ?: '')>#DateFormat(article.unpublish_at, 'yyyy-mm-dd')#T#TimeFormat(article.unpublish_at, 'HH:mm')#</cfif>">
					<small style="display:block; margin-top:0.25rem; font-size:0.72rem; color:var(--admin-text-muted);">
						Automatically transitions to Archived status upon reaching this timestamp.
					</small>
				</div>

				<input type="hidden" id="siteid" name="siteid" value="#EncodeForHTMLAttribute(Len(Trim(article.siteid ?: '')) ? article.siteid : (activeWorkspaceId != 'global' ? activeWorkspaceId : ''))#">

				<button type="button" class="btn btn-primary" style="width:100%; justify-content:center; padding:0.6rem;" onclick="saveArticleForm()" id="btnSaveSidebar">
					#svgIcon(name="check-circle", size=15)#
					<span>Save &amp; Publish</span>
				</button>
			</div>

			<!--- Category & Tags Card --->
			<div class="admin-card" style="padding:1.25rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.75rem; border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					<h3 style="margin:0; font-size:0.95rem; font-weight:700; color:var(--admin-text-main);">
						Taxonomy
					</h3>
					<a href="#urlFor(controller='articles', action='categories')#" target="_blank" style="font-size:0.75rem; color:var(--admin-primary); text-decoration:none;">
						+ Manage
					</a>
				</div>

				<div style="margin-bottom:1rem;">
					<label for="categoryId" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Primary Category
					</label>
					<select id="categoryId" name="category_id" class="form-control">
						<option value="0">-- Select Category --</option>
						<cfloop array="#categories#" index="cat">
							<option value="#cat.id#" #(Val(article.category_id ?: 0) eq cat.id ? "selected" : "")#>#EncodeForHTML(cat.name)#</option>
						</cfloop>
					</select>
				</div>

				<div>
					<label for="articleTags" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Tags (comma-separated)
					</label>
					<input type="text" id="articleTags" name="tags" class="form-control" value="#EncodeForHTML(article.tags ?: "")#" placeholder="wildfire, public safety, budget">
					<cfif ArrayLen(availableTags)>
						<div style="margin-top:0.4rem; display:flex; flex-wrap:wrap; gap:0.3rem;">
							<span style="font-size:0.7rem; color:var(--admin-text-muted); width:100%;">Suggested tags:</span>
							<cfloop array="#availableTags#" index="tg">
								<button type="button" class="badge badge-neutral" style="cursor:pointer; border:1px solid var(--admin-border); font-size:0.68rem; padding:0.15rem 0.4rem;" onclick="appendTag('#JSStringFormat(tg.name)#')">
									+#EncodeForHTML(tg.name)#
								</button>
							</cfloop>
						</div>
					</cfif>
				</div>
			</div>

			<!--- Featured Image Card --->
			<div class="admin-card" style="padding:1.25rem;">
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
							<span id="featuredImgWsName">#EncodeForHTML(activeWsObj.name ?: "Workspace")#</span>
						</span>
					</div>
				</div>

				<!--- Thumbnail Preview --->
				<div style="margin-bottom:0.75rem;">
					<div id="featuredImgPreviewWrap"
					     role="button"
					     tabindex="0"
					     aria-label="Click to browse workspace media library for cover image"
					     onclick="openMediaPickerForArticle()"
					     onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();openMediaPickerForArticle();}"
					     style="border:1.5px dashed var(--admin-border); border-radius:var(--radius-md); padding:0.5rem; text-align:center; min-height:130px; display:flex; flex-direction:column; align-items:center; justify-content:center; background:var(--admin-bg); cursor:pointer; transition:all 0.15s ease;"
					     onmouseenter="this.style.borderColor='var(--admin-primary)'; this.style.backgroundColor='var(--admin-surface-hover, ##f8fafc)';"
					     onmouseleave="this.style.borderColor='var(--admin-border)'; this.style.backgroundColor='var(--admin-bg)';"
					     title="Click to browse workspace media library">
						<img id="featuredImgPreview" src="#EncodeForHTML(article.featured_image ?: '')#" alt="#EncodeForHTMLAttribute(article.featured_image_alt ?: '')#" style="max-width:100%; max-height:140px; object-fit:cover; border-radius:var(--radius-sm); #(Len(Trim(article.featured_image ?: '')) ? '' : 'display:none;')#" />
						<div id="featuredImgPlaceholder" style="color:var(--admin-text-muted); font-size:0.8rem; #(Len(Trim(article.featured_image ?: '')) ? 'display:none;' : 'display:flex; flex-direction:column; align-items:center; justify-content:center;')#">
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
						<input type="text" id="featuredImage" name="featured_image" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(article.featured_image ?: "")#" placeholder="/files/pio/images/photo.jpg" oninput="updateImagePreview(this.value)">
						<button type="button" id="btnBrowseFeaturedImg" class="btn btn-outline-secondary btn-sm" onclick="openMediaPickerForArticle()" title="Select from Workspace Media Library" style="display:inline-flex; align-items:center; gap:0.3rem; white-space:nowrap;">
							#svgIcon(name="folder", size=13)#
							<span>Browse</span>
						</button>
						<button type="button" id="btnRemoveFeaturedImg" class="btn btn-outline-danger btn-sm" onclick="removeFeaturedImage()" title="Remove cover image" style="display:#(Len(Trim(article.featured_image ?: '')) ? 'inline-flex' : 'none')#; align-items:center; gap:0.3rem; white-space:nowrap;">
							#svgIcon(name="trash", size=13)#
							<span>Remove</span>
						</button>
					</div>
				</div>

				<!--- Decorative Toggle (WCAG 2.1 H67) --->
				<div style="background:var(--admin-bg-subtle, ##f8fafc); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:0.6rem 0.75rem; margin-bottom:0.75rem;">
					<label style="display:flex; align-items:flex-start; gap:0.5rem; font-size:0.8rem; font-weight:600; color:var(--admin-text-main); margin:0; cursor:pointer;">
						<input type="checkbox" id="featuredImageDecorative" name="featured_image_decorative" value="1" #(Val(article.featured_image_decorative ?: 0) ? 'checked="checked"' : '')# onchange="onDecorativeToggled(this.checked)" style="margin-top:0.15rem;">
						<div>
							<span>Mark as decorative image (WCAG 1.1.1 / H67)</span>
							<div style="font-weight:400; font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.15rem; line-height:1.35;">
								Check if this image is purely decorative or mood-setting and conveys no critical news content. Screen readers will safely ignore it.
							</div>
						</div>
					</label>
				</div>

				<!--- Alt Text Container --->
				<div id="altTextContainer" style="#(Val(article.featured_image_decorative ?: 0) ? 'opacity:0.5; pointer-events:none;' : '')# margin-bottom:0.75rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.25rem;">
						<label for="featuredImageAlt" style="display:block; font-weight:600; font-size:0.8rem; margin:0; color:var(--admin-text-muted);">
							Alternative Text (ADA / WCAG 2.1 AA) <span style="color:var(--admin-danger, ##ef4444); font-weight:700;">*</span>
						</label>
						<span style="font-size:0.7rem; color:var(--admin-text-muted);" id="altCharCounter">#Len(Trim(article.featured_image_alt ?: ''))#/150 rec.</span>
					</div>
					<input type="text" id="featuredImageAlt" name="featured_image_alt" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(article.featured_image_alt ?: "")#" placeholder="Brief description of the scene or subjects for screen readers" maxlength="500" oninput="onAltInput(this.value)">

					<div style="display:flex; justify-content:space-between; align-items:center; margin-top:0.3rem;">
						<div style="font-size:0.72rem; color:var(--admin-text-muted);">
							Be concise and specific. Do not include phrases like "photo of" or "image of".
						</div>
						<button type="button" class="btn btn-link btn-sm" style="padding:0; font-size:0.72rem; text-decoration:none; color:var(--admin-primary); display:inline-flex; align-items:center; gap:0.2rem; cursor:pointer;" onclick="suggestAltFromHeadline()" title="Draft initial alt text based on the article headline">
							#svgIcon(name="sparkles", size=12)#
							<span>Suggest from Headline</span>
						</button>
					</div>

					<div id="altAuditNotice" style="display:none; margin-top:0.35rem; padding:0.4rem 0.6rem; border-radius:var(--radius-sm); font-size:0.73rem; line-height:1.35;"></div>
				</div>

				<!--- Visible Story Caption --->
				<div style="margin-bottom:0.75rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.25rem;">
						<label for="featuredImageCaption" style="display:block; font-weight:600; font-size:0.8rem; margin:0; color:var(--admin-text-muted);">
							Story Caption (Visible)
						</label>
						<span style="font-size:0.7rem; color:var(--admin-text-muted);" id="captionCharCounter">#Len(Trim(article.featured_image_caption ?: ''))#/1000</span>
					</div>
					<input type="text" id="featuredImageCaption" name="featured_image_caption" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(article.featured_image_caption ?: "")#" placeholder="Optional visible caption printed below the image on the article page" maxlength="1000" oninput="updateCaptionCharCount(this.value)">
				</div>

				<!--- Extended Description (for Complex Visuals / Infographics / Charts / Maps) --->
				<div style="margin-bottom:0.75rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.25rem;">
						<label for="featuredImageDescription" style="display:block; font-weight:600; font-size:0.8rem; margin:0; color:var(--admin-text-muted);">
							Extended Description (Complex Visuals / Maps / Infographics)
						</label>
						<span style="font-size:0.7rem; color:var(--admin-text-muted);" id="descCharCounter">#Len(Trim(article.featured_image_description ?: ''))#/2000</span>
					</div>
					<textarea id="featuredImageDescription" name="featured_image_description" class="form-control" rows="2" style="font-size:0.82rem;" placeholder="Detailed text transcription for screen readers when the image contains complex maps, data charts, or documents..." maxlength="2000" oninput="updateDescCharCount(this.value)">#EncodeForHTML(article.featured_image_description ?: "")#</textarea>
					<div style="font-size:0.71rem; color:var(--admin-text-muted); margin-top:0.2rem;">
						WCAG 1.1.1 AA: If the cover image conveys detailed data, provide a full text equivalent here.
					</div>
				</div>

				<!--- Photo Credit / Attribution --->
				<div>
					<label for="featuredImageCredit" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Photo Credit / Attribution
					</label>
					<input type="text" id="featuredImageCredit" name="featured_image_credit" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(article.featured_image_credit ?: "")#" placeholder="e.g. Chelan County Sheriff's Office / Jane Doe" maxlength="255">
				</div>
			</div>

			<!--- Author Info Card --->
			<div class="admin-card" style="padding:1.25rem;">
				<h3 style="margin:0 0 0.75rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					Author &amp; Attribution
				</h3>

				<div style="margin-bottom:0.75rem;">
					<label for="authorName" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Author Name
					</label>
					<input type="text" id="authorName" name="author_name" class="form-control" value="#EncodeForHTML(article.author_name ?: "Public Information Officer")#">
				</div>

				<div>
					<label for="authorTitle" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Author Title / Department
					</label>
					<input type="text" id="authorTitle" name="author_title" class="form-control" value="#EncodeForHTML(article.author_title ?: "Public Information Office")#">
				</div>
			</div>
		</div>
	</div>
</form>

<!--- Media Picker Modal Overlay for Articles --->
<div class="admin-modal-backdrop" id="mediaPickerModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeMediaPickerModal()"></div>
<div class="admin-modal" id="mediaPickerModal" role="dialog" aria-modal="true" aria-labelledby="mediaPickerModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:96vw; max-width:1440px; height:88vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
	<div class="modal-header" style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center; background:var(--admin-bg, ##f8fafc);">
		<h2 class="modal-title" id="mediaPickerModalTitle" style="margin:0; font-size:1.05rem; font-weight:700; display:flex; align-items:center; gap:0.5rem; color:var(--admin-text-main);">
			#svgIcon(name="image", size=18)#
			<span id="mediaPickerTitleText">Select Cover Image from Media Library</span>
		</h2>
		<button type="button" class="btn btn-secondary btn-sm" onclick="closeMediaPickerModal()" aria-label="Close Media Picker" id="btnCloseMediaPicker">
			#svgIcon(name="x", size=16)#
		</button>
	</div>
	<div style="flex:1; width:100%; height:calc(100% - 60px); position:relative;">
		<iframe id="mediaPickerIframe" src="about:blank" style="width:100%; height:100%; border:none;" title="Media Asset Picker"></iframe>
	</div>
</div>
</cfoutput>

<script>
function autoSlug(val) {
	if (!val) return;
	const slug = val.toLowerCase()
		.replace(/[^a-z0-9\s-]/g, '')
		.replace(/[\s-]+/g, '-')
		.replace(/^-+|-+$/g, '')
		.substring(0, 255);
	document.getElementById('articleSlug').value = slug;
}

function appendTag(tagName) {
	const tagsInput = document.getElementById('articleTags');
	let current = tagsInput.value.split(',').map(s => s.trim()).filter(Boolean);
	if (!current.includes(tagName)) {
		current.push(tagName);
		tagsInput.value = current.join(', ');
	}
}

function updateAltCharCount(val) {
	const counter = document.getElementById('altCharCounter');
	if (counter) {
		const len = (val || '').length;
		counter.textContent = len + '/150 rec.';
		if (len > 150) {
			counter.style.color = 'var(--admin-warning, ##d97706)';
		} else {
			counter.style.color = 'var(--admin-text-muted)';
		}
	}
}

function onAltInput(val) {
	updateAltCharCount(val);
	updateAdaComplianceStatus();
}

function updateDescCharCount(val) {
	const counter = document.getElementById('descCharCounter');
	if (counter) {
		counter.textContent = (val || '').length + '/2000';
	}
}

function updateCaptionCharCount(val) {
	const counter = document.getElementById('captionCharCounter');
	if (counter) {
		counter.textContent = (val || '').length + '/1000';
	}
}

function onDecorativeToggled(isDecorative) {
	const altContainer = document.getElementById('altTextContainer');
	const imgPreview = document.getElementById('featuredImgPreview');
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
			const altInput = document.getElementById('featuredImageAlt');
			imgPreview.setAttribute('alt', altInput ? altInput.value : '');
		}
	}
	updateAdaComplianceStatus();
}

function suggestAltFromHeadline() {
	const titleEl = document.getElementById('articleTitle');
	const headline = (titleEl ? titleEl.value : '').trim();
	if (!headline) {
		if (typeof window.adminAlert === 'function') {
			window.adminAlert({ title: 'Headline Required', message: 'Please enter an article headline above first so we can suggest matching image alt text.', type: 'info' });
		} else if (typeof window.showToast === 'function') {
			window.showToast('Please enter an article headline first.', 'warning');
		}
		if (titleEl) titleEl.focus();
		return;
	}

	const altInput = document.getElementById('featuredImageAlt');
	if (altInput) {
		let suggestion = headline;
		if (suggestion.length > 120) {
			suggestion = suggestion.substring(0, 117).trim() + '...';
		}
		altInput.value = suggestion;
		updateAltCharCount(suggestion);
		updateAdaComplianceStatus();
		altInput.focus();
		if (typeof window.showToast === 'function') {
			window.showToast('Alt text populated from headline. Edit as needed for visual accuracy.', 'success');
		}
	}
}

function updateAdaComplianceStatus() {
	const imgInput = document.getElementById('featuredImage');
	const decInput = document.getElementById('featuredImageDecorative');
	const altInput = document.getElementById('featuredImageAlt');
	const badge = document.getElementById('featuredImgAdaBadge');
	const badgeText = document.getElementById('featuredImgAdaText');
	const notice = document.getElementById('altAuditNotice');

	if (!badge || !badgeText) return;

	const imgUrl = (imgInput ? imgInput.value : '').trim();
	const isDec = decInput ? decInput.checked : false;
	const altText = (altInput ? altInput.value : '').trim();

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
			notice.style.background = 'var(--admin-bg-subtle, ##f1f5f9)';
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
			notice.style.background = '##fef2f2';
			notice.style.color = '##991b1b';
			notice.style.border = '1px solid ##fecaca';
			notice.innerHTML = '<strong>⚠️ ADA Title II / WCAG 1.1.1 Requirement:</strong> Alternative text is required for non-decorative images so screen reader users receive equal access.';
		}
		return;
	}

	// Audit quality of alt text
	const fileExtRegex = /\.(jpe?g|png|gif|webp|svg|bmp|tiff)$/i;
	const genericWordRegex = /^(image|photo|picture|photograph|graphic|pic|img)$/i;
	const startsWithGeneric = /^(photo|image|picture) of /i;

	if (fileExtRegex.test(altText) || genericWordRegex.test(altText) || startsWithGeneric.test(altText)) {
		badge.classList.add('badge-warning');
		badgeText.textContent = 'Generic Alt Warning';
		badge.title = 'Alt text contains file names or generic phrases like "image of".';
		if (notice) {
			notice.style.display = 'block';
			notice.style.background = '##fffbeb';
			notice.style.color = '##92400e';
			notice.style.border = '1px solid ##fde68a';
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

function getArticleAssignedWorkspace() {
	const siteEl = document.getElementById('siteid');
	if (siteEl && siteEl.value) {
		const val = siteEl.value.trim().toLowerCase();
		if (val && val !== 'global' && val !== 'all') {
			return val;
		}
	}
	const wsCont = document.getElementById('workspaceDropdownContainer');
	if (wsCont && wsCont.getAttribute('data-active-ws-id')) {
		const wsId = wsCont.getAttribute('data-active-ws-id').trim().toLowerCase();
		if (wsId && wsId !== 'global' && wsId !== 'all') {
			return wsId;
		}
	}
	const m = document.cookie.match(/(?:^|;\s*)cmsadmin_workspace=([^;]+)/);
	if (m) {
		const cookieWs = decodeURIComponent(m[1]).trim().toLowerCase();
		if (cookieWs && cookieWs !== 'global' && cookieWs !== 'all') {
			return cookieWs;
		}
	}
	const fallback = "<cfoutput>#EncodeForJavaScript(activeWorkspaceId)#</cfoutput>".toLowerCase();
	if (fallback && fallback !== 'global' && fallback !== 'all') {
		return fallback;
	}
	return 'pio';
}

function getArticleAssignedWorkspaceName(wsId) {
	wsId = (wsId || getArticleAssignedWorkspace()).toLowerCase();
	const siteEl = document.getElementById('siteid');
	if (siteEl && siteEl.tagName === 'SELECT') {
		for (let i = 0; i < siteEl.options.length; i++) {
			if (siteEl.options[i].value.toLowerCase() === wsId) {
				return siteEl.options[i].text.trim();
			}
		}
	}
	const wsCont = document.getElementById('workspaceDropdownContainer');
	if (wsCont) {
		const titleEl = wsCont.querySelector('.header-ws-title') || wsCont.querySelector('.workspace-name');
		if (titleEl && titleEl.textContent.trim()) {
			return titleEl.textContent.trim();
		}
	}
	return wsId;
}

function onArticleWorkspaceChanged(newWsId) {
	const wsName = getArticleAssignedWorkspaceName(newWsId);
	const badgeNameEl = document.getElementById('featuredImgWsName');
	if (badgeNameEl) {
		badgeNameEl.textContent = wsName;
	}
	if (typeof window.showToast === 'function') {
		window.showToast('Article assigned workspace set to: ' + wsName, 'info');
	}
}

window.addEventListener('cmsadmin:workspaceChanged', function(e) {
	if (e && e.detail && e.detail.id) {
		const newId = e.detail.id.toLowerCase();
		if (newId !== 'global' && newId !== 'all') {
			const siteEl = document.getElementById('siteid');
			if (siteEl) {
				if (siteEl.tagName === 'SELECT') {
					for (let i = 0; i < siteEl.options.length; i++) {
						if (siteEl.options[i].value.toLowerCase() === newId) {
							siteEl.selectedIndex = i;
							break;
						}
					}
				} else {
					siteEl.value = newId;
				}
			}
			onArticleWorkspaceChanged(newId);
		}
	}
});

function updateImagePreview(url) {
	const img = document.getElementById('featuredImgPreview');
	const ph = document.getElementById('featuredImgPlaceholder');
	const btnRemove = document.getElementById('btnRemoveFeaturedImg');
	const trimmed = (url || '').trim();
	if (trimmed.length > 0) {
		img.src = trimmed;
		img.style.display = 'block';
		if (ph) ph.style.display = 'none';
		if (btnRemove) btnRemove.style.display = 'inline-flex';
	} else {
		img.src = '';
		img.style.display = 'none';
		if (ph) ph.style.display = 'flex';
		if (btnRemove) btnRemove.style.display = 'none';
	}
	updateAdaComplianceStatus();
}

function removeFeaturedImage() {
	document.getElementById('featuredImage').value = '';
	document.getElementById('featuredImageAlt').value = '';
	const captionEl = document.getElementById('featuredImageCaption');
	if (captionEl) captionEl.value = '';
	const descEl = document.getElementById('featuredImageDescription');
	if (descEl) descEl.value = '';
	const creditEl = document.getElementById('featuredImageCredit');
	if (creditEl) creditEl.value = '';
	const decEl = document.getElementById('featuredImageDecorative');
	if (decEl) decEl.checked = false;

	updateImagePreview('');
	updateAltCharCount('');
	updateCaptionCharCount('');
	updateDescCharCount('');
	onDecorativeToggled(false);
	updateAdaComplianceStatus();

	if (typeof window.showToast === 'function') {
		window.showToast('Featured cover image removed.', 'info');
	}
	const browseBtn = document.getElementById('btnBrowseFeaturedImg');
	if (browseBtn) browseBtn.focus();
}

window.openMediaPicker = function(mode, options) {
	options = options || {};
	mode = mode || 'image';
	const modal = document.getElementById('mediaPickerModal');
	const backdrop = document.getElementById('mediaPickerModalBackdrop');
	const iframe = document.getElementById('mediaPickerIframe');
	const title = document.getElementById('mediaPickerTitleText');

	if (backdrop && backdrop.parentElement !== document.body) document.body.appendChild(backdrop);
	if (modal && modal.parentElement !== document.body) document.body.appendChild(modal);

	const assignedWs = getArticleAssignedWorkspace();
	const wsName = getArticleAssignedWorkspaceName(assignedWs);

	if (title) {
		title.textContent = (mode === 'document')
			? 'Select Document from Media Library (' + wsName + ')'
			: 'Select Cover Image from Media Library (' + wsName + ')';
	}

	const pickerType = (mode === 'document') ? 'document' : 'image';
	const folder = options.folder || (mode === 'document' ? 'documents' : 'images');

	if (typeof options.onSelect === 'function') {
		window._mediaPickerCustomCallback = options.onSelect;
	} else {
		window._mediaPickerCustomCallback = null;
	}

	if (iframe) {
		iframe.src = '/media/picker?picker=' + encodeURIComponent(mode)
			+ '&type=' + encodeURIComponent(pickerType)
			+ '&folder=' + encodeURIComponent(folder)
			+ '&ws=' + encodeURIComponent(assignedWs)
			+ '&callback=onMediaSelectedFromPicker';
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
	const modal = document.getElementById('mediaPickerModal');
	const backdrop = document.getElementById('mediaPickerModalBackdrop');
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
	window._mediaPickerCustomCallback = null;
	document.body.style.overflow = '';
	if (window._mediaPickerTrigger && typeof window._mediaPickerTrigger.focus === 'function') {
		try { window._mediaPickerTrigger.focus(); } catch (err) {}
		window._mediaPickerTrigger = null;
	}
};

window.openMediaPickerForArticle = function() {
	const triggerBtn = document.getElementById('btnBrowseFeaturedImg') || document.getElementById('featuredImgPreviewWrap');
	window._mediaPickerTrigger = triggerBtn;

	window.openMediaPicker('image', {
		folder: 'images',
		onSelect: function(payload) {
			if (!payload) return;
			const url = payload.url || (payload.data && payload.data.webUrl) || '';
			if (!url) return;

			const imgInput = document.getElementById('featuredImage');
			if (imgInput) {
				imgInput.value = url;
			}

			const altInput = document.getElementById('featuredImageAlt');
			const suggestedAlt = payload.alt || payload.title || (payload.data && (payload.data.altText || payload.data.title)) || '';
			if (altInput && (!altInput.value.trim().length) && suggestedAlt) {
				altInput.value = suggestedAlt;
				updateAltCharCount(suggestedAlt);
			}

			const captionInput = document.getElementById('featuredImageCaption');
			const suggestedCaption = payload.caption || (payload.data && payload.data.caption) || '';
			if (captionInput && (!captionInput.value.trim().length) && suggestedCaption) {
				captionInput.value = suggestedCaption;
				updateCaptionCharCount(suggestedCaption);
			}

			const creditInput = document.getElementById('featuredImageCredit');
			const suggestedCredit = payload.credit || (payload.data && payload.data.credit) || '';
			if (creditInput && (!creditInput.value.trim().length) && suggestedCredit) {
				creditInput.value = suggestedCredit;
			}

			updateImagePreview(url);
			updateAdaComplianceStatus();
			if (typeof window.showToast === 'function') {
				window.showToast('Cover image selected from ' + getArticleAssignedWorkspaceName() + ' workspace.', 'success');
			}
		}
	});
};

window.onMediaSelectedFromPicker = function(payload) {
	const customCb = window._mediaPickerCustomCallback;
	closeMediaPickerModal();
	if (typeof customCb === 'function') {
		customCb(payload);
		return;
	}
	if (payload && payload.html) {
		const textarea = document.getElementById('articleContent');
		if (typeof JBDEditor !== 'undefined' && JBDEditor.get && JBDEditor.get(textarea)) {
			JBDEditor.get(textarea).insertHTML(payload.html);
		}
	}
};

window.addEventListener('message', function(e) {
	if (e.data && (e.data.type === 'CMS_MEDIA_SELECTED' || e.data.type === 'cmsMediaSelected')) {
		const customCb = window._mediaPickerCustomCallback;
		closeMediaPickerModal();
		if (typeof customCb === 'function') {
			customCb(e.data);
			return;
		}
		if (e.data.html) {
			const textarea = document.getElementById('articleContent');
			if (typeof JBDEditor !== 'undefined' && JBDEditor.get && JBDEditor.get(textarea)) {
				JBDEditor.get(textarea).insertHTML(e.data.html);
			}
		}
	}
});

document.addEventListener('keydown', function(e) {
	if (e.key === 'Escape') {
		const modal = document.getElementById('mediaPickerModal');
		if (modal && modal.style.display !== 'none') {
			closeMediaPickerModal();
		}
	}
});

/* ==========================================================================
   Automated ADA WCAG 2.1 AA Pre-Flight Linter Engine & Controller
   ========================================================================== */
window.ArticleA11yLinter = (function() {
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
		var ta = document.getElementById("articleContent");
		return (typeof JBDEditor !== "undefined" && ta) ? JBDEditor.get(ta) : null;
	}

	function getHtmlContent() {
		if (!_editorBound) bindEditorEvents();
		var ed = getEditor();
		if (ed && typeof ed.getHTML === "function") {
			return ed.getHTML();
		}
		var ta = document.getElementById("articleContent");
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
		var isDecorative = featImgDec ? featImgDec.checked : false;
		var featAltInput = document.getElementById("featuredImageAlt");
		var featAlt = featAltInput ? featAltInput.value.trim() : "";

		if (featImgUrl) {
			if (!isDecorative && !featAlt) {
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
			} else if (!isDecorative && featAlt) {
				var genericNames = ["image", "photo", "picture", "graphic", "screenshot", "img", "icon", "placeholder", "file", "download"];
				var lower = featAlt.toLowerCase().replace(/[^a-z0-9]/g, "");
				var fileExtRegex = /\.(jpe?g|png|gif|webp|svg|bmp|tiff)$/i;

				if (genericNames.indexOf(lower) !== -1 || fileExtRegex.test(featAlt) || /^(photo|image|picture) of /i.test(featAlt)) {
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
						suggestion: "Describe what is specifically portrayed in the photograph or use 'Suggest from Headline'.",
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
						suggestion: "Shorten alt text to under 150 characters and place extended narrative in the visible Story Caption field.",
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
		var genericImgs = ["image", "photo", "picture", "graphic", "screenshot", "img", "icon", "placeholder", "file", "download"];
		imgs.forEach(function(img, idx) {
			var hasAlt = img.hasAttribute("alt");
			var alt = (img.getAttribute("alt") || "").trim();
			var isDecImg = (img.getAttribute("role") === "presentation" || img.getAttribute("aria-hidden") === "true");
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
					title: "In-Article Image Missing Alt Attribute",
					message: "Image lacks an alt attribute entirely. Assistive tech will read the raw URL or file name.",
					snippet: '<img src="' + escapeHtml(srcPreview) + '">',
					suggestion: 'Provide descriptive alternative text or mark as decorative (alt="" and role="presentation").',
					selector: "img",
					index: idx,
					quickFixType: "set-alt-decorative"
				});
			} else if (alt === "" && !isDecImg) {
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
						message: "This image is inside a link with an empty alt attribute, producing an unlabelled interactive link.",
						snippet: '<a href="' + escapeHtml(parentLink.getAttribute("href") || "") + '"><img src="' + escapeHtml(srcPreview) + '" alt=""></a>',
						suggestion: "Provide descriptive alt text clarifying link destination or add aria-label to parent link.",
						selector: "img",
						index: idx,
						quickFixType: "locate"
					});
				}
			} else if (alt.length > 0) {
				var lowerAlt = alt.toLowerCase().replace(/[^a-z0-9]/g, "");
				if (genericImgs.indexOf(lowerAlt) !== -1 || /^(dsc|img|p[0-9]|screenshot)[\-_0-9]*/i.test(alt) || /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(alt)) {
					warningCount++;
					catCounts.images++;
					issues.push({
						id: "img-generic-alt-" + idx,
						category: "images",
						severity: "warning",
						rule: "WCAG 1.1.1 (Non-text Content)",
						title: "Generic or Filename Alt Text in Article",
						message: 'Alternative text "' + escapeHtml(alt) + '" is a filename or generic label.',
						snippet: '<img alt="' + escapeHtml(alt) + '" src="' + escapeHtml(srcPreview) + '">',
						suggestion: "Replace with descriptive text explaining what the visual portrays in the news story.",
						selector: "img",
						index: idx,
						quickFixType: "locate"
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
						message: "Alt text exceeds recommended 150 characters.",
						snippet: '<img alt="' + escapeHtml(alt.substring(0, 60)) + '...">',
						suggestion: "Summarize the core visual concept in under 150 characters and use a paragraph caption below the image for details.",
						selector: "img",
						index: idx,
						quickFixType: "locate"
					});
				}
			}
		});

		// --- Rule Group 3: Headings (WCAG 1.3.1 Info and Relationships) ---
		var headings = temp.querySelectorAll("h1, h2, h3, h4, h5, h6");
		var lastLevel = 1; // Article headline serves as primary H1
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
					message: "An empty heading produces a confusing milestone for screen reader users.",
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
					title: "Multiple <h1> Tags (Article Headline is Primary H1)",
					message: "The article headline is already H1. Subsections in the body should start at <h2>.",
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
					message: "Story content begins at <" + tag + "> after the title without an introductory <h2>.",
					snippet: "<" + tag + ">" + escapeHtml(text.substring(0, 40)) + "</" + tag + ">",
					suggestion: "Change this initial heading to <h2> so document outline begins logically.",
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
					message: "Skipping heading levels disrupts outline navigation for screen readers.",
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

		// --- Rule Group 4: Links (WCAG 2.4.4 Link Purpose in Context) ---
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
					message: 'Link href is empty or "#". If this initiates a JavaScript action, a semantic button is preferred.',
					snippet: '<a href="' + escapeHtml(href || "''") + '">' + escapeHtml(text || "Link #" + (idx + 1)) + '</a>',
					suggestion: "Provide a valid URL or path.",
					selector: "a",
					index: idx,
					quickFixType: "locate"
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
					message: "Link contains no readable text, aria-label, or image description.",
					snippet: '<a href="' + escapeHtml(href) + '"></a>',
					suggestion: "Insert descriptive link text or remove the empty link tag.",
					selector: "a",
					index: idx,
					quickFixType: "remove-element"
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
						message: 'Generic phrases like "' + escapeHtml(accessibleName) + '" provide no context out of flow.',
						snippet: '<a href="' + escapeHtml(href) + '">' + escapeHtml(accessibleName) + '</a>',
						suggestion: 'Provide specific link text (e.g. "Read the Full Wildfire Action Plan" instead of "' + escapeHtml(accessibleName) + '").',
						selector: "a",
						index: idx,
						quickFixType: "locate"
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
						message: "Assistive technologies read raw URLs character by character.",
						snippet: '<a href="' + escapeHtml(href) + '">' + escapeHtml(accessibleName.substring(0, 35)) + '...</a>',
						suggestion: "Replace raw URL text with a human-readable title describing the target destination.",
						selector: "a",
						index: idx,
						quickFixType: "locate"
					});
				}
			}

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
						message: 'Link opens in new tab without an audible indication like "(opens in a new tab)".',
						snippet: '<a href="' + escapeHtml(href) + '" target="_blank">' + escapeHtml(text || "Link") + '</a>',
						suggestion: 'Add an aria-label with "(opens in a new tab)" to notify assistive tech users.',
						selector: "a",
						index: idx,
						quickFixType: "add-new-tab-notice"
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
						message: 'External new-tab link lacks rel="noopener noreferrer".',
						snippet: '<a href="' + escapeHtml(href) + '" target="_blank">',
						suggestion: 'Add rel="noopener noreferrer" to external new-tab hyperlinks.',
						selector: "a",
						index: idx,
						quickFixType: "add-noopener"
					});
				}
			}
		});

		// --- Rule Group 5: Tables (WCAG 1.3.1 Info and Relationships) ---
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
						message: 'One or more <th> cells lack scope="col" or scope="row".',
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
					message: "Tables should include a caption or accessible label summarizing data.",
					snippet: "<table> (Table #" + (idx + 1) + ")",
					suggestion: "Add a <caption> element or aria-label describing table contents.",
					selector: "table",
					index: idx,
					quickFixType: "locate"
				});
			}
		});

		// --- Rule Group 6: Readability, Styling & Headline ---
		var titleInput = document.getElementById("articleTitle");
		var headlineVal = titleInput ? titleInput.value.trim() : "";
		if (!headlineVal || headlineVal.length < 5) {
			criticalCount++;
			catCounts.headings++;
			issues.push({
				id: "meta-article-title",
				category: "headings",
				severity: "error",
				rule: "WCAG 2.4.2 (Page Titled)",
				title: "Missing or Incomplete Article Headline",
				message: "Articles must have a descriptive headline explaining their topic for citizens and screen readers.",
				snippet: '<input id="articleTitle" value="' + escapeHtml(headlineVal) + '">',
				suggestion: "Provide an informative headline for this news story.",
				selector: "#articleTitle",
				index: 0,
				quickFixType: "focus-input",
				meta: { inputId: "articleTitle" }
			});
		}

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
					message: 'Element specifies a pale or low-contrast text color inline (' + escapeHtml(styleStr) + '). On white backgrounds, this fails the 4.5:1 ratio.',
					snippet: '<' + el.tagName.toLowerCase() + ' style="' + escapeHtml(styleStr) + '">' + escapeHtml((el.textContent || "").substring(0, 30)) + '</' + el.tagName.toLowerCase() + '>',
					suggestion: "Remove inline color styles to maintain high standard text contrast.",
					selector: "[style*='color']",
					index: idx,
					quickFixType: "remove-style-color"
				});
			}
		});

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
						message: "Passages of ALL-CAPS text are difficult for users with dyslexia or low vision to decipher.",
						snippet: '<p>' + escapeHtml(txt.substring(0, 50)) + '...</p>',
						suggestion: "Use sentence case with bold emphasis rather than all-uppercase text.",
						selector: "p, div, span, li",
						index: idx,
						quickFixType: "to-sentence-case"
					});
				}
			}
		});

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
				message: "Using empty <p>&nbsp;</p> tags for visual spacing creates repetitive blank pauses for screen readers.",
				snippet: "<p>&nbsp;</p> (x" + spacerCount + ")",
				suggestion: "Remove empty spacer paragraphs and use CSS spacing.",
				selector: "p",
				index: 0,
				quickFixType: "remove-empty-spacers"
			});
		}

		var metaDescInput = document.getElementById("metaDescription");
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
				selector: "#metaDescription",
				index: 0,
				quickFixType: "focus-input",
				meta: { inputId: "metaDescription" }
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
		var bar = document.getElementById("articleA11yLinterBar");
		var overallBadge = document.getElementById("articleA11yOverallBadge");
		var issueCountBadge = document.getElementById("articleA11yIssueBadge");

		if (bar) {
			bar.classList.remove("is-passed", "has-warnings", "has-errors");
			if (res.criticalCount > 0) {
				bar.classList.add("has-errors");
			} else if (res.warningCount > 0) {
				bar.classList.add("has-warnings");
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
				var hasCrit = res.issues.some(function(i) { return i.category === catKey && i.severity === "error"; });
				if (hasCrit) {
					chipEl.classList.add("has-error");
				} else if (count > 0) {
					chipEl.classList.add("has-warn");
				}
			}
		});

		// 3. Update Sidebar Publish Card Scorecard
		var pubBadge = document.getElementById("articleA11yPublishBadge");
		var pubSummary = document.getElementById("articleA11yPublishSummary");
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
				pubSummary.innerHTML = '<span style="color:#b91c1c; font-weight:600;">' + res.criticalCount + ' critical barrier' + (res.criticalCount === 1 ? '' : 's') + ' detected.</span> Review recommended before publishing.';
			} else if (res.warningCount > 0) {
				pubSummary.innerHTML = '<span style="color:#b45309; font-weight:600;">Compliant with ' + res.warningCount + ' best-practice recommendation' + (res.warningCount === 1 ? '' : 's') + '.</span>';
			} else {
				pubSummary.textContent = "Article ready for public release. Meets ADA WCAG 2.1 AA.";
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
		var listEl = document.getElementById("articleA11yIssuesList");
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
					'<span>No accessibility barriers detected across cover media, story visuals, headings, links, tables, or text readability.</span>' +
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
			html += '    <button type="button" class="btn btn-outline btn-xs" onclick="window.ArticleA11yLinter.locateIssue(\'' + issue.id + '\')" title="Scroll to and highlight this item">';
			html += '      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:3px;"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>';
			html += '      <span>Locate in Editor</span>';
			html += '    </button>';

			if (issue.quickFixType) {
				html += '    <button type="button" class="btn btn-primary btn-xs" onclick="window.ArticleA11yLinter.applyQuickFix(\'' + issue.id + '\')" style="background:var(--admin-primary);">';
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
		var inlineEl = document.getElementById("articleA11yPublishInlineList");
		var pubBadge = document.getElementById("articleA11yPublishBadge");
		var pubSummary = document.getElementById("articleA11yPublishSummary");

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
				pubSummary.innerHTML = '<span style="color:#b91c1c; font-weight:600;">' + critCount + ' critical barrier' + (critCount === 1 ? '' : 's') + ' detected.</span> Review recommended before publishing.';
			} else if (warnCount > 0) {
				pubSummary.innerHTML = '<span style="color:#b45309; font-weight:600;">Compliant with ' + warnCount + ' best-practice recommendation' + (warnCount === 1 ? '' : 's') + '.</span>';
			} else {
				pubSummary.textContent = "Article ready for public release. Meets ADA WCAG 2.1 AA.";
			}
		}

		// Update Inspect Diagnostics link text to match exact live issue count
		var lnkText = document.getElementById("lnkInspectArticleA11yText");
		var drawer = document.getElementById("articleA11yIssuesDrawer");
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
			inlineHtml += '    <button type="button" class="btn btn-outline btn-xs" style="padding:0.15rem 0.45rem; font-size:0.68rem;" onclick="window.ArticleA11yLinter.locateIssue(\'' + issue.id + '\')">Locate</button>';
			if (issue.quickFixType) {
				inlineHtml += '    <button type="button" class="btn btn-primary btn-xs" style="padding:0.15rem 0.45rem; font-size:0.68rem; background:var(--admin-primary);" onclick="window.ArticleA11yLinter.applyQuickFix(\'' + issue.id + '\')">Quick Fix</button>';
			}
			inlineHtml += '  </div>';
			inlineHtml += '</div>';
		});
		inlineEl.innerHTML = inlineHtml;
	}

	function locateIssue(issueId) {
		var issue = _lastResults.issues.find(function(i) { return i.id === issueId; });
		if (!issue) return;

		if (issue.meta && issue.meta.inputId) {
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
			var ta = document.getElementById("articleContent");
			if (ta) ta.scrollIntoView({ behavior: "smooth", block: "center" });
			return;
		}

		var targets = ed.contentArea.querySelectorAll(issue.selector);
		var targetNode = targets[issue.index] || targets[0];

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

		if (issue.quickFixType === "focus-input" && issue.meta && issue.meta.inputId) {
			locateIssue(issueId);
			return;
		}

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

		if (!contentArea && issue.quickFixType !== "focus-input") {
			locateIssue(issueId);
			return;
		}

		var targets = contentArea ? contentArea.querySelectorAll(issue.selector) : [];
		var targetNode = targets[issue.index] || targets[0];

		switch (issue.quickFixType) {
			case "set-alt-decorative":
				if (targetNode) {
					targetNode.setAttribute("alt", "");
					targetNode.setAttribute("role", "presentation");
					syncChanges();
				}
				break;

			case "change-heading":
				if (targetNode) {
					var newTag = (issue.meta && issue.meta.targetTag) ? issue.meta.targetTag : "h2";
					var replacement = document.createElement(newTag);
					replacement.innerHTML = targetNode.innerHTML;
					Array.from(targetNode.attributes).forEach(function(attr) {
						replacement.setAttribute(attr.name, attr.value);
					});
					targetNode.parentNode.replaceChild(replacement, targetNode);
					syncChanges();
				}
				break;

			case "remove-element":
				if (targetNode) {
					targetNode.remove();
					syncChanges();
				}
				break;

			case "add-new-tab-notice":
				if (targetNode) {
					var currentAria = targetNode.getAttribute("aria-label") || (targetNode.textContent || "").trim();
					var noticeText = currentAria ? (currentAria + " (opens in a new tab)") : "Link (opens in a new tab)";
					targetNode.setAttribute("aria-label", noticeText);
					if (!targetNode.getAttribute("rel") || targetNode.getAttribute("rel").indexOf("noopener") === -1) {
						targetNode.setAttribute("rel", "noopener noreferrer");
					}
					syncChanges();
				}
				break;

			case "add-noopener":
				if (targetNode) {
					var curRel = (targetNode.getAttribute("rel") || "").trim();
					var parts = curRel ? curRel.split(/\s+/) : [];
					if (parts.indexOf("noopener") === -1) parts.push("noopener");
					if (parts.indexOf("noreferrer") === -1) parts.push("noreferrer");
					targetNode.setAttribute("rel", parts.join(" "));
					syncChanges();
				}
				break;

			case "convert-table-headers":
				if (targetNode) {
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
				}
				break;

			case "add-th-scopes":
				if (targetNode) {
					var thList = targetNode.querySelectorAll("th");
					thList.forEach(function(th) {
						if (!th.hasAttribute("scope")) {
							th.setAttribute("scope", "col");
						}
					});
					syncChanges();
				}
				break;

			case "remove-style-color":
				if (targetNode) {
					targetNode.style.color = "";
					if (!targetNode.getAttribute("style") || !targetNode.getAttribute("style").trim()) {
						targetNode.removeAttribute("style");
					}
					syncChanges();
				}
				break;

			case "to-sentence-case":
				if (targetNode) {
					var rawText = targetNode.textContent || "";
					var converted = rawText.charAt(0).toUpperCase() + rawText.slice(1).toLowerCase();
					targetNode.textContent = converted;
					syncChanges();
				}
				break;

			case "remove-empty-spacers":
				if (contentArea) {
					var paras = contentArea.querySelectorAll("p");
					paras.forEach(function(p) {
						var ih = p.innerHTML.trim();
						if (ih === "" || ih === "&nbsp;" || ih === "<br>" || ih === "<br/>") {
							p.remove();
						}
					});
					syncChanges();
				}
				break;

			default:
				locateIssue(issueId);
				break;
		}
	}

	function syncDrawerState(isOpen) {
		var drawer = document.getElementById("articleA11yIssuesDrawer");
		var toggleBtn = document.getElementById("btnToggleA11yDrawer");
		var inlineList = document.getElementById("articleA11yPublishInlineList");
		var lnkInspect = document.getElementById("lnkInspectArticleA11y");
		var lnkText = document.getElementById("lnkInspectArticleA11yText");
		var lnkChevron = document.getElementById("lnkInspectArticleA11yChevron");

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
		var drawer = document.getElementById("articleA11yIssuesDrawer");
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
		var drawer = document.getElementById("articleA11yIssuesDrawer");
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

		var tabs = ["tabA11yAll", "tabA11yErrors", "tabA11yWarnings"];
		tabs.forEach(function(tid) {
			var el = document.getElementById(tid);
			if (el) {
				if ((tid === "tabA11yAll" && filterName === "all") ||
				    (tid === "tabA11yErrors" && filterName === "errors") ||
				    (tid === "tabA11yWarnings" && filterName === "warnings")) {
					el.classList.add("is-active-filter");
				} else {
					el.classList.remove("is-active-filter");
				}
			}
		});

		openDrawer();
	}

	function scheduleScan() {
		if (_scanDebounceTimer) clearTimeout(_scanDebounceTimer);
		_scanDebounceTimer = setTimeout(function() {
			scan();
		}, 250);
	}

	function init() {
		var ta = document.getElementById("articleContent");
		if (ta) {
			ta.addEventListener("input", scheduleScan);
			ta.addEventListener("change", scheduleScan);
		}

		var titleInput = document.getElementById("articleTitle");
		if (titleInput) titleInput.addEventListener("input", scheduleScan);

		var featImg = document.getElementById("featuredImage");
		if (featImg) featImg.addEventListener("input", scheduleScan);

		var featAlt = document.getElementById("featuredImageAlt");
		if (featAlt) featAlt.addEventListener("input", scheduleScan);

		var featDec = document.getElementById("featuredImageDecorative");
		if (featDec) featDec.addEventListener("change", scheduleScan);

		var metaDesc = document.getElementById("metaDescription");
		if (metaDesc) metaDesc.addEventListener("input", scheduleScan);

		var statSelect = document.getElementById("articleStatus");
		if (statSelect) statSelect.addEventListener("change", scheduleScan);

		// Bind editor readiness and reactive input listeners
		bindEditorEvents();

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

	return {
		scan: scan,
		getResults: function() { return _lastResults; },
		openDrawer: openDrawer,
		closeDrawer: closeDrawer,
		toggleDrawer: toggleDrawer,
		setFilter: setFilter,
		locateIssue: locateIssue,
		applyQuickFix: applyQuickFix,
		init: init
	};
})();

async function saveArticleForm() {
	const title = document.getElementById('articleTitle').value.trim();
	if (!title) {
		window.adminAlert({ title: 'Headline Required', message: 'Please enter an article headline/title.', type: 'warning' });
		document.getElementById('articleTitle').focus();
		return;
	}

	// Fetch rich text content from JBDEditor if attached
	let contentHtml = '';
	const textarea = document.getElementById('articleContent');
	if (typeof JBDEditor !== 'undefined' && JBDEditor.get && JBDEditor.get(textarea)) {
		contentHtml = JBDEditor.get(textarea).getHTML();
	} else {
		contentHtml = textarea.value.trim();
	}

	if (!contentHtml || contentHtml.length === 0) {
		window.adminAlert({ title: 'Body Required', message: 'Please provide content body for the article.', type: 'warning' });
		return;
	}

	// Feature: In-Editor Automated ADA WCAG Pre-Flight Quality Gate
	if (typeof window.ArticleA11yLinter !== 'undefined') {
		const linterResults = window.ArticleA11yLinter.scan();
		const currentStatus = (document.getElementById('articleStatus') ? document.getElementById('articleStatus').value : 'published');

		if (linterResults && linterResults.criticalCount > 0 && currentStatus === 'published') {
			if (typeof window.adminConfirm === 'function') {
				const proceed = await window.adminConfirm({
					title: 'ADA Pre-Flight Quality Gate',
					message: 'This article contains ' + linterResults.criticalCount + ' critical ADA / WCAG 2.1 AA accessibility violation' +
						(linterResults.criticalCount === 1 ? '' : 's') + ' (such as missing image alt text, empty headings, or unlabelled links).\n\n' +
						'Under ADA Title II public agency requirements, published public information must be accessible to individuals with disabilities.\n\n' +
						'Do you want to review and address these issues in the Pre-Flight drawer before publishing, or proceed anyway?',
					type: 'warning',
					acceptText: 'Publish Anyway',
					cancelText: 'Review in Drawer'
				});
				if (!proceed) {
					window.ArticleA11yLinter.openDrawer();
					const drawer = document.getElementById('articleA11yIssuesDrawer');
					if (drawer) drawer.scrollIntoView({ behavior: 'smooth', block: 'center' });
					return;
				}
			}
		}
	}

	const btnTop = document.getElementById('btnSaveTop');
	const btnSide = document.getElementById('btnSaveSidebar');
	if (btnTop) btnTop.disabled = true;
	if (btnSide) btnSide.disabled = true;

	const featImg = (document.getElementById('featuredImage') ? document.getElementById('featuredImage').value : '').trim();
	const isDec = document.getElementById('featuredImageDecorative') ? document.getElementById('featuredImageDecorative').checked : false;
	const featAlt = (document.getElementById('featuredImageAlt') ? document.getElementById('featuredImageAlt').value : '').trim();

	const payload = {
		id: parseInt(document.getElementById('articleId').value || '0', 10),
		title: title,
		slug: document.getElementById('articleSlug').value.trim(),
		summary: document.getElementById('articleSummary').value.trim(),
		content_html: contentHtml,
		category_id: parseInt(document.getElementById('categoryId').value || '0', 10),
		tags: document.getElementById('articleTags').value.trim(),
		featured_image: featImg,
		featured_image_alt: featAlt,
		featured_image_caption: (document.getElementById('featuredImageCaption') ? document.getElementById('featuredImageCaption').value : '').trim(),
		featured_image_description: (document.getElementById('featuredImageDescription') ? document.getElementById('featuredImageDescription').value : '').trim(),
		featured_image_credit: (document.getElementById('featuredImageCredit') ? document.getElementById('featuredImageCredit').value : '').trim(),
		featured_image_decorative: isDec ? 1 : 0,
		author_name: document.getElementById('authorName').value.trim(),
		author_title: document.getElementById('authorTitle').value.trim(),
		status: document.getElementById('articleStatus').value,
		siteid: document.getElementById('siteid').value,
		published_at: document.getElementById('publishedAt').value,
		unpublish_at: (document.getElementById('unpublishAt') ? document.getElementById('unpublishAt').value : ''),
		meta_title: document.getElementById('metaTitle').value.trim(),
		meta_description: document.getElementById('metaDescription').value.trim()
	};

	let csrfToken = '';
	const metaCsrf = document.querySelector('meta[name="csrf-token"]');
	if (metaCsrf) csrfToken = metaCsrf.getAttribute('content') || '';

	fetch('/articles/save', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'X-Requested-With': 'XMLHttpRequest',
			'X-CSRF-Token': csrfToken
		},
		body: JSON.stringify(payload)
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			window.location.href = res.data && res.data.redirect ? res.data.redirect : '/articles';
		} else {
			window.adminAlert({ title: 'Error Saving Article', message: res.message || 'Error saving article.', type: 'danger' });
			if (btnTop) btnTop.disabled = false;
			if (btnSide) btnSide.disabled = false;
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error while saving article.', type: 'danger' });
		if (btnTop) btnTop.disabled = false;
		if (btnSide) btnSide.disabled = false;
	});
}

// Initial ADA checks on page load
if (document.readyState === 'loading') {
	document.addEventListener('DOMContentLoaded', function() {
		updateAdaComplianceStatus();
		window.ArticleA11yLinter.init();
	});
} else {
	updateAdaComplianceStatus();
	window.ArticleA11yLinter.init();
}
</script>
