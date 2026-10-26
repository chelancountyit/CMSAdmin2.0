/**
 * CMSAdmin 2.0 - Core Template Interactions
 * Clean vanilla JavaScript with zero external library dependencies.
 */
window.resolveLocalAssetFallbackUrl = function (src) {
  if (!src || typeof src !== "string") return "";
  const trimmed = src.trim();
  let rel = "";
  const match = trimmed.match(/^https?:\/\/[^\/]+\/(.+)$/i);
  if (match) {
    rel = match[1].replace(/^\/+/, "");
  } else if (trimmed.startsWith("/") && !/^\/(files|images)\//i.test(trimmed)) {
    rel = trimmed.replace(/^\/+/, "");
  }
  if (!rel) return "";
  if (/^(files|images)\//i.test(rel)) return "/" + rel;
  if (/^shared(?:%20|\s)+images\//i.test(rel)) {
    return "/images/picjumbo/" + rel.replace(/^shared(?:%20|\s)+images\//i, "");
  }
  return "/files/" + rel;
};

window.healBrokenAssetImage = function (img, evt) {
  if (!img || img.tagName !== "IMG") return false;
  const rawSrc = img.getAttribute("src") || "";
  if (!rawSrc) return false;
  const fallbackSrc = window.resolveLocalAssetFallbackUrl(rawSrc);
  if (!fallbackSrc || fallbackSrc === rawSrc) return false;

  if (evt && typeof evt.stopImmediatePropagation === "function") {
    evt.stopImmediatePropagation();
  }
  img.setAttribute("data-canonical-src", rawSrc);
  img.setAttribute("src", fallbackSrc);

  if (img.id === "featuredImgPreview") {
    img.style.display = "block";
    const ph = document.getElementById("featuredImgPlaceholder");
    if (ph) ph.style.display = "none";
  } else if (img.id === "contactPhotoImg") {
    img.style.display = "block";
    const ph = document.getElementById("contactPhotoPlaceholder");
    if (ph) ph.style.display = "none";
  }
  return true;
};

if (typeof window !== "undefined") {
  window.addEventListener("error", function (e) {
    if (e && e.target && e.target.tagName === "IMG") {
      window.healBrokenAssetImage(e.target, e);
    }
  }, true);

  const scanInitialAssetImages = function () {
    document.querySelectorAll("img[src]").forEach(function (img) {
      if (img.complete && img.naturalWidth === 0) {
        window.healBrokenAssetImage(img, null);
      }
    });
  };
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", scanInitialAssetImages);
  } else {
    scanInitialAssetImages();
  }
}

const adminPromptQueue = [];
let adminPromptActive = false;

function showAdminPrompt(options) {
  return new Promise((resolve) => {
    adminPromptQueue.push({ options, resolve });
    showNextAdminPrompt();
  });
}

function showNextAdminPrompt() {
  if (adminPromptActive || adminPromptQueue.length === 0) return;

  const backdrop = document.getElementById("adminPromptBackdrop");
  const dialog = backdrop?.querySelector('[role="dialog"]');
  const title = document.getElementById("adminPromptTitle");
  const message = document.getElementById("adminPromptMessage");
  const cancel = document.getElementById("adminPromptCancel");
  const accept = document.getElementById("adminPromptAccept");
  if (!backdrop || !dialog || !title || !message || !cancel || !accept) {
    adminPromptQueue.shift().resolve(false);
    showNextAdminPrompt();
    return;
  }

  adminPromptActive = true;
  const current = adminPromptQueue.shift();
  const isAlert = current.options.kind === "alert";
  const previousFocus = document.activeElement;
  const previousOverflow = document.body.style.overflow;
  let completed = false;

  // Determine color-coded alert tone (success, danger, warning, info)
  let type = current.options.type;
  if (!type) {
    if (current.options.destructive) {
      type = "danger";
    } else {
      const combined = `${current.options.title || ""} ${current.options.message || ""}`.toLowerCase();
      if (combined.includes("error") || combined.includes("fail") || combined.includes("cannot") || combined.includes("unable") || combined.includes("invalid")) {
        type = "danger";
      } else if (combined.includes("delete") || combined.includes("remove")) {
        type = current.options.kind === "confirm" ? "danger" : "warning";
      } else if (combined.includes("warn") || combined.includes("caution") || combined.includes("attention")) {
        type = "warning";
      } else if (combined.includes("success") || combined.includes("saved") || combined.includes("created") || combined.includes("updated") || combined.includes("completed") || combined.includes("copied")) {
        type = "success";
      } else {
        type = "info";
      }
    }
  }

  // Update dialog color variant class
  dialog.classList.remove("admin-prompt--success", "admin-prompt--danger", "admin-prompt--warning", "admin-prompt--info");
  dialog.classList.add("admin-prompt--" + type);

  // Inject matching SVG icon into header
  const iconEl = document.getElementById("adminPromptIcon");
  if (iconEl) {
    const iconSvgs = {
      success: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>',
      danger: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>',
      warning: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
      info: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>'
    };
    iconEl.innerHTML = iconSvgs[type] || iconSvgs.info;
  }

  title.textContent = current.options.title || (isAlert ? (type === "danger" ? "Error" : type === "warning" ? "Warning" : type === "success" ? "Success" : "Notice") : "Please confirm");
  message.textContent = String(current.options.message || "");
  cancel.textContent = current.options.cancelText || "Cancel";
  accept.textContent = current.options.acceptText || current.options.confirmText || (isAlert ? "OK" : "Continue");
  if (isAlert) {
    cancel.hidden = true;
    cancel.style.display = "none";
  } else {
    cancel.hidden = false;
    cancel.style.display = "";
  }

  // Apply color-coded button styling
  accept.className = "btn btn-sm";
  if (type === "danger" || current.options.destructive) {
    accept.classList.add("btn-danger");
  } else if (type === "success") {
    accept.classList.add("btn-success");
  } else if (type === "warning") {
    accept.classList.add("btn-warning");
  } else {
    accept.classList.add("btn-primary");
  }

  backdrop.classList.add("is-open");
  document.body.style.overflow = "hidden";

  function finish(result) {
    if (completed) return;
    completed = true;
    backdrop.classList.remove("is-open");
    document.body.style.overflow = previousOverflow;
    document.removeEventListener("keydown", onKeydown);
    accept.removeEventListener("click", onAccept);
    cancel.removeEventListener("click", onCancel);
    backdrop.removeEventListener("click", onBackdropClick);
    if (previousFocus instanceof HTMLElement && previousFocus.isConnected) previousFocus.focus();
    if (result && typeof current.options.onConfirm === "function") {
      try { current.options.onConfirm(); } catch (e) { console.error(e); }
    } else if (!result && typeof current.options.onCancel === "function") {
      try { current.options.onCancel(); } catch (e) { console.error(e); }
    }
    current.resolve(result);
    adminPromptActive = false;
    showNextAdminPrompt();
  }

  function onAccept() { finish(true); }
  function onCancel() { finish(false); }
  function onBackdropClick(event) {
    if (event.target === backdrop) finish(isAlert);
  }
  function onKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      finish(isAlert);
      return;
    }
    if (event.key !== "Tab") return;
    const focusable = Array.from(dialog.querySelectorAll("button:not([hidden]):not([style*='display: none'])"));
    if (!focusable.length) {
      event.preventDefault();
      dialog.focus();
    } else if (!dialog.contains(document.activeElement)) {
      event.preventDefault();
      (event.shiftKey ? focusable[focusable.length - 1] : focusable[0]).focus();
    } else if (event.shiftKey && document.activeElement === focusable[0]) {
      event.preventDefault();
      focusable[focusable.length - 1].focus();
    } else if (!event.shiftKey && document.activeElement === focusable[focusable.length - 1]) {
      event.preventDefault();
      focusable[0].focus();
    }
  }

  accept.addEventListener("click", onAccept);
  cancel.addEventListener("click", onCancel);
  backdrop.addEventListener("click", onBackdropClick);
  document.addEventListener("keydown", onKeydown);
  (isAlert ? accept : cancel).focus();
}

window.adminAlert = function (messageOrOptions, options = {}) {
  if (messageOrOptions && typeof messageOrOptions === "object") {
    return showAdminPrompt({ ...options, ...messageOrOptions, kind: "alert" });
  }
  return showAdminPrompt({ ...options, kind: "alert", message: messageOrOptions });
};

window.adminConfirm = function (messageOrOptions, options = {}) {
  if (messageOrOptions && typeof messageOrOptions === "object") {
    return showAdminPrompt({ ...options, ...messageOrOptions, kind: "confirm" });
  }
  return showAdminPrompt({ ...options, kind: "confirm", message: messageOrOptions });
};

// Global polyfill for native window.alert to automatically route through CMSAdmin modal alert
window.alert = function (messageOrOptions, options = {}) {
  return window.adminAlert(messageOrOptions, options);
};

/**
 * Global Color-Coded Toast Notification Utility
 * @param {string} message - Text notification message
 * @param {"success"|"danger"|"error"|"warning"|"info"} [type="success"] - Notification category
 * @param {number} [duration=3500] - Duration in milliseconds
 */
window.showToast = function (message, type = "success", duration = 3500) {
  let container = document.getElementById("cmsToastContainer");
  if (!container) {
    container = document.createElement("div");
    container.id = "cmsToastContainer";
    container.className = "cms-toast-container";
    container.setAttribute("role", "status");
    container.setAttribute("aria-live", "polite");
    document.body.appendChild(container);
  }

  let normType = type;
  if (normType === "error") normType = "danger";
  if (!["success", "danger", "warning", "info"].includes(normType)) {
    normType = "info";
  }

  const icons = {
    success: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>',
    danger: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>',
    warning: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
    info: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>'
  };

  const toast = document.createElement("div");
  toast.className = `cms-toast cms-toast--${normType}`;
  toast.innerHTML = `
    <span class="cms-toast-icon" aria-hidden="true">${icons[normType]}</span>
    <span class="cms-toast-message">${String(message).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")}</span>
  `;

  container.appendChild(toast);

  requestAnimationFrame(() => {
    toast.classList.add("is-visible");
  });

  const dismissTimer = setTimeout(() => {
    toast.classList.remove("is-visible");
    setTimeout(() => {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 250);
  }, duration);

  toast.addEventListener("click", () => {
    clearTimeout(dismissTimer);
    toast.classList.remove("is-visible");
    setTimeout(() => {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 250);
  });
};

/**
 * CMSAdmin 2.0 - Page Loading UI & Transition Controller (WCAG AA Compliant)
 */
let pageProgressTimer = null;
let pageProgressValue = 0;
let pageLoaderDelayTimer = null;

window.startTopProgress = function () {
  const bar = document.getElementById("adminPageProgressBar");
  if (!bar) return;
  clearInterval(pageProgressTimer);
  pageProgressValue = 20;
  bar.classList.add("is-active");
  bar.style.width = pageProgressValue + "%";
  bar.setAttribute("aria-valuenow", String(pageProgressValue));

  pageProgressTimer = setInterval(() => {
    if (pageProgressValue < 65) {
      pageProgressValue += Math.random() * 14 + 6;
    } else if (pageProgressValue < 88) {
      pageProgressValue += Math.random() * 4 + 2;
    } else if (pageProgressValue < 96) {
      pageProgressValue += 0.5;
    }
    bar.style.width = Math.min(pageProgressValue, 96) + "%";
    bar.setAttribute("aria-valuenow", String(Math.round(pageProgressValue)));
  }, 180);
};

window.finishTopProgress = function () {
  const bar = document.getElementById("adminPageProgressBar");
  if (!bar) return;
  clearInterval(pageProgressTimer);
  pageProgressValue = 100;
  bar.style.width = "100%";
  bar.setAttribute("aria-valuenow", "100");
  setTimeout(() => {
    bar.classList.remove("is-active");
    setTimeout(() => {
      bar.style.width = "0%";
      bar.setAttribute("aria-valuenow", "0");
    }, 280);
  }, 220);
};

window.showPageLoader = function (title = "Loading Page...", subtitle = "Retrieving records, attributes, and navigation trees.") {
  const overlay = document.getElementById("adminPageLoadingOverlay");
  const titleEl = document.getElementById("adminLoaderTitle");
  const subEl = document.getElementById("adminLoaderSubtitle");

  if (titleEl) titleEl.textContent = title;
  if (subEl) subEl.textContent = subtitle;

  window.startTopProgress();

  if (overlay) {
    overlay.classList.add("is-visible");
    overlay.setAttribute("aria-busy", "true");
  }

  // Safety failsafe: auto-dismiss after 15 seconds if navigation stalled or aborted
  clearTimeout(window._adminLoaderSafetyTimer);
  window._adminLoaderSafetyTimer = setTimeout(() => {
    window.hidePageLoader();
  }, 15000);
};

window.hidePageLoader = function () {
  clearTimeout(pageLoaderDelayTimer);
  clearTimeout(window._adminLoaderSafetyTimer);
  const overlay = document.getElementById("adminPageLoadingOverlay");
  if (overlay) {
    overlay.classList.remove("is-visible");
    overlay.setAttribute("aria-busy", "false");
  }
  window.finishTopProgress();
};

window.getActiveWorkspaceCode = function () {
  const wsContainer = document.getElementById("workspaceDropdownContainer");
  if (!wsContainer) return "";
  const wsId = (wsContainer.getAttribute("data-active-ws-id") || "").trim();
  if (!wsId || wsId.toLowerCase() === "global" || wsId.toLowerCase() === "all") return "";
  return wsId;
};

// Global workspace creation guard: block creating content when no workspace is selected, while keeping Administration 100% accessible
document.addEventListener("click", function (e) {
  if (window.getActiveWorkspaceCode()) return;

  const target = e.target instanceof Element ? e.target : null;
  if (!target) return;

  // Never block anything inside the workspace selector dropdown or prompt dialog
  if (target.closest("#workspaceDropdownContainer") || target.closest("#adminPromptBackdrop")) return;

  // Check if clicking a creation link (<a>) outside of Administration (workspaces, users, settings)
  const link = target.closest("a[href]");
  if (link) {
    const rawHref = (link.getAttribute("href") || "").trim();
    if (rawHref && !rawHref.startsWith("#") && !rawHref.startsWith("javascript:")) {
      let url;
      try {
        url = new URL(link.href, window.location.origin);
      } catch (err) {
        url = null;
      }
      if (url && url.origin === window.location.origin) {
        const path = url.pathname.toLowerCase();
        const ctrl = (url.searchParams.get("controller") || "").toLowerCase();
        const act = (url.searchParams.get("action") || "").toLowerCase();
        const hasId = Number(url.searchParams.get("id") || 0) > 0;

        const isAdminRoute = path.includes("/workspaces") || path.includes("/users") || path.includes("/settings") ||
          ["workspaces", "users", "settings", "sessions", "main", "documentation"].includes(ctrl);

        if (!isAdminRoute) {
          const isBlockedModuleLink =
            path === "/events" || path.startsWith("/events/") ||
            path === "/calendar" || path.startsWith("/calendar/") ||
            path === "/alerts" || path.startsWith("/alerts/") ||
            path.includes("/pages/howdoi") || path.includes("/pages/how-do-i") ||
            ctrl === "events" || ctrl === "alerts" ||
            (ctrl === "pages" && (act === "howdoi" || act === "how-do-i"));

          const isCreateLink =
            path.endsWith("/new") || path.includes("/new/") ||
            path.endsWith("/create") ||
            path.endsWith("/upload") || path.includes("/media/upload") ||
            ((path.includes("/forms/builder") || path.includes("/form-builder") || (ctrl === "forms" && act === "builder")) && !hasId) ||
            ((path.includes("/pages/edit") || (ctrl === "pages" && act === "edit")) && !hasId) ||
            ["new", "create", "upload"].includes(act);

          if (isBlockedModuleLink || isCreateLink) {
            e.preventDefault();
            e.stopPropagation();
            window.adminAlert({
              title: "Workspace Required",
              message: isBlockedModuleLink
                ? "Please select a workspace from the top header before opening this module."
                : "Please select a workspace from the top header before creating content.",
              type: "warning"
            });
            return;
          }
        }
      }
    }
  }

  // Check if clicking a content-creation button when not on an Administration page
  const pagePath = window.location.pathname.toLowerCase();
  const pageParams = new URLSearchParams(window.location.search);
  const pageCtrl = (pageParams.get("controller") || "").toLowerCase();
  const onAdminPage = pagePath.includes("/workspaces") || pagePath.includes("/users") || pagePath.includes("/settings") ||
    ["workspaces", "users", "settings"].includes(pageCtrl);

  if (!onAdminPage) {
    const btn = target.closest("button");
    if (btn) {
      const btnId = (btn.id || "").toLowerCase();
      const onclickAttr = (btn.getAttribute("onclick") || "").toLowerCase();
      const isCreateBtn =
        btnId === "navadditem" ||
        btnId.includes("addpage") ||
        btnId.includes("create") ||
        btnId.includes("new") ||
        btnId.includes("upload") ||
        onclickAttr.includes("openaddpagemodal") ||
        onclickAttr.includes("openmodal") ||
        onclickAttr.includes("openupload") ||
        onclickAttr.includes("create");

      if (isCreateBtn && !onclickAttr.includes("workspacedropdownbtn")) {
        e.preventDefault();
        e.stopPropagation();
        window.adminAlert({
          title: "Workspace Required",
          message: "Please select a workspace from the top header before creating content.",
          type: "warning"
        });
        return;
      }
    }
  }
}, true);

// Automatic navigation click interceptor for seamless loading feedback
document.addEventListener("click", function (e) {
  if (e.defaultPrevented) return;
  const link = e.target.closest("a");
  if (!link || !link.href) return;

  // Skip external, target=_blank, download, data-no-loader, or modifier key clicks
  if (link.target === "_blank" || link.hasAttribute("download") || link.hasAttribute("data-no-loader")) return;
  if (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey || e.button !== 0) return;

  const rawHref = link.getAttribute("href") || "";
  if (rawHref.startsWith("#") || rawHref.startsWith("javascript:") || link.hasAttribute("data-confirm")) return;

  let url;
  try {
    url = new URL(link.href, window.location.origin);
  } catch (err) {
    return;
  }

  if (url.origin !== window.location.origin) return;
  if (url.pathname === window.location.pathname && url.search === window.location.search && url.hash !== window.location.hash) return;

  // Start instant progress bar on any internal navigation
  window.startTopProgress();

  let title = "Loading Page...";
  let subtitle = "Connecting to Chelan County server...";
  const path = url.pathname.toLowerCase();

  if (path.includes("/pages/edit") || (url.searchParams.has("controller") && url.searchParams.get("controller") === "pages" && url.searchParams.get("action") === "edit")) {
    title = url.searchParams.has("id") ? "Opening Page Editor..." : "Initializing New Page...";
    subtitle = "Loading layout, navigation trees, and media assets...";
  } else if (path.includes("/pages") || (url.searchParams.has("controller") && url.searchParams.get("controller") === "pages")) {
    title = "Loading Content Manager...";
    subtitle = "Retrieving page hierarchy, status metrics, and workspaces...";
  } else if (path.includes("/forms")) {
    title = "Loading Form Studio...";
    subtitle = "Retrieving form builder definitions...";
  } else if (path.includes("/media")) {
    title = "Loading Media Library...";
    subtitle = "Scanning workspace files and document directories...";
  }

  // If page does not arrive in 120ms, show the centered overlay
  clearTimeout(pageLoaderDelayTimer);
  pageLoaderDelayTimer = setTimeout(function () {
    const overlay = document.getElementById("adminPageLoadingOverlay");
    const titleEl = document.getElementById("adminLoaderTitle");
    const subEl = document.getElementById("adminLoaderSubtitle");
    if (titleEl) titleEl.textContent = title;
    if (subEl) subEl.textContent = subtitle;
    if (overlay) overlay.classList.add("is-visible");
  }, 120);
});

// Dismiss loader on bfcache page restore
window.addEventListener("pageshow", function () {
  window.hidePageLoader();
});

/**
 * Universal Clipboard Copy Helper
 * Works reliably across all browsers in both Secure (HTTPS) and Insecure (HTTP / Intranet) contexts.
 * @param {string} text - Content to copy to system clipboard
 * @returns {Promise<boolean>} - Resolves true if copied successfully
 */
window.copyToClipboard = async function (text) {
  if (text === null || text === undefined) return false;
  const str = String(text);

  // 1. Try modern Async Clipboard API if available and running in a secure context
  if (window.isSecureContext && navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
    try {
      await navigator.clipboard.writeText(str);
      return true;
    } catch (err) {
      // Permission denied or write error, fallback to legacy mechanism
    }
  }

  // 2. Synchronous textarea selection with document.execCommand('copy')
  // This works universally across all origins, including plain HTTP (http://cmsadmin.chelancounty.gov)
  try {
    const textArea = document.createElement("textarea");
    textArea.value = str;
    textArea.style.position = "fixed";
    textArea.style.top = "0";
    textArea.style.left = "0";
    textArea.style.width = "2em";
    textArea.style.height = "2em";
    textArea.style.padding = "0";
    textArea.style.border = "none";
    textArea.style.outline = "none";
    textArea.style.boxShadow = "none";
    textArea.style.background = "transparent";
    textArea.style.opacity = "0";
    textArea.setAttribute("readonly", "");
    document.body.appendChild(textArea);

    textArea.focus({ preventScroll: true });
    textArea.select();
    textArea.setSelectionRange(0, str.length);

    const successful = document.execCommand("copy");
    document.body.removeChild(textArea);
    if (successful) return true;
  } catch (err) {}

  // 3. If both modern and execCommand fail, return false (never use native window.prompt per CMSAdmin invariants)
  return false;
};

document.addEventListener("DOMContentLoaded", () => {
  document.addEventListener("click", async (event) => {
    const link = event.target instanceof Element ? event.target.closest("a[data-confirm]") : null;
    if (!link) return;
    event.preventDefault();
    if (await window.adminConfirm(link.getAttribute("data-confirm"), {
      title: link.getAttribute("data-confirm-title") || "Delete workspace?",
      acceptText: link.getAttribute("data-confirm-accept") || "Delete",
      destructive: true
    })) {
      window.location.assign(link.href);
    }
  });

  // 1. Sidebar Toggle (Desktop Collapse & Mobile Off-canvas)
  const toggleBtn = document.getElementById("btnToggleSidebar");
  const body = document.body;
  const backdrop = document.getElementById("sidebarBackdrop");

  // Restore saved desktop state from localStorage
  const savedSidebarState = localStorage.getItem("cmsadmin_sidebar_collapsed");
  if (savedSidebarState === "true" && window.innerWidth > 992) {
    body.classList.add("sidebar-collapsed");
  }

  if (toggleBtn) {
    toggleBtn.addEventListener("click", (e) => {
      e.preventDefault();
      if (window.innerWidth <= 992) {
        body.classList.toggle("sidebar-mobile-open");
      } else {
        body.classList.toggle("sidebar-collapsed");
        localStorage.setItem("cmsadmin_sidebar_collapsed", body.classList.contains("sidebar-collapsed"));
      }
    });
  }

  if (backdrop) {
    backdrop.addEventListener("click", () => {
      body.classList.remove("sidebar-mobile-open");
    });
  }

  // 2. Sidebar Collapsible Submenus
  const menuToggles = document.querySelectorAll(".nav-item.has-submenu > .nav-link");
  menuToggles.forEach((link) => {
    link.addEventListener("click", (e) => {
      e.preventDefault();
      const parent = link.closest(".nav-item");
      const wasOpen = parent.classList.contains("open");

      // Optional: accordion mode (close siblings)
      const siblings = parent.parentElement.querySelectorAll(".nav-item.has-submenu");
      siblings.forEach((sibling) => {
        if (sibling !== parent) sibling.classList.remove("open");
      });

      if (wasOpen) {
        parent.classList.remove("open");
      } else {
        parent.classList.add("open");
      }
    });
  });

  // 3. Dropdowns (Accessible click-outside toggle)
  const dropdownToggles = document.querySelectorAll("[data-toggle='dropdown']");
  dropdownToggles.forEach((toggle) => {
    toggle.addEventListener("click", (e) => {
      e.stopPropagation();
      const dropdown = toggle.closest(".dropdown");
      const isOpen = dropdown.classList.contains("active");

      // Close all other dropdowns
      document.querySelectorAll(".dropdown.active").forEach((d) => {
        if (d !== dropdown) d.classList.remove("active");
      });

      dropdown.classList.toggle("active", !isOpen);

      // If opening workspace dropdown, auto-focus filter input
      if (!isOpen && dropdown.id === "workspaceDropdownContainer") {
        const filterInput = document.getElementById("workspaceFilterInput");
        if (filterInput) {
          setTimeout(() => {
            filterInput.focus();
            filterInput.select();
          }, 50);
        }
      }
    });
  });

  // Prevent clicks inside dropdown menu (e.g. search filter input) from closing dropdown prematurely
  document.querySelectorAll(".dropdown-menu").forEach((menu) => {
    menu.addEventListener("click", (e) => {
      if (!e.target.closest("a, button.workspace-item, .dropdown-item")) {
        e.stopPropagation();
      }
    });
  });

  // Close dropdowns on click outside or Escape
  document.addEventListener("click", () => {
    document.querySelectorAll(".dropdown.active").forEach((d) => d.classList.remove("active"));
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      document.querySelectorAll(".dropdown.active").forEach((d) => d.classList.remove("active"));
      body.classList.remove("sidebar-mobile-open");
    }

    // Workspace switcher shortcut: Alt+W or Ctrl+K (replaces search shortcut)
    if ((e.altKey && (e.key === "w" || e.key === "W")) || (e.ctrlKey && e.key === "k")) {
      e.preventDefault();
      const wsCont = document.getElementById("workspaceDropdownContainer");
      const wsInput = document.getElementById("workspaceFilterInput");
      if (wsCont) {
        document.querySelectorAll(".dropdown.active").forEach((d) => {
          if (d !== wsCont) d.classList.remove("active");
        });
        wsCont.classList.add("active");
        if (wsInput) {
          setTimeout(() => {
            wsInput.focus();
            wsInput.select();
          }, 50);
        }
      }
    }
  });

  // 4. Fullscreen Toggle
  const fullscreenBtn = document.getElementById("btnFullscreen");
  if (fullscreenBtn) {
    fullscreenBtn.addEventListener("click", () => {
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(() => {});
      } else {
        if (document.exitFullscreen) {
          document.exitFullscreen().catch(() => {});
        }
      }
    });
  }

  // 5. Alert / Flash message dismiss
  const alertCloseBtns = document.querySelectorAll(".alert .alert-close");
  alertCloseBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      const alert = btn.closest(".alert");
      if (alert) {
        alert.style.opacity = "0";
        alert.style.transform = "scale(0.96)";
        setTimeout(() => alert.remove(), 200);
      }
    });
  });

  // 6. Workspace Dropdown & Selection Management (Department or Site)
  const WORKSPACE_ICONS = {
    grid: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/></svg>',
    building: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/></svg>',
    briefcase: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="14" x="2" y="7" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>',
    megaphone: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>',
    globe: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/></svg>'
  };

  const wsContainer = document.getElementById("workspaceDropdownContainer");
  const wsTitleEl = document.getElementById("activeWsTitle");
  const wsIconEl = document.getElementById("activeWsIcon");
  const wsPillEl = document.getElementById("activeWsTypePill");
  const wsFilterInput = document.getElementById("workspaceFilterInput");
  const wsItems = document.querySelectorAll(".workspace-item");
  const wsNoResults = document.getElementById("workspaceNoResults");
  const WS_STORAGE_KEY = "cmsadmin_active_workspace";

  function applyWorkspacePrimaryColor(hexColor) {
    const cleanColor = (hexColor && /^#[0-9a-fA-F]{3,6}$/.test(hexColor.trim())) ? hexColor.trim() : "#0073aa";
    const targets = [document.documentElement, document.body].filter(Boolean);
    targets.forEach((el) => {
      el.style.setProperty("--admin-primary", cleanColor);
      el.style.setProperty("--admin-primary-hover", "color-mix(in srgb, " + cleanColor + " 80%, #000000)");
      el.style.setProperty("--admin-primary-light", "color-mix(in srgb, " + cleanColor + " 10%, #ffffff)");
      el.style.setProperty("--admin-primary-focus", "color-mix(in srgb, " + cleanColor + " 25%, transparent)");
    });
  }

  function setActiveWorkspace(wsData, save = true) {
    if (!wsData) return;

    const isAdmin = wsContainer ? wsContainer.getAttribute("data-is-admin") === "true" : true;
    const allowedItems = Array.from(document.querySelectorAll(".workspace-item"));
    const allowedIds = allowedItems.map((item) => item.getAttribute("data-ws-id"));

    // If an unselected/prompt workspace is passed
    if (!wsData.id) {
      applyWorkspacePrimaryColor("#0073aa");
      if (wsTitleEl) wsTitleEl.textContent = "Please select a workspace";
      if (wsPillEl) {
        wsPillEl.textContent = "Select";
        wsPillEl.className = "workspace-btn-pill badge-neutral";
      }
      if (wsIconEl && WORKSPACE_ICONS["grid"]) {
        wsIconEl.innerHTML = WORKSPACE_ICONS["grid"];
      }
      if (wsContainer) {
        wsContainer.setAttribute("data-active-ws-id", "");
        wsContainer.setAttribute("data-active-ws-color", "#0073aa");
        wsContainer.setAttribute("data-active-ws-virtual-dir", "shared");
      }
      wsItems.forEach((item) => item.classList.remove("is-active"));
      if (save) {
        try {
          localStorage.removeItem(WS_STORAGE_KEY);
          document.cookie = "cmsadmin_workspace=; path=/; max-age=0; SameSite=Lax";
        } catch (e) {}
      }
      window.dispatchEvent(new CustomEvent("cmsadmin:workspaceChanged", { detail: wsData }));
      return;
    }

    // Security Gate: Non-admin users can ONLY access their assigned workspaces (never global or unassigned)
    if (!isAdmin && (wsData.id === "global" || wsData.id === "all" || !allowedIds.includes(wsData.id))) {
      if (allowedItems.length > 0) {
        const fallback = allowedItems[0];
        wsData = {
          id: fallback.getAttribute("data-ws-id"),
          name: fallback.getAttribute("data-ws-name"),
          type: fallback.getAttribute("data-ws-type"),
          color: fallback.getAttribute("data-ws-color") || "#0073aa",
          badge: fallback.getAttribute("data-ws-badge"),
          badgeCls: fallback.getAttribute("data-ws-badge-cls"),
          icon: fallback.getAttribute("data-ws-icon"),
          virtualDir: fallback.getAttribute("data-ws-virtual-dir") || fallback.getAttribute("data-ws-id"),
          storageFolder: fallback.getAttribute("data-ws-storage-folder") || fallback.getAttribute("data-ws-virtual-dir") || fallback.getAttribute("data-ws-id")
        };
      } else {
        return;
      }
    }

    if (!wsData.color) {
      const matchedItem = allowedItems.find((item) => (item.getAttribute("data-ws-id") || "").toLowerCase() === (wsData.id || "").toLowerCase());
      wsData.color = (matchedItem && matchedItem.getAttribute("data-ws-color")) || (wsContainer && wsContainer.getAttribute("data-active-ws-color")) || "#0073aa";
    }
    applyWorkspacePrimaryColor(wsData.color);

    if (wsTitleEl) wsTitleEl.textContent = wsData.name || "Please select a workspace";
    if (wsPillEl) {
      wsPillEl.textContent = wsData.badge || (wsData.type === "dept" ? "Dept" : (wsData.type === "site" ? "Site" : "Select"));
      wsPillEl.className = "workspace-btn-pill " + (wsData.badgeCls || "badge-neutral");
    }
    if (wsIconEl && wsData.icon && WORKSPACE_ICONS[wsData.icon]) {
      wsIconEl.innerHTML = WORKSPACE_ICONS[wsData.icon];
    }
    if (wsContainer) {
      wsContainer.setAttribute("data-active-ws-id", wsData.id);
      wsContainer.setAttribute("data-active-ws-color", wsData.color);
      wsContainer.setAttribute("data-active-ws-virtual-dir", wsData.virtualDir || wsData.id);
      wsContainer.setAttribute("data-active-ws-storage-folder", wsData.storageFolder || wsData.virtualDir || wsData.id);
    }

    // Update active highlight & checkmark in dropdown list
    wsItems.forEach((item) => {
      const isCurrent = item.getAttribute("data-ws-id") === wsData.id;
      item.classList.toggle("is-active", isCurrent);
    });

    if (save) {
      try {
        localStorage.setItem(WS_STORAGE_KEY, JSON.stringify(wsData));
        document.cookie = "cmsadmin_workspace=" + encodeURIComponent(wsData.id) + "; path=/; max-age=31536000; SameSite=Lax";
      } catch (e) {}
    }

    // Broadcast workspace change event to entire application
    window.dispatchEvent(new CustomEvent("cmsadmin:workspaceChanged", {
      detail: wsData
    }));

    // If currently on Forms dashboard, auto-synchronize with department filter tabs
    const deptTabs = document.querySelectorAll(".dept-filter-tabs .tab-item");
    if (deptTabs.length > 0) {
      let targetTab = null;
      if (wsData.id === "hrm") {
        targetTab = document.querySelector(".dept-filter-tabs .tab-item[data-filter='hrm']");
      } else if (wsData.id === "pio") {
        targetTab = document.querySelector(".dept-filter-tabs .tab-item[data-filter='pio']");
      } else if (wsData.id === "global") {
        targetTab = document.querySelector(".dept-filter-tabs .tab-item[data-filter='all']");
      }
      if (targetTab && !targetTab.classList.contains("active")) {
        targetTab.click();
      }
    }

    updateMediaNavLinks(wsData.id);
  }

  function updateMediaNavLinks(wsId) {
    const mediaLinks = document.querySelectorAll("a[href*='/media']");
    mediaLinks.forEach((link) => {
      const href = link.getAttribute("href") || "";
      if (href === "/media" || href.startsWith("/media?") || href === "/index.cfm/media" || href.startsWith("/index.cfm/media?")) {
        const basePath = href.split("?")[0];
        link.setAttribute("href", basePath);
      }
    });
  }

  // On page load, synchronize client-side workspace state with the server-rendered DOM.
  // The server-rendered workspace (from cookie or URL) is the authoritative source of truth for the loaded page.
  try {
    const isAdmin = wsContainer ? wsContainer.getAttribute("data-is-admin") === "true" : true;
    const serverActiveWsId = wsContainer ? wsContainer.getAttribute("data-active-ws-id") : null;
    const allowedItems = Array.from(document.querySelectorAll(".workspace-item"));
    const allowedIds = allowedItems.map((item) => item.getAttribute("data-ws-id"));

    let targetItem = null;
    if (serverActiveWsId) {
      targetItem = allowedItems.find((item) => (item.getAttribute("data-ws-id") || "").toLowerCase() === serverActiveWsId.toLowerCase());
    }

    if (targetItem) {
      const currentServerWs = {
        id: targetItem.getAttribute("data-ws-id"),
        name: targetItem.getAttribute("data-ws-name"),
        type: targetItem.getAttribute("data-ws-type"),
        color: targetItem.getAttribute("data-ws-color") || (wsContainer && wsContainer.getAttribute("data-active-ws-color")) || "#0073aa",
        badge: targetItem.getAttribute("data-ws-badge"),
        badgeCls: targetItem.getAttribute("data-ws-badge-cls"),
        icon: targetItem.getAttribute("data-ws-icon"),
        virtualDir: targetItem.getAttribute("data-ws-virtual-dir") || targetItem.getAttribute("data-ws-id"),
        storageFolder: targetItem.getAttribute("data-ws-storage-folder") || targetItem.getAttribute("data-ws-virtual-dir") || targetItem.getAttribute("data-ws-id")
      };
      // Keep UI in lockstep with the server-rendered page and update localStorage to match
      setActiveWorkspace(currentServerWs, true);
    } else if (!serverActiveWsId) {
      // No workspace selected on server
      setActiveWorkspace({ id: "", name: "Please select a workspace" }, false);
    }
  } catch (e) {}

  // Handle click on workspace item
  wsItems.forEach((item) => {
    item.addEventListener("click", (e) => {
      e.preventDefault();
      const newWsId = (item.getAttribute("data-ws-id") || "").trim();
      if (!newWsId) return;

      // Check currently active workspace ID from container or active item
      const activeItem = document.querySelector(".workspace-item.is-active");
      const currentWsId = (wsContainer ? (wsContainer.getAttribute("data-active-ws-id") || (activeItem ? activeItem.getAttribute("data-ws-id") : "")) : (activeItem ? activeItem.getAttribute("data-ws-id") : "") || "").trim();

      const wsData = {
        id: newWsId,
        name: item.getAttribute("data-ws-name") || newWsId,
        type: item.getAttribute("data-ws-type") || "dept",
        color: item.getAttribute("data-ws-color") || "#0073aa",
        badge: item.getAttribute("data-ws-badge") || "",
        badgeCls: item.getAttribute("data-ws-badge-cls") || "",
        icon: item.getAttribute("data-ws-icon") || "grid",
        virtualDir: item.getAttribute("data-ws-virtual-dir") || newWsId,
        storageFolder: item.getAttribute("data-ws-storage-folder") || item.getAttribute("data-ws-virtual-dir") || newWsId
      };

      // Set cookie and local storage immediately
      setActiveWorkspace(wsData, true);

      // Close dropdown
      if (wsContainer) wsContainer.classList.remove("active");

      // Resolve Dashboard URL
      const dashboardPath = (wsContainer && wsContainer.getAttribute("data-dashboard-url")) || "/";
      const dashboardUrl = new URL(dashboardPath, window.location.origin);
      dashboardUrl.searchParams.set("ws", newWsId);

      // Disarm any unload or unsaved changes warnings ("no questions asked")
      window.onbeforeunload = null;
      window.addEventListener("beforeunload", (evt) => {
        evt.stopImmediatePropagation();
      }, true);

      // Ensure cookie is written synchronously before navigation
      document.cookie = "cmsadmin_workspace=" + encodeURIComponent(newWsId) + "; path=/; max-age=31536000; SameSite=Lax";

      // On switching workspace from header, always force reset to dashboard
      window.showPageLoader("Switching Workspace...", "Switching to " + (wsData.name || "workspace") + " and loading Dashboard...");
      window.location.assign(dashboardUrl.toString());
    });
  });

  // Real-time filter/search inside workspace dropdown
  if (wsFilterInput) {
    wsFilterInput.addEventListener("input", () => {
      const q = wsFilterInput.value.trim().toLowerCase();
      let matchCount = 0;

      wsItems.forEach((item) => {
        const name = (item.getAttribute("data-ws-name") || "").toLowerCase();
        const type = (item.getAttribute("data-ws-type") || "").toLowerCase();
        const sub = item.querySelector(".workspace-item-sub") ? item.querySelector(".workspace-item-sub").textContent.toLowerCase() : "";
        const matches = !q || name.includes(q) || type.includes(q) || sub.includes(q);

        item.style.display = matches ? "flex" : "none";
        if (matches) matchCount++;
      });

      // Show/hide section headings based on whether matching items exist under them
      const sectionTitles = document.querySelectorAll(".workspace-menu-section-title");
      sectionTitles.forEach((title) => {
        let next = title.nextElementSibling;
        let hasVisibleChild = false;
        while (next && !next.classList.contains("workspace-menu-section-title") && !next.classList.contains("workspace-no-results")) {
          if (next.classList.contains("workspace-item") && next.style.display !== "none") {
            hasVisibleChild = true;
            break;
          }
          next = next.nextElementSibling;
        }
        title.style.display = (hasVisibleChild || !q) ? "block" : "none";
      });

      if (wsNoResults) {
        wsNoResults.style.display = matchCount === 0 ? "block" : "none";
      }
    });
  }
});
