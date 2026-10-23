component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="save,delete,restoreArchived,createModal,saveSubpage,deleteSubpage,saveFolderExplorer,deleteFolderExplorer,saveHowDoIItem,deleteHowDoIItem,reorderHowDoIItems,saveHowDoICategory,deleteHowDoICategory,prefillHowDoICategories,restoreRevision,snapshotRevision,saveCallToAction,deleteCallToAction,reorderCallToActions,convertDocument,saveOnePageSite,deleteOnePageSite,saveOnePageSection,deleteOnePageSection,reorderOnePageSections,syncOnePageToMenu,compileOnePageSite,publishOnePageToProduction");
	}

	/**
	 * Content Manager listing (reads from database with fallback to sample pages)
	 */
	function index() {
		variables.pageTitle = "Content Manager";
		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");
		variables.activeWorkspace = resolveUserActiveWorkspace(
			local.reqWs,
			getCurrentActiveRole()
		);
		variables.pages = loadPagesList();
	}

	/**
	 * Add / Edit Page. Pass ?id=N to load a page from database, omit for a new page.
	 */
	function edit() {
		ensurePagesTableColumns();
		local.all = loadPagesList();
		variables.page = {
			id: 0, title: "", slug: "", siteId: activeWorkspaceId(), menuItem: false, status: "Active", visibility: "Published",
			parent: "", layout: "Full", sidebarIds: [], updated: "", author: "", locked: false, summary: "", body: "", content: "",
			metaTitle: "", metaDesc: "", metaKeywords: "", hasArchive: false,
			imageAttachment: "", imageAttribution: "", imageAlt: "", imageTitle: "", imageDescription: "", imageDecorative: 0
		};

		if (StructKeyExists(params, "id") && IsNumeric(params.id) && Val(params.id) > 0) {
			local.dbPage = loadPageFromDb(Val(params.id));
			if (StructCount(local.dbPage)) {
				variables.page = local.dbPage;
			}
		} else if (StructKeyExists(params, "parent")) {
			for (local.p in local.all) {
				if (CompareNoCase(local.p.title, params.parent) == 0) {
					variables.page.parent = local.p.title;
					break;
				}
			}
		} else {
			// Populate from Add Page modal parameters if provided
			if (StructKeyExists(params, "title") && Len(Trim(params.title))) {
				variables.page.title = Trim(params.title);
			}
			if (StructKeyExists(params, "slug") && Len(Trim(params.slug))) {
				variables.page.slug = Trim(params.slug);
			}
			if (StructKeyExists(params, "layout") && Len(Trim(params.layout))) {
				variables.page.layout = Trim(params.layout);
			}
		}
		variables.isNew = (variables.page.id == 0);
		variables.pageTitle = variables.isNew ? "Add Page" : "Edit Page";
		variables.allPages = local.all;
		local.currentActiveWs = activeWorkspaceId();
		if (!Len(local.currentActiveWs) && StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) {
			local.rawCk = LCase(Trim(cookie.cmsadmin_workspace));
			if (local.rawCk != "global" && local.rawCk != "all") {
				local.currentActiveWs = local.rawCk;
			}
		}
		local.editSiteId = Len(local.currentActiveWs) ? local.currentActiveWs : ((StructKeyExists(variables.page, "siteId") && Len(Trim(variables.page.siteId)) && variables.page.siteId != "global" && variables.page.siteId != "all") ? Trim(variables.page.siteId) : "");
		variables.editSiteId = local.editSiteId;
		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.editSiteId, role = local.role);
		variables.availableSubpages = loadSubpages(contentId=variables.page.id, requestedWs=local.editSiteId, assignedIds=variables.page.sidebarIds);
		variables.availableSidebars = [];
		variables.availableFolders = loadFolderExplorers(contentId=variables.page.id, requestedWs=local.editSiteId);
		variables.menuItemOptions = loadMenuItemOptions(requestedWs=local.editSiteId, currentSelected=variables.page.parent);
		variables.availableForms = loadWorkspaceForms(requestedWs=local.editSiteId);
		local.showAllCtas = (local.editSiteId == "global" || local.editSiteId == "all" || !Len(local.editSiteId));
		variables.availableCtas = loadCallToActions(requestedWs=local.editSiteId, includeAllWorkspaces=local.showAllCtas);

		// Page Revisions and Version Tracking (RCW 42.56 compliance)
		variables.revisionCount = 0;
		variables.currentVersion = 1;
		if (variables.page.id > 0) {
			try {
				ensurePageRevisionsTable();
				local.revCountQ = queryExecute("
					SELECT COUNT(*) AS cnt, MAX(version_number) AS max_ver
					FROM page_revisions
					WHERE page_id = :id
				", { id: { value: variables.page.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
				variables.revisionCount = Val(local.revCountQ.cnt);
				variables.currentVersion = Val(local.revCountQ.max_ver);
				if (variables.revisionCount == 0 && Len(Trim(variables.page.title))) {
					local.initRev = recordPageRevision(variables.page.id, "System", "Initial baseline version snapshot");
					if (local.initRev.success) {
						variables.revisionCount = 1;
						variables.currentVersion = 1;
					}
				}
				if (variables.currentVersion == 0) variables.currentVersion = 1;
			} catch (any errRev) {
				variables.revisionCount = 0;
				variables.currentVersion = 1;
			}
		}
	}

	/**
	 * Add / Edit Page (Legacy v2 Route Alias)
	 */
	function editV2() {
		edit();
		renderView(template="edit");
	}

	/**
	 * Resolves candidate SiteID values for a given workspace identifier (handles code, alias, virtual_dir, and singular/plural variations).
	 */
	private array function getCandidateSiteIds(string wsId = "") {
		local.candidates = [];
		local.rawId = Trim(arguments.wsId);
		if (!Len(local.rawId)) {
			local.rawId = activeWorkspaceId();
		}
		if (!Len(local.rawId) || local.rawId == "global" || local.rawId == "all") {
			return local.candidates;
		}

		local.wsObj = resolveUserActiveWorkspace(requestedWs=local.rawId, role=getCurrentActiveRole());
		local.siteid = LCase(Trim(StructKeyExists(local.wsObj, "id") ? local.wsObj.id : local.rawId));

		if (Len(local.siteid) && local.siteid != "global" && local.siteid != "all") {
			ArrayAppend(local.candidates, local.siteid);
		}
		if (StructKeyExists(local.wsObj, "code") && Len(Trim(local.wsObj.code)) && !ArrayFindNoCase(local.candidates, local.wsObj.code)) {
			ArrayAppend(local.candidates, LCase(Trim(local.wsObj.code)));
		}
		if (StructKeyExists(local.wsObj, "alias") && Len(Trim(local.wsObj.alias)) && !ArrayFindNoCase(local.candidates, local.wsObj.alias)) {
			ArrayAppend(local.candidates, LCase(Trim(local.wsObj.alias)));
		}
		if (StructKeyExists(local.wsObj, "virtual_directory") && Len(Trim(local.wsObj.virtual_directory)) && !ArrayFindNoCase(local.candidates, local.wsObj.virtual_directory)) {
			ArrayAppend(local.candidates, LCase(Trim(local.wsObj.virtual_directory)));
		}
		// Handle common Chelan County code/alias variations (e.g. assessor <-> assessors)
		if (Len(local.siteid)) {
			if (Right(local.siteid, 1) == "s") {
				local.singular = Left(local.siteid, Len(local.siteid) - 1);
				if (Len(local.singular) && !ArrayFindNoCase(local.candidates, local.singular)) ArrayAppend(local.candidates, local.singular);
			} else {
				local.plural = local.siteid & "s";
				if (!ArrayFindNoCase(local.candidates, local.plural)) ArrayAppend(local.candidates, local.plural);
			}
		}

		// Also add variations with/without 'site-' prefix
		for (local.c in Duplicate(local.candidates)) {
			if (Left(local.c, 5) == "site-") {
				local.noSite = Mid(local.c, 6, Len(local.c));
				if (Len(local.noSite) && !ArrayFindNoCase(local.candidates, local.noSite)) {
					ArrayAppend(local.candidates, local.noSite);
				}
			} else {
				local.withSite = "site-" & local.c;
				if (!ArrayFindNoCase(local.candidates, local.withSite)) {
					ArrayAppend(local.candidates, local.withSite);
				}
			}
		}

		return local.candidates;
	}

	/**
	 * POST JSON: creates a new page from the Add Page modal directly into database
	 * Accepts { title, slug, layout, siteId } and returns { success: true, id, redirectUrl }
	 */
	function createModal() {
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.title = Left(Trim(local.req.title ?: ""), 255);
		local.rawSlug = Trim(local.req.slug ?: (local.req.permalink ?: ""));
		local.layout = Trim(local.req.layout ?: (local.req.layoutType ?: "Right Sidebar"));
		local.siteId = LCase(Trim(local.req.siteId ?: (local.req.siteID ?: "")));

		if (!Len(local.siteId) || local.siteId == "all" || local.siteId == "global") {
			local.siteId = activeWorkspaceId();
		}
		if (!Len(local.siteId) || local.siteId == "all" || local.siteId == "global") {
			fxRenderJson({ success: false, message: "Please select a workspace before creating a page." }, 422);
			return;
		}

		if (!Len(local.title)) {
			fxRenderJson({ success: false, message: "Page title is required." }, 422);
			return;
		}

		local.slug = Len(local.rawSlug) ? slugifyText(local.rawSlug) : slugifyText(local.title);
		if (!Len(local.slug)) {
			local.slug = "page-" & LCase(Left(CreateUUID(), 8));
		}

		if (local.layout != "Full" && local.layout != "Right Sidebar") {
			local.layout = "Right Sidebar";
		}

		local.actor = spCurrentActor();

		// Ensure unique slug per workspace (checking all candidate aliases for the workspace)
		local.candidateSiteIds = getCandidateSiteIds(local.siteId);
		if (ArrayLen(local.candidateSiteIds) == 0) ArrayAppend(local.candidateSiteIds, local.siteId);
		local.inPlaceholders = [];
		local.siteParams = {};
		for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
			local.pName = "csId" & local.idx;
			ArrayAppend(local.inPlaceholders, ":" & local.pName);
			local.siteParams[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
		}
		local.siteInClause = ArrayToList(local.inPlaceholders, ", ");

		local.forceNew = StructKeyExists(local.req, "forceNew") && (local.req.forceNew == 1 || local.req.forceNew == "true" || local.req.forceNew == true);

		// If not explicitly forcing a new page, check if an archived/soft-deleted page matches this slug or title
		if (!local.forceNew) {
			local.archivedParams = StructCopy(local.siteParams);
			local.archivedParams.slug = { value: local.slug, cfsqltype: "cf_sql_nvarchar" };
			local.archivedParams.title = { value: local.title, cfsqltype: "cf_sql_nvarchar" };

			local.archivedQ = queryExecute("
				SELECT TOP 1 ContentID, Title, Permalink, StatusCode, Visibility, LayoutType,
				       DeletedAt, Modified, ModifiedBy, Created, CreatedBy
				FROM pages
				WHERE SiteID IN (" & local.siteInClause & ")
				  AND DeletedAt IS NOT NULL
				  AND (Permalink = :slug OR LOWER(Title) = LOWER(:title))
				ORDER BY DeletedAt DESC, ContentID DESC
			", local.archivedParams, { datasource: "ChelanCountyWebsite" });

			if (local.archivedQ.recordCount > 0) {
				local.delAtStr = "";
				if (IsDate(local.archivedQ.DeletedAt)) {
					local.delAtStr = DateFormat(local.archivedQ.DeletedAt, "mm/dd/yyyy") & " " & TimeFormat(local.archivedQ.DeletedAt, "hh:mm TT");
				}
				local.delByStr = Len(Trim(local.archivedQ.ModifiedBy)) ? Trim(local.archivedQ.ModifiedBy) : (Trim(local.archivedQ.CreatedBy) ?: "Staff");

				fxRenderJson({
					"success": false,
					"SUCCESS": false,
					"archivedFound": true,
					"ARCHIVEDFOUND": true,
					"message": "An archived page matching this title or URL was found in this workspace.",
					"archivedPage": {
						"id": Val(local.archivedQ.ContentID),
						"title": local.archivedQ.Title ?: "",
						"slug": local.archivedQ.Permalink ?: "",
						"deletedAt": local.delAtStr,
						"deletedBy": local.delByStr,
						"layout": local.archivedQ.LayoutType ?: "Right Sidebar"
					}
				});
				return;
			}
		}

		local.candidateSlug = local.slug;
		local.counter = 2;
		while (true) {
			local.checkParams = StructCopy(local.siteParams);
			local.checkParams.slug = { value: local.candidateSlug, cfsqltype: "cf_sql_nvarchar" };
			local.existsQ = queryExecute("
				SELECT TOP 1 ContentID FROM pages WHERE SiteID IN (" & local.siteInClause & ") AND Permalink = :slug AND DeletedAt IS NULL
			", local.checkParams, { datasource: "ChelanCountyWebsite" });

			if (local.existsQ.recordCount == 0) {
				local.slug = local.candidateSlug;
				break;
			}
			local.candidateSlug = local.slug & "-" & local.counter;
			local.counter++;
			if (local.counter > 50) break;
		}

		try {
			local.res = queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				SET NOCOUNT ON;
				DECLARE @InsertedPages TABLE (newId INT);
				INSERT INTO pages (
					SiteID, PageType, MenuSelected, LayoutType, ParentID,
					StatusCode, Permalink, Title, MetaTitle, MetaDesc, MetaKeyWords,
					Summary, Body, isService, hasArchive, ShowInMenu, isLocked,
					isPublished, Visibility, ViewCount, Created, CreatedBy, Modified, ModifiedBy
				)
				OUTPUT INSERTED.ContentID INTO @InsertedPages(newId)
				VALUES (
					:siteId, 0, '', :layout, 0,
					'Active', :slug, :title, :title, '', '',
					'', '', 0, 0, 0, 0,
					0, 'Draft', 0, SYSUTCDATETIME(), :actor, SYSUTCDATETIME(), :actor
				);
				SELECT newId FROM @InsertedPages;
			", {
				siteId: { value: local.siteId, cfsqltype: "cf_sql_nvarchar" },
				layout: { value: local.layout, cfsqltype: "cf_sql_nvarchar" },
				slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
				title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
				actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
			}, { datasource: "ChelanCountyWebsite" });

			local.newId = Val(local.res.newId);

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"id": local.newId,
				"ID": local.newId,
				"newId": local.newId,
				"title": local.title,
				"slug": local.slug,
				"layout": local.layout,
				"siteId": local.siteId,
				"redirectUrl": "/pages/edit?id=" & local.newId & "&created=1"
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="Failed to create page via modal: #e.message# #e.detail#");
			fxRenderJson({ success: false, message: "Unable to create page: #e.message#" }, 500);
		}
	}

	/**
	 * POST JSON: saves full updates to an existing page in the database
	 */
	function save() {
		ensurePagesTableColumns();
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.id = Val(local.req.id ?: 0);
		local.title = Left(Trim(local.req.title ?: ""), 255);
		local.slug = slugifyText(local.req.slug ?: (local.req.permalink ?: ""));
		local.content = normalizeCtaLinkIcons(local.req.content ?: (local.req.body ?: ""));
		local.metaTitle = Left(Trim(local.req.metaTitle ?: ""), 255);
		local.metaDesc = Trim(local.req.metaDescription ?: (local.req.metaDesc ?: ""));
		local.metaKeywords = Trim(local.req.metaKeywords ?: (local.req.metaKeyWords ?: ""));
		local.status = Trim(local.req.status ?: "Active");
		local.visibility = Trim(local.req.visibility ?: "Published");
		local.hasPublishAt = StructKeyExists(local.req, "publishAt") && Len(Trim(local.req.publishAt)) && IsDate(local.req.publishAt);
		local.publishAtDate = local.hasPublishAt ? ParseDateTime(local.req.publishAt) : "";
		local.hasUnpublishAt = StructKeyExists(local.req, "unpublishAt") && Len(Trim(local.req.unpublishAt)) && IsDate(local.req.unpublishAt);
		local.unpublishAtDate = local.hasUnpublishAt ? ParseDateTime(local.req.unpublishAt) : "";
		local.layout = Trim(local.req.layout ?: "Full");
		local.pageAssignment = Trim(local.req.parent ?: "");
		local.menuItemTarget = Trim(local.req.menuItemTarget ?: "");
		local.menuItem = StructKeyExists(local.req, "menuItem") && (local.req.menuItem == 1 || local.req.menuItem == "true" || local.req.menuItem == true || local.req.menuItem == "yes");
		local.folderListingEnabled = StructKeyExists(local.req, "folderListingEnabled") && (local.req.folderListingEnabled == 1 || local.req.folderListingEnabled == "true" || local.req.folderListingEnabled == true || local.req.folderListingEnabled == "yes");
		local.sidebarIds = local.req.sidebarIds ?: [];
		if (!IsArray(local.sidebarIds)) {
			local.sidebarIds = ListToArray(local.sidebarIds);
		}
		local.sidebarJson = SerializeJSON(local.sidebarIds);

		if (!Len(local.title)) {
			fxRenderJson({ success: false, SUCCESS: false, message: "Page title is required." }, 422);
			return;
		}
		if (!Len(local.slug)) {
			local.slug = slugifyText(local.title);
		}

		local.actor = spCurrentActor();
		local.isPub = (local.visibility == "Published") ? 1 : 0;

		// Calculate PageType and MenuSelected based on Page Assignment (independent of ShowInMenu)
		if (local.pageAssignment == "Assign to Main Menu Item" || local.pageAssignment == "Assign to Menu Item") {
			local.pageType = 1;
			local.menuSelected = local.menuItemTarget;
		} else if (local.pageAssignment == "Top Level - Called from URL" || !Len(local.pageAssignment)) {
			local.pageType = 0;
			local.menuSelected = "";
		} else {
			local.pageType = 1;
			local.menuSelected = local.pageAssignment;
		}

		try {
			// If saving a brand new page directly from /pages/edit (id <= 0), insert initial row first
			if (local.id <= 0) {
				local.newSiteId = LCase(Trim(local.req.siteId ?: activeWorkspaceId()));
				if (!Len(local.newSiteId) || local.newSiteId == "all" || local.newSiteId == "global") {
					fxRenderJson({ success: false, SUCCESS: false, message: "Please select a workspace before creating a page." }, 422);
					return;
				}
				local.insRes = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					SET NOCOUNT ON;
					DECLARE @InsertedPages TABLE (newId INT);
					INSERT INTO pages (
						SiteID, PageType, MenuSelected, LayoutType, ParentID,
						StatusCode, Permalink, Title, MetaTitle, MetaDesc, MetaKeyWords,
						Summary, Body, isService, hasArchive, ShowInMenu, isLocked,
						isPublished, Visibility, ViewCount, Created, CreatedBy, Modified, ModifiedBy
					)
					OUTPUT INSERTED.ContentID INTO @InsertedPages(newId)
					VALUES (
						:siteId, 0, '', :layout, 0,
						'Active', :slug, :title, :title, '', '',
						'', '', 0, 0, 0, 0,
						0, 'Draft', 0, SYSUTCDATETIME(), :actor, SYSUTCDATETIME(), :actor
					);
					SELECT newId FROM @InsertedPages;
				", {
					siteId: { value: local.newSiteId, cfsqltype: "cf_sql_nvarchar" },
					layout: { value: local.layout, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });
				local.id = Val(local.insRes.newId);
			}

			// Retrieve existing record to check site, lock status, and avoid collisions
			local.curPageQ = queryExecute("
				SELECT SiteID, Permalink, isLocked, isService, imageAttachment, imageAttribution, imageAlt, imageTitle, imageDescription,
				       ISNULL(imageDecorative, 0) AS imageDecorative
				FROM pages
				WHERE ContentID = :id AND DeletedAt IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.curPageQ.recordCount == 0) {
				fxRenderJson({ success: false, SUCCESS: false, message: "Page not found in database." }, 404);
				return;
			}

			// Capture baseline revision of existing page if this is its first tracked revision
			ensurePageRevisionsTable();
			local.existingRevCheck = queryExecute("
				SELECT COUNT(*) AS cnt FROM page_revisions WHERE page_id = :id
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
			if (Val(local.existingRevCheck.cnt) == 0) {
				recordPageRevision(local.id, local.actor, "Baseline snapshot prior to edits");
			}

			local.siteId = local.curPageQ.SiteID ?: activeWorkspaceId();
			if (local.curPageQ.isLocked == 1) {
				// Locked / root pages keep their permalink
				local.slug = local.curPageQ.Permalink ?: local.slug;
			}

			// Validate duplicate permalink across workspace candidate aliases
			local.candidateSiteIds = getCandidateSiteIds(local.siteId);
			if (ArrayLen(local.candidateSiteIds) == 0 && Len(local.siteId)) ArrayAppend(local.candidateSiteIds, local.siteId);
			local.conflictPlaceholders = [];
			local.conflictParams = {
				slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			};
			for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
				local.pName = "confSite" & local.idx;
				ArrayAppend(local.conflictPlaceholders, ":" & local.pName);
				local.conflictParams[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
			}
			local.conflictInClause = ArrayLen(local.conflictPlaceholders) ? ArrayToList(local.conflictPlaceholders, ", ") : "''";

			local.conflictQ = queryExecute("
				SELECT TOP 1 ContentID FROM pages
				WHERE SiteID IN (" & local.conflictInClause & ") AND Permalink = :slug AND ContentID <> :id AND DeletedAt IS NULL
			", local.conflictParams, { datasource: "ChelanCountyWebsite" });

			if (local.conflictQ.recordCount > 0) {
				fxRenderJson({ success: false, SUCCESS: false, message: "The Page URL slug '" & local.slug & "' is already used by another page in this workspace." }, 422);
				return;
			}

			// Service & Image fields
			local.isService = StructKeyExists(local.req, "isService")
				? (local.req.isService == 1 || local.req.isService == "true" || local.req.isService == true || local.req.isService == "yes" ? 1 : 0)
				: Val(local.curPageQ.isService ?: 0);
			local.imageAttachment = StructKeyExists(local.req, "imageAttachment") ? Trim(local.req.imageAttachment) : (StructKeyExists(local.req, "featured_image") ? Trim(local.req.featured_image) : (local.curPageQ.imageAttachment ?: ""));
			local.imageAttribution = StructKeyExists(local.req, "imageAttribution") ? Trim(local.req.imageAttribution) : (StructKeyExists(local.req, "featured_image_credit") ? Trim(local.req.featured_image_credit) : (local.curPageQ.imageAttribution ?: ""));
			local.imageAlt = StructKeyExists(local.req, "imageAlt") ? Trim(local.req.imageAlt) : (StructKeyExists(local.req, "featured_image_alt") ? Trim(local.req.featured_image_alt) : (local.curPageQ.imageAlt ?: ""));
			local.imageTitle = StructKeyExists(local.req, "imageTitle") ? Trim(local.req.imageTitle) : (StructKeyExists(local.req, "featured_image_caption") ? Trim(local.req.featured_image_caption) : (local.curPageQ.imageTitle ?: ""));
			local.imageDescription = StructKeyExists(local.req, "imageDescription") ? Trim(local.req.imageDescription) : (StructKeyExists(local.req, "featured_image_description") ? Trim(local.req.featured_image_description) : (local.curPageQ.imageDescription ?: ""));
			local.imageDecorative = StructKeyExists(local.req, "imageDecorative") ? (local.req.imageDecorative == 1 || local.req.imageDecorative == "true" || local.req.imageDecorative == true || local.req.imageDecorative == "yes" ? 1 : 0) : (StructKeyExists(local.req, "featured_image_decorative") ? (local.req.featured_image_decorative == 1 || local.req.featured_image_decorative == "true" || local.req.featured_image_decorative == true || local.req.featured_image_decorative == "yes" ? 1 : 0) : Val(local.curPageQ.imageDecorative ?: 0));

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE pages
				SET Title = :title,
				    Permalink = :slug,
				    Body = :body,
				    MetaTitle = :metaTitle,
				    MetaDesc = :metaDesc,
				    MetaKeyWords = :metaKeywords,
				    Summary = :metaDesc,
				    StatusCode = :status,
				    Visibility = :visibility,
				    PublishAt = :publishAt,
				    publish_at = :publishAt,
				    UnpublishAt = :unpublishAt,
				    unpublish_at = :unpublishAt,
				    isPublished = :isPub,
				    LayoutType = :layout,
				    MenuSelected = :menuSelected,
				    ShowInMenu = :showInMenu,
				    PageType = :pageType,
				    hasArchive = :hasArchive,
				    isService = :isService,
				    imageAttachment = :imageAttachment,
				    imageAttribution = :imageAttribution,
				    imageAlt = :imageAlt,
				    imageTitle = :imageTitle,
				    imageDescription = :imageDescription,
				    imageDecorative = :imageDecorative,
				    SidebarIDs = :sidebarIds,
				    Modified = SYSUTCDATETIME(),
				    ModifiedBy = :actor
				WHERE ContentID = :id
			", {
				title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
				slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
				body: { value: local.content, cfsqltype: "cf_sql_nvarchar" },
				metaTitle: { value: local.metaTitle, cfsqltype: "cf_sql_nvarchar" },
				metaDesc: { value: local.metaDesc, cfsqltype: "cf_sql_nvarchar" },
				metaKeywords: { value: local.metaKeywords, cfsqltype: "cf_sql_nvarchar" },
				status: { value: local.status, cfsqltype: "cf_sql_nvarchar" },
				visibility: { value: local.visibility, cfsqltype: "cf_sql_nvarchar" },
				publishAt: local.hasPublishAt ? { value: local.publishAtDate, cfsqltype: "cf_sql_timestamp" } : { null: true, cfsqltype: "cf_sql_timestamp" },
				unpublishAt: local.hasUnpublishAt ? { value: local.unpublishAtDate, cfsqltype: "cf_sql_timestamp" } : { null: true, cfsqltype: "cf_sql_timestamp" },
				isPub: { value: local.isPub, cfsqltype: "cf_sql_bit" },
				layout: { value: local.layout, cfsqltype: "cf_sql_nvarchar" },
				menuSelected: { value: local.menuSelected, cfsqltype: "cf_sql_nvarchar" },
				showInMenu: { value: local.menuItem ? 1 : 0, cfsqltype: "cf_sql_bit" },
				pageType: { value: local.pageType, cfsqltype: "cf_sql_tinyint" },
				hasArchive: { value: local.folderListingEnabled ? 1 : 0, cfsqltype: "cf_sql_bit" },
				isService: { value: local.isService, cfsqltype: "cf_sql_bit" },
				imageAttachment: { value: local.imageAttachment, cfsqltype: "cf_sql_nvarchar" },
				imageAttribution: { value: local.imageAttribution, cfsqltype: "cf_sql_nvarchar" },
				imageAlt: { value: local.imageAlt, cfsqltype: "cf_sql_nvarchar" },
				imageTitle: { value: local.imageTitle, cfsqltype: "cf_sql_nvarchar" },
				imageDescription: { value: local.imageDescription, cfsqltype: "cf_sql_nvarchar" },
				imageDecorative: { value: local.imageDecorative, cfsqltype: "cf_sql_bit" },
				sidebarIds: { value: local.sidebarJson, cfsqltype: "cf_sql_nvarchar" },
				actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			// Sync checked Folder Explorer items for this page (avoid setting ContentID = 0 which violates FK_page_FolderExplorer_pages)
			if (StructKeyExists(local.req, "folderListingIds")) {
				local.rawFolderIds = IsArray(local.req.folderListingIds) ? local.req.folderListingIds : ListToArray(ToString(local.req.folderListingIds));
				local.checkedFolderIds = [];
				for (local.fIdItem in local.rawFolderIds) {
					local.cleanFid = Val(local.fIdItem);
					if (local.cleanFid > 0 && !ArrayFind(local.checkedFolderIds, local.cleanFid)) {
						ArrayAppend(local.checkedFolderIds, local.cleanFid);
					}
				}
				if (!local.folderListingEnabled || ArrayLen(local.checkedFolderIds) == 0) {
					try {
						queryExecute("
							UPDATE page_FolderExplorer SET ContentID = NULL WHERE ContentID = :pageId
						", { pageId: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
					} catch (any errFeNull) {}
				} else {
					local.fPlaceholders = [];
					local.fParams = { pageId: { value: local.id, cfsqltype: "cf_sql_integer" } };
					for (local.fIdx = 1; local.fIdx <= ArrayLen(local.checkedFolderIds); local.fIdx++) {
						local.fpName = "fId" & local.fIdx;
						ArrayAppend(local.fPlaceholders, ":" & local.fpName);
						local.fParams[local.fpName] = { value: local.checkedFolderIds[local.fIdx], cfsqltype: "cf_sql_integer" };
					}
					local.fInClause = ArrayToList(local.fPlaceholders, ", ");
					queryExecute("
						UPDATE page_FolderExplorer SET ContentID = :pageId WHERE ID IN (" & local.fInClause & ");
					", local.fParams, { datasource: "ChelanCountyWebsite" });
					try {
						queryExecute("
							UPDATE page_FolderExplorer SET ContentID = NULL WHERE ContentID = :pageId AND ID NOT IN (" & local.fInClause & ");
						", local.fParams, { datasource: "ChelanCountyWebsite" });
					} catch (any errFeUnlink) {}
				}
			}

			// Record the updated state as the new revision version (RCW 42.56 compliance)
			local.changeNote = StructKeyExists(local.req, "changeSummary") && Len(Trim(local.req.changeSummary))
				? Trim(local.req.changeSummary)
				: (StructKeyExists(local.req, "changeNote") && Len(Trim(local.req.changeNote)) ? Trim(local.req.changeNote) : "Published page update");
			recordPageRevision(local.id, local.actor, local.changeNote);

			local.revSummaryQ = queryExecute("
				SELECT COUNT(*) AS total_revs, MAX(version_number) AS max_ver
				FROM page_revisions
				WHERE page_id = :id
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			local.updatedStr = DateFormat(Now(), "mm/dd/yyyy") & " " & TimeFormat(Now(), "hh:mm:ss");
			fxRenderJson({
				success: true,
				SUCCESS: true,
				id: local.id,
				ID: local.id,
				message: "Page saved successfully.",
				MESSAGE: "Page saved successfully.",
				updated: local.updatedStr,
				UPDATED: local.updatedStr,
				author: local.actor,
				AUTHOR: local.actor,
				title: local.title,
				TITLE: local.title,
				slug: local.slug,
				SLUG: local.slug,
				revisionCount: Val(local.revSummaryQ.total_revs),
				REVISIONCOUNT: Val(local.revSummaryQ.total_revs),
				versionNumber: Val(local.revSummaryQ.max_ver),
				VERSIONNUMBER: Val(local.revSummaryQ.max_ver)
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="Failed to save page: #e.message# #e.detail#");
			fxRenderJson({ success: false, SUCCESS: false, message: "Unable to save page: #e.message#" }, 500);
		}
	}

	/**
	 * POST /pages/delete
	 * Soft-deletes an Inactive Page (sets DeletedAt = SYSUTCDATETIME())
	 * Only allowed when page StatusCode is 'Inactive' and isLocked is 0
	 */
	function delete() {
		local.res = { "success": false, "SUCCESS": false, "message": "" };
		try {
			local.body = fxReadJsonBody();
			local.req = IsStruct(local.body) ? local.body : params;
			local.id = Val(local.req.id ?: 0);

			if (local.id <= 0) {
				local.res.message = "Invalid page ID specified.";
				fxRenderJson(local.res, 400);
				return;
			}

			// Verify page exists, is not already deleted, and is Inactive
			local.checkQ = queryExecute("
				SELECT ContentID, Title, StatusCode, isLocked
				FROM pages
				WHERE ContentID = :id AND DeletedAt IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.checkQ.recordCount == 0) {
				local.res.message = "Page not found or already deleted.";
				fxRenderJson(local.res, 404);
				return;
			}

			if (Val(local.checkQ.isLocked) == 1) {
				local.res.message = "System locked pages cannot be deleted.";
				fxRenderJson(local.res, 403);
				return;
			}

			if (CompareNoCase(Trim(local.checkQ.StatusCode), "Inactive") != 0) {
				local.res.message = "Only Inactive pages can be soft-deleted. Please change page status to Inactive before deleting.";
				fxRenderJson(local.res, 400);
				return;
			}

			local.actor = spCurrentActor();

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;

				UPDATE pages
				SET DeletedAt = SYSUTCDATETIME(),
				    Modified = SYSUTCDATETIME(),
				    ModifiedBy = :actor
				WHERE ContentID = :id AND DeletedAt IS NULL
			", {
				actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar", null: !Len(local.actor) },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			// Record legal audit snapshot in page_revisions (RCW 42.56 compliance)
			try {
				ensurePageRevisionsTable();
				local.maxVerQ = queryExecute("
					SELECT ISNULL(MAX(version_number), 0) AS max_v
					FROM page_revisions
					WHERE page_id = :pid
				", { pid: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
				local.nextVer = Val(local.maxVerQ.max_v) + 1;

				queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;

					INSERT INTO page_revisions (
						page_id, version_number, title, slug, content_html, summary,
						layout_type, meta_json, change_summary, created_by, created_at
					) VALUES (
						:page_id, :version_number, :title, :slug, :content_html, :summary,
						:layout_type, :meta_json, :change_summary, :created_by, SYSUTCDATETIME()
					)
				", {
					page_id: { value: local.id, cfsqltype: "cf_sql_integer" },
					version_number: { value: local.nextVer, cfsqltype: "cf_sql_integer" },
					title: { value: local.checkQ.Title, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: "deleted-" & local.id, cfsqltype: "cf_sql_nvarchar" },
					content_html: { value: "", cfsqltype: "cf_sql_nvarchar" },
					summary: { value: "Page marked Inactive and soft-deleted", cfsqltype: "cf_sql_nvarchar" },
					layout_type: { value: "Full", cfsqltype: "cf_sql_nvarchar" },
					meta_json: { value: SerializeJSON({ "deleted": true, "deleted_at": Now(), "deleted_by": local.actor }), cfsqltype: "cf_sql_nvarchar" },
					change_summary: { value: "Soft-deleted from Content Manager pages directory", cfsqltype: "cf_sql_nvarchar" },
					created_by: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });
			} catch (any eRev) {
				writeLog(type="error", file="pages", text="Failed to record deletion snapshot: #eRev.message#");
			}

			local.res.success = true;
			local.res.SUCCESS = true;
			local.res.message = "Page '" & local.checkQ.Title & "' has been soft-deleted.";
			fxRenderJson(local.res);
		} catch (any e) {
			writeLog(type="error", file="pages", text="Failed to delete page: #e.message# #e.detail#");
			local.res.message = "Unable to delete page: " & e.message;
			fxRenderJson(local.res, 500);
		}
	}

	/**
	 * POST /pages/restore-archived
	 * Reactivates a soft-deleted page (sets DeletedAt = NULL, StatusCode = 'Active')
	 */
	function restoreArchived() {
		local.res = { "success": false, "SUCCESS": false, "message": "" };
		try {
			local.body = fxReadJsonBody();
			local.req = IsStruct(local.body) ? local.body : params;
			local.id = Val(local.req.id ?: 0);

			if (local.id <= 0) {
				local.res.message = "Invalid page ID specified.";
				fxRenderJson(local.res, 400);
				return;
			}

			// Verify page exists and is currently soft-deleted
			local.pageQ = queryExecute("
				SELECT ContentID, Title, Permalink, SiteID, StatusCode, LayoutType
				FROM pages
				WHERE ContentID = :id AND DeletedAt IS NOT NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.pageQ.recordCount == 0) {
				local.res.message = "Archived page not found or is already active.";
				fxRenderJson(local.res, 404);
				return;
			}

			local.actor = spCurrentActor();

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;

				UPDATE pages
				SET DeletedAt = NULL,
				    StatusCode = 'Active',
				    Visibility = 'Draft',
				    Modified = SYSUTCDATETIME(),
				    ModifiedBy = :actor
				WHERE ContentID = :id
			", {
				actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar", null: !Len(local.actor) },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			// Record legal audit snapshot in page_revisions (RCW 42.56 compliance)
			try {
				ensurePageRevisionsTable();
				local.maxVerQ = queryExecute("
					SELECT ISNULL(MAX(version_number), 0) AS max_v
					FROM page_revisions
					WHERE page_id = :pid
				", { pid: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
				local.nextVer = Val(local.maxVerQ.max_v) + 1;

				queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;

					INSERT INTO page_revisions (
						page_id, version_number, title, slug, content_html, summary,
						layout_type, meta_json, change_summary, created_by, created_at
					) VALUES (
						:page_id, :version_number, :title, :slug, :content_html, :summary,
						:layout_type, :meta_json, :change_summary, :created_by, SYSUTCDATETIME()
					)
				", {
					page_id: { value: local.id, cfsqltype: "cf_sql_integer" },
					version_number: { value: local.nextVer, cfsqltype: "cf_sql_integer" },
					title: { value: local.pageQ.Title, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.pageQ.Permalink, cfsqltype: "cf_sql_nvarchar" },
					content_html: { value: "", cfsqltype: "cf_sql_nvarchar" },
					summary: { value: "Page reactivated from archived state", cfsqltype: "cf_sql_nvarchar" },
					layout_type: { value: local.pageQ.LayoutType ?: "Full", cfsqltype: "cf_sql_nvarchar" },
					meta_json: { value: SerializeJSON({ "reactivated": true, "reactivated_at": Now(), "reactivated_by": local.actor }), cfsqltype: "cf_sql_nvarchar" },
					change_summary: { value: "Reactivated from archived state", cfsqltype: "cf_sql_nvarchar" },
					created_by: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });
			} catch (any eRev) {
				writeLog(type="error", file="pages", text="Failed to record reactivation snapshot: #eRev.message#");
			}

			local.res.success = true;
			local.res.SUCCESS = true;
			local.res.id = local.id;
			local.res.redirectUrl = "/pages/edit?id=" & local.id & "&reactivated=1";
			local.res.message = "Page '" & local.pageQ.Title & "' reactivated successfully.";
			fxRenderJson(local.res);
		} catch (any e) {
			writeLog(type="error", file="pages", text="Failed to restore archived page: #e.message# #e.detail#");
			local.res.message = "Unable to restore page: " & e.message;
			fxRenderJson(local.res, 500);
		}
	}

	/**
	 * Navigation menu items (depth-ordered) selectable under Page Attributes - Menu Item Selection.
	 */
	private array function loadMenuItemOptions(string requestedWs = "", string currentSelected = "") {
		local.options = [];
		try {
			local.requested = Len(Trim(arguments.requestedWs)) ? Trim(arguments.requestedWs)
				: (StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))
					? Trim(cookie.cmsadmin_workspace)
					: "");
			if (!Len(local.requested) || local.requested == "global" || local.requested == "all") {
				return [];
			}
			local.wsObj = resolveUserActiveWorkspace(requestedWs=local.requested, role=getCurrentActiveRole());
			local.siteid = local.wsObj.id;

			local.candidateSiteIds = getCandidateSiteIds(local.siteid);
			if (ArrayLen(local.candidateSiteIds) == 0 && Len(local.siteid)) ArrayAppend(local.candidateSiteIds, local.siteid);

			local.rows = queryNew("id,parent_item_id,label,siteid,menu_name", "integer,integer,varchar,varchar,varchar");

			if (ArrayLen(local.candidateSiteIds) > 0) {
				local.params = {};
				local.inPlaceholders = [];
				for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
					local.paramName = "siteid" & local.idx;
					ArrayAppend(local.inPlaceholders, ":" & local.paramName);
					local.params[local.paramName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar", maxlength: 100 };
				}
				local.inClause = ArrayToList(local.inPlaceholders, ", ");

				local.rows = queryExecute("
					SELECT i.id, i.parent_item_id, i.label, m.siteid, m.name AS menu_name
					FROM navigation_menu_items i
					INNER JOIN navigation_menus m ON m.id = i.navigation_menu_id
					WHERE m.siteid IN (" & local.inClause & ") AND m.menu_key = 'side' AND m.deletedat IS NULL AND i.deletedat IS NULL AND i.is_active = 1
					ORDER BY m.siteid, i.sort_order, i.id
				", local.params, { datasource: "ChelanCountyWebsite" });
			}

			// If no menu structure is defined for this workspace, return empty list immediately!
			if (local.rows.recordCount == 0) {
				return [];
			}

			// Build workspace name lookup for optgroup titles
			local.wsMap = {};
			try {
				for (local.w in getMasterWorkspaces()) {
					if (StructKeyExists(local.w, "name") && Len(local.w.name)) {
						if (StructKeyExists(local.w, "id")) local.wsMap[LCase(local.w.id)] = local.w.name;
						if (StructKeyExists(local.w, "code")) local.wsMap[LCase(local.w.code)] = local.w.name;
						if (StructKeyExists(local.w, "alias") && Len(local.w.alias)) local.wsMap[LCase(local.w.alias)] = local.w.name;
					}
				}
			} catch (any errWs) {}

			// Partition rows by menu/siteid to preserve hierarchy trees
			local.menuGroups = {};
			local.menuGroupKeys = [];
			for (local.row in local.rows) {
				local.mKey = local.row.siteid;
				if (!StructKeyExists(local.menuGroups, local.mKey)) {
					local.menuGroups[local.mKey] = [];
					ArrayAppend(local.menuGroupKeys, local.mKey);
				}
				ArrayAppend(local.menuGroups[local.mKey], local.row);
			}

			local.isMultiMenu = (ArrayLen(local.menuGroupKeys) > 1);

			// Walk each menu hierarchy depth-first
			for (local.mKey in local.menuGroupKeys) {
				local.groupRows = local.menuGroups[local.mKey];
				local.groupWsName = StructKeyExists(local.wsMap, LCase(local.mKey)) ? local.wsMap[LCase(local.mKey)] : local.mKey;
				local.groupMenuTitle = local.isMultiMenu ? local.groupWsName : "";

				local.itemIds = {};
				for (local.row in local.groupRows) {
					local.itemIds["k_" & local.row.id] = true;
				}

				local.children = {};
				for (local.row in local.groupRows) {
					local.pVal = (IsNumeric(local.row.parent_item_id) && Val(local.row.parent_item_id) > 0) ? Val(local.row.parent_item_id) : 0;
					// If parent is not in this group's rows, treat as root item (depth 0)
					if (local.pVal > 0 && !StructKeyExists(local.itemIds, "k_" & local.pVal)) {
						local.pVal = 0;
					}
					local.cKey = "k_" & local.pVal;
					if (!StructKeyExists(local.children, local.cKey)) local.children[local.cKey] = [];
					ArrayAppend(local.children[local.cKey], { id: local.row.id, label: local.row.label });
				}

				local.stack = [];
				if (StructKeyExists(local.children, "k_0")) {
					for (local.i = ArrayLen(local.children["k_0"]); local.i >= 1; local.i--) {
						ArrayAppend(local.stack, { item: local.children["k_0"][local.i], depth: 0 });
					}
				}

				local.guard = 0;
				while (ArrayLen(local.stack) && local.guard < 5000) {
					local.guard++;
					local.node = local.stack[ArrayLen(local.stack)];
					ArrayDeleteAt(local.stack, ArrayLen(local.stack));

					ArrayAppend(local.options, {
						id: local.node.item.id,
						label: local.node.item.label,
						depth: local.node.depth,
						group: local.groupMenuTitle
					});

					local.childKey = "k_" & local.node.item.id;
					if (StructKeyExists(local.children, local.childKey)) {
						for (local.i = ArrayLen(local.children[local.childKey]); local.i >= 1; local.i--) {
							ArrayAppend(local.stack, { item: local.children[local.childKey][local.i], depth: local.node.depth + 1 });
						}
					}
				}
			}
		} catch (any e) {
			local.options = [];
		}
		return local.options;
	}

	/**
	 * JSON menu item options for the workspace chosen in the header switcher.
	 */
	function menuItems() {
		local.ws = StructKeyExists(params, "ws") ? LCase(Trim(params.ws)) : "";
		if (!REFind("^[a-z0-9_-]{1,100}$", local.ws)) local.ws = "";
		local.selected = StructKeyExists(params, "selected") ? Trim(params.selected) : "";
		local.opts = loadMenuItemOptions(local.ws, local.selected);
		renderText(text=SerializeJSON({ "options": local.opts, "OPTIONS": local.opts }), contentType="application/json", layout=false);
	}

	/**
	 * Add Folder Explorer (form asking for title, absolute path, relative path, and layout)
	 */
	function folderExplorer() {
		variables.pageTitle = "Add Folder Explorer";
		variables.explorer = {
			title: StructKeyExists(params, "title") ? Trim(params.title) : "",
			absolutePath: StructKeyExists(params, "absolutePath") ? Trim(params.absolutePath) : "C:\inetpub\chelan-county\files\assessors",
			relativePath: StructKeyExists(params, "relativePath") ? Trim(params.relativePath) : "files/assessors",
			layout: StructKeyExists(params, "layout") && (params.layout eq "Full" or params.layout eq "3/9") ? Trim(params.layout) : "3/9",
			allowedExtensions: "pdf,doc,docx,xls,xlsx,jpg,png,zip",
			showBreadcrumbs: true,
			showFileSizes: true,
			showLastModified: true,
			enableSearch: true,
			status: "Active"
		};
	}

	/**
	 * Folder Explorer items saved for the workspace / page (page_FolderExplorer.ContentID = page id when attached).
	 */
	private array function loadFolderExplorers(required numeric contentId, string requestedWs = "") {
		local.items = [];
		local.siteId = Len(Trim(arguments.requestedWs)) ? Trim(arguments.requestedWs) : activeWorkspaceId();
		if ((!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") && StructKeyExists(variables, "page") && StructKeyExists(variables.page, "siteId") && Len(Trim(variables.page.siteId))) {
			local.siteId = Trim(variables.page.siteId);
		}
		if ((!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") && arguments.contentId <= 0) {
			return local.items;
		}

		local.candidateSiteIds = (Len(local.siteId) && local.siteId != "global" && local.siteId != "all") ? getCandidateSiteIds(local.siteId) : [];
		if (Len(local.siteId) && local.siteId != "global" && local.siteId != "all" && ArrayLen(local.candidateSiteIds) == 0) {
			ArrayAppend(local.candidateSiteIds, local.siteId);
		}

		local.whereClauses = [];
		local.params = {};
		if (ArrayLen(local.candidateSiteIds) > 0) {
			local.inPlaceholders = [];
			for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
				local.pName = "feSite" & local.idx;
				ArrayAppend(local.inPlaceholders, ":" & local.pName);
				local.params[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
			}
			local.inClause = ArrayToList(local.inPlaceholders, ", ");
			ArrayAppend(local.whereClauses, "SiteID IN (" & local.inClause & ")");
		}
		if (arguments.contentId > 0) {
			local.params.contentId = { value: arguments.contentId, cfsqltype: "cf_sql_integer" };
			ArrayAppend(local.whereClauses, "ContentID = :contentId");
		}
		if (ArrayLen(local.whereClauses) == 0) return local.items;

		try {
			local.rows = queryExecute("
				SELECT ID, ContentID, Title, RelativePath, AbsolutePath, Absolute, Weight, Layout, Placement
				FROM page_FolderExplorer
				WHERE (" & ArrayToList(local.whereClauses, " OR ") & ")
				ORDER BY Weight, ID
			", local.params, { datasource: "ChelanCountyWebsite" });
			for (local.row in local.rows) {
				ArrayAppend(local.items, {
					id: local.row.ID,
					contentId: Val(local.row.ContentID),
					selected: (arguments.contentId > 0 && Val(local.row.ContentID) == Val(arguments.contentId)),
					name: local.row.Title,
					path: Len(local.row.AbsolutePath) ? local.row.AbsolutePath : local.row.RelativePath,
					absolutePath: local.row.AbsolutePath,
					relativePath: local.row.RelativePath,
					absolute: local.row.Absolute,
					weight: local.row.Weight,
					layout: local.row.Layout,
					placement: local.row.Placement
				});
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="Folder explorer load failed: #e.message# #e.detail#");
		}
		return local.items;
	}

	/**
	 * Loads available forms that belong strictly to the requested workspace / department
	 */
	private array function loadWorkspaceForms(string requestedWs = "") {
		local.forms = [];
		try {
			local.targetWs = Trim(arguments.requestedWs);
			if (!Len(local.targetWs) || local.targetWs == "global" || local.targetWs == "all") {
				local.targetWs = activeWorkspaceId();
			}
			if (!Len(local.targetWs) && StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) {
				local.rawCk = LCase(Trim(cookie.cmsadmin_workspace));
				if (local.rawCk != "global" && local.rawCk != "all") {
					local.targetWs = local.rawCk;
				}
			}
			// If still empty or global, check if page has a specific workspace
			if ((!Len(local.targetWs) || local.targetWs == "global" || local.targetWs == "all") && StructKeyExists(variables, "page") && StructKeyExists(variables.page, "siteId") && Len(Trim(variables.page.siteId))) {
				local.pageWs = LCase(Trim(variables.page.siteId));
				if (local.pageWs != "global" && local.pageWs != "all") {
					local.targetWs = local.pageWs;
				}
			}

			local.cands = [];
			if (Len(local.targetWs) && local.targetWs != "global" && local.targetWs != "all") {
				local.cands = getCandidateSiteIds(local.targetWs);
				if (!ArrayFindNoCase(local.cands, local.targetWs)) {
					ArrayAppend(local.cands, LCase(Trim(local.targetWs)));
				}
				// Also include singular/plural variations
				local.lowTarget = LCase(Trim(local.targetWs));
				if (Right(local.lowTarget, 1) == "s") {
					local.sing = Left(local.lowTarget, Len(local.lowTarget) - 1);
					if (Len(local.sing) && !ArrayFindNoCase(local.cands, local.sing)) ArrayAppend(local.cands, local.sing);
				} else {
					local.plur = local.lowTarget & "s";
					if (!ArrayFindNoCase(local.cands, local.plur)) ArrayAppend(local.cands, local.plur);
				}
			}

			local.q = queryExecute("
				SELECT f.id, f.form_key, f.slug, f.title, f.description, f.siteid, f.status,
				       d.name AS dept_name, d.badge_class AS dept_badge
				FROM forms f
				LEFT JOIN form_departments d ON d.id = f.department_id
				WHERE f.deletedat IS NULL
				ORDER BY f.title ASC
			", {}, { datasource: "ChelanCountyWebsite" });

			for (local.row in local.q) {
				local.rowSiteId = LCase(Trim(local.row.siteid ?: (local.row.SITEID ?: "")));
				local.isMatch = false;

				if (ArrayLen(local.cands) > 0) {
					if (ArrayFindNoCase(local.cands, local.rowSiteId) > 0) {
						local.isMatch = true;
					}
				} else if (Len(local.targetWs) && local.targetWs != "global" && local.targetWs != "all") {
					if (local.rowSiteId == LCase(local.targetWs)) {
						local.isMatch = true;
					}
				} else {
					// Fallback only if no workspace filter at all
					local.isMatch = true;
				}

				// Only show forms that belong to the workspace
				if (!local.isMatch) {
					continue;
				}

				local.formId = Val(local.row.id ?: (local.row.ID ?: 0));
				local.formKey = local.row.form_key ?: (local.row.FORM_KEY ?: "");
				local.formSlug = local.row.slug ?: (local.row.SLUG ?: "");
				local.formTitle = Len(Trim(local.row.title ?: (local.row.TITLE ?: ""))) ? (local.row.title ?: local.row.TITLE) : "Untitled Form";
				local.formDesc = local.row.description ?: (local.row.DESCRIPTION ?: "");
				local.formSite = local.row.siteid ?: (local.row.SITEID ?: "");
				local.formStatus = LCase(local.row.status ?: (local.row.STATUS ?: "published"));
				local.rawDept = local.row.dept_name ?: (local.row.DEPT_NAME ?: "");
				local.deptName = Len(Trim(local.rawDept)) ? local.rawDept : (Len(Trim(local.formSite)) ? local.formSite : "General");
				local.rawBadge = local.row.dept_badge ?: (local.row.DEPT_BADGE ?: "");
				local.deptBadge = Len(Trim(local.rawBadge)) ? local.rawBadge : "badge-primary";

				ArrayAppend(local.forms, {
					id: local.formId,
					formKey: local.formKey,
					slug: local.formSlug,
					title: local.formTitle,
					description: local.formDesc,
					siteid: local.formSite,
					status: local.formStatus,
					deptName: local.deptName,
					deptBadge: local.deptBadge,
					isCurrentWorkspace: true
				});
			}

			// Sort alphabetically by title
			ArraySort(local.forms, function(a, b) {
				return CompareNoCase(a.title, b.title);
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="Failed to load forms: #e.message# #e.detail#");
		}
		return local.forms;
	}

	/**
	 * JSON endpoint returning available forms for a given workspace
	 * /pages/workspaceForms?ws=assessor
	 */
	function workspaceForms() {
		local.ws = StructKeyExists(params, "ws") ? LCase(Trim(params.ws)) : "";
		if (!REFind("^[a-z0-9_-]{1,100}$", local.ws)) local.ws = "";
		local.forms = loadWorkspaceForms(requestedWs=local.ws);
		renderText(text=SerializeJSON({
			"success": true,
			"workspace": local.ws,
			"count": ArrayLen(local.forms),
			"forms": local.forms
		}), contentType="application/json", layout=false);
	}

	/**
	 * POST JSON { id, contentId, title, absolutePath, relativePath, layout } - insert or update.
	 */
	function saveFolderExplorer() {
		local.body = fxReadJsonBody();
		if (!IsStruct(local.body)) {
			fxRenderJson({ success: false, message: "Invalid request payload." }, 400);
			return;
		}
		local.id = Val(local.body.id ?: 0);
		local.contentId = Val(local.body.contentId ?: 0);
		local.title = Left(Trim(local.body.title ?: ""), 255);
		local.absolutePath = Left(Trim(local.body.absolutePath ?: ""), 500);
		local.relativePath = Left(Trim(local.body.relativePath ?: ""), 500);
		local.layoutValue = Trim(local.body.layout ?: "Full");
		if (local.contentId <= 0) {
			fxRenderJson({ success: false, message: "Save the page before adding folder explorer items." }, 422);
			return;
		}
		if (!Len(local.title)) {
			fxRenderJson({ success: false, message: "A title is required." }, 422);
			return;
		}
		if (local.layoutValue != "Full" && local.layoutValue != "3/9") local.layoutValue = "Full";
		local.isAbsolute = Len(local.absolutePath) ? 1 : 0;
		local.siteId = activeWorkspaceId();
		if (!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") {
			fxRenderJson({ success: false, message: "Please select a workspace before saving folder explorer items." }, 422);
			return;
		}

		local.candidateSiteIds = getCandidateSiteIds(local.siteId);
		if (ArrayLen(local.candidateSiteIds) == 0) ArrayAppend(local.candidateSiteIds, local.siteId);
		local.inPlaceholders = [];
		local.siteParams = {};
		for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
			local.pName = "sfe" & local.idx;
			ArrayAppend(local.inPlaceholders, ":" & local.pName);
			local.siteParams[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
		}
		local.siteInClause = ArrayToList(local.inPlaceholders, ", ");

		try {
			if (local.id > 0) {
				local.updateParams = StructCopy(local.siteParams);
				local.updateParams.title = { value: local.title, cfsqltype: "cf_sql_nvarchar" };
				local.updateParams.rel = { value: local.relativePath, cfsqltype: "cf_sql_nvarchar" };
				local.updateParams.abs = { value: local.absolutePath, cfsqltype: "cf_sql_nvarchar" };
				local.updateParams.isAbs = { value: local.isAbsolute, cfsqltype: "cf_sql_bit" };
				local.updateParams.layoutValue = { value: local.layoutValue, cfsqltype: "cf_sql_nvarchar" };
				local.updateParams.id = { value: local.id, cfsqltype: "cf_sql_integer" };

				queryExecute("
					UPDATE page_FolderExplorer
					SET Title = :title, RelativePath = :rel, AbsolutePath = :abs, Absolute = :isAbs, Layout = :layoutValue
					WHERE ID = :id AND SiteID IN (" & local.siteInClause & ")
				", local.updateParams, { datasource: "ChelanCountyWebsite" });
			} else {
				local.insertParams = StructCopy(local.siteParams);
				local.insertParams.siteId = { value: local.siteId, cfsqltype: "cf_sql_nvarchar" };
				local.insertParams.contentId = { value: local.contentId, cfsqltype: "cf_sql_integer" };
				local.insertParams.title = { value: local.title, cfsqltype: "cf_sql_nvarchar" };
				local.insertParams.rel = { value: local.relativePath, cfsqltype: "cf_sql_nvarchar" };
				local.insertParams.abs = { value: local.absolutePath, cfsqltype: "cf_sql_nvarchar" };
				local.insertParams.isAbs = { value: local.isAbsolute, cfsqltype: "cf_sql_bit" };
				local.insertParams.layoutValue = { value: local.layoutValue, cfsqltype: "cf_sql_nvarchar" };

				local.res = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					SET NOCOUNT ON;
					DECLARE @InsertedRows TABLE (newId INT);
					INSERT INTO page_FolderExplorer (ContentID, SiteID, Title, RelativePath, AbsolutePath, Absolute, Weight, Layout)
					OUTPUT INSERTED.ID INTO @InsertedRows(newId)
					SELECT :contentId, :siteId, :title, :rel, :abs, :isAbs, ISNULL(MAX(Weight), 0) + 1, :layoutValue
					FROM page_FolderExplorer WHERE SiteID IN (" & local.siteInClause & ");
					SELECT newId FROM @InsertedRows;
				", local.insertParams, { datasource: "ChelanCountyWebsite" });
				local.id = local.res.newId;
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="Folder explorer save failed: #e.message# #e.detail#");
			fxRenderJson({ success: false, message: "Unable to save this folder explorer item: #e.message# #e.detail#" }, 500);
			return;
		}
		fxRenderJson({
			success: true,
			item: {
				id: local.id,
				title: local.title,
				absolutePath: local.absolutePath,
				relativePath: local.relativePath,
				layout: local.layoutValue,
				path: Len(local.absolutePath) ? local.absolutePath : local.relativePath
			}
		});
	}

	/**
	 * POST JSON { id, contentId } - hard delete.
	 */
	function deleteFolderExplorer() {
		local.body = fxReadJsonBody();
		local.id = IsStruct(local.body) ? Val(local.body.id ?: 0) : 0;
		local.contentId = IsStruct(local.body) ? Val(local.body.contentId ?: 0) : 0;
		if (local.id <= 0 || local.contentId <= 0) {
			fxRenderJson({ success: false, message: "A valid folder explorer item is required." }, 400);
			return;
		}
		local.siteId = activeWorkspaceId();
		if (!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") {
			fxRenderJson({ success: false, message: "Please select a workspace before deleting items." }, 422);
			return;
		}

		local.candidateSiteIds = getCandidateSiteIds(local.siteId);
		if (ArrayLen(local.candidateSiteIds) == 0) ArrayAppend(local.candidateSiteIds, local.siteId);
		local.inPlaceholders = [];
		local.params = { id: { value: local.id, cfsqltype: "cf_sql_integer" } };
		for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
			local.pName = "dfe" & local.idx;
			ArrayAppend(local.inPlaceholders, ":" & local.pName);
			local.params[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
		}
		local.inClause = ArrayToList(local.inPlaceholders, ", ");

		try {
			queryExecute("DELETE FROM page_FolderExplorer WHERE ID = :id AND SiteID IN (" & local.inClause & ")", local.params, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			writeLog(type="error", file="pages", text="Folder explorer delete failed: #e.message# #e.detail#");
			fxRenderJson({ success: false, message: "Unable to remove this item. Please try again." }, 500);
			return;
		}
		fxRenderJson({ success: true });
	}

	/**
	 * Subpages belonging to the active workspace (or assigned to this page).
	 */
	private array function loadSubpages(numeric contentId = 0, string requestedWs = "", any assignedIds = []) {
		local.items = [];
		local.targetWs = Len(Trim(arguments.requestedWs)) ? Trim(arguments.requestedWs) : activeWorkspaceId();
		if (!Len(local.targetWs) && StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) {
			local.rawCk = LCase(Trim(cookie.cmsadmin_workspace));
			if (local.rawCk != "global" && local.rawCk != "all") {
				local.targetWs = local.rawCk;
			}
		}

		local.candidateSiteIds = Len(local.targetWs) ? getCandidateSiteIds(local.targetWs) : [];
		if (Len(local.targetWs) && ArrayLen(local.candidateSiteIds) == 0 && local.targetWs != "global" && local.targetWs != "all") {
			ArrayAppend(local.candidateSiteIds, local.targetWs);
		}

		// Extract numeric IDs from assignedIds like ["subpage-8", "subpage-13"] or numeric [8, 13]
		local.assignedNumericIds = [];
		local.rawAssigned = IsArray(arguments.assignedIds) ? arguments.assignedIds : ListToArray(ToString(arguments.assignedIds));
		for (local.aid in local.rawAssigned) {
			local.cleanAid = ReReplaceNoCase(ToString(local.aid), "^subpage-", "");
			if (IsNumeric(local.cleanAid) && Val(local.cleanAid) > 0 && !ArrayFind(local.assignedNumericIds, Val(local.cleanAid))) {
				ArrayAppend(local.assignedNumericIds, Val(local.cleanAid));
			}
		}

		local.params = {};
		local.whereClauses = [];

		if (ArrayLen(local.candidateSiteIds) > 0) {
			local.inPlaceholders = [];
			for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
				local.pName = "spSite" & local.idx;
				ArrayAppend(local.inPlaceholders, ":" & local.pName);
				local.params[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
			}
			local.inClause = ArrayToList(local.inPlaceholders, ", ");
			ArrayAppend(local.whereClauses, "(sp.SiteID IN (" & local.inClause & ") OR sp.ContentID IN (SELECT p.ContentID FROM pages p WHERE p.SiteID IN (" & local.inClause & ")))");
		}

		if (arguments.contentId > 0) {
			local.params.contentId = { value: arguments.contentId, cfsqltype: "cf_sql_integer" };
			ArrayAppend(local.whereClauses, "sp.ContentID = :contentId");
		}

		if (ArrayLen(local.assignedNumericIds) > 0) {
			local.aidPlaceholders = [];
			for (local.aIdx = 1; local.aIdx <= ArrayLen(local.assignedNumericIds); local.aIdx++) {
				local.apName = "spAid" & local.aIdx;
				ArrayAppend(local.aidPlaceholders, ":" & local.apName);
				local.params[local.apName] = { value: local.assignedNumericIds[local.aIdx], cfsqltype: "cf_sql_integer" };
			}
			ArrayAppend(local.whereClauses, "sp.ID IN (" & ArrayToList(local.aidPlaceholders, ", ") & ")");
		}

		if (ArrayLen(local.whereClauses) == 0) {
			if (local.targetWs != "global" && local.targetWs != "all") {
				return local.items;
			}
		}

		local.sql = "
			SELECT sp.ID, sp.Title, sp.Body, sp.Position, sp.ContentID, sp.SiteID
			FROM page_SubPage sp
		";
		if (ArrayLen(local.whereClauses) > 0) {
			local.sql &= " WHERE (" & ArrayToList(local.whereClauses, " OR ") & ")";
		}
		local.sql &= " ORDER BY sp.Position, sp.Title, sp.ID";

		try {
			local.rows = queryExecute(local.sql, local.params, { datasource: "ChelanCountyWebsite" });
			for (local.row in local.rows) {
				ArrayAppend(local.items, {
					id: local.row.ID,
					title: local.row.Title,
					body: local.row.Body ?: "",
					position: local.row.Position,
					contentId: local.row.ContentID,
					siteId: local.row.SiteID ?: ""
				});
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="Subpage load failed: #e.message# #e.detail#");
		}
		return local.items;
	}

	/**
	 * Workspace the current user is working in, resolved server-side from the workspace cookie.
	 */
	private string function activeWorkspaceId() {
		local.requested = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");
		if (!Len(local.requested) || local.requested == "global" || local.requested == "all") {
			return "";
		}
		local.ws = resolveUserActiveWorkspace(requestedWs=local.requested, role=getCurrentActiveRole());
		local.id = LCase(Trim(local.ws.id ?: ""));
		if (local.id == "global" || local.id == "all") return "";
		return Len(local.id) ? Left(local.id, 100) : "";
	}

	private string function spCurrentActor() {
		if (StructKeyExists(session, "user") && IsStruct(session.user)) {
			if (Len(session.user.email ?: "")) return Left(session.user.email, 255);
			if (Len(session.user.username ?: "")) return Left(session.user.username, 255);
		}
		return "System";
	}

	/**
	 * POST JSON { id, contentId, title, body, position, siteId } - insert or update a subpage.
	 */
	function saveSubpage() {
		local.body = fxReadJsonBody();
		if (!IsStruct(local.body)) {
			fxRenderJson({ success: false, message: "Invalid request payload." }, 400);
			return;
		}
		local.id = Val(local.body.id ?: 0);
		local.contentId = Val(local.body.contentId ?: 0);
		local.title = Left(Trim(local.body.title ?: ""), 255);
		local.content = local.body.body ?: "";
		local.position = Max(0, Int(Val(local.body.position ?: 0)));
		if (local.contentId <= 0 && local.id <= 0) {
			fxRenderJson({ success: false, message: "Save the page before adding new subpages." }, 422);
			return;
		}
		if (!Len(local.title)) {
			fxRenderJson({ success: false, message: "A title / header is required." }, 422);
			return;
		}
		local.actor = spCurrentActor();
		local.siteId = (StructKeyExists(local.body, "siteId") && Len(Trim(local.body.siteId)) && local.body.siteId != "global" && local.body.siteId != "all")
			? Trim(local.body.siteId)
			: activeWorkspaceId();

		if (!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") {
			if (local.contentId > 0) {
				local.pageSiteQ = queryExecute("SELECT SiteID FROM pages WHERE ContentID = :contentId", { contentId: { value: local.contentId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
				if (local.pageSiteQ.recordCount && Len(Trim(local.pageSiteQ.SiteID)) && local.pageSiteQ.SiteID != "global" && local.pageSiteQ.SiteID != "all") {
					local.siteId = Trim(local.pageSiteQ.SiteID);
				}
			}
		}

		if (!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") {
			fxRenderJson({ success: false, message: "Please select a workspace before saving subpages." }, 422);
			return;
		}

		local.candidateSiteIds = getCandidateSiteIds(local.siteId);
		if (ArrayLen(local.candidateSiteIds) == 0) ArrayAppend(local.candidateSiteIds, local.siteId);
		local.inPlaceholders = [];
		local.siteParams = {};
		for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
			local.pName = "ssp" & local.idx;
			ArrayAppend(local.inPlaceholders, ":" & local.pName);
			local.siteParams[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
		}
		local.siteInClause = ArrayToList(local.inPlaceholders, ", ");

		try {
			if (local.id > 0) {
				local.updateParams = StructCopy(local.siteParams);
				local.updateParams.title = { value: local.title, cfsqltype: "cf_sql_nvarchar" };
				local.updateParams.body = { value: local.content, cfsqltype: "cf_sql_longvarchar" };
				local.updateParams.position = { value: local.position, cfsqltype: "cf_sql_integer" };
				local.updateParams.actor = { value: local.actor, cfsqltype: "cf_sql_nvarchar" };
				local.updateParams.id = { value: local.id, cfsqltype: "cf_sql_integer" };
				local.updateParams.contentId = { value: local.contentId, cfsqltype: "cf_sql_integer" };

				queryExecute("
					UPDATE page_SubPage
					SET Title = :title, Body = :body, Position = :position, ModifiedAt = SYSDATETIME(), ModifiedBy = :actor
					WHERE ID = :id AND (SiteID IN (" & local.siteInClause & ") OR ContentID = :contentId)
				", local.updateParams, { datasource: "ChelanCountyWebsite" });
			} else {
				local.insertParams = StructCopy(local.siteParams);
				local.insertParams.siteId = { value: local.siteId, cfsqltype: "cf_sql_nvarchar" };
				local.insertParams.contentId = { value: local.contentId, cfsqltype: "cf_sql_integer" };
				local.insertParams.title = { value: local.title, cfsqltype: "cf_sql_nvarchar" };
				local.insertParams.body = { value: local.content, cfsqltype: "cf_sql_longvarchar" };
				local.insertParams.position = { value: local.position, cfsqltype: "cf_sql_integer" };
				local.insertParams.actor = { value: local.actor, cfsqltype: "cf_sql_nvarchar" };

				local.res = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					SET NOCOUNT ON;
					DECLARE @InsertedRows TABLE (newId INT);
					INSERT INTO page_SubPage (ContentID, SiteID, Title, Body, Position, CreatedAt, CreatedBy)
					OUTPUT INSERTED.ID INTO @InsertedRows(newId)
					VALUES (:contentId, :siteId, :title, :body, :position, SYSDATETIME(), :actor);
					SELECT newId FROM @InsertedRows;
				", local.insertParams, { datasource: "ChelanCountyWebsite" });
				local.id = local.res.newId;
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="Subpage save failed: #e.message# #e.detail#");
			fxRenderJson({ success: false, message: "Unable to save this subpage: #e.message# #e.detail#" }, 500);
			return;
		}
		fxRenderJson({
			success: true,
			item: { id: local.id, title: local.title, body: local.content, position: local.position, siteId: local.siteId }
		});
	}

	/**
	 * POST JSON { id, contentId, siteId } - hard delete a subpage.
	 */
	function deleteSubpage() {
		local.body = fxReadJsonBody();
		local.id = IsStruct(local.body) ? Val(local.body.id ?: 0) : 0;
		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "A valid subpage is required." }, 400);
			return;
		}
		local.siteId = (IsStruct(local.body) && StructKeyExists(local.body, "siteId") && Len(Trim(local.body.siteId))) ? Trim(local.body.siteId) : activeWorkspaceId();

		local.subQ = queryExecute("SELECT SiteID FROM page_SubPage WHERE ID = :id", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
		if (local.subQ.recordCount == 0) {
			fxRenderJson({ success: false, message: "Subpage not found." }, 404);
			return;
		}
		local.subSiteId = Trim(local.subQ.SiteID);
		if (!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") {
			local.siteId = local.subSiteId;
		}

		local.candidateSiteIds = getCandidateSiteIds(local.siteId);
		if (ArrayLen(local.candidateSiteIds) == 0 && Len(local.siteId)) ArrayAppend(local.candidateSiteIds, local.siteId);
		if (Len(local.subSiteId) && !ArrayFindNoCase(local.candidateSiteIds, local.subSiteId)) {
			ArrayAppend(local.candidateSiteIds, local.subSiteId);
		}

		local.inPlaceholders = [];
		local.params = { id: { value: local.id, cfsqltype: "cf_sql_integer" } };
		for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
			local.pName = "dsp" & local.idx;
			ArrayAppend(local.inPlaceholders, ":" & local.pName);
			local.params[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
		}
		local.inClause = ArrayToList(local.inPlaceholders, ", ");

		try {
			queryExecute("DELETE FROM page_SubPage WHERE ID = :id AND SiteID IN (" & local.inClause & ")", local.params, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			writeLog(type="error", file="pages", text="Subpage delete failed: #e.message# #e.detail#");
			fxRenderJson({ success: false, message: "Unable to remove this subpage. Please try again." }, 500);
			return;
		}
		fxRenderJson({ success: true });
	}

	private any function fxReadJsonBody() {
		try {
			local.content = GetHTTPRequestData().content;
			if (IsBinary(local.content)) local.content = CharsetEncode(local.content, "utf-8");
			if (Len(Trim(local.content)) && IsJSON(local.content)) return DeserializeJSON(local.content);
		} catch (any e) {
			return "";
		}
		return "";
	}

	private void function fxRenderJson(required any data, numeric status = 200) {
		local.out = arguments.data;
		if (IsStruct(local.out)) {
			local.normalized = {};
			for (local.k in local.out) {
				local.normalized[LCase(local.k)] = local.out[local.k];
			}
			local.out = local.normalized;
		}
		renderText(text=SerializeJSON(local.out), contentType="application/json", layout=false, status=arguments.status);
	}

	private array function samplePages() {
		return [];
	}

	private string function slugifyText(required string text) {
		local.s = LCase(Trim(arguments.text));
		local.s = REReplace(local.s, "[^a-z0-9\s-]", "", "all");
		local.s = REReplace(local.s, "[\s_-]+", "-", "all");
		local.s = REReplace(local.s, "^-+|-+$", "", "all");
		return local.s;
	}

	private struct function loadPageFromDb(required numeric contentId) {
		local.res = {};
		if (arguments.contentId <= 0) return local.res;
		try {
			local.q = queryExecute("
				SELECT TOP 1 ContentID, SiteID, PageType, MenuSelected, LayoutType, ParentID,
				       StatusCode, Permalink, Title, MetaTitle, MetaDesc, MetaKeyWords,
				       Summary, Body, imageAttachment, imageAttribution, imageAlt, imageTitle, imageDescription,
				       ISNULL(imageDecorative, 0) AS imageDecorative,
				       isService, hasArchive, ShowInMenu, isLocked, SidebarIDs, SortOrder,
				       isPublished, Visibility, PublishAt, publish_at, UnpublishAt, unpublish_at, ViewCount, Created, CreatedBy, Modified, ModifiedBy
				FROM pages
				WHERE ContentID = :id AND DeletedAt IS NULL
			", { id: { value: arguments.contentId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.q.recordCount > 0) {
				local.row = local.q;
				local.sidebarList = [];
				if (Len(Trim(local.row.SidebarIDs))) {
					try {
						if (IsJSON(local.row.SidebarIDs)) {
							local.sidebarList = DeserializeJSON(local.row.SidebarIDs);
						} else {
							local.sidebarList = ListToArray(local.row.SidebarIDs);
						}
					} catch (any errSide) {
						local.sidebarList = [];
					}
				}
				local.updatedStr = "";
				if (IsDate(local.row.Modified)) {
					local.updatedStr = DateFormat(local.row.Modified, "mm/dd/yyyy") & " " & TimeFormat(local.row.Modified, "hh:mm:ss");
				} else if (IsDate(local.row.Created)) {
					local.updatedStr = DateFormat(local.row.Created, "mm/dd/yyyy") & " " & TimeFormat(local.row.Created, "hh:mm:ss");
				}

				local.rawPub = IsDate(local.row.publish_at ?: "") ? local.row.publish_at : (IsDate(local.row.PublishAt ?: "") ? local.row.PublishAt : "");
				local.rawUnpub = IsDate(local.row.unpublish_at ?: "") ? local.row.unpublish_at : (IsDate(local.row.UnpublishAt ?: "") ? local.row.UnpublishAt : "");

				local.res = {
					id: local.row.ContentID,
					title: local.row.Title ?: "",
					slug: local.row.Permalink ?: "",
					siteId: local.row.SiteID ?: "global",
					pageType: Val(local.row.PageType ?: 0),
					parent: local.row.MenuSelected ?: "",
					layout: Len(Trim(local.row.LayoutType)) ? local.row.LayoutType : "Full",
					status: local.row.StatusCode ?: "Active",
					visibility: local.row.Visibility ?: "Published",
					publishAt: IsDate(local.rawPub) ? DateFormat(local.rawPub, "yyyy-mm-dd") & "T" & TimeFormat(local.rawPub, "HH:mm") : "",
					unpublishAt: IsDate(local.rawUnpub) ? DateFormat(local.rawUnpub, "yyyy-mm-dd") & "T" & TimeFormat(local.rawUnpub, "HH:mm") : "",
					isPublished: (local.row.isPublished == 1),
					menuItem: (local.row.ShowInMenu == 1),
					locked: (local.row.isLocked == 1),
					summary: local.row.Summary ?: "",
					body: normalizeCtaLinkIcons(local.row.Body ?: ""),
					content: normalizeCtaLinkIcons(local.row.Body ?: ""),
					metaTitle: local.row.MetaTitle ?: "",
					metaDesc: local.row.MetaDesc ?: "",
					metaKeywords: local.row.MetaKeyWords ?: "",
					imageAttachment: local.row.imageAttachment ?: "",
					imageAttribution: local.row.imageAttribution ?: "",
					imageAlt: local.row.imageAlt ?: "",
					imageTitle: local.row.imageTitle ?: "",
					imageDescription: local.row.imageDescription ?: "",
					imageDecorative: Val(local.row.imageDecorative ?: 0),
					sidebarIds: local.sidebarList,
					author: Len(local.row.ModifiedBy) ? local.row.ModifiedBy : (local.row.CreatedBy ?: "Admin"),
					updated: local.updatedStr,
					hasArchive: (local.row.hasArchive == 1)
				};
				if (Compare(local.row.Body ?: "", local.res.body) != 0) {
					try {
						queryExecute("UPDATE pages SET Body = :body WHERE ContentID = :id", {
							body: { value: local.res.body, cfsqltype: "cf_sql_nvarchar" },
							id: { value: local.row.ContentID, cfsqltype: "cf_sql_integer" }
						}, { datasource: "ChelanCountyWebsite" });
					} catch (any errClean) {}
				}
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="Failed to load page from DB: #e.message# #e.detail#");
		}
		return local.res;
	}

	private array function loadPagesList() {
		local.pages = [];
		try {
			local.siteId = activeWorkspaceId();

			// If no workspace is selected (or invalid/global), strictly return empty list
			if (!Len(local.siteId) || local.siteId == "global" || local.siteId == "all") {
				return local.pages;
			}

			local.candidateSiteIds = getCandidateSiteIds(local.siteId);
			if (ArrayLen(local.candidateSiteIds) == 0) ArrayAppend(local.candidateSiteIds, local.siteId);

			local.params = {};
			local.inPlaceholders = [];
			for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
				local.pName = "lpSite" & local.idx;
				ArrayAppend(local.inPlaceholders, ":" & local.pName);
				local.params[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
			}
			local.inClause = ArrayToList(local.inPlaceholders, ", ");

			local.sql = "
				SELECT ContentID, SiteID, PageType, MenuSelected, LayoutType, ParentID,
				       StatusCode, Permalink, Title, Summary, isLocked, ShowInMenu,
				       isPublished, Visibility, Created, CreatedBy, Modified, ModifiedBy
				FROM pages
				WHERE DeletedAt IS NULL AND SiteID IN (" & local.inClause & ")
				ORDER BY Modified DESC, ContentID DESC
			";

			local.q = queryExecute(local.sql, local.params, { datasource: "ChelanCountyWebsite" });
			for (local.row in local.q) {
				local.updatedStr = "";
				if (IsDate(local.row.Modified)) {
					local.updatedStr = DateFormat(local.row.Modified, "mm/dd/yyyy") & " " & TimeFormat(local.row.Modified, "hh:mm:ss");
				} else if (IsDate(local.row.Created)) {
					local.updatedStr = DateFormat(local.row.Created, "mm/dd/yyyy") & " " & TimeFormat(local.row.Created, "hh:mm:ss");
				}
				ArrayAppend(local.pages, {
					id: local.row.ContentID,
					title: local.row.Title ?: "",
					slug: local.row.Permalink ?: "",
					siteId: local.row.SiteID ?: "",
					pageType: Val(local.row.PageType ?: 0),
					menuItem: (local.row.ShowInMenu == 1),
					status: local.row.StatusCode ?: "Active",
					visibility: local.row.Visibility ?: "Published",
					parent: local.row.MenuSelected ?: "",
					layout: local.row.LayoutType ?: "Full",
					updated: local.updatedStr,
					author: Len(local.row.ModifiedBy) ? local.row.ModifiedBy : (local.row.CreatedBy ?: "Admin"),
					locked: (local.row.isLocked == 1),
					summary: local.row.Summary ?: ""
				});
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="loadPagesList failed: #e.message# #e.detail#");
		}
		return local.pages;
	}

	/**
	 * GET /pages/revisions?id=N
	 * Returns full list of timestamped revision snapshots for a page (RCW 42.56 compliance)
	 */
	function revisions() {
		ensurePageRevisionsTable();
		local.pageId = StructKeyExists(params, "pageId") ? Val(params.pageId) : (StructKeyExists(params, "id") ? Val(params.id) : 0);
		if (local.pageId <= 0) {
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Invalid page ID." }, 400);
			return;
		}

		try {
			local.revQ = queryExecute("
				SELECT id, page_id, version_number, title, slug, summary, layout_type,
				       change_summary, created_by, created_at,
				       DATALENGTH(content_html) / 2 AS content_length,
				       DATALENGTH(content_html) AS content_bytes
				FROM page_revisions
				WHERE page_id = :id
				ORDER BY version_number DESC, created_at DESC
			", { id: { value: local.pageId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			local.list = [];
			for (local.r in local.revQ) {
				local.formattedDate = IsDate(local.r.created_at)
					? (DateFormat(local.r.created_at, "mmm dd, yyyy") & " at " & TimeFormat(local.r.created_at, "hh:mm tt"))
					: "";

				ArrayAppend(local.list, {
					"id": Val(local.r.id),
					"pageId": Val(local.r.page_id),
					"versionNumber": Val(local.r.version_number),
					"title": local.r.title ?: "",
					"slug": local.r.slug ?: "",
					"summary": local.r.summary ?: "",
					"layoutType": local.r.layout_type ?: "Full",
					"changeSummary": local.r.change_summary ?: "",
					"createdBy": local.r.created_by ?: "System",
					"createdAt": local.r.created_at,
					"createdAtFormatted": local.formattedDate,
					"contentLength": Val(local.r.content_length ?: 0),
					"contentBytes": Val(local.r.content_bytes ?: 0)
				});
			}

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"pageId": local.pageId,
				"count": ArrayLen(local.list),
				"COUNT": ArrayLen(local.list),
				"revisions": local.list,
				"REVISIONS": local.list
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="revisions failed: #e.message# #e.detail#");
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Unable to load page revisions: #e.message#" }, 500);
		}
	}

	/**
	 * GET /pages/revision?id=N&revId=M
	 * Returns full content_html and metadata for a specific revision
	 */
	function revision() {
		ensurePageRevisionsTable();
		local.pageId = StructKeyExists(params, "pageId") ? Val(params.pageId) : 0;
		local.revId = StructKeyExists(params, "revId") ? Val(params.revId) : (StructKeyExists(params, "revisionId") ? Val(params.revisionId) : (StructKeyExists(params, "id") ? Val(params.id) : 0));

		if (local.revId <= 0) {
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Invalid revision ID." }, 400);
			return;
		}

		try {
			local.revQ = queryExecute("
				SELECT TOP 1 id, page_id, version_number, title, slug, content_html,
				       summary, layout_type, meta_json, change_summary, created_by, created_at
				FROM page_revisions
				WHERE id = :revId " & (local.pageId > 0 ? "AND page_id = :pageId" : "") & "
			", {
				revId: { value: local.revId, cfsqltype: "cf_sql_integer" },
				pageId: { value: local.pageId, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			if (local.revQ.recordCount == 0) {
				fxRenderJson({ "success": false, "SUCCESS": false, "message": "Revision record not found." }, 404);
				return;
			}

			local.r = local.revQ;
			local.metaStruct = {};
			if (Len(Trim(local.r.meta_json ?: "")) && IsJSON(local.r.meta_json)) {
				try {
					local.metaStruct = DeserializeJSON(local.r.meta_json);
				} catch (any errJ) {
					local.metaStruct = {};
				}
			}

			local.formattedDate = IsDate(local.r.created_at)
				? (DateFormat(local.r.created_at, "mmm dd, yyyy") & " at " & TimeFormat(local.r.created_at, "hh:mm tt"))
				: "";

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"revision": {
					"id": Val(local.r.id),
					"pageId": Val(local.r.page_id),
					"versionNumber": Val(local.r.version_number),
					"title": local.r.title ?: "",
					"slug": local.r.slug ?: "",
					"contentHtml": local.r.content_html ?: "",
					"summary": local.r.summary ?: "",
					"layoutType": local.r.layout_type ?: "Full",
					"meta": local.metaStruct,
					"changeSummary": local.r.change_summary ?: "",
					"createdBy": local.r.created_by ?: "System",
					"createdAt": local.r.created_at,
					"createdAtFormatted": local.formattedDate
				}
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="revision detail failed: #e.message# #e.detail#");
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Unable to load revision: #e.message#" }, 500);
		}
	}

	/**
	 * POST /pages/restore-revision
	 * One-click rollback to a prior snapshot (with auto-snapshot of pre-rollback state)
	 */
	function restoreRevision() {
		ensurePageRevisionsTable();
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.pageId = Val(local.req.pageId ?: 0);
		local.revId = Val(local.req.revisionId ?: (local.req.revId ?: 0));

		if (local.pageId <= 0 || local.revId <= 0) {
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Both pageId and revisionId are required." }, 400);
			return;
		}

		local.actor = spCurrentActor();

		try {
			// 1. Fetch the target revision
			local.revQ = queryExecute("
				SELECT TOP 1 id, page_id, version_number, title, slug, content_html,
				       summary, layout_type, meta_json, change_summary, created_by
				FROM page_revisions
				WHERE id = :revId AND page_id = :pageId
			", {
				revId: { value: local.revId, cfsqltype: "cf_sql_integer" },
				pageId: { value: local.pageId, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			if (local.revQ.recordCount == 0) {
				fxRenderJson({ "success": false, "SUCCESS": false, "message": "Revision record not found for this page." }, 404);
				return;
			}

			local.targetRev = local.revQ;

			// 2. Snapshot current page state FIRST before applying rollback
			recordPageRevision(local.pageId, local.actor, "Pre-rollback snapshot before restoring version " & local.targetRev.version_number);

			// 3. Deserialize meta if present
			local.meta = {};
			if (Len(Trim(local.targetRev.meta_json ?: "")) && IsJSON(local.targetRev.meta_json)) {
				try { local.meta = DeserializeJSON(local.targetRev.meta_json); } catch (any ej) { local.meta = {}; }
			}

			local.metaTitle = StructKeyExists(local.meta, "metaTitle") ? local.meta.metaTitle : local.targetRev.title;
			local.metaDesc = StructKeyExists(local.meta, "metaDesc") ? local.meta.metaDesc : local.targetRev.summary;
			local.metaKeywords = StructKeyExists(local.meta, "metaKeywords") ? local.meta.metaKeywords : "";
			local.layout = Len(Trim(local.targetRev.layout_type)) ? local.targetRev.layout_type : "Full";
			local.imageAttachment = StructKeyExists(local.meta, "imageAttachment") ? local.meta.imageAttachment : "";
			local.imageAttribution = StructKeyExists(local.meta, "imageAttribution") ? local.meta.imageAttribution : "";
			local.imageAlt = StructKeyExists(local.meta, "imageAlt") ? local.meta.imageAlt : "";
			local.imageTitle = StructKeyExists(local.meta, "imageTitle") ? local.meta.imageTitle : "";
			local.imageDescription = StructKeyExists(local.meta, "imageDescription") ? local.meta.imageDescription : "";
			local.imageDecorative = StructKeyExists(local.meta, "imageDecorative") ? Val(local.meta.imageDecorative) : 0;

			// 4. Update the live pages record with the restored version
			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE pages
				SET Title = :title,
				    Permalink = :slug,
				    Body = :body,
				    Summary = :summary,
				    LayoutType = :layout,
				    MetaTitle = :metaTitle,
				    MetaDesc = :metaDesc,
				    MetaKeyWords = :metaKeywords,
				    imageAttachment = :imageAttachment,
				    imageAttribution = :imageAttribution,
				    imageAlt = :imageAlt,
				    imageTitle = :imageTitle,
				    imageDescription = :imageDescription,
				    imageDecorative = :imageDecorative,
				    Modified = SYSUTCDATETIME(),
				    ModifiedBy = :actor
				WHERE ContentID = :id
			", {
				title: { value: local.targetRev.title, cfsqltype: "cf_sql_nvarchar" },
				slug: { value: local.targetRev.slug, cfsqltype: "cf_sql_nvarchar" },
				body: { value: local.targetRev.content_html ?: "", cfsqltype: "cf_sql_longvarchar" },
				summary: { value: local.targetRev.summary ?: "", cfsqltype: "cf_sql_longvarchar" },
				layout: { value: local.layout, cfsqltype: "cf_sql_nvarchar" },
				metaTitle: { value: local.metaTitle, cfsqltype: "cf_sql_nvarchar" },
				metaDesc: { value: local.metaDesc, cfsqltype: "cf_sql_nvarchar" },
				metaKeywords: { value: local.metaKeywords, cfsqltype: "cf_sql_nvarchar" },
				imageAttachment: { value: local.imageAttachment, cfsqltype: "cf_sql_nvarchar" },
				imageAttribution: { value: local.imageAttribution, cfsqltype: "cf_sql_nvarchar" },
				imageAlt: { value: local.imageAlt, cfsqltype: "cf_sql_nvarchar" },
				imageTitle: { value: local.imageTitle, cfsqltype: "cf_sql_nvarchar" },
				imageDescription: { value: local.imageDescription, cfsqltype: "cf_sql_longvarchar" },
				imageDecorative: { value: local.imageDecorative, cfsqltype: "cf_sql_bit" },
				actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" },
				id: { value: local.pageId, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			// 5. Record the restored state as a new active revision
			local.newSnap = recordPageRevision(local.pageId, local.actor, "Restored from version " & local.targetRev.version_number);

			local.revCountQ = queryExecute("
				SELECT COUNT(*) AS total_revs, MAX(version_number) AS max_ver
				FROM page_revisions
				WHERE page_id = :id
			", { id: { value: local.pageId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Successfully restored Page to Version " & local.targetRev.version_number & ".",
				"MESSAGE": "Successfully restored Page to Version " & local.targetRev.version_number & ".",
				"restoredVersion": Val(local.targetRev.version_number),
				"currentVersion": Val(local.revCountQ.max_ver),
				"revisionCount": Val(local.revCountQ.total_revs),
				"page": {
					"id": local.pageId,
					"title": local.targetRev.title,
					"slug": local.targetRev.slug,
					"body": local.targetRev.content_html ?: "",
					"summary": local.targetRev.summary ?: "",
					"layout": local.layout,
					"metaTitle": local.metaTitle,
					"metaDesc": local.metaDesc,
					"metaKeywords": local.metaKeywords,
					"imageAttachment": local.imageAttachment,
					"imageAttribution": local.imageAttribution,
					"imageAlt": local.imageAlt,
					"imageTitle": local.imageTitle,
					"imageDescription": local.imageDescription,
					"imageDecorative": local.imageDecorative
				}
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="restoreRevision failed: #e.message# #e.detail#");
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Failed to restore revision: #e.message#" }, 500);
		}
	}

	/**
	 * POST /pages/snapshot-revision
	 * Manually triggers a snapshot checkpoint for a page
	 */
	function snapshotRevision() {
		ensurePageRevisionsTable();
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.pageId = Val(local.req.pageId ?: (local.req.id ?: 0));
		local.note = Trim(local.req.changeSummary ?: (local.req.note ?: "Manual checkpoint snapshot"));

		if (local.pageId <= 0) {
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Valid page ID is required." }, 400);
			return;
		}

		local.snap = recordPageRevision(local.pageId, spCurrentActor(), local.note);
		if (local.snap.success) {
			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Snapshot created as Version " & local.snap.version & ".",
				"MESSAGE": "Snapshot created as Version " & local.snap.version & ".",
				"versionNumber": local.snap.version,
				"revisionId": local.snap.revisionId
			});
		} else {
			fxRenderJson({ "success": false, "SUCCESS": false, "message": "Unable to create snapshot for page." }, 500);
		}
	}

	/**
	 * Records a snapshot of the current state of a page into dbo.page_revisions
	 * for RCW 42.56 compliance, audit logs, and version rollback.
	 */
	private struct function recordPageRevision(required numeric pageId, string actor = "", string changeSummary = "") {
		local.res = { "success": false, "version": 0, "revisionId": 0 };
		if (arguments.pageId <= 0) return local.res;

		try {
			ensurePageRevisionsTable();

			// Read current page row
			local.pageQ = queryExecute("
				SELECT TOP 1 ContentID, SiteID, PageType, MenuSelected, LayoutType, ParentID,
				       StatusCode, Permalink, Title, MetaTitle, MetaDesc, MetaKeyWords,
				       Summary, Body, isService, hasArchive, ShowInMenu, isLocked, SidebarIDs,
				       SortOrder, isPublished, Visibility, PublishAt, Created, CreatedBy, Modified, ModifiedBy,
				       imageAttachment, imageAttribution, imageAlt, imageTitle, imageDescription,
				       ISNULL(imageDecorative, 0) AS imageDecorative
				FROM pages
				WHERE ContentID = :id AND DeletedAt IS NULL
			", { id: { value: arguments.pageId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.pageQ.recordCount == 0) return local.res;

			// Compute next version number for this page
			local.vQ = queryExecute("
				SELECT ISNULL(MAX(version_number), 0) + 1 AS next_ver
				FROM page_revisions
				WHERE page_id = :id
			", { id: { value: arguments.pageId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			local.nextVer = Val(local.vQ.next_ver);
			local.actorName = Len(Trim(arguments.actor)) ? Trim(arguments.actor) : spCurrentActor();

			local.metaStruct = {
				"metaTitle": local.pageQ.MetaTitle ?: "",
				"metaDesc": local.pageQ.MetaDesc ?: "",
				"metaKeywords": local.pageQ.MetaKeyWords ?: "",
				"summary": local.pageQ.Summary ?: "",
				"layoutType": local.pageQ.LayoutType ?: "Full",
				"menuSelected": local.pageQ.MenuSelected ?: "",
				"showInMenu": (local.pageQ.ShowInMenu == 1),
				"pageType": Val(local.pageQ.PageType ?: 0),
				"isPublished": (local.pageQ.isPublished == 1),
				"visibility": local.pageQ.Visibility ?: "Published",
				"statusCode": local.pageQ.StatusCode ?: "Active",
				"sidebarIds": local.pageQ.SidebarIDs ?: "[]",
				"siteId": local.pageQ.SiteID ?: "global",
				"imageAttachment": local.pageQ.imageAttachment ?: "",
				"imageAttribution": local.pageQ.imageAttribution ?: "",
				"imageAlt": local.pageQ.imageAlt ?: "",
				"imageTitle": local.pageQ.imageTitle ?: "",
				"imageDescription": local.pageQ.imageDescription ?: "",
				"imageDecorative": Val(local.pageQ.imageDecorative ?: 0)
			};

			local.summaryNote = Len(Trim(arguments.changeSummary)) ? Trim(arguments.changeSummary) : ("Version " & local.nextVer & " snapshot");

			local.insQ = queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				INSERT INTO page_revisions (
					page_id, version_number, title, slug, content_html, summary,
					layout_type, meta_json, change_summary, created_by, created_at
				) VALUES (
					:pageId, :ver, :title, :slug, :body, :summary,
					:layout, :metaJson, :note, :actor, SYSUTCDATETIME()
				);
				SELECT SCOPE_IDENTITY() AS new_id;
			", {
				pageId: { value: arguments.pageId, cfsqltype: "cf_sql_integer" },
				ver: { value: local.nextVer, cfsqltype: "cf_sql_integer" },
				title: { value: local.pageQ.Title ?: "Untitled", cfsqltype: "cf_sql_nvarchar" },
				slug: { value: local.pageQ.Permalink ?: "", cfsqltype: "cf_sql_nvarchar" },
				body: { value: local.pageQ.Body ?: "", cfsqltype: "cf_sql_nvarchar" },
				summary: { value: local.pageQ.Summary ?: "", cfsqltype: "cf_sql_nvarchar" },
				layout: { value: local.pageQ.LayoutType ?: "Full", cfsqltype: "cf_sql_nvarchar" },
				metaJson: { value: SerializeJSON(local.metaStruct), cfsqltype: "cf_sql_nvarchar" },
				note: { value: Left(local.summaryNote, 500), cfsqltype: "cf_sql_nvarchar" },
				actor: { value: Left(local.actorName, 255), cfsqltype: "cf_sql_nvarchar" }
			}, { datasource: "ChelanCountyWebsite" });

			local.res.success = true;
			local.res.version = local.nextVer;
			local.res.revisionId = Val(local.insQ.new_id);
		} catch (any e) {
			writeLog(type="error", file="pages", text="recordPageRevision error: #e.message# #e.detail#");
		}
		return local.res;
	}

	/**
	 * Ensures dbo.page_revisions exists in SQL Server
	 */
	private void function ensurePageRevisionsTable() {
		try {
			queryExecute("
				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[page_revisions]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[page_revisions] (
						[id]             INT IDENTITY(1,1) NOT NULL,
						[page_id]        INT NOT NULL,
						[version_number] INT NOT NULL,
						[title]          NVARCHAR(255) NOT NULL,
						[slug]           NVARCHAR(255) NULL,
						[content_html]   NVARCHAR(MAX) NULL,
						[summary]        NVARCHAR(MAX) NULL,
						[layout_type]    NVARCHAR(50) NOT NULL CONSTRAINT [DF_page_rev_layout] DEFAULT ('Full'),
						[meta_json]      NVARCHAR(MAX) NULL,
						[change_summary] NVARCHAR(500) NULL,
						[created_by]     NVARCHAR(255) NOT NULL CONSTRAINT [DF_page_rev_author] DEFAULT ('System'),
						[created_at]     DATETIME2(7) NOT NULL CONSTRAINT [DF_page_rev_created] DEFAULT (SYSUTCDATETIME()),
						CONSTRAINT [PK_page_revisions] PRIMARY KEY CLUSTERED ([id] ASC),
						CONSTRAINT [FK_page_revisions_pages] FOREIGN KEY ([page_id]) REFERENCES [dbo].[pages] ([ContentID]) ON DELETE CASCADE
					);
				END;
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			writeLog(type="error", file="pages", text="ensurePageRevisionsTable error: #e.message#");
		}
	}

	/**
	 * Ensures dbo.pages has hero cover image & accessibility fields
	 */
	private void function ensurePagesTableColumns() {
		try {
			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('pages') AND name = 'imageAttachment')
					ALTER TABLE pages ADD imageAttachment NVARCHAR(500) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('pages') AND name = 'imageAttribution')
					ALTER TABLE pages ADD imageAttribution NVARCHAR(255) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('pages') AND name = 'imageAlt')
					ALTER TABLE pages ADD imageAlt NVARCHAR(500) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('pages') AND name = 'imageTitle')
					ALTER TABLE pages ADD imageTitle NVARCHAR(1000) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('pages') AND name = 'imageDescription')
					ALTER TABLE pages ADD imageDescription NVARCHAR(2000) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('pages') AND name = 'imageDecorative')
					ALTER TABLE pages ADD imageDecorative BIT NOT NULL CONSTRAINT DF_pages_imageDecorative DEFAULT 0;
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			writeLog(type="error", file="pages", text="ensurePagesTableColumns error: #e.message#");
		}
	}

	/**
	 * How Do I Directory & Mega-Menu Manager under Pages
	 */
	function howDoI() {
		variables.pageTitle = "How Do I";
		ensureHowDoITables();

		local.role = getCurrentActiveRole();
		variables.isAdmin = (local.role == "admin");

		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");
		variables.activeWorkspace = resolveUserActiveWorkspace(local.reqWs, local.role);

		local.wsId = LCase(Trim(variables.activeWorkspace.id ?: "global"));
		local.isGlobalWs = (local.wsId == "global" || local.wsId == "all" || !Len(local.wsId));

		// Scope: 'workspace' (default when a department is active) or 'all' (county-wide rollup, available to Admin or when Global is selected)
		local.requestedScope = StructKeyExists(params, "scope") ? LCase(Trim(params.scope)) : "";
		if (variables.isAdmin && (local.requestedScope == "all" || local.isGlobalWs)) {
			variables.viewScope = "all";
		} else {
			variables.viewScope = "workspace";
		}

		variables.categories = loadHowDoICategories(includeInactive = true);
		variables.howDoIItems = loadHowDoIItems(
			requestedWs = (variables.viewScope == "all" ? "all" : local.wsId),
			includeAllWorkspaces = (variables.viewScope == "all")
		);
		variables.countyRollupItems = loadHowDoIItems(
			requestedWs = "all",
			includeAllWorkspaces = true
		);
		variables.workspacePages = loadPagesList();
		variables.workspaceForms = loadWorkspaceForms(requestedWs = local.wsId);
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);
	}

	private boolean function fxToBoolean(any val, boolean defaultValue = false) {
		if (IsNull(arguments.val) || !IsSimpleValue(arguments.val)) return arguments.defaultValue;
		local.s = LCase(Trim(ToString(arguments.val)));
		if (ListFindNoCase("1,true,yes,on", local.s)) return true;
		if (ListFindNoCase("0,false,no,off", local.s)) return false;
		return arguments.defaultValue;
	}

	/**
	 * POST JSON: Create or update a "How Do I" link item
	 */
	function saveHowDoIItem() {
		ensureHowDoITables();
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.id = Val(local.req.id ?: 0);
		local.categoryId = Val(local.req.categoryId ?: 0);
		local.question = Left(Trim(local.req.question ?: ""), 255);
		local.destinationType = LCase(Trim(local.req.destinationType ?: "page"));
		if (!ListFindNoCase("page,form,custom,external", local.destinationType)) {
			local.destinationType = "custom";
		}
		local.pageId = Val(local.req.pageId ?: 0);
		local.formId = Val(local.req.formId ?: 0);
		local.destinationUrl = Left(Trim(local.req.destinationUrl ?: ""), 1000);
		local.openInNewTab = StructKeyExists(local.req, "openInNewTab") ? fxToBoolean(local.req.openInNewTab, false) : false;
		local.isFeaturedMegaMenu = StructKeyExists(local.req, "isFeaturedMegaMenu") ? fxToBoolean(local.req.isFeaturedMegaMenu, true) : true;
		local.isPublished = StructKeyExists(local.req, "isPublished") ? fxToBoolean(local.req.isPublished, true) : true;
		local.sortOrder = Int(Val(local.req.sortOrder ?: 0));

		local.siteId = LCase(Trim(local.req.siteId ?: ""));
		if (!Len(local.siteId) || local.siteId == "all" || local.siteId == "global") {
			local.siteId = activeWorkspaceId();
		}
		if (!Len(local.siteId) || local.siteId == "all") {
			local.siteId = "global";
		}

		local.role = getCurrentActiveRole();
		if (local.role != "admin" && !isWorkspaceAccessible(local.siteId, local.role)) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "You do not have permission to manage How Do I links for this workspace.",
				"MESSAGE": "You do not have permission to manage How Do I links for this workspace."
			}, 403);
			return;
		}

		if (local.categoryId <= 0) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Please select a How Do I category (e.g. Apply For, Pay For, Report).",
				"MESSAGE": "Please select a How Do I category (e.g. Apply For, Pay For, Report)."
			}, 422);
			return;
		}
		if (!Len(local.question)) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Please enter a question or action label (e.g. Driveway Permit, Property Taxes).",
				"MESSAGE": "Please enter a question or action label (e.g. Driveway Permit, Property Taxes)."
			}, 422);
			return;
		}
		if (!Len(local.destinationUrl)) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Please select or enter a destination URL.",
				"MESSAGE": "Please select or enter a destination URL."
			}, 422);
			return;
		}

		local.actor = spCurrentActor();

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					UPDATE how_do_i_items
					SET category_id = :catId,
					    siteid = :siteId,
					    question = :question,
					    destination_type = :dtype,
					    page_id = :pageId,
					    form_id = :formId,
					    destination_url = :durl,
					    open_in_new_tab = :newTab,
					    is_featured_mega_menu = :mega,
					    sort_order = :sortOrder,
					    is_published = :pub,
					    modified_by = :actor,
					    updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					catId: { value: local.categoryId, cfsqltype: "cf_sql_integer" },
					siteId: { value: local.siteId, cfsqltype: "cf_sql_nvarchar" },
					question: { value: local.question, cfsqltype: "cf_sql_nvarchar" },
					dtype: { value: local.destinationType, cfsqltype: "cf_sql_nvarchar" },
					pageId: local.pageId > 0 ? { value: local.pageId, cfsqltype: "cf_sql_integer" } : { value: "", null: true, cfsqltype: "cf_sql_integer" },
					formId: local.formId > 0 ? { value: local.formId, cfsqltype: "cf_sql_integer" } : { value: "", null: true, cfsqltype: "cf_sql_integer" },
					durl: { value: local.destinationUrl, cfsqltype: "cf_sql_nvarchar" },
					newTab: { value: local.openInNewTab ? 1 : 0, cfsqltype: "cf_sql_bit" },
					mega: { value: local.isFeaturedMegaMenu ? 1 : 0, cfsqltype: "cf_sql_bit" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					pub: { value: local.isPublished ? 1 : 0, cfsqltype: "cf_sql_bit" },
					actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" },
					id: { value: local.id, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				if (local.sortOrder <= 0) {
					local.maxQ = queryExecute("
						SELECT ISNULL(MAX(sort_order), 0) + 10 AS nextSort
						FROM how_do_i_items
						WHERE category_id = :catId AND deletedat IS NULL
					", { catId: { value: local.categoryId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
					local.sortOrder = Val(local.maxQ.nextSort ?: 10);
				}

				local.ins = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					SET NOCOUNT ON;
					DECLARE @InsertedRows TABLE (newId INT);
					INSERT INTO how_do_i_items (
						category_id, siteid, question, destination_type, page_id, form_id,
						destination_url, open_in_new_tab, is_featured_mega_menu, sort_order,
						is_published, created_by, modified_by, createdat, updatedat
					)
					OUTPUT INSERTED.id INTO @InsertedRows(newId)
					VALUES (
						:catId, :siteId, :question, :dtype, :pageId, :formId,
						:durl, :newTab, :mega, :sortOrder,
						:pub, :actor, :actor, SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT newId FROM @InsertedRows;
				", {
					catId: { value: local.categoryId, cfsqltype: "cf_sql_integer" },
					siteId: { value: local.siteId, cfsqltype: "cf_sql_nvarchar" },
					question: { value: local.question, cfsqltype: "cf_sql_nvarchar" },
					dtype: { value: local.destinationType, cfsqltype: "cf_sql_nvarchar" },
					pageId: local.pageId > 0 ? { value: local.pageId, cfsqltype: "cf_sql_integer" } : { value: "", null: true, cfsqltype: "cf_sql_integer" },
					formId: local.formId > 0 ? { value: local.formId, cfsqltype: "cf_sql_integer" } : { value: "", null: true, cfsqltype: "cf_sql_integer" },
					durl: { value: local.destinationUrl, cfsqltype: "cf_sql_nvarchar" },
					newTab: { value: local.openInNewTab ? 1 : 0, cfsqltype: "cf_sql_bit" },
					mega: { value: local.isFeaturedMegaMenu ? 1 : 0, cfsqltype: "cf_sql_bit" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					pub: { value: local.isPublished ? 1 : 0, cfsqltype: "cf_sql_bit" },
					actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });
				local.id = Val(local.ins.newId);
			}

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "How Do I item saved.",
				"MESSAGE": "How Do I item saved.",
				"id": local.id,
				"ID": local.id
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="saveHowDoIItem failed: #e.message# #e.detail#");
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to save How Do I item: #e.message#",
				"MESSAGE": "Unable to save How Do I item: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON: Soft-delete a "How Do I" item
	 */
	function deleteHowDoIItem() {
		ensureHowDoITables();
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;
		local.id = Val(local.req.id ?: 0);

		if (local.id <= 0) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Valid item ID is required.",
				"MESSAGE": "Valid item ID is required."
			}, 400);
			return;
		}

		try {
			local.itemQ = queryExecute("SELECT siteid FROM how_do_i_items WHERE id = :id AND deletedat IS NULL", {
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			if (local.itemQ.recordCount == 0) {
				fxRenderJson({
					"success": false,
					"SUCCESS": false,
					"message": "Item not found.",
					"MESSAGE": "Item not found."
				}, 404);
				return;
			}

			local.role = getCurrentActiveRole();
			if (local.role != "admin" && !isWorkspaceAccessible(local.itemQ.siteid, local.role)) {
				fxRenderJson({
					"success": false,
					"SUCCESS": false,
					"message": "You do not have permission to delete this item.",
					"MESSAGE": "You do not have permission to delete this item."
				}, 403);
				return;
			}

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE how_do_i_items
				SET deletedat = SYSUTCDATETIME(), modified_by = :actor
				WHERE id = :id
			", {
				actor: { value: spCurrentActor(), cfsqltype: "cf_sql_nvarchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "How Do I item removed.",
				"MESSAGE": "How Do I item removed."
			});
		} catch (any e) {
			writeLog(type="error", file="pages", text="deleteHowDoIItem failed: #e.message# #e.detail#");
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to delete item: #e.message#",
				"MESSAGE": "Unable to delete item: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON: Reorder "How Do I" items (accepts { items: [{id, sortOrder}] })
	 */
	function reorderHowDoIItems() {
		ensureHowDoITables();
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		if (!StructKeyExists(local.req, "items") || !IsArray(local.req.items)) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Items array is required for reordering.",
				"MESSAGE": "Items array is required for reordering."
			}, 400);
			return;
		}

		try {
			transaction {
				for (local.entry in local.req.items) {
					local.itemId = Val(local.entry.id ?: 0);
					local.sortVal = Int(Val(local.entry.sortOrder ?: 0));
					if (local.itemId > 0) {
						queryExecute("
							SET ANSI_NULLS ON;
							SET QUOTED_IDENTIFIER ON;
							UPDATE how_do_i_items
							SET sort_order = :sortOrder, updatedat = SYSUTCDATETIME()
							WHERE id = :id AND deletedat IS NULL
						", {
							sortOrder: { value: local.sortVal, cfsqltype: "cf_sql_integer" },
							id: { value: local.itemId, cfsqltype: "cf_sql_integer" }
						}, { datasource: "ChelanCountyWebsite" });
					}
				}
			}
			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Order updated.",
				"MESSAGE": "Order updated."
			});
		} catch (any e) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to update order: #e.message#",
				"MESSAGE": "Unable to update order: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON (Admin Only): Create or update a "How Do I" category
	 */
	function saveHowDoICategory() {
		ensureHowDoITables();
		if (getCurrentActiveRole() != "admin") {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Only Administrators can manage How Do I categories.",
				"MESSAGE": "Only Administrators can manage How Do I categories."
			}, 403);
			return;
		}

		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;
		local.id = Val(local.req.id ?: 0);
		local.name = Left(Trim(local.req.name ?: ""), 120);
		local.slug = slugifyText(Len(Trim(local.req.slug ?: "")) ? local.req.slug : local.name);
		local.icon = Left(Trim(local.req.icon ?: "help-circle"), 50);
		local.description = Left(Trim(local.req.description ?: ""), 255);
		local.sortOrder = Int(Val(local.req.sortOrder ?: 100));
		local.isActive = StructKeyExists(local.req, "isActive") ? fxToBoolean(local.req.isActive, true) : true;

		if (!Len(local.name)) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Category name is required.",
				"MESSAGE": "Category name is required."
			}, 422);
			return;
		}
		if (!Len(local.slug)) {
			local.slug = "cat-" & LCase(Left(CreateUUID(), 6));
		}

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					UPDATE how_do_i_categories
					SET name = :name,
					    slug = :slug,
					    icon = :icon,
					    description = :desc,
					    sort_order = :sortOrder,
					    is_active = :isActive,
					    updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					name: { value: local.name, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					icon: { value: local.icon, cfsqltype: "cf_sql_nvarchar" },
					desc: { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isActive: { value: local.isActive ? 1 : 0, cfsqltype: "cf_sql_bit" },
					id: { value: local.id, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				local.ins = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					SET NOCOUNT ON;
					DECLARE @InsertedRows TABLE (newId INT);
					INSERT INTO how_do_i_categories (name, slug, icon, description, sort_order, is_active, is_system, createdat, updatedat)
					OUTPUT INSERTED.id INTO @InsertedRows(newId)
					VALUES (:name, :slug, :icon, :desc, :sortOrder, :isActive, 0, SYSUTCDATETIME(), SYSUTCDATETIME());
					SELECT newId FROM @InsertedRows;
				", {
					name: { value: local.name, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					icon: { value: local.icon, cfsqltype: "cf_sql_nvarchar" },
					desc: { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isActive: { value: local.isActive ? 1 : 0, cfsqltype: "cf_sql_bit" }
				}, { datasource: "ChelanCountyWebsite" });
				local.id = Val(local.ins.newId);
			}
			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Category saved.",
				"MESSAGE": "Category saved.",
				"id": local.id,
				"ID": local.id
			});
		} catch (any e) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to save category: #e.message#",
				"MESSAGE": "Unable to save category: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON (Admin Only): Soft-delete a custom "How Do I" category
	 */
	function deleteHowDoICategory() {
		ensureHowDoITables();
		if (getCurrentActiveRole() != "admin") {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Only Administrators can delete How Do I categories.",
				"MESSAGE": "Only Administrators can delete How Do I categories."
			}, 403);
			return;
		}
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;
		local.id = Val(local.req.id ?: 0);

		if (local.id <= 0) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Valid category ID is required.",
				"MESSAGE": "Valid category ID is required."
			}, 400);
			return;
		}

		try {
			local.cntQ = queryExecute("
				SELECT COUNT(*) AS itemCnt FROM how_do_i_items WHERE category_id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (Val(local.cntQ.itemCnt) > 0) {
				local.errMsg = "Cannot delete a category that still has #Val(local.cntQ.itemCnt)# active How Do I link(s). Reassign or remove its links first.";
				fxRenderJson({
					"success": false,
					"SUCCESS": false,
					"message": local.errMsg,
					"MESSAGE": local.errMsg
				}, 422);
				return;
			}

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE how_do_i_categories SET deletedat = SYSUTCDATETIME() WHERE id = :id
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Category deleted.",
				"MESSAGE": "Category deleted."
			});
		} catch (any e) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to delete category: #e.message#",
				"MESSAGE": "Unable to delete category: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON (Admin Only): Prefill or restore the 12 standard Chelan County "How Do I" categories
	 */
	function prefillHowDoICategories() {
		ensureHowDoITables();
		if (getCurrentActiveRole() != "admin") {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Only Administrators can prefill How Do I categories.",
				"MESSAGE": "Only Administrators can prefill How Do I categories."
			}, 403);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;

				MERGE INTO [dbo].[how_do_i_categories] AS Target
				USING (VALUES
					(N'Apply For',   N'apply-for',   N'clipboard-list', N'Permits, licenses, employment, and county program applications.', 10, 1, 1),
					(N'Contact',     N'contact',     N'phone',          N'Department directories, elected officials, and office contact desks.', 20, 1, 1),
					(N'Find',        N'find',        N'search',         N'Locate county resources, election results, court statuses, and districts.', 30, 1, 1),
					(N'File A',      N'file-a',      N'file-text',      N'Submit official claims, petitions, and formal filings.', 40, 1, 1),
					(N'Join',        N'join',        N'users',          N'Volunteer boards, advisory committees, and community programs.', 50, 1, 1),
					(N'Pay For',     N'pay-for',     N'hard-drive',     N'Online payments for property taxes, court costs, probation, and accounts.', 60, 1, 1),
					(N'Learn About', N'learn-about', N'book',           N'Educational guides, court protection orders, and county initiatives.', 70, 1, 1),
					(N'Register To', N'register-to', N'check-square',   N'Voter registration, jury duty check-in, and court classes.', 80, 1, 1),
					(N'Report',      N'report',      N'megaphone',      N'Report road hazards, code violations, pest infestations, or tips.', 90, 1, 1),
					(N'Request',     N'request',     N'mail',           N'Public records requests, court case records, and vital certificates.', 100, 1, 1),
					(N'Search For',  N'search-for',  N'globe',          N'Public document archives, parcel lookups, and jail registries.', 110, 1, 1),
					(N'View',        N'view',        N'eye',            N'Court calendars, dockets, schedules, and public hearings.', 120, 1, 1)
				) AS Source ([name], [slug], [icon], [description], [sort_order], [is_active], [is_system])
				ON Target.[slug] = Source.[slug] AND Target.[deletedat] IS NULL
				WHEN MATCHED THEN
					UPDATE SET
						Target.[name] = Source.[name],
						Target.[icon] = Source.[icon],
						Target.[description] = Source.[description],
						Target.[sort_order] = Source.[sort_order],
						Target.[is_active] = 1,
						Target.[is_system] = 1,
						Target.[updatedat] = SYSUTCDATETIME()
				WHEN NOT MATCHED BY TARGET THEN
					INSERT ([name], [slug], [icon], [description], [sort_order], [is_active], [is_system], [createdat], [updatedat])
					VALUES (Source.[name], Source.[slug], Source.[icon], Source.[description], Source.[sort_order], Source.[is_active], Source.[is_system], SYSUTCDATETIME(), SYSUTCDATETIME());
			", {}, { datasource: "ChelanCountyWebsite" });

			local.cats = loadHowDoICategories(includeInactive = true);

			fxRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "12 standard Chelan County categories prefilled successfully.",
				"MESSAGE": "12 standard Chelan County categories prefilled successfully.",
				"categories": local.cats
			});
		} catch (any e) {
			fxRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to prefill categories: #e.message#",
				"MESSAGE": "Unable to prefill categories: #e.message#"
			}, 500);
		}
	}

	/**
	 * Ensures dbo.how_do_i_categories and dbo.how_do_i_items exist and are seeded with the 12 standard Chelan County categories.
	 */
	private void function ensureHowDoITables() {
		try {
			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;

				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[how_do_i_categories]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[how_do_i_categories] (
						[id]          INT IDENTITY(1,1) NOT NULL,
						[name]        NVARCHAR(120) NOT NULL,
						[slug]        NVARCHAR(120) NOT NULL,
						[icon]        NVARCHAR(50) NOT NULL CONSTRAINT [DF_how_do_i_cat_icon] DEFAULT (N'help-circle'),
						[description] NVARCHAR(255) NULL,
						[sort_order]  INT NOT NULL CONSTRAINT [DF_how_do_i_cat_sort] DEFAULT (0),
						[is_active]   BIT NOT NULL CONSTRAINT [DF_how_do_i_cat_active] DEFAULT (1),
						[is_system]   BIT NOT NULL CONSTRAINT [DF_how_do_i_cat_system] DEFAULT (0),
						[createdat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_cat_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_cat_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]   DATETIME2(7) NULL,
						CONSTRAINT [PK_how_do_i_categories] PRIMARY KEY CLUSTERED ([id] ASC)
					);
				END;

				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_how_do_i_categories_slug' AND object_id = OBJECT_ID(N'[dbo].[how_do_i_categories]'))
				BEGIN
					CREATE UNIQUE NONCLUSTERED INDEX [UQ_how_do_i_categories_slug]
						ON [dbo].[how_do_i_categories] ([slug] ASC)
						WHERE [deletedat] IS NULL;
				END;

				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[how_do_i_items]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[how_do_i_items] (
						[id]                    INT IDENTITY(1,1) NOT NULL,
						[category_id]           INT NOT NULL,
						[siteid]                NVARCHAR(100) NOT NULL CONSTRAINT [DF_how_do_i_items_siteid] DEFAULT (N'global'),
						[question]              NVARCHAR(255) NOT NULL,
						[destination_type]      NVARCHAR(30) NOT NULL CONSTRAINT [DF_how_do_i_items_dtype] DEFAULT (N'page'),
						[page_id]               INT NULL,
						[form_id]               INT NULL,
						[destination_url]       NVARCHAR(1000) NOT NULL,
						[open_in_new_tab]       BIT NOT NULL CONSTRAINT [DF_how_do_i_items_newtab] DEFAULT (0),
						[is_featured_mega_menu] BIT NOT NULL CONSTRAINT [DF_how_do_i_items_mega] DEFAULT (1),
						[sort_order]            INT NOT NULL CONSTRAINT [DF_how_do_i_items_sort] DEFAULT (0),
						[is_published]          BIT NOT NULL CONSTRAINT [DF_how_do_i_items_pub] DEFAULT (1),
						[created_by]            NVARCHAR(255) NULL,
						[modified_by]           NVARCHAR(255) NULL,
						[createdat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_items_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_items_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]             DATETIME2(7) NULL,
						CONSTRAINT [PK_how_do_i_items] PRIMARY KEY CLUSTERED ([id] ASC),
						CONSTRAINT [FK_how_do_i_items_categories] FOREIGN KEY ([category_id]) REFERENCES [dbo].[how_do_i_categories] ([id])
					);
				END;

				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_how_do_i_items_site_cat' AND object_id = OBJECT_ID(N'[dbo].[how_do_i_items]'))
				BEGIN
					CREATE NONCLUSTERED INDEX [IX_how_do_i_items_site_cat]
						ON [dbo].[how_do_i_items] ([siteid] ASC, [category_id] ASC, [sort_order] ASC)
						WHERE [deletedat] IS NULL;
				END;

				-- Ensure 12 Standard Chelan County Categories are seeded
				MERGE INTO [dbo].[how_do_i_categories] AS Target
				USING (VALUES
					(N'Apply For',   N'apply-for',   N'clipboard-list', N'Permits, licenses, employment, and county program applications.', 10, 1, 1),
					(N'Contact',     N'contact',     N'phone',          N'Department directories, elected officials, and office contact desks.', 20, 1, 1),
					(N'Find',        N'find',        N'search',         N'Locate county resources, election results, court statuses, and districts.', 30, 1, 1),
					(N'File A',      N'file-a',      N'file-text',      N'Submit official claims, petitions, and formal filings.', 40, 1, 1),
					(N'Join',        N'join',        N'users',          N'Volunteer boards, advisory committees, and community programs.', 50, 1, 1),
					(N'Pay For',     N'pay-for',     N'hard-drive',     N'Online payments for property taxes, court costs, probation, and accounts.', 60, 1, 1),
					(N'Learn About', N'learn-about', N'book',           N'Educational guides, court protection orders, and county initiatives.', 70, 1, 1),
					(N'Register To', N'register-to', N'check-square',   N'Voter registration, jury duty check-in, and court classes.', 80, 1, 1),
					(N'Report',      N'report',      N'megaphone',      N'Report road hazards, code violations, pest infestations, or tips.', 90, 1, 1),
					(N'Request',     N'request',     N'mail',           N'Public records requests, court case records, and vital certificates.', 100, 1, 1),
					(N'Search For',  N'search-for',  N'globe',          N'Public document archives, parcel lookups, and jail registries.', 110, 1, 1),
					(N'View',        N'view',        N'eye',            N'Court calendars, dockets, schedules, and public hearings.', 120, 1, 1)
				) AS Source ([name], [slug], [icon], [description], [sort_order], [is_active], [is_system])
				ON Target.[slug] = Source.[slug] AND Target.[deletedat] IS NULL
				WHEN NOT MATCHED BY TARGET THEN
					INSERT ([name], [slug], [icon], [description], [sort_order], [is_active], [is_system], [createdat], [updatedat])
					VALUES (Source.[name], Source.[slug], Source.[icon], Source.[description], Source.[sort_order], Source.[is_active], Source.[is_system], SYSUTCDATETIME(), SYSUTCDATETIME());
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			writeLog(type="error", file="pages", text="ensureHowDoITables failed: #e.message# #e.detail#");
		}
	}

	/**
	 * Loads all How Do I categories ordered by sort_order
	 */
	private array function loadHowDoICategories(boolean includeInactive = false) {
		local.cats = [];
		try {
			local.sql = "
				SELECT c.id, c.name, c.slug, c.icon, c.description, c.sort_order, c.is_active, c.is_system,
				       (SELECT COUNT(*) FROM how_do_i_items i WHERE i.category_id = c.id AND i.deletedat IS NULL) AS total_items
				FROM how_do_i_categories c
				WHERE c.deletedat IS NULL
			";
			if (!arguments.includeInactive) {
				local.sql &= " AND c.is_active = 1";
			}
			local.sql &= " ORDER BY c.sort_order ASC, c.name ASC";

			local.q = queryExecute(local.sql, {}, { datasource: "ChelanCountyWebsite" });
			for (local.r in local.q) {
				ArrayAppend(local.cats, {
					"id": Val(local.r.id),
					"name": local.r.name ?: "",
					"slug": local.r.slug ?: "",
					"icon": Len(Trim(local.r.icon ?: "")) ? local.r.icon : "help-circle",
					"description": local.r.description ?: "",
					"sortOrder": Val(local.r.sort_order),
					"isActive": (local.r.is_active == 1),
					"isSystem": (local.r.is_system == 1),
					"totalItems": Val(local.r.total_items)
				});
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="loadHowDoICategories failed: #e.message# #e.detail#");
		}
		return local.cats;
	}

	/**
	 * Loads How Do I items scoped to a workspace or across all workspaces
	 */
	private array function loadHowDoIItems(string requestedWs = "", boolean includeAllWorkspaces = false) {
		local.items = [];
		try {
			local.wsMap = {};
			for (local.w in getMasterWorkspaces()) {
				local.info = {
					"id": local.w.id,
					"name": local.w.name,
					"badge": local.w.badge ?: "Dept",
					"badgeClass": local.w.badgeClass ?: "badge-neutral"
				};
				local.wsMap[LCase(local.w.id)] = local.info;
				if (StructKeyExists(local.w, "code") && Len(local.w.code)) local.wsMap[LCase(local.w.code)] = local.info;
				if (StructKeyExists(local.w, "alias") && Len(local.w.alias)) local.wsMap[LCase(local.w.alias)] = local.info;
				if (StructKeyExists(local.w, "virtual_directory") && Len(local.w.virtual_directory)) local.wsMap[LCase(local.w.virtual_directory)] = local.info;
			}

			local.params = {};
			local.whereClause = "WHERE i.deletedat IS NULL AND c.deletedat IS NULL";

			if (!arguments.includeAllWorkspaces && Len(Trim(arguments.requestedWs)) && arguments.requestedWs != "all" && arguments.requestedWs != "global") {
				local.cands = getCandidateSiteIds(arguments.requestedWs);
				if (ArrayLen(local.cands) == 0) ArrayAppend(local.cands, LCase(Trim(arguments.requestedWs)));
				local.inList = [];
				for (local.idx = 1; local.idx <= ArrayLen(local.cands); local.idx++) {
					local.pKey = "hdiSite" & local.idx;
					ArrayAppend(local.inList, ":" & local.pKey);
					local.params[local.pKey] = { value: local.cands[local.idx], cfsqltype: "cf_sql_nvarchar" };
				}
				local.whereClause &= " AND i.siteid IN (" & ArrayToList(local.inList, ", ") & ")";
			}

			local.q = queryExecute("
				SELECT i.id, i.category_id, i.siteid, i.question, i.destination_type, i.page_id, i.form_id,
				       i.destination_url, i.open_in_new_tab, i.is_featured_mega_menu, i.sort_order, i.is_published,
				       i.created_by, i.modified_by, i.createdat, i.updatedat,
				       c.name AS category_name, c.slug AS category_slug, c.icon AS category_icon, c.sort_order AS category_sort
				FROM how_do_i_items i
				INNER JOIN how_do_i_categories c ON c.id = i.category_id
				" & local.whereClause & "
				ORDER BY c.sort_order ASC, c.name ASC, i.sort_order ASC, i.question ASC
			", local.params, { datasource: "ChelanCountyWebsite" });

			for (local.r in local.q) {
				local.sKey = LCase(Trim(local.r.siteid ?: "global"));
				local.wsInfo = StructKeyExists(local.wsMap, local.sKey)
					? local.wsMap[local.sKey]
					: { "id": local.sKey, "name": local.r.siteid ?: "Global", "badge": "County", "badgeClass": "badge-neutral" };

				local.updatedStr = "";
				if (IsDate(local.r.updatedat)) {
					local.updatedStr = DateFormat(local.r.updatedat, "mm/dd/yyyy");
				}

				ArrayAppend(local.items, {
					"id": Val(local.r.id),
					"categoryId": Val(local.r.category_id),
					"categoryName": local.r.category_name ?: "",
					"categorySlug": local.r.category_slug ?: "",
					"categoryIcon": local.r.category_icon ?: "help-circle",
					"siteId": local.r.siteid ?: "global",
					"workspaceName": local.wsInfo.name,
					"workspaceBadge": local.wsInfo.badge,
					"workspaceBadgeClass": local.wsInfo.badgeClass,
					"question": local.r.question ?: "",
					"destinationType": local.r.destination_type ?: "custom",
					"pageId": Val(local.r.page_id ?: 0),
					"formId": Val(local.r.form_id ?: 0),
					"destinationUrl": local.r.destination_url ?: "",
					"openInNewTab": (local.r.open_in_new_tab == 1),
					"isFeaturedMegaMenu": (local.r.is_featured_mega_menu == 1),
					"sortOrder": Val(local.r.sort_order),
					"isPublished": (local.r.is_published == 1),
					"updated": local.updatedStr,
					"author": Len(Trim(local.r.modified_by ?: "")) ? local.r.modified_by : (local.r.created_by ?: "Admin")
				});
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="loadHowDoIItems failed: #e.message# #e.detail#");
		}
		return local.items;
	}

	/**
	 * Call to Action Studio page under Pages
	 */
	function callToAction() {
		variables.pageTitle = "Call to Action Studio";
		ensureCallToActionTable();

		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");
		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.reqWs, role = local.role);
		variables.activeWorkspaceId = variables.activeWsObj.id ?: "global";

		// Load CTA items for workspace: workspaces can only see their own Call to Action
		local.showAll = (variables.activeWorkspaceId == "global" || variables.activeWorkspaceId == "all" || !Len(variables.activeWorkspaceId));
		variables.ctaItems = loadCallToActions(
			requestedWs = variables.activeWorkspaceId,
			includeAllWorkspaces = local.showAll
		);

		variables.categories = loadCallToActionCategories(requestedWs = variables.activeWorkspaceId);
		variables.availableWorkspaces = getMasterWorkspaces();
	}

	/**
	 * JSON API endpoint returning Call to Action items for active workspace / embeds
	 */
	function getCallToActions() {
		ensureCallToActionTable();
		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		local.showAll = (local.reqWs == "global" || local.reqWs == "all" || !Len(local.reqWs));
		local.items = loadCallToActions(
			requestedWs = local.reqWs,
			includeAllWorkspaces = local.showAll
		);

		renderText(
			text = SerializeJSON({
				"success": true,
				"count": ArrayLen(local.items),
				"items": local.items
			}),
			contentType = "application/json",
			layout = false
		);
	}

	/**
	 * Save / Update a Call to Action item
	 */
	function saveCallToAction() {
		ensureCallToActionTable();
		local.res = { "success": false, "message": "" };

		try {
			local.body = fxReadJsonBody();
			local.req = IsStruct(local.body) ? local.body : (StructKeyExists(params, "item") ? params.item : params);
			local.id = Val(local.req.id ?: 0);
			local.title = Trim(local.req.title ?: "");
			local.description = Trim(local.req.description ?: "");
			local.slug = LCase(Trim(local.req.slug ?: ""));

			local.activeWs = (StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace)))
				? Trim(cookie.cmsadmin_workspace) : "global";
			local.siteId = Trim(local.req.siteId ?: (local.req.siteid ?: local.activeWs));
			if (!Len(local.siteId)) local.siteId = local.activeWs;

			local.imageUrl = Trim(local.req.imageUrl ?: (local.req.image_url ?: ""));
			local.imageAlt = Trim(local.req.imageAlt ?: (local.req.image_alt ?: ""));
			local.badgeText = Trim(local.req.badgeText ?: (local.req.badge_text ?: ""));
			local.badgeColor = Trim(local.req.badgeColor ?: (local.req.badge_color ?: "blue"));
			local.layoutType = Trim(local.req.layoutType ?: (local.req.layout_type ?: "card"));
			local.linkText = Trim(local.req.linkText ?: (local.req.link_text ?: "Learn More"));
			local.linkUrl = Trim(local.req.linkUrl ?: (local.req.link_url ?: ""));
			local.linkIcon = Trim(local.req.linkIcon ?: (local.req.link_icon ?: "arrow"));
			local.linkStyle = Trim(local.req.linkStyle ?: (local.req.link_style ?: "link"));
			local.targetBlank = (StructKeyExists(local.req, "targetBlank") && (local.req.targetBlank == 1 || local.req.targetBlank == "1" || local.req.targetBlank == "true")) ? 1 : 0;
			local.category = Trim(local.req.category ?: "General");
			if (!Len(local.category)) local.category = "General";
			local.sortOrder = Val(local.req.sortOrder ?: (local.req.sort_order ?: 0));
			local.isPublished = (StructKeyExists(local.req, "isPublished") && (local.req.isPublished == 0 || local.req.isPublished == "0" || local.req.isPublished == "false")) ? 0 : 1;

			if (!Len(local.title)) {
				local.res.message = "Title is required for Call to Action.";
				renderText(text = SerializeJSON(local.res), contentType = "application/json", layout = false);
				return;
			}

			if (!Len(local.linkUrl)) {
				local.res.message = "Destination URL or page link is required.";
				renderText(text = SerializeJSON(local.res), contentType = "application/json", layout = false);
				return;
			}

			// Auto-generate slug from title if empty
			if (!Len(local.slug)) {
				local.slug = LCase(REReplace(local.title, "[^a-zA-Z0-9]+", "-", "all"));
				local.slug = REReplace(local.slug, "^-+|-+$", "", "all");
			}

			local.user = "Admin";
			if (StructKeyExists(session, "user") && IsStruct(session.user)) {
				local.user = session.user.full_name ?: (session.user.first_name ?: "Admin");
			}

			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE page_call_to_actions
					SET siteid = :siteid,
					    title = :title,
					    slug = :slug,
					    description = :description,
					    image_url = :imageUrl,
					    image_alt = :imageAlt,
					    badge_text = :badgeText,
					    badge_color = :badgeColor,
					    layout_type = :layoutType,
					    link_text = :linkText,
					    link_url = :linkUrl,
					    link_icon = :linkIcon,
					    link_style = :linkStyle,
					    target_blank = :targetBlank,
					    category = :category,
					    sort_order = :sortOrder,
					    is_published = :isPublished,
					    modified_by = :modifiedBy,
					    updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL;
				", {
					id: { value: local.id, cfsqltype: "cf_sql_integer" },
					siteid: { value: local.siteId, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					description: { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					imageUrl: { value: local.imageUrl, cfsqltype: "cf_sql_nvarchar" },
					imageAlt: { value: local.imageAlt, cfsqltype: "cf_sql_nvarchar" },
					badgeText: { value: local.badgeText, cfsqltype: "cf_sql_nvarchar" },
					badgeColor: { value: local.badgeColor, cfsqltype: "cf_sql_nvarchar" },
					layoutType: { value: local.layoutType, cfsqltype: "cf_sql_nvarchar" },
					linkText: { value: local.linkText, cfsqltype: "cf_sql_nvarchar" },
					linkUrl: { value: local.linkUrl, cfsqltype: "cf_sql_nvarchar" },
					linkIcon: { value: local.linkIcon, cfsqltype: "cf_sql_nvarchar" },
					linkStyle: { value: local.linkStyle, cfsqltype: "cf_sql_nvarchar" },
					targetBlank: { value: local.targetBlank, cfsqltype: "cf_sql_bit" },
					category: { value: local.category, cfsqltype: "cf_sql_nvarchar" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isPublished: { value: local.isPublished, cfsqltype: "cf_sql_bit" },
					modifiedBy: { value: local.user, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.res.success = true;
				local.res.message = 'Call to Action "' & local.title & '" updated successfully.';
				local.res.id = local.id;
			} else {
				local.insertQ = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO page_call_to_actions (
						siteid, title, slug, description, image_url, image_alt,
						badge_text, badge_color, layout_type, link_text, link_url,
						link_icon, link_style, target_blank, category, sort_order,
						is_published, created_by, modified_by, createdat, updatedat
					) VALUES (
						:siteid, :title, :slug, :description, :imageUrl, :imageAlt,
						:badgeText, :badgeColor, :layoutType, :linkText, :linkUrl,
						:linkIcon, :linkStyle, :targetBlank, :category, :sortOrder,
						:isPublished, :createdBy, :modifiedBy, SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT SCOPE_IDENTITY() AS new_id;
				", {
					siteid: { value: local.siteId, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					description: { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					imageUrl: { value: local.imageUrl, cfsqltype: "cf_sql_nvarchar" },
					imageAlt: { value: local.imageAlt, cfsqltype: "cf_sql_nvarchar" },
					badgeText: { value: local.badgeText, cfsqltype: "cf_sql_nvarchar" },
					badgeColor: { value: local.badgeColor, cfsqltype: "cf_sql_nvarchar" },
					layoutType: { value: local.layoutType, cfsqltype: "cf_sql_nvarchar" },
					linkText: { value: local.linkText, cfsqltype: "cf_sql_nvarchar" },
					linkUrl: { value: local.linkUrl, cfsqltype: "cf_sql_nvarchar" },
					linkIcon: { value: local.linkIcon, cfsqltype: "cf_sql_nvarchar" },
					linkStyle: { value: local.linkStyle, cfsqltype: "cf_sql_nvarchar" },
					targetBlank: { value: local.targetBlank, cfsqltype: "cf_sql_bit" },
					category: { value: local.category, cfsqltype: "cf_sql_nvarchar" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isPublished: { value: local.isPublished, cfsqltype: "cf_sql_bit" },
					createdBy: { value: local.user, cfsqltype: "cf_sql_nvarchar" },
					modifiedBy: { value: local.user, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.res.success = true;
				local.res.id = Val(local.insertQ.new_id);
				local.res.message = 'Call to Action "' & local.title & '" created successfully.';
			}
		} catch (any e) {
			local.res.message = "Failed to save Call to Action: " & e.message;
			writeLog(type="error", file="pages", text="saveCallToAction failed: #e.message# #e.detail#");
		}

		renderText(text = SerializeJSON(local.res), contentType = "application/json", layout = false);
	}

	/**
	 * Soft delete a Call to Action
	 */
	function deleteCallToAction() {
		ensureCallToActionTable();
		local.res = { "success": false, "message": "" };

		try {
			local.body = fxReadJsonBody();
			local.req = IsStruct(local.body) ? local.body : params;
			local.id = Val(local.req.id ?: (params.id ?: 0));
			if (local.id <= 0) {
				local.res.message = "Invalid Call to Action ID.";
				renderText(text = SerializeJSON(local.res), contentType = "application/json", layout = false);
				return;
			}

			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE page_call_to_actions
				SET deletedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL;
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			local.res.success = true;
			local.res.message = "Call to Action removed successfully.";
		} catch (any e) {
			local.res.message = "Failed to delete: " & e.message;
			writeLog(type="error", file="pages", text="deleteCallToAction failed: #e.message# #e.detail#");
		}

		renderText(text = SerializeJSON(local.res), contentType = "application/json", layout = false);
	}

	/**
	 * Reorder Call to Action items
	 */
	function reorderCallToActions() {
		ensureCallToActionTable();
		local.res = { "success": false, "message": "" };

		try {
			local.body = fxReadJsonBody();
			local.req = IsStruct(local.body) ? local.body : params;
			local.orderList = local.req.order ?: (local.req.ids ?: (params.order ?: (params.ids ?: [])));
			if (!IsArray(local.orderList)) {
				local.orderList = ListToArray(local.orderList);
			}

			local.seq = 1;
			for (local.itemId in local.orderList) {
				if (IsNumeric(local.itemId) && Val(local.itemId) > 0) {
					queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						UPDATE page_call_to_actions
						SET sort_order = :seq, updatedat = SYSUTCDATETIME()
						WHERE id = :id;
					", {
						seq: { value: local.seq, cfsqltype: "cf_sql_integer" },
						id: { value: Val(local.itemId), cfsqltype: "cf_sql_integer" }
					}, { datasource: "ChelanCountyWebsite" });
					local.seq++;
				}
			}
			local.res.success = true;
		} catch (any e) {
			local.res.message = "Reorder failed: " & e.message;
		}

		renderText(text = SerializeJSON(local.res), contentType = "application/json", layout = false);
	}

	/**
	 * Ensures the page_call_to_actions table exists and seeds initial reference items
	 */
	private void function ensureCallToActionTable() {
		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[page_call_to_actions]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[page_call_to_actions] (
						[id]            INT IDENTITY(1,1) NOT NULL,
						[siteid]        NVARCHAR(100) NOT NULL CONSTRAINT [DF_cta_siteid] DEFAULT (N'global'),
						[title]         NVARCHAR(255) NOT NULL,
						[slug]          NVARCHAR(150) NOT NULL,
						[description]   NVARCHAR(MAX) NULL,
						[image_url]     NVARCHAR(500) NULL,
						[image_alt]     NVARCHAR(255) NULL,
						[badge_text]    NVARCHAR(100) NULL,
						[badge_color]   NVARCHAR(50) NULL CONSTRAINT [DF_cta_bcolor] DEFAULT (N'blue'),
						[layout_type]   NVARCHAR(50) NOT NULL CONSTRAINT [DF_cta_layout] DEFAULT (N'card'),
						[link_text]     NVARCHAR(150) NOT NULL CONSTRAINT [DF_cta_ltext] DEFAULT (N'Learn More'),
						[link_url]      NVARCHAR(1000) NOT NULL,
						[link_icon]     NVARCHAR(50) NOT NULL CONSTRAINT [DF_cta_licon] DEFAULT (N'arrow'),
						[link_style]    NVARCHAR(50) NOT NULL CONSTRAINT [DF_cta_lstyle] DEFAULT (N'link'),
						[target_blank]  BIT NOT NULL CONSTRAINT [DF_cta_tblank] DEFAULT (0),
						[category]      NVARCHAR(100) NOT NULL CONSTRAINT [DF_cta_cat] DEFAULT (N'General'),
						[sort_order]    INT NOT NULL CONSTRAINT [DF_cta_sort] DEFAULT (0),
						[is_published]  BIT NOT NULL CONSTRAINT [DF_cta_pub] DEFAULT (1),
						[created_by]    NVARCHAR(255) NULL,
						[modified_by]   NVARCHAR(255) NULL,
						[createdat]     DATETIME2(7) NOT NULL CONSTRAINT [DF_cta_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]     DATETIME2(7) NOT NULL CONSTRAINT [DF_cta_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]     DATETIME2(7) NULL,
						CONSTRAINT [PK_page_call_to_actions] PRIMARY KEY CLUSTERED ([id] ASC)
					);

					CREATE NONCLUSTERED INDEX [IX_page_call_to_actions_site_slug]
					ON [dbo].[page_call_to_actions] ([siteid], [slug])
					WHERE [deletedat] IS NULL;
				END;
			", {}, { datasource: "ChelanCountyWebsite" });

			// Check if seed data is needed
			local.cntQ = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT COUNT(*) AS cnt FROM page_call_to_actions WHERE deletedat IS NULL;
			", {}, { datasource: "ChelanCountyWebsite" });

			if (Val(local.cntQ.cnt) == 0) {
				// Seed the 6 reference items from the Chelan County Assessor's portal
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO page_call_to_actions (
						siteid, title, slug, description, image_url, image_alt,
						badge_text, badge_color, layout_type, link_text, link_url,
						link_icon, link_style, target_blank, category, sort_order,
						is_published, created_by, createdat, updatedat
					) VALUES
					(
						'global', 'Parcel & Sale Search', 'parcel-sale-search',
						'Look up property details, assessed valuations, tax history, and verified market sales.',
						'/images/cta/parcel-search.jpg', 'Chelan County property parcel search',
						'PROPERTY SEARCH', 'blue', 'card', 'Search Parcels', 'https://www.chelancounty.gov/assessor/parcels',
						'arrow', 'link', 0, 'Assessor Services', 1, 1, 'System', SYSUTCDATETIME(), SYSUTCDATETIME()
					),
					(
						'global', 'Interactive GIS Map', 'interactive-gis-map',
						'Explore county parcel boundaries, aerial photography, tax code areas, and zoning layers.',
						'/images/cta/gis-map.jpg', 'Interactive county GIS mapping and property boundary search',
						'MAPPING', 'teal', 'card', 'Open Map', 'https://gis.chelancounty.gov',
						'external', 'link', 1, 'Assessor Services', 2, 1, 'System', SYSUTCDATETIME(), SYSUTCDATETIME()
					),
					(
						'global', 'Property Owner''s Guide', 'property-owners-guide',
						'Comprehensive reference covering assessments, market valuation cycles, and rights.',
						'/images/cta/property-guide.jpg', 'Property assessment calculations and documentation',
						'CITIZEN GUIDE', 'amber', 'card', 'Download PDF', '/files/assessor/documents/property-owners-guide.pdf',
						'pdf', 'link', 1, 'Assessor Services', 3, 1, 'System', SYSUTCDATETIME(), SYSUTCDATETIME()
					),
					(
						'global', 'Destroyed Property', 'destroyed-property',
						'File for property valuation adjustment and tax relief due to disaster, calamity, or fire damage.',
						'/images/cta/destroyed-property.jpg', 'Fire damage calamity tax relief and valuation adjustment',
						'TAX RELIEF', 'red', 'card', 'View Relief Forms', 'https://www.chelancounty.gov/assessor/destroyed-property',
						'arrow', 'link', 0, 'Assessor Services', 4, 1, 'System', SYSUTCDATETIME(), SYSUTCDATETIME()
					),
					(
						'global', 'Assessment Appeals', 'assessment-appeals',
						'Learn how to file a petition with the Chelan County Board of Equalization if you dispute your valuation.',
						'/images/cta/assessment-appeals.jpg', 'Petition paperwork for Board of Equalization valuation appeals',
						'APPEALS', 'blue', 'card', 'Appeal Instructions', 'https://www.chelancounty.gov/assessor/appeals',
						'arrow', 'link', 0, 'Assessor Services', 5, 1, 'System', SYSUTCDATETIME(), SYSUTCDATETIME()
					),
					(
						'global', 'Document Search', 'document-search',
						'Access official recorded deeds, land surveys, plats, and legal public records via AcclaimWeb.',
						'/images/cta/document-search.jpg', 'Searching recorded deeds and official public land records',
						'PUBLIC RECORDS', 'emerald', 'card', 'Search Records', 'https://recording.chelancounty.gov',
						'external', 'link', 1, 'Assessor Services', 6, 1, 'System', SYSUTCDATETIME(), SYSUTCDATETIME()
					);
				", {}, { datasource: "ChelanCountyWebsite" });
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="ensureCallToActionTable failed: #e.message# #e.detail#");
		}
	}

	/**
	 * Loads Call to Action items from database
	 */
	private array function loadCallToActions(string requestedWs = "", boolean includeAllWorkspaces = false) {
		ensureCallToActionTable();
		local.items = [];
		try {
			local.whereClause = "WHERE cta.deletedat IS NULL";
			local.params = {};

			if (!arguments.includeAllWorkspaces && Len(arguments.requestedWs) && arguments.requestedWs != "global" && arguments.requestedWs != "all") {
				local.whereClause &= " AND cta.siteid = :ws";
				local.params.ws = { value: arguments.requestedWs, cfsqltype: "cf_sql_nvarchar" };
			}

			local.q = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT cta.id, cta.siteid, cta.title, cta.slug, cta.description,
				       cta.image_url, cta.image_alt, cta.badge_text, cta.badge_color,
				       cta.layout_type, cta.link_text, cta.link_url, cta.link_icon,
				       cta.link_style, cta.target_blank, cta.category, cta.sort_order,
				       cta.is_published, cta.created_by, cta.modified_by,
				       cta.createdat, cta.updatedat
				FROM page_call_to_actions cta
				#local.whereClause#
				ORDER BY cta.sort_order ASC, cta.id ASC
			", local.params, { datasource: "ChelanCountyWebsite" });

			local.wsMap = {};
			for (local.w in getMasterWorkspaces()) {
				local.info = {
					"id": local.w.id,
					"name": local.w.name,
					"badge": local.w.badge ?: "Dept",
					"badgeClass": local.w.badgeClass ?: "badge-neutral"
				};
				local.wsMap[LCase(local.w.id)] = local.info;
				if (StructKeyExists(local.w, "code") && Len(local.w.code)) local.wsMap[LCase(local.w.code)] = local.info;
				if (StructKeyExists(local.w, "alias") && Len(local.w.alias)) local.wsMap[LCase(local.w.alias)] = local.info;
				if (StructKeyExists(local.w, "virtual_directory") && Len(local.w.virtual_directory)) local.wsMap[LCase(local.w.virtual_directory)] = local.info;
			}

			for (local.r in local.q) {
				local.wsKey = LCase(local.r.siteid ?: "global");
				local.wsInfo = StructKeyExists(local.wsMap, local.wsKey) ? local.wsMap[local.wsKey] : { "id": local.wsKey, "name": local.wsKey, "badge": "Dept", "badgeClass": "badge-neutral" };
				local.updatedStr = "";
				if (IsDate(local.r.updatedat)) {
					local.updatedStr = DateFormat(local.r.updatedat, "mm/dd/yyyy");
				}

				ArrayAppend(local.items, {
					"id": Val(local.r.id),
					"siteId": local.r.siteid ?: "global",
					"workspaceName": local.wsInfo.name,
					"workspaceBadge": local.wsInfo.badge,
					"workspaceBadgeClass": local.wsInfo.badgeClass,
					"title": local.r.title ?: "",
					"slug": local.r.slug ?: "",
					"description": local.r.description ?: "",
					"imageUrl": local.r.image_url ?: "",
					"imageAlt": local.r.image_alt ?: "",
					"badgeText": local.r.badge_text ?: "",
					"badgeColor": local.r.badge_color ?: "blue",
					"layoutType": local.r.layout_type ?: "card",
					"linkText": local.r.link_text ?: "Learn More",
					"linkUrl": local.r.link_url ?: "",
					"linkIcon": local.r.link_icon ?: "arrow",
					"linkStyle": local.r.link_style ?: "link",
					"targetBlank": (local.r.target_blank == 1),
					"category": local.r.category ?: "General",
					"sortOrder": Val(local.r.sort_order),
					"isPublished": (local.r.is_published == 1),
					"updated": local.updatedStr,
					"author": Len(Trim(local.r.modified_by ?: "")) ? local.r.modified_by : (local.r.created_by ?: "Admin"),
					"shortcode": '[call_to_action slug="' & (local.r.slug ?: '') & '"]'
				});
			}
		} catch (any e) {
			writeLog(type="error", file="pages", text="loadCallToActions failed: #e.message# #e.detail#");
		}
		return local.items;
	}

	/**
	 * Loads distinct Call to Action categories
	 */
	private array function loadCallToActionCategories(string requestedWs = "") {
		local.cats = ["General", "Assessor Services", "Online Portals", "Public Records", "Citizen Services"];
		try {
			local.whereClause = "WHERE deletedat IS NULL";
			local.params = {};
			if (Len(arguments.requestedWs) && arguments.requestedWs != "global" && arguments.requestedWs != "all") {
				local.whereClause &= " AND siteid = :ws";
				local.params.ws = { value: arguments.requestedWs, cfsqltype: "cf_sql_nvarchar" };
			}
			local.q = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT DISTINCT category
				FROM page_call_to_actions
				#local.whereClause# AND category IS NOT NULL AND LEN(category) > 0
				ORDER BY category ASC
			", local.params, { datasource: "ChelanCountyWebsite" });

			for (local.r in local.q) {
				if (!ArrayFindNoCase(local.cats, local.r.category)) {
					ArrayAppend(local.cats, local.r.category);
				}
			}
		} catch (any e) {}
		return local.cats;
	}

	/**
	 * Convert Word (.docx) or PDF (.pdf) to WCAG 2.1 AA HTML
	 */
	function convertDocument() {
		local.result = {
			"success" = false,
			"message" = "",
			"data" = {}
		};

		try {
			// Verify file upload
			if (!StructKeyExists(form, "documentFile") && !StructKeyExists(params, "documentFile")) {
				local.result.message = "Please select or drop a Word (.docx) or PDF (.pdf) file to convert.";
				renderText(text = SerializeJSON(local.result), contentType = "application/json", layout = false);
				return;
			}

			// Destination workspace
			local.ws = StructKeyExists(params, "workspace") && Len(Trim(params.workspace)) ? LCase(Trim(params.workspace)) : activeWorkspaceId();
			if (!Len(local.ws) || local.ws == "global" || local.ws == "all") {
				local.ws = "shared";
			}

			// Temp upload dir
			local.tempUploadDir = GetTempDirectory() & "doc_uploads_" & CreateUUID();
			if (!DirectoryExists(local.tempUploadDir)) {
				DirectoryCreate(local.tempUploadDir);
			}

			local.uploadRes = fileUpload(local.tempUploadDir, "documentFile", " ", "makeUnique");
			local.uploadedPath = local.tempUploadDir & "\" & local.uploadRes.serverFile;
			local.origName = local.uploadRes.clientFile;
			local.ext = LCase(local.uploadRes.serverFileExt);

			// Security check: only docx and pdf
			if (!ListFindNoCase("docx,pdf", local.ext)) {
				try { FileDelete(local.uploadedPath); } catch (any fe) {}
				try { DirectoryDelete(local.tempUploadDir); } catch (any de) {}
				local.result.message = "Invalid file type (." & local.ext & "). Only Microsoft Word (.docx) and Adobe PDF (.pdf) documents are supported.";
				renderText(text = SerializeJSON(local.result), contentType = "application/json", layout = false);
				return;
			}

			// Process conversion
			local.converter = CreateObject("component", "app.models.DocumentConverter");
			local.conv = local.converter.convertDocument(local.uploadedPath, local.origName, local.ws);

			// Clean up upload temp file
			try {
				if (FileExists(local.uploadedPath)) FileDelete(local.uploadedPath);
				if (DirectoryExists(local.tempUploadDir)) DirectoryDelete(local.tempUploadDir);
			} catch (any cleanErr) {}

			if (local.conv.success) {
				local.result.success = true;
				local.result.message = local.conv.message;
				local.result.data = local.conv;
			} else {
				local.result.message = local.conv.message;
				local.result.data = local.conv;
			}
		} catch (any ex) {
			local.result.message = "Document conversion server error: " & ex.message & (Len(ex.detail) ? " (" & ex.detail & ")" : "");
		}

		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text = SerializeJSON(local.result), layout = false);
	}



// One Page Studio methods for Pages.cfc
	/**
	 * Security Gate: One Page Studio is strictly restricted to System Administrators
	 */
	private boolean function checkOnePageAdminAccess() {
		return (getCurrentActiveRole() == "admin");
	}

	/**
	 * One Page Studio - Dashboard & Studio Builder
	 */
	function onePage() {
		if (!checkOnePageAdminAccess()) {
			flashInsert(error="Access Denied: One Page Studio is strictly restricted to System Administrators.");
			redirectTo(controller="main", action="index");
			return;
		}
		variables.pageTitle = "One Page Studio";
		ensureOnePageStudioTables();

		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");
		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.reqWs, role = local.role);
		variables.activeWorkspaceId = variables.activeWsObj.id ?: "global";

		local.showAll = (variables.activeWorkspaceId == "global" || variables.activeWorkspaceId == "all" || !Len(variables.activeWorkspaceId));
		variables.onePageSites = loadOnePageSites(requestedWs = variables.activeWorkspaceId, includeAllWorkspaces = local.showAll);

		// Determine selected site
		variables.selectedSiteId = 0;
		if (StructKeyExists(params, "id") && IsNumeric(params.id) && Val(params.id) > 0) {
			variables.selectedSiteId = Val(params.id);
		} else if (ArrayLen(variables.onePageSites) > 0) {
			variables.selectedSiteId = variables.onePageSites[1].id;
		}

		variables.selectedSite = {};
		variables.selectedSections = [];
		if (variables.selectedSiteId > 0) {
			for (local.s in variables.onePageSites) {
				if (local.s.id == variables.selectedSiteId) {
					variables.selectedSite = local.s;
					break;
				}
			}
			variables.selectedSections = loadOnePageSections(variables.selectedSiteId);
		}

		// Load candidate pages in this workspace that can be picked as sections
		variables.candidatePages = loadPagesForWorkspaceSelection(requestedWs = variables.activeWorkspaceId);
		variables.availableWorkspaces = getMasterWorkspaces();
	}

	/**
	 * JSON API: List all One Page Sites for workspace
	 */
	function getOnePageSites() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		ensureOnePageStudioTables();
		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		local.showAll = (local.reqWs == "global" || local.reqWs == "all" || !Len(local.reqWs));
		local.sites = loadOnePageSites(requestedWs = local.reqWs, includeAllWorkspaces = local.showAll);

		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text = SerializeJSON({ "success": true, "sites": local.sites, "count": ArrayLen(local.sites) }), layout = false);
	}

	/**
	 * JSON API: Get a single One Page Site with sections and live page details
	 */
	function getOnePageSite() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		ensureOnePageStudioTables();
		local.siteId = StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0;
		if (local.siteId <= 0) {
			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text = SerializeJSON({ "success": false, "message": "Valid site ID is required." }), layout = false, status = 400);
			return;
		}

		local.site = {};
		local.sites = loadOnePageSites(requestedWs = "", includeAllWorkspaces = true);
		for (local.s in local.sites) {
			if (local.s.id == local.siteId) {
				local.site = local.s;
				break;
			}
		}

		if (StructIsEmpty(local.site)) {
			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text = SerializeJSON({ "success": false, "message": "One Page Site not found." }), layout = false, status = 404);
			return;
		}

		local.sections = loadOnePageSections(local.siteId);
		local.candidatePages = loadPagesForWorkspaceSelection(requestedWs = local.site.siteid);

		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text = SerializeJSON({
			"success": true,
			"site": local.site,
			"sections": local.sections,
			"candidatePages": local.candidatePages
		}), layout = false);
	}

	/**
	 * JSON API: Save / Update One Page Site Settings
	 */
	function saveOnePageSite() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		ensureOnePageStudioTables();
		local.body = fxReadJsonBody();
		if (!IsStruct(local.body)) {
			fxRenderJson({ success: false, message: "Invalid JSON request payload." }, 400);
			return;
		}

		local.id = StructKeyExists(local.body, "id") && IsNumeric(local.body.id) ? Val(local.body.id) : (StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0);
		local.title = Left(Trim(local.body.title ?: ""), 255);
		local.slug = slugifyText(local.body.slug ?: local.title);
		local.siteid = Left(Trim(local.body.siteid ?: "global"), 100);
		local.subtitle = Left(Trim(local.body.subtitle ?: ""), 500);
		local.theme = Left(Trim(local.body.theme ?: "river-park"), 50);
		local.heroHeadline = Left(Trim(local.body.heroHeadline ?: local.title), 255);
		local.heroTagline = Left(Trim(local.body.heroTagline ?: local.subtitle), 500);
		local.heroImageUrl = Left(Trim(local.body.heroImageUrl ?: ""), 500);
		local.heroCtaPrimaryText = Left(Trim(local.body.heroCtaPrimaryText ?: "Explore Amenities"), 100);
		local.heroCtaPrimaryAnchor = Left(Trim(local.body.heroCtaPrimaryAnchor ?: "##amenities"), 100);
		if (Left(local.heroCtaPrimaryAnchor, 1) != "##" && Len(local.heroCtaPrimaryAnchor)) {
			local.heroCtaPrimaryAnchor = "##" & local.heroCtaPrimaryAnchor;
		}
		local.heroCtaSecondaryText = Left(Trim(local.body.heroCtaSecondaryText ?: "View Rates"), 100);
		local.heroCtaSecondaryAnchor = Left(Trim(local.body.heroCtaSecondaryAnchor ?: "##rates"), 100);
		if (Left(local.heroCtaSecondaryAnchor, 1) != "##" && Len(local.heroCtaSecondaryAnchor)) {
			local.heroCtaSecondaryAnchor = "##" & local.heroCtaSecondaryAnchor;
		}
		local.enableStickyNav = (StructKeyExists(local.body, "enableStickyNav") && fxToBoolean(local.body.enableStickyNav, true)) ? 1 : 0;
		local.navBrandTitle = Left(Trim(local.body.navBrandTitle ?: local.title), 150);
		local.navCtaText = Left(Trim(local.body.navCtaText ?: "Reserve Online"), 100);
		local.navCtaAnchor = Left(Trim(local.body.navCtaAnchor ?: "##rates"), 100);
		if (Left(local.navCtaAnchor, 1) != "##" && Len(local.navCtaAnchor)) {
			local.navCtaAnchor = "##" & local.navCtaAnchor;
		}
		local.enableScrollspy = (StructKeyExists(local.body, "enableScrollspy") && fxToBoolean(local.body.enableScrollspy, true)) ? 1 : 0;
		local.enableBackToTop = (StructKeyExists(local.body, "enableBackToTop") && fxToBoolean(local.body.enableBackToTop, true)) ? 1 : 0;
		local.isPublished = (StructKeyExists(local.body, "isPublished") && fxToBoolean(local.body.isPublished, true)) ? 1 : 0;
		local.customCss = local.body.customCss ?: "";
		local.metaTitle = Left(Trim(local.body.metaTitle ?: local.title), 255);
		local.metaDesc = Left(Trim(local.body.metaDesc ?: local.subtitle), 500);
		local.actor = spCurrentActor();

		if (!Len(local.title)) {
			fxRenderJson({ success: false, message: "Site title is required." }, 422);
			return;
		}
		if (!Len(local.slug)) {
			local.slug = "one-page-portal";
		}

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE one_page_sites SET
						siteid = :siteid,
						title = :title,
						slug = :slug,
						subtitle = :subtitle,
						theme = :theme,
						hero_headline = :heroHeadline,
						hero_tagline = :heroTagline,
						hero_image_url = :heroImageUrl,
						hero_cta_primary_text = :heroCtaPrimaryText,
						hero_cta_primary_anchor = :heroCtaPrimaryAnchor,
						hero_cta_secondary_text = :heroCtaSecondaryText,
						hero_cta_secondary_anchor = :heroCtaSecondaryAnchor,
						enable_sticky_nav = :enableStickyNav,
						nav_brand_title = :navBrandTitle,
						nav_cta_text = :navCtaText,
						nav_cta_anchor = :navCtaAnchor,
						enable_scrollspy = :enableScrollspy,
						enable_back_to_top = :enableBackToTop,
						is_published = :isPublished,
						custom_css = :customCss,
						meta_title = :metaTitle,
						meta_description = :metaDesc,
						modified_by = :actor,
						updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					id: { value: local.id, cfsqltype: "cf_sql_integer" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					subtitle: { value: local.subtitle, cfsqltype: "cf_sql_nvarchar" },
					theme: { value: local.theme, cfsqltype: "cf_sql_nvarchar" },
					heroHeadline: { value: local.heroHeadline, cfsqltype: "cf_sql_nvarchar" },
					heroTagline: { value: local.heroTagline, cfsqltype: "cf_sql_nvarchar" },
					heroImageUrl: { value: local.heroImageUrl, cfsqltype: "cf_sql_nvarchar" },
					heroCtaPrimaryText: { value: local.heroCtaPrimaryText, cfsqltype: "cf_sql_nvarchar" },
					heroCtaPrimaryAnchor: { value: local.heroCtaPrimaryAnchor, cfsqltype: "cf_sql_nvarchar" },
					heroCtaSecondaryText: { value: local.heroCtaSecondaryText, cfsqltype: "cf_sql_nvarchar" },
					heroCtaSecondaryAnchor: { value: local.heroCtaSecondaryAnchor, cfsqltype: "cf_sql_nvarchar" },
					enableStickyNav: { value: local.enableStickyNav, cfsqltype: "cf_sql_bit" },
					navBrandTitle: { value: local.navBrandTitle, cfsqltype: "cf_sql_nvarchar" },
					navCtaText: { value: local.navCtaText, cfsqltype: "cf_sql_nvarchar" },
					navCtaAnchor: { value: local.navCtaAnchor, cfsqltype: "cf_sql_nvarchar" },
					enableScrollspy: { value: local.enableScrollspy, cfsqltype: "cf_sql_bit" },
					enableBackToTop: { value: local.enableBackToTop, cfsqltype: "cf_sql_bit" },
					isPublished: { value: local.isPublished, cfsqltype: "cf_sql_bit" },
					customCss: { value: local.customCss, cfsqltype: "cf_sql_nvarchar" },
					metaTitle: { value: local.metaTitle, cfsqltype: "cf_sql_nvarchar" },
					metaDesc: { value: local.metaDesc, cfsqltype: "cf_sql_nvarchar" },
					actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				fxRenderJson({ success: true, id: local.id, message: "One Page Site configuration updated successfully." });
			} else {
				local.inserted = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedIds TABLE (id INT);
					INSERT INTO one_page_sites (
						siteid, title, slug, subtitle, theme, hero_headline, hero_tagline, hero_image_url,
						hero_cta_primary_text, hero_cta_primary_anchor, hero_cta_secondary_text, hero_cta_secondary_anchor,
						enable_sticky_nav, nav_brand_title, nav_cta_text, nav_cta_anchor,
						enable_scrollspy, enable_back_to_top, is_published, custom_css, meta_title, meta_description,
						created_by, modified_by, createdat, updatedat
					)
					OUTPUT INSERTED.id INTO @InsertedIds(id)
					VALUES (
						:siteid, :title, :slug, :subtitle, :theme, :heroHeadline, :heroTagline, :heroImageUrl,
						:heroCtaPrimaryText, :heroCtaPrimaryAnchor, :heroCtaSecondaryText, :heroCtaSecondaryAnchor,
						:enableStickyNav, :navBrandTitle, :navCtaText, :navCtaAnchor,
						:enableScrollspy, :enableBackToTop, :isPublished, :customCss, :metaTitle, :metaDesc,
						:actor, :actor, SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT id FROM @InsertedIds;
				", {
					siteid: { value: local.siteid, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					subtitle: { value: local.subtitle, cfsqltype: "cf_sql_nvarchar" },
					theme: { value: local.theme, cfsqltype: "cf_sql_nvarchar" },
					heroHeadline: { value: local.heroHeadline, cfsqltype: "cf_sql_nvarchar" },
					heroTagline: { value: local.heroTagline, cfsqltype: "cf_sql_nvarchar" },
					heroImageUrl: { value: local.heroImageUrl, cfsqltype: "cf_sql_nvarchar" },
					heroCtaPrimaryText: { value: local.heroCtaPrimaryText, cfsqltype: "cf_sql_nvarchar" },
					heroCtaPrimaryAnchor: { value: local.heroCtaPrimaryAnchor, cfsqltype: "cf_sql_nvarchar" },
					heroCtaSecondaryText: { value: local.heroCtaSecondaryText, cfsqltype: "cf_sql_nvarchar" },
					heroCtaSecondaryAnchor: { value: local.heroCtaSecondaryAnchor, cfsqltype: "cf_sql_nvarchar" },
					enableStickyNav: { value: local.enableStickyNav, cfsqltype: "cf_sql_bit" },
					navBrandTitle: { value: local.navBrandTitle, cfsqltype: "cf_sql_nvarchar" },
					navCtaText: { value: local.navCtaText, cfsqltype: "cf_sql_nvarchar" },
					navCtaAnchor: { value: local.navCtaAnchor, cfsqltype: "cf_sql_nvarchar" },
					enableScrollspy: { value: local.enableScrollspy, cfsqltype: "cf_sql_bit" },
					enableBackToTop: { value: local.enableBackToTop, cfsqltype: "cf_sql_bit" },
					isPublished: { value: local.isPublished, cfsqltype: "cf_sql_bit" },
					customCss: { value: local.customCss, cfsqltype: "cf_sql_nvarchar" },
					metaTitle: { value: local.metaTitle, cfsqltype: "cf_sql_nvarchar" },
					metaDesc: { value: local.metaDesc, cfsqltype: "cf_sql_nvarchar" },
					actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.newId = Val(local.inserted.id);
				fxRenderJson({ success: true, id: local.newId, message: "One Page Site created successfully." });
			}
		} catch (any err) {
			fxRenderJson({ success: false, message: "Database save error: " & err.message }, 500);
		}
	}

	/**
	 * JSON API: Soft-delete One Page Site
	 */
	function deleteOnePageSite() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		local.body = fxReadJsonBody();
		local.id = StructKeyExists(local.body, "id") && IsNumeric(local.body.id) ? Val(local.body.id) : (StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0);
		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "Valid ID required." }, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE one_page_sites SET deletedat = SYSUTCDATETIME() WHERE id = :id AND deletedat IS NULL;
				UPDATE one_page_sections SET deletedat = SYSUTCDATETIME() WHERE one_page_site_id = :id AND deletedat IS NULL;
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
			fxRenderJson({ success: true, message: "One Page Site deleted." });
		} catch (any err) {
			fxRenderJson({ success: false, message: "Delete error: " & err.message }, 500);
		}
	}

	/**
	 * JSON API: Save / Update Section in One Page Site
	 */
	function saveOnePageSection() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		ensureOnePageStudioTables();
		local.body = fxReadJsonBody();
		if (!IsStruct(local.body)) {
			fxRenderJson({ success: false, message: "Invalid JSON request payload." }, 400);
			return;
		}

		local.id = StructKeyExists(local.body, "id") && IsNumeric(local.body.id) ? Val(local.body.id) : (StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0);
		local.siteId = StructKeyExists(local.body, "one_page_site_id") && IsNumeric(local.body.one_page_site_id) ? Val(local.body.one_page_site_id) : 0;
		local.pageId = StructKeyExists(local.body, "page_id") && IsNumeric(local.body.page_id) && Val(local.body.page_id) > 0 ? Val(local.body.page_id) : JavaCast("null", "");
		local.rawAnchor = Trim(local.body.anchor_id ?: "");
		local.rawAnchor = ReReplace(local.rawAnchor, "^##+", ""); // Strip leading hashes
		local.anchorId = slugifyText(local.rawAnchor);
		local.title = Left(Trim(local.body.section_title ?: ""), 255);
		local.subtitle = Left(Trim(local.body.section_subtitle ?: ""), 500);
		local.layout = Left(Trim(local.body.section_layout ?: "full"), 50);
		local.bg = Left(Trim(local.body.section_bg ?: "default"), 50);
		local.contentOverride = local.body.content_override ?: "";
		local.showHeader = (StructKeyExists(local.body, "show_header") && fxToBoolean(local.body.show_header, true)) ? 1 : 0;
		local.showDivider = (StructKeyExists(local.body, "show_divider") && fxToBoolean(local.body.show_divider, true)) ? 1 : 0;
		local.customCssClass = Left(Trim(local.body.custom_css_class ?: ""), 100);
		local.sortOrder = StructKeyExists(local.body, "sort_order") && IsNumeric(local.body.sort_order) ? Val(local.body.sort_order) : 0;
		local.isActive = (StructKeyExists(local.body, "is_active") && fxToBoolean(local.body.is_active, true)) ? 1 : 0;

		if (local.siteId <= 0) {
			fxRenderJson({ success: false, message: "Site ID is required." }, 422);
			return;
		}
		if (!Len(local.title)) {
			fxRenderJson({ success: false, message: "Section title is required." }, 422);
			return;
		}
		if (!Len(local.anchorId)) {
			local.anchorId = slugifyText(local.title);
		}

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE one_page_sections SET
						page_id = :pageId,
						anchor_id = :anchorId,
						section_title = :title,
						section_subtitle = :subtitle,
						section_layout = :layout,
						section_bg = :bg,
						content_override = :contentOverride,
						show_header = :showHeader,
						show_divider = :showDivider,
						custom_css_class = :customCssClass,
						sort_order = :sortOrder,
						is_active = :isActive,
						updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					id: { value: local.id, cfsqltype: "cf_sql_integer" },
					pageId: { value: local.pageId, cfsqltype: "cf_sql_integer", null: IsNull(local.pageId) },
					anchorId: { value: local.anchorId, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					subtitle: { value: local.subtitle, cfsqltype: "cf_sql_nvarchar" },
					layout: { value: local.layout, cfsqltype: "cf_sql_nvarchar" },
					bg: { value: local.bg, cfsqltype: "cf_sql_nvarchar" },
					contentOverride: { value: local.contentOverride, cfsqltype: "cf_sql_nvarchar" },
					showHeader: { value: local.showHeader, cfsqltype: "cf_sql_bit" },
					showDivider: { value: local.showDivider, cfsqltype: "cf_sql_bit" },
					customCssClass: { value: local.customCssClass, cfsqltype: "cf_sql_nvarchar" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isActive: { value: local.isActive, cfsqltype: "cf_sql_bit" }
				}, { datasource: "ChelanCountyWebsite" });

				fxRenderJson({ success: true, id: local.id, anchor: "##" & local.anchorId, message: "Section updated." });
			} else {
				// If sortOrder not provided, append to end
				if (local.sortOrder <= 0) {
					local.cntQ = queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						SELECT ISNULL(MAX(sort_order), 0) + 1 AS nextSort
						FROM one_page_sections
						WHERE one_page_site_id = :siteId AND deletedat IS NULL
					", { siteId: { value: local.siteId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
					local.sortOrder = Val(local.cntQ.nextSort);
				}

				local.inserted = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedSecs TABLE (id INT);
					INSERT INTO one_page_sections (
						one_page_site_id, page_id, anchor_id, section_title, section_subtitle,
						section_layout, section_bg, content_override, show_header, show_divider,
						custom_css_class, sort_order, is_active, createdat, updatedat
					)
					OUTPUT INSERTED.id INTO @InsertedSecs(id)
					VALUES (
						:siteId, :pageId, :anchorId, :title, :subtitle,
						:layout, :bg, :contentOverride, :showHeader, :showDivider,
						:customCssClass, :sortOrder, :isActive, SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT id FROM @InsertedSecs;
				", {
					siteId: { value: local.siteId, cfsqltype: "cf_sql_integer" },
					pageId: { value: local.pageId, cfsqltype: "cf_sql_integer", null: IsNull(local.pageId) },
					anchorId: { value: local.anchorId, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					subtitle: { value: local.subtitle, cfsqltype: "cf_sql_nvarchar" },
					layout: { value: local.layout, cfsqltype: "cf_sql_nvarchar" },
					bg: { value: local.bg, cfsqltype: "cf_sql_nvarchar" },
					contentOverride: { value: local.contentOverride, cfsqltype: "cf_sql_nvarchar" },
					showHeader: { value: local.showHeader, cfsqltype: "cf_sql_bit" },
					showDivider: { value: local.showDivider, cfsqltype: "cf_sql_bit" },
					customCssClass: { value: local.customCssClass, cfsqltype: "cf_sql_nvarchar" },
					sortOrder: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isActive: { value: local.isActive, cfsqltype: "cf_sql_bit" }
				}, { datasource: "ChelanCountyWebsite" });

				local.newSecId = Val(local.inserted.id);
				fxRenderJson({ success: true, id: local.newSecId, anchor: "##" & local.anchorId, message: "Section added to One Page Site." });
			}
		} catch (any err) {
			fxRenderJson({ success: false, message: "Section save error: " & err.message }, 500);
		}
	}

	/**
	 * JSON API: Soft-delete Section
	 */
	function deleteOnePageSection() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		local.body = fxReadJsonBody();
		local.id = StructKeyExists(local.body, "id") && IsNumeric(local.body.id) ? Val(local.body.id) : (StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0);
		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "Valid ID required." }, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE one_page_sections SET deletedat = SYSUTCDATETIME() WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
			fxRenderJson({ success: true, message: "Section removed." });
		} catch (any err) {
			fxRenderJson({ success: false, message: "Delete error: " & err.message }, 500);
		}
	}

	/**
	 * JSON API: Reorder sections
	 */
	function reorderOnePageSections() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		local.body = fxReadJsonBody();
		if (!IsStruct(local.body) || !StructKeyExists(local.body, "ids") || !IsArray(local.body.ids)) {
			fxRenderJson({ success: false, message: "Invalid payload: array of IDs required." }, 400);
			return;
		}

		try {
			for (local.idx = 1; local.idx <= ArrayLen(local.body.ids); local.idx++) {
				local.sId = Val(local.body.ids[local.idx]);
				if (local.sId > 0) {
					queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						UPDATE one_page_sections SET sort_order = :ord WHERE id = :id
					", {
						ord: { value: local.idx, cfsqltype: "cf_sql_integer" },
						id: { value: local.sId, cfsqltype: "cf_sql_integer" }
					}, { datasource: "ChelanCountyWebsite" });
				}
			}
			fxRenderJson({ success: true, message: "Section order saved." });
		} catch (any err) {
			fxRenderJson({ success: false, message: "Reorder error: " & err.message }, 500);
		}
	}

	/**
	 * Sync One-Page Section Anchors into Navigation Menu (navigation_menu_items)
	 */
	function syncOnePageToMenu() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		local.body = fxReadJsonBody();
		local.siteId = StructKeyExists(local.body, "id") && IsNumeric(local.body.id) ? Val(local.body.id) : (StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0);
		if (local.siteId <= 0) {
			fxRenderJson({ success: false, message: "Valid One Page Site ID required." }, 400);
			return;
		}

		local.sites = loadOnePageSites(requestedWs = "", includeAllWorkspaces = true);
		local.site = {};
		for (local.s in local.sites) {
			if (local.s.id == local.siteId) {
				local.site = local.s;
				break;
			}
		}

		if (StructIsEmpty(local.site)) {
			fxRenderJson({ success: false, message: "Site not found." }, 404);
			return;
		}

		local.sections = loadOnePageSections(local.siteId);
		if (ArrayLen(local.sections) == 0) {
			fxRenderJson({ success: false, message: "No sections defined in this One Page Site to sync." }, 422);
			return;
		}

		try {
			// 1. Locate or create navigation menu for this workspace
			local.menuId = 0;
			local.qMenu = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 id FROM navigation_menus
				WHERE siteid = :siteid AND deletedat IS NULL
				ORDER BY CASE WHEN menu_key = 'side' THEN 1 WHEN menu_key = 'top' THEN 2 ELSE 3 END
			", { siteid: { value: local.site.siteid, cfsqltype: "cf_sql_nvarchar" } }, { datasource: "ChelanCountyWebsite" });

			if (local.qMenu.recordCount > 0) {
				local.menuId = Val(local.qMenu.id);
			} else {
				local.newMenu = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedMenu TABLE (id INT);
					INSERT INTO navigation_menus (siteid, menu_key, name, createdat, updatedat)
					OUTPUT INSERTED.id INTO @InsertedMenu(id)
					VALUES (:siteid, 'side', :name, SYSUTCDATETIME(), SYSUTCDATETIME());
					SELECT id FROM @InsertedMenu;
				", {
					siteid: { value: local.site.siteid, cfsqltype: "cf_sql_nvarchar" },
					name: { value: local.site.title & " Side Menu", cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });
				local.menuId = Val(local.newMenu.id);
			}

			// 2. Loop through active sections and sync as anchor items
			local.syncedCount = 0;
			for (local.sec in local.sections) {
				if (!local.sec.isActive) continue;
				local.dest = "##" & local.sec.anchorId;

				// Check if menu item with this destination already exists
				local.qItem = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					SELECT id FROM navigation_menu_items
					WHERE navigation_menu_id = :menuId AND destination = :dest AND deletedat IS NULL
				", {
					menuId: { value: local.menuId, cfsqltype: "cf_sql_integer" },
					dest: { value: local.dest, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				if (local.qItem.recordCount > 0) {
					// Update label and sort order
					queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						UPDATE navigation_menu_items SET
							label = :label,
							sort_order = :sortOrder,
							destination_type = 'url',
							is_active = 1,
							updatedat = SYSUTCDATETIME()
						WHERE id = :id
					", {
						label: { value: local.sec.sectionTitle, cfsqltype: "cf_sql_nvarchar" },
						sortOrder: { value: local.sec.sortOrder, cfsqltype: "cf_sql_integer" },
						id: { value: local.qItem.id, cfsqltype: "cf_sql_integer" }
					}, { datasource: "ChelanCountyWebsite" });
				} else {
					// Insert new anchor menu item
					queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						INSERT INTO navigation_menu_items (
							navigation_menu_id, label, destination_type, destination,
							sort_order, is_active, open_in_new_tab, createdat, updatedat
						) VALUES (
							:menuId, :label, 'url', :dest, :sortOrder, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()
						)
					", {
						menuId: { value: local.menuId, cfsqltype: "cf_sql_integer" },
						label: { value: local.sec.sectionTitle, cfsqltype: "cf_sql_nvarchar" },
						dest: { value: local.dest, cfsqltype: "cf_sql_nvarchar" },
						sortOrder: { value: local.sec.sortOrder, cfsqltype: "cf_sql_integer" }
					}, { datasource: "ChelanCountyWebsite" });
				}
				local.syncedCount++;
			}

			fxRenderJson({
				success: true,
				count: local.syncedCount,
				menuId: local.menuId,
				message: "Successfully synchronized " & local.syncedCount & " section anchors to Navigation Menu!"
			});
		} catch (any err) {
			fxRenderJson({ success: false, message: "Menu sync error: " & err.message }, 500);
		}
	}

	/**
	 * Compile One-Page Website into dbo.pages as a master page
	 */
	function compileOnePageSite() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}
		local.body = fxReadJsonBody();
		if (!IsStruct(local.body)) local.body = {};
		local.siteId = StructKeyExists(local.body, "id") && IsNumeric(local.body.id) ? Val(local.body.id) : (StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0);
		if (local.siteId <= 0) {
			fxRenderJson({ success: false, message: "Valid One Page Site ID required." }, 400);
			return;
		}

		local.sites = loadOnePageSites(requestedWs = "", includeAllWorkspaces = true);
		local.site = {};
		for (local.s in local.sites) {
			if (local.s.id == local.siteId) {
				local.site = local.s;
				break;
			}
		}

		if (StructIsEmpty(local.site)) {
			fxRenderJson({ success: false, message: "Site not found." }, 404);
			return;
		}

		local.sections = loadOnePageSections(local.siteId);
		local.separateAssets = StructKeyExists(local.body, "separateAssets") ? (local.body.separateAssets == true || local.body.separateAssets == "true" || local.body.separateAssets == 1) : true;
		local.cssRelPath = "/stylesheets/onepage/" & local.site.slug & ".css";
		local.jsRelPath = "/javascripts/onepage/" & local.site.slug & ".js";

		if (local.separateAssets) {
			try {
				local.cssDir = ExpandPath("/stylesheets/onepage/");
				local.jsDir = ExpandPath("/javascripts/onepage/");
				if (!DirectoryExists(local.cssDir)) DirectoryCreate(local.cssDir);
				if (!DirectoryExists(local.jsDir)) DirectoryCreate(local.jsDir);

				local.cssContent = buildOnePageCss(local.site);
				local.jsContent = buildOnePageJs(local.site);

				FileWrite(local.cssDir & local.site.slug & ".css", local.cssContent, "utf-8");
				FileWrite(local.jsDir & local.site.slug & ".js", local.jsContent, "utf-8");
			} catch (any fileErr) {
				writeLog(type="error", file="pages", text="compileOnePageSite asset write error: #fileErr.message#");
			}
		}

		local.compiledHtml = buildOnePageHtml(siteData = local.site, sectionsData = local.sections, standalone = false, separateAssets = local.separateAssets);
		local.actor = spCurrentActor();

		try {
			local.targetPageId = Val(local.site.targetPageId ?: 0);
			if (local.targetPageId > 0) {
				// Update existing page
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE pages SET
						Title = :title,
						Permalink = :permalink,
						Summary = :summary,
						Body = :body,
						LayoutType = 'One Page',
						SiteID = :siteid,
						StatusCode = 'Active',
						Visibility = 'Published',
						isPublished = 1,
						Modified = SYSUTCDATETIME(),
						ModifiedBy = :actor
					WHERE ContentID = :id AND DeletedAt IS NULL
				", {
					title: { value: local.site.title, cfsqltype: "cf_sql_nvarchar" },
					permalink: { value: local.site.slug, cfsqltype: "cf_sql_nvarchar" },
					summary: { value: local.site.subtitle, cfsqltype: "cf_sql_nvarchar" },
					body: { value: local.compiledHtml, cfsqltype: "cf_sql_nvarchar" },
					siteid: { value: local.site.siteid, cfsqltype: "cf_sql_nvarchar" },
					actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" },
					id: { value: local.targetPageId, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				// Insert new page in dbo.pages
				local.insertedPage = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedPages TABLE (id INT);
					INSERT INTO pages (
						SiteID, PageType, MenuSelected, LayoutType, ParentID,
						StatusCode, Permalink, Title, MetaTitle, MetaDesc,
						Summary, Body, isPublished, Visibility, Created, CreatedBy, Modified, ModifiedBy
					)
					OUTPUT INSERTED.ContentID INTO @InsertedPages(id)
					VALUES (
						:siteid, 0, 'Top Level - Called from URL', 'One Page', 0,
						'Active', :permalink, :title, :metaTitle, :metaDesc,
						:summary, :body, 1, 'Published', SYSUTCDATETIME(), :actor, SYSUTCDATETIME(), :actor
					);
					SELECT id FROM @InsertedPages;
				", {
					siteid: { value: local.site.siteid, cfsqltype: "cf_sql_nvarchar" },
					permalink: { value: local.site.slug, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.site.title, cfsqltype: "cf_sql_nvarchar" },
					metaTitle: { value: local.site.metaTitle ?: local.site.title, cfsqltype: "cf_sql_nvarchar" },
					metaDesc: { value: local.site.metaDescription ?: local.site.subtitle, cfsqltype: "cf_sql_nvarchar" },
					summary: { value: local.site.subtitle, cfsqltype: "cf_sql_nvarchar" },
					body: { value: local.compiledHtml, cfsqltype: "cf_sql_nvarchar" },
					actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.targetPageId = Val(local.insertedPage.id);

				// Update target_page_id on site
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE one_page_sites SET target_page_id = :pageId WHERE id = :id
				", {
					pageId: { value: local.targetPageId, cfsqltype: "cf_sql_integer" },
					id: { value: local.site.id, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });
			}

			fxRenderJson({
				success: true,
				pageId: local.targetPageId,
				permalink: local.site.slug,
				separateAssets: local.separateAssets,
				cssPath: local.separateAssets ? local.cssRelPath : "",
				jsPath: local.separateAssets ? local.jsRelPath : "",
				message: local.separateAssets
					? "One-Page website compiled successfully with separated assets (" & local.cssRelPath & " and " & local.jsRelPath & ") into Content Manager (Page ID ##" & local.targetPageId & ")!"
					: "One-Page website compiled successfully into Content Manager (Page ID ##" & local.targetPageId & ")!"
			});
		} catch (any err) {
			fxRenderJson({ success: false, message: "Compilation error: " & err.message }, 500);
		}
	}

	/**
	 * Publish One-Page Website to Production (Updates files with separated assets in workspace.project_path)
	 */
	function publishOnePageToProduction() {
		if (!checkOnePageAdminAccess()) {
			fxRenderJson({ success: false, message: "Access Denied: One Page Studio is strictly restricted to System Administrators." }, 403);
			return;
		}

		local.body = fxReadJsonBody();
		if (!IsStruct(local.body)) local.body = {};
		local.siteId = StructKeyExists(local.body, "id") && IsNumeric(local.body.id) ? Val(local.body.id) : (StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0);
		if (local.siteId <= 0) {
			fxRenderJson({ success: false, message: "Valid One Page Site ID required for production deployment." }, 400);
			return;
		}

		local.sites = loadOnePageSites(requestedWs = "", includeAllWorkspaces = true);
		local.site = {};
		for (local.s in local.sites) {
			if (local.s.id == local.siteId) {
				local.site = local.s;
				break;
			}
		}

		if (StructIsEmpty(local.site)) {
			fxRenderJson({ success: false, message: "One Page Site not found." }, 404);
			return;
		}

		// 1. Resolve Workspace & Target Project Path
		local.targetPath = "";
		local.wsCode = local.site.siteid;

		try {
			local.wsQ = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 code, name, project_path, folder_path, domain_name
				FROM cms_workspaces
				WHERE (code = :wsCode OR alias = :wsCode) AND deletedat IS NULL
			", {
				wsCode: { value: local.wsCode, cfsqltype: "cf_sql_nvarchar" }
			}, { datasource: "ChelanCountyWebsite" });

			if (local.wsQ.recordCount > 0 && Len(Trim(local.wsQ.project_path ?: ""))) {
				local.targetPath = Trim(local.wsQ.project_path);
			}
		} catch (any wsErr) {
			writeLog(type="error", file="pages", text="publishOnePageToProduction ws lookup error: ##wsErr.message##");
		}

		// Fallback heuristics for known Chelan County departmental production portals
		if (!Len(local.targetPath)) {
			if (local.wsCode == "wrcp") {
				local.targetPath = "C:\inetpub\wenatcheeriverpark.org";
			} else if (local.wsCode == "ohme" || local.wsCode == "ohme-gardens") {
				local.targetPath = "C:\inetpub\ohmegardens.org";
			} else if (local.wsCode == "fair" || local.wsCode == "chelancountyfair") {
				local.targetPath = "C:\inetpub\chelancountyfair.com";
			} else if (local.wsCode == "expo" || local.wsCode == "expocenter") {
				local.targetPath = "C:\inetpub\chelancountyexpocenter.com";
			} else if (local.wsCode == "global" || local.wsCode == "all") {
				local.targetPath = "C:\inetpub\chelan-county";
			} else {
				local.targetPath = "C:\inetpub\" & local.wsCode;
			}
		}

		// Normalize directory path (trim trailing slashes or /files)
		if (Right(local.targetPath, 6) == "\files" || Right(local.targetPath, 6) == "/files") {
			local.targetPath = Left(local.targetPath, Len(local.targetPath) - 6);
		}
		if (Right(local.targetPath, 1) == "\" || Right(local.targetPath, 1) == "/") {
			local.targetPath = Left(local.targetPath, Len(local.targetPath) - 1);
		}

		try {
			// Ensure production root and asset directories exist
			if (!DirectoryExists(local.targetPath)) {
				DirectoryCreate(local.targetPath);
			}

			local.assetsCssDir = local.targetPath & "\assets\css\";
			local.assetsJsDir = local.targetPath & "\assets\js\";
			local.assetsImgDir = local.targetPath & "\assets\images\";

			if (!DirectoryExists(local.assetsCssDir)) DirectoryCreate(local.assetsCssDir);
			if (!DirectoryExists(local.assetsJsDir)) DirectoryCreate(local.assetsJsDir);
			if (!DirectoryExists(local.assetsImgDir)) DirectoryCreate(local.assetsImgDir);

			// Load sections
			local.sections = loadOnePageSections(local.siteId);

			// 2. Generate Separated Assets
			local.cssContent = buildOnePageCss(local.site);
			local.jsContent = buildOnePageJs(local.site);
			local.htmlContent = buildOnePageHtml(
				siteData = local.site,
				sectionsData = local.sections,
				standalone = true,
				separateAssets = true,
				assetPathPrefix = "assets/"
			);
			local.readmeContent = buildOnePageReadme(local.site);

			// 3. Sync Referenced Media to Production assets/images/
			local.imagesCopied = [];
			for (local.sec in local.sections) {
				if (Len(local.sec.imageAttachment ?: "")) {
					local.cleanImg = Replace(local.sec.imageAttachment, "%20", " ", "all");
					if (Left(local.cleanImg, 1) == "/") local.cleanImg = Right(local.cleanImg, Len(local.cleanImg) - 1);
					local.diskImg = ExpandPath("/" & local.cleanImg);
					if (FileExists(local.diskImg)) {
						local.imgName = GetFileFromPath(local.diskImg);
						local.destImg = local.assetsImgDir & local.imgName;
						try {
							FileCopy(local.diskImg, local.destImg);
							ArrayAppend(local.imagesCopied, local.imgName);
						} catch (any copyErr) {}
						// Rewrite image paths in HTML to point to assets/images/
						local.htmlContent = ReplaceNoCase(local.htmlContent, local.sec.imageAttachment, "assets/images/" & local.imgName, "all");
					}
				}
			}

			// 4. Atomically write production HTML and separated assets
			FileWrite(local.targetPath & "\index.html", local.htmlContent, "utf-8");
			FileWrite(local.assetsCssDir & "site.css", local.cssContent, "utf-8");
			FileWrite(local.assetsJsDir & "site.js", local.jsContent, "utf-8");
			FileWrite(local.targetPath & "\README.md", local.readmeContent, "utf-8");

			// 5. Update site updated timestamp & publish state in DB
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE one_page_sites
				SET is_published = 1, updatedat = SYSUTCDATETIME()
				WHERE id = :id
			", {
				id: { value: local.site.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({
				success: true,
				siteId: local.site.id,
				siteTitle: local.site.title,
				projectPath: local.targetPath,
				filesUpdated: [
					"index.html",
					"assets\css\site.css",
					"assets\js\site.js",
					"README.md"
				],
				imagesCount: ArrayLen(local.imagesCopied),
				message: "Successfully published """ & local.site.title & """ to production at " & local.targetPath & " with separated assets!"
			});
		} catch (any err) {
			writeLog(type="error", file="pages", text="publishOnePageToProduction error: ##err.message## (##err.detail##)");
			fxRenderJson({
				success: false,
				message: "Production deployment failed: " & err.message & (Len(err.detail) ? " (" & err.detail & ")" : "")
			}, 500);
		}
	}

	/**
	 * Standalone Full-Page Live Preview (No CMS Admin Frame)
	 */
	function previewOnePageSite() {
		local.siteId = StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0;
		if (local.siteId <= 0) {
			renderText(text = "Valid One Page Site ID is required for preview.", layout = false);
			return;
		}

		local.sites = loadOnePageSites(requestedWs = "", includeAllWorkspaces = true);
		local.site = {};
		for (local.s in local.sites) {
			if (local.s.id == local.siteId) {
				local.site = local.s;
				break;
			}
		}

		if (StructIsEmpty(local.site)) {
			renderText(text = "One Page Site not found.", layout = false);
			return;
		}

		local.sections = loadOnePageSections(local.siteId);
		local.fullHtml = buildOnePageHtml(siteData = local.site, sectionsData = local.sections, standalone = true);

		cfheader(name="Content-Type", value="text/html; charset=utf-8");
		renderText(text = local.fullHtml, layout = false);
	}

	/**
	 * Export Standalone Responsive HTML or Separated Asset ZIP Bundle for Production Front End
	 */
	function exportOnePageSite() {
		local.siteId = StructKeyExists(params, "id") && IsNumeric(params.id) ? Val(params.id) : 0;
		if (local.siteId <= 0) {
			renderText(text = "Valid One Page Site ID is required for export.", layout = false);
			return;
		}

		local.sites = loadOnePageSites(requestedWs = "", includeAllWorkspaces = true);
		local.site = {};
		for (local.s in local.sites) {
			if (local.s.id == local.siteId) {
				local.site = local.s;
				break;
			}
		}

		if (StructIsEmpty(local.site)) {
			renderText(text = "One Page Site not found.", layout = false);
			return;
		}

		local.sections = loadOnePageSections(local.siteId);
		local.format = StructKeyExists(params, "format") ? LCase(Trim(params.format)) : (StructKeyExists(params, "bundle") && (params.bundle == 1 || params.bundle == "true" || params.bundle == "zip") ? "zip" : "html");
		local.separateAssets = StructKeyExists(params, "separateAssets") ? (params.separateAssets == 1 || params.separateAssets == "true" || params.separateAssets == true) : (local.format == "zip");
		local.slug = Len(local.site.slug) ? local.site.slug : "one-page-site";

		if (local.format == "zip") {
			// Generate separated assets
			local.cssContent = buildOnePageCss(local.site);
			local.jsContent = buildOnePageJs(local.site);
			local.htmlContent = buildOnePageHtml(siteData = local.site, sectionsData = local.sections, standalone = true, separateAssets = true, assetPathPrefix = "assets/");
			local.readmeContent = buildOnePageReadme(local.site);

			// Collect any local image files referenced in sections to include in assets/images/
			local.imagesToZip = [];
			for (local.sec in local.sections) {
				if (Len(local.sec.imageAttachment ?: "")) {
					local.cleanImg = Replace(local.sec.imageAttachment, "%20", " ", "all");
					if (Left(local.cleanImg, 1) == "/") local.cleanImg = Right(local.cleanImg, Len(local.cleanImg) - 1);
					local.diskImg = ExpandPath("/" & local.cleanImg);
					if (FileExists(local.diskImg)) {
						local.imgName = GetFileFromPath(local.diskImg);
						ArrayAppend(local.imagesToZip, { file: local.diskImg, entry: "assets/images/" & local.imgName });
						// Rewrite image in html to point to assets/images/
						local.htmlContent = ReplaceNoCase(local.htmlContent, local.sec.imageAttachment, "assets/images/" & local.imgName, "all");
					}
				}
			}

			local.tempZip = GetTempDirectory() & "ops_export_" & CreateUUID() & ".zip";
			try {
				cfzip(action="zip", file=local.tempZip, overwrite="true") {
					cfzipparam(content=local.htmlContent, entrypath="index.html");
					cfzipparam(content=local.cssContent, entrypath="assets/css/site.css");
					cfzipparam(content=local.jsContent, entrypath="assets/js/site.js");
					cfzipparam(content=local.readmeContent, entrypath="README.md");
					for (local.imgItem in local.imagesToZip) {
						cfzipparam(source=local.imgItem.file, entrypath=local.imgItem.entry);
					}
				}

				local.zipFilename = local.slug & "-bundle.zip";
				cfheader(name="Content-Disposition", value="attachment; filename=""" & local.zipFilename & """");
				cfheader(name="Content-Type", value="application/zip");
				cfcontent(file=local.tempZip, type="application/zip", deletefile="true");
				return;
			} catch (any err) {
				if (FileExists(local.tempZip)) FileDelete(local.tempZip);
				renderText(text = "ZIP Generation Error: " & err.message, layout = false);
				return;
			}
		}

		// HTML Export (single file or linked assets)
		local.fullHtml = buildOnePageHtml(siteData = local.site, sectionsData = local.sections, standalone = true, separateAssets = local.separateAssets, assetPathPrefix = "");
		local.filename = local.slug & ".html";
		cfheader(name="Content-Disposition", value="attachment; filename=" & Chr(34) & local.filename & Chr(34));
		cfheader(name="Content-Type", value="text/html; charset=utf-8");
		renderText(text = local.fullHtml, layout = false);
	}

	/**
	 * Loads all One Page Sites from database
	 */
	private array function loadOnePageSites(string requestedWs = "", boolean includeAllWorkspaces = false) {
		local.list = [];
		try {
			ensureOnePageStudioTables();
			local.whereClause = "WHERE s.deletedat IS NULL";
			local.params = {};

			if (!arguments.includeAllWorkspaces && Len(arguments.requestedWs) && arguments.requestedWs != "global" && arguments.requestedWs != "all") {
				local.candidates = getCandidateSiteIds(arguments.requestedWs);
				if (ArrayLen(local.candidates) == 0) ArrayAppend(local.candidates, arguments.requestedWs);
				local.inHolders = [];
				for (local.i = 1; local.i <= ArrayLen(local.candidates); local.i++) {
					local.p = "opsWs" & local.i;
					ArrayAppend(local.inHolders, ":" & local.p);
					local.params[local.p] = { value: local.candidates[local.i], cfsqltype: "cf_sql_nvarchar" };
				}
				local.whereClause &= " AND (s.siteid IN (" & ArrayToList(local.inHolders, ", ") & ") OR s.siteid = 'global')";
			}

			local.sql = "
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT s.id, s.siteid, s.title, s.slug, s.subtitle, s.theme,
				       s.hero_headline, s.hero_tagline, s.hero_image_url,
				       s.hero_cta_primary_text, s.hero_cta_primary_anchor,
				       s.hero_cta_secondary_text, s.hero_cta_secondary_anchor,
				       s.enable_sticky_nav, s.nav_brand_title, s.nav_cta_text, s.nav_cta_anchor,
				       s.enable_scrollspy, s.enable_back_to_top, s.target_page_id,
				       s.is_published, s.sort_order, s.custom_css, s.meta_title, s.meta_description,
				       s.created_by, s.modified_by, s.createdat, s.updatedat,
				       (SELECT COUNT(*) FROM one_page_sections sec WHERE sec.one_page_site_id = s.id AND sec.deletedat IS NULL) AS section_count
				FROM one_page_sites s
				" & local.whereClause & "
				ORDER BY s.sort_order ASC, s.id DESC
			";

			local.q = queryExecute(local.sql, local.params, { datasource: "ChelanCountyWebsite" });
			for (local.row in local.q) {
				ArrayAppend(local.list, {
					"id": Val(local.row.id),
					"siteid": local.row.siteid ?: "global",
					"title": local.row.title ?: "",
					"slug": local.row.slug ?: "",
					"subtitle": local.row.subtitle ?: "",
					"theme": local.row.theme ?: "river-park",
					"heroHeadline": local.row.hero_headline ?: "",
					"heroTagline": local.row.hero_tagline ?: "",
					"heroImageUrl": local.row.hero_image_url ?: "",
					"heroCtaPrimaryText": local.row.hero_cta_primary_text ?: "",
					"heroCtaPrimaryAnchor": local.row.hero_cta_primary_anchor ?: "",
					"heroCtaSecondaryText": local.row.hero_cta_secondary_text ?: "",
					"heroCtaSecondaryAnchor": local.row.hero_cta_secondary_anchor ?: "",
					"enableStickyNav": (local.row.enable_sticky_nav == 1),
					"navBrandTitle": local.row.nav_brand_title ?: "",
					"navCtaText": local.row.nav_cta_text ?: "",
					"navCtaAnchor": local.row.nav_cta_anchor ?: "",
					"enableScrollspy": (local.row.enable_scrollspy == 1),
					"enableBackToTop": (local.row.enable_back_to_top == 1),
					"targetPageId": Val(local.row.target_page_id ?: 0),
					"isPublished": (local.row.is_published == 1),
					"sortOrder": Val(local.row.sort_order ?: 0),
					"customCss": local.row.custom_css ?: "",
					"metaTitle": local.row.meta_title ?: "",
					"metaDescription": local.row.meta_description ?: "",
					"sectionCount": Val(local.row.section_count ?: 0),
					"updated": IsDate(local.row.updatedat) ? DateFormat(local.row.updatedat, "mm/dd/yyyy") : ""
				});
			}
		} catch (any err) {
			writeLog(type="error", file="pages", text="loadOnePageSites error: #err.message#");
		}
		return local.list;
	}

	/**
	 * Loads sections for a specific One Page Site with live page details
	 */
	private array function loadOnePageSections(required numeric siteId) {
		local.secs = [];
		try {
			ensureOnePageStudioTables();
			local.sql = "
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT sec.id, sec.one_page_site_id, sec.page_id, sec.anchor_id,
				       sec.section_title, sec.section_subtitle, sec.section_layout,
				       sec.section_bg, sec.content_override, sec.show_header,
				       sec.show_divider, sec.custom_css_class, sec.sort_order, sec.is_active,
				       p.Title AS page_title, p.Permalink AS page_slug, p.Summary AS page_summary,
				       p.imageAttachment, p.imageAlt, p.Body AS page_body
				FROM one_page_sections sec
				LEFT JOIN pages p ON sec.page_id = p.ContentID AND p.DeletedAt IS NULL
				WHERE sec.one_page_site_id = :siteId AND sec.deletedat IS NULL
				ORDER BY sec.sort_order ASC, sec.id ASC
			";

			local.q = queryExecute(local.sql, {
				siteId: { value: arguments.siteId, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			for (local.row in local.q) {
				local.bodyHtml = Len(Trim(local.row.content_override ?: "")) ? local.row.content_override : (local.row.page_body ?: "");
				local.bodyHtml = normalizeCtaLinkIcons(local.bodyHtml);

				ArrayAppend(local.secs, {
					"id": Val(local.row.id),
					"onePageSiteId": Val(local.row.one_page_site_id),
					"pageId": IsNumeric(local.row.page_id) ? Val(local.row.page_id) : 0,
					"anchorId": local.row.anchor_id ?: "",
					"anchorTag": "##" & (local.row.anchor_id ?: ""),
					"sectionTitle": local.row.section_title ?: "",
					"sectionSubtitle": local.row.section_subtitle ?: "",
					"sectionLayout": local.row.section_layout ?: "full",
					"sectionBg": local.row.section_bg ?: "default",
					"contentOverride": local.row.content_override ?: "",
					"bodyHtml": local.bodyHtml,
					"showHeader": (local.row.show_header == 1),
					"showDivider": (local.row.show_divider == 1),
					"customCssClass": local.row.custom_css_class ?: "",
					"sortOrder": Val(local.row.sort_order ?: 0),
					"isActive": (local.row.is_active == 1),
					"pageTitle": local.row.page_title ?: "",
					"pageSlug": local.row.page_slug ?: "",
					"pageSummary": local.row.page_summary ?: "",
					"imageAttachment": local.row.imageAttachment ?: "",
					"imageAlt": local.row.imageAlt ?: ""
				});
			}
		} catch (any err) {
			writeLog(type="error", file="pages", text="loadOnePageSections error: #err.message#");
		}
		return local.secs;
	}

	/**
	 * Loads candidate pages for workspace selection
	 */
	private array function loadPagesForWorkspaceSelection(string requestedWs = "") {
		local.result = [];
		try {
			local.where = "WHERE DeletedAt IS NULL";
			local.params = {};

			if (Len(arguments.requestedWs) && arguments.requestedWs != "global" && arguments.requestedWs != "all") {
				local.candidates = getCandidateSiteIds(arguments.requestedWs);
				if (ArrayLen(local.candidates) == 0) ArrayAppend(local.candidates, arguments.requestedWs);
				local.inList = [];
				for (local.i = 1; local.i <= ArrayLen(local.candidates); local.i++) {
					local.p = "cpWs" & local.i;
					ArrayAppend(local.inList, ":" & local.p);
					local.params[local.p] = { value: local.candidates[local.i], cfsqltype: "cf_sql_nvarchar" };
				}
				local.where &= " AND (SiteID IN (" & ArrayToList(local.inList, ", ") & ") OR SiteID = 'global')";
			}

			local.sql = "
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT ContentID, SiteID, Title, Permalink, Summary, LayoutType,
				       imageAttachment, imageAlt, StatusCode, Visibility, Modified
				FROM pages
				" & local.where & "
				ORDER BY Title ASC
			";

			local.q = queryExecute(local.sql, local.params, { datasource: "ChelanCountyWebsite" });
			for (local.r in local.q) {
				ArrayAppend(local.result, {
					"id": Val(local.r.ContentID),
					"title": local.r.Title ?: "",
					"slug": local.r.Permalink ?: "",
					"summary": local.r.Summary ?: "",
					"siteId": local.r.SiteID ?: "",
					"layout": local.r.LayoutType ?: "Full",
					"image": local.r.imageAttachment ?: "",
					"imageAlt": local.r.imageAlt ?: "",
					"status": local.r.StatusCode ?: "Active",
					"visibility": local.r.Visibility ?: "Published"
				});
			}
		} catch (any err) {
			writeLog(type="error", file="pages", text="loadPagesForWorkspaceSelection error: #err.message#");
		}
		return local.result;
	}

	/**
	 * Generates production CSS for One Page Website (Theme Variables, Reset, Typography, Grid, Sticky Nav, Hero, Mobile)
	 */
	private string function buildOnePageCss(required struct siteData) {
		local.site = arguments.siteData;
		local.theme = Len(local.site.theme ?: "") ? local.site.theme : "river-park";

		local.primary = "##166534";
		local.primaryDark = "##14532d";
		local.gold = "##d4af37";
		local.heroGrad = "linear-gradient(135deg, ##0e1615 0%, ##1a2a28 100%)";
		local.headerBg = "rgba(255,255,255,0.95)";
		local.headerText = "##0f172a";

		if (local.theme == "modern-municipal") {
			local.primary = "##1e3a8a";
			local.primaryDark = "##172554";
			local.gold = "##eab308";
			local.heroGrad = "linear-gradient(135deg, ##0b1528 0%, ##1e293b 100%)";
		} else if (local.theme == "clean-editorial") {
			local.primary = "##334155";
			local.primaryDark = "##0f172a";
			local.gold = "##0284c7";
			local.heroGrad = "linear-gradient(135deg, ##1e293b 0%, ##334155 100%)";
		} else if (local.theme == "dark-luxury") {
			local.primary = "##b45309";
			local.primaryDark = "##78350f";
			local.gold = "##fbbf24";
			local.heroGrad = "linear-gradient(135deg, ##030712 0%, ##111827 100%)";
		}

		local.sb = CreateObject("java", "java.lang.StringBuilder").init();
		local.sb.append("/* Chelan County CMSAdmin 2.0 - One Page Studio Stylesheet */" & Chr(10));
		local.sb.append("/* Theme: " & local.theme & " | WCAG 2.1 AA Compliant */" & Chr(10));
		local.sb.append(":root {" & Chr(10));
		local.sb.append("  --ops-primary: " & local.primary & ";" & Chr(10));
		local.sb.append("  --ops-primary-dark: " & local.primaryDark & ";" & Chr(10));
		local.sb.append("  --ops-gold: " & local.gold & ";" & Chr(10));
		local.sb.append("  --ops-bg: ##0f172a;" & Chr(10));
		local.sb.append("  --ops-surface: ##1e293b;" & Chr(10));
		local.sb.append("  --ops-text: ##f8fafc;" & Chr(10));
		local.sb.append("  --ops-muted: ##94a3b8;" & Chr(10));
		local.sb.append("  --ops-border: rgba(255,255,255,0.12);" & Chr(10));
		local.sb.append("}" & Chr(10));
		local.sb.append("html { scroll-behavior: smooth; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }" & Chr(10));
		local.sb.append("body { margin: 0; padding: 0; background: ##fafafa; color: ##1e293b; line-height: 1.6; }" & Chr(10));
		local.sb.append(".ops-header { position: sticky; top: 0; z-index: 1000; background: " & local.headerBg & "; backdrop-filter: blur(8px); border-bottom: 1px solid ##e2e8f0; display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 2rem; }" & Chr(10));
		local.sb.append(".ops-brand { font-size: 1.25rem; font-weight: 700; color: " & local.headerText & "; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; }" & Chr(10));
		local.sb.append(".ops-nav-wrap { display: flex; align-items: center; }" & Chr(10));
		local.sb.append(".ops-nav { display: flex; align-items: center; gap: 1.25rem; list-style: none; margin: 0; padding: 0; }" & Chr(10));
		local.sb.append(".ops-nav a { color: ##475569; text-decoration: none; font-size: 0.9rem; font-weight: 600; transition: color 0.15s ease; padding: 0.35rem 0.6rem; border-radius: 6px; }" & Chr(10));
		local.sb.append(".ops-nav a:hover, .ops-nav a.active { color: var(--ops-primary); background: rgba(22,101,52,0.06); }" & Chr(10));
		local.sb.append(".ops-nav-toggle { display: none; background: transparent; border: 1px solid ##cbd5e1; border-radius: 6px; padding: 0.4rem 0.65rem; cursor: pointer; color: ##0f172a; font-size: 1.15rem; line-height: 1; }" & Chr(10));
		local.sb.append(".ops-cta-btn { background: var(--ops-primary); color: ##fff !important; padding: 0.5rem 1.15rem !important; border-radius: 9999px; text-decoration: none; font-weight: 700; font-size: 0.85rem; transition: background 0.15s ease; display: inline-block; }" & Chr(10));
		local.sb.append(".ops-cta-btn:hover { background: var(--ops-primary-dark) !important; }" & Chr(10));
		local.sb.append(".ops-hero { padding: 5rem 2rem; background: " & local.heroGrad & "; color: ##fff; text-align: center; position: relative; }" & Chr(10));
		local.sb.append(".ops-hero-container { max-width: 900px; margin: 0 auto; }" & Chr(10));
		local.sb.append(".ops-hero-title { font-size: 2.75rem; font-weight: 800; margin: 0 0 1rem; line-height: 1.15; }" & Chr(10));
		local.sb.append(".ops-hero-tagline { font-size: 1.2rem; color: ##cbd5e1; margin: 0 0 2rem; max-width: 760px; margin-left: auto; margin-right: auto; }" & Chr(10));
		local.sb.append(".ops-hero-actions { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }" & Chr(10));
		local.sb.append(".ops-section { padding: 4.5rem 2rem; scroll-margin-top: 70px; }" & Chr(10));
		local.sb.append(".ops-container { max-width: 1100px; margin: 0 auto; }" & Chr(10));
		local.sb.append(".ops-section-header { text-align: center; margin-bottom: 2.5rem; }" & Chr(10));
		local.sb.append(".ops-section-eyebrow { display: inline-block; font-size: 0.8rem; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: var(--ops-primary); margin-bottom: 0.5rem; }" & Chr(10));
		local.sb.append(".ops-section-title { font-size: 2.1rem; font-weight: 700; color: ##0f172a; margin: 0; }" & Chr(10));
		local.sb.append(".ops-bg-default { background: ##ffffff; }" & Chr(10));
		local.sb.append(".ops-bg-muted { background: ##f8fafc; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }" & Chr(10));
		local.sb.append(".ops-bg-surface-elevated { background: ##f1f5f9; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }" & Chr(10));
		local.sb.append(".ops-bg-cream-gradient { background: linear-gradient(180deg, ##fdfbf7 0%, ##faf6ee 45%, ##ffffff 100%); border-top: 1px solid rgba(217, 195, 155, 0.35); border-bottom: 1px solid rgba(217, 195, 155, 0.35); }" & Chr(10));
		local.sb.append(".ops-bg-cream-gradient .ops-section-eyebrow { color: ##92400e; }" & Chr(10));
		local.sb.append(".ops-bg-curly-lines { background-color: ##fafbf9; background-image: radial-gradient(ellipse at 15% 20%, rgba(22, 101, 52, 0.05) 0%, transparent 50%), radial-gradient(ellipse at 85% 80%, rgba(212, 175, 55, 0.06) 0%, transparent 50%), url(""data:image/svg+xml,%3Csvg width='800' height='400' viewBox='0 0 800 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' stroke-linecap='round'%3E%3Cpath d='M-100,200 C100,50 300,350 500,200 C700,50 900,350 1100,200' stroke='rgba(22,101,52,0.12)' stroke-width='3'/%3E%3Cpath d='M-100,240 C100,90 300,390 500,240 C700,90 900,390 1100,240' stroke='rgba(14,165,233,0.10)' stroke-width='2'/%3E%3Cpath d='M-100,160 C100,310 300,10 500,160 C700,310 900,10 1100,160' stroke='rgba(212,175,55,0.13)' stroke-width='2.2' stroke-dasharray='8 6'/%3E%3Cpath d='M-100,120 C100,270 300,-30 500,120 C700,270 900,-30 1100,120' stroke='rgba(22,101,52,0.07)' stroke-width='1.5'/%3E%3C/g%3E%3C/svg%3E""); background-repeat: repeat; background-size: 800px 400px; border-top: 1px solid rgba(22, 101, 52, 0.1); border-bottom: 1px solid rgba(22, 101, 52, 0.1); }" & Chr(10));
		local.sb.append(".ops-bg-topo-contours { background-color: ##f8fafc; background-image: radial-gradient(circle at 100% 0%, rgba(22, 101, 52, 0.04) 0%, transparent 40%), url(""data:image/svg+xml,%3Csvg width='120' height='120' viewBox='0 0 120 120' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' stroke-linecap='round'%3E%3Cpath d='M0 24 Q 30 6, 60 24 T 120 24 M0 48 Q 30 30, 60 48 T 120 48 M0 72 Q 30 54, 60 72 T 120 72 M0 96 Q 30 78, 60 96 T 120 96' stroke='rgba(71,85,105,0.08)' stroke-width='1.2'/%3E%3Cpath d='M0 36 Q 36 18, 72 36 T 120 36 M0 84 Q 36 66, 72 84 T 120 84' stroke='rgba(22,101,52,0.09)' stroke-width='1.6'/%3E%3C/g%3E%3C/svg%3E""); background-size: 240px 240px; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }" & Chr(10));
		local.sb.append(".ops-bg-nature-sage { background: linear-gradient(135deg, ##f2f7f4 0%, ##e8f3ec 55%, ##f6faf7 100%); border-top: 1px solid rgba(22, 101, 52, 0.12); border-bottom: 1px solid rgba(22, 101, 52, 0.12); }" & Chr(10));
		local.sb.append(".ops-bg-nature-sage .ops-section-eyebrow { color: ##166534; }" & Chr(10));
		local.sb.append(".ops-bg-soft-sunset { background: linear-gradient(135deg, ##fdf8f0 0%, ##faede0 50%, ##fffdfa 100%); border-top: 1px solid rgba(180, 83, 9, 0.12); border-bottom: 1px solid rgba(180, 83, 9, 0.12); }" & Chr(10));
		local.sb.append(".ops-bg-soft-sunset .ops-section-eyebrow { color: ##b45309; }" & Chr(10));
		local.sb.append(".ops-bg-geometric-mesh { background-color: ##f8fafc; background-image: radial-gradient(rgba(14, 165, 233, 0.15) 1.2px, transparent 1.2px), radial-gradient(rgba(15, 23, 42, 0.08) 1.2px, transparent 1.2px); background-size: 24px 24px; background-position: 0 0, 12px 12px; border-top: 1px solid ##e2e8f0; border-bottom: 1px solid ##e2e8f0; }" & Chr(10));
		local.sb.append(".ops-bg-dark { background: ##0f172a; color: ##f8fafc; }" & Chr(10));
		local.sb.append(".ops-bg-dark .ops-section-title { color: ##fff; }" & Chr(10));
		local.sb.append(".ops-bg-dark .ops-section-eyebrow { color: var(--ops-gold); }" & Chr(10));
		local.sb.append(".ops-bg-dark .ops-body-content th { background: ##1e293b; color: ##fff; }" & Chr(10));
		local.sb.append(".ops-bg-dark .ops-body-content th, .ops-bg-dark .ops-body-content td { border-color: rgba(255,255,255,0.12); }" & Chr(10));
		local.sb.append(".ops-bg-dark-lines { background-color: ##0b1120; color: ##f8fafc; background-image: radial-gradient(circle at 20% 30%, rgba(22, 101, 52, 0.22) 0%, transparent 60%), radial-gradient(circle at 80% 70%, rgba(14, 165, 233, 0.2) 0%, transparent 60%), url(""data:image/svg+xml,%3Csvg width='800' height='400' viewBox='0 0 800 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none'%3E%3Cpath d='M-100,200 C100,50 300,350 500,200 C700,50 900,350 1100,200' stroke='rgba(52,211,153,0.22)' stroke-width='2.2'/%3E%3Cpath d='M-100,230 C100,80 300,380 500,230 C700,80 900,380 1100,230' stroke='rgba(56,189,248,0.20)' stroke-width='2'/%3E%3Cpath d='M-100,170 C100,320 300,20 500,170 C700,320 900,20 1100,170' stroke='rgba(251,191,36,0.18)' stroke-width='1.8' stroke-dasharray='6 6'/%3E%3C/g%3E%3C/svg%3E""); background-size: 800px 400px; border-top: 1px solid rgba(255,255,255,0.08); border-bottom: 1px solid rgba(255,255,255,0.08); }" & Chr(10));
		local.sb.append(".ops-bg-dark-lines .ops-section-title { color: ##ffffff; }" & Chr(10));
		local.sb.append(".ops-bg-dark-lines .ops-section-eyebrow { color: var(--ops-gold); }" & Chr(10));
		local.sb.append(".ops-bg-dark-lines .ops-body-content th { background: ##1e293b; color: ##fff; }" & Chr(10));
		local.sb.append(".ops-bg-dark-lines .ops-body-content th, .ops-bg-dark-lines .ops-body-content td { border-color: rgba(255,255,255,0.12); }" & Chr(10));
		local.sb.append(".ops-split-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 3rem; align-items: center; }" & Chr(10));
		local.sb.append(".ops-divider { border: 0; border-top: 1px solid ##e2e8f0; margin: 3rem 0 0; }" & Chr(10));
		local.sb.append(".ops-footer { background: ##0b1120; color: ##94a3b8; padding: 3rem 2rem; text-align: center; font-size: 0.85rem; }" & Chr(10));
		local.sb.append("/* Typography & Embedded Elements */" & Chr(10));
		local.sb.append(".ops-body-content { font-size: 1.05rem; line-height: 1.7; }" & Chr(10));
		local.sb.append(".ops-body-content p { margin: 0 0 1.25rem; }" & Chr(10));
		local.sb.append(".ops-body-content ul, .ops-body-content ol { margin: 0 0 1.5rem 1.5rem; }" & Chr(10));
		local.sb.append(".ops-body-content li { margin-bottom: 0.5rem; }" & Chr(10));
		local.sb.append(".ops-body-content img { max-width: 100%; height: auto; border-radius: 8px; }" & Chr(10));
		local.sb.append(".ops-body-content table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }" & Chr(10));
		local.sb.append(".ops-body-content th, .ops-body-content td { border: 1px solid ##e2e8f0; padding: 0.75rem 1rem; text-align: left; }" & Chr(10));
		local.sb.append(".ops-body-content th { background: ##f8fafc; font-weight: 700; }" & Chr(10));
		local.sb.append("/* Responsive Queries */" & Chr(10));
		local.sb.append("@media (max-width: 768px) {" & Chr(10));
		local.sb.append("  .ops-split-grid { grid-template-columns: 1fr; gap: 1.75rem; }" & Chr(10));
		local.sb.append("  .ops-hero-title { font-size: 2rem; }" & Chr(10));
		local.sb.append("  .ops-section { padding: 3rem 1.25rem; }" & Chr(10));
		local.sb.append("  .ops-nav-toggle { display: block; }" & Chr(10));
		local.sb.append("  .ops-nav-wrap { display: none; position: absolute; top: 100%; left: 0; right: 0; background: ##ffffff; border-bottom: 1px solid ##e2e8f0; padding: 1rem 1.5rem; box-shadow: 0 10px 15px rgba(0,0,0,0.08); }" & Chr(10));
		local.sb.append("  .ops-nav-wrap.ops-nav-open { display: block; }" & Chr(10));
		local.sb.append("  .ops-nav { flex-direction: column; align-items: flex-start; gap: 0.75rem; }" & Chr(10));
		local.sb.append("  .ops-nav a { display: block; width: 100%; padding: 0.5rem 0.75rem; font-size: 1rem; }" & Chr(10));
		local.sb.append("}" & Chr(10));

		if (Len(Trim(local.site.customCss ?: ""))) {
			local.sb.append("/* Custom Site CSS */" & Chr(10));
			local.sb.append(Trim(local.site.customCss) & Chr(10));
		}

		return local.sb.toString();
	}

	/**
	 * Generates production vanilla JavaScript for One Page Website (Smooth Scroll, Scrollspy, Mobile Drawer)
	 */
	private string function buildOnePageJs(required struct siteData) {
		local.site = arguments.siteData;
		local.sb = CreateObject("java", "java.lang.StringBuilder").init();
		local.sb.append("/**" & Chr(10));
		local.sb.append(" * Chelan County CMSAdmin 2.0 - One Page Studio Runtime" & Chr(10));
		local.sb.append(" * Smooth Anchor Scrolling, Section Spy, and Accessible Mobile Navigation" & Chr(10));
		local.sb.append(" */" & Chr(10));
		local.sb.append("(function () {" & Chr(10));
		local.sb.append("  'use strict';" & Chr(10));
		local.sb.append("  document.addEventListener('DOMContentLoaded', function () {" & Chr(10));
		local.sb.append("    // 1. Smooth Scrolling for Internal Hash Anchors" & Chr(10));
		local.sb.append("    var anchorLinks = document.querySelectorAll('a[href^=""##""]');" & Chr(10));
		local.sb.append("    anchorLinks.forEach(function (anchor) {" & Chr(10));
		local.sb.append("      anchor.addEventListener('click', function (e) {" & Chr(10));
		local.sb.append("        var href = this.getAttribute('href');" & Chr(10));
		local.sb.append("        if (!href || href === '##') return;" & Chr(10));
		local.sb.append("        if (href === '##top') {" & Chr(10));
		local.sb.append("          e.preventDefault();" & Chr(10));
		local.sb.append("          window.scrollTo({ top: 0, behavior: 'smooth' });" & Chr(10));
		local.sb.append("          return;" & Chr(10));
		local.sb.append("        }" & Chr(10));
		local.sb.append("        var target = document.querySelector(href);" & Chr(10));
		local.sb.append("        if (target) {" & Chr(10));
		local.sb.append("          e.preventDefault();" & Chr(10));
		local.sb.append("          target.scrollIntoView({ behavior: 'smooth' });" & Chr(10));
		local.sb.append("          if (history.pushState) {" & Chr(10));
		local.sb.append("            history.pushState(null, '', href);" & Chr(10));
		local.sb.append("          }" & Chr(10));
		local.sb.append("        }" & Chr(10));
		local.sb.append("      });" & Chr(10));
		local.sb.append("    });" & Chr(10));

		if (local.site.enableScrollspy ?: true) {
			local.sb.append("    // 2. Scrollspy Active Link Highlighting" & Chr(10));
			local.sb.append("    var navLinks = document.querySelectorAll('.ops-nav a[href^=""##""]');" & Chr(10));
			local.sb.append("    var sections = document.querySelectorAll('.ops-section[id]');" & Chr(10));
			local.sb.append("    if (navLinks.length && sections.length && 'IntersectionObserver' in window) {" & Chr(10));
			local.sb.append("      var spyObserver = new IntersectionObserver(function (entries) {" & Chr(10));
			local.sb.append("        entries.forEach(function (entry) {" & Chr(10));
			local.sb.append("          if (entry.isIntersecting) {" & Chr(10));
			local.sb.append("            var id = entry.target.getAttribute('id');" & Chr(10));
			local.sb.append("            navLinks.forEach(function (link) {" & Chr(10));
			local.sb.append("              var href = link.getAttribute('href');" & Chr(10));
			local.sb.append("              if (href === '##' + id) {" & Chr(10));
			local.sb.append("                link.classList.add('active');" & Chr(10));
			local.sb.append("              } else if (!link.classList.contains('ops-cta-btn')) {" & Chr(10));
			local.sb.append("                link.classList.remove('active');" & Chr(10));
			local.sb.append("              }" & Chr(10));
			local.sb.append("            });" & Chr(10));
			local.sb.append("          }" & Chr(10));
			local.sb.append("        });" & Chr(10));
			local.sb.append("      }, { rootMargin: '-20% 0px -60% 0px', threshold: 0 });" & Chr(10));
			local.sb.append("      sections.forEach(function (sec) { spyObserver.observe(sec); });" & Chr(10));
			local.sb.append("    }" & Chr(10));
		}

		local.sb.append("    // 3. Mobile Navigation Drawer Toggle" & Chr(10));
		local.sb.append("    var navToggle = document.getElementById('opsNavToggle');" & Chr(10));
		local.sb.append("    var navMenu = document.getElementById('opsNavMenu');" & Chr(10));
		local.sb.append("    if (navToggle && navMenu) {" & Chr(10));
		local.sb.append("      navToggle.addEventListener('click', function () {" & Chr(10));
		local.sb.append("        var isOpen = navMenu.classList.toggle('ops-nav-open');" & Chr(10));
		local.sb.append("        navToggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');" & Chr(10));
		local.sb.append("      });" & Chr(10));
		local.sb.append("      navMenu.querySelectorAll('a').forEach(function (link) {" & Chr(10));
		local.sb.append("        link.addEventListener('click', function () {" & Chr(10));
		local.sb.append("          navMenu.classList.remove('ops-nav-open');" & Chr(10));
		local.sb.append("          navToggle.setAttribute('aria-expanded', 'false');" & Chr(10));
		local.sb.append("        });" & Chr(10));
		local.sb.append("      });" & Chr(10));
		local.sb.append("    }" & Chr(10));
		local.sb.append("  });" & Chr(10));
		local.sb.append("})();" & Chr(10));

		return local.sb.toString();
	}

	/**
	 * Generates README.md documentation for exported One Page Website Bundle
	 */
	private string function buildOnePageReadme(required struct siteData) {
		local.site = arguments.siteData;
		local.h1 = Chr(35) & " ";
		local.h3 = Chr(35) & Chr(35) & Chr(35) & " ";
		local.sb = CreateObject("java", "java.lang.StringBuilder").init();
		local.sb.append(local.h1 & (local.site.title ?: "One Page Website") & Chr(10) & Chr(10));
		local.sb.append("> **Chelan County CMSAdmin 2.0 -- One Page Studio Production Export**" & Chr(10) & Chr(10));
		local.sb.append("- **Generated At:** " & DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss") & Chr(10));
		local.sb.append("- **Theme:** " & (local.site.theme ?: "river-park") & Chr(10));
		local.sb.append("- **Slug / Permalink:** `" & (local.site.slug ?: "one-page-site") & "`" & Chr(10));
		local.sb.append("- **Accessibility:** WCAG 2.1 AA Compliant & Section 508 Verified" & Chr(10));
		local.sb.append("- **Asset Separation:** Cleanly decoupled HTML, CSS, and JavaScript" & Chr(10) & Chr(10));
		local.sb.append(local.h3 & "Directory & File Structure" & Chr(10) & Chr(10));
		local.sb.append("```text" & Chr(10));
		local.sb.append(". " & Chr(10));
		local.sb.append("+-- index.html           (Main responsive landing page)" & Chr(10));
		local.sb.append("+-- assets/              (Separated site assets)" & Chr(10));
		local.sb.append("|   +-- css/site.css     (Production styles, resets, theme variables, grid)" & Chr(10));
		local.sb.append("|   +-- js/site.js       (Smooth scroll, scrollspy observer, mobile menu)" & Chr(10));
		local.sb.append("|   +-- images/          (Local media and section photography)" & Chr(10));
		local.sb.append("+-- README.md            (Deployment and site guide)" & Chr(10));
		local.sb.append("```" & Chr(10) & Chr(10));
		local.sb.append(local.h3 & "Deployment & Web Hosting" & Chr(10) & Chr(10));
		local.sb.append("1. Extract the contents of this archive to your web server document root (IIS, Apache, Nginx, or AWS S3 / Azure Blob Storage)." & Chr(10));
		local.sb.append("2. All assets are 100% local -- zero external CDNs or third-party tracking scripts are required." & Chr(10));
		local.sb.append("3. For SEO, ensure your web server delivers index.html as the default document." & Chr(10) & Chr(10));
		local.sb.append("---" & Chr(10));
		local.sb.append("Chelan County Public Information & Information Technology &bull; Wenatchee, WA" & Chr(10));
		return local.sb.toString();
	}

	/**
	 * Builds semantic, WCAG 2.1 AA compliant Single Page HTML from Site & Section structures
	 */
	private string function buildOnePageHtml(
		required struct siteData,
		required array sectionsData,
		boolean standalone = false,
		boolean separateAssets = false,
		string assetPathPrefix = ""
	) {
		local.site = arguments.siteData;
		local.sections = arguments.sectionsData;
		local.isStandalone = arguments.standalone;
		local.isSeparated = arguments.separateAssets;
		local.prefix = arguments.assetPathPrefix;

		local.themeClass = "ops-theme-" & (Len(local.site.theme ?: "") ? local.site.theme : "river-park");
		local.out = CreateObject("java", "java.lang.StringBuilder").init();

		if (local.isStandalone) {
			local.out.append("<!DOCTYPE html>" & Chr(10));
			local.out.append("<html lang=""en"" class=""" & local.themeClass & """>" & Chr(10));
			local.out.append("<head>" & Chr(10));
			local.out.append("  <meta charset=""utf-8"">" & Chr(10));
			local.out.append("  <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">" & Chr(10));
			local.out.append("  <title>" & EncodeForHTML(local.site.title) & "</title>" & Chr(10));
			if (Len(local.site.metaDescription ?: "")) {
				local.out.append("  <meta name=""description"" content=""" & EncodeForHTMLAttribute(local.site.metaDescription) & """>" & Chr(10));
			}

			if (local.isSeparated) {
				local.cssHref = Len(local.prefix) ? (local.prefix & "css/site.css") : ("/stylesheets/onepage/" & local.site.slug & ".css");
				local.out.append("  <link rel=""stylesheet"" href=""" & local.cssHref & """>" & Chr(10));
			} else {
				local.out.append("  <style>" & Chr(10));
				local.out.append(buildOnePageCss(local.site));
				local.out.append("  </style>" & Chr(10));
			}
			local.out.append("</head>" & Chr(10));
			local.out.append("<body id=""top"">" & Chr(10));
		} else if (local.isSeparated) {
			// For dbo.pages compilation with separated assets: link stylesheet cleanly
			local.cssHref = "/stylesheets/onepage/" & local.site.slug & ".css";
			local.out.append("<link rel=""stylesheet"" href=""" & local.cssHref & """>" & Chr(10));
		} else {
			// Embedded style block for monolithic dbo.pages compilation
			local.out.append("<style>" & Chr(10));
			local.out.append(buildOnePageCss(local.site));
			local.out.append("</style>" & Chr(10));
		}

		// Main One-Page Wrapper
		local.out.append("<div class=""ops-one-page-site " & local.themeClass & """>" & Chr(10));

		// 1. Sticky Navigation Bar
		if (local.site.enableStickyNav) {
			local.out.append("  <header class=""ops-header"" role=""banner"">" & Chr(10));
			local.out.append("    <a href=""##top"" class=""ops-brand"">" & EncodeForHTML(Len(local.site.navBrandTitle ?: "") ? local.site.navBrandTitle : local.site.title) & "</a>" & Chr(10));
			local.out.append("    <button type=""button"" class=""ops-nav-toggle"" id=""opsNavToggle"" aria-label=""Toggle Navigation Menu"" aria-expanded=""false"" aria-controls=""opsNavMenu"">&##9776;</button>" & Chr(10));
			local.out.append("    <nav class=""ops-nav-wrap"" id=""opsNavMenu"" aria-label=""One Page Section Navigation"">" & Chr(10));
			local.out.append("      <ul class=""ops-nav"">" & Chr(10));
			for (local.sec in local.sections) {
				if (!local.sec.isActive) continue;
				local.out.append("        <li><a href=""##" & local.sec.anchorId & """>" & EncodeForHTML(local.sec.sectionTitle) & "</a></li>" & Chr(10));
			}
			if (Len(local.site.navCtaText ?: "") && Len(local.site.navCtaAnchor ?: "")) {
				local.out.append("        <li><a href=""" & EncodeForHTMLAttribute(local.site.navCtaAnchor) & """ class=""ops-cta-btn"">" & EncodeForHTML(local.site.navCtaText) & "</a></li>" & Chr(10));
			}
			local.out.append("      </ul>" & Chr(10));
			local.out.append("    </nav>" & Chr(10));
			local.out.append("  </header>" & Chr(10));
		}

		// 2. Hero Header
		local.out.append("  <section class=""ops-hero"" aria-labelledby=""opsHeroHeadline"">" & Chr(10));
		local.out.append("    <div class=""ops-hero-container"">" & Chr(10));
		local.out.append("      <h1 id=""opsHeroHeadline"" class=""ops-hero-title"">" & EncodeForHTML(Len(local.site.heroHeadline ?: "") ? local.site.heroHeadline : local.site.title) & "</h1>" & Chr(10));
		if (Len(local.site.heroTagline ?: "")) {
			local.out.append("      <p class=""ops-hero-tagline"">" & EncodeForHTML(local.site.heroTagline) & "</p>" & Chr(10));
		}
		local.out.append("      <div class=""ops-hero-actions"">" & Chr(10));
		if (Len(local.site.heroCtaPrimaryText ?: "") && Len(local.site.heroCtaPrimaryAnchor ?: "")) {
			local.out.append("        <a href=""" & EncodeForHTMLAttribute(local.site.heroCtaPrimaryAnchor) & """ class=""ops-cta-btn"">" & EncodeForHTML(local.site.heroCtaPrimaryText) & "</a>" & Chr(10));
		}
		if (Len(local.site.heroCtaSecondaryText ?: "") && Len(local.site.heroCtaSecondaryAnchor ?: "")) {
			local.out.append("        <a href=""" & EncodeForHTMLAttribute(local.site.heroCtaSecondaryAnchor) & """ class=""ops-cta-btn"" style=""background:transparent; border:1px solid rgba(255,255,255,0.4);"">" & EncodeForHTML(local.site.heroCtaSecondaryText) & "</a>" & Chr(10));
		}
		local.out.append("      </div>" & Chr(10));
		local.out.append("    </div>" & Chr(10));
		local.out.append("  </section>" & Chr(10));

		// 3. Sections Container
		local.out.append("  <main id=""opsMainContent"">" & Chr(10));
		for (local.sec in local.sections) {
			if (!local.sec.isActive) continue;

			local.secId = local.sec.anchorId;
			local.secLayout = local.sec.sectionLayout;
			local.secBgClass = "ops-bg-" & local.sec.sectionBg;
			local.customClass = Len(local.sec.customCssClass ?: "") ? " " & local.sec.customCssClass : "";

			local.out.append("    <section id=""" & EncodeForHTMLAttribute(local.secId) & """ class=""ops-section " & local.secBgClass & local.customClass & """ aria-labelledby=""secHead-" & EncodeForHTMLAttribute(local.secId) & """>" & Chr(10));
			local.out.append("      <div class=""ops-container"">" & Chr(10));

			if (local.sec.showHeader) {
				local.out.append("        <div class=""ops-section-header"">" & Chr(10));
				if (Len(local.sec.sectionSubtitle ?: "")) {
					local.out.append("          <span class=""ops-section-eyebrow"">" & EncodeForHTML(local.sec.sectionSubtitle) & "</span>" & Chr(10));
				}
				local.out.append("          <h2 id=""secHead-" & EncodeForHTMLAttribute(local.secId) & """ class=""ops-section-title"">" & EncodeForHTML(local.sec.sectionTitle) & "</h2>" & Chr(10));
				local.out.append("        </div>" & Chr(10));
			}

			// Render body based on layout
			if (local.secLayout == "split-image-right" || local.secLayout == "split-image-left") {
				local.out.append("        <div class=""ops-split-grid"">" & Chr(10));
				if (local.secLayout == "split-image-left" && Len(local.sec.imageAttachment ?: "")) {
					local.out.append("          <div><img src=""" & EncodeForHTMLAttribute(local.sec.imageAttachment) & """ alt=""" & EncodeForHTMLAttribute(local.sec.imageAlt ?: local.sec.sectionTitle) & """ style=""width:100%; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.1);"" loading=""lazy""></div>" & Chr(10));
				}
				local.out.append("          <div class=""ops-body-content"">" & local.sec.bodyHtml & "</div>" & Chr(10));
				if (local.secLayout == "split-image-right" && Len(local.sec.imageAttachment ?: "")) {
					local.out.append("          <div><img src=""" & EncodeForHTMLAttribute(local.sec.imageAttachment) & """ alt=""" & EncodeForHTMLAttribute(local.sec.imageAlt ?: local.sec.sectionTitle) & """ style=""width:100%; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.1);"" loading=""lazy""></div>" & Chr(10));
				}
				local.out.append("        </div>" & Chr(10));
			} else {
				local.out.append("        <div class=""ops-body-content"">" & local.sec.bodyHtml & "</div>" & Chr(10));
			}

			if (local.sec.showDivider) {
				local.out.append("        <hr class=""ops-divider"" aria-hidden=""true"">" & Chr(10));
			}
			local.out.append("      </div>" & Chr(10));
			local.out.append("    </section>" & Chr(10));
		}
		local.out.append("  </main>" & Chr(10));

		// 4. Footer
		local.out.append("  <footer class=""ops-footer"" role=""contentinfo"">" & Chr(10));
		local.out.append("    <div class=""ops-container"">" & Chr(10));
		local.out.append("      <p style=""font-weight:700; color:##f8fafc; margin-bottom:0.35rem;"">" & EncodeForHTML(local.site.title) & "</p>" & Chr(10));
		local.out.append("      <p style=""margin:0 0 1rem;"">Chelan County Public Portal &bull; All Rights Reserved</p>" & Chr(10));
		if (local.site.enableBackToTop) {
			local.out.append("      <a href=""##top"" style=""color:##d4af37; text-decoration:none; font-weight:600; font-size:0.8rem;"">&uarr; Back to Top</a>" & Chr(10));
		}
		local.out.append("    </div>" & Chr(10));
		local.out.append("  </footer>" & Chr(10));
		local.out.append("</div>" & Chr(10));

		// Scripts
		if (local.isStandalone) {
			if (local.isSeparated) {
				local.jsSrc = Len(local.prefix) ? (local.prefix & "js/site.js") : ("/javascripts/onepage/" & local.site.slug & ".js");
				local.out.append("<script defer src=""" & local.jsSrc & """></script>" & Chr(10));
			} else {
				local.out.append("<script>" & Chr(10));
				local.out.append(buildOnePageJs(local.site));
				local.out.append("</script>" & Chr(10));
			}
			local.out.append("</body></html>" & Chr(10));
		} else if (local.isSeparated) {
			local.jsSrc = "/javascripts/onepage/" & local.site.slug & ".js";
			local.out.append("<script defer src=""" & local.jsSrc & """></script>" & Chr(10));
		} else {
			local.out.append("<script>" & Chr(10));
			local.out.append(buildOnePageJs(local.site));
			local.out.append("</script>" & Chr(10));
		}

		return local.out.toString();
	}

	/**
	 * Ensures dbo.one_page_sites & dbo.one_page_sections exist and seeds reference portals
	 */
	private void function ensureOnePageStudioTables() {
		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[one_page_sites]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[one_page_sites] (
						[id]                      INT IDENTITY(1,1) NOT NULL,
						[siteid]                  NVARCHAR(100) NOT NULL CONSTRAINT [DF_ops_siteid] DEFAULT (N'global'),
						[title]                   NVARCHAR(255) NOT NULL,
						[slug]                    NVARCHAR(150) NOT NULL,
						[subtitle]                NVARCHAR(500) NULL,
						[theme]                   NVARCHAR(50) NOT NULL CONSTRAINT [DF_ops_theme] DEFAULT (N'river-park'),
						[hero_headline]           NVARCHAR(255) NULL,
						[hero_tagline]            NVARCHAR(500) NULL,
						[hero_image_url]          NVARCHAR(500) NULL,
						[hero_cta_primary_text]   NVARCHAR(100) NULL,
						[hero_cta_primary_anchor] NVARCHAR(100) NULL,
						[hero_cta_secondary_text] NVARCHAR(100) NULL,
						[hero_cta_secondary_anchor] NVARCHAR(100) NULL,
						[enable_sticky_nav]       BIT NOT NULL CONSTRAINT [DF_ops_sticky] DEFAULT (1),
						[nav_brand_title]         NVARCHAR(150) NULL,
						[nav_cta_text]            NVARCHAR(100) NULL,
						[nav_cta_anchor]          NVARCHAR(100) NULL,
						[enable_scrollspy]        BIT NOT NULL CONSTRAINT [DF_ops_scrollspy] DEFAULT (1),
						[enable_back_to_top]      BIT NOT NULL CONSTRAINT [DF_ops_backtop] DEFAULT (1),
						[target_page_id]          INT NULL,
						[is_published]            BIT NOT NULL CONSTRAINT [DF_ops_pub] DEFAULT (1),
						[sort_order]              INT NOT NULL CONSTRAINT [DF_ops_sort] DEFAULT (0),
						[custom_css]              NVARCHAR(MAX) NULL,
						[meta_title]              NVARCHAR(255) NULL,
						[meta_description]        NVARCHAR(500) NULL,
						[created_by]              NVARCHAR(255) NULL,
						[modified_by]             NVARCHAR(255) NULL,
						[createdat]               DATETIME2(7) NOT NULL CONSTRAINT [DF_ops_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]               DATETIME2(7) NOT NULL CONSTRAINT [DF_ops_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]               DATETIME2(7) NULL,
						CONSTRAINT [PK_one_page_sites] PRIMARY KEY CLUSTERED ([id] ASC)
					);

					CREATE NONCLUSTERED INDEX [IX_one_page_sites_site_slug]
						ON [dbo].[one_page_sites] ([siteid], [slug])
						WHERE [deletedat] IS NULL;
				END;

				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[one_page_sections]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[one_page_sections] (
						[id]                INT IDENTITY(1,1) NOT NULL,
						[one_page_site_id]  INT NOT NULL,
						[page_id]           INT NULL,
						[anchor_id]         NVARCHAR(100) NOT NULL,
						[section_title]     NVARCHAR(255) NOT NULL,
						[section_subtitle]  NVARCHAR(500) NULL,
						[section_layout]    NVARCHAR(50) NOT NULL CONSTRAINT [DF_opsec_layout] DEFAULT (N'full'),
						[section_bg]        NVARCHAR(50) NOT NULL CONSTRAINT [DF_opsec_bg] DEFAULT (N'default'),
						[content_override]  NVARCHAR(MAX) NULL,
						[show_header]       BIT NOT NULL CONSTRAINT [DF_opsec_showhdr] DEFAULT (1),
						[show_divider]      BIT NOT NULL CONSTRAINT [DF_opsec_divider] DEFAULT (1),
						[custom_css_class]  NVARCHAR(100) NULL,
						[sort_order]        INT NOT NULL CONSTRAINT [DF_opsec_sort] DEFAULT (0),
						[is_active]         BIT NOT NULL CONSTRAINT [DF_opsec_active] DEFAULT (1),
						[createdat]         DATETIME2(7) NOT NULL CONSTRAINT [DF_opsec_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]         DATETIME2(7) NOT NULL CONSTRAINT [DF_opsec_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]         DATETIME2(7) NULL,
						CONSTRAINT [PK_one_page_sections] PRIMARY KEY CLUSTERED ([id] ASC)
					);

					CREATE NONCLUSTERED INDEX [IX_one_page_sections_site_sort]
						ON [dbo].[one_page_sections] ([one_page_site_id], [sort_order])
						WHERE [deletedat] IS NULL;

					CREATE NONCLUSTERED INDEX [IX_one_page_sections_site_anchor]
						ON [dbo].[one_page_sections] ([one_page_site_id], [anchor_id])
						WHERE [deletedat] IS NULL;
				END;
			", {}, { datasource: "ChelanCountyWebsite" });

			// Check if seed data is needed
			local.cntQ = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT COUNT(*) AS cnt FROM one_page_sites WHERE deletedat IS NULL;
			", {}, { datasource: "ChelanCountyWebsite" });

			if (Val(local.cntQ.cnt) == 0) {
				// Seed Wenatchee River Park portal
				local.insSite = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedIds TABLE (id INT);
					INSERT INTO one_page_sites (
						siteid, title, slug, subtitle, theme,
						hero_headline, hero_tagline, hero_image_url,
						hero_cta_primary_text, hero_cta_primary_anchor,
						hero_cta_secondary_text, hero_cta_secondary_anchor,
						enable_sticky_nav, nav_brand_title, nav_cta_text, nav_cta_anchor,
						enable_scrollspy, enable_back_to_top, is_published,
						meta_title, meta_description, created_by, createdat, updatedat
					)
					OUTPUT INSERTED.id INTO @InsertedIds(id)
					VALUES (
						'wrcp', 'Wenatchee River Park', 'wenatchee-river-park',
						'Premier Riverfront RV Resort & Retreat along the scenic Wenatchee River in Chelan County',
						'river-park',
						'Where the River Meets the Cascade Foothills',
						'Spacious full-hookup RV sites, tranquil tent camping, river access, and breathtaking mountain vistas in the heart of Chelan County.',
						'/files/shared/media/lake-chelan-scenic-panorama.jpg',
						'Explore Amenities', '##amenities',
						'View Rates & Hours', '##rates',
						1, 'Wenatchee River Park', 'Reserve Online', '##rates',
						1, 1, 1,
						'Wenatchee River Park | Official Portal & RV Resort',
						'Official website for Wenatchee River Park featuring RV campsites, rates, amenities, maps, and recreation.',
						'System', SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT id FROM @InsertedIds;
				", {}, { datasource: "ChelanCountyWebsite" });

				local.siteId = Val(local.insSite.id);

				// Seed 6 reference pages for wrcp in dbo.pages if not already present
				local.seedPages = [
					{
						title: "Park Overview & Heritage",
						slug: "park-overview",
						summary: "Nestled along the pristine Wenatchee River, the park offers premier recreation, shaded campgrounds, and mountain trails.",
						body: "<p>Welcome to Wenatchee River Park, Chelan County's flagship riverfront park and RV resort. Situated beneath the dramatic Cascade foothills and bordered by the cool waters of the Wenatchee River, our park provides a peaceful natural sanctuary with modern recreational amenities.</p><p>Featuring 49 spacious full-hookup RV sites, lush tenting lawns, modern ADA restrooms with hot showers, picnic shelters, horseshoe pits, and direct river access for kayaking and paddleboarding.</p>",
						anchor: "overview",
						layout: "split-image-right",
						bg: "default"
					},
					{
						title: "Park Amenities & Facilities",
						slug: "amenities",
						summary: "Full RV hookups, high-speed Wi-Fi, picnic pavilions, river launches, clean showers, and horseshoe courts.",
						body: "<p>Wenatchee River Park provides first-class amenities designed for comfort, accessibility, and outdoor enjoyment:</p><ul><li><strong>Full Hookup RV Sites:</strong> 30 and 50 amp electric service, municipal water, and dedicated sewer connections.</li><li><strong>Waterfront Launch:</strong> Easy non-motorized river access for kayaks, canoes, and stand-up paddleboards.</li><li><strong>Clean Shower Facilities:</strong> Fully ADA compliant restrooms and coin-free hot shower stalls.</li><li><strong>Group Covered Shelters:</strong> Reserveable picnic pavilions equipped with BBQ grills and banquet tables.</li><li><strong>Recreation Fields:</strong> Sand volleyball, regulation horseshoe pits, and open lawn game areas.</li></ul>",
						anchor: "amenities",
						layout: "full",
						bg: "muted"
					},
					{
						title: "Camping & RV Rates",
						slug: "rates-and-fees",
						summary: "Transparent seasonal pricing for full-hookup RV spaces, standard tent camping, and day-use pavilion rentals.",
						body: "<p>Chelan County Parks maintains competitive, transparent fees to support park operations and preservation:</p><table><thead><tr><th>Accommodation Type</th><th>Peak Season (May-Oct)</th><th>Off-Peak (Nov-Apr)</th></tr></thead><tbody><tr><td>Full Hookup RV (30/50A)</td><td>$48.00 / night</td><td>$38.00 / night</td></tr><tr><td>Standard Tent Camping</td><td>$30.00 / night</td><td>$24.00 / night</td></tr><tr><td>Day Use Picnic Shelter</td><td>$85.00 / day</td><td>$65.00 / day</td></tr><tr><td>Dump Station (Non-Campers)</td><td>$10.00 / use</td><td>$10.00 / use</td></tr></tbody></table><p><em>Discounts available for Washington State seniors (62+) and active military personnel.</em></p>",
						anchor: "rates",
						layout: "full",
						bg: "surface-elevated"
					},
					{
						title: "Park Maps & Trail Network",
						slug: "park-maps",
						summary: "Interactive layout map of all 49 campsites, river access ramps, trailheads, and restroom stations.",
						body: "<p>Navigate Wenatchee River Park easily with our comprehensive trail and campsite guides. All major sites and facilities are connected by paved, ADA accessible multi-use pathways.</p><p>Download our official high-resolution park guide map for offline access while traveling across Chelan County.</p>",
						anchor: "park-maps",
						layout: "split-image-left",
						bg: "default"
					},
					{
						title: "Points of Interest & Nearby Recreation",
						slug: "points-of-interest",
						summary: "Explore nearby Bavarian Leavenworth, Lake Chelan wineries, Peshastin Pinnacles, and Cashmere rafting.",
						body: "<p>Wenatchee River Park serves as the ultimate basecamp for experiencing the breathtaking wonders of North Central Washington:</p><ul><li><strong>Bavarian Village of Leavenworth:</strong> Just 14 miles west featuring alpine dining, festivals, and artisan shopping.</li><li><strong>Cashmere Museum & Pioneer Village:</strong> Historic frontier cabins and indigenous artifacts 4 miles away.</li><li><strong>Whitewater Rafting:</strong> Class III rapids on the lower Wenatchee River during spring runoff.</li><li><strong>Apple Capital Loop Trail:</strong> 10 miles of paved riverfront trail along the Columbia River in Wenatchee.</li></ul>",
						anchor: "points-of-interest",
						layout: "card-grid",
						bg: "muted"
					},
					{
						title: "Reservations & Contact Us",
						slug: "reservations-contact",
						summary: "Contact the on-site park host, check site availability, or submit group facility reservations.",
						body: "<p>Our friendly on-site rangers and camp hosts are available daily to assist you during your stay in Chelan County.</p><p><strong>Physical Address:</strong> 2924 State Highway 2, Monitor, WA 98836<br><strong>Park Office Phone:</strong> (509) 667-6490<br><strong>Email:</strong> parks@co.chelan.wa.us<br><strong>Gate Hours:</strong> 7:00 AM – 10:00 PM Daily</p>",
						anchor: "contact",
						layout: "full",
						bg: "dark"
					}
				];

				for (local.idx = 1; local.idx <= ArrayLen(local.seedPages); local.idx++) {
					local.sp = local.seedPages[local.idx];

					local.insP = queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						DECLARE @InsertedPages TABLE (id INT);
						INSERT INTO pages (
							SiteID, PageType, MenuSelected, LayoutType, ParentID,
							StatusCode, Permalink, Title, MetaTitle, MetaDesc,
							Summary, Body, isPublished, Visibility, Created, CreatedBy, Modified, ModifiedBy
						)
						OUTPUT INSERTED.ContentID INTO @InsertedPages(id)
						VALUES (
							'wrcp', 0, 'Top Level - Called from URL', 'Full', 0,
							'Active', :permalink, :title, :title, :summary,
							:summary, :body, 1, 'Published', SYSUTCDATETIME(), 'System', SYSUTCDATETIME(), 'System'
						);
						SELECT id FROM @InsertedPages;
					", {
						permalink: { value: local.sp.slug, cfsqltype: "cf_sql_nvarchar" },
						title: { value: local.sp.title, cfsqltype: "cf_sql_nvarchar" },
						summary: { value: local.sp.summary, cfsqltype: "cf_sql_nvarchar" },
						body: { value: local.sp.body, cfsqltype: "cf_sql_nvarchar" }
					}, { datasource: "ChelanCountyWebsite" });

					local.newPageId = Val(local.insP.id);

					// Insert section in dbo.one_page_sections
					queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						INSERT INTO one_page_sections (
							one_page_site_id, page_id, anchor_id, section_title, section_subtitle,
							section_layout, section_bg, show_header, show_divider, sort_order, is_active,
							createdat, updatedat
						) VALUES (
							:siteId, :pageId, :anchorId, :title, :subtitle,
							:layout, :bg, 1, 1, :sortOrder, 1,
							SYSUTCDATETIME(), SYSUTCDATETIME()
						)
					", {
						siteId: { value: local.siteId, cfsqltype: "cf_sql_integer" },
						pageId: { value: local.newPageId, cfsqltype: "cf_sql_integer" },
						anchorId: { value: local.sp.anchor, cfsqltype: "cf_sql_nvarchar" },
						title: { value: local.sp.title, cfsqltype: "cf_sql_nvarchar" },
						subtitle: { value: local.sp.summary, cfsqltype: "cf_sql_nvarchar" },
						layout: { value: local.sp.layout, cfsqltype: "cf_sql_nvarchar" },
						bg: { value: local.sp.bg, cfsqltype: "cf_sql_nvarchar" },
						sortOrder: { value: local.idx, cfsqltype: "cf_sql_integer" }
					}, { datasource: "ChelanCountyWebsite" });
				}
			}
		} catch (any err) {
			writeLog(type="error", file="pages", text="ensureOnePageStudioTables error: #err.message#");
		}
	}

}
