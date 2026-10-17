-- =============================================================================
-- Chelan County CMS Admin 2.0 - Pages Relational Database Schema
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Modules: Pages Directory, Add/Edit Page Studio, Folder Explorer & Subpages
-- Workspace Scoping: Multi-Tenant Site/Department Scoping (SiteID)
-- Safe to rerun: creates missing Pages tables, indexes, and constraints only.
-- Existing objects and data are preserved.
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1. Table: dbo.pages
-- Primary entity for county pages, landing pages, and service articles
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[pages] (
        -- Primary Key & Scoping
        [ContentID]            INT IDENTITY(1,1) NOT NULL,
        [SiteID]               NVARCHAR(100) NOT NULL CONSTRAINT [DF_pages_SiteID] DEFAULT (N'global'),
        
        -- Page Routing & Assignment
        [PageType]             TINYINT NOT NULL CONSTRAINT [DF_pages_PageType] DEFAULT (0),  -- 0: Top Level (URL route), 1: Assigned to Menu Item
        [MenuSelected]         NVARCHAR(255) NULL,                                          -- Selected Navigation Menu Item label/target
        [LayoutType]           NVARCHAR(50) NOT NULL CONSTRAINT [DF_pages_LayoutType] DEFAULT (N'Full'), -- 'Full', 'Right Sidebar'
        [ParentID]             INT NOT NULL CONSTRAINT [DF_pages_ParentID] DEFAULT (0),     -- Parent ContentID (0 if root page)
        [StatusCode]           NVARCHAR(50) NOT NULL CONSTRAINT [DF_pages_StatusCode] DEFAULT (N'Active'), -- 'Active', 'Inactive'
        [Permalink]            NVARCHAR(255) NOT NULL,                                      -- URL Slug (e.g., 'title-vi-plan', 'budget-hearings')
        [Title]                NVARCHAR(255) NOT NULL,                                      -- Page Title / Main Heading

        -- SEO & Search Metadata
        [MetaTitle]            NVARCHAR(255) NULL,                                          -- Browser tab / SERP title (up to 65 chars recommended)
        [MetaDesc]             NVARCHAR(MAX) NULL,                                          -- Meta description for search engines & previews
        [MetaKeyWords]         NVARCHAR(500) NULL,                                          -- Comma-separated SEO keywords
        [Summary]              NVARCHAR(MAX) NULL,                                          -- Short teaser / excerpt for directory cards and feeds

        -- Page Content & Rich Media
        [Body]                 NVARCHAR(MAX) NULL,                                          -- Main WYSIWYG HTML content

        -- Featured Image & Attachment (Hero Media)
        [imageAttachment]      NVARCHAR(500) NULL,                                          -- Virtual path to media asset in files/[siteid]/media/
        [imageAttribution]     NVARCHAR(255) NULL,                                          -- Photo credit / copyright attribution
        [imageAlt]             NVARCHAR(255) NULL,                                          -- ADA Title II / WCAG AA accessible alternative text
        [imageTitle]           NVARCHAR(255) NULL,                                          -- Image tooltip / descriptive title
        [imageDescription]     NVARCHAR(MAX) NULL,                                          -- Detailed caption or long description
        [imageDecorative]      BIT NOT NULL CONSTRAINT [DF_pages_imageDecorative] DEFAULT (0), -- WCAG 2.1 H67 decorative image flag

        -- Classification & Features
        [isService]            BIT NOT NULL CONSTRAINT [DF_pages_isService] DEFAULT (0),    -- 1 if public county citizen service, 0 otherwise
        [hasArchive]           BIT NOT NULL CONSTRAINT [DF_pages_hasArchive] DEFAULT (0),   -- 1 if "Add Folder Explorer" is checked / active
        [ShowInMenu]           BIT NOT NULL CONSTRAINT [DF_pages_ShowInMenu] DEFAULT (0),   -- 1 if "Show in main menu" top navigation toggle is enabled
        [isLocked]             BIT NOT NULL CONSTRAINT [DF_pages_isLocked] DEFAULT (0),     -- 1 for protected system pages (Home, Terms, 404)
        [SidebarIDs]           NVARCHAR(MAX) NULL,                                          -- JSON array or delimited list of assigned sidebar widgets
        [SortOrder]            INT NOT NULL CONSTRAINT [DF_pages_SortOrder] DEFAULT (0),    -- Display order among siblings

        -- Publication Workflow & Scheduling
        [isPublished]          BIT NOT NULL CONSTRAINT [DF_pages_isPublished] DEFAULT (1),  -- 1 if published, 0 if draft/unpublished
        [Visibility]           NVARCHAR(50) NOT NULL CONSTRAINT [DF_pages_Visibility] DEFAULT (N'Published'), -- 'Published', 'Draft', 'Scheduled', 'Hidden'
        [PublishAt]            DATETIME2(7) NULL,                                           -- Scheduled publication timestamp

        -- Telemetry & Analytics
        [ViewCount]            INT NOT NULL CONSTRAINT [DF_pages_ViewCount] DEFAULT (0),

        -- Audit Trail & Timestamps
        [Created]              DATETIME2(7) NOT NULL CONSTRAINT [DF_pages_Created] DEFAULT (SYSUTCDATETIME()),
        [CreatedBy]            NVARCHAR(255) NULL,
        [Modified]             DATETIME2(7) NULL,
        [ModifiedBy]           NVARCHAR(255) NULL,
        [DeletedAt]            DATETIME2(7) NULL,                                           -- Soft delete timestamp for permanent record protection
        [DeletedBy]            NVARCHAR(255) NULL,

        CONSTRAINT [PK_pages] PRIMARY KEY CLUSTERED ([ContentID] ASC)
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 2. Indexes for Performance & Data Integrity
-- -----------------------------------------------------------------------------
-- Slug uniqueness per workspace (different departments can use same slug, but not inside same workspace)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_pages_SiteID_Permalink' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_pages_SiteID_Permalink] 
        ON [dbo].[pages] ([SiteID] ASC, [Permalink] ASC)
        WHERE [DeletedAt] IS NULL;
END;
GO

-- Fast workspace filtering
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_pages_SiteID_Status' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_pages_SiteID_Status] 
        ON [dbo].[pages] ([SiteID] ASC, [StatusCode] ASC, [Visibility] ASC)
        INCLUDE ([Title], [Permalink], [PageType], [ParentID], [isPublished], [Modified]);
END;
GO

-- Fast hierarchy traversal (ParentID lookup)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_pages_ParentID' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_pages_ParentID] 
        ON [dbo].[pages] ([SiteID] ASC, [ParentID] ASC, [SortOrder] ASC);
END;
GO

-- Service directories index
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_pages_isService' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_pages_isService] 
        ON [dbo].[pages] ([SiteID] ASC, [isService] ASC)
        WHERE [isService] = 1 AND [DeletedAt] IS NULL;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. Foreign Key Integrity for Child Modules (Folder Explorer & SubPages)
-- -----------------------------------------------------------------------------
-- Link page_FolderExplorer.ContentID to pages.ContentID (if page_FolderExplorer exists)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[page_FolderExplorer]') AND type in (N'U'))
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = N'FK_page_FolderExplorer_pages')
BEGIN
    ALTER TABLE [dbo].[page_FolderExplorer] WITH CHECK
        ADD CONSTRAINT [FK_page_FolderExplorer_pages] FOREIGN KEY ([ContentID])
        REFERENCES [dbo].[pages] ([ContentID])
        ON DELETE CASCADE;
END;
GO

-- Link page_SubPage.ContentID to pages.ContentID (if page_SubPage exists)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[page_SubPage]') AND type in (N'U'))
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = N'FK_page_SubPage_pages')
BEGIN
    ALTER TABLE [dbo].[page_SubPage] WITH CHECK
        ADD CONSTRAINT [FK_page_SubPage_pages] FOREIGN KEY ([ContentID])
        REFERENCES [dbo].[pages] ([ContentID])
        ON DELETE CASCADE;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. Verification Check
-- -----------------------------------------------------------------------------
SELECT 
    c.name AS [ColumnName],
    t.name AS [DataType],
    c.max_length AS [MaxLength],
    c.is_nullable AS [IsNullable],
    d.definition AS [DefaultValue]
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
LEFT JOIN sys.default_constraints d ON c.default_object_id = d.object_id
WHERE c.object_id = OBJECT_ID(N'dbo.pages')
ORDER BY c.column_id;
GO

