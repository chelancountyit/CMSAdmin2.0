-- ============================================================================
-- Chelan County CMSAdmin 2.0 — Schema Migration: Scheduled Publishing & Expiration
-- Feature 3.2: Add publish_at & unpublish_at to pages, articles, calendar_events, job_listings, job_postings
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Starting Migration 3.2: Scheduled Publishing & Expiration Automation...';
GO

-- 1. Table: dbo.pages
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[pages]') AND name = 'publish_at')
BEGIN
    ALTER TABLE [dbo].[pages] ADD [publish_at] DATETIME2 NULL;
    PRINT 'Added pages.publish_at';
END;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[pages]') AND name = 'unpublish_at')
BEGIN
    ALTER TABLE [dbo].[pages] ADD [unpublish_at] DATETIME2 NULL;
    PRINT 'Added pages.unpublish_at';
END;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[pages]') AND name = 'UnpublishAt')
BEGIN
    ALTER TABLE [dbo].[pages] ADD [UnpublishAt] DATETIME2 NULL;
    PRINT 'Added pages.UnpublishAt';
END;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
UPDATE [dbo].[pages] SET [publish_at] = [PublishAt] WHERE [publish_at] IS NULL AND [PublishAt] IS NOT NULL;
UPDATE [dbo].[pages] SET [PublishAt] = [publish_at] WHERE [PublishAt] IS NULL AND [publish_at] IS NOT NULL;
UPDATE [dbo].[pages] SET [UnpublishAt] = [unpublish_at] WHERE [UnpublishAt] IS NULL AND [unpublish_at] IS NOT NULL;
UPDATE [dbo].[pages] SET [unpublish_at] = [UnpublishAt] WHERE [unpublish_at] IS NULL AND [UnpublishAt] IS NOT NULL;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_pages_schedule' AND object_id = OBJECT_ID(N'[dbo].[pages]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_pages_schedule] 
    ON [dbo].[pages] ([Visibility] ASC, [publish_at] ASC, [unpublish_at] ASC)
    WHERE [DeletedAt] IS NULL;
    PRINT 'Created index IX_pages_schedule';
END;
GO

-- 2. Table: dbo.articles
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[articles]') AND name = 'publish_at')
BEGIN
    ALTER TABLE [dbo].[articles] ADD [publish_at] DATETIME2 NULL;
    PRINT 'Added articles.publish_at';
END;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[articles]') AND name = 'unpublish_at')
BEGIN
    ALTER TABLE [dbo].[articles] ADD [unpublish_at] DATETIME2 NULL;
    PRINT 'Added articles.unpublish_at';
END;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
UPDATE [dbo].[articles] SET [publish_at] = [published_at] WHERE [publish_at] IS NULL AND [published_at] IS NOT NULL;
UPDATE [dbo].[articles] SET [published_at] = [publish_at] WHERE [published_at] IS NULL AND [publish_at] IS NOT NULL;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_articles_schedule' AND object_id = OBJECT_ID(N'[dbo].[articles]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_articles_schedule] 
    ON [dbo].[articles] ([status] ASC, [publish_at] ASC, [unpublish_at] ASC)
    WHERE [deletedat] IS NULL;
    PRINT 'Created index IX_articles_schedule';
END;
GO

-- 3. Table: dbo.calendar_events
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[calendar_events]') AND name = 'publish_at')
BEGIN
    ALTER TABLE [dbo].[calendar_events] ADD [publish_at] DATETIME2 NULL;
    PRINT 'Added calendar_events.publish_at';
END;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[calendar_events]') AND name = 'unpublish_at')
BEGIN
    ALTER TABLE [dbo].[calendar_events] ADD [unpublish_at] DATETIME2 NULL;
    PRINT 'Added calendar_events.unpublish_at';
END;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_calendar_events_schedule' AND object_id = OBJECT_ID(N'[dbo].[calendar_events]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_calendar_events_schedule] 
    ON [dbo].[calendar_events] ([status] ASC, [publish_at] ASC, [unpublish_at] ASC)
    WHERE [deletedat] IS NULL;
    PRINT 'Created index IX_calendar_events_schedule';
END;
GO

-- 4. Table: dbo.job_listings
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[job_listings]') AND name = 'publish_at')
BEGIN
    ALTER TABLE [dbo].[job_listings] ADD [publish_at] DATETIME2 NULL;
    PRINT 'Added job_listings.publish_at';
END;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[job_listings]') AND name = 'unpublish_at')
BEGIN
    ALTER TABLE [dbo].[job_listings] ADD [unpublish_at] DATETIME2 NULL;
    PRINT 'Added job_listings.unpublish_at';
END;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
UPDATE [dbo].[job_listings] SET [publish_at] = [PostDate] WHERE [publish_at] IS NULL AND [PostDate] IS NOT NULL;
UPDATE [dbo].[job_listings] SET [unpublish_at] = [ApplicationDeadline] WHERE [unpublish_at] IS NULL AND [ApplicationDeadline] IS NOT NULL;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_job_listings_schedule' AND object_id = OBJECT_ID(N'[dbo].[job_listings]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_job_listings_schedule] 
    ON [dbo].[job_listings] ([StatusCode] ASC, [publish_at] ASC, [unpublish_at] ASC)
    WHERE [DeletedAt] IS NULL;
    PRINT 'Created index IX_job_listings_schedule';
END;
GO

-- 5. Table: dbo.job_postings
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[job_postings]') AND name = 'publish_at')
BEGIN
    ALTER TABLE [dbo].[job_postings] ADD [publish_at] DATETIME2 NULL;
    PRINT 'Added job_postings.publish_at';
END;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[job_postings]') AND name = 'unpublish_at')
BEGIN
    ALTER TABLE [dbo].[job_postings] ADD [unpublish_at] DATETIME2 NULL;
    PRINT 'Added job_postings.unpublish_at';
END;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
UPDATE [dbo].[job_postings] SET [publish_at] = [open_date] WHERE [publish_at] IS NULL AND [open_date] IS NOT NULL;
UPDATE [dbo].[job_postings] SET [unpublish_at] = [close_date] WHERE [unpublish_at] IS NULL AND [close_date] IS NOT NULL;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_job_postings_schedule' AND object_id = OBJECT_ID(N'[dbo].[job_postings]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_job_postings_schedule] 
    ON [dbo].[job_postings] ([status] ASC, [publish_at] ASC, [unpublish_at] ASC)
    WHERE [deletedat] IS NULL;
    PRINT 'Created index IX_job_postings_schedule';
END;
GO

PRINT 'Migration 3.2 completed successfully.';
GO

