<cfscript>
	// -------------------------------------------------------------------------
	// Chelan County Official Form Builder Submission Notification & Auto-Responder
	// Included by Forms.cfc :: sendSubmissionNotification()
	// -------------------------------------------------------------------------

	local.mailData = StructKeyExists(request, "fbMail") ? request.fbMail : {};
	if (StructIsEmpty(local.mailData)) {
		return;
	}

	local.refId        = local.mailData.refId ?: "N/A";
	local.formTitle    = local.mailData.title ?: "Form Submission";
	local.formId       = local.mailData.formId ?: 0;
	local.formKey      = local.mailData.formKey ?: "";
	local.deptName     = local.mailData.deptName ?: "Chelan County";
	local.values       = local.mailData.values ?: [];
	local.adminUrl     = local.mailData.adminUrl ?: "https://www.chelancounty.gov/cmsadmin";
	local.submittedAt  = local.mailData.submittedAt ?: DateTimeFormat(Now(), "mmmm d, yyyy 'at' h:nn tt");
	local.ipAddress    = local.mailData.ipAddress ?: "";
	local.userAgent    = local.mailData.userAgent ?: "";
	local.targetTo     = Trim(local.mailData.to ?: "");
	local.targetCc     = Trim(local.mailData.cc ?: "");

	// Custom Email Configuration
	local.es = StructKeyExists(local.mailData, "emailSettings") && IsStruct(local.mailData.emailSettings) ? local.mailData.emailSettings : {};

	// Detect Submitter Information from submitted values
	local.submitterEmail = "";
	local.submitterName  = "";
	local.firstNamePart  = "";
	local.lastNamePart   = "";
	local.submitterPhone = "";

	for (local.v in local.values) {
		local.k = LCase(local.v.key ?: "");
		local.l = LCase(local.v.label ?: "");
		local.t = LCase(local.v.type ?: "");
		local.val = Trim(local.v.value ?: "");

		if (!Len(local.submitterEmail) && (local.t == "email" || Find("email", local.k) || Find("email", local.l))) {
			if (IsValid("email", local.val)) {
				local.submitterEmail = local.val;
			}
		}
		if (Len(local.val) && local.val != "Yes" && local.val != "No" && !Find("file", local.k)) {
			if (!Len(local.firstNamePart) && Find("first", local.l) && Find("name", local.l)) {
				local.firstNamePart = local.val;
			} else if (!Len(local.lastNamePart) && Find("last", local.l) && Find("name", local.l)) {
				local.lastNamePart = local.val;
			} else if (!Len(local.submitterName) && (Find("name", local.l) || Find("name", local.k))) {
				local.submitterName = local.val;
			}
		}
		if (!Len(local.submitterPhone) && (local.t == "tel" || local.t == "phone" || Find("phone", local.l) || Find("phone", local.k))) {
			if (Len(local.val)) {
				local.submitterPhone = local.val;
			}
		}
	}

	if (Len(local.firstNamePart) || Len(local.lastNamePart)) {
		local.submitterName = Trim(local.firstNamePart & " " & local.lastNamePart);
	}
	if (!Len(local.submitterName)) {
		local.submitterName = "Valued Resident";
	}

	// Staff Notification Configuration
	local.staffEnabled   = !StructKeyExists(local.es, "staffNotificationEnabled") || local.es.staffNotificationEnabled;
	local.staffSubject   = Len(Trim(local.es.staffSubject ?: "")) ? Trim(local.es.staffSubject) : "[New Submission] {{form_title}} ({{reference_id}})";
	local.staffNotes     = Trim(local.es.staffNotes ?: "");
	local.fromEmail      = "Chelan County Online Services <forms@chelancounty.gov>";

	// Staff Reply-To: allow county staff to reply directly to citizen if email is available
	local.replyTo = Len(local.submitterEmail) ? (local.submitterName != "Valued Resident" ? '"#local.submitterName#" <#local.submitterEmail#>' : local.submitterEmail) : "forms@chelancounty.gov";

	// Citizen Confirmation Configuration
	local.userEnabled    = !StructKeyExists(local.es, "userAutoresponderEnabled") || local.es.userAutoresponderEnabled;
	local.userFromName   = Len(Trim(local.es.userFromName ?: "")) ? Trim(local.es.userFromName) : "Chelan County Online Services";
	local.userFromEmail  = "#local.userFromName# <forms@chelancounty.gov>";
	local.userReplyTo    = Len(Trim(local.es.userReplyTo ?: "")) ? Trim(local.es.userReplyTo) : "info@chelancounty.gov";
	local.userSubject    = Len(Trim(local.es.userSubject ?: "")) ? Trim(local.es.userSubject) : "Confirmation: {{form_title}} Received ({{reference_id}})";
	local.userCustomMsg  = Trim(local.es.userCustomMessage ?: "");

	// Apply placeholder token replacements
	local.tokensList = [
		{ k: "{{form_title}}", v: local.formTitle },
		{ k: "{{reference_id}}", v: local.refId },
		{ k: "{{date}}", v: local.submittedAt },
		{ k: "{{department}}", v: local.deptName },
		{ k: "{{applicant_name}}", v: local.submitterName },
		{ k: "{{applicant_email}}", v: local.submitterEmail }
	];

	for (local.tok in local.tokensList) {
		local.staffSubject = ReplaceNoCase(local.staffSubject, local.tok.k, local.tok.v, "all");
		local.userSubject  = ReplaceNoCase(local.userSubject, local.tok.k, local.tok.v, "all");
		local.userCustomMsg = ReplaceNoCase(local.userCustomMsg, local.tok.k, local.tok.v, "all");
	}
	local.userIncludeSum = !StructKeyExists(local.es, "userIncludeSummary") || local.es.userIncludeSummary;

	// Formatters
	local.formatBytes = function(numeric bytes) {
		if (arguments.bytes <= 0) return "";
		if (arguments.bytes < 1024) return arguments.bytes & " B";
		if (arguments.bytes < 1048576) return NumberFormat(arguments.bytes / 1024, "0.0") & " KB";
		return NumberFormat(arguments.bytes / 1048576, "0.0") & " MB";
	};
</cfscript>

<!--- ======================================================================
      1. STAFF NOTIFICATION EMAIL
      ====================================================================== --->
<cfif local.staffEnabled AND Len(local.targetTo)>
	<cftry>
		<cfif Len(local.targetCc)>
			<cfmail
				to="#local.targetTo#"
				cc="#local.targetCc#"
				from="#local.fromEmail#"
				replyto="#local.replyTo#"
				subject="#local.staffSubject#">

				<cfmailpart type="text/plain" charset="utf-8">
================================================================================
CHELAN COUNTY • NEW FORM SUBMISSION
================================================================================

Form: #local.formTitle#
Reference ID: #local.refId#
Submitted: #local.submittedAt#
<cfif Len(local.submitterName) AND local.submitterName NEQ "Valued Resident">Submitter Name: #local.submitterName#
</cfif><cfif Len(local.submitterEmail)>Submitter Email: #local.submitterEmail#
</cfif><cfif Len(local.submitterPhone)>Submitter Phone: #local.submitterPhone#
</cfif>
<cfif Len(local.staffNotes)>
--------------------------------------------------------------------------------
STAFF REVIEW INSTRUCTIONS / SPECIAL NOTES:
--------------------------------------------------------------------------------
#local.staffNotes#
</cfif>
--------------------------------------------------------------------------------
SUBMITTED DETAILS:
--------------------------------------------------------------------------------
<cfloop array="#local.values#" index="local.item">
* #local.item.label#:
  <cfif local.item.type EQ "file">
    [File Upload] #local.item.fileName# (<cfif StructKeyExists(local.item, "fileSize") AND Val(local.item.fileSize) GT 0>#local.formatBytes(local.item.fileSize)#<cfelse>Uploaded</cfif>)
  <cfelseif local.item.type EQ "rating" OR local.item.type EQ "star">
    #local.item.value# / 5 Stars
  <cfelse>
    #Replace(local.item.value, Chr(10), Chr(10) & "  ", "all")#
  </cfif>

</cfloop>
--------------------------------------------------------------------------------
MANAGEMENT & AUDIT:
--------------------------------------------------------------------------------
IP Address: #local.ipAddress#
User Agent: #local.userAgent#
Spam Protection: Verified Human (Honeypot + Timing verified)
View in CMS: #local.adminUrl#

================================================================================
Chelan County Administration • 350 Orondo Ave, Wenatchee, WA 98801
This is an automated notification from the Chelan County Form Engine.
				</cfmailpart>

				<cfmailpart type="text/html" charset="utf-8">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
	<title>New Submission: #EncodeForHTML(local.formTitle)# (#local.refId#)</title>
	<style type="text/css">
		body { margin: 0; padding: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; background-color: ##f1f5f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		table { border-collapse: collapse; }
		td, th { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		img { border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
		@media only screen and (max-width: 640px) {
			.email-container { width: 100% !important; max-width: 100% !important; }
			.mobile-padding { padding-left: 16px !important; padding-right: 16px !important; }
			.label-col { width: 100% !important; display: block !important; padding-bottom: 4px !important; }
			.value-col { width: 100% !important; display: block !important; padding-left: 0 !important; }
		}
	</style>
</head>
<body style="margin: 0; padding: 24px 0 32px 0; background-color: ##f1f5f9; color: ##1e293b;">
	<center>
		<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: ##f1f5f9;">
			<tr>
				<td align="center">
					<table role="presentation" class="email-container" border="0" cellpadding="0" cellspacing="0" width="640" style="max-width: 640px; background-color: ##ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); border: 1px solid ##e2e8f0;">
						
						<!-- Official Chelan County Header -->
						<tr>
							<td style="background-color: ##0b231a; background-image: linear-gradient(135deg, ##0b231a 0%, ##163e32 100%); padding: 24px 28px; border-bottom: 3px solid ##d4af37;">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
									<tr>
										<td valign="middle">
											<div style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: ##d4af37; margin-bottom: 4px;">
												Chelan County &bull; Washington
											</div>
											<div style="font-size: 20px; font-weight: 700; color: ##ffffff; letter-spacing: -0.3px; line-height: 1.2;">
												Online Services &bull; Form Notification
											</div>
										</td>
										<td align="right" valign="middle" style="padding-left: 12px;">
											<span style="display: inline-block; background-color: rgba(212, 175, 55, 0.15); border: 1px solid ##d4af37; color: ##fef3c7; font-family: monospace; font-size: 12px; font-weight: 700; padding: 5px 10px; border-radius: 4px; white-space: nowrap;">
												#local.refId#
											</span>
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<!-- Sub-Header / Notification Alert -->
						<tr>
							<td style="padding: 24px 28px 12px 28px; background-color: ##ffffff;" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
									<tr>
										<td style="padding-bottom: 16px; border-bottom: 1px solid ##f1f5f9;">
											<div style="font-size: 13px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; color: ##0d9488; margin-bottom: 4px;">
												&bull; New Form Submission Received
											</div>
											<h1 style="margin: 0 0 6px 0; font-size: 22px; font-weight: 700; color: ##0f172a; line-height: 1.3;">
												#EncodeForHTML(local.formTitle)#
											</h1>
											<div style="font-size: 13px; color: ##64748b;">
												Recorded on <strong>#local.submittedAt#</strong>
											</div>
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<cfif Len(local.staffNotes)>
						<!-- Custom Staff Review Instructions Note -->
						<tr>
							<td style="padding: 0 28px 16px 28px;" class="mobile-padding">
								<div style="background-color: ##eff6ff; border-left: 4px solid ##0284c7; border-radius: 4px; padding: 12px 16px;">
									<div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##0369a1; margin-bottom: 4px;">
										&bull; Department Staff Review Instructions
									</div>
									<div style="font-size: 13px; color: ##1e293b; line-height: 1.5; white-space: pre-wrap;">#EncodeForHTML(local.staffNotes)#</div>
								</div>
							</td>
						</tr>
						</cfif>

						<cfif Len(local.submitterEmail) OR (Len(local.submitterName) AND local.submitterName NEQ "Valued Resident") OR Len(local.submitterPhone)>
						<!-- Submitter Quick Summary Card -->
						<tr>
							<td style="padding: 0 28px 16px 28px;" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: ##f8fafc; border: 1px solid ##e2e8f0; border-radius: 6px; padding: 14px 16px;">
									<tr>
										<td style="padding: 12px 16px;">
											<div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##475569; margin-bottom: 8px;">
												Submitter Contact Information
											</div>
											<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
												<cfif Len(local.submitterName) AND local.submitterName NEQ "Valued Resident">
												<tr>
													<td width="90" style="font-size: 13px; color: ##64748b; padding-bottom: 4px;"><strong>Name:</strong></td>
													<td style="font-size: 14px; color: ##0f172a; font-weight: 600; padding-bottom: 4px;">#EncodeForHTML(local.submitterName)#</td>
												</tr>
												</cfif>
												<cfif Len(local.submitterEmail)>
												<tr>
													<td width="90" style="font-size: 13px; color: ##64748b; padding-bottom: 4px;"><strong>Email:</strong></td>
													<td style="font-size: 14px; padding-bottom: 4px;">
														<a href="mailto:#EncodeForHTML(local.submitterEmail)#" style="color: ##0f766e; text-decoration: underline; font-weight: 600;">
															#EncodeForHTML(local.submitterEmail)#
														</a>
														<span style="font-size: 11px; color: ##64748b; margin-left: 6px;">(Clicking "Reply" in your email client will email this address)</span>
													</td>
												</tr>
												</cfif>
												<cfif Len(local.submitterPhone)>
												<tr>
													<td width="90" style="font-size: 13px; color: ##64748b;"><strong>Phone:</strong></td>
													<td style="font-size: 14px; color: ##0f172a;">
														<a href="tel:#EncodeForHTML(local.submitterPhone)#" style="color: ##0f172a; text-decoration: none; font-weight: 500;">
															#EncodeForHTML(local.submitterPhone)#
														</a>
													</td>
												</tr>
												</cfif>
											</table>
										</td>
									</tr>
								</table>
							</td>
						</tr>
						</cfif>

						<!-- Form Submission Data Table -->
						<tr>
							<td style="padding: 4px 28px 20px 28px;" class="mobile-padding">
								<div style="font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##475569; margin-bottom: 10px; border-bottom: 1px solid ##e2e8f0; padding-bottom: 6px;">
									Submitted Form Fields
								</div>
								
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse: separate; border-spacing: 0; width: 100%;">
									<cfset local.fIdx = 0>
									<cfloop array="#local.values#" index="local.val">
										<cfset local.fIdx++>
										<cfset local.isAlt = (local.fIdx MOD 2 EQ 0)>
										<tr style="background-color: #(local.isAlt ? '##f8fafc' : '##ffffff')#;">
											<td class="label-col" width="34%" valign="top" style="padding: 10px 12px; font-size: 13px; font-weight: 600; color: ##334155; border-bottom: 1px solid ##f1f5f9; line-height: 1.4;">
												#EncodeForHTML(local.val.label)#
											</td>
											<td class="value-col" width="66%" valign="top" style="padding: 10px 12px; font-size: 14px; color: ##0f172a; border-bottom: 1px solid ##f1f5f9; line-height: 1.5; word-break: break-word;">
												<cfif local.val.type EQ "file">
													<div style="display: inline-block; background-color: ##f1f5f9; border: 1px solid ##cbd5e1; border-radius: 4px; padding: 4px 8px; font-size: 13px;">
														&##128206; <strong>#EncodeForHTML(local.val.fileName)#</strong>
														<cfif StructKeyExists(local.val, "fileSize") AND Val(local.val.fileSize) GT 0>
															<span style="color: ##64748b; font-size: 11px;">(#local.formatBytes(local.val.fileSize)#)</span>
														</cfif>
													</div>
													<div style="font-size: 11px; color: ##64748b; margin-top: 3px;">
														Stored securely in county file storage. Accessible via CMS Admin.
													</div>
												<cfelseif local.val.type EQ "textarea">
													<div style="background-color: ##f8fafc; border-left: 3px solid ##0b231a; padding: 8px 12px; font-size: 13px; color: ##1e293b; border-radius: 0 4px 4px 0; white-space: pre-wrap; font-family: inherit;">#EncodeForHTML(local.val.value)#</div>
												<cfelseif local.val.type EQ "rating" OR local.val.type EQ "star">
													<span style="color: ##eab308; font-size: 16px;">
														<cfloop from="1" to="5" index="local.s">
															<cfif local.s LTE Val(local.val.value)>&##9733;<cfelse>&##9734;</cfif>
														</cfloop>
													</span>
													<strong style="margin-left: 4px; font-size: 13px; color: ##475569;">(#local.val.value# / 5)</strong>
												<cfelseif local.val.type EQ "email">
													<a href="mailto:#EncodeForHTML(local.val.value)#" style="color: ##0f766e; text-decoration: underline;">
														#EncodeForHTML(local.val.value)#
													</a>
												<cfelseif local.val.type EQ "tel" OR local.val.type EQ "phone">
													<a href="tel:#EncodeForHTML(local.val.value)#" style="color: ##0f172a; text-decoration: none;">
														#EncodeForHTML(local.val.value)#
													</a>
												<cfelseif local.val.type EQ "url">
													<a href="#EncodeForHTML(local.val.value)#" target="_blank" rel="noopener noreferrer" style="color: ##0f766e; text-decoration: underline;">
														#EncodeForHTML(local.val.value)#
													</a>
												<cfelse>
													#Replace(EncodeForHTML(local.val.value), Chr(10), "<br/>", "all")#
												</cfif>
											</td>
										</tr>
									</cfloop>
								</table>
							</td>
						</tr>

						<!-- Admin CTA Button -->
						<tr>
							<td style="padding: 10px 28px 24px 28px; background-color: ##ffffff;" align="center" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td align="center" style="border-radius: 6px; background-color: ##0b231a; background-image: linear-gradient(135deg, ##0b231a 0%, ##163e32 100%);">
											<a href="#EncodeForHTML(local.adminUrl)#" target="_blank" style="font-size: 14px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: ##ffffff; text-decoration: none; padding: 12px 24px; border-radius: 6px; border: 1px solid ##0b231a; display: inline-block; font-weight: 600; letter-spacing: 0.2px;">
												&rarr; Open Form Submissions in CMS Admin
											</a>
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<!-- Audit & Security Metadata -->
						<tr>
							<td style="padding: 16px 28px; background-color: ##f8fafc; border-top: 1px solid ##e2e8f0; font-size: 11px; color: ##64748b; line-height: 1.5;" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
									<tr>
										<td>
											<strong>Submission Audit:</strong> Ref ID: <code style="font-family: monospace; color: ##0f172a; background: ##e2e8f0; padding: 1px 4px; border-radius: 3px;">#local.refId#</code> &bull; IP: <code style="font-family: monospace; color: ##0f172a;">#local.ipAddress#</code><br/>
											<strong>Anti-Spam Verification:</strong> Passed honeypot &amp; timing verification &bull; Legitimate resident activity.
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<!-- County Standard Footer -->
						<tr>
							<td style="padding: 20px 28px; background-color: ##0b231a; color: ##94a3b8; font-size: 11px; line-height: 1.6; text-align: center; border-top: 2px solid ##d4af37;" class="mobile-padding">
								<div style="font-weight: 700; color: ##ffffff; font-size: 12px; margin-bottom: 4px;">
									Chelan County Government &bull; State of Washington
								</div>
								<div>
									Chelan County Courthouse &bull; 350 Orondo Avenue, Wenatchee, WA 98801 &bull; (509) 667-6200
								</div>
								<div style="color: ##64748b; margin-top: 6px;">
									This automated notification was generated by the Chelan County Website Form Builder Engine.
								</div>
							</td>
						</tr>

					</table>
				</td>
			</tr>
		</table>
	</center>
</body>
</html>
				</cfmailpart>
			</cfmail>
		<cfelse>
			<cfmail
				to="#local.targetTo#"
				from="#local.fromEmail#"
				replyto="#local.replyTo#"
				subject="#local.staffSubject#">

				<cfmailpart type="text/plain" charset="utf-8">
================================================================================
CHELAN COUNTY • NEW FORM SUBMISSION
================================================================================

Form: #local.formTitle#
Reference ID: #local.refId#
Submitted: #local.submittedAt#
<cfif Len(local.submitterName) AND local.submitterName NEQ "Valued Resident">Submitter Name: #local.submitterName#
</cfif><cfif Len(local.submitterEmail)>Submitter Email: #local.submitterEmail#
</cfif><cfif Len(local.submitterPhone)>Submitter Phone: #local.submitterPhone#
</cfif>
<cfif Len(local.staffNotes)>
--------------------------------------------------------------------------------
STAFF REVIEW INSTRUCTIONS / SPECIAL NOTES:
--------------------------------------------------------------------------------
#local.staffNotes#
</cfif>
--------------------------------------------------------------------------------
SUBMITTED DETAILS:
--------------------------------------------------------------------------------
<cfloop array="#local.values#" index="local.item">
* #local.item.label#:
  <cfif local.item.type EQ "file">
    [File Upload] #local.item.fileName# (<cfif StructKeyExists(local.item, "fileSize") AND Val(local.item.fileSize) GT 0>#local.formatBytes(local.item.fileSize)#<cfelse>Uploaded</cfif>)
  <cfelseif local.item.type EQ "rating" OR local.item.type EQ "star">
    #local.item.value# / 5 Stars
  <cfelse>
    #Replace(local.item.value, Chr(10), Chr(10) & "  ", "all")#
  </cfif>

</cfloop>
--------------------------------------------------------------------------------
MANAGEMENT & AUDIT:
--------------------------------------------------------------------------------
IP Address: #local.ipAddress#
User Agent: #local.userAgent#
Spam Protection: Verified Human (Honeypot + Timing verified)
View in CMS: #local.adminUrl#

================================================================================
Chelan County Administration • 350 Orondo Ave, Wenatchee, WA 98801
This is an automated notification from the Chelan County Form Engine.
				</cfmailpart>

				<cfmailpart type="text/html" charset="utf-8">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
	<title>New Submission: #EncodeForHTML(local.formTitle)# (#local.refId#)</title>
	<style type="text/css">
		body { margin: 0; padding: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; background-color: ##f1f5f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		table { border-collapse: collapse; }
		td, th { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		img { border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
		@media only screen and (max-width: 640px) {
			.email-container { width: 100% !important; max-width: 100% !important; }
			.mobile-padding { padding-left: 16px !important; padding-right: 16px !important; }
			.label-col { width: 100% !important; display: block !important; padding-bottom: 4px !important; }
			.value-col { width: 100% !important; display: block !important; padding-left: 0 !important; }
		}
	</style>
</head>
<body style="margin: 0; padding: 24px 0 32px 0; background-color: ##f1f5f9; color: ##1e293b;">
	<center>
		<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: ##f1f5f9;">
			<tr>
				<td align="center">
					<table role="presentation" class="email-container" border="0" cellpadding="0" cellspacing="0" width="640" style="max-width: 640px; background-color: ##ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); border: 1px solid ##e2e8f0;">
						
						<!-- Official Chelan County Header -->
						<tr>
							<td style="background-color: ##0b231a; background-image: linear-gradient(135deg, ##0b231a 0%, ##163e32 100%); padding: 24px 28px; border-bottom: 3px solid ##d4af37;">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
									<tr>
										<td valign="middle">
											<div style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: ##d4af37; margin-bottom: 4px;">
												Chelan County &bull; Washington
											</div>
											<div style="font-size: 20px; font-weight: 700; color: ##ffffff; letter-spacing: -0.3px; line-height: 1.2;">
												Online Services &bull; Form Notification
											</div>
										</td>
										<td align="right" valign="middle" style="padding-left: 12px;">
											<span style="display: inline-block; background-color: rgba(212, 175, 55, 0.15); border: 1px solid ##d4af37; color: ##fef3c7; font-family: monospace; font-size: 12px; font-weight: 700; padding: 5px 10px; border-radius: 4px; white-space: nowrap;">
												#local.refId#
											</span>
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<!-- Sub-Header / Notification Alert -->
						<tr>
							<td style="padding: 24px 28px 12px 28px; background-color: ##ffffff;" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
									<tr>
										<td style="padding-bottom: 16px; border-bottom: 1px solid ##f1f5f9;">
											<div style="font-size: 13px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; color: ##0d9488; margin-bottom: 4px;">
												&bull; New Form Submission Received
											</div>
											<h1 style="margin: 0 0 6px 0; font-size: 22px; font-weight: 700; color: ##0f172a; line-height: 1.3;">
												#EncodeForHTML(local.formTitle)#
											</h1>
											<div style="font-size: 13px; color: ##64748b;">
												Recorded on <strong>#local.submittedAt#</strong>
											</div>
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<cfif Len(local.staffNotes)>
						<!-- Custom Staff Review Instructions Note -->
						<tr>
							<td style="padding: 0 28px 16px 28px;" class="mobile-padding">
								<div style="background-color: ##eff6ff; border-left: 4px solid ##0284c7; border-radius: 4px; padding: 12px 16px;">
									<div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##0369a1; margin-bottom: 4px;">
										&bull; Department Staff Review Instructions
									</div>
									<div style="font-size: 13px; color: ##1e293b; line-height: 1.5; white-space: pre-wrap;">#EncodeForHTML(local.staffNotes)#</div>
								</div>
							</td>
						</tr>
						</cfif>

						<cfif Len(local.submitterEmail) OR (Len(local.submitterName) AND local.submitterName NEQ "Valued Resident") OR Len(local.submitterPhone)>
						<!-- Submitter Quick Summary Card -->
						<tr>
							<td style="padding: 0 28px 16px 28px;" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: ##f8fafc; border: 1px solid ##e2e8f0; border-radius: 6px; padding: 14px 16px;">
									<tr>
										<td style="padding: 12px 16px;">
											<div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##475569; margin-bottom: 8px;">
												Submitter Contact Information
											</div>
											<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
												<cfif Len(local.submitterName) AND local.submitterName NEQ "Valued Resident">
												<tr>
													<td width="90" style="font-size: 13px; color: ##64748b; padding-bottom: 4px;"><strong>Name:</strong></td>
													<td style="font-size: 14px; color: ##0f172a; font-weight: 600; padding-bottom: 4px;">#EncodeForHTML(local.submitterName)#</td>
												</tr>
												</cfif>
												<cfif Len(local.submitterEmail)>
												<tr>
													<td width="90" style="font-size: 13px; color: ##64748b; padding-bottom: 4px;"><strong>Email:</strong></td>
													<td style="font-size: 14px; padding-bottom: 4px;">
														<a href="mailto:#EncodeForHTML(local.submitterEmail)#" style="color: ##0f766e; text-decoration: underline; font-weight: 600;">
															#EncodeForHTML(local.submitterEmail)#
														</a>
														<span style="font-size: 11px; color: ##64748b; margin-left: 6px;">(Clicking "Reply" in your email client will email this address)</span>
													</td>
												</tr>
												</cfif>
												<cfif Len(local.submitterPhone)>
												<tr>
													<td width="90" style="font-size: 13px; color: ##64748b;"><strong>Phone:</strong></td>
													<td style="font-size: 14px; color: ##0f172a;">
														<a href="tel:#EncodeForHTML(local.submitterPhone)#" style="color: ##0f172a; text-decoration: none; font-weight: 500;">
															#EncodeForHTML(local.submitterPhone)#
														</a>
													</td>
												</tr>
												</cfif>
											</table>
										</td>
									</tr>
								</table>
							</td>
						</tr>
						</cfif>

						<!-- Form Submission Data Table -->
						<tr>
							<td style="padding: 4px 28px 20px 28px;" class="mobile-padding">
								<div style="font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##475569; margin-bottom: 10px; border-bottom: 1px solid ##e2e8f0; padding-bottom: 6px;">
									Submitted Form Fields
								</div>
								
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse: separate; border-spacing: 0; width: 100%;">
									<cfset local.fIdx = 0>
									<cfloop array="#local.values#" index="local.val">
										<cfset local.fIdx++>
										<cfset local.isAlt = (local.fIdx MOD 2 EQ 0)>
										<tr style="background-color: #(local.isAlt ? '##f8fafc' : '##ffffff')#;">
											<td class="label-col" width="34%" valign="top" style="padding: 10px 12px; font-size: 13px; font-weight: 600; color: ##334155; border-bottom: 1px solid ##f1f5f9; line-height: 1.4;">
												#EncodeForHTML(local.val.label)#
											</td>
											<td class="value-col" width="66%" valign="top" style="padding: 10px 12px; font-size: 14px; color: ##0f172a; border-bottom: 1px solid ##f1f5f9; line-height: 1.5; word-break: break-word;">
												<cfif local.val.type EQ "file">
													<div style="display: inline-block; background-color: ##f1f5f9; border: 1px solid ##cbd5e1; border-radius: 4px; padding: 4px 8px; font-size: 13px;">
														&##128206; <strong>#EncodeForHTML(local.val.fileName)#</strong>
														<cfif StructKeyExists(local.val, "fileSize") AND Val(local.val.fileSize) GT 0>
															<span style="color: ##64748b; font-size: 11px;">(#local.formatBytes(local.val.fileSize)#)</span>
														</cfif>
													</div>
													<div style="font-size: 11px; color: ##64748b; margin-top: 3px;">
														Stored securely in county file storage. Accessible via CMS Admin.
													</div>
												<cfelseif local.val.type EQ "textarea">
													<div style="background-color: ##f8fafc; border-left: 3px solid ##0b231a; padding: 8px 12px; font-size: 13px; color: ##1e293b; border-radius: 0 4px 4px 0; white-space: pre-wrap; font-family: inherit;">#EncodeForHTML(local.val.value)#</div>
												<cfelseif local.val.type EQ "rating" OR local.val.type EQ "star">
													<span style="color: ##eab308; font-size: 16px;">
														<cfloop from="1" to="5" index="local.s">
															<cfif local.s LTE Val(local.val.value)>&##9733;<cfelse>&##9734;</cfif>
														</cfloop>
													</span>
													<strong style="margin-left: 4px; font-size: 13px; color: ##475569;">(#local.val.value# / 5)</strong>
												<cfelseif local.val.type EQ "email">
													<a href="mailto:#EncodeForHTML(local.val.value)#" style="color: ##0f766e; text-decoration: underline;">
														#EncodeForHTML(local.val.value)#
													</a>
												<cfelseif local.val.type EQ "tel" OR local.val.type EQ "phone">
													<a href="tel:#EncodeForHTML(local.val.value)#" style="color: ##0f172a; text-decoration: none;">
														#EncodeForHTML(local.val.value)#
													</a>
												<cfelseif local.val.type EQ "url">
													<a href="#EncodeForHTML(local.val.value)#" target="_blank" rel="noopener noreferrer" style="color: ##0f766e; text-decoration: underline;">
														#EncodeForHTML(local.val.value)#
													</a>
												<cfelse>
													#Replace(EncodeForHTML(local.val.value), Chr(10), "<br/>", "all")#
												</cfif>
											</td>
										</tr>
									</cfloop>
								</table>
							</td>
						</tr>

						<!-- Admin CTA Button -->
						<tr>
							<td style="padding: 10px 28px 24px 28px; background-color: ##ffffff;" align="center" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td align="center" style="border-radius: 6px; background-color: ##0b231a; background-image: linear-gradient(135deg, ##0b231a 0%, ##163e32 100%);">
											<a href="#EncodeForHTML(local.adminUrl)#" target="_blank" style="font-size: 14px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: ##ffffff; text-decoration: none; padding: 12px 24px; border-radius: 6px; border: 1px solid ##0b231a; display: inline-block; font-weight: 600; letter-spacing: 0.2px;">
												&rarr; Open Form Submissions in CMS Admin
											</a>
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<!-- Audit & Security Metadata -->
						<tr>
							<td style="padding: 16px 28px; background-color: ##f8fafc; border-top: 1px solid ##e2e8f0; font-size: 11px; color: ##64748b; line-height: 1.5;" class="mobile-padding">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
									<tr>
										<td>
											<strong>Submission Audit:</strong> Ref ID: <code style="font-family: monospace; color: ##0f172a; background: ##e2e8f0; padding: 1px 4px; border-radius: 3px;">#local.refId#</code> &bull; IP: <code style="font-family: monospace; color: ##0f172a;">#local.ipAddress#</code><br/>
											<strong>Anti-Spam Verification:</strong> Passed honeypot &amp; timing verification &bull; Legitimate resident activity.
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<!-- County Standard Footer -->
						<tr>
							<td style="padding: 20px 28px; background-color: ##0b231a; color: ##94a3b8; font-size: 11px; line-height: 1.6; text-align: center; border-top: 2px solid ##d4af37;" class="mobile-padding">
								<div style="font-weight: 700; color: ##ffffff; font-size: 12px; margin-bottom: 4px;">
									Chelan County Government &bull; State of Washington
								</div>
								<div>
									Chelan County Courthouse &bull; 350 Orondo Avenue, Wenatchee, WA 98801 &bull; (509) 667-6200
								</div>
								<div style="color: ##64748b; margin-top: 6px;">
									This automated notification was generated by the Chelan County Website Form Builder Engine.
								</div>
							</td>
						</tr>

					</table>
				</td>
			</tr>
		</table>
	</center>
</body>
</html>
				</cfmailpart>
			</cfmail>
		</cfif>
		<cfset writeLog(type="information", file="form-builder", text="Staff notification successfully dispatched for #local.refId# to #local.targetTo#")>
	<cfcatch type="any">
		<cfset writeLog(type="warning", file="form-builder", text="Staff notification email failed for #local.refId# to #local.targetTo#: #cfcatch.message# #cfcatch.detail#")>
	</cfcatch>
	</cftry>
</cfif>

<!--- ======================================================================
      2. CITIZEN CONFIRMATION / AUTO-RESPONDER EMAIL
      Sent directly to resident if user confirmation is enabled and email is present
      ====================================================================== --->
<cfif local.userEnabled AND Len(local.submitterEmail) AND IsValid("email", local.submitterEmail)>
	<cftry>
		<cfmail
			to="#local.submitterEmail#"
			from="#local.userFromEmail#"
			replyto="#local.userReplyTo#"
			subject="#local.userSubject#"
			type="html">

			<cfmailpart type="text/plain" charset="utf-8">
================================================================================
CHELAN COUNTY • SUBMISSION CONFIRMATION
================================================================================

Hello <cfif Len(local.submitterName) AND local.submitterName NEQ "Valued Resident">#local.submitterName#<cfelse>Valued Resident</cfif>,

<cfif Len(local.userCustomMsg)>
#local.userCustomMsg#
<cfelse>
Thank you for contacting Chelan County. This email confirms that we have received your submission for:

  "#local.formTitle#"
</cfif>

REFERENCE NUMBER: #local.refId#
RECEIVED ON:      #local.submittedAt#

Please retain this reference number (#local.refId#) for your records. The appropriate county department has been notified and will review your submission.

If additional information or follow-up is necessary, county staff will contact you directly using the contact details provided in your submission.

<cfif local.userIncludeSum>
--------------------------------------------------------------------------------
SUMMARY OF WHAT YOU SUBMITTED:
--------------------------------------------------------------------------------
<cfloop array="#local.values#" index="local.item">
* #local.item.label#:
  <cfif local.item.type EQ "file">
    [Uploaded File] #local.item.fileName#
  <cfelseif local.item.type EQ "rating" OR local.item.type EQ "star">
    #local.item.value# / 5 Stars
  <cfelse>
    #Replace(local.item.value, Chr(10), Chr(10) & "  ", "all")#
  </cfif>

</cfloop>
</cfif>
================================================================================
Chelan County Administration
350 Orondo Avenue, Wenatchee, WA 98801
Phone: (509) 667-6200 | Web: https://www.chelancounty.gov
Office Hours: Monday - Friday, 8:00 AM - 5:00 PM PST
			</cfmailpart>

			<cfmailpart type="text/html" charset="utf-8">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
	<title>Confirmation: #EncodeForHTML(local.formTitle)# Received</title>
	<style type="text/css">
		body { margin: 0; padding: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; background-color: ##f1f5f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		table { border-collapse: collapse; }
		td, th { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		@media only screen and (max-width: 640px) {
			.email-container { width: 100% !important; max-width: 100% !important; }
			.mobile-padding { padding-left: 16px !important; padding-right: 16px !important; }
		}
	</style>
</head>
<body style="margin: 0; padding: 24px 0 32px 0; background-color: ##f1f5f9; color: ##1e293b;">
	<center>
		<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: ##f1f5f9;">
			<tr>
				<td align="center">
					<table role="presentation" class="email-container" border="0" cellpadding="0" cellspacing="0" width="640" style="max-width: 640px; background-color: ##ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); border: 1px solid ##e2e8f0;">
						
						<!-- Official Header -->
						<tr>
							<td style="background-color: ##0b231a; background-image: linear-gradient(135deg, ##0b231a 0%, ##163e32 100%); padding: 24px 28px; border-bottom: 3px solid ##d4af37;">
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
									<tr>
										<td valign="middle">
											<div style="font-size: 11px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: ##d4af37; margin-bottom: 4px;">
												Chelan County &bull; Washington
											</div>
											<div style="font-size: 20px; font-weight: 700; color: ##ffffff; letter-spacing: -0.3px; line-height: 1.2;">
												Submission Confirmation
											</div>
										</td>
										<td align="right" valign="middle">
											<span style="display: inline-block; background-color: ##10b981; color: ##ffffff; font-size: 12px; font-weight: 700; padding: 4px 12px; border-radius: 20px; text-transform: uppercase; letter-spacing: 0.5px;">
												&check; Received
											</span>
										</td>
									</tr>
								</table>
							</td>
						</tr>

						<!-- Greeting & Confirmation Banner -->
						<tr>
							<td style="padding: 28px 28px 16px 28px;" class="mobile-padding">
								<p style="margin: 0 0 14px 0; font-size: 16px; color: ##1e293b; line-height: 1.5;">
									Hello <strong><cfif Len(local.submitterName) AND local.submitterName NEQ "Valued Resident">#EncodeForHTML(local.submitterName)#<cfelse>Valued Resident</cfif></strong>,
								</p>
								
								<cfif Len(local.userCustomMsg)>
									<div style="margin: 0 0 16px 0; font-size: 15px; color: ##334155; line-height: 1.6; white-space: pre-wrap;">#EncodeForHTML(local.userCustomMsg)#</div>
								<cfelse>
									<p style="margin: 0 0 16px 0; font-size: 15px; color: ##334155; line-height: 1.6;">
										Thank you for contacting Chelan County. This email confirms that we have successfully received your submission for <strong>#EncodeForHTML(local.formTitle)#</strong>.
									</p>
								</cfif>

								<!-- Reference Number Callout Box -->
								<div style="background-color: ##f0fdf4; border: 1px solid ##bbf7d0; border-radius: 6px; padding: 16px 20px; margin: 18px 0 20px 0;">
									<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
										<tr>
											<td>
												<div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##166534; margin-bottom: 2px;">
													Your Official Confirmation Reference Number
												</div>
												<div style="font-family: monospace; font-size: 20px; font-weight: 700; color: ##14532d; letter-spacing: 1px;">
													#local.refId#
												</div>
												<div style="font-size: 12px; color: ##15803d; margin-top: 4px;">
													Recorded on #local.submittedAt#. Please save this number for future inquiries.
												</div>
											</td>
										</tr>
									</table>
								</div>

								<p style="margin: 0 0 20px 0; font-size: 14px; color: ##475569; line-height: 1.6;">
									Our staff has been notified of your submission. If follow-up or additional documentation is needed, a county representative will reach out to you directly.
								</p>
							</td>
						</tr>

						<cfif local.userIncludeSum>
						<!-- Submitter Copy of Fields -->
						<tr>
							<td style="padding: 0 28px 24px 28px;" class="mobile-padding">
								<div style="font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: ##475569; margin-bottom: 10px; border-bottom: 1px solid ##e2e8f0; padding-bottom: 6px;">
									Copy of Submitted Information
								</div>
								
								<table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse: separate; border-spacing: 0; width: 100%;">
									<cfset local.cIdx = 0>
									<cfloop array="#local.values#" index="local.val">
										<cfset local.cIdx++>
										<cfset local.isAlt = (local.cIdx MOD 2 EQ 0)>
										<tr style="background-color: #(local.isAlt ? '##f8fafc' : '##ffffff')#;">
											<td width="36%" valign="top" style="padding: 9px 12px; font-size: 13px; font-weight: 600; color: ##334155; border-bottom: 1px solid ##f1f5f9; line-height: 1.4;">
												#EncodeForHTML(local.val.label)#
											</td>
											<td width="64%" valign="top" style="padding: 9px 12px; font-size: 13px; color: ##0f172a; border-bottom: 1px solid ##f1f5f9; line-height: 1.5; word-break: break-word;">
												<cfif local.val.type EQ "file">
													<span style="font-size: 12px; color: ##0f172a; font-weight: 500;">&##128206; #EncodeForHTML(local.val.fileName)#</span>
												<cfelseif local.val.type EQ "textarea">
													<div style="background-color: ##f8fafc; border-left: 2px solid ##0d9488; padding: 6px 10px; font-size: 13px; color: ##1e293b; border-radius: 0 4px 4px 0; white-space: pre-wrap;">#EncodeForHTML(local.val.value)#</div>
												<cfelseif local.val.type EQ "rating" OR local.val.type EQ "star">
													<span style="color: ##eab308;">
														<cfloop from="1" to="5" index="local.s">
															<cfif local.s LTE Val(local.val.value)>&##9733;<cfelse>&##9734;</cfif>
														</cfloop>
													</span> (#local.val.value# / 5)
												<cfelse>
													#Replace(EncodeForHTML(local.val.value), Chr(10), "<br/>", "all")#
												</cfif>
											</td>
										</tr>
									</cfloop>
								</table>
							</td>
						</tr>
						</cfif>

						<!-- County Help & Contact Section -->
						<tr>
							<td style="padding: 16px 28px; background-color: ##f8fafc; border-top: 1px solid ##e2e8f0; font-size: 12px; color: ##475569; line-height: 1.6;" class="mobile-padding">
								<strong>Need Assistance or Have Questions?</strong><br/>
								Please visit our official website at <a href="https://www.chelancounty.gov" style="color: ##0f766e; text-decoration: underline;">www.chelancounty.gov</a> or contact Chelan County Administration at <strong>(509) 667-6200</strong> during business hours (Monday &ndash; Friday, 8:00 AM &ndash; 5:00 PM PST).
							</td>
						</tr>

						<!-- County Standard Footer -->
						<tr>
							<td style="padding: 20px 28px; background-color: ##0b231a; color: ##94a3b8; font-size: 11px; line-height: 1.6; text-align: center; border-top: 2px solid ##d4af37;" class="mobile-padding">
								<div style="font-weight: 700; color: ##ffffff; font-size: 12px; margin-bottom: 4px;">
									Chelan County Government &bull; State of Washington
								</div>
								<div>
									Chelan County Courthouse &bull; 350 Orondo Avenue, Wenatchee, WA 98801 &bull; (509) 667-6200
								</div>
								<div style="color: ##64748b; margin-top: 6px;">
									This is an automated confirmation sent because an inquiry was submitted with this email address.
								</div>
							</td>
						</tr>

					</table>
				</td>
			</tr>
		</table>
	</center>
</body>
</html>
			</cfmailpart>
		</cfmail>
		<cfset writeLog(type="information", file="form-builder", text="Citizen confirmation auto-responder sent for #local.refId# to #local.submitterEmail#")>
	<cfcatch type="any">
		<cfset writeLog(type="warning", file="form-builder", text="Citizen auto-responder failed for #local.refId# to #local.submitterEmail#: #cfcatch.message# #cfcatch.detail#")>
	</cfcatch>
	</cftry>
</cfif>
