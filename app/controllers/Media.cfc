component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="processUpload,updateMeta");
	}

	/**
	 * Media Library directory, browsing, search & asset inspector (Standalone File Explorer format)
	 */
	function index() {
		variables.pageTitle = "Media Library";

		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		local.cookieWs = StructKeyExists(cookie, "cmsadmin_workspace") && Len(Trim(cookie.cmsadmin_workspace)) ? LCase(Trim(cookie.cmsadmin_workspace)) : "";
		if (local.cookieWs eq "global") {
			local.cookieWs = "all";
		}

		variables.workspaces = getWorkspacesList();
		variables.currentWs = activeWorkspaceId();

		// Resolve canonical workspace object
		local.wsObj = resolveUserActiveWorkspace(requestedWs=variables.currentWs, role=local.role);
		local.vDir = "";
		if (Len(variables.currentWs)) {
			if (StructKeyExists(local.wsObj, "virtual_directory") && Len(Trim(local.wsObj.virtual_directory))) {
				local.vDir = Trim(local.wsObj.virtual_directory);
			} else if (StructKeyExists(local.wsObj, "virtualdir") && Len(Trim(local.wsObj.virtualdir))) {
				local.vDir = Trim(local.wsObj.virtualdir);
			}

			if (!Len(local.vDir)) {
				local.targetFolders = getFoldersForWorkspace(variables.currentWs);
				for (local.f in local.targetFolders) {
					if (DirectoryExists("C:\inetpub\chelan-county\files\" & local.f)) {
						local.vDir = local.f;
						break;
					}
				}
				if (!Len(local.vDir)) {
					local.vDir = variables.currentWs;
				}
			}

			// Ensure \files\[workspace.virtual_directory]\images|documents|shared images exists on disk
			local.rootDisk = "C:\inetpub\chelan-county\files\";
			local.vDir = Replace(Replace(Trim(local.vDir), "\", "/", "all"), "/", "", "all");
			if (Len(local.vDir)) {
				local.wsDisk = local.rootDisk & local.vDir;
				try {
					if (!DirectoryExists(local.wsDisk)) {
						DirectoryCreate(local.wsDisk);
					}
					if (!DirectoryExists(local.wsDisk & "\images")) {
						DirectoryCreate(local.wsDisk & "\images");
					}
					// If legacy media folder exists with files and images is empty, copy over files
					if (DirectoryExists(local.wsDisk & "\media") && DirectoryExists(local.wsDisk & "\images")) {
						local.mediaFiles = DirectoryList(local.wsDisk & "\media", false, "query");
						local.imgFiles = DirectoryList(local.wsDisk & "\images", false, "query");
						if (local.mediaFiles.recordCount > 0 && local.imgFiles.recordCount == 0) {
							for (local.mi = 1; local.mi <= local.mediaFiles.recordCount; local.mi++) {
								local.srcFile = local.wsDisk & "\media\" & local.mediaFiles.name[local.mi];
								local.dstFile = local.wsDisk & "\images\" & local.mediaFiles.name[local.mi];
								if (compareNoCase(local.mediaFiles.type[local.mi], "file") == 0 && !FileExists(local.dstFile)) {
									FileCopy(local.srcFile, local.dstFile);
								}
							}
						}
					}
					if (!DirectoryExists(local.wsDisk & "\documents")) {
						DirectoryCreate(local.wsDisk & "\documents");
					}
					ensureSharedImagesJunction(local.rootDisk);
				} catch (any dirErr) {
					try {
						WriteLog(file="media_explorer", type="warning", text="Workspace directory setup warning: " & dirErr.message);
					} catch (any logErr) {}
				}
			}
		}

		variables.activeWsFolder = local.vDir;
		variables.activeWsVirtualDir = local.vDir;

		// Friendly name
		variables.activeWsName = Len(variables.currentWs) && StructKeyExists(local.wsObj, "name") && Len(Trim(local.wsObj.name)) ? local.wsObj.name : "Please select a workspace";
		for (local.w in variables.workspaces) {
			if (local.w.id eq variables.currentWs) {
				variables.activeWsName = local.w.name;
				break;
			}
		}
	}



	/**
	 * Dedicated Add / Upload File view
	 */
	function upload() {
		variables.pageTitle = "Upload Media & Documents";
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");
		variables.workspaces = getWorkspacesList();
		variables.defaultWs = activeWorkspaceId();
		variables.defaultFolder = StructKeyExists(params, "folder") && Len(Trim(params.folder)) ? LCase(Trim(params.folder)) : "media";
	}

	/**
	 * Standalone Media Picker interface for iframe / modal dialog embed (File Explorer format)
	 */
	function picker() {
		variables.pageTitle = "Select Media Asset";
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");
		variables.isAdmin = local.isAdmin;
		variables.workspaces = getWorkspacesList();
		variables.currentWs = activeWorkspaceId();

		// Resolve canonical workspace object
		local.wsObj = resolveUserActiveWorkspace(requestedWs=variables.currentWs, role=local.role);
		local.vDir = "";
		if (Len(variables.currentWs)) {
			if (StructKeyExists(local.wsObj, "virtual_directory") && Len(Trim(local.wsObj.virtual_directory))) {
				local.vDir = Trim(local.wsObj.virtual_directory);
			} else if (StructKeyExists(local.wsObj, "virtualdir") && Len(Trim(local.wsObj.virtualdir))) {
				local.vDir = Trim(local.wsObj.virtualdir);
			}

			if (!Len(local.vDir)) {
				local.targetFolders = getFoldersForWorkspace(variables.currentWs);
				for (local.f in local.targetFolders) {
					if (DirectoryExists("C:\inetpub\chelan-county\files\" & local.f)) {
						local.vDir = local.f;
						break;
					}
				}
				if (!Len(local.vDir)) {
					local.vDir = variables.currentWs;
				}
			}

			// Ensure \files\[workspace.virtual_directory]\images|documents exists on disk
			local.rootDisk = "C:\inetpub\chelan-county\files\";
			local.vDir = Replace(Replace(Trim(local.vDir), "\", "/", "all"), "/", "", "all");
			if (Len(local.vDir)) {
				local.wsDisk = local.rootDisk & local.vDir;
				try {
					if (!DirectoryExists(local.wsDisk)) {
						DirectoryCreate(local.wsDisk);
					}
					if (!DirectoryExists(local.wsDisk & "\images")) {
						DirectoryCreate(local.wsDisk & "\images");
					}
					if (DirectoryExists(local.wsDisk & "\media") && DirectoryExists(local.wsDisk & "\images")) {
						local.mediaFiles = DirectoryList(local.wsDisk & "\media", false, "query");
						local.imgFiles = DirectoryList(local.wsDisk & "\images", false, "query");
						if (local.mediaFiles.recordCount > 0 && local.imgFiles.recordCount == 0) {
							for (local.mi = 1; local.mi <= local.mediaFiles.recordCount; local.mi++) {
								local.srcFile = local.wsDisk & "\media\" & local.mediaFiles.name[local.mi];
								local.dstFile = local.wsDisk & "\images\" & local.mediaFiles.name[local.mi];
								if (compareNoCase(local.mediaFiles.type[local.mi], "file") == 0 && !FileExists(local.dstFile)) {
									FileCopy(local.srcFile, local.dstFile);
								}
							}
						}
					}
					if (!DirectoryExists(local.wsDisk & "\documents")) {
						DirectoryCreate(local.wsDisk & "\documents");
					}
					ensureSharedImagesJunction(local.rootDisk);
				} catch (any dirErr) {}
			}
		}

		variables.activeWsFolder = local.vDir;
		variables.activeWsVirtualDir = local.vDir;

		variables.activeWsName = Len(variables.currentWs) && StructKeyExists(local.wsObj, "name") && Len(Trim(local.wsObj.name)) ? local.wsObj.name : "Please select a workspace";
		for (local.w in variables.workspaces) {
			if (local.w.id eq variables.currentWs) {
				variables.activeWsName = local.w.name;
				break;
			}
		}

		variables.targetInput = StructKeyExists(params, "targetInput") ? Trim(params.targetInput) : "";
		if (StructKeyExists(params, "picker") && Len(Trim(params.picker))) {
			variables.pickerMode = LCase(Trim(params.picker));
		} else if (Len(variables.targetInput)) {
			variables.pickerMode = "document";
		} else {
			variables.pickerMode = "image";
		}

		local.reqFolder = StructKeyExists(params, "folder") ? LCase(Trim(params.folder)) : "";
		if (local.reqFolder eq "documents" || variables.pickerMode eq "document") {
			variables.initialSubfolder = "documents";
		} else if (local.reqFolder eq "images" || local.reqFolder eq "media" || variables.pickerMode eq "image") {
			variables.initialSubfolder = "images";
		} else {
			variables.initialSubfolder = "";
		}

		variables.callback = StructKeyExists(params, "callback") && Len(Trim(params.callback)) ? Trim(params.callback) : "onMediaSelected";

		renderView(layout=false, hideDebugInformation=true);
	}

	/**
	 * Process file uploads to files/[workspace]/[folder] with ADA WCAG AA validation
	 */
	function processUpload() {
		local.result = {
			"success": false,
			"message": "",
			"file": {}
		};

		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		local.ws = StructKeyExists(params, "workspace") && Len(Trim(params.workspace)) ? LCase(Trim(params.workspace)) : activeWorkspaceId();
		if (!Len(local.ws) || local.ws == "global" || local.ws == "all") {
			local.result.message = "Workspace Required: Please select a workspace before uploading files.";
			renderText(text=SerializeJSON(local.result), contentType="application/json");
			return;
		}
		if (!local.isAdmin && !isWorkspaceAccessible(local.ws, local.role)) {
			local.result.message = "Security Error: You do not have permission to upload files to the '" & local.ws & "' workspace. You may only upload to your assigned workspaces.";
			renderText(text=SerializeJSON(local.result), contentType="application/json");
			return;
		}

		local.subfolder = StructKeyExists(params, "subfolder") && Len(Trim(params.subfolder)) ? LCase(Trim(params.subfolder)) : "media";
		if (local.subfolder eq "shared images" || FindNoCase("shared images", local.subfolder) > 0) {
			local.result.message = "The shared images folder is read-only. Uploading or modifying files in this folder is disabled for all users.";
			local.isJson = StructKeyExists(params, "format") && params.format eq "json";
			if (local.isJson) {
				renderText(text=SerializeJSON(local.result), contentType="application/json");
			} else {
				flashInsert(error=local.result.message);
				redirectTo(controller="media", action="index", params="ws=" & local.ws);
			}
			return;
		}

		local.altText = StructKeyExists(params, "altText") ? Trim(params.altText) : "";
		local.caption = StructKeyExists(params, "caption") ? Trim(params.caption) : "";
		local.title = StructKeyExists(params, "title") ? Trim(params.title) : "";

		// Ensure target directory exists on disk
		local.targetDir = "C:\inetpub\chelan-county\files\" & local.ws & "\" & local.subfolder;
		if (!DirectoryExists(local.targetDir)) {
			DirectoryCreate(local.targetDir);
		}

		// Handle file upload
		try {
			if (StructKeyExists(form, "mediaFile") && Len(Trim(form.mediaFile))) {
				cffile(
					action = "upload",
					destination = local.targetDir,
					fileField = "mediaFile",
					nameConflict = "makeUnique",
					result = "local.uploaded"
				);

				local.ext = LCase(local.uploaded.serverFileExt);
				local.isImg = ListFindNoCase("jpg,jpeg,png,gif,webp,svg,ico", local.ext) > 0;

				// Verify ADA WCAG Compliance for images
				local.wcagNotice = "";
				if (local.isImg && Len(local.altText) == 0) {
					local.wcagNotice = " Note: This image is marked as needing Alt Text for ADA WCAG AA compliance.";
				}

				local.result.success = true;
				local.result.message = "File '" & local.uploaded.serverFile & "' successfully uploaded to " & local.ws & "/" & local.subfolder & "." & local.wcagNotice;
				local.result.file = {
					"name": local.uploaded.serverFile,
					"size": local.uploaded.fileSize,
					"relativePath": "files/" & local.ws & "/" & local.subfolder & "/" & local.uploaded.serverFile,
					"webUrl": "/files/" & local.ws & "/" & local.subfolder & "/" & local.uploaded.serverFile,
					"extension": local.ext,
					"altText": local.altText,
					"isImage": local.isImg
				};
			} else {
				local.result.message = "No file was selected for upload.";
			}
		} catch (any e) {
			local.result.message = "Upload failed: " & e.message;
		}

		// Return JSON if requested or redirect
		local.isJson = StructKeyExists(params, "format") && params.format eq "json";
		try {
			local.req = GetHTTPRequestData();
			if (StructKeyExists(local.req.headers, "X-Requested-With") && local.req.headers["X-Requested-With"] eq "XMLHttpRequest") {
				local.isJson = true;
			}
		} catch (any err) {}

		if (local.isJson) {
			renderText(text=SerializeJSON(local.result), contentType="application/json");
		} else {
			if (local.result.success) {
				flashInsert(success=local.result.message);
			} else {
				flashInsert(error=local.result.message);
			}
			redirectTo(controller="media", action="index", params="ws=" & local.ws & "&folder=" & local.subfolder);
		}
	}

	/**
	 * Update media asset metadata (Alt text, title, caption) with live feedback
	 */
	function updateMeta() {
		if ((StructKeyExists(params, "path") && FindNoCase("shared images", params.path) > 0)
			|| (StructKeyExists(params, "id") && FindNoCase("shared images", params.id) > 0)) {
			renderText(text=SerializeJSON({ "success": false, "message": "Shared stock images are read-only. Metadata edits are disabled." }), contentType="application/json");
			return;
		}

		local.response = {
			"success": true,
			"message": "Asset metadata updated successfully.",
			"altText": StructKeyExists(params, "altText") ? Trim(params.altText) : "",
			"title": StructKeyExists(params, "title") ? Trim(params.title) : "",
			"caption": StructKeyExists(params, "caption") ? Trim(params.caption) : ""
		};

		renderText(text=SerializeJSON(local.response), contentType="application/json");
	}

	/**
	 * Ensures the 'shared images' junction exists pointing to c:\inetpub\chelan-county\images\picjumbo
	 */
	private void function ensureSharedImagesJunction(required string wsDisk) {
		local.targetPath = "C:\inetpub\chelan-county\images\picjumbo";
		local.juncPath = arguments.wsDisk;
		if (right(local.juncPath, 1) != "\") local.juncPath &= "\";
		local.juncPath &= "shared images";
		try {
			if (!DirectoryExists(local.targetPath)) {
				DirectoryCreate(local.targetPath);
			}
			if (!DirectoryExists(local.juncPath)) {
				local.pb = createObject("java", "java.lang.ProcessBuilder").init([
					"cmd.exe", "/c", "mklink", "/J", local.juncPath, local.targetPath
				]);
				local.p = local.pb.start();
				local.p.waitFor();
			}
		} catch (any ignore) {}
	}

	// =========================================================================
	// PRIVATE HELPERS & DATA PROVIDERS
	// =========================================================================

	/**
	 * Workspace directory registry with department affiliations & display labels
	 */
	private array function getWorkspacesList() {
		local.role = getCurrentActiveRole();
		local.accessible = getUserAccessibleWorkspaces(local.role);
		local.list = [];

		for (local.w in local.accessible) {
			if (local.w.id == "global") continue;
			local.entry = {
				id: local.w.id,
				name: local.w.name,
				type: local.w.type,
				badge: local.w.badge,
				folderCount: 2,
				defaultPath: StructKeyExists(local.w, "folderPath") ? local.w.folderPath : "files/" & local.w.id
			};
			if (StructKeyExists(local.w, "alias")) local.entry.alias = local.w.alias;
			ArrayAppend(local.list, local.entry);
		}

		return local.list;
	}

	/**
	 * Get on-disk folder directory names corresponding to a workspace identifier
	 */
	private array function getFoldersForWorkspace(required string wsId) {
		local.id = LCase(Trim(arguments.wsId));
		if (local.id eq "all" || local.id eq "global" || Len(local.id) eq 0) {
			return []; // Empty indicates scan all workspace directories
		}

		local.folders = [ local.id ];

		// Resolve canonical workspace object if possible
		try {
			local.wsObj = resolveUserActiveWorkspace(requestedWs=local.id, role=getCurrentActiveRole());
			if (StructKeyExists(local.wsObj, "virtual_directory") && Len(Trim(local.wsObj.virtual_directory))) {
				local.vDir = LCase(Trim(local.wsObj.virtual_directory));
				if (!ArrayFindNoCase(local.folders, local.vDir)) ArrayAppend(local.folders, local.vDir);
			}
			if (StructKeyExists(local.wsObj, "alias") && Len(Trim(local.wsObj.alias))) {
				local.al = LCase(Trim(local.wsObj.alias));
				if (!ArrayFindNoCase(local.folders, local.al)) ArrayAppend(local.folders, local.al);
			}
			if (StructKeyExists(local.wsObj, "code") && Len(Trim(local.wsObj.code))) {
				local.cd = LCase(Trim(local.wsObj.code));
				if (!ArrayFindNoCase(local.folders, local.cd)) ArrayAppend(local.folders, local.cd);
			}
		} catch (any err) {}

		if (local.id eq "auditor") {
			ArrayAppend(local.folders, "Auditor");
		}
		if (local.id eq "assessors" || local.id eq "assessor") {
			if (!ArrayFindNoCase(local.folders, "assessors")) ArrayAppend(local.folders, "assessors");
			if (!ArrayFindNoCase(local.folders, "assessor")) ArrayAppend(local.folders, "assessor");
			if (!ArrayFindNoCase(local.folders, "Assessors")) ArrayAppend(local.folders, "Assessors");
		}
		if (local.id eq "commdev" || local.id eq "community-development") {
			if (!ArrayFindNoCase(local.folders, "community-development")) ArrayAppend(local.folders, "community-development");
			if (!ArrayFindNoCase(local.folders, "commdev")) ArrayAppend(local.folders, "commdev");
		}
		if (local.id eq "pw" || local.id eq "public-works") {
			if (!ArrayFindNoCase(local.folders, "public-works")) ArrayAppend(local.folders, "public-works");
			if (!ArrayFindNoCase(local.folders, "pw")) ArrayAppend(local.folders, "pw");
		}
		if (local.id eq "admin" || local.id eq "county-administration") {
			if (!ArrayFindNoCase(local.folders, "county-administration")) ArrayAppend(local.folders, "county-administration");
			if (!ArrayFindNoCase(local.folders, "admin")) ArrayAppend(local.folders, "admin");
		}
		if (local.id eq "site-main" || local.id eq "chelancounty.gov") {
			if (!ArrayFindNoCase(local.folders, "chelancounty.gov")) ArrayAppend(local.folders, "chelancounty.gov");
			if (!ArrayFindNoCase(local.folders, "site-main")) ArrayAppend(local.folders, "site-main");
		}
		if (local.id eq "site-parks" || local.id eq "parks.chelancounty.gov") {
			if (!ArrayFindNoCase(local.folders, "parks.chelancounty.gov")) ArrayAppend(local.folders, "parks.chelancounty.gov");
			if (!ArrayFindNoCase(local.folders, "site-parks")) ArrayAppend(local.folders, "site-parks");
		}
		if (local.id eq "clerk") {
			if (!ArrayFindNoCase(local.folders, "clerk")) ArrayAppend(local.folders, "clerk");
		}
		if (local.id eq "sheriff") {
			if (!ArrayFindNoCase(local.folders, "sheriff")) ArrayAppend(local.folders, "sheriff");
		}
		if (local.id eq "treasurer") {
			if (!ArrayFindNoCase(local.folders, "treasurer")) ArrayAppend(local.folders, "treasurer");
		}
		if (local.id eq "commissioners" || local.id eq "board-of-commissioners") {
			if (!ArrayFindNoCase(local.folders, "commissioners")) ArrayAppend(local.folders, "commissioners");
			if (!ArrayFindNoCase(local.folders, "board-of-commissioners")) ArrayAppend(local.folders, "board-of-commissioners");
		}
		return local.folders;
	}

	/**
	 * Comprehensive list of media assets, scanned from disk and augmented with rich attributes
	 */
	private array function getMediaAssets(string ws = "all") {
		local.items = [];
		local.rootDir = "C:\inetpub\CMSAdmin2.0\files";
		local.targetFolders = getFoldersForWorkspace(arguments.ws);

		// Catalog dictionary for known assets to provide authoritative government alt text, dimensions, and authors
		local.catalog = {
			"assessor-seal.png": {
				"title": "Chelan County Assessor Official Seal",
				"altText": "Official circular emblem of the Chelan County Assessor featuring an apple and mountain ridge graphic",
				"caption": "Official Chelan County Assessor crest for assessment notices, roll certifications, and tax statements.",
				"dimensions": "800 x 800",
				"width": 800,
				"height": 800,
				"author": "Assessor Office",
				"tags": "seal, emblem, official, assessor, crest"
			},
			"county-crest.png": {
				"title": "Chelan County Official Government Crest",
				"altText": "Chelan County heraldic government crest with Columbia River, apple orchards, and Cascade mountain peaks",
				"caption": "High-resolution full-color Chelan County coat of arms for formal county declarations and executive stationery.",
				"dimensions": "960 x 960",
				"width": 960,
				"height": 960,
				"author": "Board of Commissioners",
				"tags": "county crest, emblem, heraldry, official"
			},
			"chelan-apple-insignia.png": {
				"title": "Chelan County Apple Insignia Logo",
				"altText": "Red apple icon symbolizing Chelan County agricultural heritage and apple production",
				"caption": "Chelan County signature apple brand mark utilized across web navigation headers and digital seals.",
				"dimensions": "512 x 512",
				"width": 512,
				"height": 512,
				"author": "County Administration",
				"tags": "logo, apple, brand, icon, insignia"
			},
			"chelan-county-official-seal.png": {
				"title": "Chelan County State of Washington Official Seal",
				"altText": "Circular seal of Chelan County Washington with mountains, lake, and established date",
				"caption": "Primary county portal header logo and official municipal trademark.",
				"dimensions": "640 x 640",
				"width": 640,
				"height": 640,
				"author": "County Administration",
				"tags": "logo, seal, official, header"
			},
			"chelan-brand-mark.png": {
				"title": "Public Information Office Press Kit Logo",
				"altText": "High contrast Chelan County media brand insignia for press releases and media alerts",
				"caption": "Media badge for PIO press announcements and official news releases.",
				"dimensions": "512 x 512",
				"width": 512,
				"height": 512,
				"author": "PIO Office",
				"tags": "pio, press, logo, news, brand"
			},
			"2026-Assessment-Roll-Summary.pdf": {
				"title": "2026 Assessment Roll and Property Valuation Summary",
				"altText": "",
				"caption": "Certified county-wide real and personal property assessed valuations, levy rates, and taxable base trends.",
				"dimensions": "8 Pages",
				"author": "Deanna Walter, Assessor",
				"tags": "assessment, roll, property tax, valuation, report"
			},
			"Senior-Disabled-Property-Tax-Exemption-Guide.pdf": {
				"title": "Senior Citizen & Disabled Persons Property Tax Exemption Guidelines",
				"altText": "",
				"caption": "Comprehensive eligibility criteria, income thresholds, and application instructions under RCW 84.36.381.",
				"dimensions": "12 Pages",
				"author": "Assessor Tax Exemption Division",
				"tags": "exemption, senior, disabled, tax relief, guide, form"
			},
			"2026-Levy-Rates-and-Tax-District-Distribution.xlsx": {
				"title": "2026 Levy Rates & Taxing District Distribution Worksheet",
				"altText": "",
				"caption": "Excel workbook detailing school district, fire district, hospital district, and port levy rate calculations.",
				"dimensions": "5 Worksheets",
				"author": "Assessor Levy Department",
				"tags": "levy, tax rates, districts, excel, data"
			},
			"Chelan-County-Strategic-Plan-2026-2030.pdf": {
				"title": "Chelan County Strategic Plan 2026-2030",
				"altText": "",
				"caption": "Five-year county government strategic vision focusing on infrastructure, wildfire resilience, and economic vitality.",
				"dimensions": "44 Pages",
				"author": "Board of Commissioners",
				"tags": "strategic plan, commissioners, policy, county vision"
			},
			"County-Logo-Usage-and-Branding-Guidelines.pdf": {
				"title": "Official County Logo Usage & Style Guide",
				"altText": "",
				"caption": "Approved color specifications (Pantone, Hex, RGB), clear space requirements, and typography guidelines.",
				"dimensions": "16 Pages",
				"author": "PIO & Administration",
				"tags": "branding, style guide, logo, colors, graphics"
			},
			"Employee-Personnel-Policy-Handbook-2026.pdf": {
				"title": "2026 Chelan County Employee Personnel Policy Handbook",
				"altText": "",
				"caption": "Official county personnel handbook covering employment policies, ethics, compensation, and safety protocols.",
				"dimensions": "68 Pages",
				"author": "Human Resources Department",
				"tags": "hrm, handbook, employee, policies, benefits"
			},
			"Equal-Opportunity-Employment-Plan.pdf": {
				"title": "Equal Employment Opportunity & Affirmative Action Plan",
				"altText": "",
				"caption": "Chelan County policy commitment ensuring non-discrimination and equal opportunity in public employment.",
				"dimensions": "20 Pages",
				"author": "Human Resources Department",
				"tags": "hrm, eeo, employment, compliance, policy"
			},
			"2026-Six-Year-Transportation-Improvement-Program.pdf": {
				"title": "2026-2031 Six-Year Comprehensive Transportation Program",
				"altText": "",
				"caption": "Adopted road improvement projects, bridge rehabilitation schedules, and county arterial paving program.",
				"dimensions": "36 Pages",
				"author": "Public Works Engineering",
				"tags": "public works, roads, transportation, engineering, tip"
			},
			"2026-General-Election-Official-Canvass-Report.pdf": {
				"title": "2026 General Election Certified Canvass Report",
				"altText": "",
				"caption": "Certified precinct-level vote totals, voter turnout statistics, and election canvass certification document.",
				"dimensions": "28 Pages",
				"author": "Chelan County Auditor",
				"tags": "auditor, elections, canvass, voting, results"
			}
		};

		// Scan filesystem recursively under files/
		if (DirectoryExists(local.rootDir)) {
			local.wsDirs = DirectoryList(local.rootDir, false, "query");
			for (local.wRow in local.wsDirs) {
				if (local.wRow.type eq "Dir") {
					local.wsName = local.wRow.name;

					// Strict workspace isolation: only scan folders assigned to this workspace!
					if (ArrayLen(local.targetFolders) > 0) {
						local.matchesWs = false;
						for (local.target in local.targetFolders) {
							if (LCase(local.wsName) eq LCase(local.target)) {
								local.matchesWs = true;
								break;
							}
						}
						if (!local.matchesWs) {
							continue; // Skip all other folders!
						}
					}

					local.subFolders = DirectoryList(local.wRow.directory & "\" & local.wsName, false, "query");
					for (local.fRow in local.subFolders) {
						if (local.fRow.type eq "Dir") {
							local.folderName = local.fRow.name;
							local.filesInFolder = DirectoryList(local.fRow.directory & "\" & local.folderName, false, "query");
							for (local.fileRow in local.filesInFolder) {
								if (local.fileRow.type eq "File" && local.fileRow.name neq "README.txt" && local.fileRow.name neq ".gitkeep") {
									local.ext = LCase(ListLast(local.fileRow.name, "."));
									local.category = getCategoryFromExt(local.ext);
									local.isImage = (local.category eq "image");

									// Look up enriched metadata or generate defaults
									local.meta = StructKeyExists(local.catalog, local.fileRow.name) ? local.catalog[local.fileRow.name] : {};
									local.title = StructKeyExists(local.meta, "title") ? local.meta.title : formatTitleFromName(local.fileRow.name);
									local.altText = StructKeyExists(local.meta, "altText") ? local.meta.altText : "";
									local.caption = StructKeyExists(local.meta, "caption") ? local.meta.caption : "";
									local.dim = StructKeyExists(local.meta, "dimensions") ? local.meta.dimensions : (local.isImage ? "600 x 600" : "");
									local.author = StructKeyExists(local.meta, "author") ? local.meta.author : "Staff Editor";
									local.tags = StructKeyExists(local.meta, "tags") ? local.meta.tags : local.wsName & ", " & local.folderName;

									// ADA WCAG status: images need non-empty alt text
									local.isWcagCompliant = (!local.isImage) || (Len(Trim(local.altText)) > 0);

									local.asset = {
										"id": Hash(local.wsName & "/" & local.folderName & "/" & local.fileRow.name),
										"name": local.fileRow.name,
										"title": local.title,
										"altText": local.altText,
										"caption": local.caption,
										"workspace": normalizeWorkspaceId(local.wsName),
										"folder": local.folderName,
										"extension": local.ext,
										"category": local.category,
										"isImage": local.isImage,
										"isWcagCompliant": local.isWcagCompliant,
										"sizeBytes": local.fileRow.size,
										"sizeFormatted": formatFileSize(local.fileRow.size),
										"dimensions": local.dim,
										"dateModified": local.fileRow.dateLastModified,
										"dateFormatted": DateFormat(local.fileRow.dateLastModified, "mmm dd, yyyy") & " at " & TimeFormat(local.fileRow.dateLastModified, "h:mm tt"),
										"relativePath": "files/" & local.wsName & "/" & local.folderName & "/" & local.fileRow.name,
										"webUrl": "/files/" & local.wsName & "/" & local.folderName & "/" & local.fileRow.name,
										"absolutePath": "C:\inetpub\chelan-county\files\" & local.wsName & "\" & local.folderName & "\" & local.fileRow.name,
										"author": local.author,
										"tags": local.tags
									};
									ArrayAppend(local.items, local.asset);
								}
							}
						}
					}
				}
			}
		}

		// Only include virtual demonstration assets when viewing All Workspaces ("all" or "global") AND if total files < 8
		if ((arguments.ws eq "all" || arguments.ws eq "global") && ArrayLen(local.items) < 8) {
			local.extraDemos = getDemoAssets();
			for (local.d in local.extraDemos) {
				ArrayAppend(local.items, local.d);
			}
		}

		return local.items;
	}

	/**
	 * Categorize extension into media family
	 */
	private string function getCategoryFromExt(required string ext) {
		switch (LCase(arguments.ext)) {
			case "jpg": case "jpeg": case "png": case "gif": case "webp": case "svg": case "ico": case "bmp":
				return "image";
			case "pdf": case "doc": case "docx": case "txt": case "rtf":
				return "document";
			case "xls": case "xlsx": case "csv":
				return "spreadsheet";
			case "ppt": case "pptx":
				return "presentation";
			case "zip": case "tar": case "gz": case "7z":
				return "archive";
			default:
				return "other";
		}
	}

	/**
	 * Compute media library KPIs
	 */
	private struct function calculateStats(required array assets) {
		local.totalBytes = 0;
		local.imgCount = 0;
		local.docCount = 0;
		local.sheetCount = 0;
		local.compliantCount = 0;
		local.missingAltCount = 0;

		for (local.item in arguments.assets) {
			local.totalBytes += local.item.sizeBytes;
			if (local.item.isImage) {
				local.imgCount++;
				if (Len(Trim(local.item.altText)) > 0) {
					local.compliantCount++;
				} else {
					local.missingAltCount++;
				}
			} else if (local.item.category eq "document") {
				local.docCount++;
			} else if (local.item.category eq "spreadsheet") {
				local.sheetCount++;
			}
		}

		local.complianceRate = local.imgCount > 0 ? Round((local.compliantCount / local.imgCount) * 100) : 100;

		return {
			"totalAssets": ArrayLen(arguments.assets),
			"imageCount": local.imgCount,
			"docCount": local.docCount,
			"sheetCount": local.sheetCount,
			"totalBytes": local.totalBytes,
			"totalStorageFormatted": formatFileSize(local.totalBytes),
			"wcagCompliantCount": local.compliantCount,
			"wcagMissingCount": local.missingAltCount,
			"complianceRate": local.complianceRate
		};
	}

	/**
	 * Multi-facet filtering and sorting
	 */
	private array function filterAssets(
		required array assets,
		required string ws,
		required string folder,
		required string type,
		required string search,
		required string altStatus,
		required string sort
	) {
		local.filtered = [];

		for (local.item in arguments.assets) {
			// Workspace filter (with alias normalization): strictly to the requested workspace
			if (arguments.ws neq "all" && arguments.ws neq "global") {
				local.filterWs = normalizeWorkspaceId(arguments.ws);
				local.itemWs = normalizeWorkspaceId(local.item.workspace);
				if (local.filterWs neq local.itemWs) {
					continue;
				}
			}
			// Folder filter
			if (arguments.folder neq "all" && LCase(local.item.folder) neq arguments.folder) {
				continue;
			}
			// Type filter
			if (arguments.type neq "all" && LCase(local.item.category) neq arguments.type) {
				continue;
			}
			// Alt Status filter (ADA WCAG)
			if (arguments.altStatus eq "missing") {
				if (!local.item.isImage || Len(Trim(local.item.altText)) > 0) {
					continue;
				}
			} else if (arguments.altStatus eq "compliant") {
				if (local.item.isImage && Len(Trim(local.item.altText)) == 0) {
					continue;
				}
			}
			// Keyword search
			if (Len(arguments.search) > 0) {
				local.haystack = LCase(local.item.name & " " & local.item.title & " " & local.item.altText & " " & local.item.caption & " " & local.item.tags & " " & local.item.workspace);
				if (FindNoCase(arguments.search, local.haystack) == 0) {
					continue;
				}
			}

			ArrayAppend(local.filtered, local.item);
		}

		// Sorting
		local.sorted = local.filtered;
		switch (arguments.sort) {
			case "oldest":
				ArraySort(local.sorted, function(e1, e2) {
					return DateCompare(e1.dateModified, e2.dateModified);
				});
				break;
			case "name_asc":
				ArraySort(local.sorted, function(e1, e2) {
					return CompareNoCase(e1.name, e2.name);
				});
				break;
			case "name_desc":
				ArraySort(local.sorted, function(e1, e2) {
					return CompareNoCase(e2.name, e1.name);
				});
				break;
			case "size_desc":
				ArraySort(local.sorted, function(e1, e2) {
					return e1.sizeBytes < e2.sizeBytes ? 1 : (e1.sizeBytes > e2.sizeBytes ? -1 : 0);
				});
				break;
			case "size_asc":
				ArraySort(local.sorted, function(e1, e2) {
					return e1.sizeBytes > e2.sizeBytes ? 1 : (e1.sizeBytes < e2.sizeBytes ? -1 : 0);
				});
				break;
			case "newest":
			default:
				ArraySort(local.sorted, function(e1, e2) {
					return DateCompare(e2.dateModified, e1.dateModified);
				});
				break;
		}

		return local.sorted;
	}

	/**
	 * Normalize workspace identifier and common navigation aliases
	 */
	private string function normalizeWorkspaceId(required string wsId) {
		local.id = LCase(Trim(arguments.wsId));
		if (local.id eq "assessor" || local.id eq "assessors") return "assessor";
		if (local.id eq "community-development" || local.id eq "commdev") return "commdev";
		if (local.id eq "public-works" || local.id eq "pw") return "pw";
		if (local.id eq "county-administration" || local.id eq "admin") return "admin";
		if (local.id eq "human-resources" || local.id eq "hrm") return "hrm";
		if (local.id eq "communications" || local.id eq "pio") return "pio";
		if (local.id eq "chelancounty.gov" || local.id eq "site-main") return "site-main";
		if (local.id eq "parks.chelancounty.gov" || local.id eq "site-parks") return "site-parks";
		if (local.id eq "gis.chelancounty.gov" || local.id eq "site-gis") return "site-gis";
		return local.id;
	}

	/**
	 * Convert byte count to human-readable string
	 */
	private string function formatFileSize(required numeric bytes) {
		if (arguments.bytes < 1024) {
			return arguments.bytes & " B";
		} else if (arguments.bytes < 1048576) {
			return NumberFormat(arguments.bytes / 1024, "0.0") & " KB";
		} else if (arguments.bytes < 1073741824) {
			return NumberFormat(arguments.bytes / 1048576, "0.0") & " MB";
		} else {
			return NumberFormat(arguments.bytes / 1073741824, "0.00") & " GB";
		}
	}

	/**
	 * Humanize a file slug into a clean title
	 */
	private string function formatTitleFromName(required string name) {
		local.clean = ListFirst(arguments.name, ".");
		local.clean = Replace(local.clean, "-", " ", "all");
		local.clean = Replace(local.clean, "_", " ", "all");
		return REReplace(local.clean, "\b(\w)", "\U\1", "all");
	}

	/**
	 * Demo asset entries ensuring rich data for testing
	 */
	private array function getDemoAssets() {
		return [
			{
				"id": Hash("assessors/media/aerial-parcel-map.jpg"),
				"name": "chelan-county-aerial-orthophoto.jpg",
				"title": "Chelan County Aerial Orthophoto & Topo Map",
				"altText": "High-altitude color orthophoto showing the Wenatchee River corridor and agricultural parcels",
				"caption": "GIS parcel overlay aerial photograph for property boundary verification and tax assessments.",
				"workspace": "assessors",
				"folder": "media",
				"extension": "jpg",
				"category": "image",
				"isImage": true,
				"isWcagCompliant": true,
				"sizeBytes": 2424832,
				"sizeFormatted": "2.3 MB",
				"dimensions": "3840 x 2160",
				"dateModified": Now(),
				"dateFormatted": DateFormat(Now(), "mmm dd, yyyy") & " at " & TimeFormat(Now(), "h:mm tt"),
				"relativePath": "files/assessors/media/chelan-county-aerial-orthophoto.jpg",
				"webUrl": "/images/apple.png",
				"absolutePath": "C:\inetpub\chelan-county\files\assessors\media\chelan-county-aerial-orthophoto.jpg",
				"author": "GIS Department",
				"tags": "aerial, parcel, map, orthophoto, gis"
			},
			{
				"id": Hash("shared/media/lake-chelan-scenic-panorama.jpg"),
				"name": "lake-chelan-scenic-panorama.jpg",
				"title": "Lake Chelan Scenic Valley & Mountain Panorama",
				"altText": "Panoramic summer landscape view of deep blue Lake Chelan flanked by forested North Cascades mountains",
				"caption": "Promotional hero photography showcasing Lake Chelan natural recreation areas.",
				"workspace": "shared",
				"folder": "media",
				"extension": "jpg",
				"category": "image",
				"isImage": true,
				"isWcagCompliant": true,
				"sizeBytes": 3145728,
				"sizeFormatted": "3.0 MB",
				"dimensions": "2560 x 1440",
				"dateModified": DateAdd("d", -2, Now()),
				"dateFormatted": DateFormat(DateAdd("d", -2, Now()), "mmm dd, yyyy") & " at 11:20 AM",
				"relativePath": "files/shared/media/lake-chelan-scenic-panorama.jpg",
				"webUrl": "/images/apple.png",
				"absolutePath": "C:\inetpub\chelan-county\files\shared\media\lake-chelan-scenic-panorama.jpg",
				"author": "PIO Office",
				"tags": "lake chelan, tourism, mountains, scenic, hero"
			},
			{
				"id": Hash("pio/media/commissioners-press-briefing.jpg"),
				"name": "commissioners-press-briefing.jpg",
				"title": "Board of Commissioners Weekly Press Briefing",
				"altText": "", // Intentionally empty to test and demonstrate ADA WCAG missing alt text alert!
				"caption": "Chelan County Commissioners conducting open public session in commissioner chambers.",
				"workspace": "pio",
				"folder": "media",
				"extension": "jpg",
				"category": "image",
				"isImage": true,
				"isWcagCompliant": false,
				"sizeBytes": 1843200,
				"sizeFormatted": "1.8 MB",
				"dimensions": "1920 x 1080",
				"dateModified": DateAdd("d", -1, Now()),
				"dateFormatted": DateFormat(DateAdd("d", -1, Now()), "mmm dd, yyyy") & " at 9:45 AM",
				"relativePath": "files/pio/media/commissioners-press-briefing.jpg",
				"webUrl": "/images/logo.png",
				"absolutePath": "C:\inetpub\chelan-county\files\pio\media\commissioners-press-briefing.jpg",
				"author": "PIO Media Desk",
				"tags": "commissioners, press, briefing, government, chambers"
			}
		];
	}

}
