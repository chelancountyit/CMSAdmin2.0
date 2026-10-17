# Series 002: Activity Summary & Engineering Changelog
**Location:** `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Executive Summary

This log maintains a chronological, permanent record of engineering milestones, schema migrations, architectural refinements, and verified features in Chelan County CMSAdmin 2.0. All AI agents and developers must append new activities to this log upon completing any significant change.

---

## 2. Chronological Milestones

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
