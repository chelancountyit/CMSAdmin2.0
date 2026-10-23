-- =============================================================================
-- Chelan County CMSAdmin 2.0 - Complete Extraction for Workspace Auditor
-- Source: cccmsdbv2 (Legacy Chelan County Website, SiteID = 1029)
-- Target: ChelanCountyWebsite (CMSAdmin 2.0 Architecture)
-- Rules: SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; Parameterized & Typified
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '==================================================';
PRINT 'STEP 1: Register / Update Workspace auditor';
PRINT '==================================================';

IF NOT EXISTS (SELECT 1 FROM dbo.cms_workspaces WHERE code = 'auditor')
BEGIN
    INSERT INTO dbo.cms_workspaces (
        code, name, alias, type, badge, badge_class, icon, color, description,
        folder_path, virtual_directory, redirect_url, department, department_category,
        storage_path, domain_name, project_path, leadership_type, job_title, contact_photo,
        contact_first_name, contact_last_name, contact_email, contact_phone, contact_fax,
        address, address2, city, state, zip, office_hours,
        is_active, is_system, sort_order, createdat, updatedat
    )
    VALUES (
        'auditor',
        'Chelan County Auditor',
        'auditor',
        'dept',
        'Auditor',
        'badge-purple',
        'building',
        '#7e22ce',
        'Elections, recording, licensing, financial services & public records',
        'c:\inetpub\chelan-county\files\auditor',
        'auditor',
        'https://www.chelancounty.gov/auditor',
        'Auditor',
        'Finance and Records',
        'files/auditor',
        'www.chelancounty.gov',
        'C:\inetpub\chelan-county',
        'elected',
        'County Auditor',
        '/images/auditor/pages/auditor-pages-eaglePlate.jpg',
        'Brandt',
        'Cappell',
        'auditor@chelancounty.gov',
        '509-667-6800',
        '509-667-6818',
        '350 Orondo Ave',
        'Suite 202',
        'Wenatchee',
        'WA',
        '98801',
        'Monday - Friday: 9:00 AM - 5:00 PM',
        1,
        0,
        20,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );
    PRINT 'Inserted workspace [auditor].';
END
ELSE
BEGIN
    UPDATE dbo.cms_workspaces SET
        name = 'Chelan County Auditor',
        alias = 'auditor',
        type = 'dept',
        badge = 'Auditor',
        badge_class = 'badge-purple',
        icon = 'building',
        color = '#7e22ce',
        description = 'Elections, recording, licensing, financial services & public records',
        folder_path = 'c:\inetpub\chelan-county\files\auditor',
        virtual_directory = 'auditor',
        redirect_url = 'https://www.chelancounty.gov/auditor',
        department = 'Auditor',
        department_category = 'Finance and Records',
        storage_path = 'files/auditor',
        domain_name = 'www.chelancounty.gov',
        project_path = 'C:\inetpub\chelan-county',
        leadership_type = 'elected',
        job_title = 'County Auditor',
        contact_first_name = 'Brandt',
        contact_last_name = 'Cappell',
        contact_email = 'auditor@chelancounty.gov',
        contact_phone = '509-667-6800',
        contact_fax = '509-667-6818',
        address = '350 Orondo Ave',
        address2 = 'Suite 202',
        city = 'Wenatchee',
        state = 'WA',
        zip = '98801',
        office_hours = 'Monday - Friday: 9:00 AM - 5:00 PM',
        is_active = 1,
        updatedat = SYSUTCDATETIME()
    WHERE code = 'auditor';
    PRINT 'Updated workspace [auditor].';
END
GO

PRINT '==================================================';
PRINT 'STEP 2: Extract 51 Pages from cccmsdbv2.dbo.cContents';
PRINT '==================================================';

-- Clean existing auditor pages if any
DELETE FROM dbo.page_revisions WHERE page_id IN (SELECT ContentID FROM dbo.pages WHERE SiteID = 'auditor');
DELETE FROM dbo.pages WHERE SiteID = 'auditor';

-- Build temporary table of sidebar IDs aggregated by ContentID
IF OBJECT_ID('tempdb..#AuditorSidebars') IS NOT NULL DROP TABLE #AuditorSidebars;

SELECT s.ContentID, STRING_AGG(CAST(s.WidgetTypeID AS NVARCHAR(20)), ',') AS SidebarList
INTO #AuditorSidebars
FROM cccmsdbv2.dbo.cSidebars s WITH (NOLOCK)
INNER JOIN cccmsdbv2.dbo.cContents c WITH (NOLOCK) ON c.ContentID = s.ContentID
WHERE c.SiteID = 1029
GROUP BY s.ContentID;

SET IDENTITY_INSERT dbo.pages ON;

INSERT INTO dbo.pages (
    ContentID, SiteID, PageType, MenuSelected, LayoutType, ParentID, StatusCode,
    Permalink, Title, MetaTitle, MetaDesc, MetaKeyWords, Summary, Body,
    imageAttachment, imageAttribution, imageAlt, imageTitle, imageDescription, imageDecorative,
    isLocked, SidebarIDs, SortOrder, isPublished, Visibility, PublishAt, ViewCount,
    Created, CreatedBy, Modified, ModifiedBy, DeletedAt, DeletedBy,
    hasCtaCards, ctaSectionTitle, publish_at, unpublish_at, UnpublishAt
)
SELECT 
    c.ContentID,
    'auditor' AS SiteID,
    ISNULL(c.PageType, 1) AS PageType,
    ISNULL(NULLIF(c.MenuTitle, ''), c.Title) AS MenuSelected,
    CASE 
        WHEN c.LayoutType = 'full-page' THEN 'Full'
        WHEN c.LayoutType = 'right-sidebar' THEN 'Right Sidebar'
        WHEN c.LayoutType = 'left-sidebar' THEN 'Right Sidebar'
        ELSE 'Full'
    END AS LayoutType,
    0 AS ParentID,
    CASE 
        WHEN c.StatusCode = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS StatusCode,
    c.Permalink,
    c.Title,
    c.Title AS MetaTitle,
    ISNULL(c.MetaDesc, '') AS MetaDesc,
    ISNULL(c.MetaKeyWords, '') AS MetaKeyWords,
    ISNULL(c.Summary, '') AS Summary,
    -- URL modernization for Auditor content body
    REPLACE(
        REPLACE(
            REPLACE(c.Body, 'https://www.co.chelan.wa.us/files/auditor/', '/files/auditor/'),
            'http://www.co.chelan.wa.us/files/auditor/', '/files/auditor/'
        ),
        'http://co.chelan.wa.us/files/auditor/', '/files/auditor/'
    ) AS Body,
    ISNULL(c.imageAttachment, '') AS imageAttachment,
    ISNULL(c.imageAttribution, '') AS imageAttribution,
    '' AS imageAlt,
    '' AS imageTitle,
    '' AS imageDescription,
    0 AS imageDecorative,
    0 AS isLocked,
    '[]' AS SidebarIDs,
    0 AS SortOrder,
    CASE WHEN c.isPublished = 1 THEN 1 ELSE 0 END AS isPublished,
    CASE WHEN c.isPublished = 1 THEN 'Published' ELSE 'Draft' END AS Visibility,
    ISNULL(c.Created, SYSUTCDATETIME()) AS PublishAt,
    0 AS ViewCount,
    ISNULL(c.Created, SYSUTCDATETIME()) AS Created,
    ISNULL(c.CreatedBy, 'Migration') AS CreatedBy,
    ISNULL(c.Modified, SYSUTCDATETIME()) AS Modified,
    ISNULL(c.ModifiedBy, 'Migration') AS ModifiedBy,
    NULL AS DeletedAt,
    NULL AS DeletedBy,
    0 AS hasCtaCards,
    NULL AS ctaSectionTitle,
    ISNULL(c.Created, SYSUTCDATETIME()) AS publish_at,
    NULL AS unpublish_at,
    NULL AS UnpublishAt
FROM cccmsdbv2.dbo.cContents c WITH (NOLOCK)
LEFT JOIN #AuditorSidebars sb ON sb.ContentID = c.ContentID
WHERE c.SiteID = 1029;

SET IDENTITY_INSERT dbo.pages OFF;

PRINT 'Extracted pages into dbo.pages: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
GO

PRINT '==================================================';
PRINT 'STEP 3: Extract SubPages into dbo.page_SubPage';
PRINT '==================================================';

DELETE FROM dbo.page_SubPage WHERE SiteID = 'auditor';

INSERT INTO dbo.page_SubPage (
    ContentID, Title, Body, Position, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy, SiteID
)
SELECT 
    -- Map subpages to the primary division or relevant parent page
    CASE 
        WHEN sp.SubPageID IN (20, 21) THEN 88  -- Accounting / Financial Services
        WHEN sp.SubPageID = 23 THEN 90         -- Vehicle Licensing
        WHEN sp.SubPageID IN (24, 25, 1114) THEN 134 -- Record A Document / Recording
        WHEN sp.SubPageID IN (1113, 1115) THEN 140   -- Search Guide
        ELSE 101 -- Home
    END AS ContentID,
    sp.Title,
    ISNULL(sp.Body, '') AS Body,
    ISNULL(sp.Position, 0) AS Position,
    ISNULL(sp.Created, SYSUTCDATETIME()) AS CreatedAt,
    ISNULL(sp.CreatedBy, 'Migration') AS CreatedBy,
    ISNULL(sp.Modified, SYSUTCDATETIME()) AS ModifiedAt,
    ISNULL(sp.ModifiedBy, 'Migration') AS ModifiedBy,
    'auditor' AS SiteID
FROM cccmsdbv2.dbo.cSubPages sp WITH (NOLOCK)
WHERE sp.SiteID = 1029;

PRINT 'Extracted subpages into dbo.page_SubPage: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- Synchronize SidebarIDs JSON arrays for pages with subpages
UPDATE dbo.pages SET SidebarIDs = '["subpage-16","subpage-17"]' WHERE ContentID = 88 AND SiteID = 'auditor';
UPDATE dbo.pages SET SidebarIDs = '["subpage-18"]' WHERE ContentID = 90 AND SiteID = 'auditor';
UPDATE dbo.pages SET SidebarIDs = '["subpage-19","subpage-20","subpage-22"]' WHERE ContentID = 134 AND SiteID = 'auditor';
UPDATE dbo.pages SET SidebarIDs = '["subpage-15","subpage-21"]' WHERE ContentID = 140 AND SiteID = 'auditor';
GO

PRINT '==================================================';
PRINT 'STEP 4: Configure Navigation Menus & Items';
PRINT '==================================================';

DECLARE @MenuID INT;

SELECT @MenuID = id FROM dbo.navigation_menus WHERE siteid = 'auditor' AND menu_key = 'side';

IF @MenuID IS NULL
BEGIN
    INSERT INTO dbo.navigation_menus (siteid, menu_key, name, is_active, createdat, updatedat)
    VALUES ('auditor', 'side', 'Auditor Side Navigation', 1, SYSUTCDATETIME(), SYSUTCDATETIME());
    SET @MenuID = SCOPE_IDENTITY();
    PRINT 'Created navigation menu: Auditor Side Navigation (ID: ' + CAST(@MenuID AS VARCHAR(10)) + ')';
END
ELSE
BEGIN
    PRINT 'Found existing navigation menu: Auditor Side Navigation (ID: ' + CAST(@MenuID AS VARCHAR(10)) + ')';
END

-- Reset items for this menu
DELETE FROM dbo.navigation_menu_items WHERE navigation_menu_id = @MenuID;

-- Top Level Division Items
DECLARE @ItemAccounting INT, @ItemElections INT, @ItemLicensing INT, @ItemRecording INT;

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Accounting', 'page', 'financial-services', 10, 1, 0, 'briefcase', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @ItemAccounting = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Elections', 'page', 'elections', 20, 1, 0, 'check-square', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @ItemElections = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Vehicle & Vessel Licensing', 'page', 'vehicle-licensing', 30, 1, 0, 'truck', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @ItemLicensing = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Recording & Records', 'page', 'record-a-document', 40, 1, 0, 'file-text', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @ItemRecording = SCOPE_IDENTITY();

-- Accounting Children
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES 
    (@MenuID, @ItemAccounting, 'Financial Services', 'page', 'financial-services', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemAccounting, 'County Budget', 'page', 'county-budget', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemAccounting, 'Comprehensive Annual Financial Report', 'page', 'comprehensive-annual-financial-report', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemAccounting, 'Financial Status Report', 'page', 'financial-status-report', 4, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemAccounting, 'Budget Process', 'page', 'budget-process', 5, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

-- Licensing Children
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES 
    (@MenuID, @ItemLicensing, 'Vehicle Licensing Overview', 'page', 'vehicle-licensing', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemLicensing, 'Private Licensing Subagents', 'page', 'private-licensing-agencies', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemLicensing, 'Licensing Fees', 'page', 'licensing-fees', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemLicensing, 'Wheeled All-Terrain Vehicles (WATV)', 'page', 'wheeled-all-terrain-vehicles-watv', 4, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemLicensing, 'Mobile Homes', 'page', 'mobile-homes', 5, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemLicensing, 'Quick Title', 'page', 'quick-title-', 6, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemLicensing, 'Special Topics in Titling', 'page', 'special-topics-in-titling', 7, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

-- Recording Children
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES 
    (@MenuID, @ItemRecording, 'Record A Document', 'page', 'record-a-document', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemRecording, 'Recording Fees', 'page', 'fees', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemRecording, 'Marriage Licenses', 'page', 'marriage-licenses', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemRecording, 'Property Fraud Notification', 'page', 'recording-notification-service', 4, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemRecording, 'Recording Downloads & Forms', 'page', 'recording-downloads', 5, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemRecording, 'Search Guidance', 'page', 'search-guide', 6, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemRecording, 'eRecording Services', 'page', 'erecording', 7, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemRecording, 'Search Public Documents (Acclaim) ↗', 'url', 'https://acclaim.co.chelan.wa.us/acclaimweb', 8, 1, 1, 'external-link', SYSUTCDATETIME(), SYSUTCDATETIME());

PRINT 'Configured navigation items for Auditor Side Navigation.';
GO

PRINT '==================================================';
PRINT 'VERIFICATION QUERY';
PRINT '==================================================';

SELECT 
    (SELECT COUNT(*) FROM dbo.pages WHERE SiteID = 'auditor' AND DeletedAt IS NULL) AS TotalAuditorPages,
    (SELECT COUNT(*) FROM dbo.pages WHERE SiteID = 'auditor' AND StatusCode = 'Active' AND DeletedAt IS NULL) AS ActiveAuditorPages,
    (SELECT COUNT(*) FROM dbo.page_SubPage WHERE SiteID = 'auditor') AS AuditorSubPages,
    (SELECT COUNT(*) FROM dbo.navigation_menu_items WHERE navigation_menu_id IN (SELECT id FROM dbo.navigation_menus WHERE siteid = 'auditor')) AS NavItems;
GO

