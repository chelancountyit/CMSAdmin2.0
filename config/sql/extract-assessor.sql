-- ============================================================================
-- CHELAN COUNTY CMSADMIN 2.0 — ASSESSOR WORKSPACE EXTRACTION SCRIPT
-- Modernization & Ingestion from cccmsdbv2 (SiteID = 1027) into ChelanCountyWebsite
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

PRINT '==================================================';
PRINT 'STEP 1: Register / Update Workspace [assessor]';
PRINT '==================================================';

IF NOT EXISTS (SELECT 1 FROM dbo.cms_workspaces WHERE code = 'assessor')
BEGIN
    INSERT INTO dbo.cms_workspaces (
        code,
        name,
        alias,
        type,
        badge,
        badge_class,
        icon,
        color,
        description,
        folder_path,
        virtual_directory,
        redirect_url,
        department,
        department_category,
        storage_path,
        domain_name,
        project_path,
        leadership_type,
        job_title,
        contact_photo,
        contact_first_name,
        contact_last_name,
        contact_email,
        contact_phone,
        contact_fax,
        address,
        address2,
        city,
        state,
        zip,
        office_hours,
        is_active,
        is_system,
        sort_order,
        createdat,
        updatedat
    )
    VALUES (
        'assessor',
        'Chelan County Assessor',
        'assessor',
        'dept',
        'Assessor',
        'badge-blue',
        'calculator',
        '#0284c7',
        'Property assessment, revaluation, parcels, maps, levies, and property tax relief',
        'c:\inetpub\chelan-county\files\assessor',
        'assessor',
        'https://www.chelancounty.gov/assessor',
        'Assessor',
        'Finance and Records',
        'files/assessor',
        'www.chelancounty.gov',
        'C:\inetpub\chelan-county',
        'elected',
        'County Assessor',
        '/images/logo/assessor-elected.jpg',
        'Wes',
        'Cornelius',
        'assessor@chelancounty.gov',
        '509-667-6365',
        '509-667-6664',
        '350 Orondo Ave',
        'Suite 206',
        'Wenatchee',
        'WA',
        '98801',
        'Monday - Friday: 9:00 AM - 5:00 PM',
        1,
        0,
        10,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );
    PRINT 'Inserted workspace [assessor].';
END
ELSE
BEGIN
    UPDATE dbo.cms_workspaces SET
        name = 'Chelan County Assessor',
        alias = 'assessor',
        type = 'dept',
        badge = 'Assessor',
        badge_class = 'badge-blue',
        icon = 'calculator',
        color = '#0284c7',
        description = 'Property assessment, revaluation, parcels, maps, levies, and property tax relief',
        folder_path = 'c:\inetpub\chelan-county\files\assessor',
        virtual_directory = 'assessor',
        redirect_url = 'https://www.chelancounty.gov/assessor',
        department = 'Assessor',
        department_category = 'Finance and Records',
        storage_path = 'files/assessor',
        domain_name = 'www.chelancounty.gov',
        project_path = 'C:\inetpub\chelan-county',
        leadership_type = 'elected',
        job_title = 'County Assessor',
        contact_photo = '/images/logo/assessor-elected.jpg',
        contact_first_name = 'Wes',
        contact_last_name = 'Cornelius',
        contact_email = 'assessor@chelancounty.gov',
        contact_phone = '509-667-6365',
        contact_fax = '509-667-6664',
        address = '350 Orondo Ave',
        address2 = 'Suite 206',
        city = 'Wenatchee',
        state = 'WA',
        zip = '98801',
        office_hours = 'Monday - Friday: 9:00 AM - 5:00 PM',
        is_active = 1,
        sort_order = 10,
        updatedat = SYSUTCDATETIME()
    WHERE code = 'assessor';
    PRINT 'Updated workspace [assessor].';
END
GO

PRINT '==================================================';
PRINT 'STEP 2: Clean Existing Assessor Pages & Revisions';
PRINT '==================================================';

DELETE FROM dbo.page_revisions WHERE page_id IN (SELECT ContentID FROM dbo.pages WHERE SiteID = 'assessor');
DELETE FROM dbo.page_SubPage WHERE SiteID = 'assessor';
DELETE FROM dbo.pages WHERE SiteID = 'assessor';

PRINT 'Cleaned existing assessor pages and revisions.';
GO

PRINT '==================================================';
PRINT 'STEP 3: Extract 39 Pages from cccmsdbv2.dbo.cContents';
PRINT '==================================================';

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
    'assessor' AS SiteID,
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
    -- URL modernization for Assessor content body
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(c.Body, 'https://www.co.chelan.wa.us/files/assessor/', '/files/assessor/'),
                        'http://www.co.chelan.wa.us/files/assessor/', '/files/assessor/'
                    ),
                    'http://co.chelan.wa.us/files/assessor/', '/files/assessor/'
                ),
                'https://www.co.chelan.wa.us/assessor/', '/assessor/page/'
            ),
            'http://www.co.chelan.wa.us/assessor/', '/assessor/page/'
        ),
        'http://co.chelan.wa.us/assessor/', '/assessor/page/'
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
WHERE c.SiteID = 1027;

SET IDENTITY_INSERT dbo.pages OFF;

PRINT 'Extracted pages into dbo.pages: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
GO

PRINT '==================================================';
PRINT 'STEP 4: Configure Navigation Menus & Items';
PRINT '==================================================';

DECLARE @MenuID INT;

SELECT @MenuID = id FROM dbo.navigation_menus WHERE siteid = 'assessor' AND menu_key = 'side';

IF @MenuID IS NULL
BEGIN
    INSERT INTO dbo.navigation_menus (siteid, menu_key, name, is_active, createdat, updatedat)
    VALUES ('assessor', 'side', 'Assessor Side Navigation', 1, SYSUTCDATETIME(), SYSUTCDATETIME());
    SET @MenuID = SCOPE_IDENTITY();
    PRINT 'Created navigation menu: Assessor Side Navigation (ID: ' + CAST(@MenuID AS VARCHAR(10)) + ')';
END
ELSE
BEGIN
    PRINT 'Found existing navigation menu: Assessor Side Navigation (ID: ' + CAST(@MenuID AS VARCHAR(10)) + ')';
END

-- Reset existing menu items for Assessor
DELETE FROM dbo.navigation_menu_items WHERE navigation_menu_id = @MenuID;

-- Top-level Parent Categories
DECLARE @AssessmentsID INT, @ExemptionsID INT, @MapsID INT;

-- 1. Assessments
INSERT INTO dbo.navigation_menu_items (
    navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, createdat, updatedat
) VALUES (
    @MenuID, NULL, 'Assessments', 'page', '/annual-revaluation', 10, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()
);
SET @AssessmentsID = SCOPE_IDENTITY();

-- 2. Exemptions
INSERT INTO dbo.navigation_menu_items (
    navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, createdat, updatedat
) VALUES (
    @MenuID, NULL, 'Exemptions', 'page', '/seniordisabled-exemptions', 20, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()
);
SET @ExemptionsID = SCOPE_IDENTITY();

-- 3. Maps
INSERT INTO dbo.navigation_menu_items (
    navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, createdat, updatedat
) VALUES (
    @MenuID, NULL, 'Maps', 'page', '/gis-mapping', 30, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()
);
SET @MapsID = SCOPE_IDENTITY();

-- Child Items under Assessments
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, createdat, updatedat)
VALUES
    (@MenuID, @AssessmentsID, 'Annual Revaluation', 'page', '/annual-revaluation', 1, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Assessment Process', 'page', '/assessment-process', 2, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Real Property', 'page', '/real-property', 3, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Personal Property', 'page', '/personal-property', 4, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Facts About Property Taxes', 'page', '/facts-about-property-taxes', 5, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Tax Bills and Payments', 'page', '/tax-bills-and-payments', 6, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Impact of New State School Tax', 'page', '/impact-of-new-state-school-tax', 7, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Appeals', 'page', '/appeals', 8, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Levies', 'page', '/levies', 9, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @AssessmentsID, 'Important Assessment Dates', 'page', '/important-assessment-dates', 10, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME());

-- Child Items under Exemptions
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, createdat, updatedat)
VALUES
    (@MenuID, @ExemptionsID, 'Senior/Disabled', 'page', '/seniordisabled-exemptions', 1, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ExemptionsID, 'Current Use', 'page', '/current-use-exemptions', 2, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ExemptionsID, 'Destroyed Property', 'page', '/destroyed-property-exemptions', 3, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ExemptionsID, 'DOR Nonprofits', 'page', '/dor-nonprofits', 4, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME());

-- Child Items under Maps
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, createdat, updatedat)
VALUES
    (@MenuID, @MapsID, 'GIS Mapping', 'page', '/gis-mapping', 1, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @MapsID, 'Historical Plats and Sections', 'page', '/historical-plats-and-sections', 2, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @MapsID, 'Zoning', 'page', '/zoning', 3, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME());

-- Top-level Direct Navigation Items
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, createdat, updatedat)
VALUES
    (@MenuID, NULL, 'Market Sales Analysis', 'page', '/market-sales-analysis', 40, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Monthly Sales Reports', 'page', '/monthly-sales-reports', 50, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Community Meetings', 'page', '/community-meetings', 60, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Frequently Asked Questions', 'page', '/frequently-asked-questions', 70, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Property Tax Summary Reports', 'page', '/property-tax-summary-reports', 80, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Parcel and Sale Search', 'page', '/parcel-and-sale-search', 90, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Helpful Links & Resources', 'page', '/assessor-resources', 100, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME());

PRINT 'Configured navigation items under menu ' + CAST(@MenuID AS VARCHAR(10));
GO

PRINT '==================================================';
PRINT 'STEP 5: Summary & Verification Query';
PRINT '==================================================';

SELECT 
    'Pages Extracted' AS Metric, 
    COUNT(*) AS TotalCount,
    SUM(CASE WHEN StatusCode = 'Active' THEN 1 ELSE 0 END) AS ActiveCount,
    SUM(CASE WHEN StatusCode = 'Inactive' THEN 1 ELSE 0 END) AS InactiveCount
FROM dbo.pages
WHERE SiteID = 'assessor';

SELECT 
    'Navigation Items' AS Metric,
    COUNT(*) AS TotalCount
FROM dbo.navigation_menu_items nmi
INNER JOIN dbo.navigation_menus nm ON nm.id = nmi.navigation_menu_id
WHERE nm.siteid = 'assessor' AND nm.menu_key = 'side';

PRINT 'Assessor extraction complete.';
GO
