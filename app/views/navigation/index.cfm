<cfprocessingdirective pageencoding="utf-8">
<cfset pageTitle = "Navigation Manager">
<cfparam name="workspacePages" default="#[]#">
<cfparam name="workspaceHomePath" default="/">
<cfscript>
	navIconNames = "folder,file-text,book,clipboard-list,calendar,building,briefcase,users,user,globe,map-pin,mail,phone,search,link,download,upload,shield,lock,info,help-circle,star,megaphone,bell,clock,hard-drive,grid,layers,settings,trending-up,tag,image,monitor,dashboard,chevron-left,chevron-right,chevron-up,chevron-down,code,arrow-left,arrow-right";
	navIconSvgs = {};
	for (navIconName in ListToArray(navIconNames)) {
		navIconSvgs[navIconName] = svgIcon(name=navIconName, size=16);
	}
	navIconSvgJson = Replace(SerializeJSON(navIconSvgs), "</", "<\/", "all");
	function navIconLabel(required string name) {
		return REReplace(
			REReplace(arguments.name, "(^|-)([a-z])", "\1 \U\2\E", "all"),
			"^\s+|\s+$", "", "all"
		);
	}
</cfscript>
<cfoutput>
<div class="page-header">
	<div>
		<h1 class="page-title" style="margin-bottom:0;">Navigation Manager</h1>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Administration</li>
				<li class="breadcrumb-item active" aria-current="page">Navigation Menus</li>
			</ol>
		</nav>
	</div>
</div>

<style>
	.nav-manager-toolbar { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1rem; }
	.nav-workspace { display:flex; flex-direction:column; gap:1.25rem; margin-top:0.5rem; }
	.nav-manager-grid { display:grid; grid-template-columns:minmax(250px, 0.85fr) minmax(320px, 1.2fr) minmax(300px, 0.95fr); gap:1.25rem; width:100%; align-items:start; }
	.nav-panel { min-width:0; background:var(--admin-surface); border:1px solid var(--admin-border); border-radius:var(--radius-lg); box-shadow:var(--shadow-sm); display:flex; flex-direction:column; position:sticky; top:calc(var(--header-height) + 1rem); max-height:calc(100vh - var(--header-height) - 2rem); align-self:start; }
	.nav-panel-header { padding:1rem 1.25rem; border-bottom:1px solid var(--admin-border); flex-shrink:0; }
	.nav-panel-title { display:flex; align-items:center; gap:0.5rem; margin:0; color:var(--admin-text-main); font-size:0.95rem; font-weight:700; }
	.nav-panel-body { padding:1rem 1.25rem; overflow-y:auto; min-height:160px; }
	.nav-menu-list { list-style:none; margin:0; padding:0; }
	.nav-menu-node { border:1px solid var(--admin-border); border-radius:var(--radius-md); margin-bottom:0.5rem; background:var(--admin-surface); }
	.nav-menu-node.is-child { margin-left:1.5rem; }
	.nav-menu-node.is-inactive { opacity:0.7; }
	.nav-menu-node.is-dragging { opacity:0.45; }
	.nav-menu-node.is-drop-target { border-color:var(--admin-primary); box-shadow:0 0 0 2px var(--admin-primary-focus); }
	.nav-menu-row { display:flex; align-items:center; gap:0.65rem; padding:0.7rem 0.8rem; }
	.nav-menu-grip { color:var(--admin-text-subtle); cursor:grab; user-select:none; font-size:1.15rem; line-height:1; }
	.nav-menu-details { flex:1; min-width:0; }
	.nav-menu-title { font-weight:600; color:var(--admin-text-main); overflow-wrap:anywhere; }
	.nav-menu-url { color:var(--admin-text-muted); font-size:0.75rem; overflow-wrap:anywhere; }
	.nav-menu-actions { display:flex; gap:0.3rem; flex-shrink:0; }
	.nav-preview-stage { min-height:360px; padding:1rem; display:flex; align-items:flex-start; justify-content:center; border:1px solid var(--admin-border-subtle); border-radius:var(--radius-md); background:var(--admin-bg); }
	.nav-preview-shell { width:100%; max-width:300px; min-height:300px; padding:0.75rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:var(--admin-surface); box-shadow:var(--shadow-sm); }
	.nav-preview-title { padding:0.4rem 0.65rem 0.7rem; color:var(--admin-text-subtle); font-size:0.7rem; font-weight:700; letter-spacing:0.06em; text-transform:uppercase; }
	.nav-preview-list { list-style:none; margin:0; padding:0; }
	.nav-preview-item { display:block; padding:0.6rem 0.7rem; border-radius:var(--radius-sm); color:var(--admin-text-main); font-size:0.85rem; font-weight:600; overflow-wrap:anywhere; }
	.nav-preview-children { list-style:none; margin:0.15rem 0 0.35rem 0.65rem; padding:0 0 0 0.65rem; border-left:1px solid var(--admin-border); }
	.nav-preview-child { display:block; padding:0.45rem 0.6rem; border-radius:var(--radius-sm); color:var(--admin-text-muted); font-size:0.8rem; overflow-wrap:anywhere; }
	.nav-preview-link { display:block; color:var(--admin-text-main); text-decoration:none; }
	.nav-preview-link:hover { color:var(--admin-primary); background:var(--admin-primary-light); }
	.nav-preview-link:focus-visible { outline:2px solid var(--admin-primary); outline-offset:2px; }
	.nav-preview-link-child { color:var(--admin-text-muted); }
	.nav-new-window-option { font-size:0.78rem; }
	.nav-icon { display:inline-flex; align-items:center; justify-content:center; width:1.25rem; height:1.25rem; margin-right:0.5rem; vertical-align:middle; flex-shrink:0; }
	.nav-icon:empty { display:none; }
	##navigationIconPreview { margin-right:0; width:2rem; height:2rem; border:1px solid var(--admin-border); border-radius:var(--radius-sm); background:var(--admin-surface); }
	##navigationIconPreview:empty { display:inline-flex; }
	.nav-menu-title .nav-icon, .nav-preview-link .nav-icon { display:inline-flex; }
	.nav-editor-status:not(:empty) { margin-bottom:0.9rem; padding:0.65rem 0.75rem; border:1px solid var(--admin-border-subtle); border-radius:var(--radius-sm); background:var(--admin-bg); }
	.nav-editor-form { display:flex; flex-direction:column; gap:1rem; }
	.nav-editor-section { padding:0.9rem; border:1px solid var(--admin-border-subtle); border-radius:var(--radius-md); background:var(--admin-bg); }
	.nav-editor-section .pg-field { margin-top:10px; }
	.nav-editor-section-heading { margin:0 0 0.8rem; color:var(--admin-text-main); font-size:0.8rem; font-weight:700; }
	.nav-editor-section-help { margin:-0.55rem 0 0.8rem; color:var(--admin-text-muted); font-size:0.74rem; line-height:1.45; }
	.nav-editor-section .pg-field:last-child { margin-bottom:0; }
	.nav-editor-input { width:100%; }
	.nav-editor-description { margin-top:0.3rem; color:var(--admin-text-muted); font-size:0.73rem; line-height:1.4; }
	.nav-editor-options { display:flex; flex-direction:column; gap:0.7rem; margin-top:10px; }
	.nav-editor-option { display:flex; align-items:flex-start; gap:0.55rem; cursor:pointer; color:var(--admin-text-main); font-size:0.78rem; line-height:1.45; }
	.nav-editor-option input { flex:0 0 auto; margin-top:0.1rem; accent-color:var(--admin-primary); }
	.nav-empty { padding:1.5rem; text-align:center; color:var(--admin-text-muted); background:var(--admin-bg); border-radius:var(--radius-md); }
	.nav-form-actions { display:flex; gap:0.5rem; justify-content:flex-end; padding-top:0.9rem; border-top:1px solid var(--admin-border-subtle); }
	@media (max-width:1400px) {
		.nav-manager-grid { grid-template-columns:minmax(230px, 0.8fr) minmax(280px, 1.1fr) minmax(280px, 0.95fr); gap:1rem; }
	}
	@media (max-width:1120px) {
		.nav-manager-grid { grid-template-columns:1fr; gap:1rem; }
		.nav-panel { position:static; max-height:none; }
		.nav-panel-body { overflow-y:visible; }
	}
	@media (max-width:520px) {
		.nav-menu-row { flex-wrap:wrap; }
		.nav-menu-actions { margin-left:auto; }
		.nav-menu-node.is-child { margin-left:0.75rem; }
	}
</style>

<div class="nav-workspace">
	<div class="admin-card">
		<div class="card-body nav-manager-toolbar">
			<div>
				<div class="form-label" style="margin-bottom:0.25rem;">Side Menu</div>
				<div class="pg-help">Manage this site's side navigation. The main menu is managed separately.</div>
				<div id="navMenuSummary" class="pg-help" aria-live="polite" style="margin-top:0.35rem;"></div>
			</div>
			<button type="button" class="btn btn-primary btn-sm" id="navAddItem">#svgIcon(name="plus", size=14)# <span>Add Menu Item</span></button>
		</div>
	</div>

<div class="nav-manager-grid">
	<section class="nav-panel" aria-labelledby="navTreeHeading">
		<div class="nav-panel-header">
			<div>
				<h2 class="nav-panel-title" id="navTreeHeading">#svgIcon(name="layers", size=16)# <span>Menu Structure</span></h2>
				<div class="pg-help">Drag an item onto another to nest it. Use the arrows to reorder items.</div>
			</div>
		</div>
		<div class="nav-panel-body">
			<div id="navTreeStatus" class="pg-help" role="status" aria-live="polite" style="margin-bottom:0.75rem;"></div>
			<ul id="navMenuTree" class="nav-menu-list" aria-label="Menu item structure"></ul>
		</div>
	</section>

	<section class="nav-panel" aria-labelledby="navPreviewHeading">
		<div class="nav-panel-header">
			<h2 class="nav-panel-title" id="navPreviewHeading">#svgIcon(name="menu", size=16)# <span>Side Menu Preview</span></h2>
		</div>
		<div class="nav-panel-body nav-preview-stage">
			<div id="navMenuPreview" class="nav-preview-shell" aria-label="Side menu preview" aria-live="polite"></div>
		</div>
	</section>

	<section class="nav-panel" aria-labelledby="navEditorHeading">
		<div class="nav-panel-header">
			<h2 class="nav-panel-title" id="navEditorHeading">#svgIcon(name="edit", size=16)# <span id="navEditorTitle">Add Menu Item</span></h2>
		</div>
		<div class="nav-panel-body">
			<div id="navigationSaveStatus" class="pg-help nav-editor-status" role="status" aria-live="polite"></div>
			<form id="navigationItemForm" class="nav-editor-form">
				<section class="nav-editor-section" aria-labelledby="navItemBasicsHeading">
					<h3 class="nav-editor-section-heading" id="navItemBasicsHeading">Menu item</h3>
					<div class="pg-field">
						<label for="navigationName" class="form-label">Label</label>
						<input type="text" id="navigationName" class="form-control nav-editor-input" maxlength="120" placeholder="e.g. Public Records" required>
						<div class="nav-editor-description">Use a short, clear name that visitors will recognize.</div>
					</div>
					<div class="pg-field">
						<label for="navigationIcon" class="form-label">Icon</label>
						<div style="display:flex; align-items:center; gap:0.6rem;">
							<span id="navigationIconPreview" class="nav-icon" aria-hidden="true"></span>
							<select id="navigationIcon" class="form-control nav-editor-input" style="flex:1;">
								<option value="">No icon</option>
								<cfloop list="#navIconNames#" index="navIconName">
									<option value="#navIconName#">#navIconLabel(navIconName)#</option>
								</cfloop>
							</select>
						</div>
						<div class="nav-editor-description">Optional icon shown beside this item in the menu.</div>
					</div>
				</section>

				<section class="nav-editor-section" aria-labelledby="navItemDestinationHeading">
					<h3 class="nav-editor-section-heading" id="navItemDestinationHeading">Destination</h3>
					<div class="pg-field">
						<label for="navigationDestinationType" class="form-label">Link type</label>
						<select id="navigationDestinationType" class="form-control nav-editor-input">
							<option value="page">Site page</option>
							<option value="custom">Custom URL</option>
						</select>
					</div>
					<div class="pg-field" id="navigationPageWrap">
						<label for="navigationPage" class="form-label">Select a page</label>
						<select id="navigationPage" class="form-control nav-editor-input">
							<option value="__workspace_home__" id="navigationWorkspaceHomeOption">Home (#encodeForHTML(workspaceHomePath)#)</option>
							<cfloop array="#workspacePages#" index="wsPage">
								<cfif LCase(wsPage.url) NEQ LCase(workspaceHomePath)>
									<option value="#encodeForHTMLAttribute(wsPage.url)#">#encodeForHTML(wsPage.title)# (#encodeForHTML(wsPage.url)#)</option>
								</cfif>
							</cfloop>
						</select>
						<div class="nav-editor-description">Home points to this workspace on the public county site.</div>
					</div>
					<div class="pg-field" id="navigationUrlWrap" hidden>
						<label for="navigationUrl" class="form-label">Custom URL or Anchor Tag</label>
						<input type="text" id="navigationUrl" class="form-control nav-editor-input" maxlength="1000" placeholder="##anchor, https://, or /path">
						<div class="nav-editor-description">Enter an anchor tag (e.g. <code>##amenities</code> or <code>##rates</code>) for one-page sections, or an external/internal URL.</div>
						<div id="navOnePageAnchorsWrap" style="margin-top:0.65rem;" hidden>
							<div style="font-size:0.75rem; font-weight:700; color:var(--admin-text-subtle); margin-bottom:0.35rem; display:flex; align-items:center; gap:0.35rem;">
								<span>One-Page Studio Section Anchors:</span>
							</div>
							<div id="navOnePageAnchorsList" style="display:flex; flex-wrap:wrap; gap:0.4rem;"></div>
						</div>
					</div>
				</section>

				<section class="nav-editor-section" aria-labelledby="navItemPlacementHeading">
					<h3 class="nav-editor-section-heading" id="navItemPlacementHeading">Placement &amp; behavior</h3>
					<div class="pg-field">
						<label for="navigationParent" class="form-label">Parent Item</label>
						<select id="navigationParent" class="form-control nav-editor-input">
							<option value="">Top level</option>
						</select>
					</div>
					<div class="pg-field">
						<label for="navigationStatus" class="form-label">Status</label>
						<select id="navigationStatus" class="form-control nav-editor-input">
							<option value="Active">Active</option>
							<option value="Inactive">Inactive</option>
						</select>
					</div>
					<div class="nav-editor-options">
						<label class="nav-editor-option">
							<input type="checkbox" id="navigationNewWindow">
							<span>
								<strong>Open link in a new tab</strong>
								<span class="nav-editor-description" style="display:block;">Assistive technology users will be informed that the link opens in a new tab.</span>
							</span>
						</label>
					</div>
				</section>

				<div class="nav-form-actions">
					<button type="submit" class="btn btn-primary btn-sm" id="navSaveItem">Save Item</button>
					<button type="button" class="btn btn-outline btn-sm" id="navCancelEdit" hidden>Cancel</button>
				</div>
			</form>
		</div>
	</section>
</div>
</div>
</cfoutput>

<script>
window.navigationBuilderConfig = <cfoutput>#navigationConfigJson#</cfoutput>;
window.navigationIconSvgs = <cfoutput>#navIconSvgJson#</cfoutput>;
</script>

<script>
(function () {
	"use strict";

	var config = window.navigationBuilderConfig || {};
	var configuredItems = getField(config, "items");
	var sideMenu = Array.isArray(configuredItems) ? configuredItems.map(normalizeItem) : [];
	var editingId = null;
	var draggedId = null;
	var form = document.getElementById("navigationItemForm");
	var nameInput = document.getElementById("navigationName");
	var destinationType = document.getElementById("navigationDestinationType");
	var pageSelect = document.getElementById("navigationPage");
	var customUrl = document.getElementById("navigationUrl");
	var homeOption = document.getElementById("navigationWorkspaceHomeOption");
	var parentSelect = document.getElementById("navigationParent");
	var iconSelect = document.getElementById("navigationIcon");
	var status = document.getElementById("navigationSaveStatus");
	var treeStatus = document.getElementById("navTreeStatus");
	var tree = document.getElementById("navMenuTree");

	function items() {
		return sideMenu;
	}

	function getField(object, name) {
		if (!object || typeof object !== "object") return undefined;
		var key = Object.keys(object).find(function (candidate) {
			return candidate.toLowerCase() === name.toLowerCase();
		});
		return key === undefined ? undefined : object[key];
	}

	function normalizeItem(item) {
		return {
			id: getField(item, "id"),
			title: getField(item, "title") || "",
			url: getField(item, "url") || "",
			destinationType: getField(item, "destinationType") || "page",
			parentId: getField(item, "parentId") || "",
			sortOrder: getField(item, "sortOrder") || 0,
			active: getField(item, "active") === true,
			newWindow: getField(item, "newWindow") === true,
			icon: getField(item, "icon") || ""
		};
	}

	var iconSvgs = window.navigationIconSvgs || {};
	function iconElement(name) {
		var span = document.createElement("span");
		span.className = "nav-icon";
		span.setAttribute("aria-hidden", "true");
		// Markup comes from the server-side svgIcon() allowlist, never from user input.
		if (name && Object.prototype.hasOwnProperty.call(iconSvgs, name)) span.innerHTML = iconSvgs[name];
		return span;
	}

	var workspaceHomeUrl = getField(config, "homeUrl") || "";
	var workspaceHomePath = getField(config, "homePath") || "/";
	var workspaceHomeValue = "__workspace_home__";
	if (homeOption) {
		homeOption.hidden = false;
		homeOption.value = workspaceHomeValue;
		homeOption.textContent = "Home (" + workspaceHomePath + ")";
	}

	// admin.js re-broadcasts the saved workspace during page init; only user-driven switches should reload,
	// otherwise a saved id the server resolves differently (alias/stale) reloads forever.
	var workspaceSwitchReady = false;
	window.addEventListener("load", function () { setTimeout(function () { workspaceSwitchReady = true; }, 300); });
	window.addEventListener("cmsadmin:workspaceChanged", function (event) {
		if (!workspaceSwitchReady) return;
		var workspaceId = event.detail && event.detail.id;
		var renderedWorkspaceId = getField(config, "workspaceId");
		if (!workspaceId || String(workspaceId).toLowerCase() === String(renderedWorkspaceId || "").toLowerCase()) return;

		var currentUrl = new URL(window.location.href);
		currentUrl.searchParams.delete("ws");
		if (currentUrl.toString() === window.location.href) {
			window.location.reload();
		} else {
			window.location.assign(currentUrl.toString());
		}
	});

	function postJson(url, data) {
		if (typeof url !== "string" || !url.trim()) {
			return Promise.reject(new Error("The navigation save endpoint is unavailable. Reload the page and try again."));
		}
		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var headers = {
			"Content-Type": "application/json",
			"X-Requested-With": "XMLHttpRequest"
		};
		if (csrfMeta) headers["X-CSRF-Token"] = csrfMeta.getAttribute("content");
		return fetch(url, {
			method: "POST",
			credentials: "same-origin",
			headers: headers,
			body: JSON.stringify(data)
		}).then(function (response) {
			return response.text().then(function (body) {
				var result;
				try {
					result = JSON.parse(body);
				} catch (error) {
					throw new Error("The server returned a non-JSON response (HTTP " + response.status + ").");
				}
				if (!result || typeof result !== "object") {
					throw new Error("The server returned an invalid navigation response (HTTP " + response.status + ").");
				}
				if (!response.ok || getField(result, "success") !== true) {
					throw new Error(
						typeof getField(result, "message") === "string" && getField(result, "message").trim()
							? getField(result, "message")
							: "The navigation change failed (HTTP " + response.status + ")."
					);
				}
				return result;
			});
		});
	}

	function sortedItems(source) {
		var nextOrder = {};
		return source.map(function (item) {
			var parentKey = item.parentId ? String(item.parentId) : "root";
			var order = nextOrder[parentKey] || 0;
			nextOrder[parentKey] = order + 1;
			return {
				id: item.id,
				parentId: item.parentId || "",
				sortOrder: order
			};
		});
	}

	function saveOrder(nextItems, successMessage) {
		treeStatus.textContent = "Saving menu order...";
		postJson(getField(config, "reorderUrl"), { items: sortedItems(nextItems) }).then(function () {
			sideMenu = nextItems;
			render();
			treeStatus.textContent = successMessage;
		}).catch(function (error) {
			treeStatus.textContent = error.message;
		});
	}

	function render() {
		tree.textContent = "";
		var current = items();
		var activeCount = current.filter(function (item) { return item.active; }).length;
		document.getElementById("navMenuSummary").textContent =
			current.length + " items \u00B7 " + activeCount + " active \u00B7 " +
			current.filter(function (item) { return item.parentId; }).length + " nested";

		current.filter(function (item) { return !item.parentId; }).forEach(function (item) {
			tree.appendChild(renderNode(item, false));
		});
		if (!tree.children.length) {
			var empty = document.createElement("li");
			empty.className = "nav-empty";
			empty.textContent = "No menu items yet. Add an item to begin building this menu.";
			tree.appendChild(empty);
		}
		renderPreview();
		renderParentChoices();
	}

	function renderNode(item, isChild) {
		var node = document.createElement("li");
		node.className = "nav-menu-node" + (isChild ? " is-child" : "") + (item.active ? "" : " is-inactive");
		node.dataset.id = item.id;
		node.draggable = true;

		var row = document.createElement("div");
		row.className = "nav-menu-row";
		var grip = document.createElement("span");
		grip.className = "nav-menu-grip";
		grip.textContent = "\u22EE\u22EE";
		grip.title = "Drag to reorder or nest";
		grip.setAttribute("aria-hidden", "true");

		var details = document.createElement("div");
		details.className = "nav-menu-details";
		var title = document.createElement("div");
		title.className = "nav-menu-title";
		if (item.icon && iconSvgs[item.icon]) title.appendChild(iconElement(item.icon));
		title.appendChild(document.createTextNode(item.title));
		var url = document.createElement("div");
		url.className = "nav-menu-url";
		url.textContent = item.url + (item.active ? "" : " \u00B7 Inactive") + (item.newWindow ? " \u00B7 Opens in new tab" : "");
		details.appendChild(title);
		details.appendChild(url);

		var actions = document.createElement("div");
		actions.className = "nav-menu-actions";
		addAction(actions, "\u2191", "Move up", function () { moveItem(item.id, -1); });
		addAction(actions, "\u2193", "Move down", function () { moveItem(item.id, 1); });
		addAction(actions, "Edit", "Edit " + item.title, function () { editItem(item.id); });
		addAction(actions, "\u00D7", "Remove " + item.title, function () { removeItem(item.id); });

		row.appendChild(grip);
		row.appendChild(details);
		row.appendChild(actions);
		node.appendChild(row);

		items().filter(function (child) { return String(child.parentId) === String(item.id); }).forEach(function (child) {
			node.appendChild(renderNode(child, true));
		});
		return node;
	}

	function addAction(container, text, label, handler) {
		var button = document.createElement("button");
		button.type = "button";
		button.className = "btn btn-outline btn-sm";
		button.textContent = text;
		button.title = label;
		button.setAttribute("aria-label", label);
		button.addEventListener("click", handler);
		container.appendChild(button);
	}

	function renderParentChoices() {
		var oldValue = parentSelect.value;
		parentSelect.textContent = "";
		var top = document.createElement("option");
		top.value = "";
		top.textContent = "Top level";
		parentSelect.appendChild(top);
		items().forEach(function (item) {
			if (String(item.id) === String(editingId) || isDescendant(item.id, editingId)) return;
			var option = document.createElement("option");
			option.value = item.id;
			option.textContent = item.title;
			parentSelect.appendChild(option);
		});
		if (Array.from(parentSelect.options).some(function (option) { return option.value === oldValue; })) {
			parentSelect.value = oldValue;
		}
	}

	function isDescendant(candidateId, itemId) {
		if (!itemId) return false;
		var parent = items().find(function (item) { return String(item.id) === String(candidateId); });
		while (parent && parent.parentId) {
			if (String(parent.parentId) === String(itemId)) return true;
			parent = items().find(function (item) { return String(item.id) === String(parent.parentId); });
		}
		return false;
	}

	function renderPreview() {
		var preview = document.getElementById("navMenuPreview");
		preview.textContent = "";
		var heading = document.createElement("div");
		heading.className = "nav-preview-title";
		heading.textContent = "Side Navigation";
		preview.appendChild(heading);
		var list = document.createElement("ul");
		list.className = "nav-preview-list";
		items().filter(function (item) { return item.active && !item.parentId; }).forEach(function (item) {
			list.appendChild(renderPreviewItem(item, false));
		});
		if (!list.children.length) {
			var empty = document.createElement("li");
			empty.className = "nav-empty";
			empty.textContent = "No active links to preview.";
			list.appendChild(empty);
		}
		preview.appendChild(list);
	}

	function renderPreviewItem(item, isChild) {
		var entry = document.createElement("li");
		var link = document.createElement("a");
		link.className = "nav-preview-link " + (isChild ? "nav-preview-child nav-preview-link-child" : "nav-preview-item");
		link.href = item.url;
		if (item.icon && iconSvgs[item.icon]) link.appendChild(iconElement(item.icon));
		link.appendChild(document.createTextNode(item.title));
		if (item.newWindow) {
			link.target = "_blank";
			link.rel = "noopener noreferrer";
			var announcement = document.createElement("span");
			announcement.className = "sr-only";
			announcement.textContent = " (opens in a new tab)";
			link.appendChild(announcement);
		}
		entry.appendChild(link);
		var children = items().filter(function (child) {
			return String(child.parentId) === String(item.id) && child.active;
		});
		if (children.length) {
			var childList = document.createElement("ul");
			childList.className = "nav-preview-children";
			children.forEach(function (child) {
				childList.appendChild(renderPreviewItem(child, true));
			});
			entry.appendChild(childList);
		}
		return entry;
	}

	function moveItem(id, direction) {
		var current = items();
		var item = current.find(function (entry) { return entry.id === id; });
		if (!item) return;
		var siblings = current.filter(function (entry) { return entry.parentId === item.parentId; });
		var index = siblings.indexOf(item);
		var target = siblings[index + direction];
		if (!target) return;
		var next = current.map(function (entry) { return Object.assign({}, entry); });
		var originalIndex = next.findIndex(function (entry) { return entry.id === id; });
		var targetIndex = next.findIndex(function (entry) { return entry.id === target.id; });
		next[originalIndex] = next[targetIndex];
		next[targetIndex] = current.find(function (entry) { return entry.id === id; });
		saveOrder(next, "Menu item order saved.");
	}

	function resetForm() {
		editingId = null;
		form.reset();
		destinationType.value = "page";
		updateDestination();
		updateIconPreview();
		document.getElementById("navEditorTitle").textContent = "Add Menu Item";
		document.getElementById("navSaveItem").textContent = "Save Item";
		document.getElementById("navCancelEdit").hidden = true;
		renderParentChoices();
	}

	function updateIconPreview() {
		var preview = document.getElementById("navigationIconPreview");
		preview.textContent = "";
		var selected = iconSelect.value;
		if (selected && Object.prototype.hasOwnProperty.call(iconSvgs, selected)) preview.innerHTML = iconSvgs[selected];
	}

	function updateDestination() {
		var isCustom = destinationType.value === "custom";
		document.getElementById("navigationPageWrap").hidden = isCustom;
		document.getElementById("navigationUrlWrap").hidden = !isCustom;
		pageSelect.required = !isCustom;
		customUrl.required = isCustom;

		var anchorsWrap = document.getElementById("navOnePageAnchorsWrap");
		var anchorsList = document.getElementById("navOnePageAnchorsList");
		if (anchorsWrap && anchorsList) {
			var anchors = config.onePageAnchors || [];
			if (isCustom && Array.isArray(anchors) && anchors.length > 0) {
				anchorsWrap.hidden = false;
				anchorsList.innerHTML = "";
				anchors.forEach(function (anc) {
					var pill = document.createElement("button");
					pill.type = "button";
					pill.className = "btn btn-outline btn-xs";
					pill.style.cssText = "font-size:0.72rem; padding:0.2rem 0.5rem; border-radius:12px; font-weight:600;";
					pill.textContent = anc.anchor + " (" + anc.label + ")";
					pill.title = "Click to set destination to " + anc.anchor;
					pill.addEventListener("click", function (e) {
						e.preventDefault();
						if (!nameInput.value.trim()) {
							nameInput.value = anc.label;
						}
						customUrl.value = anc.anchor;
						customUrl.focus();
					});
					anchorsList.appendChild(pill);
				});
			} else {
				anchorsWrap.hidden = true;
			}
		}
	}

	function editItem(id) {
		var item = items().find(function (entry) { return entry.id === id; });
		if (!item) return;
		editingId = id;
		nameInput.value = item.title;
		iconSelect.value = Array.from(iconSelect.options).some(function (o) { return o.value === item.icon; }) ? item.icon : "";
		updateIconPreview();
		renderParentChoices();
		parentSelect.value = item.parentId;
		document.getElementById("navigationStatus").value = item.active ? "Active" : "Inactive";
		document.getElementById("navigationNewWindow").checked = item.newWindow;
		var normalizedItemUrl = (item.url || "").replace(/\/+$/, "") || "/";
		var normalizedHomeUrl = workspaceHomeUrl ? workspaceHomeUrl.replace(/\/+$/, "") : "";
		var normalizedHomePath = (workspaceHomePath || "/").replace(/\/+$/, "") || "/";
		var isWorkspaceHome = (normalizedHomeUrl && normalizedItemUrl.toLowerCase() === normalizedHomeUrl.toLowerCase()) ||
			(normalizedItemUrl.toLowerCase() === normalizedHomePath.toLowerCase());
		var matchingOption = !isWorkspaceHome && Array.from(pageSelect.options).find(function (option) {
			return option.value.toLowerCase() === item.url.toLowerCase();
		});
		if (!isWorkspaceHome && !matchingOption && item.destinationType === "page" && item.url && item.url.indexOf("/") === 0) {
			var dynamicOpt = document.createElement("option");
			dynamicOpt.value = item.url;
			dynamicOpt.textContent = item.title + " (" + item.url + ")";
			pageSelect.appendChild(dynamicOpt);
			matchingOption = dynamicOpt;
		}
		destinationType.value = (isWorkspaceHome || matchingOption) ? "page" : "custom";
		updateDestination();
		if (isWorkspaceHome) {
			pageSelect.value = workspaceHomeValue;
			customUrl.value = item.url;
		} else if (matchingOption) {
			pageSelect.value = matchingOption.value;
			customUrl.value = item.url;
		} else {
			customUrl.value = item.url;
		}
		document.getElementById("navEditorTitle").textContent = "Edit Menu Item";
		document.getElementById("navSaveItem").textContent = "Save Changes";
		document.getElementById("navCancelEdit").hidden = false;
		status.textContent = 'Editing "' + item.title + '".';
		nameInput.focus();
	}

	async function removeItem(id) {
		var current = items();
		var removed = new Set([id]);
		var changed = true;
		while (changed) {
			changed = false;
			current.forEach(function (item) {
				if (removed.has(item.parentId) && !removed.has(item.id)) {
					removed.add(item.id);
					changed = true;
				}
			});
		}
		if (!await window.adminConfirm("Remove this menu item and all nested items?", {
			title: "Remove navigation item?",
			acceptText: "Remove",
			destructive: true
		})) return;
		status.textContent = "Removing menu item...";
		postJson(getField(config, "deleteUrl"), { id: id }).then(function (result) {
			sideMenu = current.filter(function (item) { return !removed.has(item.id); });
			render();
			if (editingId && removed.has(editingId)) resetForm();
			status.textContent = getField(result, "message") || "Menu item removed.";
		}).catch(function (error) {
			status.textContent = error.message;
		});
	}

	document.getElementById("navAddItem").addEventListener("click", function () {
		resetForm();
		nameInput.focus();
	});
	document.getElementById("navCancelEdit").addEventListener("click", resetForm);
	destinationType.addEventListener("change", updateDestination);
	iconSelect.addEventListener("change", updateIconPreview);

	form.addEventListener("submit", function (event) {
		event.preventDefault();
		var title = nameInput.value.trim();
		var isWorkspaceHome = destinationType.value === "page" && pageSelect.value === workspaceHomeValue;
		var url = isWorkspaceHome ? (workspaceHomePath || workspaceHomeUrl || "/") : (destinationType.value === "page" ? pageSelect.value : customUrl.value.trim());
		if (!title || !url) return;
		var parentId = parentSelect.value;
		var existing = editingId ? items().find(function (entry) { return String(entry.id) === String(editingId); }) : null;
		var siblingCount = items().filter(function (entry) {
			return String(entry.parentId || "") === String(parentId || "") && (!existing || String(entry.id) !== String(existing.id));
		}).length;
		var payload = {
			id: existing ? existing.id : 0,
			title: title,
			url: url,
			destinationType: isWorkspaceHome ? "page" : destinationType.value,
			parentId: parentId,
			sortOrder: existing && String(existing.parentId || "") === String(parentId || "")
				? existing.sortOrder
				: siblingCount,
			active: document.getElementById("navigationStatus").value === "Active",
			newWindow: document.getElementById("navigationNewWindow").checked,
			icon: iconSelect.value
		};

		status.textContent = "Saving menu item...";
		postJson(getField(config, "saveUrl"), payload).then(function (result) {
			var saved = normalizeItem(getField(result, "item"));
			if (!saved || saved.id === undefined || saved.id === null) {
				throw new Error("The server accepted the save but did not return the saved menu item. Reload the page to check whether it was stored.");
			}
			var savedIndex = sideMenu.findIndex(function (entry) { return String(entry.id) === String(saved.id); });
			if (savedIndex >= 0) sideMenu[savedIndex] = saved;
			else sideMenu.push(saved);
			render();
			status.textContent = getField(result, "message") || "Navigation item saved.";
			treeStatus.textContent = "Menu structure saved.";
			resetForm();
		}).catch(function (error) {
			status.textContent = error.message || "The navigation item could not be saved.";
		});
	});

	document.getElementById("navMenuTree").addEventListener("dragstart", function (event) {
		var node = event.target.closest(".nav-menu-node");
		if (!node) return;
		draggedId = node.dataset.id;
		node.classList.add("is-dragging");
		event.dataTransfer.effectAllowed = "move";
		event.dataTransfer.setData("text/plain", draggedId);
	});
	document.getElementById("navMenuTree").addEventListener("dragend", function () {
		document.querySelectorAll(".nav-menu-node").forEach(function (node) {
			node.classList.remove("is-dragging", "is-drop-target");
		});
	});
	document.getElementById("navMenuTree").addEventListener("dragover", function (event) {
		var target = event.target.closest(".nav-menu-node");
		if (!target || target.dataset.id === draggedId) return;
		event.preventDefault();
		target.classList.add("is-drop-target");
		event.dataTransfer.dropEffect = "move";
	});
	document.getElementById("navMenuTree").addEventListener("dragleave", function (event) {
		var target = event.target.closest(".nav-menu-node");
		if (target && !target.contains(event.relatedTarget)) target.classList.remove("is-drop-target");
	});
	document.getElementById("navMenuTree").addEventListener("drop", function (event) {
		var target = event.target.closest(".nav-menu-node");
		if (!target || !draggedId || target.dataset.id === draggedId) return;
		event.preventDefault();
		var draggedItem = items().find(function (item) { return String(item.id) === String(draggedId); });
		var targetItem = items().find(function (item) { return String(item.id) === String(target.dataset.id); });
		if (!draggedItem || !targetItem || isDescendant(targetItem.id, draggedItem.id)) return;
		var nextItems = items().map(function (item) {
			var copy = Object.assign({}, item);
			if (String(copy.id) === String(draggedId)) copy.parentId = targetItem.id;
			return copy;
		});
		saveOrder(nextItems, 'Menu item nested under "' + targetItem.title + '".');
	});

	updateDestination();
	render();
})();
</script>
