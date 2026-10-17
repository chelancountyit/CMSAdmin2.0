component extends="Controller" {

	function config() {
		super.config();
	}

	function index() {
		redirectTo(action="general");
	}

	/**
	 * General Settings
	 * County title, contact switchboard, address, timezone, and maintenance lock.
	 */
	function general() {
		variables.pageTitle = "General Settings";
		variables.settings = getSettingsMap("general");

		// Provide baseline fallbacks
		if (!structKeyExists(variables.settings, "site_title")) variables.settings.site_title = "Chelan County Washington";
		if (!structKeyExists(variables.settings, "site_tagline")) variables.settings.site_tagline = "Official County Government Administration & Public Services";
		if (!structKeyExists(variables.settings, "admin_email")) variables.settings.admin_email = "pio@chelancounty.gov";
		if (!structKeyExists(variables.settings, "county_phone")) variables.settings.county_phone = "(509) 667-6200";
		if (!structKeyExists(variables.settings, "county_address")) variables.settings.county_address = "400 Douglas Street, Suite 201, Wenatchee, WA 98801";
		if (!structKeyExists(variables.settings, "office_hours")) variables.settings.office_hours = "Monday - Friday, 8:00 AM - 5:00 PM PST";
		if (!structKeyExists(variables.settings, "timezone")) variables.settings.timezone = "America/Los_Angeles";
		if (!structKeyExists(variables.settings, "maintenance_mode")) variables.settings.maintenance_mode = "0";
		if (!structKeyExists(variables.settings, "maintenance_message")) variables.settings.maintenance_message = "Chelan County digital services are undergoing scheduled maintenance. Emergency services remain operational 24/7.";

		variables.timezones = [
			{ code: "America/Los_Angeles", label: "Pacific Time (US & Canada) - PST/PDT" },
			{ code: "America/Denver", label: "Mountain Time (US & Canada) - MST/MDT" },
			{ code: "America/Chicago", label: "Central Time (US & Canada) - CST/CDT" },
			{ code: "America/New_York", label: "Eastern Time (US & Canada) - EST/EDT" },
			{ code: "America/Anchorage", label: "Alaska Time - AKST/AKDT" },
			{ code: "Pacific/Honolulu", label: "Hawaii-Aleutian Time - HST" },
			{ code: "UTC", label: "Coordinated Universal Time (UTC)" }
		];
	}

	/**
	 * Save General Settings
	 */
	function saveGeneral() {
		var localData = {
			"site_title": trim(params.site_title ?: "Chelan County Washington"),
			"site_tagline": trim(params.site_tagline ?: ""),
			"admin_email": trim(params.admin_email ?: ""),
			"county_phone": trim(params.county_phone ?: ""),
			"county_address": trim(params.county_address ?: ""),
			"office_hours": trim(params.office_hours ?: ""),
			"timezone": trim(params.timezone ?: "America/Los_Angeles"),
			"maintenance_mode": (structKeyExists(params, "maintenance_mode") && (params.maintenance_mode == "1" || params.maintenance_mode == "true" || params.maintenance_mode == "on")) ? "1" : "0",
			"maintenance_message": trim(params.maintenance_message ?: "")
		};

		saveSettingsMap(localData, "general");
		flashInsert(success="General administrative settings saved successfully.");
		redirectTo(action="general");
	}

	/**
	 * Reading & Search Engine Optimization (SEO)
	 * Meta titles, descriptions, OpenGraph, GA4, GTM, robots.txt
	 */
	function seo() {
		variables.pageTitle = "Reading & SEO Settings";
		variables.settings = getSettingsMap("seo");

		if (!structKeyExists(variables.settings, "seo_meta_title_format")) variables.settings.seo_meta_title_format = "{page_title} | Chelan County, WA";
		if (!structKeyExists(variables.settings, "seo_default_meta_description")) variables.settings.seo_default_meta_description = "Official website of Chelan County, Washington. Access Board of County Commissioners hearings, public safety alerts, GIS mapping, property records, and county services.";
		if (!structKeyExists(variables.settings, "seo_default_og_image")) variables.settings.seo_default_og_image = "/images/picjumbo/saddlerock.jpg";
		if (!structKeyExists(variables.settings, "seo_twitter_handle")) variables.settings.seo_twitter_handle = "@ChelanCountyWA";
		if (!structKeyExists(variables.settings, "seo_ga_tracking_id")) variables.settings.seo_ga_tracking_id = "G-XXXXXXXXXX";
		if (!structKeyExists(variables.settings, "seo_gtm_container_id")) variables.settings.seo_gtm_container_id = "GTM-XXXXXXX";
		if (!structKeyExists(variables.settings, "seo_robots_txt")) variables.settings.seo_robots_txt = "User-agent: *" & chr(13) & chr(10) & "Disallow: /admin/" & chr(13) & chr(10) & "Disallow: /api/internal/" & chr(13) & chr(10) & "Allow: /" & chr(13) & chr(10) & chr(13) & chr(10) & "Sitemap: https://www.co.chelan.wa.us/sitemap.xml";
	}

	/**
	 * Save SEO Settings
	 */
	function saveSeo() {
		var localData = {
			"seo_meta_title_format": trim(params.seo_meta_title_format ?: "{page_title} | Chelan County, WA"),
			"seo_default_meta_description": trim(params.seo_default_meta_description ?: ""),
			"seo_default_og_image": trim(params.seo_default_og_image ?: ""),
			"seo_twitter_handle": trim(params.seo_twitter_handle ?: ""),
			"seo_ga_tracking_id": trim(params.seo_ga_tracking_id ?: ""),
			"seo_gtm_container_id": trim(params.seo_gtm_container_id ?: ""),
			"seo_robots_txt": trim(params.seo_robots_txt ?: "")
		};

		saveSettingsMap(localData, "seo");
		flashInsert(success="Search engine optimization and meta settings saved successfully.");
		redirectTo(action="seo");
	}

	/**
	 * Media Size Presets & Upload Constraints
	 * Width/height bounds, max upload MB, allowed extensions
	 */
	function media() {
		variables.pageTitle = "Media Size Settings";
		variables.settings = getSettingsMap("media");

		if (!structKeyExists(variables.settings, "media_thumb_width")) variables.settings.media_thumb_width = "150";
		if (!structKeyExists(variables.settings, "media_thumb_height")) variables.settings.media_thumb_height = "150";
		if (!structKeyExists(variables.settings, "media_medium_width")) variables.settings.media_medium_width = "600";
		if (!structKeyExists(variables.settings, "media_medium_height")) variables.settings.media_medium_height = "400";
		if (!structKeyExists(variables.settings, "media_large_width")) variables.settings.media_large_width = "1200";
		if (!structKeyExists(variables.settings, "media_large_height")) variables.settings.media_large_height = "800";
		if (!structKeyExists(variables.settings, "media_max_upload_mb")) variables.settings.media_max_upload_mb = "25";
		if (!structKeyExists(variables.settings, "media_allowed_extensions")) variables.settings.media_allowed_extensions = "jpg,jpeg,png,gif,webp,svg,pdf,doc,docx,xls,xlsx,csv";
	}

	/**
	 * Save Media Settings
	 */
	function saveMedia() {
		var localData = {
			"media_thumb_width": val(params.media_thumb_width ?: 150),
			"media_thumb_height": val(params.media_thumb_height ?: 150),
			"media_medium_width": val(params.media_medium_width ?: 600),
			"media_medium_height": val(params.media_medium_height ?: 400),
			"media_large_width": val(params.media_large_width ?: 1200),
			"media_large_height": val(params.media_large_height ?: 800),
			"media_max_upload_mb": val(params.media_max_upload_mb ?: 25),
			"media_allowed_extensions": trim(params.media_allowed_extensions ?: "jpg,jpeg,png,gif,webp,svg,pdf,doc,docx,xls,xlsx,csv")
		};

		if (val(localData["media_thumb_width"]) <= 0) localData["media_thumb_width"] = 150;
		if (val(localData["media_thumb_height"]) <= 0) localData["media_thumb_height"] = 150;
		if (val(localData["media_medium_width"]) <= 0) localData["media_medium_width"] = 600;
		if (val(localData["media_medium_height"]) <= 0) localData["media_medium_height"] = 400;
		if (val(localData["media_large_width"]) <= 0) localData["media_large_width"] = 1200;
		if (val(localData["media_large_height"]) <= 0) localData["media_large_height"] = 800;
		if (val(localData["media_max_upload_mb"]) <= 0) localData["media_max_upload_mb"] = 25;

		saveSettingsMap(localData, "media");
		flashInsert(success="Media size presets and upload limits updated successfully.");
		redirectTo(action="media");
	}

	/**
	 * System Diagnostics & Telemetry
	 * CFML Engine, JVM Memory, Disk Storage, SQL Server Latency, Host Info
	 */
	function system() {
		variables.pageTitle = "System Diagnostics & Telemetry";

		// JVM & Memory
		var jvmRuntime = createObject("java", "java.lang.Runtime").getRuntime();
		var maxMemBytes = jvmRuntime.maxMemory();
		var totalMemBytes = jvmRuntime.totalMemory();
		var freeMemBytes = jvmRuntime.freeMemory();
		var usedMemBytes = totalMemBytes - freeMemBytes;

		var maxMemMB = round(maxMemBytes / 1048576);
		var totalMemMB = round(totalMemBytes / 1048576);
		var freeMemMB = round(freeMemBytes / 1048576);
		var usedMemMB = round(usedMemBytes / 1048576);
		var memPercent = (maxMemMB > 0) ? round((usedMemMB / maxMemMB) * 100) : 0;

		var javaSys = createObject("java", "java.lang.System");
		var javaVersion = javaSys.getProperty("java.version");
		var javaVendor = javaSys.getProperty("java.vendor");
		var javaVmName = javaSys.getProperty("java.vm.name");

		// Disk Space for Webroot
		var webrootFile = createObject("java", "java.io.File").init(expandPath("/"));
		var diskTotalBytes = webrootFile.getTotalSpace();
		var diskFreeBytes = webrootFile.getFreeSpace();
		var diskUsableBytes = webrootFile.getUsableSpace();
		var diskUsedBytes = diskTotalBytes - diskFreeBytes;

		var diskTotalGB = round((diskTotalBytes / 1073741824) * 10) / 10;
		var diskFreeGB = round((diskFreeBytes / 1073741824) * 10) / 10;
		var diskUsableGB = round((diskUsableBytes / 1073741824) * 10) / 10;
		var diskUsedGB = round((diskUsedBytes / 1073741824) * 10) / 10;
		var diskPercent = (diskTotalGB > 0) ? round((diskUsedGB / diskTotalGB) * 100) : 0;

		// Host & OS
		var hostName = "localhost";
		try {
			hostName = createObject("java", "java.net.InetAddress").getLocalHost().getHostName();
		} catch (any e) {}

		// Database Connection & Latency Test
		var dbStatus = {
			"connected": false,
			"latencyMs": 0,
			"sqlVersion": "Unknown",
			"dbName": "ChelanCountyWebsite",
			"tableCount": 0,
			"serverTime": "",
			"errorMessage": ""
		};

		try {
			var tStart = getTickCount();
			var qDb = queryExecute("
				SELECT @@VERSION AS sql_version,
				       DB_NAME() AS current_db,
				       CONVERT(VARCHAR(30), GETDATE(), 120) AS server_time,
				       (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo')) AS table_count
			", {}, { datasource: "ChelanCountyWebsite" });
			dbStatus.latencyMs = getTickCount() - tStart;
			dbStatus.connected = true;
			if (qDb.recordCount > 0) {
				dbStatus.sqlVersion = qDb.sql_version;
				dbStatus.dbName = qDb.current_db;
				dbStatus.tableCount = qDb.table_count;
				dbStatus.serverTime = qDb.server_time;
			}
		} catch (any ex) {
			dbStatus.connected = false;
			dbStatus.errorMessage = ex.message;
		}

		// Application Uptime
		var uptimeFormatted = "Unavailable";
		try {
			var runtimeMx = createObject("java", "java.lang.management.ManagementFactory").getRuntimeMXBean();
			var uptimeMs = runtimeMx.getUptime();
			var uptimeSec = int(uptimeMs / 1000);
			var uptimeDays = int(uptimeSec / 86400);
			var uptimeHours = int((uptimeSec % 86400) / 3600);
			var uptimeMins = int((uptimeSec % 3600) / 60);
			uptimeFormatted = uptimeDays & "d " & uptimeHours & "h " & uptimeMins & "m";
		} catch (any e) {}

		// CFWheels framework info
		var wheelsVersion = "4.1.2";
		try {
			if (isDefined("get") && isCustomFunction(get)) {
				wheelsVersion = get("version");
			}
		} catch (any e) {}

		var wheelsEnv = "production";
		try {
			if (isDefined("get") && isCustomFunction(get)) {
				wheelsEnv = get("environment");
			}
		} catch (any e) {}

		variables.diagnostics = {
			"server": {
				"engine": server.coldfusion.productname ?: "ColdFusion",
				"version": server.coldfusion.productversion ?: "Unknown",
				"level": structKeyExists(server.coldfusion, "productlevel") ? server.coldfusion.productlevel : "Standard",
				"uptime": uptimeFormatted,
				"wheelsVersion": wheelsVersion,
				"wheelsEnv": wheelsEnv,
				"webroot": expandPath("/")
			},
			"os": {
				"name": server.os.name ?: "Windows",
				"version": server.os.version ?: "",
				"arch": server.os.arch ?: "amd64",
				"host": hostName
			},
			"jvm": {
				"version": javaVersion,
				"vendor": javaVendor,
				"vmName": javaVmName,
				"maxMB": maxMemMB,
				"totalMB": totalMemMB,
				"usedMB": usedMemMB,
				"freeMB": freeMemMB,
				"percent": memPercent
			},
			"disk": {
				"path": webrootFile.getAbsolutePath(),
				"totalGB": diskTotalGB,
				"usedGB": diskUsedGB,
				"freeGB": diskFreeGB,
				"usableGB": diskUsableGB,
				"percent": diskPercent
			},
			"db": dbStatus,
			"scheduler": getScheduledPublishingSummary()
		};
	}

	/**
	 * Startup & Front-End Styles
	 */
	function startup() {
		pageTitle = "Startup & Front-End Styles (jbd-templates.css)";
		var cssPath = expandPath("/stylesheets/jbd-templates.css");
		jbdTemplateCssContent = "";
		if (fileExists(cssPath)) {
			jbdTemplateCssContent = fileRead(cssPath);
		}
	}

	// -------------------------------------------------------------------------
	// Private Helper Methods
	// -------------------------------------------------------------------------

	private struct function getSettingsMap(string group = "") {
		var sqlStr = "SELECT setting_key, setting_value, setting_group, description FROM cms_settings";
		var qParams = {};
		if (len(trim(arguments.group))) {
			sqlStr &= " WHERE setting_group = :group";
			qParams["group"] = { value: arguments.group, cfsqltype: "cf_sql_nvarchar" };
		}
		var q = queryExecute(sqlStr, qParams, { datasource: "ChelanCountyWebsite" });
		var resultMap = {};
		for (var row in q) {
			resultMap[row.setting_key] = isNull(row.setting_value) ? "" : row.setting_value;
		}
		return resultMap;
	}

	private void function saveSettingsMap(required struct keys, required string group) {
		for (var k in arguments.keys) {
			var v = arguments.keys[k];
			queryExecute("
				IF EXISTS (SELECT 1 FROM cms_settings WHERE setting_key = :k)
				BEGIN
					UPDATE cms_settings
					SET setting_value = :v, updatedat = SYSUTCDATETIME()
					WHERE setting_key = :k
				END
				ELSE
				BEGIN
					INSERT INTO cms_settings (setting_key, setting_value, setting_group, description, createdat, updatedat)
					VALUES (:k, :v, :g, '', SYSUTCDATETIME(), SYSUTCDATETIME())
				END
			", {
				k: { value: k, cfsqltype: "cf_sql_nvarchar" },
				v: { value: v, cfsqltype: "cf_sql_nvarchar" },
				g: { value: arguments.group, cfsqltype: "cf_sql_nvarchar" }
			}, { datasource: "ChelanCountyWebsite" });
		}
	}

}
