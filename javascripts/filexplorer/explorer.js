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
		cfg: { filesRoot: 'C:\\inetpub\\cmsadmin2.0\\files\\', webBase: '/files/', systemDepth: 2, maxNameLen: 64, server: '' },
		ws: '',                // active workspace directory (e.g. "community-development")
		wsName: '',            // friendly display name
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
		up: $('btn-up'), crumbs: $('crumbs'), filter: $('filter'), btnNew: $('btn-new'),
		btnGrid: $('btn-grid'), btnList: $('btn-list'),
		newPanel: $('new-panel'), newName: $('new-name'), newPreview: $('new-preview'), newError: $('new-error'),
		btnCreate: $('btn-create'), btnCancel: $('btn-cancel'),
		summary: $('summary'), levelHint: $('level-hint'),
		content: $('content'), items: $('items'),
		details: $('details'), toast: $('toast')
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
		var root = state.cfg.filesRoot;
		var out = root + segs(p).join('\\');
		if (isDir && out.slice(-1) !== '\\') out += '\\';
		return out;
	}
	function webPath(p, isDir) {
		var out = state.cfg.webBase + p;
		if (isDir && out.slice(-1) !== '/') out += '/';
		return out;
	}
	function webHref(p) {
		var low = (p || '').toLowerCase();
		if (low.indexOf('shared images/') === 0 || low === 'shared images') {
			var rel = p.substring(13).replace(/^\//, '');
			return '/images/picjumbo/' + segs(rel).map(encodeURIComponent).join('/');
		}
		return state.cfg.webBase + segs(p).map(encodeURIComponent).join('/');
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
			return 'Shared stock photography library (c:/inetpub/chelan-county/images/picjumbo) is read-only. Adding, renaming, or deleting folders/files is disabled for all users.';
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
			if (d.systemDepth != null) state.cfg.systemDepth = Number(d.systemDepth);
			if (d.maxNameLen != null) state.cfg.maxNameLen = Number(d.maxNameLen);
			if (el.webRoot) {
				el.webRoot.textContent = state.cfg.webBase + (state.ws ? state.ws + '/' : '');
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
			name: String(it.name),
			type: String(it.type).toLowerCase() === 'dir' ? 'dir' : 'file',
			modified: String(it.modified || ''),
			size: Number(it.size || 0),
			ext: String(it.ext || '').toLowerCase(),
			dirs: Number(it.dirs || 0),
			files: Number(it.files || 0)
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
	}

	// ------------------------------------------------------------------
	// Rendering
	// ------------------------------------------------------------------
	var ICON = {
		folder: '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
		file: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
		image: '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5-9 9"/>',
		chevron: '<path d="M9 6l6 6-6 6"/>',
		root: '<path d="M4 6h16v4H4zM4 14h16v4H4z"/><path d="M8 8h.01M8 16h.01"/>'
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
		state.shown = q ? state.items.filter(function (it) { return it.name.toLowerCase().indexOf(q) >= 0; }) : state.items.slice();
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
			return '<img loading="lazy" decoding="async" alt="" src="' + esc(webHref(itemPath(it))) + '" data-fallback="1">';
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
					return '<div class="card item' + (isShared ? ' is-shared-card' : '') + '" role="listitem" tabindex="' + (sel || (!state.selected && idx === 0) ? '0' : '-1') + '"' +
						' aria-selected="' + (sel ? 'true' : 'false') + '" data-idx="' + idx + '">' +
						badge +
						'<div class="thumb">' + thumbFor(it) + '</div>' +
						'<div class="name" title="' + esc(displayName) + '">' + esc(displayName) + '</div>' +
						'<div class="meta">' + esc(meta) + '</div>' +
						'</div>';
				}).join('') +
				'</div>';
		} else {
			el.items.innerHTML = '<div class="table-wrap"><table class="list" role="table"><thead><tr>' +
				'<th scope="col">Name</th><th scope="col">Type</th><th scope="col" class="num">Size</th><th scope="col">Modified</th>' +
				'</tr></thead><tbody>' +
				state.shown.map(function (it, idx) {
					var sel = it.name === state.selected;
					var isDir = it.type === 'dir';
					var isShared = isDir && (it.name.toLowerCase() === 'shared images');
					var displayName = isShared ? 'Shared Images' : it.name;
					var k = isDir ? { cls: isShared ? 'shared' : 'dir', label: isShared ? 'Shared Photos' : 'Folder' } : fileKind(it.ext);
					var chipText = isShared ? 'READ-ONLY' : (isDir ? 'DIR' : (it.ext || 'FILE'));
					var chip = '<span class="chip bg-' + k.cls + '">' + esc(chipText) + '</span>';
					return '<tr class="row item" tabindex="' + (sel || (!state.selected && idx === 0) ? '0' : '-1') + '"' +
						' aria-selected="' + (sel ? 'true' : 'false') + '" data-idx="' + idx + '">' +
						'<td><div class="cell-name">' + chip + '<span title="' + esc(displayName) + '">' + esc(displayName) + '</span></div></td>' +
						'<td>' + esc(k.label) + '</td>' +
						'<td class="num mono">' + esc(isDir ? '\u2014' : fmtSize(it.size)) + '</td>' +
						'<td class="mono muted">' + esc(it.modified || '\u2014') + '</td>' +
						'</tr>';
				}).join('') +
				'</tbody></table></div>';
		}
	}

	el.items.addEventListener('error', function (e) {
		var t = e.target;
		if (t && t.tagName === 'IMG' && t.getAttribute('data-fallback')) {
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
				(canNew ? '<button type="button" class="btn btn-block" data-act="new"' + (online ? '' : ' disabled') + '>New subfolder</button>' : '') +
				(canDel && depth > state.cfg.systemDepth
					? '<button type="button" class="btn btn-danger btn-block' + (armed ? ' confirming' : '') + '" data-act="delete" data-path="' + esc(p) + '"' +
						(online ? '' : ' disabled') + '>' + (armed ? 'Confirm delete' : 'Delete folder') + '</button>'
					: '') +
				'</div>' +
				'<dl>' +
				'<dt>Server path</dt><dd class="mono">' + esc(diskPath(p, true)) + '</dd>' +
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
				? '<img alt="" src="' + esc(webHref(fp)) + '" data-fallback="1">'
				: svg(k.cls === 'image' ? 'image' : 'file', 't-' + k.cls);
			var isPicker = Boolean(state.pickerMode || state.pickerCallback || state.targetInput);
			var selectLabel = state.pickerMode === 'document' ? 'Select Document' : (state.pickerMode === 'image' ? 'Select Image' : 'Select File');
			html = '<div class="preview">' + preview + '</div>' +
				'<h2>' + esc(it.name) + '</h2>' +
				'<div class="kind">' + esc(k.label + ' \u00b7 ' + fmtSize(it.size)) + (isSharedFile ? ' \u00b7 <span style="font-weight:700; color:#0284c7;">Read-Only</span>' : '') + '</div>' +
				'<div class="actions">' +
				(isPicker
					? '<button type="button" class="btn btn-primary btn-block" data-act="select-file">' + esc(selectLabel) + '</button>' +
					  '<a class="btn btn-block" href="' + esc(webHref(fp)) + '" target="_blank" rel="noopener">Open <span class="sr-only">(opens in a new tab)</span></a>'
					: '<a class="btn btn-primary btn-block" href="' + esc(webHref(fp)) + '" target="_blank" rel="noopener">Open <span class="sr-only">(opens in a new tab)</span></a>'
				) +
				'<button type="button" class="btn btn-block" data-act="copy">Copy link</button>' +
				'</div>' +
				'<dl>' +
				'<dt>Server path</dt><dd class="mono">' + esc(diskPath(fp, false)) + '</dd>' +
				'<dt>Web URL</dt><dd class="mono">' + esc(webPath(fp, false)) + '</dd>' +
				'<dt>Size</dt><dd>' + esc(fmtSize(it.size) + ' (' + it.size.toLocaleString() + ' bytes)') + '</dd>' +
				'<dt>Modified</dt><dd>' + esc(it.modified) + '</dd>' +
				'</dl>';
		}
		el.details.innerHTML = html;
	}

	if (el.details) {
		el.details.addEventListener('error', function (e) {
			var t = e.target;
			if (t && t.tagName === 'IMG') {
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
		if (el.btnNew) {
			el.btnNew.disabled = !(online && canCreate);
			el.btnNew.title = !online ? 'Unavailable while offline'
				: (isShared ? 'Shared images is read-only. Adding or modifying folders is disabled.'
				: (canCreate ? 'Create a folder here' : 'Folders can only be created inside images or documents (or below)'));
		}
		if (el.btnCreate) el.btnCreate.disabled = !online || isShared;
		if (!canCreate) closeNew();
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
			webUrl = '/images/picjumbo/' + relShared.split('/').map(encodeURIComponent).join('/');
		}
		var baseTitle = it.name.replace(/\.[^.]+$/, '').replace(/[-_]+/g, ' ').trim() || it.name;
		var ext = (it.ext || it.name.split('.').pop() || 'FILE').toUpperCase();
		var sizeStr = fmtSize(it.size);
		var isImg = IMAGE_EXT.indexOf((it.ext || '').toLowerCase()) >= 0;
		var htmlSnippet = '';

		if (isImg) {
			htmlSnippet = '<img src="' + esc(webUrl) + '" alt="' + esc(baseTitle) + '" title="' + esc(baseTitle) + '" style="max-width:100%; height:auto;" loading="lazy">';
		} else {
			var adaNotice = baseTitle + ' (' + ext + ', opens in a new tab)';
			htmlSnippet = '<a href="' + esc(webUrl) + '" class="document-download-link" target="_blank" rel="noopener noreferrer" aria-label="' + esc(adaNotice) + '" title="' + esc(adaNotice) + '">' + esc(baseTitle) + ' (' + esc(ext) + ', ' + esc(sizeStr) + ')</a>';
		}

		var payload = {
			html: htmlSnippet,
			url: webUrl,
			title: baseTitle,
			alt: baseTitle,
			data: {
				name: it.name,
				title: baseTitle,
				altText: baseTitle,
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
				alt: baseTitle
			}, '*');
			window.parent.postMessage({
				type: 'cmsMediaSelected',
				url: webUrl,
				title: baseTitle,
				targetInput: state.targetInput
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
			} else if (act === 'copy') {
				if (it) {
					var url = location.origin + webHref(itemPath(it));
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
	// Toolbar, Tree, Breadcrumbs
	// ------------------------------------------------------------------
	el.btnNew.addEventListener('click', function () {
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
		if (e.detail && (e.detail.virtualDir || e.detail.id)) {
			var newWs = e.detail.virtualDir || e.detail.id;
			state.ws = newWs;
			state.wsName = e.detail.name || friendly(newWs);
			if (el.webRoot) el.webRoot.textContent = state.cfg.webBase + state.ws + '/';
			navigate(newWs);
		}
	});

	// ------------------------------------------------------------------
	// Boot
	// ------------------------------------------------------------------
	function boot() {
		// Read active workspace configuration from markup
		var container = $('filexplorer-container');
		if (container) {
			state.ws = container.getAttribute('data-ws') || container.getAttribute('data-ws-virtual-dir') || '';
			state.wsName = container.getAttribute('data-ws-name') || '';
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

		renderItems();
		renderDetails();
		updateWriteControls();
		setConnecting();
		ping(true);
		setInterval(function () { ping(false); }, PING_EVERY_MS);
	}

	boot();
})();
