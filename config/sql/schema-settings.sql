-- =============================================================================
-- Chelan County CMS Admin 2.0 - Administrative Settings Schema
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Module: Settings (General, SEO, Media Configuration)
-- Safe to rerun: creates missing table, indexes, and initial default settings.
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Checking Module 11: cms_settings...';
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[cms_settings]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[cms_settings] (
        [id]            INT IDENTITY(1,1) NOT NULL,
        [setting_key]   NVARCHAR(100) NOT NULL,
        [setting_value] NVARCHAR(MAX) NULL,
        [setting_group] NVARCHAR(50) NOT NULL CONSTRAINT [DF_cms_settings_group] DEFAULT ('general'),
        [description]   NVARCHAR(500) NULL,
        [createdat]     DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_settings_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat]     DATETIME2(7) NOT NULL CONSTRAINT [DF_cms_settings_updatedat] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_cms_settings] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_cms_settings_key] UNIQUE NONCLUSTERED ([setting_key] ASC)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_cms_settings_group' AND object_id = OBJECT_ID(N'[dbo].[cms_settings]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_cms_settings_group]
    ON [dbo].[cms_settings] ([setting_group])
    INCLUDE ([setting_key], [setting_value]);
END;
GO

-- Seed Baseline Settings if table is empty
IF NOT EXISTS (SELECT 1 FROM [dbo].[cms_settings])
BEGIN
    INSERT INTO [dbo].[cms_settings] ([setting_key], [setting_value], [setting_group], [description])
    VALUES
    -- General Settings
    (N'site_title', N'Chelan County Washington', N'general', N'Primary municipal website title displayed in headers and browsers'),
    (N'site_tagline', N'Official County Government Administration & Public Services', N'general', N'Sub-headline or secondary slogan for search previews and open-graph'),
    (N'admin_email', N'pio@chelancounty.gov', N'general', N'Official public information office administrative contact address'),
    (N'county_phone', N'(509) 667-6200', N'general', N'County administration central switchboard phone number'),
    (N'county_address', N'400 Douglas Street, Suite 201, Wenatchee, WA 98801', N'general', N'Official physical address for Chelan County Administration building'),
    (N'office_hours', N'Monday - Friday, 8:00 AM - 5:00 PM PST', N'general', N'Standard county courthouse public operating hours'),
    (N'timezone', N'America/Los_Angeles', N'general', N'County standard timezone identifier'),
    (N'maintenance_mode', N'0', N'general', N'Emergency maintenance lock: 1 closes front-end with notice, 0 is live'),
    (N'maintenance_message', N'Chelan County digital services are undergoing scheduled maintenance. Emergency services remain operational 24/7.', N'general', N'Public banner displayed when maintenance mode is active'),

    -- Reading & SEO
    (N'seo_meta_title_format', N'{page_title} | Chelan County, WA', N'seo', N'Template pattern used to format browser title tags across all pages'),
    (N'seo_default_meta_description', N'Official website of Chelan County, Washington. Access Board of County Commissioners hearings, public safety alerts, GIS mapping, property records, and county services.', N'seo', N'Fallback meta description for search engine result snippets when pages lack custom meta'),
    (N'seo_default_og_image', N'/images/picjumbo/saddlerock.jpg', N'seo', N'Default social media share card image URL'),
    (N'seo_twitter_handle', N'@ChelanCountyWA', N'seo', N'Official county X/Twitter handle for social share cards'),
    (N'seo_ga_tracking_id', N'G-XXXXXXXXXX', N'seo', N'Google Analytics 4 Measurement ID'),
    (N'seo_gtm_container_id', N'GTM-XXXXXXX', N'seo', N'Google Tag Manager Container ID'),
    (N'seo_robots_txt', N'User-agent: *' + CHAR(13) + CHAR(10) + N'Disallow: /admin/' + CHAR(13) + CHAR(10) + N'Disallow: /api/internal/' + CHAR(13) + CHAR(10) + N'Allow: /' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + N'Sitemap: https://www.co.chelan.wa.us/sitemap.xml', N'seo', N'Rules for search engine crawlers and web spiders'),

    -- Media Sizes
    (N'media_thumb_width', N'150', N'media', N'Automatic thumbnail max width in pixels'),
    (N'media_thumb_height', N'150', N'media', N'Automatic thumbnail max height in pixels'),
    (N'media_medium_width', N'600', N'media', N'Medium image max width in pixels'),
    (N'media_medium_height', N'400', N'media', N'Medium image max height in pixels'),
    (N'media_large_width', N'1200', N'media', N'Large hero/banner max width in pixels'),
    (N'media_large_height', N'800', N'media', N'Large hero/banner max height in pixels'),
    (N'media_max_upload_mb', N'25', N'media', N'Maximum allowed file upload size cap in Megabytes'),
    (N'media_allowed_extensions', N'jpg,jpeg,png,gif,webp,svg,pdf,doc,docx,xls,xlsx,csv', N'media', N'Comma-separated list of allowed file upload extensions');
END;
GO

