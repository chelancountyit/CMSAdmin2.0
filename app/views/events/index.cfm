<cfset pageTitle = "Events / Calendar">
<cfscript>
	activeWsId = StructKeyExists(variables, "activeWorkspace") && IsStruct(variables.activeWorkspace) ? (variables.activeWorkspace.id ?: "global") : "global";
	activeWsName = StructKeyExists(variables, "activeWorkspace") && IsStruct(variables.activeWorkspace) ? (variables.activeWorkspace.name ?: "All Workspaces") : "All Workspaces";
	activeWsBadge = StructKeyExists(variables, "activeWorkspace") && IsStruct(variables.activeWorkspace) ? (variables.activeWorkspace.badge ?: "Global") : "Global";
	activeWsBadgeClass = StructKeyExists(variables, "activeWorkspace") && IsStruct(variables.activeWorkspace) ? (variables.activeWorkspace.badgeClass ?: "badge-neutral") : "badge-neutral";
	isGlobalSelected = (activeWsId eq "global" or activeWsId eq "all" or !Len(activeWsId));
	curScope = StructKeyExists(variables, "viewScope") ? variables.viewScope : "all";

	eventsArr = StructKeyExists(variables, "events") && IsArray(variables.events) ? variables.events : [];
	catsArr = StructKeyExists(variables, "categories") && IsArray(variables.categories) ? variables.categories : [];
	wsListArr = StructKeyExists(variables, "accessibleWorkspaces") && IsArray(variables.accessibleWorkspaces) ? variables.accessibleWorkspaces : [];

	todayStr = DateFormat(Now(), "yyyy-mm-dd");
	next30Str = DateFormat(DateAdd("d", 30, Now()), "yyyy-mm-dd");

	cntTotal = ArrayLen(eventsArr);
	cntUpcoming30 = 0;
	cntHearingsMeetings = 0;
	cntWithVirtualOrAgenda = 0;

	for (ev in eventsArr) {
		if (ev.endDate >= todayStr && ev.startDate <= next30Str && ev.status != "Cancelled") {
			cntUpcoming30++;
		}
		if (ListFindNoCase("commissioners-meeting,public-hearing,advisory-board", ev.categorySlug)) {
			cntHearingsMeetings++;
		}
		if (Len(Trim(ev.virtualMeetingUrl ?: "")) || Len(Trim(ev.agendaUrl ?: ""))) {
			cntWithVirtualOrAgenda++;
		}
	}

	saveEventUrl = urlFor(controller="events", action="save");
	deleteEventUrl = urlFor(controller="events", action="delete");
	saveCategoryUrl = urlFor(controller="events", action="saveCategory");
	deleteCategoryUrl = urlFor(controller="events", action="deleteCategory");
	exportIcsUrl = urlFor(controller="events", action="exportIcs");
	mediaPickerUrl = urlFor(controller="media", action="picker");
</cfscript>

<cfoutput>
<style>
/* Events / Calendar Studio Styles */
.ev-toolbar {
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-wrap: wrap;
	gap: 0.85rem;
	margin-bottom: 1.25rem;
}
.ev-view-tabs {
	display: inline-flex;
	background: var(--admin-bg, ##f1f5f9);
	border: 1px solid var(--admin-border, ##cbd5e1);
	border-radius: var(--radius-md, 0.5rem);
	padding: 0.2rem;
	gap: 0.2rem;
}
.ev-view-tab {
	display: inline-flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.45rem 0.9rem;
	font-size: 0.825rem;
	font-weight: 600;
	border: none;
	border-radius: var(--radius-sm, 0.375rem);
	background: transparent;
	color: var(--admin-text-muted, ##475569);
	cursor: pointer;
	transition: all 0.15s ease;
}
.ev-view-tab:hover {
	color: var(--admin-text-main, ##0f172a);
}
.ev-view-tab.is-active {
	background: var(--admin-surface, ##ffffff);
	color: var(--admin-primary, ##0284c7);
	box-shadow: 0 1px 3px rgba(15, 23, 42, 0.1);
}

/* Monthly Calendar Grid */
.ev-calendar-card {
	background: var(--admin-surface, ##ffffff);
	border: 1px solid var(--admin-border, ##cbd5e1);
	border-radius: var(--radius-lg, 0.75rem);
	overflow: hidden;
	box-shadow: var(--shadow-sm);
}
.ev-calendar-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-wrap: wrap;
	gap: 0.75rem;
	padding: 1rem 1.25rem;
	border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
	background: linear-gradient(to bottom, ##ffffff, var(--admin-bg, ##f8fafc));
}
.ev-calendar-nav {
	display: flex;
	align-items: center;
	gap: 0.5rem;
}
.ev-calendar-month-title {
	font-size: 1.2rem;
	font-weight: 700;
	color: var(--admin-text-main, ##0f172a);
	min-width: 195px;
	text-align: center;
	margin: 0;
}
.ev-category-legend {
	display: flex;
	align-items: center;
	flex-wrap: wrap;
	gap: 0.65rem;
}
.ev-legend-pill {
	display: inline-flex;
	align-items: center;
	gap: 0.35rem;
	font-size: 0.75rem;
	font-weight: 600;
	color: var(--admin-text-muted, ##475569);
	padding: 0.2rem 0.55rem;
	border-radius: 999px;
	background: var(--admin-bg, ##f8fafc);
	border: 1px solid var(--admin-border-subtle, ##e2e8f0);
	cursor: pointer;
	transition: all 0.15s ease;
}
.ev-legend-pill:hover,
.ev-legend-pill.is-active {
	border-color: var(--admin-primary, ##0284c7);
	color: var(--admin-text-main, ##0f172a);
	background: ##f0f9ff;
}
.ev-legend-dot {
	width: 9px;
	height: 9px;
	border-radius: 50%;
	flex-shrink: 0;
}
.ev-weekdays-row {
	display: grid;
	grid-template-columns: repeat(7, minmax(0, 1fr));
	background: var(--admin-bg, ##f8fafc);
	border-bottom: 1px solid var(--admin-border, ##cbd5e1);
}
.ev-weekday-cell {
	padding: 0.6rem 0.5rem;
	text-align: center;
	font-size: 0.75rem;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	color: var(--admin-text-muted, ##475569);
	border-right: 1px solid var(--admin-border-subtle, ##e2e8f0);
}
.ev-weekday-cell:last-child {
	border-right: none;
}
.ev-days-grid {
	display: grid;
	grid-template-columns: repeat(7, minmax(0, 1fr));
	background: var(--admin-border-subtle, ##e2e8f0);
	gap: 1px;
}
.ev-day-cell {
	background: var(--admin-surface, ##ffffff);
	min-height: 122px;
	padding: 0.45rem;
	display: flex;
	flex-direction: column;
	gap: 0.3rem;
	position: relative;
	transition: background 0.12s ease;
}
.ev-day-cell:hover {
	background: ##fafcff;
}
.ev-day-cell.is-outside {
	background: ##f8fafc;
	color: ##94a3b8;
}
.ev-day-cell.is-today {
	background: ##f0f9ff;
}
.ev-day-top {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 0.15rem;
}
.ev-day-num {
	font-size: 0.8rem;
	font-weight: 700;
	color: var(--admin-text-main, ##0f172a);
	width: 26px;
	height: 26px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	border-radius: 50%;
}
.ev-day-cell.is-outside .ev-day-num {
	color: ##64748b;
	font-weight: 500;
}
.ev-day-cell.is-today .ev-day-num {
	background: var(--admin-primary, ##0284c7);
	color: ##ffffff;
}
.ev-day-add-btn {
	opacity: 0;
	width: 22px;
	height: 22px;
	border-radius: 4px;
	border: 1px solid var(--admin-border, ##cbd5e1);
	background: var(--admin-surface, ##ffffff);
	color: var(--admin-text-muted, ##475569);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	padding: 0;
	font-size: 0.85rem;
	line-height: 1;
	transition: all 0.15s ease;
}
.ev-day-cell:hover .ev-day-add-btn,
.ev-day-add-btn:focus-visible {
	opacity: 1;
}
.ev-day-add-btn:hover {
	background: var(--admin-primary, ##0284c7);
	color: ##ffffff;
	border-color: var(--admin-primary, ##0284c7);
}
.ev-day-events {
	display: flex;
	flex-direction: column;
	gap: 0.25rem;
	flex: 1;
}
.ev-chip {
	display: flex;
	align-items: center;
	gap: 0.3rem;
	width: 100%;
	text-align: left;
	padding: 0.24rem 0.42rem;
	border-radius: 4px;
	border: none;
	border-left: 3px solid var(--chip-color, ##0284c7);
	background: var(--chip-bg, ##f0f9ff);
	color: var(--admin-text-main, ##0f172a);
	font-size: 0.72rem;
	line-height: 1.25;
	cursor: pointer;
	overflow: hidden;
	transition: transform 0.1s ease, box-shadow 0.1s ease;
}
.ev-chip:hover {
	transform: translateY(-1px);
	box-shadow: 0 2px 5px rgba(15, 23, 42, 0.12);
}
.ev-chip.is-cancelled {
	text-decoration: line-through;
	opacity: 0.65;
}
.ev-chip-time {
	font-weight: 700;
	color: var(--chip-color, ##0284c7);
	white-space: nowrap;
	flex-shrink: 0;
}
.ev-chip-title {
	font-weight: 600;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
	flex: 1;
}
.ev-date-badge {
	display: inline-flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	width: 52px;
	min-height: 52px;
	border-radius: var(--radius-md, 0.5rem);
	border: 1px solid var(--admin-border, ##cbd5e1);
	background: var(--admin-bg, ##f8fafc);
	padding: 0.25rem;
	flex-shrink: 0;
	text-align: center;
}
.ev-date-badge-month {
	font-size: 0.65rem;
	font-weight: 800;
	text-transform: uppercase;
	letter-spacing: 0.06em;
	color: var(--admin-primary, ##0284c7);
	line-height: 1.1;
}
.ev-date-badge-day {
	font-size: 1.15rem;
	font-weight: 800;
	color: var(--admin-text-main, ##0f172a);
	line-height: 1.15;
}

/* Modal Backdrop (kept below 100000 so adminPromptBackdrop layers on top) */
.ev-modal-backdrop {
	position: fixed !important;
	inset: 0 !important;
	width: 100vw !important;
	height: 100vh !important;
	background: rgba(15, 23, 42, 0.68) !important;
	backdrop-filter: blur(4px);
	-webkit-backdrop-filter: blur(4px);
	z-index: 9990 !important;
	display: none;
	align-items: center;
	justify-content: center;
	padding: 1.25rem;
	box-sizing: border-box;
}
.ev-modal-backdrop.is-open {
	display: flex !important;
}
.ev-modal-dialog {
	background: var(--admin-surface, ##ffffff);
	border: 1px solid var(--admin-border, ##cbd5e1);
	border-radius: var(--radius-lg, 0.75rem);
	box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.42);
	width: 100%;
	max-width: 860px;
	max-height: 92vh;
	display: flex;
	flex-direction: column;
	overflow: hidden;
}
.ev-modal-header {
	padding: 1.1rem 1.5rem;
	border-bottom: 1px solid var(--admin-border-subtle, ##e2e8f0);
	display: flex;
	align-items: center;
	justify-content: space-between;
	background: linear-gradient(to bottom, ##ffffff, var(--admin-bg, ##f8fafc));
}
.ev-modal-title {
	margin: 0;
	font-size: 1.125rem;
	font-weight: 700;
	color: var(--admin-text-main, ##0f172a);
	display: flex;
	align-items: center;
	gap: 0.5rem;
}
.ev-modal-body {
	padding: 1.35rem 1.5rem;
	overflow-y: auto;
	flex: 1;
}
.ev-modal-footer {
	padding: 0.95rem 1.5rem;
	border-top: 1px solid var(--admin-border-subtle, ##e2e8f0);
	background: var(--admin-bg, ##f8fafc);
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 0.75rem;
}
.ev-section-box {
	border: 1px solid var(--admin-border-subtle, ##e2e8f0);
	border-radius: var(--radius-md, 0.5rem);
	padding: 1rem 1.15rem;
	background: ##ffffff;
	margin-bottom: 1.1rem;
}
.ev-section-box-title {
	font-size: 0.82rem;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	color: var(--admin-primary, ##0284c7);
	margin: 0 0 0.85rem 0;
	display: flex;
	align-items: center;
	gap: 0.4rem;
}
.ev-preset-pill {
	display: inline-flex;
	align-items: center;
	gap: 0.3rem;
	padding: 0.25rem 0.6rem;
	font-size: 0.74rem;
	font-weight: 600;
	border-radius: 999px;
	border: 1px solid var(--admin-border, ##cbd5e1);
	background: var(--admin-bg, ##f8fafc);
	color: var(--admin-text-main, ##0f172a);
	cursor: pointer;
	transition: all 0.12s ease;
}
.ev-preset-pill:hover {
	border-color: var(--admin-primary, ##0284c7);
	background: ##f0f9ff;
	color: var(--admin-primary, ##0284c7);
}
@media (max-width: 900px) {
	.ev-day-cell { min-height: 90px; }
}
</style>

<!--- Page Header --->
<div class="page-header">
	<div>
		<div style="display:flex; align-items:center; gap:0.65rem; flex-wrap:wrap;">
			<h1 class="page-title" style="margin-bottom:0;">Events / Calendar</h1>
			<span class="badge #activeWsBadgeClass#" style="font-size:0.75rem;">#EncodeForHTML(activeWsName)#</span>
		</div>
		<nav aria-label="Breadcrumb">
			<ol class="breadcrumb" style="margin-top:0.35rem;">
				<li class="breadcrumb-item"><a href="#urlFor(controller='main', action='index')#">#svgIcon(name="dashboard", size=14)# Home</a></li>
				<li class="breadcrumb-item">Content Management</li>
				<li class="breadcrumb-item active" aria-current="page">Events / Calendar</li>
			</ol>
		</nav>
	</div>

	<div class="page-actions" style="display:flex; gap:0.5rem; align-items:center; flex-wrap:wrap;">
		<button type="button" id="btnManageCategories" class="btn btn-outline btn-sm">
			#svgIcon(name="tag", size=15)#
			<span>Categories</span>
		</button>

		<a href="#exportIcsUrl#" class="btn btn-outline btn-sm" title="Download iCalendar (.ICS) feed">
			#svgIcon(name="download", size=15)#
			<span>Export .ICS</span>
		</a>

		<button type="button" id="btnOpenAddEvent" class="btn btn-primary btn-sm">
			#svgIcon(name="plus", size=15)#
			<span>Add Event</span>
		</button>
	</div>
</div>

<!--- KPI Summary Cards --->
<div class="stat-grid" style="margin-bottom:1.5rem;">
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Total Calendar Events</span>
			<span class="stat-value" id="statTotalEvents">#cntTotal#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-primary" aria-hidden="true">#svgIcon(name="calendar", size=24)#</div>
	</div>
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Upcoming (Next 30 Days)</span>
			<span class="stat-value" id="statUpcoming30">#cntUpcoming30#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-success" aria-hidden="true">#svgIcon(name="clock", size=24)#</div>
	</div>
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">Meetings &amp; Public Hearings</span>
			<span class="stat-value" id="statMeetings">#cntHearingsMeetings#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-warning" aria-hidden="true">#svgIcon(name="megaphone", size=24)#</div>
	</div>
	<div class="stat-card">
		<div class="stat-info">
			<span class="stat-label">With Virtual Link / Agenda</span>
			<span class="stat-value" id="statVirtualAgenda">#cntWithVirtualOrAgenda#</span>
		</div>
		<div class="stat-icon-wrapper stat-icon-info" aria-hidden="true">#svgIcon(name="video", size=24)#</div>
	</div>
</div>

<!--- View Switcher & Multi-Facet Filter Bar --->
<div class="admin-card" style="margin-bottom:1.25rem;">
	<div class="card-body" style="padding:1rem 1.25rem;">
		<div class="ev-toolbar">
			<div class="ev-view-tabs" role="tablist" aria-label="Calendar display mode">
				<button type="button" role="tab" aria-selected="true" class="ev-view-tab is-active" data-view="calendar" id="tabBtnCalendar">
					#svgIcon(name="calendar", size=15)#
					<span>Calendar Grid</span>
				</button>
				<button type="button" role="tab" aria-selected="false" class="ev-view-tab" data-view="list" id="tabBtnList">
					#svgIcon(name="list", size=15)#
					<span>Events List</span>
				</button>
				<button type="button" role="tab" aria-selected="false" class="ev-view-tab" data-view="preview" id="tabBtnPreview">
					#svgIcon(name="eye", size=15)#
					<span>Public Calendar Preview</span>
				</button>
			</div>

			<div id="evFilterCount" role="status" aria-live="polite" style="font-size:0.82rem; font-weight:600; color:var(--admin-text-muted);">
				Showing #cntTotal# of #cntTotal# events
			</div>
		</div>

		<div style="display:flex; align-items:flex-end; flex-wrap:wrap; gap:0.85rem;">
			<div style="flex:1 1 240px; max-width:340px;">
				<label for="evSearchInput" class="form-label" style="font-size:0.775rem;">Search Events</label>
				<input type="search" id="evSearchInput" class="form-control" placeholder="Title, room, location, or keyword..." style="width:100%; padding:0.5rem 0.75rem; font-size:0.85rem;">
			</div>

			<div>
				<label for="evCategoryFilter" class="form-label" style="font-size:0.775rem;">Category</label>
				<select id="evCategoryFilter" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;">
					<option value="">All Categories</option>
					<cfloop array="#catsArr#" index="cat">
						<option value="#cat.id#">#EncodeForHTML(cat.name)#</option>
					</cfloop>
				</select>
			</div>

			<div>
				<label for="evWorkspaceFilter" class="form-label" style="font-size:0.775rem;">Department / Workspace</label>
				<select id="evWorkspaceFilter" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;">
					<option value="">All Workspaces</option>
					<option value="global">County-Wide (Global)</option>
					<cfloop array="#wsListArr#" index="ws">
						<cfif ws.id neq "global">
							<option value="#EncodeForHTMLAttribute(LCase(ws.id))#">#EncodeForHTML(ws.name)#</option>
						</cfif>
					</cfloop>
				</select>
			</div>

			<div>
				<label for="evStatusFilter" class="form-label" style="font-size:0.775rem;">Status</label>
				<select id="evStatusFilter" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;">
					<option value="">All Statuses</option>
					<option value="Published">Published</option>
					<option value="Scheduled">Scheduled</option>
					<option value="Draft">Draft</option>
					<option value="Postponed">Postponed</option>
					<option value="Cancelled">Cancelled</option>
					<option value="Archived">Archived</option>
				</select>
			</div>

			<div>
				<label for="evTimeframeFilter" class="form-label" style="font-size:0.775rem;">Timeframe</label>
				<select id="evTimeframeFilter" class="form-control" style="padding:0.5rem 0.75rem; font-size:0.85rem;">
					<option value="all">All Dates</option>
					<option value="upcoming">Upcoming &amp; Today</option>
					<option value="month">Current Calendar Month</option>
					<option value="past">Past Events</option>
				</select>
			</div>

			<button type="button" id="btnResetEvFilters" class="btn btn-outline btn-sm" style="height:36px;">
				Reset
			</button>
		</div>
	</div>
</div>

<!--- ===================================================================== --->
<!--- VIEW 1: INTERACTIVE MONTHLY CALENDAR GRID                             --->
<!--- ===================================================================== --->
<section id="viewPanelCalendar" aria-label="Monthly Calendar Grid">
	<div class="ev-calendar-card">
		<div class="ev-calendar-header">
			<div class="ev-calendar-nav">
				<button type="button" id="btnCalPrev" class="btn btn-outline btn-sm" aria-label="Previous Month">
					#svgIcon(name="chevron-left", size=16)#
				</button>
				<h2 class="ev-calendar-month-title" id="calMonthYearLabel" aria-live="polite">Loading...</h2>
				<button type="button" id="btnCalNext" class="btn btn-outline btn-sm" aria-label="Next Month">
					#svgIcon(name="chevron-right", size=16)#
				</button>
				<button type="button" id="btnCalToday" class="btn btn-outline btn-sm" style="margin-left:0.35rem;">
					Today
				</button>
			</div>

			<div class="ev-category-legend" aria-label="Category color legend">
				<cfloop array="#catsArr#" index="cat">
					<button type="button" class="ev-legend-pill js-legend-filter" data-cat-id="#cat.id#" title="Filter by #EncodeForHTMLAttribute(cat.name)#">
						<span class="ev-legend-dot" style="background:#EncodeForHTMLAttribute(cat.color)#;"></span>
						<span>#EncodeForHTML(cat.name)#</span>
					</button>
				</cfloop>
			</div>
		</div>

		<div class="ev-weekdays-row" role="row">
			<div class="ev-weekday-cell" role="columnheader">Sun</div>
			<div class="ev-weekday-cell" role="columnheader">Mon</div>
			<div class="ev-weekday-cell" role="columnheader">Tue</div>
			<div class="ev-weekday-cell" role="columnheader">Wed</div>
			<div class="ev-weekday-cell" role="columnheader">Thu</div>
			<div class="ev-weekday-cell" role="columnheader">Fri</div>
			<div class="ev-weekday-cell" role="columnheader">Sat</div>
		</div>

		<div class="ev-days-grid" id="calDaysGrid" role="grid" aria-label="Calendar days">
			<!--- Populated dynamically by JS --->
		</div>
	</div>
</section>

<!--- ===================================================================== --->
<!--- VIEW 2: EVENTS LIST TABLE                                             --->
<!--- ===================================================================== --->
<section id="viewPanelList" aria-label="Events List Table" style="display:none;">
	<div class="admin-card">
		<div class="table-responsive">
			<table class="admin-table" id="eventsListTable" aria-label="County calendar events">
				<thead>
					<tr>
						<th scope="col" style="width:110px;">Actions</th>
						<th scope="col" style="width:165px;">Date &amp; Time</th>
						<th scope="col">Event &amp; Summary</th>
						<th scope="col">Category &amp; Dept</th>
						<th scope="col">Location / Virtual / Packet</th>
						<th scope="col" style="text-align:center;">Status</th>
					</tr>
				</thead>
				<tbody id="eventsTableBody">
					<cfloop array="#eventsArr#" index="ev">
						<cfset evStartObj = IsDate(ev.startDate) ? ParseDateTime(ev.startDate) : Now()>
						<cfset evMonthAbbr = DateFormat(evStartObj, "mmm")>
						<cfset evDayNum = DateFormat(evStartObj, "dd")>
						<cfset evSearchBlob = LCase(ev.title & " " & ev.summary & " " & ev.locationName & " " & ev.roomNumber & " " & ev.categoryName & " " & ev.workspaceName)>
						<tr class="ev-table-row"
							data-id="#ev.id#"
							data-search="#EncodeForHTMLAttribute(evSearchBlob)#"
							data-category="#ev.categoryId#"
							data-workspace="#EncodeForHTMLAttribute(LCase(ev.siteId))#"
							data-status="#EncodeForHTMLAttribute(ev.status)#"
							data-start="#EncodeForHTMLAttribute(ev.startDate)#"
							data-end="#EncodeForHTMLAttribute(ev.endDate)#">
							<td>
								<div style="display:flex; gap:0.25rem; align-items:center;">
									<button type="button" class="btn btn-sm btn-icon-only btn-outline js-inspect-event" data-id="#ev.id#" aria-label="View details for #EncodeForHTMLAttribute(ev.title)#" title="View Event Details">
										#svgIcon(name="eye", size=14)#
									</button>
									<button type="button" class="btn btn-sm btn-icon-only btn-outline js-edit-event" data-id="#ev.id#" aria-label="Edit #EncodeForHTMLAttribute(ev.title)#" title="Edit Event">
										#svgIcon(name="edit", size=14)#
									</button>
									<button type="button" class="btn btn-sm btn-icon-only btn-outline js-delete-event" data-id="#ev.id#" data-title="#EncodeForHTMLAttribute(ev.title)#" aria-label="Delete #EncodeForHTMLAttribute(ev.title)#" title="Delete Event" style="color:var(--admin-danger);">
										#svgIcon(name="trash", size=14)#
									</button>
								</div>
							</td>
							<td>
								<div style="display:flex; align-items:center; gap:0.65rem;">
									<div class="ev-date-badge">
										<span class="ev-date-badge-month">#evMonthAbbr#</span>
										<span class="ev-date-badge-day">#evDayNum#</span>
									</div>
									<div style="font-size:0.78rem; line-height:1.35;">
										<div style="font-weight:700; color:var(--admin-text-main);">#DateFormat(evStartObj, "ddd, mmm d, yyyy")#</div>
										<cfif ev.endDate neq ev.startDate>
											<div style="color:var(--admin-primary); font-weight:600;">thru #DateFormat(ParseDateTime(ev.endDate), "mmm d, yyyy")#</div>
										</cfif>
										<div style="color:var(--admin-text-muted);">
											<cfif ev.isAllDay>
												All-Day Event
											<cfelseif Len(ev.startTime)>
												#EncodeForHTML(ev.startTime)#<cfif Len(ev.endTime)> &ndash; #EncodeForHTML(ev.endTime)#</cfif>
											<cfelse>
												Time TBD
											</cfif>
										</div>
									</div>
								</div>
							</td>
							<td>
								<div style="display:flex; align-items:center; gap:0.4rem; flex-wrap:wrap;">
									<a href="javascript:void(0)" class="js-edit-event" data-id="#ev.id#" style="font-weight:700; color:var(--admin-text-main); text-decoration:none;">
										#EncodeForHTML(ev.title)#
									</a>
									<cfif ev.isFeatured>
										<span class="badge badge-primary" style="font-size:0.65rem;">Featured</span>
									</cfif>
									<cfif ev.isPublicNotice>
										<span class="badge badge-warning" style="font-size:0.65rem;">Public Notice</span>
									</cfif>
								</div>
								<cfif Len(ev.summary)>
									<div style="font-size:0.78rem; color:var(--admin-text-muted); margin-top:0.2rem; line-height:1.4;">
										#EncodeForHTML(ev.summary)#
									</div>
								</cfif>
							</td>
							<td>
								<div style="display:flex; flex-direction:column; gap:0.3rem; align-items:flex-start;">
									<span class="badge #ev.categoryBadge#" style="display:inline-flex; align-items:center; gap:0.3rem;">
										<span style="width:7px; height:7px; border-radius:50%; background:#EncodeForHTMLAttribute(ev.categoryColor)#; display:inline-block;"></span>
										#EncodeForHTML(ev.categoryName)#
									</span>
									<span class="badge #ev.workspaceBadgeClass#" style="font-size:0.68rem;">
										#EncodeForHTML(ev.workspaceName)#
									</span>
								</div>
							</td>
							<td>
								<div style="font-size:0.78rem; display:flex; flex-direction:column; gap:0.25rem;">
									<cfif Len(ev.locationName)>
										<div style="color:var(--admin-text-main); font-weight:600; display:flex; align-items:center; gap:0.3rem;">
											#svgIcon(name="map-pin", size=13)#
											<span>#EncodeForHTML(ev.locationName)#<cfif Len(ev.roomNumber)> &bull; #EncodeForHTML(ev.roomNumber)#</cfif></span>
										</div>
									</cfif>
									<div style="display:flex; align-items:center; gap:0.4rem; flex-wrap:wrap;">
										<cfif Len(ev.virtualMeetingUrl)>
											<a href="#EncodeForHTMLAttribute(ev.virtualMeetingUrl)#" target="_blank" rel="noopener" class="badge badge-info" style="text-decoration:none; display:inline-flex; align-items:center; gap:0.25rem; font-size:0.68rem;">
												#svgIcon(name="video", size=12)# Virtual Link
											</a>
										</cfif>
										<cfif Len(ev.agendaUrl)>
											<a href="#EncodeForHTMLAttribute(ev.agendaUrl)#" target="_blank" rel="noopener" class="badge badge-neutral" style="text-decoration:none; display:inline-flex; align-items:center; gap:0.25rem; font-size:0.68rem;">
												#svgIcon(name="paperclip", size=12)# Agenda / Packet
											</a>
										</cfif>
										<a href="#exportIcsUrl#?id=#ev.id#" class="badge badge-neutral" style="text-decoration:none; display:inline-flex; align-items:center; gap:0.25rem; font-size:0.68rem;" title="Download .ICS for this event">
											#svgIcon(name="calendar", size=11)# .ICS
										</a>
									</div>
								</div>
							</td>
							<td style="text-align:center;">
								<cfif ev.status eq "Published">
									<span class="badge badge-success">Published</span>
								<cfelseif ev.status eq "Scheduled">
									<span class="badge badge-info" style="background:##0284c7; color:##fff;">Scheduled</span>
								<cfelseif ev.status eq "Draft">
									<span class="badge badge-neutral">Draft</span>
								<cfelseif ev.status eq "Postponed">
									<span class="badge badge-warning">Postponed</span>
								<cfelseif ev.status eq "Archived">
									<span class="badge badge-neutral" style="background:var(--admin-border);">Archived</span>
								<cfelse>
									<span class="badge badge-danger">#EncodeForHTML(ev.status)#</span>
								</cfif>
							</td>
						</tr>
					</cfloop>
					<tr id="evListNoResults" style="display:#(ArrayLen(eventsArr) eq 0 ? '' : 'none')#;">
						<td colspan="6" style="text-align:center; padding:2.75rem 1.5rem; color:var(--admin-text-muted);">
							No calendar events match your current filters.
						</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>
</section>

<!--- ===================================================================== --->
<!--- VIEW 3: PUBLIC COUNTY CALENDAR PREVIEW                                --->
<!--- ===================================================================== --->
<section id="viewPanelPreview" aria-label="Public Calendar Preview" style="display:none;">
	<div class="admin-card" style="border-top:4px solid var(--admin-primary);">
		<div class="card-body" style="padding:1.5rem;">
			<div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1rem; padding-bottom:1.15rem; border-bottom:1px solid var(--admin-border-subtle); margin-bottom:1.25rem;">
				<div>
					<div style="font-size:0.75rem; font-weight:700; text-transform:uppercase; letter-spacing:0.06em; color:var(--admin-primary);">
						Chelan County Public Portal Preview
					</div>
					<h2 style="margin:0.2rem 0 0 0; font-size:1.35rem; font-weight:800; color:var(--admin-text-main);">
						Chelan County Calendar of Events &amp; Public Meetings
					</h2>
					<p style="margin:0.25rem 0 0 0; font-size:0.875rem; color:var(--admin-text-muted);">
						Board of Commissioners sessions, public hearings, advisory boards, civic deadlines, and community events.
					</p>
				</div>
				<a href="#exportIcsUrl#" class="btn btn-outline btn-sm">
					#svgIcon(name="calendar", size=15)#
					<span>Subscribe / Download County .ICS</span>
				</a>
			</div>

			<div id="publicPreviewCardsContainer" style="display:grid; grid-template-columns:repeat(auto-fill, minmax(360px, 1fr)); gap:1rem;">
				<!--- Rendered by JS from filtered published events --->
			</div>
		</div>
	</div>
</section>

<!--- ===================================================================== --->
<!--- MODAL 1: ADD / EDIT CALENDAR EVENT                                    --->
<!--- ===================================================================== --->
<div id="eventModalBackdrop" class="ev-modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="eventModalTitle">
	<div class="ev-modal-dialog">
		<div class="ev-modal-header">
			<h2 id="eventModalTitle" class="ev-modal-title">
				#svgIcon(name="calendar", size=20)#
				<span id="eventModalTitleText">Add County Calendar Event</span>
			</h2>
			<button type="button" id="btnCloseEventModal" class="admin-modal-close" aria-label="Close dialog" style="background:transparent; border:none; font-size:1.5rem; cursor:pointer; color:var(--admin-text-muted);">&times;</button>
		</div>

		<form id="eventForm" class="ev-modal-body" onsubmit="return false;" novalidate>
			<input type="hidden" id="evId" value="0">

			<!--- Section 1: Event Classification & Title --->
			<div class="ev-section-box">
				<h3 class="ev-section-box-title">
					#svgIcon(name="file-text", size=15)#
					<span>1. Event Title, Category &amp; Department</span>
				</h3>

				<div style="display:grid; grid-template-columns:repeat(12, 1fr); gap:0.9rem;">
					<div style="grid-column: span 12;">
						<label for="evTitle" class="form-label" style="font-weight:600;">
							Event Title <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
							<span class="sr-only">(required)</span>
						</label>
						<input type="text" id="evTitle" class="form-control" placeholder="e.g., Board of County Commissioners Regular Legislative Session" required aria-required="true">
					</div>

					<div style="grid-column: span 5;">
						<label for="evCategoryId" class="form-label" style="font-weight:600;">
							Event Category <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<select id="evCategoryId" class="form-control" required aria-required="true">
							<cfloop array="#catsArr#" index="cat">
								<option value="#cat.id#">#EncodeForHTML(cat.name)#</option>
							</cfloop>
						</select>
					</div>

					<div style="grid-column: span 4;">
						<label for="evSiteId" class="form-label" style="font-weight:600;">
							Department / Workspace <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<select id="evSiteId" class="form-control" required aria-required="true">
							<option value="global">County-Wide (All Workspaces)</option>
							<cfloop array="#wsListArr#" index="ws">
								<cfif ws.id neq "global">
									<option value="#EncodeForHTMLAttribute(ws.id)#" <cfif LCase(ws.id) eq LCase(activeWsId)>selected</cfif>>#EncodeForHTML(ws.name)#</option>
								</cfif>
							</cfloop>
						</select>
					</div>

					<div style="grid-column: span 3;">
						<label for="evStatus" class="form-label" style="font-weight:600;">Status</label>
						<select id="evStatus" class="form-control">
							<option value="Published">Published</option>
							<option value="Scheduled">Scheduled (Auto-Publish)</option>
							<option value="Draft">Draft</option>
							<option value="Postponed">Postponed</option>
							<option value="Cancelled">Cancelled</option>
							<option value="Archived">Archived</option>
						</select>
					</div>

					<div style="grid-column: span 12;">
						<label for="evSummary" class="form-label" style="font-weight:600;">Short Summary / Digest</label>
						<input type="text" id="evSummary" class="form-control" maxlength="500" placeholder="Brief 1-2 sentence overview shown on calendar cards and homepage feed...">
					</div>

					<div style="grid-column: span 12;">
						<label for="evDescription" class="form-label" style="font-weight:600;">Full Event Description / Public Hearing Notice Details</label>
						<textarea id="evDescription" class="form-control" rows="3" placeholder="Provide agenda highlights, public comment instructions, or event details..."></textarea>
					</div>

					<div style="grid-column: span 12; display:flex; gap:1.5rem; flex-wrap:wrap; padding-top:0.25rem;">
						<label style="display:inline-flex; align-items:center; gap:0.45rem; font-size:0.85rem; font-weight:600; cursor:pointer;">
							<input type="checkbox" id="evIsFeatured">
							<span>Feature on County Homepage Spotlight</span>
						</label>
						<label style="display:inline-flex; align-items:center; gap:0.45rem; font-size:0.85rem; font-weight:600; cursor:pointer;">
							<input type="checkbox" id="evIsPublicNotice">
							<span>Official Public Hearing / Legal Notice Flag</span>
						</label>
					</div>
				</div>
			</div>

			<!--- Section 2: Date & Time --->
			<div class="ev-section-box">
				<div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:0.5rem; margin-bottom:0.85rem;">
					<h3 class="ev-section-box-title" style="margin:0;">
						#svgIcon(name="clock", size=15)#
						<span>2. Date &amp; Schedule</span>
					</h3>
					<div style="display:flex; gap:0.35rem; flex-wrap:wrap;">
						<button type="button" class="ev-preset-pill js-time-preset" data-allday="0" data-start="09:00 AM" data-end="11:30 AM">9:00 AM &ndash; 11:30 AM</button>
						<button type="button" class="ev-preset-pill js-time-preset" data-allday="0" data-start="01:30 PM" data-end="03:30 PM">1:30 PM &ndash; 3:30 PM</button>
						<button type="button" class="ev-preset-pill js-time-preset" data-allday="0" data-start="06:00 PM" data-end="08:00 PM">6:00 PM &ndash; 8:00 PM</button>
						<button type="button" class="ev-preset-pill js-time-preset" data-allday="1" data-start="" data-end="">All-Day Event</button>
					</div>
				</div>

				<div style="display:grid; grid-template-columns:repeat(12, 1fr); gap:0.9rem; align-items:end;">
					<div style="grid-column: span 3;">
						<label for="evStartDate" class="form-label" style="font-weight:600;">
							Start Date <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<input type="date" id="evStartDate" class="form-control" required aria-required="true">
					</div>

					<div style="grid-column: span 3;">
						<label for="evEndDate" class="form-label" style="font-weight:600;">
							End Date <span style="color:var(--admin-danger);" aria-hidden="true">*</span>
						</label>
						<input type="date" id="evEndDate" class="form-control" required aria-required="true">
					</div>

					<div style="grid-column: span 2; padding-bottom:0.5rem;">
						<label style="display:inline-flex; align-items:center; gap:0.45rem; font-size:0.85rem; font-weight:600; cursor:pointer;">
							<input type="checkbox" id="evIsAllDay">
							<span>All-Day</span>
						</label>
					</div>

					<div style="grid-column: span 2;" id="evStartTimeWrap">
						<label for="evStartTime" class="form-label" style="font-weight:600;">Start Time</label>
						<input type="text" id="evStartTime" class="form-control" placeholder="09:00 AM">
					</div>

					<div style="grid-column: span 2;" id="evEndTimeWrap">
						<label for="evEndTime" class="form-label" style="font-weight:600;">End Time</label>
						<input type="text" id="evEndTime" class="form-control" placeholder="11:30 AM">
					</div>

					<div style="grid-column: span 6; border-top:1px dashed var(--admin-border); padding-top:0.75rem;">
						<label for="evPublishAt" class="form-label" style="font-weight:600; display:flex; align-items:center; gap:0.4rem;">
							<span>Publish At (Automated Release)</span>
							<span style="font-size:0.72rem; color:var(--admin-text-muted); font-weight:normal;">Leave blank to publish immediately</span>
						</label>
						<input type="datetime-local" id="evPublishAt" class="form-control">
					</div>

					<div style="grid-column: span 6; border-top:1px dashed var(--admin-border); padding-top:0.75rem;">
						<label for="evUnpublishAt" class="form-label" style="font-weight:600; display:flex; align-items:center; gap:0.4rem;">
							<span>Unpublish / Archive At (Automatic Expiration)</span>
							<span style="font-size:0.72rem; color:var(--admin-text-muted); font-weight:normal;">Leave blank for indefinite</span>
						</label>
						<input type="datetime-local" id="evUnpublishAt" class="form-control">
					</div>
				</div>
			</div>

			<!--- Section 3: Location & Virtual Meeting (Zoom / Teams) --->
			<div class="ev-section-box">
				<div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:0.5rem; margin-bottom:0.85rem;">
					<h3 class="ev-section-box-title" style="margin:0;">
						#svgIcon(name="map-pin", size=15)#
						<span>3. Location, Meeting Room &amp; Virtual Access</span>
					</h3>
					<div style="display:flex; gap:0.35rem; flex-wrap:wrap;">
						<button type="button" class="ev-preset-pill js-loc-preset"
							data-loc="Chelan County Administration Building"
							data-room="Commissioners Chambers, Suite 201"
							data-addr="400 Douglas Street, Wenatchee, WA 98801">BOCC Chambers (400 Douglas)</button>
						<button type="button" class="ev-preset-pill js-loc-preset"
							data-loc="Community Development Conference Center"
							data-room="Suite 301 Hearing Room"
							data-addr="316 Washington Street, Wenatchee, WA 98801">Comm. Dev (316 Washington)</button>
						<button type="button" class="ev-preset-pill js-loc-preset"
							data-loc="Chelan County Courthouse"
							data-room="Level 3"
							data-addr="350 Orondo Avenue, Wenatchee, WA 98801">Courthouse (350 Orondo)</button>
						<button type="button" class="ev-preset-pill js-loc-preset"
							data-loc="Chelan County Expo Center &amp; Fairgrounds"
							data-room="Main Exhibition Hall"
							data-addr="5700 Wescott Drive, Cashmere, WA 98815">Expo Center</button>
					</div>
				</div>

				<div style="display:grid; grid-template-columns:repeat(12, 1fr); gap:0.9rem;">
					<div style="grid-column: span 5;">
						<label for="evLocationName" class="form-label" style="font-weight:600;">Building / Location Name</label>
						<input type="text" id="evLocationName" class="form-control" placeholder="e.g., Chelan County Administration Building">
					</div>

					<div style="grid-column: span 3;">
						<label for="evRoomNumber" class="form-label" style="font-weight:600;">Room / Suite</label>
						<input type="text" id="evRoomNumber" class="form-control" placeholder="e.g., Chambers Suite 201">
					</div>

					<div style="grid-column: span 4;">
						<label for="evLocationAddress" class="form-label" style="font-weight:600;">Street Address</label>
						<input type="text" id="evLocationAddress" class="form-control" placeholder="400 Douglas Street, Wenatchee, WA 98801">
					</div>

					<div style="grid-column: span 7;">
						<label for="evVirtualUrl" class="form-label" style="font-weight:600;">Virtual Meeting Link (Zoom / Microsoft Teams)</label>
						<input type="url" id="evVirtualUrl" class="form-control" placeholder="https://us02web.zoom.us/j/...">
					</div>

					<div style="grid-column: span 5;">
						<label for="evVirtualId" class="form-label" style="font-weight:600;">Meeting ID / Passcode / Dial-In</label>
						<input type="text" id="evVirtualId" class="form-control" placeholder="Meeting ID: 890 4002 0100 / Passcode: 98801">
					</div>
				</div>
			</div>

			<!--- Section 4: Agenda Packet, Minutes & Contact Info --->
			<div class="ev-section-box" style="margin-bottom:0;">
				<h3 class="ev-section-box-title">
					#svgIcon(name="paperclip", size=15)#
					<span>4. Agenda Packet, Attachments &amp; Staff Contact</span>
				</h3>

				<div style="display:grid; grid-template-columns:repeat(12, 1fr); gap:0.9rem;">
					<div style="grid-column: span 6;">
						<label for="evAgendaUrl" class="form-label" style="font-weight:600;">Agenda / Packet Attachment URL</label>
						<div style="display:flex; gap:0.4rem;">
							<input type="text" id="evAgendaUrl" class="form-control" placeholder="/files/commissioners/agendas/agenda-packet.pdf" style="flex:1;">
							<button type="button" id="btnPickAgendaMedia" class="btn btn-outline btn-sm" title="Browse Media Library">
								#svgIcon(name="folder", size=14)#
								<span>Browse</span>
							</button>
						</div>
					</div>

					<div style="grid-column: span 6;">
						<label for="evMinutesUrl" class="form-label" style="font-weight:600;">Minutes / Recording URL (Optional)</label>
						<input type="text" id="evMinutesUrl" class="form-control" placeholder="/files/commissioners/minutes/minutes.pdf">
					</div>

					<div style="grid-column: span 4;">
						<label for="evContactName" class="form-label" style="font-weight:600;">Contact Person / Clerk</label>
						<input type="text" id="evContactName" class="form-control" placeholder="e.g., Clerk of the Board">
					</div>

					<div style="grid-column: span 4;">
						<label for="evContactEmail" class="form-label" style="font-weight:600;">Contact Email</label>
						<input type="email" id="evContactEmail" class="form-control" placeholder="bocc.clerk@chelancounty.gov">
					</div>

					<div style="grid-column: span 4;">
						<label for="evContactPhone" class="form-label" style="font-weight:600;">Contact Phone</label>
						<input type="tel" id="evContactPhone" class="form-control" placeholder="509-667-6215">
					</div>
				</div>
			</div>
		</form>

		<div class="ev-modal-footer">
			<div>
				<button type="button" id="btnDeleteFromModal" class="btn btn-outline btn-sm" style="color:var(--admin-danger); border-color:var(--admin-danger); display:none;">
					#svgIcon(name="trash", size=14)#
					<span>Delete Event</span>
				</button>
			</div>
			<div style="display:flex; gap:0.6rem;">
				<button type="button" id="btnCancelEventModal" class="btn btn-outline btn-sm">Cancel</button>
				<button type="button" id="btnSaveEvent" class="btn btn-primary btn-sm">
					#svgIcon(name="save", size=15)#
					<span id="btnSaveEventLabel">Save Event</span>
				</button>
			</div>
		</div>
	</div>
</div>

<!--- ===================================================================== --->
<!--- MODAL 2: EVENT QUICK INSPECTOR                                        --->
<!--- ===================================================================== --->
<div id="eventInspectorBackdrop" class="ev-modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="inspectorTitle">
	<div class="ev-modal-dialog" style="max-width:620px;">
		<div class="ev-modal-header">
			<h2 id="inspectorTitle" class="ev-modal-title">Event Details</h2>
			<button type="button" id="btnCloseInspector" class="admin-modal-close" aria-label="Close inspector" style="background:transparent; border:none; font-size:1.5rem; cursor:pointer; color:var(--admin-text-muted);">&times;</button>
		</div>
		<div class="ev-modal-body" id="inspectorBodyContent">
			<!--- Populated by JS --->
		</div>
		<div class="ev-modal-footer">
			<a href="##" id="inspectorIcsLink" class="btn btn-outline btn-sm">
				#svgIcon(name="calendar", size=14)#
				<span>Download .ICS</span>
			</a>
			<div style="display:flex; gap:0.5rem;">
				<button type="button" id="btnInspectorDelete" class="btn btn-outline btn-sm" style="color:var(--admin-danger);">
					#svgIcon(name="trash", size=14)#
					<span>Delete</span>
				</button>
				<button type="button" id="btnInspectorEdit" class="btn btn-primary btn-sm">
					#svgIcon(name="edit", size=14)#
					<span>Edit Event</span>
				</button>
			</div>
		</div>
	</div>
</div>

<!--- ===================================================================== --->
<!--- MODAL 3: MANAGE EVENT CATEGORIES                                      --->
<!--- ===================================================================== --->
<div id="categoriesModalBackdrop" class="ev-modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="categoriesModalTitle">
	<div class="ev-modal-dialog" style="max-width:720px;">
		<div class="ev-modal-header">
			<h2 id="categoriesModalTitle" class="ev-modal-title">
				#svgIcon(name="tag", size=19)#
				<span>Manage Calendar Event Categories</span>
			</h2>
			<button type="button" id="btnCloseCategoriesModal" class="admin-modal-close" aria-label="Close dialog" style="background:transparent; border:none; font-size:1.5rem; cursor:pointer; color:var(--admin-text-muted);">&times;</button>
		</div>
		<div class="ev-modal-body">
			<div class="ev-section-box">
				<h3 class="ev-section-box-title" id="catFormHeading">Add / Edit Category</h3>
				<input type="hidden" id="catEditId" value="0">
				<div style="display:grid; grid-template-columns:repeat(12, 1fr); gap:0.75rem; align-items:end;">
					<div style="grid-column: span 5;">
						<label for="catEditName" class="form-label" style="font-size:0.8rem; font-weight:600;">Category Name *</label>
						<input type="text" id="catEditName" class="form-control" placeholder="e.g., Parks &amp; Trails Event">
					</div>
					<div style="grid-column: span 3;">
						<label for="catEditColor" class="form-label" style="font-size:0.8rem; font-weight:600;">Calendar Color</label>
						<input type="color" id="catEditColor" class="form-control" value="##0284c7" style="height:38px; padding:0.2rem;">
					</div>
					<div style="grid-column: span 4;">
						<label for="catEditBadge" class="form-label" style="font-size:0.8rem; font-weight:600;">Badge Style</label>
						<select id="catEditBadge" class="form-control">
							<option value="badge-info">Info (Blue)</option>
							<option value="badge-warning">Warning (Amber)</option>
							<option value="badge-purple">Purple</option>
							<option value="badge-success">Success (Green)</option>
							<option value="badge-danger">Danger (Red)</option>
							<option value="badge-neutral">Neutral (Slate)</option>
						</select>
					</div>
					<div style="grid-column: span 9;">
						<label for="catEditDesc" class="form-label" style="font-size:0.8rem; font-weight:600;">Description</label>
						<input type="text" id="catEditDesc" class="form-control" placeholder="Short description of events in this category...">
					</div>
					<div style="grid-column: span 3; display:flex; gap:0.4rem;">
						<button type="button" id="btnSaveCategory" class="btn btn-primary btn-sm" style="flex:1; height:38px;">Save</button>
						<button type="button" id="btnResetCategoryForm" class="btn btn-outline btn-sm" style="height:38px;">Clear</button>
					</div>
				</div>
			</div>

			<div class="table-responsive">
				<table class="admin-table" aria-label="Event Categories">
					<thead>
						<tr>
							<th scope="col">Category</th>
							<th scope="col">Description</th>
							<th scope="col" style="text-align:center;">Events</th>
							<th scope="col" style="width:95px; text-align:right;">Actions</th>
						</tr>
					</thead>
					<tbody>
						<cfloop array="#catsArr#" index="cat">
							<tr>
								<td>
									<span class="badge #cat.badgeClass#" style="display:inline-flex; align-items:center; gap:0.35rem;">
										<span style="width:8px; height:8px; border-radius:50%; background:#EncodeForHTMLAttribute(cat.color)#; display:inline-block;"></span>
										#EncodeForHTML(cat.name)#
									</span>
								</td>
								<td style="font-size:0.8rem; color:var(--admin-text-muted);">#EncodeForHTML(cat.description)#</td>
								<td style="text-align:center; font-weight:700;">#cat.totalEvents#</td>
								<td style="text-align:right;">
									<button type="button" class="btn btn-sm btn-icon-only btn-outline js-edit-cat"
										data-id="#cat.id#"
										data-name="#EncodeForHTMLAttribute(cat.name)#"
										data-color="#EncodeForHTMLAttribute(cat.color)#"
										data-badge="#EncodeForHTMLAttribute(cat.badgeClass)#"
										data-desc="#EncodeForHTMLAttribute(cat.description)#"
										title="Edit Category" aria-label="Edit #EncodeForHTMLAttribute(cat.name)#">
										#svgIcon(name="edit", size=13)#
									</button>
									<cfif not cat.isSystem>
										<button type="button" class="btn btn-sm btn-icon-only btn-outline js-delete-cat"
											data-id="#cat.id#"
											data-name="#EncodeForHTMLAttribute(cat.name)#"
											title="Delete Category" aria-label="Delete #EncodeForHTMLAttribute(cat.name)#" style="color:var(--admin-danger);">
											#svgIcon(name="trash", size=13)#
										</button>
									</cfif>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</div>
	</div>
</div>

<script>
(function () {
	var rawEvents = #SerializeJSON(eventsArr)#;
	var rawCategories = #SerializeJSON(catsArr)#;
	var endpoints = {
		saveEvent: "#JSStringFormat(saveEventUrl)#",
		deleteEvent: "#JSStringFormat(deleteEventUrl)#",
		saveCategory: "#JSStringFormat(saveCategoryUrl)#",
		deleteCategory: "#JSStringFormat(deleteCategoryUrl)#",
		exportIcs: "#JSStringFormat(exportIcsUrl)#",
		mediaPicker: "#JSStringFormat(mediaPickerUrl)#"
	};
	var defaultWorkspace = "#JSStringFormat(isGlobalSelected ? 'global' : activeWsId)#";
	var todayStr = "#JSStringFormat(todayStr)#";

	function getField(obj, key, fallback) {
		if (!obj || typeof obj !== "object") return fallback;
		if (obj[key] !== undefined && obj[key] !== null) return obj[key];
		var up = key.toUpperCase();
		if (obj[up] !== undefined && obj[up] !== null) return obj[up];
		var low = key.toLowerCase();
		if (obj[low] !== undefined && obj[low] !== null) return obj[low];
		return fallback;
	}

	function normalizeEvent(raw) {
		return {
			id: Number(getField(raw, "id", 0)),
			siteId: String(getField(raw, "siteId", "global")),
			workspaceName: String(getField(raw, "workspaceName", "County-Wide")),
			workspaceBadge: String(getField(raw, "workspaceBadge", "County")),
			workspaceBadgeClass: String(getField(raw, "workspaceBadgeClass", "badge-neutral")),
			categoryId: Number(getField(raw, "categoryId", 0)),
			categoryName: String(getField(raw, "categoryName", "Event")),
			categorySlug: String(getField(raw, "categorySlug", "event")),
			categoryColor: String(getField(raw, "categoryColor", "##0284c7")),
			categoryBadge: String(getField(raw, "categoryBadge", "badge-info")),
			title: String(getField(raw, "title", "")),
			slug: String(getField(raw, "slug", "")),
			summary: String(getField(raw, "summary", "")),
			description: String(getField(raw, "description", "")),
			startDate: String(getField(raw, "startDate", todayStr)).slice(0, 10),
			endDate: String(getField(raw, "endDate", todayStr)).slice(0, 10),
			startTime: String(getField(raw, "startTime", "")),
			endTime: String(getField(raw, "endTime", "")),
			isAllDay: Boolean(getField(raw, "isAllDay", false)),
			locationName: String(getField(raw, "locationName", "")),
			locationAddress: String(getField(raw, "locationAddress", "")),
			roomNumber: String(getField(raw, "roomNumber", "")),
			virtualMeetingUrl: String(getField(raw, "virtualMeetingUrl", "")),
			virtualMeetingId: String(getField(raw, "virtualMeetingId", "")),
			agendaUrl: String(getField(raw, "agendaUrl", "")),
			minutesUrl: String(getField(raw, "minutesUrl", "")),
			contactName: String(getField(raw, "contactName", "")),
			contactEmail: String(getField(raw, "contactEmail", "")),
			contactPhone: String(getField(raw, "contactPhone", "")),
			isFeatured: Boolean(getField(raw, "isFeatured", false)),
			isPublicNotice: Boolean(getField(raw, "isPublicNotice", false)),
			status: String(getField(raw, "status", "Published")),
			publishAt: String(getField(raw, "publishAt", "")),
			unpublishAt: String(getField(raw, "unpublishAt", ""))
		};
	}

	var events = (Array.isArray(rawEvents) ? rawEvents : []).map(normalizeEvent);
	var eventsById = {};
	events.forEach(function (ev) { eventsById[ev.id] = ev; });

	// Move modals to document.body so they overlay cleanly
	["eventModalBackdrop", "eventInspectorBackdrop", "categoriesModalBackdrop"].forEach(function (id) {
		var el = document.getElementById(id);
		if (el && el.parentNode !== document.body) {
			document.body.appendChild(el);
		}
	});

	function showAlert(title, message, type) {
		if (typeof window.adminAlert === "function") {
			return window.adminAlert(message, { title: title, type: type || "info" });
		}
		if (typeof window.showToast === "function") {
			window.showToast(message, type || "info");
		}
		return Promise.resolve();
	}

	function askConfirm(title, message, confirmText) {
		if (typeof window.adminConfirm === "function") {
			return window.adminConfirm(message, {
				title: title,
				type: "danger",
				destructive: true,
				acceptText: confirmText || "Delete",
				confirmText: confirmText || "Delete",
				cancelText: "Cancel"
			});
		}
		return Promise.resolve(false);
	}

	function postJson(url, payload) {
		var csrfMeta = document.querySelector('meta[name="csrf-token"]');
		var csrfToken = csrfMeta ? csrfMeta.getAttribute("content") : "";
		var headers = {
			"Content-Type": "application/json",
			"Accept": "application/json",
			"X-Requested-With": "XMLHttpRequest"
		};
		if (csrfToken) headers["X-CSRF-Token"] = csrfToken;

		return fetch(url, {
			method: "POST",
			headers: headers,
			credentials: "same-origin",
			body: JSON.stringify(payload)
		}).then(function (r) { return r.json(); });
	}

	function escapeHtml(str) {
		return String(str || "")
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;");
	}

	// Calendar State
	var nowDate = new Date();
	var currentYear = nowDate.getFullYear();
	var currentMonth = nowDate.getMonth(); // 0-indexed
	var monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

	// Filter Elements
	var searchInput = document.getElementById("evSearchInput");
	var categoryFilter = document.getElementById("evCategoryFilter");
	var workspaceFilter = document.getElementById("evWorkspaceFilter");
	var statusFilter = document.getElementById("evStatusFilter");
	var timeframeFilter = document.getElementById("evTimeframeFilter");
	var filterCountEl = document.getElementById("evFilterCount");

	function matchesFilters(ev) {
		var q = searchInput.value.trim().toLowerCase();
		var catVal = categoryFilter.value;
		var wsVal = workspaceFilter.value.toLowerCase();
		var stVal = statusFilter.value;
		var tfVal = timeframeFilter.value;

		if (q) {
			var blob = (ev.title + " " + ev.summary + " " + ev.locationName + " " + ev.roomNumber + " " + ev.categoryName + " " + ev.workspaceName).toLowerCase();
			if (blob.indexOf(q) === -1) return false;
		}
		if (catVal && String(ev.categoryId) !== String(catVal)) return false;
		if (wsVal && ev.siteId.toLowerCase() !== wsVal) return false;
		if (stVal && ev.status !== stVal) return false;

		if (tfVal === "upcoming" && ev.endDate < todayStr) return false;
		if (tfVal === "past" && ev.endDate >= todayStr) return false;
		if (tfVal === "month") {
			var ymPrefix = currentYear + "-" + String(currentMonth + 1).padStart(2, "0");
			if (ev.startDate.slice(0, 7) > ymPrefix || ev.endDate.slice(0, 7) < ymPrefix) return false;
		}
		return true;
	}

	function pad2(n) {
		return String(n).padStart(2, "0");
	}

	function formatYMD(y, m, d) {
		return y + "-" + pad2(m + 1) + "-" + pad2(d);
	}

	function renderCalendarGrid() {
		var labelEl = document.getElementById("calMonthYearLabel");
		var gridEl = document.getElementById("calDaysGrid");
		if (!labelEl || !gridEl) return;

		labelEl.textContent = monthNames[currentMonth] + " " + currentYear;

		var firstDayOfWeek = new Date(currentYear, currentMonth, 1).getDay();
		var daysInCurrentMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
		var daysInPrevMonth = new Date(currentYear, currentMonth, 0).getDate();

		var filteredEvents = events.filter(matchesFilters);
		var totalCells = Math.ceil((firstDayOfWeek + daysInCurrentMonth) / 7) * 7;
		var html = [];

		for (var i = 0; i < totalCells; i++) {
			var cellYear = currentYear;
			var cellMonth = currentMonth;
			var cellDay = 1;
			var isOutside = false;

			if (i < firstDayOfWeek) {
				isOutside = true;
				cellDay = daysInPrevMonth - firstDayOfWeek + 1 + i;
				if (currentMonth === 0) {
					cellMonth = 11;
					cellYear = currentYear - 1;
				} else {
					cellMonth = currentMonth - 1;
				}
			} else if (i >= firstDayOfWeek + daysInCurrentMonth) {
				isOutside = true;
				cellDay = i - (firstDayOfWeek + daysInCurrentMonth) + 1;
				if (currentMonth === 11) {
					cellMonth = 0;
					cellYear = currentYear + 1;
				} else {
					cellMonth = currentMonth + 1;
				}
			} else {
				cellDay = i - firstDayOfWeek + 1;
			}

			var dateStr = formatYMD(cellYear, cellMonth, cellDay);
			var isToday = (dateStr === todayStr);

			var dayEvents = filteredEvents.filter(function (ev) {
				return ev.startDate <= dateStr && ev.endDate >= dateStr;
			});

			var cellClasses = "ev-day-cell" + (isOutside ? " is-outside" : "") + (isToday ? " is-today" : "");
			var chipsHtml = dayEvents.map(function (ev) {
				var timeLabel = ev.isAllDay ? "All Day" : (ev.startTime ? ev.startTime.replace(":00", "") : "");
				var cancelledCls = (ev.status === "Cancelled") ? " is-cancelled" : "";
				return '<button type="button" class="ev-chip' + cancelledCls + ' js-inspect-event" data-id="' + ev.id + '" style="--chip-color:' + escapeHtml(ev.categoryColor) + ';" title="' + escapeHtml(ev.title + " (" + ev.categoryName + ")") + '">'
					+ (timeLabel ? '<span class="ev-chip-time">' + escapeHtml(timeLabel) + '</span>' : '')
					+ '<span class="ev-chip-title">' + escapeHtml(ev.title) + '</span>'
					+ '</button>';
			}).join("");

			html.push(
				'<div class="' + cellClasses + '" role="gridcell" data-date="' + dateStr + '">'
				+ '<div class="ev-day-top">'
				+ '<span class="ev-day-num">' + cellDay + '</span>'
				+ '<button type="button" class="ev-day-add-btn js-quick-add-date" data-date="' + dateStr + '" title="Add event on ' + dateStr + '" aria-label="Add event on ' + dateStr + '">+</button>'
				+ '</div>'
				+ '<div class="ev-day-events">' + chipsHtml + '</div>'
				+ '</div>'
			);
		}

		gridEl.innerHTML = html.join("");
	}

	function renderListAndPreview() {
		var shown = 0;
		var rows = document.querySelectorAll("##eventsListTable .ev-table-row");
		rows.forEach(function (row) {
			var id = Number(row.getAttribute("data-id"));
			var ev = eventsById[id];
			var ok = ev ? matchesFilters(ev) : false;
			row.style.display = ok ? "" : "none";
			if (ok) shown++;
		});

		var noRes = document.getElementById("evListNoResults");
		if (noRes) noRes.style.display = (shown === 0) ? "" : "none";
		if (filterCountEl) filterCountEl.textContent = "Showing " + shown + " of " + events.length + " events";

		// Public Preview Cards
		var previewContainer = document.getElementById("publicPreviewCardsContainer");
		if (previewContainer) {
			var pubEvents = events.filter(function (ev) {
				return ev.status !== "Draft" && matchesFilters(ev);
			});
			if (!pubEvents.length) {
				previewContainer.innerHTML = '<div style="grid-column:1/-1; text-align:center; padding:2.5rem; color:var(--admin-text-muted);">No published events match the current filter criteria.</div>';
			} else {
				previewContainer.innerHTML = pubEvents.map(function (ev) {
					var timeText = ev.isAllDay ? "All-Day Event" : (ev.startTime + (ev.endTime ? " - " + ev.endTime : ""));
					var locText = ev.locationName + (ev.roomNumber ? " (" + ev.roomNumber + ")" : "");
					return '<article style="border:1px solid var(--admin-border); border-left:4px solid ' + escapeHtml(ev.categoryColor) + '; border-radius:var(--radius-md); padding:1.1rem; background:##ffffff; display:flex; flex-direction:column; justify-content:space-between; gap:0.75rem;">'
						+ '<div>'
						+ '<div style="display:flex; justify-content:space-between; align-items:center; gap:0.5rem; margin-bottom:0.45rem;">'
						+ '<span class="badge ' + escapeHtml(ev.categoryBadge) + '">' + escapeHtml(ev.categoryName) + '</span>'
						+ '<span style="font-size:0.75rem; font-weight:700; color:var(--admin-text-muted);">' + escapeHtml(ev.startDate) + (ev.endDate !== ev.startDate ? ' to ' + escapeHtml(ev.endDate) : '') + '</span>'
						+ '</div>'
						+ '<h3 style="margin:0 0 0.35rem 0; font-size:1rem; font-weight:700; color:var(--admin-text-main);">' + escapeHtml(ev.title) + '</h3>'
						+ (ev.summary ? '<p style="margin:0 0 0.6rem 0; font-size:0.83rem; color:var(--admin-text-muted); line-height:1.45;">' + escapeHtml(ev.summary) + '</p>' : '')
						+ '<div style="font-size:0.78rem; color:var(--admin-text-main); display:flex; flex-direction:column; gap:0.2rem;">'
						+ '<div><strong>Time:</strong> ' + escapeHtml(timeText || "TBD") + '</div>'
						+ (locText ? '<div><strong>Location:</strong> ' + escapeHtml(locText) + '</div>' : '')
						+ '<div><strong>Department:</strong> ' + escapeHtml(ev.workspaceName) + '</div>'
						+ '</div>'
						+ '</div>'
						+ '<div style="display:flex; gap:0.45rem; flex-wrap:wrap; padding-top:0.65rem; border-top:1px solid var(--admin-border-subtle);">'
						+ (ev.virtualMeetingUrl ? '<a href="' + escapeHtml(ev.virtualMeetingUrl) + '" target="_blank" rel="noopener" class="btn btn-primary btn-sm" style="font-size:0.75rem; padding:0.25rem 0.6rem;">Join Virtual Meeting</a>' : '')
						+ (ev.agendaUrl ? '<a href="' + escapeHtml(ev.agendaUrl) + '" target="_blank" rel="noopener" class="btn btn-outline btn-sm" style="font-size:0.75rem; padding:0.25rem 0.6rem;">Agenda Packet</a>' : '')
						+ '<a href="' + endpoints.exportIcs + '?id=' + ev.id + '" class="btn btn-outline btn-sm" style="font-size:0.75rem; padding:0.25rem 0.6rem;">+ Add to Calendar (.ICS)</a>'
						+ '</div>'
						+ '</article>';
				}).join("");
			}
		}
	}

	function refreshAllViews() {
		renderCalendarGrid();
		renderListAndPreview();
	}

	// View Tab Switching
	var viewTabs = document.querySelectorAll(".ev-view-tab");
	var panels = {
		calendar: document.getElementById("viewPanelCalendar"),
		list: document.getElementById("viewPanelList"),
		preview: document.getElementById("viewPanelPreview")
	};

	viewTabs.forEach(function (tab) {
		tab.addEventListener("click", function () {
			var target = tab.getAttribute("data-view");
			viewTabs.forEach(function (t) {
				var active = (t.getAttribute("data-view") === target);
				t.classList.toggle("is-active", active);
				t.setAttribute("aria-selected", active ? "true" : "false");
			});
			Object.keys(panels).forEach(function (k) {
				if (panels[k]) panels[k].style.display = (k === target) ? "" : "none";
			});
		});
	});

	// Month Navigation
	document.getElementById("btnCalPrev").addEventListener("click", function () {
		currentMonth--;
		if (currentMonth < 0) { currentMonth = 11; currentYear--; }
		refreshAllViews();
	});
	document.getElementById("btnCalNext").addEventListener("click", function () {
		currentMonth++;
		if (currentMonth > 11) { currentMonth = 0; currentYear++; }
		refreshAllViews();
	});
	document.getElementById("btnCalToday").addEventListener("click", function () {
		var d = new Date();
		currentYear = d.getFullYear();
		currentMonth = d.getMonth();
		refreshAllViews();
	});

	// Legend Category Quick-Filter
	document.querySelectorAll(".js-legend-filter").forEach(function (btn) {
		btn.addEventListener("click", function () {
			var catId = btn.getAttribute("data-cat-id");
			if (categoryFilter.value === catId) {
				categoryFilter.value = "";
				btn.classList.remove("is-active");
			} else {
				categoryFilter.value = catId;
				document.querySelectorAll(".js-legend-filter").forEach(function (b) { b.classList.remove("is-active"); });
				btn.classList.add("is-active");
			}
			refreshAllViews();
		});
	});

	[searchInput, categoryFilter, workspaceFilter, statusFilter, timeframeFilter].forEach(function (el) {
		if (!el) return;
		el.addEventListener(el.tagName === "SELECT" ? "change" : "input", refreshAllViews);
	});

	document.getElementById("btnResetEvFilters").addEventListener("click", function () {
		searchInput.value = "";
		categoryFilter.value = "";
		workspaceFilter.value = "";
		statusFilter.value = "";
		timeframeFilter.value = "all";
		document.querySelectorAll(".js-legend-filter").forEach(function (b) { b.classList.remove("is-active"); });
		refreshAllViews();
	});

	// =========================================================================
	// Add / Edit Event Modal Logic
	// =========================================================================
	var eventModal = document.getElementById("eventModalBackdrop");
	var isAllDayCheck = document.getElementById("evIsAllDay");
	var startTimeWrap = document.getElementById("evStartTimeWrap");
	var endTimeWrap = document.getElementById("evEndTimeWrap");

	function syncAllDayVisibility() {
		var hideTimes = isAllDayCheck.checked;
		startTimeWrap.style.opacity = hideTimes ? "0.45" : "1";
		endTimeWrap.style.opacity = hideTimes ? "0.45" : "1";
		document.getElementById("evStartTime").disabled = hideTimes;
		document.getElementById("evEndTime").disabled = hideTimes;
	}
	isAllDayCheck.addEventListener("change", syncAllDayVisibility);

	document.getElementById("evStartDate").addEventListener("change", function () {
		var sVal = this.value;
		var eInput = document.getElementById("evEndDate");
		if (sVal && (!eInput.value || eInput.value < sVal)) {
			eInput.value = sVal;
		}
	});

	// Time & Location Presets
	document.querySelectorAll(".js-time-preset").forEach(function (btn) {
		btn.addEventListener("click", function () {
			var allDay = btn.getAttribute("data-allday") === "1";
			isAllDayCheck.checked = allDay;
			document.getElementById("evStartTime").value = btn.getAttribute("data-start") || "";
			document.getElementById("evEndTime").value = btn.getAttribute("data-end") || "";
			syncAllDayVisibility();
		});
	});

	document.querySelectorAll(".js-loc-preset").forEach(function (btn) {
		btn.addEventListener("click", function () {
			document.getElementById("evLocationName").value = btn.getAttribute("data-loc") || "";
			document.getElementById("evRoomNumber").value = btn.getAttribute("data-room") || "";
			document.getElementById("evLocationAddress").value = btn.getAttribute("data-addr") || "";
		});
	});

	function openEventModal(evObj, prefillDate) {
		var isEdit = Boolean(evObj && evObj.id > 0);
		document.getElementById("eventModalTitleText").textContent = isEdit ? "Edit County Calendar Event" : "Add County Calendar Event";
		document.getElementById("btnSaveEventLabel").textContent = isEdit ? "Update Event" : "Save Event";
		document.getElementById("btnDeleteFromModal").style.display = isEdit ? "" : "none";

		document.getElementById("evId").value = isEdit ? evObj.id : 0;
		document.getElementById("evTitle").value = isEdit ? evObj.title : "";
		document.getElementById("evCategoryId").value = isEdit ? evObj.categoryId : (rawCategories.length ? getField(rawCategories[0], "id", 1) : 1);
		document.getElementById("evSiteId").value = isEdit ? evObj.siteId : (defaultWorkspace || "global");
		document.getElementById("evStatus").value = isEdit ? evObj.status : "Published";
		document.getElementById("evSummary").value = isEdit ? evObj.summary : "";
		document.getElementById("evDescription").value = isEdit ? evObj.description : "";
		document.getElementById("evIsFeatured").checked = isEdit ? Boolean(evObj.isFeatured) : false;
		document.getElementById("evIsPublicNotice").checked = isEdit ? Boolean(evObj.isPublicNotice) : false;

		var initDate = prefillDate || (isEdit ? evObj.startDate : todayStr);
		document.getElementById("evStartDate").value = initDate;
		document.getElementById("evEndDate").value = isEdit ? evObj.endDate : initDate;
		isAllDayCheck.checked = isEdit ? Boolean(evObj.isAllDay) : false;
		document.getElementById("evStartTime").value = isEdit ? evObj.startTime : "09:00 AM";
		document.getElementById("evEndTime").value = isEdit ? evObj.endTime : "11:00 AM";
		syncAllDayVisibility();

		document.getElementById("evLocationName").value = isEdit ? evObj.locationName : "";
		document.getElementById("evRoomNumber").value = isEdit ? evObj.roomNumber : "";
		document.getElementById("evLocationAddress").value = isEdit ? evObj.locationAddress : "";
		document.getElementById("evVirtualUrl").value = isEdit ? evObj.virtualMeetingUrl : "";
		document.getElementById("evVirtualId").value = isEdit ? evObj.virtualMeetingId : "";
		document.getElementById("evAgendaUrl").value = isEdit ? evObj.agendaUrl : "";
		document.getElementById("evMinutesUrl").value = isEdit ? evObj.minutesUrl : "";
		document.getElementById("evContactName").value = isEdit ? evObj.contactName : "";
		document.getElementById("evContactEmail").value = isEdit ? evObj.contactEmail : "";
		document.getElementById("evContactPhone").value = isEdit ? evObj.contactPhone : "";
		document.getElementById("evPublishAt").value = (isEdit && evObj.publishAt) ? evObj.publishAt.slice(0, 16) : "";
		document.getElementById("evUnpublishAt").value = (isEdit && evObj.unpublishAt) ? evObj.unpublishAt.slice(0, 16) : "";

		eventModal.classList.add("is-open");
		setTimeout(function () { document.getElementById("evTitle").focus(); }, 50);
	}

	function closeEventModal() {
		eventModal.classList.remove("is-open");
	}

	document.getElementById("btnOpenAddEvent").addEventListener("click", function () {
		openEventModal(null, null);
	});
	document.getElementById("btnCloseEventModal").addEventListener("click", closeEventModal);
	document.getElementById("btnCancelEventModal").addEventListener("click", closeEventModal);

	// Save Event
	document.getElementById("btnSaveEvent").addEventListener("click", function () {
		var payload = {
			id: Number(document.getElementById("evId").value || 0),
			title: document.getElementById("evTitle").value.trim(),
			categoryId: Number(document.getElementById("evCategoryId").value || 0),
			siteId: document.getElementById("evSiteId").value,
			status: document.getElementById("evStatus").value,
			publish_at: document.getElementById("evPublishAt").value || "",
			unpublish_at: document.getElementById("evUnpublishAt").value || "",
			summary: document.getElementById("evSummary").value.trim(),
			description: document.getElementById("evDescription").value.trim(),
			isFeatured: document.getElementById("evIsFeatured").checked,
			isPublicNotice: document.getElementById("evIsPublicNotice").checked,
			startDate: document.getElementById("evStartDate").value,
			endDate: document.getElementById("evEndDate").value || document.getElementById("evStartDate").value,
			isAllDay: isAllDayCheck.checked,
			startTime: document.getElementById("evStartTime").value.trim(),
			endTime: document.getElementById("evEndTime").value.trim(),
			locationName: document.getElementById("evLocationName").value.trim(),
			roomNumber: document.getElementById("evRoomNumber").value.trim(),
			locationAddress: document.getElementById("evLocationAddress").value.trim(),
			virtualMeetingUrl: document.getElementById("evVirtualUrl").value.trim(),
			virtualMeetingId: document.getElementById("evVirtualId").value.trim(),
			agendaUrl: document.getElementById("evAgendaUrl").value.trim(),
			minutesUrl: document.getElementById("evMinutesUrl").value.trim(),
			contactName: document.getElementById("evContactName").value.trim(),
			contactEmail: document.getElementById("evContactEmail").value.trim(),
			contactPhone: document.getElementById("evContactPhone").value.trim()
		};

		if (!payload.title) {
			showAlert("Event Title Required", "Please enter a title for the calendar event.", "warning");
			return;
		}
		if (!payload.startDate) {
			showAlert("Start Date Required", "Please select a start date for the calendar event.", "warning");
			return;
		}

		var btn = document.getElementById("btnSaveEvent");
		btn.disabled = true;

		postJson(endpoints.saveEvent, payload)
			.then(function (res) {
				btn.disabled = false;
				var ok = Boolean(getField(res, "success", false));
				var msg = getField(res, "message", "Calendar event saved.");
				if (ok) {
					closeEventModal();
					if (typeof window.showToast === "function") window.showToast(msg, "success");
					setTimeout(function () { window.location.reload(); }, 350);
				} else {
					showAlert("Unable to Save Event", msg, "danger");
				}
			})
			.catch(function (err) {
				btn.disabled = false;
				showAlert("Network Error", "Could not save calendar event: " + err.message, "danger");
			});
	});

	function confirmAndDeleteEvent(eventId, eventTitle) {
		askConfirm(
			"Delete Calendar Event",
			"Are you sure you want to remove \"" + (eventTitle || "this event") + "\" from the county calendar?",
			"Delete Event"
		).then(function (confirmed) {
			if (!confirmed) return;
			postJson(endpoints.deleteEvent, { id: Number(eventId) })
				.then(function (res) {
					if (getField(res, "success", false)) {
						if (typeof window.showToast === "function") window.showToast("Calendar event deleted.", "success");
						setTimeout(function () { window.location.reload(); }, 300);
					} else {
						showAlert("Delete Failed", getField(res, "message", "Unable to delete event."), "danger");
					}
				});
		});
	}

	document.getElementById("btnDeleteFromModal").addEventListener("click", function () {
		var id = Number(document.getElementById("evId").value || 0);
		var title = document.getElementById("evTitle").value;
		if (id > 0) confirmAndDeleteEvent(id, title);
	});

	// =========================================================================
	// Event Quick Inspector Modal
	// =========================================================================
	var inspectorModal = document.getElementById("eventInspectorBackdrop");
	var inspectedEventId = 0;

	function openEventInspector(ev) {
		if (!ev) return;
		inspectedEventId = ev.id;
		document.getElementById("inspectorTitle").textContent = ev.title;
		document.getElementById("inspectorIcsLink").href = endpoints.exportIcs + "?id=" + ev.id;

		var timeLabel = ev.isAllDay ? "All-Day Event" : ((ev.startTime || "TBD") + (ev.endTime ? " - " + ev.endTime : ""));
		var dateLabel = ev.startDate + (ev.endDate !== ev.startDate ? " through " + ev.endDate : "");

		var html = '<div style="display:flex; flex-direction:column; gap:0.9rem;">'
			+ '<div style="display:flex; gap:0.5rem; flex-wrap:wrap; align-items:center;">'
			+ '<span class="badge ' + escapeHtml(ev.categoryBadge) + '">' + escapeHtml(ev.categoryName) + '</span>'
			+ '<span class="badge ' + escapeHtml(ev.workspaceBadgeClass) + '">' + escapeHtml(ev.workspaceName) + '</span>'
			+ '<span class="badge badge-neutral">' + escapeHtml(ev.status) + '</span>'
			+ (ev.isFeatured ? '<span class="badge badge-primary">Featured</span>' : '')
			+ (ev.isPublicNotice ? '<span class="badge badge-warning">Public Notice</span>' : '')
			+ '</div>'
			+ '<div class="ev-section-box" style="margin:0;">'
			+ '<div style="display:grid; grid-template-columns:120px 1fr; row-gap:0.5rem; font-size:0.86rem;">'
			+ '<div style="font-weight:700; color:var(--admin-text-muted);">Date:</div><div><strong>' + escapeHtml(dateLabel) + '</strong></div>'
			+ '<div style="font-weight:700; color:var(--admin-text-muted);">Time:</div><div>' + escapeHtml(timeLabel) + '</div>'
			+ (ev.locationName ? '<div style="font-weight:700; color:var(--admin-text-muted);">Location:</div><div>' + escapeHtml(ev.locationName) + (ev.roomNumber ? ' &bull; ' + escapeHtml(ev.roomNumber) : '') + '</div>' : '')
			+ (ev.locationAddress ? '<div style="font-weight:700; color:var(--admin-text-muted);">Address:</div><div>' + escapeHtml(ev.locationAddress) + '</div>' : '')
			+ (ev.virtualMeetingUrl ? '<div style="font-weight:700; color:var(--admin-text-muted);">Virtual Link:</div><div><a href="' + escapeHtml(ev.virtualMeetingUrl) + '" target="_blank" rel="noopener" style="font-weight:600; color:var(--admin-primary);">Join Online Meeting</a>' + (ev.virtualMeetingId ? ' <span style="color:var(--admin-text-muted);">(' + escapeHtml(ev.virtualMeetingId) + ')</span>' : '') + '</div>' : '')
			+ (ev.agendaUrl ? '<div style="font-weight:700; color:var(--admin-text-muted);">Agenda Packet:</div><div><a href="' + escapeHtml(ev.agendaUrl) + '" target="_blank" rel="noopener" style="font-weight:600; color:var(--admin-primary);">View / Download Agenda Packet</a></div>' : '')
			+ (ev.contactName || ev.contactEmail ? '<div style="font-weight:700; color:var(--admin-text-muted);">Contact:</div><div>' + escapeHtml(ev.contactName) + (ev.contactPhone ? ' &bull; ' + escapeHtml(ev.contactPhone) : '') + (ev.contactEmail ? ' &bull; ' + escapeHtml(ev.contactEmail) : '') + '</div>' : '')
			+ '</div>'
			+ '</div>'
			+ (ev.summary ? '<div><div style="font-size:0.78rem; font-weight:700; text-transform:uppercase; color:var(--admin-text-muted); margin-bottom:0.25rem;">Summary</div><p style="margin:0; font-size:0.9rem; line-height:1.5;">' + escapeHtml(ev.summary) + '</p></div>' : '')
			+ (ev.description ? '<div><div style="font-size:0.78rem; font-weight:700; text-transform:uppercase; color:var(--admin-text-muted); margin-bottom:0.25rem;">Details</div><div style="font-size:0.875rem; line-height:1.55; color:var(--admin-text-muted); white-space:pre-wrap;">' + escapeHtml(ev.description) + '</div></div>' : '')
			+ '</div>';

		document.getElementById("inspectorBodyContent").innerHTML = html;
		inspectorModal.classList.add("is-open");
	}

	document.getElementById("btnCloseInspector").addEventListener("click", function () {
		inspectorModal.classList.remove("is-open");
	});
	document.getElementById("btnInspectorEdit").addEventListener("click", function () {
		inspectorModal.classList.remove("is-open");
		if (inspectedEventId && eventsById[inspectedEventId]) {
			openEventModal(eventsById[inspectedEventId], null);
		}
	});
	document.getElementById("btnInspectorDelete").addEventListener("click", function () {
		inspectorModal.classList.remove("is-open");
		if (inspectedEventId && eventsById[inspectedEventId]) {
			confirmAndDeleteEvent(inspectedEventId, eventsById[inspectedEventId].title);
		}
	});

	// Delegated Clicks for Calendar Grid & List Table
	document.addEventListener("click", function (e) {
		var quickAddBtn = e.target.closest(".js-quick-add-date");
		if (quickAddBtn) {
			e.preventDefault();
			openEventModal(null, quickAddBtn.getAttribute("data-date"));
			return;
		}
		var inspectBtn = e.target.closest(".js-inspect-event");
		if (inspectBtn) {
			e.preventDefault();
			var ev = eventsById[Number(inspectBtn.getAttribute("data-id"))];
			if (ev) openEventInspector(ev);
			return;
		}
		var editBtn = e.target.closest(".js-edit-event");
		if (editBtn) {
			e.preventDefault();
			var evEdit = eventsById[Number(editBtn.getAttribute("data-id"))];
			if (evEdit) openEventModal(evEdit, null);
			return;
		}
		var delBtn = e.target.closest(".js-delete-event");
		if (delBtn) {
			e.preventDefault();
			confirmAndDeleteEvent(delBtn.getAttribute("data-id"), delBtn.getAttribute("data-title"));
			return;
		}
	});

	// Media Library Picker for Agenda URL
	document.getElementById("btnPickAgendaMedia").addEventListener("click", function () {
		var w = 1360, h = 820;
		var left = Math.max(0, (window.screen.width - w) / 2);
		var top = Math.max(0, (window.screen.height - h) / 2);
		window.open(endpoints.mediaPicker + "?targetInput=evAgendaUrl", "CMSMediaPicker", "width=" + w + ",height=" + h + ",left=" + left + ",top=" + top + ",resizable=yes,scrollbars=yes");
	});
	window.addEventListener("message", function (e) {
		if (e.data && e.data.type === "cmsMediaSelected" && e.data.url) {
			document.getElementById("evAgendaUrl").value = e.data.url;
		}
	});

	// =========================================================================
	// Manage Event Categories Modal
	// =========================================================================
	var categoriesModal = document.getElementById("categoriesModalBackdrop");
	document.getElementById("btnManageCategories").addEventListener("click", function () {
		categoriesModal.classList.add("is-open");
	});
	document.getElementById("btnCloseCategoriesModal").addEventListener("click", function () {
		categoriesModal.classList.remove("is-open");
	});
	document.getElementById("btnResetCategoryForm").addEventListener("click", function () {
		document.getElementById("catEditId").value = "0";
		document.getElementById("catEditName").value = "";
		document.getElementById("catEditColor").value = "##0284c7";
		document.getElementById("catEditBadge").value = "badge-info";
		document.getElementById("catEditDesc").value = "";
		document.getElementById("catFormHeading").textContent = "Add / Edit Category";
	});

	document.querySelectorAll(".js-edit-cat").forEach(function (btn) {
		btn.addEventListener("click", function () {
			document.getElementById("catEditId").value = btn.getAttribute("data-id");
			document.getElementById("catEditName").value = btn.getAttribute("data-name") || "";
			document.getElementById("catEditColor").value = btn.getAttribute("data-color") || "##0284c7";
			document.getElementById("catEditBadge").value = btn.getAttribute("data-badge") || "badge-info";
			document.getElementById("catEditDesc").value = btn.getAttribute("data-desc") || "";
			document.getElementById("catFormHeading").textContent = "Editing Category: " + (btn.getAttribute("data-name") || "");
		});
	});

	document.getElementById("btnSaveCategory").addEventListener("click", function () {
		var nameVal = document.getElementById("catEditName").value.trim();
		if (!nameVal) {
			showAlert("Category Name Required", "Please enter a category name.", "warning");
			return;
		}
		postJson(endpoints.saveCategory, {
			id: Number(document.getElementById("catEditId").value || 0),
			name: nameVal,
			color: document.getElementById("catEditColor").value,
			badgeClass: document.getElementById("catEditBadge").value,
			description: document.getElementById("catEditDesc").value.trim()
		}).then(function (res) {
			if (getField(res, "success", false)) {
				if (typeof window.showToast === "function") window.showToast("Category saved.", "success");
				setTimeout(function () { window.location.reload(); }, 300);
			} else {
				showAlert("Error Saving Category", getField(res, "message", "Unable to save category."), "danger");
			}
		});
	});

	document.querySelectorAll(".js-delete-cat").forEach(function (btn) {
		btn.addEventListener("click", function () {
			var id = Number(btn.getAttribute("data-id"));
			var name = btn.getAttribute("data-name");
			askConfirm("Delete Event Category", "Delete category \"" + name + "\"?", "Delete").then(function (ok) {
				if (!ok) return;
				postJson(endpoints.deleteCategory, { id: id }).then(function (res) {
					if (getField(res, "success", false)) {
						window.location.reload();
					} else {
						showAlert("Cannot Delete Category", getField(res, "message", "Unable to delete category."), "warning");
					}
				});
			});
		});
	});

	// Escape key closes open modals
	document.addEventListener("keydown", function (e) {
		if (e.key === "Escape") {
			if (eventModal.classList.contains("is-open")) closeEventModal();
			if (inspectorModal.classList.contains("is-open")) inspectorModal.classList.remove("is-open");
			if (categoriesModal.classList.contains("is-open")) categoriesModal.classList.remove("is-open");
		}
	});

	// Initial render
	refreshAllViews();
})();
</script>
</cfoutput>

