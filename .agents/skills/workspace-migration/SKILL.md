---
name: workspace-migration
description: Extracts a legacy department workspace from co.chelan.wa.us/{workspace}, syncs its files, seeds the SQL Server ChelanCountyWebsite database for CMSAdmin 2.0, and scaffolds the CFWheels MVC controller, views, and routes on chelancounty.gov/{workspace} using ColdFusion IIS.
---

# Chelan County Department Workspace Migration Skill

Use this skill whenever asked to extract, migrate, or recreate a legacy department workspace from `https://www.co.chelan.wa.us/{workspace}` into **CMSAdmin 2.0** (`http://cmsadmin.chelancounty.gov`) and **ChelanCounty.gov** (`http://chelancounty.gov/{workspace}`).

## Core Invariants
1. **Runtime:** Always use **Adobe ColdFusion 2021 + IIS** (`http://chelancounty.gov` at `C:\inetpub\ChelanCounty.gov` and `http://cmsadmin.chelancounty.gov` at `C:\inetpub\CMSAdmin2.0`), never Lucee.
2. **Architecture:** Strictly follow **CFWheels MVC** conventions (Models in `app/models/`, Views in `app/views/{ws}/`, Controller in `app/controllers/{Dept}.cfc`, Routes in `config/routes.cfm`, and shared partials in `app/views/shared/_dept-*.cfm`).
3. **SQL Server Filtered Indexes:** Prepend all SQL Server queries touching tables with filtered indexes (`WHERE deletedat IS NULL`) with:
   ```sql
   SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
   ```

## Step-by-Step Workflow

1. **Read the Playbook:**
   Reference [`.doclib/013_WORKSPACE_MIGRATION_PLAYBOOK.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/013_WORKSPACE_MIGRATION_PLAYBOOK.md).

2. **Extract Content, Sync Media Files & Generate `{ws}_seed.json`:**
   Run [`C:\inetpub\CMSAdmin2.0\scripts\extract-legacy-workspace.ps1`](file:///c:/inetpub/CMSAdmin2.0/scripts/extract-legacy-workspace.ps1) with `powershell -ExecutionPolicy Bypass`:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\inetpub\CMSAdmin2.0\scripts\extract-legacy-workspace.ps1" `
       -WorkspaceCode "<ws>" `
       -DepartmentName "Chelan County <Dept>" `
       -OfficialFirstName "<First>" `
       -OfficialLastName "<Last>" `
       -OfficialTitle "<Title>" `
       -OfficialPhoto "<PhotoPath>" `
       -Phone "<Phone>" `
       -Fax "<Fax>" `
       -Email "<Email>" `
       -Address "<Address>" `
       -Address2 "<Suite>" `
       -Hours "<Hours>"
   ```
   Review and customize the `ctaCards`, `navigation`, and `howDoI` arrays in `C:\inetpub\ChelanCounty.gov\db\{ws}_seed.json`.

3. **Register CFWheels Routes (`C:\inetpub\ChelanCounty.gov\config\routes.cfm`):**
   Add the 6 routes (`/{ws}`, `/{ws}/page/[slug]`, `/{ws}/pages/[slug]`, `/{ws}/contacts`, `/{ws}/howdoi`, `/{ws}/file`) above `.wildcard()`.

4. **Create CFWheels Controller & Views:**
   - Clone [`app/controllers/Auditor.cfc`](file:///c:/inetpub/ChelanCounty.gov/app/controllers/Auditor.cfc) to `app/controllers/{Dept}.cfc` and call `ensureDepartmentWorkspaceSeed(siteid="{ws}", force=(StructKeyExists(params, "reseed") && params.reseed == "1"))`.
   - Clone `app/views/auditor/` (`index.cfm`, `page.cfm`, `contacts.cfm`, `howdoi.cfm`) to `app/views/{ws}/`.

5. **Reload & Seed via ColdFusion IIS:**
   ```powershell
   Invoke-WebRequest -Uri "http://chelancounty.gov/{ws}?reload=true&password=chelancms&reseed=1" -UseBasicParsing
   ```
   Verify HTTP 200 across `/{ws}`, all `/{ws}/page/{slug}` subpages, `/{ws}/contacts`, and `/{ws}/howdoi`, then log the milestone in [`.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md`](file:///c:/inetpub/CMSAdmin2.0/.doclib/002_ACTIVITY_SUMMARY_AND_CHANGELOG.md).

