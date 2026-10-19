component extends="Controller" {

	function config() {
		super.config();
		protectsFromForgery(except="processUpload,updateMeta");
	}

	/**
	 * Media Library directory, browsing, search & asset inspector (Standalone File Explorer format)
	 */
	function index() {
		ensureMediaAssetsSchema();
		syncDiskAssetsToDatabase();
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
		ensureMediaAssetsSchema();
		syncDiskAssetsToDatabase();
		variables.pageTitle = "Upload Media & Documents";
		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");
		variables.workspaces = getWorkspacesList();
		variables.defaultWs = activeWorkspaceId();
		if (!Len(variables.defaultWs) || variables.defaultWs eq "global" || variables.defaultWs eq "all") {
			variables.defaultWs = ArrayLen(variables.workspaces) > 0 ? variables.workspaces[1].id : "assessors";
		}
		variables.defaultFolder = StructKeyExists(params, "folder") && Len(Trim(params.folder)) ? LCase(Trim(params.folder)) : "images";

		// Recent uploads for display
		variables.recentUploads = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT TOP 12 id, site_id, folder, filename, file_path, web_url, file_size, file_ext, file_hash,
			       title, alt_text, caption, credit, is_image, is_wcag_compliant, width, height, created_at
			FROM dbo.media_assets
			WHERE deletedat IS NULL
			ORDER BY created_at DESC
		", {}, { datasource: "ChelanCountyWebsite" });

		// Media Statistics
		variables.mediaStats = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT COUNT(*) AS total_assets,
			       SUM(CASE WHEN is_image = 1 THEN 1 ELSE 0 END) AS total_images,
			       SUM(CASE WHEN is_image = 0 THEN 1 ELSE 0 END) AS total_documents,
			       SUM(CASE WHEN is_image = 1 AND (alt_text IS NOT NULL AND LEN(LTRIM(RTRIM(alt_text))) > 0) THEN 1 ELSE 0 END) AS wcag_compliant_images,
			       SUM(CASE WHEN is_image = 1 AND (alt_text IS NULL OR LEN(LTRIM(RTRIM(alt_text))) = 0) THEN 1 ELSE 0 END) AS needs_alt_images
			FROM dbo.media_assets
			WHERE deletedat IS NULL
		", {}, { datasource: "ChelanCountyWebsite" });
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
	 * Process file uploads to files/[workspace]/[folder] with ADA WCAG AA validation and SQL Server persistence
	 */
	function processUpload() {
		ensureMediaAssetsSchema();

		local.result = {
			"success": false,
			"message": "",
			"file": {}
		};

		local.role = getCurrentActiveRole();
		local.isAdmin = (local.role eq "admin");

		local.ws = StructKeyExists(params, "workspace") && Len(Trim(params.workspace)) ? LCase(Trim(params.workspace)) : "";
		local.subfolder = StructKeyExists(params, "subfolder") && Len(Trim(params.subfolder)) ? LCase(Trim(params.subfolder)) : "";

		// If full path like 'assessor/images' or 'community-development/documents' was passed
		if (StructKeyExists(params, "path") && Len(Trim(params.path))) {
			local.cleanP = Replace(Trim(params.path), "\", "/", "all");
			local.pathParts = ListToArray(local.cleanP, "/");
			if (ArrayLen(local.pathParts) >= 1 && !Len(local.ws)) {
				local.ws = LCase(local.pathParts[1]);
			}
			if (ArrayLen(local.pathParts) >= 2 && !Len(local.subfolder)) {
				local.subfolder = LCase(local.pathParts[2]);
			}
		}

		if (!Len(local.ws)) {
			local.ws = activeWorkspaceId();
		}
		if (!Len(local.subfolder)) {
			local.subfolder = "images";
		}
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

		local.altText = StructKeyExists(params, "altText") ? Trim(params.altText) : (StructKeyExists(params, "alt_text") ? Trim(params.alt_text) : "");
		local.caption = StructKeyExists(params, "caption") ? Trim(params.caption) : "";
		local.title = StructKeyExists(params, "title") ? Trim(params.title) : "";
		local.credit = StructKeyExists(params, "credit") ? Trim(params.credit) : "";
		local.tags = StructKeyExists(params, "tags") ? Trim(params.tags) : "";

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
				local.disallowed = "cfm,cfc,exe,bat,cmd,vbs,ps1,sh,jsp,asp,aspx,dll,com,scr,pif";
				if (ListFindNoCase(local.disallowed, local.ext) > 0) {
					try {
						FileDelete(local.targetDir & "\" & local.uploaded.serverFile);
					} catch (any delErr) {}
					local.result.message = "Security Violation: Executable file types (." & local.ext & ") are strictly forbidden from upload.";
					if (StructKeyExists(params, "format") && params.format eq "json") {
						renderText(text=SerializeJSON(local.result), contentType="application/json");
						return;
					}
					flashInsert(error=local.result.message);
					redirectTo(controller="media", action="upload", params="ws=" & local.ws);
					return;
				}

				local.uploadedPath = local.targetDir & "\" & local.uploaded.serverFile;
				local.bytes = FileReadBinary(local.uploadedPath);
				local.fileHash = LCase(Hash(local.bytes, "SHA-256"));
				local.isImg = ListFindNoCase("jpg,jpeg,png,gif,webp,svg,ico,bmp", local.ext) > 0;

				// SHA-256 Deduplication check
				local.dupAsset = queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					SELECT TOP 1 id, site_id, folder, filename, file_path, web_url, title
					FROM dbo.media_assets
					WHERE file_hash = :hash AND deletedat IS NULL
				", {
					hash: { value: local.fileHash, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.dupWarning = "";
				if (local.dupAsset.recordCount > 0) {
					local.dupWarning = " (Note: Identical file already exists at '" & local.dupAsset.file_path & "' [SHA-256: " & Left(local.fileHash, 12) & "...])";
				}

				// Compute image dimensions
				local.width = "";
				local.height = "";
				if (local.isImg && ListFindNoCase("jpg,jpeg,png,gif,bmp", local.ext) > 0) {
					try {
						local.cfImg = ImageRead(local.uploadedPath);
						local.imgInfo = ImageInfo(local.cfImg);
						local.width = local.imgInfo.width;
						local.height = local.imgInfo.height;
					} catch (any imgErr) {}
				}

				// Auto-format title if empty
				if (!Len(local.title)) {
					local.title = formatTitleFromName(local.uploaded.serverFile);
				}

				local.isDecorative = StructKeyExists(params, "isDecorative") && (params.isDecorative eq 1 || params.isDecorative eq "true" || params.isDecorative eq "yes");

				// ADA WCAG 2.1 AA Compliance Requirement (WCAG 1.1.1):
				// Alternative Text is mandatory for all images under Chelan County ADA policy.
				if (local.isImg && !local.isDecorative && Len(Trim(local.altText)) eq 0) {
					try {
						FileDelete(local.uploadedPath);
					} catch (any delErr) {}
					local.result.message = "ADA WCAG 2.1 AA Compliance Violation: Alternative Text (Image Description) is required for all images under County policy (WCAG 1.1.1). Please provide a description for screen readers and try again.";
					if (StructKeyExists(params, "format") && params.format eq "json") {
						renderText(text=SerializeJSON(local.result), contentType="application/json");
						return;
					}
					flashInsert(error=local.result.message);
					redirectTo(controller="media", action="upload", params="ws=" & local.ws);
					return;
				}

				// Check for generic or filename placeholder alt text (WCAG 1.1.1 Warning / Guidance)
				local.lowerAlt = LCase(Trim(local.altText));
				local.genericWords = "image,photo,picture,graphic,img,pic,file,screenshot";
				if (local.isImg && !local.isDecorative && (ListFindNoCase(local.genericWords, local.lowerAlt) > 0 || Right(local.lowerAlt, 4) eq ".jpg" || Right(local.lowerAlt, 4) eq ".png" || Right(local.lowerAlt, 5) eq ".webp")) {
					try {
						FileDelete(local.uploadedPath);
					} catch (any delErr) {}
					local.result.message = "ADA WCAG 2.1 AA Violation: Generic alternative text ('" & local.altText & "') or filenames are not permitted. Please describe the actual visual contents or purpose of the image for assistive technologies.";
					if (StructKeyExists(params, "format") && params.format eq "json") {
						renderText(text=SerializeJSON(local.result), contentType="application/json");
						return;
					}
					flashInsert(error=local.result.message);
					redirectTo(controller="media", action="upload", params="ws=" & local.ws);
					return;
				}

				// Verify ADA WCAG Compliance for images (WCAG 1.1.1)
				local.isWcagCompliant = (!local.isImg) || local.isDecorative || (Len(Trim(local.altText)) > 0);
				local.wcagNotice = "";

				local.mime = StructKeyExists(local.uploaded, "contentType") && StructKeyExists(local.uploaded, "contentSubType")
					? (local.uploaded.contentType & "/" & local.uploaded.contentSubType) : "";
				local.relPath = "files/" & local.ws & "/" & local.subfolder & "/" & local.uploaded.serverFile;
				local.webUrl = "/files/" & local.ws & "/" & local.subfolder & "/" & local.uploaded.serverFile;
				local.userEmail = StructKeyExists(session, "user") && StructKeyExists(session.user, "email")
					? session.user.email : (StructKeyExists(session, "username") ? session.username : "admin");

				// Persist into dbo.media_assets
				queryExecute("
					SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
					INSERT INTO dbo.media_assets (
						site_id, folder, filename, file_path, web_url,
						file_size, file_ext, mime_type, file_hash,
						title, alt_text, caption, credit,
						is_image, width, height, is_wcag_compliant, tags,
						created_by, created_at, updated_at
					) VALUES (
						:site_id, :folder, :filename, :file_path, :web_url,
						:file_size, :file_ext, :mime_type, :file_hash,
						:title, :alt_text, :caption, :credit,
						:is_image, :width, :height, :is_wcag_compliant, :tags,
						:created_by, SYSDATETIME(), SYSDATETIME()
					)
				", {
					site_id: { value: local.ws, cfsqltype: "cf_sql_nvarchar" },
					folder: { value: local.subfolder, cfsqltype: "cf_sql_nvarchar" },
					filename: { value: local.uploaded.serverFile, cfsqltype: "cf_sql_nvarchar" },
					file_path: { value: local.relPath, cfsqltype: "cf_sql_nvarchar" },
					web_url: { value: local.webUrl, cfsqltype: "cf_sql_nvarchar" },
					file_size: { value: local.uploaded.fileSize, cfsqltype: "cf_sql_bigint" },
					file_ext: { value: local.ext, cfsqltype: "cf_sql_nvarchar" },
					mime_type: { value: local.mime, cfsqltype: "cf_sql_nvarchar" },
					file_hash: { value: local.fileHash, cfsqltype: "cf_sql_nvarchar" },
					title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
					alt_text: { value: local.altText, cfsqltype: "cf_sql_nvarchar" },
					caption: { value: local.caption, cfsqltype: "cf_sql_nvarchar" },
					credit: { value: local.credit, cfsqltype: "cf_sql_nvarchar" },
					is_image: { value: local.isImg ? 1 : 0, cfsqltype: "cf_sql_bit" },
					width: { value: Val(local.width) > 0 ? Val(local.width) : JavaCast("null", ""), cfsqltype: "cf_sql_integer", null: (Val(local.width) <= 0) },
					height: { value: Val(local.height) > 0 ? Val(local.height) : JavaCast("null", ""), cfsqltype: "cf_sql_integer", null: (Val(local.height) <= 0) },
					is_wcag_compliant: { value: local.isWcagCompliant ? 1 : 0, cfsqltype: "cf_sql_bit" },
					tags: { value: local.tags, cfsqltype: "cf_sql_nvarchar" },
					created_by: { value: local.userEmail, cfsqltype: "cf_sql_nvarchar" }
				}, { datasource: "ChelanCountyWebsite" });

				local.result.success = true;
				local.result.message = "File '" & local.uploaded.serverFile & "' successfully uploaded and registered in media database for " & local.ws & "/" & local.subfolder & "." & local.wcagNotice & local.dupWarning;
				local.result.file = {
					"name": local.uploaded.serverFile,
					"size": local.uploaded.fileSize,
					"relativePath": local.relPath,
					"webUrl": local.webUrl,
					"extension": local.ext,
					"fileHash": local.fileHash,
					"title": local.title,
					"altText": local.altText,
					"caption": local.caption,
					"credit": local.credit,
					"isImage": local.isImg,
					"isWcagCompliant": local.isWcagCompliant
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
			redirectTo(controller="media", action="upload", params="ws=" & local.ws & "&folder=" & local.subfolder);
		}
	}

	/**
	 * Update media asset metadata (Alt text, title, caption, credit, tags) with SQL Server database persistence
	 */
	function updateMeta() {
		if ((StructKeyExists(params, "path") && FindNoCase("shared images", params.path) > 0)
			|| (StructKeyExists(params, "id") && FindNoCase("shared images", params.id) > 0)) {
			renderText(text=SerializeJSON({ "success": false, "message": "Shared stock images are read-only. Metadata edits are disabled." }), contentType="application/json");
			return;
		}

		ensureMediaAssetsSchema();

		local.assetId = StructKeyExists(params, "id") ? Val(params.id) : 0;
		local.path = StructKeyExists(params, "path") ? Trim(params.path) : (StructKeyExists(params, "webUrl") ? Trim(params.webUrl) : "");
		local.altText = StructKeyExists(params, "altText") ? Trim(params.altText) : (StructKeyExists(params, "alt_text") ? Trim(params.alt_text) : "");
		local.title = StructKeyExists(params, "title") ? Trim(params.title) : "";
		local.caption = StructKeyExists(params, "caption") ? Trim(params.caption) : "";
		local.credit = StructKeyExists(params, "credit") ? Trim(params.credit) : "";
		local.tags = StructKeyExists(params, "tags") ? Trim(params.tags) : "";

		local.existing = queryNew("");
		if (local.assetId > 0) {
			local.existing = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 id, site_id, folder, filename, file_path, web_url, is_image, file_hash
				FROM dbo.media_assets
				WHERE id = :id AND deletedat IS NULL
			", { id: { value: local.assetId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" });
		} else if (Len(local.path)) {
			local.normPath = Replace(local.path, "\", "/", "all");
			if (Left(local.normPath, 1) == "/") local.normPath = Mid(local.normPath, 2, Len(local.normPath));
			local.webUrl = "/" & local.normPath;

			local.existing = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 id, site_id, folder, filename, file_path, web_url, is_image, file_hash
				FROM dbo.media_assets
				WHERE (web_url = :web_url OR file_path = :file_path OR filename = :fname) AND deletedat IS NULL
			", {
				web_url: { value: local.webUrl, cfsqltype: "cf_sql_nvarchar" },
				file_path: { value: local.normPath, cfsqltype: "cf_sql_nvarchar" },
				fname: { value: ListLast(local.normPath, "/"), cfsqltype: "cf_sql_nvarchar" }
			}, { datasource: "ChelanCountyWebsite" });
		}

		local.currentUser = StructKeyExists(session, "user") && StructKeyExists(session.user, "email")
			? session.user.email : (StructKeyExists(session, "username") ? session.username : "admin");

		if (local.existing.recordCount > 0) {
			local.isImg = isBoolean(local.existing.is_image) && local.existing.is_image;
			local.isDecorative = StructKeyExists(params, "isDecorative") && (params.isDecorative eq 1 || params.isDecorative eq "true" || params.isDecorative eq "yes");
			if (local.isImg && !local.isDecorative && Len(Trim(local.altText)) eq 0) {
				renderText(text=SerializeJSON({ "success": false, "message": "WCAG 1.1.1 Compliance Violation: Alternative Text (Image Description) cannot be blank for images." }), contentType="application/json");
				return;
			}
			local.isWcag = (!local.isImg) || local.isDecorative || (Len(local.altText) > 0);

			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				UPDATE dbo.media_assets
				SET title = :title,
				    alt_text = :alt_text,
				    caption = :caption,
				    credit = :credit,
				    tags = :tags,
				    is_wcag_compliant = :is_wcag,
				    updated_at = SYSDATETIME(),
				    updated_by = :user
				WHERE id = :id
			", {
				id: { value: local.existing.id, cfsqltype: "cf_sql_integer" },
				title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
				alt_text: { value: local.altText, cfsqltype: "cf_sql_nvarchar" },
				caption: { value: local.caption, cfsqltype: "cf_sql_nvarchar" },
				credit: { value: local.credit, cfsqltype: "cf_sql_nvarchar" },
				tags: { value: local.tags, cfsqltype: "cf_sql_nvarchar" },
				is_wcag: { value: local.isWcag ? 1 : 0, cfsqltype: "cf_sql_bit" },
				user: { value: local.currentUser, cfsqltype: "cf_sql_nvarchar" }
			}, { datasource: "ChelanCountyWebsite" });

			renderText(text=SerializeJSON({
				"success": true,
				"message": "Asset metadata updated successfully in SQL Server database.",
				"id": local.existing.id,
				"title": local.title,
				"altText": local.altText,
				"caption": local.caption,
				"credit": local.credit,
				"isWcagCompliant": local.isWcag
			}), contentType="application/json");
			return;
		}

		renderText(text=SerializeJSON({
			"success": false,
			"message": "Asset record not found in database to update."
		}), contentType="application/json");
	}

	/**
	 * Ensures dbo.media_assets table and indexes exist in ChelanCountyWebsite
	 */
	public void function ensureMediaAssetsSchema() {
		try {
			queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'media_assets')
				BEGIN
					CREATE TABLE dbo.media_assets (
						id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
						site_id NVARCHAR(50) NOT NULL,
						folder NVARCHAR(100) NOT NULL,
						filename NVARCHAR(255) NOT NULL,
						file_path NVARCHAR(500) NOT NULL,
						web_url NVARCHAR(500) NOT NULL,
						file_size BIGINT NOT NULL DEFAULT 0,
						file_ext NVARCHAR(50) NOT NULL,
						mime_type NVARCHAR(100) NULL,
						file_hash NVARCHAR(64) NULL,
						title NVARCHAR(255) NULL,
						alt_text NVARCHAR(1000) NULL,
						caption NVARCHAR(1000) NULL,
						credit NVARCHAR(255) NULL,
						is_image BIT NOT NULL DEFAULT 0,
						width INT NULL,
						height INT NULL,
						is_wcag_compliant BIT NOT NULL DEFAULT 1,
						tags NVARCHAR(500) NULL,
						created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
						created_by NVARCHAR(100) NULL,
						updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
						updated_by NVARCHAR(100) NULL,
						deletedat DATETIME2(0) NULL
					);
				END;

				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_media_assets_site_folder_file' AND object_id = OBJECT_ID('dbo.media_assets'))
				BEGIN
					CREATE UNIQUE NONCLUSTERED INDEX IX_media_assets_site_folder_file
					ON dbo.media_assets (site_id, folder, filename)
					WHERE deletedat IS NULL;
				END;

				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_media_assets_file_hash' AND object_id = OBJECT_ID('dbo.media_assets'))
				BEGIN
					CREATE NONCLUSTERED INDEX IX_media_assets_file_hash
					ON dbo.media_assets (file_hash)
					WHERE deletedat IS NULL AND file_hash IS NOT NULL;
				END;

				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_media_assets_wcag' AND object_id = OBJECT_ID('dbo.media_assets'))
				BEGIN
					CREATE NONCLUSTERED INDEX IX_media_assets_wcag
					ON dbo.media_assets (site_id, is_image, is_wcag_compliant)
					WHERE deletedat IS NULL;
				END;
			", {}, { datasource: "ChelanCountyWebsite" });
		} catch (any e) {}
	}

	/**
	 * Synchronize physical on-disk files under files/ into dbo.media_assets
	 */
	public void function syncDiskAssetsToDatabase() {
		local.rootDir = "C:\inetpub\chelan-county\files\";
		if (!DirectoryExists(local.rootDir)) return;

		local.existingPaths = {};
		try {
			local.qExists = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT file_path, file_hash
				FROM dbo.media_assets
				WHERE deletedat IS NULL
			", {}, { datasource: "ChelanCountyWebsite" });
			for (local.row in local.qExists) {
				local.existingPaths[LCase(Replace(local.row.file_path, "\", "/", "all"))] = local.row.file_hash;
			}
		} catch (any e) {
			return;
		}

		local.wsDirs = DirectoryList(local.rootDir, false, "query");
		for (local.wRow in local.wsDirs) {
			if (local.wRow.type eq "Dir") {
				local.wsName = local.wRow.name;
				local.subFolders = DirectoryList(local.wRow.directory & "\" & local.wsName, false, "query");
				for (local.fRow in local.subFolders) {
					if (local.fRow.type eq "Dir") {
						local.folderName = local.fRow.name;
						local.filesInFolder = DirectoryList(local.fRow.directory & "\" & local.folderName, false, "query");
						for (local.fileRow in local.filesInFolder) {
							if (local.fileRow.type eq "File" && local.fileRow.name neq "README.txt" && local.fileRow.name neq ".gitkeep") {
								local.relPath = "files/" & local.wsName & "/" & local.folderName & "/" & local.fileRow.name;
								local.key = LCase(local.relPath);
								if (!StructKeyExists(local.existingPaths, local.key)) {
									local.fullPath = local.fileRow.directory & "\" & local.fileRow.name;
									try {
										local.fileBytes = FileReadBinary(local.fullPath);
										local.fileHash = LCase(Hash(local.fileBytes, "SHA-256"));
										local.ext = LCase(ListLast(local.fileRow.name, "."));
										local.isImg = ListFindNoCase("jpg,jpeg,png,gif,webp,svg,ico,bmp", local.ext) > 0;
										local.title = formatTitleFromName(local.fileRow.name);
										local.width = "";
										local.height = "";
										if (local.isImg && ListFindNoCase("jpg,jpeg,png,gif,bmp", local.ext) > 0) {
											try {
												local.imgObj = ImageRead(local.fullPath);
												local.iInfo = ImageInfo(local.imgObj);
												local.width = local.iInfo.width;
												local.height = local.iInfo.height;
											} catch (any imgErr) {}
										}
										local.isWcag = (!local.isImg);

										queryExecute("
											SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
											INSERT INTO dbo.media_assets (
												site_id, folder, filename, file_path, web_url,
												file_size, file_ext, file_hash,
												title, alt_text, caption, credit,
												is_image, width, height, is_wcag_compliant, tags,
												created_by, created_at, updated_at
											) VALUES (
												:site_id, :folder, :filename, :file_path, :web_url,
												:file_size, :file_ext, :file_hash,
												:title, '', '', '',
												:is_image, :width, :height, :is_wcag, :tags,
												'System Auto-Sync', SYSDATETIME(), SYSDATETIME()
											)
										", {
											site_id: { value: local.wsName, cfsqltype: "cf_sql_nvarchar" },
											folder: { value: local.folderName, cfsqltype: "cf_sql_nvarchar" },
											filename: { value: local.fileRow.name, cfsqltype: "cf_sql_nvarchar" },
											file_path: { value: local.relPath, cfsqltype: "cf_sql_nvarchar" },
											web_url: { value: "/" & local.relPath, cfsqltype: "cf_sql_nvarchar" },
											file_size: { value: local.fileRow.size, cfsqltype: "cf_sql_bigint" },
											file_ext: { value: local.ext, cfsqltype: "cf_sql_nvarchar" },
											file_hash: { value: local.fileHash, cfsqltype: "cf_sql_nvarchar" },
											title: { value: local.title, cfsqltype: "cf_sql_nvarchar" },
											is_image: { value: local.isImg ? 1 : 0, cfsqltype: "cf_sql_bit" },
											width: { value: Val(local.width) > 0 ? Val(local.width) : JavaCast("null", ""), cfsqltype: "cf_sql_integer", null: (Val(local.width) <= 0) },
											height: { value: Val(local.height) > 0 ? Val(local.height) : JavaCast("null", ""), cfsqltype: "cf_sql_integer", null: (Val(local.height) <= 0) },
											is_wcag: { value: local.isWcag ? 1 : 0, cfsqltype: "cf_sql_bit" },
											tags: { value: local.wsName & ", " & local.folderName, cfsqltype: "cf_sql_nvarchar" }
										}, { datasource: "ChelanCountyWebsite" });

										local.existingPaths[local.key] = local.fileHash;
									} catch (any syncErr) {}
								}
							}
						}
					}
				}
			}
		}
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

		// Query database for persistent media metadata from dbo.media_assets
		local.dbMap = {};
		try {
			local.qAssets = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT id, site_id, folder, filename, file_path, web_url, file_size, file_ext, file_hash,
				       title, alt_text, caption, credit, is_image, width, height, is_wcag_compliant, tags
				FROM dbo.media_assets
				WHERE deletedat IS NULL
			", {}, { datasource: "ChelanCountyWebsite" });
			for (local.a in local.qAssets) {
				local.dbMap[LCase(local.a.filename)] = local.a;
				local.dbMap[LCase(local.a.file_path)] = local.a;
			}
		} catch (any dbErr) {}

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

									// Look up enriched metadata from dbo.media_assets, fallback to catalog or defaults
									local.dbRow = StructKeyExists(local.dbMap, LCase(local.fileRow.name))
										? local.dbMap[LCase(local.fileRow.name)]
										: (StructKeyExists(local.dbMap, LCase("files/" & local.wsName & "/" & local.folderName & "/" & local.fileRow.name))
											? local.dbMap[LCase("files/" & local.wsName & "/" & local.folderName & "/" & local.fileRow.name)]
											: {});
									local.meta = StructKeyExists(local.catalog, local.fileRow.name) ? local.catalog[local.fileRow.name] : {};
									local.title = (StructKeyExists(local.dbRow, "title") && Len(Trim(local.dbRow.title))) ? local.dbRow.title
										: (StructKeyExists(local.meta, "title") ? local.meta.title : formatTitleFromName(local.fileRow.name));
									local.altText = StructKeyExists(local.dbRow, "alt_text") ? local.dbRow.alt_text
										: (StructKeyExists(local.meta, "altText") ? local.meta.altText : "");
									local.caption = StructKeyExists(local.dbRow, "caption") ? local.dbRow.caption
										: (StructKeyExists(local.meta, "caption") ? local.meta.caption : "");
									local.author = (StructKeyExists(local.dbRow, "credit") && Len(Trim(local.dbRow.credit))) ? local.dbRow.credit
										: (StructKeyExists(local.meta, "author") ? local.meta.author : "Staff Editor");
									local.tags = (StructKeyExists(local.dbRow, "tags") && Len(Trim(local.dbRow.tags))) ? local.dbRow.tags
										: (StructKeyExists(local.meta, "tags") ? local.meta.tags : (local.wsName & ", " & local.folderName));
									local.fileHash = StructKeyExists(local.dbRow, "file_hash") ? local.dbRow.file_hash : "";
									local.dim = (StructKeyExists(local.dbRow, "width") && Val(local.dbRow.width) > 0 && StructKeyExists(local.dbRow, "height") && Val(local.dbRow.height) > 0)
										? (local.dbRow.width & " x " & local.dbRow.height)
										: (StructKeyExists(local.meta, "dimensions") ? local.meta.dimensions : (local.isImage ? "600 x 600" : ""));

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
										"fileHash": local.fileHash,
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
