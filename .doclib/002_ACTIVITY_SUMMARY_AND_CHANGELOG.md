# Series 002: Activity Summary & Engineering Changelog
**Location:** `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Executive Summary

This log maintains a chronological, permanent record of engineering milestones, schema migrations, architectural refinements, and verified features in Chelan County CMSAdmin 2.0. All AI agents and developers must append new activities to this log upon completing any significant change.

---

## 2. Chronological Milestones

### Session: October 22, 2026 — Git Remote Repository Synchronization (Local Working Copy Override to Origin Main)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Complete Repository (`main` branch -> `origin/main`).
- **Key Deliverables:**
  1. **Full Working Tree Synchronization:**
     - Staged all accumulated engineering milestones including One Page Studio (`app/views/pages/onePage.cfm`, `Pages.cfc::publishOnePageToProduction`), JBDEditor table & image properties dialogs with floating contextual toolbars, form notification mailer & recipient email settings (`Forms.cfc`), login screen seal branding (250px centered) & auto-dismissing alerts (`sessions/new.cfm`), separated runtime assets (`javascripts/onepage/`, `stylesheets/onepage/`), automated test suites (`test_one_page_studio.cfm`, `test_form_email_settings.cfm`), and complete `.doclib` architectural books of record.
     - Committed as `feat(studio,forms,editor,auth): add One Page Studio with direct production publishing, form email settings, table & image editor tools, and login UX updates` (`7ac2ffa`).
     - Successfully pushed to remote repository (`https://github.com/chelancountyit/CMSAdmin2.0.git`, `main -> main`).
  2. **Working Tree Cleanliness:**
     - Working tree 100% clean and perfectly aligned with remote `origin/main`.

### Session: October 21, 2026 — One Page Studio: Expanded Section Background Styles Suite (Abstract Curly Lines, Cream Gradients, Topographic Waves & Live Modal Swatch Preview)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/controllers/Pages.cfc`, `app/views/pages/onePage.cfm`, `.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Expanded Section Background Styles (`Pages.cfc::buildOnePageCss` & `app/views/pages/onePage.cfm`):**
     - Enriched section background styling beyond the original 4 basic styles with 11 versatile, 100% local, zero-CDN CSS/SVG presets:
       - `default`: Default White Surface (`#ffffff`).
       - `muted`: Soft Muted Gray (`#f8fafc`).
       - `surface-elevated`: Elevated Subtle Slate (`#f1f5f9`).
       - `cream-gradient`: Gradient Cream to White (Warm ivory to pure white gradient with gold-tinted eyebrow text).
       - `curly-lines`: Abstract Two-Tone Curly Lines (Dual-tone flowing bezier wave ribbons in forest green and warm amber/sky blue with soft radial ambiance).
       - `topo-contours`: Topographic Contour Waves (Organic topographic elevation curves, ideal for parks, river trails, and public lands).
       - `nature-sage`: Forest Mist & Soft Sage (Delicate pale sage green gradient with organic tone).
       - `soft-sunset`: Warm Ochre / Desert Sand (Subtle sand/terracotta gradient).
       - `geometric-mesh`: Subtle Technical Grid Mesh (Precision dot matrix intersection pattern).
       - `dark`: Dark High-Contrast Midnight (`#0f172a` slate with gold accents).
       - `dark-lines`: Dark Glowing Wave Lines (Midnight canvas with glowing emerald and cyan waves).
  2. **Section Configuration Modal & Live Swatch Preview (`app/views/pages/onePage.cfm`):**
     - Expanded the "Background Style" dropdown (`#opsSecBg`) in the Section Edit modal to surface all 11 background style options.
     - Added a live visual swatch preview box (`#opsSecBgPreview`) directly beneath the dropdown that reactively displays the selected gradient, curly line, or contour texture in real time.
     - Synchronized modal opening logic (`openEditSection`) and dropdown `change` event listener to update the swatch immediately.
  3. **Verification & Stability:**
     - Verified CSS generation in live preview: `.ops-bg-cream-gradient` and `.ops-bg-curly-lines` verified in `/pages/one-page/preview?id=1`.
     - Executed full test suite: **46 / 46 One Page Studio tests passed (100% green)**.

### Session: October 21, 2026 — Login Screen: Seal Logo Enlargement (250px Centered) & Auto-Dismissing Session/Error Alerts
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/views/sessions/new.cfm`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Logo Visual Presentation (250px Height & Centered):**
     - Scaled the Chelan County Seal (`.login-seal`) on the authentication screen (`/login`) from 68px to `height: 250px; max-height: 250px; width: auto; max-width: 100%; object-fit: contain;`.
     - Centered the element cleanly via `display: block; margin-left: auto; margin-right: auto; margin-bottom: 1.25rem;` within `.login-brand-header`.
     - Added enhanced depth shadow (`filter: drop-shadow(0 8px 24px rgba(0, 0, 0, 0.35))`) and smooth interactive hover scale (`scale(1.02)`).
     - Configured responsive scaling in `@media (max-width: 480px)` to clamp height to `180px` on compact mobile viewports, preventing vertical overflow.
  2. **Auto-Hiding Session & Error Messages Engine:**
     - **Session / Flash Messages (`#flashAlertContainer`):** Added automated dismissal timer that smoothly fades out server-rendered flash/session messages (e.g. timeout notices) after 5 seconds with pause-on-hover capability and click-to-dismiss support.
     - **In-Card Error & Success Alerts (`#loginErrorAlert`, `#loginSuccessAlert`):** Enhanced `showError()` and `showSuccess()` with an auto-dismiss timer (5 seconds) with smooth CSS opacity/translation transitions.
     - **Pause-on-Hover:** Built `attachAutoHideWithPause()` so alerts remain visible while the user is hovering their mouse over the message to read it.
     - **Instant Clear on Input:** Added real-time input listeners to `#emailInput`, `#otpInput`, `#authCodeInput`, and `#connectCodeInput` to dismiss errors the moment the user resumes typing.
     - **Accessible Close Button:** Embedded an inline dismiss button (`.login-alert-dismiss`) with SVG icon (`x`) on alert containers for instant manual dismissal.
  3. **Verification & Stability:**
     - Full converter & HTTP suite tested and green: **54 / 54 tests passing in `tests/run_full_test_suite.cfm`**.
     - One Page Studio suite tested and green: **46 / 46 tests passing in `tests/test_one_page_studio.cfm`**.

### Session: October 21, 2026 — One Page Studio: "Publish to Production" Direct Server Deployment Pipeline (Decoupled Assets in workspace.project_path)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`config/routes.cfm`, `app/controllers/Pages.cfc`, `app/controllers/Controller.cfc`, `app/views/pages/onePage.cfm`, `tests/test_one_page_studio.cfm`, `.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Primary Production Action Button (`app/views/pages/onePage.cfm`):**
     - Replaced the secondary "Export Modular Bundle (.ZIP)" button with the primary **"Publish to Production"** button (`#btnOpsPublishProduction`) styled as a high-visibility `btn btn-success` with `#svgIcon(name="upload", size=16)#`.
     - Standardized user confirmation via `window.adminConfirm(...)` (complying strictly with Chelan County non-negotiable invariants: zero native `confirm()` or `alert()` dialogs, 100% accessible).
     - Provides clear visual status feedback: transitions to `"Publishing to Production..."` during deployment and shows non-blocking toast notifications upon completion via `window.showToast()`.
  2. **Direct Server Deployment Pipeline (`Pages.cfc::publishOnePageToProduction`):**
     - Registered POST route `/pages/one-page/publish-production` mapped to `pages#publishOnePageToProduction`.
     - Added CSRF exemption in `Pages.cfc::config()` and updated `Controller.cfc::enforceWorkspaceSelection()` to allow direct workspace resolution from `dbo.one_page_sites.siteid`.
     - **Filesystem Discovery:** Resolves target physical project root via `cms_workspaces.project_path` (e.g. `C:\inetpub\wenatcheeriverpark.org`, `C:\inetpub\ohmegardens.org`, `C:\inetpub\chelan-county`).
     - **Automated Directory Tree Provisioning:** Recursively validates and creates `[project_path]\assets\css\`, `[project_path]\assets\js\`, and `[project_path]\assets\images\`.
     - **Decoupled Assets Deployment:**
       - Writes generated production stylesheet to `[project_path]\assets\css\site.css` via `buildOnePageCss(site)`.
       - Writes generated production JavaScript runtime to `[project_path]\assets\js\site.js` via `buildOnePageJs(site)`.
       - Automatically scans active section markup for local photography/media attachments (e.g., `/files/shared/media/...`), copies physical image files into `[project_path]\assets\images\`, and rewrites HTML `src` attributes to relative `assets/images/[filename]` for 100% self-contained offline deployment.
       - Generates decoupled production `[project_path]\index.html` linking `assets/css/site.css` and `assets/js/site.js`.
       - Emits comprehensive deployment guide and accessibility audit report to `[project_path]\README.md`.
  3. **Verification & Full Automated Test Coverage (`tests/test_one_page_studio.cfm`):**
     - Added **SUITE 8: Publish to Production (workspace.project_path Deployment)** to `tests/test_one_page_studio.cfm`.
     - Validates end-to-end authenticated HTTP POST execution, JSON `success=true` response, physical existence of `index.html`, `assets/css/site.css`, `assets/js/site.js`, and `README.md` in `C:\inetpub\wenatcheeriverpark.org`, and verified asset `<link>` / `<script>` references.
     - **All 46 / 46 One Page Studio tests passing (100% green, 0 failures)**.
     - Full test suite verified passing: **54 / 54 tests passing in `tests/run_full_test_suite.cfm`**.

### Session: October 21, 2026 — One Page Studio: Decoupled Asset Separation (Compilation Pipeline & Standalone Modular ZIP Bundle)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/controllers/Pages.cfc`, `app/views/pages/onePage.cfm`, `stylesheets/onepage/`, `javascripts/onepage/`, `tests/test_one_page_studio.cfm`, `.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Decoupled Asset Generation & Compilation Pipeline (`compileOnePageSite`):**
     - Introduced `separateAssets` compilation parameter (defaulting to `true` with UI checkbox control).
     - **Dedicated CSS Generator (`buildOnePageCss`):** Generates modular production stylesheets with visual theme tokens (`--ops-primary`, `--ops-gold`, etc. for `river-park`, `modern-municipal`, `clean-editorial`, and `dark-luxury`), resets, typography, sticky navigation, responsive hero, split grid, section variations, table styling, and site custom CSS. Automatically persists to `/stylesheets/onepage/[slug].css`.
     - **Dedicated Vanilla JS Runtime (`buildOnePageJs`):** Generates modular production JavaScript supporting smooth anchor scrolling, `IntersectionObserver`-based Section Scrollspy, mobile navigation toggle drawer (`aria-expanded`, `aria-controls`), and back-to-top button. Automatically persists to `/javascripts/onepage/[slug].js`.
     - **Clean `dbo.pages.Body` Storage:** Decouples database storage from monolithic style/script bloat by storing clean semantic HTML referencing `<link rel="stylesheet" href="/stylesheets/onepage/[slug].css">` and `<script defer src="/javascripts/onepage/[slug].js"></script>`. Preserves backward-compatible inline fallback when `separateAssets` is set to false.
  2. **Standalone Modular Package Generator (`.ZIP` Bundle in `exportOnePageSite`):**
     - Added `format=zip` export support via native ColdFusion `<cfzip>` streaming in-memory archives.
     - **Bundle Architecture:** Packages `index.html` (referencing `assets/css/site.css` and `assets/js/site.js`), `assets/css/site.css`, `assets/js/site.js`, and `README.md` (comprehensive hosting, accessibility, and file structure documentation).
     - **Local Media Bundling:** Automatically locates section images (e.g. `/files/shared/media/...`, `/images/...`), bundles them into `assets/images/`, and rewrites HTML image tags for 100% self-contained, offline-ready deployment without external CDNs.
  3. **Studio UI Enhancements (`app/views/pages/onePage.cfm`):**
     - Added "Separate Assets (.css & .js)" toggle switch in the Publish & Actions sidebar card.
     - Added **"Export Modular Bundle (.ZIP)"** button alongside "Export Standalone HTML File".
     - Connected UI handlers to compile with `separateAssets` flag and download ZIP or HTML bundles directly.
  4. **Verification & Full Integration Testing (`tests/test_one_page_studio.cfm`):**
     - Appended **SUITE 7: Asset Separation in One Page Studio** validating CSS/JS file creation in physical directories, ZIP bundle generation with HTTP 200 `application/zip`, zip file entries verification, and standalone HTML export with separated links.
     - Executed full suite: **36 / 36 tests passing (100% pass rate, 0 failures)**.

### Session: October 21, 2026 — JBDEditor: Advanced Table Suite (In-Editor Bubble Toolbar, Drag-Resizing, Properties Modal, and WCAG Scope Standards)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`stylesheets/jbdeditor.css`, `stylesheets/jbd-templates.css`, `vendor/jbdeditor/css/editor.css`, `javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `javascripts/jbdeditor/editor.js`, `javascripts/jbdeditor/jbdeditor.js`, `javascripts/jbdeditor/jaleditor.js`, `vendor/jbdeditor/src/dialog.js`, `vendor/jbdeditor/src/editor.js`, `vendor/jbdeditor/src/jbdeditor.js`, `vendor/jbdeditor/src/jaleditor.js`, `app/views/layout.cfm`, `vendor/jbdeditor/test.html`).
- **Key Deliverables:**
  1. **Comprehensive Table Properties & Presentation Dialog (`Dialog.openTableDialog`):**
     - Enhanced modal supporting both new table creation and in-place editing of existing tables (`existingData`).
     - **Accessibility & WCAG 2.1 AA Compliance:** Full support for `th[scope="col"]`, `th[scope="row"]`, and `caption` summary describing table contents for screen readers.
     - **Presentation Controls:** Configurable width presets (100% Full Width, 75%, 50%, Auto fit-to-content), alignment (Center Block, Left Align, Right Align), styled borders (`.jbd-table-bordered`), alternating striped rows (`.jbd-table-striped`), hover highlights (`.jbd-table-hover`), and compact cell padding (`.jbd-table-sm`).
     - **In-Place Updates:** Seamlessly converts header structures, adjusts styles, and applies widths/alignment without modifying existing cell contents.
  2. **In-Editor Interactive Table Tools:**
     - **Table Resizer Overlay:** Attached to editor wrapper outside `contentArea` with `z-index: 100`, preserving clean HTML serialization.
     - **Interactive Width Drag-Handles:** Dedicated East handle (`.jbd-table-handle-e`) and Southeast handle (`.jbd-table-handle-se`) allowing direct mouse-drag resizing of table width, complete with a live tooltip badge displaying `cols × rows • width px (%)`.
     - **Collision-Aware Floating Table Bubble Toolbar:**
       - Automatically flips below the table (`.bubble-at-bottom`) when space above is constrained by the sticky top toolbar.
       - Clamps horizontally within wrapper boundaries to prevent clipping on left/right edges.
       - **Row Actions:** ➕ Row Above (`row-above`), ➕ Row Below (`row-below`), 🗑️ Delete Row (`row-delete`).
       - **Column Actions:** ➕ Col Left (`col-left`), ➕ Col Right (`col-right`), 🗑️ Delete Col (`col-delete`).
       - **Quick Toggles:** Header row toggle (`header`), Striped alternating rows (`striped`), Cell borders (`bordered`), Caption insertion/focus (`caption`).
       - **Properties & Deletion:** ⚙️ Edit Table Properties modal (`properties`), 🗑️ Delete Table (`delete`).
  3. **Seamless Keyboard & Selection Experience:**
     - Clicking or focusing inside any cell activates the table overlay and contextual bubble toolbar.
     - Double-clicking opens the Table Properties dialog directly.
     - <kbd>Tab</kbd> and <kbd>Shift</kbd>+<kbd>Tab</kbd> navigate between cells; pressing <kbd>Tab</kbd> in the final cell automatically appends a new row below.
     - <kbd>Escape</kbd> or clicking outside deselects the table cleanly.
  4. **Clean Serialization:**
     - `getHTML()` guarantees all `.jbd-table-active` outline states are cleanly stripped upon export or save.
  5. **Verification & Tests:**
     - Added **Section 15: Table Interaction & Editing Suite** to `vendor/jbdeditor/test.html`.
     - Executed via headless Google Chrome: **100% of all 245 assertions passing cleanly across all 15 suites**.
  6. **Cache Busters Bumped:**
     - Updated `app/views/layout.cfm` cache busters: `jbdeditor.css?v=2.2`, `jbd-templates.css?v=1.7`, `jbdeditor.js?v=2.2`.

### Session: October 21, 2026 — JBDEditor: Advanced Image Suite (Positioning, Drag-Resizing, Floating Bubble Toolbar, Dialog Options, and WCAG Compliance)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`stylesheets/jbdeditor.css`, `stylesheets/jbd-templates.css`, `vendor/jbdeditor/css/editor.css`, `javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `javascripts/jbdeditor/jbdeditor.js`, `javascripts/jbdeditor/jaleditor.js`, `vendor/jbdeditor/src/dialog.js`, `vendor/jbdeditor/src/editor.js`, `vendor/jbdeditor/src/jbdeditor.js`, `vendor/jbdeditor/src/jaleditor.js`, `app/views/layout.cfm`, `app/views/articles/edit.cfm`, `vendor/jbdeditor/test.html`).
- **Key Deliverables:**
  1. **Comprehensive Image Insert & Edit Dialog ("The Whole Shebang"):**
     - Modern tabbed/segmented modal in `Dialog.openImageDialog()` supporting both new insertions and seamless in-place editing of existing images (`<figure class="jbd-image">` or standalone `<img>`).
     - **Media Source Options:** Image URL input, workspace Media Library browser integration (`window.openMediaPicker` with elevated `zIndex: 100005` to stack properly over `.jbd-dialog-overlay`), and direct local file upload (`FileReader` with instant Base64 preview).
     - **Live Dimension Detection & Ratio Badge:** Auto-detects natural width/height and displays an aspect ratio badge (e.g. `16:9`, `4:3`, `1:1`).
     - **WCAG 2.1 AA / ADA Title II Compliance:** Mandatory Alt Text validation with guidance counter (rec. < 150 chars), blocking generic placeholders (*"image"*, *"photo"*, *"graphic"*, or filename endings). Includes a WCAG Technique H67 "Mark as decorative image" toggle that sets `alt=""` and `role="presentation"`.
     - **Visual Captions & Photo Credits:** Optional `<figcaption>` with rich credit styling (`.jbd-image-credit`) rendered cleanly below the image.
     - **Alignment & Layout Controls:** Left Float (`.jbd-image-left`), Center Block (`.jbd-image-center`), Right Float (`.jbd-image-right`), Full Bleed (`.jbd-image-full`), and Inline Flow (`.jbd-image-inline`).
     - **Dimension Sizing Presets & Aspect-Ratio Lock:** Presets for 25%, 33%, 50%, 75%, 100%, and Natural; custom pixel width/height inputs with a toggleable aspect ratio lock icon.
     - **Styling Presets:** Corner radius (None, Rounded `6px`, Large `12px`, Circle/Pill `9999px`), frame/borders (Bordered, Framed card), and elevation shadows (Small, Medium, Large).
     - **Hyperlink Integration:** Wrap image in a hyperlink with optional "Open in new tab (`target='_blank'`)" and "Click-to-enlarge lightbox" triggers.
  2. **In-Editor Interactive Image Tools & Toolbar Visibility:**
     - **Main Toolbar Button Integration:** Added `'image'` to both `JBD_BASIC_TOOLBAR` and `JBD_SUBPAGE_TOOLBAR` across all modules. Standard pages and articles declaring `data-jbd-toolbar="basic"` (e.g. `articles/edit.cfm`, `pages/edit.cfm`, `pressreleases/edit.cfm`, `rfps/edit.cfm`) now prominently display the Insert Image tool button.
     - **Non-Invasive DOM Resizer Overlay:** Attached to editor wrapper outside `contentArea` with elevated `z-index: 100` (above sticky toolbar) to guarantee zero handle DOM pollution into serialized HTML.
     - **8 Interactive Drag Handles:** (NW, N, NE, E, SE, S, SW, W) enabling live proportional resizing with Shift-key lock and aspect-ratio preservation.
     - **Live Dimension Tooltip Badge:** Real-time floating badge displaying exact width, height, and width percentage (`W × H px (%)`) while dragging or selecting.
     - **Collision-Aware Floating Bubble Toolbar:** 
       - Evaluates vertical clearance against sticky header; automatically flips below image (`.bubble-at-bottom`) when positioned near the top of the editor content.
       - Clamps horizontally within editor bounds to prevent clipping when selecting floated or narrow images.
       - Elevated to `z-index: 105` with single-click actions:
         - Alignment presets (Left, Center, Right, Full Width) with active state indicators.
         - Sizing buttons (25%, 50%, 75%, 100%).
         - Quick caption toggle (inserts or focuses `<figcaption>`).
         - Quick link prompt / toggle.
         - "Edit Details" button (opens the full configuration dialog preloaded with current image properties).
         - Delete button (removes image from document).
  3. **Direct File Drag-and-Drop & Clipboard Paste:**
     - Dropping image files directly into the editor canvas automatically reads them via `FileReader` and launches the WCAG-enforced Image Dialog.
     - Pasting image files from OS clipboard automatically parses the file and opens the dialog for alt text assignment.
  4. **Keyboard Accessibility & Clean Serialization:**
     - `Backspace` or `Delete` removes active image; `Escape` deselects.
     - `getHTML()` systematically removes `jbd-image-active` selection classes before exporting or saving form data.
  5. **Automated Test Harness Verification:**
     - Added comprehensive Section 14 Image Suite tests to `vendor/jbdeditor/test.html` covering modal initialization, figure creation, alignment classes, sizing presets, captioning, decorative image handling, handle creation, and clean HTML export.
     - Executed via headless Google Chrome: 100% of all tests passing cleanly.
  6. **Cache Busters Bumped:**
     - Updated `app/views/layout.cfm` cache busters: `jbdeditor.css?v=2.0`, `jbd-templates.css?v=1.6`, `jbdeditor.js?v=2.0`.

### Session: October 20, 2026 — One Page Studio: Page Section Action Buttons & ACF Key Normalization
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/views/pages/onePage.cfm`, `tests/test_one_page_studio.cfm`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Adobe ColdFusion JSON Serialization Key-Case Resolution:**
     - Identified root cause of inactive buttons: Adobe ColdFusion `SerializeJSON` capitalized struct keys (`SECTIONS`, `SELECTEDSITE`, `ROUTES`, `ID`, `SECTIONTITLE`, `ANCHORID`, etc.), causing JavaScript lookups (`config.sections`, `s.id`, `routes.saveSection`, `selectedSite.id`) to evaluate to `undefined`.
     - Introduced defensive `getProp(obj, prop, def)` case-insensitive property accessor across the One Page Studio client application.
     - Normalized `selectedSite`, `sites`, `sections`, and `routes` with concrete fallback route paths so fetch requests never target `undefined`.
  2. **Page Section Action Buttons Overhaul (`onePage.cfm`):**
     - **Move Up & Move Down:** Implemented direct DOM element swapping (`insertBefore`) on `.ops-section-row` nodes for instantaneous visual feedback, paired with automated ID extraction and persistence to `/pages/one-page/sections/reorder`. Replaced raw HTML entities with accessible SVG chevrons (`chevron-up`, `chevron-down`) and explicit `aria-label` tags.
     - **Configure / Edit Section:** Enhanced `.btnOpsEditSection` to reliably find section records and provide a DOM dataset fallback so the configuration modal opens under any state.
     - **Remove / Delete Section & Site (`window.adminConfirm` Promise Resolution):** Identified and resolved the root cause of the non-functioning Delete buttons: `window.adminConfirm()` returns an ES6 Promise resolving to `true`/`false` rather than accepting a legacy callback function. Passing `(msg, cb)` caused `adminConfirm` to treat the callback as the options object, leaving `options.onConfirm` undefined and never executing the delete fetch. Re-engineered `confirmAction(msg, opts)` to properly await the Promise and execute the delete request upon user confirmation for both Section Deletion (`.btnOpsDeleteSection`) and Site Deletion (`#btnOpsDeleteSite` and Directory `.btnOpsDirectoryDeleteSite`). Also enhanced `deleteOnePageSite()` and `deleteOnePageSection()` in `Pages.cfc` to defensively accept both JSON body payloads and query/form parameters.
     - **Copy Anchor Tag:** Added cross-origin clipboard helper `copyText(anc)` with temporary `textarea` fallback for non-secure HTTP / iframe contexts, preventing unhandled `SecurityError` or `TypeError` crashes.
     - **Add Candidate Pages:** Resolved drawer submit button (`#btnSubmitOpsAddPages`) and open buttons (`#btnOpsOpenPagePicker`, `#btnOpsEmptyAddPages`) by guaranteeing valid `selectedSite.id`.
     - **Browse Hero Media:** Wired `#btnOpsBrowseHeroMedia` to the workspace Media Library picker.
  3. **Automated Regression Verification (`tests/test_one_page_studio.cfm`):**
     - Added **SUITE 6: Section Button Operations (Save, Reorder, Delete)** to the test runner.
     - Verified clean SQL operations respecting filtered indexes (`SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`).
     - **26 / 26 automated tests passing 100% cleanly**.

### Session: October 18, 2026 — Mandatory ADA Title II & WCAG 2.1 AA Requirements Enforcement for Images
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/controllers/Media.cfc`, `api/Files.cfc`, `app/views/media/upload.cfm`, `app/views/media/index.cfm`, `app/views/media/picker.cfm`, `javascripts/filexplorer/explorer.js`, `javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `vendor/jbdeditor/src/dialog.js`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Strict Server-Side WCAG 1.1.1 Validation (`Media.cfc:processUpload()`, `Media.cfc:updateMeta()`, `api/Files.cfc:updateMeta()`):**
     - Enforced mandatory Alternative Text (`alt_text`) for all image file uploads (`.jpg, .jpeg, .png, .gif, .webp, .svg, .bmp, .ico`).
     - Uploads missing alternative text (and not explicitly flagged as decorative) are rejected with a clear compliance error (`"ADA WCAG 2.1 AA Compliance Violation: Alternative Text (Image Description) is required for all images under County policy (WCAG 1.1.1)..."`), with temporary disk files deleted immediately.
     - Rejected generic single-word placeholder alt text (*"image"*, *"photo"*, *"picture"*, *"graphic"*, *"screenshot"*) and raw filenames (*"photo.jpg"*).
     - Guarded `updateMeta()` in both `Media.cfc` and `api/Files.cfc` so authors cannot wipe or blank out alternative text on existing images.
  2. **Dedicated Upload Studio Validation (`app/views/media/upload.cfm`):**
     - Updated Alternative Text field with a bold red `* Required for Images (WCAG 1.1.1)` badge, ADA Title II indicator, and character guidance (`0 / 150 rec.`).
     - Added an accessible "Mark as decorative image" toggle (WCAG Technique H67) that dims and exempts alt text for presentation-only elements.
     - Intercepted form submit: blocks submission, highlights input with red focus border, and presents accessible error prompt if image is uploaded without alt text.
  3. **Quick Dropzone & Media Explorer Integration (`media/index.cfm`, `media/picker.cfm`, `explorer.js`):**
     - Enhanced quick upload panel in both standalone Explorer and Picker iframe: dynamically detects image files and enforces required Alt Text (`el.uploadAlt.required = true`).
     - Client-side submit validation intercepts missing or generic alt text, highlights the input with red danger styling, focuses the field, and halts upload.
     - Added `data-act="edit-meta"` action in the Details inspector sidebar: renders an **"Enter WCAG Alt Text"** button (with red alert styling for non-compliant images) and a WCAG 1.1.1 missing banner.
     - Added **Edit Image WCAG & Metadata Modal** (`#mediaEditMetaModal`): allows authors to update alternative text, title, caption, photographer attribution, and tags directly from the file explorer with live persistence to `dbo.media_assets`.
  4. **Rich Text Editor Image Insertion (`jbdeditor.js`, `jbdeditor/dialog.js`, `vendor/jbdeditor/src/dialog.js`):**
     - Enforced mandatory Alt Text in the "Insert Image" dialog. Authors cannot insert inline `<img>` tags into story content without providing descriptive alt text.
     - Eliminated native browser `alert()` in favor of `window.adminAlert()` and `window.showToast()`.

### Session: October 18, 2026 — Database Schema Completeness Audit & `form_submission_values` Constraint Resolution
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** SQL Server Database `ChelanCountyWebsite`, DDL Scripts (`config/sql/schema-complete.sql`, `config/sql/schema-form-builder.sql`, `config/sql/schema-workspaces.sql`), Documentation (`.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Missing Table Identified & Resolved (`dbo.form_submission_values`):**
     - Discovered that `dbo.form_submission_values` was absent from SQL Server `ChelanCountyWebsite` because its initial DDL contained cascading foreign keys (`ON DELETE CASCADE`) to both `dbo.forms` (indirectly via `dbo.form_submissions` and `dbo.form_fields`), triggering SQL Server Error `Msg 1785` (cycles or multiple cascade paths).
     - Altered `FK_form_subval_field` to `ON DELETE NO ACTION` while retaining `ON DELETE CASCADE` on `FK_form_subval_submission`.
     - Executed the corrected DDL on `localhost` database `ChelanCountyWebsite`, creating `dbo.form_submission_values` and its composite nonclustered index `IX_form_submission_values_lookup` (`[submission_id], [field_id]`).
  2. **Comprehensive 34-Table Schema Inventory & Verification:**
     - Verified all 34 required CMS tables are 100% present with zero missing tables:
       - **Core & Admin (5):** `cms_roles`, `cms_users`, `cms_workspaces`, `cms_user_workspaces`, `cms_settings`.
       - **Pages & Revision History (5):** `pages`, `page_revisions`, `page_FolderExplorer`, `page_SubPage`, `page_call_to_actions`.
       - **Articles & Public Information (3):** `articles`, `article_categories`, `article_tags`.
       - **Online Forms & Submissions (6):** `forms`, `form_fields`, `form_submissions`, `form_submission_values`, `form_departments`, `form_audit_logs`.
       - **Media Assets (1):** `media_assets`.
       - **Calendar & Events (2):** `calendar_events`, `calendar_event_categories`.
       - **How Do I Service Directory (2):** `how_do_i_items`, `how_do_i_categories`.
       - **Recruitment & Jobs (2):** `job_listings`, `job_applications`.
       - **Emergency Alerts (1):** `emergency_alerts`.
       - **RFPs & Solicitations (4):** `rfp_solicitations`, `rfp_addenda`, `rfp_bids`, `rfp_planholders`.
       - **Navigation & Press (3):** `navigation_menus`, `navigation_menu_items`, `press_releases`.
  3. **Filtered Indexes & Foreign Key Auditing:**
     - Confirmed all 24 filtered nonclustered indexes (`WHERE deletedat IS NULL`) are intact and functional.
     - Confirmed 15 active foreign key constraints with zero orphaned child records.
     - Identified legacy/superseded tables (`job_postings` superseded by `job_listings`, `page_CtaCard` superseded by `page_call_to_actions`).
  4. **DDL Script & Repository Synchronization:**
     - Updated `config/sql/schema-form-builder.sql` and `config/sql/schema-complete.sql` to incorporate the `ON DELETE NO ACTION` resolution for `form_submission_values`.
     - Updated `config/sql/schema-workspaces.sql` and `config/sql/schema-complete.sql` with new workspace columns: `storage_path`, `domain_name`, `project_path`, `leadership_type`, `job_title`, and `contact_photo`.
     - Updated [`.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md) to document the complete table inventory and cascade path resolution.
### Session: October 18, 2026 — Workspace Management: Leadership Classification, Job Title & Profile Photo Selection
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/models/`, `app/controllers/Workspaces.cfc`, `app/global/functions.cfm`, `app/views/workspaces/index.cfm`, `app/views/workspaces/new.cfm`, `app/views/workspaces/edit.cfm`, `dbo.cms_workspaces`, `.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Database Schema Enhancements (`dbo.cms_workspaces`):**
     - Added `leadership_type NVARCHAR(20) NULL DEFAULT 'dept_head'`, `job_title NVARCHAR(150) NULL`, and `contact_photo NVARCHAR(500) NULL` to table `dbo.cms_workspaces`.
     - Preserved filtered nonclustered index safety (`WHERE deletedat IS NULL`) by prefixing all queries with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`.
     - Seeded benchmark record for `assessor`: `leadership_type = 'elected'`, `job_title = 'County Assessor'`, and `contact_photo = '/files/assessor/images/aswang.jpg'`.
  2. **Controller & Helper Function Integration (`Workspaces.cfc`, `functions.cfm`):**
     - Updated `functions.cfm:getMasterWorkspaces()` to query `job_title` and `contact_photo`, mapping them into workspace struct properties `job_title`, `contact_photo`, `contact.job_title`, and `contact.photo`.
     - Updated `Workspaces.cfc`:
       - `new()`: initialized default empty values for `leadership_type`, `job_title`, and `contact_photo`.
       - `create()`: extracted `local.jobTitle` and `local.contactPhoto`, persisted them into `INSERT INTO cms_workspaces` with `cf_sql_varchar` parameter typing.
       - `edit()`: queried and passed `job_title` and `contact_photo` into the edit form state.
       - `update()`: extracted form inputs and persisted `job_title = :job_title, contact_photo = :contact_photo` in `UPDATE cms_workspaces`.
       - `index()`: added `job_title` to the global text search filter haystack.
  3. **Workspace Create & Edit Forms (`workspaces/new.cfm`, `workspaces/edit.cfm`):**
     - **Consolidated Column 2 ("Contact, Physical Location & Hours"):** Seamlessly merged Physical Location, Address, and Operating Hours with Leadership & Contact Information into a single logical configuration section.
     - **Leadership Classification Radio Cards:** Added interactive toggle for "Elected Official" vs "Department Head" with status badges, SVG icons, and descriptions.
     - **Profile Photo Selector & 200 &times; 200 Avatar Preview:** Added a dedicated 200&times;200px circular avatar card with subtle shadow, hover scale effect, `[Browse Media Library]` button opening the modal media picker (`/media/picker?picker=image`), direct URL text input with live preview, and a remove photo button.
     - **Job Title Field:** Added an explicit input field for Job Title (e.g., "County Assessor", "Director of Community Development") directly between the photo preview and First/Last Name inputs.
     - **Embedded Media Picker Modal (`#mediaPickerModal`):** Added modal dialog markup wrapped in `<cfoutput>` (rendering the `#svgIcon()` headers properly as inline SVGs) and JavaScript handlers (`openMediaPickerForContactPhoto`, `onMediaSelectedFromPicker`, `updateContactPhotoPreview`, `removeContactPhoto`) allowing instant photo selection from workspace media archives.
  4. **Workspace Directory & Drawer UI (`workspaces/index.cfm`):**
     - **Table Directory:** Updated the Contact column to render a 34x34px circular avatar photo next to the contact name, job title, and leadership badge ("Elected Official" / "Department Head").
     - **Expandable Details Drawer:** Updated Card 2 to display the avatar image with contact name, job title, leadership badge, and a clickable photo link.

### Session: October 18, 2026 — Media Library: Upload UI Modernization (Studio Cover Image Dropzone & Image URL Browse Row)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Media Module (`stylesheets/filexplorer/explorer.css`, `javascripts/filexplorer/explorer.js`, `app/views/media/index.cfm`, `app/views/media/picker.cfm`, `app/views/media/upload.cfm`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Unified Design Language Across All Upload Interfaces:**
     - Redesigned the file upload experience across the Main Media Library (`media/index.cfm`), Media Picker Modal (`media/picker.cfm`), and the Full Upload Studio (`media/upload.cfm`) to match the user's provided design specification (featured cover image pattern).
  2. **Hero Dropzone Card:**
     - Styled `.media-upload-dropzone` with rounded container (`border-radius: 12px`), blue dashed border (`border: 2px dashed #0284c7`), centered SVG image icon (frame with sun and mountain peak), bold heading `"Choose Cover Image / File"`, and descriptive subtitle `"Click to browse workspace media library or drag and drop here"`.
     - Supports full drag-and-drop file ingestion and direct click via transparent full-cover native file input overlay (`.media-file-native-input`).
     - Selected file state displays an interactive badge card (`.media-selected-card`) with thumbnail preview for images (via `FileReader` API), file size, file name, and an accessible `"Change"` button.
  3. **Image URL & File Browse Control Row:**
     - Positioned directly below the dropzone box with label `"Image URL"`.
     - Input field displays the prospective or selected server destination path (e.g. `/files/pio/images/photo.jpg`), dynamically updating whenever the selected workspace, folder, or file changes.
     - Neutral `[📁 Browse]` button triggers the native file selection dialog.
     - Primary `[Upload Now]` action button (with animated loading spinner state) and `[Cancel]` button for intuitive dismissal.
  4. **Bugfix & Template Compliance:**
     - Escaped SVG icon `stroke="##0284c7"` across `<cfoutput>` blocks in `index.cfm` and `picker.cfm` to eliminate `[coldfusion.util.RuntimeWrapper] 0284c7 is not a valid identifier name` runtime error.
     - Verified all three views (`/media/index`, `/media/upload`, `/media/picker`) return HTTP 200 with clean compilation under active authenticated session.

### Session: October 18–19, 2026 — Page Editor V2 Layout Overhaul, LED Status Markers, and Comprehensive Modal Restoration
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/views/pages/edit.cfm`, `app/views/pages/editV2.cfm`, `app/views/pages/_pageEditorModals.cfm`, `app/views/pages/_pageEditorScripts.cfm`, `javascripts/filexplorer/explorer.js`, `app/controllers/Pages.cfc`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Page Editor V2 Dual-Panel & Accordion Architecture:**
     - Restructured the Page Editor interface into a balanced dual-column layout:
       - **Left Panel:** Page Title, Page Slug/URL with clipboard copy button, Page Layout selector, Full WYSIWYG Editor (`pgContent`), dedicated ADA Pre-Flight Linter toolbar & expandable diagnostic drawer directly above editor content, and integrated Search & Social Sharing metadata generator card.
       - **Right Panel:** Page Features Deck containing 5 core features with real-time pulsing LED status markers (`.led-marker.is-active`, `.led-marker.is-inactive`) and active count badge (`X / 5 Active`):
         - *Cover Image* (`#ledCoverImage`): Featured header cover image, alt text, caption, credit, and decorative toggle.
         - *Navigation & Placement* (`#ledNavigation`): Menu item assignment, top-level toggle, and breadcrumbs.
         - *Sidebar & Subpages* (`#ledSidebar`): Subpage listing manager, order positions, and sidebar chooser.
         - *Folder Explorer* (`#ledFolder`): File repository items, server paths, and layout grid settings.
         - *Publish Status & Scheduling* (`#ledPublish`): Immediate publish, scheduled release, archive dates, and direct launch button to Revisions Studio.
     - **Removed Duplicate ADA Accordion Item:** Removed redundant `#accItemA11y` from the Right Panel features deck, keeping the ADA Pre-Flight Linter toolbar positioned above the content editor where real-time text analysis is performed.
  2. **Comprehensive Modal Dialog Restoration & Layout Fixes:**
     - **Resolved Script Halting Exception:** Corrected missing element ID lookup (`pgFolderItemRelative` vs `pgFolderItemRelativePath`) that previously threw an unhandled `TypeError` during script evaluation, preventing modal opener functions from defining.
     - **Universal Modal Cancel & Close Button Handlers:** Fixed broken Cancel buttons across all modals:
       - Subpage Modal (`#pgCancelSubpage`, `#pgCloseSubpageModal`): Assigned explicit IDs and `querySelectorAll('[data-close-subpage-modal]')` event bindings; exported `window.closeSubpageModal` globally.
       - Folder Item Modal (`#pgCancelFolderItem`, `#pgCloseFolderModal`): Assigned explicit IDs, `querySelectorAll('[data-close-folder-modal]')` bindings; exported `window.closeFolderItemModal` globally.
       - Media Picker (`#mediaPickerModal`), Revisions Studio (`#pgRevisionsModal`), Embed Form (`#embedFormModal`), Embed CTA (`#embedCtaModal`), and Document Converter (`#pgDocConvertModal`): Verified or added explicit Cancel buttons with instant closing and body scroll restoration.
     - **Restored Iconized Layout Selection Cards:** Replaced plain `<select>` in `#pgFolderItemModal` with the original interactive `.fe-layout-card` wireframe cards for **"Full Width"** and **"3/9 Grid Layout"**, complete with active radio dots, CSS focus states, and arrow-key accessibility.
     - **Revisions Studio Modal (`#pgRevisionsModal`):** Added fixed centered positioning (`position: fixed; inset: 0; z-index: 99999`), 96vw/88vh viewport containment, and dark blurred backdrop (`rgba(15,23,42,0.72)`) appended directly to `document.body` to eliminate document flow breakages.
     - **Subpage Modal & Folder Item Modal:** Added null guards on title/save/delete buttons in `openSubpageModal()`, `openEditSubpageModal()`, and `closeSubpageModal()`, ensuring clean opening and body scroll lock/unlock without errors.
     - **Embed Form, Embed CTA, & Document Converter Modals:** Verified all modal openers (`openEmbedFormModal`, `openEmbedCtaModal`, `openDocConvertModal`) append to `document.body` and display cleanly with ESC key dismissals.
  3. **Media Picker Single-Click Card Selection:**
     - Updated `javascripts/filexplorer/explorer.js` in `pickerMode` to render a direct **"Select Image" / "Select File"** button on every media card in grid and list views. Single-clicking the button immediately emits the payload to the parent window, updates the cover image preview and metadata, activates the `#ledCoverImage` LED status marker, and closes the modal seamlessly.
  4. **Verification & Synchronization:**
     - Verified identical synchronization between `app/views/pages/edit.cfm` and `app/views/pages/editV2.cfm`.
     - Validated all modal Cancel triggers and iconized card selections in headless Chrome tests.

### Session: October 18, 2026 — Pure Adobe ColdFusion Document to WCAG 2.1 AA HTML Converter Studio (.docx & .pdf) & Articles Module Integration
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/models/DocumentConverter.cfc`, `app/controllers/Pages.cfc`, `app/controllers/Articles.cfc`, `app/views/pages/edit.cfm`, `app/views/articles/edit.cfm`, `config/routes.cfm`, `.doclib/000_SERIES_INDEX.md`, `.doclib/012_DOCUMENT_CONVERTER_WCAG_AA.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Pure Semantic HTML Tags Without Classes or Inline Styles:**
     - Enforced strictly tag-pure standard HTML output (`<h2>`, `<h3>`, `<p>`, `<blockquote>`, `<ul>`, `<ol>`, `<li>`, `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th scope="col">`, `<td>`, `<strong>`, `<em>`, `<u>`, `<s>`, `<sup>`, `<sub>`, `<mark>`, `<a>`, `<img>`, `<hr>`, `<br>`) without CSS classes or inline styles, so converted documents visually mirror the input while inheriting the native site/editor theme.
  2. **Intelligent PDF Semantic Extraction Engine (`app/models/DocumentConverter.cfc`):**
     - Resolved raw text flattening where single-page PDF dumps previously resulted in monolithic blocks or broken line-by-line fragments.
     - **Typography & Kerning Normalization:** Automatically strips stray spaces before punctuation (`word , word .` &rarr; `word, word.`), corrects parenthesis spacing, normalizes em dashes, hyphenated words (`sign - in` &rarr; `sign-in`), and cleans running headers/footers (`Page X of Y`).
     - **Sentence Stitching & Paragraph Reflow:** Dynamically buffers and reflows continuous sentences across visual page breaks, generating well-proportioned, accessible `<p>` tags (2–3 sentences, ~250–450 characters) instead of fragmented lines.
     - **Table Matrix Heuristic:** Detects tabular blocks, permission matrices, and multi-column rows from PDF text, reconstructing clean HTML `<table><thead><tr><th scope="col">...</th></tr></thead><tbody><tr><td>...</td></tr></tbody></table>` structures.
     - **Numbered & Bullet List Reconstruction:** Detects sequential step patterns (`1. ... 2. ... 3. ...`) and bullet markers, converting them into structured `<ol><li>` and `<ul><li>` elements.
     - **Heading Hierarchy:** Downshifts primary headings to `<h2>` and subheadings to `<h3>`, preserving `<h1>` for page/article titles.
  3. **Articles & Public Information Module Integration (`Articles.cfc`, `articles/edit.cfm`, `config/routes.cfm`):**
     - Added `convertDocument()` action to `app/controllers/Articles.cfc`, exempt from CSRF in `protectsFromForgery()`.
     - Registered `/articles/convert-document` route in `config/routes.cfm`.
     - Added **"Import Word / PDF"** toolbar button (`#btnArticleImportDoc`) to the Story Content header in `app/views/articles/edit.cfm`.
     - Wrapped `#articleContent` with interactive drag-and-drop overlay (`#articleEditorDropContainer`, `#articleDocDropOverlay`) that triggers on `.docx` or `.pdf` file drags.
     - Added Document to WCAG AA Converter Studio Modal (`#articleDocConvertModal`) supporting dual Visual vs Code preview, metadata auto-population for Headline and Story Excerpt, and immediate triggering of `window.ArticleA11yLinter.scan()` on paste.
  4. **Documentation Series Update (`.doclib/000_SERIES_INDEX.md`, `.doclib/012_DOCUMENT_CONVERTER_WCAG_AA.md`):**
     - Updated Series 012 manual to document PDF typography normalization, table heuristic reconstruction, and multi-module editor integration.

### Session: October 17, 2026 — Seeding & Self-Healing Prefill for Standard Chelan County "How Do I" Categories
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/controllers/Pages.cfc`, `app/views/pages/howDoI.cfm`, `config/sql/schema-how-do-i.sql`, `TODO.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Database Seeding (`dbo.how_do_i_categories`):**
     - Executed the `MERGE` statement from `config/sql/schema-how-do-i.sql` on database `ChelanCountyWebsite`, establishing the 12 standard action categories:
       - **Apply For** (`apply-for`, icon: `clipboard-list`, sort: 10)
       - **Contact** (`contact`, icon: `phone`, sort: 20)
       - **Find** (`find`, icon: `search`, sort: 30)
       - **File A** (`file-a`, icon: `file-text`, sort: 40)
       - **Join** (`join`, icon: `users`, sort: 50)
       - **Pay For** (`pay-for`, icon: `hard-drive`, sort: 60)
       - **Learn About** (`learn-about`, icon: `book`, sort: 70)
       - **Register To** (`register-to`, icon: `check-square`, sort: 80)
       - **Report** (`report`, icon: `megaphone`, sort: 90)
       - **Request** (`request`, icon: `mail`, sort: 100)
       - **Search For** (`search-for`, icon: `globe`, sort: 110)
       - **View** (`view`, icon: `eye`, sort: 120)
  2. **Controller Self-Healing & API (`Pages.cfc`):**
     - Updated `ensureHowDoITables()` with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` to auto-merge the 12 standard categories on startup or table check.
     - Implemented `prefillHowDoICategories()` endpoint (exempted from CSRF in `config()`) allowing administrators to restore or update the standard categories with idempotent merging.
  3. **User Interface Integration (`app/views/pages/howDoI.cfm`):**
     - Added an empty state callout card in `#hdiCategoriesContainer` when categories count is 0, featuring a 1-click **"Prefill 12 Standard Categories"** action.
     - Added a **"Prefill / Reset Standard Categories"** action button in the Manage Categories modal (`#hdiCategoriesModal`) footer.
     - Wired up async AJAX handlers with `showDialogConfirm()` and `showDialogAlert()`, providing seamless category reloading without losing state.

### Session: October 17, 2026 — Universal Media Upload Action Integration Across CMSAdmin 2.0
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/controllers/Media.cfc`, `app/views/media/index.cfm`, `app/views/media/picker.cfm`, `app/views/layout.cfm`, `app/views/main/index.cfm`, `app/views/settings/media.cfm`, `app/views/pages/edit.cfm`, `app/views/articles/edit.cfm`, `app/views/pages/callToAction.cfm`, `app/views/rfps/edit.cfm`, `javascripts/filexplorer/explorer.js`, `stylesheets/filexplorer/explorer.css`, `TODO.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`).
- **Key Deliverables:**
  1. **Flexible Path Parsing in `Media.cfc:processUpload()`:**
     - Enabled inline quick uploads to accept relative directory paths (e.g. `assessor/images`) to automatically parse the target workspace and folder when uploaded from inline file explorer components.
  2. **Standalone Media Explorer (`/media/index`):**
     - Added an "Upload Media" button in the `.content-header` and an "Upload" button (`#btn-upload`) in the file explorer toolbar (`.pathbar-tools`).
     - Added an inline slide-down upload panel (`#upload-panel`) with file selection, auto-generated display title, WCAG 1.1.1 alt text input, dynamic destination preview, and a link to the full upload studio.
  3. **Media Picker Modal (`/media/picker`):**
     - Integrated `#btn-upload` and the inline `#upload-panel` directly within the picker modal toolbar, allowing editors to upload new media assets without leaving the picker or losing modal selection state.
  4. **Explorer Details Panel (`explorer.js`):**
     - When inspecting any non-read-only folder, added an "Upload file here" action button that opens the upload panel or navigates into the subfolder with `pendingUpload` enabled.
  5. **Global Navigation & Dashboard Entry Points:**
     - Left sidebar (`app/views/layout.cfm`): Upgraded "Media Library" nav item to a submenu with "Browse Explorer" (`/media/index`) and "+ Upload Files" (`/media/upload`).
     - Dashboard (`app/views/main/index.cfm`): Added "Upload Media" action button in the Media card footer alongside "Browse Media Library".
     - Administrative Settings (`app/views/settings/media.cfm`): Added "Upload Media" action button in the Media Library Manager card.
  6. **Universal Picker Modal Headers:**
     - Added an "Upload New File" button with inline SVG icon in all modal headers embedding the Media Picker iframe (`app/views/pages/edit.cfm`, `app/views/articles/edit.cfm`, `app/views/pages/callToAction.cfm`, `app/views/rfps/edit.cfm`).
     - Implemented `window.triggerMediaPickerUpload()` helper in all 4 views that triggers the inline upload panel within the iframe or opens the upload studio in a new tab as fallback.

### Session: October 17, 2026 — Media Library Database Metadata Persistence (`dbo.media_assets`), Deduplication & ADA WCAG Telemetry (TODO 1.3)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`config/sql/schema-media-assets.sql`, `app/models/MediaAsset.cfc`, `app/controllers/Media.cfc`, `app/views/media/upload.cfm`, `api/Files.cfc`, `javascripts/filexplorer/explorer.js`, `TODO.md`).
- **Key Deliverables:**
  1. **SQL Server Database Table & Filtered Indexes (`dbo.media_assets`):**
     - Authored and executed `config/sql/schema-media-assets.sql` on database `ChelanCountyWebsite`.
     - Fields include `site_id`, `folder`, `filename`, `file_path`, `web_url`, `file_size`, `file_ext`, `file_hash` (SHA-256), `title`, `alt_text`, `caption`, `credit`, `is_image`, `width`, `height`, `is_wcag_compliant`, `tags`, `created_at`, `created_by`, `updated_at`, `updated_by`, and soft-delete `deletedat`.
     - Created 3 filtered nonclustered indexes (`IX_media_assets_site_folder_file`, `IX_media_assets_file_hash`, `IX_media_assets_wcag`) with `WHERE deletedat IS NULL`.
  2. **Model & Controller (`MediaAsset.cfc`, `Media.cfc`):**
     - Created `app/models/MediaAsset.cfc` extending Wheels `Model` with standard timestamps and table mapping.
     - Updated `Media.cfc` `upload()` to provide workspace options, folder selection (`images`, `documents`, `media`), top recent uploads query from `dbo.media_assets`, and aggregated media stats (total assets, images, documents, WCAG compliant, needing alt text).
     - Enhanced `processUpload()` to compute cryptographic SHA-256 hashes (`Hash(fileBytes, "SHA-256")`), check cross-workspace duplicates against `dbo.media_assets`, extract image dimensions via `ImageRead()`, validate WCAG 1.1.1 compliance, reject executables (`.cfm, .cfc, .exe, .bat, etc.`), and insert into `dbo.media_assets`.
     - Implemented `updateMeta()` to allow editing title, alt text, caption, photographer credit, and tags with automatic `is_wcag_compliant` flag recalculation.
     - Added `syncDiskAssetsToDatabase()` to auto-catalog untracked disk files into `dbo.media_assets`.
  3. **Modernized Upload Studio View (`app/views/media/upload.cfm`):**
     - Added KPI statistics row (Total Assets, Images, Documents, and ADA WCAG AA Compliance %).
     - Implemented accessible workspace selector and subfolder dropdown (`images/` recommended for photos, `documents/` for PDFs, `media/` legacy).
     - Added real-time destination path preview updating dynamically as destination workspace/subfolder changes.
     - Integrated ADA WCAG 2.1/2.2 AA card with guidance for WCAG 1.1.1, alt text, display title (auto-populated on file selection), caption, photographer/source credit, and search tags.
     - Created "Recent Database Tracked Uploads" table displaying thumbnail/file preview, title/filename, folder location, dimensions, file size, SHA-256 hash pill, ADA WCAG status badge, and timestamp.
  4. **API & File Explorer Integration (`api/Files.cfc`, `explorer.js`):**
     - Updated `api/Files.cfc` `list()` to enrich scanned files with stored metadata (`id, title, altText, caption, credit, hash, isWcagCompliant, tags, width, height`) and added remote `updateMeta()` method.
     - Updated `explorer.js` `normaliseItem` to preserve all rich metadata attributes.
     - Enhanced `explorer.js` `renderDetails()` to display ADA accessibility status badges (WCAG AA Compliant vs Needs Alt Text), full alt text, image dimensions, caption, credit, tags, and SHA-256 hash.
     - Enhanced `selectForPicker(it)` and postMessage events (`CMS_MEDIA_SELECTED`, `cmsMediaSelected`) so authoritative alt text and full metadata flow cleanly into the picker callback, page editor, and CTA dialogs.
     - Expanded `applyFilter()` in file explorer to search across file names, titles, alt text, and tags.

---

### Session: October 17, 2026 — Workspace Primary Color Theming, CTA Grid Embed Modal Fixes & `.jbd-cta-link` SVG Icon Rendering
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** CMSAdmin 2.0 (`app/views/pages/edit.cfm`, `app/views/layout.cfm`, `app/controllers/Pages.cfc`, `app/global/functions.cfm`, `javascripts/admin.js`, `javascripts/jbdeditor.js`, `stylesheets/jbdeditor.css`, `stylesheets/jbd-templates.css`, `config/sql/schema-pages.sql`, `config/sql/schema-complete.sql`) & ChelanCounty.gov (`app/views/layout.cfm`, `app/views/helpers.cfm`, `app/views/assessor/page.cfm`, `app/views/shared/_dept-nav.cfm`, `stylesheets/styles.css`, `stylesheets/jbd-templates.css`, `README.md`).
- **Key Deliverables:**
  1. **Workspace Guard & UI Refinements (`CMSAdmin2.0/app/views/layout.cfm`, `javascripts/admin.js`):**
     - Restricted **How Do I**, **Events / Calendar**, and **Emergency Alerts** in the left navigation to require an active workspace selection (`data-requires-workspace="true"`).
     - Removed redundant header workspace pill and dynamically synced the selected workspace color directly to `--admin-primary`, `--admin-primary-hover`, `--admin-primary-light`, and `--ws-accent-color`.
  2. **Public Frontend Workspace Primary Color & 404 Not Found Card (`ChelanCounty.gov/app/views/layout.cfm`, `app/views/assessor/page.cfm`, `stylesheets/styles.css`):**
     - Mapped active department workspace color (`currentWorkspace.color`) to `--bs-primary`, `--bs-primary-rgb`, `--brand-900`, `--brand-800`, `--link-700`, `--dept-color`, and `--dept-theme-color`.
     - Styled the 404 "Page Not Found" card (`app/views/assessor/page.cfm`) with workspace-themed gradient accents, icon badge, and action buttons.
  3. **CTA Embed Modal & Shortcode Resolver (`CMSAdmin2.0/app/views/pages/edit.cfm`, `ChelanCounty.gov/app/views/helpers.cfm`):**
     - Removed individual card action footer buttons inside `#embedCtaModal` and made clicking anywhere on a card toggle its multi-select checkbox.
     - Replaced early `getElementById` bindings with delegated `document` click/input listeners so **Embed Selected Cards as Grid**, **Insert Grid Shortcode**, **Select All**, **Clear All**, and live search work reliably.
     - Updated `insertSnippetAtCursor()` to use `editor.insertTemplate()` for block HTML (`<section>`, `<aside>`, `<div>`) and integrated `[cta_grid]` / `[call_to_action]` / `[cta]` shortcode resolution into `renderCmsContent()` on `ChelanCounty.gov`.
  4. **`.jbd-cta-link` Inline SVG Icon Rendering & Unicode Persistence:**
     - Updated `generateCtaCardHtml()` and `#embedCtaModal` previews in `edit.cfm` and CTA grid templates in `jbdeditor.js` to emit inline `<svg>` arrow and external-link icons instead of `&rarr;` / `&nearr;` HTML entities.
     - Changed `Pages.cfc` `save()` and `recordPageRevision()` bindings from `cf_sql_longvarchar` to `cf_sql_nvarchar` to prevent SQL Server single-byte VARCHAR conversion of Unicode characters into `?`.
     - Added `normalizeCtaLinkIcons()` in both `CMSAdmin2.0/app/global/functions.cfm` and `ChelanCounty.gov/app/views/helpers.cfm` to automatically repair any existing `.jbd-cta-link` anchors with trailing `?`, `&rarr;`, or `&nearr;` into inline `<svg>` icons.
     - Added explicit `.jbd-cta-link svg` sizing, alignment, `stroke: currentColor`, and hover transitions across `styles.css`, `jbd-templates.css`, and `jbdeditor.css`.

---

### Session: October 17, 2026 — Call to Action Studio, Photo-Card Grid Templates & JBDEditor Shortcode Integration
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Pages Module (`app/controllers/Pages.cfc`, `app/views/pages/callToAction.cfm`, `app/views/pages/edit.cfm`, `app/views/pages/index.cfm`), Routing (`config/routes.cfm`), Navigation & UI (`app/views/layout.cfm`, `app/views/helpers.cfm`), Global Functions (`app/global/functions.cfm`), Rich Text Editor (`javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `vendor/jbdeditor/src/dialog.js`), Stylesheets (`stylesheets/jbd-templates.css`), Image Assets (`images/cta/*`), Database Schema (`page_call_to_actions`).
- **Key Deliverables:**
  1. **Call to Action Studio (`app/views/pages/callToAction.cfm`):**
     - Authored a full-featured management interface under "Pages" (`/pages/call-to-action`).
     - Includes KPI statistics bar (Total CTAs, Published, With Images, Workspaces).
     - Live search filter and interactive category filter pills ("All", "General", "Assessor Services", "Online Portals", "Public Records", "Citizen Services").
     - 3-column responsive visual card grid reproducing the Chelan County Assessor service card design from the reference screenshot.
     - Quick-copy shortcode chips for 1-click clipboard copying (`[call_to_action slug="..."]`, `[cta_grid slugs="..."]`).
     - Accessible Add / Edit Call to Action modal with real-time visual preview card that live-updates image, badge, text, link, and layout type as the user types.
     - Multi-Card Grid Builder modal enabling editors to select multiple cards via checkboxes and insert or copy composite 3-column responsive shortcode grids.
     - Reordering via drag-and-drop / sort order sequence with automatic API persistence.
  2. **Database Schema & Filtered Indexing (`page_call_to_actions`):**
     - Implemented `ensureCallToActionTable()` with soft delete support (`deletedat`).
     - Nonclustered filtered index `IX_page_call_to_actions_site_slug` on `([siteid], [slug]) WHERE [deletedat] IS NULL` executed with mandatory `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`.
     - Seeded all 6 Chelan County Assessor reference services:
       1. *Parcel & Sale Search* (`/images/cta/parcel-search.jpg`) &rarr; `Search Parcels`
       2. *Interactive GIS Map* (`/images/cta/gis-map.jpg`) &rarr; `Open Map ↗`
       3. *Property Owner's Guide* (`/images/cta/property-guide.jpg`) &rarr; `Download PDF [PDF]`
       4. *Destroyed Property* (`/images/cta/destroyed-property.jpg`) &rarr; `View Relief Forms`
       5. *Assessment Appeals* (`/images/cta/assessment-appeals.jpg`) &rarr; `Appeal Instructions`
       6. *Document Search* (`/images/cta/document-search.jpg`) &rarr; `Search Records ↗`
  3. **Shortcode & Front-End Card Rendering Engine (`app/global/functions.cfm`):**
     - Implemented `renderCallToActionCardHtml(item)`: renders semantic `<aside class="jbd-template jbd-cta-card has-image">`, responsive image with lazy-loading, badge, title, description, and action link with local SVG arrow, external icon `↗`, or `[PDF]` badge.
     - Implemented `renderCallToActionShortcodes(content)`: parses and resolves `[call_to_action slug="..."]`, `[cta slug="..."]`, `[cta_grid slugs="s1,s2,s3"]`, and `[cta_grid category="..."]` into clean `<section class="jbd-template jbd-cta-grid cta-grid-3">` containers.
  4. **JBDEditor Embed Integration (`app/views/pages/edit.cfm`, `vendor/jbdeditor/`):**
     - Added "Embed Call to Action" toolbar button (`btnEditorInsertCTA`) next to "Embed Form" in the page editor.
     - Created interactive modal dialog allowing page authors to choose any saved CTA card or generate multi-card grids with 1-click insertion into the JBDEditor content area.
     - Added `cta-photo-card` and `cta-reference-grid` block templates to `DEFAULT_BLOCK_TEMPLATES` in `dialog.js` and `jbdeditor.js`.
  5. **Navigation & UI Invariants Compliance:**
     - Added "Call to Action Manager" under "Pages" in the primary sidebar navigation (`app/views/layout.cfm`).
     - Added "Call to Action" quick-launch action button in the Pages index header (`app/views/pages/index.cfm`).
     - Non-negotiable Invariant #1: Zero external CDNs — all SVG icons, cropped JPG images, and styles are local.
     - Non-negotiable Invariant #2: Zero native browser dialogs — all confirmations and notices utilize `window.adminConfirm()`, `window.showToast()`, and accessible accessible dialog modals.
     - Non-negotiable Invariant #3: All SQL queries on `page_call_to_actions` explicitly execute `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`.
  6. **Bugfixes & Template Compilation:**
     - Escaped unescaped JS fallback URL string `"#"` to `"##"` on line 766 in `app/views/pages/callToAction.cfm` to eliminate `[coldfusion.util.RuntimeWrapper] Invalid CFML construct found on line 767 at column 57`.
     - Restored missing `<ul class="nav-submenu">` wrapper under the Pages nav item in `app/views/layout.cfm` ensuring submenu items ("All Pages", "Call to Action Manager", "How Do I") render with proper indentation, hover states, and accordion animation.
     - Removed redundant "Workspace / Department" dropdown from the Add/Edit CTA modal in `app/views/pages/callToAction.cfm`, replacing it with automatic active workspace inheritance via hidden input adhering to the County Header Workspace Switcher pattern.
     - Implemented full interactive Media Library File Explorer Picker modal (`mediaPickerModal`) in `app/views/pages/callToAction.cfm`, wiring `openMediaPicker("image", ...)` directly to the "Browse Media Library" button (`btnBrowseCtaImage`) with automatic URL/alt population and real-time live preview synchronization.
- **Verification:** Verified `page_call_to_actions` SQL Server schema and filtered index using `sqlcmd`, confirmed all 6 seed rows populated, verified `renderCallToActionShortcodes` output via live CF execution, tested route routing returning HTTP 302/200, and confirmed zero ColdFusion syntax/compilation errors.

---

### Session: October 17, 2026 — Call to Action (CTA / CTR) Cards & High-Conversion Civic Block Templates
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Stylesheets (`stylesheets/jbd-templates.css`), Rich Text Editor (`javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `vendor/jbdeditor/src/dialog.js`), Pages Studio (`app/views/pages/edit.cfm`), Documentation & Demo (`app/views/documentation/editor.cfm`, `app/views/layout.cfm`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`)
- **Key Deliverables:**
  1. **Standalone Portable CSS Suite (`stylesheets/jbd-templates.css`):**
     - Authored Section 12 for Call to Action Cards, Grids, and Banners.
     - Implemented `.jbd-cta-card` with high-contrast accent borders (`border-top: 4px solid #0b2545`), rounded container, smooth hover elevation (`box-shadow: 0 6px 16px rgba(0,0,0,0.08)`), and color-coded badges (`.jbd-cta-badge`, `.jbd-cta-badge-teal`, `.jbd-cta-badge-blue`, `.jbd-cta-badge-amber`).
     - Styled `.jbd-cta-btn` with minimum 44x44px touch targets (WCAG 2.5.5 / 2.5.8), dynamic arrow transitions, and 3:1 focus-visible outlines (`outline: 3px solid #2563eb; outline-offset: 3px`).
     - Implemented `.jbd-cta-grid` utilizing an accessible responsive CSS Grid (`repeat(auto-fit, minmax(280px, 1fr))`) that automatically reflows into single-column layouts on mobile devices.
     - Implemented full-width `.jbd-cta-banner` with Chelan navy gradient (`#0b2545` to `#134074`), white contrast action button, and high-visibility typography.
     - Added Windows High Contrast / Forced Colors Mode rules (`@media (forced-colors: active)`) with `ButtonText` and `Highlight` outlines.
  2. **Rich Text Editor Templates Suite (`javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `vendor/jbdeditor/src/dialog.js`):**
     - Added 3 new block templates under the `'Call to Action'` category:
       - `cta-card`: Single Call to Action (CTA) Card for focused citizen applications.
       - `cta-grid`: Call to Action Grid (2-Column) for paired service offerings (e.g. "Pay Taxes Online" vs. "Public Records Request").
       - `cta-banner`: High-Impact Action Banner for end-of-page application steps or office assistance advisories.
     - Dynamically generates the `'Call to Action'` filter pill in the editor's Browse Templates dialog modal.
     - Built with semantic landmark elements (`<aside>`, `<section>`), `<p class="jbd-cta-title h4">` non-heading typography to prevent disrupting page heading levels in ADA audits, and fully accessible descriptive `aria-label`s on action buttons.
  3. **Page & Subpage Studio Integration (`app/views/pages/edit.cfm`):**
     - Added `cta-card`, `cta-grid`, and `cta-banner` options to the `#pgSubpageTemplateSelect` dropdown menu.
     - Registered template markup in `SUBPAGE_TEMPLATE_MAP` for 1-click insertion into subpage bodies.
  4. **Documentation & Live Interactive Demo (`app/views/documentation/editor.cfm`):**
     - Embedded a live interactive CTA Card directly into the demo textarea.
     - Authored Section `#cta-templates` with explanations of conversion architecture, 44px touch target compliance, heading hierarchy preservation, and TOC navigation link.
  5. **Cache-Busting Asset Versioning (`app/views/layout.cfm`):**
     - Bumped `jbd-templates.css` to `?v=1.5` and `jbdeditor.js` to `?v=1.8` across the layout view.
- **Verification:** Syntax verified clean with `node -c` on all modified JavaScript files; validated CSS markup, template definitions, and subpage template selection.

---

### Session: October 17, 2026 — Online Forms: Shortcode Auto-Resolution & Public Front-End Embed Parser
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Public Front-End (`C:\inetpub\ChelanCounty.gov\app\views\helpers.cfm`, `C:\inetpub\ChelanCounty.gov\app\views\shared\_dept-overview.cfm`), Admin Page Studio (`app/views/pages/edit.cfm`), Documentation (`.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`)
- **Key Deliverables:**
  1. **Public Front-End Shortcode Resolver (`ChelanCounty.gov/app/views/helpers.cfm`):**
     - Implemented `renderCmsContent(required string html)` helper in `ChelanCounty.gov`.
     - Automatically parses `[chelan_form slug="..."]` and `[chelan_form id="..."]` tokens inside page bodies and dynamically transforms them into responsive, accessible iframe embeds pointing to `http://cmsadmin.chelancounty.gov/forms/preview?slug=...`.
  2. **Subpage & Overview Template Integration (`ChelanCounty.gov/app/views/shared/_dept-overview.cfm`):**
     - Wrapped all `#content.Body#` renderings with `#renderCmsContent(content.Body)#` across subpages, full-width layouts, and overview grids.
     - Resolved the issue where shortcodes like `[chelan_form slug="public-information-office-pio-media-press-inquiry-form-2"]` previously displayed as plain, unparsed text strings on live pages (such as `/assessor/page/contact-us`).
  3. **Page Editor Embed Form Snippet Upgrade (`app/views/pages/edit.cfm`):**
     - Updated `.btn-insert-embed-iframe` handler in the Page Editor Studio to output full cross-domain URLs with slugs (`http://cmsadmin.chelancounty.gov/forms/preview?slug=...`) instead of relative `/forms/preview?id=...`, ensuring iframes render seamlessly when pages are displayed on either domain.
  4. **Dynamic Auto-Height & Recursive Loop Prevention (`preview.cfm`, `helpers.cfm`):**
     - Added `is-embedded` styling to `preview.cfm` (`overflow: hidden !important; padding: 0.25rem 0 0.5rem 0; height: auto; max-width: 100%`).
     - Replaced unconstrained body `ResizeObserver` with a debounced bounding-box measurement of `.form-wrapper` guarded by `Math.abs(h - lastSentHeight) < 4` to prevent height feedback loops.
     - Hardened parent listener in `helpers.cfm` with bounds checking (`Math.max(350, Math.min(height, 3000))`) and delta checks, adding the requested +50px container height buffer without arbitrary runaway creep.
- **Verification:** Tested `http://chelancounty.gov/assessor/page/contact-us` and confirmed the iframe height stabilizes precisely at the exact form card height plus 50px of comfortable breathing room without recurring loops.

---

### Session: October 17, 2026 — Pages Module: Featured Cover Image Panel, Schema Migration & Pre-Flight Linter Integration
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Database Schema (`config/sql/schema-pages.sql`), Core Controller (`app/controllers/Pages.cfc`), Page Editor View (`app/views/pages/edit.cfm`), Documentation (`.doclib/006_PAGES_AND_REVISION_HISTORY_STUDIO.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`)
- **Key Deliverables:**
  1. **Featured Cover Image Panel Added to Pages Edit Studio (`app/views/pages/edit.cfm`):**
     - Replicated the Article Editor's cover image panel with exact visual styling, field naming, and UX ergonomics in `.pg-side-col` between `pgLayoutPanel` and `pgPublishPanel`.
     - Panel header features the image icon, live ADA compliance status badge (`#featuredImgAdaBadge`), and active workspace badge (`#featuredImgWsBadge`).
     - Image URL input (`#featuredImage`, `name="imageAttachment"`) with integrated `Browse Media` and `Remove` actions.
     - Interactive thumbnail preview / dropzone (`#featuredImgPreviewWrap`) linking directly to the County Media Picker overlay.
     - Decorative image toggle (`#featuredImageDecorative`, WCAG 2.1 H67) that automatically dims the alt text input container when checked and flags the element as presentation-only.
     - Alternative Text input (`#featuredImageAlt`) with real-time character counter (`0/150 rec.`), a "Suggest from Title" helper button, and dynamic audit warnings.
     - Public Story Caption (`#featuredImageCaption`, `name="imageTitle"`, `0/1000` counter) and Extended Narrative Description (`#featuredImageDescription`, `name="imageDescription"`, `0/2000` counter) for complex infographics or long captions.
     - Photo Credit & Attribution (`#featuredImageCredit`, `name="imageAttribution"`).
  2. **Database Schema & Self-Healing Column Provisioning (`config/sql/schema-pages.sql`, `app/controllers/Pages.cfc`):**
     - Updated `config/sql/schema-pages.sql` with `[imageDecorative] BIT NOT NULL CONSTRAINT [DF_pages_imageDecorative] DEFAULT (0)`.
     - Implemented `ensurePagesTableColumns()` in `Pages.cfc` to automatically detect and provision any missing cover image columns (`imageAttachment`, `imageAttribution`, `imageAlt`, `imageTitle`, `imageDescription`, `imageDecorative`) dynamically upon edit or save.
     - Adhered strictly to SQL Server filtered index requirements (`SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`) on all queries touching `dbo.pages`.
  3. **Revision History Snapshotting & Rollback Integration (`Pages.cfc`, `pages/edit.cfm`):**
     - Updated `recordPageRevision()` in `Pages.cfc` to capture all 6 cover image attributes into revision metadata JSON snapshots per Washington State RCW 42.56 compliance.
     - Updated `restoreRevision()` to restore image fields to the active record and return them in API responses.
     - Integrated `executeRollback()` client-side handler in `pages/edit.cfm` to restore all cover image inputs, reset previews, recalculate character counters, and re-evaluate ADA badges upon version rollback.
  4. **ADA WCAG 2.1 AA Pre-Flight Quality Gate Integration (`PageA11yLinter` in `pages/edit.cfm`):**
     - Added the `cover` category to `catCounts`, `_lastResults.categories`, category chips (`#chipA11yCover`), and drawer filters.
     - Integrated Rule Group 1 (Featured Cover Image) into `PageA11yLinter.scan()` to audit missing alt text on non-decorative images (critical error), generic/filename alt text (warning), and alt text exceeding 150 characters (warning).
     - Wired reactive `input` and `change` listeners on `#featuredImage`, `#featuredImageAlt`, and `#featuredImageDecorative` to trigger debounced linter scans.
  5. **Page Layout Moved to Page Attributes Group (`app/views/pages/edit.cfm`):**
     - Added **Page Layout** as the primary tab (`#tabBtnAttrLayout`, `#tabPanelAttrLayout`) within the **Page Attributes** card, containing the layout selection (`Full` vs `Right Sidebar`), available sidebars, subpage chooser, and subpage creation trigger.
     - Refactored tab navigation to smoothly cycle between **Page Layout**, **Navigation Assignment**, and **Folder Explorer**.
     - Removed redundant `#pgLayoutPanel` from the sidebar column (`.pg-side-col`), creating a clean 2-card sidebar (Featured Cover Image + Publish Card).
     - Replaced native `prompt()` in manual snapshot creation with an accessible modal dialog.
- **Verification:** Verified CFML compilation without syntax errors, tested template rendering returning HTTP 302 to login, and confirmed proper SQL Server filtered index flags.

---

### Session: October 16, 2026 — Media Explorer: Shared Images Server Path Resolution (`C:\inetpub\chelan-county\images\picjumbo`)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Files API (`api/Files.cfc`), Media Explorer Client (`javascripts/filexplorer/explorer.js`), Media Views (`app/views/media/index.cfm`, `app/views/media/picker.cfm`), Documentation (`.doclib/004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md`)
- **Key Deliverables:**
  1. **Canonical Server Path Resolution (`api/Files.cfc`):**
     - Updated `diskPathOf()` in `api/Files.cfc` so requests for `shared images` or its subfolders explicitly return the physical server path `C:\inetpub\chelan-county\images\picjumbo\` instead of the intermediate junction path.
     - Updated `webPathOf()` in `api/Files.cfc` so web URLs resolve cleanly to `/images/picjumbo/`.
  2. **Client-Side Explorer Synchronization (`javascripts/filexplorer/explorer.js`):**
     - Updated `diskPath()` in `explorer.js` so all inspector dialogs, file details sidebars, and item properties show `Server path: C:\inetpub\chelan-county\images\picjumbo\...`.
     - Updated `webPath()` and `webHref()` so `Web URL` consistently shows `/images/picjumbo/...`.
     - Standardized `rulesNote()` and bumped cachebuster to `v=2.9` in `media/index.cfm` and `media/picker.cfm`.
- **Verification:** Verified `api/Files.cfc?method=list&path=shared images` returns `diskPath: C:\inetpub\chelan-county\images\picjumbo\` and `webPath: /images/picjumbo/`. Syntax checked `explorer.js` via `node -c`.

---


### Session: October 16, 2026 — Documentation Hub: User Guide PDF & Technical Manual Integration
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Documentation Module (`app/controllers/Documentation.cfc`, `app/views/documentation/index.cfm`, `app/views/documentation/userGuide.cfm`, `config/routes.cfm`, `app/views/layout.cfm`, `miscellaneous/docs/`, `c:\inetpub\chelan-county\files\shared\documents\`)
- **Key Deliverables:**
  1. **User Guide & System Architecture PDF Assets:**
     - Deployed `CMSAdmin-2.0-User-Guide.pdf` (489 KB) and `CMSAdmin-2.0-Documentation.pdf` (931 KB) into `miscellaneous/docs/` for clean web serving.
     - Also mirrored both PDFs into `c:\inetpub\chelan-county\files\shared\documents\` so they are accessible directly within the County Shared Media Library for editors.
  2. **Controller & Routes (`Documentation.cfc`, `config/routes.cfm`):**
     - Added `userGuide()` action to `Documentation.cfc` exposing `variables.pdfUrl` and `variables.systemDocUrl`.
     - Registered `/documentation/user-guide` and `/documentation/userGuide` routes in `config/routes.cfm`.
  3. **Embedded Viewer Studio (`app/views/documentation/userGuide.cfm`):**
     - Created an interactive WCAG 2.1 AA compliant viewer studio featuring document metadata cards (Format, File Size, Target Audience, Compliance Standard).
     - Embedded a responsive PDF viewer (`<iframe>`) with fallback download links, "Open in New Tab", and direct PDF download button.
  4. **Documentation Hub & Navigation Updates (`app/views/documentation/index.cfm`, `app/views/layout.cfm`):**
     - Revamped `documentation/index.cfm` with featured cards for the **Official User Guide (PDF)** and **System Architecture Blueprint (PDF)** alongside the interactive Form Builder and JBDEditor guides.
     - Added **CMSAdmin User Guide (PDF)** submenu link directly into the Documentation sidebar nav in `layout.cfm`.
- **Verification:** Verified `/documentation` and `/documentation/user-guide` returning HTTP 200, verified static PDF asset delivery returning HTTP 200 `application/pdf`, and verified zero errors in `wheels.log`.

---


### Session: October 16, 2026 — Articles CFML Compilation Fix (`articles/edit.cfm`)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Articles Module (`app/views/articles/edit.cfm`)
- **Root Cause & Resolution:**
  - Resolved `Wheels failed to initialize. [coldfusion.util.RuntimeWrapper] Invalid CFML construct found on line 452 at column 205` preventing `/articles`, `/articles/new`, and `/articles/edit` from loading.
  - Line 452 had an unescaped CSS hex color `#e2e8f0` within a `<cfoutput>` block (`border-top:1px solid var(--admin-border-subtle, #e2e8f0)`).
  - Adobe ColdFusion parsed `#e2e8f0` as an open CFML expression variable, resulting in an unclosed CFML construct syntax error during template compilation.
  - Escaped the hex code as `##e2e8f0`. Verified clean template compilation, tested authenticated access to `/articles` and `/articles/new` returning HTTP 200, and verified zero runtime errors in `wheels.log`.

---


### Session: October 16, 2026 — RFP & Municipal Solicitations Manager Module (TODO 3.5)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Database Schema (`config/sql/schema-rfp-manager.sql`), Core Controller (`app/controllers/Rfps.cfc`), Base Controller & Public Security (`app/controllers/Controller.cfc`), Scheduled Transitions Integration (`app/global/functions.cfm`), Admin Views (`app/views/rfps/index.cfm`, `app/views/rfps/edit.cfm`), Public Views (`app/views/rfps/publicList.cfm`, `app/views/rfps/publicView.cfm`), Routes (`config/routes.cfm`), Sidebar Navigation (`app/views/layout.cfm`), View Helpers (`app/views/helpers.cfm`), Documentation Series (`.doclib/011_RFP_AND_SOLICITATIONS_MANAGER.md`, `.doclib/000_SERIES_INDEX.md`).
- **Key Deliverables:**
  1. **Architectural Scope Alignment (Announcement-First Model):**
     - Per county requirements, streamlined the module from a heavy procurement ERP down to a high-efficiency **Solicitation & Announcement Board**. Eliminated unnecessary vendor login, planholder gatekeeping, and complex sealed-bid evaluation machinery.
     - Public views focus strictly on clear scopes of work, direct specifications PDF downloads, sequenced addenda revisions, and precise submittal instructions ("How to Submit").
  2. **Relational Database Schema & Filtered Indexes (`config/sql/schema-rfp-manager.sql`):**
     - Created `dbo.rfp_solicitations` with workspace scoping (`site_id`), statutory milestone dates, budget range, and BOCC award fields.
     - Created `dbo.rfp_addenda` with sequential numbering, title, change summaries, and cascade delete.
     - Applied filtered nonclustered unique indexes (`UX_rfp_solicitations_slug_site`, `UX_rfp_solicitations_number`, `IX_rfp_solicitations_status`) with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`.
  3. **Core Procurement Controller (`app/controllers/Rfps.cfc`):**
     - Full CRUD with trigger-safe `OUTPUT INSERTED.id INTO @InsertedTable` patterns.
     - Multi-faceted filter engine supporting workspace, status, type, and keyword search.
     - Sequenced Addenda manager with automatic numbering and file attachment via Media Picker.
     - Public bid board controller actions (`publicList`, `publicView`) opened in `Controller.cfc` (`isPublicRequest()`).
  4. **Automated Lifecycle Integration (`app/global/functions.cfm`):**
     - Added steps 9 & 10 to `evaluateScheduledTransitions()` automatically shifting `Scheduled` solicitations to `Open` on publication date, and `Open` solicitations to `Under Review` the minute the submission deadline expires.
  5. **Admin UI & Public Bid Board Views:**
     - `index.cfm`: Streamlined announcement directory with 4 KPI cards (Total, Active/Open, Closing Soon, Closed/Awarded), search/filter bar, and clean management actions.
     - `edit.cfm`: Completely unified 2-column layout replacing multi-tab overhead. Features project identification, rich-text scope, specs packet & addenda picker, submittal instructions, important dates, and department contacts.
     - Polished URL Slug input group with single-line `https://chelancounty.gov/bids/` prefix (`white-space: nowrap`), seamless monospace input, and live `/bids/[slug]` preview.
     - `publicList.cfm` & `publicView.cfm`: High-accessibility (WCAG 2.1 AA) public bid board and clean solicitation notice with countdown urgency badges, specifications PDF download, and delivery requirements card.
- **Verification:** Verified SQL schema migration via `sqlcmd`, tested public endpoints `http://cmsadmin.chelancounty.gov/bids` and `http://cmsadmin.chelancounty.gov/bids/manson-boulevard-roadway-drainage-improvements` returning HTTP 200, verified admin edit studio `http://cmsadmin.chelancounty.gov/rfps/edit?id=1` with zero errors, and logged milestone.

---

### Session: October 16, 2026 — Scheduled Publishing & Expiration Automation (TODO 3.2)
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Database Schema (`config/sql/schema-scheduled-publishing.sql`), Core Scheduler Engine (`app/global/functions.cfm`, `app/events/onrequeststart.cfm`), Scheduler Controller & REST API (`app/controllers/Scheduler.cfc`, `app/controllers/Controller.cfc`, `config/routes.cfm`), Pages Module (`app/controllers/Pages.cfc`, `app/views/pages/edit.cfm`), Articles Module (`app/controllers/Articles.cfc`, `app/views/articles/edit.cfm`, `app/views/articles/index.cfm`), Calendar Events Module (`app/controllers/Events.cfc`, `app/views/events/index.cfm`), Jobs & Careers Module (`app/controllers/Jobs.cfc`, `app/views/jobs/edit.cfm`, `app/views/jobs/index.cfm`), Settings Diagnostics (`app/controllers/Settings.cfc`, `app/views/settings/system.cfm`).
- **Key Deliverables:**
  1. **Database Schema & Filtered Nonclustered Indexes (`config/sql/schema-scheduled-publishing.sql`):**
     - Added `publish_at` and `unpublish_at` (`DATETIME2 NULL`) to `pages`, `articles`, `calendar_events`, `job_listings`, and `job_postings`.
     - Standardized dual-column support (`PublishAt`/`publish_at` and `UnpublishAt`/`unpublish_at` on `pages`; `published_at`/`publish_at` on `articles`; `PostDate`/`ApplicationDeadline` on `job_listings`; `open_date`/`close_date` on `job_postings`).
     - Created filtered nonclustered indexes with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` for high-speed queries on pending scheduled releases and active expirations.
  2. **Core Transition Evaluator & Throttled Request Worker:**
     - Implemented `evaluateScheduledTransitions()` and `getScheduledPublishingSummary()` in `app/global/functions.cfm`.
     - Integrated throttled execution in `app/events/onrequeststart.cfm` (executing at most once every 60 seconds protected by mutex lock `application.schedulerLock`).
     - Added `Scheduler.cfc` providing authenticated and public API endpoints (`/scheduler/run`, `/scheduler/status`, `/api/v1/scheduler/run`, `/api/v1/scheduler/status`).
  3. **Multi-Module UI & Workflow Integration:**
     - **Pages:** Supported `publish_at` and `unpublish_at` in `Pages.cfc` and added "Unpublish / Expire On" input to Section 2 of `pages/edit.cfm`.
     - **Articles:** Supported `scheduled` and `archived` states in `Articles.cfc`, added `unpublish_at` datetime picker and `scheduled` status option in `articles/edit.cfm`, and added a Scheduled metric card and filter in `articles/index.cfm`.
     - **Calendar Events:** Added `Scheduled` and `Archived` statuses in `Events.cfc`, updated `save()` INSERT/UPDATE queries, and integrated `evPublishAt` and `evUnpublishAt` fields and payload serialization in `events/index.cfm`.
     - **Careers & Job Listings:** Added `Scheduled` and `Archived` lifecycle support to `Jobs.cfc`, updated `save()` with `publish_at` and `unpublish_at` persistence, added release/expiration datetime inputs to `jobs/edit.cfm`, and added a Scheduled KPI card, filter dropdown, and badge rendering to `jobs/index.cfm`.
     - **System Diagnostics:** Added an "Automated Publishing & Expiration Worker" telemetry card to `settings/system.cfm` displaying live pending queues across all 4 modules, worker interval status, and an interactive "Run Evaluator Now" trigger with toast feedback.
- **Verification:** Verified `/api/v1/scheduler/status` and `/api/v1/scheduler/run` REST endpoints, simulated automated article publishing (`scheduled` &rarr; `published`) upon passing release datetime, and confirmed clean database state.

---

### Session: October 16, 2026 — Navigation Manager Restoration, Page Save SQL Trigger Fix & ADA Inspect Diagnostics
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Navigation Manager (`app/controllers/Navigation.cfc`, `app/views/navigation/index.cfm`), Pages Module (`app/controllers/Pages.cfc`, `app/views/pages/edit.cfm`), Articles Module (`app/views/articles/edit.cfm`)
- **Key Deliverables:**
  1. **Navigation Manager Restoration (`Navigation.cfc`, `app/views/navigation/index.cfm`):**
     - Resolved UTF-8 mojibake (`â‹®â‹®`, `â†‘`, `â†“`, `Ã—`, `Â·`) by adding `<cfprocessingdirective pageencoding="utf-8">` and replacing raw multi-byte symbols in JavaScript with Unicode escapes (`\u22EE\u22EE`, `\u2191`, `\u2193`, `\u00D7`, `\u00B7`).
     - Replaced hardcoded placeholder `<select id="navigationPage">` options (`/index.cfm/pages/index`, etc.) with dynamic workspace pages queried from `dbo.pages` + `page_FolderExplorer` for the active workspace, plus the workspace home path (e.g., `/assessor`).
     - Added automatic self-healing in `Navigation.cfc` (`index()`) to repair menu items whose `destination` was previously overwritten with `/index.cfm/pages/index` back to their proper workspace page URLs (e.g., `/assessor/maps`, `/assessor/appeal`, `/assessor/contact-us`).
     - Added `protectsFromForgery(except="saveItem,deleteItem,reorder")`, `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`, and SQL Server trigger-safe `OUTPUT INSERTED.id INTO @TableVar` in `Navigation.cfc`.
  2. **Page Creation & Save SQL Server Trigger Compatibility (`Pages.cfc`):**
     - Fixed `Unable to create page: Error Executing Database Query` caused by SQL Server error `The target table 'pages' of the DML statement cannot have any enabled triggers if the statement contains an OUTPUT clause without INTO clause`.
     - Updated `INSERT INTO pages` in `Pages.cfc` (`save()` and `syncWorkspaceFiles()`) to use `DECLARE @InsertedPages TABLE (newId INT); ... OUTPUT INSERTED.ContentID INTO @InsertedPages(newId); SELECT newId FROM @InsertedPages;`.
     - Fixed `FK_page_FolderExplorer_pages` foreign key constraint violation when syncing workspace files by inserting `ContentID = NULL` into `page_FolderExplorer` when no matching `dbo.pages` row exists.
  3. **ADA Pre-Flight "Inspect Diagnostics" Drawer & Inline Scorecard (`app/views/pages/edit.cfm`, `app/views/articles/edit.cfm`):**
     - Connected the `#adaTopTrigger` ("Inspect Diagnostics") button and added an inline expandable diagnostics scorecard directly below the top banner in both the Page Studio and Article Editor.

---

### Session: October 16, 2026 — JBDEditor Table Insertion & Table Tools Restoration Across All Instances
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Rich Text Editor (`javascripts/jbdeditor.js`, `stylesheets/jbdeditor.css`, `app/views/layout.cfm`, `javascripts/jbdeditor/*`, `vendor/jbdeditor/src/*`)
- **Key Deliverables:**
  1. **Restored Missing `Dialog.openTableDialog`, `Dialog.openImageDialog`, and `Dialog.openSpecialCharsDialog`:**
     - Resolved `TypeError: Dialog.openTableDialog is not a function` in `javascripts/jbdeditor.js` where those static `Dialog` methods had been accidentally omitted from the main bundled editor script.
  2. **Fixed `TableManager` Cell Creation & Active Cell Detection:**
     - Replaced literal `'&nbsp;'` string children in `TableManager.addRowAbove`, `addRowBelow`, `addColLeft`, and `addColRight` with Unicode non-breaking space `'\u00A0'` so `createElement` (`document.createTextNode`) no longer prints literal `&nbsp;` text into added cells.
     - Enhanced `TableManager.getActiveCell(container, savedRange)` to fall back to `savedSelectionRange` when toolbar clicks move focus, and added `Tab` / `Shift+Tab` keyboard cell navigation inside tables.
     - Improved `openTableModal()` block-level insertion so tables are not nested inside `<p>` tags, always have a trailing paragraph `<p><br></p>` beneath them, and automatically focus the first cell on creation.
  3. **Enabled Table Controls Across All Toolbar Presets & Styled All Editor Tables:**
     - Added `'table', 'tableTools'` to `JBD_SUBPAGE_TOOLBAR` and `'tableTools'` to `JBD_ARTICLE_TOOLBAR`, and registered `subpage` in `CustomEditor.TOOLBAR_PRESETS` so Pages, Subpages, Articles, Press Releases, Job Descriptions, and Documentation editors all have full table support.
     - Updated `stylesheets/jbdeditor.css` (`v=1.8`) and `javascripts/jbdeditor.js` (`v=1.7`) in `app/views/layout.cfm` so all `<table>` and `<caption>` elements inside `.jbd-editor-content` render with clear borders, cell padding, and header backgrounds.
- **Verification:** Verified `node -c javascripts/jbdeditor.js` syntax check and synchronized all editor bundle copies.

---

### Session: October 16, 2026 — Workspace Deletion Fix & Adobe ColdFusion `DirectoryCreate` Compatibility
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Workspaces Module, Global Functions & Core Admin JS (`app/controllers/Workspaces.cfc`, `app/global/functions.cfm`, `app/views/workspaces/index.cfm`, `config/routes.cfm`, `javascripts/admin.js`, `app/views/layout.cfm`, `app/controllers/Forms.cfc`)
- **Key Deliverables:**
  1. **Adobe CF `DirectoryCreate` Fix:**
     - Resolved `[coldfusion.compiler.validation.FunctionArgMismatchException] Parameter validation error for the DIRECTORYCREATE function` when compiling `Workspaces.cfc` and `Forms.cfc` on Adobe ColdFusion 2021.
     - Replaced Lucee-specific 2-argument `DirectoryCreate(path, true)` calls with engine-agnostic `CreateObject("java", "java.io.File").init(path).mkdirs()`.
  2. **Workspace Deletion & Re-Seeding Fix:**
     - Fixed `getMasterWorkspaces()` and `ensureMasterWorkspacesTablePopulated()` in `app/global/functions.cfm` which previously forced a re-seed whenever active workspace count dropped below 16 (`arrayLen < 16` / `qCheck.cnt < 16`), causing deleted workspaces to immediately reappear or preventing cache refreshes.
     - Prepended `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` to all `cms_workspaces` SQL Server queries in `Workspaces.cfc` and `functions.cfm`.
     - Added explicit `workspacesDelete` routes in `config/routes.cfm` and exposed the **Delete** action button directly in the main workspace table row in `app/views/workspaces/index.cfm`.
     - Updated `javascripts/admin.js` (`v=1.5`) so `a[data-confirm]` links do not prematurely trigger the global page loading overlay before the user confirms the modal dialog.
- **Verification:** Verified workspace soft-deletion, cache invalidation, and clean compilation on `/workspaces`.

---

### Session: October 16, 2026 — Articles ADA Pre-Flight Linter & Cover Image Media Browser
- **Author/Agent:** Antigravity AI Pair Programmer
- **Scope:** Articles & Posts Module (`Articles.cfc`, `app/views/articles/edit.cfm`)
- **Key Deliverables:**
  1. **Workspace Image Browser Integration:**
     - Connected the Article cover image selector directly to the workspace-assigned media picker modal (`/media/picker?folder=images&ws={assignedWorkspace}`).
     - Handled thumbnail selection with postMessage and direct callback support.
  2. **Database Schema Extension for ADA Cover Image Controls:**
     - Executed SQL Server `ALTER TABLE articles` with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` adding:
       - `featured_image_caption` (`NVARCHAR(1000) NULL`)
       - `featured_image_description` (`NVARCHAR(2000) NULL`)
       - `featured_image_credit` (`NVARCHAR(255) NULL`)
       - `featured_image_decorative` (`BIT NOT NULL DEFAULT 0`)
     - Updated `Articles.cfc` (`ensureArticlesTableColumns`, `new`, `edit`, `save`) to persist all 4 columns.
  3. **Cover Image Accessibility UI & Real-Time Validator:**
     - Added decorative toggle checkbox (WCAG Technique H67) to skip screen reading for purely mood/decorative photos.
     - Added dynamic Alt Text quality auditing (flags raw filenames like `.jpg`, and generic words like `"photo"`, `"image"`).
     - Added "Suggest from Headline" button to auto-draft concise alt text from article headlines.
     - Added real-time ADA compliance badge (`No Image`, `ADA Pass`, `Decorative Pass`, `Alt Text Required`, `Generic Alt Warning`).
     - Added visible story caption and extended description (for complex infographics/maps) fields.
  4. **In-Editor Automated ADA WCAG Pre-Flight Linter (`ArticleA11yLinter`):**
     - Built comprehensive live linter engine in `app/views/articles/edit.cfm` analyzing cover images, story content images, heading hierarchy, link quality, table structure, and readability contrast.
     - Embedded sticky linter bar above `#articleContent` with overall compliance badge and category breakdown chips.
     - Implemented expandable diagnostic and quick-fix drawer with filter tabs (All, Errors, Warnings), issue cards, "Locate in Editor" pulsing, and one-click quick fixes.
     - Added companion scorecard widget to sidebar Publish Settings card.
     - Enforced pre-flight quality gate in `saveArticleForm()` that intercepts publishing if critical accessibility errors remain, prompting authors with `window.adminConfirm`.
  5. **Creation of System Knowledge Library (`.doclib/`):**
     - Established series-based documentation library with mandatory AI instructions.
- **Verification:** Verified live HTTP 200 rendering, schema persistence, and clean execution on `http://cmsadmin.chelancounty.gov/articles/new`.

---

### Session: October 15, 2026 — Page Revision History & Rollback Studio (Feature 2.2)
- **Scope:** Pages Module & RCW 42.56 Public Records Act Compliance
- **Key Deliverables:**
  1. Created `dbo.page_revisions` schema (`config/sql/schema-page-revisions.sql`) and `app/models/PageRevision.cfc`.
  2. Added automatic baseline snapshotting on edit, incremented change snapshotting on save with author attribution and optional revision note.
  3. Implemented mandatory pre-rollback safety snapshots in `restoreRevision()` before live record replacement.
  4. Built accessible modal studio (`#pgRevisionsModal`) in `app/views/pages/edit.cfm` featuring:
     - Chronological timeline cards.
     - LCS word/token-level diff generator.
     - 4 comparison view modes: Visual Diff, Side-by-Side Split, Snapshot Preview, and Raw HTML.
     - One-click version rollback powered by `window.adminConfirm`.
- **Verification:** Verified snapshot generation, diff generation across multiple edits, and rollback restoration.

---

### Session: October 15, 2026 — Emergency Alerts & Incident Dispatch System (Feature 2.1)
- **Scope:** Public Safety & PIO Dispatch System (`Alerts.cfc`, `app/views/alerts/index.cfm`)
- **Key Deliverables:**
  1. Created `dbo.emergency_alerts` table with severity levels (`critical`, `warning`, `info`) and filtered index `WHERE deletedat IS NULL`.
  2. Built Incident Dispatch Studio with live banner simulator and quick presets (Wildfires, Pass Closures, Floods, Courthouse Closures).
  3. Created high-speed public JSON endpoint `GET /api/v1/alerts/active` and configured IIS URL Rewrite rules.
  4. Added top-header emergency badge counter and workspace scoping.
- **Verification:** Hand-tested simulated alerts across all severity tiers, verified JSON API payload.

---

### Session: October 15, 2026 — Staff Profile & Password Management (Feature 1.4)
- **Scope:** User Management (`Users.cfc`, `app/views/users/profile.cfm`)
- **Key Deliverables:**
  1. Created profile management interface supporting user details and preferences.
  2. Added secure password update flow with current password hashing check, length requirements, and match confirmation.
  3. Linked to global admin header user dropdown.
- **Verification:** Hand-tested password update cycle and verified hash updates in `cms_users`.

---

### Session: October 14, 2026 — County Domain Standardization (`chelancounty.gov`)
- **Scope:** Entire Codebase & Database
- **Key Deliverables:**
  1. Executed global migration replacing legacy domain `co.chelan.wa.us` with official `chelancounty.gov`.
  2. Executed database replacement queries across SQL Server tables (`emergency_alerts`, `how_do_i_items`, `cms_users`, `cms_workspaces`, `calendar_events`, `pages`, `job_applications`).
  3. Verified 0 remaining instances of legacy domain.

---

### Milestone 9: Adobe ColdFusion Compatibility, JBDEditor Table Overhaul, ADA Pre-Flight Diagnostics & Page Creation SQL Fix
- **Files Modified:**
  - `app/controllers/Workspaces.cfc`, `app/controllers/Forms.cfc`, `app/controllers/Pages.cfc`, `app/helpers/functions.cfm`, `app/views/workspaces/index.cfm`, `config/routes.cfm`
  - `javascripts/jbdeditor.js`, `stylesheets/jbdeditor.css`, `app/views/layout.cfm`, `javascripts/admin.js`
  - `app/views/pages/edit.cfm`, `app/views/articles/edit.cfm`
- **Root Causes & Engineering Solutions:**
  1. **Adobe ColdFusion Tag/Function Compatibility:** Replaced 2-argument `DirectoryCreate(..., true)` with sequential parent directory checks and refactored `cfcookie(...)` in `cfscript` to a tag-based helper `setActiveWorkspaceCookie()`.
  2. **JBDEditor Table Engine (`TableManager`):** Added custom modal table insertion dialog (rows, columns, headers, caption, width), Tab/Shift+Tab cell navigation, cell selection anchors, and full table styling (`stylesheets/jbdeditor.css`) across all editor presets.
  3. **ADA Pre-Flight "Inspect Diagnostics" Toggle & Inline Scorecard (`pages/edit.cfm` & `articles/edit.cfm`):**
     - Fixed `.pg-a11y-drawer { display: flex; }` overriding the HTML `[hidden]` attribute by adding `.pg-a11y-drawer[hidden] { display: none !important; }` and explicitly synchronizing `drawer.style.display` and `drawer.hidden` inside `syncDrawerState()`.
     - Added an expandable inline diagnostics list (`#pgA11yPublishInlineList` and `#articleA11yPublishInlineList`) directly inside the sidebar **ADA Pre-Flight** Publish widget with `Locate` and `Quick Fix` buttons, synchronized chevron rotation (`Inspect Diagnostics` / `Hide Diagnostics`), and replaced all remaining native `prompt()` calls in `PageA11yLinter.applyQuickFix` with a custom accessible modal (`askA11yInputModal`).
  4. **Page Creation & Save SQL Server Trigger / Foreign Key Fixes (`Pages.cfc`):**
     - Fixed `The target table 'pages' of the DML statement cannot have any enabled triggers if the statement contains an OUTPUT clause without INTO clause` in `createModal()`, `save()`, `saveFolderExplorer()`, `saveSubpage()`, `saveHowDoIItem()`, and `saveHowDoICategory()` by declaring a table variable `@InsertedPages` / `@InsertedRows` and using `OUTPUT INSERTED.ContentID INTO @InsertedPages(newId)`.
     - Fixed `FK_page_FolderExplorer_pages` foreign key constraint conflict during `save()` by replacing `SET ContentID = 0` with `SET ContentID = NULL` inside a guarded `try/catch` block.




---

### Milestone 10: ADA Pre-Flight Linter & Scorecard Synchronization (`pages/edit.cfm` & `articles/edit.cfm`)
- **Files Modified:**
  - `app/views/pages/edit.cfm`, `app/views/articles/edit.cfm`
- **Issue:**
  - The companion **ADA Pre-Flight** scorecard badge displayed `PASS` (in green) and 'Content ready for public release. Meets ADA WCAG 2.1 AA.' even when active warning diagnostics (e.g. `Top-Level Section Skips <h2> (Found <h3>)`) were rendered in the inline diagnostic list.
- **Root Causes & Engineering Solutions:**
  1. **Asynchronous Editor Binding:** `getEditor()` was called once during `DOMContentLoaded` before `JBDEditor` finished initializing. As a result, input and change listeners were not bound to the editor content area, causing scans not to trigger dynamically during user editing. Added `bindEditorEvents()` with async polling and on-demand binding inside `getHtmlContent()`.
  2. **Authoritative Scan on Drawer Toggle:** `openDrawer()` and `toggleDrawer()` previously called `renderDrawerList()` without invoking `scan()`. Updated both to immediately trigger `scan()`, ensuring the latest editor DOM is parsed and the scorecard badge, summary, and diagnostic cards are freshly computed.
  3. **Strict Scorecard Self-Healing in `renderPublishInlineList()`:** Added direct synchronization of `##pgA11yPublishBadge` / `##articleA11yPublishBadge` and summary text inside `renderPublishInlineList()` based on `_lastResults.issues`. When warnings exist, the badge automatically reflects `1 WARNING` / `X WARNINGS` (`badge-warning`), and turns `badge-success` / `PASS` only when 0 violations and 0 warnings exist.
  4. **Pluralization Grammar:** Corrected badge label grammar from `1 WARNINGS` to `1 WARNING` and `1 CRITICAL`.
  5. **Early Return Clearing Bug in `renderDrawerList()`:** Previously, when all issues were resolved (`filtered.length === 0`), `renderDrawerList()` returned early before calling `renderPublishInlineList()`. Consequently, `#pgA11yPublishInlineList` was never cleared, leaving stale diagnostic cards (e.g. `WARN: Top-Level Section Skips <h2>`) visible in the sidebar Publish card while the rest of the linter reported `Compliant` / `PASS`. Removed the early return blockage, called `renderPublishInlineList()` directly from `renderUI()`, and updated `lnkInspectA11yText` to dynamically reflect exact issue counts (`Inspect Diagnostics (X)` vs `View Audit Summary`).


---

### Milestone 11: RFP & Bids Module Workspace Streamlining & ColdFusion LSP Hardening
- **Files Modified:**
  - `app/controllers/Rfps.cfc`, `app/views/rfps/edit.cfm`, `app/views/rfps/index.cfm`, `app/views/rfps/publicList.cfm`, `app/views/layout.cfm`
- **Key Deliverables & Engineering Solutions:**
  1. **Redundant Workspace Control Elimination (`rfps/edit.cfm`):** Removed the redundant "Issuing Department" `<select id="site_id">` dropdown block from the RFP edit/create template to align with the global top-header workspace switcher (Alt+W).
  2. **Seamless Data Binding & Media Picker Scoping:** Replaced the visible dropdown with a hidden `<input type="hidden" name="site_id" id="site_id">` at the form root. Enhanced `openMediaPickerForInput()` to read `site_id` with fallback to `cmsadmin_workspace` cookie, and added an event listener for `cmsadmin:workspaceChanged` to automatically synchronize new announcements with header workspace selection.
  3. **Controller Workspace Resolution (`Rfps.cfc`):** Updated `new()` and `save()` to resolve active workspace via `resolveUserActiveWorkspace()` using request parameters, `cmsadmin_workspace` cookie, and user role scoping, guaranteeing data isolation across county departments.
  4. **ColdFusion Template Parser Hardening:** Replaced embedded `<cfif>` conditionals inside HTML attributes with standard CFML ternary expressions `#(cond ? "val" : "")#` across all RFP templates and `layout.cfm`, resolving ColdFusion LSP diagnostic warnings.


---

### Milestone 12: Media Library Permanent Repository Assignment (`chelan-county\files` & `picjumbo`) & Strict Read-Only Governance
- **Files Modified:**
  - `api/Application.cfc`, `api/Files.cfc`, `app/controllers/Media.cfc`, `app/controllers/Main.cfc`, `app/controllers/Pages.cfc`, `app/controllers/Workspaces.cfc`
  - `app/views/media/upload.cfm`, `app/views/pages/edit.cfm`, `app/views/pages/folderExplorer.cfm`
  - `javascripts/filexplorer/explorer.js`, `stylesheets/filexplorer/explorer.css`
  - `.gitignore`, `.doclib/004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md`, `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`
- **Key Deliverables & Engineering Solutions:**
  1. **Permanent Main Repository (`c:\inetpub\chelan-county\files\`):**
     - Assigned `c:\inetpub\chelan-county\files\` as the authoritative permanent repository for all county documents and workspace assets across `CMSAdmin 2.0`.
     - Mirrored `c:\inetpub\CMSAdmin2.0\files\` to `c:\inetpub\chelan-county\files\` via an NTFS directory junction, allowing IIS to serve `/files/...` directly from the public county web root with zero delay or duplication.
     - Updated controllers (`Media.cfc`, `Main.cfc`, `Workspaces.cfc`, `Pages.cfc`) and API services (`api/Application.cfc`, `api/Files.cfc`) to target `c:\inetpub\chelan-county\files\` as `filesRoot`.
  2. **County-Wide Shared Image Library Outside Workspace Folders (`picjumbo`):**
     - Permanently established `c:\inetpub\chelan-county\images\picjumbo` as the centralized county stock image repository.
     - Positioned `shared images` directly at the files root (`c:\inetpub\chelan-county\files\shared images`), strictly outside all workspace folders.
     - Workspace directories remain cleanly partitioned containing only department folders (`images`, `documents`).
     - Rendered `Shared Images` in the left Explorer tree as a dedicated root-level library node with a visual divider, camera icon, and `RO` badge.
     - Implemented runtime auto-provisioning helper `ensureSharedImagesJunction(rootDisk)` in `api/Files.cfc`, `Media.cfc`, and `Workspaces.cfc`.
  3. **Strict Multi-Layer Read-Only Enforcement (All Users):**
     - **UI Layer:** Disabled "New Folder" / "Upload" actions when navigating within `shared images`. Suppressed the folder delete button, and surfaced `READ-ONLY` and `RO` visual chips in tree and file views.
     - **Files API (`api/Files.cfc`):** In `createFolder()` and `deleteFolder()`, blocked any mutation operations targeting `shared images` or its subpaths with explicit read-only errors. Set `canCreate: false` and `canDelete: false` in list payloads. Allowed `picjumbo` canonical path verification in `resolvePath()`.
     - **Media Controller (`app/controllers/Media.cfc`):** In `processUpload()` and `updateMeta()`, strictly rejected uploads and metadata modifications targeting `shared images`.
  4. **Media Picker Asset Resolution:**
     - In `javascripts/filexplorer/explorer.js`, enhanced `selectForPicker()` to detect assets originating from `shared images` or `picjumbo` and resolve clean, public web paths `/images/picjumbo/<filename>`.
  5. **Git Repository Isolation:**
     - Configured `.gitignore` to ignore `/files/` and `/images/picjumbo/` while retaining `/files/.gitkeep`, ensuring local NTFS junction points and external image assets are not committed into version control.

---

### Milestone 13: Call to Action Studio, Flexible Column Layouts (4-Col, 3x1, 50/50 Split) & Media Library Integration
- **Files Modified:**
  - `app/views/pages/callToAction.cfm`, `app/views/pages/edit.cfm`, `app/global/functions.cfm`, `stylesheets/jbd-templates.css`
  - `javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `vendor/jbdeditor/src/dialog.js`
  - `app/controllers/Pages.cfc`, `config/routes.cfm`, `app/views/layout.cfm`, `app/views/pages/index.cfm`
- **Key Deliverables & Engineering Solutions:**
  1. **Call to Action Studio Modernization:**
     - Established "Call to Action Studio" as a core component of the Pages section for managing cards, multi-action grids, and shortcodes.
     - Streamlined creation and edit modals by removing redundant Department/Workspace dropdowns, binding new cards directly to the active workspace resolved from the global header switcher.
  2. **Flexible Multi-Column Responsive Grid Layouts:**
     - **CSS Grid Architecture (`stylesheets/jbd-templates.css`):**
       - `4 Columns (4 Col Grid)`: `.cta-grid-4` (4 columns desktop `1fr 1fr 1fr 1fr`, 2 tablet at 1100px, 1 mobile at 640px).
       - `3 Columns (3x1 Reference)`: `.cta-grid-3` (3 columns desktop `1fr 1fr 1fr`, 2 tablet at 991px, 1 mobile at 640px).
       - `2 Columns (2x2 / 50-50 Split)`: `.cta-grid-2`, `.cta-grid-50-50` (2 columns 50/50 desktop `1fr 1fr`, 1 mobile at 640px).
     - **Shortcode Parser Enhancement (`app/global/functions.cfm`):**
       - Updated `renderCallToActionShortcodes()` to parse `cols`, `columns`, and `layout` shortcode attributes (e.g. `cols="4"`, `layout="4col"`, `cols="3"`, `layout="3x1"`, `cols="2"`, `layout="2x2"`, `layout="50/50"`).
       - Implemented automatic intelligent inference when column count is omitted: 2 items render as 50/50 split (`cta-grid-2 cta-grid-50-50`), 4 items render as 4-column (`cta-grid-4`), and others default to 3-column (`cta-grid-3`).
  3. **Studio Grid Builder Modal (`callToAction.cfm`):**
     - Added column layout selector with radio controls for `3 Columns (3x1 Reference)`, `4 Columns (4 Col Grid)`, and `2 Columns (2x2 / 50-50 Split)`.
     - Wired real-time synchronization in `updateGridBuilderOutput()` to update shortcode output and semantic HTML preview dynamically upon layout change.
  4. **Page Editor Embed Modal Integration (`pages/edit.cfm`):**
     - Added layout select dropdown (`3 Columns (3x1 Grid)`, `4 Columns (4 Col Grid)`, `2 Columns (2x2 / 50-50 Split)`) in `#embedCtaModal` footer.
     - Enhanced `btnEmbedGrid` and `btnInsertGridSc` handlers to embed selected HTML classes and append `cols="..."` to inserted shortcodes.
  5. **Interactive Media Library Picker Integration:**
     - Integrated County File Explorer modal with `postMessage` protocol into Call to Action Studio (`#btnBrowseCtaImage`), allowing direct asset selection and automatic population of image URLs and accessible alt text.
  6. **JBDEditor Block Templates:**
     - Added `cta-4col-grid` alongside `cta-reference-grid` and `cta-grid` in `javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, and `vendor/jbdeditor/src/dialog.js`.

---

### Milestone 13: Call to Action Studio, Flexible Column Layouts (4-Col, 3x1, 50/50 Split) & Media Library Integration
- **Files Modified:**
  - `app/views/pages/callToAction.cfm`, `app/views/pages/edit.cfm`, `app/global/functions.cfm`, `stylesheets/jbd-templates.css`
  - `javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, `vendor/jbdeditor/src/dialog.js`
  - `app/controllers/Pages.cfc`, `config/routes.cfm`, `app/views/layout.cfm`, `app/views/pages/index.cfm`
- **Key Deliverables & Engineering Solutions:**
  1. **Call to Action Studio Modernization:**
     - Established "Call to Action Studio" as a core component of the Pages section for managing cards, multi-action grids, and shortcodes.
     - Streamlined creation and edit modals by removing redundant Department/Workspace dropdowns, binding new cards directly to the active workspace resolved from the global header switcher.
  2. **Flexible Multi-Column Responsive Grid Layouts:**
     - **CSS Grid Architecture (`stylesheets/jbd-templates.css`):**
       - `4 Columns (4 Col Grid)`: `.cta-grid-4` (4 columns desktop `1fr 1fr 1fr 1fr`, 2 tablet at 1100px, 1 mobile at 640px).
       - `3 Columns (3x1 Reference)`: `.cta-grid-3` (3 columns desktop `1fr 1fr 1fr`, 2 tablet at 991px, 1 mobile at 640px).
       - `2 Columns (2x2 / 50-50 Split)`: `.cta-grid-2`, `.cta-grid-50-50` (2 columns 50/50 desktop `1fr 1fr`, 1 mobile at 640px).
     - **Shortcode Parser Enhancement (`app/global/functions.cfm`):**
       - Updated `renderCallToActionShortcodes()` to parse `cols`, `columns`, and `layout` shortcode attributes (e.g. `cols="4"`, `layout="4col"`, `cols="3"`, `layout="3x1"`, `cols="2"`, `layout="2x2"`, `layout="50/50"`).
       - Implemented automatic intelligent inference when column count is omitted: 2 items render as 50/50 split (`cta-grid-2 cta-grid-50-50`), 4 items render as 4-column (`cta-grid-4`), and others default to 3-column (`cta-grid-3`).
  3. **Studio Grid Builder Modal (`callToAction.cfm`):**
     - Added column layout selector with radio controls for `3 Columns (3x1 Reference)`, `4 Columns (4 Col Grid)`, and `2 Columns (2x2 / 50-50 Split)`.
     - Wired real-time synchronization in `updateGridBuilderOutput()` to update shortcode output and semantic HTML preview dynamically upon layout change.
  4. **Page Editor Embed Modal Integration (`pages/edit.cfm`):**
     - Added layout select dropdown (`3 Columns (3x1 Grid)`, `4 Columns (4 Col Grid)`, `2 Columns (2x2 / 50-50 Split)`) in `#embedCtaModal` footer.
     - Enhanced `btnEmbedGrid` and `btnInsertGridSc` handlers to embed selected HTML classes and append `cols="..."` to inserted shortcodes.
  5. **Interactive Media Library Picker Integration:**
     - Integrated County File Explorer modal with `postMessage` protocol into Call to Action Studio (`#btnBrowseCtaImage`), allowing direct asset selection and automatic population of image URLs and accessible alt text.
  6. **JBDEditor Block Templates:**
     - Added `cta-4col-grid` alongside `cta-reference-grid` and `cta-grid` in `javascripts/jbdeditor.js`, `javascripts/jbdeditor/dialog.js`, and `vendor/jbdeditor/src/dialog.js`.

  7. **Strict Workspace Isolation:**
     - Enforced strict workspace partitioning across `loadCallToActions()`, `loadCallToActionCategories()`, `getCallToActions()`, and `callToAction()` in `Pages.cfc`.
     - Filtered queries strictly by `cta.siteid = :ws` (unless global/all is explicitly requested).
     - Connected global header switcher listener (`cmsadmin:workspaceChanged`) in `callToAction.cfm` to immediately refresh and view the active workspace's CTAs.
  8. **JSON Body Parsing & Save Endpoint Hardening:**
     - Resolved save error `SyntaxError: Unexpected token '<'` by implementing `fxReadJsonBody()` in `saveCallToAction()`, `deleteCallToAction()`, and `reorderCallToActions()` in `app/controllers/Pages.cfc`.
     - Added hyphenated route patterns (`pages/save-call-to-action`, `pages/delete-call-to-action`, `pages/reorder-call-to-actions`) in `config/routes.cfm`.
     - Added safe response handling in `callToAction.cfm` to detect expired sessions or non-JSON payloads cleanly without throwing unhandled exceptions.
---

### Milestone 14: Clipboard Copy Hardening & Plain HTTP Compatibility (`callToAction.cfm` & `admin.js`)
- **Files Modified:**
  - `app/views/pages/callToAction.cfm`
  - `javascripts/admin.js`
- **Issue:**
  - "Copy to clipboard is not working": Clicking shortcode chips on CTA cards or clicking "Copy Shortcode" / "Copy HTML" in the Grid Builder modal failed silently or threw an uncaught error.
- **Root Cause & Engineering Solutions:**
  1. **Plain HTTP Incompatibility:** The application origin (`http://cmsadmin.chelancounty.gov`) operates over plain HTTP (`window.isSecureContext === false`). In modern Chromium browsers (Chrome & Edge), `navigator.clipboard` is restricted to secure contexts (`https://` or `localhost`) and evaluates to `undefined`, causing `navigator.clipboard.writeText(...)` to throw `TypeError: Cannot read properties of undefined (reading 'writeText')`.
  2. **Universal Dual-Mode Clipboard Helper (`copyTextToClipboard`):**
     - Implemented `copyTextToClipboard(text, successToastMsg, triggerBtn)` with dual fallback mechanisms in `callToAction.cfm`.
     - First attempts `window.copyToClipboard()` (from `admin.js`), which detects secure context availability and falls back to `document.execCommand('copy')`.
     - Directly implements an isolated `legacyExecCopy` textarea selection fallback so copying succeeds 100% reliably regardless of protocol or script load order.
  3. **Visual Feedback & Micro-Interactions:**
     - Added `.cta-shortcode-chip.btn-copied` green success animation and temporary state switch on clicked buttons.
     - Preserved accessible toast notifications using `window.showToast(..., "success")`.
  4. **Strict Invariant #2 Enforcement in `admin.js`:**
     - Removed legacy `window.prompt(...)` fallback from `javascripts/admin.js` in compliance with Chelan County Non-Negotiable Invariants.
  5. **CFML Output Hash Escaping (`callToAction.cfm`):**
     - Resolved `[coldfusion.util.RuntimeWrapper] 10b981 is not a valid identifier name` by escaping hex color hashes (`#10b981`, `#065f46`, `#d1fae5`) as double pound signs (`##10b981`, `##065f46`, `##d1fae5`) within the `<cfoutput>` block.

---

### Milestone 15: Media Library Inline Quick-Upload Beautification & Modernization
- **Files Modified:**
  - `app/views/media/index.cfm`
  - `app/views/media/picker.cfm`
  - `config/routes.cfm`
  - `stylesheets/filexplorer/explorer.css`
  - `javascripts/filexplorer/explorer.js`
- **Issue:**
  - The inline upload portion of the Media Library (`#upload-panel`) was visually outdated, utilizing raw browser default `<input type="file">` controls, crammed labels, and awkward spacing where destination path strings collided directly with the "Open Full Upload Studio" link.
  - Furthermore, clicking "Upload Now" previously failed because the client was calling `/media/processUpload`, but CFWheels routes only had `POST media/upload`, resulting in `Wheels.RouteNotFound: Incorrect HTTP Verb for route`.
- **Root Cause & Engineering Solutions:**
  1. **Upload Route & Endpoint Hardening (`config/routes.cfm` & `explorer.js`):**
     - Registered explicit route aliases in `config/routes.cfm` for `POST /media/processUpload` and `POST /media/process-upload` pointing to `media##processUpload`.
     - In `explorer.js`, targeted the canonical route `/media/upload?format=json` with automatic fallback to `/media/processUpload`.
     - Added resilient case-insensitive response parsing (`data.success || data.SUCCESS`, `data.file || data.FILE`) and session expiration redirect detection (`data.REDIRECT`).
     - Added `name="mediaFile"` to native `<input type="file">` controls in `index.cfm` and `picker.cfm`.
     - Reloaded CFWheels routing framework via `/?reload=true&password=chelancms`.
  2. **Modern Header & Path Segregation:**
     - Separated the destination folder into a dedicated pill badge with folder icon (`.fx-upload-dest-badge`), distinct from the "Full Upload Studio" external studio link.
     - Added quick close icon button (`btn-upload-close-icon`) and prominent "Quick Upload to Folder" title.
  3. **Interactive Drag & Drop Zone with Live Previews:**
     - Replaced the browser-default file selector with a modern dashed dropzone (`.fx-upload-dropzone`) that highlights on dragover (`is-dragover`).
     - Added instant image thumbnail preview via `FileReader` (or file type SVG badge for PDFs/documents), formatted file size (`fmtSize`), filename, and "Ready to upload" status badge.
     - Added a "Change / Remove" action button to swap or clear the selected file without breaking form state.
  4. **Editorial & ADA WCAG 2.1 AA Metadata Section:**
     - Styled a balanced 2-column grid for Alternative Text (`WCAG 1.1.1`) and Display Title.
     - Added an "ADA / WCAG AA" badge and clear explanatory helper hints to educate editors on accessibility requirements.
  5. **Progress Feedback & Loading State:**
     - Added SVG loading spinner and "Uploading..." state to `#btn-do-upload` during network submission.
     - Transformed `#upload-error` into a polished callout alert banner with error icon.
  6. **Asset Cache Busting:**
     - Bumped `explorer.css` and `explorer.js` cache-buster query strings to `v=3.1` across `index.cfm` and `picker.cfm`.
- **Verification:** Verified syntax with `node -c`, tested `POST /media/upload` and `POST /media/processUpload` endpoints with curl returning HTTP 200/401 JSON envelopes instead of 404 RouteNotFound errors.

---

### Milestone 16: Media Upload Controller — ColdFusion Undefined `local.width` Variable Resolution
- **Files Modified:**
  - `app/controllers/Media.cfc`
- **Issue:**
  - When submitting the upload form, ColdFusion threw: `Upload failed: Element WIDTH is undefined in LOCAL.`
- **Root Cause & Technical Resolution:**
  1. **ColdFusion 2025 Null Variable Unsetting:**
     - In Adobe ColdFusion 2025, assigning `local.width = javaCast("null", "")` de-registers the key from the `local` scope entirely.
     - When uploading non-image documents (e.g. PDFs, Word documents) or when `ImageRead()` was bypassed, referencing `local.width` and `local.height` in `queryExecute()` struct parameters or evaluation statements triggered an unhandled runtime exception: `Element WIDTH is undefined in LOCAL`.
  2. **Safe Value Initialization & Query Parameter Normalization (`Media.cfc`):**
     - Updated `processUpload()` (lines 360–370 and 420–425) and `syncDiskAssetsToDatabase()` (lines 670–680 and 708–712) to initialize `local.width = ""` and `local.height = ""`.
     - Normalized `queryExecute()` parameters for `width` and `height` to safely check numeric values and insert SQL NULL cleanly:
       ```cfc
       width: { value: Val(local.width) > 0 ? Val(local.width) : JavaCast("null", ""), cfsqltype: "cf_sql_integer", null: (Val(local.width) <= 0) },
       height: { value: Val(local.height) > 0 ? Val(local.height) : JavaCast("null", ""), cfsqltype: "cf_sql_integer", null: (Val(local.height) <= 0) }
       ```
- **Verification:** Verified syntax and variable initialization in `app/controllers/Media.cfc`, confirmed zero exceptions logged in `wheels-errors.log` and `exception.log`.

---

### Milestone 17: Media Library Re-alignment to Chelan County CMSAdmin 2.0 Institutional Design System
- **Files Modified:**
  - `app/views/media/index.cfm`
  - `app/views/media/picker.cfm`
  - `app/views/media/upload.cfm`
  - `stylesheets/filexplorer/explorer.css`
  - `javascripts/filexplorer/explorer.js`
- **Issue:**
  - The previous inline quick-upload modernization introduced non-standard custom widgets (such as a dashed drag-and-drop cloud card, custom dropzone styles, and dark badges) that deviated from the established Chelan County CMSAdmin 2.0 design system.
  - Additionally, the page header in `media/index.cfm` and `media/upload.cfm` used legacy `content-header` structures with inverted breadcrumb hierarchy.
- **Root Cause & Technical Resolution:**
  1. **Canonical Design System Re-Alignment:**
     - Aligned Media Library views directly to the institutional pattern demonstrated in modules like `rfps/edit.cfm` (`Post Solicitation Announcement` / `Announcement Information`).
  2. **Page Header Normalization (`.page-header`):**
     - Replaced legacy `.content-header` in `media/index.cfm` and `media/upload.cfm` with the canonical `.page-header` layout:
       - Page title on top (`.page-title`).
       - Breadcrumb beneath (`.breadcrumb` with `.breadcrumb-item` and SVG dashboard icon: `Home / Media Library`).
       - Action buttons on the right (`.btn .btn-primary .btn-sm` with SVG icon).
  3. **Institutional Quick-Upload Card Design (`#upload-panel`):**
     - Replaced the foreign dropzone widget with a clean, standard `.admin-card` section matching the `Announcement Information` card design.
     - Form controls use standard `.form-label` (`font-weight: 600` with `<span style="color:var(--admin-danger);">*</span>` required indicators) and `.form-control` inputs.
     - Preserved clean 2-column layout for Alternative Text (WCAG 1.1.1) and Display Title.
     - Kept full functionality: auto-title generation from filename, dynamic alt text placeholder hints, SVG loading indicators, and error banners.
  4. **CSS Streamlining (`explorer.css`):**
     - Stripped over 350 lines of redundant `.fx-upload-*` dropzone CSS, allowing the global `admin-theme.css` to govern inputs, labels, cards, and buttons consistently.
  5. **Cache-Busting:**
     - Bumped `explorer.css` and `explorer.js` cache-buster query strings to `v=3.2` across `index.cfm` and `picker.cfm`.
- **Verification:** Verified syntax with `node -c`, confirmed zero template compilation errors, and verified all inputs and headers match `admin-theme.css`.

---

### Milestone 18: Relocation of Startup & Front-End (.css) into Documentation Group
- **Files Modified:**
  - `app/views/layout.cfm`
  - `app/controllers/Documentation.cfc`
  - `app/controllers/Settings.cfc`
  - `config/routes.cfm`
  - `app/views/documentation/startup.cfm`
  - `app/views/documentation/index.cfm`
  - `app/views/settings/startup.cfm`
  - `app/views/settings/general.cfm`
  - `app/views/settings/media.cfm`
  - `app/views/settings/seo.cfm`
  - `app/views/settings/system.cfm`
- **Scope & Changes:**
  1. **Documentation Controller & Action (`Documentation.cfc`):**
     - Added `startup()` action reading `/stylesheets/jbd-templates.css` and setting `pageTitle`.
     - In `Settings.cfc`, updated `startup()` to redirect to `documentation##startup` for backward compatibility.
  2. **Route Definitions (`config/routes.cfm`):**
     - Registered `documentationStartup` (`documentation/startup`) and `documentationFrontEndCss` (`documentation/front-end-css`).
  3. **Sidebar Navigation Realignment (`app/views/layout.cfm`):**
     - Moved `Startup & Front-End (.css)` into the **Documentation** sidebar navigation submenu.
     - Removed `Startup & Front-End (.css)` from the **Settings** sidebar navigation submenu.
     - Updated menu state detection so the Documentation group expands when viewing the startup guide.
  4. **Documentation Hub Integration (`documentation/index.cfm` & `documentation/startup.cfm`):**
     - Created `app/views/documentation/startup.cfm` with standardized `.page-header` and breadcrumb navigation (`Home / Documentation / Startup & Front-End (.css)`).
     - Added a 5th guide card in `documentation/index.cfm` linking directly to the Front-End Template Integration Guide and raw `.css` download.
  5. **Settings Overview Sidebars:**
     - Updated navigation cards in `general.cfm`, `media.cfm`, `seo.cfm`, and `system.cfm` to route to `documentation##startup`.
- **Verification:** Reloaded CFWheels (`/?reload=true&password=chelancms`), verified `/documentation/startup` responds cleanly, and verified zero runtime errors in `wheels-errors.log`.

---

### Milestone 19: Intelligent Document Converter Engine (PDF & Word to WCAG 2.1 AA HTML)
- **Files Created / Modified:**
  - `app/models/DocumentConverter.cfc`
  - `app/controllers/Pages.cfc`
  - `app/controllers/Articles.cfc`
  - `app/views/pages/edit.cfm`
  - `app/views/articles/edit.cfm`
  - `config/routes.cfm`
  - `.doclib/012_DOCUMENT_CONVERTER_WCAG_AA.md`
- **Scope & Changes:**
  1. **Core Document Conversion Model (`DocumentConverter.cfc`):**
     - Built native Adobe ColdFusion 2025 document conversion pipeline converting both `.docx` (via `<cfzip>` XML extraction) and `.pdf` (via `<cfpdf>` text and raster image extraction) into pure semantic WCAG 2.1 AA HTML.
     - **Strict Styling Invariant:** Zero classes, zero inline styles emitted in the HTML output. Output consists strictly of semantic elements (`<h2>`, `<h3>`, `<p>`, `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th scope="col">`, `<td>`, `<ol>`, `<ul>`, `<li>`, `<blockquote>`, `<strong>`, `<em>`, `<a>`, `<figure>`, `<figcaption>`).
     - **Intelligent PDF Heuristic Reflow:** Implemented `cleanAndStitchPdfPages()` to scrub running headers/footers, heal split hyphens, heal URLs/paths, and normalize punctuation spacing.
     - **Multi-Table Reconstruction:** Implemented `parseAllPdfTables()` to dynamically reconstruct complex 2-column, 3-column, and 5-column tabular data into fully accessible `<table>` markup with semantic `<thead>` and `<th scope="col">` column headers.
     - **Dynamic Section Heading Detection:** Implemented `tagPdfHeadings()` replacing static string lists with a universal catalog and structural section markers (`Section \d+`, `\d+\.\d+`), downshifting hierarchy to start at `<h2>`.
     - **Sentence & List Reflow:** Implemented `reflowSentencesIntoParagraphs()` to reflow monolithic PDF text blocks into well-proportioned `<p>` tags (2-3 sentences), auto-extract numbered lists (`<ol><li>`), highlight lead-in callouts (`<strong>Note:</strong>`), and auto-linkify raw URLs and email addresses.
     - **Word (.docx) Enhancements:** Added heuristic to recognize standalone unstyled bold lines as headings, downshifting Word Heading 1 -> `<h2>`, Heading 2 -> `<h3>`.
  2. **Page & Article Editor Studio Integration (`pages/edit.cfm`, `articles/edit.cfm`):**
     - Added toolbar buttons (`#btnEditorImportDoc`, `#btnArticleImportDoc`) and animated frosted drag-and-drop overlays.
     - Created full-featured modal dialogs (`#pgDocConvertModal`, `#articleDocConvertModal`) with real-time visual and HTML code previews, insertion modes (Replace, Insert at cursor, Append), and Title/Summary auto-sync.
     - Integrated real-time accessibility auditing via `PageA11yLinter.scan()` and `ArticleA11yLinter.scan()` immediately upon insertion.
  3. **Benchmark Verification:**
     - `CMSAdmin 2.0 Documentation.pdf` (931 KB): 19 Headings (was 0), 57 Paragraphs, 7 Semantic Tables (was 0), 4 Lists, 3,729 words in ~685 ms.
     - `CMSAdmin 2.0 User Guide.pdf` (489 KB): 10 Headings, 120 Paragraphs, 2 Tables, 16 Lists, 3,813 words in ~546 ms.
   4. **Automated End-to-End Test Suite Execution (`run_full_test_suite.cfm`):**
      - Created automated test harness executing 54 assertions across 5 suites:
        - **Suite 1:** Complex 17-page `CMSAdmin 2.0 Documentation.pdf` architecture manual (19 headings, 7 tables, 57 paragraphs, 4 lists, 3,729 words in 340ms; 0 classes, 0 inline styles; WCAG 1.3.1 compliance).
        - **Suite 2:** 14-page `CMSAdmin 2.0 User Guide.pdf` end-user guide (10 headings, 2 tables, 16 lists, 120 paragraphs, 3,813 words in 341ms; 0 classes, 0 inline styles; table headers with `scope="col"`).
        - **Suite 3:** Synthetic `.docx` OpenXML package (Heading 1 downshift to `<h2>`, Heading 2 to `<h3>`, unstyled bold heuristic to `<h2>`, nested bullet lists, tables with `<thead><th scope="col">`, clean hyperlinks).
        - **Suite 4:** HTTP controller endpoints (`POST /pages/convert-document` and `POST /articles/convert-document`) with session authentication, cookie handling, and `Content-Type: application/json;charset=utf-8` response verification.
        - **Suite 5:** Security and unsupported file rejection (`.cfm` script rejection with security warning).
      - **Result:** **54 / 54 tests PASSED (100.0% Green)** on Adobe ColdFusion 2025 / IIS 10.
- **Verification:** Verified via live `curl` against IIS on `cmsadmin.chelancounty.gov`, verified zero external CDNs, verified no browser dialog popups.

---

### Milestone 19: Media Library Upload UI Redesign & Upload Spinner Display Isolation
- **Files Modified:**
  - `app/views/media/index.cfm`
  - `app/views/media/picker.cfm`
  - `app/views/media/upload.cfm`
  - `stylesheets/filexplorer/explorer.css`
  - `stylesheets/admin-theme.css`
  - `app/views/layout.cfm`
  - `javascripts/filexplorer/explorer.js`
- **Issue:**
  1. The user requested redesigning the Media Library upload dropzone to match the modern featured image dropzone specification (dashed blue border, centered blue image icon, bold title "Choose Cover Image / File", helper subtext, and an "Image URL" input row directly below with a `[Browse]` button and `[Upload Now]` action).
  2. The user reported that an unwanted spinning icon was continuously visible next to the "Upload Now" button in its idle state.
- **Root Cause & Technical Resolution:**
  1. **Upload Dropzone & URL Input Row Design (`index.cfm`, `picker.cfm`, `upload.cfm`, `explorer.css`, `admin-theme.css`):**
     - Redesigned the upload container with `.media-upload-dropzone`: 2px dashed `#0284c7` border, rounded 12px corners, `#f8fafc` background, `#svgIcon(name="image", size=36)#`, and accessible click/drag-and-drop triggers.
     - Positioned the `.media-url-browse-row` immediately underneath the dropzone featuring the prospective URL input (`#upload-target-url-input`), the `[Browse]` button (`#btn-browse-file`), and the primary submit button (`#btn-do-upload`).
     - Added `.media-selected-card` file selection badge with live image thumbnail, file size, format metadata, and "Change" action.
  2. **Upload Button Spinner Isolation & Specificity Resolution:**
     - **Root Cause:** In the button markup, `<svg id="btn-do-upload-spinner" class="fx-spinner" viewBox="0 0 24 24" hidden>` had the HTML `hidden` attribute. However, CSS flex container styling on the button and CSS rules for `.btn svg` had higher specificity than user-agent `[hidden]`, causing the SVG to render as a visible flex child. Furthermore, the inline `style` attribute had width/height dimensions but lacked `display: none !important;`. Because `.fx-spinner` runs `animation: fx-spin 0.8s linear infinite;`, the spinner was visibly rotating alongside the static upload arrow icon while idle.
     - **Resolution:**
       - Added explicit `style="display:none !important;"` directly on the `<svg id="btn-do-upload-spinner">` markup in `media/index.cfm` and `media/picker.cfm`.
       - Added explicit global specificity overrides in both `stylesheets/filexplorer/explorer.css` and `stylesheets/admin-theme.css`:
         ```css
         [hidden],
         #btn-do-upload-spinner[hidden],
         .fx-spinner[hidden],
         svg[hidden] {
           display: none !important;
         }
         ```
       - Updated `javascripts/filexplorer/explorer.js` in `boot()`, `resetFileSelection()`, and upload request handling to strictly toggle `style.setProperty('display', 'none', 'important')` and `style.setProperty('display', 'inline-block', 'important')`, ensuring the spinner is only displayed during active network upload streams.
     - Bumped cachebuster parameters to `admin-theme.css?v=4.1`, `explorer.css?v=4.1`, and `explorer.js?v=4.1` across `layout.cfm`, `index.cfm`, and `picker.cfm`.
- **Verification:**
  - Automated test script `scratch/test_media_ui.ps1` verified that all endpoints (`/media/index`, `/media/upload`, `/media/picker`) return HTTP 200 OK with session authentication, proper dropzone rendering, prospective URL row, and guaranteed hidden spinner display in idle state.

---

### Milestone 20: Workspace Provisioning Schema Extension & Location/Schedule Panel Unification
- **Files Modified:**
  - `app/controllers/Workspaces.cfc`
  - `app/views/workspaces/new.cfm`
  - `app/views/workspaces/edit.cfm`
  - `app/views/workspaces/index.cfm`
  - `app/global/functions.cfm`
  - `.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md`
  - `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`
- **User Requirements:**
  1. "on create workspace, we need to add stoarage path, domain name, project path"
  2. "on create workspace, merge physical location and address with Operating Hours and Schedule"
- **Technical Implementation:**
  1. **SQL Server Database Migration (`dbo.cms_workspaces`):**
     - Executed `ALTER TABLE dbo.cms_workspaces` with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` adding:
       - `storage_path NVARCHAR(255) NULL` (dedicated file repository path, e.g. `files/assessor`)
       - `domain_name NVARCHAR(255) NULL` (canonical web hostname, e.g. `www.chelancounty.gov`)
       - `project_path NVARCHAR(255) NULL` (server application codebase directory, e.g. `C:\inetpub\chelan-county`)
     - Backfilled existing workspaces (`global`, `assessor`, etc.) with default values.
  2. **Global Helper Functions (`app/global/functions.cfm`):**
     - Updated `ensureMasterWorkspacesTablePopulated()` to include default `storage_path`, `domain_name`, and `project_path` upon database initialization.
     - Updated `getMasterWorkspaces()` SQL query to select and map `storage_path`, `domain_name`, and `project_path` into workspace structs with in-memory caching.
  3. **Workspaces Controller (`app/controllers/Workspaces.cfc`):**
     - `index()`: Updated disk path verification to check `local.w.storage_path` (supporting both relative paths and absolute drive paths), and extended search filter haystack across `domain_name`, `storage_path`, and `project_path`.
     - `new()`: Populated defaults for `storage_path` (`""`), `domain_name` (`"www.chelancounty.gov"`), and `project_path` (`"C:\inetpub\chelan-county"`).
     - `create()`: Extracted and sanitized `domain_name`, `storage_path`, and `project_path`; updated directory auto-creation to respect `local.storagePath`; added typed query parameters to both `INSERT` and `UPDATE` SQL queries.
     - `edit()`: Selected and populated `storage_path`, `domain_name`, and `project_path` into `variables.workspace`.
     - `update()`: Extracted parameters, updated directory provisioning on disk, and persisted all fields to `dbo.cms_workspaces`.
  4. **Creation & Edit Views (`workspaces/new.cfm`, `workspaces/edit.cfm`):**
     - **Panel 1 (Site & Directory Configuration):** Added inputs for `domain_name`, `storage_path`, and `project_path` alongside `virtual_directory` in clean 2-column grids with informative helper subtext. Added live auto-suggest synchronization in `new.cfm` so typing Site Name suggests both virtual directory slug and default storage path (`files/[slug]`).
     - **Unified Location & Hours Panel (Merged Panel 3 & 4):** Merged the previously separate "Physical Location & Address" and "Operating Hours & Schedule" into a single full-width 12-column card (`.ws-location-hours-grid`) containing:
       - Left column: Facility Physical Address (Street Address, Address 2, City, State, Zip).
       - Right column: Operating Hours & Schedule textarea and helper note.
       - Card footer: Full action buttons (`[Cancel]` and `[Create Workspace]` / `[Save Workspace Changes]`).
  5. **Directory View (`workspaces/index.cfm`):**
     - Updated expandable detail drawers to display **Domain Name**, **Storage Path**, and **Project Path** alongside IIS virtual directory mappings.
- **Verification:**
  - Automated PowerShell test scripts verified end-to-end functionality against live IIS server (`cmsadmin.chelancounty.gov`):
    - Authenticated `GET /workspaces/new` verified presence of all new inputs and merged 12-column panel.
    - Authenticated `GET /workspaces/edit?id=assessor` verified accurate pre-population of fields.
    - Authenticated `POST /workspaces/create` successfully provisioned `test-auto-dept` with custom storage path, domain name, and project path verified directly in SQL Server.
    - Authenticated `POST /workspaces/update` confirmed persistence of modifications.
    - Authenticated deletion and cleanup verified soft delete and removed temporary test entries.

### 2026-10-18: Navigation & Page Directory Renamed to "Content Manager"
- **Task Overview:** Renamed the primary "All Pages" menu item under the Content Management group to "Content Manager", aligning UI terminology across controllers, views, breadcrumbs, action buttons, and loading states.
- **Architectural & View Updates:**
  1. **Sidebar Navigation (`app/views/layout.cfm`):** Updated primary submenu anchor text from `All Pages` to `Content Manager` under Content Management > Pages accordion.
  2. **Pages Controller (`app/controllers/Pages.cfc`):** Updated `variables.pageTitle = "Content Manager";` and method doc comments.
  3. **Pages Directory View (`app/views/pages/index.cfm`):** Updated `<cfset pageTitle = "Content Manager">`, header `<h1 class="page-title">Content Manager</h1>`, and breadcrumb active item.
  4. **Page Editor & CTA Studio (`app/views/pages/edit.cfm`, `app/views/pages/callToAction.cfm`):** Updated header back action buttons to `<span>Content Manager</span>`.
  5. **Dashboard Quick Links (`app/views/main/index.cfm`):** Updated workspace pages card tools (`View in Content Manager` / `Content Manager`), card footer (`Manage in Content Manager`), and quick-launch grid link.
  6. **Admin Shell & Loaders (`javascripts/admin.js`):** Updated animated transition overlay title to `"Loading Content Manager..."`.
  7. **Role Capability Matrix (`app/controllers/Users.cfc`):** Updated permissions feature description to `"Content Manager & Page Editor"`.
- **Verification:**
  - Verified ColdFusion compilation and HTTP routing via IIS (`cmsadmin.chelancounty.gov`).

### 2026-10-18: Dashboard Panel Headers Typography Standardization & Compact Header Buttons
- **Task Overview:** Aligned the typography of all dashboard panel headers (`.dashboard-grid .card-title`) with the uppercase tracked stat label design (`.stat-label`, e.g., "FORM SUBMISSIONS") and standardized header buttons across panel tools and page actions to sleek, compact dimensions.
- **Architectural & View Updates:**
  1. **Theme Stylesheet (`stylesheets/admin-theme.css`):**
     - Added rule targeting `.dashboard-grid .card-header .card-title` and `.dashboard-grid .card-title` applying `font-family: var(--admin-font)`, `font-size: 0.825rem`, `font-weight: 600`, `text-transform: uppercase`, `letter-spacing: 0.04em`, and `color: var(--admin-text-muted)`.
     - Standardized nested SVG icons in dashboard headers with matching muted color and `flex-shrink: 0`.
     - Standardized `.card-header .card-tools .btn`, `.card-header .btn` to compact sizing (`font-size: 0.75rem`, `padding: 0.22rem 0.55rem`, 12px SVG icons).
     - Standardized `.page-actions .btn.btn-sm` and `.page-header .page-actions .btn` to streamlined compact sizing (`font-size: 0.785rem`, `padding: 0.28rem 0.65rem`, 13px SVG icons).
     - Added reusable `.btn-xs` utility and balanced `.dashboard-grid .card-header` vertical padding to `0.85rem 1.25rem`.
  2. **Cache-Buster Bump (`app/views/layout.cfm`):**
     - Incremented stylesheet cache query parameter to `?v=4.3` to ensure immediate browser rendering.
- **Verification:**
  - Verified HTTP 200 delivery of `admin-theme.css?v=4.3` on local IIS host.

### 2026-10-18: Front-End Domain Integration, Layout Streamlining & Modal Title Typography
- **Task Overview:**
  1. Removed redundant "View in Content Manager" button from the Recent Workspace Pages panel header (retaining primary "+ Add Page" in header and "Manage in Content Manager" in card footer).
  2. Updated "View Portal" (and global/page "View Live Site" / "View Live") to dynamically resolve and use each workspace's configured front-end `domain_name` (e.g. `https://www.chelancounty.gov/assessor` or dedicated domain).
  3. Standardized modal titles (`.admin-modal-title`, `.modal-title`, `.ev-modal-title`, `.hdi-modal-title`, `.fb-modal-title`) to the same uppercase tracked brand typography (`font-weight: 700`, `letter-spacing: 0.04em`, `text-transform: uppercase`) sized 2 notches larger (`1.05rem`).
- **Architectural & View Updates:**
  1. **Dashboard View (`app/views/main/index.cfm`):**
     - Dynamic resolution of `local.frontEndDomain` and `local.portalUrl` from `variables.activeWsObj.domain_name` and `virtual_directory`.
     - Removed redundant `View in Content Manager` button from `.card-tools`.
  2. **Page Editor & Shell Layout (`app/views/pages/edit.cfm`, `app/views/layout.cfm`):**
     - Updated live preview links to point directly to public domain hostname.
  3. **Theme Stylesheet (`stylesheets/admin-theme.css`, `app/views/pages/index.cfm`):**
     - Styled modal titles with uppercase tracking at `1.05rem`.
     - Bumped stylesheet cache version to `?v=4.4`.
- **Verification:**
  - Verified ColdFusion compilation and HTTP 200 delivery of `admin-theme.css?v=4.4`.

### 2026-10-18: Site-Wide Panel Header Typography Standardization
- **Task Overview:** Expanded the uppercase tracked stat label font styling (`font-size: 0.825rem`, `font-weight: 600`, `text-transform: uppercase`, `letter-spacing: 0.04em`, `color: var(--admin-text-muted)`) site-wide across all `.card-header .card-title`, `.card-title`, `.panel-title`, and `.fb-panel-title` elements.
- **Architectural & View Updates:**
  1. **Global Theme Stylesheet (`stylesheets/admin-theme.css`):**
     - Promoted `.card-header .card-title` and `.card-title` definition to site-wide scope with standard `padding: 0.85rem 1.25rem` for `.card-header`.
     - Standardized matching SVG icon color and sizing across all card and panel headers.
     - Bumped stylesheet cache version to `?v=4.5`.
  2. **Page Editor View (`app/views/pages/edit.cfm`):**
     - Refactored `pgCoverImagePanel` ("Featured Cover Image") to use standard `.card-header` and `.card-title` markup with nested `.card-body`, matching the rest of the editor panels ("Publish", "Search & Sharing", "Page Attributes").
- **Verification:**
  - Verified ColdFusion compilation and HTTP 200 delivery of `admin-theme.css?v=4.5`.












### 2026-10-18: Edit Page v2 Separate Mockup Branch (Consolidated Left Panel, Feature Accordions & LED Markers)
- **Task Overview:**
  - Implemented an alternate **v2 Mockup of Edit Page** featuring a unified left panel and an interactive right-hand Page Features Accordion deck with glowing LED light markers.
  - Per the user's explicit directive (*"do not make any changes to main, this is a separate mockup"* and *"try accordion in exchange of modal"*), the main production files (`edit.cfm` and `index.cfm`) were kept completely untouched and pristine. The v2 mockup is completely segregated in `app/views/pages/editV2.cfm` and accessed via dedicated route `/pages/edit-v2`.
- **Architectural & View Updates:**
  1. **Main Branch Isolation:**
     - `app/views/pages/edit.cfm` and `app/views/pages/index.cfm` restored to 100% byte-for-byte fidelity with origin/main.
     - V2 experimentation is strictly confined to `app/views/pages/editV2.cfm` and `app/controllers/Pages.cfc::editV2()`.
  2. **Routing & Controller (`config/routes.cfm`, `app/controllers/Pages.cfc`):**
     - Registered `/pages/edit-v2` (`pagesEditV2`) and `/pages/editV2` routes in `config/routes.cfm`.
     - Added `editV2()` method in `Pages.cfc` establishing `variables.isV2Branch = true` and invoking `renderView(template="editV2")`.
  3. **Edit Page v2 View (`app/views/pages/editV2.cfm`):**
     - **Left Panel (Core Authoring in ONE Panel):** Page Title, Page URL (with prefix and clipboard copy), Page Layout (interactive visual cards for Full Width vs. Right Sidebar), Page Content (JBDEditor, quick embeds for Word/PDF, CTA, Online Forms, and ADA Pre-Flight Linter Bar), and Search & Social Sharing (Browser Title with 0/65 counter, Meta Description with 0/160 counter, and Auto-Generate from content) all in a single consolidated card.
     - **Right Panel (Page Features Accordion Deck):**
       - Replaced popup modals with a smooth, collapsible Accordion deck (`.pg-features-accordion`).
       - Features included: Cover Image, Navigation & Menu, Sidebar & Subpages, Folder Explorer, Publishing & Schedule, ADA Pre-Flight Audit, CTA Blocks, Online Forms, and RCW 42.56 Revision History.
       - Quick "Expand All" and "Collapse All" controls.
       - **LED Light Markers:** Dynamic glowing emerald/green pulses (`.led-marker.is-active`) for features with active content, glowing amber (`.led-marker.is-warn`) for warnings/attention (e.g. missing ADA alt text or unassigned sidebars), and subtle muted gray (`.led-marker.is-inactive`) for empty/unused features.
       - Real-time client-side synchronization: LED markers and subtitles update dynamically as fields change or content is typed.
- **Verification:**
  - Tested authenticated HTTP 200 delivery of `/pages/edit-v2?id=1` (475KB), verifying presence of `.pg-v2-grid`, `.pg-features-accordion`, and dynamic `.led-marker` elements.
  - Tested authenticated HTTP 200 delivery of main `/pages/edit?id=1` and `/pages` verifying 100% undisturbed production behavior.


  4. **Restoration of Editor Toolbar Actions (Per User Request):**
     - Moved in-content embedding tools and version history directly onto the Page Content label bar above `#pgContent`:
       - `Import Word / PDF` (`#btnEditorImportDoc`) launching the WCAG AA HTML document converter modal.
       - `Embed Call to Action` (`#btnEditorInsertCTA`) launching the multi-card grid & CTA embed modal.
       - `Embed Form` (`#btnEditorInsertForm`) launching the online form selector & shortcode modal.
       - `Revisions` (`#btnEditorOpenRevisions` with snapshot version badge) launching the RCW 42.56 Diff & Rollback Studio.
     - Removed CTA Blocks, Online Forms Embed, and Revision History from the right-hand accordion deck so the accordion focuses cleanly on 6 core page configuration features (Cover Image, Navigation, Sidebars & Subpages, Folder Explorer, Publishing & Schedule, ADA Pre-Flight Audit).
     - Updated real-time LED marker synchronizer badge to track the 6 core features (`0 / 6 Active`).

  5. **Revision Link Consolidated into Publish Status Panel (Per User Request):**
     - Removed `Revisions` button from the content editor toolbar above `#pgContent`, keeping the editor action bar focused solely on content creation (`Import Word / PDF`, `Embed Call to Action`, and `Embed Form`).
     - In the **Publish Status** panel on the right, balanced the primary button row to `View Live` (flex 1) and `Cancel` (flex 1).
     - Transformed the `Revision:` metadata row into an interactive, clickable link/badge (`v30 (30 records)` with a history icon) that opens the RCW 42.56 Diff & Rollback Studio modal window (`openRevisionsModal()`).

  5. **Revision Link Consolidated into Publish Status Panel (Per User Request):**
     - Removed `Revisions` button from the content editor toolbar above `#pgContent`, keeping the editor action bar focused solely on content creation (`Import Word / PDF`, `Embed Call to Action`, and `Embed Form`).
     - In the **Publish Status** panel on the right, balanced the primary button row to `View Live` (flex 1) and `Cancel` (flex 1).
     - Transformed the `Revision:` metadata row into an interactive, clickable link/badge (`v30 (30 records)` with a history icon) that opens the RCW 42.56 Diff & Rollback Studio modal window (`openRevisionsModal()`).


  6. **Revision Note Relocated to Publish Status Panel:**
     - Moved the `Revision Note` input (`#pgChangeSummary`) out of the Publishing & Schedule accordion item and placed it directly inside the primary **Publish Status** card right above the **Save Changes** button.
     - Authors can now immediately enter a revision note (RCW 42.56 compliance audit log) when saving without needing to open or navigate any accordion deck items.


### Milestone 21: Official Promotion & Overwrite of Edit Page v2 to Production (`edit.cfm`)
- **User Directive:** "implement v2 overwrite granted"
- **Architectural & View Implementation:**
  1. **Production View Promotion (`app/views/pages/edit.cfm`):**
     - Overwrote classic `edit.cfm` with the perfected v2 architecture:
       - **Consolidated Left Panel:** Page Title, Page URL permalink with copy helper, Page Layout interactive cards (Full Width vs. Right Sidebar), Page Content (JBDEditor with dropzone and automated ADA Pre-Flight linter), and Search & Social Sharing (Browser Title + Meta Description counters) in a single unified flow.
       - **Editor Action Bar:** Clean in-content embedding tools (`Import Word / PDF`, `Embed Call to Action`, and `Embed Form`) directly above `#pgContent`.
       - **Publish Status Card:** Dedicated `Revision Note` (`#pgChangeSummary`) input placed directly above the `Save Changes` button for immediate compliance journaling; `View Live` and `Cancel` balanced action row; and interactive `Revision: vX (N records)` link launching the RCW 42.56 Diff & Rollback Studio modal.
       - **6-Feature Accordion Deck:** Streamlined to the 6 core page configuration features (Cover Image, Navigation & Menu, Sidebar & Subpages, Folder Explorer, Publishing & Schedule, ADA Pre-Flight Audit) with live pulsing LED status markers (green for active, amber for warnings, gray for inactive).
     - Stripped temporary mockup banners and "v2 Branch" badges, establishing standard production headers and breadcrumbs.
  2. **Controller & Route Compatibility (`app/controllers/Pages.cfc`, `config/routes.cfm`):**
     - `Pages.cfc::edit()` naturally serves the newly promoted production `edit.cfm`.
     - `Pages.cfc::editV2()` maintained as an alias rendering `edit.cfm` to ensure backward compatibility for bookmarked URLs.
- **Verification:**
  - Automated PowerShell test scripts against live IIS server (`cmsadmin.chelancounty.gov`) verified:
    - `GET /pages/edit?id=23` returned HTTP 200 OK (472KB) with full v2 layout, accordion deck, and LED markers.
    - `POST /pages/save` verified successful persistence and revision recording with `changeSummary`.
    - `GET /pages/revisions?pageId=23` verified RCW 42.56 snapshots API functionality.

---

### Milestone 22: Edit Page v2 Bug Fixes: Cover Image Browse, Menu Visibility, Layout Toggling & Folder Explorer LED
- **User Directives:**
  1. *Featured Cover Image:* "browse is disabled"
  2. *Navigation on Menu:* "i selected top level but the menu item remained visible"
  3. *Sidebar & Subpages:* "switch to full and switch to right tottle is not working properly"
  4. *Folder Explorer:* "light remained green even if not selected a folder"
- **Root Cause & Technical Resolution:**
  1. **Featured Cover Image Browse Button (`edit.cfm`, `editV2.cfm`, `_pageEditorScripts.cfm`):**
     - In `edit.cfm` and `editV2.cfm`, the Browse button lacked `id="btnBrowseFeaturedImg"`, preventing `document.getElementById('btnBrowseFeaturedImg')` from resolving in `openMediaPickerForPageCover` and `removeFeaturedImage`.
     - Standardized button classes to `btn btn-secondary btn-xs` with explicit styling (`display:inline-flex; align-items:center; gap:0.3rem; cursor:pointer; font-weight:600;`) ensuring active, clickable appearance.
     - Added callback `window.updatePageFeaturesLedStatus()` upon media picker image selection to ensure instant LED synchronization.
  2. **Navigation on Menu Visibility (`edit.cfm`, `editV2.cfm`, `_pageEditorScripts.cfm`):**
     - `updateMenuAssignmentVisibility()` was previously defined as a private local function scoped inside an IIFE in `_pageEditorScripts.cfm`, causing an unhandled `ReferenceError: updateMenuAssignmentVisibility is not defined` when `#pgParent` triggered its inline `onchange` handler.
     - Globally exposed `window.updateMenuAssignmentVisibility` on `window` and ensured `#pgMenuAssignmentWrap` properly toggles display and hidden attribute when "Top Level - Called from URL" vs "Assign to Main Menu Item" is selected.
     - Ensured `#pgParent` and `#pgMenuItemSelect` both trigger `window.updatePageFeaturesLedStatus()`.
  3. **Sidebar & Subpages Layout Toggler (`edit.cfm`, `editV2.cfm`, `_pageEditorScripts.cfm`):**
     - `updateSidebarAvailability()` in `_pageEditorScripts.cfm` crashed with a `TypeError` when reading `sidebarPanel.hidden` because `#pgSidebarLayoutOptions` was missing in v2, halting `selectLayoutV2()` before card classes and LED state could update.
     - Added safe null-coalescing and checks for `sidebarPanel` (`document.getElementById("pgSidebarLayoutOptions") || document.getElementById("pgSidebarChooser")`) and `sidebarHelp`.
     - Updated `selectLayoutV2()` and the inline `#btnSwitchToSidebarLayout` button inside Accordion Item 3 to dynamically toggle between "Switch to Full Width" and "Switch to Right Sidebar", synchronizing the left wireframe cards, notice text, subpage chooser opacity, and LED indicator.
  4. **Folder Explorer LED Status Indicator (`edit.cfm`, `editV2.cfm`):**
     - Previously, checking "Enable Folder Explorer on this page" unconditionally activated the green LED (`is-active`), even when zero folders were checked (`checkedFolders.length === 0`).
     - Refactored `updatePageFeaturesLedStatus()`:
       - When enabled AND `checkedFolders.length > 0`: Green LED (`is-active`), counts toward active features, summary displays `N folder(s) selected`.
       - When enabled BUT `checkedFolders.length === 0`: Amber warning LED (`is-warn`), does not register as active, summary displays `Folder explorer enabled (0 folders selected)`.
       - When unchecked: Inactive gray LED (`is-inactive`), summary displays `Disabled`.
- **Verification:**
  - Authenticated test request to `http://cmsadmin.chelancounty.gov/pages/edit?id=23` verified HTTP 200 (368KB).
  - Node.js syntax parsing confirmed zero syntax errors across all embedded JavaScript blocks.
  - Verified `edit.cfm` and `editV2.cfm` remain 100% in sync.

---

### Milestone 23: VS Code Error & CFML Navigation Syntax Resolution
- **User Directive:** "fix vs code error"
- **Context & Diagnosis:**
  - Active document was `app/views/layout.cfm` (cursor positioned at line 728: PIO Emergency Alerts & News submenu item).
  - Identified issues flagged by CFML LSP / HTML language servers and runtime navigation inconsistencies:
    1. **Fragmented `<cfoutput>` Tags in HTML Attributes (`layout.cfm` lines 725–731):** Embedding `<cfoutput>#...#</cfoutput>` fragments inside `class=""` and `href=""` attributes violated HTML syntax rules in the language server. Restructured the `ul.nav-submenu` to wrap all child `li` items in a single, clean `<cfoutput>` block, emitting plain `#...#` expressions within attributes.
    2. **Missing `alerts` in Parent Nav Item Active Condition (`layout.cfm` line 717):** The parent PIO menu item checked `listFindNoCase('pressreleases,press-releases', params.controller)` but omitted `alerts`, causing the parent navigation group to close/deactivate when navigating to the Emergency Alerts & Dispatch studio (`/alerts`). Added `'alerts'` to the parent list check.
    3. **CFScript `!` Operator in CFML Tag Expression (`layout.cfm` line 763):** Replaced non-standard `(!structKeyExists(params, 'type') ...)` with canonical CFML tag expression `(not structKeyExists(params, 'type') ...)` in the Workspaces manager submenu.
    4. **Prevented Nested `<cfoutput>` Across Includes (`edit.cfm`, `editV2.cfm`):** Moved the closing `</cfoutput>` tag in `edit.cfm` and `editV2.cfm` above the `<cfinclude template="_pageEditorModals.cfm">` and `<cfinclude template="_pageEditorScripts.cfm">` directives, eliminating potential nested `<cfoutput>` tag warnings.
- **Verification:**
  - Tested local IIS application response `http://cmsadmin.chelancounty.gov/` (HTTP 200).
  - Verified `edit.cfm` and `editV2.cfm` are identical (`Compare-Object` returned zero differences).
  - Cleaned all diagnostic triggers across `layout.cfm`, `edit.cfm`, and `editV2.cfm`.

---

### Milestone 24: Application Version & Build Tracking System (`v2.1.[build]`)
- **User Directive:** "lets start a keep track of our versioning, V2.1.[build number]"
- **Deliverables & Architecture:**
  1. **Single Source of Truth (`config/version.json`):**
     - Established JSON metadata schema with `major: 2`, `minor: 1`, `build: 1`, `version: "2.1.1"`, `versionTag: "v2.1.1"`, `releaseName: "Page Studio Parity & Visual Layout Controls"`, `releaseDate`, and `builtAt`.
  2. **Application Configuration (`config/settings.cfm`):**
     - Registered framework-wide configuration keys: `set(appMajorVersion=2);`, `set(appMinorVersion=1);`, `set(appBuildNumber=1);`, `set(appVersion="2.1.1");`, `set(appVersionTag="v2.1.1");`, `set(appBuildDisplay="v2.1.1 (Build 1)");`.
  3. **Global Helper Functions (`app/global/functions.cfm`):**
     - Added `getAppVersion()` with cached in-memory deserialization from `config/version.json`.
     - Added `appVersion()`, `appVersionTag()`, `appBuildNumber()`, and `appBuildDisplay()`.
  4. **Master Shell Presentation (`app/views/layout.cfm`):**
     - **`<head>` Meta Tags:** Emits `<meta name="generator" content="Chelan County CMSAdmin v2.1.1">`, `<meta name="cms-version" content="2.1.1">`, and `<meta name="cms-build" content="1">`.
     - **Header Brand Badge:** Dynamically renders `<span class="brand-badge" title="Chelan County CMS Admin v2.1.1 (Build 1)">v2.1.1</span>`.
     - **Footer Status Bar:** Dynamically renders `<span>v2.1.1 (Build 1) &bull; Wheels 4.1 &bull; Adobe ColdFusion &bull; System Healthy</span>`.
  5. **System Info & Telemetry Dashboard (`Settings.cfc` & `system.cfm`):**
     - Integrated `diagnostics.app` into server diagnostics payload.
     - Added CMSAdmin version and build telemetry badge in page header and primary runtime table row in `/settings/system`.
  6. **Automated CLI Incrementor (`scripts/bump-version.ps1`):**
     - Created PowerShell automation tool supporting default auto-increment (`.\scripts\bump-version.ps1`), explicit build numbers (`-Build N`), minor version bumps (`-Minor N`), and major bumps (`-Major N`), synchronizing both `config/version.json` and `config/settings.cfm`.
  7. **Documentation Series Update:**
     - Documented the versioning scheme in Section 6 of `.doclib/001_SYSTEM_ARCHITECTURE.md`.
- **Verification:**
  - Tested build bump execution via `.\scripts\bump-version.ps1` (verified increment to build 2 and reset back to build 1).
  - Executed framework reload `/login?reload=true&password=chelancms` (HTTP 200).
  - Verified clean syntax across all modified files.




---

### Milestone 25: Series 007 Documentation Deep Dive & Production Specification Upgrade
- **User Directive:** "why are the md filess in .doclib is not detailed enough" -> "yes" (Expand and elevate `.doclib` technical specifications)
- **Problem Statement:** The original `.doclib` topic files (such as `007_EMERGENCY_ALERTS_AND_INCIDENTS.md`) were created as high-level summary skeletons (~70 lines) that lacked exhaustive implementation architecture, method contracts, UI walkthroughs, API schemas, and front-end integration code.
- **Deliverables & Enhancements in `.doclib/007_EMERGENCY_ALERTS_AND_INCIDENTS.md`:**
  1. **Statutory & Operational Mandate:** Formally documented RCW 42.56 public records retention compliance, EOC/PIO coordination, Level 1-3 wildfire evacuation definitions, pass closures, and county facility alerts.
  2. **System Architecture & Mermaid Topology:** Added end-to-end visual workflow mapping Dispatch Studio $\rightarrow$ Controller $\rightarrow$ SQL Server Filtered Indexes $\rightarrow$ Public REST API $\rightarrow$ Citizen Web/Mobile Touchpoints.
  3. **Data Model & Complete Data Dictionary:** Added column-by-column specifications for `dbo.emergency_alerts`, nullability, defaults, index definitions, and the mandatory `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` invariant.
  4. **Controller Actions Specification (`Alerts.cfc`):** Detailed breakdown of `config()`, `index()`, `save()`, `toggle()`, `delete()`, `apiActive()`, and private helper functions with argument handling and return envelopes.
  5. **Standard Incident Presets Catalog:** Complete JSON reference catalog for 6 municipal quick-dispatch templates (Level 1/2/3 Wildfire, Mountain Pass Closure, River Flood Warning, Courthouse 2-Hour Delay).
  6. **UI Component Architecture (`index.cfm`):** ASCII layout diagram and field-by-field walkthrough of the Dispatch Studio, KPI cards, live banner preview simulator, search filter, and accessible modals.
  7. **Public REST API Reference (`GET /api/v1/alerts/active`):** Full OpenAPI-style endpoint documentation with query filters (`?site=...`), HTTP caching/CORS headers, and sample JSON payloads for both active incidents and standby states.
  8. **Public Website Frontend Integration Blueprint:** Production-ready copy-paste embed snippet in vanilla JavaScript and CSS, with accessible ARIA live regions (`role="alert"`), `localStorage` dismissal persistence, and WCAG 2.1 AA color contrast compliance.
  9. **Operational Playbooks:** Emergency SQL "Kill Switch" script for immediate silent override across all county properties, cURL verification commands, and response header checks.

---

### Milestone 26: Complete `.doclib` Technical Overhaul & Project Customization Skill (`SKILL.md`)
- **User Directive:** "yes, this will turn out to be a reference for documentation and will become skill.md for this project"
- **Deliverables & Enhancements:**
  1. **Series 006 (Pages & Revision History Rollback Studio) Expanded:**
     - Added comprehensive technical specifications for `dbo.pages`, `dbo.page_revisions`, and `meta_json` serialization.
     - Documented the 4-phase snapshotting and rollback lifecycle, the client-side LCS word-token diff engine, the 4 comparison modes in `#pgRevisionsModal`, the 12-col Full vs 3/9 Sidebar wireframe layouts, the 6-field Featured Cover Image suite, and all controller actions in `Pages.cfc`.
  2. **Series 005 (Articles & Public Information Module) Expanded:**
     - Documented multi-tenant department scoping, category taxonomies (`dbo.article_categories`), tag indexing, scheduled publishing workflows, the automated `ArticleA11yLinter` quality gate, and the public REST API (`GET /api/v1/articles`) with full JSON schemas.
  3. **Series 004 (Media Library & Workspace File Explorer) Expanded:**
     - Documented the authoritative storage topology (`c:\inetpub\chelan-county\files\`), NTFS directory junctions for CMSAdmin and the shared photo library (`shared images` $\rightarrow$ `picjumbo`), the `dbo.media_assets` relational metadata index, the modal picker iframe postMessage contract, and traversal security controls.
  4. **Series 008 (Database Schema & SQL Server Standards) Expanded:**
     - Documented datasource configuration, the mandatory `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` invariant (Msg 1934 prevention), `cfsqltype` mapping rules (`cf_sql_nvarchar` Unicode enforcement), soft-delete audit standards, and multi-tenant workspace schemas (`dbo.cms_workspaces`).
  5. **Created Project Skill (`.agents/skills/cmsadmin2-development/SKILL.md`):**
     - Established an official, discoverable Antigravity workspace skill tailored to Chelan County CMSAdmin 2.0.
     - Encodes the 5 non-negotiable invariants, versioning and build scheme (`v2.1.[build]`), `.doclib` book of record map, page editor parity rules, cover image suite metadata, and pre-completion verification checklists for future pair-programming sessions.
- **Verification:**
  - Verified clean syntax across all `.doclib` files and `SKILL.md`.
  - Executed git status to review all staged/modified documentation assets.

---

### Milestone 27: Content Manager Inactive Page Soft-Delete Implementation
- **User Directive:** "On Content Managet pages list, when a page is inactive, give the option to soft delete /migrate-workflows"
- **Deliverables & Architecture:**
  1. **Route Mappings (`config/routes.cfm`):**
     - Added `.post(name="deletePage", pattern="pages/delete", to="pages##delete")`, `.post(name="deletePageCamel", pattern="pages/deletePage", to="pages##delete")`, and `.post(name="deletePageSoft", pattern="pages/soft-delete", to="pages##delete")`.
  2. **Controller Logic (`app/controllers/Pages.cfc`):**
     - Added `delete` to `protectsFromForgery(except="...,delete")`.
     - Implemented `function delete()`:
       - Validates page existence and ensures it is not already deleted (`DeletedAt IS NULL`).
       - Validates that system-locked pages cannot be deleted (`isLocked == 0`).
       - Enforces status constraint: only pages with `StatusCode = 'Inactive'` can be deleted.
       - Sets `DeletedAt = SYSUTCDATETIME()`, `Modified = SYSUTCDATETIME()`, and `ModifiedBy = spCurrentActor()` using mandatory `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`.
       - Records an audit snapshot in `dbo.page_revisions` to maintain 100% compliance with RCW 42.56.
  3. **Content Manager UI (`app/views/pages/index.cfm`):**
     - Expanded table actions column width from 48px to 76px.
     - Conditionally renders a red trash icon button (`.btn-outline-danger`) next to the Edit button whenever a page is inactive (`p.status eq 'Inactive'`) and not system-locked (`not p.locked`).
     - Added client-side `confirmDeletePage(id, title)` function utilizing `window.adminConfirm` with accessible prompt, CSRF token attachment, asynchronous `fetch('/pages/delete')`, and `window.showToast()` confirmation.
  4. **Skill Migration Check:**
     - Verified legacy workflow directories (`.agents/workflows/`, `_agents/workflows/`) are completely clean and migrated to the official Antigravity skill format at `.agents/skills/cmsadmin2-development/SKILL.md`.
- **Verification:**
  - Executed framework reload `/login?reload=true&password=chelancms` (HTTP 200).
  - Verified clean syntax in `config/routes.cfm`, `app/controllers/Pages.cfc`, and `app/views/pages/index.cfm`.

---

### Milestone 29: One Page Studio & Anchor-Based Navigation Integration
- **User Directive:** "We need to add an option to create a one page website (for front end portal/site) but taken from the selection of multiple pages - One Page Studio, menu can be defined from menu creation, i believe it will allow hash # tag for anchor."
- **Deliverables & Architecture:**
  1. **Relational Database Schema & SQL Server Standards:**
     - Created `dbo.one_page_sites` to store one-page portal configurations, hero settings, theme tokens, custom CSS/JS, and layout options.
     - Created `dbo.one_page_sections` to map workspace content pages (`page_id`) into ordered scrollable one-page sections with custom section anchors (`#amenities`), headings, badges, and layout variants (`contained`, `contained-card`, `full-bleed`).
     - Added SQL Server filtered indexes (`WHERE deletedat IS NULL`) complying with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` invariants:
       - `IX_one_page_sites_site_slug` on `dbo.one_page_sites([siteid], [slug])`
       - `IX_one_page_sections_site_sort` on `dbo.one_page_sections([one_page_site_id], [sort_order])`
       - `IX_one_page_sections_site_anchor` on `dbo.one_page_sections([one_page_site_id], [anchor_slug])`
     - Seeded initial reference portal for Wenatchee River Park (`siteid = 'wrcp'`, `slug = 'wenatchee-river-park'`) with 6 linked content sections and seed pages.
  2. **Navigation Anchor Hash (`#tag`) Support (`Navigation.cfc`, `navigation/index.cfm`):**
     - Updated destination validation in `Navigation.cfc::saveItem()` to permit `#tag` anchors (`^(https?://|/|##)`).
     - Enhanced `normalizeWorkspacePageDestination()` to preserve anchor hashes (`#section` and `/path#section`) without corrupting or prepending redundant slashes.
     - Enhanced `Navigation.cfc::index()` to query active one-page site anchors for the current workspace and pass them via `navigationConfigJson.onePageAnchors`.
     - Enhanced `app/views/navigation/index.cfm` with interactive quick-insert anchor pill badges in the Custom URL builder.
  3. **Controller Implementation & Public Access Bypass (`Pages.cfc`, `Controller.cfc`, `routes.cfm`):**
     - Added route mappings in `config/routes.cfm`: `pages/one-page`, `pages/one-page/preview`, `pages/one-page/export`, `pages/one-page/save`, `pages/one-page/delete`, `pages/one-page/section/save`, `pages/one-page/section/delete`, `pages/one-page/section/reorder`, and `pages/one-page/sync-menu`.
     - Whitelisted `previewonepagesite` and `exportonepagesite` in `Controller.cfc::isPublicRequest()` to allow public/guest iframe and tab previews and static zip/html downloads.
     - Added CSRF exemptions in `Pages.cfc::config()` for One Page Studio REST actions.
     - Implemented backend actions in `Pages.cfc`:
       - `onePage()`: Main Studio view action, auto-provisions schema if needed, loads active workspace sites, pages, and menus.
       - `getOnePageSites()`, `getOnePageSite()`, `saveOnePageSite()`, `deleteOnePageSite()`: Full CRUD for portal configurations.
       - `saveOnePageSection()`, `deleteOnePageSection()`, `reorderOnePageSections()`: Section management and order manipulation.
       - `syncOnePageToMenu()`: Automatic sync between One Page Studio sections and Navigation Menus with smooth-scrolling hash anchors.
       - `compileOnePageSite()`, `previewOnePageSite()`, `exportOnePageSite()`: Full multi-page assembly engine, standalone live renderer, and static export.
  4. **One Page Studio User Interface (`app/views/pages/onePage.cfm`, `app/views/layout.cfm`):**
     - Added "One Page Studio" link with desktop-stacked icon under the Pages menu in `app/views/layout.cfm`.
     - Built comprehensive Studio interface with:
       - **Assembler Tab:** Drag-and-drop / sortable list of sections with live badges, layout selectors, anchor tags, and edit/delete controls.
       - **Multi-Page Picker Drawer:** Searchable multi-page catalog to add multiple workspace pages to the one-page portal in bulk.
       - **Device Preview Tab:** Live interactive responsive iframe preview with Desktop, Tablet, and Mobile viewport toggles.
       - **Directory Tab:** Overview of all one-page sites in the active workspace with direct preview, edit, and export links.
       - **Navigation Sync:** One-click button to generate or update the workspace navigation menu with anchor links pointing to sections.
       - **Theme & Metadata Modal:** Control over navbar brand, CTA buttons, hero banner, primary colors, smooth scrolling, and custom CSS/JS.
  5. **Documentation & Automated Verification:**
     - Created comprehensive technical manual [`.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md).
     - Registered Series 013 in [`.doclib/000_SERIES_INDEX.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md).
     - Created automated test harness `tests/test_one_page_studio.cfm` verifying database schema, query execution with ANSI_NULLS/QUOTED_IDENTIFIER, controller action responses, anchor validation, HTML rendering, and menu sync: **22 / 22 Tests Passed (0 Failed)**.
- **Verification:**
  - ColdFusion framework reload executed successfully (`/login?reload=true&password=chelancms`).
  - Unit tests executed via HTTP request (`/tests/test_one_page_studio.cfm`), reporting 100% success rate.

---

### Milestone 28: Archived Page Detection & Interactive Reactivation Prompt
- **User Directive:** "what happen if i create a page with the same title as an archived page, should we ask if we need to activate the old file?" -> "lets do it"
- **Problem Statement:** When creating a new page via the "Add Page" modal, if an archived/soft-deleted page (`DeletedAt IS NOT NULL`) already existed with the same title or slug, the system previously ignored it and created a redundant, blank duplicate record. This fragmented revision history, abandoned existing assets and formatting, and created unnecessary URL suffixes (e.g. `/slug-2`).
- **Deliverables & Architecture:**
  1. **Route Mappings (`config/routes.cfm`):**
     - Registered `.post(name="restoreArchivedPage", pattern="pages/restore-archived", to="pages##restoreArchived")` and camelCase alias.
  2. **Controller Logic (`app/controllers/Pages.cfc`):**
     - Added `restoreArchived` to `protectsFromForgery(except="...,restoreArchived")`.
     - Enhanced `createModal()`:
       - Checks for existing soft-deleted pages (`DeletedAt IS NOT NULL`) in the active workspace matching the requested title or permalink (unless `forceNew: true` is passed).
       - When an archived page is detected, halts creation and returns `{ archivedFound: true, archivedPage: { id, title, slug, deletedAt, deletedBy, layout } }`.
     - Implemented `function restoreArchived()`:
       - Sets `DeletedAt = NULL`, `StatusCode = 'Active'`, `Visibility = 'Draft'`, `Modified = SYSUTCDATETIME()`, and `ModifiedBy = spCurrentActor()`.
       - Commits an automated reactivation snapshot to `dbo.page_revisions` (RCW 42.56 compliance).
       - Returns `{ success: true, redirectUrl: "/pages/edit?id=...&reactivated=1" }`.
  3. **Content Manager UI (`app/views/pages/index.cfm`):**
     - In `proceedToEditor()`, handles `data.archivedFound`:
       - Invokes `handleArchivedPageFound(archived)` using `window.adminConfirm`.
       - Explains to the author: *"An archived page titled '[Title]' (/[slug]) was previously archived on [Date] by [User]. Would you like to restore and activate this archived page with its previous content, attachments, and revision history?"*
       - Option 1 (Accept): Calls `executeRestoreArchivedPage()` to reactivate the existing page and immediately redirects to the editor with all past content intact.
       - Option 2 (Cancel): Prompts confirmation to create a fresh blank page (`proceedToEditor(true)`), auto-incrementing the slug to avoid URL conflicts.
- **Verification:**
  - Tested framework reload `/login?reload=true&password=chelancms` (HTTP 200).
  - Verified clean syntax in `config/routes.cfm`, `app/controllers/Pages.cfc`, and `app/views/pages/index.cfm`.

---

### Milestone 29: One Page Studio & Anchor-Based Navigation Integration
- **User Directive:** "We need to add an option to create a one page website (for front end portal/site) but taken from the selection of multiple pages - One Page Studio, menu can be defined from menu creation, i believe it will allow hash # tag for anchor."
- **Deliverables & Architecture:**
  1. **Relational Database Schema & SQL Server Standards:**
     - Created `dbo.one_page_sites` to store one-page portal configurations, hero settings, theme tokens, custom CSS/JS, and layout options.
     - Created `dbo.one_page_sections` to map workspace content pages (`page_id`) into ordered scrollable one-page sections with custom section anchors (`#amenities`), headings, badges, and layout variants (`contained`, `contained-card`, `full-bleed`).
     - Added SQL Server filtered indexes (`WHERE deletedat IS NULL`) complying with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` invariants:
       - `IX_one_page_sites_site_slug` on `dbo.one_page_sites([siteid], [slug])`
       - `IX_one_page_sections_site_sort` on `dbo.one_page_sections([one_page_site_id], [sort_order])`
       - `IX_one_page_sections_site_anchor` on `dbo.one_page_sections([one_page_site_id], [anchor_slug])`
     - Seeded initial reference portal for Wenatchee River Park (`siteid = 'wrcp'`, `slug = 'wenatchee-river-park'`) with 6 linked content sections and seed pages.
  2. **Navigation Anchor Hash (`#tag`) Support (`Navigation.cfc`, `navigation/index.cfm`):**
     - Updated destination validation in `Navigation.cfc::saveItem()` to permit `#tag` anchors (`^(https?://|/|##)`).
     - Enhanced `normalizeWorkspacePageDestination()` to preserve anchor hashes (`#section` and `/path#section`) without corrupting or prepending redundant slashes.
     - Enhanced `Navigation.cfc::index()` to query active one-page site anchors for the current workspace and pass them via `navigationConfigJson.onePageAnchors`.
     - Enhanced `app/views/navigation/index.cfm` with interactive quick-insert anchor pill badges in the Custom URL builder.
  3. **Controller Implementation & Public Access Bypass (`Pages.cfc`, `Controller.cfc`, `routes.cfm`):**
     - Added route mappings in `config/routes.cfm`: `pages/one-page`, `pages/one-page/preview`, `pages/one-page/export`, `pages/one-page/save`, `pages/one-page/delete`, `pages/one-page/section/save`, `pages/one-page/section/delete`, `pages/one-page/section/reorder`, and `pages/one-page/sync-menu`.
     - Whitelisted `previewonepagesite` and `exportonepagesite` in `Controller.cfc::isPublicRequest()` to allow public/guest iframe and tab previews and static zip/html downloads.
     - Added CSRF exemptions in `Pages.cfc::config()` for One Page Studio REST actions.
     - Implemented backend actions in `Pages.cfc`:
       - `onePage()`: Main Studio view action, auto-provisions schema if needed, loads active workspace sites, pages, and menus.
       - `getOnePageSites()`, `getOnePageSite()`, `saveOnePageSite()`, `deleteOnePageSite()`: Full CRUD for portal configurations.
       - `saveOnePageSection()`, `deleteOnePageSection()`, `reorderOnePageSections()`: Section management and order manipulation.
       - `syncOnePageToMenu()`: Automatic sync between One Page Studio sections and Navigation Menus with smooth-scrolling hash anchors.
       - `compileOnePageSite()`, `previewOnePageSite()`, `exportOnePageSite()`: Full multi-page assembly engine, standalone live renderer, and static export.
  4. **One Page Studio User Interface (`app/views/pages/onePage.cfm`, `app/views/layout.cfm`):**
     - Added "One Page Studio" link with desktop-stacked icon under the Pages menu in `app/views/layout.cfm`.
     - Built comprehensive Studio interface with:
       - **Assembler Tab:** Drag-and-drop / sortable list of sections with live badges, layout selectors, anchor tags, and edit/delete controls.
       - **Multi-Page Picker Drawer:** Searchable multi-page catalog to add multiple workspace pages to the one-page portal in bulk.
       - **Device Preview Tab:** Live interactive responsive iframe preview with Desktop, Tablet, and Mobile viewport toggles.
       - **Directory Tab:** Overview of all one-page sites in the active workspace with direct preview, edit, and export links.
       - **Navigation Sync:** One-click button to generate or update the workspace navigation menu with anchor links pointing to sections.
       - **Theme & Metadata Modal:** Control over navbar brand, CTA buttons, hero banner, primary colors, smooth scrolling, and custom CSS/JS.
  5. **Documentation & Automated Verification:**
     - Created comprehensive technical manual [`.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md).
     - Registered Series 013 in [`.doclib/000_SERIES_INDEX.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md).
     - Created automated test harness `tests/test_one_page_studio.cfm` verifying database schema, query execution with ANSI_NULLS/QUOTED_IDENTIFIER, controller action responses, anchor validation, HTML rendering, and menu sync: **22 / 22 Tests Passed (0 Failed)**.
- **Verification:**
  - ColdFusion framework reload executed successfully (`/login?reload=true&password=chelancms`).
  - Unit tests executed via HTTP request (`/tests/test_one_page_studio.cfm`), reporting 100% success rate.

---

### Milestone 29: One Page Studio & Anchor-Based Navigation Integration
- **User Directive:** "We need to add an option to create a one page website (for front end portal/site) but taken from the selection of multiple pages - One Page Studio, menu can be defined from menu creation, i believe it will allow hash # tag for anchor."
- **Deliverables & Architecture:**
  1. **Relational Database Schema & SQL Server Standards:**
     - Created `dbo.one_page_sites` to store one-page portal configurations, hero settings, theme tokens, custom CSS/JS, and layout options.
     - Created `dbo.one_page_sections` to map workspace content pages (`page_id`) into ordered scrollable one-page sections with custom section anchors (`#amenities`), headings, badges, and layout variants (`contained`, `contained-card`, `full-bleed`).
     - Added SQL Server filtered indexes (`WHERE deletedat IS NULL`) complying with `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` invariants:
       - `IX_one_page_sites_site_slug` on `dbo.one_page_sites([siteid], [slug])`
       - `IX_one_page_sections_site_sort` on `dbo.one_page_sections([one_page_site_id], [sort_order])`
       - `IX_one_page_sections_site_anchor` on `dbo.one_page_sections([one_page_site_id], [anchor_slug])`
     - Seeded initial reference portal for Wenatchee River Park (`siteid = 'wrcp'`, `slug = 'wenatchee-river-park'`) with 6 linked content sections and seed pages.
  2. **Navigation Anchor Hash (`#tag`) Support (`Navigation.cfc`, `navigation/index.cfm`):**
     - Updated destination validation in `Navigation.cfc::saveItem()` to permit `#tag` anchors (`^(https?://|/|##)`).
     - Enhanced `normalizeWorkspacePageDestination()` to preserve anchor hashes (`#section` and `/path#section`) without corrupting or prepending redundant slashes.
     - Enhanced `Navigation.cfc::index()` to query active one-page site anchors for the current workspace and pass them via `navigationConfigJson.onePageAnchors`.
     - Enhanced `app/views/navigation/index.cfm` with interactive quick-insert anchor pill badges in the Custom URL builder.
  3. **Controller Implementation & Public Access Bypass (`Pages.cfc`, `Controller.cfc`, `routes.cfm`):**
     - Added route mappings in `config/routes.cfm`: `pages/one-page`, `pages/one-page/preview`, `pages/one-page/export`, `pages/one-page/save`, `pages/one-page/delete`, `pages/one-page/section/save`, `pages/one-page/section/delete`, `pages/one-page/section/reorder`, and `pages/one-page/sync-menu`.
     - Whitelisted `previewonepagesite` and `exportonepagesite` in `Controller.cfc::isPublicRequest()` to allow public/guest iframe and tab previews and static zip/html downloads.
     - Added CSRF exemptions in `Pages.cfc::config()` for One Page Studio REST actions.
     - Implemented backend actions in `Pages.cfc`:
       - `onePage()`: Main Studio view action, auto-provisions schema if needed, loads active workspace sites, pages, and menus.
       - `getOnePageSites()`, `getOnePageSite()`, `saveOnePageSite()`, `deleteOnePageSite()`: Full CRUD for portal configurations.
       - `saveOnePageSection()`, `deleteOnePageSection()`, `reorderOnePageSections()`: Section management and order manipulation.
       - `syncOnePageToMenu()`: Automatic sync between One Page Studio sections and Navigation Menus with smooth-scrolling hash anchors.
       - `compileOnePageSite()`, `previewOnePageSite()`, `exportOnePageSite()`: Full multi-page assembly engine, standalone live renderer, and static export.
  4. **One Page Studio User Interface (`app/views/pages/onePage.cfm`, `app/views/layout.cfm`):**
     - Added "One Page Studio" link with desktop-stacked icon under the Pages menu in `app/views/layout.cfm`.
     - Built comprehensive Studio interface with:
       - **Assembler Tab:** Drag-and-drop / sortable list of sections with live badges, layout selectors, anchor tags, and edit/delete controls.
       - **Multi-Page Picker Drawer:** Searchable multi-page catalog to add multiple workspace pages to the one-page portal in bulk.
       - **Device Preview Tab:** Live interactive responsive iframe preview with Desktop, Tablet, and Mobile viewport toggles.
       - **Directory Tab:** Overview of all one-page sites in the active workspace with direct preview, edit, and export links.
       - **Navigation Sync:** One-click button to generate or update the workspace navigation menu with anchor links pointing to sections.
       - **Theme & Metadata Modal:** Control over navbar brand, CTA buttons, hero banner, primary colors, smooth scrolling, and custom CSS/JS.
  5. **Documentation & Automated Verification:**
     - Created comprehensive technical manual [`.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/013_ONE_PAGE_STUDIO_AND_PORTAL_BUILDER.md).
     - Registered Series 013 in [`.doclib/000_SERIES_INDEX.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md).
     - Created automated test harness `tests/test_one_page_studio.cfm` verifying database schema, query execution with ANSI_NULLS/QUOTED_IDENTIFIER, controller action responses, anchor validation, HTML rendering, and menu sync: **22 / 22 Tests Passed (0 Failed)**.
- **Verification:**
  - ColdFusion framework reload executed successfully (`/login?reload=true&password=chelancms`).
  - Unit tests executed via HTTP request (`/tests/test_one_page_studio.cfm`), reporting 100% success rate.

  - **ColdFusion Tag Output Parser Hotfix:** Resolved `Invalid CFML construct found on line 408 at column 141` in `app/views/pages/onePage.cfm` caused by unescaped HTML numeric entity `#` in `&#8942;&#8942;` inside `<cfoutput>` block, escaping it to `&##8942;&##8942;`.

  - **Navigation View CFML Hash Escaping Hotfix:** Resolved `Invalid CFML construct found on line 186 at column 162` in `app/views/navigation/index.cfm` caused by unescaped `#` in placeholder and description text (`#anchor`, `#amenities`, `#rates`) within a `<cfoutput>` context, escaping them to `##`.
  - **JSON Key Case Normalization Hotfix:** Resolved `Menu sync failed.` UI alert caused by Adobe ColdFusion `SerializeJSON` serializing unquoted CFML struct keys as uppercase (`SUCCESS`, `MESSAGE`). Added key lowercasing in `Pages.cfc::fxRenderJson()` and defensive case-insensitive checks in `app/views/pages/onePage.cfm`.
  - **Admin-Only Role Restriction:** Moved One Page Studio exclusively to the **Administration** navigation group in `app/views/layout.cfm` (alongside Workspaces, Users & Roles, and Navigation Menus with the `layers` SVG icon), removing it from the general Content Management pages submenu. Added server-side role security checks (`getCurrentActiveRole() == 'admin'`) to `Pages.cfc::onePage()` and all One Page Studio API endpoints (`saveOnePageSite`, `saveOnePageSection`, `syncOnePageToMenu`, etc.), restricting access strictly to System Administrators.
