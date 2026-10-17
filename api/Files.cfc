component output="false" hint="Remote JSON API for the standalone File Explorer. All file-system work happens here." {

	// ==================================================================
	// Remote methods
	// Paths travel as forward-slash strings relative to the files root,
	// e.g. "public-works/documents/agendas" ("" = root).
	// Errors: HTTP 200 + { "ok": false, "error": "..." }. No stack traces.
	// ==================================================================

	remote struct function ping(string ws = "", any _ = "", any reinit = "") returnformat="json" {
		noCache();
		local.cfg = getConfig();
		return {
			"ok"          : true,
			"server"      : local.cfg.serverName,
			"time"        : dateFormat(now(), "yyyy-mm-dd") & "T" & timeFormat(now(), "HH:mm:ss"),
			"filesRoot"   : local.cfg.filesRoot,
			"webBase"     : local.cfg.webBase,
			"systemDepth" : local.cfg.systemDepth,
			"maxNameLen"  : local.cfg.maxNameLen
		};
	}

	remote struct function list(string path = "", string ws = "", any _ = "") returnformat="json" {
		noCache();
		try {
			local.cfg = getConfig();
			local.cleanWs = trim(arguments.ws);

			// If ws is specified, restrict navigation strictly inside the workspace, or to shared images
			local.reqPath = trim(arguments.path);
			ensureSharedImagesJunction(local.cfg.filesRoot);

			if (len(local.cleanWs)) {
				// Ensure \files\[workspace.virtual_directory]\images and documents exist
				local.wsDisk = local.cfg.filesRoot & local.cleanWs;
				try {
					if (!directoryExists(local.wsDisk)) directoryCreate(local.wsDisk);
					if (!directoryExists(local.wsDisk & "\images")) directoryCreate(local.wsDisk & "\images");
					if (!directoryExists(local.wsDisk & "\documents")) directoryCreate(local.wsDisk & "\documents");
				} catch (any dirErr) {}

				local.isSharedImagesReq = (compareNoCase(local.reqPath, "shared images") == 0 || left(local.reqPath, 14) == "shared images/");
				if (!len(local.reqPath) || (!local.isSharedImagesReq && local.reqPath neq local.cleanWs && left(local.reqPath, len(local.cleanWs) + 1) neq local.cleanWs & "/")) {
					local.reqPath = local.cleanWs;
				}
			}

			local.target = resolvePath(local.reqPath);

			if (!directoryExists(local.target.abs)) {
				return fail("That folder does not exist.");
			}

			local.isSharedImages = (FindNoCase("shared images", local.target.rel) > 0);

			// --- items in the current folder (folders first, then files) ---
			local.q     = readDir(local.target.abs);
			local.dirs  = [];
			local.files = [];

			for (local.i = 1; local.i <= local.q.recordCount; local.i++) {
				local.name = toString(local.q.name[local.i]);
				if (left(local.name, 1) == ".") continue;
				if (local.target.depth == 1 && compareNoCase(local.name, "media") == 0) continue;

				local.item = {
					"name"     : javaCast("string", local.name),
					"modified" : fmtDate(local.q.dateLastModified[local.i])
				};

				if (compareNoCase(local.q.type[local.i], "dir") == 0) {
					local.counts = countChildren(local.target.abs & "\" & local.name);
					local.item["type"]  = "dir";
					local.item["dirs"]  = local.counts.dirs;
					local.item["files"] = local.counts.files;
					if (compareNoCase(local.name, "shared images") == 0) {
						local.item["isShared"]   = true;
						local.item["isReadOnly"] = true;
						local.item["label"]      = "Shared Images";
					}
					arrayAppend(local.dirs, local.item);
				} else {
					local.item["type"] = "file";
					local.item["size"] = val(local.q.size[local.i]);
					local.item["ext"]  = (find(".", local.name) ? lCase(listLast(local.name, ".")) : "");
					if (local.isSharedImages) {
						local.item["isReadOnly"] = true;
					}
					arrayAppend(local.files, local.item);
				}
			}

			// Sort directories: images, documents, shared images, then alphabetical
			arraySort(local.dirs, function(a, b) {
				local.orderA = (compareNoCase(a.name, "images") == 0 || compareNoCase(a.name, "media") == 0 ? 1 : (compareNoCase(a.name, "documents") == 0 ? 2 : (compareNoCase(a.name, "shared images") == 0 ? 3 : 99)));
				local.orderB = (compareNoCase(b.name, "images") == 0 || compareNoCase(b.name, "media") == 0 ? 1 : (compareNoCase(b.name, "documents") == 0 ? 2 : (compareNoCase(b.name, "shared images") == 0 ? 3 : 99)));
				if (local.orderA != local.orderB) return local.orderA < local.orderB ? -1 : 1;
				return compareNoCase(a.name, b.name);
			});

			local.items = local.dirs;
			for (local.f in local.files) arrayAppend(local.items, local.f);

			local.cfg = getConfig();
			// --- branches: one per level from root down to the current folder ---
			local.branches = [];
			local.prefix   = [];
			for (local.lvl = 0; local.lvl <= local.target.depth; local.lvl++) {
				if (local.lvl > 0) arrayAppend(local.prefix, local.target.segments[local.lvl]);
				local.relPath = arrayToList(local.prefix, "/");
				local.absPath = local.cfg.filesRoot & arrayToList(local.prefix, "\");

				local.levelDirs = subDirNames(local.absPath);
				// If workspace filtering is active, at root level only show this workspace!
				if (local.lvl == 0 && len(local.cleanWs)) {
					local.filteredDirs = [];
					for (local.dName in local.levelDirs) {
						if (compareNoCase(local.dName, local.cleanWs) == 0) {
							arrayAppend(local.filteredDirs, local.dName);
						}
					}
					// If the target folder is on disk, ensure it appears
					if (arrayLen(local.filteredDirs) == 0 && directoryExists(local.cfg.filesRoot & local.cleanWs)) {
						arrayAppend(local.filteredDirs, javaCast("string", local.cleanWs));
					}
					local.levelDirs = local.filteredDirs;
				}

				arrayAppend(local.branches, {
					"path" : javaCast("string", local.relPath),
					"dirs" : local.levelDirs
				});
			}

			// --- full folder tree for active workspace (left panel hierarchy) ---
			local.tree = {};
			if (len(local.cleanWs)) {
				local.wsRootAbs = local.cfg.filesRoot & local.cleanWs;
				if (directoryExists(local.wsRootAbs)) {
					local.wsCounts = countChildren(local.wsRootAbs);
					local.tree = {
						"name"     : javaCast("string", local.cleanWs),
						"path"     : javaCast("string", local.cleanWs),
						"dirs"     : local.wsCounts.dirs,
						"files"    : local.wsCounts.files,
						"count"    : (local.wsCounts.dirs + local.wsCounts.files),
						"children" : buildFolderTree(local.wsRootAbs, local.cleanWs)
					};
				}
			}

			// --- shared stock photography library (outside workspace folder) ---
			local.sharedTree = {};
			local.sharedRootAbs = local.cfg.filesRoot & "shared images";
			if (directoryExists(local.sharedRootAbs)) {
				local.shCounts = countChildren(local.sharedRootAbs);
				local.sharedTree = {
					"name"       : "Shared Images",
					"path"       : "shared images",
					"dirs"       : local.shCounts.dirs,
					"files"      : local.shCounts.files,
					"count"      : (local.shCounts.dirs + local.shCounts.files),
					"isShared"   : true,
					"isReadOnly" : true,
					"children"   : buildFolderTree(local.sharedRootAbs, "shared images")
				};
			}

			return {
				"ok"         : true,
				"path"       : javaCast("string", local.target.rel),
				"depth"      : local.target.depth,
				"canCreate"  : (local.target.depth >= local.cfg.systemDepth && !local.isSharedImages),
				"canDelete"  : (local.target.depth > local.cfg.systemDepth && !local.isSharedImages),
				"isReadOnly" : local.isSharedImages,
				"diskPath"   : diskPathOf(local.target.segments, true),
				"webPath"    : webPathOf(local.target.rel, true),
				"webBase"    : local.cfg.webBase,
				"filesRoot"  : local.cfg.filesRoot,
				"ws"         : javaCast("string", local.cleanWs),
				"branches"   : local.branches,
				"tree"       : local.tree,
				"sharedTree" : local.sharedTree,
				"items"      : local.items
			};
		} catch (any e) {
			return handleError(e);
		}
	}

	remote struct function createFolder(string path = "", string name = "", string ws = "", any _ = "") returnformat="json" {
		noCache();
		try {
			requirePost();
			local.cfg = getConfig();

			local.cleanWs = trim(arguments.ws);
			if (len(local.cleanWs)) {
				if (arguments.path neq local.cleanWs && left(arguments.path, len(local.cleanWs) + 1) neq local.cleanWs & "/") {
					return fail("Folders can only be created inside your active workspace.");
				}
			}

			if (FindNoCase("shared images", arguments.path) > 0) {
				return fail("The shared images folder is read-only. Adding subfolders is not permitted for any user.");
			}

			local.parent = resolvePath(arguments.path);

			if (local.parent.depth < local.cfg.systemDepth) {
				return fail("Folders can only be created inside a workspace's images or documents folder (or below).");
			}
			if (!directoryExists(local.parent.abs)) {
				return fail("The parent folder does not exist.");
			}

			local.name  = arguments.name;
			local.error = validateName(local.name);
			if (len(local.error)) return fail(local.error);

			// Duplicate check, case-insensitive, against files and folders.
			local.q = readDir(local.parent.abs);
			for (local.i = 1; local.i <= local.q.recordCount; local.i++) {
				if (compareNoCase(toString(local.q.name[local.i]), local.name) == 0) {
					return fail("An item named """ & local.q.name[local.i] & """ already exists here.");
				}
			}

			local.newSegments = duplicate(local.parent.segments);
			arrayAppend(local.newSegments, local.name);
			local.newRel = arrayToList(local.newSegments, "/");

			// Re-run the full safety check on the final path before touching disk.
			local.target = resolvePath(local.newRel);
			if (directoryExists(local.target.abs) || fileExists(local.target.abs)) {
				return fail("An item with that name already exists here.");
			}

			directoryCreate(local.target.abs);

			return {
				"ok"       : true,
				"path"     : javaCast("string", local.target.rel),
				"diskPath" : diskPathOf(local.target.segments, true)
			};
		} catch (any e) {
			return handleError(e);
		}
	}

	remote struct function deleteFolder(string path = "", string ws = "", any _ = "") returnformat="json" {
		noCache();
		try {
			requirePost();
			local.cfg = getConfig();

			local.cleanWs = trim(arguments.ws);
			if (len(local.cleanWs)) {
				if (arguments.path neq local.cleanWs && left(arguments.path, len(local.cleanWs) + 1) neq local.cleanWs & "/") {
					return fail("Folders can only be deleted inside your active workspace.");
				}
			}

			if (FindNoCase("shared images", arguments.path) > 0) {
				return fail("The shared images folder is read-only and cannot be modified or deleted.");
			}

			local.target = resolvePath(arguments.path);

			if (local.target.depth <= local.cfg.systemDepth) {
				return fail("This is a protected folder and cannot be deleted.");
			}
			if (!directoryExists(local.target.abs)) {
				return fail("That folder does not exist.");
			}
			// Empty means truly empty, including hidden entries.
			if (arrayLen(directoryList(local.target.abs, false, "name"))) {
				return fail("Only empty folders can be deleted. Remove its contents first.");
			}

			directoryDelete(local.target.abs, false);   // never recursive

			return { "ok" : true };
		} catch (any e) {
			return handleError(e);
		}
	}

	// ==================================================================
	// Path safety
	// ==================================================================

	/**
	 * Validates a relative path and returns
	 * { abs, rel, segments, depth }. Throws FX.User on anything unsafe.
	 */
	private struct function resolvePath(string path = "") {
		local.p = replace(trim(arguments.path), "\", "/", "all");

		// Tolerate a single leading/trailing slash; anything else empty is rejected.
		if (left(local.p, 1) == "/")  local.p = mid(local.p, 2, len(local.p));
		if (right(local.p, 1) == "/") local.p = left(local.p, len(local.p) - 1);

		local.segments = [];
		if (len(local.p)) {
			local.parts = listToArray(local.p, "/", true);
			for (local.seg in local.parts) {
				if (local.seg == "" || local.seg == "." || local.seg == "..") {
					userError("Invalid path.");
				}
				if (reFind('[:*?"<>|]', local.seg) || reFind("[[:cntrl:]]", local.seg)) {
					userError("Invalid path.");
				}
				if (left(local.seg, 1) == ".") {
					userError("Invalid path.");
				}
				arrayAppend(local.segments, local.seg);
			}
		}

		local.cfg = getConfig();
		local.root = local.cfg.filesRoot;
		local.abs  = local.root & arrayToList(local.segments, "\");
		if (right(local.abs, 1) == "\") local.abs = left(local.abs, len(local.abs) - 1);

		local.rootCanon = canonical(local.root);
		local.absCanon  = canonical(local.abs);
		local.picjumboCanon = canonical("C:\inetpub\chelan-county\images\picjumbo");

		local.isRootSafe = (compareNoCase(local.absCanon, local.rootCanon) == 0
			|| compareNoCase(left(local.absCanon, len(local.rootCanon) + 1), local.rootCanon & "\") == 0);
		local.isPicjumboSafe = (compareNoCase(local.absCanon, local.picjumboCanon) == 0
			|| compareNoCase(left(local.absCanon, len(local.picjumboCanon) + 1), local.picjumboCanon & "\") == 0);

		if (!local.isRootSafe && !local.isPicjumboSafe) {
			userError("Invalid path.");
		}

		return {
			"abs"      : local.abs,
			"rel"      : arrayToList(local.segments, "/"),
			"segments" : local.segments,
			"depth"    : arrayLen(local.segments)
		};
	}

	private string function canonical(required string p) {
		local.c = createObject("java", "java.io.File").init(arguments.p).getCanonicalPath();
		if (len(local.c) > 3 && right(local.c, 1) == "\") local.c = left(local.c, len(local.c) - 1);
		return local.c;
	}

	// ==================================================================
	// Folder-name validation (mirrored in assets/js/explorer.js)
	// Returns "" when valid, otherwise a human-readable message.
	// ==================================================================
	private string function validateName(string name = "") {
		local.n   = arguments.name;
		local.cfg = getConfig();
		local.max = local.cfg.maxNameLen;

		if (!len(local.n)) return "Enter a folder name.";
		if (len(local.n) > local.max) return "Folder names can be at most " & local.max & " characters.";
		if (!reFind("^[A-Za-z0-9][A-Za-z0-9 _.\-]*$", local.n)) {
			return "Use letters, numbers, spaces, dots, hyphens and underscores, starting with a letter or number.";
		}
		if (right(local.n, 1) == "." || right(local.n, 1) == " ") {
			return "Folder names cannot end with a dot or a space.";
		}
		if (reFindNoCase("^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$", local.n)) {
			return """" & local.n & """ is a reserved Windows name.";
		}
		return "";
	}

	// ==================================================================
	// Helpers
	// ==================================================================
	private query function readDir(required string abs) {
		return directoryList(arguments.abs, false, "query", "", "name asc");
	}

	private array function subDirNames(required string abs) {
		local.out = [];
		if (!directoryExists(arguments.abs)) return local.out;
		local.q = readDir(arguments.abs);
		for (local.i = 1; local.i <= local.q.recordCount; local.i++) {
			local.n = toString(local.q.name[local.i]);
			if (left(local.n, 1) == ".") continue;
			if (compareNoCase(local.q.type[local.i], "dir") == 0) {
				arrayAppend(local.out, javaCast("string", local.n));
			}
		}
		return local.out;
	}

	private array function buildFolderTree(required string absPath, required string relPath) {
		local.out = [];
		if (!directoryExists(arguments.absPath)) return local.out;

		local.q = readDir(arguments.absPath);
		for (local.i = 1; local.i <= local.q.recordCount; local.i++) {
			local.n = toString(local.q.name[local.i]);
			if (left(local.n, 1) == "." || compareNoCase(local.n, "media") == 0) continue;
			if (compareNoCase(local.q.type[local.i], "dir") == 0) {
				local.childAbs = arguments.absPath & "\" & local.n;
				local.childRel = len(arguments.relPath) ? arguments.relPath & "/" & local.n : local.n;
				local.counts   = countChildren(local.childAbs);

				local.isSharedNode = (compareNoCase(local.n, "shared images") == 0);
				local.node = {
					"name"       : javaCast("string", local.n),
					"path"       : javaCast("string", local.childRel),
					"dirs"       : local.counts.dirs,
					"files"      : local.counts.files,
					"count"      : (local.counts.dirs + local.counts.files),
					"isShared"   : local.isSharedNode,
					"isReadOnly" : local.isSharedNode,
					"children"   : buildFolderTree(local.childAbs, local.childRel)
				};
				arrayAppend(local.out, local.node);
			}
		}

		// Sort: put images/media first, documents second, shared images third; otherwise alphabetical
		arraySort(local.out, function(a, b) {
			local.orderA = (compareNoCase(a.name, "images") == 0 || compareNoCase(a.name, "media") == 0 ? 1 : (compareNoCase(a.name, "documents") == 0 ? 2 : (compareNoCase(a.name, "shared images") == 0 ? 3 : 99)));
			local.orderB = (compareNoCase(b.name, "images") == 0 || compareNoCase(b.name, "media") == 0 ? 1 : (compareNoCase(b.name, "documents") == 0 ? 2 : (compareNoCase(b.name, "shared images") == 0 ? 3 : 99)));
			if (local.orderA != local.orderB) return local.orderA < local.orderB ? -1 : 1;
			return compareNoCase(a.name, b.name);
		});

		return local.out;
	}

	private struct function countChildren(required string abs) {
		local.res = { "dirs" : 0, "files" : 0 };
		try {
			local.q = readDir(arguments.abs);
			for (local.i = 1; local.i <= local.q.recordCount; local.i++) {
				if (left(local.q.name[local.i], 1) == ".") continue;
				if (compareNoCase(local.q.type[local.i], "dir") == 0) {
					local.res.dirs++;
				} else {
					local.res.files++;
				}
			}
		} catch (any e) {
			// unreadable folder: report zero counts rather than failing the listing
		}
		return local.res;
	}

	private string function fmtDate(any d) {
		if (!isDate(arguments.d)) return "";
		return dateFormat(arguments.d, "mmm d, yyyy") & " " & timeFormat(arguments.d, "h:mm tt");
	}

	private string function diskPathOf(required array segments, boolean trailing = true) {
		local.cfg = getConfig();
		local.p = local.cfg.filesRoot & arrayToList(arguments.segments, "\");
		if (arguments.trailing && right(local.p, 1) != "\") local.p &= "\";
		return local.p;
	}

	private string function webPathOf(required string rel, boolean trailing = true) {
		local.cfg = getConfig();
		local.p = local.cfg.webBase & arguments.rel;
		if (arguments.trailing && right(local.p, 1) != "/") local.p &= "/";
		return local.p;
	}

	private void function requirePost() {
		if (compareNoCase(cgi.request_method, "POST") != 0) {
			userError("This action requires an HTTP POST.");
		}
		// Light CSRF guard: cross-site forms cannot set custom headers.
		local.h = getPageContext().getRequest().getHeader("X-Requested-With");
		if (isNull(local.h) || compareNoCase(local.h, "FileExplorer") != 0) {
			userError("Request rejected (missing X-Requested-With header).");
		}
	}

	private void function noCache() {
		local.r = getPageContext().getResponse();
		local.r.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
		local.r.setHeader("Pragma", "no-cache");
		local.r.setHeader("X-Content-Type-Options", "nosniff");
	}

	private void function userError(required string message) {
		throw(type = "FX.User", message = arguments.message);
	}

	private struct function fail(required string message) {
		return { "ok" : false, "error" : arguments.message };
	}

	private struct function getConfig() {
		if (!structKeyExists(application, "fx")) {
			local.cfg = {
				"filesRoot"   : "C:\inetpub\chelan-county\files\",
				"webBase"     : "/files/",
				"serverName"  : "WEB-01",
				"systemDepth" : 2,
				"maxNameLen"  : 64,
				"allowedIPs"  : "*"
			};
			local.cfg.filesRoot = replace(local.cfg.filesRoot, "/", "\", "all");
			if (right(local.cfg.filesRoot, 1) != "\") local.cfg.filesRoot &= "\";
			if (right(local.cfg.webBase, 1) != "/") local.cfg.webBase &= "/";
			application.fx = local.cfg;
		}
		return application.fx;
	}

	private struct function handleError(required any e) {
		if (structKeyExists(arguments.e, "type") && arguments.e.type == "FX.User") {
			return fail(arguments.e.message);
		}
		try {
			writeLog(file = "filexplorer", type = "error",
				text = arguments.e.message & " | " & (structKeyExists(arguments.e, "detail") ? arguments.e.detail : ""));
		} catch (any ignore) {}
		return fail("The server could not complete that request.");
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
			if (!directoryExists(local.targetPath)) {
				directoryCreate(local.targetPath);
			}
			if (!directoryExists(local.juncPath)) {
				local.pb = createObject("java", "java.lang.ProcessBuilder").init([
					"cmd.exe", "/c", "mklink", "/J", local.juncPath, local.targetPath
				]);
				local.p = local.pb.start();
				local.p.waitFor();
			}
		} catch (any ignore) {}
	}
}

