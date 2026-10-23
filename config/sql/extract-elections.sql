-- ============================================================================
-- Chelan County CMSAdmin 2.0 — Elections Workspace Extraction & Migration
-- Source: cccmsdbv2.dbo.cContents, cSites, cSubPages (SiteID = 1053)
-- Target: ChelanCountyWebsite.dbo.pages, cms_workspaces, navigation_menu_items
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

PRINT '==================================================';
PRINT 'STEP 1: Register / Update Workspace: elections';
PRINT '==================================================';

IF NOT EXISTS (SELECT 1 FROM dbo.cms_workspaces WHERE code = 'elections')
BEGIN
    INSERT INTO dbo.cms_workspaces (
        code, name, alias, type, department, department_category,
        contact_first_name, contact_last_name, job_title, leadership_type,
        contact_photo, contact_email, contact_phone,
        address, city, state, zip, office_hours,
        is_active, is_system, sort_order, color,
        folder_path, virtual_directory,
        createdat, updatedat
    ) VALUES (
        'elections', 'Chelan County Elections', 'elections', 'dept', 'Elections', 'Public Records & Elections',
        'Brandt', 'Cappell', 'County Auditor', 'elected',
        '/images/logo/auditor-elected.jpg', 'elections@co.chelan.wa.us', '(509) 667-6808',
        '350 Orondo Ave., Suite 306', 'Wenatchee', 'WA', '98801', 'Monday - Friday 9:00 AM - 5:00 PM',
        1, 0, 15, '#1d4ed8',
        'files/elections', 'elections',
        SYSUTCDATETIME(), SYSUTCDATETIME()
    );
    PRINT 'Inserted new workspace: elections';
END
ELSE
BEGIN
    UPDATE dbo.cms_workspaces
    SET name = 'Chelan County Elections',
        type = 'dept',
        department = 'Elections',
        department_category = 'Public Records & Elections',
        contact_first_name = 'Brandt',
        contact_last_name = 'Cappell',
        job_title = 'County Auditor',
        leadership_type = 'elected',
        contact_photo = '/images/logo/auditor-elected.jpg',
        contact_email = 'elections@co.chelan.wa.us',
        contact_phone = '(509) 667-6808',
        address = '350 Orondo Ave., Suite 306',
        city = 'Wenatchee',
        state = 'WA',
        zip = '98801',
        office_hours = 'Monday - Friday 9:00 AM - 5:00 PM',
        color = '#1d4ed8',
        folder_path = 'files/elections',
        virtual_directory = 'elections',
        is_active = 1,
        deletedat = NULL,
        updatedat = SYSUTCDATETIME()
    WHERE code = 'elections';
    PRINT 'Updated existing workspace: elections';
END;
GO

PRINT '==================================================';
PRINT 'STEP 2: Purge Old Elections Pages & Revisions';
PRINT '==================================================';

DELETE FROM dbo.page_revisions 
WHERE page_id IN (SELECT ContentID FROM dbo.pages WHERE SiteID = 'elections');

DELETE FROM dbo.page_SubPage 
WHERE SiteID = 'elections';

DELETE FROM dbo.pages 
WHERE SiteID = 'elections';

PRINT 'Purged old pages, revisions, and subpages for elections.';
GO

PRINT '==================================================';
PRINT 'STEP 3: Ingest Legacy Pages from cccmsdbv2 (SiteID = 1053)';
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
    'elections' AS SiteID,
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
    -- URL modernization for Elections content body
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(c.Body, 'https://www.co.chelan.wa.us/files/', '/files/'),
                        'http://www.co.chelan.wa.us/files/', '/files/'
                    ),
                    'https://www.co.chelan.wa.us/elections/pages/', '/elections/page/'
                ),
                'http://www.co.chelan.wa.us/elections/pages/', '/elections/page/'
            ),
            'https://www.co.chelan.wa.us/elections/', '/elections/page/'
        ),
        'http://www.co.chelan.wa.us/elections/', '/elections/page/'
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
    CASE WHEN c.StatusCode = 1 THEN 1 ELSE 0 END AS isPublished,
    CASE WHEN c.StatusCode = 1 THEN 'Published' ELSE 'Draft' END AS Visibility,
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
WHERE c.SiteID = 1053;

SET IDENTITY_INSERT dbo.pages OFF;

PRINT 'Extracted pages into dbo.pages: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
GO

PRINT '==================================================';
PRINT 'STEP 4: Extract Subpages into dbo.page_SubPage';
PRINT '==================================================';

DECLARE @SubPageTable TABLE (ID INT, SubPageID INT);

INSERT INTO dbo.page_SubPage (
    ContentID, Title, Body, Position, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy, SiteID
)
OUTPUT INSERTED.ID, 57 INTO @SubPageTable(ID, SubPageID)
SELECT 
    373 AS ContentID, -- Home Page
    LTRIM(RTRIM(sp.Title)) AS Title,
    REPLACE(
        REPLACE(ISNULL(sp.Body, ''), 'https://www.co.chelan.wa.us/files/', '/files/'),
        'http://www.co.chelan.wa.us/files/', '/files/'
    ) AS Body,
    ISNULL(sp.Position, 1) AS Position,
    COALESCE(sp.Created, SYSUTCDATETIME()) AS CreatedAt,
    '1' AS CreatedBy,
    COALESCE(sp.Modified, SYSUTCDATETIME()) AS ModifiedAt,
    '1' AS ModifiedBy,
    'elections' AS SiteID
FROM cccmsdbv2.dbo.cSubPages sp WITH (NOLOCK)
WHERE sp.SiteID = 1053 AND sp.SubPageID = 57;

INSERT INTO dbo.page_SubPage (
    ContentID, Title, Body, Position, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy, SiteID
)
OUTPUT INSERTED.ID, 58 INTO @SubPageTable(ID, SubPageID)
SELECT 
    373 AS ContentID, -- Home Page
    LTRIM(RTRIM(sp.Title)) AS Title,
    REPLACE(
        REPLACE(ISNULL(sp.Body, ''), 'https://www.co.chelan.wa.us/files/', '/files/'),
        'http://www.co.chelan.wa.us/files/', '/files/'
    ) AS Body,
    ISNULL(sp.Position, 2) AS Position,
    COALESCE(sp.Created, SYSUTCDATETIME()) AS CreatedAt,
    '1' AS CreatedBy,
    COALESCE(sp.Modified, SYSUTCDATETIME()) AS ModifiedAt,
    '1' AS ModifiedBy,
    'elections' AS SiteID
FROM cccmsdbv2.dbo.cSubPages sp WITH (NOLOCK)
WHERE sp.SiteID = 1053 AND sp.SubPageID = 58;

-- Map subpage IDs into JSON SidebarIDs
DECLARE @SpId57 INT = (SELECT TOP 1 ID FROM @SubPageTable WHERE SubPageID = 57);
DECLARE @SpId58 INT = (SELECT TOP 1 ID FROM @SubPageTable WHERE SubPageID = 58);

IF @SpId57 IS NOT NULL AND @SpId58 IS NOT NULL
BEGIN
    UPDATE dbo.pages
    SET SidebarIDs = '["subpage-' + CAST(@SpId57 AS VARCHAR(10)) + '","subpage-' + CAST(@SpId58 AS VARCHAR(10)) + '"]'
    WHERE ContentID = 373 AND SiteID = 'elections';

    UPDATE dbo.pages
    SET SidebarIDs = '["subpage-' + CAST(@SpId57 AS VARCHAR(10)) + '"]'
    WHERE ContentID = 2562 AND SiteID = 'elections';

    PRINT 'Linked SubPages ' + CAST(@SpId57 AS VARCHAR(10)) + ' and ' + CAST(@SpId58 AS VARCHAR(10)) + ' to Home (373) and Precincts Maps (2562).';
END;
GO

PRINT '==================================================';
PRINT 'STEP 5: Configure Navigation Menu & Structured Items';
PRINT '==================================================';

DECLARE @MenuID INT;

SELECT @MenuID = id 
FROM dbo.navigation_menus 
WHERE siteid = 'elections' AND menu_key = 'side';

IF @MenuID IS NULL
BEGIN
    INSERT INTO dbo.navigation_menus (siteid, menu_key, name, is_active, createdat, updatedat)
    VALUES ('elections', 'side', 'Elections Side Navigation', 1, SYSUTCDATETIME(), SYSUTCDATETIME());
    SET @MenuID = SCOPE_IDENTITY();
    PRINT 'Created navigation menu: Elections Side Navigation (ID: ' + CAST(@MenuID AS VARCHAR(10)) + ')';
END
ELSE
BEGIN
    UPDATE dbo.navigation_menus
    SET name = 'Elections Side Navigation', is_active = 1, updatedat = SYSUTCDATETIME()
    WHERE id = @MenuID;
    DELETE FROM dbo.navigation_menu_items WHERE navigation_menu_id = @MenuID;
    PRINT 'Cleaned existing items for menu ID: ' + CAST(@MenuID AS VARCHAR(10));
END;

-- Top-level Category 1: Voting & Registration
DECLARE @ItemVoting INT;
INSERT INTO dbo.navigation_menu_items (
    navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat
) VALUES (
    @MenuID, NULL, 'Voting & Registration', 'page', '/elections/page/voter-registration', 10, 1, 0, 'check-square', SYSUTCDATETIME(), SYSUTCDATETIME()
);
SET @ItemVoting = SCOPE_IDENTITY();

-- Top-level Category 2: Current & Upcoming Elections
DECLARE @ItemElections INT;
INSERT INTO dbo.navigation_menu_items (
    navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat
) VALUES (
    @MenuID, NULL, 'Elections & Results', 'page', '/elections/page/current-election-results', 20, 1, 0, 'calendar', SYSUTCDATETIME(), SYSUTCDATETIME()
);
SET @ItemElections = SCOPE_IDENTITY();

-- Top-level Category 3: Candidates & Jurisdictions
DECLARE @ItemCandidates INT;
INSERT INTO dbo.navigation_menu_items (
    navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat
) VALUES (
    @MenuID, NULL, 'Candidates & Districts', 'page', '/elections/page/candidate-resources', 30, 1, 0, 'users', SYSUTCDATETIME(), SYSUTCDATETIME()
);
SET @ItemCandidates = SCOPE_IDENTITY();

-- Top-level Category 4: Research, Maps & Data
DECLARE @ItemResearch INT;
INSERT INTO dbo.navigation_menu_items (
    navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat
) VALUES (
    @MenuID, NULL, 'Research & Maps', 'page', '/elections/page/research-and-data', 40, 1, 0, 'map', SYSUTCDATETIME(), SYSUTCDATETIME()
);
SET @ItemResearch = SCOPE_IDENTITY();

-- Voting & Registration Children
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @ItemVoting, 'Voter Registration', 'page', '/elections/page/voter-registration', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemVoting, 'Accessible Voting', 'page', '/elections/page/accessible-voting', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemVoting, 'Accessible Voting FAQ', 'page', '/elections/page/accessible-voting-faq', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemVoting, 'Ballot Drop Box Locations', 'page', '/elections/page/ballot-drop-box-locations', 4, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemVoting, 'Signature Challenges', 'page', '/elections/page/signature-challenges', 5, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemVoting, 'Online Voters'' Guide ↗', 'url', 'https://voter.votewa.gov/GenericVoterGuide.aspx?e=899&c=04#/?b=6297', 6, 1, 1, 'external-link', SYSUTCDATETIME(), SYSUTCDATETIME());

-- Elections & Results Children
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @ItemElections, 'Current Election Results', 'page', '/elections/page/current-election-results', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemElections, 'November 3, 2026 General Election', 'page', '/elections/page/november-3-2026-general-election', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemElections, 'August 4, 2026 Primary Election', 'page', '/elections/page/august-4-2026-primary-election', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemElections, 'February 10, 2026 Special Election', 'page', '/elections/page/february-10-2026-special-election', 4, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemElections, 'April 22, 2025 Special Election', 'page', '/elections/page/april-22-2025-special-election', 5, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

-- Candidates & Districts Children
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @ItemCandidates, 'Candidate Resources', 'page', '/elections/page/candidate-resources', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemCandidates, 'Special 3 Day Candidate Filing', 'page', '/elections/page/special-3-day-candidate-filing', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemCandidates, 'Jurisdiction Resources', 'page', '/elections/page/jurisdiction-resources', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

-- Research & Maps Children
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @ItemResearch, 'Research and Data', 'page', '/elections/page/research-and-data', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemResearch, 'Past Election Results', 'page', '/elections/page/past-election-results', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemResearch, 'Precincts Maps', 'page', '/elections/page/precincts-maps', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemResearch, 'Data Restrictions and Requests', 'page', '/elections/page/data-restrictions-and-requests', 4, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @ItemResearch, 'ArcGIS Precinct Mapping ↗', 'url', 'https://maps.chelancounty.gov/GIS/', 5, 1, 1, 'external-link', SYSUTCDATETIME(), SYSUTCDATETIME());

PRINT 'Configured navigation items for Elections Side Navigation.';
GO

PRINT '==================================================';
PRINT 'VERIFICATION QUERY';
PRINT '==================================================';

SELECT 
    (SELECT COUNT(*) FROM dbo.pages WHERE SiteID = 'elections' AND DeletedAt IS NULL) AS TotalElectionsPages,
    (SELECT COUNT(*) FROM dbo.pages WHERE SiteID = 'elections' AND StatusCode = 'Active' AND DeletedAt IS NULL) AS ActiveElectionsPages,
    (SELECT COUNT(*) FROM dbo.page_SubPage WHERE SiteID = 'elections') AS ElectionsSubPages,
    (SELECT COUNT(*) FROM dbo.navigation_menu_items WHERE navigation_menu_id IN (SELECT id FROM dbo.navigation_menus WHERE siteid = 'elections')) AS NavItems;
GO
