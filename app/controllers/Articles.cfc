component extends="Controller" {

	function config() {
		super.config();
		filters(through="requireLogin", except="api");
		protectsFromForgery(except="api,save,delete,toggleStatus,saveCategory,deleteCategory,saveTag,deleteTag");
	}

	/**
	 * Articles & Posts Index / Listing
	 */
	function index() {
		variables.pageTitle = "Articles & Posts";

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
		variables.filterCategory = StructKeyExists(params, "category") ? Val(params.category) : 0;
		variables.searchQuery = StructKeyExists(params, "q") ? Trim(params.q) : "";

		// Query categories for filter dropdown
		variables.categories = [];
		try {
			local.qCats = queryExecute("
				SELECT id, name, slug, badge_color
				FROM article_categories
				WHERE deletedat IS NULL
				ORDER BY sort_order ASC, name ASC
			", {}, { datasource: "ChelanCountyWebsite" });
			for (local.c in local.qCats) {
				ArrayAppend(variables.categories, {
					id: local.c.id,
					name: local.c.name,
					slug: local.c.slug,
					badge_color: local.c.badge_color ?: "##0284c7"
				});
			}
		} catch (any eCats) {
			writeLog(type="error", file="articles", text="Error fetching categories: #eCats.message#");
		}

		// Compute metrics/stats
		variables.stats = {
			total: 0,
			published: 0,
			draft: 0,
			categoriesCount: ArrayLen(variables.categories)
		};

		try {
			local.qCounts = queryExecute("
				SELECT 
					COUNT(*) AS total,
					SUM(CASE WHEN status = 'published' THEN 1 ELSE 0 END) AS published_cnt,
					SUM(CASE WHEN status = 'draft' THEN 1 ELSE 0 END) AS draft_cnt
				FROM articles
				WHERE deletedat IS NULL
			", {}, { datasource: "ChelanCountyWebsite" });
			if (local.qCounts.recordCount) {
				variables.stats.total = Val(local.qCounts.total);
				variables.stats.published = Val(local.qCounts.published_cnt);
				variables.stats.draft = Val(local.qCounts.draft_cnt);
			}
		} catch (any eStats) {}

		// Build WHERE criteria
		local.whereClauses = ["a.deletedat IS NULL"];
		local.queryParams = {};

		if (Len(variables.searchQuery)) {
			ArrayAppend(local.whereClauses, "(a.title LIKE :search OR a.summary LIKE :search OR a.tags LIKE :search OR a.author_name LIKE :search)");
			local.queryParams["search"] = { value: "%" & variables.searchQuery & "%", cfsqltype: "cf_sql_varchar" };
		}

		if (variables.filterStatus != "all" && Len(variables.filterStatus)) {
			ArrayAppend(local.whereClauses, "a.status = :status");
			local.queryParams["status"] = { value: variables.filterStatus, cfsqltype: "cf_sql_varchar" };
		}

		if (variables.filterCategory > 0) {
			ArrayAppend(local.whereClauses, "a.category_id = :category_id");
			local.queryParams["category_id"] = { value: variables.filterCategory, cfsqltype: "cf_sql_integer" };
		}

		if (variables.activeWorkspaceId != "all" && variables.activeWorkspaceId != "global" && Len(variables.activeWorkspaceId)) {
			ArrayAppend(local.whereClauses, "(a.siteid = :siteid OR a.siteid = 'global')");
			local.queryParams["siteid"] = { value: variables.activeWorkspaceId, cfsqltype: "cf_sql_varchar" };
		}

		local.whereSql = ArrayToList(local.whereClauses, " AND ");

		variables.articles = [];
		try {
			local.qArticles = queryExecute("
				SELECT a.id, a.title, a.slug, a.summary, a.category_id, a.tags,
				       a.featured_image, a.author_name, a.author_title, a.status,
				       a.siteid, a.published_at, a.created_by, a.createdat, a.updatedat,
				       c.name AS category_name, c.badge_color AS category_color
				FROM articles a
				LEFT JOIN article_categories c ON a.category_id = c.id AND c.deletedat IS NULL
				WHERE #local.whereSql#
				ORDER BY a.published_at DESC, a.id DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });

			for (local.row in local.qArticles) {
				ArrayAppend(variables.articles, {
					id: local.row.id,
					title: local.row.title,
					slug: local.row.slug,
					summary: local.row.summary ?: "",
					category_id: local.row.category_id ?: 0,
					category_name: local.row.category_name ?: "Uncategorized",
					category_color: local.row.category_color ?: "##64748b",
					tags: local.row.tags ?: "",
					featured_image: local.row.featured_image ?: "",
					author_name: local.row.author_name ?: "Staff",
					author_title: local.row.author_title ?: "",
					status: local.row.status ?: "published",
					siteid: local.row.siteid ?: "global",
					published_at: local.row.published_at,
					created_by: local.row.created_by ?: "",
					createdat: local.row.createdat,
					updatedat: local.row.updatedat
				});
			}
		} catch (any eList) {
			writeLog(type="error", file="articles", text="Articles listing error: #eList.message# #eList.detail#");
		}
	}

	/**
	 * New Article Screen
	 */
	function new() {
		variables.pageTitle = "Add New Article";
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

		if ((variables.activeWorkspaceId == "global" || !Len(variables.activeWorkspaceId)) && ArrayLen(variables.accessibleWorkspaces) > 0) {
			local.foundWs = false;
			for (local.w in variables.accessibleWorkspaces) {
				if (local.w.id == "pio" || local.w.id == "communications") {
					variables.activeWsObj = local.w;
					variables.activeWorkspaceId = local.w.id;
					local.foundWs = true;
					break;
				}
			}
			if (!local.foundWs) {
				variables.activeWsObj = variables.accessibleWorkspaces[1];
				variables.activeWorkspaceId = variables.accessibleWorkspaces[1].id;
			}
		}

		ensureArticlesTableColumns();

		variables.article = {
			id: 0,
			title: "",
			slug: "",
			summary: "",
			content_html: "<p>Write your article news story here...</p>",
			category_id: 0,
			tags: "",
			featured_image: "",
			featured_image_alt: "",
			featured_image_caption: "",
			featured_image_description: "",
			featured_image_credit: "",
			featured_image_decorative: 0,
			author_name: StructKeyExists(session, "user") && IsStruct(session.user) ? (session.user.full_name ?: "Public Information Officer") : "Public Information Officer",
			author_title: "Public Information Office",
			status: "published",
			siteid: variables.activeWorkspaceId,
			published_at: Now(),
			meta_title: "",
			meta_description: ""
		};

		loadCategoriesAndTags();
		renderView(template="edit");
	}

	/**
	 * Edit Article Screen
	 */
	function edit() {
		local.id = Val(params.id ?: 0);
		if (local.id <= 0) {
			flashInsert(error="Invalid article ID specified.");
			redirectTo(controller="articles", action="index");
			return;
		}

		variables.pageTitle = "Edit Article";
		variables.isNew = false;

		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role == "admin");
		variables.isPIO = (local.role == "pio");

		ensureArticlesTableColumns();

		local.requestedWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.requestedWs, role = local.role);
		variables.activeWorkspaceId = LCase(Trim(variables.activeWsObj.id ?: "global"));
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);

		try {
			local.q = queryExecute("
				SELECT id, title, slug, summary, content_html, category_id, tags,
				       featured_image, featured_image_alt, featured_image_caption, featured_image_description, featured_image_credit, featured_image_decorative,
				       author_name, author_title,
				       status, siteid, published_at, meta_title, meta_description,
				       created_by, modified_by, createdat, updatedat
				FROM articles
				WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (!local.q.recordCount) {
				flashInsert(error="The requested article does not exist or has been removed.");
				redirectTo(controller="articles", action="index");
				return;
			}

			local.artWs = LCase(Trim(local.q.siteid ?: ""));
			if (Len(local.artWs) && local.artWs neq "global" && (!StructKeyExists(params, "ws") || !Len(Trim(params.ws)))) {
				variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.artWs, role = local.role);
				variables.activeWorkspaceId = LCase(Trim(variables.activeWsObj.id ?: local.artWs));
			} else if ((variables.activeWorkspaceId == "global" || !Len(variables.activeWorkspaceId)) && ArrayLen(variables.accessibleWorkspaces) > 0) {
				for (local.w in variables.accessibleWorkspaces) {
					if (local.w.id == "pio" || local.w.id == "communications") {
						variables.activeWsObj = local.w;
						variables.activeWorkspaceId = local.w.id;
						break;
					}
				}
			}

			variables.article = {
				id: local.q.id,
				title: local.q.title,
				slug: local.q.slug,
				summary: local.q.summary ?: "",
				content_html: local.q.content_html ?: "",
				category_id: Val(local.q.category_id ?: 0),
				tags: local.q.tags ?: "",
				featured_image: local.q.featured_image ?: "",
				featured_image_alt: local.q.featured_image_alt ?: "",
				featured_image_caption: local.q.featured_image_caption ?: "",
				featured_image_description: local.q.featured_image_description ?: "",
				featured_image_credit: local.q.featured_image_credit ?: "",
				featured_image_decorative: Val(local.q.featured_image_decorative ?: 0),
				author_name: local.q.author_name ?: "",
				author_title: local.q.author_title ?: "",
				status: local.q.status ?: "published",
				siteid: Len(local.artWs) ? local.artWs : variables.activeWorkspaceId,
				published_at: local.q.published_at ?: Now(),
				meta_title: local.q.meta_title ?: "",
				meta_description: local.q.meta_description ?: ""
			};
		} catch (any eFetch) {
			flashInsert(error="Error loading article: #eFetch.message#");
			redirectTo(controller="articles", action="index");
			return;
		}

		loadCategoriesAndTags();
	}

	/**
	 * Save (Insert / Update) Article via Form or AJAX
	 */
	function save() {
		local.body = readJsonOrParams();

		ensureArticlesTableColumns();

		local.id = Val(local.body.id ?: 0);
		local.title = Left(Trim(local.body.title ?: ""), 255);
		local.slug = generateSlug(Len(Trim(local.body.slug ?: "")) ? local.body.slug : local.title);
		local.summary = Left(Trim(local.body.summary ?: ""), 1000);
		local.contentHtml = Trim(local.body.content_html ?: (local.body.content ?: ""));
		local.categoryId = Val(local.body.category_id ?: 0);
		local.tags = Left(Trim(local.body.tags ?: ""), 500);
		local.featuredImage = Left(Trim(local.body.featured_image ?: ""), 1000);
		local.featuredImageAlt = Left(Trim(local.body.featured_image_alt ?: ""), 500);
		local.featuredImageCaption = Left(Trim(local.body.featured_image_caption ?: ""), 1000);
		local.featuredImageDescription = Left(Trim(local.body.featured_image_description ?: ""), 2000);
		local.featuredImageCredit = Left(Trim(local.body.featured_image_credit ?: ""), 255);
		local.featuredImageDecorative = Val(local.body.featured_image_decorative ?: 0) ? 1 : 0;
		local.authorName = Left(Trim(local.body.author_name ?: "Public Information Officer"), 255);
		local.authorTitle = Left(Trim(local.body.author_title ?: ""), 255);
		local.status = LCase(Trim(local.body.status ?: "published"));
		if (!ListFindNoCase("published,draft,archived", local.status)) local.status = "published";

		local.siteid = Len(Trim(local.body.siteid ?: "")) ? LCase(Trim(local.body.siteid)) : "global";
		local.metaTitle = Left(Trim(local.body.meta_title ?: ""), 255);
		local.metaDescription = Left(Trim(local.body.meta_description ?: ""), 500);

		local.publishedAt = Now();
		if (StructKeyExists(local.body, "published_at") && Len(Trim(local.body.published_at)) && IsDate(local.body.published_at)) {
			local.publishedAt = ParseDateTime(local.body.published_at);
		}

		if (!Len(local.title)) {
			return renderJsonEnvelope(false, "Article title is required.", {}, 400);
		}
		if (!Len(local.contentHtml)) {
			return renderJsonEnvelope(false, "Article content body cannot be empty.", {}, 400);
		}

		local.currentActor = resolveCurrentActor();

		try {
			if (local.id > 0) {
				// Update
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE articles
					SET title = :title,
					    slug = :slug,
					    summary = :summary,
					    content_html = :content_html,
					    category_id = :category_id,
					    tags = :tags,
					    featured_image = :featured_image,
					    featured_image_alt = :featured_image_alt,
					    featured_image_caption = :featured_image_caption,
					    featured_image_description = :featured_image_description,
					    featured_image_credit = :featured_image_credit,
					    featured_image_decorative = :featured_image_decorative,
					    author_name = :author_name,
					    author_title = :author_title,
					    status = :status,
					    siteid = :siteid,
					    published_at = :published_at,
					    meta_title = :meta_title,
					    meta_description = :meta_description,
					    modified_by = :modified_by,
					    updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					id: { value: local.id, cfsqltype: "cf_sql_integer" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					summary: { value: local.summary, cfsqltype: "cf_sql_varchar", null: !Len(local.summary) },
					content_html: { value: local.contentHtml, cfsqltype: "cf_sql_longvarchar" },
					category_id: { value: local.categoryId, cfsqltype: "cf_sql_integer", null: (local.categoryId <= 0) },
					tags: { value: local.tags, cfsqltype: "cf_sql_varchar", null: !Len(local.tags) },
					featured_image: { value: local.featuredImage, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImage) },
					featured_image_alt: { value: local.featuredImageAlt, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageAlt) },
					featured_image_caption: { value: local.featuredImageCaption, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageCaption) },
					featured_image_description: { value: local.featuredImageDescription, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageDescription) },
					featured_image_credit: { value: local.featuredImageCredit, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageCredit) },
					featured_image_decorative: { value: local.featuredImageDecorative, cfsqltype: "cf_sql_bit" },
					author_name: { value: local.authorName, cfsqltype: "cf_sql_varchar" },
					author_title: { value: local.authorTitle, cfsqltype: "cf_sql_varchar", null: !Len(local.authorTitle) },
					status: { value: local.status, cfsqltype: "cf_sql_varchar" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" },
					published_at: { value: local.publishedAt, cfsqltype: "cf_sql_timestamp" },
					meta_title: { value: local.metaTitle, cfsqltype: "cf_sql_varchar", null: !Len(local.metaTitle) },
					meta_description: { value: local.metaDescription, cfsqltype: "cf_sql_varchar", null: !Len(local.metaDescription) },
					modified_by: { value: local.currentActor, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				// Insert
				local.qIns = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO articles (
						title, slug, summary, content_html, category_id, tags,
						featured_image, featured_image_alt, featured_image_caption, featured_image_description, featured_image_credit, featured_image_decorative,
						author_name, author_title,
						status, siteid, published_at, meta_title, meta_description,
						created_by, modified_by, createdat, updatedat
					) VALUES (
						:title, :slug, :summary, :content_html, :category_id, :tags,
						:featured_image, :featured_image_alt, :featured_image_caption, :featured_image_description, :featured_image_credit, :featured_image_decorative,
						:author_name, :author_title,
						:status, :siteid, :published_at, :meta_title, :meta_description,
						:created_by, :modified_by, SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT SCOPE_IDENTITY() AS new_id;
				", {
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					summary: { value: local.summary, cfsqltype: "cf_sql_varchar", null: !Len(local.summary) },
					content_html: { value: local.contentHtml, cfsqltype: "cf_sql_longvarchar" },
					category_id: { value: local.categoryId, cfsqltype: "cf_sql_integer", null: (local.categoryId <= 0) },
					tags: { value: local.tags, cfsqltype: "cf_sql_varchar", null: !Len(local.tags) },
					featured_image: { value: local.featuredImage, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImage) },
					featured_image_alt: { value: local.featuredImageAlt, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageAlt) },
					featured_image_caption: { value: local.featuredImageCaption, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageCaption) },
					featured_image_description: { value: local.featuredImageDescription, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageDescription) },
					featured_image_credit: { value: local.featuredImageCredit, cfsqltype: "cf_sql_varchar", null: !Len(local.featuredImageCredit) },
					featured_image_decorative: { value: local.featuredImageDecorative, cfsqltype: "cf_sql_bit" },
					author_name: { value: local.authorName, cfsqltype: "cf_sql_varchar" },
					author_title: { value: local.authorTitle, cfsqltype: "cf_sql_varchar", null: !Len(local.authorTitle) },
					status: { value: local.status, cfsqltype: "cf_sql_varchar" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" },
					published_at: { value: local.publishedAt, cfsqltype: "cf_sql_timestamp" },
					meta_title: { value: local.metaTitle, cfsqltype: "cf_sql_varchar", null: !Len(local.metaTitle) },
					meta_description: { value: local.metaDescription, cfsqltype: "cf_sql_varchar", null: !Len(local.metaDescription) },
					created_by: { value: local.currentActor, cfsqltype: "cf_sql_varchar" },
					modified_by: { value: local.currentActor, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.id = Val(local.qIns.new_id);
			}

			// Auto-register tags in article_tags table
			syncTags(local.tags, local.siteid);

			flashInsert(success="Article '#local.title#' saved successfully.");
			return renderJsonEnvelope(true, "Article saved successfully.", {
				"id": local.id,
				"redirect": urlFor(controller="articles", action="index")
			});
		} catch (any eSave) {
			writeLog(type="error", file="articles", text="Save article failed: #eSave.message# #eSave.detail#");
			return renderJsonEnvelope(false, "Failed to save article: #eSave.message#", {}, 500);
		}
	}

	/**
	 * Soft Delete Article
	 */
	function delete() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: (params.id ?: 0));

		if (local.id <= 0) {
			return renderJsonEnvelope(false, "Invalid article ID specified.", {}, 400);
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE articles
				SET deletedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			flashInsert(success="Article removed successfully.");
			return renderJsonEnvelope(true, "Article deleted successfully.", {
				"redirect": urlFor(controller="articles", action="index")
			});
		} catch (any eDel) {
			return renderJsonEnvelope(false, "Error deleting article: #eDel.message#", {}, 500);
		}
	}

	/**
	 * Toggle Status (Published <-> Draft)
	 */
	function toggleStatus() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: (params.id ?: 0));

		if (local.id <= 0) {
			return renderJsonEnvelope(false, "Invalid article ID specified.", {}, 400);
		}

		try {
			local.q = queryExecute("SELECT status FROM articles WHERE id = :id AND deletedat IS NULL", {
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			if (!local.q.recordCount) {
				return renderJsonEnvelope(false, "Article not found.", {}, 404);
			}

			local.newStatus = (local.q.status == "published") ? "draft" : "published";

			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE articles
				SET status = :status, updatedat = SYSUTCDATETIME()
				WHERE id = :id
			", {
				id: { value: local.id, cfsqltype: "cf_sql_integer" },
				status: { value: local.newStatus, cfsqltype: "cf_sql_varchar" }
			}, { datasource: "ChelanCountyWebsite" });

			return renderJsonEnvelope(true, "Status updated to #local.newStatus#.", { "status": local.newStatus });
		} catch (any eToggle) {
			return renderJsonEnvelope(false, "Failed to toggle status: #eToggle.message#", {}, 500);
		}
	}

	/**
	 * Categories Management View
	 */
	function categories() {
		variables.pageTitle = "Article Categories";

		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role == "admin");
		variables.isPIO = (local.role == "pio");

		variables.categories = [];
		try {
			local.q = queryExecute("
				SELECT c.id, c.name, c.slug, c.description, c.badge_color, c.siteid, c.sort_order,
				       (SELECT COUNT(*) FROM articles a WHERE a.category_id = c.id AND a.deletedat IS NULL) AS article_count
				FROM article_categories c
				WHERE c.deletedat IS NULL
				ORDER BY c.sort_order ASC, c.name ASC
			", {}, { datasource: "ChelanCountyWebsite" });

			for (local.row in local.q) {
				ArrayAppend(variables.categories, {
					id: local.row.id,
					name: local.row.name,
					slug: local.row.slug,
					description: local.row.description ?: "",
					badge_color: local.row.badge_color ?: "##0284c7",
					siteid: local.row.siteid ?: "global",
					sort_order: Val(local.row.sort_order ?: 0),
					article_count: Val(local.row.article_count ?: 0)
				});
			}
		} catch (any e) {
			writeLog(type="error", file="articles", text="Categories load error: #e.message#");
		}
	}

	/**
	 * Save Article Category
	 */
	function saveCategory() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: 0);
		local.name = Left(Trim(local.body.name ?: ""), 150);
		local.slug = generateSlug(Len(Trim(local.body.slug ?: "")) ? local.body.slug : local.name);
		local.description = Left(Trim(local.body.description ?: ""), 500);
		local.badgeColor = Left(Trim(local.body.badge_color ?: "##0284c7"), 50);
		local.sortOrder = Val(local.body.sort_order ?: 0);
		local.siteid = Len(Trim(local.body.siteid ?: "")) ? LCase(Trim(local.body.siteid)) : "global";

		if (!Len(local.name)) {
			return renderJsonEnvelope(false, "Category name is required.", {}, 400);
		}

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE article_categories
					SET name = :name, slug = :slug, description = :description,
					    badge_color = :badge_color, sort_order = :sort_order,
					    siteid = :siteid, updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					id: { value: local.id, cfsqltype: "cf_sql_integer" },
					name: { value: local.name, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					description: { value: local.description, cfsqltype: "cf_sql_varchar", null: !Len(local.description) },
					badge_color: { value: local.badgeColor, cfsqltype: "cf_sql_varchar" },
					sort_order: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO article_categories (
						name, slug, description, badge_color, sort_order, siteid, createdat, updatedat
					) VALUES (
						:name, :slug, :description, :badge_color, :sort_order, :siteid, SYSUTCDATETIME(), SYSUTCDATETIME()
					)
				", {
					name: { value: local.name, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					description: { value: local.description, cfsqltype: "cf_sql_varchar", null: !Len(local.description) },
					badge_color: { value: local.badgeColor, cfsqltype: "cf_sql_varchar" },
					sort_order: { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });
			}

			flashInsert(success="Category '#local.name#' saved successfully.");
			return renderJsonEnvelope(true, "Category saved successfully.", {
				"redirect": urlFor(controller="articles", action="categories")
			});
		} catch (any eCat) {
			return renderJsonEnvelope(false, "Failed to save category: #eCat.message#", {}, 500);
		}
	}

	/**
	 * Delete Article Category
	 */
	function deleteCategory() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: (params.id ?: 0));

		if (local.id <= 0) {
			return renderJsonEnvelope(false, "Invalid category ID specified.", {}, 400);
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE article_categories
				SET deletedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL;
				-- Detach articles from this category
				UPDATE articles
				SET category_id = NULL
				WHERE category_id = :id;
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			flashInsert(success="Category removed successfully.");
			return renderJsonEnvelope(true, "Category deleted successfully.", {
				"redirect": urlFor(controller="articles", action="categories")
			});
		} catch (any eDel) {
			return renderJsonEnvelope(false, "Error deleting category: #eDel.message#", {}, 500);
		}
	}

	/**
	 * Tags Management View
	 */
	function tags() {
		variables.pageTitle = "Article Tags";

		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role == "admin");
		variables.isPIO = (local.role == "pio");

		variables.tagRecords = [];
		try {
			local.q = queryExecute("
				SELECT t.id, t.name, t.slug, t.siteid, t.createdat,
				       (SELECT COUNT(*) FROM articles a WHERE a.deletedat IS NULL AND (a.tags = t.name OR a.tags LIKE '%,' + t.name + ',%' OR a.tags LIKE t.name + ',%' OR a.tags LIKE '%,' + t.name)) AS usage_count
				FROM article_tags t
				WHERE t.deletedat IS NULL
				ORDER BY t.name ASC
			", {}, { datasource: "ChelanCountyWebsite" });

			for (local.row in local.q) {
				ArrayAppend(variables.tagRecords, {
					id: local.row.id,
					name: local.row.name,
					slug: local.row.slug,
					siteid: local.row.siteid ?: "global",
					usage_count: Val(local.row.usage_count ?: 0),
					createdat: local.row.createdat
				});
			}
		} catch (any e) {
			writeLog(type="error", file="articles", text="Tags load error: #e.message#");
		}
	}

	/**
	 * Save Article Tag
	 */
	function saveTag() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: 0);
		local.name = Left(Trim(local.body.name ?: ""), 100);
		local.slug = generateSlug(Len(Trim(local.body.slug ?: "")) ? local.body.slug : local.name);
		local.siteid = Len(Trim(local.body.siteid ?: "")) ? LCase(Trim(local.body.siteid)) : "global";

		if (!Len(local.name)) {
			return renderJsonEnvelope(false, "Tag name is required.", {}, 400);
		}

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE article_tags
					SET name = :name, slug = :slug, siteid = :siteid, updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					id: { value: local.id, cfsqltype: "cf_sql_integer" },
					name: { value: local.name, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					IF NOT EXISTS (SELECT 1 FROM article_tags WHERE slug = :slug AND deletedat IS NULL)
					BEGIN
						INSERT INTO article_tags (name, slug, siteid, createdat, updatedat)
						VALUES (:name, :slug, :siteid, SYSUTCDATETIME(), SYSUTCDATETIME())
					END
				", {
					name: { value: local.name, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					siteid: { value: local.siteid, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });
			}

			flashInsert(success="Tag '#local.name#' saved successfully.");
			return renderJsonEnvelope(true, "Tag saved successfully.", {
				"redirect": urlFor(controller="articles", action="tags")
			});
		} catch (any eTag) {
			return renderJsonEnvelope(false, "Failed to save tag: #eTag.message#", {}, 500);
		}
	}

	/**
	 * Delete Article Tag
	 */
	function deleteTag() {
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: (params.id ?: 0));

		if (local.id <= 0) {
			return renderJsonEnvelope(false, "Invalid tag ID specified.", {}, 400);
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE article_tags
				SET deletedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			flashInsert(success="Tag removed successfully.");
			return renderJsonEnvelope(true, "Tag deleted successfully.", {
				"redirect": urlFor(controller="articles", action="tags")
			});
		} catch (any eDel) {
			return renderJsonEnvelope(false, "Error deleting tag: #eDel.message#", {}, 500);
		}
	}

	/**
	 * Public REST/JSON API Endpoint
	 */
	function api() {
		try {
			local.site = StructKeyExists(params, "ws") ? Trim(params.ws) : "global";
			local.limit = StructKeyExists(params, "limit") ? Val(params.limit) : 10;
			if (local.limit <= 0 || local.limit > 50) local.limit = 10;

			local.q = queryExecute("
				SELECT TOP (#local.limit#) a.id, a.title, a.slug, a.summary, a.tags,
				       a.featured_image, a.author_name, a.published_at,
				       c.name AS category_name, c.slug AS category_slug, c.badge_color
				FROM articles a
				LEFT JOIN article_categories c ON a.category_id = c.id AND c.deletedat IS NULL
				WHERE a.deletedat IS NULL AND a.status = 'published'
				  AND (a.siteid = :site OR a.siteid = 'global')
				ORDER BY a.published_at DESC
			", { site: { value: local.site, cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			local.items = [];
			for (local.r in local.q) {
				local.pubDate = "";
				if (StructKeyExists(local.r, "published_at") && IsDate(local.r.published_at)) {
					local.pubDate = DateFormat(local.r.published_at, "yyyy-mm-dd") & "T" & TimeFormat(local.r.published_at, "HH:mm:ss") & "Z";
				}
				ArrayAppend(local.items, {
					"id": local.r.id,
					"title": local.r.title,
					"slug": local.r.slug,
					"summary": local.r.summary ?: "",
					"category": local.r.category_name ?: "News",
					"category_slug": local.r.category_slug ?: "news",
					"badge_color": local.r.badge_color ?: "##0284c7",
					"tags": Len(Trim(local.r.tags ?: "")) ? ListToArray(local.r.tags) : [],
					"featured_image": local.r.featured_image ?: "",
					"author": local.r.author_name ?: "Staff",
					"published_at": local.pubDate
				});
			}

			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text=SerializeJSON({
				"success": true,
				"count": ArrayLen(local.items),
				"articles": local.items
			}));
		} catch (any eApi) {
			writeLog(type="error", file="articles_api_debug", text="Articles API Error: #eApi.message# #eApi.detail#");
			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text=SerializeJSON({ "success": false, "error": eApi.message, "articles": [] }));
		}
	}

	// --------------------------------------------------------------------------
	// PRIVATE HELPERS
	// --------------------------------------------------------------------------

	private void function loadCategoriesAndTags() {
		variables.categories = [];
		try {
			local.q = queryExecute("
				SELECT id, name, slug, badge_color
				FROM article_categories
				WHERE deletedat IS NULL
				ORDER BY sort_order ASC, name ASC
			", {}, { datasource: "ChelanCountyWebsite" });
			for (local.c in local.q) {
				ArrayAppend(variables.categories, {
					id: local.c.id,
					name: local.c.name,
					slug: local.c.slug,
					badge_color: local.c.badge_color ?: "##0284c7"
				});
			}
		} catch (any e) {}

		variables.availableTags = [];
		try {
			local.qT = queryExecute("SELECT name, slug FROM article_tags WHERE deletedat IS NULL ORDER BY name ASC", {}, { datasource: "ChelanCountyWebsite" });
			for (local.t in local.qT) {
				ArrayAppend(variables.availableTags, {
					name: local.t.name,
					slug: local.t.slug
				});
			}
		} catch (any eT) {}
	}

	private void function syncTags(required string tagList, required string siteid) {
		if (!Len(Trim(arguments.tagList))) return;
		for (local.rawTag in ListToArray(arguments.tagList)) {
			local.tag = Trim(local.rawTag);
			if (Len(local.tag)) {
				local.slug = generateSlug(local.tag);
				try {
					queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						IF NOT EXISTS (SELECT 1 FROM article_tags WHERE slug = :slug AND deletedat IS NULL)
						BEGIN
							INSERT INTO article_tags (name, slug, siteid, createdat, updatedat)
							VALUES (:name, :slug, :siteid, SYSUTCDATETIME(), SYSUTCDATETIME())
						END
					", {
						name: { value: local.tag, cfsqltype: "cf_sql_varchar" },
						slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
						siteid: { value: arguments.siteid, cfsqltype: "cf_sql_varchar" }
					}, { datasource: "ChelanCountyWebsite" });
				} catch (any e) {}
			}
		}
	}

	private string function generateSlug(required string str) {
		local.clean = LCase(Trim(arguments.str));
		local.clean = REReplace(local.clean, "[^a-z0-9\s-]", "", "all");
		local.clean = REReplace(local.clean, "[\s-]+", "-", "all");
		local.clean = REReplace(local.clean, "^-+|-+$", "", "all");
		return Len(local.clean) ? local.clean : "article-" & DateFormat(Now(), "yyyymmdd") & "-" & TimeFormat(Now(), "hhmmss");
	}

	private struct function readJsonOrParams() {
		local.content = GetHttpRequestData().content;
		if (IsBinary(local.content)) {
			local.content = CharsetEncode(local.content, "utf-8");
		}
		if (Len(Trim(local.content)) && IsJSON(local.content)) {
			try {
				return DeserializeJSON(local.content);
			} catch (any e) {}
		}
		return params;
	}

	private string function resolveCurrentActor() {
		if (StructKeyExists(session, "user") && IsStruct(session.user)) {
			return session.user.full_name ?: (session.user.email ?: "PIO Staff");
		}
		return "PIO Staff";
	}

	private void function renderJsonEnvelope(required boolean success, required string message, struct data = {}, numeric statusCode = 200) {
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
		renderText(text=SerializeJSON(local.envelope), contentType="application/json", layout=false, status=arguments.statusCode);
	}

	/**
	 * Automatically verifies and adds ADA image metadata columns to articles table
	 */
	private void function ensureArticlesTableColumns() {
		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('articles') AND name = 'featured_image_caption')
					ALTER TABLE articles ADD featured_image_caption NVARCHAR(1000) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('articles') AND name = 'featured_image_description')
					ALTER TABLE articles ADD featured_image_description NVARCHAR(2000) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('articles') AND name = 'featured_image_credit')
					ALTER TABLE articles ADD featured_image_credit NVARCHAR(255) NULL;

				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('articles') AND name = 'featured_image_decorative')
					ALTER TABLE articles ADD featured_image_decorative BIT NOT NULL CONSTRAINT DF_articles_featured_image_decorative DEFAULT 0;
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {}
	}

}
