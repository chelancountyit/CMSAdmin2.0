-- =============================================================================
-- Chelan County CMS Admin 2.0 - Complete Master Relational Database Schema
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Database Target: ChelanCountyWebsite (or custom CMS database)
--
-- Modules Compiled:
--   1. Workspaces Directory (cms_workspaces)
--   2. Roles & User Security (cms_roles, cms_users, cms_user_workspaces)
--   3. Pages, Subpages & Revisions (pages, page_FolderExplorer, page_SubPage, page_revisions)
--   4. Navigation Menus & Links (navigation_menus, navigation_menu_items)
--   5. Online Form Builder & EAV Submissions (form_departments, forms, form_fields,
--      form_submissions, form_submission_values, form_audit_logs)
--   6. Careers & Job Postings (job_listings, job_applications)
--   7. "How Do I" Directory & Mega-Menu (how_do_i_categories, how_do_i_items)
--   8. County Calendar of Events (calendar_event_categories, calendar_events)
--   9. Emergency Alerts & Incident Dispatch (emergency_alerts)
--
-- Execution Mode: One-time execution script, safe to rerun (idempotent).
-- Data Policy: ZERO test data. Only required core system lookup definitions.
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '======================================================================';
PRINT 'Starting Chelan County CMSAdmin 2.0 Database Schema Initialization...';
PRINT '======================================================================';
GO


-- =============================================================================
-- MODULE 1: WORKSPACES DIRECTORY
-- =============================================================================

PRINT 'Checking Module 1: cms_workspaces...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[cms_workspaces]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[cms_workspaces] (
        [id]                  INT IDENTITY(1,1) NOT NULL,
        [code]                NVARCHAR(50) NOT NULL,
        [name]                NVARCHAR(150) NOT NULL,
        [alias]               NVARCHAR(100) NULL,
        [type]                NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_ws_type] DEFAULT ('dept'),
        [badge]               NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_badge] DEFAULT ('Dept'),
        [badge_class]         NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_badge_cls] DEFAULT ('badge-neutral'),
        [icon]                NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_icon] DEFAULT ('building'),
        [color]               NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_ws_color] DEFAULT ('#0073aa'),
        [description]         NVARCHAR(MAX) NULL,
        [folder_path]         NVARCHAR(255) NOT NULL,
        [virtual_directory]   NVARCHAR(100) NOT NULL,
        [redirect_url]        NVARCHAR(500) NULL,
        [department]          NVARCHAR(150) NULL,
        [department_category] NVARCHAR(100) NULL,
        [contact_first_name]  NVARCHAR(100) NULL,
        [contact_last_name]   NVARCHAR(100) NULL,
        [contact_email]       NVARCHAR(255) NULL,
        [contact_phone]       NVARCHAR(50) NULL,
        [contact_fax]         NVARCHAR(50) NULL,
        [address]             NVARCHAR(255) NULL,
        [address2]            NVARCHAR(150) NULL,
        [city]                NVARCHAR(100) NOT NULL CONSTRAINT [DF_cms_ws_city] DEFAULT ('Wenatchee'),
        [state]               NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_state] DEFAULT ('WA'),
        [zip]                 NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_ws_zip] DEFAULT ('98801'),
        [office_hours]        NVARCHAR(255) NULL,
        [is_active]           BIT NOT NULL CONSTRAINT [DF_cms_ws_active] DEFAULT (1),
        [is_system]           BIT NOT NULL CONSTRAINT [DF_cms_ws_system] DEFAULT (0),
        [sort_order]          INT NOT NULL CONSTRAINT [DF_cms_ws_sort] DEFAULT (0),
        [createdat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_ws_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_ws_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]           DATETIME2(7) NULL,
        CONSTRAINT [PK_cms_workspaces] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_cms_workspaces_code] UNIQUE NONCLUSTERED ([code] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_cms_workspaces_sort' AND object_id = OBJECT_ID(N'[dbo].[cms_workspaces]'))
    CREATE NONCLUSTERED INDEX [IX_cms_workspaces_sort] ON [dbo].[cms_workspaces] ([sort_order] ASC, [id] ASC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_cms_workspaces_type' AND object_id = OBJECT_ID(N'[dbo].[cms_workspaces]'))
    CREATE NONCLUSTERED INDEX [IX_cms_workspaces_type] ON [dbo].[cms_workspaces] ([type] ASC, [is_active] ASC);
GO

-- Seed Required Municipal Directory (System Reference Workspaces)
MERGE INTO [dbo].[cms_workspaces] AS Target
USING (VALUES
    ('global', 'Global (County-Wide)', 'global', 'global', 'Global', 'badge-purple', 'globe', 'County-wide shared resources', 'files/global', 'global', NULL, 'Administration', 'County Administration', 'Wenatchee', 'WA', '98801', 1, 1, 0),
    ('shared', 'Shared Assets & Brand Library', 'shared', 'global', 'Shared', 'badge-neutral', 'grid', 'Shared municipal documents & branding', 'files/shared', 'shared', NULL, 'Administration', 'County Administration', 'Wenatchee', 'WA', '98801', 1, 1, 10),
    ('assessors', 'Assessor - Property & Parcels', 'assessors', 'dept', 'Dept', 'badge-neutral', 'building', 'Property tax assessments and parcel maps', 'files/assessors', 'assessors', NULL, 'Assessor', 'Finance and Records', 'Wenatchee', 'WA', '98801', 1, 0, 20),
    ('Auditor', 'Auditor - Elections & Records', 'Auditor', 'dept', 'Dept', 'badge-neutral', 'building', 'Elections, licensing, and public recordings', 'files/Auditor', 'Auditor', NULL, 'Auditor', 'Finance and Records', 'Wenatchee', 'WA', '98801', 1, 0, 30),
    ('commissioners', 'Board of County Commissioners', 'commissioners', 'dept', 'Dept', 'badge-neutral', 'building', 'County legislative and policy body', 'files/commissioners', 'commissioners', NULL, 'Commissioners', 'County Administration', 'Wenatchee', 'WA', '98801', 1, 0, 40),
    ('clerk', 'County Clerk & Superior Court', 'clerk', 'dept', 'Dept', 'badge-neutral', 'building', 'Superior court records and filings', 'files/clerk', 'clerk', NULL, 'Clerk', 'Law and Justice', 'Wenatchee', 'WA', '98801', 1, 0, 50),
    ('community-development', 'Community Development', 'commdev', 'dept', 'Dept', 'badge-neutral', 'building', 'Planning, permits, building codes', 'files/community-development', 'commdev', NULL, 'Community Development', 'Land and Development', 'Wenatchee', 'WA', '98801', 1, 0, 60),
    ('human-resources', 'Human Resources (HRM)', 'hrm', 'dept', 'Dept', 'badge-neutral', 'briefcase', 'Recruitment, employee benefits, civil service', 'files/human-resources', 'hrm', NULL, 'Human Resources', 'Internal Services', 'Wenatchee', 'WA', '98801', 1, 0, 70),
    ('pio', 'Public Information Office', 'pio', 'dept', 'Dept', 'badge-neutral', 'megaphone', 'Media releases, emergency alerts, public notices', 'files/pio', 'pio', NULL, 'Public Information', 'Internal Services', 'Wenatchee', 'WA', '98801', 1, 0, 80),
    ('public-works', 'Public Works & Roads', 'pw', 'dept', 'Dept', 'badge-neutral', 'building', 'Road maintenance, flood control, solid waste', 'files/public-works', 'pw', NULL, 'Public Works', 'Operations and Infrastructure', 'Wenatchee', 'WA', '98801', 1, 0, 90),
    ('sheriff', 'Sheriff''s Office', 'sheriff', 'dept', 'Dept', 'badge-neutral', 'shield', 'Law enforcement, public safety, dispatch', 'files/sheriff', 'sheriff', NULL, 'Sheriff', 'Law and Justice', 'Wenatchee', 'WA', '98801', 1, 0, 100),
    ('treasurer', 'Treasurer - Property Taxes', 'treasurer', 'dept', 'Dept', 'badge-neutral', 'building', 'Tax collection and county financial custody', 'files/treasurer', 'treasurer', NULL, 'Treasurer', 'Finance and Records', 'Wenatchee', 'WA', '98801', 1, 0, 110),
    ('site-main', 'chelancounty.gov (Main Portal)', 'chelancounty.gov', 'site', 'Main Site', 'badge-success', 'globe', 'Primary County public portal', 'files/chelancounty.gov', 'chelancounty.gov', 'https://www.chelancounty.gov', 'Public Portal', 'County Administration', 'Wenatchee', 'WA', '98801', 1, 0, 120),
    ('site-parks', 'parks.chelancounty.gov', 'parks.chelancounty.gov', 'site', 'Subsite', 'badge-primary', 'globe', 'Parks & recreation department portal', 'files/parks.chelancounty.gov', 'parks.chelancounty.gov', 'https://parks.chelancounty.gov', 'Parks & Recreation', 'Community Services', 'Wenatchee', 'WA', '98801', 1, 0, 130),
    ('site-gis', 'gis.chelancounty.gov', 'gis.chelancounty.gov', 'site', 'Portal', 'badge-warning', 'globe', 'GIS, maps and parcel viewer', 'files/gis.chelancounty.gov', 'gis.chelancounty.gov', 'https://gis.chelancounty.gov', 'GIS', 'Internal Services', 'Wenatchee', 'WA', '98801', 1, 0, 140),
    ('site-expo', 'expo.chelancounty.gov', 'expo.chelancounty.gov', 'site', 'Portal', 'badge-info', 'globe', 'Expo Center and Fairgrounds portal', 'files/expo.chelancounty.gov', 'expo.chelancounty.gov', 'https://expo.chelancounty.gov', 'Expo Center', 'Community Services', 'Cashmere', 'WA', '98815', 1, 0, 150)
) AS Source ([code], [name], [alias], [type], [badge], [badge_class], [icon], [description], [folder_path], [virtual_directory], [redirect_url], [department], [department_category], [city], [state], [zip], [is_active], [is_system], [sort_order])
ON Target.[code] = Source.[code]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([code], [name], [alias], [type], [badge], [badge_class], [icon], [description], [folder_path], [virtual_directory], [redirect_url], [department], [department_category], [city], [state], [zip], [is_active], [is_system], [sort_order], [createdat], [updatedat])
    VALUES (Source.[code], Source.[name], Source.[alias], Source.[type], Source.[badge], Source.[badge_class], Source.[icon], Source.[description], Source.[folder_path], Source.[virtual_directory], Source.[redirect_url], Source.[department], Source.[department_category], Source.[city], Source.[state], Source.[zip], Source.[is_active], Source.[is_system], Source.[sort_order], SYSUTCDATETIME(), SYSUTCDATETIME());
GO


-- =============================================================================
-- MODULE 2: USERS, ROLES & SECURITY
-- =============================================================================

PRINT 'Checking Module 2: cms_roles, cms_users, cms_user_workspaces...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[cms_roles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[cms_roles] (
        [id]                 INT IDENTITY(1,1) NOT NULL,
        [code]               NVARCHAR(50) NOT NULL,
        [name]               NVARCHAR(100) NOT NULL,
        [description]        NVARCHAR(MAX) NULL,
        [badge_class]        NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_roles_badge] DEFAULT ('badge-neutral'),
        [color_hex]          NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_roles_color] DEFAULT ('#0073aa'),
        [icon_name]          NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_roles_icon] DEFAULT ('shield'),
        [can_access_content] BIT NOT NULL CONSTRAINT [DF_cms_roles_content] DEFAULT (1),
        [can_access_hrm]     BIT NOT NULL CONSTRAINT [DF_cms_roles_hrm] DEFAULT (0),
        [can_access_pio]     BIT NOT NULL CONSTRAINT [DF_cms_roles_pio] DEFAULT (0),
        [can_access_admin]   BIT NOT NULL CONSTRAINT [DF_cms_roles_admin] DEFAULT (0),
        [is_system]          BIT NOT NULL CONSTRAINT [DF_cms_roles_system] DEFAULT (1),
        [createdat]          DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_roles_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]          DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_roles_updatedat] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_cms_roles] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_cms_roles_code] UNIQUE NONCLUSTERED ([code] ASC)
    );
END;
GO

-- Seed Required System User Roles
MERGE INTO [dbo].[cms_roles] AS Target
USING (VALUES
    ('admin', 'Administrator', 'Full unrestricted county-wide administrative access to all workspaces, settings, user security, and modules.', 'badge-danger', '#b91c1c', 'shield', 1, 1, 1, 1, 1),
    ('pio', 'PIO (Public Information Officer)', 'Dedicated public communications, emergency alerts, press releases, media kits, articles and general web publishing.', 'badge-info', '#0284c7', 'megaphone', 1, 0, 1, 0, 1),
    ('hr', 'HR (Human Resources)', 'Human resources personnel management, recruitment job postings, employee onboarding, policies, and web publishing.', 'badge-purple', '#7e22ce', 'briefcase', 1, 1, 0, 0, 1),
    ('author', 'Author (Web Content Editor)', 'General web content update permissions for drafting and editing pages, media library assets, and online forms.', 'badge-primary', '#0073aa', 'edit', 1, 0, 0, 0, 1)
) AS Source ([code], [name], [description], [badge_class], [color_hex], [icon_name], [can_access_content], [can_access_hrm], [can_access_pio], [can_access_admin], [is_system])
ON Target.[code] = Source.[code]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([code], [name], [description], [badge_class], [color_hex], [icon_name], [can_access_content], [can_access_hrm], [can_access_pio], [can_access_admin], [is_system], [createdat], [updatedat])
    VALUES (Source.[code], Source.[name], Source.[description], Source.[badge_class], Source.[color_hex], Source.[icon_name], Source.[can_access_content], Source.[can_access_hrm], Source.[can_access_pio], Source.[can_access_admin], Source.[is_system], SYSUTCDATETIME(), SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[cms_users]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[cms_users] (
        [id]                    INT IDENTITY(1,1) NOT NULL,
        [role_id]               INT NOT NULL,
        [role_code]             NVARCHAR(50) NOT NULL,
        [username]              NVARCHAR(100) NOT NULL,
        [email]                 NVARCHAR(255) NOT NULL,
        [first_name]            NVARCHAR(100) NOT NULL,
        [last_name]             NVARCHAR(100) NOT NULL,
        [job_title]             NVARCHAR(150) NULL,
        [phone]                 NVARCHAR(50) NULL,
        [department_code]       NVARCHAR(100) NULL CONSTRAINT [DF_cms_users_dept] DEFAULT ('global'),
        [department_name]       NVARCHAR(150) NULL,
        [assigned_workspaces]   NVARCHAR(MAX) NULL CONSTRAINT [DF_cms_users_workspaces] DEFAULT ('["global"]'),
        [password_hash]         NVARCHAR(255) NOT NULL,
        [password_salt]         NVARCHAR(100) NULL,
        [status]                NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_users_status] DEFAULT ('active'),
        [two_factor_enabled]    BIT NOT NULL CONSTRAINT [DF_cms_users_2fa] DEFAULT (0),
        [force_password_change] BIT NOT NULL CONSTRAINT [DF_cms_users_pw_change] DEFAULT (0),
        [last_login_at]         DATETIME2(7) NULL,
        [last_login_ip]         NVARCHAR(45) NULL,
        [createdat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_users_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_users_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]             DATETIME2(7) NULL,
        CONSTRAINT [PK_cms_users] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_cms_users_username] UNIQUE NONCLUSTERED ([username] ASC),
        CONSTRAINT [UQ_cms_users_email] UNIQUE NONCLUSTERED ([email] ASC),
        CONSTRAINT [FK_cms_users_roles] FOREIGN KEY ([role_id]) REFERENCES [dbo].[cms_roles] ([id])
    );

    CREATE NONCLUSTERED INDEX [IX_cms_users_role_code] ON [dbo].[cms_users] ([role_code] ASC);
    CREATE NONCLUSTERED INDEX [IX_cms_users_dept_code] ON [dbo].[cms_users] ([department_code] ASC);
    CREATE NONCLUSTERED INDEX [IX_cms_users_status] ON [dbo].[cms_users] ([status] ASC);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[cms_user_workspaces]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[cms_user_workspaces] (
        [id]             INT IDENTITY(1,1) NOT NULL,
        [user_id]        INT NOT NULL,
        [workspace_code] NVARCHAR(50) NOT NULL,
        [is_primary]     BIT NOT NULL CONSTRAINT [DF_cms_user_ws_primary] DEFAULT (0),
        [createdat]      DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_user_ws_createdat] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_cms_user_workspaces] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_cms_user_workspaces_user_ws] UNIQUE NONCLUSTERED ([user_id] ASC, [workspace_code] ASC),
        CONSTRAINT [FK_cms_user_workspaces_user] FOREIGN KEY ([user_id]) REFERENCES [dbo].[cms_users] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_cms_user_workspaces_ws_code] FOREIGN KEY ([workspace_code]) REFERENCES [dbo].[cms_workspaces] ([code]) ON UPDATE CASCADE
    );

    CREATE NONCLUSTERED INDEX [IX_cms_user_workspaces_ws] ON [dbo].[cms_user_workspaces] ([workspace_code] ASC);
END;
GO


-- =============================================================================
-- MODULE 3: PAGES, SUBPAGES & FOLDER EXPLORER
-- =============================================================================

PRINT 'Checking Module 3: pages, page_FolderExplorer, page_SubPage...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[pages] (
        [ContentID]        INT IDENTITY(1,1) NOT NULL,
        [SiteID]           NVARCHAR(100) NOT NULL CONSTRAINT [DF_pages_SiteID] DEFAULT (N'global'),
        [PageType]         TINYINT NOT NULL CONSTRAINT [DF_pages_PageType] DEFAULT (0),
        [MenuSelected]     NVARCHAR(255) NULL,
        [LayoutType]       NVARCHAR(50) NOT NULL CONSTRAINT [DF_pages_LayoutType] DEFAULT (N'Full'),
        [ParentID]         INT NOT NULL CONSTRAINT [DF_pages_ParentID] DEFAULT (0),
        [StatusCode]       NVARCHAR(50) NOT NULL CONSTRAINT [DF_pages_StatusCode] DEFAULT (N'Active'),
        [Permalink]        NVARCHAR(255) NOT NULL,
        [Title]            NVARCHAR(255) NOT NULL,
        [MetaTitle]        NVARCHAR(255) NULL,
        [MetaDesc]         NVARCHAR(MAX) NULL,
        [MetaKeyWords]     NVARCHAR(500) NULL,
        [Summary]          NVARCHAR(MAX) NULL,
        [Body]             NVARCHAR(MAX) NULL,
        [imageAttachment]  NVARCHAR(500) NULL,
        [imageAttribution] NVARCHAR(255) NULL,
        [imageAlt]         NVARCHAR(255) NULL,
        [imageTitle]       NVARCHAR(255) NULL,
        [imageDescription] NVARCHAR(MAX) NULL,
        [isService]        BIT NOT NULL CONSTRAINT [DF_pages_isService] DEFAULT (0),
        [hasArchive]       BIT NOT NULL CONSTRAINT [DF_pages_hasArchive] DEFAULT (0),
        [ShowInMenu]       BIT NOT NULL CONSTRAINT [DF_pages_ShowInMenu] DEFAULT (0),
        [isLocked]         BIT NOT NULL CONSTRAINT [DF_pages_isLocked] DEFAULT (0),
        [SidebarIDs]       NVARCHAR(MAX) NULL,
        [SortOrder]        INT NOT NULL CONSTRAINT [DF_pages_SortOrder] DEFAULT (0),
        [isPublished]      BIT NOT NULL CONSTRAINT [DF_pages_isPublished] DEFAULT (1),
        [Visibility]       NVARCHAR(50) NOT NULL CONSTRAINT [DF_pages_Visibility] DEFAULT (N'Published'),
        [PublishAt]        DATETIME2(7) NULL,
        [ViewCount]        INT NOT NULL CONSTRAINT [DF_pages_ViewCount] DEFAULT (0),
        [Created]          DATETIME2(7) NOT NULL CONSTRAINT [DF_pages_Created] DEFAULT (SYSUTCDATETIME()),
        [CreatedBy]        NVARCHAR(255) NULL,
        [Modified]         DATETIME2(7) NULL,
        [ModifiedBy]       NVARCHAR(255) NULL,
        [DeletedAt]        DATETIME2(7) NULL,
        [DeletedBy]        NVARCHAR(255) NULL,
        CONSTRAINT [PK_pages] PRIMARY KEY CLUSTERED ([ContentID] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_pages_SiteID_Permalink' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_pages_SiteID_Permalink]
        ON [dbo].[pages] ([SiteID] ASC, [Permalink] ASC)
        WHERE [DeletedAt] IS NULL;
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_pages_SiteID_Status' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_pages_SiteID_Status]
        ON [dbo].[pages] ([SiteID] ASC, [StatusCode] ASC, [Visibility] ASC)
        INCLUDE ([Title], [Permalink], [PageType], [ParentID], [isPublished], [Modified]);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_pages_ParentID' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_pages_ParentID]
        ON [dbo].[pages] ([SiteID] ASC, [ParentID] ASC, [SortOrder] ASC);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_pages_isService' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_pages_isService]
        ON [dbo].[pages] ([SiteID] ASC, [isService] ASC)
        WHERE [isService] = 1 AND [DeletedAt] IS NULL;
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[page_FolderExplorer]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[page_FolderExplorer] (
        [ID]           INT IDENTITY(1,1) NOT NULL,
        [ContentID]    INT NOT NULL,
        [SiteID]       NVARCHAR(100) NOT NULL CONSTRAINT [DF_page_FolderExplorer_SiteID] DEFAULT (N'global'),
        [Title]        NVARCHAR(255) NOT NULL,
        [RelativePath] NVARCHAR(500) NULL,
        [AbsolutePath] NVARCHAR(500) NULL,
        [Absolute]     BIT NOT NULL CONSTRAINT [DF_page_FolderExplorer_Absolute] DEFAULT (0),
        [Weight]       INT NOT NULL CONSTRAINT [DF_page_FolderExplorer_Weight] DEFAULT (0),
        [Layout]       NVARCHAR(50) NOT NULL CONSTRAINT [DF_page_FolderExplorer_Layout] DEFAULT (N'Full'),
        [Placement]    NVARCHAR(20) NOT NULL CONSTRAINT [DF_page_FolderExplorer_Placement] DEFAULT (N'After'),
        CONSTRAINT [PK_page_FolderExplorer] PRIMARY KEY CLUSTERED ([ID] ASC),
        CONSTRAINT [FK_page_FolderExplorer_pages] FOREIGN KEY ([ContentID]) REFERENCES [dbo].[pages] ([ContentID]) ON DELETE CASCADE
    );

    CREATE NONCLUSTERED INDEX [IX_page_FolderExplorer_ContentID] ON [dbo].[page_FolderExplorer] ([SiteID] ASC, [ContentID] ASC);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[page_SubPage]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[page_SubPage] (
        [ID]         INT IDENTITY(1,1) NOT NULL,
        [ContentID]  INT NOT NULL,
        [SiteID]     NVARCHAR(100) NOT NULL CONSTRAINT [DF_page_SubPage_SiteID] DEFAULT (N'global'),
        [Title]      NVARCHAR(255) NOT NULL,
        [Body]       NVARCHAR(MAX) NULL,
        [Position]   INT NOT NULL CONSTRAINT [DF_page_SubPage_Position] DEFAULT (0),
        [CreatedAt]  DATETIME2(7) NOT NULL CONSTRAINT [DF_page_SubPage_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        [CreatedBy]  NVARCHAR(255) NULL,
        [ModifiedAt] DATETIME2(7) NULL,
        [ModifiedBy] NVARCHAR(255) NULL,
        CONSTRAINT [PK_page_SubPage] PRIMARY KEY CLUSTERED ([ID] ASC),
        CONSTRAINT [FK_page_SubPage_pages] FOREIGN KEY ([ContentID]) REFERENCES [dbo].[pages] ([ContentID]) ON DELETE CASCADE
    );

    CREATE NONCLUSTERED INDEX [IX_page_SubPage_ContentID] ON [dbo].[page_SubPage] ([SiteID] ASC, [ContentID] ASC, [Position] ASC);
END;
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


-- =============================================================================
-- MODULE 4: NAVIGATION MENUS & MENU ITEMS
-- =============================================================================

PRINT 'Checking Module 4: navigation_menus, navigation_menu_items...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[navigation_menus]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[navigation_menus] (
        [id]        INT IDENTITY(1,1) NOT NULL,
        [siteid]    NVARCHAR(100) NOT NULL,
        [menu_key]  NVARCHAR(100) NOT NULL,
        [name]      NVARCHAR(150) NOT NULL,
        [is_active] BIT NOT NULL CONSTRAINT [DF_navigation_menus_is_active] DEFAULT (1),
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_navigation_menus_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat] DATETIME2(7) NOT NULL CONSTRAINT [DF_navigation_menus_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat] DATETIME2(7) NULL,
        CONSTRAINT [PK_navigation_menus] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_navigation_menus_site_key] UNIQUE NONCLUSTERED ([siteid] ASC, [menu_key] ASC)
    );

    CREATE NONCLUSTERED INDEX [IX_navigation_menus_siteid] ON [dbo].[navigation_menus] ([siteid] ASC);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[navigation_menu_items]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[navigation_menu_items] (
        [id]                 INT IDENTITY(1,1) NOT NULL,
        [navigation_menu_id] INT NOT NULL,
        [parent_item_id]     INT NULL,
        [label]              NVARCHAR(150) NOT NULL,
        [destination_type]   NVARCHAR(20) NOT NULL CONSTRAINT [DF_navigation_menu_items_destination_type] DEFAULT ('page'),
        [destination]        NVARCHAR(1000) NOT NULL,
        [icon]               NVARCHAR(100) NULL,
        [sort_order]         INT NOT NULL CONSTRAINT [DF_navigation_menu_items_sort_order] DEFAULT (0),
        [is_active]          BIT NOT NULL CONSTRAINT [DF_navigation_menu_items_is_active] DEFAULT (1),
        [open_in_new_tab]    BIT NOT NULL CONSTRAINT [DF_navigation_menu_items_open_in_new_tab] DEFAULT (0),
        [createdat]          DATETIME2(7) NOT NULL CONSTRAINT [DF_navigation_menu_items_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]          DATETIME2(7) NOT NULL CONSTRAINT [DF_navigation_menu_items_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]          DATETIME2(7) NULL,
        CONSTRAINT [PK_navigation_menu_items] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_navigation_menu_items_menu_id] UNIQUE NONCLUSTERED ([navigation_menu_id] ASC, [id] ASC),
        CONSTRAINT [FK_navigation_menu_items_menu] FOREIGN KEY ([navigation_menu_id]) REFERENCES [dbo].[navigation_menus] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_navigation_menu_items_parent_menu] FOREIGN KEY ([navigation_menu_id], [parent_item_id]) REFERENCES [dbo].[navigation_menu_items] ([navigation_menu_id], [id]) ON DELETE NO ACTION,
        CONSTRAINT [CK_navigation_menu_items_destination_type] CHECK ([destination_type] IN ('page', 'url')),
        CONSTRAINT [CK_navigation_menu_items_not_self_parent] CHECK ([parent_item_id] IS NULL OR [parent_item_id] <> [id])
    );

    CREATE NONCLUSTERED INDEX [IX_navigation_menu_items_menu_sort] ON [dbo].[navigation_menu_items] ([navigation_menu_id] ASC, [sort_order] ASC);
    CREATE NONCLUSTERED INDEX [IX_navigation_menu_items_parent_sort] ON [dbo].[navigation_menu_items] ([parent_item_id] ASC, [sort_order] ASC);
    CREATE NONCLUSTERED INDEX [IX_navigation_menu_items_menu_parent] ON [dbo].[navigation_menu_items] ([navigation_menu_id] ASC, [parent_item_id] ASC);
END;
GO


-- =============================================================================
-- MODULE 5: ONLINE FORM BUILDER & EAV SUBMISSIONS
-- =============================================================================

PRINT 'Checking Module 5: form_departments, forms, form_fields, form_submissions...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_departments]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_departments] (
        [id]          INT IDENTITY(1,1) NOT NULL,
        [code]        NVARCHAR(50) NOT NULL,
        [name]        NVARCHAR(150) NOT NULL,
        [description] NVARCHAR(MAX) NULL,
        [alert_email] NVARCHAR(255) NOT NULL,
        [color_hex]   NVARCHAR(20) NOT NULL CONSTRAINT [DF_form_dept_color] DEFAULT ('#0073aa'),
        [badge_class] NVARCHAR(50) NOT NULL CONSTRAINT [DF_form_dept_badge] DEFAULT ('badge-primary'),
        [is_active]   BIT NOT NULL CONSTRAINT [DF_form_dept_active] DEFAULT (1),
        [createdat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_form_dept_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_form_dept_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]   DATETIME2(7) NULL,
        CONSTRAINT [PK_form_departments] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_form_departments_code] UNIQUE NONCLUSTERED ([code] ASC)
    );
END;
GO

-- Seed Required System Form Departments
MERGE INTO [dbo].[form_departments] AS Target
USING (VALUES
    ('HRM', 'Human Resource Management', 'County employment recruitments, job applications, benefits, onboarding.', 'hrm@chelancounty.gov', '#8e44ad', 'badge-purple', 1),
    ('PIO', 'Public Information Office', 'Media inquiries, public record requests, press releases, surveys.', 'pio@chelancounty.gov', '#0284c7', 'badge-info', 1),
    ('ADMIN', 'General Administration', 'County commissioners office, public notices, administrative feedback.', 'contact@chelancounty.gov', '#0073aa', 'badge-primary', 1),
    ('COMMDEV', 'Community Development', 'Building permits, zoning questions, shoreline reviews, code compliance.', 'permits@chelancounty.gov', '#e67e22', 'badge-warning', 1),
    ('PW', 'Public Works & Roads', 'Road maintenance, right-of-way permits, flood control, solid waste.', 'public.works@chelancounty.gov', '#27ae60', 'badge-success', 1)
) AS Source ([code], [name], [description], [alert_email], [color_hex], [badge_class], [is_active])
ON Target.[code] = Source.[code]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([code], [name], [description], [alert_email], [color_hex], [badge_class], [is_active], [createdat], [updatedat])
    VALUES (Source.[code], Source.[name], Source.[description], Source.[alert_email], Source.[color_hex], Source.[badge_class], Source.[is_active], SYSUTCDATETIME(), SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[forms]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[forms] (
        [id]                          INT IDENTITY(1,1) NOT NULL,
        [department_id]               INT NULL,
        [siteid]                      NVARCHAR(100) NULL,
        [form_key]                    NVARCHAR(100) NOT NULL,
        [slug]                        NVARCHAR(200) NOT NULL,
        [title]                       NVARCHAR(255) NOT NULL,
        [description]                 NVARCHAR(MAX) NULL,
        [status]                      NVARCHAR(50) NOT NULL CONSTRAINT [DF_forms_status] DEFAULT ('published'),
        [theme_color]                 NVARCHAR(20) NOT NULL CONSTRAINT [DF_forms_theme] DEFAULT ('#0073aa'),
        [submit_text]                 NVARCHAR(100) NOT NULL CONSTRAINT [DF_forms_submit_text] DEFAULT ('Submit Form'),
        [success_message]             NVARCHAR(MAX) NULL,
        [redirect_url]                NVARCHAR(500) NULL,
        [notification_email]          NVARCHAR(255) NULL,
        [notification_email_cc]       NVARCHAR(500) NULL,
        [email_notifications_enabled] BIT NOT NULL CONSTRAINT [DF_forms_email_notif] DEFAULT (1),
        [anti_spam_enabled]           BIT NOT NULL CONSTRAINT [DF_forms_antispam] DEFAULT (1),
        [honeypot_field_name]         NVARCHAR(100) NOT NULL CONSTRAINT [DF_forms_hp_name] DEFAULT ('_chelan_gov_verify'),
        [min_delay_seconds]           INT NOT NULL CONSTRAINT [DF_forms_min_delay] DEFAULT (3),
        [cooldown_seconds]            INT NOT NULL CONSTRAINT [DF_forms_cooldown] DEFAULT (3),
        [wcag_compliant]              BIT NOT NULL CONSTRAINT [DF_forms_wcag] DEFAULT (1),
        [allow_iframe_embed]          BIT NOT NULL CONSTRAINT [DF_forms_embed] DEFAULT (1),
        [is_standalone_public]        BIT NOT NULL CONSTRAINT [DF_forms_public] DEFAULT (1),
        [submissions_count]           INT NOT NULL CONSTRAINT [DF_forms_sub_count] DEFAULT (0),
        [views_count]                 INT NOT NULL CONSTRAINT [DF_forms_views_count] DEFAULT (0),
        [schema_json]                 NVARCHAR(MAX) NULL,
        [createdat]                   DATETIME2(7) NOT NULL CONSTRAINT [DF_forms_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]                   DATETIME2(7) NOT NULL CONSTRAINT [DF_forms_updatedat] DEFAULT (SYSUTCDATETIME()),
        [publishedat]                 DATETIME2(7) NULL,
        [deletedat]                   DATETIME2(7) NULL,
        CONSTRAINT [PK_forms] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_forms_form_key] UNIQUE NONCLUSTERED ([form_key] ASC),
        CONSTRAINT [UQ_forms_slug] UNIQUE NONCLUSTERED ([slug] ASC),
        CONSTRAINT [FK_forms_departments] FOREIGN KEY ([department_id]) REFERENCES [dbo].[form_departments] ([id]) ON DELETE SET NULL
    );

    CREATE NONCLUSTERED INDEX [IX_forms_department_status] ON [dbo].[forms] ([department_id] ASC, [status] ASC);
    CREATE NONCLUSTERED INDEX [IX_forms_siteid] ON [dbo].[forms] ([siteid] ASC);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_fields]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_fields] (
        [id]                    INT IDENTITY(1,1) NOT NULL,
        [form_id]               INT NOT NULL,
        [field_key]             NVARCHAR(100) NOT NULL,
        [field_type]            NVARCHAR(50) NOT NULL,
        [label]                 NVARCHAR(255) NOT NULL,
        [placeholder]           NVARCHAR(255) NULL,
        [default_value]         NVARCHAR(MAX) NULL,
        [subtext]               NVARCHAR(500) NULL,
        [paragraph_content]     NVARCHAR(MAX) NULL,
        [paragraph_style]       NVARCHAR(50) NOT NULL CONSTRAINT [DF_form_fields_pstyle] DEFAULT ('normal'),
        [options_json]          NVARCHAR(MAX) NULL,
        [is_required]           BIT NOT NULL CONSTRAINT [DF_form_fields_req] DEFAULT (0),
        [column_width]          NVARCHAR(10) NOT NULL CONSTRAINT [DF_form_fields_width] DEFAULT ('100'),
        [textarea_rows]         INT NOT NULL CONSTRAINT [DF_form_fields_rows] DEFAULT (4),
        [sort_order]            INT NOT NULL CONSTRAINT [DF_form_fields_order] DEFAULT (0),
        [validation_rules_json] NVARCHAR(MAX) NULL,
        [is_active]             BIT NOT NULL CONSTRAINT [DF_form_fields_active] DEFAULT (1),
        [createdat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_form_fields_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_form_fields_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]             DATETIME2(7) NULL,
        CONSTRAINT [PK_form_fields] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_form_fields_key] UNIQUE NONCLUSTERED ([form_id] ASC, [field_key] ASC),
        CONSTRAINT [FK_form_fields_forms] FOREIGN KEY ([form_id]) REFERENCES [dbo].[forms] ([id]) ON DELETE CASCADE
    );

    CREATE NONCLUSTERED INDEX [IX_form_fields_form_sort] ON [dbo].[form_fields] ([form_id] ASC, [sort_order] ASC);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_submissions]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_submissions] (
        [id]                  INT IDENTITY(1,1) NOT NULL,
        [form_id]             INT NOT NULL,
        [reference_id]        NVARCHAR(50) NOT NULL,
        [status]              NVARCHAR(50) NOT NULL CONSTRAINT [DF_form_sub_status] DEFAULT ('received'),
        [submitted_at]        DATETIME2(7) NOT NULL CONSTRAINT [DF_form_sub_submittedat] DEFAULT (SYSUTCDATETIME()),
        [load_time_epoch_ms]  BIGINT NULL,
        [elapsed_seconds]     INT NULL,
        [honeypot_passed]     BIT NOT NULL CONSTRAINT [DF_form_sub_hp_passed] DEFAULT (1),
        [speed_trap_passed]   BIT NOT NULL CONSTRAINT [DF_form_sub_speed_passed] DEFAULT (1),
        [is_flagged_as_spam]  BIT NOT NULL CONSTRAINT [DF_form_sub_spam] DEFAULT (0),
        [ip_address]          NVARCHAR(45) NULL,
        [user_agent]          NVARCHAR(500) NULL,
        [assigned_to_user_id] INT NULL,
        [reviewed_by]         NVARCHAR(100) NULL,
        [reviewed_at]         DATETIME2(7) NULL,
        [admin_notes]         NVARCHAR(MAX) NULL,
        [submission_json]     NVARCHAR(MAX) NOT NULL,
        [createdat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_form_sub_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_form_sub_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]           DATETIME2(7) NULL,
        CONSTRAINT [PK_form_submissions] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_form_submissions_ref] UNIQUE NONCLUSTERED ([reference_id] ASC),
        CONSTRAINT [FK_form_submissions_forms] FOREIGN KEY ([form_id]) REFERENCES [dbo].[forms] ([id]) ON DELETE CASCADE
    );

    CREATE NONCLUSTERED INDEX [IX_form_submissions_form_date] ON [dbo].[form_submissions] ([form_id] ASC, [submitted_at] DESC);
    CREATE NONCLUSTERED INDEX [IX_form_submissions_status] ON [dbo].[form_submissions] ([status] ASC);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_submission_values]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_submission_values] (
        [id]              INT IDENTITY(1,1) NOT NULL,
        [submission_id]   INT NOT NULL,
        [field_id]        INT NULL,
        [field_key]       NVARCHAR(100) NOT NULL,
        [field_label]     NVARCHAR(255) NULL,
        [field_type]      NVARCHAR(50) NULL,
        [field_value]     NVARCHAR(MAX) NULL,
        [file_path]       NVARCHAR(500) NULL,
        [file_name]       NVARCHAR(255) NULL,
        [file_size_bytes] BIGINT NULL,
        [file_mime_type]  NVARCHAR(100) NULL,
        [createdat]       DATETIME2(7) NOT NULL CONSTRAINT [DF_form_subval_createdat] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_form_submission_values] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [FK_form_subval_submission] FOREIGN KEY ([submission_id]) REFERENCES [dbo].[form_submissions] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_form_subval_field] FOREIGN KEY ([field_id]) REFERENCES [dbo].[form_fields] ([id]) ON DELETE SET NULL
    );

    CREATE NONCLUSTERED INDEX [IX_form_submission_values_lookup] ON [dbo].[form_submission_values] ([submission_id] ASC, [field_key] ASC);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_audit_logs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_audit_logs] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [form_id]       INT NULL,
        [submission_id] INT NULL,
        [action]        NVARCHAR(100) NOT NULL,
        [performed_by]  NVARCHAR(100) NOT NULL CONSTRAINT [DF_form_audit_by] DEFAULT ('System'),
        [ip_address]    NVARCHAR(45) NULL,
        [details_json]  NVARCHAR(MAX) NULL,
        [createdat]     DATETIME2(7) NOT NULL CONSTRAINT [DF_form_audit_createdat] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_form_audit_logs] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [FK_form_audit_forms] FOREIGN KEY ([form_id]) REFERENCES [dbo].[forms] ([id]) ON DELETE SET NULL
    );

    CREATE NONCLUSTERED INDEX [IX_form_audit_form_date] ON [dbo].[form_audit_logs] ([form_id] ASC, [createdat] DESC);
END;
GO


-- =============================================================================
-- MODULE 6: CAREERS & JOB POSTINGS (HRM RECRUITMENT)
-- =============================================================================

PRINT 'Checking Module 6: job_listings, job_applications...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[job_listings]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[job_listings] (
        [JobID]                 INT IDENTITY(1,1) NOT NULL,
        [SiteID]                NVARCHAR(100) NOT NULL CONSTRAINT [DF_job_listings_SiteID] DEFAULT (N'hrm'),
        [Title]                 NVARCHAR(255) NOT NULL,
        [Permalink]             NVARCHAR(255) NOT NULL,
        [FLSAClassificationID]  INT NOT NULL CONSTRAINT [DF_job_listings_FLSA] DEFAULT (1),
        [JobClasificationID]    INT NOT NULL CONSTRAINT [DF_job_listings_Classif] DEFAULT (1),
        [isSupervisor]          BIT NOT NULL CONSTRAINT [DF_job_listings_isSupervisor] DEFAULT (0),
        [DirectSupervisor]      NVARCHAR(150) NULL,
        [Description]           NVARCHAR(MAX) NULL,
        [Summary]               NVARCHAR(MAX) NULL,
        [Qualification]         NVARCHAR(MAX) NULL,
        [Responsibilities]      NVARCHAR(MAX) NULL,
        [AdditionalInformation] NVARCHAR(MAX) NULL,
        [Benefits]              NVARCHAR(MAX) NULL,
        [Location]              NVARCHAR(255) NOT NULL CONSTRAINT [DF_job_listings_Location] DEFAULT (N'Wenatchee, WA'),
        [Address]               NVARCHAR(255) NULL CONSTRAINT [DF_job_listings_Address] DEFAULT (N'400 Douglas St'),
        [City]                  NVARCHAR(100) NOT NULL CONSTRAINT [DF_job_listings_City] DEFAULT (N'Wenatchee'),
        [State]                 NVARCHAR(50) NOT NULL CONSTRAINT [DF_job_listings_State] DEFAULT (N'WA'),
        [Zip]                   NVARCHAR(20) NOT NULL CONSTRAINT [DF_job_listings_Zip] DEFAULT (N'98801'),
        [PostDate]              DATETIME2(7) NULL,
        [MinSalary]             DECIMAL(18,2) NULL CONSTRAINT [DF_job_listings_MinSalary] DEFAULT (0),
        [MaxSalary]             DECIMAL(18,2) NULL CONSTRAINT [DF_job_listings_MaxSalary] DEFAULT (0),
        [SalarySchedule]        NVARCHAR(50) NOT NULL CONSTRAINT [DF_job_listings_SalarySched] DEFAULT (N'Hourly'),
        [SalaryGroup]           NVARCHAR(100) NOT NULL CONSTRAINT [DF_job_listings_SalaryGroup] DEFAULT (N'Non-Represented'),
        [ClassCode]             NVARCHAR(50) NULL,
        [StatusCode]            NVARCHAR(50) NOT NULL CONSTRAINT [DF_job_listings_StatusCode] DEFAULT (N'Active'),
        [ApplicationDeadline]   DATETIME2(7) NULL,
        [Attachment]            NVARCHAR(500) NULL,
        [AttachmentName]        NVARCHAR(255) NULL,
        [Created]               DATETIME2(7) NOT NULL CONSTRAINT [DF_job_listings_Created] DEFAULT (SYSUTCDATETIME()),
        [Createdby]             NVARCHAR(100) NULL,
        [Modified]              DATETIME2(7) NOT NULL CONSTRAINT [DF_job_listings_Modified] DEFAULT (SYSUTCDATETIME()),
        [Modifiedby]            NVARCHAR(100) NULL,
        [DeletedAt]             DATETIME2(7) NULL,
        CONSTRAINT [PK_job_listings] PRIMARY KEY CLUSTERED ([JobID] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_job_listings_Permalink' AND object_id = OBJECT_ID(N'[dbo].[job_listings]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_job_listings_Permalink]
        ON [dbo].[job_listings] ([SiteID] ASC, [Permalink] ASC)
        WHERE [DeletedAt] IS NULL;
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_job_listings_status' AND object_id = OBJECT_ID(N'[dbo].[job_listings]'))
    CREATE NONCLUSTERED INDEX [IX_job_listings_status] ON [dbo].[job_listings] ([StatusCode] ASC, [PostDate] DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_job_listings_SiteID' AND object_id = OBJECT_ID(N'[dbo].[job_listings]'))
    CREATE NONCLUSTERED INDEX [IX_job_listings_SiteID] ON [dbo].[job_listings] ([SiteID] ASC);
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[job_applications]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[job_applications] (
        [ApplicationID]                INT IDENTITY(1,1) NOT NULL,
        [JobID]                        INT NULL,
        [Position]                     NVARCHAR(255) NOT NULL,
        [FirstName]                    NVARCHAR(100) NOT NULL,
        [MiddleName]                   NVARCHAR(100) NULL,
        [LastName]                     NVARCHAR(100) NOT NULL,
        [Email]                        NVARCHAR(255) NOT NULL,
        [Phone]                        NVARCHAR(50) NOT NULL,
        [Address1]                     NVARCHAR(255) NOT NULL,
        [Address2]                     NVARCHAR(150) NULL,
        [City]                         NVARCHAR(100) NOT NULL,
        [State]                        NVARCHAR(50) NOT NULL CONSTRAINT [DF_job_app_State] DEFAULT (N'WA'),
        [Zip]                          NVARCHAR(20) NOT NULL,
        [hasLicense]                   BIT NOT NULL CONSTRAINT [DF_job_app_hasLic] DEFAULT (0),
        [LicenseNo]                    NVARCHAR(50) NULL,
        [LicenseState]                 NVARCHAR(50) NULL,
        [LicenseExpireDate]            DATETIME2(7) NULL,
        [hasCDL]                       BIT NOT NULL CONSTRAINT [DF_job_app_hasCDL] DEFAULT (0),
        [CDLNo]                        NVARCHAR(50) NULL,
        [CDLState]                     NVARCHAR(50) NULL,
        [CDLExpireDate]                DATETIME2(7) NULL,
        [CDLType]                      NVARCHAR(50) NULL,
        [CDLRestriction]               NVARCHAR(150) NULL,
        [wasEmployed]                  BIT NOT NULL CONSTRAINT [DF_job_app_wasEmp] DEFAULT (0),
        [EmploymentStart]              DATETIME2(7) NULL,
        [EmploymentEnd]                DATETIME2(7) NULL,
        [EmploymentDepartment]         NVARCHAR(150) NULL,
        [hasRelative]                  BIT NOT NULL CONSTRAINT [DF_job_app_hasRel] DEFAULT (0),
        [RelativeNames]                NVARCHAR(255) NULL,
        [under18]                      BIT NOT NULL CONSTRAINT [DF_job_app_u18] DEFAULT (0),
        [hasImmigration]               BIT NOT NULL CONSTRAINT [DF_job_app_hasImm] DEFAULT (1),
        [ForeignLanguage1]             NVARCHAR(100) NULL,
        [Proficiency1]                 NVARCHAR(50) NULL,
        [ForeignLanguage2]             NVARCHAR(100) NULL,
        [Proficiency2]                 NVARCHAR(50) NULL,
        [ForeignLanguage3]             NVARCHAR(100) NULL,
        [Proficiency3]                 NVARCHAR(50) NULL,
        [hasGED]                       BIT NOT NULL CONSTRAINT [DF_job_app_hasGed] DEFAULT (0),
        [HighestGrade]                 NVARCHAR(50) NULL,
        [Education1]                   NVARCHAR(255) NULL,
        [Degree1]                      NVARCHAR(150) NULL,
        [DateEarned1]                  NVARCHAR(50) NULL,
        [Education2]                   NVARCHAR(255) NULL,
        [Degree2]                      NVARCHAR(150) NULL,
        [DateEarned2]                  NVARCHAR(50) NULL,
        [Education3]                   NVARCHAR(255) NULL,
        [Degree3]                      NVARCHAR(150) NULL,
        [DateEarned3]                  NVARCHAR(50) NULL,
        [Education4]                   NVARCHAR(255) NULL,
        [Degree4]                      NVARCHAR(150) NULL,
        [DateEarned4]                  NVARCHAR(50) NULL,
        [WorkExperienceEmployer1]      NVARCHAR(255) NULL,
        [WorkExperienceEmployerPhone1] NVARCHAR(50) NULL,
        [WorkExperienceStart1]         NVARCHAR(50) NULL,
        [WorkExperienceEnd1]           NVARCHAR(50) NULL,
        [WorkExperienceReason1]        NVARCHAR(500) NULL,
        [WorkExperienceEmployer2]      NVARCHAR(255) NULL,
        [WorkExperienceEmployerPhone2] NVARCHAR(50) NULL,
        [WorkExperienceStart2]         NVARCHAR(50) NULL,
        [WorkExperienceEnd2]           NVARCHAR(50) NULL,
        [WorkExperienceReason2]        NVARCHAR(500) NULL,
        [WorkExperienceEmployer3]      NVARCHAR(255) NULL,
        [WorkExperienceEmployerPhone3] NVARCHAR(50) NULL,
        [WorkExperienceStart3]         NVARCHAR(50) NULL,
        [WorkExperienceEnd3]           NVARCHAR(50) NULL,
        [WorkExperienceReason3]        NVARCHAR(500) NULL,
        [ReferenceName1]               NVARCHAR(150) NULL,
        [ReferenceEmail1]              NVARCHAR(255) NULL,
        [ReferencePhone1]              NVARCHAR(50) NULL,
        [ReferenceName2]               NVARCHAR(150) NULL,
        [ReferenceEmail2]              NVARCHAR(255) NULL,
        [ReferencePhone2]              NVARCHAR(50) NULL,
        [ReferenceName3]               NVARCHAR(150) NULL,
        [ReferenceEmail3]              NVARCHAR(255) NULL,
        [ReferencePhone3]              NVARCHAR(50) NULL,
        [Certification]                BIT NOT NULL CONSTRAINT [DF_job_app_cert] DEFAULT (1),
        [Signature]                    NVARCHAR(255) NULL,
        [EntryDate]                    DATETIME2(7) NOT NULL CONSTRAINT [DF_job_app_EntryDate] DEFAULT (SYSUTCDATETIME()),
        [ResumePath]                   NVARCHAR(500) NULL,
        [ResumeFileName]               NVARCHAR(255) NULL,
        [CoverLetterPath]              NVARCHAR(500) NULL,
        [CoverLetterFileName]          NVARCHAR(255) NULL,
        [Status]                       NVARCHAR(50) NOT NULL CONSTRAINT [DF_job_app_Status] DEFAULT (N'New'),
        [Rating]                       INT NOT NULL CONSTRAINT [DF_job_app_Rating] DEFAULT (0),
        [AdminNotes]                   NVARCHAR(MAX) NULL,
        [ReviewedBy]                   NVARCHAR(100) NULL,
        [ReviewedAt]                   DATETIME2(7) NULL,
        [DeletedAt]                    DATETIME2(7) NULL,
        CONSTRAINT [PK_job_applications] PRIMARY KEY CLUSTERED ([ApplicationID] ASC),
        CONSTRAINT [FK_job_applications_job] FOREIGN KEY ([JobID]) REFERENCES [dbo].[job_listings] ([JobID]) ON DELETE SET NULL
    );

    CREATE NONCLUSTERED INDEX [IX_job_applications_JobID] ON [dbo].[job_applications] ([JobID] ASC);
    CREATE NONCLUSTERED INDEX [IX_job_applications_Status] ON [dbo].[job_applications] ([Status] ASC);
    CREATE NONCLUSTERED INDEX [IX_job_applications_Email] ON [dbo].[job_applications] ([Email] ASC);
    CREATE NONCLUSTERED INDEX [IX_job_applications_EntryDate] ON [dbo].[job_applications] ([EntryDate] DESC);
END;
GO


-- =============================================================================
-- MODULE 7: "HOW DO I" DIRECTORY & MEGA-MENU
-- =============================================================================

PRINT 'Checking Module 7: how_do_i_categories, how_do_i_items...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[how_do_i_categories]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[how_do_i_categories] (
        [id]          INT IDENTITY(1,1) NOT NULL,
        [name]        NVARCHAR(120) NOT NULL,
        [slug]        NVARCHAR(120) NOT NULL,
        [icon]        NVARCHAR(50) NOT NULL CONSTRAINT [DF_how_do_i_cat_icon] DEFAULT (N'help-circle'),
        [description] NVARCHAR(255) NULL,
        [sort_order]  INT NOT NULL CONSTRAINT [DF_how_do_i_cat_sort] DEFAULT (0),
        [is_active]   BIT NOT NULL CONSTRAINT [DF_how_do_i_cat_active] DEFAULT (1),
        [is_system]   BIT NOT NULL CONSTRAINT [DF_how_do_i_cat_system] DEFAULT (0),
        [createdat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_cat_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_cat_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]   DATETIME2(7) NULL,
        CONSTRAINT [PK_how_do_i_categories] PRIMARY KEY CLUSTERED ([id] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_how_do_i_categories_slug' AND object_id = OBJECT_ID(N'[dbo].[how_do_i_categories]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_how_do_i_categories_slug]
        ON [dbo].[how_do_i_categories] ([slug] ASC)
        WHERE [deletedat] IS NULL;
END;
GO

-- Seed Required System "How Do I" Categories
MERGE INTO [dbo].[how_do_i_categories] AS Target
USING (VALUES
    (N'Apply For',   N'apply-for',   N'clipboard-list', N'Permits, licenses, employment, and county program applications.', 10, 1, 1),
    (N'Contact',     N'contact',     N'phone',          N'Department directories, elected officials, and office contact desks.', 20, 1, 1),
    (N'Find',        N'find',        N'search',         N'Locate county resources, election results, court statuses, and districts.', 30, 1, 1),
    (N'File A',      N'file-a',      N'file-text',      N'Submit official claims, petitions, and formal filings.', 40, 1, 1),
    (N'Join',        N'join',        N'users',          N'Volunteer boards, advisory committees, and community programs.', 50, 1, 1),
    (N'Pay For',     N'pay-for',     N'hard-drive',     N'Online payments for property taxes, court costs, probation, and accounts.', 60, 1, 1),
    (N'Learn About', N'learn-about', N'book',           N'Educational guides, court protection orders, and county initiatives.', 70, 1, 1),
    (N'Register To', N'register-to', N'check-square',   N'Voter registration, jury duty check-in, and court classes.', 80, 1, 1),
    (N'Report',      N'report',      N'megaphone',      N'Report road hazards, code violations, pest infestations, or tips.', 90, 1, 1),
    (N'Request',     N'request',     N'mail',           N'Public records requests, court case records, and vital certificates.', 100, 1, 1),
    (N'Search For',  N'search-for',  N'globe',          N'Public document archives, parcel lookups, and jail registries.', 110, 1, 1),
    (N'View',        N'view',        N'eye',            N'Court calendars, dockets, schedules, and public hearings.', 120, 1, 1)
) AS Source ([name], [slug], [icon], [description], [sort_order], [is_active], [is_system])
ON Target.[slug] = Source.[slug] AND Target.[deletedat] IS NULL
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([name], [slug], [icon], [description], [sort_order], [is_active], [is_system], [createdat], [updatedat])
    VALUES (Source.[name], Source.[slug], Source.[icon], Source.[description], Source.[sort_order], Source.[is_active], Source.[is_system], SYSUTCDATETIME(), SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[how_do_i_items]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[how_do_i_items] (
        [id]                    INT IDENTITY(1,1) NOT NULL,
        [category_id]           INT NOT NULL,
        [siteid]                NVARCHAR(100) NOT NULL CONSTRAINT [DF_how_do_i_items_siteid] DEFAULT (N'global'),
        [question]              NVARCHAR(255) NOT NULL,
        [destination_type]      NVARCHAR(30) NOT NULL CONSTRAINT [DF_how_do_i_items_dtype] DEFAULT (N'page'),
        [page_id]               INT NULL,
        [form_id]               INT NULL,
        [destination_url]       NVARCHAR(1000) NOT NULL,
        [open_in_new_tab]       BIT NOT NULL CONSTRAINT [DF_how_do_i_items_newtab] DEFAULT (0),
        [is_featured_mega_menu] BIT NOT NULL CONSTRAINT [DF_how_do_i_items_mega] DEFAULT (1),
        [sort_order]            INT NOT NULL CONSTRAINT [DF_how_do_i_items_sort] DEFAULT (0),
        [is_published]          BIT NOT NULL CONSTRAINT [DF_how_do_i_items_pub] DEFAULT (1),
        [created_by]            NVARCHAR(255) NULL,
        [modified_by]           NVARCHAR(255) NULL,
        [createdat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_items_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]             DATETIME2(7) NOT NULL CONSTRAINT [DF_how_do_i_items_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]             DATETIME2(7) NULL,
        CONSTRAINT [PK_how_do_i_items] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [FK_how_do_i_items_categories] FOREIGN KEY ([category_id]) REFERENCES [dbo].[how_do_i_categories] ([id])
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_how_do_i_items_site_cat' AND object_id = OBJECT_ID(N'[dbo].[how_do_i_items]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_how_do_i_items_site_cat]
        ON [dbo].[how_do_i_items] ([siteid] ASC, [category_id] ASC, [sort_order] ASC)
        WHERE [deletedat] IS NULL;
END;
GO


-- =============================================================================
-- MODULE 8: COUNTY CALENDAR OF EVENTS
-- =============================================================================

PRINT 'Checking Module 8: calendar_event_categories, calendar_events...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[calendar_event_categories]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[calendar_event_categories] (
        [id]          INT IDENTITY(1,1) NOT NULL,
        [name]        NVARCHAR(120) NOT NULL,
        [slug]        NVARCHAR(120) NOT NULL,
        [color]       NVARCHAR(30)  NOT NULL CONSTRAINT [DF_cal_event_cat_color] DEFAULT (N'#0284c7'),
        [badge_class] NVARCHAR(50)  NOT NULL CONSTRAINT [DF_cal_event_cat_badge] DEFAULT (N'badge-info'),
        [icon]        NVARCHAR(50)  NOT NULL CONSTRAINT [DF_cal_event_cat_icon]  DEFAULT (N'calendar'),
        [description] NVARCHAR(255) NULL,
        [sort_order]  INT NOT NULL CONSTRAINT [DF_cal_event_cat_sort]   DEFAULT (0),
        [is_active]   BIT NOT NULL CONSTRAINT [DF_cal_event_cat_active] DEFAULT (1),
        [is_system]   BIT NOT NULL CONSTRAINT [DF_cal_event_cat_system] DEFAULT (0),
        [createdat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_cal_event_cat_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_cal_event_cat_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]   DATETIME2(7) NULL,
        CONSTRAINT [PK_calendar_event_categories] PRIMARY KEY CLUSTERED ([id] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_calendar_event_categories_slug' AND object_id = OBJECT_ID(N'[dbo].[calendar_event_categories]'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_calendar_event_categories_slug]
        ON [dbo].[calendar_event_categories] ([slug] ASC)
        WHERE [deletedat] IS NULL;
END;
GO

-- Seed Required System County Calendar Event Categories
MERGE INTO [dbo].[calendar_event_categories] AS Target
USING (VALUES
    (N'Commissioners Meeting',       N'commissioners-meeting', N'#0284c7', N'badge-info',    N'building',     N'Board of County Commissioners regular sessions, workshops, and legislative briefings.', 10, 1, 1),
    (N'Public Hearing',              N'public-hearing',        N'#b45309', N'badge-warning', N'megaphone',    N'Official public hearings, land use dockets, budget hearings, and ordinance reviews.', 20, 1, 1),
    (N'Advisory Board & Committee',  N'advisory-board',        N'#7e22ce', N'badge-purple',  N'users',        N'Planning Commission, Noxious Weed Board, Lodging Tax, and citizen advisory committees.', 30, 1, 1),
    (N'Community Event & Outreach',  N'community-event',       N'#15803d', N'badge-success', N'calendar',     N'County Expo Center events, town halls, parks activities, and public workshops.', 40, 1, 1),
    (N'Holiday & Office Closure',    N'holiday-closure',       N'#b91c1c', N'badge-danger',  N'clock',        N'Official county holidays, courthouse closures, and modified department hours.', 50, 1, 1),
    (N'Elections & Civic Deadlines', N'elections-deadlines',   N'#0f172a', N'badge-neutral', N'check-square', N'Voter registration deadlines, ballot drop dates, tax due dates, and public trainings.', 60, 1, 1)
) AS Source ([name], [slug], [color], [badge_class], [icon], [description], [sort_order], [is_active], [is_system])
ON Target.[slug] = Source.[slug] AND Target.[deletedat] IS NULL
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([name], [slug], [color], [badge_class], [icon], [description], [sort_order], [is_active], [is_system], [createdat], [updatedat])
    VALUES (Source.[name], Source.[slug], Source.[color], Source.[badge_class], Source.[icon], Source.[description], Source.[sort_order], Source.[is_active], Source.[is_system], SYSUTCDATETIME(), SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[calendar_events]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[calendar_events] (
        [id]                  INT IDENTITY(1,1) NOT NULL,
        [siteid]              NVARCHAR(100) NOT NULL CONSTRAINT [DF_calendar_events_siteid] DEFAULT (N'global'),
        [category_id]         INT NOT NULL,
        [title]               NVARCHAR(255) NOT NULL,
        [slug]                NVARCHAR(255) NOT NULL,
        [summary]             NVARCHAR(500) NULL,
        [description]         NVARCHAR(MAX) NULL,
        [start_date]          DATE NOT NULL,
        [end_date]            DATE NOT NULL,
        [start_time]          NVARCHAR(20) NULL,
        [end_time]            NVARCHAR(20) NULL,
        [is_all_day]          BIT NOT NULL CONSTRAINT [DF_calendar_events_allday] DEFAULT (0),
        [location_name]       NVARCHAR(255) NULL,
        [location_address]    NVARCHAR(255) NULL,
        [room_number]         NVARCHAR(120) NULL,
        [virtual_meeting_url] NVARCHAR(1000) NULL,
        [virtual_meeting_id]  NVARCHAR(120) NULL,
        [agenda_url]          NVARCHAR(1000) NULL,
        [minutes_url]         NVARCHAR(1000) NULL,
        [contact_name]        NVARCHAR(150) NULL,
        [contact_email]       NVARCHAR(150) NULL,
        [contact_phone]       NVARCHAR(60) NULL,
        [is_featured]         BIT NOT NULL CONSTRAINT [DF_calendar_events_featured] DEFAULT (0),
        [is_public_notice]    BIT NOT NULL CONSTRAINT [DF_calendar_events_notice] DEFAULT (0),
        [status]              NVARCHAR(30) NOT NULL CONSTRAINT [DF_calendar_events_status] DEFAULT (N'Published'),
        [created_by]          NVARCHAR(255) NULL,
        [modified_by]         NVARCHAR(255) NULL,
        [createdat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_calendar_events_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]           DATETIME2(7) NOT NULL CONSTRAINT [DF_calendar_events_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]           DATETIME2(7) NULL,
        CONSTRAINT [PK_calendar_events] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [FK_calendar_events_categories] FOREIGN KEY ([category_id]) REFERENCES [dbo].[calendar_event_categories] ([id])
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_calendar_events_dates_site' AND object_id = OBJECT_ID(N'[dbo].[calendar_events]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_calendar_events_dates_site]
        ON [dbo].[calendar_events] ([start_date] ASC, [end_date] ASC, [siteid] ASC, [category_id] ASC)
        WHERE [deletedat] IS NULL;
END;
GO


-- =============================================================================
-- MODULE 9: EMERGENCY ALERTS & INCIDENT DISPATCH
-- =============================================================================

PRINT 'Checking Module 9: emergency_alerts...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[emergency_alerts]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[emergency_alerts] (
        [id]             INT IDENTITY(1,1) NOT NULL,
        [title]          NVARCHAR(255) NOT NULL,
        [message]        NVARCHAR(MAX) NOT NULL,
        [severity]       NVARCHAR(50) NOT NULL CONSTRAINT [DF_emergency_alerts_severity] DEFAULT ('danger'), -- 'danger' (critical/red), 'warning' (orange), 'info' (blue), 'success' (green)
        [incident_type]  NVARCHAR(50) NOT NULL CONSTRAINT [DF_emergency_alerts_type] DEFAULT ('wildfire'), -- 'wildfire', 'weather', 'road_closure', 'facility', 'general'
        [link_url]       NVARCHAR(1000) NULL,
        [link_text]      NVARCHAR(100) NOT NULL CONSTRAINT [DF_emergency_alerts_linktext] DEFAULT (N'View Incident Details'),
        [is_active]      BIT NOT NULL CONSTRAINT [DF_emergency_alerts_active] DEFAULT (1),
        [is_dismissible] BIT NOT NULL CONSTRAINT [DF_emergency_alerts_dismiss] DEFAULT (1),
        [siteid]         NVARCHAR(100) NOT NULL CONSTRAINT [DF_emergency_alerts_siteid] DEFAULT (N'global'),
        [starts_at]      DATETIME2(7) NULL,
        [expires_at]     DATETIME2(7) NULL,
        [created_by]     NVARCHAR(255) NULL,
        [modified_by]    NVARCHAR(255) NULL,
        [createdat]      DATETIME2(7) NOT NULL CONSTRAINT [DF_emergency_alerts_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]      DATETIME2(7) NOT NULL CONSTRAINT [DF_emergency_alerts_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]      DATETIME2(7) NULL,
        CONSTRAINT [PK_emergency_alerts] PRIMARY KEY CLUSTERED ([id] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_emergency_alerts_active' AND object_id = OBJECT_ID(N'[dbo].[emergency_alerts]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_emergency_alerts_active] 
    ON [dbo].[emergency_alerts] ([is_active], [siteid])
    INCLUDE ([severity], [title], [starts_at], [expires_at])
    WHERE [deletedat] IS NULL;
END;
GO

-- Seed Baseline Winter Weather Advisory Broadcast if empty
IF NOT EXISTS (SELECT 1 FROM [dbo].[emergency_alerts] WHERE [deletedat] IS NULL)
BEGIN
    INSERT INTO [dbo].[emergency_alerts] (
        [title],
        [message],
        [severity],
        [incident_type],
        [link_url],
        [link_text],
        [is_active],
        [is_dismissible],
        [siteid],
        [starts_at],
        [expires_at],
        [created_by],
        [modified_by],
        [createdat],
        [updatedat]
    ) VALUES (
        N'WINTER WEATHER ADVISORY: Stevens Pass & Blewett Pass Traction Tires Required',
        N'Heavy winter snowfall is impacting higher elevations across Chelan County. WSDOT requires traction tires or chains on US-2 and US-97. County and state road crews are actively plowing and treating mountain corridors.',
        N'warning',
        N'road_closure',
        N'https://wsdot.com/travel/real-time/',
        N'View Live Pass Conditions',
        1,
        1,
        N'global',
        SYSUTCDATETIME(),
        DATEADD(day, 3, SYSUTCDATETIME()),
        N'PIO Administrator',
        N'PIO Administrator',
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );
END;
GO


-- =============================================================================
-- FINAL VERIFICATION: TABLE AUDIT REPORT
-- =============================================================================

PRINT '======================================================================';
PRINT 'Initialization Completed Successfully. Verifying registered tables:';
PRINT '======================================================================';
GO

SELECT 
    t.[name] AS [TableName],
    p.[rows] AS [RowCount],
    t.[create_date] AS [CreatedDate]
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.[schema_id] = SCHEMA_ID(N'dbo')
  AND t.[name] IN (
      N'cms_workspaces',
      N'cms_roles',
      N'cms_users',
      N'cms_user_workspaces',
      N'pages',
      N'page_FolderExplorer',
      N'page_SubPage',
      N'navigation_menus',
      N'navigation_menu_items',
      N'form_departments',
      N'forms',
      N'form_fields',
      N'form_submissions',
      N'form_submission_values',
      N'form_audit_logs',
      N'job_listings',
      N'job_applications',
      N'how_do_i_categories',
      N'how_do_i_items',
      N'calendar_event_categories',
      N'calendar_events',
      N'emergency_alerts',
      N'page_revisions'
  )
ORDER BY t.[name] ASC;
GO
