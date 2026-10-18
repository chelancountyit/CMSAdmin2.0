# Series 002: Activity Summary & Engineering Changelog
**Location:** `.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Executive Summary

This log maintains a chronological, permanent record of engineering milestones, schema migrations, architectural refinements, and verified features in Chelan County CMSAdmin 2.0. All AI agents and developers must append new activities to this log upon completing any significant change.

---

## 2. Chronological Milestones

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



