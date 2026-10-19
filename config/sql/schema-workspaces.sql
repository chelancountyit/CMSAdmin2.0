-- =============================================================================
-- Chelan County CMS Admin 2.0 - Workspaces Relational Database Schema
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Features: Municipal Departments, Divisions, Public Sites, Portals & Global Scope
-- Multi-Tenant Asset Scoping: Isolated IIS Virtual Folders (files/[virtual_dir])
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1. Table: cms_workspaces
-- Canonical directory of all 16 workspaces, municipal divisions, and public portals
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[cms_workspaces]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[cms_workspaces] (
        [id] INT IDENTITY(1,1) NOT NULL,
        
        -- Core Identification & Routing Keys
        [code] NVARCHAR(50) NOT NULL,                    -- Unique identifier: 'global', 'assessors', 'site-main', etc.
        [name] NVARCHAR(150) NOT NULL,                   -- Display Name: 'Assessor - Property & Parcels', 'chelancounty.gov'
        [alias] NVARCHAR(100) NULL,                      -- Alternate Slug/Domain alias: 'chelancounty.gov', 'parks.chelancounty.gov'
        
        -- Classification & Visual Markers
        [type] NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_ws_type] DEFAULT ('dept'), 
            -- 'global' (Unified County-wide), 'dept' (Municipal Department/Division), 'site' (Public Portal/Microsite)
        [badge] NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_badge] DEFAULT ('Dept'),
        [badge_class] NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_badge_cls] DEFAULT ('badge-neutral'),
            -- 'badge-neutral', 'badge-info', 'badge-success', 'badge-primary', 'badge-warning', 'badge-purple'
        [icon] NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_icon] DEFAULT ('building'),
            -- 'grid', 'building', 'briefcase', 'megaphone', 'shield', 'globe'
        [color] NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_ws_color] DEFAULT ('##0073aa'),
            -- Hex color code: '##0073aa', '##7e22ce', '##10b981', etc.
        [description] NVARCHAR(MAX) NULL,
        
        -- Storage & File System Scoping
        [folder_path] NVARCHAR(255) NOT NULL,            -- e.g. 'files/shared', 'files/assessors', 'files/chelancounty.gov'
        [virtual_directory] NVARCHAR(100) NOT NULL,      -- IIS virtual folder: 'shared', 'assessors', 'chelancounty.gov'
        [redirect_url] NVARCHAR(500) NULL,               -- External / Custom redirect URL
        
        -- Departmental Categorization
        [department] NVARCHAR(150) NULL,                 -- e.g. 'Assessor', 'Human Resources', 'Public Works'
        [department_category] NVARCHAR(100) NULL,        -- e.g. 'Finance and Records', 'Internal Services', 'County Administration'
        [storage_path] NVARCHAR(255) NULL,               -- Dedicated file repository path (e.g. 'files/assessor')
        [domain_name] NVARCHAR(255) NULL,                -- Canonical website hostname (e.g. 'www.chelancounty.gov')
        [project_path] NVARCHAR(255) NULL,               -- Server codebase directory (e.g. 'C:\inetpub\chelan-county')
        [leadership_type] NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_ws_lead_type] DEFAULT ('dept_head'), -- 'elected' or 'dept_head'
        [job_title] NVARCHAR(150) NULL,                  -- e.g. 'County Assessor'
        [contact_photo] NVARCHAR(500) NULL,              -- Avatar image path
        
        -- Official Contact Information
        [contact_first_name] NVARCHAR(100) NULL,
        [contact_last_name] NVARCHAR(100) NULL,
        [contact_email] NVARCHAR(255) NULL,
        [contact_phone] NVARCHAR(50) NULL,
        [contact_fax] NVARCHAR(50) NULL,
        
        -- Physical Facility Location & Address
        [address] NVARCHAR(255) NULL,                    -- Street Address (e.g. '350 Orondo Ave', '400 Douglas Street')
        [address2] NVARCHAR(150) NULL,                   -- Suite / Unit / Level (e.g. 'Suite 201', 'Level 2')
        [city] NVARCHAR(100) NOT NULL CONSTRAINT [DF_cms_ws_city] DEFAULT ('Wenatchee'),
        [state] NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_ws_state] DEFAULT ('WA'),
        [zip] NVARCHAR(20) NOT NULL CONSTRAINT [DF_cms_ws_zip] DEFAULT ('98801'),
        
        -- Operating Hours & Public Scheduling
        [office_hours] NVARCHAR(MAX) NULL,               -- e.g. 'Monday - Friday: 8:00 AM - 5:00 PM'
        
        -- Status, Hierarchy & System Flags
        [is_active] BIT NOT NULL CONSTRAINT [DF_cms_ws_active] DEFAULT (1),
        [is_system] BIT NOT NULL CONSTRAINT [DF_cms_ws_system] DEFAULT (0), -- 1 for built-in 'global'
        [sort_order] INT NOT NULL CONSTRAINT [DF_cms_ws_sort] DEFAULT (0),
        
        -- Timestamps
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_ws_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat] DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_ws_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat] DATETIME2(7) NULL,

        CONSTRAINT [PK_cms_workspaces] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_cms_workspaces_code] UNIQUE NONCLUSTERED ([code] ASC),
        CONSTRAINT [UQ_cms_workspaces_vdir] UNIQUE NONCLUSTERED ([virtual_directory] ASC),
        CONSTRAINT [CK_cms_workspaces_type] CHECK ([type] IN ('global', 'dept', 'site'))
    );

    CREATE NONCLUSTERED INDEX [IX_cms_workspaces_type] ON [dbo].[cms_workspaces] ([type] ASC);
    CREATE NONCLUSTERED INDEX [IX_cms_workspaces_category] ON [dbo].[cms_workspaces] ([department_category] ASC);
    CREATE NONCLUSTERED INDEX [IX_cms_workspaces_active] ON [dbo].[cms_workspaces] ([is_active] ASC);
    CREATE NONCLUSTERED INDEX [IX_cms_workspaces_sort] ON [dbo].[cms_workspaces] ([sort_order] ASC);
END;
GO

-- -----------------------------------------------------------------------------
-- 2. Seed Data: 16 Canonical Workspaces & Portals
-- 1 Global Unified Overview, 11 Municipal Departments & Divisions, 4 Public Sites
-- -----------------------------------------------------------------------------
MERGE INTO [dbo].[cms_workspaces] AS Target
USING (VALUES
    -- 1. Global Overview (Admin Only)
    (
        'global', 'All Workspaces', NULL, 'global', 'Global', 'badge-neutral', 'grid',
        'County-wide unified view across all municipal divisions and portals',
        'files/shared', 'shared', '', 'County-wide', 'County Administration',
        'County', 'Administration', 'info@chelancounty.gov', '509-667-6215', '',
        '400 Douglas Street', 'Suite 201', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 1, 0
    ),
    -- 2. Assessor
    (
        'assessors', 'Assessor - Property & Parcels', NULL, 'dept', 'Assessor', 'badge-info', 'building',
        'Property assessment & shared media library',
        'files/assessors', 'assessors', 'https://www.chelancounty.gov/assessor', 'Assessor', 'Finance and Records',
        'Deanna', 'Walter', 'assessor@chelancounty.gov', '509-667-6365', '509-667-6664',
        '350 Orondo Ave', 'Level 2', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 9:00 AM - 4:00 PM', 1, 0, 10
    ),
    -- 3. Auditor
    (
        'auditor', 'Auditor - Elections & Records', NULL, 'dept', 'Auditor', 'badge-purple', 'building',
        'Elections, recording & licensing',
        'files/auditor', 'auditor', 'https://www.chelancounty.gov/auditor', 'Auditor', 'Finance and Records',
        'Skip', 'Moore', 'auditor@chelancounty.gov', '509-667-6800', '509-667-6818',
        '350 Orondo Ave', 'Level 3', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 9:00 AM - 5:00 PM', 1, 0, 20
    ),
    -- 4. HRM
    (
        'hrm', 'HRM - Human Resources', NULL, 'dept', 'HRM', 'badge-purple', 'briefcase',
        'Recruitment, personnel & benefits',
        'files/hrm', 'hrm', 'https://www.chelancounty.gov/human-resources', 'Human Resources', 'Internal Services',
        'Human', 'Resources', 'jobs@chelancounty.gov', '509-667-6855', '509-667-6858',
        '400 Douglas Street', 'Suite 201', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 30
    ),
    -- 5. PIO
    (
        'pio', 'PIO - Public Information', NULL, 'dept', 'PIO', 'badge-info', 'megaphone',
        'Media alerts, press & notifications',
        'files/pio', 'pio', 'https://www.chelancounty.gov/pio', 'Public Information', 'Community Outreach',
        'Jill', 'FitzSimmons', 'pio@chelancounty.gov', '509-667-6523', '',
        '400 Douglas Street', 'Suite 201', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 40
    ),
    -- 6. Community Development
    (
        'commdev', 'Community Development', 'community-development', 'dept', 'Dept', 'badge-neutral', 'building',
        'Permits, planning & zoning',
        'files/community-development', 'community-development', 'https://www.chelancounty.gov/community-development', 'Community Development', 'Community Services',
        'Deanna', 'Walter', 'cd.director@chelancounty.gov', '509-667-6800', '509-667-6860',
        '316 Washington Street', 'Suite 401', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 50
    ),
    -- 7. Public Works
    (
        'pw', 'Public Works', 'public-works', 'dept', 'Dept', 'badge-neutral', 'building',
        'Roads, utilities & infrastructure',
        'files/public-works', 'public-works', 'https://www.chelancounty.gov/public-works', 'Public Works', 'Internal Services',
        'Eric', 'Pierson', 'public.works@chelancounty.gov', '509-667-6415', '509-667-6250',
        '316 Washington Street', 'Suite 402', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 60
    ),
    -- 8. County Administration
    (
        'admin', 'County Administration', 'county-administration', 'dept', 'Dept', 'badge-neutral', 'building',
        'Commissioners, executive & budget',
        'files/admin', 'admin', 'https://www.chelancounty.gov/administration', 'County Administration', 'County Administration',
        'Cathy', 'Mulhall', 'admin@chelancounty.gov', '509-667-6215', '509-667-6599',
        '400 Douglas Street', 'Suite 201', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 70
    ),
    -- 9. Board of Commissioners
    (
        'commissioners', 'Board of Commissioners', NULL, 'dept', 'Dept', 'badge-neutral', 'building',
        'County Commissioners & legislative agendas',
        'files/commissioners', 'commissioners', 'https://www.chelancounty.gov/board-of-commissioners', 'Commissioners', 'County Administration',
        'Clerk of', 'the Board', 'commissioners@chelancounty.gov', '509-667-6215', '509-667-6599',
        '400 Douglas Street', 'Suite 201', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 80
    ),
    -- 10. Sheriff''s Office
    (
        'sheriff', 'Sheriff''s Office', NULL, 'dept', 'Dept', 'badge-neutral', 'shield',
        'Law enforcement & public safety',
        'files/sheriff', 'sheriff', 'https://www.chelancounty.gov/sheriff', 'Sheriff', 'Law Enforcement',
        'Mike', 'Morrison', 'sheriff@chelancounty.gov', '509-667-6851', '509-667-6860',
        '401 Washington Street', 'Level 1', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:30 AM - 4:30 PM', 1, 0, 90
    ),
    -- 11. Treasurer
    (
        'treasurer', 'Treasurer', NULL, 'dept', 'Dept', 'badge-neutral', 'building',
        'Tax collections & county finance',
        'files/treasurer', 'treasurer', 'https://www.chelancounty.gov/treasurer', 'Treasurer', 'Finance and Records',
        'David', 'Griffiths', 'treasurer@chelancounty.gov', '509-667-6405', '509-667-6404',
        '350 Orondo Ave', 'Suite 204', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 9:00 AM - 4:00 PM', 1, 0, 100
    ),
    -- 12. County Clerk
    (
        'clerk', 'County Clerk', NULL, 'dept', 'Dept', 'badge-neutral', 'building',
        'Superior court records & judicial filings',
        'files/clerk', 'clerk', 'https://www.chelancounty.gov/clerk', 'County Clerk', 'Law and Judicial Services',
        'Marty', 'Young', 'clerk@chelancounty.gov', '509-667-6380', '509-667-6456',
        '350 Orondo Ave', 'Suite 501', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:30 AM - 4:30 PM', 1, 0, 110
    ),
    -- 13. chelancounty.gov (Main Site)
    (
        'site-main', 'chelancounty.gov', 'chelancounty.gov', 'site', 'Main Site', 'badge-success', 'globe',
        'Primary County public government portal',
        'files/chelancounty.gov', 'chelancounty.gov', 'https://www.chelancounty.gov', 'Public Portal', 'County Administration',
        'Web', 'Master', 'webmaster@chelancounty.gov', '509-667-6215', '',
        '400 Douglas Street', 'Suite 201', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 120
    ),
    -- 14. parks.chelancounty.gov (Subsite)
    (
        'site-parks', 'parks.chelancounty.gov', 'parks.chelancounty.gov', 'site', 'Subsite', 'badge-primary', 'globe',
        'County Parks & Recreation portal',
        'files/parks.chelancounty.gov', 'parks.chelancounty.gov', 'https://parks.chelancounty.gov', 'Parks & Recreation', 'Community Services',
        'Parks', 'Director', 'parks@chelancounty.gov', '509-667-6340', '',
        '316 Washington Street', 'Suite 402', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 130
    ),
    -- 15. gis.chelancounty.gov (Portal)
    (
        'site-gis', 'gis.chelancounty.gov', 'gis.chelancounty.gov', 'site', 'Portal', 'badge-warning', 'globe',
        'GIS, parcel viewer & map layers',
        'files/gis.chelancounty.gov', 'gis.chelancounty.gov', 'https://gis.chelancounty.gov', 'Information Technology / GIS', 'Internal Services',
        'GIS', 'Coordinator', 'gis@chelancounty.gov', '509-667-6839', '',
        '400 Douglas Street', 'Suite 201', 'Wenatchee', 'WA', '98801',
        'Monday - Friday: 8:00 AM - 5:00 PM', 1, 0, 140
    ),
    -- 16. expo.chelancounty.gov (Portal)
    (
        'site-expo', 'expo.chelancounty.gov', 'expo.chelancounty.gov', 'site', 'Portal', 'badge-info', 'globe',
        'Chelan County Expo Center & Fairgrounds',
        'files/expo.chelancounty.gov', 'expo.chelancounty.gov', 'https://expo.chelancounty.gov', 'Expo Center', 'Chelan-Douglas',
        'Expo', 'Manager', 'expo@chelancounty.gov', '509-782-3232', '',
        '5700 Wescott Drive', '', 'Cashmere', 'WA', '98815',
        'Monday - Friday: 8:00 AM - 4:30 PM', 1, 0, 150
    )
) AS Source (
    [code], [name], [alias], [type], [badge], [badge_class], [icon],
    [description], [folder_path], [virtual_directory], [redirect_url], [department], [department_category],
    [contact_first_name], [contact_last_name], [contact_email], [contact_phone], [contact_fax],
    [address], [address2], [city], [state], [zip],
    [office_hours], [is_active], [is_system], [sort_order]
)
ON Target.[code] = Source.[code]
WHEN MATCHED THEN
    UPDATE SET
        Target.[name] = Source.[name],
        Target.[alias] = Source.[alias],
        Target.[type] = Source.[type],
        Target.[badge] = Source.[badge],
        Target.[badge_class] = Source.[badge_class],
        Target.[icon] = Source.[icon],
        Target.[description] = Source.[description],
        Target.[folder_path] = Source.[folder_path],
        Target.[virtual_directory] = Source.[virtual_directory],
        Target.[redirect_url] = Source.[redirect_url],
        Target.[department] = Source.[department],
        Target.[department_category] = Source.[department_category],
        Target.[contact_first_name] = Source.[contact_first_name],
        Target.[contact_last_name] = Source.[contact_last_name],
        Target.[contact_email] = Source.[contact_email],
        Target.[contact_phone] = Source.[contact_phone],
        Target.[contact_fax] = Source.[contact_fax],
        Target.[address] = Source.[address],
        Target.[address2] = Source.[address2],
        Target.[city] = Source.[city],
        Target.[state] = Source.[state],
        Target.[zip] = Source.[zip],
        Target.[office_hours] = Source.[office_hours],
        Target.[is_active] = Source.[is_active],
        Target.[is_system] = Source.[is_system],
        Target.[sort_order] = Source.[sort_order],
        Target.[updatedat] = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        [code], [name], [alias], [type], [badge], [badge_class], [icon],
        [description], [folder_path], [virtual_directory], [redirect_url], [department], [department_category],
        [contact_first_name], [contact_last_name], [contact_email], [contact_phone], [contact_fax],
        [address], [address2], [city], [state], [zip],
        [office_hours], [is_active], [is_system], [sort_order],
        [createdat], [updatedat]
    )
    VALUES (
        Source.[code], Source.[name], Source.[alias], Source.[type], Source.[badge], Source.[badge_class], Source.[icon],
        Source.[description], Source.[folder_path], Source.[virtual_directory], Source.[redirect_url], Source.[department], Source.[department_category],
        Source.[contact_first_name], Source.[contact_last_name], Source.[contact_email], Source.[contact_phone], Source.[contact_fax],
        Source.[address], Source.[address2], Source.[city], Source.[state], Source.[zip],
        Source.[office_hours], Source.[is_active], Source.[is_system], Source.[sort_order],
        SYSUTCDATETIME(), SYSUTCDATETIME()
    );
GO

-- -----------------------------------------------------------------------------
-- 3. Foreign Key References & Integrity
-- Links User Workspaces to the Workspaces Directory
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[cms_user_workspaces]') AND type in (N'U'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_cms_user_workspaces_ws_code]') AND parent_object_id = OBJECT_ID(N'[dbo].[cms_user_workspaces]'))
    BEGIN
        ALTER TABLE [dbo].[cms_user_workspaces]
        ADD CONSTRAINT [FK_cms_user_workspaces_ws_code]
        FOREIGN KEY ([workspace_code]) REFERENCES [dbo].[cms_workspaces] ([code])
        ON UPDATE CASCADE;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. Verification Check
-- -----------------------------------------------------------------------------
SELECT 
    [id], [code], [name], [type], [badge], [badge_class], [icon],
    [virtual_directory], [folder_path], [department], [department_category],
    [contact_email], [contact_phone], [city], [is_active], [sort_order]
FROM [dbo].[cms_workspaces]
ORDER BY [sort_order] ASC, [id] ASC;
GO
