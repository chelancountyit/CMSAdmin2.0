<cfscript>
// Global application helper functions


/**
 * Ensures the 16 canonical Chelan County workspaces exist in the SQL Server database.
 */
public void function ensureMasterWorkspacesTablePopulated() {
	try {
		var qCheck = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT COUNT(1) AS cnt FROM cms_workspaces
		", {}, { datasource: "ChelanCountyWebsite" });

		if (qCheck.cnt == 0) {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'global')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('global', 'All Workspaces', '', 'global', 'Global', 'badge-neutral', 'grid', 'County-wide unified view across all municipal divisions and portals', 'files/shared', 'shared', '', 'County-wide', 'County Administration', 1, 1, 0);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'assessor')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('assessor', 'Assessor - Property & Parcels', 'assessors', 'dept', 'Assessor', 'badge-info', 'building', 'Property assessment & shared media library', 'files/assessors', 'assessors', 'https://www.chelancounty.gov/assessor', 'Assessor', 'Finance and Records', 1, 0, 10);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'auditor')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('auditor', 'Auditor - Elections & Records', '', 'dept', 'Auditor', 'badge-purple', 'building', 'Elections, recording & licensing', 'files/auditor', 'auditor', 'https://www.chelancounty.gov/auditor', 'Auditor', 'Finance and Records', 1, 0, 20);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'human-resources')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('human-resources', 'Human Resources', 'hrm', 'dept', 'HRM', 'badge-purple', 'briefcase', 'Recruitment, personnel & benefits', 'files/hrm', 'hrm', 'https://www.chelancounty.gov/human-resources', 'Human Resources', 'Internal Services', 1, 1, 30);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'communications')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('communications', 'Public Information', 'pio', 'dept', 'PIO', 'badge-info', 'megaphone', 'Media alerts, press & notifications', 'files/pio', 'pio', 'https://www.chelancounty.gov/pio', 'Public Information', 'Community Outreach', 1, 1, 40);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'admin')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('admin', 'County Administration', 'county-administration', 'dept', 'Admin', 'badge-neutral', 'building', 'Commissioners, executive & budget', 'files/admin', 'admin', 'https://www.chelancounty.gov/administration', 'County Administration', 'County Administration', 1, 1, 70);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'commissioners')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('commissioners', 'Board of Commissioners', '', 'dept', 'Commissioners', 'badge-neutral', 'building', 'County Commissioners & legislative agendas', 'files/commissioners', 'commissioners', 'https://www.chelancounty.gov/board-of-commissioners', 'Commissioners', 'County Administration', 1, 0, 80);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'sheriff')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('sheriff', 'Sheriff''s Office', '', 'dept', 'Sheriff', 'badge-neutral', 'shield', 'Law enforcement & public safety', 'files/sheriff', 'sheriff', 'https://www.chelancounty.gov/sheriff', 'Sheriff', 'Law Enforcement', 1, 0, 90);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'treasurer')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('treasurer', 'Treasurer', '', 'dept', 'Treasurer', 'badge-neutral', 'building', 'Tax collections & county finance', 'files/treasurer', 'treasurer', 'https://www.chelancounty.gov/treasurer', 'Treasurer', 'Finance and Records', 1, 0, 100);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'clerk')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('clerk', 'County Clerk', '', 'dept', 'Clerk', 'badge-neutral', 'building', 'Superior court records & judicial filings', 'files/clerk', 'clerk', 'https://www.chelancounty.gov/clerk', 'County Clerk', 'Law and Judicial Services', 1, 0, 110);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'site-main')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('site-main', 'chelancounty.gov', 'chelancounty.gov', 'site', 'Main Site', 'badge-success', 'globe', 'Primary County public government portal', 'files/chelancounty.gov', 'chelancounty.gov', 'https://www.chelancounty.gov', 'Public Portal', 'County Administration', 1, 0, 120);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'site-parks')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('site-parks', 'parks.chelancounty.gov', 'parks.chelancounty.gov', 'site', 'Subsite', 'badge-primary', 'globe', 'County Parks & Recreation portal', 'files/parks.chelancounty.gov', 'parks.chelancounty.gov', 'https://parks.chelancounty.gov', 'Parks & Recreation', 'Community Services', 1, 0, 130);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'site-gis')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('site-gis', 'gis.chelancounty.gov', 'gis.chelancounty.gov', 'site', 'Portal', 'badge-warning', 'globe', 'GIS, parcel viewer & map layers', 'files/gis.chelancounty.gov', 'gis.chelancounty.gov', 'https://gis.chelancounty.gov', 'Information Technology / GIS', 'Internal Services', 1, 0, 140);

				IF NOT EXISTS (SELECT 1 FROM cms_workspaces WHERE code = 'site-expo')
					INSERT INTO cms_workspaces (code, name, alias, type, badge, badge_class, icon, description, folder_path, virtual_directory, redirect_url, department, department_category, is_active, is_system, sort_order)
					VALUES ('site-expo', 'expo.chelancounty.gov', 'expo.chelancounty.gov', 'site', 'Portal', 'badge-info', 'globe', 'Chelan County Expo Center & Fairgrounds', 'files/expo.chelancounty.gov', 'expo.chelancounty.gov', 'https://expo.chelancounty.gov', 'Expo Center', 'Chelan-Douglas', 1, 0, 150);
			", {}, { datasource: "ChelanCountyWebsite" });
		}
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
					color: (structKeyExists(row, "color") && len(trim(row.color))) ? trim(row.color) : (row.type eq "dept" ? "##7e22ce" : (row.type eq "site" ? "##10b981" : "##0073aa")),
					badge: row.badge,
					badgeClass: row.badge_class,
					icon: row.icon,
					desc: len(row.description ?: "") ? row.description : (row.name & " Portal"),
					subtitle: len(row.description ?: "") ? row.description : (row.name & " Portal"),
					folderPath: row.folder_path,
					virtual_directory: row.virtual_directory,
					department: len(row.department ?: "") ? row.department : row.name,
					department_category: len(row.department_category ?: "") ? row.department_category : "",
					redirect_url: len(row.redirect_url ?: "") ? row.redirect_url : "",
					is_system: (isNumeric(row.is_system) && row.is_system == 1) ? true : false,
					contact: {
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
				contact: {
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
</cfscript>
