SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

PRINT '=================================================================';
PRINT 'CHELAN COUNTY CMSADMIN 2.0 - SQL SERVER SCHEMA AUDIT';
PRINT 'Database: ChelanCountyWebsite';
PRINT '=================================================================';
PRINT '';

-- 1. Check for expected tables
PRINT '[1] TABLE EXISTENCE AUDIT';
PRINT '-----------------------------------------------------------------';

DECLARE @expected TABLE (tableName NVARCHAR(128));
INSERT INTO @expected VALUES
    ('cms_roles'), ('cms_users'), ('cms_user_workspaces'), ('cms_workspaces'), ('cms_settings'),
    ('pages'), ('page_SubPage'), ('page_FolderExplorer'), ('page_revisions'), ('page_call_to_actions'),
    ('navigation_menus'), ('navigation_menu_items'),
    ('form_departments'), ('forms'), ('form_fields'), ('form_submissions'), ('form_submission_values'), ('form_audit_logs'),
    ('job_listings'), ('job_applications'),
    ('how_do_i_categories'), ('how_do_i_items'),
    ('calendar_event_categories'), ('calendar_events'),
    ('emergency_alerts'),
    ('article_categories'), ('article_tags'), ('articles'), ('press_releases'),
    ('media_assets'),
    ('rfp_solicitations'), ('rfp_addenda'), ('rfp_planholders'), ('rfp_bids');

SELECT 
    e.tableName,
    CASE WHEN t.name IS NOT NULL THEN 'PRESENT' ELSE '>>> MISSING <<<' END AS Status,
    ISNULL(p.rows, 0) AS [RowCount]
FROM @expected e
LEFT JOIN sys.tables t ON e.tableName = t.name
LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
ORDER BY Status DESC, e.tableName ASC;

-- 2. Check for missing tables
SELECT 'MISSING TABLE' AS AlertType, e.tableName
FROM @expected e
LEFT JOIN sys.tables t ON e.tableName = t.name
WHERE t.name IS NULL;

-- 3. Check for tables in DB not in expected list
SELECT 'EXTRA TABLE' AS AlertType, t.name AS tableName, p.rows AS [RowCount]
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
  AND t.name NOT IN (SELECT tableName FROM @expected)
ORDER BY t.name;

-- 4. Filtered Indexes Audit (Check WHERE deletedat IS NULL)
PRINT '';
PRINT '[2] FILTERED INDEX AUDIT';
PRINT '-----------------------------------------------------------------';
SELECT 
    t.name AS tableName,
    i.name AS indexName,
    i.is_unique AS isUnique,
    i.filter_definition AS filterDefinition
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.has_filter = 1
ORDER BY t.name, i.name;

-- 5. Foreign Key Constraints Audit
PRINT '';
PRINT '[3] FOREIGN KEY INTEGRITY AUDIT';
PRINT '-----------------------------------------------------------------';
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ParentTable,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    fk.delete_referential_action_desc AS OnDeleteAction
FROM sys.foreign_keys fk
ORDER BY ParentTable, ForeignKeyName;

-- 6. Check columns on key tables that were recently modified or are critical
PRINT '';
PRINT '[4] CRITICAL COLUMNS ON cms_workspaces';
PRINT '-----------------------------------------------------------------';
SELECT c.name AS ColumnName, ty.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID('cms_workspaces')
  AND c.name IN ('leadership_type', 'job_title', 'contact_photo', 'storage_path', 'domain_name', 'project_path', 'color', 'deletedat');

PRINT '';
PRINT '[5] CRITICAL COLUMNS ON pages';
PRINT '-----------------------------------------------------------------';
SELECT c.name AS ColumnName, ty.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID('pages')
  AND c.name IN ('ContentID', 'ParentID', 'SiteID', 'Title', 'Permalink', 'Content', 'publish_at', 'unpublish_at', 'deletedat');

PRINT '';
PRINT '[6] CRITICAL COLUMNS ON articles';
PRINT '-----------------------------------------------------------------';
SELECT c.name AS ColumnName, ty.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID('articles')
  AND c.name IN ('title', 'slug', 'siteid', 'cover_image', 'cover_image_alt', 'is_published', 'publish_at', 'unpublish_at', 'deletedat');

PRINT '';
PRINT '[7] CRITICAL COLUMNS ON emergency_alerts';
PRINT '-----------------------------------------------------------------';
SELECT c.name AS ColumnName, ty.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID('emergency_alerts')
  AND c.name IN ('siteid', 'title', 'severity', 'is_active', 'start_time', 'end_time', 'deletedat');

PRINT '';
PRINT '[8] CRITICAL COLUMNS ON media_assets';
PRINT '-----------------------------------------------------------------';
SELECT c.name AS ColumnName, ty.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID('media_assets')
  AND c.name IN ('site_id', 'folder', 'filename', 'web_url', 'file_hash', 'is_image', 'is_wcag_compliant', 'deletedat');

