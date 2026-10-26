component extends="Controller" {

	function config() {
		super.config();
	}

	/**
	 * CMS Dashboard View
	 * Dynamic workspace-scoped metrics, recent pages, online forms & submissions,
	 * storage allocation, and live editorial activity feed.
	 */
	function index() {
		variables.pageTitle = "CMS Dashboard";
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");
		variables.isAdmin = local.isAdmin;

		// Resolve requested workspace from query param or header cookie
		local.requestedWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");

		variables.activeWsObj = resolveUserActiveWorkspace(
			requestedWs = local.requestedWs,
			role = local.role
		);
		variables.activeWorkspaceId = LCase(Trim(variables.activeWsObj.id ?: ""));
		variables.hasWorkspace = (Len(variables.activeWorkspaceId) > 0 && variables.activeWorkspaceId != "global" && variables.activeWorkspaceId != "all");
		variables.workspaceName = StructKeyExists(variables.activeWsObj, "name") ? variables.activeWsObj.name : "County Administration";
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);

		// Candidate SiteIDs for database matching (aliases, codes, singular/plural)
		local.candidateSiteIds = [];
		if (variables.hasWorkspace) {
			local.candidateSiteIds = getCandidateSiteIds(variables.activeWorkspaceId);
			if (ArrayLen(local.candidateSiteIds) == 0) {
				ArrayAppend(local.candidateSiteIds, variables.activeWorkspaceId);
			}
		}

		// Initialize KPIs and content structs
		variables.stats = {
			totalPages: 0,
			publishedPages: 0,
			draftPages: 0,
			totalForms: 0,
			activeForms: 0,
			pendingSubmissions: 0,
			totalSubmissions: 0,
			mediaCount: 0,
			mediaBytes: 0,
			mediaFormattedSize: "0 KB",
			storagePercent: 0,
			navMenusCount: 0
		};

		variables.recentPages = [];
		variables.workspacePages = [];
		variables.workspaceForms = [];
		variables.recentActivities = [];

		// 1. Pages Queries
		try {
			if (variables.hasWorkspace && ArrayLen(local.candidateSiteIds) > 0) {
				local.pageParams = {};
				local.pagePlaceholders = [];
				for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
					local.pName = "pSite" & local.idx;
					ArrayAppend(local.pagePlaceholders, ":" & local.pName);
					local.pageParams[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
				}
				local.pageInClause = ArrayToList(local.pagePlaceholders, ", ");

				// Overall count & published count
				local.qCounts = queryExecute("
					SELECT COUNT(*) AS total_count,
					       SUM(CASE WHEN isPublished = 1 OR StatusCode = 'Active' THEN 1 ELSE 0 END) AS pub_count,
					       SUM(CASE WHEN isPublished = 0 AND StatusCode != 'Active' THEN 1 ELSE 0 END) AS draft_count
					FROM pages
					WHERE DeletedAt IS NULL AND SiteID IN (" & local.pageInClause & ")
				", local.pageParams, { datasource: "ChelanCountyWebsite" });

				if (local.qCounts.recordCount > 0) {
					variables.stats.totalPages = Val(local.qCounts.total_count);
					variables.stats.publishedPages = Val(local.qCounts.pub_count);
					variables.stats.draftPages = Val(local.qCounts.draft_count);
				}

				// Recent Pages for primary table
				local.qRecent = queryExecute("
					SELECT TOP 6 ContentID, SiteID, PageType, MenuSelected, LayoutType,
					       StatusCode, Permalink, Title, Summary, isPublished, Visibility,
					       Created, CreatedBy, Modified, ModifiedBy
					FROM pages
					WHERE DeletedAt IS NULL AND SiteID IN (" & local.pageInClause & ")
					ORDER BY Modified DESC, ContentID DESC
				", local.pageParams, { datasource: "ChelanCountyWebsite" });

				for (local.row in local.qRecent) {
					local.updatedStr = "";
					local.modDate = local.row.Modified;
					if (IsDate(local.modDate)) {
						local.updatedStr = DateFormat(local.modDate, "mmm d, yyyy") & " " & TimeFormat(local.modDate, "h:mm TT");
					} else if (IsDate(local.row.Created)) {
						local.modDate = local.row.Created;
						local.updatedStr = DateFormat(local.row.Created, "mmm d, yyyy") & " " & TimeFormat(local.row.Created, "h:mm TT");
					}

					local.authorName = Len(Trim(local.row.ModifiedBy)) ? local.row.ModifiedBy : (Len(Trim(local.row.CreatedBy)) ? local.row.CreatedBy : "Administrator");
					local.initials = "CC";
					local.cleanAuthor = REReplace(local.authorName, "@.*$", "");
					if (Find(".", local.cleanAuthor)) {
						local.parts = ListToArray(local.cleanAuthor, ".");
						if (ArrayLen(local.parts) >= 2) {
							local.initials = UCase(Left(local.parts[1], 1) & Left(local.parts[2], 1));
						} else {
							local.initials = UCase(Left(local.cleanAuthor, 2));
						}
					} else if (Find(" ", local.cleanAuthor)) {
						local.parts = ListToArray(local.cleanAuthor, " ");
						local.initials = UCase(Left(local.parts[1], 1) & Left(local.parts[2], 1));
					} else {
						local.initials = UCase(Left(local.cleanAuthor, 2));
					}

					ArrayAppend(variables.recentPages, {
						id: local.row.ContentID,
						title: Len(Trim(local.row.Title)) ? local.row.Title : "Untitled Page",
						permalink: local.row.Permalink ?: "",
						siteId: local.row.SiteID ?: "",
						status: Len(Trim(local.row.StatusCode)) ? local.row.StatusCode : "Active",
						visibility: Len(Trim(local.row.Visibility)) ? local.row.Visibility : "Published",
						isPublished: (local.row.isPublished == 1),
						layout: local.row.LayoutType ?: "Full",
						author: local.cleanAuthor,
						initials: local.initials,
						updated: local.updatedStr,
						modifiedDate: local.modDate
					});

					// Add page modification to unified activity feed
					if (IsDate(local.modDate)) {
						ArrayAppend(variables.recentActivities, {
							type: "page",
							title: local.cleanAuthor & " updated page",
							subtitle: '"' & (Len(Trim(local.row.Title)) ? local.row.Title : "Untitled Page") & '"',
							time: local.updatedStr,
							dateVal: local.modDate,
							icon: "file-text",
							colorClass: "stat-icon-primary",
							link: urlFor(controller="pages", action="edit", params="id=" & local.row.ContentID)
						});
					}
				}
			}
		} catch (any errPages) {
			writeLog(type="error", file="main", text="Dashboard pages query error: #errPages.message# #errPages.detail#");
		}

		// 2. Online Forms & Submissions Queries
		try {
			if (variables.hasWorkspace && ArrayLen(local.candidateSiteIds) > 0) {
				local.formParams = {};
				local.formPlaceholders = [];
				for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
					local.pName = "fSite" & local.idx;
					ArrayAppend(local.formPlaceholders, ":" & local.pName);
					local.formParams[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
				}
				local.formInClause = ArrayToList(local.formPlaceholders, ", ");

				local.qForms = queryExecute("
					SELECT f.id, f.form_key, f.slug, f.title, f.description, f.status, f.siteid,
					       f.submissions_count, f.createdat, f.updatedat,
					       d.name AS dept_name, d.badge_class AS dept_badge,
					       (SELECT COUNT(*) FROM form_submissions s WHERE s.form_id = f.id AND s.deletedat IS NULL AND s.status IN ('received','in_review')) AS pending_count
					FROM forms f
					LEFT JOIN form_departments d ON d.id = f.department_id
					WHERE f.deletedat IS NULL AND f.siteid IN (" & local.formInClause & ")
					ORDER BY f.updatedat DESC
				", local.formParams, { datasource: "ChelanCountyWebsite" });

				variables.stats.totalForms = local.qForms.recordCount;
				for (local.row in local.qForms) {
					local.isPub = (LCase(local.row.status) == "published" || LCase(local.row.status) == "active");
					if (local.isPub) variables.stats.activeForms++;
					variables.stats.pendingSubmissions += Val(local.row.pending_count);
					variables.stats.totalSubmissions += Val(local.row.submissions_count);

					ArrayAppend(variables.workspaceForms, {
						id: local.row.id,
						title: Len(Trim(local.row.title)) ? local.row.title : "Untitled Form",
						slug: local.row.slug ?: "",
						status: local.row.status ?: "published",
						pendingCount: Val(local.row.pending_count),
						submissionsCount: Val(local.row.submissions_count),
						deptName: local.row.dept_name ?: "General",
						deptBadge: local.row.dept_badge ?: "badge-primary",
						updatedAt: local.row.updatedat
					});
				}

				// Form audit logs for recent activity stream
				local.qFormLogs = queryExecute("
					SELECT TOP 4 l.id, l.form_id, l.action, l.performed_by, l.createdat, l.details_json,
					       f.title AS form_title
					FROM form_audit_logs l
					LEFT JOIN forms f ON f.id = l.form_id
					WHERE f.siteid IN (" & local.formInClause & ")
					ORDER BY l.id DESC
				", local.formParams, { datasource: "ChelanCountyWebsite" });

				for (local.logRow in local.qFormLogs) {
					local.logDate = local.logRow.createdat;
					local.logDateStr = IsDate(local.logDate) ? (DateFormat(local.logDate, "mmm d, yyyy") & " " & TimeFormat(local.logDate, "h:mm TT")) : "Recently";
					local.actionLabel = "Form updated";
					if (local.logRow.action == "FORM_CREATED") local.actionLabel = "New online form created";
					if (local.logRow.action == "FORM_SOFT_DELETED") local.actionLabel = "Form archived";

					ArrayAppend(variables.recentActivities, {
						type: "form",
						title: local.actionLabel,
						subtitle: '"' & (Len(Trim(local.logRow.form_title)) ? local.logRow.form_title : "Form ##" & local.logRow.form_id) & '"',
						time: local.logDateStr,
						dateVal: local.logDate,
						icon: "clipboard-list",
						colorClass: "stat-icon-purple",
						link: urlFor(controller="forms", action="builder", params="id=" & local.logRow.form_id)
					});
				}
			}
		} catch (any errForms) {
			writeLog(type="error", file="main", text="Dashboard forms query error: #errForms.message# #errForms.detail#");
		}

		// 3. Navigation Menus Count
		try {
			if (variables.hasWorkspace && ArrayLen(local.candidateSiteIds) > 0) {
				local.navParams = {};
				local.navPlaceholders = [];
				for (local.idx = 1; local.idx <= ArrayLen(local.candidateSiteIds); local.idx++) {
					local.pName = "nSite" & local.idx;
					ArrayAppend(local.navPlaceholders, ":" & local.pName);
					local.navParams[local.pName] = { value: local.candidateSiteIds[local.idx], cfsqltype: "cf_sql_nvarchar" };
				}
				local.navInClause = ArrayToList(local.navPlaceholders, ", ");

				local.qNav = queryExecute("
					SELECT COUNT(*) AS menu_count
					FROM navigation_menus
					WHERE deletedat IS NULL AND siteid IN (" & local.navInClause & ")
				", local.navParams, { datasource: "ChelanCountyWebsite" });

				variables.stats.navMenusCount = Val(local.qNav.menu_count);
			}
		} catch (any errNav) {
			variables.stats.navMenusCount = 0;
		}

		// 4. Media Storage Scan for the Active Workspace
		try {
			local.mediaDir = variables.hasWorkspace
				? resolveWorkspaceStorageDiskPath(wsObj=variables.activeWsObj, fallbackWs=variables.activeWorkspaceId)
				: "C:\inetpub\chelan-county\files\shared";
			variables.stats.mediaBytes = 0;
			variables.stats.mediaCount = 0;
			variables.mediaBreakdown = {
				imagesBytes: 0,
				imagesCount: 0,
				docsBytes: 0,
				docsCount: 0,
				otherBytes: 0,
				otherCount: 0
			};

			if (DirectoryExists(local.mediaDir)) {
				local.fileQuery = DirectoryList(local.mediaDir, true, "query");
				for (local.fRow in local.fileQuery) {
					if (local.fRow.type eq "File" && Left(local.fRow.name, 1) neq "." && FindNoCase("\.thumbs", local.fRow.directory) eq 0) {
						variables.stats.mediaCount++;
						local.sz = Val(local.fRow.size);
						variables.stats.mediaBytes += local.sz;
						local.ext = LCase(ListLast(local.fRow.name, "."));

						if (ListFindNoCase("jpg,jpeg,png,gif,webp,svg,ico", local.ext)) {
							variables.mediaBreakdown.imagesCount++;
							variables.mediaBreakdown.imagesBytes += local.sz;
						} else if (ListFindNoCase("pdf,doc,docx,xls,xlsx,txt", local.ext)) {
							variables.mediaBreakdown.docsCount++;
							variables.mediaBreakdown.docsBytes += local.sz;
						} else {
							variables.mediaBreakdown.otherCount++;
							variables.mediaBreakdown.otherBytes += local.sz;
						}
					}
				}
			}

			// Format human readable size
			if (variables.stats.mediaBytes >= 1073741824) {
				variables.stats.mediaFormattedSize = NumberFormat(variables.stats.mediaBytes / 1073741824, "0.0") & " GB";
			} else if (variables.stats.mediaBytes >= 1048576) {
				variables.stats.mediaFormattedSize = NumberFormat(variables.stats.mediaBytes / 1048576, "0.0") & " MB";
			} else {
				variables.stats.mediaFormattedSize = NumberFormat(variables.stats.mediaBytes / 1024, "0.0") & " KB";
			}

			// Department storage quota (500 MB soft quota per department workspace)
			local.quotaBytes = 524288000;
			variables.stats.storagePercent = Min(100, Round((variables.stats.mediaBytes / local.quotaBytes) * 100));
			if (variables.stats.mediaBytes > 0 && variables.stats.storagePercent < 1) {
				variables.stats.storagePercent = 1;
			}
		} catch (any errMedia) {
			writeLog(type="error", file="main", text="Dashboard media scan error: #errMedia.message#");
		}

		// Sort unified activity feed newest first (limit to 6 entries)
		if (ArrayLen(variables.recentActivities) > 1) {
			ArraySort(variables.recentActivities, function(a, b) {
				if (IsDate(a.dateVal) && IsDate(b.dateVal)) {
					return DateCompare(b.dateVal, a.dateVal);
				}
				return 0;
			});
		}
		if (ArrayLen(variables.recentActivities) > 6) {
			variables.recentActivities = ArraySlice(variables.recentActivities, 1, 6);
		}
	}

	private array function getCandidateSiteIds(string wsId = "") {
		local.candidates = [];
		local.rawId = Trim(arguments.wsId);
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
				local.without = Mid(local.c, 6, Len(local.c) - 5);
				if (Len(local.without) && !ArrayFindNoCase(local.candidates, local.without)) ArrayAppend(local.candidates, local.without);
			} else {
				local.withSite = "site-" & local.c;
				if (!ArrayFindNoCase(local.candidates, local.withSite)) ArrayAppend(local.candidates, local.withSite);
			}
		}

		return local.candidates;
	}

	/**
	 * Full System Notifications & Activity Center
	 */
	function notifications() {
		variables.pageTitle = "Notifications & Activity Center";
		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role eq "admin");

		// Fetch up to 50 notifications across modules
		variables.allNotifications = getSystemNotifications(role = local.role, limit = 50);

		// Metric counts
		variables.counts = {
			total: ArrayLen(variables.allNotifications),
			forms: 0,
			pages: 0,
			jobs: 0,
			unread: 0
		};

		for (local.n in variables.allNotifications) {
			if (local.n.isUnread) variables.counts.unread++;
			if (local.n.type == "form") variables.counts.forms++;
			else if (local.n.type == "page") variables.counts.pages++;
			else if (local.n.type == "job") variables.counts.jobs++;
		}

		// Filter by category if requested
		local.filterType = StructKeyExists(params, "type") ? LCase(Trim(params.type)) : "all";
		variables.activeFilterType = local.filterType;

		if (local.filterType != "all") {
			local.filteredList = [];
			for (local.n in variables.allNotifications) {
				if (local.n.type == local.filterType) {
					ArrayAppend(local.filteredList, local.n);
				}
			}
			variables.notifications = local.filteredList;
		} else {
			variables.notifications = variables.allNotifications;
		}
	}

}

