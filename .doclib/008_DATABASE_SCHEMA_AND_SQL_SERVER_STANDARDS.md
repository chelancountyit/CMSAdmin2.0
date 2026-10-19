# Series 008: Database Schema & SQL Server Standards
**Location:** `.doclib/008_DATABASE_SCHEMA_AND_SQL_SERVER_STANDARDS.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Relational Database Overview

- **Datasource:** `ChelanCountyWebsite`
- **RDBMS Engine:** Microsoft SQL Server 2019 / 2022
- **Query Execution:** Exclusively via CFML `queryExecute()` with parameterized structs (`cfsqltype`).

---

## 2. Mandatory SQL Server Invariant (Msg 1934 Prevention)

The tables in `ChelanCountyWebsite` make heavy use of **filtered nonclustered indexes** with `WHERE deletedat IS NULL` to ensure uniqueness while supporting soft deletes.

> [!CAUTION]
> SQL Server strictly requires `QUOTED_IDENTIFIER` and `ANSI_NULLS` to be `ON` for any query that touches a table containing filtered indexes. Failing to prepend these flags causes queries to fail with:
> `Msg 1934, Level 16, State 1: INSERT failed because the following SET options have forbidden settings: 'QUOTED_IDENTIFIER, ANSI_NULLS'.`

### Standard Query Template:
```sql
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
INSERT INTO articles (
    title, slug, content_html, ...
) VALUES (
    :title, :slug, :content_html, ...
);
```

---

## 3. Core Relational Tables

| Table Name | Primary Key | Description |
|---|---|---|
| `dbo.pages` | `ContentID` (INT) | Primary hierarchical site pages, templates, subpages |
| `dbo.page_revisions` | `id` (INT) | RCW 42.56 historical snapshots, visual diffs, and rollback backups |
| `dbo.page_call_to_actions` | `id` (INT) | Call to Action (CTA) cards, grid shortcodes, and service links |
| `dbo.articles` | `id` (INT) | News stories, press updates, ADA cover photos, taxonomies |
| `dbo.article_categories` | `id` (INT) | Department categories with badge colors and slug routing |
| `dbo.article_tags` | `id` (INT) | Searchable keyword tags indexed by workspace |
| `dbo.emergency_alerts` | `id` (INT) | Emergency public safety incident banners and presets |
| `dbo.how_do_i_items` | `id` (INT) | Quick citizen navigation shortcuts & mega-menu links |
| `dbo.cms_users` | `id` (INT) | Administrative users, 2FA authenticator secrets, active roles |
| `dbo.cms_workspaces` | `id` (INT IDENTITY) | Department workspaces, slugs, storage paths, domains, and logos |
| `dbo.calendar_events` | `id` (INT) | Public meetings, commissioner hearings, county holidays |

---

## 4. Parameter Typing (`cfsqltype`) Guidelines

All queries must strictly pass typed parameters to prevent SQL injection and truncation errors:

- Integer IDs: `cf_sql_integer`
- Unicode Strings & HTML Content (`NVARCHAR` / `NVARCHAR(MAX)`): `cf_sql_nvarchar` (avoid `cf_sql_longvarchar` on `NVARCHAR(MAX)` columns as single-byte `VARCHAR` binding corrupts non-ASCII Unicode symbols into `?`)
- Timestamps: `cf_sql_timestamp`
- Bit Flags / Booleans: `cf_sql_bit`

---

## 5. `dbo.cms_workspaces` Schema Definition

The `cms_workspaces` table isolates and scopes municipal department content, media repositories, and public website domains.

```sql
CREATE TABLE dbo.cms_workspaces (
    id                   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    code                 NVARCHAR(50) NOT NULL,
    name                 NVARCHAR(150) NOT NULL,
    alias                NVARCHAR(50) NULL,
    type                 NVARCHAR(20) NOT NULL DEFAULT 'dept', -- 'dept', 'site', 'global'
    badge                NVARCHAR(50) NULL,
    badge_class          NVARCHAR(50) NULL,
    icon                 NVARCHAR(50) NULL,
    description          NVARCHAR(500) NULL,
    folder_path          NVARCHAR(255) NULL,
    virtual_directory    NVARCHAR(100) NULL,
    redirect_url         NVARCHAR(255) NULL,
    department           NVARCHAR(150) NULL,
    department_category  NVARCHAR(100) NULL,
    storage_path         NVARCHAR(255) NULL,  -- Dedicated file repository path (e.g. 'files/assessor')
    domain_name          NVARCHAR(255) NULL,  -- Canonical website hostname (e.g. 'www.chelancounty.gov')
    project_path         NVARCHAR(255) NULL,  -- Server application codebase directory (e.g. 'C:\inetpub\chelan-county')
    leadership_type      NVARCHAR(20) NULL DEFAULT 'dept_head', -- Leadership tier: 'elected' (Elected Official) or 'dept_head' (Department Head)
    job_title            NVARCHAR(150) NULL,  -- Executive or official title (e.g. 'County Assessor', 'Director of Community Development')
    contact_photo        NVARCHAR(500) NULL,  -- Profile photo or avatar image URL path (e.g. '/files/assessor/images/aswang.jpg')
    contact_first_name   NVARCHAR(100) NULL,
    contact_last_name    NVARCHAR(100) NULL,
    contact_email        NVARCHAR(150) NULL,
    contact_phone        NVARCHAR(50) NULL,
    contact_fax          NVARCHAR(50) NULL,
    address              NVARCHAR(255) NULL,
    address2             NVARCHAR(255) NULL,
    city                 NVARCHAR(100) NULL DEFAULT 'Wenatchee',
    state                NVARCHAR(50) NULL DEFAULT 'WA',
    zip                  NVARCHAR(20) NULL DEFAULT '98801',
    office_hours         NVARCHAR(500) NULL,
    color                NVARCHAR(20) NULL DEFAULT '#0073AA',
    is_active            BIT NOT NULL DEFAULT 1,
    is_system            BIT NOT NULL DEFAULT 0,
    sort_order           INT NOT NULL DEFAULT 100,
    createdat            DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedat            DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    deletedat            DATETIME2(7) NULL
);
```


