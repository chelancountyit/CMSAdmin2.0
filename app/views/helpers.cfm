<cfscript>
// Place helper functions here that should be available for use in all view pages of your application.

/**
 * Returns inline SVG markup for crisp, lightweight icons with zero external dependencies.
 * @name Name of the icon (dashboard, article, pages, media, users, settings, bell, etc.)
 * @class Optional CSS classes
 * @size Width and height in pixels (default: 18)
 */
public string function svgIcon(required string name, string class = "", numeric size = 18) {
	var s = arguments.size;
	var cls = Len(arguments.class) ? " class=""#arguments.class#""" : "";
	var baseAttrs = "width=""#s#"" height=""#s#"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2"" stroke-linecap=""round"" stroke-linejoin=""round""#cls#";

	switch (LCase(arguments.name)) {
		case "dashboard":
			return '<svg #baseAttrs#><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>';
		case "article":
		case "file-text":
			return '<svg #baseAttrs#><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/></svg>';
		case "book":
		case "docs":
		case "documentation":
			return '<svg #baseAttrs#><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/><path d="M6 6h10"/><path d="M6 10h10"/></svg>';
		case "pages":
		case "copy":
			return '<svg #baseAttrs#><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>';
		case "media":
		case "image":
			return '<svg #baseAttrs#><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>';
		case "folder":
		case "categories":
			return '<svg #baseAttrs#><path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"/></svg>';
		case "tag":
		case "tags":
			return '<svg #baseAttrs#><path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5" fill="currentColor"/></svg>';
		case "users":
		case "user":
			return '<svg #baseAttrs#><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>';
		case "settings":
			return '<svg #baseAttrs#><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>';
		case "bell":
			return '<svg #baseAttrs#><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>';
		case "briefcase":
		case "hrm":
			return '<svg #baseAttrs#><rect width="20" height="14" x="2" y="7" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>';
		case "megaphone":
		case "bullhorn":
		case "pio":
			return '<svg #baseAttrs#><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>';
		case "search":
			return '<svg #baseAttrs#><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>';
		case "menu":
			return '<svg #baseAttrs#><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/></svg>';
		case "chevron-down":
			return '<svg #baseAttrs#><path d="m6 9 6 6 6-6"/></svg>';
		case "chevron-right":
			return '<svg #baseAttrs#><path d="m9 18 6-6-6-6"/></svg>';
		case "chevron-left":
			return '<svg #baseAttrs#><path d="m15 18-6-6 6-6"/></svg>';
		case "arrow-left":
			return '<svg #baseAttrs#><line x1="19" x2="5" y1="12" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>';
		case "arrow-right":
			return '<svg #baseAttrs#><line x1="5" x2="19" y1="12" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>';
		case "chevron-up":
			return '<svg #baseAttrs#><path d="m18 15-6-6-6 6"/></svg>';
		case "plus":
			return '<svg #baseAttrs#><path d="M5 12h14"/><path d="M12 5v14"/></svg>';
		case "maximize":
			return '<svg #baseAttrs#><path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/></svg>';
		case "check-circle":
			return '<svg #baseAttrs#><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>';
		case "clock":
			return '<svg #baseAttrs#><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>';
		case "eye":
			return '<svg #baseAttrs#><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
		case "edit":
			return '<svg #baseAttrs#><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/><path d="m15 5 4 4"/></svg>';
		case "trash":
			return '<svg #baseAttrs#><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>';
		case "log-out":
			return '<svg #baseAttrs#><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>';
		case "external-link":
			return '<svg #baseAttrs#><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>';
		case "trending-up":
			return '<svg #baseAttrs#><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></svg>';
		case "activity":
			return '<svg #baseAttrs#><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>';
		case "filter":
			return '<svg #baseAttrs#><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>';
		case "hard-drive":
			return '<svg #baseAttrs#><line x1="22" x2="2" y1="12" y2="12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/><line x1="6" x2="6.01" y1="16" y2="16"/><line x1="10" x2="10.01" y1="16" y2="16"/></svg>';
		case "form":
		case "form-builder":
		case "clipboard-list":
			return '<svg #baseAttrs#><rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="M12 11h4"/><path d="M12 16h4"/><path d="M8 11h.01"/><path d="M8 16h.01"/></svg>';
		case "type":
		case "text":
			return '<svg #baseAttrs#><polyline points="4 7 4 4 20 4 20 7"/><line x1="9" x2="15" y1="20" y2="20"/><line x1="12" x2="12" y1="4" y2="20"/></svg>';
		case "align-left":
		case "paragraph":
		case "textarea":
			return '<svg #baseAttrs#><line x1="21" x2="3" y1="6" y2="6"/><line x1="15" x2="3" y1="12" y2="12"/><line x1="17" x2="3" y1="18" y2="18"/></svg>';
		case "mail":
		case "email":
			return '<svg #baseAttrs#><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>';
		case "phone":
			return '<svg #baseAttrs#><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>';
		case "hash":
		case "number":
			return '<svg #baseAttrs#><line x1="4" x2="20" y1="9" y2="9"/><line x1="4" x2="20" y1="15" y2="15"/><line x1="10" x2="8" y1="3" y2="21"/><line x1="16" x2="14" y1="3" y2="21"/></svg>';
		case "calendar":
		case "date":
			return '<svg #baseAttrs#><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/></svg>';
		case "list":
		case "select":
		case "dropdown":
			return '<svg #baseAttrs#><line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/></svg>';
		case "check-square":
		case "checkbox":
			return '<svg #baseAttrs#><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>';
		case "circle-dot":
		case "radio":
			return '<svg #baseAttrs#><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/></svg>';
		case "toggle-right":
		case "switch":
			return '<svg #baseAttrs#><rect width="20" height="12" x="2" y="6" rx="6" ry="6"/><circle cx="16" cy="12" r="2"/></svg>';
		case "upload-cloud":
		case "upload":
		case "file-upload":
			return '<svg #baseAttrs#><path d="M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"/><path d="M12 12v9"/><path d="m16 16-4-4-4 4"/></svg>';
		case "star":
		case "rating":
			return '<svg #baseAttrs#><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>';
		case "pen-tool":
		case "signature":
			return '<svg #baseAttrs#><path d="m12 19 7-7 3 3-7 7-3-3z"/><path d="m18 13-1.5-7.5L2 2l3.5 14.5L13 18l5-5z"/><path d="m2 2 7.586 7.586"/><circle cx="11" cy="11" r="2"/></svg>';
		case "map-pin":
		case "address":
			return '<svg #baseAttrs#><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>';
		case "code":
		case "embed":
			return '<svg #baseAttrs#><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>';
		case "play":
			return '<svg #baseAttrs#><polygon points="5 3 19 12 5 21 5 3"/></svg>';
		case "monitor":
		case "desktop":
			return '<svg #baseAttrs#><rect width="20" height="14" x="2" y="3" rx="2"/><line x1="8" x2="16" y1="21" y2="21"/><line x1="12" x2="12" y1="17" y2="21"/></svg>';
		case "tablet":
			return '<svg #baseAttrs#><rect width="16" height="20" x="4" y="2" rx="2" ry="2"/><line x1="12" x2="12.01" y1="18" y2="18"/></svg>';
		case "smartphone":
		case "mobile":
			return '<svg #baseAttrs#><rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><line x1="12" x2="12.01" y1="18" y2="18"/></svg>';
		case "refresh-cw":
		case "reset":
			return '<svg #baseAttrs#><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/></svg>';
		case "sparkles":
		case "templates":
			return '<svg #baseAttrs#><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>';
		case "save":
			return '<svg #baseAttrs#><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>';
		case "share-2":
		case "share":
			return '<svg #baseAttrs#><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" x2="15.42" y1="13.51" y2="17.49"/><line x1="15.41" x2="8.59" y1="6.51" y2="10.49"/></svg>';
		case "download":
		case "export":
			return '<svg #baseAttrs#><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>';
		case "arrow-up":
			return '<svg #baseAttrs#><line x1="12" x2="12" y1="19" y2="5"/><polyline points="5 12 12 5 19 12"/></svg>';
		case "arrow-down":
			return '<svg #baseAttrs#><line x1="12" x2="12" y1="5" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>';
		case "check":
			return '<svg #baseAttrs#><polyline points="20 6 9 17 4 12"/></svg>';
		case "help-circle":
			return '<svg #baseAttrs#><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" x2="12.01" y1="17" y2="17"/></svg>';
		case "layers":
			return '<svg #baseAttrs#><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg>';
		case "link":
			return '<svg #baseAttrs#><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';
		case "more-vertical":
			return '<svg #baseAttrs#><circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/></svg>';
		case "shield":
		case "security":
			return '<svg #baseAttrs#><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>';
		case "lock":
			return '<svg #baseAttrs#><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>';
		case "building":
		case "department":
			return '<svg #baseAttrs#><rect width="16" height="20" x="4" y="2" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/></svg>';
		case "globe":
		case "site":
			return '<svg #baseAttrs#><circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/></svg>';
		case "grid":
		case "workspace":
			return '<svg #baseAttrs#><rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/></svg>';
		case "x":
		case "close":
			return '<svg #baseAttrs#><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>';
		case "file":
			return '<svg #baseAttrs#><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>';
		case "zoom-in":
			return '<svg #baseAttrs#><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>';
		case "info":
			return '<svg #baseAttrs#><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>';
		case "alert-triangle":
		case "warning":
			return '<svg #baseAttrs#><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" x2="12" y1="9" y2="13"/><line x1="12" x2="12.01" y1="17" y2="17"/></svg>';
		case "video":
		case "zoom":
			return '<svg #baseAttrs#><path d="m22 8-6 4 6 4V8Z"/><rect width="14" height="12" x="2" y="6" rx="2" ry="2"/></svg>';
		case "paperclip":
		case "attachment":
			return '<svg #baseAttrs#><path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"/></svg>';
		case "bug":
		case "pest":
		case "infestation":
			return '<svg #baseAttrs#><path d="m8 2 1.88 1.88"/><path d="M14.12 3.88 16 2"/><path d="M9 7.13v-1a3.003 3.003 0 1 1 6 0v1"/><path d="M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6"/><path d="M12 20v-9"/><path d="M6.53 9C4.6 8.8 3 7.1 3 5"/><path d="M6 13H2"/><path d="M3 21c0-2.1 1.7-3.9 3.8-4"/><path d="M20.97 5c0 2.1-1.6 3.8-3.5 4"/><path d="M22 13h-4"/><path d="M17.2 17c2.1.1 3.8 1.9 3.8 4"/></svg>';
		case "gavel":
		case "bids":
		case "rfps":
		case "rfp":
		case "solicitations":
			return '<svg #baseAttrs#><path d="m14 13-7.5 7.5a2.12 2.12 0 1 1-3-3L11 10"/><path d="m16 16 6-6"/><path d="m8 8 6-6"/><path d="m9 7 8 8"/><path d="m21 11-8-8"/></svg>';
		case "award":
		case "badge-check":
			return '<svg #baseAttrs#><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/></svg>';
		case "file-signature":
		case "contract":
			return '<svg #baseAttrs#><path d="M20 19.5v.5a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8.5L20 7.5V11"/><path d="M14 2v6h6"/><path d="M18.42 15.61a2.1 2.1 0 1 1 2.97 2.97L16.95 23 13 24l1-3.95 4.42-4.44Z"/></svg>';
		case "cta":
		case "call-to-action":
		case "zap":
			return '<svg #baseAttrs#><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>';
		case "cursor-click":
		case "pointer":
			return '<svg #baseAttrs#><path d="m3 3 7.07 16.97 2.51-7.39 7.39-2.51L3 3z"/><path d="m13 13 6 6"/></svg>';
		case "pdf":
		case "file-pdf":
			return '<svg #baseAttrs#><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><path d="M9 15v-4h2a1.5 1.5 0 0 1 0 3H9"/></svg>';
		case "arrow-up-right":
			return '<svg #baseAttrs#><line x1="7" y1="17" x2="17" y2="7"/><polyline points="7 7 17 7 17 17"/></svg>';
		default:
			return '<svg #baseAttrs#><circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg>';
	}
}

/**
 * Returns formatted status badge markup for CMS items
 * @status Status string (Published, Draft, Scheduled, Pending, Archived, etc.)
 */
public string function statusBadge(required string status) {
	var st = LCase(Trim(arguments.status));
	var badgeClass = "badge-neutral";
	var label = arguments.status;

	switch (st) {
		case "published":
		case "active":
		case "live":
		case "open":
			badgeClass = "badge-success";
			break;
		case "awarded":
			badgeClass = "badge-purple";
			break;
		case "draft":
			badgeClass = "badge-neutral";
			break;
		case "scheduled":
		case "pending":
		case "in review":
		case "under review":
		case "award pending":
			badgeClass = "badge-warning";
			break;
		case "trash":
		case "inactive":
		case "archived":
		case "cancelled":
		case "closed":
			badgeClass = "badge-danger";
			break;
		case "featured":
			badgeClass = "badge-primary";
			break;
	}

	return '<span class="badge #badgeClass#">#label#</span>';
}
</cfscript>
