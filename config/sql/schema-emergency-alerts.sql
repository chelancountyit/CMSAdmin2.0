-- =============================================================================
-- Chelan County CMS Admin 2.0 - Emergency Alerts & Incident Dispatch Relational Schema
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Module: PIO Public Safety Emergency Broadcasts (Wildfires, Road Closures, Weather, Facilities)
-- Workspace Scoping: Multi-Tenant Site/Department Scoping (siteid) with County-Wide Rollup ('global')
-- Safe to rerun: creates missing tables, indexes, constraints, and initial seed data.
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
