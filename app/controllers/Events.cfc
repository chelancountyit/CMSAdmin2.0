component extends="Controller" {

	function config() {
		super.config();
	}

	/**
	 * County Calendar of Events & Meetings Studio
	 */
	function index() {
		variables.pageTitle = "Events / Calendar";
		ensureEventsTables();

		local.role = getCurrentActiveRole();
		variables.isAdmin = (local.role == "admin");

		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "");
		variables.activeWorkspace = resolveUserActiveWorkspace(local.reqWs, local.role);

		local.wsId = LCase(Trim(variables.activeWorkspace.id ?: "global"));
		local.isGlobalWs = (local.wsId == "global" || local.wsId == "all" || !Len(local.wsId));

		// Always show all events across the county calendar
		variables.viewScope = "all";

		variables.categories = loadEventCategories(includeInactive = true);
		variables.events = loadCalendarEvents(
			requestedWs = "all",
			includeAllWorkspaces = true
		);
		variables.countyRollupEvents = variables.events;
		variables.accessibleWorkspaces = getUserAccessibleWorkspaces(local.role);
	}

	/**
	 * POST JSON: Create or update a County Calendar Event
	 */
	function save() {
		ensureEventsTables();
		local.body = evReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.id = Val(local.req.id ?: 0);
		local.categoryId = Val(local.req.categoryId ?: 0);
		local.title = Left(Trim(local.req.title ?: ""), 255);
		local.slug = slugifyText(Len(Trim(local.req.slug ?: "")) ? local.req.slug : local.title);
		if (!Len(local.slug)) {
			local.slug = "event-" & LCase(Left(CreateUUID(), 8));
		}
		local.summary = Left(Trim(local.req.summary ?: ""), 500);
		local.description = Trim(local.req.description ?: "");

		local.startDateRaw = Trim(local.req.startDate ?: "");
		local.endDateRaw = Trim(local.req.endDate ?: "");
		if (!Len(local.endDateRaw)) {
			local.endDateRaw = local.startDateRaw;
		}

		local.isAllDay = StructKeyExists(local.req, "isAllDay") ? evToBoolean(local.req.isAllDay, false) : false;
		local.startTime = local.isAllDay ? "" : Left(Trim(local.req.startTime ?: ""), 20);
		local.endTime = local.isAllDay ? "" : Left(Trim(local.req.endTime ?: ""), 20);

		local.locationName = Left(Trim(local.req.locationName ?: ""), 255);
		local.locationAddress = Left(Trim(local.req.locationAddress ?: ""), 255);
		local.roomNumber = Left(Trim(local.req.roomNumber ?: ""), 120);
		local.virtualMeetingUrl = Left(Trim(local.req.virtualMeetingUrl ?: ""), 1000);
		local.virtualMeetingId = Left(Trim(local.req.virtualMeetingId ?: ""), 120);
		local.agendaUrl = Left(Trim(local.req.agendaUrl ?: ""), 1000);
		local.minutesUrl = Left(Trim(local.req.minutesUrl ?: ""), 1000);

		local.contactName = Left(Trim(local.req.contactName ?: ""), 150);
		local.contactEmail = Left(Trim(local.req.contactEmail ?: ""), 150);
		local.contactPhone = Left(Trim(local.req.contactPhone ?: ""), 60);

		local.isFeatured = StructKeyExists(local.req, "isFeatured") ? evToBoolean(local.req.isFeatured, false) : false;
		local.isPublicNotice = StructKeyExists(local.req, "isPublicNotice") ? evToBoolean(local.req.isPublicNotice, false) : false;

		local.status = Trim(local.req.status ?: "Published");
		if (!ListFindNoCase("Published,Draft,Cancelled,Postponed,Scheduled,Archived", local.status)) {
			local.status = "Published";
		}

		local.siteId = LCase(Trim(local.req.siteId ?: ""));
		if (!Len(local.siteId) || local.siteId == "all") {
			local.siteId = activeWorkspaceId();
		}
		if (!Len(local.siteId) || local.siteId == "all") {
			local.siteId = "global";
		}

		local.role = getCurrentActiveRole();
		if (local.role != "admin" && local.siteId != "global" && !isWorkspaceAccessible(local.siteId, local.role)) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "You do not have permission to publish calendar events for this workspace.",
				"MESSAGE": "You do not have permission to publish calendar events for this workspace."
			}, 403);
			return;
		}

		if (!Len(local.title)) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Please enter an event title.",
				"MESSAGE": "Please enter an event title."
			}, 422);
			return;
		}
		if (local.categoryId <= 0) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Please select an event category.",
				"MESSAGE": "Please select an event category."
			}, 422);
			return;
		}
		if (!Len(local.startDateRaw) || !IsDate(local.startDateRaw)) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Please select a valid start date (YYYY-MM-DD).",
				"MESSAGE": "Please select a valid start date (YYYY-MM-DD)."
			}, 422);
			return;
		}
		if (!Len(local.endDateRaw) || !IsDate(local.endDateRaw)) {
			local.endDateRaw = local.startDateRaw;
		}

		local.startDateFormatted = DateFormat(ParseDateTime(local.startDateRaw), "yyyy-mm-dd");
		local.endDateFormatted = DateFormat(ParseDateTime(local.endDateRaw), "yyyy-mm-dd");
		if (DateCompare(local.endDateFormatted, local.startDateFormatted, "d") < 0) {
			local.endDateFormatted = local.startDateFormatted;
		}

		local.hasPublishAt = StructKeyExists(local.req, "publish_at") && Len(Trim(local.req.publish_at)) && IsDate(local.req.publish_at);
		local.publishAt = local.hasPublishAt ? ParseDateTime(local.req.publish_at) : "";

		local.hasUnpublishAt = StructKeyExists(local.req, "unpublish_at") && Len(Trim(local.req.unpublish_at)) && IsDate(local.req.unpublish_at);
		local.unpublishAt = local.hasUnpublishAt ? ParseDateTime(local.req.unpublish_at) : "";

		local.actor = evCurrentActor();

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					UPDATE calendar_events
					SET siteid              = :siteId,
					    category_id         = :catId,
					    title               = :title,
					    slug                = :slug,
					    summary             = :summary,
					    description         = :description,
					    start_date          = :startDate,
					    end_date            = :endDate,
					    start_time          = :startTime,
					    end_time            = :endTime,
					    is_all_day          = :isAllDay,
					    location_name       = :locName,
					    location_address    = :locAddr,
					    room_number         = :roomNum,
					    virtual_meeting_url = :virtUrl,
					    virtual_meeting_id  = :virtId,
					    agenda_url          = :agendaUrl,
					    minutes_url         = :minutesUrl,
					    contact_name        = :contactName,
					    contact_email       = :contactEmail,
					    contact_phone       = :contactPhone,
					    is_featured         = :isFeatured,
					    is_public_notice    = :isNotice,
					    status              = :status,
					    publish_at          = :publishAt,
					    unpublish_at        = :unpublishAt,
					    modified_by         = :actor,
					    updatedat           = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					siteId:       { value: local.siteId, cfsqltype: "cf_sql_nvarchar" },
					catId:        { value: local.categoryId, cfsqltype: "cf_sql_integer" },
					title:        { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					slug:         { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					summary:      { value: local.summary, cfsqltype: "cf_sql_nvarchar" },
					description:  { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					startDate:    { value: local.startDateFormatted, cfsqltype: "cf_sql_date" },
					endDate:      { value: local.endDateFormatted, cfsqltype: "cf_sql_date" },
					startTime:    { value: local.startTime, cfsqltype: "cf_sql_nvarchar" },
					endTime:      { value: local.endTime, cfsqltype: "cf_sql_nvarchar" },
					isAllDay:     { value: local.isAllDay ? 1 : 0, cfsqltype: "cf_sql_bit" },
					locName:      { value: local.locationName, cfsqltype: "cf_sql_nvarchar" },
					locAddr:      { value: local.locationAddress, cfsqltype: "cf_sql_nvarchar" },
					roomNum:      { value: local.roomNumber, cfsqltype: "cf_sql_nvarchar" },
					virtUrl:      { value: local.virtualMeetingUrl, cfsqltype: "cf_sql_nvarchar" },
					virtId:       { value: local.virtualMeetingId, cfsqltype: "cf_sql_nvarchar" },
					agendaUrl:    { value: local.agendaUrl, cfsqltype: "cf_sql_nvarchar" },
					minutesUrl:   { value: local.minutesUrl, cfsqltype: "cf_sql_nvarchar" },
					contactName:  { value: local.contactName, cfsqltype: "cf_sql_nvarchar" },
					contactEmail: { value: local.contactEmail, cfsqltype: "cf_sql_nvarchar" },
					contactPhone: { value: local.contactPhone, cfsqltype: "cf_sql_nvarchar" },
					isFeatured:   { value: local.isFeatured ? 1 : 0, cfsqltype: "cf_sql_bit" },
					isNotice:     { value: local.isPublicNotice ? 1 : 0, cfsqltype: "cf_sql_bit" },
					status:       { value: local.status, cfsqltype: "cf_sql_nvarchar" },
					publishAt:    local.hasPublishAt ? { value: local.publishAt, cfsqltype: "cf_sql_timestamp" } : { null: true, cfsqltype: "cf_sql_timestamp" },
					unpublishAt:  local.hasUnpublishAt ? { value: local.unpublishAt, cfsqltype: "cf_sql_timestamp" } : { null: true, cfsqltype: "cf_sql_timestamp" },
					actor:        { value: local.actor, cfsqltype: "cf_sql_nvarchar" },
					id:           { value: local.id, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				local.ins = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					INSERT INTO calendar_events (
						siteid, category_id, title, slug, summary, description,
						start_date, end_date, start_time, end_time, is_all_day,
						location_name, location_address, room_number,
						virtual_meeting_url, virtual_meeting_id, agenda_url, minutes_url,
						contact_name, contact_email, contact_phone,
						is_featured, is_public_notice, status, publish_at, unpublish_at,
						created_by, modified_by, createdat, updatedat
					) VALUES (
						:siteId, :catId, :title, :slug, :summary, :description,
						:startDate, :endDate, :startTime, :endTime, :isAllDay,
						:locName, :locAddr, :roomNum,
						:virtUrl, :virtId, :agendaUrl, :minutesUrl,
						:contactName, :contactEmail, :contactPhone,
						:isFeatured, :isNotice, :status, :publishAt, :unpublishAt,
						:actor, :actor, SYSUTCDATETIME(), SYSUTCDATETIME()
					);
					SELECT SCOPE_IDENTITY() AS new_id;
				", {
					siteId:       { value: local.siteId, cfsqltype: "cf_sql_nvarchar" },
					catId:        { value: local.categoryId, cfsqltype: "cf_sql_integer" },
					title:        { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					slug:         { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					summary:      { value: local.summary, cfsqltype: "cf_sql_nvarchar" },
					description:  { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					startDate:    { value: local.startDateFormatted, cfsqltype: "cf_sql_date" },
					endDate:      { value: local.endDateFormatted, cfsqltype: "cf_sql_date" },
					startTime:    { value: local.startTime, cfsqltype: "cf_sql_nvarchar" },
					endTime:      { value: local.endTime, cfsqltype: "cf_sql_nvarchar" },
					isAllDay:     { value: local.isAllDay ? 1 : 0, cfsqltype: "cf_sql_bit" },
					locName:      { value: local.locationName, cfsqltype: "cf_sql_nvarchar" },
					locAddr:      { value: local.locationAddress, cfsqltype: "cf_sql_nvarchar" },
					roomNum:      { value: local.roomNumber, cfsqltype: "cf_sql_nvarchar" },
					virtUrl:      { value: local.virtualMeetingUrl, cfsqltype: "cf_sql_nvarchar" },
					virtId:       { value: local.virtualMeetingId, cfsqltype: "cf_sql_nvarchar" },
					agendaUrl:    { value: local.agendaUrl, cfsqltype: "cf_sql_nvarchar" },
					minutesUrl:   { value: local.minutesUrl, cfsqltype: "cf_sql_nvarchar" },
					contactName:  { value: local.contactName, cfsqltype: "cf_sql_nvarchar" },
					contactEmail: { value: local.contactEmail, cfsqltype: "cf_sql_nvarchar" },
					contactPhone: { value: local.contactPhone, cfsqltype: "cf_sql_nvarchar" },
					isFeatured:   { value: local.isFeatured ? 1 : 0, cfsqltype: "cf_sql_bit" },
					isNotice:     { value: local.isPublicNotice ? 1 : 0, cfsqltype: "cf_sql_bit" },
					status:       { value: local.status, cfsqltype: "cf_sql_nvarchar" },
					publishAt:    local.hasPublishAt ? { value: local.publishAt, cfsqltype: "cf_sql_timestamp" } : { null: true, cfsqltype: "cf_sql_timestamp" },
					unpublishAt:  local.hasUnpublishAt ? { value: local.unpublishAt, cfsqltype: "cf_sql_timestamp" } : { null: true, cfsqltype: "cf_sql_timestamp" },
					actor:        { value: local.actor, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });
				local.id = Val(local.ins.new_id);
			}

			evRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Calendar event saved successfully.",
				"MESSAGE": "Calendar event saved successfully.",
				"id": local.id,
				"ID": local.id
			});
		} catch (any e) {
			writeLog(type="error", file="events", text="Events.save failed: #e.message# #e.detail#");
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to save calendar event: #e.message#",
				"MESSAGE": "Unable to save calendar event: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON: Soft-delete a County Calendar Event
	 */
	function delete() {
		ensureEventsTables();
		local.body = evReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;
		local.id = Val(local.req.id ?: 0);

		if (local.id <= 0) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Valid event ID is required.",
				"MESSAGE": "Valid event ID is required."
			}, 400);
			return;
		}

		try {
			local.evQ = queryExecute("SELECT siteid FROM calendar_events WHERE id = :id AND deletedat IS NULL", {
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			if (local.evQ.recordCount == 0) {
				evRenderJson({
					"success": false,
					"SUCCESS": false,
					"message": "Calendar event not found.",
					"MESSAGE": "Calendar event not found."
				}, 404);
				return;
			}

			local.role = getCurrentActiveRole();
			if (local.role != "admin" && local.evQ.siteid != "global" && !isWorkspaceAccessible(local.evQ.siteid, local.role)) {
				evRenderJson({
					"success": false,
					"SUCCESS": false,
					"message": "You do not have permission to delete this event.",
					"MESSAGE": "You do not have permission to delete this event."
				}, 403);
				return;
			}

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE calendar_events
				SET deletedat = SYSUTCDATETIME(), modified_by = :actor
				WHERE id = :id
			", {
				actor: { value: evCurrentActor(), cfsqltype: "cf_sql_nvarchar" },
				id:    { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			evRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Calendar event deleted.",
				"MESSAGE": "Calendar event deleted."
			});
		} catch (any e) {
			writeLog(type="error", file="events", text="Events.delete failed: #e.message# #e.detail#");
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to delete event: #e.message#",
				"MESSAGE": "Unable to delete event: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON: Create or update an Event Category
	 */
	function saveCategory() {
		ensureEventsTables();
		local.body = evReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.id = Val(local.req.id ?: 0);
		local.name = Left(Trim(local.req.name ?: ""), 120);
		local.slug = slugifyText(Len(Trim(local.req.slug ?: "")) ? local.req.slug : local.name);
		local.color = Left(Trim(local.req.color ?: "##0284c7"), 30);
		local.badgeClass = Left(Trim(local.req.badgeClass ?: "badge-info"), 50);
		local.icon = Left(Trim(local.req.icon ?: "calendar"), 50);
		local.description = Left(Trim(local.req.description ?: ""), 255);
		local.sortOrder = Int(Val(local.req.sortOrder ?: 100));
		local.isActive = StructKeyExists(local.req, "isActive") ? evToBoolean(local.req.isActive, true) : true;

		if (!Len(local.name)) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Category name is required.",
				"MESSAGE": "Category name is required."
			}, 422);
			return;
		}
		if (!Len(local.slug)) {
			local.slug = "cat-" & LCase(Left(CreateUUID(), 6));
		}

		try {
			if (local.id > 0) {
				queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					UPDATE calendar_event_categories
					SET name        = :name,
					    slug        = :slug,
					    color       = :color,
					    badge_class = :badgeClass,
					    icon        = :icon,
					    description = :desc,
					    sort_order  = :sortOrder,
					    is_active   = :isActive,
					    updatedat   = SYSUTCDATETIME()
					WHERE id = :id AND deletedat IS NULL
				", {
					name:       { value: local.name, cfsqltype: "cf_sql_nvarchar" },
					slug:       { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					color:      { value: local.color, cfsqltype: "cf_sql_nvarchar" },
					badgeClass: { value: local.badgeClass, cfsqltype: "cf_sql_nvarchar" },
					icon:       { value: local.icon, cfsqltype: "cf_sql_nvarchar" },
					desc:       { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					sortOrder:  { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isActive:   { value: local.isActive ? 1 : 0, cfsqltype: "cf_sql_bit" },
					id:         { value: local.id, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });
			} else {
				local.ins = queryExecute("
					SET ANSI_NULLS ON;
					SET QUOTED_IDENTIFIER ON;
					INSERT INTO calendar_event_categories (name, slug, color, badge_class, icon, description, sort_order, is_active, is_system, createdat, updatedat)
					VALUES (:name, :slug, :color, :badgeClass, :icon, :desc, :sortOrder, :isActive, 0, SYSUTCDATETIME(), SYSUTCDATETIME());
					SELECT SCOPE_IDENTITY() AS new_id;
				", {
					name:       { value: local.name, cfsqltype: "cf_sql_nvarchar" },
					slug:       { value: local.slug, cfsqltype: "cf_sql_nvarchar" },
					color:      { value: local.color, cfsqltype: "cf_sql_nvarchar" },
					badgeClass: { value: local.badgeClass, cfsqltype: "cf_sql_nvarchar" },
					icon:       { value: local.icon, cfsqltype: "cf_sql_nvarchar" },
					desc:       { value: local.description, cfsqltype: "cf_sql_nvarchar" },
					sortOrder:  { value: local.sortOrder, cfsqltype: "cf_sql_integer" },
					isActive:   { value: local.isActive ? 1 : 0, cfsqltype: "cf_sql_bit" }
				}, { datasource: "ChelanCountyWebsite" });
				local.id = Val(local.ins.new_id);
			}

			evRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Event category saved.",
				"MESSAGE": "Event category saved.",
				"id": local.id,
				"ID": local.id
			});
		} catch (any e) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to save category: #e.message#",
				"MESSAGE": "Unable to save category: #e.message#"
			}, 500);
		}
	}

	/**
	 * POST JSON: Soft-delete a custom Event Category
	 */
	function deleteCategory() {
		ensureEventsTables();
		local.body = evReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;
		local.id = Val(local.req.id ?: 0);

		if (local.id <= 0) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Valid category ID is required.",
				"MESSAGE": "Valid category ID is required."
			}, 400);
			return;
		}

		try {
			local.cntQ = queryExecute("
				SELECT COUNT(*) AS itemCnt FROM calendar_events WHERE category_id = :id AND deletedat IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (Val(local.cntQ.itemCnt) > 0) {
				local.errMsg = "Cannot delete a category that has #Val(local.cntQ.itemCnt)# active event(s). Reassign or remove its events first.";
				evRenderJson({
					"success": false,
					"SUCCESS": false,
					"message": local.errMsg,
					"MESSAGE": local.errMsg
				}, 422);
				return;
			}

			queryExecute("
				SET ANSI_NULLS ON;
				SET QUOTED_IDENTIFIER ON;
				UPDATE calendar_event_categories SET deletedat = SYSUTCDATETIME() WHERE id = :id AND is_system = 0
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			evRenderJson({
				"success": true,
				"SUCCESS": true,
				"message": "Category deleted.",
				"MESSAGE": "Category deleted."
			});
		} catch (any e) {
			evRenderJson({
				"success": false,
				"SUCCESS": false,
				"message": "Unable to delete category: #e.message#",
				"MESSAGE": "Unable to delete category: #e.message#"
			}, 500);
		}
	}

	/**
	 * GET: Export single event (?id=N) or full calendar as an .ICS (iCalendar) file
	 */
	function exportIcs() {
		ensureEventsTables();
		local.eventId = Val(params.id ?: 0);
		local.allEvents = loadCalendarEvents(requestedWs = "all", includeAllWorkspaces = true);
		local.exportList = [];

		for (local.ev in local.allEvents) {
			if (local.eventId > 0) {
				if (local.ev.id == local.eventId) {
					ArrayAppend(local.exportList, local.ev);
					break;
				}
			} else if (local.ev.status == "Published") {
				ArrayAppend(local.exportList, local.ev);
			}
		}

		local.crlf = Chr(13) & Chr(10);
		local.lines = [
			"BEGIN:VCALENDAR",
			"VERSION:2.0",
			"PRODID:-//Chelan County WA//CMSAdmin 2.0 County Calendar//EN",
			"CALSCALE:GREGORIAN",
			"METHOD:PUBLISH",
			"X-WR-CALNAME:Chelan County Calendar of Events",
			"X-WR-TIMEZONE:America/Los_Angeles"
		];

		local.dtStamp = DateFormat(Now(), "yyyymmdd") & "T" & TimeFormat(Now(), "HHmmss") & "Z";

		for (local.ev in local.exportList) {
			local.sDateClean = Replace(local.ev.startDate, "-", "", "all");
			local.eDateClean = Replace(local.ev.endDate, "-", "", "all");
			ArrayAppend(local.lines, "BEGIN:VEVENT");
			ArrayAppend(local.lines, "UID:chelan-county-event-" & local.ev.id & "@chelancounty.gov");
			ArrayAppend(local.lines, "DTSTAMP:" & local.dtStamp);
			if (local.ev.isAllDay || !Len(local.ev.startTime)) {
				ArrayAppend(local.lines, "DTSTART;VALUE=DATE:" & local.sDateClean);
				local.nextDay = DateAdd("d", 1, ParseDateTime(local.ev.endDate));
				ArrayAppend(local.lines, "DTEND;VALUE=DATE:" & DateFormat(local.nextDay, "yyyymmdd"));
			} else {
				local.stParts = Replace(local.ev.startTime, ":", "", "all");
				local.etParts = Len(local.ev.endTime) ? Replace(local.ev.endTime, ":", "", "all") : local.stParts;
				ArrayAppend(local.lines, "DTSTART:" & local.sDateClean & "T" & Left(local.stParts & "000000", 6));
				ArrayAppend(local.lines, "DTEND:" & local.eDateClean & "T" & Left(local.etParts & "000000", 6));
			}
			ArrayAppend(local.lines, "SUMMARY:" & evEscapeIcs(local.ev.title));
			local.locStr = local.ev.locationName;
			if (Len(local.ev.roomNumber)) local.locStr &= " (" & local.ev.roomNumber & ")";
			if (Len(local.ev.locationAddress)) local.locStr &= ", " & local.ev.locationAddress;
			if (Len(local.locStr)) {
				ArrayAppend(local.lines, "LOCATION:" & evEscapeIcs(local.locStr));
			}
			local.descStr = local.ev.summary;
			if (Len(local.ev.description)) {
				local.descStr &= (Len(local.descStr) ? "\n\n" : "") & REReplace(local.ev.description, "<[^>]+>", "", "all");
			}
			if (Len(local.ev.virtualMeetingUrl)) {
				local.descStr &= "\nVirtual Meeting: " & local.ev.virtualMeetingUrl;
			}
			if (Len(local.ev.agendaUrl)) {
				local.descStr &= "\nAgenda / Packet: " & local.ev.agendaUrl;
			}
			if (Len(local.descStr)) {
				ArrayAppend(local.lines, "DESCRIPTION:" & evEscapeIcs(local.descStr));
			}
			ArrayAppend(local.lines, "CATEGORIES:" & evEscapeIcs(local.ev.categoryName));
			ArrayAppend(local.lines, "END:VEVENT");
		}

		ArrayAppend(local.lines, "END:VCALENDAR");
		local.fileName = (local.eventId > 0 && ArrayLen(local.exportList) == 1)
			? (local.exportList[1].slug & ".ics")
			: "chelan-county-calendar.ics";

		cfheader(name="Content-Disposition", value="attachment; filename=""#local.fileName#""");
		renderText(text=ArrayToList(local.lines, local.crlf), contentType="text/calendar; charset=utf-8", layout=false);
	}

	private string function evEscapeIcs(required string val) {
		local.s = Replace(arguments.val, "\", "\\", "all");
		local.s = Replace(local.s, ";", "\;", "all");
		local.s = Replace(local.s, ",", "\,", "all");
		local.s = REReplace(local.s, "\r?\n", "\n", "all");
		return local.s;
	}

	/**
	 * Ensures dbo.calendar_event_categories and dbo.calendar_events exist and are seeded
	 */
	private void function ensureEventsTables() {
		try {
			queryExecute("
				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[calendar_event_categories]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[calendar_event_categories] (
						[id]          INT IDENTITY(1,1) NOT NULL,
						[name]        NVARCHAR(120) NOT NULL,
						[slug]        NVARCHAR(120) NOT NULL,
						[color]       NVARCHAR(30)  NOT NULL CONSTRAINT [DF_cal_event_cat_color] DEFAULT (N'##0284c7'),
						[badge_class] NVARCHAR(50)  NOT NULL CONSTRAINT [DF_cal_event_cat_badge] DEFAULT (N'badge-info'),
						[icon]        NVARCHAR(50)  NOT NULL CONSTRAINT [DF_cal_event_cat_icon]  DEFAULT (N'calendar'),
						[description] NVARCHAR(255) NULL,
						[sort_order]  INT NOT NULL CONSTRAINT [DF_cal_event_cat_sort]   DEFAULT (0),
						[is_active]   BIT NOT NULL CONSTRAINT [DF_cal_event_cat_active] DEFAULT (1),
						[is_system]   BIT NOT NULL CONSTRAINT [DF_cal_event_cat_system] DEFAULT (0),
						[createdat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_cal_event_cat_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_cal_event_cat_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]   DATETIME2(7) NULL,
						CONSTRAINT [PK_calendar_event_categories] PRIMARY KEY CLUSTERED ([id] ASC)
					);
				END;

				IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[calendar_events]') AND type in (N'U'))
				BEGIN
					CREATE TABLE [dbo].[calendar_events] (
						[id]                  INT IDENTITY(1,1) NOT NULL,
						[siteid]              NVARCHAR(100) NOT NULL CONSTRAINT [DF_calendar_events_siteid] DEFAULT (N'global'),
						[category_id]         INT NOT NULL,
						[title]               NVARCHAR(255) NOT NULL,
						[slug]                NVARCHAR(255) NOT NULL,
						[summary]             NVARCHAR(500) NULL,
						[description]         NVARCHAR(MAX) NULL,
						[start_date]          DATE NOT NULL,
						[end_date]            DATE NOT NULL,
						[start_time]          NVARCHAR(20) NULL,
						[end_time]            NVARCHAR(20) NULL,
						[is_all_day]          BIT NOT NULL CONSTRAINT [DF_calendar_events_allday] DEFAULT (0),
						[location_name]       NVARCHAR(255) NULL,
						[location_address]    NVARCHAR(255) NULL,
						[room_number]         NVARCHAR(120) NULL,
						[virtual_meeting_url] NVARCHAR(1000) NULL,
						[virtual_meeting_id]  NVARCHAR(120) NULL,
						[agenda_url]          NVARCHAR(1000) NULL,
						[minutes_url]         NVARCHAR(1000) NULL,
						[contact_name]        NVARCHAR(150) NULL,
						[contact_email]       NVARCHAR(150) NULL,
						[contact_phone]       NVARCHAR(60) NULL,
						[is_featured]         BIT NOT NULL CONSTRAINT [DF_calendar_events_featured] DEFAULT (0),
						[is_public_notice]    BIT NOT NULL CONSTRAINT [DF_calendar_events_notice] DEFAULT (0),
						[status]              NVARCHAR(30) NOT NULL CONSTRAINT [DF_calendar_events_status] DEFAULT (N'Published'),
						[created_by]          NVARCHAR(255) NULL,
						[modified_by]         NVARCHAR(255) NULL,
						[createdat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_calendar_events_createdat] DEFAULT (SYSUTCDATETIME()),
						[updatedat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_calendar_events_updatedat] DEFAULT (SYSUTCDATETIME()),
						[deletedat]           DATETIME2(7) NULL,
						CONSTRAINT [PK_calendar_events] PRIMARY KEY CLUSTERED ([id] ASC),
						CONSTRAINT [FK_calendar_events_categories] FOREIGN KEY ([category_id]) REFERENCES [dbo].[calendar_event_categories] ([id])
					);
				END;
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			writeLog(type="error", file="events", text="ensureEventsTables failed: #e.message# #e.detail#");
		}
	}

	/**
	 * Loads all Calendar Event Categories
	 */
	private array function loadEventCategories(boolean includeInactive = false) {
		local.cats = [];
		try {
			local.sql = "
				SELECT c.id, c.name, c.slug, c.color, c.badge_class, c.icon, c.description, c.sort_order, c.is_active, c.is_system,
				       (SELECT COUNT(*) FROM calendar_events e WHERE e.category_id = c.id AND e.deletedat IS NULL) AS total_events
				FROM calendar_event_categories c
				WHERE c.deletedat IS NULL
			";
			if (!arguments.includeInactive) {
				local.sql &= " AND c.is_active = 1";
			}
			local.sql &= " ORDER BY c.sort_order ASC, c.name ASC";

			local.q = queryExecute(local.sql, {}, { datasource: "ChelanCountyWebsite" });
			for (local.r in local.q) {
				ArrayAppend(local.cats, {
					"id":          Val(local.r.id),
					"name":        local.r.name ?: "",
					"slug":        local.r.slug ?: "",
					"color":       Len(Trim(local.r.color ?: "")) ? local.r.color : "##0284c7",
					"badgeClass":  Len(Trim(local.r.badge_class ?: "")) ? local.r.badge_class : "badge-info",
					"icon":        Len(Trim(local.r.icon ?: "")) ? local.r.icon : "calendar",
					"description": local.r.description ?: "",
					"sortOrder":   Val(local.r.sort_order),
					"isActive":    (local.r.is_active == 1),
					"isSystem":    (local.r.is_system == 1),
					"totalEvents": Val(local.r.total_events)
				});
			}
		} catch (any e) {
			writeLog(type="error", file="events", text="loadEventCategories failed: #e.message# #e.detail#");
		}
		return local.cats;
	}

	/**
	 * Loads Calendar Events scoped by workspace or county-wide
	 */
	private array function loadCalendarEvents(string requestedWs = "", boolean includeAllWorkspaces = false) {
		local.events = [];
		try {
			local.wsMap = {};
			for (local.w in getMasterWorkspaces()) {
				local.info = {
					"id":         local.w.id,
					"name":       local.w.name,
					"badge":      local.w.badge ?: "Dept",
					"badgeClass": local.w.badgeClass ?: "badge-neutral"
				};
				local.wsMap[LCase(local.w.id)] = local.info;
				if (StructKeyExists(local.w, "code") && Len(local.w.code)) local.wsMap[LCase(local.w.code)] = local.info;
				if (StructKeyExists(local.w, "alias") && Len(local.w.alias)) local.wsMap[LCase(local.w.alias)] = local.info;
				if (StructKeyExists(local.w, "virtual_directory") && Len(local.w.virtual_directory)) local.wsMap[LCase(local.w.virtual_directory)] = local.info;
			}

			local.params = {};
			local.whereClause = "WHERE e.deletedat IS NULL AND c.deletedat IS NULL";

			if (!arguments.includeAllWorkspaces && Len(Trim(arguments.requestedWs)) && arguments.requestedWs != "all" && arguments.requestedWs != "global") {
				local.cands = getCandidateSiteIds(arguments.requestedWs);
				if (ArrayLen(local.cands) == 0) ArrayAppend(local.cands, LCase(Trim(arguments.requestedWs)));
				// Also include 'global' county-wide holidays/events when viewing a department calendar
				if (!ArrayFindNoCase(local.cands, "global")) ArrayAppend(local.cands, "global");

				local.inList = [];
				for (local.idx = 1; local.idx <= ArrayLen(local.cands); local.idx++) {
					local.pKey = "evSite" & local.idx;
					ArrayAppend(local.inList, ":" & local.pKey);
					local.params[local.pKey] = { value: local.cands[local.idx], cfsqltype: "cf_sql_nvarchar" };
				}
				local.whereClause &= " AND LOWER(e.siteid) IN (" & ArrayToList(local.inList, ", ") & ")";
			}

			local.q = queryExecute("
				SELECT e.id, e.siteid, e.category_id, e.title, e.slug, e.summary, e.description,
				       e.start_date, e.end_date, e.start_time, e.end_time, e.is_all_day,
				       e.location_name, e.location_address, e.room_number,
				       e.virtual_meeting_url, e.virtual_meeting_id, e.agenda_url, e.minutes_url,
				       e.contact_name, e.contact_email, e.contact_phone,
				       e.is_featured, e.is_public_notice, e.status, e.publish_at, e.unpublish_at,
				       e.created_by, e.modified_by, e.createdat, e.updatedat,
				       c.name AS category_name, c.slug AS category_slug, c.color AS category_color,
				       c.badge_class AS category_badge, c.icon AS category_icon
				FROM calendar_events e
				INNER JOIN calendar_event_categories c ON c.id = e.category_id
				" & local.whereClause & "
				ORDER BY e.start_date ASC, CASE WHEN e.is_all_day = 1 THEN '00:00' ELSE ISNULL(NULLIF(e.start_time, ''), '09:00') END ASC, e.title ASC
			", local.params, { datasource: "ChelanCountyWebsite" });

			for (local.r in local.q) {
				local.sKey = LCase(Trim(local.r.siteid ?: "global"));
				local.wsInfo = StructKeyExists(local.wsMap, local.sKey)
					? local.wsMap[local.sKey]
					: { "id": local.sKey, "name": (local.sKey == "global" ? "County-Wide" : (local.r.siteid ?: "County-Wide")), "badge": (local.sKey == "global" ? "County-Wide" : local.r.siteid), "badgeClass": "badge-neutral" };

				local.sDateStr = IsDate(local.r.start_date) ? DateFormat(local.r.start_date, "yyyy-mm-dd") : DateFormat(Now(), "yyyy-mm-dd");
				local.eDateStr = IsDate(local.r.end_date) ? DateFormat(local.r.end_date, "yyyy-mm-dd") : local.sDateStr;
				local.updatedStr = IsDate(local.r.updatedat) ? DateFormat(local.r.updatedat, "mm/dd/yyyy") : "";

				local.pubStr = IsDate(local.r.publish_at ?: "") ? DateFormat(local.r.publish_at, "yyyy-mm-dd") & "T" & TimeFormat(local.r.publish_at, "HH:mm") : "";
				local.unpubStr = IsDate(local.r.unpublish_at ?: "") ? DateFormat(local.r.unpublish_at, "yyyy-mm-dd") & "T" & TimeFormat(local.r.unpublish_at, "HH:mm") : "";

				ArrayAppend(local.events, {
					"id":                 Val(local.r.id),
					"siteId":             local.r.siteid ?: "global",
					"workspaceName":      local.wsInfo.name,
					"workspaceBadge":     local.wsInfo.badge,
					"workspaceBadgeClass": local.wsInfo.badgeClass,
					"categoryId":         Val(local.r.category_id),
					"categoryName":       local.r.category_name ?: "Event",
					"categorySlug":       local.r.category_slug ?: "event",
					"categoryColor":      Len(Trim(local.r.category_color ?: "")) ? local.r.category_color : "##0284c7",
					"categoryBadge":      Len(Trim(local.r.category_badge ?: "")) ? local.r.category_badge : "badge-info",
					"categoryIcon":       Len(Trim(local.r.category_icon ?: "")) ? local.r.category_icon : "calendar",
					"title":              local.r.title ?: "",
					"slug":               local.r.slug ?: "",
					"summary":            local.r.summary ?: "",
					"description":        local.r.description ?: "",
					"startDate":          local.sDateStr,
					"endDate":            local.eDateStr,
					"startTime":          local.r.start_time ?: "",
					"endTime":            local.r.end_time ?: "",
					"isAllDay":           (local.r.is_all_day == 1),
					"locationName":       local.r.location_name ?: "",
					"locationAddress":    local.r.location_address ?: "",
					"roomNumber":         local.r.room_number ?: "",
					"virtualMeetingUrl":  local.r.virtual_meeting_url ?: "",
					"virtualMeetingId":   local.r.virtual_meeting_id ?: "",
					"agendaUrl":          local.r.agenda_url ?: "",
					"minutesUrl":         local.r.minutes_url ?: "",
					"contactName":        local.r.contact_name ?: "",
					"contactEmail":       local.r.contact_email ?: "",
					"contactPhone":       local.r.contact_phone ?: "",
					"isFeatured":         (local.r.is_featured == 1),
					"isPublicNotice":     (local.r.is_public_notice == 1),
					"status":             Len(Trim(local.r.status ?: "")) ? local.r.status : "Published",
					"publishAt":          local.pubStr,
					"unpublishAt":        local.unpubStr,
					"updated":            local.updatedStr,
					"author":             Len(Trim(local.r.modified_by ?: "")) ? local.r.modified_by : (local.r.created_by ?: "Admin")
				});
			}
		} catch (any e) {
			writeLog(type="error", file="events", text="loadCalendarEvents failed: #e.message# #e.detail#");
		}
		return local.events;
	}

	private array function getCandidateSiteIds(string wsId = "") {
		local.candidates = [];
		local.rawId = LCase(Trim(arguments.wsId));
		if (!Len(local.rawId) || local.rawId == "global" || local.rawId == "all") {
			return local.candidates;
		}
		local.wsObj = resolveUserActiveWorkspace(requestedWs=local.rawId, role=getCurrentActiveRole());
		local.siteid = LCase(Trim(StructKeyExists(local.wsObj, "id") ? local.wsObj.id : local.rawId));

		if (Len(local.siteid) && local.siteid != "global" && local.siteid != "all") {
			ArrayAppend(local.candidates, local.siteid);
		}
		if (StructKeyExists(local.wsObj, "code") && Len(Trim(local.wsObj.code)) && !ArrayFindNoCase(local.candidates, local.wsObj.code)) {
			ArrayAppend(local.candidates, LCase(Trim(local.wsObj.code)));
		}
		if (StructKeyExists(local.wsObj, "alias") && Len(Trim(local.wsObj.alias)) && !ArrayFindNoCase(local.candidates, local.wsObj.alias)) {
			ArrayAppend(local.candidates, LCase(Trim(local.wsObj.alias)));
		}
		if (StructKeyExists(local.wsObj, "virtual_directory") && Len(Trim(local.wsObj.virtual_directory)) && !ArrayFindNoCase(local.candidates, local.wsObj.virtual_directory)) {
			ArrayAppend(local.candidates, LCase(Trim(local.wsObj.virtual_directory)));
		}
		if (Len(local.siteid)) {
			if (Right(local.siteid, 1) == "s") {
				local.singular = Left(local.siteid, Len(local.siteid) - 1);
				if (Len(local.singular) && !ArrayFindNoCase(local.candidates, local.singular)) ArrayAppend(local.candidates, local.singular);
			} else {
				local.plural = local.siteid & "s";
				if (!ArrayFindNoCase(local.candidates, local.plural)) ArrayAppend(local.candidates, local.plural);
			}
		}
		return local.candidates;
	}

	private string function activeWorkspaceId() {
		local.reqWs = (StructKeyExists(params, "ws") && Len(Trim(params.ws))) ? Trim(params.ws)
			: ((StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? Trim(cookie.cmsadmin_workspace) : "global");
		local.wsObj = resolveUserActiveWorkspace(local.reqWs, getCurrentActiveRole());
		return LCase(Trim(local.wsObj.id ?: "global"));
	}

	private string function evCurrentActor() {
		if (StructKeyExists(session, "user") && IsStruct(session.user)) {
			if (Len(Trim(session.user.full_name ?: ""))) return Trim(session.user.full_name);
			if (Len(Trim(session.user.email ?: ""))) return Trim(session.user.email);
		}
		return "Sarah Jenkins";
	}

	private boolean function evToBoolean(any val, boolean defaultValue = false) {
		if (IsNull(arguments.val) || !IsSimpleValue(arguments.val)) return arguments.defaultValue;
		local.s = LCase(Trim(ToString(arguments.val)));
		if (ListFindNoCase("1,true,yes,on", local.s)) return true;
		if (ListFindNoCase("0,false,no,off", local.s)) return false;
		return arguments.defaultValue;
	}

	private any function evReadJsonBody() {
		try {
			local.content = GetHTTPRequestData().content;
			if (IsBinary(local.content)) local.content = CharsetEncode(local.content, "utf-8");
			if (Len(Trim(local.content)) && IsJSON(local.content)) return healUtf8MojibakeData(DeserializeJSON(healUtf8Mojibake(local.content)));
		} catch (any e) {
			return "";
		}
		return "";
	}

	private void function evRenderJson(required any data, numeric status = 200) {
		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text=SerializeJSON(arguments.data), status=arguments.status);
	}

	private string function slugifyText(required string text) {
		local.s = LCase(Trim(arguments.text));
		local.s = REReplace(local.s, "[^a-z0-9\s-]", "", "all");
		local.s = REReplace(local.s, "[\s_-]+", "-", "all");
		local.s = REReplace(local.s, "^-+|-+$", "", "all");
		return local.s;
	}

}

