component extends="Controller" {

	function config() {
		super.config();
		filters(through="requireLogin", except="apiActive,active");
		protectsFromForgery(except="apiActive,active,save,toggle,delete");
	}

	/**
	 * Emergency Alerts Studio & Incident Dispatch Dashboard
	 */
	function index() {
		ensureEmergencyAlertsTable();
		variables.pageTitle = "Emergency Alerts & Incident Dispatch";

		local.role = getCurrentActiveRole();
		variables.activeRole = local.role;
		variables.isAdmin = (local.role == "admin");
		variables.isPIO = (local.role == "pio");

		// Resolve active workspace
		local.requestedWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		variables.activeWsObj = resolveUserActiveWorkspace(requestedWs = local.requestedWs, role = local.role);
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);

		// Query alerts from database
		variables.alerts = [];
		variables.stats = {
			total: 0,
			active: 0,
			critical: 0,
			warning: 0,
			info: 0
		};

		try {
			local.q = queryExecute("
				SELECT id, title, message, severity, incident_type, link_url, link_text,
				       is_active, is_dismissible, siteid, starts_at, expires_at,
				       created_by, modified_by, createdat, updatedat
				FROM emergency_alerts
				WHERE deletedat IS NULL
				ORDER BY is_active DESC, id DESC
			", {}, { datasource: "ChelanCountyWebsite" });

			variables.stats.total = local.q.recordCount;

			for (local.row in local.q) {
				local.isActive = (local.row.is_active == 1 || local.row.is_active == true);
				local.severity = LCase(Trim(local.row.severity ?: "danger"));

				if (local.isActive) {
					variables.stats.active++;
				}
				if (local.severity == "danger" || local.severity == "critical") {
					variables.stats.critical++;
				} else if (local.severity == "warning") {
					variables.stats.warning++;
				} else {
					variables.stats.info++;
				}

				ArrayAppend(variables.alerts, {
					id: local.row.id,
					title: local.row.title,
					message: local.row.message,
					severity: local.severity,
					incident_type: local.row.incident_type ?: "general",
					link_url: local.row.link_url ?: "",
					link_text: Len(Trim(local.row.link_text ?: "")) ? local.row.link_text : "View Incident Details",
					is_active: local.isActive,
					is_dismissible: (local.row.is_dismissible == 1 || local.row.is_dismissible == true),
					siteid: local.row.siteid ?: "global",
					starts_at: local.row.starts_at,
					expires_at: local.row.expires_at,
					created_by: local.row.created_by ?: "PIO Office",
					createdat: local.row.createdat,
					updatedat: local.row.updatedat
				});
			}
		} catch (any eQuery) {
			writeLog(type="error", file="alerts", text="Alerts query error: #eQuery.message# #eQuery.detail#");
		}

		// Predefined municipal incident presets for 1-click dispatch
		variables.presets = getIncidentPresets();
	}

	/**
	 * POST: Save (Insert or Update) Emergency Alert
	 */
	function save() {
		ensureEmergencyAlertsTable();
		local.body = readJsonOrParams();

		local.id = Val(local.body.id ?: 0);
		local.title = Left(Trim(local.body.title ?: ""), 255);
		local.message = Trim(local.body.message ?: "");
		local.severity = LCase(Trim(local.body.severity ?: "danger"));
		if (!ListFindNoCase("danger,warning,info,success", local.severity)) {
			local.severity = "danger";
		}
		local.incidentType = LCase(Trim(local.body.incident_type ?: "general"));
		local.linkUrl = Left(Trim(local.body.link_url ?: ""), 1000);
		local.linkText = Left(Trim(local.body.link_text ?: "View Incident Details"), 100);
		local.isActive = StructKeyExists(local.body, "is_active") ? parseBooleanVal(local.body.is_active) : (local.id <= 0);
		local.isDismissible = StructKeyExists(local.body, "is_dismissible") ? parseBooleanVal(local.body.is_dismissible) : true;
		local.siteId = LCase(Trim(local.body.siteid ?: "global"));
		if (!Len(local.siteId)) local.siteId = "global";

		// Optional schedule
		local.startsAt = (StructKeyExists(local.body, "starts_at") && IsDate(local.body.starts_at)) ? local.body.starts_at : "";
		local.expiresAt = (StructKeyExists(local.body, "expires_at") && IsDate(local.body.expires_at)) ? local.body.expires_at : "";

		local.actor = resolveCurrentActor();

		if (!Len(local.title)) {
			renderJsonEnvelope(false, "Incident headline/title is required.");
			return;
		}
		if (!Len(local.message)) {
			renderJsonEnvelope(false, "Incident advisory message body is required.");
			return;
		}

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					UPDATE emergency_alerts SET
						title = :title,
						message = :message,
						severity = :severity,
						incident_type = :incident_type,
						link_url = :link_url,
						link_text = :link_text,
						is_active = :is_active,
						is_dismissible = :is_dismissible,
						siteid = :siteid,
						starts_at = :starts_at,
						expires_at = :expires_at,
						modified_by = :actor,
						updatedat = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					message: { value: local.message, cfsqltype: "cf_sql_nvarchar" },
					severity: { value: local.severity, cfsqltype: "cf_sql_varchar" },
					incident_type: { value: local.incidentType, cfsqltype: "cf_sql_varchar" },
					link_url: { value: local.linkUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.linkUrl) },
					link_text: { value: local.linkText, cfsqltype: "cf_sql_varchar" },
					is_active: { value: local.isActive ? 1 : 0, cfsqltype: "cf_sql_bit" },
					is_dismissible: { value: local.isDismissible ? 1 : 0, cfsqltype: "cf_sql_bit" },
					siteid: { value: local.siteId, cfsqltype: "cf_sql_varchar" },
					starts_at: { value: local.startsAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.startsAt) },
					expires_at: { value: local.expiresAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.expiresAt) },
					actor: { value: local.actor, cfsqltype: "cf_sql_varchar" },
					id: { value: local.id, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });

				renderJsonEnvelope(true, "Emergency alert updated successfully.", { "id": local.id });
			} else {
				local.qIns = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					INSERT INTO emergency_alerts (
						title, message, severity, incident_type, link_url, link_text,
						is_active, is_dismissible, siteid, starts_at, expires_at,
						created_by, modified_by, createdat, updatedat
					) VALUES (
						:title, :message, :severity, :incident_type, :link_url, :link_text,
						:is_active, :is_dismissible, :siteid, :starts_at, :expires_at,
						:actor, :actor, SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT SCOPE_IDENTITY() AS new_id;
				", {
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					message: { value: local.message, cfsqltype: "cf_sql_nvarchar" },
					severity: { value: local.severity, cfsqltype: "cf_sql_varchar" },
					incident_type: { value: local.incidentType, cfsqltype: "cf_sql_varchar" },
					link_url: { value: local.linkUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.linkUrl) },
					link_text: { value: local.linkText, cfsqltype: "cf_sql_varchar" },
					is_active: { value: local.isActive ? 1 : 0, cfsqltype: "cf_sql_bit" },
					is_dismissible: { value: local.isDismissible ? 1 : 0, cfsqltype: "cf_sql_bit" },
					siteid: { value: local.siteId, cfsqltype: "cf_sql_varchar" },
					starts_at: { value: local.startsAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.startsAt) },
					expires_at: { value: local.expiresAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.expiresAt) },
					actor: { value: local.actor, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.newId = Val(local.qIns.new_id);
				renderJsonEnvelope(true, "Emergency alert broadcast activated successfully.", { "id": local.newId });
			}
		} catch (any eSave) {
			writeLog(type="error", file="alerts", text="Alerts save error: #eSave.message# #eSave.detail#");
			renderJsonEnvelope(false, "Failed to save alert: #eSave.message#", {}, 500);
		}
	}

	/**
	 * POST: 1-Click Toggle Active Broadcast Status
	 */
	function toggle() {
		ensureEmergencyAlertsTable();
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: 0);

		if (local.id <= 0) {
			renderJsonEnvelope(false, "Invalid alert ID specified.", {}, 400);
			return;
		}

		try {
			local.q = queryExecute("
				SELECT is_active FROM emergency_alerts WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.q.recordCount == 0) {
				renderJsonEnvelope(false, "Alert not found.", {}, 404);
				return;
			}

			local.newActive = (local.q.is_active == 1) ? 0 : 1;

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE emergency_alerts SET
					is_active = :val,
					modified_by = :actor,
					updatedat = SYSUTCDATETIME()
				WHERE id = :id
			", {
				val: { value: local.newActive, cfsqltype: "cf_sql_bit" },
				actor: { value: resolveCurrentActor(), cfsqltype: "cf_sql_varchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			renderJsonEnvelope(true, local.newActive ? "Alert broadcast is now LIVE." : "Alert broadcast deactivated.", {
				"id": local.id,
				"is_active": (local.newActive == 1)
			});
		} catch (any eToggle) {
			renderJsonEnvelope(false, "Failed to toggle alert status: #eToggle.message#", {}, 500);
		}
	}

	/**
	 * POST: Soft-delete an Emergency Alert
	 */
	function delete() {
		ensureEmergencyAlertsTable();
		local.body = readJsonOrParams();
		local.id = Val(local.body.id ?: 0);

		if (local.id <= 0) {
			renderJsonEnvelope(false, "Invalid alert ID specified.", {}, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE emergency_alerts SET
					deletedat = SYSUTCDATETIME(),
					is_active = 0,
					modified_by = :actor,
					updatedat = SYSUTCDATETIME()
				WHERE id = :id
			", {
				actor: { value: resolveCurrentActor(), cfsqltype: "cf_sql_varchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			renderJsonEnvelope(true, "Emergency alert removed from broadcast history.");
		} catch (any eDel) {
			renderJsonEnvelope(false, "Failed to delete alert: #eDel.message#", {}, 500);
		}
	}

	/**
	 * Public REST / JSON API Endpoint: Return currently active emergency alerts
	 * Consumed by public websites (chelancounty.gov, parks.chelancounty.gov, etc.)
	 */
	function apiActive() {
		ensureEmergencyAlertsTable();
		
		// Set CORS headers for public consumption
		cfheader(name="Access-Control-Allow-Origin", value="*");
		cfheader(name="Access-Control-Allow-Methods", value="GET, OPTIONS");
		cfheader(name="Cache-Control", value="public, max-age=60, s-maxage=60");

		local.siteFilter = StructKeyExists(params, "site") ? LCase(Trim(params.site)) : "global";
		local.activeList = [];

		try {
			local.q = queryExecute("
				SELECT id, title, message, severity, incident_type, link_url, link_text,
				       is_dismissible, siteid, starts_at, expires_at, updatedat
				FROM emergency_alerts
				WHERE deletedat IS NULL
				  AND is_active = 1
				  AND (starts_at IS NULL OR starts_at <= SYSUTCDATETIME())
				  AND (expires_at IS NULL OR expires_at >= SYSUTCDATETIME())
				  AND (siteid = 'global' OR siteid = :site)
				ORDER BY CASE severity WHEN 'danger' THEN 1 WHEN 'warning' THEN 2 ELSE 3 END ASC, id DESC
			", { site: { value: local.siteFilter, cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			for (local.row in local.q) {
				ArrayAppend(local.activeList, {
					"id": local.row.id,
					"title": local.row.title,
					"message": local.row.message,
					"severity": local.row.severity,
					"incident_type": local.row.incident_type,
					"link_url": local.row.link_url ?: "",
					"link_text": local.row.link_text ?: "View Incident Details",
					"is_dismissible": (local.row.is_dismissible == 1),
					"siteid": local.row.siteid,
					"updatedat": local.row.updatedat
				});
			}

			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text=SerializeJSON({
				"success": true,
				"count": ArrayLen(local.activeList),
				"alerts": local.activeList,
				"timestamp": DateFormat(Now(), "yyyy-mm-dd") & "T" & TimeFormat(Now(), "HH:mm:ss") & "Z"
			}));
		} catch (any eApi) {
			cfheader(name="Content-Type", value="application/json; charset=utf-8");
			renderText(text=SerializeJSON({ "success": false, "error": eApi.message, "alerts": [] }), status=500);
		}
	}

	function active() {
		apiActive();
	}

	// --------------------------------------------------------------------------
	// PRIVATE HELPERS
	// --------------------------------------------------------------------------

	private struct function readJsonOrParams() {
		local.content = GetHttpRequestData().content;
		if (IsBinary(local.content)) {
			local.content = CharsetEncode(local.content, "utf-8");
		}
		if (Len(Trim(local.content)) && IsJSON(local.content)) {
			try {
				return healUtf8MojibakeData(DeserializeJSON(healUtf8Mojibake(local.content)));
			} catch (any e) {}
		}
		return params;
	}

	private boolean function parseBooleanVal(required any val) {
		if (IsBoolean(arguments.val)) {
			return (arguments.val == true || arguments.val == 1);
		}
		local.s = LCase(Trim(arguments.val));
		return (local.s == "1" || local.s == "true" || local.s == "yes" || local.s == "on");
	}

	private string function resolveCurrentActor() {
		if (StructKeyExists(session, "user") && isStruct(session.user)) {
			return session.user.full_name ?: (session.user.email ?: "PIO Administrator");
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

	public array function getIncidentPresets() {
		return [
			{
				id: "wildfire-level3",
				name: "Wildfire Level 3 (GO NOW)",
				badgeClass: "badge-danger",
				severity: "danger",
				incident_type: "wildfire",
				title: "LEVEL 3 EVACUATION (GO NOW): Imminent Wildfire Hazard",
				message: "DANGER IS IMMINENT! Evacuate immediately. Danger in your area is current or imminent. Do not delay, gather essential supplies, and leave the evacuation zone via designated emergency routes.",
				link_text: "View Evacuation Map & Shelters",
				link_url: "https://www.chelancounty.gov/emergency-management"
			},
			{
				id: "wildfire-level2",
				name: "Wildfire Level 2 (GET SET)",
				badgeClass: "badge-warning",
				severity: "warning",
				incident_type: "wildfire",
				title: "LEVEL 2 EVACUATION (GET SET): Significant Wildfire Threat",
				message: "Significant danger in your area. Be prepared to evacuate at a moment's notice. Relocate large animals and anyone with mobility requirements immediately.",
				link_text: "Incident Information",
				link_url: "https://www.chelancounty.gov/emergency-management"
			},
			{
				id: "wildfire-level1",
				name: "Wildfire Level 1 (GET READY)",
				badgeClass: "badge-info",
				severity: "info",
				incident_type: "wildfire",
				title: "LEVEL 1 ADVISORY (GET READY): Fire Weather Conditions",
				message: "Be aware of fire danger in your area. Assemble your emergency go-kit, sign up for Chelan County Emergency Alerts, and monitor radio/web news updates.",
				link_text: "Emergency Preparedness",
				link_url: "https://www.chelancounty.gov/emergency-management"
			},
			{
				id: "winter-closure",
				name: "Mountain Pass & Winter Road Closure",
				badgeClass: "badge-warning",
				severity: "warning",
				incident_type: "road_closure",
				title: "ROAD CLOSURE: Mountain Pass Winter Weather Advisory",
				message: "Blewett Pass and Stevens Pass experiencing severe winter conditions, heavy snowpack, and avalanche control. Traction tires or chains required; expect extended delays.",
				link_text: "Check WSDOT Travel Conditions",
				link_url: "https://wsdot.com/travel/real-time/"
			},
			{
				id: "flood-warning",
				name: "River Flood Warning",
				badgeClass: "badge-warning",
				severity: "warning",
				incident_type: "weather",
				title: "FLOOD ADVISORY: Elevated River Flows & Runoff",
				message: "Rising water levels along the Wenatchee River and tributaries. Sandbag distribution stations are active at county road maintenance yards.",
				link_text: "Sandbag Stations & River Gauges",
				link_url: "https://www.chelancounty.gov/public-works"
			},
			{
				id: "facility-delay",
				name: "Courthouse & Campus 2-Hour Delay",
				badgeClass: "badge-info",
				severity: "info",
				incident_type: "facility",
				title: "FACILITY NOTICE: Chelan County Courthouse 2-Hour Delay",
				message: "Due to hazardous winter travel and freezing rain, all Chelan County campus offices, courts, and customer service counters will open at 10:00 AM.",
				link_text: "Court Schedules & Dockets",
				link_url: "https://www.chelancounty.gov/superior-court"
			}
		];
	}

	private void function ensureEmergencyAlertsTable() {
		try {
			queryExecute("
				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[emergency_alerts]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[emergency_alerts] (
						[id]             INT IDENTITY(1,1) NOT NULL,
						[title]          NVARCHAR(255) NOT NULL,
						[message]        NVARCHAR(MAX) NOT NULL,
						[severity]       NVARCHAR(50) NOT NULL CONSTRAINT [DF_emergency_alerts_severity] DEFAULT ('danger'),
						[incident_type]  NVARCHAR(50) NOT NULL CONSTRAINT [DF_emergency_alerts_type] DEFAULT ('wildfire'),
						[link_url]       NVARCHAR(1000) NULL,
						[link_text]      NVARCHAR(100) NOT NULL CONSTRAINT [DF_emergency_alerts_linktext] DEFAULT (N'View Incident Details'),
						[is_active]      BIT NOT NULL CONSTRAINT [DF_emergency_alerts_active] DEFAULT (1),
						[is_dismissible] BIT NOT NULL CONSTRAINT [DF_emergency_alerts_dismiss] DEFAULT (1),
						[siteid]         NVARCHAR(100) NOT NULL CONSTRAINT [DF_emergency_alerts_siteid] DEFAULT (N'global'),
						[starts_at]      DATETIME2(7) NULL,
						[expires_at]     DATETIME2(7) NULL,
						[created_by]     NVARCHAR(255) NULL,
						[modified_by]    NVARCHAR(255) NULL,
						[createdat]      DATETIME2(7) NOT NULL CONSTRAINT [DF_emergency_alerts_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]      DATETIME2(7) NOT NULL CONSTRAINT [DF_emergency_alerts_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]      DATETIME2(7) NULL,
						CONSTRAINT [PK_emergency_alerts] PRIMARY KEY CLUSTERED ([id] ASC)
					);
				END;
			", {}, { datasource: "ChelanCountyWebsite" });

		} catch (any e) {
			writeLog(type="error", file="alerts", text="ensureEmergencyAlertsTable error: #e.message#");
		}
	}

}

