<cfoutput>
<cfscript>
	if (!StructKeyExists(variables, "page") || !IsStruct(variables.page)) {
		variables.page = {};
	}
	if (!StructKeyExists(variables.page, "sidebarIds") || !IsArray(variables.page.sidebarIds)) {
		variables.page.sidebarIds = IsSimpleValue(variables.page.sidebarIds ?: "") && Len(Trim(variables.page.sidebarIds ?: "")) ? ListToArray(variables.page.sidebarIds) : [];
	}
	folderAttachedHere = false;
	for (folderCheck in availableFolders) {
		if (Val(folderCheck.contentId ?: 0) == Val(page.id)) { folderAttachedHere = true; break; }
	}
	editWsObj = resolveUserActiveWorkspace(requestedWs=(Len(editSiteId) ? editSiteId : (page.siteId ?: "")), role=getCurrentActiveRole());
	editDomain = (StructKeyExists(editWsObj, "domain_name") && Len(Trim(editWsObj.domain_name)))
		? Trim(editWsObj.domain_name)
		: "www.chelancounty.gov";
	if (!REFindNoCase("^https?://", editDomain)) editDomain = "https://" & editDomain;
	if (Right(editDomain, 1) == "/") editDomain = Left(editDomain, Len(editDomain) - 1);
	livePageUrl = editDomain & "/" & page.slug;
	editVDir = editWsObj.virtual_directory ?: ((page.siteId eq "global" || !Len(page.siteId)) ? "shared" : page.siteId);
</cfscript>
<!--- Chelan County CMSAdmin 2.0 - Add / Edit Page (v2 Branch Experience with Feature Accordions) --->
<style>
	/* Two-Column Grid */
	.pg-v2-grid {
		display: grid;
		grid-template-columns: minmax(0, 1fr) 400px;
		gap: 1.5rem;
		align-items: start;
	}
	@media (max-width: 1200px) {
		.pg-v2-grid {
			grid-template-columns: 1fr;
		}
	}

	.pg-v2-left-col {
		display: flex;
		flex-direction: column;
		gap: 1.25rem;
		min-width: 0;
	}

	.pg-v2-right-col {
		display: flex;
		flex-direction: column;
		gap: 1.25rem;
		position: sticky;
		top: calc(var(--header-height, 64px) + 1.25rem);
		z-index: 15;
	}
	@media (max-width: 1200px) {
		.pg-v2-right-col {
			position: static;
		}
	}

	/* Field Styles */
	.pg-field { margin-bottom: 1.15rem; }
	.pg-field:last-child { margin-bottom: 0; }
	.pg-help { font-size: 0.76rem; color: var(--admin-text-muted, ##64748b); margin-top: 0.35rem; line-height: 1.4; }

	.pg-slug-wrap {
		display: flex;
		align-items: center;
		border: 1.5px solid var(--admin-border-input, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		overflow: hidden;
		background: var(--admin-surface, ##ffffff);
		transition: border-color 0.15s ease;
	}
	.pg-slug-wrap:focus-within {
		border-color: var(--admin-primary, ##0284c7);
		box-shadow: 0 0 0 1px var(--admin-primary, ##0284c7);
	}
	.pg-slug-wrap span {
		padding: 0.5rem 0.75rem;
		background: var(--admin-bg, ##f8fafc);
		color: var(--admin-text-muted, ##64748b);
		font-size: 0.82rem;
		font-weight: 500;
		border-right: 1px solid var(--admin-border, ##cbd5e1);
		white-space: nowrap;
	}
	.pg-slug-wrap input {
		border: none !important;
		flex: 1;
		min-width: 0;
		box-shadow: none !important;
		padding: 0.5rem 0.75rem;
		font-size: 0.9rem;
	}

	/* Layout Choice Cards */
	.pg-layout-cards-grid {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 0.85rem;
		margin-top: 0.35rem;
	}
	@media (max-width: 640px) {
		.pg-layout-cards-grid { grid-template-columns: 1fr; }
	}
	.pg-layout-card {
		border: 2px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		padding: 0.85rem 1rem;
		cursor: pointer;
		background: var(--admin-surface, ##ffffff);
		transition: all 0.15s ease;
		display: flex;
		align-items: flex-start;
		gap: 0.75rem;
		text-align: left;
		position: relative;
	}
	.pg-layout-card:hover {
		border-color: var(--admin-border-hover, ##94a3b8);
		background: var(--admin-surface-hover, ##f8fafc);
	}
	.pg-layout-card.is-selected {
		border-color: var(--admin-primary, ##0284c7) !important;
		background: rgba(2, 132, 199, 0.04) !important;
		box-shadow: 0 0 0 1px var(--admin-primary, ##0284c7);
	}
	.pg-layout-wireframe {
		width: 44px;
		height: 38px;
		border-radius: 4px;
		border: 1.5px solid var(--admin-border, ##cbd5e1);
		background: var(--admin-bg, ##f1f5f9);
		padding: 3px;
		display: flex;
		gap: 2px;
		flex-shrink: 0;
	}
	.pg-layout-card.is-selected .pg-layout-wireframe {
		border-color: var(--admin-primary, ##0284c7);
	}
	.wf-body { flex: 1; background: ##cbd5e1; border-radius: 2px; }
	.wf-side { width: 10px; background: var(--admin-primary, ##0284c7); border-radius: 2px; opacity: 0.7; }

	/* Section Dividers */
	.pg-section-divider {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin: 1.5rem 0 1rem 0;
		padding-top: 1.25rem;
		border-top: 1px solid var(--admin-border-subtle, ##e2e8f0);
	}
	.pg-section-divider-title {
		font-size: 0.88rem;
		font-weight: 700;
		color: var(--admin-text-main, ##0f172a);
		display: flex;
		align-items: center;
		gap: 0.45rem;
		margin: 0;
	}

	/* LED Light Markers */
	.led-marker {
		display: inline-block;
		width: 11px;
		height: 11px;
		border-radius: 50%;
		background: ##94a3b8;
		border: 1px solid rgba(0, 0, 0, 0.08);
		flex-shrink: 0;
		transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
		position: relative;
	}
	.led-marker.is-active, .led-marker.is-online {
		background: ##10b981 !important;
		box-shadow: 0 0 0 2.5px rgba(16, 185, 129, 0.25), 0 0 10px ##10b981, 0 0 16px rgba(16, 185, 129, 0.4) !important;
	}
	.led-marker.is-warn {
		background: ##f59e0b !important;
		box-shadow: 0 0 0 2.5px rgba(245, 158, 11, 0.25), 0 0 10px ##f59e0b, 0 0 16px rgba(245, 158, 11, 0.4) !important;
	}
	.led-marker.is-error {
		background: ##ef4444 !important;
		box-shadow: 0 0 0 2.5px rgba(239, 68, 68, 0.25), 0 0 10px ##ef4444, 0 0 16px rgba(239, 68, 68, 0.4) !important;
	}
	.led-marker.is-inactive {
		background: ##cbd5e1 !important;
		opacity: 0.55;
		box-shadow: none !important;
	}

	@keyframes ledPulse {
		0% { transform: scale(1); }
		50% { transform: scale(1.18); }
		100% { transform: scale(1); }
	}
	.led-marker.is-active {
		animation: ledPulse 2.8s infinite ease-in-out;
	}

	/* =========================================================================
	   PAGE FEATURES ACCORDION
	   ========================================================================= */
	.pg-features-accordion {
		display: flex;
		flex-direction: column;
		gap: 0.55rem;
	}
	.pg-accordion-item {
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		background: var(--admin-surface, ##ffffff);
		overflow: hidden;
		transition: all 0.2s ease;
	}
	.pg-accordion-item.is-active-feature {
		border-color: rgba(2, 132, 199, 0.3);
	}
	.pg-accordion-item.is-open {
		border-color: var(--admin-primary, ##0284c7);
		box-shadow: 0 4px 14px rgba(15, 23, 42, 0.07);
	}
	.pg-accordion-header {
		width: 100%;
		padding: 0.75rem 0.85rem;
		background: var(--admin-surface, ##ffffff);
		border: none;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.65rem;
		cursor: pointer;
		text-align: left;
		transition: background 0.15s ease;
		outline: none;
	}
	.pg-accordion-header:hover {
		background: var(--admin-surface-hover, ##f8fafc);
	}
	.pg-accordion-header:focus-visible {
		outline: 2px solid var(--admin-primary, ##0284c7);
		outline-offset: -2px;
	}
	.pg-accordion-item.is-open .pg-accordion-header {
		background: var(--admin-bg, ##f8fafc);
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
	}
	.pg-accordion-info {
		display: flex;
		align-items: center;
		gap: 0.65rem;
		min-width: 0;
		flex: 1;
	}
	.pg-accordion-icon-wrap {
		width: 32px;
		height: 32px;
		border-radius: var(--radius-sm, 0.375rem);
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
		background: var(--admin-bg, ##f1f5f9);
		color: var(--admin-text-main, ##0f172a);
		transition: all 0.15s ease;
	}
	.pg-accordion-header:hover .pg-accordion-icon-wrap,
	.pg-accordion-item.is-open .pg-accordion-icon-wrap {
		background: rgba(2, 132, 199, 0.1);
		color: var(--admin-primary, ##0284c7);
	}
	.pg-accordion-texts {
		min-width: 0;
		flex: 1;
	}
	.pg-accordion-title {
		font-size: 0.85rem;
		font-weight: 700;
		color: var(--admin-text-main, ##0f172a);
		display: flex;
		align-items: center;
		gap: 0.35rem;
	}
	.pg-accordion-desc {
		font-size: 0.72rem;
		color: var(--admin-text-muted, ##64748b);
		margin-top: 0.12rem;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.pg-accordion-chevron {
		color: var(--admin-text-muted, ##64748b);
		display: inline-flex;
		align-items: center;
		justify-content: center;
		transition: transform 0.22s cubic-bezier(0.4, 0, 0.2, 1);
		flex-shrink: 0;
	}
	.pg-accordion-item.is-open .pg-accordion-chevron {
		transform: rotate(180deg);
		color: var(--admin-primary, ##0284c7);
	}
	.pg-accordion-body {
		padding: 1rem 0.95rem;
		background: var(--admin-surface, ##ffffff);
		display: none;
	}
	.pg-accordion-item.is-open .pg-accordion-body {
		display: block;
		animation: accordionFadeIn 0.18s ease;
	}
	@keyframes accordionFadeIn {
		from { opacity: 0; transform: translateY(-4px); }
		to { opacity: 1; transform: translateY(0); }
	}

	/* =========================================================================
	   PAGE FEATURES DECK — QUICK-GUIDE HOVER TOOLTIP ("FOR DUMMIES")
	   ========================================================================= */
	.pg-feature-help-pill {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 16px;
		height: 16px;
		border-radius: 999px;
		background: var(--admin-bg, ##e2e8f0);
		color: var(--admin-text-muted, ##64748b);
		font-size: 0.65rem;
		font-weight: 800;
		line-height: 1;
		margin-left: 0.25rem;
		border: 1px solid var(--admin-border, ##cbd5e1);
		transition: all 0.15s ease;
		flex-shrink: 0;
	}
	.pg-accordion-header:hover .pg-feature-help-pill,
	.pg-accordion-header:focus-visible .pg-feature-help-pill,
	.btn:hover .pg-feature-help-pill,
	.btn:focus-visible .pg-feature-help-pill {
		background: var(--admin-primary, ##0284c7);
		color: ##ffffff;
		border-color: var(--admin-primary, ##0284c7);
		transform: scale(1.08);
	}
	.pg-feature-quick-tooltip {
		position: fixed;
		z-index: 99999;
		width: 325px;
		max-width: calc(100vw - 24px);
		background: ##0f172a;
		color: ##f8fafc;
		border: 1px solid ##334155;
		border-radius: 0.65rem;
		box-shadow: 0 18px 38px rgba(15, 23, 42, 0.42), 0 4px 12px rgba(15, 23, 42, 0.25);
		padding: 0.85rem 0.95rem;
		pointer-events: none;
		opacity: 0;
		transform: translateX(6px) scale(0.98);
		transition: opacity 0.15s ease, transform 0.15s ease;
		font-size: 0.78rem;
		line-height: 1.4;
		visibility: hidden;
	}
	.pg-feature-quick-tooltip.is-visible {
		opacity: 1;
		transform: translateX(0) scale(1);
		visibility: visible;
	}
	.pg-feature-quick-tooltip::after {
		content: "";
		position: absolute;
		top: var(--tt-arrow-top, 24px);
		right: -6px;
		width: 11px;
		height: 11px;
		background: ##0f172a;
		border-top: 1px solid ##334155;
		border-right: 1px solid ##334155;
		transform: translateY(-50%) rotate(45deg);
	}
	.pg-feature-quick-tooltip.is-below::after {
		top: -6px;
		right: auto;
		left: var(--tt-arrow-left, 28px);
		transform: translateX(-50%) rotate(-45deg);
	}
	.pg-feature-quick-tooltip.is-above::after {
		top: auto;
		bottom: -6px;
		right: auto;
		left: var(--tt-arrow-left, 28px);
		transform: translateX(-50%) rotate(135deg);
	}
	.pg-ft-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.5rem;
		padding-bottom: 0.5rem;
		margin-bottom: 0.55rem;
		border-bottom: 1px solid ##1e293b;
	}
	.pg-ft-title {
		font-size: 0.86rem;
		font-weight: 800;
		color: ##ffffff;
		letter-spacing: -0.01em;
	}
	.pg-ft-tag {
		font-size: 0.62rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		padding: 0.12rem 0.42rem;
		border-radius: 999px;
		background: rgba(56, 189, 248, 0.16);
		color: ##38bdf8;
		border: 1px solid rgba(56, 189, 248, 0.3);
		white-space: nowrap;
	}
	.pg-ft-section {
		margin-bottom: 0.55rem;
	}
	.pg-ft-section:last-child {
		margin-bottom: 0;
	}
	.pg-ft-label {
		font-size: 0.65rem;
		font-weight: 800;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: ##38bdf8;
		margin-bottom: 0.22rem;
		display: flex;
		align-items: center;
		gap: 0.3rem;
	}
	.pg-ft-what {
		color: ##e2e8f0;
		font-size: 0.79rem;
		background: ##1e293b;
		padding: 0.42rem 0.55rem;
		border-radius: 0.4rem;
		border-left: 3px solid ##38bdf8;
	}
	.pg-ft-steps {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 0.3rem;
	}
	.pg-ft-steps li {
		display: flex;
		align-items: flex-start;
		gap: 0.45rem;
		color: ##cbd5e1;
		font-size: 0.76rem;
	}
	.pg-ft-step-num {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 17px;
		height: 17px;
		border-radius: 999px;
		background: ##0284c7;
		color: ##ffffff;
		font-size: 0.66rem;
		font-weight: 800;
		flex-shrink: 0;
		margin-top: 0.05rem;
	}
	.pg-ft-steps strong {
		color: ##ffffff;
		font-weight: 700;
	}
	.pg-ft-lights {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4rem 0.65rem;
		background: rgba(15, 23, 42, 0.6);
		border: 1px solid ##1e293b;
		border-radius: 0.4rem;
		padding: 0.38rem 0.55rem;
		font-size: 0.7rem;
		color: ##94a3b8;
	}
	.pg-ft-light-item {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
	}
	.pg-ft-dot {
		width: 7px;
		height: 7px;
		border-radius: 999px;
		display: inline-block;
	}
	.pg-ft-dot.is-green { background: ##10b981; box-shadow: 0 0 6px ##10b981; }
	.pg-ft-dot.is-yellow { background: ##f59e0b; box-shadow: 0 0 6px ##f59e0b; }
	.pg-ft-dot.is-gray { background: ##64748b; }

	/* ADA Pre-Flight Linter Bar */
	.pg-a11y-linter-bar {
		background: var(--admin-surface, ##ffffff);
		border: 1.5px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem) var(--radius-md, 0.5rem) 0 0;
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
		margin-bottom: 0;
		overflow: hidden;
		transition: all 0.2s ease;
	}
	.pg-a11y-linter-bar.is-passed { border-color: var(--admin-border, ##cbd5e1); background: var(--admin-surface, ##ffffff); }
	.pg-a11y-linter-bar.has-warnings { border-color: ##f59e0b; background: ##fffdfa; }
	.pg-a11y-linter-bar.has-errors { border-color: ##ef4444; background: ##fef8f8; }
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
	.pg-a11y-bar-icon { color: var(--admin-primary, ##0284c7); display: inline-flex; }
	.pg-a11y-bar-title { font-size: 0.84rem; font-weight: 700; color: var(--admin-text-main, ##0f172a); }
	.pg-a11y-standard-badge {
		font-size: 0.68rem;
		font-weight: 700;
		padding: 0.1rem 0.35rem;
		border-radius: 3px;
		background: var(--admin-bg, ##f1f5f9);
		color: var(--admin-text-muted, ##475569);
		border: 1px solid var(--admin-border-subtle, ##e2e8f0);
	}
	.pg-a11y-category-chips { display: flex; align-items: center; gap: 0.35rem; flex-wrap: wrap; }
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
	.pg-a11y-chip:hover { background: var(--admin-surface, ##ffffff); border-color: var(--admin-border-hover, ##94a3b8); color: var(--admin-text-main, ##0f172a); }
	.pg-a11y-chip.is-active-filter { background: rgba(2, 132, 199, 0.1); border-color: var(--admin-primary, ##0284c7); color: var(--admin-primary, ##0284c7); }
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
	.pg-a11y-chip.has-error { border-color: ##fca5a5; background: ##fef2f2; color: ##b91c1c; }
	.pg-a11y-chip.has-error .chip-count { background: ##ef4444; color: ##ffffff; }
	.pg-a11y-chip.has-warn { border-color: ##fde68a; background: ##fffbeb; color: ##b45309; }
	.pg-a11y-chip.has-warn .chip-count { background: ##f59e0b; color: ##ffffff; }

	.pg-a11y-drawer {
		border-top: 1px solid var(--admin-border-subtle, ##e2e8f0);
		background: var(--admin-surface, ##ffffff);
		padding: 0.85rem 1rem;
		max-height: 440px;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}
	.pg-a11y-drawer[hidden] { display: none !important; }
	.pg-a11y-drawer-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 0.65rem; border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0); }
	.pg-a11y-issues-list { display: flex; flex-direction: column; gap: 0.65rem; }
	.pg-a11y-issue-card {
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 0.5rem);
		padding: 0.75rem 0.85rem;
		background: var(--admin-surface, ##ffffff);
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
	}
	.pg-a11y-issue-card.is-error { border-left: 4px solid ##ef4444; background: ##fffbfb; }
	.pg-a11y-issue-card.is-warn { border-left: 4px solid ##f59e0b; background: ##fffdf9; }
	.pg-a11y-rule-tag { font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; padding: 0.12rem 0.45rem; border-radius: 3px; }
	.pg-a11y-rule-tag.error { background: ##fee2e2; color: ##b91c1c; }
	.pg-a11y-rule-tag.warn { background: ##fef3c7; color: ##b45309; }

	/* Document Dropzone */
	.pg-doc-drop-zone-wrap { position: relative; }
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
		pointer-events: none;
	}
	.pg-doc-drop-overlay.is-active { display: flex; }
	.pg-doc-drop-inner { display: flex; flex-direction: column; align-items: center; gap: 0.45rem; max-width: 440px; }
	.pg-doc-drop-icon {
		width: 50px;
		height: 50px;
		border-radius: 50%;
		background: rgba(2, 132, 199, 0.12);
		color: var(--admin-primary, ##0284c7);
		display: flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 0.25rem;
	}

	/* Subpage Modal */
	.pg-subpage-modal { position: fixed; inset: 0; z-index: 99999; display: none; align-items: center; justify-content: center; padding: 1rem; }
	.pg-subpage-modal.is-open { display: flex; }
	.pg-subpage-backdrop { position: absolute; inset: 0; background: rgba(15, 23, 42, 0.72); backdrop-filter: blur(6px); -webkit-backdrop-filter: blur(6px); }
	.pg-subpage-window { position: relative; width: min(100%, 780px); max-height: min(92vh, 850px); overflow: auto; background: var(--admin-surface); border: 1px solid var(--admin-border); border-radius: var(--radius-lg); box-shadow: 0 25px 65px rgba(15, 23, 42, 0.35); }
	.pg-subpage-row { display: flex; align-items: center; gap: 0.65rem; padding: 0.55rem 0; border-bottom: 1px solid var(--admin-border-subtle); }
	.fe-layout-card { border: 2px solid var(--admin-border, ##cbd5e1); border-radius: var(--radius-md, 0.5rem); padding: 0.85rem; cursor: pointer; background: var(--admin-surface, ##ffffff); transition: all 0.15s ease; outline: none; }
	.fe-layout-card:hover { border-color: var(--admin-border-hover, ##94a3b8); }
	.fe-layout-card:focus-visible { outline: 2px solid var(--admin-primary) !important; outline-offset: 2px !important; }
	.fe-layout-card.is-selected { border-color: var(--admin-primary) !important; background: rgba(30, 58, 138, 0.04) !important; box-shadow: 0 0 0 1px var(--admin-primary); }

	/* Revision History & Rollback Studio Modal Styles */
	.rev-layout {
		display: flex;
		flex: 1;
		min-height: 0;
		overflow: hidden;
		background: var(--admin-bg, ##f8fafc);
	}
	.rev-sidebar {
		width: 320px;
		flex-shrink: 0;
		border-right: 1px solid var(--admin-border-subtle, ##e2e8f0);
		background: var(--admin-surface, ##ffffff);
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	.rev-sidebar-header {
		padding: 0.75rem 1rem;
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
		background: var(--admin-bg, ##f8fafc);
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-shrink: 0;
	}
	.rev-list {
		flex: 1;
		overflow-y: auto;
		padding: 0.5rem;
		display: flex;
		flex-direction: column;
		gap: 0.4rem;
	}
	.rev-item-card {
		width: 100%;
		text-align: left;
		padding: 0.65rem 0.85rem;
		border-radius: var(--radius-md, 6px);
		border: 1px solid var(--admin-border-subtle, ##e2e8f0);
		background: var(--admin-surface, ##ffffff);
		cursor: pointer;
		transition: all 0.15s ease;
		display: flex;
		flex-direction: column;
		gap: 0.2rem;
		font-family: inherit;
	}
	.rev-item-card:hover {
		border-color: var(--admin-border-hover, ##94a3b8);
		background: var(--admin-surface-hover, ##f8fafc);
	}
	.rev-item-card.is-active {
		border-color: var(--admin-primary, ##0284c7) !important;
		background: rgba(2, 132, 199, 0.06) !important;
		box-shadow: 0 0 0 1px var(--admin-primary, ##0284c7);
	}
	.rev-item-version {
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 0.82rem;
		font-weight: 700;
		color: var(--admin-text-main, ##0f172a);
	}
	.rev-item-meta {
		display: flex;
		align-items: center;
		gap: 0.35rem;
		font-size: 0.7rem;
		color: var(--admin-text-muted, ##64748b);
	}
	.rev-item-note {
		font-size: 0.74rem;
		color: var(--admin-text-main, ##334155);
		font-style: italic;
		line-height: 1.35;
		margin-top: 0.15rem;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
	.rev-stage {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		overflow: hidden;
		background: var(--admin-surface, ##ffffff);
	}
	.rev-stage-toolbar {
		padding: 0.65rem 1rem;
		border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
		background: var(--admin-surface, ##ffffff);
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 0.5rem;
		flex-shrink: 0;
	}
	.rev-stage-body {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		padding: 1.25rem;
		background: var(--admin-bg, ##f8fafc);
	}
	.diff-pane {
		background: var(--admin-surface, ##ffffff);
		border: 1px solid var(--admin-border, ##cbd5e1);
		border-radius: var(--radius-md, 6px);
		padding: 1.25rem;
		min-height: 100%;
		font-size: 0.9rem;
		line-height: 1.6;
	}
</style>

<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.55rem;">
			<h1 class="page-title" style="margin-bottom:0;">#isNew ? "Add Page" : "Edit Page"#</h1>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='pages', action='index')#">Page Editor</a></li>
				<li class="breadcrumb-item active" aria-current="page" id="pgBreadcrumbTitle">#isNew ? "Add Page" : EncodeForHTML(page.title)#</li>
			</ol>
		</nav>
	</div>
	<div class="page-actions">
		<a href="#urlFor(controller='pages', action='index')#" class="btn btn-outline btn-sm">
			#svgIcon(name="list", size=14)#
			<span>Page Editor</span>
		</a>
		<cfif not isNew>
			<a href="#EncodeForHTMLAttribute(livePageUrl)#" id="btnViewLivePageTop" target="_blank" rel="noopener" class="btn btn-secondary btn-sm" title="View live page on #EncodeForHTMLAttribute(editDomain)#">
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
			<strong>Page created &amp; saved to database:</strong> &ldquo;<strong>#EncodeForHTML(page.title)#</strong>&rdquo; (ID: #Val(page.id)#) with <strong>#EncodeForHTML(page.layout)#</strong> layout.
		</div>
	</div>
</cfif>

<form id="pageEditForm" class="pg-v2-grid" novalidate onsubmit="return false;">
	<input type="hidden" id="pgContentId" name="contentId" value="#Val(page.id)#">
	<input type="hidden" id="pgSiteId" name="siteId" value="#EncodeForHTMLAttribute(page.siteId ?: activeWorkspaceId())#">

	<!--- =========================================================================
	      LEFT PANEL: Page Title, Page URL, Page Layout, Page Content, Search & Sharing
	      ALL IN ONE CONSOLIDATED PANEL
	      ========================================================================= --->
	<div class="pg-v2-left-col">
		<div class="admin-card" style="margin-bottom:0;">
			<div class="card-header">
				<h2 class="card-title" style="margin-bottom:0.15rem;">
					#svgIcon(name="file-text", size=17)#
					<span>Page Details &amp; Core Content</span>
				</h2>
				<p class="pg-help" style="margin:0;">Core content authoring and search optimization in one unified workspace.</p>
			</div>

			<div class="card-body">
				<!--- 1. Page Title --->
				<div class="pg-field">
					<label for="pgTitle" class="form-label" style="font-weight:700;">Page Title <span aria-hidden="true" style="color:var(--admin-danger);">*</span><span class="sr-only"> (required)</span></label>
					<input type="text" id="pgTitle" name="title" class="form-control" required aria-required="true" value="#EncodeForHTMLAttribute(page.title)#" placeholder="e.g. Title VI Implementation Plan" style="width:100%; font-size:1.08rem; font-weight:600; padding:0.6rem 0.85rem;">
				</div>

				<!--- 2. Page URL --->
				<div class="pg-field">
					<label for="pgSlug" class="form-label" style="font-weight:700;">Page URL</label>
					<div class="pg-slug-wrap">
						<span id="pgUrlPrefixSpan" aria-hidden="true">/#EncodeForHTML(editVDir)#/pages/</span>
						<input type="text" id="pgSlug" name="slug" class="form-control" value="#EncodeForHTMLAttribute(page.slug)#" aria-describedby="pgSlugHelp" <cfif page.locked>readonly</cfif>>
						<button type="button" id="btnCopyPageUrl" class="btn btn-sm btn-icon-only btn-ghost" title="Copy full URL to clipboard" aria-label="Copy full URL to clipboard" style="border:none; border-left:1px solid var(--admin-border); border-radius:0; height:100%; padding:0.5rem 0.65rem; color:var(--admin-text-muted); display:inline-flex; align-items:center; justify-content:center; background:transparent; cursor:pointer;">
							#svgIcon(name="copy", size=14)#
						</button>
					</div>
					<div id="pgSlugHelp" class="pg-help"><cfif page.locked>The home page URL cannot be changed.<cfelse>Lowercase letters, numbers and hyphens. Generated automatically from title if left blank.</cfif></div>
				</div>

				<!--- 3. Page Layout --->
				<div class="pg-field">
					<label class="form-label" style="font-weight:700; margin-bottom:0.25rem;">Page Layout</label>
					<select id="pgLayout" name="layout" class="form-control" style="display:none;" aria-label="Page layout select">
						<option value="Full" <cfif page.layout eq "Full">selected</cfif>>Full</option>
						<option value="Right Sidebar" <cfif page.layout eq "Right Sidebar">selected</cfif>>Right Sidebar</option>
					</select>

					<div class="pg-layout-cards-grid" role="radiogroup" aria-label="Choose layout">
						<div class="pg-layout-card <cfif page.layout neq 'Right Sidebar'>is-selected</cfif>" id="layoutChoiceFull" tabindex="0" role="radio" aria-checked="#(page.layout neq 'Right Sidebar' ? 'true' : 'false')#">
							<div class="pg-layout-wireframe" aria-hidden="true">
								<div class="wf-body"></div>
							</div>
							<div>
								<strong style="display:block; font-size:0.86rem; color:var(--admin-text-main);">Full Width Layout</strong>
								<span class="pg-help" style="margin:0; font-size:0.73rem;">Clean wide layout without sidebars. Ideal for narrative pages, reports, and galleries.</span>
							</div>
						</div>

						<div class="pg-layout-card <cfif page.layout eq 'Right Sidebar'>is-selected</cfif>" id="layoutChoiceSidebar" tabindex="0" role="radio" aria-checked="#(page.layout eq 'Right Sidebar' ? 'true' : 'false')#">
							<div class="pg-layout-wireframe" aria-hidden="true">
								<div class="wf-body"></div>
								<div class="wf-side"></div>
							</div>
							<div>
								<strong style="display:block; font-size:0.86rem; color:var(--admin-text-main);">Right Sidebar Layout</strong>
								<span class="pg-help" style="margin:0; font-size:0.73rem;">Content column paired with sidebars &amp; subpages (configure in Right Panel).</span>
							</div>
						</div>
					</div>
				</div>

				<!--- 4. Page Content --->
				<div class="pg-field" style="margin-top:1.35rem;">
					<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.45rem; flex-wrap:wrap; gap:0.5rem;">
						<div style="display:flex; align-items:center; gap:0.45rem;">
							<label for="pgContent" class="form-label" style="font-weight:700; margin-bottom:0;">Page Content</label>
							<span style="font-size:0.75rem; color:var(--admin-text-muted);">(WCAG 2.1 AA)</span>
						</div>
						<div style="display:flex; align-items:center; gap:0.35rem; flex-wrap:wrap;">
							<button type="button" class="btn btn-outline-primary btn-xs" id="btnEditorImportDoc">
								#svgIcon(name="file-text", size=13)#
								<span>Import Word / PDF</span>
								<span class="pg-feature-help-pill" aria-hidden="true">?</span>
							</button>
							<button type="button" class="btn btn-outline btn-xs" id="btnEditorInsertCTA">
								#svgIcon(name="cta", size=13)#
								<span>Embed Call to Action</span>
								<span class="pg-feature-help-pill" aria-hidden="true">?</span>
							</button>
							<button type="button" class="btn btn-outline btn-xs" id="btnEditorInsertForm">
								#svgIcon(name="form", size=13)#
								<span>Embed Form</span>
								<span class="pg-feature-help-pill" aria-hidden="true">?</span>
							</button>
						</div>
					</div>

					<!--- ADA Pre-Flight Linter Bar --->
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

							<div class="pg-a11y-bar-actions" style="display:flex; align-items:center; gap:0.35rem;">
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
						<textarea id="pgContent" name="content" class="form-control pg-editor" data-jbd-editor data-jbd-toolbar="basic" data-jbd-inline-toolbar="true" data-jbd-height="420px" data-jbd-placeholder="Type page content, add headings, media, tables, and block templates..." aria-describedby="pgContentHelp"><cfif isNew><cfelseif Len(Trim(page.content ?: ''))>#EncodeForHTML(page.content)#<cfelseif Len(Trim(page.body ?: ''))>#EncodeForHTML(page.body)#<cfelse><h2>#EncodeForHTML(page.title)#</h2>
<p>#EncodeForHTML(page.summary)#</p></cfif></textarea>
					</div>
					<div id="pgContentHelp" class="pg-help">Accessible Rich Text Editor (WCAG 2.2 AA). Shortcuts: <kbd>Alt+F10</kbd> focus toolbar &middot; <kbd>&larr;/&rarr;</kbd> navigate &middot; <kbd>Esc</kbd> exit dialogs.</div>
				</div>

				<!--- 5. Search & Sharing (In the same left panel!) --->
				<div class="pg-section-divider">
					<h3 class="pg-section-divider-title">
						#svgIcon(name="search", size=16)#
						<span>Search &amp; Social Sharing Optimization</span>
					</h3>
					<button type="button" class="btn btn-outline btn-xs" id="btnAutoGenerateMeta" title="Auto-generate title and summary from page title and content" style="margin-left:auto;">
						#svgIcon(name="sparkles", size=13)#
						<span>Auto-Generate from Content</span>
					</button>
				</div>

				<div class="pg-field">
					<div style="display:flex; justify-content:space-between; align-items:center;">
						<label for="pgMetaTitle" class="form-label" style="font-weight:600; margin-bottom:0;">Browser / Search Title</label>
						<span id="pgMetaTitleCount" style="font-size:0.75rem; color:var(--admin-text-muted);">0 / 65</span>
					</div>
					<input type="text" id="pgMetaTitle" name="metaTitle" class="form-control" maxlength="65" value="#EncodeForHTMLAttribute(Len(Trim(page.metaTitle ?: '')) ? page.metaTitle : (page.title & (isNew ? '' : ' | Chelan County')))#" style="width:100%; margin-top:0.35rem;" aria-describedby="pgMetaTitleHelp">
					<div id="pgMetaTitleHelp" class="pg-help">Up to 65 characters. Appears in search results and browser title bars.</div>
				</div>

				<div class="pg-field">
					<div style="display:flex; justify-content:space-between; align-items:center;">
						<label for="pgMetaDesc" class="form-label" style="font-weight:600; margin-bottom:0;">Summary / Meta Description</label>
						<span id="pgMetaDescCount" style="font-size:0.75rem; color:var(--admin-text-muted);">0 / 160</span>
					</div>
					<textarea id="pgMetaDesc" name="metaDescription" class="form-control" maxlength="160" rows="3" style="width:100%; margin-top:0.35rem;" aria-describedby="pgMetaDescHelp">#EncodeForHTML(Len(Trim(page.metaDesc ?: '')) ? page.metaDesc : page.summary)#</textarea>
					<div id="pgMetaDescHelp" class="pg-help">Up to 160 characters. Displayed under page links in search results and social cards.</div>
				</div>
			</div>
		</div>
	</div>

	<!--- =========================================================================
	      RIGHT PANEL: Top Action Card + Expandable Page Features Accordion
	      Each feature row is an accordion item with a glowing LED marker
	      ========================================================================= --->
	<div class="pg-v2-right-col">
		<!--- Primary Action Card --->
		<div class="admin-card" id="pgPublishActionCard" style="margin-bottom:0;">
			<div class="card-header" style="display:flex; justify-content:space-between; align-items:center; gap:0.5rem;">
				<h2 class="card-title" style="margin:0;">
					#svgIcon(name="published", size=16)#
					<span>Publish Status</span>
				</h2>
				<span id="publishStatusPill" class="badge badge-success" style="font-size:0.72rem; font-weight:700;">
					#page.status eq "Active" ? "Active" : "Inactive"# &middot; #page.visibility#
				</span>
			</div>
			<div class="card-body">
				<div style="display:flex; flex-direction:column; gap:0.65rem;">
					<cfif not isNew>
						<div class="pg-field" style="margin-bottom:0.15rem;">
							<label for="pgChangeSummary" class="form-label" style="font-size:0.78rem; font-weight:600; margin-bottom:0.25rem; display:flex; justify-content:space-between; align-items:center;">
								<span>Revision Note</span>
								<span class="pg-help" style="margin:0; font-size:0.7rem; font-weight:normal;">(RCW 42.56)</span>
							</label>
							<input type="text" id="pgChangeSummary" name="changeSummary" class="form-control form-control-sm" placeholder="e.g. Updated fee schedule or meeting date" maxlength="255" style="width:100%;">
						</div>
					</cfif>

					<button type="submit" class="btn btn-primary" id="btnSavePage" style="width:100%; padding:0.65rem 1rem; font-weight:700; font-size:0.95rem; justify-content:center;">
						#svgIcon(name="save", size=16)#
						<span>#isNew ? "Create Page" : "Save Changes"#</span>
					</button>

					<div style="display:flex; gap:0.5rem;">
						<cfif not isNew>
							<a href="#EncodeForHTMLAttribute(livePageUrl)#" target="_blank" rel="noopener" class="btn btn-outline btn-sm" style="flex:1; justify-content:center;" title="View public page in new tab">
								#svgIcon(name="eye", size=14)#
								<span>View Live</span>
							</a>
						</cfif>
						<a href="#urlFor(controller='pages', action='index')#" class="btn btn-ghost btn-sm" style="<cfif isNew>width:100%;<cfelse>flex:1;</cfif> justify-content:center;">Cancel</a>
					</div>
				</div>

				<div style="margin-top:0.85rem; padding-top:0.85rem; border-top:1px solid var(--admin-border-subtle, ##e2e8f0); font-size:0.78rem; color:var(--admin-text-muted);">
					<div style="display:flex; justify-content:space-between; margin-bottom:0.35rem; align-items:center;">
						<span>Workspace:</span>
						<strong style="color:var(--admin-text-main);">#EncodeForHTML(editWsObj.name ?: "County")#</strong>
					</div>
					<cfif not isNew>
						<div style="display:flex; justify-content:space-between; align-items:center; margin-top:0.45rem; padding-top:0.45rem; border-top:1px dashed var(--admin-border-subtle, ##e2e8f0);">
							<span style="font-weight:500;">Revision:</span>
							<button type="button" class="btn btn-ghost btn-xs" id="btnOpenRevisions" onclick="openRevisionsModal()" title="Click to view historical snapshots, audit trail &amp; rollback studio (RCW 42.56)" style="color:var(--admin-primary); font-weight:700; font-size:0.78rem; padding:0.2rem 0.5rem; background:rgba(2,132,199,0.08); border:1px solid rgba(2,132,199,0.25); border-radius:4px; display:inline-flex; align-items:center; gap:0.35rem; cursor:pointer; text-decoration:none;">
								#svgIcon(name="history", size=13)#
								<span>v<span id="pgCurrentVerText">#Val(currentVersion)#</span> (<span id="pgRevCountText">#Val(revisionCount)#</span> records)</span>
							</button>
						</div>
					</cfif>
				</div>
			</div>
		</div>

		<!--- Page Features Accordion Console Card --->
		<div class="admin-card" id="pgFeaturesConsoleCard" style="margin-bottom:0;">
			<div class="card-header" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:0.5rem;">
				<div>
					<h2 class="card-title" style="margin-bottom:0.1rem;">
						#svgIcon(name="layers", size=16)#
						<span>Page Features Deck</span>
					</h2>
					<p class="pg-help" style="margin:0;">Hover over any item for a quick 1-2-3 guide, or click to expand.</p>
				</div>
				<div style="display:flex; align-items:center; gap:0.4rem;">
					<button type="button" class="btn btn-ghost btn-xs" onclick="expandAllAccordion()" title="Expand all features" style="font-size:0.72rem; padding:0.15rem 0.4rem;">Expand All</button>
					<button type="button" class="btn btn-ghost btn-xs" onclick="collapseAllAccordion()" title="Collapse all features" style="font-size:0.72rem; padding:0.15rem 0.4rem;">Collapse</button>
					<span id="featuresActiveBadge" class="badge badge-primary" style="font-size:0.72rem; font-weight:700;">
						0 Active
					</span>
				</div>
			</div>

			<div class="card-body" style="padding:0.75rem;">
				<div class="pg-features-accordion" id="pgFeaturesAccordion">
					
					<!--- -------------------------------------------------------------
					      Accordion Item 1: Featured Cover Image
					      ------------------------------------------------------------- --->
					<div class="pg-accordion-item" id="accItemCoverImage">
						<button type="button" class="pg-accordion-header" onclick="toggleAccordionItem('accItemCoverImage')" aria-expanded="false" aria-controls="accBodyCoverImage">
							<div class="pg-accordion-info">
								<span class="led-marker is-inactive" id="ledCoverImage"></span>
								<div class="pg-accordion-icon-wrap">
									#svgIcon(name="image", size=16)#
								</div>
								<div class="pg-accordion-texts">
									<div class="pg-accordion-title">
										<span>Featured Cover Image</span><span class="pg-feature-help-pill" aria-hidden="true">?</span>
									</div>
									<div class="pg-accordion-desc" id="summaryCoverImage">
										#(Len(Trim(page.imageAttachment ?: '')) ? 'Image attached' : 'No image configured')#
									</div>
								</div>
							</div>
							<span class="pg-accordion-chevron">#svgIcon(name="chevron-down", size=15)#</span>
						</button>
						<div class="pg-accordion-body" id="accBodyCoverImage">
							<!--- Thumbnail Preview --->
							<div style="margin-bottom:0.85rem;">
								<div id="featuredImgPreviewWrap" role="button" tabindex="0" aria-label="Click to browse workspace media library" onclick="openMediaPickerForPageCover()" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();openMediaPickerForPageCover();}" style="border:1.5px dashed var(--admin-border); border-radius:var(--radius-md); padding:0.6rem; text-align:center; min-height:120px; display:flex; flex-direction:column; align-items:center; justify-content:center; background:var(--admin-bg); cursor:pointer;">
									<img id="featuredImgPreview" src="#EncodeForHTML(page.imageAttachment ?: '')#" alt="#EncodeForHTMLAttribute(page.imageAlt ?: '')#" style="max-width:100%; max-height:140px; object-fit:cover; border-radius:var(--radius-sm); #(Len(Trim(page.imageAttachment ?: '')) ? '' : 'display:none;')#" />
									<div id="featuredImgPlaceholder" style="color:var(--admin-text-muted); font-size:0.8rem; #(Len(Trim(page.imageAttachment ?: '')) ? 'display:none;' : 'display:flex; flex-direction:column; align-items:center; justify-content:center;')#">
										<div style="color:var(--admin-primary); margin-bottom:0.25rem;">
											#svgIcon(name="image", size=28)#
										</div>
										<strong style="color:var(--admin-text-main); font-size:0.85rem;">Choose Cover Image</strong>
										<span style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.15rem;">Click to browse workspace media library</span>
									</div>
								</div>
							</div>

							<!--- Image URL & Picker Buttons --->
							<div class="pg-field">
								<label for="featuredImage" class="form-label" style="font-size:0.8rem; font-weight:600;">Image URL</label>
								<div style="display:flex; gap:0.35rem;">
									<input type="text" id="featuredImage" name="imageAttachment" class="form-control form-control-sm" value="#EncodeForHTML(page.imageAttachment ?: '')#" placeholder="/files/pio/images/photo.jpg" oninput="updateImagePreview(this.value); updatePageFeaturesLedStatus();">
									<button type="button" id="btnBrowseFeaturedImg" class="btn btn-secondary btn-xs" onclick="openMediaPickerForPageCover()" style="white-space:nowrap; display:inline-flex; align-items:center; gap:0.3rem; cursor:pointer;" title="Browse Workspace Media Library" aria-label="Browse Workspace Media Library">
										#svgIcon(name="folder", size=12)#
										<span>Browse</span>
									</button>
									<button type="button" id="btnRemoveFeaturedImg" class="btn btn-outline-danger btn-xs" onclick="removeFeaturedImage(); updatePageFeaturesLedStatus();" style="display:#(Len(Trim(page.imageAttachment ?: '')) ? 'inline-flex' : 'none')#; white-space:nowrap;">
										#svgIcon(name="trash", size=12)#
									</button>
								</div>
							</div>

							<!--- Decorative Toggle (WCAG 2.1 H67) --->
							<div style="background:var(--admin-bg, ##f8fafc); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:0.55rem 0.75rem; margin-bottom:0.85rem;">
								<label style="display:flex; align-items:flex-start; gap:0.5rem; font-size:0.78rem; font-weight:600; color:var(--admin-text-main); margin:0; cursor:pointer;">
									<input type="checkbox" id="featuredImageDecorative" name="imageDecorative" value="1" #(Val(page.imageDecorative ?: 0) ? 'checked="checked"' : '')# onchange="onDecorativeToggled(this.checked); updatePageFeaturesLedStatus();" style="margin-top:0.15rem;">
									<div>
										<span>Mark as decorative image (WCAG 1.1.1 / H67)</span>
										<div style="font-weight:400; font-size:0.7rem; color:var(--admin-text-muted); margin-top:0.1rem; line-height:1.3;">
											Screen readers safely ignore decorative images.
										</div>
									</div>
								</label>
							</div>

							<!--- Alt Text Container --->
							<div id="altTextContainer" class="pg-field" style="#(Val(page.imageDecorative ?: 0) ? 'opacity:0.5; pointer-events:none;' : '')#">
								<div style="display:flex; justify-content:space-between; align-items:center;">
									<label for="featuredImageAlt" class="form-label" style="font-size:0.8rem; font-weight:600; margin:0;">
										Alternative Text (ADA / WCAG 2.1 AA) <span style="color:var(--admin-danger);">*</span>
									</label>
									<span style="font-size:0.7rem; color:var(--admin-text-muted);" id="altCharCounter">#Len(Trim(page.imageAlt ?: ''))#/150 rec.</span>
								</div>
								<input type="text" id="featuredImageAlt" name="imageAlt" class="form-control form-control-sm" style="margin-top:0.25rem;" value="#EncodeForHTML(page.imageAlt ?: '')#" placeholder="Brief scene or subject description for screen readers" maxlength="500" oninput="onAltInput(this.value); updatePageFeaturesLedStatus();">
								<div style="display:flex; justify-content:space-between; align-items:center; margin-top:0.25rem;">
									<span style="font-size:0.7rem; color:var(--admin-text-muted);">Concise description.</span>
									<button type="button" class="btn btn-link btn-xs" style="padding:0; font-size:0.72rem; text-decoration:none; color:var(--admin-primary); display:inline-flex; align-items:center; gap:0.2rem;" onclick="suggestAltFromHeadline()">
										#svgIcon(name="sparkles", size=11)#
										<span>Suggest from Headline</span>
									</button>
								</div>
							</div>

							<!--- Caption & Attribution --->
							<div class="pg-field">
								<label for="featuredImageCaption" class="form-label" style="font-size:0.8rem; font-weight:600;">Story Caption (Visible)</label>
								<input type="text" id="featuredImageCaption" name="imageTitle" class="form-control form-control-sm" value="#EncodeForHTML(page.imageTitle ?: '')#" placeholder="Optional visible caption printed below image">
							</div>

							<div class="pg-field">
								<label for="featuredImageDescription" class="form-label" style="font-size:0.8rem; font-weight:600;">Extended Description (Complex Maps / Infographics)</label>
								<textarea id="featuredImageDescription" name="imageDescription" class="form-control form-control-sm" rows="2" placeholder="Detailed transcript for screen readers if image conveys charts or complex maps...">#EncodeForHTML(page.imageDescription ?: '')#</textarea>
							</div>

							<div class="pg-field">
								<label for="featuredImageCredit" class="form-label" style="font-size:0.8rem; font-weight:600;">Photo Credit / Attribution</label>
								<input type="text" id="featuredImageCredit" name="imageAttribution" class="form-control form-control-sm" value="#EncodeForHTML(page.imageAttribution ?: '')#" placeholder="e.g. Chelan County Sheriff's Office">
							</div>
						</div>
					</div>

					<!--- -------------------------------------------------------------
					      Accordion Item 2: Navigation & Main Menu Assignment
					      ------------------------------------------------------------- --->
					<div class="pg-accordion-item" id="accItemNavigation">
						<button type="button" class="pg-accordion-header" onclick="toggleAccordionItem('accItemNavigation')" aria-expanded="false" aria-controls="accBodyNavigation">
							<div class="pg-accordion-info">
								<span class="led-marker is-inactive" id="ledNavigation"></span>
								<div class="pg-accordion-icon-wrap">
									#svgIcon(name="navigation", size=16)#
								</div>
								<div class="pg-accordion-texts">
									<div class="pg-accordion-title">
										<span>Navigation &amp; Menu</span><span class="pg-feature-help-pill" aria-hidden="true">?</span>
									</div>
									<div class="pg-accordion-desc" id="summaryNavigation">
										#(page.menuItem ? 'Shown in main menu' : (Len(Trim(page.parent)) ? page.parent : 'Top-level route'))#
									</div>
								</div>
							</div>
							<span class="pg-accordion-chevron">#svgIcon(name="chevron-down", size=15)#</span>
						</button>
						<div class="pg-accordion-body" id="accBodyNavigation">
							<cfset isAssignedToMenu = (structKeyExists(page, "pageType") and Val(page.pageType) eq 1) or page.parent eq "Assign to Main Menu Item" or page.parent eq "Assign to Menu Item" or (len(trim(page.parent)) gt 0 and page.parent neq "Top Level - Called from URL")>
							<div class="pg-field">
								<label for="pgParent" class="form-label" style="font-size:0.82rem; font-weight:600;">Page Assignment</label>
								<select id="pgParent" name="parent" class="form-control form-control-sm" style="width:100%;" onchange="window.updateMenuAssignmentVisibility(); window.updatePageFeaturesLedStatus();">
									<option value="Top Level - Called from URL" <cfif not isAssignedToMenu>selected</cfif>>Top Level - Called from URL</option>
									<option value="Assign to Main Menu Item" <cfif isAssignedToMenu>selected</cfif>>Assign to Main Menu Item</option>
								</select>
								<div class="pg-help">Specify whether this page is a top-level route or nested under a main navigation menu item.</div>
							</div>

							<div id="pgMenuAssignmentWrap" class="pg-field" style="margin-top:0.75rem;<cfif not isAssignedToMenu> display:none;</cfif>" <cfif not isAssignedToMenu>hidden</cfif>>
								<label for="pgMenuItemSelect" class="form-label" style="font-size:0.82rem; font-weight:600;">Menu Item Selection</label>
								<select id="pgMenuItemSelect" name="menuItemTarget" class="form-control form-control-sm" style="width:100%;" data-initial-selected="#EncodeForHTMLAttribute(page.parent)#" data-page-workspace="#EncodeForHTMLAttribute(page.siteId)#" onchange="window.updatePageFeaturesLedStatus();">
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
								<div class="pg-help">Select the navigation item or parent page this belongs under.</div>
							</div>

							<div class="pg-field" style="margin-top:0.85rem;">
								<label style="display:flex; align-items:center; gap:0.55rem; font-size:0.84rem; cursor:pointer;">
									<input type="checkbox" id="pgMenuItem" name="menuItem" <cfif page.menuItem>checked</cfif> style="width:17px; height:17px; accent-color:var(--admin-primary);" onchange="window.updatePageFeaturesLedStatus();">
									<strong>Show in main menu navigation</strong>
								</label>
								<div class="pg-help">Adds a direct link to this page in the site's top navigation bar.</div>
							</div>
						</div>
					</div>

					<!--- -------------------------------------------------------------
					      Accordion Item 3: Sidebars & Subpages
					      ------------------------------------------------------------- --->
					<div class="pg-accordion-item" id="accItemSidebar">
						<button type="button" class="pg-accordion-header" onclick="toggleAccordionItem('accItemSidebar')" aria-expanded="false" aria-controls="accBodySidebar">
							<div class="pg-accordion-info">
								<span class="led-marker is-inactive" id="ledSidebar"></span>
								<div class="pg-accordion-icon-wrap">
									#svgIcon(name="columns", size=16)#
								</div>
								<div class="pg-accordion-texts">
									<div class="pg-accordion-title">
										<span>Sidebar &amp; Subpages</span><span class="pg-feature-help-pill" aria-hidden="true">?</span>
									</div>
									<div class="pg-accordion-desc" id="summarySidebar">
										#(page.layout eq 'Right Sidebar' ? (IsArray(page.sidebarIds) && ArrayLen(page.sidebarIds) ? ArrayLen(page.sidebarIds) & ' subpages attached' : 'Right sidebar active (0 selected)') : 'Full width layout')#
									</div>
								</div>
							</div>
							<span class="pg-accordion-chevron">#svgIcon(name="chevron-down", size=15)#</span>
						</button>
						<div class="pg-accordion-body" id="accBodySidebar">
							<div id="sidebarLayoutNotice" style="background:var(--admin-bg); border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); padding:0.65rem 0.75rem; margin-bottom:0.85rem; display:flex; align-items:center; justify-content:space-between; gap:0.5rem; flex-wrap:wrap;">
								<div style="font-size:0.78rem;">
									<span style="color:var(--admin-text-muted);">Layout:</span>
									<strong id="sidebarNoticeLayoutName" style="color:var(--admin-primary); margin-left:0.25rem;">#(page.layout eq 'Right Sidebar' ? 'Right Sidebar' : 'Full Width')#</strong>
								</div>
								<button type="button" class="btn btn-outline btn-xs" id="btnSwitchToSidebarLayout" onclick="selectLayoutV2('#(page.layout eq 'Right Sidebar' ? 'Full' : 'Right Sidebar')#');" style="font-size:0.72rem; padding:0.18rem 0.45rem;">
									<span>#(page.layout eq 'Right Sidebar' ? 'Switch to Full Width' : 'Switch to Right Sidebar')#</span>
								</button>
							</div>

							<div class="pg-field">
								<h4 class="form-label" style="font-size:0.82rem; font-weight:700; margin-bottom:0.35rem;">Assigned Subpages &amp; Sidebars</h4>
								<div id="pgSidebarChooser" role="group" aria-label="Assigned sidebars" style="display:flex; flex-direction:column; gap:0; max-height:220px; overflow-y:auto; border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.4rem 0.65rem; background:var(--admin-surface);">
									<cfloop array="#availableSidebars#" index="sidebarOption">
										<label style="display:flex; align-items:center; gap:0.5rem; padding:0.35rem 0; border-bottom:1px solid var(--admin-border-subtle); cursor:pointer;">
											<input type="checkbox" name="sidebarIds" value="#EncodeForHTMLAttribute(sidebarOption.id)#" <cfif IsArray(page.sidebarIds) && ArrayFind(page.sidebarIds, sidebarOption.id)>checked</cfif> onchange="updatePageFeaturesLedStatus();" style="width:16px; height:16px; flex-shrink:0; accent-color:var(--admin-primary);">
											<span><strong style="font-size:0.82rem; color:var(--admin-text-main);">#EncodeForHTML(sidebarOption.name)#</strong></span>
										</label>
									</cfloop>
									<cfloop array="#availableSubpages#" index="subpageOption">
										<div class="pg-subpage-row" style="padding:0.35rem 0; gap:0.5rem;">
											<label style="display:flex; align-items:center; gap:0.5rem; flex:1; min-width:0; cursor:pointer;">
												<input type="checkbox" name="sidebarIds" value="subpage-#subpageOption.id#" data-id="#subpageOption.id#" data-subpage-title="#EncodeForHTMLAttribute(subpageOption.title)#" data-content="#EncodeForHTMLAttribute(subpageOption.body)#" data-position="#Val(subpageOption.position)#" <cfif IsArray(page.sidebarIds) && ArrayFindNoCase(page.sidebarIds, "subpage-#subpageOption.id#")>checked</cfif> onchange="updatePageFeaturesLedStatus();" style="width:16px; height:16px; flex-shrink:0; accent-color:var(--admin-primary);">
												<span><strong data-subpage-title style="font-size:0.82rem; color:var(--admin-text-main);">#EncodeForHTML(subpageOption.title)#</strong></span>
											</label>
											<button type="button" class="btn btn-outline btn-xs btn-icon-only" data-edit-subpage title="Edit" aria-label="Edit #EncodeForHTMLAttribute(subpageOption.title)#">#svgIcon(name="edit", size=12)#</button>
										</div>
									</cfloop>
									<cfif ArrayLen(availableSubpages) eq 0 and ArrayLen(availableSidebars) eq 0>
										<div id="pgNoSidebarsMsg" class="pg-help" style="padding:0.5rem 0; color:var(--admin-text-muted);">No subpages or sidebars created yet.</div>
									</cfif>
								</div>
								<div class="pg-help">Display sidebars or custom subpages when Right Sidebar layout is active.</div>
							</div>

							<cfif not isNew>
								<div style="border-top:1px solid var(--admin-border-subtle); margin-top:0.75rem; padding-top:0.75rem;">
									<button type="button" class="btn btn-outline btn-xs" id="pgOpenSubpageModal" data-content-id="#page.id#" data-site-id="#EncodeForHTMLAttribute(variables.editSiteId)#" data-save-url="#urlFor(route="saveSubpage")#" data-delete-url="#urlFor(route="deleteSubpage")#">
										#svgIcon(name="plus", size=13)#
										<span>Create New Subpage</span>
									</button>
								</div>
							<cfelse>
								<div class="pg-help" style="margin-top:0.5rem;">Save page first to create custom subpages.</div>
							</cfif>
						</div>
					</div>

					<!--- -------------------------------------------------------------
					      Accordion Item 4: Folder Explorer
					      ------------------------------------------------------------- --->
					<div class="pg-accordion-item" id="accItemFolder">
						<button type="button" class="pg-accordion-header" onclick="toggleAccordionItem('accItemFolder')" aria-expanded="false" aria-controls="accBodyFolder">
							<div class="pg-accordion-info">
								<span class="led-marker is-inactive" id="ledFolder"></span>
								<div class="pg-accordion-icon-wrap">
									#svgIcon(name="folder", size=16)#
								</div>
								<div class="pg-accordion-texts">
									<div class="pg-accordion-title">
										<span>Folder Explorer</span><span class="pg-feature-help-pill" aria-hidden="true">?</span>
									</div>
									<div class="pg-accordion-desc" id="summaryFolder">
										#(folderAttachedHere or (structKeyExists(page, "hasArchive") and page.hasArchive) ? 'Folder explorer attached' : 'Disabled')#
									</div>
								</div>
							</div>
							<span class="pg-accordion-chevron">#svgIcon(name="chevron-down", size=15)#</span>
						</button>
						<div class="pg-accordion-body" id="accBodyFolder">
							<cfset isFolderExplorerEnabled = folderAttachedHere or (structKeyExists(page, "hasArchive") and page.hasArchive)>
							<div class="pg-field">
								<label style="display:flex; align-items:center; gap:0.55rem; font-size:0.85rem; cursor:pointer;">
									<input type="checkbox" id="pgFolderListingEnabled" name="folderListingEnabled" <cfif isFolderExplorerEnabled>checked</cfif> style="width:17px; height:17px; accent-color:var(--admin-primary);" aria-controls="pgFolderListingControls" onchange="updatePageFeaturesLedStatus();">
									<strong>Enable Folder Explorer on this page</strong>
								</label>
								<div class="pg-help">Embeds an interactive document repository browser.</div>
							</div>

							<div id="pgFolderListingControls" data-content-id="#page.id#" data-save-url="#urlFor(route="saveFolderExplorer")#" data-delete-url="#urlFor(route="deleteFolderExplorer")#" <cfif not isFolderExplorerEnabled>hidden</cfif> style="margin-top:0.75rem; border-top:1px solid var(--admin-border-subtle); padding-top:0.75rem;">
								<h4 class="form-label" style="font-size:0.82rem; font-weight:700; margin-bottom:0.35rem;">Attached Folders</h4>
								<div id="pgFolderListingItems" style="display:flex; flex-direction:column; gap:0; max-height:220px; overflow-y:auto; border:1px solid var(--admin-border); border-radius:var(--radius-sm); padding:0.4rem 0.65rem; background:var(--admin-surface);">
									<cfloop array="#availableFolders#" index="folderOption">
										<cfset folderAbs = folderOption.absolutePath>
										<cfset folderRel = folderOption.relativePath>
										<cfset folderLay = folderOption.layout>
										<cfset isFolderSelected = (structKeyExists(folderOption, "selected") and folderOption.selected) or (Val(folderOption.contentId ?: 0) eq Val(page.id) and Val(page.id) gt 0)>
										<div class="pg-subpage-row" data-id="#folderOption.id#" data-title="#EncodeForHTMLAttribute(folderOption.name)#" data-path="#EncodeForHTMLAttribute(folderOption.path)#" data-absolute-path="#EncodeForHTMLAttribute(folderAbs)#" data-relative-path="#EncodeForHTMLAttribute(folderRel)#" data-layout="#EncodeForHTMLAttribute(folderLay)#" style="padding:0.4rem 0; gap:0.5rem; border-bottom:1px dashed var(--admin-border-subtle); display:flex; align-items:center;">
											<label style="display:flex; align-items:flex-start; gap:0.5rem; flex:1; min-width:0; cursor:pointer;">
												<input type="checkbox" name="folderListingItems" value="#EncodeForHTMLAttribute(folderOption.path)#" data-folder-id="#Val(folderOption.id)#" <cfif isFolderSelected>checked</cfif> onchange="updatePageFeaturesLedStatus();" style="width:16px; height:16px; margin-top:0.15rem; flex-shrink:0; accent-color:var(--admin-primary);">
												<span style="min-width:0; flex:1;">
													<strong data-folder-title style="display:block; color:var(--admin-text-main); font-size:0.84rem;">#EncodeForHTML(folderOption.name)#</strong>
													<span class="pg-help" style="margin:0; font-size:0.72rem; display:flex; align-items:center; gap:0.3rem; flex-wrap:wrap;">
														<code data-folder-relative style="font-size:0.7rem; color:var(--admin-primary); background:rgba(30,58,138,0.06); padding:0.1rem 0.25rem; border-radius:3px;">/#EncodeForHTML(folderRel)#</code>
														<span>&bull;</span>
														<span class="badge badge-neutral" data-folder-layout-badge style="font-size:0.65rem; padding:0.05rem 0.35rem;">#folderLay eq '3/9' ? '3/9 Grid' : 'Full Width'#</span>
													</span>
												</span>
											</label>
											<button type="button" class="btn btn-outline btn-xs btn-icon-only" data-edit-folder-item title="Edit" aria-label="Edit #EncodeForHTMLAttribute(folderOption.name)#">#svgIcon(name="edit", size=12)#</button>
										</div>
									</cfloop>
								</div>
								<div id="pgFolderListingStatus" role="status" aria-live="polite" class="pg-help" style="margin-top:0.35rem;"></div>
								<button type="button" class="btn btn-outline btn-xs" id="pgAddFolderListingItem" style="margin-top:0.65rem;">
									#svgIcon(name="plus", size=12)#
									<span>Add Folder Item</span>
								</button>
							</div>
						</div>
					</div>

					<!--- -------------------------------------------------------------
					      Accordion Item 5: Publishing & Scheduling Details
					      ------------------------------------------------------------- --->
					<div class="pg-accordion-item" id="accItemPublish">
						<button type="button" class="pg-accordion-header" onclick="toggleAccordionItem('accItemPublish')" aria-expanded="false" aria-controls="accBodyPublish">
							<div class="pg-accordion-info">
								<span class="led-marker is-inactive" id="ledPublish"></span>
								<div class="pg-accordion-icon-wrap">
									#svgIcon(name="clock", size=16)#
								</div>
								<div class="pg-accordion-texts">
									<div class="pg-accordion-title">
										<span>Publishing &amp; Schedule</span><span class="pg-feature-help-pill" aria-hidden="true">?</span>
									</div>
									<div class="pg-accordion-desc" id="summaryPublish">
										#page.visibility# &middot; #page.status#
									</div>
								</div>
							</div>
							<span class="pg-accordion-chevron">#svgIcon(name="chevron-down", size=15)#</span>
						</button>
						<div class="pg-accordion-body" id="accBodyPublish">
							<div class="pg-field">
								<label for="pgStatus" class="form-label" style="font-size:0.8rem; font-weight:600;">Status</label>
								<select id="pgStatus" name="status" class="form-control form-control-sm" style="width:100%;" onchange="updatePageFeaturesLedStatus();">
									<option value="Active" <cfif page.status eq "Active">selected</cfif>>Active</option>
									<option value="Inactive" <cfif page.status eq "Inactive">selected</cfif>>Inactive</option>
								</select>
							</div>

							<div class="pg-field">
								<label for="pgVisibility" class="form-label" style="font-size:0.8rem; font-weight:600;">Visibility</label>
								<select id="pgVisibility" name="visibility" class="form-control form-control-sm" style="width:100%;" onchange="updatePageFeaturesLedStatus();">
									<cfloop list="Published,Draft,Scheduled,Hidden" index="v">
										<option value="#v#" <cfif page.visibility eq v>selected</cfif>>#v#</option>
									</cfloop>
								</select>
							</div>

							<div class="pg-field" id="pgScheduleWrap">
								<label for="pgPublishAt" class="form-label" style="font-size:0.8rem; font-weight:600;">Publish On Date / Time</label>
								<input type="datetime-local" id="pgPublishAt" name="publishAt" class="form-control form-control-sm" value="#page.publishAt ?: ''#" style="width:100%;" oninput="updatePageFeaturesLedStatus();">
								<div class="pg-help">Auto-releases page when Visibility is Scheduled.</div>
							</div>

							<div class="pg-field">
								<label for="pgUnpublishAt" class="form-label" style="display:flex; justify-content:space-between; align-items:center; font-size:0.8rem; font-weight:600;">
									<span>Unpublish / Expire On Date</span>
									<span class="pg-help" style="margin:0; font-weight:normal;">(optional)</span>
								</label>
								<input type="datetime-local" id="pgUnpublishAt" name="unpublishAt" class="form-control form-control-sm" value="#page.unpublishAt ?: ''#" style="width:100%;" oninput="updatePageFeaturesLedStatus();">
								<div class="pg-help">Auto-archives seasonal pages or RFP notices.</div>
							</div>

						</div>
					</div>

				</div>
			</div>
		</div>
	</div>
</form>

<!--- Subpage Modal Window --->
<div class="pg-subpage-modal" id="pgSubpageModal" role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="pgSubpageModalTitle">
	<div class="pg-subpage-backdrop" data-close-subpage-modal></div>
	<section class="pg-subpage-window" style="width:min(100%, 820px);">
		<div class="card-header">
			<div>
				<h2 class="card-title" id="pgSubpageModalTitle">Create Subpage</h2>
				<p class="pg-help" style="margin-bottom:0;">The subpage will be added to the available sidebar list.</p>
			</div>
			<button type="button" class="btn btn-outline btn-sm" id="pgCloseSubpageModal" aria-label="Close subpage editor" onclick="closeSubpageModal()">Close</button>
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
				<label for="pgSubpageContent" class="form-label" style="font-weight:600;">Body</label>
				<textarea id="pgSubpageContent" class="form-control" rows="8" placeholder="Enter subpage content..." style="width:100%; font-family:inherit;"></textarea>
			</div>
		</div>
		<div class="card-footer" style="display:flex; justify-content:flex-end; gap:0.5rem;">
			<button type="button" class="btn btn-outline btn-sm" id="pgCancelSubpage" data-close-subpage-modal onclick="closeSubpageModal()">Cancel</button>
			<button type="button" class="btn btn-primary btn-sm" id="pgSaveSubpageBtn">#svgIcon(name="save", size=14)# <span>Save Subpage</span></button>
		</div>
	</section>
</div>

<!--- Folder Item Modal Window --->
<div class="pg-subpage-modal" id="pgFolderItemModal" role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="pgFolderItemModalTitle">
	<div class="pg-subpage-backdrop" data-close-folder-modal onclick="closeFolderItemModal()"></div>
	<section class="pg-subpage-window" style="width:min(100%, 720px);">
		<div class="card-header">
			<div>
				<h2 class="card-title" id="pgFolderItemModalTitle" style="font-size:1.15rem; margin:0; display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="folder", size=20)#
					<span>Add Folder Explorer Item</span>
				</h2>
				<p class="pg-help" style="margin:0.25rem 0 0 0; font-size:0.8rem;">Configure document repository title, physical storage path, public web route, and layout.</p>
			</div>
			<button type="button" class="btn btn-outline btn-sm" id="pgCloseFolderModal" aria-label="Close folder item editor" onclick="closeFolderItemModal()">Close</button>
		</div>
		<div class="card-body">
			<div id="pgFolderItemStatus" role="status" aria-live="polite" class="pg-help" style="min-height:1.2rem; color:var(--admin-danger); font-weight:600; margin-bottom:0.75rem;"></div>
			<input type="hidden" id="pgFolderItemId" value="0">
			<div class="pg-field" style="margin-bottom:1.1rem;">
				<label for="pgFolderItemTitle" class="form-label" style="font-weight:600;">Folder Title <span style="color:var(--admin-danger);">*</span></label>
				<input type="text" id="pgFolderItemTitle" class="form-control" maxlength="120" style="width:100%; font-size:0.95rem; font-weight:600;" placeholder="e.g. Planning Documents &amp; Minutes" required aria-required="true" aria-describedby="pgFolderItemTitleHelp">
				<div id="pgFolderItemTitleHelp" class="pg-help">Display heading for this document folder explorer instance.</div>
			</div>

			<div class="pg-field" style="margin-bottom:1.1rem;">
				<label for="pgFolderItemAbsolute" class="form-label" style="font-weight:600;">Server Absolute Path <span style="color:var(--admin-danger);">*</span></label>
				<input type="text" id="pgFolderItemAbsolute" class="form-control" style="width:100%; font-family:monospace; font-size:0.85rem;" placeholder="C:\inetpub\chelan-county\files\assessors" required aria-required="true" aria-describedby="pgFolderItemAbsHelp">
				<div id="pgFolderItemAbsHelp" class="pg-help">Physical server directory or network UNC path on the filesystem.</div>
			</div>

			<div class="pg-field" style="margin-bottom:1.25rem;">
				<label for="pgFolderItemRelative" class="form-label" style="font-weight:600;">Web URL Relative Path <span style="color:var(--admin-danger);">*</span></label>
				<div style="display:flex; align-items:stretch; border:1.5px solid var(--admin-border-input, ##64748b); border-radius:var(--radius-md); overflow:hidden;">
					<span style="display:inline-flex; align-items:center; padding:0 0.75rem; background:var(--admin-bg, ##f8fafc); border-right:1px solid var(--admin-border, ##cbd5e1); color:var(--admin-text-muted, ##475569); font-size:0.85rem; font-family:monospace; user-select:none;">chelancounty.gov/</span>
					<input type="text" id="pgFolderItemRelative" class="form-control" style="flex:1; border:none; border-radius:0; font-family:monospace; font-size:0.85rem;" placeholder="files/assessors" required aria-required="true" aria-describedby="pgFolderItemRelHelp">
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
		</div>
		<div class="card-footer" style="display:flex; justify-content:flex-end; gap:0.5rem;">
			<button type="button" class="btn btn-outline btn-sm" id="pgDeleteFolderItem" hidden style="margin-right:auto; color:var(--admin-danger);">Delete</button>
			<button type="button" class="btn btn-outline btn-sm" id="pgCancelFolderItem" data-close-folder-modal onclick="closeFolderItemModal()">Cancel</button>
			<button type="button" class="btn btn-primary btn-sm" id="pgSaveFolderItem">#svgIcon(name="save", size=14)# <span>Save Folder</span></button>
		</div>
	</section>
</div>
</cfoutput>

<!--- Include shared Media Picker, Revisions Modal, Doc Convert Modal, CTA/Form Modals --->
<cfinclude template="_pageEditorModals.cfm">

<!--- Include shared rich text editor, ADA pre-flight linter engine, and savePage AJAX handler --->
<cfinclude template="_pageEditorScripts.cfm">

<!--- Core JavaScript for v2 Branch Experience (Accordion Deck, LED Markers & Live Synchronization) --->
<script>
(function() {
	"use strict";

	// 1. Accordion Toggle Manager
	window.toggleAccordionItem = function(itemId) {
		var item = document.getElementById(itemId);
		if (!item) return;
		var isOpen = item.classList.contains("is-open");
		var header = item.querySelector(".pg-accordion-header");
		
		item.classList.toggle("is-open", !isOpen);
		if (header) {
			header.setAttribute("aria-expanded", !isOpen ? "true" : "false");
		}
	};

	window.expandAllAccordion = function() {
		document.querySelectorAll(".pg-accordion-item").forEach(function(item) {
			item.classList.add("is-open");
			var header = item.querySelector(".pg-accordion-header");
			if (header) header.setAttribute("aria-expanded", "true");
		});
	};

	window.collapseAllAccordion = function() {
		document.querySelectorAll(".pg-accordion-item").forEach(function(item) {
			item.classList.remove("is-open");
			var header = item.querySelector(".pg-accordion-header");
			if (header) header.setAttribute("aria-expanded", "false");
		});
	};



	// 3. Layout Card Selector in Left Panel (Full Width vs. Right Sidebar)
	window.selectLayoutV2 = function(layoutVal) {
		var layoutSelect = document.getElementById("pgLayout");
		var cardFull = document.getElementById("layoutChoiceFull");
		var cardSidebar = document.getElementById("layoutChoiceSidebar");
		var noticeLayoutName = document.getElementById("sidebarNoticeLayoutName");
		var btnSwitch = document.getElementById("btnSwitchToSidebarLayout");
		var sidebarChooser = document.getElementById("pgSidebarChooser");

		if (layoutSelect) {
			layoutSelect.value = layoutVal;
			try {
				layoutSelect.dispatchEvent(new Event("change", { bubbles: true }));
			} catch (e) {
				console.warn("layout change event error:", e);
			}
		}

		if (layoutVal === "Right Sidebar") {
			if (cardSidebar) {
				cardSidebar.classList.add("is-selected");
				cardSidebar.setAttribute("aria-checked", "true");
			}
			if (cardFull) {
				cardFull.classList.remove("is-selected");
				cardFull.setAttribute("aria-checked", "false");
			}
			if (noticeLayoutName) noticeLayoutName.textContent = "Right Sidebar";
			if (btnSwitch) {
				btnSwitch.innerHTML = "<span>Switch to Full Width</span>";
				btnSwitch.onclick = function() { selectLayoutV2("Full"); };
			}
			if (sidebarChooser) {
				sidebarChooser.style.opacity = "1";
				sidebarChooser.style.pointerEvents = "auto";
			}
		} else {
			if (cardFull) {
				cardFull.classList.add("is-selected");
				cardFull.setAttribute("aria-checked", "true");
			}
			if (cardSidebar) {
				cardSidebar.classList.remove("is-selected");
				cardSidebar.setAttribute("aria-checked", "false");
			}
			if (noticeLayoutName) noticeLayoutName.textContent = "Full Width";
			if (btnSwitch) {
				btnSwitch.innerHTML = "<span>Switch to Right Sidebar</span>";
				btnSwitch.onclick = function() { selectLayoutV2("Right Sidebar"); };
			}
			if (sidebarChooser) {
				sidebarChooser.style.opacity = "0.6";
				sidebarChooser.style.pointerEvents = "auto";
			}
		}

		window.updatePageFeaturesLedStatus();
	};

	var cardFull = document.getElementById("layoutChoiceFull");
	if (cardFull) {
		cardFull.addEventListener("click", function() { selectLayoutV2("Full"); });
		cardFull.addEventListener("keydown", function(e) { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); selectLayoutV2("Full"); } });
	}

	var cardSidebar = document.getElementById("layoutChoiceSidebar");
	if (cardSidebar) {
		cardSidebar.addEventListener("click", function() { selectLayoutV2("Right Sidebar"); });
		cardSidebar.addEventListener("keydown", function(e) { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); selectLayoutV2("Right Sidebar"); } });
	}

	// 4. Central LED Light Marker & Features Live Synchronizer
	window.updatePageFeaturesLedStatus = function() {
		var activeCount = 0;

		// --- Feature 1: Cover Image ---
		var imgInput = document.getElementById("featuredImage");
		var imgVal = imgInput ? imgInput.value.trim() : "";
		var altInput = document.getElementById("featuredImageAlt");
		var altVal = altInput ? altInput.value.trim() : "";
		var decorInput = document.getElementById("featuredImageDecorative");
		var isDecor = decorInput ? decorInput.checked : false;
		var ledCover = document.getElementById("ledCoverImage");
		var summaryCover = document.getElementById("summaryCoverImage");
		var accCover = document.getElementById("accItemCoverImage");

		if (ledCover && summaryCover) {
			ledCover.className = "led-marker";
			if (imgVal.length > 0) {
				activeCount++;
				if (accCover) accCover.classList.add("is-active-feature");
				if (!isDecor && altVal.length === 0) {
					ledCover.classList.add("is-warn");
					summaryCover.textContent = "Image set: Alt text missing (ADA warning)";
				} else {
					ledCover.classList.add("is-active");
					var fName = imgVal.split("/").pop();
					summaryCover.textContent = (fName ? fName : "Image attached") + (isDecor ? " (Decorative)" : " · ADA Compliant");
				}
			} else {
				ledCover.classList.add("is-inactive");
				if (accCover) accCover.classList.remove("is-active-feature");
				summaryCover.textContent = "No cover image attached";
			}
		}

		// --- Feature 2: Navigation & Menu ---
		var parentSelect = document.getElementById("pgParent");
		var parentVal = parentSelect ? parentSelect.value : "";
		var menuItemCheck = document.getElementById("pgMenuItem");
		var isMenuItem = menuItemCheck ? menuItemCheck.checked : false;
		var menuTargetSelect = document.getElementById("pgMenuItemSelect");
		var menuTargetVal = menuTargetSelect ? menuTargetSelect.value.trim() : "";
		var ledNav = document.getElementById("ledNavigation");
		var summaryNav = document.getElementById("summaryNavigation");
		var accNav = document.getElementById("accItemNavigation");

		var isAssignedToMenu = (parentVal === "Assign to Main Menu Item" || parentVal === "Assign to Menu Item" || (parentVal && parentVal !== "Top Level - Called from URL"));
		if (ledNav && summaryNav) {
			ledNav.className = "led-marker";
			if (isAssignedToMenu || isMenuItem) {
				activeCount++;
				ledNav.classList.add("is-active");
				if (accNav) accNav.classList.add("is-active-feature");
				var labelParts = [];
				if (isMenuItem) labelParts.push("In main menu");
				if (isAssignedToMenu) labelParts.push(menuTargetVal ? "Parent: " + menuTargetVal : "Assigned to menu");
				summaryNav.textContent = labelParts.join(" · ") || "Assigned to navigation";
			} else {
				ledNav.classList.add("is-inactive");
				if (accNav) accNav.classList.remove("is-active-feature");
				summaryNav.textContent = "Top-level URL route";
			}
		}

		// --- Feature 3: Sidebar & Subpages ---
		var layoutSelect = document.getElementById("pgLayout");
		var layoutVal = layoutSelect ? layoutSelect.value : "Full";
		var sidebarChecked = document.querySelectorAll('input[name="sidebarIds"]:checked');
		var ledSidebar = document.getElementById("ledSidebar");
		var summarySidebar = document.getElementById("summarySidebar");
		var accSidebar = document.getElementById("accItemSidebar");

		if (ledSidebar && summarySidebar) {
			ledSidebar.className = "led-marker";
			if (layoutVal === "Right Sidebar") {
				if (sidebarChecked.length > 0) {
					activeCount++;
					ledSidebar.classList.add("is-active");
					if (accSidebar) accSidebar.classList.add("is-active-feature");
					summarySidebar.textContent = sidebarChecked.length + " subpage" + (sidebarChecked.length === 1 ? "" : "s") + " assigned";
				} else {
					ledSidebar.classList.add("is-warn");
					if (accSidebar) accSidebar.classList.add("is-active-feature");
					summarySidebar.textContent = "Right sidebar active (0 subpages selected)";
				}
			} else {
				ledSidebar.classList.add("is-inactive");
				if (accSidebar) accSidebar.classList.remove("is-active-feature");
				summarySidebar.textContent = "Full width layout (No sidebars)";
			}
		}

		// --- Feature 4: Folder Explorer ---
		var folderCheck = document.getElementById("pgFolderListingEnabled");
		var isFolder = folderCheck ? folderCheck.checked : false;
		var folderControls = document.getElementById("pgFolderListingControls");
		if (folderControls) {
			if (isFolder) folderControls.removeAttribute("hidden");
			else folderControls.setAttribute("hidden", "hidden");
		}
		var checkedFolders = document.querySelectorAll('input[name="folderListingItems"]:checked');
		var ledFolder = document.getElementById("ledFolder");
		var summaryFolder = document.getElementById("summaryFolder");
		var accFolder = document.getElementById("accItemFolder");

		if (ledFolder && summaryFolder) {
			ledFolder.className = "led-marker";
			if (isFolder) {
				if (checkedFolders.length > 0) {
					activeCount++;
					ledFolder.classList.add("is-active");
					if (accFolder) accFolder.classList.add("is-active-feature");
					summaryFolder.textContent = checkedFolders.length + " folder" + (checkedFolders.length === 1 ? "" : "s") + " selected";
				} else {
					ledFolder.classList.add("is-warn");
					if (accFolder) accFolder.classList.add("is-active-feature");
					summaryFolder.textContent = "Folder explorer enabled (0 folders selected)";
				}
			} else {
				ledFolder.classList.add("is-inactive");
				if (accFolder) accFolder.classList.remove("is-active-feature");
				summaryFolder.textContent = "Disabled";
			}
		}

		// --- Feature 5: Publishing & Scheduling ---
		var statusSelect = document.getElementById("pgStatus");
		var statusVal = statusSelect ? statusSelect.value : "Active";
		var visSelect = document.getElementById("pgVisibility");
		var visVal = visSelect ? visSelect.value : "Published";
		var pubAtInput = document.getElementById("pgPublishAt");
		var pubAtVal = pubAtInput ? pubAtInput.value.trim() : "";
		var ledPublish = document.getElementById("ledPublish");
		var summaryPublish = document.getElementById("summaryPublish");
		var pubPill = document.getElementById("publishStatusPill");

		if (pubPill) {
			pubPill.textContent = statusVal + " · " + visVal;
			if (statusVal === "Active" && visVal === "Published") {
				pubPill.className = "badge badge-success";
			} else if (visVal === "Draft") {
				pubPill.className = "badge badge-warning";
			} else if (visVal === "Scheduled") {
				pubPill.className = "badge badge-info";
			} else {
				pubPill.className = "badge badge-neutral";
			}
		}

		if (ledPublish && summaryPublish) {
			ledPublish.className = "led-marker";
			if (statusVal === "Active" && visVal === "Published") {
				activeCount++;
				ledPublish.classList.add("is-active");
				summaryPublish.textContent = "Live & Published on website";
			} else if (visVal === "Scheduled") {
				activeCount++;
				ledPublish.classList.add("is-warn");
				summaryPublish.textContent = "Scheduled" + (pubAtVal ? " for " + pubAtVal.replace("T", " ") : "");
			} else if (visVal === "Draft") {
				ledPublish.classList.add("is-warn");
				summaryPublish.textContent = "Draft · Not publicly visible";
			} else {
				ledPublish.classList.add("is-inactive");
				summaryPublish.textContent = statusVal + " · " + visVal;
			}
		}

		// Update total active badge (5 core features in the accordion deck)
		var badge = document.getElementById("featuresActiveBadge");
		if (badge) {
			badge.textContent = activeCount + " / 5 Active";
		}
	};

	// 5. Attach input listeners across all controls
	document.addEventListener("DOMContentLoaded", function() {
		var inputsToWatch = [
			"pgTitle", "pgSlug", "pgStatus", "pgVisibility", "pgPublishAt", "pgUnpublishAt",
			"featuredImage", "featuredImageAlt", "featuredImageDecorative",
			"pgParent", "pgMenuItem", "pgMenuItemSelect", "pgFolderListingEnabled"
		];
		inputsToWatch.forEach(function(id) {
			var el = document.getElementById(id);
			if (el) {
				el.addEventListener("input", window.updatePageFeaturesLedStatus);
				el.addEventListener("change", window.updatePageFeaturesLedStatus);
			}
		});

		// Checkboxes
		document.querySelectorAll('input[name="sidebarIds"], input[name="folderListingItems"]').forEach(function(cb) {
			cb.addEventListener("change", window.updatePageFeaturesLedStatus);
		});

		window.updatePageFeaturesLedStatus();
	});

	setTimeout(window.updatePageFeaturesLedStatus, 300);

	// 6. Page Features Deck & Content Toolbar — Quick-Guide Hover Tooltips ("Simple For Dummies")
	var featureGuides = {
		btnEditorImportDoc: {
			placement: "below",
			title: "Import Word / PDF",
			tag: "Time Saver",
			what: "Turns a Word (.docx) or PDF file directly into a clean webpage so you don't have to re-type or copy/paste.",
			steps: [
				"Click <strong>Import Word / PDF</strong> and drop your file into the box.",
				"Click <strong>Convert Document</strong> to preview your text, tables, and photos.",
				"Click <strong>Paste to Page Content</strong> to drop it right into the editor!"
			],
			tip: "Automatically formats headings and tables so your page passes ADA accessibility checks."
		},
		btnEditorInsertCTA: {
			placement: "below",
			title: "Embed Call to Action",
			tag: "Action Cards",
			what: "Adds eye-catching button boxes or service cards (like <em>Pay Taxes</em> or <em>Apply for a Permit</em>) into your page.",
			steps: [
				"Click <strong>Embed Call to Action</strong> to browse ready-made cards.",
				"<strong>For 1 Card:</strong> Simply click the card you want to insert.",
				"<strong>For a Row of Cards:</strong> Check the corner boxes on 2+ cards and click <strong>Embed Selected Cards as Grid</strong>."
			],
			tip: "Need to make a brand-new card? Click <strong>Open CTA Studio</strong> at the bottom of the popup."
		},
		btnEditorInsertForm: {
			placement: "below",
			title: "Embed Form",
			tag: "Online Form",
			what: "Puts a fillable online form right on your page so visitors can submit requests without printing a PDF.",
			steps: [
				"Click <strong>Embed Form</strong> to see your department's online forms.",
				"Find your form and click the blue <strong>Embed Form</strong> button next to it.",
				"Click <strong>Save Changes</strong> on your page—visitors can now fill it out right here!"
			],
			tip: "Don't see your form yet? Click <strong>Open Form Builder</strong> in the popup to create one."
		},
		accItemCoverImage: {
			title: "Featured Cover Image",
			tag: "Optional Banner",
			what: "Puts a large banner photo across the top of your page.",
			steps: [
				"Click this row to open it.",
				"Click <strong>Choose Cover Image</strong> to pick a photo.",
				"Type a short description in <strong>Alternative Text</strong> (for blind visitors), or check <strong>Mark as decorative</strong>."
			],
			lights: [
				{ dot: "green", text: "Photo + ADA description ready" },
				{ dot: "yellow", text: "Needs Alt Text description" },
				{ dot: "gray", text: "No photo used" }
			]
		},
		accItemNavigation: {
			title: "Navigation & Menu",
			tag: "Where It Lives",
			what: "Controls where visitors find this page in your department menu.",
			steps: [
				"Leave on <strong>Top Level</strong> if you only link to this page from buttons or text.",
				"Or choose <strong>Assign to Main Menu Item</strong> and pick which menu folder it belongs under.",
				"Check <strong>Show in main menu</strong> only if it belongs on the main top bar."
			],
			lights: [
				{ dot: "green", text: "Linked in a menu" },
				{ dot: "gray", text: "Standalone link (Top Level)" }
			]
		},
		accItemSidebar: {
			title: "Sidebar & Subpages",
			tag: "Right Column",
			what: "Adds extra contact boxes, links, or mini-pages along the right side of the page.",
			steps: [
				"Click <strong>Switch to Right Sidebar</strong> (or pick Right Sidebar layout on the left).",
				"Check the boxes next to the sidebars or subpages you want to show.",
				"Need a new one? Click <strong>+ Create New Subpage</strong> at the bottom."
			],
			lights: [
				{ dot: "green", text: "Sidebar on + items checked" },
				{ dot: "yellow", text: "Sidebar on, 0 items checked" },
				{ dot: "gray", text: "Full width (no sidebar)" }
			]
		},
		accItemFolder: {
			title: "Folder Explorer",
			tag: "Document Box",
			what: "Embeds a clickable folder box on your page so visitors can download PDFs and forms.",
			steps: [
				"Check <strong>Enable Folder Explorer on this page</strong>.",
				"Check the folder(s) you want visitors to see.",
				"Don't see your folder? Click <strong>+ Add Folder Item</strong> to connect one."
			],
			lights: [
				{ dot: "green", text: "Enabled + folder checked" },
				{ dot: "yellow", text: "Enabled, pick a folder" },
				{ dot: "gray", text: "Turned off" }
			]
		},
		accItemPublish: {
			title: "Publishing & Schedule",
			tag: "Who Can See It",
			what: "Controls whether the public can see this page right now, later, or not yet.",
			steps: [
				"<strong>Go Live Now:</strong> Set Status to <strong>Active</strong> and Visibility to <strong>Published</strong>.",
				"<strong>Save for Later:</strong> Set Visibility to <strong>Draft</strong> while you work on it.",
				"<strong>Auto-Post Later:</strong> Pick <strong>Scheduled</strong> and choose a Publish Date/Time."
			],
			lights: [
				{ dot: "green", text: "Live on website" },
				{ dot: "yellow", text: "Draft or Scheduled" },
				{ dot: "gray", text: "Inactive / Hidden" }
			]
		}
	};

	function initPageFeaturesQuickTooltips() {
		var tip = document.createElement("div");
		tip.id = "pgFeatureQuickTooltip";
		tip.className = "pg-feature-quick-tooltip";
		tip.setAttribute("role", "tooltip");
		tip.setAttribute("aria-hidden", "true");
		document.body.appendChild(tip);

		var activeItemId = null;

		function renderTooltipContent(info) {
			var stepsHtml = info.steps.map(function(step, idx) {
				return '<li><span class="pg-ft-step-num">' + (idx + 1) + '</span><span>' + step + '</span></li>';
			}).join("");

			var footerHtml = "";
			if (info.lights && info.lights.length) {
				var lightsHtml = info.lights.map(function(l) {
					return '<span class="pg-ft-light-item"><span class="pg-ft-dot is-' + l.dot + '"></span><span>' + l.text + '</span></span>';
				}).join("");
				footerHtml =
					'<div class="pg-ft-section">' +
						'<div class="pg-ft-label">&#128161; What the colored dot means</div>' +
						'<div class="pg-ft-lights">' + lightsHtml + '</div>' +
					'</div>';
			} else if (info.tip) {
				footerHtml =
					'<div class="pg-ft-section">' +
						'<div class="pg-ft-label">&#128161; Good to know</div>' +
						'<div class="pg-ft-lights" style="color:#e2e8f0;">' + info.tip + '</div>' +
					'</div>';
			}

			tip.innerHTML =
				'<div class="pg-ft-head">' +
					'<span class="pg-ft-title">' + info.title + '</span>' +
					'<span class="pg-ft-tag">' + info.tag + '</span>' +
				'</div>' +
				'<div class="pg-ft-section">' +
					'<div class="pg-ft-label">&#127919; What is it for?</div>' +
					'<div class="pg-ft-what">' + info.what + '</div>' +
				'</div>' +
				'<div class="pg-ft-section">' +
					'<div class="pg-ft-label">&#9889; How to use it (1-2-3)</div>' +
					'<ol class="pg-ft-steps">' + stepsHtml + '</ol>' +
				'</div>' +
				footerHtml;
		}

		function positionTooltip(targetEl, info) {
			var rect = targetEl.getBoundingClientRect();
			var tipWidth = tip.offsetWidth || 325;
			var tipHeight = tip.offsetHeight || 240;
			var gap = 12;

			tip.classList.remove("is-below", "is-above");

			if (info.placement === "below" || rect.left < tipWidth + gap + 12) {
				var centerX = rect.left + (rect.width / 2);
				var leftBelow = Math.max(12, Math.min(window.innerWidth - tipWidth - 12, centerX - (tipWidth / 2)));
				var arrowLeft = Math.max(20, Math.min(tipWidth - 20, centerX - leftBelow));
				tip.style.setProperty("--tt-arrow-left", Math.round(arrowLeft) + "px");

				var topBelow = rect.bottom + gap;
				if (topBelow + tipHeight > window.innerHeight - 12 && rect.top > tipHeight + gap + 12) {
					tip.classList.add("is-above");
					topBelow = rect.top - tipHeight - gap;
				} else {
					tip.classList.add("is-below");
				}
				tip.style.left = Math.round(leftBelow) + "px";
				tip.style.top = Math.round(topBelow) + "px";
			} else {
				var left = rect.left - tipWidth - gap;
				var top = rect.top + (rect.height / 2) - 28;
				var maxTop = window.innerHeight - tipHeight - 12;
				if (top > maxTop) top = maxTop;
				if (top < 12) top = 12;
				var arrowTop = Math.max(18, Math.min(tipHeight - 18, (rect.top + rect.height / 2) - top));
				tip.style.setProperty("--tt-arrow-top", Math.round(arrowTop) + "px");
				tip.style.left = Math.round(left) + "px";
				tip.style.top = Math.round(top) + "px";
			}
		}

		function showTooltip(itemId, targetEl) {
			var info = featureGuides[itemId];
			if (!info) return;
			activeItemId = itemId;
			renderTooltipContent(info);
			tip.classList.add("is-visible");
			tip.setAttribute("aria-hidden", "false");
			positionTooltip(targetEl, info);
		}

		function hideTooltip() {
			activeItemId = null;
			tip.classList.remove("is-visible");
			tip.setAttribute("aria-hidden", "true");
		}

		Object.keys(featureGuides).forEach(function(itemId) {
			var itemEl = document.getElementById(itemId);
			if (!itemEl) return;
			var triggerEl = itemEl.querySelector(".pg-accordion-header") || itemEl;

			triggerEl.addEventListener("mouseenter", function() {
				showTooltip(itemId, triggerEl);
			});
			triggerEl.addEventListener("mouseleave", function() {
				hideTooltip();
			});
			triggerEl.addEventListener("focus", function() {
				showTooltip(itemId, triggerEl);
			});
			triggerEl.addEventListener("blur", function() {
				hideTooltip();
			});
			triggerEl.addEventListener("click", function() {
				hideTooltip();
			});
		});

		window.addEventListener("scroll", function() {
			if (activeItemId) hideTooltip();
		}, { passive: true });
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", initPageFeaturesQuickTooltips);
	} else {
		initPageFeaturesQuickTooltips();
	}

})();
</script>