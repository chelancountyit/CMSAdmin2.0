<cfparam name="release" default="#{}#">
<cfparam name="isNew" default="true">
<cfparam name="accessibleWorkspaces" default="#[]#">
<cfparam name="activeWorkspaceId" default="global">

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">#(isNew ? "New Press Release" : "Edit Press Release: " & EncodeForHTML(release.title ?: ""))#</h1>
			<cfif !isNew>
				<cfif (release.status ?: "") eq "released">
					<span class="badge badge-success" style="font-size:0.75rem;">Released Live</span>
				<cfelseif (release.status ?: "") eq "embargoed" or ((release.is_embargoed ?: false) and IsDate(release.embargo_until ?: "") and (release.embargo_until ?: Now()) gt Now())>
					<span class="badge badge-danger" style="font-size:0.75rem;">Embargoed</span>
				<cfelseif (release.status ?: "") eq "draft">
					<span class="badge badge-warning" style="font-size:0.75rem;">Draft</span>
				<cfelse>
					<span class="badge badge-neutral" style="font-size:0.75rem;">#release.status ?: ""#</span>
				</cfif>
			</cfif>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">PIO</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='pressReleases', action='index')#">Press Releases</a></li>
				<li class="breadcrumb-item active" aria-current="page">#(isNew ? "New" : "Edit")#</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center;">
		<cfif !isNew and Val(release.id ?: 0) gt 0>
			<a href="#urlFor(controller='pressReleases', action='view', params='id=#release.id#')#" target="_blank" class="btn btn-outline-secondary btn-sm" title="View Official Printer Release">
				#svgIcon(name="eye", size=14)#
				<span>View Official Release</span>
			</a>
		</cfif>
		<a href="#urlFor(controller='pressReleases', action='index')#" class="btn btn-outline-secondary btn-sm">
			Cancel
		</a>
		<button type="button" class="btn btn-primary btn-sm" onclick="saveReleaseForm()" id="btnSaveTop">
			#svgIcon(name="check-circle", size=14)#
			<span>Save Press Release</span>
		</button>
	</div>
</div>

<form id="releaseForm" onsubmit="event.preventDefault(); saveReleaseForm();">
	<input type="hidden" name="id" id="releaseId" value="#Val(release.id ?: 0)#">

	<div style="display:grid; grid-template-columns:minmax(0, 1fr) 340px; gap:1.5rem; align-items:start;">
		<!--- Main Content Column --->
		<div style="display:flex; flex-direction:column; gap:1.25rem;">
			<!--- Title, Dateline & Slug --->
			<div class="admin-card" style="padding:1.25rem;">
				<div style="margin-bottom:1.1rem;">
					<label for="releaseTitle" style="display:block; font-weight:600; font-size:0.9rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
						Press Release Headline <span style="color:var(--admin-danger, ##ef4444);">*</span>
					</label>
					<input type="text" id="releaseTitle" name="title" class="form-control" style="font-size:1.15rem; font-weight:600; padding:0.65rem 0.85rem;" placeholder="e.g. Chelan County Announces Public Hearing on 2026 Comprehensive Plan" value="#EncodeForHTML(release.title ?: "")#" required oninput="if (#isNew ? 'true' : 'false'#) autoReleaseSlug(this.value);">
				</div>

				<div style="display:grid; grid-template-columns:220px minmax(0, 1fr); gap:1rem; align-items:start;">
					<div>
						<label for="releaseDateline" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
							Dateline (City, State)
						</label>
						<input type="text" id="releaseDateline" name="dateline" class="form-control" style="font-size:0.85rem;" value="#EncodeForHTML(release.dateline ?: "WENATCHEE, WA")#" placeholder="WENATCHEE, WA">
					</div>
					<div>
						<label for="releaseSlug" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
							URL Slug
						</label>
						<div style="display:flex; align-items:center; border:1px solid var(--admin-border); border-radius:var(--radius-md); overflow:hidden; background:var(--admin-bg);">
							<span style="padding:0.45rem 0.65rem; color:var(--admin-text-muted); font-size:0.8rem; border-right:1px solid var(--admin-border); font-family:monospace;">
								/press/
							</span>
							<input type="text" id="releaseSlug" name="slug" class="form-control" style="border:none; border-radius:0; background:transparent; font-size:0.85rem; font-family:monospace; padding:0.45rem 0.65rem;" value="#EncodeForHTML(release.slug ?: "")#" placeholder="chelan-county-public-hearing">
						</div>
					</div>
				</div>
			</div>

			<!--- Lead Summary / Subhead --->
			<div class="admin-card" style="padding:1.25rem;">
				<label for="releaseSummary" style="display:block; font-weight:600; font-size:0.9rem; margin-bottom:0.35rem; color:var(--admin-text-main);">
					Executive Summary / Sub-headline
				</label>
				<p style="font-size:0.78rem; color:var(--admin-text-muted); margin-top:0; margin-bottom:0.5rem;">
					A concise summary of key dates, decisions, or actions for wire services and news desks (max 1000 characters).
				</p>
				<textarea id="releaseSummary" name="summary" class="form-control" rows="3" maxlength="1000" style="font-size:0.9rem; resize:vertical;" placeholder="Brief summary of the announcement...">#EncodeForHTML(release.summary ?: "")#</textarea>
			</div>

			<!--- Full Release Body with JBDEditor --->
			<div class="admin-card" style="padding:1.25rem;">
				<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
					<label for="releaseContent" style="display:block; font-weight:600; font-size:0.9rem; margin:0; color:var(--admin-text-main);">
						Full Release Text <span style="color:var(--admin-danger, ##ef4444);">*</span>
					</label>
					<span style="font-size:0.75rem; color:var(--admin-text-muted);">
						Accessible JBDEditor &bull; Standard Municipal Release Format
					</span>
				</div>
				<textarea id="releaseContent" name="content_html" data-jbd-editor data-jbd-toolbar="basic" data-jbd-inline-toolbar="true" data-jbd-height="420px" data-jbd-placeholder="Type official press release copy here...">#EncodeForHTML(release.content_html ?: "")#</textarea>
			</div>
		</div>

		<!--- Sidebar Column --->
		<div style="display:flex; flex-direction:column; gap:1.25rem;">
			<!--- Publish Controls Card --->
			<div class="admin-card" style="padding:1.25rem;">
				<h3 style="margin:0 0 1rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					Release Status
				</h3>

				<div style="margin-bottom:1rem;">
					<label for="releaseStatus" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Status
					</label>
					<select id="releaseStatus" name="status" class="form-control">
						<option value="released" <cfif (release.status ?: "") eq "released">selected</cfif>>Released Live</option>
						<option value="embargoed" <cfif (release.status ?: "") eq "embargoed">selected</cfif>>Hold Under Embargo</option>
						<option value="draft" <cfif (release.status ?: "") eq "draft">selected</cfif>>Internal Draft</option>
						<option value="archived" <cfif (release.status ?: "") eq "archived">selected</cfif>>Archived</option>
					</select>
				</div>

				<div style="margin-bottom:1rem;">
					<label for="releasedAt" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Release Date &amp; Time
					</label>
					<input type="datetime-local" id="releasedAt" name="released_at" class="form-control" value="#DateFormat(release.released_at ?: Now(), 'yyyy-mm-dd')#T#TimeFormat(release.released_at ?: Now(), 'HH:mm')#">
				</div>

				<div style="margin-bottom:1.25rem;">
					<label for="siteid" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Workspace Scope
					</label>
					<select id="siteid" name="siteid" class="form-control">
						<option value="global" <cfif (release.siteid ?: "global") eq "global">selected</cfif>>Global (County-Wide Rollup)</option>
						<cfloop array="#accessibleWorkspaces#" index="ws">
							<cfif ws.id neq "all" and ws.id neq "global">
								<option value="#ws.id#" <cfif (release.siteid ?: "") eq ws.id>selected</cfif>>#EncodeForHTML(ws.name)#</option>
							</cfif>
						</cfloop>
					</select>
				</div>

				<button type="button" class="btn btn-primary" style="width:100%; justify-content:center; padding:0.6rem;" onclick="saveReleaseForm()" id="btnSaveSidebar">
					#svgIcon(name="check-circle", size=15)#
					<span>Save Press Release</span>
				</button>
			</div>

			<!--- Embargo Settings Card --->
			<div class="admin-card" style="padding:1.25rem; border-left:4px solid ##dc2626;">
				<h3 style="margin:0 0 0.75rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem; display:flex; align-items:center; gap:0.5rem;">
					#svgIcon(name="clock", size=16)#
					<span>Embargo Controls</span>
				</h3>

				<div style="margin-bottom:0.75rem;">
					<label style="display:flex; align-items:center; gap:0.5rem; cursor:pointer; font-weight:600; font-size:0.85rem; color:var(--admin-text-main);">
						<input type="checkbox" id="isEmbargoed" name="is_embargoed" value="1" <cfif (release.is_embargoed ?: false)>checked</cfif> onchange="toggleEmbargoField(this.checked)">
						Hold Under Media Embargo
					</label>
				</div>

				<div id="embargoUntilWrap" style="<cfif !(release.is_embargoed ?: false)>display:none;</cfif>">
					<label for="embargoUntil" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-danger, ##dc2626);">
						Embargo Until Date &amp; Time
					</label>
					<input type="datetime-local" id="embargoUntil" name="embargo_until" class="form-control" value="<cfif IsDate(release.embargo_until ?: '')>#DateFormat(release.embargo_until, 'yyyy-mm-dd')#T#TimeFormat(release.embargo_until, 'HH:mm')#</cfif>">
					<p style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.35rem; margin-bottom:0;">
						Public APIs will withhold full release copy until this time passes.
					</p>
				</div>
			</div>

			<!--- Media Contact Information --->
			<div class="admin-card" style="padding:1.25rem;">
				<h3 style="margin:0 0 0.75rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					Media Contact
				</h3>

				<div style="margin-bottom:0.75rem;">
					<label for="contactName" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Contact Name
					</label>
					<input type="text" id="contactName" name="contact_name" class="form-control" value="#EncodeForHTML(release.contact_name ?: "Chelan County Communications")#">
				</div>

				<div style="margin-bottom:0.75rem;">
					<label for="contactTitle" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Contact Title / Role
					</label>
					<input type="text" id="contactTitle" name="contact_title" class="form-control" value="#EncodeForHTML(release.contact_title ?: "Public Information Office")#">
				</div>

				<div style="margin-bottom:0.75rem;">
					<label for="contactPhone" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Phone Number
					</label>
					<input type="tel" id="contactPhone" name="contact_phone" class="form-control" value="#EncodeForHTML(release.contact_phone ?: "(509) 667-6200")#">
				</div>

				<div>
					<label for="contactEmail" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Email Address
					</label>
					<input type="email" id="contactEmail" name="contact_email" class="form-control" value="#EncodeForHTML(release.contact_email ?: "pio@co.chelan.wa.us")#">
				</div>
			</div>

			<!--- PDF Attachment Card --->
			<div class="admin-card" style="padding:1.25rem;">
				<h3 style="margin:0 0 0.75rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					PDF Document Download
				</h3>

				<div>
					<label for="pdfUrl" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Official Signed PDF URL
					</label>
					<input type="text" id="pdfUrl" name="pdf_url" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(release.pdf_url ?: "")#" placeholder="/assets/media/press/release.pdf">
					<p style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.35rem; margin-bottom:0;">
						Optional link to a stamped or signed PDF copy for press kits.
					</p>
				</div>
			</div>
		</div>
	</div>
</form>
</cfoutput>

<script>
function autoReleaseSlug(val) {
	if (!val) return;
	const slug = val.toLowerCase()
		.replace(/[^a-z0-9\s-]/g, '')
		.replace(/[\s-]+/g, '-')
		.replace(/^-+|-+$/g, '')
		.substring(0, 255);
	document.getElementById('releaseSlug').value = slug;
}

function toggleEmbargoField(checked) {
	const wrap = document.getElementById('embargoUntilWrap');
	const statusSelect = document.getElementById('releaseStatus');
	if (checked) {
		wrap.style.display = 'block';
		if (statusSelect.value === 'released') {
			statusSelect.value = 'embargoed';
		}
	} else {
		wrap.style.display = 'none';
		if (statusSelect.value === 'embargoed') {
			statusSelect.value = 'released';
		}
	}
}

function saveReleaseForm() {
	const title = document.getElementById('releaseTitle').value.trim();
	if (!title) {
		window.adminAlert({ title: 'Headline Required', message: 'Please enter a press release headline.', type: 'warning' });
		document.getElementById('releaseTitle').focus();
		return;
	}

	let contentHtml = '';
	const textarea = document.getElementById('releaseContent');
	if (typeof JBDEditor !== 'undefined' && JBDEditor.get && JBDEditor.get(textarea)) {
		contentHtml = JBDEditor.get(textarea).getHTML();
	} else {
		contentHtml = textarea.value.trim();
	}

	if (!contentHtml || contentHtml.length === 0) {
		window.adminAlert({ title: 'Body Required', message: 'Please provide content body for the press release.', type: 'warning' });
		return;
	}

	const btnTop = document.getElementById('btnSaveTop');
	const btnSide = document.getElementById('btnSaveSidebar');
	if (btnTop) btnTop.disabled = true;
	if (btnSide) btnSide.disabled = true;

	const isEmbargoed = document.getElementById('isEmbargoed').checked;
	const embargoUntil = document.getElementById('embargoUntil').value;

	const payload = {
		id: parseInt(document.getElementById('releaseId').value || '0', 10),
		title: title,
		slug: document.getElementById('releaseSlug').value.trim(),
		dateline: document.getElementById('releaseDateline').value.trim(),
		summary: document.getElementById('releaseSummary').value.trim(),
		content_html: contentHtml,
		is_embargoed: isEmbargoed ? 1 : 0,
		embargo_until: isEmbargoed ? embargoUntil : '',
		contact_name: document.getElementById('contactName').value.trim(),
		contact_title: document.getElementById('contactTitle').value.trim(),
		contact_phone: document.getElementById('contactPhone').value.trim(),
		contact_email: document.getElementById('contactEmail').value.trim(),
		pdf_url: document.getElementById('pdfUrl').value.trim(),
		status: document.getElementById('releaseStatus').value,
		siteid: document.getElementById('siteid').value,
		released_at: document.getElementById('releasedAt').value
	};

	fetch('/press-releases/save', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(payload)
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			window.location.href = res.data && res.data.redirect ? res.data.redirect : '/press-releases';
		} else {
			window.adminAlert({ title: 'Error Saving Press Release', message: res.message || 'Error saving press release.', type: 'danger' });
			if (btnTop) btnTop.disabled = false;
			if (btnSide) btnSide.disabled = false;
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error while saving press release.', type: 'danger' });
		if (btnTop) btnTop.disabled = false;
		if (btnSide) btnSide.disabled = false;
	});
}
</script>
