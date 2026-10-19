# Series 001: System Architecture & Platform Blueprint
**Location:** `.doclib/001_SYSTEM_ARCHITECTURE.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Executive Overview

**Chelan County CMSAdmin 2.0** is the official enterprise administrative content management system for Chelan County Government (`chelancounty.gov`). It provides centralized web content authoring, department-isolated workspaces, automated ADA WCAG 2.1 AA pre-flight quality enforcement, emergency public safety alert broadcasting, press release management, news and blog publishing, and public records revision auditing.

---

## 2. Infrastructure & Runtime Stack

| Component | Technology | Specification / Configuration |
|---|---|---|
| **Operating System** | Microsoft Windows Server | Local development on Windows 10/11 Enterprise |
| **Web Server** | Microsoft IIS 10.0 | Integrated pipeline, URL Rewrite Module 2.1 (`web.config`) |
| **Application Server** | Lucee Server / Railo CFML Engine | Java 11/17 OpenJDK runtime, BonCode AJP 1.3 connector |
| **Framework** | Wheels (CFWheels) 4.1.2 | MVC architecture, ActiveRecord ORM, REST routing |
| **Database** | Microsoft SQL Server | Datasource: `ChelanCountyWebsite` |
| **Database Access** | `queryExecute()` | Strongly typed parameterized queries with `cfsqltype` |
| **Frontend UI** | Vanilla HTML5 / ES6+ / CSS3 | Modern CSS custom properties, zero external runtime libraries |
| **Domain** | `chelancounty.gov` | Standardized county public domain (legacy `co.chelan.wa.us` retired) |

---

## 3. Directory Structure

```
c:\inetpub\CMSAdmin2.0\
├── .doclib\                   # System documentation series & knowledge base (this library)
├── app\
│   ├── controllers\           # CFWheels controllers (Pages, Articles, Alerts, Media, Users, etc.)
│   ├── models\                # ActiveRecord model CFCs (PageRevision, EmergencyAlert, etc.)
│   └── views\                 # CFML templates (articles, pages, alerts, media, layouts)
│       └── layouts\           # Admin master shell layout (layout.admin.cfm)
├── config\
│   ├── routes.cfm             # REST and custom application route mappings
│   ├── settings.cfm           # Environment settings and application configurations
│   └── sql\                   # SQL Server DDL migrations and schema scripts
├── files\                     # Department workspace file storage (/files/{workspace}/)
├── javascripts\               # Self-contained client-side scripts
│   ├── admin.js               # Global UI system: adminAlert, adminConfirm, showToast
│   ├── jbd\                   # Accessible rich text editor (JBDEditor)
│   └── filexplorer\           # Workspace media browser & picker client
└── stylesheets\               # Core styling & modern CSS design tokens
```

---

## 4. Security & Role-Based Access Control (RBAC)

CMSAdmin 2.0 implements a strict multi-tier role hierarchy:

1. **`admin` (System Administrator):**
   - Global administrative authority across all departments, system settings, user management, and security configurations.
2. **`dept_director` (Department Director):**
   - Department-level leadership with full publish and approval privileges within their assigned workspace.
3. **`editor` (Staff Editor):**
   - Can create, edit, draft, and publish pages and documents within assigned workspaces.
4. **`author` (Staff Contributor):**
   - Can create and draft content; publication requires editorial sign-off.
5. **`pio` (Public Information Officer):**
   - Specialized cross-departmental authority over emergency alerts, press releases, media contacts, and countywide articles.

### Workspace Isolation
All departmental assets and pages are partitioned by `siteid` (workspace slug, e.g. `pio`, `assessor`, `sheriff`, `commissioners`, `community-development`). Staff members are strictly routed to their assigned workspace folder trees in `/files/{siteid}/`.

---

## 5. Non-Negotiable Core Invariants

1. **Zero External CDN Policy:**
   - The application must function completely inside secure, air-gapped, or intranet environments. All fonts, styles, scripts, and SVG icons are hosted locally.
2. **Accessible Native Dialog Prohibition:**
   - Native browser popups (`alert()`, `confirm()`, `prompt()`) freeze threads and fail screen reader accessibility guidelines. All interactions use `window.adminAlert()`, `window.adminConfirm()`, and `window.showToast()`.
3. **SQL Server Filtered Index Safety:**
   - Any query executing DDL or DML against tables with filtered indexes (`WHERE deletedat IS NULL`) MUST be prepended with:
     ```sql
     SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
     ```
   - Failing to include these options triggers SQL Server `Msg 1934`.

---

## 6. Application Versioning & Build Scheme (`v2.1.[build]`)

CMSAdmin 2.0 tracks versioning using standard semantic releases parameterized by build increments:

- **Format:** `v2.1.[build]` (e.g. `v2.1.1`)
- **Single Source of Truth:** [`config/version.json`](file:///c:/inetpub/CMSAdmin2.0/config/version.json)
- **Framework Configuration:** [`config/settings.cfm`](file:///c:/inetpub/CMSAdmin2.0/config/settings.cfm) (`set(appVersion="2.1.1"); set(appBuildNumber=1);`)
- **Global Helper Functions:**
  - `getAppVersion()`: Returns structured version metadata struct.
  - `appVersion()`: Returns semantic version string (e.g. `"2.1.1"`).
  - `appVersionTag()`: Returns formatted version tag (e.g. `"v2.1.1"`).
  - `appBuildNumber()`: Returns numeric build integer (e.g. `1`).
  - `appBuildDisplay()`: Returns display string (e.g. `"v2.1.1 (Build 1)"`).
- **UI Surfaces:**
  - Header brand badge (`layout.cfm` line 290)
  - Footer status indicator (`layout.cfm` line 837)
  - HTML `<meta>` tags: `generator`, `cms-version`, `cms-build`
  - System Info Telemetry (`/settings/system`)
- **Automated CLI Incrementor:**
  ```powershell
  # Increments current build by 1 (e.g. v2.1.1 -> v2.1.2)
  .\scripts\bump-version.ps1

  # Explicit build or minor/major releases
  .\scripts\bump-version.ps1 -Build 5
  .\scripts\bump-version.ps1 -Minor 2
  ```


