<cfparam name="article" default="#{}#">
<cfparam name="isNew" default="true">
<cfparam name="categories" default="#[]#">
<cfparam name="availableTags" default="#[]#">
<cfparam name="accessibleWorkspaces" default="#[]#">
<cfparam name="activeWorkspaceId" default="global">

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

				<div style="margin-bottom:1rem;">
					<label for="articleStatus" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.3rem; color:var(--admin-text-muted);">
						Publication Status
					</label>
					<select id="articleStatus" name="status" class="form-control">
						<option value="published" <cfif (article.status ?: "") eq "published">selected</cfif>>Published Live</option>
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

				<input type="hidden" id="siteid" name="siteid" value="#EncodeForHTMLAttribute(Len(Trim(article.siteid ?: '')) ? article.siteid : (Len(Trim(activeWorkspaceId ?: '')) ? activeWorkspaceId : 'global'))#">

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
				<h3 style="margin:0 0 0.75rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); border-bottom:1px solid var(--admin-border-subtle); padding-bottom:0.5rem;">
					Featured Cover Image
				</h3>

				<div style="margin-bottom:0.75rem;">
					<div id="featuredImgPreviewWrap" style="border:1.5px dashed var(--admin-border); border-radius:var(--radius-md); padding:0.5rem; text-align:center; min-height:120px; display:flex; flex-direction:column; align-items:center; justify-content:center; background:var(--admin-bg);">
						<img id="featuredImgPreview" src="#EncodeForHTML(article.featured_image ?: '')#" alt="" style="max-width:100%; max-height:140px; object-fit:cover; border-radius:var(--radius-sm); #(Len(Trim(article.featured_image ?: '')) ? '' : 'display:none;')#" />
						<div id="featuredImgPlaceholder" style="color:var(--admin-text-muted); font-size:0.8rem; #(Len(Trim(article.featured_image ?: '')) ? 'display:none;' : '')#">
							#svgIcon(name="image", size=28)#
							<div style="margin-top:0.35rem;">No cover image set</div>
						</div>
					</div>
				</div>

				<div style="margin-bottom:0.75rem;">
					<label for="featuredImage" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Image URL
					</label>
					<div style="display:flex; gap:0.4rem;">
						<input type="text" id="featuredImage" name="featured_image" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(article.featured_image ?: "")#" placeholder="/assets/media/news/..." oninput="updateImagePreview(this.value)">
						<button type="button" class="btn btn-outline-secondary btn-sm" onclick="openMediaPickerForArticle()" title="Select from Media Library">
							Browse
						</button>
					</div>
				</div>

				<div>
					<label for="featuredImageAlt" style="display:block; font-weight:600; font-size:0.8rem; margin-bottom:0.25rem; color:var(--admin-text-muted);">
						Image Alt Text (ADA / WCAG 2.1 AA)
					</label>
					<input type="text" id="featuredImageAlt" name="featured_image_alt" class="form-control" style="font-size:0.82rem;" value="#EncodeForHTML(article.featured_image_alt ?: "")#" placeholder="Describe the image for screen readers">
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

function updateImagePreview(url) {
	const img = document.getElementById('featuredImgPreview');
	const ph = document.getElementById('featuredImgPlaceholder');
	if (url && url.trim().length > 0) {
		img.src = url.trim();
		img.style.display = 'block';
		if (ph) ph.style.display = 'none';
	} else {
		img.style.display = 'none';
		if (ph) ph.style.display = 'block';
	}
}

function openMediaPickerForArticle() {
	// If Media Picker modal or iframe is available
	const url = prompt('Enter image URL or asset path (e.g. /images/news/photo.jpg):', document.getElementById('featuredImage').value);
	if (url !== null && url.trim().length > 0) {
		document.getElementById('featuredImage').value = url.trim();
		updateImagePreview(url.trim());
	}
}

function saveArticleForm() {
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

	const btnTop = document.getElementById('btnSaveTop');
	const btnSide = document.getElementById('btnSaveSidebar');
	if (btnTop) btnTop.disabled = true;
	if (btnSide) btnSide.disabled = true;

	const payload = {
		id: parseInt(document.getElementById('articleId').value || '0', 10),
		title: title,
		slug: document.getElementById('articleSlug').value.trim(),
		summary: document.getElementById('articleSummary').value.trim(),
		content_html: contentHtml,
		category_id: parseInt(document.getElementById('categoryId').value || '0', 10),
		tags: document.getElementById('articleTags').value.trim(),
		featured_image: document.getElementById('featuredImage').value.trim(),
		featured_image_alt: document.getElementById('featuredImageAlt').value.trim(),
		author_name: document.getElementById('authorName').value.trim(),
		author_title: document.getElementById('authorTitle').value.trim(),
		status: document.getElementById('articleStatus').value,
		siteid: document.getElementById('siteid').value,
		published_at: document.getElementById('publishedAt').value,
		meta_title: document.getElementById('metaTitle').value.trim(),
		meta_description: document.getElementById('metaDescription').value.trim()
	};

	fetch('/articles/save', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
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
</script>
