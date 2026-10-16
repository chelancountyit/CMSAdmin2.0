# Series 002: Activity Summary & Engineering Changelog
**Location:** `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Executive Summary

This log maintains a chronological, permanent record of engineering milestones, schema migrations, architectural refinements, and verified features in Chelan County CMSAdmin 2.0. All AI agents and developers must append new activities to this log upon completing any significant change.

---

## 2. Chronological Milestones

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

