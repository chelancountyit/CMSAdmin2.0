# Chelan County CMSAdmin 2.0 — AI System Instructions (GEMINI.md)

## 🚨 MANDATORY INSTRUCTION FOR ALL AI ASSISTANTS

**BEFORE ATTEMPTING ANY MODIFICATION, ARCHITECTURAL WORK, OR SCHEMA QUERY:**
You MUST read and reference the **`.doclib` Documentation Series** starting with:
👉 **[`.doclib/000_SERIES_INDEX.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)**

The `.doclib` series is the definitive book of record for Chelan County CMSAdmin 2.0.

---

### Non-Negotiable Invariants:
1. **Never use external CDNs:** All CSS, fonts, SVG icons, and JS must be local.
2. **Never use native browser dialogs:** `alert()`, `confirm()`, and `prompt()` are strictly forbidden. Always use `window.adminAlert()`, `window.adminConfirm()`, and `window.showToast()`.
3. **SQL Server Filtered Indexes:** Prepend all queries touching tables with filtered indexes (`WHERE deletedat IS NULL`) with:
   ```sql
   SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
   ```
4. **Always Log Significant Changes:** After completing a milestone, append the activity to [`.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md).

---

### Series Map:
- [000: Series Master Index & AI Protocols](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)
- [001: System Architecture & Stack Blueprint](file:///c:/inetpub/CMSAdmin2.0/.doclib/001_SYSTEM_ARCHITECTURE.md)
- [002: Activity Summary & Engineering Changelog](file:///c:/inetpub/CMSAdmin2.0/.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md)
- [003: Accessibility (ADA & WCAG 2.1 AA) Pre-Flight Linter](file:///c:/inetpub/CMSAdmin2.0/.doclib/003_ACCESSIBILITY_WCAG21AA_LINTER.md)
- [004: Media Library & Workspace File Explorer](file:///c:/inetpub/CMSAdmin2.0/.doclib/004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md)
- [005: Articles & Public Information Module](file:///c:/inetpub/CMSAdmin2.0/.doclib/005_ARTICLES_AND_PUBLIC_INFORMATION.md)
- [006: Pages & Revision History Rollback Studio](file:///c:/inetpub/CMSAdmin2.0/.doclib/006_PAGES_AND_REVISION_HISTORY_STUDIO.md)
- [007: Emergency Alerts & Incident Dispatch System](file:///c:/inetpub/CMSAdmin2.0/.doclib/007_EMERGENCY_ALERTS_AND_INCIDENTS.md)
- [008: Database Schema & SQL Server Standards](file:///c:/inetpub/CMSAdmin2.0/.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md)
- [009: Development Standards, Invariants & AI Guidelines](file:///c:/inetpub/CMSAdmin2.0/.doclib/009_DEVELOPMENT_STANDARDS_AND_RULES.md)

