component extends="Controller" {

	function config() {
		super.config();
	}

	/**
	 * Workspaces Management Studio (Admin Only)
	 * Comprehensive directory of all 16 workspaces, municipal divisions, and public portals.
	 */
	function index() {
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		// Security gate: Only administrators can access workspace management
		if (!local.isAdmin) {
			flashInsert(error="Access Denied: Workspace administration is strictly restricted to System Administrators.");
			redirectTo(controller="main", action="index");
			return;
		}

		variables.pageTitle = "Workspaces Management";

		local.allWorkspaces = getMasterWorkspaces();
		local.users = [];

		// Query live staff accounts and workspace mappings from SQL Server database
		try {
			local.qUsers = queryExecute("
				SELECT u.id, u.first_name, u.last_name, u.email, u.username, u.job_title, u.role_code, u.department_code, u.assigned_workspaces
				FROM cms_users u
				WHERE u.deletedat IS NULL
				ORDER BY u.first_name ASC
			", {}, { datasource: "ChelanCountyWebsite" });

			local.qUserWs = queryExecute("
				SELECT user_id, workspace_code FROM cms_user_workspaces
			", {}, { datasource: "ChelanCountyWebsite" });

			local.userWsMap = {};
			for (local.uw in local.qUserWs) {
				if (!StructKeyExists(local.userWsMap, local.uw.user_id)) {
					local.userWsMap[local.uw.user_id] = [];
				}
				ArrayAppend(local.userWsMap[local.uw.user_id], local.uw.workspace_code);
			}

			for (local.uRow in local.qUsers) {
				local.uWs = StructKeyExists(local.userWsMap, local.uRow.id) ? local.userWsMap[local.uRow.id] : [];
				if (ArrayLen(local.uWs) == 0 && Len(local.uRow.assigned_workspaces)) {
					if (IsJSON(local.uRow.assigned_workspaces)) {
						local.uWs = DeserializeJSON(local.uRow.assigned_workspaces);
					} else {
						local.uWs = ListToArray(local.uRow.assigned_workspaces);
					}
				}
				if (ArrayLen(local.uWs) == 0) {
					local.uWs = [Len(local.uRow.department_code) ? local.uRow.department_code : "global"];
				}
				ArrayAppend(local.users, {
					id: local.uRow.id,
					first_name: local.uRow.first_name,
					last_name: local.uRow.last_name,
					name: local.uRow.first_name & " " & local.uRow.last_name,
					email: local.uRow.email,
					username: local.uRow.username,
					job_title: local.uRow.job_title,
					role_code: local.uRow.role_code,
					department_code: local.uRow.department_code,
					workspaces: local.uWs
				});
			}
		} catch (any err) {
			local.users = [];
		}

		// Calculate user counts & folder stats for each workspace
		for (local.w in local.allWorkspaces) {
			local.w.userCount = 0;
			local.w.usersList = [];

			for (local.u in local.users) {
				local.hasWs = false;
				if (StructKeyExists(local.u, "workspaces") && IsArray(local.u.workspaces)) {
					if (ArrayFindNoCase(local.u.workspaces, local.w.id) || (local.w.id neq "global" && ArrayFindNoCase(local.u.workspaces, "global"))) {
						local.hasWs = true;
					}
				} else if (StructKeyExists(local.u, "department_code") && (local.u.department_code eq local.w.id || local.u.department_code eq "global")) {
					local.hasWs = true;
				}

				if (local.hasWs) {
					local.w.userCount++;
					ArrayAppend(local.w.usersList, local.u);
				}
			}

			// Disk path check
			local.targetDiskPath = "C:\inetpub\CMSAdmin2.0\" & (StructKeyExists(local.w, "folderPath") ? local.w.folderPath : "files/" & local.w.id);
			local.w.diskExists = DirectoryExists(local.targetDiskPath);
		}

		// Multi-facet filtering
		local.filterType = StructKeyExists(params, "type") ? LCase(Trim(params.type)) : "all";
		local.searchQuery = StructKeyExists(params, "q") ? LCase(Trim(params.q)) : "";

		local.filtered = [];
		variables.metrics = {
			total: ArrayLen(local.allWorkspaces),
			dept: 0,
			site: 0,
			global: 0
		};

		for (local.w in local.allWorkspaces) {
			if (local.w.type eq "dept") variables.metrics.dept++;
			else if (local.w.type eq "site") variables.metrics.site++;
			else if (local.w.type eq "global") variables.metrics.global++;

			local.matches = true;

			if (local.filterType neq "all" && local.w.type neq local.filterType) {
				local.matches = false;
			}

			if (Len(local.searchQuery)) {
				local.contactText = "";
				if (StructKeyExists(local.w, "contact") && IsStruct(local.w.contact)) {
					local.contactText = (StructKeyExists(local.w.contact, "first_name") ? local.w.contact.first_name : "") & " " & 
					                    (StructKeyExists(local.w.contact, "last_name") ? local.w.contact.last_name : "") & " " & 
					                    (StructKeyExists(local.w.contact, "email") ? local.w.contact.email : "") & " " & 
					                    (StructKeyExists(local.w.contact, "phone") ? local.w.contact.phone : "") & " " & 
					                    (StructKeyExists(local.w.contact, "city") ? local.w.contact.city : "") & " " & 
					                    (StructKeyExists(local.w.contact, "address") ? local.w.contact.address : "");
				}
				local.haystack = LCase(
					local.w.name & " " & 
					local.w.id & " " & 
					(StructKeyExists(local.w, "virtual_directory") ? local.w.virtual_directory : "") & " " & 
					(StructKeyExists(local.w, "department") ? local.w.department : "") & " " & 
					(StructKeyExists(local.w, "department_category") ? local.w.department_category : "") & " " & 
					(StructKeyExists(local.w, "redirect_url") ? local.w.redirect_url : "") & " " & 
					local.contactText & " " & 
					local.w.desc
				);
				if (!Find(local.searchQuery, local.haystack)) {
					local.matches = false;
				}
			}

			if (local.matches) {
				ArrayAppend(local.filtered, local.w);
			}
		}

		variables.workspaces = local.filtered;
		variables.activeFilterType = local.filterType;
		variables.activeSearchQuery = local.searchQuery;
		variables.currentActiveWs = StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace)) ? LCase(Trim(cookie.cmsadmin_workspace)) : "global";
	}

	/**
	 * Create New Workspace Form
	 */
	function new() {
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		if (!local.isAdmin) {
			flashInsert(error="Access Denied: Workspace creation is strictly restricted to System Administrators.");
			redirectTo(controller="main", action="index");
			return;
		}

		variables.pageTitle = "Create New Workspace";

		variables.departmentCategories = [
			"Community Services",
			"County Administration",
			"Law Enforcement",
			"Law and Judicial Services",
			"Finance and Records",
			"Internal Services",
			"Chelan-Douglas",
			"Community Outreach"
		];

		variables.workspace = {
			type: "dept",
			site_name: "",
			virtual_directory: "",
			color: "##7e22ce",
			department: "",
			department_category: "",
			redirect_url: "",
			contact_first_name: "",
			contact_last_name: "",
			contact_email: "",
			contact_phone: "",
			contact_fax: "",
			address: "",
			address2: "",
			city: "Wenatchee",
			state: "WA",
			zip: "98801",
			office_hours: ""
		};
	}

	/**
	 * Save / Provision New Workspace
	 */
	function create() {
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		if (!local.isAdmin) {
			flashInsert(error="Access Denied: Workspace creation is strictly restricted to System Administrators.");
			redirectTo(controller="main", action="index");
			return;
		}

		local.siteName = StructKeyExists(params, "site_name") ? Trim(params.site_name) : "";
		local.virtualDir = StructKeyExists(params, "virtual_directory") ? LCase(Trim(params.virtual_directory)) : "";

		if (!Len(local.siteName) || !Len(local.virtualDir)) {
			flashInsert(error="Please provide both Site Name and Virtual Directory.");
			redirectTo(controller="workspaces", action="new");
			return;
		}

		// Sanitize virtual directory identifier
		local.cleanId = REReplace(local.virtualDir, "[^a-z0-9\-_]", "", "all");
		if (!Len(local.cleanId)) {
			local.cleanId = REReplace(LCase(local.siteName), "[^a-z0-9]+", "-", "all");
		}

		// Ensure unique ID
		local.all = getMasterWorkspaces();
		for (local.w in local.all) {
			if (local.w.id eq local.cleanId) {
				flashInsert(error="A workspace with identifier '<strong>" & local.cleanId & "</strong>' already exists. Please choose a unique virtual directory.");
				redirectTo(controller="workspaces", action="new");
				return;
			}
		}

		local.department = StructKeyExists(params, "department") ? Trim(params.department) : local.siteName;
		local.deptCategory = StructKeyExists(params, "department_category") ? Trim(params.department_category) : "";
		local.redirectUrl = StructKeyExists(params, "redirect_url") ? Trim(params.redirect_url) : "";

		// Contact details
		local.email = StructKeyExists(params, "contact_email") ? Trim(params.contact_email) : "";

		// Workspace type / marker: Department vs Site / Portal
		local.type = (StructKeyExists(params, "type") && params.type eq "site") ? "site" : "dept";
		local.icon = (local.type eq "site") ? "globe" : "building";
		local.badge = Len(local.deptCategory) ? local.deptCategory : (local.type eq "site" ? "Site" : "Dept");
		local.badgeClass = (local.type eq "site") ? "badge-success" : "badge-info";

		local.color = StructKeyExists(params, "color") ? Trim(params.color) : (local.type eq "site" ? "##10b981" : "##7e22ce");
		if (Len(local.color) && Left(local.color, 1) neq "##") {
			local.color = "##" & local.color;
		}
		if (!REFindNoCase("^##[0-9a-fA-F]{3,8}$", local.color)) {
			local.color = (local.type eq "site" ? "##10b981" : "##7e22ce");
		}

		local.newWs = {
			id: local.cleanId,
			code: local.cleanId,
			name: local.siteName,
			type: local.type,
			color: local.color,
			badge: (Len(local.badge) > 12 ? Left(local.badge, 10) & ".." : local.badge),
			badgeClass: local.badgeClass,
			icon: local.icon,
			desc: Len(local.deptCategory) ? (local.deptCategory & " - " & local.department) : (local.department & " Portal"),
			folderPath: "files/" & local.cleanId,
			virtual_directory: local.cleanId,
			department: local.department,
			department_category: local.deptCategory,
			redirect_url: local.redirectUrl,
			contact: {
				first_name: StructKeyExists(params, "contact_first_name") ? Trim(params.contact_first_name) : "",
				last_name: StructKeyExists(params, "contact_last_name") ? Trim(params.contact_last_name) : "",
				email: local.email,
				phone: StructKeyExists(params, "contact_phone") ? Trim(params.contact_phone) : "",
				fax: StructKeyExists(params, "contact_fax") ? Trim(params.contact_fax) : "",
				address: StructKeyExists(params, "address") ? Trim(params.address) : "",
				address2: StructKeyExists(params, "address2") ? Trim(params.address2) : "",
				city: StructKeyExists(params, "city") ? Trim(params.city) : "Wenatchee",
				state: StructKeyExists(params, "state") ? Trim(params.state) : "WA",
				zip: StructKeyExists(params, "zip") ? Trim(params.zip) : "98801",
				office_hours: StructKeyExists(params, "office_hours") ? Trim(params.office_hours) : ""
			},
			created_at: DateFormat(Now(), "mmm d, yyyy")
		};

		// Automatically create files/[cleanId] on disk with media and documents subfolders
		try {
			local.baseWsDir = "C:\inetpub\CMSAdmin2.0\files\" & local.cleanId;
			local.targetMediaDir = local.baseWsDir & "\media";
			local.targetDocsDir = local.baseWsDir & "\documents";
			if (!DirectoryExists(local.baseWsDir)) CreateObject("java", "java.io.File").init(local.baseWsDir).mkdirs();
			if (!DirectoryExists(local.targetMediaDir)) CreateObject("java", "java.io.File").init(local.targetMediaDir).mkdirs();
			if (!DirectoryExists(local.targetDocsDir)) CreateObject("java", "java.io.File").init(local.targetDocsDir).mkdirs();
		} catch (any err) {}

		// Persist into SQL Server database
		try {
			local.queryParams = {
				code: { value: local.cleanId, cfsqltype: "cf_sql_varchar" },
				name: { value: local.siteName, cfsqltype: "cf_sql_varchar" },
				alias: { value: local.cleanId, cfsqltype: "cf_sql_varchar" },
				type: { value: local.type, cfsqltype: "cf_sql_varchar" },
				badge: { value: local.newWs.badge, cfsqltype: "cf_sql_varchar" },
				badge_class: { value: local.badgeClass, cfsqltype: "cf_sql_varchar" },
				icon: { value: local.icon, cfsqltype: "cf_sql_varchar" },
				description: { value: local.newWs.desc, cfsqltype: "cf_sql_varchar" },
				folder_path: { value: local.newWs.folderPath, cfsqltype: "cf_sql_varchar" },
				virtual_directory: { value: local.cleanId, cfsqltype: "cf_sql_varchar" },
				redirect_url: { value: local.redirectUrl, cfsqltype: "cf_sql_varchar" },
				department: { value: local.department, cfsqltype: "cf_sql_varchar" },
				department_category: { value: local.deptCategory, cfsqltype: "cf_sql_varchar" },
				contact_first_name: { value: local.newWs.contact.first_name, cfsqltype: "cf_sql_varchar" },
				contact_last_name: { value: local.newWs.contact.last_name, cfsqltype: "cf_sql_varchar" },
				contact_email: { value: local.newWs.contact.email, cfsqltype: "cf_sql_varchar" },
				contact_phone: { value: local.newWs.contact.phone, cfsqltype: "cf_sql_varchar" },
				contact_fax: { value: local.newWs.contact.fax, cfsqltype: "cf_sql_varchar" },
				address: { value: local.newWs.contact.address, cfsqltype: "cf_sql_varchar" },
				address2: { value: local.newWs.contact.address2, cfsqltype: "cf_sql_varchar" },
				city: { value: local.newWs.contact.city, cfsqltype: "cf_sql_varchar" },
				state: { value: local.newWs.contact.state, cfsqltype: "cf_sql_varchar" },
				zip: { value: local.newWs.contact.zip, cfsqltype: "cf_sql_varchar" },
				office_hours: { value: local.newWs.contact.office_hours, cfsqltype: "cf_sql_varchar" },
				color: { value: local.color, cfsqltype: "cf_sql_varchar" }
			};

			local.qExisting = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT id, code, deletedat FROM cms_workspaces WHERE code = :code
			", { code: { value: local.cleanId, cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			if (local.qExisting.recordCount gt 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE cms_workspaces SET
						name = :name,
						alias = :alias,
						type = :type,
						badge = :badge,
						badge_class = :badge_class,
						icon = :icon,
						description = :description,
						folder_path = :folder_path,
						virtual_directory = :virtual_directory,
						redirect_url = :redirect_url,
						department = :department,
						department_category = :department_category,
						contact_first_name = :contact_first_name,
						contact_last_name = :contact_last_name,
						contact_email = :contact_email,
						contact_phone = :contact_phone,
						contact_fax = :contact_fax,
						address = :address,
						address2 = :address2,
						city = :city,
						state = :state,
						zip = :zip,
						office_hours = :office_hours,
						is_active = 1,
						deletedat = NULL,
						color = :color
					WHERE code = :code
				", local.queryParams, { datasource: "ChelanCountyWebsite" });
			} else {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO cms_workspaces (
						code, name, alias, type, badge, badge_class, icon, description,
						folder_path, virtual_directory, redirect_url, department, department_category,
						contact_first_name, contact_last_name, contact_email, contact_phone, contact_fax,
						address, address2, city, state, zip, office_hours, is_active, is_system, sort_order, color
					) VALUES (
						:code, :name, :alias, :type, :badge, :badge_class, :icon, :description,
						:folder_path, :virtual_directory, :redirect_url, :department, :department_category,
						:contact_first_name, :contact_last_name, :contact_email, :contact_phone, :contact_fax,
						:address, :address2, :city, :state, :zip, :office_hours, 1, 0, 100, :color
					)
				", local.queryParams, { datasource: "ChelanCountyWebsite" });
			}
		} catch (any dberr) {
			local.dbMessage = dberr.message & (Len(dberr.detail ?: "") ? " - " & dberr.detail : "");
			flashInsert(error="The workspace could not be saved: " & EncodeForHTML(local.dbMessage));
			redirectTo(controller="workspaces", action="new");
			return;
		}

		// Invalidate cache so fresh data is loaded from database
		StructDelete(application, "cmsWorkspacesList");

		flashInsert(success="Workspace <strong>" & local.newWs.name & "</strong> (<code>" & local.cleanId & "</code>) created successfully with dedicated folder <code>files/" & local.cleanId & "</code>.");
		redirectTo(controller="workspaces", action="index");
	}

	/**
	 * Edit Workspace Form
	 */
	function edit() {
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		if (!local.isAdmin) {
			flashInsert(error="Access Denied: Workspace management is strictly restricted to System Administrators.");
			redirectTo(controller="main", action="index");
			return;
		}

		local.targetId = StructKeyExists(params, "id") ? Trim(params.id) : (StructKeyExists(params, "key") ? Trim(params.key) : "");
		local.targetWs = {};

		try {
			local.qWs = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT id, code, name, alias, type, badge, badge_class, icon, description,
				       folder_path, virtual_directory, redirect_url, department, department_category,
				       contact_first_name, contact_last_name, contact_email, contact_phone, contact_fax,
				       address, address2, city, state, zip, office_hours, is_active, is_system, sort_order, color
				FROM cms_workspaces
				WHERE (code = :targetId OR alias = :targetId) AND deletedat IS NULL
			", { targetId: { value: local.targetId, cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			if (local.qWs.recordCount gt 0) {
				local.row = local.qWs;
				local.targetWs = {
					id: local.row.code,
					code: local.row.code,
					name: local.row.name,
					alias: Len(local.row.alias ?: "") ? local.row.alias : "",
					type: local.row.type,
					color: (StructKeyExists(local.row, "color") && Len(Trim(local.row.color))) ? Trim(local.row.color) : (local.row.type eq "dept" ? "##7e22ce" : (local.row.type eq "site" ? "##10b981" : "##0073aa")),
					badge: local.row.badge,
					badgeClass: local.row.badge_class,
					icon: local.row.icon,
					desc: Len(local.row.description ?: "") ? local.row.description : "",
					folderPath: local.row.folder_path,
					virtual_directory: local.row.virtual_directory,
					department: local.row.department,
					department_category: local.row.department_category,
					redirect_url: local.row.redirect_url,
					is_system: (IsNumeric(local.row.is_system) && local.row.is_system eq 1),
					contact: {
						first_name: Len(local.row.contact_first_name ?: "") ? local.row.contact_first_name : "",
						last_name: Len(local.row.contact_last_name ?: "") ? local.row.contact_last_name : "",
						email: Len(local.row.contact_email ?: "") ? local.row.contact_email : "",
						phone: Len(local.row.contact_phone ?: "") ? local.row.contact_phone : "",
						fax: Len(local.row.contact_fax ?: "") ? local.row.contact_fax : "",
						address: Len(local.row.address ?: "") ? local.row.address : "",
						address2: Len(local.row.address2 ?: "") ? local.row.address2 : "",
						city: Len(local.row.city ?: "") ? local.row.city : "Wenatchee",
						state: Len(local.row.state ?: "") ? local.row.state : "WA",
						zip: Len(local.row.zip ?: "") ? local.row.zip : "98801",
						office_hours: Len(local.row.office_hours ?: "") ? local.row.office_hours : ""
					}
				};
			}
		} catch (any err) {}

		// Fallback check against master catalog
		if (StructIsEmpty(local.targetWs)) {
			local.all = getMasterWorkspaces();
			for (local.w in local.all) {
				if (local.w.id eq local.targetId || (StructKeyExists(local.w, "alias") && local.w.alias eq local.targetId)) {
					local.targetWs = local.w;
					break;
				}
			}
		}

		if (StructIsEmpty(local.targetWs)) {
			flashInsert(error="Workspace '<strong>" & EncodeForHTML(local.targetId) & "</strong>' not found.");
			redirectTo(controller="workspaces", action="index");
			return;
		}

		variables.pageTitle = "Edit Workspace: " & local.targetWs.name;

		variables.departmentCategories = [
			"Community Services",
			"County Administration",
			"Law Enforcement",
			"Law and Judicial Services",
			"Finance and Records",
			"Internal Services",
			"Chelan-Douglas",
			"Community Outreach"
		];

		local.c = (StructKeyExists(local.targetWs, "contact") && IsStruct(local.targetWs.contact)) ? local.targetWs.contact : {};

		variables.workspace = {
			id: local.targetWs.id,
			type: StructKeyExists(local.targetWs, "type") ? local.targetWs.type : "dept",
			site_name: local.targetWs.name,
			virtual_directory: StructKeyExists(local.targetWs, "virtual_directory") ? local.targetWs.virtual_directory : local.targetWs.id,
			color: (StructKeyExists(local.targetWs, "color") && Len(Trim(local.targetWs.color))) ? Trim(local.targetWs.color) : (local.targetWs.type eq "dept" ? "##7e22ce" : (local.targetWs.type eq "site" ? "##10b981" : "##0073aa")),
			department: StructKeyExists(local.targetWs, "department") ? local.targetWs.department : local.targetWs.name,
			department_category: StructKeyExists(local.targetWs, "department_category") ? local.targetWs.department_category : "",
			redirect_url: StructKeyExists(local.targetWs, "redirect_url") ? local.targetWs.redirect_url : "",
			is_system: StructKeyExists(local.targetWs, "is_system") ? local.targetWs.is_system : (local.targetWs.id eq "global"),
			contact_first_name: StructKeyExists(local.c, "first_name") ? local.c.first_name : "",
			contact_last_name: StructKeyExists(local.c, "last_name") ? local.c.last_name : "",
			contact_email: StructKeyExists(local.c, "email") ? local.c.email : "",
			contact_phone: StructKeyExists(local.c, "phone") ? local.c.phone : "",
			contact_fax: StructKeyExists(local.c, "fax") ? local.c.fax : "",
			address: StructKeyExists(local.c, "address") ? local.c.address : "",
			address2: StructKeyExists(local.c, "address2") ? local.c.address2 : "",
			city: (StructKeyExists(local.c, "city") && Len(local.c.city)) ? local.c.city : "Wenatchee",
			state: (StructKeyExists(local.c, "state") && Len(local.c.state)) ? local.c.state : "WA",
			zip: (StructKeyExists(local.c, "zip") && Len(local.c.zip)) ? local.c.zip : "98801",
			office_hours: StructKeyExists(local.c, "office_hours") ? local.c.office_hours : ""
		};
	}

	/**
	 * Update Workspace
	 */
	function update() {
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		if (!local.isAdmin) {
			flashInsert(error="Access Denied: Workspace management is strictly restricted to System Administrators.");
			redirectTo(controller="main", action="index");
			return;
		}

		local.targetId = StructKeyExists(params, "id") ? Trim(params.id) : (StructKeyExists(params, "key") ? Trim(params.key) : "");
		local.all = getMasterWorkspaces();
		local.foundIndex = 0;

		for (local.i = 1; local.i <= ArrayLen(local.all); local.i++) {
			if (local.all[local.i].id eq local.targetId || (StructKeyExists(local.all[local.i], "alias") && local.all[local.i].alias eq local.targetId)) {
				local.foundIndex = local.i;
				break;
			}
		}

		if (local.foundIndex eq 0) {
			flashInsert(error="Workspace '<strong>" & EncodeForHTML(local.targetId) & "</strong>' not found.");
			redirectTo(controller="workspaces", action="index");
			return;
		}

		local.existing = local.all[local.foundIndex];
		local.siteName = StructKeyExists(params, "site_name") ? Trim(params.site_name) : local.existing.name;
		local.virtualDir = StructKeyExists(params, "virtual_directory") ? LCase(Trim(params.virtual_directory)) : (StructKeyExists(local.existing, "virtual_directory") ? local.existing.virtual_directory : local.existing.id);

		local.cleanId = REReplace(local.virtualDir, "[^a-z0-9\-_]", "", "all");
		if (!Len(local.cleanId)) local.cleanId = local.existing.id;

		local.department = StructKeyExists(params, "department") ? Trim(params.department) : (StructKeyExists(local.existing, "department") ? local.existing.department : local.siteName);
		local.deptCategory = StructKeyExists(params, "department_category") ? Trim(params.department_category) : "";
		local.redirectUrl = StructKeyExists(params, "redirect_url") ? Trim(params.redirect_url) : "";
		local.email = StructKeyExists(params, "contact_email") ? Trim(params.contact_email) : "";

		// Workspace type / marker: Department vs Site / Portal
		if (StructKeyExists(params, "type") && (params.type eq "site" || params.type eq "dept" || params.type eq "global")) {
			local.existing.type = params.type;
			if (local.existing.type eq "site") {
				local.existing.icon = "globe";
				local.existing.badgeClass = "badge-success";
			} else if (local.existing.type eq "dept") {
				local.existing.icon = "building";
				local.existing.badgeClass = "badge-info";
			}
		}

		local.badge = Len(local.deptCategory) ? local.deptCategory : (StructKeyExists(local.existing, "badge") ? local.existing.badge : (local.existing.type eq "site" ? "Site" : "Dept"));

		// Update properties on the workspace struct
		local.existing.name = local.siteName;
		local.existing.department = local.department;
		local.existing.department_category = local.deptCategory;
		local.existing.redirect_url = local.redirectUrl;
		local.existing.virtual_directory = local.cleanId;
		local.existing.badge = (Len(local.badge) > 12 ? Left(local.badge, 10) & ".." : local.badge);
		local.existing.desc = Len(local.deptCategory) ? (local.deptCategory & " - " & local.department) : (local.department & " Portal");
		local.existing.folderPath = "files/" & local.cleanId;

		local.existing.contact = {
			first_name: StructKeyExists(params, "contact_first_name") ? Trim(params.contact_first_name) : "",
			last_name: StructKeyExists(params, "contact_last_name") ? Trim(params.contact_last_name) : "",
			email: local.email,
			phone: StructKeyExists(params, "contact_phone") ? Trim(params.contact_phone) : "",
			fax: StructKeyExists(params, "contact_fax") ? Trim(params.contact_fax) : "",
			address: StructKeyExists(params, "address") ? Trim(params.address) : "",
			address2: StructKeyExists(params, "address2") ? Trim(params.address2) : "",
			city: StructKeyExists(params, "city") ? Trim(params.city) : "Wenatchee",
			state: StructKeyExists(params, "state") ? Trim(params.state) : "WA",
			zip: StructKeyExists(params, "zip") ? Trim(params.zip) : "98801",
			office_hours: StructKeyExists(params, "office_hours") ? Trim(params.office_hours) : ""
		};

		// Ensure disk folder exists
		try {
			local.baseWsDir = "C:\inetpub\CMSAdmin2.0\files\" & local.cleanId;
			local.targetMediaDir = local.baseWsDir & "\media";
			local.targetDocsDir = local.baseWsDir & "\documents";
			if (!DirectoryExists(local.baseWsDir)) CreateObject("java", "java.io.File").init(local.baseWsDir).mkdirs();
			if (!DirectoryExists(local.targetMediaDir)) CreateObject("java", "java.io.File").init(local.targetMediaDir).mkdirs();
			if (!DirectoryExists(local.targetDocsDir)) CreateObject("java", "java.io.File").init(local.targetDocsDir).mkdirs();
		} catch (any err) {}

		local.type = local.existing.type;
		local.icon = StructKeyExists(local.existing, "icon") ? local.existing.icon : (local.type eq "site" ? "globe" : "building");
		local.badgeClass = StructKeyExists(local.existing, "badgeClass") ? local.existing.badgeClass : "badge-info";

		local.color = StructKeyExists(params, "color") ? Trim(params.color) : (StructKeyExists(local.existing, "color") ? local.existing.color : "##0073aa");
		if (Len(local.color) && Left(local.color, 1) neq "##") {
			local.color = "##" & local.color;
		}
		if (!REFindNoCase("^##[0-9a-fA-F]{3,8}$", local.color)) {
			local.color = (local.existing.type eq "dept" ? "##7e22ce" : (local.existing.type eq "site" ? "##10b981" : "##0073aa"));
		}
		local.existing.color = local.color;

		// Persist update into SQL Server database
		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE cms_workspaces SET
					name = :name,
					type = :type,
					badge = :badge,
					badge_class = :badge_class,
					icon = :icon,
					description = :description,
					folder_path = :folder_path,
					virtual_directory = :virtual_directory,
					redirect_url = :redirect_url,
					department = :department,
					department_category = :department_category,
					contact_first_name = :contact_first_name,
					contact_last_name = :contact_last_name,
					contact_email = :contact_email,
					contact_phone = :contact_phone,
					contact_fax = :contact_fax,
					address = :address,
					address2 = :address2,
					city = :city,
					state = :state,
					zip = :zip,
					office_hours = :office_hours,
					color = :color,
					updatedat = SYSUTCDATETIME()
				WHERE code = :code
			", {
				name: { value: local.siteName, cfsqltype: "cf_sql_varchar" },
				type: { value: local.type, cfsqltype: "cf_sql_varchar" },
				badge: { value: local.existing.badge, cfsqltype: "cf_sql_varchar" },
				badge_class: { value: local.badgeClass, cfsqltype: "cf_sql_varchar" },
				icon: { value: local.icon, cfsqltype: "cf_sql_varchar" },
				description: { value: local.existing.desc, cfsqltype: "cf_sql_varchar" },
				folder_path: { value: local.existing.folderPath, cfsqltype: "cf_sql_varchar" },
				virtual_directory: { value: local.cleanId, cfsqltype: "cf_sql_varchar" },
				redirect_url: { value: local.redirectUrl, cfsqltype: "cf_sql_varchar" },
				department: { value: local.department, cfsqltype: "cf_sql_varchar" },
				department_category: { value: local.deptCategory, cfsqltype: "cf_sql_varchar" },
				contact_first_name: { value: local.existing.contact.first_name, cfsqltype: "cf_sql_varchar" },
				contact_last_name: { value: local.existing.contact.last_name, cfsqltype: "cf_sql_varchar" },
				contact_email: { value: local.existing.contact.email, cfsqltype: "cf_sql_varchar" },
				contact_phone: { value: local.existing.contact.phone, cfsqltype: "cf_sql_varchar" },
				contact_fax: { value: local.existing.contact.fax, cfsqltype: "cf_sql_varchar" },
				address: { value: local.existing.contact.address, cfsqltype: "cf_sql_varchar" },
				address2: { value: local.existing.contact.address2, cfsqltype: "cf_sql_varchar" },
				city: { value: local.existing.contact.city, cfsqltype: "cf_sql_varchar" },
				state: { value: local.existing.contact.state, cfsqltype: "cf_sql_varchar" },
				zip: { value: local.existing.contact.zip, cfsqltype: "cf_sql_varchar" },
				office_hours: { value: local.existing.contact.office_hours, cfsqltype: "cf_sql_varchar" },
				color: { value: local.color, cfsqltype: "cf_sql_varchar" },
				code: { value: local.existing.id, cfsqltype: "cf_sql_varchar" }
			}, { datasource: "ChelanCountyWebsite" });
		} catch (any dberr) {
			StructDelete(application, "cmsWorkspacesList");
			local.dbMessage = dberr.message & (Len(dberr.detail ?: "") ? " - " & dberr.detail : "");
			flashInsert(error="The workspace could not be updated: " & EncodeForHTML(local.dbMessage));
			redirectTo(controller="workspaces", action="edit", params="id=" & local.targetId);
			return;
		}

		// Invalidate cache so fresh data is queried from database
		StructDelete(application, "cmsWorkspacesList");

		flashInsert(success="Workspace <strong>" & local.existing.name & "</strong> updated successfully.");
		redirectTo(controller="workspaces", action="index");
	}

	/**
	 * Deactivate / Delete Workspace (Admin Only)
	 * System workspaces (e.g. 'global') cannot be deleted.
	 */
	function delete() {
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		if (!local.isAdmin) {
			flashInsert(error="Access Denied: Workspace deletion is strictly restricted to System Administrators.");
			redirectTo(controller="main", action="index");
			return;
		}

		local.targetId = StructKeyExists(params, "id") ? Trim(params.id) : (StructKeyExists(params, "key") ? Trim(params.key) : "");

		if (local.targetId eq "global") {
			flashInsert(error="Cannot delete system-protected workspace 'All Workspaces (Global)'.");
			redirectTo(controller="workspaces", action="index");
			return;
		}

		try {
			// Check if workspace exists
			local.qCheck = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT id, code, name, is_system FROM cms_workspaces WHERE (code = :code OR alias = :code) AND deletedat IS NULL
			", { code: { value: local.targetId, cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			if (local.qCheck.recordCount eq 0) {
				flashInsert(error="Workspace '<strong>" & EncodeForHTML(local.targetId) & "</strong>' not found.");
				redirectTo(controller="workspaces", action="index");
				return;
			}

			if (local.qCheck.is_system eq 1) {
				flashInsert(error="Cannot delete system-protected workspace '<strong>" & local.qCheck.name & "</strong>'.");
				redirectTo(controller="workspaces", action="index");
				return;
			}

			// Soft delete from database
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE cms_workspaces SET deletedat = SYSUTCDATETIME(), is_active = 0 WHERE code = :code
			", { code: { value: local.qCheck.code, cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			// If the deleted workspace was the currently active workspace cookie, reset to global
			if (StructKeyExists(cookie, "cmsadmin_workspace") && LCase(Trim(cookie.cmsadmin_workspace)) eq LCase(local.qCheck.code)) {
				cookie.cmsadmin_workspace = "global";
			}

			// Invalidate cache
			StructDelete(application, "cmsWorkspacesList");

			flashInsert(success="Workspace <strong>" & local.qCheck.name & "</strong> (<code>" & local.qCheck.code & "</code>) was successfully deleted.");
		} catch (any err) {
			flashInsert(error="Failed to delete workspace: " & err.message);
		}

		redirectTo(controller="workspaces", action="index");
	}

}
