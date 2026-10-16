-- =============================================================================
-- Chelan County CMS Admin 2.0 - Articles, Categories, Tags & Press Releases Schema
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Module: PIO Public Information Office (News Articles, Blog Posts, Press Releases & Media Alerts)
-- Workspace Scoping: Multi-Tenant Site/Department Scoping (siteid) with County-Wide Rollup ('global')
-- Safe to rerun: creates missing tables, indexes, constraints, and initial seed data.
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Checking Module 10: article_categories...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[article_categories]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[article_categories] (
        [id]          INT IDENTITY(1,1) NOT NULL,
        [name]        NVARCHAR(150) NOT NULL,
        [slug]        NVARCHAR(150) NOT NULL,
        [description] NVARCHAR(500) NULL,
        [badge_color] NVARCHAR(50) NOT NULL CONSTRAINT [DF_article_categories_color] DEFAULT ('#0284c7'),
        [siteid]      NVARCHAR(100) NOT NULL CONSTRAINT [DF_article_categories_siteid] DEFAULT (N'global'),
        [sort_order]  INT NOT NULL CONSTRAINT [DF_article_categories_sort] DEFAULT (0),
        [createdat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_article_categories_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]   DATETIME2(7) NOT NULL CONSTRAINT [DF_article_categories_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]   DATETIME2(7) NULL,
        CONSTRAINT [PK_article_categories] PRIMARY KEY CLUSTERED ([id] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_article_categories_slug' AND object_id = OBJECT_ID(N'[dbo].[article_categories]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_article_categories_slug] 
    ON [dbo].[article_categories] ([slug], [siteid])
    WHERE [deletedat] IS NULL;
END;
GO

PRINT 'Checking Module 10: article_tags...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[article_tags]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[article_tags] (
        [id]        INT IDENTITY(1,1) NOT NULL,
        [name]      NVARCHAR(100) NOT NULL,
        [slug]      NVARCHAR(100) NOT NULL,
        [siteid]    NVARCHAR(100) NOT NULL CONSTRAINT [DF_article_tags_siteid] DEFAULT (N'global'),
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_article_tags_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat] DATETIME2(7) NOT NULL CONSTRAINT [DF_article_tags_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat] DATETIME2(7) NULL,
        CONSTRAINT [PK_article_tags] PRIMARY KEY CLUSTERED ([id] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_article_tags_slug' AND object_id = OBJECT_ID(N'[dbo].[article_tags]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_article_tags_slug] 
    ON [dbo].[article_tags] ([slug], [siteid])
    WHERE [deletedat] IS NULL;
END;
GO

PRINT 'Checking Module 10: articles...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[articles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[articles] (
        [id]                 INT IDENTITY(1,1) NOT NULL,
        [title]              NVARCHAR(255) NOT NULL,
        [slug]               NVARCHAR(255) NOT NULL,
        [summary]            NVARCHAR(1000) NULL,
        [content_html]       NVARCHAR(MAX) NOT NULL,
        [category_id]        INT NULL,
        [tags]               NVARCHAR(500) NULL,
        [featured_image]     NVARCHAR(1000) NULL,
        [featured_image_alt] NVARCHAR(500) NULL,
        [author_name]        NVARCHAR(255) NULL,
        [author_title]       NVARCHAR(255) NULL,
        [status]             NVARCHAR(50) NOT NULL CONSTRAINT [DF_articles_status] DEFAULT ('published'), -- 'draft', 'published', 'archived'
        [siteid]             NVARCHAR(100) NOT NULL CONSTRAINT [DF_articles_siteid] DEFAULT (N'global'),
        [published_at]       DATETIME2(7) NULL,
        [meta_title]         NVARCHAR(255) NULL,
        [meta_description]   NVARCHAR(500) NULL,
        [created_by]         NVARCHAR(255) NULL,
        [modified_by]        NVARCHAR(255) NULL,
        [createdat]          DATETIME2(7) NOT NULL CONSTRAINT [DF_articles_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]          DATETIME2(7) NOT NULL CONSTRAINT [DF_articles_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]          DATETIME2(7) NULL,
        CONSTRAINT [PK_articles] PRIMARY KEY CLUSTERED ([id] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_articles_slug_siteid' AND object_id = OBJECT_ID(N'[dbo].[articles]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_articles_slug_siteid] 
    ON [dbo].[articles] ([slug], [siteid])
    INCLUDE ([title], [status], [published_at], [category_id])
    WHERE [deletedat] IS NULL;
END;
GO

PRINT 'Checking Module 10: press_releases...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[press_releases]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[press_releases] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [title]         NVARCHAR(255) NOT NULL,
        [slug]          NVARCHAR(255) NOT NULL,
        [dateline]      NVARCHAR(150) NOT NULL CONSTRAINT [DF_press_releases_dateline] DEFAULT (N'WENATCHEE, WA'),
        [summary]       NVARCHAR(1000) NULL,
        [content_html]  NVARCHAR(MAX) NOT NULL,
        [is_embargoed]  BIT NOT NULL CONSTRAINT [DF_press_releases_embargoed] DEFAULT (0),
        [embargo_until] DATETIME2(7) NULL,
        [contact_name]  NVARCHAR(150) NULL,
        [contact_title] NVARCHAR(150) NULL,
        [contact_phone] NVARCHAR(50) NULL,
        [contact_email] NVARCHAR(150) NULL,
        [pdf_url]       NVARCHAR(1000) NULL,
        [status]        NVARCHAR(50) NOT NULL CONSTRAINT [DF_press_releases_status] DEFAULT ('released'), -- 'draft', 'embargoed', 'released', 'archived'
        [siteid]        NVARCHAR(100) NOT NULL CONSTRAINT [DF_press_releases_siteid] DEFAULT (N'global'),
        [released_at]   DATETIME2(7) NULL,
        [created_by]    NVARCHAR(255) NULL,
        [modified_by]   NVARCHAR(255) NULL,
        [createdat]     DATETIME2(7) NOT NULL CONSTRAINT [DF_press_releases_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]     DATETIME2(7) NOT NULL CONSTRAINT [DF_press_releases_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat]     DATETIME2(7) NULL,
        CONSTRAINT [PK_press_releases] PRIMARY KEY CLUSTERED ([id] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_press_releases_slug_siteid' AND object_id = OBJECT_ID(N'[dbo].[press_releases]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_press_releases_slug_siteid] 
    ON [dbo].[press_releases] ([slug], [siteid])
    INCLUDE ([title], [status], [released_at], [is_embargoed], [embargo_until])
    WHERE [deletedat] IS NULL;
END;
GO

-- Seed Baseline Categories if empty
IF NOT EXISTS (SELECT 1 FROM [dbo].[article_categories] WHERE [deletedat] IS NULL)
BEGIN
    INSERT INTO [dbo].[article_categories] ([name], [slug], [description], [badge_color], [siteid], [sort_order])
    VALUES 
    (N'County News', N'county-news', N'General Chelan County government and administration announcements.', N'#0284c7', N'global', 1),
    (N'Public Safety & Health', N'public-safety', N'Sheriff, emergency management, and community health bulletins.', N'#dc2626', N'global', 2),
    (N'Public Works & Roads', N'public-works', N'Road construction, infrastructure improvements, and seasonal maintenance.', N'#d97706', N'global', 3),
    (N'Parks & Recreation', N'parks-rec', N'Trails, fairgrounds, camping, and county park facilities.', N'#16a34a', N'global', 4),
    (N'Community Development', N'community-dev', N'Zoning, planning, building permits, and environmental reviews.', N'#7c3aed', N'global', 5);
END;
GO

-- Seed Baseline Tags if empty
IF NOT EXISTS (SELECT 1 FROM [dbo].[article_tags] WHERE [deletedat] IS NULL)
BEGIN
    INSERT INTO [dbo].[article_tags] ([name], [slug], [siteid])
    VALUES 
    (N'Commissioners', N'commissioners', N'global'),
    (N'Budget', N'budget', N'global'),
    (N'Public Hearing', N'public-hearing', N'global'),
    (N'Wildfire Preparedness', N'wildfire-preparedness', N'global'),
    (N'Stevens Pass', N'stevens-pass', N'global'),
    (N'Elections', N'elections', N'global');
END;
GO

-- Seed Baseline Article if empty
IF NOT EXISTS (SELECT 1 FROM [dbo].[articles] WHERE [deletedat] IS NULL)
BEGIN
    INSERT INTO [dbo].[articles] (
        [title], [slug], [summary], [content_html], [category_id], [tags],
        [author_name], [author_title], [status], [siteid], [published_at],
        [created_by], [modified_by]
    ) VALUES (
        N'Chelan County Adopts Comprehensive Wildfire Mitigation & Community Protection Plan',
        N'chelan-county-adopts-comprehensive-wildfire-mitigation-plan',
        N'The Board of County Commissioners has unanimously approved an updated multi-agency wildfire mitigation plan prioritizing defensible space initiatives and rural water supply access.',
        N'<p>The Chelan County Board of Commissioners unanimously approved an updated multi-jurisdictional Wildfire Mitigation and Community Protection Plan during Tuesday morning''s legislative session.</p><p>Developed in close partnership with local fire districts, the Washington State Department of Natural Resources, and the US Forest Service, the updated framework establishes enhanced defensible space standards for new residential developments in high-risk wildland-urban interface zones.</p><aside class="jbd-template jbd-callout jbd-callout-info" aria-label="Key Takeaway"><div class="jbd-callout-header"><span class="jbd-callout-badge" aria-hidden="true">INFO</span><strong class="jbd-callout-title">Community Grant Funding</strong></div><p>Property owners in unincorporated Chelan County may qualify for up to $2,500 in matching cost-share funds for fuels reduction and brush clearing through the Conservation District.</p></aside><p>County emergency managers emphasize that early preparation remains the single most effective defense against wildfire hazards. Homeowners are encouraged to audit their properties before summer conditions peak.</p>',
        (SELECT TOP 1 id FROM [dbo].[article_categories] WHERE [slug] = 'public-safety'),
        N'Commissioners,Wildfire Preparedness,Public Safety',
        N'Jill FitzSimmons',
        N'Public Information Officer',
        N'published',
        N'global',
        SYSUTCDATETIME(),
        N'PIO Administrator',
        N'PIO Administrator'
    );
END;
GO

-- Seed Baseline Press Release if empty
IF NOT EXISTS (SELECT 1 FROM [dbo].[press_releases] WHERE [deletedat] IS NULL)
BEGIN
    INSERT INTO [dbo].[press_releases] (
        [title], [slug], [dateline], [summary], [content_html],
        [is_embargoed], [embargo_until], [contact_name], [contact_title],
        [contact_phone], [contact_email], [status], [siteid], [released_at],
        [created_by], [modified_by]
    ) VALUES (
        N'FOR IMMEDIATE RELEASE: Chelan County Announces Public Hearing on 2027 Capital Improvement Budget',
        N'chelan-county-public-hearing-2027-capital-improvement-budget',
        N'WENATCHEE, WA',
        N'Chelan County Commissioners will hold an open public hearing on proposed capital facilities investments, including county courthouse security upgrades and road preservation projects.',
        N'<p><strong>WENATCHEE, WA</strong> &mdash; The Chelan County Board of County Commissioners today issued an official notice of a public hearing regarding the preliminary 2027 Capital Improvement and Facilities Budget scheduled for Monday, November 3, 2026, at 10:15 AM in the Commissioners'' Boardroom at 350 Orondo Avenue.</p><p>The hearing provides county residents, business owners, and civic organizations an opportunity to review and comment on proposed municipal investments covering road resurfacing, bridge safety inspections, stormwater management, and courthouse modernization.</p><p>Interested parties may testify in person or submit written testimony via email to the Clerk of the Board prior to 5:00 PM on Friday, October 31, 2026.</p>',
        0,
        NULL,
        N'Jill FitzSimmons',
        N'Public Information Officer',
        N'(509) 667-6200',
        N'pio@chelancounty.gov',
        N'released',
        N'global',
        SYSUTCDATETIME(),
        N'PIO Administrator',
        N'PIO Administrator'
    );
END;
GO

