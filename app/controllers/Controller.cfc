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
		filters(through="requireLogin");
	}

	// Sign-in screens, the health probe, public form submissions, and public job postings/applications stay open.
	private boolean function isPublicRequest() {
		local.ctrl = LCase(params.controller ?: "");
		local.act = LCase(params.action ?: "");
		if (local.ctrl == "sessions" || local.ctrl == "up") return true;
		if (local.ctrl == "forms" && (local.act == "submit" || local.act == "preview")) return true;
		if (local.ctrl == "jobs" && (local.act == "publiclist" || local.act == "publicview" || local.act == "apply" || local.act == "submitapplication")) return true;
		if (local.ctrl == "events" && (local.act == "exportics" || local.act == "ics")) return true;
		if (local.ctrl == "alerts" && (local.act == "apiactive" || local.act == "active")) return true;
		if (local.ctrl == "articles" && local.act == "api") return true;
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

}
