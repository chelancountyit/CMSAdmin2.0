/**
 * This is the parent controller file that all your controllers should extend.
 * You can add functions to this file to make them available in all your controllers.
 * Do not delete this file.
 *
 * NOTE: When extending this controller and implementing `config()` in the child controller, don't forget to call this
 * base controller's `config()` via `super.config()`, or else the call to `protectsFromForgery` below will be skipped.
 *
 * Example controller extending this one:
 *
 * component extends="Controller" {
 *   function config() {
 *     // Call parent config method
 *     super.config();
 *
 *     // Your own config code here.
 *     // ...
 *   }
 * }
 */
component extends="wheels.Controller" {

	function config() {
		protectsFromForgery();
		filters(through="requireLogin,enforceWorkspaceSelection");
	}

	// Sign-in screens, the health probe, public form submissions, and public job postings/applications stay open.
	private boolean function isPublicRequest() {
		local.ctrl = LCase(params.controller ?: "");
		local.act = LCase(params.action ?: "");
		if (local.ctrl == "sessions" || local.ctrl == "up") return true;
		if (local.ctrl == "forms" && (local.act == "submit" || local.act == "preview")) return true;
		if (local.ctrl == "jobs" && (local.act == "publiclist" || local.act == "publicview" || local.act == "apply" || local.act == "submitapplication")) return true;
		if (local.ctrl == "rfps" && (local.act == "publiclist" || local.act == "publicview" || local.act == "registerplanholder")) return true;
		if (local.ctrl == "events" && (local.act == "exportics" || local.act == "ics")) return true;
		if (local.ctrl == "alerts" && (local.act == "apiactive" || local.act == "active")) return true;
		if (local.ctrl == "articles" && local.act == "api") return true;
		if (local.ctrl == "scheduler" && (local.act == "apirun" || local.act == "apistatus")) return true;
		if (listFindNoCase("pressreleases,press-releases", local.ctrl) && (local.act == "api" || local.act == "view")) return true;
		return false;
	}

	private boolean function isAjaxRequest() {
		local.requestedWith = cgi.http_x_requested_with ?: "";
		local.accept = cgi.http_accept ?: "";
		return local.requestedWith == "XMLHttpRequest"
			|| (FindNoCase("application/json", local.accept) && !FindNoCase("text/html", local.accept))
			|| (cgi.request_method == "POST" && FindNoCase("application/json", cgi.content_type ?: ""));
	}

	private void function requireLogin() {
		if (isPublicRequest()) return;

		local.idleLimitMinutes = 30;
		local.signedIn = StructKeyExists(session, "user") && IsStruct(session.user) && StructKeyExists(session.user, "id");
		local.expired = false;

		if (local.signedIn) {
			local.lastSeen = session.user.last_activity ?: (session.user.logged_in_at ?: Now());
			if (IsDate(local.lastSeen) && DateDiff("n", local.lastSeen, Now()) >= local.idleLimitMinutes) {
				StructClear(session);
				local.signedIn = false;
				local.expired = true;
			} else {
				session.user.last_activity = Now();
				return;
			}
		}

		if (isAjaxRequest()) {
			$header(statusCode=401, statusText="Unauthorized");
			renderText(
				text=SerializeJSON({ success: false, message: "Your session has expired. Please sign in again.", redirect: urlFor(controller="sessions", action="new") }),
				contentType="application/json",
				layout=false
			);
			return;
		}

		if (cgi.request_method == "GET") {
			session.returnTo = urlFor(controller=params.controller, action=params.action);
		}
		flashInsert(info=local.expired ? "Your session timed out. Please sign in again." : "Please sign in to continue.");
		redirectTo(controller="sessions", action="new");
	}

	/**
	 * Block creating or modifying any workspace-scoped content when no workspace is selected.
	 * Administrators retain full, unrestricted access to Administration (Workspaces, Users & Roles, Settings).
	 */
	private void function enforceWorkspaceSelection() {
		if (isPublicRequest()) return;

		local.ctrl = LCase(params.controller ?: "");
		local.act = LCase(params.action ?: "index");

		// Administration controllers (Workspaces, Users & Roles, Settings) and system/dashboard controllers do not require a selected workspace
		if (ListFindNoCase("workspaces,users,settings,sessions,main,documentation,up,scheduler", local.ctrl)) {
			return;
		}

		// Check if a valid non-global workspace is currently selected in the top header
		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");
		local.wsId = "";
		if (Len(local.reqWs) && local.reqWs != "global" && local.reqWs != "all") {
			local.wsObj = resolveUserActiveWorkspace(requestedWs=local.reqWs, role=getCurrentActiveRole());
			local.wsId = LCase(Trim(local.wsObj.id ?: ""));
			if (local.wsId == "global" || local.wsId == "all") local.wsId = "";
		}
		if (Len(local.wsId)) {
			return;
		}

		// No workspace is selected: block opening How Do I, Events / Calendar, and Emergency Alerts entirely,
		// and block all creation, upload, builder, and mutation actions across other content modules
		local.isWriteMethod = (UCase(cgi.request_method ?: "GET") != "GET");
		local.idVal = Val(params.id ?: 0);
		local.isBlockedModule = ListFindNoCase("events,alerts", local.ctrl) > 0
			|| (local.ctrl == "pages" && ListFindNoCase("howdoi,how-do-i", local.act) > 0);
		local.isBlockedAction = local.isBlockedModule
			|| local.isWriteMethod
			|| ListFindNoCase("new,create,save,upload,processupload,createmodal,saveitem,deleteitem,reorder,delete,destroy,duplicate,savehowdoi,deletehowdoi,createfolder,deletefile,renamefile,movefile,updatemeta", local.act) > 0
			|| Left(local.act, 6) == "create"
			|| Left(local.act, 4) == "save"
			|| Left(local.act, 6) == "delete"
			|| Left(local.act, 6) == "upload"
			|| ((local.act == "builder" || local.act == "edit") && local.idVal <= 0);

		if (!local.isBlockedAction) {
			return;
		}

		local.msg = local.isBlockedModule
			? "Workspace Required: Please select a workspace from the top header before opening this module."
			: "Workspace Required: Please select a workspace from the top header before creating or modifying content.";
		if (isAjaxRequest() || (StructKeyExists(params, "format") && LCase(params.format) == "json") || local.ctrl == "navigation") {
			$header(statusCode=422, statusText="Unprocessable Entity");
			renderText(
				text=SerializeJSON({ success: false, message: local.msg }),
				contentType="application/json",
				layout=false
			);
			return;
		}

		flashInsert(warning=local.msg);
		if (local.isBlockedModule) {
			redirectTo(controller="main", action="index");
		} else if (ListFindNoCase("pages,media,forms,rfps,jobs,pressreleases,press-releases,articles,navigation", local.ctrl)) {
			redirectTo(controller=params.controller, action="index");
		} else {
			redirectTo(controller="main", action="index");
		}
	}

}
