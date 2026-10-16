# Chelan County CMSAdmin 2.0 — Documentation Series Index
**Location:** `.doclib/`  
**Classification:** Core System Documentation & Knowledge Base  
**Mandatory Agent Instruction:** All AI assistants and automated coding agents (Antigravity, Gemini, Claude, Cursor, Copilot) MUST consult this index and referenced volumes before initiating architectural changes, adding features, or modifying database schemas.

---

## 📚 The .doclib Series Catalog

| Series # | Document Title | Primary Focus & Domain |
|---|---|---|
| **000** | [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md) | Master Catalog, AI Agent Protocols, and Documentation Architecture |
| **001** | [001_SYSTEM_ARCHITECTURE.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/001_SYSTEM_ARCHITECTURE.md) | Platform Stack (CFWheels 4.1.2, Lucee, IIS 10, SQL Server), Invariants & RBAC |
| **002** | [002_ACTIVITY_SUMMARY_AND_CHANGELOG.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md) | Granular Chronological Engineering Log, Implemented Modules & Live Milestones |
| **003** | [003_ACCESSIBILITY_WCAG21AA_LINTER.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/003_ACCESSIBILITY_WCAG21AA_LINTER.md) | ADA Title II & WCAG 2.1 AA Pre-Flight Linter Engine, Diagnostics & Quality Gates |
| **004** | [004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md) | Workspace-Scoped Media Explorer, Picker Overlay Modal & PostMessage Protocol |
| **005** | [005_ARTICLES_AND_PUBLIC_INFORMATION.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/005_ARTICLES_AND_PUBLIC_INFORMATION.md) | News & Articles Module, Cover Image ADA Suite, Taxonomy & Live Publishing |
| **006** | [006_PAGES_AND_REVISION_HISTORY_STUDIO.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/006_PAGES_AND_REVISION_HISTORY_STUDIO.md) | RCW 42.56 Public Records Revision Studio, Visual/Token Diff Engine & Rollback |
| **007** | [007_EMERGENCY_ALERTS_AND_INCIDENTS.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/007_EMERGENCY_ALERTS_AND_INCIDENTS.md) | Multi-Severity Emergency Banner Dispatch, Presets & Public API v1 Endpoint |
| **008** | [008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md) | SQL Server `ChelanCountyWebsite` Tables, Filtered Indexes (`Msg 1934`), & DDL Standards |
| **009** | [009_DEVELOPMENT_STANDARDS_AND_RULES.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/009_DEVELOPMENT_STANDARDS_AND_RULES.md) | Non-Negotiable Invariants: Zero CDN, No Native Dialogs, CSRF & UI Guidelines |

---

## 🤖 Instructions for AI Assistants

Whenever you are invoked in this codebase:
1. **Always Read This Index First:** Verify the active series numbers to identify the canonical source of truth for the subsystem you are touching.
2. **Consult [009_DEVELOPMENT_STANDARDS_AND_RULES.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/009_DEVELOPMENT_STANDARDS_AND_RULES.md):**
   - **Never** inject external JavaScript or CSS CDN links (`cdnjs`, `unpkg`, `jsdelivr`, `googleapis`, etc.).
   - **Never** invoke browser native dialogs (`alert()`, `confirm()`, `prompt()`). Always use `window.adminAlert()`, `window.adminConfirm()`, and `window.showToast()`.
   - **Never** run SQL Server DDL/DML without `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`.
3. **Log Your Work in [002_ACTIVITY_SUMMARY_AND_CHANGELOG.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md):**
   - Every major task, database change, or new module must be recorded in the chronological activity log with the date, files touched, and verification proof.
4. **Preserve Documentation Continuity:**
   - When creating new features that warrant dedicated documentation, add them as the next numbered series (e.g. `010_...md`) and link them here in `000_SERIES_INDEX.md`.

