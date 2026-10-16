-- =============================================================================
-- Chelan County CMS Admin 2.0 - Page Revisions & Audit History Schema (RCW 42.56)
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Module: Washington State RCW 42.56 Public Records Compliance & Page Rollback
-- Safe to rerun: creates missing tables, indexes, and constraints.
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Checking Module: page_revisions...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[page_revisions]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[page_revisions] (
        [id]             INT IDENTITY(1,1) NOT NULL,
        [page_id]        INT NOT NULL,
        [version_number] INT NOT NULL,
        [title]          NVARCHAR(255) NOT NULL,
        [slug]           NVARCHAR(255) NULL,
        [content_html]   NVARCHAR(MAX) NULL,
        [summary]        NVARCHAR(MAX) NULL,
        [layout_type]    NVARCHAR(50) NOT NULL CONSTRAINT [DF_page_rev_layout] DEFAULT ('Full'),
        [meta_json]      NVARCHAR(MAX) NULL,
        [change_summary] NVARCHAR(500) NULL,
        [created_by]     NVARCHAR(255) NOT NULL CONSTRAINT [DF_page_rev_author] DEFAULT ('System'),
        [created_at]     DATETIME2(7) NOT NULL CONSTRAINT [DF_page_rev_created] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_page_revisions] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [FK_page_revisions_pages] FOREIGN KEY ([page_id]) REFERENCES [dbo].[pages] ([ContentID]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_page_revisions_page_version' AND object_id = OBJECT_ID(N'[dbo].[page_revisions]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_page_revisions_page_version]
    ON [dbo].[page_revisions] ([page_id] ASC, [version_number] DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_page_revisions_created' AND object_id = OBJECT_ID(N'[dbo].[page_revisions]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_page_revisions_created]
    ON [dbo].[page_revisions] ([page_id] ASC, [created_at] DESC);
END;
GO

