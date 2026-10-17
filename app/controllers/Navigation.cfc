component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="saveItem,deleteItem,reorder");
		filters(through="requireAdmin");
	}

	private void function requireAdmin() {
		local.role = getCurrentActiveRole();
		if (local.role != "admin") {
			if (isAjaxRequest()) {
				renderJson({ success: false, message: "Access Denied: Navigation management is strictly restricted to System Administrators." }, 403);
			} else {
				flashInsert(error="Access Denied: Navigation menu management is strictly restricted to System Administrators.");
				redirectTo(controller="main", action="index");
			}
		}
	}

	function index() {
		variables.pageTitle = "Navigation Manager";
		local.siteid = activeNavigationSiteId();
		local.workspaceName = local.siteid;
		local.workspaceHomeUrl = "";
		local.workspaces = getMasterWorkspaces();
		local.primarySiteHost = "";
		local.currentWorkspaceType = "";
		local.currentWorkspaceRedirectUrl = "";
		local.homeSlug = ReReplaceNoCase(local.siteid, "^site-", "");
		for (local.workspace in local.workspaces) {
			if (CompareNoCase(local.workspace.id, "site-main") == 0) {
				local.primarySiteHost = StructKeyExists(local.workspace, "alias") && Len(Trim(local.workspace.alias))
					? Trim(local.workspace.alias)
					: Trim(local.workspace.name);
			}
			if (CompareNoCase(local.workspace.id, local.siteid) == 0) {
				local.workspaceName = local.workspace.name;
				local.currentWorkspaceType = StructKeyExists(local.workspace, "type") ? local.workspace.type : "";
				local.currentWorkspaceRedirectUrl = StructKeyExists(local.workspace, "redirect_url")
					&& IsSimpleValue(local.workspace.redirect_url)
					? Trim(local.workspace.redirect_url)
					: "";
				if (StructKeyExists(local.workspace, "virtual_directory")
					&& IsSimpleValue(local.workspace.virtual_directory)
					&& Len(Trim(local.workspace.virtual_directory))) {
					local.homeSlug = Trim(local.workspace.virtual_directory);
				} else if (StructKeyExists(local.workspace, "code")
					&& IsSimpleValue(local.workspace.code)
					&& Len(Trim(local.workspace.code))) {
					local.homeSlug = Trim(local.workspace.code);
				}
			}
		}
		local.cleanHomeSlug = ReReplace(local.homeSlug, "^/+|/+$", "", "all");
		local.wsBasePath = (local.siteid == "site-main" || local.siteid == "global" || !Len(local.cleanHomeSlug))
			? "/"
			: "/" & LCase(local.cleanHomeSlug);

		if (!REFindNoCase("^https?://", local.currentWorkspaceRedirectUrl) && local.siteid != "global" && Len(local.primarySiteHost)) {
			local.workspaceHomeUrl = "https://" & local.primarySiteHost & (local.siteid == "site-main" ? "" : local.wsBasePath);
		} else if (REFindNoCase("^https?://", local.currentWorkspaceRedirectUrl)) {
			if (local.siteid == "site-main" && Len(local.primarySiteHost)) {
				local.workspaceHomeUrl = "https://" & local.primarySiteHost;
			} else if (local.currentWorkspaceType == "site") {
				local.workspaceHomeUrl = local.currentWorkspaceRedirectUrl;
			} else if (Len(local.primarySiteHost)) {
				local.workspaceHomeUrl = ReReplaceNoCase(
					local.currentWorkspaceRedirectUrl,
					"^https?://[^/]*",
					"https://" & local.primarySiteHost,
					"one"
				);
			}
		}
		if (!isWorkspaceAccessible(local.siteid, getCurrentActiveRole())) {
			flashInsert(error="You do not have access to manage navigation for this workspace.");
			redirectTo(controller="main", action="index");
			return;
		}

		variables.workspaceHomePath = local.wsBasePath;
		variables.workspacePages = loadWorkspacePages(local.siteid, local.wsBasePath);

		ensureIconColumn();
		local.menuId = findNavigationMenuId(local.siteid);
		variables.navigationItems = [];
		if (local.menuId > 0) {
			local.rows = navigationQuery("
				SELECT id, parent_item_id, label, destination_type, destination,
				       sort_order, is_active, open_in_new_tab, icon
				FROM navigation_menu_items
				WHERE navigation_menu_id = :menuId AND deletedat IS NULL
				ORDER BY CASE WHEN parent_item_id IS NULL THEN 0 ELSE 1 END,
				         parent_item_id, sort_order, id
			", { menuId: intParam(local.menuId) });

			for (local.row in local.rows) {
				local.destUrl = Trim(local.row.destination ?: "");
				local.healedUrl = local.destUrl;
				// Auto-heal menu items whose destination was overwritten with admin placeholder /index.cfm/...
				if (REFindNoCase("^/index\.cfm(/|$)", local.destUrl)) {
					local.healedUrl = resolveMenuItemPageUrl(local.row.label ?: "", local.wsBasePath, variables.workspacePages);
				} else if (local.row.destination_type != "url" || (Len(local.cleanHomeSlug) && REFindNoCase("^/?" & local.cleanHomeSlug & "/(?!page/)[^/]+/?$", local.destUrl))) {
					local.healedUrl = normalizeWorkspacePageDestination(local.destUrl, local.wsBasePath);
				}
				if (Len(local.healedUrl) && local.healedUrl != local.destUrl) {
					local.destUrl = local.healedUrl;
					try {
						navigationQuery("
							UPDATE navigation_menu_items
							SET destination = :dest, destination_type = 'page', updatedat = SYSUTCDATETIME()
							WHERE id = :id
						", {
							dest: stringParam(local.destUrl, 1000),
							id: intParam(Val(local.row.id))
						});
					} catch (any errHeal) {}
				}
				ArrayAppend(variables.navigationItems, {
					id: local.row.id,
					title: local.row.label,
					url: local.destUrl,
					destinationType: local.row.destination_type == "url" ? "custom" : "page",
					parentId: IsNumeric(local.row.parent_item_id) ? Val(local.row.parent_item_id) : "",
					sortOrder: local.row.sort_order,
					active: local.row.is_active ? true : false,
					newWindow: local.row.open_in_new_tab ? true : false,
					icon: IsSimpleValue(local.row.icon) ? local.row.icon : ""
				});
			}
		}

		variables.navigationConfigJson = safeJsonForScript({
			"items": variables.navigationItems,
			"pages": variables.workspacePages,
			"workspaceId": local.siteid,
			"workspaceName": local.workspaceName,
			"homeUrl": local.workspaceHomeUrl,
			"homePath": local.wsBasePath,
			"saveUrl": urlFor(controller="navigation", action="saveItem"),
			"deleteUrl": urlFor(controller="navigation", action="deleteItem"),
			"reorderUrl": urlFor(controller="navigation", action="reorder")
		});
	}

	function saveItem() {
		local.body = readJsonBody();
		if (!IsStruct(local.body)) {
			renderJson({ success: false, message: "Invalid request payload." }, 400);
			return;
		}

		local.siteid = activeNavigationSiteId();
		if (!isWorkspaceAccessible(local.siteid, getCurrentActiveRole())) {
			renderJson({ success: false, message: "You do not have access to manage this workspace's navigation." }, 403);
			return;
		}

		local.title = Left(Trim(local.body.title ?: ""), 150);
		local.destinationType = LCase(Trim(local.body.destinationType ?: ""));
		local.destination = Left(Trim(local.body.url ?: ""), 1000);
		if (!Len(local.title) || !Len(local.destination) || !ListFindNoCase("page,custom", local.destinationType)) {
			renderJson({ success: false, message: "A label, valid link type, and destination are required." }, 422);
			return;
		}
		if (local.destinationType == "page" && !REFindNoCase("^https?://", local.destination)) {
			local.wsBasePath = resolveWorkspaceBasePath(local.siteid);
			local.destination = Left(normalizeWorkspacePageDestination(local.destination, local.wsBasePath), 1000);
		}
		if (
			(local.destinationType == "custom" && !REFindNoCase("^(https?://|/)", local.destination))
			|| (local.destinationType == "page" && !REFindNoCase("^(https?://|/)", local.destination))
			|| Left(local.destination, 2) == "//"
		) {
			renderJson({ success: false, message: "Destinations must use an HTTP(S) URL or a site-relative path." }, 422);
			return;
		}

		local.itemIdRaw = StructKeyExists(local.body, "id") && IsSimpleValue(local.body.id) ? Trim(local.body.id) : "0";
		local.parentIdRaw = StructKeyExists(local.body, "parentId") && IsSimpleValue(local.body.parentId) ? Trim(local.body.parentId) : "";
		local.sortOrderRaw = StructKeyExists(local.body, "sortOrder") && IsSimpleValue(local.body.sortOrder) ? Trim(local.body.sortOrder) : "0";
		if (!REFind("^[0-9]+$", local.itemIdRaw)) {
			renderJson({ success: false, message: "The menu item ID must be a non-negative integer." }, 422);
			return;
		}
		if (Len(local.parentIdRaw) && !REFind("^[0-9]+$", local.parentIdRaw)) {
			renderJson({ success: false, message: "Choose a valid parent item or select Top level." }, 422);
			return;
		}
		if (!REFind("^[0-9]+$", local.sortOrderRaw)) {
			renderJson({ success: false, message: "The menu item order must be a non-negative integer." }, 422);
			return;
		}
		local.itemId = Val(local.body.id ?: 0);
		local.parentId = Val(local.parentIdRaw);
		local.sortOrder = Int(Val(local.sortOrderRaw));
		local.isActive = StructKeyExists(local.body, "active") && IsBoolean(local.body.active) && local.body.active;
		local.newWindow = StructKeyExists(local.body, "newWindow") && IsBoolean(local.body.newWindow) && local.body.newWindow;
		local.icon = StructKeyExists(local.body, "icon") && IsSimpleValue(local.body.icon) ? LCase(Trim(local.body.icon)) : "";
		if (Len(local.icon) && !REFind("^[a-z0-9-]{1,50}$", local.icon)) {
			renderJson({ success: false, message: "Choose a valid icon." }, 422);
			return;
		}

		ensureIconColumn();
		try {
			transaction {
				local.menuId = findNavigationMenuId(local.siteid);
				if (local.menuId == 0) {
					local.insertedMenu = navigationQuery("
						SET NOCOUNT ON;
						DECLARE @InsertedMenu TABLE (id INT);
						INSERT INTO navigation_menus (siteid, menu_key, name)
						OUTPUT INSERTED.id INTO @InsertedMenu(id)
						VALUES (:siteid, :menuKey, :menuName);
						SELECT id FROM @InsertedMenu;
					", {
						siteid: stringParam(local.siteid, 100),
						menuKey: stringParam("side", 100),
						menuName: stringParam("Side Navigation", 150)
					});
					local.menuId = local.insertedMenu.id;
				}

				if (local.parentId > 0) {
					if (local.parentId == local.itemId || !navigationItemExists(local.menuId, local.parentId)) {
						transactionRollback();
						renderJson({ success: false, message: "Choose a valid parent item from this menu." }, 422);
						return;
					}
					if (local.itemId > 0 && navigationParentWouldCycle(local.menuId, local.itemId, local.parentId)) {
						transactionRollback();
						renderJson({ success: false, message: "An item cannot be placed beneath one of its own descendants." }, 422);
						return;
					}
				}

				local.parentParam = local.parentId > 0
					? intParam(local.parentId)
					: { value: "", cfsqltype: "cf_sql_integer", null: true };
				local.itemParams = {
					menuId: intParam(local.menuId),
					parentId: local.parentParam,
					label: stringParam(local.title, 150),
					destinationType: stringParam(local.destinationType == "custom" ? "url" : "page", 20),
					destination: stringParam(local.destination, 1000),
					sortOrder: intParam(local.sortOrder),
					isActive: bitParam(local.isActive),
					newWindow: bitParam(local.newWindow),
					icon: Len(local.icon)
						? stringParam(local.icon, 50)
						: { value: "", cfsqltype: "cf_sql_nvarchar", null: true }
				};

				if (local.itemId > 0) {
					local.itemParams.id = intParam(local.itemId);
					local.updated = navigationQuery("
						SET NOCOUNT ON;
						DECLARE @UpdatedItem TABLE (id INT);
						UPDATE navigation_menu_items
						SET parent_item_id = :parentId,
						    label = :label,
						    destination_type = :destinationType,
						    destination = :destination,
						    sort_order = :sortOrder,
						    is_active = :isActive,
						    open_in_new_tab = :newWindow,
						    icon = :icon,
						    updatedat = SYSUTCDATETIME()
						OUTPUT INSERTED.id INTO @UpdatedItem(id)
						WHERE id = :id AND navigation_menu_id = :menuId AND deletedat IS NULL;
						SELECT id FROM @UpdatedItem;
					", local.itemParams);
					if (!local.updated.recordCount) {
						transactionRollback();
						renderJson({ success: false, message: "This menu item could not be found." }, 404);
						return;
					}
					local.itemId = local.updated.id;
				} else {
					local.insertedItem = navigationQuery("
						SET NOCOUNT ON;
						DECLARE @InsertedItem TABLE (id INT);
						INSERT INTO navigation_menu_items
							(navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon)
						OUTPUT INSERTED.id INTO @InsertedItem(id)
						VALUES
							(:menuId, :parentId, :label, :destinationType, :destination, :sortOrder, :isActive, :newWindow, :icon);
						SELECT id FROM @InsertedItem;
					", local.itemParams);
					local.itemId = local.insertedItem.id;
				}
			}
		} catch (any e) {
			writeLog(type="error", file="navigation", text="Navigation item save failed: #e.message# #e.detail#");
			renderJson({ success: false, message: "Unable to save this navigation item. Please try again." }, 500);
			return;
		}

		renderJson({
			success: true,
			message: "Navigation item saved.",
			item: {
				id: local.itemId,
				title: local.title,
				url: local.destination,
				destinationType: local.destinationType,
				parentId: local.parentId > 0 ? local.parentId : "",
				sortOrder: local.sortOrder,
				active: local.isActive,
				newWindow: local.newWindow,
				icon: local.icon
			}
		});
	}

	function deleteItem() {
		local.body = readJsonBody();
		local.itemId = IsStruct(local.body) ? Val(local.body.id ?: 0) : 0;
		if (local.itemId <= 0) {
			renderJson({ success: false, message: "A valid menu item is required." }, 400);
			return;
		}

		local.siteid = activeNavigationSiteId();
		if (!isWorkspaceAccessible(local.siteid, getCurrentActiveRole())) {
			renderJson({ success: false, message: "You do not have access to manage this workspace's navigation." }, 403);
			return;
		}

		local.menuId = findNavigationMenuId(local.siteid);
		if (local.menuId == 0 || !navigationItemExists(local.menuId, local.itemId)) {
			renderJson({ success: false, message: "This menu item could not be found." }, 404);
			return;
		}

		try {
			navigationQuery("
				WITH descendants AS (
					SELECT id, CAST('/' + CAST(id AS VARCHAR(20)) + '/' AS VARCHAR(MAX)) AS path
					FROM navigation_menu_items
					WHERE id = :itemId AND navigation_menu_id = :menuId AND deletedat IS NULL
					UNION ALL
					SELECT child.id,
					       CAST(parent.path + CAST(child.id AS VARCHAR(20)) + '/' AS VARCHAR(MAX))
					FROM navigation_menu_items child
					INNER JOIN descendants parent ON child.parent_item_id = parent.id
					WHERE child.navigation_menu_id = :menuId
					  AND child.deletedat IS NULL
					  AND CHARINDEX('/' + CAST(child.id AS VARCHAR(20)) + '/', parent.path) = 0
				)
				UPDATE item
				SET is_active = 0, deletedat = SYSUTCDATETIME(), updatedat = SYSUTCDATETIME()
				FROM navigation_menu_items item
				WHERE item.id IN (SELECT id FROM descendants)
				OPTION (MAXRECURSION 32767)
			", { itemId: intParam(local.itemId), menuId: intParam(local.menuId) });
		} catch (any e) {
			writeLog(type="error", file="navigation", text="Navigation item delete failed: #e.message# #e.detail#");
			renderJson({ success: false, message: "Unable to remove this navigation item. Please try again." }, 500);
			return;
		}

		renderJson({ success: true, message: "Menu item and its nested items were removed." });
	}

	function reorder() {
		local.body = readJsonBody();
		if (!IsStruct(local.body) || !StructKeyExists(local.body, "items") || !IsArray(local.body.items)) {
			renderJson({ success: false, message: "Invalid menu order payload." }, 400);
			return;
		}

		local.siteid = activeNavigationSiteId();
		if (!isWorkspaceAccessible(local.siteid, getCurrentActiveRole())) {
			renderJson({ success: false, message: "You do not have access to manage this workspace's navigation." }, 403);
			return;
		}
		local.menuId = findNavigationMenuId(local.siteid);
		if (local.menuId == 0) {
			renderJson({ success: false, message: "This menu could not be found." }, 404);
			return;
		}

		local.menuRows = navigationQuery("
			SELECT id FROM navigation_menu_items
			WHERE navigation_menu_id = :menuId AND deletedat IS NULL
		", { menuId: intParam(local.menuId) });
		local.knownIds = {};
		for (local.row in local.menuRows) local.knownIds[local.row.id] = true;
		if (ArrayLen(local.body.items) != StructCount(local.knownIds)) {
			renderJson({ success: false, message: "The menu changed while you were editing. Reload and try again." }, 409);
			return;
		}

		local.order = [];
		local.parents = {};
		local.seenIds = {};
		for (local.entry in local.body.items) {
			if (!IsStruct(local.entry)) {
				renderJson({ success: false, message: "The menu order contains an invalid item." }, 422);
				return;
			}
			local.idRaw = StructKeyExists(local.entry, "id") && IsSimpleValue(local.entry.id) ? Trim(local.entry.id) : "";
			local.parentIdRaw = StructKeyExists(local.entry, "parentId") && IsSimpleValue(local.entry.parentId)
				? Trim(local.entry.parentId)
				: "";
			local.sortOrderRaw = StructKeyExists(local.entry, "sortOrder") && IsSimpleValue(local.entry.sortOrder)
				? Trim(local.entry.sortOrder)
				: "";
			if (!REFind("^[0-9]+$", local.idRaw)) {
				renderJson({ success: false, message: "The menu order contains an invalid item ID." }, 422);
				return;
			}
			if (Len(local.parentIdRaw) && !REFind("^[0-9]+$", local.parentIdRaw)) {
				renderJson({ success: false, message: "The menu order contains an invalid parent ID." }, 422);
				return;
			}
			if (!REFind("^[0-9]+$", local.sortOrderRaw)) {
				renderJson({ success: false, message: "The menu order contains an invalid sort order." }, 422);
				return;
			}
			local.id = Val(local.idRaw);
			local.parentId = Val(local.parentIdRaw);
			if (!StructKeyExists(local.knownIds, local.id) || StructKeyExists(local.seenIds, local.id)) {
				renderJson({ success: false, message: "The menu order contains an unknown or duplicate item." }, 422);
				return;
			}
			if (local.parentId > 0 && (!StructKeyExists(local.knownIds, local.parentId) || local.parentId == local.id)) {
				renderJson({ success: false, message: "The menu order contains an invalid parent." }, 422);
				return;
			}
			local.seenIds[local.id] = true;
			local.parents[local.id] = local.parentId;
			ArrayAppend(local.order, {
				id: local.id,
				parentId: local.parentId,
				sortOrder: Int(Val(local.sortOrderRaw))
			});
		}

		for (local.entry in local.order) {
			local.walkId = local.entry.parentId;
			local.visited = {};
			while (local.walkId > 0) {
				if (local.walkId == local.entry.id || StructKeyExists(local.visited, local.walkId)) {
					renderJson({ success: false, message: "Menu items cannot be nested beneath themselves." }, 422);
					return;
				}
				local.visited[local.walkId] = true;
				local.walkId = local.parents[local.walkId];
			}
		}

		try {
			transaction {
				for (local.entry in local.order) {
					navigationQuery("
						UPDATE navigation_menu_items
						SET parent_item_id = :parentId, sort_order = :sortOrder, updatedat = SYSUTCDATETIME()
						WHERE id = :id AND navigation_menu_id = :menuId AND deletedat IS NULL
					", {
						parentId: local.entry.parentId > 0
							? intParam(local.entry.parentId)
							: { value: "", cfsqltype: "cf_sql_integer", null: true },
						sortOrder: intParam(local.entry.sortOrder),
						id: intParam(local.entry.id),
						menuId: intParam(local.menuId)
					});
				}
			}
		} catch (any e) {
			writeLog(type="error", file="navigation", text="Navigation order update failed: #e.message# #e.detail#");
			renderJson({ success: false, message: "Unable to save the menu order. Please try again." }, 500);
			return;
		}

		renderJson({ success: true, message: "Menu order saved." });
	}

	private string function activeNavigationSiteId() {
		local.requested = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		local.workspace = resolveUserActiveWorkspace(
			requestedWs=local.requested,
			role=getCurrentActiveRole()
		);
		return local.workspace.id;
	}

	private numeric function findNavigationMenuId(required string siteid) {
		local.row = navigationQuery("
			SELECT id FROM navigation_menus
			WHERE siteid = :siteid AND menu_key = :menuKey
		", {
			siteid: stringParam(arguments.siteid, 100),
			menuKey: stringParam("side", 100)
		});
		if (local.row.recordCount) return Val(local.row.id);

		local.candidates = getCandidateSiteIds(arguments.siteid);
		for (local.cand in local.candidates) {
			local.row = navigationQuery("
				SELECT id FROM navigation_menus
				WHERE siteid = :siteid AND menu_key = :menuKey
			", {
				siteid: stringParam(local.cand, 100),
				menuKey: stringParam("side", 100)
			});
			if (local.row.recordCount) return Val(local.row.id);
		}
		return 0;
	}

	private string function resolveWorkspaceBasePath(required string siteid) {
		local.homeSlug = ReReplaceNoCase(arguments.siteid, "^site-", "");
		for (local.workspace in getMasterWorkspaces()) {
			if (CompareNoCase(local.workspace.id, arguments.siteid) == 0) {
				if (StructKeyExists(local.workspace, "virtual_directory")
					&& IsSimpleValue(local.workspace.virtual_directory)
					&& Len(Trim(local.workspace.virtual_directory))) {
					local.homeSlug = Trim(local.workspace.virtual_directory);
				} else if (StructKeyExists(local.workspace, "code")
					&& IsSimpleValue(local.workspace.code)
					&& Len(Trim(local.workspace.code))) {
					local.homeSlug = Trim(local.workspace.code);
				}
				break;
			}
		}
		local.cleanHomeSlug = ReReplace(local.homeSlug, "^/+|/+$", "", "all");
		return (arguments.siteid == "site-main" || arguments.siteid == "global" || !Len(local.cleanHomeSlug))
			? "/"
			: "/" & LCase(local.cleanHomeSlug);
	}

	private string function normalizeWorkspacePageDestination(required string destUrl, required string wsBasePath) {
		local.urlVal = Trim(arguments.destUrl);
		if (!Len(local.urlVal) || REFindNoCase("^https?://", local.urlVal)) {
			return local.urlVal;
		}
		if (Left(local.urlVal, 1) != "/") {
			local.urlVal = "/" & local.urlVal;
		}
		local.urlVal = REReplaceNoCase(local.urlVal, "\.cfm$", "", "one");
		local.urlVal = ReReplace(local.urlVal, "/+$", "", "one");
		if (!Len(local.urlVal)) {
			local.urlVal = "/";
		}

		local.cleanBase = ReReplace(arguments.wsBasePath, "^/+|/+$", "", "all");
		if (Len(local.cleanBase)) {
			local.basePath = "/" & LCase(local.cleanBase);
			if (
				CompareNoCase(local.urlVal, local.basePath) == 0
				|| CompareNoCase(local.urlVal, local.basePath & "/home") == 0
				|| CompareNoCase(local.urlVal, local.basePath & "/index") == 0
				|| CompareNoCase(local.urlVal, local.basePath & "/page/home") == 0
				|| CompareNoCase(local.urlVal, local.basePath & "/page/index") == 0
			) {
				return local.basePath;
			}
			if (REFindNoCase("^" & local.basePath & "/page/[^/]+$", local.urlVal)) {
				local.slugPart = ReReplaceNoCase(local.urlVal, "^" & local.basePath & "/page/+", "", "one");
				return local.basePath & "/page/" & local.slugPart;
			}
			if (REFindNoCase("^" & local.basePath & "/[^/]+$", local.urlVal)) {
				local.slugPart = ReReplaceNoCase(local.urlVal, "^" & local.basePath & "/+", "", "one");
				return local.basePath & "/page/" & local.slugPart;
			}
			return local.urlVal;
		} else {
			if (
				local.urlVal == "/"
				|| CompareNoCase(local.urlVal, "/home") == 0
				|| CompareNoCase(local.urlVal, "/index") == 0
			) {
				return "/";
			}
			if (!REFindNoCase("^/page/", local.urlVal)) {
				local.slugPart = ReReplace(local.urlVal, "^/+", "", "one");
				return "/page/" & local.slugPart;
			}
			return local.urlVal;
		}
	}

	private array function getCandidateSiteIds(required string wsId) {
		local.candidates = [arguments.wsId];
		local.cleanId = LCase(Trim(arguments.wsId));
		local.noSiteId = ReReplaceNoCase(local.cleanId, "^site-", "");
		if (Len(local.noSiteId) && !ArrayFindNoCase(local.candidates, local.noSiteId)) {
			ArrayAppend(local.candidates, local.noSiteId);
		}
		if (Right(local.noSiteId, 1) == "s" && Len(local.noSiteId) > 1) {
			local.singular = Left(local.noSiteId, Len(local.noSiteId) - 1);
			if (!ArrayFindNoCase(local.candidates, local.singular)) ArrayAppend(local.candidates, local.singular);
		} else if (Len(local.noSiteId)) {
			local.plural = local.noSiteId & "s";
			if (!ArrayFindNoCase(local.candidates, local.plural)) ArrayAppend(local.candidates, local.plural);
		}
		local.aliasMap = {
			"global": ["county-wide", "default", "chelan-county", "main"],
			"assessor": ["assessors", "1"],
			"auditor": ["2"],
			"board-of-commissioners": ["commissioners", "3"],
			"cashmere-dryden-airport": ["airport"],
			"clerk": ["superior-court-clerk", "4"],
			"community-development": ["5"],
			"coroner": ["6"],
			"county-fair": ["fair", "expo-center"],
			"district-court": ["7"],
			"economic-services": ["economic-development"],
			"emergency-management": ["em"],
			"facilities": ["maintenance", "facilities-maintenance"],
			"farm-worker-housing": ["fwh"],
			"flood-control-zone-district": ["flood-control"],
			"horticultural-pest-and-disease": ["pest-board", "horticultural"],
			"human-resources": ["hr", "8"],
			"information-technology": ["it", "9"],
			"jail": ["regional-justice-center", "ccrjc", "10"],
			"juvenile": ["juvenile-center", "11"],
			"natural-resources": ["nr", "12"],
			"noxious-weed": ["weed-board"],
			"ohme-gardens": ["ohme"],
			"prosecuting-attorney": ["prosecutor", "13"],
			"public-works": ["pw", "14"],
			"rivercom": ["rivercom-911", "911"],
			"sheriff": ["15"],
			"solid-waste": ["waste"],
			"superior-court": ["16"],
			"treasurer": ["17"],
			"veterans": ["veterans-program", "veterans-relief"],
			"water-conservancy-board": ["water-board"],
			"wenatchee-river-county-park": ["wenatchee-river-park", "park"]
		};
		if (StructKeyExists(local.aliasMap, local.noSiteId)) {
			for (local.alias in local.aliasMap[local.noSiteId]) {
				if (!ArrayFindNoCase(local.candidates, local.alias)) {
					ArrayAppend(local.candidates, local.alias);
				}
			}
		}
		for (local.c in Duplicate(local.candidates)) {
			if (Left(local.c, 5) != "site-") {
				local.withSite = "site-" & local.c;
				if (!ArrayFindNoCase(local.candidates, local.withSite)) {
					ArrayAppend(local.candidates, local.withSite);
				}
			}
		}
		return local.candidates;
	}

	private array function loadWorkspacePages(required string siteid, required string wsBasePath) {
		local.pages = [];
		try {
			local.candidates = getCandidateSiteIds(arguments.siteid);
			local.params = {};
			local.inList = [];
			for (local.i = 1; local.i <= ArrayLen(local.candidates); local.i++) {
				local.key = "ws" & local.i;
				ArrayAppend(local.inList, ":" & local.key);
				local.params[local.key] = { value: local.candidates[local.i], cfsqltype: "cf_sql_varchar" };
			}
			local.qPages = navigationQuery("
				SELECT p.ContentID, p.Title AS title, p.Permalink AS permalink, p.Visibility AS status, fe.FullPath
				FROM pages p
				LEFT JOIN page_FolderExplorer fe
					ON fe.ContentID = p.ContentID
					AND fe.WorkspaceID = p.siteid
				WHERE p.deletedat IS NULL
				  AND p.siteid IN (#ArrayToList(local.inList, ',')#)
				ORDER BY p.Title ASC
			", local.params);

			local.seenUrls = {};
			for (local.row in local.qPages) {
				local.rawTitle = Trim(local.row.title ?: "");
				if (!Len(local.rawTitle)) continue;

				local.rawSlug = Trim(local.row.permalink ?: "");
				local.fullPath = Trim(local.row.FullPath ?: "");
				local.publicUrl = "";

				if (!Len(local.rawSlug) && Len(local.fullPath)) {
					local.rawSlug = ListLast(REReplaceNoCase(local.fullPath, "\.cfm$", "", "one"), "/");
				}
				if (!Len(local.rawSlug)) {
					local.rawSlug = REReplace(LCase(local.rawTitle), "[^a-z0-9]+", "-", "all");
					local.rawSlug = REReplace(local.rawSlug, "^-+|-+$", "", "all");
				}

				local.cleanSlug = ReReplace(local.rawSlug, "^/+|/+$", "", "all");
				local.cleanBase = ReReplace(arguments.wsBasePath, "^/+|/+$", "", "all");
				if (Len(local.cleanBase)) {
					local.cleanSlug = ReReplaceNoCase(local.cleanSlug, "^" & local.cleanBase & "/(page/)?", "", "one");
				} else {
					local.cleanSlug = ReReplaceNoCase(local.cleanSlug, "^page/", "", "one");
				}

				if (LCase(local.cleanSlug) == "index" || LCase(local.cleanSlug) == "home" || !Len(local.cleanSlug)) {
					local.publicUrl = arguments.wsBasePath;
				} else {
					local.basePrefix = (arguments.wsBasePath == "/") ? "" : arguments.wsBasePath;
					local.publicUrl = local.basePrefix & "/page/" & local.cleanSlug;
				}

				if (!StructKeyExists(local.seenUrls, LCase(local.publicUrl))) {
					local.seenUrls[LCase(local.publicUrl)] = true;
					ArrayAppend(local.pages, {
						id: Val(local.row.ContentID),
						title: local.rawTitle,
						url: local.publicUrl,
						status: Trim(local.row.status ?: "Published")
					});
				}
			}
		} catch (any e) {
			writeLog(type="warning", file="navigation", text="Unable to load workspace pages for navigation: #e.message# #e.detail#");
		}
		return local.pages;
	}

	private string function resolveMenuItemPageUrl(
		required string label,
		required string wsBasePath,
		required array workspacePages
	) {
		local.cleanLabel = LCase(Trim(arguments.label));
		if (!Len(local.cleanLabel)) return "";
		if (local.cleanLabel == "home" || local.cleanLabel == "overview") {
			return arguments.wsBasePath;
		}
		for (local.pg in arguments.workspacePages) {
			if (LCase(Trim(local.pg.title)) == local.cleanLabel) {
				return local.pg.url;
			}
		}
		local.slug = REReplace(local.cleanLabel, "&", "and", "all");
		local.slug = REReplace(local.slug, "[^a-z0-9]+", "-", "all");
		local.slug = REReplace(local.slug, "^-+|-+$", "", "all");
		if (!Len(local.slug)) return "";

		for (local.pg in arguments.workspacePages) {
			if (Right(LCase(local.pg.url), Len(local.slug) + 1) == "/" & local.slug) {
				return local.pg.url;
			}
		}
		local.basePrefix = (arguments.wsBasePath == "/") ? "" : arguments.wsBasePath;
		return local.basePrefix & "/page/" & local.slug;
	}

	private boolean function navigationItemExists(required numeric menuId, required numeric itemId) {
		local.row = navigationQuery("
			SELECT id FROM navigation_menu_items
			WHERE id = :itemId AND navigation_menu_id = :menuId AND deletedat IS NULL
		", { itemId: intParam(arguments.itemId), menuId: intParam(arguments.menuId) });
		return local.row.recordCount > 0;
	}

	private boolean function navigationParentWouldCycle(required numeric menuId, required numeric itemId, required numeric parentId) {
		local.nextId = arguments.parentId;
		local.visited = {};
		while (local.nextId > 0) {
			if (local.nextId == arguments.itemId || StructKeyExists(local.visited, local.nextId)) return true;
			local.visited[local.nextId] = true;
			local.row = navigationQuery("
				SELECT parent_item_id FROM navigation_menu_items
				WHERE id = :itemId AND navigation_menu_id = :menuId AND deletedat IS NULL
			", { itemId: intParam(local.nextId), menuId: intParam(arguments.menuId) });
			if (!local.row.recordCount || !IsNumeric(local.row.parent_item_id)) return false;
			local.nextId = Val(local.row.parent_item_id);
		}
		return false;
	}

	private void function ensureIconColumn() {
		queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			IF COL_LENGTH('navigation_menu_items', 'icon') IS NULL
				ALTER TABLE navigation_menu_items ADD icon NVARCHAR(50) NULL
		", {}, { datasource: "ChelanCountyWebsite" });
	}

	private any function navigationQuery(required string sql, struct params = {}) {
		local.fullSql = "SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; " & arguments.sql;
		return queryExecute(local.fullSql, arguments.params, { datasource: "ChelanCountyWebsite" });
	}

	private struct function intParam(required numeric value) {
		return { value: arguments.value, cfsqltype: "cf_sql_integer" };
	}

	private struct function stringParam(required string value, numeric maxLength = 0) {
		return {
			value: arguments.value,
			cfsqltype: "cf_sql_nvarchar",
			maxlength: arguments.maxLength > 0 ? arguments.maxLength : Len(arguments.value)
		};
	}

	private struct function bitParam(required boolean value) {
		return { value: arguments.value ? 1 : 0, cfsqltype: "cf_sql_bit" };
	}

	private any function readJsonBody() {
		try {
			local.content = GetHTTPRequestData().content;
			if (IsBinary(local.content)) local.content = CharsetEncode(local.content, "utf-8");
			if (Len(Trim(local.content)) && IsJSON(local.content)) return DeserializeJSON(local.content);
		} catch (any e) {
			writeLog(type="warning", file="navigation", text="Unable to read navigation request body: #e.message#");
			return "";
		}
		return "";
	}

	private void function renderJson(required any data, numeric status = 200) {
		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text=SerializeJSON(arguments.data), status=arguments.status);
	}

	private string function safeJsonForScript(required any data) {
		return Replace(Replace(SerializeJSON(arguments.data), "</", "<\/", "all"), Chr(8232), "\u2028", "all");
	}

}
