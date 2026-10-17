component output="false" {

	// ------------------------------------------------------------------
	// Isolated API application for File Explorer / Media Library
	// Prevents CFWheels framework from intercepting /api/ requests.
	// ------------------------------------------------------------------

	this.name               = "CMSAdminFileExplorer_" & hash(getCurrentTemplatePath());
	this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
	this.sessionManagement  = false;
	this.setClientCookies   = false;

	// Keep struct-key case in JSON (Adobe CF upper-cases unquoted keys otherwise)
	this.serialization.preserveCaseForStructKey = true;
	this.serialization.preserveCaseForQueryColumn = true;
	this.secureJSON = false;

	public boolean function onApplicationStart() {
		loadConfig();
		return true;
	}

	public boolean function onRequestStart(required string targetPage) {
		if (structKeyExists(url, "reinit") && url.reinit == "1") {
			loadConfig();
		}
		if (!structKeyExists(application, "fx")) {
			loadConfig();
		}
		return true;
	}

	public void function onError(any exception, string eventName = "") {
		try {
			writeLog(file = "filexplorer", type = "error",
				text = (structKeyExists(arguments.exception, "message") ? arguments.exception.message : "Unknown error")
					& " | " & (structKeyExists(arguments.exception, "detail") ? arguments.exception.detail : ""));
		} catch (any e) {}

		try {
			getPageContext().getResponse().setStatus(200);
			getPageContext().getResponse().setContentType("application/json; charset=utf-8");
			var errMsg = structKeyExists(arguments.exception, "message") ? arguments.exception.message : "An unexpected server error occurred.";
			writeOutput(serializeJSON({ "ok": false, "error": errMsg }));
		} catch (any e) {}
	}

	private void function loadConfig() {
		var cfg = {
			filesRoot   : "C:\inetpub\chelan-county\files\",
			webBase     : "/files/",
			serverName  : "WEB-01",
			systemDepth : 2,
			maxNameLen  : 64,
			allowedIPs  : "*"
		};
		cfg.filesRoot = replace(cfg.filesRoot, "/", "\", "all");
		if (right(cfg.filesRoot, 1) != "\") cfg.filesRoot &= "\";
		if (right(cfg.webBase, 1) != "/") cfg.webBase &= "/";
		application.fx = cfg;
	}
}
