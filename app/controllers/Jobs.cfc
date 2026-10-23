component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="submitApplication");
	}

	/**
	 * Job Listings Management Studio
	 */
	function index() {
		variables.pageTitle = "Job Postings & Careers Directory";

		// Active Role & Workspace Filter
		local.role = getCurrentActiveRole();
		local.selectedSiteId = structKeyExists(params, "ws") ? LCase(Trim(params.ws)) : (structKeyExists(params, "dept") ? LCase(Trim(params.dept)) : "all");
		local.selectedStatus = structKeyExists(params, "status") ? Trim(params.status) : "Active";
		local.searchQuery = structKeyExists(params, "q") ? Trim(params.q) : "";

		// Fetch Department Workspaces for filter tabs
		variables.departments = getDepartmentsList();
		variables.selectedSiteId = local.selectedSiteId;
		variables.selectedStatus = local.selectedStatus;
		variables.searchQuery = local.searchQuery;

		// Calculate Overall Metrics
		variables.metrics = getJobMetrics(local.selectedSiteId);

		// Build Query Filter Clauses
		local.sqlWhere = " WHERE jl.DeletedAt IS NULL ";
		local.queryParams = {};

		if (local.selectedSiteId != "all" && Len(local.selectedSiteId)) {
			local.sqlWhere &= " AND (LOWER(jl.SiteID) = :siteId) ";
			local.queryParams.siteId = { value: local.selectedSiteId, cfsqltype: "cf_sql_varchar" };
		}

		if (local.selectedStatus != "All" && Len(local.selectedStatus)) {
			local.sqlWhere &= " AND jl.StatusCode = :status ";
			local.queryParams.status = { value: local.selectedStatus, cfsqltype: "cf_sql_varchar" };
		}

		if (Len(local.searchQuery)) {
			local.sqlWhere &= " AND (jl.Title LIKE :q OR jl.ClassCode LIKE :q OR jl.Location LIKE :q OR jl.Description LIKE :q) ";
			local.queryParams.q = { value: "%" & local.searchQuery & "%", cfsqltype: "cf_sql_varchar" };
		}

		// Query Job Listings with Joined Application Counts
		try {
			variables.qJobs = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					jl.JobID, jl.SiteID, jl.Title, jl.Permalink,
					jl.FLSAClassificationID, jl.JobClasificationID, jl.isSupervisor, jl.DirectSupervisor,
					jl.Location, jl.Address, jl.City, jl.State, jl.Zip,
					jl.PostDate, jl.publish_at, jl.unpublish_at, jl.MinSalary, jl.MaxSalary, jl.SalarySchedule, jl.SalaryGroup,
					jl.ClassCode, jl.StatusCode, jl.ApplicationDeadline, jl.Attachment,
					jl.Created, jl.Createdby, jl.Modified, jl.Modifiedby,
					COALESCE(cw.name, jl.SiteID) AS department_name,
					COALESCE(appCounts.total_apps, 0) AS applications_count,
					COALESCE(appCounts.new_apps, 0) AS new_applications_count
				FROM job_listings jl
				LEFT JOIN cms_workspaces cw ON LOWER(jl.SiteID) = LOWER(cw.code)
				LEFT JOIN (
					SELECT 
						JobID, 
						COUNT(*) AS total_apps,
						SUM(CASE WHEN Status = 'New' THEN 1 ELSE 0 END) AS new_apps
					FROM job_applications 
					WHERE DeletedAt IS NULL 
					GROUP BY JobID
				) appCounts ON jl.JobID = appCounts.JobID
				#local.sqlWhere#
				ORDER BY 
					CASE WHEN jl.StatusCode = 'Active' THEN 1 WHEN jl.StatusCode = 'Scheduled' THEN 2 WHEN jl.StatusCode = 'Draft' THEN 3 ELSE 4 END ASC,
					jl.PostDate DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			variables.qJobs = QueryNew("JobID,SiteID,Title,Permalink,ClassCode,StatusCode,MinSalary,MaxSalary,SalarySchedule,SalaryGroup,Location,ApplicationDeadline,applications_count,new_applications_count,department_name");
			variables.queryError = e.message;
		}
	}

	/**
	 * New Job Listing Form
	 */
	function new() {
		variables.pageTitle = "Create Job Posting";
		variables.departments = getDepartmentsList();

		variables.job = {
			jobId: 0,
			siteId: "hrm",
			title: "",
			permalink: "",
			flsaClassificationId: 1, // 1 = Non-Exempt, 2 = Exempt
			jobClassificationId: 1,  // 1 = Full-Time, 2 = Part-Time, 3 = Seasonal, 4 = Temporary, 5 = On-Call
			isSupervisor: 0,
			directSupervisor: "",
			description: "",
			qualification: "",
			responsibilities: "",
			additionalInformation: "Comprehensive medical, dental, vision coverage; Washington State PERS retirement pension; 12 paid holidays + 2 floating holidays; generous sick and annual leave accruals.",
			location: "Wenatchee, WA",
			address: "400 Douglas St",
			city: "Wenatchee",
			state: "WA",
			zip: "98801",
			postDate: DateFormat(Now(), "yyyy-mm-dd"),
			publishAt: "",
			unpublishAt: "",
			minSalary: "",
			maxSalary: "",
			salarySchedule: "Hourly",
			salaryGroup: "Non-Represented",
			classCode: "",
			statusCode: "Active",
			applicationDeadline: "",
			isOpenUntilFilled: 1,
			attachment: ""
		};

		renderView(template="edit");
	}

	/**
	 * Edit Existing Job Listing
	 */
	function edit() {
		variables.departments = getDepartmentsList();

		if (!structKeyExists(params, "id") || !IsNumeric(params.id)) {
			flashInsert(error="Invalid Job ID provided.");
			redirectTo(controller="jobs", action="index");
			return;
		}

		local.jobId = Val(params.id);

		try {
			local.qJob = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 * FROM job_listings WHERE JobID = :id AND DeletedAt IS NULL
			", { id: { value: local.jobId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.qJob.recordCount == 0) {
				flashInsert(error="Job posting not found or has been removed.");
				redirectTo(controller="jobs", action="index");
				return;
			}

			local.publishAtStr = "";
			if (structKeyExists(local.qJob, "publish_at") && IsDate(local.qJob.publish_at)) {
				local.publishAtStr = DateFormat(local.qJob.publish_at, "yyyy-mm-dd") & "T" & TimeFormat(local.qJob.publish_at, "HH:mm");
			} else if (IsDate(local.qJob.PostDate)) {
				local.publishAtStr = DateFormat(local.qJob.PostDate, "yyyy-mm-dd") & "T" & TimeFormat(local.qJob.PostDate, "HH:mm");
			}

			local.unpublishAtStr = "";
			if (structKeyExists(local.qJob, "unpublish_at") && IsDate(local.qJob.unpublish_at)) {
				local.unpublishAtStr = DateFormat(local.qJob.unpublish_at, "yyyy-mm-dd") & "T" & TimeFormat(local.qJob.unpublish_at, "HH:mm");
			} else if (IsDate(local.qJob.ApplicationDeadline)) {
				local.unpublishAtStr = DateFormat(local.qJob.ApplicationDeadline, "yyyy-mm-dd") & "T" & TimeFormat(local.qJob.ApplicationDeadline, "HH:mm");
			}

			variables.job = {
				jobId: local.qJob.JobID,
				siteId: local.qJob.SiteID,
				title: local.qJob.Title,
				permalink: local.qJob.Permalink,
				flsaClassificationId: Val(local.qJob.FLSAClassificationID),
				jobClassificationId: Val(local.qJob.JobClasificationID),
				isSupervisor: local.qJob.isSupervisor ? 1 : 0,
				directSupervisor: local.qJob.DirectSupervisor,
				description: local.qJob.Description,
				qualification: local.qJob.Qualification,
				responsibilities: local.qJob.Responsibilities,
				additionalInformation: local.qJob.AdditionalInformation,
				location: local.qJob.Location,
				address: local.qJob.Address,
				city: local.qJob.City,
				state: local.qJob.State,
				zip: local.qJob.Zip,
				postDate: IsDate(local.qJob.PostDate) ? DateFormat(local.qJob.PostDate, "yyyy-mm-dd") : "",
				publishAt: local.publishAtStr,
				unpublishAt: local.unpublishAtStr,
				minSalary: local.qJob.MinSalary,
				maxSalary: local.qJob.MaxSalary,
				salarySchedule: local.qJob.SalarySchedule,
				salaryGroup: local.qJob.SalaryGroup,
				classCode: local.qJob.ClassCode,
				statusCode: local.qJob.StatusCode,
				applicationDeadline: IsDate(local.qJob.ApplicationDeadline) ? DateFormat(local.qJob.ApplicationDeadline, "yyyy-mm-dd") : "",
				isOpenUntilFilled: (!IsDate(local.qJob.ApplicationDeadline)) ? 1 : 0,
				attachment: local.qJob.Attachment
			};

			variables.pageTitle = "Edit Job Listing: " & local.qJob.Title;
		} catch (any e) {
			flashInsert(error="Error loading job: " & e.message);
			redirectTo(controller="jobs", action="index");
		}
	}

	/**
	 * Save / Update Job Listing
	 */
	function save() {
		local.req = params;
		local.jobId = Val(local.req.JobID ?: (local.req.id ?: 0));
		local.isNew = (local.jobId == 0);

		local.title = Trim(local.req.Title ?: (local.req.title ?: ""));
		local.siteId = LCase(Trim(local.req.SiteID ?: (local.req.department_code ?: "hrm")));
		local.classCode = Trim(local.req.ClassCode ?: (local.req.job_code ?: ""));
		local.permalink = Trim(local.req.Permalink ?: (local.req.permalink ?: ""));
		if (!Len(local.permalink)) local.permalink = slugify(local.title);

		if (!Len(local.title)) {
			if (isAjaxRequest()) {
				fxRenderJson({ success: false, SUCCESS: false, message: "Position title is required." }, 422);
				return;
			}
			flashInsert(error="Position title is required.");
			if (local.isNew) {
				redirectTo(controller="jobs", action="new");
			} else {
				redirectTo(controller="jobs", action="edit", params="id=" & local.jobId);
			}
			return;
		}

		local.flsaId = Val(local.req.FLSAClassificationID ?: 1);
		local.classifId = Val(local.req.JobClasificationID ?: 1);
		local.isSup = structKeyExists(local.req, "isSupervisor") ? 1 : 0;
		local.directSupervisor = Trim(local.req.DirectSupervisor ?: "");
		local.description = Trim(local.req.Description ?: "");
		local.qualification = Trim(local.req.Qualification ?: "");
		local.responsibilities = Trim(local.req.Responsibilities ?: "");
		local.additionalInformation = Trim(local.req.AdditionalInformation ?: "");
		local.location = Trim(local.req.Location ?: "Wenatchee, WA");
		local.address = Trim(local.req.Address ?: "400 Douglas St");
		local.city = Trim(local.req.City ?: "Wenatchee");
		local.state = Trim(local.req.State ?: "WA");
		local.zip = Trim(local.req.Zip ?: "98801");

		local.hasMinSalary = IsNumeric(local.req.MinSalary ?: "");
		local.minSalary = local.hasMinSalary ? Val(local.req.MinSalary) : 0;
		local.hasMaxSalary = IsNumeric(local.req.MaxSalary ?: "");
		local.maxSalary = local.hasMaxSalary ? Val(local.req.MaxSalary) : 0;
		local.salarySchedule = Trim(local.req.SalarySchedule ?: "Hourly");
		local.salaryGroup = Trim(local.req.SalaryGroup ?: "Non-Represented");
		local.statusCode = Trim(local.req.StatusCode ?: "Active");

		local.isOpenUntilFilled = structKeyExists(local.req, "is_open_until_filled") ? 1 : 0;
		local.postDate = IsDate(local.req.PostDate ?: "") ? CreateODBCDateTime(local.req.PostDate) : Now();
		local.hasAppDeadline = (!local.isOpenUntilFilled && IsDate(local.req.ApplicationDeadline ?: ""));
		local.appDeadline = local.hasAppDeadline ? CreateODBCDateTime(local.req.ApplicationDeadline) : "";

		local.publishAt = "";
		if (structKeyExists(local.req, "publish_at") && IsDate(local.req.publish_at)) {
			local.publishAt = CreateODBCDateTime(local.req.publish_at);
		} else if (structKeyExists(local.req, "publishAt") && IsDate(local.req.publishAt)) {
			local.publishAt = CreateODBCDateTime(local.req.publishAt);
		} else {
			local.publishAt = local.postDate;
		}

		local.unpublishAt = "";
		if (structKeyExists(local.req, "unpublish_at") && IsDate(local.req.unpublish_at)) {
			local.unpublishAt = CreateODBCDateTime(local.req.unpublish_at);
		} else if (structKeyExists(local.req, "unpublishAt") && IsDate(local.req.unpublishAt)) {
			local.unpublishAt = CreateODBCDateTime(local.req.unpublishAt);
		} else if (local.hasAppDeadline) {
			local.unpublishAt = local.appDeadline;
		}

		// Auto-set status to Scheduled if publishAt is in the future and status was Active
		if (IsDate(local.publishAt) && DateCompare(local.publishAt, Now()) > 0 && local.statusCode == "Active") {
			local.statusCode = "Scheduled";
		}

		local.actor = getActorName();

		// Handle Attachment Upload
		local.attachment = Trim(local.req.existing_attachment ?: "");
		if (structKeyExists(form, "job_attachment") && Len(form.job_attachment)) {
			try {
				local.uploadDir = expandPath("./files/hrm/documents/");
				if (!DirectoryExists(local.uploadDir)) {
					DirectoryCreate(local.uploadDir);
				}
				cffile(action="upload", fileField="job_attachment", destination=local.uploadDir, nameConflict="makeunique", result="uploadRes");
				local.attachment = "/files/hrm/documents/" & uploadRes.serverFile;
			} catch (any e) {
				// keep existing
			}
		}

		try {
			if (local.isNew) {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO job_listings (
						SiteID, Title, Permalink, FLSAClassificationID, JobClasificationID, isSupervisor, DirectSupervisor,
						Description, Qualification, Responsibilities, AdditionalInformation, Location, Address, City, State, Zip,
						PostDate, publish_at, unpublish_at, MinSalary, MaxSalary, SalarySchedule, SalaryGroup, ClassCode, StatusCode, ApplicationDeadline,
						Attachment, Createdby, Created, Modified, Modifiedby
					) VALUES (
						:siteId, :title, :permalink, :flsaId, :classifId, :isSup, :directSup,
						:desc, :qual, :resp, :addInfo, :loc, :addr, :city, :state, :zip,
						:postDate, :pubAt, :unpubAt, :minSal, :maxSal, :salSched, :salGrp, :classCode, :status, :appDeadline,
						:att, :actor, SYSUTCDATETIME(), SYSUTCDATETIME(), :actor
					)
				", {
					siteId: { value: local.siteId, cfsqltype: "cf_sql_varchar" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					permalink: { value: local.permalink, cfsqltype: "cf_sql_varchar" },
					flsaId: { value: local.flsaId, cfsqltype: "cf_sql_integer" },
					classifId: { value: local.classifId, cfsqltype: "cf_sql_integer" },
					isSup: { value: local.isSup, cfsqltype: "cf_sql_bit" },
					directSup: { value: local.directSupervisor, cfsqltype: "cf_sql_varchar", null: !Len(local.directSupervisor) },
					desc: { value: local.description, cfsqltype: "cf_sql_longvarchar" },
					qual: { value: local.qualification, cfsqltype: "cf_sql_longvarchar" },
					resp: { value: local.responsibilities, cfsqltype: "cf_sql_longvarchar" },
					addInfo: { value: local.additionalInformation, cfsqltype: "cf_sql_longvarchar" },
					loc: { value: local.location, cfsqltype: "cf_sql_varchar" },
					addr: { value: local.address, cfsqltype: "cf_sql_varchar" },
					city: { value: local.city, cfsqltype: "cf_sql_varchar" },
					state: { value: local.state, cfsqltype: "cf_sql_varchar" },
					zip: { value: local.zip, cfsqltype: "cf_sql_varchar" },
					postDate: { value: local.postDate, cfsqltype: "cf_sql_timestamp" },
					pubAt: { value: local.publishAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.publishAt) },
					unpubAt: { value: local.unpublishAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.unpublishAt) },
					minSal: { value: local.minSalary, cfsqltype: "cf_sql_decimal", null: !IsNumeric(local.minSalary) },
					maxSal: { value: local.maxSalary, cfsqltype: "cf_sql_decimal", null: !IsNumeric(local.maxSalary) },
					salSched: { value: local.salarySchedule, cfsqltype: "cf_sql_varchar" },
					salGrp: { value: local.salaryGroup, cfsqltype: "cf_sql_varchar" },
					classCode: { value: local.classCode, cfsqltype: "cf_sql_varchar" },
					status: { value: local.statusCode, cfsqltype: "cf_sql_varchar" },
					appDeadline: { value: local.appDeadline, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.appDeadline) },
					att: { value: local.attachment, cfsqltype: "cf_sql_varchar", null: !Len(local.attachment) },
					actor: { value: local.actor, cfsqltype: "cf_sql_varchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.qNew = queryExecute("SELECT SCOPE_IDENTITY() AS NewID", {}, { datasource: "ChelanCountyWebsite" });
				local.newJobId = Val(local.qNew.NewID ?: 0);

				if (isAjaxRequest()) {
					fxRenderJson({
						success: true,
						SUCCESS: true,
						message: "Job listing '" & local.title & "' posted successfully!",
						jobId: local.newJobId,
						title: local.title,
						attachment: local.attachment,
						redirectUrl: urlFor(controller="jobs", action="edit", params="id=" & local.newJobId)
					});
					return;
				}

				flashInsert(success="Job listing '" & local.title & "' posted successfully!");
			} else {
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					UPDATE job_listings SET
						SiteID = :siteId,
						Title = :title,
						Permalink = :permalink,
						FLSAClassificationID = :flsaId,
						JobClasificationID = :classifId,
						isSupervisor = :isSup,
						DirectSupervisor = :directSup,
						Description = :desc,
						Qualification = :qual,
						Responsibilities = :resp,
						AdditionalInformation = :addInfo,
						Location = :loc,
						Address = :addr,
						City = :city,
						State = :state,
						Zip = :zip,
						PostDate = :postDate,
						publish_at = :pubAt,
						unpublish_at = :unpubAt,
						MinSalary = :minSal,
						MaxSalary = :maxSal,
						SalarySchedule = :salSched,
						SalaryGroup = :salGrp,
						ClassCode = :classCode,
						StatusCode = :status,
						ApplicationDeadline = :appDeadline,
						Attachment = :att,
						Modified = SYSUTCDATETIME(),
						Modifiedby = :actor
					WHERE JobID = :id
				", {
					siteId: { value: local.siteId, cfsqltype: "cf_sql_varchar" },
					title: { value: local.title, cfsqltype: "cf_sql_varchar" },
					permalink: { value: local.permalink, cfsqltype: "cf_sql_varchar" },
					flsaId: { value: local.flsaId, cfsqltype: "cf_sql_integer" },
					classifId: { value: local.classifId, cfsqltype: "cf_sql_integer" },
					isSup: { value: local.isSup, cfsqltype: "cf_sql_bit" },
					directSup: { value: local.directSupervisor, cfsqltype: "cf_sql_varchar", null: !Len(local.directSupervisor) },
					desc: { value: local.description, cfsqltype: "cf_sql_longvarchar" },
					qual: { value: local.qualification, cfsqltype: "cf_sql_longvarchar" },
					resp: { value: local.responsibilities, cfsqltype: "cf_sql_longvarchar" },
					addInfo: { value: local.additionalInformation, cfsqltype: "cf_sql_longvarchar" },
					loc: { value: local.location, cfsqltype: "cf_sql_varchar" },
					addr: { value: local.address, cfsqltype: "cf_sql_varchar" },
					city: { value: local.city, cfsqltype: "cf_sql_varchar" },
					state: { value: local.state, cfsqltype: "cf_sql_varchar" },
					zip: { value: local.zip, cfsqltype: "cf_sql_varchar" },
					postDate: { value: local.postDate, cfsqltype: "cf_sql_timestamp" },
					pubAt: { value: local.publishAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.publishAt) },
					unpubAt: { value: local.unpublishAt, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.unpublishAt) },
					minSal: { value: local.minSalary, cfsqltype: "cf_sql_decimal", null: !IsNumeric(local.minSalary) },
					maxSal: { value: local.maxSalary, cfsqltype: "cf_sql_decimal", null: !IsNumeric(local.maxSalary) },
					salSched: { value: local.salarySchedule, cfsqltype: "cf_sql_varchar" },
					salGrp: { value: local.salaryGroup, cfsqltype: "cf_sql_varchar" },
					classCode: { value: local.classCode, cfsqltype: "cf_sql_varchar" },
					status: { value: local.statusCode, cfsqltype: "cf_sql_varchar" },
					appDeadline: { value: local.appDeadline, cfsqltype: "cf_sql_timestamp", null: !IsDate(local.appDeadline) },
					att: { value: local.attachment, cfsqltype: "cf_sql_varchar", null: !Len(local.attachment) },
					actor: { value: local.actor, cfsqltype: "cf_sql_varchar" },
					id: { value: local.jobId, cfsqltype: "cf_sql_integer" }
				}, { datasource: "ChelanCountyWebsite" });

				if (isAjaxRequest()) {
					fxRenderJson({
						success: true,
						SUCCESS: true,
						message: "Job listing '" & local.title & "' updated successfully!",
						jobId: local.jobId,
						title: local.title,
						attachment: local.attachment,
						redirectUrl: urlFor(controller="jobs", action="edit", params="id=" & local.jobId)
					});
					return;
				}

				flashInsert(success="Job listing '" & local.title & "' updated successfully!");
			}

			redirectTo(controller="jobs", action="index");
		} catch (any e) {
			if (isAjaxRequest()) {
				fxRenderJson({ success: false, SUCCESS: false, message: "Error saving job listing attributes: " & e.message }, 500);
				return;
			}
			flashInsert(error="Error saving job listing attributes: " & e.message);
			if (local.isNew) {
				redirectTo(controller="jobs", action="new");
			} else {
				redirectTo(controller="jobs", action="edit", params="id=" & local.jobId);
			}
		}
	}

	/**
	 * Toggle Status (Active <-> Closed)
	 */
	function toggleStatus() {
		local.jobId = Val(params.id ?: 0);
		local.targetStatus = Trim(params.status ?: "");

		if (local.jobId <= 0) {
			if (isAjaxRequest()) {
				fxRenderJson({ success: false, message: "Invalid Job ID" }, 400);
				return;
			}
			redirectTo(controller="jobs", action="index");
			return;
		}

		try {
			if (!Len(local.targetStatus)) {
				local.current = queryExecute("SELECT StatusCode FROM job_listings WHERE JobID = :id", { id: { value: local.jobId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
				local.targetStatus = (local.current.StatusCode == "Active") ? "Closed" : "Active";
			}

			queryExecute("
				UPDATE job_listings SET StatusCode = :status, Modified = SYSUTCDATETIME() WHERE JobID = :id
			", {
				status: { value: local.targetStatus, cfsqltype: "cf_sql_varchar" },
				id: { value: local.jobId, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			if (isAjaxRequest()) {
				fxRenderJson({ success: true, newStatus: local.targetStatus, message: "Status changed to " & local.targetStatus });
				return;
			}

			flashInsert(success="Status updated to " & local.targetStatus);
			redirectTo(controller="jobs", action="index");
		} catch (any e) {
			if (isAjaxRequest()) {
				fxRenderJson({ success: false, message: e.message }, 500);
				return;
			}
			flashInsert(error="Error updating status: " & e.message);
			redirectTo(controller="jobs", action="index");
		}
	}

	/**
	 * Soft Delete Job Listing
	 */
	function delete() {
		local.jobId = Val(params.id ?: 0);

		if (local.jobId <= 0) {
			if (isAjaxRequest()) {
				fxRenderJson({ success: false, message: "Invalid Job ID" }, 400);
				return;
			}
			redirectTo(controller="jobs", action="index");
			return;
		}

		try {
			queryExecute("
				UPDATE job_listings SET DeletedAt = SYSUTCDATETIME(), StatusCode = 'Archived', Deletedby = :actor WHERE JobID = :id
			", {
				actor: { value: getActorName(), cfsqltype: "cf_sql_varchar" },
				id: { value: local.jobId, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			if (isAjaxRequest()) {
				fxRenderJson({ success: true, message: "Job listing archived successfully." });
				return;
			}

			flashInsert(success="Job listing archived successfully.");
			redirectTo(controller="jobs", action="index");
		} catch (any e) {
			if (isAjaxRequest()) {
				fxRenderJson({ success: false, message: e.message }, 500);
				return;
			}
			flashInsert(error="Error archiving job: " & e.message);
			redirectTo(controller="jobs", action="index");
		}
	}

	/**
	 * Master Candidate Applications Directory
	 */
	function applications() {
		variables.pageTitle = "Candidate Applications & Intake";

		local.selectedJobId = structKeyExists(params, "jobId") && IsNumeric(params.jobId) ? Val(params.jobId) : 0;
		local.selectedStatus = structKeyExists(params, "status") ? Trim(params.status) : "All";
		local.searchQuery = structKeyExists(params, "q") ? Trim(params.q) : "";

		variables.selectedJobId = local.selectedJobId;
		variables.selectedStatus = local.selectedStatus;
		variables.searchQuery = local.searchQuery;

		// Load Job Openings for position filter dropdown
		variables.qJobList = queryExecute("
			SELECT JobID, ClassCode, Title, SiteID FROM job_listings WHERE DeletedAt IS NULL ORDER BY Title ASC
		", {}, { datasource: "ChelanCountyWebsite" });

		// Overall Application Metrics
		variables.appMetrics = getApplicationMetrics(local.selectedJobId);

		// Build WHERE clause
		local.sqlWhere = " WHERE ja.DeletedAt IS NULL ";
		local.queryParams = {};

		if (local.selectedJobId > 0) {
			local.sqlWhere &= " AND ja.JobID = :jobId ";
			local.queryParams.jobId = { value: local.selectedJobId, cfsqltype: "cf_sql_integer" };
		}

		if (local.selectedStatus != "All" && Len(local.selectedStatus)) {
			local.sqlWhere &= " AND ja.Status = :status ";
			local.queryParams.status = { value: local.selectedStatus, cfsqltype: "cf_sql_varchar" };
		}

		if (Len(local.searchQuery)) {
			local.sqlWhere &= " AND (ja.FirstName LIKE :q OR ja.LastName LIKE :q OR ja.Email LIKE :q OR ja.Phone LIKE :q OR ja.Position LIKE :q OR ja.City LIKE :q) ";
			local.queryParams.q = { value: "%" & local.searchQuery & "%", cfsqltype: "cf_sql_varchar" };
		}

		try {
			variables.qApps = queryExecute("
				SELECT 
					ja.ApplicationID, ja.JobID, ja.Position,
					ja.FirstName, ja.MiddleName, ja.LastName,
					ja.Email, ja.Phone, ja.City, ja.State, ja.Zip,
					ja.hasLicense, ja.hasCDL, ja.CDLType, ja.wasEmployed, ja.hasRelative,
					ja.HighestGrade, ja.Education1, ja.Degree1,
					ja.WorkExperienceEmployer1, ja.WorkExperienceReason1,
					ja.Status, ja.Rating, ja.AdminNotes, ja.ReviewedBy, ja.ReviewedAt,
					ja.EntryDate,
					jl.Title AS job_title, jl.ClassCode AS job_code, jl.SiteID AS department_code,
					COALESCE(cw.name, jl.SiteID) AS department_name
				FROM job_applications ja
				LEFT JOIN job_listings jl ON ja.JobID = jl.JobID
				LEFT JOIN cms_workspaces cw ON LOWER(jl.SiteID) = LOWER(cw.code)
				#local.sqlWhere#
				ORDER BY ja.EntryDate DESC
			", local.queryParams, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			variables.qApps = QueryNew("ApplicationID,JobID,Position,FirstName,LastName,Email,Phone,City,State,hasLicense,hasCDL,Status,Rating,EntryDate,job_title");
			variables.queryError = e.message;
		}
	}

	/**
	 * Detailed Application Dossier View (Inspector)
	 */
	function application() {
		local.id = Val(params.id ?: 0);

		if (local.id <= 0) {
			flashInsert(error="Invalid application ID specified.");
			redirectTo(controller="jobs", action="applications");
			return;
		}

		try {
			local.qApp = queryExecute("
				SELECT 
					ja.*,
					jl.Title AS job_posting_title, jl.ClassCode AS job_code, jl.SiteID,
					COALESCE(cw.name, jl.SiteID) AS department_name,
					jl.MinSalary, jl.MaxSalary, jl.SalarySchedule, jl.JobClasificationID
				FROM job_applications ja
				LEFT JOIN job_listings jl ON ja.JobID = jl.JobID
				LEFT JOIN cms_workspaces cw ON LOWER(jl.SiteID) = LOWER(cw.code)
				WHERE ja.ApplicationID = :id AND ja.DeletedAt IS NULL
			", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

			if (local.qApp.recordCount == 0) {
				flashInsert(error="Application not found or has been removed.");
				redirectTo(controller="jobs", action="applications");
				return;
			}

			variables.app = local.qApp;
			variables.pageTitle = "Candidate File: " & local.qApp.FirstName & " " & local.qApp.LastName & " - " & local.qApp.Position;
		} catch (any e) {
			flashInsert(error="Error loading applicant file: " & e.message);
			redirectTo(controller="jobs", action="applications");
		}
	}

	/**
	 * AJAX Update Application Status, Rating & Notes
	 */
	function updateApplicationStatus() {
		local.body = fxReadJsonBody();
		local.req = IsStruct(local.body) ? local.body : params;

		local.id = Val(local.req.applicationId ?: (local.req.id ?: 0));
		local.status = Trim(local.req.status ?: "");
		local.rating = Val(local.req.rating ?: 0);
		local.notes = Trim(local.req.notes ?: (local.req.adminNotes ?: ""));
		local.actor = getActorName();

		if (local.id <= 0) {
			fxRenderJson({ success: false, message: "Invalid Application ID" }, 400);
			return;
		}

		try {
			queryExecute("
				UPDATE job_applications SET
					Status = :status,
					Rating = :rating,
					AdminNotes = :notes,
					ReviewedBy = :actor,
					ReviewedAt = SYSUTCDATETIME()
				WHERE ApplicationID = :id
			", {
				status: { value: local.status, cfsqltype: "cf_sql_varchar" },
				rating: { value: local.rating, cfsqltype: "cf_sql_integer" },
				notes: { value: local.notes, cfsqltype: "cf_sql_longvarchar" },
				actor: { value: local.actor, cfsqltype: "cf_sql_varchar" },
				id: { value: local.id, cfsqltype: "cf_sql_integer" }
			}, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({ 
				success: true, 
				message: "Candidate application updated.", 
				newStatus: local.status,
				reviewedBy: local.actor,
				reviewedAt: DateFormat(Now(), "mmm d, yyyy") & " " & TimeFormat(Now(), "h:mm tt")
			});
		} catch (any e) {
			fxRenderJson({ success: false, message: e.message }, 500);
		}
	}

	/**
	 * Export Applications to CSV
	 */
	function exportCsv() {
		local.jobId = Val(params.jobId ?: 0);
		local.status = Trim(params.status ?: "");

		local.sqlWhere = " WHERE ja.DeletedAt IS NULL ";
		local.queryParams = {};

		if (local.jobId > 0) {
			local.sqlWhere &= " AND ja.JobID = :jobId ";
			local.queryParams.jobId = { value: local.jobId, cfsqltype: "cf_sql_integer" };
		}
		if (Len(local.status) && local.status != "All") {
			local.sqlWhere &= " AND ja.Status = :status ";
			local.queryParams.status = { value: local.status, cfsqltype: "cf_sql_varchar" };
		}

		local.q = queryExecute("
			SELECT 
				ja.ApplicationID, ja.Position, ja.FirstName, ja.MiddleName, ja.LastName,
				ja.Email, ja.Phone, ja.Address1, ja.Address2, ja.City, ja.State, ja.Zip,
				ja.hasLicense, ja.LicenseNo, ja.LicenseState, ja.LicenseExpireDate,
				ja.hasCDL, ja.CDLNo, ja.CDLState, ja.CDLExpireDate, ja.CDLType, ja.CDLRestriction,
				ja.wasEmployed, ja.EmploymentStart, ja.EmploymentEnd, ja.EmploymentDepartment,
				ja.hasRelative, ja.RelativeNames, ja.under18, ja.hasImmigration,
				ja.ForeignLanguage1, ja.Proficiency1, ja.ForeignLanguage2, ja.Proficiency2,
				ja.hasGED, ja.HighestGrade, ja.Education1, ja.Degree1, ja.DateEarned1,
				ja.WorkExperienceEmployer1, ja.WorkExperienceStart1, ja.WorkExperienceEnd1, ja.WorkExperienceReason1,
				ja.ReferenceName1, ja.ReferencePhone1, ja.ReferenceEmail1,
				ja.Status, ja.Rating, ja.AdminNotes, ja.ReviewedBy, ja.ReviewedAt, ja.EntryDate
			FROM job_applications ja
			#local.sqlWhere#
			ORDER BY ja.EntryDate DESC
		", local.queryParams, { datasource: "ChelanCountyWebsite" });

		local.csv = "ApplicationID,Position,FirstName,LastName,Email,Phone,City,State,Zip,HasLicense,HasCDL,CDLType,WasEmployed,HasRelative,Education1,Degree1,Employer1,Status,Rating,EntryDate" & chr(13) & chr(10);

		for (local.row in local.q) {
			local.line = [
				local.row.ApplicationID,
				'"' & Replace(local.row.Position, '"', '""', 'all') & '"',
				'"' & Replace(local.row.FirstName, '"', '""', 'all') & '"',
				'"' & Replace(local.row.LastName, '"', '""', 'all') & '"',
				'"' & Replace(local.row.Email, '"', '""', 'all') & '"',
				'"' & Replace(local.row.Phone, '"', '""', 'all') & '"',
				'"' & Replace(local.row.City, '"', '""', 'all') & '"',
				'"' & Replace(local.row.State, '"', '""', 'all') & '"',
				'"' & Replace(local.row.Zip, '"', '""', 'all') & '"',
				local.row.hasLicense ? 'Yes' : 'No',
				local.row.hasCDL ? 'Yes' : 'No',
				'"' & Replace(local.row.CDLType ?: '', '"', '""', 'all') & '"',
				local.row.wasEmployed ? 'Yes' : 'No',
				local.row.hasRelative ? 'Yes' : 'No',
				'"' & Replace(local.row.Education1 ?: '', '"', '""', 'all') & '"',
				'"' & Replace(local.row.Degree1 ?: '', '"', '""', 'all') & '"',
				'"' & Replace(local.row.WorkExperienceEmployer1 ?: '', '"', '""', 'all') & '"',
				'"' & Replace(local.row.Status ?: '', '"', '""', 'all') & '"',
				local.row.Rating,
				DateFormat(local.row.EntryDate, "yyyy-mm-dd")
			];
			local.csv &= ArrayToList(local.line, ",") & chr(13) & chr(10);
		}

		cfheader(name="Content-Disposition", value="attachment; filename=""chelan-job-applications-#DateFormat(Now(), 'yyyymmdd')#.csv""");
		renderText(text=local.csv, contentType="text/csv");
	}

	/**
	 * Public Career Portal - List Open Jobs
	 */
	function publicList() {
		variables.pageTitle = "Chelan County Careers & Job Opportunities";
		variables.departments = getDepartmentsList();

		try {
			variables.qJobs = queryExecute("
				SELECT 
					jl.*,
					COALESCE(cw.name, jl.SiteID) AS department_name
				FROM job_listings jl
				LEFT JOIN cms_workspaces cw ON LOWER(jl.SiteID) = LOWER(cw.code)
				WHERE jl.StatusCode = 'Active' AND jl.DeletedAt IS NULL
				ORDER BY jl.Title ASC
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {
			variables.qJobs = QueryNew("JobID,Title,Permalink,ClassCode,MinSalary,MaxSalary,SalarySchedule,Location,Description,department_name");
		}

		renderView(template="publicList", layout="false", hideDebugInformation=true);
	}

	/**
	 * Public Job Posting View
	 */
	function publicView() {
		local.id = Val(params.id ?: 0);
		local.permalink = Trim(params.permalink ?: (params.code ?: ""));

		local.sqlWhere = " WHERE jl.StatusCode = 'Active' AND jl.DeletedAt IS NULL ";
		local.p = {};
		if (local.id > 0) {
			local.sqlWhere &= " AND jl.JobID = :id ";
			local.p.id = { value: local.id, cfsqltype: "cf_sql_integer" };
		} else if (Len(local.permalink)) {
			local.sqlWhere &= " AND (jl.Permalink = :p OR jl.ClassCode = :p) ";
			local.p.p = { value: local.permalink, cfsqltype: "cf_sql_varchar" };
		} else {
			redirectTo(controller="jobs", action="publicList");
			return;
		}

		try {
			variables.qJob = queryExecute("
				SELECT TOP 1 
					jl.*,
					COALESCE(cw.name, jl.SiteID) AS department_name
				FROM job_listings jl
				LEFT JOIN cms_workspaces cw ON LOWER(jl.SiteID) = LOWER(cw.code)
				#local.sqlWhere#
			", local.p, { datasource: "ChelanCountyWebsite" });

			if (variables.qJob.recordCount == 0) {
				redirectTo(controller="jobs", action="publicList");
				return;
			}

			variables.pageTitle = variables.qJob.Title & " - Chelan County Careers";
		} catch (any e) {
			redirectTo(controller="jobs", action="publicList");
			return;
		}

		renderView(template="publicView", layout="false", hideDebugInformation=true);
	}

	/**
	 * Public Job Application Intake Form
	 */
	function apply() {
		local.id = Val(params.id ?: (params.jobId ?: 0));
		variables.job = { jobId: 0, title: "General Employment Application", classCode: "", department_name: "Countywide" };

		if (local.id > 0) {
			try {
				local.qJ = queryExecute("
					SELECT TOP 1 
						jl.*,
						COALESCE(cw.name, jl.SiteID) AS department_name
					FROM job_listings jl
					LEFT JOIN cms_workspaces cw ON LOWER(jl.SiteID) = LOWER(cw.code)
					WHERE jl.JobID = :id AND jl.DeletedAt IS NULL
				", { id: { value: local.id, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });

				if (local.qJ.recordCount) {
					variables.job = {
						jobId: local.qJ.JobID,
						title: local.qJ.Title,
						classCode: local.qJ.ClassCode,
						department_name: local.qJ.department_name
					};
				}
			} catch (any e) {
				// Fallback
			}
		}

		variables.pageTitle = "Apply: " & variables.job.title;
		renderView(template="apply", layout="false", hideDebugInformation=true);
	}

	/**
	 * Submit Public Job Application
	 */
	function submitApplication() {
		local.req = params;

		// Anti-spam honeypot
		if (Len(Trim(local.req._chelan_gov_verify ?: ""))) {
			fxRenderJson({ success: false, message: "Spam verification check failed." }, 400);
			return;
		}

		local.jobId = Val(local.req.JobID ?: (local.req.job_id ?: 0));
		local.position = Trim(local.req.Position ?: (local.req.position ?: ""));
		local.firstName = Trim(local.req.FirstName ?: (local.req.first_name ?: ""));
		local.middleName = Trim(local.req.MiddleName ?: (local.req.middle_name ?: ""));
		local.lastName = Trim(local.req.LastName ?: (local.req.last_name ?: ""));
		local.email = Trim(local.req.Email ?: (local.req.email ?: ""));
		local.phone = Trim(local.req.Phone ?: (local.req.phone ?: ""));
		local.address1 = Trim(local.req.Address1 ?: (local.req.address1 ?: ""));
		local.address2 = Trim(local.req.Address2 ?: (local.req.address2 ?: ""));
		local.city = Trim(local.req.City ?: (local.req.city ?: ""));
		local.state = Trim(local.req.State ?: (local.req.state ?: "WA"));
		local.zip = Trim(local.req.Zip ?: (local.req.zip ?: ""));

		if (!Len(local.firstName) || !Len(local.lastName) || !Len(local.email) || !Len(local.phone)) {
			fxRenderJson({ success: false, message: "Please fill in all required contact details." }, 422);
			return;
		}

		// License fields
		local.hasLicense = (structKeyExists(local.req, "hasLicense") && (local.req.hasLicense == "1" || local.req.hasLicense == "true")) ? 1 : 0;
		local.licenseNo = Trim(local.req.LicenseNo ?: (local.req.license_no ?: ""));
		local.licenseState = Trim(local.req.LicenseState ?: (local.req.license_state ?: ""));
		local.hasLicenseExp = IsDate(local.req.LicenseExpireDate ?: (local.req.license_expire ?: ""));
		local.licenseExp = local.hasLicenseExp ? CreateODBCDateTime(local.req.LicenseExpireDate ?: local.req.license_expire) : "";

		// CDL fields
		local.hasCDL = (structKeyExists(local.req, "hasCDL") && (local.req.hasCDL == "1" || local.req.hasCDL == "true")) ? 1 : 0;
		local.cdlNo = Trim(local.req.CDLNo ?: (local.req.cdl_no ?: ""));
		local.cdlState = Trim(local.req.CDLState ?: (local.req.cdl_state ?: ""));
		local.hasCdlExp = IsDate(local.req.CDLExpireDate ?: (local.req.cdl_expire ?: ""));
		local.cdlExp = local.hasCdlExp ? CreateODBCDateTime(local.req.CDLExpireDate ?: local.req.cdl_expire) : "";
		local.cdlType = Trim(local.req.CDLType ?: (local.req.cdl_type ?: ""));
		local.cdlRestriction = Trim(local.req.CDLRestriction ?: (local.req.cdl_restriction ?: ""));

		// Previous employment
		local.wasEmployed = (structKeyExists(local.req, "wasEmployed") && (local.req.wasEmployed == "1" || local.req.wasEmployed == "true")) ? 1 : 0;
		local.hasEmpStart = IsDate(local.req.EmploymentStart ?: (local.req.employment_start ?: ""));
		local.empStart = local.hasEmpStart ? CreateODBCDateTime(local.req.EmploymentStart ?: local.req.employment_start) : "";
		local.hasEmpEnd = IsDate(local.req.EmploymentEnd ?: (local.req.employment_end ?: ""));
		local.empEnd = local.hasEmpEnd ? CreateODBCDateTime(local.req.EmploymentEnd ?: local.req.employment_end) : "";
		local.empDept = Trim(local.req.EmploymentDepartment ?: (local.req.employment_department ?: ""));

		// Relatives
		local.hasRelative = (structKeyExists(local.req, "hasRelative") && (local.req.hasRelative == "1" || local.req.hasRelative == "true")) ? 1 : 0;
		local.relativeNames = Trim(local.req.RelativeNames ?: (local.req.relative_names ?: ""));

		// Eligibility
		local.under18 = (structKeyExists(local.req, "under18") && (local.req.under18 == "1" || local.req.under18 == "true")) ? 1 : 0;
		local.hasImmigration = (structKeyExists(local.req, "hasImmigration") && (local.req.hasImmigration == "1" || local.req.hasImmigration == "true")) ? 1 : 0;

		// Languages
		local.lang1 = Trim(local.req.ForeignLanguage1 ?: (local.req.lang_1 ?: ""));
		local.prof1 = Trim(local.req.Proficiency1 ?: (local.req.prof_1 ?: ""));
		local.lang2 = Trim(local.req.ForeignLanguage2 ?: (local.req.lang_2 ?: ""));
		local.prof2 = Trim(local.req.Proficiency2 ?: (local.req.prof_2 ?: ""));
		local.lang3 = Trim(local.req.ForeignLanguage3 ?: (local.req.lang_3 ?: ""));
		local.prof3 = Trim(local.req.Proficiency3 ?: (local.req.prof_3 ?: ""));

		// Education
		local.hasGED = (structKeyExists(local.req, "hasGED") && (local.req.hasGED == "1" || local.req.hasGED == "true")) ? 1 : 0;
		local.highestGrade = Trim(local.req.HighestGrade ?: (local.req.highest_grade ?: ""));
		local.edu1 = Trim(local.req.Education1 ?: (local.req.edu_1 ?: ""));
		local.deg1 = Trim(local.req.Degree1 ?: (local.req.deg_1 ?: ""));
		local.date1 = Trim(local.req.DateEarned1 ?: (local.req.date_1 ?: ""));
		local.edu2 = Trim(local.req.Education2 ?: (local.req.edu_2 ?: ""));
		local.deg2 = Trim(local.req.Degree2 ?: (local.req.deg_2 ?: ""));
		local.date2 = Trim(local.req.DateEarned2 ?: (local.req.date_2 ?: ""));
		local.edu3 = Trim(local.req.Education3 ?: (local.req.edu_3 ?: ""));
		local.deg3 = Trim(local.req.Degree3 ?: (local.req.deg_3 ?: ""));
		local.date3 = Trim(local.req.DateEarned3 ?: (local.req.date_3 ?: ""));
		local.edu4 = Trim(local.req.Education4 ?: (local.req.edu_4 ?: ""));
		local.deg4 = Trim(local.req.Degree4 ?: (local.req.deg_4 ?: ""));
		local.date4 = Trim(local.req.DateEarned4 ?: (local.req.date_4 ?: ""));

		// Work Experience 1-3
		local.workEmp1 = Trim(local.req.WorkExperienceEmployer1 ?: (local.req.work_emp_1 ?: ""));
		local.workPhone1 = Trim(local.req.WorkExperienceEmployerPhone1 ?: (local.req.work_phone_1 ?: ""));
		local.workStart1 = Trim(local.req.WorkExperienceStart1 ?: (local.req.work_start_1 ?: ""));
		local.workEnd1 = Trim(local.req.WorkExperienceEnd1 ?: (local.req.work_end_1 ?: ""));
		local.workReason1 = Trim(local.req.WorkExperienceReason1 ?: (local.req.work_reason_1 ?: ""));

		local.workEmp2 = Trim(local.req.WorkExperienceEmployer2 ?: (local.req.work_emp_2 ?: ""));
		local.workPhone2 = Trim(local.req.WorkExperienceEmployerPhone2 ?: (local.req.work_phone_2 ?: ""));
		local.workStart2 = Trim(local.req.WorkExperienceStart2 ?: (local.req.work_start_2 ?: ""));
		local.workEnd2 = Trim(local.req.WorkExperienceEnd2 ?: (local.req.work_end_2 ?: ""));
		local.workReason2 = Trim(local.req.WorkExperienceReason2 ?: (local.req.work_reason_2 ?: ""));

		local.workEmp3 = Trim(local.req.WorkExperienceEmployer3 ?: (local.req.work_emp_3 ?: ""));
		local.workPhone3 = Trim(local.req.WorkExperienceEmployerPhone3 ?: (local.req.work_phone_3 ?: ""));
		local.workStart3 = Trim(local.req.WorkExperienceStart3 ?: (local.req.work_start_3 ?: ""));
		local.workEnd3 = Trim(local.req.WorkExperienceEnd3 ?: (local.req.work_end_3 ?: ""));
		local.workReason3 = Trim(local.req.WorkExperienceReason3 ?: (local.req.work_reason_3 ?: ""));

		// References 1-3
		local.refName1 = Trim(local.req.ReferenceName1 ?: (local.req.ref_name_1 ?: ""));
		local.refEmail1 = Trim(local.req.ReferenceEmail1 ?: (local.req.ref_email_1 ?: ""));
		local.refPhone1 = Trim(local.req.ReferencePhone1 ?: (local.req.ref_phone_1 ?: ""));

		local.refName2 = Trim(local.req.ReferenceName2 ?: (local.req.ref_name_2 ?: ""));
		local.refEmail2 = Trim(local.req.ReferenceEmail2 ?: (local.req.ref_email_2 ?: ""));
		local.refPhone2 = Trim(local.req.ReferencePhone2 ?: (local.req.ref_phone_2 ?: ""));

		local.refName3 = Trim(local.req.ReferenceName3 ?: (local.req.ref_name_3 ?: ""));
		local.refEmail3 = Trim(local.req.ReferenceEmail3 ?: (local.req.ref_email_3 ?: ""));
		local.refPhone3 = Trim(local.req.ReferencePhone3 ?: (local.req.ref_phone_3 ?: ""));

		// Attestation & Signature
		local.certification = 1;
		local.signature = Trim(local.req.Signature ?: (local.req.signature ?: (local.firstName & " " & local.lastName)));

		try {
			local.insRes = queryExecute("
				INSERT INTO job_applications (
					JobID, Position, FirstName, MiddleName, LastName, Email, Phone,
					Address1, Address2, City, State, Zip,
					hasLicense, LicenseNo, LicenseState, LicenseExpireDate,
					hasCDL, CDLNo, CDLState, CDLExpireDate, CDLType, CDLRestriction,
					wasEmployed, EmploymentStart, EmploymentEnd, EmploymentDepartment,
					hasRelative, RelativeNames, under18, hasImmigration,
					ForeignLanguage1, Proficiency1, ForeignLanguage2, Proficiency2, ForeignLanguage3, Proficiency3,
					hasGED, HighestGrade,
					Education1, Degree1, DateEarned1,
					Education2, Degree2, DateEarned2,
					Education3, Degree3, DateEarned3,
					Education4, Degree4, DateEarned4,
					WorkExperienceEmployer1, WorkExperienceEmployerPhone1, WorkExperienceStart1, WorkExperienceEnd1, WorkExperienceReason1,
					WorkExperienceEmployer2, WorkExperienceEmployerPhone2, WorkExperienceStart2, WorkExperienceEnd2, WorkExperienceReason2,
					WorkExperienceEmployer3, WorkExperienceEmployerPhone3, WorkExperienceStart3, WorkExperienceEnd3, WorkExperienceReason3,
					ReferenceName1, ReferenceEmail1, ReferencePhone1,
					ReferenceName2, ReferenceEmail2, ReferencePhone2,
					ReferenceName3, ReferenceEmail3, ReferencePhone3,
					Certification, Signature, EntryDate, Status, Rating
				) 
				OUTPUT INSERTED.ApplicationID AS newId
				VALUES (
					:jobId, :pos, :fn, :mn, :ln, :email, :phone,
					:addr1, :addr2, :city, :state, :zip,
					:hasLic, :licNo, :licState, :licExp,
					:hasCdl, :cdlNo, :cdlState, :cdlExp, :cdlType, :cdlRest,
					:wasEmp, :empStart, :empEnd, :empDept,
					:hasRel, :relNames, :under18, :hasImm,
					:lang1, :prof1, :lang2, :prof2, :lang3, :prof3,
					:hasGed, :highGrade,
					:edu1, :deg1, :date1,
					:edu2, :deg2, :date2,
					:edu3, :deg3, :date3,
					:edu4, :deg4, :date4,
					:we1, :wp1, :ws1, :weEnd1, :wr1,
					:we2, :wp2, :ws2, :weEnd2, :wr2,
					:we3, :wp3, :ws3, :weEnd3, :wr3,
					:rn1, :re1, :rp1,
					:rn2, :re2, :rp2,
					:rn3, :re3, :rp3,
					:cert, :sig, SYSUTCDATETIME(), 'New', 0
				)
			", {
				jobId: { value: local.jobId > 0 ? local.jobId : 0, cfsqltype: "cf_sql_integer", null: (local.jobId <= 0) },
				pos: { value: local.position, cfsqltype: "cf_sql_varchar" },
				fn: { value: local.firstName, cfsqltype: "cf_sql_varchar" },
				mn: { value: local.middleName, cfsqltype: "cf_sql_varchar", null: !Len(local.middleName) },
				ln: { value: local.lastName, cfsqltype: "cf_sql_varchar" },
				email: { value: local.email, cfsqltype: "cf_sql_varchar" },
				phone: { value: local.phone, cfsqltype: "cf_sql_varchar" },
				addr1: { value: local.address1, cfsqltype: "cf_sql_varchar" },
				addr2: { value: local.address2, cfsqltype: "cf_sql_varchar", null: !Len(local.address2) },
				city: { value: local.city, cfsqltype: "cf_sql_varchar" },
				state: { value: local.state, cfsqltype: "cf_sql_varchar" },
				zip: { value: local.zip, cfsqltype: "cf_sql_varchar" },
				hasLic: { value: local.hasLicense, cfsqltype: "cf_sql_bit" },
				licNo: { value: local.licenseNo, cfsqltype: "cf_sql_varchar", null: !Len(local.licenseNo) },
				licState: { value: local.licenseState, cfsqltype: "cf_sql_varchar", null: !Len(local.licenseState) },
				licExp: { value: local.licenseExp, cfsqltype: "cf_sql_timestamp", null: !local.hasLicenseExp },
				hasCdl: { value: local.hasCDL, cfsqltype: "cf_sql_bit" },
				cdlNo: { value: local.cdlNo, cfsqltype: "cf_sql_varchar", null: !Len(local.cdlNo) },
				cdlState: { value: local.cdlState, cfsqltype: "cf_sql_varchar", null: !Len(local.cdlState) },
				cdlExp: { value: local.cdlExp, cfsqltype: "cf_sql_timestamp", null: !local.hasCdlExp },
				cdlType: { value: local.cdlType, cfsqltype: "cf_sql_varchar", null: !Len(local.cdlType) },
				cdlRest: { value: local.cdlRestriction, cfsqltype: "cf_sql_varchar", null: !Len(local.cdlRestriction) },
				wasEmp: { value: local.wasEmployed, cfsqltype: "cf_sql_bit" },
				empStart: { value: local.empStart, cfsqltype: "cf_sql_timestamp", null: !local.hasEmpStart },
				empEnd: { value: local.empEnd, cfsqltype: "cf_sql_timestamp", null: !local.hasEmpEnd },
				empDept: { value: local.empDept, cfsqltype: "cf_sql_varchar", null: !Len(local.empDept) },
				hasRel: { value: local.hasRelative, cfsqltype: "cf_sql_bit" },
				relNames: { value: local.relativeNames, cfsqltype: "cf_sql_varchar", null: !Len(local.relativeNames) },
				under18: { value: local.under18, cfsqltype: "cf_sql_bit" },
				hasImm: { value: local.hasImmigration, cfsqltype: "cf_sql_bit" },
				lang1: { value: local.lang1, cfsqltype: "cf_sql_varchar", null: !Len(local.lang1) },
				prof1: { value: local.prof1, cfsqltype: "cf_sql_varchar", null: !Len(local.prof1) },
				lang2: { value: local.lang2, cfsqltype: "cf_sql_varchar", null: !Len(local.lang2) },
				prof2: { value: local.prof2, cfsqltype: "cf_sql_varchar", null: !Len(local.prof2) },
				lang3: { value: local.lang3, cfsqltype: "cf_sql_varchar", null: !Len(local.lang3) },
				prof3: { value: local.prof3, cfsqltype: "cf_sql_varchar", null: !Len(local.prof3) },
				hasGed: { value: local.hasGED, cfsqltype: "cf_sql_bit" },
				highGrade: { value: local.highestGrade, cfsqltype: "cf_sql_varchar", null: !Len(local.highestGrade) },
				edu1: { value: local.edu1, cfsqltype: "cf_sql_varchar", null: !Len(local.edu1) },
				deg1: { value: local.deg1, cfsqltype: "cf_sql_varchar", null: !Len(local.deg1) },
				date1: { value: local.date1, cfsqltype: "cf_sql_varchar", null: !Len(local.date1) },
				edu2: { value: local.edu2, cfsqltype: "cf_sql_varchar", null: !Len(local.edu2) },
				deg2: { value: local.deg2, cfsqltype: "cf_sql_varchar", null: !Len(local.deg2) },
				date2: { value: local.date2, cfsqltype: "cf_sql_varchar", null: !Len(local.date2) },
				edu3: { value: local.edu3, cfsqltype: "cf_sql_varchar", null: !Len(local.edu3) },
				deg3: { value: local.deg3, cfsqltype: "cf_sql_varchar", null: !Len(local.deg3) },
				date3: { value: local.date3, cfsqltype: "cf_sql_varchar", null: !Len(local.date3) },
				edu4: { value: local.edu4, cfsqltype: "cf_sql_varchar", null: !Len(local.edu4) },
				deg4: { value: local.deg4, cfsqltype: "cf_sql_varchar", null: !Len(local.deg4) },
				date4: { value: local.date4, cfsqltype: "cf_sql_varchar", null: !Len(local.date4) },
				we1: { value: local.workEmp1, cfsqltype: "cf_sql_varchar", null: !Len(local.workEmp1) },
				wp1: { value: local.workPhone1, cfsqltype: "cf_sql_varchar", null: !Len(local.workPhone1) },
				ws1: { value: local.workStart1, cfsqltype: "cf_sql_varchar", null: !Len(local.workStart1) },
				weEnd1: { value: local.workEnd1, cfsqltype: "cf_sql_varchar", null: !Len(local.workEnd1) },
				wr1: { value: local.workReason1, cfsqltype: "cf_sql_longvarchar", null: !Len(local.workReason1) },
				we2: { value: local.workEmp2, cfsqltype: "cf_sql_varchar", null: !Len(local.workEmp2) },
				wp2: { value: local.workPhone2, cfsqltype: "cf_sql_varchar", null: !Len(local.workPhone2) },
				ws2: { value: local.workStart2, cfsqltype: "cf_sql_varchar", null: !Len(local.workStart2) },
				weEnd2: { value: local.workEnd2, cfsqltype: "cf_sql_varchar", null: !Len(local.workEnd2) },
				wr2: { value: local.workReason2, cfsqltype: "cf_sql_longvarchar", null: !Len(local.workReason2) },
				we3: { value: local.workEmp3, cfsqltype: "cf_sql_varchar", null: !Len(local.workEmp3) },
				wp3: { value: local.workPhone3, cfsqltype: "cf_sql_varchar", null: !Len(local.workPhone3) },
				ws3: { value: local.workStart3, cfsqltype: "cf_sql_varchar", null: !Len(local.workStart3) },
				weEnd3: { value: local.workEnd3, cfsqltype: "cf_sql_varchar", null: !Len(local.workEnd3) },
				wr3: { value: local.workReason3, cfsqltype: "cf_sql_longvarchar", null: !Len(local.workReason3) },
				rn1: { value: local.refName1, cfsqltype: "cf_sql_varchar", null: !Len(local.refName1) },
				re1: { value: local.refEmail1, cfsqltype: "cf_sql_varchar", null: !Len(local.refEmail1) },
				rp1: { value: local.refPhone1, cfsqltype: "cf_sql_varchar", null: !Len(local.refPhone1) },
				rn2: { value: local.refName2, cfsqltype: "cf_sql_varchar", null: !Len(local.refName2) },
				re2: { value: local.refEmail2, cfsqltype: "cf_sql_varchar", null: !Len(local.refEmail2) },
				rp2: { value: local.refPhone2, cfsqltype: "cf_sql_varchar", null: !Len(local.refPhone2) },
				rn3: { value: local.refName3, cfsqltype: "cf_sql_varchar", null: !Len(local.refName3) },
				re3: { value: local.refEmail3, cfsqltype: "cf_sql_varchar", null: !Len(local.refEmail3) },
				rp3: { value: local.refPhone3, cfsqltype: "cf_sql_varchar", null: !Len(local.refPhone3) },
				cert: { value: local.certification, cfsqltype: "cf_sql_bit" },
				sig: { value: local.signature, cfsqltype: "cf_sql_varchar" }
			}, { datasource: "ChelanCountyWebsite" });

			fxRenderJson({
				success: true,
				applicationId: local.insRes.newId,
				message: "Thank you! Your employment application for " & local.position & " has been submitted successfully to Chelan County Human Resources."
			});
		} catch (any e) {
			fxRenderJson({ success: false, message: "Error submitting application: " & e.message }, 500);
		}
	}

	// ----------------------------------------------------
	// Helpers
	// ----------------------------------------------------

	private array function getDepartmentsList() {
		local.depts = [];
		try {
			local.q = queryExecute("
				SELECT code, name, badge_class FROM cms_workspaces WHERE is_active = 1 ORDER BY sort_order ASC, name ASC
			", {}, { datasource: "ChelanCountyWebsite" });
			for (local.r in local.q) {
				ArrayAppend(local.depts, {
					code: local.r.code,
					name: local.r.name,
					badge_class: local.r.badge_class ?: "badge-neutral"
				});
			}
		} catch (any e) {
			local.depts = [
				{ code: "hrm", name: "Human Resources Management", badge_class: "badge-purple" },
				{ code: "pw", name: "Public Works", badge_class: "badge-warning" },
				{ code: "sheriff", name: "Sheriff's Office", badge_class: "badge-danger" },
				{ code: "commdev", name: "Community Development", badge_class: "badge-info" },
				{ code: "auditor", name: "Auditor", badge_class: "badge-primary" },
				{ code: "assessors", name: "Assessor", badge_class: "badge-neutral" }
			];
		}
		return local.depts;
	}

	private struct function getJobMetrics(string siteId = "all") {
		local.m = { total: 0, active: 0, scheduled: 0, draft: 0, closed: 0, total_applications: 0, new_applications: 0 };
		local.whereClause = " WHERE DeletedAt IS NULL ";
		local.p = {};
		if (arguments.siteId != "all" && Len(arguments.siteId)) {
			local.whereClause &= " AND LOWER(SiteID) = :siteId ";
			local.p.siteId = { value: arguments.siteId, cfsqltype: "cf_sql_varchar" };
		}
		try {
			local.q = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					COUNT(*) AS total,
					SUM(CASE WHEN StatusCode = 'Active' THEN 1 ELSE 0 END) AS active,
					SUM(CASE WHEN StatusCode = 'Scheduled' THEN 1 ELSE 0 END) AS scheduled,
					SUM(CASE WHEN StatusCode = 'Draft' THEN 1 ELSE 0 END) AS draft,
					SUM(CASE WHEN StatusCode = 'Closed' THEN 1 ELSE 0 END) AS closed
				FROM job_listings #local.whereClause#
			", local.p, { datasource: "ChelanCountyWebsite" });

			local.qApps = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT 
					COUNT(*) AS total_apps,
					SUM(CASE WHEN Status = 'New' THEN 1 ELSE 0 END) AS new_apps
				FROM job_applications 
				WHERE DeletedAt IS NULL
			", {}, { datasource: "ChelanCountyWebsite" });

			local.m.total = Val(local.q.total);
			local.m.active = Val(local.q.active);
			local.m.scheduled = Val(local.q.scheduled);
			local.m.draft = Val(local.q.draft);
			local.m.closed = Val(local.q.closed);
			local.m.total_applications = Val(local.qApps.total_apps);
			local.m.new_applications = Val(local.qApps.new_apps);
		} catch (any e) {
			// keep defaults
		}
		return local.m;
	}

	private struct function getApplicationMetrics(numeric jobId = 0) {
		local.m = { total: 0, new_apps: 0, reviewing: 0, interview: 0, hired: 0 };
		local.where = " WHERE DeletedAt IS NULL ";
		local.p = {};
		if (arguments.jobId > 0) {
			local.where &= " AND JobID = :jobId ";
			local.p.jobId = { value: arguments.jobId, cfsqltype: "cf_sql_integer" };
		}
		try {
			local.q = queryExecute("
				SELECT 
					COUNT(*) AS total,
					SUM(CASE WHEN Status = 'New' THEN 1 ELSE 0 END) AS new_apps,
					SUM(CASE WHEN Status IN ('Under Review', 'Reviewing') THEN 1 ELSE 0 END) AS reviewing,
					SUM(CASE WHEN Status = 'Interview' THEN 1 ELSE 0 END) AS interview,
					SUM(CASE WHEN Status = 'Hired' THEN 1 ELSE 0 END) AS hired
				FROM job_applications #local.where#
			", local.p, { datasource: "ChelanCountyWebsite" });
			local.m.total = Val(local.q.total);
			local.m.new_apps = Val(local.q.new_apps);
			local.m.reviewing = Val(local.q.reviewing);
			local.m.interview = Val(local.q.interview);
			local.m.hired = Val(local.q.hired);
		} catch (any e) {
			// defaults
		}
		return local.m;
	}

	private string function generateNextClassCode() {
		local.year = Year(Now());
		local.prefix = "REQ-" & local.year & "-";
		try {
			local.q = queryExecute("
				SELECT TOP 1 ClassCode FROM job_listings 
				WHERE ClassCode LIKE :p 
				ORDER BY JobID DESC
			", { p: { value: local.prefix & "%", cfsqltype: "cf_sql_varchar" } }, { datasource: "ChelanCountyWebsite" });

			if (local.q.recordCount && Len(local.q.ClassCode)) {
				local.numPart = Val(ListLast(local.q.ClassCode, "-"));
				return local.prefix & NumberFormat(local.numPart + 1, "000");
			}
		} catch (any e) {
			// fallback
		}
		return local.prefix & "001";
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
		return "HR Administrator";
	}

	private any function fxReadJsonBody() {
		local.raw = GetHttpRequestData().content ?: "";
		if (IsBinary(local.raw)) {
			local.raw = CharsetEncode(local.raw, "utf-8");
		}
		if (IsSimpleValue(local.raw) && IsJSON(local.raw)) {
			return healUtf8MojibakeData(DeserializeJSON(healUtf8Mojibake(local.raw)));
		}
		return {};
	}

	private void function fxRenderJson(required any data, numeric status = 200) {
		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		renderText(text=SerializeJSON(arguments.data), status=arguments.status);
	}

}
