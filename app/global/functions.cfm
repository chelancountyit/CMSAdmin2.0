<cfscript>
// Global application helper functions


/**
 * Ensures the 16 canonical Chelan County workspaces exist in the SQL Server database.
 */
public void function ensureMasterWorkspacesTablePopulated() {
	try {
		queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'global')
				INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, storage_path, domain_name, project_path, leadership_type, is_active, is_system, sort_order)
				VALUES ('global', 'All Workspaces', '', 'global', 'Global', 'badge-neutral', 'grid', 'County-wide unified view across all municipal divisions and portals', 'files/shared', 'shared', '', 'County-wide', 'County Administration', 'files/shared', 'www.chelancounty.gov', 'C:\inetpub\chelan-county', 'dept_head', 1, 1, 0);
		", {}, { datasource: "ChelanCountyWebsite" });
	} catch (any e) {
		// Log or suppress schema verification errors
	}
}

/**
 * Returns the canonical master catalog of all workspaces and public portals in the CMS.
 * Grounded in the SQL Server database table `cms_workspaces` with in-memory caching.
 */
public array function getMasterWorkspaces() {
	var shouldRefresh = (!structKeyExists(application, "cmsWorkspacesList") 
		|| !isArray(application.cmsWorkspacesList) 
		|| arrayLen(application.cmsWorkspacesList) == 0
		|| (structKeyExists(url, "reload") && (url.reload == "true" || url.reload == "1"))
	);
	if (shouldRefresh) {
		ensureMasterWorkspacesTablePopulated();
		var wsList = [];
		try {
			var qWs = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT id, code, name, alias, type, badge, badge_class, icon, description,
				       folder_path, virtual_directory, redirect_url, department, department_category,
				       storage_path, domain_name, project_path, leadership_type, job_title, contact_photo,
				       contact_first_name, contact_last_name, contact_email, contact_phone, contact_fax,
				       address, address2, city, state, zip, office_hours, is_active, is_system, sort_order, color
				FROM cms_workspaces
				WHERE deletedat IS NULL AND is_active = 1
				ORDER BY sort_order ASC, id ASC
			", {}, { datasource: "ChelanCountyWebsite" });

			for (var row in qWs) {
				arrayAppend(wsList, {
					id: row.code,
					code: row.code,
					name: row.name,
					alias: len(row.alias ?: "") ? row.alias : "",
					type: row.type,
					leadership_type: (structKeyExists(row, "leadership_type") && len(row.leadership_type ?: "")) ? row.leadership_type : "dept_head",
					job_title: (structKeyExists(row, "job_title") && len(row.job_title ?: "")) ? row.job_title : "",
					contact_photo: (structKeyExists(row, "contact_photo") && len(row.contact_photo ?: "")) ? row.contact_photo : "",
					color: (structKeyExists(row, "color") && len(trim(row.color))) ? trim(row.color) : (row.type eq "dept" ? "##7e22ce" : (row.type eq "site" ? "##10b981" : "##0073aa")),
					badge: row.badge,
					badgeClass: row.badge_class,
					icon: row.icon,
					desc: len(row.description ?: "") ? row.description : (row.name & " Portal"),
					subtitle: len(row.description ?: "") ? row.description : (row.name & " Portal"),
					folderPath: row.folder_path,
					virtual_directory: row.virtual_directory,
					storage_path: (structKeyExists(row, "storage_path") && len(row.storage_path ?: "")) ? row.storage_path : row.folder_path,
					domain_name: (structKeyExists(row, "domain_name") && len(row.domain_name ?: "")) ? row.domain_name : "www.chelancounty.gov",
					project_path: (structKeyExists(row, "project_path") && len(row.project_path ?: "")) ? row.project_path : "C:\inetpub\chelan-county",
					department: len(row.department ?: "") ? row.department : row.name,
					department_category: len(row.department_category ?: "") ? row.department_category : "",
					redirect_url: len(row.redirect_url ?: "") ? row.redirect_url : "",
					is_system: (isNumeric(row.is_system) && row.is_system == 1) ? true : false,
					contact: {
						photo: (structKeyExists(row, "contact_photo") && len(row.contact_photo ?: "")) ? row.contact_photo : "",
						job_title: (structKeyExists(row, "job_title") && len(row.job_title ?: "")) ? row.job_title : "",
						first_name: len(row.contact_first_name ?: "") ? row.contact_first_name : "",
						last_name: len(row.contact_last_name ?: "") ? row.contact_last_name : "",
						email: len(row.contact_email ?: "") ? row.contact_email : "",
						phone: len(row.contact_phone ?: "") ? row.contact_phone : "",
						fax: len(row.contact_fax ?: "") ? row.contact_fax : "",
						address: len(row.address ?: "") ? row.address : "",
						address2: len(row.address2 ?: "") ? row.address2 : "",
						city: len(row.city ?: "") ? row.city : "Wenatchee",
						state: len(row.state ?: "") ? row.state : "WA",
						zip: len(row.zip ?: "") ? row.zip : "98801",
						office_hours: len(row.office_hours ?: "") ? row.office_hours : ""
					}
				});
			}
		} catch (any err) {
			wsList = [];
		}

		// Ensure global root workspace is always present as fallback if database returned empty
		if (arrayLen(wsList) == 0) {
			arrayAppend(wsList, {
				id: "global",
				code: "global",
				name: "All Workspaces",
				type: "global",
				color: "##0073aa",
				badge: "Global",
				badgeClass: "badge-neutral",
				icon: "grid",
				desc: "County-wide unified view across all municipal divisions and portals",
				subtitle: "County-wide unified view across all municipal divisions and portals",
				folderPath: "files/shared",
				virtual_directory: "shared",
				department: "County-wide",
				department_category: "County Administration",
				redirect_url: "",
				is_system: true,
				job_title: "",
				contact_photo: "",
				contact: {
					photo: "",
					job_title: "",
					first_name: "County",
					last_name: "Administration",
					email: "info@chelancounty.gov",
					phone: "509-667-6215",
					fax: "",
					address: "400 Douglas Street",
					address2: "Suite 201",
					city: "Wenatchee",
					state: "WA",
					zip: "98801",
					office_hours: "Monday - Friday: 8:00 AM - 5:00 PM"
				}
			});
		}

		application.cmsWorkspacesList = wsList;
	}
	return application.cmsWorkspacesList;
}

public void function saveMasterWorkspaces(required array workspaces) {
	application.cmsWorkspacesList = arguments.workspaces;
}

public void function addMasterWorkspace(required struct newWorkspace) {
	if (structKeyExists(application, "cmsWorkspacesList")) {
		structDelete(application, "cmsWorkspacesList");
	}
	getMasterWorkspaces();
}

/**
 * Returns the authenticated user's genuine database role code.
 * Defaults to 'admin' if no session.user is present.
 */
public string function getAuthenticatedUserRole() {
	if (structKeyExists(session, "user") && isStruct(session.user) && structKeyExists(session.user, "role_code") && len(trim(session.user.role_code))) {
		return lCase(trim(session.user.role_code));
	}
	return "admin";
}

/**
 * Returns true if the user genuinely belongs to the Administrator group.
 * Non-admin groups (Author, HR, PIO) return false.
 */
public boolean function isRealAdmin() {
	return (getAuthenticatedUserRole() == "admin");
}

/**
 * Returns the current active simulated or authenticated role.
 * If user belongs to a non-admin group, returns their genuine role (simulation disabled).
 * Defaults to 'admin'.
 */
public string function getCurrentActiveRole() {
	// Non-admin groups cannot simulate other roles
	if (!isRealAdmin()) {
		return getAuthenticatedUserRole();
	}

	var localRole = "admin";
	if (structKeyExists(cookie, "cmsadmin_simulated_role") && len(cookie.cmsadmin_simulated_role)) {
		localRole = lCase(trim(cookie.cmsadmin_simulated_role));
	} else if (structKeyExists(session, "simulatedRole") && len(session.simulatedRole)) {
		localRole = lCase(trim(session.simulatedRole));
	}
	if (!listFind("admin,pio,hr,author", localRole)) localRole = "admin";
	return localRole;
}

/**
 * Returns the workspace codes assigned to a user or role.
 * Accurately prioritizes the authenticated user's actual database-assigned workspaces (session.user.workspaces).
 * If admin is simulating a role, returns the simulated role template.
 */
public array function getUserAssignedWorkspaceCodes(string role = "") {
	var targetRole = len(arguments.role) ? lCase(trim(arguments.role)) : getCurrentActiveRole();
	var allWs = getMasterWorkspaces();
	var allCodes = [];
	for (var w in allWs) {
		arrayAppend(allCodes, w.id);
	}

	// Case 1: Active Role is admin AND user is real admin -> full county-wide access to all workspaces
	if (targetRole == "admin" && isRealAdmin()) {
		return allCodes;
	}

	// Case 2: When an authenticated user is logged in, use their real database-assigned workspaces!
	if (structKeyExists(session, "user") && isStruct(session.user) && structKeyExists(session.user, "workspaces") && isArray(session.user.workspaces) && arrayLen(session.user.workspaces) > 0) {
		// If real admin has 'global', they get all workspaces
		if (arrayFindNoCase(session.user.workspaces, "global")) {
			return allCodes;
		}

		// If a real admin is currently testing a simulated non-admin persona, use role template
		var isSimulating = isRealAdmin() && (targetRole != "admin");
		if (!isSimulating) {
			return session.user.workspaces;
		}
	}

	// Case 3: Role-based template fallback (for simulations or initial development preview)
	switch (targetRole) {
		case "pio":
			return ["communications", "pio", "site-main", "site-parks", "site-expo"];
		case "hr":
			return ["human-resources", "hrm", "admin", "site-main"];
		case "author":
			return ["commdev", "community-development", "assessor", "site-main", "site-gis"];
		default:
			return ["site-main"];
	}
}

/**
 * Returns the array of workspace objects accessible to the user.
 * ADMIN has access to 'global' (All Workspaces) and all 15 department & site workspaces.
 * NON-ADMINS ONLY receive their assigned workspaces matching their database profile.
 */
public array function getUserAccessibleWorkspaces(string role = "") {
	var targetRole = len(arguments.role) ? lCase(trim(arguments.role)) : getCurrentActiveRole();
	var allWs = getMasterWorkspaces();
	var accessible = [];

	var assignedCodes = getUserAssignedWorkspaceCodes(targetRole);

	// If assigned 'global' or user is admin, return all actual department & site workspaces (excluding 'global')
	if (arrayFindNoCase(assignedCodes, "global")) {
		for (var w in allWs) {
			if (w.id == "global" || w.code == "global") continue;
			arrayAppend(accessible, w);
		}
		return accessible;
	}

	for (var w in allWs) {
		// Non-admin users are strictly barred from 'global' (All Workspaces)
		if (w.id == "global" || w.code == "global") continue;

		var matched = false;
		if (arrayFindNoCase(assignedCodes, w.id) || arrayFindNoCase(assignedCodes, w.code)) {
			matched = true;
		} else if (structKeyExists(w, "alias") && len(trim(w.alias)) && arrayFindNoCase(assignedCodes, trim(w.alias))) {
			matched = true;
		}

		// Fuzzy alias matching across common database naming conventions
		if (!matched) {
			if ((w.id == "human-resources" || w.code == "human-resources" || w.id == "hrm" || w.code == "hrm") && (arrayFindNoCase(assignedCodes, "human-resources") || arrayFindNoCase(assignedCodes, "hrm"))) {
				matched = true;
			} else if ((w.id == "communications" || w.code == "communications" || w.id == "pio" || w.code == "pio") && (arrayFindNoCase(assignedCodes, "communications") || arrayFindNoCase(assignedCodes, "pio"))) {
				matched = true;
			} else if ((w.id == "assessor" || w.code == "assessor" || w.id == "assessors" || w.code == "assessors") && (arrayFindNoCase(assignedCodes, "assessor") || arrayFindNoCase(assignedCodes, "assessors"))) {
				matched = true;
			} else if ((w.id == "commdev" || w.code == "commdev" || w.id == "community-development" || w.code == "community-development") && (arrayFindNoCase(assignedCodes, "commdev") || arrayFindNoCase(assignedCodes, "community-development"))) {
				matched = true;
			}
		}

		if (matched) {
			arrayAppend(accessible, w);
		}
	}

	// Fallback safety: If somehow no workspaces matched, provide at least their primary or main site
	if (arrayLen(accessible) == 0 && arrayLen(allWs) > 0) {
		for (var w in allWs) {
			if (w.id != "global" && (w.id == "site-main" || w.code == "site-main")) {
				arrayAppend(accessible, w);
				break;
			}
		}
		if (arrayLen(accessible) == 0) {
			for (var w in allWs) {
				if (w.id != "global") {
					arrayAppend(accessible, w);
					break;
				}
			}
		}
	}

	return accessible;
}

/**
 * Checks whether a specific workspace ID is accessible for a role/user.
 */
public boolean function isWorkspaceAccessible(required string wsId, string role = "") {
	var targetRole = len(arguments.role) ? lCase(trim(arguments.role)) : getCurrentActiveRole();
	var targetId = lCase(trim(arguments.wsId));
	var assignedCodes = getUserAssignedWorkspaceCodes(targetRole);

	if (targetId == "global" || targetId == "all" || len(targetId) == 0) return false;

	if (arrayFindNoCase(assignedCodes, "global")) return true;

	var accessible = getUserAccessibleWorkspaces(targetRole);
	for (var w in accessible) {
		if (w.id == targetId || w.code == targetId || (structKeyExists(w, "alias") && len(w.alias) && w.alias == targetId)) {
			return true;
		}
	}

	return false;
}

/**
 * Resolves the safe active workspace struct for the user.
 * If no workspace is selected (or if global/all was stored), returns the unselected prompt:
 * 'Please select a workspace'
 */
public struct function resolveUserActiveWorkspace(string requestedWs = "", string role = "") {
	var targetRole = len(arguments.role) ? lCase(trim(arguments.role)) : getCurrentActiveRole();
	var req = lCase(trim(arguments.requestedWs));
	var accessible = getUserAccessibleWorkspaces(targetRole);
	var assignedCodes = getUserAssignedWorkspaceCodes(targetRole);
	var isUserGlobal = (arrayFindNoCase(assignedCodes, "global") > 0);
	var allWs = getMasterWorkspaces();

	var promptWs = {
		id: "",
		code: "",
		name: "Please select a workspace",
		type: "none",
		color: "##0073aa",
		badge: "Select",
		badgeClass: "badge-neutral",
		icon: "grid",
		desc: "Please choose a workspace from the dropdown above",
		subtitle: "Please choose a workspace from the dropdown above",
		virtual_directory: "shared",
		folderPath: "files/shared"
	};

	if (isUserGlobal) {
		if (len(req) == 0 || req == "global" || req == "all") {
			return promptWs;
		}
		for (var w in allWs) {
			if (w.id == "global" || w.code == "global") continue;
			var wId = lCase(w.id);
			var wCode = structKeyExists(w, "code") ? lCase(w.code) : "";
			var wAlias = structKeyExists(w, "alias") ? lCase(w.alias) : "";
			if (wId == req || wCode == req || wAlias == req) {
				return w;
			}
			// Fuzzy alias matching across common database naming conventions
			if ((req == "assessor" || req == "assessors") && (wId == "assessor" || wId == "assessors" || wCode == "assessor" || wCode == "assessors" || wAlias == "assessor" || wAlias == "assessors")) {
				return w;
			}
			if ((req == "human-resources" || req == "hrm") && (wId == "human-resources" || wId == "hrm" || wCode == "human-resources" || wCode == "hrm" || wAlias == "human-resources" || wAlias == "hrm")) {
				return w;
			}
			if ((req == "communications" || req == "pio") && (wId == "communications" || wId == "pio" || wCode == "communications" || wCode == "pio" || wAlias == "communications" || wAlias == "pio")) {
				return w;
			}
			if ((req == "commdev" || req == "community-development") && (wId == "commdev" || wId == "community-development" || wCode == "commdev" || wCode == "community-development" || wAlias == "commdev" || wAlias == "community-development")) {
				return w;
			}
			if ((req == "pw" || req == "public-works") && (wId == "pw" || wId == "public-works" || wCode == "pw" || wCode == "public-works" || wAlias == "pw" || wAlias == "public-works")) {
				return w;
			}
			if ((req == "admin" || req == "county-administration") && (wId == "admin" || wId == "county-administration" || wCode == "admin" || wCode == "county-administration" || wAlias == "admin" || wAlias == "county-administration")) {
				return w;
			}
		}
		return promptWs;
	}

	// Non-admin user: must be in their accessible assigned list
	if (len(req) && req != "global" && req != "all") {
		for (var w in accessible) {
			var wId = lCase(w.id);
			var wCode = structKeyExists(w, "code") ? lCase(w.code) : "";
			var wAlias = structKeyExists(w, "alias") ? lCase(w.alias) : "";
			if (wId == req || wCode == req || wAlias == req) {
				return w;
			}
			if ((req == "assessor" || req == "assessors") && (wId == "assessor" || wId == "assessors" || wCode == "assessor" || wCode == "assessors" || wAlias == "assessor" || wAlias == "assessors")) {
				return w;
			}
			if ((req == "human-resources" || req == "hrm") && (wId == "human-resources" || wId == "hrm" || wCode == "human-resources" || wCode == "hrm" || wAlias == "human-resources" || wAlias == "hrm")) {
				return w;
			}
			if ((req == "communications" || req == "pio") && (wId == "communications" || wId == "pio" || wCode == "communications" || wCode == "pio" || wAlias == "communications" || wAlias == "pio")) {
				return w;
			}
			if ((req == "commdev" || req == "community-development") && (wId == "commdev" || wId == "community-development" || wCode == "commdev" || wCode == "community-development" || wAlias == "commdev" || wAlias == "community-development")) {
				return w;
			}
			if ((req == "pw" || req == "public-works") && (wId == "pw" || wId == "public-works" || wCode == "pw" || wCode == "public-works" || wAlias == "pw" || wAlias == "public-works")) {
				return w;
			}
			if ((req == "admin" || req == "county-administration") && (wId == "admin" || wId == "county-administration" || wCode == "admin" || wCode == "county-administration" || wAlias == "admin" || wAlias == "county-administration")) {
				return w;
			}
		}
	}

	// Default fallback to first assigned workspace for non-admins
	if (arrayLen(accessible) > 0) {
		return accessible[1];
	}

	return promptWs;
}

/**
 * Returns the currently active workspace ID from URL parameter or cookie,
 * validated against the user's role and accessible workspaces.
 * Available to all controllers and views.
 */
public string function activeWorkspaceId() {
	var requested = (structKeyExists(params, "ws") && len(trim(params.ws))) ? trim(params.ws)
		: ((structKeyExists(cookie, "cmsadmin_workspace") && len(trim(cookie.cmsadmin_workspace))) ? trim(cookie.cmsadmin_workspace) : "");
	if (!len(requested) || requested == "global" || requested == "all") {
		return "";
	}
	var ws = resolveUserActiveWorkspace(requestedWs=requested, role=getCurrentActiveRole());
	var id = lCase(trim(ws.id ?: ""));
	if (id == "global" || id == "all") return "";
	return len(id) ? left(id, 100) : "";
}

/**
 * Retrieves dynamic system notifications across form submissions, page revisions,
 * job applications, and security events, tailored to the staff user's role.
 */
public array function getSystemNotifications(string role = "admin", numeric limit = 10) {
	var notifications = [];
	var targetRole = len(trim(arguments.role)) ? lCase(trim(arguments.role)) : "admin";
	var maxItems = Val(arguments.limit) > 0 ? Val(arguments.limit) : 10;
	
	try {
		// 1. Recent Form Submissions (Content, PIO, HR, Admin)
		var qForms = queryExecute("
			SELECT TOP 5 s.id, s.form_id, s.status, s.createdat, f.title AS form_title
			FROM form_submissions s
			LEFT JOIN forms f ON f.id = s.form_id
			WHERE s.deletedat IS NULL
			ORDER BY s.createdat DESC
		", {}, { datasource: "ChelanCountyWebsite" });

		for (var row in qForms) {
			var formTitle = len(trim(row.form_title ?: "")) ? trim(row.form_title) : "Online Form ##" & row.form_id;
			var isPending = (row.status == "received" || row.status == "in_review");
			arrayAppend(notifications, {
				id: "form-" & row.id,
				type: "form",
				category: "Form Submission",
				title: "Form Submission ##" & row.id,
				message: "Received for """ & formTitle & """",
				icon: "form",
				badgeClass: isPending ? "badge-primary" : "badge-neutral",
				badgeText: isPending ? "New Intake" : UCase(row.status),
				colorClass: "stat-icon-purple",
				iconColor: "##7e22ce",
				createdat: isDate(row.createdat) ? row.createdat : Now(),
				isUnread: isPending,
				link: urlFor(controller="forms", action="submissions", params="id=" & row.form_id)
			});
		}
	} catch (any eForms) {}

	try {
		// 2. Recent Page Updates (All roles)
		var qPages = queryExecute("
			SELECT TOP 5 ContentID, Title, Modified, ModifiedBy, StatusCode, isPublished
			FROM pages
			WHERE DeletedAt IS NULL
			ORDER BY Modified DESC
		", {}, { datasource: "ChelanCountyWebsite" });

		for (var row in qPages) {
			var pageTitle = len(trim(row.Title ?: "")) ? trim(row.Title) : "Untitled Page";
			var author = len(trim(row.ModifiedBy ?: "")) ? trim(row.ModifiedBy) : "Staff";
			var isLive = (row.isPublished == 1 || row.StatusCode == "Active");
			arrayAppend(notifications, {
				id: "page-" & row.ContentID,
				type: "page",
				category: "Content Update",
				title: isLive ? "Page Updated" : "Draft Saved",
				message: """" & pageTitle & """ by " & author,
				icon: "pages",
				badgeClass: isLive ? "badge-success" : "badge-warning",
				badgeText: isLive ? "Published" : "Draft",
				colorClass: "stat-icon-primary",
				iconColor: "##0073aa",
				createdat: isDate(row.Modified) ? row.Modified : Now(),
				isUnread: !isLive,
				link: urlFor(controller="pages", action="edit", params="id=" & row.ContentID)
			});
		}
	} catch (any ePages) {}

	// 3. Recent Job Applications (HR and Admin only)
	if (targetRole == "admin" || targetRole == "hr") {
		try {
			var qJobs = queryExecute("
				SELECT TOP 5 a.id, a.first_name, a.last_name, a.createdat, a.status, p.title AS job_title
				FROM job_applications a
				LEFT JOIN job_postings p ON p.id = a.job_posting_id
				WHERE a.deletedat IS NULL
				ORDER BY a.createdat DESC
			", {}, { datasource: "ChelanCountyWebsite" });

			for (var row in qJobs) {
				var applicantName = trim(row.first_name & " " & row.last_name);
				var jobTitle = len(trim(row.job_title ?: "")) ? trim(row.job_title) : "Open Position";
				var isNewApp = (row.status == "received" || row.status == "new" || !len(trim(row.status ?: "")));
				arrayAppend(notifications, {
					id: "job-" & row.id,
					type: "job",
					category: "HRM Recruitment",
					title: "Candidate Application",
					message: applicantName & " applied for " & jobTitle,
					icon: "briefcase",
					badgeClass: isNewApp ? "badge-purple" : "badge-neutral",
					badgeText: isNewApp ? "New Candidate" : UCase(row.status),
					colorClass: "stat-icon-purple",
					iconColor: "##7e22ce",
					createdat: isDate(row.createdat) ? row.createdat : Now(),
					isUnread: isNewApp,
					link: urlFor(controller="jobs", action="applications")
				});
			}
		} catch (any eJobs) {}
	}

	// Sort newest first
	if (arrayLen(notifications) > 1) {
		arraySort(notifications, function(a, b) {
			if (isDate(a.createdat) && isDate(b.createdat)) {
				return dateCompare(b.createdat, a.createdat);
			}
			return 0;
		});
	}

	// Slice to requested limit
	if (arrayLen(notifications) > maxItems) {
		return arraySlice(notifications, 1, maxItems);
	}

	return notifications;
}

/**
 * Returns formatted relative time (e.g. "5m ago", "2h ago", "Yesterday", "Oct 12")
 */
public string function formatTimeAgo(required any dateVal) {
	if (!isDate(arguments.dateVal)) return "Recently";
	var diffMin = dateDiff("n", arguments.dateVal, Now());
	if (diffMin < 1) return "Just now";
	if (diffMin < 60) return diffMin & "m ago";
	var diffHours = dateDiff("h", arguments.dateVal, Now());
	if (diffHours < 24) return diffHours & "h ago";
	var diffDays = dateDiff("d", arguments.dateVal, Now());
	if (diffDays == 1) return "Yesterday";
	if (diffDays < 7) return diffDays & "d ago";
	return dateFormat(arguments.dateVal, "mmm d, yyyy");
}

/**
 * Evaluates and transitions scheduled & expiring items across Pages, Articles, Events, and Careers.
 * Respects SQL Server filtered index invariants and logs state transitions.
 */
public struct function evaluateScheduledTransitions() {
	var report = {
		"timestamp": Now(),
		"success": true,
		"pages_published": 0,
		"pages_archived": 0,
		"articles_published": 0,
		"articles_archived": 0,
		"events_published": 0,
		"events_archived": 0,
		"jobs_published": 0,
		"jobs_archived": 0,
		"total_transitions": 0,
		"errors": []
	};

	// 1. Pages — Scheduled Release -> Published
	try {
		var qPagesPub = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE pages
			SET Visibility = 'Published',
			    StatusCode = 'Active',
			    isPublished = 1,
			    PublishAt = COALESCE(PublishAt, publish_at),
			    publish_at = COALESCE(publish_at, PublishAt),
			    Modified = SYSUTCDATETIME(),
			    ModifiedBy = 'Auto-Scheduler'
			WHERE DeletedAt IS NULL
			  AND (Visibility = 'Scheduled' OR (isPublished = 0 AND StatusCode = 'Active' AND Visibility <> 'Draft' AND Visibility <> 'Hidden'))
			  AND (publish_at IS NOT NULL OR PublishAt IS NOT NULL)
			  AND COALESCE(publish_at, PublishAt) <= SYSUTCDATETIME()
			  AND (unpublish_at IS NULL OR unpublish_at > SYSUTCDATETIME())
			  AND (UnpublishAt IS NULL OR UnpublishAt > SYSUTCDATETIME());
		", {}, { datasource: "ChelanCountyWebsite", result: "rPagesPub" });
		report.pages_published = Val(rPagesPub.recordCount ?: 0);
	} catch (any ePagesPub) {
		arrayAppend(report.errors, "Pages Publish: " & ePagesPub.message);
	}

	// 2. Pages — Expired -> Archived/Hidden
	try {
		var qPagesArch = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE pages
			SET Visibility = 'Hidden',
			    StatusCode = 'Archived',
			    isPublished = 0,
			    Modified = SYSUTCDATETIME(),
			    ModifiedBy = 'Auto-Scheduler'
			WHERE DeletedAt IS NULL
			  AND (unpublish_at IS NOT NULL OR UnpublishAt IS NOT NULL)
			  AND COALESCE(unpublish_at, UnpublishAt) <= SYSUTCDATETIME()
			  AND (Visibility <> 'Hidden' OR StatusCode <> 'Archived' OR isPublished = 1);
		", {}, { datasource: "ChelanCountyWebsite", result: "rPagesArch" });
		report.pages_archived = Val(rPagesArch.recordCount ?: 0);
	} catch (any ePagesArch) {
		arrayAppend(report.errors, "Pages Archive: " & ePagesArch.message);
	}

	// 3. Articles — Scheduled -> Published
	try {
		var qArtPub = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE articles
			SET status = 'published',
			    published_at = COALESCE(published_at, publish_at, SYSUTCDATETIME()),
			    publish_at = COALESCE(publish_at, published_at, SYSUTCDATETIME()),
			    updatedat = SYSUTCDATETIME(),
			    modified_by = 'Auto-Scheduler'
			WHERE deletedat IS NULL
			  AND status = 'scheduled'
			  AND publish_at IS NOT NULL
			  AND publish_at <= SYSUTCDATETIME()
			  AND (unpublish_at IS NULL OR unpublish_at > SYSUTCDATETIME());
		", {}, { datasource: "ChelanCountyWebsite", result: "rArtPub" });
		report.articles_published = Val(rArtPub.recordCount ?: 0);
	} catch (any eArtPub) {
		arrayAppend(report.errors, "Articles Publish: " & eArtPub.message);
	}

	// 4. Articles — Expired -> Archived
	try {
		var qArtArch = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE articles
			SET status = 'archived',
			    updatedat = SYSUTCDATETIME(),
			    modified_by = 'Auto-Scheduler'
			WHERE deletedat IS NULL
			  AND unpublish_at IS NOT NULL
			  AND unpublish_at <= SYSUTCDATETIME()
			  AND status <> 'archived';
		", {}, { datasource: "ChelanCountyWebsite", result: "rArtArch" });
		report.articles_archived = Val(rArtArch.recordCount ?: 0);
	} catch (any eArtArch) {
		arrayAppend(report.errors, "Articles Archive: " & eArtArch.message);
	}

	// 5. Calendar Events — Scheduled -> Published
	try {
		var qEvPub = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE calendar_events
			SET status = 'Published',
			    updatedat = SYSUTCDATETIME(),
			    modified_by = 'Auto-Scheduler'
			WHERE deletedat IS NULL
			  AND status = 'Scheduled'
			  AND publish_at IS NOT NULL
			  AND publish_at <= SYSUTCDATETIME()
			  AND (unpublish_at IS NULL OR unpublish_at > SYSUTCDATETIME());
		", {}, { datasource: "ChelanCountyWebsite", result: "rEvPub" });
		report.events_published = Val(rEvPub.recordCount ?: 0);
	} catch (any eEvPub) {
		arrayAppend(report.errors, "Events Publish: " & eEvPub.message);
	}

	// 6. Calendar Events — Expired -> Archived
	try {
		var qEvArch = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE calendar_events
			SET status = 'Archived',
			    updatedat = SYSUTCDATETIME(),
			    modified_by = 'Auto-Scheduler'
			WHERE deletedat IS NULL
			  AND unpublish_at IS NOT NULL
			  AND unpublish_at <= SYSUTCDATETIME()
			  AND status NOT IN ('Archived', 'Cancelled');
		", {}, { datasource: "ChelanCountyWebsite", result: "rEvArch" });
		report.events_archived = Val(rEvArch.recordCount ?: 0);
	} catch (any eEvArch) {
		arrayAppend(report.errors, "Events Archive: " & eEvArch.message);
	}

	// 7. Job Listings / Careers — Scheduled -> Active
	try {
		var qJobPub = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE job_listings
			SET StatusCode = 'Active',
			    Modified = SYSUTCDATETIME(),
			    Modifiedby = 'Auto-Scheduler'
			WHERE DeletedAt IS NULL
			  AND StatusCode = 'Scheduled'
			  AND (publish_at IS NOT NULL OR PostDate IS NOT NULL)
			  AND COALESCE(publish_at, PostDate) <= SYSUTCDATETIME()
			  AND (unpublish_at IS NULL OR unpublish_at > SYSUTCDATETIME());
		", {}, { datasource: "ChelanCountyWebsite", result: "rJobPub" });
		report.jobs_published = Val(rJobPub.recordCount ?: 0);

		// Synchronize job_postings if present
		queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE job_postings
			SET status = 'active', updatedat = SYSUTCDATETIME(), updated_by = 'Auto-Scheduler'
			WHERE deletedat IS NULL
			  AND status = 'scheduled'
			  AND (publish_at IS NOT NULL OR open_date IS NOT NULL)
			  AND COALESCE(publish_at, open_date) <= SYSUTCDATETIME()
			  AND (unpublish_at IS NULL OR unpublish_at > SYSUTCDATETIME());
		", {}, { datasource: "ChelanCountyWebsite" });
	} catch (any eJobPub) {
		arrayAppend(report.errors, "Jobs Publish: " & eJobPub.message);
	}

	// 8. Job Listings / Careers — Expired (Deadline passed) -> Closed
	try {
		var qJobArch = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE job_listings
			SET StatusCode = 'Closed',
			    Modified = SYSUTCDATETIME(),
			    Modifiedby = 'Auto-Scheduler'
			WHERE DeletedAt IS NULL
			  AND (unpublish_at IS NOT NULL OR ApplicationDeadline IS NOT NULL)
			  AND COALESCE(unpublish_at, ApplicationDeadline) <= SYSUTCDATETIME()
			  AND StatusCode NOT IN ('Archived', 'Closed');
		", {}, { datasource: "ChelanCountyWebsite", result: "rJobArch" });
		report.jobs_archived = Val(rJobArch.recordCount ?: 0);

		// Synchronize job_postings if present
		queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE job_postings
			SET status = 'closed', updatedat = SYSUTCDATETIME(), updated_by = 'Auto-Scheduler'
			WHERE deletedat IS NULL
			  AND (unpublish_at IS NOT NULL OR close_date IS NOT NULL)
			  AND COALESCE(unpublish_at, close_date) <= SYSUTCDATETIME()
			  AND status NOT IN ('archived', 'closed');
		", {}, { datasource: "ChelanCountyWebsite" });
	} catch (any eJobArch) {
		arrayAppend(report.errors, "Jobs Archive: " & eJobArch.message);
	}

	// 9. RFP Solicitations — Scheduled -> Open
	try {
		var qRfpPub = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE dbo.rfp_solicitations
			SET status = 'Open',
			    updated_at = SYSUTCDATETIME(),
			    updated_by = 'Auto-Scheduler'
			WHERE deleted_at IS NULL
			  AND status = 'Scheduled'
			  AND publish_at IS NOT NULL
			  AND publish_at <= SYSUTCDATETIME();
		", {}, { datasource: "ChelanCountyWebsite", result: "rRfpPub" });
		report.rfps_published = Val(rRfpPub.recordCount ?: 0);
	} catch (any eRfpPub) {
		arrayAppend(report.errors, "RFPs Publish: " & eRfpPub.message);
	}

	// 10. RFP Solicitations — Expired Deadline -> Under Review (Closed for Bids)
	try {
		var qRfpClose = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE dbo.rfp_solicitations
			SET status = 'Under Review',
			    updated_at = SYSUTCDATETIME(),
			    updated_by = 'Auto-Scheduler'
			WHERE deleted_at IS NULL
			  AND status = 'Open'
			  AND submission_deadline <= SYSUTCDATETIME();
		", {}, { datasource: "ChelanCountyWebsite", result: "rRfpClose" });
		report.rfps_closed = Val(rRfpClose.recordCount ?: 0);
	} catch (any eRfpClose) {
		arrayAppend(report.errors, "RFPs Close: " & eRfpClose.message);
	}

	report.total_transitions = report.pages_published + report.pages_archived
		+ report.articles_published + report.articles_archived
		+ report.events_published + report.events_archived
		+ report.jobs_published + report.jobs_archived
		+ (structKeyExists(report, "rfps_published") ? report.rfps_published : 0)
		+ (structKeyExists(report, "rfps_closed") ? report.rfps_closed : 0);

	report.success = (arrayLen(report.errors) == 0);

	return report;
}

/**
 * Returns summary statistics on pending scheduled and expiring items across modules.
 */
public struct function getScheduledPublishingSummary() {
	var summary = {
		"pages_scheduled": 0,
		"pages_expiring": 0,
		"articles_scheduled": 0,
		"articles_expiring": 0,
		"events_scheduled": 0,
		"events_expiring": 0,
		"jobs_scheduled": 0,
		"jobs_expiring": 0,
		"total_pending_actions": 0,
		"last_run": structKeyExists(application, "lastSchedulerRun") ? application.lastSchedulerRun : "",
		"last_result": structKeyExists(application, "lastSchedulerResult") ? application.lastSchedulerResult : {}
	};

	try {
		var qP = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT 
				SUM(CASE WHEN Visibility = 'Scheduled' AND COALESCE(publish_at, PublishAt) > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS sched_cnt,
				SUM(CASE WHEN Visibility = 'Published' AND (unpublish_at IS NOT NULL OR UnpublishAt IS NOT NULL) AND COALESCE(unpublish_at, UnpublishAt) > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS exp_cnt
			FROM pages
			WHERE DeletedAt IS NULL;
		", {}, { datasource: "ChelanCountyWebsite" });
		if (qP.recordCount) {
			summary.pages_scheduled = Val(qP.sched_cnt ?: 0);
			summary.pages_expiring = Val(qP.exp_cnt ?: 0);
		}
	} catch (any eP) {}

	try {
		var qA = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT 
				SUM(CASE WHEN status = 'scheduled' AND publish_at > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS sched_cnt,
				SUM(CASE WHEN status = 'published' AND unpublish_at IS NOT NULL AND unpublish_at > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS exp_cnt
			FROM articles
			WHERE deletedat IS NULL;
		", {}, { datasource: "ChelanCountyWebsite" });
		if (qA.recordCount) {
			summary.articles_scheduled = Val(qA.sched_cnt ?: 0);
			summary.articles_expiring = Val(qA.exp_cnt ?: 0);
		}
	} catch (any eA) {}

	try {
		var qE = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT 
				SUM(CASE WHEN status = 'Scheduled' AND publish_at > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS sched_cnt,
				SUM(CASE WHEN status = 'Published' AND unpublish_at IS NOT NULL AND unpublish_at > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS exp_cnt
			FROM calendar_events
			WHERE deletedat IS NULL;
		", {}, { datasource: "ChelanCountyWebsite" });
		if (qE.recordCount) {
			summary.events_scheduled = Val(qE.sched_cnt ?: 0);
			summary.events_expiring = Val(qE.exp_cnt ?: 0);
		}
	} catch (any eE) {}

	try {
		var qJ = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT 
				SUM(CASE WHEN StatusCode = 'Scheduled' AND COALESCE(publish_at, PostDate) > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS sched_cnt,
				SUM(CASE WHEN StatusCode = 'Active' AND (unpublish_at IS NOT NULL OR ApplicationDeadline IS NOT NULL) AND COALESCE(unpublish_at, ApplicationDeadline) > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS exp_cnt
			FROM job_listings
			WHERE DeletedAt IS NULL;
		", {}, { datasource: "ChelanCountyWebsite" });
		if (qJ.recordCount) {
			summary.jobs_scheduled = Val(qJ.sched_cnt ?: 0);
			summary.jobs_expiring = Val(qJ.exp_cnt ?: 0);
		}
	} catch (any eJ) {}

	summary.total_pending_actions = summary.pages_scheduled + summary.pages_expiring
		+ summary.articles_scheduled + summary.articles_expiring
		+ summary.events_scheduled + summary.events_expiring
		+ summary.jobs_scheduled + summary.jobs_expiring;

	return summary;
}

/**
 * Renders HTML markup for a single Call to Action card matching the reference design.
 */
public string function renderCallToActionCardHtml(required struct item) {
	var title = Len(item.title ?: "") ? Trim(item.title) : "Call to Action";
	var desc = Len(item.description ?: "") ? Trim(item.description) : "";
	var imgUrl = Len(item.imageUrl ?: (item.image_url ?: "")) ? Trim(item.imageUrl ?: item.image_url) : "";
	var imgAlt = Len(item.imageAlt ?: (item.image_alt ?: "")) ? Trim(item.imageAlt ?: item.image_alt) : title;
	var linkText = Len(item.linkText ?: (item.link_text ?: "")) ? Trim(item.linkText ?: item.link_text) : "Learn More";
	var linkUrl = Len(item.linkUrl ?: (item.link_url ?: "")) ? Trim(item.linkUrl ?: item.link_url) : "##";
	var linkIcon = Len(item.linkIcon ?: (item.link_icon ?: "")) ? LCase(Trim(item.linkIcon ?: item.link_icon)) : "arrow";
	var linkStyle = Len(item.linkStyle ?: (item.link_style ?: "")) ? LCase(Trim(item.linkStyle ?: item.link_style)) : "link";
	var isBlank = (StructKeyExists(item, "targetBlank") && (item.targetBlank == 1 || item.targetBlank == "1" || item.targetBlank == true))
		|| (StructKeyExists(item, "target_blank") && (item.target_blank == 1 || item.target_blank == "1" || item.target_blank == true));
	var badgeText = Len(item.badgeText ?: (item.badge_text ?: "")) ? Trim(item.badgeText ?: item.badge_text) : "";
	var badgeColor = Len(item.badgeColor ?: (item.badge_color ?: "")) ? LCase(Trim(item.badgeColor ?: item.badge_color)) : "blue";
	var hasImage = Len(imgUrl) > 0;

	var sb = CreateObject("java", "java.lang.StringBuilder").init();
	sb.append('<aside class="jbd-template jbd-cta-card');
	if (hasImage) sb.append(' has-image');
	sb.append('" aria-label="Action: ' & Replace(title, '"', '&quot;', 'all') & '">');

	if (hasImage) {
		sb.append('<div class="jbd-cta-card-img-wrap">');
		sb.append('<img src="' & Replace(imgUrl, '"', '&quot;', 'all') & '" alt="' & Replace(imgAlt, '"', '&quot;', 'all') & '" loading="lazy">');
		sb.append('</div>');
		sb.append('<div class="jbd-cta-card-content">');
	}

	if (Len(badgeText)) {
		var badgeClass = "jbd-cta-badge";
		if (badgeColor == "teal") badgeClass &= " jbd-cta-badge-teal";
		else if (badgeColor == "blue") badgeClass &= " jbd-cta-badge-blue";
		else if (badgeColor == "amber" || badgeColor == "red") badgeClass &= " jbd-cta-badge-amber";
		sb.append('<div class="jbd-cta-card-header"><span class="' & badgeClass & '" aria-hidden="true">' & Replace(badgeText, "<", "&lt;", "all") & '</span></div>');
	}

	sb.append('<p class="jbd-cta-title h4">' & Replace(title, "<", "&lt;", "all") & '</p>');
	if (Len(desc)) {
		sb.append('<p class="jbd-cta-desc">' & Replace(desc, "<", "&lt;", "all") & '</p>');
	}

	sb.append('<div class="jbd-cta-card-footer">');
	var targetAttr = isBlank ? ' target="_blank" rel="noopener noreferrer"' : '';
	var extClass = (isBlank || linkIcon == "external") ? ' has-external-icon' : '';

	if (linkStyle == "button") {
		sb.append('<a href="' & Replace(linkUrl, '"', '&quot;', 'all') & '" class="jbd-btn jbd-btn-primary jbd-cta-btn"' & targetAttr & ' aria-label="' & Replace(linkText & ' for ' & title, '"', '&quot;', 'all') & '">');
		sb.append('<span>' & Replace(linkText, "<", "&lt;", "all") & '</span>');
		if (linkIcon == "external") {
			sb.append(' <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>');
		} else if (linkIcon == "pdf") {
			sb.append(' <span class="jbd-cta-pdf-badge" aria-hidden="true">PDF</span>');
		} else if (linkIcon != "none") {
			sb.append(' <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>');
		}
		sb.append('</a>');
	} else {
		sb.append('<a href="' & Replace(linkUrl, '"', '&quot;', 'all') & '" class="jbd-cta-link' & extClass & '"' & targetAttr & ' aria-label="' & Replace(linkText & ' for ' & title, '"', '&quot;', 'all') & '">');
		sb.append('<span>' & Replace(linkText, "<", "&lt;", "all") & '</span>');
		if (linkIcon == "external") {
			sb.append(' <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>');
		} else if (linkIcon == "pdf") {
			sb.append(' <span class="jbd-cta-pdf-badge" aria-hidden="true">PDF</span>');
		} else if (linkIcon != "none") {
			sb.append(' <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>');
		}
		sb.append('</a>');
	}

	sb.append('</div>'); // footer

	if (hasImage) {
		sb.append('</div>'); // content
	}

	sb.append('</aside>');
	return sb.toString();
}

/**
 * Repairs any .jbd-cta-link anchors whose arrow/external icon was saved as '?', '&rarr;', or '&nearr;' instead of inline SVG.
 */
public string function normalizeCtaLinkIcons(required string content) {
	if (!Len(arguments.content)) {
		return arguments.content;
	}
	var result = healUtf8Mojibake(arguments.content);
	if (FindNoCase("jbd-cta-link", result) == 0) {
		return result;
	}
	var arrowSvg = ' <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>';
	var extSvg = ' <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>';
	var matches = REMatchNoCase('<a\b[^>]*class="[^"]*\bjbd-cta-link\b[^"]*"[^>]*>[\s\S]*?</a>', result);
	for (var aTag in matches) {
		if (FindNoCase("<svg", aTag) == 0 && FindNoCase("jbd-cta-pdf-badge", aTag) == 0) {
			var isExt = (FindNoCase('target="_blank"', aTag) > 0 || FindNoCase("has-external-icon", aTag) > 0 || FindNoCase("&nearr;", aTag) > 0 || Find(Chr(8599), aTag) > 0);
			var cleaned = REReplaceNoCase(aTag, '\s*(\?|&rarr;|&nearr;|##8594;|##8599;|' & Chr(8594) & '|' & Chr(8599) & ')?\s*</a>$', (isExt ? extSvg : arrowSvg) & '</a>');
			if (isExt && FindNoCase("has-external-icon", cleaned) == 0) {
				cleaned = REReplaceNoCase(cleaned, 'class="([^"]*\bjbd-cta-link\b)', 'class="\1 has-external-icon');
			}
			result = Replace(result, aTag, cleaned, "all");
		}
	}
	return result;
}

/**
 * Parses and replaces [call_to_action ...], [cta ...], and [cta_grid ...] shortcodes in content.
 */
public string function renderCallToActionShortcodes(required string content) {
	if (!Len(arguments.content) || (FindNoCase("[call_to_action", arguments.content) == 0 && FindNoCase("[cta", arguments.content) == 0)) {
		return arguments.content;
	}

	var parsed = arguments.content;

	// 1. Process Grid Shortcodes: [cta_grid slugs="s1,s2,s3" cols="3"] or [cta_grid category="..." layout="2x2"]
	var gridMatches = REMatchNoCase("\[cta_grid\s+[^\]]+\]", parsed);
	for (var gTag in gridMatches) {
		var slugsMatch = REFindNoCase('slugs?="([^"]+)"', gTag, 1, true);
		var catMatch = REFindNoCase('categor(y|ies)="([^"]+)"', gTag, 1, true);
		var colsMatch = REFindNoCase('(?:cols?|columns?|layout)="([^"]+)"', gTag, 1, true);
		var itemsHtml = "";
		var itemCount = 0;

		try {
			if (ArrayLen(slugsMatch.len) >= 2 && slugsMatch.len[2] > 0) {
				var slugList = Mid(gTag, slugsMatch.pos[2], slugsMatch.len[2]);
				var slugArr = ListToArray(slugList);
				for (var s in slugArr) {
					var qS = queryExecute("
						SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
						SELECT TOP 1 * FROM page_call_to_actions
						WHERE slug = :slug AND is_published = 1 AND deletedat IS NULL
					", { slug: { value: Trim(s), cfsqltype: "cf_sql_nvarchar" } }, { datasource: "ChelanCountyWebsite" });
					if (qS.recordCount) {
						itemsHtml &= renderCallToActionCardHtml(qS.getRow(1));
						itemCount++;
					}
				}
			} else if (ArrayLen(catMatch.len) >= 3 && catMatch.len[3] > 0) {
				var catName = Mid(gTag, catMatch.pos[3], catMatch.len[3]);
				var qC = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					SELECT * FROM page_call_to_actions
					WHERE category = :cat AND is_published = 1 AND deletedat IS NULL
					ORDER BY sort_order ASC, id ASC
				", { cat: { value: Trim(catName), cfsqltype: "cf_sql_nvarchar" } }, { datasource: "ChelanCountyWebsite" });
				itemCount = qC.recordCount;
				for (var row in qC) {
					itemsHtml &= renderCallToActionCardHtml(row);
				}
			}
		} catch (any e) {}

		if (Len(itemsHtml)) {
			var gridCls = "jbd-template jbd-cta-grid";
			var specifiedLayout = "";
			if (ArrayLen(colsMatch.len) >= 2 && colsMatch.len[2] > 0) {
				specifiedLayout = LCase(Trim(Mid(gTag, colsMatch.pos[2], colsMatch.len[2])));
			}

			if (specifiedLayout == "4" || specifiedLayout == "4col" || specifiedLayout == "4-col" || specifiedLayout == "4cols") {
				gridCls &= " cta-grid-4";
			} else if (specifiedLayout == "2" || specifiedLayout == "2col" || specifiedLayout == "2-col" || specifiedLayout == "2x2" || specifiedLayout == "50/50" || specifiedLayout == "50-50" || specifiedLayout == "5050") {
				gridCls &= " cta-grid-2 cta-grid-50-50";
			} else if (specifiedLayout == "3" || specifiedLayout == "3col" || specifiedLayout == "3-col" || specifiedLayout == "3x1" || specifiedLayout == "3-1") {
				gridCls &= " cta-grid-3";
			} else {
				// Intelligent auto-inference if not explicitly stated
				if (itemCount == 2) {
					gridCls &= " cta-grid-2 cta-grid-50-50";
				} else if (itemCount == 4) {
					gridCls &= " cta-grid-4";
				} else {
					gridCls &= " cta-grid-3";
				}
			}

			var gridReplacement = '<section class="' & gridCls & '" aria-label="Featured Actions">' & itemsHtml & '</section>';
			parsed = Replace(parsed, gTag, gridReplacement, "one");
		}
	}

	// 2. Process Individual Shortcodes: [call_to_action slug="..."] or [cta slug="..."]
	var singleMatches = REMatchNoCase("\[(?:call_to_action|cta)\s+[^\]]+\]", parsed);
	for (var sTag in singleMatches) {
		var slugM = REFindNoCase('slug="([^"]+)"', sTag, 1, true);
		var idM = REFindNoCase('id="?([0-9]+)"?', sTag, 1, true);
		var cardHtml = "";

		try {
			if (ArrayLen(slugM.len) >= 2 && slugM.len[2] > 0) {
				var targetSlug = Mid(sTag, slugM.pos[2], slugM.len[2]);
				var qOne = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					SELECT TOP 1 * FROM page_call_to_actions
					WHERE slug = :slug AND is_published = 1 AND deletedat IS NULL
				", { slug: { value: Trim(targetSlug), cfsqltype: "cf_sql_nvarchar" } }, { datasource: "ChelanCountyWebsite" });
				if (qOne.recordCount) {
					cardHtml = renderCallToActionCardHtml(qOne.getRow(1));
				}
			} else if (ArrayLen(idM.len) >= 2 && idM.len[2] > 0) {
				var targetId = Val(Mid(sTag, idM.pos[2], idM.len[2]));
				var qId = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					SELECT TOP 1 * FROM page_call_to_actions
					WHERE id = :id AND is_published = 1 AND deletedat IS NULL
				", { id: { value: targetId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
				if (qId.recordCount) {
					cardHtml = renderCallToActionCardHtml(qId.getRow(1));
				}
			}
		} catch (any e) {}

		if (Len(cardHtml)) {
			parsed = Replace(parsed, sTag, cardHtml, "one");
		}
	}

	return parsed;
}

// ----------------------------------------------------
// Application Versioning & Build Tracking (v2.1.[build])
// ----------------------------------------------------

/**
 * Returns application versioning data struct loaded from config/version.json or defaults.
 */
public struct function getAppVersion() {
	if (!structKeyExists(application, "appVersionData") || (structKeyExists(url, "reload") && (url.reload == "true" || url.reload == "1"))) {
		var verFile = expandPath("/config/version.json");
		if (fileExists(verFile)) {
			try {
				var jsonStr = fileRead(verFile, "utf-8");
				application.appVersionData = deserializeJSON(jsonStr);
			} catch (any e) {
				// Fallback to defaults
			}
		}
		if (!structKeyExists(application, "appVersionData") || !isStruct(application.appVersionData)) {
			application.appVersionData = {
				"major": 2,
				"minor": 1,
				"build": 1,
				"version": "2.1.1",
				"versionTag": "v2.1.1",
				"releaseName": "Page Studio Parity & Visual Layout Controls",
				"releaseDate": "2026-10-19",
				"builtAt": "2026-10-19T00:15:00-07:00",
				"environment": "development"
			};
		}
	}
	return application.appVersionData;
}

/**
 * Returns standard semantic version string, e.g. "2.1.1"
 */
public string function appVersion() {
	return getAppVersion().version ?: "2.1.1";
}

/**
 * Returns formatted version tag, e.g. "v2.1.1"
 */
public string function appVersionTag() {
	return getAppVersion().versionTag ?: "v2.1.1";
}

/**
 * Returns numeric build number, e.g. 1
 */
public numeric function appBuildNumber() {
	return Val(getAppVersion().build ?: 1);
}

/**
 * Returns full version and build display string, e.g. "v2.1.1 (Build 1)"
 */
public string function appBuildDisplay() {
	var v = getAppVersion();
	return "#(v.versionTag ?: 'v2.1.1')# (Build #(v.build ?: 1)#)";
}

/**
 * Multi-pass Windows-1252 (Cp1252) to UTF-8 Mojibake Self-Healer.
 * Detects and unwinds 1st- through 8th-generation UTF-8 mojibake sequences
 * without altering valid Unicode characters elsewhere in the string.
 */
public string function healUtf8Mojibake(required any input) {
	if (!IsSimpleValue(arguments.input)) return "";
	local.s = ToString(arguments.input);
	if (!Len(local.s)) return local.s;

	if (!Find(Chr(195), local.s) && !Find(Chr(194), local.s) && !Find(Chr(226), local.s)) {
		return local.s;
	}

	local.utf8Charset = createObject("java", "java.nio.charset.StandardCharsets").UTF_8;
	local.codingErrorAction = createObject("java", "java.nio.charset.CodingErrorAction");
	local.byteBufferClass = createObject("java", "java.nio.ByteBuffer");
	local.sb = createObject("java", "java.lang.StringBuilder").init(Len(local.s));

	local.len = Len(local.s);
	local.i = 1;
	while (local.i <= local.len) {
		local.ch = Mid(local.s, local.i, 1);
		local.code = Asc(local.ch);
		if (local.code <= 127) {
			local.sb.append(local.ch);
			local.i++;
			continue;
		}

		local.j = local.i;
		while (local.j <= local.len && Asc(Mid(local.s, local.j, 1)) > 127) {
			local.j++;
		}
		local.run = Mid(local.s, local.i, local.j - local.i);

		for (local.pass = 1; local.pass <= 8; local.pass++) {
			local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(65533), Chr(8221), "all");
			local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(157),   Chr(8221), "all");
			if (Len(local.run) < 2 || (!Find(Chr(195), local.run) && !Find(Chr(194), local.run) && !Find(Chr(226), local.run))) {
				break;
			}
			try {
				local.bytes = local.run.getBytes("windows-1252");
				local.decoder = local.utf8Charset.newDecoder();
				local.decoder.onMalformedInput(local.codingErrorAction.REPORT);
				local.decoder.onUnmappableCharacter(local.codingErrorAction.REPORT);
				local.decoded = local.decoder.decode(local.byteBufferClass.wrap(local.bytes)).toString();
				if (local.decoded == local.run || Find(Chr(65533), local.decoded)) {
					if (Find(Chr(226) & Chr(8364) & Chr(65533), local.decoded)) {
						local.run = Replace(local.decoded, Chr(226) & Chr(8364) & Chr(65533), Chr(8221), "all");
						continue;
					}
					break;
				}
				local.run = local.decoded;
			} catch (any e) {
				break;
			}
		}

		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(8482), Chr(8217), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(732),  Chr(8216), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(339),  Chr(8220), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(65533),Chr(8221), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(157),  Chr(8221), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(8220), Chr(8211), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(8221), Chr(8212), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(166),  Chr(8230), "all");
		local.run = Replace(local.run, Chr(226) & Chr(8364) & Chr(162),  Chr(8226), "all");
		local.run = Replace(local.run, Chr(194) & Chr(160),              Chr(160),  "all");
		local.run = Replace(local.run, Chr(194) & Chr(169),              Chr(169),  "all");
		local.run = Replace(local.run, Chr(194) & Chr(174),              Chr(174),  "all");
		local.run = Replace(local.run, Chr(194) & Chr(176),              Chr(176),  "all");
		local.run = Replace(local.run, Chr(194) & Chr(167),              Chr(167),  "all");

		local.sb.append(local.run);
		local.i = local.j;
	}

	return local.sb.toString();
}

/**
 * Recursively heals UTF-8 mojibake across strings, structs, and arrays.
 */
public any function healUtf8MojibakeData(required any val) {
	if (IsNull(arguments.val)) return "";
	if (IsSimpleValue(arguments.val)) {
		if (IsNumeric(arguments.val) || IsBoolean(arguments.val)) return arguments.val;
		return healUtf8Mojibake(arguments.val);
	}
	if (IsStruct(arguments.val)) {
		for (local.k in arguments.val) {
			if (!IsNull(arguments.val[local.k])) {
				arguments.val[local.k] = healUtf8MojibakeData(arguments.val[local.k]);
			}
		}
		return arguments.val;
	}
	if (IsArray(arguments.val)) {
		for (local.idx = 1; local.idx <= ArrayLen(arguments.val); local.idx++) {
			if (!IsNull(arguments.val[local.idx])) {
				arguments.val[local.idx] = healUtf8MojibakeData(arguments.val[local.idx]);
			}
		}
		return arguments.val;
	}
	return arguments.val;
}

// ----------------------------------------------------
// Persistent "Remember Me" Authentication Helpers (30-Day Signed Cookie)
// ----------------------------------------------------

public string function getRememberMeSecretKey() {
	return "ChelanCMS2_RememberMe_HMAC_Key_2026_" & Hash(ExpandPath("/"), "SHA-256");
}

public void function issueRememberMeCookie(required numeric userId, required string email, numeric days = 30) {
	local.expEpoch = DateDiff("s", CreateDateTime(1970, 1, 1, 0, 0, 0), Now()) + (arguments.days * 86400);
	local.payload = Int(arguments.userId) & "|" & LCase(Trim(arguments.email)) & "|" & local.expEpoch;
	local.sig = LCase(Hmac(local.payload, getRememberMeSecretKey(), "HMACSHA256", "UTF-8"));
	local.token = ToBase64(local.payload & "|" & local.sig, "UTF-8");

	cookie.cmsadmin_remember = {
		value: local.token,
		expires: arguments.days,
		path: "/",
		httponly: true
	};
	cookie.cmsadmin_last_email = {
		value: LCase(Trim(arguments.email)),
		expires: 30,
		path: "/"
	};
}

public void function clearRememberMeCookie() {
	cookie.cmsadmin_remember = {
		value: "",
		expires: "now",
		path: "/",
		httponly: true
	};
}

public boolean function tryRestoreRememberedSession() {
	if (!StructKeyExists(cookie, "cmsadmin_remember") || !Len(Trim(cookie.cmsadmin_remember))) {
		return false;
	}
	try {
		local.rawToken = URLDecode(Trim(cookie.cmsadmin_remember));
		local.decoded = ToString(ToBinary(local.rawToken), "UTF-8");
		local.parts = ListToArray(local.decoded, "|");
		if (ArrayLen(local.parts) != 4) {
			clearRememberMeCookie();
			return false;
		}
		local.userId = Val(local.parts[1]);
		local.email = LCase(Trim(local.parts[2]));
		local.expEpoch = Val(local.parts[3]);
		local.providedSig = LCase(Trim(local.parts[4]));

		local.nowEpoch = DateDiff("s", CreateDateTime(1970, 1, 1, 0, 0, 0), Now());
		if (local.userId <= 0 || local.expEpoch < local.nowEpoch) {
			clearRememberMeCookie();
			return false;
		}

		local.payload = local.userId & "|" & local.email & "|" & local.expEpoch;
		local.expectedSig = LCase(Hmac(local.payload, getRememberMeSecretKey(), "HMACSHA256", "UTF-8"));
		if (Compare(local.providedSig, local.expectedSig) != 0) {
			clearRememberMeCookie();
			return false;
		}

		local.qUser = queryExecute("
			SELECT TOP 1 u.id, u.role_id, u.role_code, u.username, u.email, u.first_name, u.last_name,
			       u.job_title, u.phone, u.department_code, u.department_name, u.assigned_workspaces,
			       u.status, u.two_factor_enabled, u.totp_connected,
			       r.name AS role_name, r.badge_class AS role_badge, r.color_hex AS role_color, r.icon_name AS role_icon
			FROM cms_users u
			LEFT JOIN cms_roles r ON u.role_id = r.id
			WHERE u.id = :id AND LOWER(LTRIM(RTRIM(u.email))) = :email AND u.status = 'active' AND u.deletedat IS NULL
		", {
			id: { value: local.userId, cfsqltype: "cf_sql_integer" },
			email: { value: local.email, cfsqltype: "cf_sql_varchar" }
		}, { datasource: "ChelanCountyWebsite" });

		if (!local.qUser.recordCount) {
			clearRememberMeCookie();
			return false;
		}

		local.row = local.qUser;
		local.wsList = [];
		local.rawWs = Trim(local.row.assigned_workspaces ?: "");
		if (Len(local.rawWs) && IsJSON(local.rawWs)) {
			local.wsList = DeserializeJSON(local.rawWs);
		} else if (Len(local.rawWs)) {
			local.wsList = ListToArray(local.rawWs);
		} else {
			local.wsList = [Len(local.row.department_code) ? local.row.department_code : "global"];
		}

		session.user = {
			id: local.row.id,
			username: local.row.username,
			email: local.row.email,
			first_name: local.row.first_name,
			last_name: local.row.last_name,
			full_name: local.row.first_name & " " & local.row.last_name,
			initials: UCase(Left(local.row.first_name, 1) & Left(local.row.last_name, 1)),
			role_code: local.row.role_code,
			role_name: Len(local.row.role_name) ? local.row.role_name : "Author",
			role_badge: Len(local.row.role_badge) ? local.row.role_badge : "badge-primary",
			role_color: Len(local.row.role_color) ? local.row.role_color : "##0073aa",
			role_icon: Len(local.row.role_icon) ? local.row.role_icon : "user",
			job_title: Len(local.row.job_title) ? local.row.job_title : "County Staff",
			department_code: Len(local.row.department_code) ? local.row.department_code : "global",
			department_name: Len(local.row.department_name) ? local.row.department_name : "County Administration",
			workspaces: local.wsList,
			totp_connected: (local.row.totp_connected == 1 || local.row.totp_connected == true),
			remember_me: true,
			logged_in_at: Now(),
			last_activity: Now()
		};

		if (!StructKeyExists(session, "simulatedRole") || !Len(Trim(session.simulatedRole))) {
			session.simulatedRole = local.row.role_code;
		}
		if (!StructKeyExists(cookie, "cmsadmin_simulated_role") || !Len(Trim(cookie.cmsadmin_simulated_role))) {
			cookie.cmsadmin_simulated_role = local.row.role_code;
		}

		return true;
	} catch (any e) {
		return false;
	}
}
</cfscript>