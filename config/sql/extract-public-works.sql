-- =============================================================================
-- Chelan County CMSAdmin 2.0 - Complete Extraction for Public Works
-- Source: cccmsdbv2 (Legacy Chelan County Website, SiteID = 1022)
-- Target: ChelanCountyWebsite (CMSAdmin 2.0 Architecture)
-- Rules: SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

PRINT '==================================================';
PRINT 'STEP 1: Register / Update Workspace [public-works]';
PRINT '==================================================';

IF EXISTS (SELECT 1 FROM dbo.cms_workspaces WHERE code IN ('public-works', 'pw'))
BEGIN
    UPDATE dbo.cms_workspaces SET
        code = 'public-works',
        name = 'Public Works',
        alias = 'pw',
        type = 'dept',
        badge = 'Public Works',
        badge_class = 'badge-info',
        icon = 'truck',
        color = '#0073aa',
        description = 'Keeping Chelan County a Great Place To Live, Work and Play! County roads, bridges, stormwater, capital projects, and development review.',
        folder_path = 'c:\inetpub\chelan-county\files\public-works',
        virtual_directory = 'public-works',
        redirect_url = 'https://www.chelancounty.gov/public-works',
        department = 'Public Works',
        department_category = 'Internal Services',
        storage_path = 'files/public-works',
        domain_name = 'www.chelancounty.gov',
        project_path = 'C:\inetpub\chelan-county',
        leadership_type = 'dept_head',
        job_title = 'Director / County Engineer',
        contact_photo = '/images/logo/public-works.jpg',
        contact_first_name = 'Eric',
        contact_last_name = 'Pierson, PE',
        contact_email = 'public.works@co.chelan.wa.us',
        contact_phone = '(509) 667-6415',
        contact_fax = '(509) 667-6250',
        address = '316 Washington St, Suite 402',
        address2 = '',
        city = 'Wenatchee',
        state = 'WA',
        zip = '98801',
        office_hours = 'Monday - Friday 8:00 AM - 5:00 PM PST',
        is_active = 1,
        deletedat = NULL,
        updatedat = SYSUTCDATETIME()
    WHERE code IN ('public-works', 'pw');
    PRINT 'Updated workspace [public-works].';
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
        'public-works',
        'Public Works',
        'pw',
        'dept',
        'Public Works',
        'badge-info',
        'truck',
        '#0073aa',
        'Keeping Chelan County a Great Place To Live, Work and Play! County roads, bridges, stormwater, capital projects, and development review.',
        'c:\inetpub\chelan-county\files\public-works',
        'public-works',
        'https://www.chelancounty.gov/public-works',
        'Public Works',
        'Internal Services',
        'files/public-works',
        'www.chelancounty.gov',
        'C:\inetpub\chelan-county',
        'dept_head',
        'Director / County Engineer',
        '/images/logo/public-works.jpg',
        'Eric',
        'Pierson, PE',
        'public.works@co.chelan.wa.us',
        '(509) 667-6415',
        '(509) 667-6250',
        '316 Washington St, Suite 402',
        '',
        'Wenatchee',
        'WA',
        '98801',
        'Monday - Friday 8:00 AM - 5:00 PM PST',
        1,
        0,
        90,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );
    PRINT 'Inserted workspace [public-works].';
END

PRINT '==================================================';
PRINT 'STEP 2: Clean Existing Public Works Pages & Assets';
PRINT '==================================================';

DELETE FROM dbo.page_revisions WHERE page_id IN (SELECT ContentID FROM dbo.pages WHERE SiteID IN ('public-works', 'pw', 'site-public-works'));
DELETE FROM dbo.page_SubPage WHERE SiteID IN ('public-works', 'pw', 'site-public-works');
IF OBJECT_ID('dbo.page_FolderExplorer', 'U') IS NOT NULL
    DELETE FROM dbo.page_FolderExplorer WHERE SiteID IN ('public-works', 'pw', 'site-public-works');
IF OBJECT_ID('dbo.page_CtaCard', 'U') IS NOT NULL
    DELETE FROM dbo.page_CtaCard WHERE SiteID IN ('public-works', 'pw', 'site-public-works');
IF OBJECT_ID('dbo.page_call_to_actions', 'U') IS NOT NULL
    DELETE FROM dbo.page_call_to_actions WHERE siteid IN ('public-works', 'pw', 'site-public-works');
DELETE FROM dbo.pages WHERE SiteID IN ('public-works', 'pw', 'site-public-works');

PRINT '==================================================';
PRINT 'STEP 3: Extract 53 Pages from cccmsdbv2.dbo.cContents (SiteID = 1022)';
PRINT '==================================================';

-- Note: Legacy ContentIDs 36, 37, and 39 collide with existing Auditor pages in dbo.pages.
-- We map 36 -> 6036, 37 -> 6037, and 39 -> 6039; all other 50 ContentIDs retain their exact legacy ID.

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
    CASE WHEN c.ContentID IN (36, 37, 39) THEN c.ContentID + 6000 ELSE c.ContentID END AS ContentID,
    'public-works' AS SiteID,
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
    CASE
        WHEN c.ContentID = 107 AND LEN(LTRIM(RTRIM(ISNULL(c.Body, '')))) = 0 THEN
            N'<p class="lead">Keeping Chelan County a Great Place To Live, Work and Play!</p>'
            + N'<p>The Chelan County Public Works Department is responsible for the planning, design, construction, and maintenance of approximately 658 miles of county roads and 61 bridges, as well as stormwater management, solid waste programs, 911 addressing, and development review across unincorporated Chelan County.</p>'
        ELSE
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    REPLACE(ISNULL(c.Body, ''), 'https://www.co.chelan.wa.us/files/', '/files/'),
                                                    'http://www.co.chelan.wa.us/files/', '/files/'
                                                ),
                                                'http://co.chelan.wa.us/files/', '/files/'
                                            ),
                                            'https://www.co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                                        ),
                                        'http://www.co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                                    ),
                                    'https://co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                                ),
                                'http://co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                            ),
                            '/public-works/pages/', '/public-works/page/'
                        ),
                        'https://www.co.chelan.wa.us/public-works/contacts', '/public-works/contacts'
                    ),
                    'https://www.co.chelan.wa.us/public-works/forms/', '/public-works/forms/'
                ),
                'http://www.co.chelan.wa.us/public-works/forms/', '/public-works/forms/'
            )
    END AS Body,
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
    CASE WHEN c.ContentID = 107 THEN 1 ELSE 0 END AS hasCtaCards,
    CASE WHEN c.ContentID = 107 THEN 'Quick Services & Online Tools' ELSE NULL END AS ctaSectionTitle,
    0 AS hasArchive,
    ISNULL(c.Created, SYSUTCDATETIME()) AS publish_at,
    NULL AS unpublish_at,
    NULL AS UnpublishAt
FROM cccmsdbv2.dbo.cContents c WITH (NOLOCK)
WHERE c.SiteID = 1022;

SET IDENTITY_INSERT dbo.pages OFF;

PRINT '==================================================';
PRINT 'STEP 3B: Append Legacy Q&A Accordions (cFAQ) to Pages with hasQnA = 1';
PRINT '==================================================';

DECLARE @QnaPageCursor CURSOR;
DECLARE @LegacyCid INT, @MappedCid INT, @QnaId INT;

SET @QnaPageCursor = CURSOR FAST_FORWARD FOR
    SELECT
        c.ContentID AS LegacyCid,
        CASE WHEN c.ContentID IN (36, 37, 39) THEN c.ContentID + 6000 ELSE c.ContentID END AS MappedCid,
        c.QnAID
    FROM cccmsdbv2.dbo.cContents c WITH (NOLOCK)
    WHERE c.SiteID = 1022
      AND c.hasQnA = 1
      AND ISNULL(c.QnAID, 0) > 0;

OPEN @QnaPageCursor;
FETCH NEXT FROM @QnaPageCursor INTO @LegacyCid, @MappedCid, @QnaId;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM cccmsdbv2.dbo.cFAQ WITH (NOLOCK) WHERE SITEID = 1022 AND QNAID = @QnaId AND STATUSCODE = 1)
    BEGIN
        DECLARE @AccordionHtml NVARCHAR(MAX) = N'<div class="accordion my-4" id="pwFaqAccordion' + CAST(@QnaId AS NVARCHAR(10)) + N'">';

        SELECT @AccordionHtml = @AccordionHtml +
            N'<div class="accordion-item border rounded-3 mb-2 overflow-hidden">' +
                N'<h3 class="accordion-header" id="faqHeading' + CAST(f.FAQID AS NVARCHAR(10)) + N'">' +
                    N'<button class="accordion-button collapsed fw-semibold" type="button" data-bs-toggle="collapse" data-bs-target="#faqCollapse' + CAST(f.FAQID AS NVARCHAR(10)) + N'" aria-expanded="false" aria-controls="faqCollapse' + CAST(f.FAQID AS NVARCHAR(10)) + N'">' +
                        LTRIM(RTRIM(ISNULL(f.QUESTION, N''))) +
                    N'</button>' +
                N'</h3>' +
                N'<div id="faqCollapse' + CAST(f.FAQID AS NVARCHAR(10)) + N'" class="accordion-collapse collapse" aria-labelledby="faqHeading' + CAST(f.FAQID AS NVARCHAR(10)) + N'" data-bs-parent="#pwFaqAccordion' + CAST(@QnaId AS NVARCHAR(10)) + N'">' +
                    N'<div class="accordion-body">' +
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(ISNULL(f.ANSWER, N''), 'https://www.co.chelan.wa.us/files/', '/files/'),
                                        'http://www.co.chelan.wa.us/files/', '/files/'
                                    ),
                                    'https://www.co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                                ),
                                'http://www.co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                            ),
                            '/public-works/pages/', '/public-works/page/'
                        ) +
                    N'</div>' +
                N'</div>' +
            N'</div>'
        FROM cccmsdbv2.dbo.cFAQ f WITH (NOLOCK)
        WHERE f.SITEID = 1022 AND f.QNAID = @QnaId AND f.STATUSCODE = 1
        ORDER BY f.FAQID ASC;

        SET @AccordionHtml = @AccordionHtml + N'</div>';

        UPDATE dbo.pages
        SET Body = ISNULL(Body, N'') + NCHAR(13) + NCHAR(10) + @AccordionHtml
        WHERE ContentID = @MappedCid AND SiteID = 'public-works';
    END;

    FETCH NEXT FROM @QnaPageCursor INTO @LegacyCid, @MappedCid, @QnaId;
END;

CLOSE @QnaPageCursor;
DEALLOCATE @QnaPageCursor;

PRINT '==================================================';
PRINT 'STEP 4: Extract 34 SubPages into dbo.page_SubPage & Link SidebarIDs';
PRINT '==================================================';

DECLARE @SpCursor CURSOR;
DECLARE @LegacySpId INT, @SpTitle NVARCHAR(255), @SpHeader NVARCHAR(255), @SpBody NVARCHAR(MAX), @SpPos INT, @SpCreated DATETIME2, @SpModified DATETIME2, @PrimaryContentId INT, @NewSpId INT;

DECLARE @SubPageMap TABLE (LegacySubPageID INT PRIMARY KEY, NewID INT);

SET @SpCursor = CURSOR FAST_FORWARD FOR
    SELECT
        sp.SubPageID,
        LTRIM(RTRIM(ISNULL(sp.Title, ''))),
        LTRIM(RTRIM(ISNULL(sp.Header, ''))),
        ISNULL(sp.Body, ''),
        ISNULL(sp.Position, 1),
        COALESCE(sp.Created, SYSUTCDATETIME()),
        COALESCE(sp.Modified, SYSUTCDATETIME()),
        ISNULL((
            SELECT TOP 1 CASE WHEN sb.ContentID IN (36, 37, 39) THEN sb.ContentID + 6000 ELSE sb.ContentID END
            FROM cccmsdbv2.dbo.cSidebars sb WITH (NOLOCK)
            INNER JOIN cccmsdbv2.dbo.cContents c WITH (NOLOCK) ON c.ContentID = sb.ContentID AND c.SiteID = 1022
            WHERE sb.WIDGETTYPE = 'subpages' AND sb.WIDGETTYPEID = sp.SubPageID
            ORDER BY sb.SIDEBARID ASC
        ), 107) AS PrimaryContentId
    FROM cccmsdbv2.dbo.cSubPages sp WITH (NOLOCK)
    WHERE sp.SiteID = 1022
    ORDER BY sp.SubPageID ASC;

OPEN @SpCursor;
FETCH NEXT FROM @SpCursor INTO @LegacySpId, @SpTitle, @SpHeader, @SpBody, @SpPos, @SpCreated, @SpModified, @PrimaryContentId;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @CleanBody NVARCHAR(MAX) = REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(@SpBody, 'https://www.co.chelan.wa.us/files/', '/files/'),
                                'http://www.co.chelan.wa.us/files/', '/files/'
                            ),
                            '/files//public-works/', '/files/public-works/'
                        ),
                        'https://www.co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                    ),
                    'http://www.co.chelan.wa.us/public-works/pages/', '/public-works/page/'
                ),
                '/public-works/pages/', '/public-works/page/'
            ),
            'https://www.co.chelan.wa.us/public-works/forms/', '/public-works/forms/'
        ),
        'http://www.co.chelan.wa.us/public-works/forms/', '/public-works/forms/'
    );

    IF LEN(@SpHeader) > 0 AND CHARINDEX(@SpHeader, @CleanBody) = 0
    BEGIN
        SET @CleanBody = N'<h4>' + @SpHeader + N'</h4>' + NCHAR(13) + NCHAR(10) + @CleanBody;
    END;

    INSERT INTO dbo.page_SubPage (
        ContentID, Title, Body, Position, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy, SiteID
    )
    VALUES (
        @PrimaryContentId,
        CASE WHEN LEN(@SpHeader) > 0 THEN @SpHeader ELSE @SpTitle END,
        @CleanBody,
        @SpPos,
        @SpCreated,
        'Migration',
        @SpModified,
        'Migration',
        'public-works'
    );

    SET @NewSpId = SCOPE_IDENTITY();
    INSERT INTO @SubPageMap (LegacySubPageID, NewID) VALUES (@LegacySpId, @NewSpId);

    FETCH NEXT FROM @SpCursor INTO @LegacySpId, @SpTitle, @SpHeader, @SpBody, @SpPos, @SpCreated, @SpModified, @PrimaryContentId;
END;

CLOSE @SpCursor;
DEALLOCATE @SpCursor;

-- Dynamically link SidebarIDs JSON array on dbo.pages from cSidebars + @SubPageMap
UPDATE p
SET p.SidebarIDs = '[' + sub.JsonList + ']',
    p.LayoutType = 'Right Sidebar'
FROM dbo.pages p
INNER JOIN (
    SELECT
        MappedContentID,
        STRING_AGG('"subpage-' + CAST(NewID AS VARCHAR(10)) + '"', ',') WITHIN GROUP (ORDER BY MinPosition ASC, MinSidebarID ASC) AS JsonList
    FROM (
        SELECT
            CASE WHEN sb.ContentID IN (36, 37, 39) THEN sb.ContentID + 6000 ELSE sb.ContentID END AS MappedContentID,
            m.NewID,
            MIN(ISNULL(sb.POSITION, 1)) AS MinPosition,
            MIN(sb.SIDEBARID) AS MinSidebarID
        FROM cccmsdbv2.dbo.cSidebars sb WITH (NOLOCK)
        INNER JOIN @SubPageMap m ON m.LegacySubPageID = sb.WIDGETTYPEID
        WHERE sb.WIDGETTYPE = 'subpages'
        GROUP BY
            CASE WHEN sb.ContentID IN (36, 37, 39) THEN sb.ContentID + 6000 ELSE sb.ContentID END,
            m.NewID
    ) dedup
    GROUP BY MappedContentID
) sub ON sub.MappedContentID = p.ContentID
WHERE p.SiteID = 'public-works';

PRINT '==================================================';
PRINT 'STEP 5: Extract Call to Action Cards (Home Page ContentID = 107)';
PRINT '==================================================';

IF OBJECT_ID('dbo.page_CtaCard', 'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.page_CtaCard (
        ContentID, SiteID, Title, ShortDescription, DestinationUrl, ImagePath, ImageAlt, ButtonText, ButtonIcon, OpenInNewTab, SortOrder, IsActive, CreatedBy
    )
    VALUES
        (107, 'public-works', N'Report A Problem', N'Report a road hazard, pothole, missing traffic sign, or drainage issue to Public Works.', N'/public-works/forms/report-a-problem', N'/images/picjumbo/report-a-problem.jpg', N'Report a road hazard or maintenance issue', N'Report Issue', N'fa-arrow-right', 0, 1, 1, N'Migration'),
        (107, 'public-works', N'Online Services', N'Apply for Public Works permits, right-of-way applications, and development services online via SmartGov.', N'https://co-chelan-wa.smartgovcommunity.com/Public/Home', N'/images/picjumbo/liberty16x9.jpg', N'Online permitting and development portal', N'Open Portal', N'fa-arrow-up-right-from-square', 1, 2, 1, N'Migration'),
        (107, 'public-works', N'Like Us On Facebook', N'Follow Chelan County Public Works on Facebook for project updates, seasonal reminders, and emergency road news.', N'https://www.facebook.com/Chelan-County-Public-Works-417916311666797/', N'/images/picjumbo/public-works-facebook.jpg', N'Follow Chelan County Public Works on Facebook', N'Follow Updates', N'fa-arrow-up-right-from-square', 1, 3, 1, N'Migration'),
        (107, 'public-works', N'Road Alert', N'View current county road restrictions, seasonal weight limits, closures, and construction travel impacts.', N'/public-works/page/traffic-alerts-and-restrictions', N'/images/picjumbo/traffic-cones.jpg', N'Traffic cones indicating road alert and restrictions', N'View Alerts', N'fa-arrow-right', 0, 4, 1, N'Migration');
END;

IF OBJECT_ID('dbo.page_call_to_actions', 'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.page_call_to_actions (
        siteid, title, slug, description, image_url, image_alt,
        badge_text, badge_color, layout_type, link_text, link_url,
        link_icon, link_style, target_blank, category, sort_order,
        is_published, created_by, modified_by, createdat, updatedat
    )
    VALUES
        (N'public-works', N'Report A Problem', N'public-works-report-a-problem', N'Report a road hazard, pothole, missing traffic sign, or drainage issue to Public Works.', N'/images/picjumbo/report-a-problem.jpg', N'Report a road hazard or maintenance issue', N'CITIZEN SERVICE', N'blue', N'card', N'Report Issue', N'/public-works/forms/report-a-problem', N'arrow', N'link', 0, N'Public Works', 1, 1, N'Migration', N'Migration', SYSUTCDATETIME(), SYSUTCDATETIME()),
        (N'public-works', N'Online Services', N'public-works-online-services', N'Apply for Public Works permits, right-of-way applications, and development services online via SmartGov.', N'/images/picjumbo/liberty16x9.jpg', N'Online permitting and development portal', N'ONLINE PORTAL', N'teal', N'card', N'Open Portal', N'https://co-chelan-wa.smartgovcommunity.com/Public/Home', N'external', N'link', 1, N'Public Works', 2, 1, N'Migration', N'Migration', SYSUTCDATETIME(), SYSUTCDATETIME()),
        (N'public-works', N'Like Us On Facebook', N'public-works-facebook', N'Follow Chelan County Public Works on Facebook for project updates, seasonal reminders, and emergency road news.', N'/images/picjumbo/public-works-facebook.jpg', N'Follow Chelan County Public Works on Facebook', N'COMMUNITY', N'blue', N'card', N'Follow Updates', N'https://www.facebook.com/Chelan-County-Public-Works-417916311666797/', N'external', N'link', 1, N'Public Works', 3, 1, N'Migration', N'Migration', SYSUTCDATETIME(), SYSUTCDATETIME()),
        (N'public-works', N'Road Alert', N'public-works-road-alert', N'View current county road restrictions, seasonal weight limits, closures, and construction travel impacts.', N'/images/picjumbo/traffic-cones.jpg', N'Traffic cones indicating road alert and restrictions', N'TRAFFIC ALERTS', N'amber', N'card', N'View Alerts', N'/public-works/page/traffic-alerts-and-restrictions', N'arrow', N'link', 0, N'Public Works', 4, 1, N'Migration', N'Migration', SYSUTCDATETIME(), SYSUTCDATETIME());
END;

PRINT '==================================================';
PRINT 'STEP 6: Configure Navigation Menu & Items';
PRINT '==================================================';

DECLARE @MenuID INT;

SELECT @MenuID = id 
FROM dbo.navigation_menus 
WHERE siteid IN ('public-works', 'pw') AND menu_key = 'side';

IF @MenuID IS NULL
BEGIN
    INSERT INTO dbo.navigation_menus (siteid, menu_key, name, is_active, createdat, updatedat)
    VALUES ('public-works', 'side', 'Public Works Side Navigation', 1, SYSUTCDATETIME(), SYSUTCDATETIME());
    SET @MenuID = SCOPE_IDENTITY();
END
ELSE
BEGIN
    UPDATE dbo.navigation_menus
    SET siteid = 'public-works', name = 'Public Works Side Navigation', is_active = 1, updatedat = SYSUTCDATETIME()
    WHERE id = @MenuID;
    DELETE FROM dbo.navigation_menu_items WHERE navigation_menu_id = @MenuID;
END;

-- 1. Traffic Alerts (Parent)
DECLARE @NavTraffic INT;
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Traffic Alerts', 'page', '/public-works/page/traffic-alerts-and-restrictions', 10, 1, 0, 'siren', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @NavTraffic = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @NavTraffic, 'Current Restrictions', 'page', '/public-works/page/traffic-alerts-and-restrictions', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavTraffic, 'County Bridges', 'page', '/public-works/page/county-bridges', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavTraffic, 'Traffic Safety Team', 'page', '/public-works/page/traffic-safety-team', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

-- 2. Business (Parent)
DECLARE @NavBusiness INT;
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Business', 'page', '/public-works/page/consultants-and-small-works', 20, 1, 0, 'briefcase', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @NavBusiness = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @NavBusiness, 'Consultants and Small Works', 'page', '/public-works/page/consultants-and-small-works', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavBusiness, 'Bidding Opportunities', 'page', '/public-works/page/bidding-opportunities', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavBusiness, 'Transportation Plans', 'page', '/public-works/page/transportation-plans', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

-- 3. Departments (Parent)
DECLARE @NavDepts INT;
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Departments', 'page', '/public-works/page/addressing-and-road-naming', 30, 1, 0, 'building', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @NavDepts = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @NavDepts, 'Addressing', 'page', '/public-works/page/addressing-and-road-naming', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavDepts, 'Development', 'page', '/public-works/page/development', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavDepts, 'Road Maintenance', 'page', '/public-works/page/road-maintenance', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavDepts, 'Solid Waste', 'url', '/solid-waste-management', 4, 1, 0, 'external-link', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavDepts, 'Storm Water', 'page', '/public-works/page/storm-water', 5, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavDepts, 'Flood Control Zone District', 'url', '/flood-control-zone-district', 6, 1, 0, 'external-link', SYSUTCDATETIME(), SYSUTCDATETIME());

-- 4. Projects (Parent)
DECLARE @NavProjects INT;
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES (@MenuID, NULL, 'Projects', 'page', '/public-works/page/capital-projects', 40, 1, 0, 'truck', SYSUTCDATETIME(), SYSUTCDATETIME());
SET @NavProjects = SCOPE_IDENTITY();

INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, @NavProjects, 'Capital Projects', 'page', '/public-works/page/capital-projects', 1, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavProjects, 'Annual Chipseal Program', 'page', '/public-works/page/pavement-preservation-program', 2, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, @NavProjects, 'Annual Archives', 'page', '/public-works/page/annual-archives', 3, 1, 0, 'file', SYSUTCDATETIME(), SYSUTCDATETIME());

-- 5. Standalone Top-Level Items
INSERT INTO dbo.navigation_menu_items (navigation_menu_id, parent_item_id, label, destination_type, destination, sort_order, is_active, open_in_new_tab, icon, createdat, updatedat)
VALUES
    (@MenuID, NULL, 'Safety & Transportation Planning', 'page', '/public-works/page/chelan-county-safety', 50, 1, 0, 'shield', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Historical Bridges', 'page', '/public-works/page/historic-bridges', 60, 1, 0, 'landmark', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Frequently Asked Questions', 'page', '/public-works/page/frequently-asked-questions-public-works', 70, 1, 0, 'help-circle', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Blog', 'url', '/public-works/blog', 80, 1, 0, 'newspaper', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'How Do I', 'url', '/public-works/howdoi', 90, 1, 0, 'help-circle', SYSUTCDATETIME(), SYSUTCDATETIME()),
    (@MenuID, NULL, 'Contact Us', 'url', '/public-works/contacts', 100, 1, 0, 'phone', SYSUTCDATETIME(), SYSUTCDATETIME());

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
    '{"migrated":true,"source":"cccmsdbv2","siteId":1022}',
    'Initial migration from legacy co.chelan.wa.us/public-works (SiteID 1022)',
    'Migration',
    ISNULL(p.Modified, SYSUTCDATETIME())
FROM dbo.pages p
WHERE p.SiteID = 'public-works';

PRINT '==================================================';
PRINT 'VERIFICATION SUMMARY';
PRINT '==================================================';

SELECT
    (SELECT COUNT(*) FROM dbo.pages WHERE SiteID = 'public-works' AND DeletedAt IS NULL) AS TotalPages,
    (SELECT COUNT(*) FROM dbo.pages WHERE SiteID = 'public-works' AND StatusCode = 'Active' AND isPublished = 1 AND DeletedAt IS NULL) AS PublishedActivePages,
    (SELECT COUNT(*) FROM dbo.page_SubPage WHERE SiteID = 'public-works') AS TotalSubPages,
    (SELECT COUNT(*) FROM dbo.page_CtaCard WHERE SiteID = 'public-works') AS TotalCtaCards,
    (SELECT COUNT(*) FROM dbo.navigation_menu_items WHERE navigation_menu_id = @MenuID) AS TotalNavItems,
    (SELECT COUNT(*) FROM dbo.page_revisions WHERE page_id IN (SELECT ContentID FROM dbo.pages WHERE SiteID = 'public-works')) AS TotalRevisions;

