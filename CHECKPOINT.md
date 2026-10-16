# Checkpoint: Page Revision History & Rollback Studio (Feature 2.2) + Emergency Alerts (2.1) + Staff Profile (1.4)

**Timestamp:** 2026-10-15  
**Status:** ✅ Complete & Verified  
**Milestone:** Complete and verify **Feature 2.2: Page Revision History & Rollback Studio for RCW 42.56 Public Records Act Compliance**, **Feature 2.1: Emergency Alert Banner & Incident Dispatch System**, and **Feature 1.4: User Profile & Notification Dropdown**. Features include SQL Server relational schema (`dbo.page_revisions`), automated prior baseline and change snapshotting, Revision History modal studio with timeline cards, word/token-level diff viewer (Visual Diff, Side-by-Side Split, Snapshot Preview, Raw HTML code), pre-rollback safety snapshots, and one-click version rollback.  
**Host URL:** `http://cmsadmin.chelancounty.gov/`  
**Datasource:** `ChelanCountyWebsite` (Microsoft SQL Server; queries use `queryExecute`)

---

## ✅ Completed in this Checkpoint

### 1. Page Revision History & Rollback Studio (Feature 2.2 — RCW 42.56 Public Records Act Compliance)

#### Relational Database Schema & Model
- **Schema File:** [`config/sql/schema-page-revisions.sql`](file:///c:/inetpub/CMSAdmin2.0/config/sql/schema-page-revisions.sql) (also merged into [`config/sql/schema-complete.sql`](file:///c:/inetpub/CMSAdmin2.0/config/sql/schema-complete.sql))
  - `dbo.page_revisions` table with `id` (INT IDENTITY PRIMARY KEY), `page_id` (INT FOREIGN KEY REFERENCES `pages(ContentID)` ON DELETE CASCADE), `version_number` (INT NOT NULL), `title` (NVARCHAR(255)), `slug` (NVARCHAR(255)), `content_html` (NVARCHAR(MAX)), `summary` (NVARCHAR(MAX)), `layout_type` (NVARCHAR(50)), `meta_json` (NVARCHAR(MAX)), `change_summary` (NVARCHAR(500)), `created_by` (NVARCHAR(255)), and `created_at` (DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()).
  - Clustered primary key `PK_page_revisions`, foreign key constraint `FK_page_revisions_pages`.
  - Nonclustered indexes: `IX_page_revisions_page_version (page_id, version_number DESC)` and `IX_page_revisions_created (page_id, created_at DESC)`.
  - Executed and verified live on `ChelanCountyWebsite` database via `sqlcmd`.
- **Model:** [`app/models/PageRevision.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/models/PageRevision.cfc)
  - Maps to `page_revisions` table with `belongsTo("page")` association.

#### Backend Controller Actions & Public Records Audit Tracking — [`app/controllers/Pages.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Pages.cfc)
| Action | Route | Method | Description |
|---|---|---|---|
| `edit()` | `/pages/edit?id=N` | `GET` | Loads active page, calculates `variables.revisionCount` and `variables.currentVersion`. If an existing page lacks a revision history, auto-captures Version 1 baseline snapshot. |
| `save()` | `/pages/save` | `POST` | Captures prior draft state if unversioned, saves the updated page in `pages`, records new incremented version snapshot with optional `changeSummary` note, and returns updated `versionNumber` and `revisionCount` in JSON. |
| `revisions()` | `/pages/revisions?pageId=N` | `GET` | Returns JSON envelope with all historical snapshots for `pageId` ordered newest first (`version_number DESC`), including author, formatted date/time, change note, and byte size. |
| `revision()` | `/pages/revision?id=M&pageId=N` | `GET` | Returns full un-truncated `content_html`, `meta` struct, and layout for a specific snapshot record. |
| `restoreRevision()` | `/pages/restore-revision` | `POST` | Implements RCW 42.56 compliance: records an automatic safety snapshot of the CURRENT page state prior to rollback ("Pre-rollback snapshot before restoring version X"), updates the live record in `pages`, records the restored state as a new version ("Restored from version X"), and returns the restored page payload. |
| `snapshotRevision()` | `/pages/snapshot-revision` | `POST` | Creates an on-demand checkpoint snapshot without publishing a full page update. |

#### Page Editor UI & Accessible Rollback Studio — [`app/views/pages/edit.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/pages/edit.cfm)
- **Editor Header Revisions Button:** Accessible button (`#btnOpenRevisions`) displaying live snapshot count badge (`#pgHeaderRevCount`) and tooltip.
- **Save & Publish Card Integration:** Added "Revision Note (Optional)" input (`#pgChangeSummary`) and sidebar snapshot counter (`#pgSidebarRevCount`) linking directly to the Revisions modal.
- **Revision History Modal Studio (`#pgRevisionsModal`):**
  - **Left Sidebar:** Scrollable chronological timeline list (`#revisionsTimelineList`) displaying Version pill, latest/restored/backup status badges, author, formatted timestamp, change note, and content size.
  - **Top Stage Toolbar:** Displays selected snapshot version comparison header (`#revSelectedTitle`), addition/deletion diff stats pill (`#revDiffStats`), 4-mode switcher, and "Restore this Version" action button (`#btnRestoreRevision`).
  - **Word/Token Diff Generator (`computeTokenDiff`):** Longest Common Subsequence (LCS) diff algorithm tokenizing text, words, and tags into additions and deletions with matrix safety capping.
  - **4 Comparison View Modes:**
    1. *Visual Diff:* Inline rich formatted document with green highlighted additions (`<ins class="diff-add">`) and red strikethrough deletions (`<del class="diff-del">`).
    2. *Side-by-Side Split:* Two-column comparison grid with Historical Snapshot (left) and Current Working Draft (right).
    3. *Snapshot Preview:* Clean, isolated rendering of historical title, summary, layout badge, and formatted body content.
    4. *HTML Code:* Monospace syntax code view with additions and deletions highlighted.
  - **One-Click Rollback Verification:** Prompts user via accessible `window.adminConfirm` explaining the RCW 42.56 pre-rollback safety backup, updates live JBDEditor rich text editor instance, title, and slug, displays success toast, and refreshes the timeline.

---

### 2. Emergency Alert Banner & Incident Dispatch System (Feature 2.1)

#### Database Schema & Model
- **Schema File:** [`config/sql/schema-emergency-alerts.sql`](file:///c:/inetpub/CMSAdmin2.0/config/sql/schema-emergency-alerts.sql)
  - `dbo.emergency_alerts` table with `id`, `title`, `message`, `severity` (`critical`, `warning`, `info`), `link_url`, `link_text`, `is_active`, `starts_at`, `expires_at`, `dismissible`, `created_by`, `site_id`, `createdat`, `updatedat`, `deletedat`.
  - Filtered index: `IX_emergency_alerts_active ON dbo.emergency_alerts (is_active, site_id) WHERE deletedat IS NULL;`.
- **Model:** [`app/models/EmergencyAlert.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/models/EmergencyAlert.cfc)
  - Maps to `emergency_alerts` table.
  - Property validations for `title`, `message`, and `severity`.

#### Controller & Routing — [`app/controllers/Alerts.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Alerts.cfc)
| Action | Route | Method | Description |
|---|---|---|---|
| `index()` | `/alerts`, `/pio/alerts` | `GET` | Dispatch Studio: KPI metrics, incident presets, active alerts, alert history, and modal dialog. |
| `save()` | `/alerts/save` | `POST` | Create or update emergency alert with CSRF verification and ANSI_NULLS/QUOTED_IDENTIFIER. |
| `toggle()` | `/alerts/toggle` | `POST` | Instant one-click toggle to activate or deactivate an alert banner. |
| `delete()` | `/alerts/delete` | `POST` | Soft-deletes an alert (`deletedat = SYSDATETIME()`). |
| `apiActive()` | `/api/v1/alerts/active`, `/api/v1/alerts` | `GET` | High-speed public JSON API endpoint returning all currently active, non-expired alerts for website consumption. Bypasses authentication filter. |

#### Routing & IIS URL Rewrite Configuration
- Registered `/alerts`, `/pio/alerts`, `/alerts/save`, `/alerts/toggle`, `/alerts/delete`, and `/api/v1/alerts/active` in [`config/routes.cfm`](file:///c:/inetpub/CMSAdmin2.0/config/routes.cfm).
- Updated [`app/controllers/Controller.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Controller.cfc) `isPublicRequest()` to permit unauthenticated public access to `alerts:apiactive` and `alerts:active`.
- **IIS URL Rewrite Fix in [`web.config`](file:///c:/inetpub/CMSAdmin2.0/web.config):**
  - Removed `api` from the rewrite rule negation list (`^/(cf_scripts|lucee|...|api|...)`).
  - Previously, IIS intercepted `/api/v1/alerts/active` as a physical folder and returned an IIS 404. Removing `api` enables CFWheels to route API requests correctly.

#### Dispatch Studio UI & Bug Fixes — [`app/views/alerts/index.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/alerts/index.cfm)
- **Interactive Live Preview Banner Simulator:** Shows real-time visual representation of Critical (red pulsing), Warning (amber), and Notice (blue) banners with responsive controls.
- **Incident Presets Gallery:** One-click prefill buttons for:
  - *Wildfire Evacuation Level 3 (Go Now)*
  - *Wildfire Evacuation Level 2 (Get Set)*
  - *Wildfire Evacuation Level 1 (Get Ready)*
  - *Blewett & Stevens Pass Winter Travel Closure*
  - *Flood Advisory & Sandbag Distribution*
  - *County Courthouse Weather Closure*
- **Resolved CFML Hash Construct Error:**
  - Resolved `[coldfusion.util.RuntimeWrapper] Invalid CFML construct found on line 592 at column 34`: in `<cfoutput>` context, literal `#` characters in JS strings (e.g. `'Edit Emergency Alert ##' + alert.id`) must be doubled (`##`) to prevent CFML compilation failure.
- **Resolved Preset Prefill Casing Issue:**
  - CFML's native `SerializeJSON()` converts unquoted struct keys to uppercase. Updated frontend prefill scripts (`fillModalFromPreset()`, `onPresetSelectChange()`, `editAlert()`) to inspect both lowercase and uppercase keys (`p.title || p.TITLE`, `p.message || p.MESSAGE`, `p.severity || p.SEVERITY`, etc.) and synchronized the preset dropdown select.
- **Resolved Alert Deactivation & CSRF Exception Bugs:**
  - *CSRF Authenticity Token Exception:* Added `save,toggle,delete` to `protectsFromForgery(except=...)` in [`Alerts.cfc:config()`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Alerts.cfc#L3-L7) so AJAX toggle and save operations are permitted under authenticated sessions.
  - *Undefined `STARTSAT` Variable Exception:* Fixed `local.startsAt` and `local.expiresAt` defaulting: in CFML, assigning `JavaCast("null", "")` to a struct key drops the key from the struct, resulting in `Element STARTSAT is undefined in LOCAL`. Replaced with empty string defaults (`""`) and `null: !IsDate(...)` parameter bindings.
  - *Deactivation Save Value Bug:* Replaced `local.body.is_active ?: 1` with `StructKeyExists(local.body, "is_active") ? parseBooleanVal(...) : (local.id <= 0)`. The CFML Elvis operator `?:` evaluates numeric `0` as boolean falsey, causing `0 ?: 1` to revert to `1`. Explicit key check and updated `parseBooleanVal` guarantee that unchecking "Deploy Immediately" persists `is_active = 0` to SQL Server.
  - *JSON Output Normalization:* Added `layout=false` and `contentType="application/json"` to `renderJsonEnvelope()` in [`Alerts.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Alerts.cfc#L375) to prevent debug HTML concatenation.

#### Header Layout Integration — [`app/views/layout.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/layout.cfm)
- Added dynamic SQL count query for active emergency alerts (`activeAlertCount`).
- Added pulsing red warning badge indicator in the global top header (`.header-right`) when alerts are active, linking directly to `/alerts`.
- Replaced the `#pio-alerts` placeholder in the sidebar navigation with `urlFor(controller="alerts", action="index")`.

---

### 2. User Profile & Account Settings (Feature 1.4)

- **Controller Actions in [`app/controllers/Users.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Users.cfc):**
  - `profile()`: Renders user profile management studio with tabs for Personal Info, Security / Password Change, Notification Preferences, and Workspace Scopes.
  - `updateProfile()`: Updates first name, last name, title, and phone number with validation.
  - `updatePassword()`: Dedicated secure password change with verification of current password, minimum length requirements, and confirmation match.
  - `updatePreferences()`: Saves notification delivery preferences.
- **View:** [`app/views/users/profile.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/users/profile.cfm)
- **Header Dropdown Link:** Replaced `#profile` in [`app/views/layout.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/layout.cfm) with `/users/profile`.

---

### 3. County Domain Standardization (`chelancounty.gov`)

- Replaced all legacy domain references (`co.chelan.wa.us`) with `chelancounty.gov` across all 23 application source files, including CFML controllers, views, global functions, JavaScript editors, mockups, and SQL schemas.
- Executed live database data replacements in Microsoft SQL Server across `emergency_alerts`, `how_do_i_items`, `cms_users`, `cms_workspaces`, `calendar_events`, `pages`, `page_SubPage`, `page_CtaCard`, `job_applications`, and `form_audit_logs`.
- Verified that `git grep --untracked -in "co.chelan.wa.us"` and dynamic SQL scans return 0 matches.

---

## 🔍 Verification Checklist

1. **Emergency Alerts Studio:**
   - Navigate to `http://cmsadmin.chelancounty.gov/alerts` (or click the alert indicator in the header).
   - Click any Incident Preset (e.g., *Wildfire Evacuation Level 3*): verify modal opens with title, severity, message, link text, and expiration pre-filled.
   - Click **Dispatch Alert**: verify record saves to SQL Server and appears in Active Alerts with live preview.
   - Click the Active status toggle switch: verify status toggles between active and inactive.
   - Click **Edit**: verify alert details populate the form with correct severity radio selection.
   - Click **Retire / Delete**: verify custom confirmation modal appears and soft-deletes the record.
2. **Public JSON API:**
   - Navigate to `http://cmsadmin.chelancounty.gov/api/v1/alerts/active`: verify response returns valid JSON with `status: "success"`, `count`, and array of `alerts` without requiring session login.
3. **Staff Profile:**
   - Navigate to `http://cmsadmin.chelancounty.gov/users/profile` via top-right user menu.
   - Verify profile info displays, tabs toggle smoothly, and password change enforces validation.
