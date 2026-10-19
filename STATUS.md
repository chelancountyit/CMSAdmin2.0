# Chelan County CMS Admin 2.0 - Comprehensive Project Status

**Current Stage:** Emergency Alerts (2.1), User Profile (1.4), Pages, Navigation, HRM Jobs, Form Builder & "How Do I?" Directory Manager (SQL Server Wired)  
**Last Updated:** 2026-10-15  
**Platform Host:** `http://cmsadmin.chelancounty.gov/`  
**Framework:** CFWheels 4.1.2 (App-side flat structure)  
**Server Environment:** Microsoft-IIS/10.0 + Lucee CFML Engine (Java/JVM)  
**WCAG Compliance:** ADA Title II, Section 508 & WCAG 2.1 / 2.2 Level AA  

---

## 📊 1. Executive Summary

CMSAdmin 2.0 is an enterprise-grade, high-performance Content Management System administration suite architected for Chelan County public services. The system replaces bloated legacy dependencies with zero-dependency modern native web standards, full ADA WCAG 2.1/2.2 AA accessibility, multi-tier automated anti-spam protections, departmental organization (featuring dedicated HRM and PIO divisions), an interactive visual online form builder, a public-service "How Do I?" directory manager, and a comprehensive pages and content management system.

---

## 🗺️ 2. Core Modules & Implementation Status

| Module | Route / Endpoint | Status | Description |
|---|---|---|---|
| **Admin Shell & Layout** | `/` (Dashboard) | ✅ Complete | Chelan County official logo (`logo.png`), responsive sidebar, workspace selector, breadcrumbs, notifications, and custom modal dialog system (`window.adminAlert`, `window.adminConfirm`, `window.adminPrompt`). |
| **Workspace Selector** | Global Header | ✅ Complete | Department/site switcher (`Global`, `HRM`, `PIO`, `Admin`, `Community Development`, etc.) with localStorage/cookie persistence and event broadcasting. |
| **Emergency Alerts & Incident Dispatch** | `/alerts`, `/pio/alerts`, `/alerts/save`, `/alerts/toggle`, `/alerts/delete`, `/api/v1/alerts/active` | ✅ Complete | Full emergency dispatch studio (`emergency_alerts` table, `Alerts.cfc`, `EmergencyAlert.cfc`). Real-time live banner simulator (Critical/Warning/Notice), one-click incident presets (Wildfires Level 1/2/3, Winter Pass Closures, Flood Advisory, Courthouse Closures), instant status toggle, active alert indicator in admin header, and high-speed public JSON API endpoint (`/api/v1/alerts/active`) with IIS URL rewrite integration. |
| **User Profile & Account Settings** | `/users/profile`, `/users/updateProfile`, `/users/updatePassword`, `/users/updatePreferences` | ✅ Complete | Staff profile and credentials studio (`Users.cfc:profile`, `users/profile.cfm`) with personal information editor, dedicated secure password changer, notification preferences, assigned workspace overview, and functional header dropdown integration. |
| **How Do I? Directory Manager** | `/pages/how-do-i`, `/pages/save-how-do-i-item`, `/pages/save-how-do-i-category`, `/pages/delete-how-do-i-item`, `/pages/delete-how-do-i-category` | ✅ Complete | Full CRUD manager under **Pages > How Do I** modeled after `https://www.chelancounty.gov/howdoi` (Apply for, Contact, Find, File, Get, Learn About, Pay, Register for, Report, Request, Submit, View). Supports linking each question to an internal CMS **Page**, an online **Form**, or an **External URL**, with live 4-column public directory preview, category management, SQL Server persistence (`how_do_i_categories`, `how_do_i_items`), CSRF header verification, and custom `adminAlert`/`adminConfirm` dialogs. |
| **Content Manager (All Pages)** | `/pages`, `/pages/index` | ✅ Complete | SQL Server-backed filterable listing, system-page protection, and accessible "Add Page" modal with real-time slugify, immediate DB creation, and 2 iconized layout wireframe cards (`Full Width` and `Right Sidebar`). |
| **Add / Edit Page Editor** | `/pages/edit`, `/pages/edit?id=N` | ✅ Complete | SQL Server-backed page & sub-page editor (`pages`, `sub_pages`), JBD Rich Text Editor, SEO meta fields, Page Assignment listbox (`Top Level - Called from URL` / `Assign to Main Menu Item`), conditional menu item picker, and Right Sidebar sub-pages manager. |
| **Page Revision History & Rollback Studio (RCW 42.56)** | `/pages/revisions`, `/pages/revision`, `/pages/restore-revision`, `/pages/snapshot-revision` | ✅ Complete | Full revision tracking and version rollback studio (`page_revisions` table, `PageRevision.cfc`, `Pages.cfc:revisions,revision,restoreRevision,snapshotRevision`). Automatic baseline and pre-rollback safety snapshots for RCW 42.56 Public Records Act compliance, token-level diff calculation, 4 comparison views (Visual Diff, Side-by-Side Split, Snapshot Preview, Raw HTML), live header badge counter, and one-click restore. |
| **Folder Explorer in Page Attributes** | `/pages/edit` (Page Attributes) | ✅ Complete | Integrated into Page Attributes on Add/Edit Page (`folder_explorers`). "Add Folder Explorer Item" modal prompts for Title, Server Absolute Path, Web URL Relative Path, and Layout selection (`Full Width` vs `3/9 Grid Layout`) with iconized wireframe cards. |
| **Events / Calendar Manager** | `/events`, `/calendar`, `/events/save`, `/events/delete`, `/events/category/save`, `/events/ics` | ✅ Complete | Full County Calendar of Events studio under **Content Management > Events / Calendar** (`calendar_events`, `calendar_event_categories`). Features Interactive Monthly Calendar Grid, Filterable Events List, Public Calendar Preview, Add/Edit Event modal with Quick Presets (time & county locations), Virtual Meeting (Zoom/Teams) links, Agenda Packet Media Library integration, Category Manager, and `.ICS` iCalendar export. |
| **Navigation Menu Manager** | `/navigation`, `/navigation/index` | ✅ Complete | Multi-workspace navigation menu & hierarchical menu item studio (`navigation_menus`, `navigation_menu_items`). |
| **HRM Job Postings & Careers** | `/jobs`, `/jobs/edit` | ✅ Complete | Human Resources job postings & applications studio (`job_postings`, `job_applications`). |
| **Form Builder Studio** | `/form-builder`, `/forms/builder` | ✅ Complete | 17+ field palette, drag/click-to-add, live property inspector, sticky scroll panels, mobile column auto-stacking, device viewport simulator. Starts with a clean canvas on new form creation with explicit template loading (`?template=...`) and draft resumption (`?resume=1`). |
| **Form Starter Templates** | `/forms/builder?template=...`, `/forms/preview?template=...` | ✅ Complete | Official municipal templates: "Report a Problem" (Public Works), "Report Infestations & Pests" (Natural Resources), HRM Candidate Intake, PIO Press Inquiry, Building Permit, and Satisfaction Survey. |
| **Form Builder DB Save / Load** | `POST /forms/save`, `/forms/builder?id=N` | ✅ Complete | `Forms.cfc:save()` upserts `forms` + `form_fields` (by `field_key`, soft-deletes removed fields), caches `schema_json`, writes `form_audit_logs`. Builder loads DB forms via `window.CMSAdminFormBuilderConfig.form` and saves via `fetch` with `X-CSRF-Token`. |
| **Public Form Intake & Submissions** | `/forms/preview?slug=…`, `/forms/submit`, `/forms/submissions`, `/forms/export-csv` | ✅ Complete | Public form rendering, per-form honeypot + speed trap, file uploads to `files/_form-uploads/`, live submissions modal, and UTF-8 CSV export. |
| **Embed & Export Engine** | Form Builder Modal | ✅ Complete | Responsive iFrame embed generator, syntax-highlighted code card, standalone WCAG AA HTML download, JSON schema export. |
| **Workspace Root Files & Media Library** | `/files/` (Root Filesystem) | ✅ Complete | Dedicated root `files/` folders provisioned for each workspace/site (`assessors`, `auditor`, `hrm`, `pio`, `community-development`, `public-works`, `admin`, `commissioners`, `sheriff`, `treasurer`, `clerk`, `chelancounty.gov`, `parks.chelancounty.gov`, `gis.chelancounty.gov`, `shared`). |
| **Media Library & Asset Browser** | `/media`, `/media/upload`, `/media/picker` | ✅ Complete | Full government-grade media asset management studio: dual Grid & List views, real-time filesystem scanning (`files/`), strict workspace folder isolation, live search, asset inspector drawer with metadata editor, drag-and-drop upload studio, and modal Media Picker integration. |
| **PIO Articles & Posts** | `/app/views/layout.cfm` | ✅ Complete | Articles & Posts menu moved exclusively under PIO (Public Information Office) in the sidebar and Quick Create menu. |
| **Users & Roles Directory** | `/users`, `/users/index` | ✅ Complete | Government staff directory with 4 user groups (`Admin`, `PIO`, `HR`, `Author`), live multi-facet filtering, search, 2FA status, and accessible Role Permissions Inspector modal. |
| **Roles & Permissions Studio** | `/users/roles` | ✅ Complete | Dedicated RBAC permissions studio with 4 usergroup overview cards, full functional capability matrix, and dynamic persona switcher. |
| **Workspaces Management Studio** | `/workspaces`, `/workspaces/index` | ✅ Complete | Dedicated Administrator workspace management center: 16 municipal workspaces, 4 KPI cards, filter tabs (Departments vs Sites), filesystem verification, staff counts, and direct context switching. |
| **Add / Edit User Management** | `/users/new`, `/users/edit` | ✅ Complete | Fast-action add/edit staff forms with interactive 4-role selection radio cards, department workspace scoping, and live permission summaries. |
| **Dynamic Role Simulator** | `/users/simulate?role=[role]` | ✅ Complete | Real-time interface simulator allowing administrators to test and preview the exact CMS interface for Admin, PIO, HR, and Author roles. |
| **Delete Prevention Policy** | Pages & Core Records | ✅ Complete | Permanent record protection on Pages: delete actions removed from Pages screens. Inactive/Hidden status used for decommissioning. |
| **Database Schema Specs** | `config/sql/*.sql`, `Form-Builder.md` | ✅ Complete | Complete SQL Server schemas (`schema-complete.sql`, `schema-emergency-alerts.sql`, `schema-events.sql`, `schema-how-do-i.sql`, `schema-pages.sql`, `schema-page-subpage.sql`, `schema-foldex-explorer.sql`, `schema-navigation.sql`, `schema-form-builder.sql`, `schema-users-roles.sql`, `schema-workspaces.sql`). |

---

## ♿ 3. ADA Title II & WCAG 2.1 / 2.2 Level AA Compliance Hardening

Every user-facing screen, public intake form, exported HTML document, and admin studio view adheres to strict WCAG 2.1/2.2 AA standards:

1. **Bypass Blocks (SC 2.4.1 - Level A)**:
   - Permanent, high-contrast "Skip to main content" links (`.skip-link`) placed as the first interactive element inside `<body>` across `layout.cfm`, `preview.cfm`, and standalone form exports. Target: `<main id="mainContent" tabindex="-1">`.
2. **Color Contrast (SC 1.4.3 & 1.4.11 - Level AA)**:
   - Normal text contrast $\ge 4.5:1$ on all backgrounds (`--admin-text-main: #0f172a` = 16.5:1, `--admin-text-muted: #475569` = 7.48:1 on white and 6.6:1 on `#f4f6fa`).
   - Accent colors calibrated: Success (`#15803d` = 4.72:1), Warning (`#b45309` = 4.82:1), Danger (`#b91c1c` = 5.92:1), Info (`#0284c7` = 4.58:1), Purple (`#7e22ce` = 7.21:1).
   - Non-text UI control borders: `--admin-border-input: #64748b` ensuring $\ge 3:1$ contrast against adjacent white backgrounds.
3. **Focus Visible (SC 2.4.7 - Level AA)**:
   - Universal 2px high-contrast solid focus ring (`outline: 2px solid var(--admin-primary) !important; outline-offset: 2px !important;`) applied globally to buttons, inputs, links, tabs, switches, and radio/checkbox controls.
4. **Information & Relationships (SC 1.3.1 - Level A)**:
   - Every input, select, textarea, and file upload has an explicit `<label for="...">`.
   - Multi-field Address blocks enclosed in `<fieldset class="fb-fieldset fb-address-group" role="group">` with `<legend>` and individual visually hidden `<label class="sr-only">` tags for Street, Line 2, City, State, and ZIP.
   - Choice groups (Radio, Checkbox) enclosed in semantic `<fieldset>` with accessible `<legend>`.
   - Subtexts linked via `aria-describedby`.
   - Asterisks accompanied by `<span class="sr-only"> (required)</span>` and `aria-required="true"`.
5. **Input Purpose Identification (SC 1.3.5 - Level AA)**:
   - Proper HTML5 `autocomplete` attributes populated (`name`, `email`, `tel`, `street-address`, `address-line2`, `address-level2`, `address-level1`, `postal-code`).
6. **Keyboard Navigation & Operability (SC 2.1.1 & 2.1.2 - Level A)**:
   - Palette items and template cards implemented as `<button type="button">` for native keyboard navigation and `Enter`/`Space` activation.
   - Interactive star ratings feature roving `tabindex` and full arrow key (`ArrowLeft`, `ArrowRight`, `ArrowUp`, `ArrowDown`), `Home`, and `End` support.
   - Modal dialogs support `Escape` key dismissal and trapping protection.
7. **Screen Reader Utility & Live Regions (SC 4.1.2 & 4.1.3 - Level AA)**:
   - Global `.sr-only` class defined in `admin-theme.css` ensuring hidden helper text is never visually leaked on any screen.
   - Live regions (`role="alert"` and `role="status"` with `aria-live="polite"`) for real-time validation and autosave status announcements.

---

## 🛡️ 4. Anti-Spam & Submission Security Architecture

1. **Invisible Honeypot Bot Trap**:
   - Inaudible and invisible field (`_chelan_gov_verify`, `aria-hidden="true"`, `tabindex="-1"`, styled off-screen). Bots populate all encountered inputs; human submissions leave it blank. Populated values trigger immediate denial (`SPAM_HONEYPOT_TRIGGERED`).
2. **Form Load Speed-Trap Token**:
   - Millisecond timestamp token (`_cf_form_load_time`) generated at render. Submissions received under 3 seconds (configurable) are held with an accessible warning alert (`SUBMISSION_TOO_FAST`).
3. **Double-Click & Cooldown Prevention**:
   - Submit buttons trigger `.btn-submitting` with spinner, disabling pointer events during inflight requests.
4. **Server Validation**:
   - `Forms.cfc:submit()` verifies honeypots and request validity, returning structured JSON response envelopes.

---

## 👥 5. Role-Based Access Control (RBAC) & User Management Architecture

The platform enforces a robust 4-tier security model designed specifically for Chelan County municipal administration:

### 1. Defined User Groups & Scopes
1. **Administrator (`admin`)**:
   - **Scope:** Full, unrestricted county-wide administrative access.
   - **Modules:** Content Management Group, HRM Group, PIO Group, Administration, Navigation Menus, Global Settings, User Provisioning, and Audit Logs.
2. **PIO (`pio` - Public Information Officer)**:
   - **Scope:** Public communications, press relations, urgent notifications, and county news.
   - **Modules:** **Content Management Group + PIO Group** (Articles & Posts, Press Releases, Media Alerts, Public Records Requests, Emergency Alerts).
   - **Restrictions:** Restricted from HRM confidential records and system administration.
3. **HR (`hr` - Human Resources)**:
   - **Scope:** Personnel recruitment, employee onboarding, benefits, and policy archives.
   - **Modules:** **Content Management Group + HRM Group** (Job Postings & Careers, Employee Onboarding, Personnel Policies, HRM Applications & Inquiries).
   - **Restrictions:** Restricted from PIO communications and system administration.
4. **Author (`author`)**:
   - **Scope:** General web content authoring and website updates.
   - **Modules:** **Content Management Group only** (Pages Directory & Editor, Media Library & Asset Browser, Form Builder Studio & Forms, Citizen Feedback & Inquiries).
   - **Restrictions:** Restricted from HRM, PIO, and Administration.

### 2. Functional Capability Matrix
| Operational Module / Feature | Author | HR | PIO | Administrator |
|---|:---:|:---:|:---:|:---:|
| **All Pages Directory & Page Editor** | ✅ Full Access | ✅ Full Access | ✅ Full Access | ✅ Full Access |
| **Media Library & Asset Browser** | ✅ Full Access | ✅ Full Access | ✅ Full Access | ✅ Full Access |
| **Form Builder Studio & Online Forms** | ✅ Full Access | ✅ Full Access | ✅ Full Access | ✅ Full Access |
| **Citizen Feedback & Inquiries** | 🔶 Assigned Dept | ✅ Full Access | ✅ Full Access | ✅ Full Access |
| **HRM Forms & Job Applications** | ⛔ No Access | ✅ Full Access | ⛔ No Access | ✅ Full Access |
| **Job Postings & Careers Studio** | ⛔ No Access | ✅ Full Access | ⛔ No Access | ✅ Full Access |
| **Employee Onboarding Workflows** | ⛔ No Access | ✅ Full Access | ⛔ No Access | ✅ Full Access |
| **Personnel Policy Library** | ⛔ No Access | ✅ Full Access | ⛔ No Access | ✅ Full Access |
| **Articles & Posts (PIO News)** | ⛔ No Access | ⛔ No Access | ✅ Full Access | ✅ Full Access |
| **Press Releases & Media Alerts** | ⛔ No Access | ⛔ No Access | ✅ Full Access | ✅ Full Access |
| **Public Records Requests (PRR)** | ⛔ No Access | ⛔ No Access | ✅ Full Access | ✅ Full Access |
| **Emergency Alerts & Notifications** | ⛔ No Access | ⛔ No Access | ✅ Full Access | ✅ Full Access |
| **Users & Roles Management** | ⛔ No Access | ⛔ No Access | ⛔ No Access | ✅ Full Access |
| **Navigation Menu Manager** | ⛔ No Access | ⛔ No Access | ⛔ No Access | ✅ Full Access |
| **System & Global Settings** | ⛔ No Access | ⛔ No Access | ⛔ No Access | ✅ Full Access |

### 3. Dynamic Persona Simulation
- **Route:** `/users/simulate?role=[admin|pio|hr|author]`
- Administrators can instantly test and verify the exact visual and functional experience of any staff role without logging out.
- The simulator dynamically adjusts the sidebar navigation, quick create menus, permission gates, and displays a high-visibility dismissible notification banner indicating the simulated persona.

### 4. Multi-Workspace & Portal Assignment Architecture
- **Capability:** Users can be assigned to multiple departmental workspaces (11 municipal divisions) and public sites/portals (4 web properties), or assigned county-wide `global` scope.
- **Assigned Workspaces Catalog (16 Scopes):**
  - **Global Scope:** `global` (All Workspaces - County-wide Overview across all 11 departments and 4 portals)
  - **11 Municipal Departments:** `assessors`, `auditor`, `hrm`, `pio`, `commdev`, `pw`, `admin`, `commissioners`, `sheriff`, `treasurer`, `clerk`
  - **4 Public Sites & Portals:** `site-main` (`chelancounty.gov`), `site-parks` (`parks.chelancounty.gov`), `site-gis` (`gis.chelancounty.gov`), `site-expo` (`expo.chelancounty.gov`)
- **Multi-Select Matrix UI:**
  - Dedicated "Assigned Workspaces & Sites" card on `users/new.cfm` and `users/edit.cfm` with master global toggle, quick buttons (`All Departments`, `All Sites`, `Clear`), live selection count badge, and categorized 2-column cards.
  - Interactive multi-workspace matrix integrated into the fast-action "Add New User" modal on `users/index.cfm`.
  - Accessible "Role Permissions Inspector" modal displays the staff member's active authorized workspaces and portals alongside their module entitlements.
- **Directory Table & Filtering:**
  - Directory table features an "Assigned Workspaces / Sites" column rendering responsive badge chips for each assigned workspace (`badge-info`, `badge-success`, `badge-purple`, etc.) with automated `+N more` popover tooltips if more than 3 workspaces are assigned.
  - Search filter bar includes a workspace selector (`dept`) with grouped `<optgroup>` options for Departments and Public Sites, matching against both specific workspace codes and global accounts.
- **Relational Database Design (`schema-users-roles.sql`):**
  - Table `cms_users` includes `assigned_workspaces NVARCHAR(MAX) NULL` JSON column for fast retrieval.
  - Relational junction table `cms_user_workspaces (id, user_id, workspace_code, is_primary, createdat)` with foreign key cascading delete, unique constraint on `(user_id, workspace_code)`, and index on `workspace_code` for strict relational integrity.

---

## 📁 6. Directory & File Reference

```
c:\inetpub\CMSAdmin2.0\
├── app/
│   ├── controllers/
│   │   ├── Alerts.cfc              # Emergency Alert Banner & Incident Dispatch controller
│   │   ├── Controller.cfc          # Base CFWheels controller (CSRF protection, role & workspace security)
│   │   ├── Documentation.cfc       # System documentation & guides controller
│   │   ├── Forms.cfc               # Form builder, listing, preview, submit, submissions & CSV export
│   │   ├── Jobs.cfc                # HRM Job Postings & Applications controller
│   │   ├── Main.cfc                # CMS Admin dashboard controller
│   │   ├── Media.cfc               # Media Library directory, scanner, upload & metadata API
│   │   ├── Navigation.cfc          # Navigation Menu & Menu Items studio controller
│   │   ├── Pages.cfc               # All Pages, Add/Edit Page, Sub-Pages, Folder Explorer & "How Do I?" CRUD
│   │   ├── Sessions.cfc            # Authentication & session controller
│   │   ├── Up.cfc                  # Proxy health check / warmup probe
│   │   ├── Users.cfc               # Users & Roles directory, matrix, simulation & CRUD actions
│   │   └── Workspaces.cfc          # Administrator Workspace Management Studio controller
│   ├── models/
│   │   ├── EmergencyAlert.cfc      # Emergency alert notifications (`emergency_alerts`)
│   │   ├── FolderExplorer.cfc      # Folder explorer mappings (`folder_explorers`)
│   │   ├── Form.cfc                # Form definitions (`forms`)
│   │   ├── FormAuditLog.cfc        # Form security & lifecycle audit log (`form_audit_logs`)
│   │   ├── FormDepartment.cfc      # Form departments (`form_departments`)
│   │   ├── FormField.cfc           # Form fields (`form_fields`)
│   │   ├── FormSubmission.cfc      # Form submissions (`form_submissions`)
│   │   ├── FormSubmissionValue.cfc # Form submission values (`form_submission_values`)
│   │   ├── HowDoICategory.cfc      # "How Do I?" verb categories (`how_do_i_categories`)
│   │   ├── HowDoIItem.cfc          # "How Do I?" action links (`how_do_i_items`)
│   │   ├── JobApplication.cfc      # HRM job applications (`job_applications`)
│   │   ├── JobPosting.cfc          # HRM job postings (`job_postings`)
│   │   ├── NavigationMenu.cfc      # Site navigation menus (`navigation_menus`)
│   │   ├── NavigationMenuItem.cfc  # Navigation menu items (`navigation_menu_items`)
│   │   ├── Page.cfc                # CMS pages (`pages`)
│   │   ├── Role.cfc                # RBAC roles (`cms_roles`)
│   │   ├── SubPage.cfc             # Page right-sidebar sub-pages (`sub_pages`)
│   │   ├── User.cfc                # Staff accounts (`cms_users`)
│   │   ├── UserWorkspace.cfc       # User-workspace junction (`cms_user_workspaces`)
│   │   └── Workspace.cfc           # Municipal workspaces (`cms_workspaces`)
│   └── views/
│       ├── layout.cfm              # Master admin template, sidebar, header, active alert badge, modal dialogs
│       ├── helpers.cfm             # Global view helpers (svgIcon, badges)
│       ├── alerts/
│       │   └── index.cfm           # Emergency Alert Dispatch Studio (live banner simulator, presets, table)
│       ├── forms/
│       │   ├── builder.cfm         # Interactive 3-column Form Builder Studio
│       │   ├── index.cfm           # Forms management directory & template gallery
│       │   └── preview.cfm         # Standalone accessible public form intake
│       ├── pages/
│       │   ├── index.cfm           # Content Manager (All Pages) listing with multi-facet filters & Add Page modal
│       │   ├── edit.cfm            # Add / Edit Page editor with JBD editor, sub-pages & folder explorer
│       │   ├── folderExplorer.cfm  # Add Folder Explorer form (Title, Paths, Grid layouts)
│       │   └── howDoI.cfm          # "How Do I?" Directory Manager (categories, items, live 4-col preview)
│       ├── media/
│       │   ├── index.cfm           # Media Library directory (Grid & List, WCAG audit, Inspector)
│       │   ├── upload.cfm          # Dedicated Drag-and-Drop file upload studio
│       │   └── picker.cfm          # Standalone embeddable Media Picker dialog for editors
│       ├── users/
│       │   ├── index.cfm           # Users Directory, KPI stat cards, fast-action modal, inspector
│       │   ├── profile.cfm         # Staff Profile & Account Settings studio (personal info, password, prefs)
│       │   ├── roles.cfm           # Roles & Permissions studio, matrix, persona switcher
│       │   ├── new.cfm             # Add New Staff Account with interactive role radio cards
│       │   └── edit.cfm            # Edit Staff Member, role tier assignment & security flags
│       └── main/
│           └── index.cfm           # Dashboard KPI stats, recent content, quick draft
├── config/
│   ├── routes.cfm                  # RESTful & explicit controller/action route mappings
│   ├── environment.cfm             # Dynamic environment detector (dev vs prod)
│   ├── settings.cfm                # App settings, reload password configuration
│   └── sql/
│       ├── schema-complete.sql     # Compiled master SQL Server schema
│       ├── schema-emergency-alerts.sql # Emergency alerts DDL & filtered index
│       ├── schema-how-do-i.sql     # "How Do I?" categories & items SQL Server schema + Chelan County seed
│       ├── schema-pages.sql        # Pages relational DDL definitions
│       ├── schema-page-subpage.sql # Sub-pages relational DDL definitions
│       ├── schema-foldex-explorer.sql # Folder Explorer relational DDL definitions
│       ├── schema-navigation.sql   # Navigation menus relational DDL definitions
│       ├── schema-form-builder.sql # Form Builder relational DDL definitions
│       ├── schema-users-roles.sql  # Users & Roles schema DDL & seed dataset
│       └── schema-workspaces.sql   # Workspaces relational DDL definitions
├── files/                          # Root filesystem storage for workspaces & sites
├── javascripts/
│   ├── admin.js                    # Admin shell, workspace selector, custom dialogs (`adminAlert`, `adminConfirm`, `adminPrompt`), toasts
│   └── form-builder.js             # Canvas engine, property binding, preview, export
├── stylesheets/
│   ├── admin-theme.css             # Core design system tokens, WCAG AA focus, utilities
│   └── form-builder.css            # Studio grid, sticky scrolling panels, device canvas
├── CHECKPOINT.md                   # Latest engineering checkpoint & verification notes
├── Form-Builder.md                 # Form Builder technical architecture & database specs
├── NEXT-AI-PROMPT.md               # Continuation prompt for next AI session
├── PROMPT.md                       # Comprehensive prompt history & continuation guidelines
├── STATUS.md                       # Master project status & compliance documentation
└── TODO.md                         # Engineering roadmap & technical debt tracker
```

---

## ⏳ 7. Open Items & Next Milestones

1. **Feature 2.2: Page Revision History & Rollback Studio (RCW 42.56 Compliance)**:
   - Database schema: `dbo.page_revisions` (`id`, `page_id`, `version_number`, `title`, `content_html`, `summary`, `layout_type`, `meta_json`, `created_by`, `created_at`).
   - Automatically snapshot prior state on save in `Pages.cfc:save()`.
   - Add "Revision History" tab in the Page Editor with visual diff viewer and one-click rollback.
2. **Feature 1.1: Scaffold PIO Division Modules (Replace Placeholder Anchors)**:
   - Articles & Posts (`Articles.cfc`): Working CRUD routes for news, county blog posts, categories, and tags.
   - Press Releases & Media Alerts: Embargo dates, media contacts, and downloadable PDF attachments.
3. **Feature 2.3: In-Editor Automated ADA WCAG Pre-Flight Linter**:
   - Real-time pre-flight bar in `pages/edit.cfm` validating alt text quality, heading hierarchy, link text clarity, and table headers.
4. **Feature 2.4: Public Website API Layer & Mega-Menu Integration**:
   - Expose read-only REST/JSON endpoints (`/api/v1/how-do-i`, `/api/v1/navigation/menu`, `/api/v1/events/upcoming`) with cache management for `chelancounty.gov`.
5. **Feature 1.3: Media Library Database Metadata Persistence**:
   - Persist alt-text, captions, copyright, and ADA compliance tags to `dbo.media_assets` with SHA-256 duplicate detection.
