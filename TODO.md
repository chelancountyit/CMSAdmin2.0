# CMSAdmin 2.0 — Engineering Roadmap & Technical Debt TODO

**Project:** Chelan County CMSAdmin 2.0  
**Host:** `http://cmsadmin.chelancounty.gov/`  
**Platform:** CFWheels 4.1.2 + Lucee CFML / IIS 10.0 + Microsoft SQL Server (`ChelanCountyWebsite`)  
**Compliance Standard:** ADA Title II, Section 508, WCAG 2.1 & 2.2 Level AA  
**Last Updated:** 2026-10-17  

---

## 🛠️ Phase 1: Remediation of Current Gaps & Technical Debt

Essential fixes to replace placeholder navigation, resolve volatile storage patterns, and complete stubbed controllers.

- [x] **1.1 Scaffold PIO Division Modules (Replace Placeholder Anchors)**
  - [x] **Articles & Posts Controller (`Articles.cfc`)**: Replace `#articles-all`, `#articles-new`, `#articles-categories`, `#articles-tags` in [`app/views/layout.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/layout.cfm#L633-L647) with working CRUD routes for news, county blog posts, categories, and tags.
  - [x] **Press Releases & Media Alerts**: Replace `#pio-press` with dedicated press release manager (embargo dates, media contacts, PDF attachments).
  - [x] **Emergency Alerts & Urgent Notices**: Replace `#pio-alerts` with an alert manager for public safety (wildfire levels, road closures, severe weather) — completed in Feature 2.1 (`/alerts`).
- [x] **1.2 Complete Administrative Settings Module (`Settings.cfc`)**
  - [x] Replace placeholder anchors in [`app/views/layout.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/layout.cfm#L740-L746) and expand [`Settings.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Settings.cfc):
    - [x] `General Settings` (`/settings/general`): County title, global contact info, timezone, maintenance mode.
    - [x] `Reading & SEO` (`/settings/seo`): Default meta tags, OpenGraph/Twitter card defaults, Google Analytics / GTM IDs, robots.txt rules.
    - [x] `Media Sizes` (`/settings/media`): Automatic image thumbnail dimensions and max upload size caps.
    - [x] `System Info & Diagnostics` (`/settings/system`): ColdFusion version, JVM memory allocation, SQL Server connection health, disk storage telemetry.
- [x] **1.3 Media Library Database Metadata Persistence (`dbo.media_assets`) & Universal Upload Integration**
  - [x] Transition [`Media.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Media.cfc) from filesystem-only directory scans to a persistent SQL Server table (`dbo.media_assets`).
  - [x] Persist alt-text, captions, copyright/credit, ADA audit flags, and workspace ownership to SQL Server.
  - [x] Store SHA-256 hashes to prevent duplicate file uploads.
  - [x] Universal upload entry points: Added direct upload button and inline slide-down upload panel across all instances of the Media Library (standalone explorer `/media/index`, modal picker `/media/picker`, explorer details panel, primary sidebar navigation submenu, dashboard media card, media settings card, and all picker modal headers across Page Editor, Article Editor, CTA Studio, and RFP Editor).
- [x] **1.4 Header Profile & Notifications Dropdown Functional Wiring**
  - [x] Replace `#profile` in [`layout.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/layout.cfm#L429-L432) with working `/users/profile` action allowing staff to update their display name, job title, phone, and 2FA settings.
  - [x] Replace mockup notification links (`#notif-1`, `#notif-2`, `#all-notifications`) with dynamic notifications driven by form submissions and editorial drafts.

---

## 🚀 Phase 2: Tier 1 High-Priority Features (Immediate Value & Compliance)

Mission-critical capabilities focused on public safety, regulatory compliance, and cross-site integration.

- [x] **2.1 Emergency Alert Banner & Incident Dispatch System**
  - [x] Database schema: `dbo.emergency_alerts` (`id`, `title`, `message`, `severity` [Critical/Red, Warning/Orange, Notice/Blue], `link_url`, `is_active`, `starts_at`, `expires_at`, `dismissible`, `created_by`, `site_id`).
  - [x] Quick-action toggle in admin header to activate/deactivate county-wide emergency banners in under 10 seconds.
  - [x] Pre-formatted incident presets: Wildfire Evacuation (Level 1 Get Ready, Level 2 Get Set, Level 3 Go Now), Winter Pass Closures, Flooding, and Courthouse Facility Closures.
  - [x] Fast JSON API endpoint (`/api/v1/alerts/active`) with caching for the public website header.
- [x] **2.2 Page Revision History & Rollback Studio (RCW 42.56 Compliance)**
  - [x] Database schema: `dbo.page_revisions` (`id`, `page_id`, `version_number`, `title`, `slug`, `content_html`, `summary`, `layout_type`, `meta_json`, `change_summary`, `created_by`, `created_at`) with foreign key cascade and nonclustered indexes.
  - [x] Automatically snapshot prior baseline state on initial access and prior/updated states on every save in [`Pages.cfc:save()`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Pages.cfc#L1250).
  - [x] "Revisions (vX)" button in Page Editor header with dynamic live badge counter and revision notes input.
  - [x] Interactive accessible modal studio (`#pgRevisionsModal`) with timeline cards (version, author, date/time, change note, size).
  - [x] Side-by-side & unified token diff viewer highlighting additions (green `<ins>`) and deletions (red `<del>`).
  - [x] Four distinct comparison modes: Visual Diff, Side-by-Side Split, Snapshot Preview, and Raw HTML code.
  - [x] One-click "Restore this Version" action with pre-rollback safety snapshot backup and `window.adminConfirm` verification.
- [x] **2.3 In-Editor Automated ADA WCAG Pre-Flight Linter**
  - [x] Real-time accessible audit bar in [`app/views/pages/edit.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/pages/edit.cfm) validating content before publish:
    - [x] Missing or empty `alt` attributes on embedded `<img>` tags (`WCAG 1.1.1`).
    - [x] Low-quality alt text (e.g. `alt="image.jpg"`, `alt="photo"`, filename patterns, or >150 chars).
    - [x] Broken heading hierarchy (e.g. skipping levels like `<h2>` to `<h4>`, multiple `<h1>` tags, empty headings).
    - [x] Ambiguous link text (flags "click here", "read more", "link" without descriptive text or aria-label), raw URLs, missing `rel="noopener noreferrer"` or screen reader notice for `target="_blank"`.
    - [x] Tables lacking semantic `<th>` column/row headers, missing `scope` attributes, or missing `<caption>` / `aria-label`.
    - [x] Inline low-contrast text styles (`#fff`, `#ccc`, `yellow`, etc. on light surfaces), extensive uppercase blocks (>50 chars), repetitive empty `<p>&nbsp;</p>` spacer blocks, and page meta title/description checks.
  - [x] Interactive Category Chips (`Images`, `Headings`, `Links`, `Tables`, `Readability`) with live error/warning counters.
  - [x] Collapsible diagnostic & quick-fix drawer (`#pgA11yIssuesDrawer`) with severity filter tabs (`All`, `Errors`, `Warnings`).
  - [x] "Locate in Editor" action: smoothly scrolls to problematic DOM element and triggers pulsating focus outline (`.jbd-a11y-pulse`).
  - [x] "Quick Fix" actions: convert first table row to `<th scope="col">`, prompt & set image alt/decorative attributes, add link aria-label or new-tab accessibility notice, correct skipped headings, and clean spacer blocks.
  - [x] Companion ADA scorecard in Publish sidebar (`#pgA11yPublishWidget`).
  - [x] Pre-flight save gate on form submit: intercepts public releases (`Visibility: Published` + `Status: Active`) when critical ADA violations exist, prompting author with `window.adminConfirm` to review or proceed.
- [x] **2.4 Call to Action (CTA) Studio, Grid Generator & Shortcode Engine**
  - [x] Management interface under Pages (`/pages/call-to-action`) with KPI statistics bar, live search, and category filter pills.
  - [x] Database schema: `dbo.page_call_to_actions` (`id`, `siteid`, `slug`, `title`, `short_description`, `image_path`, `button_text`, `button_icon`, `destination_url`, `open_in_new_tab`, `is_published`, `category`, `sort_order`, `deletedat`).
  - [x] Add/Edit CTA modal with real-time responsive preview card, Media Library file picker integration, and automatic workspace inheritance.
  - [x] Multi-Card Grid Builder modal for composite 2/3/4-column responsive shortcode generation (`[cta_grid slugs="..."]`).
  - [x] In-Editor shortcode insert modal (`#embedCtaModal`) in JBDEditor with multi-card selection and template integration.
  - [x] Shortcode resolver (`renderCallToActionShortcodes`) and `.jbd-cta-link` inline SVG icon rendering.
- [ ] **2.5 Public Website API Layer & Mega-Menu Integration**
  - [x] Pre-seeded 12 Standard Chelan County "How Do I" action categories (`dbo.how_do_i_categories`) with icons, descriptions, and sort orders; implemented self-healing auto-seed on table init and admin `prefillHowDoICategories` endpoint with UI actions in `/pages/how-do-i`.
  - [ ] Read-only REST/JSON endpoints for consumption by `chelancounty.gov`:
    - [ ] `GET /api/v1/how-do-i` (Categorized active items with `show_in_mega_menu = 1`).
    - [ ] `GET /api/v1/navigation/menu?code=main` (Hierarchical navigation structure).
    - [ ] `GET /api/v1/events/upcoming?limit=5` (Filtered calendar events).
  - [ ] In-memory caching (`application.apiCache`) with instant cache purge on admin save.

---

## 📋 Phase 3: Tier 2 Medium-Priority Features (Workflow & Operations)

Operational efficiencies that streamline multi-department publishing and media tracking.

- [ ] **3.1 Multi-Stage Editorial Workflow (Maker-Checker / Review Queues)**
  - [ ] Extend page and article statuses: `Draft` &rarr; `In Review` &rarr; `Approved` &rarr; `Published` &rarr; `Archived`.
  - [ ] Permissions gate: Authors submit drafts for review; PIO and Department Heads approve or request revisions.
  - [ ] In-app review drawer with editorial comments and email notification dispatch.
- [x] **3.2 Scheduled Publishing & Expiration Automation**
  - [x] Add `publish_at` and `unpublish_at` datetime fields to `pages`, `calendar_events`, `job_postings`, and `articles`.
  - [x] Scheduled background worker (or request-level evaluator) to transition items between scheduled, active, and archived states.
  - [x] Ideal for election dates, RFP bid closures, seasonal road advisories, and parks notices.
- [ ] **3.3 Media Asset Usage Cross-Referencing & Broken Link Guard**
  - [ ] Scan page bodies, sub-pages, events, and forms for referenced `/files/...` asset paths.
  - [ ] Display an "Attached To" list in the Media Inspector showing all pages using an asset.
  - [ ] Prevent or warn upon file deletion/renaming if an asset is currently embedded in active pages.
- [ ] **3.4 Public Records Request (PRR) Intake & Deadline Tracker**
  - [ ] Dedicated PRR intake form with statutory tracking under Washington State Public Records Act (RCW 42.56).
  - [ ] 5-business-day response deadline countdown timer with automated warnings.
  - [ ] Internal notes, status tracking (`Received`, `Under Review`, `Clarification Requested`, `Records Assembled`, `Closed`), and secure download package generation.
- [x] **3.5 RFP & Municipal Solicitations Manager (RCW 39.04, RCW 39.80, RCW 36.32)**
  - [x] Database Schema (`dbo.rfp_solicitations`, `dbo.rfp_addenda`, `dbo.rfp_planholders`, `dbo.rfp_bids`) with filtered nonclustered indexes.
  - [x] Full procurement classification: RFP (Proposals), RFQ (Qualifications under RCW 39.80), ITB (Call for Bids under RCW 39.04), SWR (Small Works Roster), and Sole Source Notices.
  - [x] Milestone & Deadline Engine with automated lock-out and Scheduled Worker integration (`Draft/Scheduled` -> `Open` -> `Under Review`).
  - [x] Sequenced Addenda Studio with Media Library Picker integration and change logs.
  - [x] Planholders Registry with self-registration, DBE tracking, duplicate prevention, and CSV export.
  - [x] Unsealed Bid Tabulation & Board of County Commissioners (BOCC) Contract Award Studio.
  - [x] Public Bid Board (`/bids`) and public solicitation dossiers (`/bids/view?slug=...`).

---

## 🔮 Phase 4: Tier 3 Strategic Municipal Enhancements

Long-term strategic enhancements for citizen engagement, administrative productivity, and security.

- [ ] **4.1 Bilingual / Spanish Language Translation Support**
  - [ ] Parallel language tabs (`English` | `Español`) in Page and Emergency Alert editors.
  - [ ] Multi-lingual schema support for "How Do I?" action questions.
  - [ ] Dedicated language toggle for public form intake.
- [ ] **4.2 Global Admin Command Palette (`Ctrl` + `K` Spotlight Search)**
  - [ ] Keyboard shortcut launcher (`Ctrl` + `K` / `Cmd` + `K`) rendered as a native accessible modal.
  - [ ] Instant search across all 11 departments and 4 portals:
    - [ ] Jump directly to edit any page or form by title/slug.
    - [ ] Quick-filter staff members by name or department.
    - [ ] Trigger actions: "New Page", "New Form", "Upload Media", "Switch Workspace".
- [ ] **4.3 Comprehensive Central Security & Audit Log**
  - [ ] Database table: `dbo.cms_audit_logs` (`id`, `user_id`, `user_email`, `action`, `module`, `record_id`, `ip_address`, `user_agent`, `details_json`, `created_at`).
  - [ ] Record login attempts, 2FA failures, role escalations, workspace switching, record deletions, and file uploads.
  - [ ] Filterable audit viewer under **Administration > Audit Trail**.
- [ ] **4.4 Automated Form Email Dispatch & Routing Engine**
  - [ ] Per-form notification recipient rules (route submissions by selected department, topic, or zip code).
  - [ ] Citizen confirmation auto-responder with submission reference number.
  - [ ] Support for secure SMTP or Microsoft Graph API (Microsoft 365 government tenant).

---

## 📐 Implementation Guidelines & Architecture Rules

When implementing any item above, maintain the strict engineering standards of the codebase:

1. **Zero External CSS/JS Libraries:** Native ES6+ and modern CSS custom properties (`admin-theme.css`) only.
2. **ADA Title II & WCAG 2.1/2.2 AA:** Explicit `<label for="...">`, 2px solid visible focus rings, $\ge 4.5:1$ text contrast, aria attributes, skip links, and semantic HTML.
3. **No Native Browser Dialogs:** Use `window.adminAlert()`, `window.adminConfirm()`, `window.adminPrompt()`, and `window.showToast()`. Keep custom modal z-index below `100000`.
4. **CFML & SQL Server Compatibility:**
   - All struct keys must be quoted before calling `SerializeJSON()`.
   - All `fetch()` POST requests must include `"X-Requested-With": "XMLHttpRequest"` and `"X-CSRF-Token"` (`meta[name="csrf-token"]`).
   - All SQL Server queries modifying tables with filtered indexes (`WHERE [deletedat] IS NULL`) must prepend `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;` and pass `value: ""` alongside `null: true` for nullable integer parameters.

