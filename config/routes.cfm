<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://guides.wheels.dev/v4-0-0/basics/routing/ for more info.

	mapper()
		// CLI-Appends-Here

		// Form Builder and Online Forms Routes
		.get(name="formBuilder", pattern="form-builder", to="forms##builder")
		.get(name="formsIndex", pattern="forms", to="forms##index")
		.get(name="formPreview", pattern="forms/preview", to="forms##preview")
		.post(name="formSave", pattern="forms/save", to="forms##save")
		.post(name="formSoftDelete", pattern="forms/delete", to="forms##softDelete")
		.post(name="formSubmit", pattern="forms/submit", to="forms##submit")
		.get(name="formSubmitGet", pattern="forms/submit", to="forms##submit")

		// Job Postings & HRM Recruitment Routes
		.get(name="jobsIndex", pattern="jobs", to="jobs##index")
		.get(name="jobsNew", pattern="jobs/new", to="jobs##new")
		.get(name="jobsEdit", pattern="jobs/edit", to="jobs##edit")
		.post(name="jobsSave", pattern="jobs/save", to="jobs##save")
		.post(name="jobsToggleStatus", pattern="jobs/toggle-status", to="jobs##toggleStatus")
		.post(name="jobsDelete", pattern="jobs/delete", to="jobs##delete")
		.get(name="jobsApplications", pattern="jobs/applications", to="jobs##applications")
		.get(name="jobsApplication", pattern="jobs/application", to="jobs##application")
		.post(name="jobsUpdateApplicationStatus", pattern="jobs/application/status", to="jobs##updateApplicationStatus")
		.get(name="jobsExportCsv", pattern="jobs/applications/export", to="jobs##exportCsv")
		.get(name="jobsPublicList", pattern="careers", to="jobs##publicList")
		.get(name="jobsPublicView", pattern="careers/view", to="jobs##publicView")
		.get(name="jobsApply", pattern="careers/apply", to="jobs##apply")
		.post(name="jobsSubmitApplication", pattern="careers/submit", to="jobs##submitApplication")

		// Navigation Builder persistence
		.post(name="navigationSaveItem", pattern="navigation/items/save", to="navigation##saveItem")
		.post(name="navigationDeleteItem", pattern="navigation/items/delete", to="navigation##deleteItem")
		.post(name="navigationReorder", pattern="navigation/items/reorder", to="navigation##reorder")

		// Documentation and Knowledge Base Routes
		.get(name="documentationEditor", pattern="documentation/editor", to="documentation##editor")
		.get(name="documentationFormBuilder", pattern="documentation/form-builder", to="documentation##formBuilder")
		.get(name="documentation", pattern="documentation", to="documentation##index")

		// Pages, How Do I, and Folder Explorer Routes
		.get(name="pagesHowDoI", pattern="pages/how-do-i", to="pages##howDoI")
		.get(name="pagesHowDoIAlt", pattern="pages/howdoi", to="pages##howDoI")
		.get(name="pagesHowDoICamel", pattern="pages/howDoI", to="pages##howDoI")
		.post(name="saveHowDoIItem", pattern="pages/how-do-i/save", to="pages##saveHowDoIItem")
		.post(name="saveHowDoIItemCamel", pattern="pages/saveHowDoIItem", to="pages##saveHowDoIItem")
		.post(name="saveHowDoIItemHyphen", pattern="pages/save-how-do-i-item", to="pages##saveHowDoIItem")
		.post(name="deleteHowDoIItem", pattern="pages/how-do-i/delete", to="pages##deleteHowDoIItem")
		.post(name="deleteHowDoIItemCamel", pattern="pages/deleteHowDoIItem", to="pages##deleteHowDoIItem")
		.post(name="deleteHowDoIItemHyphen", pattern="pages/delete-how-do-i-item", to="pages##deleteHowDoIItem")
		.post(name="reorderHowDoIItems", pattern="pages/how-do-i/reorder", to="pages##reorderHowDoIItems")
		.post(name="reorderHowDoIItemsCamel", pattern="pages/reorderHowDoIItems", to="pages##reorderHowDoIItems")
		.post(name="reorderHowDoIItemsHyphen", pattern="pages/reorder-how-do-i-items", to="pages##reorderHowDoIItems")
		.post(name="saveHowDoICategory", pattern="pages/how-do-i/category/save", to="pages##saveHowDoICategory")
		.post(name="saveHowDoICategoryCamel", pattern="pages/saveHowDoICategory", to="pages##saveHowDoICategory")
		.post(name="saveHowDoICategoryHyphen", pattern="pages/save-how-do-i-category", to="pages##saveHowDoICategory")
		.post(name="deleteHowDoICategory", pattern="pages/how-do-i/category/delete", to="pages##deleteHowDoICategory")
		.post(name="deleteHowDoICategoryCamel", pattern="pages/deleteHowDoICategory", to="pages##deleteHowDoICategory")
		.post(name="deleteHowDoICategoryHyphen", pattern="pages/delete-how-do-i-category", to="pages##deleteHowDoICategory")
		.get(name="addFolderExplorer", pattern="pages/add-folder-explorer", to="pages##folderExplorer")
		.get(name="pagesMenuItems", pattern="pages/menu-items", to="pages##menuItems")
		.get(name="pagesWorkspaceForms", pattern="pages/workspace-forms", to="pages##workspaceForms")
		.get(name="pagesWorkspaceFormsCamel", pattern="pages/workspaceForms", to="pages##workspaceForms")
		.get(name="folderExplorer", pattern="pages/folder-explorer", to="pages##folderExplorer")
		.post(name="saveFolderExplorer", pattern="pages/folder-explorer/save", to="pages##saveFolderExplorer")
		.post(name="deleteFolderExplorer", pattern="pages/folder-explorer/delete", to="pages##deleteFolderExplorer")
		.post(name="saveSubpage", pattern="pages/subpage/save", to="pages##saveSubpage")
		.post(name="deleteSubpage", pattern="pages/subpage/delete", to="pages##deleteSubpage")
		.post(name="createPageModal", pattern="pages/create-modal", to="pages##createModal")
		.post(name="savePage", pattern="pages/save", to="pages##save")
		.get(name="pageRevisions", pattern="pages/revisions", to="pages##revisions")
		.get(name="pageRevision", pattern="pages/revision", to="pages##revision")
		.post(name="restorePageRevision", pattern="pages/restore-revision", to="pages##restoreRevision")
		.post(name="restorePageRevisionCamel", pattern="pages/restoreRevision", to="pages##restoreRevision")
		.post(name="snapshotPageRevision", pattern="pages/snapshot-revision", to="pages##snapshotRevision")

		// Media Library Routes
		.get(name="mediaIndex", pattern="media", to="media##index")
		.get(name="mediaUpload", pattern="media/upload", to="media##upload")
		.post(name="mediaProcessUpload", pattern="media/upload", to="media##processUpload")
		.post(name="mediaUpdateMeta", pattern="media/update-meta", to="media##updateMeta")
		.get(name="mediaPicker", pattern="media/picker", to="media##picker")

		// Events / County Calendar Routes
		.get(name="eventsIndex", pattern="events", to="events##index")
		.get(name="calendarIndex", pattern="calendar", to="events##index")
		.post(name="eventsSave", pattern="events/save", to="events##save")
		.post(name="eventsDelete", pattern="events/delete", to="events##delete")
		.post(name="eventsCategorySave", pattern="events/category/save", to="events##saveCategory")
		.post(name="eventsCategorySaveCamel", pattern="events/saveCategory", to="events##saveCategory")
		.post(name="eventsCategorySaveHyphen", pattern="events/save-category", to="events##saveCategory")
		.post(name="eventsCategoryDelete", pattern="events/category/delete", to="events##deleteCategory")
		.post(name="eventsCategoryDeleteCamel", pattern="events/deleteCategory", to="events##deleteCategory")
		.post(name="eventsCategoryDeleteHyphen", pattern="events/delete-category", to="events##deleteCategory")
		.get(name="eventsIcs", pattern="events/ics", to="events##exportIcs")
		.get(name="eventsExportIcs", pattern="events/exportIcs", to="events##exportIcs")
		.get(name="eventsExportIcsHyphen", pattern="events/export-ics", to="events##exportIcs")

		// Users & Roles Security Routes
		.get(name="usersProfile", pattern="users/profile", to="users##profile")
		.post(name="usersUpdateProfile", pattern="users/profile/update", to="users##updateProfile")
		.post(name="usersUpdatePassword", pattern="users/profile/password", to="users##updatePassword")
		.post(name="usersToggle2Fa", pattern="users/profile/2fa", to="users##toggle2Fa")
		.get(name="usersIndex", pattern="users", to="users##index")
		.get(name="usersRoles", pattern="users/roles", to="users##roles")
		.get(name="usersNew", pattern="users/new", to="users##new")
		.post(name="usersCreate", pattern="users/create", to="users##create")
		.get(name="usersEdit", pattern="users/edit", to="users##edit")
		.post(name="usersUpdate", pattern="users/update", to="users##update")
		.get(name="usersSimulate", pattern="users/simulate", to="users##simulate")
		.post(name="usersToggleStatus", pattern="users/toggle-status", to="users##toggleStatus")
		.post(name="usersToggleStatusDirect", pattern="users/toggleStatus", to="users##toggleStatus")

		// Notifications Center Routes
		.get(name="notificationsIndex", pattern="notifications", to="main##notifications")
		.get(name="mainNotifications", pattern="main/notifications", to="main##notifications")

		// Emergency Alerts & Public Safety Dispatch Routes
		.get(name="alertsIndex", pattern="alerts", to="alerts##index")
		.get(name="alertsPioIndex", pattern="pio/alerts", to="alerts##index")
		.post(name="alertsSave", pattern="alerts/save", to="alerts##save")
		.post(name="alertsToggle", pattern="alerts/toggle", to="alerts##toggle")
		.post(name="alertsDelete", pattern="alerts/delete", to="alerts##delete")
		.get(name="alertsApiActive", pattern="api/v1/alerts/active", to="alerts##apiActive")
		.get(name="alertsApiActiveAll", pattern="api/v1/alerts", to="alerts##apiActive")
		.get(name="alertsActive", pattern="alerts/active", to="alerts##active")

		// Workspaces Administration Routes (Admin Only)
		.get(name="workspacesIndex", pattern="workspaces", to="workspaces##index")
		.get(name="workspacesNew", pattern="workspaces/new", to="workspaces##new")
		.post(name="workspacesCreate", pattern="workspaces/create", to="workspaces##create")
		.get(name="workspacesEdit", pattern="workspaces/edit", to="workspaces##edit")
		.post(name="workspacesUpdate", pattern="workspaces/update", to="workspaces##update")

		// Settings & Startup Routes
		.get(name="settingsIndex", pattern="settings", to="settings##startup")
		.get(name="settingsStartup", pattern="settings/startup", to="settings##startup")

		// Authentication & Security Routes
		.get(name="login", pattern="login", to="sessions##new")
		.post(name="checkEmail", pattern="login/check-email", to="sessions##checkEmail")
		.post(name="sendOtp", pattern="login/send-otp", to="sessions##sendOtp")
		.post(name="verifyOtp", pattern="login/verify-otp", to="sessions##verifyOtp")
		.post(name="verifyAuthenticator", pattern="login/verify-authenticator", to="sessions##verifyAuthenticator")
		.get(name="connectAuthenticator", pattern="login/connect-authenticator", to="sessions##connectAuthenticator")
		.post(name="saveAuthenticator", pattern="login/save-authenticator", to="sessions##saveAuthenticator")
		.get(name="logout", pattern="logout", to="sessions##destroy")
		.post(name="logoutPost", pattern="logout", to="sessions##destroy")

		// Liveness / warm-up endpoint. `wheels deploy`'s proxy healthcheck probes
		// `/up` before traffic cutover; a 200 here also compiles the request path
		// so the first real visitor gets warm latency. See app/controllers/Up.cfc.
		.get(name="up", to="up##index")

		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		.wildcard()

		// The root route below is the one that will be called on your application's home page.
		.root(to="main##index", method="get")
	.end();
</cfscript>
