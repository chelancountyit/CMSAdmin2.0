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
| `dbo.cms_workspaces` | `id` (NVARCHAR) | Department workspaces, slugs, storage paths, and logos |
| `dbo.calendar_events` | `id` (INT) | Public meetings, commissioner hearings, county holidays |

---

## 4. Parameter Typing (`cfsqltype`) Guidelines

All queries must strictly pass typed parameters to prevent SQL injection and truncation errors:

- Integer IDs: `cf_sql_integer`
- Unicode Strings & HTML Content (`NVARCHAR` / `NVARCHAR(MAX)`): `cf_sql_nvarchar` (avoid `cf_sql_longvarchar` on `NVARCHAR(MAX)` columns as single-byte `VARCHAR` binding corrupts non-ASCII Unicode symbols into `?`)
- Timestamps: `cf_sql_timestamp`
- Bit Flags / Booleans: `cf_sql_bit`

