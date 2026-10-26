-- ============================================================================
-- Chelan County CMSAdmin 2.0 — Media Assets Management Schema
-- Database Target: ChelanCountyWebsite (SQL Server 2019/2022/2025)
-- Conformance: ADA Title II, Section 508, WCAG 2.1 & 2.2 Level AA
-- Mandatory Settings: QUOTED_IDENTIFIER ON, ANSI_NULLS ON
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'media_assets')
BEGIN
    CREATE TABLE dbo.media_assets (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        site_id NVARCHAR(50) NOT NULL,                    -- Scoped workspace (e.g. 'assessors', 'pio', 'sheriff', 'global')
        folder NVARCHAR(300) NOT NULL,                    -- Subfolder under workspace (e.g. 'images', 'images/weddings/full', 'documents')
        filename NVARCHAR(255) NOT NULL,                  -- Physical filename (e.g. 'courthouse-2026.jpg')
        file_path NVARCHAR(500) NOT NULL,                 -- Relative disk path ('files/assessors/images/courthouse-2026.jpg')
        web_url NVARCHAR(500) NOT NULL,                   -- Absolute web URL ('/files/assessors/images/courthouse-2026.jpg')
        file_size BIGINT NOT NULL DEFAULT 0,              -- File size in bytes
        file_ext NVARCHAR(50) NOT NULL,                   -- Extension ('jpg', 'pdf', 'png', etc.)
        mime_type NVARCHAR(100) NULL,                     -- MIME content type
        file_hash NVARCHAR(64) NULL,                      -- SHA-256 hex digest for deduplication
        
        -- ADA WCAG 2.1/2.2 AA Accessibility & Metadata
        title NVARCHAR(255) NULL,                         -- Human-readable display title
        alt_text NVARCHAR(1000) NULL,                     -- Screen reader description (WCAG 1.1.1)
        caption NVARCHAR(1000) NULL,                      -- Visible caption / editorial attribution
        credit NVARCHAR(255) NULL,                        -- Copyright, photographer, department credit
        
        -- Media Properties
        is_image BIT NOT NULL DEFAULT 0,                  -- Flag indicating image vs document
        width INT NULL,                                   -- Image pixel width
        height INT NULL,                                  -- Image pixel height
        is_wcag_compliant BIT NOT NULL DEFAULT 1,         -- 0 for images without alt text
        tags NVARCHAR(500) NULL,                          -- Searchable comma-separated tags
        ocr_text NVARCHAR(2000) NULL,                     -- Extracted WinRT OCR text for flyers, signs, and infographics
        
        -- Lifecycle & Audit
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        created_by NVARCHAR(100) NULL,
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_by NVARCHAR(100) NULL,
        deletedat DATETIME2(0) NULL
    );
END
GO

-- Filtered Indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_media_assets_site_folder_file' AND object_id = OBJECT_ID('dbo.media_assets'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_media_assets_site_folder_file
    ON dbo.media_assets (site_id, folder, filename)
    WHERE deletedat IS NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_media_assets_file_hash' AND object_id = OBJECT_ID('dbo.media_assets'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_media_assets_file_hash
    ON dbo.media_assets (file_hash)
    WHERE deletedat IS NULL AND file_hash IS NOT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_media_assets_wcag' AND object_id = OBJECT_ID('dbo.media_assets'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_media_assets_wcag
    ON dbo.media_assets (site_id, is_image, is_wcag_compliant)
    WHERE deletedat IS NULL;
END
GO

