<cfparam name="articles" default="#[]#">
<cfparam name="stats" default="#{}#">
<cfparam name="categories" default="#[]#">
<cfparam name="filterStatus" default="all">
<cfparam name="filterCategory" default="0">
<cfparam name="searchQuery" default="">
<cfparam name="activeWorkspaceId" default="global">

<cfoutput>
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.25rem;">
			<h1 class="page-title" style="margin:0;">Articles &amp; News Posts</h1>
			<span class="badge badge-primary" style="font-size:0.75rem; padding:0.2rem 0.6rem;">
				#Val(stats.total ?: ArrayLen(articles))# Total
			</span>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.25rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">PIO</li>
				<li class="breadcrumb-item active" aria-current="page">Articles &amp; Posts</li>
			</ol>
		</nav>
	</div>
	<div class="page-header-actions" style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="#urlFor(controller='articles', action='categories')#" class="btn btn-outline-secondary btn-sm" title="Manage News Categories">
			#svgIcon(name="folder", size=14)#
			<span>Categories (#ArrayLen(categories)#)</span>
		</a>
		<a href="#urlFor(controller='articles', action='tags')#" class="btn btn-outline-secondary btn-sm" title="Manage News Tags">
			#svgIcon(name="tag", size=14)#
			<span>Tags</span>
		</a>
		<a href="#urlFor(controller='articles', action='api', params='limit=10')#" target="_blank" class="btn btn-outline-secondary btn-sm" title="View Public JSON API Feed">
			#svgIcon(name="code", size=14)#
			<span>JSON API</span>
		</a>
		<a href="#urlFor(controller='articles', action='new')#" class="btn btn-primary btn-sm">
			#svgIcon(name="plus", size=14)#
			<span>+ Add New Article</span>
		</a>
	</div>
</div>

<!--- Metric Cards --->
<div class="grid grid-4" style="margin-bottom:1.5rem; gap:1rem;">
	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid var(--admin-primary);">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(2, 132, 199, 0.1); display:flex; align-items:center; justify-content:center; color:var(--admin-primary);">
			#svgIcon(name="article", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">All Stories</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#Val(stats.total ?: 0)#</div>
		</div>
	</div>

	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid ##16a34a;">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(22, 163, 74, 0.1); display:flex; align-items:center; justify-content:center; color:##16a34a;">
			#svgIcon(name="check-circle", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">Published Live</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#Val(stats.published ?: 0)#</div>
		</div>
	</div>

	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid ##d97706;">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(217, 119, 6, 0.1); display:flex; align-items:center; justify-content:center; color:##d97706;">
			#svgIcon(name="clock", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">Drafts</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#Val(stats.draft ?: 0)#</div>
		</div>
	</div>

	<div class="admin-card" style="padding:1.1rem; display:flex; align-items:center; gap:1rem; border-left:4px solid ##8b5cf6;">
		<div style="width:42px; height:42px; border-radius:var(--radius-md); background:rgba(139, 92, 246, 0.1); display:flex; align-items:center; justify-content:center; color:##8b5cf6;">
			#svgIcon(name="folder", size=22)#
		</div>
		<div>
			<div style="font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em; color:var(--admin-text-muted); font-weight:600;">Categories</div>
			<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); line-height:1.2;">#ArrayLen(categories)#</div>
		</div>
	</div>
</div>

<!--- Search and Filter Toolbar --->
<div class="admin-card" style="padding:1rem; margin-bottom:1.5rem;">
	<form method="get" action="#urlFor(controller='articles', action='index')#" style="display:flex; gap:0.75rem; align-items:center; flex-wrap:wrap;">
		<div style="position:relative; flex:1; min-width:240px;">
			<input type="text" name="q" value="#EncodeForHTML(searchQuery)#" placeholder="Search articles by title, author, summary or tag..." class="form-control" style="padding-left:2.2rem; width:100%;">
			<span style="position:absolute; left:0.75rem; top:50%; transform:translateY(-50%); color:var(--admin-text-muted); pointer-events:none;">
				#svgIcon(name="search", size=15)#
			</span>
		</div>

		<div style="min-width:160px;">
			<select name="status" class="form-control" onchange="this.form.submit()">
				<option value="all" <cfif filterStatus eq 'all'>selected</cfif>>All Statuses</option>
				<option value="published" <cfif filterStatus eq 'published'>selected</cfif>>Published Only</option>
				<option value="draft" <cfif filterStatus eq 'draft'>selected</cfif>>Drafts Only</option>
				<option value="archived" <cfif filterStatus eq 'archived'>selected</cfif>>Archived</option>
			</select>
		</div>

		<div style="min-width:180px;">
			<select name="category" class="form-control" onchange="this.form.submit()">
				<option value="0" <cfif Val(filterCategory) eq 0>selected</cfif>>All Categories</option>
				<cfloop array="#categories#" index="cat">
					<option value="#cat.id#" <cfif Val(filterCategory) eq cat.id>selected</cfif>>#EncodeForHTML(cat.name)#</option>
				</cfloop>
			</select>
		</div>

		<button type="submit" class="btn btn-secondary btn-sm" style="padding:0.45rem 0.9rem;">
			Filter
		</button>
		<cfif Len(searchQuery) or filterStatus neq 'all' or Val(filterCategory) gt 0>
			<a href="#urlFor(controller='articles', action='index')#" class="btn btn-outline-secondary btn-sm" style="padding:0.45rem 0.8rem;" title="Reset filters">
				#svgIcon(name="x", size=14)# Clear
			</a>
		</cfif>
	</form>
</div>

<!--- Articles Table --->
<div class="admin-card" style="padding:0; overflow:hidden;">
	<div class="table-responsive">
		<table class="table" style="margin:0; width:100%; border-collapse:collapse;">
			<thead>
				<tr style="background:var(--admin-bg); border-bottom:1.5px solid var(--admin-border);">
					<th style="padding:0.85rem 1rem; width:70px; text-align:center;">Image</th>
					<th style="padding:0.85rem 1rem;">Article Headline &amp; Details</th>
					<th style="padding:0.85rem 1rem; width:150px;">Category</th>
					<th style="padding:0.85rem 1rem; width:130px;">Author</th>
					<th style="padding:0.85rem 1rem; width:110px; text-align:center;">Status</th>
					<th style="padding:0.85rem 1rem; width:140px;">Published</th>
					<th style="padding:0.85rem 1rem; width:150px; text-align:right;">Actions</th>
				</tr>
			</thead>
			<tbody>
				<cfif ArrayLen(articles) eq 0>
					<tr>
						<td colspan="7" style="padding:3rem 1.5rem; text-align:center; color:var(--admin-text-muted);">
							<div style="margin-bottom:0.75rem; color:var(--admin-text-muted);">
								#svgIcon(name="article", size=40)#
							</div>
							<h3 style="margin:0 0 0.5rem; font-size:1.1rem; color:var(--admin-text-main);">No articles found</h3>
							<p style="margin:0 0 1rem; font-size:0.875rem;">Get started by drafting your first county news article or announcement.</p>
							<a href="#urlFor(controller='articles', action='new')#" class="btn btn-primary btn-sm">
								#svgIcon(name="plus", size=14)# Add New Article
							</a>
						</td>
					</tr>
				<cfelse>
					<cfloop array="#articles#" index="art">
						<tr style="border-bottom:1px solid var(--admin-border-subtle); transition:background 0.15s ease;" id="article-row-#art.id#">
							<td style="padding:0.75rem 1rem; text-align:center; vertical-align:middle;">
								<cfif Len(art.featured_image)>
									<img src="#EncodeForHTML(art.featured_image)#" alt="" style="width:48px; height:48px; object-fit:cover; border-radius:var(--radius-sm); border:1px solid var(--admin-border);">
								<cfelse>
									<div style="width:48px; height:48px; border-radius:var(--radius-sm); background:var(--admin-bg); border:1px dashed var(--admin-border); display:inline-flex; align-items:center; justify-content:center; color:var(--admin-text-muted);">
										#svgIcon(name="article", size=20)#
									</div>
								</cfif>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle;">
								<div style="font-weight:600; font-size:0.95rem; color:var(--admin-text-main); margin-bottom:0.2rem;">
									<a href="#urlFor(controller='articles', action='edit', params='id=#art.id#')#" style="color:var(--admin-text-main); text-decoration:none;">
										#EncodeForHTML(art.title)#
									</a>
								</div>
								<cfif Len(art.summary)>
									<div style="font-size:0.8rem; color:var(--admin-text-muted); line-height:1.35; margin-bottom:0.3rem;">
										#EncodeForHTML(art.summary)#
									</div>
								</cfif>
								<div style="display:flex; gap:0.5rem; align-items:center; flex-wrap:wrap;">
									<span style="font-size:0.72rem; color:var(--admin-text-muted); font-family:monospace;">/#art.slug#</span>
									<cfif Len(art.tags)>
										<cfloop list="#art.tags#" index="t">
											<span class="badge badge-neutral" style="font-size:0.68rem; padding:0.1rem 0.4rem;">
												&##35;#EncodeForHTML(Trim(t))#
											</span>
										</cfloop>
									</cfif>
								</div>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle;">
								<span class="badge" style="background-color:#art.category_color#18; color:#art.category_color#; border:1px solid #art.category_color#40; font-size:0.75rem; padding:0.25rem 0.55rem; font-weight:600;">
									#EncodeForHTML(art.category_name)#
								</span>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; font-size:0.85rem;">
								<div style="font-weight:500; color:var(--admin-text-main);">#EncodeForHTML(art.author_name)#</div>
								<cfif Len(art.author_title)>
									<div style="font-size:0.72rem; color:var(--admin-text-muted);">#EncodeForHTML(art.author_title)#</div>
								</cfif>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:center;">
								<cfif art.status eq "published">
									<button type="button" class="badge badge-success" style="cursor:pointer; border:none; padding:0.25rem 0.6rem; font-size:0.72rem;" onclick="toggleArticleStatus(#art.id#, 'draft')" title="Click to unpublish (switch to draft)">
										Published
									</button>
								<cfelseif art.status eq "draft">
									<button type="button" class="badge badge-warning" style="cursor:pointer; border:none; padding:0.25rem 0.6rem; font-size:0.72rem;" onclick="toggleArticleStatus(#art.id#, 'published')" title="Click to publish live">
										Draft
									</button>
								<cfelse>
									<span class="badge badge-neutral" style="font-size:0.72rem; padding:0.25rem 0.6rem;">#art.status#</span>
								</cfif>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; font-size:0.8rem; color:var(--admin-text-muted);">
								<cfif IsDate(art.published_at)>
									#DateFormat(art.published_at, "mmm d, yyyy")#<br>
									<span style="font-size:0.72rem;">#TimeFormat(art.published_at, "h:mm tt")#</span>
								<cfelse>
									<span style="font-style:italic;">Not published</span>
								</cfif>
							</td>
							<td style="padding:0.75rem 1rem; vertical-align:middle; text-align:right;">
								<div style="display:inline-flex; gap:0.35rem; align-items:center;">
									<a href="#urlFor(controller='articles', action='edit', params='id=#art.id#')#" class="btn btn-outline-secondary btn-sm" title="Edit Article" style="padding:0.3rem 0.5rem;">
										#svgIcon(name="edit", size=13)#
									</a>
									<button type="button" class="btn btn-outline-danger btn-sm" onclick="confirmDeleteArticle(#art.id#, '#JSStringFormat(art.title)#')" title="Delete Article" style="padding:0.3rem 0.5rem;">
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
</cfoutput>

<script>
async function toggleArticleStatus(id, newStatus) {
	const ok = await window.adminConfirm({
		title: 'Update Article Status?',
		message: 'Change article publication status to "' + newStatus + '"?',
		type: 'info',
		acceptText: 'Update Status'
	});
	if (!ok) return;
	fetch('/articles/toggle-status', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ id: id, status: newStatus })
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			window.location.reload();
		} else {
			window.adminAlert({ title: 'Error', message: res.message || 'Error updating status', type: 'danger' });
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error updating article status.', type: 'danger' });
	});
}

async function confirmDeleteArticle(id, title) {
	const ok = await window.adminConfirm({
		title: 'Delete Article?',
		message: 'Are you sure you want to delete article "' + title + '"? This will remove it from publication.',
		type: 'danger',
		acceptText: 'Delete Article'
	});
	if (!ok) return;
	fetch('/articles/delete', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ id: id })
	})
	.then(r => r.json())
	.then(res => {
		if (res.success) {
			const row = document.getElementById('article-row-' + id);
			if (row) row.remove();
			if (window.showToast) window.showToast('Article deleted successfully.', 'success');
		} else {
			window.adminAlert({ title: 'Error', message: res.message || 'Error deleting article', type: 'danger' });
		}
	})
	.catch(err => {
		console.error(err);
		window.adminAlert({ title: 'Network Error', message: 'Network error deleting article.', type: 'danger' });
	});
}
</script>
