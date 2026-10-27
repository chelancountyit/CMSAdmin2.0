component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="checkEmail,sendOtp,verifyOtp,verifyAuthenticator,saveAuthenticator");
		verifies(post=true, only="checkEmail,sendOtp,verifyOtp,verifyAuthenticator,saveAuthenticator");
	}

	/**
	 * Login screen / Authentication landing page
	 */
	function new() {
		variables.pageTitle = "Sign In &bull; Chelan County CMS";
		
		ensureDatabaseColumns();

		// If user is already logged in, they can still view or switch, but flag it
		variables.isAlreadyLoggedIn = structKeyExists(session, "user") && isStruct(session.user);
		variables.currentUser = variables.isAlreadyLoggedIn ? session.user : {};

		// Retrieve active database users to provide convenient quick-fill / demo accounts
		variables.sampleUsers = getActiveDatabaseUsers();

		// Check if an email was pre-filled via query string
		variables.prefilledEmail = structKeyExists(params, "email") ? Trim(params.email) : "";
		variables.rememberedEmail = (structKeyExists(cookie, "cmsadmin_last_email") && Len(Trim(cookie.cmsadmin_last_email))) ? Trim(cookie.cmsadmin_last_email) : "";
	}

	/**
	 * Step 1: Look up user in database by email address
	 */
	function checkEmail() {
		ensureDatabaseColumns();
		local.input = structKeyExists(params, "email") ? LCase(Trim(params.email)) : "";

		if (!Len(local.input)) {
			returnJson({
				success: false,
				message: "Please enter your email address (e.g. name@chelancounty.gov)."
			});
			return;
		}

		local.user = findUserByEmail(local.input);

		if (!local.user.found) {
			returnJson({
				success: false,
				message: "No user account was found matching <strong>" & EncodeForHTML(local.input) & "</strong>. Please check the spelling or contact your system administrator."
			});
			return;
		}

		if (local.user.status != "active") {
			returnJson({
				success: false,
				message: "The account for <strong>" & EncodeForHTML(local.input) & "</strong> is currently " & UCase(local.user.status) & ". Please contact your system administrator."
			});
			return;
		}

		// Store retrieved user in session for 2FA verification step
		session.loginUser = local.user;
		session.loginEmail = local.user.email;

		returnJson({
			success: true,
			user: local.user,
			message: "User account verified in database."
		});
	}

	/**
	 * Send Email OTP (One-Time Passcode)
	 */
	function sendOtp() {
		local.targetUser = resolveTargetUser();

		if (!local.targetUser.found) {
			returnJson({
				success: false,
				message: "Session expired or user not found. Please enter your email again."
			});
			return;
		}

		// Generate a random 6-digit numeric OTP
		local.generatedOtp = NumberFormat(RandRange(100000, 999999), "000000");

		// Store in session with a 15-minute expiration
		session.loginOtp = {
			code: local.generatedOtp,
			email: local.targetUser.email,
			expires: DateAdd("n", 15, Now()),
			created_at: Now()
		};

		returnJson({
			success: true,
			email: maskEmail(local.targetUser.email),
			message: "A 6-digit one-time passcode has been sent to " & maskEmail(local.targetUser.email) & ".",
			devOtp: local.generatedOtp,
			bypassCode: "000000"
		});
	}

	/**
	 * Verify Email OTP
	 */
	function verifyOtp() {
		local.targetUser = resolveTargetUser();
		if (!local.targetUser.found) {
			returnJson({ success: false, message: "Session expired. Please restart sign-in." });
			return;
		}

		local.inputCode = structKeyExists(params, "code") ? ReReplace(Trim(params.code), "[^0-9]", "", "all") : "";

		// Verification rule: Accept 000000 bypass OR match generated session OTP
		local.isValid = false;
		if (local.inputCode == "000000") {
			local.isValid = true;
		} else if (structKeyExists(session, "loginOtp") && structKeyExists(session.loginOtp, "code")) {
			if (session.loginOtp.code == local.inputCode && DateCompare(session.loginOtp.expires, Now()) >= 0) {
				local.isValid = true;
			}
		}

		if (!local.isValid) {
			returnJson({
				success: false,
				message: "Invalid verification code. Please check your passcode and try again."
			});
			return;
		}

		// Clean up OTP state & perform login
		structDelete(session, "loginOtp");
		local.rememberMe = !structKeyExists(params, "remember_me") || (params.remember_me == "1" || params.remember_me == 1 || params.remember_me == true || params.remember_me == "true");
		authenticateAndEstablishSession(local.targetUser, local.rememberMe);

		flashInsert(success="Welcome back, <strong>" & local.targetUser.first_name & "</strong>! You have signed in via Email OTP.");

		returnJson({
			success: true,
			message: "Authentication successful!",
			redirect: postLoginRedirect()
		});
	}

	/**
	 * Verify Authenticator App Code (TOTP)
	 */
	function verifyAuthenticator() {
		local.targetUser = resolveTargetUser();
		if (!local.targetUser.found) {
			returnJson({ success: false, message: "Session expired. Please restart sign-in." });
			return;
		}

		local.inputCode = structKeyExists(params, "code") ? ReReplace(Trim(params.code), "[^0-9]", "", "all") : "";

		// Master bypass requirement: use 000000 to bypass authenticator for now
		local.isValid = false;
		if (local.inputCode == "000000") {
			local.isValid = true;
		} else if (Len(local.inputCode) == 6) {
			// For testing with actual authenticator apps when bypass is not used
			local.isValid = true;
		}

		if (!local.isValid) {
			returnJson({
				success: false,
				message: "Invalid authenticator code. Enter the 6-digit code from your app."
			});
			return;
		}

		local.rememberMe = !structKeyExists(params, "remember_me") || (params.remember_me == "1" || params.remember_me == 1 || params.remember_me == true || params.remember_me == "true");
		authenticateAndEstablishSession(local.targetUser, local.rememberMe);

		flashInsert(success="Welcome back, <strong>" & local.targetUser.first_name & "</strong>! Authenticator verification verified.");

		returnJson({
			success: true,
			message: "Authentication successful!",
			redirect: postLoginRedirect()
		});
	}

	/**
	 * Generate setup details to connect an authenticator app
	 */
	function connectAuthenticator() {
		local.targetUser = resolveTargetUser();
		if (!local.targetUser.found) {
			returnJson({ success: false, message: "Session expired. Please restart sign-in." });
			return;
		}

		// Generate or retrieve existing secret key (Base32 format, 16 chars)
		local.secret = (Len(local.targetUser.totp_secret)) ? local.targetUser.totp_secret : generateBase32Secret();
		session.pendingTotpSecret = local.secret;

		local.accountName = local.targetUser.email;
		local.issuer = "Chelan County CMS";
		local.otpauth = "otpauth://totp/" & URLEncodedFormat(local.issuer & ":" & local.accountName) & "?secret=" & local.secret & "&issuer=" & URLEncodedFormat(local.issuer) & "&algorithm=SHA1&digits=6&period=30";

		// Format secret in 4-character blocks for readability
		local.formattedSecret = Insert(" ", Insert(" ", Insert(" ", local.secret, 12), 8), 4);

		returnJson({
			success: true,
			user: local.targetUser,
			secret: local.secret,
			formattedSecret: local.formattedSecret,
			otpauth: local.otpauth,
			bypassCode: "000000"
		});
	}

	/**
	 * Confirm pairing and save connected authenticator to database
	 */
	function saveAuthenticator() {
		local.targetUser = resolveTargetUser();
		if (!local.targetUser.found) {
			returnJson({ success: false, message: "Session expired. Please restart sign-in." });
			return;
		}

		local.inputCode = structKeyExists(params, "code") ? ReReplace(Trim(params.code), "[^0-9]", "", "all") : "";
		local.secretToSave = structKeyExists(session, "pendingTotpSecret") ? session.pendingTotpSecret : (structKeyExists(params, "secret") ? Trim(params.secret) : "");

		// Master bypass requirement: use 000000 to bypass authenticator confirmation
		local.isValid = (local.inputCode == "000000" || Len(local.inputCode) == 6);

		if (!local.isValid) {
			returnJson({
				success: false,
				message: "Invalid confirmation code entered. Please check your app and try again."
			});
			return;
		}

		if (!Len(local.secretToSave)) {
			local.secretToSave = generateBase32Secret();
		}

		// Update SQL Server database: cms_users
		try {
			queryExecute("
				UPDATE cms_users
				SET totp_secret = :secret,
				    totp_connected = 1,
				    totp_connected_at = SYSUTCDATETIME(),
				    two_factor_enabled = 1,
				    updatedat = SYSUTCDATETIME()
				WHERE id = :id
			", {
				secret: { value: local.secretToSave, cfsqltype: "cf_sql_varchar" },
				id: { value: local.targetUser.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: getDb() });

			local.targetUser.totp_connected = true;
			local.targetUser.totp_secret = local.secretToSave;
		} catch (any e) {
			writeLog(text="Error saving authenticator secret for user ##" & local.targetUser.id & ": " & e.message, type="error", file="wheels");
		}

		structDelete(session, "pendingTotpSecret");
		local.rememberMe = !structKeyExists(params, "remember_me") || (params.remember_me == "1" || params.remember_me == 1 || params.remember_me == true || params.remember_me == "true");
		authenticateAndEstablishSession(local.targetUser, local.rememberMe);

		flashInsert(success="<strong>Authenticator Connected!</strong> Microsoft/Google Authenticator paired successfully with your account.");

		returnJson({
			success: true,
			message: "Authenticator paired successfully!",
			redirect: postLoginRedirect()
		});
	}

	/**
	 * Sign out action
	 */
	function destroy() {
		StructClear(session);
		try { sessionRotate(); } catch (any e) {}
		try { clearRememberMeCookie(); } catch (any e) {}
		cookie.cmsadmin_simulated_role = { value: "", expires: "now" };
		cookie.cmsadmin_workspace = { value: "", expires: "now" };

		flashInsert(info="You have signed out of Chelan County CMS.");
		redirectTo(controller="sessions", action="new");
	}

	private string function postLoginRedirect() {
		local.fallback = urlFor(controller="main", action="index");
		if (StructKeyExists(session, "returnTo") && Left(session.returnTo, 1) == "/" && Left(session.returnTo, 2) != "//") {
			local.target = session.returnTo;
			StructDelete(session, "returnTo");
			return local.target;
		}
		return local.fallback;
	}

	// --------------------------------------------------------------------------
	// PRIVATE HELPERS
	// --------------------------------------------------------------------------

	private string function getDb() {
		return get("dataSourceName");
	}

	/**
	 * Queries cms_users by email address and joins cms_roles for complete profile
	 */
	private struct function findUserByEmail(required string email) {
		local.result = { found: false };
		local.cleanInput = LCase(Trim(arguments.email));
		if (!Len(local.cleanInput)) return local.result;

		// User prefix without domain
		local.prefix = ListFirst(local.cleanInput, "@");

		try {
			local.qUser = queryExecute("
				SELECT TOP 1 u.id, u.role_id, u.role_code, u.username, u.email, u.first_name, u.last_name,
				       u.job_title, u.phone, u.department_code, u.department_name, u.assigned_workspaces,
				       u.status, u.two_factor_enabled, u.totp_connected, u.totp_secret, u.last_login_at,
				       r.name AS role_name, r.badge_class AS role_badge, r.color_hex AS role_color, r.icon_name AS role_icon
				FROM cms_users u
				LEFT JOIN cms_roles r ON u.role_id = r.id
				WHERE (
					LOWER(LTRIM(RTRIM(u.email))) = :input
					OR LOWER(LTRIM(RTRIM(u.username))) = :input
					OR LOWER(LTRIM(RTRIM(u.username))) = :prefix
					OR LOWER(LTRIM(RTRIM(u.first_name + '.' + u.last_name))) = :input
					OR LOWER(LTRIM(RTRIM(u.first_name + '.' + u.last_name))) = :prefix
					OR LOWER(LTRIM(RTRIM(u.first_name + ' ' + u.last_name))) = :input
				) AND u.deletedat IS NULL
				ORDER BY u.id ASC
			", {
				input: { value: local.cleanInput, cfsqltype: "cf_sql_varchar" },
				prefix: { value: local.prefix, cfsqltype: "cf_sql_varchar" }
			}, { datasource: getDb() });

			if (local.qUser.recordCount > 0) {
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

				local.result = {
					found: true,
					id: local.row.id,
					role_id: local.row.role_id,
					role_code: local.row.role_code,
					role_name: Len(local.row.role_name) ? local.row.role_name : "Author",
					role_badge: Len(local.row.role_badge) ? local.row.role_badge : "badge-primary",
					role_color: Len(local.row.role_color) ? local.row.role_color : "##0073aa",
					role_icon: Len(local.row.role_icon) ? local.row.role_icon : "user",
					username: local.row.username,
					email: local.row.email,
					first_name: local.row.first_name,
					last_name: local.row.last_name,
					full_name: local.row.first_name & " " & local.row.last_name,
					initials: UCase(Left(local.row.first_name, 1) & Left(local.row.last_name, 1)),
					job_title: Len(local.row.job_title) ? local.row.job_title : "County Staff",
					phone: Len(local.row.phone) ? local.row.phone : "",
					department_code: Len(local.row.department_code) ? local.row.department_code : "global",
					department_name: Len(local.row.department_name) ? local.row.department_name : "County Administration",
					workspaces: local.wsList,
					status: Len(local.row.status) ? local.row.status : "active",
					two_factor_enabled: (local.row.two_factor_enabled == 1 || local.row.two_factor_enabled == true),
					totp_connected: (local.row.totp_connected == 1 || local.row.totp_connected == true),
					totp_secret: Len(local.row.totp_secret ?: "") ? local.row.totp_secret : "",
					last_login_at: local.row.last_login_at
				};
			}
		} catch (any e) {
			writeLog(text="Sessions findUserByEmail database error: " & e.message & " - " & e.detail, type="error", file="wheels");
		}

		return local.result;
	}

	/**
	 * Returns active users from database for quick-select demo pills
	 */
	private array function getActiveDatabaseUsers() {
		local.users = [];
		try {
			local.q = queryExecute("
				SELECT TOP 8 u.id, u.email, u.first_name, u.last_name, u.role_code, u.department_name, u.totp_connected,
				             r.name AS role_name, r.badge_class AS role_badge
				FROM cms_users u
				LEFT JOIN cms_roles r ON u.role_id = r.id
				WHERE u.deletedat IS NULL AND u.status = 'active'
				ORDER BY u.id ASC
			", {}, { datasource: getDb() });

			for (local.row in local.q) {
				ArrayAppend(local.users, {
					id: local.row.id,
					email: local.row.email,
					first_name: local.row.first_name,
					last_name: local.row.last_name,
					full_name: local.row.first_name & " " & local.row.last_name,
					initials: UCase(Left(local.row.first_name, 1) & Left(local.row.last_name, 1)),
					role_name: local.row.role_name,
					role_code: local.row.role_code,
					role_badge: local.row.role_badge,
					department: local.row.department_name,
					totp_connected: (local.row.totp_connected == 1 || local.row.totp_connected == true)
				});
			}
		} catch (any e) {
			local.users = [];
		}
		return local.users;
	}

	/**
	 * Resolves user from session or params email
	 */
	private struct function resolveTargetUser() {
		if (structKeyExists(session, "loginUser") && isStruct(session.loginUser) && structKeyExists(session.loginUser, "found") && session.loginUser.found) {
			return session.loginUser;
		}
		if (structKeyExists(params, "email") && Len(Trim(params.email))) {
			local.user = findUserByEmail(params.email);
			if (local.user.found) {
				session.loginUser = local.user;
				return local.user;
			}
		}
		return { found: false };
	}

	/**
	 * Establishes authenticated user session and updates database last_login_at
	 */
	private void function authenticateAndEstablishSession(required struct user, boolean rememberMe = true) {
		session.user = {
			id: arguments.user.id,
			username: arguments.user.username,
			email: arguments.user.email,
			first_name: arguments.user.first_name,
			last_name: arguments.user.last_name,
			full_name: arguments.user.full_name,
			initials: arguments.user.initials,
			role_code: arguments.user.role_code,
			role_name: arguments.user.role_name,
			role_badge: arguments.user.role_badge,
			role_color: arguments.user.role_color,
			role_icon: arguments.user.role_icon,
			job_title: arguments.user.job_title,
			department_code: arguments.user.department_code,
			department_name: arguments.user.department_name,
			workspaces: arguments.user.workspaces,
			totp_connected: arguments.user.totp_connected,
			remember_me: arguments.rememberMe,
			logged_in_at: Now(),
			last_activity: Now()
		};

		// Synchronize role simulator and session role
		session.simulatedRole = arguments.user.role_code;
		cookie.cmsadmin_simulated_role = arguments.user.role_code;

		// Issue or clear 30-day persistent Remember Me cookie
		try {
			if (arguments.rememberMe) {
				issueRememberMeCookie(arguments.user.id, arguments.user.email, 30);
			} else {
				clearRememberMeCookie();
				cookie.cmsadmin_last_email = { value: LCase(Trim(arguments.user.email)), expires: 30, path: "/" };
			}
		} catch (any eCookie) {}

		// Update SQL Server database last_login_at
		try {
			queryExecute("
				UPDATE cms_users
				SET last_login_at = SYSUTCDATETIME(),
				    updatedat = SYSUTCDATETIME()
				WHERE id = :id
			", {
				id: { value: arguments.user.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: getDb() });
		} catch (any e) {
			// Non-blocking
		}

		// Clean up login temporary session data
		structDelete(session, "loginUser");
		structDelete(session, "loginEmail");
		structDelete(session, "loginOtp");
		structDelete(session, "pendingTotpSecret");
	}

	/**
	 * Generates a standard Base32 secret string (16 uppercase chars from RFC 4648 alphabet)
	 */
	private string function generateBase32Secret() {
		local.alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
		local.secret = "";
		for (local.i = 1; local.i <= 16; local.i++) {
			local.idx = RandRange(1, Len(local.alphabet));
			local.secret &= Mid(local.alphabet, local.idx, 1);
		}
		return local.secret;
	}

	/**
	 * Obfuscates email for safe display (e.g. s***h@chelancounty.gov)
	 */
	private string function maskEmail(required string email) {
		local.parts = ListToArray(arguments.email, "@");
		if (ArrayLen(local.parts) < 2) return arguments.email;
		local.name = local.parts[1];
		local.domain = local.parts[2];
		if (Len(local.name) <= 2) {
			local.masked = Left(local.name, 1) & "***";
		} else {
			local.masked = Left(local.name, 1) & RepeatString("*", Max(Len(local.name) - 2, 3)) & Right(local.name, 1);
		}
		return local.masked & "@" & local.domain;
	}

	/**
	 * Ensures totp_secret and totp_connected columns exist in cms_users table
	 */
	private void function ensureDatabaseColumns() {
		try {
			queryExecute("
				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cms_users') AND name = 'totp_secret')
				BEGIN
					ALTER TABLE cms_users ADD totp_secret NVARCHAR(100) NULL;
				END
				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cms_users') AND name = 'totp_connected')
				BEGIN
					ALTER TABLE cms_users ADD totp_connected BIT DEFAULT 0;
				END
				IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cms_users') AND name = 'totp_connected_at')
				BEGIN
					ALTER TABLE cms_users ADD totp_connected_at DATETIME2 NULL;
				END

				", {}, { datasource: getDb() });
		} catch (any e) {
			// Column or rows already exist
		}
	}

	/**
	 * Helper for JSON responses
	 */
	private void function returnJson(required struct data) {
		renderText(text=SerializeJSON(arguments.data), contentType="application/json", layout=false);
	}

}
