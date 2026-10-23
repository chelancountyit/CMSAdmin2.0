<cfparam name="tagRecords" default="#[]#">
<cfparam name="accessibleWorkspaces" default="#[]#">

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">Article &amp; Story Tags</h1>
			<span class="badge badge-primary" style="font-size:0.75rem; padding:0.2rem 0.6rem;">
				#ArrayLen(tagRecords)# Tags
			</span>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">PIO</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='articles', action='index')#">Articles</a></li>
				<li class="breadcrumb-item active" aria-current="page">Tags</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center;">
		<a href="#urlFor(controller='articles', action='index')#" class="btn btn-outline-secondary btn-sm">
			&larr; Back to Articles
		</a>
	</div>
</div>

<div style="display:grid; grid-template-columns:320px minmax(0, 1fr); gap:1.5rem; align-items:start;">
	<!--- Add Tag Card --->
	<div class="admin-card" style="padding:1.25rem;">
		<h3 style="margin:0 0 1rem; font-size:1rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
			Add New Tag
		</h3>
		<form id="tagForm" onsubmit="event.preventDefault(); submitTagForm();">
			<div style="margin-bottom:1rem;">
				<label for="newTagName" style="display:block; font-weight:600; font-size:0.85rem; margin-bottom:0.3rem; color:var(--admin-text-main);">
					Tag Name <span style="color:var(--admin-danger, ##ef4444);">*</span>
				</label>
				<input type="text" id="newTagName" class="form-control" placeholder="e.g. wildfire, permits, budget" required>
			</div>

			<input type="hidden" id="newTagSiteid" value="#EncodeForHTMLAttribute(activeWorkspaceId())#">

			<button type="submit" class="btn btn-primary" style="width:100%; justify-content:center;" id="btnSaveTag">
				#svgIcon(name="plus", size=14)#
				<span>Create Tag</span>
			</button>
		</form>
	</div>

	<!--- Tags List / Cloud --->
	<div class="admin-card" style="padding:0; overflow:hidden;">
		<div style="padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); display:flex; justify-content:space-between; align-items:center;">
			<h3 style="margin:0; font-size:0.95rem; font-weight:700; color:var(--admin-text-main);">
				All Registered Tags
			</h3>
			<input type="text" id="filterTagInput" class="form-control" style="max-width:200px; font-size:0.8rem; padding:0.3rem 0.6rem;" placeholder="Filter tags..." oninput="filterTagsList(this.value)">
		</div>

		<div class="table-responsive">
			<table class="table" style="margin:0; width:100%; border-collapse:collapse;">
				<thead>
					<tr style="background:var(--admin-bg); border-bottom:1.5px solid var(--admin-border);">
						<th style="padding:0.75rem 1rem;">Tag Name</th>
						<th style="padding:0.75rem 1rem; width:140px;">Slug</th>
						<th style="padding:0.75rem 1rem; width:110px; text-align:center;">Articles</th>
						<th style="padding:0.75rem 1rem; width:120px; text-align:center;">Scope</th>
						<th style="padding:0.75rem 1rem; width:90px; text-align:right;">Action</th>
					</tr>
				</thead>
				<tbody id="tagsTableBody">
					<cfif ArrayLen(tagRecords) eq 0>
						<tr>
							<td colspan="5" style="padding:2.5rem 1rem; text-align:center; color:var(--admin-text-muted);">
								No tags created yet. Tags are also auto-created when typing them in an article.
							</td>
						</tr>
					<cfelse>
						<cfloop array="#tagRecords#" index="tg">
							<tr style="border-bottom:1px solid var(--admin-border-subtle);" id="tag-row-#tg.id#" data-tag-name="#LCase(tg.name)#">
								<td style="padding:0.7rem 1rem; vertical-align:middle; font-weight:600; color:var(--admin-text-main);">
									<span class="badge badge-neutral" style="font-size:0.8rem; padding:0.25rem 0.55rem;">
										&##35;#EncodeForHTML(tg.name)#
									</span>
								</td>
								<td style="padding:0.7rem 1rem; vertical-align:middle; font-size:0.8rem; font-family:monospace; color:var(--admin-text-muted);">
									#tg.slug#
								</td>
								<td style="padding:0.7rem 1rem; vertical-align:middle; text-align:center;">
									<span class="badge badge-primary" style="font-size:0.72rem;">
										#Val(tg.usage_count ?: 0)#
									</span>
								</td>
								<td style="padding:0.7rem 1rem; vertical-align:middle; text-align:center;">
									<span class="badge" style="font-size:0.7rem; background:var(--admin-bg); border:1px solid var(--admin-border);">
										#tg.siteid#
									</span>
								</td>
								<td style="padding:0.7rem 1rem; vertical-align:middle; text-align:right;">
									<button type="button" class="btn btn-outline-danger btn-sm" onclick="deleteTagItem(#tg.id#, '#JSStringFormat(tg.name)#')" title="Delete Tag" style="padding:0.25rem 0.45rem;">
										#svgIcon(name="trash", size=13)#
									</button>
								</td>
							</tr>
						</cfloop>
					</cfif>
				</tbody>
			</table>
		</div>
	</div>
</div>
</cfoutput>

<script>
function filterTagsList(query) {
	const q = query.toLowerCase().trim();
	const rows = document.querySelectorAll('#tagsTableBody tr[data-tag-name]');
	rows.forEach(r => {
		const name = r.getAttribute('data-tag-name') || '';
		r.style.display = (name.indexOf(q) !== -1) ? '' : 'none';
	});
}

function submitTagForm() {
	const name = document.getElementById('newTagName').value.trim();
	if (!name) return;

	const btn = document.getElementById('btnSaveTag');
	if (btn) btn.disabled = true;

	const payload = {
		name: name,
		siteid: document.getElementById('newTagSiteid').value
	};

	fetch('/articles/tag/save', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json; charset=utf-8' },
		body: JSON.stringify(payload)
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			window.location.reload();
		} else {
			window.adminAlert({ title: 'Error Saving Tag', message: res.message || 'Error saving tag.', type: 'danger' });
			if (btn) btn.disabled = false;
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error saving tag.', type: 'danger' });
		if (btn) btn.disabled = false;
	});
}

async function deleteTagItem(id, name) {
	const ok = await window.adminConfirm({
		title: 'Delete Tag?',
		message: 'Are you sure you want to delete tag "' + name + '"? It will be removed from all associated articles.',
		type: 'danger',
		acceptText: 'Delete Tag'
	});
	if (!ok) return;

	fetch('/articles/tag/delete', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json; charset=utf-8' },
		body: JSON.stringify({ id: id })
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			const row = document.getElementById('tag-row-' + id);
			if (row) row.remove();
			if (window.showToast) window.showToast('Tag deleted successfully.', 'success');
		} else {
			window.adminAlert({ title: 'Error Deleting Tag', message: res.message || 'Error deleting tag.', type: 'danger' });
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error deleting tag.', type: 'danger' });
	});
}
</script>
