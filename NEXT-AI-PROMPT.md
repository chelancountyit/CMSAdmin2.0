# Continuation Prompt for Next AI Agent

```markdown
You are continuing work on Chelan County CMSAdmin 2.0, a ColdFusion (CFWheels 4.1.2) administrative application running on IIS 10.0 and Lucee CFML engine.
The database is Microsoft SQL Server (Datasource: `ChelanCountyWebsite`). Direct SQL queries use `queryExecute()`.

## 📌 Context & Current Status
We recently completed and verified:
1. **Feature 2.2: Page Revision History & Rollback Studio (RCW 42.56 Compliance)**:
   - Database schema: `dbo.page_revisions` in `ChelanCountyWebsite` (`config/sql/schema-page-revisions.sql` and `schema-complete.sql`).
   - CFWheels model `app/models/PageRevision.cfc` and routes in `config/routes.cfm`.
   - Controller `app/controllers/Pages.cfc`: baseline auto-snapshotting, save snapshotting with revision notes, `revisions()`, `revision()`, `restoreRevision()`, `snapshotRevision()`.
   - Mandatory RCW 42.56 compliance: automatic safety snapshot of CURRENT page state prior to rollback, followed by live record restoration and new version record.
   - Interactive accessible modal studio (`#pgRevisionsModal`) in `app/views/pages/edit.cfm` with chronological timeline cards, word/token diff generator, 4 view modes (Visual Diff, Side-by-Side Split, Snapshot Preview, Raw HTML), and one-click rollback with `window.adminConfirm`.
2. **Feature 2.1: Emergency Alert Banner & Incident Dispatch System** (`/alerts`, `/pio/alerts`):
   - Database table `dbo.emergency_alerts` (`config/sql/schema-emergency-alerts.sql` with filtered index `WHERE deletedat IS NULL`).
   - CFWheels model `app/models/EmergencyAlert.cfc` and controller `app/controllers/Alerts.cfc` (`index`, `save`, `toggle`, `delete`, `apiActive`).
   - Dispatch Studio `app/views/alerts/index.cfm` featuring a live banner simulator (Critical/Warning/Notice), quick-dispatch incident presets (Wildfires, Pass Closures, Floods, Courthouse Closures), active alerts list, and soft-delete.
   - Public high-speed JSON API endpoint (`GET /api/v1/alerts/active`) with public access exception in `Controller.cfc:isPublicRequest()`.
   - Updated `web.config` rewrite rules to ensure `/api/v1/...` routes reach CFWheels rather than throwing IIS 404s.
   - Top-header live alert badge indicator with count and direct sidebar link under PIO.
3. **Feature 1.4: Staff Profile & Notifications System** (`/users/profile`):
   - Created `Users.cfc` actions (`profile`, `updateProfile`, `updatePassword`, `updatePreferences`) and `app/views/users/profile.cfm`.
   - Dedicated password change tab with current password verification, length checks, and match validation.
   - Linked to top-header user menu.

Reference documentation:
- `STATUS.md`: Complete system status, active routes, and module matrix
- `CHECKPOINT.md`: Latest engineering milestone details and verification checklist
- `TODO.md`: 4-phase engineering roadmap and technical debt checklist
- `PROMPT.md`: Complete chronological prompt history and architecture rules

---

## 🎯 Recommended Next Tasks (from `TODO.md`)

1. **Feature 2.3: In-Editor Automated ADA WCAG Pre-Flight Linter**:
   - Real-time accessible audit bar in [`app/views/pages/edit.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/pages/edit.cfm) validating content before publish:
     - Missing or empty `alt` attributes on embedded `<img>` tags.
     - Low-quality alt text (e.g. `alt="image.jpg"`, `alt="photo"`).
     - Broken heading hierarchy (e.g. jumping from `<h2>` directly to `<h4>`).
     - Ambiguous link text (flags "click here", "read more", "link" without descriptive text).
     - Tables lacking semantic `<th>` column/row headers.
2. **Feature 2.4: Public Website API Layer & Mega-Menu Integration**:
   - Read-only REST/JSON endpoints for consumption by public websites:
     - `GET /api/v1/how-do-i` (Categorized active items with `show_in_mega_menu = 1`).
     - `GET /api/v1/navigation/menu?code=main` (Hierarchical navigation structure).
     - `GET /api/v1/events/upcoming?limit=5` (Filtered calendar events).
   - In-memory caching (`application.apiCache`) with instant cache purge on admin save.
3. **Feature 1.1: Scaffold PIO Division Modules (Replace Placeholder Anchors)**:
   - Articles & Posts (`Articles.cfc`): News, county blog posts, categories, and tags.
   - Press Releases & Media Alerts: Embargo dates, media contacts, PDF attachments.
   - Real-time accessible audit bar in `pages/edit.cfm` validating alt text, heading jumps, link ambiguity, and table structure before publish.
4. **County Domain Standardization (`chelancounty.gov`)**:
   - Replaced all occurrences of legacy domain `co.chelan.wa.us` across the entire codebase (CFML controllers, views, global functions, JavaScript editors, and SQL seeds).
   - Executed live SQL updates across all SQL Server tables (`emergency_alerts`, `how_do_i_items`, `cms_users`, `cms_workspaces`, `calendar_events`, `pages`, `page_SubPage`, `page_CtaCard`, `job_applications`, `form_audit_logs`).
   - Verified 0 remaining occurrences across both codebase files and SQL database.
   - `GET /api/v1/how-do-i`, `GET /api/v1/navigation/menu`, `GET /api/v1/events/upcoming`.

---

## ⚠️ Important Engineering Rules to Follow
1. **Zero external CSS/JS libraries**: Vanilla ES6+ and modern CSS custom properties (`admin-theme.css`) only.
2. **ADA WCAG 2.1/2.2 AA accessibility**: Explicit `<label for="...">`, visible 2px solid focus rings, contrast >= 4.5:1, skip links, semantic HTML.
3. **No Native `alert()` / `confirm()`**: Always use `window.adminAlert({ title, message, type })`, `window.adminConfirm({ title, message, type, confirmText, cancelText })`, and `window.showToast(msg, type)`. Keep modal backdrops below `z-index: 100000` (e.g., `9990`) so `#adminPromptBackdrop` (`z-index: 100000`) renders above open modals.
4. **CFML `<cfoutput>` Hash Escaping**:
   - In `<cfoutput>` blocks, any literal `#` in client JS or CSS (e.g. `'Alert ##' + id`, `color: ##ff0000;`) MUST be escaped as `##`.
5. **CFML JSON & Client Consumption**:
   - Quote struct keys in CFML before `SerializeJSON()` (`{ "title": ... }`).
   - On the client side, use case-insensitive fallbacks (`item.title || item.TITLE`) to safeguard against CFML key uppercasing.
   - Include `"X-Requested-With": "XMLHttpRequest"` and `"X-CSRF-Token"` on all `POST` `fetch()` calls.
6. **IIS URL Rewrite Negation Pattern**:
   - Never add `api` to the negation pattern in `web.config` so `/api/v1/...` requests route to CFWheels.
7. **SQL Server Filtered Indexes**:
   - Prepend `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` to all `INSERT`/`UPDATE` statements on tables with filtered indexes (`WHERE [deletedat] IS NULL`), and pass `value: ""` alongside `null: true` on nullable integer params.
```
