-- =============================================================================
-- Chelan County CMSAdmin 2.0 - Complete Extraction for Board of Commissioners
-- Source: cccmsdbv2 (Legacy Chelan County Website, SiteID = 1030)
-- Target: ChelanCountyWebsite (CMSAdmin 2.0 Architecture)
-- Rules: SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

PRINT '==================================================';
PRINT 'STEP 1: Register / Update Workspace [board-of-commissioners]';
PRINT '==================================================';

IF EXISTS (SELECT 1 FROM dbo.cms_workspaces WHERE code IN ('commissioners', 'board-of-commissioners'))
BEGIN
    UPDATE dbo.cms_workspaces SET
        code = 'board-of-commissioners',
        name = 'Board of County Commissioners',
        alias = 'commissioners',
        type = 'dept',
        badge = 'Commissioners',
        badge_class = 'badge-primary',
        icon = 'landmark',
        color = '#004879',
        description = 'County legislative authority, ordinances, resolutions, budget, Board of Equalization, and public sessions',
        folder_path = 'c:\inetpub\chelan-county\files\board-of-commissioners',
        virtual_directory = 'board-of-commissioners',
        redirect_url = 'https://www.chelancounty.gov/board-of-commissioners',
        department = 'Board of County Commissioners',
        department_category = 'County Administration',
        storage_path = 'files/board-of-commissioners',
        domain_name = 'www.chelancounty.gov',
        project_path = 'C:\inetpub\chelan-county',
        leadership_type = 'elected',
        job_title = 'Board of County Commissioners',
        contact_photo = '/images/logo/board-of-commissioners.jpg',
        contact_first_name = 'Cathy',
        contact_last_name = 'Mulhall',
        contact_email = 'Cathy.Mulhall@co.chelan.wa.us',
        contact_phone = '(509) 667-6215',
        contact_fax = '(509) 667-6599',
        address = '400 Douglas St.',
        address2 = 'Suite 201',
        city = 'Wenatchee',
        state = 'WA',
        zip = '98801',
        office_hours = 'Monday - Thursday: 8:00 AM - 5:00 PM, Friday: 8:00 AM - 12:00 PM',
        is_active = 1,
        deletedat = NULL,
        updatedat = SYSUTCDATETIME()
    WHERE code IN ('commissioners', 'board-of-commissioners');
    PRINT 'Updated workspace [board-of-commissioners].';
END
ELSE
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
        'board-of-commissioners',
        'Board of County Commissioners',
        'commissioners',
        'dept',
        'Commissioners',
        'badge-primary',
        'landmark',
        '#004879',
        'County legislative authority, ordinances, resolutions, budget, Board of Equalization, and public sessions',
        'c:\inetpub\chelan-county\files\board-of-commissioners',
        'board-of-commissioners',
        'https://www.chelancounty.gov/board-of-commissioners',
        'Board of County Commissioners',
        'County Administration',
        'files/board-of-commissioners',
        'www.chelancounty.gov',
        'C:\inetpub\chelan-county',
        'elected',
        'Board of County Commissioners',
        '/images/logo/board-of-commissioners.jpg',
        'Cathy',
        'Mulhall',
        'Cathy.Mulhall@co.chelan.wa.us',
        '(509) 667-6215',
        '(509) 667-6599',
        '400 Douglas St.',
        'Suite 201',
        'Wenatchee',
        'WA',
        '98801',
        'Monday - Thursday: 8:00 AM - 5:00 PM, Friday: 8:00 AM - 12:00 PM',
        1,
        0,
        30,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );
    PRINT 'Inserted workspace [board-of-commissioners].';
END

PRINT '==================================================';
PRINT 'STEP 2: Clean Existing Board of Commissioners Pages & Assets';
PRINT '==================================================';

DELETE FROM dbo.page_revisions WHERE page_id IN (SELECT ContentID FROM dbo.pages WHERE SiteID IN ('board-of-commissioners', 'commissioners'));
DELETE FROM dbo.page_SubPage WHERE SiteID IN ('board-of-commissioners', 'commissioners');
IF OBJECT_ID('dbo.page_FolderExplorer', 'U') IS NOT NULL
    DELETE FROM dbo.page_FolderExplorer WHERE SiteID IN ('board-of-commissioners', 'commissioners');
IF OBJECT_ID('dbo.page_CtaCard', 'U') IS NOT NULL
    DELETE FROM dbo.page_CtaCard WHERE SiteID IN ('board-of-commissioners', 'commissioners');
DELETE FROM dbo.pages WHERE SiteID IN ('board-of-commissioners', 'commissioners');

PRINT '==================================================';
PRINT 'STEP 3: Extract 27 Pages from cccmsdbv2.dbo.cContents (SiteID = 1030)';
PRINT '==================================================';

SET IDENTITY_INSERT dbo.pages ON;

INSERT INTO dbo.pages (
    ContentID, SiteID, PageType, MenuSelected, LayoutType, ParentID, StatusCode,
    Permalink, Title, MetaTitle, MetaDesc, MetaKeyWords, Summary, Body,
    imageAttachment, imageAttribution, imageAlt, imageTitle, imageDescription, imageDecorative,
    isLocked, SidebarIDs, SortOrder, isPublished, Visibility, PublishAt, ViewCount,
    Created, CreatedBy, Modified, ModifiedBy, DeletedAt, DeletedBy,
    hasCtaCards, ctaSectionTitle, hasArchive, publish_at, unpublish_at, UnpublishAt
)
SELECT 
    c.ContentID,
    'board-of-commissioners' AS SiteID,
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
    LOWER(LTRIM(RTRIM(c.Permalink))) AS Permalink,
    LTRIM(RTRIM(c.Title)) AS Title,
    c.Title AS MetaTitle,
    ISNULL(c.MetaDesc, '') AS MetaDesc,
    ISNULL(c.MetaKeyWords, '') AS MetaKeyWords,
    ISNULL(c.Summary, '') AS Summary,
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(c.Body, 'https://www.co.chelan.wa.us/files/', '/files/'),
                                'http://www.co.chelan.wa.us/files/', '/files/'
                            ),
                            'http://co.chelan.wa.us/files/', '/files/'
                        ),
                        'https://www.co.chelan.wa.us/board-of-commissioners/pages/', '/board-of-commissioners/page/'
                    ),
                    'http://www.co.chelan.wa.us/board-of-commissioners/pages/', '/board-of-commissioners/page/'
                ),
                '/board-of-commissioners/pages/', '/board-of-commissioners/page/'
            ),
            '/auditor/pages/', '/auditor/page/'
        ),
        '/assessor/pages/', '/assessor/page/'
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
    CASE WHEN c.ContentID = 102 THEN 1 ELSE 0 END AS hasCtaCards,
    CASE WHEN c.ContentID = 102 THEN 'Quick Services & Online Tools' ELSE NULL END AS ctaSectionTitle,
    CASE WHEN c.ContentID IN (2579, 5688, 433, 5787, 5698) THEN 1 ELSE 0 END AS hasArchive,
    ISNULL(c.Created, SYSUTCDATETIME()) AS publish_at,
    NULL AS unpublish_at,
    NULL AS UnpublishAt
FROM cccmsdbv2.dbo.cContents c WITH (NOLOCK)
WHERE c.SiteID = 1030;

SET IDENTITY_INSERT dbo.pages OFF;

PRINT '==================================================';
PRINT 'STEP 4: Extract SubPages into dbo.page_SubPage';
PRINT '==================================================';

DECLARE @SubPageMap TABLE (NewID INT, LegacySubPageID INT, TargetContentID INT);

INSERT INTO dbo.page_SubPage (
    ContentID, Title, Body, Position, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy, SiteID
)
SELECT
    CASE
        WHEN sp.SubPageID = 17 THEN 102   -- Resources (Home, Districts 1-3, Minutes)
        WHEN sp.SubPageID IN (97, 98, 99) THEN 2568 -- Public Records
        WHEN sp.SubPageID = 1126 THEN 5698 -- Housing
        WHEN sp.SubPageID IN (1133, 1144) THEN 5688 -- Lodging Tax Advisory Committee
        WHEN sp.SubPageID IN (1138, 1174) THEN 433  -- Board of Equalization
        WHEN sp.SubPageID = 1141 THEN 5718 -- American Rescue Plan Act
        WHEN sp.SubPageID = 1151 THEN 5675 -- CPIF Grant Program
        WHEN sp.SubPageID = 1169 THEN 5783 -- Tourism Impact
        WHEN sp.SubPageID = 1176 THEN 5796 -- Tax Increment Financing
        WHEN sp.SubPageID = 1181 THEN 5805 -- Tourism Impact Study
        ELSE 102
    END AS ContentID,
    LTRIM(RTRIM(sp.Title)) AS Title,
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(ISNULL(sp.Body, ''), 'https://www.co.chelan.wa.us/files/', '/files/'),
                            'http://www.co.chelan.wa.us/files/', '/files/'
                        ),
                        'https://www.co.chelan.wa.us/board-of-commissioners/pages/', '/board-of-commissioners/page/'
                    ),
                    'http://www.co.chelan.wa.us/board-of-commissioners/pages/', '/board-of-commissioners/page/'
                ),
                '/board-of-commissioners/pages/', '/board-of-commissioners/page/'
            ),
            '/auditor/pages/', '/auditor/page/'
        ),
        '/assessor/pages/', '/assessor/page/'
    ) AS Body,
    ISNULL(sp.Position, 1) AS Position,
    COALESCE(sp.Created, SYSUTCDATETIME()) AS CreatedAt,
    'Migration' AS CreatedBy,
    COALESCE(sp.Modified, SYSUTCDATETIME()) AS ModifiedAt,
    'Migration' AS ModifiedBy,
    'board-of-commissioners' AS SiteID
FROM cccmsdbv2.dbo.cSubPages sp WITH (NOLOCK)
WHERE sp.SiteID = 1030
ORDER BY sp.SubPageID ASC;

-- Dynamically link SidebarIDs JSON array on dbo.pages from inserted page_SubPage rows
DECLARE @SpResources INT = (SELECT TOP 1 ID FROM dbo.page_SubPage WHERE SiteID = 'board-of-commissioners' AND Title = 'Resources' ORDER BY ID DESC);
IF @SpResources IS NOT NULL
BEGIN
    UPDATE dbo.pages
    SET SidebarIDs = '["subpage-' + CAST(@SpResources AS VARCHAR(10)) + '"]'
    WHERE SiteID = 'board-of-commissioners' AND ContentID IN (55, 56, 57, 69, 102);
END;

UPDATE p
SET p.SidebarIDs = '[' + sub.JsonList + ']'
FROM dbo.pages p
INNER JOIN (
    SELECT ContentID, STRING_AGG('"subpage-' + CAST(ID AS VARCHAR(10)) + '"', ',') WITHIN GROUP (ORDER BY Position ASC, ID ASC) AS JsonList
    FROM dbo.page_SubPage
    WHERE SiteID = 'board-of-commissioners' AND ContentID <> 102
    GROUP BY ContentID
) sub ON sub.ContentID = p.ContentID
WHERE p.SiteID = 'board-of-commissioners';

PRINT '==================================================';
PRINT 'STEP 5: Extract Folder Explorers (cArchivePath) & CTA Cards';
PRINT '==================================================';

IF OBJECT_ID('dbo.page_FolderExplorer', 'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.page_FolderExplorer (ContentID, SiteID, Title, RelativePath, AbsolutePath, Absolute, Weight, Layout, Placement)
    VALUES
        (2579, 'board-of-commissioners', 'Meeting Minutes', 'files/board-of-commissioners/archives', 'c:\inetpub\chelan-county\files\board-of-commissioners\archives', 1, 1, '3/9', 'After'),
        (5688, 'board-of-commissioners', 'Meeting Minutes and Agenda', 'files/board-of-commissioners/archives-LTAC-meetings', 'c:\inetpub\chelan-county\files\board-of-commissioners\archives-LTAC-meetings', 1, 1, '3/9', 'After'),
        (433,  'board-of-commissioners', 'Board Meetings and Agenda', 'files/board-of-commissioners/archive-boe', 'c:\inetpub\chelan-county\files\board-of-commissioners\archive-boe', 1, 1, '3/9', 'After'),
        (5787, 'board-of-commissioners', 'BOE', 'files/board-of-commissioners/archive-boe', 'c:\inetpub\chelan-county\files\board-of-commissioners\archive-boe', 1, 1, '3/9', 'After'),
        (5698, 'board-of-commissioners', 'Meeting Minutes and Agenda', 'files/board-of-commissioners/archive-housing', 'c:\inetpub\chelan-county\files\board-of-commissioners\archive-housing', 1, 1, '3/9', 'After');
END;

IF OBJECT_ID('dbo.page_CtaCard', 'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.page_CtaCard (
        ContentID, SiteID, Title, ShortDescription, DestinationUrl, ImagePath, ImageAlt, ButtonText, ButtonIcon, OpenInNewTab, SortOrder, IsActive, CreatedBy
    )
    VALUES
        (102, 'board-of-commissioners', N'Join Commissioner Session via Zoom', N'Watch or participate in this week''s live Board of County Commissioners session.', N'/board-of-commissioners/page/join-the-commissioners-meeting', N'/images/picjumbo/calendar16x9.jpg', N'', N'Join Session', N'fa-arrow-right', 0, 1, 1, N'Migration'),
        (102, 'board-of-commissioners', N'Document & Record Search', N'Search Commissioners public resolutions, agreements, minutes, and official records.', N'/board-of-commissioners/page/document-and-record-search', N'/images/picjumbo/document16x9.jpg', N'', N'Search Records', N'fa-arrow-right', 0, 2, 1, N'Migration'),
        (102, 'board-of-commissioners', N'Chelan County Codes', N'Browse the official Chelan County Municipal Code and county ordinances online.', N'https://www.codepublishing.com/WA/ChelanCounty/', N'/images/picjumbo/codes16x9.jpg', N'', N'Browse Code', N'fa-arrow-up-right-from-square', 1, 3, 1, N'Migration'),
        (102, 'board-of-commissioners', N'Follow Us on Facebook', N'Stay connected with Chelan County announcements, news, and community updates.', N'https://www.facebook.com/ChelanCounty', N'/images/picjumbo/facebookphone.jpg', N'', N'Follow Updates', N'fa-arrow-up-right-from-square', 1, 4, 1, N'Migration');
END;

PRINT '==================================================';
PRINT 'STEP 6: Configure Navigation Menu & Items';
PRINT '==================================================';

DECLARE @MenuID INT;

SELECT @MenuID = id 
FROM dbo.navigation_menus 
WHERE siteid IN ('board-of-commissioners', 'commissioners') AND menu_key = 'side';

IF @MenuID IS NULL
BEGIN
    INSERT INTO dbo.navigation_menus (siteid, menu_key, name, is_active, createdat, updatedat)
    VALUES ('board-of-commissioners', 'side', 'Board of Commissioners Side Navigation', 1, SYSUTCDATETIME(), SYSUTCDATETIME());
    SET @MenuID = SCOPE_IDENTITY();
END
ELSE
BEGIN
    UPDATE dbo.navigation_menus
    SET siteid = 'board-of-commissioners', name = 'Board of Commissioners Side Navigation', is_active = 1, updatedat = SYSUTCDATETIME()
    WHERE id = @MenuID;
    DELETE FROM dbo.navigation_menu_items WHERE navigation_menu_id = @MenuID;
END;

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, NULL, 'Commissioner District 1', 'page', '/board-of-commissioners/page/commissioner-district-1', 10, 1, 0, 'user', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Commissioner District 2', 'page', '/board-of-commissioners/page/commissioner-district-2', 20, 1, 0, 'user', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Commissioner District 3', 'page', '/board-of-commissioners/page/commissioner-district-3', 30, 1, 0, 'user', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Weekly Commissioners Agenda', 'page', '/board-of-commissioners/page/weekly-commissioners-agenda', 40, 1, 0, 'calendar', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Join the Commissioners Meeting', 'page', '/board-of-commissioners/page/join-the-commissioners-meeting', 45, 1, 0, 'video', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Meeting Minutes', 'page', '/board-of-commissioners/page/meeting-minutes', 50, 1, 0, 'file-text', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Document and Record Search', 'page', '/board-of-commissioners/page/document-and-record-search', 55, 1, 0, 'search', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Homeless Housing Network', 'page', '/board-of-commissioners/page/housing', 60, 1, 0, 'home', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Lodging Tax Advisory Committee', 'page', '/board-of-commissioners/page/lodging-tax-advisory-committee', 70, 1, 0, 'briefcase', SYSUTCDATETIME(), SYSUTCDATETIME());

DECLARE @ItemBOE INT;
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Board of Equalization', 'page', '/board-of-commissioners/page/board-of-equalization', 80, 1, 0, 'scale', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @ItemBOE = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @ItemBOE, 'File an Appeal', 'page', '/board-of-commissioners/page/board-of-equalization', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemBOE, 'Attend a Hearing', 'page', '/board-of-commissioners/page/board-of-equalization-hearings', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, NULL, 'CPIF Grant Program', 'page', '/board-of-commissioners/page/cascade-public-infrastructure-fund-grant-program', 90, 1, 0, 'award', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'American Rescue Plan Act', 'page', '/board-of-commissioners/page/american-rescue-plan-act', 95, 1, 0, 'file-text', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Tax Increment Financing', 'page', '/board-of-commissioners/page/tax-increment-financing', 100, 1, 0, 'trending-up', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Tourism Impact Study', 'page', '/board-of-commissioners/page/tourism-impact-study', 110, 1, 0, 'bar-chart-2', SYSUTCDATETIME(), SYSUTCDATETIME());

PRINT '==================================================';
PRINT 'STEP 7: Seed Initial Page Revisions (Version 1)';
PRINT '==================================================';

INSERT INTO dbo.page_revisions (
    page_id, version_number, title, slug, content_html, summary,
    layout_type, meta_json, change_summary, created_by, created_at
)
SELECT
    p.ContentID,
    1,
    p.Title,
    p.Permalink,
    ISNULL(p.Body, ''),
    ISNULL(p.Summary, ''),
    ISNULL(p.LayoutType, 'Full'),
    '{"migrated":true,"source":"cccmsdbv2","siteId":1030}',
    'Initial migration from legacy co.chelan.wa.us/board-of-commissioners (SiteID 1030)',
    'Migration',
    ISNULL(p.Modified, SYSUTCDATETIME())
FROM dbo.pages p
WHERE p.SiteID = 'board-of-commissioners';
