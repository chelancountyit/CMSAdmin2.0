<cfparam name="categories" default="#[]#">
<cfparam name="accessibleWorkspaces" default="#[]#">

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">Article &amp; News Categories</h1>
			<span class="badge badge-primary" style="font-size:0.75rem; padding:0.2rem 0.6rem;">
				#ArrayLen(categories)# Categories
			</span>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">PIO</li>
				<li class="breadcrumb-item"><a href="#urlFor(controller='articles', action='index')#">Articles</a></li>
				<li class="breadcrumb-item active" aria-current="page">Categories</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center;">
		<a href="#urlFor(controller='articles', action='index')#" class="btn btn-outline-secondary btn-sm">
			&larr; Back to Articles
		</a>
		<button type="button" class="btn btn-primary btn-sm" onclick="openCategoryModal()">
			#svgIcon(name="plus", size=14)#
			<span>+ Add Category</span>
		</button>
	</div>
</div>

<div class="admin-card" style="padding:0; overflow:hidden;">
	<div class="table-responsive">
		<table class="table" style="margin:0; width:100%; border-collapse:collapse;">
			<thead>
				<tr style="background:var(--admin-bg); border-bottom:1.5px solid var(--admin-border);">
					<th style="padding:0.85rem 1rem; width:45px; text-align:center;">Color</th>
					<th style="padding:0.85rem 1rem;">Category Name &amp; Slug</th>
					<th style="padding:0.85rem 1rem;">Description</th>
					<th style="padding:0.85rem 1rem; width:120px; text-align:center;">Articles</th>
					<th style="padding:0.85rem 1rem; width:100px; text-align:center;">Order</th>
					<th style="padding:0.85rem 1rem; width:120px; text-align:center;">Scope</th>
					<th style="padding:0.85rem 1rem; width:130px; text-align:right;">Actions</th>
				</tr>
			</thead>
			<tbody id="categoriesTableBody">
				<cfif ArrayLen(categories) eq 0>
					<tr>
						<td colspan="7" style="padding:3rem 1.5rem; text-align:center; color:var(--admin-text-muted);">
							<p style="margin:0 0 1rem; font-size:0.9rem;">No categories defined yet.</p>
							<button type="button" class="btn btn-primary btn-sm" onclick="openCategoryModal()">
								+ Create Category
							</button>
						</td>
					</tr>
				<cfelse>
					<cfloop array="#categories#" index="cat">
						<tr style="border-bottom:1px solid var(--admin-border-subtle);" id="cat-row-#cat.id#">
							<td style="padding:0.75rem 1rem; text-align:center; vertical-align:middle;">
								<span style="display:inline-block; width:22px; height:22px; border-radius:var(--radius-sm); background-color:#cat.badge_color#; border:1px solid rgba(0,0,0,0.15); box-shadow:0 1px 2px rgba(0,0,0,0.1);"></span>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle;">
								<div style="font-weight:600; color:var(--admin-text-main);">
									#EncodeForHTML(cat.name)#
								</div>
								<div style="font-size:0.75rem; color:var(--admin-text-muted); font-family:monospace;">
									/#cat.slug#
								</div>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; font-size:0.85rem; color:var(--admin-text-muted);">
								#EncodeForHTML(cat.description ?: "—")#
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:center;">
								<span class="badge badge-neutral" style="font-size:0.75rem; font-weight:600;">
									#Val(cat.article_count ?: 0)#
								</span>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:center; font-size:0.85rem; color:var(--admin-text-muted);">
								#Val(cat.sort_order ?: 0)#
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:center;">
								<span class="badge" style="font-size:0.7rem; background:var(--admin-bg); border:1px solid var(--admin-border);">
									#cat.siteid#
								</span>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:right;">
								<div style="display:inline-flex; gap:0.35rem; align-items:center;">
									<button type="button" class="btn btn-outline-secondary btn-sm" onclick='editCategory(#SerializeJSON(cat)#)' title="Edit Category" style="padding:0.3rem 0.5rem;">
										#svgIcon(name="edit", size=13)#
									</button>
									<button type="button" class="btn btn-outline-danger btn-sm" onclick="deleteCategory(#cat.id#, '#JSStringFormat(cat.name)#')" title="Delete Category" style="padding:0.3rem 0.5rem;">
										#svgIcon(name="trash", size=13)#
									</button>
								</div>
							</td>
						</tr>
					</cfloop>
				</cfif>
			</tbody>
		</table>
	</div>
</div>

<!--- Category Modal Dialog --->
<div id="categoryModal" class="modal-backdrop" style="display:none; position:fixed; inset:0; z-index:9999; background:rgba(15,23,42,0.6); backdrop-filter:blur(4px); align-items:center; justify-content:center;">
	<div class="admin-card modal-dialog" style="max-width:520px; width:92%; margin:auto; box-shadow:0 20px 40px rgba(0,0,0,0.3); padding:1.5rem;">
		<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.75rem;">
			<h3 id="catModalTitle" style="margin:0; font-size:1.1rem; font-weight:700; color:var(--admin-text-main);">
				Add Category
			</h3>
			<button type="button" onclick="closeCategoryModal()" style="border:none; background:none; cursor:pointer; color:var(--admin-text-muted); font-size:1.2rem; line-height:1;">
				&times;
			</button>
		</div>

		<form id="categoryForm" onsubmit="event.preventDefault(); submitCategoryForm();">
			<input type="hidden" id="modalCatId" value="0">

			<div style="margin-bottom:1rem;">
				<label for="modalCatName" style="display:block; font-weight:600; font-size:0.85rem; margin-bottom:0.3rem; color:var(--admin-text-main);">
					Category Name <span style="color:var(--admin-danger, ##ef4444);">*</span>
				</label>
				<input type="text" id="modalCatName" class="form-control" required placeholder="e.g. Public Safety, Commissioners, Roads" oninput="autoCatSlug(this.value)">
			</div>

			<div style="margin-bottom:1rem;">
				<label for="modalCatSlug" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
					URL Slug
				</label>
				<input type="text" id="modalCatSlug" class="form-control" placeholder="public-safety">
			</div>

			<div style="margin-bottom:1rem;">
				<label style="display:block; font-weight:600; font-size:0.85rem; margin-bottom:0.3rem; color:var(--admin-text-main);">
					Badge Color &amp; Swatch
				</label>
				<div style="display:flex; gap:0.5rem; align-items:center;">
					<input type="color" id="modalCatColorPicker" value="##0284c7" style="width:40px; height:38px; border:1px solid var(--admin-border); border-radius:var(--radius-sm); cursor:pointer; padding:2px;" onchange="document.getElementById('modalCatColor').value = this.value">
					<input type="text" id="modalCatColor" class="form-control" value="##0284c7" style="width:120px; font-family:monospace;" oninput="document.getElementById('modalCatColorPicker').value = this.value">
					<div style="display:flex; gap:4px; margin-left:auto;">
						<span onclick="setModalColor('##0284c7')" style="width:20px; height:20px; border-radius:3px; background:##0284c7; cursor:pointer;" title="Blue"></span>
						<span onclick="setModalColor('##16a34a')" style="width:20px; height:20px; border-radius:3px; background:##16a34a; cursor:pointer;" title="Green"></span>
						<span onclick="setModalColor('##d97706')" style="width:20px; height:20px; border-radius:3px; background:##d97706; cursor:pointer;" title="Amber"></span>
						<span onclick="setModalColor('##dc2626')" style="width:20px; height:20px; border-radius:3px; background:##dc2626; cursor:pointer;" title="Red"></span>
						<span onclick="setModalColor('##8b5cf6')" style="width:20px; height:20px; border-radius:3px; background:##8b5cf6; cursor:pointer;" title="Purple"></span>
						<span onclick="setModalColor('##0d9488')" style="width:20px; height:20px; border-radius:3px; background:##0d9488; cursor:pointer;" title="Teal"></span>
					</div>
				</div>
			</div>

			<div style="margin-bottom:1rem;">
				<label for="modalCatDesc" style="display:block; font-weight:600; font-size:0.85rem; margin-bottom:0.3rem; color:var(--admin-text-main);">
					Description (Optional)
				</label>
				<textarea id="modalCatDesc" class="form-control" rows="2" placeholder="Brief description of stories in this category..."></textarea>
			</div>

			<div style="margin-bottom:1.5rem;">
				<div>
					<label for="modalCatOrder" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Sort Order
					</label>
					<input type="number" id="modalCatOrder" class="form-control" value="0">
				</div>
				<input type="hidden" id="modalCatSiteid" value="#EncodeForHTMLAttribute(activeWorkspaceId())#">
			</div>

			<div style="display:flex; justify-content:flex-end; gap:0.6rem;">
				<button type="button" class="btn btn-outline-secondary btn-sm" onclick="closeCategoryModal()">
					Cancel
				</button>
				<button type="submit" class="btn btn-primary btn-sm" id="btnSaveCat">
					Save Category
				</button>
			</div>
		</form>
	</div>
</div>
</cfoutput>

<script>
function autoCatSlug(val) {
	if (parseInt(document.getElementById('modalCatId').value, 10) > 0) return; // don't overwrite if editing
	const slug = val.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/[\s-]+/g, '-').replace(/^-+|-+$/g, '');
	document.getElementById('modalCatSlug').value = slug;
}

function setModalColor(hex) {
	document.getElementById('modalCatColor').value = hex;
	document.getElementById('modalCatColorPicker').value = hex;
}

function openCategoryModal() {
	document.getElementById('modalCatId').value = '0';
	document.getElementById('catModalTitle').innerText = 'Add Category';
	document.getElementById('modalCatName').value = '';
	document.getElementById('modalCatSlug').value = '';
	setModalColor('#0284c7');
	document.getElementById('modalCatDesc').value = '';
	document.getElementById('modalCatOrder').value = '0';
	document.getElementById('modalCatSiteid').value = 'global';
	const modal = document.getElementById('categoryModal');
	modal.style.display = 'flex';
	document.getElementById('modalCatName').focus();
}

function editCategory(cat) {
	document.getElementById('modalCatId').value = cat.id || 0;
	document.getElementById('catModalTitle').innerText = 'Edit Category: ' + (cat.name || '');
	document.getElementById('modalCatName').value = cat.name || '';
	document.getElementById('modalCatSlug').value = cat.slug || '';
	setModalColor(cat.badge_color || '#0284c7');
	document.getElementById('modalCatDesc').value = cat.description || '';
	document.getElementById('modalCatOrder').value = cat.sort_order || 0;
	document.getElementById('modalCatSiteid').value = cat.siteid || 'global';
	const modal = document.getElementById('categoryModal');
	modal.style.display = 'flex';
	document.getElementById('modalCatName').focus();
}

function closeCategoryModal() {
	document.getElementById('categoryModal').style.display = 'none';
}

function submitCategoryForm() {
	const name = document.getElementById('modalCatName').value.trim();
	if (!name) {
		window.adminAlert({ title: 'Validation Required', message: 'Category name is required.', type: 'warning' });
		return;
	}

	const payload = {
		id: parseInt(document.getElementById('modalCatId').value || '0', 10),
		name: name,
		slug: document.getElementById('modalCatSlug').value.trim(),
		badge_color: document.getElementById('modalCatColor').value.trim(),
		description: document.getElementById('modalCatDesc').value.trim(),
		sort_order: parseInt(document.getElementById('modalCatOrder').value || '0', 10),
		siteid: document.getElementById('modalCatSiteid').value
	};

	const btn = document.getElementById('btnSaveCat');
	if (btn) btn.disabled = true;

	fetch('/articles/category/save', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(payload)
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			window.location.reload();
		} else {
			window.adminAlert({ title: 'Error', message: res.message || 'Error saving category.', type: 'danger' });
			if (btn) btn.disabled = false;
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error saving category.', type: 'danger' });
		if (btn) btn.disabled = false;
	});
}

async function deleteCategory(id, name) {
	const ok = await window.adminConfirm({
		title: 'Delete Category?',
		message: 'Are you sure you want to delete category "' + name + '"? Articles in this category will become unassigned.',
		type: 'danger',
		acceptText: 'Delete Category'
	});
	if (!ok) return;

	fetch('/articles/category/delete', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ id: id })
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			const row = document.getElementById('cat-row-' + id);
			if (row) row.remove();
			if (window.showToast) window.showToast('Category deleted successfully.', 'success');
		} else {
			window.adminAlert({ title: 'Error', message: res.message || 'Error deleting category.', type: 'danger' });
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error deleting category.', type: 'danger' });
	});
}
</script>
