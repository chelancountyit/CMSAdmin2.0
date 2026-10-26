/* ==========================================================================
   CMSAdmin 2.0 - Media Library File Explorer (vanilla JS, ES2017, no deps)
   Scoped to active workspace: /files/[workspace.virtualdir]/
   ========================================================================== */
(function () {
	'use strict';

	var API_URL = '/api/Files.cfc';
	var PING_EVERY_MS = 30000;
	var REQUEST_TIMEOUT_MS = 12000;
	var CONFIRM_MS = 4000;
	var VIEW_KEY = 'fx.viewMode';

	var IMAGE_EXT = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'];
	var WORD_EXT = ['doc', 'docx', 'rtf', 'odt'];
	var EXCEL_EXT = ['xls', 'xlsx', 'csv', 'ods'];

	// ------------------------------------------------------------------
	// State
	// ------------------------------------------------------------------
	var state = {
		cfg: { filesRoot: 'C:\\inetpub\\chelan-county\\files\\', webBase: '/files/', systemDepth: 2, maxNameLen: 64, server: '' },
		ws: '',                // active workspace directory (e.g. "community-development")
		wsName: '',            // friendly display name
		assetsProtocol: 'http',
		assetsDomain: '',
		online: null,          // null = connecting, true, false
		path: '',
		depth: 0,
		data: null,            // last list response
		items: [],             // sorted items
		shown: [],             // filtered items
		selected: null,        // selected item name
		filter: '',
		view: 'grid',
		loadToken: 0,
		armed: null,           // { path, timer } for two-step delete
		pendingNew: false,
		pendingUpload: false,
		loadError: '',
		initialFolder: '',     // optional initial subfolder ("documents" or "images")
		pickerMode: '',        // optional picker mode ("document" or "image")
		pickerCallback: '',    // optional parent window callback name
		targetInput: ''        // optional opener input ID
	};

	// ------------------------------------------------------------------
	// DOM
	// ------------------------------------------------------------------
	var $ = function (id) { return document.getElementById(id); };
	var el = {
		conn: $('conn'), connText: $('conn-text'), banner: $('offline-banner'), retry: $('btn-retry'),
		tree: $('tree'), webRoot: $('web-root'),
		up: $('btn-up'), crumbs: $('crumbs'), filter: $('filter'), btnNew: $('btn-new'), btnUpload: $('btn-upload'),
		btnGrid: $('btn-grid'), btnList: $('btn-list'),
		newPanel: $('new-panel'), newName: $('new-name'), newPreview: $('new-preview'), newError: $('new-error'),
		btnCreate: $('btn-create'), btnCancel: $('btn-cancel'),
		uploadPanel: $('upload-panel'), uploadFile: $('upload-file-input'),
		uploadTitle: $('upload-title-input'), uploadAlt: $('upload-alt-input'),
		uploadPreview: $('upload-destination-preview'), uploadError: $('upload-error'),
		btnDoUpload: $('btn-do-upload'), btnUploadCancel: $('btn-upload-cancel'),
		linkFullStudio: $('link-full-upload-studio'),
		uploadDropzone: $('upload-dropzone'), dropzonePrompt: $('upload-dropzone-prompt'),
		selectedCard: $('upload-selected-card'), selectedName: $('upload-selected-name'),
		selectedMeta: $('upload-selected-meta'), selectedThumb: $('upload-selected-thumb'),
		btnRemoveFile: $('btn-remove-selected-file'), btnCloseUploadIcon: $('btn-upload-close-icon'),
		btnDoUploadText: $('btn-do-upload-text'), btnDoUploadSpinner: $('btn-do-upload-spinner'),
		btnDoUploadIcon: $('btn-do-upload-icon'),
		uploadTargetUrl: $('upload-target-url-input'),
		btnBrowseFile: $('btn-browse-file'),
		summary: $('summary'), levelHint: $('level-hint'),
		content: $('content'), items: $('items'),
		details: $('details'), toast: $('toast'),
		editMetaModal: $('mediaEditMetaModal'), editMetaForm: $('mediaEditMetaForm'),
		btnCloseEditMeta: $('btn-close-edit-meta'), btnCancelEditMeta: $('btn-cancel-edit-meta'),
		btnSaveEditMeta: $('btn-save-edit-meta'),
		editMetaId: $('edit-meta-id'), editMetaPath: $('edit-meta-path'),
		editMetaFilename: $('edit-meta-filename'), editMetaFileinfo: $('edit-meta-fileinfo'),
		editMetaThumb: $('edit-meta-thumb'), editMetaWcagBadge: $('edit-meta-wcag-badge'),
		editMetaAlt: $('edit-meta-alt'), editMetaAltChar: $('edit-meta-alt-char'),
		editMetaTitle: $('edit-meta-title'), editMetaCaption: $('edit-meta-caption'),
		editMetaCredit: $('edit-meta-credit'), editMetaTags: $('edit-meta-tags'),
		editMetaError: $('edit-meta-error')
	};

	// ------------------------------------------------------------------
	// Utilities
	// ------------------------------------------------------------------
	function esc(s) {
		return String(s == null ? '' : s)
			.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
	}

	function joinPath(a, b) { return a ? a + '/' + b : b; }
	function segs(p) { return p ? p.split('/') : []; }
	function parentOf(p) { var s = segs(p); s.pop(); return s.join('/'); }
	function depthOf(p) { return segs(p).length; }

	function diskPath(p, isDir) {
		var s = segs(p);
		if (s.length > 0 && s[0].toLowerCase() === 'shared images') {
			var sub = s.slice(1);
			var picRoot = 'C:\\inetpub\\chelan-county\\images\\picjumbo';
			var out = sub.length ? picRoot + '\\' + sub.join('\\') : picRoot;
			if (isDir && out.slice(-1) !== '\\') out += '\\';
			return out;
		}
		var root = state.cfg.filesRoot;
		var out = root + s.join('\\');
		if (isDir && out.slice(-1) !== '\\') out += '\\';
		return out;
	}
	function getAssetsBaseUrl() {
		var host = (state.assetsDomain || '').replace(/^https?:\/\//i, '').replace(/\/+$/, '');
		if (!host) return '';
		var proto = (state.assetsProtocol === 'https' || /^https:\/\//i.test(state.assetsDomain || '')) ? 'https' : 'http';
		return proto + '://' + host;
	}
	function assetsPath(p, isDir) {
		var s = segs(p);
		if (s.length > 0 && s[0].toLowerCase() === 'shared images') {
			var sub = s.slice(1);
			var outShared = (state.assetsDomain ? (state.assetsDomain + '\\') : '\\') + 'shared images' + (sub.length ? '\\' + sub.join('\\') : '');
			if (isDir && outShared.slice(-1) !== '\\') outShared += '\\';
			return outShared;
		}
		var out = (state.assetsDomain ? (state.assetsDomain + '\\') : '\\') + s.join('\\');
		if (isDir && out.slice(-1) !== '\\') out += '\\';
		return out;
	}
	function webPath(p, isDir) {
		var low = (p || '').toLowerCase();
		if (low.indexOf('shared images/') === 0 || low === 'shared images') {
			var rel = p.substring(13).replace(/^\//, '');
			var out = getAssetsBaseUrl() + '/shared images/' + (rel ? segs(rel).join('/') : '');
			if (isDir && out.slice(-1) !== '/') out += '/';
			return out;
		}
		var out = getAssetsBaseUrl() + '/' + p;
		if (isDir && out.slice(-1) !== '/') out += '/';
		return out;
	}
	function webHref(p) {
		var low = (p || '').toLowerCase();
		if (low.indexOf('shared images/') === 0 || low === 'shared images') {
			var rel = p.substring(13).replace(/^\//, '');
			return getAssetsBaseUrl() + '/shared%20images/' + (rel ? segs(rel).map(encodeURIComponent).join('/') : '');
		}
		return getAssetsBaseUrl() + '/' + segs(p).map(encodeURIComponent).join('/');
	}
	function localHref(p) {
		var low = (p || '').toLowerCase();
		if (low.indexOf('shared images/') === 0 || low === 'shared images') {
			var rel = p.substring(13).replace(/^\//, '');
			return '/images/picjumbo/' + (rel ? segs(rel).map(encodeURIComponent).join('/') : '');
		}
		return state.cfg.webBase + segs(p).map(encodeURIComponent).join('/');
	}
	function localThumbHref(p) {
		var s = segs(p);
		if (!s.length) return localHref(p);
		var fileName = s[s.length - 1];
		var dirSegs = s.slice(0, -1);
		var thumbRel = dirSegs.concat(['.thumbs', fileName]).join('/');
		return localHref(thumbRel);
	}
	function thumbHref(p) {
		var s = segs(p);
		if (!s.length) return webHref(p);
		var fileName = s[s.length - 1];
		var dirSegs = s.slice(0, -1);
		var thumbRel = dirSegs.concat(['.thumbs', fileName]).join('/');
		return webHref(thumbRel);
	}

	function friendly(name) {
		if (String(name).toLowerCase() === 'shared images') return 'Shared Images';
		return String(name).split(/[-_]+/).filter(Boolean).map(function (w) {
			return w.charAt(0).toUpperCase() + w.slice(1);
		}).join(' ');
	}

	function fmtSize(n) {
		n = Number(n) || 0;
		if (n < 1024) return n + ' B';
		var u = ['KB', 'MB', 'GB', 'TB'], i = -1;
		do { n /= 1024; i++; } while (n >= 1024 && i < u.length - 1);
		return (n >= 10 ? n.toFixed(0) : n.toFixed(1)) + ' ' + u[i];
	}

	function plural(n, one, many) { return n + ' ' + (n === 1 ? one : many); }

	function fileKind(ext) {
		ext = (ext || '').toLowerCase();
		if (IMAGE_EXT.indexOf(ext) >= 0) return { cls: 'image', label: ext.toUpperCase() + ' image' };
		if (ext === 'pdf') return { cls: 'pdf', label: 'PDF document' };
		if (WORD_EXT.indexOf(ext) >= 0) return { cls: 'word', label: 'Word document' };
		if (ext === 'csv') return { cls: 'excel', label: 'CSV file' };
		if (EXCEL_EXT.indexOf(ext) >= 0) return { cls: 'excel', label: 'Excel spreadsheet' };
		return { cls: 'other', label: ext ? ext.toUpperCase() + ' file' : 'File' };
	}

	function folderKind(depth) {
		if (state.path && state.path.toLowerCase().indexOf('shared images') >= 0) return 'Shared Stock Library (Read-Only)';
		if (depth === 0) return 'Files root';
		if (depth === 1) return 'Workspace folder';
		if (depth <= state.cfg.systemDepth) return 'System folder';
		return 'Folder';
	}

	function rulesNote(depth) {
		if (state.path && state.path.toLowerCase().indexOf('shared images') >= 0) {
			return 'Shared stock photography library (C:\\inetpub\\chelan-county\\images\\picjumbo) is read-only. Adding, renaming, or deleting folders/files is disabled for all users.';
		}
		if (depth <= 1) return 'This is your workspace root folder. Folders can be created inside images (or media) and documents.';
		if (depth <= state.cfg.systemDepth) return 'System folder. You can create subfolders inside it, but it cannot be renamed or deleted.';
		return '';
	}

	function levelHint(depth) {
		if (state.path && state.path.toLowerCase().indexOf('shared images') >= 0) {
			return 'Shared stock photography \u00b7 Read-Only (selection only)';
		}
		if (depth <= 1) return 'Workspace root \u00b7 read-only';
		if (depth <= state.cfg.systemDepth) return 'System folder \u00b7 subfolders allowed';
		return 'User folder \u00b7 subfolders allowed, delete when empty';
	}

	var toastTimer = null;
	function toast(msg, isError) {
		if (!el.toast) return;
		el.toast.textContent = msg;
		el.toast.className = 'toast' + (isError ? ' error' : '');
		el.toast.hidden = false;
		clearTimeout(toastTimer);
		toastTimer = setTimeout(function () { el.toast.hidden = true; }, 3500);
	}

	function lsGet(k) { try { return window.localStorage.getItem(k); } catch (e) { return null; } }
	function lsSet(k, v) { try { window.localStorage.setItem(k, v); } catch (e) { /* ignore */ } }

	// ------------------------------------------------------------------
	// Name validation (mirrors api/Files.cfc validateName)
	// ------------------------------------------------------------------
	function validateName(name) {
		var max = state.cfg.maxNameLen || 64;
		if (!name) return 'Enter a folder name.';
		if (name.length > max) return 'Folder names can be at most ' + max + ' characters.';
		if (!/^[A-Za-z0-9][A-Za-z0-9 _.\-]*$/.test(name)) {
			return 'Use letters, numbers, spaces, dots, hyphens and underscores, starting with a letter or number.';
		}
		if (/[. ]$/.test(name)) return 'Folder names cannot end with a dot or a space.';
		if (/^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$/i.test(name)) return '"' + name + '" is a reserved Windows name.';
		var lower = name.toLowerCase();
		for (var i = 0; i < state.items.length; i++) {
			if (state.items[i].name.toLowerCase() === lower) return 'An item named "' + state.items[i].name + '" already exists here.';
		}
		return '';
	}

	// ------------------------------------------------------------------
	// API
	// ------------------------------------------------------------------
	function parseJSON(text) {
		if (typeof text !== 'string') return null;
		var t = text.trim();
		if (t.indexOf('//') === 0) t = t.slice(2);   // Adobe CF secureJSON prefix
		try { return JSON.parse(t); } catch (e) { return null; }
	}

	/**
	 * Calls a remote CFC method. Resolves to { ok, data, error, status, network }.
	 */
	async function api(method, params, httpMethod, opts) {
		httpMethod = httpMethod || 'GET';
		opts = opts || {};
		params = params || {};

		// Automatically scope to active workspace if set (except for ping)
		if (state.ws && !params.ws && method !== 'ping') {
			params.ws = state.ws;
		}

		var qs = new URLSearchParams();
		qs.set('method', method);
		qs.set('returnformat', 'json');

		var init = {
			method: httpMethod,
			cache: 'no-store',
			credentials: 'same-origin',
			headers: { 'Accept': 'application/json', 'X-Requested-With': 'FileExplorer' }
		};

		if (httpMethod === 'GET') {
			Object.keys(params).forEach(function (k) { qs.set(k, params[k]); });
			qs.set('_', String(Date.now()));
		} else {
			var body = new URLSearchParams();
			Object.keys(params).forEach(function (k) { body.set(k, params[k]); });
			init.body = body.toString();
			init.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
		}

		var ctrl = ('AbortController' in window) ? new AbortController() : null;
		if (ctrl) init.signal = ctrl.signal;
		var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, REQUEST_TIMEOUT_MS) : null;

		var t0 = performance.now();
		var result = { ok: false, data: null, error: '', status: 0, network: false };

		try {
			var res = await fetch(API_URL + '?' + qs.toString(), init);
			result.status = res.status;
			var text = await res.text();
			result.data = parseJSON(text);
			if (result.data === null || typeof result.data !== 'object') {
				result.network = true;
				result.error = 'HTTP ' + res.status + ' (no JSON)';
			} else if (result.data.ok === true) {
				result.ok = true;
			} else {
				result.error = String(result.data.error || ('HTTP ' + res.status));
			}
		} catch (e) {
			result.network = true;
			result.error = (e && e.name === 'AbortError') ? 'Timed out' : 'Network error';
		} finally {
			if (timer) clearTimeout(timer);
		}

		result.ms = Math.round(performance.now() - t0);

		if (result.network) setOffline();
		return result;
	}

	// ------------------------------------------------------------------
	// Connection
	// ------------------------------------------------------------------
	function setConnecting() {
		if (el.conn) el.conn.className = 'conn conn-connecting';
		if (el.connText) el.connText.textContent = 'Connecting\u2026';
	}

	function setOnline(server, ms) {
		var wasOnline = state.online;
		state.online = true;
		if (el.conn) el.conn.className = 'conn conn-online';
		if (el.connText) el.connText.textContent = 'Connected \u00b7 ' + ms + ' ms';
		if (el.banner) el.banner.hidden = true;
		if (wasOnline !== true) {
			updateWriteControls();
			renderDetails();
		}
	}

	function setOffline() {
		if (state.online === false) return;
		state.online = false;
		if (el.conn) el.conn.className = 'conn conn-offline';
		if (el.connText) el.connText.textContent = 'Offline';
		if (el.banner) el.banner.hidden = false;
		closeNew();
		updateWriteControls();
		renderDetails();
	}

	async function ping(manual) {
		var wasOnline = state.online;
		if (manual) setConnecting();
		var r = await api('ping', {}, 'GET', { quiet: true });
		if (r.ok) {
			var d = r.data;
			state.cfg.server = String(d.server || '');
			if (d.filesRoot) state.cfg.filesRoot = String(d.filesRoot);
			if (d.webBase) state.cfg.webBase = String(d.webBase);
		if (d.assetsProtocol) state.assetsProtocol = String(d.assetsProtocol);
		if (typeof d.assetsDomain === 'string') state.assetsDomain = d.assetsDomain;
			if (d.systemDepth != null) state.cfg.systemDepth = Number(d.systemDepth);
			if (d.maxNameLen != null) state.cfg.maxNameLen = Number(d.maxNameLen);
			if (el.webRoot) {
				el.webRoot.textContent = getAssetsBaseUrl() + '/' + (state.ws ? state.ws + '/' : '');
			}
			if (el.newName) el.newName.maxLength = state.cfg.maxNameLen;
			setOnline(state.cfg.server, r.ms);
			if (wasOnline !== true) load(currentHashPath(), state.selected);
		} else if (!r.network) {
			state.online = false;
			if (el.conn) el.conn.className = 'conn conn-offline';
			if (el.connText) el.connText.textContent = 'Access denied';
			state.loadError = r.error;
			renderItems();
			updateWriteControls();
		}
	}

	// ------------------------------------------------------------------
	// Routing (location.hash = "#/[workspace]/documents")
	// ------------------------------------------------------------------
	function currentHashPath() {
		var h = location.hash || '';
		var p = '';
		if (h.indexOf('#/') === 0) {
			p = h.slice(2).split('/').filter(Boolean).map(function (s) {
				try { return decodeURIComponent(s); } catch (e) { return s; }
			}).join('/');
		}

		// When scoped to a workspace, ensure navigation cannot go outside it, except to shared images
		if (state.ws) {
			var isShared = (p && (p.toLowerCase() === 'shared images' || p.toLowerCase().indexOf('shared images/') === 0));
			if (!isShared && (!p || (p !== state.ws && p.indexOf(state.ws + '/') !== 0))) {
				if (state.initialFolder) {
					return state.ws + '/' + state.initialFolder;
				}
				return state.ws;
			}
		}
		return p;
	}

	function hashFor(p) { return '#/' + segs(p).map(encodeURIComponent).join('/'); }

	function navigate(p, selectName) {
		var isShared = (p && (p.toLowerCase() === 'shared images' || p.toLowerCase().indexOf('shared images/') === 0));
		if (state.ws && !isShared && (!p || (p !== state.ws && p.indexOf(state.ws + '/') !== 0))) {
			p = state.ws;
		}
		var target = hashFor(p);
		if (location.hash === target) {
			load(p, selectName);
		} else {
			state.pendingSelect = selectName || null;
			location.hash = target;
		}
	}

	window.addEventListener('hashchange', function () {
		if ((location.hash || '').indexOf('#/') !== 0 && location.hash) return;
		var sel = state.pendingSelect || null;
		state.pendingSelect = null;
		load(currentHashPath(), sel);
	});

	// ------------------------------------------------------------------
	// Loading
	// ------------------------------------------------------------------
	function sortItems(items) {
		return items.slice().sort(function (a, b) {
			if (a.type !== b.type) return a.type === 'dir' ? -1 : 1;
			return a.name.localeCompare(b.name, undefined, { sensitivity: 'base', numeric: true });
		});
	}

	function normaliseItem(it) {
		return {
			id: it.id || null,
			name: String(it.name),
			type: String(it.type).toLowerCase() === 'dir' ? 'dir' : 'file',
			modified: String(it.modified || ''),
			size: Number(it.size || 0),
			ext: String(it.ext || '').toLowerCase(),
			dirs: Number(it.dirs || 0),
			files: Number(it.files || 0),
			title: it.title || '',
			altText: it.altText || it.alt_text || '',
			caption: it.caption || '',
			credit: it.credit || '',
			tags: it.tags || '',
			hash: it.hash || it.fileHash || '',
			fileHash: it.fileHash || it.hash || '',
			isWcagCompliant: typeof it.isWcagCompliant !== 'undefined' ? Boolean(it.isWcagCompliant) : null,
			width: it.width ? Number(it.width) : null,
			height: it.height ? Number(it.height) : null
		};
	}

	async function load(p, selectName) {
		var token = ++state.loadToken;
		disarmDelete();

		var targetPath = p || (state.ws ? state.ws : '');
		var r = await api('list', { path: targetPath, ws: state.ws || '' }, 'GET');
		if (token !== state.loadToken) return;

		if (!r.ok) {
			state.loadError = r.network ? 'Cannot reach the file server.' : r.error;
			if (!r.network) toast(r.error, true);
			renderItems();
			return;
		}

		var d = r.data;
		state.loadError = '';
		state.data = d;
		state.path = String(d.path || '');
		state.depth = Number(d.depth || 0);
		if (d.filesRoot) state.cfg.filesRoot = String(d.filesRoot);
		if (d.webBase) state.cfg.webBase = String(d.webBase);
		if (d.assetsProtocol) state.assetsProtocol = String(d.assetsProtocol);
		if (typeof d.assetsDomain === 'string') state.assetsDomain = d.assetsDomain;
		state.items = sortItems((d.items || []).map(normaliseItem));
		state.selected = null;
		if (selectName) {
			var low = String(selectName).toLowerCase();
			state.items.forEach(function (it) { if (it.name.toLowerCase() === low) state.selected = it.name; });
		}
		state.filter = '';
		if (el.filter) el.filter.value = '';

		if (hashFor(state.path) !== location.hash && (location.hash || '').indexOf('#/') === 0) {
			history.replaceState(null, '', hashFor(state.path));
		}

		renderAll();

		if (state.selected) focusSelected();
		if (state.pendingNew) { state.pendingNew = false; openNew(); }
		if (state.pendingUpload) { state.pendingUpload = false; openUpload(); }
	}

	// ------------------------------------------------------------------
	// Rendering
	// ------------------------------------------------------------------
	var ICON = {
		folder: '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
		file: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
		image: '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5-9 9"/>',
		chevron: '<path d="M9 6l6 6-6 6"/>',
		root: '<path d="M4 6h16v4H4zM4 14h16v4H4z"/><path d="M8 8h.01M8 16h.01"/>',
		check: '<path d="M20 6L9 17l-5-5"/>',
		alert: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>'
	};
	function svg(name, cls) { return '<svg viewBox="0 0 24 24" aria-hidden="true"' + (cls ? ' class="' + cls + '"' : '') + '>' + ICON[name] + '</svg>'; }

	function renderAll() {
		renderTree();
		renderCrumbs();
		applyFilter();
		renderItems();
		renderDetails();
		updateWriteControls();
	}

	function renderTree() {
		var d = state.data;
		if (!d) return;
		var branches = d.branches || [];

		function isCurrent(p) { return p.toLowerCase() === state.path.toLowerCase(); }

		function renderNode(node, depth) {
			if (!node || !node.name) return '';
			var p = node.path;
			var isCur = isCurrent(p);
			var indent = depth * 18;
			var children = node.children || [];
			var childrenHtml = children.map(function (c) {
				return renderNode(c, depth + 1);
			}).join('');

			var isShared = (node.name.toLowerCase() === 'shared images' || Boolean(node.isShared));
			var displayName = isShared ? 'Shared Images' : node.name;
			var countText = (node.count != null && !isNaN(node.count) && node.count !== '') ? String(node.count) : '';

			return '<li>' +
				'<button type="button" class="tree-row' + (isCur ? ' is-active' : '') + (depth === 0 ? ' is-root' : '') + (isShared ? ' is-shared' : '') + '"' +
				' data-path="' + esc(p) + '" style="padding-left: ' + (10 + indent) + 'px;"' +
				(isCur ? ' aria-current="page"' : '') + ' title="' + esc(displayName + (isShared ? ' (Read-Only Stock Photography)' : '')) + '">' +
				svg(isShared ? 'image' : 'folder', isShared ? 'ficon ficon-shared' : 'ficon') +
				'<span class="label">' + esc(displayName) + '</span>' +
				(isShared ? '<span style="font-size:10px; padding:1px 5px; border-radius:4px; background:#e2e8f0; color:#475569; font-weight:700; margin-left:auto; margin-right:4px;">RO</span>' : '') +
				(countText !== '' ? '<span class="count">' + esc(countText) + '</span>' : '') +
				'</button>' +
				(childrenHtml ? '<ul role="list">' + childrenHtml + '</ul>' : '') +
				'</li>';
		}

		var treeHtml = '';
		if (d.tree && d.tree.name) {
			treeHtml += renderNode(d.tree, 0);
		} else if (state.ws) {
			var wsNode = {
				name: state.ws,
				path: state.ws,
				count: (d.branches && d.branches[1]) ? (d.branches[1].dirs || []).length : '',
				children: []
			};
			if (d.branches && d.branches[1] && d.branches[1].dirs) {
				wsNode.children = d.branches[1].dirs.map(function (dn) {
					return { name: dn, path: joinPath(state.ws, dn), count: '', children: [] };
				});
			}
			treeHtml += renderNode(wsNode, 0);
		}

		// Always render Shared Images as dedicated root library outside workspace folder
		var sharedNode = d.sharedTree || {
			name: 'Shared Images',
			path: 'shared images',
			count: '',
			isShared: true,
			isReadOnly: true,
			children: []
		};
		treeHtml += '<li class="tree-divider" style="margin: 10px 0; border-top: 1px solid var(--fx-border, #cbd5e1); list-style: none;" aria-hidden="true"></li>';
		treeHtml += renderNode(sharedNode, 0);

		el.tree.innerHTML = treeHtml;
	}

	function renderCrumbs() {
		var s = segs(state.path);
		var isSharedView = (state.path.toLowerCase() === 'shared images' || state.path.toLowerCase().indexOf('shared images/') === 0);

		if (isSharedView) {
			var isSharedRoot = (state.path.toLowerCase() === 'shared images');
			var html = isSharedRoot
				? '<span class="root" aria-current="page">Shared Images</span><span class="sep" aria-hidden="true">\\</span>'
				: '<button type="button" data-path="shared images" class="root" title="Shared Images">Shared Images</button><span class="sep" aria-hidden="true">\\</span>';

			var acc = 'shared images';
			for (var i = 1; i < s.length; i++) {
				var seg = s[i];
				acc = joinPath(acc, seg);
				var last = i === s.length - 1;
				html += last
					? '<span aria-current="page">' + esc(seg) + '</span><span class="sep" aria-hidden="true">\\</span>'
					: '<button type="button" data-path="' + esc(acc) + '">' + esc(seg) + '</button><span class="sep" aria-hidden="true">\\</span>';
			}
			el.crumbs.innerHTML = html;
			el.up.disabled = isSharedRoot;
			return;
		}

		if (state.ws) {
			var wsTitle = state.wsName || friendly(state.ws);
			var isWsRoot = state.path.toLowerCase() === state.ws.toLowerCase();
			var html = isWsRoot
				? '<span class="root" aria-current="page">' + esc(wsTitle) + '</span><span class="sep" aria-hidden="true">\\</span>'
				: '<button type="button" data-path="' + esc(state.ws) + '" class="root" title="' + esc(wsTitle) + '">' + esc(wsTitle) + '</button><span class="sep" aria-hidden="true">\\</span>';

			var acc = state.ws;
			for (var i = 1; i < s.length; i++) {
				var seg = s[i];
				acc = joinPath(acc, seg);
				var last = i === s.length - 1;
				html += last
					? '<span aria-current="page">' + esc(seg) + '</span><span class="sep" aria-hidden="true">\\</span>'
					: '<button type="button" data-path="' + esc(acc) + '">' + esc(seg) + '</button><span class="sep" aria-hidden="true">\\</span>';
			}
			el.crumbs.innerHTML = html;
			el.up.disabled = isWsRoot;
		} else {
			var root = state.cfg.filesRoot;
			var html = s.length
				? '<button type="button" data-path="" class="root" title="Files root">' + esc(root) + '</button>'
				: '<span class="root" aria-current="page">' + esc(root) + '</span>';
			var acc = '';
			s.forEach(function (seg, i) {
				acc = joinPath(acc, seg);
				var segLabel = (seg.toLowerCase() === 'shared images') ? 'Shared Images' : seg;
				var last = i === s.length - 1;
				html += last
					? '<span aria-current="page">' + esc(segLabel) + '</span><span class="sep" aria-hidden="true">\\</span>'
					: '<button type="button" data-path="' + esc(acc) + '">' + esc(segLabel) + '</button><span class="sep" aria-hidden="true">\\</span>';
			});
			el.crumbs.innerHTML = html;
			el.up.disabled = s.length === 0;
		}
	}

	function applyFilter() {
		var q = state.filter.trim().toLowerCase();
		state.shown = q ? state.items.filter(function (it) {
			return it.name.toLowerCase().indexOf(q) >= 0 ||
				(it.title && it.title.toLowerCase().indexOf(q) >= 0) ||
				(it.altText && it.altText.toLowerCase().indexOf(q) >= 0) ||
				(it.tags && it.tags.toLowerCase().indexOf(q) >= 0);
		}) : state.items.slice();
		if (state.selected && !state.shown.some(function (it) { return it.name === state.selected; })) state.selected = null;

		var nd = 0, nf = 0;
		state.items.forEach(function (it) { if (it.type === 'dir') nd++; else nf++; });
		var txt = plural(nd, 'folder', 'folders') + ', ' + plural(nf, 'file', 'files');
		if (q) txt += ' \u00b7 ' + state.shown.length + ' shown';
		if (el.summary) el.summary.textContent = state.data ? txt : '\u00a0';
		if (el.levelHint) el.levelHint.textContent = state.data ? levelHint(state.depth) : '';
	}

	function itemPath(it) { return joinPath(state.path, it.name); }

	function iconFor(it) {
		if (it.type === 'dir') {
			return (state.ws && state.depth === 1) ? svg('folder', 'folder-dark') : svg('folder', 'folder-light');
		}
		var k = fileKind(it.ext);
		return svg(k.cls === 'image' ? 'image' : 'file', 't-' + k.cls);
	}

	function thumbFor(it) {
		var k = it.type === 'file' ? fileKind(it.ext) : null;
		if (k && k.cls === 'image') {
			var fullUrl = webHref(itemPath(it));
			var useThumb = (it.ext !== 'svg' && it.ext !== 'ico' && it.ext !== 'webp');
			var srcUrl = useThumb ? thumbHref(itemPath(it)) : fullUrl;
			var localFull = localHref(itemPath(it));
			var localThumb = useThumb ? localThumbHref(itemPath(it)) : localFull;
			return '<img loading="lazy" decoding="async" alt="" src="' + esc(srcUrl) + '" data-full-src="' + esc(fullUrl) + '" data-local-thumb-src="' + esc(localThumb) + '" data-local-src="' + esc(localFull) + '" data-fallback="1">';
		}
		return iconFor(it);
	}

	function dirMeta(it) {
		if (it && it.name && it.name.toLowerCase() === 'shared images') {
			return 'Shared Stock Photography \u00b7 ' + plural(it.files, 'photo', 'photos');
		}
		return plural(it.dirs, 'folder', 'folders') + ' \u00b7 ' + plural(it.files, 'file', 'files');
	}

	function renderItems() {
		if (state.loadError) {
			el.items.innerHTML = '<div class="empty" role="alert">' + esc(state.loadError) +
				(state.path ? ' <button type="button" class="btn btn-small" data-path="' + esc(state.ws || '') + '">Go to workspace root</button>' : '') + '</div>';
			return;
		}
		if (!state.data) {
			el.items.innerHTML = '<div class="empty">Loading\u2026</div>';
			return;
		}
		if (!state.shown.length) {
			el.items.innerHTML = '<div class="empty">' + (state.filter ? 'No items match the filter.' : 'This folder is empty.') + '</div>';
			return;
		}

		if (state.view === 'grid') {
			el.items.innerHTML = '<div class="grid" role="list">' +
				state.shown.map(function (it, idx) {
					var sel = it.name === state.selected;
					var isDir = it.type === 'dir';
					var isShared = isDir && (it.name.toLowerCase() === 'shared images');
					var displayName = isShared ? 'Shared Images' : it.name;
					var meta = isDir ? dirMeta(it) : (fmtSize(it.size) + ' \u00b7 ' + it.modified);
					var badge = isShared ? '<span style="position:absolute; top:8px; right:8px; font-size:10.5px; font-weight:700; background:#f1f5f9; color:#475569; border:1px solid #cbd5e1; border-radius:4px; padding:2px 6px;">READ-ONLY</span>' : '';
					var pickerBtn = (state.pickerMode && !isDir)
						? '<div style="margin-top:6px; width:100%;"><button type="button" class="btn btn-primary btn-xs btn-block" data-act="select-card-file" data-idx="' + idx + '" style="width:100%; font-size:11px; padding:3px 6px; font-weight:600; cursor:pointer;">' + (state.pickerMode === 'document' ? 'Select File' : 'Select Image') + '</button></div>'
						: '';
					return '<div class="card item' + (isShared ? ' is-shared-card' : '') + '" role="listitem" tabindex="' + (sel || (!state.selected && idx === 0) ? '0' : '-1') + '"' +
						' aria-selected="' + (sel ? 'true' : 'false') + '" data-idx="' + idx + '">' +
						badge +
						'<div class="thumb">' + thumbFor(it) + '</div>' +
						'<div class="name" title="' + esc(displayName) + '">' + esc(displayName) + '</div>' +
						'<div class="meta">' + esc(meta) + '</div>' +
						pickerBtn +
						'</div>';
				}).join('') +
				'</div>';
		} else {
			el.items.innerHTML = '<div class="table-wrap"><table class="list" role="table"><thead><tr>' +
				'<th scope="col">Name</th><th scope="col">Type</th><th scope="col" class="num">Size</th><th scope="col">Modified</th>' +
				(state.pickerMode ? '<th scope="col" style="width:90px;">Action</th>' : '') +
				'</tr></thead><tbody>' +
				state.shown.map(function (it, idx) {
					var sel = it.name === state.selected;
					var isDir = it.type === 'dir';
					var isShared = isDir && (it.name.toLowerCase() === 'shared images');
					var displayName = isShared ? 'Shared Images' : it.name;
					var k = isDir ? { cls: isShared ? 'shared' : 'dir', label: isShared ? 'Shared Photos' : 'Folder' } : fileKind(it.ext);
					var chipText = isShared ? 'READ-ONLY' : (isDir ? 'DIR' : (it.ext || 'FILE'));
					var chip = '<span class="chip bg-' + k.cls + '">' + esc(chipText) + '</span>';
					var rowAction = state.pickerMode
						? ('<td>' + (!isDir ? '<button type="button" class="btn btn-primary btn-xs" data-act="select-card-file" data-idx="' + idx + '" style="font-size:11px; padding:2px 8px;">Select</button>' : '') + '</td>')
						: '';
					return '<tr class="row item" tabindex="' + (sel || (!state.selected && idx === 0) ? '0' : '-1') + '"' +
						' aria-selected="' + (sel ? 'true' : 'false') + '" data-idx="' + idx + '">' +
						'<td><div class="cell-name">' + chip + '<span title="' + esc(displayName) + '">' + esc(displayName) + '</span></div></td>' +
						'<td>' + esc(k.label) + '</td>' +
						'<td class="num mono">' + esc(isDir ? '\u2014' : fmtSize(it.size)) + '</td>' +
						'<td class="mono muted">' + esc(it.modified || '\u2014') + '</td>' +
						rowAction +
						'</tr>';
				}).join('') +
				'</tbody></table></div>';
		}
	}

	el.items.addEventListener('error', function (e) {
		var t = e.target;
		if (t && t.tagName === 'IMG' && t.getAttribute('data-fallback')) {
			var fullSrc = t.getAttribute('data-full-src');
			if (fullSrc && t.getAttribute('src') !== fullSrc) {
				t.setAttribute('src', fullSrc);
				t.removeAttribute('data-full-src');
				return;
			}
			var localThumbSrc = t.getAttribute('data-local-thumb-src');
			if (localThumbSrc && t.getAttribute('src') !== localThumbSrc) {
				t.setAttribute('src', localThumbSrc);
				t.removeAttribute('data-local-thumb-src');
				return;
			}
			var localSrc = t.getAttribute('data-local-src');
			if (localSrc && t.getAttribute('src') !== localSrc) {
				t.setAttribute('src', localSrc);
				t.removeAttribute('data-local-src');
				return;
			}
			var wrap = document.createElement('span');
			wrap.innerHTML = svg('image', 't-image');
			t.replaceWith(wrap.firstChild);
		}
	}, true);

	function selectedItem() {
		if (!state.selected) return null;
		for (var i = 0; i < state.items.length; i++) if (state.items[i].name === state.selected) return state.items[i];
		return null;
	}

	function renderDetails() {
		if (!el.details) return;
		if (!state.data) { el.details.innerHTML = '<div class="muted">Loading\u2026</div>'; return; }
		var it = selectedItem();
		var online = state.online === true;
		var html;

		if (!it || it.type === 'dir') {
			var isCurrent = !it;
			var p = isCurrent ? state.path : itemPath(it);
			var depth = depthOf(p);
			var nd, nf;
			if (isCurrent) {
				nd = 0; nf = 0;
				state.items.forEach(function (x) { if (x.type === 'dir') nd++; else nf++; });
			} else { nd = it.dirs; nf = it.files; }

			var segList = segs(p);
			var rawName = segList.length ? segList.slice(-1)[0] : '';
			var title = (state.ws && p.toLowerCase() === state.ws.toLowerCase())
				? (state.wsName || friendly(rawName))
				: (depth <= 1 ? friendly(rawName) : rawName);

			var isSharedDir = p.toLowerCase().indexOf('shared images') >= 0;
			var canUpload = !isSharedDir;
			var canNew = !isSharedDir && (depth >= state.cfg.systemDepth);
			var canDel = !isSharedDir && (depth > state.cfg.systemDepth) && (nd + nf === 0);
			var armed = state.armed && state.armed.path === p;
			var note = isSharedDir ? 'This shared stock photography library is read-only. Adding, renaming, or deleting folders/files is disabled for all users.' : rulesNote(depth);
			if (!note && nd + nf > 0) note = 'Only empty folders can be deleted.';

			html = '<div class="preview">' + svg(isSharedDir ? 'image' : 'folder', depth <= 1 ? 'folder-dark' : (isSharedDir ? 'ficon-shared' : 'folder-light')) + '</div>' +
				'<h2>' + esc(title) + '</h2>' +
				'<div class="kind">' + esc(isSharedDir ? 'Shared Stock Library (Read-Only)' : (folderKind(depth) + (isCurrent ? ' \u00b7 current folder' : ''))) + '</div>' +
				'<div class="actions">' +
				(isCurrent ? '' : '<button type="button" class="btn btn-primary btn-block" data-act="open">Open folder</button>') +
				(canUpload ? '<button type="button" class="btn ' + (isCurrent ? 'btn-primary' : '') + ' btn-block" data-act="upload"' + (online ? '' : ' disabled') + '>Upload file here</button>' : '') +
				(canNew ? '<button type="button" class="btn btn-block" data-act="new"' + (online ? '' : ' disabled') + '>New subfolder</button>' : '') +
				(!isSharedDir ? '<button type="button" class="btn btn-block" data-act="crawl-folder" data-path="' + esc(p) + '"' + (online ? '' : ' disabled') + '>OCR Crawl &amp; Make Compliant</button>' : '') +
				(canDel && depth > state.cfg.systemDepth
					? '<button type="button" class="btn btn-danger btn-block' + (armed ? ' confirming' : '') + '" data-act="delete" data-path="' + esc(p) + '"' +
						(online ? '' : ' disabled') + '>' + (armed ? 'Confirm delete' : 'Delete folder') + '</button>'
					: '') +
				'</div>' +
				'<dl>' +
				'<dt>Storage path</dt><dd class="mono">' + esc(diskPath(p, true)) + '</dd>' +
				'<dt>Web URL</dt><dd class="mono">' + esc(webPath(p, true)) + '</dd>' +
				'<dt>Contents</dt><dd>' + esc(plural(nd, 'folder', 'folders') + ', ' + plural(nf, 'file', 'files')) + '</dd>' +
				(it && it.modified ? '<dt>Modified</dt><dd>' + esc(it.modified) + '</dd>' : '') +
				'</dl>' +
				(note ? '<div class="rules-note">' + esc(note) + '</div>' : '');
		} else {
			var fp = itemPath(it);
			var k = fileKind(it.ext);
			var isSharedFile = fp.toLowerCase().indexOf('shared images') >= 0;
			var preview = k.cls === 'image'
				? '<img alt="' + esc(it.altText || it.title || '') + '" src="' + esc(webHref(fp)) + '" data-local-src="' + esc(localHref(fp)) + '" data-fallback="1">'
				: svg(k.cls === 'image' ? 'image' : 'file', 't-' + k.cls);
			var isPicker = Boolean(state.pickerMode || state.pickerCallback || state.targetInput);
			var selectLabel = state.pickerMode === 'document' ? 'Select Document' : (state.pickerMode === 'image' ? 'Select Image' : 'Select File');

			var isImg = k.cls === 'image';
			var isCompliant = (it.isWcagCompliant === true) || (!isImg) || (Boolean(it.altText && it.altText.trim()));
			var wcagPill = '';
			if (isImg) {
				if (isCompliant) {
					wcagPill = '<dd><span style="display:inline-flex; align-items:center; gap:4px; padding:3px 8px; font-size:11.5px; font-weight:600; background:#dcfce7; color:#166534; border-radius:12px;">' +
						svg('check', '') + ' WCAG AA Compliant</span></dd>';
				} else {
					wcagPill = '<dd><span style="display:inline-flex; align-items:center; gap:4px; padding:3px 8px; font-size:11.5px; font-weight:600; background:#fef3c7; color:#92400e; border-radius:12px;">' +
						svg('alert', '') + ' Needs Alt Text (WCAG 1.1.1)</span></dd>';
				}
			}

			html = '<div class="preview">' + preview + '</div>' +
				'<h2>' + esc(it.title || it.name) + '</h2>' +
				(it.title && it.title !== it.name ? '<div style="font-family:monospace; font-size:11.5px; color:var(--fx-muted); margin-bottom:4px;">' + esc(it.name) + '</div>' : '') +
				'<div class="kind">' + esc(k.label + ' \u00b7 ' + fmtSize(it.size)) + (isSharedFile ? ' \u00b7 <span style="font-weight:700; color:#0284c7;">Read-Only</span>' : '') + '</div>' +
				'<div class="actions">' +
				(isPicker
					? '<button type="button" class="btn btn-primary btn-block" data-act="select-file">' + esc(selectLabel) + '</button>' +
					  '<a class="btn btn-block" href="' + esc(webHref(fp)) + '" target="_blank" rel="noopener">Open <span class="sr-only">(opens in a new tab)</span></a>'
					: '<a class="btn btn-primary btn-block" href="' + esc(webHref(fp)) + '" target="_blank" rel="noopener">Open <span class="sr-only">(opens in a new tab)</span></a>'
				) +
				(!isSharedFile
					? (isImg && !isCompliant
						? '<button type="button" class="btn btn-block" data-act="edit-meta" style="background:#fee2e2; border:1.5px solid #ef4444; color:#991b1b; font-weight:700; display:flex; align-items:center; justify-content:center; gap:6px;">' + svg('alert', '') + '<span>Enter WCAG Alt Text</span></button>'
						: '<button type="button" class="btn btn-block" data-act="edit-meta">Edit WCAG Metadata</button>')
					: '') +
				'<button type="button" class="btn btn-block" data-act="copy">Copy link</button>' +
				'</div>' +
				(isImg && !isCompliant
					? '<div style="background:#fff1f2; border:1px solid #fecdd3; border-radius:8px; padding:8px 10px; margin:8px 0; font-size:11.5px; color:#9f1239; line-height:1.4;">' +
					  '<strong>WCAG 1.1.1 Required:</strong> Missing alternative text description for screen readers. Click "Enter WCAG Alt Text" above to satisfy ADA compliance.' +
					  '</div>'
					: '') +
				'<dl>' +
				(isImg ? '<dt>ADA Accessibility</dt>' + wcagPill : '') +
				(isImg ? '<dt>Alt text (WCAG 1.1.1)</dt><dd>' + (it.altText ? ('&ldquo;' + esc(it.altText) + '&rdquo;') : '<span style="color:#b45309; font-style:italic;">None specified &mdash; required for screen readers</span>') + '</dd>' : '') +
				(it.ocrText ? '<dt>OCR Detected Text</dt><dd class="mono" style="font-size:11.5px; background:#f5f3ff; color:#5b21b6; padding:4px 8px; border-radius:6px; border:1px solid #ddd6fe;">' + esc(it.ocrText) + '</dd>' : '') +
				(it.width && it.height ? '<dt>Dimensions</dt><dd>' + esc(it.width + ' \u00d7 ' + it.height + ' px') + '</dd>' : '') +
				(it.caption ? '<dt>Caption</dt><dd>' + esc(it.caption) + '</dd>' : '') +
				(it.credit ? '<dt>Attribution / Credit</dt><dd>' + esc(it.credit) + '</dd>' : '') +
				(it.tags ? '<dt>Tags</dt><dd>' + esc(it.tags) + '</dd>' : '') +
				'<dt>Storage path</dt><dd class="mono">' + esc(diskPath(fp, false)) + '</dd>' +
				'<dt>Web URL</dt><dd class="mono">' + esc(webPath(fp, false)) + '</dd>' +
				'<dt>Size</dt><dd>' + esc(fmtSize(it.size) + ' (' + it.size.toLocaleString() + ' bytes)') + '</dd>' +
				(it.fileHash || it.hash ? '<dt>SHA-256 Hash</dt><dd class="mono" style="font-size:11px; word-break:break-all;" title="' + esc(it.fileHash || it.hash) + '">' + esc(it.fileHash || it.hash) + '</dd>' : '') +
				'<dt>Modified</dt><dd>' + esc(it.modified) + '</dd>' +
				'</dl>';
		}
		el.details.innerHTML = html;
	}

	if (el.details) {
		el.details.addEventListener('error', function (e) {
			var t = e.target;
			if (t && t.tagName === 'IMG') {
				var localSrc = t.getAttribute('data-local-src');
				if (localSrc && t.getAttribute('src') !== localSrc) {
					t.setAttribute('src', localSrc);
					t.removeAttribute('data-local-src');
					return;
				}
				var wrap = document.createElement('span');
				wrap.innerHTML = svg('image', 't-image');
				t.replaceWith(wrap.firstChild);
			}
		}, true);
	}

	function updateWriteControls() {
		var online = state.online === true;
		var isShared = (state.path && state.path.toLowerCase().indexOf('shared images') >= 0);
		var canCreate = !isShared && !!state.data && state.depth >= state.cfg.systemDepth && (state.data.canCreate !== false);
		var canUpload = !isShared && (state.depth >= 1);
		if (el.btnNew) {
			el.btnNew.disabled = !(online && canCreate);
			el.btnNew.title = !online ? 'Unavailable while offline'
				: (isShared ? 'Shared images is read-only. Adding or modifying folders is disabled.'
				: (canCreate ? 'Create a folder here' : 'Folders can only be created inside images or documents (or below)'));
		}
		if (el.btnUpload) {
			el.btnUpload.disabled = !(online && canUpload);
			el.btnUpload.title = !online ? 'Unavailable while offline'
				: (isShared ? 'Shared images is read-only. Uploading files is disabled.'
				: (canUpload ? 'Upload file to this folder' : 'Select a folder to upload files'));
		}
		if (el.btnCreate) el.btnCreate.disabled = !online || isShared;
		if (el.btnDoUpload) el.btnDoUpload.disabled = !online || isShared;
		if (!canCreate) closeNew();
		if (!canUpload) closeUpload();
	}

	// ------------------------------------------------------------------
	// Selection & Keyboard
	// ------------------------------------------------------------------
	function setSelected(name, focus) {
		state.selected = name;
		disarmDelete(true);
		var nodes = el.items.querySelectorAll('.item');
		nodes.forEach(function (n) {
			var it = state.shown[Number(n.getAttribute('data-idx'))];
			var sel = !!it && it.name === name;
			n.setAttribute('aria-selected', sel ? 'true' : 'false');
			n.tabIndex = sel ? 0 : -1;
			if (sel && focus) n.focus();
		});
		if (!name && nodes.length) nodes[0].tabIndex = 0;
		renderDetails();
	}

	function focusSelected() {
		var n = el.items.querySelector('.item[aria-selected="true"]');
		if (n) { n.focus(); n.scrollIntoView({ block: 'nearest' }); }
	}

	function selectForPicker(it) {
		if (!it || it.type === 'dir') return;
		var fp = itemPath(it);
		var webUrl = webHref(fp);
		var isSharedPhoto = fp.toLowerCase().indexOf('shared images/') >= 0;
		if (isSharedPhoto) {
			var relShared = fp.substring(fp.toLowerCase().indexOf('shared images/') + 14);
			webUrl = getAssetsBaseUrl() + '/shared%20images/' + relShared.split('/').map(encodeURIComponent).join('/');
		}
		var baseTitle = it.title || it.name.replace(/\.[^.]+$/, '').replace(/[-_]+/g, ' ').trim() || it.name;
		var altText = it.altText || it.alt_text || baseTitle;
		var ext = (it.ext || it.name.split('.').pop() || 'FILE').toUpperCase();
		var sizeStr = fmtSize(it.size);
		var isImg = IMAGE_EXT.indexOf((it.ext || '').toLowerCase()) >= 0;
		var htmlSnippet = '';

		if (isImg) {
			htmlSnippet = '<img src="' + esc(webUrl) + '" alt="' + esc(altText) + '" title="' + esc(baseTitle) + '" style="max-width:100%; height:auto;" loading="lazy">';
		} else {
			var adaNotice = baseTitle + ' (' + ext + ', opens in a new tab)';
			htmlSnippet = '<a href="' + esc(webUrl) + '" class="document-download-link" target="_blank" rel="noopener noreferrer" aria-label="' + esc(adaNotice) + '" title="' + esc(adaNotice) + '">' + esc(baseTitle) + ' (' + esc(ext) + ', ' + esc(sizeStr) + ')</a>';
		}

		var payload = {
			html: htmlSnippet,
			url: webUrl,
			title: baseTitle,
			alt: altText,
			data: {
				id: it.id || null,
				name: it.name,
				title: baseTitle,
				altText: altText,
				caption: it.caption || '',
				credit: it.credit || '',
				tags: it.tags || '',
				fileHash: it.fileHash || it.hash || '',
				width: it.width || null,
				height: it.height || null,
				isWcagCompliant: it.isWcagCompliant,
				webUrl: webUrl,
				size: sizeStr,
				sizeFormatted: sizeStr,
				isImage: isImg
			}
		};

		if (window.parent && state.pickerCallback && typeof window.parent[state.pickerCallback] === 'function') {
			window.parent[state.pickerCallback](payload);
			return;
		}
		if (window.opener) {
			try {
				if (state.targetInput && window.opener.document) {
					var targetEl = window.opener.document.getElementById(state.targetInput);
					if (targetEl) targetEl.value = webUrl;
				}
				window.opener.postMessage({ type: 'cmsMediaSelected', url: webUrl, title: baseTitle, targetInput: state.targetInput }, '*');
			} catch (e) {}
			window.close();
			return;
		}
		if (window.parent && window.parent !== window) {
			window.parent.postMessage({
				type: 'CMS_MEDIA_SELECTED',
				html: htmlSnippet,
				url: webUrl,
				title: baseTitle,
				alt: altText,
				altText: altText,
				data: payload.data
			}, '*');
			window.parent.postMessage({
				type: 'cmsMediaSelected',
				url: webUrl,
				title: baseTitle,
				alt: altText,
				altText: altText,
				targetInput: state.targetInput,
				data: payload.data
			}, '*');
		}
	}

	function openItem(it) {
		if (!it) return;
		if (it.type === 'dir') {
			navigate(itemPath(it));
		} else if (state.pickerMode || state.pickerCallback || state.targetInput) {
			selectForPicker(it);
		} else {
			window.open(webHref(itemPath(it)), '_blank', 'noopener');
		}
	}

	function gridColumns() {
		var g = el.items.querySelector('.grid');
		if (!g) return 1;
		var cols = getComputedStyle(g).gridTemplateColumns.split(' ').filter(Boolean).length;
		return Math.max(1, cols);
	}

	el.items.addEventListener('click', function (e) {
		var selBtn = e.target.closest('[data-act="select-card-file"]');
		if (selBtn) {
			e.stopPropagation();
			var itCard = state.shown[Number(selBtn.getAttribute('data-idx'))];
			if (itCard) selectForPicker(itCard);
			return;
		}
		var b = e.target.closest('[data-path]');
		if (b && b.tagName === 'BUTTON') { navigate(b.getAttribute('data-path')); return; }
		var n = e.target.closest('.item');
		if (!n) return;
		var it = state.shown[Number(n.getAttribute('data-idx'))];
		if (it) setSelected(it.name, true);
	});

	el.items.addEventListener('dblclick', function (e) {
		var n = e.target.closest('.item');
		if (!n) return;
		openItem(state.shown[Number(n.getAttribute('data-idx'))]);
	});

	el.items.addEventListener('keydown', function (e) {
		var n = e.target.closest('.item');
		if (!n) return;
		var idx = Number(n.getAttribute('data-idx'));
		var len = state.shown.length;
		var cols = state.view === 'grid' ? gridColumns() : 1;

		if (e.key === 'Enter') {
			e.preventDefault();
			openItem(state.shown[idx]);
		} else if (e.key === 'ArrowRight') {
			e.preventDefault();
			if (idx + 1 < len) setSelected(state.shown[idx + 1].name, true);
		} else if (e.key === 'ArrowLeft') {
			e.preventDefault();
			if (idx - 1 >= 0) setSelected(state.shown[idx - 1].name, true);
		} else if (e.key === 'ArrowDown') {
			e.preventDefault();
			if (idx + cols < len) setSelected(state.shown[idx + cols].name, true);
		} else if (e.key === 'ArrowUp') {
			e.preventDefault();
			if (idx - cols >= 0) setSelected(state.shown[idx - cols].name, true);
		} else if (e.key === 'Home') {
			e.preventDefault();
			if (len) setSelected(state.shown[0].name, true);
		} else if (e.key === 'End') {
			e.preventDefault();
			if (len) setSelected(state.shown[len - 1].name, true);
		} else if (e.key === 'Escape') {
			setSelected(null, false);
		}
	});

	// Details Actions
	if (el.details) {
		el.details.addEventListener('click', async function (e) {
			var b = e.target.closest('[data-act]');
			if (!b) return;
			var act = b.getAttribute('data-act');
			var it = selectedItem();

			if (act === 'select-file') {
				if (it) selectForPicker(it);
			} else if (act === 'open') {
				if (it) openItem(it);
			} else if (act === 'upload') {
				if (!it) openUpload();
				else { state.pendingUpload = true; navigate(itemPath(it)); }
			} else if (act === 'copy') {
				if (it) {
					var url = webPath(itemPath(it), false);
					try {
						await navigator.clipboard.writeText(url);
						toast('Web link copied.');
					} catch (err) {
						toast('Could not copy link.', true);
					}
				}
			} else if (act === 'new') {
				if (!it) openNew();
				else { state.pendingNew = true; navigate(itemPath(it)); }
			} else if (act === 'delete') {
				var p = b.getAttribute('data-path');
				handleDelete(p);
			} else if (act === 'edit-meta') {
				if (it) openEditMetaModal(it);
			} else if (act === 'crawl-folder') {
				var crawlRel = b.getAttribute('data-path') || (it ? itemPath(it) : state.path);
				openCrawlModal(diskPath(crawlRel, false));
			}
		});
	}

	// ------------------------------------------------------------------
	// Two-Step Delete
	// ------------------------------------------------------------------
	function disarmDelete(silent) {
		if (state.armed) {
			clearTimeout(state.armed.timer);
			state.armed = null;
			if (!silent) renderDetails();
		}
	}

	async function handleDelete(targetPath) {
		if (!targetPath) return;
		if (state.online !== true) { toast('Unavailable while offline.', true); return; }

		if (!state.armed || state.armed.path !== targetPath) {
			disarmDelete(true);
			state.armed = {
				path: targetPath,
				timer: setTimeout(function () {
					state.armed = null;
					renderDetails();
				}, CONFIRM_MS)
			};
			renderDetails();
			return;
		}

		clearTimeout(state.armed.timer);
		state.armed = null;

		var deletedName = segs(targetPath).slice(-1)[0];
		var r = await api('deleteFolder', { path: targetPath, ws: state.ws || '' }, 'POST');
		if (!r.ok) {
			toast(r.error || 'Could not delete folder.', true);
			renderDetails();
			return;
		}

		toast('Folder "' + deletedName + '" deleted.');
		if (state.path.toLowerCase() === targetPath.toLowerCase()) {
			var parent = parentOf(targetPath);
			if (state.ws && (!parent || parent.length < state.ws.length)) parent = state.ws;
			navigate(parent);
		} else {
			await load(state.path);
		}
	}

	// ------------------------------------------------------------------
	// Inline New Folder Form
	// ------------------------------------------------------------------
	var newTouched = false;
	function openNew() {
		if (state.depth < state.cfg.systemDepth) return;
		newTouched = false;
		el.newPanel.hidden = false;
		el.newName.value = '';
		el.newError.textContent = '';
		el.newName.removeAttribute('aria-invalid');
		updateNewPreview();
		el.newName.focus();
	}

	function closeNew(focusButton) {
		if (el.newPanel.hidden) return;
		el.newPanel.hidden = true;
		el.newName.value = '';
		el.newError.textContent = '';
		el.newName.removeAttribute('aria-invalid');
		if (focusButton && el.btnNew) el.btnNew.focus();
	}

	function updateNewPreview() {
		var name = el.newName.value.trim();
		el.newPreview.textContent = 'Will create: ' + diskPath(state.path, true) + (name || '\u2026') + '\\';
		var err = name || newTouched ? validateName(name) : '';
		el.newError.textContent = err;
		if (err) el.newName.setAttribute('aria-invalid', 'true'); else el.newName.removeAttribute('aria-invalid');
		return validateName(name);
	}

	el.newName.addEventListener('input', function () { newTouched = true; updateNewPreview(); });
	el.newName.addEventListener('keydown', function (e) { if (e.key === 'Escape') { e.preventDefault(); closeNew(true); } });
	el.newPanel.addEventListener('keydown', function (e) { if (e.key === 'Escape') { e.preventDefault(); closeNew(true); } });
	el.btnCancel.addEventListener('click', function () { closeNew(true); });

	el.newPanel.addEventListener('submit', async function (e) {
		e.preventDefault();
		newTouched = true;
		var name = el.newName.value.trim();
		var err = updateNewPreview();
		if (err) { el.newName.focus(); return; }
		if (state.online !== true) { el.newError.textContent = 'Unavailable while offline.'; return; }

		el.btnCreate.disabled = true;
		var r = await api('createFolder', { path: state.path, name: name, ws: state.ws || '' }, 'POST');
		el.btnCreate.disabled = state.online !== true;

		if (!r.ok) {
			el.newError.textContent = r.error || 'Could not create the folder.';
			el.newName.setAttribute('aria-invalid', 'true');
			el.newName.focus();
			return;
		}
		closeNew(false);
		toast('Folder "' + name + '" created.');
		await load(state.path, name);
	});

	// ------------------------------------------------------------------
	// Inline Upload File
	// ------------------------------------------------------------------
	function resetFileSelection() {
		if (el.uploadFile) el.uploadFile.value = '';
		if (el.selectedCard) el.selectedCard.hidden = true;
		if (el.dropzonePrompt) el.dropzonePrompt.hidden = false;
		if (el.selectedThumb) el.selectedThumb.innerHTML = '';
		if (el.selectedName) el.selectedName.textContent = '';
		if (el.selectedMeta) el.selectedMeta.textContent = '';
		if (el.btnDoUploadSpinner) {
			el.btnDoUploadSpinner.hidden = true;
			el.btnDoUploadSpinner.style.setProperty('display', 'none', 'important');
		}
		if (el.btnDoUploadIcon) {
			el.btnDoUploadIcon.hidden = false;
			el.btnDoUploadIcon.style.removeProperty('display');
		}
		if (el.btnDoUploadText) el.btnDoUploadText.textContent = 'Upload Now';
		if (el.uploadTargetUrl) {
			var p = state.path || state.ws || '';
			el.uploadTargetUrl.value = '';
			el.uploadTargetUrl.placeholder = webPath(p, true) + 'photo.jpg';
		}
		state.lastUploadOcr = null;
		var ocrBadge = $('upload-ocr-status-badge');
		if (ocrBadge) { ocrBadge.hidden = true; ocrBadge.innerHTML = ''; }
		showUploadError('');
	}

	function ensureUploadOcrBadge() {
		var badge = $('upload-ocr-status-badge');
		if (!badge && el.uploadAlt && el.uploadAlt.parentNode) {
			badge = document.createElement('div');
			badge.id = 'upload-ocr-status-badge';
			badge.hidden = true;
			badge.style.cssText = 'margin-top:0.35rem; font-size:0.76rem; padding:0.35rem 0.65rem; border-radius:6px; display:flex; align-items:center; gap:0.4rem; line-height:1.35;';
			el.uploadAlt.parentNode.insertBefore(badge, el.uploadAlt.nextSibling);
		}
		return badge;
	}

	async function runUploadOcrPrefill(file) {
		if (!file) return;
		var badge = ensureUploadOcrBadge();
		if (badge) {
			badge.hidden = false;
			badge.style.background = '#f0f9ff';
			badge.style.border = '1px solid #bae6fd';
			badge.style.color = '#0369a1';
			badge.innerHTML = '<span>Running OCR &amp; visual content detection to auto-fill Alt Text &amp; Title&hellip;</span>';
		}
		try {
			var p = state.path || state.ws || '';
			var segList = segs(p);
			var ws = segList.length > 0 ? segList[0] : (state.ws || '');
			var sub = segList.length > 1 ? segList.slice(1).join('/') : 'images';

			var fd = new FormData();
			fd.append('mediaFile', file);
			fd.append('ws', ws);
			fd.append('subfolder', sub);

			var res = await fetch('/api/Files.cfc?method=analyzeUploadOcr&returnformat=json', {
				method: 'POST',
				headers: { 'X-Requested-With': 'FileExplorer' },
				body: fd
			});
			var raw = await res.text();
			var data = parseJSON(raw);
			if (!data || data.ok !== true) {
				if (badge) badge.hidden = true;
				return;
			}

			state.lastUploadOcr = data;
			if (el.uploadTitle && data.title) {
				el.uploadTitle.value = data.title;
			}
			if (el.uploadAlt && data.altText) {
				el.uploadAlt.value = data.altText;
				el.uploadAlt.style.borderColor = '#16a34a';
				el.uploadAlt.style.boxShadow = '0 0 0 3px rgba(22, 163, 74, 0.12)';
			}
			if (badge) {
				badge.hidden = false;
				badge.style.background = '#f0fdf4';
				badge.style.border = '1px solid #bbf7d0';
				badge.style.color = '#166534';
				var ocrSnippet = data.ocrText ? (' &bull; OCR Text: <strong class="mono">&ldquo;' + esc(data.ocrText) + '&rdquo;</strong>') : '';
				var toneSnippet = data.visualTone ? (' &bull; ' + esc((data.width && data.height ? data.width + '\u00d7' + data.height + ' ' : '') + data.visualTone)) : '';
				badge.innerHTML = '<span><strong>Auto-filled via OCR &amp; Content Detection</strong>' + ocrSnippet + toneSnippet + '</span>';
			}
		} catch (err) {
			if (badge) badge.hidden = true;
		}
	}

	function handleFileSelected(file) {
		if (!file) {
			resetFileSelection();
			return;
		}

		var clean = file.name.replace(/\.[^/.]+$/, '').replace(/[-_]+/g, ' ').trim();
		if (el.uploadTitle) {
			el.uploadTitle.value = clean.charAt(0).toUpperCase() + clean.slice(1);
		}

		var ext = file.name.split('.').pop().toLowerCase();
		var isImg = IMAGE_EXT.indexOf(ext) >= 0;
		var reqBadge = $('upload-alt-required-badge');

		if (el.uploadAlt) {
			el.uploadAlt.value = '';
			if (isImg) {
				el.uploadAlt.required = true;
				if (reqBadge) reqBadge.style.display = 'inline';
				el.uploadAlt.placeholder = 'Analyzing "' + file.name + '" via OCR & visual content detection...';
			} else {
				el.uploadAlt.required = false;
				if (reqBadge) reqBadge.style.display = 'none';
				el.uploadAlt.placeholder = 'Optional description (not an image)...';
			}
		}

		if (isImg) {
			runUploadOcrPrefill(file);
		} else {
			var badge = $('upload-ocr-status-badge');
			if (badge) badge.hidden = true;
		}

		if (el.selectedName) el.selectedName.textContent = file.name;
		if (el.selectedMeta) {
			var kind = fileKind(ext);
			el.selectedMeta.textContent = fmtSize(file.size) + ' \u2022 ' + kind.label;
		}

		if (el.selectedThumb) {
			if (isImg && window.FileReader) {
				var reader = new FileReader();
				reader.onload = function (e) {
					if (el.selectedThumb) {
						el.selectedThumb.innerHTML = '<img src="' + esc(e.target.result) + '" alt="' + esc(file.name) + '">';
					}
				};
				reader.readAsDataURL(file);
			} else {
				el.selectedThumb.innerHTML = '<svg viewBox="0 0 24 24" style="width:24px;height:24px;stroke:currentColor;fill:none;stroke-width:2;"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>';
			}
		}

		if (el.dropzonePrompt) el.dropzonePrompt.hidden = true;
		if (el.selectedCard) el.selectedCard.hidden = false;
		if (el.uploadTargetUrl) {
			var p = state.path || state.ws || '';
			el.uploadTargetUrl.value = webPath(p, true) + file.name;
		}
		showUploadError('');
	}

	function showUploadError(msg) {
		if (!el.uploadError) return;
		if (!msg) {
			el.uploadError.textContent = '';
			el.uploadError.hidden = true;
			el.uploadError.style.display = 'none';
		} else {
			el.uploadError.hidden = false;
			el.uploadError.innerHTML = '<svg viewBox="0 0 24 24" style="width:16px;height:16px;stroke:currentColor;stroke-width:2;fill:none;flex-shrink:0;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg><span>' + esc(msg) + '</span>';
			el.uploadError.style.display = 'flex';
		}
	}

	function openUpload() {
		var isShared = (state.path && state.path.toLowerCase().indexOf('shared images') >= 0);
		if (isShared || !el.uploadPanel) return;
		closeNew();
		el.uploadPanel.hidden = false;
		resetFileSelection();
		if (el.uploadTitle) el.uploadTitle.value = '';
		if (el.uploadAlt) el.uploadAlt.value = '';
		updateUploadPreview();
		if (el.uploadFile) el.uploadFile.focus();
	}

	function closeUpload(focusButton) {
		if (!el.uploadPanel || el.uploadPanel.hidden) return;
		el.uploadPanel.hidden = true;
		resetFileSelection();
		if (el.uploadTitle) el.uploadTitle.value = '';
		if (el.uploadAlt) el.uploadAlt.value = '';
		if (focusButton && el.btnUpload) el.btnUpload.focus();
	}

	function updateUploadPreview() {
		if (!el.uploadPreview) return;
		var isShared = (state.path && state.path.toLowerCase().indexOf('shared images') >= 0);
		if (isShared) {
			el.uploadPreview.textContent = 'Shared library is read-only. Uploading disabled.';
			if (el.btnDoUpload) el.btnDoUpload.disabled = true;
			return;
		}
		var p = state.path || state.ws || '';
		el.uploadPreview.textContent = 'Storage: ' + diskPath(p, true) + ' \u2022 Web URL: ' + webPath(p, true);
		if (el.uploadTargetUrl) {
			var fName = (el.uploadFile && el.uploadFile.files && el.uploadFile.files[0]) ? el.uploadFile.files[0].name : '';
			if (fName) {
				el.uploadTargetUrl.value = webPath(p, true) + fName;
			} else {
				el.uploadTargetUrl.value = '';
				el.uploadTargetUrl.placeholder = webPath(p, true) + 'photo.jpg';
			}
		}
		if (el.btnDoUpload) el.btnDoUpload.disabled = state.online !== true;
		if (el.linkFullStudio) {
			var segList = segs(p);
			var ws = segList.length > 0 ? segList[0] : (state.ws || '');
			var sub = segList.length > 1 ? segList.slice(1).join('/') : '';
			el.linkFullStudio.href = '/media/upload?ws=' + encodeURIComponent(ws) + (sub ? '&folder=' + encodeURIComponent(sub) : '');
		}
	}

	if (el.uploadFile) {
		el.uploadFile.addEventListener('change', function () {
			if (this.files && this.files[0]) {
				handleFileSelected(this.files[0]);
			} else {
				resetFileSelection();
			}
		});
		el.uploadFile.addEventListener('keydown', function (e) {
			if (e.key === 'Escape') { e.preventDefault(); closeUpload(true); }
		});
	}

	if (el.btnBrowseFile) {
		el.btnBrowseFile.addEventListener('click', function (e) {
			e.preventDefault();
			if (el.uploadFile) el.uploadFile.click();
		});
	}

	if (el.uploadDropzone) {
		['dragenter', 'dragover'].forEach(function (eventName) {
			el.uploadDropzone.addEventListener(eventName, function (e) {
				e.preventDefault();
				e.stopPropagation();
				el.uploadDropzone.classList.add('is-dragover');
			});
		});
		['dragleave', 'dragend', 'drop'].forEach(function (eventName) {
			el.uploadDropzone.addEventListener(eventName, function (e) {
				e.preventDefault();
				e.stopPropagation();
				el.uploadDropzone.classList.remove('is-dragover');
			});
		});
		el.uploadDropzone.addEventListener('drop', function (e) {
			if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length) {
				el.uploadFile.files = e.dataTransfer.files;
				handleFileSelected(e.dataTransfer.files[0]);
			}
		});
	}

	if (el.btnRemoveFile) {
		el.btnRemoveFile.addEventListener('click', function (e) {
			e.preventDefault();
			e.stopPropagation();
			resetFileSelection();
			if (el.uploadFile) el.uploadFile.focus();
		});
	}

	if (el.btnCloseUploadIcon) {
		el.btnCloseUploadIcon.addEventListener('click', function () {
			closeUpload(true);
		});
	}

	if (el.uploadPanel) {
		el.uploadPanel.addEventListener('keydown', function (e) {
			if (e.key === 'Escape') { e.preventDefault(); closeUpload(true); }
		});
	}

	if (el.btnUploadCancel) {
		el.btnUploadCancel.addEventListener('click', function () { closeUpload(true); });
	}

	if (el.uploadPanel) {
		el.uploadPanel.addEventListener('submit', async function (e) {
			e.preventDefault();
			if (!el.uploadFile || !el.uploadFile.files || !el.uploadFile.files[0]) {
				showUploadError('Please choose or drop a file to upload.');
				return;
			}
			if (state.online !== true) {
				showUploadError('Unavailable while offline.');
				return;
			}
			var f = el.uploadFile.files[0];
			var ext = (f.name.split('.').pop() || '').toLowerCase();
			var isImg = IMAGE_EXT.indexOf(ext) >= 0;
			var altVal = (el.uploadAlt && el.uploadAlt.value) ? el.uploadAlt.value.trim() : '';

			// Strict ADA WCAG 2.1 AA requirement (WCAG 1.1.1):
			if (isImg && !altVal) {
				showUploadError('WCAG 1.1.1 Requirement: Alternative Text (Image Description) is mandatory for all images. Please describe the image for screen readers.');
				if (el.uploadAlt) {
					el.uploadAlt.style.borderColor = 'var(--admin-danger, #ef4444)';
					el.uploadAlt.style.boxShadow = '0 0 0 3px rgba(239, 68, 68, 0.2)';
					el.uploadAlt.focus();
				}
				return;
			}

			// Reject generic placeholder alt text
			if (isImg) {
				var lowerAlt = altVal.toLowerCase();
				var generic = ['image', 'photo', 'picture', 'graphic', 'img', 'pic', 'file', 'screenshot'];
				if (generic.indexOf(lowerAlt) >= 0 || lowerAlt.slice(-4) === '.jpg' || lowerAlt.slice(-4) === '.png' || lowerAlt.slice(-5) === '.webp') {
					showUploadError('Generic alt text like "' + esc(altVal) + '" or filenames are not permitted. Please describe the visual content.');
					if (el.uploadAlt) {
						el.uploadAlt.style.borderColor = 'var(--admin-danger, #ef4444)';
						el.uploadAlt.style.boxShadow = '0 0 0 3px rgba(239, 68, 68, 0.2)';
						el.uploadAlt.focus();
					}
					return;
				}
			}

			var fd = new FormData();
			fd.append('mediaFile', f);
			var p = state.path || state.ws || '';
			var segList = segs(p);
			var ws = segList.length > 0 ? segList[0] : (state.ws || '');
			var sub = segList.length > 1 ? segList.slice(1).join('/') : (state.pickerMode === 'document' ? 'documents' : 'images');
			fd.append('workspace', ws);
			fd.append('subfolder', sub);
			fd.append('path', p);
			if (el.uploadTitle && el.uploadTitle.value.trim()) fd.append('title', el.uploadTitle.value.trim());
			if (altVal) fd.append('altText', altVal);
			if (state.lastUploadOcr) {
				if (state.lastUploadOcr.ocrText) fd.append('ocrText', state.lastUploadOcr.ocrText);
				if (state.lastUploadOcr.caption) fd.append('caption', state.lastUploadOcr.caption);
				if (state.lastUploadOcr.credit) fd.append('credit', state.lastUploadOcr.credit);
				if (state.lastUploadOcr.tags) fd.append('tags', state.lastUploadOcr.tags);
			}
			fd.append('format', 'json');

			if (el.btnDoUpload) el.btnDoUpload.disabled = true;
			if (el.btnDoUploadSpinner) {
				el.btnDoUploadSpinner.hidden = false;
				el.btnDoUploadSpinner.style.setProperty('display', 'inline-block', 'important');
			}
			if (el.btnDoUploadIcon) {
				el.btnDoUploadIcon.hidden = true;
				el.btnDoUploadIcon.style.setProperty('display', 'none', 'important');
			}
			if (el.btnDoUploadText) el.btnDoUploadText.textContent = 'Uploading\u2026';
			showUploadError('');

			try {
				var uploadUrl = '/media/upload?format=json';
				var res = await fetch(uploadUrl, {
					method: 'POST',
					headers: {
						'X-Requested-With': 'XMLHttpRequest'
					},
					body: fd
				});

				// Fallback to /media/processUpload if needed
				if (res.status === 404 || res.status === 405) {
					res = await fetch('/media/processUpload?format=json', {
						method: 'POST',
						headers: {
							'X-Requested-With': 'XMLHttpRequest'
						},
						body: fd
					});
				}

				if (el.btnDoUpload) el.btnDoUpload.disabled = false;
				if (el.btnDoUploadSpinner) {
					el.btnDoUploadSpinner.hidden = true;
					el.btnDoUploadSpinner.style.setProperty('display', 'none', 'important');
				}
				if (el.btnDoUploadIcon) {
					el.btnDoUploadIcon.hidden = false;
					el.btnDoUploadIcon.style.removeProperty('display');
				}
				if (el.btnDoUploadText) el.btnDoUploadText.textContent = 'Upload Now';

				if (res.status === 401) {
					showUploadError('Session has expired. Please refresh the page and sign in.');
					return;
				}

				var data = null;
				try {
					data = await res.json();
				} catch (jsonErr) {
					var raw = await res.text().catch(function () { return ''; });
					showUploadError(raw.indexOf('<!DOCTYPE') >= 0 ? 'Server returned an error (HTTP ' + res.status + ').' : (raw.slice(0, 150) || 'Upload failed.'));
					return;
				}

				if (data && data.REDIRECT && (data.SUCCESS === false || data.success === false)) {
					showUploadError((data.MESSAGE || data.message || 'Session expired.') + ' Please refresh and log in.');
					return;
				}

				var isSuccess = data && (data.success === true || data.SUCCESS === true);
				var msg = data && (data.message || data.MESSAGE);
				if (!isSuccess) {
					showUploadError(msg || 'Upload failed.');
					return;
				}

				closeUpload(false);
				var fileObj = data && (data.file || data.FILE);
				var uploadedName = (fileObj && (fileObj.name || fileObj.NAME)) ? (fileObj.name || fileObj.NAME) : f.name;
				toast('File "' + uploadedName + '" uploaded successfully.');
				await load(state.path, uploadedName);
			} catch (err) {
				if (el.btnDoUpload) el.btnDoUpload.disabled = false;
				if (el.btnDoUploadSpinner) {
					el.btnDoUploadSpinner.hidden = true;
					el.btnDoUploadSpinner.style.setProperty('display', 'none', 'important');
				}
				if (el.btnDoUploadIcon) {
					el.btnDoUploadIcon.hidden = false;
					el.btnDoUploadIcon.style.removeProperty('display');
				}
				if (el.btnDoUploadText) el.btnDoUploadText.textContent = 'Upload Now';
				showUploadError('Upload failed: ' + (err.message || 'Network error'));
			}
		});
	}

	// ------------------------------------------------------------------
	// Toolbar, Tree, Breadcrumbs
	// ------------------------------------------------------------------
	if (el.btnUpload) {
		el.btnUpload.addEventListener('click', function () {
			if (el.uploadPanel && el.uploadPanel.hidden) openUpload();
			else if (el.uploadFile) el.uploadFile.focus();
		});
	}

	el.btnNew.addEventListener('click', function () {
		closeUpload();
		if (el.newPanel.hidden) openNew(); else el.newName.focus();
	});

	el.up.addEventListener('click', function () {
		if (state.path.toLowerCase() === 'shared images') {
			navigate(state.ws || '');
			return;
		}
		if (state.ws && state.path.toLowerCase() === state.ws.toLowerCase()) {
			return; // At workspace root, cannot go higher
		}
		if (state.path) {
			var parent = parentOf(state.path);
			if (state.ws && (!parent || parent.length < state.ws.length)) parent = state.ws;
			navigate(parent, segs(state.path).slice(-1)[0]);
		}
	});

	el.tree.addEventListener('click', function (e) {
		var b = e.target.closest('[data-path]');
		if (b) navigate(b.getAttribute('data-path'));
	});

	el.crumbs.addEventListener('click', function (e) {
		var b = e.target.closest('button[data-path]');
		if (b) navigate(b.getAttribute('data-path'));
	});

	el.filter.addEventListener('input', function () {
		state.filter = el.filter.value;
		applyFilter();
		renderItems();
		renderDetails();
	});
	el.filter.addEventListener('keydown', function (e) {
		if (e.key === 'Escape' && el.filter.value) { e.preventDefault(); el.filter.value = ''; state.filter = ''; applyFilter(); renderItems(); }
	});

	function setView(v) {
		state.view = v === 'list' ? 'list' : 'grid';
		el.btnGrid.setAttribute('aria-pressed', state.view === 'grid' ? 'true' : 'false');
		el.btnList.setAttribute('aria-pressed', state.view === 'list' ? 'true' : 'false');
		lsSet(VIEW_KEY, state.view);
		renderItems();
	}
	el.btnGrid.addEventListener('click', function () { setView('grid'); });
	el.btnList.addEventListener('click', function () { setView('list'); });

	if (el.retry) el.retry.addEventListener('click', function () { ping(true); });

	el.content.addEventListener('click', function (e) {
		if (!e.target.closest('.item') && !e.target.closest('button') && state.selected) setSelected(null, false);
	});

	// Handle workspace change event from CMSAdmin 2.0 navigation
	window.addEventListener('cmsadmin:workspaceChanged', function (e) {
		if (e.detail && (e.detail.storageFolder || e.detail.virtualDir || e.detail.id)) {
			var newWs = e.detail.storageFolder || e.detail.virtualDir || e.detail.id;
			state.ws = newWs;
			state.wsName = e.detail.name || friendly(newWs);
			if (e.detail.assetsDomain) state.assetsDomain = e.detail.assetsDomain;
			if (e.detail.assetsProtocol) state.assetsProtocol = e.detail.assetsProtocol;
			if (el.webRoot) el.webRoot.textContent = getAssetsBaseUrl() + '/' + state.ws + '/';
			navigate(newWs);
		}
	});

	// ------------------------------------------------------------------
	// Metadata & WCAG Accessibility Editor Modal
	// ------------------------------------------------------------------
	function openEditMetaModal(it) {
		if (!it || !el.editMetaModal) return;
		var fp = itemPath(it);
		if (fp.toLowerCase().indexOf('shared images') >= 0) {
			toast('Shared stock photos are read-only.', true);
			return;
		}
		var isImg = fileKind(it.ext).cls === 'image';
		if (el.editMetaId) el.editMetaId.value = it.id || '';
		if (el.editMetaPath) el.editMetaPath.value = fp;
		if (el.editMetaFilename) el.editMetaFilename.textContent = it.name;
		if (el.editMetaFileinfo) el.editMetaFileinfo.textContent = fmtSize(it.size) + (it.width && it.height ? ' \u2022 ' + it.width + ' \u00d7 ' + it.height + ' px' : '');

		if (el.editMetaThumb) {
			if (isImg) {
				el.editMetaThumb.innerHTML = '<img src="' + esc(webHref(fp)) + '" data-local-src="' + esc(localHref(fp)) + '" onerror="if(this.dataset.localSrc && this.src !== this.dataset.localSrc){var l=this.dataset.localSrc;delete this.dataset.localSrc;this.src=l;}" alt="" style="width:100%; height:100%; object-fit:cover;">';
			} else {
				el.editMetaThumb.innerHTML = svg('file', 't-file');
			}
		}

		var isCompliant = (it.isWcagCompliant === true) || (!isImg) || Boolean(it.altText && it.altText.trim());
		if (el.editMetaWcagBadge) {
			if (isImg) {
				if (isCompliant) {
					el.editMetaWcagBadge.innerHTML = '<span style="display:inline-flex; align-items:center; gap:4px; padding:2px 8px; font-size:11px; font-weight:600; background:#dcfce7; color:#166534; border-radius:12px;">' + svg('check', '') + ' WCAG Compliant</span>';
				} else {
					el.editMetaWcagBadge.innerHTML = '<span style="display:inline-flex; align-items:center; gap:4px; padding:2px 8px; font-size:11px; font-weight:600; background:#fee2e2; color:#991b1b; border-radius:12px;">' + svg('alert', '') + ' Alt Text Missing (WCAG 1.1.1)</span>';
				}
			} else {
				el.editMetaWcagBadge.innerHTML = '';
			}
		}

		if (el.editMetaAlt) {
			el.editMetaAlt.value = it.altText || '';
			el.editMetaAlt.style.borderColor = '';
			el.editMetaAlt.style.boxShadow = '';
		}
		if (el.editMetaAltChar) {
			var len = (it.altText || '').length;
			el.editMetaAltChar.textContent = len + ' / 150 rec.';
			el.editMetaAltChar.style.color = len > 150 ? 'var(--admin-warning, #d97706)' : 'var(--admin-text-muted)';
		}
		if (el.editMetaTitle) el.editMetaTitle.value = it.title || '';
		if (el.editMetaCaption) el.editMetaCaption.value = it.caption || '';
		if (el.editMetaCredit) el.editMetaCredit.value = it.credit || '';
		if (el.editMetaTags) el.editMetaTags.value = it.tags || '';

		if (el.editMetaError) {
			el.editMetaError.hidden = true;
			el.editMetaError.textContent = '';
		}

		el.editMetaModal.hidden = false;
		el.editMetaModal.style.display = 'flex';
		if (el.editMetaAlt) el.editMetaAlt.focus();
	}

	function closeEditMetaModal() {
		if (!el.editMetaModal) return;
		el.editMetaModal.hidden = true;
		el.editMetaModal.style.display = 'none';
	}

	if (el.btnCloseEditMeta) el.btnCloseEditMeta.addEventListener('click', closeEditMetaModal);
	if (el.btnCancelEditMeta) el.btnCancelEditMeta.addEventListener('click', closeEditMetaModal);
	if (el.editMetaModal) {
		el.editMetaModal.addEventListener('click', function (e) {
			if (e.target === el.editMetaModal) closeEditMetaModal();
		});
		el.editMetaModal.addEventListener('keydown', function (e) {
			if (e.key === 'Escape') closeEditMetaModal();
		});
	}

	if (el.editMetaAlt) {
		el.editMetaAlt.addEventListener('input', function () {
			var len = this.value.length;
			if (el.editMetaAltChar) {
				el.editMetaAltChar.textContent = len + ' / 150 rec.';
				el.editMetaAltChar.style.color = len > 150 ? 'var(--admin-warning, #d97706)' : 'var(--admin-text-muted)';
			}
			if (this.value.trim().length > 0) {
				this.style.borderColor = '';
				this.style.boxShadow = '';
				if (el.editMetaError) el.editMetaError.hidden = true;
			}
		});
	}

	if (el.editMetaForm) {
		el.editMetaForm.addEventListener('submit', async function (e) {
			e.preventDefault();
			var it = selectedItem();
			var isImg = it ? fileKind(it.ext).cls === 'image' : true;
			var altVal = el.editMetaAlt ? el.editMetaAlt.value.trim() : '';

			// Strict WCAG validation
			if (isImg && !altVal) {
				if (el.editMetaError) {
					el.editMetaError.hidden = false;
					el.editMetaError.textContent = 'WCAG 1.1.1 Requirement: Alternative Text is mandatory for all images under County ADA policy. Please describe the image.';
				}
				el.editMetaAlt.style.borderColor = 'var(--admin-danger, #ef4444)';
				el.editMetaAlt.style.boxShadow = '0 0 0 3px rgba(239, 68, 68, 0.2)';
				el.editMetaAlt.focus();
				return;
			}

			// Reject generic alt text
			if (isImg) {
				var lower = altVal.toLowerCase();
				var generic = ['image', 'photo', 'picture', 'graphic', 'img', 'pic', 'file', 'screenshot'];
				if (generic.indexOf(lower) >= 0 || lower.slice(-4) === '.jpg' || lower.slice(-4) === '.png' || lower.slice(-5) === '.webp') {
					if (el.editMetaError) {
						el.editMetaError.hidden = false;
						el.editMetaError.textContent = 'Generic alt text like "' + esc(altVal) + '" or filenames are not permitted. Please describe the visual content.';
					}
					el.editMetaAlt.style.borderColor = 'var(--admin-danger, #ef4444)';
					el.editMetaAlt.focus();
					return;
				}
			}

			if (el.btnSaveEditMeta) el.btnSaveEditMeta.disabled = true;

			try {
				var fd = new FormData();
				if (el.editMetaId && el.editMetaId.value) fd.append('id', el.editMetaId.value);
				if (el.editMetaPath && el.editMetaPath.value) fd.append('path', el.editMetaPath.value);
				fd.append('altText', altVal);
				if (el.editMetaTitle) fd.append('title', el.editMetaTitle.value.trim());
				if (el.editMetaCaption) fd.append('caption', el.editMetaCaption.value.trim());
				if (el.editMetaCredit) fd.append('credit', el.editMetaCredit.value.trim());
				if (el.editMetaTags) fd.append('tags', el.editMetaTags.value.trim());

				var res = await fetch('/api/Files.cfc?method=updateMeta', {
					method: 'POST',
					headers: { 'X-Requested-With': 'XMLHttpRequest' },
					body: fd
				});

				var resData = await res.json().catch(function () { return null; });
				if (el.btnSaveEditMeta) el.btnSaveEditMeta.disabled = false;

				if (resData && (resData.ok === true || resData.success === true)) {
					closeEditMetaModal();
					toast('WCAG metadata saved successfully.');
					if (it) {
						it.altText = altVal;
						it.title = el.editMetaTitle ? el.editMetaTitle.value.trim() : it.title;
						it.caption = el.editMetaCaption ? el.editMetaCaption.value.trim() : it.caption;
						it.credit = el.editMetaCredit ? el.editMetaCredit.value.trim() : it.credit;
						it.tags = el.editMetaTags ? el.editMetaTags.value.trim() : it.tags;
						it.isWcagCompliant = true;
						renderDetails();
					}
				} else {
					var errText = (resData && (resData.error || resData.message)) || 'Failed to save metadata.';
					if (el.editMetaError) {
						el.editMetaError.hidden = false;
						el.editMetaError.textContent = errText;
					}
				}
			} catch (err) {
				if (el.btnSaveEditMeta) el.btnSaveEditMeta.disabled = false;
				if (el.editMetaError) {
					el.editMetaError.hidden = false;
					el.editMetaError.textContent = 'Network error: ' + (err.message || 'could not reach server');
				}
			}
		});
	}

	if (el.uploadAlt) {
		el.uploadAlt.addEventListener('input', function () {
			if (this.value.trim()) {
				this.style.borderColor = '';
				this.style.boxShadow = '';
				showUploadError('');
			}
		});
	}

	// ------------------------------------------------------------------
	// OCR Content Detection & Folder Auto-Compliance Crawler Modal
	// ------------------------------------------------------------------
	var crawlModal = $('mediaCrawlModal');
	var btnOpenCrawlModal = $('btnOpenCrawlModal');
	var btnCloseCrawlModal = $('btn-close-crawl-modal');
	var btnCancelCrawlModal = $('btn-cancel-crawl-modal');
	var crawlForm = $('mediaCrawlForm');
	var crawlPathInput = $('crawl-folder-path');
	var crawlOptRecursive = $('crawl-opt-recursive');
	var crawlOptThumbs = $('crawl-opt-thumbs');
	var crawlOptOverwrite = $('crawl-opt-overwrite');
	var crawlError = $('crawl-error');
	var crawlResultsContainer = $('crawl-results-container');
	var crawlStatScanned = $('crawl-stat-scanned');
	var crawlStatImages = $('crawl-stat-images');
	var crawlStatOcr = $('crawl-stat-ocr');
	var crawlStatCompliant = $('crawl-stat-compliant');
	var crawlSummaryLine = $('crawl-summary-line');
	var crawlResultsTbody = $('crawl-results-tbody');
	var crawlStatusText = $('crawl-status-text');
	var btnRunCrawl = $('btn-run-crawl');
	var btnRunCrawlLabel = $('btn-run-crawl-label');

	function openCrawlModal(initialPath) {
		if (!crawlModal) return;
		var defaultPath = initialPath || diskPath(state.path || state.ws || '', false);
		if (crawlPathInput) crawlPathInput.value = defaultPath;
		if (crawlError) { crawlError.hidden = true; crawlError.textContent = ''; }
		if (crawlStatusText) crawlStatusText.textContent = 'Ready to crawl folder.';
		crawlModal.hidden = false;
		crawlModal.style.display = 'flex';
		if (crawlPathInput) crawlPathInput.focus();
	}

	function closeCrawlModal() {
		if (!crawlModal) return;
		crawlModal.hidden = true;
		crawlModal.style.display = 'none';
	}

	if (btnOpenCrawlModal) {
		btnOpenCrawlModal.addEventListener('click', function () {
			var it = selectedItem();
			var targetRel = (it && it.type === 'dir') ? itemPath(it) : (state.path || state.ws || '');
			openCrawlModal(diskPath(targetRel, false));
		});
	}
	if (btnCloseCrawlModal) btnCloseCrawlModal.addEventListener('click', closeCrawlModal);
	if (btnCancelCrawlModal) btnCancelCrawlModal.addEventListener('click', closeCrawlModal);
	if (crawlModal) {
		crawlModal.addEventListener('click', function (e) {
			if (e.target === crawlModal) closeCrawlModal();
		});
		crawlModal.addEventListener('keydown', function (e) {
			if (e.key === 'Escape') closeCrawlModal();
		});
	}

	var btnPresetCurrent = $('btn-crawl-preset-current');
	var btnPresetWs = $('btn-crawl-preset-ws');
	var btnPresetAll = $('btn-crawl-preset-all');
	if (btnPresetCurrent) {
		btnPresetCurrent.addEventListener('click', function () {
			if (crawlPathInput) crawlPathInput.value = diskPath(state.path || state.ws || '', false);
		});
	}
	if (btnPresetWs) {
		btnPresetWs.addEventListener('click', function () {
			if (crawlPathInput) crawlPathInput.value = diskPath(state.ws || '', false);
		});
	}
	if (btnPresetAll) {
		btnPresetAll.addEventListener('click', function () {
			if (crawlPathInput) crawlPathInput.value = 'C:\\inetpub\\chelan-county\\files';
		});
	}

	if (crawlForm) {
		crawlForm.addEventListener('submit', async function (e) {
			e.preventDefault();
			var targetPath = crawlPathInput ? crawlPathInput.value.trim() : '';
			if (!targetPath) {
				if (crawlError) { crawlError.hidden = false; crawlError.textContent = 'Please enter a folder path to crawl.'; }
				return;
			}
			if (crawlError) { crawlError.hidden = true; crawlError.textContent = ''; }
			if (btnRunCrawl) btnRunCrawl.disabled = true;
			if (btnRunCrawlLabel) btnRunCrawlLabel.textContent = 'Running OCR & Visual Analysis...';
			if (crawlStatusText) crawlStatusText.textContent = 'Scanning images, extracting OCR text, and updating database...';

			try {
				var fd = new URLSearchParams();
				fd.set('path', targetPath);
				fd.set('ws', state.ws || '');
				fd.set('recursive', (crawlOptRecursive && crawlOptRecursive.checked) ? 'true' : 'false');
				fd.set('generateThumbs', (crawlOptThumbs && crawlOptThumbs.checked) ? 'true' : 'false');
				fd.set('overwriteAlt', (crawlOptOverwrite && crawlOptOverwrite.checked) ? 'true' : 'false');

				var res = await fetch('/api/Files.cfc?method=crawlFolder&returnformat=json', {
					method: 'POST',
					headers: {
						'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
						'X-Requested-With': 'FileExplorer'
					},
					body: fd.toString()
				});
				var rawText = await res.text();
				var data = parseJSON(rawText);

				if (btnRunCrawl) btnRunCrawl.disabled = false;
				if (btnRunCrawlLabel) btnRunCrawlLabel.textContent = 'Start OCR Crawl & Make Compliant';

				if (!data || data.ok !== true) {
					var msg = (data && data.error) ? data.error : 'Failed to crawl folder.';
					if (crawlError) { crawlError.hidden = false; crawlError.textContent = msg; }
					if (crawlStatusText) crawlStatusText.textContent = 'Crawl failed.';
					return;
				}

				if (crawlResultsContainer) crawlResultsContainer.hidden = false;
				if (crawlStatScanned) crawlStatScanned.textContent = String(data.filesScanned || 0);
				if (crawlStatImages) crawlStatImages.textContent = String(data.imagesProcessed || 0);
				if (crawlStatOcr) crawlStatOcr.textContent = String(data.ocrDetectedCount || 0);
				if (crawlStatCompliant) crawlStatCompliant.textContent = String(data.imagesProcessed || 0);
				if (crawlSummaryLine) {
					crawlSummaryLine.textContent = 'Target: ' + (data.targetDiskPath || targetPath) +
						' \u00b7 Inserted: ' + (data.inserted || 0) +
						' \u00b7 Updated: ' + (data.updated || 0) +
						' \u00b7 Newly Compliant: ' + (data.madeCompliant || 0) +
						' \u00b7 Time: ' + (data.durationMs || 0) + ' ms';
				}
				if (crawlStatusText) {
					crawlStatusText.textContent = 'Completed! ' + (data.imagesProcessed || 0) + ' images verified WCAG 1.1.1 compliant.';
				}

				if (crawlResultsTbody) {
					var rows = (data.items || []).filter(function (x) { return x.isImage; }).map(function (item) {
						var ocrBadge = item.ocrText
							? '<div style="font-family:monospace; font-size:0.74rem; background:#f5f3ff; color:#5b21b6; padding:2px 6px; border-radius:4px; border:1px solid #ddd6fe; margin-bottom:2px;">OCR: &ldquo;' + esc(item.ocrText) + '&rdquo;</div>'
							: '';
						var toneBadge = item.visualTone
							? '<span style="font-size:0.72rem; color:#64748b;">' + esc((item.width && item.height ? item.width + '\u00d7' + item.height + ' \u00b7 ' : '') + item.visualTone) + '</span>'
							: '';
						return '<tr style="border-bottom:1px solid #e2e8f0;">' +
							'<td style="padding:0.45rem 0.65rem; font-weight:600; color:#0f172a; word-break:break-all;">' + esc(item.filename) + '<div class="mono" style="font-size:0.7rem; color:#64748b; font-weight:400;">' + esc(item.siteId + '/' + item.folder) + '</div></td>' +
							'<td style="padding:0.45rem 0.65rem;">' + ocrBadge + toneBadge + '</td>' +
							'<td style="padding:0.45rem 0.65rem; color:#166534; font-weight:500;">' + esc(item.altText || '') + '</td>' +
							'</tr>';
					}).join('');
					crawlResultsTbody.innerHTML = rows || '<tr><td colspan="3" style="padding:0.75rem; text-align:center; color:#64748b;">No image files found in target folder.</td></tr>';
				}

				toast('OCR Crawl complete: ' + (data.imagesProcessed || 0) + ' images WCAG compliant.');
				await load(state.path, state.selected);
			} catch (err) {
				if (btnRunCrawl) btnRunCrawl.disabled = false;
				if (btnRunCrawlLabel) btnRunCrawlLabel.textContent = 'Start OCR Crawl & Make Compliant';
				if (crawlError) { crawlError.hidden = false; crawlError.textContent = 'Network error: ' + (err.message || 'could not complete crawl'); }
				if (crawlStatusText) crawlStatusText.textContent = 'Error during crawl.';
			}
		});
	}

	// ------------------------------------------------------------------
	// Boot
	// ------------------------------------------------------------------
	function boot() {
		// Read active workspace configuration from markup
		var container = $('filexplorer-container');
		if (container) {
			state.ws = container.getAttribute('data-ws') || container.getAttribute('data-ws-virtual-dir') || '';
			state.wsName = container.getAttribute('data-ws-name') || '';
			state.assetsProtocol = container.getAttribute('data-ws-assets-protocol') || 'http';
			state.assetsDomain = container.getAttribute('data-ws-assets-domain') || '';
			state.initialFolder = container.getAttribute('data-initial-folder') || '';
			state.pickerMode = container.getAttribute('data-picker-mode') || '';
			state.pickerCallback = container.getAttribute('data-picker-callback') || '';
			state.targetInput = container.getAttribute('data-target-input') || '';
		}

		var v = lsGet(VIEW_KEY);
		state.view = v === 'list' ? 'list' : 'grid';
		el.btnGrid.setAttribute('aria-pressed', state.view === 'grid' ? 'true' : 'false');
		el.btnList.setAttribute('aria-pressed', state.view === 'list' ? 'true' : 'false');

		state.path = currentHashPath();

		if (el.btnDoUploadSpinner) {
			el.btnDoUploadSpinner.hidden = true;
			el.btnDoUploadSpinner.style.setProperty('display', 'none', 'important');
		}
		if (el.btnDoUploadIcon) {
			el.btnDoUploadIcon.hidden = false;
			el.btnDoUploadIcon.style.removeProperty('display');
		}

		renderItems();
		renderDetails();
		updateWriteControls();
		setConnecting();
		ping(true);
		setInterval(function () { ping(false); }, PING_EVERY_MS);
	}

	boot();
})();
