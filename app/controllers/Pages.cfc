component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="save,createModal,saveSubpage,deleteSubpage,saveFolderExplorer,deleteFolderExplorer,saveHowDoIItem,deleteHowDoIItem,reorderHowDoIItems,saveHowDoICategory,deleteHowDoICategory,restoreRevision,snapshotRevision");
	}

	/**
	 * All Pages listing (reads from database with fallback to sample pages)
	 */
	function index() {
		variables.pageTitle = "All Pages";
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
		local.all = loadPagesList();
		variables.page = {
			id: 0, title: "", slug: "", siteId: activeWorkspaceId(), menuItem: false, status: "Active", visibility: "Published",
			parent: "", layout: "Full", sidebarIds: [], updated: "", author: "", locked: false, summary: "", body: "", content: "",
			metaTitle: "", metaDesc: "", metaKeywords: "", hasArchive: false
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
		variables.availableSubpages = loadSubpages(contentId=variables.page.id, requestedWs=local.editSiteId, assignedIds=variables.page.sidebarIds);
		variables.availableSidebars = [];
		variables.availableFolders = loadFolderExplorers(contentId=variables.page.id, requestedWs=local.editSiteId);
		variables.menuItemOptions = loadMenuItemOptions(requestedWs=local.editSiteId, currentSelected=variables.page.parent);
		variables.availableForms = loadWorkspaceForms(requestedWs=local.editSiteId);

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
				INSERT INTO pages (
					SiteID, PageType, MenuSelected, LayoutType, ParentID,
					StatusCode, Permalink, Title, MetaTitle, MetaDesc, MetaKeyWords,
					Summary, Body, isService, hasArchive, ShowInMenu, isLocked,
					isPublished, Visibility, ViewCount, Created, CreatedBy, Modified, ModifiedBy
				)
				OUTPUT INSERTED.ContentID AS newId
				VALUES (
					:siteId, 0, '', :layout, 0,
					'Active', :slug, :title, :title, '', '',
					'', '', 0, 0, 0, 0,
					0, 'Draft', 0, SYSUTCDATETIME(), :actor, SYSUTCDATETIME(), :actor
				)
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
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.id = Val(local.req.id ?: 0);
		local.title = Left(Trim(local.req.title ?: ""), 255);
		local.slug = slugifyText(local.req.slug ?: (local.req.permalink ?: ""));
		local.content = local.req.content ?: (local.req.body ?: "");
		local.metaTitle = Left(Trim(local.req.metaTitle ?: ""), 255);
		local.metaDesc = Trim(local.req.metaDescription ?: (local.req.metaDesc ?: ""));
		local.metaKeywords = Trim(local.req.metaKeywords ?: (local.req.metaKeyWords ?: ""));
		local.status = Trim(local.req.status ?: "Active");
		local.visibility = Trim(local.req.visibility ?: "Published");
		local.hasPublishAt = StructKeyExists(local.req, "publishAt") && Len(Trim(local.req.publishAt)) && IsDate(local.req.publishAt);
		local.publishAtDate = local.hasPublishAt ? ParseDateTime(local.req.publishAt) : "";
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

		if (local.id <= 0) {
			fxRenderJson({ success: false, SUCCESS: false, message: "Valid page ID is required." }, 400);
			return;
		}
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
			// Retrieve existing record to check site, lock status, and avoid collisions
			local.curPageQ = queryExecute("
				SELECT SiteID, isLocked, isService, imageAttachment, imageAttribution, imageAlt, imageTitle, imageDescription
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
			local.imageAttachment = StructKeyExists(local.req, "imageAttachment") ? Trim(local.req.imageAttachment) : (local.curPageQ.imageAttachment ?: "");
			local.imageAttribution = StructKeyExists(local.req, "imageAttribution") ? Trim(local.req.imageAttribution) : (local.curPageQ.imageAttribution ?: "");
			local.imageAlt = StructKeyExists(local.req, "imageAlt") ? Trim(local.req.imageAlt) : (local.curPageQ.imageAlt ?: "");
			local.imageTitle = StructKeyExists(local.req, "imageTitle") ? Trim(local.req.imageTitle) : (local.curPageQ.imageTitle ?: "");
			local.imageDescription = StructKeyExists(local.req, "imageDescription") ? Trim(local.req.imageDescription) : (local.curPageQ.imageDescription ?: "");

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
				    SidebarIDs = :sidebarIds,
				    Modified = SYSUTCDATETIME(),
				    ModifiedBy = :actor
				WHERE ContentID = :id
			", {
				title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
				slug: { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
				body: { value: local.content, cfsqltype: "cf_sql_longvarchar" },
				metaTitle: { value: local.metaTitle, cfsqltype: "cf_sql_nvarchar" },
				metaDesc: { value: local.metaDesc, cfsqltype: "cf_sql_nvarchar" },
				metaKeywords: { value: local.metaKeywords, cfsqltype: "cf_sql_nvarchar" },
				status: { value: local.status, cfsqltype: "cf_sql_nvarchar" },
				visibility: { value: local.visibility, cfsqltype: "cf_sql_nvarchar" },
				publishAt: local.hasPublishAt ? { value: local.publishAtDate, cfsqltype: "cf_sql_timestamp" } : { null: true, cfsqltype: "cf_sql_timestamp" },
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
				imageDescription: { value: local.imageDescription, cfsqltype: "cf_sql_longvarchar" },
				sidebarIds: { value: local.sidebarJson, cfsqltype: "cf_sql_nvarchar" },
				actor: { value: local.actor, cfsqltype: "cf_sql_nvarchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			// Sync checked Folder Explorer items for this page
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
					queryExecute("
						UPDATE page_FolderExplorer SET ContentID = 0 WHERE ContentID = :pageId
					", { pageId: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
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
						UPDATE page_FolderExplorer SET ContentID = 0 WHERE ContentID = :pageId AND ID NOT IN (" & local.fInClause & ");
						UPDATE page_FolderExplorer SET ContentID = :pageId WHERE ID IN (" & local.fInClause & ");
					", local.fParams, { datasource: "ChelanCountyWebsite" });
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
			absolutePath: StructKeyExists(params, "absolutePath") ? Trim(params.absolutePath) : "C:\inetpub\CMSAdmin2.0\files\assessors",
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
					INSERT INTO page_FolderExplorer (ContentID, SiteID, Title, RelativePath, AbsolutePath, Absolute, Weight, Layout)
					OUTPUT INSERTED.ID AS newId
					SELECT :contentId, :siteId, :title, :rel, :abs, :isAbs, ISNULL(MAX(Weight), 0) + 1, :layoutValue
					FROM page_FolderExplorer WHERE SiteID IN (" & local.siteInClause & ")
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
					INSERT INTO page_SubPage (ContentID, SiteID, Title, Body, Position, CreatedAt, CreatedBy)
					OUTPUT INSERTED.ID AS newId
					VALUES (:contentId, :siteId, :title, :body, :position, SYSDATETIME(), :actor)
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
		renderText(text=SerializeJSON(arguments.data), contentType="application/json", layout=false, status=arguments.status);
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
				       isService, hasArchive, ShowInMenu, isLocked, SidebarIDs, SortOrder,
				       isPublished, Visibility, PublishAt, ViewCount, Created, CreatedBy, Modified, ModifiedBy
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
					isPublished: (local.row.isPublished == 1),
					menuItem: (local.row.ShowInMenu == 1),
					locked: (local.row.isLocked == 1),
					summary: local.row.Summary ?: "",
					body: local.row.Body ?: "",
					content: local.row.Body ?: "",
					metaTitle: local.row.MetaTitle ?: "",
					metaDesc: local.row.MetaDesc ?: "",
					metaKeywords: local.row.MetaKeyWords ?: "",
					sidebarIds: local.sidebarList,
					author: Len(local.row.ModifiedBy) ? local.row.ModifiedBy : (local.row.CreatedBy ?: "Admin"),
					updated: local.updatedStr,
					hasArchive: (local.row.hasArchive == 1)
				};
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
					"metaKeywords": local.metaKeywords
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
				       SortOrder, isPublished, Visibility, PublishAt, Created, CreatedBy, Modified, ModifiedBy
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
				"siteId": local.pageQ.SiteID ?: "global"
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
				body: { value: local.pageQ.Body ?: "", cfsqltype: "cf_sql_longvarchar" },
				summary: { value: local.pageQ.Summary ?: "", cfsqltype: "cf_sql_longvarchar" },
				layout: { value: local.pageQ.LayoutType ?: "Full", cfsqltype: "cf_sql_nvarchar" },
				metaJson: { value: SerializeJSON(local.metaStruct), cfsqltype: "cf_sql_longvarchar" },
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
					INSERT INTO how_do_i_items (
						category_id, siteid, question, destination_type, page_id, form_id,
						destination_url, open_in_new_tab, is_featured_mega_menu, sort_order,
						is_published, created_by, modified_by, createdat, updatedat
					)
					OUTPUT INSERTED.id AS newId
					VALUES (
						:catId, :siteId, :question, :dtype, :pageId, :formId,
						:durl, :newTab, :mega, :sortOrder,
						:pub, :actor, :actor, SYSUTCDATETIME(), SYSUTCDATETIME()
					)
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
					INSERT INTO how_do_i_categories (name, slug, icon, description, sort_order, is_active, is_system, createdat, updatedat)
					OUTPUT INSERTED.id AS newId
					VALUES (:name, :slug, :icon, :desc, :sortOrder, :isActive, 0, SYSUTCDATETIME(), SYSUTCDATETIME())
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
	 * Ensures dbo.how_do_i_categories and dbo.how_do_i_items exist and are seeded with the 12 standard Chelan County categories and initial county links.
	 */
	private void function ensureHowDoITables() {
		try {
			queryExecute("
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
			", {}, { datasource: "ChelanCountyWebsite" });

			// Seed the 12 standard Chelan County categories if table is empty
			local.catCheck = queryExecute("SELECT COUNT(*) AS cnt FROM how_do_i_categories WHERE deletedat IS NULL", {}, { datasource: "ChelanCountyWebsite" });
			if (Val(local.catCheck.cnt) == 0) {
				queryExecute("
					INSERT INTO how_do_i_categories (name, slug, icon, description, sort_order, is_active, is_system)
					VALUES
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
				", {}, { datasource: "ChelanCountyWebsite" });
			}

			// Seed initial authentic Chelan County "How Do I" links if how_do_i_items is completely empty
			local.itemCheck = queryExecute("SELECT COUNT(*) AS cnt FROM how_do_i_items", {}, { datasource: "ChelanCountyWebsite" });
			if (Val(local.itemCheck.cnt) == 0) {
				local.catRows = queryExecute("SELECT id, slug FROM how_do_i_categories WHERE deletedat IS NULL", {}, { datasource: "ChelanCountyWebsite" });
				local.catMap = {};
				for (local.cr in local.catRows) {
					local.catMap[local.cr.slug] = local.cr.id;
				}

				local.seedItems = [
					// Apply For
					{ cat: "apply-for", site: "human-resources", q: "A Job", type: "custom", url: "/human-resources/jobs", newTab: 0, mega: 1, sort: 10 },
					{ cat: "apply-for", site: "public-works", q: "A New Address", type: "page", url: "/public-works/pages/addressing-and-road-naming", newTab: 0, mega: 1, sort: 20 },
					{ cat: "apply-for", site: "public-works", q: "Adopt a County Road Program", type: "page", url: "/solid-waste-management/pages/adopt-a-county-road", newTab: 0, mega: 1, sort: 30 },
					{ cat: "apply-for", site: "community-development", q: "Building Permit", type: "page", url: "/community-development/pages/building", newTab: 0, mega: 1, sort: 40 },
					{ cat: "apply-for", site: "sheriff", q: "Concealed Pistol License (CPL)", type: "external", url: "https://chelanwa.permitium.com/ccw/start", newTab: 1, mega: 1, sort: 50 },
					{ cat: "apply-for", site: "public-works", q: "Driveway Permit", type: "page", url: "/public-works/pages/development", newTab: 0, mega: 0, sort: 60 },
					{ cat: "apply-for", site: "public-works", q: "Event Permit", type: "page", url: "/public-works/pages/event-permits-in-chelan-county", newTab: 0, mega: 0, sort: 70 },
					{ cat: "apply-for", site: "assessors", q: "Property Tax Relief & Senior Exemption", type: "page", url: "/assessor/pages/current-use-exemptions", newTab: 0, mega: 1, sort: 80 },
					{ cat: "apply-for", site: "clerk", q: "Passport", type: "page", url: "/clerk/pages/passport-information", newTab: 0, mega: 0, sort: 90 },

					// Contact
					{ cat: "contact", site: "commissioners", q: "Board of Commissioners", type: "custom", url: "/board-of-commissioners/contacts", newTab: 0, mega: 1, sort: 10 },
					{ cat: "contact", site: "Auditor", q: "Chelan County Elections", type: "custom", url: "/elections/contacts", newTab: 0, mega: 1, sort: 20 },
					{ cat: "contact", site: "clerk", q: "Court Clerk", type: "custom", url: "/clerk/contacts", newTab: 0, mega: 1, sort: 30 },
					{ cat: "contact", site: "assessors", q: "County Assessor's Office", type: "custom", url: "/assessor/contacts", newTab: 0, mega: 1, sort: 40 },
					{ cat: "contact", site: "sheriff", q: "Sheriff's Office", type: "custom", url: "/sheriff/contacts", newTab: 0, mega: 1, sort: 50 },

					// Find
					{ cat: "find", site: "Auditor", q: "Election Results", type: "page", url: "/elections/pages/current-election-results", newTab: 0, mega: 1, sort: 10 },
					{ cat: "find", site: "public-works", q: "Flood Control Zone District", type: "custom", url: "/flood-control-zone-district", newTab: 0, mega: 1, sort: 20 },
					{ cat: "find", site: "assessors", q: "Property Levy Rates & Tax District Distribution", type: "page", url: "/assessor/pages/property-tax-summary-reports", newTab: 0, mega: 1, sort: 30 },

					// File A
					{ cat: "file-a", site: "commissioners", q: "Claim Against Chelan County", type: "custom", url: "/files/prosecutor/documents/Claim for Damages Form 2026 (fillable).pdf", newTab: 1, mega: 1, sort: 10 },
					{ cat: "file-a", site: "assessors", q: "Petition to Board of Equalization", type: "page", url: "/assessor/pages/appeals", newTab: 0, mega: 1, sort: 20 },

					// Join
					{ cat: "join", site: "commissioners", q: "County Advisory Boards & Commissions", type: "page", url: "/board-of-commissioners/pages/boards-and-commissions", newTab: 0, mega: 1, sort: 10 },
					{ cat: "join", site: "sheriff", q: "Sheriff Volunteer Search & Rescue", type: "page", url: "/sheriff/pages/search-and-rescue", newTab: 0, mega: 1, sort: 20 },

					// Pay For
					{ cat: "pay-for", site: "treasurer", q: "Property Taxes", type: "page", url: "/treasurer/pages/make-payments", newTab: 0, mega: 1, sort: 10 },
					{ cat: "pay-for", site: "clerk", q: "Court Cost and Restitution", type: "page", url: "/clerk/pages/financial-collector", newTab: 0, mega: 1, sort: 20 },
					{ cat: "pay-for", site: "global", q: "Jail Commissary Account", type: "page", url: "/regional-jail/pages/inmate-phone-and-commissary-accounts-", newTab: 0, mega: 1, sort: 30 },
					{ cat: "pay-for", site: "global", q: "Probation Fees Online", type: "page", url: "/district-court-probation/pages/probation-online-payments", newTab: 0, mega: 1, sort: 40 },

					// Learn About
					{ cat: "learn-about", site: "clerk", q: "Domestic Violence Assistance & Protection", type: "page", url: "/clerk/pages/domestic-violence-assistance", newTab: 0, mega: 1, sort: 10 },
					{ cat: "learn-about", site: "assessors", q: "How Property Taxes Are Calculated", type: "page", url: "/assessor/pages/frequently-asked-questions", newTab: 0, mega: 1, sort: 20 },

					// Register To
					{ cat: "register-to", site: "clerk", q: "Jury Duty", type: "external", url: "https://jury.chelancounty.gov", newTab: 1, mega: 1, sort: 10 },
					{ cat: "register-to", site: "clerk", q: "Parenting Class", type: "page", url: "/clerk/pages/parenting-class", newTab: 0, mega: 1, sort: 20 },
					{ cat: "register-to", site: "Auditor", q: "Vote", type: "external", url: "https://www.sos.wa.gov/elections/myvote/", newTab: 1, mega: 1, sort: 30 },

					// Report
					{ cat: "report", site: "community-development", q: "Code Violation", type: "page", url: "/community-development/pages/code-enforcement", newTab: 0, mega: 1, sort: 10 },
					{ cat: "report", site: "public-works", q: "Icy Road Conditions", type: "form", url: "/public-works/forms/report-a-problem", newTab: 0, mega: 1, sort: 20 },
					{ cat: "report", site: "public-works", q: "Missing Traffic Signs", type: "form", url: "/public-works/forms/report-a-problem", newTab: 0, mega: 1, sort: 30 },
					{ cat: "report", site: "sheriff", q: "Submit A Crime Tip", type: "form", url: "/sheriff/forms/submit-a-tip", newTab: 0, mega: 1, sort: 40 },

					// Request
					{ cat: "request", site: "pio", q: "Public Records", type: "custom", url: "/public-records-request", newTab: 0, mega: 1, sort: 10 },
					{ cat: "request", site: "Auditor", q: "A Death Certificate", type: "external", url: "https://doh.wa.gov/licenses-permits-and-certificates/vital-records/ordering-vital-record/death-record", newTab: 1, mega: 1, sort: 20 },
					{ cat: "request", site: "community-development", q: "Flood Elevation Certificate", type: "custom", url: "/community-development/contacts", newTab: 0, mega: 1, sort: 30 },

					// Search For
					{ cat: "search-for", site: "commissioners", q: "Commissioner's Public Documents", type: "page", url: "/board-of-commissioners/pages/document-and-record-search", newTab: 0, mega: 1, sort: 10 },
					{ cat: "search-for", site: "assessors", q: "Property & Parcel Search", type: "page", url: "/assessor/pages/parcel-and-sale-search", newTab: 0, mega: 1, sort: 20 },
					{ cat: "search-for", site: "global", q: "Inmate / Arrestee Roster", type: "page", url: "/regional-jail/pages/jail-registry--inmate-list", newTab: 0, mega: 1, sort: 30 },

					// View
					{ cat: "view", site: "clerk", q: "Court Dockets and Schedules", type: "page", url: "/clerk/pages/court-calendars", newTab: 0, mega: 1, sort: 10 },
					{ cat: "view", site: "assessors", q: "Monthly Property Sales Reports", type: "page", url: "/assessor/pages/monthly-sales-reports", newTab: 0, mega: 1, sort: 20 }
				];

				for (local.s in local.seedItems) {
					if (StructKeyExists(local.catMap, local.s.cat)) {
						queryExecute("
							SET ANSI_NULLS ON;
							SET QUOTED_IDENTIFIER ON;
							INSERT INTO how_do_i_items (
								category_id, siteid, question, destination_type, destination_url,
								open_in_new_tab, is_featured_mega_menu, sort_order, is_published, created_by, modified_by
							)
							VALUES (
								:catId, :siteId, :q, :dtype, :durl,
								:newTab, :mega, :sortOrder, 1, N'System Seed', N'System Seed'
							)
						", {
							catId: { value: local.catMap[local.s.cat], cfsqltype: "cf_sql_integer" },
							siteId: { value: local.s.site, cfsqltype: "cf_sql_nvarchar" },
							q: { value: local.s.q, cfsqltype: "cf_sql_nvarchar" },
							dtype: { value: local.s.type, cfsqltype: "cf_sql_nvarchar" },
							durl: { value: local.s.url, cfsqltype: "cf_sql_nvarchar" },
							newTab: { value: local.s.newTab, cfsqltype: "cf_sql_bit" },
							mega: { value: local.s.mega, cfsqltype: "cf_sql_bit" },
							sortOrder: { value: local.s.sort, cfsqltype: "cf_sql_integer" }
						}, { datasource: "ChelanCountyWebsite" });
					}
				}
			}
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

}
