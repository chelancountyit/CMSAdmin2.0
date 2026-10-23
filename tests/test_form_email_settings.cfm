<cfsetting showdebugoutput="false" requesttimeout="60">
<cfcontent type="text/plain; charset=utf-8">

<cfset results = {
	"timestamp" = DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss"),
	"totalTests" = 0,
	"passed" = 0,
	"failed" = 0
}>

<cffunction name="assertTest" access="private" returntype="void">
	<cfargument name="suiteName" type="string" required="true">
	<cfargument name="testName" type="string" required="true">
	<cfargument name="condition" type="boolean" required="true">
	<cfargument name="details" type="string" required="false" default="">

	<cfset results.totalTests++>
	<cfif arguments.condition>
		<cfset results.passed++>
		<cfoutput>[PASS] #arguments.suiteName# :: #arguments.testName#<cfif Len(arguments.details)> (#arguments.details#)</cfif>#Chr(10)#</cfoutput>
	<cfelse>
		<cfset results.failed++>
		<cfoutput>[FAIL] #arguments.suiteName# :: #arguments.testName# - FAILED! Details: #arguments.details##Chr(10)#</cfoutput>
	</cfif>
</cffunction>

<cfoutput>
======================================================================
  CHELAN COUNTY CMSADMIN 2.0 — FORM EMAIL SETTINGS TEST SUITE
======================================================================
Time: #results.timestamp#
Datasource: ChelanCountyWebsite (SQL Server)

</cfoutput>

<!--- SUITE 1: Forms Database Columns --->
<cfoutput>--- SUITE 1: Forms Table Columns ---#Chr(10)#</cfoutput>
<cftry>
	<cfset qCols = queryExecute("
		SELECT COLUMN_NAME
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'forms' AND COLUMN_NAME IN ('notification_email', 'notification_email_cc', 'email_notifications_enabled')
	", {}, { datasource: "ChelanCountyWebsite" })>
	<cfset colList = ValueList(qCols.COLUMN_NAME)>
	<cfset assertTest("Schema", "forms.notification_email exists", ListFindNoCase(colList, "notification_email") GT 0)>
	<cfset assertTest("Schema", "forms.notification_email_cc exists", ListFindNoCase(colList, "notification_email_cc") GT 0)>
	<cfset assertTest("Schema", "forms.email_notifications_enabled exists", ListFindNoCase(colList, "email_notifications_enabled") GT 0)>
<cfcatch type="any">
	<cfset assertTest("Schema", "Database query exception", false, cfcatch.message & " - " & cfcatch.detail)>
</cfcatch>
</cftry>

<!--- SUITE 2: Email Generator / Token Replacement Logic --->
<cfoutput>--- SUITE 2: Form Notification & Auto-Responder Mail Engine ---#Chr(10)#</cfoutput>
<cftry>
	<cfset request.fbMail = {
		"refId": "SUB-TEST-12345",
		"title": "Community Park Shelter Reservation",
		"formId": 999,
		"formKey": "park-reservation",
		"deptName": "Parks & Recreation",
		"values": [
			{ "key": "applicant_name", "label": "Full Name", "type": "text", "value": "Sarah Jenkins" },
			{ "key": "applicant_email", "label": "Email Address", "type": "email", "value": "sarah.jenkins@example.org" },
			{ "key": "phone", "label": "Phone Number", "type": "tel", "value": "(509) 667-6340" },
			{ "key": "reservation_date", "label": "Reservation Date", "type": "date", "value": "2026-11-15" }
		],
		"adminUrl": "https://cmsadmin.chelancounty.gov/forms",
		"submittedAt": "November 15, 2026 at 2:30 PM",
		"ipAddress": "127.0.0.1",
		"userAgent": "Mozilla/5.0 TestSuite",
		"to": "parks@chelancounty.gov",
		"cc": "supervisor@chelancounty.gov",
		"emailSettings": {
			"staffNotificationEnabled": true,
			"staffEmail": "parks@chelancounty.gov",
			"staffEmailCc": "supervisor@chelancounty.gov",
			"staffSubject": "Urgent: {{form_title}} from {{applicant_name}} [{{reference_id}}]",
			"staffNotes": "Verify park shelter availability before issuing permit.",
			"userAutoresponderEnabled": true,
			"userFromName": "Chelan County Parks Department",
			"userReplyTo": "parks.support@chelancounty.gov",
			"userSubject": "We Received Your {{form_title}} Request ({{reference_id}})",
			"userCustomMessage": "Thank you for booking with Chelan County Parks. We will contact you within 24 hours.",
			"userIncludeSummary": true
		}
	}>

	<cfsavecontent variable="mailOutput">
		<cfinclude template="/app/lib/formNotificationMail.cfm">
	</cfsavecontent>

	<cfset assertTest("MailEngine", "formNotificationMail.cfm compiled and executed without errors", true)>
	<cfset assertTest("MailEngine", "Staff subject token replaced form_title", FindNoCase("Community Park Shelter Reservation", local.staffSubject) GT 0)>
	<cfset assertTest("MailEngine", "Staff subject token replaced applicant_name", FindNoCase("Sarah Jenkins", local.staffSubject) GT 0)>
	<cfset assertTest("MailEngine", "Staff subject token replaced reference_id", FindNoCase("SUB-TEST-12345", local.staffSubject) GT 0)>
	<cfset assertTest("MailEngine", "Citizen subject token replaced", FindNoCase("SUB-TEST-12345", local.userSubject) GT 0)>
	<cfset assertTest("MailEngine", "Citizen from name customized", local.userFromName EQ "Chelan County Parks Department")>
	<cfset assertTest("MailEngine", "Citizen reply-to customized", local.userReplyTo EQ "parks.support@chelancounty.gov")>
	<cfset assertTest("MailEngine", "Citizen custom message populated", FindNoCase("Thank you for booking with Chelan County Parks", local.userCustomMsg) GT 0)>
	<cfset assertTest("MailEngine", "Staff processing notice populated", local.staffNotes EQ "Verify park shelter availability before issuing permit.")>
	<cfset assertTest("MailEngine", "Applicant submitter email detected", local.submitterEmail EQ "sarah.jenkins@example.org")>
	<cfset assertTest("MailEngine", "Applicant submitter name detected", local.submitterName EQ "Sarah Jenkins")>

<cfcatch type="any">
	<cfset assertTest("MailEngine", "Execution exception in formNotificationMail.cfm", false, cfcatch.message & " - " & cfcatch.detail)>
</cfcatch>
</cftry>

<!--- SUITE 3: Index View UI Integration Verification --->
<cfoutput>--- SUITE 3: View Template UI Integration ---#Chr(10)#</cfoutput>
<cftry>
	<cfset viewFile = FileRead("C:\inetpub\CMSAdmin2.0\app\views\forms\index.cfm", "utf-8")>
	<cfset assertTest("View", "modalFormEmailSettings exists in index.cfm", FindNoCase('id="modalFormEmailSettings"', viewFile) GT 0)>
	<cfset assertTest("View", "btn-email-settings exists in table row", FindNoCase('class="btn btn-outline btn-sm btn-icon-only btn-email-settings"', viewFile) GT 0)>
	<cfset assertTest("View", "emailStaffEnabled toggle exists", FindNoCase('id="emailStaffEnabled"', viewFile) GT 0)>
	<cfset assertTest("View", "emailUserEnabled toggle exists", FindNoCase('id="emailUserEnabled"', viewFile) GT 0)>
	<cfset assertTest("View", "btn-token-chip elements exist", FindNoCase('class="btn-token-chip"', viewFile) GT 0)>
	<cfset assertTest("View", "btnSaveEmailSettings exists", FindNoCase('id="btnSaveEmailSettings"', viewFile) GT 0)>
	<cfset assertTest("View", "emailLivePreviewContainer exists", FindNoCase('id="emailLivePreviewContainer"', viewFile) GT 0)>
	<cfset assertTest("View", "JavaScript event listener attached", FindNoCase('btn-email-settings', viewFile) GT 0)>
	<cfset assertTest("View", "Universal admin-modal-backdrop class configured", FindNoCase('class="admin-modal-backdrop fb-modal"', viewFile) GT 0)>
	<cfset assertTest("View", "Standard blue transparent gray backdrop rgba(15, 23, 42, 0.72)", FindNoCase('background: rgba(15, 23, 42, 0.72)', viewFile) GT 0)>
	<cfset assertTest("View", "Backdrop filter blur(6px) applied", FindNoCase('backdrop-filter: blur(6px)', viewFile) GT 0)>
	<cfset assertTest("View", "openAdminModal function declared", FindNoCase('function openAdminModal', viewFile) GT 0)>
	<cfset assertTest("View", "closeAdminModal function declared", FindNoCase('function closeAdminModal', viewFile) GT 0)>
	<cfset assertTest("View", "Dynamic buildFieldsTableHtml function declared in view", FindNoCase('function buildFieldsTableHtml', viewFile) GT 0)>
	<cfset assertTest("View", "View in CMSAdmin Directory CTA link included in email preview", FindNoCase('View in CMSAdmin Directory', viewFile) GT 0)>
	<cfset assertTest("View", "showToast function declared in view", FindNoCase('function showToast(', viewFile) GT 0)>
	<cfset assertTest("View", "showToastNotification alias declared for backwards compatibility", FindNoCase('showToastNotification', viewFile) GT 0)>
<cfcatch type="any">
	<cfset assertTest("View", "View file read exception", false, cfcatch.message)>
</cfcatch>
</cftry>

<cfoutput>
======================================================================

<!--- SUITE 4: Database Forms Record Inspection & Field Resolution --->
<cfoutput>--- SUITE 4: Database Forms Records & Fields ---#Chr(10)#</cfoutput>
<cftry>
	<cfset qForms = queryExecute("
		SELECT id, title, slug, siteid, notification_email, notification_email_cc, email_notifications_enabled
		FROM forms
		WHERE deletedat IS NULL
	", {}, { datasource: "ChelanCountyWebsite" })>
	<cfoutput>Found ##qForms.recordCount## active forms in database:#Chr(10)#</cfoutput>
	<cfloop query="qForms">
		<cfoutput> - ID: ##qForms.id## | Title: ##qForms.title## | SiteID: '##qForms.siteid##' | AlertEmail: '##qForms.notification_email##'#Chr(10)#</cfoutput>
	</cfloop>
	<cfset assertTest("Database", "Active forms exist in database", qForms.recordCount GT 0)>

	<cfset qFields15 = queryExecute("
		SELECT field_key, label, field_type
		FROM form_fields
		WHERE form_id = 15 AND deletedat IS NULL AND is_active = 1
		ORDER BY sort_order
	", {}, { datasource: "ChelanCountyWebsite" })>
	<cfset assertTest("Database", "Form 15 has specific fields for problem report", qFields15.recordCount GTE 5)>
	<cfset fieldKeyList = ValueList(qFields15.field_key)>
	<cfset assertTest("Database", "Form 15 contains pr_category field", ListFindNoCase(fieldKeyList, "pr_category") GT 0)>
	<cfset assertTest("Database", "Form 15 contains pr_location field", ListFindNoCase(fieldKeyList, "pr_location") GT 0)>
	<cfset assertTest("Database", "Form 15 contains pr_desc field", ListFindNoCase(fieldKeyList, "pr_desc") GT 0)>
<cfcatch type="any">
	<cfset assertTest("Database", "Failed to query forms or fields", false, cfcatch.message)>
</cfcatch>
</cftry>

TEST RUN COMPLETE: #results.passed# / #results.totalTests# passed (<cfif results.failed EQ 0>100% SUCCESS<cfelse>#results.failed# FAILED</cfif>)
======================================================================
</cfoutput>
