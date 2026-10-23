---
name: cmsadmin2-development
description: Chelan County CMSAdmin 2.0 full-stack development framework, architecture, non-negotiable invariants, and comprehensive .doclib reference guide. Activate for any CMSAdmin 2.0 coding, schema querying, page/article editing, modal creation, accessibility auditing, or public safety dispatch tasks.
---

# Chelan County CMSAdmin 2.0 Development Skill

This skill equips AI agents with the complete engineering standards, architecture, and coding rules for **Chelan County CMSAdmin 2.0**, an enterprise municipal Content Management System built on **ColdFusion Wheels 4.1**, **Adobe ColdFusion 2025**, and **Microsoft SQL Server**.

---

## 1. Non-Negotiable Invariants

All development in this repository **must** strictly adhere to these 5 core invariants:

1. **Zero External CDNs:**
   - External CDN requests (cdnjs, unpkg, jsdelivr, Google Fonts, fontawesome) are **strictly forbidden**.
   - All CSS, SVG icons, fonts, and JavaScript libraries must be hosted locally under `/stylesheets/`, `/javascripts/`, and `/fonts/`.
2. **Zero Native Browser Dialogs:**
   - `alert()`, `confirm()`, and `prompt()` are strictly forbidden.
   - Always use:
     - Informational alerts: `window.adminAlert({ title, message, type })`
     - Destructive confirmations: `await window.adminConfirm({ title, message, type, confirmText, cancelText })`
     - Notification toasts: `window.showToast(message, type)`
3. **Mandatory SQL Server Filtered Index Directives (Msg 1934 Prevention):**
   - Tables utilize filtered nonclustered indexes with `WHERE deletedat IS NULL`.
   - Every `INSERT`, `UPDATE`, or `DELETE` query touching these tables **must** be prepended with:
     ```sql
     SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
     ```
   - Omission of these connection settings causes SQL Server error `Msg 1934: UPDATE failed because QUOTED_IDENTIFIER is OFF`.
4. **Mandatory Parameterized Typing (`cfsqltype`):**
   - All `queryExecute()` statements must pass typed parameter structs.
   - `NVARCHAR` and `NVARCHAR(MAX)` columns **must** use `cfsqltype: "cf_sql_nvarchar"` to prevent multi-byte Unicode truncation/corruption into `?`.
5. **Always Log Significant Milestones:**
   - After completing significant milestones or architectural changes, append a detailed summary to [`.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md).

---

## 2. Definitive Book of Record: `.doclib` Series Map

Always ground implementations in the corresponding `.doclib` technical specification:

| Series | Document Title & Path | Core Focus & Subsystems |
| :---: | :--- | :--- |
| **000** | [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md) | Series Master Index, AI Navigation Protocols, Project Roadmap |
| **001** | [001_SYSTEM_ARCHITECTURE.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/001_SYSTEM_ARCHITECTURE.md) | Stack Blueprint, Wheels MVC, IIS, Versioning Scheme (`v2.1.[build]`) |
| **002** | [002_ACTIVITY_SUMMARY_AND_CHANGELOG.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md) | Comprehensive engineering changelog, verified milestones, test trails |
| **003** | [003_ACCESSIBILITY_WCAG21AA_LINTER.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/003_ACCESSIBILITY_WCAG21AA_LINTER.md) | ADA Title II, Section 508, WCAG 2.1 Level AA Pre-Flight Linters |
| **004** | [004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md) | Media Repository, NTFS Junctions, Modal Picker, `dbo.media_assets` |
| **005** | [005_ARTICLES_AND_PUBLIC_INFORMATION.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/005_ARTICLES_AND_PUBLIC_INFORMATION.md) | Articles & Newsroom, Cover Photo Suite, Categories, Tags, Public REST API |
| **006** | [006_PAGES_AND_REVISION_HISTORY_STUDIO.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/006_PAGES_AND_REVISION_HISTORY_STUDIO.md) | Page Editor, Parity (`edit.cfm`/`editV2.cfm`), Rollback Studio, Modals |
| **007** | [007_EMERGENCY_ALERTS_AND_INCIDENTS.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/007_EMERGENCY_ALERTS_AND_INCIDENTS.md) | Incident Dispatch Studio, Presets (Wildfires/Roads), REST API, Kill Switch |
| **008** | [008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md) | SQL Server DDL, Filtered Indexes, `cfsqltype` mapping, `cftransaction` |
| **009** | [009_DEVELOPMENT_STANDARDS_AND_RULES.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/009_DEVELOPMENT_STANDARDS_AND_RULES.md) | Code quality, naming conventions, security gating, CSRF protection |
| **010** | [010_SCHEDULED_PUBLISHING_AND_EXPIRATION_WORKER.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/010_SCHEDULED_PUBLISHING_AND_EXPIRATION_WORKER.md) | Background Evaluator, `publish_at`/`unpublish_at`, automated archiving |
| **011** | [011_RFP_AND_SOLICITATIONS_MANAGER.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/011_RFP_AND_SOLICITATIONS_MANAGER.md) | Bids, Solicitations, Addenda, Planholder registries, public bidding |
| **012** | [012_DOCUMENT_CONVERTER_WCAG_AA.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/012_DOCUMENT_CONVERTER_WCAG_AA.md) | Pure ColdFusion Word (`.docx`) & PDF to WCAG AA HTML conversion engine |

---

## 3. Application Versioning & Build Scheme (`v2.1.[build]`)

All release builds adhere to the `v2.1.[build]` incrementing standard:
- **Single Source of Truth:** [`config/version.json`](file:///c:/inetpub/CMSAdmin2.0/config/version.json)
- **Framework Registration:** [`config/settings.cfm`](file:///c:/inetpub/CMSAdmin2.0/config/settings.cfm)
- **Global Helper Functions:** [`app/global/functions.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/global/functions.cfm):
  - `getAppVersion()`: Returns cached struct from `version.json`
  - `appVersion()`: Returns `"2.1.1"`
  - `appVersionTag()`: Returns `"v2.1.1"`
  - `appBuildNumber()`: Returns numeric build (e.g. `1`)
  - `appBuildDisplay()`: Returns `"v2.1.1 (Build 1)"`
- **CLI Bumper Tool:** Run `.\scripts\bump-version.ps1` to increment the build number automatically across JSON and settings files.

---

## 4. Key Subsystem Development Patterns

### 1. Page Editor Synchronization (`edit.cfm` and `editV2.cfm`)
- `app/views/pages/edit.cfm` and `app/views/pages/editV2.cfm` **must maintain 100% parity**.
- Modals are extracted into `app/views/pages/_pageEditorModals.cfm`.
- JavaScript handlers are extracted into `app/views/pages/_pageEditorScripts.cfm`.
- `<cfoutput>` blocks must be placed cleanly outside `<cfinclude>` directives to prevent CFML language server nesting diagnostics.

### 2. Featured Cover Image Suite (6 Metadata Fields)
When implementing or modifying cover imagery across Pages, Articles, or RFPs, always include the 6 standard fields:
1. `imageAttachment` / `featured_image`: High-res URL path
2. `imageAttribution` / `featured_image_credit`: Photographer/agency credit
3. `imageAlt` / `featured_image_alt`: Concise descriptive alt text ($\le 150$ chars)
4. `imageTitle` / `featured_image_caption`: Visible public caption
5. `imageDescription` / `featured_image_description`: Extended transcription for charts/maps ($\le 2000$ chars)
6. `imageDecorative` / `featured_image_decorative`: Bit flag implementing WCAG Technique H67 (`alt=""`, `role="presentation"`)

### 3. Emergency Dispatch & Public REST API
- Alerts controller: `app/controllers/Alerts.cfc`
- Endpoint: `GET /api/v1/alerts/active?site=global`
- Always return CORS headers: `Access-Control-Allow-Origin: *`
- Always set caching header: `Cache-Control: public, max-age=60`

---

## 5. Verification Checklist Prior to Completion

Before declaring any milestone or task complete:
1. **LSP & CFML Syntax:** Check modified `.cfm` and `.cfc` files for unclosed tags or syntax warnings.
2. **SQL Invariants:** Verify `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` precedes all DML.
3. **Parity Check:** If modifying `edit.cfm` or `editV2.cfm`, run `Compare-Object` to ensure zero drift.
4. **App Response:** Test `http://cmsadmin.chelancounty.gov/` (or reload with `/login?reload=true&password=chelancms`).
5. **Changelog Entry:** Append a new milestone entry to `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`.

