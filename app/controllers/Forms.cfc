component extends="Controller" {

	function config() {
		super.config();
		// Allow JSON submissions without CSRF token mismatch if accessed via external API/iframe
		protectsFromForgery(except="submit,saveEmailSettings");
	}

	// Field types that render content only and never collect a value
	variables.FB_DISPLAY_TYPES = "paragraph,heading,divider,section,html";
	// Legacy honeypot names still honored by the public intake endpoint
	variables.FB_LEGACY_HONEYPOTS = ["_chelan_gov_verify", "_hp_verification", "website_url_hp", "fax_number_hp"];
	// Allowed upload extensions for public file fields
	variables.FB_UPLOAD_EXTENSIONS = "pdf,doc,docx,xls,xlsx,txt,rtf,jpg,jpeg,png,gif,heic,webp";
	variables.FB_UPLOAD_MAX_BYTES = 26214400; // 25 MB

	/**
	 * Main Form Builder interface - visual drag-and-drop / click-to-add form creation.
	 * Loads an existing form from the database when ?id= is supplied.
	 */
	function builder() {
		variables.pageTitle = "Form Builder";
		ensureFormDepartments();

		local.initialForm = {};
		if (StructKeyExists(params, "id") && IsNumeric(params.id) && Val(params.id) > 0) {
			local.initialForm = loadFormStruct(id=Val(params.id));
			if (StructIsEmpty(local.initialForm) || !canManageSite(local.initialForm.siteid)) {
				flashInsert(error="The requested form could not be found or you do not have access to its workspace.");
				redirectTo(controller="forms", action="index");
				return;
			}
		}

		local.allWs = getMasterWorkspaces();
		local.activeWs = activeWorkspaceId();
		local.wsObj = resolveUserActiveWorkspace(requestedWs=local.activeWs, role=getCurrentActiveRole());

		variables.fbConfig = {
			"form": local.initialForm,
			"departments": getDepartmentsForClient(),
			"workspaces": local.allWs,
			"activeWorkspaceId": local.activeWs,
			"activeWorkspaceName": StructKeyExists(local.wsObj, "name") ? local.wsObj.name : (Len(local.activeWs) ? local.activeWs : "All Workspaces"),
			"saveUrl": urlFor(controller="forms", action="save"),
			"previewUrl": urlFor(route="formPreview")
		};
		variables.fbConfigJson = safeJsonForScript(variables.fbConfig);
	}

	/**
	 * All Forms listing and management (database backed)
	 */
	function index() {
		variables.pageTitle = "Online Forms Management";
		variables.currentDept = StructKeyExists(params, "dept") ? LCase(Trim(params.dept)) : "all";
		ensureFormDepartments();

		local.siteFilter = getSiteFilterForListing();
		local.where = "f.deletedat IS NULL";
		local.qp = {};
		if (ArrayLen(local.siteFilter)) {
			local.where &= " AND f.siteid IN (:sites)";
			local.qp.sites = { value: ArrayToList(local.siteFilter), cfsqltype: "cf_sql_nvarchar", list: true };
		}

		local.qForms = fbQuery("
			SELECT f.id, f.form_key, f.slug, f.title, f.description, f.status, f.siteid,
			       f.notification_email, f.notification_email_cc, f.email_notifications_enabled,
			       f.submissions_count, f.views_count, f.anti_spam_enabled, f.wcag_compliant,
			       DATEADD(minute, DATEDIFF(minute, SYSUTCDATETIME(), SYSDATETIME()), f.updatedat) AS updated_local,
			       d.code AS dept_code, d.name AS dept_name, d.color_hex AS dept_color, d.badge_class AS dept_badge,
			       (SELECT COUNT(*) FROM form_fields ff WHERE ff.form_id = f.id AND ff.deletedat IS NULL AND ff.is_active = 1) AS field_count,
			       (SELECT COUNT(*) FROM form_submissions s WHERE s.form_id = f.id AND s.deletedat IS NULL AND s.status IN ('received','in_review')) AS pending_count
			FROM forms f
			LEFT JOIN form_departments d ON d.id = f.department_id
			WHERE #local.where#
			ORDER BY f.updatedat DESC
		", local.qp);

		// Distinct field types per form for the component badges
		local.typeMap = {};
		if (local.qForms.recordCount) {
			local.qTypes = fbQuery("
				SELECT DISTINCT form_id, field_type
				FROM form_fields
				WHERE deletedat IS NULL AND is_active = 1 AND form_id IN (:ids)
			", { ids: { value: ValueList(local.qForms.id), cfsqltype: "cf_sql_integer", list: true } });
			for (local.t in local.qTypes) {
				if (!StructKeyExists(local.typeMap, local.t.form_id)) local.typeMap[local.t.form_id] = [];
				ArrayAppend(local.typeMap[local.t.form_id], local.t.field_type);
			}
		}

		local.wsNames = getWorkspaceNameMap();
		local.base = getPublicBaseUrl();
		variables.formsList = [];
		variables.formMetrics = { total: 0, published: 0, draft: 0, archived: 0, submissions: 0, pending: 0, spamBlocked: 0, workspaces: 0, wcagCompliant: 0 };
		local.wsSeen = {};
		local.deptCounts = {};

		for (local.r in local.qForms) {
			local.deptCode = Len(local.r.dept_code) ? local.r.dept_code : "UNASSIGNED";
			local.status = LCase(local.r.status);
			ArrayAppend(variables.formsList, {
				id: local.r.id,
				formKey: local.r.form_key,
				slug: local.r.slug,
				title: local.r.title,
				description: local.r.description,
				status: local.status,
				siteid: local.r.siteid,
				workspaceName: StructKeyExists(local.wsNames, local.r.siteid) ? local.wsNames[local.r.siteid] : local.r.siteid,
				deptCode: local.deptCode,
				deptKey: local.deptCode == "COMMDEV" ? "community" : (local.deptCode == "PW" ? "works" : LCase(local.deptCode)),
				deptName: Len(local.r.dept_name) ? local.r.dept_name : "Unassigned",
				deptColor: REFind("^##[0-9a-fA-F]{3,8}$", local.r.dept_color) ? local.r.dept_color : "##0073aa",
				deptBadge: Len(local.r.dept_badge) ? local.r.dept_badge : "badge-primary",
				deptIcon: getDepartmentIcon(local.deptCode),
				fieldCount: Val(local.r.field_count),
				fieldTypeLabels: getFieldTypeBadges(StructKeyExists(local.typeMap, local.r.id) ? local.typeMap[local.r.id] : []),
				submissionsCount: Val(local.r.submissions_count),
				pendingCount: Val(local.r.pending_count),
				viewsCount: Val(local.r.views_count),
				updatedAt: IsDate(local.r.updated_local) ? local.r.updated_local : "",
				notificationEmail: local.r.notification_email ?: "",
				notificationEmailCc: local.r.notification_email_cc ?: "",
				emailNotificationsEnabled: local.r.email_notifications_enabled ? true : false,
				publicUrl: local.base & urlFor(route="formPreview") & "?slug=" & URLEncodedFormat(local.r.slug),
				editUrl: urlFor(controller="forms", action="builder", params="id=" & local.r.id),
				previewUrl: urlFor(route="formPreview") & "?slug=" & URLEncodedFormat(local.r.slug)
			});

			variables.formMetrics.total++;
			if (StructKeyExists(variables.formMetrics, local.status)) variables.formMetrics[local.status]++;
			variables.formMetrics.submissions += Val(local.r.submissions_count);
			variables.formMetrics.pending += Val(local.r.pending_count);
			if (local.r.wcag_compliant) variables.formMetrics.wcagCompliant++;
			local.wsSeen[local.r.siteid] = true;
			local.deptCounts[local.deptCode] = (StructKeyExists(local.deptCounts, local.deptCode) ? local.deptCounts[local.deptCode] : 0) + 1;
		}
		variables.formMetrics.workspaces = StructCount(local.wsSeen);

		try {
			local.qSpam = fbQuery("SELECT COUNT(*) AS cnt FROM form_audit_logs WHERE action = 'SPAM_BLOCKED'");
			variables.formMetrics.spamBlocked = Val(local.qSpam.cnt);
		} catch (any e) {}

		// Department filter tabs (only departments that are active)
		variables.deptTabs = [];
		local.qDepts = fbQuery("SELECT code, name, color_hex FROM form_departments WHERE deletedat IS NULL AND is_active = 1 ORDER BY name");
		for (local.d in local.qDepts) {
			ArrayAppend(variables.deptTabs, {
				key: local.d.code == "COMMDEV" ? "community" : (local.d.code == "PW" ? "works" : LCase(local.d.code)),
				name: local.d.name,
				color: local.d.color_hex,
				icon: getDepartmentIcon(local.d.code),
				count: StructKeyExists(local.deptCounts, local.d.code) ? local.deptCounts[local.d.code] : 0
			});
		}
	}

	/**
	 * Clean standalone preview for live test / public iframe embed.
	 * Accepts ?slug=, ?id= or ?key= to render a saved form from the database.
	 */
	function preview() {
		variables.pageTitle = "Online Form Preview";
		variables.fbRequested = false;
		local.formData = {};

		if (StructKeyExists(params, "slug") && Len(Trim(params.slug))) {
			variables.fbRequested = true;
			local.formData = loadFormStruct(slug=Trim(params.slug));
		} else if (StructKeyExists(params, "key") && Len(Trim(params.key))) {
			variables.fbRequested = true;
			local.formData = loadFormStruct(formKey=Trim(params.key));
		} else if (StructKeyExists(params, "id") && IsNumeric(params.id)) {
			variables.fbRequested = true;
			local.formData = loadFormStruct(id=Val(params.id));
		}

		// Unpublished forms are only visible to signed-in staff
		if (!StructIsEmpty(local.formData) && local.formData.status != "published" && !isStaffSession()) {
			local.formData = {};
		}

		if (!StructIsEmpty(local.formData)) {
			if (!local.formData.allowIframeEmbed) {
				cfheader(name="X-Frame-Options", value="SAMEORIGIN");
			}
			try {
				fbQuery("UPDATE forms SET views_count = views_count + 1 WHERE id = :id", { id: { value: local.formData.dbId, cfsqltype: "cf_sql_integer" } });
			} catch (any e) {}

			// Never expose internal routing addresses to the public page
			StructDelete(local.formData, "notificationEmail");
			StructDelete(local.formData, "notificationEmailCc");
			StructDelete(local.formData, "schemaJson");
		}

		variables.fbPublicFormJson = safeJsonForScript(local.formData);
		renderView(layout=false, hideDebugInformation=true);
	}

	/**
	 * Saves (creates or updates) a form definition and its fields.
	 * Expects a JSON body: { "form": { ...builder state... } }
	 */
	function save() {
		local.body = readJsonBody();
		if (!IsStruct(local.body) || !StructKeyExists(local.body, "form") || !IsStruct(local.body.form)) {
			renderJson({ "success": false, "message": "Invalid request payload." }, 400);
			return;
		}

		local.f = local.body.form;
		local.title = Left(Trim(local.f.title ?: ""), 255);
		if (!Len(local.title)) {
			renderJson({ "success": false, "message": "A form title is required." }, 422);
			return;
		}

		local.siteid = Left(Trim(local.f.siteid ?: "global"), 100);
		if (!Len(local.siteid)) local.siteid = "global";
		if (!canManageSite(local.siteid)) {
			renderJson({ "success": false, "message": "You do not have permission to save forms in the '#local.siteid#' workspace." }, 403);
			return;
		}

		local.fields = (StructKeyExists(local.f, "fields") && IsArray(local.f.fields)) ? local.f.fields : [];
		ensureFormDepartments();
		local.deptId = resolveDepartmentId(local.f.department ?: "", local.siteid);

		local.status = LCase(Trim(local.f.status ?: "published"));
		if (!ListFind("draft,published,archived", local.status)) local.status = "published";

		local.themeColor = Trim(local.f.themeColor ?: "");
		if (!REFind("^##[0-9a-fA-F]{3,8}$", local.themeColor)) local.themeColor = "##0073aa";

		local.minDelay = Min(Max(Int(Val(local.f.minDelaySeconds ?: 3)), 0), 120);
		local.cooldown = Min(Max(Int(Val(local.f.cooldownSeconds ?: 3)), 0), 60);
		local.honeypot = REReplace(Trim(local.f.honeypotFieldName ?: "_chelan_gov_verify"), "[^A-Za-z0-9_\-]", "", "all");
		if (!Len(local.honeypot)) local.honeypot = "_chelan_gov_verify";

		local.redirectUrl = Left(Trim(local.f.redirectUrl ?: ""), 500);
		if (Len(local.redirectUrl) && !REFindNoCase("^(https?://|/)", local.redirectUrl)) local.redirectUrl = "";

		local.cols = {
			department_id: local.deptId > 0 ? { value: local.deptId, cfsqltype: "cf_sql_integer" } : { value: "", cfsqltype: "cf_sql_integer", null: true },
			siteid: qp(local.siteid),
			title: qp(local.title),
			description: qp(local.f.description ?: "", "cf_sql_longnvarchar", true),
			status: qp(local.status),
			theme_color: qp(local.themeColor),
			submit_text: qp(Len(Trim(local.f.submitText ?: "")) ? Left(Trim(local.f.submitText), 100) : "Submit Form"),
			success_message: qp(local.f.successMessage ?: "", "cf_sql_longnvarchar", true),
			redirect_url: qp(local.redirectUrl, "cf_sql_nvarchar", true),
			notification_email: qp(Left(Trim(local.f.notificationEmail ?: ""), 255), "cf_sql_nvarchar", true),
			notification_email_cc: qp(Left(Trim(local.f.notificationEmailCc ?: ""), 500), "cf_sql_nvarchar", true),
			email_notifications_enabled: qbit(local.f.emailNotificationsEnabled ?: "", true),
			anti_spam_enabled: qbit(local.f.antiSpamEnabled ?: "", true),
			honeypot_field_name: qp(Left(local.honeypot, 100)),
			min_delay_seconds: { value: local.minDelay, cfsqltype: "cf_sql_integer" },
			cooldown_seconds: { value: local.cooldown, cfsqltype: "cf_sql_integer" },
			wcag_compliant: qbit(local.f.wcagCompliant ?: "", true),
			allow_iframe_embed: qbit(local.f.allowIframeEmbed ?: "", true),
			is_standalone_public: qbit(local.f.isStandalonePublic ?: "", true)
		};

		local.dbId = Val(local.f.dbId ?: 0);
		local.action = "FORM_UPDATED";

		try {
			transaction {
				if (local.dbId > 0) {
					local.qExisting = fbQuery("SELECT id, siteid, status, publishedat FROM forms WHERE id = :id AND deletedat IS NULL", { id: { value: local.dbId, cfsqltype: "cf_sql_integer" } });
					if (!local.qExisting.recordCount) {
						transactionRollback();
						renderJson({ "success": false, "message": "This form no longer exists. It may have been removed." }, 404);
						return;
					}
					if (!canManageSite(local.qExisting.siteid)) {
						transactionRollback();
						renderJson({ "success": false, "message": "You do not have permission to edit this form." }, 403);
						return;
					}

					local.setSql = [];
					for (local.c in local.cols) ArrayAppend(local.setSql, "#local.c# = :#local.c#");
					local.publishSql = (local.status == "published" && !IsDate(local.qExisting.publishedat)) ? ", publishedat = SYSUTCDATETIME()" : "";
					local.cols.id = { value: local.dbId, cfsqltype: "cf_sql_integer" };
					fbQuery("UPDATE forms SET #ArrayToList(local.setSql, ', ')#, updatedat = SYSUTCDATETIME()#local.publishSql# WHERE id = :id", local.cols);
				} else {
					local.action = "FORM_CREATED";
					local.cols.form_key = qp(generateFormKey());
					local.cols.slug = qp(uniqueSlug(local.title));
					local.colNames = StructKeyList(local.cols);
					local.colParams = ":" & ListChangeDelims(local.colNames, ", :");
					local.publishCol = local.status == "published" ? ", publishedat" : "";
					local.publishVal = local.status == "published" ? ", SYSUTCDATETIME()" : "";
					local.qIns = fbQuery("INSERT INTO forms (#local.colNames##local.publishCol#) OUTPUT INSERTED.id VALUES (#local.colParams##local.publishVal#)", local.cols);
					local.dbId = local.qIns.id;
				}

				syncFormFields(local.dbId, local.fields);

				// Cache a JSON blueprint of the saved form for exports / downstream renderers
				local.saved = loadFormStruct(id=local.dbId);
				StructDelete(local.saved, "schemaJson");
				fbQuery("UPDATE forms SET schema_json = :j WHERE id = :id", {
					j: { value: SerializeJSON(local.saved), cfsqltype: "cf_sql_longnvarchar" },
					id: { value: local.dbId, cfsqltype: "cf_sql_integer" }
				});
			}
		} catch (any e) {
			writeLog(type="error", file="form-builder", text="Form save failed: #e.message# #e.detail#");
			renderJson({ "success": false, "message": "Unable to save form: #e.message#" }, 500);
			return;
		}

		writeAudit(formId=local.dbId, action=local.action, details={ "title": local.title, "status": local.status, "fields": ArrayLen(local.fields) });

		local.result = loadFormStruct(id=local.dbId);
		StructDelete(local.result, "schemaJson");
		renderJson({
			"success": true,
			"message": local.action == "FORM_CREATED" ? "Form created and saved to the database." : "Form changes saved.",
			"form": local.result
		});
	}

	/**
	 * Soft-deletes a managed form while retaining submission and audit history.
	 */
	function softDelete() {
		local.body = readJsonBody();
		if (!IsStruct(local.body)) {
			renderJson({ "success": false, "message": "Invalid request payload." }, 400);
			return;
		}

		local.formId = Val(local.body.id ?: 0);
		local.frm = getManagedFormRow(local.formId);
		if (StructIsEmpty(local.frm)) {
			renderJson({ "success": false, "message": "Form not found or you do not have access to it." }, 404);
			return;
		}

		try {
			fbQuery("
				UPDATE forms
				SET deletedat = SYSUTCDATETIME(), updatedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });
		} catch (any e) {
			writeLog(type="error", file="form-builder", text="Form soft delete failed for ID #local.frm.id#: #e.message# #e.detail#");
			renderJson({ "success": false, "message": "Unable to delete this form. Please try again." }, 500);
			return;
		}

		writeAudit(formId=local.frm.id, action="FORM_SOFT_DELETED", details={
			"title": local.frm.title,
			"submissionsPreserved": local.frm.submissions_count
		});
		renderJson({
			"success": true,
			"message": "Form deleted. Its submissions and audit history were preserved."
		});
	}

	/**
	/**
	 * Returns email configuration for a specific form (staff alerts + citizen auto-responder)
	 */
	function getEmailSettings() {
		local.formId = Val(params.id ?: (params.key ?: 0));
		local.frm = getManagedFormRow(local.formId);
		if (StructIsEmpty(local.frm)) {
			renderJson({ "success": false, "message": "Form not found or you lack permission to manage it." }, 404);
			return;
		}

		local.q = fbQuery("
			SELECT f.id, f.title, f.slug, f.form_key, f.notification_email, f.notification_email_cc,
			       f.email_notifications_enabled, f.schema_json,
			       d.name AS dept_name, d.alert_email AS dept_alert_email
			FROM forms f
			LEFT JOIN form_departments d ON d.id = f.department_id
			WHERE f.id = :id AND f.deletedat IS NULL
		", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });

		if (!local.q.recordCount) {
			renderJson({ "success": false, "message": "Form not found." }, 404);
			return;
		}
		local.r = QueryGetRow(local.q, 1);

		local.deptAlert = Trim(local.r.dept_alert_email ?: "");
		local.formEmail = Trim(local.r.notification_email ?: "");
		local.deptName  = Trim(local.r.dept_name ?: "County Administration");

		local.resolvedStaffEmail = Len(local.formEmail) ? local.formEmail : (Len(local.deptAlert) ? local.deptAlert : "forms@chelancounty.gov");
		local.resolvedReplyTo    = Len(local.formEmail) ? local.formEmail : (Len(local.deptAlert) ? local.deptAlert : "forms@chelancounty.gov");
		local.resolvedFromName   = Len(local.deptName) && local.deptName != "County Administration" ? local.deptName : "Chelan County Online Services";

		local.emailSettings = {
			"staffNotificationEnabled": local.r.email_notifications_enabled ? true : false,
			"staffEmail": local.resolvedStaffEmail,
			"staffEmailCc": Trim(local.r.notification_email_cc ?: ""),
			"staffSubject": "[New Submission] {{form_title}} ({{reference_id}})",
			"staffNotes": "",
			"userAutoresponderEnabled": true,
			"userSubject": "Confirmation: {{form_title}} Received ({{reference_id}})",
			"userFromName": local.resolvedFromName,
			"userReplyTo": local.resolvedReplyTo,
			"userCustomMessage": "Thank you for contacting Chelan County. We have received your submission and will review it shortly. Please retain your reference number for your records.",
			"userIncludeSummary": true
		};

		if (Len(Trim(local.r.schema_json ?: ""))) {
			try {
				local.parsed = DeserializeJSON(local.r.schema_json);
				if (IsStruct(local.parsed) && StructKeyExists(local.parsed, "emailSettings") && IsStruct(local.parsed.emailSettings)) {
					StructAppend(local.emailSettings, local.parsed.emailSettings, true);
				}
			} catch (any ignore) {}
		}

		// Retrieve form fields for realistic live email preview rendering
		local.qFields = fbQuery("
			SELECT id, field_key, label, field_type, placeholder, options_json
			FROM form_fields
			WHERE form_id = :id AND deletedat IS NULL AND is_active = 1
			  AND field_type NOT IN ('paragraph', 'heading', 'divider', 'html', 'section', 'button')
			ORDER BY sort_order, id
		", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });

		local.fields = [];
		for (local.f in local.qFields) {
			local.sample = "";
			local.lk = LCase(local.f.field_key);
			local.ll = LCase(local.f.label);
			local.lt = LCase(local.f.field_type);

			// Extract first option from options_json if available
			if (Len(Trim(local.f.options_json ?: ""))) {
				try {
					local.opts = DeserializeJSON(local.f.options_json);
					if (IsArray(local.opts) && ArrayLen(local.opts)) {
						if (IsStruct(local.opts[1]) && StructKeyExists(local.opts[1], "label") && Len(Trim(local.opts[1].label))) {
							local.sample = Trim(local.opts[1].label);
						} else if (IsStruct(local.opts[1]) && StructKeyExists(local.opts[1], "value") && Len(Trim(local.opts[1].value))) {
							local.sample = Trim(local.opts[1].value);
						} else if (IsSimpleValue(local.opts[1]) && Len(Trim(local.opts[1]))) {
							local.sample = Trim(local.opts[1]);
						}
					}
				} catch (any ignore) {}
			}

			if (!Len(local.sample)) {
				if (local.lt == "email" || Find("email", local.lk) || Find("email", local.ll)) {
					local.sample = "jane.doe@example.com";
				} else if (local.lt == "phone" || local.lt == "tel" || Find("phone", local.lk) || Find("phone", local.ll)) {
					local.sample = "(509) 555-0199";
				} else if (local.lt == "address" || Find("address", local.lk) || Find("address", local.ll)) {
					local.sample = "350 Orondo Ave, Wenatchee, WA 98801";
				} else if (local.lt == "file" || Find("photo", local.lk) || Find("file", local.ll) || Find("photo", local.ll)) {
					local.sample = "hazard_inspection_photo.jpg (1.8 MB)";
				} else if (local.lt == "date" || Find("date", local.lk) || Find("date", local.ll)) {
					local.sample = "October 22, 2026";
				} else if (Find("urgency", local.lk) || Find("urgency", local.ll)) {
					local.sample = "Medium - Action needed within 48 hours";
				} else if (Find("category", local.lk) || Find("hazard", local.lk) || Find("category", local.ll)) {
					local.sample = "Pothole / Road Surface Repair";
				} else if (Find("road", local.lk) || Find("milepost", local.lk) || Find("intersection", local.ll) || Find("road", local.ll) || Find("location", local.ll)) {
					local.sample = "Chumstick Hwy & Milepost 4.5";
				} else if (Find("name", local.lk) || Find("name", local.ll)) {
					local.sample = "Jane Doe";
				} else if (local.lt == "textarea" || Find("desc", local.lk) || Find("detail", local.ll) || Find("message", local.ll)) {
					local.sample = "Observed road degradation and pothole in westbound travel lane approximately 100 feet past milepost. Requesting maintenance inspection.";
				} else if (Len(Trim(local.f.placeholder ?: ""))) {
					local.sample = Trim(local.f.placeholder);
				} else {
					local.sample = "Completed intake submission value";
				}
			}

			ArrayAppend(local.fields, {
				"id": local.f.id,
				"key": local.f.field_key,
				"label": local.f.label,
				"type": local.f.field_type,
				"sampleValue": local.sample
			});
		}

		renderJson({
			"success": true,
			"form": {
				"id": local.r.id,
				"title": local.r.title,
				"slug": local.r.slug,
				"formKey": local.r.form_key,
				"deptName": local.deptName,
				"deptAlertEmail": local.deptAlert,
				"fields": local.fields
			},
			"emailSettings": local.emailSettings
		});
	}

	/**
	 * Persists email notification and template configuration for a form
	 */
	function saveEmailSettings() {
		local.body = readJsonBody();
		if (!IsStruct(local.body)) {
			renderJson({ "success": false, "message": "Invalid request payload." }, 400);
			return;
		}

		local.formId = Val(local.body.id ?: 0);
		local.frm = getManagedFormRow(local.formId);
		if (StructIsEmpty(local.frm)) {
			renderJson({ "success": false, "message": "Form not found or you lack permission to manage it." }, 404);
			return;
		}

		local.es = StructKeyExists(local.body, "emailSettings") && IsStruct(local.body.emailSettings) ? local.body.emailSettings : {};

		local.staffEnabled   = qbit(local.es.staffNotificationEnabled ?: "", true);
		local.staffEmail     = Left(Trim(local.es.staffEmail ?: ""), 255);
		local.staffEmailCc   = Left(Trim(local.es.staffEmailCc ?: ""), 500);
		local.staffSubject   = Left(Trim(local.es.staffSubject ?: "[New Submission] {{form_title}} ({{reference_id}})"), 255);
		local.staffNotes     = Left(Trim(local.es.staffNotes ?: ""), 2000);

		local.userEnabled    = qbit(local.es.userAutoresponderEnabled ?: "", true);
		local.userSubject    = Left(Trim(local.es.userSubject ?: "Confirmation: {{form_title}} Received ({{reference_id}})"), 255);
		local.userFromName   = Left(Trim(local.es.userFromName ?: "Chelan County Online Services"), 150);
		local.userReplyTo    = Left(Trim(local.es.userReplyTo ?: "forms@chelancounty.gov"), 255);
		local.userMessage    = Left(Trim(local.es.userCustomMessage ?: ""), 4000);
		local.userSummary    = qbit(local.es.userIncludeSummary ?: "", true);

		// Read existing schema_json so other form builder properties are preserved
		local.qCur = fbQuery("SELECT schema_json FROM forms WHERE id = :id", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });
		local.schema = {};
		if (local.qCur.recordCount && Len(Trim(local.qCur.schema_json))) {
			try {
				local.tmp = DeserializeJSON(local.qCur.schema_json);
				if (IsStruct(local.tmp)) local.schema = local.tmp;
			} catch (any ignore) {}
		}

		local.schema.emailSettings = {
			"staffNotificationEnabled": local.staffEnabled.value == 1,
			"staffEmail": local.staffEmail,
			"staffEmailCc": local.staffEmailCc,
			"staffSubject": local.staffSubject,
			"staffNotes": local.staffNotes,
			"userAutoresponderEnabled": local.userEnabled.value == 1,
			"userSubject": local.userSubject,
			"userFromName": local.userFromName,
			"userReplyTo": local.userReplyTo,
			"userCustomMessage": local.userMessage,
			"userIncludeSummary": local.userSummary.value == 1
		};

		try {
			fbQuery("
				UPDATE forms
				SET notification_email = :email,
				    notification_email_cc = :cc,
				    email_notifications_enabled = :enabled,
				    schema_json = :schema,
				    updatedat = SYSUTCDATETIME()
				WHERE id = :id AND deletedat IS NULL
			", {
				email: qp(local.staffEmail, "cf_sql_nvarchar", true),
				cc: qp(local.staffEmailCc, "cf_sql_nvarchar", true),
				enabled: local.staffEnabled,
				schema: { value: SerializeJSON(local.schema), cfsqltype: "cf_sql_longnvarchar" },
				id: { value: local.frm.id, cfsqltype: "cf_sql_integer" }
			});
		} catch (any e) {
			writeLog(type="error", file="form-builder", text="Saving email settings failed for form #local.frm.id#: #e.message# #e.detail#");
			renderJson({ "success": false, "message": "Failed to update email settings: #e.message#" }, 500);
			return;
		}

		writeAudit(formId=local.frm.id, action="FORM_EMAIL_SETTINGS_UPDATED", details={
			"title": local.frm.title,
			"staffEmail": local.staffEmail,
			"staffNotifications": local.staffEnabled.value == 1,
			"userAutoresponder": local.userEnabled.value == 1
		});

		renderJson({
			"success": true,
			"message": "Email settings and templates updated successfully for " & local.frm.title & ".",
			"emailSettings": local.schema.emailSettings
		});
	}

	/**
	 * Form submission endpoint with anti-spam honeypot detection,
	 * submission time-delay verification, and security rate limiting.
	 * Persists to form_submissions / form_submission_values when a saved form key is supplied.
	 */
	function submit() {
		// 1. Merge params with JSON body if present
		local.postData = {};
		StructAppend(local.postData, params, true);
		local.json = readJsonBody();
		if (IsStruct(local.json)) StructAppend(local.postData, local.json, true);

		local.formKey = Trim(local.postData._form_key ?: (local.postData.formKey ?: ""));
		local.formId = Val(REReplace(Trim(local.postData._form_id ?: (local.postData.formId ?: "")), "^form_", "", "one"));
		local.formSlug = Trim(local.postData._form_slug ?: (local.postData.slug ?: ""));

		// Template / unsaved draft previews have no database record - validate only.
		if (!Len(local.formKey) && local.formId == 0 && !Len(local.formSlug)) {
			legacySubmit(local.postData);
			return;
		}

		local.whereClause = Len(local.formKey) ? "f.form_key = :k" : (local.formId > 0 ? "f.id = :id" : "f.slug = :s");
		local.qForm = fbQuery("
			SELECT f.*, d.alert_email AS dept_alert_email, d.name AS dept_name
			FROM forms f
			LEFT JOIN form_departments d ON d.id = f.department_id
			WHERE f.deletedat IS NULL AND #local.whereClause#
		", {
			k: qp(local.formKey),
			id: { value: local.formId, cfsqltype: "cf_sql_integer" },
			s: qp(local.formSlug)
		});

		if (!local.qForm.recordCount || (LCase(local.qForm.status) != "published" && !isStaffSession())) {
			renderJson({ "success": false, "message": "This form is not currently accepting submissions.", "errorCode": "FORM_UNAVAILABLE" }, 404);
			return;
		}
		local.frm = QueryGetRow(local.qForm, 1);

		// 2. Anti-spam: honeypot trap + submission speed trap (per-form settings)
		local.honeypotPassed = true;
		local.speedPassed = true;
		local.elapsedSeconds = "";
		local.loadTimeMs = "";
		if (StructKeyExists(local.postData, "_cf_form_load_time") && IsNumeric(local.postData._cf_form_load_time)) {
			local.loadTimeMs = Val(local.postData._cf_form_load_time);
			local.elapsedSeconds = Int((Now().getTime() - local.loadTimeMs) / 1000);
		}

		if (local.frm.anti_spam_enabled) {
			local.hpNames = Duplicate(variables.FB_LEGACY_HONEYPOTS);
			if (Len(local.frm.honeypot_field_name) && !ArrayFindNoCase(local.hpNames, local.frm.honeypot_field_name)) {
				ArrayAppend(local.hpNames, local.frm.honeypot_field_name);
			}
			for (local.hp in local.hpNames) {
				if (StructKeyExists(local.postData, local.hp) && IsSimpleValue(local.postData[local.hp]) && Len(Trim(local.postData[local.hp]))) {
					local.honeypotPassed = false;
					break;
				}
			}
			if (!local.honeypotPassed) {
				writeAudit(formId=local.frm.id, action="SPAM_BLOCKED", details={ "reason": "honeypot" });
				renderJson({
					"success": false, "securityPassed": false,
					"message": "Anti-spam security verification failed: Automated submission detected.",
					"errorCode": "SPAM_HONEYPOT_TRIGGERED"
				}, 400);
				return;
			}

			if (IsNumeric(local.elapsedSeconds) && local.frm.min_delay_seconds > 0 && local.elapsedSeconds >= 0 && local.elapsedSeconds < local.frm.min_delay_seconds) {
				writeAudit(formId=local.frm.id, action="SPAM_BLOCKED", details={ "reason": "speed_trap", "elapsedSeconds": local.elapsedSeconds });
				renderJson({
					"success": false, "securityPassed": false,
					"message": "Submission rejected: Form was completed too quickly (#local.elapsedSeconds#s). Automated bot protection requires a minimum #local.frm.min_delay_seconds#-second delay.",
					"errorCode": "SUBMISSION_TOO_FAST"
				}, 400);
				return;
			}
		}

		// 3. Collect + validate values against the saved field definitions
		local.payload = {};
		if (StructKeyExists(local.postData, "_payload") && IsSimpleValue(local.postData._payload) && IsJSON(local.postData._payload)) {
			local.tmp = DeserializeJSON(local.postData._payload);
			if (IsStruct(local.tmp)) local.payload = local.tmp;
		} else if (StructKeyExists(local.postData, "values") && IsStruct(local.postData.values)) {
			local.payload = local.postData.values;
		}

		local.qFields = fbQuery("
			SELECT id, field_key, field_type, label, is_required
			FROM form_fields
			WHERE form_id = :id AND deletedat IS NULL AND is_active = 1
			ORDER BY sort_order, id
		", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });

		local.values = [];
		local.pendingFiles = [];
		local.missing = [];
		local.hasAnySubmittedValue = false;
		for (local.fld in local.qFields) {
			if (ListFindNoCase(variables.FB_DISPLAY_TYPES, local.fld.field_type)) continue;
			local.key = local.fld.field_key;

			if (local.fld.field_type == "file") {
				if (StructKeyExists(form, local.key) && Len(form[local.key])) {
					ArrayAppend(local.pendingFiles, local.fld);
					local.hasAnySubmittedValue = true;
				} else if (local.fld.is_required) {
					ArrayAppend(local.missing, local.fld.label);
				}
				continue;
			}

			local.raw = StructKeyExists(local.payload, local.key) ? local.payload[local.key] : (StructKeyExists(local.postData, local.key) ? local.postData[local.key] : "");
			if (local.fld.field_type == "address" && !IsStruct(local.raw) && !Len(Trim(IsSimpleValue(local.raw) ? local.raw : ""))) {
				if (StructKeyExists(local.postData, local.key & "_street") || StructKeyExists(local.postData, local.key & "_city")) {
					local.raw = {
						street: Trim(local.postData[local.key & "_street"] ?: ""),
						street2: Trim(local.postData[local.key & "_street2"] ?: ""),
						city: Trim(local.postData[local.key & "_city"] ?: ""),
						state: Trim(local.postData[local.key & "_state"] ?: ""),
						zip: Trim(local.postData[local.key & "_zip"] ?: "")
					};
				}
			} else if (local.fld.field_type == "checkbox" && !IsArray(local.raw) && !Len(Trim(IsSimpleValue(local.raw) ? local.raw : ""))) {
				if (StructKeyExists(local.postData, local.key & "[]")) {
					local.raw = local.postData[local.key & "[]"];
				}
			}
			local.display = formatSubmittedValue(local.fld.field_type, local.raw);
			if (Len(Trim(local.display)) && !(local.fld.field_type == "switch" && local.display == "No")) {
				local.hasAnySubmittedValue = true;
			}
			if (local.fld.is_required && (!Len(Trim(local.display)) || (local.fld.field_type == "switch" && local.display == "No"))) {
				ArrayAppend(local.missing, local.fld.label);
			}
			ArrayAppend(local.values, {
				fieldId: local.fld.id, key: local.key, label: local.fld.label, type: local.fld.field_type,
				value: Left(local.display, 20000), raw: local.raw
			});
		}

		if (ArrayLen(local.missing)) {
			renderJson({
				"success": false,
				"message": "Please complete the following required fields: " & ArrayToList(local.missing, ", "),
				"errorCode": "VALIDATION_FAILED",
				"missing": local.missing
			}, 422);
			return;
		}

		if (!local.hasAnySubmittedValue) {
			renderJson({
				"success": false,
				"message": "Empty form submissions are not allowed. Please fill in the form fields before submitting.",
				"errorCode": "EMPTY_SUBMISSION"
			}, 422);
			return;
		}

		local.refId = generateReferenceId();

		// 4. Store uploaded files (outside of transaction so failures can be reported cleanly)
		local.uploadedFiles = [];
		if (ArrayLen(local.pendingFiles)) {
			local.uploadDir = ensureUploadDir(local.frm.form_key, local.refId);
			try {
				for (local.fld in local.pendingFiles) {
					local.up = fileUpload(local.uploadDir.absolute, local.fld.field_key, "", "makeunique");
					local.ext = LCase(ListLast(local.up.serverFile, "."));
					if (!ListFind(variables.FB_UPLOAD_EXTENSIONS, local.ext) || local.up.fileSize > variables.FB_UPLOAD_MAX_BYTES) {
						throw(type="FormBuilder.UploadRejected", message="'#local.up.clientFile#' is not an accepted file. Allowed types: #variables.FB_UPLOAD_EXTENSIONS# (max 25MB).");
					}
					ArrayAppend(local.uploadedFiles, {
						fieldId: local.fld.id, key: local.fld.field_key, label: local.fld.label, type: "file",
						value: local.up.clientFile,
						filePath: local.uploadDir.relative & local.up.serverFile,
						fileName: local.up.clientFile,
						fileSize: local.up.fileSize,
						mime: local.up.contentType & "/" & local.up.contentSubType
					});
				}
			} catch (any e) {
				try { DirectoryDelete(local.uploadDir.absolute, true); } catch (any ignore) {}
				renderJson({ "success": false, "message": e.type == "FormBuilder.UploadRejected" ? e.message : "File upload failed: #e.message#", "errorCode": "UPLOAD_FAILED" }, 422);
				return;
			}
			ArrayAppend(local.values, local.uploadedFiles, true);
		}

		// 5. Persist submission + normalized EAV values
		local.snapshot = {};
		for (local.v in local.values) {
			local.snapshot[local.v.key] = { "label": local.v.label, "type": local.v.type, "value": StructKeyExists(local.v, "raw") ? local.v.raw : local.v.value };
		}
		local.submissionJson = SerializeJSON({
			"formKey": local.frm.form_key,
			"referenceId": local.refId,
			"submittedAt": DateTimeFormat(Now(), "yyyy-mm-dd'T'HH:nn:ss"),
			"values": local.snapshot
		});

		try {
			transaction {
				local.qSub = fbQuery("
					INSERT INTO form_submissions
						(form_id, reference_id, status, load_time_epoch_ms, elapsed_seconds, honeypot_passed, speed_trap_passed, is_flagged_as_spam, ip_address, user_agent, submission_json)
					OUTPUT INSERTED.id
					VALUES (:form_id, :ref, 'received', :load_ms, :elapsed, :hp, :speed, 0, :ip, :ua, :json)
				", {
					form_id: { value: local.frm.id, cfsqltype: "cf_sql_integer" },
					ref: qp(local.refId),
					load_ms: { value: local.loadTimeMs, cfsqltype: "cf_sql_bigint", null: !IsNumeric(local.loadTimeMs) },
					elapsed: { value: local.elapsedSeconds, cfsqltype: "cf_sql_integer", null: !IsNumeric(local.elapsedSeconds) },
					hp: { value: local.honeypotPassed ? 1 : 0, cfsqltype: "cf_sql_bit" },
					speed: { value: local.speedPassed ? 1 : 0, cfsqltype: "cf_sql_bit" },
					ip: qp(Left(cgi.remote_addr, 45), "cf_sql_nvarchar", true),
					ua: qp(Left(cgi.http_user_agent, 500), "cf_sql_nvarchar", true),
					json: { value: local.submissionJson, cfsqltype: "cf_sql_longnvarchar" }
				});
				local.submissionId = local.qSub.id;

				for (local.v in local.values) {
					fbQuery("
						INSERT INTO form_submission_values
							(submission_id, field_id, field_key, field_label, field_type, field_value, file_path, file_name, file_size_bytes, file_mime_type)
						VALUES (:sid, :fid, :fkey, :flabel, :ftype, :fval, :fpath, :fname, :fsize, :fmime)
					", {
						sid: { value: local.submissionId, cfsqltype: "cf_sql_integer" },
						fid: { value: local.v.fieldId, cfsqltype: "cf_sql_integer" },
						fkey: qp(local.v.key),
						flabel: qp(Left(local.v.label, 255), "cf_sql_nvarchar", true),
						ftype: qp(Left(local.v.type, 50), "cf_sql_nvarchar", true),
						fval: qp(local.v.value, "cf_sql_longnvarchar", true),
						fpath: qp(local.v.filePath ?: "", "cf_sql_nvarchar", true),
						fname: qp(local.v.fileName ?: "", "cf_sql_nvarchar", true),
						fsize: { value: Val(local.v.fileSize ?: 0), cfsqltype: "cf_sql_bigint", null: !StructKeyExists(local.v, "fileSize") },
						fmime: qp(Left(local.v.mime ?: "", 100), "cf_sql_nvarchar", true)
					});
				}

				fbQuery("UPDATE forms SET submissions_count = submissions_count + 1 WHERE id = :id", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });
			}
		} catch (any e) {
			writeLog(type="error", file="form-builder", text="Submission save failed for form #local.frm.id#: #e.message# #e.detail#");
			renderJson({ "success": false, "message": "We were unable to record your submission. Please try again shortly.", "errorCode": "SERVER_ERROR" }, 500);
			return;
		}

		writeAudit(formId=local.frm.id, submissionId=local.submissionId, action="SUBMISSION_RECEIVED", details={ "referenceId": local.refId, "elapsedSeconds": local.elapsedSeconds });
		sendSubmissionNotification(local.frm, local.refId, local.values);

		renderJson({
			"success": true,
			"message": Len(Trim(local.frm.success_message)) ? local.frm.success_message : "Thank you! Your form submission has been successfully received and recorded.",
			"timestamp": DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss"),
			"referenceId": local.refId,
			"redirectUrl": local.frm.redirect_url,
			"securityPassed": true,
			"persisted": true
		});
	}

	/**
	 * JSON list of recent submissions for a form (used by the Forms directory modal)
	 */
	function submissions() {
		local.frm = getManagedFormRow(Val(params.id ?: 0));
		if (StructIsEmpty(local.frm)) {
			renderJson({ "success": false, "message": "Form not found." }, 404);
			return;
		}

		local.qSubs = fbQuery("
			SELECT TOP 100 id, reference_id, status, elapsed_seconds, honeypot_passed, speed_trap_passed, is_flagged_as_spam,
			       DATEADD(minute, DATEDIFF(minute, SYSUTCDATETIME(), SYSDATETIME()), submitted_at) AS submitted_local
			FROM form_submissions
			WHERE form_id = :id AND deletedat IS NULL
			ORDER BY submitted_at DESC
		", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });

		local.valueMap = {};
		if (local.qSubs.recordCount) {
			local.qVals = fbQuery("
				SELECT submission_id, field_key, field_label, field_type, field_value, file_name
				FROM form_submission_values
				WHERE submission_id IN (:ids)
				ORDER BY id
			", { ids: { value: ValueList(local.qSubs.id), cfsqltype: "cf_sql_integer", list: true } });
			for (local.v in local.qVals) {
				if (!StructKeyExists(local.valueMap, local.v.submission_id)) local.valueMap[local.v.submission_id] = [];
				ArrayAppend(local.valueMap[local.v.submission_id], {
					"key": local.v.field_key, "label": local.v.field_label, "type": local.v.field_type,
					"value": local.v.field_value, "fileName": local.v.file_name
				});
			}
		}

		local.rows = [];
		for (local.s in local.qSubs) {
			local.vals = StructKeyExists(local.valueMap, local.s.id) ? local.valueMap[local.s.id] : [];
			local.respondent = "";
			local.firstName = "";
			local.lastName = "";
			local.contactEmail = "";
			local.contactPhone = "";
			for (local.v in local.vals) {
				local.lblLower = LCase(local.v.label ?: "");
				local.valTrim = Trim(local.v.value ?: "");
				if (!Len(local.valTrim)) continue;
				if (!Len(local.firstName) && FindNoCase("first", local.lblLower) && FindNoCase("name", local.lblLower)) {
					local.firstName = local.valTrim;
				} else if (!Len(local.lastName) && FindNoCase("last", local.lblLower) && FindNoCase("name", local.lblLower)) {
					local.lastName = local.valTrim;
				} else if (!Len(local.respondent) && local.v.type == "text" && FindNoCase("name", local.lblLower)) {
					local.respondent = local.valTrim;
				}
				if (!Len(local.contactEmail) && (local.v.type == "email" || FindNoCase("email", local.lblLower))) {
					local.contactEmail = local.valTrim;
				} else if (!Len(local.contactPhone) && (local.v.type == "phone" || local.v.type == "tel" || FindNoCase("phone", local.lblLower))) {
					local.contactPhone = local.valTrim;
				}
			}
			if (Len(local.firstName) || Len(local.lastName)) {
				local.respondent = Trim(local.firstName & " " & local.lastName);
			}
			local.contact = Len(local.contactEmail) && Len(local.contactPhone)
				? (local.contactEmail & " | " & local.contactPhone)
				: (Len(local.contactEmail) ? local.contactEmail : (Len(local.contactPhone) ? local.contactPhone : "Not Provided"));
			ArrayAppend(local.rows, {
				"id": local.s.id,
				"referenceId": local.s.reference_id,
				"status": local.s.status,
				"submittedAt": IsDate(local.s.submitted_local) ? DateTimeFormat(local.s.submitted_local, "mmm d, yyyy h:nn tt") : "",
				"elapsedSeconds": local.s.elapsed_seconds,
				"verified": (local.s.honeypot_passed && local.s.speed_trap_passed && !local.s.is_flagged_as_spam),
				"respondent": Len(local.respondent) ? local.respondent : "Anonymous Respondent",
				"contact": local.contact,
				"values": local.vals
			});
		}

		renderJson({ "success": true, "form": { "id": local.frm.id, "title": local.frm.title }, "total": local.frm.submissions_count, "submissions": local.rows });
	}

	/**
	 * Soft-deletes a single form submission and updates the form's submissions_count
	 */
	function deleteSubmission() {
		local.body = readJsonBody();
		local.subId = Val(IsStruct(local.body) && StructKeyExists(local.body, "submissionId") ? local.body.submissionId : (params.submissionId ?: 0));
		if (local.subId <= 0) {
			renderJson({ "success": false, "message": "Invalid submission ID." }, 400);
			return;
		}
		local.qSub = fbQuery("SELECT id, form_id, reference_id FROM form_submissions WHERE id = :sid AND deletedat IS NULL", {
			sid: { value: local.subId, cfsqltype: "cf_sql_integer" }
		});
		if (!local.qSub.recordCount) {
			renderJson({ "success": false, "message": "Submission not found." }, 404);
			return;
		}
		local.frm = getManagedFormRow(local.qSub.form_id);
		if (StructIsEmpty(local.frm)) {
			renderJson({ "success": false, "message": "You do not have permission to manage this form." }, 403);
			return;
		}
		fbQuery("UPDATE form_submissions SET deletedat = SYSUTCDATETIME() WHERE id = :sid", {
			sid: { value: local.subId, cfsqltype: "cf_sql_integer" }
		});
		fbQuery("UPDATE forms SET submissions_count = (SELECT COUNT(*) FROM form_submissions WHERE form_id = :fid AND deletedat IS NULL) WHERE id = :fid", {
			fid: { value: local.frm.id, cfsqltype: "cf_sql_integer" }
		});
		writeAudit(formId=local.frm.id, submissionId=local.subId, action="SUBMISSION_DELETED", details={ "referenceId": local.qSub.reference_id });
		renderJson({ "success": true, "message": "Submission " & local.qSub.reference_id & " deleted." });
	}

	/**
	 * CSV export of all submissions for a form
	 */
	function exportCsv() {
		local.frm = getManagedFormRow(Val(params.id ?: 0));
		if (StructIsEmpty(local.frm)) {
			renderText(text="Form not found.", status=404);
			return;
		}

		local.qCols = fbQuery("
			SELECT field_key, label FROM form_fields
			WHERE form_id = :id AND field_type NOT IN (:display)
			ORDER BY CASE WHEN deletedat IS NULL THEN 0 ELSE 1 END, sort_order, id
		", {
			id: { value: local.frm.id, cfsqltype: "cf_sql_integer" },
			display: { value: variables.FB_DISPLAY_TYPES, cfsqltype: "cf_sql_nvarchar", list: true }
		});

		local.qSubs = fbQuery("
			SELECT id, reference_id, status, elapsed_seconds,
			       DATEADD(minute, DATEDIFF(minute, SYSUTCDATETIME(), SYSDATETIME()), submitted_at) AS submitted_local
			FROM form_submissions
			WHERE form_id = :id AND deletedat IS NULL
			ORDER BY submitted_at DESC
		", { id: { value: local.frm.id, cfsqltype: "cf_sql_integer" } });

		local.valueMap = {};
		if (local.qSubs.recordCount) {
			local.qVals = fbQuery("
				SELECT submission_id, field_key, field_value FROM form_submission_values WHERE submission_id IN (:ids)
			", { ids: { value: ValueList(local.qSubs.id), cfsqltype: "cf_sql_integer", list: true } });
			for (local.v in local.qVals) {
				local.valueMap[local.v.submission_id & "|" & LCase(local.v.field_key)] = local.v.field_value;
			}
		}

		local.header = ["Reference ID", "Submitted At", "Status", "Elapsed Seconds"];
		for (local.c in local.qCols) ArrayAppend(local.header, local.c.label);
		local.lines = [csvRow(local.header)];
		for (local.s in local.qSubs) {
			local.row = [local.s.reference_id, IsDate(local.s.submitted_local) ? DateTimeFormat(local.s.submitted_local, "yyyy-mm-dd HH:nn:ss") : "", local.s.status, local.s.elapsed_seconds];
			for (local.c in local.qCols) {
				local.k = local.s.id & "|" & LCase(local.c.field_key);
				ArrayAppend(local.row, StructKeyExists(local.valueMap, local.k) ? local.valueMap[local.k] : "");
			}
			ArrayAppend(local.lines, csvRow(local.row));
		}

		writeAudit(formId=local.frm.id, action="SUBMISSIONS_EXPORTED", details={ "rows": local.qSubs.recordCount });
		cfheader(name="Content-Disposition", value='attachment; filename="#local.frm.slug#-submissions-#DateFormat(Now(), "yyyymmdd")#.csv"');
		cfheader(name="Content-Type", value="text/csv; charset=utf-8");
		renderText(text=Chr(65279) & ArrayToList(local.lines, Chr(13) & Chr(10)));
	}

	// =========================================================================
	// Private helpers
	// =========================================================================

	private any function fbQuery(required string sql, struct params = {}) {
		return queryExecute(arguments.sql, arguments.params, { datasource: "ChelanCountyWebsite" });
	}

	private struct function qp(any value, string type = "cf_sql_nvarchar", boolean nullIfEmpty = false) {
		local.v = IsSimpleValue(arguments.value) ? arguments.value : SerializeJSON(arguments.value);
		if (arguments.nullIfEmpty && !Len(Trim(local.v))) {
			return { value: "", cfsqltype: arguments.type, null: true };
		}
		return { value: local.v, cfsqltype: arguments.type };
	}

	private struct function qbit(any value, boolean defaultValue = false) {
		local.b = arguments.defaultValue;
		if (IsSimpleValue(arguments.value) && Len(Trim(arguments.value)) && IsBoolean(arguments.value)) local.b = arguments.value ? true : false;
		return { value: local.b ? 1 : 0, cfsqltype: "cf_sql_bit" };
	}

	private void function renderJson(required any data, numeric status = 200) {
		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text=SerializeJSON(arguments.data), status=arguments.status);
	}

	private any function readJsonBody() {
		try {
			local.content = GetHTTPRequestData().content;
			if (IsBinary(local.content)) local.content = CharsetEncode(local.content, "utf-8");
			if (Len(Trim(local.content)) && IsJSON(local.content)) return healUtf8MojibakeData(DeserializeJSON(healUtf8Mojibake(local.content)));
		} catch (any e) {}
		return "";
	}

	/** Serializes a struct for safe embedding inside an inline <script> block */
	private string function safeJsonForScript(required any data) {
		if (IsStruct(arguments.data) && StructIsEmpty(arguments.data)) return "null";
		return Replace(Replace(SerializeJSON(arguments.data), "</", "<\/", "all"), Chr(8232), "\u2028", "all");
	}

	private boolean function isStaffSession() {
		return StructKeyExists(session, "user") && IsStruct(session.user) && StructKeyExists(session.user, "id");
	}

	private string function currentActor() {
		if (StructKeyExists(session, "user") && IsStruct(session.user)) {
			if (Len(session.user.email ?: "")) return Left(session.user.email, 100);
			if (Len(session.user.username ?: "")) return Left(session.user.username, 100);
		}
		return "System";
	}

	private boolean function canManageSite(required string siteid) {
		local.s = LCase(Trim(arguments.siteid));
		if (!Len(local.s) || local.s == "global" || local.s == "all") return true;
		local.role = getCurrentActiveRole();
		if (local.role == "admin" || ArrayFindNoCase(getUserAssignedWorkspaceCodes(), "global") > 0) return true;
		return isWorkspaceAccessible(local.s, local.role);
	}

	/** Workspaces to restrict the forms directory to (empty array = no restriction) */
	private array function getSiteFilterForListing() {
		local.assigned = getUserAssignedWorkspaceCodes();
		local.isGlobal = ArrayFindNoCase(local.assigned, "global") > 0;
		local.activeWs = (StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace))) ? LCase(Trim(cookie.cmsadmin_workspace)) : "global";

		if (local.activeWs != "global" && local.activeWs != "all" && isWorkspaceAccessible(local.activeWs)) {
			local.filters = [local.activeWs];
			if (Right(local.activeWs, 1) == "s") {
				local.sing = Left(local.activeWs, Len(local.activeWs) - 1);
				if (Len(local.sing) && !ArrayFindNoCase(local.filters, local.sing)) ArrayAppend(local.filters, local.sing);
			} else {
				local.plur = local.activeWs & "s";
				if (!ArrayFindNoCase(local.filters, local.plur)) ArrayAppend(local.filters, local.plur);
			}
			return local.filters;
		}
		if (local.isGlobal) return [];
		return ArrayLen(local.assigned) ? local.assigned : ["__none__"];
	}

	private struct function getWorkspaceNameMap() {
		local.map = {};
		try {
			for (local.w in getMasterWorkspaces()) local.map[local.w.id] = local.w.name;
		} catch (any e) {}
		return local.map;
	}

	private string function getPublicBaseUrl() {
		return ((cgi.https == "on" || cgi.server_port_secure == 1) ? "https" : "http") & "://" & cgi.http_host;
	}

	private struct function getManagedFormRow(required numeric id) {
		if (arguments.id <= 0) return {};
		local.q = fbQuery("SELECT id, title, slug, siteid, submissions_count FROM forms WHERE id = :id AND deletedat IS NULL", { id: { value: arguments.id, cfsqltype: "cf_sql_integer" } });
		if (!local.q.recordCount || !canManageSite(local.q.siteid)) return {};
		return QueryGetRow(local.q, 1);
	}

	private void function writeAudit(numeric formId = 0, numeric submissionId = 0, required string action, struct details = {}) {
		try {
			fbQuery("
				INSERT INTO form_audit_logs (form_id, submission_id, action, performed_by, ip_address, details_json)
				VALUES (:fid, :sid, :action, :by, :ip, :details)
			", {
				fid: { value: arguments.formId, cfsqltype: "cf_sql_integer", null: arguments.formId <= 0 },
				sid: { value: arguments.submissionId, cfsqltype: "cf_sql_integer", null: arguments.submissionId <= 0 },
				action: qp(Left(arguments.action, 100)),
				by: qp(currentActor()),
				ip: qp(Left(cgi.remote_addr, 45), "cf_sql_nvarchar", true),
				details: { value: SerializeJSON(arguments.details), cfsqltype: "cf_sql_longnvarchar" }
			});
		} catch (any e) {
			writeLog(type="warning", file="form-builder", text="Audit log write failed: #e.message#");
		}
	}

	// ---- Departments --------------------------------------------------------

	private array function defaultDepartments() {
		return [
			{ code: "ADMIN", name: "General Administration", alert_email: "contact@chelancounty.gov", color_hex: "##0073aa", badge_class: "badge-primary", aliases: "Administration,General Administration" },
			{ code: "HRM", name: "HRM - Human Resource Management", alert_email: "hrm@chelancounty.gov", color_hex: "##8e44ad", badge_class: "badge-purple", aliases: "HR,Human Resources" },
			{ code: "PIO", name: "PIO - Public Information Office", alert_email: "pio@chelancounty.gov", color_hex: "##0284c7", badge_class: "badge-info", aliases: "Public Information Office,Communications" },
			{ code: "COMMDEV", name: "Community Development & Planning", alert_email: "permits@chelancounty.gov", color_hex: "##e67e22", badge_class: "badge-warning", aliases: "Community Development,Community" },
			{ code: "PW", name: "Public Works & Roads", alert_email: "public.works@chelancounty.gov", color_hex: "##d97706", badge_class: "badge-warning", aliases: "Public Works,Works" },
			{ code: "NR", name: "Natural Resources", alert_email: "weeds@chelancounty.gov", color_hex: "##15803d", badge_class: "badge-success", aliases: "Natural Resources,Natural" }
		];
	}

	/** Seeds the standard departments once per application lifecycle (idempotent) */
	private void function ensureFormDepartments() {
		try {
			// Ensure all active CMS workspaces exist as form departments
			local.workspaces = getMasterWorkspaces();
			for (local.ws in local.workspaces) {
				local.wCode = Trim(local.ws.id);
				if (local.wCode == "global" || !Len(local.wCode)) continue;
				local.wEmail = (StructKeyExists(local.ws, "contact") && Len(Trim(local.ws.contact.email ?: ""))) ? Trim(local.ws.contact.email) : (LCase(local.ws.id) & "@chelancounty.gov");
				local.wColor = Len(Trim(local.ws.color ?: "")) ? Trim(local.ws.color) : "##0073aa";
				local.wBadge = Len(Trim(local.ws.badgeClass ?: "")) ? Trim(local.ws.badgeClass) : "badge-primary";
				fbQuery("
					IF NOT EXISTS (SELECT 1 FROM form_departments WHERE code = :code OR code = :codeUpper)
						INSERT INTO form_departments (code, name, alert_email, color_hex, badge_class)
						VALUES (:code, :name, :email, :color, :badge)
				", {
					code: qp(local.wCode),
					codeUpper: qp(UCase(local.wCode)),
					name: qp(local.ws.name),
					email: qp(local.wEmail),
					color: qp(local.wColor),
					badge: qp(local.wBadge)
				});
			}
			application.fbDepartmentsSeeded = true;
		} catch (any e) {
			writeLog(type="error", file="form-builder", text="Department seed failed: #e.message#");
		}
	}

	private array function getDepartmentsForClient() {
		ensureFormDepartments();
		local.aliasMap = {};
		for (local.d in defaultDepartments()) local.aliasMap[local.d.code] = ListToArray(local.d.aliases);
		local.out = [];
		local.q = fbQuery("SELECT code, name, alert_email, color_hex, badge_class FROM form_departments WHERE deletedat IS NULL AND is_active = 1 ORDER BY CASE WHEN code = 'ADMIN' THEN 0 ELSE 1 END, name");
		for (local.r in local.q) {
			ArrayAppend(local.out, {
				"code": local.r.code,
				"name": local.r.name,
				"alertEmail": local.r.alert_email,
				"color": local.r.color_hex,
				"badgeClass": local.r.badge_class,
				"aliases": StructKeyExists(local.aliasMap, local.r.code) ? local.aliasMap[local.r.code] : []
			});
		}
		return local.out;
	}

	/** Resolves a builder department value (code, name or legacy alias) to a form_departments.id */
	private numeric function resolveDepartmentId(required string value, string siteid = "") {
		local.v = Trim(arguments.value);
		local.s = Trim(arguments.siteid);

		// If department value is empty, fallback to owning workspace siteid
		if (!Len(local.v) && Len(local.s)) local.v = local.s;
		if (!Len(local.v)) local.v = "ADMIN";

		for (local.d in defaultDepartments()) {
			if (ListFindNoCase(local.d.aliases, local.v)) { local.v = local.d.code; break; }
		}

		// 1. Try direct match on code or name
		local.q = fbQuery("SELECT TOP 1 id FROM form_departments WHERE deletedat IS NULL AND (code = :v OR code = :vu OR name = :v)", {
			v: qp(local.v),
			vu: qp(UCase(local.v))
		});
		if (local.q.recordCount) return local.q.id;

		// 2. Try match on owning siteid if provided (e.g. assessors, assessor)
		if (Len(local.s)) {
			local.q2 = fbQuery("SELECT TOP 1 id FROM form_departments WHERE deletedat IS NULL AND (code = :s OR code = :su OR name LIKE :sp)", {
				s: qp(local.s),
				su: qp(UCase(local.s)),
				sp: qp("%" & local.s & "%")
			});
			if (local.q2.recordCount) return local.q2.id;
		}

		// 3. Match against master workspaces catalog
		for (local.w in getMasterWorkspaces()) {
			if (local.w.id == local.s || local.w.name == local.v || local.w.code == local.s) {
				local.q3 = fbQuery("SELECT TOP 1 id FROM form_departments WHERE deletedat IS NULL AND (code = :c OR code = :u OR name = :n)", {
					c: qp(local.w.id),
					u: qp(UCase(local.w.id)),
					n: qp(local.w.name)
				});
				if (local.q3.recordCount) return local.q3.id;
			}
		}

		local.qFb = fbQuery("SELECT TOP 1 id FROM form_departments WHERE deletedat IS NULL AND code = 'ADMIN'");
		return local.qFb.recordCount ? local.qFb.id : 0;
	}

	private string function getDepartmentIcon(required string code) {
		switch (UCase(arguments.code)) {
			case "HRM": return "briefcase";
			case "PIO": return "megaphone";
			case "ADMIN": return "building";
			case "COMMDEV": return "map-pin";
			case "PW": return "alert-triangle";
			case "NR": return "bug";
			default: return "form";
		}
	}

	private array function getFieldTypeBadges(required array types) {
		local.labels = { address: "Address Block", signature: "Signature", file: "File Upload", radio: "Radios", checkbox: "Checkboxes", select: "Dropdown", rating: "Rating", date: "Date Picker", switch: "Switch", textarea: "Long Text", number: "Number", paragraph: "Notice Block" };
		local.out = [];
		for (local.t in arguments.types) {
			if (StructKeyExists(local.labels, local.t) && ArrayLen(local.out) < 4) ArrayAppend(local.out, local.labels[local.t]);
		}
		return local.out;
	}

	// ---- Form load / save ---------------------------------------------------

	/** Loads a form + active fields into the builder's JSON shape. Returns {} when not found. */
	private struct function loadFormStruct(numeric id = 0, string slug = "", string formKey = "") {
		local.p = {};
		if (arguments.id > 0) {
			local.where = "f.id = :v";
			local.p.v = { value: arguments.id, cfsqltype: "cf_sql_integer" };
		} else if (Len(arguments.slug)) {
			local.where = "f.slug = :v";
			local.p.v = qp(arguments.slug);
		} else if (Len(arguments.formKey)) {
			local.where = "f.form_key = :v";
			local.p.v = qp(arguments.formKey);
		} else {
			return {};
		}

		local.q = fbQuery("
			SELECT f.*, d.code AS dept_code, d.name AS dept_name,
			       DATEADD(minute, DATEDIFF(minute, SYSUTCDATETIME(), SYSDATETIME()), f.updatedat) AS updated_local
			FROM forms f
			LEFT JOIN form_departments d ON d.id = f.department_id
			WHERE f.deletedat IS NULL AND #local.where#
		", local.p);
		if (!local.q.recordCount) return {};
		local.r = QueryGetRow(local.q, 1);

		local.qf = fbQuery("
			SELECT * FROM form_fields
			WHERE form_id = :id AND deletedat IS NULL AND is_active = 1
			ORDER BY sort_order, id
		", { id: { value: local.r.id, cfsqltype: "cf_sql_integer" } });

		local.fields = [];
		for (local.fr in local.qf) {
			local.fld = {
				"id": local.fr.field_key,
				"type": local.fr.field_type,
				"label": local.fr.label,
				"placeholder": local.fr.placeholder,
				"subtext": local.fr.subtext,
				"required": local.fr.is_required ? true : false,
				"width": Len(local.fr.column_width) ? local.fr.column_width : "100"
			};
			if (Len(local.fr.paragraph_content)) local.fld["content"] = local.fr.paragraph_content;
			if (local.fr.field_type == "paragraph") local.fld["paragraphStyle"] = local.fr.paragraph_style;
			if (local.fr.field_type == "textarea") local.fld["rows"] = local.fr.textarea_rows;
			if (Len(local.fr.default_value)) local.fld["defaultValue"] = local.fr.default_value;
			if (Len(local.fr.options_json) && IsJSON(local.fr.options_json)) {
				local.opts = DeserializeJSON(local.fr.options_json);
				if (IsArray(local.opts)) local.fld["options"] = local.opts;
			}
			if (Len(local.fr.validation_rules_json) && IsJSON(local.fr.validation_rules_json)) {
				local.extra = DeserializeJSON(local.fr.validation_rules_json);
				if (IsStruct(local.extra)) {
					for (local.k in local.extra) {
						if (!StructKeyExists(local.fld, local.k)) local.fld[local.k] = local.extra[local.k];
					}
				}
			}
			ArrayAppend(local.fields, local.fld);
		}

		local.wsNames = getWorkspaceNameMap();
		local.owningWsName = StructKeyExists(local.wsNames, local.r.siteid) ? local.wsNames[local.r.siteid] : (Len(Trim(local.r.dept_name ?: "")) ? local.r.dept_name : local.r.siteid);

		return {
			"dbId": local.r.id,
			"id": "form_" & local.r.id,
			"formKey": local.r.form_key,
			"slug": local.r.slug,
			"title": local.r.title,
			"description": local.r.description,
			"status": LCase(local.r.status),
			"department": Len(Trim(local.r.dept_code ?: "")) ? local.r.dept_code : local.r.siteid,
			"departmentName": Len(Trim(local.r.dept_name ?: "")) ? local.r.dept_name : local.owningWsName,
			"siteid": local.r.siteid,
			"workspaceName": local.owningWsName,
			"themeColor": local.r.theme_color,
			"submitText": local.r.submit_text,
			"successMessage": local.r.success_message,
			"redirectUrl": local.r.redirect_url,
			"notificationEmail": local.r.notification_email,
			"notificationEmailCc": local.r.notification_email_cc,
			"emailNotificationsEnabled": local.r.email_notifications_enabled ? true : false,
			"antiSpamEnabled": local.r.anti_spam_enabled ? true : false,
			"honeypotFieldName": local.r.honeypot_field_name,
			"minDelaySeconds": local.r.min_delay_seconds,
			"cooldownSeconds": local.r.cooldown_seconds,
			"wcagCompliant": local.r.wcag_compliant ? true : false,
			"allowIframeEmbed": local.r.allow_iframe_embed ? true : false,
			"isStandalonePublic": local.r.is_standalone_public ? true : false,
			"submissionsCount": local.r.submissions_count,
			"viewsCount": local.r.views_count,
			"updatedAt": IsDate(local.r.updated_local) ? DateTimeFormat(local.r.updated_local, "mmm d, yyyy h:nn tt") : "",
			"fields": local.fields
		};
	}

	/**
	 * Upserts field rows by field_key so existing submission values keep their field_id.
	 * Fields removed in the builder are soft-deleted.
	 */
	private void function syncFormFields(required numeric formId, required array fields) {
		local.known = "id,type,label,placeholder,defaultValue,subtext,content,paragraphStyle,options,required,width,rows";
		local.existing = {};
		local.qEx = fbQuery("SELECT id, field_key FROM form_fields WHERE form_id = :fid", { fid: { value: arguments.formId, cfsqltype: "cf_sql_integer" } });
		for (local.e in local.qEx) local.existing[LCase(local.e.field_key)] = local.e.id;

		local.keptKeys = [];
		local.seen = {};
		local.order = 0;

		for (local.fld in arguments.fields) {
			if (!IsStruct(local.fld)) continue;
			local.order++;

			local.key = Left(REReplace(Trim(local.fld.id ?: ""), "[^A-Za-z0-9_\-]", "", "all"), 100);
			if (!Len(local.key) || StructKeyExists(local.seen, LCase(local.key))) {
				local.key = "f_" & LCase(Left(Replace(CreateUUID(), "-", "", "all"), 8));
			}
			local.seen[LCase(local.key)] = true;
			ArrayAppend(local.keptKeys, local.key);

			local.type = Left(REReplace(LCase(local.fld.type ?: "text"), "[^a-z0-9_\-]", "", "all"), 50);
			if (!Len(local.type)) local.type = "text";
			local.label = Left(Trim(local.fld.label ?: ""), 255);
			if (!Len(local.label)) local.label = "Untitled Field";
			local.width = Left(Trim(local.fld.width ?: "100"), 10);
			if (!ListFind("25,33,50,66,75,100", local.width)) local.width = "100";
			local.pstyle = Left(Trim(local.fld.paragraphStyle ?: "normal"), 50);
			if (!Len(local.pstyle)) local.pstyle = "normal";
			local.rows = Min(Max(Int(Val(local.fld.rows ?: 4)), 1), 30);

			local.options = (StructKeyExists(local.fld, "options") && IsArray(local.fld.options)) ? SerializeJSON(local.fld.options) : "";
			local.extras = {};
			for (local.k in local.fld) {
				if (!ListFindNoCase(local.known, local.k) && !IsNull(local.fld[local.k])) local.extras[local.k] = local.fld[local.k];
			}

			local.p = {
				form_id: { value: arguments.formId, cfsqltype: "cf_sql_integer" },
				field_key: qp(local.key),
				field_type: qp(local.type),
				label: qp(local.label),
				placeholder: qp(Left(local.fld.placeholder ?: "", 255), "cf_sql_nvarchar", true),
				default_value: qp(local.fld.defaultValue ?: "", "cf_sql_longnvarchar", true),
				subtext: qp(Left(local.fld.subtext ?: "", 500), "cf_sql_nvarchar", true),
				paragraph_content: qp(local.fld.content ?: "", "cf_sql_longnvarchar", true),
				paragraph_style: qp(local.pstyle),
				options_json: qp(local.options, "cf_sql_longnvarchar", true),
				is_required: qbit(local.fld.required ?: "", false),
				column_width: qp(local.width),
				textarea_rows: { value: local.rows, cfsqltype: "cf_sql_integer" },
				sort_order: { value: local.order, cfsqltype: "cf_sql_integer" },
				validation_rules_json: qp(StructIsEmpty(local.extras) ? "" : SerializeJSON(local.extras), "cf_sql_longnvarchar", true)
			};

			if (StructKeyExists(local.existing, LCase(local.key))) {
				local.p.id = { value: local.existing[LCase(local.key)], cfsqltype: "cf_sql_integer" };
				fbQuery("
					UPDATE form_fields SET
						field_key = :field_key, field_type = :field_type, label = :label, placeholder = :placeholder,
						default_value = :default_value, subtext = :subtext, paragraph_content = :paragraph_content,
						paragraph_style = :paragraph_style, options_json = :options_json, is_required = :is_required,
						column_width = :column_width, textarea_rows = :textarea_rows, sort_order = :sort_order,
						validation_rules_json = :validation_rules_json, is_active = 1, deletedat = NULL, updatedat = SYSUTCDATETIME()
					WHERE id = :id AND form_id = :form_id
				", local.p);
			} else {
				fbQuery("
					INSERT INTO form_fields
						(form_id, field_key, field_type, label, placeholder, default_value, subtext, paragraph_content, paragraph_style,
						 options_json, is_required, column_width, textarea_rows, sort_order, validation_rules_json)
					VALUES
						(:form_id, :field_key, :field_type, :label, :placeholder, :default_value, :subtext, :paragraph_content, :paragraph_style,
						 :options_json, :is_required, :column_width, :textarea_rows, :sort_order, :validation_rules_json)
				", local.p);
			}
		}

		// Soft-delete fields that were removed from the canvas
		local.delSql = "UPDATE form_fields SET is_active = 0, deletedat = SYSUTCDATETIME(), updatedat = SYSUTCDATETIME() WHERE form_id = :fid AND deletedat IS NULL";
		local.delParams = { fid: { value: arguments.formId, cfsqltype: "cf_sql_integer" } };
		if (ArrayLen(local.keptKeys)) {
			local.delSql &= " AND field_key NOT IN (:keys)";
			local.delParams.keys = { value: ArrayToList(local.keptKeys), cfsqltype: "cf_sql_nvarchar", list: true };
		}
		fbQuery(local.delSql, local.delParams);
	}

	private string function slugify(required string text) {
		local.s = LCase(Trim(arguments.text));
		local.s = REReplace(local.s, "[^a-z0-9]+", "-", "all");
		local.s = REReplace(local.s, "^-+|-+$", "", "all");
		if (!Len(local.s)) local.s = "form";
		return Left(local.s, 180);
	}

	private string function uniqueSlug(required string title) {
		local.base = slugify(arguments.title);
		local.candidate = local.base;
		local.n = 1;
		while (true) {
			local.q = fbQuery("SELECT 1 AS hit FROM forms WHERE slug = :s", { s: qp(local.candidate) });
			if (!local.q.recordCount) return local.candidate;
			local.n++;
			local.candidate = local.base & "-" & local.n;
		}
	}

	private string function generateFormKey() {
		return "frm_" & LCase(Left(Replace(CreateUUID(), "-", "", "all"), 16));
	}

	private string function generateReferenceId() {
		for (local.i = 1; local.i <= 5; local.i++) {
			local.ref = "SUB-" & UCase(Left(Hash(CreateUUID() & GetTickCount(), "SHA-256"), 10));
			local.q = fbQuery("SELECT 1 AS hit FROM form_submissions WHERE reference_id = :r", { r: qp(local.ref) });
			if (!local.q.recordCount) return local.ref;
		}
		return "SUB-" & UCase(Replace(CreateUUID(), "-", "", "all"));
	}

	// ---- Submission helpers -------------------------------------------------

	private string function formatSubmittedValue(required string type, any raw = "") {
		if (IsNull(arguments.raw)) return "";
		switch (arguments.type) {
			case "checkbox":
				if (IsArray(arguments.raw)) return ArrayToList(arguments.raw, "; ");
				return IsSimpleValue(arguments.raw) ? Trim(arguments.raw) : "";
			case "switch":
				return (IsSimpleValue(arguments.raw) && IsBoolean(arguments.raw) && arguments.raw) || (IsSimpleValue(arguments.raw) && ListFindNoCase("on,yes,true,1", Trim(arguments.raw))) ? "Yes" : "No";
			case "address":
				if (IsStruct(arguments.raw)) {
					local.line1 = Trim((arguments.raw.street ?: "") & " " & (arguments.raw.street2 ?: ""));
					local.line2 = Trim((arguments.raw.city ?: "") & ", " & (arguments.raw.state ?: "") & " " & (arguments.raw.zip ?: ""));
					if (local.line2 == ",") local.line2 = "";
					if (!Len(Trim(arguments.raw.street ?: "")) && !Len(Trim(arguments.raw.city ?: ""))) return "";
					return Trim(local.line1 & (Len(local.line1) && Len(local.line2) ? ", " : "") & local.line2);
				}
				return IsSimpleValue(arguments.raw) ? Trim(arguments.raw) : "";
			default:
				return IsSimpleValue(arguments.raw) ? Trim(arguments.raw) : SerializeJSON(arguments.raw);
		}
	}

	/** Creates the per-submission upload folder (blocked from direct web access) */
	private struct function ensureUploadDir(required string formKey, required string refId) {
		local.rootAbs = ExpandPath("/") & "files\_form-uploads\";
		if (!DirectoryExists(local.rootAbs)) CreateObject("java", "java.io.File").init(local.rootAbs).mkdirs();
		if (!FileExists(local.rootAbs & "web.config")) {
			FileWrite(local.rootAbs & "web.config", '<?xml version="1.0" encoding="UTF-8"?>' & Chr(10)
				& '<!-- Citizen form uploads are private: block all direct HTTP access. -->' & Chr(10)
				& '<configuration><system.webServer><security><requestFiltering><fileExtensions allowUnlisted="false" /></requestFiltering></security></system.webServer></configuration>' & Chr(10));
		}
		local.safeKey = REReplace(arguments.formKey, "[^A-Za-z0-9_\-]", "", "all");
		local.abs = local.rootAbs & local.safeKey & "\" & arguments.refId & "\";
		if (!DirectoryExists(local.abs)) CreateObject("java", "java.io.File").init(local.abs).mkdirs();
		return { absolute: local.abs, relative: "files/_form-uploads/" & local.safeKey & "/" & arguments.refId & "/" };
	}

	private void function sendSubmissionNotification(required struct frm, required string refId, required array values) {
		// Read emailSettings from frm.schema_json if present
		local.emailSettings = {
			"staffNotificationEnabled": arguments.frm.email_notifications_enabled ? true : false,
			"staffEmail": Len(Trim(arguments.frm.notification_email ?: "")) ? Trim(arguments.frm.notification_email) : Trim(arguments.frm.dept_alert_email ?: ""),
			"staffEmailCc": Trim(arguments.frm.notification_email_cc ?: ""),
			"staffSubject": "[New Submission] {{form_title}} ({{reference_id}})",
			"staffNotes": "",
			"userAutoresponderEnabled": true,
			"userSubject": "Confirmation: {{form_title}} Received ({{reference_id}})",
			"userFromName": "Chelan County Online Services",
			"userReplyTo": Len(Trim(arguments.frm.notification_email ?: "")) ? Trim(arguments.frm.notification_email) : "forms@chelancounty.gov",
			"userCustomMessage": "Thank you for contacting Chelan County. We have received your submission and will review it shortly. Please retain your reference number for your records.",
			"userIncludeSummary": true
		};

		if (Len(Trim(arguments.frm.schema_json ?: ""))) {
			try {
				local.parsedSchema = DeserializeJSON(arguments.frm.schema_json);
				if (IsStruct(local.parsedSchema) && StructKeyExists(local.parsedSchema, "emailSettings") && IsStruct(local.parsedSchema.emailSettings)) {
					StructAppend(local.emailSettings, local.parsedSchema.emailSettings, true);
				}
			} catch (any ignore) {}
		}

		if (!local.emailSettings.staffNotificationEnabled && !local.emailSettings.userAutoresponderEnabled) {
			return;
		}
		local.to = Len(Trim(local.emailSettings.staffEmail)) ? Trim(local.emailSettings.staffEmail) : Trim(arguments.frm.dept_alert_email ?: "");
		local.cc = Trim(local.emailSettings.staffEmailCc ?: "");
		if (!Len(local.to)) return;
		request.fbMail = {
			to: local.to,
			cc: local.cc,
			subject: "New submission: #arguments.frm.title# (#arguments.refId#)",
			title: arguments.frm.title,
			refId: arguments.refId,
			values: arguments.values,
			formId: Val(arguments.frm.id ?: 0),
			formKey: arguments.frm.form_key ?: "",
			slug: arguments.frm.slug ?: "",
			submittedAt: DateTimeFormat(Now(), "mmmm d, yyyy 'at' h:nn tt"),
			ipAddress: Left(cgi.remote_addr ?: "", 45),
			userAgent: Left(cgi.http_user_agent ?: "", 250),
			emailSettings: local.emailSettings,
			adminUrl: getPublicBaseUrl() & urlFor(controller="forms", action="index")
		};
		try {
			include "/app/lib/formNotificationMail.cfm";
		} catch (any e) {
			writeLog(type="warning", file="form-builder", text="Notification email failed for #arguments.refId#: #e.message#");
		}
	}

	private string function csvRow(required array cells) {
		local.out = [];
		for (local.c in arguments.cells) {
			local.v = IsNull(local.c) ? "" : (IsSimpleValue(local.c) ? ToString(local.c) : SerializeJSON(local.c));
			// Neutralize spreadsheet formula injection
			if (REFind("^[=+\-@]", local.v)) local.v = "'" & local.v;
			ArrayAppend(local.out, '"' & Replace(local.v, '"', '""', "all") & '"');
		}
		return ArrayToList(local.out, ",");
	}

	/** Validation-only submission path for template demos / unsaved drafts (nothing persisted) */
	private void function legacySubmit(required struct postData) {
		local.response = {
			"success": true,
			"message": "Thank you! Your form submission has been successfully received and recorded.",
			"timestamp": DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss"),
			"referenceId": "SUB-" & UCase(Left(Hash(CreateUUID() & Now()), 8)),
			"securityPassed": true,
			"persisted": false
		};

		// Anti-Spam Check: Honeypot field trap
		// Bots automatically populate invisible input fields
		for (local.hp in variables.FB_LEGACY_HONEYPOTS) {
			if (StructKeyExists(arguments.postData, local.hp) && IsSimpleValue(arguments.postData[local.hp]) && Len(Trim(arguments.postData[local.hp]))) {
				local.response.success = false;
				local.response.securityPassed = false;
				local.response.message = "Anti-spam security verification failed: Automated submission detected.";
				local.response.errorCode = "SPAM_HONEYPOT_TRIGGERED";
				renderJson(local.response, 400);
				return;
			}
		}

		// Anti-Spam Check: Submission speed trap / time-delay verification
		// Legitimate humans take at least 3 seconds to review and fill out forms
		if (StructKeyExists(arguments.postData, "_cf_form_load_time") && IsNumeric(arguments.postData._cf_form_load_time)) {
			local.elapsedSeconds = Int((Now().getTime() - Val(arguments.postData._cf_form_load_time)) / 1000);
			if (local.elapsedSeconds >= 0 && local.elapsedSeconds < 3) {
				local.response.success = false;
				local.response.securityPassed = false;
				local.response.message = "Submission rejected: Form was completed too quickly (" & local.elapsedSeconds & "s). Automated bot protection requires a minimum 3-second delay.";
				local.response.errorCode = "SUBMISSION_TOO_FAST";
				renderJson(local.response, 400);
				return;
			}
		}

		renderJson(local.response);
	}

}
