component extends="Controller" {

	function config() {
		super.config();
	}

	/**
	 * Users Directory listing with multi-facet filters & KPI metrics
	 * Grounded in live Microsoft SQL Server database (cms_users & cms_roles)
	 */
	function index() {
		variables.pageTitle = "Users & Roles";

		local.allUsers = getStoredUsers();
		local.filtered = [];

		local.filterRole = StructKeyExists(params, "role") ? LCase(Trim(params.role)) : "all";
		local.filterStatus = StructKeyExists(params, "status") ? LCase(Trim(params.status)) : "all";
		local.filterDept = StructKeyExists(params, "dept") ? LCase(Trim(params.dept)) : "all";
		local.searchQuery = StructKeyExists(params, "q") ? LCase(Trim(params.q)) : "";

		// Calculate metric counts across all database users
		variables.metrics = {
			total: ArrayLen(local.allUsers),
			admin: 0,
			pio: 0,
			hr: 0,
			author: 0,
			active: 0,
			inactive: 0
		};

		for (local.u in local.allUsers) {
			if (local.u.role_code == "admin") variables.metrics.admin++;
			else if (local.u.role_code == "pio") variables.metrics.pio++;
			else if (local.u.role_code == "hr") variables.metrics.hr++;
			else if (local.u.role_code == "author") variables.metrics.author++;

			if (local.u.status == "active") variables.metrics.active++;
			else variables.metrics.inactive++;

			// Apply search & facet filters
			local.matches = true;

			if (local.filterRole != "all" && local.u.role_code != local.filterRole) {
				local.matches = false;
			}
			if (local.filterStatus != "all" && local.u.status != local.filterStatus) {
				local.matches = false;
			}
			if (local.filterDept != "all") {
				local.hasWs = false;
				if (StructKeyExists(local.u, "workspaces") && IsArray(local.u.workspaces)) {
					if (ArrayFindNoCase(local.u.workspaces, local.filterDept) || ArrayFindNoCase(local.u.workspaces, "global")) {
						local.hasWs = true;
					}
				} else if (local.u.department_code == local.filterDept || local.u.department_code == "global") {
					local.hasWs = true;
				}
				if (!local.hasWs) local.matches = false;
			}
			if (Len(local.searchQuery)) {
				local.combined = LCase(local.u.first_name & " " & local.u.last_name & " " & local.u.email & " " & local.u.username & " " & local.u.job_title);
				if (!Find(local.searchQuery, local.combined)) {
					local.matches = false;
				}
			}

			if (local.matches) {
				ArrayAppend(local.filtered, local.u);
			}
		}

		variables.users = local.filtered;
		variables.roles = getRolesList();
		variables.workspaces = getWorkspacesList();
		variables.departments = variables.workspaces;
		variables.activeFilterRole = local.filterRole;
		variables.activeFilterStatus = local.filterStatus;
		variables.activeFilterDept = local.filterDept;
		variables.activeSearchQuery = local.searchQuery;
		variables.currentSimulatedRole = getActiveSimulatedRole();
	}

	/**
	 * Roles & Permissions Studio - Comprehensive Permissions Matrix
	 */
	function roles() {
		variables.pageTitle = "Roles & Permissions Matrix";
		variables.roles = getRolesList();
		variables.allUsers = getStoredUsers();
		variables.capabilities = getCapabilityMatrix();
		variables.currentSimulatedRole = getActiveSimulatedRole();
	}

	/**
	 * Add New User Form
	 */
	function new() {
		variables.pageTitle = "Add New User";
		variables.user = {
			id: 0,
			first_name: "",
			last_name: "",
			email: "",
			username: "",
			job_title: "",
			phone: "",
			role_code: StructKeyExists(params, "role") ? Trim(params.role) : "author",
			department_code: "global",
			department_name: "All Workspaces (Global)",
			workspaces: ["global"],
			status: "active",
			two_factor_enabled: false,
			send_welcome: true
		};
		variables.isNew = true;
		variables.roles = getRolesList();
		variables.workspaces = getWorkspacesList();
		variables.departments = variables.workspaces;
	}

	/**
	 * Edit User Form
	 */
	function edit() {
		variables.isNew = false;
		local.targetId = 0;
		if (StructKeyExists(params, "id") && Val(params.id) > 0) {
			local.targetId = Val(params.id);
		} else if (StructKeyExists(params, "key") && Val(params.key) > 0) {
			local.targetId = Val(params.key);
		}

		if (local.targetId <= 0) {
			flashInsert(error="Invalid staff user ID specified.");
			redirectTo(controller="users", action="index");
			return;
		}

		local.allUsers = getStoredUsers();
		variables.user = {};

		for (local.u in local.allUsers) {
			if (local.u.id == local.targetId) {
				variables.user = local.u;
				break;
			}
		}

		if (StructIsEmpty(variables.user)) {
			flashInsert(error="User account ##" & local.targetId & " not found in database.");
			redirectTo(controller="users", action="index");
			return;
		}

		// Ensure workspaces array is initialized
		if (!StructKeyExists(variables.user, "workspaces") || !IsArray(variables.user.workspaces) || ArrayLen(variables.user.workspaces) == 0) {
			variables.user.workspaces = [StructKeyExists(variables.user, "department_code") ? variables.user.department_code : "global"];
		}

		variables.pageTitle = "Edit User - " & variables.user.first_name & " " & variables.user.last_name;
		variables.roles = getRolesList();
		variables.workspaces = getWorkspacesList();
		variables.departments = variables.workspaces;
	}

	/**
	 * Save / Create User Action
	 * Persists user into cms_users and multi-workspace assignments into cms_user_workspaces
	 */
	function create() {
		local.roleCode = StructKeyExists(params, "role_code") ? LCase(Trim(params.role_code)) : "author";
		local.firstName = StructKeyExists(params, "first_name") ? Trim(params.first_name) : "";
		local.lastName = StructKeyExists(params, "last_name") ? Trim(params.last_name) : "";
		local.email = StructKeyExists(params, "email") ? Trim(params.email) : "";

		if (!Len(local.firstName) || !Len(local.lastName) || !Len(local.email)) {
			flashInsert(error="Please provide First Name, Last Name, and Email address.");
			redirectTo(controller="users", action="new");
			return;
		}

		// Determine username
		local.username = StructKeyExists(params, "username") && Len(Trim(params.username)) 
			? Trim(params.username) 
			: LCase(Left(local.firstName, 1) & local.lastName);
		
		// Sanitize username (remove special characters)
		local.username = ReReplace(local.username, "[^a-zA-Z0-9_\.\-]", "", "all");
		if (!Len(local.username)) {
			local.username = "user" & RandRange(1000, 9999);
		}

		// Check email uniqueness
		local.qEmailCheck = queryExecute("
			SELECT id FROM cms_users WHERE email = :email AND deletedat IS NULL
		", { email: { value: local.email, cfsqltype: "cf_sql_varchar" } }, { datasource: getDb() });
		if (local.qEmailCheck.recordCount > 0) {
			flashInsert(error="A user account with email <strong>#local.email#</strong> already exists in the system.");
			redirectTo(controller="users", action="new");
			return;
		}

		// Check username uniqueness, auto-disambiguate if needed
		local.baseUsername = local.username;
		local.userSuffix = 1;
		while (true) {
			local.qUserCheck = queryExecute("
				SELECT id FROM cms_users WHERE username = :username AND deletedat IS NULL
			", { username: { value: local.username, cfsqltype: "cf_sql_varchar" } }, { datasource: getDb() });
			if (local.qUserCheck.recordCount == 0) break;
			local.userSuffix++;
			local.username = local.baseUsername & local.userSuffix;
		}

		// Lookup role_id from cms_roles
		local.qRole = queryExecute("
			SELECT id, name FROM cms_roles WHERE code = :code
		", { code: { value: local.roleCode, cfsqltype: "cf_sql_varchar" } }, { datasource: getDb() });

		local.roleId = 4; // default to author
		if (local.qRole.recordCount > 0) {
			local.roleId = local.qRole.id;
		} else {
			local.qFallback = queryExecute("SELECT id FROM cms_roles WHERE code = 'author'", {}, { datasource: getDb() });
			if (local.qFallback.recordCount > 0) local.roleId = local.qFallback.id;
		}

		// Parse multi-workspace input
		local.workspacesList = [];
		if (StructKeyExists(params, "workspaces")) {
			local.workspacesList = parseWorkspacesInput(params.workspaces);
		} else if (StructKeyExists(params, "department_code") && Len(Trim(params.department_code))) {
			local.workspacesList = [Trim(params.department_code)];
		} else {
			local.workspacesList = ["global"];
		}

		local.primaryWs = ArrayLen(local.workspacesList) > 0 ? local.workspacesList[1] : "global";
		local.deptName = getDeptNameByCode(local.primaryWs);
		local.jobTitle = StructKeyExists(params, "job_title") && Len(Trim(params.job_title)) ? Trim(params.job_title) : "Web Contributor";
		local.phone = StructKeyExists(params, "phone") ? Trim(params.phone) : "";
		local.status = StructKeyExists(params, "status") ? Trim(params.status) : "active";
		local.twoFactor = (StructKeyExists(params, "two_factor_enabled") && (params.two_factor_enabled == "1" || params.two_factor_enabled == "true" || params.two_factor_enabled == true)) ? 1 : 0;
		
		// Hash default temporary password
		local.tempPassword = "Password123!";
		local.passwordHash = bcryptHash(local.tempPassword);

		// Insert user record into cms_users
		local.qInsert = queryExecute("
			INSERT INTO cms_users (
				role_id, role_code, username, email, first_name, last_name,
				job_title, phone, department_code, department_name, assigned_workspaces,
				password_hash, status, two_factor_enabled, force_password_change,
				createdat, updatedat
			) VALUES (
				:role_id, :role_code, :username, :email, :first_name, :last_name,
				:job_title, :phone, :department_code, :department_name, :assigned_workspaces,
				:password_hash, :status, :two_factor_enabled, 1,
				SYSUTCDATETIME(), SYSUTCDATETIME()
			);
			SELECT SCOPE_IDENTITY() AS new_id;
		", {
			role_id: { value: local.roleId, cfsqltype: "cf_sql_integer" },
			role_code: { value: local.roleCode, cfsqltype: "cf_sql_varchar" },
			username: { value: local.username, cfsqltype: "cf_sql_varchar" },
			email: { value: local.email, cfsqltype: "cf_sql_varchar" },
			first_name: { value: local.firstName, cfsqltype: "cf_sql_varchar" },
			last_name: { value: local.lastName, cfsqltype: "cf_sql_varchar" },
			job_title: { value: local.jobTitle, cfsqltype: "cf_sql_varchar" },
			phone: { value: local.phone, cfsqltype: "cf_sql_varchar" },
			department_code: { value: local.primaryWs, cfsqltype: "cf_sql_varchar" },
			department_name: { value: local.deptName, cfsqltype: "cf_sql_varchar" },
			assigned_workspaces: { value: SerializeJSON(local.workspacesList), cfsqltype: "cf_sql_varchar" },
			password_hash: { value: local.passwordHash, cfsqltype: "cf_sql_varchar" },
			status: { value: local.status, cfsqltype: "cf_sql_varchar" },
			two_factor_enabled: { value: local.twoFactor, cfsqltype: "cf_sql_bit" }
		}, { datasource: getDb() });

		local.newUserId = Val(local.qInsert.new_id);

		// Insert workspaces into cms_user_workspaces
		if (local.newUserId > 0) {
			for (local.idx = 1; local.idx <= ArrayLen(local.workspacesList); local.idx++) {
				local.wsCode = local.workspacesList[local.idx];
				local.isPrimary = (local.idx == 1) ? 1 : 0;
				queryExecute("
					IF NOT EXISTS (SELECT 1 FROM cms_user_workspaces WHERE user_id = :uid AND workspace_code = :ws)
					BEGIN
						INSERT INTO cms_user_workspaces (user_id, workspace_code, is_primary, createdat)
						VALUES (:uid, :ws, :is_primary, SYSUTCDATETIME())
					END
				", {
					uid: { value: local.newUserId, cfsqltype: "cf_sql_integer" },
					ws: { value: local.wsCode, cfsqltype: "cf_sql_varchar" },
					is_primary: { value: local.isPrimary, cfsqltype: "cf_sql_bit" }
				}, { datasource: getDb() });
			}
		}

		// Refresh application cache from database
		getStoredUsers();

		flashInsert(success="User account for <strong>#local.firstName# #local.lastName#</strong> (<code>#local.username#</code>) created with <strong>#UCase(local.roleCode)#</strong> permissions and assigned to <strong>#ArrayLen(local.workspacesList)# workspace(s)</strong>.");
		redirectTo(controller="users", action="index");
	}

	/**
	 * Update User Action
	 * Updates existing cms_users record and synchronizes cms_user_workspaces
	 */
	function update() {
		local.targetId = StructKeyExists(params, "id") ? Val(params.id) : 0;
		if (local.targetId <= 0) {
			flashInsert(error="Invalid user ID specified.");
			redirectTo(controller="users", action="index");
			return;
		}

		local.firstName = StructKeyExists(params, "first_name") ? Trim(params.first_name) : "";
		local.lastName = StructKeyExists(params, "last_name") ? Trim(params.last_name) : "";
		local.email = StructKeyExists(params, "email") ? Trim(params.email) : "";
		local.username = StructKeyExists(params, "username") ? LCase(Trim(params.username)) : "";

		if (!Len(local.firstName) || !Len(local.lastName) || !Len(local.email)) {
			flashInsert(error="Please provide First Name, Last Name, and Email address.");
			redirectTo(controller="users", action="edit", params="id=" & local.targetId);
			return;
		}

		// Sanitize and validate username
		local.username = ReReplace(local.username, "[^a-zA-Z0-9_\.\-]", "", "all");
		if (!Len(local.username)) {
			flashInsert(error="Please provide a valid Username (alphanumeric, dots, hyphens, and underscores only).");
			redirectTo(controller="users", action="edit", params="id=" & local.targetId);
			return;
		}

		// Check username uniqueness against other users
		local.qUserCheck = queryExecute("
			SELECT id FROM cms_users WHERE username = :username AND id <> :id AND deletedat IS NULL
		", {
			username: { value: local.username, cfsqltype: "cf_sql_varchar" },
			id: { value: local.targetId, cfsqltype: "cf_sql_integer" }
		}, { datasource: getDb() });
		if (local.qUserCheck.recordCount > 0) {
			flashInsert(error="Another user account is already using the username <strong>#local.username#</strong>.");
			redirectTo(controller="users", action="edit", params="id=" & local.targetId);
			return;
		}

		// Check email uniqueness against other users
		local.qEmailCheck = queryExecute("
			SELECT id FROM cms_users WHERE email = :email AND id <> :id AND deletedat IS NULL
		", {
			email: { value: local.email, cfsqltype: "cf_sql_varchar" },
			id: { value: local.targetId, cfsqltype: "cf_sql_integer" }
		}, { datasource: getDb() });
		if (local.qEmailCheck.recordCount > 0) {
			flashInsert(error="Another user account is already using the email address <strong>#local.email#</strong>.");
			redirectTo(controller="users", action="edit", params="id=" & local.targetId);
			return;
		}

		local.roleCode = StructKeyExists(params, "role_code") ? LCase(Trim(params.role_code)) : "author";
		local.qRole = queryExecute("
			SELECT id FROM cms_roles WHERE code = :code
		", { code: { value: local.roleCode, cfsqltype: "cf_sql_varchar" } }, { datasource: getDb() });
		local.roleId = (local.qRole.recordCount > 0) ? local.qRole.id : 4;

		// Parse multi-workspace input
		local.workspacesList = [];
		if (StructKeyExists(params, "workspaces")) {
			local.workspacesList = parseWorkspacesInput(params.workspaces);
		} else if (StructKeyExists(params, "department_code") && Len(Trim(params.department_code))) {
			local.workspacesList = [Trim(params.department_code)];
		} else {
			local.workspacesList = ["global"];
		}

		local.primaryWs = ArrayLen(local.workspacesList) > 0 ? local.workspacesList[1] : "global";
		local.deptName = getDeptNameByCode(local.primaryWs);
		local.jobTitle = StructKeyExists(params, "job_title") ? Trim(params.job_title) : "Web Contributor";
		local.phone = StructKeyExists(params, "phone") ? Trim(params.phone) : "";
		local.status = StructKeyExists(params, "status") ? Trim(params.status) : "active";
		local.twoFactor = (StructKeyExists(params, "two_factor_enabled") && (params.two_factor_enabled == "1" || params.two_factor_enabled == "true" || params.two_factor_enabled == true)) ? 1 : 0;

		// Update cms_users
		queryExecute("
			UPDATE cms_users SET
				first_name = :first_name,
				last_name = :last_name,
				email = :email,
				username = :username,
				job_title = :job_title,
				phone = :phone,
				role_id = :role_id,
				role_code = :role_code,
				department_code = :department_code,
				department_name = :department_name,
				assigned_workspaces = :assigned_workspaces,
				status = :status,
				two_factor_enabled = :two_factor_enabled,
				updatedat = SYSUTCDATETIME()
			WHERE id = :id AND deletedat IS NULL
		", {
			first_name: { value: local.firstName, cfsqltype: "cf_sql_varchar" },
			last_name: { value: local.lastName, cfsqltype: "cf_sql_varchar" },
			email: { value: local.email, cfsqltype: "cf_sql_varchar" },
			username: { value: local.username, cfsqltype: "cf_sql_varchar" },
			job_title: { value: local.jobTitle, cfsqltype: "cf_sql_varchar" },
			phone: { value: local.phone, cfsqltype: "cf_sql_varchar" },
			role_id: { value: local.roleId, cfsqltype: "cf_sql_integer" },
			role_code: { value: local.roleCode, cfsqltype: "cf_sql_varchar" },
			department_code: { value: local.primaryWs, cfsqltype: "cf_sql_varchar" },
			department_name: { value: local.deptName, cfsqltype: "cf_sql_varchar" },
			assigned_workspaces: { value: SerializeJSON(local.workspacesList), cfsqltype: "cf_sql_varchar" },
			status: { value: local.status, cfsqltype: "cf_sql_varchar" },
			two_factor_enabled: { value: local.twoFactor, cfsqltype: "cf_sql_bit" },
			id: { value: local.targetId, cfsqltype: "cf_sql_integer" }
		}, { datasource: getDb() });

		// Sync cms_user_workspaces
		queryExecute("
			DELETE FROM cms_user_workspaces WHERE user_id = :uid
		", { uid: { value: local.targetId, cfsqltype: "cf_sql_integer" } }, { datasource: getDb() });

		for (local.idx = 1; local.idx <= ArrayLen(local.workspacesList); local.idx++) {
			local.wsCode = local.workspacesList[local.idx];
			local.isPrimary = (local.idx == 1) ? 1 : 0;
			queryExecute("
				INSERT INTO cms_user_workspaces (user_id, workspace_code, is_primary, createdat)
				VALUES (:uid, :ws, :is_primary, SYSUTCDATETIME())
			", {
				uid: { value: local.targetId, cfsqltype: "cf_sql_integer" },
				ws: { value: local.wsCode, cfsqltype: "cf_sql_varchar" },
				is_primary: { value: local.isPrimary, cfsqltype: "cf_sql_bit" }
			}, { datasource: getDb() });
		}

		// Refresh application cache
		getStoredUsers();

		flashInsert(success="User account ##" & local.targetId & " (<strong>#local.firstName# #local.lastName#</strong> &bull; <code>#local.username#</code>) updated successfully with assigned workspace scoping.");
		redirectTo(controller="users", action="index");
	}

	/**
	 * Staff User Profile View & Settings
	 * Allows logged in staff to view their account info, update contact details,
	 * change their password, and configure multi-factor authentication (2FA).
	 */
	function profile() {
		variables.pageTitle = "My Profile & Security Settings";

		// Resolve current user ID from session.user or fallback
		local.userId = (StructKeyExists(session, "user") && StructKeyExists(session.user, "id") && Val(session.user.id) > 0)
			? Val(session.user.id) : 1;

		local.allUsers = getStoredUsers();
		variables.user = {};

		for (local.u in local.allUsers) {
			if (local.u.id == local.userId) {
				variables.user = local.u;
				break;
			}
		}

		if (StructIsEmpty(variables.user)) {
			// Query directly if not found in cache
			local.q = queryExecute("
				SELECT TOP 1 u.id, u.role_id, u.role_code, u.username, u.email, u.first_name, u.last_name,
				       u.job_title, u.phone, u.department_code, u.department_name, u.assigned_workspaces,
				       u.status, u.two_factor_enabled, u.totp_connected, u.last_login_at, u.createdat,
				       r.name AS role_name, r.badge_class AS role_badge
				FROM cms_users u
				LEFT JOIN cms_roles r ON u.role_id = r.id
				WHERE u.id = :id AND u.deletedat IS NULL
			", { id: { value: local.userId, cfsqltype: "cf_sql_integer" } }, { datasource: getDb() });

			if (local.q.recordCount > 0) {
				variables.user = {
					id: local.q.id,
					role_id: local.q.role_id,
					role_code: local.q.role_code,
					role_name: local.q.role_name,
					role_badge: local.q.role_badge,
					username: local.q.username,
					email: local.q.email,
					first_name: local.q.first_name,
					last_name: local.q.last_name,
					job_title: local.q.job_title ?: "County Staff",
					phone: local.q.phone ?: "",
					department_code: local.q.department_code ?: "global",
					department_name: local.q.department_name ?: "County Administration",
					workspaces: ["global"],
					status: local.q.status,
					two_factor_enabled: (local.q.two_factor_enabled == 1),
					totp_connected: (local.q.totp_connected == 1),
					last_login_at: local.q.last_login_at,
					createdat: local.q.createdat
				};
			}
		}

		variables.roles = getRolesList();
		variables.workspaces = getWorkspacesList();
	}

	/**
	 * Update Personal Profile Information (First Name, Last Name, Job Title, Phone)
	 */
	function updateProfile() {
		local.userId = (StructKeyExists(session, "user") && StructKeyExists(session.user, "id") && Val(session.user.id) > 0)
			? Val(session.user.id) : (StructKeyExists(params, "id") ? Val(params.id) : 1);

		local.firstName = StructKeyExists(params, "first_name") ? Trim(params.first_name) : "";
		local.lastName = StructKeyExists(params, "last_name") ? Trim(params.last_name) : "";
		local.jobTitle = StructKeyExists(params, "job_title") ? Trim(params.job_title) : "";
		local.phone = StructKeyExists(params, "phone") ? Trim(params.phone) : "";

		if (!Len(local.firstName) || !Len(local.lastName)) {
			flashInsert(error="First Name and Last Name are required.");
			redirectTo(controller="users", action="profile");
			return;
		}

		queryExecute("
			UPDATE cms_users SET
				first_name = :fn,
				last_name = :ln,
				job_title = :jt,
				phone = :phone,
				updatedat = SYSUTCDATETIME()
			WHERE id = :id AND deletedat IS NULL
		", {
			fn: { value: local.firstName, cfsqltype: "cf_sql_varchar" },
			ln: { value: local.lastName, cfsqltype: "cf_sql_varchar" },
			jt: { value: local.jobTitle, cfsqltype: "cf_sql_varchar" },
			phone: { value: local.phone, cfsqltype: "cf_sql_varchar" },
			id: { value: local.userId, cfsqltype: "cf_sql_integer" }
		}, { datasource: getDb() });

		// Synchronize session.user if active
		if (StructKeyExists(session, "user") && isStruct(session.user)) {
			session.user.first_name = local.firstName;
			session.user.last_name = local.lastName;
			session.user.full_name = local.firstName & " " & local.lastName;
			session.user.initials = UCase(Left(local.firstName, 1) & Left(local.lastName, 1));
			session.user.job_title = local.jobTitle;
			session.user.phone = local.phone;
		}

		getStoredUsers();

		flashInsert(success="<strong>Profile Updated!</strong> Your name and contact details were saved successfully.");
		redirectTo(controller="users", action="profile");
	}

	/**
	 * Update Password Action (verifies current password and updates password_hash)
	 */
	function updatePassword() {
		local.userId = (StructKeyExists(session, "user") && StructKeyExists(session.user, "id") && Val(session.user.id) > 0)
			? Val(session.user.id) : (StructKeyExists(params, "id") ? Val(params.id) : 1);

		local.currentPassword = StructKeyExists(params, "current_password") ? Trim(params.current_password) : "";
		local.newPassword = StructKeyExists(params, "new_password") ? Trim(params.new_password) : "";
		local.confirmPassword = StructKeyExists(params, "confirm_password") ? Trim(params.confirm_password) : "";

		if (!Len(local.newPassword) || Len(local.newPassword) < 8) {
			flashInsert(error="New password must be at least 8 characters long.");
			redirectTo(controller="users", action="profile");
			return;
		}

		if (local.newPassword != local.confirmPassword) {
			flashInsert(error="The new password and confirmation password do not match.");
			redirectTo(controller="users", action="profile");
			return;
		}

		// Retrieve current password hash from database
		local.qUser = queryExecute("
			SELECT password_hash FROM cms_users WHERE id = :id AND deletedat IS NULL
		", { id: { value: local.userId, cfsqltype: "cf_sql_integer" } }, { datasource: getDb() });

		if (local.qUser.recordCount == 0) {
			flashInsert(error="User account not found.");
			redirectTo(controller="users", action="profile");
			return;
		}

		// Verify current password if user has an existing hash
		local.storedHash = local.qUser.password_hash;
		if (Len(local.storedHash) && Len(local.currentPassword)) {
			try {
				local.matches = bcryptVerify(local.currentPassword, local.storedHash);
				if (!local.matches) {
					flashInsert(error="The current password you entered is incorrect.");
					redirectTo(controller="users", action="profile");
					return;
				}
			} catch (any eVerify) {
				// Fallback if hash was simple string or demo password
				if (local.currentPassword != "Password123!" && local.currentPassword != local.storedHash) {
					flashInsert(error="The current password you entered is incorrect.");
					redirectTo(controller="users", action="profile");
					return;
				}
			}
		}

		// Generate new bcrypt hash
		local.newHash = bcryptHash(local.newPassword);

		queryExecute("
			UPDATE cms_users SET
				password_hash = :hash,
				force_password_change = 0,
				updatedat = SYSUTCDATETIME()
			WHERE id = :id AND deletedat IS NULL
		", {
			hash: { value: local.newHash, cfsqltype: "cf_sql_varchar" },
			id: { value: local.userId, cfsqltype: "cf_sql_integer" }
		}, { datasource: getDb() });

		flashInsert(success="<strong>Password Updated!</strong> Your account password has been changed successfully.");
		redirectTo(controller="users", action="profile");
	}

	/**
	 * Toggle Two-Factor Authentication (2FA) for current staff user
	 */
	function toggle2Fa() {
		local.userId = (StructKeyExists(session, "user") && StructKeyExists(session.user, "id") && Val(session.user.id) > 0)
			? Val(session.user.id) : (StructKeyExists(params, "id") ? Val(params.id) : 1);

		local.q = queryExecute("
			SELECT two_factor_enabled FROM cms_users WHERE id = :id AND deletedat IS NULL
		", { id: { value: local.userId, cfsqltype: "cf_sql_integer" } }, { datasource: getDb() });

		if (local.q.recordCount > 0) {
			local.new2Fa = (local.q.two_factor_enabled == 1) ? 0 : 1;
			queryExecute("
				UPDATE cms_users SET
					two_factor_enabled = :val,
					updatedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL
			", {
				val: { value: local.new2Fa, cfsqltype: "cf_sql_bit" },
				id: { value: local.userId, cfsqltype: "cf_sql_integer" }
			}, { datasource: getDb() });

			if (StructKeyExists(session, "user") && isStruct(session.user)) {
				session.user.two_factor_enabled = (local.new2Fa == 1);
			}

			getStoredUsers();

			if (local.new2Fa == 1) {
				flashInsert(success="<strong>Two-Factor Authentication Enabled!</strong> 2FA verification will now be required on sign in.");
			} else {
				flashInsert(info="Two-Factor Authentication has been disabled for your account.");
			}
		}

		redirectTo(controller="users", action="profile");
	}

	/**
	 * Toggle active / inactive status
	 */
	function toggleStatus() {
		local.targetId = StructKeyExists(params, "id") ? Val(params.id) : 0;
		if (local.targetId <= 0) {
			if (StructKeyExists(params, "format") && params.format == "json") {
				renderText(text='{"success": false, "message": "Invalid user ID"}', contentType="application/json");
				return;
			}
			flashInsert(error="Invalid user ID specified.");
			redirectTo(controller="users", action="index");
			return;
		}

		local.qUser = queryExecute("
			SELECT status FROM cms_users WHERE id = :id AND deletedat IS NULL
		", { id: { value: local.targetId, cfsqltype: "cf_sql_integer" } }, { datasource: getDb() });

		if (local.qUser.recordCount == 0) {
			if (StructKeyExists(params, "format") && params.format == "json") {
				renderText(text='{"success": false, "message": "User not found"}', contentType="application/json");
				return;
			}
			flashInsert(error="User not found.");
			redirectTo(controller="users", action="index");
			return;
		}

		local.newStatus = (local.qUser.status == "active") ? "inactive" : "active";

		queryExecute("
			UPDATE cms_users SET status = :status, updatedat = SYSUTCDATETIME() WHERE id = :id
		", {
			status: { value: local.newStatus, cfsqltype: "cf_sql_varchar" },
			id: { value: local.targetId, cfsqltype: "cf_sql_integer" }
		}, { datasource: getDb() });

		getStoredUsers();

		if (StructKeyExists(params, "format") && params.format == "json") {
			renderText(text='{"success": true, "status": "' & local.newStatus & '"}', contentType="application/json");
			return;
		}

		flashInsert(info="User status changed to <strong>" & UCase(local.newStatus) & "</strong>.");
		redirectTo(controller="users", action="index");
	}

	/**
	 * Soft delete user account
	 */
	function delete() {
		local.targetId = StructKeyExists(params, "id") ? Val(params.id) : 0;
		if (local.targetId > 0) {
			queryExecute("
				UPDATE cms_users SET deletedat = SYSUTCDATETIME(), updatedat = SYSUTCDATETIME() WHERE id = :id
			", { id: { value: local.targetId, cfsqltype: "cf_sql_integer" } }, { datasource: getDb() });
			getStoredUsers();
			flashInsert(success="User account ##" & local.targetId & " deleted successfully.");
		}
		redirectTo(controller="users", action="index");
	}

	/**
	 * Role Simulation Switcher
	 * Allows administrators to preview the CMS interface as Admin, PIO, HR, or Author.
	 * Non-admin groups are strictly prohibited from simulating roles.
	 */
	function simulate() {
		// Security Check: Only administrators are permitted to simulate user groups
		if (!isRealAdmin()) {
			flashInsert(error="Access Denied: Role simulation is restricted exclusively to the Administrator group.");
			redirectTo(controller="main", action="index");
			return;
		}

		local.targetRole = StructKeyExists(params, "role") ? LCase(Trim(params.role)) : "admin";
		if (!ListFind("admin,pio,hr,author", local.targetRole)) {
			local.targetRole = "admin";
		}

		// Store in session and cookie
		session.simulatedRole = local.targetRole;
		cookie.cmsadmin_simulated_role = local.targetRole;

		// Automatically adjust active workspace cookie to role permissions
		if (local.targetRole neq "admin") {
			local.assigned = getUserAssignedWorkspaceCodes(local.targetRole);
			if (ArrayLen(local.assigned) gt 0) {
				cookie.cmsadmin_workspace = local.assigned[1];
			}
		} else {
			cookie.cmsadmin_workspace = "global";
		}

		local.roleMap = {
			"admin": "Administrator (Full Access to Everything)",
			"pio": "PIO (Content Management + PIO Group)",
			"hr": "HR (Content Management + HRM Group)",
			"author": "Author (General Web Update - Content Management Only)"
		};

		flashInsert(success="Role simulation activated: <strong>#local.roleMap[local.targetRole]#</strong>. The sidebar menu and permission gates have adapted.");

		// Redirect to returnUrl if provided, otherwise default to roles matrix or home
		if (StructKeyExists(params, "returnUrl") && Len(Trim(params.returnUrl))) {
			redirectTo(back=true);
		} else {
			redirectTo(controller="users", action="roles");
		}
	}

	// --------------------------------------------------------------------------
	// PRIVATE DATA PROVIDERS & HELPERS (WIRED TO DATABASE)
	// --------------------------------------------------------------------------

	private string function getDb() {
		return get("dataSourceName");
	}

	private string function getActiveSimulatedRole() {
		// Non-admin groups are strictly locked to their genuine assigned role
		if (!isRealAdmin()) {
			return getAuthenticatedUserRole();
		}
		if (StructKeyExists(cookie, "cmsadmin_simulated_role") && Len(cookie.cmsadmin_simulated_role)) {
			return LCase(cookie.cmsadmin_simulated_role);
		}
		if (StructKeyExists(session, "simulatedRole") && Len(session.simulatedRole)) {
			return LCase(session.simulatedRole);
		}
		return "admin";
	}

	/**
	 * Queries cms_users from SQL Server database with role metadata and assigned workspaces
	 */
	public array function getStoredUsers() {
		local.usersList = [];
		try {
			local.qUsers = queryExecute("
				SELECT u.id, u.role_id, u.role_code, u.username, u.email, u.first_name, u.last_name,
				       u.job_title, u.phone, u.department_code, u.department_name, u.assigned_workspaces,
				       u.status, u.two_factor_enabled, u.last_login_at, u.createdat, u.updatedat,
				       r.name AS role_name, r.badge_class AS role_badge, r.color_hex AS role_color, r.icon_name AS role_icon
				FROM cms_users u
				LEFT JOIN cms_roles r ON u.role_id = r.id
				WHERE u.deletedat IS NULL
				ORDER BY u.id DESC
			", {}, { datasource: getDb() });

			for (local.row in local.qUsers) {
				// Parse assigned workspaces
				local.wsList = [];
				local.rawWs = Trim(local.row.assigned_workspaces ?: "");
				if (Len(local.rawWs)) {
					if (IsJSON(local.rawWs)) {
						local.parsed = DeserializeJSON(local.rawWs);
						if (IsArray(local.parsed)) {
							local.wsList = local.parsed;
						}
					} else {
						local.wsList = ListToArray(local.rawWs);
					}
				}

				// If no assigned workspaces in JSON column, query cms_user_workspaces
				if (ArrayLen(local.wsList) == 0) {
					local.qWs = queryExecute("
						SELECT workspace_code FROM cms_user_workspaces WHERE user_id = :uid ORDER BY is_primary DESC, id ASC
					", { uid: { value: local.row.id, cfsqltype: "cf_sql_integer" } }, { datasource: getDb() });
					for (local.wsRow in local.qWs) {
						ArrayAppend(local.wsList, local.wsRow.workspace_code);
					}
				}

				// Fallback to department code or global
				if (ArrayLen(local.wsList) == 0) {
					local.wsList = [Len(local.row.department_code) ? local.row.department_code : "global"];
				}

				local.lastLoginStr = "Never";
				if (IsDate(local.row.last_login_at)) {
					local.lastLoginStr = DateFormat(local.row.last_login_at, "mmm d, yyyy") & " " & TimeFormat(local.row.last_login_at, "h:mm tt");
				}

				local.createdStr = DateFormat(Now(), "mmm d, yyyy");
				if (IsDate(local.row.createdat)) {
					local.createdStr = DateFormat(local.row.createdat, "mmm d, yyyy");
				}

				ArrayAppend(local.usersList, {
					id: local.row.id,
					role_id: local.row.role_id,
					role_code: local.row.role_code,
					role_name: Len(local.row.role_name) ? local.row.role_name : "Author",
					role_badge: Len(local.row.role_badge) ? local.row.role_badge : "badge-primary",
					role_color: Len(local.row.role_color) ? local.row.role_color : "##0073aa",
					role_icon: Len(local.row.role_icon) ? local.row.role_icon : "edit",
					username: local.row.username,
					email: local.row.email,
					first_name: local.row.first_name,
					last_name: local.row.last_name,
					job_title: Len(local.row.job_title) ? local.row.job_title : "Web Contributor",
					phone: Len(local.row.phone) ? local.row.phone : "",
					department_code: Len(local.row.department_code) ? local.row.department_code : "global",
					department_name: Len(local.row.department_name) ? local.row.department_name : getDeptNameByCode(local.row.department_code ?: "global"),
					workspaces: local.wsList,
					status: Len(local.row.status) ? local.row.status : "active",
					two_factor_enabled: (local.row.two_factor_enabled == 1 || local.row.two_factor_enabled == true),
					last_login: local.lastLoginStr,
					last_login_at: local.row.last_login_at,
					created_at: local.createdStr,
					createdat: local.row.createdat
				});
			}
		} catch (any e) {
			writeLog(text="Users controller getStoredUsers() database error: #e.message# - #e.detail#", type="error", file="wheels");
		}

		application.cmsUsersList = local.usersList;
		return local.usersList;
	}

	private void function saveStoredUsers(required array users) {
		application.cmsUsersList = arguments.users;
	}

	private string function getDeptNameByCode(required string code) {
		local.ws = getWorkspacesList();
		for (local.w in local.ws) {
			if (local.w.code == arguments.code || local.w.id == arguments.code) return local.w.name;
		}
		return "All Workspaces (Global)";
	}

	private array function parseWorkspacesInput(required any rawInput, string defaultDept = "global") {
		local.result = [];
		if (IsArray(arguments.rawInput)) {
			for (local.item in arguments.rawInput) {
				local.trimmed = Trim(local.item);
				if (Len(local.trimmed) && !ArrayFindNoCase(local.result, local.trimmed)) {
					ArrayAppend(local.result, local.trimmed);
				}
			}
		} else if (IsSimpleValue(arguments.rawInput) && Len(Trim(arguments.rawInput))) {
			local.parts = ListToArray(Trim(arguments.rawInput));
			for (local.item in local.parts) {
				local.trimmed = Trim(local.item);
				if (Len(local.trimmed) && !ArrayFindNoCase(local.result, local.trimmed)) {
					ArrayAppend(local.result, local.trimmed);
				}
			}
		}

		if (ArrayLen(local.result) == 0) {
			ArrayAppend(local.result, arguments.defaultDept);
		}

		return local.result;
	}

	/**
	 * Queries roles from cms_roles table and calculates dynamic user count per role
	 */
	public array function getRolesList() {
		local.rolesList = [];
		try {
			local.qRoles = queryExecute("
				SELECT r.id, r.code, r.name, r.description, r.badge_class, r.color_hex, r.icon_name,
				       r.can_access_content, r.can_access_hrm, r.can_access_pio, r.can_access_admin,
				       COUNT(u.id) AS user_count
				FROM cms_roles r
				LEFT JOIN cms_users u ON u.role_id = r.id AND u.deletedat IS NULL
				GROUP BY r.id, r.code, r.name, r.description, r.badge_class, r.color_hex, r.icon_name,
				         r.can_access_content, r.can_access_hrm, r.can_access_pio, r.can_access_admin
				ORDER BY r.id ASC
			", {}, { datasource: getDb() });

			for (local.row in local.qRoles) {
				local.summary = "";
				local.scope = "";
				local.modules = [];

				switch (local.row.code) {
					case "admin":
						local.summary = "Everything";
						local.scope = "Full County-wide System Access";
						local.modules = ["Content Management", "HRM (Human Resources)", "PIO (Public Information)", "Administration & Settings"];
						break;
					case "pio":
						local.summary = "Content Management + PIO Group";
						local.scope = "Public Communications & Media Alerts";
						local.modules = ["Content Management", "PIO (Public Information)", "Articles & Posts"];
						break;
					case "hr":
						local.summary = "Content Management + HRM Group";
						local.scope = "Human Resources & Recruitment";
						local.modules = ["Content Management", "HRM (Human Resources)"];
						break;
					default:
						local.summary = "Content Management Only";
						local.scope = "General Web Update & Content Authoring";
						local.modules = ["Content Management"];
						break;
				}

				ArrayAppend(local.rolesList, {
					id: local.row.id,
					code: local.row.code,
					name: local.row.name,
					badgeClass: local.row.badge_class,
					colorHex: local.row.color_hex,
					icon: local.row.icon_name,
					summary: local.summary,
					scope: local.scope,
					description: local.row.description,
					modules: local.modules,
					userCount: Val(local.row.user_count),
					can_access_content: local.row.can_access_content,
					can_access_hrm: local.row.can_access_hrm,
					can_access_pio: local.row.can_access_pio,
					can_access_admin: local.row.can_access_admin
				});
			}
		} catch (any e) {
			writeLog(text="Users controller getRolesList() database error: #e.message#", type="error", file="wheels");
		}

		// Fallback if table was unpopulated
		if (ArrayLen(local.rolesList) == 0) {
			local.rolesList = [
				{ code: "admin", name: "Administrator", badgeClass: "badge-danger", colorHex: "##b91c1c", icon: "shield", summary: "Everything", scope: "Full County-wide System Access", description: "Administrator will have everything.", modules: ["Content Management", "HRM", "PIO", "Administration"], userCount: 0 },
				{ code: "pio", name: "PIO", badgeClass: "badge-info", colorHex: "##0284c7", icon: "megaphone", summary: "Content Management + PIO Group", scope: "Public Communications & Media Alerts", description: "PIO group access plus full Content Management.", modules: ["Content Management", "PIO"], userCount: 0 },
				{ code: "hr", name: "HR", badgeClass: "badge-purple", colorHex: "##7e22ce", icon: "briefcase", summary: "Content Management + HRM Group", scope: "Human Resources & Recruitment", description: "HRM group access plus full Content Management.", modules: ["Content Management", "HRM"], userCount: 0 },
				{ code: "author", name: "Author", badgeClass: "badge-primary", colorHex: "##0073aa", icon: "edit", summary: "Content Management Only", scope: "General Web Update & Content Authoring", description: "Author is general web update.", modules: ["Content Management"], userCount: 0 }
			];
		}

		return local.rolesList;
	}

	public array function getWorkspacesList() {
		return getMasterWorkspaces();
	}

	public array function getDepartmentsList() {
		return getMasterWorkspaces();
	}

	public array function getCapabilityMatrix() {
		return [
			{
				category: "Content Management Group",
				description: "General web authoring, page editing, media storage, and online form creation",
				items: [
					{
						feature: "Content Manager & Page Editor",
						detail: "Create, edit, publish, layout selection, and structure web pages",
						author: "Full Access",
						hr: "Full Access",
						pio: "Full Access",
						admin: "Full Access"
					},
					{
						feature: "Media Library & Asset Browser",
						detail: "Upload images, PDFs, edit WCAG alt text, organize workspace folders",
						author: "Full Access",
						hr: "Full Access",
						pio: "Full Access",
						admin: "Full Access"
					},
					{
						feature: "Form Builder Studio & Forms Directory",
						detail: "Drag-and-drop form canvas, field inspector, public embed generator",
						author: "Full Access",
						hr: "Full Access",
						pio: "Full Access",
						admin: "Full Access"
					},
					{
						feature: "Citizen Feedback & Form Submissions",
						detail: "Review public intake responses, citizen inquiries, and export CSV",
						author: "Assigned Workspaces",
						hr: "Full Access",
						pio: "Full Access",
						admin: "Full Access"
					}
				]
			},
			{
				category: "HRM Group (Human Resource Management)",
				description: "Recruitment, personnel onboarding, employee benefits, and policy archives",
				items: [
					{
						feature: "HRM Forms & Job Applications",
						detail: "Employment intake forms, confidential candidate submission logs",
						author: "No Access",
						hr: "Full Access",
						pio: "No Access",
						admin: "Full Access"
					},
					{
						feature: "Job Postings & Careers Studio",
						detail: "Publish and archive open county positions and qualification requirements",
						author: "No Access",
						hr: "Full Access",
						pio: "No Access",
						admin: "Full Access"
					},
					{
						feature: "Employee Onboarding Center",
						detail: "New hire checklists, benefits enrollment packets, and tax forms",
						author: "No Access",
						hr: "Full Access",
						pio: "No Access",
						admin: "Full Access"
					},
					{
						feature: "Personnel Policies & Union Documents",
						detail: "County handbook revisions, labor agreements, and compliance records",
						author: "No Access",
						hr: "Full Access",
						pio: "No Access",
						admin: "Full Access"
					}
				]
			},
			{
				category: "PIO Group (Public Information Office)",
				description: "Press releases, urgent county emergency alerts, public records, and articles",
				items: [
					{
						feature: "PIO Articles & Posts Manager",
						detail: "County-wide press releases, feature stories, categories, and tags",
						author: "No Access",
						hr: "No Access",
						pio: "Full Access",
						admin: "Full Access"
					},
					{
						feature: "Emergency & Weather Alerts",
						detail: "Immediate banner broadcasts on primary website and public subsites",
						author: "No Access",
						hr: "No Access",
						pio: "Full Access",
						admin: "Full Access"
					},
					{
						feature: "Press Releases & Media Relations",
						detail: "Official media kits, press contacts directory, and embargo manager",
						author: "No Access",
						hr: "No Access",
						pio: "Full Access",
						admin: "Full Access"
					},
					{
						feature: "Public Records Requests (PRR)",
						detail: "Citizen records requests, intake tracking, and compliance logs",
						author: "No Access",
						hr: "No Access",
						pio: "Full Access",
						admin: "Full Access"
					}
				]
			},
			{
				category: "Administration & System Security",
				description: "User provisioning, role assignments, global navigation menus, and system settings",
				items: [
					{
						feature: "Users & Roles Management",
						detail: "Create staff accounts, assign 4 usergroups, reset credentials, 2FA enforcement",
						author: "No Access",
						hr: "No Access",
						pio: "No Access",
						admin: "Full Access"
					},
					{
						feature: "Navigation Menu Manager",
						detail: "Global header and side menu hierarchical arrangement across workspaces",
						author: "No Access",
						hr: "No Access",
						pio: "No Access",
						admin: "Full Access"
					},
					{
						feature: "System & Reading Settings",
						detail: "SEO global parameters, security keys, media sizes, cache warmup",
						author: "No Access",
						hr: "No Access",
						pio: "No Access",
						admin: "Full Access"
					},
					{
						feature: "Audit & Security Logs",
						detail: "County-wide user activity logs, login telemetry, and change tracking",
						author: "No Access",
						hr: "No Access",
						pio: "No Access",
						admin: "Full Access"
					}
				]
			}
		];
	}

}
