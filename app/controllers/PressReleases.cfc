component extends="Controller" {

	function config() {
		super.config();
		filters(through="requireLogin", except="api,view");
		protectsFromForgery(except="api,save,delete,toggleStatus");
	}

	/**
	 * Press Releases Listing / Index
	 */
	function index() {
		variables.pageTitle = "Press Releases & Media Alerts";

		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role == "admin");
		variables.isPIO = (local.role == "pio");

		// Resolve active workspace
		local.requestedWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.requestedWs, role = local.role);
		variables.activeWorkspaceId = LCase(Trim(variables.activeWsObj.id ?: "global"));
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);

		variables.filterStatus = StructKeyExists(params, "status") ? Trim(params.status) : "all";
		variables.searchQuery = StructKeyExists(params, "q") ? Trim(params.q) : "";

		// Metrics/Stats
		variables.stats = {
			total: 0,
			active: 0,
			inactive: 0,
			archive: 0
		};

		try {
			local.qCounts = queryExecute("
				SELECT 
					COUNT(*) AS total,
					SUM(CASE WHEN status IN ('active', 'released') THEN 1 ELSE 0 END) AS active_cnt,
					SUM(CASE WHEN status IN ('inactive', 'draft', 'embargoed') THEN 1 ELSE 0 END) AS inactive_cnt,
					SUM(CASE WHEN status IN ('archive', 'archived') THEN 1 ELSE 0 END) AS archive_cnt
				FROM press_releases
				WHERE deletedat IS NULL
			", {}, { datasource: "ChelanCountyWebsite" });
			if (local.qCounts.recordCount) {
				variables.stats.total = Val(local.qCounts.total);
				variables.stats.active = Val(local.qCounts.active_cnt);
				variables.stats.inactive = Val(local.qCounts.inactive_cnt);
				variables.stats.archive = Val(local.qCounts.archive_cnt);
			}
		} catch (any eStats) {
			writeLog(type="error", file="pressreleases", text="Stats error: #eStats.message#");
		}

		// Build WHERE criteria
		local.whereClauses = ["deletedat IS NULL"];
		local.queryParams = {};

		if (Len(variables.searchQuery)) {
			ArrayAppend(local.whereClauses, "(title LIKE :search OR summary LIKE :search OR contact_name LIKE :search OR dateline LIKE :search)");
			local.queryParams["search"] = { value: "%" & variables.searchQuery & "%", cfsqltype: "cf_sql_varchar" };
		}

		if (variables.filterStatus != "all" && Len(variables.filterStatus)) {
			if (variables.filterStatus == "active") {
				ArrayAppend(local.whereClauses, "status IN ('active', 'released')");
			} else if (variables.filterStatus == "inactive") {
				ArrayAppend(local.whereClauses, "status IN ('inactive', 'draft', 'embargoed')");
			} else if (variables.filterStatus == "archive") {
				ArrayAppend(local.whereClauses, "status IN ('archive', 'archived')");
			} else {
				ArrayAppend(local.whereClauses, "status = :status");
				local.queryParams["status"] = { value: variables.filterStatus, cfsqltype: "cf_sql_varchar" };
			}
		}

		if (variables.activeWorkspaceId != "all" && variables.activeWorkspaceId != "global" && Len(variables.activeWorkspaceId)) {
			ArrayAppend(local.whereClauses, "(siteid = :siteid OR siteid = 'global')");
			local.queryParams["siteid"] = { value: variables.activeWorkspaceId, cfsqltype: "cf_sql_varchar" };
		}

		local.whereSql = ArrayToList(local.whereClauses, " AND ");

		variables.releases = [];
		try {
			local.qReleases = queryExecute("
				SELECT id, title, slug, dateline, summary, is_embargoed, embargo_until,
				       contact_name, contact_title, contact_phone, contact_email,
				       pdf_url, status, siteid, released_at, created_by, createdat, updatedat
				FROM press_releases
				WHERE #local.whereSql#
				ORDER BY released_at DESC, id DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });

			for (local.row in local.qReleases) {
				ArrayAppend(variables.releases, {
					id: local.row.id,
					title: local.row.title,
					slug: local.row.slug,
					dateline: local.row.dateline ?: "WENATCHEE, WA",
					summary: local.row.summary ?: "",
					is_embargoed: (Val(local.row.is_embargoed) == 1),
					embargo_until: local.row.embargo_until,
					contact_name: local.row.contact_name ?: "",
					contact_title: local.row.contact_title ?: "",
					contact_phone: local.row.contact_phone ?: "",
					contact_email: local.row.contact_email ?: "",
					pdf_url: local.row.pdf_url ?: "",
					status: local.row.status ?: "released",
					siteid: local.row.siteid ?: "global",
					released_at: local.row.released_at,
					created_by: local.row.created_by ?: "",
					createdat: local.row.createdat,
					updatedat: local.row.updatedat
				});
			}
		} catch (any eList) {
			writeLog(type="error", file="pressreleases", text="Press releases list error: #eList.message# #eList.detail#");
		}
	}

	/**
	 * New Press Release Screen
	 */
	function new() {
		variables.pageTitle = "New Press Release";
		variables.isNew = true;

		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role == "admin");
		variables.isPIO = (local.role == "pio");

		local.requestedWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.requestedWs, role = local.role);
		variables.activeWorkspaceId = LCase(Trim(variables.activeWsObj.id ?: "global"));
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);

		local.contactName = "Chelan County Communications";
		local.contactTitle = "Public Information Office";
		local.contactPhone = "(509) 667-6200";
		local.contactEmail = "pio@co.chelan.wa.us";

		if (StructKeyExists(session, "user") && IsStruct(session.user)) {
			if (Len(Trim(session.user.full_name ?: ""))) local.contactName = session.user.full_name;
			if (Len(Trim(session.user.email ?: ""))) local.contactEmail = session.user.email;
		}

		variables.release = {
			id: 0,
			title: "",
			slug: "",
			dateline: "WENATCHEE, WA",
			summary: "",
			content_html: "<p><strong>FOR IMMEDIATE RELEASE</strong></p><p>Write official media alert / press release copy here...</p><p>######</p>",
			is_embargoed: false,
			embargo_until: "",
			contact_name: local.contactName,
			contact_title: local.contactTitle,
			contact_phone: local.contactPhone,
			contact_email: local.contactEmail,
			pdf_url: "",
			status: "active",
			siteid: variables.activeWorkspaceId,
			released_at: Now()
		};

		renderView(template="edit");
	}

	/**
	 * Edit Press Release Screen
	 */
	function edit() {
		local.id = Val(params.id ?: 0);
		if (local.id <= 0) {
			flashInsert(error="Invalid press release ID specified.");
			redirectTo(controller="pressReleases", action="index");
			return;
		}

		variables.pageTitle = "Edit Press Release";
		variables.isNew = false;

		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role == "admin");
		variables.isPIO = (local.role == "pio");

		local.requestedWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.requestedWs, role = local.role);
		variables.activeWorkspaceId = LCase(Trim(variables.activeWsObj.id ?: "global"));
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);

		try {
			local.q = queryExecute("
				SELECT id, title, slug, dateline, summary, content_html, is_embargoed, embargo_until,
				       contact_name, contact_title, contact_phone, contact_email,
				       pdf_url, status, siteid, released_at, created_by, modified_by, createdat, updatedat
				FROM press_releases
				WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (!local.q.recordCount) {
				flashInsert(error="The requested press release does not exist or has been removed.");
				redirectTo(controller="pressReleases", action="index");
				return;
			}

			local.currStatus = local.q.status ?: "active";
			if (local.currStatus == "released") local.currStatus = "active";
			else if (local.currStatus == "draft" || local.currStatus == "embargoed") local.currStatus = "inactive";
			else if (local.currStatus == "archived") local.currStatus = "archive";

			variables.release = {
				id: local.q.id,
				title: local.q.title,
				slug: local.q.slug,
				dateline: local.q.dateline ?: "WENATCHEE, WA",
				summary: local.q.summary ?: "",
				content_html: local.q.content_html ?: "",
				is_embargoed: false,
				embargo_until: "",
				contact_name: local.q.contact_name ?: "",
				contact_title: local.q.contact_title ?: "",
				contact_phone: local.q.contact_phone ?: "",
				contact_email: local.q.contact_email ?: "",
				pdf_url: local.q.pdf_url ?: "",
				status: local.currStatus,
				siteid: local.q.siteid ?: "global",
				released_at: local.q.released_at ?: Now()
			};
		} catch (any eFetch) {
			flashInsert(error="Error loading press release: #eFetch.message#");
			redirectTo(controller="pressReleases", action="index");
			return;
		}
	}

	/**
	 * Official Printer-Friendly Press Release View
	 */
	function view() {
		local.id = Val(params.id ?: 0);
		local.slug = Trim(params.slug ?: "");

		local.where = "deletedat IS NULL";
		local.qp = {};

		if (local.id > 0) {
			local.where &= " AND id = :id";
			local.qp["id"] = { value: local.id, cfsqltype: "cf_sql_integer" };
		} else if (Len(local.slug)) {
			local.where &= " AND slug = :slug";
			local.qp["slug"] = { value: local.slug, cfsqltype: "cf_sql_varchar" };
		} else {
			flashInsert(error="Press release not found.");
			redirectTo(controller="pressReleases", action="index");
			return;
		}

		try {
			local.q = queryExecute("
				SELECT id, title, slug, dateline, summary, content_html, is_embargoed, embargo_until,
				       contact_name, contact_title, contact_phone, contact_email,
				       pdf_url, status, siteid, released_at, created_by, createdat
				FROM press_releases
				WHERE #local.where#
			", local.qp, { datasource: "ChelanCountyWebsite" });

			if (!local.q.recordCount) {
				flashInsert(error="Press release not found.");
				redirectTo(controller="pressReleases", action="index");
				return;
			}

			variables.release = {
				id: local.q.id,
				title: local.q.title,
				slug: local.q.slug,
				dateline: local.q.dateline ?: "WENATCHEE, WA",
				summary: local.q.summary ?: "",
				content_html: local.q.content_html ?: "",
				is_embargoed: (Val(local.q.is_embargoed) == 1),
				embargo_until: local.q.embargo_until,
				contact_name: local.q.contact_name ?: "Public Information Office",
				contact_title: local.q.contact_title ?: "",
				contact_phone: local.q.contact_phone ?: "(509) 667-6200",
				contact_email: local.q.contact_email ?: "pio@co.chelan.wa.us",
				pdf_url: local.q.pdf_url ?: "",
				status: local.q.status ?: "released",
				siteid: local.q.siteid ?: "global",
				released_at: local.q.released_at ?: local.q.createdat
			};

			variables.pageTitle = variables.release.title & " - Press Release";
		} catch (any eView) {
			flashInsert(error="Error loading press release: #eView.message#");
			redirectTo(controller="pressReleases", action="index");
		}
	}

	/**
	 * Save Press Release
	 */
	function save() {
		local.body = readJsonOrParams();

		local.id = Val(local.body.id ?: 0);
		local.title = Left(Trim(local.body.title ?: ""), 255);
		local.slug = generateSlug(Len(Trim(local.body.slug ?: "")) ? local.body.slug : local.title);
		local.dateline = Left(Trim(local.body.dateline ?: "WENATCHEE, WA"), 150);
		local.summary = Left(Trim(local.body.summary ?: ""), 1000);
		local.contentHtml = Trim(local.body.content_html ?: (local.body.content ?: ""));
		
		local.isEmbargoed = 0;
		local.embargoUntil = JavaCast("null", "");

		local.contactName = Left(Trim(local.body.contact_name ?: ""), 150);
		local.contactTitle = Left(Trim(local.body.contact_title ?: ""), 150);
		local.contactPhone = Left(Trim(local.body.contact_phone ?: ""), 50);
		local.contactEmail = Left(Trim(local.body.contact_email ?: ""), 150);
		local.pdfUrl = Left(Trim(local.body.pdf_url ?: ""), 1000);

		local.status = LCase(Trim(local.body.status ?: "active"));
		if (local.status == "released") local.status = "active";
		if (local.status == "draft" || local.status == "embargoed") local.status = "inactive";
		if (local.status == "archived") local.status = "archive";
		if (!ListFindNoCase("active,inactive,archive", local.status)) local.status = "active";

		local.siteid = Len(Trim(local.body.siteid ?: "")) ? LCase(Trim(local.body.siteid)) : "global";

		local.releasedAt = Now();
		if (StructKeyExists(local.body, "released_at") && Len(Trim(local.body.released_at)) && IsDate(local.body.released_at)) {
			local.releasedAt = ParseDateTime(local.body.released_at);
		}

		if (!Len(local.title)) {
			return renderJsonEnvelope(false, "Press release headline is required.", {}, 400);
		}
		if (!Len(local.contentHtml)) {
			return renderJsonEnvelope(false, "Press release content body cannot be empty.", {}, 400);
		}

		local.currentActor = resolveCurrentActor();

		try {
			if (local.id > 0) {
				// Update
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE press_releases
					SET title = :title,
					    slug = :slug,
					    dateline = :dateline,
					    summary = :summary,
					    content_html = :content_html,
					    is_embargoed = :is_embargoed,
					    embargo_until = :embargo_until,
					    contact_name = :contact_name,
					    contact_title = :contact_title,
					    contact_phone = :contact_phone,
					    contact_email = :contact_email,
					    pdf_url = :pdf_url,
					    status = :status,
					    siteid = :siteid,
					    released_at = :released_at,
					    modified_by = :modified_by,
					    updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					id: { value: local.id, cfsqltype: "cf_sql_integer" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					dateline: { value: local.dateline, cfsqltype: "cf_sql_varchar" },
					summary: { value: local.summary, cfsqltype: "cf_sql_varchar", null: !Len(local.summary) },
					content_html: { value: local.contentHtml, cfsqltype: "cf_sql_longvarchar" },
					is_embargoed: { value: local.isEmbargoed, cfsqltype: "cf_sql_bit" },
					embargo_until: { value: local.embargoUntil, cfsqltype: "cf_sql_timestamp", null: IsNull(local.embargoUntil) },
					contact_name: { value: local.contactName, cfsqltype: "cf_sql_varchar", null: !Len(local.contactName) },
					contact_title: { value: local.contactTitle, cfsqltype: "cf_sql_varchar", null: !Len(local.contactTitle) },
					contact_phone: { value: local.contactPhone, cfsqltype: "cf_sql_varchar", null: !Len(local.contactPhone) },
					contact_email: { value: local.contactEmail, cfsqltype: "cf_sql_varchar", null: !Len(local.contactEmail) },
					pdf_url: { value: local.pdfUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.pdfUrl) },
					status: { value: local.status, cfsqltype: "cf_sql_varchar" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" },
					released_at: { value: local.releasedAt, cfsqltype: "cf_sql_timestamp" },
					modified_by: { value: local.currentActor, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				// Insert
				local.qIns = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO press_releases (
						title, slug, dateline, summary, content_html, is_embargoed, embargo_until,
						contact_name, contact_title, contact_phone, contact_email,
						pdf_url, status, siteid, released_at, created_by, modified_by,
						createdat, updatedat
					) VALUES (
						:title, :slug, :dateline, :summary, :content_html, :is_embargoed, :embargo_until,
						:contact_name, :contact_title, :contact_phone, :contact_email,
						:pdf_url, :status, :siteid, :released_at, :created_by, :modified_by,
						SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT SCOPE_IDENTITY() AS new_id;
				", {
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					dateline: { value: local.dateline, cfsqltype: "cf_sql_varchar" },
					summary: { value: local.summary, cfsqltype: "cf_sql_varchar", null: !Len(local.summary) },
					content_html: { value: local.contentHtml, cfsqltype: "cf_sql_longvarchar" },
					is_embargoed: { value: local.isEmbargoed, cfsqltype: "cf_sql_bit" },
					embargo_until: { value: local.embargoUntil, cfsqltype: "cf_sql_timestamp", null: IsNull(local.embargoUntil) },
					contact_name: { value: local.contactName, cfsqltype: "cf_sql_varchar", null: !Len(local.contactName) },
					contact_title: { value: local.contactTitle, cfsqltype: "cf_sql_varchar", null: !Len(local.contactTitle) },
					contact_phone: { value: local.contactPhone, cfsqltype: "cf_sql_varchar", null: !Len(local.contactPhone) },
					contact_email: { value: local.contactEmail, cfsqltype: "cf_sql_varchar", null: !Len(local.contactEmail) },
					pdf_url: { value: local.pdfUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.pdfUrl) },
					status: { value: local.status, cfsqltype: "cf_sql_varchar" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" },
					released_at: { value: local.releasedAt, cfsqltype: "cf_sql_timestamp" },
					created_by: { value: local.currentActor, cfsqltype: "cf_sql_varchar" },
					modified_by: { value: local.currentActor, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.id = Val(local.qIns.new_id);
			}

			flashInsert(success="Press release '#local.title#' saved successfully.");
			return renderJsonEnvelope(true, "Press release saved successfully.", {
				"id": local.id,
				"redirect": urlFor(controller="pressReleases", action="index")
			});
		} catch (any eSave) {
			writeLog(type="error", file="pressreleases", text="Save press release failed: #eSave.message# #eSave.detail#");
			return renderJsonEnvelope(false, "Failed to save press release: #eSave.message#", {}, 500);
		}
	}

	/**
	 * Soft Delete Press Release
	 */
	function delete() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: (params.id ?: 0));

		if (local.id <= 0) {
			return renderJsonEnvelope(false, "Invalid press release ID specified.", {}, 400);
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE press_releases
				SET deletedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			flashInsert(success="Press release deleted.");
			return renderJsonEnvelope(true, "Press release deleted successfully.", { "id": local.id });
		} catch (any eDel) {
			writeLog(type="error", file="pressreleases", text="Delete press release failed: #eDel.message#");
			return renderJsonEnvelope(false, "Failed to delete press release.", {}, 500);
		}
	}

	/**
	 * Toggle Status
	 */
	function toggleStatus() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: 0);
		local.newStatus = LCase(Trim(local.body.status ?: ""));

		if (local.newStatus == "released") local.newStatus = "active";
		if (local.newStatus == "draft" || local.newStatus == "embargoed") local.newStatus = "inactive";
		if (local.newStatus == "archived") local.newStatus = "archive";

		if (local.id <= 0 || !ListFindNoCase("active,inactive,archive", local.newStatus)) {
			return renderJsonEnvelope(false, "Invalid press release ID or status value (must be active, inactive, or archive).", {}, 400);
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE press_releases
				SET status = :status,
				    updatedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL
			", {
				id: { value: local.id, cfsqltype: "cf_sql_integer" },
				status: { value: local.newStatus, cfsqltype: "cf_sql_varchar" }
			}, { datasource: "ChelanCountyWebsite" });

			return renderJsonEnvelope(true, "Status updated to #local.newStatus#.", { "id": local.id, "status": local.newStatus });
		} catch (any eToggle) {
			return renderJsonEnvelope(false, "Failed to update status: #eToggle.message#", {}, 500);
		}
	}

	/**
	 * Public API for website consumption
	 */
	function api() {
		local.limit = Val(params.limit ?: 10);
		if (local.limit <= 0 || local.limit > 50) local.limit = 10;

		local.status = StructKeyExists(params, "status") ? Trim(params.status) : "active";
		local.siteid = StructKeyExists(params, "siteid") ? Trim(params.siteid) : "";

		local.whereClauses = ["deletedat IS NULL"];
		local.qp = {};

		if (Len(local.status) && local.status != "all") {
			if (local.status == "active" || local.status == "released") {
				ArrayAppend(local.whereClauses, "status IN ('active', 'released')");
			} else if (local.status == "inactive" || local.status == "draft") {
				ArrayAppend(local.whereClauses, "status IN ('inactive', 'draft')");
			} else if (local.status == "archive" || local.status == "archived") {
				ArrayAppend(local.whereClauses, "status IN ('archive', 'archived')");
			} else {
				ArrayAppend(local.whereClauses, "status = :status");
				local.qp["status"] = { value: local.status, cfsqltype: "cf_sql_varchar" };
			}
		}

		if (Len(local.siteid) && local.siteid != "all") {
			ArrayAppend(local.whereClauses, "(siteid = :siteid OR siteid = 'global')");
			local.qp["siteid"] = { value: local.siteid, cfsqltype: "cf_sql_varchar" };
		}

		local.whereSql = ArrayToList(local.whereClauses, " AND ");
		local.qp["limit"] = { value: local.limit, cfsqltype: "cf_sql_integer" };

		local.releases = [];
		try {
			local.q = queryExecute("
				SELECT TOP (:limit) id, title, slug, dateline, summary,
				       contact_name, contact_title, contact_phone, contact_email,
				       pdf_url, status, siteid, released_at
				FROM press_releases
				WHERE #local.whereSql#
				ORDER BY released_at DESC, id DESC
			", local.qp, { datasource: "ChelanCountyWebsite" });

			for (local.r in local.q) {
				local.relDate = "";
				if (StructKeyExists(local.r, "released_at") && IsDate(local.r.released_at)) {
					local.relDate = DateFormat(local.r.released_at, "yyyy-mm-dd") & "T" & TimeFormat(local.r.released_at, "HH:mm:ss") & "Z";
				}
				ArrayAppend(local.releases, {
					"id": local.r.id,
					"title": local.r.title,
					"slug": local.r.slug,
					"dateline": local.r.dateline ?: "WENATCHEE, WA",
					"summary": local.r.summary ?: "",
					"contact_name": local.r.contact_name ?: "",
					"contact_title": local.r.contact_title ?: "",
					"contact_phone": local.r.contact_phone ?: "",
					"contact_email": local.r.contact_email ?: "",
					"pdf_url": local.r.pdf_url ?: "",
					"status": local.r.status,
					"siteid": local.r.siteid,
					"released_at": local.relDate
				});
			}

			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text=SerializeJSON({
				"success": true,
				"count": ArrayLen(local.releases),
				"releases": local.releases
			}));
		} catch (any eApi) {
			writeLog(type="error", file="press_api_debug", text="Press Releases API Error: #eApi.message# #eApi.detail#");
			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text=SerializeJSON({ "success": false, "error": eApi.message, "releases": [] }));
		}
	}

	// -------------------------------------------------------------------------
	// Private Helpers
	// -------------------------------------------------------------------------

	private function generateSlug(required string text) {
		local.clean = LCase(Trim(arguments.text));
		local.clean = REReplace(local.clean, "[^a-z0-9\s-]", "", "all");
		local.clean = REReplace(local.clean, "[\s-]+", "-", "all");
		local.clean = REReplace(local.clean, "^-+|-+$", "", "all");
		if (!Len(local.clean)) local.clean = "press-release-" & CreateUUID();
		return Left(local.clean, 255);
	}

	private function resolveCurrentActor() {
		if (StructKeyExists(session, "user") && IsStruct(session.user)) {
			if (Len(Trim(session.user.email ?: ""))) return session.user.email;
			if (Len(Trim(session.user.username ?: ""))) return session.user.username;
		}
		return "system";
	}

	private function readJsonOrParams() {
		local.reqBody = GetHttpRequestData().content ?: "";
		if (IsBinary(local.reqBody)) {
			local.reqBody = CharsetEncode(local.reqBody, "utf-8");
		}
		if (Len(Trim(local.reqBody)) && IsJson(Trim(local.reqBody))) {
			try {
				return DeserializeJSON(local.reqBody);
			} catch (any e) {}
		}
		return duplicate(params);
	}

	private void function renderJsonEnvelope(required boolean success, string message = "", any data = {}, numeric statusCode = 200) {
		local.envelope = {
			"success": arguments.success,
			"SUCCESS": arguments.success,
			"message": arguments.message,
			"MESSAGE": arguments.message
		};
		for (local.k in arguments.data) {
			local.envelope[local.k] = arguments.data[local.k];
			local.envelope[UCase(local.k)] = arguments.data[local.k];
		}
		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text=SerializeJSON(local.envelope), status=arguments.statusCode);
	}

}
