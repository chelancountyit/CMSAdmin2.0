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
			<button type="button" class="btn btn-outline btn-sm" onclick="closeMediaPickerModal()">Cancel</button>
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
		<button type="button" class="btn btn-outline btn-sm" onclick="closeEmbedFormModal()">Cancel</button>
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
			<button type="button" class="btn btn-outline btn-sm" onclick="closeEmbedCtaModal()">Cancel</button>
		</div>
	</div>
</div>

<!--- =========================================================================
      Feature 2.2: Page Revision History & Rollback Studio Modal (RCW 42.56)
      ========================================================================= --->
<div class="admin-modal-backdrop" id="pgRevisionsModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeRevisionsModal()" aria-hidden="true"></div>
<div class="admin-modal" id="pgRevisionsModal" role="dialog" aria-modal="true" aria-labelledby="revisionsModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:96vw; max-width:1340px; height:88vh; max-height:92vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
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
			<button type="button" class="btn btn-outline btn-sm" onclick="closeRevisionsModal()">Cancel</button>
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
<div class="admin-modal-backdrop" id="pgDocConvertModalBackdrop" style="display:none; position:fixed; inset:0; z-index:99998; background:rgba(15,23,42,0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; opacity:0; visibility:hidden; transition:opacity 0.2s ease, visibility 0.2s ease;" onclick="closeDocConvertModal()"></div>
<div class="admin-modal" id="pgDocConvertModal" role="dialog" aria-modal="true" aria-labelledby="docConvertModalTitle" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); z-index:99999; width:94%; max-width:860px; max-height:88vh; background:var(--admin-surface); border-radius:var(--radius-lg); box-shadow:0 25px 65px rgba(15,23,42,0.35); border:1px solid var(--admin-border); overflow:hidden; flex-direction:column;">
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