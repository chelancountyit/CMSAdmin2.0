component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="registerPlanholder");
	}

	/**
	 * RFP & Solicitations Directory & Management Studio
	 */
	function index() {
		variables.pageTitle = "RFP & Solicitations Management";

		// Active Role & Workspace Filter
		local.role = getCurrentActiveRole();
		local.selectedSiteId = structKeyExists(params, "ws") ? LCase(Trim(params.ws)) : (structKeyExists(params, "dept") ? LCase(Trim(params.dept)) : "all");
		local.selectedStatus = structKeyExists(params, "status") ? Trim(params.status) : "All";
		local.selectedType = structKeyExists(params, "type") ? Trim(params.type) : "All";
		local.searchQuery = structKeyExists(params, "q") ? Trim(params.q) : "";

		// Fetch Department Workspaces
		variables.departments = getDepartmentsList();
		variables.selectedSiteId = local.selectedSiteId;
		variables.selectedStatus = local.selectedStatus;
		variables.selectedType = local.selectedType;
		variables.searchQuery = local.searchQuery;

		// Calculate Overall Metrics
		variables.metrics = getRfpMetrics(local.selectedSiteId);

		// Build Query Filter Clauses
		local.sqlWhere = " WHERE s.deleted_at IS NULL ";
		local.queryParams = {};

		if (local.selectedSiteId != "all" && Len(local.selectedSiteId)) {
			local.sqlWhere &= " AND (LOWER(s.site_id) = :siteId) ";
			local.queryParams.siteId = { value: local.selectedSiteId, cfsqltype: "cf_sql_varchar" };
		}

		if (local.selectedStatus != "All" && Len(local.selectedStatus)) {
			local.sqlWhere &= " AND s.status = :status ";
			local.queryParams.status = { value: local.selectedStatus, cfsqltype: "cf_sql_varchar" };
		}

		if (local.selectedType != "All" && Len(local.selectedType)) {
			local.sqlWhere &= " AND s.solicitation_type = :type ";
			local.queryParams.type = { value: local.selectedType, cfsqltype: "cf_sql_varchar" };
		}

		if (Len(local.searchQuery)) {
			local.sqlWhere &= " AND (s.title LIKE :q OR s.solicitation_number LIKE :q OR s.summary LIKE :q OR s.contact_name LIKE :q) ";
			local.queryParams.q = { value: "%" & local.searchQuery & "%", cfsqltype: "cf_sql_varchar" };
		}

		try {
			variables.qSolicitations = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					s.id, s.site_id, s.solicitation_number, s.title, s.slug, s.solicitation_type, s.status,
					s.summary, s.estimated_budget_range, s.contact_name, s.contact_email, s.contact_phone,
					s.publish_at, s.pre_bid_datetime, s.is_pre_bid_mandatory, s.questions_due_at,
					s.submission_deadline, s.bid_opening_datetime, s.bocc_award_target_date,
					s.primary_packet_url, s.submission_method,
					s.awarded_vendor, s.awarded_amount, s.bocc_resolution_number, s.award_date,
					s.created_at, s.created_by, s.updated_at, s.updated_by,
					COALESCE(w.name, s.site_id) AS department_name,
					COALESCE(adCounts.total_addenda, 0) AS addenda_count,
					COALESCE(phCounts.total_planholders, 0) AS planholders_count,
					COALESCE(bidCounts.total_bids, 0) AS bids_count
				FROM dbo.rfp_solicitations s
				LEFT JOIN dbo.cms_workspaces w ON LOWER(s.site_id) = LOWER(w.code)
				LEFT JOIN (
					SELECT solicitation_id, COUNT(1) AS total_addenda 
					FROM dbo.rfp_addenda 
					GROUP BY solicitation_id
				) adCounts ON adCounts.solicitation_id = s.id
				LEFT JOIN (
					SELECT solicitation_id, COUNT(1) AS total_planholders 
					FROM dbo.rfp_planholders 
					GROUP BY solicitation_id
				) phCounts ON phCounts.solicitation_id = s.id
				LEFT JOIN (
					SELECT solicitation_id, COUNT(1) AS total_bids 
					FROM dbo.rfp_bids 
					GROUP BY solicitation_id
				) bidCounts ON bidCounts.solicitation_id = s.id
				#local.sqlWhere#
				ORDER BY 
					CASE WHEN s.status = 'Open' THEN 1 
					     WHEN s.status = 'Scheduled' THEN 2
					     WHEN s.status = 'Under Review' THEN 3
					     WHEN s.status = 'Award Pending' THEN 4
					     WHEN s.status = 'Awarded' THEN 5
					     ELSE 6 END,
					s.submission_deadline DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			variables.qSolicitations = QueryNew("id,site_id,solicitation_number,title,slug,solicitation_type,status,submission_deadline,department_name,addenda_count,planholders_count,bids_count");
			variables.errorMessage = "Failed to load solicitations: " & e.message;
		}

		renderView(template="index");
	}

	/**
	 * Create New Solicitation
	 */
	function new() {
		variables.pageTitle = "Create New Solicitation";
		variables.departments = getDepartmentsList();

		local.activeWs = structKeyExists(session, "activeWorkspace") && session.activeWorkspace != "global" ? session.activeWorkspace : "public-works";

		variables.solicitation = {
			id: 0,
			siteId: local.activeWs,
			solicitationNumber: generateNextNumber(local.activeWs, "RFP"),
			title: "",
			slug: "",
			solicitationType: "RFP",
			status: "Draft",
			summary: "",
			descriptionHtml: "",
			estimatedBudgetRange: "",
			contactName: getActorName(),
			contactEmail: structKeyExists(session, "user") && structKeyExists(session.user, "email") ? session.user.email : "",
			contactPhone: "(509) 667-6415",
			publishAtStr: DateFormat(Now(), "yyyy-mm-dd") & "T" & TimeFormat(Now(), "HH:mm"),
			preBidDatetimeStr: "",
			preBidLocation: "",
			isPreBidMandatory: 0,
			questionsDueAtStr: "",
			addendaCutoffAtStr: "",
			submissionDeadlineStr: DateFormat(DateAdd("d", 21, Now()), "yyyy-mm-dd") & "T14:00",
			bidOpeningDatetimeStr: "",
			bidOpeningLocation: "",
			boccAwardTargetDateStr: "",
			primaryPacketUrl: "",
			submissionMethod: "Physical",
			submissionInstructions: "Sealed bids must be delivered to the department office prior to the submission deadline.",
			awardedVendor: "",
			awardedAmount: "",
			boccResolutionNumber: "",
			awardDateStr: "",
			tabulationFileUrl: ""
		};

		variables.qAddenda = QueryNew("id,solicitation_id,addendum_number,title,description_html,file_url,published_at,created_by");
		variables.qPlanholders = QueryNew("id,solicitation_id,company_name,contact_name,email,phone,contractor_license_number,is_prime_contractor,is_dbe_certified,notified_addenda_count,registered_at");
		variables.qBids = QueryNew("id,solicitation_id,vendor_name,base_bid_amount,alternate_amount,total_bid_amount,is_responsive,is_apparent_low,is_awarded,notes,submitted_at");

		renderView(template="edit");
	}

	/**
	 * Edit Existing Solicitation Studio
	 */
	function edit() {
		variables.departments = getDepartmentsList();

		if (!structKeyExists(params, "id") || !IsNumeric(params.id)) {
			flashInsert(error="Invalid solicitation ID provided.");
			redirectTo(controller="rfps", action="index");
			return;
		}

		local.id = Val(params.id);

		try {
			local.qRfp = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 * FROM dbo.rfp_solicitations 
				WHERE id = :id AND deleted_at IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.qRfp.recordCount == 0) {
				flashInsert(error="Solicitation not found or has been removed.");
				redirectTo(controller="rfps", action="index");
				return;
			}

			variables.pageTitle = "Edit " & local.qRfp.solicitation_type & ": " & local.qRfp.solicitation_number;

			// Date helper formatting
			local.fmtDt = function(any dt) {
				if (IsDate(arguments.dt)) {
					return DateFormat(arguments.dt, "yyyy-mm-dd") & "T" & TimeFormat(arguments.dt, "HH:mm");
				}
				return "";
			};
			local.fmtDateOnly = function(any d) {
				if (IsDate(arguments.d)) {
					return DateFormat(arguments.d, "yyyy-mm-dd");
				}
				return "";
			};

			variables.solicitation = {
				id: local.qRfp.id,
				siteId: local.qRfp.site_id,
				solicitationNumber: local.qRfp.solicitation_number,
				title: local.qRfp.title,
				slug: local.qRfp.slug,
				solicitationType: local.qRfp.solicitation_type,
				status: local.qRfp.status,
				summary: local.qRfp.summary ?: "",
				descriptionHtml: local.qRfp.description_html ?: "",
				estimatedBudgetRange: local.qRfp.estimated_budget_range ?: "",
				contactName: local.qRfp.contact_name ?: "",
				contactEmail: local.qRfp.contact_email ?: "",
				contactPhone: local.qRfp.contact_phone ?: "",
				publishAtStr: local.fmtDt(local.qRfp.publish_at),
				preBidDatetimeStr: local.fmtDt(local.qRfp.pre_bid_datetime),
				preBidLocation: local.qRfp.pre_bid_location ?: "",
				isPreBidMandatory: local.qRfp.is_pre_bid_mandatory ? 1 : 0,
				questionsDueAtStr: local.fmtDt(local.qRfp.questions_due_at),
				addendaCutoffAtStr: local.fmtDt(local.qRfp.addenda_cutoff_at),
				submissionDeadlineStr: local.fmtDt(local.qRfp.submission_deadline),
				bidOpeningDatetimeStr: local.fmtDt(local.qRfp.bid_opening_datetime),
				bidOpeningLocation: local.qRfp.bid_opening_location ?: "",
				boccAwardTargetDateStr: local.fmtDateOnly(local.qRfp.bocc_award_target_date),
				primaryPacketUrl: local.qRfp.primary_packet_url ?: "",
				submissionMethod: local.qRfp.submission_method ?: "Physical",
				submissionInstructions: local.qRfp.submission_instructions ?: "",
				awardedVendor: local.qRfp.awarded_vendor ?: "",
				awardedAmount: IsNumeric(local.qRfp.awarded_amount) ? local.qRfp.awarded_amount : "",
				boccResolutionNumber: local.qRfp.bocc_resolution_number ?: "",
				awardDateStr: local.fmtDateOnly(local.qRfp.award_date),
				tabulationFileUrl: local.qRfp.tabulation_file_url ?: ""
			};

			// Query Addenda
			variables.qAddenda = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT * FROM dbo.rfp_addenda 
				WHERE solicitation_id = :id 
				ORDER BY addendum_number ASC
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			// Query Planholders
			variables.qPlanholders = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT * FROM dbo.rfp_planholders 
				WHERE solicitation_id = :id 
				ORDER BY registered_at DESC
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			// Query Bids
			variables.qBids = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT * FROM dbo.rfp_bids 
				WHERE solicitation_id = :id 
				ORDER BY total_bid_amount ASC, id ASC
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

		} catch (any e) {
			flashInsert(error="Error loading solicitation: " & e.message);
			redirectTo(controller="rfps", action="index");
			return;
		}

		renderView(template="edit");
	}

	/**
	 * Save / Update Solicitation
	 */
	function save() {
		local.isAjax = isAjax();
		local.id = structKeyExists(params, "id") ? Val(params.id) : 0;
		local.siteId = structKeyExists(params, "site_id") && Len(Trim(params.site_id)) ? Trim(params.site_id) : "public-works";
		local.solicitationNumber = structKeyExists(params, "solicitation_number") ? Trim(params.solicitation_number) : "";
		local.title = structKeyExists(params, "title") ? Trim(params.title) : "";
		local.slug = structKeyExists(params, "slug") && Len(Trim(params.slug)) ? slugify(params.slug) : slugify(local.title);
		local.solicitationType = structKeyExists(params, "solicitation_type") ? Trim(params.solicitation_type) : "RFP";
		local.status = structKeyExists(params, "status") ? Trim(params.status) : "Draft";
		local.summary = structKeyExists(params, "summary") ? Trim(params.summary) : "";
		local.descriptionHtml = structKeyExists(params, "description_html") ? Trim(params.description_html) : "";
		local.estimatedBudgetRange = structKeyExists(params, "estimated_budget_range") ? Trim(params.estimated_budget_range) : "";
		local.contactName = structKeyExists(params, "contact_name") ? Trim(params.contact_name) : "";
		local.contactEmail = structKeyExists(params, "contact_email") ? Trim(params.contact_email) : "";
		local.contactPhone = structKeyExists(params, "contact_phone") ? Trim(params.contact_phone) : "";
		local.preBidLocation = structKeyExists(params, "pre_bid_location") ? Trim(params.pre_bid_location) : "";
		local.isPreBidMandatory = structKeyExists(params, "is_pre_bid_mandatory") && (params.is_pre_bid_mandatory == 1 || params.is_pre_bid_mandatory == "true" || params.is_pre_bid_mandatory == "on") ? 1 : 0;
		local.bidOpeningLocation = structKeyExists(params, "bid_opening_location") ? Trim(params.bid_opening_location) : "";
		local.primaryPacketUrl = structKeyExists(params, "primary_packet_url") ? Trim(params.primary_packet_url) : "";
		local.submissionMethod = structKeyExists(params, "submission_method") ? Trim(params.submission_method) : "Physical";
		local.submissionInstructions = structKeyExists(params, "submission_instructions") ? Trim(params.submission_instructions) : "";
		local.awardedVendor = structKeyExists(params, "awarded_vendor") ? Trim(params.awarded_vendor) : "";
		local.awardedAmount = structKeyExists(params, "awarded_amount") && IsNumeric(Trim(params.awarded_amount)) ? Val(Trim(params.awarded_amount)) : JavaCast("null", "");
		local.boccResolutionNumber = structKeyExists(params, "bocc_resolution_number") ? Trim(params.bocc_resolution_number) : "";
		local.tabulationFileUrl = structKeyExists(params, "tabulation_file_url") ? Trim(params.tabulation_file_url) : "";

		// Parse dates
		local.parseDt = function(any val) {
			if (structKeyExists(arguments, "val") && Len(Trim(arguments.val))) {
				local.cleaned = Replace(arguments.val, "T", " ");
				if (IsDate(local.cleaned)) return ParseDateTime(local.cleaned);
			}
			return JavaCast("null", "");
		};

		local.publishAt = local.parseDt(params.publish_at ?: "");
		local.preBidDatetime = local.parseDt(params.pre_bid_datetime ?: "");
		local.questionsDueAt = local.parseDt(params.questions_due_at ?: "");
		local.addendaCutoffAt = local.parseDt(params.addenda_cutoff_at ?: "");
		local.submissionDeadline = local.parseDt(params.submission_deadline ?: "");
		local.bidOpeningDatetime = local.parseDt(params.bid_opening_datetime ?: "");
		local.boccAwardTargetDate = local.parseDt(params.bocc_award_target_date ?: "");
		local.awardDate = local.parseDt(params.award_date ?: "");

		// Fallback for deadline if missing
		if (IsNull(local.submissionDeadline)) {
			local.submissionDeadline = DateAdd("d", 21, Now());
		}

		// Validation
		if (!Len(local.title)) {
			if (local.isAjax) {
				fxRenderJson({ success: false, message: "Solicitation title is required." }, 400);
				return;
			}
			flashInsert(error="Solicitation title is required.");
			redirectTo(controller="rfps", action="new");
			return;
		}

		if (!Len(local.solicitationNumber)) {
			local.solicitationNumber = generateNextNumber(local.siteId, local.solicitationType);
		}

		local.actor = getActorName();

		try {
			if (local.id > 0) {
				// Update
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE dbo.rfp_solicitations
					SET site_id = :siteId,
					    solicitation_number = :solNumber,
					    title = :title,
					    slug = :slug,
					    solicitation_type = :solType,
					    status = :status,
					    summary = :summary,
					    description_html = :descriptionHtml,
					    estimated_budget_range = :budgetRange,
					    contact_name = :contactName,
					    contact_email = :contactEmail,
					    contact_phone = :contactPhone,
					    publish_at = :publishAt,
					    pre_bid_datetime = :preBidDatetime,
					    pre_bid_location = :preBidLocation,
					    is_pre_bid_mandatory = :isPreBidMandatory,
					    questions_due_at = :questionsDueAt,
					    addenda_cutoff_at = :addendaCutoffAt,
					    submission_deadline = :submissionDeadline,
					    bid_opening_datetime = :bidOpeningDatetime,
					    bid_opening_location = :bidOpeningLocation,
					    bocc_award_target_date = :boccAwardTargetDate,
					    primary_packet_url = :primaryPacketUrl,
					    submission_method = :submissionMethod,
					    submission_instructions = :submissionInstructions,
					    awarded_vendor = :awardedVendor,
					    awarded_amount = :awardedAmount,
					    bocc_resolution_number = :boccResolutionNumber,
					    award_date = :awardDate,
					    tabulation_file_url = :tabulationFileUrl,
					    updated_at = SYSUTCDATETIME(),
					    updated_by = :updatedBy
					WHERE id = :id AND deleted_at IS NULL
				", {
					siteId: { value: local.siteId, cfsqltype: "cf_sql_varchar" },
					solNumber: { value: local.solicitationNumber, cfsqltype: "cf_sql_varchar" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					solType: { value: local.solicitationType, cfsqltype: "cf_sql_varchar" },
					status: { value: local.status, cfsqltype: "cf_sql_varchar" },
					summary: { value: local.summary, cfsqltype: "cf_sql_varchar", null: !Len(local.summary) },
					descriptionHtml: { value: local.descriptionHtml, cfsqltype: "cf_sql_longvarchar", null: !Len(local.descriptionHtml) },
					budgetRange: { value: local.estimatedBudgetRange, cfsqltype: "cf_sql_varchar", null: !Len(local.estimatedBudgetRange) },
					contactName: { value: local.contactName, cfsqltype: "cf_sql_varchar", null: !Len(local.contactName) },
					contactEmail: { value: local.contactEmail, cfsqltype: "cf_sql_varchar", null: !Len(local.contactEmail) },
					contactPhone: { value: local.contactPhone, cfsqltype: "cf_sql_varchar", null: !Len(local.contactPhone) },
					publishAt: { value: local.publishAt, cfsqltype: "cf_sql_timestamp", null: IsNull(local.publishAt) },
					preBidDatetime: { value: local.preBidDatetime, cfsqltype: "cf_sql_timestamp", null: IsNull(local.preBidDatetime) },
					preBidLocation: { value: local.preBidLocation, cfsqltype: "cf_sql_varchar", null: !Len(local.preBidLocation) },
					isPreBidMandatory: { value: local.isPreBidMandatory, cfsqltype: "cf_sql_bit" },
					questionsDueAt: { value: local.questionsDueAt, cfsqltype: "cf_sql_timestamp", null: IsNull(local.questionsDueAt) },
					addendaCutoffAt: { value: local.addendaCutoffAt, cfsqltype: "cf_sql_timestamp", null: IsNull(local.addendaCutoffAt) },
					submissionDeadline: { value: local.submissionDeadline, cfsqltype: "cf_sql_timestamp" },
					bidOpeningDatetime: { value: local.bidOpeningDatetime, cfsqltype: "cf_sql_timestamp", null: IsNull(local.bidOpeningDatetime) },
					bidOpeningLocation: { value: local.bidOpeningLocation, cfsqltype: "cf_sql_varchar", null: !Len(local.bidOpeningLocation) },
					boccAwardTargetDate: { value: local.boccAwardTargetDate, cfsqltype: "cf_sql_date", null: IsNull(local.boccAwardTargetDate) },
					primaryPacketUrl: { value: local.primaryPacketUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.primaryPacketUrl) },
					submissionMethod: { value: local.submissionMethod, cfsqltype: "cf_sql_varchar" },
					submissionInstructions: { value: local.submissionInstructions, cfsqltype: "cf_sql_longvarchar", null: !Len(local.submissionInstructions) },
					awardedVendor: { value: local.awardedVendor, cfsqltype: "cf_sql_varchar", null: !Len(local.awardedVendor) },
					awardedAmount: { value: local.awardedAmount, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.awardedAmount) },
					boccResolutionNumber: { value: local.boccResolutionNumber, cfsqltype: "cf_sql_varchar", null: !Len(local.boccResolutionNumber) },
					awardDate: { value: local.awardDate, cfsqltype: "cf_sql_date", null: IsNull(local.awardDate) },
					tabulationFileUrl: { value: local.tabulationFileUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.tabulationFileUrl) },
					updatedBy: { value: local.actor, cfsqltype: "cf_sql_varchar" },
					id: { value: local.id, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });

				local.savedId = local.id;
			} else {
				// Insert using trigger-safe table variable
				local.qInsert = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedTable TABLE (newId INT);

					INSERT INTO dbo.rfp_solicitations (
						site_id, solicitation_number, title, slug, solicitation_type, status,
						summary, description_html, estimated_budget_range,
						contact_name, contact_email, contact_phone,
						publish_at, pre_bid_datetime, pre_bid_location, is_pre_bid_mandatory,
						questions_due_at, addenda_cutoff_at, submission_deadline,
						bid_opening_datetime, bid_opening_location, bocc_award_target_date,
						primary_packet_url, submission_method, submission_instructions,
						awarded_vendor, awarded_amount, bocc_resolution_number, award_date, tabulation_file_url,
						created_by, updated_by
					)
					OUTPUT INSERTED.id INTO @InsertedTable(newId)
					VALUES (
						:siteId, :solNumber, :title, :slug, :solType, :status,
						:summary, :descriptionHtml, :budgetRange,
						:contactName, :contactEmail, :contactPhone,
						:publishAt, :preBidDatetime, :preBidLocation, :isPreBidMandatory,
						:questionsDueAt, :addendaCutoffAt, :submissionDeadline,
						:bidOpeningDatetime, :bidOpeningLocation, :boccAwardTargetDate,
						:primaryPacketUrl, :submissionMethod, :submissionInstructions,
						:awardedVendor, :awardedAmount, :boccResolutionNumber, :awardDate, :tabulationFileUrl,
						:actor, :actor
					);

					SELECT newId FROM @InsertedTable;
				", {
					siteId: { value: local.siteId, cfsqltype: "cf_sql_varchar" },
					solNumber: { value: local.solicitationNumber, cfsqltype: "cf_sql_varchar" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					slug: { value: local.slug, cfsqltype: "cf_sql_varchar" },
					solType: { value: local.solicitationType, cfsqltype: "cf_sql_varchar" },
					status: { value: local.status, cfsqltype: "cf_sql_varchar" },
					summary: { value: local.summary, cfsqltype: "cf_sql_varchar", null: !Len(local.summary) },
					descriptionHtml: { value: local.descriptionHtml, cfsqltype: "cf_sql_longvarchar", null: !Len(local.descriptionHtml) },
					budgetRange: { value: local.estimatedBudgetRange, cfsqltype: "cf_sql_varchar", null: !Len(local.estimatedBudgetRange) },
					contactName: { value: local.contactName, cfsqltype: "cf_sql_varchar", null: !Len(local.contactName) },
					contactEmail: { value: local.contactEmail, cfsqltype: "cf_sql_varchar", null: !Len(local.contactEmail) },
					contactPhone: { value: local.contactPhone, cfsqltype: "cf_sql_varchar", null: !Len(local.contactPhone) },
					publishAt: { value: local.publishAt, cfsqltype: "cf_sql_timestamp", null: IsNull(local.publishAt) },
					preBidDatetime: { value: local.preBidDatetime, cfsqltype: "cf_sql_timestamp", null: IsNull(local.preBidDatetime) },
					preBidLocation: { value: local.preBidLocation, cfsqltype: "cf_sql_varchar", null: !Len(local.preBidLocation) },
					isPreBidMandatory: { value: local.isPreBidMandatory, cfsqltype: "cf_sql_bit" },
					questionsDueAt: { value: local.questionsDueAt, cfsqltype: "cf_sql_timestamp", null: IsNull(local.questionsDueAt) },
					addendaCutoffAt: { value: local.addendaCutoffAt, cfsqltype: "cf_sql_timestamp", null: IsNull(local.addendaCutoffAt) },
					submissionDeadline: { value: local.submissionDeadline, cfsqltype: "cf_sql_timestamp" },
					bidOpeningDatetime: { value: local.bidOpeningDatetime, cfsqltype: "cf_sql_timestamp", null: IsNull(local.bidOpeningDatetime) },
					bidOpeningLocation: { value: local.bidOpeningLocation, cfsqltype: "cf_sql_varchar", null: !Len(local.bidOpeningLocation) },
					boccAwardTargetDate: { value: local.boccAwardTargetDate, cfsqltype: "cf_sql_date", null: IsNull(local.boccAwardTargetDate) },
					primaryPacketUrl: { value: local.primaryPacketUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.primaryPacketUrl) },
					submissionMethod: { value: local.submissionMethod, cfsqltype: "cf_sql_varchar" },
					submissionInstructions: { value: local.submissionInstructions, cfsqltype: "cf_sql_longvarchar", null: !Len(local.submissionInstructions) },
					awardedVendor: { value: local.awardedVendor, cfsqltype: "cf_sql_varchar", null: !Len(local.awardedVendor) },
					awardedAmount: { value: local.awardedAmount, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.awardedAmount) },
					boccResolutionNumber: { value: local.boccResolutionNumber, cfsqltype: "cf_sql_varchar", null: !Len(local.boccResolutionNumber) },
					awardDate: { value: local.awardDate, cfsqltype: "cf_sql_date", null: IsNull(local.awardDate) },
					tabulationFileUrl: { value: local.tabulationFileUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.tabulationFileUrl) },
					actor: { value: local.actor, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.savedId = Val(local.qInsert.newId);
			}

			if (local.isAjax) {
				fxRenderJson({
					success: true,
					message: "Solicitation " & local.solicitationNumber & " saved successfully.",
					id: local.savedId,
					redirectUrl: urlFor(controller="rfps", action="edit", params="id=" & local.savedId)
				});
				return;
			}

			flashInsert(success="Solicitation saved successfully.");
			redirectTo(controller="rfps", action="edit", params="id=" & local.savedId);
		} catch (any e) {
			if (local.isAjax) {
				fxRenderJson({ success: false, message: "Database Error: " & e.message }, 500);
				return;
			}
			flashInsert(error="Error saving solicitation: " & e.message);
			redirectTo(controller="rfps", action="index");
		}
	}

	/**
	 * Soft Delete Solicitation
	 */
	function delete() {
		local.id = structKeyExists(params, "id") ? Val(params.id) : 0;
		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "Invalid ID." }, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE dbo.rfp_solicitations
				SET deleted_at = SYSUTCDATETIME(),
				    updated_at = SYSUTCDATETIME(),
				    updated_by = :actor
				WHERE id = :id AND deleted_at IS NULL
			", {
				id: { value: local.id, cfsqltype: "cf_sql_integer" },
				actor: { value: getActorName(), cfsqltype: "cf_sql_varchar" }
			}, { datasource: "ChelanCountyWebsite" });

			if (isAjax()) {
				fxRenderJson({ success: true, message: "Solicitation archived successfully." });
				return;
			}
			flashInsert(success="Solicitation archived.");
			redirectTo(controller="rfps", action="index");
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error deleting solicitation: " & e.message }, 500);
		}
	}

	/**
	 * Quick Inline Status Toggle
	 */
	function updateStatus() {
		local.id = structKeyExists(params, "id") ? Val(params.id) : 0;
		local.newStatus = structKeyExists(params, "status") ? Trim(params.status) : "";

		local.valid = ["Draft", "Scheduled", "Open", "Under Review", "Award Pending", "Awarded", "Cancelled"];
		if (local.id <= 0 || !ArrayFindNoCase(local.valid, local.newStatus)) {
			fxRenderJson({ success: false, message: "Invalid ID or status value." }, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE dbo.rfp_solicitations
				SET status = :status,
				    updated_at = SYSUTCDATETIME(),
				    updated_by = :actor
				WHERE id = :id AND deleted_at IS NULL
			", {
				status: { value: local.newStatus, cfsqltype: "cf_sql_varchar" },
				actor: { value: getActorName(), cfsqltype: "cf_sql_varchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({ success: true, message: "Status changed to " & local.newStatus });
		} catch (any e) {
			fxRenderJson({ success: false, message: "Database Error: " & e.message }, 500);
		}
	}

	/**
	 * Save Addendum
	 */
	function saveAddendum() {
		local.solicitationId = structKeyExists(params, "solicitation_id") ? Val(params.solicitation_id) : 0;
		local.addendumId = structKeyExists(params, "addendum_id") ? Val(params.addendum_id) : 0;
		local.title = structKeyExists(params, "title") ? Trim(params.title) : "";
		local.descriptionHtml = structKeyExists(params, "description_html") ? Trim(params.description_html) : "";
		local.fileUrl = structKeyExists(params, "file_url") ? Trim(params.file_url) : "";
		local.addendumNum = structKeyExists(params, "addendum_number") ? Val(params.addendum_number) : 0;

		if (local.solicitationId <= 0 || !Len(local.title)) {
			fxRenderJson({ success: false, message: "Solicitation ID and Addendum title are required." }, 400);
			return;
		}

		try {
			if (local.addendumNum <= 0) {
				local.qMax = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					SELECT COALESCE(MAX(addendum_number), 0) + 1 AS nextNum 
					FROM dbo.rfp_addenda 
					WHERE solicitation_id = :id
				", { id: { value: local.solicitationId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
				local.addendumNum = Val(local.qMax.nextNum);
			}

			if (local.addendumId > 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE dbo.rfp_addenda
					SET addendum_number = :num,
					    title = :title,
					    description_html = :descHtml,
					    file_url = :fileUrl
					WHERE id = :id AND solicitation_id = :solId
				", {
					num: { value: local.addendumNum, cfsqltype: "cf_sql_integer" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					descHtml: { value: local.descriptionHtml, cfsqltype: "cf_sql_longvarchar", null: !Len(local.descriptionHtml) },
					fileUrl: { value: local.fileUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.fileUrl) },
					id: { value: local.addendumId, cfsqltype: "cf_sql_integer" },
					solId: { value: local.solicitationId, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });

				local.savedAddendumId = local.addendumId;
			} else {
				local.qIns = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedAddenda TABLE (newId INT);

					INSERT INTO dbo.rfp_addenda (
						solicitation_id, addendum_number, title, description_html, file_url, created_by
					)
					OUTPUT INSERTED.id INTO @InsertedAddenda(newId)
					VALUES (
						:solId, :num, :title, :descHtml, :fileUrl, :actor
					);

					SELECT newId FROM @InsertedAddenda;
				", {
					solId: { value: local.solicitationId, cfsqltype: "cf_sql_integer" },
					num: { value: local.addendumNum, cfsqltype: "cf_sql_integer" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					descHtml: { value: local.descriptionHtml, cfsqltype: "cf_sql_longvarchar", null: !Len(local.descriptionHtml) },
					fileUrl: { value: local.fileUrl, cfsqltype: "cf_sql_varchar", null: !Len(local.fileUrl) },
					actor: { value: getActorName(), cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.savedAddendumId = Val(local.qIns.newId);
			}

			fxRenderJson({
				success: true,
				message: "Addendum ##" & local.addendumNum & " saved successfully.",
				addendumId: local.savedAddendumId,
				addendumNumber: local.addendumNum
			});
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error saving addendum: " & e.message }, 500);
		}
	}

	/**
	 * Delete Addendum
	 */
	function deleteAddendum() {
		local.id = structKeyExists(params, "id") ? Val(params.id) : 0;
		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "Invalid Addendum ID." }, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				DELETE FROM dbo.rfp_addenda WHERE id = :id
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({ success: true, message: "Addendum removed." });
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error deleting addendum: " & e.message }, 500);
		}
	}

	/**
	 * Planholders Master Registry
	 */
	function planholders() {
		variables.pageTitle = "Planholders Registry";
		variables.selectedSolId = structKeyExists(params, "solicitation_id") ? Val(params.solicitation_id) : 0;
		variables.searchQuery = structKeyExists(params, "q") ? Trim(params.q) : "";

		local.sqlWhere = " WHERE 1=1 ";
		local.queryParams = {};

		if (variables.selectedSolId > 0) {
			local.sqlWhere &= " AND p.solicitation_id = :solId ";
			local.queryParams.solId = { value: variables.selectedSolId, cfsqltype: "cf_sql_integer" };
		}

		if (Len(variables.searchQuery)) {
			local.sqlWhere &= " AND (p.company_name LIKE :q OR p.contact_name LIKE :q OR p.email LIKE :q OR p.contractor_license_number LIKE :q) ";
			local.queryParams.q = { value: "%" & variables.searchQuery & "%", cfsqltype: "cf_sql_varchar" };
		}

		try {
			variables.qPlanholders = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					p.*,
					s.solicitation_number, s.title AS solicitation_title, s.solicitation_type, s.site_id,
					COALESCE(w.name, s.site_id) AS department_name
				FROM dbo.rfp_planholders p
				INNER JOIN dbo.rfp_solicitations s ON p.solicitation_id = s.id
				LEFT JOIN dbo.cms_workspaces w ON LOWER(s.site_id) = LOWER(w.code)
				#local.sqlWhere#
				ORDER BY p.registered_at DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });

			variables.qSolicitationsList = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT id, solicitation_number, title 
				FROM dbo.rfp_solicitations 
				WHERE deleted_at IS NULL 
				ORDER BY solicitation_number ASC
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			variables.qPlanholders = QueryNew("id,company_name,contact_name,email,phone");
			variables.qSolicitationsList = QueryNew("id,solicitation_number,title");
		}

		renderView(template="planholders");
	}

	/**
	 * Save / Add Planholder (Admin)
	 */
	function savePlanholder() {
		local.solicitationId = structKeyExists(params, "solicitation_id") ? Val(params.solicitation_id) : 0;
		local.companyName = structKeyExists(params, "company_name") ? Trim(params.company_name) : "";
		local.contactName = structKeyExists(params, "contact_name") ? Trim(params.contact_name) : "";
		local.email = structKeyExists(params, "email") ? Trim(params.email) : "";
		local.phone = structKeyExists(params, "phone") ? Trim(params.phone) : "";
		local.license = structKeyExists(params, "contractor_license_number") ? Trim(params.contractor_license_number) : "";
		local.isPrime = structKeyExists(params, "is_prime_contractor") && (params.is_prime_contractor == 1 || params.is_prime_contractor == "true" || params.is_prime_contractor == "on") ? 1 : 0;
		local.isDbe = structKeyExists(params, "is_dbe_certified") && (params.is_dbe_certified == 1 || params.is_dbe_certified == "true" || params.is_dbe_certified == "on") ? 1 : 0;

		if (local.solicitationId <= 0 || !Len(local.companyName) || !Len(local.email)) {
			fxRenderJson({ success: false, message: "Solicitation, company name, and email are required." }, 400);
			return;
		}

		try {
			local.qIns = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				DECLARE @InsertedPh TABLE (newId INT);

				INSERT INTO dbo.rfp_planholders (
					solicitation_id, company_name, contact_name, email, phone,
					contractor_license_number, is_prime_contractor, is_dbe_certified
				)
				OUTPUT INSERTED.id INTO @InsertedPh(newId)
				VALUES (
					:solId, :company, :contact, :email, :phone,
					:license, :isPrime, :isDbe
				);

				SELECT newId FROM @InsertedPh;
			", {
				solId: { value: local.solicitationId, cfsqltype: "cf_sql_integer" },
				company: { value: local.companyName, cfsqltype: "cf_sql_varchar" },
				contact: { value: local.contactName, cfsqltype: "cf_sql_varchar" },
				email: { value: local.email, cfsqltype: "cf_sql_varchar" },
				phone: { value: local.phone, cfsqltype: "cf_sql_varchar", null: !Len(local.phone) },
				license: { value: local.license, cfsqltype: "cf_sql_varchar", null: !Len(local.license) },
				isPrime: { value: local.isPrime, cfsqltype: "cf_sql_bit" },
				isDbe: { value: local.isDbe, cfsqltype: "cf_sql_bit" }
			}, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({ success: true, message: "Planholder added successfully.", id: Val(local.qIns.newId) });
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error adding planholder: " & e.message }, 500);
		}
	}

	/**
	 * Delete Planholder
	 */
	function deletePlanholder() {
		local.id = structKeyExists(params, "id") ? Val(params.id) : 0;
		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "Invalid Planholder ID." }, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				DELETE FROM dbo.rfp_planholders WHERE id = :id
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({ success: true, message: "Planholder removed." });
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error removing planholder: " & e.message }, 500);
		}
	}

	/**
	 * Export Planholders CSV
	 */
	function exportPlanholdersCsv() {
		local.solId = structKeyExists(params, "solicitation_id") ? Val(params.solicitation_id) : 0;

		local.sqlWhere = " WHERE 1=1 ";
		local.queryParams = {};
		local.filename = "chelancounty-planholders-registry.csv";

		if (local.solId > 0) {
			local.sqlWhere &= " AND p.solicitation_id = :solId ";
			local.queryParams.solId = { value: local.solId, cfsqltype: "cf_sql_integer" };
			local.filename = "planholders-solicitation-" & local.solId & ".csv";
		}

		try {
			local.q = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					s.solicitation_number, s.title AS solicitation_title,
					p.company_name, p.contact_name, p.email, p.phone,
					p.contractor_license_number,
					CASE WHEN p.is_prime_contractor = 1 THEN 'Prime' ELSE 'Sub' END AS role_type,
					CASE WHEN p.is_dbe_certified = 1 THEN 'Yes' ELSE 'No' END AS dbe_status,
					p.registered_at
				FROM dbo.rfp_planholders p
				INNER JOIN dbo.rfp_solicitations s ON p.solicitation_id = s.id
				#local.sqlWhere#
				ORDER BY s.solicitation_number ASC, p.registered_at DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });

			local.csv = "Solicitation Number,Solicitation Title,Company Name,Contact Name,Email,Phone,Contractor License,Prime/Sub,DBE Certified,Registered Date" & Chr(13) & Chr(10);

			for (local.row in local.q) {
				local.csv &= """" & Replace(local.row.solicitation_number, """", """""", "all") & ""","
				          & """" & Replace(local.row.solicitation_title, """", """""", "all") & ""","
				          & """" & Replace(local.row.company_name, """", """""", "all") & ""","
				          & """" & Replace(local.row.contact_name, """", """""", "all") & ""","
				          & """" & Replace(local.row.email, """", """""", "all") & ""","
				          & """" & Replace(local.row.phone ?: "", """", """""", "all") & ""","
				          & """" & Replace(local.row.contractor_license_number ?: "", """", """""", "all") & ""","
				          & """" & local.row.role_type & ""","
				          & """" & local.row.dbe_status & ""","
				          & """" & DateFormat(local.row.registered_at, "yyyy-mm-dd") & " " & TimeFormat(local.row.registered_at, "HH:mm") & """"
				          & Chr(13) & Chr(10);
			}

			cfheader(name="Content-Disposition", value="attachment; filename=""#local.filename#""");
			renderText(text=local.csv, contentType="text/csv; charset=utf-8");
		} catch (any e) {
			renderText(text="Error generating CSV: " & e.message, status=500);
		}
	}

	/**
	 * Save / Edit Bid Tabulation Record
	 */
	function saveBid() {
		local.solicitationId = structKeyExists(params, "solicitation_id") ? Val(params.solicitation_id) : 0;
		local.bidId = structKeyExists(params, "bid_id") ? Val(params.bid_id) : 0;
		local.vendorName = structKeyExists(params, "vendor_name") ? Trim(params.vendor_name) : "";
		local.baseBid = structKeyExists(params, "base_bid_amount") && IsNumeric(Trim(params.base_bid_amount)) ? Val(Trim(params.base_bid_amount)) : JavaCast("null", "");
		local.alternate = structKeyExists(params, "alternate_amount") && IsNumeric(Trim(params.alternate_amount)) ? Val(Trim(params.alternate_amount)) : JavaCast("null", "");
		local.totalBid = structKeyExists(params, "total_bid_amount") && IsNumeric(Trim(params.total_bid_amount)) ? Val(Trim(params.total_bid_amount)) : local.baseBid;
		local.isResponsive = structKeyExists(params, "is_responsive") && (params.is_responsive == 1 || params.is_responsive == "true" || params.is_responsive == "on") ? 1 : 0;
		local.isApparentLow = structKeyExists(params, "is_apparent_low") && (params.is_apparent_low == 1 || params.is_apparent_low == "true" || params.is_apparent_low == "on") ? 1 : 0;
		local.isAwarded = structKeyExists(params, "is_awarded") && (params.is_awarded == 1 || params.is_awarded == "true" || params.is_awarded == "on") ? 1 : 0;
		local.notes = structKeyExists(params, "notes") ? Trim(params.notes) : "";

		if (local.solicitationId <= 0 || !Len(local.vendorName)) {
			fxRenderJson({ success: false, message: "Solicitation ID and Vendor name are required." }, 400);
			return;
		}

		try {
			if (local.bidId > 0) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE dbo.rfp_bids
					SET vendor_name = :vendor,
					    base_bid_amount = :baseBid,
					    alternate_amount = :alternate,
					    total_bid_amount = :totalBid,
					    is_responsive = :isResponsive,
					    is_apparent_low = :isLow,
					    is_awarded = :isAwarded,
					    notes = :notes
					WHERE id = :id AND solicitation_id = :solId
				", {
					vendor: { value: local.vendorName, cfsqltype: "cf_sql_varchar" },
					baseBid: { value: local.baseBid, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.baseBid) },
					alternate: { value: local.alternate, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.alternate) },
					totalBid: { value: local.totalBid, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.totalBid) },
					isResponsive: { value: local.isResponsive, cfsqltype: "cf_sql_bit" },
					isLow: { value: local.isApparentLow, cfsqltype: "cf_sql_bit" },
					isAwarded: { value: local.isAwarded, cfsqltype: "cf_sql_bit" },
					notes: { value: local.notes, cfsqltype: "cf_sql_varchar", null: !Len(local.notes) },
					id: { value: local.bidId, cfsqltype: "cf_sql_integer" },
					solId: { value: local.solicitationId, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });

				local.savedBidId = local.bidId;
			} else {
				local.qIns = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					DECLARE @InsertedBids TABLE (newId INT);

					INSERT INTO dbo.rfp_bids (
						solicitation_id, vendor_name, base_bid_amount, alternate_amount, total_bid_amount,
						is_responsive, is_apparent_low, is_awarded, notes, submitted_at
					)
					OUTPUT INSERTED.id INTO @InsertedBids(newId)
					VALUES (
						:solId, :vendor, :baseBid, :alternate, :totalBid,
						:isResponsive, :isLow, :isAwarded, :notes, SYSUTCDATETIME()
					);

					SELECT newId FROM @InsertedBids;
				", {
					solId: { value: local.solicitationId, cfsqltype: "cf_sql_integer" },
					vendor: { value: local.vendorName, cfsqltype: "cf_sql_varchar" },
					baseBid: { value: local.baseBid, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.baseBid) },
					alternate: { value: local.alternate, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.alternate) },
					totalBid: { value: local.totalBid, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.totalBid) },
					isResponsive: { value: local.isResponsive, cfsqltype: "cf_sql_bit" },
					isLow: { value: local.isApparentLow, cfsqltype: "cf_sql_bit" },
					isAwarded: { value: local.isAwarded, cfsqltype: "cf_sql_bit" },
					notes: { value: local.notes, cfsqltype: "cf_sql_varchar", null: !Len(local.notes) }
				}, { datasource: "ChelanCountyWebsite" });

				local.savedBidId = Val(local.qIns.newId);
			}

			// If marked as awarded, optionally update the main solicitation awarded fields
			if (local.isAwarded == 1) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE dbo.rfp_solicitations
					SET awarded_vendor = :vendor,
					    awarded_amount = :amount,
					    status = 'Awarded',
					    updated_at = SYSUTCDATETIME()
					WHERE id = :solId
				", {
					vendor: { value: local.vendorName, cfsqltype: "cf_sql_varchar" },
					amount: { value: local.totalBid, cfsqltype: "cf_sql_decimal", scale: 2, null: IsNull(local.totalBid) },
					solId: { value: local.solicitationId, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });
			}

			fxRenderJson({ success: true, message: "Bid record saved successfully.", id: local.savedBidId });
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error saving bid record: " & e.message }, 500);
		}
	}

	/**
	 * Delete Bid Record
	 */
	function deleteBid() {
		local.id = structKeyExists(params, "id") ? Val(params.id) : 0;
		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "Invalid Bid ID." }, 400);
			return;
		}

		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				DELETE FROM dbo.rfp_bids WHERE id = :id
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({ success: true, message: "Bid tabulation entry deleted." });
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error deleting bid record: " & e.message }, 500);
		}
	}

	/**
	 * Public Solicitations & Bid Board (/bids)
	 */
	function publicList() {
		variables.pageTitle = "Public Bids & Solicitations | Chelan County, WA";

		local.selectedStatus = structKeyExists(params, "status") ? Trim(params.status) : "Open";
		local.selectedType = structKeyExists(params, "type") ? Trim(params.type) : "All";
		local.selectedDept = structKeyExists(params, "dept") ? Trim(params.dept) : "all";
		local.searchQuery = structKeyExists(params, "q") ? Trim(params.q) : "";

		variables.selectedStatus = local.selectedStatus;
		variables.selectedType = local.selectedType;
		variables.selectedDept = local.selectedDept;
		variables.searchQuery = local.searchQuery;
		variables.departments = getDepartmentsList();

		local.sqlWhere = " WHERE s.deleted_at IS NULL AND s.status <> 'Draft' ";
		local.queryParams = {};

		if (local.selectedStatus != "All" && Len(local.selectedStatus)) {
			local.sqlWhere &= " AND s.status = :status ";
			local.queryParams.status = { value: local.selectedStatus, cfsqltype: "cf_sql_varchar" };
		}

		if (local.selectedType != "All" && Len(local.selectedType)) {
			local.sqlWhere &= " AND s.solicitation_type = :type ";
			local.queryParams.type = { value: local.selectedType, cfsqltype: "cf_sql_varchar" };
		}

		if (local.selectedDept != "all" && Len(local.selectedDept)) {
			local.sqlWhere &= " AND LOWER(s.site_id) = :dept ";
			local.queryParams.dept = { value: LCase(local.selectedDept), cfsqltype: "cf_sql_varchar" };
		}

		if (Len(local.searchQuery)) {
			local.sqlWhere &= " AND (s.title LIKE :q OR s.solicitation_number LIKE :q OR s.summary LIKE :q) ";
			local.queryParams.q = { value: "%" & local.searchQuery & "%", cfsqltype: "cf_sql_varchar" };
		}

		try {
			variables.qBids = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					s.id, s.site_id, s.solicitation_number, s.title, s.slug, s.solicitation_type, s.status,
					s.summary, s.estimated_budget_range, s.contact_name, s.contact_email, s.contact_phone,
					s.publish_at, s.submission_deadline, s.bid_opening_datetime,
					s.awarded_vendor, s.awarded_amount, s.bocc_resolution_number, s.award_date,
					COALESCE(w.name, s.site_id) AS department_name,
					COALESCE(adCounts.total_addenda, 0) AS addenda_count
				FROM dbo.rfp_solicitations s
				LEFT JOIN dbo.cms_workspaces w ON LOWER(s.site_id) = LOWER(w.code)
				LEFT JOIN (
					SELECT solicitation_id, COUNT(1) AS total_addenda 
					FROM dbo.rfp_addenda 
					GROUP BY solicitation_id
				) adCounts ON adCounts.solicitation_id = s.id
				#local.sqlWhere#
				ORDER BY 
					CASE WHEN s.status = 'Open' THEN 1 
					     WHEN s.status = 'Under Review' THEN 2
					     WHEN s.status = 'Award Pending' THEN 3
					     WHEN s.status = 'Awarded' THEN 4
					     ELSE 5 END,
					s.submission_deadline DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			variables.qBids = QueryNew("id,site_id,solicitation_number,title,slug,solicitation_type,status,submission_deadline");
		}

		renderView(template="publicList", layout="false");
	}

	/**
	 * Public Solicitation View (/bids/view?slug=... or ?id=...)
	 */
	function publicView() {
		local.slug = structKeyExists(params, "slug") ? Trim(params.slug) : "";
		local.id = structKeyExists(params, "id") ? Val(params.id) : 0;

		if (!Len(local.slug) && local.id <= 0) {
			redirectTo(controller="rfps", action="publicList");
			return;
		}

		try {
			local.whereClause = local.id > 0 ? "s.id = :id" : "s.slug = :slug";
			local.paramStruct = local.id > 0 
				? { id: { value: local.id, cfsqltype: "cf_sql_integer" } }
				: { slug: { value: local.slug, cfsqltype: "cf_sql_varchar" } };

			variables.qRfp = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 
					s.*,
					COALESCE(w.name, s.site_id) AS department_name,
					w.contact_phone AS department_phone,
					w.contact_email AS department_email
				FROM dbo.rfp_solicitations s
				LEFT JOIN dbo.cms_workspaces w ON LOWER(s.site_id) = LOWER(w.code)
				WHERE #local.whereClause# AND s.deleted_at IS NULL AND s.status <> 'Draft'
			", local.paramStruct, { datasource: "ChelanCountyWebsite" });

			if (variables.qRfp.recordCount == 0) {
				renderText(text="Solicitation not found or is no longer publicly available.", status=404);
				return;
			}

			local.solId = Val(variables.qRfp.id);
			variables.pageTitle = variables.qRfp.solicitation_number & " — " & variables.qRfp.title;

			// Addenda
			variables.qAddenda = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT * FROM dbo.rfp_addenda 
				WHERE solicitation_id = :id 
				ORDER BY addendum_number ASC
			", { id: { value: local.solId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			// Planholders (Public List)
			variables.qPlanholders = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT company_name, contact_name, contractor_license_number, is_prime_contractor, is_dbe_certified, registered_at
				FROM dbo.rfp_planholders 
				WHERE solicitation_id = :id 
				ORDER BY registered_at DESC
			", { id: { value: local.solId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			// Bids (Public Tabulations if Under Review or Awarded)
			variables.qBids = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT vendor_name, base_bid_amount, alternate_amount, total_bid_amount, is_responsive, is_apparent_low, is_awarded, notes
				FROM dbo.rfp_bids 
				WHERE solicitation_id = :id 
				ORDER BY total_bid_amount ASC, id ASC
			", { id: { value: local.solId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

		} catch (any e) {
			renderText(text="Error loading solicitation: " & e.message, status=500);
			return;
		}

		renderView(template="publicView", layout="false");
	}

	/**
	 * Public Self-Registration as Planholder
	 */
	function registerPlanholder() {
		local.solId = structKeyExists(params, "solicitation_id") ? Val(params.solicitation_id) : 0;
		local.company = structKeyExists(params, "company_name") ? Trim(params.company_name) : "";
		local.contact = structKeyExists(params, "contact_name") ? Trim(params.contact_name) : "";
		local.email = structKeyExists(params, "email") ? Trim(params.email) : "";
		local.phone = structKeyExists(params, "phone") ? Trim(params.phone) : "";
		local.license = structKeyExists(params, "contractor_license_number") ? Trim(params.contractor_license_number) : "";
		local.isPrime = structKeyExists(params, "is_prime_contractor") && (params.is_prime_contractor == 1 || params.is_prime_contractor == "true" || params.is_prime_contractor == "on") ? 1 : 0;
		local.isDbe = structKeyExists(params, "is_dbe_certified") && (params.is_dbe_certified == 1 || params.is_dbe_certified == "true" || params.is_dbe_certified == "on") ? 1 : 0;

		if (local.solId <= 0 || !Len(local.company) || !Len(local.email) || !Len(local.contact)) {
			fxRenderJson({ success: false, message: "Please complete Company Name, Contact Name, and valid Email address." }, 400);
			return;
		}

		try {
			// Check if already registered
			local.qCheck = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 id FROM dbo.rfp_planholders 
				WHERE solicitation_id = :solId AND LOWER(email) = :email
			", {
				solId: { value: local.solId, cfsqltype: "cf_sql_integer" },
				email: { value: LCase(local.email), cfsqltype: "cf_sql_varchar" }
			}, { datasource: "ChelanCountyWebsite" });

			if (local.qCheck.recordCount > 0) {
				fxRenderJson({ 
					success: true, 
					message: "You are already registered on the planholders list for this project. Any future addenda will be dispatched to " & local.email & "." 
				});
				return;
			}

			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				INSERT INTO dbo.rfp_planholders (
					solicitation_id, company_name, contact_name, email, phone,
					contractor_license_number, is_prime_contractor, is_dbe_certified
				) VALUES (
					:solId, :company, :contact, :email, :phone,
					:license, :isPrime, :isDbe
				)
			", {
				solId: { value: local.solId, cfsqltype: "cf_sql_integer" },
				company: { value: local.company, cfsqltype: "cf_sql_varchar" },
				contact: { value: local.contact, cfsqltype: "cf_sql_varchar" },
				email: { value: local.email, cfsqltype: "cf_sql_varchar" },
				phone: { value: local.phone, cfsqltype: "cf_sql_varchar", null: !Len(local.phone) },
				license: { value: local.license, cfsqltype: "cf_sql_varchar", null: !Len(local.license) },
				isPrime: { value: local.isPrime, cfsqltype: "cf_sql_bit" },
				isDbe: { value: local.isDbe, cfsqltype: "cf_sql_bit" }
			}, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({ 
				success: true, 
				message: "Successfully registered on the Chelan County Planholders List. You will receive email notifications if addenda are issued." 
			});
		} catch (any e) {
			fxRenderJson({ success: false, message: "Registration error: " & e.message }, 500);
		}
	}

	// =========================================================================
	// Private Helper Functions
	// =========================================================================

	private struct function getRfpMetrics(string siteId = "all") {
		local.metrics = {
			total_count: 0,
			open_count: 0,
			under_review_count: 0,
			awarded_count: 0,
			closing_soon_count: 0,
			total_planholders: 0,
			total_awarded_value: 0
		};

		local.sqlWhere = " WHERE s.deleted_at IS NULL ";
		local.queryParams = {};

		if (arguments.siteId != "all" && Len(arguments.siteId)) {
			local.sqlWhere &= " AND LOWER(s.site_id) = :siteId ";
			local.queryParams.siteId = { value: LCase(arguments.siteId), cfsqltype: "cf_sql_varchar" };
		}

		try {
			local.q = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					COUNT(1) AS total_count,
					SUM(CASE WHEN s.status = 'Open' THEN 1 ELSE 0 END) AS open_count,
					SUM(CASE WHEN s.status = 'Under Review' THEN 1 ELSE 0 END) AS under_review_count,
					SUM(CASE WHEN s.status = 'Awarded' THEN 1 ELSE 0 END) AS awarded_count,
					SUM(CASE WHEN s.status = 'Open' AND s.submission_deadline <= DATEADD(day, 7, SYSUTCDATETIME()) AND s.submission_deadline > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS closing_soon_count,
					SUM(COALESCE(s.awarded_amount, 0)) AS total_awarded_value
				FROM dbo.rfp_solicitations s
				#local.sqlWhere#
			", local.queryParams, { datasource: "ChelanCountyWebsite" });

			if (local.q.recordCount) {
				local.metrics.total_count = Val(local.q.total_count);
				local.metrics.open_count = Val(local.q.open_count);
				local.metrics.under_review_count = Val(local.q.under_review_count);
				local.metrics.awarded_count = Val(local.q.awarded_count);
				local.metrics.closing_soon_count = Val(local.q.closing_soon_count);
				local.metrics.total_awarded_value = Val(local.q.total_awarded_value);
			}

			local.qPh = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT COUNT(1) AS ph_count 
				FROM dbo.rfp_planholders p
				INNER JOIN dbo.rfp_solicitations s ON p.solicitation_id = s.id
				#local.sqlWhere#
			", local.queryParams, { datasource: "ChelanCountyWebsite" });

			if (local.qPh.recordCount) {
				local.metrics.total_planholders = Val(local.qPh.ph_count);
			}
		} catch (any e) {
			// fallback
		}

		return local.metrics;
	}

	private array function getDepartmentsList() {
		try {
			local.source = [];
			if (structKeyExists(variables, "getMasterWorkspaces") || structKeyExists(getGlobalScope(), "getMasterWorkspaces")) {
				local.source = getMasterWorkspaces();
			} else {
				local.q = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					SELECT code AS id, code, name, type 
					FROM dbo.cms_workspaces 
					WHERE is_active = 1 
					ORDER BY sort_order ASC, name ASC
				", {}, { datasource: "ChelanCountyWebsite" });
				for (local.r in local.q) {
					ArrayAppend(local.source, { id: local.r.code, code: local.r.code, name: local.r.name, type: local.r.type });
				}
			}

			local.arr = [];
			for (local.item in local.source) {
				if (local.item.code != "global") {
					ArrayAppend(local.arr, local.item);
				}
			}
			return local.arr;
		} catch (any e) {
			return [
				{ id: "public-works", code: "public-works", name: "Public Works", type: "dept" },
				{ id: "natural-resources", code: "natural-resources", name: "Natural Resources", type: "dept" },
				{ id: "community-development", code: "community-development", name: "Community Development", type: "dept" },
				{ id: "it", code: "it", name: "Information Technology", type: "dept" },
				{ id: "admin", code: "admin", name: "County Administration", type: "dept" }
			];
		}
	}

	private string function generateNextNumber(string siteId, string solType) {
		local.prefix = "RFP";
		if (arguments.siteId == "public-works") local.prefix = "PW";
		else if (arguments.siteId == "it") local.prefix = "IT";
		else if (arguments.siteId == "natural-resources") local.prefix = "NR";
		else if (arguments.siteId == "facilities") local.prefix = "FAC";
		else if (arguments.siteId == "sheriff") local.prefix = "SO";
		else if (arguments.siteId == "admin") local.prefix = "ADM";

		local.year = Year(Now());
		local.searchPrefix = local.prefix & "-" & local.year & "-";

		try {
			local.q = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 solicitation_number 
				FROM dbo.rfp_solicitations 
				WHERE solicitation_number LIKE :p 
				ORDER BY id DESC
			", { p: { value: local.searchPrefix & "%", cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			if (local.q.recordCount && Len(local.q.solicitation_number)) {
				local.lastNum = Val(ListLast(local.q.solicitation_number, "-"));
				return local.searchPrefix & NumberFormat(local.lastNum + 1, "00");
			}
		} catch (any e) {
			// fallback
		}

		return local.searchPrefix & "01";
	}

	private string function slugify(required string text) {
		local.s = LCase(Trim(arguments.text));
		local.s = REReplace(local.s, "[^a-z0-9\s-]", "", "all");
		local.s = REReplace(local.s, "\s+", "-", "all");
		local.s = REReplace(local.s, "-+", "-", "all");
		return local.s;
	}

	private string function getActorName() {
		if (structKeyExists(session, "user") && IsStruct(session.user)) {
			return Len(session.user.full_name ?: "") ? session.user.full_name : (session.user.first_name & " " & session.user.last_name);
		}
		return "Procurement Administrator";
	}

	private void function fxRenderJson(required any data, numeric status = 200) {
		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text=SerializeJSON(arguments.data), status=arguments.status);
	}

}
