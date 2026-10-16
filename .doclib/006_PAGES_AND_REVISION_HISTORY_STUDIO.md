# Series 006: Pages & Revision History Rollback Studio
**Location:** `.doclib/006_PAGES_AND_REVISION_HISTORY_STUDIO.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Overview & Statutory Mandate

Under **RCW 42.56 (Washington State Public Records Act)**, government websites must maintain immutable historical audit trails of published pages, administrative changes, and public notices. 

The CMSAdmin 2.0 **Pages Module** integrates a comprehensive **Revision History & Rollback Studio** directly within the page editor ([`app/views/pages/edit.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/pages/edit.cfm)).

---

## 2. Database Schema: `dbo.page_revisions`

Schema file: [`config/sql/schema-page-revisions.sql`](file:///c:/inetpub/CMSAdmin2.0/config/sql/schema-page-revisions.sql).

```sql
CREATE TABLE dbo.page_revisions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    page_id INT NOT NULL,
    version_number INT NOT NULL,
    title NVARCHAR(255) NULL,
    slug NVARCHAR(255) NULL,
    content_html NVARCHAR(MAX) NULL,
    summary NVARCHAR(MAX) NULL,
    layout_type NVARCHAR(50) NULL,
    meta_json NVARCHAR(MAX) NULL,
    change_summary NVARCHAR(500) NULL,
    created_by NVARCHAR(255) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_page_revisions_pages FOREIGN KEY (page_id) 
        REFERENCES pages(ContentID) ON DELETE CASCADE
);

CREATE NONCLUSTERED INDEX IX_page_revisions_page_version 
ON dbo.page_revisions (page_id, version_number DESC);

CREATE NONCLUSTERED INDEX IX_page_revisions_created 
ON dbo.page_revisions (page_id, created_at DESC);
```

---

## 3. Snapshotting & Rollback Lifecycle

1. **Baseline Snapshotting:**
   - When an unversioned page is loaded in `/pages/edit`, `Pages.cfc` immediately captures a Version 1 baseline snapshot.
2. **Save Snapshotting:**
   - Every save action increments `version_number`, snapshots the full content, stores optional `changeSummary` revision notes, and records the active user.
3. **Pre-Rollback Safety Snapshot:**
   - Prior to restoring any historical version, `Pages.cfc:restoreRevision()` captures a safety backup snapshot of the current working draft (`"Pre-rollback snapshot before restoring version X"`).
4. **Live Restoration:**
   - The selected snapshot is applied to `pages`, and a new version is created representing the restored state (`"Restored from version X"`).

---

## 4. The Interactive Rollback Studio (`#pgRevisionsModal`)

The Rollback Studio UI provides an accessible comparison modal:

1. **Chronological Timeline:**
   - Displays all historical versions with version pills, timestamps, authors, byte sizes, and change notes.
2. **Word/Token LCS Diff Engine:**
   - Computes granular additions (`<ins class="diff-add">`) and deletions (`<del class="diff-del">`) between the selected snapshot and the current working draft.
3. **4 Comparison Modes:**
   - **Visual Diff:** Inline document view showing formatted changes.
   - **Side-by-Side Split:** Two-column comparative layout.
   - **Snapshot Preview:** Clean rendered preview of the historical page.
   - **HTML Code:** Monospace syntax view with diff highlighting.
4. **Accessible Confirmation:**
   - Uses `window.adminConfirm` to verify rollback intent and explain the automated safety snapshot.

